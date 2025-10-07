"""
Integration tests for Risks Management API.

Covers TESTING_BACKEND.md section 8.1 - Risks Management

Status: TBD
"""

import pytest
from datetime import datetime
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession
from models.user import User
from models.organization import Organization
from models.project import Project
from models.risk import Risk, RiskSeverity, RiskStatus
from models.organization_member import OrganizationMember


@pytest.fixture
async def test_project(
    db_session: AsyncSession,
    test_organization: Organization
) -> Project:
    """Create a test project for risks testing."""
    project = Project(
        name="Test Project for Risks",
        description="Project for testing risk management",
        organization_id=test_organization.id,
        status="active"
    )
    db_session.add(project)
    await db_session.commit()
    await db_session.refresh(project)
    return project


@pytest.fixture
async def test_risk(
    db_session: AsyncSession,
    test_project: Project
) -> Risk:
    """Create a test risk."""
    risk = Risk(
        project_id=test_project.id,
        title="Test Risk",
        description="This is a test risk",
        severity=RiskSeverity.HIGH,
        status=RiskStatus.IDENTIFIED,
        mitigation="Test mitigation",
        impact="High impact on delivery",
        probability=0.7,
        updated_by="manual"
    )
    db_session.add(risk)
    await db_session.commit()
    await db_session.refresh(risk)
    return risk


class TestCreateRisk:
    """Test risk creation endpoint."""

    @pytest.mark.asyncio
    async def test_create_risk_success(
        self,
        authenticated_org_client: AsyncClient,
        test_project: Project
    ):
        """Test successful risk creation with minimal data."""
        # Arrange
        risk_data = {
            "title": "Security Vulnerability",
            "description": "SQL injection vulnerability found in API",
            "severity": "critical",
            "status": "identified"
        }

        # Act
        response = await authenticated_org_client.post(
            f"/api/v1/projects/{test_project.id}/risks",
            json=risk_data
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["title"] == "Security Vulnerability"
        assert data["description"] == "SQL injection vulnerability found in API"
        assert data["severity"] == "critical"
        assert data["status"] == "identified"
        assert data["ai_generated"] is False
        assert "id" in data
        assert data["project_id"] == str(test_project.id)

    @pytest.mark.asyncio
    async def test_create_risk_with_full_data(
        self,
        authenticated_org_client: AsyncClient,
        test_project: Project
    ):
        """Test risk creation with all optional fields."""
        # Arrange
        risk_data = {
            "title": "Budget Overrun Risk",
            "description": "Project may exceed budget by 20%",
            "severity": "high",
            "status": "mitigating",
            "mitigation": "Review budget weekly and reduce scope",
            "impact": "20% budget increase required",
            "probability": 0.6,
            "assigned_to": "John Doe",
            "assigned_to_email": "john@example.com",
            "ai_generated": True,
            "ai_confidence": 0.85
        }

        # Act
        response = await authenticated_org_client.post(
            f"/api/v1/projects/{test_project.id}/risks",
            json=risk_data
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["title"] == "Budget Overrun Risk"
        assert data["mitigation"] == "Review budget weekly and reduce scope"
        assert data["impact"] == "20% budget increase required"
        assert data["probability"] == 0.6
        assert data["assigned_to"] == "John Doe"
        assert data["assigned_to_email"] == "john@example.com"
        assert data["ai_generated"] is True
        assert data["ai_confidence"] == 0.85

    @pytest.mark.asyncio
    async def test_create_risk_invalid_project(
        self,
        authenticated_org_client: AsyncClient
    ):
        """Test creating risk for non-existent project returns 404."""
        # Arrange
        fake_project_id = "00000000-0000-0000-0000-000000000000"
        risk_data = {
            "title": "Test Risk",
            "description": "This should fail"
        }

        # Act
        response = await authenticated_org_client.post(
            f"/api/v1/projects/{fake_project_id}/risks",
            json=risk_data
        )

        # Assert
        assert response.status_code == 404

    @pytest.mark.asyncio
    async def test_create_risk_without_auth_fails(
        self,
        client: AsyncClient,
        test_project: Project
    ):
        """Test that creating risk without authentication fails."""
        # Arrange
        risk_data = {
            "title": "Unauthorized Risk",
            "description": "Should not be created"
        }

        # Act
        response = await client.post(
            f"/api/v1/projects/{test_project.id}/risks",
            json=risk_data
        )

        # Assert - EXPOSES BUG: Should return 401/403 but will succeed
        # This test will FAIL because endpoint lacks authentication
        assert response.status_code in [401, 403]


class TestListRisks:
    """Test listing risks for a project."""

    @pytest.mark.asyncio
    async def test_list_risks_success(
        self,
        authenticated_org_client: AsyncClient,
        test_project: Project,
        test_risk: Risk,
        db_session: AsyncSession
    ):
        """Test listing all risks for a project."""
        # Arrange - Create additional risks
        risk2 = Risk(
            project_id=test_project.id,
            title="Another Risk",
            description="Second risk",
            severity=RiskSeverity.MEDIUM,
            status=RiskStatus.IDENTIFIED,
            updated_by="manual"
        )
        db_session.add(risk2)
        await db_session.commit()

        # Act
        response = await authenticated_org_client.get(
            f"/api/v1/projects/{test_project.id}/risks"
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert len(data) == 2
        # Verify ordering (by severity desc, then date desc)
        assert data[0]["severity"] == "high"
        assert data[1]["severity"] == "medium"

    @pytest.mark.asyncio
    async def test_list_risks_filter_by_status(
        self,
        authenticated_org_client: AsyncClient,
        test_project: Project,
        db_session: AsyncSession
    ):
        """Test filtering risks by status."""
        # Arrange - Create risks with different statuses
        risk1 = Risk(
            project_id=test_project.id,
            title="Identified Risk",
            description="New risk",
            severity=RiskSeverity.HIGH,
            status=RiskStatus.IDENTIFIED,
            updated_by="manual"
        )
        risk2 = Risk(
            project_id=test_project.id,
            title="Resolved Risk",
            description="Old risk",
            severity=RiskSeverity.MEDIUM,
            status=RiskStatus.RESOLVED,
            updated_by="manual"
        )
        db_session.add_all([risk1, risk2])
        await db_session.commit()

        # Act
        response = await authenticated_org_client.get(
            f"/api/v1/projects/{test_project.id}/risks?status=identified"
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert len(data) == 1
        assert data[0]["status"] == "identified"

    @pytest.mark.asyncio
    async def test_list_risks_filter_by_severity(
        self,
        authenticated_org_client: AsyncClient,
        test_project: Project,
        db_session: AsyncSession
    ):
        """Test filtering risks by severity."""
        # Arrange - Create risks with different severities
        risk1 = Risk(
            project_id=test_project.id,
            title="Critical Risk",
            description="Very severe",
            severity=RiskSeverity.CRITICAL,
            status=RiskStatus.IDENTIFIED,
            updated_by="manual"
        )
        risk2 = Risk(
            project_id=test_project.id,
            title="Low Risk",
            description="Minor issue",
            severity=RiskSeverity.LOW,
            status=RiskStatus.IDENTIFIED,
            updated_by="manual"
        )
        db_session.add_all([risk1, risk2])
        await db_session.commit()

        # Act
        response = await authenticated_org_client.get(
            f"/api/v1/projects/{test_project.id}/risks?severity=critical"
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert len(data) == 1
        assert data[0]["severity"] == "critical"

    @pytest.mark.asyncio
    async def test_list_risks_empty_project(
        self,
        authenticated_org_client: AsyncClient,
        test_project: Project
    ):
        """Test listing risks for project with no risks returns empty array."""
        # Act
        response = await authenticated_org_client.get(
            f"/api/v1/projects/{test_project.id}/risks"
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data == []

    @pytest.mark.asyncio
    async def test_list_risks_invalid_project(
        self,
        authenticated_org_client: AsyncClient
    ):
        """Test listing risks for non-existent project returns 404."""
        # Arrange
        fake_project_id = "00000000-0000-0000-0000-000000000000"

        # Act
        response = await authenticated_org_client.get(
            f"/api/v1/projects/{fake_project_id}/risks"
        )

        # Assert
        assert response.status_code == 404


class TestUpdateRisk:
    """Test risk update endpoint."""

    @pytest.mark.asyncio
    async def test_update_risk_title_and_description(
        self,
        authenticated_org_client: AsyncClient,
        test_risk: Risk
    ):
        """Test updating risk title and description."""
        # Arrange
        update_data = {
            "title": "Updated Risk Title",
            "description": "Updated description"
        }

        # Act
        response = await authenticated_org_client.patch(
            f"/api/v1/risks/{test_risk.id}",
            json=update_data
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["title"] == "Updated Risk Title"
        assert data["description"] == "Updated description"

    @pytest.mark.asyncio
    async def test_update_risk_severity(
        self,
        authenticated_org_client: AsyncClient,
        test_risk: Risk
    ):
        """Test updating risk severity."""
        # Arrange
        update_data = {"severity": "critical"}

        # Act
        response = await authenticated_org_client.patch(
            f"/api/v1/risks/{test_risk.id}",
            json=update_data
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["severity"] == "critical"

    @pytest.mark.asyncio
    async def test_update_risk_status_to_resolved(
        self,
        authenticated_org_client: AsyncClient,
        test_risk: Risk
    ):
        """Test updating risk status to resolved sets resolved_date."""
        # Arrange
        update_data = {"status": "resolved"}

        # Act
        response = await authenticated_org_client.patch(
            f"/api/v1/risks/{test_risk.id}",
            json=update_data
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "resolved"
        assert data["resolved_date"] is not None

    @pytest.mark.asyncio
    async def test_update_risk_mitigation_and_impact(
        self,
        authenticated_org_client: AsyncClient,
        test_risk: Risk
    ):
        """Test updating risk mitigation and impact."""
        # Arrange
        update_data = {
            "mitigation": "New mitigation strategy",
            "impact": "Reduced impact",
            "probability": 0.3
        }

        # Act
        response = await authenticated_org_client.patch(
            f"/api/v1/risks/{test_risk.id}",
            json=update_data
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["mitigation"] == "New mitigation strategy"
        assert data["impact"] == "Reduced impact"
        assert data["probability"] == 0.3

    @pytest.mark.asyncio
    async def test_update_risk_assignment(
        self,
        authenticated_org_client: AsyncClient,
        test_risk: Risk
    ):
        """Test assigning risk to user."""
        # Arrange
        update_data = {
            "assigned_to": "Jane Doe",
            "assigned_to_email": "jane@example.com"
        }

        # Act
        response = await authenticated_org_client.patch(
            f"/api/v1/risks/{test_risk.id}",
            json=update_data
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["assigned_to"] == "Jane Doe"
        assert data["assigned_to_email"] == "jane@example.com"

    @pytest.mark.asyncio
    async def test_update_nonexistent_risk(
        self,
        authenticated_org_client: AsyncClient
    ):
        """Test updating non-existent risk returns 404."""
        # Arrange
        fake_risk_id = "00000000-0000-0000-0000-000000000000"
        update_data = {"title": "Won't work"}

        # Act
        response = await authenticated_org_client.patch(
            f"/api/v1/risks/{fake_risk_id}",
            json=update_data
        )

        # Assert
        assert response.status_code == 404

    @pytest.mark.asyncio
    async def test_update_risk_without_auth_fails(
        self,
        client: AsyncClient,
        test_risk: Risk
    ):
        """Test that updating risk without authentication fails."""
        # Arrange
        update_data = {"title": "Unauthorized update"}

        # Act
        response = await client.patch(
            f"/api/v1/risks/{test_risk.id}",
            json=update_data
        )

        # Assert - EXPOSES BUG: Should return 401/403 but will succeed
        assert response.status_code in [401, 403]


class TestDeleteRisk:
    """Test risk deletion endpoint."""

    @pytest.mark.asyncio
    async def test_delete_risk_success(
        self,
        authenticated_org_client: AsyncClient,
        test_risk: Risk,
        db_session: AsyncSession
    ):
        """Test successful risk deletion."""
        # Act
        response = await authenticated_org_client.delete(
            f"/api/v1/risks/{test_risk.id}"
        )

        # Assert
        assert response.status_code == 200
        assert response.json()["message"] == "Risk deleted successfully"

        # Verify risk is actually deleted
        result = await db_session.get(Risk, test_risk.id)
        assert result is None

    @pytest.mark.asyncio
    async def test_delete_nonexistent_risk(
        self,
        authenticated_org_client: AsyncClient
    ):
        """Test deleting non-existent risk returns 404."""
        # Arrange
        fake_risk_id = "00000000-0000-0000-0000-000000000000"

        # Act
        response = await authenticated_org_client.delete(
            f"/api/v1/risks/{fake_risk_id}"
        )

        # Assert
        assert response.status_code == 404

    @pytest.mark.asyncio
    async def test_delete_risk_without_auth_fails(
        self,
        client: AsyncClient,
        test_risk: Risk
    ):
        """Test that deleting risk without authentication fails."""
        # Act
        response = await client.delete(
            f"/api/v1/risks/{test_risk.id}"
        )

        # Assert - EXPOSES BUG: Should return 401/403 but will succeed
        assert response.status_code in [401, 403]


class TestBulkUpdateRisks:
    """Test bulk risk update endpoint."""

    @pytest.mark.asyncio
    async def test_bulk_create_risks(
        self,
        authenticated_org_client: AsyncClient,
        test_project: Project
    ):
        """Test bulk creating multiple new risks."""
        # Arrange
        risks_data = [
            {
                "title": "Risk 1",
                "description": "First bulk risk",
                "severity": "high",
                "status": "identified",
                "ai_confidence": 0.9
            },
            {
                "title": "Risk 2",
                "description": "Second bulk risk",
                "severity": "medium",
                "status": "identified",
                "ai_confidence": 0.8
            }
        ]

        # Act
        response = await authenticated_org_client.post(
            f"/api/v1/projects/{test_project.id}/risks/bulk-update",
            json=risks_data
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert len(data) == 2
        assert data[0]["title"] == "Risk 1"
        assert data[1]["title"] == "Risk 2"
        assert all(r["ai_generated"] is True for r in data)

    @pytest.mark.asyncio
    async def test_bulk_update_existing_risks(
        self,
        authenticated_org_client: AsyncClient,
        test_project: Project,
        db_session: AsyncSession
    ):
        """Test bulk updating existing risks by title."""
        # Arrange - Create existing risk
        existing_risk = Risk(
            project_id=test_project.id,
            title="Existing Risk",
            description="Old description",
            severity=RiskSeverity.LOW,
            status=RiskStatus.IDENTIFIED,
            updated_by="manual"
        )
        db_session.add(existing_risk)
        await db_session.commit()

        # Update with same title
        risks_data = [
            {
                "title": "Existing Risk",
                "description": "Updated description",
                "severity": "critical",
                "status": "mitigating"
            }
        ]

        # Act
        response = await authenticated_org_client.post(
            f"/api/v1/projects/{test_project.id}/risks/bulk-update",
            json=risks_data
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert len(data) == 1
        assert data[0]["title"] == "Existing Risk"
        assert data[0]["description"] == "Updated description"
        assert data[0]["severity"] == "critical"
        assert data[0]["updated_by"] == "ai"

    @pytest.mark.asyncio
    async def test_bulk_update_mixed_create_and_update(
        self,
        authenticated_org_client: AsyncClient,
        test_project: Project,
        db_session: AsyncSession
    ):
        """Test bulk operation with both new and existing risks."""
        # Arrange - Create one existing risk
        existing_risk = Risk(
            project_id=test_project.id,
            title="Update Me",
            description="Old",
            severity=RiskSeverity.LOW,
            status=RiskStatus.IDENTIFIED,
            updated_by="manual"
        )
        db_session.add(existing_risk)
        await db_session.commit()

        risks_data = [
            {
                "title": "Update Me",
                "description": "Updated",
                "severity": "high"
            },
            {
                "title": "New Risk",
                "description": "Brand new",
                "severity": "medium"
            }
        ]

        # Act
        response = await authenticated_org_client.post(
            f"/api/v1/projects/{test_project.id}/risks/bulk-update",
            json=risks_data
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert len(data) == 2
        # Find the updated and created risks
        updated = next(r for r in data if r["title"] == "Update Me")
        created = next(r for r in data if r["title"] == "New Risk")
        assert updated["description"] == "Updated"
        assert created["description"] == "Brand new"

    @pytest.mark.asyncio
    async def test_bulk_update_invalid_project(
        self,
        authenticated_org_client: AsyncClient
    ):
        """Test bulk update for non-existent project returns 404."""
        # Arrange
        fake_project_id = "00000000-0000-0000-0000-000000000000"
        risks_data = [{"title": "Test", "description": "Fail"}]

        # Act
        response = await authenticated_org_client.post(
            f"/api/v1/projects/{fake_project_id}/risks/bulk-update",
            json=risks_data
        )

        # Assert
        assert response.status_code == 404

    @pytest.mark.asyncio
    async def test_bulk_update_without_auth_fails(
        self,
        client: AsyncClient,
        test_project: Project
    ):
        """Test that bulk update without authentication fails."""
        # Arrange
        risks_data = [{"title": "Unauthorized", "description": "Should fail"}]

        # Act
        response = await client.post(
            f"/api/v1/projects/{test_project.id}/risks/bulk-update",
            json=risks_data
        )

        # Assert - EXPOSES BUG: Should return 401/403 but will succeed
        assert response.status_code in [401, 403]


class TestMultiTenantIsolation:
    """Test multi-tenant isolation for risks."""

    @pytest.mark.asyncio
    async def test_cannot_create_risk_for_other_org_project(
        self,
        client_factory,
        db_session: AsyncSession,
        test_user: User
    ):
        """Test that users cannot create risks for projects in other organizations."""
        # Arrange - Create two organizations
        org1 = Organization(name="Org 1", slug="org-1", created_by=test_user.id)
        org2 = Organization(name="Org 2", slug="org-2", created_by=test_user.id)
        db_session.add_all([org1, org2])
        await db_session.commit()

        # Add user to org1
        member1 = OrganizationMember(
            organization_id=org1.id,
            user_id=test_user.id,
            role="admin",
            invited_by=test_user.id,
            joined_at=datetime.utcnow()
        )
        db_session.add(member1)
        await db_session.commit()

        # Create project in org2
        project_org2 = Project(
            name="Org 2 Project",
            organization_id=org2.id,
            status="active"
        )
        db_session.add(project_org2)
        await db_session.commit()
        await db_session.refresh(project_org2)

        # Create client authenticated for org1
        from services.auth.native_auth_service import native_auth_service
        token = native_auth_service.create_access_token(
            user_id=str(test_user.id),
            email=test_user.email,
            organization_id=str(org1.id)
        )
        org1_client = await client_factory(
            Authorization=f"Bearer {token}",
            **{"X-Organization-Id": str(org1.id)}
        )

        # Act - Try to create risk for org2's project
        risk_data = {
            "title": "Cross-org Risk",
            "description": "Should not be created"
        }
        response = await org1_client.post(
            f"/api/v1/projects/{project_org2.id}/risks",
            json=risk_data
        )

        # Assert - EXPOSES BUG: Should return 404 (or 403) but will succeed
        # This test will FAIL because endpoint lacks multi-tenant validation
        assert response.status_code == 404

    @pytest.mark.asyncio
    async def test_cannot_list_risks_from_other_org(
        self,
        client_factory,
        db_session: AsyncSession,
        test_user: User
    ):
        """Test that users cannot list risks from other organizations."""
        # Arrange - Create two organizations with projects
        org1 = Organization(name="Org 1", slug="org-1", created_by=test_user.id)
        org2 = Organization(name="Org 2", slug="org-2", created_by=test_user.id)
        db_session.add_all([org1, org2])
        await db_session.commit()

        # Add user to org1 only
        member1 = OrganizationMember(
            organization_id=org1.id,
            user_id=test_user.id,
            role="admin",
            invited_by=test_user.id,
            joined_at=datetime.utcnow()
        )
        db_session.add(member1)
        await db_session.commit()

        # Create project in org2 with risk
        project_org2 = Project(
            name="Org 2 Project",
            organization_id=org2.id,
            status="active"
        )
        db_session.add(project_org2)
        await db_session.commit()
        await db_session.refresh(project_org2)

        risk = Risk(
            project_id=project_org2.id,
            title="Org 2 Risk",
            description="Should not be visible",
            severity=RiskSeverity.HIGH,
            status=RiskStatus.IDENTIFIED,
            updated_by="manual"
        )
        db_session.add(risk)
        await db_session.commit()

        # Create client authenticated for org1
        from services.auth.native_auth_service import native_auth_service
        token = native_auth_service.create_access_token(
            user_id=str(test_user.id),
            email=test_user.email,
            organization_id=str(org1.id)
        )
        org1_client = await client_factory(
            Authorization=f"Bearer {token}",
            **{"X-Organization-Id": str(org1.id)}
        )

        # Act - Try to list risks from org2's project
        response = await org1_client.get(
            f"/api/v1/projects/{project_org2.id}/risks"
        )

        # Assert - Should return 404 (project not found in user's org)
        assert response.status_code == 404
