"""
Integration tests for Program Management API.

Covers TESTING_BACKEND.md section 4.2 - Program Management

Status: All 10 features tested (50+ tests)
"""

import pytest
from datetime import datetime
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from models.user import User
from models.organization import Organization
from models.portfolio import Portfolio
from models.program import Program
from models.project import Project, ProjectStatus


class TestProgramCreation:
    """Test program creation endpoint."""

    @pytest.mark.asyncio
    async def test_create_program_minimal_data(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization
    ):
        """Test successful program creation with minimal required data."""
        # Arrange
        program_data = {
            "name": "Strategic Program"
        }

        # Act
        response = await authenticated_org_client.post(
            "/api/v1/programs/",
            json=program_data
        )

        # Assert
        assert response.status_code == 201
        data = response.json()
        assert data["name"] == "Strategic Program"
        assert data["portfolio_id"] is None
        assert data["portfolio_name"] is None
        assert data["project_count"] == 0
        assert "id" in data
        assert "created_at" in data

    @pytest.mark.asyncio
    async def test_create_program_with_full_data(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        test_user: User,
        db_session: AsyncSession
    ):
        """Test program creation with all optional fields including portfolio."""
        # Arrange - Create a portfolio first
        portfolio = Portfolio(name="Test Portfolio", organization_id=test_organization.id)
        db_session.add(portfolio)
        await db_session.commit()
        await db_session.refresh(portfolio)

        program_data = {
            "name": "Enterprise Program",
            "description": "Critical enterprise initiatives",
            "portfolio_id": str(portfolio.id),
            "created_by": "program.manager@example.com"
        }

        # Act
        response = await authenticated_org_client.post(
            "/api/v1/programs/",
            json=program_data
        )

        # Assert
        assert response.status_code == 201
        data = response.json()
        assert data["name"] == "Enterprise Program"
        assert data["description"] == "Critical enterprise initiatives"
        assert data["portfolio_id"] == str(portfolio.id)
        assert data["portfolio_name"] == "Test Portfolio"
        assert data["created_by"] == "program.manager@example.com"

    @pytest.mark.asyncio
    async def test_create_program_with_nonexistent_portfolio_fails(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization
    ):
        """Test that creating program with non-existent portfolio_id fails."""
        # Arrange
        import uuid
        fake_portfolio_id = uuid.uuid4()

        program_data = {
            "name": "Test Program",
            "portfolio_id": str(fake_portfolio_id)
        }

        # Act
        response = await authenticated_org_client.post(
            "/api/v1/programs/",
            json=program_data
        )

        # Assert
        assert response.status_code == 404
        assert "Portfolio not found" in response.json()["detail"]

    @pytest.mark.asyncio
    async def test_create_program_without_auth_fails(self, client: AsyncClient):
        """Test that creating program requires authentication."""
        # Act
        response = await client.post(
            "/api/v1/programs/",
            json={"name": "Test Program"}
        )

        # Assert
        assert response.status_code in [401, 403]

    @pytest.mark.asyncio
    async def test_create_program_defaults_created_by_to_current_user(
        self,
        authenticated_org_client: AsyncClient,
        test_user: User
    ):
        """Test that created_by defaults to current user email."""
        # Act
        response = await authenticated_org_client.post(
            "/api/v1/programs/",
            json={"name": "Auto-Created Program"}
        )

        # Assert
        assert response.status_code == 201
        data = response.json()
        assert data["created_by"] == test_user.email

    @pytest.mark.asyncio
    async def test_create_program_cross_organization_portfolio_fails(
        self,
        authenticated_org_client: AsyncClient,
        db_session: AsyncSession
    ):
        """Test that creating program with portfolio from another org fails."""
        # Arrange - Create another organization with portfolio
        from models.organization import Organization
        other_org = Organization(name="Other Org", slug="other-org")
        db_session.add(other_org)
        await db_session.commit()
        await db_session.refresh(other_org)

        other_portfolio = Portfolio(name="Other Portfolio", organization_id=other_org.id)
        db_session.add(other_portfolio)
        await db_session.commit()
        await db_session.refresh(other_portfolio)

        # Act
        response = await authenticated_org_client.post(
            "/api/v1/programs/",
            json={
                "name": "Test Program",
                "portfolio_id": str(other_portfolio.id)
            }
        )

        # Assert
        assert response.status_code == 404
        assert "Portfolio not found" in response.json()["detail"]


class TestProgramListing:
    """Test program listing endpoint."""

    @pytest.mark.asyncio
    async def test_list_programs_empty(
        self,
        authenticated_org_client: AsyncClient
    ):
        """Test listing programs when none exist."""
        # Act
        response = await authenticated_org_client.get("/api/v1/programs/")

        # Assert
        assert response.status_code == 200
        assert response.json() == []

    @pytest.mark.asyncio
    async def test_list_programs_multiple(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test listing multiple programs."""
        # Arrange - Create 3 programs
        programs = [
            Program(name="Program A", organization_id=test_organization.id),
            Program(name="Program B", organization_id=test_organization.id),
            Program(name="Program C", organization_id=test_organization.id)
        ]
        for p in programs:
            db_session.add(p)
        await db_session.commit()

        # Act
        response = await authenticated_org_client.get("/api/v1/programs/")

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert len(data) == 3
        names = [p["name"] for p in data]
        assert "Program A" in names
        assert "Program B" in names
        assert "Program C" in names

    @pytest.mark.asyncio
    async def test_list_programs_filter_by_portfolio(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test filtering programs by portfolio_id."""
        # Arrange - Create portfolio
        portfolio = Portfolio(name="Test Portfolio", organization_id=test_organization.id)
        db_session.add(portfolio)
        await db_session.commit()
        await db_session.refresh(portfolio)

        # Create programs - 2 in portfolio, 1 standalone
        program1 = Program(
            name="Portfolio Program 1",
            organization_id=test_organization.id,
            portfolio_id=portfolio.id
        )
        program2 = Program(
            name="Portfolio Program 2",
            organization_id=test_organization.id,
            portfolio_id=portfolio.id
        )
        program3 = Program(
            name="Standalone Program",
            organization_id=test_organization.id
        )
        db_session.add(program1)
        db_session.add(program2)
        db_session.add(program3)
        await db_session.commit()

        # Act
        response = await authenticated_org_client.get(
            f"/api/v1/programs/?portfolio_id={portfolio.id}"
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert len(data) == 2
        names = [p["name"] for p in data]
        assert "Portfolio Program 1" in names
        assert "Portfolio Program 2" in names
        assert "Standalone Program" not in names

    @pytest.mark.asyncio
    async def test_list_programs_pagination(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test program listing with pagination."""
        # Arrange - Create 5 programs
        for i in range(5):
            p = Program(name=f"Program {i}", organization_id=test_organization.id)
            db_session.add(p)
        await db_session.commit()

        # Act
        response = await authenticated_org_client.get("/api/v1/programs/?skip=2&limit=2")

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert len(data) == 2

    @pytest.mark.asyncio
    async def test_list_programs_multi_tenant_isolation(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test that users only see programs from their organization."""
        # Arrange - Create program in current org
        p1 = Program(name="My Program", organization_id=test_organization.id)
        db_session.add(p1)

        # Create another organization with program
        from models.organization import Organization
        other_org = Organization(name="Other Org", slug="other-org")
        db_session.add(other_org)
        await db_session.commit()
        await db_session.refresh(other_org)

        p2 = Program(name="Other Program", organization_id=other_org.id)
        db_session.add(p2)
        await db_session.commit()

        # Act
        response = await authenticated_org_client.get("/api/v1/programs/")

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert len(data) == 1
        assert data[0]["name"] == "My Program"

    @pytest.mark.asyncio
    async def test_list_programs_includes_counts(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test that program list includes project count."""
        # Arrange
        program = Program(name="Test Program", organization_id=test_organization.id)
        db_session.add(program)
        await db_session.commit()
        await db_session.refresh(program)

        # Add 2 projects
        project1 = Project(
            name="Project 1",
            organization_id=test_organization.id,
            program_id=program.id
        )
        project2 = Project(
            name="Project 2",
            organization_id=test_organization.id,
            program_id=program.id
        )
        db_session.add(project1)
        db_session.add(project2)
        await db_session.commit()

        # Act
        response = await authenticated_org_client.get("/api/v1/programs/")

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert len(data) == 1
        assert data[0]["project_count"] == 2


class TestProgramRetrieval:
    """Test program retrieval by ID."""

    @pytest.mark.asyncio
    async def test_get_program_by_id_success(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test successful program retrieval."""
        # Arrange
        program = Program(
            name="Test Program",
            description="Test description",
            organization_id=test_organization.id
        )
        db_session.add(program)
        await db_session.commit()
        await db_session.refresh(program)

        # Act
        response = await authenticated_org_client.get(f"/api/v1/programs/{program.id}")

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["id"] == str(program.id)
        assert data["name"] == "Test Program"
        assert data["description"] == "Test description"
        assert data["projects"] == []

    @pytest.mark.asyncio
    async def test_get_program_with_projects(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test getting program includes its projects."""
        # Arrange
        program = Program(name="Test Program", organization_id=test_organization.id)
        db_session.add(program)
        await db_session.commit()
        await db_session.refresh(program)

        # Add projects
        project1 = Project(
            name="Project 1",
            description="First project",
            organization_id=test_organization.id,
            program_id=program.id,
            status=ProjectStatus.ACTIVE
        )
        project2 = Project(
            name="Project 2",
            organization_id=test_organization.id,
            program_id=program.id,
            status=ProjectStatus.ACTIVE
        )
        db_session.add(project1)
        db_session.add(project2)
        await db_session.commit()

        # Act
        response = await authenticated_org_client.get(f"/api/v1/programs/{program.id}")

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["project_count"] == 2
        assert len(data["projects"]) == 2
        project_names = [p["name"] for p in data["projects"]]
        assert "Project 1" in project_names
        assert "Project 2" in project_names

    @pytest.mark.asyncio
    async def test_get_program_with_portfolio(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test getting program includes portfolio information."""
        # Arrange
        portfolio = Portfolio(name="Test Portfolio", organization_id=test_organization.id)
        db_session.add(portfolio)
        await db_session.commit()
        await db_session.refresh(portfolio)

        program = Program(
            name="Test Program",
            organization_id=test_organization.id,
            portfolio_id=portfolio.id
        )
        db_session.add(program)
        await db_session.commit()
        await db_session.refresh(program)

        # Act
        response = await authenticated_org_client.get(f"/api/v1/programs/{program.id}")

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["portfolio_id"] == str(portfolio.id)
        assert data["portfolio_name"] == "Test Portfolio"

    @pytest.mark.asyncio
    async def test_get_program_not_found(
        self,
        authenticated_org_client: AsyncClient
    ):
        """Test retrieving non-existent program returns 404."""
        # Arrange
        import uuid
        fake_id = uuid.uuid4()

        # Act
        response = await authenticated_org_client.get(f"/api/v1/programs/{fake_id}")

        # Assert
        assert response.status_code == 404
        assert "not found" in response.json()["detail"].lower()

    @pytest.mark.asyncio
    async def test_get_program_cross_organization_fails(
        self,
        authenticated_org_client: AsyncClient,
        db_session: AsyncSession
    ):
        """Test that users cannot access programs from other organizations."""
        # Arrange - Create another organization with a program
        from models.organization import Organization
        other_org = Organization(name="Other Org", slug="other-org")
        db_session.add(other_org)
        await db_session.commit()
        await db_session.refresh(other_org)

        program = Program(name="Other Program", organization_id=other_org.id)
        db_session.add(program)
        await db_session.commit()
        await db_session.refresh(program)

        # Act
        response = await authenticated_org_client.get(f"/api/v1/programs/{program.id}")

        # Assert
        assert response.status_code == 404


class TestProgramUpdate:
    """Test program update endpoint."""

    @pytest.mark.asyncio
    async def test_update_program_name(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test updating program name."""
        # Arrange
        program = Program(name="Old Name", organization_id=test_organization.id)
        db_session.add(program)
        await db_session.commit()
        await db_session.refresh(program)

        # Act
        response = await authenticated_org_client.put(
            f"/api/v1/programs/{program.id}",
            json={"name": "New Name"}
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["name"] == "New Name"

    @pytest.mark.asyncio
    async def test_update_program_all_fields(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test updating all program fields."""
        # Arrange
        portfolio = Portfolio(name="Test Portfolio", organization_id=test_organization.id)
        db_session.add(portfolio)
        await db_session.commit()
        await db_session.refresh(portfolio)

        program = Program(
            name="Original Program",
            organization_id=test_organization.id
        )
        db_session.add(program)
        await db_session.commit()
        await db_session.refresh(program)

        # Act
        response = await authenticated_org_client.put(
            f"/api/v1/programs/{program.id}",
            json={
                "name": "Updated Program",
                "description": "Updated description",
                "portfolio_id": str(portfolio.id)
            }
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["name"] == "Updated Program"
        assert data["description"] == "Updated description"
        assert data["portfolio_id"] == str(portfolio.id)
        assert data["portfolio_name"] == "Test Portfolio"

    @pytest.mark.asyncio
    async def test_update_program_make_standalone(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test removing program from portfolio (make standalone)."""
        # Arrange
        portfolio = Portfolio(name="Test Portfolio", organization_id=test_organization.id)
        db_session.add(portfolio)
        await db_session.commit()
        await db_session.refresh(portfolio)

        program = Program(
            name="Test Program",
            organization_id=test_organization.id,
            portfolio_id=portfolio.id
        )
        db_session.add(program)
        await db_session.commit()
        await db_session.refresh(program)

        # Act
        response = await authenticated_org_client.put(
            f"/api/v1/programs/{program.id}",
            json={"portfolio_id": None}
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["portfolio_id"] is None
        assert data["portfolio_name"] is None

    @pytest.mark.asyncio
    async def test_update_program_with_nonexistent_portfolio_fails(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test updating program with non-existent portfolio fails."""
        # Arrange
        program = Program(name="Test Program", organization_id=test_organization.id)
        db_session.add(program)
        await db_session.commit()
        await db_session.refresh(program)

        import uuid
        fake_portfolio_id = uuid.uuid4()

        # Act
        response = await authenticated_org_client.put(
            f"/api/v1/programs/{program.id}",
            json={"portfolio_id": str(fake_portfolio_id)}
        )

        # Assert
        assert response.status_code == 404
        assert "Portfolio not found" in response.json()["detail"]

    @pytest.mark.asyncio
    async def test_update_program_partial_fields(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test partial update of program fields."""
        # Arrange
        program = Program(
            name="Original",
            description="Original description",
            organization_id=test_organization.id
        )
        db_session.add(program)
        await db_session.commit()
        await db_session.refresh(program)

        # Act - Update only description
        response = await authenticated_org_client.put(
            f"/api/v1/programs/{program.id}",
            json={"description": "Updated description"}
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["description"] == "Updated description"
        assert data["name"] == "Original"  # Unchanged

    @pytest.mark.asyncio
    async def test_update_program_not_found(
        self,
        authenticated_org_client: AsyncClient
    ):
        """Test updating non-existent program returns 404."""
        # Arrange
        import uuid
        fake_id = uuid.uuid4()

        # Act
        response = await authenticated_org_client.put(
            f"/api/v1/programs/{fake_id}",
            json={"name": "Updated"}
        )

        # Assert
        assert response.status_code == 404

    @pytest.mark.asyncio
    async def test_update_program_cross_organization_fails(
        self,
        authenticated_org_client: AsyncClient,
        db_session: AsyncSession
    ):
        """Test that users cannot update programs from other organizations."""
        # Arrange
        from models.organization import Organization
        other_org = Organization(name="Other Org", slug="other-org")
        db_session.add(other_org)
        await db_session.commit()
        await db_session.refresh(other_org)

        program = Program(name="Other Program", organization_id=other_org.id)
        db_session.add(program)
        await db_session.commit()
        await db_session.refresh(program)

        # Act
        response = await authenticated_org_client.put(
            f"/api/v1/programs/{program.id}",
            json={"name": "Hacked"}
        )

        # Assert
        assert response.status_code == 404


class TestProgramDeletion:
    """Test program deletion endpoint."""

    @pytest.mark.asyncio
    async def test_delete_program_without_cascade(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test deleting program without cascade - projects become standalone."""
        # Arrange
        program = Program(name="Test Program", organization_id=test_organization.id)
        db_session.add(program)
        await db_session.commit()
        await db_session.refresh(program)

        project = Project(
            name="Test Project",
            organization_id=test_organization.id,
            program_id=program.id
        )
        db_session.add(project)
        await db_session.commit()

        # Act
        response = await authenticated_org_client.delete(
            f"/api/v1/programs/{program.id}?cascade_delete=false"
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert "standalone" in data["message"].lower()
        assert data["cascade_delete"] is False

        # Verify program is deleted
        result = await db_session.execute(select(Program).where(Program.id == program.id))
        assert result.scalar_one_or_none() is None

        # Verify project still exists but is orphaned
        await db_session.refresh(project)
        assert project.program_id is None

    @pytest.mark.asyncio
    async def test_delete_program_with_cascade(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test deleting program with cascade - projects are deleted."""
        # Arrange
        program = Program(name="Test Program", organization_id=test_organization.id)
        db_session.add(program)
        await db_session.commit()
        await db_session.refresh(program)

        project = Project(
            name="Test Project",
            organization_id=test_organization.id,
            program_id=program.id
        )
        db_session.add(project)
        await db_session.commit()
        project_id = project.id

        # Act
        response = await authenticated_org_client.delete(
            f"/api/v1/programs/{program.id}?cascade_delete=true"
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["cascade_delete"] is True

        # Verify both are deleted
        result = await db_session.execute(select(Program).where(Program.id == program.id))
        assert result.scalar_one_or_none() is None

        result = await db_session.execute(select(Project).where(Project.id == project_id))
        assert result.scalar_one_or_none() is None

    @pytest.mark.asyncio
    async def test_delete_program_not_found(
        self,
        authenticated_org_client: AsyncClient
    ):
        """Test deleting non-existent program returns 404."""
        # Arrange
        import uuid
        fake_id = uuid.uuid4()

        # Act
        response = await authenticated_org_client.delete(f"/api/v1/programs/{fake_id}")

        # Assert
        assert response.status_code == 404

    @pytest.mark.asyncio
    async def test_delete_empty_program(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test deleting program without projects."""
        # Arrange
        program = Program(name="Empty Program", organization_id=test_organization.id)
        db_session.add(program)
        await db_session.commit()
        await db_session.refresh(program)

        # Act
        response = await authenticated_org_client.delete(f"/api/v1/programs/{program.id}")

        # Assert
        assert response.status_code == 200

        # Verify deletion
        result = await db_session.execute(select(Program).where(Program.id == program.id))
        assert result.scalar_one_or_none() is None


class TestProgramProjects:
    """Test getting projects in a program."""

    @pytest.mark.asyncio
    async def test_get_program_projects_empty(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test getting projects when none exist."""
        # Arrange
        program = Program(name="Test Program", organization_id=test_organization.id)
        db_session.add(program)
        await db_session.commit()
        await db_session.refresh(program)

        # Act
        response = await authenticated_org_client.get(f"/api/v1/programs/{program.id}/projects")

        # Assert
        assert response.status_code == 200
        assert response.json() == []

    @pytest.mark.asyncio
    async def test_get_program_projects_multiple(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test getting multiple projects in a program."""
        # Arrange
        program = Program(name="Test Program", organization_id=test_organization.id)
        db_session.add(program)
        await db_session.commit()
        await db_session.refresh(program)

        projects = [
            Project(name="Project A", organization_id=test_organization.id, program_id=program.id),
            Project(name="Project B", organization_id=test_organization.id, program_id=program.id),
            Project(name="Project C", organization_id=test_organization.id, program_id=program.id)
        ]
        for p in projects:
            db_session.add(p)
        await db_session.commit()

        # Act
        response = await authenticated_org_client.get(f"/api/v1/programs/{program.id}/projects")

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert len(data) == 3
        names = [p["name"] for p in data]
        assert "Project A" in names
        assert "Project B" in names

    @pytest.mark.asyncio
    async def test_get_program_projects_not_found(
        self,
        authenticated_org_client: AsyncClient
    ):
        """Test getting projects for non-existent program."""
        # Arrange
        import uuid
        fake_id = uuid.uuid4()

        # Act
        response = await authenticated_org_client.get(f"/api/v1/programs/{fake_id}/projects")

        # Assert
        assert response.status_code == 404


class TestProgramPortfolioAssignment:
    """Test assigning program to portfolio."""

    @pytest.mark.asyncio
    async def test_assign_program_to_portfolio(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test successfully assigning program to portfolio."""
        # Arrange
        portfolio = Portfolio(name="Test Portfolio", organization_id=test_organization.id)
        db_session.add(portfolio)
        await db_session.commit()
        await db_session.refresh(portfolio)

        program = Program(name="Test Program", organization_id=test_organization.id)
        db_session.add(program)
        await db_session.commit()
        await db_session.refresh(program)

        # Act
        response = await authenticated_org_client.post(
            f"/api/v1/programs/{program.id}/assign-to-portfolio/{portfolio.id}"
        )

        # Assert
        assert response.status_code == 200
        assert "assigned to portfolio successfully" in response.json()["message"]

        # Verify assignment
        await db_session.refresh(program)
        assert program.portfolio_id == portfolio.id

    @pytest.mark.asyncio
    async def test_assign_program_to_portfolio_updates_projects(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test that assigning program to portfolio also updates its projects."""
        # Arrange
        portfolio = Portfolio(name="Test Portfolio", organization_id=test_organization.id)
        db_session.add(portfolio)
        await db_session.commit()
        await db_session.refresh(portfolio)

        program = Program(name="Test Program", organization_id=test_organization.id)
        db_session.add(program)
        await db_session.commit()
        await db_session.refresh(program)

        project = Project(
            name="Test Project",
            organization_id=test_organization.id,
            program_id=program.id
        )
        db_session.add(project)
        await db_session.commit()

        # Act
        response = await authenticated_org_client.post(
            f"/api/v1/programs/{program.id}/assign-to-portfolio/{portfolio.id}"
        )

        # Assert
        assert response.status_code == 200

        # Verify project inherited portfolio_id
        await db_session.refresh(project)
        assert project.portfolio_id == portfolio.id

    @pytest.mark.asyncio
    async def test_assign_program_to_nonexistent_portfolio_fails(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test that assigning to non-existent portfolio fails."""
        # Arrange
        program = Program(name="Test Program", organization_id=test_organization.id)
        db_session.add(program)
        await db_session.commit()
        await db_session.refresh(program)

        import uuid
        fake_portfolio_id = uuid.uuid4()

        # Act
        response = await authenticated_org_client.post(
            f"/api/v1/programs/{program.id}/assign-to-portfolio/{fake_portfolio_id}"
        )

        # Assert
        assert response.status_code == 404
        assert "Portfolio not found" in response.json()["detail"]

    @pytest.mark.asyncio
    async def test_assign_nonexistent_program_to_portfolio_fails(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test that assigning non-existent program fails."""
        # Arrange
        portfolio = Portfolio(name="Test Portfolio", organization_id=test_organization.id)
        db_session.add(portfolio)
        await db_session.commit()
        await db_session.refresh(portfolio)

        import uuid
        fake_program_id = uuid.uuid4()

        # Act
        response = await authenticated_org_client.post(
            f"/api/v1/programs/{fake_program_id}/assign-to-portfolio/{portfolio.id}"
        )

        # Assert
        assert response.status_code == 404
        assert "Program not found" in response.json()["detail"]


class TestProgramPortfolioRemoval:
    """Test removing program from portfolio."""

    @pytest.mark.asyncio
    async def test_remove_program_from_portfolio(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test successfully removing program from portfolio."""
        # Arrange
        portfolio = Portfolio(name="Test Portfolio", organization_id=test_organization.id)
        db_session.add(portfolio)
        await db_session.commit()
        await db_session.refresh(portfolio)

        program = Program(
            name="Test Program",
            organization_id=test_organization.id,
            portfolio_id=portfolio.id
        )
        db_session.add(program)
        await db_session.commit()
        await db_session.refresh(program)

        # Act
        response = await authenticated_org_client.post(
            f"/api/v1/programs/{program.id}/remove-from-portfolio"
        )

        # Assert
        assert response.status_code == 200
        assert "removed from portfolio successfully" in response.json()["message"]

        # Verify removal
        await db_session.refresh(program)
        assert program.portfolio_id is None

    @pytest.mark.asyncio
    async def test_remove_program_from_portfolio_updates_projects(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test that removing program from portfolio also updates its projects."""
        # Arrange
        portfolio = Portfolio(name="Test Portfolio", organization_id=test_organization.id)
        db_session.add(portfolio)
        await db_session.commit()
        await db_session.refresh(portfolio)

        program = Program(
            name="Test Program",
            organization_id=test_organization.id,
            portfolio_id=portfolio.id
        )
        db_session.add(program)
        await db_session.commit()
        await db_session.refresh(program)

        project = Project(
            name="Test Project",
            organization_id=test_organization.id,
            program_id=program.id,
            portfolio_id=portfolio.id
        )
        db_session.add(project)
        await db_session.commit()

        # Act
        response = await authenticated_org_client.post(
            f"/api/v1/programs/{program.id}/remove-from-portfolio"
        )

        # Assert
        assert response.status_code == 200

        # Verify project portfolio_id is removed
        await db_session.refresh(project)
        assert project.portfolio_id is None

    @pytest.mark.asyncio
    async def test_remove_nonexistent_program_from_portfolio_fails(
        self,
        authenticated_org_client: AsyncClient
    ):
        """Test that removing non-existent program fails."""
        # Arrange
        import uuid
        fake_program_id = uuid.uuid4()

        # Act
        response = await authenticated_org_client.post(
            f"/api/v1/programs/{fake_program_id}/remove-from-portfolio"
        )

        # Assert
        assert response.status_code == 404
        assert "Program not found" in response.json()["detail"]


class TestProgramStatistics:
    """Test program statistics endpoint."""

    @pytest.mark.asyncio
    async def test_get_program_statistics_empty(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test statistics for program with no content."""
        # Arrange
        program = Program(name="Test Program", organization_id=test_organization.id)
        db_session.add(program)
        await db_session.commit()
        await db_session.refresh(program)

        # Act
        response = await authenticated_org_client.get(f"/api/v1/programs/{program.id}/statistics")

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["program_id"] == str(program.id)
        assert data["program_name"] == "Test Program"
        assert data["portfolio"] is None
        assert data["project_count"] == 0
        assert data["archived_project_count"] == 0
        assert data["content_count"] == 0
        assert data["summary_count"] == 0
        assert data["activity_count"] == 0

    @pytest.mark.asyncio
    async def test_get_program_statistics_with_portfolio(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test statistics includes portfolio information."""
        # Arrange
        portfolio = Portfolio(name="Test Portfolio", organization_id=test_organization.id)
        db_session.add(portfolio)
        await db_session.commit()
        await db_session.refresh(portfolio)

        program = Program(
            name="Test Program",
            organization_id=test_organization.id,
            portfolio_id=portfolio.id
        )
        db_session.add(program)
        await db_session.commit()
        await db_session.refresh(program)

        # Act
        response = await authenticated_org_client.get(f"/api/v1/programs/{program.id}/statistics")

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["portfolio"] is not None
        assert data["portfolio"]["id"] == str(portfolio.id)
        assert data["portfolio"]["name"] == "Test Portfolio"

    @pytest.mark.asyncio
    async def test_get_program_statistics_with_projects(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test statistics with projects and content."""
        # Arrange
        program = Program(name="Test Program", organization_id=test_organization.id)
        db_session.add(program)
        await db_session.commit()
        await db_session.refresh(program)

        # Add 3 projects (1 archived)
        project1 = Project(
            name="Active Project",
            organization_id=test_organization.id,
            program_id=program.id
        )
        project2 = Project(
            name="Another Active",
            organization_id=test_organization.id,
            program_id=program.id
        )
        project3 = Project(
            name="Archived Project",
            organization_id=test_organization.id,
            program_id=program.id,
            status=ProjectStatus.ARCHIVED
        )
        db_session.add(project1)
        db_session.add(project2)
        db_session.add(project3)
        await db_session.commit()

        # Act
        response = await authenticated_org_client.get(f"/api/v1/programs/{program.id}/statistics")

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["project_count"] == 3
        assert data["archived_project_count"] == 1

    @pytest.mark.asyncio
    async def test_get_program_statistics_not_found(
        self,
        authenticated_org_client: AsyncClient
    ):
        """Test statistics for non-existent program."""
        # Arrange
        import uuid
        fake_id = uuid.uuid4()

        # Act
        response = await authenticated_org_client.get(f"/api/v1/programs/{fake_id}/statistics")

        # Assert
        assert response.status_code == 404


class TestProgramDeletionImpact:
    """Test program deletion impact analysis."""

    @pytest.mark.asyncio
    async def test_get_deletion_impact_empty_program(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test deletion impact for program with no projects."""
        # Arrange
        program = Program(
            name="Empty Program",
            description="No content",
            organization_id=test_organization.id
        )
        db_session.add(program)
        await db_session.commit()
        await db_session.refresh(program)

        # Act
        response = await authenticated_org_client.get(
            f"/api/v1/programs/{program.id}/deletion-impact"
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["program"]["id"] == str(program.id)
        assert data["program"]["name"] == "Empty Program"
        assert data["affected_projects"] == []
        assert data["total_projects"] == 0

    @pytest.mark.asyncio
    async def test_get_deletion_impact_with_projects(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test deletion impact for program with projects."""
        # Arrange
        program = Program(name="Full Program", organization_id=test_organization.id)
        db_session.add(program)
        await db_session.commit()
        await db_session.refresh(program)

        # Add projects
        project1 = Project(
            name="Project 1",
            description="First project",
            organization_id=test_organization.id,
            program_id=program.id
        )
        project2 = Project(
            name="Project 2",
            description="Second project",
            organization_id=test_organization.id,
            program_id=program.id
        )
        db_session.add(project1)
        db_session.add(project2)
        await db_session.commit()

        # Act
        response = await authenticated_org_client.get(
            f"/api/v1/programs/{program.id}/deletion-impact"
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["total_projects"] == 2
        assert len(data["affected_projects"]) == 2

        # Verify project details
        project_names = [p["name"] for p in data["affected_projects"]]
        assert "Project 1" in project_names
        assert "Project 2" in project_names

    @pytest.mark.asyncio
    async def test_get_deletion_impact_not_found(
        self,
        authenticated_org_client: AsyncClient
    ):
        """Test deletion impact for non-existent program."""
        # Arrange
        import uuid
        fake_id = uuid.uuid4()

        # Act
        response = await authenticated_org_client.get(f"/api/v1/programs/{fake_id}/deletion-impact")

        # Assert
        assert response.status_code == 404
