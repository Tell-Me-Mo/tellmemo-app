"""drop speaker column from live_meeting_insights

Revision ID: 56fcbb99b2d2
Revises: f11cd7beb6f5
Create Date: 2025-11-01 13:45:00.000000

Note: Speaker diarization is not supported in AssemblyAI Universal-Streaming v3 API.
This migration removes the unused speaker column from the live_meeting_insights table.
"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '56fcbb99b2d2'
down_revision = 'f11cd7beb6f5'
branch_labels = None
depends_on = None


def upgrade() -> None:
    """Drop speaker column and its index."""
    # Drop the index first
    op.drop_index('ix_live_meeting_insights_speaker', table_name='live_meeting_insights')

    # Drop the speaker column
    op.drop_column('live_meeting_insights', 'speaker')


def downgrade() -> None:
    """Re-add speaker column and its index."""
    # Add speaker column back
    op.add_column('live_meeting_insights',
        sa.Column('speaker', sa.String(255), nullable=True)
    )

    # Re-create the index
    op.create_index('ix_live_meeting_insights_speaker', 'live_meeting_insights', ['speaker'])
