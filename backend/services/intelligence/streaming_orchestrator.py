"""
Streaming Intelligence Orchestrator

Main orchestrator service that coordinates all streaming intelligence components
for real-time meeting analysis. Integrates:
- Transcription Buffer Management
- GPT-5-mini Streaming Interface
- Stream Router (routing to handlers)
- Question Handler (four-tier answer discovery)
- Action Handler (tracking and completeness)
- Answer Handler (live monitoring)
- WebSocket Broadcasting

Author: TellMeMo Team
Date: 2025-10-26
"""

import asyncio
from dataclasses import dataclass, field
from datetime import datetime
from typing import Any, Dict, List, Optional
from uuid import UUID

from sqlalchemy.ext.asyncio import AsyncSession
from redis.asyncio import Redis
import redis.asyncio as redis

from config import get_settings
from db.database import get_db_context
from utils.logger import get_logger, sanitize_for_log
from utils.exceptions import APIException

# Service imports
from services.transcription.transcription_buffer_service import get_transcription_buffer
from services.llm.gpt5_streaming import create_streaming_client, GPT5StreamingClient
from services.intelligence.stream_router import StreamRouter, get_stream_router, cleanup_stream_router
from services.intelligence.question_handler import QuestionHandler
from services.intelligence.action_handler import ActionHandler
from services.intelligence.answer_handler import AnswerHandler
from services.intelligence.segment_detector import get_segment_detector

# WebSocket import
from routers.websocket_live_insights import insights_manager

# Model imports for summary generation
from models.recording import Recording, RecordingTranscript
from models.live_insight import LiveMeetingInsight

logger = get_logger(__name__)


@dataclass
class OrchestratorMetrics:
    """Metrics for orchestrator operations."""

    total_chunks_processed: int = 0
    objects_routed: int = 0
    questions_detected: int = 0
    actions_detected: int = 0
    answers_detected: int = 0
    errors: int = 0
    total_latency_ms: float = 0.0
    streaming_sessions_active: int = 0
    redis_operations: int = 0
    redis_failures: int = 0

    @property
    def average_latency_ms(self) -> float:
        """Calculate average processing latency."""
        if self.total_chunks_processed == 0:
            return 0.0
        return self.total_latency_ms / self.total_chunks_processed


class StreamingIntelligenceException(APIException):
    """Exception for streaming intelligence orchestrator errors."""

    def __init__(self, message: str):
        super().__init__(
            message=message,
            status_code=500,
            error_code="STREAMING_INTELLIGENCE_ERROR"
        )


class StreamingIntelligenceOrchestrator:
    """
    Main orchestrator for real-time meeting intelligence.

    Coordinates all streaming components:
    - Receives transcription chunks
    - Maintains rolling transcript buffer
    - Streams context to GPT-5-mini
    - Routes GPT outputs to handlers
    - Manages parallel answer discovery
    - Broadcasts updates via WebSocket

    Usage:
        orchestrator = get_orchestrator(session_id)
        await orchestrator.process_transcription_chunk(transcript_data)
        await orchestrator.cleanup()
    """

    def __init__(self, session_id: str, recording_id: Optional[UUID] = None):
        """
        Initialize orchestrator for a meeting session.

        Args:
            session_id: Unique session identifier (typically same as recording_id)
            recording_id: Optional recording UUID for database linking
        """
        self.session_id = session_id
        self.recording_id = recording_id
        self.settings = get_settings()

        # Metrics
        self.metrics = OrchestratorMetrics()

        # Redis client (lazy initialization)
        self._redis_client: Optional[Redis] = None

        # GPT streaming client (lazy initialization)
        self._gpt_client: Optional[GPT5StreamingClient] = None

        # Component services
        self.buffer_service = get_transcription_buffer()
        self.stream_router = get_stream_router(session_id)
        self.question_handler = QuestionHandler()
        self.action_handler = ActionHandler()
        self.answer_handler = AnswerHandler()
        self.segment_detector = get_segment_detector()

        # Active streaming task
        self._streaming_task: Optional[asyncio.Task] = None
        self._stop_streaming = False

        # Register handlers with router
        self._register_handlers()

        # Set WebSocket callbacks
        self._set_websocket_callbacks()

        # Set cross-handler dependencies
        self.answer_handler.set_question_handler(self.question_handler)

        # Initialize segment detector session
        asyncio.create_task(self.segment_detector.initialize_session(session_id))

        logger.info(f"StreamingIntelligenceOrchestrator initialized for session {sanitize_for_log(session_id)}")

    def _register_handlers(self):
        """Register all handlers with the stream router."""
        self.stream_router.register_question_handler(self.question_handler.handle_question)
        self.stream_router.register_action_handler(self.action_handler.handle_action)
        self.stream_router.register_action_update_handler(self.action_handler.handle_action_update)
        self.stream_router.register_answer_handler(self.answer_handler.handle_answer)

        logger.debug(f"Handlers registered for session {self.session_id}")

    def _set_websocket_callbacks(self):
        """Set WebSocket broadcasting callbacks for all handlers."""
        async def broadcast_wrapper(session_id: str, event_data: dict):
            """Wrapper for WebSocket broadcasting."""
            try:
                await insights_manager.broadcast_to_session(session_id, event_data)
            except Exception as e:
                logger.error(f"WebSocket broadcast failed: {e}")

        self.question_handler.set_websocket_callback(broadcast_wrapper)
        self.action_handler.set_websocket_callback(broadcast_wrapper)
        self.answer_handler.set_websocket_callback(broadcast_wrapper)
        self.segment_detector.set_websocket_callback(broadcast_wrapper)

        logger.debug(f"WebSocket callbacks set for session {self.session_id}")

    async def _get_redis(self) -> Optional[Redis]:
        """
        Get or create Redis client with lazy initialization.

        Returns:
            Redis client or None if connection fails
        """
        if self._redis_client:
            return self._redis_client

        try:
            redis_url = f"redis://:{self.settings.redis_password}@{self.settings.redis_host}:{self.settings.redis_port}/{self.settings.redis_db}" if self.settings.redis_password else f"redis://{self.settings.redis_host}:{self.settings.redis_port}/{self.settings.redis_db}"

            self._redis_client = redis.from_url(redis_url, encoding="utf-8", decode_responses=True)
            await self._redis_client.ping()

            logger.info(f"Orchestrator connected to Redis for session {self.session_id}")
            return self._redis_client

        except Exception as e:
            logger.error(f"Redis connection failed for session {self.session_id}: {e}")
            self.metrics.redis_failures += 1
            return None

    async def process_transcription_chunk(
        self,
        text: str,
        speaker: Optional[str] = None,
        timestamp: Optional[datetime] = None,
        is_final: bool = True
    ) -> Dict[str, Any]:
        """
        Process a transcription chunk and trigger intelligence analysis.

        Args:
            text: Transcription text
            speaker: Speaker identifier (e.g., "Speaker A")
            timestamp: Timestamp of transcription
            is_final: Whether this is a final transcript (vs partial)

        Returns:
            Processing result with status and metrics
        """
        start_time = datetime.utcnow()

        try:
            # Only process final transcripts for GPT analysis (partials are for UI only)
            if not is_final:
                logger.debug(f"Skipping partial transcript for session {self.session_id}")
                return {"status": "skipped", "reason": "partial_transcript"}

            # Add to transcript buffer
            await self.buffer_service.add_sentence(
                session_id=self.session_id,
                text=text,
                speaker=speaker,
                timestamp=timestamp or datetime.utcnow()
            )

            # Get formatted context for GPT
            transcript_context = await self.buffer_service.get_formatted_context(
                session_id=self.session_id,
                include_timestamps=True,
                include_speakers=True,
                max_age_seconds=60  # Last 60 seconds
            )

            if not transcript_context:
                logger.warning(f"Empty transcript context for session {self.session_id}")
                return {"status": "skipped", "reason": "empty_context"}

            # Stream intelligence from GPT
            async with get_db_context() as session:
                await self._stream_gpt_intelligence(transcript_context, session)

            # Check for segment boundaries
            boundary_info = await self.segment_detector.check_boundary(
                session_id=self.session_id,
                current_time=timestamp or datetime.utcnow(),
                recent_text=text
            )

            # If segment boundary detected, trigger action alerts
            if boundary_info:
                async with get_db_context() as session:
                    # Trigger action completeness alerts
                    await self.action_handler.generate_segment_alerts(
                        session_id=self.session_id,
                        session=session
                    )

                    # Broadcast segment transition
                    await self.segment_detector.handle_segment_boundary(
                        session_id=self.session_id,
                        boundary_info=boundary_info,
                        current_time=timestamp or datetime.utcnow()
                    )

            # Update metrics
            self.metrics.total_chunks_processed += 1
            latency_ms = (datetime.utcnow() - start_time).total_seconds() * 1000
            self.metrics.total_latency_ms += latency_ms

            logger.info(
                f"Processed chunk for session {sanitize_for_log(self.session_id)}: "
                f"chunks_processed={self.metrics.total_chunks_processed}, "
                f"latency={latency_ms:.2f}ms"
            )

            return {
                "status": "success",
                "latency_ms": latency_ms,
                "chunks_processed": self.metrics.total_chunks_processed
            }

        except Exception as e:
            self.metrics.errors += 1
            logger.error(f"Error processing transcription chunk: {e}", exc_info=True)
            raise StreamingIntelligenceException(f"Failed to process transcription: {e}")

    async def _stream_gpt_intelligence(
        self,
        transcript_context: str,
        session: AsyncSession
    ):
        """
        Stream intelligence analysis from GPT-5-mini.

        Args:
            transcript_context: Formatted transcript buffer
            session: Database session for handler operations
        """
        try:
            # Initialize GPT client if not exists
            if not self._gpt_client:
                from services.llm.multi_llm_client import get_llm_client
                openai_client = get_llm_client()
                self._gpt_client = create_streaming_client(openai_client)

            # Build context with active questions/actions
            context = await self._build_context()

            # Stream objects from GPT
            async for obj in self._gpt_client.stream_intelligence(
                transcript_buffer=transcript_context,
                context=context
            ):
                self.metrics.objects_routed += 1

                # Track object types
                obj_type = obj.get("type")
                if obj_type == "question":
                    self.metrics.questions_detected += 1
                elif obj_type == "action":
                    self.metrics.actions_detected += 1
                elif obj_type == "answer":
                    self.metrics.answers_detected += 1

                # Route through stream router
                await self.stream_router.route_object(obj, session, self.session_id)

        except Exception as e:
            logger.error(f"GPT streaming failed for session {self.session_id}: {e}", exc_info=True)
            raise

    async def _build_context(self) -> Dict[str, Any]:
        """
        Build context dictionary with active questions and actions.

        Returns:
            Context dictionary for GPT prompt
        """
        context = {
            "session_id": self.session_id,
            "active_questions": [],
            "active_actions": []
        }

        try:
            redis_client = await self._get_redis()

            if redis_client:
                # Get active questions from Redis
                questions_key = f"session:{self.session_id}:active_questions"
                questions_data = await redis_client.get(questions_key)
                if questions_data:
                    import json
                    context["active_questions"] = json.loads(questions_data)

                # Get active actions from Redis
                actions_key = f"session:{self.session_id}:active_actions"
                actions_data = await redis_client.get(actions_key)
                if actions_data:
                    import json
                    context["active_actions"] = json.loads(actions_data)

                self.metrics.redis_operations += 1

        except Exception as e:
            logger.warning(f"Failed to build context from Redis: {e}")
            self.metrics.redis_failures += 1

        return context

    async def get_metrics(self) -> Dict[str, Any]:
        """
        Get orchestrator metrics.

        Returns:
            Dictionary containing all metrics
        """
        handler_metrics = {
            "stream_router": self.stream_router.get_metrics(),
            "answer_handler": self.answer_handler.get_metrics()
        }

        return {
            "session_id": self.session_id,
            "orchestrator": {
                "chunks_processed": self.metrics.total_chunks_processed,
                "objects_routed": self.metrics.objects_routed,
                "questions_detected": self.metrics.questions_detected,
                "actions_detected": self.metrics.actions_detected,
                "answers_detected": self.metrics.answers_detected,
                "errors": self.metrics.errors,
                "average_latency_ms": self.metrics.average_latency_ms,
                "redis_operations": self.metrics.redis_operations,
                "redis_failures": self.metrics.redis_failures
            },
            "handlers": handler_metrics
        }

    async def get_health_status(self) -> Dict[str, Any]:
        """
        Get health status of orchestrator and all components.

        Returns:
            Health status dictionary
        """
        health = {
            "session_id": self.session_id,
            "status": "healthy",
            "components": {}
        }

        # Check Redis connection
        redis_client = await self._get_redis()
        health["components"]["redis"] = {
            "status": "connected" if redis_client else "disconnected",
            "operations": self.metrics.redis_operations,
            "failures": self.metrics.redis_failures
        }

        # Check GPT client
        health["components"]["gpt_client"] = {
            "status": "initialized" if self._gpt_client else "not_initialized"
        }

        # Check handlers
        health["components"]["handlers"] = {
            "stream_router": "active",
            "question_handler": "active",
            "action_handler": "active",
            "answer_handler": "active"
        }

        # Overall status
        if self.metrics.errors > 10:
            health["status"] = "degraded"
        elif not redis_client:
            health["status"] = "degraded"

        return health

    async def cleanup(self):
        """
        Cleanup all resources for this session.

        Performs:
        - Handler cleanup (persist state to database)
        - Router state clearing
        - Redis connection closing
        - GPT client cleanup
        """
        logger.info(f"Cleaning up orchestrator for session {sanitize_for_log(self.session_id)}")

        try:
            # Stop any active streaming
            self._stop_streaming = True
            if self._streaming_task and not self._streaming_task.done():
                self._streaming_task.cancel()
                try:
                    await self._streaming_task
                except asyncio.CancelledError:
                    pass

            # Signal meeting end for final segment
            await self.segment_detector.signal_meeting_end(self.session_id)

            # Cleanup handlers (persist to database)
            await self.question_handler.cleanup_session(self.session_id)
            await self.action_handler.cleanup_session(self.session_id)
            await self.answer_handler.cleanup_session(self.session_id)
            await self.segment_detector.cleanup_session(self.session_id)

            # Clear router state
            self.stream_router.clear_state()

            # Close Redis connection
            if self._redis_client:
                await self._redis_client.aclose()
                self._redis_client = None

            logger.info(
                f"Orchestrator cleanup complete for session {sanitize_for_log(self.session_id)}: "
                f"chunks_processed={self.metrics.total_chunks_processed}, "
                f"questions={self.metrics.questions_detected}, "
                f"actions={self.metrics.actions_detected}"
            )

        except Exception as e:
            logger.error(f"Error during orchestrator cleanup: {e}", exc_info=True)


# Global orchestrator instances (session-based)
_orchestrator_instances: Dict[str, StreamingIntelligenceOrchestrator] = {}


def get_orchestrator(
    session_id: str,
    recording_id: Optional[UUID] = None
) -> StreamingIntelligenceOrchestrator:
    """
    Get or create orchestrator instance for a session.

    Args:
        session_id: Unique session identifier
        recording_id: Optional recording UUID

    Returns:
        StreamingIntelligenceOrchestrator instance
    """
    if session_id not in _orchestrator_instances:
        _orchestrator_instances[session_id] = StreamingIntelligenceOrchestrator(
            session_id=session_id,
            recording_id=recording_id
        )
        logger.info(f"Created new orchestrator instance for session {sanitize_for_log(session_id)}")

    return _orchestrator_instances[session_id]


async def cleanup_orchestrator(session_id: str, generate_summary: bool = True):
    """
    Cleanup and remove orchestrator instance for a session.

    Args:
        session_id: Session identifier to cleanup
        generate_summary: Whether to generate meeting summary after cleanup (default: True)
    """
    if session_id in _orchestrator_instances:
        orchestrator = _orchestrator_instances[session_id]
        await orchestrator.cleanup()

        # Generate meeting summary if requested
        if generate_summary:
            try:
                await _generate_meeting_summary(session_id, orchestrator.recording_id)
            except Exception as e:
                logger.error(f"Error generating meeting summary for session {sanitize_for_log(session_id)}: {e}", exc_info=True)

        del _orchestrator_instances[session_id]

        # Also cleanup router singleton
        cleanup_stream_router(session_id)

        logger.info(f"Removed orchestrator instance for session {sanitize_for_log(session_id)}")


async def _generate_meeting_summary(session_id: str, recording_id: Optional[UUID]) -> None:
    """
    Generate and store meeting summary after recording ends.

    This function queries all live insights and creates a comprehensive meeting summary.

    Args:
        session_id: Session identifier
        recording_id: Optional recording UUID
    """
    logger.info(f"Generating meeting summary for session {sanitize_for_log(session_id)}")

    try:
        async with get_db_context() as db:
            # Query all live insights for this session
            from sqlalchemy import select

            # Get all questions
            questions_result = await db.execute(
                select(LiveMeetingInsight)
                .where(LiveMeetingInsight.session_id == session_id)
                .where(LiveMeetingInsight.insight_type == "question")
                .order_by(LiveMeetingInsight.detected_at)
            )
            questions = questions_result.scalars().all()

            # Get all actions
            actions_result = await db.execute(
                select(LiveMeetingInsight)
                .where(LiveMeetingInsight.session_id == session_id)
                .where(LiveMeetingInsight.insight_type == "action")
                .order_by(LiveMeetingInsight.detected_at)
            )
            actions = actions_result.scalars().all()

            # Get recording if available
            recording = None
            if recording_id:
                recording_result = await db.execute(
                    select(Recording).where(Recording.id == recording_id)
                )
                recording = recording_result.scalar_one_or_none()

            # Build summary statistics
            total_questions = len(questions)
            answered_questions = sum(1 for q in questions if q.status == "answered")
            total_actions = len(actions)
            complete_actions = sum(1 for a in actions if a.status == "complete")

            # Get answer source breakdown
            answer_sources = {}
            for q in questions:
                if q.answer_source:
                    answer_sources[q.answer_source] = answer_sources.get(q.answer_source, 0) + 1

            summary_data = {
                "session_id": session_id,
                "recording_id": str(recording_id) if recording_id else None,
                "meeting_title": recording.meeting_title if recording else "Untitled Meeting",
                "total_questions": total_questions,
                "answered_questions": answered_questions,
                "unanswered_questions": total_questions - answered_questions,
                "answer_source_breakdown": answer_sources,
                "total_actions": total_actions,
                "complete_actions": complete_actions,
                "incomplete_actions": total_actions - complete_actions,
                "generated_at": datetime.utcnow().isoformat()
            }

            logger.info(
                f"Meeting summary generated for session {sanitize_for_log(session_id)}: "
                f"{total_questions} questions ({answered_questions} answered), "
                f"{total_actions} actions ({complete_actions} complete)"
            )

            # Broadcast summary to connected clients
            try:
                await insights_manager.broadcast_to_session(
                    session_id,
                    {
                        "type": "MEETING_SUMMARY",
                        "summary": summary_data,
                        "timestamp": datetime.utcnow().isoformat()
                    }
                )
            except Exception as broadcast_error:
                logger.warning(f"Could not broadcast meeting summary: {broadcast_error}")

            # Update recording metadata with summary if recording exists
            if recording:
                try:
                    recording.recording_metadata = {
                        **recording.recording_metadata,
                        "live_insights_summary": summary_data
                    }
                    await db.commit()
                    logger.info(f"Updated recording {recording_id} with meeting summary metadata")
                except Exception as update_error:
                    logger.error(f"Failed to update recording metadata: {update_error}")

    except Exception as e:
        logger.error(f"Error generating meeting summary: {e}", exc_info=True)
        raise


async def get_orchestrator_metrics(session_id: str) -> Optional[Dict[str, Any]]:
    """
    Get metrics for a specific orchestrator session.

    Args:
        session_id: Session identifier

    Returns:
        Metrics dictionary or None if session not found
    """
    if session_id in _orchestrator_instances:
        orchestrator = _orchestrator_instances[session_id]
        return await orchestrator.get_metrics()

    return None


async def get_orchestrator_health(session_id: str) -> Optional[Dict[str, Any]]:
    """
    Get health status for a specific orchestrator session.

    Args:
        session_id: Session identifier

    Returns:
        Health status dictionary or None if session not found
    """
    if session_id in _orchestrator_instances:
        orchestrator = _orchestrator_instances[session_id]
        return await orchestrator.get_health_status()

    return None
