from sqlalchemy import Column, String, DateTime, ForeignKey, Enum, Text, Float, Integer, JSON
from sqlalchemy.orm import relationship
from sqlalchemy.dialects.postgresql import UUID
from db.database import Base
import uuid
from datetime import datetime
import enum


class TaskStatus(enum.Enum):
    TODO = "todo"
    IN_PROGRESS = "in_progress"
    BLOCKED = "blocked"
    COMPLETED = "completed"
    CANCELLED = "cancelled"


class TaskPriority(enum.Enum):
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    URGENT = "urgent"


class Task(Base):
    __tablename__ = "tasks"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    project_id = Column(UUID(as_uuid=True), ForeignKey('projects.id', ondelete="CASCADE"), nullable=False)

    title = Column(String(200), nullable=False)
    description = Column(Text)
    status = Column(Enum(TaskStatus, values_callable=lambda obj: [e.value for e in obj]), nullable=False, default=TaskStatus.TODO)
    priority = Column(Enum(TaskPriority, values_callable=lambda obj: [e.value for e in obj]), nullable=False, default=TaskPriority.MEDIUM)

    assignee = Column(String(100))
    due_date = Column(DateTime)
    completed_date = Column(DateTime)

    # Progress tracking
    progress_percentage = Column(Integer, default=0)  # 0-100
    blocker_description = Column(Text)

    # Question to ask - for tasks that require asking someone something
    question_to_ask = Column(Text)

    # AI-related fields
    ai_generated = Column(String(5), default="false")  # 'true' or 'false'
    ai_confidence = Column(Float)  # Confidence score from Claude
    source_content_id = Column(UUID(as_uuid=True), ForeignKey('content.id'))  # Link to content that triggered this task
    title_embedding = Column(JSON, nullable=True)  # Embedding vector for semantic deduplication (768 dimensions)

    # Dependencies
    depends_on_risk_id = Column(UUID(as_uuid=True), ForeignKey('risks.id'))  # Task might be created to mitigate a risk

    # Tracking
    created_date = Column(DateTime, default=datetime.utcnow)
    last_updated = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    updated_by = Column(String(50))  # 'ai' or 'manual'

    # Relationships
    project = relationship("Project", back_populates="tasks")
    source_content = relationship("Content")
    related_risk = relationship("Risk")

    def to_dict(self):
        return {
            "id": str(self.id),
            "project_id": str(self.project_id),
            "title": self.title,
            "description": self.description,
            "status": self.status.value if hasattr(self.status, 'value') else self.status if self.status else None,
            "priority": self.priority.value if hasattr(self.priority, 'value') else self.priority if self.priority else None,
            "assignee": self.assignee,
            "due_date": self.due_date.isoformat() if self.due_date else None,
            "completed_date": self.completed_date.isoformat() if self.completed_date else None,
            "progress_percentage": self.progress_percentage,
            "blocker_description": self.blocker_description,
            "question_to_ask": self.question_to_ask,
            "ai_generated": self.ai_generated == "true",
            "ai_confidence": self.ai_confidence,
            "source_content_id": str(self.source_content_id) if self.source_content_id else None,
            "depends_on_risk_id": str(self.depends_on_risk_id) if self.depends_on_risk_id else None,
            "created_date": self.created_date.isoformat() if self.created_date else None,
            "last_updated": self.last_updated.isoformat() if self.last_updated else None,
            "updated_by": self.updated_by,
            "title_embedding": self.title_embedding
        }