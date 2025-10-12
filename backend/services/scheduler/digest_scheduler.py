"""
Digest Scheduler Service using APScheduler

This service manages scheduled email digest jobs:
- Daily digests: Every day at 8 AM UTC
- Weekly digests: Every Monday at 8 AM UTC
- Monthly digests: 1st of each month at 8 AM UTC
- Inactive user check: Once per day at 9 AM UTC
"""

import logging
import asyncio
from datetime import datetime
from apscheduler.schedulers.asyncio import AsyncIOScheduler
from apscheduler.triggers.cron import CronTrigger

from config import get_settings

logger = logging.getLogger(__name__)
settings = get_settings()


class DigestScheduler:
    """Service for scheduling digest email jobs"""

    def __init__(self):
        """Initialize APScheduler"""
        self.scheduler = AsyncIOScheduler()
        self.is_running = False

    def start(self):
        """
        Start the scheduler and register all digest jobs.

        This method should be called during FastAPI startup.
        """
        if self.is_running:
            logger.warning("Digest scheduler is already running")
            return

        try:
            # Check if email digest feature is enabled
            if not settings.email_digest_enabled:
                logger.info("Email digest feature is disabled - scheduler not started")
                return

            logger.info("Starting digest scheduler...")

            # Register daily digest job (8 AM UTC every day)
            self.scheduler.add_job(
                self._run_daily_digests,
                trigger=CronTrigger(hour=8, minute=0, timezone='UTC'),
                id='daily_digest_job',
                name='Daily Digest Generation',
                replace_existing=True,
                misfire_grace_time=3600  # Allow 1 hour grace period
            )
            logger.info("✅ Scheduled daily digest job: Every day at 8 AM UTC")

            # Register weekly digest job (Monday 8 AM UTC)
            self.scheduler.add_job(
                self._run_weekly_digests,
                trigger=CronTrigger(day_of_week='mon', hour=8, minute=0, timezone='UTC'),
                id='weekly_digest_job',
                name='Weekly Digest Generation',
                replace_existing=True,
                misfire_grace_time=3600
            )
            logger.info("✅ Scheduled weekly digest job: Every Monday at 8 AM UTC")

            # Register monthly digest job (1st of month 8 AM UTC)
            self.scheduler.add_job(
                self._run_monthly_digests,
                trigger=CronTrigger(day=1, hour=8, minute=0, timezone='UTC'),
                id='monthly_digest_job',
                name='Monthly Digest Generation',
                replace_existing=True,
                misfire_grace_time=3600
            )
            logger.info("✅ Scheduled monthly digest job: 1st of each month at 8 AM UTC")

            # Register inactive user check job (9 AM UTC every day)
            self.scheduler.add_job(
                self._check_inactive_users,
                trigger=CronTrigger(hour=9, minute=0, timezone='UTC'),
                id='inactive_user_check_job',
                name='Inactive User Check',
                replace_existing=True,
                misfire_grace_time=3600
            )
            logger.info("✅ Scheduled inactive user check job: Every day at 9 AM UTC")

            # Start the scheduler
            self.scheduler.start()
            self.is_running = True

            logger.info("🚀 Digest scheduler started successfully")
            logger.info(f"Next scheduled jobs:")
            for job in self.scheduler.get_jobs():
                next_run = job.next_run_time.strftime('%Y-%m-%d %H:%M:%S %Z') if job.next_run_time else 'N/A'
                logger.info(f"  - {job.name}: {next_run}")

        except Exception as e:
            logger.error(f"Failed to start digest scheduler: {e}", exc_info=True)
            raise

    def stop(self):
        """
        Stop the scheduler gracefully.

        This method should be called during FastAPI shutdown.
        """
        if not self.is_running:
            logger.warning("Digest scheduler is not running")
            return

        try:
            logger.info("Stopping digest scheduler...")
            self.scheduler.shutdown(wait=True)
            self.is_running = False
            logger.info("✅ Digest scheduler stopped successfully")

        except Exception as e:
            logger.error(f"Error stopping digest scheduler: {e}", exc_info=True)

    async def _run_daily_digests(self):
        """
        Execute daily digest generation.

        This is called by APScheduler at 8 AM UTC every day.
        """
        logger.info("🔄 Starting daily digest generation job...")
        start_time = datetime.utcnow()

        try:
            from db.database import db_manager
            from services.email.digest_service import digest_service

            async for session in db_manager.get_session():
                try:
                    job_count = await digest_service.generate_daily_digests(session)

                    elapsed = (datetime.utcnow() - start_time).total_seconds()
                    logger.info(f"✅ Daily digest generation completed: {job_count} jobs created in {elapsed:.2f}s")

                except Exception as e:
                    logger.error(f"Error in daily digest generation: {e}", exc_info=True)

                finally:
                    break

        except Exception as e:
            logger.error(f"Failed to run daily digest job: {e}", exc_info=True)

    async def _run_weekly_digests(self):
        """
        Execute weekly digest generation.

        This is called by APScheduler at 8 AM UTC every Monday.
        """
        logger.info("🔄 Starting weekly digest generation job...")
        start_time = datetime.utcnow()

        try:
            from db.database import db_manager
            from services.email.digest_service import digest_service

            async for session in db_manager.get_session():
                try:
                    job_count = await digest_service.generate_weekly_digests(session)

                    elapsed = (datetime.utcnow() - start_time).total_seconds()
                    logger.info(f"✅ Weekly digest generation completed: {job_count} jobs created in {elapsed:.2f}s")

                except Exception as e:
                    logger.error(f"Error in weekly digest generation: {e}", exc_info=True)

                finally:
                    break

        except Exception as e:
            logger.error(f"Failed to run weekly digest job: {e}", exc_info=True)

    async def _run_monthly_digests(self):
        """
        Execute monthly digest generation.

        This is called by APScheduler at 8 AM UTC on the 1st of each month.
        """
        logger.info("🔄 Starting monthly digest generation job...")
        start_time = datetime.utcnow()

        try:
            from db.database import db_manager
            from services.email.digest_service import digest_service

            async for session in db_manager.get_session():
                try:
                    job_count = await digest_service.generate_monthly_digests(session)

                    elapsed = (datetime.utcnow() - start_time).total_seconds()
                    logger.info(f"✅ Monthly digest generation completed: {job_count} jobs created in {elapsed:.2f}s")

                except Exception as e:
                    logger.error(f"Error in monthly digest generation: {e}", exc_info=True)

                finally:
                    break

        except Exception as e:
            logger.error(f"Failed to run monthly digest job: {e}", exc_info=True)

    async def _check_inactive_users(self):
        """
        Check for inactive users and send reminder emails.

        This is called by APScheduler at 9 AM UTC every day.
        """
        logger.info("🔄 Starting inactive user check job...")
        start_time = datetime.utcnow()

        try:
            from db.database import db_manager
            from services.email.digest_service import digest_service

            async for session in db_manager.get_session():
                try:
                    reminder_count = await digest_service.check_inactive_users(session)

                    elapsed = (datetime.utcnow() - start_time).total_seconds()
                    logger.info(f"✅ Inactive user check completed: {reminder_count} reminders sent in {elapsed:.2f}s")

                except Exception as e:
                    logger.error(f"Error in inactive user check: {e}", exc_info=True)

                finally:
                    break

        except Exception as e:
            logger.error(f"Failed to run inactive user check job: {e}", exc_info=True)

    def get_job_status(self) -> dict:
        """
        Get status of all scheduled jobs.

        Returns:
            Dict with job information
        """
        if not self.is_running:
            return {
                "scheduler_running": False,
                "jobs": []
            }

        jobs_info = []
        for job in self.scheduler.get_jobs():
            jobs_info.append({
                "id": job.id,
                "name": job.name,
                "next_run_time": job.next_run_time.isoformat() if job.next_run_time else None,
                "trigger": str(job.trigger)
            })

        return {
            "scheduler_running": True,
            "jobs": jobs_info,
            "current_time_utc": datetime.utcnow().isoformat()
        }


# Singleton instance
digest_scheduler = DigestScheduler()
