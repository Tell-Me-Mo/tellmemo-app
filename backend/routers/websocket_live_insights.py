"""
WebSocket router for real-time meeting insights communication.

This module provides WebSocket endpoints for streaming live meeting intelligence
including question detection, answer discovery, and action item tracking.
"""

import asyncio
import json
from datetime import datetime
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

logger = get_logger(__name__)

router = APIRouter()


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
            self.active_connections[session_id].add(websocket)

            # Store reverse mappings
            self.websocket_to_user[websocket] = user_id
            self.websocket_to_session[websocket] = session_id

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

                # Remove empty session
                if not self.active_connections[session_id]:
                    del self.active_connections[session_id]

            # Clean up reverse mappings
            self.websocket_to_user.pop(websocket, None)
            self.websocket_to_session.pop(websocket, None)

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


# Global connection manager instance
insights_manager = LiveInsightsConnectionManager()


# =============================================================================
# Broadcast Helper Functions
# =============================================================================
# These functions are called by backend services to broadcast insights to clients
# =============================================================================

async def broadcast_question_detected(session_id: str, question_data: dict):
    """
    Broadcast when a new question is detected.

    Args:
        session_id: The meeting session identifier
        question_data: Question details including id, text, speaker, timestamp
    """
    await insights_manager.broadcast_to_session(
        session_id,
        {
            "type": "QUESTION_DETECTED",
            "data": question_data,
            "timestamp": datetime.utcnow().isoformat()
        }
    )
    logger.debug(f"Broadcast QUESTION_DETECTED to session {sanitize_for_log(session_id)}")


async def broadcast_rag_result(session_id: str, question_id: str, result_data: dict):
    """
    Broadcast RAG search result for a question (progressive delivery).

    Args:
        session_id: The meeting session identifier
        question_id: The question identifier
        result_data: RAG result including document, relevance score, metadata
    """
    await insights_manager.broadcast_to_session(
        session_id,
        {
            "type": "RAG_RESULT",
            "question_id": question_id,
            "data": result_data,
            "timestamp": datetime.utcnow().isoformat()
        }
    )
    logger.debug(f"Broadcast RAG_RESULT to session {sanitize_for_log(session_id)}")


async def broadcast_answer_from_meeting(session_id: str, question_id: str, answer_data: dict):
    """
    Broadcast when an answer is found earlier in the meeting.

    Args:
        session_id: The meeting session identifier
        question_id: The question identifier
        answer_data: Answer details including text, speaker, timestamp, confidence
    """
    await insights_manager.broadcast_to_session(
        session_id,
        {
            "type": "ANSWER_FROM_MEETING",
            "question_id": question_id,
            "data": answer_data,
            "timestamp": datetime.utcnow().isoformat()
        }
    )
    logger.debug(f"Broadcast ANSWER_FROM_MEETING to session {sanitize_for_log(session_id)}")


async def broadcast_question_answered_live(session_id: str, question_id: str, answer_data: dict):
    """
    Broadcast when a question is answered in live conversation.

    Args:
        session_id: The meeting session identifier
        question_id: The question identifier
        answer_data: Answer details including text, speaker, timestamp, confidence
    """
    await insights_manager.broadcast_to_session(
        session_id,
        {
            "type": "QUESTION_ANSWERED_LIVE",
            "question_id": question_id,
            "data": answer_data,
            "timestamp": datetime.utcnow().isoformat()
        }
    )
    logger.debug(f"Broadcast QUESTION_ANSWERED_LIVE to session {sanitize_for_log(session_id)}")


async def broadcast_gpt_generated_answer(session_id: str, question_id: str, answer_data: dict):
    """
    Broadcast GPT-generated answer (Tier 4 fallback).

    Args:
        session_id: The meeting session identifier
        question_id: The question identifier
        answer_data: Answer including text, confidence, disclaimer
    """
    await insights_manager.broadcast_to_session(
        session_id,
        {
            "type": "GPT_GENERATED_ANSWER",
            "question_id": question_id,
            "data": answer_data,
            "timestamp": datetime.utcnow().isoformat()
        }
    )
    logger.debug(f"Broadcast GPT_GENERATED_ANSWER to session {sanitize_for_log(session_id)}")


async def broadcast_question_unanswered(session_id: str, question_id: str):
    """
    Broadcast when a question remains unanswered after all tiers exhausted.

    Args:
        session_id: The meeting session identifier
        question_id: The question identifier
    """
    await insights_manager.broadcast_to_session(
        session_id,
        {
            "type": "QUESTION_UNANSWERED",
            "question_id": question_id,
            "timestamp": datetime.utcnow().isoformat()
        }
    )
    logger.debug(f"Broadcast QUESTION_UNANSWERED to session {sanitize_for_log(session_id)}")


async def broadcast_action_tracked(session_id: str, action_data: dict):
    """
    Broadcast when a new action item is detected.

    Args:
        session_id: The meeting session identifier
        action_data: Action details including id, description, owner, deadline, completeness
    """
    await insights_manager.broadcast_to_session(
        session_id,
        {
            "type": "ACTION_TRACKED",
            "data": action_data,
            "timestamp": datetime.utcnow().isoformat()
        }
    )
    logger.debug(f"Broadcast ACTION_TRACKED to session {sanitize_for_log(session_id)}")


async def broadcast_action_updated(session_id: str, action_id: str, update_data: dict):
    """
    Broadcast when an action item is updated with new details.

    Args:
        session_id: The meeting session identifier
        action_id: The action identifier
        update_data: Updated fields including owner, deadline, completeness
    """
    await insights_manager.broadcast_to_session(
        session_id,
        {
            "type": "ACTION_UPDATED",
            "action_id": action_id,
            "data": update_data,
            "timestamp": datetime.utcnow().isoformat()
        }
    )
    logger.debug(f"Broadcast ACTION_UPDATED to session {sanitize_for_log(session_id)}")


async def broadcast_action_alert(session_id: str, action_id: str, alert_data: dict):
    """
    Broadcast alert for incomplete action at segment boundary.

    Args:
        session_id: The meeting session identifier
        action_id: The action identifier
        alert_data: Alert details including missing fields, completeness score
    """
    await insights_manager.broadcast_to_session(
        session_id,
        {
            "type": "ACTION_ALERT",
            "action_id": action_id,
            "data": alert_data,
            "timestamp": datetime.utcnow().isoformat()
        }
    )
    logger.debug(f"Broadcast ACTION_ALERT to session {sanitize_for_log(session_id)}")


async def broadcast_segment_transition(session_id: str, segment_data: dict):
    """
    Broadcast meeting segment transition event.

    Args:
        session_id: The meeting session identifier
        segment_data: Segment details including boundary type, timestamp
    """
    await insights_manager.broadcast_to_session(
        session_id,
        {
            "type": "SEGMENT_TRANSITION",
            "data": segment_data,
            "timestamp": datetime.utcnow().isoformat()
        }
    )
    logger.debug(f"Broadcast SEGMENT_TRANSITION to session {sanitize_for_log(session_id)}")


async def broadcast_meeting_summary(session_id: str, summary_data: dict):
    """
    Broadcast final meeting summary with all questions and actions.

    Args:
        session_id: The meeting session identifier
        summary_data: Complete summary including all insights
    """
    await insights_manager.broadcast_to_session(
        session_id,
        {
            "type": "MEETING_SUMMARY",
            "data": summary_data,
            "timestamp": datetime.utcnow().isoformat()
        }
    )
    logger.debug(f"Broadcast MEETING_SUMMARY to session {sanitize_for_log(session_id)}")


async def broadcast_transcription_partial(session_id: str, transcript_data: dict):
    """
    Broadcast partial transcription for live display.

    Args:
        session_id: The meeting session identifier
        transcript_data: Partial transcript including text, speaker, timestamp
    """
    await insights_manager.broadcast_to_session(
        session_id,
        {
            "type": "TRANSCRIPTION_PARTIAL",
            "data": transcript_data,
            "timestamp": datetime.utcnow().isoformat()
        }
    )


async def broadcast_transcription_final(session_id: str, transcript_data: dict):
    """
    Broadcast final stable transcription.

    Args:
        session_id: The meeting session identifier
        transcript_data: Final transcript including text, speaker, timestamp, confidence
    """
    await insights_manager.broadcast_to_session(
        session_id,
        {
            "type": "TRANSCRIPTION_FINAL",
            "data": transcript_data,
            "timestamp": datetime.utcnow().isoformat()
        }
    )


async def broadcast_sync_state(session_id: str, state_data: dict):
    """
    Broadcast full state synchronization on reconnect or late join.

    Args:
        session_id: The meeting session identifier
        state_data: Complete state including all questions, actions, transcripts
    """
    await insights_manager.broadcast_to_session(
        session_id,
        {
            "type": "SYNC_STATE",
            "data": state_data,
            "timestamp": datetime.utcnow().isoformat()
        }
    )
    logger.info(f"Broadcast SYNC_STATE to session {sanitize_for_log(session_id)}")


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
        # Prepare transcript data for broadcasting
        transcript_data = {
            "text": result.text,
            "speaker": result.speaker or "Unknown",
            "confidence": result.confidence,
            "audio_start": result.audio_start,
            "audio_end": result.audio_end,
            "created_at": result.created_at,
            "words": result.words
        }

        # Broadcast appropriate event based on transcription type
        if result.is_final:
            await broadcast_transcription_final(session_id, transcript_data)

            # TODO: Task 7.2 - Send final transcription to streaming orchestrator
            # from services.intelligence.streaming_orchestrator import get_orchestrator
            # orchestrator = get_orchestrator(session_id)
            # await orchestrator.process_transcription_chunk(result.text, result.speaker)

        else:
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

    # Broadcast error to clients
    await insights_manager.broadcast_to_session(
        session_id,
        {
            "type": "TRANSCRIPTION_ERROR",
            "error": error,
            "timestamp": datetime.utcnow().isoformat()
        }
    )


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
                            break

                        else:
                            logger.warning(f"Unknown message type from audio client: {message_type}")

                    except json.JSONDecodeError as e:
                        logger.error(f"Invalid JSON from audio client: {e}")

            except Exception as e:
                logger.error(f"Error processing audio message: {e}")
                # Continue processing other messages

    except WebSocketDisconnect:
        logger.info(f"Audio stream disconnected for session {sanitize_for_log(session_id)}")

    except Exception as e:
        logger.error(f"Audio stream error for session {sanitize_for_log(session_id)}: {e}")

    finally:
        # Check if this was the last client for this session
        # If no other audio streams are active, we can close the AssemblyAI connection
        # For now, we'll keep the connection open until explicitly stopped
        # This will be improved in Task 4.3 (State Synchronization)

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

        # Send connection confirmation
        await websocket.send_json({
            "type": "connection",
            "status": "connected",
            "session_id": session_id,
            "user_id": user_id,
            "timestamp": datetime.utcnow().isoformat()
        })

        # TODO: Send SYNC_STATE if user is reconnecting or joining late
        # This will be implemented in Task 4.3 (State Synchronization on Reconnect)

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
                logger.error(f"Error processing message: {e}")
                await websocket.send_json({
                    "type": "error",
                    "error": "Internal server error",
                    "timestamp": datetime.utcnow().isoformat()
                })

    except WebSocketDisconnect:
        logger.info(f"WebSocket disconnected for session {sanitize_for_log(session_id)}")

    except Exception as e:
        logger.error(f"WebSocket error for session {sanitize_for_log(session_id)}: {e}")

    finally:
        # Clean up connection
        if user:
            await insights_manager.disconnect(websocket)
