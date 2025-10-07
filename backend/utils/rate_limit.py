"""
Rate limiting utilities for API endpoints

Provides rate limiting decorators and utilities using slowapi.
"""

import os
from slowapi import Limiter
from slowapi.util import get_remote_address


class NoOpLimiter:
    """No-op limiter for testing environments."""

    def limit(self, *args, **kwargs):
        """Return a no-op decorator."""
        def decorator(func):
            return func
        return decorator


# Create limiter instance based on environment
# In testing mode, use a no-op limiter to avoid issues with httpx.AsyncClient
if os.getenv("TESTING") == "1":
    limiter = NoOpLimiter()
else:
    # This will be attached to the FastAPI app in main.py
    # No default_limits - rate limiting is applied only to specific endpoints with @limiter.limit()
    limiter = Limiter(
        key_func=get_remote_address,
        storage_uri="memory://",
        strategy="fixed-window"
    )

# Rate limit decorators for different endpoint types
# These can be imported and used with @limiter.limit()

# Strict limits for authentication endpoints (prevent brute force)
AUTH_RATE_LIMIT = "5/minute"  # 5 attempts per minute per IP

# Moderate limits for expensive operations (RAG queries, summaries)
QUERY_RATE_LIMIT = "20/minute"  # 20 queries per minute per IP

# Generous limits for general CRUD operations
GENERAL_RATE_LIMIT = "100/minute"  # 100 requests per minute per IP

# Very strict for password reset (prevent abuse)
RESET_PASSWORD_RATE_LIMIT = "3/minute"  # 3 attempts per minute per IP
