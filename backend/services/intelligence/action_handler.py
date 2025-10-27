"""Action Handler Service.

Processes action and action_update events from GPT stream, implements action state
management and accumulation logic, calculates completeness scores, merges related
action statements, and generates alerts at segment boundaries.
"""

import asyncio
import uuid
from datetime import datetime
from typing import Dict, Any, Optional, List, Callable
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_

from models.live_insight import (
    LiveMeetingInsight,
    InsightType,
    InsightStatus
)
from utils.logger import get_logger, sanitize_for_log

logger = get_logger(__name__)


class ActionHandler:
    """Handler for action item detection, tracking, and accumulation."""

    def __init__(self):
        """Initialize the action handler."""
        # Action tracking configuration
        self.min_confidence_threshold = 0.6  # Minimum confidence to track action

        # Active actions being tracked (session_id -> {action_id -> action_data})
        self._active_actions: Dict[str, Dict[str, Dict[str, Any]]] = {}

        # WebSocket broadcast callback (set by orchestrator)
        self._ws_broadcast_callback: Optional[Callable] = None

        # Metrics
        self.actions_routed = 0
        self.action_updates_routed = 0

    def set_websocket_callback(self, callback: Callable) -> None:
        """Set the WebSocket broadcast callback.

        Args:
            callback: Async function to broadcast updates to clients
        """
        self._ws_broadcast_callback = callback

    async def handle_action(
        self,
        session_id: str,
        action_data: dict,
        session: AsyncSession,
        project_id: str,
        organization_id: str,
        recording_id: str
    ) -> Optional[LiveMeetingInsight]:
        """Process action detection event and create action item.

        Args:
            session_id: The meeting session ID
            action_data: Action data from GPT stream {id, description, owner, deadline, ...}
            session: Database session
            project_id: Project UUID
            organization_id: Organization UUID
            recording_id: Recording UUID

        Returns:
            Created LiveMeetingInsight instance or None if failed
        """
        try:
            action_id = action_data.get("id", f"a_{uuid.uuid4()}")
            description = action_data.get("description", "")
            owner = action_data.get("owner")
            deadline = action_data.get("deadline")
            speaker = action_data.get("speaker")
            timestamp_str = action_data.get("timestamp")
            confidence = action_data.get("confidence", 0.0)
            completeness = action_data.get("completeness", 0.0)

            # Filter out low-confidence actions
            if confidence < self.min_confidence_threshold:
                logger.debug(
                    f"Skipping low-confidence action (confidence={confidence}): "
                    f"{sanitize_for_log(description[:50])}"
                )
                return None

            # Parse timestamp
            detected_at = datetime.utcnow()
            if timestamp_str:
                try:
                    detected_at = datetime.fromisoformat(timestamp_str.replace('Z', '+00:00'))
                except Exception as e:
                    logger.warning(f"Failed to parse timestamp {timestamp_str}: {e}")

            logger.info(
                f"Processing action for session {sanitize_for_log(session_id)}: "
                f"{sanitize_for_log(description[:100])}"
            )

            # Check for similar existing actions (merge logic)
            existing_action_id = await self._find_similar_action(
                session_id, description, session
            )

            if existing_action_id:
                # Update existing action instead of creating new one
                logger.info(f"Merging action into existing action {existing_action_id}")
                return await self._update_existing_action(
                    existing_action_id,
                    action_data,
                    session
                )

            # Calculate completeness score
            completeness_score = self._calculate_completeness(
                description=description,
                owner=owner,
                deadline=deadline
            )

            # Create LiveMeetingInsight record
            action_insight = LiveMeetingInsight(
                session_id=session_id,
                recording_id=uuid.UUID(recording_id) if recording_id else None,
                project_id=uuid.UUID(project_id) if project_id else None,
                organization_id=uuid.UUID(organization_id) if organization_id else None,
                insight_type=InsightType.ACTION,
                detected_at=detected_at,
                speaker=speaker,
                content=description,
                status=InsightStatus.TRACKED.value,
                insight_metadata={
                    "gpt_id": action_id,
                    "owner": owner,
                    "deadline": deadline,
                    "completeness_score": completeness_score,
                    "confidence": confidence,
                    "related_ids": [],  # IDs of merged/related actions
                    "update_history": []  # Track updates over time
                }
            )

            session.add(action_insight)
            await session.flush()  # Get the database ID

            db_action_id = str(action_insight.id)

            # Store in active actions for merging
            if session_id not in self._active_actions:
                self._active_actions[session_id] = {}
            self._active_actions[session_id][db_action_id] = {
                "description": description,
                "owner": owner,
                "deadline": deadline,
                "completeness": completeness_score
            }

            # Broadcast ACTION_TRACKED event
            await self._broadcast_event(session_id, {
                "type": "ACTION_TRACKED",
                "action": action_insight.to_dict()
            })

            await session.commit()

            self.actions_routed += 1

            logger.info(
                f"Action {db_action_id} created for session {session_id} "
                f"(completeness: {completeness_score:.2f})"
            )

            return action_insight

        except Exception as e:
            logger.error(f"Failed to handle action for session {session_id}: {e}", exc_info=True)
            await session.rollback()
            return None

    async def handle_action_update(
        self,
        session_id: str,
        update_data: dict,
        session: AsyncSession
    ) -> Optional[LiveMeetingInsight]:
        """Process action_update event to enrich existing action.

        Args:
            session_id: The meeting session ID
            update_data: Update data from GPT {id, owner, deadline, completeness, ...}
            session: Database session

        Returns:
            Updated LiveMeetingInsight instance or None if not found
        """
        try:
            action_gpt_id = update_data.get("id")
            new_owner = update_data.get("owner")
            new_deadline = update_data.get("deadline")
            new_completeness = update_data.get("completeness")
            confidence = update_data.get("confidence", 0.0)

            if not action_gpt_id:
                logger.warning("action_update event missing 'id' field")
                return None

            logger.debug(f"Processing action_update for action {action_gpt_id} in session {session_id}")

            # Find action by gpt_id in metadata
            result = await session.execute(
                select(LiveMeetingInsight).where(
                    and_(
                        LiveMeetingInsight.session_id == session_id,
                        LiveMeetingInsight.insight_type == InsightType.ACTION,
                        LiveMeetingInsight.insight_metadata['gpt_id'].astext == action_gpt_id
                    )
                )
            )
            action = result.scalar_one_or_none()

            if not action:
                logger.warning(f"Action {action_gpt_id} not found for update in session {session_id}")
                return None

            # Update action metadata
            metadata = action.insight_metadata or {}
            old_owner = metadata.get("owner")
            old_deadline = metadata.get("deadline")
            old_completeness = metadata.get("completeness_score", 0.0)

            # Track what changed
            changes = {}
            if new_owner and new_owner != old_owner:
                metadata["owner"] = new_owner
                changes["owner"] = {"old": old_owner, "new": new_owner}

            if new_deadline and new_deadline != old_deadline:
                metadata["deadline"] = new_deadline
                changes["deadline"] = {"old": old_deadline, "new": new_deadline}

            # Recalculate completeness
            new_completeness_score = self._calculate_completeness(
                description=action.content,
                owner=metadata.get("owner"),
                deadline=metadata.get("deadline")
            )
            metadata["completeness_score"] = new_completeness_score

            # Add to update history
            if "update_history" not in metadata:
                metadata["update_history"] = []
            metadata["update_history"].append({
                "timestamp": datetime.utcnow().isoformat(),
                "changes": changes,
                "confidence": confidence
            })

            action.insight_metadata = metadata

            # Update status if action is now complete
            if new_completeness_score >= 1.0:
                action.update_status(InsightStatus.COMPLETE.value)

            await session.commit()

            self.action_updates_routed += 1

            # Broadcast ACTION_UPDATED event
            await self._broadcast_event(session_id, {
                "type": "ACTION_UPDATED",
                "action": action.to_dict(),
                "changes": changes
            })

            logger.info(
                f"Action {action.id} updated: completeness {old_completeness:.2f} → {new_completeness_score:.2f}"
            )

            return action

        except Exception as e:
            logger.error(
                f"Failed to handle action_update for session {session_id}: {e}",
                exc_info=True
            )
            await session.rollback()
            return None

    async def generate_segment_alerts(
        self,
        session_id: str,
        session: AsyncSession
    ) -> List[Dict[str, Any]]:
        """Generate alerts for incomplete actions at segment boundaries.

        Args:
            session_id: Meeting session ID
            session: Database session

        Returns:
            List of alert dictionaries
        """
        try:
            logger.debug(f"Generating segment alerts for session {session_id}")

            # Get all tracked actions for this session
            result = await session.execute(
                select(LiveMeetingInsight).where(
                    and_(
                        LiveMeetingInsight.session_id == session_id,
                        LiveMeetingInsight.insight_type == InsightType.ACTION,
                        LiveMeetingInsight.status == InsightStatus.TRACKED.value
                    )
                )
            )
            actions = result.scalars().all()

            alerts = []

            for action in actions:
                metadata = action.insight_metadata or {}
                completeness = metadata.get("completeness_score", 0.0)
                confidence = metadata.get("confidence", 0.0)

                # Alert for high-confidence, incomplete actions
                if confidence >= 0.8 and completeness < 1.0:
                    missing_fields = []
                    if not metadata.get("owner"):
                        missing_fields.append("owner")
                    if not metadata.get("deadline"):
                        missing_fields.append("deadline")

                    alert = {
                        "action_id": str(action.id),
                        "description": action.content,
                        "completeness": completeness,
                        "missing_fields": missing_fields,
                        "confidence": confidence
                    }
                    alerts.append(alert)

                    # Broadcast alert
                    await self._broadcast_event(session_id, {
                        "type": "ACTION_ALERT",
                        "alert": alert
                    })

            logger.info(f"Generated {len(alerts)} segment alerts for session {session_id}")
            return alerts

        except Exception as e:
            logger.error(
                f"Failed to generate segment alerts for session {session_id}: {e}",
                exc_info=True
            )
            return []

    def _calculate_completeness(
        self,
        description: str,
        owner: Optional[str],
        deadline: Optional[str]
    ) -> float:
        """Calculate action completeness score based on available information.

        Scoring:
        - Description clarity: 40%
        - Owner assignment: 30%
        - Deadline specified: 30%

        Args:
            description: Action description
            owner: Assignee name
            deadline: Deadline date string

        Returns:
            Completeness score from 0.0 to 1.0
        """
        score = 0.0

        # Description clarity (40%)
        if description and len(description.strip()) >= 10:
            score += 0.4

        # Owner assignment (30%)
        if owner:
            score += 0.3

        # Deadline specified (30%)
        if deadline:
            score += 0.3

        return round(score, 2)

    async def _find_similar_action(
        self,
        session_id: str,
        description: str,
        session: AsyncSession
    ) -> Optional[str]:
        """Find similar existing action for merging.

        Uses simple keyword matching. Could be enhanced with semantic similarity.

        Args:
            session_id: Meeting session ID
            description: New action description
            session: Database session

        Returns:
            Database ID of similar action, or None
        """
        try:
            # Get recent actions from this session (last 5 minutes)
            result = await session.execute(
                select(LiveMeetingInsight).where(
                    and_(
                        LiveMeetingInsight.session_id == session_id,
                        LiveMeetingInsight.insight_type == InsightType.ACTION,
                        LiveMeetingInsight.status.in_([
                            InsightStatus.TRACKED.value,
                            InsightStatus.COMPLETE.value
                        ])
                    )
                ).order_by(LiveMeetingInsight.detected_at.desc()).limit(10)
            )
            recent_actions = result.scalars().all()

            # Simple keyword matching
            description_words = set(description.lower().split())

            for action in recent_actions:
                action_words = set(action.content.lower().split())

                # Calculate overlap
                common_words = description_words & action_words
                total_words = description_words | action_words

                if total_words:
                    similarity = len(common_words) / len(total_words)

                    # If >60% similar, consider it the same action
                    if similarity > 0.6:
                        logger.debug(
                            f"Found similar action {action.id} "
                            f"(similarity: {similarity:.2f})"
                        )
                        return str(action.id)

            return None

        except Exception as e:
            logger.error(f"Error finding similar action: {e}", exc_info=True)
            return None

    async def _update_existing_action(
        self,
        action_id: str,
        new_data: dict,
        session: AsyncSession
    ) -> Optional[LiveMeetingInsight]:
        """Update existing action with new information from merged action.

        Args:
            action_id: Database ID of existing action
            new_data: New action data to merge
            session: Database session

        Returns:
            Updated action or None
        """
        try:
            result = await session.execute(
                select(LiveMeetingInsight).where(
                    LiveMeetingInsight.id == uuid.UUID(action_id)
                )
            )
            action = result.scalar_one_or_none()

            if not action:
                return None

            metadata = action.insight_metadata or {}

            # Update owner if new one provided and old one missing
            if new_data.get("owner") and not metadata.get("owner"):
                metadata["owner"] = new_data["owner"]

            # Update deadline if new one provided and old one missing
            if new_data.get("deadline") and not metadata.get("deadline"):
                metadata["deadline"] = new_data["deadline"]

            # Track merge
            if "related_ids" not in metadata:
                metadata["related_ids"] = []
            metadata["related_ids"].append(new_data.get("id", "unknown"))

            # Recalculate completeness
            new_completeness = self._calculate_completeness(
                description=action.content,
                owner=metadata.get("owner"),
                deadline=metadata.get("deadline")
            )
            metadata["completeness_score"] = new_completeness

            action.insight_metadata = metadata

            await session.commit()

            logger.info(f"Merged action data into existing action {action_id}")
            return action

        except Exception as e:
            logger.error(f"Error updating existing action {action_id}: {e}", exc_info=True)
            return None

    async def cleanup_session(self, session_id: str) -> None:
        """Cleanup resources for a meeting session.

        Args:
            session_id: Meeting session ID
        """
        if session_id in self._active_actions:
            del self._active_actions[session_id]
            logger.info(f"Cleaned up action handler resources for session {session_id}")

    async def _broadcast_event(self, session_id: str, event_data: dict) -> None:
        """Broadcast event to WebSocket clients.

        Args:
            session_id: Meeting session ID
            event_data: Event data to broadcast
        """
        if self._ws_broadcast_callback:
            try:
                await self._ws_broadcast_callback(session_id, event_data)
            except Exception as e:
                logger.error(f"Failed to broadcast event to clients: {e}")
        else:
            logger.debug("No WebSocket callback configured, skipping broadcast")


# Global service instance
action_handler = ActionHandler()
