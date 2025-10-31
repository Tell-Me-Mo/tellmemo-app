"""
Unit tests for StreamingIntelligenceOrchestrator

Tests cover:
- Orchestrator initialization
- Transcription chunk processing
- Handler registration and coordination
- WebSocket broadcasting integration
- Metrics tracking
- Health status monitoring
- Cleanup operations
- Error handling

Author: TellMeMo Team
Date: 2025-10-26
"""

import pytest
import asyncio
from datetime import datetime
from unittest.mock import AsyncMock, MagicMock, patch, call
from uuid import uuid4

from services.intelligence.streaming_orchestrator import (
    StreamingIntelligenceOrchestrator,
    get_orchestrator,
    cleanup_orchestrator,
    get_orchestrator_metrics,
    get_orchestrator_health,
    StreamingIntelligenceException
)


@pytest.fixture
def session_id():
    """Generate test session ID."""
    return str(uuid4())


@pytest.fixture
def recording_id():
    """Generate test recording ID."""
    return uuid4()


@pytest.fixture
async def orchestrator(session_id, recording_id):
    """Create orchestrator instance for testing."""
    orch = StreamingIntelligenceOrchestrator(
        session_id=session_id,
        recording_id=recording_id
    )
    yield orch
    # Cleanup after test
    await orch.cleanup()


class TestOrchestratorInitialization:
    """Test orchestrator initialization and setup."""

    def test_orchestrator_creation(self, session_id, recording_id):
        """Test basic orchestrator creation."""
        orch = StreamingIntelligenceOrchestrator(
            session_id=session_id,
            recording_id=recording_id
        )

        assert orch.session_id == session_id
        assert orch.recording_id == recording_id
        assert orch.metrics.total_chunks_processed == 0
        assert orch.buffer_service is not None
        assert orch.stream_router is not None
        assert orch.question_handler is not None
        assert orch.action_handler is not None
        assert orch.answer_handler is not None

    def test_handler_registration(self, orchestrator):
        """Test that handlers are registered with router."""
        router = orchestrator.stream_router

        # Verify handlers are registered
        assert router._question_handler is not None
        assert router._action_handler is not None
        assert router._action_update_handler is not None
        assert router._answer_handler is not None

    def test_cross_handler_dependencies(self, orchestrator):
        """Test that cross-handler dependencies are set."""
        # AnswerHandler should have QuestionHandler reference
        assert orchestrator.answer_handler._question_handler is not None


class TestTranscriptionProcessing:
    """Test transcription chunk processing."""

    @pytest.mark.asyncio
    async def test_process_final_transcription(self, orchestrator):
        """Test processing a final transcription chunk."""
        with patch.object(orchestrator.buffer_service, 'add_sentence', new_callable=AsyncMock) as mock_add:
            with patch.object(orchestrator.buffer_service, 'get_formatted_context', new_callable=AsyncMock) as mock_context:
                with patch.object(orchestrator, '_stream_gpt_intelligence', new_callable=AsyncMock) as mock_stream:
                    mock_context.return_value = "Speaker A: Hello world"

                    result = await orchestrator.process_transcription_chunk(
                        text="Hello world",
                        speaker="Speaker A",
                        timestamp=datetime.utcnow(),
                        is_final=True
                    )

                    assert result["status"] == "success"
                    assert "latency_ms" in result
                    assert orchestrator.metrics.total_chunks_processed == 1

                    # Verify buffer service calls
                    mock_add.assert_called_once()
                    mock_context.assert_called_once()
                    mock_stream.assert_called_once()

    @pytest.mark.asyncio
    async def test_skip_partial_transcription(self, orchestrator):
        """Test that partial transcriptions are skipped."""
        result = await orchestrator.process_transcription_chunk(
            text="Hello",
            speaker="Speaker A",
            is_final=False
        )

        assert result["status"] == "skipped"
        assert result["reason"] == "partial_transcript"
        assert orchestrator.metrics.total_chunks_processed == 0

    @pytest.mark.asyncio
    async def test_skip_empty_context(self, orchestrator):
        """Test handling of empty transcript context."""
        with patch.object(orchestrator.buffer_service, 'add_sentence', new_callable=AsyncMock):
            with patch.object(orchestrator.buffer_service, 'get_formatted_context', new_callable=AsyncMock) as mock_context:
                mock_context.return_value = ""

                result = await orchestrator.process_transcription_chunk(
                    text="Test",
                    is_final=True
                )

                assert result["status"] == "skipped"
                assert result["reason"] == "empty_context"

    @pytest.mark.asyncio
    async def test_processing_error_handling(self, orchestrator):
        """Test error handling during transcription processing."""
        with patch.object(orchestrator.buffer_service, 'add_sentence', new_callable=AsyncMock) as mock_add:
            mock_add.side_effect = Exception("Buffer error")

            with pytest.raises(StreamingIntelligenceException):
                await orchestrator.process_transcription_chunk(
                    text="Test",
                    is_final=True
                )

            assert orchestrator.metrics.errors == 1


class TestGPTStreaming:
    """Test GPT streaming intelligence integration."""

    @pytest.mark.asyncio
    async def test_gpt_streaming_questions(self, orchestrator, session_id):
        """Test GPT streaming with question detection."""
        mock_session = AsyncMock()

        # Mock GPT client to yield question object
        mock_gpt_client = AsyncMock()
        async def mock_stream(*args, **kwargs):
            yield {
                "type": "question",
                "id": "q_test123",
                "text": "What is the budget?",
                "speaker": "Speaker A",
                "confidence": 0.95
            }

        mock_gpt_client.stream_intelligence = mock_stream
        orchestrator._gpt_client = mock_gpt_client

        with patch.object(orchestrator, '_build_context', new_callable=AsyncMock) as mock_context:
            with patch.object(orchestrator.stream_router, 'route_object', new_callable=AsyncMock) as mock_route:
                mock_context.return_value = {}

                await orchestrator._stream_gpt_intelligence(
                    transcript_context="Speaker A: What is the budget?",
                    session=mock_session
                )

                assert orchestrator.metrics.questions_detected == 1
                assert orchestrator.metrics.objects_routed == 1
                mock_route.assert_called_once()

    @pytest.mark.asyncio
    async def test_gpt_streaming_actions(self, orchestrator, session_id):
        """Test GPT streaming with action detection."""
        mock_session = AsyncMock()

        # Mock GPT client to yield action object
        mock_gpt_client = AsyncMock()
        async def mock_stream(*args, **kwargs):
            yield {
                "type": "action",
                "id": "a_test456",
                "description": "Update spreadsheet",
                "owner": "John",
                "deadline": "2025-10-30",
                "confidence": 0.92
            }

        mock_gpt_client.stream_intelligence = mock_stream
        orchestrator._gpt_client = mock_gpt_client

        with patch.object(orchestrator, '_build_context', new_callable=AsyncMock) as mock_context:
            with patch.object(orchestrator.stream_router, 'route_object', new_callable=AsyncMock):
                mock_context.return_value = {}

                await orchestrator._stream_gpt_intelligence(
                    transcript_context="John will update the spreadsheet by Friday",
                    session=mock_session
                )

                assert orchestrator.metrics.actions_detected == 1

    @pytest.mark.asyncio
    async def test_gpt_streaming_answers(self, orchestrator):
        """Test GPT streaming with answer detection."""
        mock_session = AsyncMock()

        # Mock GPT client to yield answer object
        mock_gpt_client = AsyncMock()
        async def mock_stream(*args, **kwargs):
            yield {
                "type": "answer",
                "question_id": "q_test123",
                "answer_text": "The budget is $250,000",
                "speaker": "Speaker B",
                "confidence": 0.90
            }

        mock_gpt_client.stream_intelligence = mock_stream
        orchestrator._gpt_client = mock_gpt_client

        with patch.object(orchestrator, '_build_context', new_callable=AsyncMock) as mock_context:
            with patch.object(orchestrator.stream_router, 'route_object', new_callable=AsyncMock):
                mock_context.return_value = {}

                await orchestrator._stream_gpt_intelligence(
                    transcript_context="Speaker B: The budget is $250,000",
                    session=mock_session
                )

                assert orchestrator.metrics.answers_detected == 1


class TestContextBuilding:
    """Test context building for GPT prompts."""

    @pytest.mark.asyncio
    async def test_build_context_with_redis(self, orchestrator):
        """Test context building with Redis data."""
        import json

        mock_redis = AsyncMock()
        mock_redis.get = AsyncMock(side_effect=[
            json.dumps([{"id": "q1", "text": "Question 1"}]),  # questions
            json.dumps([{"id": "a1", "description": "Action 1"}])  # actions
        ])

        orchestrator._redis_client = mock_redis

        context = await orchestrator._build_context()

        assert context["session_id"] == orchestrator.session_id
        assert len(context["active_questions"]) == 1
        assert len(context["active_actions"]) == 1
        assert orchestrator.metrics.redis_operations == 1

    @pytest.mark.asyncio
    async def test_build_context_without_redis(self, orchestrator):
        """Test context building when Redis is unavailable."""
        with patch.object(orchestrator, '_get_redis', new_callable=AsyncMock) as mock_redis:
            mock_redis.return_value = None

            context = await orchestrator._build_context()

            assert context["session_id"] == orchestrator.session_id
            assert context["active_questions"] == []
            assert context["active_actions"] == []


class TestMetricsAndHealth:
    """Test metrics and health status."""

    @pytest.mark.asyncio
    async def test_get_metrics(self, orchestrator):
        """Test getting orchestrator metrics."""
        orchestrator.metrics.total_chunks_processed = 10
        orchestrator.metrics.questions_detected = 3
        orchestrator.metrics.actions_detected = 2

        metrics = await orchestrator.get_metrics()

        assert metrics["session_id"] == orchestrator.session_id
        assert metrics["orchestrator"]["chunks_processed"] == 10
        assert metrics["orchestrator"]["questions_detected"] == 3
        assert metrics["orchestrator"]["actions_detected"] == 2
        assert "handlers" in metrics

    @pytest.mark.asyncio
    async def test_get_health_status_healthy(self, orchestrator):
        """Test health status when all components are healthy."""
        mock_redis = AsyncMock()
        orchestrator._redis_client = mock_redis
        orchestrator._gpt_client = AsyncMock()

        with patch.object(orchestrator, '_get_redis', new_callable=AsyncMock) as mock_get_redis:
            mock_get_redis.return_value = mock_redis

            health = await orchestrator.get_health_status()

            assert health["status"] == "healthy"
            assert health["components"]["redis"]["status"] == "connected"
            assert health["components"]["gpt_client"]["status"] == "initialized"

    @pytest.mark.asyncio
    async def test_get_health_status_degraded(self, orchestrator):
        """Test health status when Redis is disconnected."""
        with patch.object(orchestrator, '_get_redis', new_callable=AsyncMock) as mock_redis:
            mock_redis.return_value = None

            health = await orchestrator.get_health_status()

            assert health["status"] == "degraded"
            assert health["components"]["redis"]["status"] == "disconnected"


class TestCleanup:
    """Test cleanup operations."""

    @pytest.mark.asyncio
    async def test_cleanup_all_resources(self, orchestrator):
        """Test cleanup of all orchestrator resources."""
        mock_redis = AsyncMock()
        orchestrator._redis_client = mock_redis

        with patch.object(orchestrator.question_handler, 'cleanup_session', new_callable=AsyncMock) as mock_q:
            with patch.object(orchestrator.action_handler, 'cleanup_session', new_callable=AsyncMock) as mock_a:
                with patch.object(orchestrator.answer_handler, 'cleanup_session', new_callable=AsyncMock) as mock_ans:
                    await orchestrator.cleanup()

                    # Verify all handlers cleaned up
                    mock_q.assert_called_once_with(orchestrator.session_id)
                    mock_a.assert_called_once_with(orchestrator.session_id)
                    mock_ans.assert_called_once_with(orchestrator.session_id)

                    # Verify Redis closed
                    mock_redis.aclose.assert_called_once()


class TestSingletonManagement:
    """Test singleton orchestrator instance management."""

    @pytest.mark.asyncio
    async def test_get_orchestrator_creates_instance(self, session_id, recording_id):
        """Test that get_orchestrator creates new instance."""
        orch = get_orchestrator(session_id, recording_id)

        assert orch is not None
        assert orch.session_id == session_id
        assert orch.recording_id == recording_id

        # Cleanup
        await cleanup_orchestrator(session_id)

    @pytest.mark.asyncio
    async def test_get_orchestrator_returns_same_instance(self, session_id):
        """Test that get_orchestrator returns same instance for same session."""
        orch1 = get_orchestrator(session_id)
        orch2 = get_orchestrator(session_id)

        assert orch1 is orch2

        # Cleanup
        await cleanup_orchestrator(session_id)

    @pytest.mark.asyncio
    async def test_cleanup_orchestrator_removes_instance(self, session_id):
        """Test that cleanup removes orchestrator instance."""
        get_orchestrator(session_id)
        await cleanup_orchestrator(session_id)

        # Getting again should create new instance
        orch_new = get_orchestrator(session_id)
        assert orch_new is not None

        # Cleanup
        await cleanup_orchestrator(session_id)

    @pytest.mark.asyncio
    async def test_get_metrics_for_session(self, session_id):
        """Test getting metrics for specific session."""
        orch = get_orchestrator(session_id)
        orch.metrics.total_chunks_processed = 5

        metrics = await get_orchestrator_metrics(session_id)

        assert metrics is not None
        assert metrics["orchestrator"]["chunks_processed"] == 5

        # Cleanup
        await cleanup_orchestrator(session_id)

    @pytest.mark.asyncio
    async def test_get_health_for_session(self, session_id):
        """Test getting health status for specific session."""
        get_orchestrator(session_id)

        health = await get_orchestrator_health(session_id)

        assert health is not None
        assert "status" in health

        # Cleanup
        await cleanup_orchestrator(session_id)

    @pytest.mark.asyncio
    async def test_metrics_returns_none_for_unknown_session(self):
        """Test that metrics returns None for unknown session."""
        metrics = await get_orchestrator_metrics("unknown_session")
        assert metrics is None

    @pytest.mark.asyncio
    async def test_health_returns_none_for_unknown_session(self):
        """Test that health returns None for unknown session."""
        health = await get_orchestrator_health("unknown_session")
        assert health is None


class TestIntegration:
    """Integration tests for full orchestrator workflow."""

    @pytest.mark.asyncio
    async def test_full_processing_workflow(self, session_id):
        """Test complete transcription processing workflow."""
        orch = get_orchestrator(session_id)

        # Mock all dependencies
        with patch.object(orch.buffer_service, 'add_sentence', new_callable=AsyncMock):
            with patch.object(orch.buffer_service, 'get_formatted_context', new_callable=AsyncMock) as mock_context:
                with patch.object(orch, '_stream_gpt_intelligence', new_callable=AsyncMock):
                    mock_context.return_value = "Speaker A: Test transcript"

                    # Process multiple chunks
                    for i in range(5):
                        result = await orch.process_transcription_chunk(
                            text=f"Chunk {i}",
                            speaker="Speaker A",
                            is_final=True
                        )
                        assert result["status"] == "success"

                    # Verify metrics
                    metrics = await orch.get_metrics()
                    assert metrics["orchestrator"]["chunks_processed"] == 5

        # Cleanup
        await cleanup_orchestrator(session_id)
