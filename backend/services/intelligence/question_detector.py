"""
Question Detection Service

Detects and classifies questions from meeting transcripts.
Supports both explicit questions (with ?) and implicit questions.
"""

from dataclasses import dataclass
from typing import Optional, List
import re
import logging

logger = logging.getLogger(__name__)


@dataclass
class DetectedQuestion:
    """A detected question from the transcript"""
    text: str
    type: str  # 'factual', 'decision', 'process', 'clarification', 'general'
    confidence: float  # 0.0 to 1.0
    context: str  # Surrounding context


class QuestionDetector:
    """Enhanced question detection with classification"""

    QUESTION_TYPES = {
        'factual': ['what', 'when', 'where', 'who', 'which'],
        'decision': ['should we', 'can we', 'do we need', 'is it worth', 'would it be better'],
        'process': ['how do we', 'what\'s the process', 'what are the steps', 'how can we'],
        'clarification': ['can you clarify', 'what do you mean', 'could you explain']
    }

    def __init__(self, llm_client):
        self.llm_client = llm_client

    async def detect_and_classify_question(
        self,
        text: str,
        context: str = ""
    ) -> Optional[DetectedQuestion]:
        """
        Detect if text contains a question and classify it.
        Returns None if not a question.
        """
        # 1. Use regex patterns for explicit questions
        explicit_question = self._check_explicit_question(text)

        if explicit_question:
            question_type = self._classify_question_type(explicit_question)
            return DetectedQuestion(
                text=explicit_question,
                type=question_type,
                confidence=0.9,
                context=context
            )

        # 2. Use LLM for implicit questions
        implicit_question = await self._detect_implicit_question(text, context)
        if implicit_question:
            question_type = self._classify_question_type(implicit_question)
            return DetectedQuestion(
                text=implicit_question,
                type=question_type,
                confidence=0.7,
                context=context
            )

        return None

    def _check_explicit_question(self, text: str) -> Optional[str]:
        """Check for explicit question patterns"""
        # Question mark at end
        if '?' in text:
            # Extract sentence with question mark
            sentences = re.split(r'[.!]', text)
            for sent in sentences:
                if '?' in sent:
                    return sent.strip().rstrip('?').strip() + '?'

        # Question words at start
        text_lower = text.lower().strip()
        question_words = [
            'what', 'when', 'where', 'who', 'why', 'how', 'which',
            'can', 'should', 'do', 'is', 'are', 'could', 'would', 'will'
        ]

        for q_word in question_words:
            if text_lower.startswith(q_word + ' '):
                return text
            # Check for "can we", "should we" patterns
            if text_lower.startswith(q_word):
                return text

        return None

    async def _detect_implicit_question(
        self,
        text: str,
        context: str
    ) -> Optional[str]:
        """Use LLM to detect implicit questions"""
        prompt = f"""Analyze this statement and determine if it's an implicit question.

Statement: "{text}"

Context: {context[:300] if context else 'None'}

Is this an implicit question? If yes, rephrase as explicit question.
If no, respond with "NOT_A_QUESTION".

Examples:
- "I'm not sure about the deadline" → "What is the deadline?"
- "We need to know the budget" → "What is the budget?"
- "That's a good point" → "NOT_A_QUESTION"

Response (one line):"""

        try:
            response = await self.llm_client.create_message(
                prompt=prompt,
                max_tokens=100,
                temperature=0.3
            )

            answer = response.content[0].text.strip()
            if answer == "NOT_A_QUESTION" or not answer:
                return None

            return answer
        except Exception as e:
            logger.error(f"Failed to detect implicit question: {e}")
            return None

    def _classify_question_type(self, question: str) -> str:
        """Classify question into type for better answering"""
        question_lower = question.lower()

        for q_type, keywords in self.QUESTION_TYPES.items():
            if any(kw in question_lower for kw in keywords):
                return q_type

        return 'general'
