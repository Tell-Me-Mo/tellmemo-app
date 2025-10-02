"""Fast-langdetect service initialization with SSL bypass for model download."""

import ssl
import urllib.request
from typing import Dict, Any, Optional
import logging

from config import get_settings
from utils.logger import get_logger

settings = get_settings()
logger = get_logger(__name__)

# Global flag to track initialization
_initialized = False


def init_langdetect_with_ssl_bypass():
    """Initialize fast-langdetect with SSL bypass for model download."""
    global _initialized

    if _initialized:
        logger.debug("fast-langdetect already initialized")
        return True

    if not settings.detect_language or not settings.enable_multilingual:
        logger.info("Language detection disabled in settings")
        return False

    try:
        # Bypass SSL verification for model download
        original_https_context = ssl._create_default_https_context
        ssl._create_default_https_context = ssl._create_unverified_context

        logger.info("Initializing fast-langdetect with SSL bypass...")

        # Import and initialize fast-langdetect
        from fast_langdetect import detect

        # Trigger model download by doing a test detection
        # This will download the model if not already present
        test_result = detect("Hello world")

        if test_result:
            logger.info(f"✅ fast-langdetect initialized successfully. Test detection: {test_result[0]}")
            _initialized = True
        else:
            logger.warning("fast-langdetect initialized but test detection returned empty")
            _initialized = True

        # Restore original SSL context
        ssl._create_default_https_context = original_https_context

        return True

    except ImportError:
        logger.warning("fast-langdetect not installed, language detection will be disabled")
        return False
    except Exception as e:
        logger.error(f"Failed to initialize fast-langdetect: {e}")
        # Restore original SSL context even on error
        try:
            ssl._create_default_https_context = original_https_context
        except:
            pass
        return False


async def init_langdetect_service():
    """Async wrapper for langdetect initialization."""
    return init_langdetect_with_ssl_bypass()


def detect_language(text: str) -> Dict[str, Any]:
    """Detect language of text using fast-langdetect.

    Args:
        text: Text to detect language for

    Returns:
        Dict with 'language' code, 'confidence' score, and other metadata
    """
    if not _initialized:
        # Try to initialize if not done yet
        if not init_langdetect_with_ssl_bypass():
            return {'language': 'en', 'confidence': 0.0, 'error': 'Not initialized'}

    try:
        from fast_langdetect import detect

        # Limit text length for detection
        sample_text = text[:5000] if len(text) > 5000 else text

        # Detect language
        result = detect(sample_text)

        if isinstance(result, list) and len(result) > 0:
            # Get the first (most likely) result
            language = result[0].get('lang', 'en')
            confidence = result[0].get('score', 0.0)

            # Get top 3 candidates
            all_detected = [
                {"lang": lang.get('lang', ''), "prob": lang.get('score', 0.0)}
                for lang in result[:3]
            ]
        else:
            language = 'en'
            confidence = 0.0
            all_detected = []

        # Check if language is supported
        is_supported = language in settings.supported_languages_list

        return {
            'language': language,
            'confidence': confidence,
            'is_supported': is_supported,
            'all_detected': all_detected
        }

    except Exception as e:
        logger.warning(f"Language detection failed: {e}")
        return {'language': 'en', 'confidence': 0.0, 'error': str(e)}


# Create a singleton instance
class LanguageDetectionService:
    """Service for language detection using fast-langdetect."""

    def __init__(self):
        self.initialized = False

    async def initialize(self):
        """Initialize the language detection service."""
        self.initialized = await init_langdetect_service()
        return self.initialized

    def detect(self, text: str) -> Dict[str, Any]:
        """Detect language of text."""
        return detect_language(text)

    def is_available(self) -> bool:
        """Check if language detection is available."""
        return _initialized


# Singleton instance
language_detection_service = LanguageDetectionService()