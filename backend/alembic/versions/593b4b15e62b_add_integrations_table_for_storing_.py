"""Add integrations table for storing service configurations

Revision ID: 593b4b15e62b
Revises: 24bf61c4f1fc
Create Date: 2025-09-12 14:28:57.749103

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql
from sqlalchemy import inspect

# revision identifiers, used by Alembic.
revision: str = '593b4b15e62b'
down_revision: Union[str, Sequence[str], None] = '24bf61c4f1fc'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    # Create integrations table
    op.create_table('integrations',
        sa.Column('id', sa.UUID(as_uuid=True), nullable=False),
        sa.Column('type', sa.Enum('fireflies', 'slack', 'teams', 'zoom', name='integrationtype'), nullable=False),
        sa.Column('status', sa.Enum('connected', 'disconnected', 'error', 'pending', name='integrationstatus'), nullable=False),
        sa.Column('api_key', sa.String(), nullable=True),
        sa.Column('webhook_secret', sa.String(), nullable=True),
        sa.Column('auto_sync', sa.Boolean(), nullable=True),
        sa.Column('selected_project_id', sa.UUID(as_uuid=True), nullable=True),
        sa.Column('custom_settings', sa.JSON(), nullable=True),
        sa.Column('connected_at', sa.DateTime(), nullable=True),
        sa.Column('last_sync_at', sa.DateTime(), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.Column('updated_at', sa.DateTime(), nullable=False),
        sa.Column('connected_by', sa.String(), nullable=True),
        sa.Column('error_message', sa.String(), nullable=True),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('type')
    )
    
    # Clean up old tables that are no longer needed
    # Check if tables exist before trying to drop them
    conn = op.get_bind()
    inspector = sa.inspect(conn)
    
    if 'recording_transcripts' in inspector.get_table_names():
        op.drop_index(op.f('ix_recording_transcripts_recording_id'), table_name='recording_transcripts', if_exists=True)
        op.drop_table('recording_transcripts')
    
    if 'recordings' in inspector.get_table_names():
        op.drop_index(op.f('ix_recordings_created_at'), table_name='recordings', if_exists=True)
        op.drop_index(op.f('ix_recordings_project_id'), table_name='recordings', if_exists=True)
        op.drop_table('recordings')


def downgrade() -> None:
    """Downgrade schema."""
    # Drop integrations table
    op.drop_table('integrations')
    
    # Drop the enum types
    op.execute("DROP TYPE IF EXISTS integrationtype")
    op.execute("DROP TYPE IF EXISTS integrationstatus")
    
    # Recreate old tables if needed (optional)
    op.create_table('recordings',
    sa.Column('id', sa.UUID(), autoincrement=False, nullable=False),
    sa.Column('project_id', sa.UUID(), autoincrement=False, nullable=False),
    sa.Column('session_id', sa.VARCHAR(), autoincrement=False, nullable=False),
    sa.Column('meeting_title', sa.VARCHAR(), autoincrement=False, nullable=False),
    sa.Column('file_path', sa.VARCHAR(), autoincrement=False, nullable=False),
    sa.Column('file_size', sa.INTEGER(), autoincrement=False, nullable=True),
    sa.Column('duration', sa.DOUBLE_PRECISION(precision=53), autoincrement=False, nullable=False),
    sa.Column('sample_rate', sa.INTEGER(), autoincrement=False, nullable=True),
    sa.Column('start_time', postgresql.TIMESTAMP(), autoincrement=False, nullable=False),
    sa.Column('end_time', postgresql.TIMESTAMP(), autoincrement=False, nullable=False),
    sa.Column('created_at', postgresql.TIMESTAMP(), autoincrement=False, nullable=False),
    sa.Column('updated_at', postgresql.TIMESTAMP(), autoincrement=False, nullable=False),
    sa.Column('is_transcribed', sa.BOOLEAN(), autoincrement=False, nullable=True),
    sa.Column('transcription_status', sa.VARCHAR(), autoincrement=False, nullable=True),
    sa.Column('recording_metadata', postgresql.JSON(astext_type=sa.Text()), autoincrement=False, nullable=True),
    sa.ForeignKeyConstraint(['project_id'], ['projects.id'], name='recordings_project_id_fkey', ondelete='CASCADE'),
    sa.PrimaryKeyConstraint('id', name='recordings_pkey'),
    sa.UniqueConstraint('session_id', name='recordings_session_id_key', postgresql_include=[], postgresql_nulls_not_distinct=False),
    postgresql_ignore_search_path=False
    )
    op.create_index(op.f('ix_recordings_project_id'), 'recordings', ['project_id'], unique=False)
    op.create_index(op.f('ix_recordings_created_at'), 'recordings', ['created_at'], unique=False)
    op.create_table('recording_transcripts',
    sa.Column('id', sa.UUID(), autoincrement=False, nullable=False),
    sa.Column('recording_id', sa.UUID(), autoincrement=False, nullable=False),
    sa.Column('full_text', sa.TEXT(), autoincrement=False, nullable=False),
    sa.Column('segments', postgresql.JSON(astext_type=sa.Text()), autoincrement=False, nullable=True),
    sa.Column('language', sa.VARCHAR(), autoincrement=False, nullable=True),
    sa.Column('language_probability', sa.DOUBLE_PRECISION(precision=53), autoincrement=False, nullable=True),
    sa.Column('model_used', sa.VARCHAR(), autoincrement=False, nullable=True),
    sa.Column('processing_time', sa.DOUBLE_PRECISION(precision=53), autoincrement=False, nullable=True),
    sa.Column('avg_logprob', sa.DOUBLE_PRECISION(precision=53), autoincrement=False, nullable=True),
    sa.Column('compression_ratio', sa.DOUBLE_PRECISION(precision=53), autoincrement=False, nullable=True),
    sa.Column('no_speech_prob', sa.DOUBLE_PRECISION(precision=53), autoincrement=False, nullable=True),
    sa.Column('created_at', postgresql.TIMESTAMP(), autoincrement=False, nullable=False),
    sa.Column('updated_at', postgresql.TIMESTAMP(), autoincrement=False, nullable=False),
    sa.Column('recording_metadata', postgresql.JSON(astext_type=sa.Text()), autoincrement=False, nullable=True),
    sa.ForeignKeyConstraint(['recording_id'], ['recordings.id'], name=op.f('recording_transcripts_recording_id_fkey'), ondelete='CASCADE'),
    sa.PrimaryKeyConstraint('id', name=op.f('recording_transcripts_pkey'))
    )
    op.create_index(op.f('ix_recording_transcripts_recording_id'), 'recording_transcripts', ['recording_id'], unique=False)
    # ### end Alembic commands ###
