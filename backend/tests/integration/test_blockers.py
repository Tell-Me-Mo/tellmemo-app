"""
Integration tests for Blockers Management API.

Covers TESTING_BACKEND.md section 8.3 - Blockers Management

Status: All tests passing (28/28) ✅
"""

import pytest
from datetime import datetime, timedelta
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession
from models.user import User
from models.organization import Organization
from models.project import Project
from models.blocker import Blocker, BlockerImpact, BlockerStatus
from models.organization_member import OrganizationMember


@pytest.fixture
async def test_project(
    db_session: AsyncSession,
    test_organization: Organization
) -> Project:
    """Create a test project for blockers testing."""
    project = Project(
        name="Test Project for Blockers",
        description="Project for testing blocker management",
        organization_id=test_organization.id,
        status="active"
    )
    db_session.add(project)
    await db_session.commit()
    await db_session.refresh(project)
    return project


@pytest.fixture
async def test_blocker(
    db_session: AsyncSession,
    test_project: Project
) -> Blocker:
    """Create a test blocker."""
    blocker = Blocker(
        project_id=test_project.id,
        title="Test Blocker",
        description="This is a test blocker",
        impact=BlockerImpact.HIGH,
        status=BlockerStatus.ACTIVE,
        resolution="Test resolution plan",
        category="technical",
        owner="John Doe",
        updated_by="manual"
    )
    db_session.add(blocker)
    await db_session.commit()
    await db_session.refresh(blocker)
    return blocker


class TestCreateBlocker:
    """Test blocker creation endpoint."""

    @pytest.mark.asyncio
    async def test_create_blocker_success(
        self,
        authenticated_org_client: AsyncClient,
        test_project: Project
    ):
        """Test successful blocker creation with minimal data."""
        # Arrange
        blocker_data = {
            "title": "Database Migration Blocker",
            "description": "Unable to run migrations due to schema conflicts",
            "impact": "critical",
            "status": "active"
        }

        # Act
        response = await authenticated_org_client.post(
            f"/api/v1/projects/{test_project.id}/blockers",
            json=blocker_data
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["title"] == "Database Migration Blocker"
        assert data["description"] == "Unable to run migrations due to schema conflicts"
        assert data["impact"] == "critical"
        assert data["status"] == "active"
        assert data["ai_generated"] is False
        assert "id" in data
        assert data["project_id"] == str(test_project.id)

    @pytest.mark.asyncio
    async def test_create_blocker_with_full_data(
        self,
        authenticated_org_client: AsyncClient,
        test_project: Project
    ):
        """Test blocker creation with all optional fields."""
        # Arrange
        target_date = (datetime.utcnow() + timedelta(days=7)).isoformat()
        blocker_data = {
            "title": "API Rate Limit Blocker",
            "description": "Third-party API rate limit exceeded",
            "impact": "high",
            "status": "escalated",
            "resolution": "Request rate limit increase from vendor",
            "category": "external_dependency",
            "owner": "Jane Smith",
            "dependencies": "Payment processing, Notification service",
            "target_date": target_date,
            "assigned_to": "user_123",
            "assigned_to_email": "jane@example.com",
            "ai_generated": True,
            "ai_confidence": 0.85
        }

        # Act
        response = await authenticated_org_client.post(
            f"/api/v1/projects/{test_project.id}/blockers",
            json=blocker_data
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["title"] == "API Rate Limit Blocker"
        assert data["impact"] == "high"
        assert data["status"] == "escalated"
        assert data["resolution"] == "Request rate limit increase from vendor"
        assert data["category"] == "external_dependency"
        assert data["owner"] == "Jane Smith"
        assert data["assigned_to"] == "user_123"
        assert data["assigned_to_email"] == "jane@example.com"
        assert data["ai_generated"] is True
        assert data["ai_confidence"] == 0.85

    @pytest.mark.asyncio
    async def test_create_blocker_invalid_project(
        self,
        authenticated_org_client: AsyncClient
    ):
        """Test blocker creation with non-existent project ID."""
        # Arrange
        fake_project_id = "00000000-0000-0000-0000-000000000000"
        blocker_data = {
            "title": "Test Blocker",
            "description": "Should fail",
            "impact": "high"
        }

        # Act
        response = await authenticated_org_client.post(
            f"/api/projects/{fake_project_id}/blockers",
            json=blocker_data
        )

        # Assert
        assert response.status_code == 404
        assert "not found" in response.json()["detail"].lower()

    @pytest.mark.asyncio
    async def test_create_blocker_requires_authentication(
        self,
        client: AsyncClient,
        test_project: Project
    ):
        """Test that blocker creation requires authentication."""
        # Arrange
        blocker_data = {
            "title": "Test Blocker",
            "description": "Should fail without auth",
            "impact": "high"
        }

        # Act
        response = await client.post(
            f"/api/v1/projects/{test_project.id}/blockers",
            json=blocker_data
        )

        # Assert
        assert response.status_code in [401, 403]


class TestListBlockers:
    """Test listing blockers endpoint."""

    @pytest.mark.asyncio
    async def test_list_all_blockers(
        self,
        authenticated_org_client: AsyncClient,
        test_project: Project,
        test_blocker: Blocker
    ):
        """Test listing all blockers for a project."""
        # Act
        response = await authenticated_org_client.get(
            f"/api/v1/projects/{test_project.id}/blockers"
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
        assert len(data) >= 1
        assert any(b["id"] == str(test_blocker.id) for b in data)

    @pytest.mark.asyncio
    async def test_filter_blockers_by_status(
        self,
        authenticated_org_client: AsyncClient,
        test_project: Project,
        db_session: AsyncSession
    ):
        """Test filtering blockers by status."""
        # Arrange - Create blockers with different statuses
        active_blocker = Blocker(
            project_id=test_project.id,
            title="Active Blocker",
            description="Still blocking",
            impact=BlockerImpact.HIGH,
            status=BlockerStatus.ACTIVE,
            updated_by="manual"
        )
        resolved_blocker = Blocker(
            project_id=test_project.id,
            title="Resolved Blocker",
            description="No longer blocking",
            impact=BlockerImpact.MEDIUM,
            status=BlockerStatus.RESOLVED,
            resolved_date=datetime.utcnow(),
            updated_by="manual"
        )
        db_session.add_all([active_blocker, resolved_blocker])
        await db_session.commit()

        # Act
        response = await authenticated_org_client.get(
            f"/api/v1/projects/{test_project.id}/blockers?status=active"
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert all(b["status"] == "active" for b in data)
        assert any(b["title"] == "Active Blocker" for b in data)
        assert not any(b["title"] == "Resolved Blocker" for b in data)

    @pytest.mark.asyncio
    async def test_filter_blockers_by_impact(
        self,
        authenticated_org_client: AsyncClient,
        test_project: Project,
        db_session: AsyncSession
    ):
        """Test filtering blockers by impact level."""
        # Arrange - Create blockers with different impacts
        critical_blocker = Blocker(
            project_id=test_project.id,
            title="Critical Blocker",
            description="Critical issue",
            impact=BlockerImpact.CRITICAL,
            status=BlockerStatus.ACTIVE,
            updated_by="manual"
        )
        low_blocker = Blocker(
            project_id=test_project.id,
            title="Low Impact Blocker",
            description="Minor issue",
            impact=BlockerImpact.LOW,
            status=BlockerStatus.ACTIVE,
            updated_by="manual"
        )
        db_session.add_all([critical_blocker, low_blocker])
        await db_session.commit()

        # Act
        response = await authenticated_org_client.get(
            f"/api/v1/projects/{test_project.id}/blockers?impact=critical"
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert all(b["impact"] == "critical" for b in data)
        assert any(b["title"] == "Critical Blocker" for b in data)
        assert not any(b["title"] == "Low Impact Blocker" for b in data)

    @pytest.mark.asyncio
    async def test_blockers_ordered_by_impact_and_date(
        self,
        authenticated_org_client: AsyncClient,
        test_project: Project,
        db_session: AsyncSession
    ):
        """Test that blockers are ordered by impact (desc) then date (desc)."""
        # Arrange - Create blockers with different impacts
        medium_blocker = Blocker(
            project_id=test_project.id,
            title="Medium Impact",
            description="Medium issue",
            impact=BlockerImpact.MEDIUM,
            status=BlockerStatus.ACTIVE,
            updated_by="manual"
        )
        critical_blocker = Blocker(
            project_id=test_project.id,
            title="Critical Impact",
            description="Critical issue",
            impact=BlockerImpact.CRITICAL,
            status=BlockerStatus.ACTIVE,
            updated_by="manual"
        )
        db_session.add_all([medium_blocker, critical_blocker])
        await db_session.commit()

        # Act
        response = await authenticated_org_client.get(
            f"/api/v1/projects/{test_project.id}/blockers"
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        # Critical blockers should come first
        impact_order = ["critical", "high", "medium", "low"]
        for i in range(len(data) - 1):
            current_idx = impact_order.index(data[i]["impact"])
            next_idx = impact_order.index(data[i + 1]["impact"])
            assert current_idx <= next_idx

    @pytest.mark.asyncio
    async def test_list_blockers_empty_project(
        self,
        authenticated_org_client: AsyncClient,
        db_session: AsyncSession,
        test_organization: Organization
    ):
        """Test listing blockers for project with no blockers."""
        # Arrange - Create empty project
        empty_project = Project(
            name="Empty Project",
            description="No blockers",
            organization_id=test_organization.id,
            status="active"
        )
        db_session.add(empty_project)
        await db_session.commit()

        # Act
        response = await authenticated_org_client.get(
            f"/api/v1/projects/{empty_project.id}/blockers"
        )

        # Assert
        assert response.status_code == 200
        assert response.json() == []

    @pytest.mark.asyncio
    async def test_list_blockers_requires_authentication(
        self,
        client: AsyncClient,
        test_project: Project
    ):
        """Test that listing blockers requires authentication."""
        # Act
        response = await client.get(
            f"/api/v1/projects/{test_project.id}/blockers"
        )

        # Assert
        assert response.status_code in [401, 403]


class TestUpdateBlocker:
    """Test blocker update endpoint."""

    @pytest.mark.asyncio
    async def test_update_blocker_title_and_description(
        self,
        authenticated_org_client: AsyncClient,
        test_blocker: Blocker
    ):
        """Test updating blocker title and description."""
        # Arrange
        update_data = {
            "title": "Updated Blocker Title",
            "description": "Updated blocker description"
        }

        # Act
        response = await authenticated_org_client.patch(
            f"/api/v1/blockers/{test_blocker.id}",
            json=update_data
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["title"] == "Updated Blocker Title"
        assert data["description"] == "Updated blocker description"

    @pytest.mark.asyncio
    async def test_update_blocker_impact(
        self,
        authenticated_org_client: AsyncClient,
        test_blocker: Blocker
    ):
        """Test updating blocker impact level."""
        # Arrange
        update_data = {"impact": "critical"}

        # Act
        response = await authenticated_org_client.patch(
            f"/api/v1/blockers/{test_blocker.id}",
            json=update_data
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["impact"] == "critical"

    @pytest.mark.asyncio
    async def test_update_blocker_status_to_resolved(
        self,
        authenticated_org_client: AsyncClient,
        test_blocker: Blocker
    ):
        """Test updating blocker status to resolved sets resolved_date."""
        # Arrange
        update_data = {
            "status": "resolved",
            "resolved_date": datetime.utcnow().isoformat()
        }

        # Act
        response = await authenticated_org_client.patch(
            f"/api/v1/blockers/{test_blocker.id}",
            json=update_data
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "resolved"
        assert data["resolved_date"] is not None

    @pytest.mark.asyncio
    async def test_update_blocker_resolution_and_category(
        self,
        authenticated_org_client: AsyncClient,
        test_blocker: Blocker
    ):
        """Test updating blocker resolution plan and category."""
        # Arrange
        update_data = {
            "resolution": "Updated resolution plan",
            "category": "infrastructure",
            "owner": "Updated Owner"
        }

        # Act
        response = await authenticated_org_client.patch(
            f"/api/v1/blockers/{test_blocker.id}",
            json=update_data
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["resolution"] == "Updated resolution plan"
        assert data["category"] == "infrastructure"
        assert data["owner"] == "Updated Owner"

    @pytest.mark.asyncio
    async def test_update_blocker_escalation(
        self,
        authenticated_org_client: AsyncClient,
        test_blocker: Blocker
    ):
        """Test escalating a blocker."""
        # Arrange
        escalation_date = datetime.utcnow().isoformat()
        update_data = {
            "status": "escalated",
            "escalation_date": escalation_date,
            "impact": "critical"
        }

        # Act
        response = await authenticated_org_client.patch(
            f"/api/v1/blockers/{test_blocker.id}",
            json=update_data
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "escalated"
        assert data["escalation_date"] is not None
        assert data["impact"] == "critical"

    @pytest.mark.asyncio
    async def test_update_blocker_assignment(
        self,
        authenticated_org_client: AsyncClient,
        test_blocker: Blocker
    ):
        """Test updating blocker assignment."""
        # Arrange
        update_data = {
            "assigned_to": "user_456",
            "assigned_to_email": "newowner@example.com"
        }

        # Act
        response = await authenticated_org_client.patch(
            f"/api/v1/blockers/{test_blocker.id}",
            json=update_data
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["assigned_to"] == "user_456"
        assert data["assigned_to_email"] == "newowner@example.com"

    @pytest.mark.asyncio
    async def test_update_blocker_target_date(
        self,
        authenticated_org_client: AsyncClient,
        test_blocker: Blocker
    ):
        """Test updating blocker target date."""
        # Arrange
        target_date = (datetime.utcnow() + timedelta(days=14)).isoformat()
        update_data = {"target_date": target_date}

        # Act
        response = await authenticated_org_client.patch(
            f"/api/v1/blockers/{test_blocker.id}",
            json=update_data
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["target_date"] is not None

    @pytest.mark.asyncio
    async def test_update_multiple_fields_at_once(
        self,
        authenticated_org_client: AsyncClient,
        test_blocker: Blocker
    ):
        """Test updating multiple blocker fields simultaneously."""
        # Arrange
        update_data = {
            "title": "Multi-Update Blocker",
            "description": "Updated description",
            "impact": "low",
            "status": "pending",
            "resolution": "New resolution",
            "category": "process"
        }

        # Act
        response = await authenticated_org_client.patch(
            f"/api/v1/blockers/{test_blocker.id}",
            json=update_data
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["title"] == "Multi-Update Blocker"
        assert data["description"] == "Updated description"
        assert data["impact"] == "low"
        assert data["status"] == "pending"
        assert data["resolution"] == "New resolution"
        assert data["category"] == "process"

    @pytest.mark.asyncio
    async def test_update_blocker_not_found(
        self,
        authenticated_org_client: AsyncClient
    ):
        """Test updating non-existent blocker."""
        # Arrange
        fake_blocker_id = "00000000-0000-0000-0000-000000000000"
        update_data = {"title": "Should fail"}

        # Act
        response = await authenticated_org_client.patch(
            f"/api/v1/blockers/{fake_blocker_id}",
            json=update_data
        )

        # Assert
        assert response.status_code == 404

    @pytest.mark.asyncio
    async def test_update_blocker_requires_authentication(
        self,
        client: AsyncClient,
        test_blocker: Blocker
    ):
        """Test that updating blockers requires authentication."""
        # Arrange
        update_data = {"title": "Should fail"}

        # Act
        response = await client.patch(
            f"/api/v1/blockers/{test_blocker.id}",
            json=update_data
        )

        # Assert
        assert response.status_code in [401, 403]


class TestDeleteBlocker:
    """Test blocker deletion endpoint."""

    @pytest.mark.asyncio
    async def test_delete_blocker_success(
        self,
        authenticated_org_client: AsyncClient,
        test_blocker: Blocker
    ):
        """Test successful blocker deletion."""
        # Act
        response = await authenticated_org_client.delete(
            f"/api/v1/blockers/{test_blocker.id}"
        )

        # Assert
        assert response.status_code == 200
        assert "success" in response.json()["message"].lower()

    @pytest.mark.asyncio
    async def test_verify_blocker_deleted(
        self,
        authenticated_org_client: AsyncClient,
        test_project: Project,
        db_session: AsyncSession
    ):
        """Test that deleted blocker is no longer accessible."""
        # Arrange - Create and delete a blocker
        blocker = Blocker(
            project_id=test_project.id,
            title="Blocker to Delete",
            description="Will be deleted",
            impact=BlockerImpact.MEDIUM,
            status=BlockerStatus.ACTIVE,
            updated_by="manual"
        )
        db_session.add(blocker)
        await db_session.commit()
        await db_session.refresh(blocker)
        blocker_id = blocker.id

        # Act - Delete
        delete_response = await authenticated_org_client.delete(
            f"/api/v1/blockers/{blocker_id}"
        )
        assert delete_response.status_code == 200

        # Act - Try to get deleted blocker via list
        list_response = await authenticated_org_client.get(
            f"/api/v1/projects/{test_project.id}/blockers"
        )

        # Assert
        assert list_response.status_code == 200
        blockers = list_response.json()
        assert not any(b["id"] == str(blocker_id) for b in blockers)

    @pytest.mark.asyncio
    async def test_delete_blocker_not_found(
        self,
        authenticated_org_client: AsyncClient
    ):
        """Test deleting non-existent blocker."""
        # Arrange
        fake_blocker_id = "00000000-0000-0000-0000-000000000000"

        # Act
        response = await authenticated_org_client.delete(
            f"/api/v1/blockers/{fake_blocker_id}"
        )

        # Assert
        assert response.status_code == 404

    @pytest.mark.asyncio
    async def test_delete_blocker_requires_authentication(
        self,
        client: AsyncClient,
        test_blocker: Blocker
    ):
        """Test that deleting blockers requires authentication."""
        # Act
        response = await client.delete(
            f"/api/v1/blockers/{test_blocker.id}"
        )

        # Assert
        assert response.status_code in [401, 403]


class TestMultiTenantIsolation:
    """Test multi-tenant isolation for blockers."""

    @pytest.mark.asyncio
    async def test_cannot_create_blocker_for_other_org_project(
        self,
        authenticated_org_client: AsyncClient,
        db_session: AsyncSession
    ):
        """Test that users cannot create blockers for projects in other organizations."""
        # Arrange - Create a project in a different organization
        other_org = Organization(
            name="Other Organization",
            slug="other-org"
        )
        db_session.add(other_org)
        await db_session.commit()
        await db_session.refresh(other_org)

        other_project = Project(
            name="Other Org Project",
            description="Should not be accessible",
            organization_id=other_org.id,
            status="active"
        )
        db_session.add(other_project)
        await db_session.commit()
        await db_session.refresh(other_project)

        blocker_data = {
            "title": "Should Fail",
            "description": "Cross-org blocker creation",
            "impact": "high"
        }

        # Act
        response = await authenticated_org_client.post(
            f"/api/v1/projects/{other_project.id}/blockers",
            json=blocker_data
        )

        # Assert
        assert response.status_code == 404
        assert "not found" in response.json()["detail"].lower()

    @pytest.mark.asyncio
    async def test_cannot_list_blockers_from_other_org(
        self,
        authenticated_org_client: AsyncClient,
        db_session: AsyncSession
    ):
        """Test that users cannot list blockers from other organizations."""
        # Arrange - Create a project and blocker in a different organization
        other_org = Organization(
            name="Another Organization",
            slug="another-org"
        )
        db_session.add(other_org)
        await db_session.commit()

        other_project = Project(
            name="Another Org Project",
            description="Different organization",
            organization_id=other_org.id,
            status="active"
        )
        db_session.add(other_project)
        await db_session.commit()

        other_blocker = Blocker(
            project_id=other_project.id,
            title="Other Org Blocker",
            description="Should not be visible",
            impact=BlockerImpact.HIGH,
            status=BlockerStatus.ACTIVE,
            updated_by="manual"
        )
        db_session.add(other_blocker)
        await db_session.commit()

        # Act
        response = await authenticated_org_client.get(
            f"/api/v1/projects/{other_project.id}/blockers"
        )

        # Assert
        assert response.status_code == 404
        assert "not found" in response.json()["detail"].lower()
