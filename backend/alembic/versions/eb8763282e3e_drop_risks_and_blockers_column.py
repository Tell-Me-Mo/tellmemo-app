"""drop_risks_and_blockers_column

Revision ID: eb8763282e3e
Revises: 3238b6418cbd
Create Date: 2025-09-27 06:14:54.126842

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'eb8763282e3e'
down_revision: Union[str, Sequence[str], None] = '3238b6418cbd'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Drop the deprecated risks_and_blockers column."""
    op.drop_column('summaries', 'risks_and_blockers')


def downgrade() -> None:
    """Re-add risks_and_blockers column and combine data back."""
    from sqlalchemy.dialects import postgresql

    # Re-add the column
    op.add_column('summaries',
        sa.Column('risks_and_blockers', postgresql.JSONB(astext_type=sa.Text()), nullable=True)
    )

    # Combine risks and blockers back into risks_and_blockers
    op.execute("""
        UPDATE summaries
        SET risks_and_blockers = jsonb_build_object(
            'risks', COALESCE(risks, '[]'::jsonb),
            'blockers', COALESCE(blockers, '[]'::jsonb)
        )
        WHERE risks IS NOT NULL OR blockers IS NOT NULL
    """)
