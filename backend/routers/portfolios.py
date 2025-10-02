"""Portfolio management endpoints."""

from typing import List, Optional, Dict, Any
from uuid import UUID
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import func, select, or_, and_
from datetime import datetime

from db.database import db_manager, get_db
from dependencies.auth import get_current_organization, get_current_user, require_role
from models.organization import Organization
from models.user import User
from models.portfolio import Portfolio, HealthStatus
from models.program import Program
from models.project import Project
from models.content import Content
from models.summary import Summary, SummaryType
from pydantic import BaseModel
from services.rag.enhanced_rag_service_refactored import enhanced_rag_service, RAGStrategy
from services.summaries.summary_service_refactored import summary_service
from services.activity.activity_service import ActivityService
from services.prompts.portfolio_prompts import (
    get_portfolio_query_prompt
    # Portfolio summary generation moved to hierarchy_summaries.py router
)
from utils.logger import get_logger
from config import get_settings
from services.llm.multi_llm_client import get_multi_llm_client

logger = get_logger(__name__)


router = APIRouter(prefix="/api/portfolios", tags=["portfolios"])


class PortfolioCreate(BaseModel):
    """Schema for creating a portfolio."""
    name: str
    description: Optional[str] = None
    owner: Optional[str] = None
    health_status: Optional[HealthStatus] = HealthStatus.NOT_SET
    risk_summary: Optional[str] = None
    created_by: Optional[str] = None


class PortfolioUpdate(BaseModel):
    """Schema for updating a portfolio."""
    name: Optional[str] = None
    description: Optional[str] = None
    owner: Optional[str] = None
    health_status: Optional[HealthStatus] = None
    risk_summary: Optional[str] = None


class PortfolioResponse(BaseModel):
    """Schema for portfolio response."""
    id: UUID
    name: str
    description: Optional[str]
    owner: Optional[str]
    health_status: HealthStatus
    risk_summary: Optional[str]
    created_by: Optional[str]
    created_at: datetime
    updated_at: datetime
    program_count: int = 0
    direct_project_count: int = 0
    total_project_count: int = 0

    class Config:
        from_attributes = True


@router.post("/", response_model=PortfolioResponse)
async def create_portfolio(
    portfolio: PortfolioCreate,
    db: AsyncSession = Depends(get_db),
    current_org: Organization = Depends(get_current_organization),
    current_user: User = Depends(get_current_user)
):
    """Create a new portfolio."""
    # Check if portfolio with same name exists in the organization
    result = await db.execute(
        select(Portfolio).where(
            and_(
                Portfolio.name == portfolio.name,
                Portfolio.organization_id == current_org.id
            )
        )
    )
    existing = result.scalar_one_or_none()
    if existing:
        raise HTTPException(status_code=400, detail="Portfolio with this name already exists in this organization")

    db_portfolio = Portfolio(
        name=portfolio.name,
        description=portfolio.description,
        owner=portfolio.owner or current_user.email,
        health_status=portfolio.health_status,
        risk_summary=portfolio.risk_summary,
        created_by=portfolio.created_by or current_user.email,
        organization_id=current_org.id
    )
    db.add(db_portfolio)
    await db.commit()
    await db.refresh(db_portfolio)
    
    # Get counts
    program_count_result = await db.execute(
        select(func.count(Program.id)).where(
            and_(
                Program.portfolio_id == db_portfolio.id,
                Program.organization_id == current_org.id
            )
        )
    )
    program_count = program_count_result.scalar()
    
    direct_project_count_result = await db.execute(
        select(func.count(Project.id)).where(
            and_(
                Project.portfolio_id == db_portfolio.id,
                Project.organization_id == current_org.id,
                Project.program_id.is_(None)
            )
        )
    )
    direct_project_count = direct_project_count_result.scalar()
    
    total_project_count_result = await db.execute(
        select(func.count(Project.id)).where(
            and_(
                Project.portfolio_id == db_portfolio.id,
                Project.organization_id == current_org.id
            )
        )
    )
    total_project_count = total_project_count_result.scalar()
    
    response = PortfolioResponse(
        **db_portfolio.__dict__,
        program_count=program_count or 0,
        direct_project_count=direct_project_count or 0,
        total_project_count=total_project_count or 0
    )
    return response


@router.get("/", response_model=List[PortfolioResponse])
async def list_portfolios(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=1000),
    db: AsyncSession = Depends(get_db),
    current_org: Organization = Depends(get_current_organization)
):
    """List all portfolios with statistics."""
    result = await db.execute(
        select(Portfolio)
        .where(Portfolio.organization_id == current_org.id)
        .offset(skip).limit(limit)
    )
    portfolios = result.scalars().all()
    
    response = []
    for portfolio in portfolios:
        program_count_result = await db.execute(
            select(func.count(Program.id)).where(
                and_(
                    Program.portfolio_id == portfolio.id,
                    Program.organization_id == current_org.id
                )
            )
        )
        program_count = program_count_result.scalar()
        
        direct_project_count_result = await db.execute(
            select(func.count(Project.id)).where(
                and_(
                    Project.portfolio_id == portfolio.id,
                    Project.organization_id == current_org.id,
                    Project.program_id.is_(None)
                )
            )
        )
        direct_project_count = direct_project_count_result.scalar()
        
        total_project_count_result = await db.execute(
            select(func.count(Project.id)).where(
                and_(
                    Project.portfolio_id == portfolio.id,
                    Project.organization_id == current_org.id
                )
            )
        )
        total_project_count = total_project_count_result.scalar()
        
        response.append(PortfolioResponse(
            **portfolio.__dict__,
            program_count=program_count or 0,
            direct_project_count=direct_project_count or 0,
            total_project_count=total_project_count or 0
        ))
    
    return response


@router.get("/{portfolio_id}", response_model=PortfolioResponse)
async def get_portfolio(
    portfolio_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_org: Organization = Depends(get_current_organization)
):
    """Get a specific portfolio by ID."""
    result = await db.execute(
        select(Portfolio).where(
            and_(
                Portfolio.id == portfolio_id,
                Portfolio.organization_id == current_org.id
            )
        )
    )
    portfolio = result.scalar_one_or_none()
    if not portfolio:
        raise HTTPException(status_code=404, detail="Portfolio not found")
    
    program_count_result = await db.execute(
        select(func.count(Program.id)).where(
            and_(
                Program.portfolio_id == portfolio.id,
                Program.organization_id == current_org.id
            )
        )
    )
    program_count = program_count_result.scalar()
    
    direct_project_count_result = await db.execute(
        select(func.count(Project.id)).where(
            and_(
                Project.portfolio_id == portfolio.id,
                Project.organization_id == current_org.id,
                Project.program_id.is_(None)
            )
        )
    )
    direct_project_count = direct_project_count_result.scalar()
    
    total_project_count_result = await db.execute(
        select(func.count(Project.id)).where(
            and_(
                Project.portfolio_id == portfolio.id,
                Project.organization_id == current_org.id
            )
        )
    )
    total_project_count = total_project_count_result.scalar()
    
    return PortfolioResponse(
        **portfolio.__dict__,
        program_count=program_count or 0,
        direct_project_count=direct_project_count or 0,
        total_project_count=total_project_count or 0
    )


@router.put("/{portfolio_id}", response_model=PortfolioResponse)
async def update_portfolio(
    portfolio_id: UUID,
    portfolio_update: PortfolioUpdate,
    db: AsyncSession = Depends(get_db),
    current_org: Organization = Depends(get_current_organization),
    _: str = Depends(require_role("member"))
):
    """Update a portfolio."""
    result = await db.execute(
        select(Portfolio).where(
            and_(
                Portfolio.id == portfolio_id,
                Portfolio.organization_id == current_org.id
            )
        )
    )
    portfolio = result.scalar_one_or_none()
    if not portfolio:
        raise HTTPException(status_code=404, detail="Portfolio not found")
    
    if portfolio_update.name is not None:
        portfolio.name = portfolio_update.name
    if portfolio_update.description is not None:
        portfolio.description = portfolio_update.description
    if portfolio_update.owner is not None:
        portfolio.owner = portfolio_update.owner
    if portfolio_update.health_status is not None:
        portfolio.health_status = portfolio_update.health_status
    if portfolio_update.risk_summary is not None:
        portfolio.risk_summary = portfolio_update.risk_summary

    portfolio.updated_at = datetime.utcnow()
    await db.commit()
    await db.refresh(portfolio)
    
    program_count_result = await db.execute(
        select(func.count(Program.id)).where(
            and_(
                Program.portfolio_id == portfolio.id,
                Program.organization_id == current_org.id
            )
        )
    )
    program_count = program_count_result.scalar()
    
    direct_project_count_result = await db.execute(
        select(func.count(Project.id)).where(
            and_(
                Project.portfolio_id == portfolio.id,
                Project.organization_id == current_org.id,
                Project.program_id.is_(None)
            )
        )
    )
    direct_project_count = direct_project_count_result.scalar()
    
    total_project_count_result = await db.execute(
        select(func.count(Project.id)).where(
            and_(
                Project.portfolio_id == portfolio.id,
                Project.organization_id == current_org.id
            )
        )
    )
    total_project_count = total_project_count_result.scalar()
    
    return PortfolioResponse(
        **portfolio.__dict__,
        program_count=program_count or 0,
        direct_project_count=direct_project_count or 0,
        total_project_count=total_project_count or 0
    )


class DeletePortfolioRequest(BaseModel):
    """Request for deleting a portfolio with options."""
    cascade_delete: bool = False  # If True, delete all programs and projects. If False, make them standalone.


@router.get("/{portfolio_id}/deletion-impact")
async def get_portfolio_deletion_impact(
    portfolio_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_org: Organization = Depends(get_current_organization)
):
    """Get information about what will be affected by deleting a portfolio."""
    result = await db.execute(
        select(Portfolio).where(
            and_(
                Portfolio.id == portfolio_id,
                Portfolio.organization_id == current_org.id
            )
        )
    )
    portfolio = result.scalar_one_or_none()
    if not portfolio:
        raise HTTPException(status_code=404, detail="Portfolio not found")

    # Get all programs in this portfolio
    programs_result = await db.execute(
        select(Program).where(
            and_(
                Program.portfolio_id == portfolio_id,
                Program.organization_id == current_org.id
            )
        )
    )
    programs = programs_result.scalars().all()

    # Get all direct projects in this portfolio
    projects_result = await db.execute(
        select(Project).where(
            and_(
                Project.portfolio_id == portfolio_id,
                Project.organization_id == current_org.id
            )
        )
    )
    projects = projects_result.scalars().all()

    return {
        "portfolio": {
            "id": str(portfolio.id),
            "name": portfolio.name,
            "description": portfolio.description
        },
        "affected_programs": [
            {
                "id": str(p.id),
                "name": p.name,
                "description": p.description
            } for p in programs
        ],
        "affected_projects": [
            {
                "id": str(p.id),
                "name": p.name,
                "description": p.description
            } for p in projects
        ],
        "total_programs": len(programs),
        "total_projects": len(projects)
    }


@router.delete("/{portfolio_id}")
async def delete_portfolio(
    portfolio_id: UUID,
    cascade_delete: bool = Query(False, description="Delete all related programs and projects if True, otherwise make them standalone"),
    db: AsyncSession = Depends(get_db),
    current_org: Organization = Depends(get_current_organization),
    _: str = Depends(require_role("admin"))
):
    """Delete a portfolio with option to cascade or orphan related entities."""
    result = await db.execute(
        select(Portfolio).where(
            and_(
                Portfolio.id == portfolio_id,
                Portfolio.organization_id == current_org.id
            )
        )
    )
    portfolio = result.scalar_one_or_none()
    if not portfolio:
        raise HTTPException(status_code=404, detail="Portfolio not found")

    # Get all programs and projects in this portfolio
    programs_result = await db.execute(
        select(Program).where(
            and_(
                Program.portfolio_id == portfolio_id,
                Program.organization_id == current_org.id
            )
        )
    )
    programs = programs_result.scalars().all()

    projects_result = await db.execute(
        select(Project).where(
            and_(
                Project.portfolio_id == portfolio_id,
                Project.organization_id == current_org.id
            )
        )
    )
    projects = projects_result.scalars().all()

    affected_entities = {
        "programs": [{"id": str(p.id), "name": p.name} for p in programs],
        "projects": [{"id": str(p.id), "name": p.name} for p in projects]
    }

    if cascade_delete:
        # Delete all programs and projects manually since we removed CASCADE from database
        for program in programs:
            await db.delete(program)
        for project in projects:
            await db.delete(project)

    # Delete the portfolio
    # Note: If cascade_delete=False, programs and projects will automatically become standalone
    # due to the SET NULL foreign key constraint we configured
    await db.delete(portfolio)
    await db.commit()

    return {
        "message": f"Portfolio deleted successfully. {'All related entities deleted.' if cascade_delete else 'Related entities are now standalone.'}",
        "affected_entities": affected_entities,
        "cascade_delete": cascade_delete
    }


@router.get("/{portfolio_id}/programs")
async def get_portfolio_programs(
    portfolio_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_org: Organization = Depends(get_current_organization)
):
    """Get all programs in a portfolio."""
    result = await db.execute(
        select(Portfolio).where(
            and_(
                Portfolio.id == portfolio_id,
                Portfolio.organization_id == current_org.id
            )
        )
    )
    portfolio = result.scalar_one_or_none()
    if not portfolio:
        raise HTTPException(status_code=404, detail="Portfolio not found")
    
    programs_result = await db.execute(
        select(Program).where(
            and_(
                Program.portfolio_id == portfolio_id,
                Program.organization_id == current_org.id
            )
        )
    )
    programs = programs_result.scalars().all()
    return programs


@router.get("/{portfolio_id}/projects")
async def get_portfolio_projects(
    portfolio_id: UUID,
    direct_only: bool = Query(False, description="Only return direct projects without a program"),
    db: AsyncSession = Depends(get_db),
    current_org: Organization = Depends(get_current_organization)
):
    """Get projects in a portfolio."""
    result = await db.execute(
        select(Portfolio).where(
            and_(
                Portfolio.id == portfolio_id,
                Portfolio.organization_id == current_org.id
            )
        )
    )
    portfolio = result.scalar_one_or_none()
    if not portfolio:
        raise HTTPException(status_code=404, detail="Portfolio not found")
    
    query = select(Project).where(
        and_(
            Project.portfolio_id == portfolio_id,
            Project.organization_id == current_org.id
        )
    )
    if direct_only:
        query = query.where(Project.program_id.is_(None))
    
    projects_result = await db.execute(query)
    projects = projects_result.scalars().all()
    return projects


@router.get("/{portfolio_id}/statistics")
async def get_portfolio_statistics(
    portfolio_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_org: Organization = Depends(get_current_organization)
):
    """Get statistics for a portfolio."""
    # Check portfolio exists
    result = await db.execute(
        select(Portfolio).where(
            and_(
                Portfolio.id == portfolio_id,
                Portfolio.organization_id == current_org.id
            )
        )
    )
    portfolio = result.scalar_one_or_none()
    if not portfolio:
        raise HTTPException(status_code=404, detail="Portfolio not found")
    
    # Count programs
    programs_count_result = await db.execute(
        select(func.count(Program.id)).where(
            and_(
                Program.portfolio_id == portfolio_id,
                Program.organization_id == current_org.id
            )
        )
    )
    programs_count = programs_count_result.scalar() or 0
    
    # Count direct projects (without program)
    direct_projects_result = await db.execute(
        select(func.count(Project.id))
        .where(
            and_(
                Project.portfolio_id == portfolio_id,
                Project.organization_id == current_org.id,
                Project.program_id.is_(None)
            )
        )
    )
    direct_projects_count = direct_projects_result.scalar() or 0
    
    # Count all projects under this portfolio
    all_projects_result = await db.execute(
        select(func.count(Project.id))
        .where(
            and_(
                Project.portfolio_id == portfolio_id,
                Project.organization_id == current_org.id
            )
        )
    )
    all_projects_count = all_projects_result.scalar() or 0
    
    # Count archived projects
    from models.project import ProjectStatus
    archived_projects_result = await db.execute(
        select(func.count(Project.id))
        .where(
            and_(
                Project.portfolio_id == portfolio_id,
                Project.organization_id == current_org.id,
                Project.status == ProjectStatus.ARCHIVED
            )
        )
    )
    archived_projects_count = archived_projects_result.scalar() or 0
    
    # Count content items for all projects in portfolio
    from models.content import Content
    content_count_result = await db.execute(
        select(func.count(Content.id))
        .join(Project, Content.project_id == Project.id)
        .where(
            and_(
                Project.portfolio_id == portfolio_id,
                Project.organization_id == current_org.id
            )
        )
    )
    content_count = content_count_result.scalar() or 0
    
    # Count summaries for all projects in portfolio
    from models.summary import Summary
    summaries_count_result = await db.execute(
        select(func.count(Summary.id))
        .join(Project, Summary.project_id == Project.id)
        .where(
            and_(
                Project.portfolio_id == portfolio_id,
                Project.organization_id == current_org.id
            )
        )
    )
    summaries_count = summaries_count_result.scalar() or 0
    
    return {
        "portfolio_id": str(portfolio_id),
        "portfolio_name": portfolio.name,
        "program_count": programs_count,
        "project_count": all_projects_count,
        "direct_project_count": direct_projects_count,
        "archived_project_count": archived_projects_count,
        "content_count": content_count,
        "summary_count": summaries_count,
        "created_at": portfolio.created_at.isoformat(),
        "updated_at": portfolio.updated_at.isoformat() if portfolio.updated_at else None
    }


class QueryPortfolioRequest(BaseModel):
    """Request for querying portfolio content."""
    query: str
    include_archived_projects: bool = False
    limit: int = 10


class QueryPortfolioResponse(BaseModel):
    """Response from portfolio query - aligned with project query pattern."""
    answer: str  # Main synthesized answer
    sources: List[str]  # Source projects
    confidence: float  # Confidence score
    # Additional portfolio-specific fields
    results: Optional[List[Dict[str, Any]]] = None  # Raw results for detailed view
    projects_searched: int = 0
    total_results: int = 0


@router.post("/{portfolio_id}/query", response_model=QueryPortfolioResponse)
async def query_portfolio(
    portfolio_id: UUID,
    request: QueryPortfolioRequest,
    db: AsyncSession = Depends(get_db),
    current_org: Organization = Depends(get_current_organization)
):
    """
    Query all projects within a portfolio using RAG.
    Aggregates content from all projects in the portfolio for semantic search.
    """
    # Verify portfolio exists
    result = await db.execute(
        select(Portfolio).where(
            and_(
                Portfolio.id == portfolio_id,
                Portfolio.organization_id == current_org.id
            )
        )
    )
    portfolio = result.scalar_one_or_none()
    if not portfolio:
        raise HTTPException(status_code=404, detail="Portfolio not found")

    # Get all projects in the portfolio (including those in programs)
    from models.project import ProjectStatus
    projects_query = select(Project).where(
        and_(
            or_(
                Project.portfolio_id == portfolio_id,
                Project.program_id.in_(
                    select(Program.id).where(
                        and_(
                            Program.portfolio_id == portfolio_id,
                            Program.organization_id == current_org.id
                        )
                    )
                )
            ),
            Project.organization_id == current_org.id
        )
    )
    if not request.include_archived_projects:
        projects_query = projects_query.where(Project.status != ProjectStatus.ARCHIVED)

    projects_result = await db.execute(projects_query)
    projects = projects_result.scalars().all()

    if not projects:
        return QueryPortfolioResponse(
            answer="No projects found in this portfolio to query.",
            sources=[],
            confidence=0.0,
            results=[],
            projects_searched=0,
            total_results=0
        )

    # Use singleton RAG service instance (aligned with project pattern)

    # Aggregate results from all projects
    all_chunks = []
    projects_with_results = []

    try:
        # Collect chunks from all projects
        for project in projects:
            try:
                # Query each project using RAG (use singleton service)
                rag_response = await enhanced_rag_service.query_project(
                    project_id=str(project.id),
                    question=request.query,
                    strategy=RAGStrategy.HYBRID_SEARCH  # Use hybrid search for portfolio queries
                )

                # Extract relevant chunks from the response
                if rag_response.get("relevant_chunks"):
                    for chunk in rag_response["relevant_chunks"][:3]:  # Top 3 from each project
                        all_chunks.append({
                            "project_id": str(project.id),
                            "project_name": project.name,
                            "content": chunk.get("text", ""),
                            "relevance_score": chunk.get("score", 0.0),
                            "metadata": chunk.get("metadata", {})
                        })
                    projects_with_results.append(project.name)

            except Exception as e:
                logger.warning(f"Failed to query project {project.id}: {str(e)}")
                continue

        if not all_chunks:
            return QueryPortfolioResponse(
                answer="No relevant information found in the portfolio projects for your query.",
                sources=[],
                confidence=0.0,
                results=[],
                projects_searched=len(projects),
                total_results=0
            )

        # Sort chunks by relevance
        all_chunks.sort(key=lambda x: x["relevance_score"], reverse=True)
        top_chunks = all_chunks[:request.limit * 2]  # Get more chunks for Claude to analyze

        # Prepare portfolio context
        portfolio_context = {
            "program_count": len(await db.execute(select(Program).where(Program.portfolio_id == portfolio_id)).then(lambda r: r.scalars().all())),
            "project_count": len(projects),
            "health_status": portfolio.health_status.value,
            "owner": portfolio.owner
        }

        # Get programs count properly
        programs_result = await db.execute(
            select(func.count(Program.id)).where(
                and_(
                    Program.portfolio_id == portfolio_id,
                    Program.organization_id == current_org.id
                )
            )
        )
        portfolio_context["program_count"] = programs_result.scalar() or 0

        # Initialize Claude client if available
        settings = get_settings()
        llm_client = get_multi_llm_client(settings)
        claude_response = None

        if llm_client.is_available():
            try:
                # Generate portfolio-specific prompt
                prompt = get_portfolio_query_prompt(
                    query=request.query,
                    portfolio_name=portfolio.name,
                    portfolio_context=portfolio_context,
                    aggregated_chunks=top_chunks
                )

                # Get LLM analysis
                message = await llm_client.create_message(
                    prompt=prompt,
                    model=settings.llm_model,
                    max_tokens=settings.max_tokens,
                    temperature=settings.temperature
                )

                claude_response = message.content[0].text if message.content else None

            except Exception as e:
                logger.error(f"LLM analysis failed: {str(e)}")
                # Continue without LLM enhancement

        # Format results
        results = []

        # If we have Claude's response, add it as the first result
        if claude_response:
            results.append({
                "project_id": "portfolio-analysis",
                "project_name": f"Portfolio Analysis: {portfolio.name}",
                "content": claude_response,
                "relevance_score": 1.0,
                "metadata": {"type": "ai-synthesis", "projects_analyzed": len(projects_with_results)}
            })

        # Add top individual chunks
        for chunk in top_chunks[:request.limit - 1 if claude_response else request.limit]:
            results.append(chunk)

        # Log activity for portfolio query (aligned with project pattern)
        try:
            await ActivityService.log_query_submitted(
                db=db,
                project_id=portfolio_id,  # Use portfolio_id as project_id for now
                query_text=request.query,
                user_name="portfolio_user"  # TODO: Get actual user from context
            )
            await db.commit()
        except Exception as e:
            logger.warning(f"Failed to log portfolio query activity: {e}")

        # Format response aligned with project query pattern
        answer = claude_response if claude_response else f"Found {len(all_chunks)} relevant results across {len(projects_with_results)} projects in the portfolio."

        # Extract unique project sources
        sources = list(set([chunk["project_name"] for chunk in top_chunks[:10]]))

        # Calculate confidence based on result quality
        avg_score = sum(chunk["relevance_score"] for chunk in top_chunks[:5]) / min(5, len(top_chunks)) if top_chunks else 0.0
        confidence = min(avg_score + 0.2, 1.0) if claude_response else avg_score  # Boost confidence if Claude analyzed

        # Log the query for analytics
        logger.info(f"Portfolio query completed: {len(results)} results from {len(projects_with_results)} projects")

        return QueryPortfolioResponse(
            answer=answer,
            sources=sources,
            confidence=confidence,
            results=results,  # Include detailed results
            projects_searched=len(projects),
            total_results=len(all_chunks)
        )

    except Exception as e:
        logger.error(f"Portfolio query failed: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to execute portfolio query: {str(e)}"
        )