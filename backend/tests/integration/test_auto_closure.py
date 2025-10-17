"""
Integration tests for Automatic Item Closure (Issue #4 fix).

Tests the automatic closure detection for tasks, risks, and blockers
when completion/resolution is mentioned in meeting transcripts.

Status: Testing Issue #4 fix - Automatic task/risk/blocker closure
"""

import pytest
from datetime import datetime
from sqlalchemy.ext.asyncio import AsyncSession
from models.organization import Organization
from models.project import Project
from models.task import Task, TaskStatus, TaskPriority
from models.risk import Risk, RiskStatus, RiskSeverity
from models.blocker import Blocker, BlockerStatus, BlockerImpact
from services.sync.project_items_sync_service import project_items_sync_service
# No real LLM calls or content needed - testing the status update logic directly


@pytest.fixture
async def test_project_with_items(
    db_session: AsyncSession,
    test_organization: Organization
) -> tuple[Project, Task, Risk, Blocker]:
    """Create a test project with existing task, risk, and blocker."""
    # Create project
    project = Project(
        name="Auto-Closure Test Project",
        description="Testing automatic item closure",
        organization_id=test_organization.id,
        status="active"
    )
    db_session.add(project)
    await db_session.commit()
    await db_session.refresh(project)

    # Create existing task (not completed)
    task = Task(
        project_id=project.id,
        title="Implement Payment Gateway",
        description="Add payment processing functionality",
        status=TaskStatus.TODO,
        priority=TaskPriority.HIGH,
        updated_by="manual"
    )
    db_session.add(task)

    # Create existing risk (not resolved)
    risk = Risk(
        project_id=project.id,
        title="API Rate Limiting Issue",
        description="API may hit rate limits under high load",
        severity=RiskSeverity.HIGH,
        status=RiskStatus.IDENTIFIED,
        updated_by="manual"
    )
    db_session.add(risk)

    # Create existing blocker (not resolved)
    blocker = Blocker(
        project_id=project.id,
        title="Database Access Blocker",
        description="Team needs database credentials",
        impact=BlockerImpact.HIGH,
        status=BlockerStatus.ACTIVE,
        updated_by="manual"
    )
    db_session.add(blocker)

    await db_session.commit()
    await db_session.refresh(task)
    await db_session.refresh(risk)
    await db_session.refresh(blocker)

    return project, task, risk, blocker


class TestTaskAutoClosure:
    """Test automatic task closure when mentioned as completed."""

    @pytest.mark.asyncio
    async def test_task_auto_closed_when_status_update_to_completed(
        self,
        db_session: AsyncSession,
        test_project_with_items: tuple
    ):
        """Test that task is auto-closed when deduplication returns 'completed' status."""
        # Arrange
        project, task, _, _ = test_project_with_items
        content_id = None  # Not required for this test

        # Simulate deduplication result with status update to "completed"
        # (in real scenario, this comes from AI deduplication detecting "task is done")
        deduplicated_items = {
            'tasks': [],  # No new tasks
            'risks': [],
            'blockers': [],
            'lessons_learned': [],
            'status_updates': [
                {
                    'type': 'task',
                    'existing_item_number': 1,
                    'existing_title': 'Implement Payment Gateway',
                    'new_status': 'completed'
                }
            ]
        }

        # Mock the existing items
        existing_items = {
            'tasks': [task.to_dict()],
            'risks': [],
            'blockers': [],
            'lessons': []
        }

        # Act
        await project_items_sync_service._process_status_updates(
            session=db_session,
            project_id=project.id,
            content_id=content_id,
            status_updates=deduplicated_items['status_updates'],
            extracted_items={'tasks': [], 'risks': [], 'blockers': [], 'lessons': []},
            existing_items=existing_items
        )
        await db_session.commit()
        await db_session.refresh(task)

        # Assert
        assert task.status == TaskStatus.COMPLETED
        assert task.completed_date is not None
        assert task.updated_by == "ai"
        # Verify completed_date was set recently (within last minute)
        time_diff = (datetime.utcnow() - task.completed_date).total_seconds()
        assert time_diff < 60

    @pytest.mark.asyncio
    async def test_task_completed_date_not_overwritten_if_already_set(
        self,
        db_session: AsyncSession,
        test_project_with_items: tuple
    ):
        """Test that completed_date is not overwritten if already set."""
        # Arrange
        project, task, _, _ = test_project_with_items
        content_id = None  # Not required for this test

        # Set task as already completed with a specific date
        original_completed_date = datetime(2025, 1, 1, 12, 0, 0)
        task.status = TaskStatus.COMPLETED
        task.completed_date = original_completed_date
        await db_session.commit()

        deduplicated_items = {
            'status_updates': [
                {
                    'type': 'task',
                    'existing_item_number': 1,
                    'existing_title': 'Implement Payment Gateway',
                    'new_status': 'completed'
                }
            ]
        }

        existing_items = {
            'tasks': [task.to_dict()],
            'risks': [],
            'blockers': [],
            'lessons': []
        }

        # Act
        await project_items_sync_service._process_status_updates(
            session=db_session,
            project_id=project.id,
            content_id=content_id,
            status_updates=deduplicated_items['status_updates'],
            extracted_items={'tasks': [], 'risks': [], 'blockers': [], 'lessons': []},
            existing_items=existing_items
        )
        await db_session.commit()
        await db_session.refresh(task)

        # Assert - completed_date should NOT change
        assert task.completed_date == original_completed_date


class TestRiskAutoClosure:
    """Test automatic risk closure when mentioned as resolved."""

    @pytest.mark.asyncio
    async def test_risk_auto_closed_when_status_update_to_resolved(
        self,
        db_session: AsyncSession,
        test_project_with_items: tuple
    ):
        """Test that risk is auto-closed when deduplication returns 'resolved' status."""
        # Arrange
        project, _, risk, _ = test_project_with_items
        content_id = None  # Not required for this test

        deduplicated_items = {
            'status_updates': [
                {
                    'type': 'risk',
                    'existing_item_number': 1,
                    'existing_title': 'API Rate Limiting Issue',
                    'new_status': 'resolved'
                }
            ]
        }

        existing_items = {
            'tasks': [],
            'risks': [risk.to_dict()],
            'blockers': [],
            'lessons': []
        }

        # Act
        await project_items_sync_service._process_status_updates(
            session=db_session,
            project_id=project.id,
            content_id=content_id,
            status_updates=deduplicated_items['status_updates'],
            extracted_items={'tasks': [], 'risks': [], 'blockers': [], 'lessons': []},
            existing_items=existing_items
        )
        await db_session.commit()
        await db_session.refresh(risk)

        # Assert
        assert risk.status == RiskStatus.RESOLVED
        assert risk.resolved_date is not None
        assert risk.updated_by == "ai"
        # Verify resolved_date was set recently
        time_diff = (datetime.utcnow() - risk.resolved_date).total_seconds()
        assert time_diff < 60

    @pytest.mark.asyncio
    async def test_risk_resolved_date_set_via_resolution_update(
        self,
        db_session: AsyncSession,
        test_project_with_items: tuple
    ):
        """Test that risk resolved_date is set when resolution is provided."""
        # Arrange
        project, _, risk, _ = test_project_with_items
        content_id = None  # Not required for this test

        # Using 'resolution' update type (alternative path)
        deduplicated_items = {
            'status_updates': [
                {
                    'type': 'risk',
                    'existing_item_number': 1,
                    'existing_title': 'API Rate Limiting Issue',
                    'update_type': 'resolution',
                    'new_info': 'Implemented caching layer to reduce API calls'
                }
            ]
        }

        existing_items = {
            'tasks': [],
            'risks': [risk.to_dict()],
            'blockers': [],
            'lessons': []
        }

        # Act
        await project_items_sync_service._process_status_updates(
            session=db_session,
            project_id=project.id,
            content_id=content_id,
            status_updates=deduplicated_items['status_updates'],
            extracted_items={'tasks': [], 'risks': [], 'blockers': [], 'lessons': []},
            existing_items=existing_items
        )
        await db_session.commit()
        await db_session.refresh(risk)

        # Assert
        assert risk.status == RiskStatus.RESOLVED
        assert risk.resolved_date is not None
        assert risk.mitigation == 'Implemented caching layer to reduce API calls'


class TestBlockerAutoClosure:
    """Test automatic blocker closure when mentioned as resolved."""

    @pytest.mark.asyncio
    async def test_blocker_auto_closed_when_status_update_to_resolved(
        self,
        db_session: AsyncSession,
        test_project_with_items: tuple
    ):
        """Test that blocker is auto-closed when deduplication returns 'resolved' status."""
        # Arrange
        project, _, _, blocker = test_project_with_items
        content_id = None  # Not required for this test

        deduplicated_items = {
            'status_updates': [
                {
                    'type': 'blocker',
                    'existing_item_number': 1,
                    'existing_title': 'Database Access Blocker',
                    'new_status': 'resolved'
                }
            ]
        }

        existing_items = {
            'tasks': [],
            'risks': [],
            'blockers': [blocker.to_dict()],
            'lessons': []
        }

        # Act
        await project_items_sync_service._process_status_updates(
            session=db_session,
            project_id=project.id,
            content_id=content_id,
            status_updates=deduplicated_items['status_updates'],
            extracted_items={'tasks': [], 'risks': [], 'blockers': [], 'lessons': []},
            existing_items=existing_items
        )
        await db_session.commit()
        await db_session.refresh(blocker)

        # Assert
        assert blocker.status == BlockerStatus.RESOLVED
        assert blocker.resolved_date is not None
        assert blocker.updated_by == "ai"
        # Verify resolved_date was set recently
        time_diff = (datetime.utcnow() - blocker.resolved_date).total_seconds()
        assert time_diff < 60

    @pytest.mark.asyncio
    async def test_blocker_resolved_date_set_via_resolution_update(
        self,
        db_session: AsyncSession,
        test_project_with_items: tuple
    ):
        """Test that blocker resolved_date is set when resolution is provided."""
        # Arrange
        project, _, _, blocker = test_project_with_items
        content_id = None  # Not required for this test

        deduplicated_items = {
            'status_updates': [
                {
                    'type': 'blocker',
                    'existing_item_number': 1,
                    'existing_title': 'Database Access Blocker',
                    'update_type': 'resolution',
                    'new_info': 'DevOps provided database credentials'
                }
            ]
        }

        existing_items = {
            'tasks': [],
            'risks': [],
            'blockers': [blocker.to_dict()],
            'lessons': []
        }

        # Act
        await project_items_sync_service._process_status_updates(
            session=db_session,
            project_id=project.id,
            content_id=content_id,
            status_updates=deduplicated_items['status_updates'],
            extracted_items={'tasks': [], 'risks': [], 'blockers': [], 'lessons': []},
            existing_items=existing_items
        )
        await db_session.commit()
        await db_session.refresh(blocker)

        # Assert
        assert blocker.status == BlockerStatus.RESOLVED
        assert blocker.resolved_date is not None
        assert blocker.resolution == 'DevOps provided database credentials'


class TestMultipleItemsAutoClosure:
    """Test closing multiple items in a single update."""

    @pytest.mark.asyncio
    async def test_close_multiple_items_in_single_update(
        self,
        db_session: AsyncSession,
        test_project_with_items: tuple
    ):
        """Test that multiple items can be auto-closed in a single status update batch."""
        # Arrange
        project, task, risk, blocker = test_project_with_items
        content_id = None  # Not required for this test

        # Simulate meeting where all three items are mentioned as complete
        deduplicated_items = {
            'status_updates': [
                {
                    'type': 'task',
                    'existing_item_number': 1,
                    'existing_title': 'Implement Payment Gateway',
                    'new_status': 'completed'
                },
                {
                    'type': 'risk',
                    'existing_item_number': 1,
                    'existing_title': 'API Rate Limiting Issue',
                    'new_status': 'resolved'
                },
                {
                    'type': 'blocker',
                    'existing_item_number': 1,
                    'existing_title': 'Database Access Blocker',
                    'new_status': 'resolved'
                }
            ]
        }

        existing_items = {
            'tasks': [task.to_dict()],
            'risks': [risk.to_dict()],
            'blockers': [blocker.to_dict()],
            'lessons': []
        }

        # Act
        await project_items_sync_service._process_status_updates(
            session=db_session,
            project_id=project.id,
            content_id=content_id,
            status_updates=deduplicated_items['status_updates'],
            extracted_items={'tasks': [], 'risks': [], 'blockers': [], 'lessons': []},
            existing_items=existing_items
        )
        await db_session.commit()
        await db_session.refresh(task)
        await db_session.refresh(risk)
        await db_session.refresh(blocker)

        # Assert - all three items should be closed
        assert task.status == TaskStatus.COMPLETED
        assert task.completed_date is not None

        assert risk.status == RiskStatus.RESOLVED
        assert risk.resolved_date is not None

        assert blocker.status == BlockerStatus.RESOLVED
        assert blocker.resolved_date is not None

        # All should be updated by AI
        assert task.updated_by == "ai"
        assert risk.updated_by == "ai"
        assert blocker.updated_by == "ai"
