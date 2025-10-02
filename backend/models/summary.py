"""Summary model for generated meeting and project summaries."""

import uuid
from datetime import datetime
from sqlalchemy import Column, String, Text, DateTime, ForeignKey, Integer, Enum as SQLEnum
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import relationship
import enum

from db.database import Base


class SummaryType(str, enum.Enum):
    """Summary type enumeration."""
    MEETING = "meeting"
    PROJECT = "project"
    PROGRAM = "program"
    PORTFOLIO = "portfolio"


class Summary(Base):
    """Summary model for storing generated summaries."""

    __tablename__ = "summaries"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)

    # Multi-tenant support
    organization_id = Column(UUID(as_uuid=True), ForeignKey("organizations.id", ondelete="CASCADE"), nullable=False)

    # Entity relationships - only one should be set
    project_id = Column(UUID(as_uuid=True), ForeignKey("projects.id", ondelete="CASCADE"), nullable=True)
    program_id = Column(UUID(as_uuid=True), ForeignKey("programs.id", ondelete="CASCADE"), nullable=True)
    portfolio_id = Column(UUID(as_uuid=True), ForeignKey("portfolios.id", ondelete="CASCADE"), nullable=True)

    content_id = Column(UUID(as_uuid=True), ForeignKey("content.id", ondelete="CASCADE"), nullable=True)
    summary_type = Column(SQLEnum(SummaryType), nullable=False, index=True)
    subject = Column(String(255), nullable=False)
    body = Column(Text, nullable=False)
    
    # Structured data for meeting summaries
    key_points = Column(JSONB, nullable=True)  # List of key discussion points
    decisions = Column(JSONB, nullable=True)   # List of decisions made
    action_items = Column(JSONB, nullable=True)  # List of action items
    
    # Enhanced Analytics Fields
    sentiment_analysis = Column(JSONB, nullable=True)  # {overall, trajectory, topics, engagement}
    risks = Column(JSONB, nullable=True)  # List of risks [{title, description, severity, owner}]
    blockers = Column(JSONB, nullable=True)  # List of blockers [{title, description, impact, owner}]
    cross_meeting_insights = Column(JSONB, nullable=True)  # {related_discussions, progress, themes}
    priority_scores = Column(JSONB, nullable=True)  # {urgency, importance, critical_items}
    communication_insights = Column(JSONB, nullable=True)  # {unanswered, follow_ups, clarity, agenda}

    # Lessons Learned - extracted from meetings
    lessons_learned = Column(JSONB, nullable=True)  # [{title, description, category, lesson_type, impact, recommendation}]

    # Next Meeting Planning
    next_meeting_agenda = Column(JSONB, nullable=True)  # [{title, description, priority, estimated_time, presenter}]
    
    # Metadata
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    created_by = Column(String(255), nullable=True)
    date_range_start = Column(DateTime, nullable=True)  # For project summaries
    date_range_end = Column(DateTime, nullable=True)    # For project summaries
    
    # LLM tracking
    token_count = Column(Integer, nullable=True)
    generation_time_ms = Column(Integer, nullable=True)
    format = Column(String, default="general", nullable=False)  # Summary format type

    # Relationships
    organization = relationship("Organization", back_populates="summaries")
    project = relationship("Project", back_populates="summaries")
    content = relationship("Content", back_populates="summaries")