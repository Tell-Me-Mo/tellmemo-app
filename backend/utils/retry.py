"""Retry logic utilities for handling transient failures."""

import asyncio
import random
from typing import TypeVar, Callable, Optional, Tuple, Type
from functools import wraps

from utils.logger import get_logger
from utils.exceptions import LLMOverloadedException, LLMRateLimitException, LLMTimeoutException

logger = get_logger(__name__)

T = TypeVar('T')


class RetryConfig:
    """Configuration for retry behavior."""

    def __init__(
        self,
        max_attempts: int = 3,
        initial_delay: float = 1.0,
        max_delay: float = 60.0,
        exponential_base: float = 2.0,
        jitter: bool = True,
        retryable_exceptions: Optional[Tuple[Type[Exception], ...]] = None
    ):
        self.max_attempts = max_attempts
        self.initial_delay = initial_delay
        self.max_delay = max_delay
        self.exponential_base = exponential_base
        self.jitter = jitter
        self.retryable_exceptions = retryable_exceptions or (
            LLMOverloadedException,
            LLMRateLimitException,
            LLMTimeoutException,
        )


def calculate_backoff_delay(
    attempt: int,
    initial_delay: float,
    max_delay: float,
    exponential_base: float,
    jitter: bool
) -> float:
    """Calculate exponential backoff delay with optional jitter."""
    delay = min(initial_delay * (exponential_base ** attempt), max_delay)

    if jitter:
        # Add random jitter between 0% and 25% of the delay
        jitter_amount = delay * random.uniform(0, 0.25)
        delay = delay + jitter_amount

    return delay


def async_retry(config: Optional[RetryConfig] = None):
    """
    Decorator for async functions that adds retry logic with exponential backoff.

    Usage:
        @async_retry(RetryConfig(max_attempts=5))
        async def my_function():
            # function code
    """
    if config is None:
        config = RetryConfig()

    def decorator(func: Callable):
        @wraps(func)
        async def wrapper(*args, **kwargs):
            last_exception = None

            for attempt in range(config.max_attempts):
                try:
                    return await func(*args, **kwargs)

                except config.retryable_exceptions as e:
                    last_exception = e

                    if attempt < config.max_attempts - 1:
                        delay = calculate_backoff_delay(
                            attempt,
                            config.initial_delay,
                            config.max_delay,
                            config.exponential_base,
                            config.jitter
                        )

                        logger.warning(
                            f"Attempt {attempt + 1}/{config.max_attempts} failed for {func.__name__}: {e}. "
                            f"Retrying in {delay:.2f} seconds..."
                        )

                        await asyncio.sleep(delay)
                    else:
                        logger.error(
                            f"All {config.max_attempts} attempts failed for {func.__name__}. "
                            f"Last error: {e}"
                        )

                except Exception as e:
                    # Non-retryable exception, re-raise immediately
                    logger.error(f"Non-retryable error in {func.__name__}: {e}")
                    raise

            # If we've exhausted all retries, raise the last exception
            if last_exception:
                raise last_exception

        return wrapper
    return decorator


async def retry_with_backoff(
    func: Callable,
    *args,
    config: Optional[RetryConfig] = None,
    **kwargs
) -> T:
    """
    Execute a function with retry logic and exponential backoff.

    This is a functional alternative to the decorator approach.

    Usage:
        result = await retry_with_backoff(
            my_async_function,
            arg1, arg2,
            config=RetryConfig(max_attempts=5),
            kwarg1=value1
        )
    """
    if config is None:
        config = RetryConfig()

    last_exception = None

    for attempt in range(config.max_attempts):
        try:
            return await func(*args, **kwargs)

        except config.retryable_exceptions as e:
            last_exception = e

            if attempt < config.max_attempts - 1:
                delay = calculate_backoff_delay(
                    attempt,
                    config.initial_delay,
                    config.max_delay,
                    config.exponential_base,
                    config.jitter
                )

                logger.warning(
                    f"Attempt {attempt + 1}/{config.max_attempts} failed: {e}. "
                    f"Retrying in {delay:.2f} seconds..."
                )

                await asyncio.sleep(delay)
            else:
                logger.error(
                    f"All {config.max_attempts} attempts failed. Last error: {e}"
                )

        except Exception as e:
            # Non-retryable exception, re-raise immediately
            logger.error(f"Non-retryable error: {e}")
            raise

    # If we've exhausted all retries, raise the last exception
    if last_exception:
        raise last_exception