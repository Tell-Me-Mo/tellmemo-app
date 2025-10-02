"""add_project_description_changes_table

Revision ID: 239fdf20e86c
Revises: 593b4b15e62b
Create Date: 2025-09-12 17:02:57.375364

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '239fdf20e86c'
down_revision: Union[str, Sequence[str], None] = '593b4b15e62b'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    op.create_table(
        'project_description_changes',
        sa.Column('id', sa.dialects.postgresql.UUID(as_uuid=True), primary_key=True, server_default=sa.text('gen_random_uuid()')),
        sa.Column('project_id', sa.dialects.postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('old_description', sa.Text, nullable=True),
        sa.Column('new_description', sa.Text, nullable=True),
        sa.Column('content_id', sa.dialects.postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column('reason', sa.Text, nullable=True),
        sa.Column('confidence_score', sa.Float, nullable=True),
        sa.Column('changed_at', sa.DateTime, server_default=sa.text('NOW()'), nullable=False),
        sa.Column('changed_by', sa.String(255), server_default='system', nullable=False),
        sa.ForeignKeyConstraint(['project_id'], ['projects.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['content_id'], ['content.id'], ondelete='SET NULL'),
    )
    
    # Add indexes for better query performance
    op.create_index('ix_project_description_changes_project_id', 'project_description_changes', ['project_id'])
    op.create_index('ix_project_description_changes_changed_at', 'project_description_changes', ['changed_at'])


def downgrade() -> None:
    """Downgrade schema."""
    op.drop_index('ix_project_description_changes_changed_at', 'project_description_changes')
    op.drop_index('ix_project_description_changes_project_id', 'project_description_changes')
    op.drop_table('project_description_changes')
