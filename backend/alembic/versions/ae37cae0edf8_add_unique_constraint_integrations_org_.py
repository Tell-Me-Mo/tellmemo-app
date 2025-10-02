"""add_unique_constraint_integrations_org_type

Revision ID: ae37cae0edf8
Revises: beb911d9f703
Create Date: 2025-09-19 14:59:48.559391

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'ae37cae0edf8'
down_revision: Union[str, Sequence[str], None] = 'beb911d9f703'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    # Add unique constraint to ensure one integration per type per organization
    op.create_unique_constraint(
        'uq_integrations_org_type',
        'integrations',
        ['organization_id', 'type']
    )


def downgrade() -> None:
    """Downgrade schema."""
    # Remove unique constraint
    op.drop_constraint('uq_integrations_org_type', 'integrations', type_='unique')
