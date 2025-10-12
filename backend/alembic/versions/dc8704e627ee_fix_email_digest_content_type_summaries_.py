"""fix_email_digest_content_type_summaries_to_blockers

Revision ID: dc8704e627ee
Revises: d87374cb7d30
Create Date: 2025-10-12 17:20:10.587533

Fixes:
- Updates existing users' email_digest preferences to replace 'summaries' with 'blockers'
- The previous migration (d87374cb7d30) incorrectly set 'summaries' as a content type,
  but the code expects 'blockers' (see routers/email_preferences.py ContentType enum)
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'dc8704e627ee'
down_revision: Union[str, Sequence[str], None] = 'd87374cb7d30'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Replace 'summaries' with 'blockers' in email_digest content_types."""

    # Update all users who have 'summaries' in their email_digest content_types
    # Replace 'summaries' with 'blockers' using PostgreSQL JSONB array manipulation
    # Uses CTE to avoid set-returning functions in WHERE clause
    op.execute("""
        WITH users_to_update AS (
            SELECT
                id,
                preferences::jsonb AS prefs,
                preferences::jsonb->'email_digest'->'content_types' AS content_types
            FROM users
            WHERE preferences::jsonb ? 'email_digest'
              AND preferences::jsonb->'email_digest' ? 'content_types'
              AND preferences::jsonb->'email_digest'->'content_types' @> '"summaries"'::jsonb
        ),
        updated_content_types AS (
            SELECT
                id,
                prefs,
                (
                    SELECT jsonb_agg(DISTINCT new_value)
                    FROM (
                        SELECT value AS new_value
                        FROM jsonb_array_elements_text(content_types) AS value
                        WHERE value != 'summaries'
                        UNION ALL
                        SELECT 'blockers'
                    ) AS combined
                ) AS new_content_types
            FROM users_to_update
        )
        UPDATE users
        SET preferences = (
            updated_content_types.prefs ||
            jsonb_build_object(
                'email_digest',
                (updated_content_types.prefs->'email_digest' ||
                 jsonb_build_object('content_types', updated_content_types.new_content_types)
                )
            )
        )::json
        FROM updated_content_types
        WHERE users.id = updated_content_types.id;
    """)


def downgrade() -> None:
    """Revert 'blockers' back to 'summaries' in email_digest content_types."""

    # Revert the change - replace 'blockers' with 'summaries'
    # Uses CTE to avoid set-returning functions in WHERE clause
    op.execute("""
        WITH users_to_update AS (
            SELECT
                id,
                preferences::jsonb AS prefs,
                preferences::jsonb->'email_digest'->'content_types' AS content_types
            FROM users
            WHERE preferences::jsonb ? 'email_digest'
              AND preferences::jsonb->'email_digest' ? 'content_types'
              AND preferences::jsonb->'email_digest'->'content_types' @> '"blockers"'::jsonb
        ),
        updated_content_types AS (
            SELECT
                id,
                prefs,
                (
                    SELECT jsonb_agg(DISTINCT new_value)
                    FROM (
                        SELECT value AS new_value
                        FROM jsonb_array_elements_text(content_types) AS value
                        WHERE value != 'blockers'
                        UNION ALL
                        SELECT 'summaries'
                    ) AS combined
                ) AS new_content_types
            FROM users_to_update
        )
        UPDATE users
        SET preferences = (
            updated_content_types.prefs ||
            jsonb_build_object(
                'email_digest',
                (updated_content_types.prefs->'email_digest' ||
                 jsonb_build_object('content_types', updated_content_types.new_content_types)
                )
            )
        )::json
        FROM updated_content_types
        WHERE users.id = updated_content_types.id;
    """)
