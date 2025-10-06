"""
Integration tests for Hierarchy Operations API.

Covers TESTING_BACKEND.md section 4.3 - Hierarchy Operations (hierarchy.py)

Status: All 7 endpoint categories tested
"""

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession
from models.user import User
from models.organization import Organization
from models.portfolio import Portfolio
from models.program import Program
from models.project import Project, ProjectStatus


class TestGetFullHierarchy:
    """Test GET /api/hierarchy/full - Get full hierarchy tree."""

    @pytest.mark.asyncio
    async def test_get_empty_hierarchy(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization
    ):
        """Test getting hierarchy when organization has no items."""
        # Act
        response = await authenticated_org_client.get("/api/hierarchy/full")

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert "hierarchy" in data
        assert data["hierarchy"] == []
        assert data["include_archived"] is False

    @pytest.mark.asyncio
    async def test_get_hierarchy_with_portfolios_only(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test hierarchy with only portfolios (no programs or projects)."""
        # Arrange - Create portfolios
        portfolio1 = Portfolio(
            name="Portfolio Alpha",
            description="First portfolio",
            organization_id=test_organization.id
        )
        portfolio2 = Portfolio(
            name="Portfolio Beta",
            description="Second portfolio",
            organization_id=test_organization.id
        )
        db_session.add_all([portfolio1, portfolio2])
        await db_session.commit()

        # Act
        response = await authenticated_org_client.get("/api/hierarchy/full")

        # Assert
        assert response.status_code == 200
        data = response.json()
        hierarchy = data["hierarchy"]
        assert len(hierarchy) == 2
        assert hierarchy[0]["name"] == "Portfolio Alpha"
        assert hierarchy[0]["type"] == "portfolio"
        assert hierarchy[0]["children"] == []
        assert hierarchy[1]["name"] == "Portfolio Beta"

    @pytest.mark.asyncio
    async def test_get_hierarchy_with_orphaned_projects(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test hierarchy includes orphaned projects (no portfolio/program)."""
        # Arrange - Create orphaned projects
        project1 = Project(
            name="Orphaned Project",
            description="No parent",
            organization_id=test_organization.id,
            status=ProjectStatus.ACTIVE
        )
        db_session.add(project1)
        await db_session.commit()

        # Act
        response = await authenticated_org_client.get("/api/hierarchy/full")

        # Assert
        assert response.status_code == 200
        data = response.json()
        hierarchy = data["hierarchy"]
        assert len(hierarchy) == 1
        assert hierarchy[0]["id"] == str(project1.id)
        assert hierarchy[0]["type"] == "project"
        assert hierarchy[0]["portfolio_id"] is None
        assert hierarchy[0]["program_id"] is None

    @pytest.mark.asyncio
    async def test_get_hierarchy_with_orphaned_programs(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test hierarchy includes orphaned programs (no portfolio)."""
        # Arrange - Create orphaned program
        program = Program(
            name="Orphaned Program",
            description="No portfolio",
            organization_id=test_organization.id,
            portfolio_id=None
        )
        db_session.add(program)
        await db_session.commit()

        # Act
        response = await authenticated_org_client.get("/api/hierarchy/full")

        # Assert
        assert response.status_code == 200
        data = response.json()
        hierarchy = data["hierarchy"]
        assert len(hierarchy) == 1
        assert hierarchy[0]["id"] == str(program.id)
        assert hierarchy[0]["type"] == "program"
        assert hierarchy[0]["portfolio_id"] is None
        assert hierarchy[0]["children"] == []

    @pytest.mark.asyncio
    async def test_get_complete_hierarchy_tree(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test full hierarchy with portfolios > programs > projects."""
        # Arrange - Create complete hierarchy
        portfolio = Portfolio(
            name="Enterprise Portfolio",
            description="Top level",
            organization_id=test_organization.id
        )
        db_session.add(portfolio)
        await db_session.commit()
        await db_session.refresh(portfolio)

        program = Program(
            name="Innovation Program",
            description="Under portfolio",
            organization_id=test_organization.id,
            portfolio_id=portfolio.id
        )
        db_session.add(program)
        await db_session.commit()
        await db_session.refresh(program)

        project = Project(
            name="AI Initiative",
            description="Under program",
            organization_id=test_organization.id,
            portfolio_id=portfolio.id,
            program_id=program.id,
            status=ProjectStatus.ACTIVE
        )
        db_session.add(project)
        await db_session.commit()

        # Act
        response = await authenticated_org_client.get("/api/hierarchy/full")

        # Assert
        assert response.status_code == 200
        data = response.json()
        hierarchy = data["hierarchy"]
        assert len(hierarchy) == 1

        # Verify portfolio level
        portfolio_data = hierarchy[0]
        assert portfolio_data["name"] == "Enterprise Portfolio"
        assert portfolio_data["type"] == "portfolio"
        assert len(portfolio_data["children"]) == 1

        # Verify program level
        program_data = portfolio_data["children"][0]
        assert program_data["name"] == "Innovation Program"
        assert program_data["type"] == "program"
        assert program_data["portfolio_id"] == str(portfolio.id)
        assert len(program_data["children"]) == 1

        # Verify project level
        project_data = program_data["children"][0]
        assert project_data["name"] == "AI Initiative"
        assert project_data["type"] == "project"
        assert project_data["status"] == "active"

    @pytest.mark.asyncio
    async def test_get_hierarchy_excludes_archived_by_default(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test that archived projects are excluded by default."""
        # Arrange
        active_project = Project(
            name="Active Project",
            description="Active",
            organization_id=test_organization.id,
            status=ProjectStatus.ACTIVE
        )
        archived_project = Project(
            name="Archived Project",
            description="Archived",
            organization_id=test_organization.id,
            status=ProjectStatus.ARCHIVED
        )
        db_session.add_all([active_project, archived_project])
        await db_session.commit()

        # Act
        response = await authenticated_org_client.get("/api/hierarchy/full")

        # Assert
        assert response.status_code == 200
        data = response.json()
        hierarchy = data["hierarchy"]
        assert len(hierarchy) == 1
        assert hierarchy[0]["name"] == "Active Project"

    @pytest.mark.asyncio
    async def test_get_hierarchy_includes_archived_when_requested(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test that archived projects are included when include_archived=true."""
        # Arrange
        active_project = Project(
            name="Active Project",
            description="Active",
            organization_id=test_organization.id,
            status=ProjectStatus.ACTIVE
        )
        archived_project = Project(
            name="Archived Project",
            description="Archived",
            organization_id=test_organization.id,
            status=ProjectStatus.ARCHIVED
        )
        db_session.add_all([active_project, archived_project])
        await db_session.commit()

        # Act
        response = await authenticated_org_client.get(
            "/api/hierarchy/full?include_archived=true"
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        hierarchy = data["hierarchy"]
        assert len(hierarchy) == 2
        project_names = {item["name"] for item in hierarchy}
        assert "Active Project" in project_names
        assert "Archived Project" in project_names

    @pytest.mark.asyncio
    async def test_get_hierarchy_multi_tenant_isolation(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession,
        test_user: User
    ):
        """Test that hierarchy only shows items from current organization."""
        # Arrange - Create another organization
        other_org = Organization(
            name="Other Org",
            slug="other-org",
            created_by=test_user.id
        )
        db_session.add(other_org)
        await db_session.commit()

        # Create project in other org
        other_project = Project(
            name="Other Org Project",
            description="Should not appear",
            organization_id=other_org.id,
            status=ProjectStatus.ACTIVE
        )
        db_session.add(other_project)
        await db_session.commit()

        # Create project in test org
        my_project = Project(
            name="My Project",
            description="Should appear",
            organization_id=test_organization.id,
            status=ProjectStatus.ACTIVE
        )
        db_session.add(my_project)
        await db_session.commit()

        # Act
        response = await authenticated_org_client.get("/api/hierarchy/full")

        # Assert
        assert response.status_code == 200
        data = response.json()
        hierarchy = data["hierarchy"]
        assert len(hierarchy) == 1
        assert hierarchy[0]["name"] == "My Project"


class TestMoveItem:
    """Test POST /api/hierarchy/move - Move items within hierarchy."""

    @pytest.mark.asyncio
    async def test_move_project_to_portfolio(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test moving an orphaned project to a portfolio."""
        # Arrange
        portfolio = Portfolio(
            name="Target Portfolio",
            organization_id=test_organization.id
        )
        db_session.add(portfolio)
        await db_session.commit()
        await db_session.refresh(portfolio)

        project = Project(
            name="Orphaned Project",
            organization_id=test_organization.id,
            status=ProjectStatus.ACTIVE
        )
        db_session.add(project)
        await db_session.commit()
        await db_session.refresh(project)

        # Act
        response = await authenticated_org_client.post(
            "/api/hierarchy/move",
            json={
                "item_id": str(project.id),
                "item_type": "project",
                "target_parent_id": str(portfolio.id),
                "target_parent_type": "portfolio"
            }
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert "Project" in data["message"]
        assert data["item"]["portfolio_id"] == str(portfolio.id)
        assert data["item"]["program_id"] is None

    @pytest.mark.asyncio
    async def test_move_project_to_program(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test moving a project to a program."""
        # Arrange
        portfolio = Portfolio(
            name="Parent Portfolio",
            organization_id=test_organization.id
        )
        db_session.add(portfolio)
        await db_session.commit()
        await db_session.refresh(portfolio)

        program = Program(
            name="Target Program",
            organization_id=test_organization.id,
            portfolio_id=portfolio.id
        )
        db_session.add(program)
        await db_session.commit()
        await db_session.refresh(program)

        project = Project(
            name="Moving Project",
            organization_id=test_organization.id,
            status=ProjectStatus.ACTIVE
        )
        db_session.add(project)
        await db_session.commit()
        await db_session.refresh(project)

        # Act
        response = await authenticated_org_client.post(
            "/api/hierarchy/move",
            json={
                "item_id": str(project.id),
                "item_type": "project",
                "target_parent_id": str(program.id),
                "target_parent_type": "program"
            }
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["item"]["program_id"] == str(program.id)
        # Project should inherit portfolio from program
        assert data["item"]["portfolio_id"] == str(portfolio.id)

    @pytest.mark.asyncio
    async def test_move_project_between_programs(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test moving a project from one program to another."""
        # Arrange
        portfolio = Portfolio(
            name="Portfolio",
            organization_id=test_organization.id
        )
        db_session.add(portfolio)
        await db_session.commit()
        await db_session.refresh(portfolio)

        program1 = Program(
            name="Program 1",
            organization_id=test_organization.id,
            portfolio_id=portfolio.id
        )
        program2 = Program(
            name="Program 2",
            organization_id=test_organization.id,
            portfolio_id=portfolio.id
        )
        db_session.add_all([program1, program2])
        await db_session.commit()
        await db_session.refresh(program1)
        await db_session.refresh(program2)

        project = Project(
            name="Moving Project",
            organization_id=test_organization.id,
            portfolio_id=portfolio.id,
            program_id=program1.id,
            status=ProjectStatus.ACTIVE
        )
        db_session.add(project)
        await db_session.commit()
        await db_session.refresh(project)

        # Act
        response = await authenticated_org_client.post(
            "/api/hierarchy/move",
            json={
                "item_id": str(project.id),
                "item_type": "project",
                "target_parent_id": str(program2.id),
                "target_parent_type": "program"
            }
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["item"]["program_id"] == str(program2.id)

    @pytest.mark.asyncio
    async def test_move_program_between_portfolios(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test moving a program from one portfolio to another."""
        # Arrange
        portfolio1 = Portfolio(
            name="Portfolio 1",
            organization_id=test_organization.id
        )
        portfolio2 = Portfolio(
            name="Portfolio 2",
            organization_id=test_organization.id
        )
        db_session.add_all([portfolio1, portfolio2])
        await db_session.commit()
        await db_session.refresh(portfolio1)
        await db_session.refresh(portfolio2)

        program = Program(
            name="Moving Program",
            organization_id=test_organization.id,
            portfolio_id=portfolio1.id
        )
        db_session.add(program)
        await db_session.commit()
        await db_session.refresh(program)

        # Act
        response = await authenticated_org_client.post(
            "/api/hierarchy/move",
            json={
                "item_id": str(program.id),
                "item_type": "program",
                "target_parent_id": str(portfolio2.id),
                "target_parent_type": "portfolio"
            }
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["item"]["portfolio_id"] == str(portfolio2.id)

    @pytest.mark.asyncio
    async def test_move_item_with_invalid_item_id(
        self,
        authenticated_org_client: AsyncClient
    ):
        """Test moving with invalid UUID format returns 400."""
        # Act
        response = await authenticated_org_client.post(
            "/api/hierarchy/move",
            json={
                "item_id": "not-a-uuid",
                "item_type": "project",
                "target_parent_id": "also-not-a-uuid",
                "target_parent_type": "portfolio"
            }
        )

        # Assert
        assert response.status_code == 400
        assert "Invalid item ID format" in response.json()["detail"]

    @pytest.mark.asyncio
    async def test_move_item_with_invalid_item_type(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test moving with invalid item type returns 400."""
        # Arrange
        portfolio = Portfolio(
            name="Portfolio",
            organization_id=test_organization.id
        )
        db_session.add(portfolio)
        await db_session.commit()
        await db_session.refresh(portfolio)

        # Act
        response = await authenticated_org_client.post(
            "/api/hierarchy/move",
            json={
                "item_id": str(portfolio.id),
                "item_type": "invalid_type",
                "target_parent_id": str(portfolio.id),
                "target_parent_type": "portfolio"
            }
        )

        # Assert
        assert response.status_code == 400
        assert "Invalid item type" in response.json()["detail"]

    @pytest.mark.asyncio
    async def test_move_nonexistent_item(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test moving a non-existent item returns error."""
        # Arrange
        portfolio = Portfolio(
            name="Portfolio",
            organization_id=test_organization.id
        )
        db_session.add(portfolio)
        await db_session.commit()
        await db_session.refresh(portfolio)

        # Act - use a valid UUID that doesn't exist
        fake_uuid = "00000000-0000-0000-0000-000000000001"
        response = await authenticated_org_client.post(
            "/api/hierarchy/move",
            json={
                "item_id": fake_uuid,
                "item_type": "project",
                "target_parent_id": str(portfolio.id),
                "target_parent_type": "portfolio"
            }
        )

        # Assert
        assert response.status_code == 400
        assert "not found" in response.json()["detail"].lower()

    @pytest.mark.asyncio
    async def test_move_to_nonexistent_target(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test moving to a non-existent target returns error."""
        # Arrange
        project = Project(
            name="Project",
            organization_id=test_organization.id,
            status=ProjectStatus.ACTIVE
        )
        db_session.add(project)
        await db_session.commit()
        await db_session.refresh(project)

        # Act
        fake_uuid = "00000000-0000-0000-0000-000000000001"
        response = await authenticated_org_client.post(
            "/api/hierarchy/move",
            json={
                "item_id": str(project.id),
                "item_type": "project",
                "target_parent_id": fake_uuid,
                "target_parent_type": "portfolio"
            }
        )

        # Assert
        assert response.status_code == 400
        assert "not found" in response.json()["detail"].lower()


class TestBulkMoveItems:
    """Test POST /api/hierarchy/bulk-move - Bulk move items."""

    @pytest.mark.asyncio
    async def test_bulk_move_multiple_projects_to_portfolio(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test moving multiple projects to a portfolio in bulk."""
        # Arrange
        portfolio = Portfolio(
            name="Target Portfolio",
            organization_id=test_organization.id
        )
        db_session.add(portfolio)
        await db_session.commit()
        await db_session.refresh(portfolio)

        project1 = Project(name="Project 1", organization_id=test_organization.id, status=ProjectStatus.ACTIVE)
        project2 = Project(name="Project 2", organization_id=test_organization.id, status=ProjectStatus.ACTIVE)
        project3 = Project(name="Project 3", organization_id=test_organization.id, status=ProjectStatus.ACTIVE)
        db_session.add_all([project1, project2, project3])
        await db_session.commit()
        await db_session.refresh(project1)
        await db_session.refresh(project2)
        await db_session.refresh(project3)

        # Act
        response = await authenticated_org_client.post(
            "/api/hierarchy/bulk-move",
            json={
                "items": [
                    {"id": str(project1.id), "type": "project"},
                    {"id": str(project2.id), "type": "project"},
                    {"id": str(project3.id), "type": "project"}
                ],
                "target_parent_id": str(portfolio.id),
                "target_parent_type": "portfolio"
            }
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert "Bulk move completed" in data["message"]
        assert data["results"]["success_count"] == 3
        assert data["results"]["error_count"] == 0
        assert len(data["results"]["moved_items"]) == 3

    @pytest.mark.asyncio
    async def test_bulk_move_with_empty_items_list(
        self,
        authenticated_org_client: AsyncClient
    ):
        """Test bulk move with empty items list returns 400."""
        # Act
        response = await authenticated_org_client.post(
            "/api/hierarchy/bulk-move",
            json={
                "items": [],
                "target_parent_id": None,
                "target_parent_type": None
            }
        )

        # Assert
        assert response.status_code == 400
        assert "No items provided" in response.json()["detail"]

    @pytest.mark.asyncio
    async def test_bulk_move_with_partial_failures(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test bulk move with some items failing."""
        # Arrange
        portfolio = Portfolio(
            name="Portfolio",
            organization_id=test_organization.id
        )
        db_session.add(portfolio)
        await db_session.commit()
        await db_session.refresh(portfolio)

        project = Project(
            name="Valid Project",
            organization_id=test_organization.id,
            status=ProjectStatus.ACTIVE
        )
        db_session.add(project)
        await db_session.commit()
        await db_session.refresh(project)

        # Act - mix valid and invalid items
        fake_uuid = "00000000-0000-0000-0000-000000000001"
        response = await authenticated_org_client.post(
            "/api/hierarchy/bulk-move",
            json={
                "items": [
                    {"id": str(project.id), "type": "project"},
                    {"id": fake_uuid, "type": "project"}
                ],
                "target_parent_id": str(portfolio.id),
                "target_parent_type": "portfolio"
            }
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["results"]["success_count"] == 1
        assert data["results"]["error_count"] == 1
        assert len(data["results"]["errors"]) == 1

    @pytest.mark.asyncio
    async def test_bulk_move_with_invalid_item_format(
        self,
        authenticated_org_client: AsyncClient
    ):
        """Test bulk move with invalid item format returns 400."""
        # Act
        response = await authenticated_org_client.post(
            "/api/hierarchy/bulk-move",
            json={
                "items": [
                    {"id": "valid-looking-id"}  # Missing 'type' field
                ],
                "target_parent_id": None,
                "target_parent_type": None
            }
        )

        # Assert
        assert response.status_code == 400
        assert "must have 'id' and 'type' fields" in response.json()["detail"]


class TestBulkDeleteItems:
    """Test POST /api/hierarchy/bulk-delete - Bulk delete items."""

    @pytest.mark.asyncio
    async def test_bulk_delete_multiple_projects(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test deleting multiple projects in bulk."""
        # Arrange
        project1 = Project(name="Project 1", organization_id=test_organization.id, status=ProjectStatus.ACTIVE)
        project2 = Project(name="Project 2", organization_id=test_organization.id, status=ProjectStatus.ACTIVE)
        db_session.add_all([project1, project2])
        await db_session.commit()
        await db_session.refresh(project1)
        await db_session.refresh(project2)

        # Act
        response = await authenticated_org_client.post(
            "/api/hierarchy/bulk-delete",
            json={
                "items": [
                    {"id": str(project1.id), "type": "project"},
                    {"id": str(project2.id), "type": "project"}
                ],
                "delete_children": True
            }
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert "Bulk delete completed" in data["message"]
        assert data["results"]["deleted_count"] == 2
        assert data["results"]["error_count"] == 0

    @pytest.mark.asyncio
    async def test_bulk_delete_program_with_reassignment(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test deleting program and reassigning its projects."""
        # Arrange
        portfolio = Portfolio(
            name="Portfolio",
            organization_id=test_organization.id
        )
        db_session.add(portfolio)
        await db_session.commit()
        await db_session.refresh(portfolio)

        program1 = Program(
            name="Program to Delete",
            organization_id=test_organization.id,
            portfolio_id=portfolio.id
        )
        program2 = Program(
            name="Target Program",
            organization_id=test_organization.id,
            portfolio_id=portfolio.id
        )
        db_session.add_all([program1, program2])
        await db_session.commit()
        await db_session.refresh(program1)
        await db_session.refresh(program2)

        project = Project(
            name="Project",
            organization_id=test_organization.id,
            portfolio_id=portfolio.id,
            program_id=program1.id,
            status=ProjectStatus.ACTIVE
        )
        db_session.add(project)
        await db_session.commit()
        await db_session.refresh(project)

        # Act
        response = await authenticated_org_client.post(
            "/api/hierarchy/bulk-delete",
            json={
                "items": [
                    {"id": str(program1.id), "type": "program"}
                ],
                "delete_children": False,
                "reassign_to_id": str(program2.id),
                "reassign_to_type": "program"
            }
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["results"]["deleted_count"] == 1
        assert data["results"]["reassigned_count"] >= 1

    @pytest.mark.asyncio
    async def test_bulk_delete_with_empty_items(
        self,
        authenticated_org_client: AsyncClient
    ):
        """Test bulk delete with no items returns 400."""
        # Act
        response = await authenticated_org_client.post(
            "/api/hierarchy/bulk-delete",
            json={
                "items": [],
                "delete_children": True
            }
        )

        # Assert
        assert response.status_code == 400
        assert "No items provided" in response.json()["detail"]

    @pytest.mark.asyncio
    async def test_bulk_delete_requires_admin_role(
        self,
        client_factory,
        test_organization: Organization,
        db_session: AsyncSession,
        test_user: User
    ):
        """Test bulk delete requires admin role (not just member)."""
        # Arrange - Update user role to member
        from models.organization_member import OrganizationMember
        from sqlalchemy import update
        await db_session.execute(
            update(OrganizationMember)
            .where(OrganizationMember.organization_id == test_organization.id)
            .where(OrganizationMember.user_id == test_user.id)
            .values(role="member")
        )
        await db_session.commit()

        # Create client with member role
        from services.auth.native_auth_service import native_auth_service
        token = native_auth_service.create_access_token(
            user_id=str(test_user.id),
            email=test_user.email,
            organization_id=str(test_organization.id)
        )
        member_client = await client_factory(
            Authorization=f"Bearer {token}",
            **{"X-Organization-Id": str(test_organization.id)}
        )

        project = Project(name="Project", organization_id=test_organization.id, status=ProjectStatus.ACTIVE)
        db_session.add(project)
        await db_session.commit()
        await db_session.refresh(project)

        # Act
        response = await member_client.post(
            "/api/hierarchy/bulk-delete",
            json={
                "items": [{"id": str(project.id), "type": "project"}],
                "delete_children": True
            }
        )

        # Assert
        assert response.status_code in [403, 401]


class TestGetHierarchyPath:
    """Test POST /api/hierarchy/path - Get hierarchy path (breadcrumbs)."""

    @pytest.mark.asyncio
    async def test_get_path_for_orphaned_project(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test path for project with no parent."""
        # Arrange
        project = Project(
            name="Orphaned Project",
            organization_id=test_organization.id,
            status=ProjectStatus.ACTIVE
        )
        db_session.add(project)
        await db_session.commit()
        await db_session.refresh(project)

        # Act
        response = await authenticated_org_client.post(
            "/api/hierarchy/path",
            json={
                "item_id": str(project.id),
                "item_type": "project"
            }
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert len(data["path"]) == 1
        assert data["path"][0]["name"] == "Orphaned Project"
        assert data["path"][0]["type"] == "project"
        assert data["depth"] == 1

    @pytest.mark.asyncio
    async def test_get_path_for_project_in_program(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test path for project under portfolio > program."""
        # Arrange
        portfolio = Portfolio(name="Portfolio", organization_id=test_organization.id)
        db_session.add(portfolio)
        await db_session.commit()
        await db_session.refresh(portfolio)

        program = Program(
            name="Program",
            organization_id=test_organization.id,
            portfolio_id=portfolio.id
        )
        db_session.add(program)
        await db_session.commit()
        await db_session.refresh(program)

        project = Project(
            name="Project",
            organization_id=test_organization.id,
            portfolio_id=portfolio.id,
            program_id=program.id,
            status=ProjectStatus.ACTIVE
        )
        db_session.add(project)
        await db_session.commit()
        await db_session.refresh(project)

        # Act
        response = await authenticated_org_client.post(
            "/api/hierarchy/path",
            json={
                "item_id": str(project.id),
                "item_type": "project"
            }
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["depth"] == 3
        assert data["path"][0]["name"] == "Portfolio"
        assert data["path"][0]["type"] == "portfolio"
        assert data["path"][1]["name"] == "Program"
        assert data["path"][1]["type"] == "program"
        assert data["path"][2]["name"] == "Project"
        assert data["path"][2]["type"] == "project"

    @pytest.mark.asyncio
    async def test_get_path_for_program(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test path for program under portfolio."""
        # Arrange
        portfolio = Portfolio(name="Portfolio", organization_id=test_organization.id)
        db_session.add(portfolio)
        await db_session.commit()
        await db_session.refresh(portfolio)

        program = Program(
            name="Program",
            organization_id=test_organization.id,
            portfolio_id=portfolio.id
        )
        db_session.add(program)
        await db_session.commit()
        await db_session.refresh(program)

        # Act
        response = await authenticated_org_client.post(
            "/api/hierarchy/path",
            json={
                "item_id": str(program.id),
                "item_type": "program"
            }
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["depth"] == 2
        assert data["path"][0]["name"] == "Portfolio"
        assert data["path"][1]["name"] == "Program"

    @pytest.mark.asyncio
    async def test_get_path_for_portfolio(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test path for portfolio (top level)."""
        # Arrange
        portfolio = Portfolio(name="Portfolio", organization_id=test_organization.id)
        db_session.add(portfolio)
        await db_session.commit()
        await db_session.refresh(portfolio)

        # Act
        response = await authenticated_org_client.post(
            "/api/hierarchy/path",
            json={
                "item_id": str(portfolio.id),
                "item_type": "portfolio"
            }
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["depth"] == 1
        assert data["path"][0]["name"] == "Portfolio"
        assert data["path"][0]["type"] == "portfolio"

    @pytest.mark.asyncio
    async def test_get_path_with_invalid_item_type(
        self,
        authenticated_org_client: AsyncClient
    ):
        """Test path with invalid item type returns 400."""
        # Act
        response = await authenticated_org_client.post(
            "/api/hierarchy/path",
            json={
                "item_id": "00000000-0000-0000-0000-000000000001",
                "item_type": "invalid"
            }
        )

        # Assert
        assert response.status_code == 400
        assert "Invalid item type" in response.json()["detail"]


class TestSearchHierarchy:
    """Test GET /api/hierarchy/search - Search hierarchy."""

    @pytest.mark.asyncio
    async def test_search_with_empty_query(
        self,
        authenticated_org_client: AsyncClient
    ):
        """Test search with empty query returns 400."""
        # Act
        response = await authenticated_org_client.get(
            "/api/hierarchy/search?query="
        )

        # Assert
        assert response.status_code == 400
        assert "cannot be empty" in response.json()["detail"]

    @pytest.mark.asyncio
    async def test_search_portfolios_by_name(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test searching portfolios by name."""
        # Arrange
        portfolio1 = Portfolio(
            name="Digital Transformation",
            description="Modernize systems",
            organization_id=test_organization.id
        )
        portfolio2 = Portfolio(
            name="Innovation Hub",
            description="New digital products",
            organization_id=test_organization.id
        )
        db_session.add_all([portfolio1, portfolio2])
        await db_session.commit()

        # Act - search by partial name
        response = await authenticated_org_client.get(
            "/api/hierarchy/search?query=digital"
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["query"] == "digital"
        assert data["total_count"] == 2  # Both match "digital"

        # Check both portfolios are in results
        result_names = {r["name"] for r in data["results"]}
        assert "Digital Transformation" in result_names
        assert "Innovation Hub" in result_names

    @pytest.mark.asyncio
    async def test_search_programs_by_name(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test searching programs by name."""
        # Arrange
        portfolio = Portfolio(
            name="Enterprise Portfolio",
            organization_id=test_organization.id
        )
        db_session.add(portfolio)
        await db_session.commit()
        await db_session.refresh(portfolio)

        program1 = Program(
            name="Cloud Migration",
            description="Move to cloud",
            organization_id=test_organization.id,
            portfolio_id=portfolio.id
        )
        program2 = Program(
            name="Mobile App Development",
            description="New mobile apps",
            organization_id=test_organization.id,
            portfolio_id=portfolio.id
        )
        db_session.add_all([program1, program2])
        await db_session.commit()

        # Act
        response = await authenticated_org_client.get(
            "/api/hierarchy/search?query=migration"
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["total_count"] == 1
        assert data["results"][0]["name"] == "Cloud Migration"
        assert data["results"][0]["type"] == "program"
        assert data["results"][0]["portfolio_id"] == str(portfolio.id)

    @pytest.mark.asyncio
    async def test_search_projects_by_description(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test searching projects by description."""
        # Arrange
        project1 = Project(
            name="Website Redesign",
            description="Redesign company website with modern UX",
            organization_id=test_organization.id,
            status=ProjectStatus.ACTIVE
        )
        project2 = Project(
            name="API Gateway",
            description="Build microservices API gateway",
            organization_id=test_organization.id,
            status=ProjectStatus.ACTIVE
        )
        db_session.add_all([project1, project2])
        await db_session.commit()

        # Act - search by description keyword
        response = await authenticated_org_client.get(
            "/api/hierarchy/search?query=modern"
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["total_count"] == 1
        assert data["results"][0]["name"] == "Website Redesign"
        assert data["results"][0]["type"] == "project"

    @pytest.mark.asyncio
    async def test_search_with_item_type_filter(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test filtering search results by item type."""
        # Arrange
        portfolio = Portfolio(
            name="Innovation",
            description="Innovation portfolio",
            organization_id=test_organization.id
        )
        db_session.add(portfolio)
        await db_session.commit()
        await db_session.refresh(portfolio)

        program = Program(
            name="Innovation Program",
            description="Innovation initiatives",
            organization_id=test_organization.id,
            portfolio_id=portfolio.id
        )
        db_session.add(program)
        await db_session.commit()

        project = Project(
            name="Innovation Lab",
            description="Experimental projects",
            organization_id=test_organization.id,
            status=ProjectStatus.ACTIVE
        )
        db_session.add(project)
        await db_session.commit()

        # Act - search only projects
        response = await authenticated_org_client.get(
            "/api/hierarchy/search?query=innovation&item_types=project"
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["total_count"] == 1
        assert data["results"][0]["type"] == "project"
        assert data["results"][0]["name"] == "Innovation Lab"

    @pytest.mark.asyncio
    async def test_search_with_multiple_item_type_filters(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test searching with multiple item type filters."""
        # Arrange
        portfolio = Portfolio(
            name="Tech Portfolio",
            organization_id=test_organization.id
        )
        db_session.add(portfolio)
        await db_session.commit()
        await db_session.refresh(portfolio)

        program = Program(
            name="Tech Program",
            organization_id=test_organization.id,
            portfolio_id=portfolio.id
        )
        db_session.add(program)
        await db_session.commit()

        project = Project(
            name="Tech Project",
            organization_id=test_organization.id,
            status=ProjectStatus.ACTIVE
        )
        db_session.add(project)
        await db_session.commit()

        # Act - search portfolios and programs only
        response = await authenticated_org_client.get(
            "/api/hierarchy/search?query=tech&item_types=portfolio&item_types=program"
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["total_count"] == 2
        result_types = {r["type"] for r in data["results"]}
        assert "portfolio" in result_types
        assert "program" in result_types
        assert "project" not in result_types

    @pytest.mark.asyncio
    async def test_search_with_portfolio_filter(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test filtering search results by portfolio."""
        # Arrange
        portfolio1 = Portfolio(
            name="Portfolio A",
            organization_id=test_organization.id
        )
        portfolio2 = Portfolio(
            name="Portfolio B",
            organization_id=test_organization.id
        )
        db_session.add_all([portfolio1, portfolio2])
        await db_session.commit()
        await db_session.refresh(portfolio1)
        await db_session.refresh(portfolio2)

        program1 = Program(
            name="API Development",
            organization_id=test_organization.id,
            portfolio_id=portfolio1.id
        )
        program2 = Program(
            name="API Testing",
            organization_id=test_organization.id,
            portfolio_id=portfolio2.id
        )
        db_session.add_all([program1, program2])
        await db_session.commit()

        # Act - search within portfolio1 only
        response = await authenticated_org_client.get(
            f"/api/hierarchy/search?query=api&portfolio_id={str(portfolio1.id)}"
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["total_count"] == 1
        assert data["results"][0]["name"] == "API Development"

    @pytest.mark.asyncio
    async def test_search_excludes_archived_projects(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test that search excludes archived projects."""
        # Arrange
        active_project = Project(
            name="Active Migration",
            description="Active project",
            organization_id=test_organization.id,
            status=ProjectStatus.ACTIVE
        )
        archived_project = Project(
            name="Archived Migration",
            description="Archived project",
            organization_id=test_organization.id,
            status=ProjectStatus.ARCHIVED
        )
        db_session.add_all([active_project, archived_project])
        await db_session.commit()

        # Act
        response = await authenticated_org_client.get(
            "/api/hierarchy/search?query=migration"
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["total_count"] == 1
        assert data["results"][0]["name"] == "Active Migration"

    @pytest.mark.asyncio
    async def test_search_multi_tenant_isolation(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession,
        test_user: User
    ):
        """Test search only returns items from current organization."""
        # Arrange - create another org
        other_org = Organization(
            name="Other Org",
            slug="other-org",
            created_by=test_user.id
        )
        db_session.add(other_org)
        await db_session.commit()

        # Create projects in both orgs
        my_project = Project(
            name="Security Audit",
            organization_id=test_organization.id,
            status=ProjectStatus.ACTIVE
        )
        other_project = Project(
            name="Security Compliance",
            organization_id=other_org.id,
            status=ProjectStatus.ACTIVE
        )
        db_session.add_all([my_project, other_project])
        await db_session.commit()

        # Act
        response = await authenticated_org_client.get(
            "/api/hierarchy/search?query=security"
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["total_count"] == 1
        assert data["results"][0]["name"] == "Security Audit"

    @pytest.mark.asyncio
    async def test_search_respects_limit_parameter(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test search respects limit parameter."""
        # Arrange - create multiple matching projects
        projects = [
            Project(
                name=f"Test Project {i}",
                description="Test",
                organization_id=test_organization.id,
                status=ProjectStatus.ACTIVE
            )
            for i in range(10)
        ]
        db_session.add_all(projects)
        await db_session.commit()

        # Act - limit to 3 results
        response = await authenticated_org_client.get(
            "/api/hierarchy/search?query=test&limit=3"
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["total_count"] == 3
        assert len(data["results"]) == 3

    @pytest.mark.asyncio
    async def test_search_relevance_sorting(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test search results are sorted by relevance."""
        # Arrange
        exact_match = Project(
            name="API",
            description="Exact match",
            organization_id=test_organization.id,
            status=ProjectStatus.ACTIVE
        )
        starts_with = Project(
            name="API Gateway",
            description="Starts with",
            organization_id=test_organization.id,
            status=ProjectStatus.ACTIVE
        )
        contains = Project(
            name="New API Development",
            description="Contains",
            organization_id=test_organization.id,
            status=ProjectStatus.ACTIVE
        )
        db_session.add_all([contains, exact_match, starts_with])  # Add in random order
        await db_session.commit()

        # Act
        response = await authenticated_org_client.get(
            "/api/hierarchy/search?query=api"
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["total_count"] == 3
        # Results should be sorted: exact match first, then starts with, then contains
        assert data["results"][0]["name"] == "API"
        assert data["results"][1]["name"] == "API Gateway"
        assert data["results"][2]["name"] == "New API Development"

    @pytest.mark.asyncio
    async def test_search_includes_hierarchy_path(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test search results include full hierarchy path."""
        # Arrange
        portfolio = Portfolio(
            name="Enterprise",
            organization_id=test_organization.id
        )
        db_session.add(portfolio)
        await db_session.commit()
        await db_session.refresh(portfolio)

        program = Program(
            name="Cloud",
            organization_id=test_organization.id,
            portfolio_id=portfolio.id
        )
        db_session.add(program)
        await db_session.commit()
        await db_session.refresh(program)

        project = Project(
            name="Migration",
            organization_id=test_organization.id,
            portfolio_id=portfolio.id,
            program_id=program.id,
            status=ProjectStatus.ACTIVE
        )
        db_session.add(project)
        await db_session.commit()

        # Act
        response = await authenticated_org_client.get(
            "/api/hierarchy/search?query=migration"
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["total_count"] == 1

        result = data["results"][0]
        assert len(result["path"]) == 3
        assert result["path"][0]["name"] == "Enterprise"
        assert result["path"][0]["type"] == "portfolio"
        assert result["path"][1]["name"] == "Cloud"
        assert result["path"][1]["type"] == "program"
        assert result["path"][2]["name"] == "Migration"
        assert result["path"][2]["type"] == "project"

    @pytest.mark.asyncio
    async def test_search_with_invalid_item_type(
        self,
        authenticated_org_client: AsyncClient
    ):
        """Test search with invalid item type returns 400."""
        # Act
        response = await authenticated_org_client.get(
            "/api/hierarchy/search?query=test&item_types=invalid"
        )

        # Assert
        assert response.status_code == 400
        assert "Invalid item types" in response.json()["detail"]

    @pytest.mark.asyncio
    async def test_search_with_invalid_portfolio_id(
        self,
        authenticated_org_client: AsyncClient
    ):
        """Test search with invalid portfolio ID returns 400."""
        # Act
        response = await authenticated_org_client.get(
            "/api/hierarchy/search?query=test&portfolio_id=not-a-uuid"
        )

        # Assert
        assert response.status_code == 400
        assert "Invalid portfolio ID format" in response.json()["detail"]

    @pytest.mark.asyncio
    async def test_search_case_insensitive(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test search is case-insensitive."""
        # Arrange
        project = Project(
            name="UPPERCASE PROJECT",
            description="Mixed Case Description",
            organization_id=test_organization.id,
            status=ProjectStatus.ACTIVE
        )
        db_session.add(project)
        await db_session.commit()

        # Act - search with lowercase
        response = await authenticated_org_client.get(
            "/api/hierarchy/search?query=uppercase"
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["total_count"] == 1
        assert data["results"][0]["name"] == "UPPERCASE PROJECT"


class TestHierarchyStatistics:
    """Test GET /api/hierarchy/statistics/summary - Get hierarchy statistics."""

    @pytest.mark.asyncio
    async def test_get_statistics_for_empty_organization(
        self,
        authenticated_org_client: AsyncClient
    ):
        """Test statistics for organization with no items."""
        # Act
        response = await authenticated_org_client.get(
            "/api/hierarchy/statistics/summary"
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["portfolio_count"] == 0
        assert data["program_count"] == 0
        assert data["project_count"] == 0
        assert data["standalone_project_count"] == 0
        assert data["standalone_program_count"] == 0
        assert data["standalone_count"] == 0
        assert data["total_count"] == 0

    @pytest.mark.asyncio
    async def test_get_statistics_with_complete_hierarchy(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test statistics with portfolios, programs, and projects."""
        # Arrange
        portfolio = Portfolio(name="Portfolio", organization_id=test_organization.id)
        db_session.add(portfolio)
        await db_session.commit()
        await db_session.refresh(portfolio)

        program = Program(
            name="Program",
            organization_id=test_organization.id,
            portfolio_id=portfolio.id
        )
        db_session.add(program)
        await db_session.commit()
        await db_session.refresh(program)

        project1 = Project(
            name="Project 1",
            organization_id=test_organization.id,
            portfolio_id=portfolio.id,
            program_id=program.id,
            status=ProjectStatus.ACTIVE
        )
        project2 = Project(
            name="Project 2",
            organization_id=test_organization.id,
            portfolio_id=portfolio.id,
            status=ProjectStatus.ACTIVE
        )
        db_session.add_all([project1, project2])
        await db_session.commit()

        # Act
        response = await authenticated_org_client.get(
            "/api/hierarchy/statistics/summary"
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["portfolio_count"] == 1
        assert data["program_count"] == 1
        assert data["project_count"] == 2
        assert data["standalone_project_count"] == 0
        assert data["standalone_program_count"] == 0
        assert data["total_count"] == 4

    @pytest.mark.asyncio
    async def test_get_statistics_with_orphaned_items(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test statistics includes standalone items count."""
        # Arrange
        orphaned_program = Program(
            name="Orphaned Program",
            organization_id=test_organization.id,
            portfolio_id=None
        )
        db_session.add(orphaned_program)

        orphaned_project = Project(
            name="Orphaned Project",
            organization_id=test_organization.id,
            status=ProjectStatus.ACTIVE
        )
        db_session.add(orphaned_project)
        await db_session.commit()

        # Act
        response = await authenticated_org_client.get(
            "/api/hierarchy/statistics/summary"
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["standalone_program_count"] == 1
        assert data["standalone_project_count"] == 1
        assert data["standalone_count"] == 2

    @pytest.mark.asyncio
    async def test_get_statistics_excludes_archived_projects(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test that archived projects are excluded from statistics."""
        # Arrange
        active_project = Project(
            name="Active",
            organization_id=test_organization.id,
            status=ProjectStatus.ACTIVE
        )
        archived_project = Project(
            name="Archived",
            organization_id=test_organization.id,
            status=ProjectStatus.ARCHIVED
        )
        db_session.add_all([active_project, archived_project])
        await db_session.commit()

        # Act
        response = await authenticated_org_client.get(
            "/api/hierarchy/statistics/summary"
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["project_count"] == 1  # Only active project
        assert data["standalone_project_count"] == 1
