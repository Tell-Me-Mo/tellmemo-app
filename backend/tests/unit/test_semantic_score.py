"""
Unit tests for SemanticSignals.get_score() - Semantic Score Calculation

Tests the semantic density score calculation to ensure proper weighting:
- Action + Time combo: 2.0 (highest urgency)
- Decisions + Assignments: 1.5
- Questions, Risks: 1.0 each
- Single action/time: 0.5 each
- Score ≥ 0.3 indicates high semantic density
"""

import pytest
from services.intelligence.adaptive_insight_processor import (
    AdaptiveInsightProcessor,
    SemanticSignals
)


class TestSemanticScoreCalculation:
    """Test suite for SemanticSignals.get_score() calculation."""

    def setup_method(self):
        """Initialize processor before each test."""
        self.processor = AdaptiveInsightProcessor()

    # Test edge cases
    def test_score_zero_for_empty_text(self):
        """Empty text should return score of 0.0."""
        signals = SemanticSignals(word_count=0)
        assert signals.get_score() == 0.0

    def test_score_zero_for_short_text(self):
        """Text with < 5 words should return score of 0.0."""
        signals = SemanticSignals(word_count=4)
        assert signals.get_score() == 0.0

    def test_score_zero_for_no_signals(self):
        """Text with no signals should return score of 0.0."""
        signals = SemanticSignals(
            word_count=10,
            has_action_verbs=False,
            has_time_references=False,
            has_questions=False,
            has_decisions=False,
            has_assignments=False,
            has_risks=False
        )
        assert signals.get_score() == 0.0

    # Test critical combinations (highest weight)
    def test_action_plus_time_combo_highest_priority(self):
        """Action + Time combo should score 2.0 / word_count (highest)."""
        # Example: "Complete the API by Friday" = 5 words
        signals = SemanticSignals(
            word_count=5,
            has_action_verbs=True,
            has_time_references=True
        )
        expected_score = 2.0 / 5  # 0.4
        assert signals.get_score() == pytest.approx(expected_score, rel=1e-9)

    def test_action_plus_time_different_word_count(self):
        """Action + Time combo with different word counts."""
        # 10 words: "We need to complete the implementation by Friday morning deadline"
        signals = SemanticSignals(
            word_count=10,
            has_action_verbs=True,
            has_time_references=True
        )
        expected_score = 2.0 / 10  # 0.2
        assert signals.get_score() == pytest.approx(expected_score, rel=1e-9)

    def test_decision_plus_assignment_combo(self):
        """Decision + Assignment combo should score 1.5 / word_count."""
        # Example: "We decided John will implement GraphQL" = 6 words
        signals = SemanticSignals(
            word_count=6,
            has_decisions=True,
            has_assignments=True
        )
        expected_score = 1.5 / 6  # 0.25
        assert signals.get_score() == pytest.approx(expected_score, rel=1e-9)

    def test_decision_plus_assignment_different_word_count(self):
        """Decision + Assignment combo with different word counts."""
        # 12 words
        signals = SemanticSignals(
            word_count=12,
            has_decisions=True,
            has_assignments=True
        )
        expected_score = 1.5 / 12  # 0.125
        assert signals.get_score() == pytest.approx(expected_score, rel=1e-9)

    def test_combo_takes_precedence_over_individual_signals(self):
        """When combo exists, individual signals should not add to score."""
        # Action + Time combo should ONLY score 2.0, not 2.0 + 1.0 (question)
        signals = SemanticSignals(
            word_count=8,
            has_action_verbs=True,
            has_time_references=True,
            has_questions=True,  # This should be ignored
            has_risks=True       # This should be ignored
        )
        expected_score = 2.0 / 8  # 0.25 (only combo, not 2.0+1.0+1.0)
        assert signals.get_score() == pytest.approx(expected_score, rel=1e-9)

    # Test individual signals (when no combo)
    def test_questions_signal_only(self):
        """Question signal only should score 1.0 / word_count."""
        signals = SemanticSignals(
            word_count=5,
            has_questions=True
        )
        expected_score = 1.0 / 5  # 0.2
        assert signals.get_score() == pytest.approx(expected_score, rel=1e-9)

    def test_risks_signal_only(self):
        """Risk signal only should score 1.0 / word_count."""
        signals = SemanticSignals(
            word_count=6,
            has_risks=True
        )
        expected_score = 1.0 / 6  # ~0.167
        assert signals.get_score() == pytest.approx(expected_score, rel=1e-9)

    def test_action_verb_signal_only(self):
        """Action verb only should score 0.5 / word_count."""
        signals = SemanticSignals(
            word_count=8,
            has_action_verbs=True
        )
        expected_score = 0.5 / 8  # 0.0625
        assert signals.get_score() == pytest.approx(expected_score, rel=1e-9)

    def test_time_reference_signal_only(self):
        """Time reference only should score 0.5 / word_count."""
        signals = SemanticSignals(
            word_count=7,
            has_time_references=True
        )
        expected_score = 0.5 / 7  # ~0.071
        assert signals.get_score() == pytest.approx(expected_score, rel=1e-9)

    def test_multiple_individual_signals(self):
        """Multiple individual signals (no combo) should sum."""
        # Question + Risk + Action (no time) = 1.0 + 1.0 + 0.5 = 2.5
        signals = SemanticSignals(
            word_count=10,
            has_questions=True,
            has_risks=True,
            has_action_verbs=True
        )
        expected_score = (1.0 + 1.0 + 0.5) / 10  # 0.25
        assert signals.get_score() == pytest.approx(expected_score, rel=1e-9)

    def test_questions_plus_risks(self):
        """Questions + Risks should sum to 2.0."""
        signals = SemanticSignals(
            word_count=8,
            has_questions=True,
            has_risks=True
        )
        expected_score = (1.0 + 1.0) / 8  # 0.25
        assert signals.get_score() == pytest.approx(expected_score, rel=1e-9)

    def test_action_plus_time_separate_no_combo(self):
        """Action only (no time) should score 0.5, not 2.0."""
        signals = SemanticSignals(
            word_count=6,
            has_action_verbs=True,
            has_time_references=False  # No time = no combo
        )
        expected_score = 0.5 / 6  # ~0.083
        assert signals.get_score() == pytest.approx(expected_score, rel=1e-9)

    # Test threshold ≥ 0.3 for high semantic density
    def test_high_density_threshold_action_plus_time(self):
        """Action + Time with ≤ 6.67 words should exceed 0.3 threshold."""
        # 2.0 / x >= 0.3 => x <= 6.67
        signals = SemanticSignals(
            word_count=6,
            has_action_verbs=True,
            has_time_references=True
        )
        score = signals.get_score()
        assert score >= 0.3
        assert score == pytest.approx(2.0 / 6, rel=1e-9)  # 0.333

    def test_high_density_threshold_decision_plus_assignment(self):
        """Decision + Assignment with ≤ 5 words should exceed 0.3 threshold."""
        # 1.5 / x >= 0.3 => x <= 5
        signals = SemanticSignals(
            word_count=5,
            has_decisions=True,
            has_assignments=True
        )
        score = signals.get_score()
        assert score >= 0.3
        assert score == pytest.approx(1.5 / 5, rel=1e-9)  # 0.3

    def test_low_density_below_threshold(self):
        """Long text with few signals should be below 0.3 threshold."""
        # Action only (0.5) with 20 words = 0.025 (well below 0.3)
        signals = SemanticSignals(
            word_count=20,
            has_action_verbs=True
        )
        score = signals.get_score()
        assert score < 0.3
        assert score == pytest.approx(0.5 / 20, rel=1e-9)  # 0.025

    def test_borderline_high_density(self):
        """Test borderline case near 0.3 threshold."""
        # 1.5 / 5 = 0.3 (exactly at threshold)
        signals = SemanticSignals(
            word_count=5,
            has_decisions=True,
            has_assignments=True
        )
        assert signals.get_score() == pytest.approx(0.3, rel=1e-9)

    # Test real-world examples
    def test_real_example_action_plus_deadline(self):
        """Real example: 'Complete the API implementation by Friday.'"""
        text = "Complete the API implementation by Friday."
        signals = self.processor.analyze_chunk(text)

        # Should detect action + time
        assert signals.has_action_verbs is True
        assert signals.has_time_references is True

        # Score = 2.0 / word_count
        score = signals.get_score()
        assert score >= 0.3  # High density
        expected_score = 2.0 / signals.word_count
        assert score == pytest.approx(expected_score, rel=1e-9)

    def test_real_example_question_about_risk(self):
        """Real example: 'What's the risk of this being blocked?'"""
        text = "What's the risk of this being blocked?"
        signals = self.processor.analyze_chunk(text)

        # Should detect question + risk
        assert signals.has_questions is True
        assert signals.has_risks is True

        # Score = (1.0 + 1.0) / word_count = 2.0 / word_count
        score = signals.get_score()
        expected_score = 2.0 / signals.word_count
        assert score == pytest.approx(expected_score, rel=1e-9)

    def test_real_example_decision_with_assignment(self):
        """Real example: 'We decided John, please handle the GraphQL migration.'"""
        text = "We decided John, please handle the GraphQL migration."
        signals = self.processor.analyze_chunk(text)

        # Should detect decision + assignment
        assert signals.has_decisions is True
        assert signals.has_assignments is True

        # Score = 1.5 / word_count
        score = signals.get_score()
        expected_score = 1.5 / signals.word_count
        assert score == pytest.approx(expected_score, rel=1e-9)

    def test_real_example_low_density_conversation(self):
        """Real example: Low density conversation with no semantic signals."""
        text = "The weather is nice and everyone seems happy about the office environment."
        signals = self.processor.analyze_chunk(text)

        # Should have no semantic signals (avoid "today" which matches time pattern)
        assert signals.has_action_verbs is False
        assert signals.has_time_references is False
        assert signals.has_questions is False
        assert signals.has_decisions is False
        assert signals.has_assignments is False
        assert signals.has_risks is False

        # Score should be 0.0
        assert signals.get_score() == 0.0

    def test_real_example_medium_density(self):
        """Real example: Medium density with action verb and time reference."""
        text = "We need to implement this feature by next week deadline."
        signals = self.processor.analyze_chunk(text)

        # Should detect action (implement) + time (next week, deadline)
        assert signals.has_action_verbs is True
        assert signals.has_time_references is True

        # Score = 2.0 / word_count (action + time combo)
        score = signals.get_score()
        expected_score = 2.0 / signals.word_count
        assert score == pytest.approx(expected_score, rel=1e-9)

    # Test normalization by word count
    def test_normalization_prevents_score_inflation(self):
        """Longer text with same signals should have proportionally lower score."""
        # Short text: 6 words with action + time
        short_signals = SemanticSignals(
            word_count=6,
            has_action_verbs=True,
            has_time_references=True
        )

        # Long text: 12 words with action + time
        long_signals = SemanticSignals(
            word_count=12,
            has_action_verbs=True,
            has_time_references=True
        )

        short_score = short_signals.get_score()  # 2.0 / 6 = 0.333
        long_score = long_signals.get_score()    # 2.0 / 12 = 0.167

        # Long text should have exactly half the score
        assert short_score == pytest.approx(2 * long_score, rel=1e-9)

    def test_score_never_negative(self):
        """Score should never be negative."""
        # All possible signal combinations should produce non-negative scores
        for has_actions in [True, False]:
            for has_time in [True, False]:
                for has_decisions in [True, False]:
                    for has_assignments in [True, False]:
                        for has_questions in [True, False]:
                            for has_risks in [True, False]:
                                signals = SemanticSignals(
                                    word_count=10,
                                    has_action_verbs=has_actions,
                                    has_time_references=has_time,
                                    has_decisions=has_decisions,
                                    has_assignments=has_assignments,
                                    has_questions=has_questions,
                                    has_risks=has_risks
                                )
                                assert signals.get_score() >= 0.0


class TestSemanticScoreIntegration:
    """Test semantic score calculation integrated with get_stats()."""

    def setup_method(self):
        """Initialize processor before each test."""
        self.processor = AdaptiveInsightProcessor()

    def test_get_stats_includes_semantic_score(self):
        """get_stats() should include semantic_score."""
        text = "Complete the API implementation by Friday."
        stats = self.processor.get_stats(text)

        assert 'semantic_score' in stats
        assert stats['semantic_score'] > 0.0
        assert stats['semantic_score'] >= 0.3  # High density

    def test_get_stats_semantic_score_matches_signals(self):
        """Semantic score in get_stats() should match SemanticSignals.get_score()."""
        text = "We decided John, please handle this task."

        signals = self.processor.analyze_chunk(text)
        stats = self.processor.get_stats(text)

        assert stats['semantic_score'] == pytest.approx(signals.get_score(), rel=1e-9)

    def test_get_stats_zero_score_for_no_signals(self):
        """get_stats() should show 0.0 score for text with no signals."""
        text = "The weather is nice and everyone likes it."
        stats = self.processor.get_stats(text)

        assert stats['semantic_score'] == 0.0


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
