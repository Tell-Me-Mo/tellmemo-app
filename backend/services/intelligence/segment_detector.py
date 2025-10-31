"""
Segment Detector Service

Detects meeting segment boundaries and triggers action completeness alerts.

Boundaries detected via:
- Time-based intervals (every 10-15 minutes)
- Long pauses (>10 seconds of silence)
- Topic transition phrases ("moving on", "next topic", "let's discuss")
"""

import asyncio
import re
from datetime import datetime, timedelta
from typing import Dict, Any, Optional, List, Callable
from sqlalchemy.ext.asyncio import AsyncSession

from utils.logger import get_logger
from services.transcription.transcription_buffer_service import (
    get_transcription_buffer,
    TranscriptionSentence
)

logger = get_logger(__name__)


class SegmentDetector:
    """Detects meeting segment boundaries for action item review."""

    # Transition phrases that indicate topic changes
    TRANSITION_PHRASES = [
        r'\b(moving on|next topic|let\'s discuss|let\'s move|let\'s talk about)\b',
        r'\b(switching gears|change of subject|new topic|different topic)\b',
        r'\b(now let\'s|okay so|alright so|next up|next item)\b',
        r'\b(before we end|to wrap up|in summary|to conclude)\b',
        r'\b(any questions|anything else|that\'s all|that covers)\b'
    ]

    def __init__(self):
        """Initialize segment detector."""
        self.buffer_service = get_transcription_buffer()
        self._ws_broadcast_callback: Optional[Callable] = None

        # Configuration
        self.time_based_interval_minutes = 10  # Check every 10 minutes
        self.pause_threshold_seconds = 10  # Silence > 10s = boundary

        # State tracking per session
        self.last_segment_time: Dict[str, datetime] = {}  # session_id -> last boundary time
        self.last_transcript_time: Dict[str, datetime] = {}  # session_id -> last sentence time
        self.session_start_time: Dict[str, datetime] = {}  # session_id -> meeting start time

        # Compile transition phrase patterns
        self.transition_patterns = [re.compile(pattern, re.IGNORECASE)
                                   for pattern in self.TRANSITION_PHRASES]

    def set_websocket_callback(self, callback: Callable) -> None:
        """Set WebSocket broadcast callback."""
        self._ws_broadcast_callback = callback
        logger.debug("WebSocket callback registered for SegmentDetector")

    async def initialize_session(self, session_id: str) -> None:
        """Initialize tracking for a new session."""
        now = datetime.utcnow()
        self.session_start_time[session_id] = now
        self.last_segment_time[session_id] = now
        self.last_transcript_time[session_id] = now
        logger.info(f"Initialized segment tracking for session {session_id}")

    async def check_boundary(
        self,
        session_id: str,
        current_time: datetime,
        recent_text: Optional[str] = None
    ) -> Optional[Dict[str, Any]]:
        """
        Check if current point is a segment boundary.

        Returns:
            Dict with boundary info if detected, None otherwise
        """
        # Initialize session if not exists
        if session_id not in self.session_start_time:
            await self.initialize_session(session_id)

        boundary_info = None

        # Check 1: Time-based interval
        time_boundary = await self._check_time_boundary(session_id, current_time)
        if time_boundary:
            boundary_info = time_boundary

        # Check 2: Long pause detection
        pause_boundary = await self._check_pause_boundary(session_id, current_time)
        if pause_boundary:
            boundary_info = pause_boundary

        # Check 3: Transition phrase detection
        if recent_text:
            phrase_boundary = await self._check_transition_phrases(session_id, recent_text, current_time)
            if phrase_boundary:
                boundary_info = phrase_boundary

        # Update last transcript time
        self.last_transcript_time[session_id] = current_time

        if boundary_info:
            # Update last segment time
            self.last_segment_time[session_id] = current_time
            logger.info(f"Segment boundary detected for session {session_id}: {boundary_info['type']}")

        return boundary_info

    async def _check_time_boundary(
        self,
        session_id: str,
        current_time: datetime
    ) -> Optional[Dict[str, Any]]:
        """Check if time-based interval has passed."""
        last_segment = self.last_segment_time.get(session_id)
        if not last_segment:
            return None

        elapsed = (current_time - last_segment).total_seconds() / 60  # minutes

        if elapsed >= self.time_based_interval_minutes:
            return {
                "type": "time_interval",
                "elapsed_minutes": int(elapsed),
                "description": f"Time-based segment after {int(elapsed)} minutes"
            }

        return None

    async def _check_pause_boundary(
        self,
        session_id: str,
        current_time: datetime
    ) -> Optional[Dict[str, Any]]:
        """Check if there's been a long pause in conversation."""
        last_transcript = self.last_transcript_time.get(session_id)
        if not last_transcript:
            return None

        pause_duration = (current_time - last_transcript).total_seconds()

        if pause_duration >= self.pause_threshold_seconds:
            return {
                "type": "long_pause",
                "pause_seconds": int(pause_duration),
                "description": f"Long pause detected ({int(pause_duration)}s silence)"
            }

        return None

    async def _check_transition_phrases(
        self,
        session_id: str,
        text: str,
        current_time: datetime
    ) -> Optional[Dict[str, Any]]:
        """Check if text contains topic transition phrases."""
        for pattern in self.transition_patterns:
            match = pattern.search(text)
            if match:
                return {
                    "type": "transition_phrase",
                    "phrase": match.group(0),
                    "description": f"Topic transition detected: '{match.group(0)}'"
                }

        return None

    async def handle_segment_boundary(
        self,
        session_id: str,
        boundary_info: Dict[str, Any],
        current_time: datetime
    ) -> None:
        """
        Handle detected segment boundary.

        Triggers:
        - Action completeness alerts
        - WebSocket broadcast for segment transition
        """
        logger.info(f"Processing segment boundary for session {session_id}: {boundary_info['type']}")

        # Broadcast segment transition event
        await self._broadcast_segment_transition(session_id, boundary_info, current_time)

    async def signal_meeting_end(self, session_id: str) -> None:
        """Signal meeting end for final summary generation."""
        logger.info(f"Meeting end signaled for session {session_id}")

        boundary_info = {
            "type": "meeting_end",
            "description": "Meeting concluded"
        }

        # Broadcast meeting end event
        await self._broadcast_segment_transition(
            session_id,
            boundary_info,
            datetime.utcnow()
        )

    async def _broadcast_segment_transition(
        self,
        session_id: str,
        boundary_info: Dict[str, Any],
        timestamp: datetime
    ) -> None:
        """Broadcast segment transition event to WebSocket clients."""
        if not self._ws_broadcast_callback:
            logger.warning("WebSocket callback not set, cannot broadcast segment transition")
            return

        # Calculate meeting elapsed time
        start_time = self.session_start_time.get(session_id, timestamp)
        elapsed_seconds = int((timestamp - start_time).total_seconds())

        event_data = {
            "type": "SEGMENT_TRANSITION",
            "data": {
                "boundary_type": boundary_info["type"],
                "description": boundary_info.get("description", ""),
                "timestamp": timestamp.isoformat(),
                "meeting_elapsed_seconds": elapsed_seconds,
                **{k: v for k, v in boundary_info.items()
                   if k not in ["type", "description"]}
            },
            "timestamp": timestamp.isoformat()
        }

        try:
            await self._ws_broadcast_callback(session_id, event_data)
            logger.debug(f"Broadcasted segment transition for session {session_id}")
        except Exception as e:
            logger.error(f"Failed to broadcast segment transition: {e}", exc_info=True)

    async def get_segment_stats(self, session_id: str) -> Dict[str, Any]:
        """Get segment statistics for a session."""
        if session_id not in self.session_start_time:
            return {}

        start_time = self.session_start_time[session_id]
        last_segment = self.last_segment_time.get(session_id, start_time)
        current_time = datetime.utcnow()

        total_elapsed = (current_time - start_time).total_seconds()
        time_since_last_segment = (current_time - last_segment).total_seconds()

        return {
            "session_id": session_id,
            "meeting_duration_seconds": int(total_elapsed),
            "time_since_last_segment_seconds": int(time_since_last_segment),
            "last_segment_time": last_segment.isoformat(),
            "segments_count": int(total_elapsed / 60 / self.time_based_interval_minutes)
        }

    async def cleanup_session(self, session_id: str) -> None:
        """Cleanup resources for a session."""
        # Remove session state
        self.session_start_time.pop(session_id, None)
        self.last_segment_time.pop(session_id, None)
        self.last_transcript_time.pop(session_id, None)

        logger.info(f"Cleaned up segment detector state for session {session_id}")


# Singleton instance
_segment_detector_instance: Optional[SegmentDetector] = None


def get_segment_detector() -> SegmentDetector:
    """Get or create singleton SegmentDetector instance."""
    global _segment_detector_instance
    if _segment_detector_instance is None:
        _segment_detector_instance = SegmentDetector()
    return _segment_detector_instance
