from sqlalchemy import Column, String, DateTime, ForeignKey, Text, Enum as SQLEnum
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
import uuid
from datetime import datetime
import enum

from db.database import Base

class ActivityType(enum.Enum):
    PROJECT_CREATED = "project_created"
    PROJECT_UPDATED = "project_updated"
    PROJECT_DELETED = "project_deleted"
    CONTENT_UPLOADED = "content_uploaded"
    SUMMARY_GENERATED = "summary_generated"
    QUERY_SUBMITTED = "query_submitted"
    REPORT_GENERATED = "report_generated"
    MEMBER_ADDED = "member_added"
    MEMBER_REMOVED = "member_removed"

class Activity(Base):
    __tablename__ = "activities"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    project_id = Column(UUID(as_uuid=True), ForeignKey("projects.id", ondelete="CASCADE"), nullable=False)
    type = Column(SQLEnum(ActivityType), nullable=False)
    title = Column(String(255), nullable=False)
    description = Column(Text, nullable=False)
    activity_metadata = Column(Text)
    timestamp = Column(DateTime, default=datetime.utcnow, nullable=False)
    user_id = Column(String(255))
    user_name = Column(String(255))
    
    # Relationships
    project = relationship("Project", back_populates="activities")
    
    def to_dict(self):
        return {
            "id": str(self.id),
            "project_id": str(self.project_id),
            "type": self.type.value,
            "title": self.title,
            "description": self.description,
            "metadata": self.activity_metadata,
            "timestamp": self.timestamp.isoformat(),
            "user_id": self.user_id,
            "user_name": self.user_name
        }