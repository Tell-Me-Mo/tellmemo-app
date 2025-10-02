"""
Supabase Authentication Service

This module provides authentication services using Supabase Auth for JWT token
validation, user session management, and synchronization between Supabase Auth
and the local User model.
"""

from typing import Optional, Dict, Any
from datetime import datetime, timedelta, timezone
import jwt
import logging
from uuid import UUID

from supabase import create_client, Client
from gotrue import Session, User as SupabaseUser
from gotrue.errors import AuthApiError
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from config import get_settings
from models.user import User
from models.organization import Organization
from models.organization_member import OrganizationMember

logger = logging.getLogger(__name__)
settings = get_settings()


class AuthService:
    """Service for managing authentication with Supabase"""

    def __init__(self):
        """Initialize Supabase client with service role key for admin operations"""
        if not settings.supabase_url or not settings.supabase_service_role_key:
            logger.warning("Supabase configuration not found. Authentication will be disabled.")
            self.client = None
        else:
            self.client: Client = create_client(
                settings.supabase_url,
                settings.supabase_service_role_key
            )
            self.jwt_secret = settings.supabase_jwt_secret

    def verify_jwt_token(self, token: str) -> Optional[Dict[str, Any]]:
        """
        Verify a JWT token from Supabase Auth

        Args:
            token: JWT token string

        Returns:
            Decoded token payload if valid, None otherwise
        """
        if not self.client or not self.jwt_secret:
            logger.error("Supabase not configured properly")
            return None

        try:
            # Decode and verify the JWT token
            payload = jwt.decode(
                token,
                self.jwt_secret,
                algorithms=["HS256"],
                options={"verify_aud": False}  # Supabase doesn't always set audience
            )

            # Check token expiration
            exp_timestamp = payload.get("exp")
            if exp_timestamp:
                exp_time = datetime.fromtimestamp(exp_timestamp, tz=timezone.utc)
                if exp_time < datetime.now(timezone.utc):
                    logger.warning("Token has expired")
                    return None

            return payload

        except jwt.ExpiredSignatureError:
            logger.warning("JWT token has expired")
            return None
        except jwt.InvalidTokenError as e:
            logger.warning(f"Invalid JWT token: {e}")
            return None
        except Exception as e:
            logger.error(f"Error verifying JWT token: {e}")
            return None

    async def get_or_create_user(
        self,
        db: AsyncSession,
        supabase_id: str,
        email: str,
        metadata: Optional[Dict[str, Any]] = None
    ) -> Optional[User]:
        """
        Get existing user or create new user from Supabase Auth data

        Args:
            db: Database session
            supabase_id: Supabase Auth user ID
            email: User email
            metadata: Additional user metadata from Supabase

        Returns:
            User model instance
        """
        # Check if user already exists by supabase_id OR email
        result = await db.execute(
            select(User).where(
                (User.supabase_id == supabase_id) | (User.email == email)
            )
        )
        user = result.scalar_one_or_none()

        if user:
            # Update supabase_id if it was missing (for users created before Supabase integration)
            if not user.supabase_id:
                user.supabase_id = supabase_id
            # Update last login time
            user.updated_at = datetime.now(timezone.utc)
            await db.commit()
            return user

        try:
            # Create new user
            user = User(
                supabase_id=supabase_id,
                email=email,
                name=metadata.get("name") if metadata else None,
                avatar_url=metadata.get("avatar_url") if metadata else None,
                email_verified=metadata.get("email_verified", False) if metadata else False,
                preferences=metadata.get("preferences", {}) if metadata else {},
            )

            db.add(user)
            await db.commit()
            await db.refresh(user)

            logger.info(f"Created new user with email: {email}")
            return user
        except Exception as e:
            # Handle race condition - if user was created by another request
            await db.rollback()

            # Try to fetch the user again
            result = await db.execute(
                select(User).where(
                    (User.supabase_id == supabase_id) | (User.email == email)
                )
            )
            user = result.scalar_one_or_none()

            if user:
                logger.info(f"User already exists (race condition handled): {email}")
                return user
            else:
                logger.error(f"Failed to create or retrieve user: {e}")
                raise

    async def sync_user_from_supabase(
        self,
        db: AsyncSession,
        supabase_user: SupabaseUser
    ) -> Optional[User]:
        """
        Sync user data from Supabase Auth to local database

        Args:
            db: Database session
            supabase_user: Supabase Auth user object

        Returns:
            Synced User model instance
        """
        metadata = supabase_user.user_metadata if supabase_user.user_metadata else {}

        return await self.get_or_create_user(
            db=db,
            supabase_id=str(supabase_user.id),
            email=supabase_user.email,
            metadata={
                **metadata,
                "email_verified": supabase_user.email_confirmed_at is not None
            }
        )

    async def get_user_from_token(
        self,
        db: AsyncSession,
        token: str
    ) -> Optional[User]:
        """
        Get user from JWT token

        Args:
            db: Database session
            token: JWT token string

        Returns:
            User if token is valid and user exists, None otherwise
        """
        payload = self.verify_jwt_token(token)
        if not payload:
            return None

        # Get user ID from token
        supabase_id = payload.get("sub")
        if not supabase_id:
            logger.warning("No user ID in token payload")
            return None

        # Get user from database
        result = await db.execute(
            select(User).where(User.supabase_id == supabase_id)
        )
        user = result.scalar_one_or_none()

        if not user:
            # Try to get user from Supabase and sync
            email = payload.get("email")
            if email:
                user = await self.get_or_create_user(
                    db=db,
                    supabase_id=supabase_id,
                    email=email,
                    metadata=payload.get("user_metadata", {})
                )

        return user

    async def refresh_token(self, refresh_token: str) -> Optional[Dict[str, Any]]:
        """
        Refresh an access token using a refresh token

        Args:
            refresh_token: Refresh token string

        Returns:
            New token data with access_token and refresh_token
        """
        if not self.client:
            logger.error("Supabase client not initialized")
            return None

        try:
            response = self.client.auth.refresh_session(refresh_token)

            if response and response.session:
                return {
                    "access_token": response.session.access_token,
                    "refresh_token": response.session.refresh_token,
                    "expires_in": response.session.expires_in,
                    "expires_at": response.session.expires_at,
                }

            return None

        except AuthApiError as e:
            logger.error(f"Error refreshing token: {e}")
            return None
        except Exception as e:
            logger.error(f"Unexpected error refreshing token: {e}")
            return None

    async def get_user_organization(
        self,
        db: AsyncSession,
        user: User,
        organization_id: Optional[UUID] = None
    ) -> Optional[Organization]:
        """
        Get user's current organization

        Args:
            db: Database session
            user: User model instance
            organization_id: Optional specific organization ID to switch to

        Returns:
            Organization if user is a member, None otherwise
        """
        if organization_id:
            # Check if user is member of specified organization
            result = await db.execute(
                select(Organization)
                .join(OrganizationMember)
                .where(
                    OrganizationMember.user_id == user.id,
                    OrganizationMember.organization_id == organization_id,
                    Organization.id == organization_id,
                    Organization.is_active == True
                )
            )
            organization = result.scalar_one_or_none()

            if organization:
                # Update user's last active organization
                user.last_active_organization_id = organization.id
                await db.commit()
                return organization

        # Get user's last active organization
        if user.last_active_organization_id:
            result = await db.execute(
                select(Organization)
                .join(OrganizationMember)
                .where(
                    OrganizationMember.user_id == user.id,
                    Organization.id == user.last_active_organization_id,
                    Organization.is_active == True
                )
            )
            organization = result.scalar_one_or_none()

            if organization:
                return organization

        # Get user's first available organization
        result = await db.execute(
            select(Organization)
            .join(OrganizationMember)
            .where(
                OrganizationMember.user_id == user.id,
                Organization.is_active == True
            )
            .order_by(OrganizationMember.joined_at)
            .limit(1)
        )
        organization = result.scalar_one_or_none()

        if organization:
            # Update user's last active organization
            user.last_active_organization_id = organization.id
            await db.commit()

        return organization

    async def validate_user_role(
        self,
        db: AsyncSession,
        user: User,
        organization: Organization,
        required_role: Optional[str] = None
    ) -> Optional[str]:
        """
        Validate user's role in an organization

        Args:
            db: Database session
            user: User model instance
            organization: Organization model instance
            required_role: Optional required role ('admin', 'member', 'viewer')

        Returns:
            User's role in the organization if valid, None otherwise
        """
        result = await db.execute(
            select(OrganizationMember.role)
            .where(
                OrganizationMember.user_id == user.id,
                OrganizationMember.organization_id == organization.id
            )
        )
        role = result.scalar_one_or_none()

        if not role:
            return None

        if required_role:
            # Check role hierarchy
            role_hierarchy = {
                'viewer': 0,
                'member': 1,
                'admin': 2
            }

            if role_hierarchy.get(role, -1) < role_hierarchy.get(required_role, 999):
                return None

        return role


# Singleton instance
auth_service = AuthService()