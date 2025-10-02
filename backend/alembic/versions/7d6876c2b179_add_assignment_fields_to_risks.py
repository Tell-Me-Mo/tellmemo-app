"""add_assignment_fields_to_risks

Revision ID: 7d6876c2b179
Revises: 4690922c511e
Create Date: 2025-09-24 13:57:59.143529

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '7d6876c2b179'
down_revision: Union[str, Sequence[str], None] = '4690922c511e'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    # Add assignment columns to risks table
    op.add_column('risks', sa.Column('assigned_to', sa.String(length=100), nullable=True))
    op.add_column('risks', sa.Column('assigned_to_email', sa.String(length=255), nullable=True))


def downgrade() -> None:
    """Downgrade schema."""
    # Remove assignment columns from risks table
    op.drop_column('risks', 'assigned_to_email')
    op.drop_column('risks', 'assigned_to')
