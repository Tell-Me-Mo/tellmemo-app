"""add_is_demo_flag_to_content_models

Revision ID: d9a4adacfa57
Revises: b507803113ba
Create Date: 2026-02-21 09:29:02.017827

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'd9a4adacfa57'
down_revision: Union[str, Sequence[str], None] = 'b507803113ba'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

_tables = [
    'activities',
    'blockers',
    'content',
    'lessons_learned',
    'portfolios',
    'programs',
    'projects',
    'risks',
    'summaries',
    'tasks',
]


def upgrade() -> None:
    """Add is_demo boolean column to all content model tables."""
    for table in _tables:
        op.add_column(table, sa.Column('is_demo', sa.Boolean(), server_default='false', nullable=False))


def downgrade() -> None:
    """Remove is_demo column from all content model tables."""
    for table in _tables:
        op.drop_column(table, 'is_demo')
