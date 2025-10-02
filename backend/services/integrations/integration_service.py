"""Service for managing integration configurations."""

import uuid
from typing import Optional, Dict, Any, List
from datetime import datetime
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update, and_
import json
import base64
from cryptography.fernet import Fernet
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC
from cryptography.hazmat.backends import default_backend

from models.integration import Integration, IntegrationType, IntegrationStatus
from config import get_settings
from utils.logger import get_logger
from utils.monitoring import monitor_operation

logger = get_logger(__name__)


class IntegrationService:
    """Service for managing integration configurations."""
    
    def __init__(self):
        """Initialize the integration service."""
        settings = get_settings()
        # In production, use a proper key management service
        # For now, derive encryption key from a configured secret
        self.encryption_key = self._derive_encryption_key(
            settings.api_key or "default-secret-key-change-in-production"
        )
        self.cipher = Fernet(self.encryption_key)
    
    def _derive_encryption_key(self, secret: str) -> bytes:
        """Derive an encryption key from a secret."""
        kdf = PBKDF2HMAC(
            algorithm=hashes.SHA256(),
            length=32,
            salt=b'pm-master-salt',  # In production, use random salt stored separately
            iterations=100000,
            backend=default_backend()
        )
        key = base64.urlsafe_b64encode(kdf.derive(secret.encode()))
        return key
    
    def _encrypt_value(self, value: Optional[str]) -> Optional[str]:
        """Encrypt a sensitive value."""
        if not value:
            return None
        try:
            return self.cipher.encrypt(value.encode()).decode()
        except Exception as e:
            logger.error(f"Failed to encrypt value: {e}")
            # In development, store unencrypted with warning
            logger.warning("Storing value unencrypted - fix encryption in production!")
            return value
    
    def _decrypt_value(self, encrypted_value: Optional[str]) -> Optional[str]:
        """Decrypt a sensitive value."""
        if not encrypted_value:
            return None
        try:
            return self.cipher.decrypt(encrypted_value.encode()).decode()
        except Exception:
            # If decryption fails, assume it's unencrypted (development mode)
            logger.warning("Failed to decrypt value - assuming unencrypted")
            return encrypted_value
    
    @monitor_operation("get_integration", "database")
    async def get_integration(
        self,
        session: AsyncSession,
        integration_type: IntegrationType,
        organization_id: uuid.UUID
    ) -> Optional[Integration]:
        """Get an integration by type and organization."""
        try:
            result = await session.execute(
                select(Integration).where(
                    Integration.type == integration_type.value,
                    Integration.organization_id == organization_id
                )
            )
            return result.scalar_one_or_none()
        except Exception as e:
            logger.error(f"Failed to get integration {integration_type}: {e}")
            raise
    
    @monitor_operation("list_integrations", "database")
    async def list_integrations(
        self,
        session: AsyncSession,
        organization_id: uuid.UUID
    ) -> List[Integration]:
        """List all integrations for an organization."""
        try:
            result = await session.execute(
                select(Integration).where(
                    Integration.organization_id == organization_id
                )
            )
            return result.scalars().all()
        except Exception as e:
            logger.error(f"Failed to list integrations: {e}")
            raise
    
    @monitor_operation("connect_integration", "database")
    async def connect_integration(
        self,
        session: AsyncSession,
        integration_type: IntegrationType,
        organization_id: uuid.UUID,
        api_key: str,
        webhook_secret: Optional[str] = None,
        auto_sync: bool = True,
        selected_project_id: Optional[uuid.UUID] = None,
        custom_settings: Optional[Dict[str, Any]] = None,
        connected_by: str = "system"
    ) -> Integration:
        """Connect or update an integration."""
        try:
            # Check if integration already exists
            existing = await self.get_integration(session, integration_type, organization_id)
            
            if existing:
                # Update existing integration
                # Handle special case where frontend wants to keep existing API key
                if api_key != "KEEP_EXISTING_KEY":
                    existing.api_key = self._encrypt_value(api_key)
                # else: keep the existing encrypted api_key

                existing.webhook_secret = self._encrypt_value(webhook_secret)
                existing.auto_sync = auto_sync
                existing.selected_project_id = selected_project_id
                existing.custom_settings = custom_settings or {}
                existing.status = IntegrationStatus.CONNECTED
                existing.connected_at = datetime.utcnow()
                existing.connected_by = connected_by
                existing.error_message = None
                existing.updated_at = datetime.utcnow()
                
                await session.flush()
                logger.info(f"Updated integration: {integration_type.value}")
                return existing
            else:
                # Create new integration
                integration = Integration(
                    organization_id=organization_id,
                    type=integration_type,
                    api_key=self._encrypt_value(api_key),
                    webhook_secret=self._encrypt_value(webhook_secret),
                    auto_sync=auto_sync,
                    selected_project_id=selected_project_id,
                    custom_settings=custom_settings or {},
                    status=IntegrationStatus.CONNECTED,
                    connected_at=datetime.utcnow(),
                    connected_by=connected_by
                )
                session.add(integration)
                await session.flush()
                logger.info(f"Created new integration: {integration_type.value}")
                return integration
                
        except Exception as e:
            logger.error(f"Failed to connect integration {integration_type}: {e}")
            raise
    
    @monitor_operation("disconnect_integration", "database")
    async def disconnect_integration(
        self,
        session: AsyncSession,
        integration_type: IntegrationType,
        organization_id: uuid.UUID
    ) -> bool:
        """Disconnect an integration."""
        try:
            integration = await self.get_integration(session, integration_type, organization_id)
            if not integration:
                return False
            
            # Clear sensitive data
            integration.api_key = None
            integration.webhook_secret = None
            integration.status = IntegrationStatus.DISCONNECTED
            integration.updated_at = datetime.utcnow()
            
            await session.flush()
            logger.info(f"Disconnected integration: {integration_type.value}")
            return True
            
        except Exception as e:
            logger.error(f"Failed to disconnect integration {integration_type}: {e}")
            raise
    
    @monitor_operation("update_sync_time", "database")
    async def update_sync_time(
        self,
        session: AsyncSession,
        integration_type: IntegrationType,
        organization_id: uuid.UUID
    ) -> bool:
        """Update the last sync time for an integration."""
        try:
            integration = await self.get_integration(session, integration_type, organization_id)
            if not integration:
                return False
            
            integration.last_sync_at = datetime.utcnow()
            integration.updated_at = datetime.utcnow()
            
            await session.flush()
            return True
            
        except Exception as e:
            logger.error(f"Failed to update sync time for {integration_type}: {e}")
            raise
    
    @monitor_operation("get_integration_config", "database")
    async def get_integration_config(
        self,
        session: AsyncSession,
        integration_type: IntegrationType,
        organization_id: uuid.UUID
    ) -> Optional[Dict[str, Any]]:
        """Get decrypted configuration for an integration."""
        try:
            integration = await self.get_integration(session, integration_type, organization_id)
            if not integration or integration.status != IntegrationStatus.CONNECTED:
                return None
            
            return {
                "api_key": self._decrypt_value(integration.api_key),
                "webhook_secret": self._decrypt_value(integration.webhook_secret),
                "auto_sync": integration.auto_sync,
                "selected_project_id": str(integration.selected_project_id) if integration.selected_project_id else None,
                "custom_settings": integration.custom_settings or {},
                "connected_at": integration.connected_at,
                "last_sync_at": integration.last_sync_at,
                "organization_id": str(integration.organization_id)
            }
            
        except Exception as e:
            logger.error(f"Failed to get config for {integration_type}: {e}")
            raise
    
    @monitor_operation("set_integration_error", "database")
    async def set_integration_error(
        self,
        session: AsyncSession,
        integration_type: IntegrationType,
        organization_id: uuid.UUID,
        error_message: str
    ) -> bool:
        """Set an error message for an integration."""
        try:
            integration = await self.get_integration(session, integration_type, organization_id)
            if not integration:
                return False
            
            integration.status = IntegrationStatus.ERROR
            integration.error_message = error_message[:500]  # Limit error message length
            integration.updated_at = datetime.utcnow()
            
            await session.flush()
            logger.warning(f"Set error for integration {integration_type.value}: {error_message}")
            return True
            
        except Exception as e:
            logger.error(f"Failed to set error for {integration_type}: {e}")
            raise

    @monitor_operation("get_integration_config_by_webhook_id", "database")
    async def get_integration_config_by_webhook_id(
        self,
        session: AsyncSession,
        integration_type: IntegrationType,
        webhook_id: str
    ) -> Optional[Dict[str, Any]]:
        """Get decrypted configuration for an integration by webhook ID.

        This is used for webhook endpoints where we don't have user context.
        The webhook_id could be the integration ID or organization ID.
        """
        try:
            # Try to find the integration by ID or organization ID
            # For now, we'll use webhook_id as organization_id since it's passed in the URL
            try:
                org_id = uuid.UUID(webhook_id)
                integration = await self.get_integration(session, integration_type, org_id)
            except ValueError:
                # webhook_id is not a valid UUID, return None
                return None

            if not integration or integration.status != IntegrationStatus.CONNECTED:
                return None

            return {
                "api_key": self._decrypt_value(integration.api_key),
                "webhook_secret": self._decrypt_value(integration.webhook_secret),
                "auto_sync": integration.auto_sync,
                "selected_project_id": str(integration.selected_project_id) if integration.selected_project_id else None,
                "custom_settings": integration.custom_settings or {},
                "connected_at": integration.connected_at,
                "last_sync_at": integration.last_sync_at,
                "organization_id": str(integration.organization_id)
            }

        except Exception as e:
            logger.error(f"Failed to get config by webhook ID for {integration_type}: {e}")
            raise


# Singleton instance
integration_service = IntegrationService()