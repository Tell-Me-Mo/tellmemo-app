"""Portfolio model for organizing programs and projects."""

import uuid
from datetime import datetime
from sqlalchemy import Column, String, DateTime, Text, Enum as SQLEnum, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
import enum

from db.database import Base


class HealthStatus(str, enum.Enum):
    """Portfolio health status (RAG - Red, Amber, Green)."""
    GREEN = "green"
    AMBER = "amber"
    RED = "red"
    NOT_SET = "not_set"


class Portfolio(Base):
    """Portfolio model for grouping programs and projects."""

    __tablename__ = "portfolios"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    organization_id = Column(UUID(as_uuid=True), ForeignKey("organizations.id", ondelete="CASCADE"), nullable=False)
    name = Column(String(255), nullable=False, index=True)
    description = Column(Text, nullable=True)
    owner = Column(String(255), nullable=True)
    health_status = Column(SQLEnum(HealthStatus), default=HealthStatus.NOT_SET, nullable=False)
    risk_summary = Column(Text, nullable=True)
    created_by = Column(String(255), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)
    
    # Relationships
    programs = relationship("Program", back_populates="portfolio")
    projects = relationship("Project", back_populates="portfolio")  # Direct projects without a program