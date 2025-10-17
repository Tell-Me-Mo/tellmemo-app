"""Project service layer for business logic and database operations."""

from typing import List, Optional, Any
from uuid import UUID
from datetime import datetime
from sqlalchemy import select, update, delete, desc
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from models.project import Project, ProjectMember, ProjectStatus
from services.activity.activity_service import ActivityService
from utils.logger import get_logger, sanitize_for_log

logger = get_logger(__name__)


class ProjectService:
    """Service class for project-related operations."""
    
    @staticmethod
    async def create_project(
        session: AsyncSession,
        name: str,
        organization_id: UUID,
        description: Optional[str] = None,
        created_by: str = "system",
        created_by_id: Optional[str] = None,
        members: Optional[List[dict]] = None,
        portfolio_id: Optional[str] = None,
        program_id: Optional[str] = None
    ) -> Project:
        """Create a new project with optional members."""
        try:
            # Check if a project with the same name already exists in the organization
            existing_stmt = select(Project).where(
                Project.name == name,
                Project.organization_id == organization_id,
                Project.status != ProjectStatus.ARCHIVED
            )
            existing_result = await session.execute(existing_stmt)
            existing_project = existing_result.scalar_one_or_none()
            
            if existing_project:
                logger.warning(f"Project with name '{sanitize_for_log(name)}' already exists")
                raise ValueError(f"A project with the name '{name}' already exists")
            
            # Create the project
            project = Project(
                name=name,
                description=description,
                created_by=created_by,
                status=ProjectStatus.ACTIVE,
                organization_id=organization_id,
                portfolio_id=UUID(portfolio_id) if portfolio_id else None,
                program_id=UUID(program_id) if program_id else None
            )
            session.add(project)
            
            # Flush to get the project ID
            await session.flush()
            
            # Add members if provided
            if members:
                for member_data in members:
                    member = ProjectMember(
                        project_id=project.id,
                        name=member_data.get("name"),
                        email=member_data.get("email"),
                        role=member_data.get("role", "member")
                    )
                    session.add(member)
                await session.flush()
            
            await session.refresh(project, ["members"])
            
            # Log activity for project creation
            await ActivityService.log_project_created(
                db=session,
                project_id=project.id,
                project_name=project.name,
                created_by=created_by,
                user_id=created_by_id  # Pass the actual user ID
            )
            
            logger.info(f"Created project: {project.id} - {project.name}")
            return project
            
        except Exception as e:
            logger.error(f"Failed to create project: {e}")
            raise
    
    @staticmethod
    async def get_project(session: AsyncSession, project_id: UUID, organization_id: Optional[UUID] = None) -> Optional[Project]:
        """Get a project by ID with its members."""
        try:
            stmt = select(Project).where(
                Project.id == project_id
            )
            if organization_id:
                stmt = stmt.where(Project.organization_id == organization_id)
            stmt = stmt.options(selectinload(Project.members))
            
            result = await session.execute(stmt)
            project = result.scalar_one_or_none()
            
            if project:
                logger.info(f"Retrieved project: {project_id}")
            else:
                logger.warning(f"Project not found: {project_id}")
                
            return project
            
        except Exception as e:
            logger.error(f"Failed to get project {project_id}: {e}")
            raise
    
    @staticmethod
    async def list_projects(
        session: AsyncSession,
        organization_id: UUID,
        status: Optional[ProjectStatus] = None
    ) -> List[Project]:
        """List all projects with optional status filter."""
        try:
            stmt = select(Project).where(
                Project.organization_id == organization_id
            ).options(selectinload(Project.members))

            if status:
                stmt = stmt.where(Project.status == status)
            
            stmt = stmt.order_by(Project.created_at.desc())
            
            result = await session.execute(stmt)
            projects = result.scalars().all()
            
            logger.info(f"Listed {len(projects)} projects")
            return projects
            
        except Exception as e:
            logger.error(f"Failed to list projects: {e}")
            raise
    
    @staticmethod
    async def update_project(
        session: AsyncSession,
        project_id: UUID,
        organization_id: UUID,
        **kwargs
    ) -> Optional[Project]:
        """Update a project and its members."""
        try:
            # Extract kwargs
            name = kwargs.get('name')
            description = kwargs.get('description')
            status = kwargs.get('status')
            portfolio_id = kwargs.get('portfolio_id')
            program_id = kwargs.get('program_id')
            members = kwargs.get('members')

            # Get the existing project
            project = await ProjectService.get_project(session, project_id, organization_id)
            if not project:
                return None

            # Check if new name conflicts with existing project in the same organization
            if name is not None and name != project.name:
                existing_stmt = select(Project).where(
                    Project.name == name,
                    Project.organization_id == organization_id,
                    Project.id != project_id,
                    Project.status != ProjectStatus.ARCHIVED
                )
                existing_result = await session.execute(existing_stmt)
                existing_project = existing_result.scalar_one_or_none()

                if existing_project:
                    logger.warning(f"Cannot rename project to '{sanitize_for_log(name)}' - name already exists")
                    raise ValueError(f"A project with the name '{name}' already exists")

            # Update project fields
            if name is not None:
                project.name = name
            if description is not None:
                project.description = description
            if status is not None:
                project.status = status

            # Handle portfolio_id update (can be set to None for standalone)
            if 'portfolio_id' in kwargs:
                # If setting to a portfolio, verify it exists
                if portfolio_id is not None:
                    from models.portfolio import Portfolio
                    portfolio_stmt = select(Portfolio).where(
                        Portfolio.id == portfolio_id,
                        Portfolio.organization_id == organization_id
                    )
                    portfolio_result = await session.execute(portfolio_stmt)
                    portfolio = portfolio_result.scalar_one_or_none()
                    if not portfolio:
                        raise ValueError(f"Portfolio {portfolio_id} not found")

                project.portfolio_id = portfolio_id

            # Handle program_id update (can be set to None for standalone or direct portfolio)
            if 'program_id' in kwargs:
                # If setting to a program, verify it exists
                if program_id is not None:
                    from models.program import Program
                    program_stmt = select(Program).where(
                        Program.id == program_id,
                        Program.organization_id == organization_id
                    )
                    program_result = await session.execute(program_stmt)
                    program = program_result.scalar_one_or_none()
                    if not program:
                        raise ValueError(f"Program {program_id} not found")

                project.program_id = program_id

            project.updated_at = datetime.utcnow()

            # Update members if provided
            if members is not None:
                # Remove existing members
                await session.execute(
                    delete(ProjectMember).where(ProjectMember.project_id == project_id)
                )
                
                # Add new members
                for member_data in members:
                    member = ProjectMember(
                        project_id=project_id,
                        name=member_data.get("name"),
                        email=member_data.get("email"),
                        role=member_data.get("role", "member")
                    )
                    session.add(member)
            
            await session.flush()
            await session.refresh(project, ["members"])
            
            # Log activity for project update
            changes = []
            if name is not None:
                changes.append("name")
            if description is not None:
                changes.append("description")
            if status is not None:
                changes.append("status")
            if members is not None:
                changes.append("members")
            
            if changes:
                await ActivityService.log_project_updated(
                    db=session,
                    project_id=project_id,
                    project_name=project.name,
                    changes=", ".join(changes),
                    updated_by="system"  # TODO: Get actual user from context
                )
            
            logger.info(f"Updated project: {project_id}")
            return project
            
        except Exception as e:
            logger.error(f"Failed to update project {project_id}: {e}")
            raise
    
    @staticmethod
    async def archive_project(session: AsyncSession, project_id: UUID, organization_id: UUID) -> bool:
        """Archive a project by setting its status to archived."""
        try:
            stmt = update(Project).where(
                Project.id == project_id,
                Project.organization_id == organization_id
            ).values(
                status=ProjectStatus.ARCHIVED,
                updated_at=datetime.utcnow()
            )
            
            result = await session.execute(stmt)
            
            if result.rowcount > 0:
                # Get project name for activity log
                project = await ProjectService.get_project(session, project_id)
                if project:
                    await ActivityService.log_project_deleted(
                        db=session,
                        project_id=project_id,
                        project_name=project.name,
                        deleted_by="system"  # TODO: Get actual user from context
                    )
                
                logger.info(f"Archived project: {project_id}")
                return True
            else:
                logger.warning(f"Project not found for archiving: {project_id}")
                return False
                
        except Exception as e:
            logger.error(f"Failed to archive project {project_id}: {e}")
            raise
    
    @staticmethod
    async def restore_project(session: AsyncSession, project_id: UUID, organization_id: UUID) -> bool:
        """Restore an archived project by setting its status to active."""
        try:
            # First get the project to restore
            project = await ProjectService.get_project(session, project_id, organization_id)
            if not project:
                logger.warning(f"Project not found for restoration: {project_id}")
                return False

            # Check if project is already active
            if project.status == ProjectStatus.ACTIVE:
                logger.warning(f"Project {project_id} is already active")
                return False

            # Check if another active project with the same name exists in the same organization
            existing_stmt = select(Project).where(
                Project.name == project.name,
                Project.organization_id == organization_id,
                Project.status == ProjectStatus.ACTIVE,
                Project.id != project_id
            )
            existing_result = await session.execute(existing_stmt)
            existing_project = existing_result.scalar_one_or_none()
            
            if existing_project:
                logger.warning(f"Cannot restore project: Active project with name '{project.name}' already exists")
                raise ValueError(f"An active project with the name '{project.name}' already exists. Please rename or archive the existing project first.")
            
            # Proceed with restoration
            stmt = update(Project).where(
                Project.id == project_id
            ).values(
                status=ProjectStatus.ACTIVE,
                updated_at=datetime.utcnow()
            )
            
            result = await session.execute(stmt)
            
            if result.rowcount > 0:
                # Log activity
                await ActivityService.log_project_updated(
                    db=session,
                    project_id=project_id,
                    project_name=project.name,
                    changes="Status changed from archived to active",
                    updated_by="system"
                )
                
                logger.info(f"Restored project: {project.name} ({project_id})")
                return True
            else:
                logger.warning(f"Failed to update project status for: {project_id}")
                return False
                
        except ValueError:
            # Re-raise ValueError for duplicate name
            raise
        except Exception as e:
            logger.error(f"Failed to restore project {project_id}: {e}")
            raise
    
    @staticmethod
    async def delete_project(session: AsyncSession, project_id: UUID, organization_id: UUID) -> bool:
        """Permanently delete a project and all related data."""
        try:
            # First check if project exists and belongs to the organization
            stmt = select(Project).where(
                Project.id == project_id,
                Project.organization_id == organization_id
            )
            result = await session.execute(stmt)
            project = result.scalar_one_or_none()

            if not project:
                logger.warning(f"Project not found for deletion or not in organization: {project_id}")
                return False

            project_name = project.name

            # Delete the project - all related data will be cascade deleted
            # due to ondelete="CASCADE" on foreign keys and cascade="all, delete-orphan" on relationships
            await session.execute(
                delete(Project).where(
                    Project.id == project_id,
                    Project.organization_id == organization_id
                )
            )

            # Note: We can't log activity after deletion since the project is gone
            # Could consider logging to a separate audit table if needed

            logger.info(f"Permanently deleted project and all related data: {project_name} ({project_id})")
            return True

        except Exception as e:
            logger.error(f"Failed to permanently delete project {project_id}: {e}")
            raise
    
    @staticmethod
    async def add_member(
        session: AsyncSession,
        project_id: UUID,
        organization_id: UUID,
        name: str,
        email: str,
        role: str = "member"
    ) -> Optional[ProjectMember]:
        """Add a member to a project."""
        try:
            # Check if project exists and belongs to organization
            project = await ProjectService.get_project(session, project_id, organization_id)
            if not project:
                return None
            
            # Check if member already exists
            stmt = select(ProjectMember).where(
                ProjectMember.project_id == project_id,
                ProjectMember.email == email
            )
            existing = await session.execute(stmt)
            if existing.scalar_one_or_none():
                logger.warning(f"Member {sanitize_for_log(email)} already exists in project {sanitize_for_log(project_id)}")
                return None
            
            # Add new member
            member = ProjectMember(
                project_id=project_id,
                name=name,
                email=email,
                role=role
            )
            session.add(member)
            await session.flush()
            
            logger.info(f"Added member {sanitize_for_log(email)} to project {sanitize_for_log(project_id)}")
            return member
            
        except Exception as e:
            logger.error(f"Failed to add member to project {project_id}: {e}")
            raise
    
    @staticmethod
    async def remove_member(
        session: AsyncSession,
        project_id: UUID,
        organization_id: UUID,
        member_email: str
    ) -> bool:
        """Remove a member from a project."""
        try:
            # First verify project belongs to organization
            project = await ProjectService.get_project(session, project_id, organization_id)
            if not project:
                return False

            stmt = delete(ProjectMember).where(
                ProjectMember.project_id == project_id,
                ProjectMember.email == member_email
            )
            
            result = await session.execute(stmt)
            
            if result.rowcount > 0:
                logger.info(f"Removed member {sanitize_for_log(member_email)} from project {project_id}")
                return True
            else:
                logger.warning(f"Member {sanitize_for_log(member_email)} not found in project {project_id}")
                return False
                
        except Exception as e:
            logger.error(f"Failed to remove member from project {project_id}: {e}")
            raise

    @staticmethod
    async def update_project_description(
        session: AsyncSession,
        project_id: UUID,
        new_description: str,
        content_id: Optional[UUID] = None,
        reason: Optional[str] = None,
        confidence_score: Optional[float] = None,
        changed_by: str = "system"
    ) -> bool:
        """Update project description."""
        try:
            # Get the project
            project = await ProjectService.get_project(session, project_id)
            if not project:
                logger.error(f"Project {project_id} not found for description update")
                return False

            # Update project description
            project.description = new_description
            project.updated_at = datetime.utcnow()

            # Log activity
            await ActivityService.log_project_updated(
                db=session,
                project_id=project_id,
                project_name=project.name,
                changes="Description updated automatically based on new content",
                updated_by=changed_by
            )

            logger.info(f"Updated description for project {project.name}")
            return True

        except Exception as e:
            logger.error(f"Failed to update project description: {e}")
            raise

    @staticmethod
    async def get_description_change_history(
        session: AsyncSession,
        project_id: UUID,
        limit: int = 10
    ) -> List[Any]:
        """
        Get the history of description changes for a project.
        For now, returns an empty list since we don't track description change history.
        In the future, this could query a description_changes table.
        """
        # For now, return empty list - no description change tracking implemented
        # This prevents the error while allowing the description update to proceed
        return []