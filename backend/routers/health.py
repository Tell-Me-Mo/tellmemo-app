from datetime import datetime
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Dict, Any

from config import get_settings
from utils.logger import get_logger
from db.database import db_manager
from db.multi_tenant_vector_store import multi_tenant_vector_store
from services.observability.langfuse_service import langfuse_service

settings = get_settings()
router = APIRouter()
logger = get_logger(__name__)


class HealthResponse(BaseModel):
    status: str
    timestamp: datetime
    environment: str
    version: str
    services: Dict[str, Any]


@router.get("/health", response_model=HealthResponse)
async def health_check():
    try:
        # Check PostgreSQL connection
        db_healthy = await db_manager.check_connection()
        db_version = "Unknown"
        if db_healthy:
            db_version = await db_manager.get_pg_version()
            # Extract just the version number
            if db_version and "PostgreSQL" in db_version:
                db_version = db_version.split()[1]
        
        # Check Qdrant connection
        qdrant_healthy = await multi_tenant_vector_store.check_connection()
        qdrant_info = {}
        if qdrant_healthy:
            # Get info about all organization collections
            org_collections = await multi_tenant_vector_store.list_organization_collections()
            qdrant_info = {
                "total_collections": len(org_collections),
                "organizations": len(set(c.get("organization_id") for c in org_collections)),
                "total_vectors": sum(c.get("vectors_count", 0) for c in org_collections)
            }
        
        services_status = {
            "api": "healthy",
            "database": {
                "status": "healthy" if db_healthy else "unhealthy",
                "version": db_version,
                "host": settings.postgres_host,
                "port": settings.postgres_port,
                "database": settings.postgres_db
            },
            "qdrant": {
                "status": "healthy" if qdrant_healthy else "unhealthy",
                "host": settings.qdrant_host,
                "port": settings.qdrant_port,
                "collection": settings.qdrant_collection,
                **qdrant_info
            },
            "langfuse": await langfuse_service.check_health()
        }
        
        # Overall status is healthy only if all critical services are healthy
        overall_status = "healthy" if db_healthy and qdrant_healthy else "degraded"
        
        return HealthResponse(
            status=overall_status,
            timestamp=datetime.now(),
            environment=settings.api_env,
            version="0.1.0",
            services=services_status
        )
    except Exception as e:
        logger.error(f"Health check failed: {e}")
        raise HTTPException(status_code=503, detail="Service unavailable")