"""Organization model for multi-tenant support."""

import uuid
from datetime import datetime
from typing import Optional, List, TYPE_CHECKING
from sqlalchemy import Column, String, DateTime, Boolean, JSON, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from db.database import Base

if TYPE_CHECKING:
    from models.organization_member import OrganizationMember
    from models.user import User


class Organization(Base):
    """Model for organizations (tenants)."""

    __tablename__ = "organizations"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String, nullable=False)
    slug = Column(String, nullable=False, unique=True)  # URL-friendly identifier

    # Organization details
    description = Column(String, nullable=True)
    logo_url = Column(String, nullable=True)

    # Settings
    settings = Column(JSON, default=dict)  # Organization-wide settings (timezone, locale, etc.)
    is_active = Column(Boolean, default=True)

    # Creator tracking
    created_by = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"), nullable=True)

    # Timestamps
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)
    updated_at = Column(DateTime, nullable=False, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    members = relationship("OrganizationMember", back_populates="organization", cascade="all, delete-orphan")
    summaries = relationship("Summary", back_populates="organization", cascade="all, delete-orphan")
    creator = relationship("User", foreign_keys=[created_by])
    notifications = relationship("Notification", back_populates="organization", cascade="all, delete-orphan")
    support_tickets = relationship("SupportTicket", back_populates="organization", cascade="all, delete-orphan")
    conversations = relationship("Conversation", back_populates="organization", cascade="all, delete-orphan")

    def to_dict(self):
        """Convert organization to dictionary."""
        return {
            "id": str(self.id),
            "name": self.name,
            "slug": self.slug,
            "description": self.description,
            "logo_url": self.logo_url,
            "settings": self.settings,
            "is_active": self.is_active,
            "created_by": str(self.created_by) if self.created_by else None,
            "created_at": self.created_at.isoformat(),
            "updated_at": self.updated_at.isoformat(),
        }