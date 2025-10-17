from sqlalchemy import Column, String, DateTime, ForeignKey, Enum, Text, Float, JSON
from sqlalchemy.orm import relationship
from sqlalchemy.dialects.postgresql import UUID
from db.database import Base
import uuid
from datetime import datetime
import enum


class LessonCategory(enum.Enum):
    TECHNICAL = "technical"
    PROCESS = "process"
    COMMUNICATION = "communication"
    PLANNING = "planning"
    RESOURCE = "resource"
    QUALITY = "quality"
    OTHER = "other"


class LessonType(enum.Enum):
    SUCCESS = "success"
    IMPROVEMENT = "improvement"
    CHALLENGE = "challenge"
    BEST_PRACTICE = "best_practice"


class LessonLearnedImpact(enum.Enum):
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"


class LessonLearned(Base):
    __tablename__ = "lessons_learned"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    project_id = Column(UUID(as_uuid=True), ForeignKey('projects.id', ondelete="CASCADE"), nullable=False)

    title = Column(String(200), nullable=False)
    description = Column(Text, nullable=False)
    category = Column(Enum(LessonCategory, values_callable=lambda obj: [e.value for e in obj]), nullable=False, default=LessonCategory.OTHER)
    lesson_type = Column(Enum(LessonType, values_callable=lambda obj: [e.value for e in obj]), nullable=False, default=LessonType.IMPROVEMENT)
    impact = Column(Enum(LessonLearnedImpact, values_callable=lambda obj: [e.value for e in obj]), nullable=False, default=LessonLearnedImpact.MEDIUM)

    recommendation = Column(Text)  # What should be done differently in the future
    context = Column(Text)  # Additional context or background
    tags = Column(String(500))  # Comma-separated tags for easy filtering

    # AI-related fields
    ai_generated = Column(String(5), default="false")  # 'true' or 'false'
    ai_confidence = Column(Float)  # Confidence score from Claude
    source_content_id = Column(UUID(as_uuid=True), ForeignKey('content.id'))  # Link to content that triggered this lesson
    title_embedding = Column(JSON, nullable=True)  # Embedding vector for semantic deduplication (768 dimensions)

    # Tracking
    identified_date = Column(DateTime, default=datetime.utcnow)
    last_updated = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    updated_by = Column(String(50))  # 'ai' or 'manual'

    # Relationships
    project = relationship("Project", back_populates="lessons_learned")
    source_content = relationship("Content")

    def to_dict(self):
        return {
            "id": str(self.id),
            "project_id": str(self.project_id),
            "title": self.title,
            "description": self.description,
            "category": self.category.value if hasattr(self.category, 'value') else self.category if self.category else None,
            "lesson_type": self.lesson_type.value if hasattr(self.lesson_type, 'value') else self.lesson_type if self.lesson_type else None,
            "impact": self.impact.value if hasattr(self.impact, 'value') else self.impact if self.impact else None,
            "recommendation": self.recommendation,
            "context": self.context,
            "tags": self.tags.split(',') if self.tags else [],
            "ai_generated": self.ai_generated == "true",
            "ai_confidence": self.ai_confidence,
            "source_content_id": str(self.source_content_id) if self.source_content_id else None,
            "identified_date": self.identified_date.isoformat() if self.identified_date else None,
            "last_updated": self.last_updated.isoformat() if self.last_updated else None,
            "updated_by": self.updated_by,
            "title_embedding": self.title_embedding
        }