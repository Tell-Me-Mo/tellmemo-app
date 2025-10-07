"""
Invitation Management API Router

This module handles invitation acceptance flow which doesn't require organization context.
"""

import logging
from datetime import datetime
from typing import Optional
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field
from sqlalchemy import select, and_
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from db.database import db_manager, get_db
from dependencies.auth import get_current_user
from models.organization import Organization
from models.organization_member import OrganizationMember, OrganizationRole
from models.user import User
from services.auth.auth_service import AuthService
from utils.logger import get_logger

logger = get_logger(__name__)

router = APIRouter(
    prefix="/api/v1/invitations",
    tags=["Invitations"]
)


class AcceptInvitationRequest(BaseModel):
    """Request model for accepting an invitation."""
    token: str = Field(..., min_length=1)


class AcceptInvitationResponse(BaseModel):
    """Response model for successful invitation acceptance."""
    organization_id: UUID
    organization_name: str
    role: str
    message: str


class CancelInvitationResponse(BaseModel):
    """Response model for cancelled invitation."""
    message: str


@router.post(
    "/accept",
    response_model=AcceptInvitationResponse
)
async def accept_invitation(
    request: AcceptInvitationRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Accept an invitation to join an organization.
    Requires authenticated user.
    """
    try:
        # Find the invitation by token
        invitation_query = await db.execute(
            select(OrganizationMember)
            .where(
                OrganizationMember.invitation_token == request.token,
                OrganizationMember.joined_at.is_(None)  # Not yet accepted
            )
            .options(selectinload(OrganizationMember.organization))
        )

        invitation = invitation_query.scalar_one_or_none()

        if not invitation:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Invalid or expired invitation token"
            )

        # Check if invitation was meant for a specific user
        if invitation.user_id and invitation.user_id != current_user.id:
            # This invitation was for a different user
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="This invitation was sent to a different user"
            )

        # Check if user is already a member
        existing_member_query = await db.execute(
            select(OrganizationMember)
            .where(
                OrganizationMember.organization_id == invitation.organization_id,
                OrganizationMember.user_id == current_user.id,
                OrganizationMember.joined_at.isnot(None)  # Already joined
            )
        )

        existing_member = existing_member_query.scalar_one_or_none()

        if existing_member:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="You are already a member of this organization"
            )

        # Update the invitation to accept it
        invitation.user_id = current_user.id
        invitation.joined_at = datetime.utcnow()
        invitation.invitation_token = None  # Clear the token
        invitation.updated_at = datetime.utcnow()

        # Update user's last active organization if they don't have one
        if not current_user.last_active_organization_id:
            current_user.last_active_organization_id = invitation.organization_id

        await db.commit()
        await db.refresh(invitation)

        # Note: You may want to trigger a welcome notification here
        # via Supabase Edge Functions or other notification service

        return AcceptInvitationResponse(
            organization_id=invitation.organization_id,
            organization_name=invitation.organization.name,
            role=invitation.role,
            message=f"Successfully joined {invitation.organization.name} as {invitation.role}"
        )

    except HTTPException:
        raise
    except Exception as e:
        await db.rollback()
        logger.error(f"Error accepting invitation: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to accept invitation"
        )


@router.delete(
    "/{token}",
    response_model=CancelInvitationResponse
)
async def cancel_invitation(
    token: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Cancel a pending invitation.
    Only admins of the organization or the inviter can cancel.
    """
    try:
        # Find the invitation
        invitation_query = await db.execute(
            select(OrganizationMember)
            .where(
                OrganizationMember.invitation_token == token,
                OrganizationMember.joined_at.is_(None)  # Not yet accepted
            )
            .options(selectinload(OrganizationMember.organization))
        )

        invitation = invitation_query.scalar_one_or_none()

        if not invitation:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Invalid or already accepted invitation"
            )

        # Check if user has permission to cancel
        # Either the user is an admin of the organization or the one who sent the invitation
        user_member_query = await db.execute(
            select(OrganizationMember)
            .where(
                OrganizationMember.organization_id == invitation.organization_id,
                OrganizationMember.user_id == current_user.id,
                OrganizationMember.joined_at.isnot(None)
            )
        )

        user_member = user_member_query.scalar_one_or_none()

        if not user_member:
            # User is not a member of this organization
            if invitation.invited_by != current_user.id:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="You don't have permission to cancel this invitation"
                )
        elif user_member.role != OrganizationRole.ADMIN.value and invitation.invited_by != current_user.id:
            # User is a member but not admin and didn't send the invitation
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only admins or the inviter can cancel invitations"
            )

        # Delete the invitation
        await db.delete(invitation)
        await db.commit()

        return CancelInvitationResponse(
            message=f"Invitation to {invitation.organization.name} has been cancelled"
        )

    except HTTPException:
        raise
    except Exception as e:
        await db.rollback()
        logger.error(f"Error cancelling invitation: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to cancel invitation"
        )