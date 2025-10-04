"""Add activities table

Revision ID: 003_add_activities
Revises: 002_initial_schema
Create Date: 2025-09-09 08:20:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision: str = '003_add_activities'
down_revision: Union[str, None] = 'da58a5f71a6b'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Create activity type enum using SQLAlchemy's Enum
    activity_type_enum = sa.Enum(
        'PROJECT_CREATED', 'PROJECT_UPDATED', 'PROJECT_DELETED',
        'CONTENT_UPLOADED', 'SUMMARY_GENERATED', 'QUERY_SUBMITTED',
        'REPORT_GENERATED', 'MEMBER_ADDED', 'MEMBER_REMOVED',
        name='activitytype'
    )

    # Create activities table
    op.create_table(
        'activities',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False, primary_key=True),
        sa.Column('project_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('type', activity_type_enum, nullable=False),
        sa.Column('title', sa.String(255), nullable=False),
        sa.Column('description', sa.Text(), nullable=False),
        sa.Column('metadata', sa.Text(), nullable=True),
        sa.Column('timestamp', sa.DateTime(), nullable=False),
        sa.Column('user_id', sa.String(255), nullable=True),
        sa.Column('user_name', sa.String(255), nullable=True),
        sa.ForeignKeyConstraint(['project_id'], ['projects.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id')
    )
    
    # Create indexes
    op.create_index('idx_activities_project_id', 'activities', ['project_id'])
    op.create_index('idx_activities_timestamp', 'activities', ['timestamp'])
    op.create_index('idx_activities_type', 'activities', ['type'])


def downgrade() -> None:
    # Drop indexes
    op.drop_index('idx_activities_type', table_name='activities')
    op.drop_index('idx_activities_timestamp', table_name='activities')
    op.drop_index('idx_activities_project_id', table_name='activities')

    # Drop table
    op.drop_table('activities')

    # Drop enum type using SQLAlchemy's Enum
    activity_type_enum = sa.Enum(name='activitytype')
    activity_type_enum.drop(op.get_bind())