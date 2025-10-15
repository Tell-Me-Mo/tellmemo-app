from sqlalchemy import Column, String, DateTime, ForeignKey, Text, CheckConstraint
from sqlalchemy.dialects.postgresql import UUID
from db.database import Base
import uuid
from datetime import datetime


# Define valid update types as constants
class ItemUpdateType:
    """Update type constants - using strings instead of enum for flexibility."""
    COMMENT = "comment"
    STATUS_CHANGE = "status_change"
    ASSIGNMENT = "assignment"
    EDIT = "edit"
    CREATED = "created"

    # List of all valid types for validation
    ALL_TYPES = [COMMENT, STATUS_CHANGE, ASSIGNMENT, EDIT, CREATED]

    @classmethod
    def is_valid(cls, update_type: str) -> bool:
        """Check if an update type is valid."""
        return update_type in cls.ALL_TYPES


class ItemUpdate(Base):
    __tablename__ = "item_updates"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    project_id = Column(UUID(as_uuid=True), ForeignKey('projects.id', ondelete="CASCADE"), nullable=False)

    # Item reference - polymorphic association
    item_id = Column(UUID(as_uuid=True), nullable=False)  # ID of the risk/task/blocker/lesson
    item_type = Column(String(50), nullable=False)  # 'risks', 'tasks', 'blockers', 'lessons'

    # Update content
    content = Column(Text, nullable=False)
    # Using String instead of Enum for flexibility
    update_type = Column(
        String(50),
        nullable=False,
        default=ItemUpdateType.COMMENT,
        # Add check constraint to ensure valid values
        info={'valid_values': ItemUpdateType.ALL_TYPES}
    )

    # Author information
    author_name = Column(String(100), nullable=False)
    author_email = Column(String(255))

    # Tracking
    timestamp = Column(DateTime, default=datetime.utcnow, nullable=False)

    # Add table-level check constraint
    __table_args__ = (
        CheckConstraint(
            f"update_type IN {tuple(ItemUpdateType.ALL_TYPES)}",
            name='ck_item_updates_update_type'
        ),
    )

    def to_dict(self):
        return {
            "id": str(self.id),
            "project_id": str(self.project_id),
            "item_id": str(self.item_id),
            "item_type": self.item_type,
            "content": self.content,
            "update_type": self.update_type,  # Now it's already a string
            "author_name": self.author_name,
            "author_email": self.author_email,
            "timestamp": self.timestamp.isoformat() if self.timestamp else None,
        }
