"""
Replicate transcription service for audio processing using official Replicate Python client.
Uses incredibly-fast-whisper (Whisper Large v3 optimized) for high-speed, high-quality transcription.

Official Documentation: https://replicate.com/docs/get-started/python
Model: https://replicate.com/vaibhavs10/incredibly-fast-whisper
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
    """Service for transcribing audio using incredibly-fast-whisper (optimized Large v3, ~90x realtime)."""

    # incredibly-fast-whisper: Optimized Whisper Large v3 with GPU acceleration
    # Performance: 150 minutes transcribed in ~98 seconds (91.8x realtime)
    # Model: https://replicate.com/vaibhavs10/incredibly-fast-whisper
    WHISPER_MODEL = "vaibhavs10/incredibly-fast-whisper"
    WHISPER_VERSION = "3ab86df6c8f54c11309d4d1f930ac292bad43ace52d10c80d87eb258b3c9f79c"

    def __init__(self, api_key: str):
        """
        Initialize Replicate transcription service.

        Args:
            api_key: Replicate API token
        """
        self.api_key = api_key
        # Set the API token for the replicate client
        os.environ["REPLICATE_API_TOKEN"] = api_key

        logger.info("Initialized incredibly-fast-whisper service (Whisper Large v3, ~90x realtime)")

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
                "model": f"{model.owner}/{model.name} (incredibly-fast-whisper)"
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
        Transcribe an audio file using incredibly-fast-whisper (optimized Whisper Large v3).

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

            # Prepare input parameters for incredibly-fast-whisper
            # This model is pre-optimized for speed with batch_size=24 and GPU acceleration

            # Open file for Replicate to upload
            audio_file = open(audio_path, "rb")

            # Minimal parameters - incredibly-fast-whisper is already optimized
            input_params = {
                "audio": audio_file,  # Replicate handles file upload
                "task": "transcribe",  # transcribe (not translate)
                "batch_size": 24,  # Default optimized batch size
                "timestamp": "chunk",  # chunk-level timestamps (faster than word-level)
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
            logger.debug(f"Output type: {type(output)}")
            logger.debug(f"Output content (first 500 chars): {str(output)[:500]}")

            # Parse output based on type
            transcription_text = ""
            segments = []
            detected_language = language or "unknown"

            if isinstance(output, str):
                # Plain text output
                transcription_text = output
                logger.info("Received plain text output from incredibly-fast-whisper")
            elif isinstance(output, dict):
                # Structured output from incredibly-fast-whisper
                # Model returns {"text": "...", "chunks": [...], "detected_language": "en"}
                logger.info(f"Received dict output with keys: {list(output.keys())}")
                transcription_text = output.get("text", output.get("transcription", ""))
                detected_language = output.get("detected_language", detected_language)

                # Extract segments/chunks if available
                # incredibly-fast-whisper may use "chunks" instead of "segments"
                raw_segments = output.get("segments", output.get("chunks", []))
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
            elif hasattr(output, '__iter__'):
                # Iterator/generator output - join all parts
                logger.info("Received iterable output from incredibly-fast-whisper")
                parts = []
                for part in output:
                    if isinstance(part, str):
                        parts.append(part)
                    elif isinstance(part, dict):
                        parts.append(part.get("text", str(part)))
                transcription_text = "".join(parts)
            else:
                logger.warning(f"Unexpected output type: {type(output)}, attempting str conversion")
                transcription_text = str(output)

            if not transcription_text:
                logger.error(f"Transcription succeeded but no text was generated. Output type: {type(output)}, Output: {output}")
                raise Exception("Transcription succeeded but no text was generated. Check audio file quality or output format.")

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
