"""
Upload router for content that doesn't require a pre-specified project ID.
This includes AI-based project matching functionality.
"""
from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime, date as DateType
from sqlalchemy.ext.asyncio import AsyncSession
import uuid

from db.database import db_manager, get_db
from dependencies.auth import get_current_organization
from models.organization import Organization
from models.content import ContentType
from services.core.content_service import ContentService
from services.intelligence.project_matcher_service import project_matcher_service
from utils.logger import get_logger
from config import get_settings

settings = get_settings()
router = APIRouter()
logger = get_logger(__name__)


class UploadContentWithAIMatchingRequest(BaseModel):
    content_type: str = Field(..., description="Type of content: 'meeting' or 'email'")
    title: str = Field(..., description="Title of the content")
    content: str = Field(..., description="Raw text content")
    date: Optional[DateType] = Field(None, description="Date of the content")
    use_ai_matching: bool = Field(True, description="Use AI to match to project")


class UploadResponse(BaseModel):
    id: str
    message: str
    status: str
    project_id: str
    content_type: str
    title: str
    uploaded_at: datetime
    chunk_count: int
    job_id: Optional[str] = None


@router.post("/with-ai-matching", response_model=UploadResponse)
async def upload_content_with_ai_matching(
    request: UploadContentWithAIMatchingRequest,
    session: AsyncSession = Depends(get_db),
    current_org: Organization = Depends(get_current_organization)
):
    """
    Upload content with AI-based project matching.
    
    This endpoint uses AI to automatically determine which project the content
    belongs to, or creates a new project if necessary.
    """
    try:
        # Validate content type
        if request.content_type not in ["meeting", "email"]:
            raise HTTPException(
                status_code=400,
                detail="Invalid content type. Must be 'meeting' or 'email'"
            )
        
        # Validate content
        if not request.content or len(request.content.strip()) < 50:
            raise HTTPException(
                status_code=400,
                detail="Content is too short. Please provide more detailed content."
            )
        
        if len(request.content) > settings.max_file_size_mb * 1024 * 1024:
            raise HTTPException(
                status_code=400,
                detail=f"Content exceeds maximum size of {settings.max_file_size_mb}MB"
            )
        
        # Use AI to match content to project
        match_result = await project_matcher_service.match_transcript_to_project(
            session=session,
            organization_id=current_org.id,
            transcript=request.content,
            meeting_title=request.title,
            meeting_date=datetime.combine(request.date, datetime.min.time()) if request.date else None,
            participants=[]  # Could be extracted from content if needed
        )
        
        project_uuid = match_result["project_id"]
        
        logger.info(
            f"AI Matching Result: {'Created new' if match_result['is_new'] else 'Matched to existing'} "
            f"project '{match_result['project_name']}' (confidence: {match_result['confidence']})"
        )
        
        # Create content entry with the matched/created project
        content_type_enum = ContentType.MEETING if request.content_type == "meeting" else ContentType.EMAIL
        content = await ContentService.create_content(
            session=session,
            project_id=project_uuid,
            content_type=content_type_enum,
            title=request.title,
            content=request.content,
            content_date=request.date,
            uploaded_by=None  # No auth in MVP
        )
        
        await session.commit()

        # Trigger async processing (returns RQ job ID)
        rq_job_id = await ContentService.trigger_async_processing(
            content_id=content.id,
            job_metadata={
                "content_id": str(content.id),
                "title": request.title,
                "project_id": str(project_uuid),
                "filename": request.title,
                "ai_matched": True,
                "is_new_project": match_result['is_new'],
                "match_confidence": match_result['confidence']
            }
        )
        
        logger.info(f"Successfully uploaded content {content.id} with AI matching to project {project_uuid}")
        
        return UploadResponse(
            id=str(content.id),
            message=f"Content uploaded and {'assigned to new' if match_result['is_new'] else 'matched to existing'} project: {match_result['project_name']}",
            status="processing",
            project_id=str(project_uuid),
            content_type=request.content_type,
            title=request.title,
            uploaded_at=content.uploaded_at,
            chunk_count=0,  # Will be updated after processing
            job_id=rq_job_id  # Return RQ job ID for websocket tracking
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to upload content with AI matching: {e}")
        raise HTTPException(
            status_code=500,
            detail="Failed to upload content. Please try again."
        )