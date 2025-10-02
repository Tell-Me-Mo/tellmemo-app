"""add_claude_4_models_to_aimodel_enum

Revision ID: b408f4b81c80
Revises: 751062015f2b
Create Date: 2025-09-18 19:57:39.291231

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'b408f4b81c80'
down_revision: Union[str, Sequence[str], None] = '751062015f2b'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Add Claude 4 models to the aimodel enum."""
    # Add new enum values for Claude 4 models
    op.execute("ALTER TYPE aimodel ADD VALUE IF NOT EXISTS 'claude-opus-4-1-20250805'")
    op.execute("ALTER TYPE aimodel ADD VALUE IF NOT EXISTS 'claude-opus-4-20250522'")
    op.execute("ALTER TYPE aimodel ADD VALUE IF NOT EXISTS 'claude-sonnet-4-20250522'")


def downgrade() -> None:
    """Remove Claude 4 models from the aimodel enum.

    Note: PostgreSQL doesn't support removing enum values directly.
    This would require recreating the enum and all dependent columns.
    """
    # Downgrade is complex for enums in PostgreSQL
    # You would need to:
    # 1. Create a new enum without the new values
    # 2. Change all columns to use the new enum
    # 3. Drop the old enum
    # This is left as a manual process if needed
    pass