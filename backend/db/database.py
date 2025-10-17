"""Database connection and session management."""

import asyncio
from contextlib import asynccontextmanager
from typing import AsyncGenerator, Optional

import asyncpg
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine, async_sessionmaker
from sqlalchemy.orm import declarative_base
from sqlalchemy.pool import NullPool

from config import get_settings
from utils.logger import get_logger

settings = get_settings()
logger = get_logger(__name__)

Base = declarative_base()

class DatabaseManager:
    """Manages database connections and sessions."""
    
    def __init__(self):
        self._engine = None
        self._sessionmaker = None
        self._pg_pool: Optional[asyncpg.Pool] = None
        
    @property
    def engine(self):
        """Get or create the SQLAlchemy async engine."""
        if self._engine is None:
            self._engine = create_async_engine(
                settings.database_url,
                echo=False,  # Disable SQL echo logging
                poolclass=NullPool,  # Use NullPool for async connections
                pool_pre_ping=True,  # Enable connection health checks
                connect_args={
                    "server_settings": {"application_name": "pm_master_v2"},
                    "command_timeout": 60,
                }
            )
        return self._engine
    
    @property
    def sessionmaker(self) -> async_sessionmaker:
        """Get or create the async session maker."""
        if self._sessionmaker is None:
            self._sessionmaker = async_sessionmaker(
                self.engine,
                class_=AsyncSession,
                expire_on_commit=False,
                autoflush=False,
                autocommit=False
            )
        return self._sessionmaker
    
    async def get_session(self) -> AsyncGenerator[AsyncSession, None]:
        """Get an async database session."""
        async with self.sessionmaker() as session:
            try:
                yield session
                await session.commit()
            except Exception:
                await session.rollback()
                raise
            finally:
                await session.close()
    
    async def init_pg_pool(self) -> asyncpg.Pool:
        """Initialize the asyncpg connection pool for raw queries."""
        if self._pg_pool is None:
            max_retries = 5
            retry_delay = 2
            
            for attempt in range(max_retries):
                try:
                    self._pg_pool = await asyncpg.create_pool(
                        host=settings.postgres_host,
                        port=settings.postgres_port,
                        user=settings.postgres_user,
                        password=settings.postgres_password,
                        database=settings.postgres_db,
                        min_size=2,
                        max_size=10,
                        max_queries=50000,
                        max_inactive_connection_lifetime=300,
                        command_timeout=60,
                    )
                    logger.info("PostgreSQL connection pool initialized successfully")
                    break
                except (asyncpg.PostgresError, OSError) as e:
                    if attempt < max_retries - 1:
                        logger.warning(
                            f"Failed to connect to PostgreSQL (attempt {attempt + 1}/{max_retries}): {e}"
                        )
                        await asyncio.sleep(retry_delay)
                        retry_delay *= 2  # Exponential backoff
                    else:
                        logger.error(f"Failed to connect to PostgreSQL after {max_retries} attempts")
                        raise
        
        return self._pg_pool

    async def close_pg_pool(self):
        """Close the asyncpg connection pool."""
        if self._pg_pool:
            await self._pg_pool.close()
            self._pg_pool = None
            logger.info("PostgreSQL connection pool closed")
    
    async def check_connection(self) -> bool:
        """Check if the database connection is healthy."""
        try:
            pool = await self.init_pg_pool()
            async with pool.acquire() as connection:
                result = await connection.fetchval("SELECT 1")
                return result == 1
        except Exception as e:
            logger.error(f"Database health check failed: {e}")
            return False
    
    async def get_pg_version(self) -> str:
        """Get the PostgreSQL server version."""
        try:
            pool = await self.init_pg_pool()
            async with pool.acquire() as connection:
                version = await connection.fetchval("SELECT version()")
                return version
        except Exception as e:
            logger.error(f"Failed to get PostgreSQL version: {e}")
            return "Unknown"

    async def execute_raw_query(self, query: str, *args):
        """Execute a raw SQL query using asyncpg."""
        pool = await self.init_pg_pool()
        async with pool.acquire() as connection:
            return await connection.fetch(query, *args)

    async def execute_raw_command(self, command: str, *args):
        """Execute a raw SQL command using asyncpg."""
        pool = await self.init_pg_pool()
        async with pool.acquire() as connection:
            return await connection.execute(command, *args)
    
    @asynccontextmanager
    async def transaction(self):
        """Create a database transaction context."""
        pool = await self.init_pg_pool()
        async with pool.acquire() as connection:
            async with connection.transaction():
                yield connection

    async def close(self):
        """Close all database connections."""
        await self.close_pg_pool()
        if self._engine:
            await self._engine.dispose()
            self._engine = None
            self._sessionmaker = None
            logger.info("SQLAlchemy engine disposed")


# Global database manager instance
db_manager = DatabaseManager()


async def get_db() -> AsyncGenerator[AsyncSession, None]:
    """Dependency to get database session."""
    async for session in db_manager.get_session():
        yield session


@asynccontextmanager
async def get_db_context() -> AsyncSession:
    """Context manager to get database session for use outside of FastAPI dependencies."""
    async with db_manager.sessionmaker() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()


async def init_database():
    """Initialize database connections on startup."""
    try:
        await db_manager.init_pg_pool()
        version = await db_manager.get_pg_version()
        logger.info(f"Connected to PostgreSQL: {version}")
        
        # Test SQLAlchemy connection
        async for session in db_manager.get_session():
            from sqlalchemy import text
            result = await session.execute(text("SELECT 1"))
            if result.scalar() == 1:
                logger.info("SQLAlchemy connection verified")
            break
                
    except Exception as e:
        logger.error(f"Failed to initialize database: {e}")
        raise


async def close_database():
    """Close database connections on shutdown."""
    await db_manager.close()