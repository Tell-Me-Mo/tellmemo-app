"""
Authentication Middleware

This middleware handles JWT token extraction, validation, and organization
context injection for all protected API routes.
"""

import logging
import time
from typing import Optional
from uuid import UUID

from fastapi import Request, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.responses import Response, JSONResponse
import jwt
from jwt import ExpiredSignatureError

from services.auth.auth_service import auth_service
from services.auth.native_auth_service import native_auth_service
from config import get_settings
from db import get_db_context
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from models.user import User

logger = logging.getLogger(__name__)


class AuthMiddleware(BaseHTTPMiddleware):
    """
    Middleware to handle JWT authentication and organization context for all requests.
    This extracts the JWT token from the Authorization header, validates it, and adds
    user and organization context to the request state.
    """

    # Paths that don't require authentication
    PUBLIC_PATHS = [
        "/docs",
        "/openapi.json",
        "/redoc",
        "/health",
        "/api/health",
        # Supabase auth endpoints
        "/api/v1/auth/signup",
        "/api/v1/auth/signin",
        "/api/v1/auth/refresh",
        "/api/v1/auth/forgot-password",
        "/api/v1/auth/reset-password",
        # Native backend auth endpoints
        "/api/auth/signup",
        "/api/auth/login",
        "/api/auth/logout",
        "/api/auth/reset-password",
        # Other public endpoints
        "/api/v1/invitations/accept",  # Accept invitation with token
    ]

    async def dispatch(self, request: Request, call_next):
        """
        Process the request and inject authentication context

        Args:
            request: Incoming request
            call_next: Next middleware in chain

        Returns:
            Response from the next middleware or endpoint
        """
        # Skip authentication for public paths
        path = request.url.path
        if any(path.startswith(public_path) for public_path in self.PUBLIC_PATHS):
            return await call_next(request)

        # Skip OPTIONS requests (CORS preflight)
        if request.method == "OPTIONS":
            return await call_next(request)

        # Extract token from Authorization header
        authorization = request.headers.get("Authorization")
        if not authorization:
            logger.debug(f"No authorization header for path: {path}")
            # Allow request to continue without auth context
            # Individual endpoints will handle authorization requirements
            return await call_next(request)

        # Parse Bearer token
        if not authorization.startswith("Bearer "):
            logger.warning("Invalid authorization header format")
            return await call_next(request)

        token = authorization[7:]  # Remove "Bearer " prefix
        refresh_token = request.headers.get("X-Refresh-Token")  # Optional refresh token

        # Verify token and get user
        try:
            # Check if token is expired and attempt refresh if refresh token provided
            token_needs_refresh = False
            try:
                # Try to decode token to check expiration
                if auth_service.jwt_secret:
                    payload = jwt.decode(
                        token,
                        auth_service.jwt_secret,
                        algorithms=["HS256"],
                        options={"verify_exp": True}
                    )
            except ExpiredSignatureError:
                # Token is expired, attempt refresh if refresh token available
                if refresh_token:
                    logger.info("Access token expired, attempting automatic refresh")
                    token_needs_refresh = True
                else:
                    logger.debug("Access token expired and no refresh token provided")
            except Exception:
                # Other token errors, let normal validation handle it
                pass

            # Attempt token refresh if needed
            if token_needs_refresh and refresh_token:
                try:
                    new_tokens = await auth_service.refresh_token(refresh_token)
                    if new_tokens:
                        token = new_tokens["access_token"]
                        # Store new tokens in request state for response headers
                        request.state.new_tokens = new_tokens
                        logger.info("Successfully refreshed access token")
                except Exception as e:
                    logger.error(f"Failed to refresh token: {e}")

            # Use get_db_context to get a database session
            async with get_db_context() as db:
                # Use auth service based on AUTH_PROVIDER setting
                settings = get_settings()
                if settings.auth_provider == 'backend':
                    user = await native_auth_service.get_user_from_token(db, token)
                else:  # supabase
                    user = await auth_service.get_user_from_token(db, token)

                if user:
                    # Store user in request state for access in endpoints
                    request.state.user = user

                    # Extract organization ID from headers or use last active
                    org_id_str = request.headers.get("X-Organization-Id")
                    organization_id = None
                    if org_id_str:
                        try:
                            organization_id = UUID(org_id_str)
                        except ValueError:
                            logger.warning(f"Invalid organization ID in header: {org_id_str}")

                    # Get user's organization
                    organization = await auth_service.get_user_organization(
                        db, user, organization_id
                    )

                    role = None  # Initialize role variable
                    if organization:
                        request.state.organization = organization

                        # Get user's role in the organization
                        role = await auth_service.validate_user_role(
                            db, user, organization
                        )
                        if role:
                            request.state.user_role = role

                    # Log request with organization context
                    logger.info(
                        f"Request authenticated - User: {user.email}, "
                        f"Organization: {organization.name if organization else 'None'}, "
                        f"Role: {role if role else 'None'}, "
                        f"Path: {request.method} {path}"
                    )

        except Exception as e:
            logger.error(f"Error processing authentication: {e}")
            # Continue without auth context

        # Process the request
        response = await call_next(request)

        # Add new tokens to response headers if they were refreshed
        if hasattr(request.state, 'new_tokens'):
            response.headers["X-New-Access-Token"] = request.state.new_tokens["access_token"]
            response.headers["X-New-Refresh-Token"] = request.state.new_tokens["refresh_token"]
            response.headers["X-Token-Refreshed"] = "true"

        return response


class JWTBearer(HTTPBearer):
    """
    Custom JWT Bearer authentication for FastAPI dependency injection.
    This is used as a dependency in individual endpoints that require authentication.
    """

    def __init__(self, auto_error: bool = True):
        """
        Initialize JWT Bearer authentication

        Args:
            auto_error: Whether to automatically raise HTTPException on auth failure
        """
        super().__init__(auto_error=auto_error)

    async def __call__(self, request: Request) -> Optional[HTTPAuthorizationCredentials]:
        """
        Validate the JWT token from the Authorization header

        Args:
            request: Incoming request

        Returns:
            Authorization credentials if valid

        Raises:
            HTTPException: If authentication fails and auto_error is True
        """
        credentials: HTTPAuthorizationCredentials = await super().__call__(request)

        if credentials:
            if not credentials.scheme == "Bearer":
                if self.auto_error:
                    raise HTTPException(
                        status_code=status.HTTP_401_UNAUTHORIZED,
                        detail="Invalid authentication scheme",
                        headers={"WWW-Authenticate": "Bearer"},
                    )
                else:
                    return None

            # Token validation is done in middleware
            # Here we just check if user is in request state
            if not hasattr(request.state, 'user'):
                if self.auto_error:
                    raise HTTPException(
                        status_code=status.HTTP_401_UNAUTHORIZED,
                        detail="Invalid or expired token",
                        headers={"WWW-Authenticate": "Bearer"},
                    )
                else:
                    return None

            return credentials

        if self.auto_error:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Authorization required",
                headers={"WWW-Authenticate": "Bearer"},
            )
        else:
            return None


# Create reusable security dependency
jwt_bearer = JWTBearer()


async def get_current_user_ws(token: str, db: AsyncSession) -> Optional[User]:
    """
    Validate WebSocket connection token and return the current user.

    Args:
        token: JWT token from WebSocket query parameter
        db: Database session

    Returns:
        User object if token is valid, None otherwise
    """
    try:
        if not token:
            return None

        # Verify token with auth service
        user_data = auth_service.verify_token(token)
        if not user_data:
            return None

        user_id = user_data.get("sub")
        if not user_id:
            return None

        # Get user from database
        result = await db.execute(
            select(User).where(User.id == UUID(user_id))
        )
        user = result.scalar_one_or_none()

        return user

    except Exception as e:
        logger.error(f"Error validating WebSocket token: {e}")
        return None