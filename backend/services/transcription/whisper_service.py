"""
Whisper transcription service for real-time audio processing.
Uses faster-whisper for optimized performance.
"""

import os

# Set environment variables BEFORE importing anything else
os.environ['CURL_CA_BUNDLE'] = ''
os.environ['REQUESTS_CA_BUNDLE'] = ''
os.environ['HF_HUB_DISABLE_SSL_VERIFY'] = '1'
# Don't set offline mode - we need to download models
# os.environ['TRANSFORMERS_OFFLINE'] = '1'
# os.environ['HF_DATASETS_OFFLINE'] = '1'

import asyncio
import logging
import tempfile
import numpy as np
from pathlib import Path
from typing import Optional, Dict, List
import soundfile as sf
from faster_whisper import WhisperModel
import torch

from utils.monitoring import monitor_operation, monitor_sync_operation, monitor_batch_operation, MonitoringContext

logger = logging.getLogger(__name__)


class WhisperTranscriptionService:
    """Service for transcribing audio using Whisper model."""
    
    def __init__(
        self,
        model_size: str = "deepdml/faster-whisper-large-v3-turbo-ct2",  # Optimized turbo model, no auth required
        device: str = "auto",
        compute_type: str = "float16"
    ):
        """
        Initialize Whisper service.

        Args:
            model_size: Whisper model size or HuggingFace model ID
            device: Device to run on ('cpu', 'cuda', or 'auto')
            compute_type: Compute type for inference
        """
        # Auto-detect device with MPS (Apple Silicon) support
        if device == "auto":
            if torch.cuda.is_available():
                self.device = "cuda"
                logger.info("CUDA GPU detected - using GPU acceleration")
            elif torch.backends.mps.is_available():
                self.device = "cpu"  # Faster-whisper doesn't support MPS yet, but CPU on M1/M2 is fast
                logger.info("Apple Silicon detected - using optimized CPU")
            else:
                self.device = "cpu"
                logger.info("Using CPU for transcription")
        else:
            self.device = device
            
        # Optimize compute type based on hardware
        if self.device == "cuda":
            self.compute_type = "float16"  # Best for NVIDIA GPUs
        elif torch.backends.mps.is_available():
            self.compute_type = "int8"  # INT8 quantization for faster inference on Apple Silicon
        else:
            self.compute_type = "int8"  # Best for regular CPU
            
        logger.info(f"Initializing Whisper model: {model_size} on {self.device}")

        with MonitoringContext(
            "whisper_model_initialization",
            metadata={
                "model_size": model_size,
                "device": self.device,
                "compute_type": self.compute_type
            }
        ) as ctx:
            try:
                # Load model from HuggingFace (will use cached version if available)
                self.model = WhisperModel(
                    model_size,
                    device=self.device,
                    compute_type=self.compute_type,
                    download_root="./models/whisper",
                    local_files_only=False  # Allow download from HuggingFace if not cached
                )

                logger.info(f"Model '{model_size}' loaded successfully")
                ctx.update(output={"model_loaded": True, "model": model_size})
            except Exception as e:
                logger.error(f"Failed to load model '{model_size}': {e}")
                raise
        
        self.sample_rate = 16000  # Whisper expects 16kHz audio
        
    def is_model_loaded(self) -> bool:
        """Check if the Whisper model is loaded and ready."""
        return hasattr(self, 'model') and self.model is not None
        
    @monitor_operation("transcribe_audio_file", "transcription", capture_args=True, capture_result=True)
    async def transcribe_audio_file(
        self,
        audio_path: str,
        language: Optional[str] = None,
        initial_prompt: Optional[str] = None,
        progress_callback: Optional[callable] = None
    ) -> Dict:
        """
        Transcribe an audio file.
        
        Args:
            audio_path: Path to audio file
            language: Language code (e.g., 'en', 'es', 'fr')
            initial_prompt: Optional prompt to guide transcription
            progress_callback: Optional callback for progress updates
            
        Returns:
            Transcription result with text and metadata
        """
        try:
            # Create a shared progress dict for sync context
            progress_info = {"progress": 0, "message": "Starting transcription..."}
            
            # Start background task to monitor progress
            monitor_task = None
            if progress_callback:
                async def monitor_progress():
                    last_progress = -1
                    while progress_info["progress"] < 100:
                        if progress_info["progress"] != last_progress:
                            last_progress = progress_info["progress"]
                            await progress_callback(last_progress, progress_info["message"])
                        await asyncio.sleep(0.5)
                
                monitor_task = asyncio.create_task(monitor_progress())
            
            # Run transcription in executor to avoid blocking
            loop = asyncio.get_event_loop()
            result = await loop.run_in_executor(
                None,
                self._transcribe_file_sync,
                audio_path,
                language,
                initial_prompt,
                progress_info
            )
            
            # Stop monitoring
            if monitor_task:
                progress_info["progress"] = 100
                await asyncio.sleep(0.1)  # Give monitor task time to report final progress
                monitor_task.cancel()
                try:
                    await monitor_task
                except asyncio.CancelledError:
                    pass
            
            return result
        except Exception as e:
            logger.error(f"Transcription error: {e}")
            raise
            
    @monitor_sync_operation("transcribe_file_sync", "transcription")
    def _transcribe_file_sync(
        self,
        audio_path: str,
        language: Optional[str],
        initial_prompt: Optional[str],
        progress_info: Dict[str, any] = None
    ) -> Dict:
        """Synchronous file transcription."""
        # Update progress info
        if progress_info:
            progress_info["progress"] = 5
            progress_info["message"] = "Loading audio file..."

        logger.info(f"Starting transcription of: {audio_path}")

        segments, info = self.model.transcribe(
            audio_path,
            language=language,
            initial_prompt=initial_prompt,  # Use provided prompt or None

            # Performance optimization
            beam_size=5,  # Good balance of quality vs speed (use 1 for max speed)
            best_of=5,  # Number of candidates to consider
            patience=1.0,  # Beam search patience

            # Quality improvements
            temperature=0.0,  # Deterministic output (no randomness)
            compression_ratio_threshold=2.4,  # Detect hallucinations in silent parts
            log_prob_threshold=-1.0,  # Filter low-confidence segments
            no_speech_threshold=0.6,  # Silence detection sensitivity (lower = more aggressive)

            # Context and timestamps
            condition_on_previous_text=True,  # Better context-aware transcription
            word_timestamps=True,  # Enable word-level timestamps

            # VAD (Voice Activity Detection) - removes silence
            vad_filter=True,  # Enable VAD to skip silent parts (2-3x faster)
            vad_parameters={
                "threshold": 0.5,  # Speech detection sensitivity (0.3-0.7 range)
                "min_speech_duration_ms": 250,  # Minimum speech duration
                "min_silence_duration_ms": 2000,  # Minimum silence to skip (2 seconds)
                "speech_pad_ms": 400,  # Padding around speech segments
            },

            # Hallucination reduction
            hallucination_silence_threshold=None,  # Auto-detect hallucinations
            repetition_penalty=1.0,  # Prevent repetitive output
        )
        
        # Collect segments with real-time progress tracking
        transcription_segments = []
        full_text = []

        # Get total duration for progress calculation
        total_duration = info.duration if hasattr(info, 'duration') else 0
        logger.info(f"Audio duration: {total_duration:.1f}s, detected language: {info.language}")
        logger.info(f"Starting real-time transcription (progress will be logged as segments are generated)...")

        # Process segments in real-time as they're generated (don't convert to list)
        segment_count = 0
        for segment in segments:
            segment_count += 1

            segment_data = {
                "start": segment.start,
                "end": segment.end,
                "text": segment.text.strip(),
                "tokens": segment.tokens,
                "temperature": segment.temperature,
                "avg_logprob": segment.avg_logprob,
                "compression_ratio": segment.compression_ratio,
                "no_speech_prob": segment.no_speech_prob
            }
            transcription_segments.append(segment_data)
            full_text.append(segment.text.strip())

            # Update progress info and log in real-time
            if total_duration > 0:
                # Calculate progress based on time processed
                time_progress = (segment.end / total_duration) * 100
                progress = min(time_progress, 99)  # Cap at 99% until fully complete

                if progress_info:
                    if segment_count % 3 == 0:  # Update job progress every 3rd segment
                        progress_info["progress"] = progress
                        progress_info["message"] = f"Transcribing audio... {int(segment.end)}s of {int(total_duration)}s"

                # Log progress every 5 segments for real-time visibility
                if segment_count % 5 == 0:
                    logger.info(f"Progress: {progress:.0f}% - Segment {segment_count} - {int(segment.end)}s / {int(total_duration)}s transcribed")

        logger.info(f"Transcription generation complete: {segment_count} segments generated")
            
        final_text = " ".join(full_text)
        logger.info(f"Transcription complete: {len(final_text)} characters, {len(transcription_segments)} segments")

        return {
            "text": final_text,
            "segments": transcription_segments,
            "language": info.language,
            "language_probability": info.language_probability,
            "duration": info.duration,
            "transcription_options": info.transcription_options,
        }
        
    @monitor_operation("transcribe_audio_buffer", "transcription", capture_args=False, capture_result=True)
    async def transcribe_audio_buffer(
        self,
        audio_buffer: bytes,
        sample_rate: int = 16000,
        language: Optional[str] = None
    ) -> Dict:
        """
        Transcribe audio from a buffer.
        
        Args:
            audio_buffer: Raw audio bytes (PCM16)
            sample_rate: Sample rate of audio
            language: Language code
            
        Returns:
            Transcription result
        """
        # Convert bytes to numpy array
        audio_array = np.frombuffer(audio_buffer, dtype=np.int16)
        
        # Resample if necessary
        if sample_rate != self.sample_rate:
            import librosa
            audio_float = audio_array.astype(np.float32) / 32768.0
            audio_float = librosa.resample(
                audio_float,
                orig_sr=sample_rate,
                target_sr=self.sample_rate
            )
            audio_array = (audio_float * 32768.0).astype(np.int16)
            
        # Save to temporary file (faster-whisper requires file input)
        with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as temp_file:
            sf.write(
                temp_file.name,
                audio_array,
                self.sample_rate,
                subtype='PCM_16'
            )
            temp_path = temp_file.name
            
        try:
            # Transcribe temporary file
            result = await self.transcribe_audio_file(temp_path, language)
            return result
        finally:
            # Clean up temporary file
            Path(temp_path).unlink(missing_ok=True)
            
    @monitor_batch_operation("transcribe_stream", batch_size=10, operation_type="streaming")
    async def transcribe_stream(
        self,
        audio_chunks: asyncio.Queue,
        language: Optional[str] = None,
        chunk_duration: float = 5.0
    ):
        """
        Transcribe audio stream in real-time.
        
        Args:
            audio_chunks: Queue of audio chunks
            language: Language code
            chunk_duration: Duration of chunks to process (seconds)
            
        Yields:
            Transcription segments as they're processed
        """
        buffer = []
        buffer_duration = 0.0
        
        while True:
            try:
                # Get audio chunk from queue
                chunk = await asyncio.wait_for(
                    audio_chunks.get(),
                    timeout=10.0
                )
                
                if chunk is None:
                    # End of stream signal
                    if buffer:
                        # Process remaining buffer
                        audio_data = np.concatenate(buffer)
                        result = await self.transcribe_audio_buffer(
                            audio_data.tobytes(),
                            self.sample_rate,
                            language
                        )
                        yield result
                    break
                    
                # Add chunk to buffer
                audio_array = np.frombuffer(chunk, dtype=np.int16)
                buffer.append(audio_array)
                buffer_duration += len(audio_array) / self.sample_rate
                
                # Process when buffer reaches target duration
                if buffer_duration >= chunk_duration:
                    audio_data = np.concatenate(buffer)
                    
                    # Keep overlap for context
                    overlap_samples = int(0.5 * self.sample_rate)  # 0.5 second overlap
                    
                    # Process current buffer
                    result = await self.transcribe_audio_buffer(
                        audio_data.tobytes(),
                        self.sample_rate,
                        language
                    )
                    
                    # Yield result
                    yield result
                    
                    # Reset buffer with overlap
                    if len(audio_data) > overlap_samples:
                        buffer = [audio_data[-overlap_samples:]]
                        buffer_duration = overlap_samples / self.sample_rate
                    else:
                        buffer = []
                        buffer_duration = 0.0
                        
            except asyncio.TimeoutError:
                # No new audio for 10 seconds
                logger.warning("Audio stream timeout")
                continue
            except Exception as e:
                logger.error(f"Stream transcription error: {e}")
                continue
                
    def get_supported_languages(self) -> List[str]:
        """Get list of supported language codes."""
        return [
            "en", "zh", "de", "es", "ru", "ko", "fr", "ja", "pt", "tr",
            "pl", "ca", "nl", "ar", "sv", "it", "id", "hi", "fi", "vi",
            "he", "uk", "el", "ms", "cs", "ro", "da", "hu", "ta", "no",
            "th", "ur", "hr", "bg", "lt", "la", "mi", "ml", "cy", "sk",
            "te", "fa", "lv", "bn", "sr", "az", "sl", "kn", "et", "mk",
            "br", "eu", "is", "hy", "ne", "mn", "bs", "kk", "sq", "sw",
            "gl", "mr", "pa", "si", "km", "sn", "yo", "so", "af", "oc",
            "ka", "be", "tg", "sd", "gu", "am", "yi", "lo", "uz", "fo",
            "ht", "ps", "tk", "nn", "mt", "sa", "lb", "my", "bo", "tl",
            "mg", "as", "tt", "haw", "ln", "ha", "ba", "jw", "su"
        ]


# Singleton instance
_whisper_service: Optional[WhisperTranscriptionService] = None


def get_whisper_service() -> WhisperTranscriptionService:
    """Get or create Whisper service singleton."""
    global _whisper_service
    if _whisper_service is None:
        _whisper_service = WhisperTranscriptionService()
    return _whisper_service