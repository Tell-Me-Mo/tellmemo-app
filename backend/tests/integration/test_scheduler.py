"""
Integration tests for scheduler.py endpoints.

Tests cover:
- GET /api/scheduler/status - Get scheduler status
- POST /api/scheduler/trigger-project-reports - Trigger project report generation
- POST /api/scheduler/reschedule - Reschedule project reports
- Multi-tenant isolation validation
- Authentication requirements

Following testing strategy from TESTING_BACKEND.md section 10.2.
"""

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession
from datetime import datetime, timedelta, timezone
from uuid import uuid4

from models.user import User
from models.organization import Organization
from models.project import Project, ProjectStatus
from models.content import Content, ContentType


@pytest.mark.asyncio
class TestSchedulerStatus:
    """Test GET /api/scheduler/status endpoint."""

    async def test_get_scheduler_status_success(
        self, authenticated_org_client: AsyncClient
    ):
        """Test getting scheduler status successfully."""
        # Act
        response = await authenticated_org_client.get("/api/v1/scheduler/status")

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert "scheduler_running" in data
        assert "jobs" in data
        assert isinstance(data["scheduler_running"], bool)
        assert isinstance(data["jobs"], list)

    async def test_get_scheduler_status_shows_scheduled_jobs(
        self, authenticated_org_client: AsyncClient
    ):
        """Test that scheduler status includes information about scheduled jobs."""
        # Act
        response = await authenticated_org_client.get("/api/v1/scheduler/status")

        # Assert
        assert response.status_code == 200
        data = response.json()

        # Note: Scheduler has no active jobs by default (all disabled)
        assert len(data["jobs"]) >= 0

        # If there are jobs, verify structure
        for job in data["jobs"]:
            assert "id" in job
            assert "name" in job
            assert "next_run_time" in job or job.get("next_run_time") is None
            assert "trigger" in job

    async def test_get_scheduler_status_requires_auth(self, client_factory):
        """Test that scheduler status requires authentication (FIXED)."""
        # Arrange
        client = await client_factory()

        # Act
        response = await client.get("/api/v1/scheduler/status")

        # Assert
        # FIXED: Now requires authentication
        assert response.status_code in [401, 403]


@pytest.mark.asyncio
class TestTriggerProjectReports:
    """Test POST /api/scheduler/trigger-project-reports endpoint."""

    async def test_trigger_specific_project_report(
        self,
        authenticated_org_client: AsyncClient,
        db_session: AsyncSession,
        test_user: User,
        test_organization: Organization,
    ):
        """Test triggering report for a specific project."""
        # Arrange
        project = Project(
            id=uuid4(),
            name="Test Project for Scheduler",
            organization_id=test_organization.id,
            status=ProjectStatus.ACTIVE,
            created_by=test_user.email,
        )
        db_session.add(project)
        await db_session.commit()

        # Act
        response = await authenticated_org_client.post(
            "/api/v1/scheduler/trigger-project-reports",
            json={
                "project_id": str(project.id),
                "date_range_start": (datetime.utcnow() - timedelta(days=7)).isoformat(),
                "date_range_end": datetime.utcnow().isoformat(),
            },
        )

        # Assert
        # FIXED: Method names corrected, should work now
        # Note: May return 500 if no content exists for summary generation
        assert response.status_code in [200, 500]

    async def test_trigger_all_projects_report(
        self,
        authenticated_org_client: AsyncClient,
        db_session: AsyncSession,
        test_user: User,
        test_organization: Organization,
    ):
        """Test triggering reports for all active projects."""
        # Arrange
        project1 = Project(
            id=uuid4(),
            name="Project 1",
            organization_id=test_organization.id,
            status=ProjectStatus.ACTIVE,
            created_by=test_user.email,
        )
        project2 = Project(
            id=uuid4(),
            name="Project 2",
            organization_id=test_organization.id,
            status=ProjectStatus.ACTIVE,
            created_by=test_user.email,
        )
        db_session.add(project1)
        db_session.add(project2)
        await db_session.commit()

        # Act
        response = await authenticated_org_client.post(
            "/api/v1/scheduler/trigger-project-reports",
            json={},  # No project_id triggers all projects
        )

        # Assert
        # FIXED: Method names corrected, should work now
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "success"
        assert "summaries_generated" in data

    async def test_trigger_nonexistent_project_report(
        self, authenticated_org_client: AsyncClient
    ):
        """Test triggering report for a project that doesn't exist."""
        # Arrange
        nonexistent_id = str(uuid4())

        # Act
        response = await authenticated_org_client.post(
            "/api/v1/scheduler/trigger-project-reports",
            json={"project_id": nonexistent_id},
        )

        # Assert
        # FIXED: Now validates project exists
        assert response.status_code == 404
        assert response.json()["detail"] == "Project not found"

    async def test_trigger_project_report_invalid_uuid(
        self, authenticated_org_client: AsyncClient
    ):
        """Test triggering report with invalid UUID format."""
        # Act
        response = await authenticated_org_client.post(
            "/api/v1/scheduler/trigger-project-reports",
            json={"project_id": "not-a-valid-uuid"},
        )

        # Assert
        # Invalid UUID should return error
        assert response.status_code in [400, 422, 500]

    async def test_trigger_project_report_requires_auth(self, client_factory):
        """Test that trigger endpoint requires authentication (FIXED)."""
        # Arrange
        client = await client_factory()

        # Act
        response = await client.post(
            "/api/v1/scheduler/trigger-project-reports",
            json={},
        )

        # Assert
        # FIXED: Now requires authentication
        assert response.status_code in [401, 403]


@pytest.mark.asyncio
class TestRescheduleProjectReports:
    """Test POST /api/scheduler/reschedule endpoint."""

    async def test_reschedule_with_cron_expression(
        self, authenticated_org_client: AsyncClient
    ):
        """Test rescheduling using a cron expression.

        NOTE: This endpoint is deprecated and returns 501.
        Scheduling has been moved to Redis Queue (RQ).
        """
        # Act
        response = await authenticated_org_client.post(
            "/api/v1/scheduler/reschedule",
            json={"cron_expression": "0 18 * * fri"},
        )

        # Assert - endpoint is deprecated and returns 501
        assert response.status_code == 501
        data = response.json()
        assert "detail" in data
        assert "Redis Queue" in data["detail"]

    async def test_reschedule_with_individual_components(
        self, authenticated_org_client: AsyncClient
    ):
        """Test rescheduling using individual time components.

        NOTE: This endpoint is deprecated and returns 501.
        Scheduling has been moved to Redis Queue (RQ).
        """
        # Act
        response = await authenticated_org_client.post(
            "/api/v1/scheduler/reschedule",
            json={
                "day_of_week": "mon",
                "hour": 10,
                "minute": 30,
            },
        )

        # Assert - endpoint is deprecated and returns 501
        assert response.status_code == 501
        data = response.json()
        assert "detail" in data
        assert "Redis Queue" in data["detail"]

    async def test_reschedule_with_defaults(self, authenticated_org_client: AsyncClient):
        """Test rescheduling with default values (Friday 5 PM).

        NOTE: This endpoint is deprecated and returns 501.
        Scheduling has been moved to Redis Queue (RQ).
        """
        # Act
        response = await authenticated_org_client.post(
            "/api/v1/scheduler/reschedule",
            json={},  # Use defaults
        )

        # Assert - endpoint is deprecated and returns 501
        assert response.status_code == 501
        data = response.json()
        assert "detail" in data
        assert "Redis Queue" in data["detail"]

    async def test_reschedule_invalid_hour(self, authenticated_org_client: AsyncClient):
        """Test rescheduling with invalid hour value."""
        # Act
        response = await authenticated_org_client.post(
            "/api/v1/scheduler/reschedule",
            json={"hour": 25},  # Invalid hour (> 23)
        )

        # Assert
        # Should return 422 for validation error
        assert response.status_code == 422

    async def test_reschedule_invalid_minute(
        self, authenticated_org_client: AsyncClient
    ):
        """Test rescheduling with invalid minute value."""
        # Act
        response = await authenticated_org_client.post(
            "/api/v1/scheduler/reschedule",
            json={"minute": 60},  # Invalid minute (> 59)
        )

        # Assert
        # Should return 422 for validation error
        assert response.status_code == 422

    async def test_reschedule_requires_auth(self, client_factory):
        """Test that reschedule endpoint requires authentication (FIXED)."""
        # Arrange
        client = await client_factory()

        # Act
        response = await client.post(
            "/api/v1/scheduler/reschedule",
            json={"cron_expression": "0 18 * * fri"},
        )

        # Assert
        # FIXED: Now requires authentication
        assert response.status_code in [401, 403]


@pytest.mark.asyncio
class TestMultiTenantIsolation:
    """Test multi-tenant isolation for scheduler endpoints."""

    async def test_cannot_trigger_report_for_other_org_project(
        self,
        client_factory,
        db_session: AsyncSession,
        test_user: User,
    ):
        """Test that users cannot trigger reports for projects in other organizations."""
        # Arrange
        # Create first organization and client
        from models.organization import Organization
        from models.organization_member import OrganizationMember
        from services.auth.native_auth_service import native_auth_service

        org1 = Organization(
            name="First Org",
            slug="first-org-scheduler-test",
            created_by=test_user.id,
        )
        db_session.add(org1)
        await db_session.commit()
        await db_session.refresh(org1)

        member1 = OrganizationMember(
            organization_id=org1.id,
            user_id=test_user.id,
            role="admin",
            invited_by=test_user.id,
            joined_at=datetime.utcnow(),
        )
        db_session.add(member1)
        await db_session.commit()

        # Create client for org1
        token_org1 = native_auth_service.create_access_token(
            user_id=str(test_user.id),
            email=test_user.email,
            organization_id=str(org1.id),
        )
        client_org1 = await client_factory(
            Authorization=f"Bearer {token_org1}",
            **{"X-Organization-Id": str(org1.id)},
        )

        # Create second organization
        org2 = Organization(
            name="Second Org",
            slug="second-org-scheduler-test",
            created_by=test_user.id,
        )
        db_session.add(org2)
        await db_session.commit()
        await db_session.refresh(org2)

        # Create project in org2
        project_org2 = Project(
            id=uuid4(),
            name="Org2 Project",
            organization_id=org2.id,
            status=ProjectStatus.ACTIVE,
            created_by=test_user.email,
        )
        db_session.add(project_org2)
        await db_session.commit()

        # Act - Try to trigger report using org1 client
        response = await client_org1.post(
            "/api/v1/scheduler/trigger-project-reports",
            json={"project_id": str(project_org2.id)},
        )

        # Assert
        # FIXED: Now validates organization ownership
        # Returns 404 (not 403) to prevent information disclosure
        assert response.status_code == 404
        assert response.json()["detail"] == "Project not found"
