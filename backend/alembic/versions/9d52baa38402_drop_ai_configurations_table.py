"""drop_ai_configurations_table

Revision ID: 9d52baa38402
Revises: 1f43912a2a9b
Create Date: 2025-09-26 11:01:56.840190

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


# revision identifiers, used by Alembic.
revision: str = '9d52baa38402'
down_revision: Union[str, Sequence[str], None] = '1f43912a2a9b'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Drop the ai_configurations table as we're now using integrations table for AI Brain."""
    op.drop_table('ai_configurations')


def downgrade() -> None:
    """Recreate the ai_configurations table."""
    op.create_table('ai_configurations',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('organization_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('provider', sa.Enum('claude', 'openai', 'groq', name='aiprovider'), nullable=False),
        sa.Column('model', sa.Enum('claude-opus-4-1-20250805', 'claude-opus-4-20250522', 'claude-sonnet-4-20250522', 'claude-3-5-sonnet-latest', 'claude-3-5-haiku-latest', 'claude-3-opus-latest', 'gpt-4o', 'gpt-4o-mini', 'gpt-4-turbo', 'gpt-3.5-turbo', name='aimodel'), nullable=False),
        sa.Column('api_key', sa.String(), nullable=False),
        sa.Column('is_active', sa.Boolean(), nullable=True),
        sa.Column('is_default', sa.Boolean(), nullable=True),
        sa.Column('model_settings', postgresql.JSON(astext_type=sa.Text()), nullable=True),
        sa.Column('last_used_at', sa.DateTime(), nullable=True),
        sa.Column('total_requests', sa.String(), nullable=True),
        sa.Column('total_tokens_used', sa.String(), nullable=True),
        sa.Column('created_by', sa.String(), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.Column('updated_at', sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(['organization_id'], ['organizations.id'], ),
        sa.PrimaryKeyConstraint('id')
    )