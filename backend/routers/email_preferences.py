"""API endpoints for email digest preferences."""

from typing import List, Optional, Dict, Any
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

# Pydantic models for request/response


class EmailDigestPreferences(BaseModel):
    """Model for email digest preferences."""
    enabled: bool = Field(default=False, description="Enable/disable email digests")
    frequency: str = Field(default="weekly", description="Digest frequency: daily, weekly, monthly, never")
    content_types: List[str] = Field(
        default=["summaries", "tasks_assigned", "risks_critical"],
        description="Content to include in digest"
    )
    project_filter: str = Field(default="all", description="Project filter: all or specific project IDs")
    include_portfolio_rollup: bool = Field(default=True, description="Include portfolio-level summaries")
    last_sent_at: Optional[datetime] = Field(default=None, description="Last digest send timestamp")


class EmailPreferencesResponse(BaseModel):
    """Model for email preferences response."""
    email_digest: EmailDigestPreferences

    class Config:
        from_attributes = True


class DigestPreviewResponse(BaseModel):
    """Model for digest preview response."""
    html_content: str
    text_content: str
    digest_data: Dict[str, Any]


# Create router
router = APIRouter(prefix="/api/v1/email-preferences", tags=["email-preferences"])


@router.get("/digest", response_model=EmailPreferencesResponse)
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
        'enabled': False,
        'frequency': 'weekly',
        'content_types': ['summaries', 'tasks_assigned', 'risks_critical'],
        'project_filter': 'all',
        'include_portfolio_rollup': True,
        'last_sent_at': None
    })

    return EmailPreferencesResponse(
        email_digest=EmailDigestPreferences(**email_digest)
    )


@router.put("/digest", response_model=EmailPreferencesResponse)
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
    # Validate frequency
    valid_frequencies = ['daily', 'weekly', 'monthly', 'never']
    if preferences.frequency not in valid_frequencies:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid frequency. Must be one of: {', '.join(valid_frequencies)}"
        )

    # Validate content types
    valid_content_types = ['summaries', 'activities', 'tasks_assigned', 'risks_critical', 'decisions']
    for content_type in preferences.content_types:
        if content_type not in valid_content_types:
            raise HTTPException(
                status_code=400,
                detail=f"Invalid content type '{content_type}'. Must be one of: {', '.join(valid_content_types)}"
            )

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

    return EmailPreferencesResponse(email_digest=preferences)


@router.post("/digest/preview", response_model=DigestPreviewResponse)
async def preview_digest(
    digest_type: str = Query(default="weekly", description="Digest type: daily, weekly, monthly"),
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
    # Validate digest type
    valid_types = ['daily', 'weekly', 'monthly']
    if digest_type not in valid_types:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid digest type. Must be one of: {', '.join(valid_types)}"
        )

    # Import services
    from services.email.digest_service import digest_service
    from services.email.template_service import template_service

    # Calculate time period based on digest type
    from datetime import timedelta
    now = datetime.utcnow()
    if digest_type == 'daily':
        start_date = now - timedelta(days=1)
        period_text = "Last 24 hours"
    elif digest_type == 'weekly':
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
        'digest_type': digest_type,
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
        html_content=html_content,
        text_content=text_content,
        digest_data=digest_data
    )


@router.post("/digest/send-test")
async def send_test_digest(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Send a test digest email to the current user immediately.

    Args:
        current_user: Current authenticated user
        db: Database session

    Returns:
        Job ID and status
    """
    from queue_config import queue_config
    from datetime import timedelta

    # Calculate time period (last 7 days for test)
    now = datetime.utcnow()
    start_date = now - timedelta(weeks=1)

    # Enqueue test digest email job
    job = queue_config.high_queue.enqueue(
        'tasks.email_tasks.send_digest_email_task',
        user_id=str(current_user.id),
        digest_type='weekly',
        start_date=start_date.isoformat(),
        end_date=now.isoformat(),
        job_timeout='5m'
    )

    return {
        "success": True,
        "message": "Test digest email queued for sending",
        "job_id": job.id,
        "status": job.get_status()
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
