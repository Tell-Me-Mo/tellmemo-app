"""drop_custom_format_templates_table

Revision ID: ee309bf732c6
Revises: ab03f7be1f9a
Create Date: 2025-09-26 10:49:43.206881

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'ee309bf732c6'
down_revision: Union[str, Sequence[str], None] = 'ab03f7be1f9a'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Drop the custom_format_templates table as it is not being used."""
    # Check if table exists before dropping
    conn = op.get_bind()
    result = conn.execute(sa.text("""
        SELECT EXISTS (
            SELECT 1
            FROM information_schema.tables
            WHERE table_schema = 'public'
            AND table_name = 'custom_format_templates'
        )
    """))
    if result.scalar():
        op.drop_table('custom_format_templates')


def downgrade() -> None:
    """Recreate the custom_format_templates table."""
    op.create_table(
        'custom_format_templates',
        sa.Column('id', sa.UUID(), nullable=False),
        sa.Column('organization_id', sa.UUID(), nullable=False),
        sa.Column('name', sa.String(255), nullable=False),
        sa.Column('template', sa.Text(), nullable=False),
        sa.Column('summary_type', sa.String(50), nullable=False),
        sa.Column('is_active', sa.Boolean(), nullable=False, server_default='true'),
        sa.Column('created_at', sa.DateTime(), nullable=False, server_default=sa.func.now()),
        sa.Column('updated_at', sa.DateTime(), nullable=False, server_default=sa.func.now()),
        sa.Column('created_by', sa.UUID(), nullable=True),
        sa.PrimaryKeyConstraint('id'),
        sa.ForeignKeyConstraint(['organization_id'], ['organizations.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['created_by'], ['users.id'], ondelete='SET NULL'),
        sa.UniqueConstraint('organization_id', 'name', name='uq_custom_format_templates_org_name')
    )
