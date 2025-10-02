"""add_cascade_delete_to_project_foreign_keys

Revision ID: 26a5373f07f5
Revises: 7d6876c2b179
Create Date: 2025-09-24 15:39:17.631391

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '26a5373f07f5'
down_revision: Union[str, Sequence[str], None] = '7d6876c2b179'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Add CASCADE delete to project foreign keys in risks, lessons_learned, and tasks tables."""

    # Drop existing foreign key constraints
    op.drop_constraint('risks_project_id_fkey', 'risks', type_='foreignkey')
    op.drop_constraint('lessons_learned_project_id_fkey', 'lessons_learned', type_='foreignkey')
    op.drop_constraint('tasks_project_id_fkey', 'tasks', type_='foreignkey')

    # Add new foreign key constraints with CASCADE delete
    op.create_foreign_key(
        'risks_project_id_fkey',
        'risks',
        'projects',
        ['project_id'],
        ['id'],
        ondelete='CASCADE'
    )
    op.create_foreign_key(
        'lessons_learned_project_id_fkey',
        'lessons_learned',
        'projects',
        ['project_id'],
        ['id'],
        ondelete='CASCADE'
    )
    op.create_foreign_key(
        'tasks_project_id_fkey',
        'tasks',
        'projects',
        ['project_id'],
        ['id'],
        ondelete='CASCADE'
    )


def downgrade() -> None:
    """Remove CASCADE delete from project foreign keys."""

    # Drop CASCADE foreign key constraints
    op.drop_constraint('risks_project_id_fkey', 'risks', type_='foreignkey')
    op.drop_constraint('lessons_learned_project_id_fkey', 'lessons_learned', type_='foreignkey')
    op.drop_constraint('tasks_project_id_fkey', 'tasks', type_='foreignkey')

    # Add back original foreign key constraints without CASCADE
    op.create_foreign_key(
        'risks_project_id_fkey',
        'risks',
        'projects',
        ['project_id'],
        ['id']
    )
    op.create_foreign_key(
        'lessons_learned_project_id_fkey',
        'lessons_learned',
        'projects',
        ['project_id'],
        ['id']
    )
    op.create_foreign_key(
        'tasks_project_id_fkey',
        'tasks',
        'projects',
        ['project_id'],
        ['id']
    )
