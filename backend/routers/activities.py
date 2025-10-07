"""Activity tracking endpoints for the Meeting RAG System."""

from fastapi import APIRouter, Depends, HTTPException, Query
from typing import List, Optional
from datetime import datetime
from uuid import UUID
from sqlalchemy import and_

from db.database import get_db
from sqlalchemy.ext.asyncio import AsyncSession
from dependencies.auth import get_current_organization, get_current_user, require_role
from models.organization import Organization
from models.user import User
from services.activity.activity_service import ActivityService
from models.activity import ActivityType
from utils.logger import get_logger

logger = get_logger(__name__)

router = APIRouter(prefix="/api/v1", tags=["activities"])


@router.get("/projects/{project_id}/activities")
async def get_project_activities(
    project_id: UUID,
    limit: int = Query(50, ge=1, le=100),
    offset: int = Query(0, ge=0),
    activity_type: Optional[str] = None,
    since: Optional[datetime] = None,
    db: AsyncSession = Depends(get_db),
    current_org: Organization = Depends(get_current_organization),
    current_user: User = Depends(get_current_user),
    _: str = Depends(require_role("member"))
):
    """Get activities for a specific project."""
    try:
        # Parse activity type if provided
        parsed_type = None
        if activity_type:
            try:
                parsed_type = ActivityType(activity_type)
            except ValueError:
                raise HTTPException(status_code=400, detail=f"Invalid activity type: {activity_type}")
        
        activities = await ActivityService.get_project_activities(
            db=db,
            project_id=project_id,
            organization_id=current_org.id,
            limit=limit,
            offset=offset,
            activity_type=parsed_type,
            since=since
        )
        
        return [activity.to_dict() for activity in activities]
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error fetching project activities: {e}")
        raise HTTPException(status_code=500, detail="Failed to fetch activities")


@router.get("/activities/recent")
async def get_recent_activities(
    project_ids: str = Query(..., description="Comma-separated list of project IDs"),
    hours: int = Query(24, ge=1, le=168),
    limit: int = Query(20, ge=1, le=50),
    db: AsyncSession = Depends(get_db),
    current_org: Organization = Depends(get_current_organization),
    current_user: User = Depends(get_current_user),
    _: str = Depends(require_role("member"))
):
    """Get recent activities across multiple projects."""
    try:
        # Parse project IDs
        try:
            parsed_ids = [UUID(pid.strip()) for pid in project_ids.split(",")]
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid project ID format")
        
        activities = await ActivityService.get_recent_activities(
            db=db,
            project_ids=parsed_ids,
            organization_id=current_org.id,
            hours=hours,
            limit=limit
        )
        
        return [activity.to_dict() for activity in activities]
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error fetching recent activities: {e}")
        raise HTTPException(status_code=500, detail="Failed to fetch recent activities")


@router.delete("/projects/{project_id}/activities")
async def delete_project_activities(
    project_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_org: Organization = Depends(get_current_organization),
    current_user: User = Depends(get_current_user),
    _: str = Depends(require_role("admin"))
):
    """Delete all activities for a project (admin only)."""
    try:
        count = await ActivityService.delete_project_activities(
            db=db,
            project_id=project_id,
            organization_id=current_org.id
        )
        
        return {"message": f"Deleted {count} activities", "count": count}
        
    except Exception as e:
        logger.error(f"Error deleting project activities: {e}")
        raise HTTPException(status_code=500, detail="Failed to delete activities")