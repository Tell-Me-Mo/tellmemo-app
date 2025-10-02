"""Portfolio service for managing portfolio operations."""

from typing import List, Optional
from uuid import UUID
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, delete
from sqlalchemy.orm import selectinload

from models.portfolio import Portfolio
from models.program import Program
from models.project import Project
from utils.logger import get_logger
from utils.monitoring import monitor_operation, monitor_sync_operation

logger = get_logger(__name__)


class PortfolioService:
    """Service class for portfolio operations."""
    
    @staticmethod
    @monitor_operation("create_portfolio", "database", capture_args=True, capture_result=True)
    async def create_portfolio(
        session: AsyncSession,
        name: str,
        description: Optional[str] = None,
        created_by: str = "system"
    ) -> Portfolio:
        """Create a new portfolio.
        
        Args:
            session: Database session
            name: Portfolio name (must be unique)
            description: Portfolio description
            created_by: User creating the portfolio
            
        Returns:
            Created portfolio instance
            
        Raises:
            ValueError: If portfolio name already exists
        """
        # Check if portfolio name already exists
        existing = await session.execute(
            select(Portfolio).where(Portfolio.name == name)
        )
        if existing.scalars().first():
            raise ValueError(f"Portfolio with name '{name}' already exists")
        
        portfolio = Portfolio(
            name=name,
            description=description,
            created_by=created_by
        )
        
        session.add(portfolio)
        await session.commit()
        await session.refresh(portfolio)
        
        logger.info(f"Created portfolio: {portfolio.name} (ID: {portfolio.id})")
        return portfolio
    
    @staticmethod
    @monitor_operation("get_portfolio", "database", capture_args=True, capture_result=False)
    async def get_portfolio(
        session: AsyncSession,
        portfolio_id: UUID
    ) -> Optional[Portfolio]:
        """Get portfolio by ID with related data.
        
        Args:
            session: Database session
            portfolio_id: Portfolio UUID
            
        Returns:
            Portfolio instance or None if not found
        """
        result = await session.execute(
            select(Portfolio)
            .options(
                selectinload(Portfolio.programs),
                selectinload(Portfolio.projects)
            )
            .where(Portfolio.id == portfolio_id)
        )
        return result.scalars().first()
    
    @staticmethod
    @monitor_operation("list_portfolios", "database", capture_args=False, capture_result=True)
    async def list_portfolios(
        session: AsyncSession,
        include_counts: bool = True
    ) -> List[Portfolio]:
        """List all portfolios with optional counts.
        
        Args:
            session: Database session
            include_counts: Whether to include program/project counts
            
        Returns:
            List of portfolio instances
        """
        query = select(Portfolio).options(
            selectinload(Portfolio.programs),
            selectinload(Portfolio.projects)
        ).order_by(Portfolio.name)
        
        result = await session.execute(query)
        portfolios = result.scalars().all()
        
        return list(portfolios)
    
    @staticmethod
    @monitor_operation("update_portfolio", "database", capture_args=True, capture_result=False)
    async def update_portfolio(
        session: AsyncSession,
        portfolio_id: UUID,
        name: Optional[str] = None,
        description: Optional[str] = None
    ) -> Optional[Portfolio]:
        """Update portfolio details.
        
        Args:
            session: Database session
            portfolio_id: Portfolio UUID
            name: New portfolio name
            description: New portfolio description
            
        Returns:
            Updated portfolio instance or None if not found
            
        Raises:
            ValueError: If new name conflicts with existing portfolio
        """
        result = await session.execute(
            select(Portfolio).where(Portfolio.id == portfolio_id)
        )
        portfolio = result.scalars().first()
        
        if not portfolio:
            return None
        
        # Check for name conflicts if updating name
        if name and name != portfolio.name:
            existing = await session.execute(
                select(Portfolio).where(Portfolio.name == name)
            )
            if existing.scalars().first():
                raise ValueError(f"Portfolio with name '{name}' already exists")
            portfolio.name = name
        
        if description is not None:
            portfolio.description = description
        
        await session.commit()
        await session.refresh(portfolio)
        
        logger.info(f"Updated portfolio: {portfolio.name} (ID: {portfolio.id})")
        return portfolio
    
    @staticmethod
    @monitor_operation("delete_portfolio", "database", capture_args=True, capture_result=True)
    async def delete_portfolio(
        session: AsyncSession,
        portfolio_id: UUID,
        reassign_to_portfolio_id: Optional[UUID] = None
    ) -> bool:
        """Delete a portfolio and handle related entities.
        
        Args:
            session: Database session
            portfolio_id: Portfolio UUID to delete
            reassign_to_portfolio_id: Optional portfolio to reassign programs/projects to
            
        Returns:
            True if deleted, False if not found
        """
        result = await session.execute(
            select(Portfolio).where(Portfolio.id == portfolio_id)
        )
        portfolio = result.scalars().first()
        
        if not portfolio:
            return False
        
        # Handle reassignment of programs and projects if specified
        if reassign_to_portfolio_id:
            # Reassign programs
            await session.execute(
                select(Program)
                .where(Program.portfolio_id == portfolio_id)
                .update({Program.portfolio_id: reassign_to_portfolio_id})
            )
            
            # Reassign standalone projects
            await session.execute(
                select(Project)
                .where(Project.portfolio_id == portfolio_id)
                .update({Project.portfolio_id: reassign_to_portfolio_id})
            )
        else:
            # Set programs and projects to orphaned (no portfolio)
            await session.execute(
                select(Program)
                .where(Program.portfolio_id == portfolio_id)
                .update({Program.portfolio_id: None})
            )
            
            await session.execute(
                select(Project)
                .where(Project.portfolio_id == portfolio_id)
                .update({Project.portfolio_id: None})
            )
        
        await session.delete(portfolio)
        await session.commit()
        
        logger.info(f"Deleted portfolio: {portfolio.name} (ID: {portfolio.id})")
        return True
    
    @staticmethod
    @monitor_operation("get_portfolio_statistics", "analysis", capture_args=True, capture_result=True)
    async def get_portfolio_statistics(
        session: AsyncSession,
        portfolio_id: UUID
    ) -> Optional[dict]:
        """Get portfolio statistics including counts and status breakdown.
        
        Args:
            session: Database session
            portfolio_id: Portfolio UUID
            
        Returns:
            Dictionary with portfolio statistics or None if not found
        """
        portfolio = await PortfolioService.get_portfolio(session, portfolio_id)
        if not portfolio:
            return None
        
        # Count programs
        program_count = len(portfolio.programs)
        
        # Count direct projects (not under programs)
        direct_projects = [p for p in portfolio.projects if p.program_id is None]
        direct_project_count = len(direct_projects)
        
        # Count all projects (direct + under programs)
        total_projects = len(portfolio.projects)
        
        # Project status breakdown
        active_projects = len([p for p in portfolio.projects if p.status.value == 'active'])
        archived_projects = len([p for p in portfolio.projects if p.status.value == 'archived'])
        
        return {
            'portfolio_id': str(portfolio_id),
            'portfolio_name': portfolio.name,
            'program_count': program_count,
            'direct_project_count': direct_project_count,
            'total_project_count': total_projects,
            'active_projects': active_projects,
            'archived_projects': archived_projects,
            'created_at': portfolio.created_at,
            'updated_at': portfolio.updated_at
        }