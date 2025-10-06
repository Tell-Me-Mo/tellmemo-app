"""
Integration tests for transcription.py endpoints.

Tests cover:
- POST /api/transcribe - Audio file transcription
- GET /api/languages - List supported languages
- GET /api/health - Service health check
- File validation (size, empty files)
- Multi-tenant isolation
- Authentication requirements
- Background job creation
- Whisper and Salad service integration

Following testing strategy from TESTING_BACKEND.md section 11.2.
"""

import pytest
import os
import tempfile
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession
from datetime import datetime
from uuid import uuid4
from pathlib import Path
from unittest.mock import Mock, AsyncMock, patch, MagicMock
import io

from models.user import User
from models.organization import Organization
from models.project import Project, ProjectStatus
from models.integration import Integration, IntegrationType, IntegrationStatus
from services.core.upload_job_service import upload_job_service, JobStatus


@pytest.fixture
async def test_project(
    db_session: AsyncSession,
    test_organization: Organization
) -> Project:
    """Create a test project for transcription tests."""
    project = Project(
        id=uuid4(),
        name="Test Project",
        description="Test project for transcription",
        organization_id=test_organization.id,
        status=ProjectStatus.ACTIVE,
        created_at=datetime.utcnow(),
        updated_at=datetime.utcnow()
    )
    db_session.add(project)
    await db_session.commit()
    await db_session.refresh(project)
    return project


class ReusableBytesIO(io.BytesIO):
    """A BytesIO that resets to the beginning when read."""
    def read(self, *args, **kwargs):
        self.seek(0)  # Always start from the beginning
        return super().read(*args, **kwargs)


@pytest.fixture
def mock_audio_file():
    """Create a mock audio file factory for testing."""
    def _create_audio_file():
        # Create a small valid WAV file (minimal header + some data)
        content = b'RIFF' + b'\x00' * 4 + b'WAVE' + b'fmt ' + b'\x00' * 16 + b'data' + b'\x00' * 100
        buffer = ReusableBytesIO(content)
        buffer.seek(0)  # Ensure file pointer is at the beginning
        buffer.name = "test_audio.wav"  # Add a name attribute
        return buffer
    return _create_audio_file


@pytest.fixture(autouse=True)
def mock_whisper_service():
    """Mock WhisperTranscriptionService."""
    with patch('services.transcription.whisper_service.WhisperTranscriptionService') as mock_class:
        service = Mock()
        service.is_model_loaded = Mock(return_value=True)
        service.transcribe_audio_file = AsyncMock(return_value={
            "text": "This is a test transcription.",
            "segments": [
                {
                    "text": "This is a test transcription.",
                    "start": 0.0,
                    "end": 2.5
                }
            ],
            "language": "en"
        })
        mock_class.return_value = service

        # Also mock the get_whisper_service function
        with patch('routers.transcription.get_whisper_service', return_value=service):
            # Mock ContentService.trigger_async_processing to prevent background task hanging
            with patch('routers.transcription.ContentService.trigger_async_processing', new=AsyncMock()):
                yield service


@pytest.fixture
def mock_salad_service():
    """Mock SaladTranscriptionService."""
    with patch('routers.transcription.get_salad_service') as mock_func:
        service = Mock()
        service.transcribe_audio_file = AsyncMock(return_value={
            "text": "This is a Salad transcription.",
            "segments": [
                {
                    "text": "This is a Salad transcription.",
                    "start": 0.0,
                    "end": 2.5
                }
            ],
            "language": "en"
        })
        mock_func.return_value = service
        yield service


@pytest.mark.asyncio
class TestTranscribeAudio:
    """Test POST /api/transcribe endpoint."""

    async def test_transcribe_audio_success_whisper(
        self,
        authenticated_org_client: AsyncClient,
        test_project: Project,
        mock_audio_file,
        mock_whisper_service
    ):
        """Test successful audio transcription using Whisper service."""
        # Arrange
        files = {"audio_file": ("test_audio.wav", mock_audio_file(), "audio/wav")}
        data = {
            "project_id": str(test_project.id),
            "meeting_title": "Test Meeting",
            "language": "en"
        }

        # Act
        response = await authenticated_org_client.post(
            "/api/transcribe",
            files=files,
            data=data
        )

        # Assert
        if response.status_code != 200:
            print(f"\n==== DEBUG INFO ====")
            print(f"Response status: {response.status_code}")
            print(f"Response body: {response.text}")
            print(f"===================\n")
        assert response.status_code == 200
        result = response.json()
        assert "job_id" in result
        assert result["status"] == "processing"
        assert result["message"] == "Audio file uploaded successfully. Transcription in progress."
        assert result["metadata"]["project_id"] == str(test_project.id)
        assert result["metadata"]["meeting_title"] == "Test Meeting"
        assert result["metadata"]["language"] == "en"
        assert result["metadata"]["filename"] == "test_audio.wav"
        assert result["metadata"]["file_size"] > 0

    async def test_transcribe_audio_with_auto_language(
        self,
        authenticated_org_client: AsyncClient,
        test_project: Project,
        mock_audio_file,
        mock_whisper_service
    ):
        """Test transcription with automatic language detection."""
        # Arrange
        files = {"audio_file": ("test_audio.mp3", mock_audio_file(), "audio/mpeg")}
        data = {
            "project_id": str(test_project.id),
            "meeting_title": "Auto Language Test",
            "language": "auto"
        }

        # Act
        response = await authenticated_org_client.post(
            "/api/transcribe",
            files=files,
            data=data
        )

        # Assert
        assert response.status_code == 200
        result = response.json()
        assert result["metadata"]["language"] == "auto"

    async def test_transcribe_audio_without_meeting_title(
        self,
        authenticated_org_client: AsyncClient,
        test_project: Project,
        mock_audio_file,
        mock_whisper_service
    ):
        """Test transcription without meeting title (should auto-generate)."""
        # Arrange
        files = {"audio_file": ("recording.wav", mock_audio_file(), "audio/wav")}
        data = {
            "project_id": str(test_project.id),
            "language": "en"
        }

        # Act
        response = await authenticated_org_client.post(
            "/api/transcribe",
            files=files,
            data=data
        )

        # Assert
        assert response.status_code == 200
        result = response.json()
        assert result["metadata"]["meeting_title"] is None

    async def test_transcribe_audio_with_salad_integration(
        self,
        authenticated_org_client: AsyncClient,
        db_session: AsyncSession,
        test_organization: Organization,
        test_project: Project,
        mock_audio_file,
        mock_salad_service
    ):
        """Test transcription using Salad service when integration is configured."""
        # Arrange - connect Salad transcription integration
        integration = Integration(
            id=uuid4(),
            organization_id=test_organization.id,
            type=IntegrationType.TRANSCRIPTION,
            status=IntegrationStatus.CONNECTED,
            api_key="test_salad_api_key",
            custom_settings={
                "service_type": "salad",
                "organization_name": "test-org"
            },
            connected_at=datetime.utcnow()
        )
        db_session.add(integration)
        await db_session.commit()

        files = {"audio_file": ("test_audio.wav", mock_audio_file(), "audio/wav")}
        data = {
            "project_id": str(test_project.id),
            "meeting_title": "Salad Test",
            "language": "en"
        }

        # Act
        response = await authenticated_org_client.post(
            "/api/transcribe",
            files=files,
            data=data
        )

        # Assert
        assert response.status_code == 200
        result = response.json()
        assert "job_id" in result
        assert result["status"] == "processing"

    async def test_transcribe_audio_file_too_large(
        self,
        authenticated_org_client: AsyncClient,
        test_project: Project,
        mock_whisper_service
    ):
        """Test that files larger than 100MB are rejected."""
        # Arrange - create a file that reports as > 100MB
        large_file = io.BytesIO(b'x' * 1000)  # Small content but we'll mock the size
        files = {"audio_file": ("large_audio.wav", large_file, "audio/wav")}
        data = {
            "project_id": str(test_project.id),
            "language": "en"
        }

        # Mock os.path.getsize to return > 100MB
        with patch('os.path.getsize', return_value=101 * 1024 * 1024):
            # Act
            response = await authenticated_org_client.post(
                "/api/transcribe",
                files=files,
                data=data
            )

        # Assert
        assert response.status_code == 413
        assert "too large" in response.json()["detail"].lower()

    async def test_transcribe_audio_empty_file(
        self,
        authenticated_org_client: AsyncClient,
        test_project: Project,
        mock_whisper_service
    ):
        """Test that empty audio files are rejected."""
        # Arrange
        empty_file = io.BytesIO(b'')
        # Note: empty_file is created in the test itself, not using the fixture
        files = {"audio_file": ("empty.wav", empty_file, "audio/wav")}
        data = {
            "project_id": str(test_project.id),
            "language": "en"
        }

        # Act
        response = await authenticated_org_client.post(
            "/api/transcribe",
            files=files,
            data=data
        )

        # Assert
        assert response.status_code == 400
        assert "empty" in response.json()["detail"].lower()

    async def test_transcribe_audio_requires_authentication(
        self,
        client_factory,
        test_project: Project,
        mock_audio_file
    ):
        """Test that transcription requires authentication."""
        # Arrange
        client = await client_factory()
        files = {"audio_file": ("test_audio.wav", mock_audio_file(), "audio/wav")}
        data = {
            "project_id": str(test_project.id),
            "language": "en"
        }

        # Act
        response = await client.post(
            "/api/transcribe",
            files=files,
            data=data
        )

        # Assert
        assert response.status_code in [401, 403]

    async def test_transcribe_audio_multi_tenant_isolation(
        self,
        client_factory,
        db_session: AsyncSession,
        test_organization: Organization,
        mock_audio_file,
        mock_whisper_service
    ):
        """Test that users cannot transcribe to projects in other organizations."""
        # Arrange - create second organization with project
        from models.user import User
        from models.organization_member import OrganizationMember
        from services.auth.native_auth_service import native_auth_service

        user2 = User(
            id=uuid4(),
            email="user2@example.com",
            password_hash="hashed",
            name="User 2",
            auth_provider="native",
            is_active=True
        )
        db_session.add(user2)
        await db_session.commit()

        org2 = Organization(
            id=uuid4(),
            name="Org 2",
            slug="org-2",
            created_by=user2.id
        )
        db_session.add(org2)
        await db_session.commit()

        member2 = OrganizationMember(
            organization_id=org2.id,
            user_id=user2.id,
            role="admin",
            invited_by=user2.id,
            joined_at=datetime.utcnow()
        )
        db_session.add(member2)
        await db_session.commit()

        project2 = Project(
            id=uuid4(),
            name="Org 2 Project",
            organization_id=org2.id,
            status=ProjectStatus.ACTIVE,
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow()
        )
        db_session.add(project2)
        await db_session.commit()

        # Create client for user2 with org2 context
        token2 = native_auth_service.create_access_token(
            user_id=str(user2.id),
            email=user2.email,
            organization_id=str(org2.id)
        )
        client2 = await client_factory(
            Authorization=f"Bearer {token2}",
            **{"X-Organization-Id": str(org2.id)}
        )

        # Try to transcribe to org1's project (should fail)
        from models.project import Project as ProjectModel
        from sqlalchemy import select

        # Get first org's project
        result = await db_session.execute(
            select(ProjectModel).where(ProjectModel.organization_id == test_organization.id).limit(1)
        )
        org1_project = result.scalar_one_or_none()

        if org1_project:
            files = {"audio_file": ("test_audio.wav", mock_audio_file(), "audio/wav")}
            data = {
                "project_id": str(org1_project.id),
                "language": "en"
            }

            # Act - user2 tries to transcribe to org1's project
            response = await client2.post(
                "/api/transcribe",
                files=files,
                data=data
            )

            # Assert - should return 404 (not revealing project existence to prevent information disclosure)
            assert response.status_code == 404
            assert response.json()["detail"] == "Project not found"

    async def test_transcribe_audio_with_ai_matching(
        self,
        authenticated_org_client: AsyncClient,
        mock_audio_file,
        mock_whisper_service
    ):
        """Test transcription with AI project matching."""
        # Arrange
        files = {"audio_file": ("test_audio.wav", mock_audio_file(), "audio/wav")}
        data = {
            "project_id": "auto",
            "meeting_title": "AI Matching Test",
            "language": "en",
            "use_ai_matching": "true"
        }

        # Mock the project matcher service
        with patch('routers.transcription.project_matcher_service.match_transcript_to_project') as mock_matcher:
            mock_matcher.return_value = {
                "project_id": uuid4(),
                "project_name": "Matched Project",
                "is_new": False,
                "confidence": 0.95
            }

            # Act
            response = await authenticated_org_client.post(
                "/api/transcribe",
                files=files,
                data=data
            )

        # Assert
        assert response.status_code == 200
        result = response.json()
        assert "job_id" in result

    async def test_transcribe_audio_creates_background_job(
        self,
        authenticated_org_client: AsyncClient,
        test_project: Project,
        mock_audio_file,
        mock_whisper_service
    ):
        """Test that transcription creates a background job for tracking."""
        # Arrange
        files = {"audio_file": ("test_audio.wav", mock_audio_file(), "audio/wav")}
        data = {
            "project_id": str(test_project.id),
            "meeting_title": "Job Test",
            "language": "en"
        }

        # Act
        response = await authenticated_org_client.post(
            "/api/transcribe",
            files=files,
            data=data
        )

        # Assert
        assert response.status_code == 200
        result = response.json()
        job_id = result["job_id"]

        # Verify job was created
        job = upload_job_service.get_job(job_id)
        assert job is not None
        assert job["project_id"] == str(test_project.id)
        assert job["job_type"] == "transcription"
        assert job["filename"] == "test_audio.wav"

    async def test_transcribe_audio_missing_project_id(
        self,
        authenticated_org_client: AsyncClient,
        mock_audio_file,
        mock_whisper_service
    ):
        """Test that project_id is required."""
        # Arrange
        files = {"audio_file": ("test_audio.wav", mock_audio_file(), "audio/wav")}
        data = {
            "language": "en"
        }

        # Act
        response = await authenticated_org_client.post(
            "/api/transcribe",
            files=files,
            data=data
        )

        # Assert
        assert response.status_code == 422  # Validation error

    async def test_transcribe_audio_missing_file(
        self,
        authenticated_org_client: AsyncClient,
        test_project: Project
    ):
        """Test that audio_file is required."""
        # Arrange
        data = {
            "project_id": str(test_project.id),
            "language": "en"
        }

        # Act
        response = await authenticated_org_client.post(
            "/api/transcribe",
            data=data
        )

        # Assert
        assert response.status_code == 422  # Validation error

    async def test_transcribe_audio_invalid_project_id_format(
        self,
        authenticated_org_client: AsyncClient,
        mock_audio_file,
        mock_whisper_service
    ):
        """Test that invalid project_id UUID format is rejected."""
        # Arrange
        files = {"audio_file": ("test_audio.wav", mock_audio_file(), "audio/wav")}
        data = {
            "project_id": "not-a-valid-uuid",
            "language": "en"
        }

        # Act
        response = await authenticated_org_client.post(
            "/api/transcribe",
            files=files,
            data=data
        )

        # Assert
        assert response.status_code == 400
        assert "Invalid project_id format" in response.json()["detail"]

    async def test_transcribe_audio_nonexistent_project(
        self,
        authenticated_org_client: AsyncClient,
        mock_audio_file,
        mock_whisper_service
    ):
        """Test that transcription to non-existent project returns 404."""
        # Arrange - use a valid UUID that doesn't exist
        nonexistent_uuid = str(uuid4())
        files = {"audio_file": ("test_audio.wav", mock_audio_file(), "audio/wav")}
        data = {
            "project_id": nonexistent_uuid,
            "language": "en"
        }

        # Act
        response = await authenticated_org_client.post(
            "/api/transcribe",
            files=files,
            data=data
        )

        # Assert
        assert response.status_code == 404
        assert response.json()["detail"] == "Project not found"


@pytest.mark.asyncio
class TestGetSupportedLanguages:
    """Test GET /api/languages endpoint."""

    async def test_get_languages_returns_list(
        self,
        client: AsyncClient
    ):
        """Test that supported languages endpoint returns a list."""
        # Act
        response = await client.get("/api/languages")

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert "languages" in data
        assert "default" in data
        assert isinstance(data["languages"], list)
        assert len(data["languages"]) > 0
        assert data["default"] == "en"

    async def test_get_languages_includes_common_languages(
        self,
        client: AsyncClient
    ):
        """Test that common languages are included."""
        # Act
        response = await client.get("/api/languages")

        # Assert
        assert response.status_code == 200
        data = response.json()
        languages = data["languages"]

        # Verify common languages are present
        assert "en" in languages  # English
        assert "es" in languages  # Spanish
        assert "fr" in languages  # French
        assert "de" in languages  # German
        assert "zh" in languages  # Chinese
        assert "ja" in languages  # Japanese

    async def test_get_languages_no_auth_required(
        self,
        client: AsyncClient
    ):
        """Test that languages endpoint doesn't require authentication."""
        # This is intentional - language list is public information
        # Act
        response = await client.get("/api/languages")

        # Assert
        assert response.status_code == 200


@pytest.mark.asyncio
class TestTranscriptionHealth:
    """Test GET /api/health endpoint."""

    async def test_health_check_when_healthy(
        self,
        client: AsyncClient,
        mock_whisper_service
    ):
        """Test health check when service is healthy."""
        # Arrange
        mock_whisper_service.is_model_loaded.return_value = True

        # Act
        response = await client.get("/api/health")

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "healthy"
        assert data["model_loaded"] is True
        assert data["service"] == "transcription"

    async def test_health_check_when_not_ready(
        self,
        client: AsyncClient
    ):
        """Test health check when model is not loaded."""
        # Arrange - mock Whisper service with model not loaded
        with patch('routers.transcription.get_whisper_service') as mock:
            service = Mock()
            service.is_model_loaded = Mock(return_value=False)
            mock.return_value = service

            # Act
            response = await client.get("/api/health")

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "not_ready"
        assert data["model_loaded"] is False

    async def test_health_check_when_service_fails(
        self,
        client: AsyncClient
    ):
        """Test health check when service throws exception."""
        # Arrange - mock Whisper service that throws exception
        with patch('routers.transcription.get_whisper_service') as mock:
            mock.side_effect = Exception("Service initialization failed")

            # Act
            response = await client.get("/api/health")

        # Assert
        assert response.status_code == 503
        data = response.json()
        assert data["status"] == "unhealthy"
        assert "error" in data

    async def test_health_check_no_auth_required(
        self,
        client: AsyncClient,
        mock_whisper_service
    ):
        """Test that health endpoint doesn't require authentication."""
        # This is intentional - health check should be public
        # Act
        response = await client.get("/api/health")

        # Assert
        assert response.status_code in [200, 503]  # Either healthy or unhealthy, but not auth error


@pytest.mark.asyncio
class TestTranscriptionBackgroundProcessing:
    """Test background transcription processing logic."""

    async def test_background_processing_updates_job_progress(
        self,
        authenticated_org_client: AsyncClient,
        test_project: Project,
        mock_audio_file,
        mock_whisper_service
    ):
        """Test that background task updates job progress."""
        # Arrange
        files = {"audio_file": ("test_audio.wav", mock_audio_file(), "audio/wav")}
        data = {
            "project_id": str(test_project.id),
            "meeting_title": "Progress Test",
            "language": "en"
        }

        # Act
        response = await authenticated_org_client.post(
            "/api/transcribe",
            files=files,
            data=data
        )

        # Assert
        assert response.status_code == 200
        result = response.json()
        job_id = result["job_id"]

        # Wait a bit for background task to start
        import asyncio
        await asyncio.sleep(0.1)

        # Check job status was updated
        job = upload_job_service.get_job(job_id)
        assert job is not None
        # Job should have been updated from initial state
        assert job["status"] in ["processing", "completed", "failed"]
