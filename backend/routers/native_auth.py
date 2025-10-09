"""
Native Authentication API Router

This module provides authentication endpoints for user registration, login,
and password management using native JWT and bcrypt authentication.
"""

import logging
from typing import Optional
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, status, Request
from pydantic import BaseModel, EmailStr
from sqlalchemy.ext.asyncio import AsyncSession

from db import get_db
from services.auth.native_auth_service import native_auth_service
from models.user import User
from dependencies.auth import get_current_user_optional

logger = logging.getLogger(__name__)

router = APIRouter(
    prefix="/api/v1/auth",
    tags=["Native Authentication"]
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


class ResetPasswordRequest(BaseModel):
    """Request model for password reset initiation"""
    email: EmailStr


class UpdatePasswordRequest(BaseModel):
    """Request model for password update"""
    new_password: str


class UpdateProfileRequest(BaseModel):
    """Request model for profile update"""
    name: Optional[str] = None
    avatar_url: Optional[str] = None


class VerifyOTPRequest(BaseModel):
    """Request model for OTP verification"""
    email: EmailStr
    token: str


class RefreshTokenRequest(BaseModel):
    """Request model for token refresh"""
    refresh_token: str


class AuthResponse(BaseModel):
    """Response model for authentication operations"""
    access_token: str
    refresh_token: Optional[str] = None
    token_type: str = "Bearer"
    user_id: str
    email: str
    name: Optional[str] = None
    organization_id: Optional[str] = None


class MessageResponse(BaseModel):
    """Generic message response"""
    message: str
    success: bool = True


class UserInfoResponse(BaseModel):
    """User information response"""
    user_id: str
    email: str
    name: Optional[str] = None
    organization_id: Optional[str] = None


@router.post("/signup", response_model=AuthResponse)
async def sign_up(
    request_obj: Request,
    request: SignUpRequest,
    db: AsyncSession = Depends(get_db)
):
    """
    Register a new user account with native authentication

    Args:
        request: Sign up request with email and password
        db: Database session

    Returns:
        Authentication response with tokens and user data

    Raises:
        HTTPException: If registration fails
    """
    try:
        # Create user with native auth
        user = await native_auth_service.register_user(
            db=db,
            email=request.email,
            password=request.password,
            name=request.name
        )

        if not user:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Email already registered"
            )

        # Generate tokens
        access_token = native_auth_service.create_access_token(
            user_id=str(user.id),
            email=user.email,
            organization_id=str(user.last_active_organization_id) if user.last_active_organization_id else None
        )

        refresh_token = native_auth_service.create_refresh_token(
            user_id=str(user.id)
        )

        return AuthResponse(
            access_token=access_token,
            refresh_token=refresh_token,
            user_id=str(user.id),
            email=user.email,
            name=user.name,
            organization_id=str(user.last_active_organization_id) if user.last_active_organization_id else None
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error during sign up: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to create account"
        )


@router.post("/login", response_model=AuthResponse)
async def sign_in(
    request_obj: Request,
    request: SignInRequest,
    db: AsyncSession = Depends(get_db)
):
    """
    Sign in an existing user with native authentication

    Args:
        request: Sign in request with email and password
        db: Database session

    Returns:
        Authentication response with tokens and user data

    Raises:
        HTTPException: If authentication fails
    """
    try:
        # Authenticate user
        user = await native_auth_service.authenticate_user(
            db=db,
            email=request.email,
            password=request.password
        )

        if not user:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid email or password"
            )

        # Generate tokens
        access_token = native_auth_service.create_access_token(
            user_id=str(user.id),
            email=user.email,
            organization_id=str(user.last_active_organization_id) if user.last_active_organization_id else None
        )

        refresh_token = native_auth_service.create_refresh_token(
            user_id=str(user.id)
        )

        return AuthResponse(
            access_token=access_token,
            refresh_token=refresh_token,
            user_id=str(user.id),
            email=user.email,
            name=user.name,
            organization_id=str(user.last_active_organization_id) if user.last_active_organization_id else None
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error during sign in: {e}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authentication failed"
        )


@router.post("/logout", response_model=MessageResponse)
async def sign_out():
    """
    Sign out the current user

    Returns:
        Success message
    """
    # With JWT tokens, logout is handled client-side by removing the token
    # In a production environment, you might want to implement token blacklisting
    return MessageResponse(
        message="Signed out successfully"
    )


@router.post("/refresh", response_model=AuthResponse)
async def refresh_token(
    request: RefreshTokenRequest,
    db: AsyncSession = Depends(get_db)
):
    """
    Refresh access token using a valid refresh token

    Args:
        request: Refresh token request
        db: Database session

    Returns:
        New access and refresh tokens

    Raises:
        HTTPException: If refresh token is invalid or expired
    """
    try:
        # Verify refresh token
        payload = native_auth_service.verify_jwt_token(request.refresh_token)

        if not payload:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid or expired refresh token"
            )

        # Check token type
        if payload.get("type") != "refresh":
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token type"
            )

        # Get user ID from token
        user_id = payload.get("sub")
        if not user_id:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token payload"
            )

        # Get user from database
        from sqlalchemy import select
        result = await db.execute(
            select(User).where(
                User.id == user_id,
                User.auth_provider == 'native',
                User.is_active == True
            )
        )
        user = result.scalar_one_or_none()

        if not user:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="User not found or inactive"
            )

        # Generate new tokens
        access_token = native_auth_service.create_access_token(
            user_id=str(user.id),
            email=user.email,
            organization_id=str(user.last_active_organization_id) if user.last_active_organization_id else None
        )

        refresh_token = native_auth_service.create_refresh_token(
            user_id=str(user.id)
        )

        return AuthResponse(
            access_token=access_token,
            refresh_token=refresh_token,
            user_id=str(user.id),
            email=user.email,
            name=user.name,
            organization_id=str(user.last_active_organization_id) if user.last_active_organization_id else None
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error during token refresh: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Token refresh failed"
        )


@router.post("/reset-password", response_model=MessageResponse)
async def reset_password(request_obj: Request, request: ResetPasswordRequest):
    """
    Request a password reset (placeholder for email-based reset flow)

    Args:
        request: Reset password request with email

    Returns:
        Success message

    Note:
        In a production environment, this would send a password reset email
        For now, it returns a success message to avoid email enumeration
    """
    # TODO: Implement email-based password reset flow
    # For now, return success to avoid email enumeration
    return MessageResponse(
        message="If an account exists with this email, a password reset link has been sent."
    )


@router.put("/password", response_model=MessageResponse)
async def update_password(
    request: UpdatePasswordRequest,
    current_user: User = Depends(get_current_user_optional),
    db: AsyncSession = Depends(get_db)
):
    """
    Update user password (requires authentication)

    Args:
        request: Update password request with new password
        current_user: Current authenticated user
        db: Database session

    Returns:
        Success message

    Raises:
        HTTPException: If update fails
    """
    if not current_user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authentication required"
        )

    success = await native_auth_service.update_password(
        db=db,
        user=current_user,
        new_password=request.new_password
    )

    if not success:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to update password"
        )

    return MessageResponse(message="Password updated successfully")


@router.put("/profile", response_model=MessageResponse)
async def update_profile(
    request: UpdateProfileRequest,
    current_user: User = Depends(get_current_user_optional),
    db: AsyncSession = Depends(get_db)
):
    """
    Update user profile (requires authentication)

    Args:
        request: Update profile request
        current_user: Current authenticated user
        db: Database session

    Returns:
        Success message

    Raises:
        HTTPException: If update fails
    """
    if not current_user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authentication required"
        )

    try:
        await native_auth_service.update_user_profile(
            db=db,
            user=current_user,
            name=request.name,
            avatar_url=request.avatar_url
        )

        return MessageResponse(message="Profile updated successfully")

    except Exception as e:
        logger.error(f"Error updating profile: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to update profile"
        )


@router.get("/verify-token", response_model=UserInfoResponse)
async def verify_token(
    current_user: User = Depends(get_current_user_optional)
):
    """
    Verify JWT token and return user information

    Args:
        current_user: Current authenticated user

    Returns:
        User information

    Raises:
        HTTPException: If token is invalid
    """
    if not current_user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token"
        )

    return UserInfoResponse(
        user_id=str(current_user.id),
        email=current_user.email,
        name=current_user.name,
        organization_id=str(current_user.last_active_organization_id) if current_user.last_active_organization_id else None
    )


@router.post("/verify-otp", response_model=MessageResponse)
async def verify_otp(request: VerifyOTPRequest):
    """
    Verify OTP code (placeholder for OTP verification flow)

    Args:
        request: OTP verification request

    Returns:
        Success message

    Note:
        This is a placeholder. Implement actual OTP verification logic as needed.
    """
    # TODO: Implement OTP verification logic
    return MessageResponse(
        message="OTP verification not implemented for native auth"
    )
