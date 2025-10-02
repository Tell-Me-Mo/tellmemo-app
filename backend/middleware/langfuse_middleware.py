"""Langfuse monitoring middleware for FastAPI with context manager support."""

import time
import json
import uuid
from typing import Callable, Optional, Dict, Any
from datetime import datetime

from fastapi import Request, Response
from fastapi.routing import APIRoute
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.types import ASGIApp

from services.observability.langfuse_service import langfuse_service
from utils.logger import get_logger

logger = get_logger(__name__)


class LangfuseMiddleware(BaseHTTPMiddleware):
    """Middleware for tracking all API requests with Langfuse v3 context managers."""
    
    def __init__(self, app: ASGIApp):
        super().__init__(app)
        self.langfuse_client = langfuse_service.client
    
    async def dispatch(self, request: Request, call_next: Callable) -> Response:
        """Process each request with Langfuse monitoring."""
        # Skip health checks and static files
        if request.url.path in ["/health", "/metrics", "/favicon.ico"]:
            return await call_next(request)
        
        # Check if Langfuse is enabled
        if not langfuse_service.is_enabled:
            return await call_next(request)
        
        # Generate request ID
        request_id = str(uuid.uuid4())
        request.state.request_id = request_id
        
        # Extract request metadata
        method = request.method
        path = request.url.path
        query_params = dict(request.query_params)
        
        # Try to get user info from headers or auth
        user_id = request.headers.get("X-User-ID")
        api_key = request.headers.get("X-API-Key")

        # Get organization context from request state (set by auth middleware)
        organization_id = None
        organization_name = None
        user_role = None
        user_email = None

        if hasattr(request.state, 'user'):
            user_email = request.state.user.email if request.state.user else None
            user_id = str(request.state.user.id) if request.state.user else user_id

        if hasattr(request.state, 'organization'):
            organization_id = str(request.state.organization.id) if request.state.organization else None
            organization_name = request.state.organization.name if request.state.organization else None

        if hasattr(request.state, 'user_role'):
            user_role = request.state.user_role
        
        # Start timing
        start_time = time.time()
        
        # Check if Langfuse client supports context managers
        if self.langfuse_client and hasattr(self.langfuse_client, 'start_as_current_span'):
            try:
                # Use context manager for proper span tracking
                with self.langfuse_client.start_as_current_span(
                    name=f"{method} {path}",
                    input={
                        "method": method,
                        "path": path,
                        "query_params": query_params,
                        "headers": {
                            "content_type": request.headers.get("content-type"),
                            "user_agent": request.headers.get("user-agent"),
                        }
                    },
                    metadata={
                        "request_id": request_id,
                        "user_id": user_id,
                        "user_email": user_email,
                        "organization_id": organization_id,
                        "organization_name": organization_name,
                        "user_role": user_role,
                        "api_key": api_key,
                        "client_host": request.client.host if request.client else None
                    },
                    version="1.0.0"
                ) as span:
                    # Store span in request state for nested operations
                    request.state.langfuse_span = span
                    
                    try:
                        # Process the request
                        response = await call_next(request)
                        
                        # Calculate response time
                        response_time = (time.time() - start_time) * 1000
                        
                        # Update span with response info
                        if hasattr(span, 'update'):
                            span.update(
                                output={
                                    "status_code": response.status_code,
                                    "response_time_ms": response_time,
                                    "success": 200 <= response.status_code < 400
                                },
                                metadata={
                                    "response_headers": dict(response.headers) if response.headers else {},
                                    "token_refreshed": response.headers.get("X-Token-Refreshed", "false")
                                }
                            )
                        
                        # Add performance score
                        if hasattr(span, 'score'):
                            # Score based on response time
                            if response_time < 100:
                                performance_score = 1.0
                            elif response_time < 500:
                                performance_score = 0.8
                            elif response_time < 1000:
                                performance_score = 0.6
                            elif response_time < 3000:
                                performance_score = 0.4
                            else:
                                performance_score = 0.2
                            
                            span.score(
                                name="api_performance",
                                value=performance_score,
                                comment=f"Response time: {response_time:.2f}ms"
                            )
                        
                        return response
                        
                    except Exception as e:
                        # Log error to span
                        if hasattr(span, 'update'):
                            span.update(
                                output={
                                    "error": str(e),
                                    "error_type": type(e).__name__,
                                    "status_code": 500
                                },
                                level="ERROR",
                                status_message=str(e)
                            )
                        raise
                        
            except Exception as e:
                logger.error(f"Langfuse middleware error: {e}")
                # Continue without monitoring if Langfuse fails
                return await call_next(request)
        else:
            # Fallback to simpler tracking without context managers
            try:
                trace = langfuse_service.create_trace(
                    name=f"{method} {path}",
                    user_id=user_id,
                    session_id=request_id,
                    metadata={
                        "method": method,
                        "path": path,
                        "query_params": query_params,
                        "api_key": api_key,
                        "organization_id": organization_id,
                        "organization_name": organization_name,
                        "user_role": user_role
                    },
                    tags=["api", method.lower()]
                )
                
                trace_id = trace.get('id') if isinstance(trace, dict) else None
                
                # Process request
                response = await call_next(request)
                
                # Log response
                response_time = (time.time() - start_time) * 1000
                
                if trace_id:
                    langfuse_service.create_event(
                        trace_id=trace_id,
                        name="api_response",
                        metadata={
                            "status_code": response.status_code,
                            "response_time_ms": response_time
                        },
                        level="INFO" if response.status_code < 400 else "ERROR"
                    )
                    
                    langfuse_service.flush()
                
                return response
                
            except Exception as e:
                logger.error(f"Langfuse fallback tracking error: {e}")
                return await call_next(request)


class LangfuseRouteHandler(APIRoute):
    """Custom route handler for more detailed endpoint tracking."""
    
    def get_route_handler(self) -> Callable:
        original_route_handler = super().get_route_handler()
        
        async def custom_route_handler(request: Request) -> Response:
            # Get Langfuse span from request state if available
            parent_span = getattr(request.state, 'langfuse_span', None)
            
            if parent_span and langfuse_service.client:
                langfuse_client = langfuse_service.client
                
                # Create nested span for endpoint logic
                if hasattr(langfuse_client, 'start_as_current_span'):
                    with langfuse_client.start_as_current_span(
                        name=f"endpoint_logic_{self.endpoint.__name__}",
                        input={
                            "endpoint": self.endpoint.__name__,
                            "path": self.path,
                            "methods": list(self.methods) if self.methods else []
                        }
                    ) as endpoint_span:
                        # Store endpoint span for use in endpoint code
                        request.state.endpoint_span = endpoint_span
                        
                        # Execute endpoint
                        response = await original_route_handler(request)
                        
                        # Update endpoint span
                        if hasattr(endpoint_span, 'update'):
                            endpoint_span.update(
                                output={
                                    "completed": True,
                                    "response_type": type(response).__name__
                                }
                            )
                        
                        return response
            
            # Fallback to original handler
            return await original_route_handler(request)
        
        return custom_route_handler


def add_langfuse_middleware(app):
    """Add Langfuse middleware to FastAPI app."""
    app.add_middleware(LangfuseMiddleware)
    logger.info("Langfuse middleware initialized for API monitoring")


def track_background_task(task_name: str, metadata: Optional[Dict[str, Any]] = None):
    """Decorator for tracking background tasks with Langfuse."""
    def decorator(func: Callable):
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


def track_database_operation(operation_type: str):
    """Decorator for tracking database operations."""
    def decorator(func: Callable):
        async def wrapper(*args, **kwargs):
            if not langfuse_service.is_enabled:
                return await func(*args, **kwargs)
            
            langfuse_client = langfuse_service.client
            if langfuse_client and hasattr(langfuse_client, 'start_as_current_span'):
                with langfuse_client.start_as_current_span(
                    name=f"db_{operation_type}",
                    input={
                        "operation": operation_type,
                        "function": func.__name__
                    }
                ) as db_span:
                    start_time = time.time()
                    
                    try:
                        result = await func(*args, **kwargs)
                        
                        execution_time = (time.time() - start_time) * 1000
                        
                        if hasattr(db_span, 'update'):
                            db_span.update(
                                output={
                                    "success": True,
                                    "execution_time_ms": execution_time,
                                    "rows_affected": len(result) if hasattr(result, '__len__') else 1
                                }
                            )
                        
                        return result
                        
                    except Exception as e:
                        if hasattr(db_span, 'update'):
                            db_span.update(
                                output={
                                    "success": False,
                                    "error": str(e),
                                    "error_type": type(e).__name__
                                },
                                level="ERROR"
                            )
                        raise
            else:
                return await func(*args, **kwargs)
        
        return wrapper
    return decorator