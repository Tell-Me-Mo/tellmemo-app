"""
Integration tests for Phase 2: Proactive Clarification feature.

Tests the clarification service that detects vague statements and suggests
clarifying questions to help teams avoid ambiguity.
"""

import pytest
from services.intelligence.clarification_service import ClarificationService


class TestVaguenessDetection:
    """Test vagueness detection patterns and classification."""

    def test_detect_time_vagueness(self):
        """Test detection of vague time references."""
        service = ClarificationService(llm_client=None)

        # Test pattern-based detection (no LLM needed)
        statement = "We should deploy this feature soon"

        # Pattern detection should work synchronously for this test
        import re
        detected = False
        for pattern in service.VAGUE_PATTERNS['time']:
            if re.search(pattern, statement, re.IGNORECASE):
                detected = True
                break

        assert detected, "Failed to detect time vagueness in 'soon'"

    def test_detect_assignment_vagueness(self):
        """Test detection of unassigned actions."""
        service = ClarificationService(llm_client=None)

        statement = "Someone should review the PR"

        import re
        detected = False
        for pattern in service.VAGUE_PATTERNS['assignment']:
            if re.search(pattern, statement, re.IGNORECASE):
                detected = True
                break

        assert detected, "Failed to detect assignment vagueness in 'someone should'"

    def test_detect_detail_vagueness(self):
        """Test detection of missing details."""
        service = ClarificationService(llm_client=None)

        statement = "We need to fix the bug"

        import re
        detected = False
        for pattern in service.VAGUE_PATTERNS['detail']:
            if re.search(pattern, statement, re.IGNORECASE):
                detected = True
                break

        assert detected, "Failed to detect detail vagueness in 'the bug'"

    def test_detect_scope_vagueness(self):
        """Test detection of unclear scope."""
        service = ClarificationService(llm_client=None)

        statement = "Maybe we should consider using GraphQL"

        import re
        detected = False
        for pattern in service.VAGUE_PATTERNS['scope']:
            if re.search(pattern, statement, re.IGNORECASE):
                detected = True
                break

        assert detected, "Failed to detect scope vagueness in 'maybe'"

    def test_ignore_clear_statements(self):
        """Test that clear statements are not flagged as vague."""
        service = ClarificationService(llm_client=None)

        statement = "John will deploy the feature on October 25th at 2pm"

        import re
        detected = False
        for vague_type, patterns in service.VAGUE_PATTERNS.items():
            for pattern in patterns:
                if re.search(pattern, statement, re.IGNORECASE):
                    detected = True
                    break

        assert not detected, "Clear statement should not be flagged as vague"


class TestClarificationQuestions:
    """Test generation of clarifying questions."""

    def test_time_clarification_templates(self):
        """Test that time vagueness has appropriate question templates."""
        service = ClarificationService(llm_client=None)

        questions = service.CLARIFICATION_TEMPLATES['time']

        assert len(questions) > 0, "Should have time clarification templates"
        assert any('deadline' in q.lower() or 'when' in q.lower() for q in questions), \
            "Time questions should ask about deadlines/timing"

    def test_assignment_clarification_templates(self):
        """Test that assignment vagueness has appropriate question templates."""
        service = ClarificationService(llm_client=None)

        questions = service.CLARIFICATION_TEMPLATES['assignment']

        assert len(questions) > 0, "Should have assignment clarification templates"
        assert any('who' in q.lower() or 'owner' in q.lower() for q in questions), \
            "Assignment questions should ask about ownership"

    def test_detail_clarification_templates(self):
        """Test that detail vagueness has appropriate question templates."""
        service = ClarificationService(llm_client=None)

        questions = service.CLARIFICATION_TEMPLATES['detail']

        assert len(questions) > 0, "Should have detail clarification templates"
        assert any('specific' in q.lower() or 'detail' in q.lower() for q in questions), \
            "Detail questions should ask for specifics"

    def test_scope_clarification_templates(self):
        """Test that scope vagueness has appropriate question templates."""
        service = ClarificationService(llm_client=None)

        questions = service.CLARIFICATION_TEMPLATES['scope']

        assert len(questions) > 0, "Should have scope clarification templates"
        assert any('certain' in q.lower() or 'decision' in q.lower() for q in questions), \
            "Scope questions should ask about certainty"


class TestClarificationService:
    """Test the complete clarification service workflow."""

    @pytest.mark.asyncio
    async def test_service_instantiation(self):
        """Test that service can be instantiated."""
        service = ClarificationService(llm_client=None)

        assert service is not None
        assert hasattr(service, 'VAGUE_PATTERNS')
        assert hasattr(service, 'CLARIFICATION_TEMPLATES')

    def test_vagueness_types_covered(self):
        """Test that all four vagueness types are defined."""
        service = ClarificationService(llm_client=None)

        expected_types = ['time', 'assignment', 'detail', 'scope']

        assert all(t in service.VAGUE_PATTERNS for t in expected_types), \
            "All vagueness types should have patterns"
        assert all(t in service.CLARIFICATION_TEMPLATES for t in expected_types), \
            "All vagueness types should have question templates"


class TestPerformance:
    """Test performance characteristics of clarification detection."""

    def test_pattern_detection_speed(self):
        """Test that pattern-based detection is fast (<50ms)."""
        import time
        import re

        service = ClarificationService(llm_client=None)
        statement = "Someone should handle this soon"

        start = time.time()

        # Pattern detection (synchronous)
        detected = False
        for vague_type, patterns in service.VAGUE_PATTERNS.items():
            for pattern in patterns:
                if re.search(pattern, statement, re.IGNORECASE):
                    detected = True
                    break
            if detected:
                break

        elapsed = time.time() - start

        assert detected, "Should detect vagueness"
        assert elapsed < 0.05, f"Pattern detection should be <50ms, got {elapsed*1000:.1f}ms"


class TestEdgeCases:
    """Test edge cases and error handling."""

    @pytest.mark.asyncio
    async def test_empty_statement(self):
        """Test handling of empty statements."""
        service = ClarificationService(llm_client=None)

        result = await service.detect_vagueness("")

        assert result is None, "Empty statement should return None"

    @pytest.mark.asyncio
    async def test_very_short_statement(self):
        """Test handling of very short statements."""
        service = ClarificationService(llm_client=None)

        result = await service.detect_vagueness("OK")

        assert result is None, "Very short statement should return None"

    def test_multiple_vagueness_types(self):
        """Test statement with multiple types of vagueness."""
        import re

        service = ClarificationService(llm_client=None)
        statement = "Someone should maybe deploy this soon"

        detected_types = []
        for vague_type, patterns in service.VAGUE_PATTERNS.items():
            for pattern in patterns:
                if re.search(pattern, statement, re.IGNORECASE):
                    detected_types.append(vague_type)
                    break

        # Should detect at least 2 types (assignment: "someone", time: "soon", scope: "maybe")
        assert len(detected_types) >= 2, \
            f"Should detect multiple vagueness types, found: {detected_types}"
