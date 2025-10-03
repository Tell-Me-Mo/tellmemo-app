"""
Test Native Authentication

Tests for native backend authentication with JWT and bcrypt
"""
import pytest
import pytest_asyncio
import uuid
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from models.user import User
from services.auth.native_auth_service import native_auth_service


@pytest.mark.asyncio
async def test_native_signup(api_client: AsyncClient, db_session: AsyncSession):
    """Test user signup with native auth"""
    # Generate unique email
    test_email = f"test_native_{uuid.uuid4().hex[:8]}@example.com"
    test_password = "SecurePassword123!"
    test_name = "Test User Native"

    # Sign up
    response = await api_client.post(
        "/api/auth/signup",
        json={
            "email": test_email,
            "password": test_password,
            "name": test_name
        }
    )

    assert response.status_code == 200, f"Signup failed: {response.text}"
    data = response.json()

    # Verify response structure
    assert "access_token" in data
    assert "refresh_token" in data
    assert "user_id" in data
    assert "email" in data
    assert data["email"] == test_email
    assert data["token_type"] == "Bearer"

    # Verify user was created in database
    result = await db_session.execute(
        select(User).where(User.email == test_email)
    )
    user = result.scalar_one_or_none()

    assert user is not None
    assert user.email == test_email
    assert user.name == test_name
    assert user.auth_provider == "native"
    assert user.password_hash is not None
    assert user.supabase_id is None

    # Clean up
    await db_session.delete(user)
    await db_session.commit()


@pytest.mark.asyncio
async def test_native_signup_duplicate_email(api_client: AsyncClient, db_session: AsyncSession):
    """Test that duplicate email signup fails"""
    test_email = f"test_duplicate_{uuid.uuid4().hex[:8]}@example.com"
    test_password = "SecurePassword123!"

    # First signup
    response1 = await api_client.post(
        "/api/auth/signup",
        json={
            "email": test_email,
            "password": test_password,
        }
    )
    assert response1.status_code == 200

    # Second signup with same email should fail
    response2 = await api_client.post(
        "/api/auth/signup",
        json={
            "email": test_email,
            "password": test_password,
        }
    )
    assert response2.status_code == 409  # Conflict

    # Clean up
    result = await db_session.execute(
        select(User).where(User.email == test_email)
    )
    user = result.scalar_one_or_none()
    if user:
        await db_session.delete(user)
        await db_session.commit()


@pytest.mark.asyncio
async def test_native_login(api_client: AsyncClient, db_session: AsyncSession):
    """Test user login with native auth"""
    # Create user first
    test_email = f"test_login_{uuid.uuid4().hex[:8]}@example.com"
    test_password = "SecurePassword123!"

    # Sign up
    signup_response = await api_client.post(
        "/api/auth/signup",
        json={
            "email": test_email,
            "password": test_password,
        }
    )
    assert signup_response.status_code == 200

    # Login
    login_response = await api_client.post(
        "/api/auth/login",
        json={
            "email": test_email,
            "password": test_password,
        }
    )

    assert login_response.status_code == 200, f"Login failed: {login_response.text}"
    data = login_response.json()

    # Verify response structure
    assert "access_token" in data
    assert "refresh_token" in data
    assert "user_id" in data
    assert "email" in data
    assert data["email"] == test_email

    # Clean up
    result = await db_session.execute(
        select(User).where(User.email == test_email)
    )
    user = result.scalar_one_or_none()
    if user:
        await db_session.delete(user)
        await db_session.commit()


@pytest.mark.asyncio
async def test_native_login_wrong_password(api_client: AsyncClient, db_session: AsyncSession):
    """Test login with wrong password fails"""
    # Create user first
    test_email = f"test_wrongpass_{uuid.uuid4().hex[:8]}@example.com"
    test_password = "SecurePassword123!"

    # Sign up
    signup_response = await api_client.post(
        "/api/auth/signup",
        json={
            "email": test_email,
            "password": test_password,
        }
    )
    assert signup_response.status_code == 200

    # Try login with wrong password
    login_response = await api_client.post(
        "/api/auth/login",
        json={
            "email": test_email,
            "password": "WrongPassword123!",
        }
    )

    assert login_response.status_code == 401  # Unauthorized

    # Clean up
    result = await db_session.execute(
        select(User).where(User.email == test_email)
    )
    user = result.scalar_one_or_none()
    if user:
        await db_session.delete(user)
        await db_session.commit()


@pytest.mark.asyncio
async def test_native_verify_token(api_client: AsyncClient, db_session: AsyncSession):
    """Test token verification endpoint"""
    # Create user and get token
    test_email = f"test_verify_{uuid.uuid4().hex[:8]}@example.com"
    test_password = "SecurePassword123!"

    # Sign up
    signup_response = await api_client.post(
        "/api/auth/signup",
        json={
            "email": test_email,
            "password": test_password,
        }
    )
    assert signup_response.status_code == 200
    access_token = signup_response.json()["access_token"]

    # Verify token
    verify_response = await api_client.get(
        "/api/auth/verify-token",
        headers={"Authorization": f"Bearer {access_token}"}
    )

    assert verify_response.status_code == 200, f"Token verification failed: {verify_response.text}"
    data = verify_response.json()

    assert "user_id" in data
    assert "email" in data
    assert data["email"] == test_email

    # Clean up
    result = await db_session.execute(
        select(User).where(User.email == test_email)
    )
    user = result.scalar_one_or_none()
    if user:
        await db_session.delete(user)
        await db_session.commit()


@pytest.mark.asyncio
async def test_native_update_password(api_client: AsyncClient, db_session: AsyncSession):
    """Test password update"""
    # Create user and get token
    test_email = f"test_updatepass_{uuid.uuid4().hex[:8]}@example.com"
    old_password = "OldPassword123!"
    new_password = "NewPassword456!"

    # Sign up
    signup_response = await api_client.post(
        "/api/auth/signup",
        json={
            "email": test_email,
            "password": old_password,
        }
    )
    assert signup_response.status_code == 200
    access_token = signup_response.json()["access_token"]

    # Update password
    update_response = await api_client.put(
        "/api/auth/password",
        json={"new_password": new_password},
        headers={"Authorization": f"Bearer {access_token}"}
    )

    assert update_response.status_code == 200, f"Password update failed: {update_response.text}"

    # Try login with old password - should fail
    old_login_response = await api_client.post(
        "/api/auth/login",
        json={
            "email": test_email,
            "password": old_password,
        }
    )
    assert old_login_response.status_code == 401

    # Try login with new password - should succeed
    new_login_response = await api_client.post(
        "/api/auth/login",
        json={
            "email": test_email,
            "password": new_password,
        }
    )
    assert new_login_response.status_code == 200

    # Clean up
    result = await db_session.execute(
        select(User).where(User.email == test_email)
    )
    user = result.scalar_one_or_none()
    if user:
        await db_session.delete(user)
        await db_session.commit()


@pytest.mark.asyncio
async def test_native_logout(api_client: AsyncClient):
    """Test logout endpoint"""
    response = await api_client.post("/api/auth/logout")
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
