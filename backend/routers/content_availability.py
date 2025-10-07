"""API endpoints for checking content availability."""

from fastapi import APIRouter, HTTPException, Depends, Query
from pydantic import BaseModel
from typing import Optional, Dict, Any
from datetime import datetime
from sqlalchemy.ext.asyncio import AsyncSession
import uuid

from db.database import get_db
from dependencies.auth import get_current_organization
from models.organization import Organization
from services.core.content_availability_service import content_availability_service
from utils.logger import get_logger, sanitize_for_log

router = APIRouter()
logger = get_logger(__name__)


class ContentAvailabilityResponse(BaseModel):
    """Response model for content availability check."""
    has_content: bool
    content_count: int
    can_generate_summary: bool
    message: str
    latest_content_date: Optional[str] = None
    content_breakdown: Optional[Dict[str, int]] = None
    project_count: Optional[int] = None
    projects_with_content: Optional[int] = None
    program_count: Optional[int] = None
    program_breakdown: Optional[Dict[str, Any]] = None
    project_content_breakdown: Optional[Dict[str, int]] = None
    recent_summaries_count: Optional[int] = None


class SummaryStatsResponse(BaseModel):
    """Response model for summary generation statistics."""
    total_summaries: int
    last_generated: Optional[str] = None
    average_generation_time: float
    formats_generated: list[str]
    type_breakdown: Optional[Dict[str, int]] = None
    recent_summary_id: Optional[str] = None


@router.get("/check/{entity_type}/{entity_id}", response_model=ContentAvailabilityResponse)
async def check_content_availability(
    entity_type: str,
    entity_id: str,
    date_start: Optional[datetime] = Query(None),
    date_end: Optional[datetime] = Query(None),
    session: AsyncSession = Depends(get_db),
    current_org: Organization = Depends(get_current_organization)
):
    """Check content availability for a given entity (project, program, or portfolio)."""
    logger.info(f"Checking content availability for {sanitize_for_log(entity_type)} {sanitize_for_log(entity_id)}")

    try:
        # Validate entity type
        if entity_type not in ["project", "program", "portfolio"]:
            raise HTTPException(
                status_code=400,
                detail="Invalid entity type. Must be 'project', 'program', or 'portfolio'"
            )

        # Convert entity_id to UUID
        try:
            entity_uuid = uuid.UUID(entity_id)
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid entity ID format")

        # Check availability based on entity type
        result = None
        if entity_type == "project":
            result = await content_availability_service.check_project_content(
                session, entity_uuid, current_org.id, date_start, date_end
            )
        elif entity_type == "program":
            result = await content_availability_service.check_program_content(
                session, entity_uuid, current_org.id, date_start, date_end
            )
        elif entity_type == "portfolio":
            result = await content_availability_service.check_portfolio_content(
                session, entity_uuid, current_org.id, date_start, date_end
            )

        if result is None:
            raise HTTPException(status_code=500, detail="Failed to check content availability")

        return ContentAvailabilityResponse(**result)

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error checking content availability: {e}")
        raise HTTPException(status_code=500, detail="Failed to check content availability")


@router.get("/stats/{entity_type}/{entity_id}", response_model=SummaryStatsResponse)
async def get_summary_statistics(
    entity_type: str,
    entity_id: str,
    session: AsyncSession = Depends(get_db),
    current_org: Organization = Depends(get_current_organization)
):
    """Get summary generation statistics for a given entity."""
    logger.info(f"Getting summary statistics for {sanitize_for_log(entity_type)} {sanitize_for_log(entity_id)}")

    try:
        # Validate entity type
        if entity_type not in ["project", "program", "portfolio"]:
            raise HTTPException(
                status_code=400,
                detail="Invalid entity type. Must be 'project', 'program', or 'portfolio'"
            )

        # Convert entity_id to UUID
        try:
            entity_uuid = uuid.UUID(entity_id)
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid entity ID format")

        # Get statistics
        stats = await content_availability_service.get_summary_generation_stats(
            session, entity_type, entity_uuid, current_org.id
        )

        return SummaryStatsResponse(**stats)

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting summary statistics: {e}")
        raise HTTPException(status_code=500, detail="Failed to get summary statistics")


@router.post("/batch-check")
async def batch_check_availability(
    entities: list[Dict[str, str]],
    date_start: Optional[datetime] = None,
    date_end: Optional[datetime] = None,
    session: AsyncSession = Depends(get_db),
    current_org: Organization = Depends(get_current_organization)
):
    """Check content availability for multiple entities at once."""
    logger.info(f"Batch checking content availability for {len(entities)} entities")

    results = {}

    for entity in entities:
        entity_type = entity.get("type")
        entity_id = entity.get("id")

        if not entity_type or not entity_id:
            continue

        try:
            entity_uuid = uuid.UUID(entity_id)

            if entity_type == "project":
                result = await content_availability_service.check_project_content(
                    session, entity_uuid, current_org.id, date_start, date_end
                )
            elif entity_type == "program":
                result = await content_availability_service.check_program_content(
                    session, entity_uuid, current_org.id, date_start, date_end
                )
            elif entity_type == "portfolio":
                result = await content_availability_service.check_portfolio_content(
                    session, entity_uuid, current_org.id, date_start, date_end
                )
            else:
                continue

            results[entity_id] = result

        except Exception as e:
            logger.error(f"Error checking availability for {sanitize_for_log(entity_type)} {sanitize_for_log(entity_id)}: {e}")
            results[entity_id] = {
                "has_content": False,
                "error": str(e)
            }

    return results