"""
Test Redis Cache Service for Session Caching

This test verifies that Redis caching is working correctly for session management.
"""

import asyncio
import pytest
from uuid import uuid4

from services.cache.redis_cache_service import redis_cache


@pytest.mark.asyncio
async def test_redis_connection():
    """Test Redis connection is available"""
    is_available = await redis_cache.is_available()
    assert is_available, "Redis should be available"


@pytest.mark.asyncio
async def test_session_cache_operations():
    """Test basic session cache operations (get, set, delete)"""
    # Generate test user ID
    user_id = uuid4()

    # Test session data
    session_data = {
        "user_id": str(user_id),
        "email": "test@example.com",
        "org_id": str(uuid4()),
        "org_name": "Test Organization",
        "role": "admin"
    }

    # Set session
    success = await redis_cache.set_session(user_id, session_data)
    assert success, "Session should be cached successfully"

    # Get session
    cached_session = await redis_cache.get_session(user_id)
    assert cached_session is not None, "Session should be retrieved from cache"
    assert cached_session["email"] == "test@example.com"
    assert cached_session["role"] == "admin"

    # Delete session
    success = await redis_cache.delete_session(user_id)
    assert success, "Session should be deleted successfully"

    # Verify deletion
    cached_session = await redis_cache.get_session(user_id)
    assert cached_session is None, "Session should not exist after deletion"


@pytest.mark.asyncio
async def test_session_ttl():
    """Test session TTL is set correctly"""
    user_id = uuid4()

    session_data = {
        "user_id": str(user_id),
        "email": "ttl_test@example.com",
        "org_id": str(uuid4()),
        "role": "member"
    }

    # Set session with 1-minute TTL
    success = await redis_cache.set_session(user_id, session_data, ttl_minutes=1)
    assert success, "Session should be cached with TTL"

    # Verify session exists
    cached_session = await redis_cache.get_session(user_id)
    assert cached_session is not None, "Session should exist immediately after caching"

    # Clean up
    await redis_cache.delete_session(user_id)


@pytest.mark.asyncio
async def test_cache_miss():
    """Test cache miss returns None"""
    # Generate random user ID that doesn't exist in cache
    non_existent_user_id = uuid4()

    cached_session = await redis_cache.get_session(non_existent_user_id)
    assert cached_session is None, "Cache miss should return None"


if __name__ == "__main__":
    # Run tests manually if needed
    async def run_tests():
        print("Testing Redis connection...")
        await test_redis_connection()
        print("✓ Redis connection test passed")

        print("Testing session cache operations...")
        await test_session_cache_operations()
        print("✓ Session cache operations test passed")

        print("Testing session TTL...")
        await test_session_ttl()
        print("✓ Session TTL test passed")

        print("Testing cache miss...")
        await test_cache_miss()
        print("✓ Cache miss test passed")

        print("\n✓ All tests passed!")

        # Close Redis connection
        await redis_cache.close()

    asyncio.run(run_tests())
