"""
Salad transcription service for audio processing using Salad API.
Uses Salad's transcription endpoint for fast, scalable transcription.
"""

import os
import asyncio
import logging
import aiohttp
import json
import ssl
import certifi
from typing import Optional, Dict, Any, Callable
from pathlib import Path
from utils.logger import sanitize_for_log

logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)  # Temporarily set to DEBUG for troubleshooting


class SaladTranscriptionService:
    """Service for transcribing audio using Salad API."""

    def __init__(
        self,
        api_key: str,
        organization_name: str,
        base_url: str = "https://api.salad.com/api/public"
    ):
        """
        Initialize Salad transcription service.

        Args:
            api_key: Salad API key
            organization_name: Your Salad organization name
            base_url: Salad API base URL
        """
        self.api_key = api_key
        self.organization_name = organization_name
        self.base_url = base_url
        self.headers = {
            "Salad-Api-Key": api_key,
            "Content-Type": "application/json",
            "Accept": "application/json"
        }

        logger.info("Initialized Salad transcription service")

    async def test_connection(self) -> Dict[str, Any]:
        """
        Test the API connection and verify credentials.

        Returns:
            Dict with success status and message
        """
        try:
            # Validate base_url to prevent SSRF attacks
            from urllib.parse import urlparse
            parsed_url = urlparse(self.base_url)

            # Only allow HTTPS connections to salad.com domain
            if parsed_url.scheme != 'https':
                return {
                    "success": False,
                    "error": "Only HTTPS connections are allowed"
                }

            # Validate hostname to prevent SSRF
            if not parsed_url.hostname or not parsed_url.hostname.endswith('.salad.com'):
                if parsed_url.hostname != 'api.salad.com':
                    return {
                        "success": False,
                        "error": "Invalid API endpoint. Must be a salad.com domain."
                    }

            # Try to list container groups to verify API key and organization
            test_url = f"{self.base_url}/organizations/{self.organization_name}/container-groups"

            # Disable SSL verification for development
            ssl_context = ssl.create_default_context()
            ssl_context.check_hostname = False
            ssl_context.verify_mode = ssl.CERT_NONE
            connector = aiohttp.TCPConnector(ssl=ssl_context)
            async with aiohttp.ClientSession(connector=connector) as session:
                async with session.get(
                    test_url,
                    headers=self.headers,
                    timeout=aiohttp.ClientTimeout(total=10)
                ) as response:
                    if response.status == 200:
                        # Successfully connected and authenticated
                        _ = await response.json()  # Validate JSON response
                        logger.info("Salad API test successful")
                        return {
                            "success": True,
                            "message": "Successfully connected to Salad API",
                            "organization": self.organization_name
                        }
                    elif response.status == 401:
                        return {
                            "success": False,
                            "error": "Invalid API key. Please check your Salad API key."
                        }
                    elif response.status == 403:
                        return {
                            "success": False,
                            "error": f"Access denied. Please verify the organization name '{self.organization_name}' is correct."
                        }
                    elif response.status == 404:
                        return {
                            "success": False,
                            "error": f"Organization '{self.organization_name}' not found. Please check the organization name."
                        }
                    else:
                        error_text = await response.text()
                        return {
                            "success": False,
                            "error": f"Salad API returned status {response.status}: {error_text}"
                        }

        except aiohttp.ClientError as e:
            logger.error(f"Network error testing Salad connection: {sanitize_for_log(str(e))}")
            return {
                "success": False,
                "error": "Network error. Please check your internet connection."
            }
        except Exception as e:
            logger.error(f"Unexpected error testing Salad connection: {sanitize_for_log(str(e))}")
            return {
                "success": False,
                "error": "Unexpected error occurred"
            }

    async def upload_to_s4_multipart(
        self,
        audio_path: str,
        mime_type: str = "audio/mpeg",
        chunk_size_mb: int = 95  # Just under 100MB limit
    ) -> str:
        """
        Upload large audio file (>100MB) to S4 using multipart upload.

        Args:
            audio_path: Path to the local audio file
            mime_type: MIME type of the audio file
            chunk_size_mb: Size of each chunk in MB (max 100MB per S4 limit)

        Returns:
            Signed URL for the uploaded file
        """
        try:
            file_name = Path(audio_path).name
            s4_path = f"audio/{file_name}"
            file_size = Path(audio_path).stat().st_size
            chunk_size_bytes = chunk_size_mb * 1024 * 1024

            logger.info(f"Starting multipart upload to S4: {s4_path} ({file_size / 1024 / 1024:.2f} MB)")

            # Disable SSL verification for development
            ssl_context = ssl.create_default_context()
            ssl_context.check_hostname = False
            ssl_context.verify_mode = ssl.CERT_NONE
            connector = aiohttp.TCPConnector(ssl=ssl_context)

            async with aiohttp.ClientSession(connector=connector) as session:
                # Step 1: Initiate multipart upload
                initiate_url = f"https://storage-api.salad.com/organizations/{self.organization_name}/file_parts/{s4_path}?uploads"
                logger.info(f"Initiating multipart upload")

                async with session.post(
                    initiate_url,
                    headers={"Salad-Api-Key": self.api_key}
                ) as response:
                    if response.status not in [200, 201]:
                        error_text = await response.text()
                        logger.error(f"Failed to initiate multipart upload: {response.status} - {error_text}")
                        raise Exception(f"Failed to initiate multipart upload: {response.status} - {error_text}")

                    result = await response.json()
                    upload_id = result.get('uploadId')

                    if not upload_id:
                        raise Exception(f"No uploadId returned from S4: {result}")

                    logger.info(f"Multipart upload initiated with uploadId: {upload_id}")

                # Step 2: Upload parts
                parts = []
                part_number = 1

                with open(audio_path, 'rb') as f:
                    while True:
                        chunk = f.read(chunk_size_bytes)
                        if not chunk:
                            break

                        logger.info(f"Uploading part {part_number} ({len(chunk) / 1024 / 1024:.2f} MB)")

                        part_url = f"https://storage-api.salad.com/organizations/{self.organization_name}/file_parts/{s4_path}?partNumber={part_number}&uploadId={upload_id}"

                        async with session.put(
                            part_url,
                            headers={
                                "Salad-Api-Key": self.api_key,
                                "Content-Type": "application/octet-stream"
                            },
                            data=chunk
                        ) as part_response:
                            if part_response.status not in [200, 201]:
                                error_text = await part_response.text()
                                logger.error(f"Failed to upload part {part_number}: {part_response.status} - {error_text}")
                                raise Exception(f"Failed to upload part {part_number}: {part_response.status} - {error_text}")

                            # Get ETag from response headers
                            etag = part_response.headers.get('ETag')
                            if etag:
                                # Remove quotes from ETag if present
                                etag = etag.strip('"')

                            parts.append({
                                "partNumber": part_number,
                                "etag": etag
                            })

                            logger.info(f"Part {part_number} uploaded successfully (ETag: {etag})")

                        part_number += 1

                logger.info(f"All {len(parts)} parts uploaded successfully")

                # Step 3: Complete multipart upload
                complete_url = f"https://storage-api.salad.com/organizations/{self.organization_name}/file_parts/{s4_path}?uploadId={upload_id}"
                complete_payload = {
                    "parts": parts,
                    "mimeType": mime_type,
                    "sign": True,
                    "signatureExp": 3 * 24 * 60 * 60  # 3 days
                }

                logger.info(f"Completing multipart upload with {len(parts)} parts")

                async with session.post(
                    complete_url,
                    headers={
                        "Salad-Api-Key": self.api_key,
                        "Content-Type": "application/json"
                    },
                    json=complete_payload
                ) as response:
                    if response.status not in [200, 201]:
                        error_text = await response.text()
                        logger.error(f"Failed to complete multipart upload: {response.status} - {error_text}")
                        raise Exception(f"Failed to complete multipart upload: {response.status} - {error_text}")

                    result = await response.json()
                    signed_url = result.get('url')

                    if not signed_url:
                        raise Exception(f"No signed URL returned from S4: {result}")

                    logger.info(f"Multipart upload completed successfully, got signed URL")
                    return signed_url

        except Exception as e:
            logger.error(f"S4 multipart upload error: {sanitize_for_log(str(e))}", exc_info=True)
            raise

    async def upload_to_s4(
        self,
        audio_path: str,
        mime_type: str = "audio/mpeg"
    ) -> str:
        """
        Upload audio file to Salad S4 storage and get signed URL.
        Automatically uses multipart upload for files >100MB.

        Args:
            audio_path: Path to the local audio file
            mime_type: MIME type of the audio file

        Returns:
            Signed URL for the uploaded file
        """
        try:
            # Check file size to determine upload method
            file_size = Path(audio_path).stat().st_size
            file_size_mb = file_size / (1024 * 1024)

            # S4 has a 100MB single upload limit (Cloudflare Workers constraint)
            # Use multipart upload for files >= 100MB
            if file_size_mb >= 100:
                logger.info(f"File size ({file_size_mb:.2f} MB) >= 100MB, using multipart upload")
                return await self.upload_to_s4_multipart(audio_path, mime_type)

            # For files < 100MB, use simple single upload
            file_name = Path(audio_path).name
            s4_path = f"audio/{file_name}"
            upload_url = f"https://storage-api.salad.com/organizations/{self.organization_name}/files/{s4_path}"

            logger.info(f"Uploading file to S4: {s4_path} ({file_size_mb:.2f} MB)")

            # Disable SSL verification for development
            ssl_context = ssl.create_default_context()
            ssl_context.check_hostname = False
            ssl_context.verify_mode = ssl.CERT_NONE
            connector = aiohttp.TCPConnector(ssl=ssl_context)
            async with aiohttp.ClientSession(connector=connector) as session:
                # Read file
                with open(audio_path, 'rb') as f:
                    file_data = f.read()

                # Prepare multipart form data
                form_data = aiohttp.FormData()
                form_data.add_field('file', file_data, filename=file_name, content_type=mime_type)
                form_data.add_field('mimeType', mime_type)
                form_data.add_field('sign', 'true')
                form_data.add_field('signatureExp', str(3 * 24 * 60 * 60))  # 3 days

                # Upload file
                async with session.put(
                    upload_url,
                    headers={"Salad-Api-Key": self.api_key},
                    data=form_data
                ) as response:
                    if response.status not in [200, 201]:
                        error_text = await response.text()
                        logger.error(f"S4 upload failed: {response.status} - {error_text}")
                        raise Exception(f"Failed to upload to S4: {response.status} - {error_text}")

                    result = await response.json()
                    signed_url = result.get('url')

                    if not signed_url:
                        raise Exception(f"No signed URL returned from S4: {result}")

                    logger.info(f"File uploaded to S4, got signed URL")
                    return signed_url

        except Exception as e:
            logger.error(f"S4 upload error: {sanitize_for_log(str(e))}", exc_info=True)
            raise

    async def transcribe_audio_file(
        self,
        audio_path: str,
        language: Optional[str] = None,  # Make optional for auto-detection
        progress_callback: Optional[Callable] = None
    ) -> Dict[str, Any]:
        """
        Transcribe an audio file using Salad API.

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
                await progress_callback(5.0, "Uploading audio to S4 storage...")

            # First, upload file to S4 and get signed URL
            try:
                # Determine MIME type based on file extension - expanded format support
                file_ext = Path(audio_path).suffix.lower()

                # Comprehensive format support for both audio and video
                SUPPORTED_FORMATS = {
                    # Audio formats
                    '.mp3': 'audio/mpeg',
                    '.wav': 'audio/wav',
                    '.m4a': 'audio/mp4',
                    '.aac': 'audio/aac',
                    '.ogg': 'audio/ogg',
                    '.flac': 'audio/flac',
                    '.webm': 'audio/webm',
                    '.aiff': 'audio/aiff',
                    '.wma': 'audio/x-ms-wma',
                    # Video formats (Salad can extract audio from video)
                    '.mp4': 'video/mp4',
                    '.mov': 'video/quicktime',
                    '.mkv': 'video/x-matroska',
                    '.avi': 'video/x-msvideo'
                }

                if file_ext not in SUPPORTED_FORMATS:
                    logger.warning(f"Unknown file format {file_ext}, defaulting to audio/mpeg")

                mime_type = SUPPORTED_FORMATS.get(file_ext, 'audio/mpeg')

                signed_url = await self.upload_to_s4(audio_path, mime_type)
                logger.info(f"Audio uploaded to S4, got signed URL")

            except Exception as e:
                logger.error(f"Failed to upload to S4: {sanitize_for_log(str(e))}")
                raise Exception("S4 upload failed")

            # Get file size for logging
            file_size_mb = Path(audio_path).stat().st_size / (1024 * 1024)
            logger.info(f"Processing audio file: {audio_path} ({file_size_mb:.2f} MB)")

            # Update progress: Uploading
            if progress_callback:
                await progress_callback(15.0, "Submitting transcription job...")

            # Prepare request payload with enhanced configuration
            # Build input configuration dynamically based on requirements
            input_config = {
                "url": signed_url,  # Use the signed URL instead of base64
                "return_as_file": False,  # We want JSON response
                "sentence_level_timestamps": True,
                "word_level_timestamps": False,  # Word-level timestamps without speaker labels
                "diarization": False,  # Disable word-level diarization (not needed)
                "sentence_diarization": True,  # Enable sentence-level speaker labeling (sufficient for meetings)
            }

            # Only include language_code if specified (for diarization)
            # If not specified, Salad will auto-detect the language
            if language:
                input_config["language_code"] = language
                logger.info("Using specified language for transcription")
            else:
                # Let Salad auto-detect the language for optimal results
                # This is especially useful for multilingual content
                logger.info("Language auto-detection enabled")

            payload = {
                "input": input_config,
                "webhook": None,  # Optional webhook for async processing
                "metadata": {
                    "audio_path": Path(audio_path).name
                }
            }

            # Create inference endpoint job
            # Note: The endpoint name might need to be different based on your Salad configuration
            # Common endpoint names: "transcribe", "whisper", "speech-to-text"
            endpoint_url = f"{self.base_url}/organizations/{self.organization_name}/inference-endpoints/transcribe/jobs"
            logger.info(f"Submitting transcription job to endpoint")

            # Disable SSL verification for development
            ssl_context = ssl.create_default_context()
            ssl_context.check_hostname = False
            ssl_context.verify_mode = ssl.CERT_NONE
            connector = aiohttp.TCPConnector(ssl=ssl_context)
            async with aiohttp.ClientSession(connector=connector) as session:
                # Submit transcription job
                async with session.post(
                    endpoint_url,
                    headers=self.headers,
                    json=payload
                ) as response:
                    if response.status == 401:
                        logger.error("Salad API authentication failed")
                        raise Exception("Authentication failed: Invalid API key or organization name. Please check your Salad API credentials.")
                    elif response.status == 403:
                        logger.error("Salad API access denied")
                        raise Exception("Access denied: Your API key doesn't have permission to access this endpoint.")
                    elif response.status == 404:
                        logger.error(f"Salad API endpoint not found")
                        raise Exception(f"Salad API endpoint not found. Please check your organization configuration.")
                    elif response.status != 201 and response.status != 200:
                        error_text = await response.text()
                        logger.error(f"Salad API error: {response.status} - {error_text}")
                        raise Exception(f"Salad API error (HTTP {response.status}): {error_text or 'Unknown error'}")

                    job_data = await response.json()
                    job_id = job_data.get("id")

                    logger.info(f"Created transcription job: {job_id}")

                # Update progress: Processing
                if progress_callback:
                    await progress_callback(30.0, "Transcription in progress...")

                # Poll for job completion
                status_url = f"{endpoint_url}/{job_id}"
                max_attempts = 180  # 15 minutes max wait (increased for longer audio files)
                attempt = 0

                while attempt < max_attempts:
                    await asyncio.sleep(5)  # Poll every 5 seconds

                    async with session.get(
                        status_url,
                        headers=self.headers
                    ) as status_response:
                        if status_response.status != 200:
                            response_text = await status_response.text()
                            logger.warning(f"Failed to get job status: {status_response.status}, response: {response_text}")
                            attempt += 1
                            continue

                        job_status = await status_response.json()
                        status = job_status.get("status")

                        # Log detailed job status for debugging (but exclude the large base64 input)
                        logger.info(f"Job {job_id} status: {status}, attempt {attempt}/{max_attempts}")

                        # Create a cleaned version for logging that excludes sensitive data
                        log_status = job_status.copy()
                        if "input" in log_status and isinstance(log_status["input"], dict):
                            # Hide both audio data and signed URLs
                            if "audio" in log_status["input"]:
                                log_status["input"]["audio"] = f"<base64 audio data, {len(log_status['input'].get('audio', ''))} chars>"
                            if "url" in log_status["input"]:
                                log_status["input"]["url"] = "<signed URL hidden>"

                        logger.debug(f"Job status (sensitive data excluded): {json.dumps(log_status, indent=2)}")

                        # Update progress based on status
                        if progress_callback:
                            # Calculate progress (30% to 65% range)
                            progress_pct = 30.0 + (attempt / max_attempts) * 35.0
                            time_elapsed = attempt * 5  # seconds

                            # Create informative status message
                            if time_elapsed > 60:
                                time_msg = f"{time_elapsed // 60}m {time_elapsed % 60}s"
                            else:
                                time_msg = f"{time_elapsed}s"

                            await progress_callback(
                                min(progress_pct, 65.0),
                                f"Processing audio ({status}, {time_msg} elapsed)..."
                            )

                        if status == "succeeded":
                            # Get the full job status response
                            result = job_status

                            # Log the raw output for debugging
                            logger.info(f"Job {job_id} succeeded with response keys: {list(result.keys())}")

                            # Check if there's an output URL or separate endpoint for results
                            # Salad might store results separately
                            transcription_text = ""
                            segments = []

                            # Check various possible locations for the transcription
                            # 1. Direct in response
                            transcription_text = result.get("text", "")

                            # 2. In output field
                            if not transcription_text and "output" in result:
                                output = result["output"]
                                if isinstance(output, dict):
                                    transcription_text = output.get("text", "")
                                elif isinstance(output, str):
                                    transcription_text = output

                            # 3. In events - Salad typically returns results in the last event
                            if not transcription_text and "events" in result:
                                events = result.get("events", [])
                                logger.debug(f"Job has {len(events)} events")

                                # Check the last event for output
                                if events:
                                    for event in reversed(events):  # Check from latest event backwards
                                        if isinstance(event, dict):
                                            # Check if event has output field
                                            if "output" in event:
                                                event_output = event["output"]
                                                if isinstance(event_output, dict):
                                                    transcription_text = event_output.get("text", "")
                                                    if not segments:
                                                        segments = event_output.get("segments", [])
                                                elif isinstance(event_output, str):
                                                    transcription_text = event_output

                                                if transcription_text:
                                                    logger.info(f"Found transcription in event output")
                                                    break

                            # 4. We might need to make another API call to get results
                            if not transcription_text:
                                # Check if there's a result_url or output_url
                                result_url = result.get("result_url") or result.get("output_url")
                                if result_url:
                                    logger.info(f"Fetching results from: {result_url}")
                                    async with session.get(result_url, headers=self.headers) as result_response:
                                        if result_response.status == 200:
                                            output_data = await result_response.json()
                                            transcription_text = output_data.get("text", "")
                                            segments = output_data.get("segments", [])

                            # Get segments if we haven't already
                            if not segments:
                                segments = result.get("segments", [])
                                if not segments and "output" in result and isinstance(result["output"], dict):
                                    segments = result["output"].get("segments", [])

                            if not transcription_text:
                                logger.error(f"Job {job_id} succeeded but no transcription text was returned")
                                logger.error(f"Full job response: {json.dumps(job_status, indent=2)}")
                                raise Exception("Transcription succeeded but no text was generated. Check audio file quality.")

                            # Convert Salad segments to Whisper-compatible format with speaker info
                            formatted_segments = []
                            for segment in segments:
                                segment_data = {
                                    "id": segment.get("id", 0),
                                    "start": segment.get("start", 0.0),
                                    "end": segment.get("end", 0.0),
                                    "text": segment.get("text", ""),
                                    "tokens": segment.get("tokens", []),
                                    "temperature": segment.get("temperature", 0.0),
                                    "avg_logprob": segment.get("avg_logprob", 0.0),
                                    "compression_ratio": segment.get("compression_ratio", 0.0),
                                    "no_speech_prob": segment.get("no_speech_prob", 0.0)
                                }

                                # Include speaker information if available from diarization
                                if "speaker" in segment:
                                    segment_data["speaker"] = segment["speaker"]
                                if "words" in segment:
                                    # Include word-level timestamps and speaker info if available
                                    segment_data["words"] = segment["words"]

                                formatted_segments.append(segment_data)

                            logger.info(f"Transcription completed successfully: {len(transcription_text)} characters, {len(formatted_segments)} segments")

                            # Update progress: Complete
                            if progress_callback:
                                await progress_callback(100.0, "Transcription completed")

                            # Extract detected language from result
                            detected_language = result.get("language")
                            if not detected_language and "output" in result and isinstance(result["output"], dict):
                                detected_language = result["output"].get("language")

                            # Log language detection results
                            if detected_language:
                                logger.info(f"Detected language: {detected_language}")

                            # Extract speaker information if available
                            speakers = result.get("speakers", [])
                            if not speakers and "output" in result and isinstance(result["output"], dict):
                                speakers = result["output"].get("speakers", [])

                            if speakers:
                                logger.info(f"Identified {len(speakers)} unique speakers")

                            return {
                                "text": transcription_text,
                                "segments": formatted_segments,
                                "language": detected_language or language or "unknown",
                                "duration": result.get("duration", 0),
                                "speakers": speakers,  # Include speaker information
                                "service": "salad"
                            }

                        elif status == "failed":
                            error_msg = job_status.get("error", job_status.get("message", "Unknown error"))
                            logger.error(f"Transcription job {job_id} failed: {error_msg}")
                            logger.error(f"Full failed job response: {json.dumps(job_status, indent=2)}")
                            raise Exception(f"Transcription failed: {error_msg}")

                        elif status in ["pending", "running"]:
                            # Continue polling
                            attempt += 1
                        else:
                            logger.warning(f"Unknown job status: {status}")
                            attempt += 1

                # Timeout
                raise Exception("Transcription timed out after 15 minutes")

        except Exception as e:
            logger.error(f"Salad transcription error: {sanitize_for_log(str(e))}", exc_info=True)
            raise

    async def check_service_health(self) -> bool:
        """
        Check if Salad transcription service is available.

        Returns:
            True if service is healthy, False otherwise
        """
        try:
            # Check organization access
            org_url = f"{self.base_url}/organizations/{self.organization_name}"

            # Disable SSL verification for development
            ssl_context = ssl.create_default_context()
            ssl_context.check_hostname = False
            ssl_context.verify_mode = ssl.CERT_NONE
            connector = aiohttp.TCPConnector(ssl=ssl_context)
            async with aiohttp.ClientSession(connector=connector) as session:
                async with session.get(
                    org_url,
                    headers=self.headers
                ) as response:
                    if response.status == 200:
                        logger.info("Salad transcription service is healthy")
                        return True
                    else:
                        logger.warning(f"Salad service check failed: {response.status}")
                        return False

        except Exception as e:
            logger.error(f"Salad health check error: {sanitize_for_log(str(e))}")
            return False

    def is_model_loaded(self) -> bool:
        """
        For compatibility with Whisper service interface.
        Salad is always ready as it's a cloud service.
        """
        return True


# Singleton instance management
_salad_service_instance: Optional[SaladTranscriptionService] = None


def get_salad_service(
    api_key: Optional[str] = None,
    organization_name: Optional[str] = None
) -> SaladTranscriptionService:
    """
    Get or create a singleton instance of Salad transcription service.

    Args:
        api_key: Salad API key (reads from env if not provided)
        organization_name: Salad organization name (reads from env if not provided)

    Returns:
        SaladTranscriptionService instance
    """
    global _salad_service_instance

    if _salad_service_instance is None:
        # Get credentials from environment if not provided
        api_key = api_key or os.getenv("SALAD_API_KEY")
        organization_name = organization_name or os.getenv("SALAD_ORGANIZATION")

        if not api_key or not organization_name:
            raise ValueError(
                "Salad API credentials not provided. "
                "Set SALAD_API_KEY and SALAD_ORGANIZATION environment variables "
                "or provide them as parameters."
            )

        _salad_service_instance = SaladTranscriptionService(
            api_key=api_key,
            organization_name=organization_name
        )

    return _salad_service_instance