"""add_native_auth_support

Revision ID: 75faa7f26436
Revises: 88b552b4ff94
Create Date: 2025-10-03 08:31:45.301188

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '75faa7f26436'
down_revision: Union[str, Sequence[str], None] = ('remove_weekly_enum', '0c116931077e')
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema to support native authentication."""
    # Make supabase_id nullable to support native auth users
    op.alter_column('users', 'supabase_id',
                    existing_type=sa.String(),
                    nullable=True)

    # Add password_hash column for native auth
    op.add_column('users', sa.Column('password_hash', sa.String(), nullable=True))

    # Add auth_provider column to distinguish auth type ('supabase' or 'native')
    op.add_column('users', sa.Column('auth_provider', sa.String(), nullable=False, server_default='supabase'))


def downgrade() -> None:
    """Downgrade schema."""
    # Remove auth_provider column
    op.drop_column('users', 'auth_provider')

    # Remove password_hash column
    op.drop_column('users', 'password_hash')

    # Make supabase_id non-nullable again
    op.alter_column('users', 'supabase_id',
                    existing_type=sa.String(),
                    nullable=False)
