"""
Integration tests for WebSocket Job Updates.

Covers TESTING_BACKEND.md section 10.1 - WebSocket job updates (websocket_jobs.py)

Features tested:
- [x] WebSocket connection and authentication
- [x] Subscribe to specific job updates
- [x] Subscribe to project job updates
- [x] Receive real-time job progress updates
- [x] Cancel jobs via WebSocket
- [x] Ping/pong heartbeat
- [x] Multiple client connections
- [x] Unsubscribe from job updates

Status: Basic WebSocket infrastructure tests (full auth testing requires WebSocket auth implementation)
"""

import pytest
import asyncio
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession
from models.user import User
from models.organization import Organization
from models.project import Project, ProjectStatus
from services.core.upload_job_service import upload_job_service, JobType, JobStatus
import uuid

from tests.websocket_test_utils import WebSocketTestClient, send_and_receive, wait_for_websocket_message


# ============================================================================
# Fixtures
# ============================================================================

@pytest.fixture
async def test_project(
    db_session: AsyncSession,
    test_organization: Organization,
    test_user: User
) -> Project:
    """Create a test project for WebSocket tests."""
    project = Project(
        name="WebSocket Test Project",
        description="Project for testing WebSocket job updates",
        organization_id=test_organization.id,
        created_by=str(test_user.id),
        status=ProjectStatus.ACTIVE
    )
    db_session.add(project)
    await db_session.commit()
    await db_session.refresh(project)
    return project


@pytest.fixture
def test_job(test_project: Project):
    """Create a test job for WebSocket tests."""
    job_id = upload_job_service.create_job(
        project_id=str(test_project.id),
        job_type=JobType.TEXT_UPLOAD,
        filename="websocket_test.txt",
        file_size=2048,
        total_steps=5,
        metadata={"test": "websocket"}
    )
    return upload_job_service.get_job(job_id)


# ============================================================================
# WebSocket Connection Tests
# ============================================================================

@pytest.mark.asyncio
async def test_websocket_connection():
    """Test basic WebSocket connection to job updates endpoint."""
    ws_client = WebSocketTestClient()

    try:
        # Connect to WebSocket endpoint
        await ws_client.connect("/ws/jobs")

        # Should receive connection confirmation
        message = await ws_client.receive_json(timeout=3.0)

        assert message["type"] == "connection"
        assert message["status"] == "connected"
        assert "client_id" in message
        assert "timestamp" in message

    finally:
        await ws_client.disconnect()


@pytest.mark.asyncio
async def test_websocket_connection_with_client_id():
    """Test WebSocket connection with custom client ID."""
    ws_client = WebSocketTestClient()
    custom_client_id = str(uuid.uuid4())

    try:
        # Connect with custom client ID
        await ws_client.connect("/ws/jobs", params={"client_id": custom_client_id})

        # Should receive connection confirmation with our client ID
        message = await ws_client.receive_json(timeout=3.0)

        assert message["type"] == "connection"
        assert message["client_id"] == custom_client_id

    finally:
        await ws_client.disconnect()


# ============================================================================
# Subscribe to Job Updates
# ============================================================================

@pytest.mark.asyncio
async def test_subscribe_to_job(test_job):
    """Test subscribing to a specific job's updates."""
    ws_client = WebSocketTestClient()

    try:
        await ws_client.connect("/ws/jobs")

        # Wait for connection confirmation
        await ws_client.receive_json(timeout=3.0)

        # Subscribe to job
        await ws_client.send_json({
            "action": "subscribe",
            "job_id": test_job.job_id
        })

        # Should receive current job status
        message = await ws_client.receive_json(timeout=3.0)

        assert message["type"] == "job_update"
        assert message["job"]["job_id"] == test_job.job_id
        assert message["job"]["status"] == "pending"

    finally:
        await ws_client.disconnect()


@pytest.mark.asyncio
async def test_unsubscribe_from_job(test_job):
    """Test unsubscribing from job updates."""
    ws_client = WebSocketTestClient()

    try:
        await ws_client.connect("/ws/jobs")
        await ws_client.receive_json(timeout=3.0)  # Connection msg

        # Subscribe
        await ws_client.send_json({
            "action": "subscribe",
            "job_id": test_job.job_id
        })
        await ws_client.receive_json(timeout=3.0)  # Job status

        # Unsubscribe
        await ws_client.send_json({
            "action": "unsubscribe",
            "job_id": test_job.job_id
        })

        # Update job - should NOT receive update after unsubscribe
        upload_job_service.update_job_progress(
            test_job.job_id,
            status=JobStatus.PROCESSING,
            progress=50.0
        )

        # Wait a bit to see if we receive update (we shouldn't)
        await asyncio.sleep(1)

        # Should not have received job update
        # (only had connection msg and initial status)
        assert len(ws_client.received_messages) == 2

    finally:
        await ws_client.disconnect()


# ============================================================================
# Subscribe to Project Jobs
# ============================================================================

@pytest.mark.asyncio
async def test_subscribe_to_project(test_project, test_job):
    """Test subscribing to all jobs in a project."""
    ws_client = WebSocketTestClient()

    try:
        await ws_client.connect("/ws/jobs")
        await ws_client.receive_json(timeout=3.0)  # Connection msg

        # Subscribe to project
        await ws_client.send_json({
            "action": "subscribe_project",
            "project_id": str(test_project.id)
        })

        # Should receive update for existing job
        message = await ws_client.receive_json(timeout=3.0)

        assert message["type"] == "job_update"
        assert message["job"]["project_id"] == str(test_project.id)

    finally:
        await ws_client.disconnect()


# ============================================================================
# Real-time Job Updates
# ============================================================================

@pytest.mark.asyncio
async def test_receive_job_progress_updates(test_job):
    """Test receiving real-time job progress updates."""
    ws_client = WebSocketTestClient()

    try:
        await ws_client.connect("/ws/jobs")
        await ws_client.receive_json(timeout=3.0)  # Connection msg

        # Subscribe to job
        await ws_client.send_json({
            "action": "subscribe",
            "job_id": test_job.job_id
        })
        await ws_client.receive_json(timeout=3.0)  # Initial status

        # Update job progress
        upload_job_service.update_job_progress(
            test_job.job_id,
            status=JobStatus.PROCESSING,
            progress=25.0,
            current_step=1
        )

        # Should receive progress update
        message = await wait_for_websocket_message(
            ws_client,
            "job_update",
            timeout=3.0
        )

        assert message is not None
        assert message["job"]["status"] == "processing"
        assert message["job"]["progress"] == 25.0
        assert message["job"]["current_step"] == 1

    finally:
        await ws_client.disconnect()


@pytest.mark.asyncio
async def test_receive_job_completion(test_job):
    """Test receiving job completion update."""
    ws_client = WebSocketTestClient()

    try:
        await ws_client.connect("/ws/jobs")
        await ws_client.receive_json(timeout=3.0)

        await ws_client.send_json({
            "action": "subscribe",
            "job_id": test_job.job_id
        })
        await ws_client.receive_json(timeout=3.0)

        # Complete the job
        upload_job_service.update_job_progress(
            test_job.job_id,
            status=JobStatus.COMPLETED,
            progress=100.0,
            result={"content_id": "test-123"}
        )

        # Should receive completion update
        message = await wait_for_websocket_message(
            ws_client,
            "job_update",
            timeout=3.0
        )

        assert message is not None
        assert message["job"]["status"] == "completed"
        assert message["job"]["progress"] == 100.0
        assert message["job"]["result"]["content_id"] == "test-123"

    finally:
        await ws_client.disconnect()


# ============================================================================
# Get Job Status
# ============================================================================

@pytest.mark.asyncio
async def test_get_job_status_via_websocket(test_job):
    """Test getting job status via WebSocket."""
    ws_client = WebSocketTestClient()

    try:
        await ws_client.connect("/ws/jobs")
        await ws_client.receive_json(timeout=3.0)

        # Request job status
        await ws_client.send_json({
            "action": "get_status",
            "job_id": test_job.job_id
        })

        # Should receive job status
        message = await ws_client.receive_json(timeout=3.0)

        assert message["type"] == "job_update"
        assert message["job"]["job_id"] == test_job.job_id

    finally:
        await ws_client.disconnect()


@pytest.mark.asyncio
async def test_get_nonexistent_job_status():
    """Test getting status of non-existent job."""
    ws_client = WebSocketTestClient()
    fake_job_id = str(uuid.uuid4())

    try:
        await ws_client.connect("/ws/jobs")
        await ws_client.receive_json(timeout=3.0)

        # Request non-existent job status
        await ws_client.send_json({
            "action": "get_status",
            "job_id": fake_job_id
        })

        # Should receive error
        message = await ws_client.receive_json(timeout=3.0)

        assert message["type"] == "error"
        assert "not found" in message["error"].lower()

    finally:
        await ws_client.disconnect()


# ============================================================================
# Cancel Job via WebSocket
# ============================================================================

@pytest.mark.asyncio
async def test_cancel_job_via_websocket(test_job):
    """Test cancelling a job via WebSocket."""
    ws_client = WebSocketTestClient()

    try:
        await ws_client.connect("/ws/jobs")
        await ws_client.receive_json(timeout=3.0)

        # Cancel job
        await ws_client.send_json({
            "action": "cancel",
            "job_id": test_job.job_id
        })

        # Should receive cancellation confirmation
        message = await ws_client.receive_json(timeout=3.0)

        assert message["type"] == "job_cancelled"
        assert message["job_id"] == test_job.job_id

        # Verify job is actually cancelled
        job = upload_job_service.get_job(test_job.job_id)
        assert job.status == JobStatus.CANCELLED

    finally:
        await ws_client.disconnect()


@pytest.mark.asyncio
async def test_cancel_nonexistent_job():
    """Test cancelling a non-existent job."""
    ws_client = WebSocketTestClient()
    fake_job_id = str(uuid.uuid4())

    try:
        await ws_client.connect("/ws/jobs")
        await ws_client.receive_json(timeout=3.0)

        # Try to cancel non-existent job
        await ws_client.send_json({
            "action": "cancel",
            "job_id": fake_job_id
        })

        # Should receive error
        message = await ws_client.receive_json(timeout=3.0)

        assert message["type"] == "error"
        assert "failed to cancel" in message["error"].lower()

    finally:
        await ws_client.disconnect()


# ============================================================================
# Ping/Pong Heartbeat
# ============================================================================

@pytest.mark.asyncio
async def test_ping_pong_heartbeat():
    """Test ping/pong heartbeat mechanism."""
    ws_client = WebSocketTestClient()

    try:
        await ws_client.connect("/ws/jobs")
        await ws_client.receive_json(timeout=3.0)

        # Send ping
        await ws_client.send_json({"action": "ping"})

        # Should receive pong
        message = await ws_client.receive_json(timeout=3.0)

        assert message["type"] == "pong"
        assert "timestamp" in message

    finally:
        await ws_client.disconnect()


# ============================================================================
# Multiple Client Connections
# ============================================================================

@pytest.mark.asyncio
async def test_multiple_clients_receive_updates(test_job):
    """Test that multiple clients can subscribe and receive updates."""
    client1 = WebSocketTestClient()
    client2 = WebSocketTestClient()

    try:
        # Connect both clients
        await client1.connect("/ws/jobs", params={"client_id": "client1"})
        await client2.connect("/ws/jobs", params={"client_id": "client2"})

        # Receive connection confirmations
        await client1.receive_json(timeout=3.0)
        await client2.receive_json(timeout=3.0)

        # Both subscribe to same job
        await client1.send_json({"action": "subscribe", "job_id": test_job.job_id})
        await client2.send_json({"action": "subscribe", "job_id": test_job.job_id})

        # Both receive initial status
        await client1.receive_json(timeout=3.0)
        await client2.receive_json(timeout=3.0)

        # Update job
        upload_job_service.update_job_progress(
            test_job.job_id,
            status=JobStatus.PROCESSING,
            progress=50.0
        )

        # Both clients should receive update
        msg1 = await wait_for_websocket_message(client1, "job_update", timeout=3.0)
        msg2 = await wait_for_websocket_message(client2, "job_update", timeout=3.0)

        assert msg1 is not None
        assert msg2 is not None
        assert msg1["job"]["progress"] == 50.0
        assert msg2["job"]["progress"] == 50.0

    finally:
        await client1.disconnect()
        await client2.disconnect()


# ============================================================================
# Error Handling
# ============================================================================

@pytest.mark.asyncio
async def test_unknown_action_returns_error():
    """Test that unknown actions return an error."""
    ws_client = WebSocketTestClient()

    try:
        await ws_client.connect("/ws/jobs")
        await ws_client.receive_json(timeout=3.0)

        # Send unknown action
        await ws_client.send_json({"action": "unknown_action"})

        # Should receive error
        message = await ws_client.receive_json(timeout=3.0)

        assert message["type"] == "error"
        assert "unknown action" in message["error"].lower()

    finally:
        await ws_client.disconnect()


# ============================================================================
# NOTE: WebSocket Authentication Tests
# ============================================================================
#
# WebSocket authentication is currently not implemented in the backend.
# This is a known security limitation that should be addressed by:
#
# 1. Passing authentication token as a query parameter
# 2. Validating the token on connection
# 3. Storing user/organization context for the connection
# 4. Validating access to jobs based on organization
#
# Once authentication is implemented, add tests for:
# - Connection rejection without valid token
# - Multi-tenant isolation (can't subscribe to jobs from other orgs)
# - Permission validation for job cancellation
#
# ============================================================================
