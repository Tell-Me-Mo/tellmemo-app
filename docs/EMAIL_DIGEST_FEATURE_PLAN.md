# Email Digest Feature - Technical Architecture & Implementation Plan

**Feature Branch:** `feature/email-digest-report`
**Created:** 2025-10-12
**Status:** Planning Phase

---

## Table of Contents

1. [Feature Overview](#feature-overview)
2. [Current Infrastructure Analysis](#current-infrastructure-analysis)
3. [Architecture Design](#architecture-design)
4. [Database Schema Changes](#database-schema-changes)
5. [Backend Implementation](#backend-implementation)
6. [Frontend Implementation](#frontend-implementation)
7. [Email Templates](#email-templates)
8. [Testing Strategy](#testing-strategy)
9. [Implementation Roadmap](#implementation-roadmap)
10. [Success Metrics](#success-metrics)

---

## Feature Overview

### Business Goals
- **Increase user engagement** by delivering insights via email
- **Reduce churn** by keeping users informed without requiring login
- **Expand reach** to stakeholders who don't use the platform daily
- **Automate reporting** to save time for project managers

### User Stories

**As a Project Manager**, I want to:
- Receive daily/weekly digest emails about my projects
- Configure which projects to include in digests
- Choose digest frequency (daily, weekly, monthly)
- Customize what information to include

**As an Executive**, I want to:
- Receive portfolio-level summaries via email
- Get only high-priority updates (risks, blockers, decisions)
- Unsubscribe from digests I don't need

**As a Team Member**, I want to:
- Get notifications about tasks assigned to me
- Receive summaries of meetings I attended
- Control email notification preferences

### Feature Scope

**In Scope:**
- ✅ SMTP integration with popular providers
- ✅ User email preferences (digest frequency, content types)
- ✅ Daily/weekly/monthly digest generation
- ✅ Project-level digests (activities, summaries, tasks, risks)
- ✅ Portfolio/program-level digests (rollup view)
- ✅ HTML email templates (responsive design)
- ✅ Scheduled job system for automated sending
- ✅ Email unsubscribe functionality
- ✅ Digest preview in UI before sending

**Out of Scope (Future Enhancements):**
- ❌ Real-time email notifications (instant alerts)
- ❌ Email threading/conversations
- ❌ Email reply processing
- ❌ Custom email template builder UI
- ❌ A/B testing for email content

---

## Current Infrastructure Analysis

### Existing Components

#### ✅ Notification System
- **Location:** `backend/services/notifications/notification_service.py`
- **Features:**
  - Well-structured notification types, priorities, categories
  - In-app notification delivery working
  - WebSocket real-time updates functional
  - Supports `delivered_channels` array for multi-channel delivery
  - Has `email_sent_at` timestamp field (ready for email integration)

#### ✅ Email Service (Partial)
- **Location:** `backend/services/integrations/email_service.py`
- **Current State:**
  - Only supports Supabase Auth emails (invitations, password resets)
  - Has `send_custom_email()` placeholder method
  - Has `send_weekly_report_email()` stub implementation
  - **Gap:** No actual SMTP integration for custom emails

#### ✅ Redis Queue System
- **Location:** `backend/queue_config.py`
- **Features:**
  - Multi-priority queues (high, default, low)
  - Job progress tracking via Redis pub/sub
  - Automatic retry on failure
  - Well-tested with transcription and content processing

#### ✅ Database Models
- **User Model:** Has `preferences` JSON field for storing email settings
- **Notification Model:** Ready for email delivery tracking
- **Summary Model:** Rich structured data for digest content
- **Activity Model:** Tracks all user/project activities

#### ❌ Missing Components
- **No SMTP configuration** in environment variables
- **No email digest preferences** schema/table
- **No scheduled job system** for digest generation
- **No HTML email templates**
- **No digest aggregation service**

---

## Architecture Design

### System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    USER PREFERENCE MANAGEMENT                   │
│  - User configures digest preferences in UI                     │
│  - Frequency: daily, weekly, monthly, never                     │
│  - Content types: summaries, tasks, risks, activities           │
│  - Project/portfolio selection                                  │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                    SCHEDULED JOB SCHEDULER                      │
│  - APScheduler (or similar) runs periodic jobs                  │
│  - Daily: 8 AM user's timezone                                  │
│  - Weekly: Monday 8 AM                                          │
│  - Monthly: 1st of month 8 AM                                   │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                    DIGEST GENERATION SERVICE                    │
│  1. Query users with digest_enabled=True for frequency          │
│  2. For each user:                                              │
│     - Fetch projects/portfolios based on preferences            │
│     - Aggregate data (activities, summaries, tasks, risks)      │
│     - Generate personalized digest content                      │
│     - Queue email job in Redis Queue (low priority)             │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                    REDIS QUEUE (LOW PRIORITY)                   │
│  - email_digest_task(user_id, digest_data)                      │
│  - Batch processing to avoid rate limits                        │
│  - Retry on failure (max 3 attempts)                            │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                    EMAIL SENDING SERVICE                        │
│  1. Render HTML template with digest data                       │
│  2. Send via SMTP (SendGrid/AWS SES/Mailgun)                    │
│  3. Track delivery status                                       │
│  4. Update notification record (email_sent_at timestamp)        │
│  5. Log errors for failed deliveries                            │
└─────────────────────────────────────────────────────────────────┘
```

### Data Flow: Daily Digest

```
08:00 AM (User Timezone)
     │
     ▼
[APScheduler Trigger] → daily_digest_job()
     │
     ▼
Query Users:
  SELECT * FROM users
  WHERE preferences->>'digest_frequency' = 'daily'
  AND preferences->>'digest_enabled' = true
     │
     ▼
For each user:
     │
     ├─ Fetch user's organizations
     ├─ Fetch projects (based on preferences)
     ├─ Query activities (last 24 hours)
     ├─ Query summaries (last 24 hours)
     ├─ Query tasks (assigned to user, due soon)
     ├─ Query risks (high/critical severity)
     │
     ▼
Aggregate & Format Data:
  {
    "user_name": "John Doe",
    "digest_period": "Last 24 hours",
    "summary_stats": {
      "projects_active": 5,
      "new_summaries": 3,
      "pending_tasks": 7,
      "critical_risks": 2
    },
    "projects": [
      {
        "name": "Project Alpha",
        "activities": [...],
        "summaries": [...],
        "tasks": [...],
        "risks": [...]
      }
    ]
  }
     │
     ▼
Enqueue Email Job:
  queue_config.low_queue.enqueue(
    'email_digest_task',
    user_id=user.id,
    digest_data=data
  )
     │
     ▼
[RQ Worker] Process email_digest_task:
     │
     ├─ Render HTML template
     ├─ Send via SMTP
     ├─ Update notification record
     └─ Log delivery status
```

---

## Database Schema Changes

### 1. Add Email Digest Preferences to User

**No new table needed!** Use existing `users.preferences` JSON field:

```json
{
  "email_digest": {
    "enabled": true,
    "frequency": "daily",  // "daily", "weekly", "monthly", "never"
    "timezone": "America/Los_Angeles",
    "send_time": "08:00",  // Time to send digest
    "content_types": [
      "summaries",
      "activities",
      "tasks_assigned",
      "risks_critical",
      "decisions"
    ],
    "project_filter": {
      "type": "all",  // "all", "selected", "favorites"
      "project_ids": []  // If type="selected"
    },
    "portfolio_filter": {
      "enabled": false,
      "portfolio_ids": []
    },
    "include_portfolio_rollup": false,
    "last_sent_at": "2025-10-12T08:00:00Z"
  },
  "email_notifications": {
    "task_assigned": true,
    "risk_created": true,
    "summary_ready": false,
    "meeting_processed": false
  }
}
```

### 2. Email Delivery Tracking

**Use existing `notifications` table!**

The `Notification` model already has:
- `delivered_channels` - Array to track delivery methods
- `email_sent_at` - Timestamp when email was sent
- `extra_data` (metadata) - Can store digest info

**Create new notification category:**
```python
class NotificationCategory(enum.Enum):
    # ... existing categories ...
    EMAIL_DIGEST_SENT = "email_digest_sent"
```

### 3. Migration Script

**Alembic Migration:** `add_email_digest_preferences.py`

```python
"""Add email digest feature support

Revision ID: xxxxx
Revises: xxxxx
Create Date: 2025-10-12
"""

from alembic import op

def upgrade():
    # Update User preferences JSON schema (documentation only)
    # Add default email_digest preferences for existing users
    op.execute("""
        UPDATE users
        SET preferences = preferences ||
        '{"email_digest": {
            "enabled": false,
            "frequency": "weekly",
            "timezone": "UTC",
            "send_time": "08:00",
            "content_types": ["summaries", "tasks_assigned", "risks_critical"],
            "project_filter": {"type": "all", "project_ids": []},
            "portfolio_filter": {"enabled": false, "portfolio_ids": []},
            "include_portfolio_rollup": false
        }}'::jsonb
        WHERE preferences->>'email_digest' IS NULL
    """)

def downgrade():
    # Remove email_digest from preferences
    op.execute("""
        UPDATE users
        SET preferences = preferences - 'email_digest'
    """)
```

---

## Backend Implementation

### 1. Environment Variables

**Add to `.env.example` and `.env`:**

```bash
# ===== EMAIL/SMTP CONFIGURATION ===== (Required for email digests)
# Choose SMTP provider: sendgrid, aws_ses, mailgun, smtp
EMAIL_PROVIDER=smtp
EMAIL_FROM_ADDRESS=noreply@tellmemo.io
EMAIL_FROM_NAME=TellMeMo

# SMTP Configuration (if EMAIL_PROVIDER=smtp)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your-email@gmail.com
SMTP_PASSWORD=your-app-password
SMTP_USE_TLS=true

# SendGrid (if EMAIL_PROVIDER=sendgrid)
SENDGRID_API_KEY=your-sendgrid-api-key

# AWS SES (if EMAIL_PROVIDER=aws_ses)
AWS_SES_ACCESS_KEY_ID=your-aws-access-key
AWS_SES_SECRET_ACCESS_KEY=your-aws-secret-key
AWS_SES_REGION=us-east-1

# Mailgun (if EMAIL_PROVIDER=mailgun)
MAILGUN_API_KEY=your-mailgun-api-key
MAILGUN_DOMAIN=mg.tellmemo.io

# Email Digest Configuration
EMAIL_DIGEST_ENABLED=true
EMAIL_DIGEST_BATCH_SIZE=50  # Max emails per batch
EMAIL_DIGEST_RATE_LIMIT=100  # Max emails per hour
```

### 2. Update `config.py`

```python
# backend/config.py

class Settings(BaseSettings):
    # ... existing settings ...

    # Email/SMTP Configuration
    email_provider: str = Field(default="smtp", env="EMAIL_PROVIDER")
    email_from_address: str = Field(default="noreply@tellmemo.io", env="EMAIL_FROM_ADDRESS")
    email_from_name: str = Field(default="TellMeMo", env="EMAIL_FROM_NAME")

    # SMTP
    smtp_host: str = Field(default="smtp.gmail.com", env="SMTP_HOST")
    smtp_port: int = Field(default=587, env="SMTP_PORT")
    smtp_username: str = Field(default="", env="SMTP_USERNAME")
    smtp_password: str = Field(default="", env="SMTP_PASSWORD")
    smtp_use_tls: bool = Field(default=True, env="SMTP_USE_TLS")

    # SendGrid
    sendgrid_api_key: str = Field(default="", env="SENDGRID_API_KEY")

    # AWS SES
    aws_ses_access_key_id: str = Field(default="", env="AWS_SES_ACCESS_KEY_ID")
    aws_ses_secret_access_key: str = Field(default="", env="AWS_SES_SECRET_ACCESS_KEY")
    aws_ses_region: str = Field(default="us-east-1", env="AWS_SES_REGION")

    # Mailgun
    mailgun_api_key: str = Field(default="", env="MAILGUN_API_KEY")
    mailgun_domain: str = Field(default="", env="MAILGUN_DOMAIN")

    # Digest Configuration
    email_digest_enabled: bool = Field(default=True, env="EMAIL_DIGEST_ENABLED")
    email_digest_batch_size: int = Field(default=50, env="EMAIL_DIGEST_BATCH_SIZE")
    email_digest_rate_limit: int = Field(default=100, env="EMAIL_DIGEST_RATE_LIMIT")
```

### 3. SMTP Service Implementation

**Create:** `backend/services/email/smtp_service.py`

```python
"""SMTP Service for sending emails via multiple providers"""

import logging
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from typing import List, Optional
from config import get_settings

logger = logging.getLogger(__name__)
settings = get_settings()


class SMTPService:
    """Unified SMTP service supporting multiple providers"""

    def __init__(self):
        self.provider = settings.email_provider

    async def send_email(
        self,
        to_email: str,
        subject: str,
        html_body: str,
        text_body: Optional[str] = None,
        cc: Optional[List[str]] = None,
        bcc: Optional[List[str]] = None
    ) -> bool:
        """
        Send email via configured provider.

        Args:
            to_email: Recipient email address
            subject: Email subject
            html_body: HTML email content
            text_body: Plain text fallback
            cc: CC recipients
            bcc: BCC recipients

        Returns:
            True if sent successfully, False otherwise
        """
        try:
            if self.provider == "smtp":
                return await self._send_via_smtp(
                    to_email, subject, html_body, text_body, cc, bcc
                )
            elif self.provider == "sendgrid":
                return await self._send_via_sendgrid(
                    to_email, subject, html_body, text_body, cc, bcc
                )
            elif self.provider == "aws_ses":
                return await self._send_via_ses(
                    to_email, subject, html_body, text_body, cc, bcc
                )
            elif self.provider == "mailgun":
                return await self._send_via_mailgun(
                    to_email, subject, html_body, text_body, cc, bcc
                )
            else:
                logger.error(f"Unknown email provider: {self.provider}")
                return False

        except Exception as e:
            logger.error(f"Failed to send email to {to_email}: {e}", exc_info=True)
            return False

    async def _send_via_smtp(
        self, to_email, subject, html_body, text_body, cc, bcc
    ) -> bool:
        """Send email via standard SMTP"""
        try:
            msg = MIMEMultipart("alternative")
            msg["From"] = f"{settings.email_from_name} <{settings.email_from_address}>"
            msg["To"] = to_email
            msg["Subject"] = subject

            if cc:
                msg["Cc"] = ", ".join(cc)

            # Attach text and HTML parts
            if text_body:
                msg.attach(MIMEText(text_body, "plain"))
            msg.attach(MIMEText(html_body, "html"))

            # Connect and send
            with smtplib.SMTP(settings.smtp_host, settings.smtp_port) as server:
                if settings.smtp_use_tls:
                    server.starttls()
                if settings.smtp_username and settings.smtp_password:
                    server.login(settings.smtp_username, settings.smtp_password)

                recipients = [to_email]
                if cc:
                    recipients.extend(cc)
                if bcc:
                    recipients.extend(bcc)

                server.sendmail(
                    settings.email_from_address,
                    recipients,
                    msg.as_string()
                )

            logger.info(f"Email sent successfully to {to_email} via SMTP")
            return True

        except Exception as e:
            logger.error(f"SMTP send failed: {e}", exc_info=True)
            return False

    async def _send_via_sendgrid(
        self, to_email, subject, html_body, text_body, cc, bcc
    ) -> bool:
        """Send email via SendGrid API"""
        try:
            from sendgrid import SendGridAPIClient
            from sendgrid.helpers.mail import Mail, Email, To, Content

            message = Mail(
                from_email=Email(settings.email_from_address, settings.email_from_name),
                to_emails=To(to_email),
                subject=subject,
                html_content=Content("text/html", html_body)
            )

            if text_body:
                message.add_content(Content("text/plain", text_body))

            sg = SendGridAPIClient(settings.sendgrid_api_key)
            response = sg.send(message)

            logger.info(f"Email sent via SendGrid to {to_email}: {response.status_code}")
            return response.status_code in [200, 201, 202]

        except Exception as e:
            logger.error(f"SendGrid send failed: {e}", exc_info=True)
            return False

    async def _send_via_ses(
        self, to_email, subject, html_body, text_body, cc, bcc
    ) -> bool:
        """Send email via AWS SES"""
        try:
            import boto3

            client = boto3.client(
                'ses',
                region_name=settings.aws_ses_region,
                aws_access_key_id=settings.aws_ses_access_key_id,
                aws_secret_access_key=settings.aws_ses_secret_access_key
            )

            body = {
                'Html': {'Data': html_body, 'Charset': 'UTF-8'}
            }
            if text_body:
                body['Text'] = {'Data': text_body, 'Charset': 'UTF-8'}

            response = client.send_email(
                Source=f"{settings.email_from_name} <{settings.email_from_address}>",
                Destination={'ToAddresses': [to_email]},
                Message={
                    'Subject': {'Data': subject, 'Charset': 'UTF-8'},
                    'Body': body
                }
            )

            logger.info(f"Email sent via AWS SES to {to_email}: {response['MessageId']}")
            return True

        except Exception as e:
            logger.error(f"AWS SES send failed: {e}", exc_info=True)
            return False

    async def _send_via_mailgun(
        self, to_email, subject, html_body, text_body, cc, bcc
    ) -> bool:
        """Send email via Mailgun API"""
        try:
            import requests

            response = requests.post(
                f"https://api.mailgun.net/v3/{settings.mailgun_domain}/messages",
                auth=("api", settings.mailgun_api_key),
                data={
                    "from": f"{settings.email_from_name} <{settings.email_from_address}>",
                    "to": to_email,
                    "subject": subject,
                    "html": html_body,
                    "text": text_body or ""
                }
            )

            logger.info(f"Email sent via Mailgun to {to_email}: {response.status_code}")
            return response.status_code == 200

        except Exception as e:
            logger.error(f"Mailgun send failed: {e}", exc_info=True)
            return False


# Singleton instance
smtp_service = SMTPService()
```

### 4. Email Digest Service

**Create:** `backend/services/email/digest_service.py`

```python
"""Email Digest Service for generating and sending periodic digests"""

import logging
from datetime import datetime, timedelta
from typing import List, Dict, Any, Optional
from sqlalchemy import select, and_, or_
from sqlalchemy.ext.asyncio import AsyncSession

from models.user import User
from models.project import Project
from models.summary import Summary
from models.activity import Activity
from models.task import Task
from models.risk import Risk
from models.notification import Notification, NotificationCategory, NotificationType
from services.email.smtp_service import smtp_service
from services.notifications.notification_service import NotificationService

logger = logging.getLogger(__name__)


class DigestService:
    """Service for generating and sending email digests"""

    @staticmethod
    async def generate_daily_digests(db: AsyncSession) -> int:
        """
        Generate daily digests for all users with daily frequency.

        Returns:
            Number of digests queued
        """
        from queue_config import queue_config

        # Query users with daily digest enabled
        query = select(User).where(
            and_(
                User.is_active == True,
                User.email_verified == True,
                User.preferences['email_digest']['enabled'].as_boolean() == True,
                User.preferences['email_digest']['frequency'].astext == 'daily'
            )
        )

        result = await db.execute(query)
        users = result.scalars().all()

        digest_count = 0
        for user in users:
            try:
                # Enqueue digest generation job (low priority)
                queue_config.low_queue.enqueue(
                    'tasks.email_tasks.send_digest_email_task',
                    user_id=str(user.id),
                    digest_type='daily'
                )
                digest_count += 1
                logger.info(f"Queued daily digest for user {user.email}")

            except Exception as e:
                logger.error(f"Failed to queue digest for user {user.email}: {e}")

        return digest_count

    @staticmethod
    async def generate_weekly_digests(db: AsyncSession) -> int:
        """Generate weekly digests (runs on Mondays)"""
        # Similar to daily_digests but for weekly frequency
        pass

    @staticmethod
    async def generate_monthly_digests(db: AsyncSession) -> int:
        """Generate monthly digests (runs on 1st of month)"""
        pass

    @staticmethod
    async def aggregate_digest_data(
        db: AsyncSession,
        user: User,
        period_start: datetime,
        period_end: datetime
    ) -> Dict[str, Any]:
        """
        Aggregate all digest data for a user.

        Args:
            db: Database session
            user: User to generate digest for
            period_start: Start of digest period
            period_end: End of digest period

        Returns:
            Dictionary with all digest data
        """
        preferences = user.preferences.get('email_digest', {})
        content_types = preferences.get('content_types', [])

        # Get user's projects
        projects = await DigestService._get_user_projects(db, user)

        digest_data = {
            "user_name": user.name or user.email.split('@')[0],
            "user_email": user.email,
            "period_start": period_start,
            "period_end": period_end,
            "digest_period": DigestService._format_period(period_start, period_end),
            "projects": []
        }

        # Aggregate data for each project
        for project in projects:
            project_data = {
                "id": str(project.id),
                "name": project.name,
                "description": project.description
            }

            if "summaries" in content_types:
                project_data["summaries"] = await DigestService._get_project_summaries(
                    db, project.id, period_start, period_end
                )

            if "activities" in content_types:
                project_data["activities"] = await DigestService._get_project_activities(
                    db, project.id, period_start, period_end
                )

            if "tasks_assigned" in content_types:
                project_data["tasks"] = await DigestService._get_user_tasks(
                    db, project.id, user.id, period_end
                )

            if "risks_critical" in content_types:
                project_data["risks"] = await DigestService._get_critical_risks(
                    db, project.id, period_end
                )

            digest_data["projects"].append(project_data)

        # Calculate summary stats
        digest_data["summary_stats"] = DigestService._calculate_stats(digest_data)

        return digest_data

    @staticmethod
    async def _get_user_projects(db: AsyncSession, user: User) -> List[Project]:
        """Get projects for user based on preferences"""
        preferences = user.preferences.get('email_digest', {})
        project_filter = preferences.get('project_filter', {})

        if project_filter.get('type') == 'all':
            # Get all projects from user's organizations
            # (Implementation depends on organization membership)
            pass
        elif project_filter.get('type') == 'selected':
            # Get specific projects
            project_ids = project_filter.get('project_ids', [])
            # Query projects by IDs
            pass

        return []  # TODO: Implement

    @staticmethod
    async def _get_project_summaries(
        db: AsyncSession, project_id: str, start: datetime, end: datetime
    ) -> List[Dict]:
        """Get summaries created in period"""
        query = select(Summary).where(
            and_(
                Summary.project_id == project_id,
                Summary.created_at >= start,
                Summary.created_at <= end
            )
        ).order_by(Summary.created_at.desc())

        result = await db.execute(query)
        summaries = result.scalars().all()

        return [
            {
                "id": str(s.id),
                "subject": s.subject,
                "created_at": s.created_at.isoformat(),
                "format": s.format
            }
            for s in summaries
        ]

    @staticmethod
    def _format_period(start: datetime, end: datetime) -> str:
        """Format period as human-readable string"""
        if (end - start).days == 1:
            return f"{start.strftime('%B %d, %Y')}"
        elif (end - start).days == 7:
            return f"Week of {start.strftime('%B %d, %Y')}"
        else:
            return f"{start.strftime('%b %d')} - {end.strftime('%b %d, %Y')}"

    @staticmethod
    def _calculate_stats(digest_data: Dict) -> Dict[str, int]:
        """Calculate summary statistics"""
        stats = {
            "projects_active": len(digest_data["projects"]),
            "new_summaries": 0,
            "pending_tasks": 0,
            "critical_risks": 0,
            "activities_count": 0
        }

        for project in digest_data["projects"]:
            stats["new_summaries"] += len(project.get("summaries", []))
            stats["pending_tasks"] += len(project.get("tasks", []))
            stats["critical_risks"] += len(project.get("risks", []))
            stats["activities_count"] += len(project.get("activities", []))

        return stats


# Singleton instance
digest_service = DigestService()
```

### 5. Email Task (Redis Queue)

**Create:** `backend/tasks/email_tasks.py`

```python
"""RQ Tasks for Email Processing"""

import asyncio
import logging
from datetime import datetime, timedelta
from rq import get_current_job

from services.email.digest_service import DigestService
from services.email.smtp_service import smtp_service
from services.email.template_service import TemplateService
from services.notifications.notification_service import NotificationService
from models.notification import NotificationCategory, NotificationType
from queue_config import queue_config

logger = logging.getLogger(__name__)


def send_digest_email_task(user_id: str, digest_type: str):
    """
    RQ Task: Send email digest to user.

    Args:
        user_id: User UUID as string
        digest_type: 'daily', 'weekly', or 'monthly'
    """
    rq_job = get_current_job()

    try:
        # Set job metadata
        if rq_job:
            rq_job.meta['status'] = 'processing'
            rq_job.meta['step'] = f'Generating {digest_type} digest'
            rq_job.save_meta()

        # Run async task
        result = asyncio.run(_send_digest_async(user_id, digest_type, rq_job))

        # Update job status
        if rq_job:
            rq_job.meta['status'] = 'completed'
            rq_job.meta['result'] = result
            rq_job.save_meta()

        return result

    except Exception as e:
        logger.error(f"Digest email task failed for user {user_id}: {e}", exc_info=True)

        if rq_job:
            rq_job.meta['status'] = 'failed'
            rq_job.meta['error'] = str(e)
            rq_job.save_meta()

        raise


async def _send_digest_async(user_id: str, digest_type: str, rq_job):
    """Async implementation of digest email sending"""
    from db.database import db_manager
    from models.user import User
    import uuid

    async for session in db_manager.get_session():
        try:
            # Fetch user
            from sqlalchemy import select
            result = await session.execute(
                select(User).where(User.id == uuid.UUID(user_id))
            )
            user = result.scalar_one_or_none()

            if not user:
                raise ValueError(f"User {user_id} not found")

            # Calculate period
            end_time = datetime.utcnow()
            if digest_type == 'daily':
                start_time = end_time - timedelta(days=1)
            elif digest_type == 'weekly':
                start_time = end_time - timedelta(days=7)
            elif digest_type == 'monthly':
                start_time = end_time - timedelta(days=30)
            else:
                raise ValueError(f"Invalid digest type: {digest_type}")

            # Aggregate digest data
            digest_data = await DigestService.aggregate_digest_data(
                db=session,
                user=user,
                period_start=start_time,
                period_end=end_time
            )

            # Render email template
            html_body = TemplateService.render_digest_email(digest_data)
            text_body = TemplateService.render_digest_email_text(digest_data)

            subject = f"Your {digest_type.capitalize()} TellMeMo Digest"

            # Send email
            sent = await smtp_service.send_email(
                to_email=user.email,
                subject=subject,
                html_body=html_body,
                text_body=text_body
            )

            if sent:
                # Create notification record
                notification_service = NotificationService(session)
                await notification_service.create_notification(
                    user_id=str(user.id),
                    title=f"{digest_type.capitalize()} Digest Sent",
                    message=f"Your {digest_type} digest has been emailed to {user.email}",
                    type=NotificationType.INFO,
                    category=NotificationCategory.EMAIL_DIGEST_SENT,
                    metadata={"digest_type": digest_type, "period_start": start_time.isoformat()}
                )

                # Update last_sent_at in user preferences
                user.preferences['email_digest']['last_sent_at'] = end_time.isoformat()
                await session.commit()

                logger.info(f"Digest email sent successfully to {user.email}")
                return {"status": "sent", "user_email": user.email}
            else:
                logger.error(f"Failed to send digest email to {user.email}")
                return {"status": "failed", "user_email": user.email}

        except Exception as e:
            logger.error(f"Error in digest email sending: {e}", exc_info=True)
            raise

        finally:
            break  # Exit after first iteration
```

### 6. Email Template Service

**Create:** `backend/services/email/template_service.py`

```python
"""Email Template Service for rendering HTML emails"""

import logging
from typing import Dict, Any
from jinja2 import Environment, FileSystemLoader, select_autoescape
import os

logger = logging.getLogger(__name__)


class TemplateService:
    """Service for rendering email templates"""

    def __init__(self):
        template_dir = os.path.join(os.path.dirname(__file__), '../../templates/email')
        self.env = Environment(
            loader=FileSystemLoader(template_dir),
            autoescape=select_autoescape(['html', 'xml'])
        )

    def render_digest_email(self, data: Dict[str, Any]) -> str:
        """
        Render digest email HTML template.

        Args:
            data: Digest data dictionary

        Returns:
            Rendered HTML string
        """
        try:
            template = self.env.get_template('digest_email.html')
            return template.render(**data)
        except Exception as e:
            logger.error(f"Failed to render digest email template: {e}")
            return self._fallback_html(data)

    def render_digest_email_text(self, data: Dict[str, Any]) -> str:
        """Render plain text version of digest email"""
        try:
            template = self.env.get_template('digest_email.txt')
            return template.render(**data)
        except Exception as e:
            logger.error(f"Failed to render text template: {e}")
            return self._fallback_text(data)

    def _fallback_html(self, data: Dict) -> str:
        """Simple fallback HTML if template fails"""
        return f"""
        <html>
        <body>
            <h2>Your TellMeMo Digest</h2>
            <p>Hello {data.get('user_name', 'there')},</p>
            <p>Here's your {data.get('digest_period', 'recent')} summary.</p>
            <p>Visit <a href="https://tellmemo.io">TellMeMo</a> to view details.</p>
        </body>
        </html>
        """

    def _fallback_text(self, data: Dict) -> str:
        """Simple fallback text"""
        return f"""
        Your TellMeMo Digest

        Hello {data.get('user_name', 'there')},

        Here's your {data.get('digest_period', 'recent')} summary.

        Visit https://tellmemo.io to view details.
        """


# Singleton instance
template_service = TemplateService()
```

### 7. Scheduler Service

**Create:** `backend/services/scheduler/digest_scheduler.py`

```python
"""APScheduler service for scheduling digest jobs"""

import logging
from apscheduler.schedulers.asyncio import AsyncIOScheduler
from apscheduler.triggers.cron import CronTrigger
from datetime import datetime

logger = logging.getLogger(__name__)


class DigestScheduler:
    """Scheduler for periodic digest generation"""

    def __init__(self):
        self.scheduler = AsyncIOScheduler()

    def start(self):
        """Start the scheduler"""
        # Daily digest: Every day at 8 AM UTC
        self.scheduler.add_job(
            self._run_daily_digests,
            trigger=CronTrigger(hour=8, minute=0),
            id='daily_digest',
            name='Generate daily email digests',
            replace_existing=True
        )

        # Weekly digest: Every Monday at 8 AM UTC
        self.scheduler.add_job(
            self._run_weekly_digests,
            trigger=CronTrigger(day_of_week='mon', hour=8, minute=0),
            id='weekly_digest',
            name='Generate weekly email digests',
            replace_existing=True
        )

        # Monthly digest: 1st of every month at 8 AM UTC
        self.scheduler.add_job(
            self._run_monthly_digests,
            trigger=CronTrigger(day=1, hour=8, minute=0),
            id='monthly_digest',
            name='Generate monthly email digests',
            replace_existing=True
        )

        self.scheduler.start()
        logger.info("Digest scheduler started")

    async def _run_daily_digests(self):
        """Generate daily digests"""
        from db.database import db_manager
        from services.email.digest_service import DigestService

        async for session in db_manager.get_session():
            try:
                count = await DigestService.generate_daily_digests(session)
                logger.info(f"Queued {count} daily digests")
            except Exception as e:
                logger.error(f"Daily digest generation failed: {e}")
            finally:
                break

    async def _run_weekly_digests(self):
        """Generate weekly digests"""
        # Similar to daily
        pass

    async def _run_monthly_digests(self):
        """Generate monthly digests"""
        # Similar to daily
        pass

    def stop(self):
        """Stop the scheduler"""
        self.scheduler.shutdown()
        logger.info("Digest scheduler stopped")


# Singleton instance
digest_scheduler = DigestScheduler()
```

### 8. API Endpoints

**Create:** `backend/routers/email_preferences.py`

```python
"""API endpoints for email digest preferences"""

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from pydantic import BaseModel
from typing import List, Optional

from db.database import db_manager
from dependencies.auth import get_current_user
from models.user import User

router = APIRouter(prefix="/api/email-preferences", tags=["Email Preferences"])


class EmailDigestPreferences(BaseModel):
    enabled: bool
    frequency: str  # daily, weekly, monthly, never
    timezone: str
    send_time: str
    content_types: List[str]
    project_filter: dict
    portfolio_filter: dict
    include_portfolio_rollup: bool


@router.get("/digest")
async def get_digest_preferences(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(db_manager.get_session)
):
    """Get user's email digest preferences"""
    prefs = current_user.preferences.get('email_digest', {})
    return prefs


@router.put("/digest")
async def update_digest_preferences(
    preferences: EmailDigestPreferences,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(db_manager.get_session)
):
    """Update user's email digest preferences"""
    if not current_user.preferences:
        current_user.preferences = {}

    current_user.preferences['email_digest'] = preferences.dict()
    await db.commit()

    return {"status": "updated", "preferences": preferences.dict()}


@router.post("/digest/preview")
async def preview_digest(
    digest_type: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(db_manager.get_session)
):
    """Generate a preview of the digest email (without sending)"""
    from services.email.digest_service import DigestService
    from services.email.template_service import TemplateService
    from datetime import datetime, timedelta

    # Calculate period based on digest type
    end_time = datetime.utcnow()
    if digest_type == 'daily':
        start_time = end_time - timedelta(days=1)
    elif digest_type == 'weekly':
        start_time = end_time - timedelta(days=7)
    else:
        start_time = end_time - timedelta(days=30)

    # Aggregate data
    digest_data = await DigestService.aggregate_digest_data(
        db=db,
        user=current_user,
        period_start=start_time,
        period_end=end_time
    )

    # Render HTML
    html_content = TemplateService().render_digest_email(digest_data)

    return {
        "digest_type": digest_type,
        "period": f"{start_time.isoformat()} to {end_time.isoformat()}",
        "html_preview": html_content,
        "data": digest_data
    }


@router.post("/digest/send-test")
async def send_test_digest(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(db_manager.get_session)
):
    """Send a test digest email immediately"""
    from queue_config import queue_config

    # Enqueue test digest (high priority for immediate delivery)
    job = queue_config.high_queue.enqueue(
        'tasks.email_tasks.send_digest_email_task',
        user_id=str(current_user.id),
        digest_type='daily'
    )

    return {
        "status": "queued",
        "job_id": job.id,
        "message": "Test digest will be sent shortly"
    }
```

---

## Email Templates

### Directory Structure

```
backend/
└── templates/
    └── email/
        ├── base.html                   # Base template with header/footer
        ├── digest_email.html           # HTML digest template
        ├── digest_email.txt            # Plain text digest template
        ├── components/
        │   ├── summary_card.html       # Summary component
        │   ├── task_list.html          # Task list component
        │   ├── risk_alert.html         # Risk alert component
        │   └── activity_feed.html      # Activity feed component
        └── styles/
            └── email_styles.css        # Inline CSS for emails
```

### Base Template

**File:** `backend/templates/email/base.html`

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{% block title %}TellMeMo Digest{% endblock %}</title>
    <style>
        /* Inline CSS for email compatibility */
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
            line-height: 1.6;
            color: #333;
            margin: 0;
            padding: 0;
            background-color: #f4f4f4;
        }
        .container {
            max-width: 600px;
            margin: 20px auto;
            background: #ffffff;
            border-radius: 8px;
            overflow: hidden;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 30px;
            text-align: center;
        }
        .header h1 {
            margin: 0;
            font-size: 24px;
        }
        .content {
            padding: 30px;
        }
        .footer {
            background: #f8f9fa;
            padding: 20px;
            text-align: center;
            font-size: 12px;
            color: #6c757d;
        }
        .button {
            display: inline-block;
            padding: 12px 24px;
            background: #667eea;
            color: white;
            text-decoration: none;
            border-radius: 4px;
            margin: 10px 0;
        }
        .stats {
            display: flex;
            justify-content: space-around;
            margin: 20px 0;
            padding: 20px;
            background: #f8f9fa;
            border-radius: 4px;
        }
        .stat {
            text-align: center;
        }
        .stat-value {
            font-size: 32px;
            font-weight: bold;
            color: #667eea;
        }
        .stat-label {
            font-size: 12px;
            color: #6c757d;
            text-transform: uppercase;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>📊 TellMeMo</h1>
            <p>{% block header_subtitle %}Your Project Intelligence Digest{% endblock %}</p>
        </div>

        <div class="content">
            {% block content %}{% endblock %}
        </div>

        <div class="footer">
            <p>
                <a href="{{ frontend_url }}/settings/email-preferences">Email Preferences</a> |
                <a href="{{ frontend_url }}/unsubscribe?token={{ unsubscribe_token }}">Unsubscribe</a>
            </p>
            <p>&copy; 2025 TellMeMo. All rights reserved.</p>
        </div>
    </div>
</body>
</html>
```

### Digest Email Template

**File:** `backend/templates/email/digest_email.html`

```html
{% extends "base.html" %}

{% block title %}Your {{ digest_period }} Digest - TellMeMo{% endblock %}

{% block header_subtitle %}{{ digest_period }}{% endblock %}

{% block content %}
<p>Hi {{ user_name }},</p>

<p>Here's what happened across your projects:</p>

<!-- Summary Statistics -->
<div class="stats">
    <div class="stat">
        <div class="stat-value">{{ summary_stats.projects_active }}</div>
        <div class="stat-label">Active Projects</div>
    </div>
    <div class="stat">
        <div class="stat-value">{{ summary_stats.new_summaries }}</div>
        <div class="stat-label">New Summaries</div>
    </div>
    <div class="stat">
        <div class="stat-value">{{ summary_stats.pending_tasks }}</div>
        <div class="stat-label">Pending Tasks</div>
    </div>
    <div class="stat">
        <div class="stat-value">{{ summary_stats.critical_risks }}</div>
        <div class="stat-label">Critical Risks</div>
    </div>
</div>

<!-- Project Details -->
{% for project in projects %}
<div style="margin-bottom: 30px; padding: 20px; border: 1px solid #e0e0e0; border-radius: 4px;">
    <h2 style="margin-top: 0; color: #667eea;">{{ project.name }}</h2>

    {% if project.summaries %}
    <h3>📝 Recent Summaries</h3>
    <ul>
        {% for summary in project.summaries %}
        <li>
            <strong>{{ summary.subject }}</strong><br>
            <small>{{ summary.created_at }}</small>
        </li>
        {% endfor %}
    </ul>
    {% endif %}

    {% if project.tasks %}
    <h3>✅ Your Tasks</h3>
    <ul>
        {% for task in project.tasks %}
        <li>
            {{ task.title }}
            {% if task.due_date %}<span style="color: #dc3545;">(Due: {{ task.due_date }})</span>{% endif %}
        </li>
        {% endfor %}
    </ul>
    {% endif %}

    {% if project.risks %}
    <h3>⚠️ Critical Risks</h3>
    <ul>
        {% for risk in project.risks %}
        <li style="color: #dc3545;">
            <strong>{{ risk.title }}</strong> - {{ risk.severity }}
        </li>
        {% endfor %}
    </ul>
    {% endif %}

    <a href="{{ frontend_url }}/projects/{{ project.id }}" class="button">View Project</a>
</div>
{% endfor %}

<p style="text-align: center; margin-top: 30px;">
    <a href="{{ frontend_url }}/dashboard" class="button">Open TellMeMo Dashboard</a>
</p>
{% endblock %}
```

---

## Frontend Implementation

### 1. Email Preferences Screen

**Create:** `lib/features/settings/presentation/screens/email_preferences_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EmailPreferencesScreen extends ConsumerStatefulWidget {
  const EmailPreferencesScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<EmailPreferencesScreen> createState() => _EmailPreferencesScreenState();
}

class _EmailPreferencesScreenState extends ConsumerState<EmailPreferencesScreen> {
  bool _digestEnabled = false;
  String _frequency = 'weekly';
  Set<String> _contentTypes = {'summaries', 'tasks_assigned', 'risks_critical'};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Email Digest Preferences'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Enable/Disable Toggle
          SwitchListTile(
            title: const Text('Enable Email Digests'),
            subtitle: const Text('Receive periodic email summaries'),
            value: _digestEnabled,
            onChanged: (value) {
              setState(() {
                _digestEnabled = value;
              });
            },
          ),

          const Divider(),

          // Frequency Selection
          ListTile(
            title: const Text('Digest Frequency'),
            subtitle: Text(_frequency.toUpperCase()),
          ),
          RadioListTile<String>(
            title: const Text('Daily'),
            value: 'daily',
            groupValue: _frequency,
            onChanged: (value) {
              setState(() {
                _frequency = value!;
              });
            },
          ),
          RadioListTile<String>(
            title: const Text('Weekly'),
            value: 'weekly',
            groupValue: _frequency,
            onChanged: (value) {
              setState(() {
                _frequency = value!;
              });
            },
          ),
          RadioListTile<String>(
            title: const Text('Monthly'),
            value: 'monthly',
            groupValue: _frequency,
            onChanged: (value) {
              setState(() {
                _frequency = value!;
              });
            },
          ),

          const Divider(),

          // Content Type Selection
          const ListTile(
            title: Text('Include in Digest'),
          ),
          CheckboxListTile(
            title: const Text('Meeting Summaries'),
            value: _contentTypes.contains('summaries'),
            onChanged: (value) {
              setState(() {
                if (value!) {
                  _contentTypes.add('summaries');
                } else {
                  _contentTypes.remove('summaries');
                }
              });
            },
          ),
          CheckboxListTile(
            title: const Text('Tasks Assigned to Me'),
            value: _contentTypes.contains('tasks_assigned'),
            onChanged: (value) {
              setState(() {
                if (value!) {
                  _contentTypes.add('tasks_assigned');
                } else {
                  _contentTypes.remove('tasks_assigned');
                }
              });
            },
          ),
          CheckboxListTile(
            title: const Text('Critical Risks'),
            value: _contentTypes.contains('risks_critical'),
            onChanged: (value) {
              setState(() {
                if (value!) {
                  _contentTypes.add('risks_critical');
                } else {
                  _contentTypes.remove('risks_critical');
                }
              });
            },
          ),
          CheckboxListTile(
            title: const Text('Project Activities'),
            value: _contentTypes.contains('activities'),
            onChanged: (value) {
              setState(() {
                if (value!) {
                  _contentTypes.add('activities');
                } else {
                  _contentTypes.remove('activities');
                }
              });
            },
          ),

          const SizedBox(height: 32),

          // Save Button
          ElevatedButton(
            onPressed: _savePreferences,
            child: const Text('Save Preferences'),
          ),

          const SizedBox(height: 16),

          // Preview Button
          OutlinedButton(
            onPressed: _previewDigest,
            child: const Text('Preview Digest'),
          ),

          const SizedBox(height: 8),

          // Send Test Email Button
          OutlinedButton(
            onPressed: _sendTestEmail,
            child: const Text('Send Test Email'),
          ),
        ],
      ),
    );
  }

  Future<void> _savePreferences() async {
    // Call API to save preferences
    // TODO: Implement API call
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preferences saved successfully')),
    );
  }

  Future<void> _previewDigest() async {
    // Call API to get preview
    // Show preview dialog
    // TODO: Implement preview
  }

  Future<void> _sendTestEmail() async {
    // Call API to send test email
    // TODO: Implement test email
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Test email sent! Check your inbox.')),
    );
  }
}
```

---

## Testing Strategy

### 1. Unit Tests

**Backend:**
- `test_smtp_service.py` - Test email sending with mocked SMTP
- `test_digest_service.py` - Test digest data aggregation
- `test_template_service.py` - Test template rendering
- `test_email_tasks.py` - Test RQ job execution

**Frontend:**
- `email_preferences_screen_test.dart` - Test UI interactions
- `email_preferences_provider_test.dart` - Test state management

### 2. Integration Tests

- End-to-end digest generation flow
- SMTP provider integration (SendGrid, AWS SES, etc.)
- Scheduler trigger verification
- Database preference updates

### 3. Manual Testing Checklist

- [ ] Configure SMTP credentials
- [ ] Enable email digests for test user
- [ ] Trigger manual digest send
- [ ] Verify email received with correct content
- [ ] Test unsubscribe link
- [ ] Test different frequencies (daily, weekly, monthly)
- [ ] Test different content type combinations
- [ ] Test email preview in UI
- [ ] Test HTML rendering in different email clients
- [ ] Test plain text fallback

---

## Implementation Roadmap

### Phase 1: Foundation (Week 1)

**Backend:**
- [ ] Add SMTP configuration to `.env` and `config.py`
- [ ] Implement `SMTPService` with SMTP provider (start with one, e.g., SMTP)
- [ ] Create database migration for email preferences
- [ ] Update `User` model with default email preferences
- [ ] Create `email_preferences` API endpoints (GET, PUT)

**Frontend:**
- [ ] Create Email Preferences screen UI
- [ ] Implement API client for preferences
- [ ] Add navigation to settings

**Testing:**
- [ ] Unit test SMTP service with mock
- [ ] Test API endpoints
- [ ] Test UI interactions

### Phase 2: Digest Generation (Week 2)

**Backend:**
- [ ] Implement `DigestService` data aggregation
- [ ] Create `TemplateService` for email rendering
- [ ] Implement base HTML email template
- [ ] Implement digest email template (HTML + text)
- [ ] Create RQ task `send_digest_email_task`

**Testing:**
- [ ] Test digest data aggregation
- [ ] Test template rendering
- [ ] Test RQ task execution
- [ ] Send test digest manually

### Phase 3: Scheduling (Week 3)

**Backend:**
- [ ] Implement `DigestScheduler` with APScheduler
- [ ] Add scheduler initialization to FastAPI startup
- [ ] Configure cron triggers for daily/weekly/monthly
- [ ] Implement batch processing for rate limiting

**Testing:**
- [ ] Test scheduler triggers
- [ ] Test batch processing
- [ ] Test rate limiting
- [ ] Monitor logs for scheduled runs

### Phase 4: Polish & Features (Week 4)

**Backend:**
- [ ] Add additional SMTP providers (SendGrid, AWS SES, Mailgun)
- [ ] Implement unsubscribe functionality
- [ ] Add digest preview endpoint
- [ ] Add send test email endpoint
- [ ] Optimize database queries for performance

**Frontend:**
- [ ] Implement digest preview dialog
- [ ] Add test email send button
- [ ] Add unsubscribe management
- [ ] Polish UI/UX

**Testing:**
- [ ] End-to-end integration tests
- [ ] Load testing (simulate 1000+ users)
- [ ] Email client compatibility testing
- [ ] User acceptance testing

### Phase 5: Deployment & Monitoring

- [ ] Deploy to production
- [ ] Configure production SMTP credentials
- [ ] Set up monitoring/alerts for failed emails
- [ ] Monitor email delivery rates
- [ ] Gather user feedback
- [ ] Iterate based on analytics

---

## Success Metrics

### Technical Metrics

- **Email Delivery Rate:** >95% successfully delivered
- **Digest Generation Time:** <5 seconds per user
- **Queue Processing Time:** <10 minutes for 1000 users
- **Email Open Rate:** >30% (industry average: 20-25%)
- **Click-through Rate:** >10%
- **Unsubscribe Rate:** <2%

### Business Metrics

- **User Engagement:** +20% increase in weekly active users
- **Session Frequency:** +15% increase in login frequency
- **User Retention:** +10% improvement in 30-day retention
- **Feature Adoption:** 50% of users enable email digests

### Monitoring & Alerts

- **Failed Email Alerts:** Trigger alert if >5% emails fail
- **Scheduler Health:** Alert if scheduler stops running
- **Queue Backlog:** Alert if queue exceeds 1000 pending jobs
- **SMTP Rate Limits:** Monitor and alert on approaching limits

---

## Future Enhancements

### Phase 2 (Post-MVP)

1. **Smart Digest Timing**
   - Machine learning to determine optimal send time per user
   - Timezone-aware sending
   - Frequency auto-adjustment based on engagement

2. **Personalized Content**
   - AI-generated summaries tailored to user role
   - Priority-based content ordering
   - Dynamic content based on user behavior

3. **Interactive Emails**
   - Mark tasks complete from email (AMP for Email)
   - Reply to comments
   - Quick actions (approve/reject)

4. **Advanced Analytics**
   - Email engagement dashboard
   - A/B testing for subject lines
   - Content performance tracking

5. **Multi-channel Delivery**
   - Slack digest integration
   - Microsoft Teams integration
   - Push notifications (mobile)

---

## Appendix

### Dependencies to Add

**Backend:**
```txt
# requirements.txt additions
apscheduler==3.10.4  # Job scheduling
jinja2==3.1.2  # Template rendering
sendgrid==6.10.0  # SendGrid provider (optional)
boto3==1.28.85  # AWS SES provider (optional)
```

**Frontend:**
```yaml
# pubspec.yaml additions
dependencies:
  intl: ^0.18.0  # Timezone handling
```

### Configuration Examples

**Gmail SMTP:**
```env
EMAIL_PROVIDER=smtp
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your-email@gmail.com
SMTP_PASSWORD=your-app-password
SMTP_USE_TLS=true
```

**SendGrid:**
```env
EMAIL_PROVIDER=sendgrid
SENDGRID_API_KEY=SG.xxx
```

**AWS SES:**
```env
EMAIL_PROVIDER=aws_ses
AWS_SES_ACCESS_KEY_ID=AKIA...
AWS_SES_SECRET_ACCESS_KEY=xxx
AWS_SES_REGION=us-east-1
```

---

## Questions & Decisions

**Q: Which SMTP provider should we use?**
A: Start with generic SMTP (supports Gmail, Outlook) for MVP. Add SendGrid/AWS SES for production scale.

**Q: How to handle email bounces?**
A: Phase 2 - implement webhook handlers for bounce/complaint notifications.

**Q: Should we use HTML or plain text?**
A: Both! HTML for rich formatting, plain text as fallback.

**Q: How to handle timezone conversion?**
A: Store user timezone in preferences, convert all times to user's local timezone in templates.

**Q: Rate limiting strategy?**
A: Batch process 50 emails at a time with 1-second delay between batches.

---

## Resources

- [SendGrid Email API Docs](https://docs.sendgrid.com/)
- [AWS SES Developer Guide](https://docs.aws.amazon.com/ses/)
- [Email Design Best Practices](https://www.campaignmonitor.com/resources/guides/email-design-best-practices/)
- [APScheduler Documentation](https://apscheduler.readthedocs.io/)
- [Jinja2 Template Designer Docs](https://jinja.palletsprojects.com/)

---

**Document End**
