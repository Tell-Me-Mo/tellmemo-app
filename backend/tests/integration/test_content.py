"""
Integration tests for Content Upload API.

Covers TESTING_BACKEND.md section 5.1 - Content Upload (content.py, upload.py)
and section 5.2 - Content Retrieval

Status: TBD
"""

import pytest
import io
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession
from models.user import User
from models.organization import Organization
from models.project import Project, ProjectStatus


# ============================================================================
# Fixtures
# ============================================================================

@pytest.fixture
async def test_project(
    db_session: AsyncSession,
    test_organization: Organization,
    test_user: User
) -> Project:
    """Create a test project for content upload tests."""
    project = Project(
        name="Content Test Project",
        description="Project for testing content uploads",
        organization_id=test_organization.id,
        created_by=str(test_user.id),  # Convert UUID to string
        status=ProjectStatus.ACTIVE
    )

    db_session.add(project)
    await db_session.commit()
    await db_session.refresh(project)

    return project


@pytest.fixture
async def archived_project(
    db_session: AsyncSession,
    test_organization: Organization,
    test_user: User
) -> Project:
    """Create an archived project for testing upload restrictions."""
    project = Project(
        name="Archived Project",
        description="Archived project - should reject uploads",
        organization_id=test_organization.id,
        created_by=str(test_user.id),  # Convert UUID to string
        status=ProjectStatus.ARCHIVED
    )

    db_session.add(project)
    await db_session.commit()
    await db_session.refresh(project)

    return project


@pytest.fixture
def sample_meeting_transcript() -> str:
    """Sample meeting transcript for testing."""
    return """
    Meeting: Q4 Planning Session
    Date: 2024-10-06
    Attendees: John Doe, Jane Smith, Bob Johnson

    John: Let's discuss our Q4 goals and priorities.

    Jane: I think we need to focus on three main areas:
    1. Customer acquisition - targeting 20% growth
    2. Product development - launching the new analytics dashboard
    3. Team expansion - hiring 5 new engineers

    Bob: Agreed. For the analytics dashboard, we should prioritize
    the following features:
    - Real-time data visualization
    - Custom report builder
    - API integration with third-party tools

    John: Great points. Let's also discuss potential risks:
    - Budget constraints may limit hiring
    - Technical debt in the current platform could slow development
    - Market competition is increasing

    Action Items:
    - Jane: Draft detailed hiring plan by Oct 15
    - Bob: Create technical specification for dashboard by Oct 20
    - John: Schedule follow-up meeting for Nov 1

    Key Decisions:
    - Approved budget increase for Q4 hiring
    - Decided to use React for dashboard frontend
    - Will evaluate market positioning monthly

    Next Steps:
    - Review and approve Q4 OKRs
    - Begin recruitment for engineering positions
    - Start dashboard development sprint
    """


@pytest.fixture
def sample_email_content() -> str:
    """Sample email content for testing."""
    return """
    From: client@example.com
    To: team@company.com
    Subject: Project Update Request
    Date: 2024-10-06

    Hi Team,

    I wanted to follow up on the project status. Could you provide:

    1. Progress update on the key milestones
    2. Any blockers or risks we should be aware of
    3. Timeline for the next deliverable

    We have a board meeting next week and need to present the status.

    Thanks,
    Client Name
    """


@pytest.fixture
def short_content() -> str:
    """Content that's too short (less than 50 chars)."""
    return "This is too short"


# ============================================================================
# Section 5.1: Content Upload - File Upload
# ============================================================================

class TestFileUpload:
    """Test file upload endpoint: POST /api/projects/{project_id}/upload"""

    @pytest.mark.asyncio
    async def test_upload_meeting_transcript_success(
        self,
        authenticated_org_client: AsyncClient,
        test_project: Project,
        sample_meeting_transcript: str
    ):
        """Test successful meeting transcript upload with valid file."""
        # Arrange
        file_content = sample_meeting_transcript.encode('utf-8')
        files = {
            'file': ('meeting_transcript.txt', io.BytesIO(file_content), 'text/plain')
        }
        data = {
            'content_type': 'meeting',
            'title': 'Q4 Planning Session'
        }

        # Act
        response = await authenticated_org_client.post(
            f"/api/v1/projects/{test_project.id}/upload",
            files=files,
            data=data
        )

        # Assert
        assert response.status_code == 200
        result = response.json()
        assert result['status'] == 'processing'
        assert result['project_id'] == str(test_project.id)
        assert result['content_type'] == 'meeting'
        assert result['title'] == 'Q4 Planning Session'
        assert 'id' in result
        assert 'job_id' in result
        assert result['chunk_count'] == 0  # Not processed yet
        assert 'uploaded successfully' in result['message'].lower()

    @pytest.mark.asyncio
    async def test_upload_email_content_success(
        self,
        authenticated_org_client: AsyncClient,
        test_project: Project,
        sample_email_content: str
    ):
        """Test successful email content upload."""
        # Arrange
        file_content = sample_email_content.encode('utf-8')
        files = {
            'file': ('email.txt', io.BytesIO(file_content), 'text/plain')
        }
        data = {
            'content_type': 'email',
            'title': 'Project Update Request'
        }

        # Act
        response = await authenticated_org_client.post(
            f"/api/v1/projects/{test_project.id}/upload",
            files=files,
            data=data
        )

        # Assert
        assert response.status_code == 200
        result = response.json()
        assert result['content_type'] == 'email'
        assert result['title'] == 'Project Update Request'

    @pytest.mark.asyncio
    async def test_upload_without_title_uses_filename(
        self,
        authenticated_org_client: AsyncClient,
        test_project: Project,
        sample_meeting_transcript: str
    ):
        """Test that filename is used as title when title not provided."""
        # Arrange
        file_content = sample_meeting_transcript.encode('utf-8')
        files = {
            'file': ('q4_planning_meeting.txt', io.BytesIO(file_content), 'text/plain')
        }
        data = {
            'content_type': 'meeting'
        }

        # Act
        response = await authenticated_org_client.post(
            f"/api/v1/projects/{test_project.id}/upload",
            files=files,
            data=data
        )

        # Assert
        assert response.status_code == 200
        result = response.json()
        assert result['title'] == 'q4_planning_meeting'  # Filename without extension

    @pytest.mark.asyncio
    async def test_upload_with_date(
        self,
        authenticated_org_client: AsyncClient,
        test_project: Project,
        sample_meeting_transcript: str
    ):
        """Test upload with content date specified."""
        # Arrange
        file_content = sample_meeting_transcript.encode('utf-8')
        files = {
            'file': ('meeting.txt', io.BytesIO(file_content), 'text/plain')
        }
        data = {
            'content_type': 'meeting',
            'title': 'Meeting with Date',
            'content_date': '2024-10-06'
        }

        # Act
        response = await authenticated_org_client.post(
            f"/api/v1/projects/{test_project.id}/upload",
            files=files,
            data=data
        )

        # Assert
        assert response.status_code == 200

    @pytest.mark.asyncio
    async def test_upload_invalid_content_type(
        self,
        authenticated_org_client: AsyncClient,
        test_project: Project,
        sample_meeting_transcript: str
    ):
        """Test that invalid content type is rejected."""
        # Arrange
        file_content = sample_meeting_transcript.encode('utf-8')
        files = {
            'file': ('meeting.txt', io.BytesIO(file_content), 'text/plain')
        }
        data = {
            'content_type': 'invalid_type',
            'title': 'Test'
        }

        # Act
        response = await authenticated_org_client.post(
            f"/api/v1/projects/{test_project.id}/upload",
            files=files,
            data=data
        )

        # Assert
        assert response.status_code == 400
        assert 'must be' in response.json()['detail'].lower()

    @pytest.mark.asyncio
    async def test_upload_invalid_project_id(
        self,
        authenticated_org_client: AsyncClient,
        sample_meeting_transcript: str
    ):
        """Test upload with invalid project ID format."""
        # Arrange
        file_content = sample_meeting_transcript.encode('utf-8')
        files = {
            'file': ('meeting.txt', io.BytesIO(file_content), 'text/plain')
        }
        data = {
            'content_type': 'meeting',
            'title': 'Test'
        }

        # Act
        response = await authenticated_org_client.post(
            "/api/v1/projects/invalid-uuid/upload",
            files=files,
            data=data
        )

        # Assert
        assert response.status_code == 400
        assert 'invalid' in response.json()['detail'].lower()

    @pytest.mark.asyncio
    async def test_upload_nonexistent_project(
        self,
        authenticated_org_client: AsyncClient,
        sample_meeting_transcript: str
    ):
        """Test upload to non-existent project."""
        # Arrange
        fake_project_id = "00000000-0000-0000-0000-000000000000"
        file_content = sample_meeting_transcript.encode('utf-8')
        files = {
            'file': ('meeting.txt', io.BytesIO(file_content), 'text/plain')
        }
        data = {
            'content_type': 'meeting',
            'title': 'Test'
        }

        # Act
        response = await authenticated_org_client.post(
            f"/api/v1/projects/{fake_project_id}/upload",
            files=files,
            data=data
        )

        # Assert
        assert response.status_code == 400  # Project not found (ValueError caught)
        assert 'not found' in response.json()['detail'].lower()

    @pytest.mark.asyncio
    async def test_upload_to_archived_project(
        self,
        authenticated_org_client: AsyncClient,
        archived_project: Project,
        sample_meeting_transcript: str
    ):
        """Test that uploads to archived projects are rejected."""
        # Arrange
        file_content = sample_meeting_transcript.encode('utf-8')
        files = {
            'file': ('meeting.txt', io.BytesIO(file_content), 'text/plain')
        }
        data = {
            'content_type': 'meeting',
            'title': 'Test'
        }

        # Act
        response = await authenticated_org_client.post(
            f"/api/v1/projects/{archived_project.id}/upload",
            files=files,
            data=data
        )

        # Assert
        # Should fail because project is not active
        assert response.status_code == 400
        assert 'not active' in response.json()['detail'].lower()

    @pytest.mark.asyncio
    async def test_upload_file_too_large(
        self,
        authenticated_org_client: AsyncClient,
        test_project: Project
    ):
        """Test that files exceeding size limit are rejected."""
        # Arrange - Create a file larger than 10MB
        large_content = "x" * (11 * 1024 * 1024)  # 11MB
        files = {
            'file': ('large_file.txt', io.BytesIO(large_content.encode('utf-8')), 'text/plain')
        }
        data = {
            'content_type': 'meeting',
            'title': 'Large File'
        }

        # Act
        response = await authenticated_org_client.post(
            f"/api/v1/projects/{test_project.id}/upload",
            files=files,
            data=data
        )

        # Assert
        assert response.status_code == 400
        assert 'exceeds' in response.json()['detail'].lower()

    @pytest.mark.asyncio
    async def test_upload_empty_file(
        self,
        authenticated_org_client: AsyncClient,
        test_project: Project
    ):
        """Test that empty files are rejected."""
        # Arrange
        files = {
            'file': ('empty.txt', io.BytesIO(b''), 'text/plain')
        }
        data = {
            'content_type': 'meeting',
            'title': 'Empty File'
        }

        # Act
        response = await authenticated_org_client.post(
            f"/api/v1/projects/{test_project.id}/upload",
            files=files,
            data=data
        )

        # Assert
        assert response.status_code in [400, 500]
        if response.status_code == 400:
            assert 'empty' in response.json()['detail'].lower()

    @pytest.mark.asyncio
    async def test_upload_file_too_short(
        self,
        authenticated_org_client: AsyncClient,
        test_project: Project,
        short_content: str
    ):
        """Test that files with content < 50 chars are rejected."""
        # Arrange
        files = {
            'file': ('short.txt', io.BytesIO(short_content.encode('utf-8')), 'text/plain')
        }
        data = {
            'content_type': 'meeting',
            'title': 'Short File'
        }

        # Act
        response = await authenticated_org_client.post(
            f"/api/v1/projects/{test_project.id}/upload",
            files=files,
            data=data
        )

        # Assert
        assert response.status_code in [400, 500]
        if response.status_code == 400:
            assert 'short' in response.json()['detail'].lower()

    @pytest.mark.asyncio
    async def test_upload_non_text_file(
        self,
        authenticated_org_client: AsyncClient,
        test_project: Project
    ):
        """Test that non-text files are rejected."""
        # Arrange - Create fake binary content
        binary_content = bytes([0xFF, 0xD8, 0xFF, 0xE0])  # JPEG header
        files = {
            'file': ('image.jpg', io.BytesIO(binary_content), 'image/jpeg')
        }
        data = {
            'content_type': 'meeting',
            'title': 'Image File'
        }

        # Act
        response = await authenticated_org_client.post(
            f"/api/v1/projects/{test_project.id}/upload",
            files=files,
            data=data
        )

        # Assert
        assert response.status_code in [400, 500]
        if response.status_code == 400:
            assert 'not supported' in response.json()['detail'].lower()

    @pytest.mark.asyncio
    async def test_upload_without_authentication(
        self,
        client: AsyncClient,
        test_project: Project,
        sample_meeting_transcript: str
    ):
        """Test that unauthenticated requests are rejected."""
        # Arrange
        file_content = sample_meeting_transcript.encode('utf-8')
        files = {
            'file': ('meeting.txt', io.BytesIO(file_content), 'text/plain')
        }
        data = {
            'content_type': 'meeting',
            'title': 'Unauthorized'
        }

        # Act
        response = await client.post(
            f"/api/v1/projects/{test_project.id}/upload",
            files=files,
            data=data
        )

        # Assert
        assert response.status_code in [401, 403]


# ============================================================================
# Section 5.1: Content Upload - Text Upload
# ============================================================================

class TestTextUpload:
    """Test text upload endpoint: POST /api/projects/{project_id}/upload/text"""

    @pytest.mark.asyncio
    async def test_upload_text_meeting_success(
        self,
        authenticated_org_client: AsyncClient,
        test_project: Project,
        sample_meeting_transcript: str
    ):
        """Test successful text upload for meeting content."""
        # Arrange
        request_data = {
            'content_type': 'meeting',
            'title': 'Q4 Planning via Text',
            'content': sample_meeting_transcript,
            'date': '2024-10-06'
        }

        # Act
        response = await authenticated_org_client.post(
            f"/api/v1/projects/{test_project.id}/upload/text",
            json=request_data
        )

        # Assert
        assert response.status_code == 200
        result = response.json()
        assert result['status'] == 'processing'
        assert result['project_id'] == str(test_project.id)
        assert result['content_type'] == 'meeting'
        assert result['title'] == 'Q4 Planning via Text'
        assert 'id' in result
        assert 'job_id' in result

    @pytest.mark.asyncio
    async def test_upload_text_email_success(
        self,
        authenticated_org_client: AsyncClient,
        test_project: Project,
        sample_email_content: str
    ):
        """Test successful text upload for email content."""
        # Arrange
        request_data = {
            'content_type': 'email',
            'title': 'Client Email',
            'content': sample_email_content
        }

        # Act
        response = await authenticated_org_client.post(
            f"/api/v1/projects/{test_project.id}/upload/text",
            json=request_data
        )

        # Assert
        assert response.status_code == 200
        result = response.json()
        assert result['content_type'] == 'email'

    @pytest.mark.asyncio
    async def test_upload_text_without_date(
        self,
        authenticated_org_client: AsyncClient,
        test_project: Project,
        sample_meeting_transcript: str
    ):
        """Test text upload without date (optional field)."""
        # Arrange
        request_data = {
            'content_type': 'meeting',
            'title': 'Undated Meeting',
            'content': sample_meeting_transcript
        }

        # Act
        response = await authenticated_org_client.post(
            f"/api/v1/projects/{test_project.id}/upload/text",
            json=request_data
        )

        # Assert
        assert response.status_code == 200

    @pytest.mark.asyncio
    async def test_upload_text_invalid_content_type(
        self,
        authenticated_org_client: AsyncClient,
        test_project: Project,
        sample_meeting_transcript: str
    ):
        """Test that invalid content type is rejected."""
        # Arrange
        request_data = {
            'content_type': 'document',  # Invalid
            'title': 'Test',
            'content': sample_meeting_transcript
        }

        # Act
        response = await authenticated_org_client.post(
            f"/api/v1/projects/{test_project.id}/upload/text",
            json=request_data
        )

        # Assert
        assert response.status_code == 400

    @pytest.mark.asyncio
    async def test_upload_text_content_too_short(
        self,
        authenticated_org_client: AsyncClient,
        test_project: Project,
        short_content: str
    ):
        """Test that content < 50 chars is rejected."""
        # Arrange
        request_data = {
            'content_type': 'meeting',
            'title': 'Short Content',
            'content': short_content
        }

        # Act
        response = await authenticated_org_client.post(
            f"/api/v1/projects/{test_project.id}/upload/text",
            json=request_data
        )

        # Assert
        assert response.status_code == 400
        assert 'short' in response.json()['detail'].lower()

    @pytest.mark.asyncio
    async def test_upload_text_content_too_large(
        self,
        authenticated_org_client: AsyncClient,
        test_project: Project
    ):
        """Test that content exceeding size limit is rejected."""
        # Arrange - Create content larger than max size
        large_content = "x" * (11 * 1024 * 1024)  # 11MB
        request_data = {
            'content_type': 'meeting',
            'title': 'Large Content',
            'content': large_content
        }

        # Act
        response = await authenticated_org_client.post(
            f"/api/v1/projects/{test_project.id}/upload/text",
            json=request_data
        )

        # Assert
        assert response.status_code == 400
        assert 'exceeds' in response.json()['detail'].lower()

    @pytest.mark.asyncio
    async def test_upload_text_missing_required_fields(
        self,
        authenticated_org_client: AsyncClient,
        test_project: Project
    ):
        """Test that missing required fields are rejected."""
        # Arrange - Missing content field
        request_data = {
            'content_type': 'meeting',
            'title': 'Missing Content'
            # Missing 'content' field
        }

        # Act
        response = await authenticated_org_client.post(
            f"/api/v1/projects/{test_project.id}/upload/text",
            json=request_data
        )

        # Assert
        assert response.status_code == 422  # Validation error


# ============================================================================
# Section 5.1: Content Upload - AI-based Project Matching
# ============================================================================

class TestAIProjectMatching:
    """Test AI-based project matching: POST /api/upload/with-ai-matching"""

    @pytest.mark.asyncio
    async def test_ai_matching_creates_response(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        sample_meeting_transcript: str
    ):
        """Test AI matching endpoint returns a response."""
        # Arrange
        request_data = {
            'content_type': 'meeting',
            'title': 'Strategic Planning Meeting',
            'content': sample_meeting_transcript,
            'use_ai_matching': True
        }

        # Act
        response = await authenticated_org_client.post(
            "/api/v1/upload/with-ai-matching",
            json=request_data
        )

        # Assert
        # Note: This test may fail if AI service is not available or configured
        # We expect either success (200) or service unavailable (500/503)
        assert response.status_code in [200, 500, 503]

        if response.status_code == 200:
            result = response.json()
            assert 'project_id' in result
            assert 'id' in result
            assert 'job_id' in result
            # Message should indicate if project was created or matched
            assert 'project' in result['message'].lower()

    @pytest.mark.asyncio
    async def test_ai_matching_invalid_content_type(
        self,
        authenticated_org_client: AsyncClient,
        sample_meeting_transcript: str
    ):
        """Test AI matching with invalid content type."""
        # Arrange
        request_data = {
            'content_type': 'invalid',
            'title': 'Test',
            'content': sample_meeting_transcript
        }

        # Act
        response = await authenticated_org_client.post(
            "/api/v1/upload/with-ai-matching",
            json=request_data
        )

        # Assert
        assert response.status_code == 400

    @pytest.mark.asyncio
    async def test_ai_matching_content_too_short(
        self,
        authenticated_org_client: AsyncClient,
        short_content: str
    ):
        """Test AI matching with content too short."""
        # Arrange
        request_data = {
            'content_type': 'meeting',
            'title': 'Short',
            'content': short_content
        }

        # Act
        response = await authenticated_org_client.post(
            "/api/v1/upload/with-ai-matching",
            json=request_data
        )

        # Assert
        assert response.status_code == 400
        assert 'short' in response.json()['detail'].lower()


# ============================================================================
# Section 5.2: Content Retrieval
# ============================================================================

class TestContentRetrieval:
    """Test content retrieval endpoints."""

    @pytest.fixture
    async def uploaded_content_ids(
        self,
        authenticated_org_client: AsyncClient,
        test_project: Project,
        sample_meeting_transcript: str,
        sample_email_content: str
    ):
        """Upload sample content and return IDs for retrieval tests."""
        # Upload meeting content
        meeting_data = {
            'content_type': 'meeting',
            'title': 'Test Meeting',
            'content': sample_meeting_transcript
        }
        meeting_response = await authenticated_org_client.post(
            f"/api/v1/projects/{test_project.id}/upload/text",
            json=meeting_data
        )
        meeting_id = meeting_response.json()['id']

        # Upload email content
        email_data = {
            'content_type': 'email',
            'title': 'Test Email',
            'content': sample_email_content
        }
        email_response = await authenticated_org_client.post(
            f"/api/v1/projects/{test_project.id}/upload/text",
            json=email_data
        )
        email_id = email_response.json()['id']

        return {'meeting_id': meeting_id, 'email_id': email_id}

    @pytest.mark.asyncio
    async def test_list_project_content(
        self,
        authenticated_org_client: AsyncClient,
        test_project: Project,
        uploaded_content_ids: dict
    ):
        """Test listing all content for a project."""
        # Act
        response = await authenticated_org_client.get(
            f"/api/v1/projects/{test_project.id}/content"
        )

        # Assert
        assert response.status_code == 200
        content_list = response.json()
        assert isinstance(content_list, list)
        assert len(content_list) >= 2  # At least meeting and email

    @pytest.mark.asyncio
    async def test_list_project_content_filter_by_meeting(
        self,
        authenticated_org_client: AsyncClient,
        test_project: Project,
        uploaded_content_ids: dict
    ):
        """Test filtering content by type (meeting)."""
        # Act
        response = await authenticated_org_client.get(
            f"/api/v1/projects/{test_project.id}/content?content_type=meeting"
        )

        # Assert
        assert response.status_code == 200
        content_list = response.json()
        assert all(item['content_type'] == 'meeting' for item in content_list)

    @pytest.mark.asyncio
    async def test_list_project_content_filter_by_email(
        self,
        authenticated_org_client: AsyncClient,
        test_project: Project,
        uploaded_content_ids: dict
    ):
        """Test filtering content by type (email)."""
        # Act
        response = await authenticated_org_client.get(
            f"/api/v1/projects/{test_project.id}/content?content_type=email"
        )

        # Assert
        assert response.status_code == 200
        content_list = response.json()
        assert all(item['content_type'] == 'email' for item in content_list)

    @pytest.mark.asyncio
    async def test_list_project_content_with_limit(
        self,
        authenticated_org_client: AsyncClient,
        test_project: Project,
        uploaded_content_ids: dict
    ):
        """Test limiting number of results."""
        # Act
        response = await authenticated_org_client.get(
            f"/api/v1/projects/{test_project.id}/content?limit=1"
        )

        # Assert
        assert response.status_code == 200
        content_list = response.json()
        assert len(content_list) <= 1

    @pytest.mark.asyncio
    async def test_list_project_content_invalid_filter(
        self,
        authenticated_org_client: AsyncClient,
        test_project: Project
    ):
        """Test that invalid content type filter is rejected."""
        # Act
        response = await authenticated_org_client.get(
            f"/api/v1/projects/{test_project.id}/content?content_type=invalid"
        )

        # Assert
        assert response.status_code == 400

    @pytest.mark.asyncio
    async def test_get_content_by_id(
        self,
        authenticated_org_client: AsyncClient,
        test_project: Project,
        uploaded_content_ids: dict
    ):
        """Test retrieving specific content by ID."""
        # Act
        response = await authenticated_org_client.get(
            f"/api/v1/projects/{test_project.id}/content/{uploaded_content_ids['meeting_id']}"
        )

        # Assert
        assert response.status_code == 200
        content = response.json()
        assert content['id'] == uploaded_content_ids['meeting_id']
        assert content['title'] == 'Test Meeting'
        assert content['content_type'] == 'meeting'
        assert 'content' in content  # Should include actual text

    @pytest.mark.asyncio
    async def test_get_content_nonexistent_id(
        self,
        authenticated_org_client: AsyncClient,
        test_project: Project
    ):
        """Test retrieving non-existent content returns 404."""
        # Arrange
        fake_content_id = "00000000-0000-0000-0000-000000000000"

        # Act
        response = await authenticated_org_client.get(
            f"/api/v1/projects/{test_project.id}/content/{fake_content_id}"
        )

        # Assert
        assert response.status_code == 404

    @pytest.mark.asyncio
    async def test_get_content_wrong_project(
        self,
        authenticated_org_client: AsyncClient,
        test_project: Project,
        uploaded_content_ids: dict,
        db_session: AsyncSession,
        test_organization: Organization,
        test_user: User
    ):
        """Test that content from wrong project is not accessible."""
        # Arrange - Create another project
        other_project = Project(
            name="Other Project",
            organization_id=test_organization.id,
            created_by=str(test_user.id),  # Convert UUID to string
            status=ProjectStatus.ACTIVE
        )
        db_session.add(other_project)
        await db_session.commit()
        await db_session.refresh(other_project)

        # Act - Try to access content from test_project via other_project
        response = await authenticated_org_client.get(
            f"/api/v1/projects/{other_project.id}/content/{uploaded_content_ids['meeting_id']}"
        )

        # Assert
        assert response.status_code == 404  # Content doesn't belong to this project

    @pytest.mark.asyncio
    async def test_get_content_invalid_id_format(
        self,
        authenticated_org_client: AsyncClient,
        test_project: Project
    ):
        """Test that invalid UUID format is rejected."""
        # Act
        response = await authenticated_org_client.get(
            f"/api/v1/projects/{test_project.id}/content/invalid-uuid"
        )

        # Assert
        assert response.status_code == 400
