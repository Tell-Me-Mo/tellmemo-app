"""drop_project_description_changes_feature

Revision ID: 1f43912a2a9b
Revises: ee309bf732c6
Create Date: 2025-09-26 10:55:15.745949

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '1f43912a2a9b'
down_revision: Union[str, Sequence[str], None] = 'ee309bf732c6'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Drop the project_description_changes table and feature."""
    op.drop_table('project_description_changes')


def downgrade() -> None:
    """Recreate the project_description_changes table."""
    op.create_table(
        'project_description_changes',
        sa.Column('id', sa.UUID(), nullable=False),
        sa.Column('project_id', sa.UUID(), nullable=False),
        sa.Column('old_description', sa.Text(), nullable=True),
        sa.Column('new_description', sa.Text(), nullable=True),
        sa.Column('content_id', sa.UUID(), nullable=True),
        sa.Column('reason', sa.Text(), nullable=True),
        sa.Column('confidence_score', sa.Float(), nullable=True),
        sa.Column('changed_at', sa.DateTime(), nullable=False, server_default=sa.func.now()),
        sa.Column('changed_by', sa.String(255), nullable=False, server_default='system'),
        sa.PrimaryKeyConstraint('id'),
        sa.ForeignKeyConstraint(['project_id'], ['projects.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['content_id'], ['content.id'], ondelete='SET NULL')
    )
    op.create_index('ix_project_description_changes_project_id', 'project_description_changes', ['project_id'])
    op.create_index('ix_project_description_changes_changed_at', 'project_description_changes', ['changed_at'])
