"""
Pytest configuration and fixtures for integration tests
"""
import os
import asyncio
import uuid
from typing import AsyncGenerator, Dict, Any
import pytest
import pytest_asyncio
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine, async_sessionmaker
from sqlalchemy.pool import NullPool
# Import configuration
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from config import Settings

# Use real database and API endpoints
DATABASE_URL = os.getenv("DATABASE_URL", "postgresql+asyncpg://pm_master:pm_master_pass@localhost:5432/pm_master_db")
API_BASE_URL = os.getenv("API_BASE_URL", "http://localhost:8000")


@pytest.fixture(scope="session")
def event_loop():
    """Create an event loop for the test session"""
    loop = asyncio.get_event_loop_policy().new_event_loop()
    yield loop
    loop.close()


@pytest.fixture(scope="session")
def test_settings():
    """Configuration settings using real services"""
    settings = Settings()
    settings.database_url = DATABASE_URL
    settings.api_env = os.getenv("API_ENV", "development")
    # Use real Claude API key from environment
    settings.claude_api_key = os.getenv("CLAUDE_API_KEY", "")
    return settings


@pytest_asyncio.fixture(scope="session")
async def test_db_engine():
    """Use real database engine - no test database"""
    engine = create_async_engine(
        DATABASE_URL,
        echo=False,
        pool_pre_ping=True,
        poolclass=NullPool
    )
    
    # We'll use the real database, no setup needed
    # Tests will clean up after themselves
    
    yield engine
    
    # No cleanup - using real database
    await engine.dispose()


@pytest_asyncio.fixture
async def db_session(test_db_engine):
    """Create a test database session"""
    async_session_maker = async_sessionmaker(
        test_db_engine,
        class_=AsyncSession,
        expire_on_commit=False
    )
    async with async_session_maker() as session:
        yield session
        await session.rollback()


@pytest_asyncio.fixture
async def api_client() -> AsyncGenerator[AsyncClient, None]:
    """Create an async HTTP client for API testing"""
    async with AsyncClient(base_url=API_BASE_URL, timeout=30.0) as client:
        yield client


@pytest_asyncio.fixture
async def test_project(api_client: AsyncClient):
    """Create a test project and clean up after test"""
    project_data = {
        "name": f"Test Project {uuid.uuid4().hex[:8]}",
        "description": "Integration test project",
        "members": [
            {"name": "Test User", "email": "test@example.com", "role": "PM"}
        ]
    }
    
    response = await api_client.post("/api/projects", json=project_data)
    assert response.status_code == 200
    project = response.json()
    
    yield project
    
    # Cleanup
    await api_client.delete(f"/api/projects/{project['id']}")


@pytest_asyncio.fixture
async def test_content(api_client: AsyncClient, test_project: Dict[str, Any]):
    """Upload test content to a project"""
    content_data = {
        "content_type": "meeting",
        "title": "Test Meeting Transcript",
        "content": """
        Meeting Date: January 15, 2024
        Attendees: John Doe, Jane Smith, Bob Johnson
        
        Discussion Points:
        1. Project Timeline Review
           - Current sprint is on track
           - Need to complete API integration by end of week
           - Frontend development starting next week
        
        2. Technical Decisions
           - Decided to use JWT for authentication
           - Will implement Redis for caching
           - Database migration scheduled for Thursday
        
        3. Action Items
           - John: Complete API documentation
           - Jane: Set up CI/CD pipeline
           - Bob: Review security requirements
        
        Next Meeting: January 22, 2024
        """
    }
    
    response = await api_client.post(
        f"/api/projects/{test_project['id']}/upload/text",
        json=content_data
    )
    assert response.status_code == 200
    content = response.json()
    
    # Wait for processing to complete
    await asyncio.sleep(5)
    
    yield content
    
    # Content is cleaned up with project deletion


# No mock fixtures - using real Claude API and embedding service


@pytest_asyncio.fixture
async def api_with_auth(api_client: AsyncClient):
    """API client with authentication headers"""
    api_client.headers["X-API-Key"] = os.getenv("API_KEY", "development_reset_key")
    return api_client


@pytest_asyncio.fixture
async def clean_database(api_with_auth: AsyncClient):
    """Clean all database data before and after test"""
    # Clean before test
    response = await api_with_auth.request(
        "DELETE",
        "/api/admin/reset",
        json={"confirm": True}
    )
    assert response.status_code in [200, 404]  # 404 if endpoint doesn't exist yet
    
    yield
    
    # Clean after test
    response = await api_with_auth.request(
        "DELETE",
        "/api/admin/reset",
        json={"confirm": True}
    )
    assert response.status_code in [200, 404]


# Performance benchmarking fixtures
@pytest.fixture
def performance_tracker():
    """Track performance metrics during tests"""
    class PerformanceTracker:
        def __init__(self):
            self.metrics = {}
        
        def record(self, metric_name: str, value: float):
            if metric_name not in self.metrics:
                self.metrics[metric_name] = []
            self.metrics[metric_name].append(value)
        
        def get_average(self, metric_name: str) -> float:
            if metric_name not in self.metrics:
                return 0.0
            return sum(self.metrics[metric_name]) / len(self.metrics[metric_name])
        
        def assert_performance(self, metric_name: str, max_value: float):
            avg = self.get_average(metric_name)
            assert avg <= max_value, f"{metric_name} average {avg:.2f} exceeds limit {max_value}"
    
    return PerformanceTracker()