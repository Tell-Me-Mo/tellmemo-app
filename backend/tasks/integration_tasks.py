"""
RQ Task for External Integration Processing

This module contains RQ tasks for processing external integrations like Fireflies.ai.
"""

import asyncio
import logging
import uuid
from typing import Optional
from datetime import datetime
from rq import get_current_job

from services.transcription.fireflies_service import FirefliesService
from services.core.content_service import ContentService
from services.intelligence.project_matcher_service import project_matcher_service
from models.content import ContentType
from utils.logger import sanitize_for_log

logger = logging.getLogger(__name__)


def process_fireflies_transcript_task(
    meeting_id: str,
    api_key: str,
    organization_id: str,  # UUID as string
    project_id: Optional[str] = None,  # UUID as string or None
    use_smart_matching: bool = True
):
    """
    RQ Task: Process Fireflies.ai transcript webhook.

    This is a synchronous wrapper around async Fireflies processing logic.

    Args:
        meeting_id: Fireflies meeting ID
        api_key: Fireflies API key
        organization_id: Organization UUID (as string)
        project_id: Project UUID (as string, optional)
        use_smart_matching: Whether to use AI project matching

    Note:
        This function runs in RQ worker process.
        Use job.meta for progress tracking.
    """
    # Get current RQ job for progress tracking
    rq_job = get_current_job()

    job_id = None

    try:
        # Convert organization_id string to UUID
        org_uuid = uuid.UUID(organization_id)
        project_uuid = uuid.UUID(project_id) if project_id else None

        # Update RQ job metadata
        if rq_job:
            rq_job.meta['status'] = 'processing'
            rq_job.meta['progress'] = 0.0
            rq_job.meta['step'] = 'Starting Fireflies import'
            rq_job.save_meta()

        # Run async Fireflies processing in event loop
        result = asyncio.run(
            _process_fireflies_async(
                meeting_id=meeting_id,
                api_key=api_key,
                organization_id=org_uuid,
                project_id=project_uuid,
                use_smart_matching=use_smart_matching,
                rq_job=rq_job
            )
        )

        # Update RQ job metadata on success
        if rq_job:
            rq_job.meta['status'] = 'completed'
            rq_job.meta['progress'] = 100.0
            rq_job.meta['step'] = 'Completed'
            rq_job.meta['result'] = result
            rq_job.save_meta()

        logger.info(f"Fireflies processing task completed successfully for meeting {meeting_id}")
        return result

    except Exception as e:
        error_msg = f"Fireflies processing failed: {sanitize_for_log(str(e))}"
        logger.error(f"Fireflies processing task error: {error_msg}", exc_info=True)

        # Update RQ job metadata
        if rq_job:
            rq_job.meta['status'] = 'failed'
            rq_job.meta['error'] = error_msg
            rq_job.save_meta()

        raise


async def _process_fireflies_async(
    meeting_id: str,
    api_key: str,
    organization_id: uuid.UUID,
    project_id: Optional[uuid.UUID],
    use_smart_matching: bool,
    rq_job
) -> dict:
    """
    Async implementation of Fireflies transcript processing.
    """
    from db.database import db_manager

    async with db_manager.sessionmaker() as db:
        # Update RQ job meta
        if rq_job:
            rq_job.meta['progress'] = 10.0
            rq_job.meta['step'] = 'Fetching transcript from Fireflies'
            rq_job.meta['current_step'] = 1
            rq_job.save_meta()

        # Initialize Fireflies service and fetch meeting data
        fireflies_service = FirefliesService(api_key)
        meeting_data = await fireflies_service.get_meeting_transcription(meeting_id)

        # Update RQ job meta
        if rq_job:
            rq_job.meta['progress'] = 30.0
            rq_job.meta['step'] = f"Processing transcript: {meeting_data['title']}"
            rq_job.meta['current_step'] = 2
            rq_job.save_meta()

        # Parse date
        try:
            meeting_date = datetime.fromisoformat(meeting_data['date'].replace('Z', '+00:00'))
        except Exception as e:
            logger.warning(f"Failed to parse meeting date: {e}, using current date")
            meeting_date = datetime.now()

        # Handle project matching
        if use_smart_matching and not project_id:
            # Update RQ job meta
            if rq_job:
                rq_job.meta['progress'] = 40.0
                rq_job.meta['step'] = 'AI matching to project'
                rq_job.meta['current_step'] = 3
                rq_job.save_meta()

            # Use AI to match to project
            match_result = await project_matcher_service.match_transcript_to_project(
                session=db,
                organization_id=organization_id,
                transcript=meeting_data['transcript'],
                meeting_title=meeting_data['title'],
                meeting_date=meeting_date,
                participants=meeting_data.get('participants', [])
            )

            project_id = match_result["project_id"]

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
                rq_job.meta['project_id'] = str(project_id)
                rq_job.save_meta()

        # Update RQ job meta
        if rq_job:
            rq_job.meta['progress'] = 60.0
            rq_job.meta['step'] = 'Saving transcript to database'
            rq_job.meta['current_step'] = 4
            rq_job.save_meta()

        # Create content record
        content = await ContentService.create_content(
            session=db,
            project_id=project_id,
            content_type=ContentType.MEETING,
            title=meeting_data['title'],
            content=meeting_data['transcript'],
            content_date=meeting_date.date(),
            uploaded_by="fireflies_integration"
        )

        await db.commit()

        content_id = str(content.id)
        logger.info(f"Saved Fireflies transcript to database: {content_id}")

        # Update RQ job meta
        if rq_job:
            rq_job.meta['progress'] = 70.0
            rq_job.meta['step'] = 'Starting content processing'
            rq_job.meta['current_step'] = 5
            rq_job.save_meta()

        await ContentService.trigger_async_processing(content.id, None)

        # Update RQ job meta
        if rq_job:
            rq_job.meta['progress'] = 90.0
            rq_job.meta['step'] = 'Processing content and generating summary'
            rq_job.meta['current_step'] = 6
            rq_job.meta['content_id'] = content_id
            rq_job.save_meta()

        logger.info(f"Fireflies processing completed for meeting {meeting_id}")

        return {
            "content_id": content_id,
            "project_id": str(project_id),
            "meeting_id": meeting_id,
            "title": meeting_data['title']
        }
