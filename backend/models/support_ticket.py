"""Support ticket models."""
from sqlalchemy import Column, String, Text, DateTime, Boolean, Integer, ForeignKey, UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from db.database import Base
import uuid


class SupportTicket(Base):
    """Support ticket model."""
    __tablename__ = 'support_tickets'

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    organization_id = Column(UUID(as_uuid=True), ForeignKey('organizations.id', ondelete='CASCADE'), nullable=False)
    title = Column(String(255), nullable=False)
    description = Column(Text, nullable=False)
    type = Column(String(50), nullable=False)  # bug_report, feature_request, general_support, documentation
    priority = Column(String(20), nullable=False)  # low, medium, high, critical
    status = Column(String(30), nullable=False, server_default='open')  # open, in_progress, waiting_for_user, resolved, closed
    created_by = Column(UUID(as_uuid=True), ForeignKey('users.id', ondelete='CASCADE'), nullable=False)
    assigned_to = Column(UUID(as_uuid=True), ForeignKey('users.id', ondelete='SET NULL'), nullable=True)
    resolved_at = Column(DateTime(timezone=True), nullable=True)
    resolution_notes = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.current_timestamp(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.current_timestamp(), onupdate=func.current_timestamp(), nullable=False)

    # Relationships
    organization = relationship('Organization', back_populates='support_tickets')
    creator = relationship('User', foreign_keys=[created_by], back_populates='created_tickets')
    assignee = relationship('User', foreign_keys=[assigned_to], back_populates='assigned_tickets')
    comments = relationship('TicketComment', back_populates='ticket', cascade='all, delete-orphan')
    attachments = relationship('TicketAttachment', back_populates='ticket', cascade='all, delete-orphan')


class TicketComment(Base):
    """Ticket comment model."""
    __tablename__ = 'ticket_comments'

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    ticket_id = Column(UUID(as_uuid=True), ForeignKey('support_tickets.id', ondelete='CASCADE'), nullable=False)
    user_id = Column(UUID(as_uuid=True), ForeignKey('users.id', ondelete='CASCADE'), nullable=False)
    comment = Column(Text, nullable=False)
    is_internal = Column(Boolean, nullable=False, server_default='false')
    is_system_message = Column(Boolean, nullable=False, server_default='false')
    created_at = Column(DateTime(timezone=True), server_default=func.current_timestamp(), nullable=False)

    # Relationships
    ticket = relationship('SupportTicket', back_populates='comments')
    user = relationship('User', back_populates='ticket_comments')
    attachments = relationship('TicketAttachment', back_populates='comment', cascade='all, delete-orphan')


class TicketAttachment(Base):
    """Ticket attachment model."""
    __tablename__ = 'ticket_attachments'

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    ticket_id = Column(UUID(as_uuid=True), ForeignKey('support_tickets.id', ondelete='CASCADE'), nullable=False)
    comment_id = Column(UUID(as_uuid=True), ForeignKey('ticket_comments.id', ondelete='CASCADE'), nullable=True)
    file_name = Column(String(255), nullable=False)
    file_url = Column(Text, nullable=False)
    file_type = Column(String(100), nullable=True)
    file_size = Column(Integer, nullable=True)
    uploaded_by = Column(UUID(as_uuid=True), ForeignKey('users.id', ondelete='CASCADE'), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.current_timestamp(), nullable=False)

    # Relationships
    ticket = relationship('SupportTicket', back_populates='attachments')
    comment = relationship('TicketComment', back_populates='attachments')
    uploader = relationship('User', back_populates='ticket_attachments')