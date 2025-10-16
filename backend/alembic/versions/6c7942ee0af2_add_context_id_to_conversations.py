"""add_context_id_to_conversations

Revision ID: 6c7942ee0af2
Revises: convert_enum_to_varchar
Create Date: 2025-10-16 08:36:51.719536

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '6c7942ee0af2'
down_revision: Union[str, Sequence[str], None] = 'convert_enum_to_varchar'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    # Add context_id column to conversations table
    op.add_column('conversations', sa.Column('context_id', sa.String(length=255), nullable=True))

    # Add index for faster filtering
    op.create_index(
        'ix_conversations_context_id',
        'conversations',
        ['context_id'],
        unique=False
    )


def downgrade() -> None:
    """Downgrade schema."""
    # Drop index first
    op.drop_index('ix_conversations_context_id', table_name='conversations')

    # Drop column
    op.drop_column('conversations', 'context_id')
