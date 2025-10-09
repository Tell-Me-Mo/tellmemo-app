#!/usr/bin/env python3
"""
RQ Worker Startup Script

This script starts RQ workers to process background jobs for PM Master V2.

Usage:
    # Start worker for all queues (high, default, low)
    python backend/start_rq_worker.py

    # Start worker for specific queues
    python backend/start_rq_worker.py --queues high default

    # Start worker with burst mode (exit when queues are empty)
    python backend/start_rq_worker.py --burst

    # Start multiple workers (worker pool)
    python backend/start_rq_worker.py --workers 4

Environment Variables:
    REDIS_HOST: Redis host (default: localhost)
    REDIS_PORT: Redis port (default: 6379)
    REDIS_DB: Redis database number (default: 0)
    REDIS_PASSWORD: Redis password (optional)
"""

import sys
import os
import logging
import argparse
from pathlib import Path

# Add backend directory to Python path
backend_dir = Path(__file__).parent
sys.path.insert(0, str(backend_dir))

from rq import Worker, SimpleWorker
from rq.worker_pool import WorkerPool
from queue_config import queue_config
from config import get_settings
import platform

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


def parse_args():
    """Parse command line arguments"""
    parser = argparse.ArgumentParser(description='Start RQ workers for PM Master V2')

    parser.add_argument(
        '--queues',
        nargs='+',
        default=['high', 'default', 'low'],
        choices=['high', 'default', 'low'],
        help='Queue names to process (default: all queues in priority order)'
    )

    parser.add_argument(
        '--burst',
        action='store_true',
        help='Run in burst mode (exit when all queues are empty)'
    )

    parser.add_argument(
        '--workers',
        type=int,
        default=1,
        help='Number of workers to start (default: 1)'
    )

    parser.add_argument(
        '--name',
        type=str,
        default=None,
        help='Worker name (default: auto-generated)'
    )

    parser.add_argument(
        '--log-level',
        type=str,
        default='INFO',
        choices=['DEBUG', 'INFO', 'WARNING', 'ERROR'],
        help='Logging level (default: INFO)'
    )

    return parser.parse_args()


def start_worker(queue_names, burst=False, worker_name=None, log_level='INFO'):
    """
    Start a single RQ worker.

    Args:
        queue_names: List of queue names to process
        burst: Whether to run in burst mode
        worker_name: Optional worker name
        log_level: Logging level
    """
    # Set log level
    logging.getLogger().setLevel(getattr(logging, log_level))

    # Get queue objects
    queues = [queue_config.get_queue(name) for name in queue_names]

    logger.info(f"Starting RQ worker for queues: {queue_names}")
    logger.info(f"Burst mode: {burst}")
    logger.info(f"Worker name: {worker_name or 'auto-generated'}")

    # Get Redis connection
    redis_conn = queue_config._get_redis_connection()

    # Use SimpleWorker on macOS to avoid fork() issues with PyTorch/transformers
    # SimpleWorker runs jobs in the same process instead of forking
    worker_class = SimpleWorker if platform.system() == 'Darwin' else Worker

    if worker_class == SimpleWorker:
        logger.info("Using SimpleWorker (no forking) for macOS compatibility")

    # Create worker
    worker = worker_class(
        queues,
        connection=redis_conn,
        name=worker_name,
        log_job_description=True,
        disable_default_exception_handler=False
    )

    # Start worker
    try:
        logger.info("Worker started successfully. Waiting for jobs...")
        worker.work(burst=burst, logging_level=log_level)
    except KeyboardInterrupt:
        logger.info("Worker interrupted by user. Shutting down...")
    except Exception as e:
        logger.error(f"Worker error: {e}", exc_info=True)
        raise
    finally:
        logger.info("Worker shutdown complete")


def start_worker_pool(queue_names, num_workers, burst=False, log_level='INFO'):
    """
    Start multiple RQ workers using WorkerPool.

    Args:
        queue_names: List of queue names to process
        num_workers: Number of workers to start
        burst: Whether to run in burst mode
        log_level: Logging level
    """
    # Set log level
    logging.getLogger().setLevel(getattr(logging, log_level))

    # On macOS, WorkerPool uses fork() which causes issues with PyTorch/transformers
    # Fall back to single SimpleWorker
    if platform.system() == 'Darwin':
        logger.warning("WorkerPool not supported on macOS due to fork() limitations.")
        logger.warning("Falling back to single SimpleWorker. For multiple workers, run separate processes.")
        start_worker(queue_names, burst=burst, log_level=log_level)
        return

    # Get queue objects
    queues = [queue_config.get_queue(name) for name in queue_names]

    logger.info(f"Starting RQ worker pool with {num_workers} workers for queues: {queue_names}")
    logger.info(f"Burst mode: {burst}")

    # Get Redis connection
    redis_conn = queue_config._get_redis_connection()

    # Create worker pool
    pool = WorkerPool(
        queues,
        connection=redis_conn,
        num_workers=num_workers,
        log_job_description=True
    )

    # Start worker pool
    try:
        logger.info("Worker pool started successfully. Waiting for jobs...")
        pool.start(burst=burst, logging_level=log_level)
    except KeyboardInterrupt:
        logger.info("Worker pool interrupted by user. Shutting down...")
    except Exception as e:
        logger.error(f"Worker pool error: {e}", exc_info=True)
        raise
    finally:
        logger.info("Worker pool shutdown complete")


def main():
    """Main entry point"""
    args = parse_args()

    # Verify Redis connection
    try:
        settings = get_settings()
        logger.info(f"Connecting to Redis at {settings.redis_host}:{settings.redis_port}")

        # Test connection
        redis_conn = queue_config._get_redis_connection()
        redis_conn.ping()
        logger.info("Redis connection successful")

    except Exception as e:
        logger.error(f"Failed to connect to Redis: {e}")
        logger.error("Please ensure Redis is running and configuration is correct")
        sys.exit(1)

    # Display queue information
    queue_info = queue_config.get_queue_info()
    logger.info("Current queue status:")
    for queue_name, info in queue_info.items():
        if queue_name in args.queues:
            logger.info(
                f"  {queue_name}: {info['count']} queued, "
                f"{info['started_jobs']} started, "
                f"{info['finished_jobs']} finished, "
                f"{info['failed_jobs']} failed"
            )

    # Start workers
    if args.workers > 1:
        # Start worker pool
        start_worker_pool(
            queue_names=args.queues,
            num_workers=args.workers,
            burst=args.burst,
            log_level=args.log_level
        )
    else:
        # Start single worker
        start_worker(
            queue_names=args.queues,
            burst=args.burst,
            worker_name=args.name,
            log_level=args.log_level
        )


if __name__ == '__main__':
    main()
