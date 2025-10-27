"""
Unit tests for GPTAnswerGenerator service (Tier 4 Answer Discovery).

Tests cover:
- Answer generation with GPT-5-mini
- Confidence threshold enforcement (>0.70)
- Database updates and question status transitions
- WebSocket event broadcasting
- Timeout handling (3 seconds)
- Error handling for JSON parsing and low confidence
- GPT-generated answer disclaimer

Author: TellMeMo Team
Created: 2025-10-27
Task: 8.1 - Unit Tests for Backend Services
"""

import pytest
import asyncio
import uuid
from datetime import datetime, timezone
from unittest.mock import AsyncMock, MagicMock, patch
from sqlalchemy.orm import Session

from services.intelligence.gpt_answer_generator import GPTAnswerGenerator
from models.live_insight import (
    LiveMeetingInsight,
    InsightType,
    InsightStatus,
    AnswerSource
)


@pytest.fixture
def gpt_generator():
    """Create GPTAnswerGenerator instance for testing."""
    return GPTAnswerGenerator(timeout=3.0, confidence_threshold=0.70)


@pytest.fixture
def mock_broadcast_callback():
    """Create mock WebSocket broadcast callback."""
    return AsyncMock()


@pytest.fixture
def mock_llm_client():
    """Create mock LLM client."""
    client = MagicMock()
    client.generate_structured_response = AsyncMock()
    return client


@pytest.fixture
def sample_question_record():
    """Sample question database record."""
    question_id = uuid.uuid4()
    return LiveMeetingInsight(
        id=question_id,
        session_id="test-session-123",
        recording_id=uuid.uuid4(),
        project_id=uuid.uuid4(),
        organization_id=uuid.uuid4(),
        insight_type=InsightType.QUESTION,
        detected_at=datetime.now(timezone.utc),
        speaker="Speaker A",
        content="What is the typical ROI timeline for infrastructure investments?",
        status=InsightStatus.MONITORING.value,
        insight_metadata={"gpt_id": "q_abc123-def456"}
    )


@pytest.fixture
def mock_db_session():
    """Create mock database session."""
    session = MagicMock(spec=Session)
    session.query = MagicMock()
    session.commit = MagicMock()
    session.rollback = MagicMock()
    return session


# ============================================================================
# Initialization Tests
# ============================================================================

def test_initialization():
    """Test GPTAnswerGenerator initialization."""
    generator = GPTAnswerGenerator(timeout=5.0, confidence_threshold=0.75)

    assert generator._timeout == 5.0
    assert generator._confidence_threshold == 0.75
    assert generator._broadcast_callback is None


def test_initialization_defaults():
    """Test default values."""
    generator = GPTAnswerGenerator()

    assert generator._timeout == 3.0
    assert generator._confidence_threshold == 0.70


# ============================================================================
# Answer Generation Tests
# ============================================================================

@pytest.mark.asyncio
async def test_generate_answer_success(
    gpt_generator,
    sample_question_record,
    mock_db_session,
    mock_broadcast_callback
):
    """Test successful answer generation with high confidence."""
    gpt_generator._broadcast_callback = mock_broadcast_callback

    # Mock GPT response with high confidence
    gpt_response = {
        "answer": "Typical infrastructure investments show ROI within 18-36 months.",
        "confidence": 0.78,
        "sources": "general knowledge",
        "disclaimer": "AI-generated answer based on general knowledge"
    }

    with patch('services.intelligence.gpt_answer_generator.get_multi_llm_client') as mock_get_client:
        mock_client = MagicMock()
        mock_client.generate_structured_response = AsyncMock(return_value=gpt_response)
        mock_get_client.return_value = mock_client

        # Mock database query
        mock_db_session.query.return_value.filter.return_value.first.return_value = sample_question_record

        result = await gpt_generator.generate_answer(
            session_id="test-session-123",
            question_id=str(sample_question_record.id),
            question_text="What is the typical ROI timeline?",
            speaker="Speaker A",
            meeting_context="Discussion about budget planning",
            db_session=mock_db_session
        )

    assert result is True
    assert sample_question_record.status == InsightStatus.FOUND.value
    assert sample_question_record.answer_source == AnswerSource.GPT_GENERATED.value
    mock_broadcast_callback.assert_called_once()


@pytest.mark.asyncio
async def test_generate_answer_low_confidence(
    gpt_generator,
    sample_question_record,
    mock_db_session
):
    """Test answer generation rejects low confidence responses."""
    # Mock GPT response with low confidence (<0.70)
    gpt_response = {
        "answer": "I'm not sure about specific timelines.",
        "confidence": 0.65,
        "sources": "general knowledge",
        "disclaimer": "AI-generated answer"
    }

    with patch('services.intelligence.gpt_answer_generator.get_multi_llm_client') as mock_get_client:
        mock_client = MagicMock()
        mock_client.generate_structured_response = AsyncMock(return_value=gpt_response)
        mock_get_client.return_value = mock_client

        mock_db_session.query.return_value.filter.return_value.first.return_value = sample_question_record

        result = await gpt_generator.generate_answer(
            session_id="test-session-123",
            question_id=str(sample_question_record.id),
            question_text="What is the budget?",
            speaker="Speaker A",
            meeting_context="Budget discussion",
            db_session=mock_db_session
        )

    # Should return False due to low confidence
    assert result is False
    # Status should remain unchanged
    assert sample_question_record.status == InsightStatus.MONITORING.value


@pytest.mark.asyncio
async def test_generate_answer_timeout(
    gpt_generator,
    sample_question_record,
    mock_db_session
):
    """Test timeout handling during GPT generation."""

    async def slow_generate(*args, **kwargs):
        await asyncio.sleep(10)  # Exceed 3-second timeout
        return {"answer": "test", "confidence": 0.8}

    with patch('services.intelligence.gpt_answer_generator.get_multi_llm_client') as mock_get_client:
        mock_client = MagicMock()
        mock_client.generate_structured_response = slow_generate
        mock_get_client.return_value = mock_client

        mock_db_session.query.return_value.filter.return_value.first.return_value = sample_question_record

        result = await gpt_generator.generate_answer(
            session_id="test-session-123",
            question_id=str(sample_question_record.id),
            question_text="What is the budget?",
            speaker="Speaker A",
            meeting_context="Budget discussion",
            db_session=mock_db_session
        )

    # Should return False on timeout
    assert result is False


@pytest.mark.asyncio
async def test_generate_answer_missing_answer_field(
    gpt_generator,
    sample_question_record,
    mock_db_session
):
    """Test handling of malformed GPT response missing 'answer' field."""
    gpt_response = {
        "confidence": 0.8,
        # Missing 'answer' field
    }

    with patch('services.intelligence.gpt_answer_generator.get_multi_llm_client') as mock_get_client:
        mock_client = MagicMock()
        mock_client.generate_structured_response = AsyncMock(return_value=gpt_response)
        mock_get_client.return_value = mock_client

        mock_db_session.query.return_value.filter.return_value.first.return_value = sample_question_record

        result = await gpt_generator.generate_answer(
            session_id="test-session-123",
            question_id=str(sample_question_record.id),
            question_text="What is the budget?",
            speaker="Speaker A",
            meeting_context="Budget discussion",
            db_session=mock_db_session
        )

    assert result is False


@pytest.mark.asyncio
async def test_generate_answer_confidence_normalization(
    gpt_generator,
    sample_question_record,
    mock_db_session
):
    """Test confidence score normalization when > 1.0."""
    # Mock GPT response with confidence > 1.0
    gpt_response = {
        "answer": "The budget is $250,000",
        "confidence": 85,  # Should be normalized to 0.85
        "sources": "general knowledge"
    }

    with patch('services.intelligence.gpt_answer_generator.get_multi_llm_client') as mock_get_client:
        mock_client = MagicMock()
        mock_client.generate_structured_response = AsyncMock(return_value=gpt_response)
        mock_get_client.return_value = mock_client

        mock_db_session.query.return_value.filter.return_value.first.return_value = sample_question_record

        result = await gpt_generator.generate_answer(
            session_id="test-session-123",
            question_id=str(sample_question_record.id),
            question_text="What is the budget?",
            speaker="Speaker A",
            meeting_context="Budget discussion",
            db_session=mock_db_session
        )

    assert result is True
    # Check that confidence was normalized
    tier_results = sample_question_record.insight_metadata.get("tier_results", [])
    assert len(tier_results) == 1
    assert tier_results[0]["confidence"] == 0.85


# ============================================================================
# WebSocket Broadcast Tests
# ============================================================================

@pytest.mark.asyncio
async def test_broadcast_gpt_answer(
    gpt_generator,
    sample_question_record,
    mock_db_session,
    mock_broadcast_callback
):
    """Test WebSocket broadcasting of GPT-generated answer."""
    gpt_generator._broadcast_callback = mock_broadcast_callback

    gpt_response = {
        "answer": "Infrastructure ROI is typically 18-36 months",
        "confidence": 0.75,
        "sources": "general knowledge",
        "disclaimer": "AI-generated answer"
    }

    with patch('services.intelligence.gpt_answer_generator.get_multi_llm_client') as mock_get_client:
        mock_client = MagicMock()
        mock_client.generate_structured_response = AsyncMock(return_value=gpt_response)
        mock_get_client.return_value = mock_client

        mock_db_session.query.return_value.filter.return_value.first.return_value = sample_question_record

        await gpt_generator.generate_answer(
            session_id="test-session-123",
            question_id=str(sample_question_record.id),
            question_text="What is ROI timeline?",
            speaker="Speaker A",
            meeting_context="Budget discussion",
            db_session=mock_db_session
        )

    # Verify broadcast was called
    mock_broadcast_callback.assert_called_once()
    call_args = mock_broadcast_callback.call_args[0]
    assert call_args[0] == "test-session-123"
    event_data = call_args[1]
    assert event_data["type"] == "GPT_GENERATED_ANSWER"
    assert "answer" in event_data
    assert "confidence" in event_data
    assert "disclaimer" in event_data


@pytest.mark.asyncio
async def test_broadcast_failure_handled_gracefully(
    gpt_generator,
    sample_question_record,
    mock_db_session
):
    """Test that broadcast failures don't crash answer generation."""
    # Mock broadcast callback that raises exception
    failing_callback = AsyncMock(side_effect=Exception("Broadcast failed"))
    gpt_generator._broadcast_callback = failing_callback

    gpt_response = {
        "answer": "Test answer",
        "confidence": 0.75,
        "sources": "general knowledge"
    }

    with patch('services.intelligence.gpt_answer_generator.get_multi_llm_client') as mock_get_client:
        mock_client = MagicMock()
        mock_client.generate_structured_response = AsyncMock(return_value=gpt_response)
        mock_get_client.return_value = mock_client

        mock_db_session.query.return_value.filter.return_value.first.return_value = sample_question_record

        # Should not raise exception despite broadcast failure
        result = await gpt_generator.generate_answer(
            session_id="test-session-123",
            question_id=str(sample_question_record.id),
            question_text="What is the budget?",
            speaker="Speaker A",
            meeting_context="Budget discussion",
            db_session=mock_db_session
        )

    # Answer generation should succeed despite broadcast failure
    assert result is True


# ============================================================================
# Error Handling Tests
# ============================================================================

@pytest.mark.asyncio
async def test_question_not_found_in_database(
    gpt_generator,
    mock_db_session
):
    """Test handling when question is not found in database."""
    # Mock database returning None
    mock_db_session.query.return_value.filter.return_value.first.return_value = None

    result = await gpt_generator.generate_answer(
        session_id="test-session-123",
        question_id=str(uuid.uuid4()),
        question_text="What is the budget?",
        speaker="Speaker A",
        meeting_context="Budget discussion",
        db_session=mock_db_session
    )

    assert result is False


@pytest.mark.asyncio
async def test_database_commit_failure(
    gpt_generator,
    sample_question_record,
    mock_db_session
):
    """Test handling of database commit failures."""
    # Mock successful GPT response
    gpt_response = {
        "answer": "Test answer",
        "confidence": 0.75,
        "sources": "general knowledge"
    }

    # Mock database commit to fail
    mock_db_session.commit.side_effect = Exception("Database error")

    with patch('services.intelligence.gpt_answer_generator.get_multi_llm_client') as mock_get_client:
        mock_client = MagicMock()
        mock_client.generate_structured_response = AsyncMock(return_value=gpt_response)
        mock_get_client.return_value = mock_client

        mock_db_session.query.return_value.filter.return_value.first.return_value = sample_question_record

        result = await gpt_generator.generate_answer(
            session_id="test-session-123",
            question_id=str(sample_question_record.id),
            question_text="What is the budget?",
            speaker="Speaker A",
            meeting_context="Budget discussion",
            db_session=mock_db_session
        )

    # Should return False on database error
    assert result is False
    # Rollback should be called
    mock_db_session.rollback.assert_called()


# ============================================================================
# Prompt Building Tests
# ============================================================================

def test_build_system_prompt(gpt_generator):
    """Test system prompt generation."""
    system_prompt = gpt_generator._build_system_prompt()

    assert isinstance(system_prompt, str)
    assert len(system_prompt) > 0
    assert "general knowledge" in system_prompt.lower()
    assert "confidence" in system_prompt.lower()


def test_build_user_prompt(gpt_generator):
    """Test user prompt generation with context."""
    user_prompt = gpt_generator._build_user_prompt(
        question_text="What is the Q4 budget?",
        speaker="Sarah",
        meeting_context="[10:30] John: We need to finalize the budget..."
    )

    assert isinstance(user_prompt, str)
    assert "What is the Q4 budget?" in user_prompt
    assert "Sarah" in user_prompt
    assert "John: We need to finalize the budget" in user_prompt


def test_build_user_prompt_truncates_long_context(gpt_generator):
    """Test that long meeting context is truncated."""
    long_context = "This is a very long context. " * 200  # ~5000 chars

    user_prompt = gpt_generator._build_user_prompt(
        question_text="What is the budget?",
        speaker="Sarah",
        meeting_context=long_context
    )

    # Should truncate to ~1500 chars
    assert len(user_prompt) < 2000
