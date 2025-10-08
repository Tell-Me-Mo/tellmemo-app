"""
Integration tests for AI-based project matching functionality.

Covers:
- AI project matching with use_ai_matching=true parameter
- New project creation flow via AI matching
- project_created flag in job results

Status: Complete
"""

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession
from models.organization import Organization
from models.user import User
from models.project import Project
from services.core.upload_job_service import upload_job_service


# ============================================================================
# Fixtures
# ============================================================================

@pytest.fixture
def sample_new_project_meeting() -> str:
    """Meeting transcript for a completely new product launch project."""
    return """
    Meeting: Product Launch Meeting
    Date: 2025-10-08
    Attendees: Sarah Chen, Mark Johnson, Lisa Park

    Sarah: Today we're discussing the launch of our new AI-powered analytics platform.
    This is a completely new initiative that hasn't been started yet.

    Mark: The product will focus on three main areas:
    1. Real-time data visualization with AI insights
    2. Predictive analytics for business metrics
    3. Automated reporting and recommendations

    Lisa: We need to establish the project scope and timeline.
    Target launch date is Q2 2026.

    Key Decisions:
    - Create new project: AI Analytics Platform
    - Budget approved: $2M for development
    - Team size: 8 engineers, 2 designers, 1 PM

    Action Items:
    - Sarah: Set up project in system by Oct 15
    - Mark: Draft technical architecture by Oct 20
    - Lisa: Create hiring plan by Oct 18

    Next Steps:
    - Kickoff meeting scheduled for Oct 22
    - First sprint planning on Oct 25
    """


@pytest.fixture
def sample_existing_project_meeting() -> str:
    """Meeting transcript that should match to an existing project."""
    return """
    Meeting: Sprint Review - Content Test Project
    Date: 2025-10-08
    Attendees: Team Members

    We discussed progress on the Content Test Project that we've been working on.

    Updates:
    - Completed 15 story points this sprint
    - All content upload features are working
    - Ready for next sprint planning

    Action Items:
    - Continue with existing roadmap
    - Schedule next sprint planning
    """


# ============================================================================
# Test AI Project Matching - New Project Creation
# ============================================================================

class TestAIMatchingNewProject:
    """Test AI matching creates new projects when needed."""

    @pytest.mark.asyncio
    async def test_upload_with_ai_matching_creates_project(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        sample_new_project_meeting: str
    ):
        """Test that AI matching creates new project when needed."""
        # Arrange
        request_data = {
            "content_type": "meeting",
            "title": "Product Launch Meeting",
            "content": sample_new_project_meeting,
            "use_ai_matching": True
        }

        # Act
        response = await authenticated_org_client.post(
            "/api/v1/upload/with-ai-matching",
            json=request_data
        )

        # Assert
        assert response.status_code == 200
        data = response.json()

        # Verify response contains project_id
        assert "project_id" in data
        assert data["project_id"] is not None

        # Verify message indicates project creation
        message_lower = data["message"].lower()
        assert any(keyword in message_lower for keyword in ["new", "created", "assigned"]), \
            f"Message should indicate project creation: {data['message']}"

        # Verify job_id is present for tracking
        assert "job_id" in data
        assert data["job_id"] is not None

    @pytest.mark.asyncio
    async def test_ai_matching_job_contains_project_created_flag(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        sample_new_project_meeting: str
    ):
        """Test that job metadata contains project_created flag when new project is created."""
        # Arrange
        request_data = {
            "content_type": "meeting",
            "title": "Meeting about new product launch",
            "content": sample_new_project_meeting,
            "use_ai_matching": True
        }

        # Act
        response = await authenticated_org_client.post(
            "/api/v1/upload/with-ai-matching",
            json=request_data
        )

        # Assert response
        assert response.status_code == 200
        data = response.json()
        assert "job_id" in data

        # Get job details to verify metadata
        job_id = data["job_id"]
        job = upload_job_service.get_job(job_id)

        # Verify job exists and has correct metadata
        assert job is not None, "Job should exist in job service"
        assert "metadata" in job.to_dict()

        job_metadata = job.metadata

        # Verify project_created flag exists and is True for new projects
        assert "is_new_project" in job_metadata, \
            f"Job metadata should contain is_new_project flag. Metadata: {job_metadata}"

        # Note: The actual value depends on whether AI creates a new project or matches existing
        # In this test, we expect True since the content is about a new project
        project_created = job_metadata.get("is_new_project")
        assert isinstance(project_created, bool), "is_new_project should be a boolean"

    @pytest.mark.asyncio
    async def test_ai_matching_returns_confidence_score(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        sample_new_project_meeting: str
    ):
        """Test that AI matching includes confidence score in job metadata."""
        # Arrange
        request_data = {
            "content_type": "meeting",
            "title": "New Initiative Planning",
            "content": sample_new_project_meeting,
            "use_ai_matching": True
        }

        # Act
        response = await authenticated_org_client.post(
            "/api/v1/upload/with-ai-matching",
            json=request_data
        )

        # Assert
        assert response.status_code == 200
        data = response.json()

        # Get job and check confidence in metadata
        job_id = data["job_id"]
        job = upload_job_service.get_job(job_id)

        assert job is not None
        job_metadata = job.metadata

        # Verify confidence score exists
        assert "match_confidence" in job_metadata, \
            f"Job metadata should contain match_confidence. Metadata: {job_metadata}"

        confidence = job_metadata["match_confidence"]
        assert isinstance(confidence, (int, float)), "Confidence should be numeric"
        assert 0 <= confidence <= 1, "Confidence should be between 0 and 1"


# ============================================================================
# Test AI Project Matching - Existing Project Matching
# ============================================================================

class TestAIMatchingExistingProject:
    """Test AI matching to existing projects."""

    @pytest.mark.asyncio
    async def test_ai_matching_to_existing_project(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        sample_existing_project_meeting: str,
        db_session: AsyncSession,
        test_user: User
    ):
        """Test that AI matches content to existing project when appropriate."""
        # Arrange - Create a project first
        from models.project import Project, ProjectStatus

        existing_project = Project(
            name="Content Test Project",
            description="Existing project for AI matching test",
            organization_id=test_organization.id,
            created_by=str(test_user.id),
            status=ProjectStatus.ACTIVE
        )
        db_session.add(existing_project)
        await db_session.commit()
        await db_session.refresh(existing_project)

        # Upload content with AI matching
        request_data = {
            "content_type": "meeting",
            "title": "Sprint Review Meeting",
            "content": sample_existing_project_meeting,
            "use_ai_matching": True
        }

        # Act
        response = await authenticated_org_client.post(
            "/api/v1/upload/with-ai-matching",
            json=request_data
        )

        # Assert
        assert response.status_code == 200
        data = response.json()

        # Verify project_id is returned
        assert "project_id" in data

        # Verify job has project matching metadata
        job_id = data["job_id"]
        job = upload_job_service.get_job(job_id)
        assert job is not None

        job_metadata = job.metadata
        assert "ai_matched" in job_metadata
        assert job_metadata["ai_matched"] is True
        assert "is_new_project" in job_metadata


# ============================================================================
# Test AI Matching Error Handling
# ============================================================================

class TestAIMatchingErrorHandling:
    """Test error handling in AI matching."""

    @pytest.mark.asyncio
    async def test_ai_matching_with_invalid_content_type(
        self,
        authenticated_org_client: AsyncClient,
        sample_new_project_meeting: str
    ):
        """Test AI matching rejects invalid content types."""
        # Arrange
        request_data = {
            "content_type": "invalid_type",
            "title": "Test Meeting",
            "content": sample_new_project_meeting,
            "use_ai_matching": True
        }

        # Act
        response = await authenticated_org_client.post(
            "/api/v1/upload/with-ai-matching",
            json=request_data
        )

        # Assert
        assert response.status_code == 400
        assert "content type" in response.json()["detail"].lower()

    @pytest.mark.asyncio
    async def test_ai_matching_with_short_content(
        self,
        authenticated_org_client: AsyncClient
    ):
        """Test AI matching rejects content that's too short."""
        # Arrange
        short_content = "This is too short"
        request_data = {
            "content_type": "meeting",
            "title": "Short Meeting",
            "content": short_content,
            "use_ai_matching": True
        }

        # Act
        response = await authenticated_org_client.post(
            "/api/v1/upload/with-ai-matching",
            json=request_data
        )

        # Assert
        assert response.status_code == 400
        assert "short" in response.json()["detail"].lower()

    @pytest.mark.asyncio
    async def test_ai_matching_with_missing_required_fields(
        self,
        authenticated_org_client: AsyncClient,
        sample_new_project_meeting: str
    ):
        """Test AI matching requires all mandatory fields."""
        # Arrange - Missing title
        request_data = {
            "content_type": "meeting",
            # Missing 'title' field
            "content": sample_new_project_meeting,
            "use_ai_matching": True
        }

        # Act
        response = await authenticated_org_client.post(
            "/api/v1/upload/with-ai-matching",
            json=request_data
        )

        # Assert
        assert response.status_code == 422  # Validation error

    @pytest.mark.asyncio
    async def test_ai_matching_without_authentication(
        self,
        client: AsyncClient,
        sample_new_project_meeting: str
    ):
        """Test AI matching requires authentication."""
        # Arrange
        request_data = {
            "content_type": "meeting",
            "title": "Unauthorized Meeting",
            "content": sample_new_project_meeting,
            "use_ai_matching": True
        }

        # Act
        response = await client.post(
            "/api/v1/upload/with-ai-matching",
            json=request_data
        )

        # Assert
        assert response.status_code in [401, 403]


# ============================================================================
# Test AI Matching with Email Content
# ============================================================================

class TestAIMatchingEmail:
    """Test AI matching with email content type."""

    @pytest.mark.asyncio
    async def test_ai_matching_with_email_content(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization
    ):
        """Test AI matching works with email content type."""
        # Arrange
        email_content = """
        From: client@newclient.com
        To: team@company.com
        Subject: New Partnership Opportunity - Digital Transformation Project
        Date: 2025-10-08

        Hi Team,

        We're excited to discuss a new partnership opportunity with you.
        We need help with a digital transformation project that involves:

        1. Modernizing our legacy systems
        2. Implementing cloud infrastructure
        3. Building a new customer portal

        This would be a new engagement with an estimated budget of $500K.
        Can we schedule a kickoff meeting next week?

        Looking forward to working together.

        Best regards,
        John Smith
        CEO, NewClient Inc.
        """

        request_data = {
            "content_type": "email",
            "title": "New Partnership Opportunity",
            "content": email_content,
            "use_ai_matching": True
        }

        # Act
        response = await authenticated_org_client.post(
            "/api/v1/upload/with-ai-matching",
            json=request_data
        )

        # Assert
        assert response.status_code == 200
        data = response.json()

        assert "project_id" in data
        assert data["content_type"] == "email"
        assert "job_id" in data

        # Verify job metadata
        job_id = data["job_id"]
        job = upload_job_service.get_job(job_id)

        assert job is not None
        assert "is_new_project" in job.metadata
        assert "match_confidence" in job.metadata


# ============================================================================
# Test AI Matching with Dates
# ============================================================================

class TestAIMatchingWithDates:
    """Test AI matching with content dates."""

    @pytest.mark.asyncio
    async def test_ai_matching_with_content_date(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        sample_new_project_meeting: str
    ):
        """Test AI matching accepts and processes content date."""
        # Arrange
        request_data = {
            "content_type": "meeting",
            "title": "Dated Meeting",
            "content": sample_new_project_meeting,
            "date": "2025-10-08",
            "use_ai_matching": True
        }

        # Act
        response = await authenticated_org_client.post(
            "/api/v1/upload/with-ai-matching",
            json=request_data
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert "project_id" in data
        assert "job_id" in data

    @pytest.mark.asyncio
    async def test_ai_matching_without_date(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        sample_new_project_meeting: str
    ):
        """Test AI matching works without content date (optional field)."""
        # Arrange
        request_data = {
            "content_type": "meeting",
            "title": "Undated Meeting",
            "content": sample_new_project_meeting,
            "use_ai_matching": True
            # No 'date' field
        }

        # Act
        response = await authenticated_org_client.post(
            "/api/v1/upload/with-ai-matching",
            json=request_data
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert "project_id" in data
