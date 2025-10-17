"""add_title_embedding_to_items

Revision ID: 77dd4a4b845e
Revises: 6c7942ee0af2
Create Date: 2025-10-16 11:58:52.370302

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '77dd4a4b845e'
down_revision: Union[str, Sequence[str], None] = '6c7942ee0af2'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Add title_embedding JSON column to risks, tasks, blockers, and lessons_learned tables."""
    # Add title_embedding column as JSON to store embedding vectors (768 dimensions)
    # Using JSON instead of pgvector for compatibility
    op.add_column('risks', sa.Column('title_embedding', sa.JSON, nullable=True))
    op.add_column('tasks', sa.Column('title_embedding', sa.JSON, nullable=True))
    op.add_column('blockers', sa.Column('title_embedding', sa.JSON, nullable=True))
    op.add_column('lessons_learned', sa.Column('title_embedding', sa.JSON, nullable=True))


def downgrade() -> None:
    """Remove title_embedding columns."""
    op.drop_column('lessons_learned', 'title_embedding')
    op.drop_column('blockers', 'title_embedding')
    op.drop_column('tasks', 'title_embedding')
    op.drop_column('risks', 'title_embedding')
