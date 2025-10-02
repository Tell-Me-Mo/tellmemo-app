"""Query model for tracking user queries and analytics."""

import uuid
from datetime import datetime
from sqlalchemy import Column, String, Text, DateTime, ForeignKey, Integer, Float
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import relationship

from db.database import Base


class Query(Base):
    """Query model for logging and analyzing user queries."""
    
    __tablename__ = "queries"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    project_id = Column(UUID(as_uuid=True), ForeignKey("projects.id", ondelete="CASCADE"), nullable=False)
    
    # Query details
    question = Column(Text, nullable=False)
    answer = Column(Text, nullable=False)
    
    # Sources and context
    sources = Column(JSONB, nullable=True)  # List of source references
    retrieved_chunks = Column(JSONB, nullable=True)  # IDs and metadata of retrieved chunks
    confidence_score = Column(Float, nullable=True)  # Confidence score of the answer
    
    # Performance metrics
    response_time_ms = Column(Integer, nullable=False)
    token_count = Column(Integer, nullable=True)
    embedding_time_ms = Column(Integer, nullable=True)
    retrieval_time_ms = Column(Integer, nullable=True)
    generation_time_ms = Column(Integer, nullable=True)
    
    # User tracking
    created_by = Column(String(255), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    
    # Feedback (for future enhancement)
    user_rating = Column(Integer, nullable=True)  # 1-5 rating
    user_feedback = Column(Text, nullable=True)
    
    # Cost tracking
    llm_cost_usd = Column(Float, nullable=True)
    
    # Relationships
    project = relationship("Project", back_populates="queries")