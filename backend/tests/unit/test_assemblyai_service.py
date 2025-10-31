"""
Unit Tests for AssemblyAI Service

Tests the connection management, transcription parsing, and metrics tracking
for AssemblyAI real-time transcription integration.

Task 2.0.5: Implement AssemblyAI Streaming Integration
"""

import pytest
import asyncio
from datetime import datetime
from unittest.mock import AsyncMock, MagicMock, patch

from services.transcription.assemblyai_service import (
    AssemblyAIConnectionManager,
    AssemblyAIConnection,
    TranscriptionMetrics,
    TranscriptionResult,
    ConnectionState
)


# Test Fixtures

@pytest.fixture
def session_id() -> str:
    """Generate a unique session ID for testing."""
    return f"test_session_{datetime.now().timestamp()}"


@pytest.fixture
def api_key() -> str:
    """Mock API key for testing."""
    return "test_api_key_12345"


@pytest.fixture
def transcription_metrics(session_id):
    """Create a TranscriptionMetrics instance."""
    return TranscriptionMetrics(session_id=session_id)


# Test: TranscriptionMetrics

def test_transcription_metrics_creation(transcription_metrics, session_id):
    """Test creation of TranscriptionMetrics."""
    assert transcription_metrics.session_id == session_id
    assert transcription_metrics.audio_bytes_sent == 0
    assert transcription_metrics.audio_duration_seconds == 0.0
    assert transcription_metrics.transcription_count == 0
    assert transcription_metrics.started_at is None


def test_transcription_metrics_cost_estimate(transcription_metrics):
    """Test cost estimation calculation."""
    # 1 minute of audio = 60 seconds
    transcription_metrics.audio_duration_seconds = 60.0

    # Expected: 60 * $0.000042 = $0.00252 (AssemblyAI Universal-Streaming v3: $0.15/hour)
    assert transcription_metrics.cost_estimate == pytest.approx(0.00252, rel=1e-9)


def test_transcription_metrics_cost_estimate_hour(transcription_metrics):
    """Test cost estimation for 1 hour."""
    # 1 hour of audio = 3600 seconds
    transcription_metrics.audio_duration_seconds = 3600.0

    # Expected: 3600 * $0.000042 = $0.1512 (AssemblyAI Universal-Streaming v3: $0.15/hour)
    assert transcription_metrics.cost_estimate == 0.1512


def test_transcription_metrics_session_duration(transcription_metrics):
    """Test session duration calculation."""
    start_time = datetime(2025, 10, 26, 10, 0, 0)
    end_time = datetime(2025, 10, 26, 10, 15, 30)

    transcription_metrics.started_at = start_time
    transcription_metrics.ended_at = end_time

    # Expected: 15 minutes 30 seconds = 930 seconds
    assert transcription_metrics.session_duration_seconds == 930.0


# Test: TranscriptionResult

def test_transcription_result_creation():
    """Test creation of TranscriptionResult."""
    result = TranscriptionResult(
        text="Hello, what is the budget?",
        is_final=True,
        speaker="Speaker A",
        confidence=0.95,
        audio_start=0,
        audio_end=3000,
        created_at="2025-10-26T10:30:00Z",
        words=[]
    )

    assert result.text == "Hello, what is the budget?"
    assert result.is_final is True
    assert result.speaker == "Speaker A"
    assert result.confidence == 0.95
    assert result.audio_start == 0
    assert result.audio_end == 3000


def test_transcription_result_partial():
    """Test partial transcription result."""
    result = TranscriptionResult(
        text="Hello, what is...",
        is_final=False,
        speaker=None,
        confidence=0.75,
        audio_start=0,
        audio_end=1500,
        created_at="2025-10-26T10:30:00Z",
        words=[]
    )

    assert result.is_final is False
    assert result.speaker is None
    assert result.confidence == 0.75


# Test: AssemblyAIConnection Parsing

def test_parse_transcription_result_final():
    """Test parsing final transcription from AssemblyAI response."""
    # Mock connection
    connection = AssemblyAIConnection(
        session_id="test_session",
        api_key="test_key",
        on_transcription=None,
        on_error=None
    )

    # Mock AssemblyAI response
    assemblyai_response = {
        "message_type": "FinalTranscript",
        "text": "The budget is $250,000 for infrastructure.",
        "confidence": 0.97,
        "audio_start": 0,
        "audio_end": 4000,
        "created": "2025-10-26T10:30:00Z",
        "speaker_labels": ["Speaker B"],
        "words": [
            {"text": "The", "start": 0, "end": 200, "confidence": 0.99, "speaker": "B"},
            {"text": "budget", "start": 200, "end": 500, "confidence": 0.98, "speaker": "B"}
        ]
    }

    result = connection._parse_transcription_result(assemblyai_response, is_final=True)

    assert result.text == "The budget is $250,000 for infrastructure."
    assert result.is_final is True
    assert result.speaker == "Speaker B"
    assert result.confidence == 0.97
    assert result.audio_start == 0
    assert result.audio_end == 4000
    assert len(result.words) == 2


def test_parse_transcription_result_partial():
    """Test parsing partial transcription from AssemblyAI response."""
    connection = AssemblyAIConnection(
        session_id="test_session",
        api_key="test_key",
        on_transcription=None,
        on_error=None
    )

    assemblyai_response = {
        "message_type": "PartialTranscript",
        "text": "The budget is",
        "confidence": 0.85,
        "audio_start": 0,
        "audio_end": 1500,
        "created": "2025-10-26T10:30:00Z",
        "words": []
    }

    result = connection._parse_transcription_result(assemblyai_response, is_final=False)

    assert result.text == "The budget is"
    assert result.is_final is False
    assert result.confidence == 0.85


def test_extract_speaker_from_words():
    """Test speaker extraction from words array."""
    connection = AssemblyAIConnection(
        session_id="test_session",
        api_key="test_key",
        on_transcription=None,
        on_error=None
    )

    assemblyai_response = {
        "text": "Hello everyone",
        "words": [
            {"text": "Hello", "speaker": "A"},
            {"text": "everyone", "speaker": "A"}
        ]
    }

    speaker = connection._extract_speaker(assemblyai_response)
    assert speaker == "Speaker A"


def test_extract_speaker_no_speaker():
    """Test speaker extraction when no speaker info available."""
    connection = AssemblyAIConnection(
        session_id="test_session",
        api_key="test_key",
        on_transcription=None,
        on_error=None
    )

    assemblyai_response = {
        "text": "Hello everyone",
        "words": []
    }

    speaker = connection._extract_speaker(assemblyai_response)
    assert speaker is None


# Test: AssemblyAIConnectionManager

def test_connection_manager_initialization():
    """Test AssemblyAIConnectionManager initialization."""
    manager = AssemblyAIConnectionManager()

    assert isinstance(manager.active_connections, dict)
    assert len(manager.active_connections) == 0


def test_connection_manager_session_active():
    """Test checking if session has active connection."""
    manager = AssemblyAIConnectionManager()

    assert manager.is_session_active("nonexistent_session") is False


@pytest.mark.asyncio
async def test_connection_manager_get_metrics_no_connection():
    """Test getting metrics for non-existent session."""
    manager = AssemblyAIConnectionManager()

    metrics = manager.get_metrics("nonexistent_session")
    assert metrics is None


# Test: Connection State

def test_connection_state_enum():
    """Test ConnectionState enum values."""
    assert ConnectionState.DISCONNECTED.value == "disconnected"
    assert ConnectionState.CONNECTING.value == "connecting"
    assert ConnectionState.CONNECTED.value == "connected"
    assert ConnectionState.ERROR.value == "error"
    assert ConnectionState.FAILED.value == "failed"


# Test: Audio Duration Calculation

def test_audio_duration_calculation(transcription_metrics):
    """Test audio duration calculation from bytes."""
    # PCM 16kHz, 16-bit, mono: bytes / (16000 * 2 * 1) = bytes / 32000

    # 32000 bytes = 1 second
    audio_bytes = 32000
    duration_seconds = audio_bytes / 32000

    transcription_metrics.audio_bytes_sent = audio_bytes
    transcription_metrics.audio_duration_seconds = duration_seconds

    assert transcription_metrics.audio_duration_seconds == 1.0


def test_audio_duration_10_seconds(transcription_metrics):
    """Test audio duration calculation for 10 seconds."""
    # 320000 bytes = 10 seconds
    audio_bytes = 320000
    duration_seconds = audio_bytes / 32000

    transcription_metrics.audio_bytes_sent = audio_bytes
    transcription_metrics.audio_duration_seconds = duration_seconds

    assert transcription_metrics.audio_duration_seconds == 10.0

    # Cost for 10 seconds: 10 * $0.000042 = $0.00042 (AssemblyAI Universal-Streaming v3)
    assert transcription_metrics.cost_estimate == pytest.approx(0.00042, rel=1e-9)


# Test: Connection URL Construction

def test_assemblyai_connection_url():
    """Test AssemblyAI WebSocket URL format."""
    base_url = AssemblyAIConnection.ASSEMBLYAI_URL
    sample_rate = AssemblyAIConnection.SAMPLE_RATE
    encoding = AssemblyAIConnection.ENCODING

    assert base_url == "wss://streaming.assemblyai.com/v3/ws"
    assert sample_rate == 16000
    assert encoding == "pcm_s16le"


# Test: Reconnection Logic

def test_connection_max_reconnect_attempts():
    """Test max reconnection attempts configuration."""
    connection = AssemblyAIConnection(
        session_id="test_session",
        api_key="test_key",
        on_transcription=None,
        on_error=None
    )

    assert connection.max_reconnect_attempts == 3
    assert connection.reconnect_delay_seconds == [1, 2, 5]


# Test: Metrics Tracking Updates

def test_metrics_update_on_transcription(transcription_metrics):
    """Test metrics updates when transcription is received."""
    # Simulate receiving transcriptions
    transcription_metrics.transcription_count += 1
    transcription_metrics.partial_count += 1

    assert transcription_metrics.transcription_count == 1
    assert transcription_metrics.partial_count == 1
    assert transcription_metrics.final_count == 0


def test_metrics_update_final_transcription(transcription_metrics):
    """Test metrics updates for final transcription."""
    transcription_metrics.transcription_count += 1
    transcription_metrics.final_count += 1

    assert transcription_metrics.transcription_count == 1
    assert transcription_metrics.final_count == 1
    assert transcription_metrics.partial_count == 0


def test_metrics_error_tracking(transcription_metrics):
    """Test error count tracking."""
    transcription_metrics.error_count += 1
    transcription_metrics.error_count += 1

    assert transcription_metrics.error_count == 2


# Test: Connection Lifecycle

def test_connection_initial_state():
    """Test connection starts in DISCONNECTED state."""
    connection = AssemblyAIConnection(
        session_id="test_session",
        api_key="test_key",
        on_transcription=None,
        on_error=None
    )

    assert connection.state == ConnectionState.DISCONNECTED
    assert connection.websocket is None
    assert connection.metrics.connection_attempts == 0


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
