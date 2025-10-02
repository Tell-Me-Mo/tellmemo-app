"""add_lessons_learned_table

Revision ID: 60c76d7c2f4b
Revises: f19c8c331ae0
Create Date: 2025-09-21 07:41:24.907905

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision: str = '60c76d7c2f4b'
down_revision: Union[str, Sequence[str], None] = 'f19c8c331ae0'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    # Create enums for lesson learned (if they don't exist)
    op.execute("""
        DO $$ BEGIN
            CREATE TYPE lessoncategory AS ENUM ('technical', 'process', 'communication', 'planning', 'resource', 'quality', 'other');
        EXCEPTION
            WHEN duplicate_object THEN null;
        END $$;
    """)

    op.execute("""
        DO $$ BEGIN
            CREATE TYPE lessontype AS ENUM ('success', 'improvement', 'challenge', 'best_practice');
        EXCEPTION
            WHEN duplicate_object THEN null;
        END $$;
    """)

    op.execute("""
        DO $$ BEGIN
            CREATE TYPE lessonlearnedimpact AS ENUM ('low', 'medium', 'high');
        EXCEPTION
            WHEN duplicate_object THEN null;
        END $$;
    """)

    # Create lessons_learned table
    op.create_table('lessons_learned',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('project_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('title', sa.String(length=200), nullable=False),
        sa.Column('description', sa.Text(), nullable=False),
        sa.Column('category', postgresql.ENUM('technical', 'process', 'communication', 'planning', 'resource', 'quality', 'other', name='lessoncategory', create_type=False), nullable=False),
        sa.Column('lesson_type', postgresql.ENUM('success', 'improvement', 'challenge', 'best_practice', name='lessontype', create_type=False), nullable=False),
        sa.Column('impact', postgresql.ENUM('low', 'medium', 'high', name='lessonlearnedimpact', create_type=False), nullable=False),
        sa.Column('recommendation', sa.Text(), nullable=True),
        sa.Column('context', sa.Text(), nullable=True),
        sa.Column('tags', sa.String(length=500), nullable=True),
        sa.Column('ai_generated', sa.String(length=5), nullable=True),
        sa.Column('ai_confidence', sa.Float(), nullable=True),
        sa.Column('source_content_id', postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column('identified_date', sa.DateTime(), nullable=True),
        sa.Column('last_updated', sa.DateTime(), nullable=True),
        sa.Column('updated_by', sa.String(length=50), nullable=True),
        sa.ForeignKeyConstraint(['project_id'], ['projects.id'], ),
        sa.ForeignKeyConstraint(['source_content_id'], ['content.id'], ),
        sa.PrimaryKeyConstraint('id')
    )

    # Create index for faster queries
    op.create_index('ix_lessons_learned_project_id', 'lessons_learned', ['project_id'], unique=False)
    op.create_index('ix_lessons_learned_category', 'lessons_learned', ['category'], unique=False)
    op.create_index('ix_lessons_learned_lesson_type', 'lessons_learned', ['lesson_type'], unique=False)


def downgrade() -> None:
    """Downgrade schema."""
    # Drop indexes
    op.drop_index('ix_lessons_learned_lesson_type', table_name='lessons_learned')
    op.drop_index('ix_lessons_learned_category', table_name='lessons_learned')
    op.drop_index('ix_lessons_learned_project_id', table_name='lessons_learned')

    # Drop table
    op.drop_table('lessons_learned')

    # Drop enums
    op.execute("DROP TYPE lessonlearnedimpact")
    op.execute("DROP TYPE lessontype")
    op.execute("DROP TYPE lessoncategory")
