"""add_support_tickets_system

Revision ID: 4690922c511e
Revises: 1d4bd197002a
Create Date: 2025-09-23 14:28:23.291615

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


# revision identifiers, used by Alembic.
revision: str = '4690922c511e'
down_revision: Union[str, Sequence[str], None] = '1d4bd197002a'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""

    # Create support_tickets table
    op.create_table(
        'support_tickets',
        sa.Column('id', sa.UUID(), nullable=False),
        sa.Column('organization_id', sa.UUID(), nullable=False),
        sa.Column('title', sa.String(length=255), nullable=False),
        sa.Column('description', sa.Text(), nullable=False),
        sa.Column('type', sa.String(length=50), nullable=False),
        sa.Column('priority', sa.String(length=20), nullable=False),
        sa.Column('status', sa.String(length=30), nullable=False, server_default='open'),
        sa.Column('created_by', sa.UUID(), nullable=False),
        sa.Column('assigned_to', sa.UUID(), nullable=True),
        sa.Column('resolved_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('resolution_notes', sa.Text(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('CURRENT_TIMESTAMP'), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('CURRENT_TIMESTAMP'), nullable=False),
        sa.ForeignKeyConstraint(['organization_id'], ['organizations.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['created_by'], ['users.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['assigned_to'], ['users.id'], ondelete='SET NULL'),
        sa.PrimaryKeyConstraint('id')
    )

    # Create indexes for tickets
    op.create_index('idx_tickets_organization_id', 'support_tickets', ['organization_id'])
    op.create_index('idx_tickets_created_by', 'support_tickets', ['created_by'])
    op.create_index('idx_tickets_status', 'support_tickets', ['status'])
    op.create_index('idx_tickets_priority', 'support_tickets', ['priority'])
    op.create_index('idx_tickets_created_at', 'support_tickets', ['created_at'])

    # Create ticket_comments table
    op.create_table(
        'ticket_comments',
        sa.Column('id', sa.UUID(), nullable=False),
        sa.Column('ticket_id', sa.UUID(), nullable=False),
        sa.Column('user_id', sa.UUID(), nullable=False),
        sa.Column('comment', sa.Text(), nullable=False),
        sa.Column('is_internal', sa.Boolean(), nullable=False, server_default='false'),
        sa.Column('is_system_message', sa.Boolean(), nullable=False, server_default='false'),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('CURRENT_TIMESTAMP'), nullable=False),
        sa.ForeignKeyConstraint(['ticket_id'], ['support_tickets.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id')
    )

    # Create indexes for comments
    op.create_index('idx_comments_ticket_id', 'ticket_comments', ['ticket_id'])
    op.create_index('idx_comments_created_at', 'ticket_comments', ['created_at'])

    # Create ticket_attachments table
    op.create_table(
        'ticket_attachments',
        sa.Column('id', sa.UUID(), nullable=False),
        sa.Column('ticket_id', sa.UUID(), nullable=False),
        sa.Column('comment_id', sa.UUID(), nullable=True),
        sa.Column('file_name', sa.String(length=255), nullable=False),
        sa.Column('file_url', sa.Text(), nullable=False),
        sa.Column('file_type', sa.String(length=100), nullable=True),
        sa.Column('file_size', sa.Integer(), nullable=True),
        sa.Column('uploaded_by', sa.UUID(), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('CURRENT_TIMESTAMP'), nullable=False),
        sa.ForeignKeyConstraint(['ticket_id'], ['support_tickets.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['comment_id'], ['ticket_comments.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['uploaded_by'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id')
    )

    # Create index for attachments
    op.create_index('idx_attachments_ticket_id', 'ticket_attachments', ['ticket_id'])


def downgrade() -> None:
    """Downgrade schema."""
    # Drop tables and indexes
    op.drop_index('idx_attachments_ticket_id', 'ticket_attachments')
    op.drop_table('ticket_attachments')

    op.drop_index('idx_comments_created_at', 'ticket_comments')
    op.drop_index('idx_comments_ticket_id', 'ticket_comments')
    op.drop_table('ticket_comments')

    op.drop_index('idx_tickets_created_at', 'support_tickets')
    op.drop_index('idx_tickets_priority', 'support_tickets')
    op.drop_index('idx_tickets_status', 'support_tickets')
    op.drop_index('idx_tickets_created_by', 'support_tickets')
    op.drop_index('idx_tickets_organization_id', 'support_tickets')
    op.drop_table('support_tickets')