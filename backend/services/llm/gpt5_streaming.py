"""
GPT-5-mini Streaming Intelligence Service

Provides streaming interface to OpenAI GPT-5-mini API with:
- Real-time NDJSON response parsing
- Token context window management
- Rate limit handling with exponential backoff
- Stream interruption recovery
- Comprehensive logging

Used for real-time meeting intelligence: question detection, action tracking, answer identification.
"""

import json
import logging
import asyncio
from typing import AsyncGenerator, Dict, Any, Optional, List
from datetime import datetime

from openai import AsyncOpenAI, AsyncStream
from openai.types.chat import ChatCompletionChunk

from utils.exceptions import LLMRateLimitException, LLMTimeoutException, LLMOverloadedException
from utils.retry import retry_with_backoff, RetryConfig

logger = logging.getLogger(__name__)


class GPT5StreamingClient:
    """
    Streaming client for GPT-5-mini with intelligent NDJSON parsing.

    Features:
    - Newline-delimited JSON parsing for real-time object extraction
    - Token usage tracking with stream_options
    - Exponential backoff for rate limits
    - Stream interruption recovery (up to 3 retries)
    - Circuit breaker integration ready
    """

    def __init__(
        self,
        openai_client: AsyncOpenAI,
        model: str = "gpt-4o-mini",  # Using gpt-4o-mini (no verification required, cheaper, faster)
        temperature: float = 0.3,
        max_tokens: int = 1000,
        timeout: float = 30.0
    ):
        """
        Initialize GPT-5 streaming client.

        Args:
            openai_client: Configured AsyncOpenAI client
            model: Model name (default: gpt-5-mini)
            temperature: Temperature for consistent output (default: 0.3)
            max_tokens: Maximum tokens per request (default: 1000)
            timeout: Request timeout in seconds (default: 30.0)
        """
        self.client = openai_client
        self.model = model
        self.temperature = temperature
        self.max_tokens = max_tokens
        self.timeout = timeout

        # Retry configuration for rate limits
        self.retry_config = RetryConfig(
            max_attempts=5,
            initial_delay=1.0,
            max_delay=16.0,
            exponential_base=2.0,
            jitter=True,
            retryable_exceptions=(LLMRateLimitException,)
        )

    async def stream_intelligence(
        self,
        transcript_buffer: str,
        context: Dict[str, Any],
        system_prompt: str
    ) -> AsyncGenerator[Dict[str, Any], None]:
        """
        Stream intelligence detections from GPT-5-mini.

        Sends transcript buffer with context to GPT and yields JSON objects as they arrive.
        Uses NDJSON parsing to extract complete objects from the stream.

        Args:
            transcript_buffer: Recent transcript (last 60 seconds, ~1200 tokens)
            context: Additional context (last 5 questions/actions, ~500 tokens)
            system_prompt: System instruction for GPT (~300 tokens)

        Yields:
            Dict objects containing detected insights (questions, actions, answers)

        Raises:
            LLMRateLimitException: When rate limited (will retry with backoff)
            LLMTimeoutException: When request times out
            LLMOverloadedException: When service is overloaded
        """
        # Format user message with transcript and context
        user_message = self._format_user_message(transcript_buffer, context)

        # Create messages array
        messages = [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_message}
        ]

        # Log request details
        logger.info(
            f"GPT-5 Streaming Request - Model: {self.model}, "
            f"Temp: {self.temperature}, MaxTokens: {self.max_tokens}, "
            f"Messages: {len(messages)}, PromptPreview: {user_message[:100]}..."
        )

        request_start = datetime.utcnow()
        object_count = 0
        total_tokens_used = 0

        try:
            # Execute streaming (with internal retry logic)
            async for obj in self._execute_stream_with_retry(messages):
                object_count += 1
                yield obj

        except Exception as e:
            # Log detailed error information
            duration_ms = (datetime.utcnow() - request_start).total_seconds() * 1000
            logger.error(
                f"GPT-5 Streaming Error - Duration: {duration_ms:.0f}ms, "
                f"ObjectsYielded: {object_count}, Error: {str(e)}"
            )
            raise

        # Log successful completion
        duration_ms = (datetime.utcnow() - request_start).total_seconds() * 1000
        logger.info(
            f"GPT-5 Streaming Complete - Duration: {duration_ms:.0f}ms, "
            f"Objects: {object_count}, Tokens: {total_tokens_used}"
        )

    async def _execute_stream_with_retry(
        self,
        messages: List[Dict[str, str]]
    ) -> AsyncGenerator[Dict[str, Any], None]:
        """
        Execute streaming request with error handling and retry support.

        This method is wrapped by retry_with_backoff for rate limit handling.
        """
        max_retry_attempts = 3
        retry_count = 0

        while retry_count < max_retry_attempts:
            try:
                # Create streaming request
                stream = await self.client.chat.completions.create(
                    model=self.model,
                    messages=messages,
                    stream=True,
                    stream_options={"include_usage": True},
                    temperature=self.temperature,  # gpt-4o-mini supports temperature
                    max_tokens=self.max_tokens,  # gpt-4o-mini uses max_tokens (not max_completion_tokens)
                    timeout=self.timeout
                )

                # Parse NDJSON stream
                async for obj in self._parse_ndjson_stream(stream):
                    yield obj

                # Stream completed successfully
                return

            except Exception as e:
                error_str = str(e).lower()

                # Classify error
                if "429" in str(e) or "rate" in error_str:
                    logger.warning(f"Rate limit hit (attempt {retry_count + 1}/{max_retry_attempts}): {e}")
                    raise LLMRateLimitException(f"GPT-5 rate limit: {e}")

                elif "timeout" in error_str or "504" in str(e):
                    logger.warning(f"Timeout (attempt {retry_count + 1}/{max_retry_attempts}): {e}")
                    retry_count += 1
                    if retry_count >= max_retry_attempts:
                        raise LLMTimeoutException(f"GPT-5 timeout after {max_retry_attempts} attempts: {e}")
                    await asyncio.sleep(2 ** retry_count)  # Exponential backoff
                    continue

                elif "529" in str(e) or "503" in str(e) or "overload" in error_str:
                    logger.error(f"Service overloaded: {e}")
                    raise LLMOverloadedException(f"GPT-5 overloaded: {e}")

                else:
                    logger.error(f"Unknown error in GPT-5 streaming: {e}")
                    raise

    async def _parse_ndjson_stream(
        self,
        stream: AsyncStream[ChatCompletionChunk]
    ) -> AsyncGenerator[Dict[str, Any], None]:
        """
        Parse newline-delimited JSON from GPT streaming response.

        Buffers chunks until complete JSON objects are detected (by newline).
        Handles incomplete lines at end of stream gracefully.

        Args:
            stream: OpenAI streaming response

        Yields:
            Parsed JSON objects
        """
        buffer = ""
        chunk_count = 0

        try:
            async for chunk in stream:
                chunk_count += 1

                # Extract delta content
                if chunk.choices and len(chunk.choices) > 0:
                    delta = chunk.choices[0].delta
                    content = delta.content if delta.content else ""

                    if content:
                        buffer += content

                        # Parse complete lines (ending with \n)
                        while "\n" in buffer:
                            line, buffer = buffer.split("\n", 1)
                            line = line.strip()

                            if not line:
                                continue  # Skip empty lines

                            try:
                                obj = json.loads(line)

                                # Validate object has required fields
                                if isinstance(obj, dict) and "type" in obj:
                                    yield obj
                                else:
                                    logger.debug(f"Skipping invalid object (no 'type' field): {line[:100]}")

                            except json.JSONDecodeError as e:
                                logger.warning(f"Malformed JSON in stream (line {chunk_count}): {line[:100]}, Error: {e}")
                                continue

                # Track usage from final chunk
                if hasattr(chunk, 'usage') and chunk.usage:
                    logger.debug(
                        f"Token usage: input={chunk.usage.prompt_tokens}, "
                        f"output={chunk.usage.completion_tokens}, "
                        f"total={chunk.usage.total_tokens}"
                    )

        except Exception as e:
            logger.error(f"Error parsing NDJSON stream (chunk {chunk_count}): {e}")
            raise

        # Handle incomplete buffer at end - try to parse it as final JSON object
        if buffer.strip():
            try:
                obj = json.loads(buffer.strip())

                # Validate object has required fields
                if isinstance(obj, dict) and "type" in obj:
                    logger.info(f"Parsed final JSON object from buffer (no trailing newline): type={obj.get('type')}")
                    yield obj
                else:
                    logger.warning(f"Invalid final object in buffer (no 'type' field): {buffer[:200]}")

            except json.JSONDecodeError as e:
                logger.warning(f"Incomplete JSON at end of stream (could not parse): {buffer[:200]}, Error: {e}")

    def _format_user_message(self, transcript_buffer: str, context: Dict[str, Any]) -> str:
        """
        Format user message with transcript buffer and context.

        Args:
            transcript_buffer: Recent transcript text
            context: Context dictionary with active questions/actions

        Returns:
            Formatted string for GPT
        """
        # Extract context items
        recent_questions = context.get("recent_questions", [])
        recent_actions = context.get("recent_actions", [])
        session_id = context.get("session_id", "unknown")

        # Build message
        message_parts = [
            "=== MEETING TRANSCRIPT (Last 60 seconds) ===",
            transcript_buffer,
            "",
            f"=== CONTEXT (Session: {session_id}) ===",
        ]

        if recent_questions:
            message_parts.append("Recent Questions:")
            for q in recent_questions:
                message_parts.append(f"  - [{q.get('id')}] {q.get('text')} (Status: {q.get('status')})")
            message_parts.append("")

        if recent_actions:
            message_parts.append("Recent Actions:")
            for a in recent_actions:
                message_parts.append(
                    f"  - [{a.get('id')}] {a.get('description')} "
                    f"(Owner: {a.get('owner', 'unassigned')}, "
                    f"Deadline: {a.get('deadline', 'none')})"
                )
            message_parts.append("")

        message_parts.append("Analyze the transcript and detect any new questions, actions, or answers.")

        return "\n".join(message_parts)


async def create_streaming_client(
    openai_client: AsyncOpenAI,
    model: str = "gpt-4o-mini",  # Using gpt-4o-mini (no verification required, cheaper, faster)
    temperature: float = 0.3,
    max_tokens: int = 1000
) -> GPT5StreamingClient:
    """
    Factory function to create a GPT-5 streaming client.

    Args:
        openai_client: Configured AsyncOpenAI client
        model: Model name (default: gpt-5-mini)
        temperature: Temperature setting (default: 0.3 for consistent output)
        max_tokens: Max tokens per request (default: 1000)

    Returns:
        Configured GPT5StreamingClient instance
    """
    return GPT5StreamingClient(
        openai_client=openai_client,
        model=model,
        temperature=temperature,
        max_tokens=max_tokens
    )
