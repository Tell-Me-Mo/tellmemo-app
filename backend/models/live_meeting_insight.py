"""Live Meeting Insight model for storing real-time insights."""

import uuid
from datetime import datetime
from sqlalchemy import Column, String, Text, DateTime, ForeignKey, Float, Integer
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import relationship

from db.database import Base


class LiveMeetingInsight(Base):
    """Model for storing insights extracted during live meetings."""

    __tablename__ = "live_meeting_insights"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    session_id = Column(String(255), nullable=False, index=True)
    project_id = Column(UUID(as_uuid=True), ForeignKey("projects.id", ondelete="CASCADE"), nullable=False, index=True)
    organization_id = Column(UUID(as_uuid=True), ForeignKey("organizations.id", ondelete="CASCADE"), nullable=False, index=True)

    # Insight details
    insight_type = Column(String(50), nullable=False, index=True)  # action_item, decision, question, etc.
    priority = Column(String(20), nullable=False)  # critical, high, medium, low
    content = Column(Text, nullable=False)
    context = Column(Text, nullable=True)

    # Action item specific fields
    assigned_to = Column(String(255), nullable=True)
    due_date = Column(String(50), nullable=True)

    # Metadata
    confidence_score = Column(Float, nullable=True)
    chunk_index = Column(Integer, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False, index=True)
    insight_metadata = Column(JSONB, nullable=True)  # For storing related_content_ids, contradictions, etc.

    # Relationships
    project = relationship("Project", backref="live_insights")
    organization = relationship("Organization", backref="live_insights")

    def to_dict(self):
        """Convert model to dictionary."""
        return {
            'id': str(self.id),
            'session_id': self.session_id,
            'project_id': str(self.project_id),
            'organization_id': str(self.organization_id),
            'insight_type': self.insight_type,
            'priority': self.priority,
            'content': self.content,
            'context': self.context,
            'assigned_to': self.assigned_to,
            'due_date': self.due_date,
            'confidence_score': self.confidence_score,
            'chunk_index': self.chunk_index,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'metadata': self.insight_metadata
        }
