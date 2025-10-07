"""
Langfuse observability service for LLM monitoring and cost tracking.
"""
import os
from typing import Optional, Dict, Any, List
from contextlib import contextmanager
import logging
from datetime import datetime

from langfuse import Langfuse

from config import get_settings

settings = get_settings()

logger = logging.getLogger(__name__)


class NoOpContextManager:
    """No-op context manager that does nothing when Langfuse is disabled."""

    def __init__(self, *args, **kwargs):
        pass

    def __enter__(self):
        return self

    def __exit__(self, *args):
        pass

    def update(self, **kwargs):
        """No-op update method."""
        pass

    def end(self):
        """No-op end method."""
        pass


class NoOpClient:
    """No-op client that mimics Langfuse client interface when disabled."""

    def start_as_current_span(self, *args, **kwargs):
        """Return a no-op context manager."""
        return NoOpContextManager(*args, **kwargs)

    def start_span(self, *args, **kwargs):
        """Return a no-op span."""
        return NoOpContextManager(*args, **kwargs)

    def start_generation(self, *args, **kwargs):
        """Return a no-op generation."""
        return NoOpContextManager(*args, **kwargs)

    def create_event(self, *args, **kwargs):
        """Return None for events."""
        return None

    def create_score(self, *args, **kwargs):
        """Return None for scores."""
        return None

    def flush(self):
        """No-op flush."""
        pass

    def shutdown(self):
        """No-op shutdown."""
        pass


class LangfuseService:
    """Service for LLM observability and monitoring using Langfuse."""
    
    _instance: Optional['LangfuseService'] = None
    _client: Optional[Langfuse] = None
    
    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
        return cls._instance
    
    def __init__(self):
        """Initialize Langfuse service."""
        if not hasattr(self, 'initialized'):
            self.initialized = False
            self._is_enabled = False
            self._initialize_client()
    
    def _initialize_client(self):
        """Initialize Langfuse client with configuration."""
        try:
            # Check if we're in testing mode
            if os.getenv("TESTING") == "1":
                logger.info("Langfuse is disabled in testing mode - using no-op client")
                self._client = NoOpClient()
                self._is_enabled = False
                return

            # Check if Langfuse is enabled
            if not settings.LANGFUSE_ENABLED:
                logger.info("Langfuse is disabled via LANGFUSE_ENABLED=false - using no-op client")
                self._client = NoOpClient()
                self._is_enabled = False
                return

            # Check if Langfuse is configured
            if not settings.LANGFUSE_PUBLIC_KEY or not settings.LANGFUSE_SECRET_KEY:
                logger.warning("Langfuse keys not configured - using no-op client")
                self._client = NoOpClient()
                self._is_enabled = False
                return

            # Set OpenTelemetry timeout environment variables before initializing client
            # This prevents the very short default timeout (0.074s) that causes connection errors
            os.environ.setdefault('OTEL_EXPORTER_OTLP_TIMEOUT', '30000')  # 30 seconds in milliseconds
            os.environ.setdefault('OTEL_EXPORTER_OTLP_TRACES_TIMEOUT', '30000')

            # Initialize Langfuse client
            self._client = Langfuse(
                public_key=settings.LANGFUSE_PUBLIC_KEY,
                secret_key=settings.LANGFUSE_SECRET_KEY,
                host=settings.LANGFUSE_HOST,
                debug=False,
                flush_interval=1.0,  # Flush every second
                flush_at=10,  # Flush after 10 events
                timeout=30  # 30 second timeout for HTTP requests
            )

            self.initialized = True
            self._is_enabled = True
            logger.info(f"Langfuse client initialized - host: {settings.LANGFUSE_HOST}")

        except Exception as e:
            logger.error(f"Failed to initialize Langfuse client: {e} - using no-op client")
            self._client = NoOpClient()
            self._is_enabled = False
    
    @property
    def client(self) -> Optional[Langfuse]:
        """Get Langfuse client instance."""
        return self._client
    
    @property
    def is_enabled(self) -> bool:
        """Check if Langfuse is enabled and configured."""
        return self._is_enabled
    
    def create_trace(
        self,
        name: str,
        user_id: Optional[str] = None,
        session_id: Optional[str] = None,
        metadata: Optional[Dict[str, Any]] = None,
        tags: Optional[List[str]] = None,
        release: Optional[str] = None,
        version: Optional[str] = None,
        **kwargs
    ):
        """Create a new trace for tracking LLM operations."""
        if not self.is_enabled:
            return None
        
        try:
            # Langfuse v3 - Start a root span which creates the trace
            span = self._client.start_span(
                name=name,
                input=metadata,
                metadata={
                    'user_id': user_id,
                    'session_id': session_id,
                    'tags': tags or [],
                    'release': release,
                    'version': version
                },
                version=version
            )
            
            # Get the trace ID from the span
            trace_id = span.trace_id if hasattr(span, 'trace_id') else None
            
            # Update trace attributes
            if user_id or session_id:
                try:
                    span.update_trace(
                        user_id=user_id,
                        session_id=session_id,
                        tags=tags,
                        release=release,
                        version=version
                    )
                except Exception as e:
                    logger.debug(f"Could not update trace attributes: {e}")
            
            # Return trace object with span for later use
            # Include the span's observation ID for child spans to reference
            span_id = span.id if hasattr(span, 'id') else None
            return {'id': trace_id, 'name': name, 'span': span, 'span_id': span_id}
            
        except AttributeError as e:
            # Try alternative approach with observation
            try:
                import uuid
                trace_id = str(uuid.uuid4())
                # Create an event to mark the trace start
                self._client.create_event(
                    trace_id=trace_id,
                    name=name,
                    metadata=metadata or {},
                    **kwargs
                )
                return {'id': trace_id, 'name': name}
            except Exception as fallback_e:
                logger.debug(f"Fallback trace creation also failed: {fallback_e}")
                # Return a mock trace object so the app continues to work
                import uuid
                return {'id': str(uuid.uuid4()), 'name': name}
        except Exception as e:
            logger.error(f"Failed to create Langfuse trace: {e}")
            # Return a mock trace object so the app continues to work
            import uuid
            return {'id': str(uuid.uuid4()), 'name': name}
    
    def create_generation(
        self,
        trace_id: str,
        name: str,
        model: str,
        model_parameters: Optional[Dict[str, Any]] = None,
        input: Optional[Any] = None,
        output: Optional[Any] = None,
        usage: Optional[Dict[str, int]] = None,
        metadata: Optional[Dict[str, Any]] = None,
        level: Optional[str] = None,
        status_message: Optional[str] = None,
        completion_start_time: Optional[datetime] = None,
        end_time: Optional[datetime] = None,
        **kwargs
    ):
        """Create a generation observation for LLM calls."""
        if not self.is_enabled:
            return None
        
        try:
            # Create trace context if we have trace_id
            trace_context = None
            parent_observation_id = kwargs.get('parent_observation_id')
            if trace_id or parent_observation_id:
                try:
                    from langfuse.types import TraceContext
                    trace_context = TraceContext(
                        trace_id=trace_id,
                        observation_id=parent_observation_id
                    )
                except ImportError:
                    # TraceContext might not be available in all versions
                    pass
            
            # Langfuse v3 - Create a generation for LLM calls
            generation = self._client.start_generation(
                trace_context=trace_context,
                name=name,
                model=model,
                model_parameters=model_parameters or {},
                input=input,
                metadata=metadata or {},
                level=level,
                status_message=status_message,
                completion_start_time=completion_start_time,
                usage_details=usage  # Note: it's usage_details, not usage
            )
            
            # Update with output if available
            if output:
                try:
                    generation.update(output=output)
                except Exception as e:
                    logger.debug(f"Could not update generation output: {e}")
            
            # End the generation if we have all the data
            if end_time:
                try:
                    generation.end()
                except Exception as e:
                    logger.debug(f"Could not end generation: {e}")
            
            return generation
        except Exception as e:
            logger.error(f"Failed to create Langfuse generation: {e}")
            # Return a basic object so the app continues to work
            return {'id': None, 'name': name, 'trace_id': trace_id}
    
    def create_span(
        self,
        trace_id: str,
        name: str,
        parent_observation_id: Optional[str] = None,
        start_time: Optional[datetime] = None,
        end_time: Optional[datetime] = None,
        input: Optional[Any] = None,
        output: Optional[Any] = None,
        metadata: Optional[Dict[str, Any]] = None,
        level: Optional[str] = None,
        status_message: Optional[str] = None,
        **kwargs
    ):
        """Create a span for tracking sub-operations."""
        if not self.is_enabled:
            return None
        
        try:
            # Create trace context if we have trace_id and parent
            trace_context = None
            if trace_id or parent_observation_id:
                try:
                    from langfuse.types import TraceContext
                    trace_context = TraceContext(
                        trace_id=trace_id,
                        observation_id=parent_observation_id
                    )
                except ImportError:
                    # TraceContext might not be available in all versions
                    pass
            
            # Langfuse v3 - Create a span with trace context
            span = self._client.start_span(
                trace_context=trace_context,
                name=name,
                input=input,
                metadata=metadata or {},
                level=level,
                status_message=status_message
            )
            
            # Update with output if provided
            if output:
                try:
                    span.update(output=output)
                except Exception as e:
                    logger.debug(f"Could not update span output: {e}")
            
            # End the span if end_time is provided
            if end_time:
                try:
                    span.end()  # end() doesn't take arguments in v3
                except Exception as e:
                    logger.debug(f"Could not end span: {e}")
            
            return span
        except Exception as e:
            logger.error(f"Failed to create Langfuse span: {e}")
            # Return a basic object so the app continues to work
            return {'id': None, 'name': name, 'trace_id': trace_id}
    
    def create_event(
        self,
        trace_id: str,
        name: str,
        parent_observation_id: Optional[str] = None,
        start_time: Optional[datetime] = None,
        input: Optional[Any] = None,
        output: Optional[Any] = None,
        metadata: Optional[Dict[str, Any]] = None,
        level: Optional[str] = None,
        status_message: Optional[str] = None,
        **kwargs
    ):
        """Create an event for tracking discrete occurrences."""
        if not self.is_enabled:
            return None
        
        try:
            # Langfuse v3 - create_event requires a trace context
            # We need to create a temporary span context for the event
            from langfuse.types import TraceContext
            
            # Create trace context
            trace_context = TraceContext(
                trace_id=trace_id,
                observation_id=parent_observation_id
            ) if parent_observation_id else None
            
            # Create the event
            event = self._client.create_event(
                name=name,
                trace_context=trace_context,
                input=input,
                output=output,
                metadata=metadata or {},
                level=level,
                status_message=status_message,
                version=kwargs.get('version')
            )
            return event
        except ImportError:
            # Fallback if TraceContext not available
            try:
                # Try without trace_context
                event = self._client.create_event(
                    name=name,
                    input=input,
                    output=output,
                    metadata={
                        **(metadata or {}),
                        'trace_id': trace_id,
                        'parent_observation_id': parent_observation_id
                    },
                    level=level,
                    status_message=status_message
                )
                return event
            except Exception as e:
                logger.debug(f"Event creation fallback also failed: {e}")
                return None
        except Exception as e:
            logger.error(f"Failed to create Langfuse event: {e}")
            return None
    
    def score(
        self,
        trace_id: str,
        name: str,
        value: float,
        observation_id: Optional[str] = None,
        comment: Optional[str] = None,
        **kwargs
    ):
        """Add a score to a trace or observation."""
        if not self.is_enabled:
            return None
        
        try:
            # Langfuse v3 uses create_score instead of score
            score = self._client.create_score(
                trace_id=trace_id,
                name=name,
                value=value,
                observation_id=observation_id,
                comment=comment,
                **kwargs
            )
            return score
        except Exception as e:
            logger.error(f"Failed to create Langfuse score: {e}")
            return None
    
    def flush(self):
        """Flush pending events to Langfuse."""
        if not self.is_enabled:
            return
        
        try:
            self._client.flush()
            logger.debug("Flushed Langfuse events successfully")
        except Exception as e:
            logger.error(f"Failed to flush Langfuse events: {e}")
    
    def shutdown(self):
        """Shutdown Langfuse client and flush remaining events."""
        if not self.is_enabled:
            return
        
        try:
            self._client.shutdown()
            logger.info("Langfuse client shutdown complete")
        except Exception as e:
            logger.error(f"Failed to shutdown Langfuse client: {e}")
    
    @contextmanager
    def trace_context(self, name: str, **kwargs):
        """Context manager for creating traces with automatic error handling."""
        trace = None
        try:
            trace = self.create_trace(name=name, **kwargs)
            yield trace
        except Exception as e:
            if trace:
                self.create_event(
                    trace_id=trace.id if hasattr(trace, 'id') else None,
                    name="error",
                    level="ERROR",
                    status_message=str(e)
                )
            raise
        finally:
            self.flush()
    
    async def check_health(self) -> Dict[str, Any]:
        """Check Langfuse service health."""
        try:
            if not self.is_enabled:
                return {
                    "status": "disabled",
                    "message": "Langfuse not configured"
                }
            
            # Try to create a test trace
            test_trace = self.create_trace(
                name="health_check",
                metadata={"type": "health_check", "timestamp": datetime.utcnow().isoformat()}
            )
            
            if test_trace:
                self.flush()
                return {
                    "status": "healthy",
                    "host": settings.LANGFUSE_HOST,
                    "enabled": True
                }
            else:
                return {
                    "status": "unhealthy",
                    "message": "Failed to create test trace"
                }
                
        except Exception as e:
            logger.error(f"Langfuse health check failed: {e}")
            return {
                "status": "error",
                "message": str(e)
            }


# Singleton instance
langfuse_service = LangfuseService()