"""add_notifications_table

Revision ID: f19c8c331ae0
Revises: 923efe3cfccd
Create Date: 2025-09-20 20:49:56.427420

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


# revision identifiers, used by Alembic.
revision: str = 'f19c8c331ae0'
down_revision: Union[str, Sequence[str], None] = '923efe3cfccd'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Create notifications table and related enums."""

    # Create enums directly without checking
    # SQLAlchemy will handle creating them if they don't exist

    # Create notifications table
    op.create_table('notifications',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('organization_id', postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), nullable=True),

        # Core notification data
        sa.Column('title', sa.String(length=255), nullable=False),
        sa.Column('message', sa.Text(), nullable=True),
        sa.Column('type', sa.Enum('info', 'success', 'warning', 'error', 'system', name='notificationtype'), nullable=False),
        sa.Column('priority', sa.Enum('low', 'normal', 'high', 'critical', name='notificationpriority'), nullable=True),

        # Metadata
        sa.Column('category', sa.Enum('system', 'project_update', 'meeting_ready', 'summary_generated',
                                      'task_assigned', 'task_due', 'task_completed', 'risk_created',
                                      'risk_status_changed', 'team_joined', 'invitation_accepted',
                                      'content_processed', 'integration_status', 'other',
                                      name='notificationcategory'), nullable=True),
        sa.Column('entity_type', sa.String(length=50), nullable=True),
        sa.Column('entity_id', postgresql.UUID(as_uuid=True), nullable=True),

        # Status tracking
        sa.Column('is_read', sa.Boolean(), nullable=True, default=False),
        sa.Column('read_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('is_archived', sa.Boolean(), nullable=True, default=False),
        sa.Column('archived_at', sa.DateTime(timezone=True), nullable=True),

        # Action support
        sa.Column('action_url', sa.Text(), nullable=True),
        sa.Column('action_label', sa.String(length=100), nullable=True),
        sa.Column('metadata', postgresql.JSON(astext_type=sa.Text()), nullable=True),

        # Delivery tracking
        sa.Column('delivered_channels', postgresql.ARRAY(sa.String()), nullable=True),
        sa.Column('email_sent_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('push_sent_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('in_app_delivered_at', sa.DateTime(timezone=True), nullable=True),

        # Timestamps
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=True),
        sa.Column('expires_at', sa.DateTime(timezone=True), nullable=True),

        sa.ForeignKeyConstraint(['organization_id'], ['organizations.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id')
    )

    # Create indexes for better query performance
    op.create_index('idx_notifications_user_read', 'notifications', ['user_id', 'is_read'])
    op.create_index('idx_notifications_org_created', 'notifications', ['organization_id', 'created_at'])
    op.create_index('idx_notifications_entity', 'notifications', ['entity_type', 'entity_id'])
    op.create_index('idx_notifications_user_created', 'notifications', ['user_id', 'created_at'])
    op.create_index('idx_notifications_user_archived', 'notifications', ['user_id', 'is_archived'])


def downgrade() -> None:
    """Drop notifications table and related enums."""

    # Drop indexes
    op.drop_index('idx_notifications_user_archived', table_name='notifications')
    op.drop_index('idx_notifications_user_created', table_name='notifications')
    op.drop_index('idx_notifications_entity', table_name='notifications')
    op.drop_index('idx_notifications_org_created', table_name='notifications')
    op.drop_index('idx_notifications_user_read', table_name='notifications')

    # Drop table
    op.drop_table('notifications')

    # Drop enums
    op.execute('DROP TYPE IF EXISTS notificationcategory')
    op.execute('DROP TYPE IF EXISTS notificationpriority')
    op.execute('DROP TYPE IF EXISTS notificationtype')