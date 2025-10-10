"""Program management endpoints."""

from typing import List, Optional
from uuid import UUID
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import func, select, update, and_
from datetime import datetime

from db.database import db_manager, get_db
from dependencies.auth import get_current_organization, get_current_user, require_role
from models.organization import Organization
from models.user import User
from models.portfolio import Portfolio
from models.program import Program
from models.project import Project, ProjectStatus
from pydantic import BaseModel


router = APIRouter(prefix="/api/v1/programs", tags=["programs"])


async def validate_program_name_uniqueness(
    db: AsyncSession,
    name: str,
    organization_id: UUID,
    exclude_program_id: Optional[UUID] = None
) -> None:
    """
    Validate that a program name is unique within an organization.

    Args:
        db: Database session
        name: Program name to validate
        organization_id: Organization ID to check within
        exclude_program_id: Optional program ID to exclude from check (for updates)

    Raises:
        HTTPException: If a duplicate name is found
    """
    query = select(Program).where(
        and_(
            func.lower(Program.name) == func.lower(name),
            Program.organization_id == organization_id
        )
    )

    # Exclude the current program when updating
    if exclude_program_id:
        query = query.where(Program.id != exclude_program_id)

    result = await db.execute(query)
    existing_program = result.scalar_one_or_none()

    if existing_program:
        raise HTTPException(
            status_code=400,
            detail="Program with this name already exists in this organization"
        )


class ProgramCreate(BaseModel):
    """Schema for creating a program."""
    name: str
    description: Optional[str] = None
    portfolio_id: Optional[UUID] = None
    created_by: Optional[str] = None


class ProgramUpdate(BaseModel):
    """Schema for updating a program."""
    name: Optional[str] = None
    description: Optional[str] = None
    portfolio_id: Optional[UUID] = None


class ProjectSummary(BaseModel):
    """Simplified project for inclusion in program response."""
    id: UUID
    name: str
    description: Optional[str]
    status: str
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True


class ProgramResponse(BaseModel):
    """Schema for program response."""
    id: UUID
    name: str
    description: Optional[str]
    portfolio_id: Optional[UUID]
    portfolio_name: Optional[str] = None
    created_by: Optional[str]
    created_at: datetime
    updated_at: datetime
    project_count: int = 0
    projects: List[ProjectSummary] = []
    
    class Config:
        from_attributes = True


@router.post("/", response_model=ProgramResponse, status_code=201)
async def create_program(
    program: ProgramCreate,
    db: AsyncSession = Depends(get_db),
    current_org: Organization = Depends(get_current_organization),
    current_user: User = Depends(get_current_user)
):
    """Create a new program."""
    # Validate program name uniqueness
    await validate_program_name_uniqueness(db, program.name, current_org.id)

    # If portfolio_id provided, verify it exists in the same organization
    portfolio_name = None
    if program.portfolio_id:
        result = await db.execute(
            select(Portfolio).where(
                and_(
                    Portfolio.id == program.portfolio_id,
                    Portfolio.organization_id == current_org.id
                )
            )
        )
        portfolio = result.scalar_one_or_none()
        if not portfolio:
            raise HTTPException(status_code=404, detail="Portfolio not found")
        portfolio_name = portfolio.name

    db_program = Program(
        name=program.name,
        description=program.description,
        portfolio_id=program.portfolio_id,
        created_by=program.created_by or current_user.email,
        organization_id=current_org.id
    )
    db.add(db_program)
    await db.commit()
    await db.refresh(db_program)
    
    # Get project count
    project_count_result = await db.execute(
        select(func.count(Project.id)).where(
            and_(
                Project.program_id == db_program.id,
                Project.organization_id == current_org.id
            )
        )
    )
    project_count = project_count_result.scalar()
    
    response = ProgramResponse(
        **db_program.__dict__,
        portfolio_name=portfolio_name,
        project_count=project_count or 0
    )
    return response


@router.get("/", response_model=List[ProgramResponse])
async def list_programs(
    portfolio_id: Optional[UUID] = Query(None, description="Filter by portfolio"),
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=1000),
    db: AsyncSession = Depends(get_db),
    current_org: Organization = Depends(get_current_organization)
):
    """List all programs with optional portfolio filter."""
    query = select(Program).where(Program.organization_id == current_org.id).offset(skip).limit(limit)
    
    if portfolio_id:
        query = query.where(Program.portfolio_id == portfolio_id)
    
    result = await db.execute(query)
    programs = result.scalars().all()
    
    response = []
    for program in programs:
        portfolio_name = None
        if program.portfolio_id:
            portfolio_result = await db.execute(
                select(Portfolio).where(
                    and_(
                        Portfolio.id == program.portfolio_id,
                        Portfolio.organization_id == current_org.id
                    )
                )
            )
            portfolio = portfolio_result.scalar_one_or_none()
            if portfolio:
                portfolio_name = portfolio.name
        
        project_count_result = await db.execute(
            select(func.count(Project.id)).where(
                and_(
                    Project.program_id == program.id,
                    Project.organization_id == current_org.id
                )
            )
        )
        project_count = project_count_result.scalar()
        
        response.append(ProgramResponse(
            **program.__dict__,
            portfolio_name=portfolio_name,
            project_count=project_count or 0
        ))
    
    return response


@router.get("/{program_id}", response_model=ProgramResponse)
async def get_program(
    program_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_org: Organization = Depends(get_current_organization)
):
    """Get a specific program by ID."""
    result = await db.execute(
        select(Program).where(
            and_(
                Program.id == program_id,
                Program.organization_id == current_org.id
            )
        )
    )
    program = result.scalar_one_or_none()
    if not program:
        raise HTTPException(status_code=404, detail="Program not found")
    
    portfolio_name = None
    if program.portfolio_id:
        portfolio_result = await db.execute(
            select(Portfolio).where(
                and_(
                    Portfolio.id == program.portfolio_id,
                    Portfolio.organization_id == current_org.id
                )
            )
        )
        portfolio = portfolio_result.scalar_one_or_none()
        if portfolio:
            portfolio_name = portfolio.name
    
    # Fetch projects for this program
    projects_result = await db.execute(
        select(Project).where(
            and_(
                Project.program_id == program.id,
                Project.organization_id == current_org.id
            )
        )
    )
    projects = projects_result.scalars().all()
    
    # Convert projects to ProjectSummary
    project_summaries = [
        ProjectSummary(
            id=proj.id,
            name=proj.name,
            description=proj.description,
            status=proj.status.value,
            created_at=proj.created_at,
            updated_at=proj.updated_at
        )
        for proj in projects
    ]
    
    return ProgramResponse(
        **program.__dict__,
        portfolio_name=portfolio_name,
        project_count=len(projects),
        projects=project_summaries
    )


@router.put("/{program_id}", response_model=ProgramResponse)
async def update_program(
    program_id: UUID,
    program_update: ProgramUpdate,
    db: AsyncSession = Depends(get_db),
    current_org: Organization = Depends(get_current_organization),
    _: str = Depends(require_role("member"))
):
    """Update a program."""
    result = await db.execute(
        select(Program).where(
            and_(
                Program.id == program_id,
                Program.organization_id == current_org.id
            )
        )
    )
    program = result.scalar_one_or_none()
    if not program:
        raise HTTPException(status_code=404, detail="Program not found")

    # Validate name uniqueness if name is being updated
    if program_update.name is not None:
        await validate_program_name_uniqueness(
            db,
            program_update.name,
            current_org.id,
            exclude_program_id=program_id
        )
        program.name = program_update.name
    if program_update.description is not None:
        program.description = program_update.description
    # Check if portfolio_id field was provided in the update (could be None to make standalone)
    if 'portfolio_id' in program_update.model_dump(exclude_unset=True):
        # Only verify portfolio exists if a non-null portfolio_id is provided
        if program_update.portfolio_id is not None:
            portfolio_result = await db.execute(
                select(Portfolio).where(
                    and_(
                        Portfolio.id == program_update.portfolio_id,
                        Portfolio.organization_id == current_org.id
                    )
                )
            )
            portfolio = portfolio_result.scalar_one_or_none()
            if not portfolio:
                raise HTTPException(status_code=404, detail="Portfolio not found")
        # Set portfolio_id to the provided value (could be None for standalone)
        program.portfolio_id = program_update.portfolio_id
    
    program.updated_at = datetime.utcnow()
    await db.commit()
    await db.refresh(program)
    
    portfolio_name = None
    if program.portfolio_id:
        portfolio_result = await db.execute(
            select(Portfolio).where(
                and_(
                    Portfolio.id == program.portfolio_id,
                    Portfolio.organization_id == current_org.id
                )
            )
        )
        portfolio = portfolio_result.scalar_one_or_none()
        if portfolio:
            portfolio_name = portfolio.name
    
    project_count_result = await db.execute(
        select(func.count(Project.id)).where(
            and_(
                Project.program_id == program.id,
                Project.organization_id == current_org.id
            )
        )
    )
    project_count = project_count_result.scalar()
    
    return ProgramResponse(
        **program.__dict__,
        portfolio_name=portfolio_name,
        project_count=project_count or 0
    )


@router.get("/{program_id}/deletion-impact")
async def get_program_deletion_impact(
    program_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_org: Organization = Depends(get_current_organization)
):
    """Get information about what will be affected by deleting a program."""
    result = await db.execute(
        select(Program).where(
            and_(
                Program.id == program_id,
                Program.organization_id == current_org.id
            )
        )
    )
    program = result.scalar_one_or_none()
    if not program:
        raise HTTPException(status_code=404, detail="Program not found")

    # Get all projects in this program
    projects_result = await db.execute(
        select(Project).where(
            and_(
                Project.program_id == program_id,
                Project.organization_id == current_org.id
            )
        )
    )
    projects = projects_result.scalars().all()

    return {
        "program": {
            "id": str(program.id),
            "name": program.name,
            "description": program.description,
            "portfolio_id": str(program.portfolio_id) if program.portfolio_id else None
        },
        "affected_projects": [
            {
                "id": str(p.id),
                "name": p.name,
                "description": p.description
            } for p in projects
        ],
        "total_projects": len(projects)
    }


@router.delete("/{program_id}")
async def delete_program(
    program_id: UUID,
    cascade_delete: bool = Query(False, description="Delete all related projects if True, otherwise make them standalone"),
    db: AsyncSession = Depends(get_db),
    current_org: Organization = Depends(get_current_organization),
    _: str = Depends(require_role("admin"))
):
    """Delete a program with option to cascade or orphan related projects."""
    result = await db.execute(
        select(Program).where(
            and_(
                Program.id == program_id,
                Program.organization_id == current_org.id
            )
        )
    )
    program = result.scalar_one_or_none()
    if not program:
        raise HTTPException(status_code=404, detail="Program not found")

    # Get all projects in this program
    projects_result = await db.execute(
        select(Project).where(
            and_(
                Project.program_id == program_id,
                Project.organization_id == current_org.id
            )
        )
    )
    projects = projects_result.scalars().all()

    affected_entities = {
        "projects": [{"id": str(p.id), "name": p.name} for p in projects]
    }

    portfolio_id = program.portfolio_id  # Remember portfolio to assign to orphaned projects

    if cascade_delete:
        # Delete all projects manually since database constraint is SET NULL, not CASCADE
        for project in projects:
            await db.delete(project)

    # Delete the program
    # Note: If cascade_delete=False, projects will automatically have program_id set to NULL
    # due to the SET NULL foreign key constraint, making them standalone while keeping their portfolio_id
    await db.delete(program)
    await db.commit()

    return {
        "message": f"Program deleted successfully. {'All related projects deleted.' if cascade_delete else 'Related projects are now standalone.'}",
        "affected_entities": affected_entities,
        "cascade_delete": cascade_delete
    }


@router.get("/{program_id}/projects")
async def get_program_projects(
    program_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_org: Organization = Depends(get_current_organization)
):
    """Get all projects in a program."""
    result = await db.execute(
        select(Program).where(
            and_(
                Program.id == program_id,
                Program.organization_id == current_org.id
            )
        )
    )
    program = result.scalar_one_or_none()
    if not program:
        raise HTTPException(status_code=404, detail="Program not found")
    
    projects_result = await db.execute(
        select(Project).where(
            and_(
                Project.program_id == program_id,
                Project.organization_id == current_org.id
            )
        )
    )
    projects = projects_result.scalars().all()
    return projects


@router.post("/{program_id}/assign-to-portfolio/{portfolio_id}")
async def assign_program_to_portfolio(
    program_id: UUID,
    portfolio_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_org: Organization = Depends(get_current_organization),
    _: str = Depends(require_role("member"))
):
    """Assign a program to a portfolio."""
    program_result = await db.execute(
        select(Program).where(
            and_(
                Program.id == program_id,
                Program.organization_id == current_org.id
            )
        )
    )
    program = program_result.scalar_one_or_none()
    if not program:
        raise HTTPException(status_code=404, detail="Program not found")
    
    portfolio_result = await db.execute(
        select(Portfolio).where(
            and_(
                Portfolio.id == portfolio_id,
                Portfolio.organization_id == current_org.id
            )
        )
    )
    portfolio = portfolio_result.scalar_one_or_none()
    if not portfolio:
        raise HTTPException(status_code=404, detail="Portfolio not found")
    
    program.portfolio_id = portfolio_id
    program.updated_at = datetime.utcnow()
    
    # Update all projects in this program to have the same portfolio_id
    await db.execute(
        update(Project)
        .where(
            and_(
                Project.program_id == program_id,
                Project.organization_id == current_org.id
            )
        )
        .values(portfolio_id=portfolio_id, updated_at=datetime.utcnow())
    )
    
    await db.commit()
    
    return {"message": "Program assigned to portfolio successfully"}


@router.post("/{program_id}/remove-from-portfolio")
async def remove_program_from_portfolio(
    program_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_org: Organization = Depends(get_current_organization),
    _: str = Depends(require_role("member"))
):
    """Remove a program from its portfolio (make it standalone)."""
    result = await db.execute(
        select(Program).where(
            and_(
                Program.id == program_id,
                Program.organization_id == current_org.id
            )
        )
    )
    program = result.scalar_one_or_none()
    if not program:
        raise HTTPException(status_code=404, detail="Program not found")
    
    program.portfolio_id = None
    program.updated_at = datetime.utcnow()
    
    # Update all projects in this program to remove portfolio_id
    await db.execute(
        update(Project)
        .where(
            and_(
                Project.program_id == program_id,
                Project.organization_id == current_org.id
            )
        )
        .values(portfolio_id=None, updated_at=datetime.utcnow())
    )
    
    await db.commit()
    
    return {"message": "Program removed from portfolio successfully"}


@router.get("/{program_id}/statistics")
async def get_program_statistics(
    program_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_org: Organization = Depends(get_current_organization)
):
    """Get statistics for a program."""
    # Check program exists
    result = await db.execute(
        select(Program).where(
            and_(
                Program.id == program_id,
                Program.organization_id == current_org.id
            )
        )
    )
    program = result.scalar_one_or_none()
    if not program:
        raise HTTPException(status_code=404, detail="Program not found")
    
    # Count projects in this program
    projects_count_result = await db.execute(
        select(func.count(Project.id)).where(
            and_(
                Project.program_id == program_id,
                Project.organization_id == current_org.id
            )
        )
    )
    projects_count = projects_count_result.scalar() or 0
    
    # Count archived projects
    from models.project import ProjectStatus
    archived_projects_result = await db.execute(
        select(func.count(Project.id))
        .where(
            and_(
                Project.program_id == program_id,
                Project.organization_id == current_org.id,
                Project.status == ProjectStatus.ARCHIVED
            )
        )
    )
    archived_projects_count = archived_projects_result.scalar() or 0
    
    # Count content items for all projects in program
    from models.content import Content
    content_count_result = await db.execute(
        select(func.count(Content.id))
        .join(Project, Content.project_id == Project.id)
        .where(
            and_(
                Project.program_id == program_id,
                Project.organization_id == current_org.id
            )
        )
    )
    content_count = content_count_result.scalar() or 0
    
    # Count summaries for all projects in program
    from models.summary import Summary
    summaries_count_result = await db.execute(
        select(func.count(Summary.id))
        .join(Project, Summary.project_id == Project.id)
        .where(
            and_(
                Project.program_id == program_id,
                Project.organization_id == current_org.id
            )
        )
    )
    summaries_count = summaries_count_result.scalar() or 0
    
    # Count activities for all projects in program
    from models.activity import Activity
    activities_count_result = await db.execute(
        select(func.count(Activity.id))
        .join(Project, Activity.project_id == Project.id)
        .where(
            and_(
                Project.program_id == program_id,
                Project.organization_id == current_org.id
            )
        )
    )
    activities_count = activities_count_result.scalar() or 0
    
    # Get portfolio info if exists
    portfolio_info = None
    if program.portfolio_id:
        portfolio_result = await db.execute(
            select(Portfolio.id, Portfolio.name)
            .where(
                and_(
                    Portfolio.id == program.portfolio_id,
                    Portfolio.organization_id == current_org.id
                )
            )
        )
        portfolio = portfolio_result.first()
        if portfolio:
            portfolio_info = {
                "id": str(portfolio.id),
                "name": portfolio.name
            }
    
    return {
        "program_id": str(program_id),
        "program_name": program.name,
        "portfolio": portfolio_info,
        "project_count": projects_count,
        "archived_project_count": archived_projects_count,
        "content_count": content_count,
        "summary_count": summaries_count,
        "activity_count": activities_count,
        "created_at": program.created_at.isoformat(),
        "updated_at": program.updated_at.isoformat() if program.updated_at else None
    }