"""add_question_to_ask_field_to_tasks

Revision ID: ab03f7be1f9a
Revises: d1d5279328d9
Create Date: 2025-09-25 08:35:21.205925

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'ab03f7be1f9a'
down_revision: Union[str, Sequence[str], None] = 'd1d5279328d9'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    # Add question_to_ask column to tasks table
    op.add_column('tasks', sa.Column('question_to_ask', sa.Text(), nullable=True))


def downgrade() -> None:
    """Downgrade schema."""
    # Remove question_to_ask column from tasks table
    op.drop_column('tasks', 'question_to_ask')
