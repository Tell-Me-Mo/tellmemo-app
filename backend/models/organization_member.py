"""Organization member junction table for user-organization relationships."""

import uuid
from datetime import datetime
from enum import Enum
from typing import TYPE_CHECKING
from sqlalchemy import Column, String, DateTime, ForeignKey, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID, ENUM
from sqlalchemy.orm import relationship

from db.database import Base

if TYPE_CHECKING:
    from models.user import User
    from models.organization import Organization


class OrganizationRole(str, Enum):
    """Organization member roles."""
    ADMIN = "admin"
    MEMBER = "member"
    VIEWER = "viewer"


class OrganizationMember(Base):
    """Junction table for users and organizations with roles."""

    __tablename__ = "organization_members"
    __table_args__ = (
        UniqueConstraint('organization_id', 'user_id', name='uq_organization_user'),
    )

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)

    # Foreign keys
    organization_id = Column(UUID(as_uuid=True), ForeignKey("organizations.id", ondelete="CASCADE"), nullable=False)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=True)  # Nullable for pending invitations

    # Role - Use string enum values for PostgreSQL compatibility
    role = Column(
        ENUM('admin', 'member', 'viewer', name='organizationrole'),
        nullable=False,
        default='member'
    )

    # Invitation tracking
    invited_by = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    invitation_token = Column(String, nullable=True, unique=True)  # For pending invitations
    invitation_email = Column(String(255), nullable=True)  # Email for pending invitations
    invitation_sent_at = Column(DateTime, nullable=True)

    # Timestamps
    joined_at = Column(DateTime, nullable=True)  # Nullable for pending invitations, set explicitly when member joins
    updated_at = Column(DateTime, nullable=False, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    organization = relationship("Organization", back_populates="members")
    user = relationship("User", back_populates="organization_memberships", foreign_keys=[user_id])
    inviter = relationship("User", foreign_keys=[invited_by])

    def to_dict(self):
        """Convert organization member to dictionary."""
        return {
            "id": str(self.id),
            "organization_id": str(self.organization_id),
            "user_id": str(self.user_id),
            "role": self.role.value,
            "invited_by": str(self.invited_by) if self.invited_by else None,
            "invitation_token": self.invitation_token,
            "invitation_sent_at": self.invitation_sent_at.isoformat() if self.invitation_sent_at else None,
            "joined_at": self.joined_at.isoformat(),
            "updated_at": self.updated_at.isoformat(),
        }