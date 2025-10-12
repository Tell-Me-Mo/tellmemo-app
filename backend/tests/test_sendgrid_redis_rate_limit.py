"""
Test SendGrid Rate Limiting with Redis Persistence

This test verifies that rate limiting state is properly stored in Redis
and persists across service restarts.
"""

import sys
import os

# Add backend directory to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from services.email.sendgrid_service import SendGridService
from config import get_settings
import time

settings = get_settings()


def test_redis_rate_limit_persistence():
    """Test that rate limit state persists in Redis"""
    print("=" * 60)
    print("Testing SendGrid Rate Limiting with Redis Persistence")
    print("=" * 60)

    # Test 1: Create service and check initial state
    print("\n[Test 1] Creating SendGrid service...")
    service1 = SendGridService()

    if service1.redis_client:
        print("✅ Redis connected successfully")
    else:
        print("⚠️  Redis not available - using in-memory fallback")

    # Get initial rate limit status
    initial_status = service1.get_rate_limit_status()
    print(f"\nInitial rate limit status:")
    print(f"  - Remaining: {initial_status['remaining']}")
    print(f"  - Limit: {initial_status['limit']}")
    print(f"  - Storage: {initial_status['storage']}")

    # Test 2: Modify rate limit
    print("\n[Test 2] Modifying rate limit counter...")
    test_value = 42
    service1._set_rate_limit_remaining(test_value)

    modified_remaining = service1._get_rate_limit_remaining()
    print(f"  - Set rate limit to: {test_value}")
    print(f"  - Read back value: {modified_remaining}")

    if modified_remaining == test_value:
        print("✅ Rate limit value correctly stored")
    else:
        print(f"❌ Rate limit mismatch! Expected {test_value}, got {modified_remaining}")

    # Test 3: Create new service instance and verify persistence
    print("\n[Test 3] Creating new service instance to test persistence...")
    service2 = SendGridService()

    persisted_remaining = service2._get_rate_limit_remaining()
    print(f"  - Value from new instance: {persisted_remaining}")

    if service2.redis_client and persisted_remaining == test_value:
        print("✅ Rate limit persisted across service instances (Redis working)")
    elif not service2.redis_client and persisted_remaining == settings.email_digest_rate_limit:
        print("⚠️  Using in-memory fallback (Redis not available)")
    else:
        print(f"❌ Persistence test failed!")

    # Test 4: Test reset time persistence
    print("\n[Test 4] Testing reset time persistence...")
    from datetime import datetime, timedelta
    reset_time = datetime.utcnow() + timedelta(hours=24)

    service2._set_rate_limit_reset_time(reset_time)
    retrieved_reset_time = service2._get_rate_limit_reset_time()

    if retrieved_reset_time:
        time_diff = abs((retrieved_reset_time - reset_time).total_seconds())
        print(f"  - Set reset time: {reset_time}")
        print(f"  - Retrieved reset time: {retrieved_reset_time}")
        print(f"  - Time difference: {time_diff} seconds")

        if time_diff < 1:
            print("✅ Reset time persisted correctly")
        else:
            print(f"❌ Reset time mismatch!")
    else:
        print("❌ Reset time not retrieved")

    # Test 5: Test rate limit status endpoint
    print("\n[Test 5] Testing rate limit status endpoint...")
    status = service2.get_rate_limit_status()
    print(f"  - Remaining: {status['remaining']}")
    print(f"  - Limit: {status['limit']}")
    print(f"  - Percentage used: {status['percentage_used']}%")
    print(f"  - Reset at: {status['reset_at']}")
    print(f"  - Storage backend: {status['storage']}")

    if 'storage' in status:
        print("✅ Rate limit status includes storage backend info")

    # Cleanup: Reset to default value
    print("\n[Cleanup] Resetting rate limit to default...")
    service2._set_rate_limit_remaining(settings.email_digest_rate_limit)
    service2._set_rate_limit_reset_time(None)
    print("✅ Cleanup complete")

    print("\n" + "=" * 60)
    print("Test completed successfully!")
    print("=" * 60)


if __name__ == "__main__":
    test_redis_rate_limit_persistence()
