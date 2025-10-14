"""add_item_updates_table

Revision ID: 6d218df43825
Revises: dc8704e627ee
Create Date: 2025-10-14 17:55:39.950950

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import UUID


# revision identifiers, used by Alembic.
revision: str = '6d218df43825'
down_revision: Union[str, Sequence[str], None] = 'dc8704e627ee'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    op.create_table(
        'item_updates',
        sa.Column('id', UUID(as_uuid=True), primary_key=True),
        sa.Column('project_id', UUID(as_uuid=True), sa.ForeignKey('projects.id', ondelete='CASCADE'), nullable=False),
        sa.Column('item_id', UUID(as_uuid=True), nullable=False),
        sa.Column('item_type', sa.String(50), nullable=False),
        sa.Column('content', sa.Text(), nullable=False),
        sa.Column('update_type', sa.Enum('COMMENT', 'STATUS_CHANGE', 'ASSIGNMENT', 'EDIT', 'CREATED', name='itemupdatetype'), nullable=False),
        sa.Column('author_name', sa.String(100), nullable=False),
        sa.Column('author_email', sa.String(255), nullable=True),
        sa.Column('timestamp', sa.DateTime(), nullable=False),
    )

    # Create indexes for better query performance
    op.create_index('ix_item_updates_project_id', 'item_updates', ['project_id'])
    op.create_index('ix_item_updates_item_lookup', 'item_updates', ['project_id', 'item_id', 'item_type'])
    op.create_index('ix_item_updates_timestamp', 'item_updates', ['timestamp'])


def downgrade() -> None:
    """Downgrade schema."""
    op.drop_index('ix_item_updates_timestamp', 'item_updates')
    op.drop_index('ix_item_updates_item_lookup', 'item_updates')
    op.drop_index('ix_item_updates_project_id', 'item_updates')
    op.drop_table('item_updates')
    op.execute('DROP TYPE itemupdatetype')
