"""
Unified Logging System for PM Master V2

Provides both simple and structured logging capabilities with backward compatibility.
Supports correlation IDs, performance metrics, audit trails, and JSON output.
"""

import json
import logging
import sys
import time
import traceback
import uuid
from datetime import datetime
from typing import Any, Dict, Optional, Union
from functools import wraps
from contextlib import contextmanager
from enum import Enum

# Lazy import to avoid circular dependencies
_settings = None

def _get_settings():
    global _settings
    if _settings is None:
        from config import get_settings
        _settings = get_settings()
    return _settings


class LogLevel(str, Enum):
    """Log levels with semantic meaning."""
    DEBUG = "DEBUG"
    INFO = "INFO"
    WARNING = "WARNING"
    ERROR = "ERROR"
    CRITICAL = "CRITICAL"
    AUDIT = "AUDIT"
    METRIC = "METRIC"


class LogComponent(str, Enum):
    """System components for categorization."""
    API = "api"
    SERVICE = "service"
    LLM = "llm"
    DATABASE = "database"
    CACHE = "cache"
    QUEUE = "queue"
    WEBSOCKET = "websocket"
    SCHEDULER = "scheduler"


class StructuredLogger(logging.LoggerAdapter):
    """Enhanced logger with structured output and correlation tracking."""

    def __init__(self, name: str, extra: Optional[Dict] = None):
        logger = logging.getLogger(name)
        super().__init__(logger, extra or {})
        self.logger_name = name  # Use different attribute name to avoid conflict
        self._context = {}

    def _create_log_entry(
        self,
        level: str,
        message: str,
        component: Optional[str] = None,
        correlation_id: Optional[str] = None,
        metadata: Optional[Dict[str, Any]] = None,
        error: Optional[Exception] = None,
        duration_ms: Optional[float] = None,
        **kwargs
    ) -> Dict[str, Any]:
        """Create a structured log entry."""
        settings = _get_settings()

        # Try to get request context from current request
        request_context = {}
        try:
            from fastapi import Request
            import contextvars
            # Get current request if available
            request_var = contextvars.ContextVar('request', default=None)
            request = request_var.get()
            if request and hasattr(request, 'state'):
                if hasattr(request.state, 'user'):
                    request_context['user_id'] = str(request.state.user.id)
                    request_context['user_email'] = request.state.user.email
                if hasattr(request.state, 'organization'):
                    request_context['organization_id'] = str(request.state.organization.id)
                    request_context['organization_name'] = request.state.organization.name
                if hasattr(request.state, 'user_role'):
                    request_context['user_role'] = request.state.user_role
                if hasattr(request.state, 'request_id'):
                    correlation_id = correlation_id or request.state.request_id
        except Exception:
            pass  # Silently ignore if context not available

        entry = {
            "timestamp": datetime.utcnow().isoformat(),
            "level": level,
            "logger": self.logger_name,
            "message": message,
            "correlation_id": correlation_id or self._context.get("correlation_id"),
            "environment": settings.api_env if settings else "unknown",
        }

        if component:
            entry["component"] = component

        if duration_ms is not None:
            entry["duration_ms"] = round(duration_ms, 2)

        if error:
            entry["error"] = {
                "type": type(error).__name__,
                "message": str(error),
                "stack_trace": traceback.format_exc() if settings and settings.is_development else None
            }

        if metadata:
            entry["metadata"] = self._sanitize_metadata(metadata)

        # Add any additional kwargs
        entry.update(kwargs)

        # Add context if available
        if self._context:
            entry["context"] = self._context

        # Add request context (organization, user, etc.)
        if request_context:
            entry["request_context"] = request_context

        return entry

    def _sanitize_metadata(self, metadata: Dict[str, Any]) -> Dict[str, Any]:
        """Sanitize sensitive data from metadata."""
        settings = _get_settings()
        if settings and settings.is_development:
            return metadata

        # List of keys that might contain sensitive data
        sensitive_keys = ["password", "token", "api_key", "secret", "authorization"]

        sanitized = {}
        for key, value in metadata.items():
            if any(sensitive in key.lower() for sensitive in sensitive_keys):
                sanitized[key] = "***REDACTED***"
            elif isinstance(value, dict):
                sanitized[key] = self._sanitize_metadata(value)
            else:
                sanitized[key] = value

        return sanitized

    def _log_structured(self, level: str, message: str, **kwargs):
        """Internal structured logging method."""
        entry = self._create_log_entry(level, message, **kwargs)

        settings = _get_settings()
        if settings and settings.is_development:
            # Pretty print for development
            self.logger.log(
                getattr(logging, level, logging.INFO),
                json.dumps(entry, indent=2, default=str)
            )
        else:
            # Single line for production
            self.logger.log(
                getattr(logging, level, logging.INFO),
                json.dumps(entry, default=str)
            )

    def debug(self, message: str, **kwargs):
        """Log debug message."""
        if kwargs.get('structured', False):
            kwargs.pop('structured')
            self._log_structured(LogLevel.DEBUG, message, **kwargs)
        else:
            self.logger.debug(message)

    def info(self, message: str, **kwargs):
        """Log info message."""
        if kwargs.get('structured', False):
            kwargs.pop('structured')
            self._log_structured(LogLevel.INFO, message, **kwargs)
        else:
            self.logger.info(message)

    def warning(self, message: str, **kwargs):
        """Log warning message."""
        if kwargs.get('structured', False):
            kwargs.pop('structured')
            self._log_structured(LogLevel.WARNING, message, **kwargs)
        else:
            self.logger.warning(message)

    def error(self, message: str, error: Optional[Exception] = None, **kwargs):
        """Log error message with optional exception."""
        if kwargs.get('structured', False):
            kwargs.pop('structured')
            self._log_structured(LogLevel.ERROR, message, error=error, **kwargs)
        else:
            if error:
                self.logger.error(f"{message}: {error}", exc_info=True)
            else:
                self.logger.error(message)

    def critical(self, message: str, error: Optional[Exception] = None, **kwargs):
        """Log critical message."""
        if kwargs.get('structured', False):
            kwargs.pop('structured')
            self._log_structured(LogLevel.CRITICAL, message, error=error, **kwargs)
        else:
            if error:
                self.logger.critical(f"{message}: {error}", exc_info=True)
            else:
                self.logger.critical(message)

    def audit(self, action: str, user_id: str, **kwargs):
        """Log audit trail entry."""
        self._log_structured(
            LogLevel.AUDIT,
            f"Audit: {action}",
            user_id=user_id,
            action=action,
            **kwargs
        )

    def metric(self, metric_name: str, value: float, unit: str = "ms", **kwargs):
        """Log performance metric."""
        self._log_structured(
            LogLevel.METRIC,
            f"Metric: {metric_name}",
            metric_name=metric_name,
            value=value,
            unit=unit,
            **kwargs
        )

    @contextmanager
    def context(self, **context_data):
        """Context manager for adding contextual data to logs."""
        old_context = self._context.copy()
        self._context.update(context_data)
        try:
            yield self
        finally:
            self._context = old_context

    @contextmanager
    def timer(self, operation: str, **kwargs):
        """Context manager for timing operations."""
        start_time = time.time()
        self.info(f"Starting {operation}", structured=True, operation=operation, **kwargs)

        try:
            yield
        finally:
            duration_ms = (time.time() - start_time) * 1000
            self.info(
                f"Completed {operation}",
                structured=True,
                operation=operation,
                duration_ms=duration_ms,
                **kwargs
            )
            self.metric(f"{operation}_duration", duration_ms, unit="ms", **kwargs)


class SummaryGenerationLogger(StructuredLogger):
    """Specialized logger for summary generation with additional methods."""

    def log_generation_start(
        self,
        entity_type: str,
        entity_id: str,
        summary_type: str,
        format_type: str,
        correlation_id: Optional[str] = None
    ):
        """Log the start of summary generation."""
        self.info(
            "Summary generation started",
            structured=True,
            component=LogComponent.SERVICE,
            correlation_id=correlation_id or str(uuid.uuid4()),
            entity_type=entity_type,
            entity_id=entity_id,
            summary_type=summary_type,
            format_type=format_type
        )

    def log_generation_complete(
        self,
        entity_type: str,
        entity_id: str,
        summary_id: str,
        duration_ms: float,
        token_count: int,
        cost_usd: float,
        correlation_id: Optional[str] = None
    ):
        """Log successful summary generation."""
        self.info(
            "Summary generation completed",
            structured=True,
            component=LogComponent.SERVICE,
            correlation_id=correlation_id,
            entity_type=entity_type,
            entity_id=entity_id,
            summary_id=summary_id,
            duration_ms=duration_ms,
            token_count=token_count,
            cost_usd=cost_usd
        )

        # Also log as metric
        self.metric(
            f"summary_generation_{entity_type}",
            duration_ms,
            entity_type=entity_type,
            tokens=token_count,
            cost=cost_usd
        )

    def log_llm_request(
        self,
        model: str,
        prompt_tokens: int,
        max_tokens: int,
        temperature: float,
        correlation_id: Optional[str] = None
    ):
        """Log LLM API request."""
        self.info(
            "LLM request initiated",
            structured=True,
            component=LogComponent.LLM,
            correlation_id=correlation_id,
            model=model,
            prompt_tokens=prompt_tokens,
            max_tokens=max_tokens,
            temperature=temperature
        )

    def log_llm_response(
        self,
        model: str,
        completion_tokens: int,
        total_tokens: int,
        response_time_ms: float,
        cost_usd: float,
        correlation_id: Optional[str] = None
    ):
        """Log LLM API response."""
        self.info(
            "LLM response received",
            structured=True,
            component=LogComponent.LLM,
            correlation_id=correlation_id,
            model=model,
            completion_tokens=completion_tokens,
            total_tokens=total_tokens,
            response_time_ms=response_time_ms,
            cost_usd=cost_usd
        )

    def log_aggregation_stats(
        self,
        entity_type: str,
        entity_id: str,
        projects_count: int,
        content_items: int,
        total_tokens: int,
        correlation_id: Optional[str] = None
    ):
        """Log data aggregation statistics."""
        self.info(
            "Data aggregation completed",
            structured=True,
            component=LogComponent.SERVICE,
            correlation_id=correlation_id,
            entity_type=entity_type,
            entity_id=entity_id,
            projects_count=projects_count,
            content_items=content_items,
            total_tokens=total_tokens
        )

    def log_cache_operation(
        self,
        operation: str,
        cache_key: str,
        hit: bool,
        correlation_id: Optional[str] = None
    ):
        """Log cache operations."""
        self.debug(
            f"Cache {operation}",
            structured=True,
            component=LogComponent.CACHE,
            correlation_id=correlation_id,
            operation=operation,
            cache_key=cache_key,
            cache_hit=hit
        )

    def log_database_operation(
        self,
        operation: str,
        table: str,
        duration_ms: float,
        rows_affected: int = 0,
        correlation_id: Optional[str] = None
    ):
        """Log database operations."""
        self.debug(
            f"Database {operation}",
            structured=True,
            component=LogComponent.DATABASE,
            correlation_id=correlation_id,
            operation=operation,
            table=table,
            duration_ms=duration_ms,
            rows_affected=rows_affected
        )


def log_execution_time(logger: StructuredLogger, operation_name: str):
    """Decorator to log function execution time."""
    def decorator(func):
        @wraps(func)
        async def async_wrapper(*args, **kwargs):
            with logger.timer(operation_name):
                return await func(*args, **kwargs)

        @wraps(func)
        def sync_wrapper(*args, **kwargs):
            with logger.timer(operation_name):
                return func(*args, **kwargs)

        # Return appropriate wrapper based on function type
        import asyncio
        if asyncio.iscoroutinefunction(func):
            return async_wrapper
        return sync_wrapper

    return decorator


def get_correlation_id() -> str:
    """Generate a new correlation ID."""
    return str(uuid.uuid4())


# Cache for logger instances
_logger_cache = {}


def get_logger(name: Optional[str] = None, structured: bool = False) -> Union[logging.Logger, StructuredLogger]:
    """Get a logger instance.

    Args:
        name: Logger name. If None, uses the calling module's __name__.
        structured: If True, returns a StructuredLogger for JSON output.
                   If False, returns a standard Python logger (default for backward compatibility).

    Returns:
        Either a standard Python logger or a StructuredLogger based on the structured parameter.

    The logger will use the root logger's configuration set by configure_logging().
    This avoids duplicate handlers and duplicate log messages.
    """
    logger_name = name or __name__

    # Use cache to avoid creating multiple instances
    cache_key = f"{logger_name}_{structured}"
    if cache_key in _logger_cache:
        return _logger_cache[cache_key]

    if structured:
        logger = StructuredLogger(logger_name)
    else:
        logger = logging.getLogger(logger_name)

    _logger_cache[cache_key] = logger
    return logger


# Create singleton instances for common use cases
def _create_singleton_loggers():
    """Create singleton logger instances."""
    return {
        'summary': SummaryGenerationLogger("summary_generation"),
        'api': StructuredLogger("api"),
        'service': StructuredLogger("service"),
        'db': StructuredLogger("database")
    }

# Initialize singleton loggers
_singletons = _create_singleton_loggers()

# Export commonly used loggers
summary_logger = _singletons['summary']
api_logger = _singletons['api']
service_logger = _singletons['service']
db_logger = _singletons['db']

# Maintain backward compatibility
structured_logger = summary_logger  # Alias for existing code


__all__ = [
    # Main function
    'get_logger',

    # Classes
    'StructuredLogger',
    'SummaryGenerationLogger',

    # Enums
    'LogLevel',
    'LogComponent',

    # Utilities
    'log_execution_time',
    'get_correlation_id',

    # Singleton instances
    'summary_logger',
    'api_logger',
    'service_logger',
    'db_logger',
    'structured_logger',  # Backward compatibility
]