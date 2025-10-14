from sqlalchemy import Column, String, DateTime, ForeignKey, Enum, Text
from sqlalchemy.dialects.postgresql import UUID
from db.database import Base
import uuid
from datetime import datetime
import enum


class ItemUpdateType(enum.Enum):
    COMMENT = "comment"
    STATUS_CHANGE = "status_change"
    ASSIGNMENT = "assignment"
    EDIT = "edit"
    CREATED = "created"


class ItemUpdate(Base):
    __tablename__ = "item_updates"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    project_id = Column(UUID(as_uuid=True), ForeignKey('projects.id', ondelete="CASCADE"), nullable=False)

    # Item reference - polymorphic association
    item_id = Column(UUID(as_uuid=True), nullable=False)  # ID of the risk/task/blocker/lesson
    item_type = Column(String(50), nullable=False)  # 'risks', 'tasks', 'blockers', 'lessons'

    # Update content
    content = Column(Text, nullable=False)
    update_type = Column(Enum(ItemUpdateType, values_callable=lambda obj: [e.value for e in obj]), nullable=False, default=ItemUpdateType.COMMENT)

    # Author information
    author_name = Column(String(100), nullable=False)
    author_email = Column(String(255))

    # Tracking
    timestamp = Column(DateTime, default=datetime.utcnow, nullable=False)

    def to_dict(self):
        return {
            "id": str(self.id),
            "project_id": str(self.project_id),
            "item_id": str(self.item_id),
            "item_type": self.item_type,
            "content": self.content,
            "update_type": self.update_type.value if self.update_type else None,
            "author_name": self.author_name,
            "author_email": self.author_email,
            "timestamp": self.timestamp.isoformat() if self.timestamp else None,
        }
