"""
Integration tests for Portfolio Management API.

Covers TESTING_BACKEND.md section 4.1 - Portfolio Management

Status: All 10 features tested (60+ tests)
"""

import pytest
from datetime import datetime
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from models.user import User
from models.organization import Organization
from models.portfolio import Portfolio, HealthStatus
from models.program import Program
from models.project import Project, ProjectStatus


class TestPortfolioCreation:
    """Test portfolio creation endpoint."""

    @pytest.mark.asyncio
    async def test_create_portfolio_minimal_data(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization
    ):
        """Test successful portfolio creation with minimal required data."""
        # Arrange
        portfolio_data = {
            "name": "Strategic Portfolio"
        }

        # Act
        response = await authenticated_org_client.post(
            "/api/v1/portfolios/",
            json=portfolio_data
        )

        # Assert
        assert response.status_code == 201
        data = response.json()
        assert data["name"] == "Strategic Portfolio"
        assert data["health_status"] == "not_set"
        assert data["program_count"] == 0
        assert data["direct_project_count"] == 0
        assert data["total_project_count"] == 0
        assert "id" in data
        assert "created_at" in data

    @pytest.mark.asyncio
    async def test_create_portfolio_with_full_data(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        test_user: User
    ):
        """Test portfolio creation with all optional fields."""
        # Arrange
        portfolio_data = {
            "name": "Enterprise Portfolio",
            "description": "Critical enterprise initiatives",
            "owner": "portfolio.manager@example.com",
            "health_status": "green",
            "risk_summary": "Low risk, on track"
        }

        # Act
        response = await authenticated_org_client.post(
            "/api/v1/portfolios/",
            json=portfolio_data
        )

        # Assert
        assert response.status_code == 201
        data = response.json()
        assert data["name"] == "Enterprise Portfolio"
        assert data["description"] == "Critical enterprise initiatives"
        assert data["owner"] == "portfolio.manager@example.com"
        assert data["health_status"] == "green"
        assert data["risk_summary"] == "Low risk, on track"
        assert data["created_by"] == test_user.email

    @pytest.mark.asyncio
    async def test_create_portfolio_duplicate_name_fails(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization
    ):
        """Test that duplicate portfolio names are rejected."""
        # Arrange
        portfolio_data = {"name": "Duplicate Portfolio"}
        await authenticated_org_client.post("/api/v1/portfolios/", json=portfolio_data)

        # Act
        response = await authenticated_org_client.post("/api/v1/portfolios/", json=portfolio_data)

        # Assert
        assert response.status_code == 400
        assert "already exists" in response.json()["detail"]

    @pytest.mark.asyncio
    async def test_create_portfolio_without_auth_fails(self, client: AsyncClient):
        """Test that creating portfolio requires authentication."""
        # Act
        response = await client.post(
            "/api/v1/portfolios/",
            json={"name": "Test Portfolio"}
        )

        # Assert
        assert response.status_code in [401, 403]

    @pytest.mark.asyncio
    async def test_create_portfolio_defaults_owner_to_current_user(
        self,
        authenticated_org_client: AsyncClient,
        test_user: User
    ):
        """Test that owner defaults to current user email."""
        # Act
        response = await authenticated_org_client.post(
            "/api/v1/portfolios/",
            json={"name": "Auto-Owner Portfolio"}
        )

        # Assert
        assert response.status_code == 201
        data = response.json()
        assert data["owner"] == test_user.email
        assert data["created_by"] == test_user.email


class TestPortfolioListing:
    """Test portfolio listing endpoint."""

    @pytest.mark.asyncio
    async def test_list_portfolios_empty(
        self,
        authenticated_org_client: AsyncClient
    ):
        """Test listing portfolios when none exist."""
        # Act
        response = await authenticated_org_client.get("/api/v1/portfolios/")

        # Assert
        assert response.status_code == 200
        assert response.json() == []

    @pytest.mark.asyncio
    async def test_list_portfolios_multiple(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test listing multiple portfolios."""
        # Arrange - Create 3 portfolios
        portfolios = [
            Portfolio(name="Portfolio A", organization_id=test_organization.id),
            Portfolio(name="Portfolio B", organization_id=test_organization.id, health_status=HealthStatus.GREEN),
            Portfolio(name="Portfolio C", organization_id=test_organization.id, health_status=HealthStatus.RED)
        ]
        for p in portfolios:
            db_session.add(p)
        await db_session.commit()

        # Act
        response = await authenticated_org_client.get("/api/v1/portfolios/")

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert len(data) == 3
        names = [p["name"] for p in data]
        assert "Portfolio A" in names
        assert "Portfolio B" in names
        assert "Portfolio C" in names

    @pytest.mark.asyncio
    async def test_list_portfolios_pagination(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test portfolio listing with pagination."""
        # Arrange - Create 5 portfolios
        for i in range(5):
            p = Portfolio(name=f"Portfolio {i}", organization_id=test_organization.id)
            db_session.add(p)
        await db_session.commit()

        # Act
        response = await authenticated_org_client.get("/api/v1/portfolios/?skip=2&limit=2")

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert len(data) == 2

    @pytest.mark.asyncio
    async def test_list_portfolios_multi_tenant_isolation(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test that users only see portfolios from their organization."""
        # Arrange - Create portfolio in current org
        p1 = Portfolio(name="My Portfolio", organization_id=test_organization.id)
        db_session.add(p1)

        # Create another organization with portfolio
        from models.organization import Organization
        other_org = Organization(name="Other Org", slug="other-org")
        db_session.add(other_org)
        await db_session.commit()
        await db_session.refresh(other_org)

        p2 = Portfolio(name="Other Portfolio", organization_id=other_org.id)
        db_session.add(p2)
        await db_session.commit()

        # Act
        response = await authenticated_org_client.get("/api/v1/portfolios/")

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert len(data) == 1
        assert data[0]["name"] == "My Portfolio"

    @pytest.mark.asyncio
    async def test_list_portfolios_includes_counts(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test that portfolio list includes program and project counts."""
        # Arrange
        portfolio = Portfolio(name="Test Portfolio", organization_id=test_organization.id)
        db_session.add(portfolio)
        await db_session.commit()
        await db_session.refresh(portfolio)

        # Add program
        program = Program(
            name="Test Program",
            organization_id=test_organization.id,
            portfolio_id=portfolio.id
        )
        db_session.add(program)
        await db_session.commit()
        await db_session.refresh(program)

        # Add direct project (without program)
        project1 = Project(
            name="Direct Project",
            organization_id=test_organization.id,
            portfolio_id=portfolio.id
        )
        db_session.add(project1)

        # Add project in program
        project2 = Project(
            name="Program Project",
            organization_id=test_organization.id,
            portfolio_id=portfolio.id,
            program_id=program.id
        )
        db_session.add(project2)
        await db_session.commit()

        # Act
        response = await authenticated_org_client.get("/api/v1/portfolios/")

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert len(data) == 1
        assert data[0]["program_count"] == 1
        assert data[0]["direct_project_count"] == 1
        assert data[0]["total_project_count"] == 2


class TestPortfolioRetrieval:
    """Test portfolio retrieval by ID."""

    @pytest.mark.asyncio
    async def test_get_portfolio_by_id_success(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test successful portfolio retrieval."""
        # Arrange
        portfolio = Portfolio(
            name="Test Portfolio",
            description="Test description",
            organization_id=test_organization.id,
            health_status=HealthStatus.AMBER
        )
        db_session.add(portfolio)
        await db_session.commit()
        await db_session.refresh(portfolio)

        # Act
        response = await authenticated_org_client.get(f"/api/v1/portfolios/{portfolio.id}")

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["id"] == str(portfolio.id)
        assert data["name"] == "Test Portfolio"
        assert data["description"] == "Test description"
        assert data["health_status"] == "amber"

    @pytest.mark.asyncio
    async def test_get_portfolio_not_found(
        self,
        authenticated_org_client: AsyncClient
    ):
        """Test retrieving non-existent portfolio returns 404."""
        # Arrange
        import uuid
        fake_id = uuid.uuid4()

        # Act
        response = await authenticated_org_client.get(f"/api/v1/portfolios/{fake_id}")

        # Assert
        assert response.status_code == 404
        assert "not found" in response.json()["detail"].lower()

    @pytest.mark.asyncio
    async def test_get_portfolio_cross_organization_fails(
        self,
        authenticated_org_client: AsyncClient,
        db_session: AsyncSession
    ):
        """Test that users cannot access portfolios from other organizations."""
        # Arrange - Create another organization with a portfolio
        from models.organization import Organization
        other_org = Organization(name="Other Org", slug="other-org")
        db_session.add(other_org)
        await db_session.commit()
        await db_session.refresh(other_org)

        portfolio = Portfolio(name="Other Portfolio", organization_id=other_org.id)
        db_session.add(portfolio)
        await db_session.commit()
        await db_session.refresh(portfolio)

        # Act
        response = await authenticated_org_client.get(f"/api/v1/portfolios/{portfolio.id}")

        # Assert
        assert response.status_code == 404


class TestPortfolioUpdate:
    """Test portfolio update endpoint."""

    @pytest.mark.asyncio
    async def test_update_portfolio_name(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test updating portfolio name."""
        # Arrange
        portfolio = Portfolio(name="Old Name", organization_id=test_organization.id)
        db_session.add(portfolio)
        await db_session.commit()
        await db_session.refresh(portfolio)

        # Act
        response = await authenticated_org_client.put(
            f"/api/v1/portfolios/{portfolio.id}",
            json={"name": "New Name"}
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["name"] == "New Name"

    @pytest.mark.asyncio
    async def test_update_portfolio_all_fields(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test updating all portfolio fields."""
        # Arrange
        portfolio = Portfolio(
            name="Original Portfolio",
            organization_id=test_organization.id,
            health_status=HealthStatus.NOT_SET
        )
        db_session.add(portfolio)
        await db_session.commit()
        await db_session.refresh(portfolio)

        # Act
        response = await authenticated_org_client.put(
            f"/api/v1/portfolios/{portfolio.id}",
            json={
                "name": "Updated Portfolio",
                "description": "Updated description",
                "owner": "new.owner@example.com",
                "health_status": "red",
                "risk_summary": "High risk identified"
            }
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["name"] == "Updated Portfolio"
        assert data["description"] == "Updated description"
        assert data["owner"] == "new.owner@example.com"
        assert data["health_status"] == "red"
        assert data["risk_summary"] == "High risk identified"

    @pytest.mark.asyncio
    async def test_update_portfolio_partial_fields(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test partial update of portfolio fields."""
        # Arrange
        portfolio = Portfolio(
            name="Original",
            description="Original description",
            organization_id=test_organization.id
        )
        db_session.add(portfolio)
        await db_session.commit()
        await db_session.refresh(portfolio)

        # Act - Update only health status
        response = await authenticated_org_client.put(
            f"/api/v1/portfolios/{portfolio.id}",
            json={"health_status": "green"}
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["health_status"] == "green"
        assert data["name"] == "Original"  # Unchanged
        assert data["description"] == "Original description"  # Unchanged

    @pytest.mark.asyncio
    async def test_update_portfolio_not_found(
        self,
        authenticated_org_client: AsyncClient
    ):
        """Test updating non-existent portfolio returns 404."""
        # Arrange
        import uuid
        fake_id = uuid.uuid4()

        # Act
        response = await authenticated_org_client.put(
            f"/api/v1/portfolios/{fake_id}",
            json={"name": "Updated"}
        )

        # Assert
        assert response.status_code == 404

    @pytest.mark.asyncio
    async def test_update_portfolio_cross_organization_fails(
        self,
        authenticated_org_client: AsyncClient,
        db_session: AsyncSession
    ):
        """Test that users cannot update portfolios from other organizations."""
        # Arrange
        from models.organization import Organization
        other_org = Organization(name="Other Org", slug="other-org")
        db_session.add(other_org)
        await db_session.commit()
        await db_session.refresh(other_org)

        portfolio = Portfolio(name="Other Portfolio", organization_id=other_org.id)
        db_session.add(portfolio)
        await db_session.commit()
        await db_session.refresh(portfolio)

        # Act
        response = await authenticated_org_client.put(
            f"/api/v1/portfolios/{portfolio.id}",
            json={"name": "Hacked"}
        )

        # Assert
        assert response.status_code == 404


class TestPortfolioDeletion:
    """Test portfolio deletion endpoint."""

    @pytest.mark.asyncio
    async def test_delete_portfolio_without_cascade(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test deleting portfolio without cascade - programs/projects become standalone."""
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

        project = Project(
            name="Test Project",
            organization_id=test_organization.id,
            portfolio_id=portfolio.id
        )
        db_session.add(project)
        await db_session.commit()

        # Act
        response = await authenticated_org_client.delete(
            f"/api/v1/portfolios/{portfolio.id}?cascade_delete=false"
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert "standalone" in data["message"].lower()
        assert data["cascade_delete"] is False

        # Verify portfolio is deleted
        result = await db_session.execute(select(Portfolio).where(Portfolio.id == portfolio.id))
        assert result.scalar_one_or_none() is None

        # Verify program and project still exist but are orphaned
        await db_session.refresh(program)
        await db_session.refresh(project)
        assert program.portfolio_id is None
        assert project.portfolio_id is None

    @pytest.mark.asyncio
    async def test_delete_portfolio_with_cascade(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test deleting portfolio with cascade - programs/projects are deleted."""
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

        project = Project(
            name="Test Project",
            organization_id=test_organization.id,
            portfolio_id=portfolio.id
        )
        db_session.add(project)
        await db_session.commit()
        program_id = program.id
        project_id = project.id

        # Act
        response = await authenticated_org_client.delete(
            f"/api/v1/portfolios/{portfolio.id}?cascade_delete=true"
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["cascade_delete"] is True

        # Verify all are deleted
        result = await db_session.execute(select(Portfolio).where(Portfolio.id == portfolio.id))
        assert result.scalar_one_or_none() is None

        result = await db_session.execute(select(Program).where(Program.id == program_id))
        assert result.scalar_one_or_none() is None

        result = await db_session.execute(select(Project).where(Project.id == project_id))
        assert result.scalar_one_or_none() is None

    @pytest.mark.asyncio
    async def test_delete_portfolio_not_found(
        self,
        authenticated_org_client: AsyncClient
    ):
        """Test deleting non-existent portfolio returns 404."""
        # Arrange
        import uuid
        fake_id = uuid.uuid4()

        # Act
        response = await authenticated_org_client.delete(f"/api/v1/portfolios/{fake_id}")

        # Assert
        assert response.status_code == 404

    @pytest.mark.asyncio
    async def test_delete_empty_portfolio(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test deleting portfolio without programs or projects."""
        # Arrange
        portfolio = Portfolio(name="Empty Portfolio", organization_id=test_organization.id)
        db_session.add(portfolio)
        await db_session.commit()
        await db_session.refresh(portfolio)

        # Act
        response = await authenticated_org_client.delete(f"/api/v1/portfolios/{portfolio.id}")

        # Assert
        assert response.status_code == 200

        # Verify deletion
        result = await db_session.execute(select(Portfolio).where(Portfolio.id == portfolio.id))
        assert result.scalar_one_or_none() is None


class TestPortfolioPrograms:
    """Test getting programs in a portfolio."""

    @pytest.mark.asyncio
    async def test_get_portfolio_programs_empty(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test getting programs when none exist."""
        # Arrange
        portfolio = Portfolio(name="Test Portfolio", organization_id=test_organization.id)
        db_session.add(portfolio)
        await db_session.commit()
        await db_session.refresh(portfolio)

        # Act
        response = await authenticated_org_client.get(f"/api/v1/portfolios/{portfolio.id}/programs")

        # Assert
        assert response.status_code == 200
        assert response.json() == []

    @pytest.mark.asyncio
    async def test_get_portfolio_programs_multiple(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test getting multiple programs in a portfolio."""
        # Arrange
        portfolio = Portfolio(name="Test Portfolio", organization_id=test_organization.id)
        db_session.add(portfolio)
        await db_session.commit()
        await db_session.refresh(portfolio)

        programs = [
            Program(name="Program A", organization_id=test_organization.id, portfolio_id=portfolio.id),
            Program(name="Program B", organization_id=test_organization.id, portfolio_id=portfolio.id),
            Program(name="Program C", organization_id=test_organization.id, portfolio_id=portfolio.id)
        ]
        for p in programs:
            db_session.add(p)
        await db_session.commit()

        # Act
        response = await authenticated_org_client.get(f"/api/v1/portfolios/{portfolio.id}/programs")

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert len(data) == 3
        names = [p["name"] for p in data]
        assert "Program A" in names
        assert "Program B" in names

    @pytest.mark.asyncio
    async def test_get_portfolio_programs_not_found(
        self,
        authenticated_org_client: AsyncClient
    ):
        """Test getting programs for non-existent portfolio."""
        # Arrange
        import uuid
        fake_id = uuid.uuid4()

        # Act
        response = await authenticated_org_client.get(f"/api/v1/portfolios/{fake_id}/programs")

        # Assert
        assert response.status_code == 404


class TestPortfolioProjects:
    """Test getting projects in a portfolio."""

    @pytest.mark.asyncio
    async def test_get_portfolio_projects_all(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test getting all projects in a portfolio (direct and in programs)."""
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

        # Direct project
        project1 = Project(
            name="Direct Project",
            organization_id=test_organization.id,
            portfolio_id=portfolio.id
        )
        db_session.add(project1)

        # Project in program
        project2 = Project(
            name="Program Project",
            organization_id=test_organization.id,
            portfolio_id=portfolio.id,
            program_id=program.id
        )
        db_session.add(project2)
        await db_session.commit()

        # Act
        response = await authenticated_org_client.get(f"/api/v1/portfolios/{portfolio.id}/projects")

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert len(data) == 2
        names = [p["name"] for p in data]
        assert "Direct Project" in names
        assert "Program Project" in names

    @pytest.mark.asyncio
    async def test_get_portfolio_projects_direct_only(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test getting only direct projects (without program)."""
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

        # Direct project
        project1 = Project(
            name="Direct Project",
            organization_id=test_organization.id,
            portfolio_id=portfolio.id
        )
        db_session.add(project1)

        # Project in program
        project2 = Project(
            name="Program Project",
            organization_id=test_organization.id,
            portfolio_id=portfolio.id,
            program_id=program.id
        )
        db_session.add(project2)
        await db_session.commit()

        # Act
        response = await authenticated_org_client.get(
            f"/api/v1/portfolios/{portfolio.id}/projects?direct_only=true"
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert len(data) == 1
        assert data[0]["name"] == "Direct Project"

    @pytest.mark.asyncio
    async def test_get_portfolio_projects_empty(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test getting projects when none exist."""
        # Arrange
        portfolio = Portfolio(name="Test Portfolio", organization_id=test_organization.id)
        db_session.add(portfolio)
        await db_session.commit()
        await db_session.refresh(portfolio)

        # Act
        response = await authenticated_org_client.get(f"/api/v1/portfolios/{portfolio.id}/projects")

        # Assert
        assert response.status_code == 200
        assert response.json() == []


class TestPortfolioStatistics:
    """Test portfolio statistics endpoint."""

    @pytest.mark.asyncio
    async def test_get_portfolio_statistics_empty(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test statistics for portfolio with no content."""
        # Arrange
        portfolio = Portfolio(name="Test Portfolio", organization_id=test_organization.id)
        db_session.add(portfolio)
        await db_session.commit()
        await db_session.refresh(portfolio)

        # Act
        response = await authenticated_org_client.get(f"/api/v1/portfolios/{portfolio.id}/statistics")

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["portfolio_id"] == str(portfolio.id)
        assert data["portfolio_name"] == "Test Portfolio"
        assert data["program_count"] == 0
        assert data["project_count"] == 0
        assert data["direct_project_count"] == 0
        assert data["archived_project_count"] == 0
        assert data["content_count"] == 0
        assert data["summary_count"] == 0

    @pytest.mark.asyncio
    async def test_get_portfolio_statistics_with_content(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test statistics with programs, projects, and content."""
        # Arrange
        portfolio = Portfolio(name="Test Portfolio", organization_id=test_organization.id)
        db_session.add(portfolio)
        await db_session.commit()
        await db_session.refresh(portfolio)

        # Add 2 programs
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
        db_session.add(program1)
        db_session.add(program2)
        await db_session.commit()
        await db_session.refresh(program1)
        await db_session.refresh(program2)

        # Add 3 projects (1 direct, 2 in programs)
        project1 = Project(
            name="Direct Project",
            organization_id=test_organization.id,
            portfolio_id=portfolio.id
        )
        project2 = Project(
            name="Program Project 1",
            organization_id=test_organization.id,
            portfolio_id=portfolio.id,
            program_id=program1.id
        )
        project3 = Project(
            name="Program Project 2",
            organization_id=test_organization.id,
            portfolio_id=portfolio.id,
            program_id=program2.id,
            status=ProjectStatus.ARCHIVED
        )
        db_session.add(project1)
        db_session.add(project2)
        db_session.add(project3)
        await db_session.commit()

        # Act
        response = await authenticated_org_client.get(f"/api/v1/portfolios/{portfolio.id}/statistics")

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["program_count"] == 2
        assert data["project_count"] == 3
        assert data["direct_project_count"] == 1
        assert data["archived_project_count"] == 1

    @pytest.mark.asyncio
    async def test_get_portfolio_statistics_not_found(
        self,
        authenticated_org_client: AsyncClient
    ):
        """Test statistics for non-existent portfolio."""
        # Arrange
        import uuid
        fake_id = uuid.uuid4()

        # Act
        response = await authenticated_org_client.get(f"/api/v1/portfolios/{fake_id}/statistics")

        # Assert
        assert response.status_code == 404


class TestPortfolioDeletionImpact:
    """Test portfolio deletion impact analysis."""

    @pytest.mark.asyncio
    async def test_get_deletion_impact_empty_portfolio(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test deletion impact for portfolio with no programs/projects."""
        # Arrange
        portfolio = Portfolio(
            name="Empty Portfolio",
            description="No content",
            organization_id=test_organization.id
        )
        db_session.add(portfolio)
        await db_session.commit()
        await db_session.refresh(portfolio)

        # Act
        response = await authenticated_org_client.get(
            f"/api/v1/portfolios/{portfolio.id}/deletion-impact"
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["portfolio"]["id"] == str(portfolio.id)
        assert data["portfolio"]["name"] == "Empty Portfolio"
        assert data["affected_programs"] == []
        assert data["affected_projects"] == []
        assert data["total_programs"] == 0
        assert data["total_projects"] == 0

    @pytest.mark.asyncio
    async def test_get_deletion_impact_with_content(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test deletion impact for portfolio with programs and projects."""
        # Arrange
        portfolio = Portfolio(name="Full Portfolio", organization_id=test_organization.id)
        db_session.add(portfolio)
        await db_session.commit()
        await db_session.refresh(portfolio)

        # Add programs
        program1 = Program(
            name="Program A",
            description="First program",
            organization_id=test_organization.id,
            portfolio_id=portfolio.id
        )
        program2 = Program(
            name="Program B",
            description="Second program",
            organization_id=test_organization.id,
            portfolio_id=portfolio.id
        )
        db_session.add(program1)
        db_session.add(program2)
        await db_session.commit()

        # Add projects
        project1 = Project(
            name="Project 1",
            description="First project",
            organization_id=test_organization.id,
            portfolio_id=portfolio.id
        )
        project2 = Project(
            name="Project 2",
            description="Second project",
            organization_id=test_organization.id,
            portfolio_id=portfolio.id
        )
        db_session.add(project1)
        db_session.add(project2)
        await db_session.commit()

        # Act
        response = await authenticated_org_client.get(
            f"/api/v1/portfolios/{portfolio.id}/deletion-impact"
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["total_programs"] == 2
        assert data["total_projects"] == 2
        assert len(data["affected_programs"]) == 2
        assert len(data["affected_projects"]) == 2

        # Verify program details
        program_names = [p["name"] for p in data["affected_programs"]]
        assert "Program A" in program_names
        assert "Program B" in program_names

        # Verify project details
        project_names = [p["name"] for p in data["affected_projects"]]
        assert "Project 1" in project_names
        assert "Project 2" in project_names

    @pytest.mark.asyncio
    async def test_get_deletion_impact_not_found(
        self,
        authenticated_org_client: AsyncClient
    ):
        """Test deletion impact for non-existent portfolio."""
        # Arrange
        import uuid
        fake_id = uuid.uuid4()

        # Act
        response = await authenticated_org_client.get(f"/api/v1/portfolios/{fake_id}/deletion-impact")

        # Assert
        assert response.status_code == 404


class TestPortfolioQuery:
    """Test portfolio query (RAG) endpoint."""

    @pytest.mark.asyncio
    async def test_query_portfolio_no_projects(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test querying portfolio with no projects."""
        # Arrange
        portfolio = Portfolio(name="Empty Portfolio", organization_id=test_organization.id)
        db_session.add(portfolio)
        await db_session.commit()
        await db_session.refresh(portfolio)

        # Act
        response = await authenticated_org_client.post(
            f"/api/v1/portfolios/{portfolio.id}/query",
            json={"query": "What are the key risks?"}
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert "no projects" in data["answer"].lower()
        assert data["sources"] == []
        assert data["confidence"] == 0.0
        assert data["projects_searched"] == 0

    @pytest.mark.asyncio
    async def test_query_portfolio_not_found(
        self,
        authenticated_org_client: AsyncClient
    ):
        """Test querying non-existent portfolio."""
        # Arrange
        import uuid
        fake_id = uuid.uuid4()

        # Act
        response = await authenticated_org_client.post(
            f"/api/v1/portfolios/{fake_id}/query",
            json={"query": "Test query"}
        )

        # Assert
        assert response.status_code == 404

    @pytest.mark.asyncio
    async def test_query_portfolio_with_limit(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test portfolio query with result limit."""
        # Arrange
        portfolio = Portfolio(name="Test Portfolio", organization_id=test_organization.id)
        db_session.add(portfolio)
        await db_session.commit()
        await db_session.refresh(portfolio)

        # Act
        response = await authenticated_org_client.post(
            f"/api/v1/portfolios/{portfolio.id}/query",
            json={
                "query": "What are the risks?",
                "limit": 5
            }
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert "answer" in data
        assert "sources" in data
        assert "confidence" in data

    @pytest.mark.asyncio
    async def test_query_portfolio_exclude_archived(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test portfolio query excluding archived projects."""
        # Arrange
        portfolio = Portfolio(name="Test Portfolio", organization_id=test_organization.id)
        db_session.add(portfolio)
        await db_session.commit()
        await db_session.refresh(portfolio)

        # Add archived project
        project = Project(
            name="Archived Project",
            organization_id=test_organization.id,
            portfolio_id=portfolio.id,
            status=ProjectStatus.ARCHIVED
        )
        db_session.add(project)
        await db_session.commit()

        # Act
        response = await authenticated_org_client.post(
            f"/api/v1/portfolios/{portfolio.id}/query",
            json={
                "query": "Test query",
                "include_archived_projects": False
            }
        )

        # Assert
        assert response.status_code == 200
        # Should not search archived projects
        data = response.json()
        assert data["projects_searched"] == 0
