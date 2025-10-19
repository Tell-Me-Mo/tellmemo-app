"""Live Meeting Insights API Router."""

from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from typing import List, Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_
from datetime import datetime
import uuid

from db.database import get_db
from dependencies.auth import get_current_user, require_role
from models.user import User
from models.project import Project
from models.organization_member import OrganizationMember
from models.live_meeting_insight import LiveMeetingInsight
from utils.logger import get_logger, sanitize_for_log

router = APIRouter()
logger = get_logger(__name__)


class LiveInsightResponse(BaseModel):
    """Response model for a single insight."""
    id: str
    session_id: str
    project_id: str
    organization_id: str
    insight_type: str
    priority: str
    content: str
    context: Optional[str] = None
    assigned_to: Optional[str] = None
    due_date: Optional[str] = None
    confidence_score: Optional[float] = None
    chunk_index: Optional[int] = None
    created_at: str
    metadata: Optional[dict] = None


class LiveInsightsListResponse(BaseModel):
    """Response model for list of insights."""
    insights: List[LiveInsightResponse]
    total: int
    session_id: Optional[str] = None
    project_id: str


@router.get("/api/v1/projects/{project_id}/live-insights", response_model=LiveInsightsListResponse)
async def get_project_live_insights(
    project_id: str,
    session_id: Optional[str] = None,
    insight_type: Optional[str] = None,
    priority: Optional[str] = None,
    limit: int = 100,
    offset: int = 0,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
    _: str = Depends(require_role("member"))
):
    """
    Get live meeting insights for a project.

    Args:
        project_id: UUID of the project
        session_id: Optional filter by session ID
        insight_type: Optional filter by insight type (action_item, decision, question, etc.)
        priority: Optional filter by priority (critical, high, medium, low)
        limit: Maximum number of insights to return (default 100, max 500)
        offset: Number of insights to skip for pagination
        db: Database session
        current_user: Authenticated user

    Returns:
        List of live meeting insights with metadata
    """
    try:
        # Validate project UUID
        try:
            project_uuid = uuid.UUID(project_id)
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid project ID format")

        # Verify project exists and user has access
        result = await db.execute(
            select(Project).where(Project.id == project_uuid)
        )
        project = result.scalar_one_or_none()

        if not project:
            raise HTTPException(status_code=404, detail="Project not found")

        # Verify user is member of project's organization
        org_member_result = await db.execute(
            select(OrganizationMember).where(
                and_(
                    OrganizationMember.user_id == current_user.id,
                    OrganizationMember.organization_id == project.organization_id
                )
            )
        )
        if not org_member_result.scalar_one_or_none():
            raise HTTPException(status_code=403, detail="Not authorized to access this project")

        # Enforce limit constraints
        limit = min(limit, 500)  # Max 500 insights per request

        # Build query
        query = select(LiveMeetingInsight).where(
            LiveMeetingInsight.project_id == project_uuid
        )

        # Apply filters
        if session_id:
            query = query.where(LiveMeetingInsight.session_id == session_id)

        if insight_type:
            query = query.where(LiveMeetingInsight.insight_type == insight_type)

        if priority:
            query = query.where(LiveMeetingInsight.priority == priority)

        # Order by most recent first
        query = query.order_by(LiveMeetingInsight.created_at.desc())

        # Apply pagination
        query = query.limit(limit).offset(offset)

        # Execute query
        result = await db.execute(query)
        insights = result.scalars().all()

        # Get total count for pagination
        count_query = select(LiveMeetingInsight).where(
            LiveMeetingInsight.project_id == project_uuid
        )
        if session_id:
            count_query = count_query.where(LiveMeetingInsight.session_id == session_id)
        if insight_type:
            count_query = count_query.where(LiveMeetingInsight.insight_type == insight_type)
        if priority:
            count_query = count_query.where(LiveMeetingInsight.priority == priority)

        count_result = await db.execute(count_query)
        total = len(count_result.scalars().all())

        # Convert to response format
        insights_response = [
            LiveInsightResponse(
                id=str(insight.id),
                session_id=insight.session_id,
                project_id=str(insight.project_id),
                organization_id=str(insight.organization_id),
                insight_type=insight.insight_type,
                priority=insight.priority,
                content=insight.content,
                context=insight.context,
                assigned_to=insight.assigned_to,
                due_date=insight.due_date,
                confidence_score=insight.confidence_score,
                chunk_index=insight.chunk_index,
                created_at=insight.created_at.isoformat(),
                metadata=insight.insight_metadata
            )
            for insight in insights
        ]

        logger.info(
            f"Retrieved {len(insights_response)} live insights for project {sanitize_for_log(project_id)}"
            f"{f' (session: {sanitize_for_log(session_id)})' if session_id else ''}"
        )

        return LiveInsightsListResponse(
            insights=insights_response,
            total=total,
            session_id=session_id,
            project_id=project_id
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error retrieving live insights for project {sanitize_for_log(project_id)}: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Failed to retrieve insights: {str(e)}")


@router.get("/api/v1/sessions/{session_id}/live-insights", response_model=LiveInsightsListResponse)
async def get_session_live_insights(
    session_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
    _: str = Depends(require_role("member"))
):
    """
    Get all live meeting insights for a specific session.

    Args:
        session_id: Session identifier
        db: Database session
        current_user: Authenticated user

    Returns:
        List of live meeting insights for the session
    """
    try:
        # Get insights for session
        result = await db.execute(
            select(LiveMeetingInsight).where(
                LiveMeetingInsight.session_id == session_id
            ).order_by(LiveMeetingInsight.chunk_index.asc())
        )
        insights = result.scalars().all()

        if not insights:
            raise HTTPException(status_code=404, detail="No insights found for this session")

        # Verify user has access to the project
        first_insight = insights[0]
        org_member_result = await db.execute(
            select(OrganizationMember).where(
                and_(
                    OrganizationMember.user_id == current_user.id,
                    OrganizationMember.organization_id == first_insight.organization_id
                )
            )
        )
        if not org_member_result.scalar_one_or_none():
            raise HTTPException(status_code=403, detail="Not authorized to access this session")

        # Convert to response format
        insights_response = [
            LiveInsightResponse(
                id=str(insight.id),
                session_id=insight.session_id,
                project_id=str(insight.project_id),
                organization_id=str(insight.organization_id),
                insight_type=insight.insight_type,
                priority=insight.priority,
                content=insight.content,
                context=insight.context,
                assigned_to=insight.assigned_to,
                due_date=insight.due_date,
                confidence_score=insight.confidence_score,
                chunk_index=insight.chunk_index,
                created_at=insight.created_at.isoformat(),
                metadata=insight.insight_metadata
            )
            for insight in insights
        ]

        logger.info(f"Retrieved {len(insights_response)} live insights for session {sanitize_for_log(session_id)}")

        return LiveInsightsListResponse(
            insights=insights_response,
            total=len(insights_response),
            session_id=session_id,
            project_id=str(first_insight.project_id)
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error retrieving live insights for session {sanitize_for_log(session_id)}: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Failed to retrieve insights: {str(e)}")
