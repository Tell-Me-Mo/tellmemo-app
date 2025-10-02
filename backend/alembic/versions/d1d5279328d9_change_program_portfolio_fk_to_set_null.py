"""change_program_portfolio_fk_to_set_null

Revision ID: d1d5279328d9
Revises: 26a5373f07f5
Create Date: 2025-09-24 15:47:10.126691

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'd1d5279328d9'
down_revision: Union[str, Sequence[str], None] = '26a5373f07f5'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Change program portfolio_id foreign key from CASCADE to SET NULL."""

    # Drop existing foreign key constraint
    op.drop_constraint('programs_portfolio_id_fkey', 'programs', type_='foreignkey')

    # Add new foreign key constraint with SET NULL
    op.create_foreign_key(
        'programs_portfolio_id_fkey',
        'programs',
        'portfolios',
        ['portfolio_id'],
        ['id'],
        ondelete='SET NULL'
    )


def downgrade() -> None:
    """Revert program portfolio_id foreign key from SET NULL to CASCADE."""

    # Drop SET NULL foreign key constraint
    op.drop_constraint('programs_portfolio_id_fkey', 'programs', type_='foreignkey')

    # Add back CASCADE foreign key constraint
    op.create_foreign_key(
        'programs_portfolio_id_fkey',
        'programs',
        'portfolios',
        ['portfolio_id'],
        ['id'],
        ondelete='CASCADE'
    )
