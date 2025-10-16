"""fix_add_title_embedding_columns_if_missing

Revision ID: 729cd7038d25
Revises: 77dd4a4b845e
Create Date: 2025-10-16 16:06:00.950573

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '729cd7038d25'
down_revision: Union[str, Sequence[str], None] = '77dd4a4b845e'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Add title_embedding columns if they don't exist.

    This migration fixes an issue where migration 77dd4a4b845e was marked as applied
    but the columns were not actually created in some databases.
    """
    # Use raw SQL with IF NOT EXISTS to safely add columns
    conn = op.get_bind()

    # Add title_embedding to risks table
    conn.execute(sa.text("""
        ALTER TABLE risks
        ADD COLUMN IF NOT EXISTS title_embedding JSON
    """))

    # Add title_embedding to tasks table
    conn.execute(sa.text("""
        ALTER TABLE tasks
        ADD COLUMN IF NOT EXISTS title_embedding JSON
    """))

    # Add title_embedding to blockers table
    conn.execute(sa.text("""
        ALTER TABLE blockers
        ADD COLUMN IF NOT EXISTS title_embedding JSON
    """))

    # Add title_embedding to lessons_learned table
    conn.execute(sa.text("""
        ALTER TABLE lessons_learned
        ADD COLUMN IF NOT EXISTS title_embedding JSON
    """))


def downgrade() -> None:
    """Remove title_embedding columns.

    Note: This only removes columns if they exist, to match the upgrade behavior.
    """
    # Use raw SQL with IF EXISTS to safely remove columns
    conn = op.get_bind()

    # Drop title_embedding from lessons_learned table
    conn.execute(sa.text("""
        ALTER TABLE lessons_learned
        DROP COLUMN IF EXISTS title_embedding
    """))

    # Drop title_embedding from blockers table
    conn.execute(sa.text("""
        ALTER TABLE blockers
        DROP COLUMN IF EXISTS title_embedding
    """))

    # Drop title_embedding from tasks table
    conn.execute(sa.text("""
        ALTER TABLE tasks
        DROP COLUMN IF EXISTS title_embedding
    """))

    # Drop title_embedding from risks table
    conn.execute(sa.text("""
        ALTER TABLE risks
        DROP COLUMN IF EXISTS title_embedding
    """))
