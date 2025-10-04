"""add_activity_metadata_column

Revision ID: 1056eb2594d0
Revises: 75faa7f26436
Create Date: 2025-10-04 08:59:14.246139

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision: str = '1056eb2594d0'
down_revision: Union[str, Sequence[str], None] = '75faa7f26436'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema - Add activity_metadata column if it doesn't exist."""
    # Check if column already exists and rename 'metadata' if needed
    conn = op.get_bind()
    inspector = sa.inspect(conn)
    columns = [col['name'] for col in inspector.get_columns('activities')]

    if 'metadata' in columns and 'activity_metadata' not in columns:
        # Rename 'metadata' to 'activity_metadata'
        op.alter_column('activities', 'metadata', new_column_name='activity_metadata')
    elif 'activity_metadata' not in columns:
        # Add the column if it doesn't exist at all
        op.add_column('activities', sa.Column('activity_metadata', sa.Text(), nullable=True))


def downgrade() -> None:
    """Downgrade schema - Rename activity_metadata back to metadata."""
    conn = op.get_bind()
    inspector = sa.inspect(conn)
    columns = [col['name'] for col in inspector.get_columns('activities')]

    if 'activity_metadata' in columns:
        # Rename back to 'metadata'
        op.alter_column('activities', 'activity_metadata', new_column_name='metadata')
