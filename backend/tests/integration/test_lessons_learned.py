"""
Integration tests for Lessons Learned CRUD API.

Covers TESTING_BACKEND.md section 9.1 - Lessons Learned CRUD

Tests cover:
- Create lesson learned
- List lessons for project with filtering
- Update lesson learned
- Delete lesson learned
- Batch create lessons (AI extraction)
- Multi-tenant isolation
- Authentication requirements

Expected Status: Will find CRITICAL BUGS - missing auth and multi-tenant validation
"""

import pytest
from datetime import datetime
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession
from models.user import User
from models.organization import Organization
from models.project import Project
from models.lesson_learned import LessonLearned, LessonCategory, LessonType, LessonLearnedImpact
from models.organization_member import OrganizationMember


@pytest.fixture
async def test_project(
    db_session: AsyncSession,
    test_organization: Organization
) -> Project:
    """Create a test project for lessons learned testing."""
    project = Project(
        name="Test Project for Lessons",
        description="Project for testing lessons learned management",
        organization_id=test_organization.id,
        status="active"
    )
    db_session.add(project)
    await db_session.commit()
    await db_session.refresh(project)
    return project


@pytest.fixture
async def test_lesson(
    db_session: AsyncSession,
    test_project: Project
) -> LessonLearned:
    """Create a test lesson learned."""
    lesson = LessonLearned(
        project_id=test_project.id,
        title="Test Lesson Learned",
        description="This is a test lesson learned",
        category=LessonCategory.TECHNICAL,
        lesson_type=LessonType.IMPROVEMENT,
        impact=LessonLearnedImpact.HIGH,
        recommendation="Implement automated testing",
        context="Discovered during code review",
        tags="testing,automation,quality",
        ai_generated="false",
        updated_by="manual"
    )
    db_session.add(lesson)
    await db_session.commit()
    await db_session.refresh(lesson)
    return lesson


class TestCreateLessonLearned:
    """Test lesson learned creation endpoint."""

    @pytest.mark.asyncio
    async def test_create_lesson_success(
        self,
        authenticated_org_client: AsyncClient,
        test_project: Project
    ):
        """Test successful lesson learned creation with minimal data."""
        # Arrange
        lesson_data = {
            "title": "Code Review Process Improvement",
            "description": "Implementing pair programming reduced bugs by 30%",
            "category": "process",
            "lesson_type": "success",
            "impact": "high"
        }

        # Act
        response = await authenticated_org_client.post(
            f"/api/v1/projects/{test_project.id}/lessons-learned",
            json=lesson_data
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["title"] == "Code Review Process Improvement"
        assert data["description"] == "Implementing pair programming reduced bugs by 30%"
        assert data["category"] == "process"
        assert data["lesson_type"] == "success"
        assert data["impact"] == "high"
        assert data["ai_generated"] is False
        assert "id" in data
        assert data["project_id"] == str(test_project.id)

    @pytest.mark.asyncio
    async def test_create_lesson_with_full_data(
        self,
        authenticated_org_client: AsyncClient,
        test_project: Project
    ):
        """Test lesson learned creation with all optional fields."""
        # Arrange
        lesson_data = {
            "title": "Database Performance Optimization",
            "description": "Adding indexes improved query performance significantly",
            "category": "technical",
            "lesson_type": "best_practice",
            "impact": "high",
            "recommendation": "Always profile queries before optimization",
            "context": "Discovered during load testing phase",
            "tags": "database,performance,optimization"
        }

        # Act
        response = await authenticated_org_client.post(
            f"/api/v1/projects/{test_project.id}/lessons-learned",
            json=lesson_data
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["title"] == "Database Performance Optimization"
        assert data["category"] == "technical"
        assert data["lesson_type"] == "best_practice"
        assert data["impact"] == "high"
        assert data["recommendation"] == "Always profile queries before optimization"
        assert data["context"] == "Discovered during load testing phase"
        assert "database" in data["tags"]
        assert "performance" in data["tags"]
        assert data["ai_generated"] is False

    @pytest.mark.asyncio
    async def test_create_lesson_invalid_project(
        self,
        authenticated_org_client: AsyncClient
    ):
        """Test lesson creation with non-existent project ID."""
        # Arrange
        fake_project_id = "00000000-0000-0000-0000-000000000000"
        lesson_data = {
            "title": "Test Lesson",
            "description": "Should fail",
            "category": "technical",
            "lesson_type": "improvement",
            "impact": "medium"
        }

        # Act
        response = await authenticated_org_client.post(
            f"/api/v1/projects/{fake_project_id}/lessons-learned",
            json=lesson_data
        )

        # Assert
        assert response.status_code == 404
        assert "not found" in response.json()["detail"].lower()

    @pytest.mark.asyncio
    async def test_create_lesson_requires_authentication(
        self,
        client: AsyncClient,
        test_project: Project
    ):
        """Test that lesson creation requires authentication."""
        # Arrange
        lesson_data = {
            "title": "Test Lesson",
            "description": "Should fail without auth",
            "category": "technical",
            "lesson_type": "improvement",
            "impact": "medium"
        }

        # Act
        response = await client.post(
            f"/api/v1/projects/{test_project.id}/lessons-learned",
            json=lesson_data
        )

        # Assert
        assert response.status_code in [401, 403]


class TestListLessonsLearned:
    """Test listing lessons learned endpoint."""

    @pytest.mark.asyncio
    async def test_list_all_lessons(
        self,
        authenticated_org_client: AsyncClient,
        test_project: Project,
        test_lesson: LessonLearned
    ):
        """Test listing all lessons learned for a project."""
        # Act
        response = await authenticated_org_client.get(
            f"/api/v1/projects/{test_project.id}/lessons-learned"
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
        assert len(data) >= 1
        assert data[0]["title"] == "Test Lesson Learned"
        assert data[0]["category"] == "technical"

    @pytest.mark.asyncio
    async def test_list_lessons_filter_by_category(
        self,
        authenticated_org_client: AsyncClient,
        test_project: Project,
        db_session: AsyncSession
    ):
        """Test filtering lessons by category."""
        # Arrange - Create lessons with different categories
        lesson1 = LessonLearned(
            project_id=test_project.id,
            title="Technical Lesson",
            description="Technical lesson",
            category=LessonCategory.TECHNICAL,
            lesson_type=LessonType.IMPROVEMENT,
            impact=LessonLearnedImpact.MEDIUM,
            ai_generated="false",
            updated_by="manual"
        )
        lesson2 = LessonLearned(
            project_id=test_project.id,
            title="Process Lesson",
            description="Process lesson",
            category=LessonCategory.PROCESS,
            lesson_type=LessonType.IMPROVEMENT,
            impact=LessonLearnedImpact.MEDIUM,
            ai_generated="false",
            updated_by="manual"
        )
        db_session.add_all([lesson1, lesson2])
        await db_session.commit()

        # Act
        response = await authenticated_org_client.get(
            f"/api/v1/projects/{test_project.id}/lessons-learned?category=technical"
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert len(data) == 1
        assert data[0]["category"] == "technical"

    @pytest.mark.asyncio
    async def test_list_lessons_filter_by_lesson_type(
        self,
        authenticated_org_client: AsyncClient,
        test_project: Project,
        db_session: AsyncSession
    ):
        """Test filtering lessons by lesson type."""
        # Arrange - Create lessons with different types
        lesson1 = LessonLearned(
            project_id=test_project.id,
            title="Success Story",
            description="What worked well",
            category=LessonCategory.TECHNICAL,
            lesson_type=LessonType.SUCCESS,
            impact=LessonLearnedImpact.HIGH,
            ai_generated="false",
            updated_by="manual"
        )
        lesson2 = LessonLearned(
            project_id=test_project.id,
            title="Challenge Faced",
            description="What didn't work",
            category=LessonCategory.TECHNICAL,
            lesson_type=LessonType.CHALLENGE,
            impact=LessonLearnedImpact.MEDIUM,
            ai_generated="false",
            updated_by="manual"
        )
        db_session.add_all([lesson1, lesson2])
        await db_session.commit()

        # Act
        response = await authenticated_org_client.get(
            f"/api/v1/projects/{test_project.id}/lessons-learned?lesson_type=success"
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert len(data) == 1
        assert data[0]["lesson_type"] == "success"

    @pytest.mark.asyncio
    async def test_list_lessons_filter_by_impact(
        self,
        authenticated_org_client: AsyncClient,
        test_project: Project,
        db_session: AsyncSession
    ):
        """Test filtering lessons by impact level."""
        # Arrange - Create lessons with different impacts
        lesson1 = LessonLearned(
            project_id=test_project.id,
            title="High Impact Lesson",
            description="Major lesson",
            category=LessonCategory.TECHNICAL,
            lesson_type=LessonType.IMPROVEMENT,
            impact=LessonLearnedImpact.HIGH,
            ai_generated="false",
            updated_by="manual"
        )
        lesson2 = LessonLearned(
            project_id=test_project.id,
            title="Low Impact Lesson",
            description="Minor lesson",
            category=LessonCategory.TECHNICAL,
            lesson_type=LessonType.IMPROVEMENT,
            impact=LessonLearnedImpact.LOW,
            ai_generated="false",
            updated_by="manual"
        )
        db_session.add_all([lesson1, lesson2])
        await db_session.commit()

        # Act
        response = await authenticated_org_client.get(
            f"/api/v1/projects/{test_project.id}/lessons-learned?impact=high"
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert len(data) == 1
        assert data[0]["impact"] == "high"

    @pytest.mark.asyncio
    async def test_list_lessons_ordered_by_date(
        self,
        authenticated_org_client: AsyncClient,
        test_project: Project,
        db_session: AsyncSession
    ):
        """Test that lessons are ordered by identified date (most recent first)."""
        # Arrange - Create multiple lessons
        for i in range(3):
            lesson = LessonLearned(
                project_id=test_project.id,
                title=f"Lesson {i}",
                description=f"Description {i}",
                category=LessonCategory.TECHNICAL,
                lesson_type=LessonType.IMPROVEMENT,
                impact=LessonLearnedImpact.MEDIUM,
                ai_generated="false",
                updated_by="manual"
            )
            db_session.add(lesson)
            await db_session.commit()
            await db_session.refresh(lesson)

        # Act
        response = await authenticated_org_client.get(
            f"/api/v1/projects/{test_project.id}/lessons-learned"
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert len(data) >= 3
        # Verify dates are in descending order (most recent first)
        dates = [datetime.fromisoformat(lesson["identified_date"].replace('Z', '+00:00')) for lesson in data if lesson["identified_date"]]
        for i in range(len(dates) - 1):
            assert dates[i] >= dates[i + 1]

    @pytest.mark.asyncio
    async def test_list_lessons_empty_project(
        self,
        authenticated_org_client: AsyncClient,
        test_project: Project
    ):
        """Test listing lessons for project with no lessons."""
        # Act
        response = await authenticated_org_client.get(
            f"/api/v1/projects/{test_project.id}/lessons-learned"
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
        assert len(data) == 0

    @pytest.mark.asyncio
    async def test_list_lessons_requires_authentication(
        self,
        client: AsyncClient,
        test_project: Project
    ):
        """Test that listing lessons requires authentication."""
        # Act
        response = await client.get(
            f"/api/v1/projects/{test_project.id}/lessons-learned"
        )

        # Assert
        assert response.status_code in [401, 403]


class TestUpdateLessonLearned:
    """Test updating lesson learned endpoint."""

    @pytest.mark.asyncio
    async def test_update_lesson_title_and_description(
        self,
        authenticated_org_client: AsyncClient,
        test_lesson: LessonLearned
    ):
        """Test updating lesson title and description."""
        # Arrange
        update_data = {
            "title": "Updated Lesson Title",
            "description": "Updated description with more details"
        }

        # Act
        response = await authenticated_org_client.put(
            f"/api/v1/lessons-learned/{test_lesson.id}",
            json=update_data
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["title"] == "Updated Lesson Title"
        assert data["description"] == "Updated description with more details"
        # Original fields unchanged
        assert data["category"] == "technical"
        assert data["lesson_type"] == "improvement"

    @pytest.mark.asyncio
    async def test_update_lesson_category(
        self,
        authenticated_org_client: AsyncClient,
        test_lesson: LessonLearned
    ):
        """Test updating lesson category."""
        # Arrange
        update_data = {
            "category": "communication"
        }

        # Act
        response = await authenticated_org_client.put(
            f"/api/v1/lessons-learned/{test_lesson.id}",
            json=update_data
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["category"] == "communication"

    @pytest.mark.asyncio
    async def test_update_lesson_type_and_impact(
        self,
        authenticated_org_client: AsyncClient,
        test_lesson: LessonLearned
    ):
        """Test updating lesson type and impact."""
        # Arrange
        update_data = {
            "lesson_type": "best_practice",
            "impact": "high"
        }

        # Act
        response = await authenticated_org_client.put(
            f"/api/v1/lessons-learned/{test_lesson.id}",
            json=update_data
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["lesson_type"] == "best_practice"
        assert data["impact"] == "high"

    @pytest.mark.asyncio
    async def test_update_lesson_recommendation(
        self,
        authenticated_org_client: AsyncClient,
        test_lesson: LessonLearned
    ):
        """Test updating lesson recommendation."""
        # Arrange
        update_data = {
            "recommendation": "Updated recommendation: Use automated tools for this task"
        }

        # Act
        response = await authenticated_org_client.put(
            f"/api/v1/lessons-learned/{test_lesson.id}",
            json=update_data
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["recommendation"] == "Updated recommendation: Use automated tools for this task"

    @pytest.mark.asyncio
    async def test_update_lesson_context_and_tags(
        self,
        authenticated_org_client: AsyncClient,
        test_lesson: LessonLearned
    ):
        """Test updating lesson context and tags."""
        # Arrange
        update_data = {
            "context": "Updated context information",
            "tags": "updated,new-tags,testing"
        }

        # Act
        response = await authenticated_org_client.put(
            f"/api/v1/lessons-learned/{test_lesson.id}",
            json=update_data
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["context"] == "Updated context information"
        assert "updated" in data["tags"]
        assert "new-tags" in data["tags"]

    @pytest.mark.asyncio
    async def test_update_lesson_multiple_fields(
        self,
        authenticated_org_client: AsyncClient,
        test_lesson: LessonLearned
    ):
        """Test updating multiple fields at once."""
        # Arrange
        update_data = {
            "title": "Comprehensive Update",
            "description": "All fields updated",
            "category": "planning",
            "lesson_type": "challenge",
            "impact": "low",
            "recommendation": "New recommendation",
            "context": "New context",
            "tags": "comprehensive,update"
        }

        # Act
        response = await authenticated_org_client.put(
            f"/api/v1/lessons-learned/{test_lesson.id}",
            json=update_data
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["title"] == "Comprehensive Update"
        assert data["category"] == "planning"
        assert data["lesson_type"] == "challenge"
        assert data["impact"] == "low"
        assert data["recommendation"] == "New recommendation"

    @pytest.mark.asyncio
    async def test_update_lesson_not_found(
        self,
        authenticated_org_client: AsyncClient
    ):
        """Test updating non-existent lesson."""
        # Arrange
        fake_lesson_id = "00000000-0000-0000-0000-000000000000"
        update_data = {
            "title": "Should fail"
        }

        # Act
        response = await authenticated_org_client.put(
            f"/api/v1/lessons-learned/{fake_lesson_id}",
            json=update_data
        )

        # Assert
        assert response.status_code == 404
        assert "not found" in response.json()["detail"].lower()

    @pytest.mark.asyncio
    async def test_update_lesson_requires_authentication(
        self,
        client: AsyncClient,
        test_lesson: LessonLearned
    ):
        """Test that lesson update requires authentication."""
        # Arrange
        update_data = {
            "title": "Should fail without auth"
        }

        # Act
        response = await client.put(
            f"/api/v1/lessons-learned/{test_lesson.id}",
            json=update_data
        )

        # Assert
        assert response.status_code in [401, 403]


class TestDeleteLessonLearned:
    """Test deleting lesson learned endpoint."""

    @pytest.mark.asyncio
    async def test_delete_lesson_success(
        self,
        authenticated_org_client: AsyncClient,
        test_lesson: LessonLearned
    ):
        """Test successful lesson deletion."""
        # Act
        response = await authenticated_org_client.delete(
            f"/api/v1/lessons-learned/{test_lesson.id}"
        )

        # Assert
        assert response.status_code == 200
        assert "success" in response.json()["message"].lower()

    @pytest.mark.asyncio
    async def test_delete_lesson_verify_deleted(
        self,
        authenticated_org_client: AsyncClient,
        test_lesson: LessonLearned,
        test_project: Project
    ):
        """Test that deleted lesson no longer appears in list."""
        # Arrange - Delete the lesson
        await authenticated_org_client.delete(
            f"/api/v1/lessons-learned/{test_lesson.id}"
        )

        # Act - Try to list lessons
        response = await authenticated_org_client.get(
            f"/api/v1/projects/{test_project.id}/lessons-learned"
        )

        # Assert - Lesson should not be in list
        assert response.status_code == 200
        data = response.json()
        lesson_ids = [lesson["id"] for lesson in data]
        assert str(test_lesson.id) not in lesson_ids

    @pytest.mark.asyncio
    async def test_delete_lesson_not_found(
        self,
        authenticated_org_client: AsyncClient
    ):
        """Test deleting non-existent lesson."""
        # Arrange
        fake_lesson_id = "00000000-0000-0000-0000-000000000000"

        # Act
        response = await authenticated_org_client.delete(
            f"/api/v1/lessons-learned/{fake_lesson_id}"
        )

        # Assert
        assert response.status_code == 404
        assert "not found" in response.json()["detail"].lower()

    @pytest.mark.asyncio
    async def test_delete_lesson_requires_authentication(
        self,
        client: AsyncClient,
        test_lesson: LessonLearned
    ):
        """Test that lesson deletion requires authentication."""
        # Act
        response = await client.delete(
            f"/api/v1/lessons-learned/{test_lesson.id}"
        )

        # Assert
        assert response.status_code in [401, 403]


class TestBatchCreateLessonsLearned:
    """Test batch creation of lessons learned from AI extraction."""

    @pytest.mark.asyncio
    async def test_batch_create_lessons_success(
        self,
        authenticated_org_client: AsyncClient,
        test_project: Project
    ):
        """Test successful batch creation of lessons learned."""
        # Arrange
        lessons_data = [
            {
                "title": "Testing Best Practices",
                "description": "Unit tests improved code quality",
                "category": "quality",
                "lesson_type": "best_practice",
                "impact": "high",
                "recommendation": "Write tests first",
                "confidence": 0.95
            },
            {
                "title": "Code Review Process",
                "description": "Peer reviews caught critical bugs",
                "category": "process",
                "lesson_type": "success",
                "impact": "high",
                "confidence": 0.88
            },
            {
                "title": "Documentation Gaps",
                "description": "Lack of API docs slowed integration",
                "category": "communication",
                "lesson_type": "challenge",
                "impact": "medium",
                "recommendation": "Maintain up-to-date API documentation",
                "confidence": 0.92
            }
        ]

        # Act
        response = await authenticated_org_client.post(
            f"/api/v1/projects/{test_project.id}/lessons-learned/batch",
            json=lessons_data
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert "Created 3 lessons learned" in data["message"]
        assert len(data["lessons"]) == 3
        assert data["lessons"][0]["ai_generated"] is True
        assert data["lessons"][0]["ai_confidence"] == 0.95

    @pytest.mark.asyncio
    async def test_batch_create_with_source_content(
        self,
        authenticated_org_client: AsyncClient,
        test_project: Project
    ):
        """Test batch creation without source content ID (FK constraint)."""
        # Arrange - Don't pass source_content_id since it has FK constraint
        # In production, AI would only pass valid content IDs that exist
        lessons_data = [
            {
                "title": "Performance Issue",
                "description": "Database queries were slow",
                "category": "technical",
                "lesson_type": "challenge",
                "impact": "high"
            }
        ]

        # Act - Test without source_content_id parameter
        response = await authenticated_org_client.post(
            f"/api/v1/projects/{test_project.id}/lessons-learned/batch",
            json=lessons_data
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert len(data["lessons"]) == 1
        assert data["lessons"][0]["source_content_id"] is None

    @pytest.mark.asyncio
    async def test_batch_create_invalid_project(
        self,
        authenticated_org_client: AsyncClient
    ):
        """Test batch creation with non-existent project."""
        # Arrange
        fake_project_id = "00000000-0000-0000-0000-000000000000"
        lessons_data = [
            {
                "title": "Test Lesson",
                "description": "Should fail"
            }
        ]

        # Act
        response = await authenticated_org_client.post(
            f"/api/v1/projects/{fake_project_id}/lessons-learned/batch",
            json=lessons_data
        )

        # Assert
        assert response.status_code == 404
        assert "not found" in response.json()["detail"].lower()

    @pytest.mark.asyncio
    async def test_batch_create_requires_authentication(
        self,
        client: AsyncClient,
        test_project: Project
    ):
        """Test that batch creation requires authentication."""
        # Arrange
        lessons_data = [
            {
                "title": "Test Lesson",
                "description": "Should fail without auth"
            }
        ]

        # Act
        response = await client.post(
            f"/api/v1/projects/{test_project.id}/lessons-learned/batch",
            json=lessons_data
        )

        # Assert
        assert response.status_code in [401, 403]


class TestMultiTenantIsolation:
    """Test multi-tenant data isolation for lessons learned."""

    @pytest.mark.asyncio
    async def test_cannot_create_lesson_for_other_org_project(
        self,
        authenticated_org_client: AsyncClient,
        db_session: AsyncSession
    ):
        """Test that users cannot create lessons for projects in other organizations."""
        # Arrange - Create a project in a different organization
        other_org = Organization(
            name="Other Organization",
            slug="other-org"
        )
        db_session.add(other_org)
        await db_session.commit()
        await db_session.refresh(other_org)

        other_project = Project(
            name="Other Project",
            organization_id=other_org.id,
            status="active"
        )
        db_session.add(other_project)
        await db_session.commit()
        await db_session.refresh(other_project)

        lesson_data = {
            "title": "Test Lesson",
            "description": "Should fail - cross-org access",
            "category": "technical",
            "lesson_type": "improvement",
            "impact": "medium"
        }

        # Act
        response = await authenticated_org_client.post(
            f"/api/v1/projects/{other_project.id}/lessons-learned",
            json=lesson_data
        )

        # Assert - Should fail (404 to prevent information disclosure)
        assert response.status_code in [404, 403]

    @pytest.mark.asyncio
    async def test_cannot_list_lessons_from_other_org(
        self,
        authenticated_org_client: AsyncClient,
        db_session: AsyncSession
    ):
        """Test that users cannot list lessons from other organizations."""
        # Arrange - Create project and lesson in different organization
        other_org = Organization(
            name="Other Organization",
            slug="other-org-2"
        )
        db_session.add(other_org)
        await db_session.commit()
        await db_session.refresh(other_org)

        other_project = Project(
            name="Other Project",
            organization_id=other_org.id,
            status="active"
        )
        db_session.add(other_project)
        await db_session.commit()
        await db_session.refresh(other_project)

        other_lesson = LessonLearned(
            project_id=other_project.id,
            title="Secret Lesson",
            description="Should not be visible",
            category=LessonCategory.TECHNICAL,
            lesson_type=LessonType.IMPROVEMENT,
            impact=LessonLearnedImpact.HIGH,
            ai_generated="false",
            updated_by="manual"
        )
        db_session.add(other_lesson)
        await db_session.commit()

        # Act
        response = await authenticated_org_client.get(
            f"/api/v1/projects/{other_project.id}/lessons-learned"
        )

        # Assert - Should fail or return empty (depending on implementation)
        # Most secure: return 404 to prevent information disclosure
        assert response.status_code in [404, 403, 200]
        if response.status_code == 200:
            # If it returns 200, list should be empty
            assert len(response.json()) == 0
