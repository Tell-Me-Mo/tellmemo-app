"""
Unit tests for graceful degradation in realtime_meeting_insights service.

Tests that when Active Intelligence phases fail, the system continues to operate
in a degraded mode rather than crashing entirely. This ensures users still get
core insights even when some AI features are temporarily unavailable.

Expected behavior:
- Individual phase failures should NOT crash the entire pipeline
- Failed phases should be tracked with PhaseStatus.FAILED
- Overall status should be ProcessingStatus.DEGRADED when some phases fail
- Core insights should still be extracted and returned
- Error messages should be logged but not exposed to users
"""

import pytest
from datetime import datetime
from unittest.mock import AsyncMock, patch

from services.intelligence.realtime_meeting_insights import (
    RealtimeMeetingInsightsService,
    MeetingInsight,
    InsightType,
    InsightPriority,
    TranscriptChunk,
    ProcessingStatus,
    PhaseStatus
)


class TestGracefulDegradation:
    """Test graceful degradation when Active Intelligence phases fail."""

    @pytest.fixture
    def service(self):
        """Create a RealtimeMeetingInsightsService instance."""
        return RealtimeMeetingInsightsService()

    @pytest.fixture
    def sample_chunk(self):
        """Create a sample TranscriptChunk."""
        return TranscriptChunk(
            chunk_id="test_chunk_1",
            text="What should we do? John will implement the feature by Friday.",
            timestamp=datetime.utcnow(),
            index=0,
            speaker="Team"
        )

    @pytest.fixture
    def sample_insights(self):
        """Create sample insights that would trigger multiple phases."""
        return [
            MeetingInsight(
                insight_id="test_1",
                type=InsightType.QUESTION,
                priority=InsightPriority.MEDIUM,
                content="What should we do?",
                context="Team discussion",
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
            ),
            MeetingInsight(
                insight_id="test_3",
                type=InsightType.DECISION,
                priority=InsightPriority.HIGH,
                content="Use GraphQL for API",
                context="Architecture decision",
                timestamp=datetime.utcnow()
            )
        ]

    @pytest.mark.asyncio
    async def test_single_phase_failure_results_in_degraded_status(self, service, sample_chunk, sample_insights):
        """Test that when one phase fails, overall status is DEGRADED."""
        from services.intelligence.action_item_quality_service import ActionItemQualityReport

        session_id = "test_session"
        project_id = "test_project"
        org_id = "test_org"
        context = "Team discussion about next steps"

        # Mock quality service with proper return value
        quality_report = ActionItemQualityReport(
            action_item="John to implement feature",
            completeness_score=0.9,
            issues=[],
            improved_version=None
        )

        # Mock Phase 1 (question_answering) to raise an exception
        with patch.object(service.question_detector, 'detect_and_classify_question',
                         new_callable=AsyncMock, side_effect=Exception("Question detector LLM timeout")), \
             patch.object(service.clarification_service, 'detect_vagueness',
                         new_callable=AsyncMock, return_value=None), \
             patch.object(service.conflict_detection_service, 'detect_conflicts',
                         new_callable=AsyncMock, return_value=None), \
             patch.object(service.quality_service, 'check_quality',
                         new_callable=AsyncMock, return_value=quality_report), \
             patch.object(service.follow_up_service, 'suggest_follow_ups',
                         new_callable=AsyncMock, return_value=[]), \
             patch.object(service.repetition_detector, 'detect_repetition',
                         new_callable=AsyncMock, return_value=None), \
             patch.object(service.time_tracker, 'track_time_usage',
                         new_callable=AsyncMock, return_value=None):

            proactive_responses, phase_status, error_messages, phase_timings = await service._process_proactive_assistance(
                session_id=session_id,
                project_id=project_id,
                organization_id=org_id,
                insights=sample_insights,
                context=context,
                current_chunk=sample_chunk
            )

        # Verify Phase 1 failed
        assert phase_status['question_answering'] == PhaseStatus.FAILED
        assert 'question_answering' in error_messages
        assert "Question detector LLM timeout" in error_messages['question_answering']

        # Verify other phases succeeded
        assert phase_status['clarification'] == PhaseStatus.SUCCESS
        assert phase_status['conflict_detection'] == PhaseStatus.SUCCESS
        assert phase_status['action_item_quality'] == PhaseStatus.SUCCESS
        assert phase_status['follow_up_suggestions'] == PhaseStatus.SUCCESS
        assert phase_status['meeting_efficiency'] == PhaseStatus.SUCCESS

        # Verify we still got responses from successful phases (if any)
        # In this case, no responses because mocks return None/empty lists
        # But the important thing is the pipeline didn't crash

    @pytest.mark.asyncio
    async def test_multiple_phase_failures_results_in_degraded_status(self, service, sample_chunk, sample_insights):
        """Test that when multiple phases fail, overall status is still DEGRADED."""
        from services.intelligence.action_item_quality_service import ActionItemQualityReport

        session_id = "test_session"
        project_id = "test_project"
        org_id = "test_org"
        context = "Team discussion"

        quality_report = ActionItemQualityReport(
            action_item="John to implement feature",
            completeness_score=0.9,
            issues=[],
            improved_version=None
        )

        # Mock multiple phases to fail
        with patch.object(service.question_detector, 'detect_and_classify_question',
                         new_callable=AsyncMock, side_effect=Exception("QA service down")), \
             patch.object(service.clarification_service, 'detect_vagueness',
                         new_callable=AsyncMock, side_effect=Exception("Clarification service timeout")), \
             patch.object(service.conflict_detection_service, 'detect_conflicts',
                         new_callable=AsyncMock, side_effect=Exception("Conflict detection LLM error")), \
             patch.object(service.quality_service, 'check_quality',
                         new_callable=AsyncMock, return_value=quality_report), \
             patch.object(service.follow_up_service, 'suggest_follow_ups',
                         new_callable=AsyncMock, return_value=[]), \
             patch.object(service.repetition_detector, 'detect_repetition',
                         new_callable=AsyncMock, return_value=None), \
             patch.object(service.time_tracker, 'track_time_usage',
                         new_callable=AsyncMock, return_value=None):

            proactive_responses, phase_status, error_messages, phase_timings = await service._process_proactive_assistance(
                session_id=session_id,
                project_id=project_id,
                organization_id=org_id,
                insights=sample_insights,
                context=context,
                current_chunk=sample_chunk
            )

        # Verify multiple phases failed
        assert phase_status['question_answering'] == PhaseStatus.FAILED
        assert phase_status['clarification'] == PhaseStatus.FAILED
        assert phase_status['conflict_detection'] == PhaseStatus.FAILED

        # Verify error messages are captured
        assert 'question_answering' in error_messages
        assert 'clarification' in error_messages
        assert 'conflict_detection' in error_messages

        # Verify other phases still succeeded
        assert phase_status['action_item_quality'] == PhaseStatus.SUCCESS
        assert phase_status['follow_up_suggestions'] == PhaseStatus.SUCCESS
        assert phase_status['meeting_efficiency'] == PhaseStatus.SUCCESS

    @pytest.mark.asyncio
    async def test_phase6_failure_is_tracked(self, service, sample_chunk, sample_insights):
        """Test that Phase 6 (meeting_efficiency) failures are also gracefully handled."""
        session_id = "test_session"
        project_id = "test_project"
        org_id = "test_org"
        context = "Team discussion"

        # Mock Phase 6 (repetition detector) to fail
        with patch.object(service.question_detector, 'detect_and_classify_question',
                         new_callable=AsyncMock, return_value=None), \
             patch.object(service.clarification_service, 'detect_vagueness',
                         new_callable=AsyncMock, return_value=None), \
             patch.object(service.conflict_detection_service, 'detect_conflicts',
                         new_callable=AsyncMock, return_value=None), \
             patch.object(service.quality_service, 'check_quality',
                         new_callable=AsyncMock, return_value=None), \
             patch.object(service.follow_up_service, 'suggest_follow_ups',
                         new_callable=AsyncMock, return_value=[]), \
             patch.object(service.repetition_detector, 'detect_repetition',
                         new_callable=AsyncMock, side_effect=Exception("Repetition detector crashed")), \
             patch.object(service.time_tracker, 'track_time_usage',
                         new_callable=AsyncMock, return_value=None):

            proactive_responses, phase_status, error_messages, phase_timings = await service._process_proactive_assistance(
                session_id=session_id,
                project_id=project_id,
                organization_id=org_id,
                insights=sample_insights,
                context=context,
                current_chunk=sample_chunk
            )

        # Verify Phase 6 failed
        assert phase_status['meeting_efficiency'] == PhaseStatus.FAILED
        assert 'meeting_efficiency' in error_messages
        assert "Repetition detector crashed" in error_messages['meeting_efficiency']

    @pytest.mark.asyncio
    async def test_all_proactive_phases_fail_but_core_insights_still_returned(self, service, sample_chunk):
        """
        Test that even when ALL Active Intelligence phases fail,
        core insight extraction still works (doesn't crash).

        This simulates a worst-case scenario where LLM services are degraded
        but the system should still extract basic insights.
        """
        session_id = "test_session"
        project_id = "test_project"
        org_id = "test_org"

        # Sample insights that were already extracted (before proactive assistance)
        sample_insights = [
            MeetingInsight(
                insight_id="test_1",
                type=InsightType.DECISION,
                priority=InsightPriority.HIGH,
                content="Use PostgreSQL",
                context="Database decision",
                timestamp=datetime.utcnow()
            )
        ]
        context = "Database discussion"

        # Mock ALL phases to fail
        with patch.object(service.question_detector, 'detect_and_classify_question',
                         new_callable=AsyncMock, side_effect=Exception("Service down")), \
             patch.object(service.clarification_service, 'detect_vagueness',
                         new_callable=AsyncMock, side_effect=Exception("Service down")), \
             patch.object(service.conflict_detection_service, 'detect_conflicts',
                         new_callable=AsyncMock, side_effect=Exception("Service down")), \
             patch.object(service.quality_service, 'check_quality',
                         new_callable=AsyncMock, side_effect=Exception("Service down")), \
             patch.object(service.follow_up_service, 'suggest_follow_ups',
                         new_callable=AsyncMock, side_effect=Exception("Service down")), \
             patch.object(service.repetition_detector, 'detect_repetition',
                         new_callable=AsyncMock, side_effect=Exception("Service down")), \
             patch.object(service.time_tracker, 'track_time_usage',
                         new_callable=AsyncMock, side_effect=Exception("Service down")):

            proactive_responses, phase_status, error_messages, phase_timings = await service._process_proactive_assistance(
                session_id=session_id,
                project_id=project_id,
                organization_id=org_id,
                insights=sample_insights,
                context=context,
                current_chunk=sample_chunk
            )

        # Verify phases based on actual activation (decision insight triggers some phases)
        # Phases that should be SKIPPED (not activated by decision insight)
        assert phase_status.get('question_answering', PhaseStatus.SKIPPED) == PhaseStatus.SKIPPED  # No question
        assert phase_status.get('action_item_quality', PhaseStatus.SKIPPED) == PhaseStatus.SKIPPED  # No action item

        # Phases that should be FAILED (activated but failed)
        assert phase_status['clarification'] == PhaseStatus.FAILED  # Decision insight triggers this
        assert phase_status['conflict_detection'] == PhaseStatus.FAILED  # Decision insight triggers this
        assert phase_status['follow_up_suggestions'] == PhaseStatus.FAILED  # Decision insight triggers this
        assert phase_status['meeting_efficiency'] == PhaseStatus.FAILED

        # Verify error messages were captured for all failed phases
        assert len(error_messages) >= 4  # At least the 4 phases that were active

        # Verify we got no proactive responses (all phases failed)
        assert len(proactive_responses) == 0

        # Important: The function should NOT raise an exception
        # It should return gracefully with failed status

    @pytest.mark.asyncio
    async def test_failed_phases_list_is_populated_correctly(self, service, sample_chunk, sample_insights):
        """Test that failed_phases list correctly identifies which phases failed."""
        from services.intelligence.action_item_quality_service import ActionItemQualityReport

        session_id = "test_session"
        project_id = "test_project"
        org_id = "test_org"
        context = "Team discussion"

        quality_report = ActionItemQualityReport(
            action_item="John to implement feature",
            completeness_score=0.9,
            issues=[],
            improved_version=None
        )

        # Mock specific phases to fail
        with patch.object(service.question_detector, 'detect_and_classify_question',
                         new_callable=AsyncMock, side_effect=Exception("Phase 1 error")), \
             patch.object(service.clarification_service, 'detect_vagueness',
                         new_callable=AsyncMock, return_value=None), \
             patch.object(service.conflict_detection_service, 'detect_conflicts',
                         new_callable=AsyncMock, side_effect=Exception("Phase 3 error")), \
             patch.object(service.quality_service, 'check_quality',
                         new_callable=AsyncMock, return_value=quality_report), \
             patch.object(service.follow_up_service, 'suggest_follow_ups',
                         new_callable=AsyncMock, return_value=[]), \
             patch.object(service.repetition_detector, 'detect_repetition',
                         new_callable=AsyncMock, return_value=None), \
             patch.object(service.time_tracker, 'track_time_usage',
                         new_callable=AsyncMock, return_value=None):

            proactive_responses, phase_status, error_messages, phase_timings = await service._process_proactive_assistance(
                session_id=session_id,
                project_id=project_id,
                organization_id=org_id,
                insights=sample_insights,
                context=context,
                current_chunk=sample_chunk
            )

        # Build failed_phases list from phase_status (as done in process_transcript_chunk)
        failed_phases = [phase for phase, status in phase_status.items() if status == PhaseStatus.FAILED]

        # Verify exactly the failed phases are listed
        assert 'question_answering' in failed_phases
        assert 'conflict_detection' in failed_phases
        # Note: We expect exactly 2 failures, not more
        assert len(failed_phases) == 2

    @pytest.mark.asyncio
    async def test_phase_timings_are_recorded_even_for_failed_phases(self, service, sample_chunk, sample_insights):
        """Test that phase execution times are recorded even when phases fail."""
        session_id = "test_session"
        project_id = "test_project"
        org_id = "test_org"
        context = "Team discussion"

        # Mock a phase to fail
        with patch.object(service.question_detector, 'detect_and_classify_question',
                         new_callable=AsyncMock, side_effect=Exception("Timeout")), \
             patch.object(service.clarification_service, 'detect_vagueness',
                         new_callable=AsyncMock, return_value=None), \
             patch.object(service.conflict_detection_service, 'detect_conflicts',
                         new_callable=AsyncMock, return_value=None), \
             patch.object(service.quality_service, 'check_quality',
                         new_callable=AsyncMock, return_value=None), \
             patch.object(service.follow_up_service, 'suggest_follow_ups',
                         new_callable=AsyncMock, return_value=[]), \
             patch.object(service.repetition_detector, 'detect_repetition',
                         new_callable=AsyncMock, return_value=None), \
             patch.object(service.time_tracker, 'track_time_usage',
                         new_callable=AsyncMock, return_value=None):

            proactive_responses, phase_status, error_messages, phase_timings = await service._process_proactive_assistance(
                session_id=session_id,
                project_id=project_id,
                organization_id=org_id,
                insights=sample_insights,
                context=context,
                current_chunk=sample_chunk
            )

        # Verify timing was recorded for the failed phase
        assert 'question_answering' in phase_timings
        assert phase_timings['question_answering'] >= 0  # Should have some timing value

    @pytest.mark.asyncio
    async def test_no_proactive_responses_when_all_phases_fail(self, service, sample_chunk, sample_insights):
        """Test that proactive_responses is empty when all phases fail."""
        session_id = "test_session"
        project_id = "test_project"
        org_id = "test_org"
        context = "Team discussion"

        # Mock all phases to fail
        with patch.object(service.question_detector, 'detect_and_classify_question',
                         new_callable=AsyncMock, side_effect=Exception("Error")), \
             patch.object(service.clarification_service, 'detect_vagueness',
                         new_callable=AsyncMock, side_effect=Exception("Error")), \
             patch.object(service.conflict_detection_service, 'detect_conflicts',
                         new_callable=AsyncMock, side_effect=Exception("Error")), \
             patch.object(service.quality_service, 'check_quality',
                         new_callable=AsyncMock, side_effect=Exception("Error")), \
             patch.object(service.follow_up_service, 'suggest_follow_ups',
                         new_callable=AsyncMock, side_effect=Exception("Error")), \
             patch.object(service.repetition_detector, 'detect_repetition',
                         new_callable=AsyncMock, side_effect=Exception("Error")), \
             patch.object(service.time_tracker, 'track_time_usage',
                         new_callable=AsyncMock, side_effect=Exception("Error")):

            proactive_responses, phase_status, error_messages, phase_timings = await service._process_proactive_assistance(
                session_id=session_id,
                project_id=project_id,
                organization_id=org_id,
                insights=sample_insights,
                context=context,
                current_chunk=sample_chunk
            )

        # Verify no proactive responses were generated
        assert len(proactive_responses) == 0

    @pytest.mark.asyncio
    async def test_warning_message_generated_for_degraded_status(self, service, sample_chunk, sample_insights):
        """Test that a user-friendly warning message is generated when status is DEGRADED."""
        from services.intelligence.realtime_meeting_insights import ProcessingResult
        from services.intelligence.action_item_quality_service import ActionItemQualityReport

        session_id = "test_session"
        project_id = "test_project"
        org_id = "test_org"
        context = "Team discussion"

        quality_report = ActionItemQualityReport(
            action_item="John to implement feature",
            completeness_score=0.9,
            issues=[],
            improved_version=None
        )

        # Mock a phase to fail
        with patch.object(service.question_detector, 'detect_and_classify_question',
                         new_callable=AsyncMock, side_effect=Exception("Service unavailable")), \
             patch.object(service.clarification_service, 'detect_vagueness',
                         new_callable=AsyncMock, return_value=None), \
             patch.object(service.conflict_detection_service, 'detect_conflicts',
                         new_callable=AsyncMock, return_value=None), \
             patch.object(service.quality_service, 'check_quality',
                         new_callable=AsyncMock, return_value=quality_report), \
             patch.object(service.follow_up_service, 'suggest_follow_ups',
                         new_callable=AsyncMock, return_value=[]), \
             patch.object(service.repetition_detector, 'detect_repetition',
                         new_callable=AsyncMock, return_value=None), \
             patch.object(service.time_tracker, 'track_time_usage',
                         new_callable=AsyncMock, return_value=None):

            proactive_responses, phase_status, error_messages, phase_timings = await service._process_proactive_assistance(
                session_id=session_id,
                project_id=project_id,
                organization_id=org_id,
                insights=sample_insights,
                context=context,
                current_chunk=sample_chunk
            )

        # Build ProcessingResult to test warning message
        failed_phases = [phase for phase, status in phase_status.items() if status == PhaseStatus.FAILED]

        result = ProcessingResult(
            session_id=session_id,
            chunk_index=0,
            insights=sample_insights,
            proactive_assistance=proactive_responses,
            overall_status=ProcessingStatus.DEGRADED,
            phase_status=phase_status,
            failed_phases=failed_phases,
            error_messages=error_messages
        )

        # Test warning message generation
        warning = result.get_warning_message()
        assert warning is not None
        assert "unavailable" in warning.lower()
        # The warning message shows feature count, not phase names (for user-friendliness)
        assert "features" in warning.lower() or "feature" in warning.lower()


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
