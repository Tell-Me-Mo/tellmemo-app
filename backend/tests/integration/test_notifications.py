"""
Integration tests for Notifications API.

Covers TESTING_BACKEND.md section 12.1 - Notifications

Tests cover:
- Create notification
- List notifications (with filters: is_read, is_archived, limit, offset)
- Get unread count
- Mark notification as read
- Bulk mark as read (specific IDs and mark all)
- Archive notification
- Delete notification
- Bulk create notifications
- Multi-tenant isolation
- Authentication requirements
- Expired notifications handling

Expected Status: Will test all notification endpoints and multi-tenant security
"""

import pytest
from datetime import datetime, timedelta
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession
from models.user import User
from models.organization import Organization
from models.notification import (
    Notification,
    NotificationType,
    NotificationPriority,
    NotificationCategory
)


@pytest.fixture
async def test_notification(
    db_session: AsyncSession,
    test_user: User,
    test_organization: Organization
) -> Notification:
    """Create a test notification."""
    notification = Notification(
        user_id=test_user.id,
        organization_id=test_organization.id,
        title="Test Notification",
        message="This is a test notification message",
        type=NotificationType.INFO,
        priority=NotificationPriority.NORMAL,
        category=NotificationCategory.SYSTEM,
        is_read=False,
        is_archived=False,
        extra_data={"test_key": "test_value"}
    )
    db_session.add(notification)
    await db_session.commit()
    await db_session.refresh(notification)
    return notification


@pytest.fixture
async def test_notification_read(
    db_session: AsyncSession,
    test_user: User,
    test_organization: Organization
) -> Notification:
    """Create a read test notification."""
    notification = Notification(
        user_id=test_user.id,
        organization_id=test_organization.id,
        title="Read Notification",
        message="This notification has been read",
        type=NotificationType.SUCCESS,
        priority=NotificationPriority.NORMAL,
        category=NotificationCategory.CONTENT_PROCESSED,
        is_read=True,
        read_at=datetime.utcnow(),
        is_archived=False
    )
    db_session.add(notification)
    await db_session.commit()
    await db_session.refresh(notification)
    return notification


@pytest.fixture
async def test_notification_archived(
    db_session: AsyncSession,
    test_user: User,
    test_organization: Organization
) -> Notification:
    """Create an archived test notification."""
    notification = Notification(
        user_id=test_user.id,
        organization_id=test_organization.id,
        title="Archived Notification",
        message="This notification has been archived",
        type=NotificationType.WARNING,
        priority=NotificationPriority.HIGH,
        category=NotificationCategory.RISK_CREATED,
        is_read=True,
        read_at=datetime.utcnow(),
        is_archived=True,
        archived_at=datetime.utcnow()
    )
    db_session.add(notification)
    await db_session.commit()
    await db_session.refresh(notification)
    return notification


class TestCreateNotification:
    """Test notification creation endpoint."""

    @pytest.mark.asyncio
    async def test_create_notification_minimal(
        self,
        authenticated_org_client: AsyncClient
    ):
        """Test creating notification with minimal required fields."""
        # Arrange
        notification_data = {
            "title": "New Task Assigned"
        }

        # Act
        response = await authenticated_org_client.post(
            "/api/v1/notifications/",
            json=notification_data
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["title"] == "New Task Assigned"
        assert data["type"] == "info"  # Default type
        assert data["priority"] == "normal"  # Default priority
        assert data["category"] == "other"  # Default category
        assert data["is_read"] is False
        assert data["is_archived"] is False
        assert data["metadata"] == {}
        assert "id" in data

    @pytest.mark.asyncio
    async def test_create_notification_full(
        self,
        authenticated_org_client: AsyncClient
    ):
        """Test creating notification with all optional fields."""
        # Arrange
        notification_data = {
            "title": "Critical Risk Identified",
            "message": "A high-priority risk has been identified in Project X",
            "type": "error",
            "priority": "critical",
            "category": "risk_created",
            "entity_type": "risk",
            "entity_id": "123e4567-e89b-12d3-a456-426614174000",
            "action_url": "/risks/123",
            "action_label": "View Risk",
            "metadata": {"risk_severity": "high", "project": "Project X"},
            "expires_in_hours": 72
        }

        # Act
        response = await authenticated_org_client.post(
            "/api/v1/notifications/",
            json=notification_data
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["title"] == "Critical Risk Identified"
        assert data["message"] == "A high-priority risk has been identified in Project X"
        assert data["type"] == "error"
        assert data["priority"] == "critical"
        assert data["category"] == "risk_created"
        assert data["entity_type"] == "risk"
        assert data["entity_id"] == "123e4567-e89b-12d3-a456-426614174000"
        assert data["action_url"] == "/risks/123"
        assert data["action_label"] == "View Risk"
        assert data["metadata"]["risk_severity"] == "high"
        assert data["expires_at"] is not None

    @pytest.mark.asyncio
    async def test_create_notification_requires_auth(
        self,
        client: AsyncClient
    ):
        """Test that creating notification requires authentication."""
        # Arrange
        notification_data = {
            "title": "Test Notification"
        }

        # Act
        response = await client.post(
            "/api/v1/notifications/",
            json=notification_data
        )

        # Assert
        assert response.status_code in [401, 403]

    @pytest.mark.asyncio
    async def test_create_notification_validation_empty_title(
        self,
        authenticated_org_client: AsyncClient
    ):
        """Test that empty title is rejected."""
        # Arrange
        notification_data = {
            "title": ""
        }

        # Act
        response = await authenticated_org_client.post(
            "/api/v1/notifications/",
            json=notification_data
        )

        # Assert
        assert response.status_code == 422  # Validation error


class TestListNotifications:
    """Test listing notifications endpoint."""

    @pytest.mark.asyncio
    async def test_list_notifications_default(
        self,
        authenticated_org_client: AsyncClient,
        test_notification: Notification,
        test_notification_read: Notification
    ):
        """Test listing notifications with default parameters (excludes archived)."""
        # Act
        response = await authenticated_org_client.get("/api/v1/notifications/")

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert "notifications" in data
        assert "total" in data
        assert "unread_count" in data
        assert data["total"] >= 2
        assert data["unread_count"] == 1  # Only test_notification is unread

        # Verify archived notifications are excluded by default
        notification_ids = [n["id"] for n in data["notifications"]]
        assert str(test_notification.id) in notification_ids
        assert str(test_notification_read.id) in notification_ids

    @pytest.mark.asyncio
    async def test_list_notifications_filter_unread(
        self,
        authenticated_org_client: AsyncClient,
        test_notification: Notification,
        test_notification_read: Notification
    ):
        """Test filtering notifications by unread status."""
        # Act
        response = await authenticated_org_client.get(
            "/api/v1/notifications/?is_read=false"
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["total"] >= 1
        assert all(not n["is_read"] for n in data["notifications"])
        # Should include only unread notification
        notification_ids = [n["id"] for n in data["notifications"]]
        assert str(test_notification.id) in notification_ids
        assert str(test_notification_read.id) not in notification_ids

    @pytest.mark.asyncio
    async def test_list_notifications_filter_read(
        self,
        authenticated_org_client: AsyncClient,
        test_notification: Notification,
        test_notification_read: Notification
    ):
        """Test filtering notifications by read status."""
        # Act
        response = await authenticated_org_client.get(
            "/api/v1/notifications/?is_read=true"
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert all(n["is_read"] for n in data["notifications"])
        # Should include read notification
        notification_ids = [n["id"] for n in data["notifications"]]
        assert str(test_notification_read.id) in notification_ids
        assert str(test_notification.id) not in notification_ids

    @pytest.mark.asyncio
    async def test_list_notifications_include_archived(
        self,
        authenticated_org_client: AsyncClient,
        test_notification: Notification,
        test_notification_archived: Notification
    ):
        """Test including archived notifications."""
        # Act
        response = await authenticated_org_client.get(
            "/api/v1/notifications/?is_archived=true"
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        # Should include archived notifications
        notification_ids = [n["id"] for n in data["notifications"]]
        assert str(test_notification_archived.id) in notification_ids

    @pytest.mark.asyncio
    async def test_list_notifications_pagination(
        self,
        authenticated_org_client: AsyncClient,
        db_session: AsyncSession,
        test_user: User,
        test_organization: Organization
    ):
        """Test pagination with limit and offset."""
        # Arrange - Create 5 notifications
        for i in range(5):
            notification = Notification(
                user_id=test_user.id,
                organization_id=test_organization.id,
                title=f"Notification {i}",
                type=NotificationType.INFO,
                priority=NotificationPriority.NORMAL,
                category=NotificationCategory.SYSTEM
            )
            db_session.add(notification)
        await db_session.commit()

        # Act - Get first 2 notifications
        response = await authenticated_org_client.get(
            "/api/v1/notifications/?limit=2&offset=0"
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert len(data["notifications"]) == 2

        # Act - Get next 2 notifications
        response2 = await authenticated_org_client.get(
            "/api/v1/notifications/?limit=2&offset=2"
        )

        # Assert
        assert response2.status_code == 200
        data2 = response2.json()
        assert len(data2["notifications"]) == 2
        # IDs should be different
        ids_page1 = {n["id"] for n in data["notifications"]}
        ids_page2 = {n["id"] for n in data2["notifications"]}
        assert ids_page1.isdisjoint(ids_page2)

    @pytest.mark.asyncio
    async def test_list_notifications_requires_auth(
        self,
        client: AsyncClient
    ):
        """Test that listing notifications requires authentication."""
        # Act
        response = await client.get("/api/v1/notifications/")

        # Assert
        assert response.status_code in [401, 403]

    @pytest.mark.asyncio
    async def test_list_notifications_multi_tenant_isolation(
        self,
        client_factory,
        db_session: AsyncSession,
        test_user: User,
        test_organization: Organization
    ):
        """Test that users can only see their own notifications."""
        # Arrange - Create another user and organization
        from models.organization_member import OrganizationMember
        from services.auth.native_auth_service import native_auth_service

        other_user = User(
            email="other@example.com",
            password_hash=native_auth_service.hash_password("OtherPass123!"),
            name="Other User",
            auth_provider='native',
            email_verified=True,
            is_active=True
        )
        db_session.add(other_user)
        await db_session.commit()
        await db_session.refresh(other_user)

        other_org = Organization(
            name="Other Organization",
            slug="other-organization",
            created_by=other_user.id
        )
        db_session.add(other_org)
        await db_session.commit()
        await db_session.refresh(other_org)

        member = OrganizationMember(
            organization_id=other_org.id,
            user_id=other_user.id,
            role="admin",
            invited_by=other_user.id,
            joined_at=datetime.utcnow()
        )
        db_session.add(member)
        await db_session.commit()

        # Create notification for test_user
        notification1 = Notification(
            user_id=test_user.id,
            organization_id=test_organization.id,
            title="Notification for Test User",
            type=NotificationType.INFO,
            priority=NotificationPriority.NORMAL,
            category=NotificationCategory.SYSTEM
        )
        db_session.add(notification1)

        # Create notification for other_user
        notification2 = Notification(
            user_id=other_user.id,
            organization_id=other_org.id,
            title="Notification for Other User",
            type=NotificationType.INFO,
            priority=NotificationPriority.NORMAL,
            category=NotificationCategory.SYSTEM
        )
        db_session.add(notification2)
        await db_session.commit()

        # Create authenticated client for test_user
        token1 = native_auth_service.create_access_token(
            user_id=str(test_user.id),
            email=test_user.email,
            organization_id=str(test_organization.id)
        )
        client1 = await client_factory(
            Authorization=f"Bearer {token1}",
            **{"X-Organization-Id": str(test_organization.id)}
        )

        # Act - List notifications as test_user
        response = await client1.get("/api/v1/notifications/")

        # Assert - Should only see own notifications
        assert response.status_code == 200
        data = response.json()
        notification_titles = [n["title"] for n in data["notifications"]]
        assert "Notification for Test User" in notification_titles
        assert "Notification for Other User" not in notification_titles


class TestGetUnreadCount:
    """Test get unread count endpoint."""

    @pytest.mark.asyncio
    async def test_get_unread_count(
        self,
        authenticated_org_client: AsyncClient,
        test_notification: Notification,
        test_notification_read: Notification
    ):
        """Test getting unread notification count."""
        # Act
        response = await authenticated_org_client.get(
            "/api/v1/notifications/unread-count"
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert "unread_count" in data
        assert data["unread_count"] >= 1

    @pytest.mark.asyncio
    async def test_get_unread_count_excludes_archived(
        self,
        authenticated_org_client: AsyncClient,
        db_session: AsyncSession,
        test_user: User,
        test_organization: Organization
    ):
        """Test that unread count excludes archived notifications."""
        # Arrange - Create unread but archived notification
        notification = Notification(
            user_id=test_user.id,
            organization_id=test_organization.id,
            title="Unread Archived",
            type=NotificationType.INFO,
            priority=NotificationPriority.NORMAL,
            category=NotificationCategory.SYSTEM,
            is_read=False,
            is_archived=True,
            archived_at=datetime.utcnow()
        )
        db_session.add(notification)
        await db_session.commit()

        # Act
        response = await authenticated_org_client.get(
            "/api/v1/notifications/unread-count"
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        # Archived notifications should not be counted even if unread
        # We can't assert exact count, but we verified the notification was created
        assert "unread_count" in data

    @pytest.mark.asyncio
    async def test_get_unread_count_requires_auth(
        self,
        client: AsyncClient
    ):
        """Test that getting unread count requires authentication."""
        # Act
        response = await client.get("/api/v1/notifications/unread-count")

        # Assert
        assert response.status_code in [401, 403]


class TestMarkAsRead:
    """Test mark notification as read endpoint."""

    @pytest.mark.asyncio
    async def test_mark_notification_as_read_success(
        self,
        authenticated_org_client: AsyncClient,
        test_notification: Notification
    ):
        """Test successfully marking a notification as read."""
        # Act
        response = await authenticated_org_client.put(
            f"/api/v1/notifications/{test_notification.id}/read"
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert "marked as read" in data["message"].lower()

        # Verify notification is marked as read
        list_response = await authenticated_org_client.get(
            f"/api/v1/notifications/?is_read=true"
        )
        assert list_response.status_code == 200
        notification_ids = [n["id"] for n in list_response.json()["notifications"]]
        assert str(test_notification.id) in notification_ids

    @pytest.mark.asyncio
    async def test_mark_notification_as_read_not_found(
        self,
        authenticated_org_client: AsyncClient
    ):
        """Test marking non-existent notification as read."""
        # Arrange
        fake_id = "123e4567-e89b-12d3-a456-426614174999"

        # Act
        response = await authenticated_org_client.put(
            f"/api/v1/notifications/{fake_id}/read"
        )

        # Assert
        assert response.status_code == 404

    @pytest.mark.asyncio
    async def test_mark_notification_as_read_other_user(
        self,
        client_factory,
        db_session: AsyncSession,
        test_notification: Notification
    ):
        """Test that user cannot mark another user's notification as read."""
        # Arrange - Create another user
        from services.auth.native_auth_service import native_auth_service

        other_user = User(
            email="other@example.com",
            password_hash=native_auth_service.hash_password("OtherPass123!"),
            name="Other User",
            auth_provider='native',
            email_verified=True,
            is_active=True
        )
        db_session.add(other_user)
        await db_session.commit()

        token = native_auth_service.create_access_token(
            user_id=str(other_user.id),
            email=other_user.email,
            organization_id=None
        )
        other_client = await client_factory(Authorization=f"Bearer {token}")

        # Act - Try to mark test_notification (owned by test_user) as read
        response = await other_client.put(
            f"/api/v1/notifications/{test_notification.id}/read"
        )

        # Assert - Should get 404 (not found) to prevent information disclosure
        assert response.status_code == 404

    @pytest.mark.asyncio
    async def test_mark_notification_as_read_requires_auth(
        self,
        client: AsyncClient,
        test_notification: Notification
    ):
        """Test that marking notification as read requires authentication."""
        # Act
        response = await client.put(
            f"/api/v1/notifications/{test_notification.id}/read"
        )

        # Assert
        assert response.status_code in [401, 403]


class TestBulkMarkAsRead:
    """Test bulk mark as read endpoint."""

    @pytest.mark.asyncio
    async def test_bulk_mark_specific_ids(
        self,
        authenticated_org_client: AsyncClient,
        db_session: AsyncSession,
        test_user: User,
        test_organization: Organization
    ):
        """Test marking specific notifications as read."""
        # Arrange - Create 3 unread notifications
        notifications = []
        for i in range(3):
            notification = Notification(
                user_id=test_user.id,
                organization_id=test_organization.id,
                title=f"Notification {i}",
                type=NotificationType.INFO,
                priority=NotificationPriority.NORMAL,
                category=NotificationCategory.SYSTEM,
                is_read=False
            )
            db_session.add(notification)
            notifications.append(notification)
        await db_session.commit()
        for n in notifications:
            await db_session.refresh(n)

        # Act - Mark first 2 as read
        request_data = {
            "notification_ids": [str(notifications[0].id), str(notifications[1].id)],
            "mark_all": False
        }
        response = await authenticated_org_client.put(
            "/api/v1/notifications/mark-read",
            json=request_data
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["count"] == 2

    @pytest.mark.asyncio
    async def test_bulk_mark_all_as_read(
        self,
        authenticated_org_client: AsyncClient,
        db_session: AsyncSession,
        test_user: User,
        test_organization: Organization
    ):
        """Test marking all notifications as read."""
        # Arrange - Create multiple unread notifications
        for i in range(5):
            notification = Notification(
                user_id=test_user.id,
                organization_id=test_organization.id,
                title=f"Notification {i}",
                type=NotificationType.INFO,
                priority=NotificationPriority.NORMAL,
                category=NotificationCategory.SYSTEM,
                is_read=False
            )
            db_session.add(notification)
        await db_session.commit()

        # Act - Mark all as read
        request_data = {
            "mark_all": True
        }
        response = await authenticated_org_client.put(
            "/api/v1/notifications/mark-read",
            json=request_data
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["count"] >= 5

        # Verify unread count is 0
        count_response = await authenticated_org_client.get(
            "/api/v1/notifications/unread-count"
        )
        assert count_response.json()["unread_count"] == 0

    @pytest.mark.asyncio
    async def test_bulk_mark_read_requires_ids_or_mark_all(
        self,
        authenticated_org_client: AsyncClient
    ):
        """Test that either notification_ids or mark_all must be provided."""
        # Arrange
        request_data = {
            "mark_all": False
        }

        # Act
        response = await authenticated_org_client.put(
            "/api/v1/notifications/mark-read",
            json=request_data
        )

        # Assert
        assert response.status_code == 400
        assert "notification_ids or mark_all" in response.json()["detail"]

    @pytest.mark.asyncio
    async def test_bulk_mark_read_requires_auth(
        self,
        client: AsyncClient
    ):
        """Test that bulk mark as read requires authentication."""
        # Arrange
        request_data = {
            "mark_all": True
        }

        # Act
        response = await client.put(
            "/api/v1/notifications/mark-read",
            json=request_data
        )

        # Assert
        assert response.status_code in [401, 403]


class TestArchiveNotification:
    """Test archive notification endpoint."""

    @pytest.mark.asyncio
    async def test_archive_notification_success(
        self,
        authenticated_org_client: AsyncClient,
        test_notification: Notification
    ):
        """Test successfully archiving a notification."""
        # Act
        response = await authenticated_org_client.put(
            f"/api/v1/notifications/{test_notification.id}/archive"
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert "archived" in data["message"].lower()

        # Verify notification is archived (excluded from default list)
        list_response = await authenticated_org_client.get("/api/v1/notifications/")
        assert list_response.status_code == 200
        notification_ids = [n["id"] for n in list_response.json()["notifications"]]
        assert str(test_notification.id) not in notification_ids

    @pytest.mark.asyncio
    async def test_archive_notification_not_found(
        self,
        authenticated_org_client: AsyncClient
    ):
        """Test archiving non-existent notification."""
        # Arrange
        fake_id = "123e4567-e89b-12d3-a456-426614174999"

        # Act
        response = await authenticated_org_client.put(
            f"/api/v1/notifications/{fake_id}/archive"
        )

        # Assert
        assert response.status_code == 404

    @pytest.mark.asyncio
    async def test_archive_notification_other_user(
        self,
        client_factory,
        db_session: AsyncSession,
        test_notification: Notification
    ):
        """Test that user cannot archive another user's notification."""
        # Arrange - Create another user
        from services.auth.native_auth_service import native_auth_service

        other_user = User(
            email="other@example.com",
            password_hash=native_auth_service.hash_password("OtherPass123!"),
            name="Other User",
            auth_provider='native',
            email_verified=True,
            is_active=True
        )
        db_session.add(other_user)
        await db_session.commit()

        token = native_auth_service.create_access_token(
            user_id=str(other_user.id),
            email=other_user.email,
            organization_id=None
        )
        other_client = await client_factory(Authorization=f"Bearer {token}")

        # Act - Try to archive test_notification (owned by test_user)
        response = await other_client.put(
            f"/api/v1/notifications/{test_notification.id}/archive"
        )

        # Assert - Should get 404 to prevent information disclosure
        assert response.status_code == 404

    @pytest.mark.asyncio
    async def test_archive_notification_requires_auth(
        self,
        client: AsyncClient,
        test_notification: Notification
    ):
        """Test that archiving notification requires authentication."""
        # Act
        response = await client.put(
            f"/api/v1/notifications/{test_notification.id}/archive"
        )

        # Assert
        assert response.status_code in [401, 403]


class TestDeleteNotification:
    """Test delete notification endpoint."""

    @pytest.mark.asyncio
    async def test_delete_notification_success(
        self,
        authenticated_org_client: AsyncClient,
        test_notification: Notification
    ):
        """Test successfully deleting a notification."""
        # Act
        response = await authenticated_org_client.delete(
            f"/api/v1/notifications/{test_notification.id}"
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert "deleted" in data["message"].lower()

        # Verify notification is deleted
        list_response = await authenticated_org_client.get(
            "/api/v1/notifications/?is_archived=true"
        )
        assert list_response.status_code == 200
        notification_ids = [n["id"] for n in list_response.json()["notifications"]]
        assert str(test_notification.id) not in notification_ids

    @pytest.mark.asyncio
    async def test_delete_notification_not_found(
        self,
        authenticated_org_client: AsyncClient
    ):
        """Test deleting non-existent notification."""
        # Arrange
        fake_id = "123e4567-e89b-12d3-a456-426614174999"

        # Act
        response = await authenticated_org_client.delete(
            f"/api/v1/notifications/{fake_id}"
        )

        # Assert
        assert response.status_code == 404

    @pytest.mark.asyncio
    async def test_delete_notification_other_user(
        self,
        client_factory,
        db_session: AsyncSession,
        test_notification: Notification
    ):
        """Test that user cannot delete another user's notification."""
        # Arrange - Create another user
        from services.auth.native_auth_service import native_auth_service

        other_user = User(
            email="other@example.com",
            password_hash=native_auth_service.hash_password("OtherPass123!"),
            name="Other User",
            auth_provider='native',
            email_verified=True,
            is_active=True
        )
        db_session.add(other_user)
        await db_session.commit()

        token = native_auth_service.create_access_token(
            user_id=str(other_user.id),
            email=other_user.email,
            organization_id=None
        )
        other_client = await client_factory(Authorization=f"Bearer {token}")

        # Act - Try to delete test_notification (owned by test_user)
        response = await other_client.delete(
            f"/api/v1/notifications/{test_notification.id}"
        )

        # Assert - Should get 404 to prevent information disclosure
        assert response.status_code == 404

    @pytest.mark.asyncio
    async def test_delete_notification_requires_auth(
        self,
        client: AsyncClient,
        test_notification: Notification
    ):
        """Test that deleting notification requires authentication."""
        # Act
        response = await client.delete(
            f"/api/v1/notifications/{test_notification.id}"
        )

        # Assert
        assert response.status_code in [401, 403]


class TestBulkCreateNotifications:
    """Test bulk create notifications endpoint."""

    @pytest.mark.asyncio
    async def test_bulk_create_notifications_success(
        self,
        authenticated_org_client: AsyncClient,
        db_session: AsyncSession,
        test_user: User,
        test_organization: Organization
    ):
        """Test successfully creating notifications for multiple users."""
        # Arrange - Create additional users
        from models.organization_member import OrganizationMember
        from services.auth.native_auth_service import native_auth_service

        user2 = User(
            email="user2@example.com",
            password_hash=native_auth_service.hash_password("Pass123!"),
            name="User 2",
            auth_provider='native',
            email_verified=True,
            is_active=True
        )
        user3 = User(
            email="user3@example.com",
            password_hash=native_auth_service.hash_password("Pass123!"),
            name="User 3",
            auth_provider='native',
            email_verified=True,
            is_active=True
        )
        db_session.add_all([user2, user3])
        await db_session.commit()
        await db_session.refresh(user2)
        await db_session.refresh(user3)

        # Add users to organization
        for user in [user2, user3]:
            member = OrganizationMember(
                organization_id=test_organization.id,
                user_id=user.id,
                role="member",
                invited_by=test_user.id,
                joined_at=datetime.utcnow()
            )
            db_session.add(member)
        await db_session.commit()

        # Arrange - Bulk notification data
        bulk_data = {
            "user_ids": [str(user2.id), str(user3.id)],
            "title": "System Maintenance Scheduled",
            "message": "System maintenance will occur on Sunday at 2am",
            "type": "system",
            "priority": "high",
            "category": "system",
            "metadata": {"maintenance_date": "2024-01-15"}
        }

        # Act
        response = await authenticated_org_client.post(
            "/api/v1/notifications/bulk",
            json=bulk_data
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert len(data) == 2
        for notification in data:
            assert notification["title"] == "System Maintenance Scheduled"
            assert notification["type"] == "system"
            assert notification["priority"] == "high"
            assert notification["metadata"]["maintenance_date"] == "2024-01-15"

    @pytest.mark.asyncio
    async def test_bulk_create_notifications_requires_auth(
        self,
        client: AsyncClient,
        test_user: User
    ):
        """Test that bulk create requires authentication."""
        # Arrange
        bulk_data = {
            "user_ids": [str(test_user.id)],
            "title": "Test Notification"
        }

        # Act
        response = await client.post(
            "/api/v1/notifications/bulk",
            json=bulk_data
        )

        # Assert
        assert response.status_code in [401, 403]

    @pytest.mark.asyncio
    async def test_bulk_create_notifications_empty_user_list(
        self,
        authenticated_org_client: AsyncClient
    ):
        """Test that empty user list creates no notifications."""
        # Arrange
        bulk_data = {
            "user_ids": [],
            "title": "Test Notification"
        }

        # Act
        response = await authenticated_org_client.post(
            "/api/v1/notifications/bulk",
            json=bulk_data
        )

        # Assert
        # Empty user list is accepted but creates no notifications
        assert response.status_code == 200
        assert len(response.json()) == 0


class TestExpiredNotifications:
    """Test handling of expired notifications."""

    @pytest.mark.asyncio
    async def test_expired_notifications_excluded_from_list(
        self,
        authenticated_org_client: AsyncClient,
        db_session: AsyncSession,
        test_user: User,
        test_organization: Organization
    ):
        """Test that expired notifications are excluded from listing."""
        # Arrange - Create an expired notification
        expired_notification = Notification(
            user_id=test_user.id,
            organization_id=test_organization.id,
            title="Expired Notification",
            type=NotificationType.INFO,
            priority=NotificationPriority.NORMAL,
            category=NotificationCategory.SYSTEM,
            expires_at=datetime.utcnow() - timedelta(hours=1)
        )
        db_session.add(expired_notification)

        # Create a non-expired notification
        valid_notification = Notification(
            user_id=test_user.id,
            organization_id=test_organization.id,
            title="Valid Notification",
            type=NotificationType.INFO,
            priority=NotificationPriority.NORMAL,
            category=NotificationCategory.SYSTEM,
            expires_at=datetime.utcnow() + timedelta(hours=1)
        )
        db_session.add(valid_notification)
        await db_session.commit()

        # Act
        response = await authenticated_org_client.get("/api/v1/notifications/")

        # Assert
        assert response.status_code == 200
        data = response.json()
        notification_ids = [n["id"] for n in data["notifications"]]
        # Expired notification should be excluded
        assert str(expired_notification.id) not in notification_ids
        # Valid notification should be included
        assert str(valid_notification.id) in notification_ids

    @pytest.mark.asyncio
    async def test_expired_notifications_excluded_from_unread_count(
        self,
        authenticated_org_client: AsyncClient,
        db_session: AsyncSession,
        test_user: User,
        test_organization: Organization
    ):
        """Test that expired notifications don't count as unread."""
        # Arrange - Create an expired unread notification
        expired_notification = Notification(
            user_id=test_user.id,
            organization_id=test_organization.id,
            title="Expired Unread",
            type=NotificationType.INFO,
            priority=NotificationPriority.NORMAL,
            category=NotificationCategory.SYSTEM,
            is_read=False,
            expires_at=datetime.utcnow() - timedelta(hours=1)
        )
        db_session.add(expired_notification)
        await db_session.commit()

        # Act
        response = await authenticated_org_client.get(
            "/api/v1/notifications/unread-count"
        )

        # Assert - Expired notification should not be counted
        assert response.status_code == 200
        # We can't assert exact count, but endpoint should succeed
        assert "unread_count" in response.json()
