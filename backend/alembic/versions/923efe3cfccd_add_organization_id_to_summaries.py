"""add_organization_id_to_summaries

Revision ID: 923efe3cfccd
Revises: ae37cae0edf8
Create Date: 2025-09-19 19:25:09.829846

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


# revision identifiers, used by Alembic.
revision: str = '923efe3cfccd'
down_revision: Union[str, Sequence[str], None] = 'ae37cae0edf8'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Add organization_id to summaries table for multi-tenant support."""

    # Add organization_id column to summaries table
    op.add_column('summaries', sa.Column('organization_id', postgresql.UUID(as_uuid=True), nullable=True))

    # Set default organization for existing summaries by using the organization_id from their associated project
    op.execute("""
        UPDATE summaries
        SET organization_id = projects.organization_id
        FROM projects
        WHERE summaries.project_id = projects.id
        AND summaries.organization_id IS NULL
    """)

    # For summaries without project_id (program/portfolio summaries), set to default organization
    default_org_id = '00000000-0000-0000-0000-000000000001'
    op.execute(f"""
        UPDATE summaries
        SET organization_id = '{default_org_id}'
        WHERE organization_id IS NULL
    """)

    # Make organization_id NOT NULL after setting values
    op.alter_column('summaries', 'organization_id', nullable=False)

    # Add foreign key constraint
    op.create_foreign_key('fk_summaries_organization', 'summaries', 'organizations', ['organization_id'], ['id'], ondelete='CASCADE')

    # Add index for better query performance
    op.create_index('idx_summaries_organization_id', 'summaries', ['organization_id'])


def downgrade() -> None:
    """Remove organization_id from summaries table."""

    # Drop index and foreign key constraint
    op.drop_index('idx_summaries_organization_id', 'summaries')
    op.drop_constraint('fk_summaries_organization', 'summaries', type_='foreignkey')

    # Drop organization_id column
    op.drop_column('summaries', 'organization_id')
