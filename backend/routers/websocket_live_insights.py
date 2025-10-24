"""
WebSocket router for real-time meeting insights streaming.

Handles live meeting transcription and insight extraction, providing
real-time feedback to participants during meetings.

Architecture:
- Receives audio chunks from Flutter client (~10s each)
- Transcribes using Replicate (incredibly-fast-whisper)
- Extracts insights using Claude Haiku
- Broadcasts insights back to client via WebSocket

Smart Batching Optimizations (reduces API costs by ~66%):
- Skips transcripts shorter than 15 characters
- Processes insights every 3rd chunk (batching)
- Only calls LLM when meaningful content detected
- Accumulates context across chunks for better results

Performance:
- Before: ~18 LLM calls per minute (every chunk)
- After: ~6 LLM calls per minute (every 3rd meaningful chunk)
- Cost reduction: 66% fewer API calls
- Latency: Similar (batching doesn't delay meaningful insights)
"""

import asyncio
import json
import logging
import time
import uuid
import base64
import tempfile
import os
from typing import Dict, Optional, Set, List
from datetime import datetime
from enum import Enum
from pathlib import Path

from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Depends, Query, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from db.database import get_db
from models.project import Project
from models.user import User
from services.intelligence.realtime_meeting_insights import (
    realtime_insights_service,
    TranscriptChunk,
    InsightType
)
from services.intelligence.adaptive_insight_processor import get_adaptive_processor
from services.intelligence.transcript_validator import get_transcript_validator, TranscriptQuality
from services.intelligence.proactive_assistance_feedback_service import get_feedback_service
from services.intelligence.topic_coherence_detector import get_topic_coherence_detector
from services.transcription.replicate_transcription_service import get_replicate_service
from dependencies.auth import get_current_user_ws
from utils.logger import get_logger, sanitize_for_log
from config import get_settings

logger = get_logger(__name__)
router = APIRouter(prefix="/ws", tags=["websocket", "live-insights"])

# Adaptive Processing Configuration (replaces blind batching)
USE_ADAPTIVE_PROCESSING = True  # Set to False to revert to old BATCH_SIZE behavior
MIN_TRANSCRIPT_LENGTH = 15  # Skip transcripts shorter than this (chars) - DEPRECATED with adaptive
BATCH_SIZE = 3  # Process insights every Nth chunk (reduces API calls by ~66%) - DEPRECATED with adaptive


class MeetingPhase(Enum):
    """Phases of a live meeting session."""
    INITIALIZING = "initializing"
    ACTIVE = "active"
    PAUSED = "paused"
    FINALIZING = "finalizing"
    COMPLETED = "completed"
    ERROR = "error"


class LiveMeetingSession:
    """Represents an active live meeting session."""

    def __init__(
        self,
        session_id: str,
        project_id: str,
        organization_id: str,
        user_id: str,
        websocket: WebSocket,
        enabled_insight_types: Optional[List[str]] = None
    ):
        self.session_id = session_id
        self.project_id = project_id
        self.organization_id = organization_id
        self.user_id = user_id
        self.websocket = websocket

        # User preferences for cost optimization
        # Only extract insight types the user wants to see
        self.enabled_insight_types = enabled_insight_types or [
            "action_item", "decision", "question", "risk",
            "key_point", "related_discussion", "contradiction", "missing_info"
        ]
        logger.info(f"Session {session_id} will extract insight types: {self.enabled_insight_types}")

        # Session state
        self.phase = MeetingPhase.INITIALIZING
        self.start_time = datetime.utcnow()
        self.last_activity = datetime.utcnow()

        # Transcription state
        self.chunk_index = 0
        self.total_audio_duration = 0.0
        self.accumulated_transcript = []

        # Adaptive processing state
        self.chunks_since_last_process = 0
        self.accumulated_context: List[str] = []

        # Insight tracking
        self.total_insights_extracted = 0
        self.insights_by_type: Dict[str, int] = {}

        # Performance metrics
        self.processing_times = []
        self.transcription_times = []

        # Cancellation support
        self.is_cancelled = False

    def cancel(self) -> None:
        """Mark session as cancelled to stop ongoing processing."""
        self.is_cancelled = True
        logger.info(f"Session {self.session_id} marked as cancelled")

    def update_activity(self) -> None:
        """Update last activity timestamp."""
        self.last_activity = datetime.utcnow()

    def add_processing_time(self, ms: float) -> None:
        """Track processing time for metrics."""
        self.processing_times.append(ms)

    def add_transcription_time(self, ms: float) -> None:
        """Track transcription time for metrics."""
        self.transcription_times.append(ms)

    def increment_insight_count(self, insight_type: str) -> None:
        """Increment count for specific insight type."""
        self.insights_by_type[insight_type] = self.insights_by_type.get(insight_type, 0) + 1
        self.total_insights_extracted += 1

    def get_metrics(self) -> Dict:
        """Get session performance metrics."""
        return {
            'session_duration_seconds': (datetime.utcnow() - self.start_time).total_seconds(),
            'chunks_processed': self.chunk_index,
            'total_insights': self.total_insights_extracted,
            'insights_by_type': self.insights_by_type,
            'avg_processing_time_ms': sum(self.processing_times) / len(self.processing_times) if self.processing_times else 0,
            'avg_transcription_time_ms': sum(self.transcription_times) / len(self.transcription_times) if self.transcription_times else 0,
        }


class LiveInsightsConnectionManager:
    """Manages WebSocket connections for live meeting insights."""

    def __init__(self):
        # Active sessions: session_id -> LiveMeetingSession
        self.active_sessions: Dict[str, LiveMeetingSession] = {}

        # User connections: user_id -> set of session_ids
        self.user_sessions: Dict[str, Set[str]] = {}

        # Session cleanup task
        self._cleanup_task: Optional[asyncio.Task] = None
        self._session_timeout_seconds = 7200  # 2 hours

    async def create_session(
        self,
        project_id: str,
        organization_id: str,
        user_id: str,
        websocket: WebSocket,
        db: AsyncSession,
        enabled_insight_types: Optional[List[str]] = None
    ) -> LiveMeetingSession:
        """Create a new live meeting session."""

        # Generate session ID
        session_id = f"live_{project_id}_{user_id}_{int(time.time())}"

        # Create session with user preferences
        session = LiveMeetingSession(
            session_id=session_id,
            project_id=project_id,
            organization_id=organization_id,
            user_id=user_id,
            websocket=websocket,
            enabled_insight_types=enabled_insight_types
        )

        # Store session
        self.active_sessions[session_id] = session

        if user_id not in self.user_sessions:
            self.user_sessions[user_id] = set()
        self.user_sessions[user_id].add(session_id)

        # Start cleanup task if not running
        if self._cleanup_task is None or self._cleanup_task.done():
            self._cleanup_task = asyncio.create_task(self._cleanup_stale_sessions())

        logger.info(
            f"Created live meeting session: {sanitize_for_log(session_id)} "
            f"for project {sanitize_for_log(project_id)}"
        )

        # Send initialization confirmation
        await self.send_message(session, {
            'type': 'session_initialized',
            'session_id': session_id,
            'project_id': project_id,
            'timestamp': datetime.utcnow().isoformat()
        })

        return session

    async def end_session(self, session_id: str, db: AsyncSession) -> Dict:
        """End a live meeting session and finalize insights."""

        if session_id not in self.active_sessions:
            return {'error': 'Session not found'}

        session = self.active_sessions[session_id]
        session.phase = MeetingPhase.FINALIZING

        try:
            # Finalize insights and persist to database
            final_insights = await realtime_insights_service.finalize_session(
                session_id=session_id,
                project_id=session.project_id,
                organization_id=session.organization_id,
                db=db
            )

            # Get session metrics
            metrics = session.get_metrics()

            # Send final summary
            await self.send_message(session, {
                'type': 'session_finalized',
                'session_id': session_id,
                'insights': final_insights,
                'metrics': metrics,
                'timestamp': datetime.utcnow().isoformat()
            })

            session.phase = MeetingPhase.COMPLETED

            # Cleanup topic coherence state
            topic_detector = get_topic_coherence_detector()
            topic_detector.cleanup_session(session_id)

            # Cleanup session
            self._remove_session(session_id)

            logger.info(f"Finalized session {sanitize_for_log(session_id)}")

            return {
                'session_id': session_id,
                'insights': final_insights,
                'metrics': metrics
            }

        except Exception as e:
            logger.error(f"Error finalizing session {session_id}: {e}", exc_info=True)
            session.phase = MeetingPhase.ERROR
            return {'error': str(e)}

    def _remove_session(self, session_id: str) -> None:
        """Remove session from active sessions."""
        if session_id in self.active_sessions:
            session = self.active_sessions[session_id]
            user_id = session.user_id

            del self.active_sessions[session_id]

            if user_id in self.user_sessions:
                self.user_sessions[user_id].discard(session_id)
                if not self.user_sessions[user_id]:
                    del self.user_sessions[user_id]

    async def send_message(self, session: LiveMeetingSession, data: Dict) -> bool:
        """
        Send JSON message to WebSocket client with connection state validation.

        Returns:
            True if message sent successfully, False otherwise
        """
        try:
            # Check if WebSocket is still connected
            if not hasattr(session.websocket, 'client_state'):
                logger.warning(f"WebSocket for session {session.session_id} has no client_state")
                return False

            # Verify WebSocket is in connected state
            from starlette.websockets import WebSocketState
            if session.websocket.client_state != WebSocketState.CONNECTED:
                logger.warning(
                    f"WebSocket for session {session.session_id} not connected "
                    f"(state: {session.websocket.client_state})"
                )
                return False

            await session.websocket.send_json(data)
            session.update_activity()
            return True

        except WebSocketDisconnect:
            # Client disconnected gracefully (e.g., user stopped recording)
            logger.info(f"Session {session.session_id} WebSocket closed before insights sent")
            session.cancel()  # Mark session as cancelled to stop ongoing processing
            return False

        except RuntimeError as e:
            # Handle "Cannot call send once a close message has been sent"
            if "close message" in str(e) or "not connected" in str(e).lower():
                logger.info(f"Session {session.session_id} WebSocket already closed")
                return False
            logger.error(f"Runtime error sending message to session {session.session_id}: {e}")
            return False

        except Exception as e:
            # Check if it's a known disconnection error
            error_str = str(e).lower()
            if any(keyword in error_str for keyword in ['disconnect', 'closed', 'connection']):
                logger.info(f"Session {session.session_id} WebSocket connection lost")
                return False

            # Log unexpected errors with full traceback
            logger.error(
                f"Unexpected error sending message to session {session.session_id}: {e}",
                exc_info=True
            )
            return False

    async def _cleanup_stale_sessions(self) -> None:
        """Background task to cleanup stale sessions."""
        while True:
            try:
                await asyncio.sleep(300)  # Check every 5 minutes

                current_time = datetime.utcnow()
                stale_sessions = []

                for session_id, session in self.active_sessions.items():
                    time_since_activity = (current_time - session.last_activity).total_seconds()

                    if time_since_activity > self._session_timeout_seconds:
                        stale_sessions.append(session_id)

                # Remove stale sessions
                for session_id in stale_sessions:
                    logger.warning(f"Cleaning up stale session: {sanitize_for_log(session_id)}")
                    self._remove_session(session_id)

            except asyncio.CancelledError:
                break
            except Exception as e:
                logger.error(f"Error in cleanup task: {e}", exc_info=True)


# Global connection manager
live_insights_manager = LiveInsightsConnectionManager()


@router.websocket("/live-insights")
async def websocket_live_insights(
    websocket: WebSocket,
    project_id: str = Query(...),
    db: AsyncSession = Depends(get_db)
):
    """
    WebSocket endpoint for real-time meeting insights.

    Authentication:
    - Pass JWT token as query parameter: ?token=<jwt_token>&project_id=<id>

    Message Protocol:

    Client -> Server:
    1. Initialize: {"action": "init", "project_id": "..."}
    2. Audio Chunk: {"action": "audio_chunk", "data": base64_audio, "duration": 10.0}
    3. Pause: {"action": "pause"}
    4. Resume: {"action": "resume"}
    5. End: {"action": "end"}

    Server -> Client:
    1. Session Init: {"type": "session_initialized", "session_id": "..."}
    2. Transcription: {"type": "transcript_chunk", "text": "...", "chunk_index": 0}
    3. Insights: {"type": "insights_extracted", "insights": [...]}
    4. Metrics: {"type": "metrics_update", "metrics": {...}}
    5. Final Summary: {"type": "session_finalized", "insights": {...}, "metrics": {...}}
    6. Error: {"type": "error", "message": "..."}
    """

    session: Optional[LiveMeetingSession] = None
    settings = get_settings()

    try:
        # Accept WebSocket connection FIRST
        await websocket.accept()

        # Authenticate user
        try:
            current_user = await get_current_user_ws(websocket, db=db)
            user_id = str(current_user.id)
        except HTTPException as e:
            await websocket.close(code=1008, reason=f"Authentication failed: {e.detail}")
            return

        # Verify user has access to the project and get organization
        from sqlalchemy import select
        result = await db.execute(
            select(Project).where(Project.id == project_id)
        )
        project = result.scalar_one_or_none()

        if not project:
            await websocket.close(code=1008, reason="Project not found")
            return

        organization_id = str(project.organization_id)

        # Verify user is member of the organization
        from models.organization_member import OrganizationMember
        result = await db.execute(
            select(OrganizationMember).where(
                OrganizationMember.user_id == current_user.id,
                OrganizationMember.organization_id == project.organization_id
            )
        )
        membership = result.scalar_one_or_none()

        if not membership:
            await websocket.close(code=1008, reason="User not authorized to access this project")
            return

        # Wait for initialization message
        init_data = await websocket.receive_json()

        if init_data.get('action') != 'init':
            await websocket.close(code=1008, reason="First message must be 'init'")
            return

        # Extract user's insight type preferences for cost optimization
        enabled_insight_types = init_data.get('enabled_insight_types')
        if enabled_insight_types:
            logger.info(f"User requested insight types: {enabled_insight_types}")

        # Create session with user preferences (this will send session_initialized message)
        session = await live_insights_manager.create_session(
            project_id=project_id,
            organization_id=organization_id,
            user_id=user_id,
            websocket=websocket,
            db=db,
            enabled_insight_types=enabled_insight_types
        )

        session.phase = MeetingPhase.ACTIVE

        # Main message loop
        while True:
            try:
                data = await websocket.receive_json()
                action = data.get('action')

                if action == 'audio_chunk':
                    await handle_audio_chunk(session, data, db)

                elif action == 'pause':
                    session.phase = MeetingPhase.PAUSED
                    await live_insights_manager.send_message(session, {
                        'type': 'session_paused',
                        'timestamp': datetime.utcnow().isoformat()
                    })

                elif action == 'resume':
                    session.phase = MeetingPhase.ACTIVE
                    await live_insights_manager.send_message(session, {
                        'type': 'session_resumed',
                        'timestamp': datetime.utcnow().isoformat()
                    })

                elif action == 'end':
                    # Finalize session
                    final_result = await live_insights_manager.end_session(session.session_id, db)
                    break

                elif action == 'ping':
                    # Heartbeat
                    await live_insights_manager.send_message(session, {
                        'type': 'pong',
                        'timestamp': datetime.utcnow().isoformat()
                    })

                elif action == 'feedback':
                    # User feedback on proactive assistance
                    await handle_feedback(session, data, db)

                else:
                    await live_insights_manager.send_message(session, {
                        'type': 'error',
                        'message': f'Unknown action: {action}'
                    })

            except WebSocketDisconnect:
                # Handle graceful disconnection
                logger.info(f"WebSocket disconnected during receive for session {session.session_id}")
                if session:
                    session.cancel()  # Stop any ongoing processing
                break

            except RuntimeError as e:
                # Handle "WebSocket is not connected" errors
                if "not connected" in str(e).lower() or "close message" in str(e).lower():
                    logger.info(f"WebSocket connection lost for session {session.session_id}")
                    if session:
                        session.cancel()  # Stop any ongoing processing
                    break
                raise  # Re-raise other RuntimeErrors

    except WebSocketDisconnect:
        logger.info(f"Client disconnected from live insights session")
        if session:
            session.cancel()  # Stop any ongoing processing
            live_insights_manager._remove_session(session.session_id)

    except Exception as e:
        logger.error(f"Error in live insights WebSocket: {e}", exc_info=True)
        if session:
            await live_insights_manager.send_message(session, {
                'type': 'error',
                'message': str(e)
            })
            live_insights_manager._remove_session(session.session_id)


async def handle_feedback(
    session: LiveMeetingSession,
    data: Dict,
    db: AsyncSession
) -> None:
    """
    Handle user feedback on proactive assistance suggestions.

    Expected data format:
    {
        "action": "feedback",
        "insight_id": "session_0_2",
        "helpful": true,  # or false
        "assistance_type": "auto_answer",
        "confidence_score": 0.89,  # optional
        "feedback_text": "Answer was accurate",  # optional
        "feedback_category": "helpful"  # optional
    }

    Args:
        session: Active meeting session
        data: Feedback data from client
        db: Database session
    """
    try:
        # Extract feedback data
        insight_id = data.get('insight_id')
        is_helpful = data.get('helpful')
        assistance_type = data.get('assistance_type')
        confidence_score = data.get('confidence_score')
        feedback_text = data.get('feedback_text')
        feedback_category = data.get('feedback_category')

        # Validate required fields
        if not insight_id or is_helpful is None or not assistance_type:
            await live_insights_manager.send_message(session, {
                'type': 'feedback_error',
                'message': 'Missing required feedback fields (insight_id, helpful, assistance_type)'
            })
            return

        # Get feedback service
        feedback_service = get_feedback_service()

        # Record feedback
        feedback = await feedback_service.record_feedback(
            db=db,
            session_id=session.session_id,
            insight_id=insight_id,
            project_id=session.project_id,
            organization_id=session.organization_id,
            user_id=session.user_id,
            assistance_type=assistance_type,
            is_helpful=is_helpful,
            confidence_score=confidence_score,
            feedback_text=feedback_text,
            feedback_category=feedback_category,
            metadata={
                'chunk_index': session.chunk_index,
                'session_phase': session.phase.value
            }
        )

        # Send confirmation
        await live_insights_manager.send_message(session, {
            'type': 'feedback_recorded',
            'feedback_id': str(feedback.id),
            'insight_id': insight_id,
            'timestamp': datetime.utcnow().isoformat()
        })

        logger.info(
            f"Recorded {'positive' if is_helpful else 'negative'} feedback for "
            f"{assistance_type} (insight_id={insight_id}, session={session.session_id})"
        )

    except Exception as e:
        logger.error(f"Error handling feedback: {e}")
        await live_insights_manager.send_message(session, {
            'type': 'feedback_error',
            'message': f'Failed to record feedback: {str(e)}'
        })


async def handle_audio_chunk(
    session: LiveMeetingSession,
    data: Dict,
    db: AsyncSession
) -> None:
    """
    Process incoming audio chunk: transcribe and extract insights.

    Uses smart batching to reduce API calls:
    - Skips empty/short transcripts (< 15 chars)
    - Batches chunks (processes every 3rd chunk)
    - Accumulates context for better LLM results

    Args:
        session: Active meeting session
        data: Audio chunk data from client
        db: Database session
    """
    try:
        start_time = time.time()

        # Extract audio data
        audio_data = data.get('data')  # Base64 encoded audio
        duration = data.get('duration', 10.0)
        speaker = data.get('speaker')

        if not audio_data:
            await live_insights_manager.send_message(session, {
                'type': 'error',
                'message': 'No audio data provided'
            })
            return

        # Transcribe audio using Replicate service
        transcript_text = ""
        temp_audio_path = None

        try:
            # Decode base64 audio data
            audio_bytes = base64.b64decode(audio_data)
            audio_size_kb = len(audio_bytes) / 1024

            # AudioStreamingService sends raw PCM16 data (16kHz, mono, 16-bit)
            # Convert to WAV format for Whisper compatibility
            import wave
            import io

            # Create WAV file with proper header
            wav_buffer = io.BytesIO()
            with wave.open(wav_buffer, 'wb') as wav_file:
                wav_file.setnchannels(1)  # Mono
                wav_file.setsampwidth(2)   # 16-bit = 2 bytes
                wav_file.setframerate(16000)  # 16kHz sample rate
                wav_file.writeframes(audio_bytes)

            wav_bytes = wav_buffer.getvalue()

            # Create temporary file for audio
            with tempfile.NamedTemporaryFile(delete=False, suffix='.wav') as temp_file:
                temp_audio_path = temp_file.name
                temp_file.write(wav_bytes)

            logger.info(
                f"Chunk {session.chunk_index}: Received {audio_size_kb:.2f} KB audio, "
                f"duration: {duration}s, saved to: {temp_audio_path}"
            )

            # Get Replicate transcription service
            settings = get_settings()
            replicate_service = get_replicate_service(api_key=settings.replicate_api_key)

            # Transcribe audio
            transcription_result = await replicate_service.transcribe_audio_file(
                audio_path=temp_audio_path,
                language=None  # Auto-detect language
            )

            transcript_text = transcription_result.get('text', '').strip()
            segments_count = len(transcription_result.get('segments', []))

            if not transcript_text:
                logger.warning(f"Transcription returned empty text for chunk {session.chunk_index}")
                transcript_text = "[No speech detected]"

            # Log transcription result with preview
            text_preview = transcript_text[:100] + ('...' if len(transcript_text) > 100 else '')
            logger.info(
                f"Chunk {session.chunk_index} transcribed: {len(transcript_text)} chars, "
                f"{segments_count} segments, text: '{text_preview}'"
            )

        except Exception as e:
            logger.error(f"Transcription error for chunk {session.chunk_index}: {e}", exc_info=True)
            await live_insights_manager.send_message(session, {
                'type': 'error',
                'message': f'Transcription failed: {str(e)}'
            })
            transcript_text = "[Transcription failed]"

        finally:
            # Clean up temporary file
            if temp_audio_path and os.path.exists(temp_audio_path):
                try:
                    os.unlink(temp_audio_path)
                    logger.debug(f"Deleted temporary file: {temp_audio_path}")
                except Exception as e:
                    logger.warning(f"Failed to delete temporary file {temp_audio_path}: {e}")

        transcription_time = time.time() - start_time
        session.add_transcription_time(transcription_time * 1000)

        # Validate transcript quality using TranscriptValidator
        validator = get_transcript_validator()
        validation_result = validator.validate(transcript_text)

        # Log validation results for monitoring
        if not validation_result.is_valid:
            logger.info(
                f"Chunk {session.chunk_index} transcript filtered: "
                f"quality={validation_result.quality.value}, "
                f"reason={validation_result.reason}, "
                f"words={validation_result.word_count}, "
                f"chars={validation_result.char_count}"
            )
        else:
            logger.debug(
                f"Chunk {session.chunk_index} transcript valid: "
                f"words={validation_result.word_count}, "
                f"chars={validation_result.char_count}"
            )

        is_meaningful = validation_result.is_valid

        # Check if session has been cancelled
        if session.is_cancelled:
            logger.info(f"Session {session.session_id} cancelled, aborting chunk {session.chunk_index} processing")
            return

        # Send transcription update
        # Check WebSocket connection before sending
        sent = await live_insights_manager.send_message(session, {
            'type': 'transcript_chunk',
            'chunk_index': session.chunk_index,
            'text': transcript_text,
            'speaker': speaker,
            'timestamp': datetime.utcnow().isoformat(),
            'is_valid': validation_result.is_valid,
            'quality': validation_result.quality.value
        })

        # If WebSocket is closed, abort processing
        if not sent:
            logger.info(f"Session {session.session_id} WebSocket already closed, aborting processing")
            session.cancel()  # Mark as cancelled to prevent further processing
            return

        # Create transcript chunk
        chunk = TranscriptChunk(
            chunk_id=f"{session.session_id}_{session.chunk_index}",
            text=transcript_text,
            timestamp=datetime.utcnow(),
            index=session.chunk_index,
            speaker=speaker,
            duration_seconds=duration
        )

        # Adaptive Processing: Intelligently decide when to process based on content
        processing_stats = None  # Will hold stats for metadata
        adaptive_reason = None

        if USE_ADAPTIVE_PROCESSING:
            adaptive_processor = get_adaptive_processor()
            topic_detector = get_topic_coherence_detector()

            # Check topic coherence (only if we have accumulated content)
            topic_change_detected = False
            topic_similarity = None

            if is_meaningful and session.accumulated_context:
                should_batch, batch_reason, similarity = await topic_detector.should_batch(
                    session_id=session.session_id,
                    current_chunk=transcript_text,
                    current_chunk_index=session.chunk_index,
                    accumulated_chunks=session.accumulated_context
                )

                topic_change_detected = not should_batch
                topic_similarity = similarity

                logger.debug(
                    f"Chunk {session.chunk_index} topic coherence: "
                    f"{'CONTINUE BATCH' if should_batch else 'TOPIC CHANGE'} | "
                    f"reason={batch_reason}"
                )

            # Get semantic analysis with topic coherence input
            should_process_insights, reason = adaptive_processor.should_process_now(
                current_text=transcript_text,
                chunk_index=session.chunk_index,
                chunks_since_last_process=session.chunks_since_last_process,
                accumulated_context=session.accumulated_context,
                topic_change_detected=topic_change_detected,
                topic_similarity=topic_similarity
            )

            adaptive_reason = reason

            # Add to accumulated context (up to max batch size)
            if is_meaningful:
                session.accumulated_context.append(transcript_text)
                # Prevent unbounded growth
                if len(session.accumulated_context) > adaptive_processor.max_batch_size:
                    session.accumulated_context.pop(0)
                session.chunks_since_last_process += 1

            # Get stats for processing metadata
            processing_stats = adaptive_processor.get_stats(transcript_text)

            # Log processing decision with topic coherence info
            topic_info = ""
            if topic_similarity is not None:
                topic_info = f" | topic_similarity={topic_similarity:.3f}"

            logger.info(
                f"Chunk {session.chunk_index} analysis: "
                f"{reason} | "
                f"priority={processing_stats['priority']} | "
                f"score={processing_stats['semantic_score']:.2f} | "
                f"words={processing_stats['word_count']}"
                f"{topic_info}"
            )

            # Reset counters if processing
            if should_process_insights:
                session.chunks_since_last_process = 0
                session.accumulated_context.clear()

        else:
            # Legacy batching: Only process insights when we have meaningful content
            # and we've accumulated enough chunks
            should_process_insights = (
                is_meaningful and
                (session.chunk_index % BATCH_SIZE == 0 or session.chunk_index == 0)
            )

            adaptive_reason = "legacy_batching" if should_process_insights else "batching_accumulation"

            if not is_meaningful:
                logger.info(
                    f"Skipping insight extraction for chunk {session.chunk_index}: "
                    f"validation failed - {validation_result.reason}"
                )
            elif not should_process_insights:
                logger.debug(
                    f"Batching chunk {session.chunk_index}: "
                    f"will process at chunk {(session.chunk_index // BATCH_SIZE + 1) * BATCH_SIZE}"
                )

        # Extract insights (only when adaptive processor or batching decides to)
        # Create empty ProcessingResult for when we skip processing
        from services.intelligence.realtime_meeting_insights import ProcessingResult, ProcessingStatus

        result = ProcessingResult(
            session_id=session.session_id,
            chunk_index=chunk.index,
            insights=[],
            proactive_assistance=[],
            evolved_insights=[],
            overall_status=ProcessingStatus.OK,
            phase_status={},
            total_insights_count=0,
            processing_time_ms=0
        )

        if should_process_insights:
            # Final cancellation check before expensive insight extraction
            if session.is_cancelled:
                logger.info(f"Session {session.session_id} cancelled before insight extraction")
                return

            insights_start = time.time()

            result = await realtime_insights_service.process_transcript_chunk(
                session_id=session.session_id,
                project_id=session.project_id,
                organization_id=session.organization_id,
                chunk=chunk,
                db=db,
                # Pass user preferences for cost optimization
                enabled_insight_types=session.enabled_insight_types,
                # Pass processing stats for metadata
                adaptive_stats=processing_stats,
                adaptive_reason=adaptive_reason
            )

            insights_time = time.time() - insights_start
            session.add_processing_time(insights_time * 1000)

        # Update session state
        session.chunk_index += 1
        session.total_audio_duration += duration
        session.accumulated_transcript.append(transcript_text)

        # Track insights
        for insight in result.insights:
            insight_type = insight.type.value
            session.increment_insight_count(insight_type)

        # Build WebSocket message with partial results support
        message = {
            'type': 'insights_extracted',
            'chunk_index': chunk.index,
            'insights': [insight.to_dict() for insight in result.insights],  # New insights
            'evolved_insights': result.evolved_insights,  # Insights that evolved from previous ones
            'total_insights': result.total_insights_count,
            'processing_time_ms': result.processing_time_ms,
            'timestamp': datetime.utcnow().isoformat(),
            'proactive_assistance': result.proactive_assistance,
            'status': result.overall_status.value,  # ok | degraded | failed
            'phase_status': {k: v.value for k, v in result.phase_status.items()},
        }

        # Add warning message for degraded status
        warning_msg = result.get_warning_message()
        if warning_msg:
            message['warning'] = warning_msg
            logger.warning(f"Session {session.session_id} degraded: {warning_msg}")

        # Include error details if any phases failed (for debugging/monitoring)
        if result.failed_phases:
            message['failed_phases'] = result.failed_phases
            # Don't expose internal error messages to client for security
            # but log them for debugging
            logger.error(
                f"Session {session.session_id} phase failures: {result.error_messages}"
            )

        # Add skip reason if chunk was skipped
        if result.skipped_reason:
            message['skipped_reason'] = result.skipped_reason
            if result.similarity_score is not None:
                message['similarity_score'] = result.similarity_score

        # Send insights update
        # Check WebSocket connection before sending
        sent = await live_insights_manager.send_message(session, message)

        # If WebSocket is closed, abort processing
        if not sent:
            return

        # Send metrics update every 10 chunks
        if session.chunk_index % 10 == 0:
            sent = await live_insights_manager.send_message(session, {
                'type': 'metrics_update',
                'metrics': session.get_metrics(),
                'timestamp': datetime.utcnow().isoformat()
            })

            # If WebSocket is closed, abort processing
            if not sent:
                return

    except Exception as e:
        logger.error(f"Error handling audio chunk: {e}", exc_info=True)
        # Try to send error message, but don't fail if WebSocket is closed
        await live_insights_manager.send_message(session, {
            'type': 'error',
            'message': f'Failed to process audio chunk: {str(e)}'
        })


# Export router and manager
__all__ = ['router', 'live_insights_manager']
