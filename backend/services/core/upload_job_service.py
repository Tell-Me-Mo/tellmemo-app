"""Upload job tracking service for async file processing with progress tracking."""

import asyncio
import uuid
from datetime import datetime, timedelta
from typing import Dict, Optional, Any, List
from enum import Enum
from apscheduler.schedulers.asyncio import AsyncIOScheduler
from apscheduler.jobstores.memory import MemoryJobStore
from dataclasses import dataclass, field
from collections import defaultdict
import traceback

from utils.logger import get_logger
from utils.monitoring import monitor_operation, monitor_sync_operation, track_background_task, MonitoringContext

logger = get_logger(__name__)

# WebSocket manager will be injected at runtime
job_websocket_manager = None


class JobStatus(str, Enum):
    """Status of an upload job."""
    PENDING = "pending"
    PROCESSING = "processing"
    COMPLETED = "completed"
    FAILED = "failed"
    CANCELLED = "cancelled"


class JobType(str, Enum):
    """Type of upload job."""
    TRANSCRIPTION = "transcription"
    TEXT_UPLOAD = "text_upload"
    EMAIL_UPLOAD = "email_upload"
    BATCH_UPLOAD = "batch_upload"
    PROJECT_SUMMARY = "project_summary"
    MEETING_SUMMARY = "meeting_summary"


@dataclass
class UploadJob:
    """Represents an upload job with progress tracking."""
    job_id: str
    project_id: str
    job_type: JobType
    status: JobStatus
    progress: float = 0.0
    total_steps: int = 1
    current_step: int = 0
    step_description: Optional[str] = None
    filename: Optional[str] = None
    file_size: Optional[int] = None
    error_message: Optional[str] = None
    result: Optional[Dict[str, Any]] = None
    created_at: datetime = field(default_factory=datetime.utcnow)
    updated_at: datetime = field(default_factory=datetime.utcnow)
    completed_at: Optional[datetime] = None
    metadata: Dict[str, Any] = field(default_factory=dict)
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert job to dictionary for API response."""
        return {
            "job_id": self.job_id,
            "project_id": self.project_id,
            "job_type": self.job_type.value,
            "status": self.status.value,
            "progress": self.progress,
            "total_steps": self.total_steps,
            "current_step": self.current_step,
            "step_description": self.step_description,
            "filename": self.filename,
            "file_size": self.file_size,
            "error_message": self.error_message,
            "result": self.result,
            "created_at": self.created_at.isoformat(),
            "updated_at": self.updated_at.isoformat(),
            "completed_at": self.completed_at.isoformat() if self.completed_at else None,
            "metadata": self.metadata
        }


class UploadJobService:
    """Service for managing upload jobs and tracking their progress."""
    
    def __init__(self):
        """Initialize the upload job service."""
        self.scheduler = AsyncIOScheduler(
            jobstores={
                'default': MemoryJobStore()
            },
            job_defaults={
                'coalesce': True,
                'max_instances': 3,
                'misfire_grace_time': 30
            }
        )
        self.jobs: Dict[str, UploadJob] = {}
        self.job_callbacks: Dict[str, List[callable]] = defaultdict(list)
        self._is_running = False
        logger.info("Upload job service initialized")
    
    def start(self):
        """Start the job scheduler."""
        if not self._is_running:
            self.scheduler.start()
            self._is_running = True
            logger.info("Upload job scheduler started")
    
    def shutdown(self):
        """Shutdown the job scheduler."""
        if self._is_running:
            self.scheduler.shutdown(wait=True)
            self._is_running = False
            logger.info("Upload job scheduler shut down")
    
    @monitor_sync_operation("create_upload_job", "job_management")
    def create_job(
        self,
        project_id: str,
        job_type: JobType,
        filename: Optional[str] = None,
        file_size: Optional[int] = None,
        total_steps: int = 1,
        metadata: Optional[Dict[str, Any]] = None
    ) -> str:
        """
        Create a new upload job.
        
        Args:
            project_id: Project ID for the upload
            job_type: Type of upload job
            filename: Optional filename
            file_size: Optional file size in bytes
            total_steps: Total number of processing steps
            metadata: Additional job metadata
            
        Returns:
            Job ID
        """
        job_id = str(uuid.uuid4())
        job = UploadJob(
            job_id=job_id,
            project_id=project_id,
            job_type=job_type,
            status=JobStatus.PENDING,
            filename=filename,
            file_size=file_size,
            total_steps=total_steps,
            metadata=metadata or {}
        )
        
        self.jobs[job_id] = job
        logger.info(f"Created upload job {job_id} for project {project_id} (type: {job_type.value})")
        
        # Clean up old jobs after 1 hour
        self.scheduler.add_job(
            func=self._cleanup_job,
            args=[job_id],
            trigger='date',
            run_date=datetime.utcnow() + timedelta(hours=1),
            id=f"cleanup_{job_id}",
            replace_existing=True
        )
        
        return job_id
    
    @monitor_sync_operation("update_job_progress", "job_management")
    def update_job_progress(
        self,
        job_id: str,
        progress: Optional[float] = None,
        current_step: Optional[int] = None,
        step_description: Optional[str] = None,
        status: Optional[JobStatus] = None,
        error_message: Optional[str] = None,
        result: Optional[Dict[str, Any]] = None,
        metadata: Optional[Dict[str, Any]] = None
    ) -> Optional[UploadJob]:
        """
        Update job progress and status.

        Args:
            job_id: Job ID to update
            progress: Progress percentage (0-100)
            current_step: Current processing step
            status: New job status
            error_message: Error message if failed
            result: Job result data
            metadata: Additional metadata to store with the job

        Returns:
            Updated job or None if not found
        """
        job = self.jobs.get(job_id)
        if not job:
            logger.warning(f"Job {job_id} not found")
            return None
        
        # Update fields
        if progress is not None:
            job.progress = min(100.0, max(0.0, progress))
        
        if current_step is not None:
            job.current_step = current_step
            # Auto-calculate progress based on steps if not provided
            if progress is None and job.total_steps > 0:
                job.progress = (current_step / job.total_steps) * 100
        
        if step_description is not None:
            job.step_description = step_description
        
        if status is not None:
            job.status = status
            if status in [JobStatus.COMPLETED, JobStatus.FAILED, JobStatus.CANCELLED]:
                job.completed_at = datetime.utcnow()
                if status == JobStatus.COMPLETED:
                    job.progress = 100.0
        
        if error_message is not None:
            job.error_message = error_message
        
        if result is not None:
            job.result = result

        if metadata is not None:
            # Merge metadata with existing metadata
            if job.metadata:
                job.metadata.update(metadata)
            else:
                job.metadata = metadata

        job.updated_at = datetime.utcnow()
        
        # Trigger callbacks
        self._trigger_callbacks(job_id, job)
        
        logger.debug(f"Updated job {job_id}: status={job.status.value}, progress={job.progress:.1f}%")
        
        # Broadcast update via WebSocket if available
        if job_websocket_manager:
            try:
                # Create task to broadcast update asynchronously
                asyncio.create_task(self._broadcast_websocket_update(job_id, job))
            except RuntimeError:
                # No event loop running, skip WebSocket broadcast
                pass
        
        return job

    def update_job_metadata(self, job_id: str, metadata_update: Dict[str, Any]) -> Optional[UploadJob]:
        """
        Update job metadata.

        Args:
            job_id: Job ID to update
            metadata_update: Dictionary of metadata to update

        Returns:
            Updated job or None if not found
        """
        job = self.jobs.get(job_id)
        if not job:
            logger.warning(f"Job {job_id} not found")
            return None

        # Update metadata
        job.metadata.update(metadata_update)
        job.updated_at = datetime.utcnow()

        # Trigger callbacks
        self._trigger_callbacks(job_id, job)

        logger.debug(f"Updated job {job_id} metadata: {metadata_update}")

        # Broadcast update via WebSocket if available
        if job_websocket_manager:
            try:
                # Create task to broadcast update asynchronously
                asyncio.create_task(self._broadcast_websocket_update(job_id, job))
            except RuntimeError:
                # No event loop running, skip WebSocket broadcast
                pass

        return job

    async def _broadcast_websocket_update(self, job_id: str, job: UploadJob):
        """Broadcast job update via WebSocket."""
        try:
            await job_websocket_manager.broadcast_job_update(job_id, job)
        except Exception as e:
            logger.debug(f"Could not broadcast WebSocket update: {e}")
    
    def get_job(self, job_id: str) -> Optional[UploadJob]:
        """Get job by ID."""
        return self.jobs.get(job_id)
    
    @monitor_sync_operation("get_project_jobs", "database")
    def get_project_jobs(
        self,
        project_id: str,
        status: Optional[JobStatus] = None,
        limit: int = 50
    ) -> List[UploadJob]:
        """
        Get jobs for a specific project.
        
        Args:
            project_id: Project ID
            status: Optional status filter
            limit: Maximum number of jobs to return
            
        Returns:
            List of jobs sorted by creation time (newest first)
        """
        jobs = [
            job for job in self.jobs.values()
            if job.project_id == project_id
            and (status is None or job.status == status)
        ]
        
        # Sort by creation time, newest first
        jobs.sort(key=lambda x: x.created_at, reverse=True)
        
        return jobs[:limit]
    
    def get_active_jobs(self) -> List[UploadJob]:
        """Get all active (pending or processing) jobs."""
        return [
            job for job in self.jobs.values()
            if job.status in [JobStatus.PENDING, JobStatus.PROCESSING]
        ]
    
    @monitor_sync_operation("cancel_job", "job_management")
    def cancel_job(self, job_id: str) -> bool:
        """
        Cancel a job.
        
        Args:
            job_id: Job ID to cancel
            
        Returns:
            True if cancelled, False if not found or already completed
        """
        job = self.jobs.get(job_id)
        if not job:
            return False
        
        if job.status in [JobStatus.COMPLETED, JobStatus.FAILED, JobStatus.CANCELLED]:
            return False
        
        job.status = JobStatus.CANCELLED
        job.completed_at = datetime.utcnow()
        job.updated_at = datetime.utcnow()
        
        # Trigger callbacks
        self._trigger_callbacks(job_id, job)
        
        logger.info(f"Cancelled job {job_id}")
        return True
    
    @monitor_operation("complete_job", "job_management", capture_args=True)
    async def complete_job(self, job_id: str, result: Optional[Dict[str, Any]] = None) -> bool:
        """
        Mark a job as completed.
        
        Args:
            job_id: Job ID to complete
            result: Optional result data
            
        Returns:
            True if completed, False if not found
        """
        job = self.jobs.get(job_id)
        if not job:
            return False
        
        job.status = JobStatus.COMPLETED
        job.progress = 100.0
        job.completed_at = datetime.utcnow()
        job.updated_at = datetime.utcnow()
        job.result = result
        
        # Broadcast update via WebSocket if available
        if job_websocket_manager:
            try:
                # Create task to broadcast update asynchronously
                asyncio.create_task(self._broadcast_websocket_update(job_id, job))
            except Exception as e:
                logger.debug(f"Could not broadcast WebSocket update: {e}")
        
        # Trigger callbacks
        self._trigger_callbacks(job_id, job)
        
        logger.info(f"Completed job {job_id}")
        return True
    
    @monitor_operation("fail_job", "job_management", capture_args=True)
    async def fail_job(self, job_id: str, error_message: str) -> bool:
        """
        Mark a job as failed.
        
        Args:
            job_id: Job ID to fail
            error_message: Error message
            
        Returns:
            True if failed, False if not found
        """
        job = self.jobs.get(job_id)
        if not job:
            return False
        
        job.status = JobStatus.FAILED
        job.error_message = error_message
        job.completed_at = datetime.utcnow()
        job.updated_at = datetime.utcnow()
        
        # Broadcast update via WebSocket if available
        if job_websocket_manager:
            try:
                # Create task to broadcast update asynchronously
                asyncio.create_task(self._broadcast_websocket_update(job_id, job))
            except Exception as e:
                logger.debug(f"Could not broadcast WebSocket update: {e}")
        
        # Trigger callbacks
        self._trigger_callbacks(job_id, job)
        
        logger.error(f"Failed job {job_id}: {error_message}")
        return True
    
    @monitor_operation("update_job_progress_async", "job_management", capture_args=True)
    async def update_job_progress_async(
        self,
        job_id: str,
        progress: Optional[float] = None,
        current_step: Optional[int] = None,
        step_description: Optional[str] = None,
        total_steps: Optional[int] = None
    ):
        """
        Update job progress asynchronously.
        
        Args:
            job_id: Job ID to update
            progress: Progress percentage (0-100)
            current_step: Current step number
            step_description: Description of current step
            total_steps: Total number of steps (optional)
        """
        job = self.jobs.get(job_id)
        if not job:
            logger.warning(f"Job {job_id} not found for progress update")
            return
        
        if progress is not None:
            job.progress = min(100.0, max(0.0, progress))
        
        if current_step is not None:
            job.current_step = current_step
            
        if step_description is not None:
            job.step_description = step_description
        
        if total_steps is not None:
            job.total_steps = total_steps
        
        job.status = JobStatus.PROCESSING
        job.updated_at = datetime.utcnow()
        
        logger.debug(f"Updated job {job_id}: status={job.status.value}, progress={job.progress:.1f}%")
        
        # Broadcast update via WebSocket if available
        if job_websocket_manager:
            try:
                # Create task to broadcast update asynchronously
                await self._broadcast_websocket_update(job_id, job)
            except Exception as e:
                logger.debug(f"Could not broadcast WebSocket update: {e}")
    
    def register_callback(self, job_id: str, callback: callable):
        """
        Register a callback for job status updates.
        
        Args:
            job_id: Job ID to monitor
            callback: Callback function(job_id, job)
        """
        self.job_callbacks[job_id].append(callback)
    
    def _trigger_callbacks(self, job_id: str, job: UploadJob):
        """Trigger registered callbacks for a job."""
        for callback in self.job_callbacks.get(job_id, []):
            try:
                asyncio.create_task(self._safe_callback(callback, job_id, job))
            except Exception as e:
                logger.error(f"Error triggering callback for job {job_id}: {e}")
    
    async def _safe_callback(self, callback: callable, job_id: str, job: UploadJob):
        """Safely execute a callback."""
        try:
            if asyncio.iscoroutinefunction(callback):
                await callback(job_id, job)
            else:
                callback(job_id, job)
        except Exception as e:
            logger.error(f"Callback error for job {job_id}: {e}")
    
    def _cleanup_job(self, job_id: str):
        """Clean up old job data."""
        if job_id in self.jobs:
            job = self.jobs[job_id]
            # Only clean up completed jobs
            if job.status in [JobStatus.COMPLETED, JobStatus.FAILED, JobStatus.CANCELLED]:
                del self.jobs[job_id]
                # Clean up callbacks
                if job_id in self.job_callbacks:
                    del self.job_callbacks[job_id]
                logger.debug(f"Cleaned up job {job_id}")
    
    @track_background_task("execute_upload_job")
    async def execute_job(
        self,
        job_id: str,
        job_function: callable,
        *args,
        **kwargs
    ):
        """
        Execute a job function with automatic progress tracking.
        
        Args:
            job_id: Job ID
            job_function: Async function to execute
            *args, **kwargs: Arguments for the job function
        """
        job = self.get_job(job_id)
        if not job:
            logger.error(f"Job {job_id} not found")
            return
        
        try:
            # Update status to processing
            self.update_job_progress(job_id, status=JobStatus.PROCESSING)
            
            # Execute the job function
            result = await job_function(job_id, *args, **kwargs)
            
            # Update status to completed
            self.update_job_progress(
                job_id,
                status=JobStatus.COMPLETED,
                progress=100.0,
                result=result
            )
            
            logger.info(f"Job {job_id} completed successfully")
            
        except asyncio.CancelledError:
            # Handle cancellation
            self.update_job_progress(
                job_id,
                status=JobStatus.CANCELLED,
                error_message="Job was cancelled"
            )
            logger.info(f"Job {job_id} was cancelled")
            raise
            
        except Exception as e:
            # Handle errors
            error_msg = str(e)
            error_trace = traceback.format_exc()
            
            self.update_job_progress(
                job_id,
                status=JobStatus.FAILED,
                error_message=error_msg
            )
            
            logger.error(f"Job {job_id} failed: {error_msg}\n{error_trace}")
    
    def get_stats(self) -> Dict[str, Any]:
        """Get service statistics."""
        active_jobs = self.get_active_jobs()
        
        status_counts = defaultdict(int)
        for job in self.jobs.values():
            status_counts[job.status.value] += 1
        
        type_counts = defaultdict(int)
        for job in self.jobs.values():
            type_counts[job.job_type.value] += 1
        
        return {
            "total_jobs": len(self.jobs),
            "active_jobs": len(active_jobs),
            "status_breakdown": dict(status_counts),
            "type_breakdown": dict(type_counts),
            "scheduler_running": self._is_running
        }


# Global instance
upload_job_service = UploadJobService()

def set_websocket_manager(manager):
    """Set the WebSocket manager for broadcasting updates."""
    global job_websocket_manager
    job_websocket_manager = manager
    logger.info("WebSocket manager registered for job updates")