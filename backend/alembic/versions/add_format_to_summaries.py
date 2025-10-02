"""add format to summaries

Revision ID: add_format_to_summaries
Revises: 298a5f7ab449
Create Date: 2025-01-14 12:00:00.000000

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = 'add_format_to_summaries'
down_revision = '298a5f7ab449'
branch_labels = None
depends_on = None


def upgrade():
    # Add format column to summaries table
    op.add_column('summaries', sa.Column('format', sa.String(), nullable=False, server_default='general'))

    # Remove the server default after adding the column
    op.alter_column('summaries', 'format', server_default=None)


def downgrade():
    # Remove format column from summaries table
    op.drop_column('summaries', 'format')