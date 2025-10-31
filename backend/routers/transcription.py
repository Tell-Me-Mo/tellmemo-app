"""
HTTP endpoints for audio file transcription.
Handles file uploads and batch transcription processing.
"""

import asyncio
import os
import shutil
import logging
import uuid
from typing import Optional
from datetime import datetime, date
from pathlib import Path
import tempfile

from fastapi import APIRouter, UploadFile, File, Form, HTTPException, Depends
from fastapi.responses import JSONResponse
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from db.database import get_db
from dependencies.auth import get_current_organization
from models.organization import Organization
from utils.logger import sanitize_for_log
from models.content import Content, ContentType
from config import get_settings
from queue_config import queue_config

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/v1", tags=["transcription"])


@router.post("/transcribe")
async def transcribe_audio(
    audio_file: UploadFile = File(...),
    project_id: str = Form(...),
    meeting_title: Optional[str] = Form(None),
    language: Optional[str] = Form("auto", description="Language code (e.g., 'en', 'es', 'fr') or 'auto' for automatic detection"),
    timestamp: Optional[str] = Form(None),
    use_ai_matching: bool = Form(False, description="Use AI to match to project if project_id is 'auto'"),
    transcription_text: Optional[str] = Form(None, description="Pre-existing transcription text from live recording (skips audio transcription)"),
    transcription_segments: Optional[str] = Form(None, description="JSON array of transcription segments with timing info"),
    db: AsyncSession = Depends(get_db),
    current_org: Organization = Depends(get_current_organization)
):
    """
    Transcribe an uploaded audio file asynchronously.

    This endpoint immediately returns a job ID and processes the transcription
    in the background. Use the job status endpoint to track progress.

    Supported formats: MP3, WAV, M4A, AAC, OGG, FLAC, WEBM, AIFF, WMA, MP4, MOV, MKV, AVI

    Args:
        background_tasks: FastAPI background tasks handler
        audio_file: The audio file to transcribe (various audio/video formats supported)
        project_id: ID of the project this recording belongs to
        meeting_title: Optional title for the meeting
        language: Language code for transcription (default: "en")
        timestamp: Optional timestamp for the recording
        db: Database session

    Returns:
        JSON response with job ID for tracking transcription progress
    """
    try:
        # Validate file size
        settings = get_settings()
        max_size_bytes = settings.max_audio_file_size_mb * 1024 * 1024
        file_size = 0
        temp_file_path = None
        temp_file_path_for_cleanup = None  # Original path for cleanup
        task_queued = False  # Track if background task was successfully queued

        # Create temp directory inside uploads (container-accessible)
        # Use /app/uploads/temp_audio in production, backend/uploads/temp_audio in dev
        uploads_base = Path("/app/uploads") if os.path.exists("/app/uploads") else Path(__file__).parent.parent / "uploads"
        temp_dir = uploads_base / "temp_audio"
        temp_dir.mkdir(parents=True, exist_ok=True)

        try:
            # Save uploaded file to temporary location
            with tempfile.NamedTemporaryFile(
                delete=False,
                dir=temp_dir,
                suffix=Path(audio_file.filename).suffix
            ) as temp_file:
                shutil.copyfileobj(audio_file.file, temp_file)
                temp_file_path = temp_file.name
                file_size = os.path.getsize(temp_file_path)

            # Save original path for cleanup before converting to container path
            temp_file_path_for_cleanup = temp_file_path

            # Only convert to container path if RQ worker is in Docker
            # Check if we're in a Docker environment by looking for /.dockerenv
            is_docker = os.path.exists('/.dockerenv')

            if is_docker and not temp_file_path.startswith("/app/"):
                # Running on host FastAPI but worker is in Docker - convert to container path
                temp_file_name = Path(temp_file_path).name
                temp_file_path = f"/app/uploads/temp_audio/{temp_file_name}"
            # If both FastAPI and RQ worker are on host, keep the local path as-is

            # Check file size
            if file_size > max_size_bytes:
                raise HTTPException(
                    status_code=413,
                    detail=f"File too large. Maximum size is {settings.max_audio_file_size_mb}MB"
                )

            if file_size == 0:
                raise HTTPException(
                    status_code=400,
                    detail="Audio file is empty"
                )

            logger.info(f"Received audio file: {audio_file.filename}, size: {file_size} bytes")

            # Validate project ownership (multi-tenant isolation)
            # Skip validation only if using AI matching with "auto" project_id
            if project_id != "auto" or not use_ai_matching:
                try:
                    # Convert project_id to UUID and validate it belongs to current organization
                    project_uuid = uuid.UUID(project_id)

                    # Query project with organization check
                    from models.project import Project
                    result = await db.execute(
                        select(Project).where(
                            Project.id == project_uuid,
                            Project.organization_id == current_org.id
                        )
                    )
                    project = result.scalar_one_or_none()

                    if not project:
                        raise HTTPException(
                            status_code=404,
                            detail="Project not found"
                        )

                    logger.info(f"Project validation passed: {project_uuid} belongs to org {current_org.id}")

                except ValueError:
                    # Invalid UUID format
                    raise HTTPException(
                        status_code=400,
                        detail="Invalid project_id format"
                    )

            # Enqueue RQ task for transcription processing
            from tasks.transcription_tasks import process_audio_transcription_task

            rq_job = queue_config.high_queue.enqueue(
                process_audio_transcription_task,
                temp_file_path=temp_file_path,
                project_id=project_id,
                meeting_title=meeting_title,
                language=language,
                tracking_job_id=None,
                file_size=file_size,
                filename=audio_file.filename,
                organization_id=str(current_org.id),  # Convert UUID to string for RQ serialization
                use_ai_matching=use_ai_matching,
                transcription_text=transcription_text,  # Pass pre-existing transcription if available
                transcription_segments=transcription_segments,  # Pass segments if available
                job_timeout='30m',  # 30 minute timeout for long transcriptions
                result_ttl=3600,  # Keep result for 1 hour
                failure_ttl=86400  # Keep failed jobs for 24 hours
            )

            task_queued = True  # Mark as successfully queued
            logger.info(f"Queued transcription job (RQ job: {rq_job.id})")

            # Initialize RQ job metadata for progress tracking
            rq_job.meta['status'] = 'processing'
            rq_job.meta['progress'] = 2.0
            rq_job.meta['step'] = 'Audio file uploaded, queuing for transcription...'
            rq_job.meta['current_step'] = 0
            rq_job.meta['total_steps'] = 8
            rq_job.meta['filename'] = audio_file.filename
            rq_job.meta['project_id'] = project_id
            rq_job.save_meta()

            # Return RQ job ID directly to Flutter
            return JSONResponse(content={
                "job_id": rq_job.id,  # Return RQ job ID directly
                "status": "processing",
                "message": "Audio file uploaded successfully. Transcription in progress.",
                "metadata": {
                    "project_id": project_id,
                    "meeting_title": meeting_title,
                    "language": language,
                    "filename": audio_file.filename,
                    "file_size": file_size
                }
            })

        finally:
            # Clean up temp file if task was not successfully queued
            # If queued, the background task is responsible for cleanup
            if not task_queued and temp_file_path_for_cleanup and os.path.exists(temp_file_path_for_cleanup):
                try:
                    os.unlink(temp_file_path_for_cleanup)
                    logger.debug(f"Cleaned up temp file: {temp_file_path_for_cleanup}")
                except Exception as cleanup_error:
                    logger.error(f"Failed to clean up temp file {temp_file_path_for_cleanup}: {cleanup_error}")

    except HTTPException:
        # RQ job will be marked as failed automatically
        raise
    except Exception as e:
        logger.error(f"Transcription error: {sanitize_for_log(str(e))}", exc_info=True)
        # RQ job will be marked as failed automatically
        raise HTTPException(
            status_code=500,
            detail=f"Transcription error: {str(e)}"
        )


@router.get("/languages")
async def get_supported_languages():
    """
    Get list of supported languages for transcription.
    """
    # Whisper supports many languages
    # Here are the most common ones
    languages = [
        "en",  # English
        "es",  # Spanish
        "fr",  # French
        "de",  # German
        "it",  # Italian
        "pt",  # Portuguese
        "ru",  # Russian
        "zh",  # Chinese
        "ja",  # Japanese
        "ko",  # Korean
        "ar",  # Arabic
        "hi",  # Hindi
        "nl",  # Dutch
        "pl",  # Polish
        "tr",  # Turkish
        "sv",  # Swedish
        "da",  # Danish
        "no",  # Norwegian
        "fi",  # Finnish
        "he",  # Hebrew
    ]
    
    return JSONResponse(content={
        "languages": languages,
        "default": "en"
    })


@router.get("/health")
async def check_transcription_health():
    """
    Check if transcription service is healthy.
    """
    try:
        whisper_service = get_whisper_service()
        is_ready = whisper_service.is_model_loaded()
        
        return JSONResponse(content={
            "status": "healthy" if is_ready else "not_ready",
            "model_loaded": is_ready,
            "service": "transcription"
        })
    except Exception as e:
        logger.error(f"Health check failed: {sanitize_for_log(str(e))}", exc_info=True)
        return JSONResponse(
            status_code=503,
            content={
                "status": "unhealthy",
                "error": "Service health check failed"
            }
        )