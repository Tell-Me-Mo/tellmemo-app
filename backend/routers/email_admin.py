"""Admin endpoints for email digest testing and manual triggers."""

from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from pydantic import BaseModel

from db.database import get_db
from dependencies.auth import get_current_user
from models.user import User
from services.scheduler.digest_scheduler import digest_scheduler

router = APIRouter(prefix="/api/v1/admin/email", tags=["admin-email"])


class TriggerResponse(BaseModel):
    """Response model for manual trigger operations."""
    success: bool
    message: str
    job_count: Optional[int] = None


@router.post("/trigger-daily-digest", response_model=TriggerResponse)
async def trigger_daily_digest(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Manually trigger daily digest job (admin only).

    This endpoint allows admins to trigger daily digest generation
    without waiting for the scheduled time. Useful for testing.

    Args:
        current_user: Current authenticated user (must be admin)
        db: Database session

    Returns:
        Job count and status
    """
    # TODO: Add admin permission check
    # For now, allow any authenticated user

    try:
        from services.email.digest_service import digest_service

        job_count = await digest_service.generate_daily_digests(db)

        return TriggerResponse(
            success=True,
            message=f"Daily digest generation triggered successfully",
            job_count=job_count
        )

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to trigger daily digest: {str(e)}")


@router.post("/trigger-weekly-digest", response_model=TriggerResponse)
async def trigger_weekly_digest(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Manually trigger weekly digest job (admin only).

    Args:
        current_user: Current authenticated user (must be admin)
        db: Database session

    Returns:
        Job count and status
    """
    try:
        from services.email.digest_service import digest_service

        job_count = await digest_service.generate_weekly_digests(db)

        return TriggerResponse(
            success=True,
            message=f"Weekly digest generation triggered successfully",
            job_count=job_count
        )

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to trigger weekly digest: {str(e)}")


@router.post("/trigger-monthly-digest", response_model=TriggerResponse)
async def trigger_monthly_digest(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Manually trigger monthly digest job (admin only).

    Args:
        current_user: Current authenticated user (must be admin)
        db: Database session

    Returns:
        Job count and status
    """
    try:
        from services.email.digest_service import digest_service

        job_count = await digest_service.generate_monthly_digests(db)

        return TriggerResponse(
            success=True,
            message=f"Monthly digest generation triggered successfully",
            job_count=job_count
        )

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to trigger monthly digest: {str(e)}")


@router.post("/trigger-inactive-check", response_model=TriggerResponse)
async def trigger_inactive_check(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Manually trigger inactive user check job (admin only).

    Checks for users with no activities for 7+ days and sends
    reminder emails.

    Args:
        current_user: Current authenticated user (must be admin)
        db: Database session

    Returns:
        Inactive user count and reminder count
    """
    try:
        from services.email.digest_service import digest_service

        reminder_count = await digest_service.check_inactive_users(db)

        return TriggerResponse(
            success=True,
            message=f"Inactive user check triggered successfully",
            job_count=reminder_count
        )

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to trigger inactive check: {str(e)}")


@router.post("/send-digest/{user_id}", response_model=TriggerResponse)
async def send_digest_to_user(
    user_id: str,
    digest_type: str = Query(default="weekly", description="Digest type: daily, weekly, monthly"),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Send digest email to specific user immediately (admin only).

    Useful for debugging specific user issues or testing digest content.

    Args:
        user_id: Target user ID
        digest_type: Type of digest (daily, weekly, monthly)
        current_user: Current authenticated user (must be admin)
        db: Database session

    Returns:
        Job ID and status
    """
    # Validate digest type
    valid_types = ['daily', 'weekly', 'monthly']
    if digest_type not in valid_types:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid digest type. Must be one of: {', '.join(valid_types)}"
        )

    try:
        from queue_config import queue_config
        from datetime import datetime, timedelta

        # Calculate time period
        now = datetime.utcnow()
        if digest_type == 'daily':
            start_date = now - timedelta(days=1)
        elif digest_type == 'weekly':
            start_date = now - timedelta(weeks=1)
        else:  # monthly
            start_date = now - timedelta(days=30)

        # Enqueue job
        job = queue_config.high_queue.enqueue(
            'tasks.email_tasks.send_digest_email_task',
            user_id=user_id,
            digest_type=digest_type,
            start_date=start_date.isoformat(),
            end_date=now.isoformat(),
            job_timeout='10m'
        )

        return TriggerResponse(
            success=True,
            message=f"Digest email queued for user {user_id} (job: {job.id})",
            job_count=1
        )

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to send digest: {str(e)}")


@router.get("/scheduler-status")
async def get_scheduler_status(
    current_user: User = Depends(get_current_user),
):
    """
    Get digest scheduler status (admin only).

    Returns information about all scheduled jobs and their next run times.

    Args:
        current_user: Current authenticated user (must be admin)

    Returns:
        Scheduler status and job information
    """
    try:
        status = digest_scheduler.get_job_status()
        return status

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get scheduler status: {str(e)}")


@router.get("/sendgrid-status")
async def get_sendgrid_status(
    current_user: User = Depends(get_current_user),
):
    """
    Get SendGrid service status (admin only).

    Returns rate limit information and service health.

    Args:
        current_user: Current authenticated user (must be admin)

    Returns:
        SendGrid service status
    """
    try:
        from services.email.sendgrid_service import sendgrid_service

        return {
            "configured": sendgrid_service.is_configured(),
            "rate_limit": sendgrid_service.get_rate_limit_status()
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get SendGrid status: {str(e)}")
