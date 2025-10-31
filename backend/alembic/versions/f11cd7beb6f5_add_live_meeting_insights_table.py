"""add_live_meeting_insights_table

Revision ID: f11cd7beb6f5
Revises: 729cd7038d25
Create Date: 2025-10-26 09:03:49.027801

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


# revision identifiers, used by Alembic.
revision: str = 'f11cd7beb6f5'
down_revision: Union[str, Sequence[str], None] = '729cd7038d25'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    # Create live_meeting_insights table
    op.create_table('live_meeting_insights',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('session_id', sa.String(), nullable=False),
        sa.Column('recording_id', postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column('project_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('organization_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('insight_type', sa.String(), nullable=False),
        sa.Column('detected_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('speaker', sa.String(), nullable=True),
        sa.Column('content', sa.Text(), nullable=False),
        sa.Column('status', sa.String(), nullable=False),
        sa.Column('answer_source', sa.String(), nullable=True),
        sa.Column('insight_metadata', postgresql.JSONB(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(['project_id'], ['projects.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['organization_id'], ['organizations.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id')
    )

    # Create indexes for performance
    op.create_index(op.f('ix_live_meeting_insights_session_id'), 'live_meeting_insights', ['session_id'], unique=False)
    op.create_index(op.f('ix_live_meeting_insights_recording_id'), 'live_meeting_insights', ['recording_id'], unique=False)
    op.create_index(op.f('ix_live_meeting_insights_project_id'), 'live_meeting_insights', ['project_id'], unique=False)
    op.create_index(op.f('ix_live_meeting_insights_organization_id'), 'live_meeting_insights', ['organization_id'], unique=False)
    op.create_index(op.f('ix_live_meeting_insights_insight_type'), 'live_meeting_insights', ['insight_type'], unique=False)
    op.create_index(op.f('ix_live_meeting_insights_detected_at'), 'live_meeting_insights', ['detected_at'], unique=False)
    op.create_index(op.f('ix_live_meeting_insights_speaker'), 'live_meeting_insights', ['speaker'], unique=False)

    # Create composite indexes for common query patterns
    op.create_index('ix_live_meeting_insights_project_created', 'live_meeting_insights', ['project_id', 'created_at'], unique=False)
    op.create_index('ix_live_meeting_insights_session_detected', 'live_meeting_insights', ['session_id', 'detected_at'], unique=False)


def downgrade() -> None:
    """Downgrade schema."""
    # Drop indexes
    op.drop_index('ix_live_meeting_insights_session_detected', table_name='live_meeting_insights')
    op.drop_index('ix_live_meeting_insights_project_created', table_name='live_meeting_insights')
    op.drop_index(op.f('ix_live_meeting_insights_speaker'), table_name='live_meeting_insights')
    op.drop_index(op.f('ix_live_meeting_insights_detected_at'), table_name='live_meeting_insights')
    op.drop_index(op.f('ix_live_meeting_insights_insight_type'), table_name='live_meeting_insights')
    op.drop_index(op.f('ix_live_meeting_insights_organization_id'), table_name='live_meeting_insights')
    op.drop_index(op.f('ix_live_meeting_insights_project_id'), table_name='live_meeting_insights')
    op.drop_index(op.f('ix_live_meeting_insights_recording_id'), table_name='live_meeting_insights')
    op.drop_index(op.f('ix_live_meeting_insights_session_id'), table_name='live_meeting_insights')

    # Drop table
    op.drop_table('live_meeting_insights')
