from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime
from uuid import UUID
from sqlalchemy.ext.asyncio import AsyncSession

from db.database import db_manager, get_db
from dependencies.auth import get_current_organization, get_current_user, require_role
from models.organization import Organization
from models.user import User
from models.project import ProjectStatus
from services.hierarchy.project_service import ProjectService
from utils.logger import get_logger

router = APIRouter()
logger = get_logger(__name__)


class ProjectMemberModel(BaseModel):
    name: str
    email: str
    role: str


class CreateProjectRequest(BaseModel):
    name: str
    description: Optional[str] = None
    members: Optional[List[ProjectMemberModel]] = []
    portfolio_id: Optional[str] = None
    program_id: Optional[str] = None


class UpdateProjectRequest(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    status: Optional[str] = None
    portfolio_id: Optional[UUID] = None
    program_id: Optional[UUID] = None
    members: Optional[List[ProjectMemberModel]] = None


class ProjectResponse(BaseModel):
    id: str
    name: str
    description: Optional[str]
    created_by: str
    created_at: datetime
    updated_at: Optional[datetime]
    status: str
    members: List[ProjectMemberModel]
    portfolio_id: Optional[str] = None
    program_id: Optional[str] = None


class AddMemberRequest(BaseModel):
    name: str
    email: str
    role: str = "member"



@router.post("", response_model=ProjectResponse)
async def create_project(
    request: CreateProjectRequest,
    session: AsyncSession = Depends(get_db),
    current_org: Organization = Depends(get_current_organization),
    current_user: User = Depends(get_current_user)
):
    try:
        # Convert member models to dicts
        members_data = None
        if request.members:
            members_data = [member.model_dump() for member in request.members]
        
        # Create project using service
        project = await ProjectService.create_project(
            session=session,
            name=request.name,
            organization_id=current_org.id,
            description=request.description,
            created_by=current_user.email,
            created_by_id=str(current_user.id),  # Pass the actual user ID
            members=members_data,
            portfolio_id=request.portfolio_id,
            program_id=request.program_id
        )
        
        # Convert to response model
        return ProjectResponse(
            id=str(project.id),
            name=project.name,
            description=project.description,
            created_by=project.created_by,
            created_at=project.created_at,
            updated_at=project.updated_at,
            status=project.status.value,
            members=[
                ProjectMemberModel(
                    name=member.name,
                    email=member.email,
                    role=member.role
                ) for member in project.members
            ],
            portfolio_id=str(project.portfolio_id) if project.portfolio_id else None,
            program_id=str(project.program_id) if project.program_id else None
        )
    except ValueError as e:
        # Handle duplicate project name error
        logger.warning(f"Project creation validation error: {e}")
        raise HTTPException(status_code=409, detail=str(e))
    except Exception as e:
        logger.error(f"Failed to create project: {e}")
        raise HTTPException(status_code=500, detail="Failed to create project")


@router.get("", response_model=List[ProjectResponse])
async def list_projects(
    status: Optional[str] = None,
    session: AsyncSession = Depends(get_db),
    current_org: Organization = Depends(get_current_organization)
):
    try:
        # Convert status string to enum if provided
        status_enum = None
        if status:
            try:
                status_enum = ProjectStatus(status)
            except ValueError:
                raise HTTPException(status_code=400, detail=f"Invalid status: {status}")
        
        # Get projects from service
        projects = await ProjectService.list_projects(session, current_org.id, status=status_enum)
        
        # Convert to response models
        return [
            ProjectResponse(
                id=str(project.id),
                name=project.name,
                description=project.description,
                created_by=project.created_by,
                created_at=project.created_at,
                updated_at=project.updated_at,
                status=project.status.value,
                members=[
                    ProjectMemberModel(
                        name=member.name,
                        email=member.email,
                        role=member.role
                    ) for member in project.members
                ],
                portfolio_id=str(project.portfolio_id) if project.portfolio_id else None,
                program_id=str(project.program_id) if project.program_id else None
            ) for project in projects
        ]
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to list projects: {e}")
        raise HTTPException(status_code=500, detail="Failed to list projects")


@router.get("/{project_id}", response_model=ProjectResponse)
async def get_project(
    project_id: str,
    session: AsyncSession = Depends(get_db),
    current_org: Organization = Depends(get_current_organization)
):
    try:
        # Convert string to UUID
        try:
            project_uuid = UUID(project_id)
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid project ID format")
        
        # Get project from service
        project = await ProjectService.get_project(session, project_uuid, current_org.id)
        
        if not project:
            raise HTTPException(status_code=404, detail="Project not found")
        
        # Convert to response model
        return ProjectResponse(
            id=str(project.id),
            name=project.name,
            description=project.description,
            created_by=project.created_by,
            created_at=project.created_at,
            updated_at=project.updated_at,
            status=project.status.value,
            members=[
                ProjectMemberModel(
                    name=member.name,
                    email=member.email,
                    role=member.role
                ) for member in project.members
            ],
            portfolio_id=str(project.portfolio_id) if project.portfolio_id else None,
            program_id=str(project.program_id) if project.program_id else None
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get project: {e}")
        raise HTTPException(status_code=500, detail="Failed to get project")


@router.put("/{project_id}", response_model=ProjectResponse)
async def update_project(
    project_id: str,
    request: UpdateProjectRequest,
    session: AsyncSession = Depends(get_db),
    current_org: Organization = Depends(get_current_organization),
    _: str = Depends(require_role("member"))
):
    try:
        # Convert string to UUID
        try:
            project_uuid = UUID(project_id)
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid project ID format")
        
        # Convert status string to enum if provided
        status_enum = None
        if request.status:
            try:
                status_enum = ProjectStatus(request.status)
            except ValueError:
                raise HTTPException(status_code=400, detail=f"Invalid status: {request.status}")
        
        # Convert member models to dicts
        members_data = None
        if request.members is not None:
            members_data = [member.model_dump() for member in request.members]

        # Build kwargs for update, only including fields that were explicitly set
        update_kwargs = {
            'session': session,
            'project_id': project_uuid,
            'organization_id': current_org.id,
        }

        # Only add fields if they were explicitly set in the request
        request_dict = request.model_dump(exclude_unset=True)
        if 'name' in request_dict:
            update_kwargs['name'] = request.name
        if 'description' in request_dict:
            update_kwargs['description'] = request.description
        if 'status' in request_dict:
            update_kwargs['status'] = status_enum
        if 'portfolio_id' in request_dict:
            update_kwargs['portfolio_id'] = request.portfolio_id
        if 'program_id' in request_dict:
            update_kwargs['program_id'] = request.program_id
        if 'members' in request_dict:
            update_kwargs['members'] = members_data

        # Update project using service
        project = await ProjectService.update_project(**update_kwargs)
        
        if not project:
            raise HTTPException(status_code=404, detail="Project not found")
        
        # Convert to response model
        return ProjectResponse(
            id=str(project.id),
            name=project.name,
            description=project.description,
            created_by=project.created_by,
            created_at=project.created_at,
            updated_at=project.updated_at,
            status=project.status.value,
            members=[
                ProjectMemberModel(
                    name=member.name,
                    email=member.email,
                    role=member.role
                ) for member in project.members
            ],
            portfolio_id=str(project.portfolio_id) if project.portfolio_id else None,
            program_id=str(project.program_id) if project.program_id else None
        )
    except HTTPException:
        raise
    except ValueError as e:
        # Handle duplicate project name error
        logger.warning(f"Project update validation error: {e}")
        raise HTTPException(status_code=409, detail=str(e))
    except Exception as e:
        logger.error(f"Failed to update project: {e}")
        raise HTTPException(status_code=500, detail="Failed to update project")


@router.patch("/{project_id}/archive")
async def archive_project(
    project_id: str,
    session: AsyncSession = Depends(get_db),
    current_org: Organization = Depends(get_current_organization),
    _: str = Depends(require_role("member"))
):
    try:
        # Convert string to UUID
        try:
            project_uuid = UUID(project_id)
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid project ID format")
        
        # Archive project using service
        success = await ProjectService.archive_project(session, project_uuid, current_org.id)
        
        if not success:
            raise HTTPException(status_code=404, detail="Project not found")
        
        return {"message": "Project archived successfully"}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to archive project: {e}")
        raise HTTPException(status_code=500, detail="Failed to archive project")


@router.patch("/{project_id}/restore")
async def restore_project(
    project_id: str,
    session: AsyncSession = Depends(get_db),
    current_org: Organization = Depends(get_current_organization),
    _: str = Depends(require_role("member"))
):
    try:
        # Convert string to UUID
        try:
            project_uuid = UUID(project_id)
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid project ID format")
        
        # Restore project using service
        success = await ProjectService.restore_project(session, project_uuid, current_org.id)
        
        if not success:
            raise HTTPException(status_code=404, detail="Project not found")
        
        return {"message": "Project restored successfully"}
    except ValueError as e:
        # Handle duplicate name error
        logger.warning(f"Cannot restore project due to duplicate name: {e}")
        raise HTTPException(status_code=409, detail=str(e))
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to restore project: {e}")
        raise HTTPException(status_code=500, detail="Failed to restore project")


@router.delete("/{project_id}")
async def delete_project(
    project_id: str,
    session: AsyncSession = Depends(get_db),
    current_org: Organization = Depends(get_current_organization),
    _: str = Depends(require_role("admin"))
):
    try:
        # Convert string to UUID
        try:
            project_uuid = UUID(project_id)
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid project ID format")
        
        # Permanently delete project and all related data
        success = await ProjectService.delete_project(session, project_uuid, current_org.id)
        
        if not success:
            raise HTTPException(status_code=404, detail="Project not found")
        
        return {"message": "Project permanently deleted successfully"}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to delete project: {e}")
        raise HTTPException(status_code=500, detail="Failed to delete project")


@router.post("/{project_id}/members")
async def add_project_member(
    project_id: str,
    request: AddMemberRequest,
    session: AsyncSession = Depends(get_db),
    current_org: Organization = Depends(get_current_organization),
    _: str = Depends(require_role("member"))
):
    try:
        # Convert string to UUID
        try:
            project_uuid = UUID(project_id)
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid project ID format")
        
        # Add member using service
        member = await ProjectService.add_member(
            session=session,
            project_id=project_uuid,
            organization_id=current_org.id,
            name=request.name,
            email=request.email,
            role=request.role
        )
        
        if not member:
            raise HTTPException(
                status_code=400, 
                detail="Failed to add member. Project may not exist or member already exists."
            )
        
        return {
            "message": "Member added successfully",
            "member": {
                "name": member.name,
                "email": member.email,
                "role": member.role
            }
        }
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to add member: {e}")
        raise HTTPException(status_code=500, detail="Failed to add member")


@router.delete("/{project_id}/members/{email}")
async def remove_project_member(
    project_id: str,
    email: str,
    session: AsyncSession = Depends(get_db),
    current_org: Organization = Depends(get_current_organization),
    _: str = Depends(require_role("member"))
):
    try:
        # Convert string to UUID
        try:
            project_uuid = UUID(project_id)
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid project ID format")
        
        # Remove member using service
        success = await ProjectService.remove_member(
            session=session,
            project_id=project_uuid,
            organization_id=current_org.id,
            member_email=email
        )
        
        if not success:
            raise HTTPException(status_code=404, detail="Member not found in project")
        
        return {"message": "Member removed successfully"}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to remove member: {e}")
        raise HTTPException(status_code=500, detail="Failed to remove member")
