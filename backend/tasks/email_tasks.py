"""
RQ Tasks for Email Processing

This module contains RQ tasks for sending emails:
- Digest emails (daily/weekly/monthly)
- Onboarding welcome emails
- Inactive user reminder emails
"""

import asyncio
import logging
import uuid
from typing import Optional
from datetime import datetime, timedelta
from rq import get_current_job

from services.email.sendgrid_service import sendgrid_service
from services.email.template_service import template_service
from services.email.digest_service import digest_service
from models.notification import NotificationCategory
from queue_config import queue_config
from config import get_settings
import jwt

logger = logging.getLogger(__name__)
settings = get_settings()


def send_digest_email_task(
    user_id: str,
    digest_type: str,
    start_date: str,
    end_date: str
):
    """
    RQ Task: Send digest email to a user.

    Args:
        user_id: User UUID (as string)
        digest_type: Type of digest (daily, weekly, monthly)
        start_date: Start date ISO string
        end_date: End date ISO string
    """
    rq_job = get_current_job()

    try:
        # Update job metadata
        if rq_job:
            rq_job.meta['status'] = 'processing'
            rq_job.meta['progress'] = 0.0
            rq_job.meta['step'] = f'Generating {digest_type} digest'
            rq_job.save_meta()

        # Run async email sending
        result = asyncio.run(
            _send_digest_email_async(
                user_id=user_id,
                digest_type=digest_type,
                start_date=datetime.fromisoformat(start_date),
                end_date=datetime.fromisoformat(end_date),
                rq_job=rq_job
            )
        )

        # Update job metadata on success
        if rq_job:
            rq_job.meta['status'] = 'completed'
            rq_job.meta['progress'] = 100.0
            rq_job.meta['step'] = 'Email sent successfully'
            rq_job.meta['result'] = result
            rq_job.save_meta()

        logger.info(f"Digest email sent successfully to user {user_id}")
        return result

    except Exception as e:
        error_msg = f"Failed to send digest email: {str(e)}"
        logger.error(f"Digest email task error: {error_msg}", exc_info=True)

        if rq_job:
            rq_job.meta['status'] = 'failed'
            rq_job.meta['error'] = error_msg
            rq_job.save_meta()

        raise


async def _send_digest_email_async(
    user_id: str,
    digest_type: str,
    start_date: datetime,
    end_date: datetime,
    rq_job
) -> dict:
    """
    Async implementation of digest email sending.

    Steps:
    1. Fetch user from database
    2. Aggregate digest data
    3. Render email templates
    4. Send via SendGrid
    5. Create notification record
    6. Update user preferences with last_sent_at
    """
    from db.database import get_db_context
    from models.user import User
    from models.notification import Notification, NotificationType, NotificationPriority
    from sqlalchemy import select, update

    async with get_db_context() as session:
        try:
            # 1. Fetch user
            if rq_job:
                rq_job.meta['progress'] = 10.0
                rq_job.meta['step'] = 'Fetching user data'
                rq_job.save_meta()

            result = await session.execute(
                select(User).where(User.id == uuid.UUID(user_id))
            )
            user = result.scalar_one_or_none()

            if not user:
                raise ValueError(f"User {user_id} not found")

            # 2. Aggregate digest data
            if rq_job:
                rq_job.meta['progress'] = 30.0
                rq_job.meta['step'] = 'Aggregating digest data'
                rq_job.save_meta()

            digest_data = await digest_service.aggregate_digest_data(
                user_id=user_id,
                start_date=start_date,
                end_date=end_date,
                db=session
            )

            # Check if digest has content
            if not digest_service._has_digest_content(digest_data):
                logger.info(f"Skipping empty digest for user {user_id}")
                return {"status": "skipped", "reason": "empty_digest"}

            # 3. Render email templates
            if rq_job:
                rq_job.meta['progress'] = 50.0
                rq_job.meta['step'] = 'Rendering email templates'
                rq_job.save_meta()

            # Generate unsubscribe token
            unsubscribe_token = jwt.encode(
                {
                    'user_id': user_id,
                    'purpose': 'unsubscribe',
                    'exp': int((datetime.utcnow() + timedelta(days=90)).timestamp())  # 90 days
                },
                settings.jwt_secret,
                algorithm='HS256'
            )

            # Calculate period text
            if digest_type == 'daily':
                period_text = "Last 24 hours"
            elif digest_type == 'weekly':
                period_text = "Last 7 days"
            else:
                period_text = "Last 30 days"

            # Prepare template context
            context = {
                'user_name': user.name or user.email.split('@')[0],
                'digest_type': digest_type,
                'digest_period': period_text,
                'summary_stats': digest_data.get('summary_stats', {}),
                'projects': digest_data.get('projects', []),
                'dashboard_url': f"{settings.frontend_url}/dashboard",
                'frontend_url': settings.frontend_url,
                'unsubscribe_url': f"{settings.frontend_url}/api/v1/email-preferences/unsubscribe?token={unsubscribe_token}",
                'current_year': datetime.utcnow().year
            }

            html_content = template_service.render_digest_email(context)
            text_content = template_service.render_digest_email_text(context)

            # 4. Send via SendGrid
            if rq_job:
                rq_job.meta['progress'] = 70.0
                rq_job.meta['step'] = 'Sending email'
                rq_job.save_meta()

            # Generate subject line
            if digest_type == 'daily':
                subject = f"Your Daily TellMeMo Digest - {datetime.utcnow().strftime('%b %d, %Y')}"
            elif digest_type == 'weekly':
                subject = f"Weekly Summary - {start_date.strftime('%b %d')} to {end_date.strftime('%b %d, %Y')}"
            else:
                subject = f"Monthly Summary - {datetime.utcnow().strftime('%B %Y')}"

            send_result = sendgrid_service.send_email(
                to_email=user.email,
                subject=subject,
                html_content=html_content,
                text_content=text_content,
                custom_args={
                    'digest_type': digest_type,
                    'user_id': user_id
                }
            )

            if not send_result['success']:
                raise Exception(f"SendGrid error: {send_result.get('error')}")

            # 5. Create notification record
            if rq_job:
                rq_job.meta['progress'] = 85.0
                rq_job.meta['step'] = 'Creating notification record'
                rq_job.save_meta()

            notification = Notification(
                user_id=user.id,
                organization_id=None,  # Digest emails are not org-specific
                title=f"{digest_type.title()} Digest Sent",
                message=f"Your {digest_type} digest email was sent successfully",
                type=NotificationType.INFO,
                priority=NotificationPriority.LOW,
                category=NotificationCategory.EMAIL_DIGEST_SENT,
                delivered_channels=['email'],
                email_sent_at=datetime.utcnow()
            )
            session.add(notification)

            # 6. Update user preferences with last_sent_at
            if rq_job:
                rq_job.meta['progress'] = 95.0
                rq_job.meta['step'] = 'Updating user preferences'
                rq_job.save_meta()

            preferences = user.preferences or {}
            if 'email_digest' not in preferences:
                preferences['email_digest'] = {}

            preferences['email_digest']['last_sent_at'] = datetime.utcnow().isoformat()

            await session.execute(
                update(User)
                .where(User.id == user.id)
                .values(preferences=preferences)
            )

            await session.commit()

            logger.info(f"✅ Digest email sent to {user.email}")

            return {
                'status': 'success',
                'user_id': user_id,
                'digest_type': digest_type,
                'message_id': send_result.get('message_id'),
                'email': user.email
            }

        except Exception as e:
            logger.error(f"Failed to send digest email to {user_id}: {e}", exc_info=True)
            await session.rollback()
            raise


def send_onboarding_email_task(user_id: str):
    """
    RQ Task: Send onboarding welcome email to a new user.

    Args:
        user_id: User UUID (as string)
    """
    rq_job = get_current_job()

    try:
        if rq_job:
            rq_job.meta['status'] = 'processing'
            rq_job.meta['progress'] = 0.0
            rq_job.meta['step'] = 'Sending onboarding email'
            rq_job.save_meta()

        result = asyncio.run(
            _send_onboarding_email_async(user_id=user_id, rq_job=rq_job)
        )

        if rq_job:
            rq_job.meta['status'] = 'completed'
            rq_job.meta['progress'] = 100.0
            rq_job.meta['step'] = 'Onboarding email sent'
            rq_job.meta['result'] = result
            rq_job.save_meta()

        logger.info(f"Onboarding email sent to user {user_id}")
        return result

    except Exception as e:
        error_msg = f"Failed to send onboarding email: {str(e)}"
        logger.error(f"Onboarding email task error: {error_msg}", exc_info=True)

        if rq_job:
            rq_job.meta['status'] = 'failed'
            rq_job.meta['error'] = error_msg
            rq_job.save_meta()

        raise


async def _send_onboarding_email_async(user_id: str, rq_job) -> dict:
    """Async implementation of onboarding email sending."""
    from db.database import get_db_context
    from models.user import User
    from models.notification import Notification, NotificationType, NotificationPriority
    from sqlalchemy import select

    async with get_db_context() as session:
        try:
            # Fetch user
            result = await session.execute(
                select(User).where(User.id == uuid.UUID(user_id))
            )
            user = result.scalar_one_or_none()

            if not user:
                raise ValueError(f"User {user_id} not found")

            # Generate unsubscribe token
            unsubscribe_token = jwt.encode(
                {
                    'user_id': user_id,
                    'purpose': 'unsubscribe',
                    'exp': int((datetime.utcnow() + timedelta(days=90)).timestamp())
                },
                settings.jwt_secret,
                algorithm='HS256'
            )

            # Prepare context
            context = {
                'user_name': user.name or user.email.split('@')[0],
                'dashboard_url': f"{settings.frontend_url}/dashboard",
                'frontend_url': settings.frontend_url,
                'unsubscribe_url': f"{settings.frontend_url}/api/v1/email-preferences/unsubscribe?token={unsubscribe_token}",
                'current_year': datetime.utcnow().year
            }

            # Render templates
            html_content = template_service.render_onboarding_email(context)
            text_content = template_service.render_onboarding_email_text(context)

            # Send email
            send_result = sendgrid_service.send_email(
                to_email=user.email,
                subject="Welcome to TellMeMo!",
                html_content=html_content,
                text_content=text_content,
                custom_args={'email_type': 'onboarding', 'user_id': user_id}
            )

            if not send_result['success']:
                raise Exception(f"SendGrid error: {send_result.get('error')}")

            # Create notification
            notification = Notification(
                user_id=user.id,
                organization_id=None,
                title="Welcome Email Sent",
                message="Your onboarding email was sent successfully",
                type=NotificationType.INFO,
                priority=NotificationPriority.LOW,
                category=NotificationCategory.EMAIL_ONBOARDING_SENT,
                delivered_channels=['email'],
                email_sent_at=datetime.utcnow()
            )
            session.add(notification)
            await session.commit()

            logger.info(f"✅ Onboarding email sent to {user.email}")

            return {
                'status': 'success',
                'user_id': user_id,
                'message_id': send_result.get('message_id'),
                'email': user.email
            }

        except Exception as e:
            logger.error(f"Failed to send onboarding email: {e}", exc_info=True)
            await session.rollback()
            raise


def send_inactive_reminder_task(user_id: str):
    """
    RQ Task: Send inactive user reminder email.

    Args:
        user_id: User UUID (as string)
    """
    rq_job = get_current_job()

    try:
        if rq_job:
            rq_job.meta['status'] = 'processing'
            rq_job.meta['progress'] = 0.0
            rq_job.meta['step'] = 'Sending inactive reminder'
            rq_job.save_meta()

        result = asyncio.run(
            _send_inactive_reminder_async(user_id=user_id, rq_job=rq_job)
        )

        if rq_job:
            rq_job.meta['status'] = 'completed'
            rq_job.meta['progress'] = 100.0
            rq_job.meta['step'] = 'Inactive reminder sent'
            rq_job.meta['result'] = result
            rq_job.save_meta()

        logger.info(f"Inactive reminder sent to user {user_id}")
        return result

    except Exception as e:
        error_msg = f"Failed to send inactive reminder: {str(e)}"
        logger.error(f"Inactive reminder task error: {error_msg}", exc_info=True)

        if rq_job:
            rq_job.meta['status'] = 'failed'
            rq_job.meta['error'] = error_msg
            rq_job.save_meta()

        raise


async def _send_inactive_reminder_async(user_id: str, rq_job) -> dict:
    """Async implementation of inactive reminder email sending."""
    from db.database import get_db_context
    from models.user import User
    from models.notification import Notification, NotificationType, NotificationPriority
    from sqlalchemy import select

    async with get_db_context() as session:
        try:
            # Fetch user
            result = await session.execute(
                select(User).where(User.id == uuid.UUID(user_id))
            )
            user = result.scalar_one_or_none()

            if not user:
                raise ValueError(f"User {user_id} not found")

            # Generate unsubscribe token
            unsubscribe_token = jwt.encode(
                {
                    'user_id': user_id,
                    'purpose': 'unsubscribe',
                    'exp': int((datetime.utcnow() + timedelta(days=90)).timestamp())
                },
                settings.jwt_secret,
                algorithm='HS256'
            )

            # Prepare context
            context = {
                'user_name': user.name or user.email.split('@')[0],
                'dashboard_url': 'https://app.tellmemo.io/#/dashboard',
                'frontend_url': settings.frontend_url,
                'unsubscribe_url': f"{settings.frontend_url}/api/v1/email-preferences/unsubscribe?token={unsubscribe_token}",
                'current_year': datetime.utcnow().year
            }

            # Render templates
            html_content = template_service.render_inactive_reminder_email(context)
            text_content = template_service.render_inactive_reminder_email_text(context)

            # Send email
            send_result = sendgrid_service.send_email(
                to_email=user.email,
                subject="Ready to get started with TellMeMo?",
                html_content=html_content,
                text_content=text_content,
                custom_args={'email_type': 'inactive_reminder', 'user_id': user_id}
            )

            if not send_result['success']:
                raise Exception(f"SendGrid error: {send_result.get('error')}")

            # Create notification
            notification = Notification(
                user_id=user.id,
                organization_id=None,
                title="Inactive Reminder Sent",
                message="Inactive user reminder email was sent",
                type=NotificationType.INFO,
                priority=NotificationPriority.LOW,
                category=NotificationCategory.EMAIL_INACTIVE_REMINDER_SENT,
                delivered_channels=['email'],
                email_sent_at=datetime.utcnow()
            )
            session.add(notification)
            await session.commit()

            logger.info(f"✅ Inactive reminder sent to {user.email}")

            return {
                'status': 'success',
                'user_id': user_id,
                'message_id': send_result.get('message_id'),
                'email': user.email
            }

        except Exception as e:
            logger.error(f"Failed to send inactive reminder: {e}", exc_info=True)
            await session.rollback()
            raise
