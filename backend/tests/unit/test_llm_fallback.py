"""
Integration tests for LLM provider fallback functionality.

Tests the ProviderCascade and MultiProviderLLMClient's ability to:
- Automatically fallback to OpenAI when Claude is overloaded (529 error)
- Translate models to equivalent quality tiers
- Track fallback metadata for observability
"""

import pytest
from unittest.mock import Mock, AsyncMock, patch
from anthropic import APIError

from services.llm.multi_llm_client import (
    MultiProviderLLMClient,
    ClaudeProviderClient,
    OpenAIProviderClient,
    ProviderCascade
)
from models.integration import get_equivalent_model, AIProvider
from config import Settings


@pytest.fixture
def mock_settings():
    """Create mock settings with fallback enabled."""
    settings = Mock(spec=Settings)
    settings.anthropic_api_key = "test-claude-key"
    settings.openai_api_key = "test-openai-key"
    settings.enable_llm_fallback = True
    settings.fallback_provider = "openai"
    settings.primary_provider_max_retries = 2
    settings.fallback_provider_max_retries = 3
    settings.fallback_on_overload = True
    settings.fallback_on_rate_limit = False
    settings.llm_model = "claude-3-5-haiku-latest"
    settings.max_tokens = 4096
    settings.temperature = 0.7
    settings.api_env = "test"
    return settings


@pytest.fixture
def mock_claude_client():
    """Create a mock Claude client."""
    client = Mock(spec=ClaudeProviderClient)
    client.is_available.return_value = True
    return client


@pytest.fixture
def mock_openai_client():
    """Create a mock OpenAI client."""
    client = Mock(spec=OpenAIProviderClient)
    client.is_available.return_value = True
    return client


class TestModelTranslation:
    """Test model equivalence mapping."""

    def test_claude_to_openai_translation(self):
        """Test Claude models translate to correct OpenAI equivalents."""
        # Cost-optimized tier
        assert get_equivalent_model("claude-3-5-haiku-latest", AIProvider.OPENAI) == "gpt-4o-mini"

        # Balanced tier
        assert get_equivalent_model("claude-3-5-sonnet-20241022", AIProvider.OPENAI) == "gpt-4o"

        # High-capability tier
        assert get_equivalent_model("claude-opus-4-20250514", AIProvider.OPENAI) == "gpt-4o"

    def test_openai_to_claude_translation(self):
        """Test OpenAI models translate to correct Claude equivalents."""
        # Cost-optimized tier
        assert get_equivalent_model("gpt-4o-mini", AIProvider.CLAUDE) == "claude-3-5-haiku-latest"

        # Balanced tier
        assert get_equivalent_model("gpt-4o", AIProvider.CLAUDE) == "claude-3-5-sonnet-20241022"

    def test_unknown_model_returns_none(self):
        """Test that unknown models return None."""
        assert get_equivalent_model("unknown-model", AIProvider.OPENAI) is None


class TestProviderCascade:
    """Test ProviderCascade fallback logic."""

    @pytest.mark.asyncio
    async def test_successful_primary_no_fallback(self, mock_settings, mock_claude_client, mock_openai_client):
        """Test that successful primary call doesn't trigger fallback."""
        # Setup mock response
        mock_response = Mock()
        mock_response.content = [Mock(text="Success response")]
        mock_response.usage = Mock(input_tokens=100, output_tokens=200)

        mock_claude_client.create_message = AsyncMock(return_value=mock_response)

        # Create cascade
        cascade = ProviderCascade(
            primary_client=mock_claude_client,
            primary_provider_name="Claude",
            fallback_client=mock_openai_client,
            fallback_provider_name="OpenAI",
            settings=mock_settings
        )

        # Execute
        response, metadata = await cascade.execute_with_fallback(
            operation="create_message",
            primary_model="claude-3-5-haiku-latest",
            prompt="Test prompt",
            model="claude-3-5-haiku-latest",
            max_tokens=100,
            temperature=0.7
        )

        # Assertions
        assert response == mock_response
        assert metadata["fallback_triggered"] is False
        assert metadata["provider_used"] == "Claude"
        assert len(metadata["attempts"]) == 1
        assert metadata["attempts"][0]["success"] is True

        # Verify only primary was called
        mock_claude_client.create_message.assert_called_once()
        mock_openai_client.create_message.assert_not_called()

    @pytest.mark.asyncio
    async def test_fallback_on_529_error(self, mock_settings, mock_claude_client, mock_openai_client):
        """Test that 529 error triggers immediate fallback to OpenAI."""
        # Setup Claude to return 529 error
        claude_error = Exception("Error code: 529 - {'type': 'error', 'error': {'type': 'overloaded_error'}}")
        mock_claude_client.create_message = AsyncMock(side_effect=claude_error)

        # Setup OpenAI success response
        openai_response = Mock()
        openai_response.content = [Mock(text="Fallback success")]
        openai_response.usage = Mock(prompt_tokens=100, completion_tokens=200)
        mock_openai_client.create_message = AsyncMock(return_value=openai_response)

        # Create cascade
        cascade = ProviderCascade(
            primary_client=mock_claude_client,
            primary_provider_name="Claude",
            fallback_client=mock_openai_client,
            fallback_provider_name="OpenAI",
            settings=mock_settings
        )

        # Execute
        response, metadata = await cascade.execute_with_fallback(
            operation="create_message",
            primary_model="claude-3-5-haiku-latest",
            prompt="Test prompt",
            model="claude-3-5-haiku-latest",
            max_tokens=100,
            temperature=0.7
        )

        # Assertions
        assert response == openai_response
        assert metadata["fallback_triggered"] is True
        assert metadata["fallback_reason"] == "overloaded"
        assert metadata["provider_used"] == "OpenAI"
        assert metadata["primary_model"] == "claude-3-5-haiku-latest"
        assert metadata["fallback_model"] == "gpt-4o-mini"  # Translated model
        assert len(metadata["attempts"]) == 2  # Primary + fallback

        # Verify both were called
        mock_claude_client.create_message.assert_called_once()
        mock_openai_client.create_message.assert_called_once()

        # Verify OpenAI was called with translated model
        openai_call_args = mock_openai_client.create_message.call_args
        assert openai_call_args[1]["model"] == "gpt-4o-mini"

    @pytest.mark.asyncio
    async def test_fallback_disabled_raises_error(self, mock_settings, mock_claude_client, mock_openai_client):
        """Test that fallback doesn't happen when disabled."""
        # Disable fallback
        mock_settings.fallback_on_overload = False

        # Setup Claude to return 529 error
        claude_error = Exception("Error code: 529 - overloaded")
        mock_claude_client.create_message = AsyncMock(side_effect=claude_error)

        # Create cascade
        cascade = ProviderCascade(
            primary_client=mock_claude_client,
            primary_provider_name="Claude",
            fallback_client=mock_openai_client,
            fallback_provider_name="OpenAI",
            settings=mock_settings
        )

        # Execute and expect exception
        with pytest.raises(Exception):
            await cascade.execute_with_fallback(
                operation="create_message",
                primary_model="claude-3-5-haiku-latest",
                prompt="Test prompt",
                model="claude-3-5-haiku-latest",
                max_tokens=100,
                temperature=0.7
            )

        # Verify fallback was NOT called
        mock_openai_client.create_message.assert_not_called()

    @pytest.mark.asyncio
    async def test_503_error_triggers_fallback(self, mock_settings, mock_claude_client, mock_openai_client):
        """Test that 503 service unavailable also triggers fallback."""
        # Setup Claude to return 503 error
        claude_error = Exception("Error code: 503 - Service Unavailable")
        mock_claude_client.create_message = AsyncMock(side_effect=claude_error)

        # Setup OpenAI success
        openai_response = Mock()
        openai_response.content = [Mock(text="Fallback success")]
        openai_response.usage = Mock(prompt_tokens=100, completion_tokens=200)
        mock_openai_client.create_message = AsyncMock(return_value=openai_response)

        # Create cascade
        cascade = ProviderCascade(
            primary_client=mock_claude_client,
            primary_provider_name="Claude",
            fallback_client=mock_openai_client,
            fallback_provider_name="OpenAI",
            settings=mock_settings
        )

        # Execute
        response, metadata = await cascade.execute_with_fallback(
            operation="create_message",
            primary_model="claude-3-5-haiku-latest",
            prompt="Test prompt",
            model="claude-3-5-haiku-latest",
            max_tokens=100,
            temperature=0.7
        )

        # Assertions
        assert metadata["fallback_triggered"] is True
        assert metadata["fallback_reason"] == "overloaded"
        mock_openai_client.create_message.assert_called_once()


class TestMultiProviderLLMClientFallback:
    """Test MultiProviderLLMClient integration with fallback."""

    @pytest.mark.asyncio
    async def test_client_initializes_with_both_providers(self, mock_settings):
        """Test that client initializes both Claude and OpenAI when keys are present."""
        with patch('services.llm.multi_llm_client.ClaudeProviderClient') as MockClaude, \
             patch('services.llm.multi_llm_client.OpenAIProviderClient') as MockOpenAI:

            # Create mock instances
            mock_claude = Mock()
            mock_claude.is_available.return_value = True
            MockClaude.return_value = mock_claude

            mock_openai = Mock()
            mock_openai.is_available.return_value = True
            MockOpenAI.return_value = mock_openai

            # Initialize client
            client = MultiProviderLLMClient(settings=mock_settings)

            # Verify both providers initialized
            assert client.primary_provider_client is not None
            assert client.secondary_provider_client is not None
            assert client.primary_provider_name == "Claude"
            assert client.secondary_provider_name == "OpenAI"

    # Note: End-to-end integration test with real API clients would be done in
    # integration tests. The ProviderCascade tests above already validate the
    # full fallback logic comprehensively.


class TestFallbackMetadata:
    """Test fallback metadata tracking."""

    @pytest.mark.asyncio
    async def test_metadata_includes_all_attempts(self, mock_settings, mock_claude_client, mock_openai_client):
        """Test that metadata tracks all provider attempts."""
        # Setup Claude failure and OpenAI success
        claude_error = Exception("Error code: 529")
        mock_claude_client.create_message = AsyncMock(side_effect=claude_error)

        openai_response = Mock()
        openai_response.content = [Mock(text="Success")]
        openai_response.usage = Mock(prompt_tokens=50, completion_tokens=100)
        mock_openai_client.create_message = AsyncMock(return_value=openai_response)

        # Create cascade
        cascade = ProviderCascade(
            primary_client=mock_claude_client,
            primary_provider_name="Claude",
            fallback_client=mock_openai_client,
            fallback_provider_name="OpenAI",
            settings=mock_settings
        )

        # Execute
        response, metadata = await cascade.execute_with_fallback(
            operation="create_message",
            primary_model="claude-3-5-haiku-latest",
            prompt="Test",
            model="claude-3-5-haiku-latest",
            max_tokens=100,
            temperature=0.7
        )

        # Verify metadata structure
        assert "fallback_triggered" in metadata
        assert "fallback_enabled" in metadata
        assert "primary_model" in metadata
        assert "fallback_model" in metadata
        assert "fallback_reason" in metadata
        assert "attempts" in metadata
        assert "provider_used" in metadata

        # Verify attempts tracking
        attempts = metadata["attempts"]
        assert len(attempts) == 2
        assert attempts[0]["provider"] == "Claude"
        assert attempts[0]["success"] is False
        assert attempts[0]["error"] == "overloaded"
        assert attempts[1]["provider"] == "OpenAI"
        assert attempts[1]["success"] is True


class TestFallbackEdgeCases:
    """Test edge cases and error scenarios."""

    @pytest.mark.asyncio
    async def test_no_fallback_client_available(self, mock_settings, mock_claude_client):
        """Test that error is raised when fallback client is not available."""
        # Setup Claude to fail
        claude_error = Exception("Error code: 529")
        mock_claude_client.create_message = AsyncMock(side_effect=claude_error)

        # Create cascade with no fallback client
        cascade = ProviderCascade(
            primary_client=mock_claude_client,
            primary_provider_name="Claude",
            fallback_client=None,
            fallback_provider_name="None",
            settings=mock_settings
        )

        # Execute and expect error
        with pytest.raises(Exception):
            await cascade.execute_with_fallback(
                operation="create_message",
                primary_model="claude-3-5-haiku-latest",
                prompt="Test",
                model="claude-3-5-haiku-latest",
                max_tokens=100,
                temperature=0.7
            )

    @pytest.mark.asyncio
    async def test_both_providers_fail(self, mock_settings, mock_claude_client, mock_openai_client):
        """Test that error is raised when both providers fail."""
        # Setup both to fail
        claude_error = Exception("Error code: 529")
        openai_error = Exception("OpenAI also failed")

        mock_claude_client.create_message = AsyncMock(side_effect=claude_error)
        mock_openai_client.create_message = AsyncMock(side_effect=openai_error)

        # Create cascade
        cascade = ProviderCascade(
            primary_client=mock_claude_client,
            primary_provider_name="Claude",
            fallback_client=mock_openai_client,
            fallback_provider_name="OpenAI",
            settings=mock_settings
        )

        # Execute and expect error
        with pytest.raises(Exception):
            await cascade.execute_with_fallback(
                operation="create_message",
                primary_model="claude-3-5-haiku-latest",
                prompt="Test",
                model="claude-3-5-haiku-latest",
                max_tokens=100,
                temperature=0.7
            )

    @pytest.mark.asyncio
    async def test_conversation_operation(self, mock_settings, mock_claude_client, mock_openai_client):
        """Test that fallback works for create_conversation operation."""
        # Setup Claude failure
        claude_error = Exception("Error code: 529")
        mock_claude_client.create_conversation = AsyncMock(side_effect=claude_error)

        # Setup OpenAI success
        openai_response = Mock()
        openai_response.content = [Mock(text="Conversation response")]
        openai_response.usage = Mock(prompt_tokens=100, completion_tokens=200)
        mock_openai_client.create_conversation = AsyncMock(return_value=openai_response)

        # Create cascade
        cascade = ProviderCascade(
            primary_client=mock_claude_client,
            primary_provider_name="Claude",
            fallback_client=mock_openai_client,
            fallback_provider_name="OpenAI",
            settings=mock_settings
        )

        # Execute with conversation operation
        response, metadata = await cascade.execute_with_fallback(
            operation="create_conversation",
            primary_model="claude-3-5-haiku-latest",
            messages=[{"role": "user", "content": "Hello"}],
            model="claude-3-5-haiku-latest",
            max_tokens=100,
            temperature=0.7
        )

        # Assertions
        assert response == openai_response
        assert metadata["fallback_triggered"] is True
        mock_openai_client.create_conversation.assert_called_once()
