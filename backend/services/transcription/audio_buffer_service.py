"""
Audio buffer management service for handling streaming audio data.
Manages buffering, chunking, and saving of audio streams.
"""

import asyncio
import logging
import tempfile
import uuid
from pathlib import Path
from typing import Optional, Dict, List
from datetime import datetime
import numpy as np
import soundfile as sf
import base64
from collections import deque

from utils.monitoring import monitor_operation, monitor_sync_operation

logger = logging.getLogger(__name__)


class AudioSession:
    """Represents a single audio recording session."""
    
    def __init__(
        self,
        session_id: str,
        project_id: str,
        meeting_title: Optional[str] = None,
        sample_rate: int = 16000
    ):
        self.session_id = session_id
        self.project_id = project_id
        self.meeting_title = meeting_title or f"Recording_{datetime.now().isoformat()}"
        self.sample_rate = sample_rate
        
        # Audio buffers
        self.audio_buffer = deque()  # For short-term buffering
        self.full_recording = []  # Complete recording
        self.chunk_queue = asyncio.Queue()  # For streaming to transcription
        
        # Session metadata
        self.start_time = datetime.now()
        self.end_time: Optional[datetime] = None
        self.is_active = True
        self.is_paused = False
        self.total_samples = 0
        self.transcription_segments = []
        
        # File paths
        self.temp_file_path: Optional[Path] = None
        self.final_file_path: Optional[Path] = None
        
    def add_audio_chunk(self, audio_data: bytes) -> None:
        """Add audio chunk to buffers."""
        if not self.is_active or self.is_paused:
            return
            
        # Convert to numpy array
        audio_array = np.frombuffer(audio_data, dtype=np.int16)
        
        # Log audio statistics (commented out for production)
        # if len(audio_array) > 0:
        #     max_amp = np.max(np.abs(audio_array))
        #     logger.debug(f"Audio chunk for session {self.session_id}: samples={len(audio_array)}, max_amplitude={max_amp}")
        
        # Add to buffers
        self.audio_buffer.append(audio_array)
        self.full_recording.append(audio_array)
        self.total_samples += len(audio_array)
        
        # Put in queue for transcription (non-blocking)
        try:
            self.chunk_queue.put_nowait(audio_data)
        except asyncio.QueueFull:
            logger.warning(f"Transcription queue full for session {self.session_id}")
            
    def get_buffer_for_transcription(self, duration_seconds: float = 5.0) -> Optional[bytes]:
        """
        Get audio buffer for transcription.
        
        Args:
            duration_seconds: Duration of audio to return
            
        Returns:
            Audio bytes or None if insufficient data
        """
        samples_needed = int(duration_seconds * self.sample_rate)
        
        # Collect enough samples from buffer
        collected = []
        collected_samples = 0
        
        while self.audio_buffer and collected_samples < samples_needed:
            chunk = self.audio_buffer.popleft()
            collected.append(chunk)
            collected_samples += len(chunk)
            
        if collected_samples < samples_needed * 0.8:  # Allow 80% minimum
            # Put back if not enough data
            for chunk in reversed(collected):
                self.audio_buffer.appendleft(chunk)
            return None
            
        # Concatenate and return
        audio_data = np.concatenate(collected)
        
        # Keep last 0.5 seconds for context
        overlap_samples = int(0.5 * self.sample_rate)
        if len(audio_data) > overlap_samples:
            self.audio_buffer.appendleft(audio_data[-overlap_samples:])
            
        return audio_data.tobytes()
        
    def pause(self):
        """Pause recording."""
        self.is_paused = True
        logger.info(f"Session {self.session_id} paused")
        
    def resume(self):
        """Resume recording."""
        self.is_paused = False
        logger.info(f"Session {self.session_id} resumed")
        
    @monitor_operation(
        operation_name="save_recording",
        operation_type="general",
        capture_args=False,
        capture_result=True
    )
    async def save_recording(self, output_dir: Path) -> Optional[Path]:
        """
        Save the complete recording to file.
        
        Args:
            output_dir: Directory to save file
            
        Returns:
            Path to saved file or None if failed
        """
        if not self.full_recording:
            logger.warning(f"No audio data to save for session {self.session_id}")
            return None
            
        try:
            # Ensure output directory exists
            output_dir.mkdir(parents=True, exist_ok=True)
            
            # Generate filename
            timestamp = self.start_time.strftime("%Y%m%d_%H%M%S")
            filename = f"{self.project_id}_{timestamp}_{self.session_id[:8]}.wav"
            file_path = output_dir / filename
            
            # Concatenate all audio
            full_audio = np.concatenate(self.full_recording)
            
            # Save to file
            sf.write(
                str(file_path),
                full_audio,
                self.sample_rate,
                subtype='PCM_16'
            )
            
            self.final_file_path = file_path
            logger.info(f"Recording saved to {file_path}")
            return file_path
            
        except Exception as e:
            logger.error(f"Failed to save recording: {e}")
            return None
            
    def stop(self):
        """Stop the recording session."""
        self.is_active = False
        self.end_time = datetime.now()
        # Signal end of stream to transcription
        try:
            self.chunk_queue.put_nowait(None)
        except:
            pass
        logger.info(f"Session {self.session_id} stopped")
        
    def get_duration(self) -> float:
        """Get recording duration in seconds."""
        return self.total_samples / self.sample_rate
        
    def get_metadata(self) -> Dict:
        """Get session metadata."""
        return {
            "session_id": self.session_id,
            "project_id": self.project_id,
            "meeting_title": self.meeting_title,
            "start_time": self.start_time.isoformat(),
            "end_time": self.end_time.isoformat() if self.end_time else None,
            "duration": self.get_duration(),
            "sample_rate": self.sample_rate,
            "is_active": self.is_active,
            "is_paused": self.is_paused,
            "total_samples": self.total_samples,
            "file_path": str(self.final_file_path) if self.final_file_path else None
        }


class AudioBufferService:
    """Service for managing multiple audio recording sessions."""
    
    def __init__(self, storage_dir: Path = Path("./recordings")):
        self.sessions: Dict[str, AudioSession] = {}
        self.storage_dir = storage_dir
        self.storage_dir.mkdir(parents=True, exist_ok=True)
        
    @monitor_sync_operation(
        operation_name="create_session",
        operation_type="general"
    )
    def create_session(
        self,
        project_id: str,
        meeting_title: Optional[str] = None,
        session_id: Optional[str] = None
    ) -> AudioSession:
        """
        Create a new audio recording session.
        
        Args:
            project_id: Project ID
            meeting_title: Optional meeting title
            session_id: Optional session ID (auto-generated if not provided)
            
        Returns:
            New AudioSession instance
        """
        if session_id is None:
            session_id = str(uuid.uuid4())
            
        session = AudioSession(
            session_id=session_id,
            project_id=project_id,
            meeting_title=meeting_title
        )
        
        self.sessions[session_id] = session
        logger.info(f"Created audio session {session_id} for project {project_id}")
        return session
        
    def get_session(self, session_id: str) -> Optional[AudioSession]:
        """Get session by ID."""
        return self.sessions.get(session_id)
        
    @monitor_sync_operation(
        operation_name="add_audio_chunk",
        operation_type="general"
    )
    def add_audio_chunk(
        self,
        session_id: str,
        audio_data: bytes,
        is_base64: bool = True
    ) -> bool:
        """
        Add audio chunk to session.
        
        Args:
            session_id: Session ID
            audio_data: Audio data (base64 encoded or raw bytes)
            is_base64: Whether audio_data is base64 encoded
            
        Returns:
            True if successful
        """
        session = self.get_session(session_id)
        if not session:
            logger.error(f"Session {session_id} not found")
            return False
            
        try:
            # Decode base64 if needed
            if is_base64:
                audio_bytes = base64.b64decode(audio_data)
            else:
                audio_bytes = audio_data
                
            session.add_audio_chunk(audio_bytes)
            return True
            
        except Exception as e:
            logger.error(f"Failed to add audio chunk: {e}")
            return False
            
    @monitor_operation(
        operation_name="stop_session",
        operation_type="general",
        capture_args=True,
        capture_result=True
    )
    async def stop_session(self, session_id: str) -> Optional[Path]:
        """
        Stop session and save recording.
        
        Args:
            session_id: Session ID
            
        Returns:
            Path to saved file or None
        """
        session = self.get_session(session_id)
        if not session:
            return None
            
        session.stop()
        
        # Save recording
        project_dir = self.storage_dir / session.project_id
        file_path = await session.save_recording(project_dir)
        
        return file_path
        
    def pause_session(self, session_id: str) -> bool:
        """Pause a session."""
        session = self.get_session(session_id)
        if session:
            session.pause()
            return True
        return False
        
    def resume_session(self, session_id: str) -> bool:
        """Resume a session."""
        session = self.get_session(session_id)
        if session:
            session.resume()
            return True
        return False
        
    def cleanup_session(self, session_id: str):
        """Remove session from memory."""
        if session_id in self.sessions:
            del self.sessions[session_id]
            logger.info(f"Cleaned up session {session_id}")
            
    def get_active_sessions(self) -> List[str]:
        """Get list of active session IDs."""
        return [
            sid for sid, session in self.sessions.items()
            if session.is_active
        ]
        
    def get_session_metadata(self, session_id: str) -> Optional[Dict]:
        """Get session metadata."""
        session = self.get_session(session_id)
        if session:
            return session.get_metadata()
        return None


# Singleton instance
_audio_buffer_service: Optional[AudioBufferService] = None


def get_audio_buffer_service() -> AudioBufferService:
    """Get or create audio buffer service singleton."""
    global _audio_buffer_service
    if _audio_buffer_service is None:
        _audio_buffer_service = AudioBufferService()
    return _audio_buffer_service