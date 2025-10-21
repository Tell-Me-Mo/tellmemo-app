"""
Meeting Time Tracker Service for Phase 6: Meeting Efficiency Features

Tracks how time is being spent in meetings, identifying when discussions are
running long or when time could be better allocated.
"""

from dataclasses import dataclass
from typing import Dict, List, Optional
from datetime import datetime, timezone, timedelta
from collections import defaultdict
import logging

logger = logging.getLogger(__name__)


@dataclass
class TimeUsageAlert:
    """Alert for meeting time usage patterns"""
    alert_type: str  # 'long_discussion', 'time_limit_approaching', 'off_topic'
    topic: str
    time_spent_minutes: float
    severity: str  # 'high', 'medium', 'low'
    reasoning: str
    suggestions: List[str]
    timestamp: datetime


class MeetingTimeTrackerService:
    """
    Service for tracking meeting time usage and alerting when time could be better spent.

    Helps teams stay on track by monitoring:
    - Individual topic discussion duration
    - Overall meeting duration
    - Time spent on specific agenda items
    """

    # Configuration
    LONG_DISCUSSION_THRESHOLD_MINUTES = 10  # Alert if single topic > 10 minutes
    MEETING_TIME_WARNING_MINUTES = 45  # Warn when approaching typical 60-min meeting limit
    CHECK_INTERVAL_CHUNKS = 5  # Check time usage every 5 chunks (~50 seconds)

    def __init__(self):
        # Session-specific tracking
        self.session_start_times: Dict[str, datetime] = {}
        self.topic_start_times: Dict[str, Dict[str, datetime]] = defaultdict(dict)
        self.last_topic: Dict[str, Optional[str]] = {}
        self.chunk_count: Dict[str, int] = defaultdict(int)
        self.last_alert_times: Dict[str, Dict[str, datetime]] = defaultdict(dict)

    async def track_time_usage(
        self,
        session_id: str,
        current_text: str,
        chunk_timestamp: datetime,
        current_topic: Optional[str] = None
    ) -> Optional[TimeUsageAlert]:
        """
        Track time usage and generate alerts for inefficient time spending.

        Args:
            session_id: Meeting session identifier
            current_text: Current discussion text (for topic extraction if needed)
            chunk_timestamp: When this chunk was captured
            current_topic: Explicit topic name if known (otherwise inferred from text)

        Returns:
            TimeUsageAlert if time usage issue detected, None otherwise
        """

        # Initialize session tracking
        if session_id not in self.session_start_times:
            self.session_start_times[session_id] = chunk_timestamp
            logger.info(f"Started time tracking for session {session_id}")

        # Increment chunk count
        self.chunk_count[session_id] += 1

        # Only check every N chunks to avoid alert fatigue
        if self.chunk_count[session_id] % self.CHECK_INTERVAL_CHUNKS != 0:
            return None

        # Calculate total meeting duration
        meeting_duration = (chunk_timestamp - self.session_start_times[session_id]).total_seconds() / 60

        # Check if meeting is running long
        if meeting_duration >= self.MEETING_TIME_WARNING_MINUTES:
            alert_key = f"meeting_duration_{int(meeting_duration/15)*15}"  # Alert every 15 mins
            if not self._was_recently_alerted(session_id, alert_key, chunk_timestamp):
                self._record_alert(session_id, alert_key, chunk_timestamp)
                return TimeUsageAlert(
                    alert_type='time_limit_approaching',
                    topic='Overall Meeting',
                    time_spent_minutes=meeting_duration,
                    severity='high' if meeting_duration >= 55 else 'medium',
                    reasoning=f"Meeting has been running for {meeting_duration:.1f} minutes. "
                             f"Consider wrapping up or scheduling a follow-up.",
                    suggestions=[
                        "Summarize key decisions and action items",
                        "Schedule a follow-up meeting for remaining topics",
                        "Prioritize the most critical remaining items",
                        "Set a hard stop time for the meeting"
                    ],
                    timestamp=datetime.now(timezone.utc)
                )

        # Track current topic duration (if topic provided or can be inferred)
        if current_topic:
            # Check if topic changed
            last_topic = self.last_topic.get(session_id)

            if last_topic != current_topic:
                # Topic changed - start tracking new topic
                self.topic_start_times[session_id][current_topic] = chunk_timestamp
                self.last_topic[session_id] = current_topic
                logger.debug(f"Started tracking topic '{current_topic}' for session {session_id}")
            else:
                # Same topic - check duration
                topic_start = self.topic_start_times[session_id].get(current_topic)
                if topic_start:
                    topic_duration = (chunk_timestamp - topic_start).total_seconds() / 60

                    if topic_duration >= self.LONG_DISCUSSION_THRESHOLD_MINUTES:
                        alert_key = f"long_discussion_{current_topic}"
                        if not self._was_recently_alerted(session_id, alert_key, chunk_timestamp):
                            self._record_alert(session_id, alert_key, chunk_timestamp)
                            return TimeUsageAlert(
                                alert_type='long_discussion',
                                topic=current_topic,
                                time_spent_minutes=topic_duration,
                                severity='medium',
                                reasoning=f"'{current_topic}' has been discussed for {topic_duration:.1f} minutes. "
                                         f"Consider moving to the next topic or taking action.",
                                suggestions=[
                                    "Summarize what has been decided so far",
                                    "Take a vote if consensus is difficult",
                                    "Table this topic and revisit later",
                                    "Assign someone to research and report back"
                                ],
                                timestamp=datetime.now(timezone.utc)
                            )

        return None

    def _was_recently_alerted(
        self,
        session_id: str,
        alert_key: str,
        current_time: datetime,
        cooldown_minutes: int = 5
    ) -> bool:
        """Check if we recently sent this type of alert (avoid alert fatigue)"""
        last_alert = self.last_alert_times[session_id].get(alert_key)
        if last_alert:
            time_since_alert = (current_time - last_alert).total_seconds() / 60
            return time_since_alert < cooldown_minutes
        return False

    def _record_alert(self, session_id: str, alert_key: str, timestamp: datetime):
        """Record that we sent an alert"""
        self.last_alert_times[session_id][alert_key] = timestamp

    def get_meeting_summary(self, session_id: str) -> Dict[str, any]:
        """
        Get a summary of time usage for the meeting.

        Args:
            session_id: Meeting session identifier

        Returns:
            Dictionary with time usage statistics
        """
        if session_id not in self.session_start_times:
            return {'error': 'Session not found'}

        current_time = datetime.now(timezone.utc)
        meeting_duration = (current_time - self.session_start_times[session_id]).total_seconds() / 60

        # Calculate topic durations
        topic_durations = {}
        for topic, start_time in self.topic_start_times[session_id].items():
            duration = (current_time - start_time).total_seconds() / 60
            topic_durations[topic] = duration

        return {
            'session_id': session_id,
            'total_duration_minutes': meeting_duration,
            'topics_discussed': len(topic_durations),
            'topic_durations': topic_durations,
            'chunks_processed': self.chunk_count.get(session_id, 0)
        }

    def clear_session(self, session_id: str):
        """Clear tracking data for a session when meeting ends"""
        if session_id in self.session_start_times:
            del self.session_start_times[session_id]
        if session_id in self.topic_start_times:
            del self.topic_start_times[session_id]
        if session_id in self.last_topic:
            del self.last_topic[session_id]
        if session_id in self.chunk_count:
            del self.chunk_count[session_id]
        if session_id in self.last_alert_times:
            del self.last_alert_times[session_id]
        logger.info(f"Cleared time tracking for session {session_id}")
