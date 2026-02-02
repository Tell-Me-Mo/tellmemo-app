"""Unit tests for language detection service format handling.

Tests the detect_language function's ability to handle different
return formats from fast_langdetect library.
"""

import pytest
from unittest.mock import patch, MagicMock


class TestLangdetectFormatHandling:
    """Tests for handling various response formats from fast_langdetect."""

    @pytest.fixture(autouse=True)
    def mock_initialization(self):
        """Mock the initialization state to allow testing detect_language."""
        with patch('services.llm.langdetect_service._initialized', True):
            yield

    @pytest.fixture
    def mock_settings(self):
        """Mock settings for tests."""
        settings = MagicMock()
        settings.supported_languages_list = ['en', 'es', 'fr', 'de', 'uk', 'pl']
        return settings

    def test_dict_format_with_lang_and_score(self, mock_settings):
        """Test handling dict format: {'lang': 'en', 'score': 0.95}"""
        mock_result = [
            {'lang': 'en', 'score': 0.95},
            {'lang': 'de', 'score': 0.03},
            {'lang': 'fr', 'score': 0.02}
        ]

        with patch('fast_langdetect.detect', return_value=mock_result):
            with patch('services.llm.langdetect_service.settings', mock_settings):
                from services.llm.langdetect_service import detect_language
                result = detect_language("Hello world")

        assert result['language'] == 'en'
        assert result['confidence'] == 0.95
        assert result['is_supported'] is True
        assert len(result['all_detected']) == 3

    def test_dict_format_with_language_key(self, mock_settings):
        """Test handling dict format with 'language' key instead of 'lang'."""
        mock_result = [
            {'language': 'es', 'confidence': 0.88}
        ]

        with patch('fast_langdetect.detect', return_value=mock_result):
            with patch('services.llm.langdetect_service.settings', mock_settings):
                from services.llm.langdetect_service import detect_language
                result = detect_language("Hola mundo")

        assert result['language'] == 'es'
        assert result['confidence'] == 0.88

    def test_tuple_format(self, mock_settings):
        """Test handling tuple format: ('en', 0.95)"""
        mock_result = [
            ('en', 0.95),
            ('de', 0.03),
            ('fr', 0.02)
        ]

        with patch('fast_langdetect.detect', return_value=mock_result):
            with patch('services.llm.langdetect_service.settings', mock_settings):
                from services.llm.langdetect_service import detect_language
                result = detect_language("Hello world")

        assert result['language'] == 'en'
        assert result['confidence'] == 0.95
        assert len(result['all_detected']) == 3
        assert result['all_detected'][0]['lang'] == 'en'

    def test_string_format(self, mock_settings):
        """Test handling simple string format: 'en'"""
        mock_result = ['en', 'de', 'fr']

        with patch('fast_langdetect.detect', return_value=mock_result):
            with patch('services.llm.langdetect_service.settings', mock_settings):
                from services.llm.langdetect_service import detect_language
                result = detect_language("Hello world")

        assert result['language'] == 'en'
        assert result['confidence'] == 0.95  # Default high confidence for top result
        assert len(result['all_detected']) == 3

    def test_uppercase_language_code_normalized(self, mock_settings):
        """Test that uppercase language codes are normalized to lowercase."""
        mock_result = ['EN', 'DE', 'FR']

        with patch('fast_langdetect.detect', return_value=mock_result):
            with patch('services.llm.langdetect_service.settings', mock_settings):
                from services.llm.langdetect_service import detect_language
                result = detect_language("Hello world")

        assert result['language'] == 'en'
        assert all(d['lang'].islower() for d in result['all_detected'])

    def test_empty_result_fallback(self, mock_settings):
        """Test fallback to 'en' when detection returns empty list."""
        mock_result = []

        with patch('fast_langdetect.detect', return_value=mock_result):
            with patch('services.llm.langdetect_service.settings', mock_settings):
                from services.llm.langdetect_service import detect_language
                result = detect_language("Test text")

        assert result['language'] == 'en'
        assert result['confidence'] == 0.0
        assert result['all_detected'] == []

    def test_unsupported_language_flagged(self, mock_settings):
        """Test that unsupported languages are flagged correctly."""
        mock_result = [{'lang': 'ja', 'score': 0.99}]  # Japanese not in supported list

        with patch('fast_langdetect.detect', return_value=mock_result):
            with patch('services.llm.langdetect_service.settings', mock_settings):
                from services.llm.langdetect_service import detect_language
                result = detect_language("こんにちは")

        assert result['language'] == 'ja'
        assert result['is_supported'] is False

    def test_exception_handling(self, mock_settings):
        """Test that exceptions are caught and return fallback."""
        with patch('fast_langdetect.detect', side_effect=Exception("Detection failed")):
            with patch('services.llm.langdetect_service.settings', mock_settings):
                from services.llm.langdetect_service import detect_language
                result = detect_language("Test text")

        assert result['language'] == 'en'
        assert result['confidence'] == 0.0
        assert 'error' in result

    def test_long_text_truncated(self, mock_settings):
        """Test that text longer than 5000 chars is truncated."""
        long_text = "a" * 10000
        mock_result = [{'lang': 'en', 'score': 0.9}]

        with patch('fast_langdetect.detect', return_value=mock_result) as mock_detect:
            with patch('services.llm.langdetect_service.settings', mock_settings):
                from services.llm.langdetect_service import detect_language
                detect_language(long_text)

        # Verify the text passed to detect was truncated
        called_text = mock_detect.call_args[0][0]
        assert len(called_text) == 5000


class TestLangdetectInitialization:
    """Tests for service initialization behavior."""

    def test_not_initialized_returns_fallback(self):
        """Test that uninitialized state returns fallback when init fails."""
        with patch('services.llm.langdetect_service._initialized', False):
            with patch('services.llm.langdetect_service.init_langdetect_with_ssl_bypass', return_value=False):
                from services.llm.langdetect_service import detect_language
                result = detect_language("Test")

        assert result['language'] == 'en'
        assert result['confidence'] == 0.0
        assert 'error' in result
