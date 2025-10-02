"""Add recording and transcript tables

Revision ID: 24bf61c4f1fc
Revises: bad13dcc38ff
Create Date: 2025-09-10 12:39:27.073638

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


# revision identifiers, used by Alembic.
revision: str = '24bf61c4f1fc'
down_revision: Union[str, Sequence[str], None] = 'bad13dcc38ff'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    # Create recordings table
    op.create_table('recordings',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('project_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('session_id', sa.String(), nullable=False),
        sa.Column('meeting_title', sa.String(), nullable=False),
        sa.Column('file_path', sa.String(), nullable=False),
        sa.Column('file_size', sa.Integer(), nullable=True),
        sa.Column('duration', sa.Float(), nullable=False),
        sa.Column('sample_rate', sa.Integer(), nullable=True),
        sa.Column('start_time', sa.DateTime(), nullable=False),
        sa.Column('end_time', sa.DateTime(), nullable=False),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.Column('updated_at', sa.DateTime(), nullable=False),
        sa.Column('is_transcribed', sa.Boolean(), nullable=True),
        sa.Column('transcription_status', sa.String(), nullable=True),
        sa.Column('recording_metadata', sa.JSON(), nullable=True),
        sa.ForeignKeyConstraint(['project_id'], ['projects.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('session_id')
    )
    
    # Create index on project_id for faster queries
    op.create_index(op.f('ix_recordings_project_id'), 'recordings', ['project_id'], unique=False)
    op.create_index(op.f('ix_recordings_created_at'), 'recordings', ['created_at'], unique=False)
    
    # Create recording_transcripts table
    op.create_table('recording_transcripts',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('recording_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('full_text', sa.Text(), nullable=False),
        sa.Column('segments', sa.JSON(), nullable=True),
        sa.Column('language', sa.String(), nullable=True),
        sa.Column('language_probability', sa.Float(), nullable=True),
        sa.Column('model_used', sa.String(), nullable=True),
        sa.Column('processing_time', sa.Float(), nullable=True),
        sa.Column('avg_logprob', sa.Float(), nullable=True),
        sa.Column('compression_ratio', sa.Float(), nullable=True),
        sa.Column('no_speech_prob', sa.Float(), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.Column('updated_at', sa.DateTime(), nullable=False),
        sa.Column('recording_metadata', sa.JSON(), nullable=True),
        sa.ForeignKeyConstraint(['recording_id'], ['recordings.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id')
    )
    
    # Create index on recording_id for faster queries
    op.create_index(op.f('ix_recording_transcripts_recording_id'), 'recording_transcripts', ['recording_id'], unique=False)


def downgrade() -> None:
    """Downgrade schema."""
    # Drop indexes
    op.drop_index(op.f('ix_recording_transcripts_recording_id'), table_name='recording_transcripts')
    op.drop_index(op.f('ix_recordings_created_at'), table_name='recordings')
    op.drop_index(op.f('ix_recordings_project_id'), table_name='recordings')
    
    # Drop tables
    op.drop_table('recording_transcripts')
    op.drop_table('recordings')
