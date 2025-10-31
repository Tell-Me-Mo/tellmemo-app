"""
Custom Instrumentation Decorators

Provides decorators for tracing critical application operations:
- LLM calls (with provider, model, tokens tracking)
- RAG queries (with retrieval metrics)
- Embedding generation (with model and dimension tracking)
- General async/sync operations
"""

import functools
import time
from typing import Any, Callable, Optional
from opentelemetry import trace
from opentelemetry.trace import Status, StatusCode

tracer = trace.get_tracer(__name__)


def trace_async(span_name: Optional[str] = None, attributes: Optional[dict] = None):
    """
    Decorator for tracing async functions.

    Usage:
        @trace_async("my_operation")
        async def my_function():
            ...

        @trace_async(attributes={"user_id": "123"})
        async def my_function():
            ...
    """
    def decorator(func: Callable) -> Callable:
        _span_name = span_name or f"{func.__module__}.{func.__name__}"

        @functools.wraps(func)
        async def wrapper(*args, **kwargs):
            with tracer.start_as_current_span(_span_name) as span:
                # Add custom attributes
                if attributes:
                    for key, value in attributes.items():
                        span.set_attribute(key, value)

                # Add function metadata
                span.set_attribute("function.name", func.__name__)
                span.set_attribute("function.module", func.__module__)

                try:
                    result = await func(*args, **kwargs)
                    span.set_status(Status(StatusCode.OK))
                    return result
                except Exception as e:
                    span.set_status(Status(StatusCode.ERROR, str(e)))
                    span.record_exception(e)
                    raise

        return wrapper
    return decorator


def trace_sync(span_name: Optional[str] = None, attributes: Optional[dict] = None):
    """
    Decorator for tracing synchronous functions.

    Usage:
        @trace_sync("my_operation")
        def my_function():
            ...
    """
    def decorator(func: Callable) -> Callable:
        _span_name = span_name or f"{func.__module__}.{func.__name__}"

        @functools.wraps(func)
        def wrapper(*args, **kwargs):
            with tracer.start_as_current_span(_span_name) as span:
                # Add custom attributes
                if attributes:
                    for key, value in attributes.items():
                        span.set_attribute(key, value)

                # Add function metadata
                span.set_attribute("function.name", func.__name__)
                span.set_attribute("function.module", func.__module__)

                try:
                    result = func(*args, **kwargs)
                    span.set_status(Status(StatusCode.OK))
                    return result
                except Exception as e:
                    span.set_status(Status(StatusCode.ERROR, str(e)))
                    span.record_exception(e)
                    raise

        return wrapper
    return decorator


def track_llm_call(provider: Optional[str] = None, model: Optional[str] = None):
    """
    Decorator for tracking LLM API calls with detailed metrics.

    Captures:
    - Provider (claude, openai, deepseek)
    - Model name
    - Prompt tokens
    - Completion tokens
    - Total tokens
    - Latency
    - Cost (if available)
    - Success/failure status

    Usage:
        @track_llm_call(provider="claude", model="haiku")
        async def call_claude(prompt: str):
            ...

    Expected return value structure (for metrics extraction):
        {
            "content": "response text",
            "usage": {
                "prompt_tokens": 100,
                "completion_tokens": 50,
                "total_tokens": 150
            },
            "model": "claude-3-5-haiku-latest",
            "provider": "claude"
        }
    """
    def decorator(func: Callable) -> Callable:
        @functools.wraps(func)
        async def wrapper(*args, **kwargs):
            start_time = time.time()

            with tracer.start_as_current_span("llm.call") as span:
                # Set provider and model attributes
                if provider:
                    span.set_attribute("llm.provider", provider)
                if model:
                    span.set_attribute("llm.model", model)

                span.set_attribute("llm.function", func.__name__)

                try:
                    result = await func(*args, **kwargs)
                    latency = time.time() - start_time

                    # Extract metrics from result
                    if isinstance(result, dict):
                        # Extract token usage
                        if "usage" in result:
                            usage = result["usage"]
                            span.set_attribute("llm.usage.prompt_tokens", usage.get("prompt_tokens", 0))
                            span.set_attribute("llm.usage.completion_tokens", usage.get("completion_tokens", 0))
                            span.set_attribute("llm.usage.total_tokens", usage.get("total_tokens", 0))

                        # Extract actual model and provider used (may differ from requested)
                        if "model" in result:
                            span.set_attribute("llm.response.model", result["model"])
                        if "provider" in result:
                            span.set_attribute("llm.response.provider", result["provider"])

                    # Set latency
                    span.set_attribute("llm.latency_seconds", latency)
                    span.set_status(Status(StatusCode.OK))

                    return result

                except Exception as e:
                    latency = time.time() - start_time
                    span.set_attribute("llm.latency_seconds", latency)
                    span.set_attribute("llm.error", str(e))
                    span.set_status(Status(StatusCode.ERROR, str(e)))
                    span.record_exception(e)
                    raise

        return wrapper
    return decorator


def track_rag_query():
    """
    Decorator for tracking RAG query operations.

    Captures:
    - Query text length
    - Number of chunks retrieved
    - Retrieval time
    - Context size
    - Success/failure status

    Usage:
        @track_rag_query()
        async def query_rag(query: str, project_id: str):
            ...

    Expected return value structure:
        {
            "answer": "response text",
            "sources": [...],
            "chunks_retrieved": 5,
            "context_size": 2048,
            "retrieval_time_ms": 150
        }
    """
    def decorator(func: Callable) -> Callable:
        @functools.wraps(func)
        async def wrapper(*args, **kwargs):
            start_time = time.time()

            with tracer.start_as_current_span("rag.query") as span:
                span.set_attribute("rag.function", func.__name__)

                # Try to extract query text from arguments
                if args and len(args) > 0 and isinstance(args[0], str):
                    query_text = args[0]
                    span.set_attribute("rag.query_length", len(query_text))
                elif "query" in kwargs:
                    query_text = kwargs["query"]
                    span.set_attribute("rag.query_length", len(query_text))

                # Try to extract project_id
                if "project_id" in kwargs:
                    span.set_attribute("rag.project_id", str(kwargs["project_id"]))

                try:
                    result = await func(*args, **kwargs)
                    latency = time.time() - start_time

                    # Extract metrics from result
                    if isinstance(result, dict):
                        if "chunks_retrieved" in result:
                            span.set_attribute("rag.chunks_retrieved", result["chunks_retrieved"])
                        if "context_size" in result:
                            span.set_attribute("rag.context_size", result["context_size"])
                        if "sources" in result and isinstance(result["sources"], list):
                            span.set_attribute("rag.sources_count", len(result["sources"]))

                    span.set_attribute("rag.latency_seconds", latency)
                    span.set_status(Status(StatusCode.OK))

                    return result

                except Exception as e:
                    latency = time.time() - start_time
                    span.set_attribute("rag.latency_seconds", latency)
                    span.set_attribute("rag.error", str(e))
                    span.set_status(Status(StatusCode.ERROR, str(e)))
                    span.record_exception(e)
                    raise

        return wrapper
    return decorator


def track_embedding_generation(model: Optional[str] = None):
    """
    Decorator for tracking embedding generation operations.

    Captures:
    - Model name
    - Number of texts embedded
    - Embedding dimension
    - Generation time
    - Success/failure status

    Usage:
        @track_embedding_generation(model="google/embeddinggemma-300m")
        async def generate_embeddings(texts: List[str]):
            ...

    Expected return value: List[List[float]] or numpy array
    """
    def decorator(func: Callable) -> Callable:
        @functools.wraps(func)
        async def wrapper(*args, **kwargs):
            start_time = time.time()

            with tracer.start_as_current_span("embedding.generate") as span:
                if model:
                    span.set_attribute("embedding.model", model)

                span.set_attribute("embedding.function", func.__name__)

                # Try to extract text count from arguments
                if args and len(args) > 0:
                    texts = args[0]
                    if isinstance(texts, list):
                        span.set_attribute("embedding.text_count", len(texts))
                elif "texts" in kwargs:
                    texts = kwargs["texts"]
                    if isinstance(texts, list):
                        span.set_attribute("embedding.text_count", len(texts))

                try:
                    result = await func(*args, **kwargs)
                    latency = time.time() - start_time

                    # Extract embedding dimension
                    if result is not None:
                        if hasattr(result, 'shape'):  # numpy array
                            span.set_attribute("embedding.dimension", result.shape[-1])
                        elif isinstance(result, list) and len(result) > 0:
                            if isinstance(result[0], list):
                                span.set_attribute("embedding.dimension", len(result[0]))

                    span.set_attribute("embedding.latency_seconds", latency)
                    span.set_status(Status(StatusCode.OK))

                    return result

                except Exception as e:
                    latency = time.time() - start_time
                    span.set_attribute("embedding.latency_seconds", latency)
                    span.set_attribute("embedding.error", str(e))
                    span.set_status(Status(StatusCode.ERROR, str(e)))
                    span.record_exception(e)
                    raise

        return wrapper
    return decorator
