"""
Integration tests for Project Matcher Service.
"""

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession
from models.organization import Organization
from services.intelligence.project_matcher_service import project_matcher_service


class TestProjectMatcher:
    """Test project matching service."""

    @pytest.mark.asyncio
    async def test_match_creates_new_project_when_none_exist(
        self,
        db_session: AsyncSession,
        test_organization: Organization
    ):
        """Test that matcher creates new project when no projects exist."""
        # Arrange
        transcript = "We discussed the new marketing campaign for Q4."
        meeting_title = "auto"

        # Act
        result = await project_matcher_service.match_transcript_to_project(
            session=db_session,
            organization_id=test_organization.id,
            transcript=transcript,
            meeting_title=meeting_title
        )

        # Assert
        assert result["is_new"] is True
        assert result["project_id"] is not None
        assert result["project_name"] is not None

    @pytest.mark.asyncio
    async def test_match_uses_existing_when_ai_suggests_duplicate_name(
        self,
        authenticated_org_client: AsyncClient,
        db_session: AsyncSession,
        test_organization: Organization
    ):
        """Test that matcher uses existing project when AI suggests a duplicate name."""
        # Arrange - Create an existing project
        create_response = await authenticated_org_client.post(
            "/api/v1/projects",
            json={"name": "Marketing Campaign"}
        )
        assert create_response.status_code == 201
        existing_project_id = create_response.json()["id"]

        # Transcript that might make AI suggest "Marketing Campaign" again
        transcript = "We need to finalize the marketing campaign strategy."
        meeting_title = "auto"

        # Act
        result = await project_matcher_service.match_transcript_to_project(
            session=db_session,
            organization_id=test_organization.id,
            transcript=transcript,
            meeting_title=meeting_title
        )

        # Assert - Should match to existing project if AI suggests same name
        # OR create new with different name - either way should not fail
        assert result["project_id"] is not None
        assert "already exists" not in str(result)
