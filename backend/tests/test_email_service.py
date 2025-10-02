#!/usr/bin/env python3
"""
Test script for Supabase email service functionality
"""

import asyncio
import sys
import os
from pathlib import Path

# Add backend to path
backend_dir = Path(__file__).parent
sys.path.insert(0, str(backend_dir))

from services.integrations.email_service import email_service


async def test_email_service():
    """Test the email service (Supabase)"""

    print("Testing Email Service (Supabase)")
    print("=" * 50)

    # Test invitation email
    print("\n1. Testing Invitation Email via Supabase...")
    print("   Note: Supabase inviteUserByEmail will create a user and send invitation")
    print("   In development, this only works for team members' emails")

    invitation_sent = await email_service.send_invitation_email(
        invitation_email="test@example.com",
        invitation_token="test-token-123",
        organization_name="Acme Corporation",
        inviter_name="John Doe",
        role="member"
    )
    print(f"   Invitation email result: {invitation_sent}")

    # Test password reset email
    print("\n2. Testing Password Reset Email...")
    print("   Note: This will only work for existing users in Supabase")

    reset_sent = await email_service.send_password_reset_email(
        user_email="user@example.com"
    )
    print(f"   Password reset result: {reset_sent}")

    # Test magic link
    print("\n3. Testing Magic Link Email...")
    magic_link_sent = await email_service.send_magic_link_email(
        user_email="user@example.com"
    )
    print(f"   Magic link result: {magic_link_sent}")

    # Test weekly report (custom email)
    print("\n4. Testing Custom Email (Weekly Report)...")
    report_data = {
        "meetings_count": 12,
        "summaries_count": 8,
        "decisions_count": 23,
        "actions_count": 15
    }
    report_sent = await email_service.send_weekly_report_email(
        user_email="manager@example.com",
        user_name="Charlie Wilson",
        organization_name="Enterprise Corp",
        report_data=report_data
    )
    print(f"   Weekly report result: {report_sent}")

    print("\n" + "=" * 50)
    print("Email Service Test Complete")
    print("\nIMPORTANT NOTES:")
    print("1. Supabase Auth emails only work for:")
    print("   - Team members' emails (in development)")
    print("   - Any email if custom SMTP is configured")
    print("2. Email templates are configured in Supabase Dashboard:")
    print("   - Go to Authentication > Email Templates")
    print("3. For custom emails (weekly reports), implement Edge Functions")
    print("4. Check Supabase logs for actual email delivery status")


if __name__ == "__main__":
    asyncio.run(test_email_service())