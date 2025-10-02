"""API endpoints for project risks and tasks management."""

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update, delete, and_
from typing import List, Optional
from uuid import UUID
from datetime import datetime
from pydantic import BaseModel, Field

from db.database import get_db
from dependencies.auth import get_current_organization, get_current_user, require_role
from models.organization import Organization
from models.user import User
from models.risk import Risk, RiskSeverity, RiskStatus
from models.task import Task, TaskStatus, TaskPriority
from models.blocker import Blocker, BlockerImpact, BlockerStatus
from models.project import Project


router = APIRouter(prefix="/api", tags=["risks-tasks"])


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
    db: AsyncSession = Depends(get_db)
):
    """Create a new risk for a project."""
    # Verify project exists
    project = await db.get(Project, project_id)
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
        ai_generated="true" if risk_data.ai_generated else "false",
        ai_confidence=risk_data.ai_confidence,
        source_content_id=risk_data.source_content_id,
        updated_by="manual"
    )

    db.add(risk)
    await db.commit()
    await db.refresh(risk)

    return risk.to_dict()


@router.patch("/risks/{risk_id}")
async def update_risk(
    risk_id: UUID,
    risk_data: RiskUpdate,
    db: AsyncSession = Depends(get_db)
):
    """Update an existing risk."""
    risk = await db.get(Risk, risk_id)
    if not risk:
        raise HTTPException(status_code=404, detail="Risk not found")

    update_data = risk_data.dict(exclude_unset=True)

    # Handle status changes
    if "status" in update_data and update_data["status"] == RiskStatus.RESOLVED:
        update_data["resolved_date"] = datetime.utcnow()

    update_data["last_updated"] = datetime.utcnow()
    update_data["updated_by"] = "manual"

    for key, value in update_data.items():
        if hasattr(risk, key):
            setattr(risk, key, value)

    await db.commit()
    await db.refresh(risk)

    return risk.to_dict()


@router.delete("/risks/{risk_id}")
async def delete_risk(risk_id: UUID, db: AsyncSession = Depends(get_db)):
    """Delete a risk."""
    risk = await db.get(Risk, risk_id)
    if not risk:
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
    db: AsyncSession = Depends(get_db)
):
    """Get all tasks for a project with optional filtering."""
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
    db: AsyncSession = Depends(get_db)
):
    """Create a new task for a project."""
    # Verify project exists
    project = await db.get(Project, project_id)
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

    return task.to_dict()


@router.patch("/tasks/{task_id}")
async def update_task(
    task_id: UUID,
    task_data: TaskUpdate,
    db: AsyncSession = Depends(get_db)
):
    """Update an existing task."""
    task = await db.get(Task, task_id)
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")

    update_data = task_data.dict(exclude_unset=True)

    # Handle status changes
    if "status" in update_data:
        if update_data["status"] == TaskStatus.COMPLETED and not task.completed_date:
            update_data["completed_date"] = datetime.utcnow()
            update_data["progress_percentage"] = 100
        elif update_data["status"] != TaskStatus.COMPLETED:
            update_data["completed_date"] = None

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

    update_data["last_updated"] = datetime.utcnow()
    update_data["updated_by"] = "manual"

    for key, value in update_data.items():
        if hasattr(task, key):
            setattr(task, key, value)

    await db.commit()
    await db.refresh(task)

    return task.to_dict()


@router.delete("/tasks/{task_id}")
async def delete_task(task_id: UUID, db: AsyncSession = Depends(get_db)):
    """Delete a task."""
    task = await db.get(Task, task_id)
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")

    await db.delete(task)
    await db.commit()

    return {"message": "Task deleted successfully"}


# Bulk operations for AI updates
@router.post("/projects/{project_id}/risks/bulk-update")
async def bulk_update_risks(
    project_id: UUID,
    risks: List[dict],
    db: AsyncSession = Depends(get_db)
):
    """Bulk create/update risks from AI analysis."""
    # Verify project exists
    project = await db.get(Project, project_id)
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
                ai_generated=True,
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
    db: AsyncSession = Depends(get_db)
):
    """Bulk create/update tasks from AI analysis."""
    # Verify project exists
    project = await db.get(Project, project_id)
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
                ai_generated=True,
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

    # Update fields
    update_data = blocker_update.model_dump(exclude_unset=True)
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