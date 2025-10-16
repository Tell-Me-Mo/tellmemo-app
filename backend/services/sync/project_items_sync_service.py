"""
Project Items Synchronization Service

This service handles the synchronization of risks, tasks, and lessons learned
from meeting summaries to project-level database tables.

It performs:
1. Extraction of items from meeting summary data
2. AI-powered deduplication against existing project items
3. Database updates with deduplicated items
"""

import logging
from typing import Dict, Any, List, Optional
from datetime import datetime
import uuid
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from models.risk import Risk, RiskSeverity, RiskStatus
from models.task import Task, TaskStatus, TaskPriority
from models.lesson_learned import LessonLearned, LessonCategory, LessonType, LessonLearnedImpact
from models.blocker import Blocker, BlockerImpact, BlockerStatus
from services.intelligence.risks_tasks_analyzer_service import RisksTasksAnalyzer
from services.intelligence.semantic_deduplicator import semantic_deduplicator
from services.item_updates_service import ItemUpdatesService
from config import get_settings

logger = logging.getLogger(__name__)


class ProjectItemsSyncService:
    """Service for synchronizing project items from meeting summaries."""

    def __init__(self):
        """Initialize the service."""
        self.analyzer = RisksTasksAnalyzer()
        self.semantic_deduplicator = semantic_deduplicator
        self.settings = get_settings()

    async def sync_items_from_summary(
        self,
        session: AsyncSession,
        project_id: uuid.UUID,
        content_id: uuid.UUID,
        summary_data: Dict[str, Any]
    ) -> Dict[str, Any]:
        """
        Synchronize project items from meeting summary data.

        Args:
            session: Database session
            project_id: Project ID
            content_id: Content ID (for tracking source)
            summary_data: Meeting summary data containing extracted items

        Returns:
            Dict with counts of synced items and any errors
        """
        logger.debug(f"[BLOCKER_DEBUG] sync_items_from_summary called")
        logger.debug(f"[BLOCKER_DEBUG] summary_data type: {type(summary_data)}")
        logger.debug(f"[BLOCKER_DEBUG] summary_data keys: {summary_data.keys() if isinstance(summary_data, dict) else 'Not a dict'}")

        result = {
            "risks_synced": 0,
            "blockers_synced": 0,
            "tasks_synced": 0,
            "lessons_synced": 0,
            "status_updates_processed": 0,
            "errors": []
        }

        try:
            # Extract items from summary data
            extracted_items = self._extract_items_from_summary(summary_data)

            # Get existing project items for deduplication
            existing_items = await self._get_existing_project_items(session, project_id)

            # Use semantic deduplication if enabled, otherwise fall back to AI-only
            if self.settings.enable_semantic_deduplication:
                logger.info("Using semantic deduplication with embeddings + AI")
                deduplicated_items = await self._semantic_deduplicate_items(
                    extracted_items, existing_items
                )
            else:
                logger.info("Using legacy AI-only deduplication")
                # Legacy AI-only deduplication
                deduplicated_items = await self.analyzer.deduplicate_extracted_items(
                    extracted_risks=extracted_items['risks'],
                    extracted_blockers=extracted_items['blockers'],
                    extracted_tasks=extracted_items['tasks'],
                    extracted_lessons=extracted_items['lessons'],
                    existing_risks=existing_items['risks'],
                    existing_blockers=existing_items['blockers'],
                    existing_tasks=existing_items['tasks'],
                    existing_lessons=existing_items['lessons']
                )

            # Process status updates first (update existing items with new info)
            status_updates = deduplicated_items.get('status_updates', [])
            if status_updates:
                logger.info(f"Processing {len(status_updates)} status updates")
                await self._process_status_updates(
                    session, project_id, content_id,
                    status_updates,
                    extracted_items,
                    existing_items
                )
                result['status_updates_processed'] = len(status_updates)
            else:
                result['status_updates_processed'] = 0

            # Update database with deduplicated items
            await self._update_project_risks(
                session, project_id, content_id,
                deduplicated_items.get('risks', []),
                existing_items['risks']
            )
            result['risks_synced'] = len(deduplicated_items.get('risks', []))

            await self._update_project_blockers(
                session, project_id, content_id,
                deduplicated_items.get('blockers', []),
                existing_items['blockers']
            )
            result['blockers_synced'] = len(deduplicated_items.get('blockers', []))

            await self._update_project_tasks(
                session, project_id, content_id,
                deduplicated_items.get('tasks', []),
                existing_items['tasks']
            )
            result['tasks_synced'] = len(deduplicated_items.get('tasks', []))

            await self._update_project_lessons(
                session, project_id, content_id,
                deduplicated_items.get('lessons_learned', []),
                existing_items['lessons']
            )
            result['lessons_synced'] = len(deduplicated_items.get('lessons_learned', []))

            # Commit all changes
            logger.debug(f"[BLOCKER_DEBUG] About to commit session with {result['blockers_synced']} blockers")
            await session.commit()
            logger.debug(f"[BLOCKER_DEBUG] Session committed successfully")

            # Verify blockers were actually saved
            if result['blockers_synced'] > 0:
                from sqlalchemy import select
                from models.blocker import Blocker
                verify_result = await session.execute(
                    select(Blocker).where(Blocker.project_id == project_id)
                )
                saved_blockers = verify_result.scalars().all()
                logger.debug(f"[BLOCKER_DEBUG] Verification: Found {len(saved_blockers)} blockers in DB for project {project_id}")
                for blocker in saved_blockers:
                    logger.debug(f"[BLOCKER_DEBUG] - Blocker in DB: {blocker.title} (ID: {blocker.id})")

            logger.info(
                f"Project items sync complete for content {content_id}: "
                f"{result['risks_synced']} risks, {result['blockers_synced']} blockers, "
                f"{result['tasks_synced']} tasks, {result['lessons_synced']} lessons, "
                f"{result['status_updates_processed']} status updates"
            )

        except Exception as e:
            logger.error(f"Failed to sync project items: {e}")
            result['errors'].append(str(e))
            await session.rollback()

        return result

    def _extract_items_from_summary(self, summary_data: Dict[str, Any]) -> Dict[str, List]:
        """
        Extract risks, blockers, tasks, and lessons from summary data.

        Args:
            summary_data: Meeting summary data

        Returns:
            Dict with extracted risks, blockers, tasks, and lessons
        """
        logger.debug(f"[BLOCKER_DEBUG] Extracting items from summary data keys: {summary_data.keys()}")

        # Extract risks and blockers from separate columns
        risks = summary_data.get('risks', [])
        blockers = summary_data.get('blockers', [])

        logger.debug(f"[BLOCKER_DEBUG] Raw blockers data type: {type(blockers)}")
        logger.debug(f"[BLOCKER_DEBUG] Raw blockers data: {blockers}")

        # Fallback to risks_and_blockers if separate columns are empty (backward compatibility)
        if not risks and not blockers:
            logger.debug(f"[BLOCKER_DEBUG] No data in separate columns, checking risks_and_blockers")
            risks_and_blockers = summary_data.get('risks_and_blockers', {})
            if isinstance(risks_and_blockers, dict):
                risks = risks_and_blockers.get('risks', [])
                blockers = risks_and_blockers.get('blockers', [])
                logger.debug(f"[BLOCKER_DEBUG] Extracted from risks_and_blockers - risks: {len(risks)}, blockers: {len(blockers)}")

        # Extract tasks from action_items
        tasks = summary_data.get('action_items', [])

        # Extract lessons learned
        lessons = summary_data.get('lessons_learned', [])

        logger.info(
            f"Extracted from summary: {len(risks)} risks, {len(blockers)} blockers, "
            f"{len(tasks)} tasks, {len(lessons)} lessons"
        )

        logger.debug(f"[BLOCKER_DEBUG] Final blockers list: {blockers}")

        return {
            'risks': risks,
            'blockers': blockers,
            'tasks': tasks,
            'lessons': lessons
        }

    async def _get_existing_project_items(
        self,
        session: AsyncSession,
        project_id: uuid.UUID
    ) -> Dict[str, List]:
        """
        Get existing project items from database.

        Args:
            session: Database session
            project_id: Project ID

        Returns:
            Dict with existing risks, blockers, tasks, and lessons
        """
        # Get existing risks
        risks_result = await session.execute(
            select(Risk).where(Risk.project_id == project_id)
        )
        existing_risks = [risk.to_dict() for risk in risks_result.scalars().all()]

        # Get existing blockers
        blockers_result = await session.execute(
            select(Blocker).where(Blocker.project_id == project_id)
        )
        existing_blockers = [blocker.to_dict() for blocker in blockers_result.scalars().all()]

        # Get existing tasks
        tasks_result = await session.execute(
            select(Task).where(Task.project_id == project_id)
        )
        existing_tasks = [task.to_dict() for task in tasks_result.scalars().all()]

        # Get existing lessons
        lessons_result = await session.execute(
            select(LessonLearned).where(LessonLearned.project_id == project_id)
        )
        existing_lessons = [lesson.to_dict() for lesson in lessons_result.scalars().all()]

        logger.debug(
            f"Found existing items: {len(existing_risks)} risks, {len(existing_blockers)} blockers, "
            f"{len(existing_tasks)} tasks, {len(existing_lessons)} lessons"
        )

        return {
            'risks': existing_risks,
            'blockers': existing_blockers,
            'tasks': existing_tasks,
            'lessons': existing_lessons
        }

    async def _process_status_updates(
        self,
        session: AsyncSession,
        project_id: uuid.UUID,
        content_id: uuid.UUID,
        status_updates: List[Dict[str, Any]],
        extracted_items: Dict[str, List],
        existing_items: Dict[str, List]
    ) -> None:
        """
        Process status updates to update existing items with new information.

        Status updates contain information about existing items that have
        new status, progress, or other updates from the latest meeting.

        Args:
            session: Database session
            project_id: Project ID
            content_id: Content ID
            status_updates: List of status update objects from deduplication
            extracted_items: Items extracted from the current meeting
            existing_items: Existing items from the database
        """
        from models.risk import Risk
        from models.blocker import Blocker
        from models.task import Task
        from models.lesson_learned import LessonLearned

        for update in status_updates:
            try:
                # Handle multiple formats:
                # 1. Semantic dedup format: {"type": "risk", "existing_item_id": UUID, "existing_title": "...", "update_type": "status", "new_info": {...}}
                # 2. Legacy AI format: {"type": "risk", "extracted_number": 2, "existing_title": "...", "new_status": null}
                # 3. Expected format: {"item_type": "risk", "existing_item_number": 2, "update_type": "status", "new_info": "..."}

                # Get item type (handle both 'type' and 'item_type' keys)
                item_type = (update.get('item_type') or update.get('type', '')).lower()

                # Get existing item identifier - prefer UUID if available
                existing_item_id = update.get('existing_item_id')  # UUID from semantic dedup
                existing_title = update.get('existing_title', '')

                # Get index (handle legacy formats)
                existing_item_index = -1
                if 'existing_item_number' in update:
                    existing_item_index = update.get('existing_item_number', -1) - 1  # Expected format

                # Get update type and info
                update_type = update.get('update_type', 'status')  # Default to status
                new_info = update.get('new_info') or update.get('new_status', '')
                new_info_dict = update.get('new_info_dict', {})  # Full dict with all updates

                logger.debug(f"Processing status update: type={item_type}, update={update_type}, id={existing_item_id}, title={existing_title}")

                # Skip if no new information (this is normal for pure duplicates)
                if not new_info and not new_info_dict and update.get('new_status') is None:
                    logger.debug(f"Skipping status update with no actual status change (duplicate item): {update}")
                    continue

                if not existing_item_id and existing_item_index < 0 and not existing_title:
                    logger.warning(f"Cannot identify existing item for status update (no ID, index, or title): {update}")
                    continue

                # Get the corresponding existing item data and model
                if item_type == 'risk':
                    # Try UUID lookup first (from semantic dedup)
                    if existing_item_id:
                        existing_obj = await session.get(Risk, existing_item_id)
                        if not existing_obj:
                            logger.warning(f"Could not find risk with ID {existing_item_id}")
                            continue
                    # Fall back to index-based lookup (legacy)
                    elif existing_item_index >= 0 and existing_item_index < len(existing_items.get('risks', [])):
                        existing_item_data = existing_items['risks'][existing_item_index]

                        # Validate that the indexed item matches the expected title
                        if existing_title and existing_item_data.get('title') != existing_title:
                            logger.warning(
                                f"Index mismatch for risk update: index {existing_item_index} points to "
                                f"'{existing_item_data.get('title')}' but expected '{existing_title}'. "
                                f"Searching by title instead."
                            )
                            # Try to find by title instead
                            existing_item_data = next(
                                (item for item in existing_items['risks'] if item.get('title') == existing_title),
                                None
                            )
                            if not existing_item_data:
                                logger.warning(f"Could not find risk with title '{existing_title}' for update")
                                continue

                        item_id = existing_item_data.get('id')
                        if not item_id:
                            logger.warning(f"No ID found for risk update: {update}")
                            continue

                        # Fetch the actual database object
                        existing_obj = await session.get(Risk, item_id)
                    else:
                        logger.warning(f"Could not locate risk for update: {update}")
                        continue
                    if existing_obj:
                        # Build update_data dict (same pattern as manual updates)
                        update_data = {}
                        author_name = "AI Assistant"

                        if update_type == 'status' and new_info:
                            # Handle both enum and string values
                            if isinstance(new_info, str):
                                update_data['status'] = new_info
                            else:
                                update_data['status'] = new_info.value if hasattr(new_info, 'value') else str(new_info)

                            # Set resolved_date when risk is resolved (auto-closure)
                            if update_data['status'] == 'resolved' and not existing_obj.resolved_date:
                                update_data['resolved_date'] = datetime.utcnow()
                                logger.info(f"Risk '{existing_obj.title}' automatically closed - resolved_date set")
                        elif update_type == 'mitigation':
                            if new_info:
                                update_data['mitigation'] = new_info
                        elif update_type == 'severity' and new_info:
                            # Handle both enum and string values
                            if isinstance(new_info, str):
                                update_data['severity'] = new_info
                            else:
                                update_data['severity'] = new_info.value if hasattr(new_info, 'value') else str(new_info)
                        elif update_type == 'resolution':
                            if new_info:
                                update_data['mitigation'] = new_info
                            update_data['status'] = 'resolved'
                            # Set resolved_date when resolution is provided (auto-closure)
                            if not existing_obj.resolved_date:
                                update_data['resolved_date'] = datetime.utcnow()
                                logger.info(f"Risk '{existing_obj.title}' automatically closed - resolved_date set")

                        # Skip if no actual changes (e.g. AI detected duplicate with same status)
                        if not update_data:
                            logger.debug(f"Skipping risk update - no actual changes detected for '{existing_obj.title}'")
                            continue

                        # Track changes using ItemUpdatesService (same as manual updates)
                        if 'status' in update_data and update_data['status'] != existing_obj.status:
                            await ItemUpdatesService.track_status_change(
                                db=session,
                                project_id=project_id,
                                item_id=existing_obj.id,
                                item_type='risks',
                                old_status=existing_obj.status,
                                new_status=update_data['status'],
                                author_name=author_name,
                                author_email=None
                            )

                        if 'assigned_to' in update_data and update_data['assigned_to'] != existing_obj.assigned_to:
                            await ItemUpdatesService.track_assignment(
                                db=session,
                                project_id=project_id,
                                item_id=existing_obj.id,
                                item_type='risks',
                                old_assignee=existing_obj.assigned_to,
                                new_assignee=update_data['assigned_to'],
                                author_name=author_name,
                                author_email=None
                            )

                        # Detect and track other field changes
                        changes = ItemUpdatesService.detect_changes(existing_obj, update_data)
                        if changes:
                            await ItemUpdatesService.track_field_changes(
                                db=session,
                                project_id=project_id,
                                item_id=existing_obj.id,
                                item_type='risks',
                                changes=changes,
                                author_name=author_name,
                                author_email=None
                            )

                        # Apply updates to object
                        for key, value in update_data.items():
                            if hasattr(existing_obj, key):
                                setattr(existing_obj, key, value)

                        if content_id:
                            existing_obj.source_content_id = str(content_id)
                        existing_obj.last_updated = datetime.utcnow()
                        existing_obj.updated_by = "ai"
                        logger.info(f"Updated risk '{existing_obj.title}' with {list(update_data.keys())}")

                elif item_type == 'blocker':
                    # Try UUID lookup first (from semantic dedup)
                    if existing_item_id:
                        existing_obj = await session.get(Blocker, existing_item_id)
                        if not existing_obj:
                            logger.warning(f"Could not find blocker with ID {existing_item_id}")
                            continue
                    # Fall back to index-based lookup (legacy)
                    elif existing_item_index >= 0 and existing_item_index < len(existing_items.get('blockers', [])):
                        existing_item_data = existing_items['blockers'][existing_item_index]

                        # Validate that the indexed item matches the expected title
                        if existing_title and existing_item_data.get('title') != existing_title:
                            logger.warning(
                                f"Index mismatch for blocker update: index {existing_item_index} points to "
                                f"'{existing_item_data.get('title')}' but expected '{existing_title}'. "
                                f"Searching by title instead."
                            )
                            # Try to find by title instead
                            existing_item_data = next(
                                (item for item in existing_items['blockers'] if item.get('title') == existing_title),
                                None
                            )
                            if not existing_item_data:
                                logger.warning(f"Could not find blocker with title '{existing_title}' for update")
                                continue

                        item_id = existing_item_data.get('id')
                        if not item_id:
                            logger.warning(f"No ID found for blocker update: {update}")
                            continue

                        existing_obj = await session.get(Blocker, item_id)
                    else:
                        logger.warning(f"Could not locate blocker for update: {update}")
                        continue
                    if existing_obj:
                        # Build update_data dict (same pattern as manual updates)
                        update_data = {}
                        author_name = "AI Assistant"

                        if update_type == 'status' and new_info:
                            # Handle both enum and string values
                            if isinstance(new_info, str):
                                update_data['status'] = new_info
                            else:
                                update_data['status'] = new_info.value if hasattr(new_info, 'value') else str(new_info)

                            # Set resolved_date when blocker is resolved (auto-closure)
                            if update_data['status'] == 'resolved' and not existing_obj.resolved_date:
                                update_data['resolved_date'] = datetime.utcnow()
                                logger.info(f"Blocker '{existing_obj.title}' automatically closed - resolved_date set")
                        elif update_type == 'resolution':
                            if new_info:
                                update_data['resolution'] = new_info
                                # If resolution provided, mark as resolved
                                update_data['status'] = 'resolved'
                                # Set resolved_date when resolution is provided (auto-closure)
                                if not existing_obj.resolved_date:
                                    update_data['resolved_date'] = datetime.utcnow()
                                    logger.info(f"Blocker '{existing_obj.title}' automatically closed - resolved_date set")
                        elif update_type == 'impact' and new_info:
                            # Handle both enum and string values
                            if isinstance(new_info, str):
                                update_data['impact'] = new_info
                            else:
                                update_data['impact'] = new_info.value if hasattr(new_info, 'value') else str(new_info)

                        # Skip if no actual changes (e.g. AI detected duplicate with same status)
                        if not update_data:
                            logger.debug(f"Skipping blocker update - no actual changes detected for '{existing_obj.title}'")
                            continue

                        # Track changes using ItemUpdatesService (same as manual updates)
                        if 'status' in update_data and update_data['status'] != existing_obj.status:
                            await ItemUpdatesService.track_status_change(
                                db=session,
                                project_id=project_id,
                                item_id=existing_obj.id,
                                item_type='blockers',
                                old_status=existing_obj.status,
                                new_status=update_data['status'],
                                author_name=author_name,
                                author_email=None
                            )

                        # Track assignment changes (blockers can have assigned_to or owner)
                        if 'assigned_to' in update_data and update_data['assigned_to'] != existing_obj.assigned_to:
                            await ItemUpdatesService.track_assignment(
                                db=session,
                                project_id=project_id,
                                item_id=existing_obj.id,
                                item_type='blockers',
                                old_assignee=existing_obj.assigned_to,
                                new_assignee=update_data['assigned_to'],
                                author_name=author_name,
                                author_email=None
                            )
                        elif 'owner' in update_data and update_data['owner'] != existing_obj.owner:
                            await ItemUpdatesService.track_assignment(
                                db=session,
                                project_id=project_id,
                                item_id=existing_obj.id,
                                item_type='blockers',
                                old_assignee=existing_obj.owner,
                                new_assignee=update_data['owner'],
                                author_name=author_name,
                                author_email=None
                            )

                        # Detect and track other field changes
                        changes = ItemUpdatesService.detect_changes(existing_obj, update_data)
                        if changes:
                            await ItemUpdatesService.track_field_changes(
                                db=session,
                                project_id=project_id,
                                item_id=existing_obj.id,
                                item_type='blockers',
                                changes=changes,
                                author_name=author_name,
                                author_email=None
                            )

                        # Apply updates to object
                        for key, value in update_data.items():
                            if hasattr(existing_obj, key):
                                setattr(existing_obj, key, value)

                        if content_id:
                            existing_obj.source_content_id = str(content_id)
                        existing_obj.last_updated = datetime.utcnow()
                        existing_obj.updated_by = "ai"
                        logger.info(f"Updated blocker '{existing_obj.title}' with {list(update_data.keys())}")

                elif item_type == 'task':
                    # Try UUID lookup first (from semantic dedup)
                    if existing_item_id:
                        existing_obj = await session.get(Task, existing_item_id)
                        if not existing_obj:
                            logger.warning(f"Could not find task with ID {existing_item_id}")
                            continue
                    # Fall back to index-based lookup (legacy)
                    elif existing_item_index >= 0 and existing_item_index < len(existing_items.get('tasks', [])):
                        existing_item_data = existing_items['tasks'][existing_item_index]

                        # Validate that the indexed item matches the expected title
                        if existing_title and existing_item_data.get('title') != existing_title:
                            logger.warning(
                                f"Index mismatch for task update: index {existing_item_index} points to "
                                f"'{existing_item_data.get('title')}' but expected '{existing_title}'. "
                                f"Searching by title instead."
                            )
                            # Try to find by title instead
                            existing_item_data = next(
                                (item for item in existing_items['tasks'] if item.get('title') == existing_title),
                                None
                            )
                            if not existing_item_data:
                                logger.warning(f"Could not find task with title '{existing_title}' for update")
                                continue

                        item_id = existing_item_data.get('id')
                        if not item_id:
                            logger.warning(f"No ID found for task update: {update}")
                            continue

                        existing_obj = await session.get(Task, item_id)
                    else:
                        logger.warning(f"Could not locate task for update: {update}")
                        continue
                    if existing_obj:
                        # Build update_data dict (same pattern as manual updates)
                        update_data = {}
                        author_name = "AI Assistant"

                        if update_type == 'status' and new_info:
                            # Map invalid task statuses to valid ones
                            task_status_mapping = {
                                'not_started': 'todo',
                                'pending': 'todo',
                                'done': 'completed',
                                'finished': 'completed',
                                'in progress': 'in_progress',
                                'working': 'in_progress'
                            }

                            # Normalize and validate status
                            status_value = new_info.lower() if isinstance(new_info, str) else str(new_info).lower()
                            status_value = task_status_mapping.get(status_value, status_value)

                            # Validate against allowed values
                            valid_task_statuses = ['todo', 'in_progress', 'blocked', 'completed', 'cancelled']
                            if status_value not in valid_task_statuses:
                                logger.warning(f"Invalid task status '{status_value}' (original: '{new_info}'), defaulting to 'todo'")
                                status_value = 'todo'

                            update_data['status'] = status_value

                            # Set completed_date when task is completed (auto-closure)
                            if status_value == 'completed' and not existing_obj.completed_date:
                                update_data['completed_date'] = datetime.utcnow()
                                logger.info(f"Task '{existing_obj.title}' automatically closed - completed_date set")
                        elif update_type == 'progress':
                            # Extract progress percentage if mentioned
                            try:
                                import re
                                progress_match = re.search(r'(\d+)%', new_info)
                                if progress_match:
                                    update_data['progress_percentage'] = int(progress_match.group(1))
                            except:
                                pass
                            # Also update status based on progress description
                            if 'complete' in new_info.lower():
                                update_data['status'] = 'completed'
                                update_data['completed_date'] = datetime.utcnow()
                            elif 'in progress' in new_info.lower() or 'started' in new_info.lower():
                                update_data['status'] = 'in_progress'
                        elif update_type == 'assignee':
                            if new_info:
                                update_data['assignee'] = new_info
                        elif update_type == 'blocker':
                            update_data['blocker_description'] = new_info
                            update_data['status'] = 'blocked'

                        # Handle multi-field updates from new_info_dict
                        if new_info_dict and isinstance(new_info_dict, dict):
                            if 'due_date' in new_info_dict and new_info_dict['due_date']:
                                try:
                                    due_date_val = new_info_dict['due_date']
                                    if isinstance(due_date_val, str):
                                        due_date_val = datetime.fromisoformat(due_date_val.replace('Z', '+00:00')).replace(tzinfo=None)
                                    update_data['due_date'] = due_date_val
                                except Exception as e:
                                    logger.warning(f"Could not parse due_date '{new_info_dict['due_date']}': {e}")

                        # Skip if no actual changes (e.g. AI detected duplicate with same status)
                        if not update_data:
                            logger.debug(f"Skipping task update - no actual changes detected for '{existing_obj.title}'")
                            continue

                        # Track changes using ItemUpdatesService (same as manual updates)
                        if 'status' in update_data and update_data['status'] != existing_obj.status:
                            await ItemUpdatesService.track_status_change(
                                db=session,
                                project_id=project_id,
                                item_id=existing_obj.id,
                                item_type='tasks',
                                old_status=existing_obj.status,
                                new_status=update_data['status'],
                                author_name=author_name,
                                author_email=None
                            )

                        if 'assignee' in update_data and update_data['assignee'] != existing_obj.assignee:
                            await ItemUpdatesService.track_assignment(
                                db=session,
                                project_id=project_id,
                                item_id=existing_obj.id,
                                item_type='tasks',
                                old_assignee=existing_obj.assignee,
                                new_assignee=update_data['assignee'],
                                author_name=author_name,
                                author_email=None
                            )

                        # Detect and track other field changes
                        changes = ItemUpdatesService.detect_changes(existing_obj, update_data)
                        if changes:
                            await ItemUpdatesService.track_field_changes(
                                db=session,
                                project_id=project_id,
                                item_id=existing_obj.id,
                                item_type='tasks',
                                changes=changes,
                                author_name=author_name,
                                author_email=None
                            )

                        # Apply updates to object
                        for key, value in update_data.items():
                            if hasattr(existing_obj, key):
                                setattr(existing_obj, key, value)

                        if content_id:
                            existing_obj.source_content_id = str(content_id)
                        existing_obj.last_updated = datetime.utcnow()
                        existing_obj.updated_by = "ai"
                        logger.info(f"Updated task '{existing_obj.title}' with {list(update_data.keys())}")

                elif item_type == 'lesson':
                    # Try UUID lookup first (from semantic dedup)
                    if existing_item_id:
                        existing_obj = await session.get(LessonLearned, existing_item_id)
                        if not existing_obj:
                            logger.warning(f"Could not find lesson with ID {existing_item_id}")
                            continue
                    # Fall back to index-based lookup (legacy)
                    elif existing_item_index >= 0 and existing_item_index < len(existing_items.get('lessons', [])):
                        existing_item_data = existing_items['lessons'][existing_item_index]

                        # Validate that the indexed item matches the expected title
                        if existing_title and existing_item_data.get('title') != existing_title:
                            logger.warning(
                                f"Index mismatch for lesson update: index {existing_item_index} points to "
                                f"'{existing_item_data.get('title')}' but expected '{existing_title}'. "
                                f"Searching by title instead."
                            )
                            # Try to find by title instead
                            existing_item_data = next(
                                (item for item in existing_items['lessons'] if item.get('title') == existing_title),
                                None
                            )
                            if not existing_item_data:
                                logger.warning(f"Could not find lesson with title '{existing_title}' for update")
                                continue

                        item_id = existing_item_data.get('id')
                        if not item_id:
                            logger.warning(f"No ID found for lesson update: {update}")
                            continue

                        existing_obj = await session.get(LessonLearned, item_id)
                    else:
                        logger.warning(f"Could not locate lesson for update: {update}")
                        continue
                    if existing_obj:
                        # Build update_data dict (same pattern as manual updates)
                        update_data = {}
                        author_name = "AI Assistant"

                        if update_type == 'recommendation':
                            if new_info:
                                update_data['recommendation'] = new_info
                        elif update_type == 'impact':
                            if new_info:
                                update_data['impact'] = new_info
                        elif update_type == 'context':
                            # Append new context to existing
                            if new_info:
                                update_data['context'] = f"{existing_obj.context}\n\nUpdate: {new_info}" if existing_obj.context else new_info

                        # Skip if no actual changes (e.g. AI detected duplicate with no new info)
                        if not update_data:
                            logger.debug(f"Skipping lesson update - no actual changes detected for '{existing_obj.title}'")
                            continue

                        # Track changes using ItemUpdatesService (same as manual updates)
                        # Note: Lessons don't have status or assignment, just field changes
                        changes = ItemUpdatesService.detect_changes(existing_obj, update_data)
                        if changes:
                            await ItemUpdatesService.track_field_changes(
                                db=session,
                                project_id=project_id,
                                item_id=existing_obj.id,
                                item_type='lessons',
                                changes=changes,
                                author_name=author_name,
                                author_email=None
                            )

                        # Apply updates to object
                        for key, value in update_data.items():
                            if hasattr(existing_obj, key):
                                setattr(existing_obj, key, value)

                        existing_obj.source_content_id = str(content_id)
                        existing_obj.last_updated = datetime.utcnow()
                        existing_obj.updated_by = "ai"
                        logger.info(f"Updated lesson '{existing_obj.title}' with {list(update_data.keys())}")

                else:
                    logger.warning(
                        f"Could not find existing item for update: "
                        f"type={item_type}, id={existing_item_id}, index={existing_item_index}, title={existing_title}"
                    )

            except Exception as e:
                logger.error(f"Error processing status update {update}: {e}")
                # Continue processing other updates even if one fails
                continue

    async def _update_project_risks(
        self,
        session: AsyncSession,
        project_id: uuid.UUID,
        content_id: uuid.UUID,
        new_risks: List[Dict[str, Any]],
        existing_risks: List[Dict[str, Any]]
    ) -> None:
        """Update project risks in database."""
        # Valid risk statuses from the RiskStatus enum
        valid_risk_statuses = ['identified', 'mitigating', 'resolved', 'accepted', 'escalated']

        # Mapping for common incorrect statuses to valid ones
        status_mapping = {
            'active': 'identified',  # 'active' is for blockers, not risks
            'pending': 'identified',
            'in_progress': 'mitigating',
            'closed': 'resolved',
            'done': 'resolved'
        }

        for risk_data in new_risks:
            try:
                # Validate and map risk status
                risk_status = risk_data.get('status', 'identified')
                if isinstance(risk_status, str):
                    risk_status = risk_status.lower()
                    # Map invalid status to valid one
                    if risk_status not in valid_risk_statuses:
                        original_status = risk_status
                        risk_status = status_mapping.get(risk_status, 'identified')
                        logger.warning(f"Invalid risk status '{original_status}' mapped to '{risk_status}'")

                # Check if risk already exists by title (shouldn't happen after dedup, but safety check)
                query = select(Risk).where(
                    Risk.project_id == project_id,
                    Risk.title == risk_data.get('title')
                )
                result = await session.execute(query)
                existing_risk = result.scalar_one_or_none()

                if existing_risk:
                    # Update existing risk
                    existing_risk.description = risk_data.get('description', existing_risk.description)
                    existing_risk.severity = risk_data.get('severity', 'medium')
                    existing_risk.status = risk_status
                    existing_risk.mitigation = risk_data.get('mitigation', existing_risk.mitigation)
                    existing_risk.impact = risk_data.get('impact', existing_risk.impact)
                    existing_risk.ai_confidence = risk_data.get('confidence', 0.8)
                    existing_risk.source_content_id = str(content_id)
                    existing_risk.last_updated = datetime.utcnow()
                    existing_risk.updated_by = "ai"
                else:
                    # Create new risk
                    new_risk = Risk(
                        project_id=project_id,
                        title=risk_data.get('title'),
                        description=risk_data.get('description'),
                        severity=risk_data.get('severity', 'medium'),
                        status=risk_status,
                        mitigation=risk_data.get('mitigation'),
                        impact=risk_data.get('impact'),
                        ai_generated="true",
                        ai_confidence=risk_data.get('confidence', 0.8),
                        source_content_id=str(content_id),
                        updated_by="ai",
                        title_embedding=risk_data.get('title_embedding')  # Store embedding
                    )
                    session.add(new_risk)

            except Exception as e:
                logger.error(f"Error updating risk '{risk_data.get('title')}': {e}")

    async def _update_project_blockers(
        self,
        session: AsyncSession,
        project_id: uuid.UUID,
        content_id: uuid.UUID,
        new_blockers: List[Dict[str, Any]],
        existing_blockers: List[Dict[str, Any]]
    ) -> None:
        """Update project blockers in database."""
        logger.debug(f"[BLOCKER_DEBUG] _update_project_blockers called with {len(new_blockers)} new blockers")
        logger.debug(f"[BLOCKER_DEBUG] Project ID: {project_id}, Content ID: {content_id}")

        for blocker_data in new_blockers:
            try:
                logger.debug(f"[BLOCKER_DEBUG] Processing blocker: {blocker_data.get('title')}")
                logger.debug(f"[BLOCKER_DEBUG] Blocker data: {blocker_data}")

                # Parse target_date if it's a string
                target_date = blocker_data.get('target_date')
                if target_date and isinstance(target_date, str):
                    try:
                        # Parse ISO date string to datetime
                        target_date = datetime.fromisoformat(target_date.replace('Z', '+00:00'))
                    except (ValueError, AttributeError):
                        logger.warning(f"Invalid date format for blocker target_date: {target_date}")
                        target_date = None

                # Check if blocker already exists by title
                query = select(Blocker).where(
                    Blocker.project_id == project_id,
                    Blocker.title == blocker_data.get('title')
                )
                result = await session.execute(query)
                existing_blocker = result.scalar_one_or_none()

                logger.debug(f"[BLOCKER_DEBUG] Existing blocker found: {existing_blocker is not None}")

                if existing_blocker:
                    # Update existing blocker
                    existing_blocker.description = blocker_data.get('description', existing_blocker.description)
                    existing_blocker.impact = blocker_data.get('impact', 'high')
                    existing_blocker.status = blocker_data.get('status', 'active')
                    existing_blocker.resolution = blocker_data.get('resolution', existing_blocker.resolution)
                    existing_blocker.category = blocker_data.get('category', existing_blocker.category)
                    existing_blocker.owner = blocker_data.get('owner', existing_blocker.owner)
                    existing_blocker.dependencies = blocker_data.get('dependencies', existing_blocker.dependencies)
                    existing_blocker.target_date = target_date or existing_blocker.target_date
                    existing_blocker.ai_confidence = blocker_data.get('confidence', 0.8)
                    existing_blocker.source_content_id = str(content_id)
                    existing_blocker.last_updated = datetime.utcnow()
                    existing_blocker.updated_by = "ai"
                else:
                    # Create new blocker
                    logger.debug(f"[BLOCKER_DEBUG] Creating new blocker with title: {blocker_data.get('title')}")

                    new_blocker = Blocker(
                        project_id=project_id,
                        title=blocker_data.get('title'),
                        description=blocker_data.get('description'),
                        impact=blocker_data.get('impact', 'high'),
                        status=blocker_data.get('status', 'active'),
                        resolution=blocker_data.get('resolution'),
                        category=blocker_data.get('category', 'general'),
                        owner=blocker_data.get('owner'),
                        dependencies=str(blocker_data.get('dependencies')) if blocker_data.get('dependencies') else None,
                        target_date=target_date,
                        ai_generated="true",
                        ai_confidence=blocker_data.get('confidence', 0.8),
                        source_content_id=str(content_id),
                        updated_by="ai",
                        title_embedding=blocker_data.get('title_embedding')  # Store embedding
                    )
                    session.add(new_blocker)
                    logger.debug(f"[BLOCKER_DEBUG] Added new blocker to session: {new_blocker.title}")

                    # Flush to get the ID and verify it's persisted
                    await session.flush()
                    logger.debug(f"[BLOCKER_DEBUG] Flushed blocker to DB with ID: {new_blocker.id}")

            except Exception as e:
                logger.error(f"[BLOCKER_DEBUG] Error updating blocker '{blocker_data.get('title')}': {e}")
                logger.exception(f"[BLOCKER_DEBUG] Full exception details:")

    async def _update_project_tasks(
        self,
        session: AsyncSession,
        project_id: uuid.UUID,
        content_id: uuid.UUID,
        new_tasks: List[Dict[str, Any]],
        existing_tasks: List[Dict[str, Any]]
    ) -> None:
        """Update project tasks in database."""
        from utils.text_similarity import are_tasks_similar

        for task_data in new_tasks:
            try:
                # Use title if available, otherwise use description
                task_title = task_data.get('title') or task_data.get('description', '')

                # Parse due_date if it's a string
                due_date = task_data.get('due_date')
                if due_date and isinstance(due_date, str):
                    try:
                        # Parse ISO date string to datetime and convert to UTC naive
                        due_date = datetime.fromisoformat(due_date.replace('Z', '+00:00'))
                        # Convert to naive UTC datetime for database storage
                        due_date = due_date.replace(tzinfo=None)
                    except (ValueError, AttributeError):
                        logger.warning(f"Invalid date format for task due_date: {due_date}")
                        due_date = None

                # Check if task already exists - first by exact match
                query = select(Task).where(
                    Task.project_id == project_id,
                    Task.title == task_title
                )
                result = await session.execute(query)
                existing_task = result.scalar_one_or_none()

                # If no exact match, check for similar tasks using fuzzy matching
                if not existing_task:
                    all_tasks_query = select(Task).where(Task.project_id == project_id)
                    all_tasks_result = await session.execute(all_tasks_query)
                    all_project_tasks = all_tasks_result.scalars().all()

                    for task in all_project_tasks:
                        if are_tasks_similar(task_title, task.title, threshold=0.75):
                            existing_task = task
                            logger.info(f"Found similar task via fuzzy matching: '{task_title}' matches '{task.title}'")
                            break

                # Normalize task status (for both update and creation)
                task_status_mapping = {
                    'not_started': 'todo',
                    'pending': 'todo',
                    'done': 'completed',
                    'finished': 'completed',
                    'in progress': 'in_progress',
                    'working': 'in_progress'
                }

                # Get and validate status
                raw_status = task_data.get('status', 'todo')
                if isinstance(raw_status, str):
                    raw_status = raw_status.lower()
                    raw_status = task_status_mapping.get(raw_status, raw_status)

                # Validate against allowed values
                valid_task_statuses = ['todo', 'in_progress', 'blocked', 'completed', 'cancelled']
                if raw_status not in valid_task_statuses:
                    logger.warning(f"Invalid task status '{raw_status}' from AI, defaulting to 'todo'")
                    raw_status = 'todo'

                if existing_task:
                    # Update existing task
                    existing_task.description = task_data.get('description', existing_task.description)
                    existing_task.priority = task_data.get('priority', task_data.get('urgency', 'medium'))
                    existing_task.assignee = task_data.get('assignee', existing_task.assignee)
                    existing_task.due_date = due_date or existing_task.due_date
                    existing_task.question_to_ask = task_data.get('question_to_ask', existing_task.question_to_ask)
                    existing_task.ai_confidence = task_data.get('confidence', 0.8)
                    existing_task.source_content_id = str(content_id)
                    existing_task.last_updated = datetime.utcnow()
                    existing_task.updated_by = "ai"
                else:
                    # Create new task
                    new_task = Task(
                        project_id=project_id,
                        title=task_title,
                        description=task_data.get('description'),
                        status=raw_status,  # Use validated status
                        priority=task_data.get('priority', task_data.get('urgency', 'medium')),
                        assignee=task_data.get('assignee'),
                        due_date=due_date,
                        question_to_ask=task_data.get('question_to_ask'),
                        ai_generated="true",
                        ai_confidence=task_data.get('confidence', 0.8),
                        source_content_id=str(content_id),
                        updated_by="ai",  # Use updated_by instead of created_by
                        title_embedding=task_data.get('title_embedding')  # Store embedding
                    )
                    session.add(new_task)

            except Exception as e:
                logger.error(f"Error updating task '{task_title}': {e}")

    async def _update_project_lessons(
        self,
        session: AsyncSession,
        project_id: uuid.UUID,
        content_id: uuid.UUID,
        new_lessons: List[Dict[str, Any]],
        existing_lessons: List[Dict[str, Any]]
    ) -> None:
        """Update project lessons learned in database."""

        # Map LLM categories to valid enum values
        category_mapping = {
            'compliance': 'process',  # Map compliance to process
            'legal': 'process',       # Map legal to process
            'governance': 'process',  # Map governance to process
            'technical': 'technical',
            'process': 'process',
            'communication': 'communication',
            'planning': 'planning',
            'resource': 'resource',
            'quality': 'quality',
            'other': 'other'
        }

        # Valid lesson types
        valid_lesson_types = ['success', 'improvement', 'challenge', 'best_practice']

        # Valid impact values
        valid_impacts = ['low', 'medium', 'high']

        for lesson_data in new_lessons:
            try:
                # Map category to valid enum value
                raw_category = lesson_data.get('category', 'other').lower()
                mapped_category = category_mapping.get(raw_category, 'other')

                # Validate lesson_type
                raw_lesson_type = lesson_data.get('lesson_type', 'improvement').lower().replace(' ', '_')
                if raw_lesson_type not in valid_lesson_types:
                    raw_lesson_type = 'improvement'

                # Validate impact
                raw_impact = lesson_data.get('impact', 'medium').lower()
                if raw_impact not in valid_impacts:
                    raw_impact = 'medium'

                # Check if lesson already exists
                query = select(LessonLearned).where(
                    LessonLearned.project_id == project_id,
                    LessonLearned.title == lesson_data.get('title')
                )
                result = await session.execute(query)
                existing_lesson = result.scalar_one_or_none()

                if existing_lesson:
                    # Update existing lesson
                    existing_lesson.description = lesson_data.get('description', existing_lesson.description)
                    existing_lesson.category = mapped_category
                    existing_lesson.lesson_type = raw_lesson_type
                    existing_lesson.impact = raw_impact
                    existing_lesson.recommendation = lesson_data.get('recommendation', existing_lesson.recommendation)
                    existing_lesson.context = lesson_data.get('context', existing_lesson.context)
                    existing_lesson.ai_confidence = lesson_data.get('confidence', 0.8)
                    existing_lesson.source_content_id = str(content_id)
                    existing_lesson.last_updated = datetime.utcnow()
                    existing_lesson.updated_by = "ai"
                else:
                    # Create new lesson
                    new_lesson = LessonLearned(
                        project_id=project_id,
                        title=lesson_data.get('title'),
                        description=lesson_data.get('description'),
                        category=mapped_category,
                        lesson_type=raw_lesson_type,
                        impact=raw_impact,
                        recommendation=lesson_data.get('recommendation'),
                        context=lesson_data.get('context'),
                        ai_generated="true",
                        ai_confidence=lesson_data.get('confidence', 0.8),
                        source_content_id=str(content_id),
                        updated_by="ai",  # Use updated_by instead of created_by
                        title_embedding=lesson_data.get('title_embedding')  # Store embedding
                    )
                    session.add(new_lesson)

            except Exception as e:
                logger.error(f"Error updating lesson '{lesson_data.get('title')}': {e}")


    async def _semantic_deduplicate_items(
        self,
        extracted_items: Dict[str, List],
        existing_items: Dict[str, List]
    ) -> Dict[str, Any]:
        """
        Perform semantic deduplication using embeddings + AI.

        Returns deduplicated items in the same format as the legacy AI-only deduplication.
        """
        result = {
            'risks': [],
            'blockers': [],
            'tasks': [],
            'lessons_learned': [],
            'status_updates': []
        }

        # Process each item type
        item_types = [
            ('risks', 'risk'),
            ('blockers', 'blocker'),
            ('tasks', 'task'),
            ('lessons', 'lesson')
        ]

        for items_key, item_type in item_types:
            new_items = extracted_items.get(items_key, [])
            existing = existing_items.get(items_key, [])

            if not new_items:
                continue

            # Run semantic deduplication
            dedup_result = await self.semantic_deduplicator.deduplicate_items(
                item_type=item_type,
                new_items=new_items,
                existing_items=existing
            )

            # Add unique items to result
            result_key = items_key if items_key != 'lessons' else 'lessons_learned'
            result[result_key] = dedup_result['unique_items']

            # Process updates as status_updates for compatibility with existing code
            if self.settings.enable_intelligent_updates:
                for update_info in dedup_result['updates']:
                    # Extract new_info dict - it contains the actual field updates
                    new_info_dict = update_info.get('new_info', {})

                    # Convert new_info dict to a simple value for the status update
                    # Priority: look for common update fields
                    new_info_value = None
                    if update_info.get('update_type') == 'status' and 'status' in new_info_dict:
                        new_info_value = new_info_dict['status']
                    elif 'description' in new_info_dict:
                        new_info_value = new_info_dict['description']
                    elif new_info_dict:
                        # Take the first value from the dict
                        new_info_value = next(iter(new_info_dict.values()))

                    status_update = {
                        'type': item_type,
                        'existing_item_id': update_info['existing_item_id'],  # UUID for direct lookup
                        'existing_title': update_info['existing_item_title'],
                        'update_type': update_info.get('update_type', 'content'),
                        'new_info': new_info_value or new_info_dict,  # Use simple value or full dict
                        'new_info_dict': new_info_dict,  # Preserve full dict
                        'confidence': update_info.get('confidence', 0.8)
                    }
                    result['status_updates'].append(status_update)

            logger.info(
                f"Semantic dedup for {item_type}: "
                f"{len(dedup_result['unique_items'])} unique, "
                f"{len(dedup_result['updates'])} updates, "
                f"{len(dedup_result['exact_duplicates'])} skipped"
            )

        return result

    async def _apply_intelligent_update(
        self,
        session: AsyncSession,
        project_id: uuid.UUID,
        content_id: uuid.UUID,
        item_type: str,
        update_info: Dict[str, Any]
    ) -> None:
        """
        Apply intelligent update to an existing item.
        Handles updates extracted from duplicates during semantic deduplication.
        """
        existing_id = update_info['existing_item_id']
        new_info = update_info.get('new_info', {})
        update_type = update_info.get('update_type', 'content')

        # Get the model class
        if item_type == 'risk':
            from models.risk import Risk
            model_class = Risk
        elif item_type == 'task':
            from models.task import Task
            model_class = Task
        elif item_type == 'blocker':
            from models.blocker import Blocker
            model_class = Blocker
        elif item_type == 'lesson':
            from models.lesson_learned import LessonLearned
            model_class = LessonLearned
        else:
            logger.warning(f"Unknown item type for update: {item_type}")
            return

        # Fetch existing item
        existing_obj = await session.get(model_class, existing_id)

        if not existing_obj:
            logger.warning(f"Could not find {item_type} with ID {existing_id} for update")
            return

        # Apply updates based on type
        if update_type == 'status' and 'status' in new_info:
            existing_obj.status = new_info['status']
            logger.info(f"Updated {item_type} '{existing_obj.title}' status to {new_info['status']}")

        elif update_type == 'content':
            # Update description if changed
            if 'description' in new_info and new_info['description']:
                if self.settings.append_updates_to_description:
                    # Append new info
                    existing_desc = existing_obj.description or ""
                    existing_obj.description = f"{existing_desc}\n\nUpdate: {new_info['description']}"
                else:
                    # Replace
                    existing_obj.description = new_info['description']

            # Type-specific content updates
            if item_type == 'risk' and 'mitigation' in new_info:
                existing_obj.mitigation = new_info['mitigation']
            elif item_type == 'blocker' and 'resolution' in new_info:
                existing_obj.resolution = new_info['resolution']
                if new_info['resolution']:  # If resolution added, might be resolved
                    if 'status' in new_info:
                        existing_obj.status = new_info['status']
            elif item_type == 'task' and 'assignee' in new_info:
                existing_obj.assignee = new_info['assignee']
            elif item_type == 'lesson' and 'recommendation' in new_info:
                existing_obj.recommendation = new_info['recommendation']

        # Update metadata
        existing_obj.source_content_id = str(content_id)
        existing_obj.last_updated = datetime.utcnow()
        existing_obj.updated_by = "ai"

        logger.info(
            f"Applied intelligent update to {item_type} '{existing_obj.title}': "
            f"type={update_type}, confidence={update_info.get('confidence', 0.8):.2f}"
        )


# Singleton instance
project_items_sync_service = ProjectItemsSyncService()