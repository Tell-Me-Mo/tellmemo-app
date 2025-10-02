"""API endpoints for hierarchy-based summaries (program and portfolio)."""

from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime, timedelta
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
import uuid

from utils.logger import get_logger
from utils.exceptions import (
    APIException,
    LLMOverloadedException,
    LLMRateLimitException,
    LLMAuthenticationException,
    LLMTimeoutException,
    InsufficientDataException
)
from db.database import get_db
from services.summaries.summary_service_refactored import summary_service
from models.summary import Summary, SummaryType

router = APIRouter()
logger = get_logger(__name__)


class HierarchySummaryRequest(BaseModel):
    type: str = Field(..., description="Summary type: 'program' or 'portfolio'")
    entity_id: str = Field(..., description="Program or Portfolio ID")
    date_range_start: Optional[datetime] = Field(None, description="Start date for summary")
    date_range_end: Optional[datetime] = Field(None, description="End date for summary")
    created_by: Optional[str] = Field(None, description="User who requested the summary")
    format: Optional[str] = Field("general", description="Summary format: 'general', 'executive', 'technical', or 'stakeholder'")


class HierarchySummaryResponse(BaseModel):
    summary_id: str
    entity_id: str
    summary_type: str
    subject: str
    body: str
    key_points: Optional[list] = None
    decisions: Optional[list] = None
    action_items: Optional[list] = None
    sentiment_analysis: Optional[dict] = None
    communication_insights: Optional[dict] = None
    cross_meeting_insights: Optional[dict] = None
    next_meeting_agenda: Optional[list] = None
    format: str = "general"
    created_at: str
    created_by: Optional[str] = None
    date_range_start: Optional[str] = None
    date_range_end: Optional[str] = None
    token_count: Optional[int] = None
    generation_time_ms: Optional[int] = None
    # Program/Portfolio specific fields
    risks: Optional[list] = None
    blockers: Optional[list] = None
    cross_project_dependencies: Optional[list] = None
    resource_metrics: Optional[dict] = None
    program_health: Optional[dict] = None
    program_performance: Optional[list] = None
    portfolio_metrics: Optional[dict] = None
    strategic_initiatives: Optional[list] = None


@router.post("/program/{program_id}/summary", deprecated=True)
async def generate_program_summary(
    program_id: str,
    request: HierarchySummaryRequest,
    session: AsyncSession = Depends(get_db)
):
    """
    Generate a summary for all projects in a program.

    **DEPRECATED**: Use POST /api/summaries/generate instead.
    This endpoint will be removed in a future version.
    """
    logger.info(f"Generating program summary for program {program_id}")

    try:
        # Convert program_id to UUID
        try:
            program_uuid = uuid.UUID(program_id)
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid program ID format")

        # Set default date range if not provided
        week_start = request.date_range_start if request.date_range_start else datetime.now() - timedelta(days=7)
        week_end = request.date_range_end if request.date_range_end else datetime.now()

        # Generate program summary
        summary_data = await summary_service.generate_program_summary(
            session=session,
            program_id=program_uuid,
            week_start=week_start,
            week_end=week_end,
            created_by=request.created_by,
            format_type=request.format
        )

        return HierarchySummaryResponse(
            summary_id=summary_data.get("id", str(uuid.uuid4())),
            entity_id=str(program_uuid),
            summary_type="PROGRAM",
            subject=summary_data.get("subject", "Program Summary"),
            body=summary_data.get("summary_text", ""),
            key_points=summary_data.get("key_points", []),
            decisions=summary_data.get("decisions", []),
            action_items=summary_data.get("action_items", []),
            sentiment_analysis=summary_data.get("sentiment_analysis"),
            risks=summary_data.get("risks"),
            blockers=summary_data.get("blockers"),
            communication_insights=summary_data.get("communication_insights"),
            cross_meeting_insights=summary_data.get("cross_meeting_insights"),
            next_meeting_agenda=summary_data.get("next_meeting_agenda"),
            format=request.format,
            created_at=datetime.now().isoformat(),
            created_by=request.created_by,
            date_range_start=summary_data.get("date_range_start", week_start.isoformat() if week_start else None),
            date_range_end=summary_data.get("date_range_end", week_end.isoformat() if week_end else None),
            token_count=summary_data.get("token_count"),
            generation_time_ms=summary_data.get("generation_time_ms"),
            # Program-specific fields
            cross_project_dependencies=summary_data.get("cross_project_dependencies"),
            resource_metrics=summary_data.get("resource_metrics"),
            program_health=summary_data.get("program_health")
        )

    except APIException as e:
        logger.error(f"API error generating program summary: {e.message}")
        raise HTTPException(
            status_code=e.status_code,
            detail={
                "error": e.error_code,
                "message": e.message,
                "user_message": e.details.get("user_message", e.message),
                "retry_after": e.details.get("retry_after")
            }
        )
    except ValueError as e:
        logger.error(f"Validation error generating program summary: {e}")
        raise HTTPException(status_code=422, detail=str(e))
    except Exception as e:
        logger.error(f"Failed to generate program summary: {e}")
        raise HTTPException(status_code=500, detail="Failed to generate program summary")


@router.post("/portfolio/{portfolio_id}/summary", deprecated=True)
async def generate_portfolio_summary(
    portfolio_id: str,
    request: HierarchySummaryRequest,
    session: AsyncSession = Depends(get_db)
):
    """
    Generate a summary for all projects in a portfolio.

    **DEPRECATED**: Use POST /api/summaries/generate instead.
    This endpoint will be removed in a future version.
    """
    logger.info(f"Generating portfolio summary for portfolio {portfolio_id}")

    try:
        # Convert portfolio_id to UUID
        try:
            portfolio_uuid = uuid.UUID(portfolio_id)
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid portfolio ID format")

        # Set default date range if not provided
        week_start = request.date_range_start if request.date_range_start else datetime.now() - timedelta(days=7)
        week_end = request.date_range_end if request.date_range_end else datetime.now()

        # Generate portfolio summary
        summary_data = await summary_service.generate_portfolio_summary(
            session=session,
            portfolio_id=portfolio_uuid,
            week_start=week_start,
            week_end=week_end,
            created_by=request.created_by,
            format_type=request.format
        )

        return HierarchySummaryResponse(
            summary_id=summary_data.get("id", str(uuid.uuid4())),
            entity_id=str(portfolio_uuid),
            summary_type="PORTFOLIO",
            subject=summary_data.get("subject", "Portfolio Summary"),
            body=summary_data.get("summary_text", ""),
            key_points=summary_data.get("key_points", []),
            decisions=summary_data.get("decisions", []),
            action_items=summary_data.get("action_items", []),
            sentiment_analysis=summary_data.get("sentiment_analysis"),
            risks=summary_data.get("risks"),
            blockers=summary_data.get("blockers"),
            communication_insights=summary_data.get("communication_insights"),
            cross_meeting_insights=summary_data.get("cross_meeting_insights"),
            next_meeting_agenda=summary_data.get("next_meeting_agenda"),
            format=request.format,
            created_at=datetime.now().isoformat(),
            created_by=request.created_by,
            date_range_start=summary_data.get("date_range_start", week_start.isoformat() if week_start else None),
            date_range_end=summary_data.get("date_range_end", week_end.isoformat() if week_end else None),
            token_count=summary_data.get("token_count"),
            generation_time_ms=summary_data.get("generation_time_ms"),
            # Portfolio-specific fields
            program_performance=summary_data.get("program_performance"),
            portfolio_metrics=summary_data.get("portfolio_metrics"),
            strategic_initiatives=summary_data.get("strategic_initiatives")
        )

    except APIException as e:
        logger.error(f"API error generating portfolio summary: {e.message}")
        raise HTTPException(
            status_code=e.status_code,
            detail={
                "error": e.error_code,
                "message": e.message,
                "user_message": e.details.get("user_message", e.message),
                "retry_after": e.details.get("retry_after")
            }
        )
    except ValueError as e:
        logger.error(f"Validation error generating portfolio summary: {e}")
        raise HTTPException(status_code=422, detail=str(e))
    except Exception as e:
        logger.error(f"Failed to generate portfolio summary: {e}")
        raise HTTPException(status_code=500, detail="Failed to generate portfolio summary")


@router.get("/program/{program_id}/summaries", response_model=List[HierarchySummaryResponse])
async def get_program_summaries(
    program_id: str,
    limit: int = 50,
    session: AsyncSession = Depends(get_db)
):
    """Get all summaries for a specific program."""
    logger.info(f"Fetching summaries for program {program_id}")

    try:
        # Convert program_id to UUID
        try:
            program_uuid = uuid.UUID(program_id)
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid program ID format")

        # Query summaries for this program
        query = select(Summary).where(
            Summary.program_id == program_uuid
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
    session: AsyncSession = Depends(get_db)
):
    """Get all summaries for a specific portfolio."""
    logger.info(f"Fetching summaries for portfolio {portfolio_id}")

    try:
        # Convert portfolio_id to UUID
        try:
            portfolio_uuid = uuid.UUID(portfolio_id)
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid portfolio ID format")

        # Query summaries for this portfolio
        query = select(Summary).where(
            Summary.portfolio_id == portfolio_uuid
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