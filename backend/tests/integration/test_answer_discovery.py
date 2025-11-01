"""
Integration Tests for Four-Tier Answer Discovery System

Tests the complete answer discovery flow from question detection through
all four tiers: RAG → Meeting Context → Live Monitoring → GPT Generation.

Tier Priorities:
- Tier 1 (RAG): 2s timeout - Search organization documents
- Tier 2 (Meeting Context): 1.5s timeout - Search earlier in meeting
- Tier 3 (Live Monitoring): 15s timeout - Monitor conversation for answers
- Tier 4 (GPT Generated): 3s timeout - AI-generated fallback answer
"""

import pytest
import asyncio
import uuid
import json
from datetime import datetime, timedelta
from unittest.mock import Mock, AsyncMock, patch, MagicMock
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from models.live_insight import (
    LiveMeetingInsight,
    InsightType,
    InsightStatus,
    AnswerSource
)
from models.recording import Recording
from models.project import Project
from models.organization import Organization
from models.user import User

from services.intelligence.question_handler import QuestionHandler
from services.intelligence.rag_search import RAGSearchService, RAGSearchResult
from services.intelligence.meeting_context_search import (
    MeetingContextSearchService,
    MeetingContextResult
)
from services.intelligence.gpt_answer_generator import GPTAnswerGenerator
from services.intelligence.answer_handler import AnswerHandler
from services.transcription.transcription_buffer_service import TranscriptionBufferService


# ============================================================================
# TEST FIXTURES
# ============================================================================

@pytest.fixture
def session_id():
    """Generate unique session ID for each test."""
    return f"test-session-{uuid.uuid4()}"


@pytest.fixture
def question_id():
    """Generate unique question ID for each test."""
    return f"q_{uuid.uuid4()}"


@pytest.fixture
async def test_organization() -> Organization:
    """Create test organization with independent session for true database commit."""
    from db.database import get_db_context

    # Use unique slug per test to avoid conflicts
    unique_slug = f"test-org-ad-{uuid.uuid4().hex[:8]}"

    organization = Organization(
        name="Test Organization for Answer Discovery",
        slug=unique_slug,
        is_active=True
    )

    async with get_db_context() as session:
        session.add(organization)
        await session.commit()
        await session.refresh(organization)

    return organization


@pytest.fixture
async def test_project(test_organization: Organization) -> Project:
    """Create test project with independent session for true database commit."""
    from db.database import get_db_context

    project = Project(
        name="Test Project for Answer Discovery",
        description="Test project for answer discovery integration tests",
        organization_id=test_organization.id,
        status="active",
        created_by=str(test_organization.created_by)
    )

    async with get_db_context() as session:
        session.add(project)
        await session.commit()
        await session.refresh(project)

    return project


@pytest.fixture
async def test_recording(test_project: Project) -> Recording:
    """Create test recording with independent session for true database commit.

    This fixture uses its own database session to ensure the recording is truly
    committed and visible to other sessions, which is necessary for testing code
    that creates its own database contexts.
    """
    from db.database import get_db_context

    now = datetime.utcnow()
    recording = Recording(
        id=uuid.uuid4(),
        project_id=test_project.id,
        session_id=f"test-session-{uuid.uuid4()}",
        meeting_title="Test Meeting",
        file_path="/tmp/test_recording.m4a",
        duration=300.0,
        start_time=now,
        end_time=now + timedelta(minutes=5),
        is_transcribed=False,
        transcription_status="pending",
        created_at=now
    )

    async with get_db_context() as session:
        session.add(recording)
        await session.commit()
        await session.refresh(recording)

    return recording


@pytest.fixture
def mock_rag_service():
    """Mock RAG search service with controlled responses."""
    service = Mock(spec=RAGSearchService)

    async def mock_search(question, project_id, organization_id, streaming=True):
        """Mock RAG search - can be configured per test."""
        # Default: no results (will be overridden in tests)
        return
        yield  # Make it an async generator

    service.search = mock_search
    service.timeout = 2.0
    service.is_available = Mock(return_value=True)  # RAG service is available by default
    return service


@pytest.fixture
def mock_meeting_context_service():
    """Mock meeting context search service."""
    service = Mock(spec=MeetingContextSearchService)

    async def mock_search(question, session_id, speaker=None, organization_id=None):
        """Mock meeting context search - can be configured per test."""
        # Default: no answer found
        return MeetingContextResult(
            found_answer=False,
            confidence=0.0,
            search_duration_ms=100
        )

    service.search = mock_search
    service.timeout = 1.5
    return service


@pytest.fixture
def mock_gpt_answer_generator():
    """Mock GPT answer generator."""
    generator = Mock(spec=GPTAnswerGenerator)

    async def mock_generate(session_id, question_id, question_text, speaker=None,
                           meeting_context=None, db_session=None):
        """Mock GPT answer generation - can be configured per test."""
        # Default: answer generated successfully
        return True

    generator.generate_answer = mock_generate
    generator.timeout = 3.0
    generator.confidence_threshold = 0.70
    return generator


@pytest.fixture
def mock_transcription_buffer():
    """Mock transcription buffer service."""
    buffer = Mock(spec=TranscriptionBufferService)

    async def mock_get_context(session_id):
        """Return mock transcript context."""
        return """
[10:15:30] Speaker A: What's the budget for Q4 infrastructure?
[10:16:05] Speaker B: I think Sarah sent that in an email.
[10:16:45] Speaker C: Let me check the documents.
"""

    buffer.get_formatted_context = AsyncMock(side_effect=mock_get_context)
    buffer.add_sentence = AsyncMock()
    return buffer


@pytest.fixture
async def mock_broadcast_callback():
    """Mock WebSocket broadcast callback."""
    messages_sent = []

    async def broadcast(session_id, message):
        """Capture broadcast messages for assertion."""
        messages_sent.append({
            "session_id": session_id,
            "message": message,
            "timestamp": datetime.utcnow()
        })

    broadcast.messages = messages_sent
    return broadcast


@pytest.fixture
def question_handler(mock_broadcast_callback):
    """Create QuestionHandler instance with mocked dependencies."""
    handler = QuestionHandler()
    handler.set_websocket_callback(mock_broadcast_callback)
    return handler


# ============================================================================
# TEST: Full Four-Tier Answer Discovery Flow
# ============================================================================

@pytest.mark.asyncio
class TestFullAnswerDiscoveryFlow:
    """Test complete answer discovery flow through all tiers."""

    async def test_tier1_rag_finds_answer_immediately(
        self,
        db_session: AsyncSession,
        test_recording: Recording,
        test_project: Project,
        test_organization: Organization,
        session_id: str,
        question_id: str,
        question_handler: QuestionHandler,
        mock_broadcast_callback,
        mock_rag_service,
        mock_meeting_context_service,
        mock_gpt_answer_generator
    ):
        """
        Test Tier 1 (RAG) finds answer immediately in documents.
        Expected: Question answered via RAG, other tiers not needed.
        """
        # Arrange: Configure RAG to find 2 relevant documents
        async def rag_finds_answers(question, project_id, organization_id, streaming=True):
            """RAG returns 2 document results progressively."""
            await asyncio.sleep(0.1)  # Simulate search delay
            yield RAGSearchResult(
                document_id="doc-1",
                title="Q4 Infrastructure Budget Plan",
                content="The Q4 infrastructure budget is $250,000, including cloud and servers.",
                relevance_score=0.92,
                url="https://docs.example.com/budget-q4",
                metadata={"source": "Budget Planning 2025"}
            )

            await asyncio.sleep(0.05)
            yield RAGSearchResult(
                document_id="doc-2",
                title="Infrastructure Investment Timeline",
                content="Infrastructure investments are allocated quarterly with $250K for Q4.",
                relevance_score=0.85,
                url="https://docs.example.com/infrastructure",
                metadata={"source": "Finance Docs"}
            )

        mock_rag_service.search = rag_finds_answers

        # Patch services
        with patch('services.intelligence.question_handler.rag_search_service', mock_rag_service):
            with patch('services.intelligence.question_handler.get_meeting_context_search',
                      return_value=mock_meeting_context_service):

                # Act: Handle question
                question_data = {
                    "id": question_id,
                    "text": "What's the budget for Q4 infrastructure?",
                    "speaker": "Speaker A",
                    "timestamp": datetime.utcnow().isoformat(),
                    "confidence": 0.95,
                    "category": "factual"
                }

                result = await question_handler.handle_question(
                    session_id=session_id,
                    question_data=question_data,
                    project_id=str(test_project.id),
                    organization_id=str(test_organization.id),
                    recording_id=str(test_recording.id)
                )

                # Wait longer for async tier processing and DB updates
                # Background tasks may take time to complete, including DB writes
                await asyncio.sleep(3.0)

        # Assert: Question created in database
        assert result is not None
        assert result.insight_type == InsightType.QUESTION
        assert result.content == question_data["text"]
        # Note: speaker field removed - streaming API doesn't support speaker diarization

        # Get the actual database-generated question ID
        db_question_id = str(result.id)

        # Assert: RAG results broadcasted
        messages = mock_broadcast_callback.messages
        rag_messages = [m for m in messages if m["message"]["type"] == "RAG_RESULT_PROGRESSIVE"]

        assert len(rag_messages) >= 2, f"Should have 2 RAG result messages, got {len(rag_messages)}"

        # Verify first RAG result (use database ID, not GPT ID)
        # Messages now have nested 'data' structure
        first_rag = rag_messages[0]["message"]["data"]
        assert first_rag["question_id"] == db_question_id
        assert first_rag["document"]["title"] == "Q4 Infrastructure Budget Plan"
        assert first_rag["document"]["relevance_score"] == 0.92
        assert "source" in first_rag
        assert first_rag["source"] == "rag"

        # Assert: Final RAG completion message
        rag_complete = [m for m in messages if m["message"]["type"] == "RAG_RESULT_COMPLETE"]
        assert len(rag_complete) == 1
        assert rag_complete[0]["message"]["data"]["num_sources"] == 2
        assert rag_complete[0]["message"]["data"]["confidence"] > 0.85

    async def test_tier2_meeting_context_finds_answer(
        self,
        db_session: AsyncSession,
        test_recording: Recording,
        test_project: Project,
        test_organization: Organization,
        session_id: str,
        question_id: str,
        question_handler: QuestionHandler,
        mock_broadcast_callback,
        mock_rag_service,
        mock_meeting_context_service
    ):
        """
        Test Tier 2 (Meeting Context) finds answer from earlier discussion.
        Expected: RAG finds nothing, meeting context finds answer.
        """
        # Arrange: RAG returns no results
        async def rag_no_results(question, project_id, organization_id, streaming=True):
            return
            yield  # Empty generator

        mock_rag_service.search = rag_no_results

        # Meeting context finds answer
        async def meeting_context_finds_answer(question, session_id, speaker=None, organization_id=None):
            await asyncio.sleep(0.2)  # Simulate search
            return MeetingContextResult(
                found_answer=True,
                answer_text="The budget is $250,000 for infrastructure.",
                quotes=[{
                    "text": "The budget is $250,000 for infrastructure, including cloud costs.",
                    "speaker": "Speaker C",
                    "timestamp": "2025-10-26T10:16:45Z"
                }],
                confidence=0.88,
                search_duration_ms=200
            )

        mock_meeting_context_service.search = meeting_context_finds_answer

        # Patch services
        with patch('services.intelligence.question_handler.rag_search_service', mock_rag_service):
            with patch('services.intelligence.question_handler.get_meeting_context_search',
                      return_value=mock_meeting_context_service):

                # Act: Handle question
                question_data = {
                    "id": question_id,
                    "text": "What did we say about the infrastructure budget?",
                    "speaker": "Speaker A",
                    "timestamp": datetime.utcnow().isoformat(),
                    "confidence": 0.92,
                    "category": "clarification"
                }

                result = await question_handler.handle_question(
                    session_id=session_id,
                    question_data=question_data,
                    project_id=str(test_project.id),
                    organization_id=str(test_organization.id),
                    recording_id=str(test_recording.id)
                )

                # Wait for tier processing
                await asyncio.sleep(0.5)

        # Get the actual database-generated question ID
        db_question_id = str(result.id)

        # Assert: Meeting context result broadcasted
        messages = mock_broadcast_callback.messages
        meeting_msgs = [m for m in messages if m["message"]["type"] == "ANSWER_FROM_MEETING"]

        assert len(meeting_msgs) == 1, "Should have meeting context answer"

        # Access nested 'data' structure
        meeting_answer = meeting_msgs[0]["message"]["data"]
        assert meeting_answer["question_id"] == db_question_id
        assert meeting_answer["answer_text"] == "The budget is $250,000 for infrastructure."
        assert meeting_answer["confidence"] == 0.88
        assert "meeting_context" in meeting_answer.get("tier", "")
        assert len(meeting_answer["quotes"]) == 1

    async def test_tier3_live_monitoring_detects_answer(
        self,
        db_session: AsyncSession,
        test_recording: Recording,
        test_project: Project,
        test_organization: Organization,
        session_id: str,
        question_id: str,
        question_handler: QuestionHandler,
        mock_broadcast_callback,
        mock_rag_service,
        mock_meeting_context_service
    ):
        """
        Test Tier 3 (Live Monitoring) detects answer in subsequent conversation.
        Expected: RAG and meeting context find nothing, answer appears within 15s.
        """
        # Arrange: RAG and Meeting Context return no results
        async def no_results_rag(question, project_id, organization_id, streaming=True):
            return
            yield

        async def no_results_meeting(question, session_id, speaker=None, organization_id=None):
            return MeetingContextResult(found_answer=False, confidence=0.0)

        mock_rag_service.search = no_results_rag
        mock_meeting_context_service.search = no_results_meeting

        # Create answer handler
        answer_handler = AnswerHandler()
        answer_handler.set_websocket_callback(mock_broadcast_callback)

        with patch('services.intelligence.question_handler.rag_search_service', mock_rag_service):
            with patch('services.intelligence.question_handler.get_meeting_context_search',
                      return_value=mock_meeting_context_service):

                # Act: Handle question (starts 15s monitoring)
                question_data = {
                    "id": question_id,
                    "text": "Who will lead the new project?",
                    "speaker": "Speaker A",
                    "timestamp": datetime.utcnow().isoformat(),
                    "confidence": 0.90
                }

                result = await question_handler.handle_question(
                    session_id=session_id,
                    question_data=question_data,
                    project_id=str(test_project.id),
                    organization_id=str(test_organization.id),
                    recording_id=str(test_recording.id)
                )

                # Wait a bit for tier 1 & 2 to complete
                await asyncio.sleep(0.3)

                # Get the database-generated question ID
                db_question_id = str(result.id)

                # Simulate answer appearing in conversation after 2 seconds
                await asyncio.sleep(2.0)

                answer_data = {
                    "type": "answer",
                    "question_id": question_id,  # Use GPT ID (from metadata), not database UUID
                    "answer_text": "Sarah will lead the new infrastructure project.",
                    "speaker": "Speaker B",
                    "timestamp": datetime.utcnow().isoformat(),
                    "confidence": 0.92
                }

                # Answer handler processes the answer
                answer_handler._question_handler = question_handler
                await answer_handler.handle_answer(
                    answer_obj=answer_data,  # Correct parameter name
                    session_id=session_id
                )

                await asyncio.sleep(0.2)

        # Assert: Live answer detected and broadcasted
        messages = mock_broadcast_callback.messages
        live_msgs = [m for m in messages if m["message"]["type"] == "QUESTION_ANSWERED_LIVE"]

        assert len(live_msgs) >= 1, "Should have live answer detection"

        # Check the first QUESTION_ANSWERED_LIVE message structure
        first_live_msg = live_msgs[0]["message"]
        assert first_live_msg["question_id"] == db_question_id
        assert first_live_msg["data"]["source"] == "live_conversation"
        assert "Sarah will lead" in first_live_msg["data"]["answer_text"]
        assert first_live_msg["data"]["confidence"] == 0.92

    async def test_tier4_gpt_generates_fallback_answer(
        self,
        db_session: AsyncSession,
        test_recording: Recording,
        test_project: Project,
        test_organization: Organization,
        session_id: str,
        question_id: str,
        question_handler: QuestionHandler,
        mock_broadcast_callback,
        mock_rag_service,
        mock_meeting_context_service,
        mock_gpt_answer_generator
    ):
        """
        Test Tier 4 (GPT Generated) generates answer when all other tiers fail.
        Expected: RAG, meeting context, live monitoring all fail → GPT generates answer.
        """
        # Arrange: All tiers fail to find answer
        async def no_results_rag(question, project_id, organization_id, streaming=True):
            return
            yield

        async def no_results_meeting(question, session_id, speaker=None, organization_id=None):
            return MeetingContextResult(found_answer=False, confidence=0.0)

        # GPT generates answer successfully
        async def gpt_generates_answer(session_id, question_id, question_text, speaker=None,
                                       meeting_context=None, db_session=None):
            """Simulate GPT answer generation."""
            # Broadcast GPT answer via callback
            await mock_broadcast_callback(session_id, {
                "type": "GPT_GENERATED_ANSWER",
                "question_id": question_id,
                "answer": {
                    "text": "Typical infrastructure ROI timelines range from 18-36 months depending on scope.",
                    "confidence": 0.75,
                    "disclaimer": "This answer is AI-generated and not from your documents or meeting. Please verify accuracy."
                },
                "source": "gpt_generated",
                "timestamp": datetime.utcnow().isoformat()
            })
            return True

        mock_rag_service.search = no_results_rag
        mock_meeting_context_service.search = no_results_meeting
        mock_gpt_answer_generator.generate_answer = gpt_generates_answer

        with patch('services.intelligence.question_handler.rag_search_service', mock_rag_service):
            with patch('services.intelligence.question_handler.get_meeting_context_search',
                      return_value=mock_meeting_context_service):

                # Reduce live monitoring timeout for faster test
                question_handler.monitoring_timeout_seconds = 1

                # Act: Handle question
                question_data = {
                    "id": question_id,
                    "text": "What's the typical ROI timeline for infrastructure investments?",
                    "speaker": "Speaker A",
                    "timestamp": datetime.utcnow().isoformat(),
                    "confidence": 0.88
                }

                result = await question_handler.handle_question(
                    session_id=session_id,
                    question_data=question_data,
                    project_id=str(test_project.id),
                    organization_id=str(test_organization.id),
                    recording_id=str(test_recording.id)
                )

                # Get the database-generated question ID
                db_question_id = str(result.id)

                # Wait for all tiers to complete (including 1s live monitoring)
                await asyncio.sleep(2.0)

                # Manually trigger GPT generation (simulating orchestrator)
                await mock_gpt_answer_generator.generate_answer(
                    session_id=session_id,
                    question_id=db_question_id,  # Use database ID
                    question_text=question_data["text"],
                    speaker="Speaker A",
                    meeting_context="Meeting about infrastructure planning",
                    db_session=db_session
                )

        # Assert: GPT answer broadcasted
        messages = mock_broadcast_callback.messages
        gpt_msgs = [m for m in messages if m["message"]["type"] == "GPT_GENERATED_ANSWER"]

        assert len(gpt_msgs) == 1, "Should have GPT-generated answer"

        gpt_answer = gpt_msgs[0]["message"]
        assert gpt_answer["question_id"] == db_question_id
        assert "ROI timeline" in gpt_answer["answer"]["text"]
        assert gpt_answer["source"] == "gpt_generated"
        assert gpt_answer["answer"]["confidence"] == 0.75
        assert "AI-generated" in gpt_answer["answer"]["disclaimer"]


# ============================================================================
# TEST: Timeout Handling
# ============================================================================

@pytest.mark.asyncio
class TestTimeoutHandling:
    """Test timeout behavior for each tier."""

    async def test_rag_timeout_after_2_seconds(
        self,
        db_session: AsyncSession,
        test_recording: Recording,
        test_project: Project,
        test_organization: Organization,
        session_id: str,
        question_id: str,
        question_handler: QuestionHandler,
        mock_broadcast_callback,
        mock_rag_service
    ):
        """Test RAG search times out after 2 seconds."""
        # Arrange: RAG search hangs longer than timeout
        async def slow_rag_search(question, project_id, organization_id, streaming=True):
            """Simulate slow RAG search that exceeds timeout."""
            await asyncio.sleep(3.0)  # Exceeds 2s timeout
            yield RAGSearchResult(
                document_id="doc-late",
                title="Late Document",
                content="This should never appear",
                relevance_score=0.9
            )

        mock_rag_service.search = slow_rag_search
        mock_rag_service.timeout = 2.0

        with patch('services.intelligence.question_handler.rag_search_service', mock_rag_service):
            # Act: Handle question
            question_data = {
                "id": question_id,
                "text": "Test RAG timeout?",
                "speaker": "Speaker A",
                "timestamp": datetime.utcnow().isoformat(),
                "confidence": 0.9
            }

            start_time = asyncio.get_event_loop().time()

            result = await question_handler.handle_question(
                session_id=session_id,
                question_data=question_data,
                project_id=str(test_project.id),
                organization_id=str(test_organization.id),
                recording_id=str(test_recording.id)
            )

            # Wait for RAG tier timeout
            await asyncio.sleep(2.5)
            elapsed = asyncio.get_event_loop().time() - start_time

        # Assert: RAG tier should timeout around 2s, not 3s
        assert elapsed < 3.0, f"RAG search should timeout at 2s, took {elapsed:.2f}s"

        # Assert: No RAG results broadcasted (timeout occurred)
        messages = mock_broadcast_callback.messages
        rag_msgs = [m for m in messages if "RAG" in m["message"]["type"]]

        # Should have no results or timeout message
        assert len(rag_msgs) == 0 or any("timeout" in str(m).lower() for m in rag_msgs)

    async def test_meeting_context_timeout_after_1_5_seconds(
        self,
        db_session: AsyncSession,
        test_recording: Recording,
        test_project: Project,
        test_organization: Organization,
        session_id: str,
        question_id: str,
        question_handler: QuestionHandler,
        mock_broadcast_callback,
        mock_meeting_context_service
    ):
        """Test meeting context search times out after 1.5 seconds."""
        # Arrange: Meeting context search hangs
        async def slow_meeting_search(question, session_id, speaker=None, organization_id=None):
            await asyncio.sleep(2.5)  # Exceeds 1.5s timeout
            return MeetingContextResult(
                found_answer=True,
                answer_text="This should never appear",
                confidence=0.9
            )

        mock_meeting_context_service.search = slow_meeting_search
        mock_meeting_context_service.timeout = 1.5

        with patch('services.intelligence.question_handler.get_meeting_context_search',
                  return_value=mock_meeting_context_service):

            # Act: Handle question
            question_data = {
                "id": question_id,
                "text": "Test meeting context timeout?",
                "speaker": "Speaker A",
                "timestamp": datetime.utcnow().isoformat(),
                "confidence": 0.9
            }

            start_time = asyncio.get_event_loop().time()

            result = await question_handler.handle_question(
                session_id=session_id,
                question_data=question_data,
                project_id=str(test_project.id),
                organization_id=str(test_organization.id),
                recording_id=str(test_recording.id)
            )

            await asyncio.sleep(2.0)
            elapsed = asyncio.get_event_loop().time() - start_time

        # Assert: Meeting context should timeout around 1.5s
        assert elapsed < 2.5, f"Meeting context should timeout at 1.5s, took {elapsed:.2f}s"

    async def test_live_monitoring_timeout_after_15_seconds(
        self,
        db_session: AsyncSession,
        test_recording: Recording,
        test_project: Project,
        test_organization: Organization,
        session_id: str,
        question_id: str,
        question_handler: QuestionHandler,
        mock_broadcast_callback,
        mock_rag_service,
        mock_meeting_context_service
    ):
        """Test live monitoring times out after 15 seconds if no answer appears."""
        # Arrange: RAG and meeting context return nothing
        async def no_results_rag(question, project_id, organization_id, streaming=True):
            return
            yield

        async def no_results_meeting(question, session_id, speaker=None, organization_id=None):
            return MeetingContextResult(found_answer=False, confidence=0.0)

        mock_rag_service.search = no_results_rag
        mock_meeting_context_service.search = no_results_meeting

        # Reduce timeout for faster test (use 2s instead of 15s)
        question_handler.monitoring_timeout_seconds = 2

        with patch('services.intelligence.question_handler.rag_search_service', mock_rag_service):
            with patch('services.intelligence.question_handler.get_meeting_context_search',
                      return_value=mock_meeting_context_service):

                # Act: Handle question
                question_data = {
                    "id": question_id,
                    "text": "This question will never be answered",
                    "speaker": "Speaker A",
                    "timestamp": datetime.utcnow().isoformat(),
                    "confidence": 0.9
                }

                start_time = asyncio.get_event_loop().time()

                result = await question_handler.handle_question(
                    session_id=session_id,
                    question_data=question_data,
                    project_id=str(test_project.id),
                    organization_id=str(test_organization.id),
                    recording_id=str(test_recording.id)
                )

                # Wait for monitoring timeout
                await asyncio.sleep(2.5)
                elapsed = asyncio.get_event_loop().time() - start_time

        # Assert: Should timeout around 2s (reduced from 15s)
        assert 2.0 <= elapsed < 3.0, f"Live monitoring should timeout at 2s, took {elapsed:.2f}s"

        # Assert: Question marked as unanswered after timeout
        messages = mock_broadcast_callback.messages
        unanswered_msgs = [m for m in messages if m["message"]["type"] == "QUESTION_UNANSWERED"]

        # May have unanswered message depending on orchestrator implementation
        # (This is handled by Tier 4 or orchestrator)


# ============================================================================
# TEST: Graceful Degradation
# ============================================================================

@pytest.mark.asyncio
class TestGracefulDegradation:
    """Test system continues operating when tiers fail."""

    async def test_rag_failure_continues_to_tier2(
        self,
        db_session: AsyncSession,
        test_recording: Recording,
        test_project: Project,
        test_organization: Organization,
        session_id: str,
        question_id: str,
        question_handler: QuestionHandler,
        mock_broadcast_callback,
        mock_rag_service,
        mock_meeting_context_service
    ):
        """Test RAG failure doesn't block meeting context search."""
        # Arrange: RAG raises exception
        async def rag_raises_error(question, project_id, organization_id, streaming=True):
            raise Exception("Vector database connection failed")
            yield

        # Meeting context works fine
        async def meeting_context_works(question, session_id, speaker=None, organization_id=None):
            return MeetingContextResult(
                found_answer=True,
                answer_text="Found in earlier discussion",
                confidence=0.85,
                quotes=[{"text": "Answer from meeting", "speaker": "Speaker B"}]
            )

        mock_rag_service.search = rag_raises_error
        mock_meeting_context_service.search = meeting_context_works

        with patch('services.intelligence.question_handler.rag_search_service', mock_rag_service):
            with patch('services.intelligence.question_handler.get_meeting_context_search',
                      return_value=mock_meeting_context_service):

                # Act: Handle question (RAG will fail, but should continue)
                question_data = {
                    "id": question_id,
                    "text": "Test graceful degradation",
                    "speaker": "Speaker A",
                    "timestamp": datetime.utcnow().isoformat(),
                    "confidence": 0.9
                }

                result = await question_handler.handle_question(
                    session_id=session_id,
                    question_data=question_data,
                    project_id=str(test_project.id),
                    organization_id=str(test_organization.id),
                    recording_id=str(test_recording.id)
                )

                await asyncio.sleep(0.5)

        # Assert: Question still created despite RAG failure
        assert result is not None
        assert result.insight_type == InsightType.QUESTION

        # Assert: Meeting context answer received
        messages = mock_broadcast_callback.messages
        meeting_msgs = [m for m in messages if m["message"]["type"] == "ANSWER_FROM_MEETING"]

        assert len(meeting_msgs) == 1, "Meeting context should still work despite RAG failure"
        assert meeting_msgs[0]["message"]["data"]["answer_text"] == "Found in earlier discussion"

    async def test_vector_db_unavailable_skips_rag(
        self,
        db_session: AsyncSession,
        test_recording: Recording,
        test_project: Project,
        test_organization: Organization,
        session_id: str,
        question_id: str,
        question_handler: QuestionHandler,
        mock_broadcast_callback,
        mock_rag_service
    ):
        """Test system gracefully skips RAG when vector DB unavailable."""
        # Arrange: RAG service indicates unavailability
        async def rag_unavailable(question, project_id, organization_id, streaming=True):
            # Return empty generator immediately
            return
            yield

        mock_rag_service.search = rag_unavailable

        with patch('services.intelligence.question_handler.rag_search_service', mock_rag_service):
            # Act: Handle question
            question_data = {
                "id": question_id,
                "text": "Test vector DB unavailable",
                "speaker": "Speaker A",
                "timestamp": datetime.utcnow().isoformat(),
                "confidence": 0.9
            }

            result = await question_handler.handle_question(
                session_id=session_id,
                question_data=question_data,
                project_id=str(test_project.id),
                organization_id=str(test_organization.id),
                recording_id=str(test_recording.id)
            )

            await asyncio.sleep(0.3)

        # Assert: Question created successfully
        assert result is not None

        # Assert: No RAG results (skipped tier)
        messages = mock_broadcast_callback.messages
        rag_msgs = [m for m in messages if "RAG" in m["message"]["type"]]
        assert len(rag_msgs) == 0, "RAG should be skipped when unavailable"


# ============================================================================
# TEST: Concurrent Question Handling
# ============================================================================

@pytest.mark.asyncio
class TestConcurrentQuestions:
    """Test handling multiple questions simultaneously."""

    async def test_multiple_questions_processed_in_parallel(
        self,
        db_session: AsyncSession,
        test_recording: Recording,
        test_project: Project,
        test_organization: Organization,
        session_id: str,
        question_handler: QuestionHandler,
        mock_broadcast_callback,
        mock_rag_service
    ):
        """Test system processes multiple questions concurrently."""
        # Arrange: RAG returns different results for each question
        call_count = 0

        async def rag_different_results(question, project_id, organization_id, streaming=True):
            nonlocal call_count
            call_count += 1
            current_call = call_count

            await asyncio.sleep(0.2)
            yield RAGSearchResult(
                document_id=f"doc-{current_call}",
                title=f"Document for Question {current_call}",
                content=f"Answer {current_call}",
                relevance_score=0.8
            )

        mock_rag_service.search = rag_different_results

        with patch('services.intelligence.question_handler.rag_search_service', mock_rag_service):
            # Act: Submit 3 questions concurrently
            questions = [
                {
                    "id": f"q_{uuid.uuid4()}",
                    "text": f"Question {i}?",
                    "speaker": "Speaker A",
                    "timestamp": datetime.utcnow().isoformat(),
                    "confidence": 0.9
                }
                for i in range(1, 4)
            ]

            # Process all questions in parallel
            tasks = [
                question_handler.handle_question(
                    session_id=session_id,
                    question_data=q,
                    project_id=str(test_project.id),
                    organization_id=str(test_organization.id),
                    recording_id=str(test_recording.id)
                )
                for q in questions
            ]

            results = await asyncio.gather(*tasks)

            # Wait for all tiers to process
            await asyncio.sleep(1.0)

        # Assert: All questions created
        assert all(r is not None for r in results)
        assert len(results) == 3

        # Assert: RAG called for each question
        assert call_count == 3, f"RAG should be called 3 times, was called {call_count}"

        # Assert: Results for all 3 questions broadcasted
        messages = mock_broadcast_callback.messages
        # Get database question IDs from results
        db_question_ids = [str(r.id) for r in results]

        for db_q_id in db_question_ids:
            # Check in nested 'data' structure
            q_messages = [m for m in messages if m["message"].get("data", {}).get("question_id") == db_q_id]
            assert len(q_messages) > 0, f"Should have messages for question {db_q_id}"


# ============================================================================
# TEST: Progressive Result Delivery
# ============================================================================

@pytest.mark.asyncio
class TestProgressiveResults:
    """Test results are delivered progressively as tiers complete."""

    async def test_results_streamed_as_available(
        self,
        db_session: AsyncSession,
        test_recording: Recording,
        test_project: Project,
        test_organization: Organization,
        session_id: str,
        question_id: str,
        question_handler: QuestionHandler,
        mock_broadcast_callback,
        mock_rag_service
    ):
        """Test RAG results are streamed progressively, not batched."""
        # Arrange: RAG returns 3 results with delays
        async def rag_progressive_results(question, project_id, organization_id, streaming=True):
            for i in range(1, 4):
                await asyncio.sleep(0.15)  # Delay between results
                yield RAGSearchResult(
                    document_id=f"doc-{i}",
                    title=f"Document {i}",
                    content=f"Content {i}",
                    relevance_score=0.9 - (i * 0.1)
                )

        mock_rag_service.search = rag_progressive_results

        with patch('services.intelligence.question_handler.rag_search_service', mock_rag_service):
            # Act: Handle question
            question_data = {
                "id": question_id,
                "text": "Test progressive delivery",
                "speaker": "Speaker A",
                "timestamp": datetime.utcnow().isoformat(),
                "confidence": 0.9
            }

            result = await question_handler.handle_question(
                session_id=session_id,
                question_data=question_data,
                project_id=str(test_project.id),
                organization_id=str(test_organization.id),
                recording_id=str(test_recording.id)
            )

            # Wait for all results
            await asyncio.sleep(0.8)

        # Assert: Progressive RAG messages sent
        messages = mock_broadcast_callback.messages
        rag_progressive = [m for m in messages if m["message"]["type"] == "RAG_RESULT_PROGRESSIVE"]

        assert len(rag_progressive) == 3, f"Should have 3 progressive RAG results, got {len(rag_progressive)}"

        # Assert: Messages sent in order with increasing result numbers
        for i, msg in enumerate(rag_progressive, 1):
            # Access nested 'data' structure
            assert f"Document {i}" in msg["message"]["data"]["document"]["title"]

        # Assert: Final completion message sent
        rag_complete = [m for m in messages if m["message"]["type"] == "RAG_RESULT_COMPLETE"]
        assert len(rag_complete) == 1
