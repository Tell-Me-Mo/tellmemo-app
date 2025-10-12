"""
Email Digest Service

This service handles digest generation and data aggregation:
- Daily/weekly/monthly digest generation
- User activity tracking for inactive user detection
- Data aggregation from projects, summaries, tasks, and risks
"""

import logging
from typing import Dict, Any, List, Optional
from datetime import datetime, timedelta
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_, or_, func, desc
import uuid

from config import get_settings
from models.user import User
from models.activity import Activity
from models.notification import Notification, NotificationCategory
from models.organization_member import OrganizationMember

# Import email services for use in this module
from services.email.sendgrid_service import sendgrid_service
from services.email.template_service import template_service

logger = logging.getLogger(__name__)
settings = get_settings()


class DigestService:
    """Service for generating email digests"""

    async def generate_daily_digests(self, db: AsyncSession) -> int:
        """
        Generate daily digest jobs for all eligible users.

        Args:
            db: Database session

        Returns:
            Number of digest jobs created
        """
        from queue_config import queue_config
        from datetime import timedelta

        # Get users with daily digest enabled
        result = await db.execute(
            select(User).where(
                and_(
                    User.is_active == True,
                    User.preferences['email_digest']['enabled'].as_boolean() == True,
                    User.preferences['email_digest']['frequency'].as_string() == 'daily'
                )
            )
        )
        users = result.scalars().all()

        logger.info(f"Found {len(users)} users for daily digest")

        # Calculate time period
        end_date = datetime.utcnow()
        start_date = end_date - timedelta(days=1)

        job_count = 0
        for user in users:
            try:
                # Lightweight check if digest has content (avoids expensive aggregation)
                has_content = await self.has_recent_content(
                    user_id=str(user.id),
                    start_date=start_date,
                    end_date=end_date,
                    db=db
                )

                if not has_content:
                    logger.info(f"Skipping empty digest for user {user.id}")
                    continue

                # Enqueue email job (will aggregate data in background)
                queue_config.low_queue.enqueue(
                    'tasks.email_tasks.send_digest_email_task',
                    user_id=str(user.id),
                    digest_type='daily',
                    start_date=start_date.isoformat(),
                    end_date=end_date.isoformat(),
                    job_timeout='10m'
                )
                job_count += 1

            except Exception as e:
                logger.error(f"Error creating daily digest for user {user.id}: {e}")

        logger.info(f"Created {job_count} daily digest jobs")
        return job_count

    async def generate_weekly_digests(self, db: AsyncSession) -> int:
        """
        Generate weekly digest jobs for all eligible users.

        Args:
            db: Database session

        Returns:
            Number of digest jobs created
        """
        from queue_config import queue_config

        # Get users with weekly digest enabled
        result = await db.execute(
            select(User).where(
                and_(
                    User.is_active == True,
                    User.preferences['email_digest']['enabled'].as_boolean() == True,
                    User.preferences['email_digest']['frequency'].as_string() == 'weekly'
                )
            )
        )
        users = result.scalars().all()

        logger.info(f"Found {len(users)} users for weekly digest")

        # Calculate time period
        end_date = datetime.utcnow()
        start_date = end_date - timedelta(weeks=1)

        job_count = 0
        for user in users:
            try:
                # Lightweight check if digest has content (avoids expensive aggregation)
                has_content = await self.has_recent_content(
                    user_id=str(user.id),
                    start_date=start_date,
                    end_date=end_date,
                    db=db
                )

                if not has_content:
                    logger.info(f"Skipping empty digest for user {user.id}")
                    continue

                # Enqueue email job (will aggregate data in background)
                queue_config.low_queue.enqueue(
                    'tasks.email_tasks.send_digest_email_task',
                    user_id=str(user.id),
                    digest_type='weekly',
                    start_date=start_date.isoformat(),
                    end_date=end_date.isoformat(),
                    job_timeout='10m'
                )
                job_count += 1

            except Exception as e:
                logger.error(f"Error creating weekly digest for user {user.id}: {e}")

        logger.info(f"Created {job_count} weekly digest jobs")
        return job_count

    async def generate_monthly_digests(self, db: AsyncSession) -> int:
        """
        Generate monthly digest jobs for all eligible users.

        Args:
            db: Database session

        Returns:
            Number of digest jobs created
        """
        from queue_config import queue_config

        # Get users with monthly digest enabled
        result = await db.execute(
            select(User).where(
                and_(
                    User.is_active == True,
                    User.preferences['email_digest']['enabled'].as_boolean() == True,
                    User.preferences['email_digest']['frequency'].as_string() == 'monthly'
                )
            )
        )
        users = result.scalars().all()

        logger.info(f"Found {len(users)} users for monthly digest")

        # Calculate time period
        end_date = datetime.utcnow()
        start_date = end_date - timedelta(days=30)

        job_count = 0
        for user in users:
            try:
                # Lightweight check if digest has content (avoids expensive aggregation)
                has_content = await self.has_recent_content(
                    user_id=str(user.id),
                    start_date=start_date,
                    end_date=end_date,
                    db=db
                )

                if not has_content:
                    logger.info(f"Skipping empty digest for user {user.id}")
                    continue

                # Enqueue email job (will aggregate data in background)
                queue_config.low_queue.enqueue(
                    'tasks.email_tasks.send_digest_email_task',
                    user_id=str(user.id),
                    digest_type='monthly',
                    start_date=start_date.isoformat(),
                    end_date=end_date.isoformat(),
                    job_timeout='10m'
                )
                job_count += 1

            except Exception as e:
                logger.error(f"Error creating monthly digest for user {user.id}: {e}")

        logger.info(f"Created {job_count} monthly digest jobs")
        return job_count

    async def aggregate_digest_data(
        self,
        user_id: str,
        start_date: datetime,
        end_date: datetime,
        db: AsyncSession
    ) -> Dict[str, Any]:
        """
        Aggregate digest data for a user.

        Args:
            user_id: User ID
            start_date: Start of digest period
            end_date: End of digest period
            db: Database session

        Returns:
            Digest data dictionary
        """
        from models.project import Project
        from models.task import Task, TaskStatus
        from models.risk import Risk, RiskStatus, RiskSeverity
        from models.blocker import Blocker, BlockerStatus, BlockerImpact
        from models.organization import Organization

        # Get user info
        user_result = await db.execute(
            select(User).where(User.id == uuid.UUID(user_id))
        )
        user = user_result.scalar_one_or_none()

        if not user:
            raise ValueError(f"User {user_id} not found")

        # Get user's organizations
        org_result = await db.execute(
            select(OrganizationMember).where(
                OrganizationMember.user_id == uuid.UUID(user_id)
            )
        )
        org_memberships = org_result.scalars().all()
        org_ids = [str(m.organization_id) for m in org_memberships]

        # Get user's projects (across all organizations)
        project_result = await db.execute(
            select(Project).where(
                Project.organization_id.in_([uuid.UUID(oid) for oid in org_ids])
            ).order_by(desc(Project.updated_at))
        )
        projects = project_result.scalars().all()

        # Aggregate data per project
        project_data = []
        total_blockers = 0
        total_tasks = 0
        total_risks = 0

        for project in projects:
            # Get organization name
            org_result = await db.execute(
                select(Organization).where(Organization.id == project.organization_id)
            )
            org = org_result.scalar_one_or_none()

            # Get pending/in-progress tasks for this project
            task_result = await db.execute(
                select(Task).where(
                    and_(
                        Task.project_id == project.id,
                        or_(
                            Task.status == TaskStatus.TODO,
                            Task.status == TaskStatus.IN_PROGRESS
                        )
                    )
                ).order_by(Task.due_date.asc().nullslast())
            )
            tasks = task_result.scalars().all()

            # Get critical risks for this project
            risk_result = await db.execute(
                select(Risk).where(
                    and_(
                        Risk.project_id == project.id,
                        Risk.severity.in_([RiskSeverity.HIGH, RiskSeverity.CRITICAL]),
                        Risk.status != RiskStatus.RESOLVED
                    )
                ).order_by(desc(Risk.severity), desc(Risk.identified_date))
            )
            risks = risk_result.scalars().all()

            # Get active blockers for this project
            blocker_result = await db.execute(
                select(Blocker).where(
                    and_(
                        Blocker.project_id == project.id,
                        Blocker.status.in_([BlockerStatus.ACTIVE, BlockerStatus.ESCALATED])
                    )
                ).order_by(desc(Blocker.impact), desc(Blocker.identified_date))
            )
            blockers = blocker_result.scalars().all()

            # Only include projects with activity
            if tasks or risks or blockers:
                project_data.append({
                    'id': str(project.id),
                    'name': project.name,
                    'organization_name': org.name if org else None,
                    'tasks': [
                        {
                            'title': t.title,
                            'due_date': t.due_date,
                            'status': t.status
                        }
                        for t in tasks
                    ],
                    'risks': [
                        {
                            'title': r.title,
                            'severity': r.severity,
                            'status': r.status
                        }
                        for r in risks
                    ],
                    'blockers': [
                        {
                            'title': b.title,
                            'description': b.description,
                            'impact': b.impact,
                            'status': b.status,
                            'owner': b.owner
                        }
                        for b in blockers
                    ]
                })

                total_blockers += len(blockers)
                total_tasks += len(tasks)
                total_risks += len(risks)

        # Calculate summary statistics
        summary_stats = {
            'projects_active': len(project_data),
            'active_blockers': total_blockers,
            'pending_tasks': total_tasks,
            'critical_risks': total_risks
        }

        # Format digest period
        digest_period = {
            'start_date': start_date.isoformat(),
            'end_date': end_date.isoformat()
        }

        return {
            'user_name': user.name,
            'user_email': user.email,
            'digest_period': digest_period,
            'summary_stats': summary_stats,
            'projects': project_data,
            'organizations': []  # Populated if needed for multi-org view
        }

    async def check_inactive_users(self, db: AsyncSession) -> int:
        """
        Check for inactive users and send reminder emails.

        A user is considered inactive if they:
        - Registered more than 7 days ago
        - Have no activities (creation actions)
        - Haven't received an inactive reminder yet

        Args:
            db: Database session

        Returns:
            Number of reminder emails sent
        """
        from queue_config import queue_config

        # Calculate cutoff date (7 days ago)
        cutoff_date = datetime.utcnow() - timedelta(days=7)

        # Get all active users registered before cutoff
        result = await db.execute(
            select(User).where(
                and_(
                    User.is_active == True,
                    User.created_at <= cutoff_date
                )
            )
        )
        users = result.scalars().all()

        reminder_count = 0

        for user in users:
            # Check if user has any activities
            activity_result = await db.execute(
                select(func.count(Activity.id)).where(
                    Activity.user_id == str(user.id)
                )
            )
            activity_count = activity_result.scalar()

            if activity_count > 0:
                # User is active, skip
                continue

            # Check if reminder already sent
            has_reminder = await self._has_sent_inactive_reminder(str(user.id), db)
            if has_reminder:
                # Already sent, skip
                continue

            # User is inactive - send reminder email
            try:
                queue_config.low_queue.enqueue(
                    'tasks.email_tasks.send_inactive_reminder_task',
                    user_id=str(user.id),
                    job_timeout='5m'
                )
                reminder_count += 1
                logger.info(f"Queued inactive reminder for user {user.id}")

            except Exception as e:
                logger.error(f"Error queuing inactive reminder for user {user.id}: {e}")

        logger.info(f"Queued {reminder_count} inactive user reminders")
        return reminder_count

    async def send_onboarding_email(self, user_id: str, db: AsyncSession) -> bool:
        """
        Send onboarding welcome email to a new user.

        Args:
            user_id: User ID
            db: Database session

        Returns:
            Success status
        """
        from queue_config import queue_config

        try:
            # Enqueue onboarding email job
            queue_config.high_queue.enqueue(
                'tasks.email_tasks.send_onboarding_email_task',
                user_id=user_id,
                job_timeout='5m'
            )
            logger.info(f"Queued onboarding email for user {user_id}")
            return True

        except Exception as e:
            logger.error(f"Error queuing onboarding email for user {user_id}: {e}")
            return False

    async def has_recent_content(
        self,
        user_id: str,
        start_date: datetime,
        end_date: datetime,
        db: AsyncSession
    ) -> bool:
        """
        Lightweight check if user has any digest content without full aggregation.

        This is much faster than aggregate_digest_data() because it uses COUNT queries
        instead of fetching all the data.

        Args:
            user_id: User ID
            start_date: Start of digest period
            end_date: End of digest period
            db: Database session

        Returns:
            True if user has any content in the period, False otherwise
        """
        from models.project import Project
        from models.task import Task, TaskStatus
        from models.risk import Risk, RiskStatus, RiskSeverity
        from models.blocker import Blocker, BlockerStatus

        # Get user's organizations
        org_result = await db.execute(
            select(OrganizationMember.organization_id).where(
                OrganizationMember.user_id == uuid.UUID(user_id)
            )
        )
        org_ids = [row[0] for row in org_result.all()]

        if not org_ids:
            return False

        # Get user's project IDs
        project_result = await db.execute(
            select(Project.id).where(
                Project.organization_id.in_(org_ids)
            )
        )
        project_ids = [row[0] for row in project_result.all()]

        if not project_ids:
            return False

        # Check for pending/in-progress tasks in user's projects
        task_count_result = await db.execute(
            select(func.count(Task.id)).where(
                and_(
                    Task.project_id.in_(project_ids),
                    or_(
                        Task.status == TaskStatus.TODO,
                        Task.status == TaskStatus.IN_PROGRESS
                    )
                )
            )
        )
        task_count = task_count_result.scalar()

        if task_count > 0:
            return True

        # Check for critical risks
        risk_count_result = await db.execute(
            select(func.count(Risk.id)).where(
                and_(
                    Risk.project_id.in_(project_ids),
                    Risk.severity.in_([RiskSeverity.HIGH, RiskSeverity.CRITICAL]),
                    Risk.status != RiskStatus.RESOLVED
                )
            )
        )
        risk_count = risk_count_result.scalar()

        if risk_count > 0:
            return True

        # Check for active blockers
        blocker_count_result = await db.execute(
            select(func.count(Blocker.id)).where(
                and_(
                    Blocker.project_id.in_(project_ids),
                    Blocker.status.in_([BlockerStatus.ACTIVE, BlockerStatus.ESCALATED])
                )
            )
        )
        blocker_count = blocker_count_result.scalar()

        return blocker_count > 0

    def _has_digest_content(self, digest_data: Dict[str, Any]) -> bool:
        """
        Check if digest has any content to send.

        Args:
            digest_data: Digest data dictionary

        Returns:
            True if digest has content, False otherwise
        """
        stats = digest_data.get('summary_stats', {})

        # Check if any counters are non-zero
        has_content = (
            stats.get('projects_active', 0) > 0 or
            stats.get('active_blockers', 0) > 0 or
            stats.get('pending_tasks', 0) > 0 or
            stats.get('critical_risks', 0) > 0
        )

        return has_content

    async def _has_sent_inactive_reminder(self, user_id: str, db: AsyncSession) -> bool:
        """
        Check if inactive reminder has already been sent to user.

        Args:
            user_id: User ID (as string)
            db: Database session

        Returns:
            True if reminder already sent, False otherwise
        """
        result = await db.execute(
            select(func.count(Notification.id)).where(
                and_(
                    Notification.user_id == user_id,
                    Notification.category == NotificationCategory.EMAIL_INACTIVE_REMINDER_SENT
                )
            )
        )
        count = result.scalar()

        return count > 0

    async def _get_user_last_activity(self, user_id: str, db: AsyncSession) -> Optional[datetime]:
        """
        Get the timestamp of the user's last activity.

        Args:
            user_id: User ID
            db: Database session

        Returns:
            Timestamp of last activity, or None if no activities
        """
        result = await db.execute(
            select(Activity.timestamp)
            .where(Activity.user_id == user_id)
            .order_by(desc(Activity.timestamp))
            .limit(1)
        )
        last_activity = result.scalar_one_or_none()

        return last_activity


# Singleton instance
digest_service = DigestService()
