"""
Unit tests for LiveMeetingInsight model.

Tests model creation, helper methods, and business logic.
"""

import pytest
import uuid
from datetime import datetime
from models.live_insight import (
    LiveMeetingInsight,
    InsightType,
    InsightStatus,
    AnswerSource
)


def test_insight_type_enum_values():
    """Test InsightType enum has correct values."""
    assert InsightType.QUESTION.value == "question"
    assert InsightType.ACTION.value == "action"
    assert InsightType.ANSWER.value == "answer"


def test_insight_status_enum_values():
    """Test InsightStatus enum has correct values."""
    assert InsightStatus.SEARCHING.value == "searching"
    assert InsightStatus.FOUND.value == "found"
    assert InsightStatus.MONITORING.value == "monitoring"
    assert InsightStatus.ANSWERED.value == "answered"
    assert InsightStatus.UNANSWERED.value == "unanswered"
    assert InsightStatus.TRACKED.value == "tracked"
    assert InsightStatus.COMPLETE.value == "complete"


def test_answer_source_enum_values():
    """Test AnswerSource enum has correct values for four-tier system."""
    assert AnswerSource.RAG.value == "rag"
    assert AnswerSource.MEETING_CONTEXT.value == "meeting_context"
    assert AnswerSource.LIVE_CONVERSATION.value == "live_conversation"
    assert AnswerSource.GPT_GENERATED.value == "gpt_generated"
    assert AnswerSource.USER_PROVIDED.value == "user_provided"
    assert AnswerSource.UNANSWERED.value == "unanswered"


def test_create_question_insight():
    """Test creating a question insight with required fields."""
    question_id = uuid.uuid4()
    question = LiveMeetingInsight(
        id=question_id,
        session_id="session-123",
        recording_id=uuid.uuid4(),
        project_id=uuid.uuid4(),
        organization_id=uuid.uuid4(),
        insight_type=InsightType.QUESTION,
        detected_at=datetime.utcnow(),
        content="What is the budget for Q4?",
        status="searching"
    )

    assert question.id == question_id
    assert question.insight_type == InsightType.QUESTION
    assert question.content == "What is the budget for Q4?"
    assert question.status == "searching"


def test_create_action_insight():
    """Test creating an action insight."""
    action = LiveMeetingInsight(
        session_id="session-456",
        recording_id=uuid.uuid4(),
        project_id=uuid.uuid4(),
        organization_id=uuid.uuid4(),
        insight_type=InsightType.ACTION,
        detected_at=datetime.utcnow(),
        content="Update the documentation by Friday",
        status="tracked",
        insight_metadata={
            "owner": "John",
            "deadline": "2025-10-30"
        }
    )

    assert action.insight_type == InsightType.ACTION
    assert action.insight_metadata["owner"] == "John"
    assert action.insight_metadata["deadline"] == "2025-10-30"


def test_update_status_method():
    """Test update_status helper method."""
    now = datetime.utcnow()
    insight = LiveMeetingInsight(
        session_id="session-789",
        recording_id=uuid.uuid4(),
        project_id=uuid.uuid4(),
        organization_id=uuid.uuid4(),
        insight_type=InsightType.QUESTION,
        detected_at=now,
        content="Sample question?",
        status="searching",
        created_at=now,
        updated_at=now
    )

    original_updated_at = insight.updated_at

    insight.update_status("answered")

    assert insight.status == "answered"
    assert insight.updated_at >= original_updated_at


def test_add_tier_result_method():
    """Test add_tier_result method for four-tier answer discovery."""
    question = LiveMeetingInsight(
        session_id="session-abc",
        recording_id=uuid.uuid4(),
        project_id=uuid.uuid4(),
        organization_id=uuid.uuid4(),
        insight_type=InsightType.QUESTION,
        detected_at=datetime.utcnow(),
        content="What is the project timeline?",
        status="searching",
        insight_metadata={}
    )

    # Add Tier 1 (RAG) result
    question.add_tier_result("rag", {
        "documents": [
            {"title": "Project Plan.pdf", "relevance": 0.92}
        ],
        "confidence": 0.9
    })

    assert "tier_results" in question.insight_metadata
    assert "rag" in question.insight_metadata["tier_results"]
    assert question.insight_metadata["tier_results"]["rag"]["confidence"] == 0.9

    # Add Tier 2 (Meeting Context) result
    question.add_tier_result("meeting_context", {
        "quote": "Timeline is 6 months",
        "speaker": "Sarah",
        "timestamp": "2025-10-26T10:15:00Z",
        "confidence": 0.95
    })

    assert "meeting_context" in question.insight_metadata["tier_results"]

    # Add Tier 4 (GPT Generated) result
    question.add_tier_result("gpt_generated", {
        "answer": "Typical project timelines range from 3-9 months",
        "confidence": 0.75,
        "disclaimer": "AI-generated, not from documents"
    })

    assert "gpt_generated" in question.insight_metadata["tier_results"]
    assert len(question.insight_metadata["tier_results"]) == 3


def test_calculate_completeness_for_question():
    """Test calculate_completeness returns 0 for non-action insights."""
    question = LiveMeetingInsight(
        session_id="session-def",
        recording_id=uuid.uuid4(),
        project_id=uuid.uuid4(),
        organization_id=uuid.uuid4(),
        insight_type=InsightType.QUESTION,
        detected_at=datetime.utcnow(),
        content="Sample question?"
    )

    completeness = question.calculate_completeness()

    assert completeness == 0.0


def test_calculate_completeness_description_only():
    """Test completeness score of 0.4 for action with description only."""
    action = LiveMeetingInsight(
        session_id="session-ghi",
        recording_id=uuid.uuid4(),
        project_id=uuid.uuid4(),
        organization_id=uuid.uuid4(),
        insight_type=InsightType.ACTION,
        detected_at=datetime.utcnow(),
        content="Update the documentation",
        insight_metadata={}
    )

    completeness = action.calculate_completeness()

    assert completeness == 0.4
    assert action.insight_metadata["completeness_score"] == 0.4


def test_calculate_completeness_with_owner():
    """Test completeness score of 0.7 for action with description and owner."""
    action = LiveMeetingInsight(
        session_id="session-jkl",
        recording_id=uuid.uuid4(),
        project_id=uuid.uuid4(),
        organization_id=uuid.uuid4(),
        insight_type=InsightType.ACTION,
        detected_at=datetime.utcnow(),
        content="Update the documentation",
        insight_metadata={"owner": "John"}
    )

    completeness = action.calculate_completeness()

    assert completeness == 0.7


def test_calculate_completeness_with_deadline():
    """Test completeness score of 0.7 for action with description and deadline."""
    action = LiveMeetingInsight(
        session_id="session-mno",
        recording_id=uuid.uuid4(),
        project_id=uuid.uuid4(),
        organization_id=uuid.uuid4(),
        insight_type=InsightType.ACTION,
        detected_at=datetime.utcnow(),
        content="Update the documentation",
        insight_metadata={"deadline": "2025-10-30"}
    )

    completeness = action.calculate_completeness()

    assert completeness == 0.7


def test_calculate_completeness_complete_action():
    """Test completeness score of 1.0 for action with all fields."""
    action = LiveMeetingInsight(
        session_id="session-pqr",
        recording_id=uuid.uuid4(),
        project_id=uuid.uuid4(),
        organization_id=uuid.uuid4(),
        insight_type=InsightType.ACTION,
        detected_at=datetime.utcnow(),
        content="Update the documentation by Friday",
        insight_metadata={
            "owner": "Sarah",
            "deadline": "2025-10-30"
        }
    )

    completeness = action.calculate_completeness()

    assert completeness == 1.0
    assert action.insight_metadata["completeness_score"] == 1.0


def test_set_answer_source_method():
    """Test set_answer_source method for tracking answer sources."""
    question = LiveMeetingInsight(
        session_id="session-stu",
        recording_id=uuid.uuid4(),
        project_id=uuid.uuid4(),
        organization_id=uuid.uuid4(),
        insight_type=InsightType.QUESTION,
        detected_at=datetime.utcnow(),
        content="What is the project budget?",
        status="searching"
    )

    # Set answer source to RAG (Tier 1)
    question.set_answer_source("rag", confidence=0.92)

    assert question.answer_source == "rag"
    assert question.insight_metadata["confidence"] == 0.92


def test_set_answer_source_gpt_generated():
    """Test set_answer_source for GPT-generated answers (Tier 4)."""
    question = LiveMeetingInsight(
        session_id="session-vwx",
        recording_id=uuid.uuid4(),
        project_id=uuid.uuid4(),
        organization_id=uuid.uuid4(),
        insight_type=InsightType.QUESTION,
        detected_at=datetime.utcnow(),
        content="What are typical ROI timelines?",
        status="searching"
    )

    # Set answer source to GPT-generated (Tier 4)
    question.set_answer_source("gpt_generated", confidence=0.78)

    assert question.answer_source == "gpt_generated"
    assert question.insight_metadata["confidence"] == 0.78


def test_to_dict_method():
    """Test to_dict converts model to dictionary correctly."""
    recording_id = uuid.uuid4()
    project_id = uuid.uuid4()
    organization_id = uuid.uuid4()
    detected_at = datetime.utcnow()

    question = LiveMeetingInsight(
        session_id="session-yz",
        recording_id=recording_id,
        project_id=project_id,
        organization_id=organization_id,
        insight_type=InsightType.QUESTION,
        detected_at=detected_at,
        content="What is the timeline?",
        status="answered",
        answer_source="meeting_context",
        insight_metadata={"confidence": 0.95}
    )

    result = question.to_dict()

    assert result["session_id"] == "session-yz"
    assert result["recording_id"] == str(recording_id)
    assert result["project_id"] == str(project_id)
    assert result["organization_id"] == str(organization_id)
    assert result["insight_type"] == "question"
    # Flutter expects 'text' key, not 'content'
    assert result["text"] == "What is the timeline?"
    assert result["status"] == "answered"
    assert result["answer_source"] == "meeting_context"
    assert result["metadata"]["confidence"] == 0.95


# Note: Speaker field removed - streaming API doesn't support speaker diarization



def test_metadata_initialization():
    """Test insight_metadata field initializes as empty dict by default."""
    insight = LiveMeetingInsight(
        session_id="session-init",
        recording_id=uuid.uuid4(),
        project_id=uuid.uuid4(),
        organization_id=uuid.uuid4(),
        insight_type=InsightType.ACTION,
        detected_at=datetime.utcnow(),
        content="Test action"
    )

    assert insight.insight_metadata == {} or insight.insight_metadata is None
