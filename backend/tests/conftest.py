"""
Pytest configuration and shared fixtures for backend tests.

This module provides test fixtures following the integration-first testing strategy
outlined in TESTING_BACKEND.md.
"""

import os

# IMPORTANT: Set environment variables BEFORE any other imports
# This ensures that services initialize with correct configuration
os.environ["TESTING"] = "1"
os.environ["DATABASE_URL"] = os.getenv(
    "TEST_DATABASE_URL",
    "postgresql+asyncpg://pm_master:pm_master_pass@localhost:5432/pm_master_test"
)
# Set consistent JWT secret for tests
os.environ["JWT_SECRET"] = "test_jwt_secret_key_for_testing_only_do_not_use_in_production"
os.environ["AUTH_PROVIDER"] = "backend"  # Use backend auth for tests

import pytest
import asyncio
from typing import AsyncGenerator, Generator
from contextlib import asynccontextmanager
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine, async_sessionmaker
from sqlalchemy.pool import NullPool
from httpx import AsyncClient, ASGITransport
from datetime import datetime, timezone

from db.database import Base, get_db
from main import app
from models.user import User
from models.organization import Organization
from models.organization_member import OrganizationMember
from services.auth.native_auth_service import native_auth_service

# CRITICAL: Force native_auth_service to use test JWT secret
# The service was already initialized with a random secret before we set the env var
native_auth_service.jwt_secret = os.environ["JWT_SECRET"]

# Test database engine
TEST_DATABASE_URL = os.environ["DATABASE_URL"]

engine = create_async_engine(
    TEST_DATABASE_URL,
    echo=False,
    poolclass=NullPool,  # Disable connection pooling for tests
)

TestSessionLocal = async_sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autocommit=False,
    autoflush=False,
)


@pytest.fixture(scope="session")
def event_loop() -> Generator:
    """Create an event loop for the test session."""
    loop = asyncio.get_event_loop_policy().new_event_loop()
    yield loop
    loop.close()


@pytest.fixture(scope="function")
async def db_session() -> AsyncGenerator[AsyncSession, None]:
    """
    Create a fresh database session for each test.

    This fixture:
    - Creates all tables before the test
    - Yields a database session
    - Rolls back any changes and drops all tables after the test
    """
    # Create tables
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    # Create session
    async with TestSessionLocal() as session:
        yield session
        await session.rollback()

    # Drop tables
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)


@pytest.fixture(scope="function")
async def client(db_session: AsyncSession, monkeypatch) -> AsyncGenerator[AsyncClient, None]:
    """
    Create an async HTTP client for testing API endpoints.

    This fixture overrides both get_db and get_db_context to use the test database session.
    """
    async def override_get_db():
        yield db_session

    # Override dependency injection get_db
    app.dependency_overrides[get_db] = override_get_db

    # CRITICAL: Also override get_db_context for middleware using monkeypatch
    # The auth middleware uses get_db_context() directly, not the dependency injection
    @asynccontextmanager
    async def override_get_db_context():
        yield db_session

    # Patch it in both locations
    monkeypatch.setattr("db.database.get_db_context", override_get_db_context)
    monkeypatch.setattr("middleware.auth_middleware.get_db_context", override_get_db_context)

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac

    # Cleanup handled by monkeypatch
    app.dependency_overrides.clear()


@pytest.fixture
async def test_user(db_session: AsyncSession) -> User:
    """
    Create a test user with native authentication.

    Returns:
        User instance with:
        - Email: test@example.com
        - Password: TestPassword123!
        - Name: Test User
    """
    password_hash = native_auth_service.hash_password("TestPassword123!")

    user = User(
        email="test@example.com",
        password_hash=password_hash,
        name="Test User",
        auth_provider='native',
        email_verified=True,
        is_active=True
    )

    db_session.add(user)
    await db_session.commit()
    await db_session.refresh(user)

    return user


@pytest.fixture
async def test_user_token(test_user: User) -> str:
    """
    Create a valid access token for the test user (without organization context).

    Args:
        test_user: Test user fixture

    Returns:
        Valid JWT access token
    """
    return native_auth_service.create_access_token(
        user_id=str(test_user.id),
        email=test_user.email,
        organization_id=None
    )


@pytest.fixture
async def test_user_refresh_token(test_user: User) -> str:
    """
    Create a valid refresh token for the test user.

    Args:
        test_user: Test user fixture

    Returns:
        Valid JWT refresh token
    """
    return native_auth_service.create_refresh_token(
        user_id=str(test_user.id)
    )


@pytest.fixture
async def authenticated_client(
    client: AsyncClient,
    test_user_token: str
) -> AsyncClient:
    """
    Create an authenticated HTTP client with valid JWT token.

    Args:
        client: Base HTTP client
        test_user_token: Valid access token

    Returns:
        AsyncClient with Authorization header set
    """
    client.headers["Authorization"] = f"Bearer {test_user_token}"
    return client


@pytest.fixture
async def authenticated_org_client(
    client: AsyncClient,
    test_user: User,
    test_organization: Organization
) -> AsyncClient:
    """
    Create an authenticated HTTP client with organization context.

    Args:
        client: Base HTTP client
        test_user: Test user fixture
        test_organization: Test organization fixture

    Returns:
        AsyncClient with Authorization and X-Organization-Id headers set
    """
    token = native_auth_service.create_access_token(
        user_id=str(test_user.id),
        email=test_user.email,
        organization_id=str(test_organization.id)
    )
    client.headers["Authorization"] = f"Bearer {token}"
    client.headers["X-Organization-Id"] = str(test_organization.id)
    return client


@pytest.fixture
async def test_organization(db_session: AsyncSession, test_user: User) -> Organization:
    """
    Create a test organization with the test user as owner.

    Args:
        db_session: Database session
        test_user: Test user who will own the organization

    Returns:
        Organization instance
    """
    org = Organization(
        name="Test Organization",
        slug="test-organization",
        created_by=test_user.id
    )

    db_session.add(org)
    await db_session.commit()
    await db_session.refresh(org)

    # Add user as organization member with admin role
    member = OrganizationMember(
        organization_id=org.id,
        user_id=test_user.id,
        role="admin",
        invited_by=test_user.id
    )

    db_session.add(member)
    await db_session.commit()

    # Update user's last active organization
    test_user.last_active_organization_id = org.id
    await db_session.commit()
    await db_session.refresh(test_user)

    return org


@pytest.fixture
async def inactive_user(db_session: AsyncSession) -> User:
    """
    Create an inactive test user.

    Returns:
        Inactive User instance
    """
    password_hash = native_auth_service.hash_password("InactivePassword123!")

    user = User(
        email="inactive@example.com",
        password_hash=password_hash,
        name="Inactive User",
        auth_provider='native',
        email_verified=True,
        is_active=False
    )

    db_session.add(user)
    await db_session.commit()
    await db_session.refresh(user)

    return user


# Sample data fixtures for testing
@pytest.fixture
def sample_signup_data() -> dict:
    """Sample data for user registration."""
    return {
        "email": "newuser@example.com",
        "password": "NewPassword123!",
        "name": "New User"
    }


@pytest.fixture
def sample_login_data() -> dict:
    """Sample data for user login."""
    return {
        "email": "test@example.com",
        "password": "TestPassword123!"
    }


@pytest.fixture
def invalid_login_data() -> dict:
    """Invalid login data for testing authentication failures."""
    return {
        "email": "test@example.com",
        "password": "WrongPassword123!"
    }


@pytest.fixture
def sample_profile_update() -> dict:
    """Sample data for profile update."""
    return {
        "name": "Updated Name",
        "avatar_url": "https://example.com/avatar.png"
    }
