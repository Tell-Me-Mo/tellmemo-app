"""Activity tracking service for the Meeting RAG System."""

from typing import List, Optional, Dict, Any
from datetime import datetime, timedelta
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, desc, and_
from uuid import UUID

from models.activity import Activity, ActivityType
from utils.logger import get_logger
from utils.monitoring import monitor_operation, monitor_sync_operation

logger = get_logger(__name__)


class ActivityService:
    """Service for managing project activities."""
    
    @staticmethod
    @monitor_operation(
        operation_name="create_activity",
        operation_type="database",
        capture_args=True,
        capture_result=False
    )
    async def create_activity(
        db: AsyncSession,
        project_id: UUID,
        activity_type: ActivityType,
        title: str,
        description: str,
        metadata: Optional[str] = None,
        user_id: Optional[str] = None,
        user_name: Optional[str] = None
    ) -> Activity:
        """Create a new activity record."""
        try:
            activity = Activity(
                project_id=project_id,
                type=activity_type,
                title=title,
                description=description,
                activity_metadata=metadata,
                user_id=user_id,
                user_name=user_name,
                timestamp=datetime.utcnow()
            )
            
            db.add(activity)
            await db.commit()
            await db.refresh(activity)
            
            logger.info(f"Created activity: {activity_type.value} for project {project_id}")
            return activity
            
        except Exception as e:
            logger.error(f"Error creating activity: {e}")
            await db.rollback()
            raise
    
    @staticmethod
    @monitor_operation(
        operation_name="get_project_activities",
        operation_type="database",
        capture_args=True,
        capture_result=True
    )
    async def get_project_activities(
        db: AsyncSession,
        project_id: UUID,
        organization_id: UUID,  # Added for multi-tenant support
        limit: int = 50,
        offset: int = 0,
        activity_type: Optional[ActivityType] = None,
        since: Optional[datetime] = None
    ) -> List[Activity]:
        """Get activities for a project with optional filtering."""
        try:
            query = select(Activity).where(Activity.project_id == project_id)
            
            if activity_type:
                query = query.where(Activity.type == activity_type)
            
            if since:
                query = query.where(Activity.timestamp >= since)
            
            query = query.order_by(desc(Activity.timestamp))
            query = query.limit(limit).offset(offset)
            
            result = await db.execute(query)
            activities = result.scalars().all()
            
            return activities
            
        except Exception as e:
            logger.error(f"Error fetching activities: {e}")
            raise
    
    @staticmethod
    @monitor_operation(
        operation_name="get_recent_activities",
        operation_type="database",
        capture_args=True,
        capture_result=True
    )
    async def get_recent_activities(
        db: AsyncSession,
        project_ids: List[UUID],
        organization_id: UUID,  # Added for multi-tenant support
        hours: int = 24,
        limit: int = 20
    ) -> List[Activity]:
        """Get recent activities across multiple projects."""
        try:
            since = datetime.utcnow() - timedelta(hours=hours)
            
            query = select(Activity).where(
                and_(
                    Activity.project_id.in_(project_ids),
                    Activity.timestamp >= since
                )
            )
            query = query.order_by(desc(Activity.timestamp))
            query = query.limit(limit)
            
            result = await db.execute(query)
            activities = result.scalars().all()
            
            return activities
            
        except Exception as e:
            logger.error(f"Error fetching recent activities: {e}")
            raise
    
    @staticmethod
    async def log_project_created(
        db: AsyncSession,
        project_id: UUID,
        project_name: str,
        created_by: Optional[str] = None,
        user_id: Optional[str] = None
    ) -> Activity:
        """Log project creation activity."""
        return await ActivityService.create_activity(
            db=db,
            project_id=project_id,
            activity_type=ActivityType.PROJECT_CREATED,
            title="Project created",
            description=f"New project '{project_name}' was created",
            user_name=created_by,
            user_id=user_id
        )
    
    @staticmethod
    async def log_content_uploaded(
        db: AsyncSession,
        project_id: UUID,
        content_title: str,
        content_type: str,
        user_name: Optional[str] = None,
        user_id: Optional[str] = None
    ) -> Activity:
        """Log content upload activity."""
        return await ActivityService.create_activity(
            db=db,
            project_id=project_id,
            activity_type=ActivityType.CONTENT_UPLOADED,
            title=f"{content_type.title()} uploaded",
            description=f"'{content_title}' was uploaded",
            metadata=content_type,
            user_name=user_name,
            user_id=user_id
        )
    
    @staticmethod
    async def log_summary_generated(
        db: AsyncSession,
        project_id: UUID,
        summary_type: str,
        summary_subject: str,
        user_name: Optional[str] = None,
        user_id: Optional[str] = None
    ) -> Activity:
        """Log summary generation activity."""
        return await ActivityService.create_activity(
            db=db,
            project_id=project_id,
            activity_type=ActivityType.SUMMARY_GENERATED,
            title=f"{summary_type.title()} summary generated",
            description=f"'{summary_subject}' was generated",
            metadata=summary_type,
            user_name=user_name,
            user_id=user_id
        )
    
    @staticmethod
    async def log_query_submitted(
        db: AsyncSession,
        project_id: UUID,
        query_text: str,
        user_name: Optional[str] = None,
        user_id: Optional[str] = None
    ) -> Activity:
        """Log query submission activity."""
        # Truncate query if too long
        display_query = query_text[:100] + "..." if len(query_text) > 100 else query_text

        return await ActivityService.create_activity(
            db=db,
            project_id=project_id,
            activity_type=ActivityType.QUERY_SUBMITTED,
            title="Query submitted",
            description=f"Question: {display_query}",
            user_name=user_name,
            user_id=user_id
        )
    
    @staticmethod
    async def log_project_updated(
        db: AsyncSession,
        project_id: UUID,
        project_name: str,
        changes: str,
        updated_by: Optional[str] = None,
        user_id: Optional[str] = None
    ) -> Activity:
        """Log project update activity."""
        return await ActivityService.create_activity(
            db=db,
            project_id=project_id,
            activity_type=ActivityType.PROJECT_UPDATED,
            title="Project updated",
            description=f"Project '{project_name}' was updated: {changes}",
            user_name=updated_by,
            user_id=user_id
        )
    
    @staticmethod
    async def log_project_deleted(
        db: AsyncSession,
        project_id: UUID,
        project_name: str,
        deleted_by: Optional[str] = None,
        user_id: Optional[str] = None
    ) -> Activity:
        """Log project deletion/archival activity."""
        return await ActivityService.create_activity(
            db=db,
            project_id=project_id,
            activity_type=ActivityType.PROJECT_DELETED,
            title="Project archived",
            description=f"Project '{project_name}' was archived",
            user_name=deleted_by,
            user_id=user_id
        )
    
    @staticmethod
    @monitor_operation(
        operation_name="delete_project_activities",
        operation_type="database",
        capture_args=True,
        capture_result=True
    )
    async def delete_project_activities(
        db: AsyncSession,
        project_id: UUID,
        organization_id: UUID  # Added for multi-tenant support
    ) -> int:
        """Delete all activities for a project."""
        try:
            query = select(Activity).where(Activity.project_id == project_id)
            result = await db.execute(query)
            activities = result.scalars().all()
            
            count = len(activities)
            for activity in activities:
                await db.delete(activity)
            
            await db.commit()
            logger.info(f"Deleted {count} activities for project {project_id}")
            
            return count
            
        except Exception as e:
            logger.error(f"Error deleting activities: {e}")
            await db.rollback()
            raise