"""
Organization Management API Router

This module provides endpoints for creating, managing, and switching between organizations
in the multi-tenant architecture.
"""

import re
import logging
from typing import List, Optional
from datetime import datetime, timezone
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status, Request, Response
from pydantic import BaseModel, Field, validator
from sqlalchemy import select, and_, or_, func
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from db.database import db_manager, get_db
from dependencies.auth import get_current_user, require_role, get_current_user_role
from models.organization import Organization
from models.organization_member import OrganizationMember, OrganizationRole
from models.user import User
from services.integrations.email_service import email_service
from utils.logger import get_logger, sanitize_for_log

logger = get_logger(__name__)

router = APIRouter(
    prefix="/api/v1/organizations",
    tags=["Organizations"]
)


# Request/Response Models

# Shared validator for role fields
def validate_organization_role(v):
    """Shared validator for organization role fields."""
    if v not in [r.value for r in OrganizationRole]:
        raise ValueError(f'Invalid role. Must be one of: {[r.value for r in OrganizationRole]}')
    return v


class CreateOrganizationRequest(BaseModel):
    """Request model for creating a new organization."""
    name: str = Field(..., min_length=1, max_length=100)
    slug: Optional[str] = Field(None, min_length=1, max_length=100)
    description: Optional[str] = Field(None, max_length=500)
    logo_url: Optional[str] = None
    settings: Optional[dict] = Field(default_factory=dict)

    @validator('slug')
    def validate_slug(cls, v, values):
        if v:
            # Ensure slug is URL-friendly
            if not re.match(r'^[a-z0-9-]+$', v):
                raise ValueError('Slug must contain only lowercase letters, numbers, and hyphens')
        return v


class UpdateOrganizationRequest(BaseModel):
    """Request model for updating an organization."""
    name: Optional[str] = Field(None, min_length=1, max_length=100)
    description: Optional[str] = Field(None, max_length=500)
    logo_url: Optional[str] = None
    settings: Optional[dict] = None


class OrganizationMemberResponse(BaseModel):
    """Response model for organization member."""
    id: str
    user_id: str
    email: str
    name: Optional[str]
    avatar_url: Optional[str]
    role: str
    joined_at: datetime
    invited_by: Optional[str] = None


class OrganizationResponse(BaseModel):
    """Response model for organization details."""
    id: str
    name: str
    slug: str
    description: Optional[str]
    logo_url: Optional[str]
    settings: dict
    is_active: bool
    created_by: Optional[str]
    created_at: datetime
    updated_at: datetime
    member_count: Optional[int] = None
    current_user_role: Optional[str] = None


class OrganizationListResponse(BaseModel):
    """Response model for organization list."""
    organizations: List[OrganizationResponse]
    total: int


class InvitationCreate(BaseModel):
    """Request model for inviting a new member."""
    email: str = Field(..., min_length=1)
    role: Optional[str] = Field(default=OrganizationRole.MEMBER.value)

    @validator('role')
    def validate_role(cls, v):
        return validate_organization_role(v)


class InvitationResponse(BaseModel):
    """Response model for invitation details."""
    id: UUID
    organization_id: UUID
    email: str
    role: str
    invitation_token: str
    invitation_sent_at: datetime
    invited_by: UUID


class RoleUpdateRequest(BaseModel):
    """Request model for updating member role."""
    role: str

    @validator('role')
    def validate_role(cls, v):
        return validate_organization_role(v)


class SwitchOrganizationResponse(BaseModel):
    """Response model for organization switching."""
    organization_id: str
    organization_name: str
    role: str
    message: str


def generate_slug(name: str, existing_slugs: set = None) -> str:
    """Generate a URL-friendly slug from organization name."""
    # Limit input length to prevent ReDoS attacks
    name = name[:200] if len(name) > 200 else name

    # Convert to lowercase and replace spaces/special chars with hyphens (ReDoS-safe)
    # Use list comprehension instead of regex to avoid polynomial time complexity
    slug_chars = [c if c.isalnum() else '-' for c in name.lower()]
    slug = ''.join(slug_chars)

    # Replace multiple consecutive hyphens with single hyphen
    while '--' in slug:
        slug = slug.replace('--', '-')

    slug = slug.strip('-')

    if not existing_slugs:
        return slug

    # Ensure uniqueness
    base_slug = slug
    counter = 1
    while slug in existing_slugs:
        slug = f"{base_slug}-{counter}"
        counter += 1

    return slug


@router.post("", response_model=OrganizationResponse, status_code=status.HTTP_201_CREATED)
async def create_organization(
    request: CreateOrganizationRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Create a new organization.

    The creating user automatically becomes the admin of the organization.

    Args:
        request: Organization creation request
        db: Database session
        current_user: Current authenticated user

    Returns:
        Created organization details

    Raises:
        HTTPException: If creation fails
    """
    try:
        # Generate slug if not provided
        if not request.slug:
            # Get existing slugs to ensure uniqueness
            result = await db.execute(select(Organization.slug))
            existing_slugs = {row[0] for row in result}
            request.slug = generate_slug(request.name, existing_slugs)

        # Check if slug is already taken
        existing = await db.execute(
            select(Organization).where(Organization.slug == request.slug)
        )
        if existing.scalar_one_or_none():
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=f"Organization with slug '{request.slug}' already exists"
            )

        # Create organization
        organization = Organization(
            name=request.name,
            slug=request.slug,
            description=request.description,
            logo_url=request.logo_url,
            settings=request.settings or {},
            created_by=current_user.id
        )
        db.add(organization)
        await db.flush()

        # Add creator as admin
        member = OrganizationMember(
            organization_id=organization.id,
            user_id=current_user.id,
            role=OrganizationRole.ADMIN.value,  # Use string value for database
            invited_by=None,  # Self-joined as creator
            joined_at=datetime.utcnow()
        )
        db.add(member)

        # Update user's last active organization
        current_user.last_active_organization_id = organization.id

        await db.commit()
        await db.refresh(organization)

        return OrganizationResponse(
            id=str(organization.id),
            name=organization.name,
            slug=organization.slug,
            description=organization.description,
            logo_url=organization.logo_url,
            settings=organization.settings,
            is_active=organization.is_active,
            created_by=str(organization.created_by) if organization.created_by else None,
            created_at=organization.created_at,
            updated_at=organization.updated_at,
            member_count=1,
            current_user_role=OrganizationRole.ADMIN.value
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error creating organization: {e}")
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to create organization"
        )


@router.get("", response_model=OrganizationListResponse)
async def list_user_organizations(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
    include_inactive: bool = False
):
    """
    List all organizations the current user belongs to.

    Args:
        db: Database session
        current_user: Current authenticated user
        include_inactive: Whether to include inactive organizations

    Returns:
        List of organizations with user's role in each
    """
    try:
        # Build query
        query = (
            select(Organization, OrganizationMember.role)
            .join(OrganizationMember, OrganizationMember.organization_id == Organization.id)
            .where(OrganizationMember.user_id == current_user.id)
        )

        if not include_inactive:
            query = query.where(Organization.is_active == True)

        query = query.order_by(Organization.created_at.desc())

        # Execute query
        result = await db.execute(query)
        organizations_with_roles = result.all()

        # Get member counts
        org_ids = [org.id for org, _ in organizations_with_roles]
        member_counts = {}
        if org_ids:
            count_result = await db.execute(
                select(
                    OrganizationMember.organization_id,
                    func.count(OrganizationMember.id).label('count')
                )
                .where(OrganizationMember.organization_id.in_(org_ids))
                .group_by(OrganizationMember.organization_id)
            )
            member_counts = {str(row[0]): row[1] for row in count_result}

        # Format response
        organizations = []
        for org, role in organizations_with_roles:
            organizations.append(OrganizationResponse(
                id=str(org.id),
                name=org.name,
                slug=org.slug,
                description=org.description,
                logo_url=org.logo_url,
                settings=org.settings,
                is_active=org.is_active,
                created_by=str(org.created_by) if org.created_by else None,
                created_at=org.created_at,
                updated_at=org.updated_at,
                member_count=member_counts.get(str(org.id), 0),
                current_user_role=role  # role is already a string
            ))

        return OrganizationListResponse(
            organizations=organizations,
            total=len(organizations)
        )

    except Exception as e:
        logger.error(f"Error listing organizations: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to list organizations"
        )


@router.get("/{organization_id}", response_model=OrganizationResponse)
async def get_organization(
    organization_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get organization details.

    User must be a member of the organization to view its details.

    Args:
        organization_id: Organization ID
        db: Database session
        current_user: Current authenticated user

    Returns:
        Organization details

    Raises:
        HTTPException: If organization not found or user not authorized
    """
    try:
        # Get organization with user's membership
        result = await db.execute(
            select(Organization, OrganizationMember)
            .join(OrganizationMember, OrganizationMember.organization_id == Organization.id)
            .where(
                and_(
                    Organization.id == organization_id,
                    OrganizationMember.user_id == current_user.id
                )
            )
            .options(selectinload(Organization.members))
        )

        row = result.first()
        if not row:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Organization not found or you don't have access"
            )

        organization, membership = row

        # Get member count
        member_count = len(organization.members)

        return OrganizationResponse(
            id=str(organization.id),
            name=organization.name,
            slug=organization.slug,
            description=organization.description,
            logo_url=organization.logo_url,
            settings=organization.settings,
            is_active=organization.is_active,
            created_by=str(organization.created_by) if organization.created_by else None,
            created_at=organization.created_at,
            updated_at=organization.updated_at,
            member_count=member_count,
            current_user_role=membership.role  # role is already a string
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting organization: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to get organization details"
        )


@router.put("/{organization_id}", response_model=OrganizationResponse)
async def update_organization(
    organization_id: UUID,
    request: UpdateOrganizationRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Update organization details.

    Only organization admins can update organization settings.

    Args:
        organization_id: Organization ID
        request: Update request
        db: Database session
        current_user: Current authenticated user

    Returns:
        Updated organization details

    Raises:
        HTTPException: If organization not found or user not authorized
    """
    try:
        # Get organization with user's membership
        result = await db.execute(
            select(Organization, OrganizationMember)
            .join(OrganizationMember, OrganizationMember.organization_id == Organization.id)
            .where(
                and_(
                    Organization.id == organization_id,
                    OrganizationMember.user_id == current_user.id
                )
            )
        )

        row = result.first()
        if not row:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Organization not found"
            )

        organization, membership = row

        # Check if user is admin
        if membership.role != OrganizationRole.ADMIN.value:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only organization admins can update settings"
            )

        # Update fields
        if request.name is not None:
            organization.name = request.name
        if request.description is not None:
            organization.description = request.description
        if request.logo_url is not None:
            organization.logo_url = request.logo_url
        if request.settings is not None:
            organization.settings = request.settings

        organization.updated_at = datetime.utcnow()

        await db.commit()
        await db.refresh(organization)

        # Get member count
        count_result = await db.execute(
            select(func.count(OrganizationMember.id))
            .where(OrganizationMember.organization_id == organization_id)
        )
        member_count = count_result.scalar()

        return OrganizationResponse(
            id=str(organization.id),
            name=organization.name,
            slug=organization.slug,
            description=organization.description,
            logo_url=organization.logo_url,
            settings=organization.settings,
            is_active=organization.is_active,
            created_by=str(organization.created_by) if organization.created_by else None,
            created_at=organization.created_at,
            updated_at=organization.updated_at,
            member_count=member_count,
            current_user_role=membership.role  # role is already a string
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error updating organization: {e}")
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to update organization"
        )


@router.delete("/{organization_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_organization(
    organization_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Delete an organization.

    Only organization admins can delete an organization. This will cascade delete
    all related data including projects, content, and vector collections.

    Args:
        organization_id: Organization ID
        db: Database session
        current_user: Current authenticated user

    Raises:
        HTTPException: If organization not found or user not authorized
    """
    try:
        # Get organization with user's membership
        result = await db.execute(
            select(Organization, OrganizationMember)
            .join(OrganizationMember, OrganizationMember.organization_id == Organization.id)
            .where(
                and_(
                    Organization.id == organization_id,
                    OrganizationMember.user_id == current_user.id
                )
            )
        )

        row = result.first()
        if not row:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Organization not found"
            )

        organization, membership = row

        # Check if user is admin
        if membership.role != OrganizationRole.ADMIN.value:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only organization admins can delete the organization"
            )

        # Check if this is the user's last active organization
        if current_user.last_active_organization_id == organization_id:
            # Find another organization for the user
            other_org = await db.execute(
                select(OrganizationMember.organization_id)
                .where(
                    and_(
                        OrganizationMember.user_id == current_user.id,
                        OrganizationMember.organization_id != organization_id
                    )
                )
                .limit(1)
            )
            other_org_id = other_org.scalar_one_or_none()
            current_user.last_active_organization_id = other_org_id

        # Delete the organization (cascade will handle related data)
        await db.delete(organization)
        await db.commit()

        # Clean up Qdrant collections for this organization
        from db.multi_tenant_vector_store import multi_tenant_vector_store
        try:
            await multi_tenant_vector_store.delete_organization_collections(str(organization_id))
            logger.info(f"Deleted Qdrant collections for organization {sanitize_for_log(organization_id)}")
        except Exception as qdrant_error:
            logger.error(f"Failed to delete Qdrant collections for organization {sanitize_for_log(organization_id)}: {qdrant_error}")
            # Continue even if Qdrant cleanup fails

        logger.info(f"Organization {sanitize_for_log(organization_id)} deleted by user {sanitize_for_log(current_user.id)}")

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error deleting organization: {e}")
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to delete organization"
        )


@router.post("/{organization_id}/switch", response_model=SwitchOrganizationResponse)
async def switch_organization(
    organization_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Switch the user's active organization.

    Updates the user's last_active_organization_id to the specified organization.
    The user must be a member of the target organization.

    Args:
        organization_id: Target organization ID
        db: Database session
        current_user: Current authenticated user

    Returns:
        Switch confirmation with organization details

    Raises:
        HTTPException: If organization not found or user not a member
    """
    try:
        # Verify user is a member of the target organization
        result = await db.execute(
            select(Organization, OrganizationMember)
            .join(OrganizationMember, OrganizationMember.organization_id == Organization.id)
            .where(
                and_(
                    Organization.id == organization_id,
                    OrganizationMember.user_id == current_user.id,
                    Organization.is_active == True
                )
            )
        )

        row = result.first()
        if not row:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Organization not found or you are not a member"
            )

        organization, membership = row

        # Update user's active organization
        current_user.last_active_organization_id = organization_id
        current_user.updated_at = datetime.utcnow()

        await db.commit()

        return SwitchOrganizationResponse(
            organization_id=str(organization.id),
            organization_name=organization.name,
            role=membership.role,  # role is already a string
            message=f"Switched to organization: {organization.name}"
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error switching organization: {e}")
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to switch organization"
        )


@router.get("/{organization_id}/members", response_model=List[OrganizationMemberResponse])
async def list_organization_members(
    organization_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    List all members of an organization.

    Any member of the organization can view the member list.

    Args:
        organization_id: Organization ID
        db: Database session
        current_user: Current authenticated user

    Returns:
        List of organization members with their roles

    Raises:
        HTTPException: If organization not found or user not authorized
    """
    try:
        # Verify user is a member
        membership_check = await db.execute(
            select(OrganizationMember)
            .where(
                and_(
                    OrganizationMember.organization_id == organization_id,
                    OrganizationMember.user_id == current_user.id
                )
            )
        )

        if not membership_check.scalar_one_or_none():
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Organization not found or you are not a member"
            )

        # Get all members with user details
        result = await db.execute(
            select(OrganizationMember, User)
            .join(User, User.id == OrganizationMember.user_id)
            .where(OrganizationMember.organization_id == organization_id)
            .order_by(OrganizationMember.joined_at.desc())
        )

        members = []
        for member, user in result:
            members.append(OrganizationMemberResponse(
                id=str(member.id),
                user_id=str(user.id),
                email=user.email,
                name=user.name,
                avatar_url=user.avatar_url,
                role=member.role,  # role is already a string
                joined_at=member.joined_at or member.updated_at,
                invited_by=str(member.invited_by) if member.invited_by else None
            ))

        return members

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error listing organization members: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to list organization members"
        )


@router.post(
    "/{organization_id}/members/invite",
    response_model=InvitationResponse,
    status_code=status.HTTP_201_CREATED
)
async def invite_member(
    organization_id: UUID,
    invitation: InvitationCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
    user_role: str = Depends(get_current_user_role)
):
    """
    Invite a new member to the organization.
    Only admins and members can invite new users.
    """
    try:
        # Check if user has permission to invite (admin or member)
        if user_role == OrganizationRole.VIEWER.value:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Viewers cannot invite new members"
            )

        # Check if organization exists
        org_query = await db.execute(
            select(Organization).where(Organization.id == organization_id)
        )
        organization = org_query.scalar_one_or_none()

        if not organization:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Organization not found"
            )

        # Check if user already exists in the system
        user_query = await db.execute(
            select(User).where(User.email == invitation.email)
        )
        existing_user = user_query.scalar_one_or_none()

        # Check if invitation or membership already exists
        if existing_user:
            # Check if user is already a member
            member_query = await db.execute(
                select(OrganizationMember).where(
                    OrganizationMember.organization_id == organization_id,
                    OrganizationMember.user_id == existing_user.id
                )
            )
            existing_member = member_query.scalar_one_or_none()
            if existing_member:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="User is already a member of this organization"
                )

        # Check if invitation already exists for this email
        invitation_query = await db.execute(
            select(OrganizationMember).where(
                OrganizationMember.organization_id == organization_id,
                OrganizationMember.invitation_email == invitation.email,
                OrganizationMember.joined_at.is_(None)
            )
        )
        existing_invitation = invitation_query.scalar_one_or_none()
        if existing_invitation:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="An invitation has already been sent to this email"
            )

        # Generate invitation token
        import secrets
        invitation_token = secrets.token_urlsafe(32)

        # Create pending invitation
        new_invitation = OrganizationMember(
            organization_id=organization_id,
            user_id=existing_user.id if existing_user else None,
            role=invitation.role if invitation.role else OrganizationRole.MEMBER.value,
            invited_by=current_user.id,
            invitation_token=invitation_token,
            invitation_email=invitation.email,  # Store the email
            invitation_sent_at=datetime.utcnow(),
            joined_at=None  # Pending invitation - not yet accepted
        )

        db.add(new_invitation)
        await db.commit()
        await db.refresh(new_invitation)

        # Send invitation email via Supabase
        email_sent = await email_service.send_invitation_email(
            invitation_email=invitation.email,
            invitation_token=invitation_token,
            organization_name=organization.name,
            inviter_name=current_user.name or current_user.email,
            role=new_invitation.role
        )

        if not email_sent:
            logger.warning(f"Failed to send invitation email to {sanitize_for_log(invitation.email)}")
            # Don't fail the request, invitation is still created

        # Return invitation details
        return InvitationResponse(
            id=new_invitation.id,
            organization_id=organization_id,
            email=invitation.email,
            role=new_invitation.role,
            invitation_token=invitation_token,
            invitation_sent_at=new_invitation.invitation_sent_at,
            invited_by=current_user.id
        )

    except HTTPException:
        raise
    except Exception as e:
        await db.rollback()
        logger.error(f"Error inviting member: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to send invitation"
        )


@router.get(
    "/{organization_id}/invitations",
    response_model=List[InvitationResponse]
)
async def list_pending_invitations(
    organization_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
    user_role: str = Depends(get_current_user_role)
):
    """
    List all pending invitations for an organization.
    Only admins and members can view invitations.
    """
    try:
        # Check if user has permission to view invitations
        if user_role == OrganizationRole.VIEWER.value:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Viewers cannot view invitations"
            )

        # Get pending invitations
        query = await db.execute(
            select(OrganizationMember)
            .where(
                OrganizationMember.organization_id == organization_id,
                OrganizationMember.invitation_token.isnot(None),
                OrganizationMember.joined_at.is_(None)
            )
            .options(selectinload(OrganizationMember.user))
        )

        invitations = query.scalars().all()

        # Convert to response model
        response = []
        for inv in invitations:
            # Get email from user if exists, otherwise from invitation_email
            email = inv.user.email if inv.user else inv.invitation_email

            response.append(InvitationResponse(
                id=inv.id,
                organization_id=organization_id,
                email=email,
                role=inv.role,
                invitation_token=inv.invitation_token,
                invitation_sent_at=inv.invitation_sent_at,
                invited_by=inv.invited_by
            ))

        return response

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error listing invitations: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to list invitations"
        )


@router.put(
    "/{organization_id}/members/{user_id}",
    response_model=OrganizationMemberResponse
)
async def update_member_role(
    organization_id: UUID,
    user_id: UUID,
    role_update: RoleUpdateRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
    user_role: str = Depends(get_current_user_role)
):
    """
    Update a member's role in the organization.
    Only admins can update member roles.
    """
    try:
        # Only admins can update roles
        if user_role != OrganizationRole.ADMIN.value:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only admins can update member roles"
            )

        # Prevent users from modifying their own role
        if user_id == current_user.id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="You cannot modify your own role"
            )

        # Get the member
        member_query = await db.execute(
            select(OrganizationMember)
            .where(
                OrganizationMember.organization_id == organization_id,
                OrganizationMember.user_id == user_id
            )
            .options(selectinload(OrganizationMember.user))
        )

        member = member_query.scalar_one_or_none()

        if not member:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Member not found in this organization"
            )

        # Update the role
        member.role = role_update.role  # Already a string value
        member.updated_at = datetime.utcnow()

        await db.commit()
        await db.refresh(member)

        return OrganizationMemberResponse(
            id=str(member.id),
            user_id=str(member.user_id),
            email=member.user.email,
            name=member.user.name,
            avatar_url=member.user.avatar_url,
            role=member.role,
            joined_at=member.joined_at or member.updated_at,
            invited_by=str(member.invited_by) if member.invited_by else None
        )

    except HTTPException:
        raise
    except Exception as e:
        await db.rollback()
        logger.error(f"Error updating member role: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to update member role"
        )


@router.delete(
    "/{organization_id}/members/{user_id}",
    status_code=status.HTTP_204_NO_CONTENT
)
async def remove_member(
    organization_id: UUID,
    user_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
    user_role: str = Depends(get_current_user_role)
):
    """
    Remove a member from the organization.
    Only admins can remove members.
    """
    try:
        # Only admins can remove members
        if user_role != OrganizationRole.ADMIN.value:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only admins can remove members"
            )

        # Prevent users from removing themselves
        if user_id == current_user.id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="You cannot remove yourself from the organization"
            )

        # Check if user is the organization creator
        org_query = await db.execute(
            select(Organization).where(Organization.id == organization_id)
        )
        organization = org_query.scalar_one_or_none()

        if organization and organization.created_by == user_id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Cannot remove the organization creator"
            )

        # Get the member
        member_query = await db.execute(
            select(OrganizationMember)
            .where(
                OrganizationMember.organization_id == organization_id,
                OrganizationMember.user_id == user_id
            )
        )

        member = member_query.scalar_one_or_none()

        if not member:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Member not found in this organization"
            )

        # If this is the user's last active organization, clear it
        user_query = await db.execute(
            select(User).where(User.id == user_id)
        )
        user = user_query.scalar_one_or_none()

        if user and user.last_active_organization_id == organization_id:
            user.last_active_organization_id = None

        # Delete the membership
        await db.delete(member)
        await db.commit()

        return Response(status_code=status.HTTP_204_NO_CONTENT)

    except HTTPException:
        raise
    except Exception as e:
        await db.rollback()
        logger.error(f"Error removing member: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to remove member"
        )