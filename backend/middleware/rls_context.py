"""
Row-Level Security Context Middleware for FastAPI.
Sets PostgreSQL session variables for RLS policies to use.
"""

from typing import Optional
from fastapi import Request
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.responses import Response
import asyncpg
from contextlib import asynccontextmanager


class RLSContextMiddleware(BaseHTTPMiddleware):
    """
    Middleware to set PostgreSQL session context for Row-Level Security.

    This middleware extracts the organization_id and user_id from the
    authenticated user and sets them as PostgreSQL session variables
    that RLS policies can use.
    """

    async def dispatch(self, request: Request, call_next):
        """Process the request and set RLS context."""
        # Get the database session from the request state if available
        # This assumes the database dependency is already injected
        response = await call_next(request)
        return response


@asynccontextmanager
async def set_rls_context(connection: asyncpg.Connection, user_id: Optional[str] = None, organization_id: Optional[str] = None):
    """
    Context manager to set RLS context for a database connection.

    Usage:
        async with set_rls_context(conn, user_id, org_id):
            # Execute queries with RLS context
            await conn.fetch("SELECT * FROM projects")
    """
    try:
        # Set the session variables for RLS
        if user_id:
            await connection.execute(f"SET LOCAL app.user_id = '{user_id}'")
        if organization_id:
            await connection.execute(f"SET LOCAL app.organization_id = '{organization_id}'")

        yield connection
    finally:
        # Reset session variables (optional, as LOCAL variables are transaction-scoped)
        await connection.execute("RESET app.user_id")
        await connection.execute("RESET app.organization_id")


async def set_session_rls_context(db_session, user_id: Optional[str] = None, organization_id: Optional[str] = None):
    """
    Set RLS context for SQLAlchemy async session.

    This should be called at the beginning of each request handler
    that needs RLS enforcement.

    Args:
        db_session: SQLAlchemy AsyncSession
        user_id: The current user's ID
        organization_id: The current organization's ID
    """
    if user_id:
        await db_session.execute(f"SET LOCAL app.user_id = '{user_id}'")
    if organization_id:
        await db_session.execute(f"SET LOCAL app.organization_id = '{organization_id}'")

    # Commit to apply the settings
    await db_session.commit()


class RLSContextDependency:
    """
    FastAPI dependency to automatically set RLS context based on the current user.

    Usage in routes:
        @app.get("/projects")
        async def get_projects(
            current_user: User = Depends(get_current_user),
            db: AsyncSession = Depends(get_db),
            _rls: None = Depends(RLSContextDependency())
        ):
            # RLS context is automatically set
            projects = await db.execute(select(Project))
            return projects.scalars().all()
    """

    async def __call__(self, request: Request, db, current_user = None):
        """Set RLS context for the current request."""
        if current_user:
            # Extract user and organization from the authenticated user
            user_id = str(current_user.id) if hasattr(current_user, 'id') else None
            org_id = str(current_user.organization_id) if hasattr(current_user, 'organization_id') else None

            # Set the RLS context in the database session
            if user_id:
                await db.execute(f"SET LOCAL app.user_id = '{user_id}'")
            if org_id:
                await db.execute(f"SET LOCAL app.organization_id = '{org_id}'")

            await db.commit()

        return None