"""add_portfolio_health_owner_risk_fields

Revision ID: 298a5f7ab449
Revises: 1a2b3c4d5e6f
Create Date: 2025-09-13 17:47:33.385900

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision: str = '298a5f7ab449'
down_revision: Union[str, Sequence[str], None] = '1a2b3c4d5e6f'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    # Create enum type for health status
    health_status_enum = sa.Enum('GREEN', 'AMBER', 'RED', 'NOT_SET', name='healthstatus')
    health_status_enum.create(op.get_bind(), checkfirst=True)

    # Add new columns to portfolios table
    op.add_column('portfolios', sa.Column('owner', sa.String(length=255), nullable=True))
    op.add_column('portfolios', sa.Column('health_status', health_status_enum, server_default='NOT_SET', nullable=False))
    op.add_column('portfolios', sa.Column('risk_summary', sa.Text(), nullable=True))


def downgrade() -> None:
    """Downgrade schema."""
    # Remove columns from portfolios table
    op.drop_column('portfolios', 'risk_summary')
    op.drop_column('portfolios', 'health_status')
    op.drop_column('portfolios', 'owner')

    # Drop enum type
    sa.Enum(name='healthstatus').drop(op.get_bind())
