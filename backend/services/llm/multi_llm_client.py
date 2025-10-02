"""
Multi-Provider LLM Client Service supporting Claude and OpenAI.
Provides dynamic provider switching based on organization configuration.
"""

import logging
from typing import Optional, Dict, Any, List, Union
from abc import ABC, abstractmethod
import httpx
from anthropic import AsyncAnthropic
from openai import AsyncOpenAI
from sqlalchemy.ext.asyncio import AsyncSession

try:
    from langfuse.decorators import observe, langfuse_context
    LANGFUSE_AVAILABLE = True
except ImportError:
    LANGFUSE_AVAILABLE = False
    def observe(name=None):
        def decorator(func):
            return func
        return decorator

    class DummyLangfuseContext:
        def update_current_observation(self, **kwargs):
            pass

    langfuse_context = DummyLangfuseContext()

from config import Settings
from models.integration import AIProvider, AIModel, MODEL_PROVIDER_MAP, Integration, IntegrationType, IntegrationStatus
from models.organization import Organization

logger = logging.getLogger(__name__)


class BaseProviderClient(ABC):
    """Base class for LLM provider clients."""

    @abstractmethod
    async def create_message(
        self,
        prompt: str,
        *,
        model: str,
        max_tokens: int,
        temperature: float,
        system: Optional[str] = None,
        **kwargs
    ) -> Optional[Any]:
        """Create a message using the provider's API."""
        pass

    @abstractmethod
    async def create_conversation(
        self,
        messages: List[Dict[str, str]],
        *,
        model: str,
        max_tokens: int,
        temperature: float,
        **kwargs
    ) -> Optional[Any]:
        """Create a conversation with message history."""
        pass

    @abstractmethod
    def is_available(self) -> bool:
        """Check if the provider client is available."""
        pass


class ClaudeProviderClient(BaseProviderClient):
    """Claude (Anthropic) provider client."""

    def __init__(self, api_key: str, settings: Settings):
        self.api_key = api_key
        self.settings = settings
        self.client = self._initialize_client()

    def _initialize_client(self) -> Optional[AsyncAnthropic]:
        """Initialize the Anthropic client."""
        if not self.api_key:
            return None

        try:
            if self.settings.api_env == "development":
                http_client = httpx.AsyncClient(verify=False)
                client = AsyncAnthropic(
                    api_key=self.api_key,
                    http_client=http_client
                )
            else:
                client = AsyncAnthropic(api_key=self.api_key)
            return client
        except Exception as e:
            logger.error(f"Failed to initialize Claude client: {str(e)}")
            return None

    def is_available(self) -> bool:
        return self.client is not None

    async def create_message(
        self,
        prompt: str,
        *,
        model: str,
        max_tokens: int,
        temperature: float,
        system: Optional[str] = None,
        **kwargs
    ) -> Optional[Any]:
        """Create a message using Claude API."""
        if not self.client:
            return None

        messages = [{"role": "user", "content": prompt}]
        api_params = {
            "model": model,
            "max_tokens": max_tokens,
            "temperature": temperature,
            "messages": messages,
        }

        if system:
            api_params["system"] = system

        api_params.update(kwargs)

        response = await self.client.messages.create(**api_params)

        if LANGFUSE_AVAILABLE and hasattr(response, 'usage'):
            langfuse_context.update_current_observation(
                usage={
                    "input": response.usage.input_tokens,
                    "output": response.usage.output_tokens,
                    "unit": "TOKENS"
                }
            )

        return response

    async def create_conversation(
        self,
        messages: List[Dict[str, str]],
        *,
        model: str,
        max_tokens: int,
        temperature: float,
        **kwargs
    ) -> Optional[Any]:
        """Create a conversation with Claude."""
        if not self.client:
            return None

        api_params = {
            "model": model,
            "max_tokens": max_tokens,
            "temperature": temperature,
            "messages": messages,
            **kwargs
        }

        response = await self.client.messages.create(**api_params)

        if LANGFUSE_AVAILABLE and hasattr(response, 'usage'):
            langfuse_context.update_current_observation(
                usage={
                    "input": response.usage.input_tokens,
                    "output": response.usage.output_tokens,
                    "unit": "TOKENS"
                }
            )

        return response


class OpenAIProviderClient(BaseProviderClient):
    """OpenAI provider client."""

    def __init__(self, api_key: str, settings: Settings):
        self.api_key = api_key
        self.settings = settings
        self.client = self._initialize_client()

    def _initialize_client(self) -> Optional[AsyncOpenAI]:
        """Initialize the OpenAI client."""
        if not self.api_key:
            return None

        try:
            if self.settings.api_env == "development":
                http_client = httpx.AsyncClient(verify=False)
                client = AsyncOpenAI(
                    api_key=self.api_key,
                    http_client=http_client
                )
            else:
                client = AsyncOpenAI(api_key=self.api_key)
            return client
        except Exception as e:
            logger.error(f"Failed to initialize OpenAI client: {str(e)}")
            return None

    def is_available(self) -> bool:
        return self.client is not None

    async def create_message(
        self,
        prompt: str,
        *,
        model: str,
        max_tokens: int,
        temperature: float,
        system: Optional[str] = None,
        **kwargs
    ) -> Optional[Any]:
        """Create a message using OpenAI API."""
        if not self.client:
            return None

        messages = []
        if system:
            messages.append({"role": "system", "content": system})
        messages.append({"role": "user", "content": prompt})

        response = await self.client.chat.completions.create(
            model=model,
            messages=messages,
            max_tokens=max_tokens,
            temperature=temperature,
            **kwargs
        )

        if LANGFUSE_AVAILABLE and hasattr(response, 'usage'):
            langfuse_context.update_current_observation(
                usage={
                    "input": response.usage.prompt_tokens,
                    "output": response.usage.completion_tokens,
                    "unit": "TOKENS"
                }
            )

        # Wrap OpenAI response to match Claude-like interface
        return self._wrap_openai_response(response)

    async def create_conversation(
        self,
        messages: List[Dict[str, str]],
        *,
        model: str,
        max_tokens: int,
        temperature: float,
        **kwargs
    ) -> Optional[Any]:
        """Create a conversation with OpenAI."""
        if not self.client:
            return None

        response = await self.client.chat.completions.create(
            model=model,
            messages=messages,
            max_tokens=max_tokens,
            temperature=temperature,
            **kwargs
        )

        if LANGFUSE_AVAILABLE and hasattr(response, 'usage'):
            langfuse_context.update_current_observation(
                usage={
                    "input": response.usage.prompt_tokens,
                    "output": response.usage.completion_tokens,
                    "unit": "TOKENS"
                }
            )

        return self._wrap_openai_response(response)

    def _wrap_openai_response(self, response):
        """Wrap OpenAI response to match Claude-like interface."""
        # Create a Claude-like response structure
        class WrappedContent:
            def __init__(self, text):
                self.text = text

        class WrappedResponse:
            def __init__(self, openai_response):
                self.content = [WrappedContent(openai_response.choices[0].message.content)]
                self.usage = openai_response.usage
                self._raw = openai_response

        return WrappedResponse(response)


class MultiProviderLLMClient:
    """
    Multi-provider LLM client that dynamically switches between Claude and OpenAI.
    """

    _instance: Optional['MultiProviderLLMClient'] = None

    def __init__(self, settings: Optional[Settings] = None):
        """Initialize the multi-provider LLM client."""
        if settings is None:
            from config import get_settings
            settings = get_settings()

        self.settings = settings
        self.providers: Dict[AIProvider, BaseProviderClient] = {}
        self.default_org_id = "00000000-0000-0000-0000-000000000001"  # Default organization for MVP

        # Store fallback configuration from environment
        self.fallback_provider = None
        self.fallback_model = settings.llm_model
        self.fallback_max_tokens = settings.max_tokens
        self.fallback_temperature = settings.temperature

        # Initialize fallback provider from environment if available
        if settings.anthropic_api_key:
            self._initialize_fallback_provider()

        logger.info("Multi-provider LLM Client initialized")

    def _initialize_fallback_provider(self):
        """Initialize fallback provider from environment variables."""
        if self.settings.anthropic_api_key:
            self.fallback_provider = ClaudeProviderClient(
                self.settings.anthropic_api_key,
                self.settings
            )
            logger.info("Fallback Claude provider initialized from environment")

    @classmethod
    def get_instance(cls, settings: Optional[Settings] = None) -> 'MultiProviderLLMClient':
        """Get singleton instance of multi-provider LLM client."""
        if cls._instance is None:
            cls._instance = cls(settings)
        return cls._instance

    @classmethod
    def reset_instance(cls):
        """Reset the singleton instance (useful for testing)."""
        cls._instance = None

    def is_available(self) -> bool:
        """
        Check if any LLM provider is available.
        For backward compatibility with existing services.
        """
        return self.fallback_provider is not None and self.fallback_provider.is_available()

    def get_model_info(self) -> Dict[str, Any]:
        """
        Get information about the current model configuration.
        For backward compatibility with existing services.
        """
        return {
            "model": self.fallback_model,
            "max_tokens": self.fallback_max_tokens,
            "temperature": self.fallback_temperature,
            "available": self.is_available()
        }

    async def get_active_provider(
        self,
        session: Optional[AsyncSession],
        organization_id: Optional[str] = None
    ) -> tuple[Optional[BaseProviderClient], Optional[Dict[str, Any]]]:
        """
        Get the active provider for an organization.
        Returns (provider_client, configuration_dict).
        Checks Integration table for AI_BRAIN integration, falls back to environment if not configured.
        """
        org_id = organization_id or self.default_org_id

        # Try to get AI Brain integration from database
        if session:
            try:
                from sqlalchemy import select, and_

                query = select(Integration).where(
                    and_(
                        Integration.organization_id == org_id,
                        Integration.type == IntegrationType.AI_BRAIN,
                        Integration.status == IntegrationStatus.CONNECTED
                    )
                )

                result = await session.execute(query)
                integration = result.scalar_one_or_none()

                if integration and integration.api_key:
                    # Get configuration from integration custom_settings
                    custom_settings = integration.custom_settings or {}
                    provider_str = custom_settings.get("provider", "claude")
                    model_str = custom_settings.get("model", self.fallback_model)

                    try:
                        provider_enum = AIProvider(provider_str)
                    except ValueError:
                        logger.warning(f"Invalid provider in integration: {provider_str}, falling back to environment")
                        provider_enum = None

                    if provider_enum:
                        # Decrypt API key
                        from services.integrations.integration_service import integration_service
                        api_key = integration_service._decrypt_value(integration.api_key)

                        # Check if provider is already cached
                        if provider_enum in self.providers:
                            provider_client = self.providers[provider_enum]
                        else:
                            # Initialize new provider
                            provider_client = self._create_provider_client(provider_enum, api_key)
                            if provider_client:
                                self.providers[provider_enum] = provider_client
                                logger.info(f"Initialized {provider_enum.value} provider from integration for organization {org_id}")

                        if provider_client:
                            config_dict = {
                                "model": model_str,
                                "max_tokens": custom_settings.get("max_tokens", self.fallback_max_tokens),
                                "temperature": custom_settings.get("temperature", self.fallback_temperature),
                                "provider": provider_str,
                            }
                            logger.debug(f"Using AI Brain integration: {provider_str} / {model_str}")
                            return provider_client, config_dict

            except Exception as e:
                logger.warning(f"Failed to load AI Brain integration, falling back to environment: {e}")

        # Fall back to environment variables
        if self.fallback_provider:
            logger.debug("Using fallback provider from environment")
            config_dict = {
                "model": self.fallback_model,
                "max_tokens": self.fallback_max_tokens,
                "temperature": self.fallback_temperature,
                "provider": "claude (env)",
            }
            return self.fallback_provider, config_dict

        logger.warning("No AI provider configured in integrations or environment")
        return None, None

    def _create_provider_client(
        self,
        provider: AIProvider,
        api_key: str
    ) -> Optional[BaseProviderClient]:
        """Create a provider client based on the provider type."""
        if provider == AIProvider.CLAUDE:
            return ClaudeProviderClient(api_key, self.settings)
        elif provider == AIProvider.OPENAI:
            return OpenAIProviderClient(api_key, self.settings)
        else:
            logger.error(f"Unknown provider: {provider}")
            return None

    @observe(name="multi_llm_create_message")
    async def create_message(
        self,
        prompt: str,
        *,
        session: Optional[AsyncSession] = None,
        organization_id: Optional[str] = None,
        model: Optional[str] = None,
        max_tokens: Optional[int] = None,
        temperature: Optional[float] = None,
        system: Optional[str] = None,
        **kwargs
    ) -> Optional[Any]:
        """
        Create a message using the active provider for the organization.
        If no session is provided, uses the fallback provider.
        Includes retry logic with exponential backoff for 529 errors.
        """
        if session:
            provider_client, ai_config = await self.get_active_provider(session, organization_id)
        else:
            # Use fallback provider when no session is available
            provider_client = self.fallback_provider
            ai_config = None

        if not provider_client:
            logger.warning("No LLM provider available")
            return None

        # Use configuration dict or fallback values
        if ai_config:
            model = model or ai_config.get("model", self.fallback_model)
            max_tokens = max_tokens or ai_config.get("max_tokens", self.fallback_max_tokens)
            temperature = temperature or ai_config.get("temperature", self.fallback_temperature)
        else:
            # Using fallback provider
            model = model or self.fallback_model
            max_tokens = max_tokens or self.fallback_max_tokens
            temperature = temperature or self.fallback_temperature

        # Import here to avoid circular dependency
        from utils.retry import RetryConfig, retry_with_backoff
        from utils.exceptions import (
            LLMOverloadedException,
            LLMRateLimitException,
            LLMTimeoutException,
            LLMAuthenticationException
        )
        import asyncio

        async def call_provider():
            try:
                logger.debug(f"Creating message with model: {model}, provider: {provider_client.__class__.__name__}")

                response = await provider_client.create_message(
                    prompt,
                    model=model,
                    max_tokens=max_tokens,
                    temperature=temperature,
                    system=system,
                    **kwargs
                )

                # Note: Usage statistics tracking removed (AIConfiguration table dropped)

                return response

            except Exception as e:
                error_str = str(e)
                # Check for specific error codes (handles both Claude and OpenAI)
                if "529" in error_str or "overloaded" in error_str.lower() or "503" in error_str:
                    # 529 is Claude overloaded, 503 is OpenAI service unavailable
                    logger.warning(f"LLM API overloaded: {error_str}")
                    raise LLMOverloadedException()
                elif "429" in error_str or "rate_limit" in error_str.lower():
                    # 429 is rate limit for both providers
                    logger.warning(f"Rate limit exceeded: {error_str}")
                    raise LLMRateLimitException()
                elif "timeout" in error_str.lower() or "504" in error_str:
                    # Timeout errors
                    logger.warning(f"Request timeout: {error_str}")
                    raise LLMTimeoutException()
                elif "401" in error_str or "unauthorized" in error_str.lower():
                    # Authentication errors
                    logger.error(f"Authentication failed: {error_str}")
                    raise LLMAuthenticationException()
                else:
                    logger.error(f"Error calling LLM API: {error_str}")
                    raise

        # Configure retry with exponential backoff for overloaded errors
        retry_config = RetryConfig(
            max_attempts=5,  # Increased from 3 to 5 for 529 errors
            initial_delay=2.0,  # Start with 2 second delay
            max_delay=30.0,  # Cap at 30 seconds
            exponential_base=2.0,
            jitter=True,
            retryable_exceptions=(
                LLMOverloadedException,
                LLMRateLimitException,
                LLMTimeoutException,
            )
        )

        try:
            return await retry_with_backoff(
                call_provider,
                config=retry_config
            )
        except (LLMOverloadedException, LLMRateLimitException, LLMTimeoutException) as e:
            # These exceptions have user-friendly messages
            raise
        except Exception as e:
            logger.error(f"Failed after retries: {str(e)}")
            raise

    async def create_conversation(
        self,
        session: AsyncSession,
        messages: List[Dict[str, str]],
        *,
        organization_id: Optional[str] = None,
        model: Optional[str] = None,
        max_tokens: Optional[int] = None,
        temperature: Optional[float] = None,
        **kwargs
    ) -> Optional[Any]:
        """
        Create a conversation using the active provider.
        Includes retry logic with exponential backoff for transient errors.
        """
        provider_client, ai_config = await self.get_active_provider(session, organization_id)

        if not provider_client:
            logger.warning("No LLM provider available")
            return None

        # Use configuration dict or fallback values
        if ai_config:
            model = model or ai_config.get("model", self.fallback_model)
            max_tokens = max_tokens or ai_config.get("max_tokens", self.fallback_max_tokens)
            temperature = temperature or ai_config.get("temperature", self.fallback_temperature)
        else:
            model = model or self.fallback_model
            max_tokens = max_tokens or self.fallback_max_tokens
            temperature = temperature or self.fallback_temperature

        # Import here to avoid circular dependency
        from utils.retry import RetryConfig, retry_with_backoff
        from utils.exceptions import (
            LLMOverloadedException,
            LLMRateLimitException,
            LLMTimeoutException,
            LLMAuthenticationException
        )

        async def call_provider():
            try:
                logger.debug(f"Creating conversation with model: {model}, provider: {provider_client.__class__.__name__}")

                response = await provider_client.create_conversation(
                    messages,
                    model=model,
                    max_tokens=max_tokens,
                    temperature=temperature,
                    **kwargs
                )

                # Note: Usage statistics tracking removed (AIConfiguration table dropped)

                return response

            except Exception as e:
                error_str = str(e)
                # Check for specific error codes (handles both Claude and OpenAI)
                if "529" in error_str or "overloaded" in error_str.lower() or "503" in error_str:
                    # 529 is Claude overloaded, 503 is OpenAI service unavailable
                    logger.warning(f"LLM API overloaded: {error_str}")
                    raise LLMOverloadedException()
                elif "429" in error_str or "rate_limit" in error_str.lower():
                    # 429 is rate limit for both providers
                    logger.warning(f"Rate limit exceeded: {error_str}")
                    raise LLMRateLimitException()
                elif "timeout" in error_str.lower() or "504" in error_str:
                    # Timeout errors
                    logger.warning(f"Request timeout: {error_str}")
                    raise LLMTimeoutException()
                elif "401" in error_str or "unauthorized" in error_str.lower():
                    # Authentication errors
                    logger.error(f"Authentication failed: {error_str}")
                    raise LLMAuthenticationException()
                else:
                    logger.error(f"Error in conversation API call: {error_str}")
                    raise

        # Configure retry with exponential backoff for overloaded errors
        retry_config = RetryConfig(
            max_attempts=5,  # Same as create_message
            initial_delay=2.0,
            max_delay=30.0,
            exponential_base=2.0,
            jitter=True,
            retryable_exceptions=(
                LLMOverloadedException,
                LLMRateLimitException,
                LLMTimeoutException,
            )
        )

        try:
            return await retry_with_backoff(
                call_provider,
                config=retry_config
            )
        except (LLMOverloadedException, LLMRateLimitException, LLMTimeoutException) as e:
            # These exceptions have user-friendly messages
            raise
        except Exception as e:
            logger.error(f"Failed after retries: {str(e)}")
            raise

    # Note: _update_usage_stats removed (AIConfiguration table dropped)

    async def test_configuration(
        self,
        provider: AIProvider,
        api_key: str,
        model: str
    ) -> Dict[str, Any]:
        """
        Test an AI configuration to verify it works.
        """
        try:
            # Create a temporary provider client
            provider_client = self._create_provider_client(provider, api_key)

            if not provider_client or not provider_client.is_available():
                return {
                    "success": False,
                    "error": "Failed to initialize provider client"
                }

            # Make a minimal test call
            response = await provider_client.create_message(
                prompt="Say 'test successful' and nothing else.",
                model=model,
                max_tokens=20,
                temperature=0
            )

            if response:
                return {
                    "success": True,
                    "message": "Configuration test successful"
                }
            else:
                return {
                    "success": False,
                    "error": "No response from API"
                }

        except Exception as e:
            return {
                "success": False,
                "error": str(e)
            }

    def get_available_models(self, provider: AIProvider) -> List[str]:
        """Get list of available models for a provider."""
        return [
            model.value for model, prov in MODEL_PROVIDER_MAP.items()
            if prov == provider
        ]

    async def health_check(self, session: Optional[AsyncSession] = None, organization_id: Optional[str] = None) -> Dict[str, Any]:
        """
        Perform a health check on the active provider.
        """
        provider_client, ai_config = await self.get_active_provider(session, organization_id)

        if not provider_client:
            return {
                "status": "unavailable",
                "reason": "No provider configured"
            }

        try:
            # Get model from config or use fallback
            model = ai_config.get("model", self.fallback_model) if ai_config else self.fallback_model
            provider = ai_config.get("provider", "unknown") if ai_config else "claude (env)"

            # Test provider
            response = await provider_client.create_message(
                prompt="Hello",
                model=model,
                max_tokens=10,
                temperature=0
            )
            test_result = {"success": bool(response)}

            if test_result.get("success"):
                return {
                    "status": "healthy",
                    "provider": provider,
                    "model": model,
                    "source": "integration" if ai_config and ai_config.get("provider") != "claude (env)" else "environment"
                }
            else:
                return {
                    "status": "error",
                    "reason": test_result.get("error", "Unknown error")
                }

        except Exception as e:
            return {
                "status": "error",
                "reason": str(e)
            }


# Global function to get the multi-provider LLM client instance
def get_multi_llm_client(settings: Optional[Settings] = None) -> MultiProviderLLMClient:
    """
    Get the singleton multi-provider LLM client instance.
    """
    return MultiProviderLLMClient.get_instance(settings)