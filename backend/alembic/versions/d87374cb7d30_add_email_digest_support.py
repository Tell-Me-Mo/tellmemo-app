"""add_email_digest_support

Revision ID: d87374cb7d30
Revises: 1056eb2594d0
Create Date: 2025-10-12 09:53:03.861179

Adds:
- New email notification categories (EMAIL_DIGEST_SENT, EMAIL_ONBOARDING_SENT, EMAIL_INACTIVE_REMINDER_SENT)
- Performance indexes for email digest queries
- Default email preferences for existing users
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


# revision identifiers, used by Alembic.
revision: str = 'd87374cb7d30'
down_revision: Union[str, Sequence[str], None] = '1056eb2594d0'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Add email digest support."""

    # 1. Add new notification categories to the enum
    # PostgreSQL requires ALTER TYPE for adding enum values
    op.execute("""
        ALTER TYPE notificationcategory ADD VALUE IF NOT EXISTS 'email_digest_sent';
    """)
    op.execute("""
        ALTER TYPE notificationcategory ADD VALUE IF NOT EXISTS 'email_onboarding_sent';
    """)
    op.execute("""
        ALTER TYPE notificationcategory ADD VALUE IF NOT EXISTS 'email_inactive_reminder_sent';
    """)

    # 2. Create performance indexes for email digest queries

    # Index on users preferences for digest queries (GIN index for JSONB)
    op.execute("""
        CREATE INDEX IF NOT EXISTS idx_users_preferences_digest
        ON users USING GIN (preferences);
    """)

    # Composite index for activity queries (inactive user detection)
    op.execute("""
        CREATE INDEX IF NOT EXISTS idx_activities_user_created
        ON activities (user_id, created_at DESC);
    """)

    # Composite index for notification queries (check if email sent)
    op.execute("""
        CREATE INDEX IF NOT EXISTS idx_notifications_user_category
        ON notifications (user_id, category, created_at DESC);
    """)

    # Index for summaries by project and date (digest content)
    op.execute("""
        CREATE INDEX IF NOT EXISTS idx_summaries_project_created
        ON summaries (project_id, created_at DESC);
    """)

    # Index for tasks by assignee and due date (digest content)
    op.execute("""
        CREATE INDEX IF NOT EXISTS idx_tasks_assignee_due
        ON tasks (assigned_to, due_date) WHERE assigned_to IS NOT NULL;
    """)

    # 3. Set default email preferences for existing users
    # New users will get these defaults during registration
    op.execute("""
        UPDATE users
        SET preferences = COALESCE(preferences, '{}'::jsonb) ||
            jsonb_build_object(
                'email_digest', jsonb_build_object(
                    'enabled', false,
                    'frequency', 'weekly',
                    'content_types', ARRAY['summaries', 'tasks_assigned', 'risks_critical']::text[],
                    'project_filter', 'all',
                    'include_portfolio_rollup', true,
                    'last_sent_at', NULL
                )
            )
        WHERE preferences IS NULL
           OR NOT preferences ? 'email_digest';
    """)


def downgrade() -> None:
    """Remove email digest support."""

    # Drop indexes
    op.execute("DROP INDEX IF EXISTS idx_tasks_assignee_due;")
    op.execute("DROP INDEX IF EXISTS idx_summaries_project_created;")
    op.execute("DROP INDEX IF EXISTS idx_notifications_user_category;")
    op.execute("DROP INDEX IF EXISTS idx_activities_user_created;")
    op.execute("DROP INDEX IF EXISTS idx_users_preferences_digest;")

    # Remove email_digest preferences from users
    op.execute("""
        UPDATE users
        SET preferences = preferences - 'email_digest'
        WHERE preferences ? 'email_digest';
    """)

    # Note: PostgreSQL doesn't support removing enum values
    # The new notification categories will remain in the enum
    # This is safe and follows PostgreSQL best practices
