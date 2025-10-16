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
    from purgatory import AsyncCircuitBreakerFactory
    from purgatory.domain.model import OpenedState
    PURGATORY_AVAILABLE = True
except ImportError as e:
    PURGATORY_AVAILABLE = False
    OpenedState = Exception  # Fallback for type hints
    # Log import failure at module load time
    import logging
    _logger = logging.getLogger(__name__)
    _logger.warning(
        f"⚠️  Circuit breaker library 'purgatory' not available: {e}. "
        "Circuit breaker functionality will be disabled. "
        "Install with: pip install purgatory==3.0.1"
    )

from config import Settings
from models.integration import AIProvider, AIModel, MODEL_PROVIDER_MAP, Integration, IntegrationType, IntegrationStatus, get_equivalent_model
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


class ProviderCascade:
    """
    Manages cascading fallback between primary and fallback LLM providers.

    This class implements an elegant fallback strategy:
    - Primary provider is tried first with limited retries
    - On overload errors (529, 503), automatically fallback to secondary provider
    - On rate limit errors (429), retry primary with exponential backoff
    - Tracks metadata about provider usage and fallback events
    """

    def __init__(
        self,
        primary_client: Optional[BaseProviderClient],
        primary_provider_name: str,
        fallback_client: Optional[BaseProviderClient],
        fallback_provider_name: str,
        settings: Settings
    ):
        """
        Initialize the provider cascade.

        Args:
            primary_client: Primary provider client instance
            primary_provider_name: Name of primary provider (for logging)
            fallback_client: Fallback provider client instance
            fallback_provider_name: Name of fallback provider (for logging)
            settings: Application settings
        """
        self.primary_client = primary_client
        self.primary_provider_name = primary_provider_name
        self.fallback_client = fallback_client
        self.fallback_provider_name = fallback_provider_name
        self.settings = settings

        # Initialize circuit breaker factory for primary provider
        self.circuit_breaker_factory = None
        self.circuit_breaker_name = f"{primary_provider_name}_api"
        if settings.enable_circuit_breaker:
            if PURGATORY_AVAILABLE:
                try:
                    self.circuit_breaker_factory = AsyncCircuitBreakerFactory(
                        default_threshold=settings.circuit_breaker_failure_threshold,
                        default_ttl=settings.circuit_breaker_timeout_seconds
                    )
                    logger.info(
                        f"Circuit breaker enabled for {primary_provider_name} "
                        f"(threshold: {settings.circuit_breaker_failure_threshold}, "
                        f"timeout: {settings.circuit_breaker_timeout_seconds}s)"
                    )
                except Exception as e:
                    logger.warning(f"Failed to initialize circuit breaker: {e}")
                    self.circuit_breaker_factory = None
            else:
                logger.warning(
                    f"⚠️  Circuit breaker requested for {primary_provider_name} but purgatory library is not available. "
                    "Circuit breaker functionality will be disabled. Install with: pip install purgatory==3.0.1"
                )

    def _translate_model_for_fallback(self, source_model: str) -> Optional[str]:
        """
        Translate a model to its equivalent in the fallback provider.

        Args:
            source_model: The source model string

        Returns:
            Equivalent model string, or None if translation fails
        """
        # Determine target provider based on fallback client
        if isinstance(self.fallback_client, OpenAIProviderClient):
            target_provider = AIProvider.OPENAI
        elif isinstance(self.fallback_client, ClaudeProviderClient):
            target_provider = AIProvider.CLAUDE
        else:
            logger.warning(f"Unknown fallback client type: {type(self.fallback_client)}")
            return None

        # Use the model equivalence mapping
        equivalent_model = get_equivalent_model(source_model, target_provider)

        if equivalent_model:
            logger.info(
                f"Model translation: {source_model} → {equivalent_model} "
                f"(for {target_provider.value} provider)"
            )
        else:
            logger.warning(
                f"No model equivalence found for {source_model} → {target_provider.value}"
            )

        return equivalent_model

    async def _execute_fallback(
        self,
        operation: str,
        primary_model: str,
        fallback_reason: str,
        metadata: Dict[str, Any],
        **kwargs
    ) -> tuple[Optional[Any], Dict[str, Any]]:
        """
        Execute fallback to secondary provider.

        Args:
            operation: Operation type ("create_message" or "create_conversation")
            primary_model: Primary model that failed
            fallback_reason: Reason for fallback (e.g., "overloaded", "rate_limit")
            metadata: Metadata dictionary to update
            **kwargs: Arguments to pass to the provider method

        Returns:
            Tuple of (response, metadata_dict)
        """
        from utils.exceptions import (
            LLMRateLimitException,
            LLMTimeoutException,
            LLMOverloadedException,
        )
        from utils.retry import RetryConfig, retry_with_backoff

        logger.info(
            f"🔄 Fallback triggered: {self.primary_provider_name} → {self.fallback_provider_name} "
            f"(reason: {fallback_reason})"
        )
        metadata["fallback_triggered"] = True
        metadata["fallback_reason"] = fallback_reason

        # Translate model to equivalent
        fallback_model = self._translate_model_for_fallback(primary_model)
        if not fallback_model:
            logger.error(
                f"Cannot fallback: no model equivalence for {primary_model}"
            )
            raise Exception(f"No model equivalence found for {primary_model}")

        metadata["fallback_model"] = fallback_model
        metadata["provider_used"] = self.fallback_provider_name

        # Update kwargs with translated model
        kwargs["model"] = fallback_model

        # Configure retry for fallback provider
        retry_config = RetryConfig(
            max_attempts=self.settings.fallback_provider_max_retries,
            initial_delay=2.0,
            max_delay=30.0,
            exponential_base=2.0,
            jitter=True,
            retryable_exceptions=(
                LLMRateLimitException,
                LLMTimeoutException,
                LLMOverloadedException,
            )
        )

        async def call_fallback():
            """Call fallback provider with error handling."""
            try:
                if operation == "create_message":
                    response = await self.fallback_client.create_message(**kwargs)
                elif operation == "create_conversation":
                    response = await self.fallback_client.create_conversation(**kwargs)
                else:
                    raise ValueError(f"Unknown operation: {operation}")

                metadata["attempts"].append({
                    "provider": self.fallback_provider_name,
                    "model": fallback_model,
                    "success": True
                })
                logger.info(
                    f"✅ Fallback successful: {self.fallback_provider_name} / {fallback_model}"
                )
                return response

            except Exception as e:
                error_str = str(e)
                metadata["attempts"].append({
                    "provider": self.fallback_provider_name,
                    "model": fallback_model,
                    "success": False,
                    "error": error_str
                })
                logger.error(
                    f"❌ Fallback failed on {self.fallback_provider_name}: {error_str}"
                )
                raise

        # Try fallback provider with retries
        response = await retry_with_backoff(call_fallback, config=retry_config)
        return response, metadata

    async def execute_with_fallback(
        self,
        operation: str,
        primary_model: str,
        **kwargs
    ) -> tuple[Optional[Any], Dict[str, Any]]:
        """
        Execute an LLM operation with automatic provider fallback.

        Strategy:
        1. Try primary provider with limited retries (for rate limits only)
        2. On overload (529/503), immediately fallback to secondary provider
        3. On rate limit (429), retry primary with exponential backoff
        4. Track all attempts and metadata

        Args:
            operation: Operation type ("create_message" or "create_conversation")
            primary_model: Primary model to use
            **kwargs: Arguments to pass to the provider method

        Returns:
            Tuple of (response, metadata_dict)
            metadata includes: provider_used, fallback_triggered, attempts, fallback_model
        """
        # Import exceptions here to avoid circular dependency
        from utils.exceptions import (
            LLMOverloadedException,
            LLMRateLimitException,
            LLMTimeoutException,
            LLMAuthenticationException
        )
        from utils.retry import RetryConfig, retry_with_backoff

        metadata = {
            "provider_used": self.primary_provider_name,
            "fallback_triggered": False,
            "fallback_enabled": self.settings.enable_llm_fallback,
            "primary_model": primary_model,
            "attempts": []
        }

        # Check if fallback is available
        fallback_available = (
            self.settings.enable_llm_fallback and
            self.fallback_client is not None and
            self.fallback_client.is_available()
        )

        # Phase 1: Try primary provider
        try:
            logger.debug(
                f"Attempting {operation} with primary provider: "
                f"{self.primary_provider_name} / {primary_model}"
            )

            # Configure retry for primary provider (only for rate limits and timeouts)
            retry_config = RetryConfig(
                max_attempts=self.settings.primary_provider_max_retries,
                initial_delay=2.0,
                max_delay=30.0,
                exponential_base=2.0,
                jitter=True,
                retryable_exceptions=(
                    LLMRateLimitException,
                    LLMTimeoutException,
                )
            )

            async def call_primary():
                """Call primary provider with error handling."""
                try:
                    if operation == "create_message":
                        response = await self.primary_client.create_message(**kwargs)
                    elif operation == "create_conversation":
                        response = await self.primary_client.create_conversation(**kwargs)
                    else:
                        raise ValueError(f"Unknown operation: {operation}")

                    metadata["attempts"].append({
                        "provider": self.primary_provider_name,
                        "model": primary_model,
                        "success": True
                    })
                    return response

                except Exception as e:
                    error_str = str(e)

                    # Classify the error
                    if "529" in error_str or "overloaded" in error_str.lower() or "503" in error_str:
                        metadata["attempts"].append({
                            "provider": self.primary_provider_name,
                            "model": primary_model,
                            "success": False,
                            "error": "overloaded"
                        })
                        logger.warning(
                            f"{self.primary_provider_name} overloaded (529/503): {error_str}"
                        )
                        raise LLMOverloadedException()

                    elif "429" in error_str or "rate_limit" in error_str.lower():
                        metadata["attempts"].append({
                            "provider": self.primary_provider_name,
                            "model": primary_model,
                            "success": False,
                            "error": "rate_limit"
                        })
                        logger.warning(f"Rate limit on {self.primary_provider_name}: {error_str}")
                        raise LLMRateLimitException()

                    elif "timeout" in error_str.lower() or "504" in error_str:
                        metadata["attempts"].append({
                            "provider": self.primary_provider_name,
                            "model": primary_model,
                            "success": False,
                            "error": "timeout"
                        })
                        logger.warning(f"Timeout on {self.primary_provider_name}: {error_str}")
                        raise LLMTimeoutException()

                    elif "401" in error_str or "unauthorized" in error_str.lower():
                        metadata["attempts"].append({
                            "provider": self.primary_provider_name,
                            "model": primary_model,
                            "success": False,
                            "error": "authentication"
                        })
                        logger.error(f"Authentication failed on {self.primary_provider_name}: {error_str}")
                        raise LLMAuthenticationException()

                    else:
                        metadata["attempts"].append({
                            "provider": self.primary_provider_name,
                            "model": primary_model,
                            "success": False,
                            "error": "unknown"
                        })
                        logger.error(f"Unknown error on {self.primary_provider_name}: {error_str}")
                        raise

            # Try primary provider with retries (wrapped with circuit breaker if enabled)
            if self.circuit_breaker_factory:
                try:
                    async with await self.circuit_breaker_factory.get_breaker(self.circuit_breaker_name):
                        response = await retry_with_backoff(call_primary, config=retry_config)
                    return response, metadata
                except OpenedState:
                    # Circuit is open - immediately trigger fallback
                    logger.warning(
                        f"🚫 Circuit breaker open for {self.primary_provider_name} - "
                        f"skipping primary and using fallback immediately"
                    )
                    metadata["attempts"].append({
                        "provider": self.primary_provider_name,
                        "model": primary_model,
                        "success": False,
                        "error": "circuit_breaker_open"
                    })
                    raise LLMOverloadedException()
            else:
                response = await retry_with_backoff(call_primary, config=retry_config)
                return response, metadata

        except LLMOverloadedException as e:
            # Primary provider is overloaded - try fallback if available
            if not fallback_available:
                logger.error(
                    f"{self.primary_provider_name} overloaded and no fallback available"
                )
                raise

            if not self.settings.fallback_on_overload:
                logger.warning(
                    f"{self.primary_provider_name} overloaded but fallback disabled "
                    f"by configuration (FALLBACK_ON_OVERLOAD=false)"
                )
                raise

            # Phase 2: Fallback to secondary provider
            return await self._execute_fallback(
                operation=operation,
                primary_model=primary_model,
                fallback_reason="overloaded",
                metadata=metadata,
                **kwargs
            )

        except LLMRateLimitException as e:
            # Rate limit on primary - optionally fallback
            if fallback_available and self.settings.fallback_on_rate_limit:
                return await self._execute_fallback(
                    operation=operation,
                    primary_model=primary_model,
                    fallback_reason="rate_limit",
                    metadata=metadata,
                    **kwargs
                )

            # No fallback for rate limit - re-raise
            raise

        except Exception as e:
            # Other errors - re-raise without fallback
            logger.error(f"Non-retryable error: {str(e)}")
            raise


class MultiProviderLLMClient:
    """
    Multi-provider LLM client that dynamically switches between Claude and OpenAI.
    """

    _instance: Optional['MultiProviderLLMClient'] = None

    def __init__(self, settings: Optional[Settings] = None):
        """Initialize the multi-provider LLM client with primary and fallback providers."""
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

        # Initialize primary and fallback providers from environment
        self.primary_provider_client = None
        self.primary_provider_name = None
        self.secondary_provider_client = None
        self.secondary_provider_name = None

        self._initialize_providers_from_env()

        logger.info(
            f"Multi-provider LLM Client initialized - "
            f"Primary: {self.primary_provider_name or 'None'}, "
            f"Fallback: {self.secondary_provider_name or 'None'} "
            f"(fallback {'enabled' if self.settings.enable_llm_fallback else 'disabled'})"
        )

    def _initialize_providers_from_env(self):
        """
        Initialize primary and fallback providers from environment variables.

        Strategy:
        - Primary provider is determined by which API key is set (Claude by default)
        - Fallback provider is the opposite provider (if both keys are configured)
        - If FALLBACK_PROVIDER is explicitly set, use that configuration
        """
        has_claude = bool(self.settings.anthropic_api_key)
        has_openai = bool(self.settings.openai_api_key)

        # Determine primary provider based on configuration
        # By default, Claude is primary (backward compatibility)
        if has_claude:
            self.primary_provider_client = ClaudeProviderClient(
                self.settings.anthropic_api_key,
                self.settings
            )
            self.primary_provider_name = "Claude"
            logger.info("Primary provider: Claude (initialized from environment)")

            # Set Claude as fallback for backward compatibility
            self.fallback_provider = self.primary_provider_client

        # If OpenAI is also available, set it as fallback
        if has_openai and self.settings.enable_llm_fallback:
            if self.settings.fallback_provider.lower() == "openai":
                self.secondary_provider_client = OpenAIProviderClient(
                    self.settings.openai_api_key,
                    self.settings
                )
                self.secondary_provider_name = "OpenAI"
                logger.info("Fallback provider: OpenAI (initialized from environment)")
            elif not has_claude:
                # No Claude, use OpenAI as primary
                self.primary_provider_client = OpenAIProviderClient(
                    self.settings.openai_api_key,
                    self.settings
                )
                self.primary_provider_name = "OpenAI"
                self.fallback_provider = self.primary_provider_client
                logger.info("Primary provider: OpenAI (Claude not configured)")

        if not has_claude and not has_openai:
            logger.warning("No LLM provider API keys configured in environment")

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
        Create a message using the active provider with automatic fallback on overload.

        New behavior:
        - Uses ProviderCascade for intelligent fallback
        - On 529 overload, automatically switches to fallback provider (e.g., OpenAI)
        - Tracks fallback metadata for observability
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

        # Determine provider name for logging
        if isinstance(provider_client, ClaudeProviderClient):
            provider_name = "Claude"
        elif isinstance(provider_client, OpenAIProviderClient):
            provider_name = "OpenAI"
        else:
            provider_name = "Unknown"

        # Create ProviderCascade for intelligent fallback
        cascade = ProviderCascade(
            primary_client=provider_client,
            primary_provider_name=provider_name,
            fallback_client=self.secondary_provider_client,
            fallback_provider_name=self.secondary_provider_name or "None",
            settings=self.settings
        )

        # Execute with cascade fallback
        response, metadata = await cascade.execute_with_fallback(
            operation="create_message",
            primary_model=model,
            prompt=prompt,
            model=model,
            max_tokens=max_tokens,
            temperature=temperature,
            system=system,
            **kwargs
        )

        # Log fallback events for monitoring
        if metadata.get("fallback_triggered"):
            logger.warning(
                f"⚠️  Fallback used: {metadata.get('primary_model')} → {metadata.get('fallback_model')} "
                f"(reason: {metadata.get('fallback_reason')})"
            )

        return response

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
        Create a conversation using the active provider with automatic fallback on overload.

        New behavior:
        - Uses ProviderCascade for intelligent fallback
        - On 529 overload, automatically switches to fallback provider
        - Tracks fallback metadata for observability
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

        # Determine provider name for logging
        if isinstance(provider_client, ClaudeProviderClient):
            provider_name = "Claude"
        elif isinstance(provider_client, OpenAIProviderClient):
            provider_name = "OpenAI"
        else:
            provider_name = "Unknown"

        # Create ProviderCascade for intelligent fallback
        cascade = ProviderCascade(
            primary_client=provider_client,
            primary_provider_name=provider_name,
            fallback_client=self.secondary_provider_client,
            fallback_provider_name=self.secondary_provider_name or "None",
            settings=self.settings
        )

        # Execute with cascade fallback
        response, metadata = await cascade.execute_with_fallback(
            operation="create_conversation",
            primary_model=model,
            messages=messages,
            model=model,
            max_tokens=max_tokens,
            temperature=temperature,
            **kwargs
        )

        # Log fallback events for monitoring
        if metadata.get("fallback_triggered"):
            logger.warning(
                f"⚠️  Fallback used: {metadata.get('primary_model')} → {metadata.get('fallback_model')} "
                f"(reason: {metadata.get('fallback_reason')})"
            )

        return response

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