"""Live Meeting Insight Model.

This model stores real-time questions, actions, and answers detected during live meetings.
"""
import uuid
import enum
from datetime import datetime
from sqlalchemy import Column, String, Text, DateTime, ForeignKey, Enum as SQLEnum
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import relationship
from db.database import Base


class InsightType(str, enum.Enum):
    """Insight type enumeration."""
    QUESTION = "question"
    ACTION = "action"
    ANSWER = "answer"


class InsightStatus(str, enum.Enum):
    """Insight status enumeration."""
    SEARCHING = "searching"
    FOUND = "found"
    MONITORING = "monitoring"
    ANSWERED = "answered"
    UNANSWERED = "unanswered"
    TRACKED = "tracked"
    COMPLETE = "complete"


class AnswerSource(str, enum.Enum):
    """Answer source enumeration for four-tier discovery system."""
    RAG = "rag"  # Tier 1: From documents
    MEETING_CONTEXT = "meeting_context"  # Tier 2: Earlier in meeting
    LIVE_CONVERSATION = "live_conversation"  # Tier 3: Live monitoring
    GPT_GENERATED = "gpt_generated"  # Tier 4: AI-generated
    USER_PROVIDED = "user_provided"  # User manually marked as answered
    UNANSWERED = "unanswered"  # No answer found


class LiveMeetingInsight(Base):
    """Model for real-time meeting insights (questions, actions, answers)."""

    __tablename__ = "live_meeting_insights"

    # Primary key
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)

    # Session and recording identifiers
    session_id = Column(String(255), nullable=False, index=True)
    recording_id = Column(
        UUID(as_uuid=True),
        ForeignKey("recordings.id", ondelete="CASCADE"),
        nullable=True,
        index=True
    )

    # Foreign keys to organization and project
    project_id = Column(
        UUID(as_uuid=True),
        ForeignKey("projects.id", ondelete="CASCADE"),
        nullable=False,
        index=True
    )
    organization_id = Column(
        UUID(as_uuid=True),
        ForeignKey("organizations.id", ondelete="CASCADE"),
        nullable=False,
        index=True
    )

    # Insight classification (stored as string for flexibility)
    insight_type = Column(String(50), nullable=False, index=True)

    # Temporal information
    detected_at = Column(DateTime(timezone=True), nullable=False, index=True)

    # Speaker attribution
    speaker = Column(String(255), nullable=True, index=True)

    # Content
    content = Column(Text, nullable=False)

    # Status tracking
    status = Column(String(50), nullable=False, default="tracking")

    # Answer source (for questions)
    answer_source = Column(String(50), nullable=True)

    # Insight metadata stored as JSONB for flexibility
    # Stores: tier_results, completeness_score, confidence, etc.
    # Note: Using 'insight_metadata' instead of 'metadata' (reserved by SQLAlchemy)
    insight_metadata = Column(JSONB, nullable=True, default={})

    # Timestamps
    created_at = Column(DateTime(timezone=True), default=datetime.utcnow, nullable=False)
    updated_at = Column(
        DateTime(timezone=True),
        default=datetime.utcnow,
        onupdate=datetime.utcnow,
        nullable=False
    )

    # Relationships
    recording = relationship("Recording", back_populates="live_insights")
    project = relationship("Project", back_populates="live_insights")
    organization = relationship("Organization", back_populates="live_insights")

    def update_status(self, new_status: str) -> None:
        """Update the insight status.

        Args:
            new_status: The new status value
        """
        self.status = new_status
        self.updated_at = datetime.utcnow()

    def add_tier_result(self, tier_type: str, result_data: dict) -> None:
        """Add a tier result to the insight metadata.

        Args:
            tier_type: The tier type (rag, meeting_context, live_conversation, gpt_generated)
            result_data: Dictionary containing tier result data
        """
        if not self.insight_metadata:
            self.insight_metadata = {}

        if "tier_results" not in self.insight_metadata:
            self.insight_metadata["tier_results"] = {}

        self.insight_metadata["tier_results"][tier_type] = result_data
        self.updated_at = datetime.utcnow()

    def calculate_completeness(self) -> float:
        """Calculate action item completeness score.

        Based on presence of:
        - Description: 0.4
        - Owner: 0.3
        - Deadline: 0.3

        Returns:
            Completeness score from 0.0 to 1.0
        """
        if self.insight_type != InsightType.ACTION:
            return 0.0

        score = 0.0

        # Description is required (base score)
        if self.content:
            score += 0.4

        # Check insight_metadata for owner and deadline
        if self.insight_metadata:
            if self.insight_metadata.get("owner"):
                score += 0.3
            if self.insight_metadata.get("deadline"):
                score += 0.3

        # Store completeness in insight_metadata
        if not self.insight_metadata:
            self.insight_metadata = {}
        self.insight_metadata["completeness_score"] = score

        return score

    def set_answer_source(self, source: str, confidence: float = None) -> None:
        """Set the answer source for a question.

        Args:
            source: The answer source (rag, meeting_context, live_conversation, gpt_generated)
            confidence: Optional confidence score for the answer
        """
        self.answer_source = source

        if confidence is not None:
            if not self.insight_metadata:
                self.insight_metadata = {}
            self.insight_metadata["confidence"] = confidence

        self.updated_at = datetime.utcnow()

    def to_dict(self) -> dict:
        """Convert to dictionary representation.

        Returns:
            Dictionary representation of the insight
        """
        return {
            "id": str(self.id),
            "session_id": self.session_id,
            "recording_id": str(self.recording_id),
            "project_id": str(self.project_id),
            "organization_id": str(self.organization_id),
            "insight_type": self.insight_type.value if self.insight_type else None,
            "detected_at": self.detected_at.isoformat() if self.detected_at else None,
            "speaker": self.speaker,
            "content": self.content,
            "status": self.status,
            "answer_source": self.answer_source,
            "metadata": self.insight_metadata or {},
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }
