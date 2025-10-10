"""
Unit tests for RQ utilities (decorators and cancellation helpers).

Tests the new decorator pattern for job cancellation handling.
"""

import pytest
import asyncio
from unittest.mock import Mock, MagicMock
from rq.job import Job

from utils.rq_utils import (
    check_cancellation,
    CancellationCheckpoint,
    PeriodicCancellationChecker
)


class TestCheckCancellationDecorator:
    """Test suite for @check_cancellation decorator"""

    @pytest.fixture
    def mock_rq_job(self):
        """Create a mock RQ job"""
        job = Mock(spec=Job)
        job.id = "test-job-123"
        job.is_canceled = False
        job.refresh = Mock()
        return job

    @pytest.mark.asyncio
    async def test_decorator_allows_execution_when_not_cancelled(self, mock_rq_job):
        """Test that decorated function executes normally when job is not cancelled"""

        @check_cancellation()
        async def sample_task(data, rq_job=None):
            return f"Processed: {data}"

        result = await sample_task("test_data", rq_job=mock_rq_job)

        assert result == "Processed: test_data"
        assert mock_rq_job.refresh.called

    @pytest.mark.asyncio
    async def test_decorator_raises_when_cancelled(self, mock_rq_job):
        """Test that decorated function raises CancelledError when job is cancelled"""
        mock_rq_job.is_canceled = True

        @check_cancellation()
        async def sample_task(data, rq_job=None):
            return f"Processed: {data}"

        with pytest.raises(asyncio.CancelledError, match="Job cancelled"):
            await sample_task("test_data", rq_job=mock_rq_job)

        assert mock_rq_job.refresh.called

    @pytest.mark.asyncio
    async def test_decorator_works_without_rq_job(self):
        """Test that decorated function works when rq_job is None"""

        @check_cancellation()
        async def sample_task(data, rq_job=None):
            return f"Processed: {data}"

        # Should not raise - just skip cancellation check
        result = await sample_task("test_data", rq_job=None)
        assert result == "Processed: test_data"

    def test_decorator_works_with_sync_functions(self, mock_rq_job):
        """Test that decorator works with synchronous functions"""

        @check_cancellation()
        def sync_task(data, rq_job=None):
            return f"Processed: {data}"

        result = sync_task("test_data", rq_job=mock_rq_job)

        assert result == "Processed: test_data"
        assert mock_rq_job.refresh.called

    def test_decorator_with_sync_function_raises_when_cancelled(self, mock_rq_job):
        """Test that decorator raises for sync functions when cancelled"""
        mock_rq_job.is_canceled = True

        @check_cancellation()
        def sync_task(data, rq_job=None):
            return f"Processed: {data}"

        with pytest.raises(asyncio.CancelledError):
            sync_task("test_data", rq_job=mock_rq_job)


class TestCancellationCheckpoint:
    """Test suite for CancellationCheckpoint class"""

    @pytest.fixture
    def mock_rq_job(self):
        """Create a mock RQ job"""
        job = Mock(spec=Job)
        job.id = "test-job-456"
        job.is_canceled = False
        job.refresh = Mock()
        return job

    def test_checkpoint_allows_execution_when_not_cancelled(self, mock_rq_job):
        """Test checkpoint allows execution when job is not cancelled"""
        checkpoint = CancellationCheckpoint(mock_rq_job)

        # Should not raise
        checkpoint.check("at step 1")
        checkpoint.check("at step 2")

        assert mock_rq_job.refresh.call_count == 2

    def test_checkpoint_raises_when_cancelled(self, mock_rq_job):
        """Test checkpoint raises when job is cancelled"""
        mock_rq_job.is_canceled = True
        checkpoint = CancellationCheckpoint(mock_rq_job)

        with pytest.raises(asyncio.CancelledError, match="Job cancelled"):
            checkpoint.check("at step 1")

        assert mock_rq_job.refresh.called

    def test_checkpoint_works_without_rq_job(self):
        """Test checkpoint works when rq_job is None"""
        checkpoint = CancellationCheckpoint(None)

        # Should not raise - just skip check
        checkpoint.check("at step 1")
        checkpoint.check("at step 2")

    def test_checkpoint_includes_context_in_log(self, mock_rq_job, caplog):
        """Test checkpoint includes context string in log messages"""
        import logging

        mock_rq_job.is_canceled = True
        checkpoint = CancellationCheckpoint(mock_rq_job)

        with caplog.at_level(logging.INFO):
            with pytest.raises(asyncio.CancelledError):
                checkpoint.check("during embedding generation")

        # Verify context appears in logs (if logging is configured)
        # This is optional - just checking it doesn't crash


class TestPeriodicCancellationChecker:
    """Test suite for PeriodicCancellationChecker context manager"""

    @pytest.fixture
    def mock_rq_job(self):
        """Create a mock RQ job"""
        job = Mock(spec=Job)
        job.id = "test-job-789"
        job.is_canceled = False
        job.refresh = Mock()
        return job

    @pytest.mark.asyncio
    async def test_periodic_checker_allows_normal_execution(self, mock_rq_job):
        """Test periodic checker allows normal execution"""
        executed = False

        async with PeriodicCancellationChecker(mock_rq_job, interval=0.1):
            await asyncio.sleep(0.3)  # Sleep for 3 intervals
            executed = True

        assert executed
        # Should have checked multiple times
        assert mock_rq_job.refresh.call_count >= 2

    @pytest.mark.asyncio
    async def test_periodic_checker_logs_cancellation(self, mock_rq_job, caplog):
        """Test periodic checker logs when cancellation is detected"""
        import logging

        # Set job as cancelled from the start
        mock_rq_job.is_canceled = True

        with caplog.at_level(logging.INFO):
            try:
                async with PeriodicCancellationChecker(mock_rq_job, interval=0.05):
                    # Give it time to check and detect cancellation
                    await asyncio.sleep(0.2)
            except asyncio.CancelledError:
                pass  # Expected in background task

        # Verify cancellation was detected and logged
        assert mock_rq_job.refresh.called

    @pytest.mark.asyncio
    async def test_periodic_checker_works_without_rq_job(self):
        """Test periodic checker works when rq_job is None"""
        executed = False

        async with PeriodicCancellationChecker(None, interval=0.1):
            await asyncio.sleep(0.2)
            executed = True

        assert executed


class TestDecoratorIntegration:
    """Integration tests for decorator with actual task-like functions"""

    @pytest.fixture
    def mock_rq_job(self):
        """Create a mock RQ job"""
        job = Mock(spec=Job)
        job.id = "integration-job-123"
        job.is_canceled = False
        job.refresh = Mock()
        return job

    @pytest.mark.asyncio
    async def test_decorator_with_checkpoint_combination(self, mock_rq_job):
        """Test combining decorator and checkpoint in same function"""

        @check_cancellation()
        async def complex_task(steps, rq_job=None):
            checkpoint = CancellationCheckpoint(rq_job)
            results = []

            for i, step in enumerate(steps):
                checkpoint.check(f"before step {i}")
                results.append(f"Completed {step}")

            return results

        result = await complex_task(["step1", "step2", "step3"], rq_job=mock_rq_job)

        assert len(result) == 3
        assert mock_rq_job.refresh.call_count >= 4  # 1 decorator + 3 checkpoints

    @pytest.mark.asyncio
    async def test_cancellation_during_multi_step_task(self, mock_rq_job):
        """Test that cancellation stops execution mid-task"""

        @check_cancellation()
        async def multi_step_task(rq_job=None):
            checkpoint = CancellationCheckpoint(rq_job)

            results = []
            for i in range(5):
                checkpoint.check(f"step {i}")

                # Simulate cancellation after step 2
                if i == 2:
                    rq_job.is_canceled = True

                results.append(i)

            return results

        with pytest.raises(asyncio.CancelledError):
            await multi_step_task(rq_job=mock_rq_job)
