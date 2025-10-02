"""Conversation model for storing user chat sessions."""

import uuid
from datetime import datetime
from sqlalchemy import Column, String, Text, DateTime, ForeignKey
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import relationship

from db.database import Base


class Conversation(Base):
    """Conversation model for storing chat sessions."""

    __tablename__ = "conversations"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    project_id = Column(UUID(as_uuid=True), ForeignKey("projects.id", ondelete="CASCADE"), nullable=False)
    organization_id = Column(UUID(as_uuid=True), ForeignKey("organizations.id", ondelete="CASCADE"), nullable=False)

    # Conversation metadata
    title = Column(String(255), nullable=False)

    # Messages stored as JSONB array
    # Each message: {"question": str, "answer": str, "sources": [str], "confidence": float, "timestamp": str, "isAnswerPending": bool}
    messages = Column(JSONB, nullable=False, default=list)

    # Tracking
    created_by = Column(String(255), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    last_accessed_at = Column(DateTime, default=datetime.utcnow, nullable=False)

    # Relationships
    project = relationship("Project", back_populates="conversations")
    organization = relationship("Organization", back_populates="conversations")