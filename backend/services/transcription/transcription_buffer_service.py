"""
Transcription Buffer Service

Manages a rolling 60-second window of transcription sentences with in-memory storage.
Provides formatted output for GPT consumption and automatic trimming of old content.

Task 2.1: Implement Transcription Buffer Manager
"""

import json
from typing import Optional, List, Dict, Any
from datetime import datetime, timedelta
from dataclasses import dataclass, field, asdict
from collections import deque
import asyncio

from config import get_settings
from utils.logger import get_logger

logger = get_logger(__name__)
settings = get_settings()


@dataclass
class TranscriptionSentence:
    """
    Represents a single transcription sentence in the buffer.

    Note: Speaker field removed - not supported in Universal-Streaming v3 API.
    """

    sentence_id: str
    text: str
    timestamp: float
    start_time: float
    end_time: float
    confidence: float = 1.0
    metadata: Dict[str, Any] = field(default_factory=dict)

    def to_dict(self) -> Dict[str, Any]:
        """Convert sentence to dictionary."""
        return asdict(self)

    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> "TranscriptionSentence":
        """Create sentence from dictionary."""
        return cls(**data)


class TranscriptionBufferService:
    """
    Manages a rolling window of transcription sentences with in-memory storage.

    Features:
    - Automatic time-based trimming (60-second window)
    - Size-based limiting (max 100 sentences)
    - Formatted output for GPT consumption
    - Fast in-memory operations
    - Per-session buffer isolation
    """

    def __init__(self):
        """Initialize TranscriptionBuffer service."""
        self._buffers: Dict[str, deque] = {}  # session_id -> deque of TranscriptionSentence
        self._lock = asyncio.Lock()
        self.window_seconds = settings.transcription_buffer_window_seconds
        self.max_sentences = settings.transcription_buffer_max_sentences

    def _get_or_create_buffer(self, session_id: str) -> deque:
        """Get or create buffer for session."""
        if session_id not in self._buffers:
            self._buffers[session_id] = deque(maxlen=self.max_sentences)
            logger.debug(f"Created new buffer for session {session_id}")
        return self._buffers[session_id]

    async def close(self):
        """Close and cleanup buffers."""
        async with self._lock:
            self._buffers.clear()
            logger.info("TranscriptionBuffer cleaned up all session buffers")

    async def add_sentence(
        self,
        session_id: str,
        sentence: TranscriptionSentence
    ) -> bool:
        """
        Add a sentence to the buffer and auto-trim old content.

        Args:
            session_id: Unique session identifier
            sentence: TranscriptionSentence object to add

        Returns:
            True if added successfully, False otherwise
        """
        try:
            async with self._lock:
                buffer = self._get_or_create_buffer(session_id)
                buffer.append(sentence)

                # Auto-trim old sentences based on time window
                await self._trim_buffer(session_id)

                logger.info(f"✅ Added sentence to buffer for session {session_id}: {sentence.sentence_id}, text='{sentence.text[:50]}', buffer_size={len(buffer)}")
                return True

        except Exception as e:
            logger.error(f"Failed to add sentence to buffer for session {session_id}: {e}")
            return False

    async def _trim_buffer(self, session_id: str):
        """
        Remove sentences older than window_seconds.

        Args:
            session_id: Session identifier to trim
        """
        if session_id not in self._buffers:
            return

        try:
            buffer = self._buffers[session_id]
            current_time = datetime.now().timestamp()
            cutoff_time = current_time - self.window_seconds

            logger.info(f"_trim_buffer: session={session_id}, buffer_len={len(buffer)}, current_time={current_time}, cutoff_time={cutoff_time}, window={self.window_seconds}s")

            if buffer:
                logger.info(f"First sentence timestamp: {buffer[0].timestamp}, is_old={buffer[0].timestamp < cutoff_time}")

            # Remove sentences older than cutoff time (from left side)
            removed_count = 0
            while buffer and buffer[0].timestamp < cutoff_time:
                removed_sentence = buffer.popleft()
                removed_count += 1
                logger.warning(f"TRIMMED sentence: timestamp={removed_sentence.timestamp}, age={(current_time - removed_sentence.timestamp)}s")

            if removed_count > 0:
                logger.warning(f"Trimmed {removed_count} sentences from buffer for session {session_id}, remaining={len(buffer)}")

        except Exception as e:
            logger.error(f"Failed to trim buffer for session {session_id}: {e}")

    async def get_buffer(
        self,
        session_id: str,
        max_age_seconds: Optional[int] = None
    ) -> List[TranscriptionSentence]:
        """
        Get current buffer contents in chronological order.

        Args:
            session_id: Session identifier
            max_age_seconds: Optional override for window size (e.g., get last 30 seconds)

        Returns:
            List of TranscriptionSentence objects in chronological order
        """
        try:
            async with self._lock:
                if session_id not in self._buffers:
                    logger.debug(f"No buffer exists for session {session_id}")
                    return []

                buffer = self._buffers[session_id]

                # Filter by time window if specified
                if max_age_seconds:
                    current_time = datetime.now().timestamp()
                    cutoff_time = current_time - max_age_seconds
                    sentences = [s for s in buffer if s.timestamp >= cutoff_time]
                    logger.info(f"Retrieved {len(sentences)}/{len(buffer)} sentences for session {session_id} (within {max_age_seconds}s)")
                else:
                    sentences = list(buffer)
                    logger.info(f"Retrieved {len(sentences)} sentences from buffer for session {session_id}")

                return sentences

        except Exception as e:
            logger.error(f"Failed to get buffer for session {session_id}: {e}")
            return []

    async def get_formatted_context(
        self,
        session_id: str,
        include_timestamps: bool = True,
        max_age_seconds: Optional[int] = None
    ) -> str:
        """
        Get formatted buffer content for GPT consumption.

        Note: include_speakers parameter removed - not supported in streaming API.

        Args:
            session_id: Session identifier
            include_timestamps: Include timestamps in output
            max_age_seconds: Optional override for window size

        Returns:
            Formatted string suitable for LLM context
        """
        sentences = await self.get_buffer(session_id, max_age_seconds)

        logger.info(f"get_formatted_context for session {session_id}: found {len(sentences)} sentences")

        if not sentences:
            logger.warning(f"⚠️ No sentences in buffer for session {session_id}")
            return "No recent transcription available."

        lines = []
        for s in sentences:
            parts = []

            if include_timestamps:
                time_str = datetime.fromtimestamp(s.timestamp).strftime("%H:%M:%S")
                parts.append(f"[{time_str}]")

            parts.append(s.text)

            lines.append(" ".join(parts))

        context = "\n".join(lines)
        logger.debug(f"Generated formatted context for session {session_id}: {len(context)} chars")
        return context

    async def get_buffer_stats(self, session_id: str) -> Dict[str, Any]:
        """
        Get buffer statistics for monitoring and debugging.

        Args:
            session_id: Session identifier

        Returns:
            Dictionary with buffer statistics
        """
        try:
            async with self._lock:
                if session_id not in self._buffers:
                    return {
                        "session_id": session_id,
                        "sentence_count": 0,
                        "window_seconds": self.window_seconds,
                        "max_sentences": self.max_sentences
                    }

                buffer = self._buffers[session_id]
                count = len(buffer)

                if count > 0:
                    oldest_timestamp = buffer[0].timestamp
                    newest_timestamp = buffer[-1].timestamp
                    time_span_seconds = newest_timestamp - oldest_timestamp
                else:
                    oldest_timestamp = None
                    newest_timestamp = None
                    time_span_seconds = 0

                return {
                    "session_id": session_id,
                    "sentence_count": count,
                    "oldest_timestamp": oldest_timestamp,
                    "newest_timestamp": newest_timestamp,
                    "time_span_seconds": time_span_seconds,
                    "window_seconds": self.window_seconds,
                    "max_sentences": self.max_sentences
                }

        except Exception as e:
            logger.error(f"Failed to get buffer stats for session {session_id}: {e}")
            return {
                "session_id": session_id,
                "error": str(e)
            }

    async def clear_buffer(self, session_id: str) -> bool:
        """
        Clear the entire buffer for a session.

        Args:
            session_id: Session identifier

        Returns:
            True if cleared successfully, False otherwise
        """
        try:
            async with self._lock:
                if session_id in self._buffers:
                    del self._buffers[session_id]
                    logger.info(f"Cleared buffer for session {session_id}")
                return True
        except Exception as e:
            logger.error(f"Failed to clear buffer for session {session_id}: {e}")
            return False


# Singleton instance at module level
_transcription_buffer_instance: Optional[TranscriptionBufferService] = None


def get_transcription_buffer() -> TranscriptionBufferService:
    """Get the singleton TranscriptionBuffer instance."""
    global _transcription_buffer_instance

    if _transcription_buffer_instance is None:
        _transcription_buffer_instance = TranscriptionBufferService()

    return _transcription_buffer_instance
