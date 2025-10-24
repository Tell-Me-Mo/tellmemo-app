"""
Integration Tests for Proactive Features Validation

This test suite validates that all proactive assistance features are working:
1. Auto-Answer - Questions are detected and answered automatically
2. Follow-Up Suggestions - Related topics are suggested based on context
3. Repetition Detection - Circular discussions are identified
4. Conflict Resolution - Conflicts with past decisions show resolution suggestions

Author: Claude Code AI Assistant
Date: October 2025
Issue: #4 - Missing Proactive Features
"""

import pytest
import uuid
from datetime import datetime, timezone, timedelta
from sqlalchemy.ext.asyncio import AsyncSession

from services.intelligence.realtime_meeting_insights import (
    RealtimeMeetingInsightsService,
    TranscriptChunk,
    ProcessingStatus
)
from services.llm.multi_llm_client import get_multi_llm_client
from db.multi_tenant_vector_store import multi_tenant_vector_store
from config import get_settings


@pytest.mark.asyncio
class TestAutoAnswerFeature:
    """Test suite for auto-answer functionality"""

    async def test_auto_answer_generates_answer_for_direct_question(self, db: AsyncSession):
        """
        Test that direct questions trigger auto-answer with high confidence.

        Given: A project with past meeting content about GraphQL
        When: User asks "What did we decide about GraphQL?"
        Then: Auto-answer should be generated with confidence >= 0.6
        """
        service = RealtimeMeetingInsightsService()
        settings = get_settings()

        # Setup test data
        session_id = f"test_session_{uuid.uuid4()}"
        project_id = str(uuid.uuid4())
        org_id = str(uuid.uuid4())

        # Seed knowledge base with past decision about GraphQL
        await self._seed_past_decision(
            project_id=project_id,
            org_id=org_id,
            content="We decided to use GraphQL for our API because it provides better flexibility"
        )

        # Create chunk with direct question
        chunk = TranscriptChunk(
            chunk_id=str(uuid.uuid4()),
            text="What did we decide about GraphQL?",
            timestamp=datetime.now(timezone.utc),
            index=1,
            speaker="Alice"
        )

        # Process chunk
        result = await service.process_transcript_chunk(
            session_id=session_id,
            project_id=project_id,
            organization_id=org_id,
            chunk=chunk,
            db=db
        )

        # Assertions
        assert result.overall_status == ProcessingStatus.OK
        assert 'question_answering' in result.phase_status

        # Check for auto-answer in proactive assistance
        auto_answers = [
            p for p in result.proactive_assistance
            if p['type'] == 'auto_answer'
        ]

        assert len(auto_answers) > 0, "Auto-answer should be generated for direct question"

        auto_answer = auto_answers[0]
        assert auto_answer['confidence'] >= 0.6, f"Confidence {auto_answer['confidence']} should be >= 0.6"
        assert 'graphql' in auto_answer['answer'].lower()
        assert len(auto_answer['sources']) > 0, "Should have at least one source"

    async def test_auto_answer_skipped_for_non_questions(self, db: AsyncSession):
        """
        Test that auto-answer phase is skipped for non-questions.

        Given: A chunk with no question markers
        When: Processing a statement like "We should use GraphQL"
        Then: question_answering phase should be skipped
        """
        service = RealtimeMeetingInsightsService()

        session_id = f"test_session_{uuid.uuid4()}"
        project_id = str(uuid.uuid4())
        org_id = str(uuid.uuid4())

        chunk = TranscriptChunk(
            chunk_id=str(uuid.uuid4()),
            text="We should use GraphQL for our API.",
            timestamp=datetime.now(timezone.utc),
            index=1,
            speaker="Bob"
        )

        result = await service.process_transcript_chunk(
            session_id=session_id,
            project_id=project_id,
            organization_id=org_id,
            chunk=chunk,
            db=db
        )

        # Check that question_answering was skipped
        from services.intelligence.realtime_meeting_insights import PhaseStatus
        assert result.phase_status.get('question_answering') == PhaseStatus.SKIPPED

    async def _seed_past_decision(self, project_id: str, org_id: str, content: str):
        """Helper to seed knowledge base with past decision"""
        from services.rag.embedding_service import embedding_service

        content_id = str(uuid.uuid4())
        embedding = await embedding_service.generate_embedding(content)

        await multi_tenant_vector_store.upsert_vector(
            organization_id=org_id,
            content_id=content_id,
            vector=embedding,
            collection_type="content",
            metadata={
                "project_id": project_id,
                "title": "GraphQL Decision",
                "text": content,
                "content_type": "transcript",
                "created_at": datetime.now(timezone.utc).isoformat()
            }
        )


@pytest.mark.asyncio
class TestFollowUpSuggestions:
    """Test suite for follow-up suggestion functionality"""

    async def test_follow_up_suggestions_for_decisions(self, db: AsyncSession):
        """
        Test that follow-up suggestions are generated for decisions.

        Given: A project with open action items related to authentication
        When: Team makes a decision about authentication
        Then: Follow-up suggestions should be generated with confidence >= 0.55
        """
        service = RealtimeMeetingInsightsService()

        session_id = f"test_session_{uuid.uuid4()}"
        project_id = str(uuid.uuid4())
        org_id = str(uuid.uuid4())

        # Seed with open action item
        await self._seed_open_item(
            project_id=project_id,
            org_id=org_id,
            content="TODO: Implement JWT refresh token logic (assigned to Dev Team)"
        )

        # Create chunk with decision about authentication
        chunk = TranscriptChunk(
            chunk_id=str(uuid.uuid4()),
            text="We decided to use JWT tokens for authentication.",
            timestamp=datetime.now(timezone.utc),
            index=1,
            speaker="Charlie"
        )

        result = await service.process_transcript_chunk(
            session_id=session_id,
            project_id=project_id,
            organization_id=org_id,
            chunk=chunk,
            db=db
        )

        # Check for follow-up suggestions
        follow_ups = [
            p for p in result.proactive_assistance
            if p['type'] == 'follow_up_suggestion'
        ]

        assert len(follow_ups) > 0, "Follow-up suggestions should be generated"

        follow_up = follow_ups[0]
        assert follow_up['confidence'] >= 0.55
        assert 'urgency' in follow_up
        assert follow_up['urgency'] in ['high', 'medium', 'low']

    async def _seed_open_item(self, project_id: str, org_id: str, content: str):
        """Helper to seed knowledge base with open action item"""
        from services.rag.embedding_service import embedding_service

        content_id = str(uuid.uuid4())
        embedding = await embedding_service.generate_embedding(content)

        await multi_tenant_vector_store.upsert_vector(
            organization_id=org_id,
            content_id=content_id,
            vector=embedding,
            collection_type="content",
            metadata={
                "project_id": project_id,
                "title": "Open Action Items",
                "text": content,
                "content_type": "action_item",
                "created_at": (datetime.now(timezone.utc) - timedelta(days=2)).isoformat()
            }
        )


@pytest.mark.asyncio
class TestRepetitionDetection:
    """Test suite for repetition detection functionality"""

    async def test_repetition_detected_after_3_occurrences(self, db: AsyncSession):
        """
        Test that repetition is detected after 3 similar discussions.

        Given: A meeting session in progress
        When: The same topic is discussed 3+ times within 15 minutes
        Then: Repetition alert should be generated with confidence >= 0.65
        """
        service = RealtimeMeetingInsightsService()

        session_id = f"test_session_{uuid.uuid4()}"
        project_id = str(uuid.uuid4())
        org_id = str(uuid.uuid4())

        base_time = datetime.now(timezone.utc)

        # First mention
        chunk1 = TranscriptChunk(
            chunk_id=str(uuid.uuid4()),
            text="I think we should use MongoDB for the database.",
            timestamp=base_time,
            index=1,
            speaker="Alice"
        )
        await service.process_transcript_chunk(
            session_id, project_id, org_id, chunk1, db
        )

        # Second mention (5 minutes later)
        chunk2 = TranscriptChunk(
            chunk_id=str(uuid.uuid4()),
            text="As I mentioned, MongoDB would be a good choice for our database.",
            timestamp=base_time + timedelta(minutes=5),
            index=2,
            speaker="Alice"
        )
        await service.process_transcript_chunk(
            session_id, project_id, org_id, chunk2, db
        )

        # Third mention (10 minutes later) - Should trigger alert
        chunk3 = TranscriptChunk(
            chunk_id=str(uuid.uuid4()),
            text="Going back to MongoDB, I still think it's the right database choice.",
            timestamp=base_time + timedelta(minutes=10),
            index=3,
            speaker="Alice"
        )
        result = await service.process_transcript_chunk(
            session_id, project_id, org_id, chunk3, db
        )

        # Check for repetition alert
        repetitions = [
            p for p in result.proactive_assistance
            if p['type'] == 'repetition_detected'
        ]

        assert len(repetitions) > 0, "Repetition should be detected after 3 mentions"

        repetition = repetitions[0]
        assert repetition['confidence'] >= 0.65
        assert repetition['occurrences'] >= 3
        assert len(repetition['suggestions']) > 0


@pytest.mark.asyncio
class TestConflictResolution:
    """Test suite for conflict detection with resolution suggestions"""

    async def test_conflict_includes_resolution_suggestions(self, db: AsyncSession):
        """
        Test that conflict detection includes resolution suggestions.

        Given: A past decision to use REST API
        When: Team discusses using GraphQL instead
        Then: Conflict should be detected with resolution_suggestions list
        """
        service = RealtimeMeetingInsightsService()

        session_id = f"test_session_{uuid.uuid4()}"
        project_id = str(uuid.uuid4())
        org_id = str(uuid.uuid4())

        # Seed past decision
        await self._seed_past_decision(
            project_id=project_id,
            org_id=org_id,
            content="We decided to use REST API for our backend services"
        )

        # Create conflicting decision
        chunk = TranscriptChunk(
            chunk_id=str(uuid.uuid4()),
            text="Let's switch to GraphQL instead of REST for our API.",
            timestamp=datetime.now(timezone.utc),
            index=1,
            speaker="David"
        )

        result = await service.process_transcript_chunk(
            session_id=session_id,
            project_id=project_id,
            organization_id=org_id,
            chunk=chunk,
            db=db
        )

        # Check for conflict with resolution suggestions
        conflicts = [
            p for p in result.proactive_assistance
            if p['type'] == 'conflict_detected'
        ]

        assert len(conflicts) > 0, "Conflict should be detected"

        conflict = conflicts[0]
        assert conflict['confidence'] >= 0.65
        assert 'resolution_suggestions' in conflict
        assert len(conflict['resolution_suggestions']) > 0, "Should have resolution suggestions"
        assert conflict['conflict_severity'] in ['high', 'medium', 'low']

        # Verify suggestions are actionable strings
        for suggestion in conflict['resolution_suggestions']:
            assert isinstance(suggestion, str)
            assert len(suggestion) > 10  # Meaningful suggestion

    async def _seed_past_decision(self, project_id: str, org_id: str, content: str):
        """Helper to seed knowledge base with past decision"""
        from services.rag.embedding_service import embedding_service

        content_id = str(uuid.uuid4())
        embedding = await embedding_service.generate_embedding(content)

        await multi_tenant_vector_store.upsert_vector(
            organization_id=org_id,
            content_id=content_id,
            vector=embedding,
            collection_type="content",
            metadata={
                "project_id": project_id,
                "title": "API Decision",
                "text": content,
                "content_type": "decision",
                "created_at": (datetime.now(timezone.utc) - timedelta(days=7)).isoformat()
            }
        )


@pytest.mark.asyncio
class TestLoweredConfidenceThresholds:
    """Test that lowered confidence thresholds surface more features"""

    async def test_medium_confidence_auto_answer_not_filtered(self, db: AsyncSession):
        """
        Test that auto-answers with confidence 0.6-0.7 are now surfaced.

        Given: Lowered threshold from 0.7 to 0.6
        When: Auto-answer has confidence 0.65
        Then: Should be included in results (not filtered)
        """
        # This test verifies the fix - previously confidence 0.65 would be filtered
        # Now with threshold 0.6, it should pass through

        service = RealtimeMeetingInsightsService()

        # Check that min_confidence_threshold was lowered
        assert service.qa_service.min_confidence_threshold == 0.6

    async def test_medium_confidence_follow_up_not_filtered(self, db: AsyncSession):
        """
        Test that follow-up suggestions with confidence 0.55-0.65 are now surfaced.

        Given: Lowered threshold from 0.65 to 0.55
        When: Follow-up has confidence 0.60
        Then: Should be included in results
        """
        service = RealtimeMeetingInsightsService()

        # Check that threshold was lowered
        from services.intelligence.follow_up_suggestions_service import FollowUpSuggestionsService
        assert FollowUpSuggestionsService.MIN_CONFIDENCE_THRESHOLD == 0.55


if __name__ == "__main__":
    pytest.main([__file__, "-v", "--tb=short"])
