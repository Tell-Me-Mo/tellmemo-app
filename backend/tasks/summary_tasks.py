"""
RQ Task for Summary Generation

This module contains RQ tasks for generating summaries (meeting, project, program, portfolio).
"""

import asyncio
import logging
import uuid
from typing import Optional
from datetime import datetime
from rq import get_current_job

from services.summaries.summary_service_refactored import summary_service
from utils.logger import sanitize_for_log

logger = logging.getLogger(__name__)


def generate_summary_task(
    tracking_job_id: str,
    entity_type: str,  # 'project', 'program', 'portfolio'
    entity_id: str,  # UUID as string
    entity_name: str,
    summary_type: str,  # 'meeting', 'project', 'program', 'portfolio'
    content_id: Optional[str] = None,  # For meeting summaries
    date_range_start: Optional[str] = None,  # ISO format
    date_range_end: Optional[str] = None,  # ISO format
    format_type: str = "general",
    created_by: Optional[str] = None,
    created_by_id: Optional[str] = None
):
    """
    RQ Task: Generate summary for any entity type.

    This is a synchronous wrapper around async summary generation logic.

    Args:
        tracking_job_id: Upload job tracking ID
        entity_type: Type of entity (project, program, portfolio)
        entity_id: Entity UUID (as string)
        entity_name: Entity name for display
        summary_type: Type of summary to generate
        content_id: Content UUID for meeting summaries (optional)
        date_range_start: Start date (ISO format)
        date_range_end: End date (ISO format)
        format_type: Summary format (general, executive, technical, stakeholder)
        created_by: User email
        created_by_id: User UUID (as string)

    Note:
        This function runs in RQ worker process.
        Use job.meta for progress tracking.
    """
    # Get current RQ job for progress tracking
    rq_job = get_current_job()

    try:
        # Convert string UUIDs to UUID objects
        entity_uuid = uuid.UUID(entity_id)
        content_uuid = uuid.UUID(content_id) if content_id else None
        created_by_uuid = uuid.UUID(created_by_id) if created_by_id else None

        # Parse dates
        start_date = datetime.fromisoformat(date_range_start) if date_range_start else None
        end_date = datetime.fromisoformat(date_range_end) if date_range_end else None

        # Update RQ job metadata
        if rq_job:
            from queue_config import queue_config

            rq_job.meta['status'] = 'processing'
            rq_job.meta['progress'] = 0.0
            rq_job.meta['step'] = 'Starting summary generation'
            rq_job.save_meta()

            # Publish via Redis pub/sub
            queue_config.publish_job_update(rq_job.id, {
                'status': 'processing',
                'progress': 0.0,
                'step': 'Starting summary generation'
            })

        # Run async summary generation in event loop
        result = asyncio.run(
            _generate_summary_async(
                entity_type=entity_type,
                entity_uuid=entity_uuid,
                entity_name=entity_name,
                summary_type=summary_type,
                content_uuid=content_uuid,
                start_date=start_date,
                end_date=end_date,
                format_type=format_type,
                created_by=created_by,
                created_by_uuid=created_by_uuid,
                rq_job=rq_job
            )
        )

        # Update RQ job metadata on success
        if rq_job:
            from queue_config import queue_config

            rq_job.meta['status'] = 'completed'
            rq_job.meta['progress'] = 100.0
            rq_job.meta['step'] = 'Completed'
            rq_job.meta['result'] = result
            rq_job.save_meta()

            # Publish via Redis pub/sub
            queue_config.publish_job_update(rq_job.id, {
                'status': 'completed',
                'progress': 100.0,
                'step': 'Completed'
            })

        logger.info(f"Summary generation task completed successfully")
        return result

    except Exception as e:
        error_msg = f"Summary generation failed: {sanitize_for_log(str(e))}"
        logger.error(f"Summary generation task error: {error_msg}", exc_info=True)

        # Update RQ job metadata
        if rq_job:
            from queue_config import queue_config

            rq_job.meta['status'] = 'failed'
            rq_job.meta['error'] = error_msg
            rq_job.save_meta()

            # Publish via Redis pub/sub
            queue_config.publish_job_update(rq_job.id, {
                'status': 'failed',
                'error': error_msg
            })

        raise


async def _generate_summary_async(
    entity_type: str,
    entity_uuid: uuid.UUID,
    entity_name: str,
    summary_type: str,
    content_uuid: Optional[uuid.UUID],
    start_date: Optional[datetime],
    end_date: Optional[datetime],
    format_type: str,
    created_by: Optional[str],
    created_by_uuid: Optional[uuid.UUID],
    rq_job
) -> dict:
    """
    Async implementation of summary generation.
    """
    from db.database import db_manager

    # Update RQ job meta
    if rq_job:
        from queue_config import queue_config

        rq_job.meta['progress'] = 10.0
        rq_job.meta['step'] = 'Initializing summary generation'
        rq_job.meta['current_step'] = 1
        rq_job.save_meta()

        # Publish via Redis pub/sub
        queue_config.publish_job_update(rq_job.id, {
            'status': 'processing',
            'progress': 10.0,
            'step': 'Initializing summary generation'
        })

    async with db_manager.sessionmaker() as session:
        # Update RQ job meta
        if rq_job:
            from queue_config import queue_config

            rq_job.meta['progress'] = 30.0
            rq_job.meta['step'] = 'Collecting and analyzing data'
            rq_job.meta['current_step'] = 2
            rq_job.save_meta()

            # Publish via Redis pub/sub
            queue_config.publish_job_update(rq_job.id, {
                'status': 'processing',
                'progress': 30.0,
                'step': 'Collecting and analyzing data'
            })

        # Generate summary based on type
        summary_data = None

        if summary_type == "meeting":
            if not content_uuid:
                raise ValueError("content_id required for meeting summaries")

            summary_data = await summary_service.generate_meeting_summary(
                session=session,
                project_id=entity_uuid,
                content_id=content_uuid,
                created_by=created_by,
                created_by_id=str(created_by_uuid) if created_by_uuid else None,
                rq_job=rq_job,
                format_type=format_type
            )

        elif summary_type == "project":
            summary_data = await summary_service.generate_project_summary(
                session=session,
                project_id=entity_uuid,
                week_start=start_date,
                week_end=end_date,
                created_by=created_by,
                created_by_id=str(created_by_uuid) if created_by_uuid else None,
                rq_job=rq_job,
                format_type=format_type
            )

        elif summary_type == "program":
            summary_data = await summary_service.generate_program_summary(
                session=session,
                program_id=entity_uuid,
                week_start=start_date,
                week_end=end_date,
                created_by=created_by,
                created_by_id=str(created_by_uuid) if created_by_uuid else None,
                rq_job=rq_job,
                format_type=format_type
            )

        elif summary_type == "portfolio":
            summary_data = await summary_service.generate_portfolio_summary(
                session=session,
                portfolio_id=entity_uuid,
                week_start=start_date,
                week_end=end_date,
                created_by=created_by,
                created_by_id=str(created_by_uuid) if created_by_uuid else None,
                rq_job=rq_job,
                format_type=format_type
            )

        else:
            raise ValueError(f"Unknown summary type: {summary_type}")

        # Update RQ job meta
        if rq_job:
            from queue_config import queue_config

            rq_job.meta['progress'] = 90.0
            rq_job.meta['step'] = 'Finalizing summary'
            rq_job.meta['current_step'] = 3
            rq_job.meta['summary_id'] = summary_data.get("id")
            rq_job.save_meta()

            # Publish via Redis pub/sub
            queue_config.publish_job_update(rq_job.id, {
                'status': 'processing',
                'progress': 90.0,
                'step': 'Finalizing summary'
            })

        logger.info(f"Summary generation completed")

        return {
            "summary_id": summary_data.get("id"),
            "entity_type": entity_type,
            "entity_id": str(entity_uuid),
            "summary_type": summary_type
        }
