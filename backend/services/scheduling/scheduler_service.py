"""Scheduler service for automated tasks like weekly report generation."""

import asyncio
from datetime import datetime, timedelta, timezone
from typing import Optional
from apscheduler.schedulers.asyncio import AsyncIOScheduler
from apscheduler.triggers.cron import CronTrigger
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from db.database import get_db
from models.project import Project, ProjectStatus
from services.summaries.summary_service_refactored import SummaryService
from utils.logger import get_logger, sanitize_for_log
from utils.monitoring import monitor_operation, track_background_task

logger = get_logger(__name__)


class SchedulerService:
    """Service for managing scheduled tasks."""
    
    def __init__(self):
        """Initialize the scheduler service."""
        self.scheduler = AsyncIOScheduler()
        self.summary_service = SummaryService()
        self._is_running = False
        logger.info("Scheduler service initialized")
    
    def start(self):
        """Start the scheduler."""
        if not self._is_running:
            self._setup_jobs()
            self.scheduler.start()
            self._is_running = True
            logger.info("Scheduler started successfully")
    
    def shutdown(self):
        """Shutdown the scheduler."""
        if self._is_running:
            self.scheduler.shutdown(wait=True)
            self._is_running = False
            logger.info("Scheduler shut down successfully")
    
    def _setup_jobs(self):
        """Setup all scheduled jobs."""
        # Weekly report generation - Every Friday at 5 PM - DISABLED
        # self.scheduler.add_job(
        #     func=self._generate_weekly_reports,
        #     trigger=CronTrigger(
        #         day_of_week='fri',
        #         hour=17,
        #         minute=0,
        #         timezone='UTC'
        #     ),
        #     id='weekly_reports',
        #     name='Generate Weekly Reports',
        #     replace_existing=True
        # )
        # logger.info("Scheduled weekly report generation for Fridays at 5 PM UTC")

        # Also add a daily check for testing purposes (can be removed in production) - DISABLED
        # if self._is_development_mode():
        #     self.scheduler.add_job(
        #         func=self._generate_weekly_reports,
        #         trigger=CronTrigger(
        #             hour=9,
        #             minute=0,
        #             timezone='UTC'
        #         ),
        #         id='daily_test_reports',
        #         name='Daily Test Reports (Dev Only)',
        #         replace_existing=True
        #     )
        #     logger.info("Scheduled daily test report generation at 9 AM UTC (development mode)")

        logger.info("Scheduler started with no active jobs (weekly and daily reports disabled)")
    
    def _is_development_mode(self) -> bool:
        """Check if running in development mode."""
        from config import get_settings
        settings = get_settings()
        return settings.api_env == "development"
    
    @track_background_task("generate_weekly_reports")
    async def _generate_weekly_reports(self):
        """Generate weekly reports for all active projects."""
        logger.info("Starting scheduled weekly report generation")
        
        async for session in get_db():
            try:
                # Get all active projects
                result = await session.execute(
                    select(Project).where(Project.status == ProjectStatus.ACTIVE)
                )
                projects = result.scalars().all()
                
                if not projects:
                    logger.info("No active projects found for weekly report generation")
                    break
                
                logger.info(f"Generating weekly reports for {len(projects)} active projects")
                
                # Generate report for each project
                for project in projects:
                    try:
                        await self._generate_project_weekly_report(session, project)
                    except Exception as e:
                        logger.error(f"Failed to generate weekly report for project {project.id}: {e}")
                        continue
                
                logger.info("Completed scheduled weekly report generation")
                
            except Exception as e:
                logger.error(f"Error during scheduled weekly report generation: {e}")
            finally:
                break
    
    @monitor_operation(
        operation_name="generate_project_weekly_report",
        operation_type="general",
        capture_args=True,
        capture_result=False
    )
    async def _generate_project_weekly_report(
        self,
        session: AsyncSession,
        project: Project
    ):
        """
        Generate weekly report for a specific project.
        
        Args:
            session: Database session
            project: Project to generate report for
        """
        try:
            # Calculate date range (last 7 days)
            end_date = datetime.now(timezone.utc).replace(tzinfo=None)
            start_date = end_date - timedelta(days=7)
            
            logger.info(
                f"Generating weekly report for project '{project.name}' "
                f"({start_date.date()} to {end_date.date()})"
            )
            
            # Generate the weekly summary
            summary_data = await self.summary_service.generate_weekly_summary(
                session=session,
                project_id=project.id,
                date_range_start=start_date,
                date_range_end=end_date,
                created_by="scheduler",
                format_type="general"
            )
            
            logger.info(
                f"Successfully generated weekly report for project '{project.name}' "
                f"(Summary ID: {summary_data['summary_id']})"
            )
            
            # TODO: Add email notification logic here when email service is implemented
            # await self.email_service.send_weekly_report(project, summary_data)
            
        except Exception as e:
            logger.error(f"Failed to generate weekly report for project {project.id}: {e}")
            raise
    
    @monitor_operation(
        operation_name="trigger_weekly_report",
        operation_type="general",
        capture_args=True,
        capture_result=True
    )
    async def trigger_weekly_report(
        self,
        project_id: str,
        date_range_start: Optional[datetime] = None,
        date_range_end: Optional[datetime] = None
    ) -> dict:
        """
        Manually trigger weekly report generation for a specific project.
        
        Args:
            project_id: Project UUID
            date_range_start: Optional start date
            date_range_end: Optional end date
            
        Returns:
            Summary data dictionary
        """
        logger.info(f"Manual trigger for weekly report generation for project {project_id}")
        
        summary_data = None
        async for session in get_db():
            try:
                # Validate project exists
                result = await session.execute(
                    select(Project).where(Project.id == project_id)
                )
                project = result.scalar_one_or_none()
                
                if not project:
                    raise ValueError(f"Project {project_id} not found")
                
                # Generate the weekly summary
                summary_data = await self.summary_service.generate_weekly_summary(
                    session=session,
                    project_id=project_id,
                    date_range_start=date_range_start,
                    date_range_end=date_range_end,
                    created_by="manual",
                    format_type="general"
                )
                
                logger.info(
                    f"Successfully generated manual weekly report for project {project_id} "
                    f"(Summary ID: {summary_data['summary_id']})"
                )
                
            except Exception as e:
                logger.error(f"Failed to generate manual weekly report: {e}")
                raise
            finally:
                break
        
        return summary_data
    
    def get_scheduled_jobs(self) -> list:
        """
        Get list of all scheduled jobs.
        
        Returns:
            List of job information dictionaries
        """
        jobs = []
        for job in self.scheduler.get_jobs():
            jobs.append({
                "id": job.id,
                "name": job.name,
                "next_run_time": job.next_run_time.isoformat() if job.next_run_time else None,
                "trigger": str(job.trigger)
            })
        return jobs
    
    def reschedule_weekly_reports(
        self,
        day_of_week: str = 'fri',
        hour: int = 17,
        minute: int = 0
    ):
        """
        Reschedule the weekly report generation time.
        If the job doesn't exist, it will be created.

        Args:
            day_of_week: Day of week (mon, tue, wed, thu, fri, sat, sun)
            hour: Hour (0-23)
            minute: Minute (0-59)

        Returns:
            datetime: Next run time of the job
        """
        trigger = CronTrigger(
            day_of_week=day_of_week,
            hour=hour,
            minute=minute,
            timezone='UTC'
        )

        # Check if job exists
        existing_job = self.scheduler.get_job('weekly_reports')

        if existing_job:
            # Reschedule existing job
            self.scheduler.reschedule_job(
                job_id='weekly_reports',
                trigger=trigger
            )
            # Sanitize all user inputs before logging
            safe_day = sanitize_for_log(day_of_week).upper()
            safe_hour = sanitize_for_log(hour)
            safe_minute = sanitize_for_log(minute)
            logger.info(
                f"Rescheduled weekly reports to {safe_day} at {safe_hour}:{safe_minute} UTC"
            )
        else:
            # Add new job
            self.scheduler.add_job(
                func=self._generate_weekly_reports,
                trigger=trigger,
                id='weekly_reports',
                name='Generate Weekly Reports',
                replace_existing=True
            )
            # Sanitize all user inputs before logging
            safe_day = sanitize_for_log(day_of_week).upper()
            safe_hour = sanitize_for_log(hour)
            safe_minute = sanitize_for_log(minute)
            logger.info(
                f"Created weekly reports job scheduled for {safe_day} at {safe_hour}:{safe_minute} UTC"
            )

        # Get the next run time
        job = self.scheduler.get_job('weekly_reports')
        if job:
            # If scheduler is running, return the actual next_run_time
            if hasattr(job, 'next_run_time') and job.next_run_time:
                return job.next_run_time
            # If scheduler isn't running (e.g., in tests), compute next run time from trigger
            elif hasattr(job, 'trigger'):
                from datetime import datetime
                return job.trigger.get_next_fire_time(None, datetime.now(job.trigger.timezone))
        return None


# Global scheduler instance
scheduler_service = SchedulerService()