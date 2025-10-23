"""
Unit tests for selective phase execution in realtime_meeting_insights service.

Tests the _determine_active_phases method which optimizes LLM calls by only running
relevant Active Intelligence phases based on chunk content and extracted insights.

Expected savings: 40-60% reduction in LLM calls
"""

import pytest
from datetime import datetime
from unittest.mock import Mock, patch

from services.intelligence.realtime_meeting_insights import (
    RealtimeMeetingInsightsService,
    MeetingInsight,
    InsightType,
    InsightPriority,
    TranscriptChunk
)


class TestSelectivePhaseExecution:
    """Test selective phase execution optimization."""

    @pytest.fixture
    def service(self):
        """Create a RealtimeMeetingInsightsService instance."""
        return RealtimeMeetingInsightsService()

    @pytest.fixture
    def sample_chunk(self):
        """Create a sample TranscriptChunk."""
        return TranscriptChunk(
            chunk_id="test_chunk_1",
            text="Sample text",
            timestamp=datetime.utcnow(),
            index=0,
            speaker="John"
        )

    def test_phase1_activated_by_question_mark(self, service):
        """Test Phase 1 (question_answering) is activated by question mark."""
        chunk_text = "Should we use GraphQL for the API?"
        insights = []

        active_phases = service._determine_active_phases(chunk_text, insights)

        assert 'question_answering' in active_phases

    def test_phase1_activated_by_question_words(self, service):
        """Test Phase 1 is activated by question words (what, when, where, who, why, how)."""
        test_cases = [
            "What is the deadline for this task",
            "When should we schedule the meeting",
            "Where are we storing the data",
            "Who is responsible for testing",
            "Why did we choose this approach",
            "How will we implement authentication"
        ]

        for chunk_text in test_cases:
            insights = []
            active_phases = service._determine_active_phases(chunk_text, insights)
            assert 'question_answering' in active_phases, f"Failed for: {chunk_text}"

    def test_phase1_activated_by_question_insight(self, service):
        """Test Phase 1 is activated when a QUESTION insight was extracted."""
        chunk_text = "We need to decide on the database"
        insights = [
            MeetingInsight(
                insight_id="test_1",
                type=InsightType.QUESTION,
                priority=InsightPriority.MEDIUM,
                content="Which database should we use?",
                context="Database selection discussion",
                timestamp=datetime.utcnow()
            )
        ]

        active_phases = service._determine_active_phases(chunk_text, insights)

        assert 'question_answering' in active_phases

    def test_phase2_activated_by_action_item_insight(self, service):
        """Test Phase 2 (clarification) is activated by action item insight."""
        chunk_text = "John will handle the documentation"
        insights = [
            MeetingInsight(
                insight_id="test_1",
                type=InsightType.ACTION_ITEM,
                priority=InsightPriority.HIGH,
                content="John to complete documentation",
                context="Task assignment",
                timestamp=datetime.utcnow()
            )
        ]

        active_phases = service._determine_active_phases(chunk_text, insights)

        assert 'clarification' in active_phases

    def test_phase2_activated_by_decision_insight(self, service):
        """Test Phase 2 (clarification) is activated by decision insight."""
        chunk_text = "We decided to use PostgreSQL"
        insights = [
            MeetingInsight(
                insight_id="test_1",
                type=InsightType.DECISION,
                priority=InsightPriority.HIGH,
                content="Use PostgreSQL as database",
                context="Database decision",
                timestamp=datetime.utcnow()
            )
        ]

        active_phases = service._determine_active_phases(chunk_text, insights)

        assert 'clarification' in active_phases

    def test_phase3_activated_by_decision_keywords(self, service):
        """Test Phase 3 (conflict_detection) is activated by decision keywords."""
        test_cases = [
            "We decided to use GraphQL",
            "The team agreed on using Docker",
            "This approach was approved by management",
            "Let's use TypeScript for the frontend",
            "We'll implement authentication first",
            "We're going to deploy on AWS",
            "We will do weekly sprints",
            "We plan to launch in Q2",
            "We commit to the new architecture",
            "We choose React for the UI",
            "We selected MongoDB"
        ]

        for chunk_text in test_cases:
            insights = []
            active_phases = service._determine_active_phases(chunk_text, insights)
            assert 'conflict_detection' in active_phases, f"Failed for: {chunk_text}"

    def test_phase3_activated_by_decision_insight(self, service):
        """Test Phase 3 is activated when a DECISION insight was extracted."""
        chunk_text = "The architecture is finalized"
        insights = [
            MeetingInsight(
                insight_id="test_1",
                type=InsightType.DECISION,
                priority=InsightPriority.CRITICAL,
                content="Finalized microservices architecture",
                context="Architecture decision",
                timestamp=datetime.utcnow()
            )
        ]

        active_phases = service._determine_active_phases(chunk_text, insights)

        assert 'conflict_detection' in active_phases

    def test_phase4_activated_by_action_item_insight(self, service):
        """Test Phase 4 (action_item_quality) is activated only by action item insight."""
        chunk_text = "Sarah will review the code"
        insights = [
            MeetingInsight(
                insight_id="test_1",
                type=InsightType.ACTION_ITEM,
                priority=InsightPriority.HIGH,
                content="Sarah to review code",
                context="Code review assignment",
                timestamp=datetime.utcnow()
            )
        ]

        active_phases = service._determine_active_phases(chunk_text, insights)

        assert 'action_item_quality' in active_phases

    def test_phase5_activated_by_decision_or_key_point(self, service):
        """Test Phase 5 (follow_up_suggestions) is activated by decision or key_point insight."""
        # Test with decision insight
        chunk_text = "We decided on the deployment strategy"
        insights_decision = [
            MeetingInsight(
                insight_id="test_1",
                type=InsightType.DECISION,
                priority=InsightPriority.HIGH,
                content="Deploy using Kubernetes",
                context="Deployment decision",
                timestamp=datetime.utcnow()
            )
        ]

        active_phases = service._determine_active_phases(chunk_text, insights_decision)
        assert 'follow_up_suggestions' in active_phases

        # Test with key_point insight
        insights_key_point = [
            MeetingInsight(
                insight_id="test_2",
                type=InsightType.KEY_POINT,
                priority=InsightPriority.MEDIUM,
                content="Performance is critical for user experience",
                context="Performance discussion",
                timestamp=datetime.utcnow()
            )
        ]

        active_phases = service._determine_active_phases(chunk_text, insights_key_point)
        assert 'follow_up_suggestions' in active_phases

    def test_phase6_always_active(self, service):
        """Test Phase 6 (meeting_efficiency) is always active (handled separately)."""
        # Phase 6 is not explicitly added by _determine_active_phases
        # It runs separately in _process_proactive_assistance
        chunk_text = "Generic conversation text"
        insights = []

        active_phases = service._determine_active_phases(chunk_text, insights)

        # Phase 6 should NOT be in active_phases as it's handled separately
        # This is intentional - Phase 6 always runs in _process_proactive_assistance
        assert 'meeting_efficiency' not in active_phases

    def test_no_phases_activated_for_generic_text(self, service):
        """Test that no phases are activated for generic conversation without signals."""
        chunk_text = "The weather is nice today"
        insights = []

        active_phases = service._determine_active_phases(chunk_text, insights)

        # Should be empty or very minimal
        # Phase 6 always runs separately, but shouldn't be in this set
        assert len(active_phases) == 0

    def test_multiple_phases_activated_simultaneously(self, service):
        """Test that multiple phases can be activated at once."""
        chunk_text = "What database should we use? We decided to let's go with PostgreSQL."
        insights = [
            MeetingInsight(
                insight_id="test_1",
                type=InsightType.QUESTION,
                priority=InsightPriority.MEDIUM,
                content="Which database?",
                context="Database selection",
                timestamp=datetime.utcnow()
            ),
            MeetingInsight(
                insight_id="test_2",
                type=InsightType.DECISION,
                priority=InsightPriority.HIGH,
                content="Use PostgreSQL",
                context="Database decision",
                timestamp=datetime.utcnow()
            ),
            MeetingInsight(
                insight_id="test_3",
                type=InsightType.ACTION_ITEM,
                priority=InsightPriority.HIGH,
                content="John to set up PostgreSQL",
                context="Database setup task",
                timestamp=datetime.utcnow()
            )
        ]

        active_phases = service._determine_active_phases(chunk_text, insights)

        # Should activate multiple phases
        assert 'question_answering' in active_phases  # Question mark and QUESTION insight
        assert 'clarification' in active_phases  # ACTION_ITEM and DECISION insights
        assert 'conflict_detection' in active_phases  # "decided" and "let's" keywords + DECISION insight
        assert 'action_item_quality' in active_phases  # ACTION_ITEM insight
        assert 'follow_up_suggestions' in active_phases  # DECISION insight

    def test_case_insensitive_keyword_matching(self, service):
        """Test that keyword matching is case-insensitive."""
        test_cases = [
            "We DECIDED to use GraphQL",
            "The team AGREED on Docker",
            "LET'S implement this feature",
            "WHAT is the deadline"
        ]

        for chunk_text in test_cases:
            insights = []
            active_phases = service._determine_active_phases(chunk_text, insights)
            assert len(active_phases) > 0, f"Should activate phases for: {chunk_text}"

    def test_phase_activation_counts_optimization(self, service):
        """Test that selective execution reduces phase activation significantly."""
        # Scenario 1: Generic conversation (minimal phases)
        generic_chunks = [
            "The team is working well together",
            "We had a good discussion today",
            "Thanks everyone for attending"
        ]

        total_phases_generic = 0
        for chunk_text in generic_chunks:
            active_phases = service._determine_active_phases(chunk_text, [])
            total_phases_generic += len(active_phases)

        # Should activate very few phases (close to 0)
        assert total_phases_generic <= 3, f"Generic chunks activated {total_phases_generic} phases"

        # Scenario 2: High-signal conversation (multiple phases)
        high_signal_chunks = [
            "What should we do? We decided to use GraphQL.",
            "John will implement this by Friday",
            "This is a critical decision for the project"
        ]

        total_phases_high_signal = 0
        for chunk_text in high_signal_chunks:
            insights = [
                MeetingInsight(
                    insight_id="test",
                    type=InsightType.ACTION_ITEM,
                    priority=InsightPriority.HIGH,
                    content="Task",
                    context="Context",
                    timestamp=datetime.utcnow()
                )
            ]
            active_phases = service._determine_active_phases(chunk_text, insights)
            total_phases_high_signal += len(active_phases)

        # Should activate many more phases
        assert total_phases_high_signal > total_phases_generic * 2

    def test_edge_case_empty_chunk_text(self, service):
        """Test handling of empty chunk text."""
        chunk_text = ""
        insights = []

        active_phases = service._determine_active_phases(chunk_text, insights)

        assert len(active_phases) == 0

    def test_edge_case_empty_insights(self, service):
        """Test handling when no insights were extracted."""
        chunk_text = "What is the plan? We decided to proceed."
        insights = []

        active_phases = service._determine_active_phases(chunk_text, insights)

        # Should still activate phases based on keywords
        assert 'question_answering' in active_phases  # "What"
        assert 'conflict_detection' in active_phases  # "decided"

    def test_edge_case_none_type_insights(self, service):
        """Test handling of edge cases with risk and other insight types."""
        chunk_text = "There's a risk with this approach"
        insights = [
            MeetingInsight(
                insight_id="test_1",
                type=InsightType.RISK,
                priority=InsightPriority.HIGH,
                content="Security risk identified",
                context="Risk assessment",
                timestamp=datetime.utcnow()
            )
        ]

        active_phases = service._determine_active_phases(chunk_text, insights)

        # RISK insights shouldn't activate any specific phases
        # (unless they trigger keyword detection)
        # This is correct - not all insight types activate phases
        assert 'action_item_quality' not in active_phases
        assert 'clarification' not in active_phases


class TestSelectivePhaseExecutionIntegration:
    """Integration tests to verify phase status tracking in process_proactive_assistance."""

    @pytest.fixture
    def service(self):
        """Create a RealtimeMeetingInsightsService instance."""
        return RealtimeMeetingInsightsService()

    @pytest.mark.asyncio
    async def test_skipped_phases_are_tracked(self, service):
        """Test that skipped phases are properly tracked in phase_status."""
        from services.intelligence.realtime_meeting_insights import PhaseStatus

        session_id = "test_session"
        project_id = "test_project"
        org_id = "test_org"

        # Generic chunk with no signals - should skip most phases
        chunk = TranscriptChunk(
            chunk_id="chunk_1",
            text="We had a productive meeting today",
            timestamp=datetime.utcnow(),
            index=0,
            speaker="John"
        )

        insights = []  # No insights extracted
        context = "Meeting discussion"

        # Mock all the service dependencies with AsyncMock for async methods
        from unittest.mock import AsyncMock

        with patch.object(service.qa_service, 'answer_question', new_callable=AsyncMock) as mock_qa, \
             patch.object(service.clarification_service, 'detect_vagueness', new_callable=AsyncMock) as mock_clarify, \
             patch.object(service.conflict_detection_service, 'detect_conflicts', new_callable=AsyncMock) as mock_conflict, \
             patch.object(service.quality_service, 'check_quality', new_callable=AsyncMock) as mock_quality, \
             patch.object(service.follow_up_service, 'suggest_follow_ups', new_callable=AsyncMock) as mock_followup, \
             patch.object(service.repetition_detector, 'detect_repetition', new_callable=AsyncMock) as mock_repetition, \
             patch.object(service.time_tracker, 'track_time_usage', new_callable=AsyncMock) as mock_time:

            # Configure mocks to return None (no alerts)
            mock_repetition.return_value = None
            mock_time.return_value = None

            proactive_responses, phase_status, error_messages, phase_timings = await service._process_proactive_assistance(
                session_id=session_id,
                project_id=project_id,
                organization_id=org_id,
                insights=insights,
                context=context,
                current_chunk=chunk
            )

        # Verify most phases are SKIPPED
        assert phase_status['question_answering'] == PhaseStatus.SKIPPED
        assert phase_status['clarification'] == PhaseStatus.SKIPPED
        assert phase_status['conflict_detection'] == PhaseStatus.SKIPPED
        assert phase_status['action_item_quality'] == PhaseStatus.SKIPPED
        assert phase_status['follow_up_suggestions'] == PhaseStatus.SKIPPED

        # Phase 6 (meeting_efficiency) should always run
        assert phase_status['meeting_efficiency'] == PhaseStatus.SUCCESS

        # No errors should be present
        assert len(error_messages) == 0

    @pytest.mark.asyncio
    async def test_active_phases_are_executed(self, service):
        """Test that active phases are properly executed based on signals."""
        from services.intelligence.realtime_meeting_insights import PhaseStatus

        session_id = "test_session"
        project_id = "test_project"
        org_id = "test_org"

        # Chunk with question and action item - should activate multiple phases
        chunk = TranscriptChunk(
            chunk_id="chunk_1",
            text="What should we do? John will implement by Friday.",
            timestamp=datetime.utcnow(),
            index=0,
            speaker="Team"
        )

        insights = [
            MeetingInsight(
                insight_id="test_1",
                type=InsightType.QUESTION,
                priority=InsightPriority.MEDIUM,
                content="What should we do?",
                context="Discussion",
                timestamp=datetime.utcnow()
            ),
            MeetingInsight(
                insight_id="test_2",
                type=InsightType.ACTION_ITEM,
                priority=InsightPriority.HIGH,
                content="John to implement feature",
                context="Task assignment",
                timestamp=datetime.utcnow(),
                assigned_to="John"
            )
        ]
        context = "Team discussion about next steps"

        # Mock service dependencies with AsyncMock for async methods
        from unittest.mock import AsyncMock
        from services.intelligence.action_item_quality_service import ActionItemQualityReport

        with patch.object(service.question_detector, 'detect_and_classify_question', new_callable=AsyncMock, return_value=None), \
             patch.object(service.clarification_service, 'detect_vagueness', new_callable=AsyncMock, return_value=None), \
             patch.object(service.quality_service, 'check_quality', new_callable=AsyncMock) as mock_quality, \
             patch.object(service.repetition_detector, 'detect_repetition', new_callable=AsyncMock, return_value=None), \
             patch.object(service.time_tracker, 'track_time_usage', new_callable=AsyncMock, return_value=None):

            # Mock quality check to return good completeness
            mock_quality.return_value = ActionItemQualityReport(
                action_item="John to implement feature",
                completeness_score=0.9,
                issues=[],
                improved_version=None
            )

            proactive_responses, phase_status, error_messages, phase_timings = await service._process_proactive_assistance(
                session_id=session_id,
                project_id=project_id,
                organization_id=org_id,
                insights=insights,
                context=context,
                current_chunk=chunk
            )

        # Verify phases were activated
        # Phase 1: Question answering (question insight)
        assert phase_status['question_answering'] == PhaseStatus.SUCCESS

        # Phase 2: Clarification (action item insight)
        assert phase_status['clarification'] == PhaseStatus.SUCCESS

        # Phase 4: Action item quality (action item insight)
        assert phase_status['action_item_quality'] == PhaseStatus.SUCCESS

        # Phase 3 and 5 should be skipped (no decision keywords/insights)
        assert phase_status['conflict_detection'] == PhaseStatus.SKIPPED
        assert phase_status['follow_up_suggestions'] == PhaseStatus.SKIPPED

        # Phase 6 always runs
        assert phase_status['meeting_efficiency'] == PhaseStatus.SUCCESS


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
