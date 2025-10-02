"""change_enums_to_lowercase

Revision ID: 2f2533f00d83
Revises: 4667bb4a3ec9
Create Date: 2025-09-18 15:58:39.007516

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '2f2533f00d83'
down_revision: Union[str, Sequence[str], None] = '4667bb4a3ec9'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Convert enum values to lowercase by recreating enums."""

    # PostgreSQL enums can't be altered directly, so we need to:
    # 1. Create new enums with lowercase values
    # 2. Alter columns to use new enums
    # 3. Drop old enums

    # Create new enums with lowercase values
    op.execute("CREATE TYPE riskseverity_new AS ENUM ('low', 'medium', 'high', 'critical')")
    op.execute("CREATE TYPE riskstatus_new AS ENUM ('identified', 'mitigating', 'resolved', 'accepted', 'escalated')")
    op.execute("CREATE TYPE taskstatus_new AS ENUM ('todo', 'in_progress', 'blocked', 'completed', 'cancelled')")
    op.execute("CREATE TYPE taskpriority_new AS ENUM ('low', 'medium', 'high', 'urgent')")

    # Drop defaults first to avoid cast errors
    op.execute("ALTER TABLE risks ALTER COLUMN severity DROP DEFAULT")
    op.execute("ALTER TABLE risks ALTER COLUMN status DROP DEFAULT")
    op.execute("ALTER TABLE tasks ALTER COLUMN status DROP DEFAULT")
    op.execute("ALTER TABLE tasks ALTER COLUMN priority DROP DEFAULT")

    # Update risks table
    op.execute("""
        ALTER TABLE risks
        ALTER COLUMN severity TYPE riskseverity_new
        USING LOWER(severity::text)::riskseverity_new
    """)

    op.execute("""
        ALTER TABLE risks
        ALTER COLUMN status TYPE riskstatus_new
        USING LOWER(status::text)::riskstatus_new
    """)

    # Update tasks table
    op.execute("""
        ALTER TABLE tasks
        ALTER COLUMN status TYPE taskstatus_new
        USING LOWER(status::text)::taskstatus_new
    """)

    op.execute("""
        ALTER TABLE tasks
        ALTER COLUMN priority TYPE taskpriority_new
        USING LOWER(priority::text)::taskpriority_new
    """)

    # Restore defaults with lowercase values
    op.execute("ALTER TABLE risks ALTER COLUMN severity SET DEFAULT 'medium'::riskseverity_new")
    op.execute("ALTER TABLE risks ALTER COLUMN status SET DEFAULT 'identified'::riskstatus_new")
    op.execute("ALTER TABLE tasks ALTER COLUMN status SET DEFAULT 'todo'::taskstatus_new")
    op.execute("ALTER TABLE tasks ALTER COLUMN priority SET DEFAULT 'medium'::taskpriority_new")

    # Drop old enums
    op.execute("DROP TYPE riskseverity")
    op.execute("DROP TYPE riskstatus")
    op.execute("DROP TYPE taskstatus")
    op.execute("DROP TYPE taskpriority")

    # Rename new enums
    op.execute("ALTER TYPE riskseverity_new RENAME TO riskseverity")
    op.execute("ALTER TYPE riskstatus_new RENAME TO riskstatus")
    op.execute("ALTER TYPE taskstatus_new RENAME TO taskstatus")
    op.execute("ALTER TYPE taskpriority_new RENAME TO taskpriority")


def downgrade() -> None:
    """Revert enum values back to uppercase."""

    # Create enums with uppercase values
    op.execute("CREATE TYPE riskseverity_old AS ENUM ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL')")
    op.execute("CREATE TYPE riskstatus_old AS ENUM ('IDENTIFIED', 'MITIGATING', 'RESOLVED', 'ACCEPTED', 'ESCALATED')")
    op.execute("CREATE TYPE taskstatus_old AS ENUM ('TODO', 'IN_PROGRESS', 'BLOCKED', 'COMPLETED', 'CANCELLED')")
    op.execute("CREATE TYPE taskpriority_old AS ENUM ('LOW', 'MEDIUM', 'HIGH', 'URGENT')")

    # Update risks table
    op.execute("""
        ALTER TABLE risks
        ALTER COLUMN severity TYPE riskseverity_old
        USING UPPER(severity::text)::riskseverity_old
    """)

    op.execute("""
        ALTER TABLE risks
        ALTER COLUMN status TYPE riskstatus_old
        USING UPPER(status::text)::riskstatus_old
    """)

    # Update tasks table
    op.execute("""
        ALTER TABLE tasks
        ALTER COLUMN status TYPE taskstatus_old
        USING UPPER(status::text)::taskstatus_old
    """)

    op.execute("""
        ALTER TABLE tasks
        ALTER COLUMN priority TYPE taskpriority_old
        USING UPPER(priority::text)::taskpriority_old
    """)

    # Drop lowercase enums
    op.execute("DROP TYPE riskseverity")
    op.execute("DROP TYPE riskstatus")
    op.execute("DROP TYPE taskstatus")
    op.execute("DROP TYPE taskpriority")

    # Rename old enums back
    op.execute("ALTER TYPE riskseverity_old RENAME TO riskseverity")
    op.execute("ALTER TYPE riskstatus_old RENAME TO riskstatus")
    op.execute("ALTER TYPE taskstatus_old RENAME TO taskstatus")
    op.execute("ALTER TYPE taskpriority_old RENAME TO taskpriority")
