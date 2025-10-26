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
        confidence_threshold: float = 0.85
    ):
        """
        Initialize AnswerHandler.

        Args:
            question_handler: QuestionHandler instance for monitoring cancellation
            confidence_threshold: Minimum confidence to mark as answered (default: 0.85)
        """
        self._question_handler = question_handler
        self._confidence_threshold = confidence_threshold
        self._ws_broadcast_callback: Optional[Callable] = None

        # Metrics
        self.answers_processed = 0
        self.questions_resolved = 0
        self.low_confidence_answers = 0

        logger.info(
            f"AnswerHandler initialized with confidence threshold: {confidence_threshold}"
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
            speaker = answer_obj.get("speaker")
            timestamp_str = answer_obj.get("timestamp")
            confidence = answer_obj.get("confidence", 0.9)

            # Validate required fields
            if not question_gpt_id or not answer_text:
                logger.warning(
                    f"Answer object missing required fields: {answer_obj}"
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
                speaker=speaker,
                timestamp=timestamp,
                confidence=confidence
            )

            if not db_question_id:
                logger.warning(
                    f"Question {question_gpt_id} not found in database. "
                    "Cannot mark as answered."
                )
                return None

            # Signal Tier 3 live monitoring that answer was detected
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
                speaker=speaker,
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
        speaker: Optional[str],
        timestamp: datetime,
        confidence: float
    ) -> Optional[UUID]:
        """
        Find question in database and update status to ANSWERED.

        Args:
            session_id: Meeting session identifier
            question_gpt_id: GPT-generated question ID (e.g., "q_abc123...")
            answer_text: The answer text
            speaker: Speaker who provided the answer
            timestamp: When the answer was detected
            confidence: Confidence score of the match

        Returns:
            Database question UUID if found and updated, None otherwise
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
                question.add_tier_result(
                    tier_type="live_conversation",
                    result_data={
                        "answer": answer_text,
                        "speaker": speaker,
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
        speaker: Optional[str],
        confidence: float
    ) -> None:
        """
        Broadcast answer detected event to WebSocket clients.

        Args:
            session_id: Meeting session identifier
            question_id: Database question UUID
            answer_text: The answer text
            speaker: Speaker who provided the answer
            confidence: Confidence score
        """
        event_data = {
            "type": "ANSWER_DETECTED",
            "question_id": question_id,
            "answer": answer_text,
            "speaker": speaker,
            "confidence": confidence,
            "source": "live_conversation",
            "timestamp": datetime.now(timezone.utc).isoformat()
        }

        if self._ws_broadcast_callback:
            try:
                await self._ws_broadcast_callback(session_id, event_data)
                logger.debug(
                    f"Broadcasted ANSWER_DETECTED event for question {question_id}"
                )
            except Exception as e:
                logger.error(f"Failed to broadcast answer event: {e}")
        else:
            logger.debug("No WebSocket callback configured, skipping broadcast")

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
            "low_confidence_answers": self.low_confidence_answers
        }
