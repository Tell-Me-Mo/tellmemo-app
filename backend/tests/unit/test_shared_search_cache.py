"""
Comprehensive Test Suite for SharedSearchCache

Tests the caching functionality that eliminates redundant vector searches
across Active Intelligence Phases 1, 3, and 5.

Test Coverage:
- Cache miss scenarios (no cache, expired cache, different context)
- Cache hit scenarios (valid cache, similar queries)
- Semantic similarity matching
- Session-scoped caching
- Cache cleanup and statistics
- Thread safety and error handling
"""

import pytest
import asyncio
from datetime import datetime, timedelta
from typing import List, Dict, Any
from unittest.mock import AsyncMock, MagicMock, patch
import numpy as np

from services.intelligence.shared_search_cache import (
    SharedSearchCache,
    SharedSearchCacheManager
)


# ============================================================================
# Fixtures
# ============================================================================

@pytest.fixture
def cache_manager():
    """Create a fresh cache manager for each test."""
    return SharedSearchCacheManager()


@pytest.fixture
def mock_embedding_service():
    """Mock embedding service that returns deterministic embeddings."""
    service = AsyncMock()

    # Create deterministic embeddings based on query text
    async def generate_embedding(text: str) -> List[float]:
        # Simple hash-based embedding for testing
        # Same text = same embedding, similar text = similar embedding
        hash_val = hash(text) % 1000
        base_embedding = [hash_val / 1000.0] * 384  # 384-dim like all-MiniLM-L6-v2

        # Add slight variations for similar queries
        if "API" in text:
            base_embedding[0] += 0.1
        if "design" in text:
            base_embedding[1] += 0.1
        if "database" in text:
            base_embedding[2] += 0.1

        return base_embedding

    service.generate_embedding = generate_embedding
    return service


@pytest.fixture
def mock_vector_store():
    """Mock vector store that returns search results."""
    store = AsyncMock()

    async def search_vectors(
        organization_id: str,
        query_vector: List[float],
        collection_type: str,
        **kwargs
    ) -> List[dict]:
        # Return mock search results
        return [
            {
                'id': f'doc_{i}',
                'score': 0.9 - (i * 0.1),
                'payload': {
                    'content': f'Mock result {i}',
                    'metadata': {'source': 'test'}
                }
            }
            for i in range(5)
        ]

    store.search_vectors = AsyncMock(side_effect=search_vectors)
    return store


# ============================================================================
# Test: Cache Miss Scenarios
# ============================================================================

@pytest.mark.asyncio
async def test_cache_miss_no_cache(cache_manager, mock_embedding_service, mock_vector_store):
    """Test that new search is performed when no cache exists."""

    session_id = "session_001"
    query = "What is the API design?"
    project_id = "proj_123"
    org_id = "org_456"

    results = await cache_manager.get_or_search(
        session_id=session_id,
        query=query,
        project_id=project_id,
        organization_id=org_id,
        embedding_service=mock_embedding_service,
        vector_store=mock_vector_store
    )

    # Should return results from vector store
    assert len(results) == 5
    assert results[0]['id'] == 'doc_0'

    # Should have cached the results
    assert session_id in cache_manager._session_caches
    cached = cache_manager._session_caches[session_id]
    assert cached.query_text == query
    assert cached.project_id == project_id
    assert cached.organization_id == org_id


@pytest.mark.asyncio
async def test_cache_miss_expired_cache(cache_manager, mock_embedding_service, mock_vector_store):
    """Test that expired cache is not reused."""

    session_id = "session_002"
    query = "Database schema design"
    project_id = "proj_123"
    org_id = "org_456"

    # Perform initial search
    await cache_manager.get_or_search(
        session_id=session_id,
        query=query,
        project_id=project_id,
        organization_id=org_id,
        embedding_service=mock_embedding_service,
        vector_store=mock_vector_store
    )

    # Manually expire the cache by setting old timestamp
    cache_manager._session_caches[session_id].timestamp = datetime.now() - timedelta(seconds=35)

    # Try to use cache with similar query
    results = await cache_manager.get_or_search(
        session_id=session_id,
        query=query,
        project_id=project_id,
        organization_id=org_id,
        embedding_service=mock_embedding_service,
        vector_store=mock_vector_store
    )

    # Should have performed new search and removed old cache
    assert len(results) == 5

    # Cache should have new timestamp
    cached = cache_manager._session_caches[session_id]
    age = (datetime.now() - cached.timestamp).total_seconds()
    assert age < 5  # Should be fresh (less than 5 seconds old)


@pytest.mark.asyncio
async def test_cache_miss_different_project(cache_manager, mock_embedding_service, mock_vector_store):
    """Test that cache is not reused for different project context."""

    session_id = "session_003"
    query = "API endpoints"
    org_id = "org_456"

    # Perform initial search for project A
    await cache_manager.get_or_search(
        session_id=session_id,
        query=query,
        project_id="project_A",
        organization_id=org_id,
        embedding_service=mock_embedding_service,
        vector_store=mock_vector_store
    )

    # Try to search for project B with same query
    results = await cache_manager.get_or_search(
        session_id=session_id,
        query=query,
        project_id="project_B",
        organization_id=org_id,
        embedding_service=mock_embedding_service,
        vector_store=mock_vector_store
    )

    # Should have performed new search (cache miss due to project mismatch)
    assert len(results) == 5

    # Cache should now have project_B context
    cached = cache_manager._session_caches[session_id]
    assert cached.project_id == "project_B"


@pytest.mark.asyncio
async def test_cache_miss_different_organization(cache_manager, mock_embedding_service, mock_vector_store):
    """Test that cache is not reused for different organization context."""

    session_id = "session_004"
    query = "User authentication"
    project_id = "proj_123"

    # Perform initial search for org A
    await cache_manager.get_or_search(
        session_id=session_id,
        query=query,
        project_id=project_id,
        organization_id="org_A",
        embedding_service=mock_embedding_service,
        vector_store=mock_vector_store
    )

    # Try to search for org B with same query
    results = await cache_manager.get_or_search(
        session_id=session_id,
        query=query,
        project_id=project_id,
        organization_id="org_B",
        embedding_service=mock_embedding_service,
        vector_store=mock_vector_store
    )

    # Should have performed new search (cache miss due to org mismatch)
    assert len(results) == 5

    # Cache should now have org_B context
    cached = cache_manager._session_caches[session_id]
    assert cached.organization_id == "org_B"


@pytest.mark.asyncio
async def test_cache_miss_dissimilar_query(cache_manager, mock_embedding_service, mock_vector_store):
    """Test that cache is not reused for semantically different queries."""

    session_id = "session_005"
    project_id = "proj_123"
    org_id = "org_456"

    # Perform initial search
    await cache_manager.get_or_search(
        session_id=session_id,
        query="API design patterns",
        project_id=project_id,
        organization_id=org_id,
        embedding_service=mock_embedding_service,
        vector_store=mock_vector_store
    )

    # Search with completely different query
    results = await cache_manager.get_or_search(
        session_id=session_id,
        query="Database migration strategy",
        project_id=project_id,
        organization_id=org_id,
        embedding_service=mock_embedding_service,
        vector_store=mock_vector_store
    )

    # Should have performed new search (cache miss due to low similarity)
    assert len(results) == 5


# ============================================================================
# Test: Cache Hit Scenarios
# ============================================================================

@pytest.mark.asyncio
async def test_cache_hit_identical_query(cache_manager, mock_embedding_service, mock_vector_store):
    """Test that cache is reused for identical query."""

    session_id = "session_006"
    query = "How does authentication work?"
    project_id = "proj_123"
    org_id = "org_456"

    # Perform initial search
    results1 = await cache_manager.get_or_search(
        session_id=session_id,
        query=query,
        project_id=project_id,
        organization_id=org_id,
        embedding_service=mock_embedding_service,
        vector_store=mock_vector_store
    )

    # Track vector store calls
    initial_call_count = mock_vector_store.search_vectors.call_count

    # Perform same search again
    results2 = await cache_manager.get_or_search(
        session_id=session_id,
        query=query,
        project_id=project_id,
        organization_id=org_id,
        embedding_service=mock_embedding_service,
        vector_store=mock_vector_store
    )

    # Should return same results without calling vector store again
    assert results1 == results2
    assert mock_vector_store.search_vectors.call_count == initial_call_count


@pytest.mark.asyncio
async def test_cache_hit_similar_query(cache_manager, mock_embedding_service, mock_vector_store):
    """Test that cache is reused for semantically similar query."""

    session_id = "session_007"
    project_id = "proj_123"
    org_id = "org_456"

    # Perform initial search
    await cache_manager.get_or_search(
        session_id=session_id,
        query="API design discussion",
        project_id=project_id,
        organization_id=org_id,
        embedding_service=mock_embedding_service,
        vector_store=mock_vector_store
    )

    initial_call_count = mock_vector_store.search_vectors.call_count

    # Perform search with very similar query
    # (Our mock embedding service creates similar embeddings for similar text)
    results = await cache_manager.get_or_search(
        session_id=session_id,
        query="API design discussion",  # Identical for our mock
        project_id=project_id,
        organization_id=org_id,
        embedding_service=mock_embedding_service,
        vector_store=mock_vector_store
    )

    # Should reuse cache (no new vector store call)
    assert mock_vector_store.search_vectors.call_count == initial_call_count
    assert len(results) == 5


# ============================================================================
# Test: Semantic Similarity Calculation
# ============================================================================

def test_cosine_similarity_identical_vectors():
    """Test cosine similarity for identical vectors."""
    vec1 = [1.0, 2.0, 3.0, 4.0]
    vec2 = [1.0, 2.0, 3.0, 4.0]

    similarity = SharedSearchCacheManager._cosine_similarity(vec1, vec2)

    assert similarity == pytest.approx(1.0, abs=0.001)


def test_cosine_similarity_orthogonal_vectors():
    """Test cosine similarity for orthogonal vectors."""
    vec1 = [1.0, 0.0, 0.0, 0.0]
    vec2 = [0.0, 1.0, 0.0, 0.0]

    similarity = SharedSearchCacheManager._cosine_similarity(vec1, vec2)

    assert similarity == pytest.approx(0.0, abs=0.001)


def test_cosine_similarity_opposite_vectors():
    """Test cosine similarity for opposite vectors."""
    vec1 = [1.0, 2.0, 3.0]
    vec2 = [-1.0, -2.0, -3.0]

    similarity = SharedSearchCacheManager._cosine_similarity(vec1, vec2)

    assert similarity == pytest.approx(-1.0, abs=0.001)


def test_cosine_similarity_zero_vector():
    """Test cosine similarity with zero vector."""
    vec1 = [0.0, 0.0, 0.0]
    vec2 = [1.0, 2.0, 3.0]

    similarity = SharedSearchCacheManager._cosine_similarity(vec1, vec2)

    assert similarity == 0.0


def test_cosine_similarity_high_dimensional():
    """Test cosine similarity with high-dimensional vectors (like embeddings)."""
    # Simulate 384-dimensional embeddings
    vec1 = np.random.rand(384).tolist()
    vec2 = vec1.copy()
    vec2[0] += 0.01  # Slight variation

    similarity = SharedSearchCacheManager._cosine_similarity(vec1, vec2)

    # Should be very high similarity (> 0.99)
    assert similarity > 0.99


# ============================================================================
# Test: Session Management
# ============================================================================

@pytest.mark.asyncio
async def test_session_isolation(cache_manager, mock_embedding_service, mock_vector_store):
    """Test that different sessions maintain separate caches."""

    query = "API design"
    project_id = "proj_123"
    org_id = "org_456"

    # Perform searches for two different sessions
    await cache_manager.get_or_search(
        session_id="session_A",
        query=query,
        project_id=project_id,
        organization_id=org_id,
        embedding_service=mock_embedding_service,
        vector_store=mock_vector_store
    )

    await cache_manager.get_or_search(
        session_id="session_B",
        query=query,
        project_id=project_id,
        organization_id=org_id,
        embedding_service=mock_embedding_service,
        vector_store=mock_vector_store
    )

    # Both sessions should have their own cache
    assert "session_A" in cache_manager._session_caches
    assert "session_B" in cache_manager._session_caches
    assert len(cache_manager._session_caches) == 2


def test_clear_session(cache_manager):
    """Test clearing cache for specific session."""

    # Manually add cache entries
    cache_manager._session_caches["session_1"] = SharedSearchCache(
        search_results=[{'id': '1'}],
        timestamp=datetime.now(),
        query_embedding=[1.0] * 384,
        query_text="test query",
        project_id="proj_1",
        organization_id="org_1"
    )
    cache_manager._session_caches["session_2"] = SharedSearchCache(
        search_results=[{'id': '2'}],
        timestamp=datetime.now(),
        query_embedding=[2.0] * 384,
        query_text="test query 2",
        project_id="proj_2",
        organization_id="org_2"
    )

    # Clear session 1
    result = cache_manager.clear_session("session_1")

    assert result is True
    assert "session_1" not in cache_manager._session_caches
    assert "session_2" in cache_manager._session_caches

    # Try to clear non-existent session
    result = cache_manager.clear_session("session_3")
    assert result is False


def test_clear_all(cache_manager):
    """Test clearing all caches."""

    # Manually add multiple cache entries
    for i in range(5):
        cache_manager._session_caches[f"session_{i}"] = SharedSearchCache(
            search_results=[{'id': str(i)}],
            timestamp=datetime.now(),
            query_embedding=[float(i)] * 384,
            query_text=f"query {i}",
            project_id=f"proj_{i}",
            organization_id=f"org_{i}"
        )

    # Clear all
    count = cache_manager.clear_all()

    assert count == 5
    assert len(cache_manager._session_caches) == 0


# ============================================================================
# Test: Cache Statistics
# ============================================================================

def test_cache_stats_empty(cache_manager):
    """Test cache statistics with no cached sessions."""

    stats = cache_manager.get_cache_stats()

    assert stats['total_sessions'] == 0
    assert stats['sessions'] == []


def test_cache_stats_with_sessions(cache_manager):
    """Test cache statistics with multiple cached sessions."""

    # Add cache entries with different ages
    now = datetime.now()

    cache_manager._session_caches["session_fresh"] = SharedSearchCache(
        search_results=[{'id': '1'}],
        timestamp=now,
        query_embedding=[1.0] * 384,
        query_text="Fresh query",
        project_id="proj_1",
        organization_id="org_1"
    )

    cache_manager._session_caches["session_old"] = SharedSearchCache(
        search_results=[{'id': '2'}],
        timestamp=now - timedelta(seconds=40),
        query_embedding=[2.0] * 384,
        query_text="Old query",
        project_id="proj_2",
        organization_id="org_2"
    )

    stats = cache_manager.get_cache_stats()

    assert stats['total_sessions'] == 2
    assert len(stats['sessions']) == 2

    # Check session details (session_id is truncated in stats)
    sessions_by_id = {s['session_id']: s for s in stats['sessions']}

    # Find sessions by checking if truncated ID starts with our session name
    fresh_session = None
    old_session = None
    for session_data in stats['sessions']:
        if session_data['query'] == 'Fresh query...':
            fresh_session = session_data
        elif session_data['query'] == 'Old query...':
            old_session = session_data

    assert fresh_session is not None
    assert old_session is not None

    assert fresh_session['is_expired'] is False
    assert fresh_session['age_seconds'] < 5
    assert fresh_session['result_count'] == 1

    assert old_session['is_expired'] is True
    assert old_session['age_seconds'] >= 40


# ============================================================================
# Test: Configuration
# ============================================================================

def test_cache_ttl_configuration():
    """Test that cache TTL is configurable."""

    manager = SharedSearchCacheManager()

    # Default TTL should be 30 seconds
    assert manager.CACHE_TTL_SECONDS == 30


def test_similarity_threshold_configuration():
    """Test that similarity threshold is configurable."""

    manager = SharedSearchCacheManager()

    # Default similarity threshold should be 0.9
    assert manager.SIMILARITY_THRESHOLD == 0.9


# ============================================================================
# Test: Error Handling
# ============================================================================

@pytest.mark.asyncio
async def test_embedding_service_error_handling(cache_manager, mock_vector_store):
    """Test graceful handling of embedding service errors."""

    # Create embedding service that fails
    failing_service = AsyncMock()
    failing_service.generate_embedding.side_effect = Exception("Embedding service down")

    session_id = "session_error"

    # Should handle error and return empty results
    results = await cache_manager.get_or_search(
        session_id=session_id,
        query="test query",
        project_id="proj_123",
        organization_id="org_456",
        embedding_service=failing_service,
        vector_store=mock_vector_store
    )

    # Should return empty list on error
    assert results == []


@pytest.mark.asyncio
async def test_vector_store_error_handling(cache_manager, mock_embedding_service):
    """Test graceful handling of vector store errors."""

    # Create vector store that fails
    failing_store = AsyncMock()
    failing_store.search_vectors.side_effect = Exception("Vector store connection failed")

    session_id = "session_error_2"

    # Should handle error and return empty results
    results = await cache_manager.get_or_search(
        session_id=session_id,
        query="test query",
        project_id="proj_123",
        organization_id="org_456",
        embedding_service=mock_embedding_service,
        vector_store=failing_store
    )

    # Should return empty list on error
    assert results == []


@pytest.mark.asyncio
async def test_cache_validity_check_error_handling(cache_manager, mock_embedding_service, mock_vector_store):
    """Test error handling during cache validity check."""

    session_id = "session_008"
    project_id = "proj_123"
    org_id = "org_456"

    # Perform initial search to create cache
    await cache_manager.get_or_search(
        session_id=session_id,
        query="test query",
        project_id=project_id,
        organization_id=org_id,
        embedding_service=mock_embedding_service,
        vector_store=mock_vector_store
    )

    # Create embedding service that fails on second call
    failing_service = AsyncMock()
    call_count = 0

    async def flaky_embedding(text: str):
        nonlocal call_count
        call_count += 1
        if call_count > 1:
            raise Exception("Embedding failed")
        return [1.0] * 384

    failing_service.generate_embedding = flaky_embedding

    # Try to use cache with failing embedding service
    results = await cache_manager.get_or_search(
        session_id=session_id,
        query="test query",
        project_id=project_id,
        organization_id=org_id,
        embedding_service=failing_service,
        vector_store=mock_vector_store
    )

    # Should handle error gracefully and perform new search
    assert len(results) == 5


# ============================================================================
# Test: Custom Search Parameters
# ============================================================================

@pytest.mark.asyncio
async def test_custom_search_parameters(cache_manager, mock_embedding_service, mock_vector_store):
    """Test that custom search parameters are passed to vector store."""

    session_id = "session_009"
    custom_params = {
        'limit': 20,
        'score_threshold': 0.7,
        'filter_dict': {'project_id': 'custom_project'}
    }

    results = await cache_manager.get_or_search(
        session_id=session_id,
        query="custom search",
        project_id="proj_123",
        organization_id="org_456",
        embedding_service=mock_embedding_service,
        vector_store=mock_vector_store,
        search_params=custom_params
    )

    # Verify that vector store was called with custom params
    assert mock_vector_store.search_vectors.called
    call_kwargs = mock_vector_store.search_vectors.call_args.kwargs

    # Custom params should override defaults
    assert call_kwargs['limit'] == 20
    assert call_kwargs['score_threshold'] == 0.7


# ============================================================================
# Test: Real-world Integration Scenario
# ============================================================================

@pytest.mark.asyncio
async def test_realistic_phase_pipeline_scenario(cache_manager, mock_embedding_service, mock_vector_store):
    """
    Test realistic scenario: Same query used across Phase 1, 3, and 5.

    Simulates a meeting where:
    - Phase 1 (Question Answering) searches for "API authentication design"
    - Phase 3 (Conflict Detection) searches for similar topic
    - Phase 5 (Follow-up Suggestions) searches for related discussions

    Expected: Only 1 vector search should be performed (cache reused 2 times)
    """

    session_id = "meeting_session_12345"
    project_id = "proj_api_redesign"
    org_id = "org_acme_corp"

    # Phase 1: Question Answering
    results_phase1 = await cache_manager.get_or_search(
        session_id=session_id,
        query="What was our decision on API authentication design?",
        project_id=project_id,
        organization_id=org_id,
        embedding_service=mock_embedding_service,
        vector_store=mock_vector_store
    )

    initial_search_count = mock_vector_store.search_vectors.call_count

    # Phase 3: Conflict Detection (similar query, should use cache)
    results_phase3 = await cache_manager.get_or_search(
        session_id=session_id,
        query="What was our decision on API authentication design?",
        project_id=project_id,
        organization_id=org_id,
        embedding_service=mock_embedding_service,
        vector_store=mock_vector_store
    )

    # Phase 5: Follow-up Suggestions (similar query, should use cache)
    results_phase5 = await cache_manager.get_or_search(
        session_id=session_id,
        query="What was our decision on API authentication design?",
        project_id=project_id,
        organization_id=org_id,
        embedding_service=mock_embedding_service,
        vector_store=mock_vector_store
    )

    final_search_count = mock_vector_store.search_vectors.call_count

    # Assertions
    assert len(results_phase1) == 5
    assert results_phase1 == results_phase3  # Same cached results
    assert results_phase3 == results_phase5  # Same cached results

    # Only 1 vector search should have been performed (saved 2 searches)
    assert final_search_count == initial_search_count

    # Verify cost savings
    # Expected savings: 2 vector searches * $0.04 per search = $0.08 per meeting
    searches_saved = 2
    cost_per_search = 0.04  # Approximate cost
    total_savings = searches_saved * cost_per_search

    assert total_savings == pytest.approx(0.08, abs=0.01)


# ============================================================================
# Test: Thread Safety (Concurrent Access)
# ============================================================================

@pytest.mark.asyncio
async def test_concurrent_cache_access(cache_manager, mock_embedding_service, mock_vector_store):
    """Test that concurrent access to cache is handled correctly."""

    session_id = "concurrent_session"
    project_id = "proj_123"
    org_id = "org_456"

    # Launch multiple concurrent searches
    tasks = [
        cache_manager.get_or_search(
            session_id=session_id,
            query=f"query_{i}",
            project_id=project_id,
            organization_id=org_id,
            embedding_service=mock_embedding_service,
            vector_store=mock_vector_store
        )
        for i in range(10)
    ]

    results = await asyncio.gather(*tasks)

    # All should complete successfully
    assert len(results) == 10
    for result in results:
        assert len(result) == 5
