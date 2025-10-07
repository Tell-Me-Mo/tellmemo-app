"""
Native Authentication Service

This module provides authentication services using JWT tokens and bcrypt
for password hashing, without requiring external authentication providers.
"""

from typing import Optional, Dict, Any
from datetime import datetime, timedelta, timezone
import jwt
import logging
from utils.logger import sanitize_for_log
import secrets
import bcrypt
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, or_

from config import get_settings
from models.user import User

logger = logging.getLogger(__name__)
settings = get_settings()


class NativeAuthService:
    """Service for managing native authentication with JWT and bcrypt"""

    def __init__(self):
        """Initialize native auth service with JWT configuration"""
        # Use JWT secret from config or generate a temporary one (should set in .env)
        self.jwt_secret = settings.jwt_secret if settings.jwt_secret else secrets.token_urlsafe(32)
        if not settings.jwt_secret:
            logger.warning("JWT_SECRET not set in environment. Using temporary secret. Set JWT_SECRET in .env for production!")
        self.jwt_algorithm = "HS256"
        self.access_token_expire_minutes = settings.access_token_expire_minutes
        self.refresh_token_expire_days = settings.refresh_token_expire_days

    def hash_password(self, password: str) -> str:
        """
        Hash a password using bcrypt

        Args:
            password: Plain text password

        Returns:
            Hashed password
        """
        # Generate salt and hash password
        salt = bcrypt.gensalt()
        hashed = bcrypt.hashpw(password.encode('utf-8'), salt)
        return hashed.decode('utf-8')

    def verify_password(self, plain_password: str, hashed_password: str) -> bool:
        """
        Verify a password against its hash

        Args:
            plain_password: Plain text password to verify
            hashed_password: Hashed password to compare against

        Returns:
            True if password matches, False otherwise
        """
        return bcrypt.checkpw(
            plain_password.encode('utf-8'),
            hashed_password.encode('utf-8')
        )

    def create_access_token(self, user_id: str, email: str, organization_id: Optional[str] = None) -> str:
        """
        Create a JWT access token

        Args:
            user_id: User ID
            email: User email
            organization_id: Optional organization ID

        Returns:
            JWT access token string
        """
        expire = datetime.now(timezone.utc) + timedelta(minutes=self.access_token_expire_minutes)

        payload = {
            "sub": user_id,
            "email": email,
            "exp": expire,
            "iat": datetime.now(timezone.utc),
            "type": "access"
        }

        if organization_id:
            payload["organization_id"] = organization_id

        return jwt.encode(payload, self.jwt_secret, algorithm=self.jwt_algorithm)

    def create_refresh_token(self, user_id: str) -> str:
        """
        Create a JWT refresh token

        Args:
            user_id: User ID

        Returns:
            JWT refresh token string
        """
        expire = datetime.now(timezone.utc) + timedelta(days=self.refresh_token_expire_days)

        payload = {
            "sub": user_id,
            "exp": expire,
            "iat": datetime.now(timezone.utc),
            "type": "refresh"
        }

        return jwt.encode(payload, self.jwt_secret, algorithm=self.jwt_algorithm)

    def verify_jwt_token(self, token: str) -> Optional[Dict[str, Any]]:
        """
        Verify a JWT token

        Args:
            token: JWT token string

        Returns:
            Decoded token payload if valid, None otherwise
        """
        try:
            payload = jwt.decode(
                token,
                self.jwt_secret,
                algorithms=[self.jwt_algorithm]
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

    async def register_user(
        self,
        db: AsyncSession,
        email: str,
        password: str,
        name: Optional[str] = None
    ) -> Optional[User]:
        """
        Register a new user with native authentication

        Args:
            db: Database session
            email: User email
            password: Plain text password
            name: Optional user name

        Returns:
            Created User instance or None if user already exists
        """
        # Check if user already exists
        result = await db.execute(
            select(User).where(User.email == email)
        )
        existing_user = result.scalar_one_or_none()

        if existing_user:
            logger.warning(f"User with email {email} already exists")
            return None

        try:
            # Hash password
            password_hash = self.hash_password(password)

            # Create new user
            user = User(
                email=email,
                password_hash=password_hash,
                name=name,
                auth_provider='native',
                supabase_id=None,
                email_verified=False,  # Set to True if you want to skip email verification
                is_active=True
            )

            db.add(user)
            await db.commit()
            await db.refresh(user)

            logger.info(f"Created new native auth user: {email}")
            return user

        except Exception as e:
            await db.rollback()
            logger.error(f"Error creating user: {e}")
            raise

    async def authenticate_user(
        self,
        db: AsyncSession,
        email: str,
        password: str
    ) -> Optional[User]:
        """
        Authenticate a user with email and password

        Args:
            db: Database session
            email: User email
            password: Plain text password

        Returns:
            User instance if authentication successful, None otherwise
        """
        # Get user by email
        result = await db.execute(
            select(User).where(
                User.email == email,
                User.auth_provider == 'native'
            )
        )
        user = result.scalar_one_or_none()

        if not user:
            logger.warning(f"User not found or not using native auth: {email}")
            return None

        if not user.password_hash:
            logger.warning(f"User has no password hash: {email}")
            return None

        # Verify password
        if not self.verify_password(password, user.password_hash):
            logger.warning(f"Invalid password for user: {email}")
            return None

        # Check if user is active
        if not user.is_active:
            logger.warning(f"User is not active: {email}")
            return None

        # Update last login (use UTC naive datetime for PostgreSQL compatibility)
        now = datetime.now(timezone.utc).replace(tzinfo=None)
        user.last_login_at = now
        user.updated_at = now
        await db.commit()

        return user

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
        user_id = payload.get("sub")
        if not user_id:
            logger.warning("No user ID in token payload")
            return None

        # Get user from database
        result = await db.execute(
            select(User).where(
                User.id == user_id,
                User.auth_provider == 'native'
            )
        )
        user = result.scalar_one_or_none()

        return user

    async def update_password(
        self,
        db: AsyncSession,
        user: User,
        new_password: str
    ) -> bool:
        """
        Update user password

        Args:
            db: Database session
            user: User instance
            new_password: New plain text password

        Returns:
            True if successful, False otherwise
        """
        try:
            user.password_hash = self.hash_password(new_password)
            user.updated_at = datetime.now(timezone.utc).replace(tzinfo=None)
            await db.commit()
            return True
        except Exception as e:
            await db.rollback()
            logger.error(f"Error updating password: {e}")
            return False

    async def update_user_profile(
        self,
        db: AsyncSession,
        user: User,
        name: Optional[str] = None,
        avatar_url: Optional[str] = None,
        preferences: Optional[Dict[str, Any]] = None
    ) -> User:
        """
        Update user profile

        Args:
            db: Database session
            user: User instance
            name: Optional new name
            avatar_url: Optional new avatar URL
            preferences: Optional new preferences

        Returns:
            Updated User instance
        """
        try:
            if name is not None:
                user.name = name
            if avatar_url is not None:
                user.avatar_url = avatar_url
            if preferences is not None:
                user.preferences = preferences

            user.updated_at = datetime.now(timezone.utc).replace(tzinfo=None)
            await db.commit()
            await db.refresh(user)
            return user

        except Exception as e:
            await db.rollback()
            logger.error(f"Error updating user profile: {e}")
            raise


# Singleton instance
native_auth_service = NativeAuthService()
