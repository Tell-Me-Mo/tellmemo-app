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

    # Content
    # Note: Speaker diarization not supported in streaming API
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

        # Mark the JSONB field as modified so SQLAlchemy detects the change
        from sqlalchemy.orm import attributes
        attributes.flag_modified(self, "insight_metadata")

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
            Dictionary representation of the insight (Flutter-compatible format)
        """
        # Flutter expects different field names - map backend fields to Flutter model
        result = {
            "id": str(self.id),
            "session_id": self.session_id,
            "recording_id": str(self.recording_id) if self.recording_id else None,
            "project_id": str(self.project_id),
            "organization_id": str(self.organization_id),
            "insight_type": self.insight_type if isinstance(self.insight_type, str) else self.insight_type.value,
            "timestamp": self.detected_at.isoformat() if self.detected_at else None,  # Flutter expects 'timestamp'
            "text": self.content,  # Flutter expects 'text' not 'content'
            "description": self.content,  # For actions, Flutter expects 'description'
            "status": self.status,
            "answer_source": self.answer_source,
            "metadata": self.insight_metadata or {},
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }
        # Note: Speaker diarization not supported in streaming API

        # Add Flutter-specific fields with sensible defaults
        metadata = self.insight_metadata or {}

        # For questions: add category and confidence
        if self.insight_type == "question" or (hasattr(self.insight_type, 'value') and self.insight_type.value == "question"):
            result["category"] = metadata.get("category", "factual")
            result["confidence"] = metadata.get("confidence", 0.85)  # Default question detection confidence

            # Convert tier_results dict to list format expected by Flutter
            tier_results_dict = metadata.get("tier_results", {})
            tier_results_list = []

            # DEBUG: Log raw tier_results from metadata
            import logging
            logger = logging.getLogger(__name__)
            logger.info(f"[to_dict] Question {self.id}: tier_results_dict type={type(tier_results_dict)}, value={tier_results_dict}")

            if isinstance(tier_results_dict, dict):
                # Convert dict to proper TierResult format with all required fields
                for tier_type, tier_data in tier_results_dict.items():
                    logger.info(f"[to_dict] Processing tier_type={tier_type}, tier_data={tier_data}")
                    # Extract answer text from tier data
                    if isinstance(tier_data, dict):
                        # For RAG tier, sources is a list of documents with content
                        # For other tiers, look for answer or content field directly
                        if tier_type == "rag" and "sources" in tier_data:
                            sources = tier_data.get("sources", [])
                            if sources and isinstance(sources, list) and len(sources) > 0:
                                # Create a TierResult for each source document
                                for idx, source_doc in enumerate(sources):
                                    if isinstance(source_doc, dict):
                                        doc_content = source_doc.get("content", "")
                                        doc_title = source_doc.get("title", "Untitled Document")
                                        doc_score = source_doc.get("relevance_score", 0.0)

                                        tier_result = {
                                            "tierType": tier_type,
                                            "content": doc_content,  # Document content preview
                                            "confidence": doc_score,  # Individual document score
                                            "source": doc_title,  # Document title
                                            "foundAt": tier_data.get("timestamp", datetime.utcnow().isoformat()),
                                            "metadata": source_doc  # Full source metadata
                                        }
                                        tier_results_list.append(tier_result)
                                        logger.info(f"[to_dict] Added RAG tier_result {idx+1}/{len(sources)}: title={doc_title}, score={doc_score:.3f}, content_len={len(doc_content)}")
                        else:
                            # Non-RAG tiers or fallback: look for answer/content directly
                            content = tier_data.get("answer", tier_data.get("content", ""))
                            tier_confidence = tier_data.get("confidence", 0.85)
                            source = tier_data.get("source", tier_type)
                            timestamp = tier_data.get("timestamp", datetime.utcnow().isoformat())

                            tier_result = {
                                "tierType": tier_type,
                                "content": content,
                                "confidence": tier_confidence,
                                "source": source,
                                "foundAt": timestamp,
                                "metadata": tier_data
                            }
                            tier_results_list.append(tier_result)
                            logger.info(f"[to_dict] Added tier_result: {tier_result}")
            elif isinstance(tier_results_dict, list):
                tier_results_list = tier_results_dict
                logger.info(f"[to_dict] tier_results_dict is already a list: {tier_results_list}")

            result["tierResults"] = tier_results_list
            logger.info(f"[to_dict] Final tierResults count: {len(tier_results_list)}")
            result["answeredAt"] = None  # To be populated when answered

        # For actions: add completeness score and deadline
        elif self.insight_type == "action" or (hasattr(self.insight_type, 'value') and self.insight_type.value == "action"):
            result["completenessScore"] = metadata.get("completeness_score", 0.4)
            result["confidence"] = metadata.get("confidence", 0.8)  # Default action detection confidence
            result["owner"] = metadata.get("owner")
            result["deadline"] = metadata.get("deadline")
            result["completedAt"] = None  # To be populated when completed

        return result
