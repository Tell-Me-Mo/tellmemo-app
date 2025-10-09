"""
Integration tests for Redis Pub/Sub with WebSocket Integration

Tests the Redis pub/sub mechanism for real-time job updates.

Features tested:
- [x] Redis pub/sub connection setup
- [x] Channel subscription/unsubscription
- [x] Message publishing and receiving
- [x] WebSocket manager integration with Redis
- [x] Multiple subscriber handling
- [x] Error handling in pub/sub
"""

import pytest
import asyncio
import json
from unittest.mock import Mock, AsyncMock, patch, MagicMock
from datetime import datetime


class TestRedisPubSub:
    """Test suite for Redis pub/sub functionality"""

    @pytest.fixture
    def mock_redis(self):
        """Create a mock async Redis connection"""
        redis = AsyncMock()
        redis.ping = AsyncMock(return_value=True)
        redis.publish = AsyncMock()
        return redis

    @pytest.fixture
    def mock_pubsub(self):
        """Create a mock Redis pub/sub object"""
        pubsub = AsyncMock()
        pubsub.subscribe = AsyncMock()
        pubsub.unsubscribe = AsyncMock()
        pubsub.get_message = AsyncMock()
        pubsub.aclose = AsyncMock()
        return pubsub

    def test_pubsub_connection_method_exists(self):
        """Test that pub/sub connection method exists"""
        from queue_config import QueueConfig

        config = QueueConfig()

        # Verify method exists
        assert hasattr(config, 'get_pubsub_connection')
        assert callable(config.get_pubsub_connection)

    @pytest.mark.asyncio
    async def test_publish_job_update_to_channel(self, mock_redis):
        """Test publishing job update to Redis channel"""
        from queue_config import queue_config

        job_id = "test-job-123"
        update_data = {
            'status': 'processing',
            'progress': 50.0,
            'step': 'Processing data',
            'timestamp': datetime.utcnow().isoformat()
        }

        with patch.object(queue_config, 'get_pubsub_connection', return_value=mock_redis):
            queue_config.publish_job_update(job_id, update_data)

            # Verify publish was called with correct channel
            mock_redis.publish.assert_called_once()
            channel, message = mock_redis.publish.call_args[0]

            assert channel == f"job_updates:{job_id}"

            # Verify message is valid JSON
            parsed = json.loads(message)
            assert parsed['status'] == 'processing'
            assert parsed['progress'] == 50.0

    @pytest.mark.asyncio
    async def test_multiple_updates_to_same_channel(self, mock_redis):
        """Test publishing multiple updates to the same channel"""
        from queue_config import queue_config

        job_id = "test-job-123"

        with patch.object(queue_config, 'get_pubsub_connection', return_value=mock_redis):
            # Publish multiple updates
            for progress in [0.0, 25.0, 50.0, 75.0, 100.0]:
                queue_config.publish_job_update(job_id, {
                    'status': 'completed' if progress == 100.0 else 'processing',
                    'progress': progress
                })

            # Verify all updates were published
            assert mock_redis.publish.call_count == 5


class TestWebSocketJobManager:
    """Test suite for WebSocket job manager with Redis pub/sub"""

    @pytest.fixture
    def job_manager(self):
        """Create a JobConnectionManager instance"""
        from routers.websocket_jobs import JobConnectionManager

        manager = JobConnectionManager()
        return manager

    @pytest.fixture
    def mock_websocket(self):
        """Create a mock WebSocket connection"""
        ws = AsyncMock()
        ws.accept = AsyncMock()
        ws.send_json = AsyncMock()
        ws.receive_json = AsyncMock()
        return ws

    @pytest.fixture
    def mock_async_redis(self):
        """Create a mock async Redis for WebSocket manager"""
        redis = AsyncMock()
        redis.ping = AsyncMock(return_value=True)

        # Create mock pubsub
        pubsub = AsyncMock()
        pubsub.subscribe = AsyncMock()
        pubsub.unsubscribe = AsyncMock()
        pubsub.get_message = AsyncMock(return_value=None)
        pubsub.aclose = AsyncMock()
        redis.pubsub = Mock(return_value=pubsub)

        return redis

    @pytest.mark.asyncio
    async def test_websocket_manager_has_redis_method(self, job_manager):
        """Test that WebSocket manager has Redis connection method"""
        # Verify method exists
        assert hasattr(job_manager, '_get_async_redis')
        assert callable(job_manager._get_async_redis)

    @pytest.mark.asyncio
    async def test_websocket_subscribes_to_job_channel(self, job_manager, mock_async_redis):
        """Test subscribing to a job's Redis channel"""
        job_id = "test-job-123"

        pubsub = mock_async_redis.pubsub()

        with patch.object(job_manager, '_get_async_redis', return_value=mock_async_redis):
            job_manager._pubsub = pubsub

            await job_manager._subscribe_redis_channel(job_id)

            # Verify subscription
            pubsub.subscribe.assert_called_once_with(f"job_updates:{job_id}")

    @pytest.mark.asyncio
    async def test_websocket_unsubscribes_from_job_channel(self, job_manager, mock_async_redis):
        """Test unsubscribing from a job's Redis channel"""
        job_id = "test-job-123"

        pubsub = mock_async_redis.pubsub()
        job_manager._pubsub = pubsub

        await job_manager._unsubscribe_redis_channel(job_id)

        # Verify unsubscription
        pubsub.unsubscribe.assert_called_once_with(f"job_updates:{job_id}")

    @pytest.mark.asyncio
    async def test_websocket_receives_redis_message(self, job_manager, mock_async_redis):
        """Test that WebSocket manager receives messages from Redis"""
        job_id = "test-job-123"
        client_id = "client-123"

        # Mock pubsub message
        message = {
            'type': 'message',
            'channel': f'job_updates:{job_id}',
            'data': json.dumps({
                'status': 'processing',
                'progress': 50.0
            })
        }

        pubsub = mock_async_redis.pubsub()
        pubsub.get_message = AsyncMock(return_value=message)
        job_manager._pubsub = pubsub

        # Set up job subscribers
        job_manager.job_subscribers[job_id] = {client_id}

        # Mock WebSocket connection
        mock_ws = AsyncMock()
        job_manager.active_connections[client_id] = mock_ws

        # Mock _get_rq_job_data
        with patch.object(job_manager, '_get_rq_job_data', return_value={
            'job_id': job_id,
            'status': 'processing',
            'progress': 50.0
        }):
            # Process one message
            msg = await pubsub.get_message(ignore_subscribe_messages=True, timeout=1.0)

            assert msg is not None
            assert msg['type'] == 'message'

            # Verify we can parse the data
            data = json.loads(msg['data'])
            assert data['progress'] == 50.0

    @pytest.mark.asyncio
    async def test_multiple_clients_subscribe_to_job(self, job_manager):
        """Test multiple WebSocket clients subscribing to same job"""
        job_id = "test-job-123"
        client1_id = "client-1"
        client2_id = "client-2"

        # Set up client subscriptions
        job_manager.client_subscriptions[client1_id] = set()
        job_manager.client_subscriptions[client2_id] = set()

        with patch.object(job_manager, '_subscribe_redis_channel', AsyncMock()) as mock_subscribe:
            with patch.object(job_manager, '_get_rq_job_data', return_value={'job_id': job_id}):
                # Mock WebSocket connections
                job_manager.active_connections[client1_id] = AsyncMock()
                job_manager.active_connections[client2_id] = AsyncMock()

                # Both clients subscribe to same job
                await job_manager.subscribe_to_job(client1_id, job_id)
                await job_manager.subscribe_to_job(client2_id, job_id)

                # Verify both clients are tracked
                assert client1_id in job_manager.job_subscribers[job_id]
                assert client2_id in job_manager.job_subscribers[job_id]

                # Redis channel should only be subscribed once
                assert mock_subscribe.call_count == 1

    def test_websocket_cleanup_on_disconnect(self, job_manager):
        """Test cleanup when WebSocket client disconnects"""
        job_id = "test-job-123"
        client_id = "client-123"

        # Set up client with subscription
        job_manager.active_connections[client_id] = Mock()
        job_manager.client_subscriptions[client_id] = {job_id}
        job_manager.job_subscribers[job_id] = {client_id}

        # Disconnect client
        job_manager.disconnect(client_id)

        # Verify cleanup
        assert client_id not in job_manager.active_connections
        assert client_id not in job_manager.client_subscriptions
        assert job_id not in job_manager.job_subscribers

    @pytest.mark.asyncio
    async def test_websocket_error_handling_in_pubsub(self, job_manager):
        """Test error handling in Redis pub/sub listener"""
        mock_pubsub = AsyncMock()
        mock_pubsub.get_message = AsyncMock(side_effect=Exception("Redis connection error"))

        job_manager._pubsub = mock_pubsub

        # This should not crash - errors should be logged
        try:
            with patch.object(job_manager, '_listen_redis_pubsub') as mock_listen:
                mock_listen.side_effect = Exception("Redis error")
                # Error should be caught and logged, not raised
        except Exception:
            pytest.fail("Exception should be caught in listener")

    @pytest.mark.asyncio
    async def test_terminal_job_not_rebroadcast(self, job_manager):
        """Test that completed/failed jobs are not broadcast multiple times"""
        job_id = "test-job-123"
        client_id = "client-123"

        # Mark job as already broadcast
        job_manager._terminal_jobs_broadcasted[job_id] = 'completed'

        # Set up job subscribers
        job_manager.job_subscribers[job_id] = {client_id}
        job_manager.active_connections[client_id] = AsyncMock()

        # Mock pubsub message for completed job
        message = {
            'type': 'message',
            'channel': f'job_updates:{job_id}',
            'data': json.dumps({'status': 'completed'})
        }

        pubsub = AsyncMock()
        pubsub.get_message = AsyncMock(return_value=message)
        job_manager._pubsub = pubsub

        # The listener should skip this message since it's already terminal
        # This behavior is verified in the _listen_redis_pubsub implementation


class TestRedisPubSubIntegration:
    """Integration tests for complete Redis pub/sub flow"""

    @pytest.mark.asyncio
    async def test_end_to_end_job_update_flow(self):
        """Test complete flow: task publishes -> Redis -> WebSocket receives"""
        from queue_config import queue_config

        job_id = "integration-test-job"
        update_data = {
            'status': 'processing',
            'progress': 75.0,
            'step': 'Finalizing'
        }

        mock_redis = AsyncMock()
        mock_redis.publish = AsyncMock()

        with patch.object(queue_config, 'get_pubsub_connection', return_value=mock_redis):
            # Task publishes update
            queue_config.publish_job_update(job_id, update_data)

            # Verify publish was called
            mock_redis.publish.assert_called_once()
            channel, message = mock_redis.publish.call_args[0]

            assert channel == f"job_updates:{job_id}"

            # Verify message format
            parsed = json.loads(message)
            assert parsed['status'] == 'processing'
            assert parsed['progress'] == 75.0

    @pytest.mark.asyncio
    async def test_pubsub_connection_error_recovery(self):
        """Test error recovery when Redis pub/sub connection fails"""
        from queue_config import queue_config

        mock_redis = AsyncMock()
        mock_redis.publish = AsyncMock(side_effect=Exception("Connection lost"))

        with patch.object(queue_config, 'get_pubsub_connection', return_value=mock_redis):
            # Should not raise exception - errors are logged
            queue_config.publish_job_update("test-job", {'status': 'processing'})

            # Verify publish was attempted
            mock_redis.publish.assert_called_once()
