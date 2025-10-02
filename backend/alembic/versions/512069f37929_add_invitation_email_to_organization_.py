"""add_invitation_email_to_organization_members

Revision ID: 512069f37929
Revises: 9c37bfd8ecb8
Create Date: 2025-09-19 10:54:11.800755

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '512069f37929'
down_revision: Union[str, Sequence[str], None] = '9c37bfd8ecb8'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Add invitation_email column to store email for pending invitations."""
    # Add invitation_email column to organization_members table
    op.add_column('organization_members',
        sa.Column('invitation_email', sa.String(255), nullable=True)
    )

    # Allow user_id to be nullable for pending invitations
    op.alter_column('organization_members', 'user_id',
        existing_type=sa.UUID(),
        nullable=True
    )

    # Update the unique constraint to handle null user_id
    op.drop_constraint('uq_organization_user', 'organization_members')
    op.create_unique_constraint(
        'uq_organization_user',
        'organization_members',
        ['organization_id', 'user_id'],
        postgresql_nulls_not_distinct=False  # Allow multiple null user_ids
    )

    # Add unique constraint for invitation_email per organization
    op.create_unique_constraint(
        'uq_organization_invitation_email',
        'organization_members',
        ['organization_id', 'invitation_email'],
        postgresql_nulls_not_distinct=False
    )


def downgrade() -> None:
    """Remove invitation_email column and restore original constraints."""
    # Drop the new constraints
    op.drop_constraint('uq_organization_invitation_email', 'organization_members')
    op.drop_constraint('uq_organization_user', 'organization_members')

    # Restore original unique constraint
    op.create_unique_constraint(
        'uq_organization_user',
        'organization_members',
        ['organization_id', 'user_id']
    )

    # Make user_id non-nullable again
    op.alter_column('organization_members', 'user_id',
        existing_type=sa.UUID(),
        nullable=False
    )

    # Drop invitation_email column
    op.drop_column('organization_members', 'invitation_email')
