"""
RQ (Redis Queue) Configuration for Background Job Processing

This module configures Redis queues for handling async jobs like:
- Audio transcription
- Content processing (embeddings, chunking)
- Summary generation
- Email/integration processing

Features:
- Multiple priority queues (high, default, low)
- Job progress tracking via job.meta and Redis pub/sub
- Automatic retry for failed jobs
- Job result persistence
- Real-time WebSocket updates via Redis pub/sub
"""

import logging
from typing import Optional
from redis import Redis
from rq import Queue
from rq.job import Job
from config import get_settings

logger = logging.getLogger(__name__)
settings = get_settings()


class QueueConfig:
    """Centralized RQ queue configuration"""

    def __init__(self):
        """Initialize Redis connection and queues"""
        self._redis_conn: Optional[Redis] = None
        self._pubsub_conn: Optional[Redis] = None  # Separate connection for pub/sub
        self._high_queue: Optional[Queue] = None
        self._default_queue: Optional[Queue] = None
        self._low_queue: Optional[Queue] = None

    def _get_redis_connection(self) -> Redis:
        """
        Get or create Redis connection with connection pooling.

        Returns:
            Redis connection instance
        """
        if self._redis_conn is None:
            try:
                # Build Redis URL
                if settings.redis_password:
                    redis_url = f"redis://:{settings.redis_password}@{settings.redis_host}:{settings.redis_port}/{settings.redis_db}"
                else:
                    redis_url = f"redis://{settings.redis_host}:{settings.redis_port}/{settings.redis_db}"

                # Create Redis connection with connection pooling
                # NOTE: decode_responses=False is required for RQ because it uses pickle serialization
                self._redis_conn = Redis.from_url(
                    redis_url,
                    decode_responses=False,  # RQ uses pickle (binary data), not UTF-8 strings
                    socket_connect_timeout=5,
                    socket_timeout=5,
                    socket_keepalive=True,
                    socket_keepalive_options={},
                    health_check_interval=30
                )

                # Test connection
                self._redis_conn.ping()
                logger.info(f"RQ Redis connection established: {settings.redis_host}:{settings.redis_port}")

            except Exception as e:
                logger.error(f"Failed to connect to Redis for RQ: {e}")
                raise

        return self._redis_conn

    @property
    def high_queue(self) -> Queue:
        """
        High priority queue for time-sensitive jobs.

        Use cases:
        - Real-time transcription requests
        - User-initiated summary generation

        Returns:
            RQ Queue instance
        """
        if self._high_queue is None:
            redis_conn = self._get_redis_connection()
            self._high_queue = Queue(
                'high',
                connection=redis_conn,
                default_timeout='30m',  # 30 minute timeout for long transcriptions
                result_ttl=3600  # Keep results for 1 hour
            )
            logger.info("High priority queue initialized")

        return self._high_queue

    @property
    def default_queue(self) -> Queue:
        """
        Default priority queue for standard background jobs.

        Use cases:
        - Content processing (embeddings, chunking)
        - Email processing
        - Batch operations

        Returns:
            RQ Queue instance
        """
        if self._default_queue is None:
            redis_conn = self._get_redis_connection()
            self._default_queue = Queue(
                'default',
                connection=redis_conn,
                default_timeout='20m',  # 20 minute timeout
                result_ttl=3600  # Keep results for 1 hour
            )
            logger.info("Default priority queue initialized")

        return self._default_queue

    @property
    def low_queue(self) -> Queue:
        """
        Low priority queue for non-urgent background jobs.

        Use cases:
        - Scheduled summary generation
        - Analytics processing
        - Cleanup tasks

        Returns:
            RQ Queue instance
        """
        if self._low_queue is None:
            redis_conn = self._get_redis_connection()
            self._low_queue = Queue(
                'low',
                connection=redis_conn,
                default_timeout='60m',  # 60 minute timeout for batch jobs
                result_ttl=7200  # Keep results for 2 hours
            )
            logger.info("Low priority queue initialized")

        return self._low_queue

    def get_queue(self, priority: str = 'default') -> Queue:
        """
        Get queue by priority level.

        Args:
            priority: Queue priority ('high', 'default', 'low')

        Returns:
            RQ Queue instance
        """
        queue_map = {
            'high': self.high_queue,
            'default': self.default_queue,
            'low': self.low_queue
        }

        return queue_map.get(priority, self.default_queue)

    def get_job(self, job_id: str) -> Optional[Job]:
        """
        Retrieve job by ID from any queue.

        Args:
            job_id: RQ job ID

        Returns:
            Job instance or None if not found
        """
        try:
            redis_conn = self._get_redis_connection()
            job = Job.fetch(job_id, connection=redis_conn)
            return job
        except Exception as e:
            logger.warning(f"Job {job_id} not found: {e}")
            return None

    def get_job_status(self, job_id: str) -> Optional[str]:
        """
        Get job status.

        Args:
            job_id: RQ job ID

        Returns:
            Job status string or None
        """
        job = self.get_job(job_id)
        if job:
            return job.get_status()
        return None

    def get_job_progress(self, job_id: str) -> Optional[dict]:
        """
        Get job progress metadata.

        Args:
            job_id: RQ job ID

        Returns:
            Job metadata dict or None
        """
        job = self.get_job(job_id)
        if job and hasattr(job, 'meta'):
            return job.meta
        return None

    def cancel_job(self, job_id: str) -> bool:
        """
        Cancel a queued or running job.

        Args:
            job_id: RQ job ID

        Returns:
            True if cancelled, False otherwise
        """
        try:
            job = self.get_job(job_id)
            if job:
                job.cancel()
                logger.info(f"Job {job_id} cancelled")
                return True
        except Exception as e:
            logger.error(f"Failed to cancel job {job_id}: {e}")

        return False

    def get_queue_info(self) -> dict:
        """
        Get information about all queues.

        Returns:
            Dict with queue statistics
        """
        return {
            'high': {
                'name': 'high',
                'count': len(self.high_queue),
                'started_jobs': self.high_queue.started_job_registry.count,
                'finished_jobs': self.high_queue.finished_job_registry.count,
                'failed_jobs': self.high_queue.failed_job_registry.count
            },
            'default': {
                'name': 'default',
                'count': len(self.default_queue),
                'started_jobs': self.default_queue.started_job_registry.count,
                'finished_jobs': self.default_queue.finished_job_registry.count,
                'failed_jobs': self.default_queue.failed_job_registry.count
            },
            'low': {
                'name': 'low',
                'count': len(self.low_queue),
                'started_jobs': self.low_queue.started_job_registry.count,
                'finished_jobs': self.low_queue.finished_job_registry.count,
                'failed_jobs': self.low_queue.failed_job_registry.count
            }
        }

    def get_pubsub_connection(self) -> Redis:
        """
        Get a separate Redis connection for pub/sub.

        Note: Pub/sub requires a dedicated connection because it's blocking.

        Returns:
            Redis connection instance for pub/sub
        """
        if self._pubsub_conn is None:
            try:
                # Build Redis URL
                if settings.redis_password:
                    redis_url = f"redis://:{settings.redis_password}@{settings.redis_host}:{settings.redis_port}/{settings.redis_db}"
                else:
                    redis_url = f"redis://{settings.redis_host}:{settings.redis_port}/{settings.redis_db}"

                # Create dedicated pub/sub connection
                # decode_responses=True for pub/sub since we're sending JSON strings
                self._pubsub_conn = Redis.from_url(
                    redis_url,
                    decode_responses=True,  # Pub/sub uses JSON strings
                    socket_connect_timeout=5,
                    socket_timeout=None,  # No timeout for pub/sub listening
                    socket_keepalive=True,
                    socket_keepalive_options={},
                    health_check_interval=30
                )

                # Test connection
                self._pubsub_conn.ping()
                logger.info(f"Redis pub/sub connection established: {settings.redis_host}:{settings.redis_port}")

            except Exception as e:
                logger.error(f"Failed to connect to Redis for pub/sub: {e}")
                raise

        return self._pubsub_conn

    def publish_job_update(self, job_id: str, update_data: dict):
        """
        Publish a job update to Redis pub/sub channel.

        Args:
            job_id: RQ job ID
            update_data: Update data to publish (will be JSON serialized)
        """
        try:
            import json
            redis_conn = self.get_pubsub_connection()
            channel = f"job_updates:{job_id}"
            message = json.dumps(update_data)
            redis_conn.publish(channel, message)

            # Log job updates (use DEBUG to avoid production log pollution)
            if update_data.get('status') == 'completed':
                result_info = ""
                if 'result' in update_data:
                    result_type = type(update_data['result']).__name__
                    result_keys = list(update_data['result'].keys()) if isinstance(update_data['result'], dict) else None
                    result_info = f", result_type={result_type}, result_keys={result_keys}"
                logger.debug(
                    f"Published COMPLETED job update: job_id={job_id}, channel={channel}, "
                    f"update_keys={list(update_data.keys())}{result_info}"
                )
            else:
                logger.debug(f"Published update for job {job_id} to channel {channel}")
        except Exception as e:
            logger.error(f"Failed to publish job update for {job_id}: {e}")

    def publish_live_insight(self, session_id: str, event_data: dict):
        """
        Publish a live meeting insight event to Redis pub/sub channel.

        This enables cross-process communication between RQ workers (which detect
        insights) and the main backend process (which manages WebSocket connections).

        Args:
            session_id: Meeting session identifier
            event_data: Event data to publish (will be JSON serialized)
                       Should include 'type' field (e.g., 'QUESTION_DETECTED', 'ACTION_TRACKED')
        """
        try:
            import json
            redis_conn = self.get_pubsub_connection()
            channel = f"live_insights:{session_id}"
            message = json.dumps(event_data)
            redis_conn.publish(channel, message)

            event_type = event_data.get('type', 'UNKNOWN')
            logger.debug(f"Published live insight to Redis: session={session_id}, type={event_type}, channel={channel}")
        except Exception as e:
            logger.error(f"Failed to publish live insight for session {session_id}: {e}")

    def close(self):
        """Close Redis connections"""
        if self._redis_conn:
            self._redis_conn.close()
            logger.info("RQ Redis connection closed")

        if self._pubsub_conn:
            self._pubsub_conn.close()
            logger.info("Redis pub/sub connection closed")


# Singleton instance
queue_config = QueueConfig()
