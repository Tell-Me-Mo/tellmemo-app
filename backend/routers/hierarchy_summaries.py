"""API endpoints for hierarchy-based summaries (program and portfolio)."""

from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from typing import Optional, List
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
import uuid

from utils.logger import get_logger
from db.database import get_db
from models.summary import Summary
from models.organization import Organization
from dependencies.auth import get_current_user, get_current_organization

router = APIRouter()
logger = get_logger(__name__)


class HierarchySummaryResponse(BaseModel):
    """Response model for hierarchy summaries (program/portfolio)."""
    summary_id: str
    entity_id: str
    summary_type: str
    subject: str
    body: str
    key_points: Optional[list] = None
    decisions: Optional[list] = None
    action_items: Optional[list] = None
    format: str = "general"
    created_at: str
    created_by: Optional[str] = None
    date_range_start: Optional[str] = None
    date_range_end: Optional[str] = None


@router.get("/program/{program_id}/summaries", response_model=List[HierarchySummaryResponse])
async def get_program_summaries(
    program_id: str,
    limit: int = 50,
    session: AsyncSession = Depends(get_db),
    current_user = Depends(get_current_user),
    current_org: Organization = Depends(get_current_organization)
):
    """
    Get all summaries for a specific program.

    Requires authentication and filters by organization.
    """
    logger.info(f"Fetching summaries for program {program_id} in organization {current_org.id}")

    # Validate UUID format before entering try block
    try:
        program_uuid = uuid.UUID(program_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid program ID format")

    try:
        # Query summaries for this program with multi-tenant isolation
        query = select(Summary).where(
            Summary.program_id == program_uuid,
            Summary.organization_id == current_org.id  # Multi-tenant isolation
        ).order_by(Summary.created_at.desc()).limit(limit)

        result = await session.execute(query)
        summaries = result.scalars().all()

        response_summaries = []
        for summary in summaries:
            response_summaries.append(HierarchySummaryResponse(
                summary_id=str(summary.id),
                entity_id=str(program_uuid),
                summary_type=summary.summary_type.value.upper(),
                subject=summary.subject,
                body=summary.body or "",
                key_points=summary.key_points or [],
                decisions=summary.decisions or [],
                action_items=summary.action_items or [],
                format=getattr(summary, 'format', 'general'),
                created_at=summary.created_at.isoformat(),
                created_by=summary.created_by,
                date_range_start=summary.date_range_start.isoformat() if summary.date_range_start else None,
                date_range_end=summary.date_range_end.isoformat() if summary.date_range_end else None
            ))

        return response_summaries

    except Exception as e:
        logger.error(f"Failed to fetch program summaries: {e}")
        raise HTTPException(status_code=500, detail="Failed to fetch program summaries")


@router.get("/portfolio/{portfolio_id}/summaries", response_model=List[HierarchySummaryResponse])
async def get_portfolio_summaries(
    portfolio_id: str,
    limit: int = 50,
    session: AsyncSession = Depends(get_db),
    current_user = Depends(get_current_user),
    current_org: Organization = Depends(get_current_organization)
):
    """
    Get all summaries for a specific portfolio.

    Requires authentication and filters by organization.
    """
    logger.info(f"Fetching summaries for portfolio {portfolio_id} in organization {current_org.id}")

    # Validate UUID format before entering try block
    try:
        portfolio_uuid = uuid.UUID(portfolio_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid portfolio ID format")

    try:
        # Query summaries for this portfolio with multi-tenant isolation
        query = select(Summary).where(
            Summary.portfolio_id == portfolio_uuid,
            Summary.organization_id == current_org.id  # Multi-tenant isolation
        ).order_by(Summary.created_at.desc()).limit(limit)

        result = await session.execute(query)
        summaries = result.scalars().all()

        response_summaries = []
        for summary in summaries:
            response_summaries.append(HierarchySummaryResponse(
                summary_id=str(summary.id),
                entity_id=str(portfolio_uuid),
                summary_type=summary.summary_type.value.upper(),
                subject=summary.subject,
                body=summary.body or "",
                key_points=summary.key_points or [],
                decisions=summary.decisions or [],
                action_items=summary.action_items or [],
                format=getattr(summary, 'format', 'general'),
                created_at=summary.created_at.isoformat(),
                created_by=summary.created_by,
                date_range_start=summary.date_range_start.isoformat() if summary.date_range_start else None,
                date_range_end=summary.date_range_end.isoformat() if summary.date_range_end else None
            ))

        return response_summaries

    except Exception as e:
        logger.error(f"Failed to fetch portfolio summaries: {e}")
        raise HTTPException(status_code=500, detail="Failed to fetch portfolio summaries")