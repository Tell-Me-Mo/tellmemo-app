"""Monitoring utilities for Langfuse integration across all services."""

import time
import functools
from typing import Any, Callable, Optional, Dict, List
from datetime import datetime

from services.observability.langfuse_service import langfuse_service
from utils.logger import get_logger

logger = get_logger(__name__)


def monitor_operation(
    operation_name: str,
    operation_type: str = "general",
    capture_args: bool = False,
    capture_result: bool = True
):
    """
    Decorator for monitoring async operations with Langfuse context managers.
    
    Args:
        operation_name: Name of the operation for tracking
        operation_type: Type of operation (e.g., "database", "vector", "embedding", "parsing")
        capture_args: Whether to capture function arguments
        capture_result: Whether to capture function result
    """
    def decorator(func: Callable) -> Callable:
        @functools.wraps(func)
        async def wrapper(*args, **kwargs):
            # Check if Langfuse is enabled
            if not langfuse_service.is_enabled:
                return await func(*args, **kwargs)
            
            langfuse_client = langfuse_service.client
            if not langfuse_client or not hasattr(langfuse_client, 'start_as_current_span'):
                # Fallback to original function without monitoring
                return await func(*args, **kwargs)
            
            start_time = time.time()
            
            # Prepare input data for tracking
            input_data = {
                "function": func.__name__,
                "operation_type": operation_type
            }
            
            if capture_args:
                # Safely capture args (avoid large objects)
                input_data["args_count"] = len(args)
                input_data["kwargs_keys"] = list(kwargs.keys())
                
                # Capture specific known safe arguments
                if "project_id" in kwargs:
                    input_data["project_id"] = str(kwargs["project_id"])
                if "content_type" in kwargs:
                    input_data["content_type"] = kwargs["content_type"]
                if "limit" in kwargs:
                    input_data["limit"] = kwargs["limit"]
            
            # Use context manager for monitoring
            with langfuse_client.start_as_current_span(
                name=operation_name,
                input=input_data
            ) as span:
                try:
                    # Execute the function
                    result = await func(*args, **kwargs)
                    
                    # Calculate execution time
                    execution_time = (time.time() - start_time) * 1000
                    
                    # Prepare output data
                    output_data = {
                        "success": True,
                        "execution_time_ms": execution_time
                    }
                    
                    if capture_result and result is not None:
                        # Safely capture result metadata
                        if isinstance(result, (list, tuple)):
                            output_data["result_count"] = len(result)
                        elif isinstance(result, dict):
                            output_data["result_keys"] = list(result.keys())[:10]  # Limit keys
                            if "id" in result:
                                output_data["result_id"] = str(result["id"])
                            if "chunk_count" in result:
                                output_data["chunk_count"] = result["chunk_count"]
                        elif hasattr(result, '__len__'):
                            output_data["result_length"] = len(result)
                    
                    # Update span with output
                    if hasattr(span, 'update'):
                        span.update(output=output_data)
                    
                    # Add performance score
                    if hasattr(span, 'score'):
                        # Score based on execution time
                        if operation_type == "database":
                            threshold = 100  # ms for database ops
                        elif operation_type == "vector":
                            threshold = 500  # ms for vector ops
                        elif operation_type == "embedding":
                            threshold = 200  # ms for embedding ops
                        else:
                            threshold = 1000  # ms for general ops
                        
                        score = max(0.2, min(1.0, threshold / execution_time))
                        span.score(
                            name=f"{operation_type}_performance",
                            value=score,
                            comment=f"Execution time: {execution_time:.2f}ms"
                        )
                    
                    return result
                    
                except Exception as e:
                    # Log error to span
                    if hasattr(span, 'update'):
                        span.update(
                            output={
                                "success": False,
                                "error": str(e),
                                "error_type": type(e).__name__
                            },
                            level="ERROR",
                            status_message=str(e)
                        )
                    raise
        
        return wrapper
    return decorator


def monitor_sync_operation(
    operation_name: str,
    operation_type: str = "general"
):
    """Decorator for monitoring synchronous operations."""
    def decorator(func: Callable) -> Callable:
        @functools.wraps(func)
        def wrapper(*args, **kwargs):
            if not langfuse_service.is_enabled:
                return func(*args, **kwargs)
            
            langfuse_client = langfuse_service.client
            if not langfuse_client or not hasattr(langfuse_client, 'start_as_current_span'):
                return func(*args, **kwargs)
            
            start_time = time.time()
            
            with langfuse_client.start_as_current_span(
                name=operation_name,
                input={"function": func.__name__, "type": operation_type}
            ) as span:
                try:
                    result = func(*args, **kwargs)
                    
                    execution_time = (time.time() - start_time) * 1000
                    
                    if hasattr(span, 'update'):
                        span.update(
                            output={
                                "success": True,
                                "execution_time_ms": execution_time
                            }
                        )
                    
                    return result
                    
                except Exception as e:
                    if hasattr(span, 'update'):
                        span.update(
                            output={"success": False, "error": str(e)},
                            level="ERROR"
                        )
                    raise
        
        return wrapper
    return decorator


class MonitoringContext:
    """Context manager for monitoring code blocks."""

    def __init__(self, name: str, metadata: Optional[Dict[str, Any]] = None):
        self.name = name
        self.metadata = metadata or {}
        self.span = None
        self.span_context = None
        self.start_time = None

    def __enter__(self):
        if not langfuse_service.is_enabled:
            return self

        langfuse_client = langfuse_service.client
        if langfuse_client and hasattr(langfuse_client, 'start_as_current_span'):
            self.start_time = time.time()
            # Store the context manager, not the span
            self.span_context = langfuse_client.start_as_current_span(
                name=self.name,
                input=self.metadata
            )
            # Enter the context and get the span
            self.span = self.span_context.__enter__()

        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        if self.span:
            if exc_type:
                # Error occurred
                if hasattr(self.span, 'update'):
                    self.span.update(
                        output={
                            "success": False,
                            "error": str(exc_val),
                            "error_type": exc_type.__name__
                        },
                        level="ERROR"
                    )
            else:
                # Success
                execution_time = (time.time() - self.start_time) * 1000 if self.start_time else 0
                if hasattr(self.span, 'update'):
                    self.span.update(
                        output={
                            "success": True,
                            "execution_time_ms": execution_time
                        }
                    )

        # Exit using the context manager, not the span
        if self.span_context:
            self.span_context.__exit__(exc_type, exc_val, exc_tb)
    
    def update(self, **kwargs):
        """Update the span with additional data."""
        if self.span and hasattr(self.span, 'update'):
            self.span.update(**kwargs)
    
    def score(self, name: str, value: float, comment: str = None):
        """Add a score to the span."""
        if self.span and hasattr(self.span, 'score'):
            self.span.score(name=name, value=value, comment=comment)


def track_background_task(task_name: str, metadata: Optional[Dict[str, Any]] = None):
    """Decorator for tracking background tasks with Langfuse."""
    def decorator(func: Callable):
        @functools.wraps(func)
        async def wrapper(*args, **kwargs):
            if not langfuse_service.is_enabled:
                return await func(*args, **kwargs)
            
            langfuse_client = langfuse_service.client
            if langfuse_client and hasattr(langfuse_client, 'start_as_current_span'):
                with langfuse_client.start_as_current_span(
                    name=f"background_task_{task_name}",
                    input={
                        "task_name": task_name,
                        "args_count": len(args),
                        "kwargs_keys": list(kwargs.keys()),
                        "metadata": metadata or {}
                    }
                ) as task_span:
                    try:
                        result = await func(*args, **kwargs)
                        
                        if hasattr(task_span, 'update'):
                            task_span.update(
                                output={
                                    "success": True,
                                    "result_type": type(result).__name__ if result else None
                                }
                            )
                        
                        return result
                        
                    except Exception as e:
                        if hasattr(task_span, 'update'):
                            task_span.update(
                                output={
                                    "success": False,
                                    "error": str(e),
                                    "error_type": type(e).__name__
                                },
                                level="ERROR",
                                status_message=str(e)
                            )
                        raise
            else:
                # Fallback without context manager
                return await func(*args, **kwargs)
        
        return wrapper
    return decorator


def track_quality_metrics(
    chunks: List[Dict[str, Any]],
    question: str,
    answer: str,
    sources: List[str]
) -> Dict[str, float]:
    """
    Calculate and track quality metrics for RAG responses.
    
    Returns:
        Dictionary of quality metrics
    """
    metrics = {}
    
    # Calculate chunk relevance
    if chunks:
        avg_score = sum(c.get('score', 0) for c in chunks) / len(chunks)
        metrics['avg_chunk_score'] = avg_score
        metrics['chunk_count'] = len(chunks)
        
        # Score distribution
        high_score_chunks = [c for c in chunks if c.get('score', 0) > 0.7]
        metrics['high_relevance_ratio'] = len(high_score_chunks) / len(chunks)
    else:
        metrics['avg_chunk_score'] = 0
        metrics['chunk_count'] = 0
        metrics['high_relevance_ratio'] = 0
    
    # Answer quality metrics
    metrics['answer_length'] = len(answer)
    metrics['sources_count'] = len(sources)
    
    # Question complexity
    metrics['question_length'] = len(question)
    metrics['question_words'] = len(question.split())
    
    # Calculate confidence score
    confidence = min(0.95, (
        metrics['avg_chunk_score'] * 0.4 +
        metrics['high_relevance_ratio'] * 0.3 +
        min(1.0, metrics['sources_count'] / 3) * 0.3
    ))
    metrics['confidence'] = confidence
    
    # Log metrics to Langfuse if available
    langfuse_client = langfuse_service.client
    if langfuse_client and hasattr(langfuse_client, 'start_as_current_span'):
        try:
            with langfuse_client.start_as_current_span(
                name="response_quality_metrics",
                input={"question": question[:200]}
            ) as span:
                if hasattr(span, 'update'):
                    span.update(output=metrics)
                
                if hasattr(span, 'score'):
                    span.score(
                        name="response_confidence",
                        value=confidence,
                        comment=f"Based on {metrics['chunk_count']} chunks"
                    )
        except Exception as e:
            logger.warning(f"Failed to track quality metrics: {e}")
    
    return metrics


def monitor_batch_operation(
    operation_name: str,
    batch_size: int,
    operation_type: str = "batch"
):
    """Monitor batch processing operations."""
    def decorator(func: Callable) -> Callable:
        @functools.wraps(func)
        async def wrapper(*args, **kwargs):
            if not langfuse_service.is_enabled:
                return await func(*args, **kwargs)
            
            langfuse_client = langfuse_service.client
            if not langfuse_client or not hasattr(langfuse_client, 'start_as_current_span'):
                return await func(*args, **kwargs)
            
            with langfuse_client.start_as_current_span(
                name=operation_name,
                input={
                    "batch_size": batch_size,
                    "operation_type": operation_type
                }
            ) as span:
                start_time = time.time()
                
                try:
                    result = await func(*args, **kwargs)
                    
                    execution_time = (time.time() - start_time) * 1000
                    throughput = (batch_size / execution_time) * 1000  # items per second
                    
                    if hasattr(span, 'update'):
                        span.update(
                            output={
                                "success": True,
                                "execution_time_ms": execution_time,
                                "throughput_per_sec": throughput,
                                "items_processed": batch_size
                            }
                        )
                    
                    if hasattr(span, 'score'):
                        # Score based on throughput
                        expected_throughput = 10  # items per second
                        score = min(1.0, throughput / expected_throughput)
                        span.score(
                            name="batch_throughput",
                            value=score,
                            comment=f"Processed {batch_size} items in {execution_time:.2f}ms"
                        )
                    
                    return result
                    
                except Exception as e:
                    if hasattr(span, 'update'):
                        span.update(
                            output={
                                "success": False,
                                "error": str(e),
                                "items_failed": batch_size
                            },
                            level="ERROR"
                        )
                    raise
        
        return wrapper
    return decorator