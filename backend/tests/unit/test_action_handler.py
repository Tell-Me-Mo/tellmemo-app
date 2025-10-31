"""Unit tests for ActionHandler service."""

import pytest
import asyncio
import uuid
from datetime import datetime
from unittest.mock import AsyncMock, MagicMock, patch
from sqlalchemy.ext.asyncio import AsyncSession

from services.intelligence.action_handler import ActionHandler
from models.live_insight import (
    LiveMeetingInsight,
    InsightType,
    InsightStatus
)


@pytest.fixture
def action_handler():
    """Create an ActionHandler instance for testing."""
    return ActionHandler()


@pytest.fixture
def mock_session():
    """Create a mock async database session."""
    session = AsyncMock(spec=AsyncSession)
    session.flush = AsyncMock()
    session.commit = AsyncMock()
    session.rollback = AsyncMock()
    session.add = MagicMock()
    return session


@pytest.fixture
def sample_action_data():
    """Sample action data from GPT stream."""
    return {
        "id": "a_1a2b3c4d-5e6f-7a8b-9c0d-1e2f3a4b5c6d",
        "description": "Update the budget spreadsheet with Q4 numbers",
        "owner": "John",
        "deadline": "2025-10-30",
        "speaker": "Sarah",
        "timestamp": "2025-10-26T10:30:05Z",
        "completeness": 1.0,
        "confidence": 0.95
    }


@pytest.fixture
def sample_action_update():
    """Sample action_update data from GPT stream."""
    return {
        "id": "a_1a2b3c4d-5e6f-7a8b-9c0d-1e2f3a4b5c6d",
        "owner": "Mike",
        "deadline": "2025-11-05",
        "completeness": 1.0,
        "confidence": 0.88
    }


@pytest.mark.asyncio
class TestActionHandlerInitialization:
    """Test ActionHandler initialization."""

    def test_initialization(self, action_handler):
        """Test handler initializes with correct configuration."""
        assert action_handler.min_confidence_threshold == 0.6
        assert action_handler._active_actions == {}
        assert action_handler._ws_broadcast_callback is None
        assert action_handler.actions_routed == 0
        assert action_handler.action_updates_routed == 0

    def test_set_websocket_callback(self, action_handler):
        """Test setting WebSocket callback."""
        callback = AsyncMock()
        action_handler.set_websocket_callback(callback)
        assert action_handler._ws_broadcast_callback == callback


@pytest.mark.asyncio
class TestHandleAction:
    """Test action handling and creation."""

    async def test_handle_action_success(
        self,
        action_handler,
        mock_session,
        sample_action_data
    ):
        """Test successful action handling creates database record."""
        session_id = "test_session_123"
        project_id = str(uuid.uuid4())
        org_id = str(uuid.uuid4())
        recording_id = str(uuid.uuid4())

        # Mock WebSocket broadcast
        ws_callback = AsyncMock()
        action_handler.set_websocket_callback(ws_callback)

        # Mock find_similar_action to return None (no duplicates)
        with patch.object(action_handler, '_find_similar_action', return_value=None):
            result = await action_handler.handle_action(
                session_id=session_id,
                action_data=sample_action_data,
                session=mock_session,
                project_id=project_id,
                organization_id=org_id,
                recording_id=recording_id
            )

        # Verify database operations
        assert mock_session.add.called
        assert mock_session.flush.called
        assert mock_session.commit.called

        # Verify result
        assert result is not None
        assert result.insight_type == InsightType.ACTION
        assert result.content == sample_action_data["description"]
        assert result.speaker == sample_action_data["speaker"]
        assert result.status == InsightStatus.TRACKED.value

        # Verify metadata
        metadata = result.insight_metadata
        assert metadata["gpt_id"] == sample_action_data["id"]
        assert metadata["owner"] == sample_action_data["owner"]
        assert metadata["deadline"] == sample_action_data["deadline"]
        assert metadata["confidence"] == sample_action_data["confidence"]
        assert "completeness_score" in metadata

        # Verify WebSocket broadcast
        assert ws_callback.called
        call_args = ws_callback.call_args[0]
        assert call_args[0] == session_id
        assert call_args[1]["type"] == "ACTION_TRACKED"

        # Verify metrics
        assert action_handler.actions_routed == 1

    async def test_handle_action_low_confidence_filtered(
        self,
        action_handler,
        mock_session,
        sample_action_data
    ):
        """Test low-confidence actions are filtered out."""
        session_id = "test_session_123"
        project_id = str(uuid.uuid4())
        org_id = str(uuid.uuid4())
        recording_id = str(uuid.uuid4())

        # Set low confidence
        low_confidence_data = sample_action_data.copy()
        low_confidence_data["confidence"] = 0.3

        result = await action_handler.handle_action(
            session_id=session_id,
            action_data=low_confidence_data,
            session=mock_session,
            project_id=project_id,
            organization_id=org_id,
            recording_id=recording_id
        )

        # Should be filtered
        assert result is None
        assert not mock_session.add.called

    async def test_handle_action_merge_with_similar(
        self,
        action_handler,
        mock_session,
        sample_action_data
    ):
        """Test merging action with similar existing action."""
        session_id = "test_session_123"
        project_id = str(uuid.uuid4())
        org_id = str(uuid.uuid4())
        recording_id = str(uuid.uuid4())
        existing_action_id = str(uuid.uuid4())

        # Mock finding similar action
        with patch.object(action_handler, '_find_similar_action', return_value=existing_action_id):
            with patch.object(action_handler, '_update_existing_action', return_value=MagicMock()):
                result = await action_handler.handle_action(
                    session_id=session_id,
                    action_data=sample_action_data,
                    session=mock_session,
                    project_id=project_id,
                    organization_id=org_id,
                    recording_id=recording_id
                )

        # Should not create new action
        assert not mock_session.add.called

    async def test_handle_action_exception(
        self,
        action_handler,
        mock_session,
        sample_action_data
    ):
        """Test exception handling during action creation."""
        session_id = "test_session_123"
        project_id = str(uuid.uuid4())
        org_id = str(uuid.uuid4())
        recording_id = str(uuid.uuid4())

        # Mock session.add to raise exception
        mock_session.add.side_effect = Exception("Database error")

        with patch.object(action_handler, '_find_similar_action', return_value=None):
            result = await action_handler.handle_action(
                session_id=session_id,
                action_data=sample_action_data,
                session=mock_session,
                project_id=project_id,
                organization_id=org_id,
                recording_id=recording_id
            )

        # Should handle exception gracefully
        assert result is None
        assert mock_session.rollback.called


@pytest.mark.asyncio
class TestHandleActionUpdate:
    """Test action update handling."""

    async def test_handle_action_update_success(
        self,
        action_handler,
        mock_session,
        sample_action_update
    ):
        """Test successful action update."""
        session_id = "test_session_123"

        # Mock existing action
        existing_action = MagicMock(spec=LiveMeetingInsight)
        existing_action.id = uuid.uuid4()
        existing_action.content = "Update the budget spreadsheet"
        existing_action.insight_metadata = {
            "gpt_id": sample_action_update["id"],
            "owner": "John",
            "deadline": "2025-10-30",
            "completeness_score": 1.0,
            "confidence": 0.95
        }
        existing_action.update_status = MagicMock()
        existing_action.to_dict = MagicMock(return_value={"id": str(existing_action.id), "content": "Update the budget spreadsheet"})

        # Mock database query
        mock_result = MagicMock()
        mock_result.scalar_one_or_none.return_value = existing_action
        mock_session.execute = AsyncMock(return_value=mock_result)

        # Mock WebSocket broadcast
        ws_callback = AsyncMock()
        action_handler.set_websocket_callback(ws_callback)

        result = await action_handler.handle_action_update(
            session_id=session_id,
            update_data=sample_action_update,
            session=mock_session
        )

        # Verify result
        assert result is not None
        assert mock_session.commit.called

        # Verify metadata updated
        metadata = existing_action.insight_metadata
        assert metadata["owner"] == sample_action_update["owner"]
        assert metadata["deadline"] == sample_action_update["deadline"]
        assert "update_history" in metadata
        assert len(metadata["update_history"]) > 0

        # Verify WebSocket broadcast
        assert ws_callback.called
        call_args = ws_callback.call_args[0]
        assert call_args[1]["type"] == "ACTION_UPDATED"

        # Verify metrics
        assert action_handler.action_updates_routed == 1

    async def test_handle_action_update_not_found(
        self,
        action_handler,
        mock_session,
        sample_action_update
    ):
        """Test action update when action not found."""
        session_id = "test_session_123"

        # Mock database query returning None
        mock_result = MagicMock()
        mock_result.scalar_one_or_none.return_value = None
        mock_session.execute = AsyncMock(return_value=mock_result)

        result = await action_handler.handle_action_update(
            session_id=session_id,
            update_data=sample_action_update,
            session=mock_session
        )

        # Should return None
        assert result is None

    async def test_handle_action_update_missing_id(
        self,
        action_handler,
        mock_session
    ):
        """Test action update with missing ID field."""
        session_id = "test_session_123"
        invalid_update = {"owner": "Mike"}  # Missing 'id'

        result = await action_handler.handle_action_update(
            session_id=session_id,
            update_data=invalid_update,
            session=mock_session
        )

        # Should return None
        assert result is None


@pytest.mark.asyncio
class TestCompletenessScoring:
    """Test completeness calculation."""

    def test_completeness_all_fields(self, action_handler):
        """Test completeness with all fields present."""
        score = action_handler._calculate_completeness(
            description="Update the budget spreadsheet",
            owner="John",
            deadline="2025-10-30"
        )
        assert score == 1.0

    def test_completeness_description_only(self, action_handler):
        """Test completeness with description only."""
        score = action_handler._calculate_completeness(
            description="Update the budget spreadsheet",
            owner=None,
            deadline=None
        )
        assert score == 0.4

    def test_completeness_description_and_owner(self, action_handler):
        """Test completeness with description and owner."""
        score = action_handler._calculate_completeness(
            description="Update the budget spreadsheet",
            owner="John",
            deadline=None
        )
        assert score == 0.7

    def test_completeness_description_and_deadline(self, action_handler):
        """Test completeness with description and deadline."""
        score = action_handler._calculate_completeness(
            description="Update the budget spreadsheet",
            owner=None,
            deadline="2025-10-30"
        )
        assert score == 0.7

    def test_completeness_short_description(self, action_handler):
        """Test completeness with very short description."""
        score = action_handler._calculate_completeness(
            description="Update",  # Less than 10 characters
            owner="John",
            deadline="2025-10-30"
        )
        # Description doesn't count, only owner + deadline
        assert score == 0.6


@pytest.mark.asyncio
class TestSegmentAlerts:
    """Test segment alert generation."""

    async def test_generate_segment_alerts_with_incomplete_actions(
        self,
        action_handler,
        mock_session
    ):
        """Test generating alerts for incomplete actions."""
        session_id = "test_session_123"

        # Mock incomplete action
        action1 = MagicMock(spec=LiveMeetingInsight)
        action1.id = uuid.uuid4()
        action1.content = "Update documentation"
        action1.insight_metadata = {
            "completeness_score": 0.4,  # Description only
            "confidence": 0.9,
            "owner": None,
            "deadline": None
        }

        # Mock complete action (should not alert)
        action2 = MagicMock(spec=LiveMeetingInsight)
        action2.id = uuid.uuid4()
        action2.content = "Review pull request"
        action2.insight_metadata = {
            "completeness_score": 1.0,
            "confidence": 0.9,
            "owner": "Sarah",
            "deadline": "2025-10-28"
        }

        # Mock database query
        mock_result = MagicMock()
        mock_scalars = MagicMock()
        mock_scalars.all.return_value = [action1, action2]
        mock_result.scalars.return_value = mock_scalars
        mock_session.execute = AsyncMock(return_value=mock_result)

        # Mock WebSocket broadcast
        ws_callback = AsyncMock()
        action_handler.set_websocket_callback(ws_callback)

        alerts = await action_handler.generate_segment_alerts(
            session_id=session_id,
            session=mock_session
        )

        # Should generate 1 alert (for action1)
        assert len(alerts) == 1
        assert alerts[0]["action_id"] == str(action1.id)
        assert "owner" in alerts[0]["missing_fields"]
        assert "deadline" in alerts[0]["missing_fields"]

        # Verify WebSocket broadcast
        assert ws_callback.called

    async def test_generate_segment_alerts_low_confidence_ignored(
        self,
        action_handler,
        mock_session
    ):
        """Test low-confidence actions are not alerted."""
        session_id = "test_session_123"

        # Mock low-confidence incomplete action
        action = MagicMock(spec=LiveMeetingInsight)
        action.id = uuid.uuid4()
        action.content = "Update documentation"
        action.insight_metadata = {
            "completeness_score": 0.4,
            "confidence": 0.7,  # Below 0.8 threshold
            "owner": None,
            "deadline": None
        }

        # Mock database query
        mock_result = MagicMock()
        mock_scalars = MagicMock()
        mock_scalars.all.return_value = [action]
        mock_result.scalars.return_value = mock_scalars
        mock_session.execute = AsyncMock(return_value=mock_result)

        alerts = await action_handler.generate_segment_alerts(
            session_id=session_id,
            session=mock_session
        )

        # Should not generate alert
        assert len(alerts) == 0


@pytest.mark.asyncio
class TestActionMerging:
    """Test action similarity detection and merging."""

    async def test_find_similar_action_high_similarity(
        self,
        action_handler,
        mock_session
    ):
        """Test finding similar action with high keyword overlap."""
        session_id = "test_session_123"
        description = "Update the budget spreadsheet for Q4"

        # Mock existing similar action
        existing_action = MagicMock(spec=LiveMeetingInsight)
        existing_action.id = uuid.uuid4()
        existing_action.content = "Update the budget spreadsheet"

        # Mock database query
        mock_result = MagicMock()
        mock_scalars = MagicMock()
        mock_scalars.all.return_value = [existing_action]
        mock_result.scalars.return_value = mock_scalars
        mock_session.execute = AsyncMock(return_value=mock_result)

        similar_id = await action_handler._find_similar_action(
            session_id=session_id,
            description=description,
            session=mock_session
        )

        # Should find similar action (UUID needs to be converted to string for comparison)
        expected_id = str(existing_action.id) if hasattr(existing_action.id, 'hex') else existing_action.id
        assert similar_id == expected_id

    async def test_find_similar_action_low_similarity(
        self,
        action_handler,
        mock_session
    ):
        """Test no match for dissimilar actions."""
        session_id = "test_session_123"
        description = "Schedule the team meeting"

        # Mock existing different action
        existing_action = MagicMock(spec=LiveMeetingInsight)
        existing_action.id = uuid.uuid4()
        existing_action.content = "Update the budget spreadsheet"

        # Mock database query
        mock_result = MagicMock()
        mock_scalars = MagicMock()
        mock_scalars.all.return_value = [existing_action]
        mock_result.scalars.return_value = mock_scalars
        mock_session.execute = AsyncMock(return_value=mock_result)

        similar_id = await action_handler._find_similar_action(
            session_id=session_id,
            description=description,
            session=mock_session
        )

        # Should not find match
        assert similar_id is None


@pytest.mark.asyncio
class TestCleanup:
    """Test session cleanup."""

    async def test_cleanup_session(self, action_handler):
        """Test cleaning up session resources."""
        session_id = "test_session_123"

        # Add active actions
        action_handler._active_actions[session_id] = {
            "action1": {"description": "Test", "owner": None, "deadline": None}
        }

        await action_handler.cleanup_session(session_id)

        # Should remove session
        assert session_id not in action_handler._active_actions
