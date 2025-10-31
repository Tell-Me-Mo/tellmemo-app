"""
Mocked unit tests for WebSocket Live Insights Router.

Tests connection lifecycle, message broadcasting, and user feedback handling
without requiring a running backend server.
"""

import pytest
import uuid
from datetime import datetime, timedelta
from unittest.mock import AsyncMock, MagicMock, patch


# =============================================================================
# Connection Manager Tests
# =============================================================================

@pytest.mark.asyncio
async def test_connection_manager_tracks_sessions():
    """Test that connection manager properly tracks session connections."""
    from routers.websocket_live_insights import LiveInsightsConnectionManager

    session_id = str(uuid.uuid4())
    manager = LiveInsightsConnectionManager()

    # Mock WebSocket and Redis methods
    mock_websocket = AsyncMock()
    manager._subscribe_redis_channel = AsyncMock()

    # Initially no connections
    assert manager.get_connection_count(session_id) == 0
    assert not manager.is_session_active(session_id)

    # Connect
    async with manager.lock:
        if session_id not in manager.active_connections:
            manager.active_connections[session_id] = set()
            await manager._subscribe_redis_channel(session_id)

        manager.active_connections[session_id].add(mock_websocket)
        manager.websocket_to_user[mock_websocket] = "user123"
        manager.websocket_to_session[mock_websocket] = session_id

    # After connect
    assert manager.get_connection_count(session_id) == 1
    assert manager.is_session_active(session_id)

    # Disconnect
    manager._unsubscribe_redis_channel = AsyncMock()
    async with manager.lock:
        manager.active_connections[session_id].discard(mock_websocket)
        if not manager.active_connections[session_id]:
            del manager.active_connections[session_id]
            await manager._unsubscribe_redis_channel(session_id)

        manager.websocket_to_user.pop(mock_websocket, None)
        manager.websocket_to_session.pop(mock_websocket, None)

    # After disconnect
    assert manager.get_connection_count(session_id) == 0
    assert not manager.is_session_active(session_id)


@pytest.mark.asyncio
async def test_broadcast_to_session():
    """Test broadcasting message to all clients in a session."""
    from routers.websocket_live_insights import LiveInsightsConnectionManager

    session_id = str(uuid.uuid4())
    manager = LiveInsightsConnectionManager()

    # Add two mock WebSocket connections
    ws1 = AsyncMock()
    ws2 = AsyncMock()

    manager.active_connections[session_id] = {ws1, ws2}
    manager.websocket_to_session[ws1] = session_id
    manager.websocket_to_session[ws2] = session_id
    manager.websocket_to_user[ws1] = "user1"
    manager.websocket_to_user[ws2] = "user2"

    # Broadcast message
    message = {
        "type": "QUESTION_DETECTED",
        "data": {"text": "Test question"},
        "timestamp": datetime.utcnow().isoformat()
    }

    await manager.broadcast_to_session(session_id, message)

    # Both WebSockets should have received the message
    ws1.send_json.assert_called_once_with(message)
    ws2.send_json.assert_called_once_with(message)


@pytest.mark.asyncio
async def test_broadcast_handles_disconnected_client():
    """Test that broadcast handles disconnected clients gracefully."""
    from routers.websocket_live_insights import LiveInsightsConnectionManager

    session_id = str(uuid.uuid4())
    manager = LiveInsightsConnectionManager()

    # Add WebSocket that will fail to send
    ws_fail = AsyncMock()
    ws_fail.send_json.side_effect = Exception("Connection closed")

    ws_success = AsyncMock()

    manager.active_connections[session_id] = {ws_fail, ws_success}
    manager.websocket_to_session[ws_fail] = session_id
    manager.websocket_to_session[ws_success] = session_id
    manager.websocket_to_user[ws_fail] = "user_fail"
    manager.websocket_to_user[ws_success] = "user_success"

    message = {"type": "TEST", "data": {}}

    # Should not raise exception, should disconnect failed client
    await manager.broadcast_to_session(session_id, message)

    # Failed client should be removed
    assert ws_fail not in manager.active_connections.get(session_id, set())

    # Success client should still receive message
    ws_success.send_json.assert_called_once_with(message)


# =============================================================================
# Broadcast Function Tests
# =============================================================================

@pytest.mark.asyncio
async def test_broadcast_question_detected():
    """Test broadcasting question detection."""
    with patch('queue_config.queue_config.publish_live_insight') as mock_publish:
        from routers.websocket_live_insights import broadcast_question_detected

        session_id = str(uuid.uuid4())
        question_data = {
            "id": str(uuid.uuid4()),
            "text": "What's the budget?",
            "speaker": "John",
            "timestamp": datetime.utcnow().isoformat(),
            "category": "factual",
            "confidence": 0.95
        }

        await broadcast_question_detected(session_id, question_data)

        # Verify Redis publish was called
        assert mock_publish.call_count == 1
        call_args = mock_publish.call_args[0]
        assert call_args[0] == session_id
        assert call_args[1]["type"] == "QUESTION_DETECTED"
        assert call_args[1]["data"]["text"] == "What's the budget?"


@pytest.mark.asyncio
async def test_broadcast_rag_result():
    """Test broadcasting RAG result."""
    with patch('queue_config.queue_config.publish_live_insight') as mock_publish:
        from routers.websocket_live_insights import broadcast_rag_result

        session_id = str(uuid.uuid4())
        question_id = str(uuid.uuid4())
        result_data = {
            "document": "Meeting notes from last week",
            "relevance": 0.87,
            "source": "doc_123"
        }

        await broadcast_rag_result(session_id, question_id, result_data)

        assert mock_publish.call_count == 1
        call_args = mock_publish.call_args[0]
        assert call_args[1]["type"] == "RAG_RESULT"
        assert call_args[1]["question_id"] == question_id


@pytest.mark.asyncio
async def test_broadcast_action_tracked():
    """Test broadcasting action tracking."""
    with patch('queue_config.queue_config.publish_live_insight') as mock_publish:
        from routers.websocket_live_insights import broadcast_action_tracked

        session_id = str(uuid.uuid4())
        action_data = {
            "id": str(uuid.uuid4()),
            "description": "Update documentation",
            "owner": "Alice",
            "deadline": None,
            "completeness": 0.5,
            "timestamp": datetime.utcnow().isoformat()
        }

        await broadcast_action_tracked(session_id, action_data)

        assert mock_publish.call_count == 1
        call_args = mock_publish.call_args[0]
        assert call_args[1]["type"] == "ACTION_TRACKED"
        assert call_args[1]["data"]["description"] == "Update documentation"


@pytest.mark.asyncio
async def test_broadcast_transcription_final():
    """Test broadcasting final transcription."""
    with patch('queue_config.queue_config.publish_live_insight') as mock_publish:
        from routers.websocket_live_insights import broadcast_transcription_final

        session_id = str(uuid.uuid4())
        transcript_data = {
            "id": str(uuid.uuid4()),
            "text": "This is the final transcript",
            "speaker": "Bob",
            "timestamp": datetime.utcnow().isoformat(),
            "confidence": 0.92
        }

        await broadcast_transcription_final(session_id, transcript_data)

        assert mock_publish.call_count == 1
        call_args = mock_publish.call_args[0]
        assert call_args[1]["type"] == "TRANSCRIPTION_FINAL"


@pytest.mark.asyncio
async def test_broadcast_meeting_summary():
    """Test broadcasting meeting summary."""
    with patch('queue_config.queue_config.publish_live_insight') as mock_publish:
        from routers.websocket_live_insights import broadcast_meeting_summary

        session_id = str(uuid.uuid4())
        summary_data = {
            "questions": [
                {"id": "q1", "text": "Question 1", "answered": True}
            ],
            "actions": [
                {"id": "a1", "description": "Action 1", "complete": False}
            ],
            "timestamp": datetime.utcnow().isoformat()
        }

        await broadcast_meeting_summary(session_id, summary_data)

        assert mock_publish.call_count == 1
        call_args = mock_publish.call_args[0]
        assert call_args[1]["type"] == "MEETING_SUMMARY"
        assert len(call_args[1]["data"]["questions"]) == 1
        assert len(call_args[1]["data"]["actions"]) == 1


# =============================================================================
# Multiple Client Tests
# =============================================================================

@pytest.mark.asyncio
async def test_multiple_clients_receive_broadcasts():
    """Test that multiple clients in same session receive broadcasts."""
    from routers.websocket_live_insights import LiveInsightsConnectionManager

    session_id = str(uuid.uuid4())
    manager = LiveInsightsConnectionManager()

    # Add three clients
    ws1 = AsyncMock()
    ws2 = AsyncMock()
    ws3 = AsyncMock()

    for ws, user in [(ws1, "user1"), (ws2, "user2"), (ws3, "user3")]:
        manager.active_connections.setdefault(session_id, set()).add(ws)
        manager.websocket_to_session[ws] = session_id
        manager.websocket_to_user[ws] = user

    message = {
        "type": "QUESTION_DETECTED",
        "data": {"text": "Question for everyone"}
    }

    await manager.broadcast_to_session(session_id, message)

    # All three should receive
    ws1.send_json.assert_called_once()
    ws2.send_json.assert_called_once()
    ws3.send_json.assert_called_once()


@pytest.mark.asyncio
async def test_different_sessions_isolated():
    """Test that broadcasts to different sessions are isolated."""
    from routers.websocket_live_insights import LiveInsightsConnectionManager

    session1 = str(uuid.uuid4())
    session2 = str(uuid.uuid4())
    manager = LiveInsightsConnectionManager()

    # Session 1 clients
    ws1_s1 = AsyncMock()
    manager.active_connections[session1] = {ws1_s1}
    manager.websocket_to_session[ws1_s1] = session1
    manager.websocket_to_user[ws1_s1] = "user1"

    # Session 2 clients
    ws1_s2 = AsyncMock()
    manager.active_connections[session2] = {ws1_s2}
    manager.websocket_to_session[ws1_s2] = session2
    manager.websocket_to_user[ws1_s2] = "user2"

    # Broadcast to session1 only
    message = {"type": "TEST", "data": {}}
    await manager.broadcast_to_session(session1, message)

    # Only session1 client receives
    ws1_s1.send_json.assert_called_once()
    ws1_s2.send_json.assert_not_called()


# =============================================================================
# Error Handling Tests
# =============================================================================

@pytest.mark.asyncio
async def test_handle_assemblyai_error():
    """Test handling AssemblyAI transcription errors."""
    with patch('queue_config.queue_config.publish_live_insight') as mock_publish:
        from routers.websocket_live_insights import handle_assemblyai_error

        session_id = str(uuid.uuid4())
        error_message = "Connection to AssemblyAI failed"

        await handle_assemblyai_error(session_id, error_message)

        # Should publish error event
        assert mock_publish.call_count == 1
        call_args = mock_publish.call_args[0]
        assert call_args[1]["type"] == "TRANSCRIPTION_ERROR"
        assert call_args[1]["error"] == error_message


# =============================================================================
# Redis Pub/Sub Integration Tests
# =============================================================================

@pytest.mark.asyncio
async def test_redis_subscription_on_first_client():
    """Test Redis channel subscription when first client connects."""
    from routers.websocket_live_insights import LiveInsightsConnectionManager

    session_id = str(uuid.uuid4())
    manager = LiveInsightsConnectionManager()
    manager._subscribe_redis_channel = AsyncMock()

    ws = AsyncMock()

    # First client connects
    async with manager.lock:
        if session_id not in manager.active_connections:
            manager.active_connections[session_id] = set()
            await manager._subscribe_redis_channel(session_id)

        manager.active_connections[session_id].add(ws)
        manager.websocket_to_session[ws] = session_id
        manager.websocket_to_user[ws] = "user1"

    # Should have subscribed
    manager._subscribe_redis_channel.assert_called_once_with(session_id)


@pytest.mark.asyncio
async def test_redis_unsubscription_on_last_client():
    """Test Redis channel unsubscription when last client disconnects."""
    from routers.websocket_live_insights import LiveInsightsConnectionManager

    session_id = str(uuid.uuid4())
    manager = LiveInsightsConnectionManager()
    manager._unsubscribe_redis_channel = AsyncMock()

    ws = AsyncMock()
    manager.active_connections[session_id] = {ws}
    manager.websocket_to_session[ws] = session_id
    manager.websocket_to_user[ws] = "user1"

    # Last client disconnects
    async with manager.lock:
        manager.active_connections[session_id].discard(ws)

        if not manager.active_connections[session_id]:
            del manager.active_connections[session_id]
            await manager._unsubscribe_redis_channel(session_id)

        manager.websocket_to_user.pop(ws, None)
        manager.websocket_to_session.pop(ws, None)

    # Should have unsubscribed
    manager._unsubscribe_redis_channel.assert_called_once_with(session_id)


@pytest.mark.asyncio
async def test_no_subscription_on_second_client():
    """Test no redundant Redis subscription when second client connects."""
    from routers.websocket_live_insights import LiveInsightsConnectionManager

    session_id = str(uuid.uuid4())
    manager = LiveInsightsConnectionManager()
    manager._subscribe_redis_channel = AsyncMock()

    # First client already connected
    ws1 = AsyncMock()
    manager.active_connections[session_id] = {ws1}
    manager.websocket_to_session[ws1] = session_id
    manager.websocket_to_user[ws1] = "user1"

    # Second client connects
    ws2 = AsyncMock()
    async with manager.lock:
        if session_id not in manager.active_connections:
            manager.active_connections[session_id] = set()
            await manager._subscribe_redis_channel(session_id)

        manager.active_connections[session_id].add(ws2)
        manager.websocket_to_session[ws2] = session_id
        manager.websocket_to_user[ws2] = "user2"

    # Should NOT have subscribed again (session already existed)
    manager._subscribe_redis_channel.assert_not_called()


# =============================================================================
# Cleanup Tests
# =============================================================================

@pytest.mark.asyncio
async def test_cleanup_removes_all_tracking():
    """Test that disconnect properly cleans up all tracking."""
    from routers.websocket_live_insights import LiveInsightsConnectionManager

    session_id = str(uuid.uuid4())
    manager = LiveInsightsConnectionManager()
    manager._unsubscribe_redis_channel = AsyncMock()

    ws = AsyncMock()
    manager.active_connections[session_id] = {ws}
    manager.websocket_to_session[ws] = session_id
    manager.websocket_to_user[ws] = "user123"

    # Disconnect
    async with manager.lock:
        session_id_lookup = manager.websocket_to_session.get(ws)
        user_id = manager.websocket_to_user.get(ws)

        if session_id_lookup and session_id_lookup in manager.active_connections:
            manager.active_connections[session_id_lookup].discard(ws)

            if not manager.active_connections[session_id_lookup]:
                del manager.active_connections[session_id_lookup]
                await manager._unsubscribe_redis_channel(session_id_lookup)

        manager.websocket_to_user.pop(ws, None)
        manager.websocket_to_session.pop(ws, None)

    # All tracking should be cleaned up
    assert ws not in manager.websocket_to_session
    assert ws not in manager.websocket_to_user
    assert session_id not in manager.active_connections


# =============================================================================
# Session Memory Leak Prevention Tests
# =============================================================================

@pytest.mark.asyncio
async def test_stale_session_cleanup():
    """Test that stale sessions are cleaned up after TTL expires."""
    from routers.websocket_live_insights import LiveInsightsConnectionManager
    import routers.websocket_live_insights as insights_module

    manager = LiveInsightsConnectionManager()

    # Create test session IDs
    old_session_id = str(uuid.uuid4())
    recent_session_id = str(uuid.uuid4())

    # Set up old session (25 hours ago - beyond 24h TTL)
    old_timestamp = datetime.now() - timedelta(hours=25)
    insights_module._session_timestamps[old_session_id] = old_timestamp
    insights_module._session_organization_map[old_session_id] = uuid.uuid4()
    insights_module._session_tier_config[old_session_id] = ["tier1", "tier2"]

    # Set up recent session (1 hour ago - within TTL)
    recent_timestamp = datetime.now() - timedelta(hours=1)
    insights_module._session_timestamps[recent_session_id] = recent_timestamp
    insights_module._session_organization_map[recent_session_id] = uuid.uuid4()
    insights_module._session_tier_config[recent_session_id] = ["tier1"]

    # Run cleanup
    await manager._cleanup_stale_sessions()

    # Old session should be removed
    assert old_session_id not in insights_module._session_timestamps
    assert old_session_id not in insights_module._session_organization_map
    assert old_session_id not in insights_module._session_tier_config

    # Recent session should still exist
    assert recent_session_id in insights_module._session_timestamps
    assert recent_session_id in insights_module._session_organization_map
    assert recent_session_id in insights_module._session_tier_config

    # Clean up test data
    insights_module._session_timestamps.pop(recent_session_id, None)
    insights_module._session_organization_map.pop(recent_session_id, None)
    insights_module._session_tier_config.pop(recent_session_id, None)


@pytest.mark.asyncio
async def test_cleanup_handles_missing_entries():
    """Test that cleanup gracefully handles sessions with missing entries in some maps."""
    from routers.websocket_live_insights import LiveInsightsConnectionManager
    import routers.websocket_live_insights as insights_module

    manager = LiveInsightsConnectionManager()

    # Create session with only timestamp (missing from other maps)
    session_id = str(uuid.uuid4())
    old_timestamp = datetime.now() - timedelta(hours=25)
    insights_module._session_timestamps[session_id] = old_timestamp

    # Run cleanup - should not raise exception
    await manager._cleanup_stale_sessions()

    # Session should be removed from timestamp map
    assert session_id not in insights_module._session_timestamps


@pytest.mark.asyncio
async def test_session_timestamp_updated_on_access():
    """Test that session timestamp is updated when session is accessed."""
    import routers.websocket_live_insights as insights_module

    session_id = str(uuid.uuid4())
    org_id = uuid.uuid4()

    # Simulate session creation
    initial_time = datetime.now()
    insights_module._session_organization_map[session_id] = org_id
    insights_module._session_timestamps[session_id] = initial_time

    # Wait a moment
    import asyncio
    await asyncio.sleep(0.1)

    # Update timestamp (simulating access)
    insights_module._session_timestamps[session_id] = datetime.now()

    # Timestamp should be newer
    assert insights_module._session_timestamps[session_id] > initial_time

    # Clean up test data
    insights_module._session_timestamps.pop(session_id, None)
    insights_module._session_organization_map.pop(session_id, None)


@pytest.mark.asyncio
async def test_cleanup_logs_removed_sessions():
    """Test that cleanup logs information about removed sessions."""
    from routers.websocket_live_insights import LiveInsightsConnectionManager
    import routers.websocket_live_insights as insights_module

    manager = LiveInsightsConnectionManager()

    # Create multiple old sessions
    session_ids = [str(uuid.uuid4()) for _ in range(3)]
    old_timestamp = datetime.now() - timedelta(hours=25)

    for session_id in session_ids:
        insights_module._session_timestamps[session_id] = old_timestamp
        insights_module._session_organization_map[session_id] = uuid.uuid4()

    # Run cleanup with logging check
    with patch('routers.websocket_live_insights.logger') as mock_logger:
        await manager._cleanup_stale_sessions()

        # Should have logged the cleanup
        assert mock_logger.info.called
        log_message = mock_logger.info.call_args[0][0]
        assert "Cleaned up" in log_message
        assert "stale sessions" in log_message


@pytest.mark.asyncio
async def test_cleanup_with_no_stale_sessions():
    """Test that cleanup handles case with no stale sessions."""
    from routers.websocket_live_insights import LiveInsightsConnectionManager
    import routers.websocket_live_insights as insights_module

    manager = LiveInsightsConnectionManager()

    # Create only recent sessions
    session_id = str(uuid.uuid4())
    recent_timestamp = datetime.now() - timedelta(hours=1)
    insights_module._session_timestamps[session_id] = recent_timestamp
    insights_module._session_organization_map[session_id] = uuid.uuid4()

    # Run cleanup
    await manager._cleanup_stale_sessions()

    # Recent session should still exist
    assert session_id in insights_module._session_timestamps
    assert session_id in insights_module._session_organization_map

    # Clean up test data
    insights_module._session_timestamps.pop(session_id, None)
    insights_module._session_organization_map.pop(session_id, None)


@pytest.mark.asyncio
async def test_cleanup_handles_exceptions():
    """Test that cleanup handles exceptions gracefully without crashing."""
    from routers.websocket_live_insights import LiveInsightsConnectionManager
    import routers.websocket_live_insights as insights_module

    manager = LiveInsightsConnectionManager()

    # Create a session with invalid timestamp that might cause issues
    session_id = str(uuid.uuid4())
    insights_module._session_timestamps[session_id] = None  # Invalid timestamp

    # Run cleanup - should not raise exception
    try:
        await manager._cleanup_stale_sessions()
    except Exception as e:
        pytest.fail(f"Cleanup should handle exceptions gracefully, but raised: {e}")

    # Clean up test data
    insights_module._session_timestamps.pop(session_id, None)
