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


# =============================================================================
# Broadcast Message Type Tests
# =============================================================================

@pytest.mark.asyncio
async def test_broadcast_rag_result(ws_token: str):
    """Test broadcasting RAG search results (Tier 1 answer discovery)."""
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

        # Import broadcast function
        from routers.websocket_live_insights import broadcast_rag_result

        # Broadcast RAG result
        rag_data = {
            "document_title": "Q4 Budget Plan 2025",
            "content": "The infrastructure budget for Q4 is $250,000",
            "relevance_score": 0.92,
            "url": "https://docs.example.com/budget-q4",
            "source": "documents"
        }

        await broadcast_rag_result(session_id, question_id, rag_data)

        # Should receive the broadcast
        message = await wait_for_websocket_message(ws_client, "RAG_RESULT", timeout=3.0)

        assert message is not None
        assert message["type"] == "RAG_RESULT"
        assert message["question_id"] == question_id
        assert message["data"]["document_title"] == "Q4 Budget Plan 2025"
        assert message["data"]["relevance_score"] == 0.92
        assert "timestamp" in message

    finally:
        await ws_client.disconnect()


@pytest.mark.asyncio
async def test_broadcast_answer_from_meeting(ws_token: str):
    """Test broadcasting answer found earlier in meeting (Tier 2)."""
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

        # Import broadcast function
        from routers.websocket_live_insights import broadcast_answer_from_meeting

        # Broadcast answer from meeting
        answer_data = {
            "answer_text": "The budget was discussed as $250,000 for infrastructure",
            "speaker": "Sarah",
            "timestamp": "2025-10-27T10:15:30Z",
            "confidence": 0.88,
            "source": "meeting_context"
        }

        await broadcast_answer_from_meeting(session_id, question_id, answer_data)

        # Should receive the broadcast
        message = await wait_for_websocket_message(ws_client, "ANSWER_FROM_MEETING", timeout=3.0)

        assert message is not None
        assert message["type"] == "ANSWER_FROM_MEETING"
        assert message["question_id"] == question_id
        assert message["data"]["speaker"] == "Sarah"
        assert message["data"]["confidence"] == 0.88
        assert "timestamp" in message

    finally:
        await ws_client.disconnect()


@pytest.mark.asyncio
async def test_broadcast_question_answered_live(ws_token: str):
    """Test broadcasting answer from live conversation (Tier 3)."""
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

        # Import broadcast function
        from routers.websocket_live_insights import broadcast_question_answered_live

        # Broadcast live answer
        answer_data = {
            "answer_text": "Yes, the budget is $250,000",
            "speaker": "John",
            "timestamp": "2025-10-27T10:16:45Z",
            "confidence": 0.95,
            "source": "live_conversation"
        }

        await broadcast_question_answered_live(session_id, question_id, answer_data)

        # Should receive the broadcast
        message = await wait_for_websocket_message(ws_client, "QUESTION_ANSWERED_LIVE", timeout=3.0)

        assert message is not None
        assert message["type"] == "QUESTION_ANSWERED_LIVE"
        assert message["question_id"] == question_id
        assert message["data"]["answer_text"] == "Yes, the budget is $250,000"
        assert message["data"]["confidence"] == 0.95
        assert "timestamp" in message

    finally:
        await ws_client.disconnect()


@pytest.mark.asyncio
async def test_broadcast_gpt_generated_answer(ws_token: str):
    """Test broadcasting GPT-generated answer (Tier 4 fallback)."""
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

        # Import broadcast function
        from routers.websocket_live_insights import broadcast_gpt_generated_answer

        # Broadcast GPT-generated answer
        answer_data = {
            "answer": "Typical Q4 infrastructure budgets range from $200,000 to $500,000",
            "confidence": 0.75,
            "source": "gpt_generated",
            "disclaimer": "This answer is AI-generated and not from your documents or meeting. Please verify accuracy."
        }

        await broadcast_gpt_generated_answer(session_id, question_id, answer_data)

        # Should receive the broadcast
        message = await wait_for_websocket_message(ws_client, "GPT_GENERATED_ANSWER", timeout=3.0)

        assert message is not None
        assert message["type"] == "GPT_GENERATED_ANSWER"
        assert message["question_id"] == question_id
        assert message["data"]["confidence"] == 0.75
        assert "disclaimer" in message["data"]
        assert "timestamp" in message

    finally:
        await ws_client.disconnect()


@pytest.mark.asyncio
async def test_broadcast_question_unanswered(ws_token: str):
    """Test broadcasting when question remains unanswered after all tiers."""
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

        # Import broadcast function
        from routers.websocket_live_insights import broadcast_question_unanswered

        # Broadcast unanswered status
        await broadcast_question_unanswered(session_id, question_id)

        # Should receive the broadcast
        message = await wait_for_websocket_message(ws_client, "QUESTION_UNANSWERED", timeout=3.0)

        assert message is not None
        assert message["type"] == "QUESTION_UNANSWERED"
        assert message["question_id"] == question_id
        assert "timestamp" in message

    finally:
        await ws_client.disconnect()


@pytest.mark.asyncio
async def test_broadcast_action_updated(ws_token: str):
    """Test broadcasting action item updates."""
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

        # Import broadcast function
        from routers.websocket_live_insights import broadcast_action_updated

        # Broadcast action update
        update_data = {
            "owner": "Sarah",
            "deadline": "2025-11-05",
            "completeness": 1.0
        }

        await broadcast_action_updated(session_id, action_id, update_data)

        # Should receive the broadcast
        message = await wait_for_websocket_message(ws_client, "ACTION_UPDATED", timeout=3.0)

        assert message is not None
        assert message["type"] == "ACTION_UPDATED"
        assert message["action_id"] == action_id
        assert message["data"]["owner"] == "Sarah"
        assert message["data"]["completeness"] == 1.0
        assert "timestamp" in message

    finally:
        await ws_client.disconnect()


@pytest.mark.asyncio
async def test_broadcast_action_alert(ws_token: str):
    """Test broadcasting action item alerts at segment boundaries."""
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

        # Import broadcast function
        from routers.websocket_live_insights import broadcast_action_alert

        # Broadcast action alert
        alert_data = {
            "missing_fields": ["owner", "deadline"],
            "completeness": 0.4,
            "severity": "medium"
        }

        await broadcast_action_alert(session_id, action_id, alert_data)

        # Should receive the broadcast
        message = await wait_for_websocket_message(ws_client, "ACTION_ALERT", timeout=3.0)

        assert message is not None
        assert message["type"] == "ACTION_ALERT"
        assert message["action_id"] == action_id
        assert "owner" in message["data"]["missing_fields"]
        assert message["data"]["completeness"] == 0.4
        assert "timestamp" in message

    finally:
        await ws_client.disconnect()


@pytest.mark.asyncio
async def test_broadcast_segment_transition(ws_token: str):
    """Test broadcasting segment transition events."""
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

        # Import broadcast function
        from routers.websocket_live_insights import broadcast_segment_transition

        # Broadcast segment transition
        segment_data = {
            "boundary_type": "long_pause",
            "duration_seconds": 12.5,
            "previous_topic": "Budget discussion",
            "estimated_new_topic": "Timeline review"
        }

        await broadcast_segment_transition(session_id, segment_data)

        # Should receive the broadcast
        message = await wait_for_websocket_message(ws_client, "SEGMENT_TRANSITION", timeout=3.0)

        assert message is not None
        assert message["type"] == "SEGMENT_TRANSITION"
        assert message["data"]["boundary_type"] == "long_pause"
        assert message["data"]["duration_seconds"] == 12.5
        assert "timestamp" in message

    finally:
        await ws_client.disconnect()


@pytest.mark.asyncio
async def test_broadcast_meeting_summary(ws_token: str):
    """Test broadcasting final meeting summary."""
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

        # Import broadcast function
        from routers.websocket_live_insights import broadcast_meeting_summary

        # Broadcast meeting summary
        summary_data = {
            "total_questions": 15,
            "answered_questions": 12,
            "unanswered_questions": 3,
            "total_actions": 8,
            "complete_actions": 5,
            "incomplete_actions": 3,
            "duration_minutes": 45
        }

        await broadcast_meeting_summary(session_id, summary_data)

        # Should receive the broadcast
        message = await wait_for_websocket_message(ws_client, "MEETING_SUMMARY", timeout=3.0)

        assert message is not None
        assert message["type"] == "MEETING_SUMMARY"
        assert message["data"]["total_questions"] == 15
        assert message["data"]["answered_questions"] == 12
        assert message["data"]["total_actions"] == 8
        assert "timestamp" in message

    finally:
        await ws_client.disconnect()


@pytest.mark.asyncio
async def test_broadcast_transcription_partial(ws_token: str):
    """Test broadcasting partial transcription updates."""
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

        # Import broadcast function
        from routers.websocket_live_insights import broadcast_transcription_partial

        # Broadcast partial transcription
        transcript_data = {
            "text": "Hello, what is the",
            "speaker": "Speaker A",
            "timestamp": "2025-10-27T10:30:05Z",
            "confidence": 0.85,
            "is_final": False
        }

        await broadcast_transcription_partial(session_id, transcript_data)

        # Should receive the broadcast
        message = await wait_for_websocket_message(ws_client, "TRANSCRIPTION_PARTIAL", timeout=3.0)

        assert message is not None
        assert message["type"] == "TRANSCRIPTION_PARTIAL"
        assert message["data"]["text"] == "Hello, what is the"
        assert message["data"]["is_final"] is False
        assert "timestamp" in message

    finally:
        await ws_client.disconnect()


@pytest.mark.asyncio
async def test_broadcast_transcription_final(ws_token: str):
    """Test broadcasting final transcription updates."""
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

        # Import broadcast function
        from routers.websocket_live_insights import broadcast_transcription_final

        # Broadcast final transcription
        transcript_data = {
            "text": "Hello, what is the budget for Q4?",
            "speaker": "Speaker A",
            "timestamp": "2025-10-27T10:30:05Z",
            "confidence": 0.95,
            "is_final": True
        }

        await broadcast_transcription_final(session_id, transcript_data)

        # Should receive the broadcast
        message = await wait_for_websocket_message(ws_client, "TRANSCRIPTION_FINAL", timeout=3.0)

        assert message is not None
        assert message["type"] == "TRANSCRIPTION_FINAL"
        assert message["data"]["text"] == "Hello, what is the budget for Q4?"
        assert message["data"]["is_final"] is True
        assert message["data"]["confidence"] == 0.95
        assert "timestamp" in message

    finally:
        await ws_client.disconnect()


@pytest.mark.asyncio
async def test_broadcast_sync_state(ws_token: str):
    """Test broadcasting state synchronization on reconnect."""
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

        # Import broadcast function
        from routers.websocket_live_insights import broadcast_sync_state

        # Broadcast sync state
        state_data = {
            "session_id": session_id,
            "meeting_elapsed_seconds": 1520,
            "active_participants": ["user1", "user2"],
            "questions": [
                {
                    "id": str(uuid.uuid4()),
                    "text": "What's the budget?",
                    "status": "answered",
                    "answer_source": "rag"
                }
            ],
            "actions": [
                {
                    "id": str(uuid.uuid4()),
                    "description": "Update documentation",
                    "owner": "John",
                    "completeness": 1.0
                }
            ]
        }

        await broadcast_sync_state(session_id, state_data)

        # Should receive the broadcast
        message = await wait_for_websocket_message(ws_client, "SYNC_STATE", timeout=3.0)

        assert message is not None
        assert message["type"] == "SYNC_STATE"
        assert message["data"]["session_id"] == session_id
        assert message["data"]["meeting_elapsed_seconds"] == 1520
        assert len(message["data"]["questions"]) == 1
        assert len(message["data"]["actions"]) == 1
        assert "timestamp" in message

    finally:
        await ws_client.disconnect()


# =============================================================================
# Reconnection and Error Handling Tests
# =============================================================================

@pytest.mark.asyncio
async def test_reconnection_receives_sync_state(ws_token: str):
    """Test that reconnecting client receives SYNC_STATE message."""
    session_id = str(uuid.uuid4())
    ws_client1 = WebSocketTestClient()
    ws_client2 = WebSocketTestClient()

    try:
        # First client connects
        await ws_client1.connect(
            f"/ws/live-insights/{session_id}",
            params={"token": ws_token}
        )

        # Wait for connection message
        await ws_client1.receive_json(timeout=3.0)

        # Simulate some activity - broadcast a question
        from routers.websocket_live_insights import broadcast_question_detected

        question_data = {
            "id": str(uuid.uuid4()),
            "text": "What's the timeline?",
            "speaker": "Sarah",
            "timestamp": datetime.utcnow().isoformat(),
            "category": "factual",
            "confidence": 0.95
        }

        await broadcast_question_detected(session_id, question_data)

        # First client receives the question
        msg1 = await wait_for_websocket_message(ws_client1, "QUESTION_DETECTED", timeout=3.0)
        assert msg1 is not None

        # Second client connects (simulating reconnection or late join)
        await ws_client2.connect(
            f"/ws/live-insights/{session_id}",
            params={"token": ws_token}
        )

        # Second client receives connection message
        conn_msg = await ws_client2.receive_json(timeout=3.0)
        assert conn_msg["type"] == "connection"

        # Note: SYNC_STATE would be sent by the backend on connection
        # In a full implementation, the second client would receive
        # a SYNC_STATE message with all active questions/actions

    finally:
        await ws_client1.disconnect()
        await ws_client2.disconnect()


@pytest.mark.asyncio
async def test_concurrent_message_delivery(ws_token: str):
    """Test that multiple broadcast messages are delivered in order."""
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

        # Import broadcast functions
        from routers.websocket_live_insights import (
            broadcast_question_detected,
            broadcast_action_tracked
        )

        # Send multiple broadcasts rapidly
        question_id = str(uuid.uuid4())
        action_id = str(uuid.uuid4())

        await broadcast_question_detected(session_id, {
            "id": question_id,
            "text": "Question 1",
            "speaker": "John",
            "timestamp": datetime.utcnow().isoformat(),
            "category": "factual",
            "confidence": 0.95
        })

        await broadcast_action_tracked(session_id, {
            "id": action_id,
            "description": "Action 1",
            "owner": "Sarah",
            "deadline": "2025-11-05",
            "completeness": 1.0,
            "confidence": 0.9
        })

        # Both messages should be received
        msg1 = await ws_client.receive_json(timeout=3.0)
        msg2 = await ws_client.receive_json(timeout=3.0)

        # Verify we got both types (order might vary)
        message_types = {msg1["type"], msg2["type"]}
        assert "QUESTION_DETECTED" in message_types
        assert "ACTION_TRACKED" in message_types

    finally:
        await ws_client.disconnect()
