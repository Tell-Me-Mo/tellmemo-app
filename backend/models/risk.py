from sqlalchemy import Column, String, DateTime, ForeignKey, Enum, Text, Float
from sqlalchemy.orm import relationship
from sqlalchemy.dialects.postgresql import UUID
from db.database import Base
import uuid
from datetime import datetime
import enum


class RiskSeverity(enum.Enum):
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    CRITICAL = "critical"


class RiskStatus(enum.Enum):
    IDENTIFIED = "identified"
    MITIGATING = "mitigating"
    RESOLVED = "resolved"
    ACCEPTED = "accepted"
    ESCALATED = "escalated"


class Risk(Base):
    __tablename__ = "risks"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    project_id = Column(UUID(as_uuid=True), ForeignKey('projects.id', ondelete="CASCADE"), nullable=False)

    title = Column(String(200), nullable=False)
    description = Column(Text, nullable=False)
    severity = Column(Enum(RiskSeverity, values_callable=lambda obj: [e.value for e in obj]), nullable=False, default=RiskSeverity.MEDIUM)
    status = Column(Enum(RiskStatus, values_callable=lambda obj: [e.value for e in obj]), nullable=False, default=RiskStatus.IDENTIFIED)

    mitigation = Column(Text)
    impact = Column(Text)
    probability = Column(Float)  # 0.0 to 1.0

    # AI-related fields
    ai_generated = Column(String(5), default="false")  # 'true' or 'false'
    ai_confidence = Column(Float)  # Confidence score from Claude
    source_content_id = Column(UUID(as_uuid=True), ForeignKey('content.id'))  # Link to content that triggered this risk

    # Assignment fields
    assigned_to = Column(String(100))
    assigned_to_email = Column(String(255))

    # Tracking
    identified_date = Column(DateTime, default=datetime.utcnow)
    resolved_date = Column(DateTime)
    last_updated = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    updated_by = Column(String(50))  # 'ai' or 'manual'

    # Relationships
    project = relationship("Project", back_populates="risks")
    source_content = relationship("Content")

    def to_dict(self):
        return {
            "id": str(self.id),
            "project_id": str(self.project_id),
            "title": self.title,
            "description": self.description,
            "severity": self.severity.value if self.severity else None,
            "status": self.status.value if self.status else None,
            "mitigation": self.mitigation,
            "impact": self.impact,
            "probability": self.probability,
            "assigned_to": self.assigned_to,
            "assigned_to_email": self.assigned_to_email,
            "ai_generated": self.ai_generated == "true",
            "ai_confidence": self.ai_confidence,
            "source_content_id": str(self.source_content_id) if self.source_content_id else None,
            "identified_date": self.identified_date.isoformat() if self.identified_date else None,
            "resolved_date": self.resolved_date.isoformat() if self.resolved_date else None,
            "last_updated": self.last_updated.isoformat() if self.last_updated else None,
            "updated_by": self.updated_by
        }