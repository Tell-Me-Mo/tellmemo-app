"""API endpoints for email digest preferences."""

from typing import List, Optional, Dict, Any
from enum import Enum
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update
from pydantic import BaseModel, Field
from datetime import datetime
import jwt
from jwt.exceptions import InvalidTokenError

from db.database import get_db
from dependencies.auth import get_current_user
from models.user import User
from config import get_settings

settings = get_settings()

# Enums for validation


class DigestType(str, Enum):
    """Valid digest types."""
    daily = "daily"
    weekly = "weekly"
    monthly = "monthly"


class DigestFrequency(str, Enum):
    """Valid digest frequencies."""
    daily = "daily"
    weekly = "weekly"
    monthly = "monthly"
    never = "never"


class ContentType(str, Enum):
    """Valid content types for digest."""
    blockers = "blockers"
    activities = "activities"
    tasks_assigned = "tasks_assigned"
    risks_critical = "risks_critical"
    decisions = "decisions"


# Pydantic models for request/response


class EmailDigestPreferences(BaseModel):
    """Model for email digest preferences."""
    enabled: bool = Field(default=True, description="Enable/disable email digests")
    frequency: DigestFrequency = Field(default=DigestFrequency.weekly, description="Digest frequency: daily, weekly, monthly, never")
    content_types: List[ContentType] = Field(
        default=[ContentType.blockers, ContentType.tasks_assigned, ContentType.risks_critical],
        description="Content to include in digest"
    )
    project_filter: str = Field(default="all", description="Project filter: all or specific project IDs")
    include_portfolio_rollup: bool = Field(default=True, description="Include portfolio-level summaries")
    last_sent_at: Optional[datetime] = Field(default=None, description="Last digest send timestamp")

    class Config:
        use_enum_values = True  # Automatically convert enums to their values when serializing


class EmailPreferencesResponse(BaseModel):
    """Model for email preferences response."""
    email_digest: EmailDigestPreferences

    class Config:
        from_attributes = True


class DigestPreviewResponse(BaseModel):
    """Model for digest preview response."""
    html_preview: str
    text_preview: Optional[str] = None
    digest_data: Dict[str, Any]


# Create router
router = APIRouter(prefix="/api/v1/email-preferences", tags=["email-preferences"])


@router.get("/digest", response_model=EmailDigestPreferences)
async def get_digest_preferences(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Get user's email digest preferences.

    Args:
        current_user: Current authenticated user
        db: Database session

    Returns:
        User's email digest preferences
    """
    # Get user preferences from database
    result = await db.execute(
        select(User).where(User.id == current_user.id)
    )
    user = result.scalar_one_or_none()

    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    # Extract email_digest preferences or use defaults
    preferences = user.preferences or {}
    email_digest = preferences.get('email_digest', {
        'enabled': True,
        'frequency': 'weekly',
        'content_types': ['blockers', 'tasks_assigned', 'risks_critical'],
        'project_filter': 'all',
        'include_portfolio_rollup': True,
        'last_sent_at': None
    })

    return EmailDigestPreferences(**email_digest)


@router.put("/digest", response_model=EmailDigestPreferences)
async def update_digest_preferences(
    preferences: EmailDigestPreferences,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Update user's email digest preferences.

    Args:
        preferences: New digest preferences
        current_user: Current authenticated user
        db: Database session

    Returns:
        Updated email digest preferences
    """
    # Validation happens in Pydantic model via Field validators
    # (frequency and content_types are validated when EmailDigestPreferences is instantiated)

    # Get current preferences
    result = await db.execute(
        select(User).where(User.id == current_user.id)
    )
    user = result.scalar_one_or_none()

    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    # Update preferences
    current_preferences = user.preferences or {}
    current_preferences['email_digest'] = preferences.model_dump(mode='json')

    # Save to database
    await db.execute(
        update(User)
        .where(User.id == current_user.id)
        .values(preferences=current_preferences)
    )
    await db.commit()

    return preferences


@router.post("/digest/preview", response_model=DigestPreviewResponse)
async def preview_digest(
    digest_type: DigestType = Query(default=DigestType.weekly, description="Digest type: daily, weekly, monthly"),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Generate a preview of the digest email without sending.

    Args:
        digest_type: Type of digest to preview (daily, weekly, monthly)
        current_user: Current authenticated user
        db: Database session

    Returns:
        Preview of HTML and text email content
    """
    # Validation is automatic via Enum

    # Import services
    from services.email.digest_service import digest_service
    from services.email.template_service import template_service

    # Calculate time period based on digest type
    from datetime import timedelta
    now = datetime.utcnow()
    if digest_type == DigestType.daily:
        start_date = now - timedelta(days=1)
        period_text = "Last 24 hours"
    elif digest_type == DigestType.weekly:
        start_date = now - timedelta(weeks=1)
        period_text = "Last 7 days"
    else:  # monthly
        start_date = now - timedelta(days=30)
        period_text = "Last 30 days"

    # Aggregate digest data
    digest_data = await digest_service.aggregate_digest_data(
        user_id=str(current_user.id),
        start_date=start_date,
        end_date=now,
        db=db
    )

    # Prepare template context
    context = {
        'user_name': current_user.name or current_user.email.split('@')[0],
        'digest_type': digest_type.value,
        'digest_period': period_text,
        'summary_stats': digest_data.get('summary_stats', {}),
        'projects': digest_data.get('projects', []),
        'dashboard_url': f"{settings.frontend_url}/dashboard",
        'frontend_url': settings.frontend_url,
        'unsubscribe_url': '#',  # Placeholder for preview
        'current_year': now.year
    }

    # Render templates
    html_content = template_service.render_digest_email(context)
    text_content = template_service.render_digest_email_text(context)

    return DigestPreviewResponse(
        html_preview=html_content,
        text_preview=text_content,
        digest_data=digest_data
    )


@router.post("/digest/send-test")
async def send_test_digest(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Send ALL test emails to the current user immediately.

    This will send:
    - Daily digest
    - Weekly digest
    - Monthly digest
    - Onboarding welcome email
    - Inactive reminder email

    Args:
        current_user: Current authenticated user
        db: Database session

    Returns:
        Job IDs and status for all queued emails
    """
    from queue_config import queue_config
    from datetime import timedelta

    now = datetime.utcnow()
    jobs = []

    # 1. Daily digest (last 24 hours)
    daily_start = now - timedelta(days=1)
    daily_job = queue_config.high_queue.enqueue(
        'tasks.email_tasks.send_digest_email_task',
        user_id=str(current_user.id),
        digest_type='daily',
        start_date=daily_start.isoformat(),
        end_date=now.isoformat(),
        job_timeout='5m'
    )
    jobs.append({
        "email_type": "daily_digest",
        "job_id": daily_job.id,
        "status": daily_job.get_status()
    })

    # 2. Weekly digest (last 7 days)
    weekly_start = now - timedelta(weeks=1)
    weekly_job = queue_config.high_queue.enqueue(
        'tasks.email_tasks.send_digest_email_task',
        user_id=str(current_user.id),
        digest_type='weekly',
        start_date=weekly_start.isoformat(),
        end_date=now.isoformat(),
        job_timeout='5m'
    )
    jobs.append({
        "email_type": "weekly_digest",
        "job_id": weekly_job.id,
        "status": weekly_job.get_status()
    })

    # 3. Monthly digest (last 30 days)
    monthly_start = now - timedelta(days=30)
    monthly_job = queue_config.high_queue.enqueue(
        'tasks.email_tasks.send_digest_email_task',
        user_id=str(current_user.id),
        digest_type='monthly',
        start_date=monthly_start.isoformat(),
        end_date=now.isoformat(),
        job_timeout='5m'
    )
    jobs.append({
        "email_type": "monthly_digest",
        "job_id": monthly_job.id,
        "status": monthly_job.get_status()
    })

    # 4. Onboarding welcome email
    onboarding_job = queue_config.high_queue.enqueue(
        'tasks.email_tasks.send_onboarding_email_task',
        user_id=str(current_user.id),
        job_timeout='5m'
    )
    jobs.append({
        "email_type": "onboarding_welcome",
        "job_id": onboarding_job.id,
        "status": onboarding_job.get_status()
    })

    # 5. Inactive user reminder email
    inactive_job = queue_config.high_queue.enqueue(
        'tasks.email_tasks.send_inactive_reminder_task',
        user_id=str(current_user.id),
        job_timeout='5m'
    )
    jobs.append({
        "email_type": "inactive_reminder",
        "job_id": inactive_job.id,
        "status": inactive_job.get_status()
    })

    return {
        "success": True,
        "message": f"All {len(jobs)} test emails queued for sending",
        "total_emails": len(jobs),
        "jobs": jobs
    }


@router.get("/unsubscribe")
async def unsubscribe_from_digest(
    token: str = Query(..., description="Unsubscribe JWT token"),
    db: AsyncSession = Depends(get_db),
):
    """
    Unsubscribe user from email digests using signed JWT token.

    Args:
        token: Signed JWT token containing user_id
        db: Database session

    Returns:
        Success message
    """
    try:
        # Decode JWT token
        payload = jwt.decode(
            token,
            settings.jwt_secret,
            algorithms=["HS256"]
        )

        user_id = payload.get('user_id')
        purpose = payload.get('purpose')

        # Validate token purpose
        if purpose != 'unsubscribe':
            raise HTTPException(status_code=400, detail="Invalid token purpose")

        if not user_id:
            raise HTTPException(status_code=400, detail="Invalid token: missing user_id")

        # Get user
        result = await db.execute(
            select(User).where(User.id == user_id)
        )
        user = result.scalar_one_or_none()

        if not user:
            raise HTTPException(status_code=404, detail="User not found")

        # Disable email digest
        current_preferences = user.preferences or {}
        if 'email_digest' not in current_preferences:
            current_preferences['email_digest'] = {}

        current_preferences['email_digest']['enabled'] = False

        # Save to database
        await db.execute(
            update(User)
            .where(User.id == user_id)
            .values(preferences=current_preferences)
        )
        await db.commit()

        return {
            "success": True,
            "message": "You have been successfully unsubscribed from email digests. You can re-enable them anytime in your settings."
        }

    except InvalidTokenError as e:
        raise HTTPException(status_code=400, detail=f"Invalid token: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to unsubscribe: {str(e)}")
