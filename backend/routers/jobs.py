"""Job tracking and progress monitoring endpoints."""

from fastapi import APIRouter, HTTPException, Query, Request, Depends
from fastapi.responses import StreamingResponse
from typing import List, Optional
from pydantic import BaseModel
import asyncio
import json
import uuid
from datetime import datetime
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from rq.job import Job, JobStatus as RQJobStatus
from utils.logger import get_logger, sanitize_for_log
from dependencies.auth import get_current_user, get_current_organization
from models.user import User
from models.organization import Organization
from models.project import Project
from db.database import get_db
from queue_config import queue_config

router = APIRouter()
logger = get_logger(__name__)


def _rq_job_to_dict(rq_job: Job) -> dict:
    """Convert RQ job to API response format."""
    try:
        # Get metadata
        meta = rq_job.meta or {}

        # Map RQ status to our status strings
        status_map = {
            RQJobStatus.QUEUED: "pending",
            RQJobStatus.STARTED: "processing",
            RQJobStatus.FINISHED: "completed",
            RQJobStatus.FAILED: "failed",
            RQJobStatus.CANCELED: "cancelled",
            RQJobStatus.STOPPED: "cancelled",
            RQJobStatus.SCHEDULED: "pending",
            RQJobStatus.DEFERRED: "pending"
        }

        status = status_map.get(rq_job.get_status(), "pending")
        progress = meta.get('progress', 0.0)

        return {
            "job_id": rq_job.id,
            "project_id": meta.get('project_id', ''),
            "job_type": meta.get('job_type', 'processing'),
            "status": status,
            "progress": progress,
            "total_steps": meta.get('total_steps', 0),
            "current_step": meta.get('current_step', 0),
            "filename": meta.get('filename'),
            "file_size": meta.get('file_size'),
            "error_message": rq_job.exc_info if rq_job.is_failed else meta.get('error'),
            "result": rq_job.result if rq_job.is_finished else meta.get('result'),
            "created_at": rq_job.created_at.isoformat() if rq_job.created_at else datetime.utcnow().isoformat(),
            "updated_at": datetime.utcnow().isoformat(),  # RQ doesn't track update time
            "completed_at": rq_job.ended_at.isoformat() if rq_job.ended_at else None,
            "metadata": meta
        }
    except Exception as e:
        logger.error(f"Error converting RQ job to dict: {e}")
        return {
            "job_id": rq_job.id if hasattr(rq_job, 'id') else 'unknown',
            "project_id": '',
            "job_type": 'unknown',
            "status": "failed",
            "progress": 0.0,
            "total_steps": 0,
            "current_step": 0,
            "filename": None,
            "file_size": None,
            "error_message": str(e),
            "result": None,
            "created_at": datetime.utcnow().isoformat(),
            "updated_at": datetime.utcnow().isoformat(),
            "completed_at": None,
            "metadata": {}
        }


class JobResponse(BaseModel):
    """Response model for job information."""
    job_id: str
    project_id: str
    job_type: str
    status: str
    progress: float
    total_steps: int
    current_step: int
    filename: Optional[str]
    file_size: Optional[int]
    error_message: Optional[str]
    result: Optional[dict]
    created_at: str
    updated_at: str
    completed_at: Optional[str]
    metadata: dict


class JobStatsResponse(BaseModel):
    """Response model for job service statistics."""
    total_jobs: int
    active_jobs: int
    status_breakdown: dict
    type_breakdown: dict
    scheduler_running: bool


# NOTE: More specific routes must come before parametric routes
# to avoid route matching issues in FastAPI

@router.get("/jobs/active", response_model=List[JobResponse])
async def get_active_jobs(
    current_user: User = Depends(get_current_user),
    current_org: Organization = Depends(get_current_organization),
    db: AsyncSession = Depends(get_db)
):
    """
    Get all currently active RQ jobs (pending or processing) for the current organization.

    Returns:
        List of active jobs for the user's organization
    """
    # Get all job IDs from the default queue
    queue = queue_config.default_queue
    active_job_ids = queue.started_job_registry.get_job_ids() + queue.get_job_ids()

    # Get job details and filter by organization
    org_jobs = []
    for job_id in active_job_ids:
        try:
            rq_job = queue_config.get_job(job_id)
            if not rq_job:
                continue

            # Check if job belongs to current org
            job_meta = rq_job.meta or {}
            project_id_str = job_meta.get('project_id')

            if not project_id_str:
                # System job without project, skip
                continue

            try:
                project_id = uuid.UUID(project_id_str)
                result = await db.execute(
                    select(Project).where(Project.id == project_id)
                )
                project = result.scalar_one_or_none()

                if project and project.organization_id == current_org.id:
                    org_jobs.append(_rq_job_to_dict(rq_job))
            except (ValueError, AttributeError):
                continue

        except Exception as e:
            logger.warning(f"Error processing job {job_id}: {e}")
            continue

    return [JobResponse(**job) for job in org_jobs]


@router.get("/jobs/stats", response_model=JobStatsResponse)
async def get_job_stats(
    current_user: User = Depends(get_current_user),
    current_org: Organization = Depends(get_current_organization)
):
    """
    Get statistics about RQ jobs for the current organization.

    Returns:
        Service statistics including job counts and status breakdown
    """
    queue = queue_config.default_queue

    # Get counts from different registries
    queued_count = len(queue.get_job_ids())
    started_count = len(queue.started_job_registry.get_job_ids())
    finished_count = len(queue.finished_job_registry.get_job_ids())
    failed_count = len(queue.failed_job_registry.get_job_ids())

    # Note: We can't easily filter by organization without loading all jobs
    # This returns counts for ALL jobs in the queue
    return JobStatsResponse(
        total_jobs=queued_count + started_count + finished_count + failed_count,
        active_jobs=queued_count + started_count,
        status_breakdown={
            "queued": queued_count,
            "started": started_count,
            "finished": finished_count,
            "failed": failed_count
        },
        type_breakdown={},  # RQ doesn't track job types separately
        scheduler_running=True  # RQ is always running if Redis is available
    )


@router.get("/jobs/{job_id}", response_model=JobResponse)
async def get_job_status(
    job_id: str,
    current_user: User = Depends(get_current_user),
    current_org: Organization = Depends(get_current_organization),
    db: AsyncSession = Depends(get_db)
):
    """
    Get the status of a specific RQ job.

    Args:
        job_id: The RQ job ID to query

    Returns:
        Job information including progress and status
    """
    # Get RQ job from Redis
    rq_job = queue_config.get_job(job_id)
    if not rq_job:
        raise HTTPException(status_code=404, detail=f"Job {job_id} not found")

    # Validate that the job's project belongs to the current organization
    job_meta = rq_job.meta or {}
    project_id_str = job_meta.get('project_id')

    if not project_id_str:
        # Job doesn't have project_id, allow it (might be a system job)
        return JobResponse(**_rq_job_to_dict(rq_job))

    try:
        project_id = uuid.UUID(project_id_str)
    except (ValueError, AttributeError):
        raise HTTPException(status_code=404, detail=f"Job {job_id} not found")

    result = await db.execute(
        select(Project).where(Project.id == project_id)
    )
    project = result.scalar_one_or_none()

    if not project or project.organization_id != current_org.id:
        # Return 404 to prevent information disclosure
        raise HTTPException(status_code=404, detail=f"Job {job_id} not found")

    return JobResponse(**_rq_job_to_dict(rq_job))


@router.post("/jobs/{job_id}/cancel")
async def cancel_job(
    job_id: str,
    current_user: User = Depends(get_current_user),
    current_org: Organization = Depends(get_current_organization),
    db: AsyncSession = Depends(get_db)
):
    """
    Cancel an RQ job if it's still running.

    Args:
        job_id: The RQ job ID to cancel

    Returns:
        Success message or error
    """
    # Get RQ job from Redis
    rq_job = queue_config.get_job(job_id)
    if not rq_job:
        raise HTTPException(status_code=404, detail=f"Job {job_id} not found")

    # Validate that the job's project belongs to the current organization
    job_meta = rq_job.meta or {}
    project_id_str = job_meta.get('project_id')

    if project_id_str:
        try:
            project_id = uuid.UUID(project_id_str)
        except (ValueError, AttributeError):
            raise HTTPException(status_code=404, detail=f"Job {job_id} not found")

        result = await db.execute(
            select(Project).where(Project.id == project_id)
        )
        project = result.scalar_one_or_none()

        if not project or project.organization_id != current_org.id:
            # Return 404 to prevent information disclosure
            raise HTTPException(status_code=404, detail=f"Job {job_id} not found")

    # Check if job can be cancelled
    if rq_job.is_finished or rq_job.is_failed:
        raise HTTPException(
            status_code=400,
            detail="Job cannot be cancelled (already completed)"
        )

    # Cancel the RQ job
    try:
        rq_job.cancel()
        logger.info(f"Cancelled RQ job {job_id}")
        return {"message": f"Job {job_id} has been cancelled"}
    except Exception as e:
        logger.error(f"Failed to cancel job {job_id}: {e}")
        raise HTTPException(status_code=500, detail="Failed to cancel job")


@router.get("/jobs/{job_id}/stream")
async def stream_job_progress(
    request: Request,
    job_id: str,
    timeout: int = Query(300, description="Timeout in seconds"),
    current_user: User = Depends(get_current_user),
    current_org: Organization = Depends(get_current_organization),
    db: AsyncSession = Depends(get_db)
):
    """
    Stream RQ job progress updates using Server-Sent Events (SSE).

    Note: For real-time updates, consider using WebSocket endpoint /ws/jobs instead.

    This endpoint will stream real-time updates about job progress until:
    - The job completes (success, failure, or cancellation)
    - The timeout is reached
    - The client disconnects

    Args:
        job_id: The RQ job ID to monitor
        timeout: Maximum time to stream in seconds (default 5 minutes)

    Returns:
        SSE stream with job progress updates
    """
    # Get and validate job
    rq_job = queue_config.get_job(job_id)
    if not rq_job:
        raise HTTPException(status_code=404, detail=f"Job {job_id} not found")

    # Validate organization access
    job_meta = rq_job.meta or {}
    project_id_str = job_meta.get('project_id')

    if project_id_str:
        try:
            project_id = uuid.UUID(project_id_str)
            result = await db.execute(
                select(Project).where(Project.id == project_id)
            )
            project = result.scalar_one_or_none()

            if not project or project.organization_id != current_org.id:
                raise HTTPException(status_code=404, detail=f"Job {job_id} not found")
        except (ValueError, AttributeError):
            raise HTTPException(status_code=404, detail=f"Job {job_id} not found")

    async def event_generator():
        """Generate SSE events for job progress."""
        start_time = asyncio.get_event_loop().time()
        last_update = None

        try:
            while True:
                # Check if client disconnected
                if await request.is_disconnected():
                    logger.info(f"Client disconnected from job stream {sanitize_for_log(job_id)}")
                    break

                # Check timeout
                if asyncio.get_event_loop().time() - start_time > timeout:
                    yield f"event: timeout\ndata: {json.dumps({'message': 'Stream timeout reached'})}\n\n"
                    break

                # Get current job status
                rq_job = queue_config.get_job(job_id)
                if not rq_job:
                    yield f"event: error\ndata: {json.dumps({'message': 'Job not found'})}\n\n"
                    break

                job_dict = _rq_job_to_dict(rq_job)

                # Send update if job changed
                current_update = (job_dict['status'], job_dict['progress'], job_dict['current_step'])
                if current_update != last_update:
                    event_data = {
                        "job_id": job_id,
                        "status": job_dict['status'],
                        "progress": job_dict['progress'],
                        "current_step": job_dict['current_step'],
                        "total_steps": job_dict['total_steps'],
                        "error_message": job_dict['error_message'],
                        "result": job_dict['result']
                    }

                    # Send progress event
                    yield f"event: progress\ndata: {json.dumps(event_data)}\n\n"
                    last_update = current_update

                # Check if job is complete
                if job_dict['status'] in ['completed', 'failed', 'cancelled']:
                    # Send final status
                    yield f"event: {job_dict['status']}\ndata: {json.dumps(job_dict)}\n\n"
                    break

                # Wait a bit before next check
                await asyncio.sleep(0.5)

        except asyncio.CancelledError:
            logger.info(f"Job stream cancelled for {sanitize_for_log(job_id)}")
            yield f"event: cancelled\ndata: {json.dumps({'message': 'Stream cancelled'})}\n\n"
        except Exception as e:
            logger.error(f"Error in job stream for {sanitize_for_log(job_id)}: {sanitize_for_log(str(e))}", exc_info=True)
            yield f"event: error\ndata: {json.dumps({'message': 'Internal error occurred'})}\n\n"

    return StreamingResponse(
        event_generator(),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
            "X-Accel-Buffering": "no"  # Disable nginx buffering
        }
    )


@router.get("/projects/{project_id}/jobs", response_model=List[JobResponse])
async def get_project_jobs(
    project_id: str,
    status: Optional[str] = Query(None, description="Filter by status"),
    limit: int = Query(50, description="Maximum number of jobs to return"),
    current_user: User = Depends(get_current_user),
    current_org: Organization = Depends(get_current_organization),
    db: AsyncSession = Depends(get_db)
):
    """
    Get all RQ jobs for a specific project.

    Args:
        project_id: Project ID
        status: Optional status filter (pending, processing, completed, failed, cancelled)
        limit: Maximum number of jobs to return

    Returns:
        List of jobs for the project
    """
    # Validate status filter if provided
    valid_statuses = ['pending', 'processing', 'completed', 'failed', 'cancelled']
    if status and status not in valid_statuses:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid status filter. Must be one of: {', '.join(valid_statuses)}"
        )

    try:
        # Validate project ID format
        project_uuid = uuid.UUID(project_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid project ID format")

    # Validate that project exists and belongs to current organization
    result = await db.execute(
        select(Project).where(Project.id == project_uuid)
    )
    project = result.scalar_one_or_none()

    if not project:
        raise HTTPException(status_code=404, detail=f"Project {project_id} not found")

    if project.organization_id != current_org.id:
        # Return 404 to prevent information disclosure
        raise HTTPException(status_code=404, detail=f"Project {project_id} not found")

    # Get all jobs from all registries
    queue = queue_config.default_queue
    all_job_ids = (
        queue.get_job_ids() +  # Queued
        queue.started_job_registry.get_job_ids() +  # Started
        queue.finished_job_registry.get_job_ids()[:limit] +  # Finished (limited)
        queue.failed_job_registry.get_job_ids()[:limit]  # Failed (limited)
    )

    # Filter jobs by project_id and status
    project_jobs = []
    for job_id in all_job_ids:
        if len(project_jobs) >= limit:
            break

        try:
            rq_job = queue_config.get_job(job_id)
            if not rq_job:
                continue

            job_meta = rq_job.meta or {}
            job_project_id = job_meta.get('project_id')

            if job_project_id == project_id:
                job_dict = _rq_job_to_dict(rq_job)

                # Apply status filter if specified
                if status and job_dict['status'] != status:
                    continue

                project_jobs.append(job_dict)

        except Exception as e:
            logger.warning(f"Error processing job {job_id}: {e}")
            continue

    # Sort jobs by created_at (newest first)
    project_jobs.sort(key=lambda x: x.get('created_at', ''), reverse=True)

    return [JobResponse(**job) for job in project_jobs]


@router.get("/projects/{project_id}/jobs/stream")
async def stream_project_jobs(
    request: Request,
    project_id: str,
    timeout: int = Query(300, description="Timeout in seconds"),
    current_user: User = Depends(get_current_user),
    current_org: Organization = Depends(get_current_organization),
    db: AsyncSession = Depends(get_db)
):
    """
    Stream all RQ job updates for a project using Server-Sent Events (SSE).

    Note: For real-time updates, consider using WebSocket endpoint /ws/jobs instead.

    This endpoint will stream real-time updates about all jobs in a project.

    Args:
        project_id: The project ID to monitor
        timeout: Maximum time to stream in seconds (default 5 minutes)

    Returns:
        SSE stream with job updates for the project
    """
    try:
        # Validate project ID format
        project_uuid = uuid.UUID(project_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid project ID format")

    # Validate that project exists and belongs to current organization
    result = await db.execute(
        select(Project).where(Project.id == project_uuid)
    )
    project = result.scalar_one_or_none()

    if not project:
        raise HTTPException(status_code=404, detail=f"Project {project_id} not found")

    if project.organization_id != current_org.id:
        # Return 404 to prevent information disclosure
        raise HTTPException(status_code=404, detail=f"Project {project_id} not found")

    async def event_generator():
        """Generate SSE events for project jobs."""
        start_time = asyncio.get_event_loop().time()
        sent_jobs = set()

        try:
            while True:
                # Check if client disconnected
                if await request.is_disconnected():
                    logger.info(f"Client disconnected from project job stream {sanitize_for_log(project_id)}")
                    break

                # Check timeout
                if asyncio.get_event_loop().time() - start_time > timeout:
                    yield f"event: timeout\ndata: {json.dumps({'message': 'Stream timeout reached'})}\n\n"
                    break

                # Get all jobs from queue for this project
                queue = queue_config.default_queue
                all_job_ids = (
                    queue.get_job_ids() +
                    queue.started_job_registry.get_job_ids() +
                    queue.finished_job_registry.get_job_ids()[:100] +
                    queue.failed_job_registry.get_job_ids()[:100]
                )

                # Filter and send updates for project jobs
                for job_id in all_job_ids:
                    try:
                        rq_job = queue_config.get_job(job_id)
                        if not rq_job:
                            continue

                        job_meta = rq_job.meta or {}
                        if job_meta.get('project_id') == project_id:
                            job_dict = _rq_job_to_dict(rq_job)
                            job_key = f"{job_id}:{job_dict['status']}:{job_dict['progress']}"

                            if job_key not in sent_jobs:
                                sent_jobs.add(job_key)

                                event_data = {
                                    "job_id": job_id,
                                    "status": job_dict['status'],
                                    "progress": job_dict['progress'],
                                    "job_type": job_dict['job_type'],
                                    "filename": job_dict['filename'],
                                    "created_at": job_dict['created_at']
                                }

                                yield f"event: job_update\ndata: {json.dumps(event_data)}\n\n"

                    except Exception as e:
                        logger.warning(f"Error processing job {job_id} in stream: {e}")
                        continue

                # Send heartbeat
                yield f"event: heartbeat\ndata: {json.dumps({'timestamp': asyncio.get_event_loop().time()})}\n\n"

                # Wait before next check
                await asyncio.sleep(1)

        except asyncio.CancelledError:
            logger.info(f"Project job stream cancelled for {sanitize_for_log(project_id)}")
            yield f"event: cancelled\ndata: {json.dumps({'message': 'Stream cancelled'})}\n\n"
        except Exception as e:
            logger.error(f"Error in project job stream for {sanitize_for_log(project_id)}: {sanitize_for_log(str(e))}", exc_info=True)
            yield f"event: error\ndata: {json.dumps({'message': 'Internal error occurred'})}\n\n"

    return StreamingResponse(
        event_generator(),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
            "X-Accel-Buffering": "no"  # Disable nginx buffering
        }
    )