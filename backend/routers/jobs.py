"""Job tracking and progress monitoring endpoints."""

from fastapi import APIRouter, HTTPException, Query, Request
from fastapi.responses import StreamingResponse
from typing import List, Optional
from pydantic import BaseModel
import asyncio
import json
import uuid

from services.core.upload_job_service import upload_job_service, JobStatus, JobType, UploadJob
from utils.logger import get_logger

router = APIRouter()
logger = get_logger(__name__)


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
async def get_active_jobs():
    """
    Get all currently active jobs (pending or processing).
    
    Returns:
        List of active jobs
    """
    jobs = upload_job_service.get_active_jobs()
    return [JobResponse(**job.to_dict()) for job in jobs]


@router.get("/jobs/stats", response_model=JobStatsResponse)
async def get_job_stats():
    """
    Get statistics about the job service.
    
    Returns:
        Service statistics including job counts and status breakdown
    """
    stats = upload_job_service.get_stats()
    return JobStatsResponse(**stats)


@router.get("/jobs/{job_id}", response_model=JobResponse)
async def get_job_status(job_id: str):
    """
    Get the status of a specific job.
    
    Args:
        job_id: The job ID to query
        
    Returns:
        Job information including progress and status
    """
    job = upload_job_service.get_job(job_id)
    if not job:
        raise HTTPException(status_code=404, detail=f"Job {job_id} not found")
    
    return JobResponse(**job.to_dict())


@router.post("/jobs/{job_id}/cancel")
async def cancel_job(job_id: str):
    """
    Cancel a job if it's still running.
    
    Args:
        job_id: The job ID to cancel
        
    Returns:
        Success message or error
    """
    success = upload_job_service.cancel_job(job_id)
    if not success:
        raise HTTPException(
            status_code=400,
            detail="Job cannot be cancelled (not found or already completed)"
        )
    
    return {"message": f"Job {job_id} has been cancelled"}


@router.get("/jobs/{job_id}/stream")
async def stream_job_progress(
    request: Request,
    job_id: str,
    timeout: int = Query(300, description="Timeout in seconds")
):
    """
    Stream job progress updates using Server-Sent Events (SSE).
    
    This endpoint will stream real-time updates about job progress until:
    - The job completes (success, failure, or cancellation)
    - The timeout is reached
    - The client disconnects
    
    Args:
        job_id: The job ID to monitor
        timeout: Maximum time to stream in seconds (default 5 minutes)
        
    Returns:
        SSE stream with job progress updates
    """
    job = upload_job_service.get_job(job_id)
    if not job:
        raise HTTPException(status_code=404, detail=f"Job {job_id} not found")
    
    async def event_generator():
        """Generate SSE events for job progress."""
        start_time = asyncio.get_event_loop().time()
        last_update = None
        
        try:
            while True:
                # Check if client disconnected
                if await request.is_disconnected():
                    logger.info(f"Client disconnected from job stream {job_id}")
                    break
                
                # Check timeout
                if asyncio.get_event_loop().time() - start_time > timeout:
                    yield f"event: timeout\ndata: {json.dumps({'message': 'Stream timeout reached'})}\n\n"
                    break
                
                # Get current job status
                job = upload_job_service.get_job(job_id)
                if not job:
                    yield f"event: error\ndata: {json.dumps({'message': 'Job not found'})}\n\n"
                    break
                
                # Send update if job changed
                current_update = (job.status, job.progress, job.current_step)
                if current_update != last_update:
                    event_data = {
                        "job_id": job_id,
                        "status": job.status.value,
                        "progress": job.progress,
                        "current_step": job.current_step,
                        "total_steps": job.total_steps,
                        "error_message": job.error_message,
                        "result": job.result
                    }
                    
                    # Send progress event
                    yield f"event: progress\ndata: {json.dumps(event_data)}\n\n"
                    last_update = current_update
                
                # Check if job is complete
                if job.status in [JobStatus.COMPLETED, JobStatus.FAILED, JobStatus.CANCELLED]:
                    # Send final status
                    yield f"event: {job.status.value}\ndata: {json.dumps(job.to_dict())}\n\n"
                    break
                
                # Wait a bit before next check
                await asyncio.sleep(0.5)
                
        except asyncio.CancelledError:
            logger.info(f"Job stream cancelled for {job_id}")
            yield f"event: cancelled\ndata: {json.dumps({'message': 'Stream cancelled'})}\n\n"
        except Exception as e:
            logger.error(f"Error in job stream for {job_id}: {e}")
            yield f"event: error\ndata: {json.dumps({'message': str(e)})}\n\n"
    
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
    limit: int = Query(50, description="Maximum number of jobs to return")
):
    """
    Get all jobs for a specific project.
    
    Args:
        project_id: Project ID
        status: Optional status filter (pending, processing, completed, failed, cancelled)
        limit: Maximum number of jobs to return
        
    Returns:
        List of jobs for the project
    """
    try:
        # Validate project ID
        uuid.UUID(project_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid project ID format")
    
    # Parse status filter
    status_filter = None
    if status:
        try:
            status_filter = JobStatus(status)
        except ValueError:
            raise HTTPException(
                status_code=400,
                detail=f"Invalid status: {status}. Must be one of: pending, processing, completed, failed, cancelled"
            )
    
    jobs = upload_job_service.get_project_jobs(project_id, status_filter, limit)
    return [JobResponse(**job.to_dict()) for job in jobs]


@router.get("/projects/{project_id}/jobs/stream")
async def stream_project_jobs(
    request: Request,
    project_id: str,
    timeout: int = Query(300, description="Timeout in seconds")
):
    """
    Stream all job updates for a project using Server-Sent Events (SSE).
    
    This endpoint will stream real-time updates about all jobs in a project.
    
    Args:
        project_id: The project ID to monitor
        timeout: Maximum time to stream in seconds (default 5 minutes)
        
    Returns:
        SSE stream with job updates for the project
    """
    try:
        # Validate project ID
        uuid.UUID(project_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid project ID format")
    
    async def event_generator():
        """Generate SSE events for project jobs."""
        start_time = asyncio.get_event_loop().time()
        sent_jobs = set()
        
        try:
            while True:
                # Check if client disconnected
                if await request.is_disconnected():
                    logger.info(f"Client disconnected from project job stream {project_id}")
                    break
                
                # Check timeout
                if asyncio.get_event_loop().time() - start_time > timeout:
                    yield f"event: timeout\ndata: {json.dumps({'message': 'Stream timeout reached'})}\n\n"
                    break
                
                # Get all project jobs
                jobs = upload_job_service.get_project_jobs(project_id, limit=100)
                
                # Send updates for new or changed jobs
                for job in jobs:
                    job_key = f"{job.job_id}:{job.status.value}:{job.progress}"
                    if job_key not in sent_jobs:
                        sent_jobs.add(job_key)
                        
                        event_data = {
                            "job_id": job.job_id,
                            "status": job.status.value,
                            "progress": job.progress,
                            "job_type": job.job_type.value,
                            "filename": job.filename,
                            "created_at": job.created_at.isoformat()
                        }
                        
                        yield f"event: job_update\ndata: {json.dumps(event_data)}\n\n"
                
                # Send heartbeat
                yield f"event: heartbeat\ndata: {json.dumps({'timestamp': asyncio.get_event_loop().time()})}\n\n"
                
                # Wait before next check
                await asyncio.sleep(1)
                
        except asyncio.CancelledError:
            logger.info(f"Project job stream cancelled for {project_id}")
            yield f"event: cancelled\ndata: {json.dumps({'message': 'Stream cancelled'})}\n\n"
        except Exception as e:
            logger.error(f"Error in project job stream for {project_id}: {e}")
            yield f"event: error\ndata: {json.dumps({'message': str(e)})}\n\n"
    
    return StreamingResponse(
        event_generator(),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
            "X-Accel-Buffering": "no"  # Disable nginx buffering
        }
    )