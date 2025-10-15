"""convert_itemupdatetype_enum_to_varchar

Revision ID: convert_enum_to_varchar
Revises: d7d1975698c8
Create Date: 2025-10-15 12:00:00.000000

Convert ItemUpdateType enum to VARCHAR for better flexibility and easier migrations
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import ENUM


# revision identifiers, used by Alembic.
revision: str = 'convert_enum_to_varchar'
down_revision: Union[str, Sequence[str], None] = 'd7d1975698c8'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Convert enum to VARCHAR."""

    # Create a temporary column with VARCHAR type
    op.add_column('item_updates', sa.Column('update_type_new', sa.String(50), nullable=True))

    # Copy data from enum to varchar, converting to lowercase
    op.execute("""
        UPDATE item_updates
        SET update_type_new = LOWER(update_type::text)
    """)

    # Make the new column not nullable
    op.alter_column('item_updates', 'update_type_new', nullable=False)

    # Drop the old enum column
    op.drop_column('item_updates', 'update_type')

    # Rename the new column to the original name
    op.alter_column('item_updates', 'update_type_new', new_column_name='update_type')

    # Drop the enum type if it exists
    op.execute("DROP TYPE IF EXISTS itemupdatetype CASCADE")

    # Add a CHECK constraint to ensure valid values (optional but recommended)
    op.create_check_constraint(
        'ck_item_updates_update_type',
        'item_updates',
        "update_type IN ('comment', 'status_change', 'assignment', 'edit', 'created')"
    )


def downgrade() -> None:
    """Convert VARCHAR back to enum."""

    # Remove the check constraint
    op.drop_constraint('ck_item_updates_update_type', 'item_updates', type_='check')

    # Create the enum type
    update_type_enum = ENUM('comment', 'status_change', 'assignment', 'edit', 'created', name='itemupdatetype')
    update_type_enum.create(op.get_bind())

    # Add a temporary enum column
    op.add_column('item_updates', sa.Column('update_type_old', update_type_enum, nullable=True))

    # Copy data from varchar to enum
    op.execute("""
        UPDATE item_updates
        SET update_type_old = update_type::itemupdatetype
    """)

    # Make the old column not nullable
    op.alter_column('item_updates', 'update_type_old', nullable=False)

    # Drop the varchar column
    op.drop_column('item_updates', 'update_type')

    # Rename the enum column back
    op.alter_column('item_updates', 'update_type_old', new_column_name='update_type')