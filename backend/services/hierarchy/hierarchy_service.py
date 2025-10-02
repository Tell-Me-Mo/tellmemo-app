"""Hierarchy service for managing portfolio/program/project relationships."""

from typing import List, Optional, Dict, Any, Tuple
from uuid import UUID
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, and_, or_, update
from sqlalchemy.orm import selectinload

from models.portfolio import Portfolio
from models.program import Program
from models.project import Project, ProjectStatus
from services.hierarchy.portfolio_service import PortfolioService
from services.hierarchy.program_service import ProgramService
from services.hierarchy.project_service import ProjectService
from utils.logger import get_logger
from utils.monitoring import monitor_operation, monitor_sync_operation, MonitoringContext

logger = get_logger(__name__)


class HierarchyService:
    """Service for managing the hierarchical organization of portfolios, programs, and projects."""
    
    @staticmethod
    @monitor_operation("get_full_hierarchy", "database", capture_args=True, capture_result=True)
    async def get_full_hierarchy(
        session: AsyncSession,
        include_archived: bool = False
    ) -> List[Dict[str, Any]]:
        """Get the complete organizational hierarchy.
        
        Args:
            session: Database session
            include_archived: Whether to include archived projects
            
        Returns:
            List of portfolio dictionaries with nested programs and projects
        """
        # Build status filter
        status_filter = [] if include_archived else [ProjectStatus.ACTIVE]
        
        # Get all portfolios with related data
        portfolios_result = await session.execute(
            select(Portfolio)
            .options(
                selectinload(Portfolio.programs).selectinload(Program.projects),
                selectinload(Portfolio.projects)
            )
            .order_by(Portfolio.name)
        )
        portfolios = portfolios_result.scalars().all()
        
        # Get orphaned programs (no portfolio) - these shouldn't exist but handle gracefully
        orphaned_programs_result = await session.execute(
            select(Program)
            .options(selectinload(Program.projects))
            .where(Program.portfolio_id.is_(None))
            .order_by(Program.name)
        )
        orphaned_programs = orphaned_programs_result.scalars().all()
        
        # Get orphaned projects (no portfolio or program)
        orphaned_projects_result = await session.execute(
            select(Project)
            .where(
                and_(
                    Project.portfolio_id.is_(None),
                    Project.program_id.is_(None)
                )
            )
            .order_by(Project.name)
        )
        orphaned_projects = orphaned_projects_result.scalars().all()
        
        # Build hierarchy structure
        hierarchy = []
        
        # Process portfolios
        for portfolio in portfolios:
            portfolio_data = {
                'id': str(portfolio.id),
                'name': portfolio.name,
                'description': portfolio.description,
                'type': 'portfolio',
                'created_at': portfolio.created_at.isoformat(),
                'updated_at': portfolio.updated_at.isoformat(),
                'programs': [],
                'direct_projects': []
            }
            
            # Add programs under this portfolio
            for program in portfolio.programs:
                program_projects = [
                    HierarchyService._format_project(p) 
                    for p in program.projects
                    if not status_filter or p.status in status_filter
                ]
                
                program_data = {
                    'id': str(program.id),
                    'name': program.name,
                    'description': program.description,
                    'type': 'program',
                    'portfolio_id': str(program.portfolio_id),
                    'created_at': program.created_at.isoformat(),
                    'updated_at': program.updated_at.isoformat(),
                    'projects': program_projects
                }
                portfolio_data['programs'].append(program_data)
            
            # Add direct projects under this portfolio (not under any program)
            direct_projects = [
                p for p in portfolio.projects 
                if p.program_id is None and (not status_filter or p.status in status_filter)
            ]
            
            portfolio_data['direct_projects'] = [
                HierarchyService._format_project(p) for p in direct_projects
            ]
            
            hierarchy.append(portfolio_data)
        
        # Add orphaned items if they exist
        if orphaned_programs or orphaned_projects:
            orphaned_section = {
                'id': 'orphaned',
                'name': 'Unassigned Items',
                'description': 'Items not assigned to any portfolio',
                'type': 'virtual',
                'created_at': None,
                'updated_at': None,
                'programs': [],
                'direct_projects': []
            }
            
            # Add orphaned programs
            for program in orphaned_programs:
                program_projects = [
                    HierarchyService._format_project(p) 
                    for p in program.projects
                    if not status_filter or p.status in status_filter
                ]
                
                program_data = {
                    'id': str(program.id),
                    'name': program.name,
                    'description': program.description,
                    'type': 'program',
                    'portfolio_id': None,
                    'created_at': program.created_at.isoformat(),
                    'updated_at': program.updated_at.isoformat(),
                    'projects': program_projects
                }
                orphaned_section['programs'].append(program_data)
            
            # Add orphaned projects
            orphaned_section['direct_projects'] = [
                HierarchyService._format_project(p) 
                for p in orphaned_projects
                if not status_filter or p.status in status_filter
            ]
            
            if orphaned_section['programs'] or orphaned_section['direct_projects']:
                hierarchy.append(orphaned_section)
        
        return hierarchy
    
    @staticmethod
    def _format_project(project: Project) -> Dict[str, Any]:
        """Format project for hierarchy response."""
        return {
            'id': str(project.id),
            'name': project.name,
            'description': project.description,
            'type': 'project',
            'status': project.status.value,
            'portfolio_id': str(project.portfolio_id) if project.portfolio_id else None,
            'program_id': str(project.program_id) if project.program_id else None,
            'created_at': project.created_at.isoformat(),
            'updated_at': project.updated_at.isoformat(),
            'member_count': len(project.members) if project.members else 0
        }
    
    @staticmethod
    @monitor_operation("move_hierarchy_item", "database", capture_args=True, capture_result=True)
    async def move_item(
        session: AsyncSession,
        item_id: UUID,
        item_type: str,
        target_parent_id: Optional[UUID] = None,
        target_parent_type: Optional[str] = None
    ) -> Dict[str, Any]:
        """Move an item within the hierarchy.
        
        Args:
            session: Database session
            item_id: ID of item to move
            item_type: Type of item ('project', 'program')
            target_parent_id: ID of target parent (portfolio/program)
            target_parent_type: Type of target parent ('portfolio', 'program')
            
        Returns:
            Dictionary with move result and updated hierarchy path
            
        Raises:
            ValueError: If move is invalid
        """
        if item_type == 'project':
            return await HierarchyService._move_project(
                session, item_id, target_parent_id, target_parent_type
            )
        elif item_type == 'program':
            return await HierarchyService._move_program(
                session, item_id, target_parent_id, target_parent_type
            )
        else:
            raise ValueError(f"Invalid item type: {item_type}")
    
    @staticmethod
    @monitor_operation("move_project", "database", capture_args=True, capture_result=False)
    async def _move_project(
        session: AsyncSession,
        project_id: UUID,
        target_parent_id: Optional[UUID],
        target_parent_type: Optional[str]
    ) -> Dict[str, Any]:
        """Move a project within the hierarchy."""
        # Get the project
        project_result = await session.execute(
            select(Project).where(Project.id == project_id)
        )
        project = project_result.scalars().first()
        if not project:
            raise ValueError(f"Project with ID '{project_id}' not found")
        
        old_portfolio_id = project.portfolio_id
        old_program_id = project.program_id
        
        if target_parent_type == 'portfolio':
            # Moving to direct portfolio (no program)
            if target_parent_id:
                # Verify portfolio exists
                portfolio_result = await session.execute(
                    select(Portfolio).where(Portfolio.id == target_parent_id)
                )
                if not portfolio_result.scalars().first():
                    raise ValueError(f"Portfolio with ID '{target_parent_id}' not found")
                
                project.portfolio_id = target_parent_id
                project.program_id = None
            else:
                # Moving to orphaned (no portfolio, no program)
                project.portfolio_id = None
                project.program_id = None
                
        elif target_parent_type == 'program':
            # Moving to program
            if not target_parent_id:
                raise ValueError("Program ID required when moving to program")
            
            # Get program and verify it exists
            program_result = await session.execute(
                select(Program).where(Program.id == target_parent_id)
            )
            program = program_result.scalars().first()
            if not program:
                raise ValueError(f"Program with ID '{target_parent_id}' not found")
            
            project.program_id = target_parent_id
            project.portfolio_id = program.portfolio_id  # Inherit portfolio from program
            
        else:
            # Moving to orphaned
            project.portfolio_id = None
            project.program_id = None
        
        # Store values before commit
        project_name = project.name
        new_portfolio_id = project.portfolio_id
        new_program_id = project.program_id
        
        # Format project before commit - but avoid accessing lazy-loaded relationships
        formatted_project = {
            'id': str(project.id),
            'name': project.name,
            'description': project.description,
            'type': 'project',
            'status': project.status.value,
            'portfolio_id': str(project.portfolio_id) if project.portfolio_id else None,
            'program_id': str(project.program_id) if project.program_id else None,
            'created_at': project.created_at.isoformat(),
            'updated_at': project.updated_at.isoformat()
        }
        
        await session.commit()
        
        logger.info(f"Moved project {project_name} from portfolio={old_portfolio_id}, program={old_program_id} to portfolio={new_portfolio_id}, program={new_program_id}")
        
        return {
            'success': True,
            'message': f'Project "{project_name}" moved successfully',
            'item': formatted_project
        }
    
    @staticmethod
    @monitor_operation("move_program", "database", capture_args=True, capture_result=False)
    async def _move_program(
        session: AsyncSession,
        program_id: UUID,
        target_parent_id: Optional[UUID],
        target_parent_type: Optional[str]
    ) -> Dict[str, Any]:
        """Move a program within the hierarchy."""
        # Programs can only be moved between portfolios
        if target_parent_type != 'portfolio':
            raise ValueError("Programs can only be moved to portfolios")
        
        # Get the program
        program_result = await session.execute(
            select(Program).where(Program.id == program_id)
        )
        program = program_result.scalars().first()
        if not program:
            raise ValueError(f"Program with ID '{program_id}' not found")
        
        if not target_parent_id:
            raise ValueError("Portfolio ID required when moving program")
        
        # Verify target portfolio exists
        portfolio_result = await session.execute(
            select(Portfolio).where(Portfolio.id == target_parent_id)
        )
        if not portfolio_result.scalars().first():
            raise ValueError(f"Portfolio with ID '{target_parent_id}' not found")
        
        # Check for name conflicts in target portfolio
        existing_result = await session.execute(
            select(Program).where(
                and_(
                    Program.name == program.name,
                    Program.portfolio_id == target_parent_id,
                    Program.id != program_id
                )
            )
        )
        if existing_result.scalars().first():
            raise ValueError(f"Program with name '{program.name}' already exists in target portfolio")
        
        old_portfolio_id = program.portfolio_id
        program.portfolio_id = target_parent_id
        
        # Store values before commit
        program_name = program.name
        program_desc = program.description
        program_created = program.created_at.isoformat()
        program_updated = program.updated_at.isoformat()
        
        # Update all projects under this program to inherit the new portfolio
        await session.execute(
            update(Project)
            .where(Project.program_id == program_id)
            .values(portfolio_id=target_parent_id)
        )
        
        await session.commit()
        
        logger.info(f"Moved program {program_name} from portfolio {old_portfolio_id} to portfolio {target_parent_id}")
        
        return {
            'success': True,
            'message': f'Program "{program_name}" moved successfully',
            'item': {
                'id': str(program_id),
                'name': program_name,
                'description': program_desc,
                'type': 'program',
                'portfolio_id': str(target_parent_id),
                'created_at': program_created,
                'updated_at': program_updated
            }
        }
    
    @staticmethod
    @monitor_operation("bulk_move_items", "database", capture_args=True, capture_result=True)
    async def bulk_move_items(
        session: AsyncSession,
        items: List[Dict[str, Any]],
        target_parent_id: Optional[UUID] = None,
        target_parent_type: Optional[str] = None
    ) -> Dict[str, Any]:
        """Move multiple items in bulk.
        
        Args:
            session: Database session
            items: List of items to move with 'id' and 'type' keys
            target_parent_id: Target parent ID
            target_parent_type: Target parent type
            
        Returns:
            Dictionary with bulk move results
        """
        results = {
            'success_count': 0,
            'error_count': 0,
            'errors': [],
            'moved_items': []
        }
        
        for item in items:
            try:
                result = await HierarchyService.move_item(
                    session, 
                    UUID(item['id']), 
                    item['type'],
                    target_parent_id,
                    target_parent_type
                )
                results['success_count'] += 1
                results['moved_items'].append(result['item'])
                
            except Exception as e:
                results['error_count'] += 1
                results['errors'].append({
                    'item_id': item['id'],
                    'item_type': item['type'],
                    'error': str(e)
                })
                logger.error(f"Failed to move item {item['id']} ({item['type']}): {e}")
        
        return results
    
    @staticmethod
    @monitor_operation("get_hierarchy_path", "database", capture_args=True, capture_result=True)
    async def get_hierarchy_path(
        session: AsyncSession,
        item_id: UUID,
        item_type: str
    ) -> List[Dict[str, Any]]:
        """Get the full hierarchy path for an item.
        
        Args:
            session: Database session
            item_id: Item ID
            item_type: Item type
            
        Returns:
            List of hierarchy path items from root to target
        """
        path = []
        
        if item_type == 'project':
            project_result = await session.execute(
                select(Project)
                .options(
                    selectinload(Project.portfolio),
                    selectinload(Project.program).selectinload(Program.portfolio)
                )
                .where(Project.id == item_id)
            )
            project = project_result.scalars().first()
            if not project:
                return path
            
            # Add portfolio to path if exists
            portfolio = project.program.portfolio if project.program else project.portfolio
            if portfolio:
                path.append({
                    'id': str(portfolio.id),
                    'name': portfolio.name,
                    'type': 'portfolio'
                })
            
            # Add program to path if exists
            if project.program:
                path.append({
                    'id': str(project.program.id),
                    'name': project.program.name,
                    'type': 'program'
                })
            
            # Add project
            path.append({
                'id': str(project.id),
                'name': project.name,
                'type': 'project'
            })
            
        elif item_type == 'program':
            program_result = await session.execute(
                select(Program)
                .options(selectinload(Program.portfolio))
                .where(Program.id == item_id)
            )
            program = program_result.scalars().first()
            if not program:
                return path
            
            # Add portfolio to path if exists
            if program.portfolio:
                path.append({
                    'id': str(program.portfolio.id),
                    'name': program.portfolio.name,
                    'type': 'portfolio'
                })
            
            # Add program
            path.append({
                'id': str(program.id),
                'name': program.name,
                'type': 'program'
            })
            
        elif item_type == 'portfolio':
            portfolio_result = await session.execute(
                select(Portfolio).where(Portfolio.id == item_id)
            )
            portfolio = portfolio_result.scalars().first()
            if portfolio:
                path.append({
                    'id': str(portfolio.id),
                    'name': portfolio.name,
                    'type': 'portfolio'
                })
        
        return path