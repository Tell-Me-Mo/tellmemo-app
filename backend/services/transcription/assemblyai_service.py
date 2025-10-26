"""
AssemblyAI Real-Time Transcription Service.

This module provides real-time speech-to-text transcription with speaker diarization
using AssemblyAI's streaming API. Implements single connection per session architecture
for cost efficiency and consistency.
"""

import asyncio
import json
import websockets
from datetime import datetime
from typing import Optional, Callable, Dict, Any, Set
from dataclasses import dataclass, field
from enum import Enum

from utils.logger import get_logger, sanitize_for_log
from config import get_settings

logger = get_logger(__name__)
settings = get_settings()


class ConnectionState(Enum):
    """AssemblyAI connection lifecycle states."""
    DISCONNECTED = "disconnected"
    CONNECTING = "connecting"
    CONNECTED = "connected"
    ERROR = "error"
    FAILED = "failed"


@dataclass
class TranscriptionMetrics:
    """Metrics for transcription session tracking."""
    session_id: str
    audio_bytes_sent: int = 0
    audio_duration_seconds: float = 0.0
    transcription_count: int = 0
    partial_count: int = 0
    final_count: int = 0
    error_count: int = 0
    connection_attempts: int = 0
    started_at: Optional[datetime] = None
    ended_at: Optional[datetime] = None

    @property
    def cost_estimate(self) -> float:
        """Calculate estimated cost based on audio duration."""
        # AssemblyAI pricing: $0.00025/second = $0.015/minute = $0.90/hour
        return self.audio_duration_seconds * 0.00025

    @property
    def session_duration_seconds(self) -> float:
        """Calculate total session duration."""
        if not self.started_at:
            return 0.0
        end_time = self.ended_at or datetime.utcnow()
        return (end_time - self.started_at).total_seconds()


@dataclass
class TranscriptionResult:
    """Parsed transcription result from AssemblyAI."""
    text: str
    is_final: bool
    speaker: Optional[str]
    confidence: float
    audio_start: int  # milliseconds
    audio_end: int  # milliseconds
    created_at: str
    words: list = field(default_factory=list)


class AssemblyAIConnectionManager:
    """
    Manages single AssemblyAI WebSocket connection per session.

    Implements cost-efficient architecture where multiple clients share
    a single AssemblyAI connection per meeting session.
    """

    def __init__(self):
        # session_id -> AssemblyAIConnection
        self.active_connections: Dict[str, 'AssemblyAIConnection'] = {}

        # Lock for thread-safe operations
        self.lock = asyncio.Lock()

        # Get AssemblyAI API key from environment
        self.api_key = settings.assemblyai_api_key if hasattr(settings, 'assemblyai_api_key') else None

        if not self.api_key:
            logger.warning("AssemblyAI API key not configured - transcription will fail")

    async def get_or_create_connection(
        self,
        session_id: str,
        on_transcription: Optional[Callable] = None,
        on_error: Optional[Callable] = None
    ) -> Optional['AssemblyAIConnection']:
        """
        Get existing connection for session or create new one.

        Args:
            session_id: The meeting session identifier
            on_transcription: Callback for transcription results
            on_error: Callback for errors

        Returns:
            AssemblyAIConnection instance or None if creation failed
        """
        async with self.lock:
            # Return existing connection if active
            if session_id in self.active_connections:
                connection = self.active_connections[session_id]
                if connection.state in [ConnectionState.CONNECTED, ConnectionState.CONNECTING]:
                    logger.info(f"Reusing existing AssemblyAI connection for session {sanitize_for_log(session_id)}")
                    return connection
                else:
                    # Clean up dead connection
                    await self.close_connection(session_id)

            # Create new connection
            if not self.api_key:
                logger.error("Cannot create AssemblyAI connection: API key not configured")
                return None

            connection = AssemblyAIConnection(
                session_id=session_id,
                api_key=self.api_key,
                on_transcription=on_transcription,
                on_error=on_error
            )

            # Connect to AssemblyAI
            success = await connection.connect()
            if success:
                self.active_connections[session_id] = connection
                logger.info(f"Created new AssemblyAI connection for session {sanitize_for_log(session_id)}")
                return connection
            else:
                logger.error(f"Failed to create AssemblyAI connection for session {sanitize_for_log(session_id)}")
                return None

    async def close_connection(self, session_id: str):
        """
        Close and remove connection for a session.

        Args:
            session_id: The meeting session identifier
        """
        async with self.lock:
            if session_id in self.active_connections:
                connection = self.active_connections[session_id]
                await connection.close()
                del self.active_connections[session_id]
                logger.info(f"Closed AssemblyAI connection for session {sanitize_for_log(session_id)}")

    def is_session_active(self, session_id: str) -> bool:
        """Check if session has an active AssemblyAI connection."""
        return (
            session_id in self.active_connections and
            self.active_connections[session_id].state == ConnectionState.CONNECTED
        )

    async def send_audio(self, session_id: str, audio_data: bytes) -> bool:
        """
        Send audio data to AssemblyAI for a session.

        Args:
            session_id: The meeting session identifier
            audio_data: PCM audio bytes

        Returns:
            True if sent successfully, False otherwise
        """
        connection = self.active_connections.get(session_id)
        if not connection:
            logger.warning(f"No AssemblyAI connection for session {sanitize_for_log(session_id)}")
            return False

        return await connection.send_audio(audio_data)

    def get_metrics(self, session_id: str) -> Optional[TranscriptionMetrics]:
        """Get transcription metrics for a session."""
        connection = self.active_connections.get(session_id)
        return connection.metrics if connection else None


class AssemblyAIConnection:
    """
    Single WebSocket connection to AssemblyAI Real-Time API.

    Handles:
    - Connection lifecycle management
    - Audio streaming
    - Transcription result parsing
    - Automatic reconnection
    - Metrics tracking
    """

    ASSEMBLYAI_URL = "wss://api.assemblyai.com/v2/realtime/ws"

    # Audio format: PCM 16kHz, 16-bit, mono (as per Flutter audio streaming spec)
    SAMPLE_RATE = 16000
    ENCODING = "pcm_s16le"

    def __init__(
        self,
        session_id: str,
        api_key: str,
        on_transcription: Optional[Callable] = None,
        on_error: Optional[Callable] = None
    ):
        self.session_id = session_id
        self.api_key = api_key
        self.on_transcription = on_transcription
        self.on_error = on_error

        # Connection state
        self.websocket: Optional[websockets.WebSocketClientProtocol] = None
        self.state = ConnectionState.DISCONNECTED

        # Metrics tracking
        self.metrics = TranscriptionMetrics(session_id=session_id)

        # Background tasks
        self.listener_task: Optional[asyncio.Task] = None
        self.heartbeat_task: Optional[asyncio.Task] = None

        # Reconnection settings
        self.max_reconnect_attempts = 3
        self.reconnect_delay_seconds = [1, 2, 5]  # Exponential backoff

    async def connect(self) -> bool:
        """
        Connect to AssemblyAI Real-Time API.

        Returns:
            True if connected successfully, False otherwise
        """
        if self.state == ConnectionState.CONNECTED:
            logger.warning(f"Already connected to AssemblyAI for session {sanitize_for_log(self.session_id)}")
            return True

        self.state = ConnectionState.CONNECTING
        self.metrics.connection_attempts += 1

        try:
            # Build WebSocket URL with authentication and parameters
            url = f"{self.ASSEMBLYAI_URL}?sample_rate={self.SAMPLE_RATE}&encoding={self.ENCODING}"

            # Add token parameter for authentication
            url += f"&token={self.api_key}"

            # Enable speaker diarization
            url += "&enable_speaker_labels=true"

            logger.info(f"Connecting to AssemblyAI for session {sanitize_for_log(self.session_id)}...")

            # Connect with timeout
            self.websocket = await asyncio.wait_for(
                websockets.connect(
                    url,
                    additional_headers={
                        "Authorization": self.api_key
                    },
                    max_size=10 * 1024 * 1024,  # 10MB max message size
                    ping_interval=20,
                    ping_timeout=10
                ),
                timeout=10.0
            )

            self.state = ConnectionState.CONNECTED
            self.metrics.started_at = datetime.utcnow()

            logger.info(f"✓ Connected to AssemblyAI for session {sanitize_for_log(self.session_id)}")

            # Start listener task for receiving transcriptions
            self.listener_task = asyncio.create_task(self._listen_for_transcriptions())

            return True

        except asyncio.TimeoutError:
            logger.error(f"AssemblyAI connection timeout for session {sanitize_for_log(self.session_id)}")
            self.state = ConnectionState.ERROR
            return False
        except Exception as e:
            logger.error(f"AssemblyAI connection error for session {sanitize_for_log(self.session_id)}: {e}")
            self.state = ConnectionState.ERROR
            return False

    async def send_audio(self, audio_data: bytes) -> bool:
        """
        Send audio data to AssemblyAI.

        Args:
            audio_data: PCM audio bytes (16kHz, 16-bit, mono)

        Returns:
            True if sent successfully, False otherwise
        """
        if self.state != ConnectionState.CONNECTED or not self.websocket:
            logger.warning(f"Cannot send audio: not connected for session {sanitize_for_log(self.session_id)}")
            return False

        try:
            # Send audio as binary message
            await self.websocket.send(audio_data)

            # Update metrics
            self.metrics.audio_bytes_sent += len(audio_data)

            # Calculate duration: bytes / (sample_rate * bytes_per_sample * channels)
            # For PCM 16kHz, 16-bit, mono: bytes / (16000 * 2 * 1) = bytes / 32000
            duration_seconds = len(audio_data) / 32000
            self.metrics.audio_duration_seconds += duration_seconds

            return True

        except websockets.exceptions.ConnectionClosed:
            logger.warning(f"AssemblyAI connection closed while sending audio for session {sanitize_for_log(self.session_id)}")
            self.state = ConnectionState.ERROR
            await self._attempt_reconnect()
            return False
        except Exception as e:
            logger.error(f"Error sending audio to AssemblyAI for session {sanitize_for_log(self.session_id)}: {e}")
            self.metrics.error_count += 1
            return False

    async def _listen_for_transcriptions(self):
        """
        Background task to listen for transcription results from AssemblyAI.
        """
        logger.info(f"Started AssemblyAI listener for session {sanitize_for_log(self.session_id)}")

        try:
            while self.state == ConnectionState.CONNECTED and self.websocket:
                try:
                    # Receive message from AssemblyAI
                    message = await asyncio.wait_for(
                        self.websocket.recv(),
                        timeout=30.0  # 30-second timeout for receiving
                    )

                    # Parse JSON message
                    data = json.loads(message)

                    # Extract message type
                    message_type = data.get("message_type")

                    if message_type == "PartialTranscript":
                        # Partial transcription (unstable, real-time)
                        result = self._parse_transcription_result(data, is_final=False)
                        self.metrics.partial_count += 1
                        self.metrics.transcription_count += 1

                        if self.on_transcription:
                            await self.on_transcription(self.session_id, result)

                    elif message_type == "FinalTranscript":
                        # Final transcription (stable, after ~2s delay)
                        result = self._parse_transcription_result(data, is_final=True)
                        self.metrics.final_count += 1
                        self.metrics.transcription_count += 1

                        if self.on_transcription:
                            await self.on_transcription(self.session_id, result)

                    elif message_type == "SessionBegins":
                        logger.info(f"AssemblyAI session began for {sanitize_for_log(self.session_id)}")

                    elif message_type == "SessionTerminated":
                        logger.info(f"AssemblyAI session terminated for {sanitize_for_log(self.session_id)}")
                        break

                    else:
                        logger.debug(f"Unknown AssemblyAI message type: {message_type}")

                except asyncio.TimeoutError:
                    # No message received in 30 seconds - connection might be idle
                    logger.debug(f"No transcription received in 30s for session {sanitize_for_log(self.session_id)} (idle)")
                    continue

                except json.JSONDecodeError as e:
                    logger.error(f"Failed to parse AssemblyAI response: {e}")
                    self.metrics.error_count += 1
                    continue

                except websockets.exceptions.ConnectionClosed:
                    logger.warning(f"AssemblyAI connection closed for session {sanitize_for_log(self.session_id)}")
                    self.state = ConnectionState.ERROR
                    await self._attempt_reconnect()
                    break

        except Exception as e:
            logger.error(f"Error in AssemblyAI listener for session {sanitize_for_log(self.session_id)}: {e}")
            self.state = ConnectionState.ERROR
            if self.on_error:
                await self.on_error(self.session_id, str(e))

        finally:
            logger.info(f"AssemblyAI listener stopped for session {sanitize_for_log(self.session_id)}")

    def _parse_transcription_result(self, data: Dict[str, Any], is_final: bool) -> TranscriptionResult:
        """
        Parse AssemblyAI transcription response into TranscriptionResult.

        Args:
            data: Raw AssemblyAI JSON response
            is_final: Whether this is a final or partial transcription

        Returns:
            Parsed TranscriptionResult
        """
        return TranscriptionResult(
            text=data.get("text", ""),
            is_final=is_final,
            speaker=self._extract_speaker(data),
            confidence=data.get("confidence", 0.0),
            audio_start=data.get("audio_start", 0),
            audio_end=data.get("audio_end", 0),
            created_at=data.get("created", datetime.utcnow().isoformat()),
            words=data.get("words", [])
        )

    def _extract_speaker(self, data: Dict[str, Any]) -> Optional[str]:
        """
        Extract speaker label from AssemblyAI response.

        Args:
            data: AssemblyAI JSON response

        Returns:
            Speaker label (e.g., "Speaker A") or None
        """
        # Check for speaker_labels field (array of speakers)
        speaker_labels = data.get("speaker_labels")
        if speaker_labels and len(speaker_labels) > 0:
            return speaker_labels[0]

        # Check for words array with speaker information
        words = data.get("words", [])
        if words and len(words) > 0:
            first_word = words[0]
            speaker = first_word.get("speaker")
            if speaker:
                return f"Speaker {speaker}"

        return None

    async def _attempt_reconnect(self):
        """
        Attempt to reconnect to AssemblyAI with exponential backoff.
        """
        if self.metrics.connection_attempts >= self.max_reconnect_attempts:
            logger.error(f"Max reconnection attempts reached for session {sanitize_for_log(self.session_id)}")
            self.state = ConnectionState.FAILED
            if self.on_error:
                await self.on_error(self.session_id, "Max reconnection attempts reached")
            return

        attempt = self.metrics.connection_attempts
        delay = self.reconnect_delay_seconds[min(attempt, len(self.reconnect_delay_seconds) - 1)]

        logger.info(
            f"Attempting to reconnect to AssemblyAI for session {sanitize_for_log(self.session_id)} "
            f"in {delay}s (attempt {attempt + 1}/{self.max_reconnect_attempts})"
        )

        await asyncio.sleep(delay)
        await self.connect()

    async def close(self):
        """
        Close the AssemblyAI connection and clean up resources.
        """
        logger.info(f"Closing AssemblyAI connection for session {sanitize_for_log(self.session_id)}")

        # Cancel background tasks
        if self.listener_task and not self.listener_task.done():
            self.listener_task.cancel()
            try:
                await self.listener_task
            except asyncio.CancelledError:
                pass

        if self.heartbeat_task and not self.heartbeat_task.done():
            self.heartbeat_task.cancel()
            try:
                await self.heartbeat_task
            except asyncio.CancelledError:
                pass

        # Close WebSocket
        if self.websocket:
            try:
                await self.websocket.close()
            except Exception as e:
                logger.error(f"Error closing AssemblyAI WebSocket: {e}")

        # Update state and metrics
        self.state = ConnectionState.DISCONNECTED
        self.metrics.ended_at = datetime.utcnow()

        # Log final metrics
        logger.info(
            f"AssemblyAI session metrics for {sanitize_for_log(self.session_id)}: "
            f"duration={self.metrics.session_duration_seconds:.1f}s, "
            f"audio={self.metrics.audio_duration_seconds:.1f}s, "
            f"transcriptions={self.metrics.transcription_count} "
            f"(partial={self.metrics.partial_count}, final={self.metrics.final_count}), "
            f"cost=${self.metrics.cost_estimate:.4f}"
        )


# Global connection manager instance
assemblyai_manager = AssemblyAIConnectionManager()
