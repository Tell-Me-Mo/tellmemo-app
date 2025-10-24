"""
Clarification Service - Detects vague statements and suggests clarifying questions.

This service analyzes insights (especially action items and decisions) for vagueness
and generates context-specific clarifying questions to help teams avoid ambiguity.
"""

from dataclasses import dataclass
from typing import List, Optional
import re
import logging
import json

logger = logging.getLogger(__name__)


@dataclass
class ClarificationSuggestion:
    """Suggestion for clarifying a vague statement"""
    statement: str
    vagueness_type: str  # 'time', 'assignment', 'detail', 'scope'
    confidence: float
    suggested_questions: List[str]
    reasoning: str


class ClarificationService:
    """Service for detecting vague statements and suggesting clarifications"""

    VAGUE_PATTERNS = {
        'time': [
            r'\b(soon|later|eventually|sometime|next week|next month)\b',
            r'\b(probably|maybe|might)\s+(next|this)\s+(week|month)\b',
            r'\basap\b',
            r'\bwhen (we|you) (can|have time)\b'
        ],
        'assignment': [
            r'\b(someone|somebody)\s+(should|needs to|has to|will|must)\b',
            r'\bwe need to\b(?!\s+(discuss|talk|meet))',  # "we need to" without discussion context
            r'\bit would be good if\b',
            r'\bsomeone can\b',
            r'\banyone (can|should|could)\b'
        ],
        'detail': [
            r'\bthe (bug|issue|problem)(?!\s+(with|in|about|is|was))',  # "the bug" without context
            r'\bthat (feature|thing|stuff|item)\b',
            r'\bthis (needs to be|should be|has to be)\b(?!\s+\w+ed)',  # vague action without specifics
            r'\b(fix|update|improve|enhance) (it|this|that)\b'
        ],
        'scope': [
            r'\b(probably|maybe|might|possibly|perhaps)\b',
            r'\bkind of|sort of\b',
            r'\bI think\b(?!\s+(we should|it\'s))',
            r'\bnot sure (if|whether|about)\b'
        ]
    }

    CLARIFICATION_TEMPLATES = {
        'time': [
            "What is the specific deadline or target date?",
            "By when should this be completed?",
            "What's the timeframe for this?"
        ],
        'assignment': [
            "Who specifically will handle this?",
            "Who is the owner for this task?",
            "Which team member will be responsible?"
        ],
        'detail': [
            "Can you provide more specifics?",
            "What are the exact details or requirements?",
            "Which specific item are you referring to?"
        ],
        'scope': [
            "What level of certainty do we have?",
            "Should we treat this as confirmed or tentative?",
            "Do we need to make a firm decision on this?"
        ]
    }

    def __init__(self, llm_client):
        self.llm_client = llm_client

    async def detect_vagueness(
        self,
        statement: str,
        context: str = ""
    ) -> Optional[ClarificationSuggestion]:
        """
        Detect if a statement is vague and needs clarification.
        Returns None if statement is clear enough.
        """
        if not statement or len(statement.strip()) < 5:
            return None

        # Check pattern-based vagueness (fast, high precision)
        for vague_type, patterns in self.VAGUE_PATTERNS.items():
            for pattern in patterns:
                if re.search(pattern, statement, re.IGNORECASE):
                    logger.info(f"Detected {vague_type} vagueness via pattern: {pattern}")
                    return await self._generate_clarification(
                        statement=statement,
                        vagueness_type=vague_type,
                        context=context,
                        confidence=0.85
                    )

        # Use LLM for more subtle vagueness (slower, broader coverage)
        llm_result = await self._llm_detect_vagueness(statement, context)
        if llm_result:
            return llm_result

        return None

    async def _generate_clarification(
        self,
        statement: str,
        vagueness_type: str,
        context: str,
        confidence: float
    ) -> ClarificationSuggestion:
        """Generate clarifying questions for a vague statement"""

        # Get template questions
        base_questions = self.CLARIFICATION_TEMPLATES.get(vagueness_type, [
            "Can you provide more details?",
            "What specific information is needed?"
        ])

        # Escape quotes in statement and context for safety
        statement_escaped = statement.replace('"', '\\"').replace('\n', ' ')
        context_escaped = (context.replace('"', '\\"').replace('\n', ' ') if context else "No additional context")

        # Use LLM to customize questions based on context
        prompt = f"""Given this vague statement from a meeting, generate 2-3 specific clarifying questions.

Statement: {statement_escaped}
Context: {context_escaped}
Vagueness Type: {vagueness_type}

Base question templates:
{chr(10).join(f"- {q}" for q in base_questions)}

CRITICAL: You MUST respond with ONLY a JSON array. Absolutely NO additional text, explanations, or formatting.
Each question must be a complete sentence ending with a question mark.
Each question must use ONLY single quotes inside the JSON strings (never double quotes).

Example correct response (note: use \\\\ to escape backslashes):
["What is the specific launch date?", "Who will coordinate the launch?", "What are the success criteria?"]

JSON array:"""

        try:
            response = await self.llm_client.create_message(
                prompt=prompt,
                max_tokens=200,
                temperature=0.3  # Lower temperature for more consistent formatting
            )

            response_text = response.content[0].text.strip()

            # Handle empty response
            if not response_text:
                logger.warning("Empty response from LLM clarification generation")
                questions = base_questions[:3]
            else:
                # Remove markdown code blocks if present
                if '```' in response_text:
                    # Extract content between code blocks
                    match = re.search(r'```(?:json)?\s*\n?(.*?)\n?```', response_text, re.DOTALL)
                    if match:
                        response_text = match.group(1).strip()
                    else:
                        # Fallback: remove all ``` markers
                        response_text = re.sub(r'```(?:json)?', '', response_text).strip()

                # Remove any leading/trailing text that's not part of the JSON array
                # Find the first '[' and last ']'
                start_idx = response_text.find('[')
                end_idx = response_text.rfind(']')
                if start_idx != -1 and end_idx != -1 and end_idx > start_idx:
                    response_text = response_text[start_idx:end_idx+1]

                # Try to fix common JSON issues
                # Replace problematic contractions with escaped versions
                response_text = response_text.replace("we're", "we are").replace("it's", "it is")
                response_text = response_text.replace("you're", "you are").replace("they're", "they are")

                # Try to parse JSON
                try:
                    questions = json.loads(response_text)
                    if isinstance(questions, list) and len(questions) > 0:
                        # Validate all items are strings
                        questions = [str(q).strip() for q in questions if q and isinstance(q, str)]
                        if not questions:
                            logger.warning("LLM returned empty question list after filtering")
                            questions = base_questions[:3]
                    else:
                        logger.warning(f"LLM returned non-list or empty: {type(questions)}")
                        questions = base_questions[:3]
                except json.JSONDecodeError as e:
                    logger.warning(f"Failed to parse LLM clarification response: {e}")
                    logger.debug(f"Raw response: {response_text[:300]}")
                    # Last resort: try to extract questions manually using regex
                    matches = re.findall(r'"([^"]+\?)"', response_text)
                    if matches and len(matches) >= 2:
                        questions = matches[:3]
                        logger.info(f"Recovered {len(questions)} questions via regex extraction")
                    else:
                        questions = base_questions[:3]

        except Exception as e:
            logger.error(f"Error generating clarification questions: {e}")
            # Fallback to template questions
            questions = base_questions[:3]

        return ClarificationSuggestion(
            statement=statement,
            vagueness_type=vagueness_type,
            confidence=confidence,
            suggested_questions=questions[:3],  # Limit to 3 questions
            reasoning=f"Detected {vagueness_type} vagueness in statement"
        )

    async def _llm_detect_vagueness(
        self,
        statement: str,
        context: str
    ) -> Optional[ClarificationSuggestion]:
        """Use LLM to detect subtle vagueness"""

        # Escape quotes in statement and context for JSON safety
        statement_escaped = statement.replace('"', '\\"').replace('\n', ' ')
        context_escaped = (context.replace('"', '\\"').replace('\n', ' ') if context else "No additional context")

        prompt = f"""Analyze this statement from a meeting for vagueness or missing information.

Statement: {statement_escaped}
Context: {context_escaped}

Determine if the statement is vague or missing critical details.

CRITICAL: Respond with ONLY valid JSON. Absolutely NO additional text, explanations, or formatting.
Use simple alphanumeric descriptions in the missing_info field (no quotes or special characters).

Response format (if vague):
{{
    "is_vague": true,
    "type": "time",
    "confidence": 0.8,
    "missing_info": "needs specific deadline or timeframe"
}}

Valid types: time, assignment, detail, scope
Confidence: number between 0.0 and 1.0

If NOT vague, respond with: {{"is_vague": false}}

JSON response:"""

        try:
            response = await self.llm_client.create_message(
                prompt=prompt,
                max_tokens=150,
                temperature=0.2  # Very low temperature for consistent JSON
            )

            response_text = response.content[0].text.strip()

            # Handle empty or invalid response
            if not response_text:
                logger.warning("Empty response from LLM vagueness detection")
                return None

            # Remove markdown code blocks if present
            if '```' in response_text:
                match = re.search(r'```(?:json)?\s*\n?(.*?)\n?```', response_text, re.DOTALL)
                if match:
                    response_text = match.group(1).strip()
                else:
                    response_text = re.sub(r'```(?:json)?', '', response_text).strip()

            # Extract JSON object (find first { and last })
            start_idx = response_text.find('{')
            end_idx = response_text.rfind('}')
            if start_idx != -1 and end_idx != -1 and end_idx > start_idx:
                response_text = response_text[start_idx:end_idx+1]

            # Try to fix common JSON issues
            response_text = response_text.replace("we're", "we are").replace("it's", "it is")
            response_text = response_text.replace("'", "\\'")  # Escape single quotes

            result = json.loads(response_text)

            if result.get('is_vague') and result.get('confidence', 0) >= 0.7:  # Raised threshold from 0.6 to 0.7
                vague_type = result.get('type', 'detail')
                # Validate type
                if vague_type not in ['time', 'assignment', 'detail', 'scope']:
                    vague_type = 'detail'

                confidence = float(result.get('confidence', 0.7))

                # Only return if confidence is reasonably high
                if confidence < 0.7:
                    logger.debug(f"Vagueness confidence too low ({confidence:.2f}), skipping")
                    return None

                return await self._generate_clarification(
                    statement=statement,
                    vagueness_type=vague_type,
                    context=context,
                    confidence=confidence
                )
        except json.JSONDecodeError as e:
            logger.warning(f"Failed to parse LLM vagueness detection response: {e}")
            if 'response_text' in locals():
                logger.debug(f"Raw response: {response_text[:300]}")
        except Exception as e:
            logger.error(f"Error in LLM vagueness detection: {e}")

        return None
