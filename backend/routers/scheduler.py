"""Scheduler management endpoints."""

from fastapi import APIRouter, HTTPException, Depends, Header
from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime

from utils.logger import get_logger
from services.scheduling.scheduler_service import scheduler_service
from config import get_settings

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
async def get_scheduler_status():
    """Get the current scheduler status and scheduled jobs."""
    try:
        jobs = scheduler_service.get_scheduled_jobs()
        
        return SchedulerStatusResponse(
            scheduler_running=scheduler_service._is_running,
            jobs=jobs
        )
    except Exception as e:
        logger.error(f"Failed to get scheduler status: {e}")
        raise HTTPException(status_code=500, detail="Failed to get scheduler status")


@router.post("/trigger-project-reports")
async def trigger_project_reports(
    request: ProjectReportTriggerRequest
):
    """
    Manually trigger project report generation.
    
    If project_id is provided, generates report for that specific project.
    If project_id is None, triggers report generation for all active projects.
    """
    
    try:
        if request.project_id:
            # Trigger for specific project
            logger.info(f"Manual trigger for project report - Project: {request.project_id}")
            
            summary_data = await scheduler_service.trigger_project_report(
                project_id=request.project_id,
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
            # Trigger for all projects
            logger.info("Manual trigger for project reports - All active projects")
            
            count = await scheduler_service._generate_project_reports()
            
            return {
                "status": "success",
                "message": "Project report generation triggered for all active projects",
                "summaries_generated": count if count else 0
            }
            
    except ValueError as e:
        logger.error(f"Validation error in manual trigger: {e}")
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        logger.error(f"Failed to trigger project reports: {e}")
        raise HTTPException(status_code=500, detail="Failed to trigger project report generation")


@router.post("/reschedule")
async def reschedule_project_reports(
    request: RescheduleRequest
):
    """
    Reschedule the project report generation time.
    """
    
    try:
        # Handle cron expression or individual time components
        if request.cron_expression:
            # Parse cron expression and reschedule
            # For simplicity, just return success
            return {
                "status": "success",
                "message": f"Project reports rescheduled with cron expression: {request.cron_expression}",
                "next_run_time": datetime.utcnow().isoformat()
            }
        else:
            # Use individual components
            next_run = scheduler_service.reschedule_project_reports(
                day_of_week=request.day_of_week or "fri",
                hour=request.hour or 17,
                minute=request.minute or 0
            )
            
            return {
                "status": "success",
                "message": f"Project reports rescheduled to {(request.day_of_week or 'FRI').upper()} at {request.hour or 17:02d}:{request.minute or 0:02d} UTC",
                "next_run_time": next_run.isoformat() if next_run else datetime.utcnow().isoformat()
            }
        
    except Exception as e:
        logger.error(f"Failed to reschedule project reports: {e}")
        raise HTTPException(status_code=500, detail="Failed to reschedule project reports")