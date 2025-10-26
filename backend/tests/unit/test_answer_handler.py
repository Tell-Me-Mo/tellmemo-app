"""
Unit tests for AnswerHandler service.

Tests cover:
- Answer processing and question resolution
- Confidence threshold enforcement
- Database updates and status transitions
- WebSocket event broadcasting
- QuestionHandler monitoring cancellation integration
- Error handling and edge cases

Author: TellMeMo Team
Created: 2025-10-26
"""

import pytest
from datetime import datetime, timezone
from uuid import uuid4
from unittest.mock import AsyncMock, MagicMock, patch

from services.intelligence.answer_handler import AnswerHandler
from models.live_insight import (
    AnswerSource,
    InsightStatus,
    InsightType,
    LiveMeetingInsight,
)


@pytest.fixture
def answer_handler():
    """Create AnswerHandler instance for testing."""
    return AnswerHandler(confidence_threshold=0.85)


@pytest.fixture
def mock_question_handler():
    """Create mock QuestionHandler."""
    handler = MagicMock()
    handler.cancel_monitoring = AsyncMock()
    return handler


@pytest.fixture
def mock_ws_callback():
    """Create mock WebSocket broadcast callback."""
    return AsyncMock()


@pytest.fixture
def sample_answer_obj():
    """Sample answer object from GPT stream."""
    return {
        "type": "answer",
        "question_id": "q_abc123-def456",
        "answer_text": "The budget is $250,000 for infrastructure",
        "speaker": "Speaker B",
        "timestamp": "2025-10-26T10:30:00Z",
        "confidence": 0.92
    }


@pytest.fixture
def sample_question_record():
    """Sample question database record."""
    question_id = uuid4()
    return LiveMeetingInsight(
        id=question_id,
        session_id="test-session-123",
        recording_id=uuid4(),
        project_id=uuid4(),
        organization_id=uuid4(),
        insight_type=InsightType.QUESTION,
        detected_at=datetime.now(timezone.utc),
        speaker="Speaker A",
        content="What is the budget for infrastructure?",
        status=InsightStatus.SEARCHING.value,
        insight_metadata={"gpt_id": "q_abc123-def456"}
    )


# ============================================================================
# Initialization Tests
# ============================================================================

def test_initialization():
    """Test AnswerHandler initialization."""
    handler = AnswerHandler(confidence_threshold=0.9)

    assert handler._confidence_threshold == 0.9
    assert handler._question_handler is None
    assert handler._ws_broadcast_callback is None
    assert handler.answers_processed == 0
    assert handler.questions_resolved == 0
    assert handler.low_confidence_answers == 0


def test_set_websocket_callback(answer_handler, mock_ws_callback):
    """Test WebSocket callback registration."""
    answer_handler.set_websocket_callback(mock_ws_callback)

    assert answer_handler._ws_broadcast_callback == mock_ws_callback


def test_set_question_handler(answer_handler, mock_question_handler):
    """Test QuestionHandler registration."""
    answer_handler.set_question_handler(mock_question_handler)

    assert answer_handler._question_handler == mock_question_handler


# ============================================================================
# Answer Processing Tests
# ============================================================================

@pytest.mark.asyncio
async def test_handle_answer_success(
    answer_handler,
    mock_question_handler,
    mock_ws_callback,
    sample_answer_obj,
    sample_question_record
):
    """Test successful answer processing and question resolution."""
    # Setup
    answer_handler.set_question_handler(mock_question_handler)
    answer_handler.set_websocket_callback(mock_ws_callback)
    session_id = "test-session-123"

    # Mock database query and update
    with patch('services.intelligence.answer_handler.get_db_context') as mock_db:
        mock_session = AsyncMock()
        mock_db.return_value.__aenter__.return_value = mock_session

        # Mock database query result
        mock_result = MagicMock()
        mock_result.scalar_one_or_none.return_value = sample_question_record
        mock_session.execute = AsyncMock(return_value=mock_result)

        # Execute
        result = await answer_handler.handle_answer(sample_answer_obj, session_id)

        # Verify
        assert result == str(sample_question_record.id)
        assert answer_handler.answers_processed == 1
        assert answer_handler.questions_resolved == 1

        # Verify database update
        assert sample_question_record.status == InsightStatus.ANSWERED.value
        assert sample_question_record.answer_source == AnswerSource.LIVE_CONVERSATION.value

        # Verify monitoring cancellation
        mock_question_handler.cancel_monitoring.assert_called_once_with(
            session_id,
            str(sample_question_record.id)
        )

        # Verify WebSocket broadcast
        mock_ws_callback.assert_called_once()
        broadcast_args = mock_ws_callback.call_args
        assert broadcast_args[0][0] == session_id
        event_data = broadcast_args[0][1]
        assert event_data["type"] == "ANSWER_DETECTED"
        assert event_data["question_id"] == str(sample_question_record.id)
        assert event_data["answer"] == sample_answer_obj["answer_text"]
        assert event_data["source"] == "live_conversation"


@pytest.mark.asyncio
async def test_handle_answer_low_confidence(
    answer_handler,
    sample_answer_obj
):
    """Test answer with low confidence is not processed."""
    # Setup - confidence below threshold
    sample_answer_obj["confidence"] = 0.75
    session_id = "test-session-123"

    # Execute
    result = await answer_handler.handle_answer(sample_answer_obj, session_id)

    # Verify
    assert result is None
    assert answer_handler.answers_processed == 1
    assert answer_handler.questions_resolved == 0
    assert answer_handler.low_confidence_answers == 1


@pytest.mark.asyncio
async def test_handle_answer_missing_fields():
    """Test answer object with missing required fields."""
    handler = AnswerHandler()
    invalid_answer = {
        "type": "answer",
        "question_id": "q_abc123",
        # Missing answer_text
    }

    result = await handler.handle_answer(invalid_answer, "session-123")

    assert result is None
    assert handler.answers_processed == 1
    assert handler.questions_resolved == 0


@pytest.mark.asyncio
async def test_handle_answer_question_not_found(
    answer_handler,
    sample_answer_obj
):
    """Test answer for non-existent question."""
    session_id = "test-session-123"

    # Mock database query returning None
    with patch('services.intelligence.answer_handler.get_db_context') as mock_db:
        mock_session = AsyncMock()
        mock_db.return_value.__aenter__.return_value = mock_session

        mock_result = MagicMock()
        mock_result.scalar_one_or_none.return_value = None
        mock_session.execute = AsyncMock(return_value=mock_result)

        # Execute
        result = await answer_handler.handle_answer(sample_answer_obj, session_id)

        # Verify
        assert result is None
        assert answer_handler.answers_processed == 1
        assert answer_handler.questions_resolved == 0


@pytest.mark.asyncio
async def test_handle_answer_without_timestamp(
    answer_handler,
    sample_answer_obj,
    sample_question_record
):
    """Test answer processing without timestamp defaults to current time."""
    # Remove timestamp
    sample_answer_obj.pop("timestamp", None)
    session_id = "test-session-123"

    with patch('services.intelligence.answer_handler.get_db_context') as mock_db:
        mock_session = AsyncMock()
        mock_db.return_value.__aenter__.return_value = mock_session

        mock_result = MagicMock()
        mock_result.scalar_one_or_none.return_value = sample_question_record
        mock_session.execute = AsyncMock(return_value=mock_result)

        # Execute
        result = await answer_handler.handle_answer(sample_answer_obj, session_id)

        # Verify
        assert result == str(sample_question_record.id)
        assert sample_question_record.status == InsightStatus.ANSWERED.value


@pytest.mark.asyncio
async def test_handle_answer_without_confidence(
    answer_handler,
    sample_answer_obj,
    sample_question_record
):
    """Test answer processing without confidence uses default (0.9)."""
    # Remove confidence
    sample_answer_obj.pop("confidence", None)
    session_id = "test-session-123"

    with patch('services.intelligence.answer_handler.get_db_context') as mock_db:
        mock_session = AsyncMock()
        mock_db.return_value.__aenter__.return_value = mock_session

        mock_result = MagicMock()
        mock_result.scalar_one_or_none.return_value = sample_question_record
        mock_session.execute = AsyncMock(return_value=mock_result)

        # Execute
        result = await answer_handler.handle_answer(sample_answer_obj, session_id)

        # Verify - default confidence 0.9 is above threshold 0.85
        assert result == str(sample_question_record.id)


# ============================================================================
# Monitoring Cancellation Tests
# ============================================================================

@pytest.mark.asyncio
async def test_cancel_monitoring_on_answer(
    answer_handler,
    mock_question_handler,
    sample_answer_obj,
    sample_question_record
):
    """Test that Tier 3 monitoring is cancelled when answer is detected."""
    answer_handler.set_question_handler(mock_question_handler)
    session_id = "test-session-123"

    with patch('services.intelligence.answer_handler.get_db_context') as mock_db:
        mock_session = AsyncMock()
        mock_db.return_value.__aenter__.return_value = mock_session

        mock_result = MagicMock()
        mock_result.scalar_one_or_none.return_value = sample_question_record
        mock_session.execute = AsyncMock(return_value=mock_result)

        # Execute
        await answer_handler.handle_answer(sample_answer_obj, session_id)

        # Verify monitoring was cancelled
        mock_question_handler.cancel_monitoring.assert_called_once_with(
            session_id,
            str(sample_question_record.id)
        )


@pytest.mark.asyncio
async def test_handle_answer_without_question_handler(
    answer_handler,
    sample_answer_obj,
    sample_question_record
):
    """Test answer processing works without QuestionHandler registered."""
    # Don't set question handler
    session_id = "test-session-123"

    with patch('services.intelligence.answer_handler.get_db_context') as mock_db:
        mock_session = AsyncMock()
        mock_db.return_value.__aenter__.return_value = mock_session

        mock_result = MagicMock()
        mock_result.scalar_one_or_none.return_value = sample_question_record
        mock_session.execute = AsyncMock(return_value=mock_result)

        # Execute
        result = await answer_handler.handle_answer(sample_answer_obj, session_id)

        # Verify - should succeed despite no question handler
        assert result == str(sample_question_record.id)


@pytest.mark.asyncio
async def test_cancel_monitoring_failure_is_handled(
    answer_handler,
    mock_question_handler,
    sample_answer_obj,
    sample_question_record
):
    """Test that monitoring cancellation failure doesn't break answer processing."""
    answer_handler.set_question_handler(mock_question_handler)
    session_id = "test-session-123"

    # Make cancel_monitoring raise exception
    mock_question_handler.cancel_monitoring.side_effect = Exception("Cancel failed")

    with patch('services.intelligence.answer_handler.get_db_context') as mock_db:
        mock_session = AsyncMock()
        mock_db.return_value.__aenter__.return_value = mock_session

        mock_result = MagicMock()
        mock_result.scalar_one_or_none.return_value = sample_question_record
        mock_session.execute = AsyncMock(return_value=mock_result)

        # Execute
        result = await answer_handler.handle_answer(sample_answer_obj, session_id)

        # Verify - answer processing should still succeed
        assert result == str(sample_question_record.id)
        assert answer_handler.questions_resolved == 1


# ============================================================================
# WebSocket Broadcast Tests
# ============================================================================

@pytest.mark.asyncio
async def test_broadcast_without_callback(
    answer_handler,
    sample_answer_obj,
    sample_question_record
):
    """Test answer processing works without WebSocket callback."""
    # Don't set WebSocket callback
    session_id = "test-session-123"

    with patch('services.intelligence.answer_handler.get_db_context') as mock_db:
        mock_session = AsyncMock()
        mock_db.return_value.__aenter__.return_value = mock_session

        mock_result = MagicMock()
        mock_result.scalar_one_or_none.return_value = sample_question_record
        mock_session.execute = AsyncMock(return_value=mock_result)

        # Execute
        result = await answer_handler.handle_answer(sample_answer_obj, session_id)

        # Verify - should succeed despite no callback
        assert result == str(sample_question_record.id)


@pytest.mark.asyncio
async def test_broadcast_failure_is_handled(
    answer_handler,
    mock_ws_callback,
    sample_answer_obj,
    sample_question_record
):
    """Test that WebSocket broadcast failure doesn't break answer processing."""
    answer_handler.set_websocket_callback(mock_ws_callback)
    session_id = "test-session-123"

    # Make broadcast raise exception
    mock_ws_callback.side_effect = Exception("Broadcast failed")

    with patch('services.intelligence.answer_handler.get_db_context') as mock_db:
        mock_session = AsyncMock()
        mock_db.return_value.__aenter__.return_value = mock_session

        mock_result = MagicMock()
        mock_result.scalar_one_or_none.return_value = sample_question_record
        mock_session.execute = AsyncMock(return_value=mock_result)

        # Execute
        result = await answer_handler.handle_answer(sample_answer_obj, session_id)

        # Verify - answer processing should still succeed
        assert result == str(sample_question_record.id)
        assert answer_handler.questions_resolved == 1


# ============================================================================
# Database Error Handling Tests
# ============================================================================

@pytest.mark.asyncio
async def test_handle_answer_database_error(
    answer_handler,
    sample_answer_obj
):
    """Test database error handling during answer processing."""
    session_id = "test-session-123"

    # Mock database exception
    with patch('services.intelligence.answer_handler.get_db_context') as mock_db:
        mock_db.side_effect = Exception("Database connection failed")

        # Execute
        result = await answer_handler.handle_answer(sample_answer_obj, session_id)

        # Verify
        assert result is None
        assert answer_handler.answers_processed == 1
        assert answer_handler.questions_resolved == 0


# ============================================================================
# Metrics Tests
# ============================================================================

def test_get_metrics(answer_handler):
    """Test metrics retrieval."""
    # Set some metrics manually
    answer_handler.answers_processed = 10
    answer_handler.questions_resolved = 8
    answer_handler.low_confidence_answers = 2

    metrics = answer_handler.get_metrics()

    assert metrics["answers_processed"] == 10
    assert metrics["questions_resolved"] == 8
    assert metrics["low_confidence_answers"] == 2


# ============================================================================
# Session Cleanup Tests
# ============================================================================

@pytest.mark.asyncio
async def test_cleanup_session():
    """Test session cleanup."""
    handler = AnswerHandler()
    session_id = "test-session-123"

    # Should not raise exception
    await handler.cleanup_session(session_id)


# ============================================================================
# Edge Cases Tests
# ============================================================================

@pytest.mark.asyncio
async def test_multiple_answers_for_same_question(
    answer_handler,
    sample_answer_obj,
    sample_question_record
):
    """Test processing multiple answers for the same question."""
    session_id = "test-session-123"

    with patch('services.intelligence.answer_handler.get_db_context') as mock_db:
        mock_session = AsyncMock()
        mock_db.return_value.__aenter__.return_value = mock_session

        mock_result = MagicMock()
        mock_result.scalar_one_or_none.return_value = sample_question_record
        mock_session.execute = AsyncMock(return_value=mock_result)

        # First answer
        result1 = await answer_handler.handle_answer(sample_answer_obj, session_id)
        assert result1 == str(sample_question_record.id)

        # Second answer for same question (status already ANSWERED)
        sample_answer_obj["answer_text"] = "Actually, it's $300,000"
        sample_answer_obj["confidence"] = 0.95

        result2 = await answer_handler.handle_answer(sample_answer_obj, session_id)

        # Both should succeed
        assert result2 == str(sample_question_record.id)
        assert answer_handler.questions_resolved == 2


@pytest.mark.asyncio
async def test_answer_with_invalid_timestamp_format(
    answer_handler,
    sample_answer_obj,
    sample_question_record
):
    """Test answer with invalid timestamp format falls back to current time."""
    sample_answer_obj["timestamp"] = "invalid-timestamp"
    session_id = "test-session-123"

    with patch('services.intelligence.answer_handler.get_db_context') as mock_db:
        mock_session = AsyncMock()
        mock_db.return_value.__aenter__.return_value = mock_session

        mock_result = MagicMock()
        mock_result.scalar_one_or_none.return_value = sample_question_record
        mock_session.execute = AsyncMock(return_value=mock_result)

        # Execute
        result = await answer_handler.handle_answer(sample_answer_obj, session_id)

        # Verify - should succeed with current timestamp
        assert result == str(sample_question_record.id)


def test_custom_confidence_threshold():
    """Test AnswerHandler with custom confidence threshold."""
    handler = AnswerHandler(confidence_threshold=0.95)

    assert handler._confidence_threshold == 0.95


@pytest.mark.asyncio
async def test_answer_at_exact_confidence_threshold(
    sample_answer_obj,
    sample_question_record
):
    """Test answer with confidence exactly at threshold is processed."""
    # Set handler threshold to 0.92
    handler = AnswerHandler(confidence_threshold=0.92)

    # Answer has confidence 0.92 (exact match)
    sample_answer_obj["confidence"] = 0.92
    session_id = "test-session-123"

    with patch('services.intelligence.answer_handler.get_db_context') as mock_db:
        mock_session = AsyncMock()
        mock_db.return_value.__aenter__.return_value = mock_session

        mock_result = MagicMock()
        mock_result.scalar_one_or_none.return_value = sample_question_record
        mock_session.execute = AsyncMock(return_value=mock_result)

        # Execute
        result = await handler.handle_answer(sample_answer_obj, session_id)

        # Verify - should NOT be processed (threshold is exclusive <, not <=)
        assert result is None
        assert handler.low_confidence_answers == 1
