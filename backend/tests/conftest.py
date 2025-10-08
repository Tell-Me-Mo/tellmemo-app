"""
Pytest configuration and shared fixtures for backend tests.

This module provides test fixtures following the integration-first testing strategy
outlined in TESTING_BACKEND.md.
"""

import os

# IMPORTANT: Set environment variables BEFORE any other imports
# This ensures that services initialize with correct configuration
os.environ["TESTING"] = "1"

# SECURITY: Verify we're in test mode before setting test secrets
if os.getenv("TESTING") != "1":
    raise RuntimeError(
        "SECURITY VIOLATION: Attempting to use hardcoded test secrets outside test environment. "
        "TESTING environment variable must be set to '1'."
    )

os.environ["DATABASE_URL"] = os.getenv(
    "TEST_DATABASE_URL",
    "postgresql+asyncpg://pm_master:pm_master_pass@localhost:5432/pm_master_test"
)

# Set consistent JWT secret for tests (ONLY allowed when TESTING=1)
os.environ["JWT_SECRET"] = "test_jwt_secret_key_for_testing_only_do_not_use_in_production"
os.environ["AUTH_PROVIDER"] = "backend"  # Use backend auth for tests

import pytest
import asyncio
import socket
from typing import AsyncGenerator, Generator
from contextlib import asynccontextmanager
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine, async_sessionmaker
from sqlalchemy.pool import NullPool
from httpx import AsyncClient, ASGITransport
from datetime import datetime
from unittest.mock import Mock, AsyncMock, patch

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


def is_server_running(host: str = "localhost", port: int = 8000) -> bool:
    """Check if a server is running on the specified host and port."""
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(1)
        result = sock.connect_ex((host, port))
        sock.close()
        return result == 0
    except Exception:
        return False


def pytest_collection_modifyitems(config, items):
    """
    Automatically skip WebSocket tests - they require special test server setup.

    WebSocket tests in test_websocket_*.py files connect to a running server,
    but require the server to use the test database. This is complex to set up,
    so these tests are skipped in normal test runs.
    """
    skip_websocket = pytest.mark.skip(
        reason="WebSocket tests require test server with test database access (integration test limitation)"
    )

    for item in items:
        # Skip all tests in websocket test files
        if "test_websocket" in str(item.fspath):
            item.add_marker(skip_websocket)


@pytest.fixture(scope="session")
def event_loop() -> Generator:
    """Create an event loop for the test session."""
    loop = asyncio.get_event_loop_policy().new_event_loop()
    yield loop
    loop.close()


@pytest.fixture(scope="function", autouse=False)
async def db_session() -> AsyncGenerator[AsyncSession, None]:
    """
    Create a fresh database session for each test.

    This fixture:
    - Creates all tables before the test
    - Yields a database session
    - Drops all tables after the test to ensure clean state
    """
    # Drop tables first to ensure clean slate (in case previous test failed)
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)

    # Create tables
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    # Create session
    try:
        async with TestSessionLocal() as session:
            try:
                yield session
            finally:
                # Always rollback, even if test/fixtures fail
                await session.rollback()
    finally:
        # Always drop tables to ensure clean state for next test
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.drop_all)


@pytest.fixture(scope="function")
async def client_factory(db_session: AsyncSession, monkeypatch):
    """
    Create a factory for generating multiple independent HTTP clients.

    This fixture allows tests to create multiple authenticated clients for different users.
    Each client shares the same database session, overrides, and transport.
    """
    # Set up database overrides once
    async def override_get_db():
        yield db_session

    app.dependency_overrides[get_db] = override_get_db

    @asynccontextmanager
    async def override_get_db_context():
        yield db_session

    monkeypatch.setattr("db.database.get_db_context", override_get_db_context)
    monkeypatch.setattr("middleware.auth_middleware.get_db_context", override_get_db_context)

    # Create a shared transport for all clients (important for sharing app state)
    transport = ASGITransport(app=app)

    # Keep track of all clients created for cleanup
    clients = []

    async def create_client(user: User = None, organization: Organization = None, **headers) -> AsyncClient:
        """
        Create a new client with optional headers or user/org context.

        Args:
            user: Optional User object to create auth token for
            organization: Optional Organization object to set context
            **headers: Additional headers to set

        Returns:
            AsyncClient with configured headers
        """
        ac = AsyncClient(transport=transport, base_url="http://test")

        # If user is provided, create token
        if user:
            org_id = str(organization.id) if organization else None
            token = native_auth_service.create_access_token(
                user_id=str(user.id),
                email=user.email,
                organization_id=org_id
            )
            ac.headers["Authorization"] = f"Bearer {token}"

            # If org is provided, set org header
            if organization:
                ac.headers["X-Organization-Id"] = str(organization.id)

        # Set any additional provided headers
        for key, value in headers.items():
            ac.headers[key] = value

        clients.append(ac)
        return ac

    # Yield the factory function
    yield create_client

    # Cleanup all clients
    for client in clients:
        await client.aclose()

    app.dependency_overrides.clear()


@pytest.fixture(scope="function")
async def client(client_factory) -> AsyncClient:
    """
    Create a single async HTTP client for testing API endpoints.

    This is a convenience fixture that uses client_factory to create one client.
    For tests that need multiple clients with different auth, use client_factory directly.
    """
    return await client_factory()


@pytest.fixture(scope="function")
async def async_client(client_factory) -> AsyncClient:
    """
    Alias for client fixture - creates an unauthenticated async HTTP client.

    This is used by some tests that need to test authentication failures.
    """
    return await client_factory()


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
    client_factory,
    test_user_token: str
) -> AsyncClient:
    """
    Create an authenticated HTTP client with valid JWT token.

    Args:
        client_factory: Client factory function
        test_user_token: Valid access token

    Returns:
        AsyncClient with Authorization header set
    """
    return await client_factory(Authorization=f"Bearer {test_user_token}")


@pytest.fixture
async def authenticated_org_client(
    client_factory,
    test_user: User,
    test_organization: Organization
) -> AsyncClient:
    """
    Create an authenticated HTTP client with organization context.

    Args:
        client_factory: Client factory function
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
    return await client_factory(
        Authorization=f"Bearer {token}",
        **{"X-Organization-Id": str(test_organization.id)}
    )


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
        invited_by=test_user.id,
        joined_at=datetime.utcnow()
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


# Additional fixtures for multi-tenant testing

@pytest.fixture
async def test_project(db_session: AsyncSession, test_organization: Organization):
    """
    Create a test project within the test organization.

    Args:
        db_session: Database session
        test_organization: Test organization for the project

    Returns:
        Project instance
    """
    from models.project import Project

    project = Project(
        name="Test Project",
        description="Test project for security testing",
        organization_id=test_organization.id,
        status="active",
        created_by=str(test_organization.created_by)  # Convert UUID to string
    )

    db_session.add(project)
    await db_session.commit()
    await db_session.refresh(project)

    return project


@pytest.fixture
async def test_user_2(db_session: AsyncSession) -> User:
    """
    Create a second test user for multi-tenant testing.

    Returns:
        User instance with:
        - Email: test2@example.com
        - Password: TestPassword123!
        - Name: Test User 2
    """
    password_hash = native_auth_service.hash_password("TestPassword123!")

    user = User(
        email="test2@example.com",
        password_hash=password_hash,
        name="Test User 2",
        auth_provider='native',
        email_verified=True,
        is_active=True
    )

    db_session.add(user)
    await db_session.commit()
    await db_session.refresh(user)

    return user


@pytest.fixture
async def test_org_2(db_session: AsyncSession, test_user_2: User) -> Organization:
    """
    Create a second test organization for multi-tenant testing.

    Args:
        db_session: Database session
        test_user_2: Second test user who will own this organization

    Returns:
        Organization instance
    """
    org = Organization(
        name="Test Organization 2",
        slug="test-organization-2",
        created_by=test_user_2.id
    )

    db_session.add(org)
    await db_session.commit()
    await db_session.refresh(org)

    # Add user as organization member with admin role
    member = OrganizationMember(
        organization_id=org.id,
        user_id=test_user_2.id,
        role="admin",
        invited_by=test_user_2.id,
        joined_at=datetime.utcnow()
    )

    db_session.add(member)
    await db_session.commit()

    # Update user's last active organization
    test_user_2.last_active_organization_id = org.id
    await db_session.commit()
    await db_session.refresh(test_user_2)

    return org


@pytest.fixture(scope="function", autouse=True)
def mock_llm_client():
    """
    Mock the LLM client to prevent real API calls during tests.

    This fixture automatically mocks the MultiProviderLLMClient for all tests,
    preventing accidental calls to Anthropic or OpenAI APIs.
    """
    async def mock_create_message(**kwargs):
        """Return different mock responses based on the system prompt or prompt content."""
        system_prompt = kwargs.get('system', '')
        prompt = kwargs.get('prompt', '')

        # Create mock usage
        mock_usage = Mock(input_tokens=100, output_tokens=200)

        # Project matcher response
        if 'project management assistant' in system_prompt.lower() or 'project matching' in prompt.lower():
            response = Mock()
            response.content = [Mock(text='{"action": "create_new", "project_name": "Test Project", "project_description": "Test project created from meeting", "confidence": 0.85, "reasoning": "New project needed for this meeting"}')]
            response.usage = mock_usage
            return response

        # Default summary response
        response = Mock()
        response.content = [Mock(text='{"subject": "Test Meeting Summary", "body": "This is a test summary generated for testing purposes.", "key_points": ["Point 1", "Point 2", "Point 3"], "action_items": [{"title": "Action 1", "assignee": "Test User", "due_date": "2025-10-14"}], "decisions": [{"title": "Decision 1", "description": "Test decision"}], "risks": [], "blockers": [], "lessons_learned": []}')]
        response.usage = mock_usage
        return response

    # Create mock LLM client
    mock_client = Mock()
    mock_client.is_available.return_value = True
    mock_client.create_message = AsyncMock(side_effect=mock_create_message)

    # Patch the get_multi_llm_client function to return our mock
    with patch('services.summaries.summary_service_refactored.get_multi_llm_client', return_value=mock_client):
        # Also patch the already-instantiated summary_service's llm_client
        from services.summaries.summary_service_refactored import summary_service
        summary_service.llm_client = mock_client

        # Patch project_matcher_service's llm_client
        from services.intelligence.project_matcher_service import project_matcher_service
        project_matcher_service.llm_client = mock_client

        yield mock_client
