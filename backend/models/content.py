"""Content model for meeting transcripts and emails."""

import uuid
from datetime import datetime, date
from sqlalchemy import Column, String, Text, DateTime, Date, ForeignKey, Boolean, Integer, Enum as SQLEnum
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
import enum

from db.database import Base


class ContentType(str, enum.Enum):
    """Content type enumeration."""
    MEETING = "meeting"
    EMAIL = "email"


class Content(Base):
    """Content model for storing meeting transcripts and email content."""
    
    __tablename__ = "content"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    project_id = Column(UUID(as_uuid=True), ForeignKey("projects.id", ondelete="CASCADE"), nullable=False)
    content_type = Column(SQLEnum(ContentType), nullable=False, index=True)
    title = Column(String(255), nullable=False)
    content = Column(Text, nullable=False)
    date = Column(Date, nullable=True)
    uploaded_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    uploaded_by = Column(String(255), nullable=True)
    chunk_count = Column(Integer, default=0, nullable=False)
    summary_generated = Column(Boolean, default=False, nullable=False)
    
    # Metadata for tracking processing status
    processed_at = Column(DateTime, nullable=True)
    processing_error = Column(Text, nullable=True)
    
    # Relationships
    project = relationship("Project", back_populates="content")
    summaries = relationship("Summary", back_populates="content", cascade="all, delete-orphan")