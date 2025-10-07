"""Support ticket router."""
from typing import List, Optional
from datetime import datetime
from pathlib import Path
from fastapi import APIRouter, Depends, HTTPException, Query, UploadFile, File
from fastapi.responses import FileResponse
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_, or_, desc, asc
from sqlalchemy.orm import selectinload
from pydantic import BaseModel, Field
import uuid
import aiofiles
import asyncio

from db.database import get_db
from models.support_ticket import SupportTicket, TicketComment, TicketAttachment
from models.user import User
from models.organization import Organization
from dependencies.auth import get_current_organization
from dependencies.auth import get_current_user
from .websocket_tickets import broadcast_ticket_created, broadcast_ticket_status_changed
from services.notifications.ticket_notification_service import ticket_notification_service


router = APIRouter(prefix="/api/v1/support-tickets", tags=["Support Tickets"])


# Pydantic models for request/response
class TicketCreateRequest(BaseModel):
    """Request model for creating a ticket."""
    title: str = Field(..., min_length=1, max_length=255)
    description: str = Field(..., min_length=1)
    type: str = Field(..., pattern="^(bug_report|feature_request|general_support|documentation)$")
    priority: str = Field(..., pattern="^(low|medium|high|critical)$")


class TicketUpdateRequest(BaseModel):
    """Request model for updating a ticket."""
    title: Optional[str] = Field(None, min_length=1, max_length=255)
    description: Optional[str] = Field(None, min_length=1)
    type: Optional[str] = Field(None, pattern="^(bug_report|feature_request|general_support|documentation)$")
    priority: Optional[str] = Field(None, pattern="^(low|medium|high|critical)$")
    status: Optional[str] = Field(None, pattern="^(open|in_progress|waiting_for_user|resolved|closed)$")
    assigned_to: Optional[uuid.UUID] = None
    resolution_notes: Optional[str] = None


class CommentCreateRequest(BaseModel):
    """Request model for creating a comment."""
    comment: str = Field(..., min_length=1)
    is_internal: bool = False


class TicketResponse(BaseModel):
    """Response model for a ticket."""
    id: uuid.UUID
    title: str
    description: str
    type: str
    priority: str
    status: str
    created_by: uuid.UUID
    creator_name: Optional[str]
    creator_email: str
    assigned_to: Optional[uuid.UUID]
    assignee_name: Optional[str]
    assignee_email: Optional[str]
    resolved_at: Optional[datetime]
    resolution_notes: Optional[str]
    created_at: datetime
    updated_at: datetime
    comment_count: int
    attachment_count: int
    last_comment: Optional[dict]

    class Config:
        from_attributes = True


class CommentResponse(BaseModel):
    """Response model for a comment."""
    id: uuid.UUID
    ticket_id: uuid.UUID
    user_id: uuid.UUID
    user_name: Optional[str]
    user_email: str
    comment: str
    is_internal: bool
    is_system_message: bool
    created_at: datetime
    attachments: List[dict]

    class Config:
        from_attributes = True


@router.post("/", response_model=TicketResponse)
async def create_ticket(
    request: TicketCreateRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
    organization: Organization = Depends(get_current_organization)
) -> TicketResponse:
    """Create a new support ticket."""
    try:
        # Create the ticket
        ticket = SupportTicket(
            organization_id=organization.id,
            title=request.title,
            description=request.description,
            type=request.type,
            priority=request.priority,
            status="open",
            created_by=current_user.id
        )

        db.add(ticket)
        await db.commit()
        await db.refresh(ticket)

        # Load relationships
        await db.refresh(ticket, ["creator", "comments", "attachments"])

        # Build response for client
        response = TicketResponse(
            id=ticket.id,
            title=ticket.title,
            description=ticket.description,
            type=ticket.type,
            priority=ticket.priority,
            status=ticket.status,
            created_by=ticket.created_by,
            creator_name=ticket.creator.name,
            creator_email=ticket.creator.email,
            assigned_to=ticket.assigned_to,
            assignee_name=None,
            assignee_email=None,
            resolved_at=ticket.resolved_at,
            resolution_notes=ticket.resolution_notes,
            created_at=ticket.created_at,
            updated_at=ticket.updated_at,
            comment_count=0,
            attachment_count=0,
            last_comment=None
        )

        # Broadcast to all users in organization
        await broadcast_ticket_created(
            str(organization.id),
            response.dict()
        )

        # Send email notifications
        asyncio.create_task(
            ticket_notification_service.notify_ticket_created(
                ticket, current_user, organization, db
            )
        )

        return response
    except Exception as e:
        await db.rollback()
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/", response_model=List[TicketResponse])
async def list_tickets(
    status: Optional[str] = Query(None, pattern="^(open|in_progress|waiting_for_user|resolved|closed)$"),
    priority: Optional[str] = Query(None, pattern="^(low|medium|high|critical)$"),
    type: Optional[str] = Query(None, pattern="^(bug_report|feature_request|general_support|documentation)$"),
    assigned_to_me: bool = False,
    created_by_me: bool = False,
    sort_by: str = Query("created_at", pattern="^(created_at|updated_at|priority|status)$"),
    sort_order: str = Query("desc", pattern="^(asc|desc)$"),
    limit: int = Query(50, ge=1, le=100),
    offset: int = Query(0, ge=0),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
    organization: Organization = Depends(get_current_organization)
) -> List[TicketResponse]:
    """List tickets with filters."""
    try:
        # Build query
        query = select(SupportTicket).where(
            SupportTicket.organization_id == organization.id
        ).options(
            selectinload(SupportTicket.creator),
            selectinload(SupportTicket.assignee),
            selectinload(SupportTicket.comments).selectinload(TicketComment.user),
            selectinload(SupportTicket.attachments)
        )

        # Apply filters
        if status:
            query = query.where(SupportTicket.status == status)
        if priority:
            query = query.where(SupportTicket.priority == priority)
        if type:
            query = query.where(SupportTicket.type == type)
        if assigned_to_me:
            query = query.where(SupportTicket.assigned_to == current_user.id)
        if created_by_me:
            query = query.where(SupportTicket.created_by == current_user.id)

        # Apply sorting
        order_column = getattr(SupportTicket, sort_by)
        if sort_order == "desc":
            query = query.order_by(desc(order_column))
        else:
            query = query.order_by(asc(order_column))

        # Apply pagination
        query = query.limit(limit).offset(offset)

        # Execute query
        result = await db.execute(query)
        tickets = result.scalars().all()

        # Build responses
        responses = []
        for ticket in tickets:
            # Get last comment
            last_comment = None
            if ticket.comments:
                sorted_comments = sorted(ticket.comments, key=lambda x: x.created_at, reverse=True)
                last_comment_obj = sorted_comments[0]
                last_comment = {
                    "id": str(last_comment_obj.id),
                    "user_name": last_comment_obj.user.name,
                    "user_email": last_comment_obj.user.email,
                    "comment": last_comment_obj.comment[:100] + "..." if len(last_comment_obj.comment) > 100 else last_comment_obj.comment,
                    "created_at": last_comment_obj.created_at.isoformat()
                }

            responses.append(TicketResponse(
                id=ticket.id,
                title=ticket.title,
                description=ticket.description,
                type=ticket.type,
                priority=ticket.priority,
                status=ticket.status,
                created_by=ticket.created_by,
                creator_name=ticket.creator.name,
                creator_email=ticket.creator.email,
                assigned_to=ticket.assigned_to,
                assignee_name=ticket.assignee.name if ticket.assignee else None,
                assignee_email=ticket.assignee.email if ticket.assignee else None,
                resolved_at=ticket.resolved_at,
                resolution_notes=ticket.resolution_notes,
                created_at=ticket.created_at,
                updated_at=ticket.updated_at,
                comment_count=len(ticket.comments),
                attachment_count=len(ticket.attachments),
                last_comment=last_comment
            ))

        return responses
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/{ticket_id}", response_model=TicketResponse)
async def get_ticket(
    ticket_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
    organization: Organization = Depends(get_current_organization)
) -> TicketResponse:
    """Get a specific ticket."""
    try:
        # Get ticket with relationships
        query = select(SupportTicket).where(
            and_(
                SupportTicket.id == ticket_id,
                SupportTicket.organization_id == organization.id
            )
        ).options(
            selectinload(SupportTicket.creator),
            selectinload(SupportTicket.assignee),
            selectinload(SupportTicket.comments).selectinload(TicketComment.user),
            selectinload(SupportTicket.attachments)
        )

        result = await db.execute(query)
        ticket = result.scalar_one_or_none()

        if not ticket:
            raise HTTPException(status_code=404, detail="Ticket not found")

        # Get last comment
        last_comment = None
        if ticket.comments:
            sorted_comments = sorted(ticket.comments, key=lambda x: x.created_at, reverse=True)
            last_comment_obj = sorted_comments[0]
            last_comment = {
                "id": str(last_comment_obj.id),
                "user_name": last_comment_obj.user.name,
                "user_email": last_comment_obj.user.email,
                "comment": last_comment_obj.comment,
                "created_at": last_comment_obj.created_at.isoformat()
            }

        return TicketResponse(
            id=ticket.id,
            title=ticket.title,
            description=ticket.description,
            type=ticket.type,
            priority=ticket.priority,
            status=ticket.status,
            created_by=ticket.created_by,
            creator_name=ticket.creator.name,
            creator_email=ticket.creator.email,
            assigned_to=ticket.assigned_to,
            assignee_name=ticket.assignee.name if ticket.assignee else None,
            assignee_email=ticket.assignee.email if ticket.assignee else None,
            resolved_at=ticket.resolved_at,
            resolution_notes=ticket.resolution_notes,
            created_at=ticket.created_at,
            updated_at=ticket.updated_at,
            comment_count=len(ticket.comments),
            attachment_count=len(ticket.attachments),
            last_comment=last_comment
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.patch("/{ticket_id}", response_model=TicketResponse)
async def update_ticket(
    ticket_id: uuid.UUID,
    request: TicketUpdateRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
    organization: Organization = Depends(get_current_organization)
) -> TicketResponse:
    """Update a ticket."""
    try:
        # Get ticket
        query = select(SupportTicket).where(
            and_(
                SupportTicket.id == ticket_id,
                SupportTicket.organization_id == organization.id
            )
        )

        result = await db.execute(query)
        ticket = result.scalar_one_or_none()

        if not ticket:
            raise HTTPException(status_code=404, detail="Ticket not found")

        # Track status change for notifications
        old_status = ticket.status
        old_assignee = ticket.assigned_to

        # Update fields
        update_data = request.dict(exclude_unset=True)
        for field, value in update_data.items():
            setattr(ticket, field, value)

        # Update resolved_at if status changed to resolved/closed
        if request.status in ["resolved", "closed"] and not ticket.resolved_at:
            ticket.resolved_at = datetime.utcnow()

        ticket.updated_at = datetime.utcnow()

        await db.commit()
        await db.refresh(ticket)

        # Load relationships
        await db.refresh(ticket, ["creator", "assignee", "comments", "attachments"])

        # Get last comment
        last_comment = None
        if ticket.comments:
            sorted_comments = sorted(ticket.comments, key=lambda x: x.created_at, reverse=True)
            last_comment_obj = sorted_comments[0]
            await db.refresh(last_comment_obj, ["user"])
            last_comment = {
                "id": str(last_comment_obj.id),
                "user_name": last_comment_obj.user.name,
                "user_email": last_comment_obj.user.email,
                "comment": last_comment_obj.comment[:100] + "..." if len(last_comment_obj.comment) > 100 else last_comment_obj.comment,
                "created_at": last_comment_obj.created_at.isoformat()
            }

        # Send notifications for status change
        if request.status and old_status != ticket.status:
            await broadcast_ticket_status_changed(
                str(organization.id),
                str(ticket.id),
                old_status,
                ticket.status,
                str(current_user.id)
            )
            asyncio.create_task(
                ticket_notification_service.notify_status_changed(
                    ticket, old_status, ticket.status, current_user, organization, db
                )
            )

        # Send notification for assignment
        if request.assigned_to and old_assignee != ticket.assigned_to and ticket.assignee:
            asyncio.create_task(
                ticket_notification_service.notify_ticket_assigned(
                    ticket, ticket.assignee, current_user, organization, db
                )
            )

        return TicketResponse(
            id=ticket.id,
            title=ticket.title,
            description=ticket.description,
            type=ticket.type,
            priority=ticket.priority,
            status=ticket.status,
            created_by=ticket.created_by,
            creator_name=ticket.creator.name,
            creator_email=ticket.creator.email,
            assigned_to=ticket.assigned_to,
            assignee_name=ticket.assignee.name if ticket.assignee else None,
            assignee_email=ticket.assignee.email if ticket.assignee else None,
            resolved_at=ticket.resolved_at,
            resolution_notes=ticket.resolution_notes,
            created_at=ticket.created_at,
            updated_at=ticket.updated_at,
            comment_count=len(ticket.comments),
            attachment_count=len(ticket.attachments),
            last_comment=last_comment
        )
    except HTTPException:
        raise
    except Exception as e:
        await db.rollback()
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/{ticket_id}/comments", response_model=CommentResponse)
async def add_comment(
    ticket_id: uuid.UUID,
    request: CommentCreateRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
    organization: Organization = Depends(get_current_organization)
) -> CommentResponse:
    """Add a comment to a ticket."""
    try:
        # Check if ticket exists
        query = select(SupportTicket).where(
            and_(
                SupportTicket.id == ticket_id,
                SupportTicket.organization_id == organization.id
            )
        )

        result = await db.execute(query)
        ticket = result.scalar_one_or_none()

        if not ticket:
            raise HTTPException(status_code=404, detail="Ticket not found")

        # Create comment
        comment = TicketComment(
            ticket_id=ticket_id,
            user_id=current_user.id,
            comment=request.comment,
            is_internal=request.is_internal
        )

        db.add(comment)

        # Update ticket's updated_at
        ticket.updated_at = datetime.utcnow()

        await db.commit()
        await db.refresh(comment)
        await db.refresh(comment, ["user", "attachments"])

        return CommentResponse(
            id=comment.id,
            ticket_id=comment.ticket_id,
            user_id=comment.user_id,
            user_name=comment.user.name,
            user_email=comment.user.email,
            comment=comment.comment,
            is_internal=comment.is_internal,
            is_system_message=comment.is_system_message,
            created_at=comment.created_at,
            attachments=[]
        )
    except HTTPException:
        raise
    except Exception as e:
        await db.rollback()
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/{ticket_id}/comments", response_model=List[CommentResponse])
async def get_comments(
    ticket_id: uuid.UUID,
    include_internal: bool = False,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
    organization: Organization = Depends(get_current_organization)
) -> List[CommentResponse]:
    """Get comments for a ticket."""
    try:
        # Check if ticket exists
        ticket_query = select(SupportTicket).where(
            and_(
                SupportTicket.id == ticket_id,
                SupportTicket.organization_id == organization.id
            )
        )

        result = await db.execute(ticket_query)
        ticket = result.scalar_one_or_none()

        if not ticket:
            raise HTTPException(status_code=404, detail="Ticket not found")

        # Build comment query
        query = select(TicketComment).where(
            TicketComment.ticket_id == ticket_id
        ).options(
            selectinload(TicketComment.user),
            selectinload(TicketComment.attachments)
        ).order_by(asc(TicketComment.created_at))

        # Filter internal comments if not requested
        if not include_internal:
            query = query.where(TicketComment.is_internal == False)

        result = await db.execute(query)
        comments = result.scalars().all()

        # Build responses
        responses = []
        for comment in comments:
            attachments = [
                {
                    "id": str(attachment.id),
                    "file_name": attachment.file_name,
                    "file_url": attachment.file_url,
                    "file_type": attachment.file_type,
                    "file_size": attachment.file_size
                }
                for attachment in comment.attachments
            ]

            responses.append(CommentResponse(
                id=comment.id,
                ticket_id=comment.ticket_id,
                user_id=comment.user_id,
                user_name=comment.user.name,
                user_email=comment.user.email,
                comment=comment.comment,
                is_internal=comment.is_internal,
                is_system_message=comment.is_system_message,
                created_at=comment.created_at,
                attachments=attachments
            ))

        return responses
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.delete("/{ticket_id}")
async def delete_ticket(
    ticket_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
    organization: Organization = Depends(get_current_organization)
) -> dict:
    """Delete a ticket (admin only)."""
    try:
        # Get ticket
        query = select(SupportTicket).where(
            and_(
                SupportTicket.id == ticket_id,
                SupportTicket.organization_id == organization.id
            )
        )

        result = await db.execute(query)
        ticket = result.scalar_one_or_none()

        if not ticket:
            raise HTTPException(status_code=404, detail="Ticket not found")

        # Only creator or admin can delete
        if ticket.created_by != current_user.id:
            # Check if user is admin
            # For now, we'll allow only the creator
            raise HTTPException(status_code=403, detail="Only ticket creator can delete")

        await db.delete(ticket)
        await db.commit()

        return {"message": "Ticket deleted successfully"}
    except HTTPException:
        raise
    except Exception as e:
        await db.rollback()
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/{ticket_id}/attachments")
async def upload_attachment(
    ticket_id: uuid.UUID,
    file: UploadFile = File(...),
    comment_id: Optional[uuid.UUID] = None,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
    organization: Organization = Depends(get_current_organization)
) -> dict:
    """Upload an attachment to a ticket or comment."""
    import os
    import aiofiles
    from pathlib import Path

    try:
        # Check if ticket exists
        query = select(SupportTicket).where(
            and_(
                SupportTicket.id == ticket_id,
                SupportTicket.organization_id == organization.id
            )
        )

        result = await db.execute(query)
        ticket = result.scalar_one_or_none()

        if not ticket:
            raise HTTPException(status_code=404, detail="Ticket not found")

        # If comment_id is provided, verify it exists
        if comment_id:
            comment_query = select(TicketComment).where(
                and_(
                    TicketComment.id == comment_id,
                    TicketComment.ticket_id == ticket_id
                )
            )
            comment_result = await db.execute(comment_query)
            if not comment_result.scalar_one_or_none():
                raise HTTPException(status_code=404, detail="Comment not found")

        # Create upload directory if it doesn't exist
        # Validate base directory exists and is safe
        base_upload_dir = Path("uploads").resolve()
        upload_dir = (base_upload_dir / "support_tickets" / str(organization.id) / str(ticket_id)).resolve()

        # Ensure the resolved path is within the base upload directory (prevent path traversal)
        if not str(upload_dir).startswith(str(base_upload_dir)):
            raise HTTPException(status_code=400, detail="Invalid upload path")

        upload_dir.mkdir(parents=True, exist_ok=True)

        # Generate unique filename - sanitize the extension to prevent directory traversal
        file_extension = Path(file.filename).suffix
        # Only allow alphanumeric and common file extensions
        if not file_extension or not file_extension.replace('.', '').isalnum():
            file_extension = '.bin'  # Default extension for unknown types

        unique_filename = f"{uuid.uuid4()}{file_extension}"
        file_path = (upload_dir / unique_filename).resolve()

        # Final validation: ensure file_path is within upload_dir
        if not str(file_path).startswith(str(upload_dir)):
            raise HTTPException(status_code=400, detail="Invalid file path")

        # Save file
        async with aiofiles.open(file_path, 'wb') as f:
            content = await file.read()
            await f.write(content)

        # Create attachment record
        attachment = TicketAttachment(
            ticket_id=ticket_id,
            comment_id=comment_id,
            file_name=file.filename,
            file_url=str(file_path),
            file_type=file.content_type,
            file_size=len(content),
            uploaded_by=current_user.id
        )

        db.add(attachment)

        # Update ticket's updated_at
        ticket.updated_at = datetime.utcnow()

        # Add system comment for attachment
        if not comment_id:
            system_comment = TicketComment(
                ticket_id=ticket_id,
                user_id=current_user.id,
                comment=f"Attached file: {file.filename}",
                is_system_message=True
            )
            db.add(system_comment)

        await db.commit()
        await db.refresh(attachment)

        return {
            "id": str(attachment.id),
            "file_name": attachment.file_name,
            "file_url": attachment.file_url,
            "file_type": attachment.file_type,
            "file_size": attachment.file_size,
            "created_at": attachment.created_at.isoformat()
        }
    except HTTPException:
        raise
    except Exception as e:
        await db.rollback()
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/{ticket_id}/attachments/{attachment_id}")
async def download_attachment(
    ticket_id: uuid.UUID,
    attachment_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
    organization: Organization = Depends(get_current_organization)
):
    """Download a ticket attachment."""
    from fastapi.responses import FileResponse

    try:
        # Get attachment
        query = select(TicketAttachment).where(
            and_(
                TicketAttachment.id == attachment_id,
                TicketAttachment.ticket_id == ticket_id
            )
        ).options(selectinload(TicketAttachment.ticket))

        result = await db.execute(query)
        attachment = result.scalar_one_or_none()

        if not attachment:
            raise HTTPException(status_code=404, detail="Attachment not found")

        # Verify organization access
        if attachment.ticket.organization_id != organization.id:
            raise HTTPException(status_code=403, detail="Access denied")

        # Return file with path validation
        base_upload_dir = Path("uploads").resolve()
        file_path = Path(attachment.file_url).resolve()

        # Ensure the file path is within the base upload directory (prevent path traversal)
        if not str(file_path).startswith(str(base_upload_dir)):
            logger.error(f"Path traversal attempt detected: {attachment.file_url}")
            raise HTTPException(status_code=403, detail="Access denied")

        if not file_path.exists():
            raise HTTPException(status_code=404, detail="File not found on disk")

        return FileResponse(
            path=str(file_path),
            media_type=attachment.file_type or 'application/octet-stream',
            filename=attachment.file_name
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))