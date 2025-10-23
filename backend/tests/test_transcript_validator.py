"""
Unit tests for TranscriptValidator service.

Tests noise detection, quality validation, and edge cases.
"""

import pytest
from services.intelligence.transcript_validator import (
    TranscriptValidator,
    TranscriptQuality,
    get_transcript_validator
)


class TestTranscriptValidator:
    """Test suite for TranscriptValidator."""

    @pytest.fixture
    def validator(self):
        """Get validator instance."""
        return get_transcript_validator()

    # ==================== Noise Detection Tests ====================

    def test_detects_music_noise(self, validator):
        """Should detect [music] as noise."""
        result = validator.validate("[music]")
        assert not result.is_valid
        assert result.quality == TranscriptQuality.NOISE
        assert "noise marker" in result.reason.lower()

    def test_detects_background_noise(self, validator):
        """Should detect [background noise] as noise."""
        result = validator.validate("[background noise]")
        assert not result.is_valid
        assert result.quality == TranscriptQuality.NOISE

    def test_detects_inaudible_noise(self, validator):
        """Should detect [inaudible] as noise."""
        result = validator.validate("[inaudible]")
        assert not result.is_valid
        assert result.quality == TranscriptQuality.NOISE

    def test_detects_silence_noise(self, validator):
        """Should detect [silence] as noise."""
        result = validator.validate("[silence]")
        assert not result.is_valid
        assert result.quality == TranscriptQuality.NOISE

    def test_detects_musical_notation(self, validator):
        """Should detect ♪...♪ as noise."""
        result = validator.validate("♪ la la la ♪")
        assert not result.is_valid
        assert result.quality == TranscriptQuality.NOISE

    def test_detects_no_speech_detected(self, validator):
        """Should detect [No speech detected] as noise."""
        result = validator.validate("[No speech detected]")
        assert not result.is_valid
        assert result.quality == TranscriptQuality.NOISE

    def test_detects_transcription_failed(self, validator):
        """Should detect [Transcription failed] as noise."""
        result = validator.validate("[Transcription failed]")
        assert not result.is_valid
        assert result.quality == TranscriptQuality.NOISE

    def test_detects_generic_bracketed_markers(self, validator):
        """Should detect generic [marker] patterns as noise."""
        result = validator.validate("[unknown marker]")
        assert not result.is_valid
        assert result.quality == TranscriptQuality.NOISE

    # ==================== Empty/Short Tests ====================

    def test_detects_empty_string(self, validator):
        """Should detect empty string."""
        result = validator.validate("")
        assert not result.is_valid
        assert result.quality == TranscriptQuality.EMPTY

    def test_detects_whitespace_only(self, validator):
        """Should detect whitespace-only string."""
        result = validator.validate("   \n\t  ")
        assert not result.is_valid
        assert result.quality == TranscriptQuality.EMPTY

    def test_detects_too_short_chars(self, validator):
        """Should detect strings shorter than 3 chars."""
        result = validator.validate("ab")
        assert not result.is_valid
        assert result.quality == TranscriptQuality.EMPTY

    def test_detects_too_short_words(self, validator):
        """Should detect transcripts with < 3 words."""
        result = validator.validate("hello there")
        assert not result.is_valid
        assert result.quality == TranscriptQuality.TOO_SHORT
        assert result.word_count == 2

    # ==================== Punctuation-Only Tests ====================

    def test_detects_punctuation_only(self, validator):
        """Should detect punctuation-only content."""
        result = validator.validate("... !!! ???")
        assert not result.is_valid
        assert result.quality == TranscriptQuality.PUNCTUATION_ONLY

    def test_detects_mixed_punctuation_whitespace(self, validator):
        """Should detect mixed punctuation and whitespace."""
        result = validator.validate(". , ; : ! ?")
        assert not result.is_valid
        assert result.quality == TranscriptQuality.PUNCTUATION_ONLY

    # ==================== Low Word Ratio Tests ====================

    def test_detects_low_meaningful_word_ratio(self, validator):
        """Should detect transcripts with too many filler words."""
        result = validator.validate("um uh like basically you know")
        assert not result.is_valid
        assert result.quality == TranscriptQuality.LOW_WORD_RATIO
        assert "meaningful words" in result.reason.lower()

    def test_filler_words_only(self, validator):
        """Should reject filler words only."""
        result = validator.validate("um um um uh uh uh")
        assert not result.is_valid
        assert result.quality == TranscriptQuality.LOW_WORD_RATIO

    # ==================== Valid Transcript Tests ====================

    def test_accepts_valid_short_statement(self, validator):
        """Should accept valid short statement."""
        result = validator.validate("Let's do it")
        assert result.is_valid
        assert result.quality == TranscriptQuality.VALID
        assert result.word_count == 3

    def test_accepts_valid_action_item(self, validator):
        """Should accept valid action item."""
        result = validator.validate("John will finish the API by Friday")
        assert result.is_valid
        assert result.quality == TranscriptQuality.VALID
        assert result.word_count == 7

    def test_accepts_valid_question(self, validator):
        """Should accept valid question."""
        result = validator.validate("What's the budget for Q4?")
        assert result.is_valid
        assert result.quality == TranscriptQuality.VALID

    def test_accepts_valid_decision(self, validator):
        """Should accept valid decision."""
        result = validator.validate("We decided to use GraphQL for all APIs")
        assert result.is_valid
        assert result.quality == TranscriptQuality.VALID

    def test_accepts_statement_with_some_fillers(self, validator):
        """Should accept statements with reasonable filler word ratio."""
        result = validator.validate("um so basically we need to fix the authentication bug")
        assert result.is_valid
        assert result.quality == TranscriptQuality.VALID

    def test_accepts_long_meaningful_content(self, validator):
        """Should accept long meaningful content."""
        text = "The project is on track and we've completed the authentication module. Next, we'll implement the payment gateway integration."
        result = validator.validate(text)
        assert result.is_valid
        assert result.quality == TranscriptQuality.VALID
        assert result.word_count > 10

    # ==================== Edge Cases ====================

    def test_handles_case_insensitivity(self, validator):
        """Should handle case-insensitive noise detection."""
        result = validator.validate("[MUSIC]")
        assert not result.is_valid
        assert result.quality == TranscriptQuality.NOISE

    def test_preserves_original_text(self, validator):
        """Should preserve original text in result."""
        original = "  Test content  "
        result = validator.validate(original)
        assert result.original_text == original

    def test_counts_words_correctly(self, validator):
        """Should count words correctly."""
        result = validator.validate("one two three four five")
        assert result.word_count == 5

    def test_counts_chars_correctly(self, validator):
        """Should count characters correctly (stripped)."""
        result = validator.validate("  hello  ")
        assert result.char_count == 5  # "hello" length

    def test_singleton_pattern(self):
        """Should return same instance (singleton)."""
        validator1 = get_transcript_validator()
        validator2 = get_transcript_validator()
        assert validator1 is validator2

    def test_quick_is_valid_method(self, validator):
        """Should provide quick boolean check."""
        assert validator.is_valid("Let's finish the API by Friday")
        assert not validator.is_valid("[music]")
        assert not validator.is_valid("um uh like")

    # ==================== Meaningful Word Analysis ====================

    def test_filters_short_words(self, validator):
        """Should not count very short words as meaningful."""
        words = ["a", "to", "testing", "functionality"]
        meaningful_count = validator._count_meaningful_words(words)
        # "testing" and "functionality" should count (>= 2 chars, not filler)
        assert meaningful_count == 2

    def test_filters_filler_words(self, validator):
        """Should not count filler words as meaningful."""
        words = ["um", "uh", "like", "hello", "world"]
        meaningful_count = validator._count_meaningful_words(words)
        # Only "hello" and "world" should count
        assert meaningful_count == 2

    def test_tokenizes_correctly(self, validator):
        """Should tokenize words correctly."""
        words = validator._tokenize_words("Hello, world! How are you?")
        assert len(words) == 5
        assert all(word.islower() for word in words)
        assert "hello" in words
        assert "world" in words
