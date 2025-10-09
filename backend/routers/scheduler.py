"""Scheduler management endpoints."""

from fastapi import APIRouter, HTTPException, Depends, Header
from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime
from uuid import UUID
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from utils.logger import get_logger, sanitize_for_log
from services.scheduling.scheduler_service import scheduler_service
from config import get_settings
from models.user import User
from models.organization import Organization
from dependencies.auth import get_current_user, get_current_organization, require_role
from db.database import get_db

router = APIRouter()
logger = get_logger(__name__)
settings = get_settings()


class SchedulerStatusResponse(BaseModel):
    """Response model for scheduler status."""
    scheduler_running: bool
    jobs: List[dict]


class ProjectReportTriggerRequest(BaseModel):
    """Request model for triggering project reports."""
    project_id: Optional[str] = Field(None, description="Specific project ID or None for all projects")
    date_range_start: Optional[datetime] = Field(None, description="Start date for report")
    date_range_end: Optional[datetime] = Field(None, description="End date for report")


class RescheduleRequest(BaseModel):
    """Request model for rescheduling project reports."""
    cron_expression: Optional[str] = Field(None, description="Cron expression for scheduling")
    day_of_week: Optional[str] = Field(None, description="Day of week (mon, tue, wed, thu, fri, sat, sun)")
    hour: Optional[int] = Field(None, ge=0, le=23, description="Hour (0-23)")
    minute: Optional[int] = Field(None, ge=0, le=59, description="Minute (0-59)")
    timezone: Optional[str] = Field("UTC", description="Timezone for the schedule")


@router.get("/status", response_model=SchedulerStatusResponse)
async def get_scheduler_status(
    current_user: User = Depends(get_current_user),
    current_org: Organization = Depends(get_current_organization),
):
    """
    Get the current scheduler status and scheduled jobs.

    Note: Automated scheduling has been moved to Redis Queue (RQ).
    This endpoint returns empty for backward compatibility.
    """
    return SchedulerStatusResponse(
        scheduler_running=False,
        jobs=[]
    )


@router.post("/trigger-project-reports")
async def trigger_project_reports(
    request: ProjectReportTriggerRequest,
    current_user: User = Depends(get_current_user),
    current_org: Organization = Depends(get_current_organization),
    db: AsyncSession = Depends(get_db)
):
    """
    Manually trigger project report generation.

    If project_id is provided, generates report for that specific project.
    If project_id is None, triggers report generation for all active projects.
    """

    try:
        if request.project_id:
            # Trigger for specific project
            logger.info(f"Manual trigger for project report - Project: {sanitize_for_log(request.project_id)}")

            # Validate UUID format
            try:
                project_uuid = UUID(request.project_id)
            except (ValueError, AttributeError):
                raise HTTPException(status_code=422, detail="Invalid project ID format")

            # Validate project belongs to user's organization
            from models.project import Project

            result = await db.execute(
                select(Project).where(Project.id == project_uuid)
            )
            project = result.scalar_one_or_none()

            if not project:
                raise HTTPException(status_code=404, detail="Project not found")

            if project.organization_id != current_org.id:
                # Return 404 to prevent information disclosure
                raise HTTPException(status_code=404, detail="Project not found")

            # Use correct method name
            summary_data = await scheduler_service.trigger_weekly_report(
                project_id=str(project_uuid),
                date_range_start=request.date_range_start,
                date_range_end=request.date_range_end
            )

            return {
                "status": "success",
                "message": f"Project report generated for project {request.project_id}",
                "summary_id": summary_data.get("summary_id"),
                "summaries_generated": 1
            }
        else:
            # Trigger for all projects in user's organization
            logger.info(f"Manual trigger for project reports - All active projects in organization {current_org.id}")

            # Get all active projects in organization
            from models.project import Project, ProjectStatus

            result = await db.execute(
                select(Project).where(
                    Project.organization_id == current_org.id,
                    Project.status == ProjectStatus.ACTIVE
                )
            )
            projects = result.scalars().all()

            if not projects:
                return {
                    "status": "success",
                    "message": "No active projects found in organization",
                    "summaries_generated": 0
                }

            # Generate reports for each project
            count = 0
            errors = []
            for project in projects:
                try:
                    await scheduler_service.trigger_weekly_report(
                        project_id=str(project.id),
                        date_range_start=request.date_range_start,
                        date_range_end=request.date_range_end
                    )
                    count += 1
                except Exception as e:
                    logger.error(f"Failed to generate report for project {project.id}: {e}")
                    errors.append(str(project.id))

            message = f"Project reports generated for {count} projects"
            if errors:
                message += f" ({len(errors)} failed)"

            return {
                "status": "success" if count > 0 else "partial_failure",
                "message": message,
                "summaries_generated": count
            }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to trigger project reports: {e}")
        raise HTTPException(status_code=500, detail="Failed to trigger project report generation")


@router.post("/reschedule")
async def reschedule_project_reports(
    request: RescheduleRequest,
    current_user: User = Depends(get_current_user),
    current_org: Organization = Depends(get_current_organization),
    _: None = Depends(require_role("admin")),
):
    """
    Reschedule the project report generation time.

    Note: Automated scheduling has been moved to Redis Queue (RQ).
    This endpoint is deprecated and returns a 501 Not Implemented status.

    Requires admin role.
    """
    raise HTTPException(
        status_code=501,
        detail="Automated scheduling has been moved to Redis Queue. Use manual triggers via /trigger-project-reports instead."
    )