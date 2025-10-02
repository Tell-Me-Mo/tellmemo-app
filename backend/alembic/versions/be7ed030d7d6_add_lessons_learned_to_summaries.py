"""add_lessons_learned_to_summaries

Revision ID: be7ed030d7d6
Revises: 9d52baa38402
Create Date: 2025-09-26 13:45:57.941393

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


# revision identifiers, used by Alembic.
revision: str = 'be7ed030d7d6'
down_revision: Union[str, Sequence[str], None] = '9d52baa38402'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Add lessons_learned column to summaries table."""
    op.add_column('summaries', sa.Column('lessons_learned', postgresql.JSONB(astext_type=sa.Text()), nullable=True))


def downgrade() -> None:
    """Remove lessons_learned column from summaries table."""
    op.drop_column('summaries', 'lessons_learned')
