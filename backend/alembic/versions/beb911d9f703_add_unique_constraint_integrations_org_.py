"""add_unique_constraint_integrations_org_type

Revision ID: beb911d9f703
Revises: 512069f37929
Create Date: 2025-09-19 14:05:47.181999

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'beb911d9f703'
down_revision: Union[str, Sequence[str], None] = '512069f37929'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Add unique constraint on (organization_id, type) to ensure one integration of each type per organization."""
    # Create unique constraint
    op.create_unique_constraint(
        'uq_integrations_organization_type',
        'integrations',
        ['organization_id', 'type']
    )


def downgrade() -> None:
    """Remove unique constraint."""
    # Drop unique constraint
    op.drop_constraint('uq_integrations_organization_type', 'integrations', type_='unique')
