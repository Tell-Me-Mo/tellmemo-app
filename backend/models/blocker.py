from sqlalchemy import Column, String, DateTime, ForeignKey, Enum, Text, Float, JSON
from sqlalchemy.orm import relationship
from sqlalchemy.dialects.postgresql import UUID
from db.database import Base
import uuid
from datetime import datetime
import enum


class BlockerImpact(enum.Enum):
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    CRITICAL = "critical"


class BlockerStatus(enum.Enum):
    ACTIVE = "active"
    RESOLVED = "resolved"
    PENDING = "pending"
    ESCALATED = "escalated"


class Blocker(Base):
    __tablename__ = "blockers"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    project_id = Column(UUID(as_uuid=True), ForeignKey('projects.id', ondelete="CASCADE"), nullable=False)

    title = Column(String(200), nullable=False)
    description = Column(Text, nullable=False)
    impact = Column(Enum(BlockerImpact, values_callable=lambda obj: [e.value for e in obj]), nullable=False, default=BlockerImpact.HIGH)
    status = Column(Enum(BlockerStatus, values_callable=lambda obj: [e.value for e in obj]), nullable=False, default=BlockerStatus.ACTIVE)

    resolution = Column(Text)  # How to resolve the blocker
    category = Column(String(50), default="general")
    owner = Column(String(100))  # Who is responsible for resolution
    dependencies = Column(Text)  # JSON array of dependencies

    # Dates
    target_date = Column(DateTime)  # When it needs to be resolved by
    resolved_date = Column(DateTime)
    escalation_date = Column(DateTime)  # When it was escalated

    # AI-related fields
    ai_generated = Column(String(5), default="false")  # 'true' or 'false'
    ai_confidence = Column(Float)  # Confidence score from Claude
    source_content_id = Column(UUID(as_uuid=True), ForeignKey('content.id'))  # Link to content that triggered this blocker
    title_embedding = Column(JSON, nullable=True)  # Embedding vector for semantic deduplication (768 dimensions)

    # Assignment fields
    assigned_to = Column(String(100))  # User ID or name
    assigned_to_email = Column(String(255))

    # Tracking
    identified_date = Column(DateTime, default=datetime.utcnow)
    last_updated = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    updated_by = Column(String(50))  # 'ai' or 'manual'

    # Relationships
    project = relationship("Project", back_populates="blockers")
    source_content = relationship("Content")

    def to_dict(self):
        return {
            "id": str(self.id),
            "project_id": str(self.project_id),
            "title": self.title,
            "description": self.description,
            "impact": self.impact.value if hasattr(self.impact, 'value') else self.impact if self.impact else None,
            "status": self.status.value if hasattr(self.status, 'value') else self.status if self.status else None,
            "resolution": self.resolution,
            "category": self.category,
            "owner": self.owner,
            "dependencies": self.dependencies,
            "target_date": self.target_date.isoformat() if self.target_date else None,
            "resolved_date": self.resolved_date.isoformat() if self.resolved_date else None,
            "escalation_date": self.escalation_date.isoformat() if self.escalation_date else None,
            "ai_generated": self.ai_generated == "true",
            "ai_confidence": self.ai_confidence,
            "source_content_id": str(self.source_content_id) if self.source_content_id else None,
            "assigned_to": self.assigned_to,
            "assigned_to_email": self.assigned_to_email,
            "identified_date": self.identified_date.isoformat() if self.identified_date else None,
            "last_updated": self.last_updated.isoformat() if self.last_updated else None,
            "updated_by": self.updated_by,
            "title_embedding": self.title_embedding
        }