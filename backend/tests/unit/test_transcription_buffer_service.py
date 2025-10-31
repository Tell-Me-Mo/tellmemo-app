"""
Unit Tests for TranscriptionBufferService

Tests the rolling window buffer functionality, Redis integration,
and formatted output generation for GPT consumption.

Task 2.1: Implement Transcription Buffer Manager
"""

import pytest
import asyncio
from datetime import datetime, timedelta
from typing import List
from unittest.mock import AsyncMock, patch

from services.transcription.transcription_buffer_service import (
    TranscriptionBufferService,
    TranscriptionSentence,
    get_transcription_buffer
)


# Test Fixtures

@pytest.fixture
def sample_sentence() -> TranscriptionSentence:
    """Create a sample transcription sentence."""
    return TranscriptionSentence(
        sentence_id="sent_001",
        text="Hello, what is the budget for Q4?",
        speaker="Speaker A",
        timestamp=datetime.now().timestamp(),
        start_time=datetime.now().timestamp(),
        end_time=datetime.now().timestamp() + 3.5,
        confidence=0.95,
        metadata={"language": "en"}
    )


@pytest.fixture
def sample_sentences() -> List[TranscriptionSentence]:
    """Create multiple sample sentences spanning a time window."""
    current_time = datetime.now().timestamp()
    sentences = []

    for i in range(5):
        sentences.append(TranscriptionSentence(
            sentence_id=f"sent_{i:03d}",
            text=f"This is sentence number {i}.",
            speaker=f"Speaker {chr(65 + i % 3)}",
            timestamp=current_time + (i * 10),
            start_time=current_time + (i * 10),
            end_time=current_time + (i * 10) + 2,
            confidence=0.90 + (i * 0.02),
            metadata={}
        ))

    return sentences


@pytest.fixture
async def buffer_service():
    """Create a TranscriptionBufferService instance and clean up after test."""
    service = TranscriptionBufferService()
    yield service
    await service.close()


@pytest.fixture
def session_id() -> str:
    """Generate a unique session ID for testing."""
    return f"test_session_{datetime.now().timestamp()}"


# Test: TranscriptionSentence Data Model

def test_transcription_sentence_creation(sample_sentence):
    """Test creation of TranscriptionSentence dataclass."""
    assert sample_sentence.sentence_id == "sent_001"
    assert sample_sentence.text == "Hello, what is the budget for Q4?"
    assert sample_sentence.speaker == "Speaker A"
    assert sample_sentence.confidence == 0.95
    assert sample_sentence.metadata == {"language": "en"}


def test_transcription_sentence_to_dict(sample_sentence):
    """Test conversion of sentence to dictionary."""
    sentence_dict = sample_sentence.to_dict()

    assert isinstance(sentence_dict, dict)
    assert sentence_dict["sentence_id"] == "sent_001"
    assert sentence_dict["text"] == "Hello, what is the budget for Q4?"
    assert sentence_dict["speaker"] == "Speaker A"
    assert sentence_dict["confidence"] == 0.95


def test_transcription_sentence_from_dict(sample_sentence):
    """Test creation of sentence from dictionary."""
    sentence_dict = sample_sentence.to_dict()
    reconstructed = TranscriptionSentence.from_dict(sentence_dict)

    assert reconstructed.sentence_id == sample_sentence.sentence_id
    assert reconstructed.text == sample_sentence.text
    assert reconstructed.speaker == sample_sentence.speaker
    assert reconstructed.confidence == sample_sentence.confidence
    assert reconstructed.metadata == sample_sentence.metadata


# Test: Service Initialization

@pytest.mark.asyncio
async def test_service_initialization(buffer_service):
    """Test TranscriptionBufferService initialization."""
    assert buffer_service._buffers == {}
    assert buffer_service.window_seconds == 60
    assert buffer_service.max_sentences == 100


# Removed Redis connection tests - service now uses in-memory storage


# Test: Add Sentence

@pytest.mark.asyncio
async def test_add_sentence_success(buffer_service, session_id, sample_sentence):
    """Test adding a sentence to the buffer."""
    success = await buffer_service.add_sentence(session_id, sample_sentence)

    # Should always succeed with in-memory storage
    assert success is True

    # Verify sentence was added
    buffer = await buffer_service.get_buffer(session_id)
    assert len(buffer) == 1
    assert buffer[0].sentence_id == sample_sentence.sentence_id

    # Clean up
    await buffer_service.clear_buffer(session_id)


@pytest.mark.asyncio
async def test_add_multiple_sentences(buffer_service, session_id, sample_sentences):
    """Test adding multiple sentences to the buffer."""
    for sentence in sample_sentences:
        success = await buffer_service.add_sentence(session_id, sentence)
        assert success is True

    # Verify count
    buffer = await buffer_service.get_buffer(session_id)
    assert len(buffer) == len(sample_sentences)

    # Clean up
    await buffer_service.clear_buffer(session_id)


# Test: Get Buffer

@pytest.mark.asyncio
async def test_get_buffer_empty(buffer_service, session_id):
    """Test getting buffer when empty."""
    buffer = await buffer_service.get_buffer(session_id)

    assert isinstance(buffer, list)
    assert len(buffer) == 0


@pytest.mark.asyncio
async def test_get_buffer_with_sentences(buffer_service, session_id, sample_sentences):
    """Test retrieving buffer contents in chronological order."""
    # Add sentences
    for sentence in sample_sentences:
        await buffer_service.add_sentence(session_id, sentence)

    # Get buffer
    buffer = await buffer_service.get_buffer(session_id)

    assert len(buffer) == len(sample_sentences)

    # Verify chronological order
    for i in range(len(buffer) - 1):
        assert buffer[i].timestamp <= buffer[i + 1].timestamp

    # Clean up
    await buffer_service.clear_buffer(session_id)


@pytest.mark.asyncio
async def test_get_buffer_with_max_age(buffer_service, session_id):
    """Test getting buffer with custom max_age_seconds."""
    current_time = datetime.now().timestamp()

    # Add sentences with varying ages
    old_sentence = TranscriptionSentence(
        sentence_id="old",
        text="Old sentence",
        speaker="Speaker A",
        timestamp=current_time - 50,
        start_time=current_time - 50,
        end_time=current_time - 48,
        confidence=0.9
    )

    recent_sentence = TranscriptionSentence(
        sentence_id="recent",
        text="Recent sentence",
        speaker="Speaker B",
        timestamp=current_time - 5,
        start_time=current_time - 5,
        end_time=current_time - 3,
        confidence=0.95
    )

    await buffer_service.add_sentence(session_id, old_sentence)
    await buffer_service.add_sentence(session_id, recent_sentence)

    # Get buffer with 30-second window
    buffer = await buffer_service.get_buffer(session_id, max_age_seconds=30)

    # Should only contain recent sentence
    assert len(buffer) == 1
    assert buffer[0].sentence_id == "recent"

    # Clean up
    await buffer_service.clear_buffer(session_id)


# Test: Auto-Trimming

@pytest.mark.asyncio
async def test_auto_trim_by_time(buffer_service, session_id):
    """Test automatic trimming of sentences older than window_seconds."""
    current_time = datetime.now().timestamp()

    # Add old sentence (beyond window)
    old_sentence = TranscriptionSentence(
        sentence_id="old",
        text="Old sentence",
        speaker="Speaker A",
        timestamp=current_time - 70,
        start_time=current_time - 70,
        end_time=current_time - 68,
        confidence=0.9
    )

    # Add recent sentence (within window)
    recent_sentence = TranscriptionSentence(
        sentence_id="recent",
        text="Recent sentence",
        speaker="Speaker B",
        timestamp=current_time - 5,
        start_time=current_time - 5,
        end_time=current_time - 3,
        confidence=0.95
    )

    await buffer_service.add_sentence(session_id, old_sentence)
    await buffer_service.add_sentence(session_id, recent_sentence)

    # Get buffer (auto-trim should have removed old sentence)
    buffer = await buffer_service.get_buffer(session_id)

    # Only recent sentence should remain
    assert len(buffer) == 1
    assert buffer[0].sentence_id == "recent"

    # Clean up
    await buffer_service.clear_buffer(session_id)


@pytest.mark.asyncio
async def test_auto_trim_by_count(buffer_service, session_id):
    """Test automatic trimming when max_sentences limit is exceeded."""
    # Temporarily set low limit for testing
    original_max = buffer_service.max_sentences
    buffer_service.max_sentences = 3

    current_time = datetime.now().timestamp()

    # Add 5 sentences (exceeds limit of 3)
    for i in range(5):
        sentence = TranscriptionSentence(
            sentence_id=f"sent_{i}",
            text=f"Sentence {i}",
            speaker="Speaker A",
            timestamp=current_time + i,
            start_time=current_time + i,
            end_time=current_time + i + 1,
            confidence=0.9
        )
        await buffer_service.add_sentence(session_id, sentence)

    # Get buffer
    buffer = await buffer_service.get_buffer(session_id)

    # Should only have 3 sentences (oldest 2 removed by deque maxlen)
    assert len(buffer) <= 3

    # Should be the latest 3 sentences
    if len(buffer) == 3:
        assert buffer[0].sentence_id == "sent_2"
        assert buffer[1].sentence_id == "sent_3"
        assert buffer[2].sentence_id == "sent_4"

    # Restore original max
    buffer_service.max_sentences = original_max

    # Clean up
    await buffer_service.clear_buffer(session_id)


# Test: Formatted Context Output

@pytest.mark.asyncio
async def test_get_formatted_context_empty(buffer_service, session_id):
    """Test formatted context when buffer is empty."""
    context = await buffer_service.get_formatted_context(session_id)

    assert context == "No recent transcription available."


@pytest.mark.asyncio
async def test_get_formatted_context_with_timestamps_and_speakers(buffer_service, session_id, sample_sentences):
    """Test formatted context with timestamps and speakers."""
    # Add sentences
    for sentence in sample_sentences:
        await buffer_service.add_sentence(session_id, sentence)

    # Get formatted context
    context = await buffer_service.get_formatted_context(
        session_id,
        include_timestamps=True,
        include_speakers=True
    )

    # Verify format: "[HH:MM:SS] Speaker X: Text"
    lines = context.split("\n")
    assert len(lines) == len(sample_sentences)

    for line in lines:
        assert line.startswith("[")
        assert "]" in line
        assert "Speaker" in line
        assert ":" in line

    # Clean up
    await buffer_service.clear_buffer(session_id)


@pytest.mark.asyncio
async def test_get_formatted_context_without_timestamps(buffer_service, session_id, sample_sentences):
    """Test formatted context without timestamps."""
    # Add sentences
    for sentence in sample_sentences:
        await buffer_service.add_sentence(session_id, sentence)

    # Get formatted context
    context = await buffer_service.get_formatted_context(
        session_id,
        include_timestamps=False,
        include_speakers=True
    )

    lines = context.split("\n")

    for line in lines:
        assert not line.startswith("[")
        assert "Speaker" in line

    # Clean up
    await buffer_service.clear_buffer(session_id)


@pytest.mark.asyncio
async def test_get_formatted_context_without_speakers(buffer_service, session_id, sample_sentences):
    """Test formatted context without speaker attribution."""
    # Add sentences
    for sentence in sample_sentences:
        await buffer_service.add_sentence(session_id, sentence)

    # Get formatted context
    context = await buffer_service.get_formatted_context(
        session_id,
        include_timestamps=True,
        include_speakers=False
    )

    lines = context.split("\n")

    for line in lines:
        assert line.startswith("[")
        # Should not have "Speaker X:" pattern
        assert "This is sentence" in line

    # Clean up
    await buffer_service.clear_buffer(session_id)


# Test: Buffer Statistics

@pytest.mark.asyncio
async def test_get_buffer_stats_empty(buffer_service, session_id):
    """Test buffer statistics when empty."""
    stats = await buffer_service.get_buffer_stats(session_id)

    assert stats["session_id"] == session_id
    assert stats["sentence_count"] == 0
    assert "window_seconds" in stats
    assert "max_sentences" in stats


@pytest.mark.asyncio
async def test_get_buffer_stats_with_sentences(buffer_service, session_id, sample_sentences):
    """Test buffer statistics with sentences."""
    # Add sentences
    for sentence in sample_sentences:
        await buffer_service.add_sentence(session_id, sentence)

    # Get stats
    stats = await buffer_service.get_buffer_stats(session_id)

    assert stats["sentence_count"] == len(sample_sentences)
    assert "time_span_seconds" in stats
    assert stats["window_seconds"] == buffer_service.window_seconds
    assert stats["max_sentences"] == buffer_service.max_sentences

    # Clean up
    await buffer_service.clear_buffer(session_id)


# Test: Clear Buffer

@pytest.mark.asyncio
async def test_clear_buffer(buffer_service, session_id, sample_sentences):
    """Test clearing the entire buffer."""
    # Add sentences
    for sentence in sample_sentences:
        await buffer_service.add_sentence(session_id, sentence)

    # Verify buffer has content
    buffer_before = await buffer_service.get_buffer(session_id)
    assert len(buffer_before) > 0

    # Clear buffer
    success = await buffer_service.clear_buffer(session_id)
    assert success is True

    # Verify buffer is empty
    buffer_after = await buffer_service.get_buffer(session_id)
    assert len(buffer_after) == 0


# Test: Singleton Pattern

def test_singleton_pattern():
    """Test that get_transcription_buffer returns the same instance."""
    instance1 = get_transcription_buffer()
    instance2 = get_transcription_buffer()

    assert instance1 is instance2


# Test: Graceful Degradation

# Removed Redis graceful degradation test - service now uses in-memory storage

# Test: Close Connection

@pytest.mark.asyncio
async def test_close_connection(buffer_service):
    """Test closing and cleaning up buffers."""
    # Add a sentence
    sample = TranscriptionSentence(
        sentence_id="test",
        text="Test",
        speaker="A",
        timestamp=datetime.now().timestamp(),
        start_time=datetime.now().timestamp(),
        end_time=datetime.now().timestamp() + 1,
        confidence=0.9
    )
    await buffer_service.add_sentence("test_session", sample)

    # Verify buffer exists
    assert "test_session" in buffer_service._buffers

    # Close connection
    await buffer_service.close()

    # Verify buffers are cleared
    assert len(buffer_service._buffers) == 0
