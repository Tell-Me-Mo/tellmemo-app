"""Conversations API router for managing chat sessions."""

from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from typing import List, Optional, Dict, Any
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_, desc, update
from datetime import datetime
import uuid

from db.database import get_db
from dependencies.auth import get_current_organization, get_current_user, require_role
from models.conversation import Conversation
from models.organization import Organization
from models.user import User
from models.project import Project
from utils.logger import get_logger, sanitize_for_log

router = APIRouter()
logger = get_logger(__name__)


class MessageModel(BaseModel):
    question: str
    answer: str
    sources: List[str]
    confidence: float
    timestamp: str
    isAnswerPending: bool = False


class ConversationCreateRequest(BaseModel):
    title: str
    messages: List[MessageModel] = []


class ConversationUpdateRequest(BaseModel):
    title: Optional[str] = None
    messages: Optional[List[MessageModel]] = None


class ConversationResponse(BaseModel):
    id: str
    project_id: str
    title: str
    messages: List[Dict[str, Any]]
    created_at: str
    last_accessed_at: str


@router.get("/{project_id}/conversations", response_model=List[ConversationResponse])
async def get_conversations(
    project_id: str,
    session: AsyncSession = Depends(get_db),
    current_org: Organization = Depends(get_current_organization),
    current_user: User = Depends(get_current_user),
    _: str = Depends(require_role("member"))
):
    """
    Get all conversations for an entity (project, program, portfolio, or organization).

    Args:
        project_id: UUID of the entity or 'organization' for org-level conversations
        session: Database session

    Returns:
        List of conversations for the entity
    """
    logger.info(f"Getting conversations for entity {sanitize_for_log(project_id)}")

    try:
        # Handle organization-level conversations
        if project_id == 'organization':
            result = await session.execute(
                select(Conversation)
                .where(
                    and_(
                        Conversation.project_id.is_(None),  # Organization-level conversations have NULL project_id
                        Conversation.organization_id == current_org.id
                    )
                )
                .order_by(desc(Conversation.last_accessed_at))
            )
        else:
            # Get conversations directly by entity ID (no entity type validation needed)
            # The entity ID could be a project, program, or portfolio
            result = await session.execute(
                select(Conversation)
                .where(
                    and_(
                        Conversation.project_id == project_id,
                        Conversation.organization_id == current_org.id
                    )
                )
                .order_by(desc(Conversation.last_accessed_at))
            )
        conversations = result.scalars().all()

        return [
            ConversationResponse(
                id=str(conversation.id),
                project_id=str(conversation.project_id) if conversation.project_id else 'organization',
                title=conversation.title,
                messages=conversation.messages,
                created_at=conversation.created_at.isoformat(),
                last_accessed_at=conversation.last_accessed_at.isoformat()
            )
            for conversation in conversations
        ]

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get conversations for entity {sanitize_for_log(project_id)}: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/{project_id}/conversations", response_model=ConversationResponse)
async def create_conversation(
    project_id: str,
    request: ConversationCreateRequest,
    session: AsyncSession = Depends(get_db),
    current_org: Organization = Depends(get_current_organization),
    current_user: User = Depends(get_current_user),
    _: str = Depends(require_role("member"))
):
    """
    Create a new conversation for an entity (project, program, or portfolio).

    Args:
        project_id: UUID of the entity (can be project, program, or portfolio ID)
        request: Conversation creation request
        session: Database session

    Returns:
        Created conversation
    """
    logger.info(f"Creating conversation for entity {sanitize_for_log(project_id)}: {sanitize_for_log(request.title)}")

    try:
        # Create conversation (handle organization-level conversations)
        conversation = Conversation(
            project_id=None if project_id == 'organization' else uuid.UUID(project_id),
            organization_id=current_org.id,
            title=request.title,
            messages=[msg.model_dump() for msg in request.messages],
            created_by=current_user.email or "unknown",
            created_at=datetime.utcnow(),
            last_accessed_at=datetime.utcnow()
        )

        session.add(conversation)
        await session.commit()
        await session.refresh(conversation)

        return ConversationResponse(
            id=str(conversation.id),
            project_id=str(conversation.project_id) if conversation.project_id else 'organization',
            title=conversation.title,
            messages=conversation.messages,
            created_at=conversation.created_at.isoformat(),
            last_accessed_at=conversation.last_accessed_at.isoformat()
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to create conversation for entity {sanitize_for_log(project_id)}: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.put("/{project_id}/conversations/{conversation_id}", response_model=ConversationResponse)
async def update_conversation(
    project_id: str,
    conversation_id: str,
    request: ConversationUpdateRequest,
    session: AsyncSession = Depends(get_db),
    current_org: Organization = Depends(get_current_organization),
    current_user: User = Depends(get_current_user),
    _: str = Depends(require_role("member"))
):
    """
    Update an existing conversation.

    Args:
        project_id: UUID of the project
        conversation_id: UUID of the conversation
        request: Conversation update request
        session: Database session

    Returns:
        Updated conversation
    """
    logger.info(f"Updating conversation {sanitize_for_log(conversation_id)} for project {sanitize_for_log(project_id)}")

    try:
        # Verify conversation exists and belongs to the project and organization
        if project_id == 'organization':
            # Organization-level conversation
            result = await session.execute(
                select(Conversation).where(
                    and_(
                        Conversation.id == conversation_id,
                        Conversation.project_id.is_(None),
                        Conversation.organization_id == current_org.id
                    )
                )
            )
        else:
            # Entity-specific conversation
            result = await session.execute(
                select(Conversation).where(
                    and_(
                        Conversation.id == conversation_id,
                        Conversation.project_id == project_id,
                        Conversation.organization_id == current_org.id
                    )
                )
            )
        conversation = result.scalar_one_or_none()

        if not conversation:
            raise HTTPException(status_code=404, detail=f"Conversation {conversation_id} not found")

        # Update fields
        update_data = {"last_accessed_at": datetime.utcnow()}

        if request.title is not None:
            update_data["title"] = request.title

        if request.messages is not None:
            update_data["messages"] = [msg.model_dump() for msg in request.messages]

        # Update conversation
        await session.execute(
            update(Conversation)
            .where(Conversation.id == conversation_id)
            .values(**update_data)
        )
        await session.commit()

        # Refresh conversation
        await session.refresh(conversation)

        return ConversationResponse(
            id=str(conversation.id),
            project_id=str(conversation.project_id) if conversation.project_id else 'organization',
            title=conversation.title,
            messages=conversation.messages,
            created_at=conversation.created_at.isoformat(),
            last_accessed_at=conversation.last_accessed_at.isoformat()
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to update conversation {sanitize_for_log(conversation_id)}: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.delete("/{project_id}/conversations/{conversation_id}")
async def delete_conversation(
    project_id: str,
    conversation_id: str,
    session: AsyncSession = Depends(get_db),
    current_org: Organization = Depends(get_current_organization),
    current_user: User = Depends(get_current_user),
    _: str = Depends(require_role("member"))
):
    """
    Delete a conversation.

    Args:
        project_id: UUID of the project
        conversation_id: UUID of the conversation
        session: Database session

    Returns:
        Success message
    """
    logger.info(f"Deleting conversation {sanitize_for_log(conversation_id)} for project {sanitize_for_log(project_id)}")

    try:
        # Verify conversation exists and belongs to the project/organization
        if project_id == 'organization':
            # Organization-level conversation
            result = await session.execute(
                select(Conversation).where(
                    and_(
                        Conversation.id == conversation_id,
                        Conversation.project_id.is_(None),
                        Conversation.organization_id == current_org.id
                    )
                )
            )
        else:
            # Entity-specific conversation
            result = await session.execute(
                select(Conversation).where(
                    and_(
                        Conversation.id == conversation_id,
                        Conversation.project_id == project_id,
                        Conversation.organization_id == current_org.id
                    )
                )
            )
        conversation = result.scalar_one_or_none()

        if not conversation:
            raise HTTPException(status_code=404, detail=f"Conversation {conversation_id} not found")

        # Delete conversation
        await session.delete(conversation)
        await session.commit()

        return {"message": "Conversation deleted successfully"}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to delete conversation {sanitize_for_log(conversation_id)}: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/{project_id}/conversations/{conversation_id}", response_model=ConversationResponse)
async def get_conversation(
    project_id: str,
    conversation_id: str,
    session: AsyncSession = Depends(get_db),
    current_org: Organization = Depends(get_current_organization),
    current_user: User = Depends(get_current_user),
    _: str = Depends(require_role("member"))
):
    """
    Get a specific conversation.

    Args:
        project_id: UUID of the project
        conversation_id: UUID of the conversation
        session: Database session

    Returns:
        Conversation details
    """
    logger.info(f"Getting conversation {sanitize_for_log(conversation_id)} for project {sanitize_for_log(project_id)}")

    try:
        # Get conversation and update last accessed time
        if project_id == 'organization':
            # Organization-level conversation
            result = await session.execute(
                select(Conversation).where(
                    and_(
                        Conversation.id == conversation_id,
                        Conversation.project_id.is_(None),
                        Conversation.organization_id == current_org.id
                    )
                )
            )
        else:
            # Entity-specific conversation
            result = await session.execute(
                select(Conversation).where(
                    and_(
                        Conversation.id == conversation_id,
                        Conversation.project_id == project_id,
                        Conversation.organization_id == current_org.id
                    )
                )
            )
        conversation = result.scalar_one_or_none()

        if not conversation:
            raise HTTPException(status_code=404, detail=f"Conversation {conversation_id} not found")

        # Update last accessed time
        await session.execute(
            update(Conversation)
            .where(Conversation.id == conversation_id)
            .values(last_accessed_at=datetime.utcnow())
        )
        await session.commit()
        await session.refresh(conversation)

        return ConversationResponse(
            id=str(conversation.id),
            project_id=str(conversation.project_id) if conversation.project_id else 'organization',
            title=conversation.title,
            messages=conversation.messages,
            created_at=conversation.created_at.isoformat(),
            last_accessed_at=conversation.last_accessed_at.isoformat()
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get conversation {sanitize_for_log(conversation_id)}: {e}")
        raise HTTPException(status_code=500, detail=str(e))