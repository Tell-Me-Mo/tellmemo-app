"""
Integration tests for Content Availability API.

Covers TESTING_BACKEND.md section 5.3 - Content Availability (content_availability.py)

Status: TBD
"""

import pytest
from datetime import datetime, timedelta
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession
from models.user import User
from models.organization import Organization
from models.project import Project, ProjectStatus
from models.program import Program
from models.portfolio import Portfolio
from models.content import Content, ContentType
from models.summary import Summary, SummaryType


# ============================================================================
# Fixtures
# ============================================================================

@pytest.fixture
async def test_project_with_content(
    db_session: AsyncSession,
    test_organization: Organization,
    test_user: User
) -> Project:
    """Create a test project with content."""
    project = Project(
        name="Content Availability Test Project",
        description="Project with content for availability tests",
        organization_id=test_organization.id,
        created_by=str(test_user.id),
        status=ProjectStatus.ACTIVE
    )

    db_session.add(project)
    await db_session.commit()
    await db_session.refresh(project)

    # Add 5 pieces of content (3 meetings, 2 emails)
    for i in range(3):
        content = Content(
            project_id=project.id,
            content_type=ContentType.MEETING,
            title=f"Meeting {i+1}",
            content=f"Meeting transcript {i+1} content",
            uploaded_by=str(test_user.id),
            uploaded_at=datetime.utcnow() - timedelta(days=i)
        )
        db_session.add(content)

    for i in range(2):
        content = Content(
            project_id=project.id,
            content_type=ContentType.EMAIL,
            title=f"Email {i+1}",
            content=f"Email {i+1} content",
            uploaded_by=str(test_user.id),
            uploaded_at=datetime.utcnow() - timedelta(days=i+3)
        )
        db_session.add(content)

    await db_session.commit()

    return project


@pytest.fixture
async def test_program_with_content(
    db_session: AsyncSession,
    test_organization: Organization,
    test_user: User
) -> Program:
    """Create a test program with projects containing content."""
    program = Program(
        name="Test Program with Content",
        description="Program for availability tests",
        organization_id=test_organization.id,
        created_by=str(test_user.id)
    )

    db_session.add(program)
    await db_session.commit()
    await db_session.refresh(program)

    # Create 2 projects in the program with content
    for i in range(2):
        project = Project(
            name=f"Program Project {i+1}",
            description=f"Project {i+1} in program",
            organization_id=test_organization.id,
            program_id=program.id,
            created_by=str(test_user.id),
            status=ProjectStatus.ACTIVE
        )
        db_session.add(project)
        await db_session.flush()

        # Add content to each project
        for j in range(2):
            content = Content(
                project_id=project.id,
                content_type=ContentType.MEETING,
                title=f"Program Project {i+1} Meeting {j+1}",
                content=f"Content {j+1}",
                uploaded_by=str(test_user.id),
                uploaded_at=datetime.utcnow() - timedelta(days=j)
            )
            db_session.add(content)

    await db_session.commit()

    return program


@pytest.fixture
async def test_portfolio_with_content(
    db_session: AsyncSession,
    test_organization: Organization,
    test_user: User
) -> Portfolio:
    """Create a test portfolio with programs and projects containing content."""
    portfolio = Portfolio(
        name="Test Portfolio with Content",
        description="Portfolio for availability tests",
        organization_id=test_organization.id,
        created_by=str(test_user.id)
    )

    db_session.add(portfolio)
    await db_session.commit()
    await db_session.refresh(portfolio)

    # Create a program in the portfolio
    program = Program(
        name="Portfolio Program",
        description="Program in portfolio",
        organization_id=test_organization.id,
        portfolio_id=portfolio.id,
        created_by=str(test_user.id)
    )
    db_session.add(program)
    await db_session.flush()

    # Create project in the program
    project1 = Project(
        name="Portfolio Program Project",
        description="Project in program",
        organization_id=test_organization.id,
        program_id=program.id,
        portfolio_id=portfolio.id,
        created_by=str(test_user.id),
        status=ProjectStatus.ACTIVE
    )
    db_session.add(project1)
    await db_session.flush()

    # Add content to program project
    for i in range(2):
        content = Content(
            project_id=project1.id,
            content_type=ContentType.MEETING,
            title=f"Program Project Meeting {i+1}",
            content=f"Content {i+1}",
            uploaded_by=str(test_user.id),
            uploaded_at=datetime.utcnow() - timedelta(days=i)
        )
        db_session.add(content)

    # Create direct project in portfolio (not through program)
    project2 = Project(
        name="Direct Portfolio Project",
        description="Direct project in portfolio",
        organization_id=test_organization.id,
        portfolio_id=portfolio.id,
        created_by=str(test_user.id),
        status=ProjectStatus.ACTIVE
    )
    db_session.add(project2)
    await db_session.flush()

    # Add content to direct project
    for i in range(3):
        content = Content(
            project_id=project2.id,
            content_type=ContentType.EMAIL,
            title=f"Direct Project Email {i+1}",
            content=f"Content {i+1}",
            uploaded_by=str(test_user.id),
            uploaded_at=datetime.utcnow() - timedelta(days=i+2)
        )
        db_session.add(content)

    await db_session.commit()

    return portfolio


@pytest.fixture
async def test_project_with_summaries(
    db_session: AsyncSession,
    test_project_with_content: Project,
    test_organization: Organization,
    test_user: User
) -> Project:
    """Add summaries to test project."""
    # Create 3 summaries for the project
    for i in range(3):
        summary = Summary(
            organization_id=test_organization.id,
            project_id=test_project_with_content.id,
            summary_type=SummaryType.PROJECT,
            subject=f"Project Summary {i+1}",
            body=f"Summary body {i+1}",
            created_by=str(test_user.id),
            created_at=datetime.utcnow() - timedelta(days=i),
            generation_time_ms=1000 + i*100,
            format="general"
        )
        db_session.add(summary)

    await db_session.commit()

    return test_project_with_content


# ============================================================================
# Test: Check Content Availability for Project
# ============================================================================

@pytest.mark.asyncio
async def test_check_project_content_availability_with_content(
    authenticated_org_client: AsyncClient,
    test_project_with_content: Project
):
    """Test checking content availability for a project with content."""
    response = await authenticated_org_client.get(
        f"/api/content-availability/check/project/{test_project_with_content.id}"
    )

    assert response.status_code == 200
    data = response.json()

    assert data["has_content"] is True
    assert data["content_count"] == 5
    assert data["can_generate_summary"] is True
    assert data["latest_content_date"] is not None
    assert data["content_breakdown"] is not None
    assert data["content_breakdown"]["meeting"] == 3
    assert data["content_breakdown"]["email"] == 2
    assert "Sufficient content available" in data["message"]


@pytest.mark.asyncio
async def test_check_project_content_availability_empty_project(
    authenticated_org_client: AsyncClient,
    db_session: AsyncSession,
    test_organization: Organization,
    test_user: User
):
    """Test checking content availability for a project without content."""
    project = Project(
        name="Empty Project",
        description="Project with no content",
        organization_id=test_organization.id,
        created_by=str(test_user.id),
        status=ProjectStatus.ACTIVE
    )
    db_session.add(project)
    await db_session.commit()
    await db_session.refresh(project)

    response = await authenticated_org_client.get(
        f"/api/content-availability/check/project/{project.id}"
    )

    assert response.status_code == 200
    data = response.json()

    assert data["has_content"] is False
    assert data["content_count"] == 0
    assert data["can_generate_summary"] is False
    assert data["latest_content_date"] is None
    assert "No content available" in data["message"]


@pytest.mark.asyncio
async def test_check_project_content_availability_with_date_filter(
    authenticated_org_client: AsyncClient,
    test_project_with_content: Project
):
    """Test checking content availability with date range filter."""
    # Filter to content from last 3 days (should get all 5 items)
    date_start = (datetime.utcnow() - timedelta(days=5)).isoformat()
    date_end = datetime.utcnow().isoformat()

    response = await authenticated_org_client.get(
        f"/api/content-availability/check/project/{test_project_with_content.id}",
        params={
            "date_start": date_start,
            "date_end": date_end
        }
    )

    assert response.status_code == 200
    data = response.json()

    # Should find all content (5 items)
    assert data["has_content"] is True
    assert data["content_count"] == 5
    assert data["can_generate_summary"] is True


# ============================================================================
# Test: Check Content Availability for Program
# ============================================================================

@pytest.mark.asyncio
async def test_check_program_content_availability_with_content(
    authenticated_org_client: AsyncClient,
    test_program_with_content: Program
):
    """Test checking content availability for a program with content."""
    response = await authenticated_org_client.get(
        f"/api/content-availability/check/program/{test_program_with_content.id}"
    )

    assert response.status_code == 200
    data = response.json()

    assert data["has_content"] is True
    assert data["content_count"] == 4  # 2 projects × 2 content each
    assert data["project_count"] == 2
    assert data["projects_with_content"] == 2
    assert data["can_generate_summary"] is True
    assert data["project_content_breakdown"] is not None
    assert "Sufficient content available" in data["message"]


@pytest.mark.asyncio
async def test_check_program_content_availability_empty_program(
    authenticated_org_client: AsyncClient,
    db_session: AsyncSession,
    test_organization: Organization,
    test_user: User
):
    """Test checking content availability for a program without projects."""
    program = Program(
        name="Empty Program",
        description="Program with no projects",
        organization_id=test_organization.id,
        created_by=str(test_user.id)
    )
    db_session.add(program)
    await db_session.commit()
    await db_session.refresh(program)

    response = await authenticated_org_client.get(
        f"/api/content-availability/check/program/{program.id}"
    )

    assert response.status_code == 200
    data = response.json()

    assert data["has_content"] is False
    assert data["content_count"] == 0
    assert data["project_count"] == 0
    assert data["projects_with_content"] == 0
    assert data["can_generate_summary"] is False
    assert "No projects found" in data["message"]


# ============================================================================
# Test: Check Content Availability for Portfolio
# ============================================================================

@pytest.mark.asyncio
async def test_check_portfolio_content_availability_with_content(
    authenticated_org_client: AsyncClient,
    test_portfolio_with_content: Portfolio
):
    """Test checking content availability for a portfolio with content."""
    response = await authenticated_org_client.get(
        f"/api/content-availability/check/portfolio/{test_portfolio_with_content.id}"
    )

    assert response.status_code == 200
    data = response.json()

    assert data["has_content"] is True
    assert data["content_count"] == 5  # 2 from program project + 3 from direct project
    assert data["program_count"] == 1
    assert data["project_count"] == 2
    assert data["projects_with_content"] == 2
    assert data["can_generate_summary"] is True
    assert data["program_breakdown"] is not None
    assert "Sufficient content available" in data["message"]


@pytest.mark.asyncio
async def test_check_portfolio_content_availability_empty_portfolio(
    authenticated_org_client: AsyncClient,
    db_session: AsyncSession,
    test_organization: Organization,
    test_user: User
):
    """Test checking content availability for a portfolio without projects."""
    portfolio = Portfolio(
        name="Empty Portfolio",
        description="Portfolio with no projects",
        organization_id=test_organization.id,
        created_by=str(test_user.id)
    )
    db_session.add(portfolio)
    await db_session.commit()
    await db_session.refresh(portfolio)

    response = await authenticated_org_client.get(
        f"/api/content-availability/check/portfolio/{portfolio.id}"
    )

    assert response.status_code == 200
    data = response.json()

    assert data["has_content"] is False
    assert data["content_count"] == 0
    assert data["program_count"] == 0
    assert data["project_count"] == 0
    assert data["projects_with_content"] == 0
    assert data["can_generate_summary"] is False
    assert "No projects found" in data["message"]


# ============================================================================
# Test: Validation
# ============================================================================

@pytest.mark.asyncio
async def test_check_content_availability_invalid_entity_type(
    authenticated_org_client: AsyncClient,
    test_project_with_content: Project
):
    """Test checking content availability with invalid entity type."""
    response = await authenticated_org_client.get(
        f"/api/content-availability/check/invalid_type/{test_project_with_content.id}"
    )

    assert response.status_code == 400
    assert "Invalid entity type" in response.json()["detail"]


@pytest.mark.asyncio
async def test_check_content_availability_invalid_uuid(
    authenticated_org_client: AsyncClient
):
    """Test checking content availability with invalid UUID format."""
    response = await authenticated_org_client.get(
        "/api/content-availability/check/project/invalid-uuid"
    )

    assert response.status_code == 400
    assert "Invalid entity ID format" in response.json()["detail"]


# ============================================================================
# Test: Summary Statistics
# ============================================================================

@pytest.mark.asyncio
async def test_get_summary_statistics_with_summaries(
    authenticated_org_client: AsyncClient,
    test_project_with_summaries: Project
):
    """Test getting summary statistics for a project with summaries."""
    response = await authenticated_org_client.get(
        f"/api/content-availability/stats/project/{test_project_with_summaries.id}"
    )

    assert response.status_code == 200
    data = response.json()

    assert data["total_summaries"] == 3
    assert data["last_generated"] is not None
    assert data["average_generation_time"] > 0
    assert data["formats_generated"] == ["general"]
    assert data["type_breakdown"] is not None
    assert data["type_breakdown"]["project"] == 3
    assert data["recent_summary_id"] is not None


@pytest.mark.asyncio
async def test_get_summary_statistics_no_summaries(
    authenticated_org_client: AsyncClient,
    test_project_with_content: Project
):
    """Test getting summary statistics for a project without summaries."""
    response = await authenticated_org_client.get(
        f"/api/content-availability/stats/project/{test_project_with_content.id}"
    )

    assert response.status_code == 200
    data = response.json()

    assert data["total_summaries"] == 0
    assert data["last_generated"] is None
    assert data["average_generation_time"] == 0
    assert data["formats_generated"] == []


@pytest.mark.asyncio
async def test_get_summary_statistics_invalid_entity_type(
    authenticated_org_client: AsyncClient,
    test_project_with_content: Project
):
    """Test getting summary statistics with invalid entity type."""
    response = await authenticated_org_client.get(
        f"/api/content-availability/stats/invalid_type/{test_project_with_content.id}"
    )

    assert response.status_code == 400
    assert "Invalid entity type" in response.json()["detail"]


@pytest.mark.asyncio
async def test_get_summary_statistics_invalid_uuid(
    authenticated_org_client: AsyncClient
):
    """Test getting summary statistics with invalid UUID format."""
    response = await authenticated_org_client.get(
        "/api/content-availability/stats/project/invalid-uuid"
    )

    assert response.status_code == 400
    assert "Invalid entity ID format" in response.json()["detail"]


# ============================================================================
# Test: Batch Check Availability
# ============================================================================

@pytest.mark.asyncio
async def test_batch_check_availability_multiple_entities(
    authenticated_org_client: AsyncClient,
    test_project_with_content: Project,
    test_program_with_content: Program,
    test_portfolio_with_content: Portfolio
):
    """Test batch checking content availability for multiple entities."""
    entities = [
        {"type": "project", "id": str(test_project_with_content.id)},
        {"type": "program", "id": str(test_program_with_content.id)},
        {"type": "portfolio", "id": str(test_portfolio_with_content.id)}
    ]

    response = await authenticated_org_client.post(
        "/api/content-availability/batch-check",
        json=entities
    )

    assert response.status_code == 200
    data = response.json()

    # Check all entities returned
    assert str(test_project_with_content.id) in data
    assert str(test_program_with_content.id) in data
    assert str(test_portfolio_with_content.id) in data

    # Check project data
    project_data = data[str(test_project_with_content.id)]
    assert project_data["has_content"] is True
    assert project_data["content_count"] == 5

    # Check program data
    program_data = data[str(test_program_with_content.id)]
    assert program_data["has_content"] is True
    assert program_data["content_count"] == 4

    # Check portfolio data
    portfolio_data = data[str(test_portfolio_with_content.id)]
    assert portfolio_data["has_content"] is True
    assert portfolio_data["content_count"] == 5


@pytest.mark.asyncio
async def test_batch_check_availability_with_date_filter(
    authenticated_org_client: AsyncClient,
    test_project_with_content: Project
):
    """Test batch checking content availability with date range filter."""
    entities = [
        {"type": "project", "id": str(test_project_with_content.id)}
    ]

    date_start = (datetime.utcnow() - timedelta(days=5)).isoformat()
    date_end = datetime.utcnow().isoformat()

    response = await authenticated_org_client.post(
        f"/api/content-availability/batch-check?date_start={date_start}&date_end={date_end}",
        json=entities
    )

    assert response.status_code == 200
    data = response.json()

    project_data = data[str(test_project_with_content.id)]
    assert project_data["content_count"] == 5  # All content


@pytest.mark.asyncio
async def test_batch_check_availability_invalid_entity_skipped(
    authenticated_org_client: AsyncClient,
    test_project_with_content: Project
):
    """Test batch checking handles invalid entities gracefully."""
    entities = [
        {"type": "project", "id": str(test_project_with_content.id)},
        {"type": "invalid_type", "id": "some-id"},  # Invalid type - should return error
        {"type": "project"},  # Missing ID - should be skipped
        {"id": "some-id"}  # Missing type - should be skipped
    ]

    response = await authenticated_org_client.post(
        "/api/content-availability/batch-check",
        json=entities
    )

    assert response.status_code == 200
    data = response.json()

    # Valid project should be in results with data
    assert str(test_project_with_content.id) in data
    assert data[str(test_project_with_content.id)]["has_content"] is True

    # Invalid UUID should be in results with error
    assert "some-id" in data
    assert "error" in data["some-id"]
    assert data["some-id"]["has_content"] is False

    # Entries with missing type or ID should be skipped entirely
    # Total should be 2 (valid project + invalid UUID with error)
    assert len(data) == 2


@pytest.mark.asyncio
async def test_batch_check_availability_empty_list(
    authenticated_org_client: AsyncClient
):
    """Test batch checking with empty entity list."""
    response = await authenticated_org_client.post(
        "/api/content-availability/batch-check",
        json=[]
    )

    assert response.status_code == 200
    data = response.json()
    assert data == {}


# ============================================================================
# Test: Multi-tenant Isolation
# ============================================================================

@pytest.mark.asyncio
async def test_check_content_availability_different_organization(
    client_factory,
    db_session: AsyncSession,
    test_user: User,
    test_project_with_content: Project
):
    """Test that content availability check respects multi-tenant isolation."""
    # Create a different organization
    from models.organization import Organization
    from models.organization_member import OrganizationMember
    from services.auth.native_auth_service import native_auth_service

    other_org = Organization(
        name="Other Organization",
        slug="other-organization",
        created_by=test_user.id
    )
    db_session.add(other_org)
    await db_session.commit()
    await db_session.refresh(other_org)

    # Add user as member
    member = OrganizationMember(
        organization_id=other_org.id,
        user_id=test_user.id,
        role="admin",
        invited_by=test_user.id,
        joined_at=datetime.utcnow()
    )
    db_session.add(member)
    await db_session.commit()

    # Create client for other org
    token = native_auth_service.create_access_token(
        user_id=str(test_user.id),
        email=test_user.email,
        organization_id=str(other_org.id)
    )
    other_org_client = await client_factory(
        Authorization=f"Bearer {token}",
        **{"X-Organization-Id": str(other_org.id)}
    )

    # Try to check content availability for project in different org
    response = await other_org_client.get(
        f"/api/content-availability/check/project/{test_project_with_content.id}"
    )

    # Should return 404 to prevent information disclosure
    assert response.status_code == 404
    assert "not found" in response.json()["detail"].lower()


# ============================================================================
# Test: Recent Summaries Count
# ============================================================================

@pytest.mark.asyncio
async def test_check_project_content_recent_summaries(
    authenticated_org_client: AsyncClient,
    test_project_with_summaries: Project
):
    """Test that recent summaries count is included in availability check."""
    response = await authenticated_org_client.get(
        f"/api/content-availability/check/project/{test_project_with_summaries.id}"
    )

    assert response.status_code == 200
    data = response.json()

    # Should show recent summaries (within last 7 days)
    assert data["recent_summaries_count"] == 3
