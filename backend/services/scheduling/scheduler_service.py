"""Service for manual weekly report generation.

Note: Automated scheduling has been moved to Redis Queue (RQ).
This service provides manual trigger endpoints only.
"""

from datetime import datetime, timedelta, timezone
from typing import Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from db.database import get_db
from models.project import Project, ProjectStatus
from services.summaries.summary_service_refactored import SummaryService
from utils.logger import get_logger
from utils.monitoring import monitor_operation

logger = get_logger(__name__)


class SchedulerService:
    """Service for manual weekly report generation."""

    def __init__(self):
        """Initialize the scheduler service."""
        self.summary_service = SummaryService()
        logger.info("Scheduler service initialized (manual triggers only)")
    
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
    


# Global scheduler instance
scheduler_service = SchedulerService()