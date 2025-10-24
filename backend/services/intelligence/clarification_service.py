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

        # Use LLM to customize questions based on context
        prompt = f"""Given this vague statement from a meeting, generate 2-3 specific clarifying questions.

Statement: "{statement}"
Context: {context if context else "No additional context"}
Vagueness Type: {vagueness_type}

Base question templates:
{chr(10).join(f"- {q}" for q in base_questions)}

Generate 2-3 specific, actionable clarifying questions for this statement.
Make them relevant to the statement and context.
Return ONLY a JSON array of strings.

Example format:
["What is the specific launch date?", "Who will coordinate the launch?"]
"""

        try:
            response = await self.llm_client.create_message(
                prompt=prompt,
                max_tokens=200,
                temperature=0.5
            )

            response_text = response.content[0].text.strip()

            # Handle empty response
            if not response_text:
                logger.warning("Empty response from LLM clarification generation")
                questions = base_questions[:3]
            else:
                # Try to extract JSON if wrapped in markdown code blocks
                if response_text.startswith('```'):
                    lines = response_text.split('\n')
                    json_lines = [line for line in lines if line and not line.startswith('```')]
                    response_text = '\n'.join(json_lines).strip()

                # Try to parse JSON
                try:
                    questions = json.loads(response_text)
                    if isinstance(questions, list) and len(questions) > 0:
                        # Validate all items are strings
                        questions = [str(q) for q in questions if q]
                    else:
                        questions = base_questions[:3]
                except json.JSONDecodeError as e:
                    logger.warning(f"Failed to parse LLM response as JSON: {e}")
                    logger.debug(f"Response text was: {response_text[:200]}")
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

        prompt = f"""Analyze this statement from a meeting for vagueness or missing information.

Statement: "{statement}"
Context: {context if context else "No additional context"}

Is this statement vague or missing critical details?
If yes, what type of information is missing?

Types: time, assignment, detail, scope

Response format (JSON):
{{
    "is_vague": true/false,
    "type": "time/assignment/detail/scope",
    "confidence": 0.0-1.0,
    "missing_info": "description of what's missing"
}}

If not vague, respond: {{"is_vague": false}}
"""

        try:
            response = await self.llm_client.create_message(
                prompt=prompt,
                max_tokens=150,
                temperature=0.3
            )

            response_text = response.content[0].text.strip()

            # Handle empty or invalid response
            if not response_text:
                logger.warning("Empty response from LLM vagueness detection")
                return None

            # Try to extract JSON if wrapped in markdown code blocks
            if response_text.startswith('```'):
                # Extract JSON from markdown code block
                lines = response_text.split('\n')
                json_lines = [line for line in lines if line and not line.startswith('```')]
                response_text = '\n'.join(json_lines).strip()

            result = json.loads(response_text)

            if result.get('is_vague') and result.get('confidence', 0) >= 0.6:
                vague_type = result.get('type', 'detail')
                # Validate type
                if vague_type not in ['time', 'assignment', 'detail', 'scope']:
                    vague_type = 'detail'

                return await self._generate_clarification(
                    statement=statement,
                    vagueness_type=vague_type,
                    context=context,
                    confidence=result['confidence']
                )
        except json.JSONDecodeError as e:
            logger.warning(f"Failed to parse LLM vagueness detection response: {e}")
            logger.debug(f"Response text was: {response_text[:200] if response_text else 'None'}")
        except Exception as e:
            logger.error(f"Error in LLM vagueness detection: {e}")

        return None
