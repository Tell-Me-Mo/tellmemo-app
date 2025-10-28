"""
Meeting Context Search Service

Searches the current meeting transcript for answers to detected questions
using GPT-5-mini for semantic matching. This is Tier 2 of the four-tier
answer discovery system.

Tier 2: Meeting Context Search
- Searches earlier in the current meeting transcript
- Uses GPT-5-mini for semantic search and matching
- Returns exact quotes with speaker attribution and timestamp
- Timeout: 1.5 seconds maximum (optimized with GPT-5-mini)
"""

import asyncio
import json
import logging
from datetime import datetime
from typing import Optional, Dict, Any, List
from dataclasses import dataclass

from ..transcription.transcription_buffer_service import get_transcription_buffer
from ..llm.multi_llm_client import get_multi_llm_client

logger = logging.getLogger(__name__)


@dataclass
class MeetingContextResult:
    """Result from meeting context search."""

    found_answer: bool
    answer_text: Optional[str] = None
    quotes: Optional[List[Dict[str, Any]]] = None  # [{text, speaker, timestamp}]
    confidence: float = 0.0
    search_duration_ms: int = 0

    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary for JSON serialization."""
        return {
            "found_answer": self.found_answer,
            "answer_text": self.answer_text,
            "quotes": self.quotes or [],
            "confidence": self.confidence,
            "search_duration_ms": self.search_duration_ms
        }


class MeetingContextSearchService:
    """
    Service to search current meeting transcript for answers to questions.

    Uses GPT-5-mini for semantic search and improved reference detection.
    Returns exact quotes with speaker attribution and clickable timestamps.
    """

    def __init__(
        self,
        timeout: float = 1.5,
        confidence_threshold: float = 0.75,
        max_quotes: int = 3
    ):
        """
        Initialize meeting context search service.

        Args:
            timeout: Maximum time to wait for search (seconds)
            confidence_threshold: Minimum confidence to return answer (0-1)
            max_quotes: Maximum number of relevant quotes to return
        """
        self.timeout = timeout
        self.confidence_threshold = confidence_threshold
        self.max_quotes = max_quotes
        self.transcription_buffer = get_transcription_buffer()
        self.llm_client = get_multi_llm_client()

        logger.info(
            f"MeetingContextSearchService initialized: "
            f"timeout={timeout}s, confidence_threshold={confidence_threshold}, "
            f"max_quotes={max_quotes}"
        )

    async def search(
        self,
        question: str,
        session_id: str,
        speaker: Optional[str] = None,
        organization_id: Optional[str] = None
    ) -> MeetingContextResult:
        """
        Search meeting transcript for answer to question.

        Args:
            question: The question text to search for
            session_id: Meeting session identifier
            speaker: Who asked the question (optional)
            organization_id: Organization ID for LLM tracking (optional)

        Returns:
            MeetingContextResult with answer, quotes, and confidence
        """
        start_time = datetime.now()

        try:
            # Search with timeout
            search_task = self._search_transcript(
                question=question,
                session_id=session_id,
                speaker=speaker,
                organization_id=organization_id
            )

            result = await asyncio.wait_for(search_task, timeout=self.timeout)

            duration_ms = int((datetime.now() - start_time).total_seconds() * 1000)
            result.search_duration_ms = duration_ms

            if result.found_answer:
                logger.info(
                    f"Meeting context search found answer: session={session_id}, "
                    f"confidence={result.confidence:.2f}, duration={duration_ms}ms, "
                    f"quotes={len(result.quotes or [])}"
                )
            else:
                logger.debug(
                    f"Meeting context search found no answer: session={session_id}, "
                    f"duration={duration_ms}ms"
                )

            return result

        except asyncio.TimeoutError:
            duration_ms = int(self.timeout * 1000)
            logger.warning(
                f"Meeting context search timeout: session={session_id}, "
                f"timeout={self.timeout}s, question='{question[:50]}...'"
            )
            return MeetingContextResult(
                found_answer=False,
                search_duration_ms=duration_ms
            )

        except Exception as e:
            duration_ms = int((datetime.now() - start_time).total_seconds() * 1000)
            logger.error(
                f"Meeting context search error: session={session_id}, "
                f"error={str(e)}, duration={duration_ms}ms",
                exc_info=True
            )
            return MeetingContextResult(
                found_answer=False,
                search_duration_ms=duration_ms
            )

    async def _search_transcript(
        self,
        question: str,
        session_id: str,
        speaker: Optional[str],
        organization_id: Optional[str]
    ) -> MeetingContextResult:
        """
        Internal method to search transcript using GPT-5-mini.

        Args:
            question: Question text
            session_id: Session identifier
            speaker: Question speaker
            organization_id: Organization ID

        Returns:
            MeetingContextResult with findings
        """
        # Step 1: Get formatted meeting transcript
        transcript = await self.transcription_buffer.get_formatted_context(
            session_id=session_id,
            include_timestamps=True,
            include_speakers=True
        )

        if not transcript or len(transcript.strip()) < 20:
            logger.debug(
                f"Meeting transcript too short for search: session={session_id}, "
                f"length={len(transcript) if transcript else 0}"
            )
            return MeetingContextResult(found_answer=False)

        # Step 2: Build prompts for GPT-5-mini
        system_prompt = self._build_system_prompt()
        user_prompt = self._build_user_prompt(
            question=question,
            transcript=transcript,
            speaker=speaker
        )

        # Step 3: Call GPT-5-mini for semantic search
        try:
            response = await self.llm_client.create_message(
                prompt=user_prompt,
                system=system_prompt,  # Use 'system' not 'system_prompt' for Claude API
                session=None,
                organization_id=organization_id,
                temperature=0.3,  # Low temperature for precise search
                max_tokens=500,   # Moderate for answer extraction
                response_format={"type": "json_object"}
            )

            # Step 4: Parse GPT response
            return self._parse_gpt_response(response)

        except Exception as e:
            logger.error(
                f"GPT-5-mini call failed for meeting context search: "
                f"session={session_id}, error={str(e)}",
                exc_info=True
            )
            return MeetingContextResult(found_answer=False)

    def _build_system_prompt(self) -> str:
        """Build system prompt for GPT-5-mini semantic search."""
        return """You are a meeting transcript search assistant. Your job is to search the meeting transcript for answers to questions.

TASK:
1. Read the provided meeting transcript carefully
2. Determine if the question was already answered earlier in the meeting
3. If yes, extract the answer with exact quotes, speaker attribution, and timestamps
4. If no, return found_answer=false

OUTPUT FORMAT (JSON):
{
  "found_answer": true/false,
  "answer_text": "Concise summary of the answer (1-2 sentences)",
  "quotes": [
    {
      "text": "Exact quote from transcript",
      "speaker": "Speaker A",
      "timestamp": "[HH:MM:SS]"
    }
  ],
  "confidence": 0.85
}

RULES:
- Only return found_answer=true if confident (>75% confidence)
- Use exact quotes from the transcript, do not paraphrase
- Include speaker attribution and timestamps for all quotes
- Return up to 3 most relevant quotes
- Confidence should be 0.0-1.0 based on how clearly the answer was stated
- If the question wasn't discussed, return found_answer=false
- Do not fabricate answers or infer beyond what was said"""

    def _build_user_prompt(
        self,
        question: str,
        transcript: str,
        speaker: Optional[str]
    ) -> str:
        """
        Build user prompt with question and transcript.

        Args:
            question: Question to search for
            transcript: Formatted meeting transcript
            speaker: Question speaker (optional)

        Returns:
            Formatted user prompt
        """
        speaker_info = f"\nAsked by: {speaker}" if speaker else ""

        return f"""QUESTION TO SEARCH FOR:
"{question}"{speaker_info}

MEETING TRANSCRIPT:
{transcript}

Search the transcript above and determine if this question was already answered earlier in the meeting. Return your analysis in JSON format as specified."""

    def _parse_gpt_response(self, response: str) -> MeetingContextResult:
        """
        Parse GPT-5-mini JSON response.

        Args:
            response: Raw GPT response string

        Returns:
            MeetingContextResult with parsed data
        """
        try:
            # Extract text content from Message object (Claude/OpenAI response)
            if hasattr(response, 'content') and isinstance(response.content, list):
                # Claude/OpenAI Message object with content array
                response_text = response.content[0].text if response.content else ""
                logger.debug(f"Extracted text from Message object: {response_text[:200] if response_text else 'EMPTY'}")
            elif isinstance(response, str):
                # Already a string
                response_text = response
                logger.debug(f"Response already string: {response_text[:200] if response_text else 'EMPTY'}")
            else:
                # Fallback - convert to string
                response_text = str(response)
                logger.debug(f"Converted response to string: {response_text[:200]}")

            if not response_text or response_text.strip() == "":
                logger.warning("Response text is empty after extraction")
                return MeetingContextResult(found_answer=False)

            data = json.loads(response_text)

            found_answer = data.get("found_answer", False)
            confidence = float(data.get("confidence", 0.0))

            # Check confidence threshold
            if confidence < self.confidence_threshold:
                logger.debug(
                    f"Meeting context answer below confidence threshold: "
                    f"confidence={confidence:.2f}, threshold={self.confidence_threshold}"
                )
                return MeetingContextResult(found_answer=False)

            # Extract answer and quotes
            answer_text = data.get("answer_text")
            quotes = data.get("quotes", [])

            # Validate quotes structure
            validated_quotes = []
            for quote in quotes[:self.max_quotes]:
                if isinstance(quote, dict) and "text" in quote:
                    validated_quotes.append({
                        "text": quote.get("text", ""),
                        "speaker": quote.get("speaker", "Unknown"),
                        "timestamp": quote.get("timestamp", "")
                    })

            return MeetingContextResult(
                found_answer=found_answer,
                answer_text=answer_text,
                quotes=validated_quotes,
                confidence=confidence
            )

        except json.JSONDecodeError as e:
            logger.error(
                f"Failed to parse GPT response as JSON: {str(e)}, "
                f"response_text='{response_text[:200] if response_text else 'EMPTY'}...'"
            )
            return MeetingContextResult(found_answer=False)

        except Exception as e:
            logger.error(
                f"Error parsing GPT response: {str(e)}",
                exc_info=True
            )
            return MeetingContextResult(found_answer=False)


# Singleton instance
_meeting_context_search_service: Optional[MeetingContextSearchService] = None


def get_meeting_context_search() -> MeetingContextSearchService:
    """Get singleton instance of MeetingContextSearchService."""
    global _meeting_context_search_service
    if _meeting_context_search_service is None:
        _meeting_context_search_service = MeetingContextSearchService()
    return _meeting_context_search_service
