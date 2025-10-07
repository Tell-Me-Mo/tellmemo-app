"""
Integration tests for Tasks Management API.

Covers TESTING_BACKEND.md section 8.2 - Tasks Management

Status: TBD
"""

import pytest
from datetime import datetime, timedelta
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession
from models.user import User
from models.organization import Organization
from models.project import Project
from models.task import Task, TaskStatus, TaskPriority
from models.risk import Risk, RiskSeverity, RiskStatus
from models.organization_member import OrganizationMember


@pytest.fixture
async def test_project(
    db_session: AsyncSession,
    test_organization: Organization
) -> Project:
    """Create a test project for tasks testing."""
    project = Project(
        name="Test Project for Tasks",
        description="Project for testing task management",
        organization_id=test_organization.id,
        status="active"
    )
    db_session.add(project)
    await db_session.commit()
    await db_session.refresh(project)
    return project


@pytest.fixture
async def test_task(
    db_session: AsyncSession,
    test_project: Project
) -> Task:
    """Create a test task."""
    task = Task(
        project_id=test_project.id,
        title="Test Task",
        description="This is a test task",
        status=TaskStatus.TODO,
        priority=TaskPriority.HIGH,
        assignee="John Doe",
        progress_percentage=0,
        updated_by="manual"
    )
    db_session.add(task)
    await db_session.commit()
    await db_session.refresh(task)
    return task


@pytest.fixture
async def test_risk(
    db_session: AsyncSession,
    test_project: Project
) -> Risk:
    """Create a test risk for task dependencies."""
    risk = Risk(
        project_id=test_project.id,
        title="Test Risk",
        description="Risk for task dependency testing",
        severity=RiskSeverity.HIGH,
        status=RiskStatus.IDENTIFIED,
        updated_by="manual"
    )
    db_session.add(risk)
    await db_session.commit()
    await db_session.refresh(risk)
    return risk


class TestCreateTask:
    """Test task creation endpoint."""

    @pytest.mark.asyncio
    async def test_create_task_success(
        self,
        authenticated_org_client: AsyncClient,
        test_project: Project
    ):
        """Test successful task creation with minimal data."""
        # Arrange
        task_data = {
            "title": "Implement new feature",
            "description": "Add user authentication to the app",
            "status": "todo",
            "priority": "high"
        }

        # Act
        response = await authenticated_org_client.post(
            f"/api/v1/projects/{test_project.id}/tasks",
            json=task_data
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["title"] == "Implement new feature"
        assert data["description"] == "Add user authentication to the app"
        assert data["status"] == "todo"
        assert data["priority"] == "high"
        assert data["progress_percentage"] == 0
        assert data["ai_generated"] is False
        assert "id" in data
        assert data["project_id"] == str(test_project.id)

    @pytest.mark.asyncio
    async def test_create_task_with_full_data(
        self,
        authenticated_org_client: AsyncClient,
        test_project: Project,
        test_risk: Risk
    ):
        """Test task creation with all optional fields."""
        # Arrange
        due_date = (datetime.utcnow() + timedelta(days=7)).isoformat()
        task_data = {
            "title": "Fix critical bug",
            "description": "Resolve database connection issue",
            "status": "in_progress",
            "priority": "urgent",
            "assignee": "Jane Doe",
            "due_date": due_date,
            "progress_percentage": 25,
            "blocker_description": "Waiting for database credentials",
            "question_to_ask": "Which database should we use?",
            "ai_generated": True,
            "ai_confidence": 0.85,
            "depends_on_risk_id": str(test_risk.id)
        }

        # Act
        response = await authenticated_org_client.post(
            f"/api/v1/projects/{test_project.id}/tasks",
            json=task_data
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["title"] == "Fix critical bug"
        assert data["assignee"] == "Jane Doe"
        assert data["progress_percentage"] == 25
        assert data["blocker_description"] == "Waiting for database credentials"
        assert data["question_to_ask"] == "Which database should we use?"
        assert data["ai_generated"] is True
        assert data["ai_confidence"] == 0.85
        assert data["depends_on_risk_id"] == str(test_risk.id)
        assert data["due_date"] is not None

    @pytest.mark.asyncio
    async def test_create_task_with_invalid_risk_dependency(
        self,
        authenticated_org_client: AsyncClient,
        test_project: Project
    ):
        """Test creating task with non-existent risk dependency returns 404."""
        # Arrange
        fake_risk_id = "00000000-0000-0000-0000-000000000000"
        task_data = {
            "title": "Task with invalid risk",
            "description": "This should fail",
            "depends_on_risk_id": fake_risk_id
        }

        # Act
        response = await authenticated_org_client.post(
            f"/api/v1/projects/{test_project.id}/tasks",
            json=task_data
        )

        # Assert
        assert response.status_code == 404

    @pytest.mark.asyncio
    async def test_create_task_invalid_project(
        self,
        authenticated_org_client: AsyncClient
    ):
        """Test creating task for non-existent project returns 404."""
        # Arrange
        fake_project_id = "00000000-0000-0000-0000-000000000000"
        task_data = {
            "title": "Test Task",
            "description": "This should fail"
        }

        # Act
        response = await authenticated_org_client.post(
            f"/api/v1/projects/{fake_project_id}/tasks",
            json=task_data
        )

        # Assert
        assert response.status_code == 404

    @pytest.mark.asyncio
    async def test_create_task_without_auth_fails(
        self,
        client: AsyncClient,
        test_project: Project
    ):
        """Test that creating task without authentication fails."""
        # Arrange
        task_data = {
            "title": "Unauthorized Task",
            "description": "Should not be created"
        }

        # Act
        response = await client.post(
            f"/api/v1/projects/{test_project.id}/tasks",
            json=task_data
        )

        # Assert - EXPOSES BUG: Should return 401/403
        assert response.status_code in [401, 403]


class TestListTasks:
    """Test listing tasks for a project."""

    @pytest.mark.asyncio
    async def test_list_tasks_success(
        self,
        authenticated_org_client: AsyncClient,
        test_project: Project,
        test_task: Task,
        db_session: AsyncSession
    ):
        """Test listing all tasks for a project."""
        # Arrange - Create additional task
        task2 = Task(
            project_id=test_project.id,
            title="Another Task",
            description="Second task",
            status=TaskStatus.IN_PROGRESS,
            priority=TaskPriority.MEDIUM,
            updated_by="manual"
        )
        db_session.add(task2)
        await db_session.commit()

        # Act
        response = await authenticated_org_client.get(
            f"/api/v1/projects/{test_project.id}/tasks"
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert len(data) == 2
        # Verify ordering (by priority desc, then due_date)
        assert data[0]["priority"] == "high"
        assert data[1]["priority"] == "medium"

    @pytest.mark.asyncio
    async def test_list_tasks_filter_by_status(
        self,
        authenticated_org_client: AsyncClient,
        test_project: Project,
        db_session: AsyncSession
    ):
        """Test filtering tasks by status."""
        # Arrange - Create tasks with different statuses
        task1 = Task(
            project_id=test_project.id,
            title="Todo Task",
            description="Not started",
            status=TaskStatus.TODO,
            priority=TaskPriority.MEDIUM,
            updated_by="manual"
        )
        task2 = Task(
            project_id=test_project.id,
            title="Completed Task",
            description="Finished",
            status=TaskStatus.COMPLETED,
            priority=TaskPriority.MEDIUM,
            updated_by="manual"
        )
        db_session.add_all([task1, task2])
        await db_session.commit()

        # Act
        response = await authenticated_org_client.get(
            f"/api/v1/projects/{test_project.id}/tasks?status=todo"
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert len(data) == 1
        assert data[0]["status"] == "todo"

    @pytest.mark.asyncio
    async def test_list_tasks_filter_by_priority(
        self,
        authenticated_org_client: AsyncClient,
        test_project: Project,
        db_session: AsyncSession
    ):
        """Test filtering tasks by priority."""
        # Arrange - Create tasks with different priorities
        task1 = Task(
            project_id=test_project.id,
            title="Urgent Task",
            description="Very important",
            status=TaskStatus.TODO,
            priority=TaskPriority.URGENT,
            updated_by="manual"
        )
        task2 = Task(
            project_id=test_project.id,
            title="Low Priority Task",
            description="Can wait",
            status=TaskStatus.TODO,
            priority=TaskPriority.LOW,
            updated_by="manual"
        )
        db_session.add_all([task1, task2])
        await db_session.commit()

        # Act
        response = await authenticated_org_client.get(
            f"/api/v1/projects/{test_project.id}/tasks?priority=urgent"
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert len(data) == 1
        assert data[0]["priority"] == "urgent"

    @pytest.mark.asyncio
    async def test_list_tasks_filter_by_assignee(
        self,
        authenticated_org_client: AsyncClient,
        test_project: Project,
        db_session: AsyncSession
    ):
        """Test filtering tasks by assignee."""
        # Arrange - Create tasks with different assignees
        task1 = Task(
            project_id=test_project.id,
            title="Task for Alice",
            description="Alice's work",
            status=TaskStatus.TODO,
            priority=TaskPriority.MEDIUM,
            assignee="Alice",
            updated_by="manual"
        )
        task2 = Task(
            project_id=test_project.id,
            title="Task for Bob",
            description="Bob's work",
            status=TaskStatus.TODO,
            priority=TaskPriority.MEDIUM,
            assignee="Bob",
            updated_by="manual"
        )
        db_session.add_all([task1, task2])
        await db_session.commit()

        # Act
        response = await authenticated_org_client.get(
            f"/api/v1/projects/{test_project.id}/tasks?assignee=Alice"
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert len(data) == 1
        assert data[0]["assignee"] == "Alice"

    @pytest.mark.asyncio
    async def test_list_tasks_empty_project(
        self,
        authenticated_org_client: AsyncClient,
        test_project: Project
    ):
        """Test listing tasks for project with no tasks returns empty array."""
        # Act
        response = await authenticated_org_client.get(
            f"/api/v1/projects/{test_project.id}/tasks"
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data == []

    @pytest.mark.asyncio
    async def test_list_tasks_without_auth_fails(
        self,
        client: AsyncClient,
        test_project: Project
    ):
        """Test that listing tasks without authentication fails."""
        # Act
        response = await client.get(
            f"/api/v1/projects/{test_project.id}/tasks"
        )

        # Assert - EXPOSES BUG: Should return 401/403
        assert response.status_code in [401, 403]


class TestUpdateTask:
    """Test task update endpoint."""

    @pytest.mark.asyncio
    async def test_update_task_title_and_description(
        self,
        authenticated_org_client: AsyncClient,
        test_task: Task
    ):
        """Test updating task title and description."""
        # Arrange
        update_data = {
            "title": "Updated Task Title",
            "description": "Updated description"
        }

        # Act
        response = await authenticated_org_client.patch(
            f"/api/v1/tasks/{test_task.id}",
            json=update_data
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["title"] == "Updated Task Title"
        assert data["description"] == "Updated description"

    @pytest.mark.asyncio
    async def test_update_task_status_to_completed(
        self,
        authenticated_org_client: AsyncClient,
        test_task: Task
    ):
        """Test updating task status to completed sets completed_date and progress to 100."""
        # Arrange
        update_data = {"status": "completed"}

        # Act
        response = await authenticated_org_client.patch(
            f"/api/v1/tasks/{test_task.id}",
            json=update_data
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "completed"
        assert data["completed_date"] is not None
        assert data["progress_percentage"] == 100

    @pytest.mark.asyncio
    async def test_update_task_status_auto_updates_progress(
        self,
        authenticated_org_client: AsyncClient,
        test_task: Task
    ):
        """Test that changing status auto-updates progress percentage."""
        # Arrange - Change to in_progress should set progress to 50
        update_data = {"status": "in_progress"}

        # Act
        response = await authenticated_org_client.patch(
            f"/api/v1/tasks/{test_task.id}",
            json=update_data
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "in_progress"
        assert data["progress_percentage"] == 50

    @pytest.mark.asyncio
    async def test_update_task_progress_manually(
        self,
        authenticated_org_client: AsyncClient,
        test_task: Task
    ):
        """Test manually updating progress percentage."""
        # Arrange
        update_data = {
            "status": "in_progress",
            "progress_percentage": 75
        }

        # Act
        response = await authenticated_org_client.patch(
            f"/api/v1/tasks/{test_task.id}",
            json=update_data
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["progress_percentage"] == 75

    @pytest.mark.asyncio
    async def test_update_task_priority(
        self,
        authenticated_org_client: AsyncClient,
        test_task: Task
    ):
        """Test updating task priority."""
        # Arrange
        update_data = {"priority": "urgent"}

        # Act
        response = await authenticated_org_client.patch(
            f"/api/v1/tasks/{test_task.id}",
            json=update_data
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["priority"] == "urgent"

    @pytest.mark.asyncio
    async def test_update_task_assignee(
        self,
        authenticated_org_client: AsyncClient,
        test_task: Task
    ):
        """Test updating task assignee."""
        # Arrange
        update_data = {"assignee": "Jane Doe"}

        # Act
        response = await authenticated_org_client.patch(
            f"/api/v1/tasks/{test_task.id}",
            json=update_data
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["assignee"] == "Jane Doe"

    @pytest.mark.asyncio
    async def test_update_task_due_date(
        self,
        authenticated_org_client: AsyncClient,
        test_task: Task
    ):
        """Test updating task due date."""
        # Arrange
        new_due_date = (datetime.utcnow() + timedelta(days=5)).isoformat()
        update_data = {"due_date": new_due_date}

        # Act
        response = await authenticated_org_client.patch(
            f"/api/v1/tasks/{test_task.id}",
            json=update_data
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["due_date"] is not None

    @pytest.mark.asyncio
    async def test_update_task_blocker_description(
        self,
        authenticated_org_client: AsyncClient,
        test_task: Task
    ):
        """Test updating task blocker description."""
        # Arrange
        update_data = {
            "status": "blocked",
            "blocker_description": "Waiting for API access"
        }

        # Act
        response = await authenticated_org_client.patch(
            f"/api/v1/tasks/{test_task.id}",
            json=update_data
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "blocked"
        assert data["blocker_description"] == "Waiting for API access"

    @pytest.mark.asyncio
    async def test_update_nonexistent_task(
        self,
        authenticated_org_client: AsyncClient
    ):
        """Test updating non-existent task returns 404."""
        # Arrange
        fake_task_id = "00000000-0000-0000-0000-000000000000"
        update_data = {"title": "Won't work"}

        # Act
        response = await authenticated_org_client.patch(
            f"/api/v1/tasks/{fake_task_id}",
            json=update_data
        )

        # Assert
        assert response.status_code == 404

    @pytest.mark.asyncio
    async def test_update_task_without_auth_fails(
        self,
        client: AsyncClient,
        test_task: Task
    ):
        """Test that updating task without authentication fails."""
        # Arrange
        update_data = {"title": "Unauthorized update"}

        # Act
        response = await client.patch(
            f"/api/v1/tasks/{test_task.id}",
            json=update_data
        )

        # Assert - EXPOSES BUG: Should return 401/403
        assert response.status_code in [401, 403]


class TestDeleteTask:
    """Test task deletion endpoint."""

    @pytest.mark.asyncio
    async def test_delete_task_success(
        self,
        authenticated_org_client: AsyncClient,
        test_task: Task,
        db_session: AsyncSession
    ):
        """Test successful task deletion."""
        # Act
        response = await authenticated_org_client.delete(
            f"/api/v1/tasks/{test_task.id}"
        )

        # Assert
        assert response.status_code == 200
        assert response.json()["message"] == "Task deleted successfully"

        # Verify task is actually deleted
        result = await db_session.get(Task, test_task.id)
        assert result is None

    @pytest.mark.asyncio
    async def test_delete_nonexistent_task(
        self,
        authenticated_org_client: AsyncClient
    ):
        """Test deleting non-existent task returns 404."""
        # Arrange
        fake_task_id = "00000000-0000-0000-0000-000000000000"

        # Act
        response = await authenticated_org_client.delete(
            f"/api/v1/tasks/{fake_task_id}"
        )

        # Assert
        assert response.status_code == 404

    @pytest.mark.asyncio
    async def test_delete_task_without_auth_fails(
        self,
        client: AsyncClient,
        test_task: Task
    ):
        """Test that deleting task without authentication fails."""
        # Act
        response = await client.delete(
            f"/api/v1/tasks/{test_task.id}"
        )

        # Assert - EXPOSES BUG: Should return 401/403
        assert response.status_code in [401, 403]


class TestBulkUpdateTasks:
    """Test bulk task update endpoint."""

    @pytest.mark.asyncio
    async def test_bulk_create_tasks(
        self,
        authenticated_org_client: AsyncClient,
        test_project: Project
    ):
        """Test bulk creating multiple new tasks."""
        # Arrange
        tasks_data = [
            {
                "title": "Task 1",
                "description": "First bulk task",
                "status": "todo",
                "priority": "high",
                "ai_confidence": 0.9
            },
            {
                "title": "Task 2",
                "description": "Second bulk task",
                "status": "in_progress",
                "priority": "medium",
                "ai_confidence": 0.8
            }
        ]

        # Act
        response = await authenticated_org_client.post(
            f"/api/v1/projects/{test_project.id}/tasks/bulk-update",
            json=tasks_data
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert len(data) == 2
        assert data[0]["title"] == "Task 1"
        assert data[1]["title"] == "Task 2"
        # EXPOSES BUG: ai_generated should be True but might fail due to type mismatch
        assert all(t["ai_generated"] is True for t in data)

    @pytest.mark.asyncio
    async def test_bulk_update_existing_tasks(
        self,
        authenticated_org_client: AsyncClient,
        test_project: Project,
        db_session: AsyncSession
    ):
        """Test bulk updating existing tasks by title."""
        # Arrange - Create existing task
        existing_task = Task(
            project_id=test_project.id,
            title="Existing Task",
            description="Old description",
            status=TaskStatus.TODO,
            priority=TaskPriority.LOW,
            updated_by="manual"
        )
        db_session.add(existing_task)
        await db_session.commit()

        # Update with same title
        tasks_data = [
            {
                "title": "Existing Task",
                "description": "Updated description",
                "status": "in_progress",
                "priority": "urgent"
            }
        ]

        # Act
        response = await authenticated_org_client.post(
            f"/api/v1/projects/{test_project.id}/tasks/bulk-update",
            json=tasks_data
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert len(data) == 1
        assert data[0]["title"] == "Existing Task"
        assert data[0]["description"] == "Updated description"
        assert data[0]["status"] == "in_progress"
        assert data[0]["priority"] == "urgent"
        assert data[0]["updated_by"] == "ai"

    @pytest.mark.asyncio
    async def test_bulk_update_mixed_create_and_update(
        self,
        authenticated_org_client: AsyncClient,
        test_project: Project,
        db_session: AsyncSession
    ):
        """Test bulk operation with both new and existing tasks."""
        # Arrange - Create one existing task
        existing_task = Task(
            project_id=test_project.id,
            title="Update Me",
            description="Old",
            status=TaskStatus.TODO,
            priority=TaskPriority.LOW,
            updated_by="manual"
        )
        db_session.add(existing_task)
        await db_session.commit()

        tasks_data = [
            {
                "title": "Update Me",
                "description": "Updated",
                "priority": "high"
            },
            {
                "title": "New Task",
                "description": "Brand new",
                "priority": "medium"
            }
        ]

        # Act
        response = await authenticated_org_client.post(
            f"/api/v1/projects/{test_project.id}/tasks/bulk-update",
            json=tasks_data
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert len(data) == 2
        # Find the updated and created tasks
        updated = next(t for t in data if t["title"] == "Update Me")
        created = next(t for t in data if t["title"] == "New Task")
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
        tasks_data = [{"title": "Test", "description": "Fail"}]

        # Act
        response = await authenticated_org_client.post(
            f"/api/v1/projects/{fake_project_id}/tasks/bulk-update",
            json=tasks_data
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
        tasks_data = [{"title": "Unauthorized", "description": "Should fail"}]

        # Act
        response = await client.post(
            f"/api/v1/projects/{test_project.id}/tasks/bulk-update",
            json=tasks_data
        )

        # Assert - EXPOSES BUG: Should return 401/403
        assert response.status_code in [401, 403]


class TestMultiTenantIsolation:
    """Test multi-tenant isolation for tasks."""

    @pytest.mark.asyncio
    async def test_cannot_create_task_for_other_org_project(
        self,
        client_factory,
        db_session: AsyncSession,
        test_user: User
    ):
        """Test that users cannot create tasks for projects in other organizations."""
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

        # Act - Try to create task for org2's project
        task_data = {
            "title": "Cross-org Task",
            "description": "Should not be created"
        }
        response = await org1_client.post(
            f"/api/v1/projects/{project_org2.id}/tasks",
            json=task_data
        )

        # Assert - EXPOSES BUG: Should return 404 but will likely succeed
        assert response.status_code == 404

    @pytest.mark.asyncio
    async def test_cannot_list_tasks_from_other_org(
        self,
        client_factory,
        db_session: AsyncSession,
        test_user: User
    ):
        """Test that users cannot list tasks from other organizations."""
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

        # Create project in org2 with task
        project_org2 = Project(
            name="Org 2 Project",
            organization_id=org2.id,
            status="active"
        )
        db_session.add(project_org2)
        await db_session.commit()
        await db_session.refresh(project_org2)

        task = Task(
            project_id=project_org2.id,
            title="Org 2 Task",
            description="Should not be visible",
            status=TaskStatus.TODO,
            priority=TaskPriority.HIGH,
            updated_by="manual"
        )
        db_session.add(task)
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

        # Act - Try to list tasks from org2's project
        response = await org1_client.get(
            f"/api/v1/projects/{project_org2.id}/tasks"
        )

        # Assert - EXPOSES BUG: Should return 404 or empty array
        # Current implementation will likely return the task
        assert response.status_code == 404 or response.json() == []
