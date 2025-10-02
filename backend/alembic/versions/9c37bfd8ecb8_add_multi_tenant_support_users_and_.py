"""add_multi_tenant_support_users_and_organization_members

Revision ID: 9c37bfd8ecb8
Revises: b408f4b81c80
Create Date: 2025-09-19 07:27:32.509035

"""
from typing import Sequence, Union
import uuid
from datetime import datetime

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


# revision identifiers, used by Alembic.
revision: str = '9c37bfd8ecb8'
down_revision: Union[str, Sequence[str], None] = 'b408f4b81c80'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema for multi-tenant support."""

    # Create users table
    op.create_table('users',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False, default=uuid.uuid4),
        sa.Column('supabase_id', sa.String(), nullable=False),
        sa.Column('email', sa.String(), nullable=False),
        sa.Column('name', sa.String(), nullable=True),
        sa.Column('avatar_url', sa.String(), nullable=True),
        sa.Column('preferences', sa.JSON(), nullable=True, default=dict),
        sa.Column('last_active_organization_id', postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column('is_active', sa.Boolean(), nullable=True, default=True),
        sa.Column('email_verified', sa.Boolean(), nullable=True, default=False),
        sa.Column('created_at', sa.DateTime(), nullable=False, default=datetime.utcnow),
        sa.Column('updated_at', sa.DateTime(), nullable=False, default=datetime.utcnow),
        sa.Column('last_login_at', sa.DateTime(), nullable=True),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('supabase_id'),
        sa.UniqueConstraint('email')
    )

    # Update organizations table to add new columns
    op.add_column('organizations', sa.Column('description', sa.String(), nullable=True))
    op.add_column('organizations', sa.Column('logo_url', sa.String(), nullable=True))
    op.add_column('organizations', sa.Column('settings', sa.JSON(), nullable=True, default=dict))
    op.add_column('organizations', sa.Column('created_by', postgresql.UUID(as_uuid=True), nullable=True))

    # Add foreign key constraint for created_by after users table exists
    op.create_foreign_key('fk_organizations_created_by', 'organizations', 'users', ['created_by'], ['id'], ondelete='SET NULL')

    # Create organization_members junction table
    op.create_table('organization_members',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False, default=uuid.uuid4),
        sa.Column('organization_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('role', postgresql.ENUM('admin', 'member', 'viewer', name='organizationrole', create_type=True), nullable=False, default='member'),
        sa.Column('invited_by', postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column('invitation_token', sa.String(), nullable=True),
        sa.Column('invitation_sent_at', sa.DateTime(), nullable=True),
        sa.Column('joined_at', sa.DateTime(), nullable=False, default=datetime.utcnow),
        sa.Column('updated_at', sa.DateTime(), nullable=False, default=datetime.utcnow),
        sa.ForeignKeyConstraint(['organization_id'], ['organizations.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['invited_by'], ['users.id'], ondelete='SET NULL'),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('organization_id', 'user_id', name='uq_organization_user'),
        sa.UniqueConstraint('invitation_token')
    )

    # Add organization_id to portfolios table
    op.add_column('portfolios', sa.Column('organization_id', postgresql.UUID(as_uuid=True), nullable=True))

    # Add organization_id to programs table
    op.add_column('programs', sa.Column('organization_id', postgresql.UUID(as_uuid=True), nullable=True))

    # Add organization_id to projects table
    op.add_column('projects', sa.Column('organization_id', postgresql.UUID(as_uuid=True), nullable=True))

    # Add organization_id to integrations table
    op.add_column('integrations', sa.Column('organization_id', postgresql.UUID(as_uuid=True), nullable=True))

    # Remove unique constraint from integrations.type since it will now be unique per organization
    op.drop_constraint('integrations_type_key', 'integrations', type_='unique')

    # Create a default user for migration
    default_user_id = uuid.uuid4()
    op.execute(f"""
        INSERT INTO users (id, supabase_id, email, name, is_active, email_verified, created_at, updated_at)
        VALUES ('{default_user_id}', 'default-migration-user', 'admin@default.com', 'Default Admin', true, true, NOW(), NOW())
    """)

    # Get the default organization ID (should already exist)
    default_org_id = '00000000-0000-0000-0000-000000000001'

    # Update the default organization to have a creator
    op.execute(f"""
        UPDATE organizations
        SET created_by = '{default_user_id}',
            settings = '{{"timezone": "UTC", "locale": "en-US"}}'::jsonb
        WHERE id = '{default_org_id}'
    """)

    # Create an admin membership for default user in default organization
    op.execute(f"""
        INSERT INTO organization_members (id, organization_id, user_id, role, joined_at, updated_at)
        VALUES ('{uuid.uuid4()}', '{default_org_id}', '{default_user_id}', 'admin', NOW(), NOW())
    """)

    # Update existing data to use default organization
    op.execute(f"UPDATE portfolios SET organization_id = '{default_org_id}' WHERE organization_id IS NULL")
    op.execute(f"UPDATE programs SET organization_id = '{default_org_id}' WHERE organization_id IS NULL")
    op.execute(f"UPDATE projects SET organization_id = '{default_org_id}' WHERE organization_id IS NULL")
    op.execute(f"UPDATE integrations SET organization_id = '{default_org_id}' WHERE organization_id IS NULL")

    # Now make organization_id NOT NULL after setting values
    op.alter_column('portfolios', 'organization_id', nullable=False)
    op.alter_column('programs', 'organization_id', nullable=False)
    op.alter_column('projects', 'organization_id', nullable=False)
    op.alter_column('integrations', 'organization_id', nullable=False)

    # Add foreign key constraints
    op.create_foreign_key('fk_portfolios_organization', 'portfolios', 'organizations', ['organization_id'], ['id'], ondelete='CASCADE')
    op.create_foreign_key('fk_programs_organization', 'programs', 'organizations', ['organization_id'], ['id'], ondelete='CASCADE')
    op.create_foreign_key('fk_projects_organization', 'projects', 'organizations', ['organization_id'], ['id'], ondelete='CASCADE')
    op.create_foreign_key('fk_integrations_organization', 'integrations', 'organizations', ['organization_id'], ['id'], ondelete='CASCADE')

    # Create composite indexes for better query performance
    op.create_index('idx_projects_organization_id', 'projects', ['organization_id'])
    op.create_index('idx_portfolios_organization_id', 'portfolios', ['organization_id'])
    op.create_index('idx_programs_organization_id', 'programs', ['organization_id'])
    op.create_index('idx_integrations_organization_type', 'integrations', ['organization_id', 'type'])
    op.create_index('idx_organization_members_org', 'organization_members', ['organization_id'])
    op.create_index('idx_organization_members_user', 'organization_members', ['user_id'])


def downgrade() -> None:
    """Downgrade schema - remove multi-tenant support."""

    # Drop indexes
    op.drop_index('idx_organization_members_user', 'organization_members')
    op.drop_index('idx_organization_members_org', 'organization_members')
    op.drop_index('idx_integrations_organization_type', 'integrations')
    op.drop_index('idx_programs_organization_id', 'programs')
    op.drop_index('idx_portfolios_organization_id', 'portfolios')
    op.drop_index('idx_projects_organization_id', 'projects')

    # Drop foreign key constraints
    op.drop_constraint('fk_integrations_organization', 'integrations', type_='foreignkey')
    op.drop_constraint('fk_projects_organization', 'projects', type_='foreignkey')
    op.drop_constraint('fk_programs_organization', 'programs', type_='foreignkey')
    op.drop_constraint('fk_portfolios_organization', 'portfolios', type_='foreignkey')

    # Remove organization_id columns
    op.drop_column('integrations', 'organization_id')
    op.drop_column('projects', 'organization_id')
    op.drop_column('programs', 'organization_id')
    op.drop_column('portfolios', 'organization_id')

    # Re-add unique constraint to integrations.type
    op.create_unique_constraint('integrations_type_key', 'integrations', ['type'])

    # Drop organization_members table
    op.drop_table('organization_members')

    # Remove foreign key and columns from organizations
    op.drop_constraint('fk_organizations_created_by', 'organizations', type_='foreignkey')
    op.drop_column('organizations', 'created_by')
    op.drop_column('organizations', 'settings')
    op.drop_column('organizations', 'logo_url')
    op.drop_column('organizations', 'description')

    # Drop users table
    op.drop_table('users')

    # Drop enum type
    op.execute("DROP TYPE organizationrole")