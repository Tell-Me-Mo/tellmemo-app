"""separate_risks_and_blockers_in_summaries

Revision ID: 3238b6418cbd
Revises: 063a01c21a09
Create Date: 2025-09-27 06:11:19.954372

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


# revision identifiers, used by Alembic.
revision: str = '3238b6418cbd'
down_revision: Union[str, Sequence[str], None] = '063a01c21a09'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """
    Separate risks_and_blockers column into risks and blockers columns.
    Migrate existing data to preserve it.
    """
    # Add new columns
    op.add_column('summaries', sa.Column('risks', postgresql.JSONB(astext_type=sa.Text()), nullable=True))
    op.add_column('summaries', sa.Column('blockers', postgresql.JSONB(astext_type=sa.Text()), nullable=True))

    # Migrate existing data from risks_and_blockers to separate columns
    op.execute("""
        UPDATE summaries
        SET
            risks = COALESCE((risks_and_blockers->>'risks')::jsonb, '[]'::jsonb),
            blockers = COALESCE((risks_and_blockers->>'blockers')::jsonb, '[]'::jsonb)
        WHERE risks_and_blockers IS NOT NULL
    """)

    # Note: We keep risks_and_blockers column for backward compatibility during transition


def downgrade() -> None:
    """
    Revert to only having combined risks_and_blockers column.
    """
    # Combine the data back
    op.execute("""
        UPDATE summaries
        SET risks_and_blockers = jsonb_build_object(
            'risks', COALESCE(risks, '[]'::jsonb),
            'blockers', COALESCE(blockers, '[]'::jsonb),
            'total_risk_score', COALESCE(risks_and_blockers->>'total_risk_score', '0'),
            'critical_count', COALESCE(risks_and_blockers->>'critical_count', '0'),
            'mitigation_coverage', COALESCE(risks_and_blockers->>'mitigation_coverage', '0'),
            'timeline_impact', COALESCE(risks_and_blockers->>'timeline_impact', 'low_risk'),
            'categories', COALESCE(risks_and_blockers->'categories', '{}'::jsonb)
        )
        WHERE risks IS NOT NULL OR blockers IS NOT NULL
    """)

    # Drop the separate columns
    op.drop_column('summaries', 'risks')
    op.drop_column('summaries', 'blockers')
