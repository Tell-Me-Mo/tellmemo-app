"""WebSocket endpoint for real-time notifications."""

import json
import asyncio
from typing import Dict, Set
from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from datetime import datetime
import uuid

from db.database import get_db
from middleware.auth_middleware import get_current_user_ws
from services.notifications.notification_service import NotificationService
from models.notification import Notification
from utils.logger import get_logger

logger = get_logger(__name__)

router = APIRouter()

class ConnectionManager:
    """Manages WebSocket connections for notifications."""

    def __init__(self):
        # Map user_id to set of WebSocket connections
        self.active_connections: Dict[str, Set[WebSocket]] = {}
        # Map WebSocket to user_id for reverse lookup
        self.websocket_to_user: Dict[WebSocket, str] = {}
        # Lock for thread-safe operations
        self.lock = asyncio.Lock()

    async def connect(self, websocket: WebSocket, user_id: str):
        """Add a new WebSocket connection for a user."""
        await websocket.accept()

        async with self.lock:
            if user_id not in self.active_connections:
                self.active_connections[user_id] = set()
            self.active_connections[user_id].add(websocket)
            self.websocket_to_user[websocket] = user_id

        logger.info(f"WebSocket connected for user {user_id}. Total connections: {len(self.active_connections[user_id])}")

    async def disconnect(self, websocket: WebSocket):
        """Remove a WebSocket connection."""
        async with self.lock:
            user_id = self.websocket_to_user.get(websocket)
            if user_id:
                self.active_connections[user_id].discard(websocket)
                if not self.active_connections[user_id]:
                    del self.active_connections[user_id]
                del self.websocket_to_user[websocket]
                logger.info(f"WebSocket disconnected for user {user_id}")

    async def send_notification_to_user(self, user_id: str, notification: Dict):
        """Send notification to all WebSocket connections for a user."""
        if user_id in self.active_connections:
            disconnected = set()

            for websocket in self.active_connections[user_id]:
                try:
                    await websocket.send_json({
                        "type": "notification",
                        "data": notification,
                        "timestamp": datetime.utcnow().isoformat()
                    })
                except Exception as e:
                    logger.error(f"Error sending notification to user {user_id}: {e}")
                    disconnected.add(websocket)

            # Clean up disconnected websockets
            for ws in disconnected:
                await self.disconnect(ws)

    async def broadcast_to_organization(self, organization_id: str, notification: Dict, db: AsyncSession):
        """Broadcast notification to all users in an organization."""
        # This would require tracking organization membership
        # For now, we'll implement user-specific notifications
        pass

    async def send_heartbeat(self, websocket: WebSocket):
        """Send heartbeat to keep connection alive."""
        try:
            await websocket.send_json({
                "type": "heartbeat",
                "timestamp": datetime.utcnow().isoformat()
            })
        except:
            pass

    def is_user_connected(self, user_id: str) -> bool:
        """Check if a user has any active WebSocket connections."""
        return user_id in self.active_connections and len(self.active_connections[user_id]) > 0

    def get_connected_users(self) -> Set[str]:
        """Get set of all connected user IDs."""
        return set(self.active_connections.keys())

    def get_connection_count(self, user_id: str) -> int:
        """Get number of active connections for a user."""
        return len(self.active_connections.get(user_id, set()))


# Create global connection manager instance
notification_manager = ConnectionManager()


@router.websocket("/ws/notifications")
async def websocket_notifications(
    websocket: WebSocket,
    token: str = Query(..., description="Authentication token"),
    db: AsyncSession = Depends(get_db)
):
    """
    WebSocket endpoint for real-time notifications.

    Client connects with: ws://localhost:8000/ws/notifications?token=<auth_token>

    Message types sent to client:
    - notification: New notification
    - heartbeat: Keep-alive ping
    - notification_read: Notification marked as read
    - notification_archived: Notification archived
    - unread_count: Updated unread count
    """
    user = None

    try:
        # Authenticate user from token
        user = await get_current_user_ws(token, db)
        if not user:
            await websocket.close(code=4001, reason="Unauthorized")
            return

        user_id = str(user.id)

        # Connect websocket
        await notification_manager.connect(websocket, user_id)

        # Send initial unread count
        notification_service = NotificationService(db)
        unread_count = await notification_service.get_unread_count(user_id)

        await websocket.send_json({
            "type": "unread_count",
            "data": {"count": unread_count},
            "timestamp": datetime.utcnow().isoformat()
        })

        # Keep connection alive
        heartbeat_task = asyncio.create_task(heartbeat_sender(websocket))

        try:
            # Listen for messages from client
            while True:
                data = await websocket.receive_text()

                try:
                    message = json.loads(data)
                    await handle_client_message(websocket, user_id, message, db)
                except json.JSONDecodeError:
                    await websocket.send_json({
                        "type": "error",
                        "message": "Invalid JSON format"
                    })

        except WebSocketDisconnect:
            logger.info(f"WebSocket disconnected for user {user_id}")

    except Exception as e:
        logger.error(f"WebSocket error: {e}")

    finally:
        # Clean up
        if user:
            await notification_manager.disconnect(websocket)

        # Cancel heartbeat task
        if 'heartbeat_task' in locals():
            heartbeat_task.cancel()


async def heartbeat_sender(websocket: WebSocket):
    """Send periodic heartbeat to keep connection alive."""
    try:
        while True:
            await asyncio.sleep(30)  # Send heartbeat every 30 seconds
            await notification_manager.send_heartbeat(websocket)
    except asyncio.CancelledError:
        pass


async def handle_client_message(
    websocket: WebSocket,
    user_id: str,
    message: Dict,
    db: AsyncSession
):
    """Handle messages from client."""
    msg_type = message.get("type")

    if msg_type == "ping":
        # Respond to ping
        await websocket.send_json({
            "type": "pong",
            "timestamp": datetime.utcnow().isoformat()
        })

    elif msg_type == "mark_read":
        # Mark notification as read
        notification_id = message.get("notification_id")
        if notification_id:
            service = NotificationService(db)
            success = await service.mark_as_read(notification_id, user_id)

            if success:
                # Notify all user's connections
                await notification_manager.send_notification_to_user(user_id, {
                    "type": "notification_read",
                    "notification_id": notification_id
                })

                # Send updated unread count
                unread_count = await service.get_unread_count(user_id)
                await notification_manager.send_notification_to_user(user_id, {
                    "type": "unread_count",
                    "count": unread_count
                })

    elif msg_type == "mark_all_read":
        # Mark all notifications as read
        service = NotificationService(db)
        count = await service.mark_all_as_read(user_id)

        await websocket.send_json({
            "type": "all_marked_read",
            "count": count,
            "timestamp": datetime.utcnow().isoformat()
        })

        # Send updated unread count (should be 0)
        await notification_manager.send_notification_to_user(user_id, {
            "type": "unread_count",
            "count": 0
        })

    elif msg_type == "get_unread_count":
        # Get current unread count
        service = NotificationService(db)
        unread_count = await service.get_unread_count(user_id)

        await websocket.send_json({
            "type": "unread_count",
            "data": {"count": unread_count},
            "timestamp": datetime.utcnow().isoformat()
        })


async def broadcast_new_notification(notification: Notification):
    """
    Broadcast a new notification to the user via WebSocket.
    This function is called by the notification service when creating notifications.
    """
    if not notification.user_id:
        return

    user_id = str(notification.user_id)

    # Check if user is connected
    if notification_manager.is_user_connected(user_id):
        notification_data = {
            "id": str(notification.id),
            "title": notification.title,
            "message": notification.message,
            "type": notification.type.value if notification.type else "info",
            "priority": notification.priority.value if notification.priority else "normal",
            "category": notification.category.value if notification.category else "other",
            "entity_type": notification.entity_type,
            "entity_id": str(notification.entity_id) if notification.entity_id else None,
            "action_url": notification.action_url,
            "action_label": notification.action_label,
            "metadata": notification.extra_data,
            "created_at": notification.created_at.isoformat() if notification.created_at else None,
            "is_read": notification.is_read,
        }

        await notification_manager.send_notification_to_user(user_id, notification_data)
        logger.info(f"Broadcast notification {notification.id} to user {user_id}")


# Export for use in notification service
__all__ = ['router', 'notification_manager', 'broadcast_new_notification']