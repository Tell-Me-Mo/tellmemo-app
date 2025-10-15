"""API endpoints for project risks and tasks management."""

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update, delete, and_
from typing import List, Optional
from uuid import UUID
from datetime import datetime
from pydantic import BaseModel, Field, validator

from db.database import get_db
from dependencies.auth import get_current_organization, get_current_user, require_role
from models.organization import Organization
from models.user import User
from models.risk import Risk, RiskSeverity, RiskStatus
from models.task import Task, TaskStatus, TaskPriority
from models.blocker import Blocker, BlockerImpact, BlockerStatus
from models.project import Project
from models.item_update import ItemUpdate, ItemUpdateType
from services.item_updates_service import ItemUpdatesService


router = APIRouter(prefix="/api/v1", tags=["risks-tasks"])


# Pydantic models for request/response
class RiskCreate(BaseModel):
    title: str
    description: str
    severity: RiskSeverity = RiskSeverity.MEDIUM
    status: RiskStatus = RiskStatus.IDENTIFIED
    mitigation: Optional[str] = None
    impact: Optional[str] = None
    probability: Optional[float] = Field(None, ge=0.0, le=1.0)
    assigned_to: Optional[str] = None
    assigned_to_email: Optional[str] = None
    ai_generated: bool = False
    ai_confidence: Optional[float] = Field(None, ge=0.0, le=1.0)
    source_content_id: Optional[UUID] = None


class RiskUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    severity: Optional[RiskSeverity] = None
    status: Optional[RiskStatus] = None
    mitigation: Optional[str] = None
    impact: Optional[str] = None
    probability: Optional[float] = Field(None, ge=0.0, le=1.0)
    assigned_to: Optional[str] = None
    assigned_to_email: Optional[str] = None


class TaskCreate(BaseModel):
    title: str
    description: Optional[str] = None
    status: TaskStatus = TaskStatus.TODO
    priority: TaskPriority = TaskPriority.MEDIUM
    assignee: Optional[str] = None
    due_date: Optional[datetime] = None
    progress_percentage: int = Field(0, ge=0, le=100)
    blocker_description: Optional[str] = None
    question_to_ask: Optional[str] = None
    ai_generated: bool = False
    ai_confidence: Optional[float] = Field(None, ge=0.0, le=1.0)
    source_content_id: Optional[UUID] = None
    depends_on_risk_id: Optional[UUID] = None


class TaskUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    status: Optional[TaskStatus] = None
    priority: Optional[TaskPriority] = None
    assignee: Optional[str] = None
    due_date: Optional[datetime] = None
    completed_date: Optional[datetime] = None
    progress_percentage: Optional[int] = Field(None, ge=0, le=100)
    blocker_description: Optional[str] = None
    question_to_ask: Optional[str] = None


class BlockerCreate(BaseModel):
    title: str
    description: str
    impact: BlockerImpact = BlockerImpact.HIGH
    status: BlockerStatus = BlockerStatus.ACTIVE
    resolution: Optional[str] = None
    category: Optional[str] = None
    owner: Optional[str] = None
    dependencies: Optional[str] = None
    target_date: Optional[datetime] = None
    assigned_to: Optional[str] = None
    assigned_to_email: Optional[str] = None
    ai_generated: bool = False
    ai_confidence: Optional[float] = Field(None, ge=0.0, le=1.0)
    source_content_id: Optional[UUID] = None


class BlockerUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    impact: Optional[BlockerImpact] = None
    status: Optional[BlockerStatus] = None
    resolution: Optional[str] = None
    category: Optional[str] = None
    owner: Optional[str] = None
    dependencies: Optional[str] = None
    target_date: Optional[datetime] = None
    resolved_date: Optional[datetime] = None
    escalation_date: Optional[datetime] = None
    assigned_to: Optional[str] = None
    assigned_to_email: Optional[str] = None


# ItemUpdate schemas
class ItemUpdateCreate(BaseModel):
    content: str
    update_type: str = ItemUpdateType.COMMENT  # Now using string with default
    author_name: str
    author_email: Optional[str] = None

    @validator('update_type')
    def validate_update_type(cls, v):
        """Validate that update_type is one of the allowed values."""
        if not ItemUpdateType.is_valid(v):
            raise ValueError(f"Invalid update_type. Must be one of: {', '.join(ItemUpdateType.ALL_TYPES)}")
        return v


# Risk endpoints
@router.get("/projects/{project_id}/risks")
async def get_project_risks(
    project_id: UUID,
    status: Optional[RiskStatus] = None,
    severity: Optional[RiskSeverity] = None,
    db: AsyncSession = Depends(get_db),
    current_org: Organization = Depends(get_current_organization),
    current_user: User = Depends(get_current_user),
    _: str = Depends(require_role("member"))
):
    """Get all risks for a project with optional filtering."""
    # First verify project belongs to organization
    project_result = await db.execute(
        select(Project).where(
            and_(
                Project.id == project_id,
                Project.organization_id == current_org.id
            )
        )
    )
    project = project_result.scalar_one_or_none()
    if not project:
        raise HTTPException(status_code=404, detail="Project not found")

    query = select(Risk).where(Risk.project_id == project_id)

    if status:
        query = query.where(Risk.status == status)
    if severity:
        query = query.where(Risk.severity == severity)

    result = await db.execute(query.order_by(Risk.severity.desc(), Risk.identified_date.desc()))
    risks = result.scalars().all()

    return [risk.to_dict() for risk in risks]


@router.post("/projects/{project_id}/risks")
async def create_risk(
    project_id: UUID,
    risk_data: RiskCreate,
    db: AsyncSession = Depends(get_db),
    current_org: Organization = Depends(get_current_organization),
    current_user: User = Depends(get_current_user),
    _: str = Depends(require_role("member"))
):
    """Create a new risk for a project."""
    # Verify project belongs to organization
    project_result = await db.execute(
        select(Project).where(
            and_(
                Project.id == project_id,
                Project.organization_id == current_org.id
            )
        )
    )
    project = project_result.scalar_one_or_none()
    if not project:
        raise HTTPException(status_code=404, detail="Project not found")

    risk = Risk(
        project_id=project_id,
        title=risk_data.title,
        description=risk_data.description,
        severity=risk_data.severity,
        status=risk_data.status,
        mitigation=risk_data.mitigation,
        impact=risk_data.impact,
        probability=risk_data.probability,
        assigned_to=risk_data.assigned_to,
        assigned_to_email=risk_data.assigned_to_email,
        ai_generated="true" if risk_data.ai_generated else "false",
        ai_confidence=risk_data.ai_confidence,
        source_content_id=risk_data.source_content_id,
        updated_by="manual"
    )

    db.add(risk)
    await db.commit()
    await db.refresh(risk)

    # Create CREATED update
    author_name = current_user.name or current_user.email or "User"
    await ItemUpdatesService.create_item_created_update(
        db=db,
        project_id=project_id,
        item_id=risk.id,
        item_type='risks',
        item_title=risk.title,
        author_name=author_name,
        author_email=current_user.email,
        ai_generated=risk_data.ai_generated
    )
    await db.commit()

    return risk.to_dict()


@router.patch("/risks/{risk_id}")
async def update_risk(
    risk_id: UUID,
    risk_data: RiskUpdate,
    db: AsyncSession = Depends(get_db),
    current_org: Organization = Depends(get_current_organization),
    current_user: User = Depends(get_current_user),
    _: str = Depends(require_role("member"))
):
    """Update an existing risk."""
    # Get risk
    risk = await db.get(Risk, risk_id)
    if not risk:
        raise HTTPException(status_code=404, detail="Risk not found")

    # Verify project belongs to organization
    project = await db.get(Project, risk.project_id)
    if not project or project.organization_id != current_org.id:
        raise HTTPException(status_code=404, detail="Risk not found")

    update_data = risk_data.dict(exclude_unset=True)

    # Track status changes before updating
    author_name = current_user.name or current_user.email or "User"
    if "status" in update_data and update_data["status"] != risk.status:
        await ItemUpdatesService.track_status_change(
            db=db,
            project_id=risk.project_id,
            item_id=risk.id,
            item_type='risks',
            old_status=risk.status,
            new_status=update_data["status"],
            author_name=author_name,
            author_email=current_user.email
        )
        # Handle resolved date
        if update_data["status"] == RiskStatus.RESOLVED:
            update_data["resolved_date"] = datetime.utcnow()

    # Track assignment changes
    if "assigned_to" in update_data and update_data["assigned_to"] != risk.assigned_to:
        await ItemUpdatesService.track_assignment(
            db=db,
            project_id=risk.project_id,
            item_id=risk.id,
            item_type='risks',
            old_assignee=risk.assigned_to,
            new_assignee=update_data["assigned_to"],
            author_name=author_name,
            author_email=current_user.email
        )

    # Detect other field changes
    changes = ItemUpdatesService.detect_changes(risk, update_data)
    if changes:
        await ItemUpdatesService.track_field_changes(
            db=db,
            project_id=risk.project_id,
            item_id=risk.id,
            item_type='risks',
            changes=changes,
            author_name=author_name,
            author_email=current_user.email
        )

    update_data["last_updated"] = datetime.utcnow()
    update_data["updated_by"] = "manual"

    for key, value in update_data.items():
        if hasattr(risk, key):
            setattr(risk, key, value)

    await db.commit()
    await db.refresh(risk)

    return risk.to_dict()


@router.delete("/risks/{risk_id}")
async def delete_risk(
    risk_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_org: Organization = Depends(get_current_organization),
    current_user: User = Depends(get_current_user),
    _: str = Depends(require_role("member"))
):
    """Delete a risk."""
    # Get risk
    risk = await db.get(Risk, risk_id)
    if not risk:
        raise HTTPException(status_code=404, detail="Risk not found")

    # Verify project belongs to organization
    project = await db.get(Project, risk.project_id)
    if not project or project.organization_id != current_org.id:
        raise HTTPException(status_code=404, detail="Risk not found")

    await db.delete(risk)
    await db.commit()

    return {"message": "Risk deleted successfully"}


# Task endpoints
@router.get("/projects/{project_id}/tasks")
async def get_project_tasks(
    project_id: UUID,
    status: Optional[TaskStatus] = None,
    priority: Optional[TaskPriority] = None,
    assignee: Optional[str] = None,
    db: AsyncSession = Depends(get_db),
    current_org: Organization = Depends(get_current_organization),
    current_user: User = Depends(get_current_user),
    _: str = Depends(require_role("member"))
):
    """Get all tasks for a project with optional filtering."""
    # First verify project belongs to organization
    project_result = await db.execute(
        select(Project).where(
            and_(
                Project.id == project_id,
                Project.organization_id == current_org.id
            )
        )
    )
    project = project_result.scalar_one_or_none()
    if not project:
        raise HTTPException(status_code=404, detail="Project not found")

    query = select(Task).where(Task.project_id == project_id)

    if status:
        query = query.where(Task.status == status)
    if priority:
        query = query.where(Task.priority == priority)
    if assignee:
        query = query.where(Task.assignee == assignee)

    result = await db.execute(query.order_by(Task.priority.desc(), Task.due_date))
    tasks = result.scalars().all()

    return [task.to_dict() for task in tasks]


@router.post("/projects/{project_id}/tasks")
async def create_task(
    project_id: UUID,
    task_data: TaskCreate,
    db: AsyncSession = Depends(get_db),
    current_org: Organization = Depends(get_current_organization),
    current_user: User = Depends(get_current_user),
    _: str = Depends(require_role("member"))
):
    """Create a new task for a project."""
    # Verify project belongs to organization
    project_result = await db.execute(
        select(Project).where(
            and_(
                Project.id == project_id,
                Project.organization_id == current_org.id
            )
        )
    )
    project = project_result.scalar_one_or_none()
    if not project:
        raise HTTPException(status_code=404, detail="Project not found")

    # Verify risk exists if depends_on_risk_id is provided
    if task_data.depends_on_risk_id:
        risk = await db.get(Risk, task_data.depends_on_risk_id)
        if not risk:
            raise HTTPException(status_code=404, detail="Related risk not found")

    task = Task(
        project_id=project_id,
        title=task_data.title,
        description=task_data.description,
        status=task_data.status,
        priority=task_data.priority,
        assignee=task_data.assignee,
        due_date=task_data.due_date,
        progress_percentage=task_data.progress_percentage,
        blocker_description=task_data.blocker_description,
        question_to_ask=task_data.question_to_ask,
        ai_generated="true" if task_data.ai_generated else "false",
        ai_confidence=task_data.ai_confidence,
        source_content_id=task_data.source_content_id,
        depends_on_risk_id=task_data.depends_on_risk_id,
        updated_by="manual"
    )

    db.add(task)
    await db.commit()
    await db.refresh(task)

    # Create CREATED update
    author_name = current_user.name or current_user.email or "User"
    await ItemUpdatesService.create_item_created_update(
        db=db,
        project_id=project_id,
        item_id=task.id,
        item_type='tasks',
        item_title=task.title,
        author_name=author_name,
        author_email=current_user.email,
        ai_generated=task_data.ai_generated
    )
    await db.commit()

    return task.to_dict()


@router.patch("/tasks/{task_id}")
async def update_task(
    task_id: UUID,
    task_data: TaskUpdate,
    db: AsyncSession = Depends(get_db),
    current_org: Organization = Depends(get_current_organization),
    current_user: User = Depends(get_current_user),
    _: str = Depends(require_role("member"))
):
    """Update an existing task."""
    # Get task
    task = await db.get(Task, task_id)
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")

    # Verify project belongs to organization
    project = await db.get(Project, task.project_id)
    if not project or project.organization_id != current_org.id:
        raise HTTPException(status_code=404, detail="Task not found")

    update_data = task_data.dict(exclude_unset=True)

    # Track status changes before updating
    author_name = current_user.name or current_user.email or "User"
    if "status" in update_data and update_data["status"] != task.status:
        await ItemUpdatesService.track_status_change(
            db=db,
            project_id=task.project_id,
            item_id=task.id,
            item_type='tasks',
            old_status=task.status,
            new_status=update_data["status"],
            author_name=author_name,
            author_email=current_user.email
        )
        # Handle completed date
        if update_data["status"] == TaskStatus.COMPLETED and not task.completed_date:
            update_data["completed_date"] = datetime.utcnow()
            update_data["progress_percentage"] = 100
        elif update_data["status"] != TaskStatus.COMPLETED:
            update_data["completed_date"] = None

    # Track assignment changes (for tasks it's 'assignee' not 'assigned_to')
    if "assignee" in update_data and update_data["assignee"] != task.assignee:
        await ItemUpdatesService.track_assignment(
            db=db,
            project_id=task.project_id,
            item_id=task.id,
            item_type='tasks',
            old_assignee=task.assignee,
            new_assignee=update_data["assignee"],
            author_name=author_name,
            author_email=current_user.email
        )

    # Auto-update progress based on status
    if "status" in update_data and "progress_percentage" not in update_data:
        status_progress_map = {
            TaskStatus.TODO: 0,
            TaskStatus.IN_PROGRESS: 50,
            TaskStatus.BLOCKED: task.progress_percentage,  # Keep current
            TaskStatus.COMPLETED: 100,
            TaskStatus.CANCELLED: task.progress_percentage  # Keep current
        }
        update_data["progress_percentage"] = status_progress_map.get(update_data["status"], 0)

    # Detect other field changes
    changes = ItemUpdatesService.detect_changes(task, update_data)
    if changes:
        await ItemUpdatesService.track_field_changes(
            db=db,
            project_id=task.project_id,
            item_id=task.id,
            item_type='tasks',
            changes=changes,
            author_name=author_name,
            author_email=current_user.email
        )

    update_data["last_updated"] = datetime.utcnow()
    update_data["updated_by"] = "manual"

    for key, value in update_data.items():
        if hasattr(task, key):
            setattr(task, key, value)

    await db.commit()
    await db.refresh(task)

    return task.to_dict()


@router.delete("/tasks/{task_id}")
async def delete_task(
    task_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_org: Organization = Depends(get_current_organization),
    current_user: User = Depends(get_current_user),
    _: str = Depends(require_role("member"))
):
    """Delete a task."""
    # Get task
    task = await db.get(Task, task_id)
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")

    # Verify project belongs to organization
    project = await db.get(Project, task.project_id)
    if not project or project.organization_id != current_org.id:
        raise HTTPException(status_code=404, detail="Task not found")

    await db.delete(task)
    await db.commit()

    return {"message": "Task deleted successfully"}


# Bulk operations for AI updates
@router.post("/projects/{project_id}/risks/bulk-update")
async def bulk_update_risks(
    project_id: UUID,
    risks: List[dict],
    db: AsyncSession = Depends(get_db),
    current_org: Organization = Depends(get_current_organization),
    current_user: User = Depends(get_current_user),
    _: str = Depends(require_role("member"))
):
    """Bulk create/update risks from AI analysis."""
    # Verify project belongs to organization
    project_result = await db.execute(
        select(Project).where(
            and_(
                Project.id == project_id,
                Project.organization_id == current_org.id
            )
        )
    )
    project = project_result.scalar_one_or_none()
    if not project:
        raise HTTPException(status_code=404, detail="Project not found")

    updated_risks = []

    for risk_data in risks:
        # Check if risk already exists (by title and project_id)
        query = select(Risk).where(
            Risk.project_id == project_id,
            Risk.title == risk_data.get("title")
        )
        result = await db.execute(query)
        existing_risk = result.scalar_one_or_none()

        if existing_risk:
            # Update existing risk
            for key, value in risk_data.items():
                if key not in ["id", "project_id"] and hasattr(existing_risk, key):
                    # Convert string enums to enum instances if needed
                    if key == "severity" and isinstance(value, str):
                        value = RiskSeverity(value)
                    elif key == "status" and isinstance(value, str):
                        value = RiskStatus(value)
                    setattr(existing_risk, key, value)
            existing_risk.last_updated = datetime.utcnow()
            existing_risk.updated_by = "ai"
            updated_risks.append(existing_risk)
        else:
            # Create new risk
            new_risk = Risk(
                project_id=project_id,
                title=risk_data.get("title"),
                description=risk_data.get("description"),
                severity=RiskSeverity(risk_data.get("severity", "medium")),
                status=RiskStatus(risk_data.get("status", "identified")),
                mitigation=risk_data.get("mitigation"),
                impact=risk_data.get("impact"),
                probability=risk_data.get("probability"),
                ai_generated="true",
                ai_confidence=risk_data.get("ai_confidence", 0.8),
                source_content_id=risk_data.get("source_content_id"),
                updated_by="ai"
            )
            db.add(new_risk)
            updated_risks.append(new_risk)

    await db.commit()

    return [risk.to_dict() for risk in updated_risks]


@router.post("/projects/{project_id}/tasks/bulk-update")
async def bulk_update_tasks(
    project_id: UUID,
    tasks: List[dict],
    db: AsyncSession = Depends(get_db),
    current_org: Organization = Depends(get_current_organization),
    current_user: User = Depends(get_current_user),
    _: str = Depends(require_role("member"))
):
    """Bulk create/update tasks from AI analysis."""
    # Verify project belongs to organization
    project_result = await db.execute(
        select(Project).where(
            and_(
                Project.id == project_id,
                Project.organization_id == current_org.id
            )
        )
    )
    project = project_result.scalar_one_or_none()
    if not project:
        raise HTTPException(status_code=404, detail="Project not found")

    updated_tasks = []

    for task_data in tasks:
        # Check if task already exists (by title and project_id)
        query = select(Task).where(
            Task.project_id == project_id,
            Task.title == task_data.get("title")
        )
        result = await db.execute(query)
        existing_task = result.scalar_one_or_none()

        if existing_task:
            # Update existing task
            for key, value in task_data.items():
                if key not in ["id", "project_id"] and hasattr(existing_task, key):
                    # Convert string status to enum if needed
                    if key == "status" and isinstance(value, str):
                        value = TaskStatus(value)
                    elif key == "priority" and isinstance(value, str):
                        value = TaskPriority(value)
                    setattr(existing_task, key, value)
            existing_task.last_updated = datetime.utcnow()
            existing_task.updated_by = "ai"
            updated_tasks.append(existing_task)
        else:
            # Create new task
            new_task = Task(
                project_id=project_id,
                title=task_data.get("title"),
                description=task_data.get("description"),
                status=TaskStatus(task_data.get("status", "todo")),
                priority=TaskPriority(task_data.get("priority", "medium")),
                assignee=task_data.get("assignee"),
                due_date=task_data.get("due_date"),
                progress_percentage=task_data.get("progress_percentage", 0),
                blocker_description=task_data.get("blocker_description"),
                ai_generated="true",
                ai_confidence=task_data.get("ai_confidence", 0.8),
                source_content_id=task_data.get("source_content_id"),
                depends_on_risk_id=task_data.get("depends_on_risk_id"),
                updated_by="ai"
            )
            db.add(new_task)
            updated_tasks.append(new_task)

    await db.commit()

    return [task.to_dict() for task in updated_tasks]


# Blocker endpoints
@router.get("/projects/{project_id}/blockers")
async def get_project_blockers(
    project_id: UUID,
    status: Optional[BlockerStatus] = None,
    impact: Optional[BlockerImpact] = None,
    db: AsyncSession = Depends(get_db),
    current_org: Organization = Depends(get_current_organization),
    current_user: User = Depends(get_current_user),
    _: str = Depends(require_role("member"))
):
    """Get all blockers for a project with optional filtering."""
    # First verify project belongs to organization
    project_result = await db.execute(
        select(Project).where(
            and_(
                Project.id == project_id,
                Project.organization_id == current_org.id
            )
        )
    )
    project = project_result.scalar_one_or_none()

    if not project:
        raise HTTPException(status_code=404, detail="Project not found")

    # Build query
    query = select(Blocker).where(Blocker.project_id == project_id)

    # Apply filters
    if status:
        query = query.where(Blocker.status == status)
    if impact:
        query = query.where(Blocker.impact == impact)

    # Order by impact (critical first) and identified date
    query = query.order_by(Blocker.impact.desc(), Blocker.identified_date.desc())

    result = await db.execute(query)
    blockers = result.scalars().all()

    return [blocker.to_dict() for blocker in blockers]


@router.post("/projects/{project_id}/blockers")
async def create_blocker(
    project_id: UUID,
    blocker_data: BlockerCreate,
    db: AsyncSession = Depends(get_db),
    current_org: Organization = Depends(get_current_organization),
    current_user: User = Depends(get_current_user),
    _: str = Depends(require_role("member"))
):
    """Create a new blocker for a project."""
    # Verify project belongs to organization
    project_result = await db.execute(
        select(Project).where(
            and_(
                Project.id == project_id,
                Project.organization_id == current_org.id
            )
        )
    )
    project = project_result.scalar_one_or_none()

    if not project:
        raise HTTPException(status_code=404, detail="Project not found")

    # Create blocker
    new_blocker = Blocker(
        project_id=project_id,
        title=blocker_data.title,
        description=blocker_data.description,
        impact=blocker_data.impact,
        status=blocker_data.status,
        resolution=blocker_data.resolution,
        category=blocker_data.category,
        owner=blocker_data.owner,
        dependencies=blocker_data.dependencies,
        target_date=blocker_data.target_date,
        assigned_to=blocker_data.assigned_to,
        assigned_to_email=blocker_data.assigned_to_email,
        ai_generated="true" if blocker_data.ai_generated else "false",
        ai_confidence=blocker_data.ai_confidence,
        source_content_id=blocker_data.source_content_id,
        identified_date=datetime.utcnow(),
        last_updated=datetime.utcnow(),
        updated_by="manual"
    )

    db.add(new_blocker)
    await db.commit()
    await db.refresh(new_blocker)

    # Create CREATED update
    author_name = current_user.name or current_user.email or "User"
    await ItemUpdatesService.create_item_created_update(
        db=db,
        project_id=project_id,
        item_id=new_blocker.id,
        item_type='blockers',
        item_title=new_blocker.title,
        author_name=author_name,
        author_email=current_user.email,
        ai_generated=blocker_data.ai_generated
    )
    await db.commit()

    return new_blocker.to_dict()


@router.patch("/blockers/{blocker_id}")
async def update_blocker(
    blocker_id: UUID,
    blocker_update: BlockerUpdate,
    db: AsyncSession = Depends(get_db),
    current_org: Organization = Depends(get_current_organization),
    current_user: User = Depends(get_current_user),
    _: str = Depends(require_role("member"))
):
    """Update a blocker."""
    # Get blocker
    blocker = await db.get(Blocker, blocker_id)
    if not blocker:
        raise HTTPException(status_code=404, detail="Blocker not found")

    # Verify project belongs to organization
    project = await db.get(Project, blocker.project_id)
    if not project or project.organization_id != current_org.id:
        raise HTTPException(status_code=404, detail="Blocker not found")

    update_data = blocker_update.model_dump(exclude_unset=True)

    # Track status changes before updating
    author_name = current_user.name or current_user.email or "User"
    if "status" in update_data and update_data["status"] != blocker.status:
        await ItemUpdatesService.track_status_change(
            db=db,
            project_id=blocker.project_id,
            item_id=blocker.id,
            item_type='blockers',
            old_status=blocker.status,
            new_status=update_data["status"],
            author_name=author_name,
            author_email=current_user.email
        )

    # Track assignment changes (for blockers it can be 'assigned_to' or 'owner')
    if "assigned_to" in update_data and update_data["assigned_to"] != blocker.assigned_to:
        await ItemUpdatesService.track_assignment(
            db=db,
            project_id=blocker.project_id,
            item_id=blocker.id,
            item_type='blockers',
            old_assignee=blocker.assigned_to,
            new_assignee=update_data["assigned_to"],
            author_name=author_name,
            author_email=current_user.email
        )
    elif "owner" in update_data and update_data["owner"] != blocker.owner:
        await ItemUpdatesService.track_assignment(
            db=db,
            project_id=blocker.project_id,
            item_id=blocker.id,
            item_type='blockers',
            old_assignee=blocker.owner,
            new_assignee=update_data["owner"],
            author_name=author_name,
            author_email=current_user.email
        )

    # Detect other field changes
    changes = ItemUpdatesService.detect_changes(blocker, update_data)
    if changes:
        await ItemUpdatesService.track_field_changes(
            db=db,
            project_id=blocker.project_id,
            item_id=blocker.id,
            item_type='blockers',
            changes=changes,
            author_name=author_name,
            author_email=current_user.email
        )

    # Update fields
    for key, value in update_data.items():
        if hasattr(blocker, key):
            setattr(blocker, key, value)

    blocker.last_updated = datetime.utcnow()
    blocker.updated_by = "manual"

    await db.commit()
    await db.refresh(blocker)

    return blocker.to_dict()


@router.delete("/blockers/{blocker_id}")
async def delete_blocker(
    blocker_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_org: Organization = Depends(get_current_organization),
    current_user: User = Depends(get_current_user),
    _: str = Depends(require_role("member"))
):
    """Delete a blocker."""
    # Get blocker
    blocker = await db.get(Blocker, blocker_id)
    if not blocker:
        raise HTTPException(status_code=404, detail="Blocker not found")

    # Verify project belongs to organization
    project = await db.get(Project, blocker.project_id)
    if not project or project.organization_id != current_org.id:
        raise HTTPException(status_code=404, detail="Blocker not found")

    await db.delete(blocker)
    await db.commit()

    return {"message": "Blocker deleted successfully"}


# ItemUpdate endpoints - Specific routes to avoid path conflicts
async def _get_item_updates_internal(
    project_id: UUID,
    item_type: str,
    item_id: UUID,
    db: AsyncSession,
    current_org: Organization
):
    """Internal helper function to get item updates."""
    # Verify project belongs to organization
    project_result = await db.execute(
        select(Project).where(
            and_(
                Project.id == project_id,
                Project.organization_id == current_org.id
            )
        )
    )
    project = project_result.scalar_one_or_none()
    if not project:
        raise HTTPException(status_code=404, detail="Project not found")

    # Query item updates - ordered by most recent first
    query = select(ItemUpdate).where(
        and_(
            ItemUpdate.project_id == project_id,
            ItemUpdate.item_id == item_id,
            ItemUpdate.item_type == item_type
        )
    ).order_by(ItemUpdate.timestamp.desc())

    result = await db.execute(query)
    updates = result.scalars().all()

    return [update.to_dict() for update in updates]


async def _create_item_update_internal(
    project_id: UUID,
    item_type: str,
    item_id: UUID,
    update_data: ItemUpdateCreate,
    db: AsyncSession,
    current_org: Organization
):
    """Internal helper function to create item updates."""
    # Verify project belongs to organization
    project_result = await db.execute(
        select(Project).where(
            and_(
                Project.id == project_id,
                Project.organization_id == current_org.id
            )
        )
    )
    project = project_result.scalar_one_or_none()
    if not project:
        raise HTTPException(status_code=404, detail="Project not found")

    # Create update
    new_update = ItemUpdate(
        project_id=project_id,
        item_id=item_id,
        item_type=item_type,
        content=update_data.content,
        update_type=update_data.update_type,
        author_name=update_data.author_name,
        author_email=update_data.author_email,
        timestamp=datetime.utcnow()
    )

    db.add(new_update)
    await db.commit()
    await db.refresh(new_update)

    return new_update.to_dict()


# Specific routes for risks
@router.get("/projects/{project_id}/risks/{risk_id}/updates")
async def get_risk_updates(
    project_id: UUID,
    risk_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_org: Organization = Depends(get_current_organization),
    current_user: User = Depends(get_current_user),
    _: str = Depends(require_role("member"))
):
    """Get all updates for a specific risk."""
    return await _get_item_updates_internal(project_id, 'risks', risk_id, db, current_org)


@router.post("/projects/{project_id}/risks/{risk_id}/updates")
async def create_risk_update(
    project_id: UUID,
    risk_id: UUID,
    update_data: ItemUpdateCreate,
    db: AsyncSession = Depends(get_db),
    current_org: Organization = Depends(get_current_organization),
    current_user: User = Depends(get_current_user),
    _: str = Depends(require_role("member"))
):
    """Create a new update/comment for a risk."""
    return await _create_item_update_internal(project_id, 'risks', risk_id, update_data, db, current_org)


# Specific routes for tasks
@router.get("/projects/{project_id}/tasks/{task_id}/updates")
async def get_task_updates(
    project_id: UUID,
    task_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_org: Organization = Depends(get_current_organization),
    current_user: User = Depends(get_current_user),
    _: str = Depends(require_role("member"))
):
    """Get all updates for a specific task."""
    return await _get_item_updates_internal(project_id, 'tasks', task_id, db, current_org)


@router.post("/projects/{project_id}/tasks/{task_id}/updates")
async def create_task_update(
    project_id: UUID,
    task_id: UUID,
    update_data: ItemUpdateCreate,
    db: AsyncSession = Depends(get_db),
    current_org: Organization = Depends(get_current_organization),
    current_user: User = Depends(get_current_user),
    _: str = Depends(require_role("member"))
):
    """Create a new update/comment for a task."""
    return await _create_item_update_internal(project_id, 'tasks', task_id, update_data, db, current_org)


# Specific routes for blockers
@router.get("/projects/{project_id}/blockers/{blocker_id}/updates")
async def get_blocker_updates(
    project_id: UUID,
    blocker_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_org: Organization = Depends(get_current_organization),
    current_user: User = Depends(get_current_user),
    _: str = Depends(require_role("member"))
):
    """Get all updates for a specific blocker."""
    return await _get_item_updates_internal(project_id, 'blockers', blocker_id, db, current_org)


@router.post("/projects/{project_id}/blockers/{blocker_id}/updates")
async def create_blocker_update(
    project_id: UUID,
    blocker_id: UUID,
    update_data: ItemUpdateCreate,
    db: AsyncSession = Depends(get_db),
    current_org: Organization = Depends(get_current_organization),
    current_user: User = Depends(get_current_user),
    _: str = Depends(require_role("member"))
):
    """Create a new update/comment for a blocker."""
    return await _create_item_update_internal(project_id, 'blockers', blocker_id, update_data, db, current_org)


@router.delete("/updates/{update_id}")
async def delete_item_update(
    update_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_org: Organization = Depends(get_current_organization),
    current_user: User = Depends(get_current_user),
    _: str = Depends(require_role("member"))
):
    """Delete an item update."""
    # Get update
    update = await db.get(ItemUpdate, update_id)
    if not update:
        raise HTTPException(status_code=404, detail="Update not found")

    # Verify project belongs to organization
    project = await db.get(Project, update.project_id)
    if not project or project.organization_id != current_org.id:
        raise HTTPException(status_code=404, detail="Update not found")

    await db.delete(update)
    await db.commit()

    return {"message": "Update deleted successfully"}