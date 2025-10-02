"""fix_portfolio_program_project_unique_constraints_per_org

Revision ID: 1d4bd197002a
Revises: 60c76d7c2f4b
Create Date: 2025-09-22 16:19:59.451614

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '1d4bd197002a'
down_revision: Union[str, Sequence[str], None] = '60c76d7c2f4b'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema - Fix unique constraints to be per organization."""

    # Drop existing global unique constraint on portfolios only (others don't exist)
    op.drop_constraint('portfolios_name_key', 'portfolios', type_='unique')

    # Create new unique constraints that are per organization/parent
    op.create_unique_constraint(
        'portfolios_name_organization_id_key',
        'portfolios',
        ['name', 'organization_id']
    )
    op.create_unique_constraint(
        'programs_name_portfolio_id_key',
        'programs',
        ['name', 'portfolio_id']
    )
    op.create_unique_constraint(
        'projects_name_program_id_key',
        'projects',
        ['name', 'program_id']
    )
    # Also add constraint for projects directly under portfolios
    op.create_unique_constraint(
        'projects_name_portfolio_id_key',
        'projects',
        ['name', 'portfolio_id']
    )


def downgrade() -> None:
    """Downgrade schema - Revert to global unique constraints."""

    # Drop per-organization unique constraints
    op.drop_constraint('portfolios_name_organization_id_key', 'portfolios', type_='unique')
    op.drop_constraint('programs_name_portfolio_id_key', 'programs', type_='unique')
    op.drop_constraint('projects_name_program_id_key', 'projects', type_='unique')
    op.drop_constraint('projects_name_portfolio_id_key', 'projects', type_='unique')

    # Recreate only the original global unique constraint on portfolios
    op.create_unique_constraint('portfolios_name_key', 'portfolios', ['name'])
