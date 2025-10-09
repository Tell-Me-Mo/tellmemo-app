"""
Unit tests for Replicate transcription service.

Tests the ReplicateTranscriptionService with incredibly-fast-whisper model.
Uses mocked official Replicate client following official patterns.
"""

import pytest
from unittest.mock import AsyncMock, MagicMock, patch, mock_open
from services.transcription.replicate_transcription_service import (
    ReplicateTranscriptionService,
    get_replicate_service
)
from replicate.exceptions import ReplicateError


class TestReplicateServiceInitialization:
    """Test service initialization."""

    def test_service_initialization(self):
        """Test that service initializes with API key."""
        service = ReplicateTranscriptionService(api_key="test_key")
        assert service.api_key == "test_key"
        assert service.WHISPER_MODEL == "vaibhavs10/incredibly-fast-whisper"

    def test_singleton_get_service(self):
        """Test singleton pattern for get_replicate_service."""
        with patch.dict('os.environ', {'REPLICATE_API_KEY': 'test_key'}):
            service1 = get_replicate_service()
            service2 = get_replicate_service()
            # Should return same instance
            assert service1 is service2


class TestReplicateServiceConnectionTest:
    """Test API connection validation."""

    @pytest.mark.asyncio
    async def test_connection_success(self):
        """Test successful API connection."""
        service = ReplicateTranscriptionService(api_key="test_key")

        # Mock successful model fetch
        mock_model = MagicMock()
        mock_model.owner = "vaibhavs10"
        mock_model.name = "incredibly-fast-whisper"

        with patch('replicate.models.get', return_value=mock_model):
            result = await service.test_connection()

        assert result["success"] is True
        assert "Successfully connected" in result["message"]
        assert "vaibhavs10/incredibly-fast-whisper" in result["model"]

    @pytest.mark.asyncio
    async def test_connection_invalid_api_key(self):
        """Test connection with invalid API key."""
        service = ReplicateTranscriptionService(api_key="invalid_key")

        # Mock authentication error
        with patch('replicate.models.get', side_effect=ReplicateError("Unauthorized")):
            result = await service.test_connection()

        assert result["success"] is False
        assert "Invalid API key" in result["error"]


class TestReplicateTranscription:
    """Test audio transcription functionality."""

    @pytest.mark.asyncio
    async def test_transcribe_success(self, tmp_path):
        """Test successful transcription with mocked Replicate client."""
        service = ReplicateTranscriptionService(api_key="test_key")

        # Create a small test audio file
        test_audio = tmp_path / "test.mp3"
        test_audio.write_bytes(b"fake audio data")

        # Mock replicate.run() response
        mock_output = {
            "text": "This is a test transcription.",
            "detected_language": "en",
            "segments": [
                {
                    "id": 0,
                    "start": 0.0,
                    "end": 2.5,
                    "text": "This is a test transcription.",
                    "tokens": [1, 2, 3],
                    "temperature": 0.0,
                    "avg_logprob": -0.5,
                    "compression_ratio": 1.5,
                    "no_speech_prob": 0.01
                }
            ]
        }

        with patch('replicate.run', return_value=mock_output):
            with patch('builtins.open', mock_open(read_data=b"fake audio data")):
                result = await service.transcribe_audio_file(
                    audio_path=str(test_audio),
                    language="en"
                )

        assert result["text"] == "This is a test transcription."
        assert result["language"] == "en"
        assert result["service"] == "replicate"
        assert len(result["segments"]) == 1
        assert result["segments"][0]["text"] == "This is a test transcription."

    @pytest.mark.asyncio
    async def test_transcribe_auto_language_detection(self, tmp_path):
        """Test transcription with automatic language detection."""
        service = ReplicateTranscriptionService(api_key="test_key")

        test_audio = tmp_path / "test.mp3"
        test_audio.write_bytes(b"fake audio data")

        # Mock replicate.run() response with French
        mock_output = {
            "text": "Bonjour le monde",
            "detected_language": "fr"
        }

        with patch('replicate.run', return_value=mock_output):
            with patch('builtins.open', mock_open(read_data=b"fake audio data")):
                result = await service.transcribe_audio_file(
                    audio_path=str(test_audio),
                    language=None  # Auto-detect
                )

        assert result["text"] == "Bonjour le monde"
        assert result["language"] == "fr"

    @pytest.mark.asyncio
    async def test_transcribe_plain_text_output(self, tmp_path):
        """Test transcription with plain text output (no segments)."""
        service = ReplicateTranscriptionService(api_key="test_key")

        test_audio = tmp_path / "test.mp3"
        test_audio.write_bytes(b"fake audio data")

        # Mock replicate.run() returning plain text
        mock_output = "This is plain text output."

        with patch('replicate.run', return_value=mock_output):
            with patch('builtins.open', mock_open(read_data=b"fake audio data")):
                result = await service.transcribe_audio_file(
                    audio_path=str(test_audio),
                    language="en"
                )

        assert result["text"] == "This is plain text output."
        assert result["service"] == "replicate"

    @pytest.mark.asyncio
    async def test_transcribe_failed_prediction(self, tmp_path):
        """Test handling of failed transcription."""
        service = ReplicateTranscriptionService(api_key="test_key")

        test_audio = tmp_path / "test.mp3"
        test_audio.write_bytes(b"fake audio data")

        # Mock ReplicateError
        with patch('replicate.run', side_effect=ReplicateError("Audio file is corrupted")):
            with patch('builtins.open', mock_open(read_data=b"fake audio data")):
                with pytest.raises(Exception) as exc_info:
                    await service.transcribe_audio_file(
                        audio_path=str(test_audio),
                        language="en"
                    )

                assert "Replicate API error" in str(exc_info.value)

    @pytest.mark.asyncio
    async def test_transcribe_authentication_error(self, tmp_path):
        """Test handling of authentication errors."""
        service = ReplicateTranscriptionService(api_key="invalid_key")

        test_audio = tmp_path / "test.mp3"
        test_audio.write_bytes(b"fake audio data")

        # Mock authentication error
        with patch('replicate.run', side_effect=ReplicateError("Unauthorized")):
            with patch('builtins.open', mock_open(read_data=b"fake audio data")):
                with pytest.raises(Exception) as exc_info:
                    await service.transcribe_audio_file(
                        audio_path=str(test_audio),
                        language="en"
                    )

                assert "Authentication failed" in str(exc_info.value)

    @pytest.mark.asyncio
    async def test_transcribe_with_progress_callback(self, tmp_path):
        """Test transcription with progress callback."""
        service = ReplicateTranscriptionService(api_key="test_key")

        test_audio = tmp_path / "test.mp3"
        test_audio.write_bytes(b"fake audio data")

        # Track progress updates
        progress_updates = []

        async def progress_callback(progress: float, description: str):
            progress_updates.append((progress, description))

        # Mock replicate.run()
        mock_output = {"text": "Test transcription"}

        with patch('replicate.run', return_value=mock_output):
            with patch('builtins.open', mock_open(read_data=b"fake audio data")):
                await service.transcribe_audio_file(
                    audio_path=str(test_audio),
                    language="en",
                    progress_callback=progress_callback
                )

        # Should have progress updates
        assert len(progress_updates) > 0
        assert progress_updates[0][0] == 5.0  # First update at 5%
        assert progress_updates[-1][0] == 100.0  # Final update at 100%


class TestReplicateServiceHealth:
    """Test service health check."""

    @pytest.mark.asyncio
    async def test_health_check_healthy(self):
        """Test health check when service is available."""
        service = ReplicateTranscriptionService(api_key="test_key")

        # Mock successful connection
        with patch.object(service, 'test_connection', return_value={"success": True}):
            is_healthy = await service.check_service_health()

        assert is_healthy is True

    @pytest.mark.asyncio
    async def test_health_check_unhealthy(self):
        """Test health check when service is unavailable."""
        service = ReplicateTranscriptionService(api_key="test_key")

        # Mock failed connection
        with patch.object(service, 'test_connection', return_value={"success": False}):
            is_healthy = await service.check_service_health()

        assert is_healthy is False

    def test_is_model_loaded_always_true(self):
        """Test that cloud service is always considered ready."""
        service = ReplicateTranscriptionService(api_key="test_key")
        assert service.is_model_loaded() is True
