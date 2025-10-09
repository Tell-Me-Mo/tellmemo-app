from fastapi import APIRouter, HTTPException, UploadFile, File, Depends, Form, Request
from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime, date as DateType
from sqlalchemy.ext.asyncio import AsyncSession
import uuid
import time

from db.database import db_manager, get_db
from dependencies.auth import get_current_organization, get_current_user, require_role
from models.organization import Organization
from models.user import User
from models.content import ContentType
from services.core.content_service import ContentService
from services.observability.langfuse_service import langfuse_service
from services.intelligence.project_matcher_service import project_matcher_service
from utils.logger import get_logger, sanitize_for_log
from config import get_settings

settings = get_settings()

router = APIRouter()
logger = get_logger(__name__)


class UploadContentRequest(BaseModel):
    content_type: str = Field(..., description="Type of content: 'meeting' or 'email'")
    title: str = Field(..., description="Title of the content")
    content: str = Field(..., description="Raw text content")
    date: Optional[DateType] = Field(None, description="Date of the content")
    use_ai_matching: bool = Field(False, description="Use AI to match to project if project_id is 'auto'")




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


class ContentResponse(BaseModel):
    id: str
    project_id: str
    content_type: str
    title: str
    date: Optional[DateType]
    uploaded_at: datetime
    uploaded_by: Optional[str]
    chunk_count: int
    summary_generated: bool
    processed_at: Optional[datetime]
    processing_error: Optional[str]
    content: Optional[str] = None  # Include actual content text when requested


@router.post("/{project_id}/upload", response_model=UploadResponse)
async def upload_content(
    request: Request,
    project_id: str,
    file: UploadFile = File(..., description="Text file to upload"),
    content_type: str = Form(..., description="Type: 'meeting' or 'email'"),
    title: Optional[str] = Form(None, description="Title (optional, uses filename if not provided)"),
    content_date: Optional[DateType] = Form(None, description="Date of content (optional)"),
    use_ai_matching: bool = Form(False, description="Use AI to match to project if project_id is 'auto'"),
    session: AsyncSession = Depends(get_db),
    current_org: Organization = Depends(get_current_organization),
    current_user: User = Depends(get_current_user)
):
    """
    Upload a text file containing meeting transcript or email content.
    
    Accepts only .txt files up to 10MB in size.
    The content will be processed asynchronously for chunking and embedding.
    """
    start_time = time.time()
    langfuse_client = langfuse_service.client
    
    # Check if we can use context managers
    if langfuse_client and hasattr(langfuse_client, 'start_as_current_span'):
        with langfuse_client.start_as_current_span(
            name="content_upload",
            input={
                "project_id": project_id,
                "filename": file.filename,
                "content_type": content_type,
                "title": title or file.filename
            }
        ) as upload_span:
            try:
                # Validate content type
                if content_type not in ["meeting", "email"]:
                    raise HTTPException(
                        status_code=400,
                        detail="Invalid content type. Must be 'meeting' or 'email'"
                    )
                
                # Handle project ID - either use provided or match with AI
                if project_id == "auto" and use_ai_matching:
                    # Read file content for AI matching
                    file_content = await file.read()
                    file_size = len(file_content)

                    validation_result = await ContentService.validate_file_upload(
                        file_content=file_content,
                        filename=file.filename,
                        content_type=file.content_type or "text/plain"
                    )

                    # Use AI to match content to project
                    match_result = await project_matcher_service.match_transcript_to_project(
                        session=session,
                        organization_id=current_org.id,
                        transcript=validation_result["text"],
                        meeting_title=title or file.filename.rsplit('.', 1)[0],
                        meeting_date=datetime.combine(content_date, datetime.min.time()) if content_date else None,
                        participants=[]  # Could be extracted from content if needed
                    )

                    project_uuid = match_result["project_id"]
                    project_match_info = match_result

                    logger.info(
                        f"AI Matching Result: {'Created new' if match_result['is_new'] else 'Matched to existing'} "
                        f"project '{match_result['project_name']}' (confidence: {match_result['confidence']})"
                    )
                else:
                    # Parse provided project ID
                    try:
                        project_uuid = uuid.UUID(project_id)
                        project_match_info = None
                    except ValueError:
                        raise HTTPException(status_code=400, detail="Invalid project ID format")
                
                # Use filename as title if not provided
                if not title:
                    title = file.filename.rsplit('.', 1)[0] if '.' in file.filename else file.filename
                
                # Read and validate file if not already done
                if project_id != "auto" or not use_ai_matching:
                    with langfuse_client.start_as_current_span(
                        name="validate_file"
                    ) as validate_span:
                        file_content = await file.read()
                        file_size = len(file_content)

                        validation_result = await ContentService.validate_file_upload(
                            file_content=file_content,
                            filename=file.filename,
                            content_type=file.content_type or "text/plain"
                        )

                        if hasattr(validate_span, 'update'):
                            validate_span.update(
                                output={"file_size": file_size, "valid": True}
                            )
                
                # Create content entry with monitoring
                with langfuse_client.start_as_current_span(
                    name="create_content_entry"
                ) as create_span:
                    content_type_enum = ContentType.MEETING if content_type == "meeting" else ContentType.EMAIL
                    content = await ContentService.create_content(
                        session=session,
                        project_id=project_uuid,
                        content_type=content_type_enum,
                        title=title,
                        content=validation_result["text"],
                        content_date=content_date,
                        uploaded_by=current_user.email or "unknown",
                        uploaded_by_id=str(current_user.id) if current_user else None
                    )
                    
                    await session.commit()
                    
                    if hasattr(create_span, 'update'):
                        create_span.update(
                            output={"content_id": str(content.id)}
                        )
                
                # Prepare metadata for RQ job
                job_metadata = {
                    "content_id": str(content.id),
                    "title": title,
                    "filename": file.filename,
                    "file_size": file_size,
                    "project_id": str(project_uuid)
                }
                if project_match_info:
                    job_metadata.update({
                        "ai_matched": True,
                        "is_new_project": project_match_info['is_new'],
                        "match_confidence": project_match_info['confidence'],
                        "project_name": project_match_info['project_name']
                    })

                # Trigger async processing and get RQ job ID
                rq_job_id = await ContentService.trigger_async_processing(content.id, job_metadata)
                
                # Update main span
                total_time = (time.time() - start_time) * 1000
                if hasattr(upload_span, 'update'):
                    upload_span.update(
                        output={
                            "success": True,
                            "content_id": str(content.id),
                            "processing_time_ms": total_time,
                            "file_size": file_size
                        }
                    )

                logger.info(f"Successfully uploaded content {content.id} for project {sanitize_for_log(project_id)}")
                
                # Prepare response message
                if project_match_info:
                    message = f"File '{file.filename}' uploaded and {'assigned to new' if project_match_info['is_new'] else 'matched to existing'} project: {project_match_info['project_name']}"
                else:
                    message = f"File '{file.filename}' uploaded successfully and queued for processing"

                return UploadResponse(
                    id=str(content.id),
                    message=message,
                    status="processing",
                    project_id=str(project_uuid),
                    content_type=content_type,
                    title=title,
                    uploaded_at=content.uploaded_at,
                    chunk_count=0,  # Will be updated after processing
                    job_id=rq_job_id  # Return RQ job ID directly
                )

            except ValueError as e:
                raise HTTPException(status_code=400, detail=str(e))
            except HTTPException:
                raise
            except Exception as e:
                logger.error(f"Failed to upload content: {e}")
                raise HTTPException(
                    status_code=500,
                    detail="Failed to upload content. Please try again."
                )
    else:
        # Original implementation without monitoring
        try:
            # Validate content type
            if content_type not in ["meeting", "email"]:
                raise HTTPException(
                    status_code=400,
                    detail="Invalid content type. Must be 'meeting' or 'email'"
                )
            
            # Parse project ID
            try:
                project_uuid = uuid.UUID(project_id)
            except ValueError:
                raise HTTPException(status_code=400, detail="Invalid project ID format")
            
            # Use filename as title if not provided
            if not title:
                title = file.filename.rsplit('.', 1)[0] if '.' in file.filename else file.filename
            
            # Read and validate file
            file_content = await file.read()
            validation_result = await ContentService.validate_file_upload(
                file_content=file_content,
                filename=file.filename,
                content_type=file.content_type or "text/plain"
            )
            
            # Create content entry
            content_type_enum = ContentType.MEETING if content_type == "meeting" else ContentType.EMAIL
            content = await ContentService.create_content(
                session=session,
                project_id=project_uuid,
                content_type=content_type_enum,
                title=title,
                content=validation_result["text"],
                content_date=content_date,
                uploaded_by=current_user.email or "unknown",
                uploaded_by_id=str(current_user.id) if current_user else None
            )
            
            await session.commit()
            
            # Prepare metadata for RQ job
            file_size = len(file_content)
            job_metadata = {
                "content_id": str(content.id),
                "title": title,
                "filename": file.filename,
                "file_size": file_size,
                "project_id": project_id
            }

            # Trigger async processing and get RQ job ID
            rq_job_id = await ContentService.trigger_async_processing(content.id, job_metadata)

            logger.info(f"Successfully uploaded content {content.id} for project {sanitize_for_log(project_id)}")

            return UploadResponse(
                id=str(content.id),
                message=f"File '{file.filename}' uploaded successfully and queued for processing",
                status="processing",
                project_id=project_id,
                content_type=content_type,
                title=title,
                uploaded_at=content.uploaded_at,
                chunk_count=0,  # Will be updated after processing
                job_id=rq_job_id  # Return RQ job ID directly
            )
        
        except ValueError as e:
            raise HTTPException(status_code=400, detail=str(e))
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Failed to upload content: {e}")
            raise HTTPException(
                status_code=500,
                detail="Failed to upload content. Please try again."
            )


@router.post("/{project_id}/upload/text", response_model=UploadResponse)
async def upload_text_content(
    project_id: str,
    request: UploadContentRequest,
    session: AsyncSession = Depends(get_db),
    current_org: Organization = Depends(get_current_organization),
    current_user: User = Depends(get_current_user),
    _: str = Depends(require_role("member"))
):
    """
    Upload text content directly (without file).
    
    This endpoint accepts raw text content instead of a file upload.
    Useful for API integrations or direct text input.
    """
    try:
        # Validate content type
        if request.content_type not in ["meeting", "email"]:
            raise HTTPException(
                status_code=400,
                detail="Invalid content type. Must be 'meeting' or 'email'"
            )

        # Handle project ID - either use provided or match with AI
        if project_id == "auto" and request.use_ai_matching:
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
            project_match_info = match_result

            logger.info(
                f"AI Matching Result: {'Created new' if match_result['is_new'] else 'Matched to existing'} "
                f"project '{match_result['project_name']}' (confidence: {match_result['confidence']})"
            )
        else:
            # Parse provided project ID
            try:
                project_uuid = uuid.UUID(project_id)
                project_match_info = None
            except ValueError:
                raise HTTPException(status_code=400, detail="Invalid project ID format")
        
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
        
        # Create content entry
        content_type_enum = ContentType.MEETING if request.content_type == "meeting" else ContentType.EMAIL
        content = await ContentService.create_content(
            session=session,
            project_id=project_uuid,
            content_type=content_type_enum,
            title=request.title,
            content=request.content,
            content_date=request.date,
            uploaded_by=current_user.email,
            uploaded_by_id=str(current_user.id)
        )
        
        await session.commit()
        
        # Prepare metadata for RQ job
        content_size = len(request.content.encode('utf-8'))
        job_metadata = {
            "content_id": str(content.id),
            "title": request.title,
            "file_size": content_size,
            "project_id": str(project_uuid)
        }
        if project_match_info:
            job_metadata.update({
                "ai_matched": True,
                "is_new_project": project_match_info['is_new'],
                "match_confidence": project_match_info['confidence'],
                "project_name": project_match_info['project_name']
            })

        # Trigger async processing and get RQ job ID
        rq_job_id = await ContentService.trigger_async_processing(content.id, job_metadata)

        logger.info(f"Successfully uploaded text content {content.id} for project {sanitize_for_log(project_id)}")

        # Prepare response message
        if project_match_info:
            message = f"Content uploaded and {'assigned to new' if project_match_info['is_new'] else 'matched to existing'} project: {project_match_info['project_name']}"
        else:
            message = "Content uploaded successfully and queued for processing"

        return UploadResponse(
            id=str(content.id),
            message=message,
            status="processing",
            project_id=str(project_uuid),
            content_type=request.content_type,
            title=request.title,
            uploaded_at=content.uploaded_at,
            chunk_count=0,  # Will be updated after processing
            job_id=rq_job_id  # Return RQ job ID directly
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to upload text content: {e}")
        raise HTTPException(
            status_code=500,
            detail="Failed to upload content. Please try again."
        )


@router.get("/{project_id}/content", response_model=list[ContentResponse])
async def get_project_content(
    project_id: str,
    content_type: Optional[str] = None,
    limit: int = 100,
    session: AsyncSession = Depends(get_db),
    current_org: Organization = Depends(get_current_organization),
    current_user: User = Depends(get_current_user),
    _: str = Depends(require_role("member"))
):
    """
    Get all content for a project.
    
    Optionally filter by content type (meeting/email).
    """
    try:
        # Parse project ID
        try:
            project_uuid = uuid.UUID(project_id)
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid project ID format")
        
        # Parse content type if provided
        content_type_enum = None
        if content_type:
            if content_type not in ["meeting", "email"]:
                raise HTTPException(
                    status_code=400,
                    detail="Invalid content type. Must be 'meeting' or 'email'"
                )
            content_type_enum = ContentType.MEETING if content_type == "meeting" else ContentType.EMAIL
        
        # Get content for project, ensuring it belongs to current organization
        content_list = await ContentService.get_project_content(
            session=session,
            project_id=project_uuid,
            organization_id=current_org.id,
            content_type=content_type_enum,
            limit=limit
        )
        
        # Convert to response
        return [
            ContentResponse(
                id=str(content.id),
                project_id=str(content.project_id),
                content_type=content.content_type.value,
                title=content.title,
                date=content.date,
                uploaded_at=content.uploaded_at,
                uploaded_by=content.uploaded_by,
                chunk_count=content.chunk_count,
                summary_generated=content.summary_generated,
                processed_at=content.processed_at,
                processing_error=content.processing_error
            )
            for content in content_list
        ]
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get project content: {e}")
        raise HTTPException(
            status_code=500,
            detail="Failed to retrieve content. Please try again."
        )


@router.get("/{project_id}/content/{content_id}", response_model=ContentResponse)
async def get_content_by_id(
    project_id: str,
    content_id: str,
    session: AsyncSession = Depends(get_db),
    current_org: Organization = Depends(get_current_organization),
    current_user: User = Depends(get_current_user),
    _: str = Depends(require_role("member"))
):
    """Get specific content by ID."""
    try:
        # Parse IDs
        try:
            project_uuid = uuid.UUID(project_id)
            content_uuid = uuid.UUID(content_id)
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid ID format")
        
        # Get content, ensuring it belongs to current organization
        content = await ContentService.get_content_by_id(session, content_uuid, current_org.id)
        
        if not content:
            raise HTTPException(status_code=404, detail="Content not found")
        
        # Verify content belongs to project
        if content.project_id != project_uuid:
            raise HTTPException(status_code=404, detail="Content not found")
        
        return ContentResponse(
            id=str(content.id),
            project_id=str(content.project_id),
            content_type=content.content_type.value,
            title=content.title,
            date=content.date,
            uploaded_at=content.uploaded_at,
            uploaded_by=content.uploaded_by,
            chunk_count=content.chunk_count,
            summary_generated=content.summary_generated,
            processed_at=content.processed_at,
            processing_error=content.processing_error,
            content=content.content  # Include the actual content text
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get content: {e}")
        raise HTTPException(
            status_code=500,
            detail="Failed to retrieve content. Please try again."
        )