"""recreate_live_meeting_insights_with_correct_schema

Revision ID: b8013e9f9d08
Revises: f11cd7beb6f5
Create Date: 2025-10-27 21:06:03.413057

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'b8013e9f9d08'
down_revision: Union[str, Sequence[str], None] = 'f11cd7beb6f5'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    # Drop existing table (it has incorrect schema)
    op.drop_table('live_meeting_insights')

    # Recreate with correct schema matching the model
    # Note: recording_id is nullable since recordings table doesn't exist yet
    op.create_table('live_meeting_insights',
        sa.Column('id', sa.dialects.postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('session_id', sa.String(length=255), nullable=False),
        sa.Column('recording_id', sa.dialects.postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column('project_id', sa.dialects.postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('organization_id', sa.dialects.postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('insight_type', sa.String(length=50), nullable=False),
        sa.Column('detected_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('speaker', sa.String(length=255), nullable=True),
        sa.Column('content', sa.Text(), nullable=False),
        sa.Column('status', sa.String(length=50), nullable=False, server_default='tracking'),
        sa.Column('answer_source', sa.String(length=50), nullable=True),
        sa.Column('insight_metadata', sa.dialects.postgresql.JSONB(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(['project_id'], ['projects.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['organization_id'], ['organizations.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id')
    )

    # Create indexes
    op.create_index('ix_live_meeting_insights_session_id', 'live_meeting_insights', ['session_id'])
    op.create_index('ix_live_meeting_insights_recording_id', 'live_meeting_insights', ['recording_id'])
    op.create_index('ix_live_meeting_insights_project_id', 'live_meeting_insights', ['project_id'])
    op.create_index('ix_live_meeting_insights_organization_id', 'live_meeting_insights', ['organization_id'])
    op.create_index('ix_live_meeting_insights_insight_type', 'live_meeting_insights', ['insight_type'])
    op.create_index('ix_live_meeting_insights_detected_at', 'live_meeting_insights', ['detected_at'])
    op.create_index('ix_live_meeting_insights_speaker', 'live_meeting_insights', ['speaker'])

    # Composite indexes for common query patterns
    op.create_index('ix_live_meeting_insights_project_created', 'live_meeting_insights', ['project_id', 'created_at'])
    op.create_index('ix_live_meeting_insights_session_detected', 'live_meeting_insights', ['session_id', 'detected_at'])


def downgrade() -> None:
    """Downgrade schema."""
    # Drop indexes
    op.drop_index('ix_live_meeting_insights_session_detected', table_name='live_meeting_insights')
    op.drop_index('ix_live_meeting_insights_project_created', table_name='live_meeting_insights')
    op.drop_index('ix_live_meeting_insights_speaker', table_name='live_meeting_insights')
    op.drop_index('ix_live_meeting_insights_detected_at', table_name='live_meeting_insights')
    op.drop_index('ix_live_meeting_insights_insight_type', table_name='live_meeting_insights')
    op.drop_index('ix_live_meeting_insights_organization_id', table_name='live_meeting_insights')
    op.drop_index('ix_live_meeting_insights_project_id', table_name='live_meeting_insights')
    op.drop_index('ix_live_meeting_insights_recording_id', table_name='live_meeting_insights')
    op.drop_index('ix_live_meeting_insights_session_id', table_name='live_meeting_insights')

    # Drop and recreate old table (this is just for rollback, normally wouldn't do this)
    op.drop_table('live_meeting_insights')
