"""WebSocket router for real-time ticket updates."""
from typing import Dict, Set
from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
import json
import uuid
from datetime import datetime

from db.database import get_db
from models.user import User
from models.organization import Organization
from middleware.auth_middleware import get_current_user_ws
from services.auth.auth_service import auth_service


router = APIRouter(prefix="/ws", tags=["websocket-tickets"])

# Store active connections by organization
class TicketConnectionManager:
    def __init__(self):
        # Organization ID -> Set of WebSocket connections
        self.active_connections: Dict[str, Set[WebSocket]] = {}
        # WebSocket -> User ID mapping
        self.connection_users: Dict[WebSocket, str] = {}
        # WebSocket -> Organization ID mapping
        self.connection_orgs: Dict[WebSocket, str] = {}

    async def connect(self, websocket: WebSocket, user_id: str, org_id: str):
        """Accept and register a new WebSocket connection."""
        await websocket.accept()

        # Add to organization's connection set
        if org_id not in self.active_connections:
            self.active_connections[org_id] = set()
        self.active_connections[org_id].add(websocket)

        # Store user and org mapping
        self.connection_users[websocket] = user_id
        self.connection_orgs[websocket] = org_id

        print(f"User {user_id} connected to ticket updates for org {org_id}")

    def disconnect(self, websocket: WebSocket):
        """Remove a WebSocket connection."""
        # Get org for this connection
        org_id = self.connection_orgs.get(websocket)
        user_id = self.connection_users.get(websocket)

        if org_id and org_id in self.active_connections:
            self.active_connections[org_id].discard(websocket)
            # Clean up empty org sets
            if not self.active_connections[org_id]:
                del self.active_connections[org_id]

        # Clean up mappings
        self.connection_users.pop(websocket, None)
        self.connection_orgs.pop(websocket, None)

        print(f"User {user_id} disconnected from ticket updates for org {org_id}")

    async def broadcast_to_organization(self, org_id: str, message: dict):
        """Broadcast a message to all connections in an organization."""
        if org_id in self.active_connections:
            # Create tasks for all broadcasts
            disconnected = set()
            for connection in self.active_connections[org_id]:
                try:
                    await connection.send_json(message)
                except:
                    # Mark for disconnection if send fails
                    disconnected.add(connection)

            # Clean up disconnected clients
            for conn in disconnected:
                self.disconnect(conn)

    async def send_to_user(self, user_id: str, org_id: str, message: dict):
        """Send a message to a specific user in an organization."""
        if org_id in self.active_connections:
            for connection in self.active_connections[org_id]:
                if self.connection_users.get(connection) == user_id:
                    try:
                        await connection.send_json(message)
                    except:
                        self.disconnect(connection)


# Create a single instance
ticket_manager = TicketConnectionManager()


@router.websocket("/tickets")
async def websocket_tickets(
    websocket: WebSocket,
    token: str = Query(...),
    db: AsyncSession = Depends(get_db)
):
    """WebSocket endpoint for real-time ticket updates."""
    try:
        # Authenticate user from token
        user = await get_current_user_ws(token, db)
        if not user:
            await websocket.close(code=1008, reason="Unauthorized")
            return

        # Get organization from token
        organization = await auth_service.get_user_organization(db, user)
        if not organization:
            await websocket.close(code=1008, reason="No organization context")
            return

        # Connect the user
        await ticket_manager.connect(websocket, str(user.id), str(organization.id))

        # Send initial connection success message
        await websocket.send_json({
            "type": "connection",
            "status": "connected",
            "user_id": str(user.id),
            "organization_id": str(organization.id),
            "timestamp": datetime.utcnow().isoformat()
        })

        # Keep connection alive and handle incoming messages
        while True:
            try:
                # Receive message from client
                data = await websocket.receive_json()

                # Handle different message types
                message_type = data.get("type")

                if message_type == "ping":
                    # Respond to ping
                    await websocket.send_json({
                        "type": "pong",
                        "timestamp": datetime.utcnow().isoformat()
                    })

                elif message_type == "subscribe":
                    # Subscribe to specific ticket updates
                    ticket_id = data.get("ticket_id")
                    if ticket_id:
                        await websocket.send_json({
                            "type": "subscribed",
                            "ticket_id": ticket_id,
                            "timestamp": datetime.utcnow().isoformat()
                        })

                # You can add more message handlers here

            except WebSocketDisconnect:
                break
            except json.JSONDecodeError:
                await websocket.send_json({
                    "type": "error",
                    "message": "Invalid JSON",
                    "timestamp": datetime.utcnow().isoformat()
                })
            except Exception as e:
                print(f"Error in WebSocket: {str(e)}")
                break

    except Exception as e:
        print(f"WebSocket error: {str(e)}")
        await websocket.close(code=1011, reason="Internal error")
    finally:
        ticket_manager.disconnect(websocket)


# Helper functions to broadcast ticket events

async def broadcast_ticket_created(organization_id: str, ticket_data: dict):
    """Broadcast when a new ticket is created."""
    await ticket_manager.broadcast_to_organization(
        organization_id,
        {
            "type": "ticket_created",
            "ticket": ticket_data,
            "timestamp": datetime.utcnow().isoformat()
        }
    )


async def broadcast_ticket_updated(organization_id: str, ticket_data: dict):
    """Broadcast when a ticket is updated."""
    await ticket_manager.broadcast_to_organization(
        organization_id,
        {
            "type": "ticket_updated",
            "ticket": ticket_data,
            "timestamp": datetime.utcnow().isoformat()
        }
    )


async def broadcast_comment_added(organization_id: str, ticket_id: str, comment_data: dict):
    """Broadcast when a comment is added to a ticket."""
    await ticket_manager.broadcast_to_organization(
        organization_id,
        {
            "type": "comment_added",
            "ticket_id": ticket_id,
            "comment": comment_data,
            "timestamp": datetime.utcnow().isoformat()
        }
    )


async def broadcast_ticket_status_changed(organization_id: str, ticket_id: str, old_status: str, new_status: str, changed_by: str):
    """Broadcast when ticket status changes."""
    await ticket_manager.broadcast_to_organization(
        organization_id,
        {
            "type": "status_changed",
            "ticket_id": ticket_id,
            "old_status": old_status,
            "new_status": new_status,
            "changed_by": changed_by,
            "timestamp": datetime.utcnow().isoformat()
        }
    )