"""
Transcription Buffer Service

Manages a rolling 60-second window of transcription sentences with Redis storage.
Provides formatted output for GPT consumption and automatic trimming of old content.

Task 2.1: Implement Transcription Buffer Manager
"""

import json
from typing import Optional, List, Dict, Any
from datetime import datetime, timedelta
from dataclasses import dataclass, field, asdict

import redis.asyncio as redis
from redis.asyncio import Redis

from config import get_settings
from utils.logger import get_logger

logger = get_logger(__name__)
settings = get_settings()


@dataclass
class TranscriptionSentence:
    """Represents a single transcription sentence in the buffer."""

    sentence_id: str
    text: str
    speaker: str
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
    Manages a rolling window of transcription sentences with Redis storage.

    Features:
    - Automatic time-based trimming (60-second window)
    - Size-based limiting (max 100 sentences)
    - Formatted output for GPT consumption
    - Distributed state management via Redis
    - Graceful degradation if Redis is unavailable
    """

    def __init__(self):
        """Initialize TranscriptionBuffer service."""
        self._client: Optional[Redis] = None
        self._is_available = False
        self.window_seconds = settings.transcription_buffer_window_seconds
        self.max_sentences = settings.transcription_buffer_max_sentences
        self.ttl_hours = settings.transcription_buffer_ttl_hours

    async def _get_client(self) -> Optional[Redis]:
        """Get or create Redis client with lazy initialization."""
        if self._client:
            return self._client

        try:
            # Build Redis URL with authentication if password is provided
            if settings.redis_password:
                redis_url = f"redis://:{settings.redis_password}@{settings.redis_host}:{settings.redis_port}/{settings.redis_db}"
            else:
                redis_url = f"redis://{settings.redis_host}:{settings.redis_port}/{settings.redis_db}"

            self._client = redis.from_url(
                redis_url,
                encoding="utf-8",
                decode_responses=True,
                socket_connect_timeout=2,
                socket_timeout=2
            )

            await self._client.ping()
            self._is_available = True
            logger.info("TranscriptionBuffer connected to Redis")
            return self._client

        except Exception as e:
            logger.error(f"Redis connection failed: {e}")
            self._is_available = False
            return None

    async def close(self):
        """Close Redis connection."""
        if self._client:
            await self._client.aclose()
            self._client = None
            self._is_available = False
            logger.info("TranscriptionBuffer Redis connection closed")

    def _get_buffer_key(self, session_id: str) -> str:
        """Generate Redis key for session buffer."""
        return f"transcription_buffer:{session_id}"

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
        client = await self._get_client()
        if not client:
            logger.warning(f"Redis not available, sentence not buffered for session {session_id}")
            return False

        try:
            key = self._get_buffer_key(session_id)

            # Use Redis Sorted Set (ZADD) with timestamp as score for automatic ordering
            sentence_json = json.dumps(sentence.to_dict())
            await client.zadd(
                key,
                {sentence_json: sentence.timestamp}
            )

            # Set expiration on the key (auto-cleanup if session ends)
            await client.expire(key, timedelta(hours=self.ttl_hours))

            # Auto-trim old sentences
            await self._trim_buffer(session_id)

            logger.debug(f"Added sentence to buffer for session {session_id}: {sentence.sentence_id}")
            return True

        except Exception as e:
            logger.error(f"Failed to add sentence to buffer for session {session_id}: {e}")
            return False

    async def _trim_buffer(self, session_id: str):
        """
        Remove sentences older than window_seconds and enforce max_sentences limit.

        Args:
            session_id: Session identifier to trim
        """
        client = await self._get_client()
        if not client:
            return

        try:
            key = self._get_buffer_key(session_id)
            current_time = datetime.now().timestamp()
            cutoff_time = current_time - self.window_seconds

            # Remove entries with score (timestamp) < cutoff_time
            removed_count = await client.zremrangebyscore(key, '-inf', cutoff_time)

            if removed_count > 0:
                logger.debug(f"Trimmed {removed_count} old sentences from buffer for session {session_id}")

            # Enforce max_sentences limit (keep only latest N sentences)
            count = await client.zcard(key)
            if count > self.max_sentences:
                # Remove oldest entries beyond max_sentences
                to_remove = count - self.max_sentences
                await client.zremrangebyrank(key, 0, to_remove - 1)
                logger.debug(f"Removed {to_remove} excess sentences to enforce max limit for session {session_id}")

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
        client = await self._get_client()
        if not client:
            logger.warning(f"Redis not available, returning empty buffer for session {session_id}")
            return []

        try:
            key = self._get_buffer_key(session_id)

            # Get sentences within time window
            if max_age_seconds:
                current_time = datetime.now().timestamp()
                cutoff_time = current_time - max_age_seconds
                raw_sentences = await client.zrangebyscore(
                    key, cutoff_time, '+inf'
                )
            else:
                # Get all sentences (already time-trimmed)
                raw_sentences = await client.zrange(key, 0, -1)

            # Deserialize sentences
            sentences = []
            for raw in raw_sentences:
                try:
                    data = json.loads(raw)
                    sentences.append(TranscriptionSentence.from_dict(data))
                except json.JSONDecodeError as e:
                    logger.warning(f"Malformed sentence JSON in buffer: {e}")
                    continue

            logger.debug(f"Retrieved {len(sentences)} sentences from buffer for session {session_id}")
            return sentences

        except Exception as e:
            logger.error(f"Failed to get buffer for session {session_id}: {e}")
            return []

    async def get_formatted_context(
        self,
        session_id: str,
        include_timestamps: bool = True,
        include_speakers: bool = True,
        max_age_seconds: Optional[int] = None
    ) -> str:
        """
        Get formatted buffer content for GPT consumption.

        Args:
            session_id: Session identifier
            include_timestamps: Include timestamps in output
            include_speakers: Include speaker names
            max_age_seconds: Optional override for window size

        Returns:
            Formatted string suitable for LLM context
        """
        sentences = await self.get_buffer(session_id, max_age_seconds)

        if not sentences:
            return "No recent transcription available."

        lines = []
        for s in sentences:
            parts = []

            if include_timestamps:
                time_str = datetime.fromtimestamp(s.timestamp).strftime("%H:%M:%S")
                parts.append(f"[{time_str}]")

            if include_speakers:
                parts.append(f"{s.speaker}:")

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
        client = await self._get_client()
        if not client:
            return {
                "session_id": session_id,
                "sentence_count": 0,
                "redis_available": False,
                "error": "Redis not available"
            }

        try:
            key = self._get_buffer_key(session_id)

            # Get sentence count
            count = await client.zcard(key)

            # Get time range
            if count > 0:
                oldest_raw = await client.zrange(key, 0, 0, withscores=True)
                newest_raw = await client.zrange(key, -1, -1, withscores=True)

                oldest_timestamp = oldest_raw[0][1] if oldest_raw else None
                newest_timestamp = newest_raw[0][1] if newest_raw else None

                time_span_seconds = newest_timestamp - oldest_timestamp if (oldest_timestamp and newest_timestamp) else 0
            else:
                oldest_timestamp = None
                newest_timestamp = None
                time_span_seconds = 0

            # Get TTL
            ttl = await client.ttl(key)

            return {
                "session_id": session_id,
                "sentence_count": count,
                "oldest_timestamp": oldest_timestamp,
                "newest_timestamp": newest_timestamp,
                "time_span_seconds": time_span_seconds,
                "ttl_seconds": ttl,
                "redis_available": True,
                "window_seconds": self.window_seconds,
                "max_sentences": self.max_sentences
            }

        except Exception as e:
            logger.error(f"Failed to get buffer stats for session {session_id}: {e}")
            return {
                "session_id": session_id,
                "redis_available": True,
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
        client = await self._get_client()
        if not client:
            logger.warning(f"Redis not available, cannot clear buffer for session {session_id}")
            return False

        try:
            key = self._get_buffer_key(session_id)
            await client.delete(key)
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
