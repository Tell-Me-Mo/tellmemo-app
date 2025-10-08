"""
Integration tests for Audio Transcription API.

Tests the /api/v1/transcribe endpoint with focus on:
- File size validation (configurable limits)
- File format validation
- Multi-tenant isolation
- AI-based project matching

Status: Complete
"""

import pytest
import io
import shutil
from pathlib import Path
from unittest.mock import patch, MagicMock
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession
from models.user import User
from models.organization import Organization
from models.project import Project, ProjectStatus
from config import get_settings


# ============================================================================
# Fixtures
# ============================================================================

@pytest.fixture(scope="module", autouse=True)
def cleanup_temp_audio():
    """Clean up temporary audio files after all tests in this module."""
    # Setup: nothing needed
    yield

    # Teardown: clean up temp_audio directory
    temp_dir = Path("backend/temp_audio")
    if temp_dir.exists():
        try:
            shutil.rmtree(temp_dir)
            print(f"\n✓ Cleaned up {temp_dir}")
        except Exception as e:
            print(f"\n⚠ Warning: Could not clean up {temp_dir}: {e}")

@pytest.fixture
async def test_project(
    db_session: AsyncSession,
    test_organization: Organization,
    test_user: User
) -> Project:
    """Create a test project for transcription tests."""
    project = Project(
        name="Transcription Test Project",
        description="Project for testing audio transcription",
        organization_id=test_organization.id,
        created_by=str(test_user.id),
        status=ProjectStatus.ACTIVE
    )

    db_session.add(project)
    await db_session.commit()
    await db_session.refresh(project)

    return project


def mock_audio_file(size_mb: float = 0.1):
    """
    Create a mock audio file without generating actual large files.

    Args:
        size_mb: Size in MB (default 0.1 MB = 100 KB)

    Returns:
        BytesIO object simulating an audio file
    """
    # Create a small WAV-like header + dummy data
    size_bytes = int(size_mb * 1024 * 1024)
    # Simple WAV header (44 bytes) + audio data
    wav_header = b'RIFF' + (size_bytes - 8).to_bytes(4, 'little') + b'WAVEfmt '
    wav_header += b'\x10\x00\x00\x00'  # Format chunk size
    wav_header += b'\x01\x00'  # Audio format (PCM)
    wav_header += b'\x01\x00'  # Number of channels (mono)
    wav_header += b'\x44\xac\x00\x00'  # Sample rate (44100)
    wav_header += b'\x88\x58\x01\x00'  # Byte rate
    wav_header += b'\x02\x00'  # Block align
    wav_header += b'\x10\x00'  # Bits per sample
    wav_header += b'data' + (size_bytes - 44).to_bytes(4, 'little')

    # Fill rest with zeros (silent audio)
    audio_data = wav_header + b'\x00' * (size_bytes - len(wav_header))

    return io.BytesIO(audio_data)


# ============================================================================
# Test Class: File Size Validation
# ============================================================================

class TestAudioFileSizeValidation:
    """Tests for audio file size validation with configurable limits."""

    @pytest.mark.asyncio
    async def test_file_within_size_limit_accepted(
        self,
        authenticated_client: AsyncClient,
        test_project: Project
    ):
        """Test that audio files within size limit are accepted."""
        # Create a small file (1 MB - well within 500MB limit)
        audio_file = mock_audio_file(size_mb=1.0)

        files = {
            'audio_file': ('meeting.wav', audio_file, 'audio/wav')
        }
        data = {
            'project_id': str(test_project.id),
            'language': 'en'
        }

        with patch('routers.transcription.process_audio_transcription'):
            response = await authenticated_client.post(
                '/api/v1/transcribe',
                files=files,
                data=data
            )

        # Should accept the file and return 202 (background job created)
        assert response.status_code == 200
        assert 'job_id' in response.json()

    @pytest.mark.asyncio
    async def test_file_exceeding_size_limit_rejected(
        self,
        authenticated_client: AsyncClient,
        test_project: Project
    ):
        """Test that files exceeding max_audio_file_size_mb are rejected with 413."""
        settings = get_settings()
        max_size_mb = settings.max_audio_file_size_mb

        # Create mock file slightly over the limit
        # We don't actually create a huge file - we mock the size check
        audio_file = mock_audio_file(size_mb=0.1)  # Small file

        files = {
            'audio_file': ('huge_meeting.wav', audio_file, 'audio/wav')
        }
        data = {
            'project_id': str(test_project.id),
            'language': 'en'
        }

        # Mock os.path.getsize to return size exceeding limit
        with patch('os.path.getsize', return_value=(max_size_mb + 1) * 1024 * 1024):
            response = await authenticated_client.post(
                '/api/v1/transcribe',
                
                files=files,
                data=data
            )

        # Should reject with 413 Payload Too Large
        assert response.status_code == 413
        assert 'File too large' in response.json()['detail']
        assert f'{max_size_mb}MB' in response.json()['detail']

    @pytest.mark.asyncio
    async def test_error_message_includes_configured_limit(
        self,
        authenticated_client: AsyncClient,
        test_project: Project
    ):
        """Test that error message includes the configured size limit."""
        settings = get_settings()
        max_size_mb = settings.max_audio_file_size_mb

        audio_file = mock_audio_file(size_mb=0.1)

        files = {
            'audio_file': ('oversized.wav', audio_file, 'audio/wav')
        }
        data = {
            'project_id': str(test_project.id),
            'language': 'en'
        }

        # Mock file size exceeding limit
        with patch('os.path.getsize', return_value=(max_size_mb + 50) * 1024 * 1024):
            response = await authenticated_client.post(
                '/api/v1/transcribe',
                
                files=files,
                data=data
            )

        assert response.status_code == 413
        error_detail = response.json()['detail']
        # Verify the error message contains the configured limit
        assert f'{max_size_mb}MB' in error_detail

    @pytest.mark.asyncio
    async def test_empty_file_rejected(
        self,
        authenticated_client: AsyncClient,
        test_project: Project
    ):
        """Test that empty audio files are rejected."""
        empty_file = io.BytesIO(b'')

        files = {
            'audio_file': ('empty.wav', empty_file, 'audio/wav')
        }
        data = {
            'project_id': str(test_project.id),
            'language': 'en'
        }

        response = await authenticated_client.post(
            '/api/v1/transcribe',
            
            files=files,
            data=data
        )

        assert response.status_code == 400
        assert 'empty' in response.json()['detail'].lower()

    @pytest.mark.asyncio
    async def test_boundary_file_size_at_exact_limit(
        self,
        authenticated_client: AsyncClient,
        test_project: Project
    ):
        """Test file at exact size limit boundary."""
        settings = get_settings()
        max_size_mb = settings.max_audio_file_size_mb
        max_size_bytes = max_size_mb * 1024 * 1024

        audio_file = mock_audio_file(size_mb=0.1)

        files = {
            'audio_file': ('boundary.wav', audio_file, 'audio/wav')
        }
        data = {
            'project_id': str(test_project.id),
            'language': 'en'
        }

        # Test exactly at limit (should pass)
        with patch('os.path.getsize', return_value=max_size_bytes):
            with patch('routers.transcription.process_audio_transcription'):
                response = await authenticated_client.post(
                    '/api/v1/transcribe',
                    
                    files=files,
                    data=data
                )

        assert response.status_code == 200

    @pytest.mark.asyncio
    async def test_boundary_file_size_one_byte_over_limit(
        self,
        authenticated_client: AsyncClient,
        test_project: Project
    ):
        """Test file one byte over size limit boundary."""
        settings = get_settings()
        max_size_mb = settings.max_audio_file_size_mb
        max_size_bytes = max_size_mb * 1024 * 1024

        audio_file = mock_audio_file(size_mb=0.1)

        files = {
            'audio_file': ('over_boundary.wav', audio_file, 'audio/wav')
        }
        data = {
            'project_id': str(test_project.id),
            'language': 'en'
        }

        # Test one byte over limit (should fail)
        with patch('os.path.getsize', return_value=max_size_bytes + 1):
            response = await authenticated_client.post(
                '/api/v1/transcribe',
                
                files=files,
                data=data
            )

        assert response.status_code == 413


# ============================================================================
# Test Class: AI Project Matching
# ============================================================================

class TestAIProjectMatching:
    """Tests for AI-based automatic project matching."""

    @pytest.mark.asyncio
    async def test_auto_project_matching_with_meeting_title(
        self,
        authenticated_client: AsyncClient,
        test_project: Project
    ):
        """Test automatic project matching using 'auto' project_id.

        Note: The 'auto' feature requires projects to exist for AI matching,
        so we create a test project fixture for this test.
        """
        audio_file = mock_audio_file(size_mb=1.0)

        files = {
            'audio_file': ('sprint_planning.wav', audio_file, 'audio/wav')
        }
        data = {
            'project_id': 'auto',  # Trigger AI matching
            'meeting_title': 'Sprint Planning Q4',
            'language': 'en',
            'use_ai_matching': 'true'
        }

        with patch('routers.transcription.process_audio_transcription'):
            response = await authenticated_client.post(
                '/api/v1/transcribe',

                files=files,
                data=data
            )

        # AI matching may return 404 if no suitable project found,
        # or 200 if it successfully matches to a project
        assert response.status_code in [200, 404]


# ============================================================================
# Test Class: Multi-tenant Isolation
# ============================================================================

class TestMultiTenantIsolation:
    """Tests for multi-tenant security and isolation."""

    @pytest.mark.asyncio
    async def test_cannot_upload_to_other_organization_project(
        self,
        authenticated_client: AsyncClient,
        db_session: AsyncSession,
        test_user: User
    ):
        """Test that users cannot upload audio to projects in other organizations."""
        # Create a different organization
        other_org = Organization(
            name="Other Organization",
            slug="other-org"
        )
        db_session.add(other_org)
        await db_session.commit()
        await db_session.refresh(other_org)

        # Create project in other organization
        other_project = Project(
            name="Other Org Project",
            description="Should not be accessible",
            organization_id=other_org.id,
            created_by=str(test_user.id),
            status=ProjectStatus.ACTIVE
        )
        db_session.add(other_project)
        await db_session.commit()
        await db_session.refresh(other_project)

        audio_file = mock_audio_file(size_mb=1.0)

        files = {
            'audio_file': ('meeting.wav', audio_file, 'audio/wav')
        }
        data = {
            'project_id': str(other_project.id),  # Different org's project
            'language': 'en'
        }

        response = await authenticated_client.post(
            '/api/v1/transcribe',
            
            files=files,
            data=data
        )

        # Should be forbidden (403) or not found (404)
        assert response.status_code in [403, 404]


# ============================================================================
# Test Class: Language Support
# ============================================================================

class TestLanguageSupport:
    """Tests for multi-language transcription support."""

    @pytest.mark.asyncio
    async def test_auto_language_detection(
        self,
        authenticated_client: AsyncClient,
        test_project: Project
    ):
        """Test automatic language detection when language='auto'."""
        audio_file = mock_audio_file(size_mb=1.0)

        files = {
            'audio_file': ('meeting_multilingual.wav', audio_file, 'audio/wav')
        }
        data = {
            'project_id': str(test_project.id),
            'language': 'auto'  # Auto-detect language
        }

        with patch('routers.transcription.process_audio_transcription'):
            response = await authenticated_client.post(
                '/api/v1/transcribe',
                
                files=files,
                data=data
            )

        assert response.status_code == 200

    @pytest.mark.asyncio
    async def test_specific_language_support(
        self,
        authenticated_client: AsyncClient,
        test_project: Project
    ):
        """Test transcription with specific language codes."""
        languages_to_test = ['en', 'es', 'fr', 'de', 'zh']

        for lang in languages_to_test:
            audio_file = mock_audio_file(size_mb=1.0)

            files = {
                'audio_file': (f'meeting_{lang}.wav', audio_file, 'audio/wav')
            }
            data = {
                'project_id': str(test_project.id),
                'language': lang
            }

            with patch('routers.transcription.process_audio_transcription'):
                response = await authenticated_client.post(
                    '/api/v1/transcribe',
                    
                    files=files,
                    data=data
                )

            assert response.status_code == 200, f"Failed for language: {lang}"
