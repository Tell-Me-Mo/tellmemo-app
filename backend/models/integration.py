"""Integration model for storing external service configurations."""

import uuid
import logging
from datetime import datetime
from typing import Optional, Dict, Any
from sqlalchemy import Column, String, DateTime, Boolean, JSON, Enum as SQLEnum, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
import enum

from db.database import Base

logger = logging.getLogger(__name__)


class IntegrationType(str, enum.Enum):
    """Types of supported integrations."""
    FIREFLIES = "fireflies"
    SLACK = "slack"
    TEAMS = "teams"
    ZOOM = "zoom"
    TRANSCRIPTION = "transcription"  # For transcription service configuration
    AI_BRAIN = "ai_brain"  # For AI/LLM provider configuration


class IntegrationStatus(str, enum.Enum):
    """Status of an integration."""
    CONNECTED = "connected"
    DISCONNECTED = "disconnected"
    ERROR = "error"
    PENDING = "pending"


class AIProvider(str, enum.Enum):
    """AI/LLM providers for AI Brain integration."""
    CLAUDE = "claude"
    OPENAI = "openai"


class AIModel(str, enum.Enum):
    """AI models for different providers."""
    # Claude 4 models
    CLAUDE_OPUS_4_1 = "claude-opus-4-1-20250514"
    CLAUDE_OPUS_4 = "claude-opus-4-20250514"
    CLAUDE_SONNET_4 = "claude-sonnet-4-20250514"
    # Claude 3.5 models
    CLAUDE_3_5_SONNET = "claude-3-5-sonnet-20241022"
    CLAUDE_3_5_HAIKU = "claude-3-5-haiku-latest"
    # OpenAI models
    GPT_4O = "gpt-4o"
    GPT_4O_MINI = "gpt-4o-mini"
    GPT_4_TURBO = "gpt-4-turbo"
    GPT_35_TURBO = "gpt-3.5-turbo"


# Mapping of models to their providers
MODEL_PROVIDER_MAP = {
    # Claude models
    AIModel.CLAUDE_OPUS_4_1: AIProvider.CLAUDE,
    AIModel.CLAUDE_OPUS_4: AIProvider.CLAUDE,
    AIModel.CLAUDE_SONNET_4: AIProvider.CLAUDE,
    AIModel.CLAUDE_3_5_SONNET: AIProvider.CLAUDE,
    AIModel.CLAUDE_3_5_HAIKU: AIProvider.CLAUDE,
    # OpenAI models
    AIModel.GPT_4O: AIProvider.OPENAI,
    AIModel.GPT_4O_MINI: AIProvider.OPENAI,
    AIModel.GPT_4_TURBO: AIProvider.OPENAI,
    AIModel.GPT_35_TURBO: AIProvider.OPENAI,
}


# Model equivalence mapping for intelligent fallback
# Maps each model to its closest equivalent in the other provider
MODEL_EQUIVALENCE_MAP = {
    # Claude → OpenAI equivalents (based on capability & cost)
    AIModel.CLAUDE_3_5_HAIKU: AIModel.GPT_4O_MINI,      # Cost/speed optimized, similar pricing
    AIModel.CLAUDE_3_5_SONNET: AIModel.GPT_4O,          # Balanced performance, high capability
    AIModel.CLAUDE_SONNET_4: AIModel.GPT_4O,            # Latest Sonnet → GPT-4o
    AIModel.CLAUDE_OPUS_4: AIModel.GPT_4O,              # High capability flagship
    AIModel.CLAUDE_OPUS_4_1: AIModel.GPT_4_TURBO,       # Extended context, advanced reasoning

    # OpenAI → Claude equivalents (reverse mapping)
    AIModel.GPT_4O_MINI: AIModel.CLAUDE_3_5_HAIKU,      # Cost optimized
    AIModel.GPT_4O: AIModel.CLAUDE_3_5_SONNET,          # Balanced capability
    AIModel.GPT_4_TURBO: AIModel.CLAUDE_OPUS_4,         # High capability
    AIModel.GPT_35_TURBO: AIModel.CLAUDE_3_5_HAIKU,     # Legacy model → Haiku
}


def get_equivalent_model(source_model: str, target_provider: AIProvider) -> Optional[str]:
    """
    Get the equivalent model in the target provider.

    Args:
        source_model: The model string (e.g., "claude-3-5-haiku-latest")
        target_provider: The target provider enum

    Returns:
        Equivalent model string, or None if no mapping exists

    Example:
        >>> get_equivalent_model("claude-3-5-haiku-latest", AIProvider.OPENAI)
        "gpt-4o-mini"
    """
    # Try to find the model in AIModel enum
    source_model_enum = None
    for model_enum in AIModel:
        if model_enum.value == source_model:
            source_model_enum = model_enum
            break

    if not source_model_enum:
        # Model not found in enum, return None
        logger.warning(
            f"Model translation failed: '{source_model}' not found in AIModel enum. "
            f"Available models: {[m.value for m in AIModel]}"
        )
        return None

    # Get the equivalent model
    equivalent_model_enum = MODEL_EQUIVALENCE_MAP.get(source_model_enum)
    if not equivalent_model_enum:
        # No equivalence mapping exists
        logger.warning(
            f"Model translation failed: No equivalence mapping for {source_model_enum.value} → {target_provider.value}. "
            f"Add mapping to MODEL_EQUIVALENCE_MAP if this model should support fallback."
        )
        return None

    # Verify the equivalent model belongs to the target provider
    if MODEL_PROVIDER_MAP.get(equivalent_model_enum) != target_provider:
        # Mapping doesn't match target provider (shouldn't happen with correct mapping)
        logger.error(
            f"Model translation error: Mapped model {equivalent_model_enum.value} belongs to "
            f"{MODEL_PROVIDER_MAP.get(equivalent_model_enum)}, not {target_provider}. "
            "This is a configuration error in MODEL_EQUIVALENCE_MAP."
        )
        return None

    return equivalent_model_enum.value


class Integration(Base):
    """Model for storing integration configurations."""
    
    __tablename__ = "integrations"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    organization_id = Column(UUID(as_uuid=True), ForeignKey("organizations.id", ondelete="CASCADE"), nullable=False)
    type = Column(SQLEnum(IntegrationType, values_callable=lambda obj: [e.value for e in obj]), nullable=False)
    status = Column(SQLEnum(IntegrationStatus, values_callable=lambda obj: [e.value for e in obj]), nullable=False, default=IntegrationStatus.DISCONNECTED)
    
    # Encrypted credentials (should be encrypted in production)
    api_key = Column(String, nullable=True)
    webhook_secret = Column(String, nullable=True)
    
    # Configuration settings
    auto_sync = Column(Boolean, default=True)
    selected_project_id = Column(UUID(as_uuid=True), nullable=True)  # null means "all projects" with smart matching
    custom_settings = Column(JSON, nullable=True, default={})
    
    # Timestamps
    connected_at = Column(DateTime, nullable=True)
    last_sync_at = Column(DateTime, nullable=True)
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)
    updated_at = Column(DateTime, nullable=False, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Metadata
    connected_by = Column(String, nullable=True)
    error_message = Column(String, nullable=True)
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert integration to dictionary."""
        return {
            "id": str(self.id),
            "type": self.type.value,
            "status": self.status.value,
            "auto_sync": self.auto_sync,
            "selected_project_id": str(self.selected_project_id) if self.selected_project_id else None,
            "custom_settings": self.custom_settings or {},
            "connected_at": self.connected_at.isoformat() if self.connected_at else None,
            "last_sync_at": self.last_sync_at.isoformat() if self.last_sync_at else None,
            "created_at": self.created_at.isoformat(),
            "updated_at": self.updated_at.isoformat(),
            "connected_by": self.connected_by,
            "error_message": self.error_message
        }