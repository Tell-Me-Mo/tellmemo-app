"""add_program_portfolio_ids_to_summaries

Revision ID: 3836bef74d9a
Revises: f802fce0546d
Create Date: 2025-09-14 12:23:25.566204

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '3836bef74d9a'
down_revision: Union[str, Sequence[str], None] = 'f802fce0546d'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    # Add program_id column
    op.add_column('summaries', sa.Column('program_id', sa.UUID(), nullable=True))
    op.create_foreign_key(
        'fk_summaries_program_id',
        'summaries', 'programs',
        ['program_id'], ['id'],
        ondelete='CASCADE'
    )

    # Add portfolio_id column
    op.add_column('summaries', sa.Column('portfolio_id', sa.UUID(), nullable=True))
    op.create_foreign_key(
        'fk_summaries_portfolio_id',
        'summaries', 'portfolios',
        ['portfolio_id'], ['id'],
        ondelete='CASCADE'
    )

    # Make project_id nullable since program/portfolio summaries won't have a project
    op.alter_column('summaries', 'project_id', nullable=True)


def downgrade() -> None:
    """Downgrade schema."""
    # Remove foreign keys
    op.drop_constraint('fk_summaries_portfolio_id', 'summaries', type_='foreignkey')
    op.drop_constraint('fk_summaries_program_id', 'summaries', type_='foreignkey')

    # Remove columns
    op.drop_column('summaries', 'portfolio_id')
    op.drop_column('summaries', 'program_id')

    # Make project_id non-nullable again
    op.alter_column('summaries', 'project_id', nullable=False)
