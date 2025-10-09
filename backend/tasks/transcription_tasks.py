"""
RQ Task for Audio Transcription Processing

This module contains RQ tasks for processing audio transcription jobs.
RQ tasks must be synchronous, so we wrap async code with asyncio.run().
"""

import os
import asyncio
import logging
import uuid
from typing import Optional
from datetime import datetime
from pathlib import Path
from rq import get_current_job

from config import get_settings
from services.transcription.whisper_service import get_whisper_service
from services.transcription.salad_transcription_service import get_salad_service
from services.transcription.replicate_transcription_service import get_replicate_service
from services.core.content_service import ContentService
from services.integrations.integration_service import integration_service
from services.intelligence.project_matcher_service import project_matcher_service
from models.content import ContentType
from models.integration import IntegrationType
from utils.logger import sanitize_for_log
from queue_config import queue_config

logger = logging.getLogger(__name__)


def process_audio_transcription_task(
    temp_file_path: str,
    project_id: str,
    meeting_title: Optional[str],
    language: str,
    tracking_job_id: str,
    file_size: int,
    filename: str,
    organization_id: str,  # UUID as string for RQ serialization
    use_ai_matching: bool = False
):
    """
    RQ Task: Process audio transcription.

    This is a synchronous wrapper around async transcription logic.
    RQ requires synchronous functions, so we use asyncio.run() internally.

    Args:
        temp_file_path: Path to temporary audio file
        project_id: Project UUID or 'auto'
        meeting_title: Optional meeting title
        language: Language code or 'auto'
        tracking_job_id: Upload job tracking ID
        file_size: File size in bytes
        filename: Original filename
        organization_id: Organization UUID (as string)
        use_ai_matching: Whether to use AI project matching

    Note:
        This function runs in RQ worker process, not FastAPI process.
        Use job.meta for progress tracking.
    """
    # Get current RQ job for progress tracking
    rq_job = get_current_job()

    try:
        # Convert organization_id string back to UUID
        org_uuid = uuid.UUID(organization_id)

        # Update RQ job metadata and publish to Redis
        if rq_job:
            rq_job.meta['status'] = 'processing'
            rq_job.meta['progress'] = 0.0
            rq_job.meta['step'] = 'Starting transcription'
            rq_job.save_meta()

            # Publish update via Redis pub/sub for real-time updates
            queue_config.publish_job_update(rq_job.id, {
                'status': 'processing',
                'progress': 0.0,
                'step': 'Starting transcription'
            })

        # Run async transcription in event loop
        result = asyncio.run(
            _process_transcription_async(
                temp_file_path=temp_file_path,
                project_id=project_id,
                meeting_title=meeting_title,
                language=language,
                tracking_job_id=tracking_job_id,
                file_size=file_size,
                filename=filename,
                organization_id=org_uuid,
                use_ai_matching=use_ai_matching,
                rq_job=rq_job
            )
        )

        # Update RQ job metadata on success
        # NOTE: Don't mark as fully completed (100%) because content processing is still ongoing
        # The frontend should check for content_processing_job_id in metadata and track that job
        if rq_job:
            rq_job.meta['status'] = 'processing'  # Keep as processing, not completed
            rq_job.meta['progress'] = 75.0  # Transcription done, but content processing ongoing
            rq_job.meta['step'] = 'Transcription complete. Processing content and generating summary...'
            rq_job.meta['result'] = result
            rq_job.meta['transcription_phase_complete'] = True  # Flag to indicate transcription is done
            rq_job.save_meta()

            # Publish via Redis
            queue_config.publish_job_update(rq_job.id, {
                'status': 'processing',
                'progress': 75.0,
                'step': 'Transcription complete. Processing content and generating summary...'
            })

        logger.info(f"Transcription task completed successfully for job {tracking_job_id}")
        return result

    except asyncio.CancelledError:
        logger.info(f"Transcription job {tracking_job_id} was cancelled")

        if rq_job:
            rq_job.meta['status'] = 'cancelled'
            rq_job.meta['error'] = 'Job was cancelled by user'
            rq_job.save_meta()

            # Publish via Redis
            queue_config.publish_job_update(rq_job.id, {
                'status': 'cancelled',
                'error': 'Job was cancelled by user'
            })

        raise

    except Exception as e:
        error_msg = f"Transcription failed: {sanitize_for_log(str(e))}"
        logger.error(f"Transcription task error: {error_msg}", exc_info=True)

        # Update RQ job metadata
        if rq_job:
            rq_job.meta['status'] = 'failed'
            rq_job.meta['error'] = error_msg
            rq_job.save_meta()

            # Publish via Redis
            queue_config.publish_job_update(rq_job.id, {
                'status': 'failed',
                'error': error_msg
            })

        raise

    finally:
        # Clean up temp file
        try:
            if os.path.exists(temp_file_path):
                os.unlink(temp_file_path)
                logger.info(f"Cleaned up temp file: {temp_file_path}")
        except Exception as e:
            logger.warning(f"Failed to delete temp file: {sanitize_for_log(str(e))}")


async def _process_transcription_async(
    temp_file_path: str,
    project_id: str,
    meeting_title: Optional[str],
    language: str,
    tracking_job_id: str,
    file_size: int,
    filename: str,
    organization_id: uuid.UUID,
    use_ai_matching: bool,
    rq_job
) -> dict:
    """
    Async implementation of transcription processing.

    This is the actual async logic extracted from the router.
    """
    from db.database import db_manager

    async with db_manager.sessionmaker() as db:
        # Update RQ job meta
        if rq_job:
            rq_job.meta['progress'] = 5.0
            rq_job.meta['step'] = 'Loading AI model'
            rq_job.meta['current_step'] = 1
            rq_job.save_meta()

            # Publish via Redis
            queue_config.publish_job_update(rq_job.id, {
                'status': 'processing',
                'progress': 5.0,
                'step': 'Loading AI model'
            })

        # Check if job was cancelled (via RQ)
        if rq_job and rq_job.is_canceled:
            logger.info(f"Job {tracking_job_id} was cancelled before transcription started")
            raise asyncio.CancelledError("Job cancelled by user")

        # Get settings
        settings = get_settings()

        # Check for transcription integration configuration
        transcription_config = await integration_service.get_integration_config(
            db,
            IntegrationType.TRANSCRIPTION,
            organization_id
        )

        # Determine transcription service
        service_type = 'whisper'  # Default
        service_config = {}

        if transcription_config:
            custom_settings = transcription_config.get('custom_settings', {})
            service_type = custom_settings.get('service_type', 'whisper')

            if service_type == 'salad':
                service_config = {
                    'api_key': transcription_config.get('api_key'),
                    'organization_name': custom_settings.get('organization_name')
                }
            elif service_type == 'replicate':
                service_config = {
                    'api_key': transcription_config.get('api_key')
                }
        else:
            # Fall back to environment variables
            service_type = settings.default_transcription_service.lower()

            if service_type == 'salad':
                service_config = {
                    'api_key': settings.salad_api_key,
                    'organization_name': settings.salad_organization_name
                }
            elif service_type == 'replicate':
                service_config = {
                    'api_key': settings.replicate_api_key
                }

        # Progress callback
        async def transcription_progress(progress: float, description: str):
            # Check if job was cancelled (via RQ)
            if rq_job and rq_job.is_canceled:
                raise asyncio.CancelledError("Job was cancelled by user")

            job_progress = 10.0 + (progress * 0.55)  # 10% to 65%

            # Update RQ job meta
            if rq_job:
                rq_job.meta['progress'] = job_progress
                rq_job.meta['step'] = description
                rq_job.save_meta()

                # Publish via Redis for real-time updates
                queue_config.publish_job_update(rq_job.id, {
                    'status': 'processing',
                    'progress': job_progress,
                    'step': description
                })

        # Transcribe using selected service
        logger.info(f"Starting transcription: {temp_file_path} using {service_type.capitalize()}")

        transcription_language = None if language == "auto" else language

        if service_type == 'salad':
            if not service_config.get('api_key') or not service_config.get('organization_name'):
                raise ValueError("Salad API key and organization name required")

            salad_service = get_salad_service(
                api_key=service_config['api_key'],
                organization_name=service_config['organization_name']
            )

            if rq_job:
                rq_job.meta['progress'] = 10.0
                rq_job.meta['step'] = 'Connecting to Salad API...'
                rq_job.save_meta()

                # Publish via Redis
                queue_config.publish_job_update(rq_job.id, {
                    'status': 'processing',
                    'progress': 10.0,
                    'step': 'Connecting to Salad API...'
                })

            transcription_result = await salad_service.transcribe_audio_file(
                audio_path=temp_file_path,
                language=transcription_language,
                progress_callback=transcription_progress
            )

        elif service_type == 'replicate':
            if not service_config.get('api_key'):
                raise ValueError("Replicate API key required")

            replicate_service = get_replicate_service(
                api_key=service_config['api_key']
            )

            if rq_job:
                rq_job.meta['progress'] = 10.0
                rq_job.meta['step'] = 'Connecting to Replicate API...'
                rq_job.save_meta()

                # Publish via Redis
                queue_config.publish_job_update(rq_job.id, {
                    'status': 'processing',
                    'progress': 10.0,
                    'step': 'Connecting to Replicate API...'
                })

            transcription_result = await replicate_service.transcribe_audio_file(
                audio_path=temp_file_path,
                language=transcription_language,
                progress_callback=transcription_progress
            )

        else:
            # Local Whisper
            whisper_service = get_whisper_service()

            if rq_job:
                rq_job.meta['progress'] = 10.0
                rq_job.meta['step'] = 'Model ready, starting transcription...'
                rq_job.save_meta()

                # Publish via Redis
                queue_config.publish_job_update(rq_job.id, {
                    'status': 'processing',
                    'progress': 10.0,
                    'step': 'Model ready, starting transcription...'
                })

            transcription_result = await whisper_service.transcribe_audio_file(
                audio_path=temp_file_path,
                language=language,
                progress_callback=transcription_progress
            )

        if not transcription_result:
            raise Exception("Transcription failed - no result returned")

        # Extract results
        transcription_text = transcription_result.get("text", "")
        segments = transcription_result.get("segments", [])
        detected_language = transcription_result.get("language", language)

        if not transcription_text:
            raise Exception("Transcription failed - no text generated")

        logger.info(f"Transcription completed: {len(transcription_text)} characters")

        # Check cancellation (via RQ)
        if rq_job and rq_job.is_canceled:
            logger.info(f"Job {tracking_job_id} cancelled after transcription")
            raise asyncio.CancelledError("Job cancelled by user")

        # Update RQ job meta
        if rq_job:
            rq_job.meta['progress'] = 66.0
            rq_job.meta['step'] = 'Saving transcription to database'
            rq_job.meta['current_step'] = 2
            rq_job.save_meta()

            # Publish via Redis
            queue_config.publish_job_update(rq_job.id, {
                'status': 'processing',
                'progress': 66.0,
                'step': 'Saving transcription to database'
            })

        # Calculate audio duration
        audio_duration = 0
        if segments:
            audio_duration = max(seg.get("end", 0) for seg in segments)

        # Handle project matching
        if project_id == "auto" and use_ai_matching:
            match_result = await project_matcher_service.match_transcript_to_project(
                session=db,
                organization_id=organization_id,
                transcript=transcription_text,
                meeting_title=meeting_title or f"Recording - {datetime.now().strftime('%Y-%m-%d %H:%M')}",
                meeting_date=datetime.now(),
                participants=[]
            )

            project_uuid = match_result["project_id"]

            logger.info(
                f"AI Matching: {'Created new' if match_result['is_new'] else 'Matched to existing'} "
                f"project '{match_result['project_name']}' (confidence: {match_result['confidence']})"
            )

            # Store AI matching metadata in RQ job
            if rq_job:
                rq_job.meta['ai_matched'] = True
                rq_job.meta['is_new_project'] = match_result['is_new']
                rq_job.meta['match_confidence'] = match_result['confidence']
                rq_job.meta['project_name'] = match_result['project_name']
                rq_job.meta['project_id'] = str(project_uuid)
                rq_job.save_meta()
        else:
            try:
                project_uuid = uuid.UUID(project_id)
            except ValueError:
                project_uuid = uuid.uuid5(uuid.NAMESPACE_DNS, project_id)
                logger.info(f"Generated UUID for project_id '{project_id}': {project_uuid}")

        # Format title and content
        title = meeting_title or f"Recording - {datetime.now().strftime('%Y-%m-%d %H:%M')}"
        metadata_header = f"[Audio Recording - Duration: {int(audio_duration)}s, Language: {detected_language}]\n\n"
        full_content = metadata_header + transcription_text

        # Create content record
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
        logger.info(f"Saved transcription to database: {content_id}")

        # Update RQ job meta
        if rq_job:
            rq_job.meta['progress'] = 70.0
            rq_job.meta['step'] = 'Starting content processing'
            rq_job.meta['current_step'] = 3
            rq_job.save_meta()

            # Publish via Redis
            queue_config.publish_job_update(rq_job.id, {
                'status': 'processing',
                'progress': 70.0,
                'step': 'Starting content processing'
            })

        # Prepare metadata for content processing job, including parent job ID
        job_metadata = {
            'parent_transcription_job_id': rq_job.id if rq_job else None
        }

        # Trigger async processing and capture the child job ID
        content_processing_job_id = await ContentService.trigger_async_processing(
            content.id,
            job_metadata=job_metadata
        )
        logger.info(f"Triggered async processing for content {content_id} with job {tracking_job_id}, content processing job: {content_processing_job_id}")

        # Update RQ job meta with child job ID so frontend can track the complete pipeline
        if rq_job:
            rq_job.meta['progress'] = 75.0
            rq_job.meta['step'] = 'Transcription complete. Processing content and generating summary...'
            rq_job.meta['current_step'] = 4
            rq_job.meta['content_id'] = content_id
            rq_job.meta['content_processing_job_id'] = content_processing_job_id  # Store child job ID
            rq_job.meta['transcription_completed'] = True  # Mark transcription as done
            rq_job.save_meta()

        return {
            "content_id": content_id,
            "project_id": str(project_uuid),
            "transcription_length": len(transcription_text),
            "language": detected_language,
            "duration": audio_duration
        }
