"""remove_weekly_from_summarytype

Revision ID: remove_weekly_enum
Revises: c86dafd40f5e
Create Date: 2025-09-15 18:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'remove_weekly_enum'
down_revision: Union[str, Sequence[str], None] = 'c86dafd40f5e'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Remove WEEKLY from summarytype enum by recreating the enum."""
    # Create a new enum type without WEEKLY
    op.execute("CREATE TYPE summarytype_new AS ENUM ('MEETING', 'PROJECT', 'PROGRAM', 'PORTFOLIO')")

    # Alter the column to use the new enum type
    op.execute("ALTER TABLE summaries ALTER COLUMN summary_type TYPE summarytype_new USING summary_type::text::summarytype_new")

    # Drop the old enum type
    op.execute("DROP TYPE summarytype")

    # Rename the new enum type to the original name
    op.execute("ALTER TYPE summarytype_new RENAME TO summarytype")


def downgrade() -> None:
    """Add WEEKLY back to summarytype enum."""
    # Create a new enum type with WEEKLY
    op.execute("CREATE TYPE summarytype_new AS ENUM ('MEETING', 'PROJECT', 'WEEKLY', 'PROGRAM', 'PORTFOLIO')")

    # Alter the column to use the new enum type
    op.execute("ALTER TABLE summaries ALTER COLUMN summary_type TYPE summarytype_new USING summary_type::text::summarytype_new")

    # Drop the old enum type
    op.execute("DROP TYPE summarytype")

    # Rename the new enum type to the original name
    op.execute("ALTER TYPE summarytype_new RENAME TO summarytype")