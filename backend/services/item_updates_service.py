"""Service for managing item updates and automatic change tracking."""

from typing import Optional, Dict, Any, List
from uuid import UUID
from datetime import datetime
from sqlalchemy.ext.asyncio import AsyncSession

from models.item_update import ItemUpdate, ItemUpdateType
from utils.logger import get_logger

logger = get_logger(__name__)


class ItemUpdatesService:
    """Service for creating and managing item updates."""

    @staticmethod
    async def create_update(
        db: AsyncSession,
        project_id: UUID,
        item_id: UUID,
        item_type: str,
        content: str,
        update_type: str,  # Now accepts string directly
        author_name: str,
        author_email: Optional[str] = None,
        commit: bool = True
    ) -> ItemUpdate:
        """Create a new item update."""
        update = ItemUpdate(
            project_id=project_id,
            item_id=item_id,
            item_type=item_type,
            content=content,
            update_type=update_type,
            author_name=author_name,
            author_email=author_email,
            timestamp=datetime.utcnow()
        )

        db.add(update)

        if commit:
            await db.commit()
            await db.refresh(update)

        return update

    @staticmethod
    async def track_status_change(
        db: AsyncSession,
        project_id: UUID,
        item_id: UUID,
        item_type: str,
        old_status: Any,
        new_status: Any,
        author_name: str = "System",
        author_email: Optional[str] = None
    ) -> Optional[ItemUpdate]:
        """Track status changes and create an update."""
        if old_status == new_status:
            return None

        old_value = old_status.value if hasattr(old_status, 'value') else str(old_status)
        new_value = new_status.value if hasattr(new_status, 'value') else str(new_status)

        content = f"Status changed from '{old_value}' to '{new_value}'"

        return await ItemUpdatesService.create_update(
            db=db,
            project_id=project_id,
            item_id=item_id,
            item_type=item_type,
            content=content,
            update_type=ItemUpdateType.STATUS_CHANGE,  # Using string constant
            author_name=author_name,
            author_email=author_email,
            commit=False
        )

    @staticmethod
    async def track_assignment(
        db: AsyncSession,
        project_id: UUID,
        item_id: UUID,
        item_type: str,
        old_assignee: Optional[str],
        new_assignee: Optional[str],
        author_name: str = "System",
        author_email: Optional[str] = None
    ) -> Optional[ItemUpdate]:
        """Track assignment changes and create an update."""
        if old_assignee == new_assignee:
            return None

        if old_assignee is None and new_assignee:
            content = f"Assigned to {new_assignee}"
        elif old_assignee and new_assignee is None:
            content = f"Unassigned from {old_assignee}"
        elif old_assignee and new_assignee:
            content = f"Reassigned from {old_assignee} to {new_assignee}"
        else:
            return None

        return await ItemUpdatesService.create_update(
            db=db,
            project_id=project_id,
            item_id=item_id,
            item_type=item_type,
            content=content,
            update_type=ItemUpdateType.ASSIGNMENT,  # Using string constant
            author_name=author_name,
            author_email=author_email,
            commit=False
        )

    @staticmethod
    async def track_field_changes(
        db: AsyncSession,
        project_id: UUID,
        item_id: UUID,
        item_type: str,
        changes: Dict[str, Dict[str, Any]],
        author_name: str = "System",
        author_email: Optional[str] = None
    ) -> List[ItemUpdate]:
        """
        Track multiple field changes and create updates.

        Args:
            changes: Dict with field names as keys and dicts containing 'old' and 'new' values
                    Example: {'priority': {'old': 'low', 'new': 'high'}}
        """
        updates = []

        # Field display names
        field_labels = {
            'severity': 'Severity',
            'priority': 'Priority',
            'impact': 'Impact',
            'mitigation': 'Mitigation plan',
            'resolution': 'Resolution',
            'category': 'Category',
            'title': 'Title',
            'description': 'Description',
            'due_date': 'Due date',
            'target_date': 'Target date',
            'probability': 'Probability',
            'progress_percentage': 'Progress',
        }

        for field_name, change in changes.items():
            if field_name in ['status', 'assigned_to', 'assignee', 'owner']:
                # These are handled by specific tracking methods
                continue

            old_val = change.get('old')
            new_val = change.get('new')

            if old_val == new_val:
                continue

            field_label = field_labels.get(field_name, field_name.replace('_', ' ').title())

            # Format values
            old_str = ItemUpdatesService._format_value(old_val)
            new_str = ItemUpdatesService._format_value(new_val)

            if old_str and new_str:
                content = f"{field_label} changed from '{old_str}' to '{new_str}'"
            elif new_str:
                content = f"{field_label} set to '{new_str}'"
            elif old_str:
                content = f"{field_label} removed (was '{old_str}')"
            else:
                continue

            update = await ItemUpdatesService.create_update(
                db=db,
                project_id=project_id,
                item_id=item_id,
                item_type=item_type,
                content=content,
                update_type=ItemUpdateType.EDIT,  # Using string constant
                author_name=author_name,
                author_email=author_email,
                commit=False
            )
            updates.append(update)

        return updates

    @staticmethod
    def _format_value(value: Any) -> str:
        """Format a value for display in updates."""
        if value is None:
            return ""
        if hasattr(value, 'value'):  # Enum
            return value.value
        if isinstance(value, datetime):
            return value.strftime('%Y-%m-%d')
        if isinstance(value, bool):
            return "Yes" if value else "No"
        if isinstance(value, (int, float)):
            return str(value)
        return str(value).strip()

    @staticmethod
    async def create_item_created_update(
        db: AsyncSession,
        project_id: UUID,
        item_id: UUID,
        item_type: str,
        item_title: str,
        author_name: str = "System",
        author_email: Optional[str] = None,
        ai_generated: bool = False
    ) -> ItemUpdate:
        """Create an update when an item is first created."""
        if ai_generated:
            content = f"Created by AI: {item_title}"
        else:
            content = f"Created: {item_title}"

        return await ItemUpdatesService.create_update(
            db=db,
            project_id=project_id,
            item_id=item_id,
            item_type=item_type,
            content=content,
            update_type=ItemUpdateType.CREATED,  # Using string constant
            author_name=author_name,
            author_email=author_email,
            commit=False
        )

    @staticmethod
    def detect_changes(old_obj: Any, update_data: Dict[str, Any]) -> Dict[str, Dict[str, Any]]:
        """
        Detect what fields have changed between old object and update data.

        Returns:
            Dict with field names as keys and dicts containing 'old' and 'new' values
        """
        changes = {}

        for field_name, new_value in update_data.items():
            if field_name in ['last_updated', 'updated_by', 'timestamp']:
                # Skip metadata fields
                continue

            if hasattr(old_obj, field_name):
                old_value = getattr(old_obj, field_name)

                # Convert enums to their values for comparison
                old_compare = old_value.value if hasattr(old_value, 'value') else old_value
                new_compare = new_value.value if hasattr(new_value, 'value') else new_value

                if old_compare != new_compare:
                    changes[field_name] = {
                        'old': old_value,
                        'new': new_value
                    }

        return changes
