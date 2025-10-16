"""
Backfill script to generate embeddings for existing risks, tasks, blockers, and lessons.

This script should be run once after deploying the semantic deduplication feature
to populate embeddings for all existing items in the database.

Usage:
    python scripts/backfill_embeddings.py
"""

import asyncio
import logging
import sys
from pathlib import Path

# Add parent directory to path to import from backend
sys.path.insert(0, str(Path(__file__).parent.parent))

from sqlalchemy import select
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker

from models.risk import Risk
from models.task import Task
from models.blocker import Blocker
from models.lesson_learned import LessonLearned
from services.rag.embedding_service import embedding_service
from config import get_settings

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)

settings = get_settings()


async def backfill_embeddings_for_model(session: AsyncSession, model_class, model_name: str):
    """Backfill embeddings for a specific model."""

    logger.info(f"Starting backfill for {model_name}...")

    # Get all items without embeddings
    query = select(model_class).where(model_class.title_embedding.is_(None))
    result = await session.execute(query)
    items = result.scalars().all()

    if not items:
        logger.info(f"No {model_name} items need backfilling")
        return 0

    logger.info(f"Found {len(items)} {model_name} items without embeddings")

    # Extract titles
    titles = [item.title for item in items]

    # Generate embeddings in batches
    batch_size = 32
    total_updated = 0

    for i in range(0, len(items), batch_size):
        batch_items = items[i:i + batch_size]
        batch_titles = titles[i:i + batch_size]

        logger.info(f"Processing batch {i // batch_size + 1}/{(len(items) + batch_size - 1) // batch_size}")

        try:
            # Generate embeddings
            embeddings = await embedding_service.generate_embeddings_batch(batch_titles)

            # Update database
            for item, embedding in zip(batch_items, embeddings):
                item.title_embedding = embedding
                total_updated += 1

            # Commit batch
            await session.commit()
            logger.info(f"Updated {len(batch_items)} {model_name} items")

        except Exception as e:
            logger.error(f"Error processing batch: {e}")
            await session.rollback()
            continue

    logger.info(f"Completed backfill for {model_name}: {total_updated} items updated")
    return total_updated


async def main():
    """Main backfill function."""
    logger.info("=" * 60)
    logger.info("Starting embedding backfill script")
    logger.info("=" * 60)

    # Create async engine
    engine = create_async_engine(
        settings.database_url,
        echo=False,
        pool_pre_ping=True
    )

    # Create session factory
    async_session_factory = sessionmaker(
        engine, class_=AsyncSession, expire_on_commit=False
    )

    try:
        # Initialize embedding service
        logger.info("Initializing embedding service...")
        await embedding_service.warm_up()
        logger.info(f"Embedding service ready: {embedding_service.get_model_info()}")

        # Create session
        async with async_session_factory() as session:
            total_updated = 0

            # Backfill each model type
            models = [
                (Risk, "Risks"),
                (Task, "Tasks"),
                (Blocker, "Blockers"),
                (LessonLearned, "Lessons Learned")
            ]

            for model_class, model_name in models:
                count = await backfill_embeddings_for_model(session, model_class, model_name)
                total_updated += count

            logger.info("=" * 60)
            logger.info(f"Backfill complete! Total items updated: {total_updated}")
            logger.info("=" * 60)

    except Exception as e:
        logger.error(f"Backfill failed: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

    finally:
        await engine.dispose()


if __name__ == "__main__":
    asyncio.run(main())
