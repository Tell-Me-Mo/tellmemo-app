"""add_transcription_integration_type

Revision ID: 37c0e8b8f436
Revises: remove_weekly_enum
Create Date: 2025-09-16 14:39:59.956076

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '37c0e8b8f436'
down_revision: Union[str, Sequence[str], None] = 'remove_weekly_enum'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    # Add 'transcription' to the IntegrationType enum
    op.execute("ALTER TYPE integrationtype ADD VALUE IF NOT EXISTS 'transcription'")


def downgrade() -> None:
    """Downgrade schema."""
    pass
