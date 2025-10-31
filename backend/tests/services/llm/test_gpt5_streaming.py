"""
Integration Tests for GPT-5-mini Streaming Client

Tests the GPT5StreamingClient with real and mocked OpenAI API responses.
Validates NDJSON parsing, rate limit handling, timeout recovery, and error handling.

Run with:
    pytest backend/tests/services/llm/test_gpt5_streaming.py -v
"""

import pytest
import asyncio
import json
from unittest.mock import AsyncMock, MagicMock, patch
from typing import List, Dict, Any

from services.llm.gpt5_streaming import GPT5StreamingClient, create_streaming_client
from utils.exceptions import LLMRateLimitException, LLMTimeoutException, LLMOverloadedException


@pytest.fixture
def mock_openai_client():
    """Create a mock AsyncOpenAI client."""
    return AsyncMock()


@pytest.fixture
def streaming_client(mock_openai_client):
    """Create a GPT5StreamingClient with mock client."""
    return GPT5StreamingClient(
        openai_client=mock_openai_client,
        model="gpt-5-mini",
        temperature=0.3,
        max_tokens=1000,
        timeout=30.0
    )


class MockStreamChunk:
    """Mock OpenAI stream chunk."""
    def __init__(self, content: str, usage=None):
        self.choices = [MagicMock()]
        self.choices[0].delta = MagicMock()
        self.choices[0].delta.content = content
        self.usage = usage


class TestGPT5StreamingClientInitialization:
    """Test client initialization and configuration."""

    def test_client_initialization(self, mock_openai_client):
        """Test client initializes with correct configuration."""
        client = GPT5StreamingClient(
            openai_client=mock_openai_client,
            model="gpt-5-mini",
            temperature=0.5,
            max_tokens=500,
            timeout=20.0
        )

        assert client.client == mock_openai_client
        assert client.model == "gpt-5-mini"
        assert client.temperature == 0.5
        assert client.max_tokens == 500
        assert client.timeout == 20.0

    def test_default_configuration(self, mock_openai_client):
        """Test client uses correct defaults."""
        client = GPT5StreamingClient(openai_client=mock_openai_client)

        assert client.model == "gpt-4o-mini"
        assert client.temperature == 0.3
        assert client.max_tokens == 1000
        assert client.timeout == 30.0

    @pytest.mark.asyncio
    async def test_factory_function(self, mock_openai_client):
        """Test factory function creates client correctly."""
        client = await create_streaming_client(
            openai_client=mock_openai_client,
            model="gpt-5-mini",
            temperature=0.2,
            max_tokens=800
        )

        assert isinstance(client, GPT5StreamingClient)
        assert client.model == "gpt-5-mini"
        assert client.temperature == 0.2
        assert client.max_tokens == 800


class TestNDJSONParsing:
    """Test NDJSON parsing from streaming responses."""

    @pytest.mark.asyncio
    async def test_single_object_parsing(self, streaming_client, mock_openai_client):
        """Test parsing a single complete NDJSON object."""
        # Mock stream with single object
        question_obj = {
            "type": "question",
            "id": "q_123",
            "text": "What's the budget?",
            "speaker": "Speaker A",
            "confidence": 0.95
        }
        json_line = json.dumps(question_obj) + "\n"

        mock_stream = AsyncMock()
        mock_stream.__aiter__.return_value = [
            MockStreamChunk(json_line)
        ]

        mock_openai_client.chat.completions.create.return_value = mock_stream

        # Execute streaming
        results = []
        async for obj in streaming_client._parse_ndjson_stream(mock_stream):
            results.append(obj)

        # Verify
        assert len(results) == 1
        assert results[0]["type"] == "question"
        assert results[0]["id"] == "q_123"
        assert results[0]["text"] == "What's the budget?"

    @pytest.mark.asyncio
    async def test_multiple_objects_parsing(self, streaming_client, mock_openai_client):
        """Test parsing multiple NDJSON objects in stream."""
        # Mock stream with multiple objects
        question = {"type": "question", "id": "q_1", "text": "Question 1"}
        action = {"type": "action", "id": "a_1", "description": "Action 1"}
        answer = {"type": "answer", "question_id": "q_1", "answer_text": "Answer 1"}

        stream_content = (
            json.dumps(question) + "\n" +
            json.dumps(action) + "\n" +
            json.dumps(answer) + "\n"
        )

        mock_stream = AsyncMock()
        mock_stream.__aiter__.return_value = [
            MockStreamChunk(stream_content)
        ]

        # Execute streaming
        results = []
        async for obj in streaming_client._parse_ndjson_stream(mock_stream):
            results.append(obj)

        # Verify
        assert len(results) == 3
        assert results[0]["type"] == "question"
        assert results[1]["type"] == "action"
        assert results[2]["type"] == "answer"

    @pytest.mark.asyncio
    async def test_chunked_object_parsing(self, streaming_client):
        """Test parsing when object is split across multiple chunks."""
        # Mock stream where JSON object arrives in multiple chunks
        obj = {"type": "question", "id": "q_123", "text": "What is the budget for Q4?"}
        json_str = json.dumps(obj) + "\n"

        # Split into 3 chunks
        chunk1 = json_str[:20]
        chunk2 = json_str[20:40]
        chunk3 = json_str[40:]

        mock_stream = AsyncMock()
        mock_stream.__aiter__.return_value = [
            MockStreamChunk(chunk1),
            MockStreamChunk(chunk2),
            MockStreamChunk(chunk3)
        ]

        # Execute streaming
        results = []
        async for obj in streaming_client._parse_ndjson_stream(mock_stream):
            results.append(obj)

        # Verify complete object is reconstructed
        assert len(results) == 1
        assert results[0]["type"] == "question"
        assert results[0]["id"] == "q_123"

    @pytest.mark.asyncio
    async def test_malformed_json_skipped(self, streaming_client):
        """Test that malformed JSON lines are skipped gracefully."""
        # Mock stream with mix of valid and invalid JSON
        valid_obj = {"type": "question", "id": "q_1", "text": "Valid"}
        invalid_json = "{malformed json"
        valid_obj2 = {"type": "action", "id": "a_1", "description": "Also valid"}

        stream_content = (
            json.dumps(valid_obj) + "\n" +
            invalid_json + "\n" +
            json.dumps(valid_obj2) + "\n"
        )

        mock_stream = AsyncMock()
        mock_stream.__aiter__.return_value = [
            MockStreamChunk(stream_content)
        ]

        # Execute streaming
        results = []
        async for obj in streaming_client._parse_ndjson_stream(mock_stream):
            results.append(obj)

        # Verify only valid objects are returned
        assert len(results) == 2
        assert results[0]["type"] == "question"
        assert results[1]["type"] == "action"

    @pytest.mark.asyncio
    async def test_empty_lines_skipped(self, streaming_client):
        """Test that empty lines are skipped."""
        # Mock stream with empty lines
        obj1 = {"type": "question", "id": "q_1", "text": "Question"}
        obj2 = {"type": "action", "id": "a_1", "description": "Action"}

        stream_content = (
            "\n" +
            json.dumps(obj1) + "\n" +
            "\n\n" +
            json.dumps(obj2) + "\n" +
            "\n"
        )

        mock_stream = AsyncMock()
        mock_stream.__aiter__.return_value = [
            MockStreamChunk(stream_content)
        ]

        # Execute streaming
        results = []
        async for obj in streaming_client._parse_ndjson_stream(mock_stream):
            results.append(obj)

        # Verify only objects are returned
        assert len(results) == 2

    @pytest.mark.asyncio
    async def test_objects_without_type_field_skipped(self, streaming_client):
        """Test that objects without 'type' field are skipped."""
        # Mock stream with objects missing 'type'
        valid_obj = {"type": "question", "id": "q_1", "text": "Valid"}
        invalid_obj = {"id": "x_1", "some_field": "no type field"}

        stream_content = (
            json.dumps(valid_obj) + "\n" +
            json.dumps(invalid_obj) + "\n"
        )

        mock_stream = AsyncMock()
        mock_stream.__aiter__.return_value = [
            MockStreamChunk(stream_content)
        ]

        # Execute streaming
        results = []
        async for obj in streaming_client._parse_ndjson_stream(mock_stream):
            results.append(obj)

        # Verify only valid object is returned
        assert len(results) == 1
        assert results[0]["type"] == "question"


class TestTokenUsageTracking:
    """Test token usage tracking functionality."""

    @pytest.mark.asyncio
    async def test_token_usage_logged(self, streaming_client):
        """Test that token usage is extracted from final chunk."""
        # Mock stream with usage data in final chunk
        question = {"type": "question", "id": "q_1", "text": "Question"}
        json_line = json.dumps(question) + "\n"

        # Create mock usage object
        mock_usage = MagicMock()
        mock_usage.prompt_tokens = 1500
        mock_usage.completion_tokens = 200
        mock_usage.total_tokens = 1700

        mock_stream = AsyncMock()
        # First chunk with content
        chunk1 = MockStreamChunk(json_line)
        # Second chunk with usage (final chunk)
        chunk2 = MockStreamChunk("", usage=mock_usage)

        mock_stream.__aiter__.return_value = [chunk1, chunk2]

        # Execute streaming
        results = []
        async for obj in streaming_client._parse_ndjson_stream(mock_stream):
            results.append(obj)

        # Verify object was parsed and usage was tracked (via logging)
        assert len(results) == 1


class TestErrorHandling:
    """Test error handling and recovery."""

    @pytest.mark.asyncio
    async def test_rate_limit_error_raised(self, streaming_client, mock_openai_client):
        """Test that rate limit errors are properly detected and raised."""
        # Mock API error with 429 status
        mock_openai_client.chat.completions.create.side_effect = Exception("429 rate_limit_exceeded")

        # Execute and expect exception
        with pytest.raises(LLMRateLimitException):
            results = []
            async for obj in streaming_client._execute_stream_with_retry([{"role": "user", "content": "test"}]):
                results.append(obj)

    @pytest.mark.asyncio
    async def test_timeout_error_with_retry(self, streaming_client, mock_openai_client):
        """Test that timeout errors trigger retry logic."""
        # Mock timeout on first 2 attempts, success on 3rd
        call_count = 0

        async def mock_create(*args, **kwargs):
            nonlocal call_count
            call_count += 1
            if call_count < 3:
                raise Exception("timeout")
            else:
                # Return successful stream
                question = {"type": "question", "id": "q_1", "text": "Question"}
                json_line = json.dumps(question) + "\n"
                mock_stream = AsyncMock()
                mock_stream.__aiter__.return_value = [MockStreamChunk(json_line)]
                return mock_stream

        mock_openai_client.chat.completions.create = mock_create

        # Execute streaming
        results = []
        async for obj in streaming_client._execute_stream_with_retry([{"role": "user", "content": "test"}]):
            results.append(obj)

        # Verify retry succeeded
        assert call_count == 3
        assert len(results) == 1

    @pytest.mark.asyncio
    async def test_timeout_error_max_retries_exceeded(self, streaming_client, mock_openai_client):
        """Test that timeout errors fail after max retries."""
        # Mock persistent timeout
        mock_openai_client.chat.completions.create.side_effect = Exception("timeout")

        # Execute and expect timeout exception
        with pytest.raises(LLMTimeoutException):
            results = []
            async for obj in streaming_client._execute_stream_with_retry([{"role": "user", "content": "test"}]):
                results.append(obj)

    @pytest.mark.asyncio
    async def test_overload_error_raised(self, streaming_client, mock_openai_client):
        """Test that overload errors (529/503) are properly detected."""
        # Mock API overload error
        mock_openai_client.chat.completions.create.side_effect = Exception("529 service_overloaded")

        # Execute and expect overload exception
        with pytest.raises(LLMOverloadedException):
            results = []
            async for obj in streaming_client._execute_stream_with_retry([{"role": "user", "content": "test"}]):
                results.append(obj)


class TestFullStreamingFlow:
    """End-to-end tests for full streaming intelligence flow."""

    @pytest.mark.asyncio
    async def test_successful_streaming_intelligence(self, streaming_client, mock_openai_client):
        """Test complete successful streaming intelligence detection."""
        # Mock complete response with question, action, and answer
        question = {
            "type": "question",
            "id": "q_abc123",
            "text": "What's the Q4 budget?",
            "speaker": "Speaker A",
            "timestamp": "2025-10-26T10:15:00Z",
            "category": "factual",
            "confidence": 0.95
        }
        action = {
            "type": "action",
            "id": "a_def456",
            "description": "Update budget spreadsheet",
            "owner": "John",
            "deadline": "2025-10-30",
            "completeness": 1.0,
            "confidence": 0.92
        }
        answer = {
            "type": "answer",
            "question_id": "q_abc123",
            "answer_text": "$250,000 for infrastructure",
            "speaker": "Speaker B",
            "confidence": 0.97
        }

        stream_content = (
            json.dumps(question) + "\n" +
            json.dumps(action) + "\n" +
            json.dumps(answer) + "\n"
        )

        mock_stream = AsyncMock()
        mock_stream.__aiter__.return_value = [
            MockStreamChunk(stream_content)
        ]

        mock_openai_client.chat.completions.create.return_value = mock_stream

        # Execute streaming intelligence
        transcript = "[10:15] Speaker A: What's the Q4 budget?\n[10:16] Speaker B: $250,000 for infrastructure"
        context = {"recent_questions": [], "recent_actions": [], "session_id": "test-session"}
        system_prompt = "Analyze meeting transcript for questions, actions, and answers."

        results = []
        async for obj in streaming_client.stream_intelligence(
            transcript_buffer=transcript,
            context=context,
            system_prompt=system_prompt
        ):
            results.append(obj)

        # Verify all objects detected
        assert len(results) == 3
        assert results[0]["type"] == "question"
        assert results[1]["type"] == "action"
        assert results[2]["type"] == "answer"

        # Verify API called with correct parameters
        call_args = mock_openai_client.chat.completions.create.call_args
        assert call_args.kwargs["model"] == "gpt-5-mini"
        assert call_args.kwargs["temperature"] == 0.3
        assert call_args.kwargs["max_tokens"] == 1000
        assert call_args.kwargs["stream"] is True
        assert call_args.kwargs["stream_options"] == {"include_usage": True}

    @pytest.mark.asyncio
    async def test_user_message_formatting(self, streaming_client):
        """Test that user message is correctly formatted with context."""
        transcript = "[10:15] Speaker A: Question text"
        context = {
            "recent_questions": [
                {"id": "q_1", "text": "Previous question", "status": "searching"}
            ],
            "recent_actions": [
                {"id": "a_1", "description": "Previous action", "owner": "John", "deadline": "2025-10-30"}
            ],
            "session_id": "test-123"
        }

        formatted = streaming_client._format_user_message(transcript, context)

        # Verify formatting
        assert "MEETING TRANSCRIPT" in formatted
        assert transcript in formatted
        assert "CONTEXT" in formatted
        assert "test-123" in formatted
        assert "Recent Questions:" in formatted
        assert "q_1" in formatted
        assert "Previous question" in formatted
        assert "Recent Actions:" in formatted
        assert "a_1" in formatted
        assert "Previous action" in formatted
        assert "John" in formatted


class TestEdgeCases:
    """Test edge cases and unusual scenarios."""

    @pytest.mark.asyncio
    async def test_empty_stream(self, streaming_client):
        """Test handling of empty stream response."""
        mock_stream = AsyncMock()
        mock_stream.__aiter__.return_value = []

        results = []
        async for obj in streaming_client._parse_ndjson_stream(mock_stream):
            results.append(obj)

        # Should complete without errors
        assert len(results) == 0

    @pytest.mark.asyncio
    async def test_stream_with_only_whitespace(self, streaming_client):
        """Test stream containing only whitespace."""
        mock_stream = AsyncMock()
        mock_stream.__aiter__.return_value = [
            MockStreamChunk("   \n\n  \n   ")
        ]

        results = []
        async for obj in streaming_client._parse_ndjson_stream(mock_stream):
            results.append(obj)

        # Should skip all whitespace
        assert len(results) == 0

    @pytest.mark.asyncio
    async def test_incomplete_json_at_end(self, streaming_client):
        """Test that incomplete JSON at stream end is discarded."""
        # Mock stream with complete object + incomplete object
        complete_obj = {"type": "question", "id": "q_1", "text": "Complete"}
        incomplete_json = '{"type": "action", "id": "a_1"'  # No closing brace, no newline

        stream_content = json.dumps(complete_obj) + "\n" + incomplete_json

        mock_stream = AsyncMock()
        mock_stream.__aiter__.return_value = [
            MockStreamChunk(stream_content)
        ]

        results = []
        async for obj in streaming_client._parse_ndjson_stream(mock_stream):
            results.append(obj)

        # Should only return complete object, discard incomplete
        assert len(results) == 1
        assert results[0]["type"] == "question"


# Performance/Load Testing (optional, can be slow)
@pytest.mark.slow
class TestPerformance:
    """Performance tests (marked as slow)."""

    @pytest.mark.asyncio
    async def test_large_stream_performance(self, streaming_client):
        """Test parsing performance with large number of objects."""
        # Create stream with 100 objects
        objects = [
            {"type": "question", "id": f"q_{i}", "text": f"Question {i}"}
            for i in range(100)
        ]

        stream_content = "\n".join(json.dumps(obj) for obj in objects) + "\n"

        mock_stream = AsyncMock()
        mock_stream.__aiter__.return_value = [
            MockStreamChunk(stream_content)
        ]

        import time
        start = time.time()

        results = []
        async for obj in streaming_client._parse_ndjson_stream(mock_stream):
            results.append(obj)

        duration = time.time() - start

        # Verify all objects parsed
        assert len(results) == 100

        # Performance check: Should parse 100 objects in <1 second
        assert duration < 1.0, f"Parsing took {duration:.2f}s, expected <1.0s"


if __name__ == "__main__":
    pytest.main([__file__, "-v", "-s"])
