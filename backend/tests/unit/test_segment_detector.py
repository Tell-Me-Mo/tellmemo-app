"""
Unit tests for SegmentDetector service.

Tests cover:
- Session initialization and tracking
- Three boundary detection methods (time, pause, transition phrases)
- Segment transition broadcasting
- Meeting end signaling
- Segment statistics calculation
- Session cleanup

Author: TellMeMo Team
Created: 2025-10-27
Task: 8.1 - Unit Tests for Backend Services
"""

import pytest
import asyncio
from datetime import datetime, timezone
from unittest.mock import AsyncMock, MagicMock, patch

from services.intelligence.segment_detector import SegmentDetector


@pytest.fixture
def segment_detector():
    """Create SegmentDetector instance for testing."""
    return SegmentDetector()


@pytest.fixture
def mock_ws_callback():
    """Create mock WebSocket broadcast callback."""
    return AsyncMock()


@pytest.fixture
def session_id():
    """Generate unique session ID for testing."""
    return f"test_session_{datetime.now().timestamp()}"


# ============================================================================
# Initialization Tests
# ============================================================================

def test_initialization(segment_detector):
    """Test SegmentDetector initialization."""
    assert segment_detector.time_based_interval_minutes == 10  # 10 minutes
    assert segment_detector.pause_threshold_seconds == 10
    assert len(segment_detector.transition_patterns) > 0
    assert segment_detector.last_segment_time == {}
    assert segment_detector._ws_broadcast_callback is None


def test_set_websocket_callback(segment_detector, mock_ws_callback):
    """Test setting WebSocket callback."""
    segment_detector.set_websocket_callback(mock_ws_callback)
    assert segment_detector._ws_broadcast_callback == mock_ws_callback


# ============================================================================
# Session Management Tests
# ============================================================================

@pytest.mark.asyncio
async def test_initialize_session(segment_detector, session_id):
    """Test session initialization."""
    await segment_detector.initialize_session(session_id)

    assert session_id in segment_detector.session_start_time
    assert segment_detector.session_start_time[session_id] is not None
    assert segment_detector.last_segment_time[session_id] is not None
    assert segment_detector.last_transcript_time[session_id] is not None


@pytest.mark.asyncio
async def test_cleanup_session(segment_detector, session_id):
    """Test session cleanup removes state."""
    await segment_detector.initialize_session(session_id)
    assert session_id in segment_detector.session_start_time

    await segment_detector.cleanup_session(session_id)
    assert session_id not in segment_detector.session_start_time


# ============================================================================
# Boundary Detection Tests
# ============================================================================

@pytest.mark.asyncio
async def test_time_boundary_detection(segment_detector, session_id):
    """Test time-based boundary detection (10 minute intervals)."""
    from datetime import timedelta
    current_time = datetime.utcnow()

    # Initialize session with old segment time (11 minutes ago)
    await segment_detector.initialize_session(session_id)
    segment_detector.last_segment_time[session_id] = current_time - timedelta(minutes=11)

    boundary = await segment_detector.check_boundary(
        session_id=session_id,
        current_time=current_time,
        recent_text="Some discussion happening"
    )

    assert boundary is not None
    assert boundary["type"] == "time_interval"
    assert "elapsed_minutes" in boundary


@pytest.mark.asyncio
async def test_pause_boundary_detection(segment_detector, session_id):
    """Test long pause detection (>10 seconds silence)."""
    from datetime import timedelta
    current_time = datetime.utcnow()

    # Initialize session with recent segment but old transcript (12 seconds ago)
    await segment_detector.initialize_session(session_id)
    segment_detector.last_segment_time[session_id] = current_time - timedelta(seconds=60)
    segment_detector.last_transcript_time[session_id] = current_time - timedelta(seconds=12)

    boundary = await segment_detector.check_boundary(
        session_id=session_id,
        current_time=current_time,
        recent_text="Resuming after silence"
    )

    assert boundary is not None
    assert boundary["type"] == "long_pause"
    assert boundary["pause_seconds"] >= 12


@pytest.mark.asyncio
async def test_transition_phrase_detection(segment_detector, session_id):
    """Test transition phrase detection."""
    current_time = datetime.utcnow()

    await segment_detector.initialize_session(session_id)

    transition_texts = [
        "Alright, moving on to the next topic",
        "Let's discuss the budget now",
        "Switching gears to talk about infrastructure",
        "Before we end, I want to mention",
        "To wrap up this discussion"
    ]

    for text in transition_texts:
        boundary = await segment_detector.check_boundary(
            session_id=session_id,
            current_time=current_time,
            recent_text=text
        )

        assert boundary is not None, f"Failed to detect phrase in: {text}"
        assert boundary["type"] == "transition_phrase"
        assert "phrase" in boundary


@pytest.mark.asyncio
async def test_no_boundary_detected(segment_detector, session_id):
    """Test when no boundary should be detected."""
    from datetime import timedelta
    current_time = datetime.utcnow()

    # Initialize session with recent activity (2 minutes ago)
    await segment_detector.initialize_session(session_id)
    segment_detector.last_segment_time[session_id] = current_time - timedelta(minutes=2)
    segment_detector.last_transcript_time[session_id] = current_time - timedelta(seconds=2)

    boundary = await segment_detector.check_boundary(
        session_id=session_id,
        current_time=current_time,
        recent_text="Regular conversation continues"
    )

    assert boundary is None


@pytest.mark.asyncio
async def test_auto_initialization_on_first_check(segment_detector, session_id):
    """Test that session is auto-initialized on first boundary check."""
    current_time = datetime.utcnow()

    # Don't manually initialize
    assert session_id not in segment_detector.session_start_time

    # Should auto-initialize
    boundary = await segment_detector.check_boundary(
        session_id=session_id,
        current_time=current_time,
        recent_text="First transcript"
    )

    # Should be initialized now
    assert session_id in segment_detector.session_start_time
    # First check should not return boundary
    assert boundary is None


# ============================================================================
# Segment Handling Tests
# ============================================================================

@pytest.mark.asyncio
async def test_handle_segment_boundary(
    segment_detector,
    session_id,
    mock_ws_callback
):
    """Test handling segment boundary updates state and broadcasts."""
    segment_detector.set_websocket_callback(mock_ws_callback)

    current_time = datetime.utcnow()
    await segment_detector.initialize_session(session_id)

    boundary_info = {
        "type": "time_interval",
        "elapsed_minutes": 11
    }

    await segment_detector.handle_segment_boundary(
        session_id=session_id,
        boundary_info=boundary_info,
        current_time=current_time
    )

    # Verify WebSocket broadcast
    mock_ws_callback.assert_called_once()
    call_args = mock_ws_callback.call_args[0]
    assert call_args[0] == session_id
    event_data = call_args[1]
    assert event_data["type"] == "SEGMENT_TRANSITION"
    assert event_data["data"]["boundary_type"] == "time_interval"


@pytest.mark.asyncio
async def test_signal_meeting_end(
    segment_detector,
    session_id,
    mock_ws_callback
):
    """Test signaling meeting end broadcasts special event."""
    segment_detector.set_websocket_callback(mock_ws_callback)

    await segment_detector.initialize_session(session_id)

    await segment_detector.signal_meeting_end(session_id)

    # Verify WebSocket broadcast
    mock_ws_callback.assert_called_once()
    call_args = mock_ws_callback.call_args[0]
    assert call_args[0] == session_id
    event_data = call_args[1]
    assert event_data["type"] == "SEGMENT_TRANSITION"
    assert event_data["data"]["boundary_type"] == "meeting_end"


# ============================================================================
# Statistics Tests
# ============================================================================

@pytest.mark.asyncio
async def test_get_segment_stats(segment_detector, session_id):
    """Test segment statistics calculation."""
    from datetime import timedelta
    current_time = datetime.utcnow()

    # Initialize and simulate some activity
    await segment_detector.initialize_session(session_id)
    segment_detector.last_segment_time[session_id] = current_time - timedelta(minutes=5)

    stats = await segment_detector.get_segment_stats(session_id)

    assert stats is not None
    assert isinstance(stats, dict)


@pytest.mark.asyncio
async def test_get_segment_stats_uninitialized_session(segment_detector):
    """Test stats for uninitialized session returns empty stats."""
    stats = await segment_detector.get_segment_stats("nonexistent_session")

    assert stats is not None
    assert isinstance(stats, dict)


# ============================================================================
# Transition Phrase Pattern Tests
# ============================================================================

def test_transition_patterns_coverage(segment_detector):
    """Test that all expected transition phrase patterns are present."""
    patterns = segment_detector.transition_patterns

    # Should have multiple patterns (actual implementation has 5 patterns)
    assert len(patterns) >= 5

    # Test sample phrases match patterns
    test_phrases = {
        "moving on to the next topic": True,
        "let's discuss the budget": True,
        "switching gears here": True,
        "before we end": True,
        "to wrap up": True,
        "any questions before we move on": True,
        "regular conversation": False
    }

    for phrase, should_match in test_phrases.items():
        matched = any(pattern.search(phrase) for pattern in patterns)
        assert matched == should_match, f"Failed for phrase: {phrase}"


# ============================================================================
# WebSocket Broadcast Tests
# ============================================================================

@pytest.mark.asyncio
async def test_broadcast_without_callback(segment_detector, session_id):
    """Test broadcasting gracefully handles missing callback."""
    # No callback configured
    await segment_detector.initialize_session(session_id)

    boundary_info = {
        "type": "time_interval",
        "elapsed_minutes": 11
    }

    # Should not raise exception
    await segment_detector.handle_segment_boundary(
        session_id=session_id,
        boundary_info=boundary_info,
        current_time=datetime.utcnow()
    )


@pytest.mark.asyncio
async def test_broadcast_exception_handling(
    segment_detector,
    session_id
):
    """Test broadcast handles callback exceptions gracefully."""
    failing_callback = AsyncMock(side_effect=Exception("Broadcast failed"))
    segment_detector.set_websocket_callback(failing_callback)

    await segment_detector.initialize_session(session_id)

    boundary_info = {
        "type": "time_interval",
        "elapsed_minutes": 11
    }

    # Should not raise exception despite broadcast failure
    await segment_detector.handle_segment_boundary(
        session_id=session_id,
        boundary_info=boundary_info,
        current_time=datetime.utcnow()
    )


# ============================================================================
# Integration Tests
# ============================================================================

@pytest.mark.asyncio
async def test_full_segment_detection_flow(
    segment_detector,
    session_id,
    mock_ws_callback
):
    """Test complete flow from initialization to boundary detection."""
    from datetime import timedelta
    segment_detector.set_websocket_callback(mock_ws_callback)

    current_time = datetime.utcnow()

    # 1. Initialize session
    await segment_detector.initialize_session(session_id)

    # 2. Simulate 11 minutes passing (trigger time boundary)
    segment_detector.last_segment_time[session_id] = current_time - timedelta(minutes=11)

    # 3. Check boundary
    boundary = await segment_detector.check_boundary(
        session_id=session_id,
        current_time=current_time,
        recent_text="Continuing discussion"
    )

    assert boundary is not None
    assert boundary["type"] == "time_interval"

    # 4. Handle boundary
    await segment_detector.handle_segment_boundary(
        session_id=session_id,
        boundary_info=boundary,
        current_time=current_time
    )

    # 5. Verify broadcast
    mock_ws_callback.assert_called()

    # 6. Get stats
    stats = await segment_detector.get_segment_stats(session_id)
    assert stats is not None

    # 7. Signal meeting end
    await segment_detector.signal_meeting_end(session_id)

    # 8. Cleanup
    await segment_detector.cleanup_session(session_id)
    assert session_id not in segment_detector.session_start_time
