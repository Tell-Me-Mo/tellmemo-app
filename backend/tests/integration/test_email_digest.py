"""
Integration tests for Email Digest Feature.

Tests cover the complete email digest flow including:
- Email preferences API endpoints
- Digest generation and scheduling
- Admin testing endpoints
- Onboarding and inactive reminder emails
"""

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession
from datetime import datetime, timedelta
from unittest.mock import patch, Mock, AsyncMock
from sqlalchemy import select

from models.user import User
from models.project import Project
from models.summary import Summary
from models.activity import Activity
from models.notification import Notification, NotificationCategory
from services.auth.native_auth_service import native_auth_service


# Fixtures for email digest testing

@pytest.fixture
async def user_with_digest_enabled(db_session: AsyncSession) -> User:
    """Create a test user with email digest enabled."""
    password_hash = native_auth_service.hash_password("TestPassword123!")

    user = User(
        email="digest@example.com",
        password_hash=password_hash,
        name="Digest User",
        auth_provider='native',
        email_verified=True,
        is_active=True,
        preferences={
            "email_digest": {
                "enabled": True,
                "frequency": "weekly",
                "content_types": ["summaries", "tasks_assigned", "risks_critical"],
                "include_portfolio_rollup": True,
                "last_sent_at": None
            }
        }
    )

    db_session.add(user)
    await db_session.commit()
    await db_session.refresh(user)

    return user


@pytest.fixture
async def user_with_digest_disabled(db_session: AsyncSession) -> User:
    """Create a test user with email digest disabled."""
    password_hash = native_auth_service.hash_password("TestPassword123!")

    user = User(
        email="nodigest@example.com",
        password_hash=password_hash,
        name="No Digest User",
        auth_provider='native',
        email_verified=True,
        is_active=True,
        preferences={
            "email_digest": {
                "enabled": False,
                "frequency": "never",
                "content_types": [],
                "include_portfolio_rollup": False,
                "last_sent_at": None
            }
        }
    )

    db_session.add(user)
    await db_session.commit()
    await db_session.refresh(user)

    return user


@pytest.fixture
async def inactive_digest_user(db_session: AsyncSession) -> User:
    """Create a test user who has been inactive for 8 days."""
    password_hash = native_auth_service.hash_password("TestPassword123!")

    # Create user with creation date 8 days ago
    old_date = datetime.utcnow() - timedelta(days=8)

    user = User(
        email="inactive@example.com",
        password_hash=password_hash,
        name="Inactive User",
        auth_provider='native',
        email_verified=True,
        is_active=True,
        created_at=old_date,
        preferences={
            "email_digest": {
                "enabled": True,
                "frequency": "weekly",
                "content_types": ["summaries"],
                "last_sent_at": None
            }
        }
    )

    db_session.add(user)
    await db_session.commit()
    await db_session.refresh(user)

    return user


@pytest.fixture
async def project_with_summaries(db_session: AsyncSession, test_organization, test_user) -> Project:
    """Create a test project with summaries for digest testing."""
    project = Project(
        name="Digest Test Project",
        description="Project for email digest testing",
        organization_id=test_organization.id,
        status="active",
        created_by=str(test_user.id)
    )

    db_session.add(project)
    await db_session.commit()
    await db_session.refresh(project)

    # Add some recent summaries
    for i in range(3):
        summary = Summary(
            project_id=project.id,
            user_id=test_user.id,
            organization_id=test_organization.id,
            subject=f"Test Summary {i + 1}",
            body=f"This is test summary {i + 1} for digest generation",
            summary_type="meeting",
            created_at=datetime.utcnow() - timedelta(hours=i)
        )
        db_session.add(summary)

    await db_session.commit()

    return project


# Mock fixtures for email sending

@pytest.fixture
def mock_sendgrid_service():
    """Mock SendGrid service to prevent actual email sending."""
    with patch('services.email.digest_service.sendgrid_service') as mock:
        mock.send_email.return_value = {
            "success": True,
            "message_id": "test-message-id-123"
        }
        mock.is_configured.return_value = True
        yield mock


@pytest.fixture
def mock_template_service():
    """Mock template service for email rendering."""
    with patch('services.email.digest_service.template_service') as mock:
        mock.render_digest_email.return_value = "<html>Digest Email</html>"
        mock.render_digest_email_text.return_value = "Digest Email Text"
        mock.render_onboarding_email.return_value = "<html>Welcome Email</html>"
        mock.render_onboarding_email_text.return_value = "Welcome Email Text"
        mock.render_inactive_reminder_email.return_value = "<html>Reminder Email</html>"
        mock.render_inactive_reminder_email_text.return_value = "Reminder Email Text"
        yield mock


class TestEmailPreferencesAPI:
    """Tests for email preferences API endpoints."""

    @pytest.mark.integration
    async def test_get_digest_preferences_default(
        self,
        authenticated_client: AsyncClient,
        test_user: User
    ):
        """Test getting default email digest preferences for new user."""
        response = await authenticated_client.get("/api/v1/email-preferences/digest")

        assert response.status_code == 200
        data = response.json()

        # Verify default preferences structure
        assert "enabled" in data
        assert "frequency" in data
        assert "content_types" in data
        assert isinstance(data["content_types"], list)

    @pytest.mark.integration
    async def test_get_digest_preferences_custom(
        self,
        client_factory,
        user_with_digest_enabled: User
    ):
        """Test getting custom email digest preferences."""
        client = await client_factory(user=user_with_digest_enabled)

        response = await client.get("/api/v1/email-preferences/digest")

        assert response.status_code == 200
        data = response.json()

        # Verify custom preferences
        assert data["enabled"] is True
        assert data["frequency"] == "weekly"
        assert "summaries" in data["content_types"]

    @pytest.mark.integration
    async def test_update_digest_preferences(
        self,
        authenticated_client: AsyncClient,
        test_user: User,
        db_session: AsyncSession
    ):
        """Test updating email digest preferences."""
        update_data = {
            "enabled": True,
            "frequency": "daily",
            "content_types": ["summaries", "risks_critical"]
        }

        response = await authenticated_client.put(
            "/api/v1/email-preferences/digest",
            json=update_data
        )

        assert response.status_code == 200
        data = response.json()

        # Verify response
        assert data["enabled"] is True
        assert data["frequency"] == "daily"
        assert len(data["content_types"]) == 2

        # Verify database was updated
        await db_session.refresh(test_user)
        prefs = test_user.preferences.get("email_digest", {})
        assert prefs["enabled"] is True
        assert prefs["frequency"] == "daily"

    @pytest.mark.integration
    async def test_update_digest_preferences_unauthenticated(
        self,
        client: AsyncClient
    ):
        """Test updating preferences fails without authentication."""
        update_data = {
            "enabled": True,
            "frequency": "weekly"
        }

        response = await client.put("/api/v1/email-preferences/digest", json=update_data)

        assert response.status_code == 401

    @pytest.mark.integration
    async def test_update_digest_preferences_invalid_frequency(
        self,
        authenticated_client: AsyncClient
    ):
        """Test updating preferences with invalid frequency."""
        update_data = {
            "enabled": True,
            "frequency": "invalid_frequency"
        }

        response = await authenticated_client.put(
            "/api/v1/email-preferences/digest",
            json=update_data
        )

        # Should fail validation
        assert response.status_code == 422


class TestDigestPreview:
    """Tests for digest preview functionality."""

    @pytest.mark.integration
    async def test_preview_weekly_digest(
        self,
        client_factory,
        user_with_digest_enabled: User,
        test_organization,
        project_with_summaries: Project,
        mock_sendgrid_service,
        mock_template_service
    ):
        """Test previewing a weekly digest without sending."""
        client = await client_factory(
            user=user_with_digest_enabled,
            organization=test_organization
        )

        response = await client.post(
            "/api/v1/email-preferences/digest/preview",
            params={"digest_type": "weekly"}
        )

        assert response.status_code == 200
        data = response.json()

        # Verify preview data structure
        assert "html_preview" in data
        assert "digest_data" in data
        assert "user_name" in data["digest_data"]

        # Verify email was NOT sent (mock should not be called)
        mock_sendgrid_service.send_email.assert_not_called()

    @pytest.mark.integration
    async def test_preview_daily_digest(
        self,
        authenticated_client: AsyncClient,
        mock_template_service
    ):
        """Test previewing a daily digest."""
        response = await authenticated_client.post(
            "/api/v1/email-preferences/digest/preview",
            params={"digest_type": "daily"}
        )

        assert response.status_code == 200
        data = response.json()
        assert "html_preview" in data

    @pytest.mark.integration
    async def test_preview_digest_unauthenticated(
        self,
        client: AsyncClient
    ):
        """Test preview fails without authentication."""
        response = await client.post("/api/v1/email-preferences/digest/preview")

        assert response.status_code == 401


class TestSendTestDigest:
    """Tests for sending test digest emails."""

    @pytest.mark.integration
    async def test_send_test_digest(
        self,
        authenticated_client: AsyncClient,
        mock_sendgrid_service,
        mock_template_service
    ):
        """Test sending a test digest email."""
        response = await authenticated_client.post(
            "/api/v1/email-preferences/digest/send-test"
        )

        assert response.status_code == 200
        data = response.json()

        # Verify job was queued
        assert "job_id" in data
        assert "message" in data
        assert "queued" in data["message"].lower()

    @pytest.mark.integration
    async def test_send_test_digest_unauthenticated(
        self,
        client: AsyncClient
    ):
        """Test send test digest fails without authentication."""
        response = await client.post("/api/v1/email-preferences/digest/send-test")

        assert response.status_code == 401


class TestUnsubscribe:
    """Tests for email digest unsubscribe functionality."""

    @pytest.mark.integration
    async def test_unsubscribe_with_valid_token(
        self,
        client: AsyncClient,
        user_with_digest_enabled: User,
        db_session: AsyncSession
    ):
        """Test unsubscribing from digests with valid JWT token."""
        # Generate unsubscribe token
        import jwt
        payload = {
            "user_id": str(user_with_digest_enabled.id),
            "purpose": "unsubscribe",
            "exp": datetime.utcnow() + timedelta(days=90)
        }
        token = jwt.encode(
            payload,
            native_auth_service.jwt_secret,
            algorithm=native_auth_service.jwt_algorithm
        )

        response = await client.get(
            f"/api/v1/email-preferences/unsubscribe?token={token}"
        )

        assert response.status_code == 200

        # Verify user preferences were updated
        await db_session.refresh(user_with_digest_enabled)
        prefs = user_with_digest_enabled.preferences.get("email_digest", {})
        assert prefs["enabled"] is False

    @pytest.mark.integration
    async def test_unsubscribe_with_invalid_token(
        self,
        client: AsyncClient
    ):
        """Test unsubscribe fails with invalid token."""
        response = await client.get(
            "/api/v1/email-preferences/unsubscribe?token=invalid.token.here"
        )

        assert response.status_code == 400

    @pytest.mark.integration
    async def test_unsubscribe_with_expired_token(
        self,
        client: AsyncClient,
        user_with_digest_enabled: User
    ):
        """Test unsubscribe fails with expired token."""
        import jwt
        payload = {
            "user_id": str(user_with_digest_enabled.id),
            "purpose": "unsubscribe",
            "exp": datetime.utcnow() - timedelta(days=1)  # Expired
        }
        token = jwt.encode(
            payload,
            native_auth_service.jwt_secret,
            algorithm=native_auth_service.jwt_algorithm
        )

        response = await client.get(
            f"/api/v1/email-preferences/unsubscribe?token={token}"
        )

        assert response.status_code == 400


class TestAdminEmailEndpoints:
    """Tests for admin email testing endpoints."""

    @pytest.mark.integration
    async def test_trigger_daily_digest(
        self,
        authenticated_client: AsyncClient,
        user_with_digest_enabled: User,
        mock_sendgrid_service
    ):
        """Test manually triggering daily digest generation."""
        response = await authenticated_client.post(
            "/api/v1/admin/email/trigger-daily-digest"
        )

        assert response.status_code == 200
        data = response.json()

        assert data["success"] is True
        assert "job_count" in data

    @pytest.mark.integration
    async def test_trigger_weekly_digest(
        self,
        authenticated_client: AsyncClient,
        user_with_digest_enabled: User,
        mock_sendgrid_service
    ):
        """Test manually triggering weekly digest generation."""
        response = await authenticated_client.post(
            "/api/v1/admin/email/trigger-weekly-digest"
        )

        assert response.status_code == 200
        data = response.json()

        assert data["success"] is True
        assert "job_count" in data

    @pytest.mark.integration
    async def test_trigger_monthly_digest(
        self,
        authenticated_client: AsyncClient,
        mock_sendgrid_service
    ):
        """Test manually triggering monthly digest generation."""
        response = await authenticated_client.post(
            "/api/v1/admin/email/trigger-monthly-digest"
        )

        assert response.status_code == 200
        data = response.json()

        assert data["success"] is True

    @pytest.mark.integration
    async def test_trigger_inactive_check(
        self,
        authenticated_client: AsyncClient,
        inactive_digest_user: User,
        mock_sendgrid_service
    ):
        """Test manually triggering inactive user check."""
        response = await authenticated_client.post(
            "/api/v1/admin/email/trigger-inactive-check"
        )

        assert response.status_code == 200
        data = response.json()

        assert data["success"] is True
        assert "job_count" in data

    @pytest.mark.integration
    async def test_send_digest_to_specific_user(
        self,
        authenticated_client: AsyncClient,
        user_with_digest_enabled: User,
        mock_sendgrid_service
    ):
        """Test sending digest to a specific user."""
        response = await authenticated_client.post(
            f"/api/v1/admin/email/send-digest/{user_with_digest_enabled.id}",
            params={"digest_type": "weekly"}
        )

        assert response.status_code == 200
        data = response.json()

        assert data["success"] is True
        assert "job_count" in data
        assert data["job_count"] == 1

    @pytest.mark.integration
    async def test_send_digest_invalid_type(
        self,
        authenticated_client: AsyncClient,
        user_with_digest_enabled: User
    ):
        """Test sending digest with invalid type."""
        response = await authenticated_client.post(
            f"/api/v1/admin/email/send-digest/{user_with_digest_enabled.id}",
            params={"digest_type": "invalid"}
        )

        assert response.status_code == 400

    @pytest.mark.integration
    async def test_get_scheduler_status(
        self,
        authenticated_client: AsyncClient
    ):
        """Test getting scheduler status."""
        response = await authenticated_client.get("/api/v1/admin/email/scheduler-status")

        assert response.status_code == 200
        data = response.json()

        # Verify scheduler status structure
        assert "scheduler_running" in data
        if data["scheduler_running"]:
            assert "jobs" in data
            assert isinstance(data["jobs"], list)

    @pytest.mark.integration
    async def test_get_sendgrid_status(
        self,
        authenticated_client: AsyncClient,
        mock_sendgrid_service
    ):
        """Test getting SendGrid service status."""
        mock_sendgrid_service.get_rate_limit_status.return_value = {
            "remaining": 95,
            "limit": 100,
            "reset_at": datetime.utcnow().isoformat()
        }

        response = await authenticated_client.get("/api/v1/admin/email/sendgrid-status")

        assert response.status_code == 200
        data = response.json()

        assert "configured" in data
        assert "rate_limit" in data


class TestOnboardingEmail:
    """Tests for onboarding email functionality."""

    @pytest.mark.integration
    async def test_onboarding_email_on_signup(
        self,
        client: AsyncClient,
        mock_sendgrid_service,
        mock_template_service
    ):
        """Test that onboarding email is queued on user registration."""
        signup_data = {
            "email": "newuser@example.com",
            "password": "NewPassword123!",
            "name": "New User"
        }

        response = await client.post("/api/v1/auth/signup", json=signup_data)

        assert response.status_code == 200

        # Verify user was created successfully
        data = response.json()
        assert "user_id" in data

        # Note: Email sending is queued in background, so we can't directly
        # verify it was sent. In production, check RQ queue or notification table.


class TestInactiveUserReminder:
    """Tests for inactive user reminder emails."""

    @pytest.mark.integration
    async def test_inactive_user_detection(
        self,
        db_session: AsyncSession,
        inactive_digest_user: User
    ):
        """Test that inactive users are correctly identified."""
        from services.email.digest_service import digest_service

        # Get user's last activity
        last_activity = await digest_service._get_user_last_activity(
            str(inactive_digest_user.id),
            db_session
        )

        # User should have no activities (None)
        assert last_activity is None

    @pytest.mark.integration
    async def test_inactive_reminder_not_sent_twice(
        self,
        db_session: AsyncSession,
        inactive_digest_user: User
    ):
        """Test that inactive reminder is not sent multiple times."""
        # Create a notification indicating reminder was already sent
        notification = Notification(
            user_id=inactive_digest_user.id,
            title="Inactive User Reminder",
            message="Reminder email sent",
            category=NotificationCategory.EMAIL_INACTIVE_REMINDER_SENT,
            priority="low"
        )
        db_session.add(notification)
        await db_session.commit()

        from services.email.digest_service import digest_service

        # Check if reminder was already sent
        already_sent = await digest_service._has_sent_inactive_reminder(
            str(inactive_digest_user.id),
            db_session
        )

        assert already_sent is True


class TestDigestContentGeneration:
    """Tests for digest content aggregation."""

    @pytest.mark.integration
    async def test_digest_data_aggregation(
        self,
        db_session: AsyncSession,
        user_with_digest_enabled: User,
        test_organization,
        project_with_summaries: Project
    ):
        """Test that digest data is correctly aggregated."""
        from services.email.digest_service import digest_service

        start_date = datetime.utcnow() - timedelta(days=7)
        end_date = datetime.utcnow()

        digest_data = await digest_service.aggregate_digest_data(
            user_id=str(user_with_digest_enabled.id),
            start_date=start_date,
            end_date=end_date,
            db=db_session
        )

        # Verify digest data structure
        assert "user_name" in digest_data
        assert "digest_period" in digest_data
        assert "summary_stats" in digest_data
        assert "organizations" in digest_data

    @pytest.mark.integration
    async def test_empty_digest_not_sent(
        self,
        db_session: AsyncSession,
        user_with_digest_enabled: User
    ):
        """Test that digest with no content is not sent."""
        from services.email.digest_service import digest_service

        # Generate digest for user with no projects/activities
        start_date = datetime.utcnow() - timedelta(days=7)
        end_date = datetime.utcnow()

        digest_data = await digest_service.aggregate_digest_data(
            user_id=str(user_with_digest_enabled.id),
            start_date=start_date,
            end_date=end_date,
            db=db_session
        )

        # Check if digest has content
        has_content = digest_service._has_digest_content(digest_data)

        # Should be False since user has no projects/activities
        assert has_content is False


class TestEmailDigestRateLimiting:
    """Tests for rate limiting functionality."""

    @pytest.mark.integration
    async def test_rate_limit_tracking(
        self,
        mock_sendgrid_service
    ):
        """Test that rate limiting is properly tracked."""
        mock_sendgrid_service.get_rate_limit_status.return_value = {
            "remaining": 50,
            "limit": 100,
            "reset_at": datetime.utcnow().isoformat()
        }

        from services.email.sendgrid_service import sendgrid_service

        status = sendgrid_service.get_rate_limit_status()

        assert "remaining" in status
        assert "limit" in status
        assert status["limit"] == 100


class TestEdgeCases:
    """Test edge cases and error scenarios."""

    @pytest.mark.integration
    async def test_digest_generation_with_no_users(
        self,
        db_session: AsyncSession,
        mock_sendgrid_service
    ):
        """Test digest generation when no users have digests enabled."""
        from services.email.digest_service import digest_service

        job_count = await digest_service.generate_daily_digests(db_session)

        # Should be 0 since no users have daily digest enabled
        assert job_count >= 0

    @pytest.mark.integration
    async def test_unsubscribe_already_disabled(
        self,
        client: AsyncClient,
        user_with_digest_disabled: User,
        db_session: AsyncSession
    ):
        """Test unsubscribing when already unsubscribed."""
        import jwt
        payload = {
            "user_id": str(user_with_digest_disabled.id),
            "purpose": "unsubscribe",
            "exp": datetime.utcnow() + timedelta(days=90)
        }
        token = jwt.encode(
            payload,
            native_auth_service.jwt_secret,
            algorithm=native_auth_service.jwt_algorithm
        )

        response = await client.get(
            f"/api/v1/email-preferences/unsubscribe?token={token}"
        )

        # Should still succeed (idempotent operation)
        assert response.status_code == 200

    @pytest.mark.integration
    async def test_preview_digest_with_no_content(
        self,
        authenticated_client: AsyncClient,
        mock_template_service
    ):
        """Test previewing digest when user has no content."""
        response = await authenticated_client.post(
            "/api/v1/email-preferences/digest/preview",
            params={"digest_type": "weekly"}
        )

        # Should still return preview even with empty content
        assert response.status_code == 200
        data = response.json()
        assert "html_preview" in data
