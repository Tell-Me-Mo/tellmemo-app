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
    project_id = Column(UUID(as_uuid=True), nullable=True)  # Can store project_id, program_id, portfolio_id, or None for org-level. No FK constraint to allow flexibility.
    organization_id = Column(UUID(as_uuid=True), ForeignKey("organizations.id", ondelete="CASCADE"), nullable=False)
    context_id = Column(String(255), nullable=True)  # Optional context ID for filtering (e.g., 'risk_<uuid>', 'task_<uuid>')

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
    # Note: project relationship removed since project_id no longer has FK constraint (it can store program/portfolio IDs too)
    organization = relationship("Organization", back_populates="conversations")