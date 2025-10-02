"""
WebSocket router for real-time job progress updates.
Handles job tracking and progress notifications.
"""

import asyncio
import json
import logging
from typing import Dict, Set, Optional
from datetime import datetime
import uuid

from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Query
from services.core.upload_job_service import upload_job_service, JobStatus, UploadJob
from utils.logger import get_logger

logger = get_logger(__name__)
router = APIRouter(prefix="/ws", tags=["websocket"])


class JobConnectionManager:
    """Manages WebSocket connections for job progress updates."""
    
    def __init__(self):
        # Maps client_id to WebSocket connection
        self.active_connections: Dict[str, WebSocket] = {}
        # Maps client_id to set of job_ids they're tracking
        self.client_subscriptions: Dict[str, Set[str]] = {}
        # Maps job_id to set of client_ids tracking it
        self.job_subscribers: Dict[str, Set[str]] = {}
        # Maps client_id to project_id for project-wide updates
        self.project_subscriptions: Dict[str, Optional[str]] = {}
        
    async def connect(self, client_id: str, websocket: WebSocket):
        """Accept and store connection."""
        await websocket.accept()
        self.active_connections[client_id] = websocket
        self.client_subscriptions[client_id] = set()
        self.project_subscriptions[client_id] = None
        logger.info(f"Job WebSocket connected: {client_id}")
        
        # Send initial connection confirmation
        await self.send_json(client_id, {
            "type": "connection",
            "status": "connected",
            "client_id": client_id,
            "timestamp": datetime.utcnow().isoformat()
        })
        
    def disconnect(self, client_id: str):
        """Remove connection and clean up subscriptions."""
        if client_id in self.active_connections:
            # Clean up job subscriptions
            if client_id in self.client_subscriptions:
                for job_id in self.client_subscriptions[client_id]:
                    if job_id in self.job_subscribers:
                        self.job_subscribers[job_id].discard(client_id)
                        if not self.job_subscribers[job_id]:
                            del self.job_subscribers[job_id]
                del self.client_subscriptions[client_id]
            
            # Clean up project subscription
            if client_id in self.project_subscriptions:
                del self.project_subscriptions[client_id]
            
            # Remove connection
            del self.active_connections[client_id]
            logger.info(f"Job WebSocket disconnected: {client_id}")
            
    async def subscribe_to_job(self, client_id: str, job_id: str):
        """Subscribe client to specific job updates."""
        if client_id in self.client_subscriptions:
            self.client_subscriptions[client_id].add(job_id)
            
            if job_id not in self.job_subscribers:
                self.job_subscribers[job_id] = set()
            self.job_subscribers[job_id].add(client_id)
            
            logger.debug(f"Client {client_id} subscribed to job {job_id}")
            
            # Send current job status immediately
            job = upload_job_service.get_job(job_id)
            if job:
                await self.send_job_update(client_id, job)
    
    async def unsubscribe_from_job(self, client_id: str, job_id: str):
        """Unsubscribe client from job updates."""
        if client_id in self.client_subscriptions:
            self.client_subscriptions[client_id].discard(job_id)
            
        if job_id in self.job_subscribers:
            self.job_subscribers[job_id].discard(client_id)
            if not self.job_subscribers[job_id]:
                del self.job_subscribers[job_id]
                
        logger.debug(f"Client {client_id} unsubscribed from job {job_id}")
    
    async def subscribe_to_project(self, client_id: str, project_id: str):
        """Subscribe client to all jobs in a project."""
        if client_id in self.project_subscriptions:
            self.project_subscriptions[client_id] = project_id
            logger.debug(f"Client {client_id} subscribed to project {project_id}")
            
            # Send all active jobs for this project
            jobs = upload_job_service.get_project_jobs(project_id, limit=100)
            active_jobs = [job for job in jobs if job.status in [JobStatus.PENDING, JobStatus.PROCESSING]]
            
            for job in active_jobs:
                await self.send_job_update(client_id, job)
    
    async def send_json(self, client_id: str, data: dict):
        """Send JSON data to specific connection."""
        if client_id in self.active_connections:
            try:
                websocket = self.active_connections[client_id]
                await websocket.send_json(data)
            except Exception as e:
                logger.error(f"Error sending to client {client_id}: {e}")
                self.disconnect(client_id)
    
    async def send_job_update(self, client_id: str, job: UploadJob):
        """Send job update to specific client."""
        await self.send_json(client_id, {
            "type": "job_update",
            "job": job.to_dict(),
            "timestamp": datetime.utcnow().isoformat()
        })
    
    async def broadcast_job_update(self, job_id: str, job: UploadJob):
        """Broadcast job update to all subscribers."""
        if job_id in self.job_subscribers:
            # Send to direct subscribers
            for client_id in list(self.job_subscribers[job_id]):
                await self.send_job_update(client_id, job)
        
        # Also send to project subscribers
        for client_id, project_id in self.project_subscriptions.items():
            if project_id == job.project_id:
                await self.send_job_update(client_id, job)
        
        # For new jobs or jobs from integrations, broadcast to all connected clients
        # so they can display the progress overlay
        if job.status == JobStatus.PROCESSING and job.progress <= 10:
            # This is likely a new job from an integration
            await self.broadcast_new_job_to_all(job)
    
    async def broadcast_new_job_to_all(self, job: UploadJob):
        """Broadcast new job notification to all connected clients."""
        for client_id in list(self.active_connections.keys()):
            await self.send_json(client_id, {
                "type": "new_job",
                "job": job.to_dict(),
                "timestamp": datetime.utcnow().isoformat()
            })
    
    async def send_error(self, client_id: str, error: str):
        """Send error message to client."""
        await self.send_json(client_id, {
            "type": "error",
            "error": error,
            "timestamp": datetime.utcnow().isoformat()
        })


# Global connection manager instance
job_manager = JobConnectionManager()


@router.websocket("/jobs")
async def websocket_job_updates(
    websocket: WebSocket,
    client_id: Optional[str] = Query(None)
):
    """
    WebSocket endpoint for real-time job progress updates.
    
    Clients can:
    - Subscribe to specific jobs
    - Subscribe to all jobs in a project
    - Receive real-time progress updates
    - Cancel jobs
    
    Message format:
    - Subscribe to job: {"action": "subscribe", "job_id": "..."}
    - Unsubscribe from job: {"action": "unsubscribe", "job_id": "..."}
    - Subscribe to project: {"action": "subscribe_project", "project_id": "..."}
    - Get job status: {"action": "get_status", "job_id": "..."}
    - Cancel job: {"action": "cancel", "job_id": "..."}
    """
    # Generate client ID if not provided
    if not client_id:
        client_id = str(uuid.uuid4())
    
    await job_manager.connect(client_id, websocket)
    
    try:
        while True:
            # Receive message from client
            data = await websocket.receive_json()
            action = data.get("action")
            
            if action == "subscribe":
                job_id = data.get("job_id")
                if job_id:
                    await job_manager.subscribe_to_job(client_id, job_id)
                    
            elif action == "unsubscribe":
                job_id = data.get("job_id")
                if job_id:
                    await job_manager.unsubscribe_from_job(client_id, job_id)
                    
            elif action == "subscribe_project":
                project_id = data.get("project_id")
                if project_id:
                    await job_manager.subscribe_to_project(client_id, project_id)
                    
            elif action == "get_status":
                job_id = data.get("job_id")
                if job_id:
                    job = upload_job_service.get_job(job_id)
                    if job:
                        await job_manager.send_job_update(client_id, job)
                    else:
                        await job_manager.send_error(client_id, f"Job {job_id} not found")
                        
            elif action == "cancel":
                job_id = data.get("job_id")
                if job_id:
                    success = upload_job_service.cancel_job(job_id)
                    if success:
                        await job_manager.send_json(client_id, {
                            "type": "job_cancelled",
                            "job_id": job_id,
                            "timestamp": datetime.utcnow().isoformat()
                        })
                    else:
                        await job_manager.send_error(client_id, f"Failed to cancel job {job_id}")
                        
            elif action == "ping":
                # Heartbeat/keepalive
                await job_manager.send_json(client_id, {
                    "type": "pong",
                    "timestamp": datetime.utcnow().isoformat()
                })
                
            else:
                await job_manager.send_error(client_id, f"Unknown action: {action}")
                
    except WebSocketDisconnect:
        job_manager.disconnect(client_id)
    except Exception as e:
        logger.error(f"WebSocket error for client {client_id}: {e}")
        job_manager.disconnect(client_id)


# Export the manager so the job service can send updates
__all__ = ['job_manager', 'router']