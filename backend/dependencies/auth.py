"""
Authentication Dependencies

This module provides FastAPI dependencies for authentication and authorization
in API endpoints.
"""

from typing import Optional
from uuid import UUID

from fastapi import Depends, HTTPException, Request, status
from sqlalchemy.ext.asyncio import AsyncSession

from db import get_db
from models.user import User
from models.organization import Organization
from models.organization_member import OrganizationMember
from middleware.auth_middleware import jwt_bearer
from services.auth.auth_service import auth_service


async def get_current_user(
    request: Request,
    credentials=Depends(jwt_bearer),
    db: AsyncSession = Depends(get_db)
) -> User:
    """
    Get the current authenticated user from the request

    Args:
        request: FastAPI request object
        credentials: JWT bearer credentials
        db: Database session

    Returns:
        Current authenticated User

    Raises:
        HTTPException: If user is not authenticated
    """
    if not hasattr(request.state, 'user'):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not authenticated",
            headers={"WWW-Authenticate": "Bearer"},
        )

    # Get user from request state (set by middleware)
    user_from_state = request.state.user

    # Re-fetch user in current session to avoid "not bound to Session" error
    from sqlalchemy import select
    from models.user import User as UserModel

    result = await db.execute(
        select(UserModel).where(UserModel.id == user_from_state.id)
    )
    user = result.scalar_one_or_none()

    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found",
            headers={"WWW-Authenticate": "Bearer"},
        )

    return user


async def get_current_organization(
    request: Request,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
) -> Organization:
    """
    Get the current organization context

    Args:
        request: FastAPI request object
        current_user: Current authenticated user
        db: Database session

    Returns:
        Current Organization

    Raises:
        HTTPException: If organization context is not available
    """
    # Try to get from request state first (set by middleware)
    if hasattr(request.state, 'organization'):
        return request.state.organization

    # Otherwise get user's last active organization
    organization = await auth_service.get_user_organization(
        db, current_user
    )

    if not organization:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No organization found for user"
        )

    return organization


async def get_current_user_role(
    request: Request,
    current_user: User = Depends(get_current_user),
    current_org: Organization = Depends(get_current_organization),
    db: AsyncSession = Depends(get_db)
) -> str:
    """
    Get the current user's role in the organization

    Args:
        request: FastAPI request object
        current_user: Current authenticated user
        current_org: Current organization
        db: Database session

    Returns:
        User's role in the organization

    Raises:
        HTTPException: If user is not a member of the organization
    """
    # Try to get from request state first (set by middleware)
    if hasattr(request.state, 'user_role'):
        return request.state.user_role

    # Otherwise query the database
    role = await auth_service.validate_user_role(
        db, current_user, current_org
    )

    if not role:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="User is not a member of this organization"
        )

    return role


def require_role(required_role: str):
    """
    Dependency factory to require a specific role or higher

    Args:
        required_role: Minimum required role ('admin', 'member', 'viewer')

    Returns:
        FastAPI dependency function
    """
    async def check_role(
        role: str = Depends(get_current_user_role)
    ) -> str:
        """
        Check if user has required role or higher

        Args:
            role: User's current role

        Returns:
            User's role if authorized

        Raises:
            HTTPException: If user doesn't have required role
        """
        role_hierarchy = {
            'viewer': 0,
            'member': 1,
            'admin': 2
        }

        if role_hierarchy.get(role, -1) < role_hierarchy.get(required_role, 999):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Requires {required_role} role or higher"
            )

        return role

    return check_role


# Convenience dependencies for common role requirements
require_admin = require_role("admin")
require_member = require_role("member")
require_viewer = require_role("viewer")


async def get_optional_current_user(
    request: Request,
    db: AsyncSession = Depends(get_db)
) -> Optional[User]:
    """
    Get the current user if authenticated, otherwise return None

    Args:
        request: FastAPI request object
        db: Database session

    Returns:
        Current authenticated User or None
    """
    # Check if user is in request state (set by middleware)
    if hasattr(request.state, 'user'):
        return request.state.user

    # Check for authorization header
    authorization = request.headers.get("Authorization")
    if not authorization or not authorization.startswith("Bearer "):
        return None

    token = authorization[7:]  # Remove "Bearer " prefix

    # Try to get user from token
    try:
        user = await auth_service.get_user_from_token(db, token)
        return user
    except Exception:
        return None


async def get_optional_organization(
    request: Request,
    user: Optional[User] = Depends(get_optional_current_user),
    db: AsyncSession = Depends(get_db)
) -> Optional[Organization]:
    """
    Get the current organization if user is authenticated, otherwise return None

    Args:
        request: FastAPI request object
        user: Optional authenticated user
        db: Database session

    Returns:
        Current Organization or None
    """
    if not user:
        return None

    # Try to get from request state first
    if hasattr(request.state, 'organization'):
        return request.state.organization

    # Otherwise get user's organization
    return await auth_service.get_user_organization(db, user)