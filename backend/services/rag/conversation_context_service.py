"""Conversation context service for handling follow-up questions and context-aware RAG."""

import re
from typing import List, Dict, Any, Optional, Tuple
from datetime import datetime
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from models.conversation import Conversation
from services.llm.multi_llm_client import get_multi_llm_client
from utils.logger import get_logger, sanitize_for_log

logger = get_logger(__name__)


class ConversationContextService:
    """Service for managing conversation context and follow-up detection."""

    def __init__(self):
        self.llm_client = get_multi_llm_client()

        # Follow-up detection patterns
        self.followup_patterns = [
            r'\b(what|why|how|when|where|who|which)\s+(about|for|of)\s+(that|this|those|these|it|them)\b',
            r'\b(tell me more|explain|elaborate|details?|expand)\b',
            r'\b(and|also|additionally|furthermore|moreover)\b',
            r'\b(those|these|that|this|it|them)\b',
            r'\b(previous|earlier|before|above|mentioned)\b',
            r'\b(continue|keep going|go on)\b',
            r'\b(what else|anything else|more)\b',
        ]

        # Context keywords that indicate reference to previous content
        self.context_keywords = [
            'that', 'this', 'those', 'these', 'it', 'them', 'they',
            'above', 'previous', 'earlier', 'mentioned', 'said',
            'why', 'how', 'what about', 'tell me more', 'explain'
        ]

    async def detect_followup_question(self, question: str, conversation_messages: List[Dict]) -> bool:
        """
        Detect if a question is a follow-up to previous conversation.

        Args:
            question: The user's question
            conversation_messages: Previous messages in conversation

        Returns:
            True if this appears to be a follow-up question
        """
        if not conversation_messages:
            return False

        question_lower = question.lower().strip()

        # Pattern-based detection for obvious follow-ups
        for pattern in self.followup_patterns:
            if re.search(pattern, question_lower, re.IGNORECASE):
                logger.debug(f"Follow-up detected by pattern: {pattern}")
                return True

        # Check for context keywords
        for keyword in self.context_keywords:
            if keyword in question_lower:
                logger.debug(f"Follow-up detected by keyword: {keyword}")
                return True

        # Check if question is very short (likely follow-up)
        if len(question.split()) <= 3 and any(word in question_lower for word in ['why', 'how', 'what', 'more']):
            logger.debug("Follow-up detected by short question pattern")
            return True

        # Use LLM for more sophisticated detection if patterns don't match
        if len(conversation_messages) > 0:
            return await self._llm_based_followup_detection(question, conversation_messages)

        return False

    async def _llm_based_followup_detection(self, question: str, conversation_messages: List[Dict]) -> bool:
        """Use LLM to detect follow-up questions more accurately."""
        try:
            # Get last 2 Q&A pairs for context
            recent_context = conversation_messages[-2:] if len(conversation_messages) >= 2 else conversation_messages

            context_text = ""
            for msg in recent_context:
                context_text += f"Q: {msg.get('question', '')}\nA: {msg.get('answer', '')[:200]}...\n\n"

            prompt = f"""Given this conversation context:

{context_text}

Is this new question a follow-up that references or builds upon the previous conversation?
Question: "{question}"

Consider it a follow-up if it:
- Uses pronouns or references like "that", "this", "it", "them"
- Asks for more details about something previously discussed
- Continues a line of questioning
- Would be unclear without the previous context

Answer only: YES or NO"""

            response = await self.llm_client.generate_response(
                prompt,
                max_tokens=10,
                temperature=0.1
            )

            result = response.strip().upper().startswith('YES')
            logger.debug(f"LLM follow-up detection: {result}")
            return result

        except Exception as e:
            logger.warning(f"LLM follow-up detection failed: {e}")
            return False

    async def enhance_query_with_context(
        self,
        question: str,
        conversation_messages: List[Dict],
        max_context_pairs: int = 3,
        max_context_length: int = 1200
    ) -> str:
        """
        Enhance a follow-up question with conversation context.

        Args:
            question: The user's question
            conversation_messages: Previous messages in conversation
            max_context_pairs: Maximum number of Q&A pairs to include
            max_context_length: Maximum total length of context

        Returns:
            Enhanced question with context
        """
        if not conversation_messages:
            return question

        # Get recent context (last N Q&A pairs)
        recent_messages = conversation_messages[-max_context_pairs:]

        # Build context summary with strict length limits
        context_parts = []
        total_context_length = 0

        for i, msg in enumerate(recent_messages):
            q = msg.get('question', '')
            a = msg.get('answer', '')

            # Truncate question if too long
            if len(q) > 200:
                q = q[:200] + "..."

            # Truncate answer for context
            if len(a) > 400:
                a = a[:400] + "..."

            context_part = f"Q{i+1}: {q}\nA{i+1}: {a}"

            # Check if adding this would exceed max length
            if total_context_length + len(context_part) > max_context_length:
                break

            context_parts.append(context_part)
            total_context_length += len(context_part)

        context_text = "\n\n".join(context_parts)

        # Create a more concise enhanced query for better search
        enhanced_query = f"""Context: {context_text}

Question: {question}"""

        logger.info(f"Enhanced query created with {len(context_parts)} context pairs, {len(enhanced_query)} chars")
        logger.debug(f"Original: {sanitize_for_log(question)}")
        logger.debug(f"Enhanced: {sanitize_for_log(enhanced_query[:200])}...")

        return enhanced_query

    async def get_conversation_context(
        self,
        conversation_id: str,
        session: AsyncSession,
        organization_id: str
    ) -> Tuple[Optional[Conversation], List[Dict]]:
        """
        Get conversation and its messages for context.

        Args:
            conversation_id: UUID of the conversation
            session: Database session
            organization_id: Organization ID for security

        Returns:
            Tuple of (conversation, messages_list)
        """
        try:
            result = await session.execute(
                select(Conversation).where(
                    Conversation.id == conversation_id,
                    Conversation.organization_id == organization_id
                )
            )
            conversation = result.scalar_one_or_none()

            if not conversation:
                logger.warning(f"Conversation {sanitize_for_log(conversation_id)} not found")
                return None, []

            messages = conversation.messages or []
            logger.debug(f"Retrieved conversation with {len(messages)} messages")

            return conversation, messages

        except Exception as e:
            logger.error(f"Failed to get conversation context: {e}")
            return None, []

    async def should_use_context_aware_search(
        self,
        question: str,
        conversation_messages: List[Dict]
    ) -> bool:
        """
        Determine if query should use context-aware search.

        Args:
            question: The user's question
            conversation_messages: Previous messages in conversation

        Returns:
            True if context-aware search should be used
        """
        # Always use context-aware search if there are previous messages
        # and the question appears to be a follow-up
        if conversation_messages:
            is_followup = await self.detect_followup_question(question, conversation_messages)
            logger.info(f"Context-aware search recommended: {is_followup}")
            return is_followup

        return False

    def create_conversation_title(self, first_question: str) -> str:
        """
        Create a conversation title from the first question.

        Args:
            first_question: The first question in the conversation

        Returns:
            Generated title
        """
        # Clean and truncate the question for a title
        title = first_question.strip()

        # Remove question marks and extra whitespace (ReDoS-safe)
        title = title.rstrip('?!')
        title = ' '.join(title.split())

        # Truncate if too long
        if len(title) > 50:
            title = title[:47] + "..."

        return title

    def format_message_for_storage(
        self,
        question: str,
        answer: str,
        sources: List[str],
        confidence: float
    ) -> Dict[str, Any]:
        """
        Format a Q&A pair for storage in conversation.

        Args:
            question: User question
            answer: System answer
            sources: List of source references
            confidence: Confidence score

        Returns:
            Formatted message dict
        """
        return {
            "question": question,
            "answer": answer,
            "sources": sources,
            "confidence": confidence,
            "timestamp": datetime.utcnow().isoformat(),
            "isAnswerPending": False
        }


# Global service instance
conversation_context_service = ConversationContextService()