"""
Integration tests for WebSocket Live Insights Router.

Tests connection lifecycle, authentication, message broadcasting,
and user feedback handling.
"""

import pytest
import uuid
from datetime import datetime

from tests.websocket_test_utils import WebSocketTestClient, wait_for_websocket_message, send_and_receive


# =============================================================================
# Connection and Authentication Tests
# =============================================================================

@pytest.mark.asyncio
async def test_websocket_connection_success(ws_token: str):
    """Test successful WebSocket connection with valid token."""
    session_id = str(uuid.uuid4())
    ws_client = WebSocketTestClient()

    try:
        # Connect with valid token
        await ws_client.connect(
            f"/ws/live-insights/{session_id}",
            params={"token": ws_token}
        )

        # Should receive connection confirmation
        message = await ws_client.receive_json(timeout=3.0)

        assert message["type"] == "connection"
        assert message["status"] == "connected"
        assert message["session_id"] == session_id
        assert "user_id" in message
        assert "timestamp" in message

    finally:
        await ws_client.disconnect()


@pytest.mark.asyncio
async def test_websocket_connection_unauthorized():
    """Test WebSocket connection fails without valid token."""
    session_id = str(uuid.uuid4())
    ws_client = WebSocketTestClient()

    try:
        # Attempt connection with invalid token
        await ws_client.connect(
            f"/ws/live-insights/{session_id}",
            params={"token": "invalid_token"}
        )

        # Connection should be closed by server
        # WebSocket will raise exception on closure
        pytest.fail("Expected connection to be rejected")

    except Exception as e:
        # Expected behavior - connection rejected
        assert "Unauthorized" in str(e) or "close" in str(e).lower()

    finally:
        await ws_client.disconnect()


@pytest.mark.asyncio
async def test_websocket_ping_pong(ws_token: str):
    """Test heartbeat ping/pong mechanism."""
    session_id = str(uuid.uuid4())
    ws_client = WebSocketTestClient()

    try:
        # Connect
        await ws_client.connect(
            f"/ws/live-insights/{session_id}",
            params={"token": ws_token}
        )

        # Wait for connection message
        await ws_client.receive_json(timeout=3.0)

        # Send ping
        await ws_client.send_json({"type": "ping"})

        # Should receive pong
        response = await wait_for_websocket_message(ws_client, "pong", timeout=3.0)

        assert response is not None
        assert response["type"] == "pong"
        assert "timestamp" in response

    finally:
        await ws_client.disconnect()


# =============================================================================
# User Feedback Tests
# =============================================================================

@pytest.mark.asyncio
async def test_mark_question_answered(ws_token: str):
    """Test user marking question as answered."""
    session_id = str(uuid.uuid4())
    question_id = str(uuid.uuid4())
    ws_client = WebSocketTestClient()

    try:
        # Connect
        await ws_client.connect(
            f"/ws/live-insights/{session_id}",
            params={"token": ws_token}
        )

        # Wait for connection message
        await ws_client.receive_json(timeout=3.0)

        # Send mark_answered feedback
        response = await send_and_receive(
            ws_client,
            send_data={
                "type": "mark_answered",
                "question_id": question_id
            },
            expected_type="feedback_received",
            timeout=3.0
        )

        assert response["action"] == "mark_answered"
        assert response["question_id"] == question_id

    finally:
        await ws_client.disconnect()


@pytest.mark.asyncio
async def test_assign_action(ws_token: str):
    """Test user assigning action to someone."""
    session_id = str(uuid.uuid4())
    action_id = str(uuid.uuid4())
    ws_client = WebSocketTestClient()

    try:
        # Connect
        await ws_client.connect(
            f"/ws/live-insights/{session_id}",
            params={"token": ws_token}
        )

        # Wait for connection message
        await ws_client.receive_json(timeout=3.0)

        # Send assign_action feedback
        response = await send_and_receive(
            ws_client,
            send_data={
                "type": "assign_action",
                "action_id": action_id,
                "owner": "John Doe"
            },
            expected_type="feedback_received",
            timeout=3.0
        )

        assert response["action"] == "assign_action"
        assert response["action_id"] == action_id
        assert response["owner"] == "John Doe"

    finally:
        await ws_client.disconnect()


@pytest.mark.asyncio
async def test_set_deadline(ws_token: str):
    """Test user setting deadline for action."""
    session_id = str(uuid.uuid4())
    action_id = str(uuid.uuid4())
    deadline = "2025-10-30"
    ws_client = WebSocketTestClient()

    try:
        # Connect
        await ws_client.connect(
            f"/ws/live-insights/{session_id}",
            params={"token": ws_token}
        )

        # Wait for connection message
        await ws_client.receive_json(timeout=3.0)

        # Send set_deadline feedback
        response = await send_and_receive(
            ws_client,
            send_data={
                "type": "set_deadline",
                "action_id": action_id,
                "deadline": deadline
            },
            expected_type="feedback_received",
            timeout=3.0
        )

        assert response["action"] == "set_deadline"
        assert response["action_id"] == action_id
        assert response["deadline"] == deadline

    finally:
        await ws_client.disconnect()


@pytest.mark.asyncio
async def test_dismiss_question(ws_token: str):
    """Test user dismissing a question."""
    session_id = str(uuid.uuid4())
    question_id = str(uuid.uuid4())
    ws_client = WebSocketTestClient()

    try:
        # Connect
        await ws_client.connect(
            f"/ws/live-insights/{session_id}",
            params={"token": ws_token}
        )

        # Wait for connection message
        await ws_client.receive_json(timeout=3.0)

        # Send dismiss_question feedback
        response = await send_and_receive(
            ws_client,
            send_data={
                "type": "dismiss_question",
                "question_id": question_id
            },
            expected_type="feedback_received",
            timeout=3.0
        )

        assert response["action"] == "dismiss_question"
        assert response["question_id"] == question_id

    finally:
        await ws_client.disconnect()


@pytest.mark.asyncio
async def test_dismiss_action(ws_token: str):
    """Test user dismissing an action."""
    session_id = str(uuid.uuid4())
    action_id = str(uuid.uuid4())
    ws_client = WebSocketTestClient()

    try:
        # Connect
        await ws_client.connect(
            f"/ws/live-insights/{session_id}",
            params={"token": ws_token}
        )

        # Wait for connection message
        await ws_client.receive_json(timeout=3.0)

        # Send dismiss_action feedback
        response = await send_and_receive(
            ws_client,
            send_data={
                "type": "dismiss_action",
                "action_id": action_id
            },
            expected_type="feedback_received",
            timeout=3.0
        )

        assert response["action"] == "dismiss_action"
        assert response["action_id"] == action_id

    finally:
        await ws_client.disconnect()


@pytest.mark.asyncio
async def test_mark_action_complete(ws_token: str):
    """Test user marking action as complete."""
    session_id = str(uuid.uuid4())
    action_id = str(uuid.uuid4())
    ws_client = WebSocketTestClient()

    try:
        # Connect
        await ws_client.connect(
            f"/ws/live-insights/{session_id}",
            params={"token": ws_token}
        )

        # Wait for connection message
        await ws_client.receive_json(timeout=3.0)

        # Send mark_complete feedback
        response = await send_and_receive(
            ws_client,
            send_data={
                "type": "mark_complete",
                "action_id": action_id
            },
            expected_type="feedback_received",
            timeout=3.0
        )

        assert response["action"] == "mark_complete"
        assert response["action_id"] == action_id

    finally:
        await ws_client.disconnect()


# =============================================================================
# Error Handling Tests
# =============================================================================

@pytest.mark.asyncio
async def test_invalid_json_handling(ws_token: str):
    """Test handling of invalid JSON from client."""
    session_id = str(uuid.uuid4())
    ws_client = WebSocketTestClient()

    try:
        # Connect
        await ws_client.connect(
            f"/ws/live-insights/{session_id}",
            params={"token": ws_token}
        )

        # Wait for connection message
        await ws_client.receive_json(timeout=3.0)

        # Send invalid JSON (will be handled by test client as best effort)
        # In real scenario, malformed JSON would trigger error response
        await ws_client.send_json({"type": "unknown_type", "data": "test"})

        # Should receive error response
        response = await wait_for_websocket_message(ws_client, "error", timeout=3.0)

        assert response is not None
        assert response["type"] == "error"
        assert "error" in response

    finally:
        await ws_client.disconnect()


# =============================================================================
# Broadcasting Tests
# =============================================================================

@pytest.mark.asyncio
async def test_broadcast_to_multiple_clients(ws_token: str):
    """Test broadcasting messages to multiple clients in same session."""
    session_id = str(uuid.uuid4())
    ws_client1 = WebSocketTestClient()
    ws_client2 = WebSocketTestClient()

    try:
        # Connect both clients to same session (simulating multi-device)
        await ws_client1.connect(
            f"/ws/live-insights/{session_id}",
            params={"token": ws_token}
        )
        await ws_client2.connect(
            f"/ws/live-insights/{session_id}",
            params={"token": ws_token}
        )

        # Wait for connection messages
        await ws_client1.receive_json(timeout=3.0)
        await ws_client2.receive_json(timeout=3.0)

        # Simulate broadcast by importing broadcast function
        # This would normally be triggered by backend services
        from routers.websocket_live_insights import broadcast_question_detected

        question_data = {
            "id": str(uuid.uuid4()),
            "text": "What's the budget?",
            "speaker": "John",
            "timestamp": datetime.utcnow().isoformat(),
            "category": "factual",
            "confidence": 0.95
        }

        # Broadcast to session
        await broadcast_question_detected(session_id, question_data)

        # Both clients should receive the broadcast
        msg1 = await wait_for_websocket_message(ws_client1, "QUESTION_DETECTED", timeout=3.0)
        msg2 = await wait_for_websocket_message(ws_client2, "QUESTION_DETECTED", timeout=3.0)

        assert msg1 is not None
        assert msg1["type"] == "QUESTION_DETECTED"
        assert msg1["data"]["text"] == "What's the budget?"

        assert msg2 is not None
        assert msg2["type"] == "QUESTION_DETECTED"
        assert msg2["data"]["text"] == "What's the budget?"

    finally:
        await ws_client1.disconnect()
        await ws_client2.disconnect()


# =============================================================================
# Connection Manager Tests
# =============================================================================

@pytest.mark.asyncio
async def test_connection_manager_tracks_sessions(ws_token: str):
    """Test that connection manager properly tracks session connections."""
    from routers.websocket_live_insights import insights_manager

    session_id = str(uuid.uuid4())
    ws_client = WebSocketTestClient()

    # Initially no connections
    assert insights_manager.get_connection_count(session_id) == 0
    assert not insights_manager.is_session_active(session_id)

    try:
        # Connect
        await ws_client.connect(
            f"/ws/live-insights/{session_id}",
            params={"token": ws_token}
        )

        # Wait for connection message
        await ws_client.receive_json(timeout=3.0)

        # Should have 1 connection
        assert insights_manager.get_connection_count(session_id) == 1
        assert insights_manager.is_session_active(session_id)

    finally:
        await ws_client.disconnect()

    # After disconnect, should be cleaned up
    # Note: cleanup happens asynchronously, so we might need a small delay
    import asyncio
    await asyncio.sleep(0.1)

    assert insights_manager.get_connection_count(session_id) == 0
    assert not insights_manager.is_session_active(session_id)
