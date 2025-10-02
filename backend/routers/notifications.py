"""API endpoints for notifications."""

from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, Body
from sqlalchemy.ext.asyncio import AsyncSession
from pydantic import BaseModel, Field
from datetime import datetime
import uuid

from db.database import get_db
from services.notifications.notification_service import NotificationService
from models.notification import (
    NotificationType,
    NotificationPriority,
    NotificationCategory
)
from dependencies.auth import get_current_user, get_current_organization
from models.user import User


# Pydantic models for request/response

class NotificationCreate(BaseModel):
    """Model for creating a notification."""
    title: str = Field(..., min_length=1, max_length=255)
    message: Optional[str] = None
    type: NotificationType = NotificationType.INFO
    priority: NotificationPriority = NotificationPriority.NORMAL
    category: NotificationCategory = NotificationCategory.OTHER
    entity_type: Optional[str] = None
    entity_id: Optional[str] = None
    action_url: Optional[str] = None
    action_label: Optional[str] = None
    metadata: Optional[dict] = None
    expires_in_hours: Optional[int] = None


class NotificationResponse(BaseModel):
    """Model for notification response."""
    id: str
    organization_id: Optional[str]
    user_id: str
    title: str
    message: Optional[str]
    type: str
    priority: str
    category: str
    entity_type: Optional[str]
    entity_id: Optional[str]
    is_read: bool
    read_at: Optional[datetime]
    is_archived: bool
    archived_at: Optional[datetime]
    action_url: Optional[str]
    action_label: Optional[str]
    metadata: dict
    created_at: datetime
    expires_at: Optional[datetime]

    class Config:
        from_attributes = True


class NotificationListResponse(BaseModel):
    """Model for notification list response."""
    notifications: List[NotificationResponse]
    total: int
    unread_count: int


class MarkReadRequest(BaseModel):
    """Model for marking notifications as read."""
    notification_ids: Optional[List[str]] = None
    mark_all: bool = False


class BulkNotificationCreate(BaseModel):
    """Model for creating bulk notifications."""
    user_ids: List[str]
    title: str = Field(..., min_length=1, max_length=255)
    message: Optional[str] = None
    type: NotificationType = NotificationType.INFO
    priority: NotificationPriority = NotificationPriority.NORMAL
    category: NotificationCategory = NotificationCategory.SYSTEM
    metadata: Optional[dict] = None


# Create router
router = APIRouter(prefix="/api/notifications", tags=["notifications"])


@router.get("/", response_model=NotificationListResponse)
async def get_notifications(
    is_read: Optional[bool] = Query(None, description="Filter by read status"),
    is_archived: bool = Query(False, description="Include archived notifications"),
    limit: int = Query(50, ge=1, le=100, description="Maximum number of results"),
    offset: int = Query(0, ge=0, description="Number of results to skip"),
    current_user: User = Depends(get_current_user),
    current_org_id: Optional[str] = Depends(get_current_organization),
    db: AsyncSession = Depends(get_db),
):
    """
    Get notifications for the current user.

    Args:
        is_read: Optional filter by read status
        is_archived: Include archived notifications (default: False)
        limit: Maximum number of results (1-100)
        offset: Number of results to skip
        current_user: Current authenticated user
        current_org_id: Current organization ID
        db: Database session

    Returns:
        NotificationListResponse with notifications and counts
    """
    service = NotificationService(db)

    notifications = await service.get_user_notifications(
        user_id=str(current_user.id),
        organization_id=current_org_id,
        is_read=is_read,
        is_archived=is_archived,
        limit=limit,
        offset=offset,
    )

    unread_count = await service.get_unread_count(
        user_id=str(current_user.id),
        organization_id=current_org_id,
    )

    # Convert to response models
    notification_responses = [
        NotificationResponse(
            id=str(n.id),
            organization_id=str(n.organization_id) if n.organization_id else None,
            user_id=str(n.user_id),
            title=n.title,
            message=n.message,
            type=n.type.value,
            priority=n.priority.value if n.priority else "normal",
            category=n.category.value if n.category else "other",
            entity_type=n.entity_type,
            entity_id=str(n.entity_id) if n.entity_id else None,
            is_read=n.is_read,
            read_at=n.read_at,
            is_archived=n.is_archived,
            archived_at=n.archived_at,
            action_url=n.action_url,
            action_label=n.action_label,
            metadata=n.extra_data or {},
            created_at=n.created_at,
            expires_at=n.expires_at,
        )
        for n in notifications
    ]

    return NotificationListResponse(
        notifications=notification_responses,
        total=len(notification_responses),
        unread_count=unread_count,
    )


@router.post("/", response_model=NotificationResponse)
async def create_notification(
    notification: NotificationCreate,
    current_user: User = Depends(get_current_user),
    current_org_id: Optional[str] = Depends(get_current_organization),
    db: AsyncSession = Depends(get_db),
):
    """
    Create a notification for the current user.

    This endpoint is mainly for testing. In production, notifications
    are typically created by backend services.

    Args:
        notification: Notification creation data
        current_user: Current authenticated user
        current_org_id: Current organization ID
        db: Database session

    Returns:
        Created notification
    """
    service = NotificationService(db)

    created = await service.create_notification(
        user_id=str(current_user.id),
        title=notification.title,
        message=notification.message,
        type=notification.type,
        priority=notification.priority,
        category=notification.category,
        organization_id=current_org_id,
        entity_type=notification.entity_type,
        entity_id=notification.entity_id,
        action_url=notification.action_url,
        action_label=notification.action_label,
        metadata=notification.metadata,
        expires_in_hours=notification.expires_in_hours,
    )

    return NotificationResponse(
        id=str(created.id),
        organization_id=str(created.organization_id) if created.organization_id else None,
        user_id=str(created.user_id),
        title=created.title,
        message=created.message,
        type=created.type.value,
        priority=created.priority.value,
        category=created.category.value,
        entity_type=created.entity_type,
        entity_id=str(created.entity_id) if created.entity_id else None,
        is_read=created.is_read,
        read_at=created.read_at,
        is_archived=created.is_archived,
        archived_at=created.archived_at,
        action_url=created.action_url,
        action_label=created.action_label,
        metadata=created.extra_data or {},
        created_at=created.created_at,
        expires_at=created.expires_at,
    )


@router.get("/unread-count")
async def get_unread_count(
    current_user: User = Depends(get_current_user),
    current_org_id: Optional[str] = Depends(get_current_organization),
    db: AsyncSession = Depends(get_db),
):
    """
    Get count of unread notifications.

    Args:
        current_user: Current authenticated user
        current_org_id: Current organization ID
        db: Database session

    Returns:
        Count of unread notifications
    """
    service = NotificationService(db)
    count = await service.get_unread_count(
        user_id=str(current_user.id),
        organization_id=current_org_id,
    )
    return {"unread_count": count}


@router.put("/{notification_id}/read")
async def mark_as_read(
    notification_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Mark a notification as read.

    Args:
        notification_id: Notification ID
        current_user: Current authenticated user
        db: Database session

    Returns:
        Success status
    """
    service = NotificationService(db)
    success = await service.mark_as_read(
        notification_id=notification_id,
        user_id=str(current_user.id),
    )

    if not success:
        raise HTTPException(status_code=404, detail="Notification not found")

    return {"success": True, "message": "Notification marked as read"}


@router.put("/mark-read")
async def mark_multiple_as_read(
    request: MarkReadRequest,
    current_user: User = Depends(get_current_user),
    current_org_id: Optional[str] = Depends(get_current_organization),
    db: AsyncSession = Depends(get_db),
):
    """
    Mark multiple notifications as read or mark all as read.

    Args:
        request: Request containing notification IDs or mark_all flag
        current_user: Current authenticated user
        current_org_id: Current organization ID
        db: Database session

    Returns:
        Number of notifications marked as read
    """
    service = NotificationService(db)

    if request.mark_all:
        count = await service.mark_all_as_read(
            user_id=str(current_user.id),
            organization_id=current_org_id,
        )
    elif request.notification_ids:
        count = 0
        for notification_id in request.notification_ids:
            success = await service.mark_as_read(
                notification_id=notification_id,
                user_id=str(current_user.id),
            )
            if success:
                count += 1
    else:
        raise HTTPException(
            status_code=400,
            detail="Either notification_ids or mark_all must be provided"
        )

    return {"success": True, "count": count, "message": f"Marked {count} notifications as read"}


@router.put("/{notification_id}/archive")
async def archive_notification(
    notification_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Archive a notification.

    Args:
        notification_id: Notification ID
        current_user: Current authenticated user
        db: Database session

    Returns:
        Success status
    """
    service = NotificationService(db)
    success = await service.archive_notification(
        notification_id=notification_id,
        user_id=str(current_user.id),
    )

    if not success:
        raise HTTPException(status_code=404, detail="Notification not found")

    return {"success": True, "message": "Notification archived"}


@router.delete("/{notification_id}")
async def delete_notification(
    notification_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Delete a notification.

    Args:
        notification_id: Notification ID
        current_user: Current authenticated user
        db: Database session

    Returns:
        Success status
    """
    service = NotificationService(db)
    success = await service.delete_notification(
        notification_id=notification_id,
        user_id=str(current_user.id),
    )

    if not success:
        raise HTTPException(status_code=404, detail="Notification not found")

    return {"success": True, "message": "Notification deleted"}


# Admin endpoints (for system notifications)

@router.post("/bulk", response_model=List[NotificationResponse])
async def create_bulk_notifications(
    request: BulkNotificationCreate,
    current_user: User = Depends(get_current_user),
    current_org_id: Optional[str] = Depends(get_current_organization),
    db: AsyncSession = Depends(get_db),
):
    """
    Create notifications for multiple users (admin only).

    Args:
        request: Bulk notification creation data
        current_user: Current authenticated user (must be admin)
        current_org_id: Current organization ID
        db: Database session

    Returns:
        List of created notifications
    """
    # TODO: Check if user is admin
    # For now, we'll allow any authenticated user to create bulk notifications

    service = NotificationService(db)

    notifications = await service.create_bulk_notifications(
        user_ids=request.user_ids,
        title=request.title,
        message=request.message,
        type=request.type,
        priority=request.priority,
        category=request.category,
        organization_id=current_org_id,
        metadata=request.metadata,
    )

    return [
        NotificationResponse(
            id=str(n.id),
            organization_id=str(n.organization_id) if n.organization_id else None,
            user_id=str(n.user_id),
            title=n.title,
            message=n.message,
            type=n.type.value,
            priority=n.priority.value,
            category=n.category.value,
            entity_type=n.entity_type,
            entity_id=str(n.entity_id) if n.entity_id else None,
            is_read=n.is_read,
            read_at=n.read_at,
            is_archived=n.is_archived,
            archived_at=n.archived_at,
            action_url=n.action_url,
            action_label=n.action_label,
            metadata=n.extra_data or {},
            created_at=n.created_at,
            expires_at=n.expires_at,
        )
        for n in notifications
    ]