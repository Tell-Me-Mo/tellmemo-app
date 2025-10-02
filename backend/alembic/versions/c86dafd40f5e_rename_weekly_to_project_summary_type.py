"""rename_weekly_to_project_summary_type

Revision ID: c86dafd40f5e
Revises: 3836bef74d9a
Create Date: 2025-09-15 17:39:12.494156

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'c86dafd40f5e'
down_revision: Union[str, Sequence[str], None] = '3836bef74d9a'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Rename WEEKLY to PROJECT in summarytype enum."""
    # PostgreSQL doesn't allow direct rename of enum values, so we need a workaround
    # Add the new value first
    op.execute("ALTER TYPE summarytype ADD VALUE IF NOT EXISTS 'PROJECT' AFTER 'MEETING'")

    # Commit to make the new enum value available
    op.execute("COMMIT")

    # Start a new transaction for the UPDATE
    op.execute("BEGIN")

    # Update existing records
    op.execute("UPDATE summaries SET summary_type = 'PROJECT' WHERE summary_type = 'WEEKLY'")

    # Note: We cannot remove the old 'WEEKLY' value from the enum in PostgreSQL
    # It will remain but unused


def downgrade() -> None:
    """Revert PROJECT back to WEEKLY in summarytype enum."""
    # Add WEEKLY back if it was somehow removed
    op.execute("ALTER TYPE summarytype ADD VALUE IF NOT EXISTS 'WEEKLY' AFTER 'MEETING'")

    # Update existing records back
    op.execute("UPDATE summaries SET summary_type = 'WEEKLY' WHERE summary_type = 'PROJECT'")
