"""Proactive Assistance Feedback model for user feedback collection and analytics."""

import uuid
from datetime import datetime
from sqlalchemy import Column, String, DateTime, ForeignKey, Boolean, Float, Text, Index
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import relationship

from db.database import Base


class ProactiveAssistanceFeedback(Base):
    """Model for storing user feedback on proactive assistance suggestions."""

    __tablename__ = "proactive_assistance_feedback"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)

    # Session and insight tracking
    session_id = Column(String(255), nullable=False, index=True)
    insight_id = Column(String(255), nullable=False, index=True)  # From ProactiveAssistanceModel
    project_id = Column(UUID(as_uuid=True), ForeignKey("projects.id", ondelete="CASCADE"), nullable=False, index=True)
    organization_id = Column(UUID(as_uuid=True), ForeignKey("organizations.id", ondelete="CASCADE"), nullable=False, index=True)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)

    # Feedback content
    assistance_type = Column(String(50), nullable=False, index=True)  # auto_answer, clarification_needed, etc.
    is_helpful = Column(Boolean, nullable=False, index=True)  # True = thumbs up, False = thumbs down
    confidence_score = Column(Float, nullable=True)  # Original confidence score for correlation analysis

    # Optional detailed feedback
    feedback_text = Column(Text, nullable=True)  # Optional text feedback from user
    feedback_category = Column(String(50), nullable=True)  # wrong_answer, not_relevant, too_verbose, etc.

    # Metadata for analysis
    feedback_metadata = Column(JSONB, nullable=True)  # Context, user agent, etc.

    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False, index=True)

    # Relationships
    project = relationship("Project")
    organization = relationship("Organization")
    user = relationship("User")

    # Composite indexes for analytics queries
    __table_args__ = (
        Index('ix_feedback_type_helpful', 'assistance_type', 'is_helpful'),
        Index('ix_feedback_project_type', 'project_id', 'assistance_type'),
        Index('ix_feedback_org_created', 'organization_id', 'created_at'),
    )

    def to_dict(self):
        """Convert model to dictionary."""
        return {
            'id': str(self.id),
            'session_id': self.session_id,
            'insight_id': self.insight_id,
            'project_id': str(self.project_id),
            'organization_id': str(self.organization_id),
            'user_id': str(self.user_id),
            'assistance_type': self.assistance_type,
            'is_helpful': self.is_helpful,
            'confidence_score': self.confidence_score,
            'feedback_text': self.feedback_text,
            'feedback_category': self.feedback_category,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'metadata': self.feedback_metadata
        }
