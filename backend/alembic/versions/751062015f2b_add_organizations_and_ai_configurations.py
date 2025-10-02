"""add_organizations_and_ai_configurations

Revision ID: 751062015f2b
Revises: 2f2533f00d83
Create Date: 2025-09-18 18:04:22.994328

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql
import uuid

# revision identifiers, used by Alembic.
revision: str = '751062015f2b'
down_revision: Union[str, Sequence[str], None] = '2f2533f00d83'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    # Create organizations table
    op.create_table('organizations',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('name', sa.String(), nullable=False),
        sa.Column('slug', sa.String(), nullable=False),
        sa.Column('is_active', sa.Boolean(), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.Column('updated_at', sa.DateTime(), nullable=False),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('slug')
    )

    # Create AI provider enum
    ai_provider_enum = sa.Enum('claude', 'openai', name='aiprovider')
    ai_provider_enum.create(op.get_bind())

    # Create AI model enum
    ai_model_enum = sa.Enum(
        'claude-3-5-sonnet-latest', 'claude-3-5-haiku-latest', 'claude-3-opus-latest',
        'gpt-4o', 'gpt-4o-mini', 'gpt-4-turbo', 'gpt-3.5-turbo',
        name='aimodel'
    )
    ai_model_enum.create(op.get_bind())

    # Create ai_configurations table
    op.create_table('ai_configurations',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('organization_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('provider', postgresql.ENUM('claude', 'openai', name='aiprovider', create_type=False), nullable=False),
        sa.Column('model', postgresql.ENUM('claude-3-5-sonnet-latest', 'claude-3-5-haiku-latest', 'claude-3-opus-latest',
                                          'gpt-4o', 'gpt-4o-mini', 'gpt-4-turbo', 'gpt-3.5-turbo',
                                          name='aimodel', create_type=False), nullable=False),
        sa.Column('api_key', sa.String(), nullable=False),
        sa.Column('is_active', sa.Boolean(), nullable=True),
        sa.Column('is_default', sa.Boolean(), nullable=True),
        sa.Column('model_settings', sa.JSON(), nullable=True),
        sa.Column('last_used_at', sa.DateTime(), nullable=True),
        sa.Column('total_requests', sa.String(), nullable=True),
        sa.Column('total_tokens_used', sa.String(), nullable=True),
        sa.Column('created_by', sa.String(), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.Column('updated_at', sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(['organization_id'], ['organizations.id'], ),
        sa.PrimaryKeyConstraint('id')
    )

    # Add AI_BRAIN to IntegrationType enum
    op.execute("ALTER TYPE integrationtype ADD VALUE IF NOT EXISTS 'ai_brain'")

    # Create default organization for MVP
    op.execute("""
        INSERT INTO organizations (id, name, slug, is_active, created_at, updated_at)
        VALUES (
            '00000000-0000-0000-0000-000000000001'::uuid,
            'Default Organization',
            'default',
            true,
            NOW(),
            NOW()
        )
    """)


def downgrade() -> None:
    """Downgrade schema."""
    # Drop ai_configurations table
    op.drop_table('ai_configurations')

    # Drop organizations table
    op.drop_table('organizations')

    # Drop enums
    sa.Enum(name='aimodel').drop(op.get_bind())
    sa.Enum(name='aiprovider').drop(op.get_bind())

    # Note: We cannot easily remove AI_BRAIN from integrationtype enum in PostgreSQL
