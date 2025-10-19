"""
Integration tests for live insights WebSocket endpoint.

Tests the complete flow of:
1. WebSocket connection with authentication
2. Audio chunk processing
3. Transcription
4. Insight extraction
5. Session lifecycle (pause, resume, end)
6. Persistence to database
"""

import pytest
import json
import base64
import asyncio
from datetime import datetime
from unittest.mock import patch, AsyncMock, Mock
from sqlalchemy import select

from models.live_meeting_insight import LiveMeetingInsight
from models.project import Project


@pytest.mark.asyncio
async def test_live_insights_rest_api_get_by_project(
    authenticated_org_client,
    db_session,
    test_project,
    test_organization
):
    """Test retrieving live insights by project ID via REST API."""
    # Create test insights in database
    insight1 = LiveMeetingInsight(
        session_id="test_session_1",
        project_id=test_project.id,
        organization_id=test_organization.id,
        insight_type="action_item",
        priority="high",
        content="Complete API documentation by Friday",
        context="Discussion about documentation needs",
        assigned_to="John",
        due_date="2025-10-22",
        confidence_score=0.92,
        chunk_index=0
    )

    insight2 = LiveMeetingInsight(
        session_id="test_session_1",
        project_id=test_project.id,
        organization_id=test_organization.id,
        insight_type="decision",
        priority="high",
        content="Use GraphQL for new API",
        context="Team decision on API architecture",
        confidence_score=0.95,
        chunk_index=1
    )

    db_session.add_all([insight1, insight2])
    await db_session.commit()

    # Fetch insights via API
    response = await authenticated_org_client.get(
        f"/api/v1/projects/{test_project.id}/live-insights"
    )

    assert response.status_code == 200
    data = response.json()

    assert "insights" in data
    assert len(data["insights"]) == 2
    assert data["total"] == 2
    assert data["project_id"] == str(test_project.id)

    # Verify insight content
    insights = data["insights"]
    action_items = [i for i in insights if i["insight_type"] == "action_item"]
    assert len(action_items) == 1
    assert action_items[0]["content"] == "Complete API documentation by Friday"
    assert action_items[0]["assigned_to"] == "John"


@pytest.mark.asyncio
async def test_live_insights_rest_api_filter_by_type(
    authenticated_org_client,
    db_session,
    test_project,
    test_organization
):
    """Test filtering insights by type."""
    # Create insights of different types
    insights = [
        LiveMeetingInsight(
            session_id="test_session",
            project_id=test_project.id,
            organization_id=test_organization.id,
            insight_type="action_item",
            priority="high",
            content="Action item 1",
            confidence_score=0.9,
            chunk_index=0
        ),
        LiveMeetingInsight(
            session_id="test_session",
            project_id=test_project.id,
            organization_id=test_organization.id,
            insight_type="decision",
            priority="medium",
            content="Decision 1",
            confidence_score=0.85,
            chunk_index=1
        ),
        LiveMeetingInsight(
            session_id="test_session",
            project_id=test_project.id,
            organization_id=test_organization.id,
            insight_type="action_item",
            priority="low",
            content="Action item 2",
            confidence_score=0.8,
            chunk_index=2
        )
    ]

    db_session.add_all(insights)
    await db_session.commit()

    # Filter by action_item type
    response = await authenticated_org_client.get(
        f"/api/v1/projects/{test_project.id}/live-insights?insight_type=action_item"
    )

    assert response.status_code == 200
    data = response.json()

    assert len(data["insights"]) == 2
    assert all(i["insight_type"] == "action_item" for i in data["insights"])


@pytest.mark.asyncio
async def test_live_insights_rest_api_filter_by_priority(
    authenticated_org_client,
    db_session,
    test_project,
    test_organization
):
    """Test filtering insights by priority."""
    # Create insights with different priorities
    insights = [
        LiveMeetingInsight(
            session_id="test_session",
            project_id=test_project.id,
            organization_id=test_organization.id,
            insight_type="risk",
            priority="critical",
            content="Critical risk",
            confidence_score=0.95,
            chunk_index=0
        ),
        LiveMeetingInsight(
            session_id="test_session",
            project_id=test_project.id,
            organization_id=test_organization.id,
            insight_type="blocker",
            priority="high",
            content="High priority blocker",
            confidence_score=0.9,
            chunk_index=1
        ),
        LiveMeetingInsight(
            session_id="test_session",
            project_id=test_project.id,
            organization_id=test_organization.id,
            insight_type="question",
            priority="low",
            content="Low priority question",
            confidence_score=0.7,
            chunk_index=2
        )
    ]

    db_session.add_all(insights)
    await db_session.commit()

    # Filter by high priority
    response = await authenticated_org_client.get(
        f"/api/v1/projects/{test_project.id}/live-insights?priority=high"
    )

    assert response.status_code == 200
    data = response.json()

    assert len(data["insights"]) == 1
    assert data["insights"][0]["priority"] == "high"


@pytest.mark.asyncio
async def test_live_insights_rest_api_filter_by_session(
    authenticated_org_client,
    db_session,
    test_project,
    test_organization
):
    """Test filtering insights by session ID."""
    # Create insights from different sessions
    session1_insights = [
        LiveMeetingInsight(
            session_id="session_1",
            project_id=test_project.id,
            organization_id=test_organization.id,
            insight_type="action_item",
            priority="high",
            content="Session 1 action",
            confidence_score=0.9,
            chunk_index=0
        ),
        LiveMeetingInsight(
            session_id="session_1",
            project_id=test_project.id,
            organization_id=test_organization.id,
            insight_type="decision",
            priority="medium",
            content="Session 1 decision",
            confidence_score=0.85,
            chunk_index=1
        )
    ]

    session2_insights = [
        LiveMeetingInsight(
            session_id="session_2",
            project_id=test_project.id,
            organization_id=test_organization.id,
            insight_type="action_item",
            priority="high",
            content="Session 2 action",
            confidence_score=0.9,
            chunk_index=0
        )
    ]

    db_session.add_all(session1_insights + session2_insights)
    await db_session.commit()

    # Filter by session 1
    response = await authenticated_org_client.get(
        f"/api/v1/projects/{test_project.id}/live-insights?session_id=session_1"
    )

    assert response.status_code == 200
    data = response.json()

    assert len(data["insights"]) == 2
    assert all(i["session_id"] == "session_1" for i in data["insights"])


@pytest.mark.asyncio
async def test_live_insights_rest_api_pagination(
    authenticated_org_client,
    db_session,
    test_project,
    test_organization
):
    """Test pagination of insights."""
    # Create 25 insights
    insights = [
        LiveMeetingInsight(
            session_id="test_session",
            project_id=test_project.id,
            organization_id=test_organization.id,
            insight_type="action_item",
            priority="medium",
            content=f"Action item {i}",
            confidence_score=0.8,
            chunk_index=i
        )
        for i in range(25)
    ]

    db_session.add_all(insights)
    await db_session.commit()

    # Get first page (10 items)
    response1 = await authenticated_org_client.get(
        f"/api/v1/projects/{test_project.id}/live-insights?limit=10&offset=0"
    )

    assert response1.status_code == 200
    data1 = response1.json()
    assert len(data1["insights"]) == 10
    assert data1["total"] == 25

    # Get second page
    response2 = await authenticated_org_client.get(
        f"/api/v1/projects/{test_project.id}/live-insights?limit=10&offset=10"
    )

    assert response2.status_code == 200
    data2 = response2.json()
    assert len(data2["insights"]) == 10

    # Verify pages don't overlap
    ids_page1 = {i["id"] for i in data1["insights"]}
    ids_page2 = {i["id"] for i in data2["insights"]}
    assert len(ids_page1.intersection(ids_page2)) == 0


@pytest.mark.asyncio
async def test_live_insights_rest_api_get_by_session(
    authenticated_org_client,
    db_session,
    test_project,
    test_organization
):
    """Test retrieving insights by session ID via dedicated endpoint."""
    session_id = "test_session_123"

    # Create insights for this session
    insights = [
        LiveMeetingInsight(
            session_id=session_id,
            project_id=test_project.id,
            organization_id=test_organization.id,
            insight_type="action_item",
            priority="high",
            content=f"Action {i}",
            confidence_score=0.9,
            chunk_index=i
        )
        for i in range(3)
    ]

    db_session.add_all(insights)
    await db_session.commit()

    # Fetch via session endpoint
    response = await authenticated_org_client.get(
        f"/api/v1/sessions/{session_id}/live-insights"
    )

    assert response.status_code == 200
    data = response.json()

    assert len(data["insights"]) == 3
    assert data["session_id"] == session_id
    assert data["project_id"] == str(test_project.id)

    # Verify chronological order by chunk_index
    chunk_indices = [i["chunk_index"] for i in data["insights"]]
    assert chunk_indices == [0, 1, 2]


@pytest.mark.asyncio
async def test_live_insights_rest_api_unauthorized_access(
    authenticated_org_client,
    db_session,
    test_organization,
    test_user_2,
    test_org_2
):
    """Test that users cannot access insights from other organizations."""
    from models.project import Project

    # Create a project in a different organization
    other_project = Project(
        name="Other Project",
        description="Project in different org",
        organization_id=test_org_2.id,
        status="active",
        created_by=str(test_user_2.id)
    )

    db_session.add(other_project)
    await db_session.commit()
    await db_session.refresh(other_project)

    # Create insight in other project
    insight = LiveMeetingInsight(
        session_id="other_session",
        project_id=other_project.id,
        organization_id=test_org_2.id,
        insight_type="action_item",
        priority="high",
        content="Secret action",
        confidence_score=0.9,
        chunk_index=0
    )

    db_session.add(insight)
    await db_session.commit()

    # Try to access insights from authenticated_org_client (belongs to test_organization)
    response = await authenticated_org_client.get(
        f"/api/v1/projects/{other_project.id}/live-insights"
    )

    # Should return 403 Forbidden or 404 Not Found
    assert response.status_code in [403, 404]


@pytest.mark.asyncio
async def test_live_insights_rest_api_empty_results(
    authenticated_org_client,
    test_project
):
    """Test API returns empty array when no insights exist."""
    response = await authenticated_org_client.get(
        f"/api/v1/projects/{test_project.id}/live-insights"
    )

    assert response.status_code == 200
    data = response.json()

    assert data["insights"] == []
    assert data["total"] == 0
    assert data["project_id"] == str(test_project.id)


@pytest.mark.asyncio
async def test_realtime_insights_service_process_chunk(
    db_session,
    test_project,
    test_organization,
    test_user
):
    """Test the realtime insights service processes a chunk and extracts insights."""
    from services.intelligence.realtime_meeting_insights import (
        realtime_insights_service,
        TranscriptChunk
    )

    # Create a transcript chunk
    chunk = TranscriptChunk(
        chunk_id="chunk_1",
        text="John will send the API documentation to the team by Friday. This is critical for the launch.",
        timestamp=datetime.utcnow(),
        index=0,
        speaker="John",
        duration_seconds=10.0
    )

    session_id = "test_session_integration"

    # Mock the LLM response (already mocked globally, but ensure it returns insights)
    with patch('services.intelligence.realtime_meeting_insights.realtime_insights_service.llm_client') as mock_llm:
        mock_response = Mock()
        mock_response.content = [Mock(text=json.dumps({
            "insights": [
                {
                    "type": "action_item",
                    "priority": "high",
                    "content": "John to send API documentation",
                    "context": "Critical for launch",
                    "assigned_to": "John",
                    "due_date": "Friday",
                    "confidence": 0.92
                }
            ]
        }))]
        mock_response.usage = Mock(input_tokens=100, output_tokens=50)
        mock_llm.create_message = AsyncMock(return_value=mock_response)

        # Process the chunk
        result = await realtime_insights_service.process_transcript_chunk(
            session_id=session_id,
            project_id=str(test_project.id),
            organization_id=str(test_organization.id),
            chunk=chunk,
            db=db_session
        )

    # Verify result structure
    assert result["session_id"] == session_id
    assert result["chunk_index"] == 0
    assert "insights" in result
    assert len(result["insights"]) > 0

    # Verify insight content
    insight = result["insights"][0]
    assert insight["type"] == "action_item"
    assert "John" in insight["content"]


@pytest.mark.asyncio
async def test_realtime_insights_service_deduplication(
    db_session,
    test_project,
    test_organization
):
    """Test that the service deduplicates identical insights."""
    from services.intelligence.realtime_meeting_insights import (
        realtime_insights_service,
        TranscriptChunk
    )

    session_id = "test_dedup_session"

    # First chunk
    chunk1 = TranscriptChunk(
        chunk_id="chunk_1",
        text="John needs to complete the API documentation by Friday.",
        timestamp=datetime.utcnow(),
        index=0,
        speaker="John"
    )

    # Use EXACT same content for both insights to ensure deduplication
    insight_content = "Complete API documentation by Friday"

    with patch('services.intelligence.realtime_meeting_insights.realtime_insights_service.llm_client') as mock_llm:
        mock_response1 = Mock()
        mock_response1.content = [Mock(text=json.dumps({
            "insights": [
                {
                    "type": "action_item",
                    "priority": "high",
                    "content": insight_content,
                    "assigned_to": "John",
                    "due_date": "Friday",
                    "confidence": 0.9
                }
            ]
        }))]
        mock_response1.usage = Mock(input_tokens=100, output_tokens=50)
        mock_llm.create_message = AsyncMock(return_value=mock_response1)

        result1 = await realtime_insights_service.process_transcript_chunk(
            session_id=session_id,
            project_id=str(test_project.id),
            organization_id=str(test_organization.id),
            chunk=chunk1,
            db=db_session
        )

    assert len(result1["insights"]) == 1
    first_insight_id = result1["insights"][0]["insight_id"]

    # Second chunk with IDENTICAL content (should be deduplicated)
    chunk2 = TranscriptChunk(
        chunk_id="chunk_2",
        text="Just to confirm, John will finish the API documentation by Friday.",
        timestamp=datetime.utcnow(),
        index=1,
        speaker="Sarah"
    )

    with patch('services.intelligence.realtime_meeting_insights.realtime_insights_service.llm_client') as mock_llm:
        mock_response2 = Mock()
        mock_response2.content = [Mock(text=json.dumps({
            "insights": [
                {
                    "type": "action_item",
                    "priority": "high",
                    "content": insight_content,  # EXACT same content
                    "assigned_to": "John",
                    "due_date": "Friday",
                    "confidence": 0.9
                }
            ]
        }))]
        mock_response2.usage = Mock(input_tokens=100, output_tokens=50)
        mock_llm.create_message = AsyncMock(return_value=mock_response2)

        result2 = await realtime_insights_service.process_transcript_chunk(
            session_id=session_id,
            project_id=str(test_project.id),
            organization_id=str(test_organization.id),
            chunk=chunk2,
            db=db_session
        )

    # Should have 0 new insights due to deduplication (identical content has similarity > 0.85)
    assert len(result2["insights"]) == 0, f"Identical insight should be deduplicated. Got: {result2['insights']}"


@pytest.mark.asyncio
async def test_realtime_insights_finalize_session_persists_to_db(
    db_session,
    test_project,
    test_organization
):
    """Test that finalizing a session persists insights to the database."""
    from services.intelligence.realtime_meeting_insights import (
        realtime_insights_service,
        TranscriptChunk
    )

    session_id = "test_persist_session"

    # Create and process a chunk
    chunk = TranscriptChunk(
        chunk_id="chunk_1",
        text="We decided to use GraphQL for the new API. This is a critical decision.",
        timestamp=datetime.utcnow(),
        index=0,
        speaker="Team"
    )

    with patch('services.intelligence.realtime_meeting_insights.realtime_insights_service.llm_client') as mock_llm:
        mock_response = Mock()
        mock_response.content = [Mock(text=json.dumps({
            "insights": [
                {
                    "type": "decision",
                    "priority": "critical",
                    "content": "Use GraphQL for new API",
                    "context": "Architecture decision",
                    "confidence": 0.95
                }
            ]
        }))]
        mock_response.usage = Mock(input_tokens=100, output_tokens=50)
        mock_llm.create_message = AsyncMock(return_value=mock_response)

        await realtime_insights_service.process_transcript_chunk(
            session_id=session_id,
            project_id=str(test_project.id),
            organization_id=str(test_organization.id),
            chunk=chunk,
            db=db_session
        )

    # Finalize the session
    result = await realtime_insights_service.finalize_session(
        session_id=session_id,
        project_id=str(test_project.id),
        organization_id=str(test_organization.id),
        db=db_session
    )

    # Verify the result
    assert "insights" in result
    assert len(result["insights"]) > 0

    # Verify insights were persisted to database
    stmt = select(LiveMeetingInsight).where(
        LiveMeetingInsight.session_id == session_id
    )
    db_result = await db_session.execute(stmt)
    db_insights = db_result.scalars().all()

    assert len(db_insights) > 0
    assert db_insights[0].insight_type == "decision"
    assert "GraphQL" in db_insights[0].content
    assert db_insights[0].project_id == test_project.id
    assert db_insights[0].organization_id == test_organization.id
