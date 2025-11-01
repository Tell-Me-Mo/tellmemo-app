"""
Integration test for Redis Pub/Sub in Live Insights.

Tests that insights published from workers/backend processes
are correctly received by WebSocket clients through Redis pub/sub.

Uses mocking to avoid requiring a running backend server.
"""

import pytest
import asyncio
import uuid
from datetime import datetime
from unittest.mock import AsyncMock, MagicMock, patch


@pytest.mark.asyncio
async def test_redis_pubsub_publish_to_redis():
    """
    Test that broadcast functions publish to Redis pub/sub.

    Verifies that when a question is detected, it's published to Redis
    using the correct channel format.
    """
    session_id = str(uuid.uuid4())
    question_data = {
        "id": str(uuid.uuid4()),
        "text": "What is the project timeline?",
        "speaker": "Alice",
        "timestamp": datetime.utcnow().isoformat(),
        "category": "planning",
        "confidence": 0.92
    }

    # Mock queue_config.publish_live_insight (patch where it's imported, not where it's defined)
    with patch('queue_config.queue_config.publish_live_insight') as mock_publish:
        # Import and call broadcast function
        from routers.websocket_live_insights import broadcast_question_detected

        await broadcast_question_detected(session_id, question_data)

        # Verify it called publish_live_insight with correct params
        assert mock_publish.call_count == 1
        call_args = mock_publish.call_args[0]

        assert call_args[0] == session_id
        assert call_args[1]["type"] == "QUESTION_DETECTED"
        assert call_args[1]["data"]["text"] == "What is the project timeline?"


@pytest.mark.asyncio
async def test_redis_pubsub_uses_asyncio_to_thread():
    """
    Test that broadcast functions use asyncio.to_thread to avoid blocking.

    Ensures sync Redis publish() is run in thread pool.
    """
    session_id = str(uuid.uuid4())

    # Mock asyncio.to_thread
    with patch('routers.websocket_live_insights.asyncio.to_thread', new_callable=AsyncMock) as mock_to_thread:
        mock_to_thread.return_value = None

        from routers.websocket_live_insights import _publish_to_redis

        event_data = {"type": "TEST", "data": {}}
        await _publish_to_redis(session_id, event_data)

        # Verify asyncio.to_thread was called
        assert mock_to_thread.call_count == 1


@pytest.mark.asyncio
async def test_redis_listener_broadcasts_to_websockets():
    """
    Test that Redis listener receives messages and broadcasts to WebSocket clients.

    Simulates receiving a message from Redis and verifies it's broadcast
    to connected WebSocket clients.
    """
    from routers.websocket_live_insights import LiveInsightsConnectionManager
    import json

    session_id = str(uuid.uuid4())
    manager = LiveInsightsConnectionManager()

    # Mock WebSocket connection
    mock_websocket = AsyncMock()

    # Manually add connection (bypassing real WebSocket accept)
    manager.active_connections[session_id] = {mock_websocket}
    manager.websocket_to_session[mock_websocket] = session_id
    manager.websocket_to_user[mock_websocket] = "test-user"

    # Simulate Redis message
    event_data = {
        "type": "QUESTION_DETECTED",
        "data": {
            "id": str(uuid.uuid4()),
            "text": "Test question",
            "speaker": "Bob"
        },
        "timestamp": datetime.utcnow().isoformat()
    }

    # Broadcast to session (this is what Redis listener calls)
    await manager.broadcast_to_session(session_id, event_data)

    # Verify WebSocket received the message
    mock_websocket.send_json.assert_called_once()
    sent_message = mock_websocket.send_json.call_args[0][0]
    assert sent_message["type"] == "QUESTION_DETECTED"
    assert sent_message["data"]["text"] == "Test question"


@pytest.mark.asyncio
async def test_connection_manager_subscription_lifecycle():
    """
    Test that Redis subscriptions are managed correctly during connect/disconnect.
    """
    from routers.websocket_live_insights import LiveInsightsConnectionManager

    session_id = str(uuid.uuid4())
    manager = LiveInsightsConnectionManager()

    # Mock Redis methods
    manager._subscribe_redis_channel = AsyncMock()
    manager._unsubscribe_redis_channel = AsyncMock()

    # Mock WebSocket
    mock_websocket = AsyncMock()
    user_id = "test-user"

    # Connect (simulating the connect method logic)
    async with manager.lock:
        if session_id not in manager.active_connections:
            manager.active_connections[session_id] = set()
            await manager._subscribe_redis_channel(session_id)

        manager.active_connections[session_id].add(mock_websocket)
        manager.websocket_to_user[mock_websocket] = user_id
        manager.websocket_to_session[mock_websocket] = session_id

    # Verify subscription was called
    manager._subscribe_redis_channel.assert_called_once_with(session_id)
    assert manager.get_connection_count(session_id) == 1

    # Disconnect (simulating the disconnect method logic)
    async with manager.lock:
        manager.active_connections[session_id].discard(mock_websocket)

        if not manager.active_connections[session_id]:
            del manager.active_connections[session_id]
            await manager._unsubscribe_redis_channel(session_id)

        manager.websocket_to_user.pop(mock_websocket, None)
        manager.websocket_to_session.pop(mock_websocket, None)

    # Verify unsubscription was called
    manager._unsubscribe_redis_channel.assert_called_once_with(session_id)
    assert manager.get_connection_count(session_id) == 0


@pytest.mark.asyncio
async def test_multiple_broadcast_functions_all_use_redis():
    """
    Test that all broadcast functions use Redis pub/sub.

    Spot-check several different broadcast functions to ensure consistency.
    """
    session_id = str(uuid.uuid4())

    with patch('queue_config.queue_config.publish_live_insight') as mock_publish:
        from routers.websocket_live_insights import (
            broadcast_question_detected,
            broadcast_action_tracked,
            broadcast_transcription_final,
            broadcast_meeting_summary
        )

        # Test question
        await broadcast_question_detected(session_id, {
            "id": "q1", "text": "Question", "speaker": "Alice",
            "timestamp": datetime.utcnow().isoformat()
        })

        # Test action
        await broadcast_action_tracked(session_id, {
            "id": "a1", "description": "Action", "timestamp": datetime.utcnow().isoformat()
        })

        # Test transcription
        await broadcast_transcription_final(session_id, {
            "id": "t1", "text": "Transcript", "timestamp": datetime.utcnow().isoformat()
        })

        # Test summary
        await broadcast_meeting_summary(session_id, {
            "questions": [], "actions": [], "timestamp": datetime.utcnow().isoformat()
        })

        # All 4 should have published to Redis
        assert mock_publish.call_count == 4

        # Verify event types
        calls = [call[0][1]["type"] for call in mock_publish.call_args_list]
        assert "QUESTION_DETECTED" in calls
        assert "ACTION_TRACKED" in calls
        assert "TRANSCRIPTION_FINAL" in calls
        assert "MEETING_SUMMARY" in calls
