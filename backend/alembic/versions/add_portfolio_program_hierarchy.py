"""Add portfolio and program hierarchy tables

Revision ID: 1a2b3c4d5e6f
Revises: 239fdf20e86c
Create Date: 2025-09-12 18:00:00.000000

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision = '1a2b3c4d5e6f'
down_revision = '239fdf20e86c'
branch_labels = None
depends_on = None


def upgrade() -> None:
    # Create portfolios table
    op.create_table(
        'portfolios',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False, primary_key=True),
        sa.Column('name', sa.String(255), nullable=False, unique=True),
        sa.Column('description', sa.Text(), nullable=True),
        sa.Column('created_by', sa.String(255), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.Column('updated_at', sa.DateTime(), nullable=False),
    )
    
    # Create index on portfolio name
    op.create_index('ix_portfolios_name', 'portfolios', ['name'])
    
    # Create programs table
    op.create_table(
        'programs',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False, primary_key=True),
        sa.Column('name', sa.String(255), nullable=False),
        sa.Column('description', sa.Text(), nullable=True),
        sa.Column('portfolio_id', postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column('created_by', sa.String(255), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.Column('updated_at', sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(['portfolio_id'], ['portfolios.id'], ondelete='CASCADE'),
    )
    
    # Create index on program name
    op.create_index('ix_programs_name', 'programs', ['name'])
    
    # Add hierarchy columns to projects table
    op.add_column('projects', sa.Column('portfolio_id', postgresql.UUID(as_uuid=True), nullable=True))
    op.add_column('projects', sa.Column('program_id', postgresql.UUID(as_uuid=True), nullable=True))
    
    # Add foreign key constraints for projects
    op.create_foreign_key(
        'fk_projects_portfolio_id',
        'projects', 'portfolios',
        ['portfolio_id'], ['id'],
        ondelete='SET NULL'
    )
    
    op.create_foreign_key(
        'fk_projects_program_id', 
        'projects', 'programs',
        ['program_id'], ['id'],
        ondelete='SET NULL'
    )
    
    # Change projects description to TEXT type for consistency
    op.alter_column('projects', 'description', type_=sa.Text(), existing_nullable=True)


def downgrade() -> None:
    # Remove foreign key constraints first
    op.drop_constraint('fk_projects_program_id', 'projects', type_='foreignkey')
    op.drop_constraint('fk_projects_portfolio_id', 'projects', type_='foreignkey')
    
    # Remove hierarchy columns from projects
    op.drop_column('projects', 'program_id')
    op.drop_column('projects', 'portfolio_id')
    
    # Change projects description back to String type
    op.alter_column('projects', 'description', type_=sa.String(), existing_nullable=True)
    
    # Drop programs table
    op.drop_index('ix_programs_name')
    op.drop_table('programs')
    
    # Drop portfolios table  
    op.drop_index('ix_portfolios_name')
    op.drop_table('portfolios')