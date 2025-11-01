"""
Answer Handler Service

Processes answer detection events from GPT stream, matches answers to active questions,
and updates question status to answered when confident matches are found.

Author: TellMeMo Team
Created: 2025-10-26
"""

import logging
from typing import Any, Callable, Dict, Optional
from datetime import datetime, timezone
from uuid import UUID

from sqlalchemy import and_, select
from sqlalchemy.ext.asyncio import AsyncSession

from db.database import get_db_context
from models.live_insight import (
    AnswerSource,
    InsightStatus,
    InsightType,
    LiveMeetingInsight,
)

logger = logging.getLogger(__name__)


class AnswerHandler:
    """
    Handles answer detection events from GPT stream.

    Responsibilities:
    - Match answers to active questions semantically
    - Update question status to ANSWERED when confidence > 85%
    - Remove questions from active tracking
    - Broadcast resolution events to clients
    - Store answer source and timestamp
    """

    def __init__(
        self,
        question_handler: Optional[Any] = None,
        confidence_threshold: float = 0.85,
        tier_config: Optional[Dict[str, bool]] = None
    ):
        """
        Initialize AnswerHandler.

        Args:
            question_handler: QuestionHandler instance for monitoring cancellation
            confidence_threshold: Minimum confidence to mark as answered (default: 0.85)
            tier_config: Dictionary of tier enablement status (e.g., {'live_conversation': True})
        """
        self._question_handler = question_handler
        self._confidence_threshold = confidence_threshold
        self._ws_broadcast_callback: Optional[Callable] = None

        # Tier configuration (default all enabled if not provided)
        self._tier_config = tier_config or {
            'rag': True,
            'meeting_context': True,
            'live_conversation': True,
            'gpt_generated': True
        }

        # Metrics
        self.answers_processed = 0
        self.questions_resolved = 0
        self.low_confidence_answers = 0
        self.skipped_disabled_tier_answers = 0

        logger.info(
            f"AnswerHandler initialized with confidence threshold: {confidence_threshold}, "
            f"tier_config: {self._tier_config}"
        )

    def set_websocket_callback(self, callback: Callable) -> None:
        """Set the WebSocket broadcast callback."""
        self._ws_broadcast_callback = callback
        logger.debug("WebSocket callback registered with AnswerHandler")

    def set_question_handler(self, question_handler: Any) -> None:
        """Set the QuestionHandler for monitoring cancellation."""
        self._question_handler = question_handler
        logger.debug("QuestionHandler registered with AnswerHandler")

    async def handle_answer(
        self,
        answer_obj: Dict[str, Any],
        session_id: str
    ) -> Optional[str]:
        """
        Process answer event from GPT stream.

        Args:
            answer_obj: Answer object from GPT with structure:
                {
                    "type": "answer",
                    "question_id": "q_{uuid}",
                    "answer_text": "The answer text",
                    "speaker": "Speaker B",
                    "timestamp": "2025-10-26T10:30:00Z",
                    "confidence": 0.92
                }
            session_id: Meeting session identifier

        Returns:
            Database question ID (UUID str) if successfully matched and updated, None otherwise
        """
        self.answers_processed += 1

        try:
            # Extract fields
            question_gpt_id = answer_obj.get("question_id")
            answer_text = answer_obj.get("answer_text")
            timestamp_str = answer_obj.get("timestamp")
            confidence = answer_obj.get("confidence", 0.9)

            # Validate required fields
            if not question_gpt_id or not answer_text:
                logger.warning(
                    f"Answer object missing required fields: {answer_obj}"
                )
                return None

            # Check if live conversation tier is enabled
            # (answers from GPT stream are from live conversation monitoring)
            if not self._tier_config.get('live_conversation', True):
                self.skipped_disabled_tier_answers += 1
                logger.info(
                    f"Skipping answer from live conversation (Tier 4 disabled) for question {question_gpt_id}"
                )
                return None

            # Parse timestamp
            try:
                timestamp = datetime.fromisoformat(
                    timestamp_str.replace('Z', '+00:00')
                ) if timestamp_str else datetime.now(timezone.utc)
            except (ValueError, AttributeError):
                timestamp = datetime.now(timezone.utc)

            # Check confidence threshold
            if confidence < self._confidence_threshold:
                self.low_confidence_answers += 1
                logger.info(
                    f"Answer confidence ({confidence:.2f}) below threshold "
                    f"({self._confidence_threshold:.2f}) for question {question_gpt_id}. "
                    "Skipping question resolution."
                )
                return None

            logger.info(
                f"Processing answer for question {question_gpt_id} "
                f"(confidence: {confidence:.2f}, session: {session_id})"
            )

            # Find and update question in database
            db_question_id = await self._update_question_status(
                session_id=session_id,
                question_gpt_id=question_gpt_id,
                answer_text=answer_text,
                timestamp=timestamp,
                confidence=confidence
            )

            if not db_question_id:
                logger.warning(
                    f"Question {question_gpt_id} not found in database. "
                    "Cannot mark as answered."
                )
                return None

            # Signal Tier 4 live monitoring that answer was detected
            if self._question_handler:
                try:
                    # Signal the monitoring task (this will set the asyncio.Event)
                    self._question_handler.signal_answer_detected(
                        session_id, str(db_question_id)
                    )
                    logger.debug(
                        f"Signaled answer detection for question {db_question_id}"
                    )
                except Exception as e:
                    logger.warning(
                        f"Failed to signal answer detection for question {db_question_id}: {e}"
                    )

            # Broadcast answer detected event
            await self._broadcast_answer_detected(
                session_id=session_id,
                question_id=str(db_question_id),
                answer_text=answer_text,
                confidence=confidence
            )

            self.questions_resolved += 1
            logger.info(
                f"Question {db_question_id} marked as answered "
                f"(total resolved: {self.questions_resolved})"
            )

            return str(db_question_id)

        except Exception as e:
            logger.error(
                f"Error processing answer for session {session_id}: {e}",
                exc_info=True
            )
            return None

    async def _update_question_status(
        self,
        session_id: str,
        question_gpt_id: str,
        answer_text: str,
        timestamp: datetime,
        confidence: float
    ) -> Optional[UUID]:
        """
        Find question in database and update status to ANSWERED.

        Args:
            session_id: Meeting session identifier
            question_gpt_id: GPT-generated question ID (e.g., "q_abc123...")
            answer_text: The answer text
            timestamp: When the answer was detected
            confidence: Confidence score of the match

        Returns:
            Database question UUID if found and updated, None otherwise

        Note: Speaker diarization not supported in streaming API.
        """
        try:
            async with get_db_context() as db_session:
                # Find question by gpt_id in metadata
                result = await db_session.execute(
                    select(LiveMeetingInsight).where(
                        and_(
                            LiveMeetingInsight.session_id == session_id,
                            LiveMeetingInsight.insight_type == InsightType.QUESTION,
                            LiveMeetingInsight.insight_metadata['gpt_id'].astext == question_gpt_id
                        )
                    )
                )
                question = result.scalar_one_or_none()

                if not question:
                    logger.warning(
                        f"Question with gpt_id '{question_gpt_id}' not found "
                        f"in session {session_id}"
                    )
                    return None

                # Update question status to ANSWERED
                question.update_status(InsightStatus.ANSWERED.value)

                # Set answer source
                question.set_answer_source(
                    AnswerSource.LIVE_CONVERSATION.value,
                    confidence
                )

                # Add tier result with answer details
                # Note: Speaker diarization not supported in streaming API
                question.add_tier_result(
                    tier_type="live_conversation",
                    result_data={
                        "answer": answer_text,
                        "timestamp": timestamp.isoformat(),
                        "confidence": confidence,
                        "source": "live_conversation"
                    }
                )

                logger.debug(
                    f"Updated question {question.id} to ANSWERED status "
                    f"(gpt_id: {question_gpt_id})"
                )

                return question.id

        except Exception as e:
            logger.error(
                f"Database error updating question status: {e}",
                exc_info=True
            )
            return None

    async def _broadcast_answer_detected(
        self,
        session_id: str,
        question_id: str,
        answer_text: str,
        confidence: float
    ) -> None:
        """
        Broadcast answer detected event immediately, then fetch complete data.

        This uses a two-phase approach for better UX responsiveness:
        1. Immediate broadcast with essential answer data
        2. Optional DB fetch for complete question object (best-effort)

        Args:
            session_id: Meeting session identifier
            question_id: Database question UUID
            answer_text: The answer text
            confidence: Confidence score

        Note: Speaker diarization not supported in streaming API.
        """
        if not self._ws_broadcast_callback:
            logger.debug("No WebSocket callback configured, skipping broadcast")
            return

        try:
            # ========================================================================
            # PHASE 1: Immediate broadcast with answer data (fast user feedback)
            # ========================================================================
            # Broadcast QUESTION_ANSWERED_LIVE (Tier 4 - live conversation monitoring)
            # This is distinct from ANSWER_FROM_MEETING (Tier 2) and provides clear
            # indication that the answer was found through live conversation monitoring
            event_data = {
                "type": "QUESTION_ANSWERED_LIVE",
                "question_id": question_id,
                "data": {
                    "answer_text": answer_text,
                    "speaker": speaker,
                    "confidence": confidence,
                    "source": "live_conversation",
                    "tier": "live_conversation",
                    "label": "👂 Answered Live",
                    "timestamp": datetime.now(timezone.utc).isoformat()
                },
                "timestamp": datetime.now(timezone.utc).isoformat()
            }

            await self._ws_broadcast_callback(session_id, event_data)
            logger.debug(
                f"Broadcasted QUESTION_ANSWERED_LIVE event for question {question_id}"
            )

            # ========================================================================
            # PHASE 2: Fetch complete question object (best-effort enrichment)
            # ========================================================================
            # Try to fetch full question data from database for richer client display
            # If this fails, user still got the essential answer information above
            try:
                from db.database import get_db_context
                from sqlalchemy import select

                async with get_db_context() as db_session:
                    result = await db_session.execute(
                        select(LiveMeetingInsight).where(
                            LiveMeetingInsight.id == UUID(question_id)
                        )
                    )
                    question = result.scalar_one_or_none()

                    if question:
                        # Broadcast complete question object as follow-up enrichment
                        question_dict = question.to_dict()
                        enriched_event = {
                            "type": "QUESTION_ANSWERED_LIVE",
                            "data": question_dict,
                            "timestamp": datetime.now(timezone.utc).isoformat()
                        }
                        await self._ws_broadcast_callback(session_id, enriched_event)
                        logger.debug(
                            f"Broadcasted enriched QUESTION_ANSWERED_LIVE data for question {question_id}"
                        )
                    else:
                        logger.debug(
                            f"Question {question_id} not yet available in DB for enrichment - "
                            f"client received essential answer data"
                        )

            except Exception as enrichment_error:
                # Enrichment is optional - log but don't fail
                logger.debug(
                    f"Could not fetch enriched data for question {question_id}: "
                    f"{enrichment_error}"
                )

        except Exception as e:
            logger.error(f"Failed to broadcast answer event: {e}", exc_info=True)

    async def cleanup_session(self, session_id: str) -> None:
        """
        Clean up resources for a session.

        Args:
            session_id: Meeting session identifier
        """
        logger.info(f"Cleaning up AnswerHandler resources for session {session_id}")
        # No session-specific state to clean up currently

    def get_metrics(self) -> Dict[str, int]:
        """Get handler metrics."""
        return {
            "answers_processed": self.answers_processed,
            "questions_resolved": self.questions_resolved,
            "low_confidence_answers": self.low_confidence_answers,
            "skipped_disabled_tier_answers": self.skipped_disabled_tier_answers
        }
