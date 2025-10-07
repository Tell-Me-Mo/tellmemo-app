from fastapi import APIRouter, HTTPException, Depends, Query
from pydantic import BaseModel
from typing import List, Optional, Dict, Any
from uuid import UUID
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_

from db.database import db_manager, get_db
from dependencies.auth import get_current_organization, get_current_user, require_role
from models.organization import Organization
from models.user import User
from services.hierarchy.hierarchy_service import HierarchyService
from utils.logger import get_logger

router = APIRouter(prefix="/api/v1/hierarchy", tags=["hierarchy"])
logger = get_logger(__name__)


class MoveItemRequest(BaseModel):
    item_id: str
    item_type: str  # 'project' or 'program'
    target_parent_id: Optional[str] = None
    target_parent_type: Optional[str] = None  # 'portfolio' or 'program'


class BulkMoveRequest(BaseModel):
    items: List[Dict[str, str]]  # List of {'id': str, 'type': str}
    target_parent_id: Optional[str] = None
    target_parent_type: Optional[str] = None


class HierarchyPathRequest(BaseModel):
    item_id: str
    item_type: str

class BulkDeleteRequest(BaseModel):
    items: List[Dict[str, str]]  # List of {'id': str, 'type': str}
    delete_children: bool = True
    reassign_to_id: Optional[str] = None
    reassign_to_type: Optional[str] = None


@router.get("/full")
async def get_full_hierarchy(
    include_archived: bool = False,
    session: AsyncSession = Depends(get_db),
    current_org: Organization = Depends(get_current_organization),
    current_user: User = Depends(get_current_user),
    _: str = Depends(require_role("member"))
):
    """Get the complete organizational hierarchy."""
    try:
        from models.portfolio import Portfolio
        from models.program import Program
        from models.project import Project, ProjectStatus
        
        # Get all portfolios for current organization
        portfolios_result = await session.execute(
            select(Portfolio).where(
                Portfolio.organization_id == current_org.id
            ).order_by(Portfolio.name)
        )
        portfolios = portfolios_result.scalars().all()
        
        # Get all programs for current organization
        programs_result = await session.execute(
            select(Program).where(
                Program.organization_id == current_org.id
            ).order_by(Program.name)
        )
        programs = programs_result.scalars().all()
        
        # Get all projects for current organization
        project_query = select(Project).where(Project.organization_id == current_org.id)
        if not include_archived:
            project_query = project_query.where(Project.status != ProjectStatus.ARCHIVED)
        projects_result = await session.execute(project_query.order_by(Project.name))
        projects = projects_result.scalars().all()
        
        # Build hierarchy
        hierarchy = []
        
        # Process portfolios
        for portfolio in portfolios:
            portfolio_programs = [p for p in programs if p.portfolio_id == portfolio.id]
            portfolio_projects = [p for p in projects if p.portfolio_id == portfolio.id and p.program_id is None]
            
            portfolio_data = {
                'id': str(portfolio.id),
                'name': portfolio.name,
                'description': portfolio.description,
                'type': 'portfolio',
                'children': []
            }
            
            # Add programs
            for program in portfolio_programs:
                program_projects = [p for p in projects if p.program_id == program.id]
                program_data = {
                    'id': str(program.id),
                    'name': program.name,
                    'description': program.description,
                    'type': 'program',
                    'portfolio_id': str(portfolio.id),
                    'children': [
                        {
                            'id': str(p.id),
                            'name': p.name,
                            'description': p.description,
                            'type': 'project',
                            'portfolio_id': str(p.portfolio_id) if p.portfolio_id else None,
                            'program_id': str(p.program_id) if p.program_id else None,
                            'status': p.status.value,
                            'children': []
                        } for p in program_projects
                    ]
                }
                portfolio_data['children'].append(program_data)
            
            # Add direct projects
            for project in portfolio_projects:
                portfolio_data['children'].append({
                    'id': str(project.id),
                    'name': project.name,
                    'description': project.description,
                    'type': 'project',
                    'portfolio_id': str(project.portfolio_id),
                    'program_id': None,
                    'status': project.status.value,
                    'children': []
                })
            
            hierarchy.append(portfolio_data)
        
        # Add orphaned programs
        orphaned_programs = [p for p in programs if p.portfolio_id is None]
        for program in orphaned_programs:
            program_projects = [p for p in projects if p.program_id == program.id]
            hierarchy.append({
                'id': str(program.id),
                'name': program.name,
                'description': program.description,
                'type': 'program',
                'portfolio_id': None,
                'children': [
                    {
                        'id': str(p.id),
                        'name': p.name,
                        'description': p.description,
                        'type': 'project',
                        'portfolio_id': str(p.portfolio_id) if p.portfolio_id else None,
                        'program_id': str(p.program_id),
                        'status': p.status.value,
                        'children': []
                    } for p in program_projects
                ]
            })
        
        # Add orphaned projects
        orphaned_projects = [p for p in projects if p.portfolio_id is None and p.program_id is None]
        for project in orphaned_projects:
            hierarchy.append({
                'id': str(project.id),
                'name': project.name,
                'description': project.description,
                'type': 'project',
                'portfolio_id': None,
                'program_id': None,
                'status': project.status.value,
                'children': []
            })
        
        return {
            'hierarchy': hierarchy,
            'include_archived': include_archived
        }
        
    except Exception as e:
        logger.error(f"Failed to get full hierarchy: {e}")
        raise HTTPException(status_code=500, detail="Failed to get hierarchy")


@router.post("/move")
async def move_item(
    request: MoveItemRequest,
    session: AsyncSession = Depends(get_db),
    current_org: Organization = Depends(get_current_organization),
    current_user: User = Depends(get_current_user),
    _: str = Depends(require_role("member"))
):
    """Move an item within the hierarchy."""
    try:
        # Convert string IDs to UUIDs
        try:
            item_uuid = UUID(request.item_id)
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid item ID format")
        
        target_uuid = None
        if request.target_parent_id:
            try:
                target_uuid = UUID(request.target_parent_id)
            except ValueError:
                raise HTTPException(status_code=400, detail="Invalid target parent ID format")
        
        # Validate item type
        if request.item_type not in ['project', 'program']:
            raise HTTPException(status_code=400, detail="Invalid item type. Must be 'project' or 'program'")
        
        # Validate target parent type if provided
        if request.target_parent_type and request.target_parent_type not in ['portfolio', 'program']:
            raise HTTPException(status_code=400, detail="Invalid target parent type. Must be 'portfolio' or 'program'")
        
        result = await HierarchyService.move_item(
            session=session,
            item_id=item_uuid,
            item_type=request.item_type,
            target_parent_id=target_uuid,
            target_parent_type=request.target_parent_type,
            organization_id=current_org.id
        )
        
        return result
        
    except HTTPException:
        raise
    except ValueError as e:
        logger.warning(f"Move item validation error: {e}")
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error(f"Failed to move item: {e}")
        raise HTTPException(status_code=500, detail="Failed to move item")


@router.post("/bulk-move")
async def bulk_move_items(
    request: BulkMoveRequest,
    session: AsyncSession = Depends(get_db),
    current_org: Organization = Depends(get_current_organization),
    current_user: User = Depends(get_current_user),
    _: str = Depends(require_role("member"))
):
    """Move multiple items in bulk."""
    try:
        # Validate items
        if not request.items:
            raise HTTPException(status_code=400, detail="No items provided")
        
        # Convert target parent ID to UUID
        target_uuid = None
        if request.target_parent_id:
            try:
                target_uuid = UUID(request.target_parent_id)
            except ValueError:
                raise HTTPException(status_code=400, detail="Invalid target parent ID format")
        
        # Validate items format and types
        for item in request.items:
            if 'id' not in item or 'type' not in item:
                raise HTTPException(status_code=400, detail="Each item must have 'id' and 'type' fields")
            
            if item['type'] not in ['project', 'program']:
                raise HTTPException(status_code=400, detail=f"Invalid item type: {item['type']}")
            
            # Validate UUID format
            try:
                UUID(item['id'])
            except ValueError:
                raise HTTPException(status_code=400, detail=f"Invalid item ID format: {item['id']}")
        
        # Validate target parent type if provided
        if request.target_parent_type and request.target_parent_type not in ['portfolio', 'program']:
            raise HTTPException(status_code=400, detail="Invalid target parent type")
        
        result = await HierarchyService.bulk_move_items(
            session=session,
            items=request.items,
            target_parent_id=target_uuid,
            target_parent_type=request.target_parent_type,
            organization_id=current_org.id
        )
        
        return {
            'message': f'Bulk move completed: {result["success_count"]} succeeded, {result["error_count"]} failed',
            'results': result
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to bulk move items: {e}")
        raise HTTPException(status_code=500, detail="Failed to bulk move items")


@router.post("/bulk-delete")
async def bulk_delete_items(
    request: BulkDeleteRequest,
    session: AsyncSession = Depends(get_db),
    current_org: Organization = Depends(get_current_organization),
    current_user: User = Depends(get_current_user),
    _: str = Depends(require_role("admin"))
):
    """Bulk delete items from the hierarchy."""
    try:
        if not request.items:
            raise HTTPException(status_code=400, detail="No items provided for deletion")
        
        deleted_count = 0
        reassigned_count = 0
        error_count = 0
        errors = []
        
        for item in request.items:
            try:
                item_uuid = UUID(item['id'])
                item_type = item['type']
                
                if item_type not in ['project', 'program', 'portfolio']:
                    errors.append({'id': item['id'], 'error': 'Invalid item type'})
                    error_count += 1
                    continue
                
                # Handle deletion based on item type
                if item_type == 'project':
                    from models.project import Project
                    project = await session.get(Project, item_uuid)
                    if project:
                        await session.delete(project)
                        deleted_count += 1
                
                elif item_type == 'program':
                    from models.program import Program
                    program = await session.get(Program, item_uuid)
                    if program:
                        if not request.delete_children and request.reassign_to_id:
                            # Reassign child projects
                            from models.project import Project
                            stmt = select(Project).where(Project.program_id == item_uuid)
                            result = await session.execute(stmt)
                            projects = result.scalars().all()
                            
                            for project in projects:
                                if request.reassign_to_type == 'program':
                                    project.program_id = UUID(request.reassign_to_id)
                                elif request.reassign_to_type == 'portfolio':
                                    project.portfolio_id = UUID(request.reassign_to_id)
                                    project.program_id = None
                                else:
                                    project.program_id = None
                                    project.portfolio_id = None
                                reassigned_count += 1
                        
                        await session.delete(program)
                        deleted_count += 1
                
                elif item_type == 'portfolio':
                    from models.portfolio import Portfolio
                    portfolio = await session.get(Portfolio, item_uuid)
                    if portfolio:
                        if not request.delete_children and request.reassign_to_id:
                            # Reassign child programs and projects
                            from models.program import Program
                            from models.project import Project
                            
                            # Reassign programs
                            stmt = select(Program).where(Program.portfolio_id == item_uuid)
                            result = await session.execute(stmt)
                            programs = result.scalars().all()
                            
                            for program in programs:
                                if request.reassign_to_type == 'portfolio':
                                    program.portfolio_id = UUID(request.reassign_to_id)
                                else:
                                    program.portfolio_id = None
                                reassigned_count += 1
                            
                            # Reassign projects
                            stmt = select(Project).where(Project.portfolio_id == item_uuid)
                            result = await session.execute(stmt)
                            projects = result.scalars().all()
                            
                            for project in projects:
                                if request.reassign_to_type == 'portfolio':
                                    project.portfolio_id = UUID(request.reassign_to_id)
                                else:
                                    project.portfolio_id = None
                                reassigned_count += 1
                        
                        await session.delete(portfolio)
                        deleted_count += 1
                
            except ValueError:
                errors.append({'id': item['id'], 'error': 'Invalid ID format'})
                error_count += 1
            except Exception as e:
                errors.append({'id': item['id'], 'error': str(e)})
                error_count += 1
        
        await session.commit()
        
        return {
            'message': f'Bulk delete completed: {deleted_count} deleted, {reassigned_count} reassigned, {error_count} failed',
            'results': {
                'deleted_count': deleted_count,
                'reassigned_count': reassigned_count,
                'error_count': error_count,
                'errors': errors
            }
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to bulk delete items: {e}")
        raise HTTPException(status_code=500, detail="Failed to bulk delete items")


@router.post("/path")
async def get_hierarchy_path(
    request: HierarchyPathRequest,
    session: AsyncSession = Depends(get_db),
    current_org: Organization = Depends(get_current_organization),
    current_user: User = Depends(get_current_user),
    _: str = Depends(require_role("member"))
):
    """Get the hierarchy path for an item."""
    try:
        # Convert string ID to UUID
        try:
            item_uuid = UUID(request.item_id)
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid item ID format")
        
        # Validate item type
        if request.item_type not in ['project', 'program', 'portfolio']:
            raise HTTPException(status_code=400, detail="Invalid item type")
        
        path = await HierarchyService.get_hierarchy_path(
            session=session,
            item_id=item_uuid,
            item_type=request.item_type,
            organization_id=current_org.id
        )
        
        return {
            'path': path,
            'depth': len(path)
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get hierarchy path: {e}")
        raise HTTPException(status_code=500, detail="Failed to get hierarchy path")


@router.get("/search")
async def search_hierarchy(
    query: str,
    item_types: Optional[List[str]] = Query(default=None),
    portfolio_id: Optional[str] = None,
    limit: int = 20,
    session: AsyncSession = Depends(get_db),
    current_org: Organization = Depends(get_current_organization),
    current_user: User = Depends(get_current_user),
    _: str = Depends(require_role("member"))
):
    """Search across the hierarchy for items matching the query."""
    try:
        from models.portfolio import Portfolio
        from models.program import Program
        from models.project import Project, ProjectStatus
        from sqlalchemy import or_
        from sqlalchemy.orm import selectinload

        if not query.strip():
            raise HTTPException(status_code=400, detail="Search query cannot be empty")

        # Validate item_types if provided
        valid_types = {'portfolio', 'program', 'project'}
        if item_types:
            invalid_types = set(item_types) - valid_types
            if invalid_types:
                raise HTTPException(
                    status_code=400,
                    detail=f"Invalid item types: {', '.join(invalid_types)}. Must be one of: {', '.join(valid_types)}"
                )

        # Parse portfolio_id if provided
        portfolio_uuid = None
        if portfolio_id:
            try:
                portfolio_uuid = UUID(portfolio_id)
            except ValueError:
                raise HTTPException(status_code=400, detail="Invalid portfolio ID format")

        results = []
        search_pattern = f"%{query.lower()}%"

        # Search portfolios if included
        if not item_types or 'portfolio' in item_types:
            portfolio_query = select(Portfolio).where(
                and_(
                    Portfolio.organization_id == current_org.id,
                    or_(
                        Portfolio.name.ilike(search_pattern),
                        Portfolio.description.ilike(search_pattern)
                    )
                )
            )
            if portfolio_uuid:
                portfolio_query = portfolio_query.where(Portfolio.id == portfolio_uuid)

            portfolio_query = portfolio_query.limit(limit)
            portfolio_result = await session.execute(portfolio_query)
            portfolios = portfolio_result.scalars().all()

            for portfolio in portfolios:
                results.append({
                    'id': str(portfolio.id),
                    'name': portfolio.name,
                    'description': portfolio.description,
                    'type': 'portfolio',
                    'path': [{'id': str(portfolio.id), 'name': portfolio.name, 'type': 'portfolio'}],
                    'created_at': portfolio.created_at.isoformat(),
                    'updated_at': portfolio.updated_at.isoformat()
                })

        # Search programs if included
        if not item_types or 'program' in item_types:
            program_query = select(Program).options(
                selectinload(Program.portfolio)
            ).where(
                and_(
                    Program.organization_id == current_org.id,
                    or_(
                        Program.name.ilike(search_pattern),
                        Program.description.ilike(search_pattern)
                    )
                )
            )
            if portfolio_uuid:
                program_query = program_query.where(Program.portfolio_id == portfolio_uuid)

            program_query = program_query.limit(limit)
            program_result = await session.execute(program_query)
            programs = program_result.scalars().all()

            for program in programs:
                path = []
                if program.portfolio:
                    path.append({
                        'id': str(program.portfolio.id),
                        'name': program.portfolio.name,
                        'type': 'portfolio'
                    })
                path.append({
                    'id': str(program.id),
                    'name': program.name,
                    'type': 'program'
                })

                results.append({
                    'id': str(program.id),
                    'name': program.name,
                    'description': program.description,
                    'type': 'program',
                    'portfolio_id': str(program.portfolio_id) if program.portfolio_id else None,
                    'path': path,
                    'created_at': program.created_at.isoformat(),
                    'updated_at': program.updated_at.isoformat()
                })

        # Search projects if included
        if not item_types or 'project' in item_types:
            project_query = select(Project).options(
                selectinload(Project.portfolio),
                selectinload(Project.program).selectinload(Program.portfolio)
            ).where(
                and_(
                    Project.organization_id == current_org.id,
                    Project.status != ProjectStatus.ARCHIVED,
                    or_(
                        Project.name.ilike(search_pattern),
                        Project.description.ilike(search_pattern)
                    )
                )
            )
            if portfolio_uuid:
                project_query = project_query.where(Project.portfolio_id == portfolio_uuid)

            project_query = project_query.limit(limit)
            project_result = await session.execute(project_query)
            projects = project_result.scalars().all()

            for project in projects:
                path = []
                portfolio = project.program.portfolio if project.program else project.portfolio
                if portfolio:
                    path.append({
                        'id': str(portfolio.id),
                        'name': portfolio.name,
                        'type': 'portfolio'
                    })
                if project.program:
                    path.append({
                        'id': str(project.program.id),
                        'name': project.program.name,
                        'type': 'program'
                    })
                path.append({
                    'id': str(project.id),
                    'name': project.name,
                    'type': 'project'
                })

                results.append({
                    'id': str(project.id),
                    'name': project.name,
                    'description': project.description,
                    'type': 'project',
                    'status': project.status.value,
                    'portfolio_id': str(project.portfolio_id) if project.portfolio_id else None,
                    'program_id': str(project.program_id) if project.program_id else None,
                    'path': path,
                    'created_at': project.created_at.isoformat(),
                    'updated_at': project.updated_at.isoformat()
                })

        # Sort results by relevance (exact match first, then by name)
        def sort_key(item):
            name_lower = item['name'].lower()
            query_lower = query.lower()
            if name_lower == query_lower:
                return (0, name_lower)  # Exact match
            elif name_lower.startswith(query_lower):
                return (1, name_lower)  # Starts with query
            else:
                return (2, name_lower)  # Contains query

        results.sort(key=sort_key)

        # Apply limit across all result types
        results = results[:limit]

        return {
            'query': query,
            'results': results,
            'total_count': len(results),
            'item_types_searched': item_types or ['portfolio', 'program', 'project'],
            'portfolio_filter': portfolio_id
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to search hierarchy: {e}")
        raise HTTPException(status_code=500, detail="Failed to search hierarchy")


@router.get("/statistics/summary")
async def get_hierarchy_statistics(
    session: AsyncSession = Depends(get_db),
    current_org: Organization = Depends(get_current_organization),
    current_user: User = Depends(get_current_user),
    _: str = Depends(require_role("member"))
):
    """Get overall hierarchy statistics."""
    try:
        from models.portfolio import Portfolio
        from models.program import Program
        from models.project import Project, ProjectStatus
        from sqlalchemy import func
        
        # Count portfolios for current organization
        portfolio_count_result = await session.execute(
            select(func.count(Portfolio.id)).where(
                Portfolio.organization_id == current_org.id
            )
        )
        portfolio_count = portfolio_count_result.scalar() or 0
        
        # Count programs for current organization
        program_count_result = await session.execute(
            select(func.count(Program.id)).where(
                Program.organization_id == current_org.id
            )
        )
        program_count = program_count_result.scalar() or 0
        
        # Count all projects (excluding archived) for current organization
        project_count_result = await session.execute(
            select(func.count(Project.id))
            .where(and_(
                Project.organization_id == current_org.id,
                Project.status != ProjectStatus.ARCHIVED
            ))
        )
        project_count = project_count_result.scalar() or 0
        
        # Count standalone projects (no portfolio and no program) for current organization
        standalone_projects_result = await session.execute(
            select(func.count(Project.id))
            .where(and_(
                Project.organization_id == current_org.id,
                Project.portfolio_id.is_(None),
                Project.program_id.is_(None),
                Project.status != ProjectStatus.ARCHIVED
            ))
        )
        standalone_project_count = standalone_projects_result.scalar() or 0
        
        # Count standalone programs (no portfolio) for current organization
        standalone_programs_result = await session.execute(
            select(func.count(Program.id))
            .where(and_(
                Program.organization_id == current_org.id,
                Program.portfolio_id.is_(None)
            ))
        )
        standalone_program_count = standalone_programs_result.scalar() or 0
        
        return {
            'portfolio_count': portfolio_count,
            'program_count': program_count,
            'project_count': project_count,
            'standalone_project_count': standalone_project_count,
            'standalone_program_count': standalone_program_count,
            'standalone_count': standalone_project_count + standalone_program_count,
            'total_count': portfolio_count + program_count + project_count
        }
        
    except Exception as e:
        logger.error(f"Failed to get hierarchy statistics: {e}")
        raise HTTPException(status_code=500, detail="Failed to get hierarchy statistics")