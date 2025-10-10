"""
RQ (Redis Queue) Utilities

Provides decorators and helpers for working with RQ background jobs,
including cancellation handling, progress tracking, and error handling.
"""

import asyncio
import logging
from functools import wraps
from typing import Optional, Callable, Any
from rq.job import Job

logger = logging.getLogger(__name__)


def check_cancellation(
    rq_job_arg: str = 'rq_job',
    check_before: bool = True,
    check_after: bool = False
):
    """
    Decorator that checks if an RQ job has been cancelled.

    This decorator provides elegant cancellation handling by automatically
    checking the job status before (and optionally after) function execution.

    Args:
        rq_job_arg: Name of the keyword argument containing the RQ job
        check_before: Check for cancellation before function execution
        check_after: Check for cancellation after function execution

    Usage:
        @check_cancellation()
        async def my_task(data, rq_job=None):
            # Automatically checks for cancellation before execution
            await process_data(data)

        # For sync functions:
        @check_cancellation()
        def my_sync_task(data, rq_job=None):
            process_data_sync(data)

    Raises:
        asyncio.CancelledError: If job has been cancelled
    """
    def decorator(func: Callable) -> Callable:
        @wraps(func)
        async def async_wrapper(*args, **kwargs):
            rq_job = kwargs.get(rq_job_arg)

            # Check before execution
            if check_before:
                _check_job_cancelled(rq_job, func.__name__, "before")

            # Execute the function
            result = await func(*args, **kwargs)

            # Check after execution
            if check_after:
                _check_job_cancelled(rq_job, func.__name__, "after")

            return result

        @wraps(func)
        def sync_wrapper(*args, **kwargs):
            rq_job = kwargs.get(rq_job_arg)

            # Check before execution
            if check_before:
                _check_job_cancelled(rq_job, func.__name__, "before")

            # Execute the function
            result = func(*args, **kwargs)

            # Check after execution
            if check_after:
                _check_job_cancelled(rq_job, func.__name__, "after")

            return result

        # Return appropriate wrapper based on whether function is async
        if asyncio.iscoroutinefunction(func):
            return async_wrapper
        else:
            return sync_wrapper

    return decorator


def _check_job_cancelled(rq_job: Optional[Job], func_name: str, when: str = "before"):
    """
    Internal helper to check if RQ job is cancelled.

    Args:
        rq_job: RQ job instance or None
        func_name: Name of the function being checked (for logging)
        when: When the check is happening ('before' or 'after')

    Raises:
        asyncio.CancelledError: If job has been cancelled
    """
    if not rq_job:
        return

    try:
        # Refresh job status from Redis to get latest state
        rq_job.refresh()

        if rq_job.is_canceled:
            logger.info(f"Job {rq_job.id} cancelled {when} executing {func_name}")
            raise asyncio.CancelledError(f"Job cancelled by user")

    except asyncio.CancelledError:
        # Re-raise cancellation errors
        raise

    except Exception as e:
        # Log but don't fail on Redis connection errors
        logger.warning(f"Failed to check job cancellation status: {e}")


class CancellationCheckpoint:
    """
    Context manager for manual cancellation checkpoints.

    Use this when you need to check for cancellation at specific
    points within a function without using decorators.

    Usage:
        async def my_task(rq_job=None):
            checkpoint = CancellationCheckpoint(rq_job)

            # Process step 1
            await process_step_1()
            checkpoint.check("after step 1")

            # Process step 2
            await process_step_2()
            checkpoint.check("after step 2")
    """

    def __init__(self, rq_job: Optional[Job]):
        """
        Initialize checkpoint.

        Args:
            rq_job: RQ job instance or None
        """
        self.rq_job = rq_job

    def check(self, context: str = ""):
        """
        Check if job has been cancelled.

        Args:
            context: Optional context string for logging

        Raises:
            asyncio.CancelledError: If job has been cancelled
        """
        if not self.rq_job:
            return

        try:
            self.rq_job.refresh()

            if self.rq_job.is_canceled:
                msg = f"Job {self.rq_job.id} cancelled"
                if context:
                    msg += f" ({context})"
                logger.info(msg)
                raise asyncio.CancelledError("Job cancelled by user")

        except asyncio.CancelledError:
            raise

        except Exception as e:
            logger.warning(f"Failed to check job cancellation: {e}")


class PeriodicCancellationChecker:
    """
    Context manager that periodically checks for job cancellation.

    This is useful for long-running operations that don't have
    natural checkpoints (e.g., external API calls, model inference).

    Usage:
        async def my_task(rq_job=None):
            async with PeriodicCancellationChecker(rq_job, interval=1.0):
                # Automatically checks every 1 second
                await long_running_operation()
    """

    def __init__(self, rq_job: Optional[Job], interval: float = 1.0):
        """
        Initialize periodic checker.

        Args:
            rq_job: RQ job instance or None
            interval: Check interval in seconds (default: 1.0)
        """
        self.rq_job = rq_job
        self.interval = interval
        self._task: Optional[asyncio.Task] = None
        self._stopped = False

    async def _periodic_check(self):
        """Background task that periodically checks for cancellation."""
        try:
            while not self._stopped:
                await asyncio.sleep(self.interval)

                if self.rq_job:
                    self.rq_job.refresh()
                    if self.rq_job.is_canceled:
                        logger.info(f"Job {self.rq_job.id} cancelled (periodic check)")
                        raise asyncio.CancelledError("Job cancelled by user")

        except asyncio.CancelledError:
            # Cancellation detected, let it propagate
            raise

        except Exception as e:
            logger.warning(f"Error in periodic cancellation check: {e}")

    async def __aenter__(self):
        """Start periodic checking when entering context."""
        if self.rq_job:
            self._task = asyncio.create_task(self._periodic_check())
        return self

    async def __aexit__(self, exc_type, exc_val, exc_tb):
        """Stop periodic checking when exiting context."""
        self._stopped = True
        if self._task:
            self._task.cancel()
            try:
                await self._task
            except asyncio.CancelledError:
                pass
        return False  # Don't suppress exceptions


def update_job_progress(
    rq_job: Optional[Job],
    progress: float,
    step: str,
    current_step: Optional[int] = None,
    publish_to_redis: bool = True
):
    """
    Helper to update RQ job progress with optional Redis pub/sub.

    Args:
        rq_job: RQ job instance or None
        progress: Progress percentage (0-100)
        step: Description of current step
        current_step: Optional current step number
        publish_to_redis: Whether to publish update to Redis pub/sub
    """
    if not rq_job:
        return

    try:
        rq_job.meta['progress'] = progress
        rq_job.meta['step'] = step
        if current_step is not None:
            rq_job.meta['current_step'] = current_step
        rq_job.save_meta()

        # Publish to Redis pub/sub for real-time updates
        if publish_to_redis:
            from queue_config import queue_config
            queue_config.publish_job_update(rq_job.id, {
                'status': 'processing',
                'progress': progress,
                'step': step
            })

    except Exception as e:
        logger.warning(f"Failed to update job progress: {e}")
