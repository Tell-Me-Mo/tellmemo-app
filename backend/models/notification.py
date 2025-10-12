from sqlalchemy import Column, String, Text, Boolean, ForeignKey, DateTime, Enum, JSON, ARRAY
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
import uuid
import enum
from db.database import Base


class NotificationType(enum.Enum):
    INFO = "info"
    SUCCESS = "success"
    WARNING = "warning"
    ERROR = "error"
    SYSTEM = "system"


class NotificationPriority(enum.Enum):
    LOW = "low"
    NORMAL = "normal"
    HIGH = "high"
    CRITICAL = "critical"


class NotificationCategory(enum.Enum):
    SYSTEM = "system"
    PROJECT_UPDATE = "project_update"
    MEETING_READY = "meeting_ready"
    SUMMARY_GENERATED = "summary_generated"
    TASK_ASSIGNED = "task_assigned"
    TASK_DUE = "task_due"
    TASK_COMPLETED = "task_completed"
    RISK_CREATED = "risk_created"
    RISK_STATUS_CHANGED = "risk_status_changed"
    TEAM_JOINED = "team_joined"
    INVITATION_ACCEPTED = "invitation_accepted"
    CONTENT_PROCESSED = "content_processed"
    INTEGRATION_STATUS = "integration_status"
    EMAIL_DIGEST_SENT = "email_digest_sent"
    EMAIL_ONBOARDING_SENT = "email_onboarding_sent"
    EMAIL_INACTIVE_REMINDER_SENT = "email_inactive_reminder_sent"
    OTHER = "other"


class Notification(Base):
    __tablename__ = "notifications"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    organization_id = Column(UUID(as_uuid=True), ForeignKey("organizations.id", ondelete="CASCADE"))
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"))

    # Core notification data
    title = Column(String(255), nullable=False)
    message = Column(Text)
    type = Column(Enum(NotificationType), nullable=False)
    priority = Column(Enum(NotificationPriority), default=NotificationPriority.NORMAL)

    # Metadata
    category = Column(Enum(NotificationCategory), default=NotificationCategory.OTHER)
    entity_type = Column(String(50))  # 'project', 'task', 'risk', 'summary', etc
    entity_id = Column(UUID(as_uuid=True))  # Reference to related entity

    # Status tracking
    is_read = Column(Boolean, default=False)
    read_at = Column(DateTime(timezone=True))
    is_archived = Column(Boolean, default=False)
    archived_at = Column(DateTime(timezone=True))

    # Action support
    action_url = Column(Text)
    action_label = Column(String(100))
    extra_data = Column("metadata", JSON, default={})

    # Delivery tracking
    delivered_channels = Column(ARRAY(String), default=[])
    email_sent_at = Column(DateTime(timezone=True))
    push_sent_at = Column(DateTime(timezone=True))
    in_app_delivered_at = Column(DateTime(timezone=True))

    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    expires_at = Column(DateTime(timezone=True))

    # Relationships
    organization = relationship("Organization", back_populates="notifications")
    user = relationship("User", back_populates="notifications")

    def to_dict(self):
        return {
            "id": str(self.id),
            "organization_id": str(self.organization_id) if self.organization_id else None,
            "user_id": str(self.user_id) if self.user_id else None,
            "title": self.title,
            "message": self.message,
            "type": self.type.value if self.type else None,
            "priority": self.priority.value if self.priority else None,
            "category": self.category.value if self.category else None,
            "entity_type": self.entity_type,
            "entity_id": str(self.entity_id) if self.entity_id else None,
            "is_read": self.is_read,
            "read_at": self.read_at.isoformat() if self.read_at else None,
            "is_archived": self.is_archived,
            "archived_at": self.archived_at.isoformat() if self.archived_at else None,
            "action_url": self.action_url,
            "action_label": self.action_label,
            "metadata": self.extra_data or {},
            "delivered_channels": self.delivered_channels or [],
            "email_sent_at": self.email_sent_at.isoformat() if self.email_sent_at else None,
            "push_sent_at": self.push_sent_at.isoformat() if self.push_sent_at else None,
            "in_app_delivered_at": self.in_app_delivered_at.isoformat() if self.in_app_delivered_at else None,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "expires_at": self.expires_at.isoformat() if self.expires_at else None,
        }

    def mark_as_read(self):
        """Mark notification as read with timestamp"""
        self.is_read = True
        self.read_at = func.now()

    def mark_as_archived(self):
        """Archive notification with timestamp"""
        self.is_archived = True
        self.archived_at = func.now()

    def add_delivery_channel(self, channel: str):
        """Add a delivery channel to the notification"""
        if not self.delivered_channels:
            self.delivered_channels = []
        if channel not in self.delivered_channels:
            self.delivered_channels.append(channel)

            # Set specific delivery timestamp
            if channel == "email":
                self.email_sent_at = func.now()
            elif channel == "push":
                self.push_sent_at = func.now()
            elif channel == "in_app":
                self.in_app_delivered_at = func.now()

    def __repr__(self):
        return f"<Notification(id={self.id}, title={self.title}, user_id={self.user_id})>"