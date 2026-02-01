"""
Test Resend Service with Redis-backed Rate Limiting

This test verifies that the Resend service properly implements
Redis-backed distributed rate limiting for multi-instance deployments.
"""

import sys
import os
from unittest.mock import patch, MagicMock
from datetime import datetime, timedelta

# Add backend directory to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from services.email.resend_service import ResendService, RESEND_DAILY_LIMIT, RESEND_MONTHLY_LIMIT
from config import get_settings

settings = get_settings()


def test_resend_service_configuration():
    """Test that Resend service initializes correctly"""
    print("=" * 60)
    print("Testing Resend Service Configuration")
    print("=" * 60)

    # Test 1: Create service and check initial state
    print("\n[Test 1] Creating Resend service...")
    service = ResendService()

    if service.is_configured():
        print("  Resend service configured successfully")
        print(f"   - From email: {service.from_email}")
        print(f"   - From name: {service.from_name}")
    else:
        print("  Resend service not configured (API key missing)")
        print("   Set RESEND_API_KEY environment variable to enable")

    # Test 2: Check Redis connection status
    print("\n[Test 2] Testing Redis connection for rate limiting...")
    if service.redis_client:
        print("  Redis connected for distributed rate limiting")
    else:
        print("  Using in-memory fallback (Redis unavailable)")

    # Test 3: Check rate limit status structure
    print("\n[Test 3] Testing rate limit status endpoint...")
    status = service.get_rate_limit_status()

    print(f"  Provider: {status.get('provider')}")
    print(f"  Storage: {status.get('storage')}")
    print(f"  Rate limit (req/sec): {status.get('rate_limit', {}).get('requests_per_second')}")
    print(f"  Daily quota:")
    daily = status.get('quotas', {}).get('daily', {})
    print(f"    - Limit: {daily.get('limit')}")
    print(f"    - Remaining: {daily.get('remaining')}")
    print(f"    - Used: {daily.get('used')}")
    print(f"    - Percentage used: {daily.get('percentage_used')}%")
    print(f"  Monthly quota:")
    monthly = status.get('quotas', {}).get('monthly', {})
    print(f"    - Limit: {monthly.get('limit')}")
    print(f"    - Remaining: {monthly.get('remaining')}")
    print(f"    - Used: {monthly.get('used')}")
    print(f"    - Percentage used: {monthly.get('percentage_used')}%")

    # Verify structure
    assert "provider" in status, "Missing provider field"
    assert status["provider"] == "resend", "Provider should be resend"
    assert "storage" in status, "Missing storage field"
    assert status["storage"] in ["redis", "memory"], "Storage should be redis or memory"
    assert "quotas" in status, "Missing quotas field"
    assert "daily" in status["quotas"], "Missing daily quota"
    assert "monthly" in status["quotas"], "Missing monthly quota"
    assert "rate_limit" in status, "Missing rate_limit field"
    assert "limits" in status, "Missing limits field"
    print("  Rate limit status structure is correct")


def test_redis_rate_limit_methods():
    """Test Redis-backed rate limit getter/setter methods"""
    print("\n" + "=" * 60)
    print("Testing Redis Rate Limit Methods")
    print("=" * 60)

    service = ResendService()

    # Test daily quota methods
    print("\n[Test 4] Testing daily quota get/set...")
    initial_daily = service._get_daily_remaining()
    print(f"  Initial daily remaining: {initial_daily}")
    assert initial_daily <= RESEND_DAILY_LIMIT, "Daily remaining should not exceed limit"

    # Test setting daily quota
    test_value = 50
    service._set_daily_remaining(test_value)
    retrieved = service._get_daily_remaining()
    assert retrieved == test_value, f"Expected {test_value}, got {retrieved}"
    print(f"  Set daily to {test_value}, retrieved: {retrieved}")

    # Restore original
    service._set_daily_remaining(initial_daily)
    print("  Daily quota methods work correctly")

    # Test monthly quota methods
    print("\n[Test 5] Testing monthly quota get/set...")
    initial_monthly = service._get_monthly_remaining()
    print(f"  Initial monthly remaining: {initial_monthly}")
    assert initial_monthly <= RESEND_MONTHLY_LIMIT, "Monthly remaining should not exceed limit"

    # Test setting monthly quota
    test_value = 1500
    service._set_monthly_remaining(test_value)
    retrieved = service._get_monthly_remaining()
    assert retrieved == test_value, f"Expected {test_value}, got {retrieved}"
    print(f"  Set monthly to {test_value}, retrieved: {retrieved}")

    # Restore original
    service._set_monthly_remaining(initial_monthly)
    print("  Monthly quota methods work correctly")


def test_rate_limit_check():
    """Test pre-send rate limit checking"""
    print("\n" + "=" * 60)
    print("Testing Rate Limit Check")
    print("=" * 60)

    service = ResendService()

    # Test with available quota
    print("\n[Test 6] Testing rate limit check with available quota...")
    # Ensure we have quota
    service._set_daily_remaining(50)
    service._set_monthly_remaining(1000)

    result = service._check_rate_limit()
    assert result["allowed"] is True, "Should be allowed with available quota"
    print("  Rate limit check passed with available quota")

    # Test with exhausted daily quota
    print("\n[Test 7] Testing rate limit check with exhausted daily quota...")
    service._set_daily_remaining(0)
    tomorrow = datetime.utcnow() + timedelta(days=1)
    service._set_daily_reset_time(tomorrow)

    result = service._check_rate_limit()
    assert result["allowed"] is False, "Should be blocked with no daily quota"
    assert result["error_type"] == "daily_quota", "Error type should be daily_quota"
    print(f"  Correctly blocked: {result['error']}")

    # Restore daily quota
    service._set_daily_remaining(RESEND_DAILY_LIMIT)
    service._set_daily_reset_time(None)

    # Test with exhausted monthly quota
    print("\n[Test 8] Testing rate limit check with exhausted monthly quota...")
    service._set_monthly_remaining(0)
    next_month = datetime.utcnow() + timedelta(days=30)
    service._set_monthly_reset_time(next_month)

    result = service._check_rate_limit()
    assert result["allowed"] is False, "Should be blocked with no monthly quota"
    assert result["error_type"] == "monthly_quota", "Error type should be monthly_quota"
    print(f"  Correctly blocked: {result['error']}")

    # Restore monthly quota
    service._set_monthly_remaining(RESEND_MONTHLY_LIMIT)
    service._set_monthly_reset_time(None)


def test_rate_limit_update():
    """Test rate limit counter updates after sending"""
    print("\n" + "=" * 60)
    print("Testing Rate Limit Update")
    print("=" * 60)

    service = ResendService()

    # Set known values
    print("\n[Test 9] Testing rate limit decrement after send...")
    service._set_daily_remaining(100)
    service._set_monthly_remaining(3000)

    # Simulate sending 5 emails
    service._update_rate_limit(5)

    daily_after = service._get_daily_remaining()
    monthly_after = service._get_monthly_remaining()

    assert daily_after == 95, f"Expected daily=95, got {daily_after}"
    assert monthly_after == 2995, f"Expected monthly=2995, got {monthly_after}"
    print(f"  After sending 5 emails: daily={daily_after}, monthly={monthly_after}")
    print("  Rate limit update works correctly")

    # Restore
    service._set_daily_remaining(RESEND_DAILY_LIMIT)
    service._set_monthly_remaining(RESEND_MONTHLY_LIMIT)


def test_idempotency_key_generation():
    """Test idempotency key generation"""
    print("\n" + "=" * 60)
    print("Testing Idempotency Key Generation")
    print("=" * 60)

    service = ResendService()

    print("\n[Test 10] Testing idempotency key generation...")
    key1 = service._generate_idempotency_key("test@example.com", "Test Subject", "digest")
    key2 = service._generate_idempotency_key("test@example.com", "Test Subject", "digest")
    key3 = service._generate_idempotency_key("other@example.com", "Test Subject", "digest")

    print(f"  - Key 1 (same params): {key1[:32]}...")
    print(f"  - Key 2 (same params): {key2[:32]}...")
    print(f"  - Key 3 (diff email): {key3[:32]}...")

    # Same params should generate same key (within same hour)
    assert key1 == key2, "Same parameters should generate same key"
    # Different email should generate different key
    assert key1 != key3, "Different parameters should generate different key"
    # Key should be 64 chars (SHA256 hex)
    assert len(key1) == 64, f"Key should be 64 chars, got {len(key1)}"
    print("  Idempotency key generation works correctly")


def test_send_email_rate_limit_enforcement():
    """Test that send_email enforces rate limits before sending"""
    print("\n" + "=" * 60)
    print("Testing Send Email Rate Limit Enforcement")
    print("=" * 60)

    service = ResendService()

    print("\n[Test 11] Testing send_email rejects when quota exhausted...")

    # Set daily quota to 0
    service._set_daily_remaining(0)
    tomorrow = datetime.utcnow() + timedelta(days=1)
    service._set_daily_reset_time(tomorrow)

    # Try to send email
    result = service.send_email(
        to_email="test@example.com",
        subject="Test",
        html_content="<p>Test</p>"
    )

    # Should fail due to rate limit, not due to unconfigured API
    if not service.is_configured():
        print("  Skipping - API not configured")
    else:
        assert result["success"] is False, "Should fail when quota exhausted"
        assert "quota" in result["error"].lower() or "rate limit" in result["error"].lower()
        assert result.get("error_type") == "daily_quota", "Should be daily_quota error"
        print(f"  Correctly rejected: {result['error']}")

    # Restore quota
    service._set_daily_remaining(RESEND_DAILY_LIMIT)
    service._set_daily_reset_time(None)


def test_batch_send_rate_limit_enforcement():
    """Test that send_batch enforces rate limits before sending"""
    print("\n" + "=" * 60)
    print("Testing Batch Send Rate Limit Enforcement")
    print("=" * 60)

    service = ResendService()

    print("\n[Test 12] Testing send_batch rejects when batch exceeds quota...")

    # Set daily quota to 5
    service._set_daily_remaining(5)

    # Try to send 10 emails
    emails = [
        {"to": f"user{i}@example.com", "subject": "Test", "html": "<p>Test</p>"}
        for i in range(10)
    ]

    result = service.send_batch(emails)

    if not service.is_configured():
        assert result["success"] is False
        assert "not configured" in result["error"].lower()
        print("  Correctly rejected (API not configured)")
    else:
        assert result["success"] is False, "Should fail when batch exceeds quota"
        assert "exceeds" in result["error"].lower() or "quota" in result["error"].lower()
        print(f"  Correctly rejected: {result['error']}")

    # Restore quota
    service._set_daily_remaining(RESEND_DAILY_LIMIT)


def run_all_tests():
    """Run all rate limiting tests"""
    print("\n" + "=" * 60)
    print("RESEND SERVICE REDIS RATE LIMITING TESTS")
    print("=" * 60)

    test_resend_service_configuration()
    test_redis_rate_limit_methods()
    test_rate_limit_check()
    test_rate_limit_update()
    test_idempotency_key_generation()
    test_send_email_rate_limit_enforcement()
    test_batch_send_rate_limit_enforcement()

    print("\n" + "=" * 60)
    print("ALL TESTS COMPLETED SUCCESSFULLY!")
    print("=" * 60)


if __name__ == "__main__":
    run_all_tests()
