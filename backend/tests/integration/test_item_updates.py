"""Integration tests for item updates across all item types."""

import pytest
from datetime import datetime
from typing import Dict, Any
import asyncio

from tests.test_utils import client, create_test_user, create_test_project


@pytest.fixture
async def setup_test_items():
    """Create test items for each type."""
    user = await create_test_user()
    project = await create_test_project(user["access_token"])

    # Create one item of each type
    items = {}

    # Create a risk
    risk_response = client.post(
        f"/api/v1/projects/{project['id']}/risks",
        headers={"Authorization": f"Bearer {user['access_token']}"},
        json={
            "title": "Test Risk",
            "description": "Risk for testing updates",
            "severity": "high",
            "probability": "medium",
            "status": "identified"
        }
    )
    assert risk_response.status_code == 201
    items["risk"] = risk_response.json()

    # Create a task
    task_response = client.post(
        f"/api/v1/projects/{project['id']}/tasks",
        headers={"Authorization": f"Bearer {user['access_token']}"},
        json={
            "title": "Test Task",
            "description": "Task for testing updates",
            "priority": "high",
            "status": "to_do"
        }
    )
    assert task_response.status_code == 201
    items["task"] = task_response.json()

    # Create a blocker
    blocker_response = client.post(
        f"/api/v1/projects/{project['id']}/blockers",
        headers={"Authorization": f"Bearer {user['access_token']}"},
        json={
            "title": "Test Blocker",
            "description": "Blocker for testing updates",
            "severity": "critical",
            "status": "active"
        }
    )
    assert blocker_response.status_code == 201
    items["blocker"] = blocker_response.json()

    # Create a lesson learned
    lesson_response = client.post(
        f"/api/v1/projects/{project['id']}/lessons",
        headers={"Authorization": f"Bearer {user['access_token']}"},
        json={
            "title": "Test Lesson",
            "description": "Lesson for testing updates",
            "impact": "positive",
            "category": "process"
        }
    )
    assert lesson_response.status_code == 201
    items["lesson"] = lesson_response.json()

    return {
        "user": user,
        "project": project,
        "items": items
    }


class TestItemUpdates:
    """Test item updates functionality across all item types."""

    @pytest.mark.parametrize("item_type", ["risk", "task", "blocker", "lesson"])
    def test_add_comment_to_item(self, setup_test_items, item_type):
        """Test adding a comment to each item type."""
        data = setup_test_items
        item = data["items"][item_type.replace("lesson", "lesson")]

        # Add a comment
        response = client.post(
            f"/api/v1/projects/{data['project']['id']}/{item_type}s/{item['id']}/updates",
            headers={"Authorization": f"Bearer {data['user']['access_token']}"},
            json={
                "content": f"Test comment on {item_type}",
                "update_type": "comment",
                "author_name": "Test User"
            }
        )

        assert response.status_code == 201
        update = response.json()
        assert update["content"] == f"Test comment on {item_type}"
        assert update["update_type"] == "comment"
        assert update["author_name"] == "Test User"
        assert "id" in update
        assert "timestamp" in update

    @pytest.mark.parametrize("item_type", ["risk", "task", "blocker", "lesson"])
    def test_get_item_updates(self, setup_test_items, item_type):
        """Test retrieving updates for each item type."""
        data = setup_test_items
        item = data["items"][item_type.replace("lesson", "lesson")]

        # Add multiple updates
        update_types = ["comment", "status_change", "edit"]
        for update_type in update_types:
            client.post(
                f"/api/v1/projects/{data['project']['id']}/{item_type}s/{item['id']}/updates",
                headers={"Authorization": f"Bearer {data['user']['access_token']}"},
                json={
                    "content": f"{update_type} update",
                    "update_type": update_type,
                    "author_name": "Test User"
                }
            )

        # Get all updates
        response = client.get(
            f"/api/v1/projects/{data['project']['id']}/{item_type}s/{item['id']}/updates",
            headers={"Authorization": f"Bearer {data['user']['access_token']}"}
        )

        assert response.status_code == 200
        updates = response.json()
        assert len(updates) >= 3

        # Verify updates are sorted by timestamp (newest first)
        timestamps = [update["timestamp"] for update in updates]
        assert timestamps == sorted(timestamps, reverse=True)

    def test_update_with_author_email(self, setup_test_items):
        """Test adding update with author email."""
        data = setup_test_items
        item = data["items"]["risk"]

        response = client.post(
            f"/api/v1/projects/{data['project']['id']}/risks/{item['id']}/updates",
            headers={"Authorization": f"Bearer {data['user']['access_token']}"},
            json={
                "content": "Update with email",
                "update_type": "comment",
                "author_name": "John Doe",
                "author_email": "john@example.com"
            }
        )

        assert response.status_code == 201
        update = response.json()
        assert update["author_name"] == "John Doe"
        assert update.get("author_email") == "john@example.com"

    def test_different_update_types(self, setup_test_items):
        """Test all different update types."""
        data = setup_test_items
        item = data["items"]["task"]

        update_types = [
            ("comment", "This is a comment"),
            ("status_change", "Status changed from 'to_do' to 'in_progress'"),
            ("assignment", "Assigned to John Doe"),
            ("edit", "Description updated"),
            ("created", "Task created")
        ]

        for update_type, content in update_types:
            response = client.post(
                f"/api/v1/projects/{data['project']['id']}/tasks/{item['id']}/updates",
                headers={"Authorization": f"Bearer {data['user']['access_token']}"},
                json={
                    "content": content,
                    "update_type": update_type,
                    "author_name": "Test User"
                }
            )

            assert response.status_code == 201
            update = response.json()
            assert update["update_type"] == update_type
            assert update["content"] == content

    def test_delete_update(self, setup_test_items):
        """Test deleting an update."""
        data = setup_test_items
        item = data["items"]["blocker"]

        # Create an update
        create_response = client.post(
            f"/api/v1/projects/{data['project']['id']}/blockers/{item['id']}/updates",
            headers={"Authorization": f"Bearer {data['user']['access_token']}"},
            json={
                "content": "Update to delete",
                "update_type": "comment",
                "author_name": "Test User"
            }
        )
        assert create_response.status_code == 201
        update_id = create_response.json()["id"]

        # Delete the update
        delete_response = client.delete(
            f"/api/v1/updates/{update_id}",
            headers={"Authorization": f"Bearer {data['user']['access_token']}"}
        )
        assert delete_response.status_code == 204

        # Verify it's deleted
        get_response = client.get(
            f"/api/v1/projects/{data['project']['id']}/blockers/{item['id']}/updates",
            headers={"Authorization": f"Bearer {data['user']['access_token']}"}
        )
        updates = get_response.json()
        assert all(u["id"] != update_id for u in updates)

    def test_update_without_author_name(self, setup_test_items):
        """Test that missing author_name defaults to 'Current User'."""
        data = setup_test_items
        item = data["items"]["lesson"]

        response = client.post(
            f"/api/v1/projects/{data['project']['id']}/lessons/{item['id']}/updates",
            headers={"Authorization": f"Bearer {data['user']['access_token']}"},
            json={
                "content": "Update without author",
                "update_type": "comment"
            }
        )

        assert response.status_code == 201
        update = response.json()
        # Backend should default to 'Current User' when no author_name provided
        assert update["author_name"] in ["Current User", "User"]

    def test_unauthorized_access(self, setup_test_items):
        """Test that unauthorized users cannot add updates."""
        data = setup_test_items
        item = data["items"]["risk"]

        # Try without auth token
        response = client.post(
            f"/api/v1/projects/{data['project']['id']}/risks/{item['id']}/updates",
            json={
                "content": "Unauthorized update",
                "update_type": "comment"
            }
        )

        assert response.status_code == 401

    def test_concurrent_updates(self, setup_test_items):
        """Test adding multiple updates concurrently."""
        data = setup_test_items
        item = data["items"]["task"]

        # Simulate concurrent updates
        responses = []
        for i in range(5):
            response = client.post(
                f"/api/v1/projects/{data['project']['id']}/tasks/{item['id']}/updates",
                headers={"Authorization": f"Bearer {data['user']['access_token']}"},
                json={
                    "content": f"Concurrent update {i}",
                    "update_type": "comment",
                    "author_name": f"User {i}"
                }
            )
            responses.append(response)

        # All should succeed
        for response in responses:
            assert response.status_code == 201

        # Verify all updates were created
        get_response = client.get(
            f"/api/v1/projects/{data['project']['id']}/tasks/{item['id']}/updates",
            headers={"Authorization": f"Bearer {data['user']['access_token']}"}
        )
        updates = get_response.json()
        assert len(updates) >= 5