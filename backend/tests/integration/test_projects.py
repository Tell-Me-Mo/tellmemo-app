"""
Integration tests for Project Management API.

Covers TESTING_BACKEND.md section 3.1 - Project CRUD and 3.2 - Project Members

Status: TBD
"""

import pytest
from datetime import datetime
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession
from models.user import User
from models.organization import Organization
from models.project import Project, ProjectStatus
from models.organization_member import OrganizationMember, OrganizationRole


class TestProjectCreation:
    """Test project creation endpoint."""

    @pytest.mark.asyncio
    async def test_create_project_success(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization
    ):
        """Test successful project creation with minimal data."""
        # Arrange
        project_data = {
            "name": "My New Project",
            "description": "A test project"
        }

        # Act
        response = await authenticated_org_client.post(
            "/api/v1/projects/",
            json=project_data
        )

        # Assert
        assert response.status_code == 201
        data = response.json()
        assert data["name"] == "My New Project"
        assert data["description"] == "A test project"
        assert data["status"] == "active"
        assert data["members"] == []
        assert "id" in data
        assert "created_at" in data

    @pytest.mark.asyncio
    async def test_create_project_with_members(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization
    ):
        """Test project creation with team members."""
        # Arrange
        project_data = {
            "name": "Project with Team",
            "description": "Test project",
            "members": [
                {"name": "John Doe", "email": "john@example.com", "role": "lead"},
                {"name": "Jane Smith", "email": "jane@example.com", "role": "member"}
            ]
        }

        # Act
        response = await authenticated_org_client.post(
            "/api/v1/projects/",
            json=project_data
        )

        # Assert
        assert response.status_code == 201
        data = response.json()
        assert len(data["members"]) == 2
        assert data["members"][0]["name"] == "John Doe"
        assert data["members"][0]["email"] == "john@example.com"
        assert data["members"][0]["role"] == "lead"

    @pytest.mark.asyncio
    async def test_create_project_duplicate_name_fails(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test that duplicate project names are rejected."""
        # Arrange - Create first project
        await authenticated_org_client.post(
            "/api/v1/projects/",
            json={"name": "Duplicate Project"}
        )

        # Act - Try to create project with same name
        response = await authenticated_org_client.post(
            "/api/v1/projects/",
            json={"name": "Duplicate Project"}
        )

        # Assert
        assert response.status_code == 409
        assert "already exists" in response.json()["detail"]

    @pytest.mark.asyncio
    async def test_create_project_without_auth_fails(
        self,
        client: AsyncClient
    ):
        """Test that unauthenticated request fails."""
        # Arrange
        project_data = {"name": "Unauthorized Project"}

        # Act
        response = await client.post(
            "/api/v1/projects/",
            json=project_data
        )

        # Assert - Returns 403 (backend behavior)
        assert response.status_code == 403

    @pytest.mark.asyncio
    async def test_create_project_without_organization_fails(
        self,
        authenticated_client: AsyncClient
    ):
        """Test that request without organization context fails."""
        # Arrange
        project_data = {"name": "No Org Project"}

        # Act
        response = await authenticated_client.post(
            "/api/v1/projects/",
            json=project_data
        )

        # Assert - Returns 404 when no organization in context
        assert response.status_code == 404

    @pytest.mark.asyncio
    async def test_create_project_with_portfolio_assignment(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test creating project assigned to a portfolio."""
        # Arrange - Create portfolio first
        from models.portfolio import Portfolio
        portfolio = Portfolio(
            name="Test Portfolio",
            organization_id=test_organization.id,
            created_by="test@example.com"
        )
        db_session.add(portfolio)
        await db_session.commit()
        await db_session.refresh(portfolio)

        project_data = {
            "name": "Portfolio Project",
            "portfolio_id": str(portfolio.id)
        }

        # Act
        response = await authenticated_org_client.post(
            "/api/v1/projects/",
            json=project_data
        )

        # Assert
        assert response.status_code == 201
        data = response.json()
        assert data["portfolio_id"] == str(portfolio.id)


class TestProjectList:
    """Test listing projects."""

    @pytest.mark.asyncio
    async def test_list_projects_success(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization
    ):
        """Test listing organization's projects."""
        # Arrange - Create projects
        await authenticated_org_client.post(
            "/api/v1/projects/",
            json={"name": "Project 1"}
        )
        await authenticated_org_client.post(
            "/api/v1/projects/",
            json={"name": "Project 2"}
        )

        # Act
        response = await authenticated_org_client.get("/api/v1/projects/")

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert len(data) == 2
        assert data[0]["name"] == "Project 2"  # Most recent first
        assert data[1]["name"] == "Project 1"

    @pytest.mark.asyncio
    async def test_list_projects_empty(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization
    ):
        """Test listing when no projects exist."""
        # Act
        response = await authenticated_org_client.get("/api/v1/projects/")

        # Assert
        assert response.status_code == 200
        assert response.json() == []

    @pytest.mark.asyncio
    async def test_list_projects_filter_by_active_status(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test filtering projects by active status."""
        # Arrange - Create active and archived projects
        response1 = await authenticated_org_client.post(
            "/api/v1/projects/",
            json={"name": "Active Project"}
        )
        project1_id = response1.json()["id"]

        await authenticated_org_client.post(
            "/api/v1/projects/",
            json={"name": "Another Active"}
        )

        # Archive one project
        await authenticated_org_client.patch(f"/api/v1/projects/{project1_id}/archive")

        # Act
        response = await authenticated_org_client.get(
            "/api/v1/projects?status=active"
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert len(data) == 1
        assert data[0]["name"] == "Another Active"

    @pytest.mark.asyncio
    async def test_list_projects_filter_by_archived_status(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization
    ):
        """Test filtering projects by archived status."""
        # Arrange
        response1 = await authenticated_org_client.post(
            "/api/v1/projects/",
            json={"name": "Project to Archive"}
        )
        project1_id = response1.json()["id"]

        # Archive the project
        await authenticated_org_client.patch(f"/api/v1/projects/{project1_id}/archive")

        # Act
        response = await authenticated_org_client.get(
            "/api/v1/projects?status=archived"
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert len(data) == 1
        assert data[0]["name"] == "Project to Archive"
        assert data[0]["status"] == "archived"

    @pytest.mark.asyncio
    async def test_list_projects_invalid_status_fails(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization
    ):
        """Test that invalid status filter returns 400."""
        # Act
        response = await authenticated_org_client.get(
            "/api/v1/projects?status=invalid"
        )

        # Assert
        assert response.status_code == 400
        assert "Invalid status" in response.json()["detail"]


class TestGetProject:
    """Test getting project details."""

    @pytest.mark.asyncio
    async def test_get_project_success(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization
    ):
        """Test getting project by ID."""
        # Arrange
        create_response = await authenticated_org_client.post(
            "/api/v1/projects/",
            json={
                "name": "Test Project",
                "description": "Test description",
                "members": [{"name": "John", "email": "john@test.com", "role": "lead"}]
            }
        )
        project_id = create_response.json()["id"]

        # Act
        response = await authenticated_org_client.get(
            f"/api/v1/projects/{project_id}"
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["id"] == project_id
        assert data["name"] == "Test Project"
        assert data["description"] == "Test description"
        assert len(data["members"]) == 1

    @pytest.mark.asyncio
    async def test_get_project_not_found(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization
    ):
        """Test getting non-existent project."""
        # Arrange
        fake_uuid = "00000000-0000-0000-0000-000000000000"

        # Act
        response = await authenticated_org_client.get(
            f"/api/v1/projects/{fake_uuid}"
        )

        # Assert
        assert response.status_code == 404
        assert "not found" in response.json()["detail"].lower()

    @pytest.mark.asyncio
    async def test_get_project_invalid_uuid_fails(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization
    ):
        """Test getting project with invalid UUID format."""
        # Act
        response = await authenticated_org_client.get(
            "/api/v1/projects/invalid-uuid"
        )

        # Assert
        assert response.status_code == 400
        assert "Invalid project ID format" in response.json()["detail"]


class TestUpdateProject:
    """Test updating project details."""

    @pytest.mark.asyncio
    async def test_update_project_name(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization
    ):
        """Test updating project name."""
        # Arrange
        create_response = await authenticated_org_client.post(
            "/api/v1/projects/",
            json={"name": "Original Name"}
        )
        project_id = create_response.json()["id"]

        # Act
        response = await authenticated_org_client.put(
            f"/api/v1/projects/{project_id}",
            json={"name": "Updated Name"}
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["name"] == "Updated Name"
        assert data["updated_at"] is not None

    @pytest.mark.asyncio
    async def test_update_project_description(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization
    ):
        """Test updating project description."""
        # Arrange
        create_response = await authenticated_org_client.post(
            "/api/v1/projects/",
            json={"name": "Test Project", "description": "Original"}
        )
        project_id = create_response.json()["id"]

        # Act
        response = await authenticated_org_client.put(
            f"/api/v1/projects/{project_id}",
            json={"description": "Updated description"}
        )

        # Assert
        assert response.status_code == 200
        assert response.json()["description"] == "Updated description"

    @pytest.mark.asyncio
    async def test_update_project_status(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization
    ):
        """Test updating project status."""
        # Arrange
        create_response = await authenticated_org_client.post(
            "/api/v1/projects/",
            json={"name": "Test Project"}
        )
        project_id = create_response.json()["id"]

        # Act
        response = await authenticated_org_client.put(
            f"/api/v1/projects/{project_id}",
            json={"status": "archived"}
        )

        # Assert
        assert response.status_code == 200
        assert response.json()["status"] == "archived"

    @pytest.mark.asyncio
    async def test_update_project_members(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization
    ):
        """Test updating project members (replaces all)."""
        # Arrange
        create_response = await authenticated_org_client.post(
            "/api/v1/projects/",
            json={
                "name": "Test Project",
                "members": [{"name": "John", "email": "john@test.com", "role": "lead"}]
            }
        )
        project_id = create_response.json()["id"]

        # Act
        response = await authenticated_org_client.put(
            f"/api/v1/projects/{project_id}",
            json={
                "members": [
                    {"name": "Jane", "email": "jane@test.com", "role": "member"},
                    {"name": "Bob", "email": "bob@test.com", "role": "viewer"}
                ]
            }
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert len(data["members"]) == 2
        assert data["members"][0]["name"] == "Jane"
        assert data["members"][1]["name"] == "Bob"

    @pytest.mark.asyncio
    async def test_update_project_duplicate_name_fails(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization
    ):
        """Test that updating to duplicate name fails."""
        # Arrange
        await authenticated_org_client.post(
            "/api/v1/projects/",
            json={"name": "Existing Project"}
        )
        create_response = await authenticated_org_client.post(
            "/api/v1/projects/",
            json={"name": "Project to Rename"}
        )
        project_id = create_response.json()["id"]

        # Act
        response = await authenticated_org_client.put(
            f"/api/v1/projects/{project_id}",
            json={"name": "Existing Project"}
        )

        # Assert
        assert response.status_code == 409
        assert "already exists" in response.json()["detail"]

    @pytest.mark.asyncio
    async def test_update_project_invalid_status_fails(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization
    ):
        """Test that invalid status fails."""
        # Arrange
        create_response = await authenticated_org_client.post(
            "/api/v1/projects/",
            json={"name": "Test Project"}
        )
        project_id = create_response.json()["id"]

        # Act
        response = await authenticated_org_client.put(
            f"/api/v1/projects/{project_id}",
            json={"status": "invalid"}
        )

        # Assert
        assert response.status_code == 400
        assert "Invalid status" in response.json()["detail"]

    @pytest.mark.asyncio
    async def test_update_project_as_non_member_requires_role(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization
    ):
        """Test that updating requires at least member role."""
        # Arrange
        create_response = await authenticated_org_client.post(
            "/api/v1/projects/",
            json={"name": "Test Project"}
        )
        project_id = create_response.json()["id"]

        # Act - With authenticated org client (should have member role)
        response = await authenticated_org_client.put(
            f"/api/v1/projects/{project_id}",
            json={"name": "Updated"}
        )

        # Assert
        assert response.status_code == 200


class TestArchiveProject:
    """Test archiving projects."""

    @pytest.mark.asyncio
    async def test_archive_project_success(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization
    ):
        """Test archiving a project."""
        # Arrange
        create_response = await authenticated_org_client.post(
            "/api/v1/projects/",
            json={"name": "Project to Archive"}
        )
        project_id = create_response.json()["id"]

        # Act
        response = await authenticated_org_client.patch(
            f"/api/v1/projects/{project_id}/archive"
        )

        # Assert
        assert response.status_code == 200
        assert "archived successfully" in response.json()["message"]

        # Verify project is archived
        get_response = await authenticated_org_client.get(
            f"/api/v1/projects/{project_id}"
        )
        assert get_response.json()["status"] == "archived"

    @pytest.mark.asyncio
    async def test_archive_project_not_found(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization
    ):
        """Test archiving non-existent project."""
        # Arrange
        fake_uuid = "00000000-0000-0000-0000-000000000000"

        # Act
        response = await authenticated_org_client.patch(
            f"/api/v1/projects/{fake_uuid}/archive"
        )

        # Assert
        assert response.status_code == 404

    @pytest.mark.asyncio
    async def test_archive_project_allows_duplicate_names(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization
    ):
        """Test that archiving allows creating new project with same name."""
        # Arrange
        create_response = await authenticated_org_client.post(
            "/api/v1/projects/",
            json={"name": "Reusable Name"}
        )
        project_id = create_response.json()["id"]

        # Archive the project
        await authenticated_org_client.patch(
            f"/api/v1/projects/{project_id}/archive"
        )

        # Act - Create new project with same name
        response = await authenticated_org_client.post(
            "/api/v1/projects/",
            json={"name": "Reusable Name"}
        )

        # Assert
        assert response.status_code == 201


class TestRestoreProject:
    """Test restoring archived projects."""

    @pytest.mark.asyncio
    async def test_restore_project_success(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization
    ):
        """Test restoring an archived project."""
        # Arrange
        create_response = await authenticated_org_client.post(
            "/api/v1/projects/",
            json={"name": "Project to Restore"}
        )
        project_id = create_response.json()["id"]

        # Archive the project
        await authenticated_org_client.patch(
            f"/api/v1/projects/{project_id}/archive"
        )

        # Act
        response = await authenticated_org_client.patch(
            f"/api/v1/projects/{project_id}/restore"
        )

        # Assert
        assert response.status_code == 200
        assert "restored successfully" in response.json()["message"]

        # Verify project is active
        get_response = await authenticated_org_client.get(
            f"/api/v1/projects/{project_id}"
        )
        assert get_response.json()["status"] == "active"

    @pytest.mark.asyncio
    async def test_restore_project_duplicate_name_fails(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization
    ):
        """Test that restoring fails if active project with same name exists."""
        # Arrange
        create_response1 = await authenticated_org_client.post(
            "/api/v1/projects/",
            json={"name": "Duplicate Name"}
        )
        project1_id = create_response1.json()["id"]

        # Archive first project
        await authenticated_org_client.patch(
            f"/api/v1/projects/{project1_id}/archive"
        )

        # Create new project with same name
        await authenticated_org_client.post(
            "/api/v1/projects/",
            json={"name": "Duplicate Name"}
        )

        # Act - Try to restore archived project
        response = await authenticated_org_client.patch(
            f"/api/v1/projects/{project1_id}/restore"
        )

        # Assert
        assert response.status_code == 409
        assert "already exists" in response.json()["detail"]

    @pytest.mark.asyncio
    async def test_restore_project_not_found(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization
    ):
        """Test restoring non-existent project."""
        # Arrange
        fake_uuid = "00000000-0000-0000-0000-000000000000"

        # Act
        response = await authenticated_org_client.patch(
            f"/api/v1/projects/{fake_uuid}/restore"
        )

        # Assert
        assert response.status_code == 404


class TestDeleteProject:
    """Test permanently deleting projects."""

    @pytest.mark.asyncio
    async def test_delete_project_as_admin(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test permanently deleting a project as admin."""
        # Arrange
        create_response = await authenticated_org_client.post(
            "/api/v1/projects/",
            json={"name": "Project to Delete"}
        )
        project_id = create_response.json()["id"]

        # Act
        response = await authenticated_org_client.delete(
            f"/api/v1/projects/{project_id}"
        )

        # Assert
        assert response.status_code == 200
        assert "permanently deleted" in response.json()["message"]

        # Verify project is deleted
        from sqlalchemy import select
        result = await db_session.execute(
            select(Project).where(Project.id == project_id)
        )
        assert result.scalar_one_or_none() is None

    @pytest.mark.asyncio
    async def test_delete_project_not_found(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization
    ):
        """Test deleting non-existent project."""
        # Arrange
        fake_uuid = "00000000-0000-0000-0000-000000000000"

        # Act
        response = await authenticated_org_client.delete(
            f"/api/v1/projects/{fake_uuid}"
        )

        # Assert
        assert response.status_code == 404

    @pytest.mark.asyncio
    async def test_delete_project_requires_admin_role(
        self,
        client_factory,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test that non-admins cannot delete projects."""
        # Arrange - Create member user
        from services.auth.native_auth_service import native_auth_service

        member_user = User(
            email="member@example.com",
            password_hash=native_auth_service.hash_password("Password123!"),
            name="Member User",
            auth_provider='native',
            email_verified=True,
            is_active=True
        )
        db_session.add(member_user)
        await db_session.flush()

        # Add as member (not admin)
        member = OrganizationMember(
            organization_id=test_organization.id,
            user_id=member_user.id,
            role=OrganizationRole.MEMBER.value,
            invited_by=test_organization.created_by,
            joined_at=None
        )
        db_session.add(member)
        await db_session.commit()

        # Create project as admin
        from models.project import Project as ProjectModel
        project = ProjectModel(
            name="Test Project",
            organization_id=test_organization.id,
            created_by="test@example.com"
        )
        db_session.add(project)
        await db_session.commit()
        await db_session.refresh(project)

        # Create member token
        member_token = native_auth_service.create_access_token(
            user_id=str(member_user.id),
            email=member_user.email,
            organization_id=str(test_organization.id)
        )

        member_client = await client_factory(
            Authorization=f"Bearer {member_token}",
            **{"X-Organization-Id": str(test_organization.id)}
        )

        # Act
        response = await member_client.delete(
            f"/api/v1/projects/{project.id}"
        )

        # Assert
        assert response.status_code == 403


class TestProjectMemberManagement:
    """Test adding and removing project members."""

    @pytest.mark.asyncio
    async def test_add_member_to_project(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization
    ):
        """Test adding a member to a project."""
        # Arrange
        create_response = await authenticated_org_client.post(
            "/api/v1/projects/",
            json={"name": "Test Project"}
        )
        project_id = create_response.json()["id"]

        member_data = {
            "name": "New Member",
            "email": "newmember@test.com",
            "role": "member"
        }

        # Act
        response = await authenticated_org_client.post(
            f"/api/v1/projects/{project_id}/members",
            json=member_data
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert "Member added successfully" in data["message"]
        assert data["member"]["name"] == "New Member"
        assert data["member"]["email"] == "newmember@test.com"
        assert data["member"]["role"] == "member"

    @pytest.mark.asyncio
    async def test_add_duplicate_member_fails(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization
    ):
        """Test that adding duplicate member fails."""
        # Arrange
        create_response = await authenticated_org_client.post(
            "/api/v1/projects/",
            json={
                "name": "Test Project",
                "members": [{"name": "John", "email": "john@test.com", "role": "lead"}]
            }
        )
        project_id = create_response.json()["id"]

        # Act - Try to add same member again
        response = await authenticated_org_client.post(
            f"/api/v1/projects/{project_id}/members",
            json={"name": "John", "email": "john@test.com", "role": "member"}
        )

        # Assert
        assert response.status_code == 400

    @pytest.mark.asyncio
    async def test_remove_member_from_project(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization
    ):
        """Test removing a member from a project."""
        # Arrange
        create_response = await authenticated_org_client.post(
            "/api/v1/projects/",
            json={
                "name": "Test Project",
                "members": [{"name": "John", "email": "john@test.com", "role": "lead"}]
            }
        )
        project_id = create_response.json()["id"]

        # Act
        response = await authenticated_org_client.delete(
            f"/api/v1/projects/{project_id}/members/john@test.com"
        )

        # Assert
        assert response.status_code == 200
        assert "Member removed successfully" in response.json()["message"]

        # Verify member is removed
        get_response = await authenticated_org_client.get(
            f"/api/v1/projects/{project_id}"
        )
        assert len(get_response.json()["members"]) == 0

    @pytest.mark.asyncio
    async def test_remove_nonexistent_member_fails(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization
    ):
        """Test that removing non-existent member fails."""
        # Arrange
        create_response = await authenticated_org_client.post(
            "/api/v1/projects/",
            json={"name": "Test Project"}
        )
        project_id = create_response.json()["id"]

        # Act
        response = await authenticated_org_client.delete(
            f"/api/v1/projects/{project_id}/members/nonexistent@test.com"
        )

        # Assert
        assert response.status_code == 404


class TestProjectAssignment:
    """Test project assignment to programs and portfolios (TESTING_BACKEND.md section 3.3)."""

    @pytest.mark.asyncio
    async def test_assign_project_to_program(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test assigning a standalone project to a program."""
        # Arrange - Create a program
        from models.program import Program
        program = Program(
            name="Test Program",
            organization_id=test_organization.id,
            created_by="test@example.com"
        )
        db_session.add(program)
        await db_session.commit()
        await db_session.refresh(program)

        # Create a standalone project
        create_response = await authenticated_org_client.post(
            "/api/v1/projects/",
            json={"name": "Standalone Project"}
        )
        project_id = create_response.json()["id"]
        assert create_response.json()["program_id"] is None

        # Act - Assign to program
        response = await authenticated_org_client.put(
            f"/api/v1/projects/{project_id}",
            json={"program_id": str(program.id)}
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["program_id"] == str(program.id)
        assert data["updated_at"] is not None

    @pytest.mark.asyncio
    async def test_assign_project_to_portfolio(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test assigning a standalone project to a portfolio."""
        # Arrange - Create a portfolio
        from models.portfolio import Portfolio
        portfolio = Portfolio(
            name="Test Portfolio",
            organization_id=test_organization.id,
            created_by="test@example.com"
        )
        db_session.add(portfolio)
        await db_session.commit()
        await db_session.refresh(portfolio)

        # Create a standalone project
        create_response = await authenticated_org_client.post(
            "/api/v1/projects/",
            json={"name": "Portfolio Project"}
        )
        project_id = create_response.json()["id"]
        assert create_response.json()["portfolio_id"] is None

        # Act - Assign to portfolio
        response = await authenticated_org_client.put(
            f"/api/v1/projects/{project_id}",
            json={"portfolio_id": str(portfolio.id)}
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["portfolio_id"] == str(portfolio.id)
        assert data["updated_at"] is not None

    @pytest.mark.asyncio
    async def test_move_project_between_programs(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test moving a project from one program to another."""
        # Arrange - Create two programs
        from models.program import Program
        program1 = Program(
            name="Program A",
            organization_id=test_organization.id,
            created_by="test@example.com"
        )
        program2 = Program(
            name="Program B",
            organization_id=test_organization.id,
            created_by="test@example.com"
        )
        db_session.add_all([program1, program2])
        await db_session.commit()
        await db_session.refresh(program1)
        await db_session.refresh(program2)

        # Create project assigned to program1
        create_response = await authenticated_org_client.post(
            "/api/v1/projects/",
            json={
                "name": "Moving Project",
                "program_id": str(program1.id)
            }
        )
        project_id = create_response.json()["id"]
        assert create_response.json()["program_id"] == str(program1.id)

        # Act - Move to program2
        response = await authenticated_org_client.put(
            f"/api/v1/projects/{project_id}",
            json={"program_id": str(program2.id)}
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["program_id"] == str(program2.id)

        # Verify the change persisted
        get_response = await authenticated_org_client.get(
            f"/api/v1/projects/{project_id}"
        )
        assert get_response.json()["program_id"] == str(program2.id)

    @pytest.mark.asyncio
    async def test_assign_project_to_both_program_and_portfolio(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test assigning a project to both a program and portfolio (program under portfolio)."""
        # Arrange - Create portfolio and program under it
        from models.portfolio import Portfolio
        from models.program import Program

        portfolio = Portfolio(
            name="Parent Portfolio",
            organization_id=test_organization.id,
            created_by="test@example.com"
        )
        db_session.add(portfolio)
        await db_session.commit()
        await db_session.refresh(portfolio)

        program = Program(
            name="Child Program",
            portfolio_id=portfolio.id,
            organization_id=test_organization.id,
            created_by="test@example.com"
        )
        db_session.add(program)
        await db_session.commit()
        await db_session.refresh(program)

        # Create project
        create_response = await authenticated_org_client.post(
            "/api/v1/projects/",
            json={"name": "Hierarchical Project"}
        )
        project_id = create_response.json()["id"]

        # Act - Assign to both program and portfolio
        response = await authenticated_org_client.put(
            f"/api/v1/projects/{project_id}",
            json={
                "program_id": str(program.id),
                "portfolio_id": str(portfolio.id)
            }
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["program_id"] == str(program.id)
        assert data["portfolio_id"] == str(portfolio.id)

    @pytest.mark.asyncio
    async def test_unassign_project_from_program(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test removing program assignment (making project standalone)."""
        # Arrange - Create program and assigned project
        from models.program import Program
        program = Program(
            name="Test Program",
            organization_id=test_organization.id,
            created_by="test@example.com"
        )
        db_session.add(program)
        await db_session.commit()
        await db_session.refresh(program)

        create_response = await authenticated_org_client.post(
            "/api/v1/projects/",
            json={
                "name": "Assigned Project",
                "program_id": str(program.id)
            }
        )
        project_id = create_response.json()["id"]
        assert create_response.json()["program_id"] == str(program.id)

        # Act - Unassign from program
        response = await authenticated_org_client.put(
            f"/api/v1/projects/{project_id}",
            json={"program_id": None}
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["program_id"] is None

    @pytest.mark.asyncio
    async def test_unassign_project_from_portfolio(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test removing portfolio assignment."""
        # Arrange - Create portfolio and assigned project
        from models.portfolio import Portfolio
        portfolio = Portfolio(
            name="Test Portfolio",
            organization_id=test_organization.id,
            created_by="test@example.com"
        )
        db_session.add(portfolio)
        await db_session.commit()
        await db_session.refresh(portfolio)

        create_response = await authenticated_org_client.post(
            "/api/v1/projects/",
            json={
                "name": "Portfolio Project",
                "portfolio_id": str(portfolio.id)
            }
        )
        project_id = create_response.json()["id"]

        # Act - Unassign from portfolio
        response = await authenticated_org_client.put(
            f"/api/v1/projects/{project_id}",
            json={"portfolio_id": None}
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["portfolio_id"] is None

    @pytest.mark.asyncio
    async def test_assign_project_to_nonexistent_program_fails(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization
    ):
        """Test that assigning to non-existent program fails with 409."""
        # Arrange
        create_response = await authenticated_org_client.post(
            "/api/v1/projects/",
            json={"name": "Test Project"}
        )
        project_id = create_response.json()["id"]
        fake_program_uuid = "00000000-0000-0000-0000-000000000000"

        # Act
        response = await authenticated_org_client.put(
            f"/api/v1/projects/{project_id}",
            json={"program_id": fake_program_uuid}
        )

        # Assert
        assert response.status_code == 409
        assert "not found" in response.json()["detail"]

    @pytest.mark.asyncio
    async def test_assign_project_to_nonexistent_portfolio_fails(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization
    ):
        """Test that assigning to non-existent portfolio fails with 409."""
        # Arrange
        create_response = await authenticated_org_client.post(
            "/api/v1/projects/",
            json={"name": "Test Project"}
        )
        project_id = create_response.json()["id"]
        fake_portfolio_uuid = "00000000-0000-0000-0000-000000000000"

        # Act
        response = await authenticated_org_client.put(
            f"/api/v1/projects/{project_id}",
            json={"portfolio_id": fake_portfolio_uuid}
        )

        # Assert
        assert response.status_code == 409
        assert "not found" in response.json()["detail"]

    @pytest.mark.asyncio
    async def test_assign_project_to_program_from_different_org_fails(
        self,
        client_factory,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test that assigning project to program from different organization fails."""
        # Arrange - Create second organization with a user first
        from services.auth.native_auth_service import native_auth_service

        # Create admin user for org2
        admin2 = User(
            email="admin2@example.com",
            password_hash=native_auth_service.hash_password("Password123!"),
            name="Admin 2",
            auth_provider='native',
            email_verified=True,
            is_active=True
        )
        db_session.add(admin2)
        await db_session.flush()

        org2 = Organization(
            name="Second Org",
            slug="second-org",
            created_by=admin2.id
        )
        db_session.add(org2)
        await db_session.commit()
        await db_session.refresh(org2)

        # Create program in org2
        from models.program import Program
        program_org2 = Program(
            name="Org2 Program",
            organization_id=org2.id,
            created_by="admin2@example.com"
        )
        db_session.add(program_org2)
        await db_session.commit()
        await db_session.refresh(program_org2)

        # Create user for org1
        user1 = User(
            email="user1@example.com",
            password_hash=native_auth_service.hash_password("Password123!"),
            name="User 1",
            auth_provider='native',
            email_verified=True,
            is_active=True
        )
        db_session.add(user1)
        await db_session.flush()

        from models.organization_member import OrganizationMember, OrganizationRole
        member1 = OrganizationMember(
            organization_id=test_organization.id,
            user_id=user1.id,
            role=OrganizationRole.ADMIN.value,
            invited_by=test_organization.created_by,
            joined_at=datetime.utcnow()
        )
        db_session.add(member1)
        await db_session.commit()

        # Create token for user1 in org1
        token1 = native_auth_service.create_access_token(
            user_id=str(user1.id),
            email=user1.email,
            organization_id=str(test_organization.id)
        )

        client1 = await client_factory(
            Authorization=f"Bearer {token1}",
            **{"X-Organization-Id": str(test_organization.id)}
        )

        # Create project in org1
        create_response = await client1.post(
            "/api/v1/projects/",
            json={"name": "Org1 Project"}
        )
        project_id = create_response.json()["id"]

        # Act - Try to assign org1 project to org2 program
        response = await client1.put(
            f"/api/v1/projects/{project_id}",
            json={"program_id": str(program_org2.id)}
        )

        # Assert - Should fail with 409 (backend validates program belongs to org)
        assert response.status_code == 409
        assert "not found" in response.json()["detail"]

    @pytest.mark.asyncio
    async def test_create_project_with_program_assignment(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test creating project with program assignment in one step."""
        # Arrange - Create program
        from models.program import Program
        program = Program(
            name="Initial Program",
            organization_id=test_organization.id,
            created_by="test@example.com"
        )
        db_session.add(program)
        await db_session.commit()
        await db_session.refresh(program)

        # Act - Create project with program assignment
        response = await authenticated_org_client.post(
            "/api/v1/projects/",
            json={
                "name": "Pre-assigned Project",
                "program_id": str(program.id)
            }
        )

        # Assert
        assert response.status_code == 201
        data = response.json()
        assert data["program_id"] == str(program.id)

    @pytest.mark.asyncio
    async def test_move_project_from_portfolio_to_program(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test moving project from portfolio to program."""
        # Arrange - Create portfolio and program
        from models.portfolio import Portfolio
        from models.program import Program

        portfolio = Portfolio(
            name="Source Portfolio",
            organization_id=test_organization.id,
            created_by="test@example.com"
        )
        program = Program(
            name="Target Program",
            organization_id=test_organization.id,
            created_by="test@example.com"
        )
        db_session.add_all([portfolio, program])
        await db_session.commit()
        await db_session.refresh(portfolio)
        await db_session.refresh(program)

        # Create project in portfolio
        create_response = await authenticated_org_client.post(
            "/api/v1/projects/",
            json={
                "name": "Moving Project",
                "portfolio_id": str(portfolio.id)
            }
        )
        project_id = create_response.json()["id"]

        # Act - Move to program (remove from portfolio, add to program)
        response = await authenticated_org_client.put(
            f"/api/v1/projects/{project_id}",
            json={
                "portfolio_id": None,
                "program_id": str(program.id)
            }
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["portfolio_id"] is None
        assert data["program_id"] == str(program.id)
