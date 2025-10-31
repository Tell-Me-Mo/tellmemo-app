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

# Import all models to register them with Base.metadata before create_all()
import models  # noqa: F401

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
    from sqlalchemy import text

    # Drop all tables using CASCADE to handle foreign key dependencies
    # Use raw SQL to avoid errors when tables don't exist
    async with engine.begin() as conn:
        # Drop all tables in the public schema with CASCADE
        await conn.execute(text("""
            DO $$
            DECLARE
                r RECORD;
            BEGIN
                FOR r IN (SELECT tablename FROM pg_tables WHERE schemaname = 'public') LOOP
                    EXECUTE 'DROP TABLE IF EXISTS ' || quote_ident(r.tablename) || ' CASCADE';
                END LOOP;
                -- Also drop custom types
                FOR r IN (SELECT typname FROM pg_type WHERE typnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public') AND typtype = 'e') LOOP
                    EXECUTE 'DROP TYPE IF EXISTS ' || quote_ident(r.typname) || ' CASCADE';
                END LOOP;
            END $$;
        """))

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
            await conn.execute(text("""
                DO $$
                DECLARE
                    r RECORD;
                BEGIN
                    FOR r IN (SELECT tablename FROM pg_tables WHERE schemaname = 'public') LOOP
                        EXECUTE 'DROP TABLE IF EXISTS ' || quote_ident(r.tablename) || ' CASCADE';
                    END LOOP;
                    FOR r IN (SELECT typname FROM pg_type WHERE typnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public') AND typtype = 'e') LOOP
                        EXECUTE 'DROP TYPE IF EXISTS ' || quote_ident(r.typname) || ' CASCADE';
                    END LOOP;
                END $$;
            """))


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
async def ws_token(test_user_token: str) -> str:
    """
    Alias for test_user_token for WebSocket tests.

    Args:
        test_user_token: Valid JWT access token

    Returns:
        Valid JWT access token for WebSocket authentication
    """
    return test_user_token


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


@pytest.fixture(scope="function", autouse=False)
def mock_llm_client():
    """
    Mock the LLM client to prevent real API calls during tests.

    This fixture mocks the MultiProviderLLMClient for tests that don't need
    to test provider selection logic. Use this for tests focused on other
    functionality (API endpoints, data validation, etc.).

    Usage:
        @pytest.mark.usefixtures("mock_llm_client")
        class TestSomething:
            pass

    For integration tests that need to test provider selection, DO NOT use
    this fixture. Instead, mock only the HTTP/API layer in your test.
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

        # Semantic deduplication AI analysis response
        if 'duplicate detection' in prompt.lower() or 'semantically similar' in prompt.lower():
            # Return a proper analysis structure matching what the service expects
            response = Mock()
            # Parse to determine how many pairs there are
            import re
            pair_matches = re.findall(r'Pair (\d+):', prompt)
            num_pairs = len(pair_matches)

            # Generate analysis for each pair
            analysis_items = []
            for i in range(num_pairs):
                # Check if the pair mentions keywords that suggest duplicate or unique
                pair_section_start = prompt.find(f'Pair {i}:')
                pair_section_end = prompt.find(f'Pair {i+1}:') if i < num_pairs - 1 else len(prompt)
                pair_text = prompt[pair_section_start:pair_section_end].lower()

                # Simple heuristic: if titles share 2+ words, likely duplicate
                existing_title = re.search(r'existing.*?title:\s*([^\n]+)', pair_text, re.IGNORECASE)
                new_title = re.search(r'new.*?title:\s*([^\n]+)', pair_text, re.IGNORECASE)

                is_similar = False
                if existing_title and new_title:
                    existing_words = set(existing_title.group(1).lower().split())
                    new_words = set(new_title.group(1).lower().split())
                    common_words = existing_words & new_words
                    is_similar = len(common_words) >= 2

                analysis_items.append({
                    "index": i,
                    "is_duplicate": is_similar,
                    "has_new_info": is_similar,  # If duplicate, assume it has updates
                    "update_type": "status" if is_similar else None,
                    "new_info": {"status": "updated"} if is_similar else {},
                    "confidence": 0.85 if is_similar else 0.3,
                    "reasoning": "Items refer to same concept with updates" if is_similar else "Different topics"
                })

            response.content = [Mock(text='{"analysis": ' + str(analysis_items).replace("'", '"').replace('True', 'true').replace('False', 'false').replace('None', 'null') + '}')]
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

        # Patch semantic_deduplicator's llm_client
        from services.intelligence.semantic_deduplicator import semantic_deduplicator
        semantic_deduplicator.llm_client = mock_client

        yield mock_client


@pytest.fixture(scope="function", autouse=True)
def mock_redis_for_rq():
    """
    Replace real Redis with FakeRedis for RQ job queue testing.

    This fixture automatically replaces the Redis connection in queue_config
    with FakeRedis for all tests, preventing the need for:
    - A running Redis server
    - RQ workers to process jobs
    - Cleanup between tests

    Jobs are stored in-memory and can be inspected/manipulated without workers.
    """
    import fakeredis
    from queue_config import queue_config

    # Create a fresh FakeRedis instance for each test
    fake_redis = fakeredis.FakeRedis(decode_responses=False)

    # Replace the Redis connection in queue_config
    original_redis_conn = queue_config._redis_conn
    original_pubsub_conn = queue_config._pubsub_conn
    original_high_queue = queue_config._high_queue
    original_default_queue = queue_config._default_queue
    original_low_queue = queue_config._low_queue

    # Set FakeRedis as the connection
    queue_config._redis_conn = fake_redis

    # Create a separate FakeRedis instance for pub/sub (with decode_responses=True)
    queue_config._pubsub_conn = fakeredis.FakeRedis(decode_responses=True)

    # Reset queues so they'll be recreated with FakeRedis
    queue_config._high_queue = None
    queue_config._default_queue = None
    queue_config._low_queue = None

    yield fake_redis

    # Restore original connections after test
    queue_config._redis_conn = original_redis_conn
    queue_config._pubsub_conn = original_pubsub_conn
    queue_config._high_queue = original_high_queue
    queue_config._default_queue = original_default_queue
    queue_config._low_queue = original_low_queue


@pytest.fixture(scope="function", autouse=True)
async def mock_redis_cache():
    """
    Replace real Redis with FakeRedis for cache service testing.

    This fixture automatically replaces the Redis connection in redis_cache service
    with FakeRedis for all tests, preventing the need for a running Redis server.

    The cache service operates in-memory and is automatically cleaned up between tests.
    """
    import fakeredis.aioredis
    from services.cache.redis_cache_service import redis_cache

    # Create a fresh FakeRedis async instance for each test
    fake_redis_async = fakeredis.aioredis.FakeRedis(decode_responses=True)

    # Store original client and availability state
    original_client = redis_cache._client
    original_is_available = redis_cache._is_available

    # Replace with FakeRedis
    redis_cache._client = fake_redis_async
    redis_cache._is_available = True

    yield fake_redis_async

    # Close FakeRedis connection
    await fake_redis_async.aclose()

    # Restore original state
    redis_cache._client = original_client
    redis_cache._is_available = original_is_available


@pytest.fixture(scope="function", autouse=True)
def mock_embedding_service():
    """
    Mock the embedding service to prevent downloading HuggingFace models during tests.

    This fixture automatically mocks the EmbeddingService for all tests,
    preventing accidental downloads of the embeddinggemma-300m model.

    Returns deterministic 768-dimensional embeddings for testing with some semantic similarity.
    """
    import numpy as np
    import re
    from services.rag.embedding_service import embedding_service

    def text_to_simple_embedding(text: str, normalize: bool = True):
        """
        Generate a simple embedding that captures basic text similarity.

        This creates embeddings where similar words/topics produce similar vectors.
        """
        # Normalize text
        text_lower = text.lower()

        # Extract key words (very simple tokenization)
        words = re.findall(r'\b\w+\b', text_lower)

        # Create base embedding from hash
        hash_val = hash(text) % (2**32)
        np.random.seed(hash_val)
        base_embedding = np.random.randn(768).astype(np.float32) * 0.3  # Smaller magnitude

        # Add components based on common words to create similarity
        # This makes texts with same words more similar
        word_contribution = np.zeros(768, dtype=np.float32)
        for word in words:
            word_hash = hash(word) % (2**32)
            np.random.seed(word_hash)
            word_vec = np.random.randn(768).astype(np.float32) * 0.1
            word_contribution += word_vec

        # Combine base and word contribution
        embedding = base_embedding + word_contribution

        if normalize:
            norm = np.linalg.norm(embedding)
            if norm > 0:
                embedding = embedding / norm

        return embedding

    async def mock_generate_embedding(text: str, normalize: bool = True):
        """Generate a deterministic fake embedding based on text."""
        embedding = text_to_simple_embedding(text, normalize)
        return embedding.tolist()

    async def mock_generate_embeddings_batch(
        texts: list,
        batch_size: int = 32,
        normalize: bool = True,
        show_progress: bool = False
    ):
        """Generate fake embeddings for a batch of texts."""
        embeddings = []
        for text in texts:
            embedding = await mock_generate_embedding(text, normalize)
            embeddings.append(embedding)
        return embeddings

    # Store original methods
    original_generate_embedding = embedding_service.generate_embedding
    original_generate_embeddings_batch = embedding_service.generate_embeddings_batch
    original_get_model = embedding_service.get_model

    # Mock the methods
    embedding_service.generate_embedding = mock_generate_embedding
    embedding_service.generate_embeddings_batch = mock_generate_embeddings_batch

    # Mock get_model to avoid downloading
    async def mock_get_model():
        # Return a mock model object
        mock_model = Mock()
        mock_model.encode = lambda texts, **kwargs: np.random.randn(len(texts) if isinstance(texts, list) else 1, 768)
        return mock_model

    embedding_service.get_model = mock_get_model

    # Mark model as loaded
    embedding_service._model = Mock()

    yield embedding_service

    # Restore original methods
    embedding_service.generate_embedding = original_generate_embedding
    embedding_service.generate_embeddings_batch = original_generate_embeddings_batch
    embedding_service.get_model = original_get_model
    embedding_service._model = None
