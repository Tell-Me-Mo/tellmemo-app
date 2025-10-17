"""
Integration router for handling external service integrations
"""
import uuid
from datetime import datetime
from typing import Dict, Any, List, Optional
from fastapi import APIRouter, Depends, HTTPException, Header, Request
from pydantic import BaseModel
import json
import hashlib
import hmac
import logging
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import and_

from db.database import get_db
from dependencies.auth import get_current_organization, get_current_user, require_role
from models.organization import Organization
from models.user import User
from models.project import Project
from models.integration import IntegrationType, IntegrationStatus as IntegrationStatusEnum
from services.core.content_service import ContentService
from services.transcription.fireflies_service import FirefliesService
from services.transcription.salad_transcription_service import SaladTranscriptionService
from services.intelligence.project_matcher_service import project_matcher_service
from services.integrations.integration_service import integration_service
from models.content import ContentType
from utils.logger import sanitize_for_log
from queue_config import queue_config

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/v1/integrations", tags=["integrations"])

# Pydantic models for request/response
class IntegrationConfig(BaseModel):
    api_key: str
    webhook_secret: Optional[str] = None
    auto_sync: bool = True
    selected_project: Optional[str] = None
    custom_settings: Optional[Dict[str, Any]] = None

class IntegrationStatus(BaseModel):
    id: str
    name: str
    type: str
    status: str
    connected_at: Optional[datetime] = None
    last_sync_at: Optional[datetime] = None
    configuration: Optional[Dict[str, Any]] = None

class FirefliesWebhookPayload(BaseModel):
    meetingId: str
    eventType: str

# Integration configuration is now stored in database via integration_service

@router.get("/", response_model=List[IntegrationStatus])
async def get_integrations(
    db: AsyncSession = Depends(get_db),
    current_org: Organization = Depends(get_current_organization),
    current_user: User = Depends(get_current_user),
    _: str = Depends(require_role("member"))
):
    """Get list of available integrations"""
    # Get all configured integrations from database for current organization
    db_integrations = await integration_service.list_integrations(db, current_org.id)
    
    # Create a map of existing integrations
    existing_map = {integration.type: integration for integration in db_integrations}
    
    # Define all available integration types
    available_integrations = [
        {
            "type": IntegrationType.AI_BRAIN,
            "name": "AI Brain",
        },
        {
            "type": IntegrationType.FIREFLIES,
            "name": "Fireflies.ai",
        },
        {
            "type": IntegrationType.TRANSCRIPTION,
            "name": "Transcription Service",
        },
        # Add more integrations here as they become available
    ]
    
    integrations = []
    for integration_info in available_integrations:
        integration_type = integration_info["type"]
        existing = existing_map.get(integration_type)
        
        if existing:
            integrations.append(
                IntegrationStatus(
                    id=integration_type.value,
                    name=integration_info["name"],
                    type=integration_type.value,
                    status=existing.status.value,
                    connected_at=existing.connected_at,
                    last_sync_at=existing.last_sync_at,
                    configuration={
                        "auto_sync": existing.auto_sync,
                        "selected_project": str(existing.selected_project_id) if existing.selected_project_id else "all_projects",
                        "custom_settings": existing.custom_settings if existing.custom_settings else {}
                    } if existing.status == IntegrationStatusEnum.CONNECTED else None
                )
            )
        else:
            integrations.append(
                IntegrationStatus(
                    id=integration_type.value,
                    name=integration_info["name"],
                    type=integration_type.value,
                    status="not_connected",
                    connected_at=None,
                    last_sync_at=None,
                    configuration=None
                )
            )
    
    return integrations

@router.post("/{integration_id}/connect")
async def connect_integration(
    integration_id: str,
    config: IntegrationConfig,
    db: AsyncSession = Depends(get_db),
    current_org: Organization = Depends(get_current_organization),
    current_user: User = Depends(get_current_user),
    _: str = Depends(require_role("admin"))
):
    """Connect an integration"""
    try:
        # Map integration_id to IntegrationType
        integration_type_map = {
            "fireflies": IntegrationType.FIREFLIES,
            "transcription": IntegrationType.TRANSCRIPTION,
            "ai_brain": IntegrationType.AI_BRAIN,
        }
        
        integration_type = integration_type_map.get(integration_id)
        if not integration_type:
            raise HTTPException(status_code=404, detail="Integration not found")
        
        # Parse project ID if provided
        project_id = None
        if config.selected_project and config.selected_project != "all_projects":
            try:
                project_id = uuid.UUID(config.selected_project)
            except ValueError:
                raise HTTPException(status_code=400, detail="Invalid project ID")
        
        # Store configuration in database
        integration = await integration_service.connect_integration(
            session=db,
            integration_type=integration_type,
            organization_id=current_org.id,
            api_key=config.api_key,
            webhook_secret=config.webhook_secret,
            auto_sync=config.auto_sync,
            selected_project_id=project_id,
            custom_settings=config.custom_settings,
            connected_by=current_user.email or "unknown"
        )
        
        await db.commit()

        logger.info(f"Connected integration: {sanitize_for_log(integration_id)}")
        
        return {
            "status": "connected",
            "message": f"Successfully connected to {integration_id}",
            "integration_id": integration_id,
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to connect integration {sanitize_for_log(integration_id)}: {sanitize_for_log(str(e))}")
        raise HTTPException(status_code=500, detail="Failed to connect integration. Please check your configuration.")

@router.post("/{integration_id}/disconnect")
async def disconnect_integration(
    integration_id: str,
    db: AsyncSession = Depends(get_db),
    current_org: Organization = Depends(get_current_organization),
    current_user: User = Depends(get_current_user),
    _: str = Depends(require_role("admin"))
):
    """Disconnect an integration"""
    try:
        # Map integration_id to IntegrationType
        integration_type_map = {
            "fireflies": IntegrationType.FIREFLIES,
            "transcription": IntegrationType.TRANSCRIPTION,
            "ai_brain": IntegrationType.AI_BRAIN,
        }
        
        integration_type = integration_type_map.get(integration_id)
        if not integration_type:
            raise HTTPException(status_code=404, detail="Integration not found")
        
        # Disconnect in database
        success = await integration_service.disconnect_integration(db, integration_type, current_org.id)
        
        if success:
            await db.commit()
            logger.info(f"Disconnected integration: {sanitize_for_log(integration_id)}")
            return {
                "status": "disconnected",
                "message": f"Successfully disconnected from {integration_id}",
            }
        else:
            raise HTTPException(status_code=404, detail="Integration not connected")
            
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to disconnect integration {sanitize_for_log(integration_id)}: {sanitize_for_log(str(e))}")
        raise HTTPException(status_code=500, detail="Failed to disconnect integration")

@router.post("/{integration_id}/test")
async def test_integration_connection(
    integration_id: str,
    config: IntegrationConfig,
    db: AsyncSession = Depends(get_db),
    current_org: Organization = Depends(get_current_organization),
    current_user: User = Depends(get_current_user),
    _: str = Depends(require_role("member"))
):
    """Test connection for an integration without saving configuration"""
    try:
        # Map integration_id to IntegrationType
        integration_type_map = {
            "fireflies": IntegrationType.FIREFLIES,
            "transcription": IntegrationType.TRANSCRIPTION,
            "ai_brain": IntegrationType.AI_BRAIN,
        }

        integration_type = integration_type_map.get(integration_id)
        if not integration_type:
            raise HTTPException(status_code=404, detail="Integration not found")

        # Test based on integration type
        if integration_type == IntegrationType.FIREFLIES:
            # Test Fireflies connection
            fireflies_service = FirefliesService(config.api_key)
            success = await fireflies_service.test_connection()

            if success:
                return {
                    "success": True,
                    "message": "Fireflies API connection successful"
                }
            else:
                return {
                    "success": False,
                    "error": "Failed to connect to Fireflies API. Please check your API key."
                }

        elif integration_type == IntegrationType.TRANSCRIPTION:
            # Test transcription service connection
            custom_settings = config.custom_settings or {}
            service_type = custom_settings.get("service_type", "whisper")

            if service_type == "salad":
                # Test Salad API connection
                if not config.api_key or config.api_key == "local_whisper":
                    return {
                        "success": False,
                        "error": "Salad API requires a valid API key"
                    }

                organization_name = custom_settings.get("organization_name", "")
                if not organization_name:
                    return {
                        "success": False,
                        "error": "Organization name is required for Salad API"
                    }

                # Test actual Salad API connection
                salad_service = SaladTranscriptionService(
                    api_key=config.api_key,
                    organization_name=organization_name
                )
                result = await salad_service.test_connection()
                # Don't expose internal error details to API response - use generic messages only
                if not result.get("success", False):
                    # Log the actual error for debugging but don't expose it to the user
                    if result.get("error"):
                        logger.debug(f"Salad API test failed: {result.get('error')}")
                    return {
                        "success": False,
                        "error": "Connection test failed. Please verify your API credentials."
                    }
                return {
                    "success": True,
                    "message": "Salad API connection successful"
                }
            else:
                # Local Whisper doesn't need testing
                return {
                    "success": True,
                    "message": "Local Whisper transcription is ready"
                }

        elif integration_type == IntegrationType.AI_BRAIN:
            # Test AI Brain connection (LLM provider)
            from services.llm.multi_llm_client import get_multi_llm_client
            from models.integration import AIProvider, AIModel

            custom_settings = config.custom_settings or {}
            provider = custom_settings.get("provider", "claude")
            model = custom_settings.get("model", "claude-haiku-4-5-20251001")

            # Validate provider and model
            try:
                provider_enum = AIProvider(provider)
                model_enum = AIModel(model)
            except ValueError:
                return {
                    "success": False,
                    "error": f"Invalid provider or model: {provider}/{model}"
                }

            # Test the configuration
            client = get_multi_llm_client()
            result = await client.test_configuration(
                provider=provider_enum,
                api_key=config.api_key,
                model=model
            )

            # Don't expose internal error details to API response - use generic messages only
            if result.get("success", False):
                # Use generic success message, don't expose internal details
                return {
                    "success": True,
                    "message": "Connection test successful"
                }
            else:
                # Log the actual error for debugging but don't expose it to the user
                if result.get("error"):
                    logger.debug(f"AI Brain test failed: {result.get('error')}")
                return {
                    "success": False,
                    "error": "Connection test failed. Please check your credentials."
                }

        return {
            "success": False,
            "error": "Unknown integration type"
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to test integration {sanitize_for_log(integration_id)}: {e}", exc_info=True)
        return {
            "success": False,
            "error": "Connection test failed. Please check your configuration."
        }

@router.post("/{integration_id}/sync")
async def sync_integration(
    integration_id: str,
    db: AsyncSession = Depends(get_db),
    current_org: Organization = Depends(get_current_organization),
    current_user: User = Depends(get_current_user),
    _: str = Depends(require_role("member"))
):
    """Manually trigger sync for an integration"""
    try:
        # Map integration_id to IntegrationType
        integration_type_map = {
            "fireflies": IntegrationType.FIREFLIES,
            "transcription": IntegrationType.TRANSCRIPTION,
            "ai_brain": IntegrationType.AI_BRAIN,
        }
        
        integration_type = integration_type_map.get(integration_id)
        if not integration_type:
            raise HTTPException(status_code=404, detail="Integration not found")
        
        # Check if integration is connected for current organization
        config = await integration_service.get_integration_config(db, integration_type, current_org.id)
        if not config:
            raise HTTPException(status_code=400, detail="Integration not connected")
        
        # Update last sync time
        await integration_service.update_sync_time(db, integration_type, current_org.id)
        await db.commit()

        # TODO: Implement actual sync logic
        logger.info(f"Syncing integration: {sanitize_for_log(integration_id)}")
        
        return {
            "status": "syncing",
            "message": f"Sync initiated for {integration_id}",
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to sync integration {sanitize_for_log(integration_id)}: {sanitize_for_log(str(e))}")
        raise HTTPException(status_code=500, detail="Failed to sync integration")

@router.post("/webhooks/fireflies/{integration_id}")
async def fireflies_webhook(
    integration_id: str,
    payload: FirefliesWebhookPayload,
    db: AsyncSession = Depends(get_db),
    x_fireflies_signature: Optional[str] = Header(None),
    # Note: Webhooks don't have user context, we'll need to identify org from integration_id
):
    """
    Webhook endpoint for receiving Fireflies.ai meeting completion notifications
    
    Expected payload format:
    {"meetingId": "01K4YNPA4QTTJBV9GKS4QEFWMW", "eventType": "Transcription completed"}
    """
    try:
        # Get integration config from database - need to find organization from integration_id
        # This is a webhook endpoint, so we need to identify the organization differently
        config = await integration_service.get_integration_config_by_webhook_id(db, IntegrationType.FIREFLIES, integration_id)
        
        if config:
            webhook_secret = config.get("webhook_secret")
            
            if webhook_secret and x_fireflies_signature:
                # Create signature from payload
                payload_str = json.dumps(payload.dict(), separators=(',', ':'))
                expected_signature = hmac.new(
                    webhook_secret.encode(),
                    payload_str.encode(),
                    hashlib.sha256
                ).hexdigest()
                
                if not hmac.compare_digest(expected_signature, x_fireflies_signature):
                    logger.warning(f"Invalid webhook signature for integration {sanitize_for_log(integration_id)}")
                    raise HTTPException(status_code=401, detail="Invalid signature")
        
        # Check if this is a transcription completed event
        if payload.eventType != "Transcription completed":
            logger.info(f"Ignoring Fireflies event type: {sanitize_for_log(payload.eventType)}")
            return {
                "status": "ignored",
                "message": f"Event type '{payload.eventType}' not processed"
            }
        
        # Get Fireflies API key from database config
        if not config:
            raise HTTPException(
                status_code=400, 
                detail="Fireflies integration not configured. Please connect the integration first."
            )
        
        api_key = config.get("api_key")
        
        if not api_key:
            raise HTTPException(
                status_code=400,
                detail="Fireflies API key not configured"
            )
        
        # Get target project ID from config or use "All Projects" logic
        project_id = config.get("selected_project_id")
        use_smart_matching = not project_id or project_id == "all_projects"

        # Enqueue RQ task for Fireflies transcript processing
        from tasks.integration_tasks import process_fireflies_transcript_task

        organization_id = uuid.UUID(config['organization_id'])

        rq_job = queue_config.default_queue.enqueue(
            process_fireflies_transcript_task,
            meeting_id=payload.meetingId,
            api_key=api_key,
            organization_id=str(organization_id),  # Convert UUID to string for RQ
            project_id=str(project_id) if project_id and project_id != "all_projects" else None,
            use_smart_matching=use_smart_matching,
            job_timeout='20m',  # 20 minute timeout
            result_ttl=3600,  # Keep result for 1 hour
            failure_ttl=86400  # Keep failed jobs for 24 hours
        )

        # Initialize RQ job metadata for progress tracking
        rq_job.meta['status'] = 'processing'
        rq_job.meta['progress'] = 0.0
        rq_job.meta['step'] = 'Fireflies webhook received, queuing for processing...'
        rq_job.meta['current_step'] = 0
        rq_job.meta['total_steps'] = 6
        rq_job.meta['meeting_id'] = payload.meetingId
        rq_job.meta['source'] = 'fireflies'
        rq_job.save_meta()

        logger.info(f"Enqueued Fireflies webhook processing for meeting {payload.meetingId} (RQ job: {rq_job.id})")

        # Update last sync time in database for the organization that owns this integration
        if config and config.get('organization_id'):
            await integration_service.update_sync_time(db, IntegrationType.FIREFLIES, config['organization_id'])
        await db.commit()

        logger.info(f"Received Fireflies webhook for meeting ID: {sanitize_for_log(payload.meetingId)}")
        
        return {
            "status": "accepted",
            "message": "Webhook received successfully",
            "meeting_id": payload.meetingId,
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error processing Fireflies webhook: {sanitize_for_log(str(e))}")
        raise HTTPException(status_code=500, detail="Failed to process webhook")


@router.get("/{integration_id}/activity")
async def get_integration_activity(
    integration_id: str,
    limit: int = 50,
    db: AsyncSession = Depends(get_db),
    current_org: Organization = Depends(get_current_organization),
    current_user: User = Depends(get_current_user),
    _: str = Depends(require_role("member"))
):
    """Get activity log for an integration"""
    # Map integration_id to IntegrationType
    integration_type_map = {
        "fireflies": IntegrationType.FIREFLIES,
    }
    
    integration_type = integration_type_map.get(integration_id)
    if not integration_type:
        return []
    
    # Check if integration exists for current organization
    integration = await integration_service.get_integration(db, integration_type, current_org.id)
    if not integration:
        return []
    
    # TODO: Implement actual activity tracking from database
    # For now, return sample activity if connected
    if integration.status == IntegrationStatusEnum.CONNECTED:
        return [
        {
            "id": "1",
            "type": "import",
            "title": "Meeting imported",
            "description": "Weekly team standup - 45 minutes",
            "timestamp": datetime.now().isoformat(),
            "status": "success",
        },
        {
            "id": "2",
            "type": "sync",
            "title": "Sync completed",
            "description": "3 new meetings found",
            "timestamp": datetime.now().isoformat(),
            "status": "success",
        },
    ]
    else:
        return []