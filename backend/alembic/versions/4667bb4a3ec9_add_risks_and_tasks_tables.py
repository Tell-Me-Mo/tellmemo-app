"""add_risks_and_tasks_tables

Revision ID: 4667bb4a3ec9
Revises: 37c0e8b8f436
Create Date: 2025-09-18 08:19:37.595591

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '4667bb4a3ec9'
down_revision: Union[str, Sequence[str], None] = '37c0e8b8f436'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    # Create risk severity enum
    op.execute("""
        DO $$ BEGIN
            CREATE TYPE riskseverity AS ENUM ('low', 'medium', 'high', 'critical');
        EXCEPTION
            WHEN duplicate_object THEN null;
        END $$;
    """)

    # Create risk status enum
    op.execute("""
        DO $$ BEGIN
            CREATE TYPE riskstatus AS ENUM ('identified', 'mitigating', 'resolved', 'accepted', 'escalated');
        EXCEPTION
            WHEN duplicate_object THEN null;
        END $$;
    """)

    # Create task status enum
    op.execute("""
        DO $$ BEGIN
            CREATE TYPE taskstatus AS ENUM ('todo', 'in_progress', 'blocked', 'completed', 'cancelled');
        EXCEPTION
            WHEN duplicate_object THEN null;
        END $$;
    """)

    # Create task priority enum
    op.execute("""
        DO $$ BEGIN
            CREATE TYPE taskpriority AS ENUM ('low', 'medium', 'high', 'urgent');
        EXCEPTION
            WHEN duplicate_object THEN null;
        END $$;
    """)

    # Create risks table with raw SQL to avoid enum creation issues
    op.execute("""
        CREATE TABLE IF NOT EXISTS risks (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            project_id UUID NOT NULL REFERENCES projects(id),
            title VARCHAR(200) NOT NULL,
            description TEXT NOT NULL,
            severity riskseverity NOT NULL DEFAULT 'medium',
            status riskstatus NOT NULL DEFAULT 'identified',
            mitigation TEXT,
            impact TEXT,
            probability FLOAT,
            ai_generated VARCHAR(5) DEFAULT 'false',
            ai_confidence FLOAT,
            source_content_id UUID REFERENCES content(id),
            identified_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            resolved_date TIMESTAMP,
            last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_by VARCHAR(50)
        )
    """)

    # Create tasks table with raw SQL
    op.execute("""
        CREATE TABLE IF NOT EXISTS tasks (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            project_id UUID NOT NULL REFERENCES projects(id),
            title VARCHAR(200) NOT NULL,
            description TEXT,
            status taskstatus NOT NULL DEFAULT 'todo',
            priority taskpriority NOT NULL DEFAULT 'medium',
            assignee VARCHAR(100),
            due_date TIMESTAMP,
            completed_date TIMESTAMP,
            progress_percentage INTEGER DEFAULT 0,
            blocker_description TEXT,
            ai_generated VARCHAR(5) DEFAULT 'false',
            ai_confidence FLOAT,
            source_content_id UUID REFERENCES content(id),
            depends_on_risk_id UUID REFERENCES risks(id),
            created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_by VARCHAR(50)
        )
    """)

    # Create indexes for better performance
    op.create_index('ix_risks_project_id', 'risks', ['project_id'])
    op.create_index('ix_risks_status', 'risks', ['status'])
    op.create_index('ix_tasks_project_id', 'tasks', ['project_id'])
    op.create_index('ix_tasks_status', 'tasks', ['status'])


def downgrade() -> None:
    """Downgrade schema."""
    # Drop indexes
    op.drop_index('ix_tasks_status', table_name='tasks')
    op.drop_index('ix_tasks_project_id', table_name='tasks')
    op.drop_index('ix_risks_status', table_name='risks')
    op.drop_index('ix_risks_project_id', table_name='risks')

    # Drop tables
    op.drop_table('tasks')
    op.drop_table('risks')

    # Drop enums
    op.execute("DROP TYPE IF EXISTS taskpriority")
    op.execute("DROP TYPE IF EXISTS taskstatus")
    op.execute("DROP TYPE IF EXISTS riskstatus")
    op.execute("DROP TYPE IF EXISTS riskseverity")
