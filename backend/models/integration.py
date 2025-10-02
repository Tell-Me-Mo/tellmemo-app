"""Integration model for storing external service configurations."""

import uuid
from datetime import datetime
from typing import Optional, Dict, Any
from sqlalchemy import Column, String, DateTime, Boolean, JSON, Enum as SQLEnum, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
import enum

from db.database import Base


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