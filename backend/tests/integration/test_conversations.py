"""
Integration tests for Conversation Management API.

Covers TESTING_BACKEND.md section 14.1 - Conversation Management

Status: Comprehensive tests for all conversation endpoints
"""

import pytest
from datetime import datetime
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession
from models.user import User
from models.organization import Organization
from models.project import Project, ProjectStatus
from models.conversation import Conversation


# Fixtures
@pytest.fixture
async def test_project(
    db_session: AsyncSession,
    test_organization: Organization,
    test_user: User
) -> Project:
    """Create a test project for conversation tests."""
    project = Project(
        name="Conversation Test Project",
        description="Project for testing conversations",
        organization_id=test_organization.id,
        created_by=str(test_user.id),
        status=ProjectStatus.ACTIVE
    )

    db_session.add(project)
    await db_session.commit()
    await db_session.refresh(project)

    return project


@pytest.fixture
async def unauthenticated_client(client_factory) -> AsyncClient:
    """Create an unauthenticated HTTP client."""
    return await client_factory()


class TestCreateConversation:
    """Test conversation creation endpoint."""

    @pytest.mark.asyncio
    async def test_create_conversation_for_project(
        self,
        authenticated_org_client: AsyncClient,
        test_project: Project
    ):
        """Test creating a conversation for a project."""
        # Arrange
        conversation_data = {
            "title": "Project Discussion",
            "messages": []
        }

        # Act
        response = await authenticated_org_client.post(
            f"/api/projects/{test_project.id}/conversations",
            json=conversation_data
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["title"] == "Project Discussion"
        assert data["project_id"] == str(test_project.id)
        assert data["messages"] == []
        assert "id" in data
        assert "created_at" in data
        assert "last_accessed_at" in data

    @pytest.mark.asyncio
    async def test_create_conversation_with_messages(
        self,
        authenticated_org_client: AsyncClient,
        test_project: Project
    ):
        """Test creating a conversation with initial messages."""
        # Arrange
        conversation_data = {
            "title": "Q&A Session",
            "messages": [
                {
                    "question": "What is the project status?",
                    "answer": "The project is on track.",
                    "sources": ["meeting_2024_01_15.txt"],
                    "confidence": 0.95,
                    "timestamp": "2024-01-15T10:00:00",
                    "isAnswerPending": False
                },
                {
                    "question": "Any blockers?",
                    "answer": "No blockers identified.",
                    "sources": ["meeting_2024_01_15.txt"],
                    "confidence": 0.90,
                    "timestamp": "2024-01-15T10:05:00",
                    "isAnswerPending": False
                }
            ]
        }

        # Act
        response = await authenticated_org_client.post(
            f"/api/projects/{test_project.id}/conversations",
            json=conversation_data
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["title"] == "Q&A Session"
        assert len(data["messages"]) == 2
        assert data["messages"][0]["question"] == "What is the project status?"
        assert data["messages"][0]["answer"] == "The project is on track."
        assert data["messages"][0]["confidence"] == 0.95
        assert data["messages"][1]["question"] == "Any blockers?"

    @pytest.mark.asyncio
    async def test_create_organization_level_conversation(
        self,
        authenticated_org_client: AsyncClient
    ):
        """Test creating an organization-level conversation (no project)."""
        # Arrange
        conversation_data = {
            "title": "Organization Strategy",
            "messages": [
                {
                    "question": "What are our key initiatives?",
                    "answer": "We have 5 key initiatives this quarter.",
                    "sources": ["strategy_doc.pdf"],
                    "confidence": 0.92,
                    "timestamp": "2024-01-15T10:00:00",
                    "isAnswerPending": False
                }
            ]
        }

        # Act
        response = await authenticated_org_client.post(
            "/api/projects/organization/conversations",
            json=conversation_data
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["title"] == "Organization Strategy"
        assert data["project_id"] == "organization"
        assert len(data["messages"]) == 1
        assert data["messages"][0]["question"] == "What are our key initiatives?"

    @pytest.mark.asyncio
    async def test_create_conversation_requires_authentication(
        self,
        unauthenticated_client: AsyncClient,
        test_project: Project
    ):
        """Test that creating a conversation requires authentication."""
        # Arrange
        conversation_data = {
            "title": "Test Conversation",
            "messages": []
        }

        # Act
        response = await unauthenticated_client.post(
            f"/api/projects/{test_project.id}/conversations",
            json=conversation_data
        )

        # Assert
        assert response.status_code in [401, 403]

    @pytest.mark.asyncio
    async def test_create_conversation_requires_member_role(
        self,
        client_factory,
        test_project: Project,
        db_session: AsyncSession
    ):
        """Test that creating a conversation requires member role."""
        # This test assumes role-based access control is enforced
        # The endpoint uses require_role("member") which should allow members and above
        # This test is a placeholder - actual implementation may vary
        pass


class TestListConversations:
    """Test conversation listing endpoint."""

    @pytest.mark.asyncio
    async def test_list_conversations_for_project(
        self,
        authenticated_org_client: AsyncClient,
        test_project: Project,
        db_session: AsyncSession,
        test_organization: Organization,
        test_user: User
    ):
        """Test listing all conversations for a project."""
        # Arrange - Create multiple conversations
        conv1 = Conversation(
            project_id=test_project.id,
            organization_id=test_organization.id,
            title="First Discussion",
            messages=[],
            created_by=test_user.email,
            created_at=datetime.utcnow(),
            last_accessed_at=datetime.utcnow()
        )
        conv2 = Conversation(
            project_id=test_project.id,
            organization_id=test_organization.id,
            title="Second Discussion",
            messages=[],
            created_by=test_user.email,
            created_at=datetime.utcnow(),
            last_accessed_at=datetime.utcnow()
        )
        db_session.add_all([conv1, conv2])
        await db_session.commit()

        # Act
        response = await authenticated_org_client.get(
            f"/api/projects/{test_project.id}/conversations"
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert len(data) == 2
        titles = [conv["title"] for conv in data]
        assert "First Discussion" in titles
        assert "Second Discussion" in titles

    @pytest.mark.asyncio
    async def test_list_organization_level_conversations(
        self,
        authenticated_org_client: AsyncClient,
        db_session: AsyncSession,
        test_organization: Organization,
        test_user: User
    ):
        """Test listing organization-level conversations."""
        # Arrange - Create org-level conversations
        conv1 = Conversation(
            project_id=None,  # Organization-level
            organization_id=test_organization.id,
            title="Org Strategy Q1",
            messages=[],
            created_by=test_user.email,
            created_at=datetime.utcnow(),
            last_accessed_at=datetime.utcnow()
        )
        conv2 = Conversation(
            project_id=None,  # Organization-level
            organization_id=test_organization.id,
            title="Org Strategy Q2",
            messages=[],
            created_by=test_user.email,
            created_at=datetime.utcnow(),
            last_accessed_at=datetime.utcnow()
        )
        db_session.add_all([conv1, conv2])
        await db_session.commit()

        # Act
        response = await authenticated_org_client.get(
            "/api/projects/organization/conversations"
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert len(data) == 2
        titles = [conv["title"] for conv in data]
        assert "Org Strategy Q1" in titles
        assert "Org Strategy Q2" in titles
        # Verify all conversations are org-level
        for conv in data:
            assert conv["project_id"] == "organization"

    @pytest.mark.asyncio
    async def test_list_conversations_empty_result(
        self,
        authenticated_org_client: AsyncClient,
        test_project: Project
    ):
        """Test listing conversations when none exist."""
        # Act
        response = await authenticated_org_client.get(
            f"/api/projects/{test_project.id}/conversations"
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data == []

    @pytest.mark.asyncio
    async def test_list_conversations_ordered_by_last_accessed(
        self,
        authenticated_org_client: AsyncClient,
        test_project: Project,
        db_session: AsyncSession,
        test_organization: Organization,
        test_user: User
    ):
        """Test that conversations are ordered by last_accessed_at (most recent first)."""
        # Arrange - Create conversations with different last_accessed times
        import time
        conv1 = Conversation(
            project_id=test_project.id,
            organization_id=test_organization.id,
            title="Oldest",
            messages=[],
            created_by=test_user.email,
            created_at=datetime(2024, 1, 1, 10, 0, 0),
            last_accessed_at=datetime(2024, 1, 1, 10, 0, 0)
        )
        conv2 = Conversation(
            project_id=test_project.id,
            organization_id=test_organization.id,
            title="Newest",
            messages=[],
            created_by=test_user.email,
            created_at=datetime(2024, 1, 3, 10, 0, 0),
            last_accessed_at=datetime(2024, 1, 3, 10, 0, 0)
        )
        conv3 = Conversation(
            project_id=test_project.id,
            organization_id=test_organization.id,
            title="Middle",
            messages=[],
            created_by=test_user.email,
            created_at=datetime(2024, 1, 2, 10, 0, 0),
            last_accessed_at=datetime(2024, 1, 2, 10, 0, 0)
        )
        db_session.add_all([conv1, conv2, conv3])
        await db_session.commit()

        # Act
        response = await authenticated_org_client.get(
            f"/api/projects/{test_project.id}/conversations"
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert len(data) == 3
        # Most recent first
        assert data[0]["title"] == "Newest"
        assert data[1]["title"] == "Middle"
        assert data[2]["title"] == "Oldest"

    @pytest.mark.asyncio
    async def test_list_conversations_requires_authentication(
        self,
        unauthenticated_client: AsyncClient,
        test_project: Project
    ):
        """Test that listing conversations requires authentication."""
        # Act
        response = await unauthenticated_client.get(
            f"/api/projects/{test_project.id}/conversations"
        )

        # Assert
        assert response.status_code in [401, 403]


class TestGetConversation:
    """Test get conversation by ID endpoint."""

    @pytest.mark.asyncio
    async def test_get_conversation_by_id(
        self,
        authenticated_org_client: AsyncClient,
        test_project: Project,
        db_session: AsyncSession,
        test_organization: Organization,
        test_user: User
    ):
        """Test getting a specific conversation by ID."""
        # Arrange
        conversation = Conversation(
            project_id=test_project.id,
            organization_id=test_organization.id,
            title="Detailed Discussion",
            messages=[
                {
                    "question": "What's the timeline?",
                    "answer": "Two weeks.",
                    "sources": ["plan.pdf"],
                    "confidence": 0.88,
                    "timestamp": "2024-01-15T10:00:00",
                    "isAnswerPending": False
                }
            ],
            created_by=test_user.email,
            created_at=datetime.utcnow(),
            last_accessed_at=datetime.utcnow()
        )
        db_session.add(conversation)
        await db_session.commit()
        await db_session.refresh(conversation)

        # Act
        response = await authenticated_org_client.get(
            f"/api/projects/{test_project.id}/conversations/{conversation.id}"
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["id"] == str(conversation.id)
        assert data["title"] == "Detailed Discussion"
        assert len(data["messages"]) == 1
        assert data["messages"][0]["question"] == "What's the timeline?"

    @pytest.mark.asyncio
    async def test_get_conversation_updates_last_accessed(
        self,
        authenticated_org_client: AsyncClient,
        test_project: Project,
        db_session: AsyncSession,
        test_organization: Organization,
        test_user: User
    ):
        """Test that getting a conversation updates last_accessed_at."""
        # Arrange
        old_time = datetime(2024, 1, 1, 10, 0, 0)
        conversation = Conversation(
            project_id=test_project.id,
            organization_id=test_organization.id,
            title="Test Conversation",
            messages=[],
            created_by=test_user.email,
            created_at=old_time,
            last_accessed_at=old_time
        )
        db_session.add(conversation)
        await db_session.commit()
        await db_session.refresh(conversation)

        # Act
        response = await authenticated_org_client.get(
            f"/api/projects/{test_project.id}/conversations/{conversation.id}"
        )

        # Assert
        assert response.status_code == 200
        # Refresh to get updated value
        await db_session.refresh(conversation)
        # last_accessed_at should be more recent than old_time
        assert conversation.last_accessed_at > old_time

    @pytest.mark.asyncio
    async def test_get_organization_level_conversation(
        self,
        authenticated_org_client: AsyncClient,
        db_session: AsyncSession,
        test_organization: Organization,
        test_user: User
    ):
        """Test getting an organization-level conversation."""
        # Arrange
        conversation = Conversation(
            project_id=None,
            organization_id=test_organization.id,
            title="Org Level Chat",
            messages=[],
            created_by=test_user.email,
            created_at=datetime.utcnow(),
            last_accessed_at=datetime.utcnow()
        )
        db_session.add(conversation)
        await db_session.commit()
        await db_session.refresh(conversation)

        # Act
        response = await authenticated_org_client.get(
            f"/api/projects/organization/conversations/{conversation.id}"
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["id"] == str(conversation.id)
        assert data["project_id"] == "organization"
        assert data["title"] == "Org Level Chat"

    @pytest.mark.asyncio
    async def test_get_conversation_not_found(
        self,
        authenticated_org_client: AsyncClient,
        test_project: Project
    ):
        """Test getting a non-existent conversation."""
        # Arrange
        fake_id = "00000000-0000-0000-0000-000000000000"

        # Act
        response = await authenticated_org_client.get(
            f"/api/projects/{test_project.id}/conversations/{fake_id}"
        )

        # Assert
        assert response.status_code == 404
        assert "not found" in response.json()["detail"].lower()

    @pytest.mark.asyncio
    async def test_get_conversation_requires_authentication(
        self,
        unauthenticated_client: AsyncClient,
        test_project: Project,
        db_session: AsyncSession,
        test_organization: Organization,
        test_user: User
    ):
        """Test that getting a conversation requires authentication."""
        # Arrange
        conversation = Conversation(
            project_id=test_project.id,
            organization_id=test_organization.id,
            title="Test",
            messages=[],
            created_by=test_user.email,
            created_at=datetime.utcnow(),
            last_accessed_at=datetime.utcnow()
        )
        db_session.add(conversation)
        await db_session.commit()
        await db_session.refresh(conversation)

        # Act
        response = await unauthenticated_client.get(
            f"/api/projects/{test_project.id}/conversations/{conversation.id}"
        )

        # Assert
        assert response.status_code in [401, 403]


class TestUpdateConversation:
    """Test conversation update endpoint."""

    @pytest.mark.asyncio
    async def test_update_conversation_title(
        self,
        authenticated_org_client: AsyncClient,
        test_project: Project,
        db_session: AsyncSession,
        test_organization: Organization,
        test_user: User
    ):
        """Test updating a conversation's title."""
        # Arrange
        conversation = Conversation(
            project_id=test_project.id,
            organization_id=test_organization.id,
            title="Original Title",
            messages=[],
            created_by=test_user.email,
            created_at=datetime.utcnow(),
            last_accessed_at=datetime.utcnow()
        )
        db_session.add(conversation)
        await db_session.commit()
        await db_session.refresh(conversation)

        update_data = {
            "title": "Updated Title"
        }

        # Act
        response = await authenticated_org_client.put(
            f"/api/projects/{test_project.id}/conversations/{conversation.id}",
            json=update_data
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["title"] == "Updated Title"
        assert data["id"] == str(conversation.id)

    @pytest.mark.asyncio
    async def test_update_conversation_messages(
        self,
        authenticated_org_client: AsyncClient,
        test_project: Project,
        db_session: AsyncSession,
        test_organization: Organization,
        test_user: User
    ):
        """Test updating a conversation's messages (adding to chat history)."""
        # Arrange
        conversation = Conversation(
            project_id=test_project.id,
            organization_id=test_organization.id,
            title="Chat",
            messages=[
                {
                    "question": "First question?",
                    "answer": "First answer.",
                    "sources": [],
                    "confidence": 0.90,
                    "timestamp": "2024-01-15T10:00:00",
                    "isAnswerPending": False
                }
            ],
            created_by=test_user.email,
            created_at=datetime.utcnow(),
            last_accessed_at=datetime.utcnow()
        )
        db_session.add(conversation)
        await db_session.commit()
        await db_session.refresh(conversation)

        # Add a new message to the conversation
        update_data = {
            "messages": [
                {
                    "question": "First question?",
                    "answer": "First answer.",
                    "sources": [],
                    "confidence": 0.90,
                    "timestamp": "2024-01-15T10:00:00",
                    "isAnswerPending": False
                },
                {
                    "question": "Second question?",
                    "answer": "Second answer.",
                    "sources": ["doc.pdf"],
                    "confidence": 0.85,
                    "timestamp": "2024-01-15T10:05:00",
                    "isAnswerPending": False
                }
            ]
        }

        # Act
        response = await authenticated_org_client.put(
            f"/api/projects/{test_project.id}/conversations/{conversation.id}",
            json=update_data
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert len(data["messages"]) == 2
        assert data["messages"][1]["question"] == "Second question?"
        assert data["messages"][1]["answer"] == "Second answer."

    @pytest.mark.asyncio
    async def test_update_conversation_both_title_and_messages(
        self,
        authenticated_org_client: AsyncClient,
        test_project: Project,
        db_session: AsyncSession,
        test_organization: Organization,
        test_user: User
    ):
        """Test updating both title and messages in one request."""
        # Arrange
        conversation = Conversation(
            project_id=test_project.id,
            organization_id=test_organization.id,
            title="Old Title",
            messages=[],
            created_by=test_user.email,
            created_at=datetime.utcnow(),
            last_accessed_at=datetime.utcnow()
        )
        db_session.add(conversation)
        await db_session.commit()
        await db_session.refresh(conversation)

        update_data = {
            "title": "New Title",
            "messages": [
                {
                    "question": "Test question?",
                    "answer": "Test answer.",
                    "sources": [],
                    "confidence": 0.95,
                    "timestamp": "2024-01-15T10:00:00",
                    "isAnswerPending": False
                }
            ]
        }

        # Act
        response = await authenticated_org_client.put(
            f"/api/projects/{test_project.id}/conversations/{conversation.id}",
            json=update_data
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["title"] == "New Title"
        assert len(data["messages"]) == 1
        assert data["messages"][0]["question"] == "Test question?"

    @pytest.mark.asyncio
    async def test_update_conversation_updates_last_accessed(
        self,
        authenticated_org_client: AsyncClient,
        test_project: Project,
        db_session: AsyncSession,
        test_organization: Organization,
        test_user: User
    ):
        """Test that updating a conversation updates last_accessed_at."""
        # Arrange
        old_time = datetime(2024, 1, 1, 10, 0, 0)
        conversation = Conversation(
            project_id=test_project.id,
            organization_id=test_organization.id,
            title="Test",
            messages=[],
            created_by=test_user.email,
            created_at=old_time,
            last_accessed_at=old_time
        )
        db_session.add(conversation)
        await db_session.commit()
        await db_session.refresh(conversation)

        update_data = {"title": "Updated"}

        # Act
        response = await authenticated_org_client.put(
            f"/api/projects/{test_project.id}/conversations/{conversation.id}",
            json=update_data
        )

        # Assert
        assert response.status_code == 200
        await db_session.refresh(conversation)
        assert conversation.last_accessed_at > old_time

    @pytest.mark.asyncio
    async def test_update_conversation_not_found(
        self,
        authenticated_org_client: AsyncClient,
        test_project: Project
    ):
        """Test updating a non-existent conversation."""
        # Arrange
        fake_id = "00000000-0000-0000-0000-000000000000"
        update_data = {"title": "New Title"}

        # Act
        response = await authenticated_org_client.put(
            f"/api/projects/{test_project.id}/conversations/{fake_id}",
            json=update_data
        )

        # Assert
        assert response.status_code == 404

    @pytest.mark.asyncio
    async def test_update_conversation_requires_authentication(
        self,
        unauthenticated_client: AsyncClient,
        test_project: Project,
        db_session: AsyncSession,
        test_organization: Organization,
        test_user: User
    ):
        """Test that updating a conversation requires authentication."""
        # Arrange
        conversation = Conversation(
            project_id=test_project.id,
            organization_id=test_organization.id,
            title="Test",
            messages=[],
            created_by=test_user.email,
            created_at=datetime.utcnow(),
            last_accessed_at=datetime.utcnow()
        )
        db_session.add(conversation)
        await db_session.commit()
        await db_session.refresh(conversation)

        update_data = {"title": "Hacked"}

        # Act
        response = await unauthenticated_client.put(
            f"/api/projects/{test_project.id}/conversations/{conversation.id}",
            json=update_data
        )

        # Assert
        assert response.status_code in [401, 403]

    @pytest.mark.asyncio
    async def test_update_organization_level_conversation(
        self,
        authenticated_org_client: AsyncClient,
        db_session: AsyncSession,
        test_organization: Organization,
        test_user: User
    ):
        """Test updating an organization-level conversation (bug check for None project_id)."""
        # Arrange
        conversation = Conversation(
            project_id=None,  # Organization-level
            organization_id=test_organization.id,
            title="Org Strategy",
            messages=[],
            created_by=test_user.email,
            created_at=datetime.utcnow(),
            last_accessed_at=datetime.utcnow()
        )
        db_session.add(conversation)
        await db_session.commit()
        await db_session.refresh(conversation)

        update_data = {"title": "Updated Org Strategy"}

        # Act
        response = await authenticated_org_client.put(
            f"/api/projects/organization/conversations/{conversation.id}",
            json=update_data
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["title"] == "Updated Org Strategy"
        assert data["project_id"] == "organization"  # Should return 'organization', not None


class TestDeleteConversation:
    """Test conversation deletion endpoint."""

    @pytest.mark.asyncio
    async def test_delete_conversation(
        self,
        authenticated_org_client: AsyncClient,
        test_project: Project,
        db_session: AsyncSession,
        test_organization: Organization,
        test_user: User
    ):
        """Test deleting a conversation."""
        # Arrange
        conversation = Conversation(
            project_id=test_project.id,
            organization_id=test_organization.id,
            title="To Delete",
            messages=[],
            created_by=test_user.email,
            created_at=datetime.utcnow(),
            last_accessed_at=datetime.utcnow()
        )
        db_session.add(conversation)
        await db_session.commit()
        await db_session.refresh(conversation)
        conversation_id = conversation.id

        # Act
        response = await authenticated_org_client.delete(
            f"/api/projects/{test_project.id}/conversations/{conversation_id}"
        )

        # Assert
        assert response.status_code == 200
        assert "deleted successfully" in response.json()["message"].lower()

        # Verify conversation is actually deleted
        from sqlalchemy import select
        result = await db_session.execute(
            select(Conversation).where(Conversation.id == conversation_id)
        )
        deleted_conv = result.scalar_one_or_none()
        assert deleted_conv is None

    @pytest.mark.asyncio
    async def test_delete_organization_level_conversation(
        self,
        authenticated_org_client: AsyncClient,
        db_session: AsyncSession,
        test_organization: Organization,
        test_user: User
    ):
        """Test deleting an organization-level conversation."""
        # Arrange
        conversation = Conversation(
            project_id=None,
            organization_id=test_organization.id,
            title="Org Conv",
            messages=[],
            created_by=test_user.email,
            created_at=datetime.utcnow(),
            last_accessed_at=datetime.utcnow()
        )
        db_session.add(conversation)
        await db_session.commit()
        await db_session.refresh(conversation)
        conversation_id = conversation.id

        # Act
        response = await authenticated_org_client.delete(
            f"/api/projects/organization/conversations/{conversation_id}"
        )

        # Assert
        assert response.status_code == 200
        assert "deleted successfully" in response.json()["message"].lower()

    @pytest.mark.asyncio
    async def test_delete_conversation_not_found(
        self,
        authenticated_org_client: AsyncClient,
        test_project: Project
    ):
        """Test deleting a non-existent conversation."""
        # Arrange
        fake_id = "00000000-0000-0000-0000-000000000000"

        # Act
        response = await authenticated_org_client.delete(
            f"/api/projects/{test_project.id}/conversations/{fake_id}"
        )

        # Assert
        assert response.status_code == 404

    @pytest.mark.asyncio
    async def test_delete_conversation_requires_authentication(
        self,
        unauthenticated_client: AsyncClient,
        test_project: Project,
        db_session: AsyncSession,
        test_organization: Organization,
        test_user: User
    ):
        """Test that deleting a conversation requires authentication."""
        # Arrange
        conversation = Conversation(
            project_id=test_project.id,
            organization_id=test_organization.id,
            title="Test",
            messages=[],
            created_by=test_user.email,
            created_at=datetime.utcnow(),
            last_accessed_at=datetime.utcnow()
        )
        db_session.add(conversation)
        await db_session.commit()
        await db_session.refresh(conversation)

        # Act
        response = await unauthenticated_client.delete(
            f"/api/projects/{test_project.id}/conversations/{conversation.id}"
        )

        # Assert
        assert response.status_code in [401, 403]


class TestMultiTenantIsolation:
    """Test multi-tenant isolation for conversations."""

    @pytest.mark.asyncio
    async def test_cannot_access_other_org_conversations(
        self,
        client_factory,
        test_project: Project,
        db_session: AsyncSession,
        test_organization: Organization,
        test_user: User
    ):
        """Test that users cannot access conversations from other organizations."""
        # Arrange - Create a second organization and user
        from models.organization import Organization
        from models.user import User
        from models.organization_member import OrganizationMember, OrganizationRole
        from services.auth.native_auth_service import native_auth_service

        other_org = Organization(
            name="Other Org",
            slug="other-org",
            created_at=datetime.utcnow()
        )
        db_session.add(other_org)
        await db_session.commit()
        await db_session.refresh(other_org)

        other_user = User(
            email="other@example.com",
            password_hash="hashedpass",
            name="Other User",
            is_active=True
        )
        db_session.add(other_user)
        await db_session.commit()
        await db_session.refresh(other_user)

        other_member = OrganizationMember(
            user_id=other_user.id,
            organization_id=other_org.id,
            role=OrganizationRole.ADMIN
        )
        db_session.add(other_member)
        await db_session.commit()

        # Create conversation in test_organization
        conversation = Conversation(
            project_id=test_project.id,
            organization_id=test_organization.id,
            title="Secret Conversation",
            messages=[],
            created_by=test_user.email,
            created_at=datetime.utcnow(),
            last_accessed_at=datetime.utcnow()
        )
        db_session.add(conversation)
        await db_session.commit()
        await db_session.refresh(conversation)

        # Create client for other_user in other_org
        other_token = native_auth_service.create_access_token(
            user_id=str(other_user.id),
            email=other_user.email,
            organization_id=str(other_org.id)
        )
        other_client = await client_factory(
            Authorization=f"Bearer {other_token}",
            **{"X-Organization-Id": str(other_org.id)}
        )

        # Act - Try to access conversation from other org
        response = await other_client.get(
            f"/api/projects/{test_project.id}/conversations/{conversation.id}"
        )

        # Assert - Should not be able to access
        assert response.status_code == 404

    @pytest.mark.asyncio
    async def test_cannot_list_other_org_conversations(
        self,
        client_factory,
        test_project: Project,
        db_session: AsyncSession,
        test_organization: Organization,
        test_user: User
    ):
        """Test that listing conversations only returns conversations from the user's organization."""
        # Arrange - Create conversation in test_organization
        conversation = Conversation(
            project_id=test_project.id,
            organization_id=test_organization.id,
            title="Org 1 Conversation",
            messages=[],
            created_by=test_user.email,
            created_at=datetime.utcnow(),
            last_accessed_at=datetime.utcnow()
        )
        db_session.add(conversation)
        await db_session.commit()

        # Create second organization and user
        from models.organization import Organization
        from models.user import User
        from models.organization_member import OrganizationMember, OrganizationRole
        from services.auth.native_auth_service import native_auth_service

        other_org = Organization(
            name="Other Org",
            slug="other-org",
            created_at=datetime.utcnow()
        )
        db_session.add(other_org)
        await db_session.commit()
        await db_session.refresh(other_org)

        other_user = User(
            email="other2@example.com",
            password_hash="hashedpass",
            name="Other User 2",
            is_active=True
        )
        db_session.add(other_user)
        await db_session.commit()
        await db_session.refresh(other_user)

        other_member = OrganizationMember(
            user_id=other_user.id,
            organization_id=other_org.id,
            role=OrganizationRole.ADMIN
        )
        db_session.add(other_member)
        await db_session.commit()

        # Create client for other_user in other_org
        other_token = native_auth_service.create_access_token(
            user_id=str(other_user.id),
            email=other_user.email,
            organization_id=str(other_org.id)
        )
        other_client = await client_factory(
            Authorization=f"Bearer {other_token}",
            **{"X-Organization-Id": str(other_org.id)}
        )

        # Act - List conversations for test_project (which belongs to test_organization)
        response = await other_client.get(
            f"/api/projects/{test_project.id}/conversations"
        )

        # Assert - Should return empty list (no cross-org access)
        assert response.status_code == 200
        data = response.json()
        assert len(data) == 0


class TestMultiTurnChatHistory:
    """Test multi-turn conversation functionality."""

    @pytest.mark.asyncio
    async def test_build_conversation_history_over_time(
        self,
        authenticated_org_client: AsyncClient,
        test_project: Project
    ):
        """Test building a multi-turn conversation by updating messages."""
        # Act 1 - Create conversation with first message
        create_data = {
            "title": "Project Q&A",
            "messages": [
                {
                    "question": "What's the project status?",
                    "answer": "On track.",
                    "sources": ["status.pdf"],
                    "confidence": 0.90,
                    "timestamp": "2024-01-15T10:00:00",
                    "isAnswerPending": False
                }
            ]
        }
        response1 = await authenticated_org_client.post(
            f"/api/projects/{test_project.id}/conversations",
            json=create_data
        )
        assert response1.status_code == 200
        conversation_id = response1.json()["id"]

        # Act 2 - Add second message
        update_data_2 = {
            "messages": [
                {
                    "question": "What's the project status?",
                    "answer": "On track.",
                    "sources": ["status.pdf"],
                    "confidence": 0.90,
                    "timestamp": "2024-01-15T10:00:00",
                    "isAnswerPending": False
                },
                {
                    "question": "Any risks?",
                    "answer": "No major risks identified.",
                    "sources": ["risk_report.pdf"],
                    "confidence": 0.85,
                    "timestamp": "2024-01-15T10:05:00",
                    "isAnswerPending": False
                }
            ]
        }
        response2 = await authenticated_org_client.put(
            f"/api/projects/{test_project.id}/conversations/{conversation_id}",
            json=update_data_2
        )
        assert response2.status_code == 200
        assert len(response2.json()["messages"]) == 2

        # Act 3 - Add third message
        update_data_3 = {
            "messages": [
                {
                    "question": "What's the project status?",
                    "answer": "On track.",
                    "sources": ["status.pdf"],
                    "confidence": 0.90,
                    "timestamp": "2024-01-15T10:00:00",
                    "isAnswerPending": False
                },
                {
                    "question": "Any risks?",
                    "answer": "No major risks identified.",
                    "sources": ["risk_report.pdf"],
                    "confidence": 0.85,
                    "timestamp": "2024-01-15T10:05:00",
                    "isAnswerPending": False
                },
                {
                    "question": "What's next?",
                    "answer": "Sprint planning meeting.",
                    "sources": ["calendar.pdf"],
                    "confidence": 0.92,
                    "timestamp": "2024-01-15T10:10:00",
                    "isAnswerPending": False
                }
            ]
        }
        response3 = await authenticated_org_client.put(
            f"/api/projects/{test_project.id}/conversations/{conversation_id}",
            json=update_data_3
        )

        # Assert
        assert response3.status_code == 200
        final_data = response3.json()
        assert len(final_data["messages"]) == 3
        assert final_data["messages"][0]["question"] == "What's the project status?"
        assert final_data["messages"][1]["question"] == "Any risks?"
        assert final_data["messages"][2]["question"] == "What's next?"

    @pytest.mark.asyncio
    async def test_conversation_with_pending_answer(
        self,
        authenticated_org_client: AsyncClient,
        test_project: Project
    ):
        """Test creating a conversation with a pending answer (streaming scenario)."""
        # Arrange
        conversation_data = {
            "title": "Live Q&A",
            "messages": [
                {
                    "question": "What are the key milestones?",
                    "answer": "",
                    "sources": [],
                    "confidence": 0.0,
                    "timestamp": "2024-01-15T10:00:00",
                    "isAnswerPending": True
                }
            ]
        }

        # Act
        response = await authenticated_org_client.post(
            f"/api/projects/{test_project.id}/conversations",
            json=conversation_data
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert len(data["messages"]) == 1
        assert data["messages"][0]["isAnswerPending"] is True
        assert data["messages"][0]["answer"] == ""
