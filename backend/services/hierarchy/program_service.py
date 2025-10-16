"""Program service for managing program operations."""

from typing import List, Optional
from uuid import UUID
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, delete, and_
from sqlalchemy.orm import selectinload

from models.portfolio import Portfolio
from models.program import Program
from models.project import Project
from utils.logger import get_logger

logger = get_logger(__name__)


class ProgramService:
    """Service class for program operations."""

    @staticmethod
    async def create_program(
        session: AsyncSession,
        name: str,
        portfolio_id: UUID,
        description: Optional[str] = None,
        created_by: str = "system"
    ) -> Program:
        """Create a new program.
        
        Args:
            session: Database session
            name: Program name
            portfolio_id: Parent portfolio ID
            description: Program description
            created_by: User creating the program
            
        Returns:
            Created program instance
            
        Raises:
            ValueError: If portfolio doesn't exist or program name conflicts within portfolio
        """
        # Verify portfolio exists
        portfolio_result = await session.execute(
            select(Portfolio).where(Portfolio.id == portfolio_id)
        )
        if not portfolio_result.scalars().first():
            raise ValueError(f"Portfolio with ID '{portfolio_id}' not found")
        
        # Check if program name already exists within the portfolio
        existing = await session.execute(
            select(Program).where(
                and_(
                    Program.name == name,
                    Program.portfolio_id == portfolio_id
                )
            )
        )
        if existing.scalars().first():
            raise ValueError(f"Program with name '{name}' already exists in this portfolio")
        
        program = Program(
            name=name,
            portfolio_id=portfolio_id,
            description=description,
            created_by=created_by
        )
        
        session.add(program)
        await session.commit()
        await session.refresh(program)
        
        logger.info(f"Created program: {program.name} (ID: {program.id}) in portfolio {portfolio_id}")
        return program

    @staticmethod
    async def get_program(
        session: AsyncSession,
        program_id: UUID
    ) -> Optional[Program]:
        """Get program by ID with related data.
        
        Args:
            session: Database session
            program_id: Program UUID
            
        Returns:
            Program instance or None if not found
        """
        result = await session.execute(
            select(Program)
            .options(
                selectinload(Program.portfolio),
                selectinload(Program.projects)
            )
            .where(Program.id == program_id)
        )
        return result.scalars().first()

    @staticmethod
    async def list_programs(
        session: AsyncSession,
        portfolio_id: Optional[UUID] = None
    ) -> List[Program]:
        """List programs, optionally filtered by portfolio.
        
        Args:
            session: Database session
            portfolio_id: Optional portfolio filter
            
        Returns:
            List of program instances
        """
        query = select(Program).options(
            selectinload(Program.portfolio),
            selectinload(Program.projects)
        ).order_by(Program.name)
        
        if portfolio_id:
            query = query.where(Program.portfolio_id == portfolio_id)
        
        result = await session.execute(query)
        programs = result.scalars().all()
        
        return list(programs)

    @staticmethod
    async def update_program(
        session: AsyncSession,
        program_id: UUID,
        name: Optional[str] = None,
        description: Optional[str] = None,
        portfolio_id: Optional[UUID] = None
    ) -> Optional[Program]:
        """Update program details.
        
        Args:
            session: Database session
            program_id: Program UUID
            name: New program name
            description: New program description
            portfolio_id: New parent portfolio ID
            
        Returns:
            Updated program instance or None if not found
            
        Raises:
            ValueError: If new name conflicts or portfolio doesn't exist
        """
        result = await session.execute(
            select(Program).where(Program.id == program_id)
        )
        program = result.scalars().first()
        
        if not program:
            return None
        
        # If moving to new portfolio, verify it exists
        target_portfolio_id = portfolio_id if portfolio_id else program.portfolio_id
        if portfolio_id and portfolio_id != program.portfolio_id:
            portfolio_result = await session.execute(
                select(Portfolio).where(Portfolio.id == portfolio_id)
            )
            if not portfolio_result.scalars().first():
                raise ValueError(f"Portfolio with ID '{portfolio_id}' not found")
        
        # Check for name conflicts if updating name
        if name and name != program.name:
            existing = await session.execute(
                select(Program).where(
                    and_(
                        Program.name == name,
                        Program.portfolio_id == target_portfolio_id,
                        Program.id != program_id
                    )
                )
            )
            if existing.scalars().first():
                raise ValueError(f"Program with name '{name}' already exists in the target portfolio")
            program.name = name
        
        if description is not None:
            program.description = description
            
        if portfolio_id:
            program.portfolio_id = portfolio_id
        
        await session.commit()
        await session.refresh(program)
        
        logger.info(f"Updated program: {program.name} (ID: {program.id})")
        return program

    @staticmethod
    async def delete_program(
        session: AsyncSession,
        program_id: UUID,
        reassign_to_program_id: Optional[UUID] = None
    ) -> bool:
        """Delete a program and handle related projects.
        
        Args:
            session: Database session
            program_id: Program UUID to delete
            reassign_to_program_id: Optional program to reassign projects to
            
        Returns:
            True if deleted, False if not found
        """
        result = await session.execute(
            select(Program).where(Program.id == program_id)
        )
        program = result.scalars().first()
        
        if not program:
            return False
        
        # Handle reassignment of projects if specified
        if reassign_to_program_id:
            await session.execute(
                select(Project)
                .where(Project.program_id == program_id)
                .update({Project.program_id: reassign_to_program_id})
            )
        else:
            # Set projects to direct portfolio projects (no program)
            await session.execute(
                select(Project)
                .where(Project.program_id == program_id)
                .update({Project.program_id: None})
            )
        
        await session.delete(program)
        await session.commit()
        
        logger.info(f"Deleted program: {program.name} (ID: {program.id})")
        return True

    @staticmethod
    async def move_projects_to_program(
        session: AsyncSession,
        program_id: UUID,
        project_ids: List[UUID]
    ) -> int:
        """Move projects to a program.
        
        Args:
            session: Database session
            program_id: Target program ID
            project_ids: List of project IDs to move
            
        Returns:
            Number of projects successfully moved
            
        Raises:
            ValueError: If program doesn't exist
        """
        # Verify program exists and get its portfolio
        result = await session.execute(
            select(Program).where(Program.id == program_id)
        )
        program = result.scalars().first()
        if not program:
            raise ValueError(f"Program with ID '{program_id}' not found")
        
        moved_count = 0
        for project_id in project_ids:
            project_result = await session.execute(
                select(Project).where(Project.id == project_id)
            )
            project = project_result.scalars().first()
            
            if project:
                # Update project to be under this program and its portfolio
                project.program_id = program_id
                project.portfolio_id = program.portfolio_id
                moved_count += 1
        
        await session.commit()
        
        logger.info(f"Moved {moved_count} projects to program {program.name}")
        return moved_count

    @staticmethod
    async def get_program_statistics(
        session: AsyncSession,
        program_id: UUID
    ) -> Optional[dict]:
        """Get program statistics including project counts and status breakdown.
        
        Args:
            session: Database session
            program_id: Program UUID
            
        Returns:
            Dictionary with program statistics or None if not found
        """
        program = await ProgramService.get_program(session, program_id)
        if not program:
            return None
        
        # Count projects
        total_projects = len(program.projects)
        
        # Project status breakdown
        active_projects = len([p for p in program.projects if p.status.value == 'active'])
        archived_projects = len([p for p in program.projects if p.status.value == 'archived'])
        
        return {
            'program_id': str(program_id),
            'program_name': program.name,
            'portfolio_id': str(program.portfolio_id),
            'portfolio_name': program.portfolio.name if program.portfolio else None,
            'total_project_count': total_projects,
            'active_projects': active_projects,
            'archived_projects': archived_projects,
            'created_at': program.created_at,
            'updated_at': program.updated_at
        }