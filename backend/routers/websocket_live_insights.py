"""
WebSocket router for real-time meeting insights communication.

This module provides WebSocket endpoints for streaming live meeting intelligence
including question detection, answer discovery, and action item tracking.
"""

import asyncio
import json
from datetime import datetime, timedelta
from typing import Dict, Set, Optional
from uuid import UUID

from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Query, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from models.user import User
from db.database import get_db
from middleware.auth_middleware import get_current_user_ws
from utils.logger import get_logger, sanitize_for_log
from services.transcription.assemblyai_service import (
    assemblyai_manager,
    TranscriptionResult
)
from services.intelligence.streaming_orchestrator import get_orchestrator, cleanup_orchestrator

logger = get_logger(__name__)

router = APIRouter()

# Session context storage: session_id -> organization_id
# Used to pass organization context to orchestrator when processing transcriptions
_session_organization_map: Dict[str, UUID] = {}

# Session tier configuration storage: session_id -> List[enabled_tiers]
# Used to pass tier configuration when creating orchestrator
_session_tier_config: Dict[str, list] = {}

# Session timestamp tracking: session_id -> datetime
# Used for TTL-based cleanup of stale sessions
_session_timestamps: Dict[str, datetime] = {}

# Session cleanup configuration
SESSION_TTL_HOURS = 24  # Sessions older than this will be cleaned up
CLEANUP_INTERVAL_MINUTES = 30  # How often to run cleanup task


class LiveInsightsConnectionManager:
    """
    Manages WebSocket connections for live meeting insights.

    Supports multiple participants per meeting session with real-time
    insight broadcasting and user feedback handling.
    """

    def __init__(self):
        # session_id -> Set[WebSocket connections]
        self.active_connections: Dict[str, Set[WebSocket]] = {}

        # WebSocket -> user_id mapping for reverse lookup
        self.websocket_to_user: Dict[WebSocket, str] = {}

        # WebSocket -> session_id mapping for reverse lookup
        self.websocket_to_session: Dict[WebSocket, str] = {}

        # Lock for thread-safe operations
        self.lock = asyncio.Lock()

        # Redis pub/sub for cross-process communication
        self._pubsub_task: Optional[asyncio.Task] = None
        self._pubsub = None
        self._async_redis = None

        # Session cleanup task
        self._cleanup_task: Optional[asyncio.Task] = None
        self._start_cleanup_task()

    async def connect(self, websocket: WebSocket, session_id: str, user_id: str):
        """
        Connect a WebSocket client to a meeting session.

        Args:
            websocket: The WebSocket connection
            session_id: The meeting session identifier
            user_id: The authenticated user identifier
        """
        await websocket.accept()

        async with self.lock:
            # Add to session connections
            if session_id not in self.active_connections:
                self.active_connections[session_id] = set()
                # Subscribe to Redis channel for this session
                await self._subscribe_redis_channel(session_id)

            self.active_connections[session_id].add(websocket)

            # Store reverse mappings
            self.websocket_to_user[websocket] = user_id
            self.websocket_to_session[websocket] = session_id

        # Start Redis pub/sub listener if not already running
        if self._pubsub_task is None or self._pubsub_task.done():
            self._pubsub_task = asyncio.create_task(self._listen_redis_pubsub())
            logger.info("Started Redis pub/sub listener task for live insights")

        logger.info(
            f"Live insights WebSocket connected: session={sanitize_for_log(session_id)}, "
            f"user={sanitize_for_log(user_id)}, "
            f"total_connections={len(self.active_connections.get(session_id, []))}"
        )

    async def disconnect(self, websocket: WebSocket):
        """
        Disconnect a WebSocket client and clean up resources.

        Args:
            websocket: The WebSocket connection to disconnect
        """
        async with self.lock:
            # Get session and user before removing
            session_id = self.websocket_to_session.get(websocket)
            user_id = self.websocket_to_user.get(websocket)

            if session_id and session_id in self.active_connections:
                self.active_connections[session_id].discard(websocket)

                # Remove empty session and unsubscribe from Redis
                if not self.active_connections[session_id]:
                    del self.active_connections[session_id]
                    await self._unsubscribe_redis_channel(session_id)

            # Clean up reverse mappings
            self.websocket_to_user.pop(websocket, None)
            self.websocket_to_session.pop(websocket, None)

        # Stop pub/sub listener if no more connections
        if not self.active_connections:
            if self._pubsub_task:
                self._pubsub_task.cancel()
                self._pubsub_task = None
            self._pubsub = None
            logger.info("Stopped Redis pub/sub listener (no active connections)")

        if session_id:
            logger.info(
                f"Live insights WebSocket disconnected: session={sanitize_for_log(session_id)}, "
                f"user={sanitize_for_log(user_id)}, "
                f"remaining_connections={len(self.active_connections.get(session_id, []))}"
            )

    async def broadcast_to_session(self, session_id: str, message: dict):
        """
        Broadcast a message to all connections in a meeting session.

        Args:
            session_id: The meeting session identifier
            message: The message data to broadcast
        """
        if session_id not in self.active_connections:
            logger.debug(f"No active connections for session {sanitize_for_log(session_id)}")
            return

        disconnected = set()

        for websocket in list(self.active_connections[session_id]):
            try:
                await websocket.send_json(message)
            except Exception as e:
                logger.error(
                    f"Error broadcasting to session {sanitize_for_log(session_id)}: {e}"
                )
                disconnected.add(websocket)

        # Clean up disconnected clients
        for ws in disconnected:
            await self.disconnect(ws)

    async def send_to_client(self, websocket: WebSocket, message: dict):
        """
        Send a message to a specific WebSocket client.

        Args:
            websocket: The target WebSocket connection
            message: The message data to send
        """
        try:
            await websocket.send_json(message)
        except Exception as e:
            session_id = self.websocket_to_session.get(websocket)
            logger.error(
                f"Error sending to client in session {sanitize_for_log(session_id)}: {e}"
            )
            await self.disconnect(websocket)

    def is_session_active(self, session_id: str) -> bool:
        """
        Check if a meeting session has any active connections.

        Args:
            session_id: The meeting session identifier

        Returns:
            True if session has active connections, False otherwise
        """
        return session_id in self.active_connections and len(self.active_connections[session_id]) > 0

    def get_connection_count(self, session_id: str) -> int:
        """
        Get the number of active connections for a session.

        Args:
            session_id: The meeting session identifier

        Returns:
            Number of active connections
        """
        return len(self.active_connections.get(session_id, []))

    async def _get_async_redis(self):
        """Get or create async Redis connection for pub/sub."""
        if self._async_redis is None:
            from redis.asyncio import Redis as AsyncRedis
            from config import get_settings

            settings = get_settings()
            if settings.redis_password:
                redis_url = f"redis://:{settings.redis_password}@{settings.redis_host}:{settings.redis_port}/{settings.redis_db}"
            else:
                redis_url = f"redis://{settings.redis_host}:{settings.redis_port}/{settings.redis_db}"

            self._async_redis = await AsyncRedis.from_url(
                redis_url,
                decode_responses=True,
                socket_connect_timeout=5,
                socket_keepalive=True
            )
            logger.info("Async Redis connection established for live insights pub/sub")

        return self._async_redis

    async def _subscribe_redis_channel(self, session_id: str):
        """Subscribe to Redis pub/sub channel for a session."""
        try:
            if self._pubsub is None:
                redis_conn = await self._get_async_redis()
                self._pubsub = redis_conn.pubsub()

            channel = f"live_insights:{session_id}"
            await self._pubsub.subscribe(channel)
            logger.debug(f"Subscribed to Redis channel: {channel}")
        except Exception as e:
            logger.error(f"Failed to subscribe to Redis channel for session {session_id}: {e}")

    async def _unsubscribe_redis_channel(self, session_id: str):
        """Unsubscribe from Redis pub/sub channel for a session."""
        try:
            if self._pubsub:
                channel = f"live_insights:{session_id}"
                await self._pubsub.unsubscribe(channel)
                logger.debug(f"Unsubscribed from Redis channel: {channel}")
        except Exception as e:
            logger.error(f"Failed to unsubscribe from Redis channel for session {session_id}: {e}")

    async def _listen_redis_pubsub(self):
        """Background task to listen for Redis pub/sub messages and broadcast to WebSocket clients."""
        logger.info("Redis pub/sub listener started for live insights")
        try:
            while True:
                if self._pubsub is None:
                    # Wait for first subscription
                    await asyncio.sleep(1)
                    continue

                # Listen for messages with timeout
                message = await self._pubsub.get_message(ignore_subscribe_messages=True, timeout=1.0)

                if message and message['type'] == 'message':
                    try:
                        import json
                        channel = message['channel']
                        # Extract session_id from channel name (format: live_insights:{session_id})
                        session_id = channel.split(':', 1)[1]
                        event_data = json.loads(message['data'])

                        event_type = event_data.get('type', 'UNKNOWN')
                        logger.debug(f"Received Redis message for session {sanitize_for_log(session_id)}: type={event_type}")

                        # Broadcast to all WebSocket clients connected to this session
                        await self.broadcast_to_session(session_id, event_data)

                    except Exception as e:
                        logger.error(f"Error processing Redis pub/sub message for live insights: {e}", exc_info=True)

        except asyncio.CancelledError:
            logger.info("Redis pub/sub listener cancelled for live insights")
            # Clean up pub/sub connection
            if self._pubsub:
                try:
                    await self._pubsub.unsubscribe()
                    await self._pubsub.aclose()
                except Exception as e:
                    logger.warning(f"Error closing pub/sub during cancellation: {e}")
                self._pubsub = None
            # Close async Redis connection
            if self._async_redis:
                try:
                    await self._async_redis.aclose()
                except Exception as e:
                    logger.warning(f"Error closing Redis connection: {e}")
                self._async_redis = None
        except Exception as e:
            logger.error(f"Fatal error in Redis pub/sub listener for live insights: {e}", exc_info=True)

    def _start_cleanup_task(self):
        """Start the background task for cleaning up stale sessions."""
        try:
            # Create cleanup task - it will run in background
            self._cleanup_task = asyncio.create_task(self._cleanup_stale_sessions_loop())
            logger.info(
                f"Started session cleanup task (TTL: {SESSION_TTL_HOURS}h, "
                f"interval: {CLEANUP_INTERVAL_MINUTES}m)"
            )
        except RuntimeError:
            # No event loop running yet - task will be started on first connection
            logger.debug("Event loop not running, cleanup task will start on first connection")

    async def _cleanup_stale_sessions_loop(self):
        """Background task that periodically cleans up stale sessions."""
        logger.info("Session cleanup loop started")
        try:
            while True:
                # Wait for cleanup interval
                await asyncio.sleep(CLEANUP_INTERVAL_MINUTES * 60)

                # Perform cleanup
                await self._cleanup_stale_sessions()

        except asyncio.CancelledError:
            logger.info("Session cleanup task cancelled")
        except Exception as e:
            logger.error(f"Fatal error in session cleanup loop: {e}", exc_info=True)

    async def _cleanup_stale_sessions(self):
        """
        Remove sessions older than SESSION_TTL_HOURS from global session maps.

        This prevents unbounded memory growth by cleaning up sessions that are
        no longer active.
        """
        global _session_organization_map, _session_tier_config, _session_timestamps

        try:
            cutoff_time = datetime.now() - timedelta(hours=SESSION_TTL_HOURS)
            removed_sessions = []

            # Iterate over copy of keys to avoid modification during iteration
            for session_id in list(_session_timestamps.keys()):
                session_time = _session_timestamps.get(session_id)

                if session_time and session_time < cutoff_time:
                    # Remove from all session maps
                    _session_organization_map.pop(session_id, None)
                    _session_tier_config.pop(session_id, None)
                    _session_timestamps.pop(session_id, None)
                    removed_sessions.append(session_id)

            if removed_sessions:
                logger.info(
                    f"Cleaned up {len(removed_sessions)} stale sessions "
                    f"(older than {SESSION_TTL_HOURS}h): "
                    f"{[sanitize_for_log(sid) for sid in removed_sessions[:5]]}"
                    f"{'...' if len(removed_sessions) > 5 else ''}"
                )
            else:
                logger.debug(
                    f"Session cleanup completed: 0 stale sessions removed "
                    f"({len(_session_timestamps)} active sessions)"
                )

        except Exception as e:
            logger.error(f"Error during session cleanup: {e}", exc_info=True)


# Global connection manager instance
insights_manager = LiveInsightsConnectionManager()


# =============================================================================
# Broadcast Helper Functions
# =============================================================================
# These functions are called by backend services to broadcast insights to clients
# =============================================================================

async def _publish_to_redis(session_id: str, event_data: dict):
    """
    Helper to publish event data to Redis pub/sub in a thread-safe manner.

    Uses asyncio.to_thread() to run synchronous Redis publish() without blocking
    the async event loop.

    Args:
        session_id: Meeting session identifier
        event_data: Event data dict with 'type' and other fields
    """
    from queue_config import queue_config
    await asyncio.to_thread(queue_config.publish_live_insight, session_id, event_data)


async def broadcast_question_detected(session_id: str, question_data: dict):
    """
    Broadcast when a new question is detected.

    Args:
        session_id: The meeting session identifier
        question_data: Question details including id, text, speaker, timestamp
    """
    event_data = {
        "type": "QUESTION_DETECTED",
        "data": question_data,
        "timestamp": datetime.utcnow().isoformat()
    }

    await _publish_to_redis(session_id, event_data)
    logger.debug(f"Published QUESTION_DETECTED to Redis for session {sanitize_for_log(session_id)}")


async def broadcast_rag_result(session_id: str, question_id: str, result_data: dict):
    """
    Broadcast RAG search result for a question (progressive delivery).

    Args:
        session_id: The meeting session identifier
        question_id: The question identifier
        result_data: RAG result including document, relevance score, metadata
    """
    event_data = {
        "type": "RAG_RESULT",
        "question_id": question_id,
        "data": result_data,
        "timestamp": datetime.utcnow().isoformat()
    }

    await _publish_to_redis(session_id, event_data)
    logger.debug(f"Published RAG_RESULT to Redis for session {sanitize_for_log(session_id)}")


async def broadcast_answer_from_meeting(session_id: str, question_id: str, answer_data: dict):
    """
    Broadcast when an answer is found earlier in the meeting.

    Args:
        session_id: The meeting session identifier
        question_id: The question identifier
        answer_data: Answer details including text, speaker, timestamp, confidence
    """
    event_data = {
        "type": "ANSWER_FROM_MEETING",
        "question_id": question_id,
        "data": answer_data,
        "timestamp": datetime.utcnow().isoformat()
    }

    await _publish_to_redis(session_id, event_data)
    logger.debug(f"Published ANSWER_FROM_MEETING to Redis for session {sanitize_for_log(session_id)}")


async def broadcast_question_answered_live(session_id: str, question_id: str, answer_data: dict):
    """
    Broadcast when a question is answered in live conversation.

    Args:
        session_id: The meeting session identifier
        question_id: The question identifier
        answer_data: Answer details including text, speaker, timestamp, confidence
    """
    event_data = {
        "type": "QUESTION_ANSWERED_LIVE",
        "question_id": question_id,
        "data": answer_data,
        "timestamp": datetime.utcnow().isoformat()
    }

    await _publish_to_redis(session_id, event_data)
    logger.debug(f"Published QUESTION_ANSWERED_LIVE to Redis for session {sanitize_for_log(session_id)}")


async def broadcast_gpt_generated_answer(session_id: str, question_id: str, answer_data: dict):
    """
    Broadcast GPT-generated answer (Tier 4 fallback).

    Args:
        session_id: The meeting session identifier
        question_id: The question identifier
        answer_data: Answer including text, confidence, disclaimer
    """
    event_data = {
        "type": "GPT_GENERATED_ANSWER",
        "question_id": question_id,
        "data": answer_data,
        "timestamp": datetime.utcnow().isoformat()
    }

    await _publish_to_redis(session_id, event_data)
    logger.debug(f"Published GPT_GENERATED_ANSWER to Redis for session {sanitize_for_log(session_id)}")


async def broadcast_question_unanswered(session_id: str, question_id: str):
    """
    Broadcast when a question remains unanswered after all tiers exhausted.

    Args:
        session_id: The meeting session identifier
        question_id: The question identifier
    """
    event_data = {
        "type": "QUESTION_UNANSWERED",
        "question_id": question_id,
        "timestamp": datetime.utcnow().isoformat()
    }

    await _publish_to_redis(session_id, event_data)
    logger.debug(f"Published QUESTION_UNANSWERED to Redis for session {sanitize_for_log(session_id)}")


async def broadcast_action_tracked(session_id: str, action_data: dict):
    """
    Broadcast when a new action item is detected.

    Args:
        session_id: The meeting session identifier
        action_data: Action details including id, description, owner, deadline, completeness
    """
    event_data = {
        "type": "ACTION_TRACKED",
        "data": action_data,
        "timestamp": datetime.utcnow().isoformat()
    }

    await _publish_to_redis(session_id, event_data)
    logger.debug(f"Published ACTION_TRACKED to Redis for session {sanitize_for_log(session_id)}")


async def broadcast_action_updated(session_id: str, action_id: str, update_data: dict):
    """
    Broadcast when an action item is updated with new details.

    Args:
        session_id: The meeting session identifier
        action_id: The action identifier
        update_data: Updated fields including owner, deadline, completeness
    """
    event_data = {
        "type": "ACTION_UPDATED",
        "action_id": action_id,
        "data": update_data,
        "timestamp": datetime.utcnow().isoformat()
    }

    await _publish_to_redis(session_id, event_data)
    logger.debug(f"Published ACTION_UPDATED to Redis for session {sanitize_for_log(session_id)}")


async def broadcast_action_alert(session_id: str, action_id: str, alert_data: dict):
    """
    Broadcast alert for incomplete action at segment boundary.

    Args:
        session_id: The meeting session identifier
        action_id: The action identifier
        alert_data: Alert details including missing fields, completeness score
    """
    event_data = {
        "type": "ACTION_ALERT",
        "action_id": action_id,
        "data": alert_data,
        "timestamp": datetime.utcnow().isoformat()
    }

    await _publish_to_redis(session_id, event_data)
    logger.debug(f"Published ACTION_ALERT to Redis for session {sanitize_for_log(session_id)}")


async def broadcast_segment_transition(session_id: str, segment_data: dict):
    """
    Broadcast meeting segment transition event.

    Args:
        session_id: The meeting session identifier
        segment_data: Segment details including boundary type, timestamp
    """
    event_data = {
        "type": "SEGMENT_TRANSITION",
        "data": segment_data,
        "timestamp": datetime.utcnow().isoformat()
    }

    await _publish_to_redis(session_id, event_data)
    logger.debug(f"Published SEGMENT_TRANSITION to Redis for session {sanitize_for_log(session_id)}")


async def broadcast_meeting_summary(session_id: str, summary_data: dict):
    """
    Broadcast final meeting summary with all questions and actions.

    Args:
        session_id: The meeting session identifier
        summary_data: Complete summary including all insights
    """
    event_data = {
        "type": "MEETING_SUMMARY",
        "data": summary_data,
        "timestamp": datetime.utcnow().isoformat()
    }

    await _publish_to_redis(session_id, event_data)
    logger.debug(f"Published MEETING_SUMMARY to Redis for session {sanitize_for_log(session_id)}")


async def broadcast_transcription_partial(session_id: str, transcript_data: dict):
    """
    Broadcast partial transcription for live display.

    Args:
        session_id: The meeting session identifier
        transcript_data: Partial transcript including text, speaker, timestamp
    """
    event_data = {
        "type": "TRANSCRIPTION_PARTIAL",
        "data": transcript_data,
        "timestamp": datetime.utcnow().isoformat()
    }

    await _publish_to_redis(session_id, event_data)


async def broadcast_transcription_final(session_id: str, transcript_data: dict):
    """
    Broadcast final stable transcription.

    Args:
        session_id: The meeting session identifier
        transcript_data: Final transcript including text, speaker, timestamp, confidence
    """
    event_data = {
        "type": "TRANSCRIPTION_FINAL",
        "data": transcript_data,
        "timestamp": datetime.utcnow().isoformat()
    }

    await _publish_to_redis(session_id, event_data)


async def broadcast_sync_state(session_id: str, state_data: dict):
    """
    Broadcast full state synchronization on reconnect or late join.

    Args:
        session_id: The meeting session identifier
        state_data: Complete state including all questions, actions, transcripts
    """
    event_data = {
        "type": "SYNC_STATE",
        "data": state_data,
        "timestamp": datetime.utcnow().isoformat()
    }

    await _publish_to_redis(session_id, event_data)
    logger.info(f"Published SYNC_STATE to Redis for session {sanitize_for_log(session_id)}")


async def get_session_state(session_id: str, db: AsyncSession) -> dict:
    """
    Retrieve complete session state from database for reconnection sync.

    Queries live_meeting_insights table for all questions and actions
    associated with the session_id.

    Args:
        session_id: The meeting session identifier
        db: Database session

    Returns:
        dict: Session state with questions and actions arrays
    """
    from models.live_insight import LiveMeetingInsight, InsightType
    from sqlalchemy import select

    try:
        # Query all insights for this session
        stmt = (
            select(LiveMeetingInsight)
            .where(LiveMeetingInsight.session_id == session_id)
            .order_by(LiveMeetingInsight.detected_at.asc())
        )
        result = await db.execute(stmt)
        insights = result.scalars().all()

        questions = []
        actions = []

        for insight in insights:
            if insight.insight_type == InsightType.QUESTION:
                # Convert database model to Flutter-compatible format
                question_data = {
                    "id": str(insight.id),
                    "text": insight.content,
                    "speaker": insight.speaker,
                    "timestamp": insight.detected_at.isoformat() if insight.detected_at else None,
                    "status": insight.status,
                    "answer_source": insight.answer_source,
                    "tier_results": insight.insight_metadata.get("tier_results", []) if insight.insight_metadata else [],
                    "metadata": insight.insight_metadata or {}
                }
                questions.append(question_data)

            elif insight.insight_type == InsightType.ACTION:
                # Convert database model to Flutter-compatible format
                metadata = insight.insight_metadata or {}
                action_data = {
                    "id": str(insight.id),
                    "description": insight.content,
                    "owner": metadata.get("owner"),
                    "deadline": metadata.get("deadline"),
                    "speaker": insight.speaker,
                    "timestamp": insight.detected_at.isoformat() if insight.detected_at else None,
                    "completeness": metadata.get("completeness_score", 0.0),
                    "status": insight.status,
                    "metadata": metadata
                }
                actions.append(action_data)

        state_data = {
            "session_id": session_id,
            "timestamp": datetime.utcnow().isoformat(),
            "questions": questions,
            "actions": actions
        }

        logger.info(
            f"Retrieved session state for {sanitize_for_log(session_id)}: "
            f"{len(questions)} questions, {len(actions)} actions"
        )

        return state_data

    except Exception as e:
        logger.error(
            f"Error retrieving session state for {sanitize_for_log(session_id)}: {e}",
            exc_info=True
        )
        # Return empty state on error
        return {
            "session_id": session_id,
            "timestamp": datetime.utcnow().isoformat(),
            "questions": [],
            "actions": []
        }


# =============================================================================
# AssemblyAI Transcription Callback Handlers
# =============================================================================

async def handle_transcription_result(session_id: str, result: TranscriptionResult):
    """
    Handle transcription result from AssemblyAI and broadcast to clients.

    Args:
        session_id: The meeting session identifier
        result: Parsed transcription result
    """
    try:
        # Generate unique ID for this transcript segment
        import uuid
        transcript_id = str(uuid.uuid4())

        # Convert audio timestamps (milliseconds) to ISO datetime strings
        # Use created_at as base timestamp, then add audio offsets
        base_time = datetime.fromisoformat(result.created_at.replace('Z', '+00:00')) if result.created_at else datetime.utcnow()

        # Calculate start/end times from audio offsets
        start_time = base_time + timedelta(milliseconds=result.audio_start)
        end_time = base_time + timedelta(milliseconds=result.audio_end) if result.audio_end > 0 else None

        # Prepare transcript data for broadcasting (Flutter-compatible format)
        transcript_data = {
            "id": transcript_id,
            "text": result.text,
            "speaker": result.speaker,  # Can be null
            "startTime": start_time.isoformat(),
            "endTime": end_time.isoformat() if end_time else None,
            "isFinal": result.is_final,
            "confidence": result.confidence,
            "metadata": {
                "audio_start": result.audio_start,
                "audio_end": result.audio_end,
                "words": result.words
            }
        }

        # Broadcast appropriate event based on transcription type
        if result.is_final:
            await broadcast_transcription_final(session_id, transcript_data)

            logger.info(f"🔵 FINAL transcription received for session {sanitize_for_log(session_id)}: '{result.text[:100]}...'")

            # Task 7.2: Send final transcription to streaming orchestrator for intelligence processing
            try:
                # Get organization_id from session context
                organization_id = _session_organization_map.get(session_id)

                # Get tier configuration from session context (if set by client)
                enabled_tiers = _session_tier_config.get(session_id)

                orchestrator = get_orchestrator(
                    session_id=session_id,
                    organization_id=organization_id,
                    enabled_tiers=enabled_tiers
                )
                logger.info(f"Sending final transcript to orchestrator for session {sanitize_for_log(session_id)}")
                await orchestrator.process_transcription_chunk(
                    text=result.text,
                    speaker=result.speaker,
                    timestamp=datetime.fromisoformat(result.created_at.replace('Z', '+00:00')) if result.created_at else datetime.utcnow(),
                    is_final=True
                )
                logger.info(f"✅ Successfully forwarded final transcription to orchestrator for session {sanitize_for_log(session_id)}")
            except Exception as e:
                logger.error(f"❌ Failed to process transcription with orchestrator for session {sanitize_for_log(session_id)}: {e}", exc_info=True)
                # Continue execution - don't fail transcription if intelligence processing fails

        else:
            logger.debug(f"⚪ Partial transcription for session {sanitize_for_log(session_id)}: '{result.text[:50]}...'")
            await broadcast_transcription_partial(session_id, transcript_data)

    except Exception as e:
        logger.error(f"Error handling transcription for session {sanitize_for_log(session_id)}: {e}")


async def handle_assemblyai_error(session_id: str, error: str):
    """
    Handle AssemblyAI connection error.

    Args:
        session_id: The meeting session identifier
        error: Error message
    """
    logger.error(f"AssemblyAI error for session {sanitize_for_log(session_id)}: {error}")

    # Publish error to Redis pub/sub for cross-process communication
    try:
        event_data = {
            "type": "TRANSCRIPTION_ERROR",
            "error": error,
            "timestamp": datetime.utcnow().isoformat()
        }
        await _publish_to_redis(session_id, event_data)
    except Exception as e:
        logger.warning(f"Failed to publish AssemblyAI error to Redis for session {sanitize_for_log(session_id)}: {e}")


# =============================================================================
# WebSocket Endpoints
# =============================================================================

@router.websocket("/ws/audio-stream/{session_id}")
async def websocket_audio_stream(
    websocket: WebSocket,
    session_id: str,
    token: str = Query(..., description="Authentication token"),
    db: AsyncSession = Depends(get_db)
):
    """
    WebSocket endpoint for audio streaming with binary frame support.

    Receives binary audio frames from Flutter client and forwards to AssemblyAI
    for real-time transcription with speaker diarization.

    Audio format: PCM 16kHz, 16-bit, mono (as specified in Task 2.0)

    Args:
        websocket: The WebSocket connection
        session_id: The meeting session identifier
        token: JWT authentication token
        db: Database session
    """
    user = None
    assemblyai_connection = None

    try:
        # Authenticate user
        user = await get_current_user_ws(token, db)
        if not user:
            await websocket.close(code=4001, reason="Unauthorized")
            logger.warning(f"Unauthorized audio stream connection attempt for session {sanitize_for_log(session_id)}")
            return

        user_id = str(user.id)

        # Accept WebSocket connection
        await websocket.accept()
        logger.info(f"Audio stream connected: session={sanitize_for_log(session_id)}, user={sanitize_for_log(user_id)}")

        # Store organization_id for this session (for orchestrator context)
        if user.last_active_organization_id:
            _session_organization_map[session_id] = user.last_active_organization_id
            # Update session timestamp for TTL tracking
            _session_timestamps[session_id] = datetime.now()

        # Send connection confirmation
        await websocket.send_json({
            "type": "audio_stream_connected",
            "status": "ready",
            "session_id": session_id,
            "timestamp": datetime.utcnow().isoformat()
        })

        # Get or create AssemblyAI connection for this session
        assemblyai_connection = await assemblyai_manager.get_or_create_connection(
            session_id=session_id,
            on_transcription=handle_transcription_result,
            on_error=handle_assemblyai_error
        )

        if not assemblyai_connection:
            await websocket.send_json({
                "type": "error",
                "error": "Failed to connect to transcription service",
                "timestamp": datetime.utcnow().isoformat()
            })
            await websocket.close(code=1011, reason="Transcription service unavailable")
            return

        # Audio streaming loop
        while True:
            try:
                # Receive message from client
                message = await websocket.receive()

                # Handle different message types
                if "bytes" in message:
                    # Binary audio frame
                    audio_data = message["bytes"]

                    # Forward to AssemblyAI
                    success = await assemblyai_manager.send_audio(session_id, audio_data)

                    if not success:
                        logger.warning(f"Failed to send audio to AssemblyAI for session {sanitize_for_log(session_id)}")

                elif "text" in message:
                    # JSON control message
                    try:
                        data = json.loads(message["text"])
                        message_type = data.get("type")

                        if message_type == "ping":
                            # Heartbeat response
                            await websocket.send_json({
                                "type": "pong",
                                "timestamp": datetime.utcnow().isoformat()
                            })

                        elif message_type == "audio_quality":
                            # Audio quality metrics from client (optional)
                            logger.debug(f"Audio quality metrics from client: {data}")

                        elif message_type == "stop_audio":
                            # Client requests to stop audio streaming
                            logger.info(f"Client requested to stop audio for session {sanitize_for_log(session_id)}")

                            # Cleanup orchestrator when audio streaming stops
                            try:
                                await cleanup_orchestrator(session_id)
                                logger.info(f"Orchestrator cleaned up for session {sanitize_for_log(session_id)}")
                            except Exception as e:
                                logger.error(f"Error cleaning up orchestrator: {e}")

                            break

                        else:
                            logger.warning(f"Unknown message type from audio client: {message_type}")

                    except json.JSONDecodeError as e:
                        logger.error(f"Invalid JSON from audio client: {e}")

            except Exception as e:
                error_msg = str(e)

                # Break loop if WebSocket is disconnected/closed
                if "disconnect" in error_msg.lower() or "closed" in error_msg.lower() or "receive" in error_msg.lower():
                    logger.info(f"WebSocket disconnected during message processing for session {sanitize_for_log(session_id)}")
                    break

                # Log unexpected errors
                logger.error(f"Error processing audio message: {e}")

                # Continue processing other messages for non-fatal errors

    except WebSocketDisconnect:
        logger.info(f"Audio stream disconnected for session {sanitize_for_log(session_id)}")

    except Exception as e:
        logger.error(f"Audio stream error for session {sanitize_for_log(session_id)}: {e}")

    finally:
        # Check if this was the last client for this session
        # If no other audio streams are active, we can close the AssemblyAI connection
        # For now, we'll keep the connection open until explicitly stopped
        # This will be improved in Task 4.3 (State Synchronization)

        # Cleanup orchestrator on disconnect
        try:
            await cleanup_orchestrator(session_id)
            logger.info(f"Orchestrator cleaned up for session {sanitize_for_log(session_id)}")
        except Exception as e:
            logger.error(f"Error cleaning up orchestrator in finally block: {e}")

        # Clean up session maps to prevent memory leak
        _session_organization_map.pop(session_id, None)
        _session_tier_config.pop(session_id, None)
        _session_timestamps.pop(session_id, None)
        logger.debug(f"Session context cleaned up for session {sanitize_for_log(session_id)}")

        logger.info(f"Audio stream cleanup for session {sanitize_for_log(session_id)}")


@router.websocket("/ws/live-insights/{session_id}")
async def websocket_live_insights(
    websocket: WebSocket,
    session_id: str,
    token: str = Query(..., description="Authentication token"),
    db: AsyncSession = Depends(get_db)
):
    """
    WebSocket endpoint for real-time meeting insights.

    Provides bidirectional communication for:
    - Server → Client: Questions, actions, answers, transcriptions
    - Client → Server: User feedback (mark answered, assign action, etc.)

    Args:
        websocket: The WebSocket connection
        session_id: The meeting session identifier
        token: JWT authentication token
        db: Database session
    """
    user = None

    try:
        # Authenticate user
        user = await get_current_user_ws(token, db)
        if not user:
            await websocket.close(code=4001, reason="Unauthorized")
            logger.warning(f"Unauthorized WebSocket connection attempt for session {sanitize_for_log(session_id)}")
            return

        user_id = str(user.id)

        # Connect to session
        await insights_manager.connect(websocket, session_id, user_id)

        # Update session timestamp for TTL tracking
        _session_timestamps[session_id] = datetime.now()

        # Send connection confirmation
        await websocket.send_json({
            "type": "connection",
            "status": "connected",
            "session_id": session_id,
            "user_id": user_id,
            "timestamp": datetime.utcnow().isoformat()
        })

        # Task 4.3: Send SYNC_STATE for reconnection and late join support
        # Retrieve and send current session state from database
        try:
            state_data = await get_session_state(session_id, db)
            await websocket.send_json({
                "type": "SYNC_STATE",
                "data": state_data,
                "timestamp": datetime.utcnow().isoformat()
            })
            logger.info(
                f"Sent SYNC_STATE to user {sanitize_for_log(user_id)} for session {sanitize_for_log(session_id)}: "
                f"{len(state_data.get('questions', []))} questions, {len(state_data.get('actions', []))} actions"
            )
        except Exception as e:
            logger.error(
                f"Failed to send SYNC_STATE to user {sanitize_for_log(user_id)}: {e}",
                exc_info=True
            )
            # Continue execution - sync failure shouldn't prevent connection

        # Message handling loop
        while True:
            try:
                # Receive message from client
                data = await websocket.receive_json()

                # Handle different message types
                message_type = data.get("type")

                if message_type == "ping":
                    # Heartbeat response
                    await websocket.send_json({
                        "type": "pong",
                        "timestamp": datetime.utcnow().isoformat()
                    })

                elif message_type == "SET_TIER_CONFIG":
                    # Client is setting tier configuration for answer discovery
                    enabled_tiers = data.get("enabled_tiers", [])
                    _session_tier_config[session_id] = enabled_tiers
                    # Update session timestamp when tier config is set
                    _session_timestamps[session_id] = datetime.now()
                    logger.info(
                        f"User {sanitize_for_log(user_id)} set tier configuration for session "
                        f"{sanitize_for_log(session_id)}: {enabled_tiers}"
                    )
                    await websocket.send_json({
                        "type": "tier_config_received",
                        "enabled_tiers": enabled_tiers,
                        "timestamp": datetime.utcnow().isoformat()
                    })

                elif message_type == "mark_answered":
                    # User manually marks question as answered
                    question_id = data.get("question_id")
                    if question_id:
                        logger.info(
                            f"User {sanitize_for_log(user_id)} marked question "
                            f"{sanitize_for_log(question_id)} as answered"
                        )
                        # TODO: Update question status in database
                        # This will be integrated with QuestionHandler service

                        await websocket.send_json({
                            "type": "feedback_received",
                            "action": "mark_answered",
                            "question_id": question_id,
                            "timestamp": datetime.utcnow().isoformat()
                        })

                elif message_type == "assign_action":
                    # User assigns action to someone
                    action_id = data.get("action_id")
                    owner = data.get("owner")
                    if action_id and owner:
                        logger.info(
                            f"User {sanitize_for_log(user_id)} assigned action "
                            f"{sanitize_for_log(action_id)} to {sanitize_for_log(owner)}"
                        )
                        # TODO: Update action owner in database
                        # This will be integrated with ActionHandler service

                        await websocket.send_json({
                            "type": "feedback_received",
                            "action": "assign_action",
                            "action_id": action_id,
                            "owner": owner,
                            "timestamp": datetime.utcnow().isoformat()
                        })

                elif message_type == "set_deadline":
                    # User sets deadline for action
                    action_id = data.get("action_id")
                    deadline = data.get("deadline")
                    if action_id and deadline:
                        logger.info(
                            f"User {sanitize_for_log(user_id)} set deadline for action "
                            f"{sanitize_for_log(action_id)} to {sanitize_for_log(deadline)}"
                        )
                        # TODO: Update action deadline in database
                        # This will be integrated with ActionHandler service

                        await websocket.send_json({
                            "type": "feedback_received",
                            "action": "set_deadline",
                            "action_id": action_id,
                            "deadline": deadline,
                            "timestamp": datetime.utcnow().isoformat()
                        })

                elif message_type == "dismiss_question":
                    # User dismisses a question
                    question_id = data.get("question_id")
                    if question_id:
                        logger.info(
                            f"User {sanitize_for_log(user_id)} dismissed question "
                            f"{sanitize_for_log(question_id)}"
                        )
                        # TODO: Mark question as dismissed in database
                        # This will be integrated with QuestionHandler service

                        await websocket.send_json({
                            "type": "feedback_received",
                            "action": "dismiss_question",
                            "question_id": question_id,
                            "timestamp": datetime.utcnow().isoformat()
                        })

                elif message_type == "dismiss_action":
                    # User dismisses an action
                    action_id = data.get("action_id")
                    if action_id:
                        logger.info(
                            f"User {sanitize_for_log(user_id)} dismissed action "
                            f"{sanitize_for_log(action_id)}"
                        )
                        # TODO: Mark action as dismissed in database
                        # This will be integrated with ActionHandler service

                        await websocket.send_json({
                            "type": "feedback_received",
                            "action": "dismiss_action",
                            "action_id": action_id,
                            "timestamp": datetime.utcnow().isoformat()
                        })

                elif message_type == "mark_complete":
                    # User marks action as complete
                    action_id = data.get("action_id")
                    if action_id:
                        logger.info(
                            f"User {sanitize_for_log(user_id)} marked action "
                            f"{sanitize_for_log(action_id)} as complete"
                        )
                        # TODO: Update action status to complete in database
                        # This will be integrated with ActionHandler service

                        await websocket.send_json({
                            "type": "feedback_received",
                            "action": "mark_complete",
                            "action_id": action_id,
                            "timestamp": datetime.utcnow().isoformat()
                        })

                else:
                    # Unknown message type
                    logger.warning(
                        f"Unknown message type '{message_type}' from user "
                        f"{sanitize_for_log(user_id)} in session {sanitize_for_log(session_id)}"
                    )
                    await websocket.send_json({
                        "type": "error",
                        "error": f"Unknown message type: {message_type}",
                        "timestamp": datetime.utcnow().isoformat()
                    })

            except json.JSONDecodeError as e:
                logger.error(f"Invalid JSON from client: {e}")
                await websocket.send_json({
                    "type": "error",
                    "error": "Invalid JSON format",
                    "timestamp": datetime.utcnow().isoformat()
                })

            except Exception as e:
                error_msg = str(e)

                # Check if this is a disconnect/close error (expected during shutdown)
                if "disconnect" in error_msg.lower() or "closed" in error_msg.lower() or "NO_STATUS_RCVD" in error_msg:
                    logger.info(f"WebSocket closed during message processing for session {sanitize_for_log(session_id)}")
                    break

                # Log unexpected errors
                logger.error(f"Error processing message: {e}")

                # Try to send error message only if WebSocket is still connected
                try:
                    await websocket.send_json({
                        "type": "error",
                        "error": "Internal server error",
                        "timestamp": datetime.utcnow().isoformat()
                    })
                except Exception as send_error:
                    logger.debug(f"Could not send error message (WebSocket likely closed): {send_error}")

    except WebSocketDisconnect:
        logger.info(f"WebSocket disconnected for session {sanitize_for_log(session_id)}")

    except Exception as e:
        logger.error(f"WebSocket error for session {sanitize_for_log(session_id)}: {e}")

    finally:
        # Clean up connection
        if user:
            await insights_manager.disconnect(websocket)
