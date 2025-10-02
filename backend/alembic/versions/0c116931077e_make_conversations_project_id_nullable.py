"""make_conversations_project_id_nullable

Revision ID: 0c116931077e
Revises: d46a27c2202f
Create Date: 2025-09-30 17:39:45.296194

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '0c116931077e'
down_revision: Union[str, Sequence[str], None] = 'd46a27c2202f'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Make project_id nullable in conversations table to support organization-level conversations."""
    # Make project_id nullable
    op.alter_column('conversations', 'project_id',
                    existing_type=sa.UUID(),
                    nullable=True)


def downgrade() -> None:
    """Revert project_id to NOT NULL (will fail if there are organization-level conversations)."""
    # Make project_id NOT NULL again
    op.alter_column('conversations', 'project_id',
                    existing_type=sa.UUID(),
                    nullable=False)
