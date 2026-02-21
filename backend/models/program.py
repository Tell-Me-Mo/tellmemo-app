"""Program model for organizing projects within portfolios."""

import uuid
from datetime import datetime
from sqlalchemy import Column, String, DateTime, ForeignKey, Text, Boolean
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from db.database import Base


class Program(Base):
    """Program model for grouping related projects."""
    
    __tablename__ = "programs"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    organization_id = Column(UUID(as_uuid=True), ForeignKey("organizations.id", ondelete="CASCADE"), nullable=False)
    name = Column(String(255), nullable=False, index=True)
    description = Column(Text, nullable=True)
    portfolio_id = Column(UUID(as_uuid=True), ForeignKey("portfolios.id", ondelete="SET NULL"), nullable=True)
    created_by = Column(String(255), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)
    is_demo = Column(Boolean, default=False, nullable=False, server_default="false")

    # Relationships
    portfolio = relationship("Portfolio", back_populates="programs")
    projects = relationship("Project", back_populates="program")