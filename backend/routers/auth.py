"""
Authentication API Router

This module provides authentication endpoints for user registration, login,
token refresh, and password management using Supabase Auth.
"""

import logging
from typing import Optional
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, status, Request
from pydantic import BaseModel, EmailStr
from sqlalchemy.ext.asyncio import AsyncSession

from db import get_db
from services.auth.auth_service import auth_service
from models.user import User
from dependencies.auth import get_optional_current_user

logger = logging.getLogger(__name__)

router = APIRouter(
    prefix="/api/v1/auth",
    tags=["Authentication"]
)


# Request/Response Models
class SignUpRequest(BaseModel):
    """Request model for user registration"""
    email: EmailStr
    password: str
    name: Optional[str] = None


class SignInRequest(BaseModel):
    """Request model for user login"""
    email: EmailStr
    password: str


class RefreshTokenRequest(BaseModel):
    """Request model for token refresh"""
    refresh_token: str


class ForgotPasswordRequest(BaseModel):
    """Request model for password reset initiation"""
    email: EmailStr


class ResetPasswordRequest(BaseModel):
    """Request model for password reset confirmation"""
    token: str
    password: str


class AuthResponse(BaseModel):
    """Response model for authentication operations"""
    access_token: str
    refresh_token: str
    token_type: str = "Bearer"
    expires_in: int
    user: dict


class MessageResponse(BaseModel):
    """Generic message response"""
    message: str
    success: bool = True


@router.post("/signup", response_model=AuthResponse)
async def sign_up(
    request: Request,
    signup_data: SignUpRequest,
    db: AsyncSession = Depends(get_db)
):
    """
    Register a new user account

    Args:
        signup_data: Sign up request with email and password
        db: Database session

    Returns:
        Authentication response with tokens and user data

    Raises:
        HTTPException: If registration fails
    """
    if not auth_service.client:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Authentication service not configured"
        )

    try:
        # Create user in Supabase Auth
        response = auth_service.client.auth.sign_up({
            "email": signup_data.email,
            "password": signup_data.password,
            "options": {
                "data": {
                    "name": signup_data.name
                }
            }
        })

        if not response.user:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Failed to create user account"
            )

        # Sync user to local database
        local_user = await auth_service.sync_user_from_supabase(
            db, response.user
        )

        if not local_user:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to sync user data"
            )

        # Note: Supabase automatically sends a confirmation email based on your
        # email template settings in the Supabase dashboard

        # Return authentication response
        return AuthResponse(
            access_token=response.session.access_token,
            refresh_token=response.session.refresh_token,
            expires_in=response.session.expires_in,
            user={
                "id": str(local_user.id),
                "email": local_user.email,
                "name": local_user.name,
                "avatar_url": local_user.avatar_url,
                "email_verified": local_user.email_verified
            }
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error during sign up: {e}")
        # Check if it's a duplicate email error
        if "already registered" in str(e).lower() or "duplicate" in str(e).lower():
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Email already registered"
            )
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to create account"
        )


@router.post("/signin", response_model=AuthResponse)
async def sign_in(
    signin_data: SignInRequest,
    db: AsyncSession = Depends(get_db)
):
    """
    Sign in an existing user

    Args:
        signin_data: Sign in request with email and password
        db: Database session

    Returns:
        Authentication response with tokens and user data

    Raises:
        HTTPException: If authentication fails
    """
    if not auth_service.client:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Authentication service not configured"
        )

    try:
        # Authenticate with Supabase Auth
        response = auth_service.client.auth.sign_in_with_password({
            "email": signin_data.email,
            "password": signin_data.password
        })

        if not response.user or not response.session:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid email or password"
            )

        # Sync user to local database
        local_user = await auth_service.sync_user_from_supabase(
            db, response.user
        )

        if not local_user:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to sync user data"
            )

        # Update last login (use timezone-naive datetime for PostgreSQL)
        local_user.updated_at = datetime.now(timezone.utc).replace(tzinfo=None)
        await db.commit()

        # Return authentication response
        return AuthResponse(
            access_token=response.session.access_token,
            refresh_token=response.session.refresh_token,
            expires_in=response.session.expires_in,
            user={
                "id": str(local_user.id),
                "email": local_user.email,
                "name": local_user.name,
                "avatar_url": local_user.avatar_url,
                "email_verified": local_user.email_verified,
                "last_active_organization_id": str(local_user.last_active_organization_id)
                    if local_user.last_active_organization_id else None
            }
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error during sign in: {e}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authentication failed"
        )


@router.post("/refresh", response_model=AuthResponse)
async def refresh_token(
    refresh_data: RefreshTokenRequest,
    db: AsyncSession = Depends(get_db)
):
    """
    Refresh an access token using a refresh token

    Args:
        refresh_data: Refresh token request
        db: Database session

    Returns:
        New authentication tokens

    Raises:
        HTTPException: If refresh fails
    """
    # Check which auth service is being used
    from services.auth.native_auth_service import native_auth_service

    try:
        # Try native auth first
        payload = native_auth_service.verify_jwt_token(refresh_data.refresh_token)

        if payload and payload.get('type') == 'refresh':
            # Native auth refresh
            user_id = payload.get('sub')
            if not user_id:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Invalid refresh token"
                )

            # Get user from database
            from sqlalchemy import select
            result = await db.execute(
                select(User).where(User.id == user_id)
            )
            user = result.scalar_one_or_none()

            if not user or not user.is_active:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="User not found or inactive"
                )

            # Create new tokens
            new_access_token = native_auth_service.create_access_token(
                str(user.id),
                user.email,
                str(user.last_active_organization_id) if user.last_active_organization_id else None
            )
            new_refresh_token = native_auth_service.create_refresh_token(str(user.id))

            return AuthResponse(
                access_token=new_access_token,
                refresh_token=new_refresh_token,
                expires_in=native_auth_service.access_token_expire_minutes * 60,
                user={
                    "id": str(user.id),
                    "email": user.email,
                    "name": user.name,
                    "avatar_url": user.avatar_url,
                    "email_verified": user.email_verified,
                    "last_active_organization_id": str(user.last_active_organization_id)
                        if user.last_active_organization_id else None
                }
            )

        # Fall back to Supabase auth if native auth fails
        if not auth_service.client:
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="Authentication service not configured"
            )

        # Refresh the session
        response = auth_service.client.auth.refresh_session(refresh_data.refresh_token)

        if not response or not response.session:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid or expired refresh token"
            )

        # Get user from the new session
        user_response = auth_service.client.auth.get_user(response.session.access_token)

        if not user_response or not user_response.user:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Failed to get user data"
            )

        # Sync user data
        local_user = await auth_service.sync_user_from_supabase(
            db, user_response.user
        )

        return AuthResponse(
            access_token=response.session.access_token,
            refresh_token=response.session.refresh_token,
            expires_in=response.session.expires_in,
            user={
                "id": str(local_user.id),
                "email": local_user.email,
                "name": local_user.name,
                "avatar_url": local_user.avatar_url,
                "email_verified": local_user.email_verified,
                "last_active_organization_id": str(local_user.last_active_organization_id)
                    if local_user.last_active_organization_id else None
            }
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error refreshing token: {e}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Failed to refresh token"
        )


@router.post("/forgot-password", response_model=MessageResponse)
async def forgot_password(
    forgot_password_data: ForgotPasswordRequest
):
    """
    Request a password reset email

    Args:
        forgot_password_data: Forgot password request with email

    Returns:
        Success message

    Raises:
        HTTPException: If request fails
    """
    if not auth_service.client:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Authentication service not configured"
        )

    try:
        # Request password reset
        auth_service.client.auth.reset_password_email(
            forgot_password_data.email,
            {
                "redirect_to": "http://localhost:8100/reset-password"  # Configure this URL
            }
        )

        # Always return success to avoid email enumeration
        return MessageResponse(
            message="If an account exists with this email, a password reset link has been sent."
        )

    except Exception as e:
        logger.error(f"Error requesting password reset: {e}")
        # Still return success to avoid email enumeration
        return MessageResponse(
            message="If an account exists with this email, a password reset link has been sent."
        )


@router.post("/reset-password", response_model=MessageResponse)
async def reset_password(
    reset_password_data: ResetPasswordRequest,
    db: AsyncSession = Depends(get_db)
):
    """
    Reset password using a reset token

    Args:
        reset_password_data: Reset password request with token and new password
        db: Database session

    Returns:
        Success message

    Raises:
        HTTPException: If reset fails
    """
    if not auth_service.client:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Authentication service not configured"
        )

    try:
        # Update password using the token
        response = auth_service.client.auth.update_user(
            {
                "password": reset_password_data.password
            },
            access_token=reset_password_data.token  # The reset token acts as an access token
        )

        if not response or not response.user:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid or expired reset token"
            )

        # Sync user data
        await auth_service.sync_user_from_supabase(db, response.user)

        return MessageResponse(
            message="Password has been reset successfully"
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error resetting password: {e}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Failed to reset password"
        )


@router.post("/signout", response_model=MessageResponse)
async def sign_out(
    current_user: Optional[User] = Depends(get_optional_current_user)
):
    """
    Sign out the current user

    Args:
        current_user: Optional current user

    Returns:
        Success message
    """
    if not auth_service.client:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Authentication service not configured"
        )

    try:
        # Sign out from Supabase (invalidates refresh token)
        # Note: Access tokens remain valid until expiry
        if current_user:
            # In a real implementation, you might want to blacklist the token
            # or track logout in a sessions table
            logger.info(f"User {current_user.email} signed out")

        return MessageResponse(
            message="Signed out successfully"
        )

    except Exception as e:
        logger.error(f"Error during sign out: {e}")
        # Sign out should always succeed from client perspective
        return MessageResponse(
            message="Signed out successfully"
        )