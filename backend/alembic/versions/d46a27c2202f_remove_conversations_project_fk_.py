"""remove_conversations_project_fk_constraint

Revision ID: d46a27c2202f
Revises: 34f233d35b44
Create Date: 2025-09-30 08:30:43.958304

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'd46a27c2202f'
down_revision: Union[str, Sequence[str], None] = '34f233d35b44'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    # Drop the foreign key constraint to allow conversations for programs and portfolios
    # Check if constraint exists first
    conn = op.get_bind()
    result = conn.execute(sa.text("""
        SELECT constraint_name
        FROM information_schema.table_constraints
        WHERE table_name = 'conversations'
        AND constraint_name = 'conversations_project_id_fkey'
    """))
    if result.fetchone():
        op.drop_constraint('conversations_project_id_fkey', 'conversations', type_='foreignkey')


def downgrade() -> None:
    """Downgrade schema."""
    # Restore the foreign key constraint
    op.create_foreign_key(
        'conversations_project_id_fkey',
        'conversations',
        'projects',
        ['project_id'],
        ['id'],
        ondelete='CASCADE'
    )
