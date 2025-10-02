"""
WebSocket router for real-time audio streaming and transcription.
Handles audio recording sessions with live transcription using Whisper.
"""

import asyncio
import json
import logging
from typing import Dict, Optional
from datetime import datetime
from pathlib import Path

from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Query, Depends
from fastapi.responses import JSONResponse
from sqlalchemy.ext.asyncio import AsyncSession

from db.database import get_db
from services.transcription.whisper_service import get_whisper_service
from services.transcription.audio_buffer_service import get_audio_buffer_service
from models.content import Content
from services.core.content_service import ContentService

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/ws", tags=["websocket"])


class ConnectionManager:
    """Manages WebSocket connections for audio streaming."""
    
    def __init__(self):
        self.active_connections: Dict[str, WebSocket] = {}
        
    async def connect(self, session_id: str, websocket: WebSocket):
        """Accept and store connection."""
        await websocket.accept()
        self.active_connections[session_id] = websocket
        logger.info(f"WebSocket connected: {session_id}")
        
    def disconnect(self, session_id: str):
        """Remove connection."""
        if session_id in self.active_connections:
            del self.active_connections[session_id]
            logger.info(f"WebSocket disconnected: {session_id}")
            
    async def send_json(self, session_id: str, data: dict):
        """Send JSON data to specific connection."""
        if session_id in self.active_connections:
            try:
                await self.active_connections[session_id].send_json(data)
            except Exception as e:
                logger.error(f"Error sending to {session_id}: {e}")
                
    async def broadcast_json(self, data: dict):
        """Broadcast JSON data to all connections."""
        for session_id, connection in self.active_connections.items():
            try:
                await connection.send_json(data)
            except Exception as e:
                logger.error(f"Error broadcasting to {session_id}: {e}")


# Global connection manager
manager = ConnectionManager()


async def process_transcription_task(
    session_id: str,
    audio_session,
    whisper_service,
    db: AsyncSession
):
    """
    Background task to process audio and generate transcriptions.
    
    Args:
        session_id: Session ID
        audio_session: AudioSession instance
        whisper_service: Whisper transcription service
        db: Database session
    """
    try:
        # Process audio stream with optimized parameters
        async for transcription in whisper_service.transcribe_stream(
            audio_session.chunk_queue,
            language="en",  # Specify language to skip detection overhead
            chunk_duration=3.0  # Smaller chunks for lower latency (3s instead of 5s)
        ):
            if not transcription:
                continue
                
            # Send transcription to client
            for segment in transcription.get("segments", []):
                await manager.send_json(session_id, {
                    "type": "transcription",
                    "text": segment["text"],
                    "start_time": segment["start"],
                    "end_time": segment["end"],
                    "is_final": False
                })
                
                # Store segment in session
                audio_session.transcription_segments.append(segment)
                
        logger.info(f"Transcription task completed for session {session_id}")
        
    except Exception as e:
        logger.error(f"Transcription task error for {session_id}: {e}")
        await manager.send_json(session_id, {
            "type": "error",
            "message": f"Transcription error: {str(e)}"
        })


@router.websocket("/transcribe")
async def websocket_transcribe(
    websocket: WebSocket,
    session_id: str = Query(...),
    project_id: str = Query(...),
    meeting_title: Optional[str] = Query(None)
):
    """
    WebSocket endpoint for real-time audio transcription.
    
    Query Parameters:
        session_id: Unique session identifier
        project_id: Project ID for the recording
        meeting_title: Optional meeting title
    """
    # Get services
    audio_service = get_audio_buffer_service()
    whisper_service = get_whisper_service()
    
    # Connect WebSocket
    await manager.connect(session_id, websocket)
    
    # Create audio session
    audio_session = None
    transcription_task = None
    
    try:
        # Initialize session
        audio_session = audio_service.create_session(
            project_id=project_id,
            meeting_title=meeting_title,
            session_id=session_id
        )
        
        # Send session info
        await websocket.send_json({
            "type": "session_info",
            "info": {
                "session_id": session_id,
                "project_id": project_id,
                "meeting_title": meeting_title,
                "start_time": audio_session.start_time.isoformat()
            }
        })
        
        # Start transcription task
        # Note: In production, you'd want to pass a proper DB session here
        transcription_task = asyncio.create_task(
            process_transcription_task(
                session_id,
                audio_session,
                whisper_service,
                None  # DB session would go here
            )
        )
        
        # Process incoming messages
        while True:
            try:
                # Receive message
                message = await websocket.receive_json()
                msg_type = message.get("type")
                
                if msg_type == "audio_chunk":
                    # Process audio chunk
                    audio_data = message.get("audio")
                    if audio_data:
                        # logger.debug(f"Received audio chunk: {len(audio_data)} characters (base64)")
                        success = audio_service.add_audio_chunk(
                            session_id,
                            audio_data,
                            is_base64=True
                        )
                        
                        if not success:
                            await websocket.send_json({
                                "type": "error",
                                "message": "Failed to process audio chunk"
                            })
                    else:
                        logger.warning(f"Received audio_chunk message without audio data")
                            
                elif msg_type == "control":
                    # Handle control messages
                    action = message.get("action")
                    
                    if action == "pause":
                        audio_service.pause_session(session_id)
                        await websocket.send_json({
                            "type": "status",
                            "status": "paused"
                        })
                        
                    elif action == "resume":
                        audio_service.resume_session(session_id)
                        await websocket.send_json({
                            "type": "status",
                            "status": "recording"
                        })
                        
                    elif action == "stop":
                        # Stop and save recording
                        file_path = await audio_service.stop_session(session_id)
                        
                        # Send final transcription
                        if audio_session.transcription_segments:
                            full_text = " ".join([
                                seg["text"] for seg in audio_session.transcription_segments
                            ])
                            
                            await websocket.send_json({
                                "type": "transcription",
                                "text": full_text,
                                "is_final": True,
                                "segments": audio_session.transcription_segments
                            })
                            
                        # Send completion message
                        await websocket.send_json({
                            "type": "recording_complete",
                            "file_path": str(file_path) if file_path else None,
                            "metadata": audio_session.get_metadata()
                        })
                        
                        break
                        
                elif msg_type == "ping":
                    # Respond to ping
                    await websocket.send_json({"type": "pong"})
                    
                elif msg_type == "disconnect":
                    # Client requesting disconnect
                    break
                    
                elif msg_type == "handshake":
                    # Client handshake - already handled above
                    logger.info(f"Handshake from session {session_id}")
                    
                else:
                    logger.warning(f"Unknown message type: {msg_type}")
                    
            except WebSocketDisconnect:
                logger.info(f"Client disconnected: {session_id}")
                break
            except json.JSONDecodeError as e:
                logger.error(f"Invalid JSON from {session_id}: {e}")
                await websocket.send_json({
                    "type": "error",
                    "message": "Invalid JSON format"
                })
            except Exception as e:
                logger.error(f"Error processing message from {session_id}: {e}")
                await websocket.send_json({
                    "type": "error",
                    "message": str(e)
                })
                
    except Exception as e:
        logger.error(f"WebSocket error for {session_id}: {e}")
        try:
            await websocket.send_json({
                "type": "error",
                "message": f"Server error: {str(e)}"
            })
        except:
            pass
            
    finally:
        # Cleanup
        manager.disconnect(session_id)
        
        # Cancel transcription task
        if transcription_task and not transcription_task.done():
            transcription_task.cancel()
            try:
                await transcription_task
            except asyncio.CancelledError:
                pass
                
        # Stop session if still active
        if audio_session and audio_session.is_active:
            await audio_service.stop_session(session_id)
            
        # Cleanup session
        audio_service.cleanup_session(session_id)
        
        logger.info(f"WebSocket session {session_id} cleaned up")


@router.get("/sessions/active")
async def get_active_sessions():
    """Get list of active recording sessions."""
    audio_service = get_audio_buffer_service()
    active_sessions = audio_service.get_active_sessions()
    
    sessions_info = []
    for session_id in active_sessions:
        metadata = audio_service.get_session_metadata(session_id)
        if metadata:
            sessions_info.append(metadata)
            
    return JSONResponse(content={
        "active_sessions": sessions_info,
        "count": len(sessions_info)
    })


@router.get("/sessions/{session_id}")
async def get_session_info(session_id: str):
    """Get information about a specific session."""
    audio_service = get_audio_buffer_service()
    metadata = audio_service.get_session_metadata(session_id)
    
    if not metadata:
        return JSONResponse(
            status_code=404,
            content={"error": "Session not found"}
        )
        
    return JSONResponse(content=metadata)