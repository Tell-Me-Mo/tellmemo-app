"""
Test Resend Service Configuration and Rate Limit Status

This test verifies that the Resend service is properly configured
and rate limit information is correctly tracked.
"""

import sys
import os

# Add backend directory to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from services.email.resend_service import ResendService
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
        print("✅ Resend service configured successfully")
        print(f"   - From email: {service.from_email}")
        print(f"   - From name: {service.from_name}")
    else:
        print("⚠️  Resend service not configured (API key missing)")
        print("   Set RESEND_API_KEY environment variable to enable")

    # Test 2: Check rate limit status structure
    print("\n[Test 2] Testing rate limit status endpoint...")
    status = service.get_rate_limit_status()

    print(f"  Provider: {status.get('provider')}")
    print(f"  Rate limit (req/sec): {status.get('rate_limit', {}).get('requests_per_second')}")
    print(f"  Free tier limits:")
    print(f"    - Daily: {status.get('limits', {}).get('free_daily')} emails")
    print(f"    - Monthly: {status.get('limits', {}).get('free_monthly')} emails")
    print(f"    - Max recipients/email: {status.get('limits', {}).get('max_recipients_per_email')}")
    print(f"    - Max batch size: {status.get('limits', {}).get('max_batch_size')}")
    print(f"    - Max attachment size: {status.get('limits', {}).get('max_attachment_size_mb')} MB")

    # Verify structure
    assert "provider" in status, "Missing provider field"
    assert status["provider"] == "resend", "Provider should be resend"
    assert "rate_limit" in status, "Missing rate_limit field"
    assert "limits" in status, "Missing limits field"
    print("✅ Rate limit status structure is correct")

    # Test 3: Test idempotency key generation
    print("\n[Test 3] Testing idempotency key generation...")
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
    print("✅ Idempotency key generation works correctly")

    # Test 4: Test send_email validation (without actually sending)
    print("\n[Test 4] Testing send_email validation...")

    if not service.is_configured():
        result = service.send_email(
            to_email="test@example.com",
            subject="Test",
            html_content="<p>Test</p>"
        )
        assert result["success"] is False
        assert "not configured" in result["error"].lower()
        print("✅ Correctly rejects email when not configured")
    else:
        # Test recipient limit validation
        too_many_recipients = ",".join([f"user{i}@example.com" for i in range(51)])
        result = service.send_email(
            to_email=too_many_recipients,
            subject="Test",
            html_content="<p>Test</p>"
        )
        assert result["success"] is False
        assert "too many recipients" in result["error"].lower()
        print("✅ Correctly rejects too many recipients")

    print("\n" + "=" * 60)
    print("All tests completed successfully!")
    print("=" * 60)


if __name__ == "__main__":
    test_resend_service_configuration()
