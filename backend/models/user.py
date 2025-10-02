"""User model for authentication and multi-tenant support."""

import uuid
from datetime import datetime
from typing import Optional, List, TYPE_CHECKING
from sqlalchemy import Column, String, DateTime, Boolean, JSON
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from db.database import Base

if TYPE_CHECKING:
    from models.organization_member import OrganizationMember


class User(Base):
    """Model for authenticated users."""

    __tablename__ = "users"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)

    # Supabase auth fields
    supabase_id = Column(String, nullable=False, unique=True)  # Maps to Supabase Auth UID
    email = Column(String, nullable=False, unique=True)

    # Profile fields
    name = Column(String, nullable=True)
    avatar_url = Column(String, nullable=True)

    # Settings and preferences
    preferences = Column(JSON, default=dict)  # User preferences and settings
    last_active_organization_id = Column(UUID(as_uuid=True), nullable=True)  # Last accessed organization

    # Status
    is_active = Column(Boolean, default=True)
    email_verified = Column(Boolean, default=False)

    # Timestamps
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)
    updated_at = Column(DateTime, nullable=False, default=datetime.utcnow, onupdate=datetime.utcnow)
    last_login_at = Column(DateTime, nullable=True)

    # Relationships
    organization_memberships = relationship(
        "OrganizationMember",
        back_populates="user",
        cascade="all, delete-orphan",
        foreign_keys="OrganizationMember.user_id"
    )

    notifications = relationship(
        "Notification",
        back_populates="user",
        cascade="all, delete-orphan"
    )

    # Support ticket relationships
    created_tickets = relationship(
        "SupportTicket",
        foreign_keys="SupportTicket.created_by",
        back_populates="creator"
    )
    assigned_tickets = relationship(
        "SupportTicket",
        foreign_keys="SupportTicket.assigned_to",
        back_populates="assignee"
    )
    ticket_comments = relationship(
        "TicketComment",
        back_populates="user",
        cascade="all, delete-orphan"
    )
    ticket_attachments = relationship(
        "TicketAttachment",
        back_populates="uploader",
        cascade="all, delete-orphan"
    )

    def to_dict(self):
        """Convert user to dictionary."""
        return {
            "id": str(self.id),
            "supabase_id": self.supabase_id,
            "email": self.email,
            "name": self.name,
            "avatar_url": self.avatar_url,
            "preferences": self.preferences,
            "last_active_organization_id": str(self.last_active_organization_id) if self.last_active_organization_id else None,
            "is_active": self.is_active,
            "email_verified": self.email_verified,
            "created_at": self.created_at.isoformat(),
            "updated_at": self.updated_at.isoformat(),
            "last_login_at": self.last_login_at.isoformat() if self.last_login_at else None,
        }