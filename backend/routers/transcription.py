"""
HTTP endpoints for audio file transcription.
Handles file uploads and batch transcription processing.
"""

import os
import shutil
import logging
import uuid
from typing import Optional
from datetime import datetime, date
from pathlib import Path
import tempfile

from fastapi import APIRouter, UploadFile, File, Form, HTTPException, Depends, BackgroundTasks
from fastapi.responses import JSONResponse
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from db.database import get_db
from dependencies.auth import get_current_organization
from models.organization import Organization
from services.transcription.whisper_service import get_whisper_service
from services.transcription.salad_transcription_service import get_salad_service
from services.core.content_service import ContentService
from services.core.upload_job_service import upload_job_service, JobType, JobStatus
from services.integrations.integration_service import integration_service
from services.intelligence.project_matcher_service import project_matcher_service
from models.content import Content, ContentType
from models.integration import Integration, IntegrationType, IntegrationStatus
from config import get_settings

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api", tags=["transcription"])


async def process_audio_transcription(
    temp_file_path: str,
    project_id: str,
    meeting_title: Optional[str],
    language: str,
    job_id: str,
    file_size: int,
    filename: str,
    organization_id: uuid.UUID,
    use_ai_matching: bool = False
):
    """
    Background task to process audio transcription.

    This function handles the actual transcription work:
    1. Transcribes the audio file
    2. Saves the transcription to database
    3. Triggers content processing for embeddings
    4. Triggers summary generation
    """
    from db.database import db_manager

    try:
        async with db_manager.sessionmaker() as db:
            # Update job: starting transcription
            upload_job_service.update_job_progress(
                job_id,
                current_step=1,
                status=JobStatus.PROCESSING,
                progress=5.0,
                step_description="Loading AI model..."
            )

            # Get settings for environment variable defaults
            settings = get_settings()

            # Check for transcription integration configuration (UI settings override env vars)
            transcription_config = await integration_service.get_integration_config(
                db,
                IntegrationType.TRANSCRIPTION,
                organization_id
            )

            # Determine which transcription service to use
            # Priority: UI Integration settings > Environment variables > Default (whisper)
            use_salad = False
            salad_api_key = None
            salad_org = None

            if transcription_config:
                # UI Integration settings take precedence
                custom_settings = transcription_config.get('custom_settings', {})
                service_type = custom_settings.get('service_type', 'whisper')
                use_salad = (service_type == 'salad')
                if use_salad:
                    salad_api_key = transcription_config.get('api_key')
                    salad_org = custom_settings.get('organization_name')
            else:
                # Fall back to environment variable configuration
                use_salad = (settings.default_transcription_service.lower() == 'salad')
                if use_salad:
                    salad_api_key = settings.salad_api_key
                    salad_org = settings.salad_organization_name

            # Create progress callback for transcription
            async def transcription_progress(progress: float, description: str):
                # Map transcription progress (0-100%) to overall job progress (10-65%)
                job_progress = 10.0 + (progress * 0.55)  # 10% to 65% range
                upload_job_service.update_job_progress(
                    job_id,
                    progress=job_progress,
                    step_description=description
                )

            # Transcribe using selected service
            logger.info(f"Starting transcription for file: {temp_file_path} using {'Salad' if use_salad else 'Whisper'}")

            if use_salad:
                # Use Salad transcription service
                try:
                    # Validate Salad credentials
                    if not salad_api_key or not salad_org:
                        raise ValueError("Salad API key and organization name are required. Configure via UI Integration settings or environment variables (SALAD_API_KEY, SALAD_ORGANIZATION_NAME).")

                    salad_service = get_salad_service(
                        api_key=salad_api_key,
                        organization_name=salad_org
                    )

                    upload_job_service.update_job_progress(
                        job_id,
                        progress=10.0,
                        step_description="Connecting to Salad API..."
                    )

                    # Pass language as None for auto-detection, or use specified language
                    # Auto-detection is preferred for better accuracy with multilingual content
                    transcription_language = None if language == "auto" else language

                    transcription_result = await salad_service.transcribe_audio_file(
                        audio_path=temp_file_path,
                        language=transcription_language,
                        progress_callback=transcription_progress
                    )
                except Exception as e:
                    raise Exception(f"Salad API error: {str(e)}")
            else:
                # Use local Whisper service
                whisper_service = get_whisper_service()

                # Update progress after model is loaded
                upload_job_service.update_job_progress(
                    job_id,
                    progress=10.0,
                    step_description="Model ready, starting transcription..."
                )

                transcription_result = await whisper_service.transcribe_audio_file(
                    audio_path=temp_file_path,
                    language=language,
                    progress_callback=transcription_progress
                )

            if not transcription_result:
                raise Exception("Transcription failed - no result returned")

            # Extract text and segments
            transcription_text = transcription_result.get("text", "")
            segments = transcription_result.get("segments", [])
            detected_language = transcription_result.get("language", language)

            if not transcription_text:
                raise Exception("Transcription failed - no text generated")

            logger.info(f"Transcription completed: {len(transcription_text)} characters")

            # Update job: transcription complete, saving to database
            upload_job_service.update_job_progress(
                job_id,
                current_step=2,
                progress=66.0,
                step_description="Saving transcription to database"
            )

            # Calculate audio duration from segments
            audio_duration = 0
            if segments:
                audio_duration = max(seg.get("end", 0) for seg in segments)

            # Save to database
            content_id = None
            if transcription_text:
                try:
                    # Handle project matching if needed
                    if project_id == "auto" and use_ai_matching:
                        # Use AI to match transcription to project
                        match_result = await project_matcher_service.match_transcript_to_project(
                            session=db,
                            organization_id=organization_id,
                            transcript=transcription_text,
                            meeting_title=meeting_title or f"Recording - {datetime.now().strftime('%Y-%m-%d %H:%M')}",
                            meeting_date=datetime.now(),
                            participants=[]  # Could be extracted from transcription if needed
                        )

                        project_uuid = match_result["project_id"]
                        project_match_info = match_result

                        logger.info(
                            f"AI Matching Result: {'Created new' if match_result['is_new'] else 'Matched to existing'} "
                            f"project '{match_result['project_name']}' (confidence: {match_result['confidence']})"
                        )

                        # Update job metadata with match info AND actual project_id
                        upload_job_service.update_job_metadata(
                            job_id,
                            {
                                "ai_matched": True,
                                "is_new_project": match_result['is_new'],
                                "match_confidence": match_result['confidence'],
                                "project_name": match_result['project_name'],
                                "project_id": str(project_uuid)  # Add actual project UUID
                            }
                        )
                    else:
                        # Convert project_id to UUID if it's not already
                        try:
                            project_uuid = uuid.UUID(project_id)
                        except ValueError:
                            # If project_id is not a valid UUID, generate one based on the string
                            project_uuid = uuid.uuid5(uuid.NAMESPACE_DNS, project_id)
                            logger.info(f"Generated UUID for project_id '{project_id}': {project_uuid}")

                    # Format the title with metadata
                    title = meeting_title or f"Recording - {datetime.now().strftime('%Y-%m-%d %H:%M')}"

                    # Add metadata to the content text as a header
                    metadata_header = f"[Audio Recording - Duration: {int(audio_duration)}s, Language: {detected_language}]\n\n"
                    full_content = metadata_header + transcription_text

                    # Create content record using static method
                    content = await ContentService.create_content(
                        session=db,
                        project_id=project_uuid,
                        content_type=ContentType.MEETING,
                        title=title,
                        content=full_content,
                        content_date=datetime.now().date(),
                        uploaded_by="transcription_service"
                    )

                    await db.commit()

                    content_id = str(content.id)
                    logger.info(f"Saved transcription to database with ID: {content_id}")

                    # Update job: triggering async processing
                    upload_job_service.update_job_progress(
                        job_id,
                        current_step=3,
                        progress=70.0,
                        step_description="Starting content processing"
                    )

                    # Trigger async processing for embeddings and summary generation
                    await ContentService.trigger_async_processing(content.id, job_id)
                    logger.info(f"Triggered async processing for content ID: {content_id} with job {job_id}")

                    # Update job progress
                    upload_job_service.update_job_progress(
                        job_id,
                        current_step=4,
                        progress=75.0,
                        step_description="Processing content and generating summary",
                        result={"content_id": content_id}
                    )

                except Exception as e:
                    logger.error(f"Failed to save to database: {e}")
                    raise

    except Exception as e:
        logger.error(f"Transcription background task error: {e}", exc_info=True)
        await upload_job_service.fail_job(job_id, str(e))
    finally:
        # Clean up temp file
        try:
            if os.path.exists(temp_file_path):
                os.unlink(temp_file_path)
                logger.info(f"Cleaned up temp file: {temp_file_path}")
        except Exception as e:
            logger.warning(f"Failed to delete temp file: {e}")


@router.post("/transcribe")
async def transcribe_audio(
    background_tasks: BackgroundTasks,
    audio_file: UploadFile = File(...),
    project_id: str = Form(...),
    meeting_title: Optional[str] = Form(None),
    language: Optional[str] = Form("auto", description="Language code (e.g., 'en', 'es', 'fr') or 'auto' for automatic detection"),
    timestamp: Optional[str] = Form(None),
    use_ai_matching: bool = Form(False, description="Use AI to match to project if project_id is 'auto'"),
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
        # Validate file size (max 100MB)
        file_size = 0
        temp_file_path = None

        # Create temp directory if it doesn't exist
        temp_dir = Path("backend/temp_audio")
        temp_dir.mkdir(parents=True, exist_ok=True)

        # Save uploaded file to temporary location
        with tempfile.NamedTemporaryFile(
            delete=False,
            dir=temp_dir,
            suffix=Path(audio_file.filename).suffix
        ) as temp_file:
            shutil.copyfileobj(audio_file.file, temp_file)
            temp_file_path = temp_file.name
            file_size = os.path.getsize(temp_file_path)

        # Check file size
        if file_size > 100 * 1024 * 1024:  # 100MB
            os.unlink(temp_file_path)
            raise HTTPException(
                status_code=413,
                detail="File too large. Maximum size is 100MB"
            )

        if file_size == 0:
            os.unlink(temp_file_path)
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
                    # Clean up temp file before returning error
                    if temp_file_path and os.path.exists(temp_file_path):
                        os.unlink(temp_file_path)
                    raise HTTPException(
                        status_code=404,
                        detail="Project not found"
                    )

                logger.info(f"Project validation passed: {project_id} belongs to org {current_org.id}")

            except ValueError:
                # Invalid UUID format
                if temp_file_path and os.path.exists(temp_file_path):
                    os.unlink(temp_file_path)
                raise HTTPException(
                    status_code=400,
                    detail="Invalid project_id format"
                )

        # Create job for tracking transcription and processing progress
        job_id = upload_job_service.create_job(
            project_id=project_id,
            job_type=JobType.TRANSCRIPTION,
            filename=audio_file.filename,
            file_size=file_size,
            total_steps=8,  # Upload, Transcribe, Save, Preprocess, Chunk, Embed, Store, Summary
            metadata={"language": language, "meeting_title": meeting_title}
        )

        # Update job: file uploaded, queuing for transcription
        upload_job_service.update_job_progress(
            job_id,
            current_step=0,
            status=JobStatus.PROCESSING,
            progress=2.0,
            step_description="Audio file uploaded, queuing for transcription..."
        )

        # Add background task to process transcription
        background_tasks.add_task(
            process_audio_transcription,
            temp_file_path=temp_file_path,
            project_id=project_id,
            meeting_title=meeting_title,
            language=language,
            job_id=job_id,
            file_size=file_size,
            filename=audio_file.filename,
            organization_id=current_org.id,
            use_ai_matching=use_ai_matching
        )

        logger.info(f"Queued transcription job {job_id} for processing")

        # Return immediately with job ID
        return JSONResponse(content={
            "job_id": job_id,
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
        
    except HTTPException:
        # Update job as failed if exists
        if 'job_id' in locals():
            await upload_job_service.fail_job(job_id, "Transcription failed")
        raise
    except Exception as e:
        logger.error(f"Transcription error: {e}", exc_info=True)
        # Update job as failed if exists
        if 'job_id' in locals():
            await upload_job_service.fail_job(job_id, str(e))
        # Clean up temp file if it exists
        if temp_file_path and os.path.exists(temp_file_path):
            try:
                os.unlink(temp_file_path)
            except:
                pass
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
        logger.error(f"Health check failed: {e}")
        return JSONResponse(
            status_code=503,
            content={
                "status": "unhealthy",
                "error": str(e)
            }
        )