"""
Transcript Validator Service

Filters empty, noise-only, and low-quality transcripts before processing.

Purpose:
- Detect transcription errors (noise markers, gibberish)
- Validate content quality (minimum length, meaningful words)
- Prevent wasted LLM calls on invalid transcripts
- Improve overall system accuracy

Integration:
- Called in WebSocket router before insight extraction
- Works with AdaptiveInsightProcessor for intelligent filtering
- Logs filtered transcripts for monitoring

Performance:
- <1ms per validation (regex-based)
- No external API calls
- Zero cost filtering layer
"""

import re
import string
from dataclasses import dataclass
from enum import Enum
from typing import Optional, Set
from utils.logger import get_logger

logger = get_logger(__name__)


class TranscriptQuality(Enum):
    """Quality classification for transcripts."""
    VALID = "valid"              # Clean, meaningful content
    EMPTY = "empty"              # No content
    NOISE = "noise"              # Transcription noise markers
    TOO_SHORT = "too_short"      # Less than minimum length
    PUNCTUATION_ONLY = "punctuation_only"  # Only punctuation/whitespace
    LOW_WORD_RATIO = "low_word_ratio"      # Too few meaningful words


@dataclass
class ValidationResult:
    """Result of transcript validation."""
    is_valid: bool
    quality: TranscriptQuality
    reason: str
    original_text: str
    word_count: int
    char_count: int


class TranscriptValidator:
    """
    Validates transcript quality before insight extraction.

    Filters:
    1. Empty transcripts (0-2 characters)
    2. Transcription noise markers ([music], [inaudible], etc.)
    3. Punctuation-only content
    4. Too short transcripts (< minimum words)
    5. Low meaningful word ratio

    Configuration:
    - MIN_WORD_COUNT: Minimum words for valid transcript
    - MIN_MEANINGFUL_WORD_RATIO: Minimum ratio of meaningful words
    """

    # Transcription noise patterns
    NOISE_PATTERNS = [
        r'^\[music\]$',
        r'^\[background noise\]$',
        r'^\[inaudible\]$',
        r'^\[silence\]$',
        r'^\[no speech detected\]$',
        r'^\[transcription failed\]$',
        r'^♪.*♪$',
        r'^\[.*\]$',  # Generic bracketed noise markers
    ]

    # Common filler words (used for meaningful word ratio calculation)
    FILLER_WORDS: Set[str] = {
        'um', 'uh', 'er', 'ah', 'eh', 'hmm', 'hm',
        'like', 'you know', 'i mean', 'sort of', 'kind of',
        'actually', 'basically', 'literally', 'right', 'okay', 'ok'
    }

    # Configuration
    MIN_WORD_COUNT = 3  # Minimum words to be considered valid
    MIN_MEANINGFUL_WORD_RATIO = 0.3  # At least 30% of words should be meaningful

    def __init__(self):
        """Initialize validator with compiled regex patterns."""
        self.noise_patterns_compiled = [
            re.compile(pattern, re.IGNORECASE)
            for pattern in self.NOISE_PATTERNS
        ]

    def validate(self, transcript: str) -> ValidationResult:
        """
        Validate transcript quality.

        Args:
            transcript: Raw transcript text from transcription service

        Returns:
            ValidationResult with is_valid flag and detailed metrics
        """
        # Store original for logging
        original_text = transcript
        text = transcript.strip()

        # Get basic metrics
        char_count = len(text)
        words = self._tokenize_words(text)
        word_count = len(words)

        # Check 1: Empty transcript
        if not text or char_count < 3:
            return ValidationResult(
                is_valid=False,
                quality=TranscriptQuality.EMPTY,
                reason="Transcript is empty or too short (< 3 characters)",
                original_text=original_text,
                word_count=word_count,
                char_count=char_count
            )

        # Check 2: Noise markers
        for pattern in self.noise_patterns_compiled:
            if pattern.match(text):
                return ValidationResult(
                    is_valid=False,
                    quality=TranscriptQuality.NOISE,
                    reason=f"Transcript contains noise marker: '{text}'",
                    original_text=original_text,
                    word_count=word_count,
                    char_count=char_count
                )

        # Check 3: Punctuation-only
        if all(c in string.punctuation + string.whitespace for c in text):
            return ValidationResult(
                is_valid=False,
                quality=TranscriptQuality.PUNCTUATION_ONLY,
                reason="Transcript contains only punctuation and whitespace",
                original_text=original_text,
                word_count=word_count,
                char_count=char_count
            )

        # Check 4: Too short (word count)
        if word_count < self.MIN_WORD_COUNT:
            return ValidationResult(
                is_valid=False,
                quality=TranscriptQuality.TOO_SHORT,
                reason=f"Transcript too short ({word_count} words, minimum: {self.MIN_WORD_COUNT})",
                original_text=original_text,
                word_count=word_count,
                char_count=char_count
            )

        # Check 5: Low meaningful word ratio
        meaningful_word_count = self._count_meaningful_words(words)
        meaningful_ratio = meaningful_word_count / word_count if word_count > 0 else 0

        if meaningful_ratio < self.MIN_MEANINGFUL_WORD_RATIO:
            return ValidationResult(
                is_valid=False,
                quality=TranscriptQuality.LOW_WORD_RATIO,
                reason=f"Too few meaningful words ({meaningful_ratio:.1%}, minimum: {self.MIN_MEANINGFUL_WORD_RATIO:.1%})",
                original_text=original_text,
                word_count=word_count,
                char_count=char_count
            )

        # All checks passed
        return ValidationResult(
            is_valid=True,
            quality=TranscriptQuality.VALID,
            reason="Transcript is valid",
            original_text=original_text,
            word_count=word_count,
            char_count=char_count
        )

    def _tokenize_words(self, text: str) -> list[str]:
        """
        Tokenize text into words (case-insensitive, alphanumeric only).

        Args:
            text: Input text

        Returns:
            List of lowercase words
        """
        # Remove punctuation and split on whitespace
        words = re.findall(r'\b\w+\b', text.lower())
        return words

    def _count_meaningful_words(self, words: list[str]) -> int:
        """
        Count meaningful words (excluding filler words).

        Args:
            words: List of words (lowercase)

        Returns:
            Count of meaningful words
        """
        meaningful_count = 0

        for word in words:
            # Skip filler words
            if word in self.FILLER_WORDS:
                continue

            # Skip very short words (likely articles, prepositions)
            if len(word) < 2:
                continue

            meaningful_count += 1

        return meaningful_count

    def is_valid(self, transcript: str) -> bool:
        """
        Quick validation check (returns only boolean).

        Args:
            transcript: Raw transcript text

        Returns:
            True if transcript is valid, False otherwise
        """
        return self.validate(transcript).is_valid


# Singleton instance
_validator_instance: Optional[TranscriptValidator] = None


def get_transcript_validator() -> TranscriptValidator:
    """
    Get singleton instance of TranscriptValidator.

    Returns:
        TranscriptValidator instance
    """
    global _validator_instance
    if _validator_instance is None:
        _validator_instance = TranscriptValidator()
        logger.info("TranscriptValidator initialized")
    return _validator_instance


# Export public API
__all__ = [
    'TranscriptValidator',
    'TranscriptQuality',
    'ValidationResult',
    'get_transcript_validator'
]
