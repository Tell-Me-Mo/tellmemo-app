"""add_live_meeting_insights_table

Revision ID: 78bd477668c3
Revises: 729cd7038d25
Create Date: 2025-10-19 18:46:14.428760

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


# revision identifiers, used by Alembic.
revision: str = '78bd477668c3'
down_revision: Union[str, Sequence[str], None] = '729cd7038d25'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    # Create live_meeting_insights table
    op.create_table(
        'live_meeting_insights',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('session_id', sa.String(length=255), nullable=False),
        sa.Column('project_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('organization_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('insight_type', sa.String(length=50), nullable=False),
        sa.Column('priority', sa.String(length=20), nullable=False),
        sa.Column('content', sa.Text(), nullable=False),
        sa.Column('context', sa.Text(), nullable=True),
        sa.Column('assigned_to', sa.String(length=255), nullable=True),
        sa.Column('due_date', sa.String(length=50), nullable=True),
        sa.Column('confidence_score', sa.Float(), nullable=True),
        sa.Column('chunk_index', sa.Integer(), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.Column('insight_metadata', postgresql.JSONB(astext_type=sa.Text()), nullable=True),
        sa.ForeignKeyConstraint(['organization_id'], ['organizations.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['project_id'], ['projects.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id')
    )

    # Create indexes for efficient queries
    op.create_index(op.f('ix_live_meeting_insights_session_id'), 'live_meeting_insights', ['session_id'], unique=False)
    op.create_index(op.f('ix_live_meeting_insights_project_id'), 'live_meeting_insights', ['project_id'], unique=False)
    op.create_index(op.f('ix_live_meeting_insights_organization_id'), 'live_meeting_insights', ['organization_id'], unique=False)
    op.create_index(op.f('ix_live_meeting_insights_insight_type'), 'live_meeting_insights', ['insight_type'], unique=False)
    op.create_index(op.f('ix_live_meeting_insights_created_at'), 'live_meeting_insights', ['created_at'], unique=False)

    # Create composite index for common queries (project + created_at)
    op.create_index('ix_live_meeting_insights_project_created', 'live_meeting_insights', ['project_id', 'created_at'], unique=False)


def downgrade() -> None:
    """Downgrade schema."""
    op.drop_index('ix_live_meeting_insights_project_created', table_name='live_meeting_insights')
    op.drop_index(op.f('ix_live_meeting_insights_created_at'), table_name='live_meeting_insights')
    op.drop_index(op.f('ix_live_meeting_insights_insight_type'), table_name='live_meeting_insights')
    op.drop_index(op.f('ix_live_meeting_insights_organization_id'), table_name='live_meeting_insights')
    op.drop_index(op.f('ix_live_meeting_insights_project_id'), table_name='live_meeting_insights')
    op.drop_index(op.f('ix_live_meeting_insights_session_id'), table_name='live_meeting_insights')
    op.drop_table('live_meeting_insights')
