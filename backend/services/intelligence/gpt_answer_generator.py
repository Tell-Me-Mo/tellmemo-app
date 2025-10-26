"""
GPT Answer Generator Service (Tier 4)

This service generates AI-powered answers for questions that couldn't be answered through:
- Tier 1: RAG Search
- Tier 2: Meeting Context Search
- Tier 3: Live Conversation Monitoring

Uses GPT-5-mini to generate answers based on general knowledge with confidence scoring.
"""

import asyncio
import json
from datetime import datetime
from typing import Dict, Any, Optional
from sqlalchemy.orm import Session

from core.logging import get_logger
from services.llm.multi_llm_client import get_multi_llm_client
from models.live_insight import LiveMeetingInsight, AnswerSource, InsightStatus

logger = get_logger(__name__)


class GPTAnswerGenerator:
    """
    Generates AI-powered answers using GPT-5-mini for questions that couldn't
    be answered through other tiers.
    """

    def __init__(
        self,
        broadcast_callback: Optional[callable] = None,
        timeout: float = 3.0,
        confidence_threshold: float = 0.70
    ):
        """
        Initialize GPT Answer Generator.

        Args:
            broadcast_callback: Async function to broadcast events via WebSocket
            timeout: Timeout for GPT generation in seconds (default: 3.0)
            confidence_threshold: Minimum confidence to return answer (default: 0.70)
        """
        self.broadcast_callback = broadcast_callback
        self.timeout = timeout
        self.confidence_threshold = confidence_threshold

        logger.info(
            f"GPTAnswerGenerator initialized with timeout={timeout}s, "
            f"threshold={confidence_threshold}"
        )

    async def generate_answer(
        self,
        session_id: str,
        question_id: str,
        question_text: str,
        speaker: Optional[str] = None,
        meeting_context: Optional[str] = None,
        db_session: Optional[Session] = None
    ) -> bool:
        """
        Generate an AI-powered answer for a question using GPT-5-mini.

        Args:
            session_id: Meeting session ID
            question_id: Question ID
            question_text: The question to answer
            speaker: Speaker who asked the question
            meeting_context: Brief meeting context summary
            db_session: Database session for updates

        Returns:
            bool: True if answer generated successfully, False otherwise
        """
        logger.info(
            f"[Tier 4] Generating GPT answer for question {question_id}: "
            f"{question_text[:50]}..."
        )

        try:
            # Generate answer with timeout
            result = await asyncio.wait_for(
                self._call_gpt_for_answer(
                    question_text=question_text,
                    speaker=speaker,
                    meeting_context=meeting_context
                ),
                timeout=self.timeout
            )

            if not result:
                logger.warning(f"GPT failed to generate answer for {question_id}")
                return False

            answer = result.get("answer", "")
            confidence = result.get("confidence", 0.0)
            disclaimer = result.get("disclaimer", "")

            # Check confidence threshold
            if confidence < self.confidence_threshold:
                logger.info(
                    f"GPT answer confidence ({confidence:.2f}) below threshold "
                    f"({self.confidence_threshold}) for {question_id}"
                )
                return False

            logger.info(
                f"[Tier 4] GPT generated answer with confidence {confidence:.2f} "
                f"for question {question_id}"
            )

            # Update database if session provided
            if db_session:
                await self._update_question_with_gpt_answer(
                    db_session=db_session,
                    question_id=question_id,
                    answer=answer,
                    confidence=confidence,
                    disclaimer=disclaimer
                )

            # Broadcast to WebSocket clients
            if self.broadcast_callback:
                await self._broadcast_gpt_answer(
                    session_id=session_id,
                    question_id=question_id,
                    answer=answer,
                    confidence=confidence,
                    disclaimer=disclaimer
                )

            return True

        except asyncio.TimeoutError:
            logger.warning(
                f"GPT answer generation timeout ({self.timeout}s) for {question_id}"
            )
            return False
        except Exception as e:
            logger.error(
                f"Error generating GPT answer for {question_id}: {e}",
                exc_info=True
            )
            return False

    async def _call_gpt_for_answer(
        self,
        question_text: str,
        speaker: Optional[str] = None,
        meeting_context: Optional[str] = None
    ) -> Optional[Dict[str, Any]]:
        """
        Call GPT-5-mini to generate an answer.

        Args:
            question_text: The question to answer
            speaker: Speaker who asked the question
            meeting_context: Brief meeting context

        Returns:
            Dict with answer, confidence, and disclaimer, or None on failure
        """
        try:
            # Get multi-LLM client (fallback provider for background tasks)
            llm_client = get_multi_llm_client()

            # Build prompt
            system_prompt = self._build_system_prompt()
            user_prompt = self._build_user_prompt(
                question_text=question_text,
                speaker=speaker,
                meeting_context=meeting_context
            )

            logger.debug(f"Calling GPT-5-mini with question: {question_text[:100]}...")

            # Call GPT (non-streaming)
            response = await llm_client.create_message(
                prompt=user_prompt,
                system_prompt=system_prompt,
                session=None,  # No session for background task
                organization_id=None,
                temperature=0.7,  # Balanced creativity and consistency
                max_tokens=300,  # Concise answers
                response_format={"type": "json_object"}
            )

            # Parse response
            if not response or not response.get("content"):
                logger.warning("GPT returned empty response")
                return None

            content = response["content"]

            # Try to parse as JSON
            try:
                result = json.loads(content)

                # Validate required fields
                if "answer" not in result:
                    logger.warning("GPT response missing 'answer' field")
                    return None

                # Normalize confidence to 0-1 range if needed
                confidence = result.get("confidence", 0.0)
                if confidence > 1.0:
                    confidence = confidence / 100.0

                return {
                    "answer": result.get("answer", ""),
                    "confidence": confidence,
                    "disclaimer": result.get(
                        "disclaimer",
                        "This answer was generated by AI based on general knowledge, "
                        "not from your documents or meeting."
                    )
                }

            except json.JSONDecodeError as e:
                logger.error(f"Failed to parse GPT response as JSON: {e}")
                logger.debug(f"GPT response: {content[:500]}")
                return None

        except Exception as e:
            logger.error(f"Error calling GPT for answer: {e}", exc_info=True)
            return None

    def _build_system_prompt(self) -> str:
        """Build system prompt for GPT answer generation."""
        return """You are an AI assistant helping answer questions during meetings.

Generate concise, helpful answers to questions that couldn't be answered from:
- Organization documents (RAG search)
- Previous meeting transcript
- Subsequent live conversation

Provide answers based on general knowledge when appropriate. Be honest about
limitations and suggest verification when needed.

Respond in JSON format with:
- "answer": Your concise answer (2-3 sentences max)
- "confidence": Confidence score 0-100 (only answer if >70)
- "disclaimer": Acknowledgment that this is AI-generated

IMPORTANT:
- Do NOT fabricate specific company data or internal information
- Acknowledge uncertainty when appropriate
- Suggest where to find authoritative information if possible
- Be concise and actionable"""

    def _build_user_prompt(
        self,
        question_text: str,
        speaker: Optional[str] = None,
        meeting_context: Optional[str] = None
    ) -> str:
        """
        Build user prompt for GPT answer generation.

        Args:
            question_text: The question to answer
            speaker: Speaker who asked the question
            meeting_context: Brief meeting context

        Returns:
            Formatted user prompt
        """
        prompt_parts = [
            f"Question: {question_text}",
        ]

        if speaker:
            prompt_parts.append(f"Asked by: {speaker}")

        if meeting_context:
            prompt_parts.append(f"Meeting context: {meeting_context}")

        prompt_parts.extend([
            "",
            "This question was asked during a live meeting. No answer was found in:",
            "- Organization documents (RAG)",
            "- Previous meeting transcript",
            "- Subsequent live conversation (15 second window)",
            "",
            "Generate a helpful answer based on general knowledge. Be concise and "
            "indicate if information should be verified with the team.",
            "",
            'Response format: {"answer": "...", "confidence": 0-100, "disclaimer": "..."}'
        ])

        return "\n".join(prompt_parts)

    async def _update_question_with_gpt_answer(
        self,
        db_session: Session,
        question_id: str,
        answer: str,
        confidence: float,
        disclaimer: str
    ):
        """
        Update question in database with GPT-generated answer.

        Args:
            db_session: Database session
            question_id: Question ID
            answer: Generated answer
            confidence: Confidence score
            disclaimer: Disclaimer text
        """
        try:
            question = db_session.query(LiveMeetingInsight).filter_by(
                id=question_id
            ).first()

            if not question:
                logger.warning(f"Question {question_id} not found in database")
                return

            # Update status to FOUND (answer was generated)
            question.update_status(InsightStatus.FOUND.value)

            # Set answer source
            question.set_answer_source(
                AnswerSource.GPT_GENERATED.value,
                confidence
            )

            # Add tier result
            question.add_tier_result(
                tier_type="gpt_generated",
                result_data={
                    "answer": answer,
                    "confidence": confidence,
                    "disclaimer": disclaimer,
                    "timestamp": datetime.utcnow().isoformat(),
                    "model": "gpt-5-mini"
                }
            )

            db_session.commit()

            logger.info(
                f"Updated question {question_id} with GPT-generated answer "
                f"(confidence: {confidence:.2f})"
            )

        except Exception as e:
            logger.error(
                f"Error updating question {question_id} with GPT answer: {e}",
                exc_info=True
            )
            db_session.rollback()

    async def _broadcast_gpt_answer(
        self,
        session_id: str,
        question_id: str,
        answer: str,
        confidence: float,
        disclaimer: str
    ):
        """
        Broadcast GPT-generated answer via WebSocket.

        Args:
            session_id: Meeting session ID
            question_id: Question ID
            answer: Generated answer
            confidence: Confidence score
            disclaimer: Disclaimer text
        """
        if not self.broadcast_callback:
            logger.debug("No broadcast callback configured, skipping")
            return

        try:
            event_data = {
                "type": "GPT_GENERATED_ANSWER",
                "question_id": question_id,
                "data": {
                    "answer": answer,
                    "confidence": confidence,
                    "disclaimer": disclaimer,
                    "source": "gpt_generated",
                    "model": "gpt-5-mini"
                },
                "timestamp": datetime.utcnow().isoformat()
            }

            await self.broadcast_callback(session_id, event_data)

            logger.info(
                f"Broadcast GPT-generated answer for question {question_id} "
                f"to session {session_id}"
            )

        except Exception as e:
            logger.error(
                f"Error broadcasting GPT answer for {question_id}: {e}",
                exc_info=True
            )
