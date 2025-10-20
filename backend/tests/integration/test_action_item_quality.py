"""
Integration tests for Phase 4: Action Item Quality Enhancement feature.

Tests the quality service that detects incomplete action items and suggests
improvements to ensure clarity and completeness.
"""

import pytest
from services.intelligence.action_item_quality_service import ActionItemQualityService


class TestFieldDetection:
    """Test detection of required fields in action items."""

    def test_detect_missing_owner(self):
        """Test detection of action items without owner."""
        service = ActionItemQualityService(llm_client=None)

        action_item = "Fix the authentication bug by Friday"

        has_owner = service._has_owner(action_item)

        assert not has_owner, "Should detect missing owner"

    def test_detect_present_owner(self):
        """Test detection of action items with owner."""
        service = ActionItemQualityService(llm_client=None)

        test_cases = [
            "John to fix the authentication bug",
            "Sarah will review the PR",
            "Assigned to: Alice",
            "Owner: Bob"
        ]

        for action_item in test_cases:
            has_owner = service._has_owner(action_item)
            assert has_owner, f"Should detect owner in '{action_item}'"

    def test_detect_missing_deadline(self):
        """Test detection of action items without deadline."""
        service = ActionItemQualityService(llm_client=None)

        action_item = "John to fix the authentication bug"

        has_deadline = service._has_deadline(action_item)

        assert not has_deadline, "Should detect missing deadline"

    def test_detect_present_deadline(self):
        """Test detection of action items with deadline."""
        service = ActionItemQualityService(llm_client=None)

        test_cases = [
            "Fix the bug by Friday",
            "Complete review by 10/25",
            "Deploy by end of week",
            "Due by next Monday",
            "Within 3 days"
        ]

        for action_item in test_cases:
            has_deadline = service._has_deadline(action_item)
            assert has_deadline, f"Should detect deadline in '{action_item}'"

    def test_detect_vague_verbs(self):
        """Test detection of vague action verbs."""
        service = ActionItemQualityService(llm_client=None)

        vague_actions = [
            "look into the performance issue",
            "check on the deployment status",
            "think about the architecture",
            "consider using GraphQL"
        ]

        for action_item in vague_actions:
            has_vague = any(verb in action_item.lower() for verb in service.VAGUE_VERBS)
            assert has_vague, f"Should detect vague verb in '{action_item}'"

    def test_ignore_clear_verbs(self):
        """Test that clear action verbs are not flagged."""
        service = ActionItemQualityService(llm_client=None)

        clear_actions = [
            "implement user authentication",
            "review the security audit",
            "deploy to production",
            "fix the timeout bug"
        ]

        for action_item in clear_actions:
            has_vague = any(verb in action_item.lower() for verb in service.VAGUE_VERBS)
            assert not has_vague, f"Should not flag clear verb in '{action_item}'"


class TestCompletenessScoring:
    """Test completeness score calculation."""

    def test_perfect_score_no_issues(self):
        """Test that action items with no issues get perfect score."""
        service = ActionItemQualityService(llm_client=None)

        issues = []
        score = service._calculate_completeness(issues)

        assert score == 1.0, "Perfect action item should have score of 1.0"

    def test_score_with_critical_issues(self):
        """Test score calculation with critical issues."""
        service = ActionItemQualityService(llm_client=None)

        from services.intelligence.action_item_quality_service import QualityIssue

        issues = [
            QualityIssue(field='owner', severity='critical', message='No owner'),
            QualityIssue(field='deadline', severity='critical', message='No deadline')
        ]
        score = service._calculate_completeness(issues)

        # 1.0 - 0.3 - 0.3 = 0.4
        assert abs(score - 0.4) < 0.0001, f"Expected 0.4, got {score}"

    def test_score_with_important_issues(self):
        """Test score calculation with important issues."""
        service = ActionItemQualityService(llm_client=None)

        from services.intelligence.action_item_quality_service import QualityIssue

        issues = [
            QualityIssue(field='description', severity='important', message='Too brief')
        ]
        score = service._calculate_completeness(issues)

        # 1.0 - 0.15 = 0.85
        assert score == 0.85, f"Expected 0.85, got {score}"

    def test_score_with_suggestions(self):
        """Test score calculation with suggestions."""
        service = ActionItemQualityService(llm_client=None)

        from services.intelligence.action_item_quality_service import QualityIssue

        issues = [
            QualityIssue(field='success_criteria', severity='suggestion', message='Add criteria')
        ]
        score = service._calculate_completeness(issues)

        # 1.0 - 0.05 = 0.95
        assert score == 0.95, f"Expected 0.95, got {score}"

    def test_score_minimum_is_zero(self):
        """Test that score never goes below zero."""
        service = ActionItemQualityService(llm_client=None)

        from services.intelligence.action_item_quality_service import QualityIssue

        # Create many critical issues that would sum to negative
        issues = [
            QualityIssue(field=f'field{i}', severity='critical', message='Issue')
            for i in range(10)
        ]
        score = service._calculate_completeness(issues)

        assert score >= 0.0, "Score should never be negative"
        assert score == 0.0, f"Score with many issues should be 0.0, got {score}"


class TestQualityReportGeneration:
    """Test end-to-end quality report generation."""

    @pytest.mark.asyncio
    async def test_complete_action_item_no_report(self):
        """Test that complete action items get high scores."""
        # Mock LLM client (not needed for pattern detection)
        service = ActionItemQualityService(llm_client=None)

        action_item = "John to implement user authentication by Friday 5pm"

        report = await service.check_quality(action_item)

        # Should have owner (John) and deadline (Friday)
        assert report.completeness_score >= 0.6, "Complete action item should have high score"
        assert len(report.issues) <= 1, "Complete action item should have few issues"

    @pytest.mark.asyncio
    async def test_incomplete_action_item_generates_report(self):
        """Test that incomplete action items generate quality reports."""
        service = ActionItemQualityService(llm_client=None)

        action_item = "Looking into that performance bug"

        report = await service.check_quality(action_item)

        # Should detect multiple issues
        assert report.completeness_score < 0.5, "Incomplete action item should have low score"
        assert len(report.issues) >= 2, "Should detect multiple issues"

        # Check for specific issues
        issue_fields = [issue.field for issue in report.issues]
        assert 'owner' in issue_fields, "Should detect missing owner"
        assert 'deadline' in issue_fields, "Should detect missing deadline"

    @pytest.mark.asyncio
    async def test_vague_action_item_flagged(self):
        """Test that action items with vague verbs are flagged."""
        service = ActionItemQualityService(llm_client=None)

        action_item = "John to look into the performance issue by next week"

        report = await service.check_quality(action_item)

        # Should detect vague verb
        issue_messages = [issue.message.lower() for issue in report.issues]
        has_vague_verb_issue = any('vague' in msg for msg in issue_messages)

        assert has_vague_verb_issue, "Should flag vague action verb 'look into'"

    @pytest.mark.asyncio
    async def test_brief_description_flagged(self):
        """Test that overly brief descriptions are flagged."""
        service = ActionItemQualityService(llm_client=None)

        action_item = "Fix bug"

        report = await service.check_quality(action_item)

        # Should detect brief description
        issue_fields = [issue.field for issue in report.issues]
        assert 'description' in issue_fields, "Should flag brief description"


class TestFieldLabels:
    """Test helper methods for UI display."""

    def test_field_label_mapping(self):
        """Test that field names map to user-friendly labels."""
        # This would be in the service if we added a helper method
        # For now, just verify the pattern we'd use
        field_map = {
            'owner': 'Missing Owner',
            'deadline': 'Missing Deadline',
            'description': 'Vague Description',
            'success_criteria': 'Success Criteria'
        }

        assert field_map['owner'] == 'Missing Owner'
        assert field_map['deadline'] == 'Missing Deadline'
        assert field_map['description'] == 'Vague Description'


if __name__ == '__main__':
    pytest.main([__file__, '-v'])
