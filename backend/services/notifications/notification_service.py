"""Notification service for managing user notifications."""

import uuid
from typing import List, Optional, Dict, Any
from datetime import datetime, timedelta
from sqlalchemy import select, update, delete, and_, or_, func
from sqlalchemy.orm import Session
from sqlalchemy.ext.asyncio import AsyncSession

from models.notification import (
    Notification,
    NotificationType,
    NotificationPriority,
    NotificationCategory
)
from models.user import User
from models.organization import Organization


class NotificationService:
    """Service for managing notifications."""

    def __init__(self, db_session: AsyncSession):
        """Initialize notification service with database session."""
        self.db = db_session

    async def create_notification(
        self,
        user_id: str,
        title: str,
        message: Optional[str] = None,
        type: NotificationType = NotificationType.INFO,
        priority: NotificationPriority = NotificationPriority.NORMAL,
        category: NotificationCategory = NotificationCategory.OTHER,
        organization_id: Optional[str] = None,
        entity_type: Optional[str] = None,
        entity_id: Optional[str] = None,
        action_url: Optional[str] = None,
        action_label: Optional[str] = None,
        metadata: Optional[Dict[str, Any]] = None,
        expires_in_hours: Optional[int] = None,
    ) -> Notification:
        """
        Create a new notification.

        Args:
            user_id: ID of the user to notify
            title: Notification title
            message: Notification message
            type: Type of notification
            priority: Priority level
            category: Category of notification
            organization_id: Optional organization ID
            entity_type: Type of related entity (project, task, etc)
            entity_id: ID of related entity
            action_url: URL for action button
            action_label: Label for action button
            metadata: Additional metadata
            expires_in_hours: Hours until notification expires

        Returns:
            Created notification
        """
        notification = Notification(
            id=uuid.uuid4(),
            user_id=uuid.UUID(user_id),
            organization_id=uuid.UUID(organization_id) if organization_id else None,
            title=title,
            message=message,
            type=type,
            priority=priority,
            category=category,
            entity_type=entity_type,
            entity_id=uuid.UUID(entity_id) if entity_id else None,
            action_url=action_url,
            action_label=action_label,
            extra_data=metadata or {},
            expires_at=datetime.utcnow() + timedelta(hours=expires_in_hours) if expires_in_hours else None,
            delivered_channels=["in_app"],
            in_app_delivered_at=datetime.utcnow()
        )

        self.db.add(notification)
        await self.db.commit()
        await self.db.refresh(notification)

        # TODO: Send real-time notification via WebSocket
        await self._send_realtime_notification(notification)

        return notification

    async def get_user_notifications(
        self,
        user_id: str,
        organization_id: Optional[str] = None,
        is_read: Optional[bool] = None,
        is_archived: Optional[bool] = False,
        limit: int = 50,
        offset: int = 0,
    ) -> List[Notification]:
        """
        Get notifications for a user.

        Args:
            user_id: User ID
            organization_id: Optional filter by organization
            is_read: Optional filter by read status
            is_archived: Filter by archived status (default: False)
            limit: Maximum number of results
            offset: Number of results to skip

        Returns:
            List of notifications
        """
        query = select(Notification).where(
            Notification.user_id == uuid.UUID(user_id)
        )

        if organization_id:
            query = query.where(Notification.organization_id == uuid.UUID(organization_id))

        if is_read is not None:
            query = query.where(Notification.is_read == is_read)

        query = query.where(Notification.is_archived == is_archived)

        # Filter out expired notifications
        query = query.where(
            or_(
                Notification.expires_at == None,
                Notification.expires_at > datetime.utcnow()
            )
        )

        query = query.order_by(Notification.created_at.desc())
        query = query.limit(limit).offset(offset)

        result = await self.db.execute(query)
        return result.scalars().all()

    async def get_unread_count(
        self,
        user_id: str,
        organization_id: Optional[str] = None,
    ) -> int:
        """
        Get count of unread notifications for a user.

        Args:
            user_id: User ID
            organization_id: Optional filter by organization

        Returns:
            Count of unread notifications
        """
        query = select(func.count(Notification.id)).where(
            and_(
                Notification.user_id == uuid.UUID(user_id),
                Notification.is_read == False,
                Notification.is_archived == False,
                or_(
                    Notification.expires_at == None,
                    Notification.expires_at > datetime.utcnow()
                )
            )
        )

        if organization_id:
            query = query.where(Notification.organization_id == uuid.UUID(organization_id))

        result = await self.db.execute(query)
        return result.scalar() or 0

    async def mark_as_read(
        self,
        notification_id: str,
        user_id: str,
    ) -> bool:
        """
        Mark a notification as read.

        Args:
            notification_id: Notification ID
            user_id: User ID (for authorization)

        Returns:
            True if successful, False otherwise
        """
        result = await self.db.execute(
            update(Notification)
            .where(
                and_(
                    Notification.id == uuid.UUID(notification_id),
                    Notification.user_id == uuid.UUID(user_id)
                )
            )
            .values(
                is_read=True,
                read_at=datetime.utcnow()
            )
        )
        await self.db.commit()
        return result.rowcount > 0

    async def mark_all_as_read(
        self,
        user_id: str,
        organization_id: Optional[str] = None,
    ) -> int:
        """
        Mark all notifications as read for a user.

        Args:
            user_id: User ID
            organization_id: Optional filter by organization

        Returns:
            Number of notifications marked as read
        """
        query = update(Notification).where(
            and_(
                Notification.user_id == uuid.UUID(user_id),
                Notification.is_read == False,
                Notification.is_archived == False
            )
        ).values(
            is_read=True,
            read_at=datetime.utcnow()
        )

        if organization_id:
            query = query.where(Notification.organization_id == uuid.UUID(organization_id))

        result = await self.db.execute(query)
        await self.db.commit()
        return result.rowcount

    async def archive_notification(
        self,
        notification_id: str,
        user_id: str,
    ) -> bool:
        """
        Archive a notification.

        Args:
            notification_id: Notification ID
            user_id: User ID (for authorization)

        Returns:
            True if successful, False otherwise
        """
        result = await self.db.execute(
            update(Notification)
            .where(
                and_(
                    Notification.id == uuid.UUID(notification_id),
                    Notification.user_id == uuid.UUID(user_id)
                )
            )
            .values(
                is_archived=True,
                archived_at=datetime.utcnow()
            )
        )
        await self.db.commit()
        return result.rowcount > 0

    async def delete_notification(
        self,
        notification_id: str,
        user_id: str,
    ) -> bool:
        """
        Delete a notification.

        Args:
            notification_id: Notification ID
            user_id: User ID (for authorization)

        Returns:
            True if successful, False otherwise
        """
        result = await self.db.execute(
            delete(Notification).where(
                and_(
                    Notification.id == uuid.UUID(notification_id),
                    Notification.user_id == uuid.UUID(user_id)
                )
            )
        )
        await self.db.commit()
        return result.rowcount > 0

    async def cleanup_expired_notifications(self) -> int:
        """
        Delete expired notifications.

        Returns:
            Number of notifications deleted
        """
        result = await self.db.execute(
            delete(Notification).where(
                and_(
                    Notification.expires_at != None,
                    Notification.expires_at < datetime.utcnow()
                )
            )
        )
        await self.db.commit()
        return result.rowcount

    async def create_bulk_notifications(
        self,
        user_ids: List[str],
        title: str,
        message: Optional[str] = None,
        type: NotificationType = NotificationType.INFO,
        priority: NotificationPriority = NotificationPriority.NORMAL,
        category: NotificationCategory = NotificationCategory.SYSTEM,
        organization_id: Optional[str] = None,
        metadata: Optional[Dict[str, Any]] = None,
    ) -> List[Notification]:
        """
        Create notifications for multiple users.

        Args:
            user_ids: List of user IDs
            title: Notification title
            message: Notification message
            type: Type of notification
            priority: Priority level
            category: Category of notification
            organization_id: Optional organization ID
            metadata: Additional metadata

        Returns:
            List of created notifications
        """
        notifications = []
        for user_id in user_ids:
            notification = Notification(
                id=uuid.uuid4(),
                user_id=uuid.UUID(user_id),
                organization_id=uuid.UUID(organization_id) if organization_id else None,
                title=title,
                message=message,
                type=type,
                priority=priority,
                category=category,
                extra_data=metadata or {},
                delivered_channels=["in_app"],
                in_app_delivered_at=datetime.utcnow()
            )
            notifications.append(notification)
            self.db.add(notification)

        await self.db.commit()

        # Refresh all notifications
        for notification in notifications:
            await self.db.refresh(notification)

        # Send real-time notifications
        for notification in notifications:
            await self._send_realtime_notification(notification)

        return notifications

    async def _send_realtime_notification(self, notification: Notification):
        """
        Send real-time notification via WebSocket.

        Args:
            notification: Notification to send
        """
        # Import here to avoid circular dependency
        try:
            from routers.websocket_notifications import broadcast_new_notification
            import asyncio

            # Create task to broadcast notification asynchronously
            asyncio.create_task(broadcast_new_notification(notification))
        except ImportError:
            # WebSocket module not available
            pass
        except Exception as e:
            # Log error but don't fail notification creation
            import logging
            logger = logging.getLogger(__name__)
            logger.error(f"Failed to broadcast notification via WebSocket: {e}")

    # Notification factory methods for common scenarios

    async def notify_task_assigned(
        self,
        user_id: str,
        task_title: str,
        task_id: str,
        project_name: str,
        organization_id: str,
    ) -> Notification:
        """Create notification for task assignment."""
        return await self.create_notification(
            user_id=user_id,
            title="Task Assigned",
            message=f'You have been assigned to task "{task_title}" in project "{project_name}"',
            type=NotificationType.INFO,
            priority=NotificationPriority.NORMAL,
            category=NotificationCategory.TASK_ASSIGNED,
            organization_id=organization_id,
            entity_type="task",
            entity_id=task_id,
            action_url=f"/tasks/{task_id}",
            action_label="View Task"
        )

    async def notify_summary_ready(
        self,
        user_id: str,
        summary_type: str,
        entity_name: str,
        summary_id: str,
        organization_id: str,
    ) -> Notification:
        """Create notification for summary generation completion."""
        return await self.create_notification(
            user_id=user_id,
            title="Summary Generated",
            message=f'{summary_type} summary for "{entity_name}" is ready',
            type=NotificationType.SUCCESS,
            priority=NotificationPriority.NORMAL,
            category=NotificationCategory.SUMMARY_GENERATED,
            organization_id=organization_id,
            entity_type="summary",
            entity_id=summary_id,
            action_url=f"/summaries/{summary_id}",
            action_label="View Summary"
        )

    async def notify_meeting_ready(
        self,
        user_id: str,
        meeting_title: str,
        content_id: str,
        organization_id: str,
    ) -> Notification:
        """Create notification for meeting recording ready."""
        return await self.create_notification(
            user_id=user_id,
            title="Meeting Recording Ready",
            message=f'Recording for "{meeting_title}" has been processed',
            type=NotificationType.SUCCESS,
            priority=NotificationPriority.NORMAL,
            category=NotificationCategory.MEETING_READY,
            organization_id=organization_id,
            entity_type="content",
            entity_id=content_id,
            action_url=f"/content/{content_id}",
            action_label="View Recording"
        )

    async def notify_risk_created(
        self,
        user_id: str,
        risk_title: str,
        risk_id: str,
        project_name: str,
        organization_id: str,
    ) -> Notification:
        """Create notification for new risk."""
        return await self.create_notification(
            user_id=user_id,
            title="New Risk Identified",
            message=f'A new risk "{risk_title}" has been identified in project "{project_name}"',
            type=NotificationType.WARNING,
            priority=NotificationPriority.HIGH,
            category=NotificationCategory.RISK_CREATED,
            organization_id=organization_id,
            entity_type="risk",
            entity_id=risk_id,
            action_url=f"/risks/{risk_id}",
            action_label="View Risk"
        )