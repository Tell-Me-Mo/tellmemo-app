"""
RQ Task for Content Processing (Embeddings, Chunking, Summaries)

This module contains RQ tasks for processing uploaded content.
"""

import asyncio
import logging
import uuid
from typing import Optional
from rq import get_current_job

from services.core.content_service import ContentService
from utils.logger import sanitize_for_log
from utils.rq_utils import check_cancellation
from queue_config import queue_config

logger = logging.getLogger(__name__)


def process_content_task(
    content_id: str,  # UUID as string for RQ serialization
    tracking_job_id: Optional[str] = None
):
    """
    RQ Task: Process content (chunking, embeddings, summary generation).

    This is a synchronous wrapper around async content processing logic.

    Args:
        content_id: Content UUID (as string)
        tracking_job_id: Optional upload job tracking ID

    Note:
        This function runs in RQ worker process.
        Use job.meta for progress tracking.
    """
    # Get current RQ job for progress tracking
    rq_job = get_current_job()

    try:
        # Convert content_id string back to UUID
        content_uuid = uuid.UUID(content_id)

        # Update RQ job metadata
        if rq_job:
            rq_job.meta['status'] = 'processing'
            rq_job.meta['progress'] = 0.0
            rq_job.meta['step'] = 'Starting content processing'
            rq_job.save_meta()

            # Publish via Redis
            queue_config.publish_job_update(rq_job.id, {
                'status': 'processing',
                'progress': 0.0,
                'step': 'Starting content processing'
            })

        # Run async content processing in event loop
        result = asyncio.run(
            _process_content_async(
                content_id=content_uuid,
                tracking_job_id=tracking_job_id,
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

            # Publish via Redis
            queue_config.publish_job_update(rq_job.id, {
                'status': 'completed',
                'progress': 100.0,
                'step': 'Completed'
            })

            # Update parent transcription job if it exists
            parent_job_id = rq_job.meta.get('parent_transcription_job_id')
            if parent_job_id:
                try:
                    # Get parent job and update its status using queue_config.get_job()
                    parent_job = queue_config.get_job(parent_job_id)
                    if parent_job:
                        parent_job.meta['status'] = 'completed'
                        parent_job.meta['progress'] = 100.0
                        parent_job.meta['step'] = 'All processing complete'
                        parent_job.meta['content_processing_completed'] = True
                        parent_job.save_meta()

                        # Publish parent job update via Redis
                        queue_config.publish_job_update(parent_job_id, {
                            'status': 'completed',
                            'progress': 100.0,
                            'step': 'All processing complete'
                        })

                        logger.info(f"Updated parent transcription job {parent_job_id} to completed status")
                except Exception as e:
                    logger.warning(f"Failed to update parent job {parent_job_id}: {e}")

        logger.info(f"Content processing task completed successfully for content {content_id}")
        return result

    except Exception as e:
        error_msg = f"Content processing failed: {sanitize_for_log(str(e))}"
        logger.error(f"Content processing task error: {error_msg}", exc_info=True)

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


@check_cancellation()
async def _process_content_async(
    content_id: uuid.UUID,
    tracking_job_id: Optional[str],
    rq_job
) -> dict:
    """
    Async implementation of content processing.

    Performs:
    1. Content preprocessing and cleaning
    2. Intelligent chunking
    3. Embedding generation
    4. Vector storage in Qdrant
    5. Auto-summary generation (for meetings)
    6. Project description analysis
    """
    from db.database import db_manager

    async for session in db_manager.get_session():
        try:
            # Update RQ job meta
            if rq_job:
                rq_job.meta['progress'] = 5.0
                rq_job.meta['step'] = 'Processing content'
                rq_job.save_meta()

                # Publish via Redis
                queue_config.publish_job_update(rq_job.id, {
                    'status': 'processing',
                    'progress': 5.0,
                    'step': 'Processing content'
                })

            # Call the existing async processing method with RQ job for progress tracking
            await ContentService.process_content_async(
                session=session,
                content_id=content_id,
                rq_job=rq_job
            )

            logger.info(f"Content processing completed for {content_id}")

            return {
                "content_id": str(content_id),
                "status": "completed"
            }

        except asyncio.CancelledError:
            logger.info(f"Content processing job cancelled for content {content_id}")
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
            logger.error(f"Content processing failed for {content_id}: {e}", exc_info=True)
            raise

        finally:
            # Exit after first iteration (get_session is async generator)
            break
