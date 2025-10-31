"""
Unit tests for StreamRouter service.

Tests cover:
- Object validation and routing
- Handler registration and invocation
- ID validation and state tracking
- Error handling for malformed objects
- Metrics collection
- State cleanup
"""

import pytest
import uuid
import numpy as np
from datetime import datetime
from typing import Dict, Any, List
from unittest.mock import AsyncMock, patch

from services.intelligence.stream_router import (
    StreamRouter,
    StreamRouterException,
    MalformedObjectException,
    get_stream_router,
    cleanup_stream_router,
)


@pytest.fixture
def session_id() -> str:
    """Generate unique session ID for testing."""
    return f"test_session_{uuid.uuid4()}"


@pytest.fixture
def mock_embedding_service():
    """Mock embedding service to return deterministic embeddings."""
    with patch('services.intelligence.stream_router.embedding_service') as mock:
        # Return unique embeddings for different texts
        async def generate_embedding(text: str, normalize: bool = True):
            # Generate deterministic embedding based on text hash
            np.random.seed(hash(text) % (2**32))
            embedding = np.random.rand(768).tolist()
            if normalize:
                # Normalize to unit vector
                norm = np.linalg.norm(embedding)
                embedding = (np.array(embedding) / norm).tolist()
            return embedding

        mock.generate_embedding = AsyncMock(side_effect=generate_embedding)
        yield mock


@pytest.fixture
def router(session_id: str, mock_embedding_service) -> StreamRouter:
    """Create stream router instance with mocked embedding service."""
    return StreamRouter(session_id)


@pytest.fixture
def sample_question() -> Dict[str, Any]:
    """Sample question object from GPT."""
    return {
        "type": "question",
        "id": f"q_{uuid.uuid4()}",
        "text": "What is the budget for Q4?",
        "speaker": "Sarah",
        "timestamp": "2025-10-26T10:15:30Z",
        "category": "factual",
        "confidence": 0.95
    }


@pytest.fixture
def sample_action() -> Dict[str, Any]:
    """Sample action object from GPT."""
    return {
        "type": "action",
        "id": f"a_{uuid.uuid4()}",
        "description": "Update the budget spreadsheet",
        "owner": "John",
        "deadline": "2025-10-30",
        "speaker": "Sarah",
        "timestamp": "2025-10-26T10:16:00Z",
        "completeness": 1.0,
        "confidence": 0.92
    }


@pytest.fixture
def sample_action_update() -> Dict[str, Any]:
    """Sample action_update object from GPT."""
    return {
        "type": "action_update",
        "id": f"a_{uuid.uuid4()}",
        "owner": "Mike",
        "deadline": "2025-11-05",
        "completeness": 1.0,
        "confidence": 0.88
    }


@pytest.fixture
def sample_answer(sample_question: Dict[str, Any]) -> Dict[str, Any]:
    """Sample answer object from GPT."""
    return {
        "type": "answer",
        "question_id": sample_question["id"],
        "answer_text": "The Q4 budget is $250,000",
        "speaker": "Mike",
        "timestamp": "2025-10-26T10:17:00Z",
        "confidence": 0.90
    }


class TestStreamRouterInitialization:
    """Tests for router initialization."""

    def test_initialization(self, session_id: str):
        """Test router initialization with session ID."""
        router = StreamRouter(session_id)

        assert router.session_id == session_id
        assert len(router.question_ids) == 0
        assert len(router.action_ids) == 0
        assert len(router.question_text_to_id) == 0
        assert len(router.action_text_to_id) == 0
        assert router.metrics.total_objects_processed == 0

    def test_singleton_factory(self, session_id: str):
        """Test get_stream_router factory returns same instance."""
        router1 = get_stream_router(session_id)
        router2 = get_stream_router(session_id)

        assert router1 is router2
        assert router1.session_id == session_id


class TestHandlerRegistration:
    """Tests for handler registration."""

    @pytest.mark.asyncio
    async def test_register_question_handler(self, router: StreamRouter):
        """Test question handler registration."""
        called = []

        async def handler(obj: Dict[str, Any]):
            called.append(obj)

        router.register_question_handler(handler)
        assert router._question_handler is not None

    @pytest.mark.asyncio
    async def test_register_action_handler(self, router: StreamRouter):
        """Test action handler registration."""
        called = []

        async def handler(obj: Dict[str, Any]):
            called.append(obj)

        router.register_action_handler(handler)
        assert router._action_handler is not None

    @pytest.mark.asyncio
    async def test_register_answer_handler(self, router: StreamRouter):
        """Test answer handler registration."""
        called = []

        async def handler(obj: Dict[str, Any]):
            called.append(obj)

        router.register_answer_handler(handler)
        assert router._answer_handler is not None


class TestObjectValidation:
    """Tests for object validation."""

    def test_validate_question_success(self, router: StreamRouter, sample_question: Dict[str, Any]):
        """Test validation of valid question object."""
        # Should not raise
        router._validate_object(sample_question)

    def test_validate_action_success(self, router: StreamRouter, sample_action: Dict[str, Any]):
        """Test validation of valid action object."""
        # Should not raise
        router._validate_object(sample_action)

    def test_validate_answer_success(self, router: StreamRouter, sample_question: Dict[str, Any]):
        """Test validation of valid answer object."""
        # Create answer with question_text instead of question_id
        answer = {
            "type": "answer",
            "question_text": sample_question["text"],  # Use text instead of ID
            "answer_text": "The Q4 budget is $250,000",
            "speaker": "Mike",
            "timestamp": "2025-10-26T10:17:00Z",
            "confidence": 0.90
        }
        # Should not raise
        router._validate_object(answer)

    def test_validate_missing_type_field(self, router: StreamRouter):
        """Test validation fails when 'type' field is missing."""
        obj = {"id": "q_123", "text": "test"}

        with pytest.raises(MalformedObjectException) as exc_info:
            router._validate_object(obj)

        assert "missing required 'type' field" in str(exc_info.value)

    def test_validate_unsupported_type(self, router: StreamRouter):
        """Test validation fails for unsupported type."""
        obj = {"type": "unknown_type", "id": "123"}

        with pytest.raises(MalformedObjectException) as exc_info:
            router._validate_object(obj)

        assert "Unsupported type" in str(exc_info.value)

    def test_validate_question_missing_required_field(self, router: StreamRouter):
        """Test validation fails when question missing required field."""
        obj = {
            "type": "question",
            "id": f"q_{uuid.uuid4()}",
            # Missing 'text' and 'timestamp'
        }

        with pytest.raises(MalformedObjectException) as exc_info:
            router._validate_object(obj)

        assert "missing required field" in str(exc_info.value)

    def test_validate_action_missing_required_field(self, router: StreamRouter):
        """Test validation fails when action missing required field."""
        obj = {
            "type": "action",
            "id": f"a_{uuid.uuid4()}",
            # Missing 'description' and 'timestamp'
        }

        with pytest.raises(MalformedObjectException) as exc_info:
            router._validate_object(obj)

        assert "missing required field" in str(exc_info.value)

    def test_validate_not_dict(self, router: StreamRouter):
        """Test validation fails when object is not a dictionary."""
        obj = "not a dict"

        with pytest.raises(MalformedObjectException) as exc_info:
            router._validate_object(obj)

        assert "must be a dictionary" in str(exc_info.value)


class TestIDValidation:
    """Tests for ID validation."""

    def test_validate_id_valid_uuid_format(self, router: StreamRouter):
        """Test validation of valid UUID format (q_{uuid}, a_{uuid})."""
        valid_ids = [
            f"q_{uuid.uuid4()}",
            f"a_{uuid.uuid4()}",
        ]

        for obj_id in valid_ids:
            # Should not raise
            router._validate_id(obj_id, "test")

    def test_validate_id_invalid_uuid_format(self, router: StreamRouter):
        """Test validation logs warning but doesn't raise for invalid UUID."""
        invalid_ids = [
            "q_not-a-uuid",
            "a_12345",
            "invalid_format",
        ]

        for obj_id in invalid_ids:
            # Should not raise - logs warning but allows processing
            router._validate_id(obj_id, "test")

    def test_validate_id_empty_string(self, router: StreamRouter):
        """Test validation fails for empty ID."""
        with pytest.raises(MalformedObjectException) as exc_info:
            router._validate_id("", "test")

        assert "Invalid ID" in str(exc_info.value)

    def test_validate_id_none(self, router: StreamRouter):
        """Test validation fails for None ID."""
        with pytest.raises(MalformedObjectException) as exc_info:
            router._validate_id(None, "test")

        assert "Invalid ID" in str(exc_info.value)


class TestRouting:
    """Tests for object routing."""

    @pytest.mark.asyncio
    async def test_route_question(self, router: StreamRouter, sample_question: Dict[str, Any]):
        """Test routing question object to handler."""
        called = []

        async def handler(obj: Dict[str, Any]):
            called.append(obj)

        router.register_question_handler(handler)
        await router.route_object(sample_question)

        assert len(called) == 1
        assert called[0] == sample_question
        assert sample_question["id"] in router.question_ids
        assert router.metrics.questions_routed == 1
        assert router.metrics.total_objects_processed == 1

    @pytest.mark.asyncio
    async def test_route_action(self, router: StreamRouter, sample_action: Dict[str, Any]):
        """Test routing action object to handler."""
        called = []

        async def handler(obj: Dict[str, Any]):
            called.append(obj)

        router.register_action_handler(handler)
        await router.route_object(sample_action)

        assert len(called) == 1
        assert called[0] == sample_action
        assert sample_action["id"] in router.action_ids
        assert router.metrics.actions_routed == 1
        assert router.metrics.total_objects_processed == 1

    @pytest.mark.asyncio
    async def test_route_action_update(self, router: StreamRouter, sample_action: Dict[str, Any]):
        """Test routing action_update object to handler."""
        called = []

        async def handler(obj: Dict[str, Any]):
            called.append(obj)

        # First create the action so update can match to it
        router.register_action_handler(handler)
        await router.route_object(sample_action)

        # Reset called list
        called.clear()

        # Now send action_update with matching action_text
        action_update = {
            "type": "action_update",
            "action_text": sample_action["description"],  # Must match original action description
            "owner": "Mike",
            "deadline": "2025-11-05",
            "completeness": 1.0,
            "confidence": 0.88
        }

        router.register_action_update_handler(handler)
        await router.route_object(action_update)

        assert len(called) == 1
        assert called[0]["action_text"] == sample_action["description"]
        assert router.metrics.action_updates_routed == 1

    @pytest.mark.asyncio
    async def test_route_answer(
        self,
        router: StreamRouter,
        sample_question: Dict[str, Any]
    ):
        """Test routing answer object to handler."""
        called = []

        async def handler(obj: Dict[str, Any]):
            called.append(obj)

        # First route question so answer can reference it
        async def dummy_handler(obj: Dict[str, Any]):
            pass

        router.register_question_handler(dummy_handler)
        await router.route_object(sample_question)

        # Create answer with question_text to match
        answer = {
            "type": "answer",
            "question_text": sample_question["text"],  # Match by text, not ID
            "answer_text": "The Q4 budget is $250,000",
            "speaker": "Mike",
            "timestamp": "2025-10-26T10:17:00Z",
            "confidence": 0.90
        }

        # Then route answer
        router.register_answer_handler(handler)
        await router.route_object(answer)

        assert len(called) == 1
        assert called[0]["question_text"] == sample_question["text"]
        assert router.metrics.answers_routed == 1

    @pytest.mark.asyncio
    async def test_route_without_handler_registered(
        self,
        router: StreamRouter,
        sample_question: Dict[str, Any]
    ):
        """Test routing without handler registered logs warning but doesn't fail."""
        # No handler registered
        await router.route_object(sample_question)

        # Should still track state
        assert sample_question["id"] in router.question_ids
        assert router.metrics.questions_routed == 0  # Not routed to handler
        assert router.metrics.total_objects_processed == 1


class TestErrorHandling:
    """Tests for error handling."""

    @pytest.mark.asyncio
    async def test_malformed_object_graceful_handling(self, router: StreamRouter):
        """Test malformed object is handled gracefully without raising."""
        malformed_obj = {"type": "question"}  # Missing required fields

        # Should not raise - logs warning and increments malformed counter
        await router.route_object(malformed_obj)

        assert router.metrics.malformed_objects == 1
        assert router.metrics.total_objects_processed == 0  # Not counted as processed

    @pytest.mark.asyncio
    async def test_handler_exception_propagates(self, router: StreamRouter, sample_question: Dict[str, Any]):
        """Test exception in handler propagates as StreamRouterException."""

        async def failing_handler(obj: Dict[str, Any]):
            raise ValueError("Handler failed")

        router.register_question_handler(failing_handler)

        with pytest.raises(StreamRouterException) as exc_info:
            await router.route_object(sample_question)

        assert "Failed to route object" in str(exc_info.value)
        assert router.metrics.routing_errors == 1


class TestMetrics:
    """Tests for metrics collection."""

    @pytest.mark.asyncio
    async def test_metrics_collection(
        self,
        router: StreamRouter,
        sample_question: Dict[str, Any],
        sample_action: Dict[str, Any]
    ):
        """Test metrics are collected correctly."""
        # Register handlers
        async def dummy_handler(obj: Dict[str, Any]):
            pass

        router.register_question_handler(dummy_handler)
        router.register_action_handler(dummy_handler)

        # Route objects
        await router.route_object(sample_question)
        await router.route_object(sample_action)

        metrics = router.get_metrics()

        assert metrics["total_objects_processed"] == 2
        assert metrics["questions_routed"] == 1
        assert metrics["actions_routed"] == 1
        assert metrics["malformed_objects"] == 0
        assert metrics["routing_errors"] == 0
        assert metrics["average_latency_ms"] > 0

    @pytest.mark.asyncio
    async def test_average_latency_calculation(self, router: StreamRouter, sample_question: Dict[str, Any]):
        """Test average latency is calculated correctly."""
        async def dummy_handler(obj: Dict[str, Any]):
            pass

        router.register_question_handler(dummy_handler)

        await router.route_object(sample_question)
        await router.route_object(sample_question)

        metrics = router.get_metrics()
        assert metrics["average_latency_ms"] > 0
        assert router.metrics.total_objects_processed == 2


class TestStateManagement:
    """Tests for state management."""

    @pytest.mark.asyncio
    async def test_state_tracking(
        self,
        router: StreamRouter,
        sample_question: Dict[str, Any],
        sample_action: Dict[str, Any]
    ):
        """Test question and action text mappings are tracked."""
        async def dummy_handler(obj: Dict[str, Any]):
            pass

        router.register_question_handler(dummy_handler)
        router.register_action_handler(dummy_handler)

        await router.route_object(sample_question)
        await router.route_object(sample_action)

        # Check that text mappings exist
        assert sample_question["text"] in router.question_text_to_id
        assert sample_action["description"] in router.action_text_to_id
        # Check that IDs are tracked
        assert len(router.question_ids) == 1
        assert len(router.action_ids) == 1

    def test_clear_state(self, router: StreamRouter):
        """Test state clearing."""
        # Add some state
        router.question_ids.add("q_123")
        router.action_ids.add("a_456")
        router.question_text_to_id["What is the budget?"] = "q_123"
        router.action_text_to_id["Update the report"] = "a_456"

        router.clear_state()

        assert len(router.question_ids) == 0
        assert len(router.action_ids) == 0
        assert len(router.question_text_to_id) == 0
        assert len(router.action_text_to_id) == 0


class TestCleanup:
    """Tests for router cleanup."""

    def test_cleanup_stream_router(self, session_id: str):
        """Test cleanup removes router instance."""
        router = get_stream_router(session_id)
        router.question_ids.add("q_123")

        cleanup_stream_router(session_id)

        # New instance should be created
        new_router = get_stream_router(session_id)
        assert len(new_router.question_ids) == 0


class TestIntegration:
    """Integration tests with multiple objects."""

    @pytest.mark.asyncio
    async def test_full_conversation_flow(self, router: StreamRouter):
        """Test routing full conversation with question, answer, and action."""
        routed_objects = {
            "questions": [],
            "actions": [],
            "answers": []
        }

        async def question_handler(obj: Dict[str, Any]):
            routed_objects["questions"].append(obj)

        async def action_handler(obj: Dict[str, Any]):
            routed_objects["actions"].append(obj)

        async def answer_handler(obj: Dict[str, Any]):
            routed_objects["answers"].append(obj)

        router.register_question_handler(question_handler)
        router.register_action_handler(action_handler)
        router.register_answer_handler(answer_handler)

        # Question
        question = {
            "type": "question",
            "text": "What's the deadline?",
            "timestamp": "2025-10-26T10:00:00Z"
        }
        await router.route_object(question)

        # Action
        action = {
            "type": "action",
            "description": "Complete the report",
            "timestamp": "2025-10-26T10:01:00Z"
        }
        await router.route_object(action)

        # Answer (must reference question by text)
        answer = {
            "type": "answer",
            "question_text": question["text"],  # Match by text
            "answer_text": "The deadline is Friday",
            "timestamp": "2025-10-26T10:02:00Z"
        }
        await router.route_object(answer)

        assert len(routed_objects["questions"]) == 1
        assert len(routed_objects["actions"]) == 1
        assert len(routed_objects["answers"]) == 1
        assert router.metrics.total_objects_processed == 3
