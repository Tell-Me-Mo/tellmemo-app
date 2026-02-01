"""merge_multiple_heads

Revision ID: b507803113ba
Revises: 354e5237a23b, 56fcbb99b2d2
Create Date: 2026-02-01 12:25:30.279564

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'b507803113ba'
down_revision: Union[str, Sequence[str], None] = ('354e5237a23b', '56fcbb99b2d2')
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    pass


def downgrade() -> None:
    """Downgrade schema."""
    pass
