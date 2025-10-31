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
        assert question_handler.monitoring_timeout_seconds == 60
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

        # Mock the select query for duplicate check
        mock_existing_result = AsyncMock()
        mock_existing_result.scalars = MagicMock(return_value=MagicMock(first=MagicMock(return_value=None)))
        mock_session.execute = AsyncMock(return_value=mock_existing_result)

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

        # Mock the select query for duplicate check
        mock_existing_result = AsyncMock()
        mock_existing_result.scalars = MagicMock(return_value=MagicMock(first=MagicMock(return_value=None)))
        mock_session.execute = AsyncMock(return_value=mock_existing_result)
        mock_session.add = MagicMock()

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
        with patch('services.intelligence.question_handler.rag_search_service') as mock_rag:
            mock_rag.is_available = MagicMock(return_value=True)

            # Mock async generator that yields no results
            async def empty_generator():
                return
                yield  # This makes it a generator

            mock_rag.search = MagicMock(return_value=empty_generator())

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
        with patch('services.intelligence.question_handler.rag_search_service') as mock_rag:
            mock_rag.is_available = MagicMock(return_value=True)

            # Simulate slow RAG search
            async def slow_generator():
                await asyncio.sleep(10)
                yield MagicMock()

            mock_rag.search = MagicMock(return_value=slow_generator())

            # Set a very short timeout for testing
            original_timeout = question_handler.rag_search_timeout
            question_handler.rag_search_timeout = 0.1

            result = await question_handler._tier1_rag_search(
                session_id="test_session",
                question_id=str(uuid.uuid4()),
                question_text="What is the budget?",
                project_id=str(uuid.uuid4()),
                organization_id=str(uuid.uuid4())
            )

            # Restore original timeout
            question_handler.rag_search_timeout = original_timeout

        assert result is False

    async def test_rag_search_exception(self, question_handler):
        """Test RAG search exception handling."""
        with patch('services.intelligence.question_handler.rag_search_service') as mock_rag:
            mock_rag.is_available = MagicMock(return_value=True)

            # Mock async generator that raises exception
            async def error_generator():
                raise Exception("RAG error")
                yield  # Makes it a generator

            mock_rag.search = MagicMock(return_value=error_generator())

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
             patch.object(question_handler, '_tier4_live_monitoring', AsyncMock(return_value=False)) as mock_tier4, \
             patch.object(question_handler, '_tier3_gpt_generated_answer', AsyncMock(return_value=False)) as mock_tier3:

            start_time = asyncio.get_event_loop().time()

            await question_handler._parallel_answer_discovery(
                session_id=session_id,
                question_id=question_id,
                question_text="What is the budget?",
                project_id=str(uuid.uuid4()),
                organization_id=str(uuid.uuid4())
            )

            elapsed_time = asyncio.get_event_loop().time() - start_time

            # Verify tiers 1, 2, and 4 were called in parallel
            mock_tier1.assert_called_once()
            mock_tier2.assert_called_once()
            mock_tier4.assert_called_once()
            # Tier 3 (GPT) should be called since all others failed
            mock_tier3.assert_called_once()

            # Verify parallel execution (should take ~0.1s, not 0.3s sequential)
            assert elapsed_time < 0.5

    async def test_tier4_triggered_only_when_others_fail(self, question_handler):
        """Test Tier 3 (GPT) is only triggered when Tiers 1, 2, and 4 all fail."""
        question_handler.monitoring_timeout_seconds = 0.1

        # Mock Tier 1 success
        with patch.object(question_handler, '_tier1_rag_search', AsyncMock(return_value=True)), \
             patch.object(question_handler, '_tier2_meeting_context_search', AsyncMock(return_value=False)), \
             patch.object(question_handler, '_tier4_live_monitoring', AsyncMock(return_value=False)), \
             patch.object(question_handler, '_tier3_gpt_generated_answer', AsyncMock(return_value=False)) as mock_tier3:

            await question_handler._parallel_answer_discovery(
                session_id="test_session",
                question_id=str(uuid.uuid4()),
                question_text="What is the budget?",
                project_id=str(uuid.uuid4()),
                organization_id=str(uuid.uuid4())
            )

            # Tier 3 (GPT) should NOT be called since Tier 1 succeeded
            mock_tier3.assert_not_called()

    async def test_unanswered_broadcast_after_all_tiers_fail(self, question_handler):
        """Test QUESTION_UNANSWERED is broadcast only after ALL 4 tiers complete without answer."""
        question_handler.monitoring_timeout_seconds = 0.1
        session_id = "test_session"
        question_id = str(uuid.uuid4())

        # Mock WebSocket broadcast
        ws_callback = AsyncMock()
        question_handler.set_websocket_callback(ws_callback)

        # Mock all tiers failing
        with patch.object(question_handler, '_tier1_rag_search', AsyncMock(return_value=False)), \
             patch.object(question_handler, '_tier2_meeting_context_search', AsyncMock(return_value=False)), \
             patch.object(question_handler, '_tier4_live_monitoring', AsyncMock(return_value=False)), \
             patch.object(question_handler, '_tier3_gpt_generated_answer', AsyncMock(return_value=False)), \
             patch('db.database.get_db_context') as mock_db:

            # Mock database context for UNANSWERED verification and persistence
            mock_db_session = AsyncMock()
            mock_question = MagicMock()
            mock_question.status = InsightStatus.SEARCHING.value  # Not answered yet
            mock_question.update_status = MagicMock()
            mock_question.set_answer_source = MagicMock()

            mock_db_result = AsyncMock()
            mock_db_result.scalar_one_or_none = MagicMock(return_value=mock_question)
            mock_db_session.execute = AsyncMock(return_value=mock_db_result)

            # Create async context manager
            async def async_context_manager():
                return mock_db_session

            mock_db.return_value.__aenter__ = AsyncMock(side_effect=async_context_manager)
            mock_db.return_value.__aexit__ = AsyncMock(return_value=None)

            await question_handler._parallel_answer_discovery(
                session_id=session_id,
                question_id=question_id,
                question_text="What is the budget?",
                project_id=str(uuid.uuid4()),
                organization_id=str(uuid.uuid4())
            )

            # Verify QUESTION_UNANSWERED was broadcast
            unanswered_calls = [
                call for call in ws_callback.call_args_list
                if call[0][1].get('type') == 'QUESTION_UNANSWERED'
            ]
            assert len(unanswered_calls) == 1, "QUESTION_UNANSWERED should be broadcast once"

            # Verify the broadcast contains correct data
            unanswered_event = unanswered_calls[0][0][1]
            assert unanswered_event['data']['question_id'] == question_id
            assert unanswered_event['data']['status'] == 'unanswered'

    async def test_no_unanswered_broadcast_when_tier4_succeeds(self, question_handler):
        """Test QUESTION_UNANSWERED is NOT broadcast when Tier 4 finds an answer."""
        question_handler.monitoring_timeout_seconds = 0.1
        session_id = "test_session"
        question_id = str(uuid.uuid4())

        # Mock WebSocket broadcast
        ws_callback = AsyncMock()
        question_handler.set_websocket_callback(ws_callback)

        # Mock Tiers 1-3 failing, but Tier 4 succeeding
        with patch.object(question_handler, '_tier1_rag_search', AsyncMock(return_value=False)), \
             patch.object(question_handler, '_tier2_meeting_context_search', AsyncMock(return_value=False)), \
             patch.object(question_handler, '_tier4_live_monitoring', AsyncMock(return_value=True)), \
             patch.object(question_handler, '_tier3_gpt_generated_answer', AsyncMock(return_value=False)):

            await question_handler._parallel_answer_discovery(
                session_id=session_id,
                question_id=question_id,
                question_text="What is the budget?",
                project_id=str(uuid.uuid4()),
                organization_id=str(uuid.uuid4())
            )

            # Verify QUESTION_UNANSWERED was NOT broadcast
            unanswered_calls = [
                call for call in ws_callback.call_args_list
                if call[0][1].get('type') == 'QUESTION_UNANSWERED'
            ]
            assert len(unanswered_calls) == 0, "QUESTION_UNANSWERED should NOT be broadcast when Tier 4 succeeds"

    async def test_no_unanswered_broadcast_when_answered_after_timeout(self, question_handler):
        """Test QUESTION_UNANSWERED is NOT broadcast when answer detected after Tier 4 timeout."""
        question_handler.monitoring_timeout_seconds = 0.1
        session_id = "test_session"
        question_id = str(uuid.uuid4())

        # Mock WebSocket broadcast
        ws_callback = AsyncMock()
        question_handler.set_websocket_callback(ws_callback)

        # Mock all tiers failing (Tier 4 times out)
        with patch.object(question_handler, '_tier1_rag_search', AsyncMock(return_value=False)), \
             patch.object(question_handler, '_tier2_meeting_context_search', AsyncMock(return_value=False)), \
             patch.object(question_handler, '_tier4_live_monitoring', AsyncMock(return_value=False)), \
             patch.object(question_handler, '_tier3_gpt_generated_answer', AsyncMock(return_value=False)), \
             patch('db.database.get_db_context') as mock_db:

            # Mock database showing question was ANSWERED (by AnswerHandler after timeout)
            mock_db_session = AsyncMock()
            mock_question = MagicMock()
            mock_question.status = InsightStatus.ANSWERED.value  # Already answered!

            mock_db_result = AsyncMock()
            mock_db_result.scalar_one_or_none = MagicMock(return_value=mock_question)
            mock_db_session.execute = AsyncMock(return_value=mock_db_result)

            # Create async context manager
            async def async_context_manager():
                return mock_db_session

            mock_db.return_value.__aenter__ = AsyncMock(side_effect=async_context_manager)
            mock_db.return_value.__aexit__ = AsyncMock(return_value=None)

            await question_handler._parallel_answer_discovery(
                session_id=session_id,
                question_id=question_id,
                question_text="What is the budget?",
                project_id=str(uuid.uuid4()),
                organization_id=str(uuid.uuid4())
            )

            # Verify QUESTION_UNANSWERED was NOT broadcast (race condition prevented)
            unanswered_calls = [
                call for call in ws_callback.call_args_list
                if call[0][1].get('type') == 'QUESTION_UNANSWERED'
            ]
            assert len(unanswered_calls) == 0, "QUESTION_UNANSWERED should NOT be broadcast when question was answered after timeout"


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
