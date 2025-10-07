"""
Rate limiting utilities for API endpoints

Provides rate limiting decorators and utilities using slowapi.
"""

from slowapi import Limiter
from slowapi.util import get_remote_address

# Create limiter instance
# This will be attached to the FastAPI app in main.py
limiter = Limiter(
    key_func=get_remote_address,
    default_limits=["100/minute"],  # General API endpoints
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
