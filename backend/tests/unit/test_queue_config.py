"""
Unit tests for RQ Queue Configuration (queue_config.py)

Tests the Redis Queue (RQ) infrastructure for background job processing.

Features tested:
- [x] Queue initialization (high, default, low priority)
- [x] Job enqueuing and retrieval
- [x] Job status tracking
- [x] Job metadata management
- [x] Job cancellation
- [x] Queue statistics
- [x] Redis pub/sub publishing
"""

import pytest
from unittest.mock import Mock, patch, MagicMock
from rq import Queue
from rq.job import Job
from redis import Redis


class TestQueueConfig:
    """Test suite for QueueConfig class"""

    @pytest.fixture
    def mock_redis(self):
        """Create a mock Redis connection"""
        mock_redis = Mock(spec=Redis)
        mock_redis.ping.return_value = True
        return mock_redis

    @pytest.fixture
    def queue_config_instance(self, mock_redis):
        """Create QueueConfig instance with mocked Redis"""
        with patch('queue_config.Redis') as MockRedis:
            MockRedis.from_url.return_value = mock_redis

            # Import after patching
            from queue_config import QueueConfig
            config = QueueConfig()

            yield config

            # Cleanup
            config._redis_conn = None
            config._pubsub_conn = None
            config._high_queue = None
            config._default_queue = None
            config._low_queue = None

    def test_get_redis_connection_success(self, queue_config_instance, mock_redis):
        """Test successful Redis connection initialization"""
        with patch('queue_config.Redis') as MockRedis:
            MockRedis.from_url.return_value = mock_redis

            conn = queue_config_instance._get_redis_connection()

            assert conn is not None
            mock_redis.ping.assert_called_once()

    def test_get_redis_connection_cached(self, queue_config_instance, mock_redis):
        """Test that Redis connection is cached and reused"""
        queue_config_instance._redis_conn = mock_redis

        conn1 = queue_config_instance._get_redis_connection()
        conn2 = queue_config_instance._get_redis_connection()

        assert conn1 is conn2
        # Should not create new connection
        assert mock_redis.ping.call_count == 0

    def test_high_queue_initialization(self, queue_config_instance, mock_redis):
        """Test high priority queue initialization"""
        with patch('queue_config.Queue') as MockQueue:
            mock_queue = Mock(spec=Queue)
            MockQueue.return_value = mock_queue

            with patch.object(queue_config_instance, '_get_redis_connection', return_value=mock_redis):
                queue = queue_config_instance.high_queue

                assert queue is not None
                MockQueue.assert_called_once_with(
                    'high',
                    connection=mock_redis,
                    default_timeout='30m',
                    result_ttl=3600
                )

    def test_default_queue_initialization(self, queue_config_instance, mock_redis):
        """Test default priority queue initialization"""
        with patch('queue_config.Queue') as MockQueue:
            mock_queue = Mock(spec=Queue)
            MockQueue.return_value = mock_queue

            with patch.object(queue_config_instance, '_get_redis_connection', return_value=mock_redis):
                queue = queue_config_instance.default_queue

                assert queue is not None
                MockQueue.assert_called_once_with(
                    'default',
                    connection=mock_redis,
                    default_timeout='20m',
                    result_ttl=3600
                )

    def test_low_queue_initialization(self, queue_config_instance, mock_redis):
        """Test low priority queue initialization"""
        with patch('queue_config.Queue') as MockQueue:
            mock_queue = Mock(spec=Queue)
            MockQueue.return_value = mock_queue

            with patch.object(queue_config_instance, '_get_redis_connection', return_value=mock_redis):
                queue = queue_config_instance.low_queue

                assert queue is not None
                MockQueue.assert_called_once_with(
                    'low',
                    connection=mock_redis,
                    default_timeout='60m',
                    result_ttl=7200
                )

    def test_get_queue_by_priority(self, queue_config_instance, mock_redis):
        """Test getting queue by priority level"""
        # Directly set the private queue attributes to avoid property issues
        mock_high = Mock(spec=Queue)
        mock_default = Mock(spec=Queue)
        mock_low = Mock(spec=Queue)

        queue_config_instance._high_queue = mock_high
        queue_config_instance._default_queue = mock_default
        queue_config_instance._low_queue = mock_low

        # Test each priority
        assert queue_config_instance.get_queue('high') == mock_high
        assert queue_config_instance.get_queue('default') == mock_default
        assert queue_config_instance.get_queue('low') == mock_low

        # Test invalid priority defaults to 'default'
        assert queue_config_instance.get_queue('invalid') == mock_default

    def test_get_job_success(self, queue_config_instance, mock_redis):
        """Test retrieving a job by ID"""
        job_id = "test-job-123"
        mock_job = Mock(spec=Job)

        with patch('queue_config.Job.fetch', return_value=mock_job) as mock_fetch:
            with patch.object(queue_config_instance, '_get_redis_connection', return_value=mock_redis):
                job = queue_config_instance.get_job(job_id)

                assert job == mock_job
                mock_fetch.assert_called_once_with(job_id, connection=mock_redis)

    def test_get_job_not_found(self, queue_config_instance, mock_redis):
        """Test retrieving non-existent job returns None"""
        job_id = "nonexistent-job"

        with patch('queue_config.Job.fetch', side_effect=Exception("Job not found")):
            with patch.object(queue_config_instance, '_get_redis_connection', return_value=mock_redis):
                job = queue_config_instance.get_job(job_id)

                assert job is None

    def test_get_job_status(self, queue_config_instance):
        """Test getting job status"""
        job_id = "test-job-123"
        mock_job = Mock(spec=Job)
        mock_job.get_status.return_value = "started"

        with patch.object(queue_config_instance, 'get_job', return_value=mock_job):
            status = queue_config_instance.get_job_status(job_id)

            assert status == "started"
            mock_job.get_status.assert_called_once()

    def test_get_job_status_not_found(self, queue_config_instance):
        """Test getting status of non-existent job"""
        job_id = "nonexistent-job"

        with patch.object(queue_config_instance, 'get_job', return_value=None):
            status = queue_config_instance.get_job_status(job_id)

            assert status is None

    def test_get_job_progress(self, queue_config_instance):
        """Test getting job progress metadata"""
        job_id = "test-job-123"
        mock_job = Mock(spec=Job)
        mock_job.meta = {
            'progress': 50.0,
            'step': 'Processing data',
            'status': 'processing'
        }

        with patch.object(queue_config_instance, 'get_job', return_value=mock_job):
            progress = queue_config_instance.get_job_progress(job_id)

            assert progress == mock_job.meta
            assert progress['progress'] == 50.0

    def test_get_job_progress_no_metadata(self, queue_config_instance):
        """Test getting progress when job has no metadata"""
        job_id = "test-job-123"
        mock_job = Mock(spec=Job)
        del mock_job.meta  # No meta attribute

        with patch.object(queue_config_instance, 'get_job', return_value=mock_job):
            progress = queue_config_instance.get_job_progress(job_id)

            assert progress is None

    def test_cancel_job_success(self, queue_config_instance):
        """Test cancelling a job successfully"""
        job_id = "test-job-123"
        mock_job = Mock(spec=Job)

        with patch.object(queue_config_instance, 'get_job', return_value=mock_job):
            result = queue_config_instance.cancel_job(job_id)

            assert result is True
            mock_job.cancel.assert_called_once()

    def test_cancel_job_not_found(self, queue_config_instance):
        """Test cancelling non-existent job returns False"""
        job_id = "nonexistent-job"

        with patch.object(queue_config_instance, 'get_job', return_value=None):
            result = queue_config_instance.cancel_job(job_id)

            assert result is False

    def test_cancel_job_error(self, queue_config_instance):
        """Test error handling when cancelling job fails"""
        job_id = "test-job-123"
        mock_job = Mock(spec=Job)
        mock_job.cancel.side_effect = Exception("Cancel failed")

        with patch.object(queue_config_instance, 'get_job', return_value=mock_job):
            result = queue_config_instance.cancel_job(job_id)

            assert result is False

    def test_get_queue_info(self, queue_config_instance):
        """Test getting statistics for all queues"""
        # Mock queue registries
        mock_high_queue = Mock()
        mock_high_queue.__len__ = Mock(return_value=5)
        mock_high_queue.started_job_registry.count = 2
        mock_high_queue.finished_job_registry.count = 10
        mock_high_queue.failed_job_registry.count = 1

        mock_default_queue = Mock()
        mock_default_queue.__len__ = Mock(return_value=3)
        mock_default_queue.started_job_registry.count = 1
        mock_default_queue.finished_job_registry.count = 8
        mock_default_queue.failed_job_registry.count = 0

        mock_low_queue = Mock()
        mock_low_queue.__len__ = Mock(return_value=1)
        mock_low_queue.started_job_registry.count = 0
        mock_low_queue.finished_job_registry.count = 5
        mock_low_queue.failed_job_registry.count = 2

        # Directly set the private queue attributes
        queue_config_instance._high_queue = mock_high_queue
        queue_config_instance._default_queue = mock_default_queue
        queue_config_instance._low_queue = mock_low_queue

        info = queue_config_instance.get_queue_info()

        # Verify structure
        assert 'high' in info
        assert 'default' in info
        assert 'low' in info

        # Verify high queue stats
        assert info['high']['count'] == 5
        assert info['high']['started_jobs'] == 2
        assert info['high']['finished_jobs'] == 10
        assert info['high']['failed_jobs'] == 1

        # Verify default queue stats
        assert info['default']['count'] == 3
        assert info['default']['started_jobs'] == 1

        # Verify low queue stats
        assert info['low']['count'] == 1
        assert info['low']['failed_jobs'] == 2

    def test_publish_job_update(self, queue_config_instance):
        """Test publishing job update to Redis pub/sub"""
        job_id = "test-job-123"
        update_data = {
            'status': 'processing',
            'progress': 50.0,
            'step': 'Processing data'
        }

        mock_pubsub_redis = Mock()
        with patch.object(queue_config_instance, 'get_pubsub_connection', return_value=mock_pubsub_redis):
            queue_config_instance.publish_job_update(job_id, update_data)

            # Verify publish was called with correct channel and message
            mock_pubsub_redis.publish.assert_called_once()
            call_args = mock_pubsub_redis.publish.call_args
            assert call_args[0][0] == f"job_updates:{job_id}"

            # Verify message is JSON serialized
            import json
            message = json.loads(call_args[0][1])
            assert message['status'] == 'processing'
            assert message['progress'] == 50.0

    def test_publish_job_update_error_handling(self, queue_config_instance):
        """Test error handling when publishing fails"""
        job_id = "test-job-123"
        update_data = {'status': 'processing'}

        mock_pubsub_redis = Mock()
        mock_pubsub_redis.publish.side_effect = Exception("Redis connection error")

        with patch.object(queue_config_instance, 'get_pubsub_connection', return_value=mock_pubsub_redis):
            # Should not raise exception, just log error
            queue_config_instance.publish_job_update(job_id, update_data)

    def test_close_connections(self, queue_config_instance):
        """Test closing Redis connections"""
        mock_redis = Mock()
        mock_pubsub = Mock()

        queue_config_instance._redis_conn = mock_redis
        queue_config_instance._pubsub_conn = mock_pubsub

        queue_config_instance.close()

        mock_redis.close.assert_called_once()
        mock_pubsub.close.assert_called_once()

    def test_get_pubsub_connection(self, queue_config_instance):
        """Test getting separate Redis connection for pub/sub"""
        mock_pubsub_redis = Mock(spec=Redis)
        mock_pubsub_redis.ping.return_value = True

        with patch('queue_config.Redis') as MockRedis:
            MockRedis.from_url.return_value = mock_pubsub_redis

            conn = queue_config_instance.get_pubsub_connection()

            assert conn is not None
            mock_pubsub_redis.ping.assert_called_once()

            # Verify decode_responses=True for pub/sub (JSON strings)
            call_args = MockRedis.from_url.call_args
            assert call_args[1]['decode_responses'] is True

    def test_get_pubsub_connection_cached(self, queue_config_instance):
        """Test that pub/sub connection is cached"""
        mock_pubsub_redis = Mock(spec=Redis)
        queue_config_instance._pubsub_conn = mock_pubsub_redis

        conn1 = queue_config_instance.get_pubsub_connection()
        conn2 = queue_config_instance.get_pubsub_connection()

        assert conn1 is conn2
        # Should not ping again
        assert mock_pubsub_redis.ping.call_count == 0
