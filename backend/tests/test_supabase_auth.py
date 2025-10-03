"""
Test Supabase Authentication

Tests for Supabase authentication integration
"""
import pytest
import pytest_asyncio
import uuid
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from models.user import User
from config import get_settings

settings = get_settings()


@pytest.mark.asyncio
@pytest.mark.skipif(
    not settings.supabase_url or not settings.supabase_service_role_key,
    reason="Supabase not configured"
)
async def test_supabase_signup(api_client: AsyncClient, db_session: AsyncSession):
    """Test user signup with Supabase auth"""
    # Generate unique email
    test_email = f"test_supabase_{uuid.uuid4().hex[:8]}@example.com"
    test_password = "SecurePassword123!"
    test_name = "Test User Supabase"

    # Sign up
    response = await api_client.post(
        "/api/v1/auth/signup",
        json={
            "email": test_email,
            "password": test_password,
            "name": test_name
        }
    )

    # If Supabase is properly configured, this should succeed
    if response.status_code == 503:
        pytest.skip("Supabase authentication service not available")

    assert response.status_code == 200, f"Signup failed: {response.text}"
    data = response.json()

    # Verify response structure
    assert "access_token" in data
    assert "refresh_token" in data
    assert "user" in data
    assert data["user"]["email"] == test_email
    assert data["token_type"] == "Bearer"

    # Verify user was created in database
    result = await db_session.execute(
        select(User).where(User.email == test_email)
    )
    user = result.scalar_one_or_none()

    assert user is not None
    assert user.email == test_email
    assert user.name == test_name
    assert user.auth_provider == "supabase"
    assert user.supabase_id is not None
    assert user.password_hash is None  # Supabase users don't have local password hash

    # Clean up - delete from local DB
    # Note: Supabase user will remain in Supabase (requires admin API to delete)
    await db_session.delete(user)
    await db_session.commit()


@pytest.mark.asyncio
@pytest.mark.skipif(
    not settings.supabase_url or not settings.supabase_service_role_key,
    reason="Supabase not configured"
)
async def test_supabase_signin(api_client: AsyncClient, db_session: AsyncSession):
    """Test user signin with Supabase auth"""
    # For this test to work, you need a pre-existing Supabase user
    # Or create one first with signup

    # Generate unique email
    test_email = f"test_signin_{uuid.uuid4().hex[:8]}@example.com"
    test_password = "SecurePassword123!"

    # First, sign up
    signup_response = await client.post(
        "/api/v1/auth/signup",
        json={
            "email": test_email,
            "password": test_password,
        }
    )

    if signup_response.status_code == 503:
        pytest.skip("Supabase authentication service not available")

    assert signup_response.status_code == 200

    # Now sign in
    signin_response = await client.post(
        "/api/v1/auth/signin",
        json={
            "email": test_email,
            "password": test_password,
        }
    )

    assert signin_response.status_code == 200, f"Signin failed: {signin_response.text}"
    data = signin_response.json()

    # Verify response structure
    assert "access_token" in data
    assert "refresh_token" in data
    assert "user" in data
    assert data["user"]["email"] == test_email

    # Clean up
    result = await db_session.execute(
        select(User).where(User.email == test_email)
    )
    user = result.scalar_one_or_none()
    if user:
        await db_session.delete(user)
        await db_session.commit()


@pytest.mark.asyncio
@pytest.mark.skipif(
    not settings.supabase_url or not settings.supabase_service_role_key,
    reason="Supabase not configured"
)
async def test_supabase_signin_wrong_password(api_client: AsyncClient, db_session: AsyncSession):
    """Test signin with wrong password fails"""
    # Create user first
    test_email = f"test_wrongpass_sb_{uuid.uuid4().hex[:8]}@example.com"
    test_password = "SecurePassword123!"

    # Sign up
    signup_response = await client.post(
        "/api/v1/auth/signup",
        json={
            "email": test_email,
            "password": test_password,
        }
    )

    if signup_response.status_code == 503:
        pytest.skip("Supabase authentication service not available")

    assert signup_response.status_code == 200

    # Try signin with wrong password
    signin_response = await client.post(
        "/api/v1/auth/signin",
        json={
            "email": test_email,
            "password": "WrongPassword123!",
        }
    )

    assert signin_response.status_code == 401  # Unauthorized

    # Clean up
    result = await db_session.execute(
        select(User).where(User.email == test_email)
    )
    user = result.scalar_one_or_none()
    if user:
        await db_session.delete(user)
        await db_session.commit()


@pytest.mark.asyncio
@pytest.mark.skipif(
    not settings.supabase_url or not settings.supabase_service_role_key,
    reason="Supabase not configured"
)
async def test_supabase_token_refresh(api_client: AsyncClient, db_session: AsyncSession):
    """Test token refresh with Supabase"""
    # Create user and get tokens
    test_email = f"test_refresh_{uuid.uuid4().hex[:8]}@example.com"
    test_password = "SecurePassword123!"

    # Sign up
    signup_response = await client.post(
        "/api/v1/auth/signup",
        json={
            "email": test_email,
            "password": test_password,
        }
    )

    if signup_response.status_code == 503:
        pytest.skip("Supabase authentication service not available")

    assert signup_response.status_code == 200
    refresh_token = signup_response.json()["refresh_token"]

    # Refresh token
    refresh_response = await client.post(
        "/api/v1/auth/refresh",
        json={"refresh_token": refresh_token}
    )

    assert refresh_response.status_code == 200, f"Token refresh failed: {refresh_response.text}"
    data = refresh_response.json()

    assert "access_token" in data
    assert "refresh_token" in data

    # Clean up
    result = await db_session.execute(
        select(User).where(User.email == test_email)
    )
    user = result.scalar_one_or_none()
    if user:
        await db_session.delete(user)
        await db_session.commit()


@pytest.mark.asyncio
async def test_supabase_not_configured_gracefully():
    """Test that when Supabase is not configured, endpoints return proper error"""
    # This test ensures graceful degradation when Supabase credentials are missing
    if settings.supabase_url and settings.supabase_service_role_key:
        pytest.skip("Supabase is configured, skipping not-configured test")

    # If we get here, Supabase is not configured
    # The auth service should handle this gracefully
    from services.auth.auth_service import auth_service
    assert auth_service.client is None or settings.supabase_url == ""
