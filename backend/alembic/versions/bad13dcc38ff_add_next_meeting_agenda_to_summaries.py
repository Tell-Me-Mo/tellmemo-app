"""add_next_meeting_agenda_to_summaries

Revision ID: bad13dcc38ff
Revises: 3a00877aedfb
Create Date: 2025-09-10 11:29:49.501988

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


# revision identifiers, used by Alembic.
revision: str = 'bad13dcc38ff'
down_revision: Union[str, Sequence[str], None] = '3a00877aedfb'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Add next_meeting_agenda column to summaries table."""
    op.add_column('summaries', 
        sa.Column('next_meeting_agenda', postgresql.JSONB(astext_type=sa.Text()), nullable=True)
    )


def downgrade() -> None:
    """Remove next_meeting_agenda column from summaries table."""
    op.drop_column('summaries', 'next_meeting_agenda')
