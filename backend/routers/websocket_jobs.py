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
from redis.asyncio import Redis as AsyncRedis
from utils.logger import get_logger, sanitize_for_log
from queue_config import queue_config
from config import get_settings

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
        # Redis pub/sub listener task
        self._pubsub_task = None
        self._pubsub = None
        self._async_redis: Optional[AsyncRedis] = None
        # Track which jobs have been broadcast as completed (to avoid duplicate broadcasts)
        self._terminal_jobs_broadcasted: Dict[str, str] = {}  # job_id -> last_status
        
    async def connect(self, client_id: str, websocket: WebSocket):
        """Accept and store connection."""
        await websocket.accept()
        self.active_connections[client_id] = websocket
        self.client_subscriptions[client_id] = set()
        self.project_subscriptions[client_id] = None
        logger.info(f"Job WebSocket connected: {sanitize_for_log(client_id)}")

        # Start Redis pub/sub listener if not already running
        if self._pubsub_task is None or self._pubsub_task.done():
            self._pubsub_task = asyncio.create_task(self._listen_redis_pubsub())
            logger.info("Started Redis pub/sub listener task")

        # Send initial connection confirmation (client might have disconnected already)
        try:
            await self.send_json(client_id, {
                "type": "connection",
                "status": "connected",
                "client_id": client_id,
                "timestamp": datetime.utcnow().isoformat()
            })
        except Exception:
            # Client already disconnected, cleanup will happen via WebSocketDisconnect
            pass
        
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
            logger.info(f"Job WebSocket disconnected: {sanitize_for_log(client_id)}")

            # Stop pub/sub listener if no more connections
            if not self.active_connections:
                if self._pubsub_task:
                    self._pubsub_task.cancel()
                    self._pubsub_task = None
                # Set pubsub to None - task cancellation will handle cleanup
                self._pubsub = None
                logger.info("Stopped Redis pub/sub listener (no active connections)")
            
    async def subscribe_to_job(self, client_id: str, job_id: str):
        """Subscribe client to specific job updates (job_id is RQ job ID)."""
        if client_id in self.client_subscriptions:
            self.client_subscriptions[client_id].add(job_id)

            if job_id not in self.job_subscribers:
                self.job_subscribers[job_id] = set()
                # Subscribe to Redis pub/sub channel for this job
                await self._subscribe_redis_channel(job_id)

            self.job_subscribers[job_id].add(client_id)

            logger.debug(f"Client {sanitize_for_log(client_id)} subscribed to RQ job {sanitize_for_log(job_id)}")

            # Send current job status immediately from RQ
            job_data = self._get_rq_job_data(job_id)
            if job_data:
                await self.send_json(client_id, {
                    "type": "job_update",
                    "job": job_data,
                    "timestamp": datetime.utcnow().isoformat()
                })
    
    async def unsubscribe_from_job(self, client_id: str, job_id: str):
        """Unsubscribe client from job updates."""
        if client_id in self.client_subscriptions:
            self.client_subscriptions[client_id].discard(job_id)

        if job_id in self.job_subscribers:
            self.job_subscribers[job_id].discard(client_id)
            if not self.job_subscribers[job_id]:
                del self.job_subscribers[job_id]
                # Unsubscribe from Redis pub/sub channel if no more subscribers
                await self._unsubscribe_redis_channel(job_id)
                # Clean up terminal job tracking if no more subscribers
                if job_id in self._terminal_jobs_broadcasted:
                    del self._terminal_jobs_broadcasted[job_id]
                    logger.debug(f"Cleaned up terminal job tracking for {sanitize_for_log(job_id)}")

        logger.debug(f"Client {sanitize_for_log(client_id)} unsubscribed from job {sanitize_for_log(job_id)}")
    
    async def subscribe_to_project(self, client_id: str, project_id: str):
        """Subscribe client to all jobs in a project."""
        if client_id in self.project_subscriptions:
            self.project_subscriptions[client_id] = project_id
            logger.debug(f"Client {sanitize_for_log(client_id)} subscribed to project {sanitize_for_log(project_id)}")

            # Note: We could scan RQ for active jobs in this project if needed
            # For now, clients will get updates as jobs progress
    
    async def send_json(self, client_id: str, data: dict):
        """Send JSON data to specific connection."""
        if client_id in self.active_connections:
            try:
                websocket = self.active_connections[client_id]
                await websocket.send_json(data)
            except Exception as e:
                logger.error(f"Error sending to client {sanitize_for_log(client_id)}: {e}")
                self.disconnect(client_id)
    
    def _get_rq_job_data(self, rq_job_id: str) -> Optional[dict]:
        """Get job data directly from RQ."""
        from queue_config import queue_config

        try:
            rq_job = queue_config.get_job(rq_job_id)
            if not rq_job:
                return None

            meta = rq_job.meta or {}
            rq_status = rq_job.get_status()

            # Map RQ status to our status format
            meta_status = meta.get('status', '').lower()

            # Check if this job has a child job that's still processing
            child_job_id = meta.get('content_processing_job_id')
            child_completed = meta.get('content_processing_completed', False)
            has_active_child = child_job_id and not child_completed

            if meta_status == 'completed' or rq_status == 'finished':
                # If job is finished but has an active child, keep it as processing
                status = 'processing' if has_active_child else 'completed'
            elif meta_status == 'failed' or rq_status == 'failed':
                status = 'failed'
            elif meta_status == 'cancelled' or rq_status == 'canceled':
                status = 'cancelled'
            elif meta_status == 'processing' or rq_status in ['queued', 'started']:
                status = 'processing'
            else:
                status = 'pending'

            # If job has an active child, try to get child's progress
            progress = meta.get('progress', 0.0)
            step_description = meta.get('step', '')

            if has_active_child and child_job_id:
                # Try to get child job's progress
                try:
                    child_job = queue_config.get_job(child_job_id)
                    if child_job and child_job.meta:
                        child_progress = child_job.meta.get('progress', 0.0)
                        child_step = child_job.meta.get('step', '')

                        # Map child progress (0-100) to parent progress (75-100)
                        # 75% = transcription complete, 100% = everything complete
                        progress = 75.0 + (child_progress * 0.25)
                        step_description = child_step if child_step else 'Processing content and generating summary...'
                except Exception as e:
                    logger.debug(f"Could not get child job progress: {e}")
                    # Keep using parent's progress if child lookup fails
                    pass

            # Build job data from RQ meta
            # For result, prefer meta['result'] (set during task execution) over rq_job.result (set after task completes)
            # Use explicit None check to allow falsy results (empty dict, 0, False, etc.)
            result = meta.get('result')
            if result is None and rq_job.is_finished:
                result = rq_job.result

            return {
                'job_id': rq_job_id,
                'project_id': meta.get('project_id', ''),
                'job_type': 'transcription',  # Could be in meta if needed
                'status': status,
                'progress': progress,
                'total_steps': meta.get('total_steps', 1),
                'current_step': meta.get('current_step', 0),
                'step_description': step_description,
                'filename': meta.get('filename'),
                'error_message': meta.get('error'),
                'result': result,
                'created_at': rq_job.created_at.isoformat() if rq_job.created_at else None,
                'updated_at': datetime.utcnow().isoformat(),
                'metadata': meta
            }
        except Exception as e:
            logger.error(f"Error getting RQ job data for {rq_job_id}: {e}")
            return None

    async def _get_async_redis(self) -> AsyncRedis:
        """Get or create async Redis connection for WebSocket pub/sub."""
        if self._async_redis is None:
            settings = get_settings()
            if settings.redis_password:
                redis_url = f"redis://:{settings.redis_password}@{settings.redis_host}:{settings.redis_port}/{settings.redis_db}"
            else:
                redis_url = f"redis://{settings.redis_host}:{settings.redis_port}/{settings.redis_db}"

            self._async_redis = await AsyncRedis.from_url(
                redis_url,
                decode_responses=True,
                socket_connect_timeout=5,
                socket_keepalive=True
            )
            logger.info("Async Redis connection established for WebSocket pub/sub")

        return self._async_redis

    async def _subscribe_redis_channel(self, job_id: str):
        """Subscribe to Redis pub/sub channel for a job."""
        try:
            if self._pubsub is None:
                redis_conn = await self._get_async_redis()
                self._pubsub = redis_conn.pubsub()

            channel = f"job_updates:{job_id}"
            await self._pubsub.subscribe(channel)
            logger.debug(f"Subscribed to Redis channel: {channel}")
        except Exception as e:
            logger.error(f"Failed to subscribe to Redis channel for job {job_id}: {e}")

    async def _unsubscribe_redis_channel(self, job_id: str):
        """Unsubscribe from Redis pub/sub channel for a job."""
        try:
            if self._pubsub:
                channel = f"job_updates:{job_id}"
                await self._pubsub.unsubscribe(channel)
                logger.debug(f"Unsubscribed from Redis channel: {channel}")
        except Exception as e:
            logger.error(f"Failed to unsubscribe from Redis channel for job {job_id}: {e}")

    async def _listen_redis_pubsub(self):
        """Background task to listen for Redis pub/sub messages."""
        logger.info("Redis pub/sub listener started")
        try:
            while True:
                if self._pubsub is None:
                    # Wait for first subscription
                    await asyncio.sleep(1)
                    continue

                # Listen for messages with timeout
                message = await self._pubsub.get_message(ignore_subscribe_messages=True, timeout=1.0)

                if message and message['type'] == 'message':
                    try:
                        channel = message['channel']
                        # Extract job_id from channel name (format: job_updates:{job_id})
                        job_id = channel.split(':', 1)[1]
                        data = json.loads(message['data'])

                        # Skip if already broadcast as terminal
                        if job_id in self._terminal_jobs_broadcasted:
                            continue

                        # Get full job data from RQ (in case pub/sub data is partial)
                        job_data = self._get_rq_job_data(job_id)
                        if not job_data:
                            # Fallback to using data from pub/sub message
                            job_data = data

                        job_status = job_data.get('status')

                        # Broadcast to all subscribers
                        if job_id in self.job_subscribers:
                            for client_id in list(self.job_subscribers[job_id]):
                                await self.send_json(client_id, {
                                    "type": "job_update",
                                    "job": job_data,
                                    "timestamp": datetime.utcnow().isoformat()
                                })

                        # Also broadcast to project subscribers
                        project_id = job_data.get('project_id')
                        if project_id:
                            for client_id, subscribed_project_id in self.project_subscriptions.items():
                                if subscribed_project_id == project_id:
                                    await self.send_json(client_id, {
                                        "type": "job_update",
                                        "job": job_data,
                                        "timestamp": datetime.utcnow().isoformat()
                                    })

                        # If job reached a terminal state, mark it
                        if job_status in ['completed', 'failed', 'cancelled']:
                            self._terminal_jobs_broadcasted[job_id] = job_status
                            logger.debug(f"Job {job_id} reached terminal state '{job_status}' via Redis pub/sub")

                    except Exception as e:
                        logger.error(f"Error processing Redis pub/sub message: {e}", exc_info=True)

        except asyncio.CancelledError:
            logger.info("Redis pub/sub listener cancelled")
            # Clean up pub/sub connection
            if self._pubsub:
                try:
                    await self._pubsub.unsubscribe()
                    await self._pubsub.aclose()
                except Exception as e:
                    logger.warning(f"Error closing pub/sub during cancellation: {e}")
                self._pubsub = None
            # Close async Redis connection
            if self._async_redis:
                try:
                    await self._async_redis.aclose()
                except Exception as e:
                    logger.warning(f"Error closing async Redis during cancellation: {e}")
                self._async_redis = None
        except Exception as e:
            logger.error(f"Error in Redis pub/sub listener: {e}", exc_info=True)

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
                rq_job_id = data.get("job_id")
                if rq_job_id:
                    job_data = job_manager._get_rq_job_data(rq_job_id)
                    if job_data:
                        await job_manager.send_json(client_id, {
                            "type": "job_update",
                            "job": job_data,
                            "timestamp": datetime.utcnow().isoformat()
                        })
                    else:
                        await job_manager.send_error(client_id, f"Job {rq_job_id} not found")

            elif action == "cancel":
                rq_job_id = data.get("job_id")
                if rq_job_id:
                    from queue_config import queue_config
                    success = queue_config.cancel_job(rq_job_id)
                    if success:
                        await job_manager.send_json(client_id, {
                            "type": "job_cancelled",
                            "job_id": rq_job_id,
                            "timestamp": datetime.utcnow().isoformat()
                        })
                    else:
                        await job_manager.send_error(client_id, f"Failed to cancel job {rq_job_id}")
                        
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
        logger.error(f"WebSocket error for client {sanitize_for_log(client_id)}: {e}")
        job_manager.disconnect(client_id)


# Export the manager so the job service can send updates
__all__ = ['job_manager', 'router']