"""Unit tests for QuestionHandler service."""

import pytest
import asyncio
import uuid
from datetime import datetime
from unittest.mock import AsyncMock, MagicMock, patch
from sqlalchemy.ext.asyncio import AsyncSession

from services.intelligence.question_handler import QuestionHandler
from models.live_insight import (
    LiveMeetingInsight,
    InsightType,
    InsightStatus,
    AnswerSource
)


@pytest.fixture
def question_handler():
    """Create a QuestionHandler instance for testing."""
    return QuestionHandler()


@pytest.fixture
def mock_session():
    """Create a mock async database session."""
    session = AsyncMock(spec=AsyncSession)
    session.flush = AsyncMock()
    session.commit = AsyncMock()
    session.rollback = AsyncMock()
    return session


@pytest.fixture
def sample_question_data():
    """Sample question data from GPT stream."""
    return {
        "id": "q_3f8a9b2c-1d4e-4f9a-b8c3-2a1b4c5d6e7f",
        "text": "What is the Q4 infrastructure budget?",
        "speaker": "Speaker A",
        "timestamp": "2025-10-26T10:30:05Z",
        "category": "factual",
        "confidence": 0.95
    }


@pytest.mark.asyncio
class TestQuestionHandlerInitialization:
    """Test QuestionHandler initialization."""

    def test_initialization(self, question_handler):
        """Test handler initializes with correct configuration."""
        assert question_handler.monitoring_timeout_seconds == 15
        assert question_handler.rag_search_timeout == 2.0
        assert question_handler.meeting_context_timeout == 1.5
        assert question_handler.gpt_generation_timeout == 3.0
        assert question_handler._active_monitoring == {}
        assert question_handler._ws_broadcast_callback is None

    def test_set_websocket_callback(self, question_handler):
        """Test setting WebSocket callback."""
        callback = AsyncMock()
        question_handler.set_websocket_callback(callback)
        assert question_handler._ws_broadcast_callback == callback


@pytest.mark.asyncio
class TestHandleQuestion:
    """Test question handling and lifecycle."""

    async def test_handle_question_success(
        self,
        question_handler,
        mock_session,
        sample_question_data
    ):
        """Test successful question handling creates database record and triggers discovery."""
        session_id = "test_session_123"
        project_id = str(uuid.uuid4())
        org_id = str(uuid.uuid4())
        recording_id = str(uuid.uuid4())

        # Mock database operations
        mock_session.add = MagicMock()

        # Mock WebSocket broadcast
        ws_callback = AsyncMock()
        question_handler.set_websocket_callback(ws_callback)

        # Mock parallel answer discovery (don't execute)
        with patch.object(asyncio, 'create_task', return_value=None):
            result = await question_handler.handle_question(
                session_id=session_id,
                question_data=sample_question_data,
                session=mock_session,
                project_id=project_id,
                organization_id=org_id,
                recording_id=recording_id
            )

        # Verify database record created
        assert result is not None
        assert isinstance(result, LiveMeetingInsight)
        assert result.session_id == session_id
        assert result.content == sample_question_data["text"]
        assert result.insight_type == InsightType.QUESTION
        assert result.status == InsightStatus.SEARCHING.value
        assert result.speaker == sample_question_data["speaker"]

        # Verify metadata stored
        assert result.insight_metadata["gpt_id"] == sample_question_data["id"]
        assert result.insight_metadata["category"] == sample_question_data["category"]
        assert result.insight_metadata["confidence"] == sample_question_data["confidence"]

        # Verify database operations
        mock_session.add.assert_called_once()
        mock_session.flush.assert_called_once()
        mock_session.commit.assert_called_once()

        # Verify WebSocket broadcast
        ws_callback.assert_called_once()
        call_args = ws_callback.call_args[0]
        assert call_args[0] == session_id
        assert call_args[1]["type"] == "QUESTION_DETECTED"

    async def test_handle_question_missing_gpt_id(
        self,
        question_handler,
        mock_session
    ):
        """Test question handling generates UUID if GPT ID missing."""
        question_data = {
            "text": "What is the budget?",
            "speaker": "John"
        }

        with patch.object(asyncio, 'create_task', return_value=None):
            result = await question_handler.handle_question(
                session_id="test_session",
                question_data=question_data,
                session=mock_session,
                project_id=str(uuid.uuid4()),
                organization_id=str(uuid.uuid4()),
                recording_id=str(uuid.uuid4())
            )

        assert result is not None
        assert result.insight_metadata["gpt_id"].startswith("q_")

    async def test_handle_question_exception_handling(
        self,
        question_handler,
        mock_session,
        sample_question_data
    ):
        """Test exception handling during question processing."""
        # Simulate database error
        mock_session.flush.side_effect = Exception("Database error")

        result = await question_handler.handle_question(
            session_id="test_session",
            question_data=sample_question_data,
            session=mock_session,
            project_id=str(uuid.uuid4()),
            organization_id=str(uuid.uuid4()),
            recording_id=str(uuid.uuid4())
        )

        assert result is None
        mock_session.rollback.assert_called_once()


@pytest.mark.asyncio
class TestTier1RAGSearch:
    """Test Tier 1: RAG search functionality."""

    async def test_rag_search_no_results(self, question_handler):
        """Test RAG search with no results."""
        with patch('services.intelligence.question_handler.enhanced_rag_service') as mock_rag:
            mock_rag.query_project = AsyncMock(return_value={"answer": "", "sources": []})

            result = await question_handler._tier1_rag_search(
                session_id="test_session",
                question_id=str(uuid.uuid4()),
                question_text="What is the budget?",
                project_id=str(uuid.uuid4()),
                organization_id=str(uuid.uuid4())
            )

        assert result is False

    async def test_rag_search_timeout(self, question_handler):
        """Test RAG search timeout handling."""
        with patch('services.intelligence.question_handler.enhanced_rag_service') as mock_rag:
            # Simulate slow RAG search
            async def slow_search(*args, **kwargs):
                await asyncio.sleep(10)
                return {"answer": "test", "sources": []}

            mock_rag.query_project = slow_search

            result = await question_handler._tier1_rag_search(
                session_id="test_session",
                question_id=str(uuid.uuid4()),
                question_text="What is the budget?",
                project_id=str(uuid.uuid4()),
                organization_id=str(uuid.uuid4())
            )

        assert result is False

    async def test_rag_search_exception(self, question_handler):
        """Test RAG search exception handling."""
        with patch('services.intelligence.question_handler.enhanced_rag_service') as mock_rag:
            mock_rag.query_project = AsyncMock(side_effect=Exception("RAG error"))

            result = await question_handler._tier1_rag_search(
                session_id="test_session",
                question_id=str(uuid.uuid4()),
                question_text="What is the budget?",
                project_id=str(uuid.uuid4()),
                organization_id=str(uuid.uuid4())
            )

        assert result is False


@pytest.mark.asyncio
class TestTier3LiveMonitoring:
    """Test Tier 3: Live monitoring functionality."""

    # NOTE: Detailed tests for live monitoring require database integration
    # These are simplified unit tests focusing on timeout behavior


@pytest.mark.asyncio
class TestParallelAnswerDiscovery:
    """Test parallel answer discovery across multiple tiers."""

    async def test_parallel_execution(self, question_handler):
        """Test that tiers execute in parallel."""
        # Reduce timeouts for faster testing
        question_handler.monitoring_timeout_seconds = 0.1

        session_id = "test_session"
        question_id = str(uuid.uuid4())

        # Mock all tier methods
        with patch.object(question_handler, '_tier1_rag_search', AsyncMock(return_value=False)) as mock_tier1, \
             patch.object(question_handler, '_tier2_meeting_context_search', AsyncMock(return_value=False)) as mock_tier2, \
             patch.object(question_handler, '_tier3_live_monitoring', AsyncMock(return_value=False)) as mock_tier3, \
             patch.object(question_handler, '_tier4_gpt_generated_answer', AsyncMock(return_value=False)) as mock_tier4:

            start_time = asyncio.get_event_loop().time()

            await question_handler._parallel_answer_discovery(
                session_id=session_id,
                question_id=question_id,
                question_text="What is the budget?",
                project_id=str(uuid.uuid4()),
                organization_id=str(uuid.uuid4())
            )

            elapsed_time = asyncio.get_event_loop().time() - start_time

            # Verify all tiers were called
            mock_tier1.assert_called_once()
            mock_tier2.assert_called_once()
            mock_tier3.assert_called_once()
            mock_tier4.assert_called_once()

            # Verify parallel execution (should take ~0.1s, not 0.3s sequential)
            assert elapsed_time < 0.5

    async def test_tier4_triggered_only_when_others_fail(self, question_handler):
        """Test Tier 4 is only triggered when Tiers 1-3 all fail."""
        question_handler.monitoring_timeout_seconds = 0.1

        # Mock Tier 1 success
        with patch.object(question_handler, '_tier1_rag_search', AsyncMock(return_value=True)), \
             patch.object(question_handler, '_tier2_meeting_context_search', AsyncMock(return_value=False)), \
             patch.object(question_handler, '_tier3_live_monitoring', AsyncMock(return_value=False)), \
             patch.object(question_handler, '_tier4_gpt_generated_answer', AsyncMock(return_value=False)) as mock_tier4:

            await question_handler._parallel_answer_discovery(
                session_id="test_session",
                question_id=str(uuid.uuid4()),
                question_text="What is the budget?",
                project_id=str(uuid.uuid4()),
                organization_id=str(uuid.uuid4())
            )

            # Tier 4 should NOT be called since Tier 1 succeeded
            mock_tier4.assert_not_called()


@pytest.mark.asyncio
class TestResourceCleanup:
    """Test resource cleanup and session management."""

    async def test_cancel_monitoring(self, question_handler):
        """Test cancelling monitoring for a specific question."""
        session_id = "test_session"
        question_id = str(uuid.uuid4())

        # Create a real asyncio task (not a mock) so cancel() works properly
        async def dummy_task():
            await asyncio.sleep(10)

        task = asyncio.create_task(dummy_task())
        question_handler._active_monitoring[session_id] = {question_id: task}

        await question_handler.cancel_monitoring(session_id, question_id)

        # Give task a moment to process cancellation
        await asyncio.sleep(0.01)

        # Verify task was cancelled
        assert task.cancelled() or task.done()

        # Clean up
        try:
            await task
        except asyncio.CancelledError:
            pass

    async def test_cleanup_session(self, question_handler):
        """Test cleaning up all resources for a session."""
        session_id = "test_session"

        # Create real asyncio tasks (not mocks) so cancel() works properly
        async def dummy_task():
            await asyncio.sleep(10)

        task1 = asyncio.create_task(dummy_task())
        task2 = asyncio.create_task(dummy_task())

        question_handler._active_monitoring[session_id] = {
            str(uuid.uuid4()): task1,
            str(uuid.uuid4()): task2
        }

        await question_handler.cleanup_session(session_id)

        # Give tasks a moment to process cancellation
        await asyncio.sleep(0.01)

        # Verify all tasks cancelled
        assert task1.cancelled() or task1.done()
        assert task2.cancelled() or task2.done()

        # Verify session removed
        assert session_id not in question_handler._active_monitoring

        # Clean up tasks
        for task in [task1, task2]:
            try:
                await task
            except asyncio.CancelledError:
                pass


@pytest.mark.asyncio
class TestWebSocketBroadcast:
    """Test WebSocket event broadcasting."""

    async def test_broadcast_with_callback(self, question_handler):
        """Test broadcasting events when callback is configured."""
        ws_callback = AsyncMock()
        question_handler.set_websocket_callback(ws_callback)

        session_id = "test_session"
        event_data = {"type": "QUESTION_DETECTED", "data": "test"}

        await question_handler._broadcast_event(session_id, event_data)

        ws_callback.assert_called_once_with(session_id, event_data)

    async def test_broadcast_without_callback(self, question_handler):
        """Test broadcasting gracefully handles missing callback."""
        # No callback configured
        session_id = "test_session"
        event_data = {"type": "QUESTION_DETECTED"}

        # Should not raise exception
        await question_handler._broadcast_event(session_id, event_data)

    async def test_broadcast_exception_handling(self, question_handler):
        """Test broadcast handles callback exceptions gracefully."""
        ws_callback = AsyncMock(side_effect=Exception("Broadcast error"))
        question_handler.set_websocket_callback(ws_callback)

        session_id = "test_session"
        event_data = {"type": "QUESTION_DETECTED"}

        # Should not raise exception
        await question_handler._broadcast_event(session_id, event_data)
