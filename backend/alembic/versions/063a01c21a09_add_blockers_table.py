"""add_blockers_table

Revision ID: 063a01c21a09
Revises: be7ed030d7d6
Create Date: 2025-09-27 05:08:08.983827

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '063a01c21a09'
down_revision: Union[str, Sequence[str], None] = 'be7ed030d7d6'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    # Skip enum type creation - they already exist from a previous migration or manual creation
    # If needed in fresh DB, uncomment these lines:
    # op.execute("CREATE TYPE blockerimpact AS ENUM ('low', 'medium', 'high', 'critical')")
    # op.execute("CREATE TYPE blockerstatus AS ENUM ('active', 'resolved', 'pending', 'escalated')")

    # Create blockers table
    op.create_table('blockers',
        sa.Column('id', sa.UUID(), nullable=False),
        sa.Column('project_id', sa.UUID(), nullable=False),
        sa.Column('title', sa.String(length=200), nullable=False),
        sa.Column('description', sa.Text(), nullable=False),
        sa.Column('impact', sa.Enum('low', 'medium', 'high', 'critical', name='blockerimpact'), nullable=False),
        sa.Column('status', sa.Enum('active', 'resolved', 'pending', 'escalated', name='blockerstatus'), nullable=False),
        sa.Column('resolution', sa.Text(), nullable=True),
        sa.Column('category', sa.String(length=50), nullable=True),
        sa.Column('owner', sa.String(length=100), nullable=True),
        sa.Column('dependencies', sa.Text(), nullable=True),
        sa.Column('target_date', sa.DateTime(), nullable=True),
        sa.Column('resolved_date', sa.DateTime(), nullable=True),
        sa.Column('escalation_date', sa.DateTime(), nullable=True),
        sa.Column('ai_generated', sa.String(length=5), nullable=True),
        sa.Column('ai_confidence', sa.Float(), nullable=True),
        sa.Column('source_content_id', sa.UUID(), nullable=True),
        sa.Column('assigned_to', sa.String(length=100), nullable=True),
        sa.Column('assigned_to_email', sa.String(length=255), nullable=True),
        sa.Column('identified_date', sa.DateTime(), nullable=True),
        sa.Column('last_updated', sa.DateTime(), nullable=True),
        sa.Column('updated_by', sa.String(length=50), nullable=True),
        sa.ForeignKeyConstraint(['project_id'], ['projects.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['source_content_id'], ['content.id'], ),
        sa.PrimaryKeyConstraint('id')
    )

    # Create index for project_id
    op.create_index(op.f('ix_blockers_project_id'), 'blockers', ['project_id'], unique=False)
    op.create_index(op.f('ix_blockers_status'), 'blockers', ['status'], unique=False)


def downgrade() -> None:
    """Downgrade schema."""
    op.drop_index(op.f('ix_blockers_status'), table_name='blockers')
    op.drop_index(op.f('ix_blockers_project_id'), table_name='blockers')
    op.drop_table('blockers')
    op.execute("DROP TYPE blockerstatus")
    op.execute("DROP TYPE blockerimpact")
