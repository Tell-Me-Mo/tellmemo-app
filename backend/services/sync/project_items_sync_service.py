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
                # Handle both formats: new expected format and current actual format from AI
                # Current AI format: {"type": "risk", "extracted_number": 2, "existing_title": "...", "new_status": null}
                # Expected format: {"item_type": "risk", "existing_item_number": 2, "update_type": "status", "new_info": "..."}

                # Get item type (handle both 'type' and 'item_type' keys)
                item_type = (update.get('item_type') or update.get('type', '')).lower()

                # Get index (handle both formats)
                if 'existing_item_number' in update:
                    existing_item_index = update.get('existing_item_number', -1) - 1  # Expected format
                else:
                    # For current format, we need to find by title since no index given
                    existing_item_index = -1

                # Get update type and info
                update_type = update.get('update_type', 'status')  # Default to status
                new_info = update.get('new_info') or update.get('new_status', '')
                extracted_item_index = update.get('extracted_item_number') or update.get('extracted_number', -1)
                extracted_item_index = extracted_item_index - 1 if extracted_item_index > 0 else -1

                # If we have a title but no index, try to find the item by title
                existing_title = update.get('existing_title', '')

                logger.debug(f"Processing status update: type={item_type}, update={update_type}, index={existing_item_index}, title={existing_title}")

                # Skip if no new information (this is normal for pure duplicates)
                if not new_info and update.get('new_status') is None:
                    logger.debug(f"Skipping status update with no actual status change (duplicate item): {update}")
                    continue

                if existing_item_index < 0 and not existing_title:
                    logger.debug(f"Cannot identify existing item for status update (likely duplicate without status change): {update}")
                    continue

                # Get the corresponding existing item data and model
                if item_type == 'risk' and existing_item_index < len(existing_items.get('risks', [])):
                    existing_item_data = existing_items['risks'][existing_item_index]
                    item_id = existing_item_data.get('id')

                    # Fetch the actual database object
                    existing_obj = await session.get(Risk, item_id)
                    if existing_obj:
                        # Apply updates based on type
                        if update_type == 'status' and new_info:
                            # Handle both enum and string values
                            if isinstance(new_info, str):
                                existing_obj.status = new_info
                            else:
                                existing_obj.status = new_info.value if hasattr(new_info, 'value') else str(new_info)

                            # Set resolved_date when risk is resolved (auto-closure)
                            if existing_obj.status == 'resolved' and not existing_obj.resolved_date:
                                existing_obj.resolved_date = datetime.utcnow()
                                logger.info(f"Risk '{existing_obj.title}' automatically closed - resolved_date set")
                        elif update_type == 'mitigation':
                            existing_obj.mitigation = new_info or existing_obj.mitigation
                        elif update_type == 'severity' and new_info:
                            # Handle both enum and string values
                            if isinstance(new_info, str):
                                existing_obj.severity = new_info
                            else:
                                existing_obj.severity = new_info.value if hasattr(new_info, 'value') else str(new_info)
                        elif update_type == 'resolution':
                            existing_obj.mitigation = new_info or existing_obj.mitigation
                            existing_obj.status = 'resolved'
                            # Set resolved_date when resolution is provided (auto-closure)
                            if not existing_obj.resolved_date:
                                existing_obj.resolved_date = datetime.utcnow()
                                logger.info(f"Risk '{existing_obj.title}' automatically closed - resolved_date set")

                        # Always update metadata
                        if content_id:
                            existing_obj.source_content_id = str(content_id)
                        existing_obj.last_updated = datetime.utcnow()
                        existing_obj.updated_by = "ai"
                        logger.info(f"Updated risk '{existing_obj.title}' with {update_type}")

                elif item_type == 'blocker' and existing_item_index < len(existing_items.get('blockers', [])):
                    existing_item_data = existing_items['blockers'][existing_item_index]
                    item_id = existing_item_data.get('id')

                    existing_obj = await session.get(Blocker, item_id)
                    if existing_obj:
                        if update_type == 'status' and new_info:
                            # Handle both enum and string values
                            if isinstance(new_info, str):
                                existing_obj.status = new_info
                            else:
                                existing_obj.status = new_info.value if hasattr(new_info, 'value') else str(new_info)

                            # Set resolved_date when blocker is resolved (auto-closure)
                            if existing_obj.status == 'resolved' and not existing_obj.resolved_date:
                                existing_obj.resolved_date = datetime.utcnow()
                                logger.info(f"Blocker '{existing_obj.title}' automatically closed - resolved_date set")
                        elif update_type == 'resolution':
                            existing_obj.resolution = new_info or existing_obj.resolution
                            if new_info:  # If resolution provided, mark as resolved
                                existing_obj.status = 'resolved'
                                # Set resolved_date when resolution is provided (auto-closure)
                                if not existing_obj.resolved_date:
                                    existing_obj.resolved_date = datetime.utcnow()
                                    logger.info(f"Blocker '{existing_obj.title}' automatically closed - resolved_date set")
                        elif update_type == 'impact' and new_info:
                            # Handle both enum and string values
                            if isinstance(new_info, str):
                                existing_obj.impact = new_info
                            else:
                                existing_obj.impact = new_info.value if hasattr(new_info, 'value') else str(new_info)

                        if content_id:
                            existing_obj.source_content_id = str(content_id)
                        existing_obj.last_updated = datetime.utcnow()
                        existing_obj.updated_by = "ai"
                        logger.info(f"Updated blocker '{existing_obj.title}' with {update_type}")

                elif item_type == 'task' and existing_item_index < len(existing_items.get('tasks', [])):
                    existing_item_data = existing_items['tasks'][existing_item_index]
                    item_id = existing_item_data.get('id')

                    existing_obj = await session.get(Task, item_id)
                    if existing_obj:
                        if update_type == 'status' and new_info:
                            # Handle both enum and string values
                            if isinstance(new_info, str):
                                existing_obj.status = new_info
                            else:
                                existing_obj.status = new_info.value if hasattr(new_info, 'value') else str(new_info)

                            # Set completed_date when task is completed (auto-closure)
                            if existing_obj.status == 'completed' and not existing_obj.completed_date:
                                existing_obj.completed_date = datetime.utcnow()
                                logger.info(f"Task '{existing_obj.title}' automatically closed - completed_date set")
                        elif update_type == 'progress':
                            # Extract progress percentage if mentioned
                            try:
                                import re
                                progress_match = re.search(r'(\d+)%', new_info)
                                if progress_match:
                                    existing_obj.progress_percentage = int(progress_match.group(1))
                            except:
                                pass
                            # Also update status based on progress description
                            if 'complete' in new_info.lower():
                                existing_obj.status = 'completed'
                                existing_obj.completed_date = datetime.utcnow()
                            elif 'in progress' in new_info.lower() or 'started' in new_info.lower():
                                existing_obj.status = 'in_progress'
                        elif update_type == 'assignee':
                            existing_obj.assignee = new_info or existing_obj.assignee
                        elif update_type == 'blocker':
                            existing_obj.blocker_description = new_info
                            existing_obj.status = 'blocked'

                        if content_id:
                            existing_obj.source_content_id = str(content_id)
                        existing_obj.last_updated = datetime.utcnow()
                        existing_obj.updated_by = "ai"
                        logger.info(f"Updated task '{existing_obj.title}' with {update_type}")

                elif item_type == 'lesson' and existing_item_index < len(existing_items.get('lessons', [])):
                    existing_item_data = existing_items['lessons'][existing_item_index]
                    item_id = existing_item_data.get('id')

                    existing_obj = await session.get(LessonLearned, item_id)
                    if existing_obj:
                        if update_type == 'recommendation':
                            existing_obj.recommendation = new_info or existing_obj.recommendation
                        elif update_type == 'impact':
                            existing_obj.impact = new_info or existing_obj.impact
                        elif update_type == 'context':
                            # Append new context to existing
                            existing_obj.context = f"{existing_obj.context}\n\nUpdate: {new_info}" if existing_obj.context else new_info

                        existing_obj.source_content_id = str(content_id)
                        existing_obj.last_updated = datetime.utcnow()
                        existing_obj.updated_by = "ai"
                        logger.info(f"Updated lesson '{existing_obj.title}' with {update_type}")

                else:
                    logger.warning(f"Could not find existing item for update: type={item_type}, index={existing_item_index}")

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
                        status='todo',  # Using TaskStatus.TODO value
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
                    status_update = {
                        'type': item_type,
                        'existing_item_id': update_info['existing_item_id'],
                        'existing_title': update_info['existing_item_title'],
                        'update_type': update_info.get('update_type', 'content'),
                        'new_info': update_info.get('new_info', {}),
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