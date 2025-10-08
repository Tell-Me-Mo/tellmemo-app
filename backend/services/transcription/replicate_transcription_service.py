"""
Replicate transcription service for audio processing using official Replicate Python client.
Uses OpenAI Whisper large-v3 model via Replicate for high-quality transcription.

Official Documentation: https://replicate.com/docs/get-started/python
"""

import os
import asyncio
import logging
from typing import Optional, Dict, Any, Callable
from pathlib import Path
import replicate
from replicate.exceptions import ReplicateError
from utils.logger import sanitize_for_log

logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)


class ReplicateTranscriptionService:
    """Service for transcribing audio using Replicate API with Whisper large-v3."""

    # Whisper large-v3 model on Replicate (official version hash from docs)
    WHISPER_MODEL = "openai/whisper"
    WHISPER_VERSION = "4d50797290df275329f202e48c76360b3f22b08d28c196cbc54600319435f8d2"

    def __init__(self, api_key: str):
        """
        Initialize Replicate transcription service.

        Args:
            api_key: Replicate API token
        """
        self.api_key = api_key
        # Set the API token for the replicate client
        os.environ["REPLICATE_API_TOKEN"] = api_key

        logger.info("Initialized Replicate transcription service with Whisper large-v3")

    async def test_connection(self) -> Dict[str, Any]:
        """
        Test the API connection and verify credentials.

        Returns:
            Dict with success status and message
        """
        try:
            # Try to get the model to verify credentials
            model = replicate.models.get(self.WHISPER_MODEL)

            logger.info("Replicate API test successful")
            return {
                "success": True,
                "message": "Successfully connected to Replicate API",
                "model": f"{model.owner}/{model.name} (large-v3)"
            }

        except ReplicateError as e:
            error_str = str(e).lower()

            if "unauthorized" in error_str or "authentication" in error_str:
                return {
                    "success": False,
                    "error": "Invalid API key. Please check your Replicate API token."
                }
            elif "forbidden" in error_str:
                return {
                    "success": False,
                    "error": "Access denied. Please verify your Replicate API token permissions."
                }
            else:
                return {
                    "success": False,
                    "error": f"Replicate API error: {str(e)}"
                }

        except Exception as e:
            logger.error(f"Unexpected error testing Replicate connection: {sanitize_for_log(str(e))}")
            return {
                "success": False,
                "error": "Unexpected error occurred"
            }

    async def transcribe_audio_file(
        self,
        audio_path: str,
        language: Optional[str] = None,
        progress_callback: Optional[Callable] = None
    ) -> Dict[str, Any]:
        """
        Transcribe an audio file using Replicate Whisper large-v3.

        Args:
            audio_path: Path to the audio file
            language: Language code for transcription (None for auto-detection)
            progress_callback: Optional callback for progress updates

        Returns:
            Transcription result with text and segments
        """
        try:
            # Update progress: Starting
            if progress_callback:
                await progress_callback(5.0, "Preparing audio file...")

            file_size_mb = Path(audio_path).stat().st_size / (1024 * 1024)
            logger.info(f"Processing audio file: {audio_path} ({file_size_mb:.2f} MB)")

            if progress_callback:
                await progress_callback(15.0, "Submitting to Replicate API...")

            # Prepare input parameters following official Replicate best practices
            input_params = {
                "audio": open(audio_path, "rb"),  # Replicate handles file upload
                "model": "large-v3",  # Use Whisper large-v3 for best quality
                "transcription": "plain text",  # Options: "plain text", "srt", "vtt"
                "translate": False,  # Don't translate, keep original language
                "temperature": 0.0,  # Greedy decoding for deterministic results
                "patience": 1.0,  # Beam search patience
                "suppress_tokens": "-1",  # Default suppression
                "logprob_threshold": -1.0,  # Default logprob threshold
                "no_speech_threshold": 0.6,  # No speech detection threshold
                "condition_on_previous_text": True,  # Use context from previous segments
                "compression_ratio_threshold": 2.4,  # Detect repetitive output
                "temperature_increment_on_fallback": 0.2,  # Increase temp on failure
            }

            # Add language if specified (otherwise auto-detect)
            if language and language != "auto":
                input_params["language"] = language
                logger.info(f"Using specified language: {language}")
            else:
                logger.info("Using automatic language detection")

            if progress_callback:
                await progress_callback(30.0, "Transcription in progress...")

            # Create prediction using official client
            # Note: replicate.run() is synchronous, but we can run it in executor
            loop = asyncio.get_event_loop()

            # Run the prediction in a thread pool to not block the event loop
            def run_prediction():
                return replicate.run(
                    f"{self.WHISPER_MODEL}:{self.WHISPER_VERSION}",
                    input=input_params
                )

            # Poll for progress updates while waiting
            prediction_task = loop.run_in_executor(None, run_prediction)

            # Simulate progress updates during transcription
            progress = 30.0
            while not prediction_task.done():
                await asyncio.sleep(3)
                progress = min(progress + 5, 65.0)
                if progress_callback:
                    await progress_callback(progress, "Processing audio...")

            # Get the result
            output = await prediction_task

            logger.info(f"Transcription completed, processing output")

            # Parse output based on type
            transcription_text = ""
            segments = []
            detected_language = language or "unknown"

            if isinstance(output, str):
                # Plain text output
                transcription_text = output
            elif isinstance(output, dict):
                # Structured output with text and segments
                transcription_text = output.get("text", "")
                detected_language = output.get("detected_language", detected_language)

                # Extract segments if available
                raw_segments = output.get("segments", [])
                for seg in raw_segments:
                    segments.append({
                        "id": seg.get("id", 0),
                        "start": seg.get("start", 0.0),
                        "end": seg.get("end", 0.0),
                        "text": seg.get("text", ""),
                        "tokens": seg.get("tokens", []),
                        "temperature": seg.get("temperature", 0.0),
                        "avg_logprob": seg.get("avg_logprob", 0.0),
                        "compression_ratio": seg.get("compression_ratio", 0.0),
                        "no_speech_prob": seg.get("no_speech_prob", 0.0)
                    })

            if not transcription_text:
                logger.error("Transcription succeeded but no text was generated")
                raise Exception("Transcription succeeded but no text was generated. Check audio file quality.")

            logger.info(f"Transcription completed: {len(transcription_text)} characters, {len(segments)} segments")

            if progress_callback:
                await progress_callback(100.0, "Transcription completed")

            # Calculate duration from segments
            duration = 0
            if segments:
                duration = max(seg.get("end", 0) for seg in segments)

            return {
                "text": transcription_text,
                "segments": segments,
                "language": detected_language,
                "duration": duration,
                "service": "replicate"
            }

        except ReplicateError as e:
            logger.error(f"Replicate API error: {sanitize_for_log(str(e))}", exc_info=True)

            error_str = str(e).lower()
            if "unauthorized" in error_str or "authentication" in error_str:
                raise Exception("Authentication failed: Invalid API token. Please check your Replicate API credentials.")
            elif "payment" in error_str or "billing" in error_str:
                raise Exception("Billing required: Please add credits to your Replicate account.")
            else:
                raise Exception(f"Replicate API error: {str(e)}")

        except Exception as e:
            logger.error(f"Replicate transcription error: {sanitize_for_log(str(e))}", exc_info=True)
            raise

    async def check_service_health(self) -> bool:
        """
        Check if Replicate transcription service is available.

        Returns:
            True if service is healthy, False otherwise
        """
        try:
            result = await self.test_connection()
            return result.get("success", False)
        except Exception as e:
            logger.error(f"Replicate health check error: {sanitize_for_log(str(e))}")
            return False

    def is_model_loaded(self) -> bool:
        """
        For compatibility with Whisper service interface.
        Replicate is always ready as it's a cloud service.
        """
        return True


# Singleton instance management
_replicate_service_instance: Optional[ReplicateTranscriptionService] = None


def get_replicate_service(
    api_key: Optional[str] = None
) -> ReplicateTranscriptionService:
    """
    Get or create a singleton instance of Replicate transcription service.

    Args:
        api_key: Replicate API token (reads from env if not provided)

    Returns:
        ReplicateTranscriptionService instance
    """
    global _replicate_service_instance

    if _replicate_service_instance is None:
        # Get credentials from environment if not provided
        # Note: Replicate uses REPLICATE_API_TOKEN not REPLICATE_API_KEY
        api_key = api_key or os.getenv("REPLICATE_API_KEY") or os.getenv("REPLICATE_API_TOKEN")

        if not api_key:
            raise ValueError(
                "Replicate API token not provided. "
                "Set REPLICATE_API_KEY or REPLICATE_API_TOKEN environment variable "
                "or provide it as a parameter."
            )

        _replicate_service_instance = ReplicateTranscriptionService(
            api_key=api_key
        )

    return _replicate_service_instance
