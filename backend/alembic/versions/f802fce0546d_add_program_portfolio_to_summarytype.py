"""add_program_portfolio_to_summarytype

Revision ID: f802fce0546d
Revises: add_format_to_summaries
Create Date: 2025-09-14 12:10:08.104137

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'f802fce0546d'
down_revision: Union[str, Sequence[str], None] = 'add_format_to_summaries'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    # Add new values to the summarytype enum
    op.execute("ALTER TYPE summarytype ADD VALUE IF NOT EXISTS 'PROGRAM'")
    op.execute("ALTER TYPE summarytype ADD VALUE IF NOT EXISTS 'PORTFOLIO'")


def downgrade() -> None:
    """Downgrade schema."""
    # Note: PostgreSQL doesn't support removing values from enums easily
    # The downgrade would require recreating the enum type and all dependent columns
    # For simplicity, we'll leave a comment about manual intervention if needed
    pass  # Manual intervention required to remove enum values
