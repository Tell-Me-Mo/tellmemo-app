"""
Integration tests for Activity Feed API.

Covers TESTING_BACKEND.md section 12.2 - Activity Feed

Tests cover:
- Get project activities (with filtering and pagination)
- Get recent activities (across multiple projects with time filtering)
- Delete project activities (admin only)
- Multi-tenant isolation
- Authentication requirements
- Invalid input handling

Expected Status: Will test all activity feed endpoints and multi-tenant security
"""

import pytest
from datetime import datetime, timedelta
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession
from models.user import User
from models.organization import Organization
from models.organization_member import OrganizationMember
from models.project import Project, ProjectStatus
from models.activity import Activity, ActivityType
from services.auth.native_auth_service import native_auth_service


# ========================================
# Project Fixtures
# ========================================

@pytest.fixture
async def test_project(
    db_session: AsyncSession,
    test_organization: Organization,
    test_user: User
) -> Project:
    """Create a test project for activity tests."""
    project = Project(
        name="Activity Test Project",
        description="Project for testing activities",
        organization_id=test_organization.id,
        created_by=str(test_user.id),
        status=ProjectStatus.ACTIVE
    )

    db_session.add(project)
    await db_session.commit()
    await db_session.refresh(project)
    return project


@pytest.fixture
async def second_project(
    db_session: AsyncSession,
    test_organization: Organization,
    test_user: User
) -> Project:
    """Create a second test project."""
    project = Project(
        name="Second Activity Project",
        description="Second project for multi-project tests",
        organization_id=test_organization.id,
        created_by=str(test_user.id),
        status=ProjectStatus.ACTIVE
    )

    db_session.add(project)
    await db_session.commit()
    await db_session.refresh(project)
    return project


# ========================================
# Multi-tenant Fixtures
# ========================================

@pytest.fixture
async def second_organization(
    db_session: AsyncSession,
    test_user: User
) -> Organization:
    """Create a second organization for multi-tenant tests."""
    org = Organization(
        name="Second Organization",
        slug="second-organization",
        created_by=test_user.id
    )

    db_session.add(org)
    await db_session.commit()
    await db_session.refresh(org)
    return org


@pytest.fixture
async def second_org_user(
    db_session: AsyncSession
) -> User:
    """Create a user for second organization."""
    password_hash = native_auth_service.hash_password("SecondOrgPass123!")

    user = User(
        email="secondorg@example.com",
        password_hash=password_hash,
        name="Second Org User",
        auth_provider='native',
        email_verified=True,
        is_active=True
    )

    db_session.add(user)
    await db_session.commit()
    await db_session.refresh(user)
    return user


@pytest.fixture
async def second_org_admin(
    db_session: AsyncSession,
    second_organization: Organization,
    second_org_user: User
) -> User:
    """Create admin user for second organization."""
    # Add user as admin member
    member = OrganizationMember(
        organization_id=second_organization.id,
        user_id=second_org_user.id,
        role="admin",
        invited_by=second_org_user.id,
        joined_at=datetime.utcnow()
    )

    db_session.add(member)
    await db_session.commit()

    # Update user's last active organization
    second_org_user.last_active_organization_id = second_organization.id
    await db_session.commit()
    await db_session.refresh(second_org_user)

    return second_org_user


# ========================================
# Auth Fixtures
# ========================================

@pytest.fixture
async def admin_client(
    client_factory,
    test_user: User,
    test_organization: Organization
) -> AsyncClient:
    """Create an authenticated HTTP client with admin role."""
    token = native_auth_service.create_access_token(
        user_id=str(test_user.id),
        email=test_user.email,
        organization_id=str(test_organization.id)
    )
    return await client_factory(
        Authorization=f"Bearer {token}",
        **{"X-Organization-Id": str(test_organization.id)}
    )


# ========================================
# Activity Fixtures
# ========================================

@pytest.fixture
async def test_activity_1(
    db_session: AsyncSession,
    test_project: Project
) -> Activity:
    """Create first test activity."""
    activity = Activity(
        project_id=test_project.id,
        type=ActivityType.PROJECT_CREATED,
        title="Project created",
        description=f"New project '{test_project.name}' was created",
        activity_metadata='{"status": "active"}',
        user_id="user123",
        user_name="John Doe",
        timestamp=datetime.utcnow() - timedelta(hours=2)
    )
    db_session.add(activity)
    await db_session.commit()
    await db_session.refresh(activity)
    return activity


@pytest.fixture
async def test_activity_2(
    db_session: AsyncSession,
    test_project: Project
) -> Activity:
    """Create second test activity (content upload)."""
    activity = Activity(
        project_id=test_project.id,
        type=ActivityType.CONTENT_UPLOADED,
        title="Meeting uploaded",
        description="'Q1 Planning Meeting' was uploaded",
        activity_metadata='meeting',
        user_id="user456",
        user_name="Jane Smith",
        timestamp=datetime.utcnow() - timedelta(hours=1)
    )
    db_session.add(activity)
    await db_session.commit()
    await db_session.refresh(activity)
    return activity


@pytest.fixture
async def test_activity_3(
    db_session: AsyncSession,
    test_project: Project
) -> Activity:
    """Create third test activity (summary generated)."""
    activity = Activity(
        project_id=test_project.id,
        type=ActivityType.SUMMARY_GENERATED,
        title="Project summary generated",
        description="'Weekly Summary' was generated",
        activity_metadata='project',
        user_id="user123",
        user_name="John Doe",
        timestamp=datetime.utcnow() - timedelta(minutes=30)
    )
    db_session.add(activity)
    await db_session.commit()
    await db_session.refresh(activity)
    return activity


@pytest.fixture
async def test_activity_old(
    db_session: AsyncSession,
    test_project: Project
) -> Activity:
    """Create old test activity (beyond 24 hours)."""
    activity = Activity(
        project_id=test_project.id,
        type=ActivityType.QUERY_SUBMITTED,
        title="Query submitted",
        description="Question: What are the Q1 goals?",
        user_id="user123",
        user_name="John Doe",
        timestamp=datetime.utcnow() - timedelta(hours=30)
    )
    db_session.add(activity)
    await db_session.commit()
    await db_session.refresh(activity)
    return activity


@pytest.fixture
async def second_project_activity(
    db_session: AsyncSession,
    second_project: Project
) -> Activity:
    """Create activity for second project."""
    activity = Activity(
        project_id=second_project.id,
        type=ActivityType.MEMBER_ADDED,
        title="Member added",
        description="New member added to project",
        user_id="user789",
        user_name="Bob Wilson",
        timestamp=datetime.utcnow() - timedelta(minutes=15)
    )
    db_session.add(activity)
    await db_session.commit()
    await db_session.refresh(activity)
    return activity


# ========================================
# Test GET /api/projects/{project_id}/activities
# ========================================

@pytest.mark.asyncio
async def test_get_project_activities_success(
    authenticated_org_client: AsyncClient,
    test_project: Project,
    test_activity_1: Activity,
    test_activity_2: Activity,
    test_activity_3: Activity
):
    """Test getting activities for a project."""
    response = await authenticated_org_client.get(
        f"/api/projects/{test_project.id}/activities"
    )

    assert response.status_code == 200
    activities = response.json()

    # Should return all 3 activities, ordered by timestamp DESC (newest first)
    assert len(activities) == 3
    assert activities[0]["type"] == ActivityType.SUMMARY_GENERATED.value
    assert activities[1]["type"] == ActivityType.CONTENT_UPLOADED.value
    assert activities[2]["type"] == ActivityType.PROJECT_CREATED.value

    # Verify structure of first activity
    assert "id" in activities[0]
    assert "project_id" in activities[0]
    assert "type" in activities[0]
    assert "title" in activities[0]
    assert "description" in activities[0]
    assert "timestamp" in activities[0]
    assert "user_id" in activities[0]
    assert "user_name" in activities[0]


@pytest.mark.asyncio
async def test_get_project_activities_with_type_filter(
    authenticated_org_client: AsyncClient,
    test_project: Project,
    test_activity_1: Activity,
    test_activity_2: Activity,
    test_activity_3: Activity
):
    """Test filtering activities by type."""
    response = await authenticated_org_client.get(
        f"/api/projects/{test_project.id}/activities",
        params={"activity_type": ActivityType.CONTENT_UPLOADED.value}
    )

    assert response.status_code == 200
    activities = response.json()

    # Should only return content upload activity
    assert len(activities) == 1
    assert activities[0]["type"] == ActivityType.CONTENT_UPLOADED.value
    assert activities[0]["title"] == "Meeting uploaded"


@pytest.mark.asyncio
async def test_get_project_activities_with_since_filter(
    authenticated_org_client: AsyncClient,
    test_project: Project,
    test_activity_1: Activity,
    test_activity_2: Activity,
    test_activity_3: Activity
):
    """Test filtering activities by timestamp."""
    # Filter to only get activities from last 90 minutes
    since_time = (datetime.utcnow() - timedelta(minutes=90)).isoformat()

    response = await authenticated_org_client.get(
        f"/api/projects/{test_project.id}/activities",
        params={"since": since_time}
    )

    assert response.status_code == 200
    activities = response.json()

    # Should only return activities 2 and 3 (within 90 minutes)
    assert len(activities) == 2
    assert activities[0]["type"] == ActivityType.SUMMARY_GENERATED.value
    assert activities[1]["type"] == ActivityType.CONTENT_UPLOADED.value


@pytest.mark.asyncio
async def test_get_project_activities_with_pagination(
    authenticated_org_client: AsyncClient,
    test_project: Project,
    test_activity_1: Activity,
    test_activity_2: Activity,
    test_activity_3: Activity
):
    """Test pagination of activities."""
    # Get first page (limit 2)
    response = await authenticated_org_client.get(
        f"/api/projects/{test_project.id}/activities",
        params={"limit": 2, "offset": 0}
    )

    assert response.status_code == 200
    activities = response.json()
    assert len(activities) == 2

    # Get second page
    response = await authenticated_org_client.get(
        f"/api/projects/{test_project.id}/activities",
        params={"limit": 2, "offset": 2}
    )

    assert response.status_code == 200
    activities = response.json()
    assert len(activities) == 1


@pytest.mark.asyncio
async def test_get_project_activities_invalid_type(
    authenticated_org_client: AsyncClient,
    test_project: Project
):
    """Test filtering with invalid activity type."""
    response = await authenticated_org_client.get(
        f"/api/projects/{test_project.id}/activities",
        params={"activity_type": "invalid_type"}
    )

    assert response.status_code == 400
    assert "Invalid activity type" in response.json()["detail"]


@pytest.mark.asyncio
async def test_get_project_activities_empty_result(
    authenticated_org_client: AsyncClient,
    test_project: Project
):
    """Test getting activities for project with no activities."""
    response = await authenticated_org_client.get(
        f"/api/projects/{test_project.id}/activities"
    )

    assert response.status_code == 200
    activities = response.json()
    assert len(activities) == 0


@pytest.mark.asyncio
async def test_get_project_activities_invalid_project_id(
    authenticated_org_client: AsyncClient
):
    """Test getting activities with invalid project UUID."""
    response = await authenticated_org_client.get(
        "/api/projects/not-a-uuid/activities"
    )

    assert response.status_code == 422  # Validation error


@pytest.mark.asyncio
async def test_get_project_activities_requires_authentication(
    client: AsyncClient,
    test_project: Project,
    test_activity_1: Activity
):
    """Test that authentication is required."""
    response = await client.get(
        f"/api/projects/{test_project.id}/activities"
    )

    assert response.status_code in [401, 403]


# ========================================
# Test GET /api/activities/recent
# ========================================

@pytest.mark.asyncio
async def test_get_recent_activities_single_project(
    authenticated_org_client: AsyncClient,
    test_project: Project,
    test_activity_1: Activity,
    test_activity_2: Activity,
    test_activity_3: Activity,
    test_activity_old: Activity
):
    """Test getting recent activities for a single project."""
    response = await authenticated_org_client.get(
        "/api/activities/recent",
        params={
            "project_ids": str(test_project.id),
            "hours": 24,
            "limit": 20
        }
    )

    assert response.status_code == 200
    activities = response.json()

    # Should return 3 activities (excluding the 30-hour old one)
    assert len(activities) == 3

    # Should be ordered by timestamp DESC
    assert activities[0]["type"] == ActivityType.SUMMARY_GENERATED.value
    assert activities[1]["type"] == ActivityType.CONTENT_UPLOADED.value
    assert activities[2]["type"] == ActivityType.PROJECT_CREATED.value


@pytest.mark.asyncio
async def test_get_recent_activities_multiple_projects(
    authenticated_org_client: AsyncClient,
    test_project: Project,
    second_project: Project,
    test_activity_1: Activity,
    test_activity_3: Activity,
    second_project_activity: Activity
):
    """Test getting recent activities across multiple projects."""
    response = await authenticated_org_client.get(
        "/api/activities/recent",
        params={
            "project_ids": f"{test_project.id},{second_project.id}",
            "hours": 24,
            "limit": 20
        }
    )

    assert response.status_code == 200
    activities = response.json()

    # Should return activities from both projects
    assert len(activities) == 3

    # Should be ordered by timestamp DESC (newest first)
    assert activities[0]["type"] == ActivityType.MEMBER_ADDED.value
    assert str(activities[0]["project_id"]) == str(second_project.id)


@pytest.mark.asyncio
async def test_get_recent_activities_custom_time_range(
    authenticated_org_client: AsyncClient,
    test_project: Project,
    test_activity_1: Activity,
    test_activity_2: Activity,
    test_activity_3: Activity
):
    """Test getting recent activities with custom time range."""
    response = await authenticated_org_client.get(
        "/api/activities/recent",
        params={
            "project_ids": str(test_project.id),
            "hours": 1,  # Only last hour (should get activity_3 at 30min ago)
            "limit": 20
        }
    )

    assert response.status_code == 200
    activities = response.json()

    # Should only return activity 3 (within last hour - 30 minutes ago)
    # Activity 2 is 1 hour ago (exactly on the boundary, may or may not be included)
    assert len(activities) >= 1
    assert activities[0]["type"] == ActivityType.SUMMARY_GENERATED.value


@pytest.mark.asyncio
async def test_get_recent_activities_with_limit(
    authenticated_org_client: AsyncClient,
    test_project: Project,
    test_activity_1: Activity,
    test_activity_2: Activity,
    test_activity_3: Activity
):
    """Test limiting number of recent activities returned."""
    response = await authenticated_org_client.get(
        "/api/activities/recent",
        params={
            "project_ids": str(test_project.id),
            "hours": 24,
            "limit": 2
        }
    )

    assert response.status_code == 200
    activities = response.json()

    # Should only return 2 most recent activities
    assert len(activities) == 2
    assert activities[0]["type"] == ActivityType.SUMMARY_GENERATED.value
    assert activities[1]["type"] == ActivityType.CONTENT_UPLOADED.value


@pytest.mark.asyncio
async def test_get_recent_activities_invalid_project_id_format(
    authenticated_org_client: AsyncClient
):
    """Test getting recent activities with invalid project ID format."""
    response = await authenticated_org_client.get(
        "/api/activities/recent",
        params={
            "project_ids": "not-a-uuid,also-invalid",
            "hours": 24
        }
    )

    assert response.status_code == 400
    assert "Invalid project ID format" in response.json()["detail"]


@pytest.mark.asyncio
async def test_get_recent_activities_empty_result(
    authenticated_org_client: AsyncClient,
    test_project: Project,
    test_activity_old: Activity
):
    """Test getting recent activities when no recent activities exist."""
    response = await authenticated_org_client.get(
        "/api/activities/recent",
        params={
            "project_ids": str(test_project.id),
            "hours": 1,  # Old activity is 30 hours old
            "limit": 20
        }
    )

    assert response.status_code == 200
    activities = response.json()
    assert len(activities) == 0


@pytest.mark.asyncio
async def test_get_recent_activities_requires_authentication(
    client: AsyncClient,
    test_project: Project
):
    """Test that authentication is required."""
    response = await client.get(
        "/api/activities/recent",
        params={
            "project_ids": str(test_project.id),
            "hours": 24
        }
    )

    assert response.status_code in [401, 403]


# ========================================
# Test DELETE /api/projects/{project_id}/activities
# ========================================

@pytest.mark.asyncio
async def test_delete_project_activities_as_admin(
    admin_client: AsyncClient,
    test_project: Project,
    test_activity_1: Activity,
    test_activity_2: Activity,
    test_activity_3: Activity,
    db_session: AsyncSession
):
    """Test deleting all activities for a project as admin."""
    response = await admin_client.delete(
        f"/api/projects/{test_project.id}/activities"
    )

    assert response.status_code == 200
    result = response.json()
    assert result["count"] == 3
    assert "Deleted 3 activities" in result["message"]

    # Verify activities are deleted
    from sqlalchemy import select
    stmt = select(Activity).where(Activity.project_id == test_project.id)
    result = await db_session.execute(stmt)
    activities = result.scalars().all()
    assert len(activities) == 0


@pytest.mark.asyncio
async def test_delete_project_activities_as_non_admin(
    client_factory,
    test_organization: Organization,
    test_project: Project,
    test_activity_1: Activity,
    db_session: AsyncSession
):
    """Test that non-admin users cannot delete activities."""
    # Create a member (non-admin) user
    member_user = User(
        email="member@example.com",
        password_hash=native_auth_service.hash_password("MemberPass123!"),
        name="Member User",
        auth_provider='native',
        email_verified=True,
        is_active=True,
        last_active_organization_id=test_organization.id
    )
    db_session.add(member_user)
    await db_session.commit()
    await db_session.refresh(member_user)

    # Add user as member (not admin)
    member = OrganizationMember(
        organization_id=test_organization.id,
        user_id=member_user.id,
        role="member",
        invited_by=test_organization.created_by,
        joined_at=datetime.utcnow()
    )
    db_session.add(member)
    await db_session.commit()

    # Create member client
    token = native_auth_service.create_access_token(
        user_id=str(member_user.id),
        email=member_user.email,
        organization_id=str(test_organization.id)
    )
    member_client = await client_factory(
        Authorization=f"Bearer {token}",
        **{"X-Organization-Id": str(test_organization.id)}
    )

    # Try to delete activities as member (should fail)
    response = await member_client.delete(
        f"/api/projects/{test_project.id}/activities"
    )

    assert response.status_code == 403
    assert "admin role" in response.json()["detail"].lower()


@pytest.mark.asyncio
async def test_delete_project_activities_empty_project(
    admin_client: AsyncClient,
    test_project: Project
):
    """Test deleting activities when project has no activities."""
    response = await admin_client.delete(
        f"/api/projects/{test_project.id}/activities"
    )

    assert response.status_code == 200
    result = response.json()
    assert result["count"] == 0
    assert "Deleted 0 activities" in result["message"]


@pytest.mark.asyncio
async def test_delete_project_activities_invalid_project_id(
    admin_client: AsyncClient
):
    """Test deleting activities with invalid project UUID."""
    response = await admin_client.delete(
        "/api/projects/not-a-uuid/activities"
    )

    assert response.status_code == 422  # Validation error


@pytest.mark.asyncio
async def test_delete_project_activities_requires_authentication(
    client: AsyncClient,
    test_project: Project
):
    """Test that authentication is required."""
    response = await client.delete(
        f"/api/projects/{test_project.id}/activities"
    )

    assert response.status_code in [401, 403]


# ========================================
# Multi-tenant Isolation Tests
# ========================================

@pytest.mark.asyncio
async def test_get_project_activities_cross_org_isolation(
    authenticated_org_client: AsyncClient,
    client_factory,
    test_project: Project,
    test_activity_1: Activity,
    second_organization: Organization,
    second_org_admin: User,
    db_session: AsyncSession
):
    """Test that users cannot access activities from other organizations."""
    # Create client for second organization user (using admin fixture which sets up membership)
    token = native_auth_service.create_access_token(
        user_id=str(second_org_admin.id),
        email=second_org_admin.email,
        organization_id=str(second_organization.id)
    )
    second_org_client = await client_factory(
        Authorization=f"Bearer {token}",
        **{"X-Organization-Id": str(second_organization.id)}
    )

    # Try to access first org's project activities
    response = await second_org_client.get(
        f"/api/projects/{test_project.id}/activities"
    )

    # Should return empty list (no access to other org's project activities)
    assert response.status_code == 200
    activities = response.json()
    assert len(activities) == 0  # Multi-tenant isolation working


@pytest.mark.asyncio
async def test_get_recent_activities_cross_org_isolation(
    authenticated_org_client: AsyncClient,
    client_factory,
    test_project: Project,
    test_activity_1: Activity,
    second_organization: Organization,
    second_org_admin: User
):
    """Test that users cannot access activities from other organizations' projects."""
    # Create client for second organization user (using admin fixture which sets up membership)
    token = native_auth_service.create_access_token(
        user_id=str(second_org_admin.id),
        email=second_org_admin.email,
        organization_id=str(second_organization.id)
    )
    second_org_client = await client_factory(
        Authorization=f"Bearer {token}",
        **{"X-Organization-Id": str(second_organization.id)}
    )

    # Try to access first org's project activities
    response = await second_org_client.get(
        "/api/activities/recent",
        params={
            "project_ids": str(test_project.id),
            "hours": 24
        }
    )

    # Should return empty list (no access to other org's activities)
    assert response.status_code == 200
    activities = response.json()
    assert len(activities) == 0  # Multi-tenant isolation working


@pytest.mark.asyncio
async def test_delete_project_activities_cross_org_isolation(
    admin_client: AsyncClient,
    client_factory,
    test_project: Project,
    test_activity_1: Activity,
    second_organization: Organization,
    second_org_admin: User,
    db_session: AsyncSession
):
    """Test that admins cannot delete activities from other organizations."""
    # Create admin client for second organization
    token = native_auth_service.create_access_token(
        user_id=str(second_org_admin.id),
        email=second_org_admin.email,
        organization_id=str(second_organization.id)
    )
    second_org_admin_client = await client_factory(
        Authorization=f"Bearer {token}",
        **{"X-Organization-Id": str(second_organization.id)}
    )

    # Try to delete first org's project activities
    response = await second_org_admin_client.delete(
        f"/api/projects/{test_project.id}/activities"
    )

    # Should return 200 with 0 deleted (multi-tenant isolation prevents deletion)
    assert response.status_code == 200
    result = response.json()
    assert result["count"] == 0  # Multi-tenant isolation working

    # Verify activities are NOT deleted
    from sqlalchemy import select
    stmt = select(Activity).where(Activity.project_id == test_project.id)
    result = await db_session.execute(stmt)
    activities = result.scalars().all()
    assert len(activities) == 1  # Original activity still exists
