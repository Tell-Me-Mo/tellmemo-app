"""update_itemupdatetype_enum_to_lowercase

Revision ID: d7d1975698c8
Revises: 6d218df43825
Create Date: 2025-10-15 09:06:42.854431

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'd7d1975698c8'
down_revision: Union[str, Sequence[str], None] = '6d218df43825'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema - convert itemupdatetype enum to lowercase values."""
    # Create new enum with lowercase values
    op.execute("CREATE TYPE itemupdatetype_new AS ENUM ('comment', 'status_change', 'assignment', 'edit', 'created')")

    # Convert existing data and change column type
    op.execute("""
        ALTER TABLE item_updates
        ALTER COLUMN update_type TYPE itemupdatetype_new
        USING (LOWER(update_type::text)::itemupdatetype_new)
    """)

    # Drop old enum type
    op.execute("DROP TYPE itemupdatetype")

    # Rename new enum to original name
    op.execute("ALTER TYPE itemupdatetype_new RENAME TO itemupdatetype")


def downgrade() -> None:
    """Downgrade schema - convert itemupdatetype enum back to uppercase values."""
    # Create old enum with uppercase values
    op.execute("CREATE TYPE itemupdatetype_old AS ENUM ('COMMENT', 'STATUS_CHANGE', 'ASSIGNMENT', 'EDIT', 'CREATED')")

    # Convert existing data and change column type back
    op.execute("""
        ALTER TABLE item_updates
        ALTER COLUMN update_type TYPE itemupdatetype_old
        USING (UPPER(update_type::text)::itemupdatetype_old)
    """)

    # Drop new enum type
    op.execute("DROP TYPE itemupdatetype")

    # Rename old enum back to original name
    op.execute("ALTER TYPE itemupdatetype_old RENAME TO itemupdatetype")
