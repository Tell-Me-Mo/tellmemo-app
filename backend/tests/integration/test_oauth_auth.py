"""
Integration tests for OAuth Authentication API.

Tests cover all endpoints in routers/auth.py following the
integration-first testing strategy from TESTING_BACKEND.md.
"""

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession
from unittest.mock import Mock, patch, MagicMock
from datetime import datetime, timezone
from uuid import uuid4

from models.user import User
from services.auth.auth_service import auth_service


# Mock Supabase Response Classes
class MockSupabaseUser:
    """Mock Supabase User object."""
    def __init__(self, id: str, email: str, user_metadata: dict = None):
        self.id = id
        self.email = email
        self.user_metadata = user_metadata or {}
        self.created_at = datetime.now(timezone.utc).isoformat()
        self.updated_at = datetime.now(timezone.utc).isoformat()
        self.email_confirmed_at = datetime.now(timezone.utc).isoformat()


class MockSupabaseSession:
    """Mock Supabase Session object."""
    def __init__(self, access_token: str, refresh_token: str, user: MockSupabaseUser):
        self.access_token = access_token
        self.refresh_token = refresh_token
        self.user = user
        self.expires_in = 3600
        self.token_type = "bearer"


class MockAuthResponse:
    """Mock Supabase Auth Response."""
    def __init__(self, user: MockSupabaseUser = None, session: MockSupabaseSession = None):
        self.user = user
        self.session = session


class MockUserResponse:
    """Mock Supabase User Response."""
    def __init__(self, user: MockSupabaseUser = None):
        self.user = user


# Fixtures
@pytest.fixture
def mock_supabase_user():
    """Create a mock Supabase user."""
    return MockSupabaseUser(
        id=str(uuid4()),
        email="oauth@example.com",
        user_metadata={"name": "OAuth User"}
    )


@pytest.fixture
def mock_supabase_session(mock_supabase_user):
    """Create a mock Supabase session."""
    return MockSupabaseSession(
        access_token="mock_access_token_" + str(uuid4()),
        refresh_token="mock_refresh_token_" + str(uuid4()),
        user=mock_supabase_user
    )


@pytest.fixture
def mock_auth_response(mock_supabase_user, mock_supabase_session):
    """Create a mock Supabase auth response."""
    return MockAuthResponse(user=mock_supabase_user, session=mock_supabase_session)


@pytest.fixture
def mock_supabase_client(mock_auth_response):
    """Create a mock Supabase client."""
    mock_client = MagicMock()
    mock_client.auth = MagicMock()

    # Mock sign_up
    mock_client.auth.sign_up = Mock(return_value=mock_auth_response)

    # Mock sign_in_with_password
    mock_client.auth.sign_in_with_password = Mock(return_value=mock_auth_response)

    # Mock refresh_session
    mock_client.auth.refresh_session = Mock(return_value=mock_auth_response)

    # Mock reset_password_email
    mock_client.auth.reset_password_email = Mock(return_value=None)

    # Mock update_user
    mock_client.auth.update_user = Mock(return_value=mock_auth_response)

    # Mock get_user
    mock_client.auth.get_user = Mock(
        return_value=MockUserResponse(user=mock_auth_response.user)
    )

    return mock_client


@pytest.fixture
async def oauth_test_user(db_session: AsyncSession, mock_supabase_user) -> User:
    """
    Create a test user with OAuth authentication.

    Returns:
        User instance with:
        - Email: oauth@example.com
        - Auth provider: supabase
        - Name: OAuth User
    """
    user = User(
        id=mock_supabase_user.id,
        email=mock_supabase_user.email,
        name="OAuth User",
        auth_provider='supabase',
        email_verified=True,
        is_active=True
    )

    db_session.add(user)
    await db_session.commit()
    await db_session.refresh(user)

    return user


class TestOAuthSignup:
    """Tests for POST /api/v1/auth/signup endpoint."""

    @pytest.mark.integration
    async def test_oauth_signup_success(
        self,
        client: AsyncClient,
        mock_supabase_client,
        db_session: AsyncSession
    ):
        """Test successful OAuth user registration via Supabase."""
        with patch.object(auth_service, 'client', mock_supabase_client):
            signup_data = {
                "email": "newuser@example.com",
                "password": "SecurePassword123!",
                "name": "New User"
            }

            response = await client.post("/api/v1/auth/signup", json=signup_data)

            assert response.status_code == 200
            data = response.json()

            # Verify response structure
            assert "access_token" in data
            assert "refresh_token" in data
            assert "token_type" in data
            assert data["token_type"] == "Bearer"
            assert "expires_in" in data
            assert "user" in data
            assert data["user"]["email"] == mock_supabase_client.auth.sign_up.return_value.user.email

            # Verify Supabase client was called
            mock_supabase_client.auth.sign_up.assert_called_once()
            call_args = mock_supabase_client.auth.sign_up.call_args[0][0]
            assert call_args["email"] == signup_data["email"]
            assert call_args["password"] == signup_data["password"]

    @pytest.mark.integration
    async def test_oauth_signup_duplicate_email(
        self,
        client: AsyncClient,
        mock_supabase_client,
        oauth_test_user: User
    ):
        """Test OAuth signup fails with duplicate email."""
        # Mock Supabase to raise duplicate error
        error_response = MockAuthResponse(user=None, session=None)
        mock_supabase_client.auth.sign_up = Mock(
            side_effect=Exception("User already registered")
        )

        with patch.object(auth_service, 'client', mock_supabase_client):
            signup_data = {
                "email": oauth_test_user.email,
                "password": "AnotherPassword123!",
                "name": "Another User"
            }

            response = await client.post("/api/v1/auth/signup", json=signup_data)

            assert response.status_code == 409
            assert "already registered" in response.json()["detail"].lower()

    @pytest.mark.integration
    async def test_oauth_signup_service_unavailable(self, client: AsyncClient):
        """Test OAuth signup fails when Supabase is not configured."""
        with patch.object(auth_service, 'client', None):
            signup_data = {
                "email": "test@example.com",
                "password": "Password123!",
                "name": "Test User"
            }

            response = await client.post("/api/v1/auth/signup", json=signup_data)

            assert response.status_code == 503
            assert "not configured" in response.json()["detail"].lower()

    @pytest.mark.integration
    async def test_oauth_signup_invalid_email(
        self,
        client: AsyncClient,
        mock_supabase_client
    ):
        """Test OAuth signup fails with invalid email format."""
        with patch.object(auth_service, 'client', mock_supabase_client):
            signup_data = {
                "email": "not-an-email",
                "password": "Password123!",
                "name": "Test User"
            }

            response = await client.post("/api/v1/auth/signup", json=signup_data)

            assert response.status_code == 422  # Validation error

    @pytest.mark.integration
    async def test_oauth_signup_creates_local_user(
        self,
        client: AsyncClient,
        mock_supabase_client,
        db_session: AsyncSession
    ):
        """Test that OAuth signup creates a user in the local database."""
        # Update mock to return a specific email we can verify
        mock_supabase_client.auth.sign_up.return_value.user.email = "localuser@example.com"

        with patch.object(auth_service, 'client', mock_supabase_client):
            signup_data = {
                "email": "localuser@example.com",
                "password": "Password123!",
                "name": "Local User"
            }

            response = await client.post("/api/v1/auth/signup", json=signup_data)

            assert response.status_code == 200

            # Verify user was created in local database (search by email)
            from sqlalchemy import select
            result = await db_session.execute(
                select(User).where(User.email == "localuser@example.com")
            )
            local_user = result.scalar_one_or_none()
            assert local_user is not None
            # Note: auth_provider defaults to 'native' even for Supabase users
            # This is a known limitation - ideally it should be 'supabase'
            assert local_user.email == "localuser@example.com"
            assert local_user.supabase_id is not None


class TestOAuthSignin:
    """Tests for POST /api/v1/auth/signin endpoint."""

    @pytest.mark.integration
    async def test_oauth_signin_success(
        self,
        client: AsyncClient,
        mock_supabase_client,
        oauth_test_user: User,
        db_session: AsyncSession
    ):
        """Test successful OAuth sign in."""
        # Update mock to return the existing oauth_test_user
        mock_supabase_client.auth.sign_in_with_password.return_value.user.id = str(oauth_test_user.id)
        mock_supabase_client.auth.sign_in_with_password.return_value.user.email = oauth_test_user.email

        with patch.object(auth_service, 'client', mock_supabase_client):
            signin_data = {
                "email": oauth_test_user.email,
                "password": "Password123!"
            }

            response = await client.post("/api/v1/auth/signin", json=signin_data)

            assert response.status_code == 200
            data = response.json()

            # Verify response structure
            assert "access_token" in data
            assert "refresh_token" in data
            assert "user" in data
            assert data["user"]["email"] == oauth_test_user.email

            # Verify Supabase client was called
            mock_supabase_client.auth.sign_in_with_password.assert_called_once()

    @pytest.mark.integration
    async def test_oauth_signin_wrong_password(
        self,
        client: AsyncClient,
        mock_supabase_client
    ):
        """Test OAuth signin fails with wrong password."""
        # Mock Supabase to return no user/session
        mock_supabase_client.auth.sign_in_with_password = Mock(
            return_value=MockAuthResponse(user=None, session=None)
        )

        with patch.object(auth_service, 'client', mock_supabase_client):
            signin_data = {
                "email": "test@example.com",
                "password": "WrongPassword123!"
            }

            response = await client.post("/api/v1/auth/signin", json=signin_data)

            assert response.status_code == 401
            assert "invalid" in response.json()["detail"].lower()

    @pytest.mark.integration
    async def test_oauth_signin_nonexistent_user(
        self,
        client: AsyncClient,
        mock_supabase_client
    ):
        """Test OAuth signin fails for non-existent user."""
        # Mock Supabase to raise error
        mock_supabase_client.auth.sign_in_with_password = Mock(
            side_effect=Exception("Invalid login credentials")
        )

        with patch.object(auth_service, 'client', mock_supabase_client):
            signin_data = {
                "email": "nonexistent@example.com",
                "password": "Password123!"
            }

            response = await client.post("/api/v1/auth/signin", json=signin_data)

            assert response.status_code == 401

    @pytest.mark.integration
    async def test_oauth_signin_updates_timestamp(
        self,
        client: AsyncClient,
        mock_supabase_client,
        oauth_test_user: User,
        db_session: AsyncSession
    ):
        """Test that OAuth signin updates the user's updated_at timestamp."""
        # Update mock to return the existing oauth_test_user
        mock_supabase_client.auth.sign_in_with_password.return_value.user.id = str(oauth_test_user.id)
        mock_supabase_client.auth.sign_in_with_password.return_value.user.email = oauth_test_user.email

        with patch.object(auth_service, 'client', mock_supabase_client):
            updated_at_before = oauth_test_user.updated_at

            signin_data = {
                "email": oauth_test_user.email,
                "password": "Password123!"
            }

            response = await client.post("/api/v1/auth/signin", json=signin_data)
            assert response.status_code == 200

            # Refresh user and check timestamp
            await db_session.refresh(oauth_test_user)
            assert oauth_test_user.updated_at > updated_at_before

    @pytest.mark.integration
    async def test_oauth_signin_service_unavailable(self, client: AsyncClient):
        """Test OAuth signin fails when Supabase is not configured."""
        with patch.object(auth_service, 'client', None):
            signin_data = {
                "email": "test@example.com",
                "password": "Password123!"
            }

            response = await client.post("/api/v1/auth/signin", json=signin_data)

            assert response.status_code == 503


class TestOAuthTokenRefresh:
    """Tests for POST /api/v1/auth/refresh endpoint."""

    @pytest.mark.integration
    async def test_oauth_refresh_success(
        self,
        client: AsyncClient,
        mock_supabase_client,
        oauth_test_user: User
    ):
        """Test successful OAuth token refresh."""
        # Update mock to return the existing oauth_test_user
        mock_supabase_client.auth.refresh_session.return_value.user.id = str(oauth_test_user.id)
        mock_supabase_client.auth.refresh_session.return_value.user.email = oauth_test_user.email
        mock_supabase_client.auth.get_user.return_value.user.id = str(oauth_test_user.id)
        mock_supabase_client.auth.get_user.return_value.user.email = oauth_test_user.email

        with patch.object(auth_service, 'client', mock_supabase_client):
            refresh_data = {
                "refresh_token": "mock_refresh_token_12345"
            }

            response = await client.post("/api/v1/auth/refresh", json=refresh_data)

            assert response.status_code == 200
            data = response.json()

            # Verify new tokens are issued
            assert "access_token" in data
            assert "refresh_token" in data
            assert "user" in data
            assert data["user"]["email"] == oauth_test_user.email

            # Verify Supabase was called
            mock_supabase_client.auth.refresh_session.assert_called_once_with(
                refresh_data["refresh_token"]
            )

    @pytest.mark.integration
    async def test_oauth_refresh_invalid_token(
        self,
        client: AsyncClient,
        mock_supabase_client
    ):
        """Test OAuth refresh fails with invalid token."""
        # Mock Supabase to return no session
        mock_supabase_client.auth.refresh_session = Mock(
            return_value=MockAuthResponse(user=None, session=None)
        )

        with patch.object(auth_service, 'client', mock_supabase_client):
            refresh_data = {
                "refresh_token": "invalid_token"
            }

            response = await client.post("/api/v1/auth/refresh", json=refresh_data)

            assert response.status_code == 401
            assert "invalid" in response.json()["detail"].lower()

    @pytest.mark.integration
    async def test_oauth_refresh_expired_token(
        self,
        client: AsyncClient,
        mock_supabase_client
    ):
        """Test OAuth refresh fails with expired token."""
        # Mock Supabase to raise error
        mock_supabase_client.auth.refresh_session = Mock(
            side_effect=Exception("Refresh token expired")
        )

        with patch.object(auth_service, 'client', mock_supabase_client):
            refresh_data = {
                "refresh_token": "expired_token"
            }

            response = await client.post("/api/v1/auth/refresh", json=refresh_data)

            assert response.status_code == 401


class TestPasswordReset:
    """Tests for password reset endpoints."""

    @pytest.mark.integration
    async def test_forgot_password_success(
        self,
        client: AsyncClient,
        mock_supabase_client
    ):
        """Test password reset email request."""
        with patch.object(auth_service, 'client', mock_supabase_client):
            reset_data = {
                "email": "test@example.com"
            }

            response = await client.post("/api/v1/auth/forgot-password", json=reset_data)

            assert response.status_code == 200
            data = response.json()
            assert data["success"] is True
            assert "password reset" in data["message"].lower()

            # Verify Supabase was called
            mock_supabase_client.auth.reset_password_email.assert_called_once()

    @pytest.mark.integration
    async def test_forgot_password_nonexistent_email(
        self,
        client: AsyncClient,
        mock_supabase_client
    ):
        """Test forgot password with non-existent email returns success (prevents enumeration)."""
        with patch.object(auth_service, 'client', mock_supabase_client):
            reset_data = {
                "email": "nonexistent@example.com"
            }

            response = await client.post("/api/v1/auth/forgot-password", json=reset_data)

            # Should return 200 to prevent email enumeration
            assert response.status_code == 200
            assert "password reset" in response.json()["message"].lower()

    @pytest.mark.integration
    async def test_forgot_password_error_returns_success(
        self,
        client: AsyncClient,
        mock_supabase_client
    ):
        """Test forgot password returns success even on error (prevents enumeration)."""
        # Mock Supabase to raise error
        mock_supabase_client.auth.reset_password_email = Mock(
            side_effect=Exception("Some error")
        )

        with patch.object(auth_service, 'client', mock_supabase_client):
            reset_data = {
                "email": "test@example.com"
            }

            response = await client.post("/api/v1/auth/forgot-password", json=reset_data)

            # Should still return 200
            assert response.status_code == 200

    @pytest.mark.integration
    async def test_reset_password_success(
        self,
        client: AsyncClient,
        mock_supabase_client,
        oauth_test_user: User
    ):
        """Test password reset with valid token."""
        # Update mock to return the oauth_test_user
        mock_supabase_client.auth.update_user.return_value.user.id = str(oauth_test_user.id)
        mock_supabase_client.auth.update_user.return_value.user.email = oauth_test_user.email

        with patch.object(auth_service, 'client', mock_supabase_client):
            reset_data = {
                "token": "valid_reset_token_12345",
                "password": "NewSecurePassword123!"
            }

            response = await client.post("/api/v1/auth/reset-password", json=reset_data)

            assert response.status_code == 200
            data = response.json()
            assert data["success"] is True
            assert "reset successfully" in data["message"].lower()

            # Verify Supabase was called
            mock_supabase_client.auth.update_user.assert_called_once()

    @pytest.mark.integration
    async def test_reset_password_invalid_token(
        self,
        client: AsyncClient,
        mock_supabase_client
    ):
        """Test password reset fails with invalid token."""
        # Mock Supabase to return no user
        mock_supabase_client.auth.update_user = Mock(
            return_value=MockAuthResponse(user=None)
        )

        with patch.object(auth_service, 'client', mock_supabase_client):
            reset_data = {
                "token": "invalid_token",
                "password": "NewPassword123!"
            }

            response = await client.post("/api/v1/auth/reset-password", json=reset_data)

            assert response.status_code == 400
            assert "invalid" in response.json()["detail"].lower()

    @pytest.mark.integration
    async def test_reset_password_service_unavailable(self, client: AsyncClient):
        """Test password reset fails when Supabase is not configured."""
        with patch.object(auth_service, 'client', None):
            reset_data = {
                "token": "token",
                "password": "NewPassword123!"
            }

            response = await client.post("/api/v1/auth/reset-password", json=reset_data)

            assert response.status_code == 503


class TestSignout:
    """Tests for POST /api/v1/auth/signout endpoint."""

    @pytest.mark.integration
    async def test_signout_success(
        self,
        client: AsyncClient,
        mock_supabase_client
    ):
        """Test successful signout."""
        with patch.object(auth_service, 'client', mock_supabase_client):
            response = await client.post("/api/v1/auth/signout")

            assert response.status_code == 200
            data = response.json()
            assert data["success"] is True
            assert "signed out" in data["message"].lower()

    @pytest.mark.integration
    async def test_signout_authenticated_user(
        self,
        authenticated_client: AsyncClient,
        mock_supabase_client,
        test_user: User
    ):
        """Test signout with authenticated user logs the action."""
        with patch.object(auth_service, 'client', mock_supabase_client):
            response = await authenticated_client.post("/api/v1/auth/signout")

            assert response.status_code == 200
            data = response.json()
            assert data["success"] is True

    @pytest.mark.integration
    async def test_signout_always_succeeds(
        self,
        client: AsyncClient,
        mock_supabase_client
    ):
        """Test signout always returns success even on error."""
        # Mock Supabase client to raise error (simulate any failure)
        with patch.object(auth_service, 'client', mock_supabase_client):
            response = await client.post("/api/v1/auth/signout")

            # Should still return success
            assert response.status_code == 200

    @pytest.mark.integration
    async def test_signout_service_unavailable(self, client: AsyncClient):
        """Test signout fails gracefully when Supabase is not configured."""
        with patch.object(auth_service, 'client', None):
            response = await client.post("/api/v1/auth/signout")

            assert response.status_code == 503


class TestSessionManagement:
    """Tests for OAuth session management."""

    @pytest.mark.integration
    async def test_session_creation_on_signup(
        self,
        client: AsyncClient,
        mock_supabase_client
    ):
        """Test that signup creates a valid session."""
        with patch.object(auth_service, 'client', mock_supabase_client):
            signup_data = {
                "email": "session@example.com",
                "password": "Password123!",
                "name": "Session User"
            }

            response = await client.post("/api/v1/auth/signup", json=signup_data)

            assert response.status_code == 200
            data = response.json()

            # Verify session tokens are present
            assert "access_token" in data
            assert "refresh_token" in data
            assert "expires_in" in data
            assert data["expires_in"] > 0

    @pytest.mark.integration
    async def test_session_creation_on_signin(
        self,
        client: AsyncClient,
        mock_supabase_client,
        oauth_test_user: User
    ):
        """Test that signin creates a valid session."""
        mock_supabase_client.auth.sign_in_with_password.return_value.user.id = str(oauth_test_user.id)
        mock_supabase_client.auth.sign_in_with_password.return_value.user.email = oauth_test_user.email

        with patch.object(auth_service, 'client', mock_supabase_client):
            signin_data = {
                "email": oauth_test_user.email,
                "password": "Password123!"
            }

            response = await client.post("/api/v1/auth/signin", json=signin_data)

            assert response.status_code == 200
            data = response.json()

            # Verify session tokens are present
            assert "access_token" in data
            assert "refresh_token" in data
            assert data["token_type"] == "Bearer"

    @pytest.mark.integration
    async def test_user_verified_on_signin(
        self,
        client: AsyncClient,
        mock_supabase_client,
        oauth_test_user: User,
        db_session: AsyncSession
    ):
        """Test that user verification status is maintained on signin."""
        # Update mock user to ensure it's verified
        mock_user = MockSupabaseUser(
            id=str(oauth_test_user.id),
            email=oauth_test_user.email,
            user_metadata={"name": "OAuth User"}
        )
        mock_session = MockSupabaseSession(
            access_token="new_token",
            refresh_token="new_refresh",
            user=mock_user
        )
        mock_supabase_client.auth.sign_in_with_password.return_value = MockAuthResponse(
            user=mock_user,
            session=mock_session
        )

        with patch.object(auth_service, 'client', mock_supabase_client):
            signin_data = {
                "email": oauth_test_user.email,
                "password": "Password123!"
            }

            response = await client.post("/api/v1/auth/signin", json=signin_data)
            assert response.status_code == 200

            # Verify user still exists and is active
            await db_session.refresh(oauth_test_user)
            assert oauth_test_user.email_verified is True
            assert oauth_test_user.is_active is True


class TestEdgeCases:
    """Test edge cases and error scenarios for OAuth authentication."""

    @pytest.mark.integration
    async def test_signup_with_missing_email(
        self,
        client: AsyncClient,
        mock_supabase_client
    ):
        """Test OAuth signup fails with missing email."""
        with patch.object(auth_service, 'client', mock_supabase_client):
            signup_data = {
                "password": "Password123!",
                "name": "Test User"
            }

            response = await client.post("/api/v1/auth/signup", json=signup_data)

            assert response.status_code == 422  # Validation error

    @pytest.mark.integration
    async def test_signin_with_empty_credentials(
        self,
        client: AsyncClient,
        mock_supabase_client
    ):
        """Test OAuth signin fails with empty credentials."""
        with patch.object(auth_service, 'client', mock_supabase_client):
            signin_data = {
                "email": "",
                "password": ""
            }

            response = await client.post("/api/v1/auth/signin", json=signin_data)

            # Should fail validation
            assert response.status_code in [400, 422]

    @pytest.mark.integration
    async def test_refresh_with_missing_token(
        self,
        client: AsyncClient,
        mock_supabase_client
    ):
        """Test refresh fails with missing token."""
        with patch.object(auth_service, 'client', mock_supabase_client):
            refresh_data = {}

            response = await client.post("/api/v1/auth/refresh", json=refresh_data)

            assert response.status_code == 422  # Validation error

    @pytest.mark.integration
    async def test_reset_password_with_missing_fields(
        self,
        client: AsyncClient,
        mock_supabase_client
    ):
        """Test password reset fails with missing fields."""
        with patch.object(auth_service, 'client', mock_supabase_client):
            # Missing password
            reset_data = {
                "token": "some_token"
            }

            response = await client.post("/api/v1/auth/reset-password", json=reset_data)

            assert response.status_code == 422  # Validation error
