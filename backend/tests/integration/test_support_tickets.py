"""
Integration tests for Support Tickets API.

Covers TESTING_BACKEND.md section 13.1 - Ticket Management

Tests cover:
- Create support ticket
- List tickets (with filtering, sorting, pagination)
- Get ticket by ID
- Update ticket (status, priority, assignment, resolution)
- Delete ticket (creator only)
- Add comments to tickets
- List ticket comments (with internal filter)
- Upload attachments to tickets
- Download attachments
- Multi-tenant isolation
- Authentication requirements
- Validation and error handling

Expected Status: Comprehensive coverage of all ticket management features
"""

import pytest
from datetime import datetime, timedelta
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession
from models.user import User
from models.organization import Organization
from models.organization_member import OrganizationMember
from models.support_ticket import SupportTicket, TicketComment, TicketAttachment
from services.auth.native_auth_service import native_auth_service
import uuid
from pathlib import Path
import tempfile


# ========================================
# Ticket Fixtures
# ========================================

@pytest.fixture
async def test_ticket(
    db_session: AsyncSession,
    test_organization: Organization,
    test_user: User
) -> SupportTicket:
    """Create a test support ticket."""
    ticket = SupportTicket(
        organization_id=test_organization.id,
        title="Test Bug Report",
        description="This is a test bug that needs to be fixed",
        type="bug_report",
        priority="high",
        status="open",
        created_by=test_user.id
    )

    db_session.add(ticket)
    await db_session.commit()
    await db_session.refresh(ticket)
    return ticket


@pytest.fixture
async def resolved_ticket(
    db_session: AsyncSession,
    test_organization: Organization,
    test_user: User
) -> SupportTicket:
    """Create a resolved test ticket."""
    ticket = SupportTicket(
        organization_id=test_organization.id,
        title="Resolved Issue",
        description="This issue has been resolved",
        type="feature_request",
        priority="medium",
        status="resolved",
        created_by=test_user.id,
        resolved_at=datetime.utcnow(),
        resolution_notes="Fixed in version 2.0"
    )

    db_session.add(ticket)
    await db_session.commit()
    await db_session.refresh(ticket)
    return ticket


# ========================================
# Multi-tenant Fixtures
# ========================================

@pytest.fixture
async def second_organization(
    db_session: AsyncSession,
    test_user: User
) -> Organization:
    """Create a second organization for multi-tenant tests."""
    org = Organization(
        name="Second Organization",
        slug="second-organization",
        created_by=test_user.id
    )

    db_session.add(org)
    await db_session.commit()
    await db_session.refresh(org)
    return org


@pytest.fixture
async def second_org_user(
    db_session: AsyncSession
) -> User:
    """Create a user for the second organization."""
    user = User(
        email="secondorg@example.com",
        name="Second Org User",
        password_hash=native_auth_service.hash_password("password123"),
        is_active=True,
        email_verified=True
    )

    db_session.add(user)
    await db_session.commit()
    await db_session.refresh(user)
    return user


@pytest.fixture
async def second_org_membership(
    db_session: AsyncSession,
    second_organization: Organization,
    second_org_user: User
) -> OrganizationMember:
    """Create membership for second organization user."""
    member = OrganizationMember(
        organization_id=second_organization.id,
        user_id=second_org_user.id,
        role="admin"
    )

    db_session.add(member)

    # Set as active organization
    second_org_user.active_organization_id = second_organization.id

    await db_session.commit()
    await db_session.refresh(member)
    return member


@pytest.fixture
async def second_org_ticket(
    db_session: AsyncSession,
    second_organization: Organization,
    second_org_user: User
) -> SupportTicket:
    """Create a ticket in the second organization."""
    ticket = SupportTicket(
        organization_id=second_organization.id,
        title="Second Org Ticket",
        description="This ticket belongs to second organization",
        type="general_support",
        priority="low",
        status="open",
        created_by=second_org_user.id
    )

    db_session.add(ticket)
    await db_session.commit()
    await db_session.refresh(ticket)
    return ticket


# ========================================
# Test Classes
# ========================================

class TestCreateTicket:
    """Tests for POST /api/v1/support-tickets/"""

    @pytest.mark.asyncio
    async def test_create_ticket_success(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization
    ):
        """Test creating a support ticket successfully."""
        response = await authenticated_org_client.post(
            "/api/v1/support-tickets/",
            json={
                "title": "New Feature Request",
                "description": "We need a new dashboard feature",
                "type": "feature_request",
                "priority": "medium"
            }
        )

        assert response.status_code == 200
        data = response.json()

        assert data["title"] == "New Feature Request"
        assert data["description"] == "We need a new dashboard feature"
        assert data["type"] == "feature_request"
        assert data["priority"] == "medium"
        assert data["status"] == "open"
        assert "id" in data
        assert data["created_by"] is not None
        assert data["creator_name"] is not None
        assert data["creator_email"] is not None
        assert data["assigned_to"] is None
        assert data["comment_count"] == 0
        assert data["attachment_count"] == 0

    @pytest.mark.asyncio
    async def test_create_ticket_all_types(
        self,
        authenticated_org_client: AsyncClient
    ):
        """Test creating tickets with all valid types."""
        types = ["bug_report", "feature_request", "general_support", "documentation"]

        for ticket_type in types:
            response = await authenticated_org_client.post(
                "/api/v1/support-tickets/",
                json={
                    "title": f"Test {ticket_type}",
                    "description": f"Testing {ticket_type} type",
                    "type": ticket_type,
                    "priority": "low"
                }
            )

            assert response.status_code == 200
            assert response.json()["type"] == ticket_type

    @pytest.mark.asyncio
    async def test_create_ticket_all_priorities(
        self,
        authenticated_org_client: AsyncClient
    ):
        """Test creating tickets with all valid priorities."""
        priorities = ["low", "medium", "high", "critical"]

        for priority in priorities:
            response = await authenticated_org_client.post(
                "/api/v1/support-tickets/",
                json={
                    "title": f"Test {priority} priority",
                    "description": f"Testing {priority} priority",
                    "type": "bug_report",
                    "priority": priority
                }
            )

            assert response.status_code == 200
            assert response.json()["priority"] == priority

    @pytest.mark.asyncio
    async def test_create_ticket_missing_required_fields(
        self,
        authenticated_org_client: AsyncClient
    ):
        """Test creating ticket without required fields."""
        # Missing title
        response = await authenticated_org_client.post(
            "/api/v1/support-tickets/",
            json={
                "description": "Missing title",
                "type": "bug_report",
                "priority": "medium"
            }
        )
        assert response.status_code == 422

        # Missing description
        response = await authenticated_org_client.post(
            "/api/v1/support-tickets/",
            json={
                "title": "Missing description",
                "type": "bug_report",
                "priority": "medium"
            }
        )
        assert response.status_code == 422

    @pytest.mark.asyncio
    async def test_create_ticket_invalid_type(
        self,
        authenticated_org_client: AsyncClient
    ):
        """Test creating ticket with invalid type."""
        response = await authenticated_org_client.post(
            "/api/v1/support-tickets/",
            json={
                "title": "Invalid Type",
                "description": "Testing invalid type",
                "type": "invalid_type",
                "priority": "medium"
            }
        )

        assert response.status_code == 422

    @pytest.mark.asyncio
    async def test_create_ticket_invalid_priority(
        self,
        authenticated_org_client: AsyncClient
    ):
        """Test creating ticket with invalid priority."""
        response = await authenticated_org_client.post(
            "/api/v1/support-tickets/",
            json={
                "title": "Invalid Priority",
                "description": "Testing invalid priority",
                "type": "bug_report",
                "priority": "urgent"
            }
        )

        assert response.status_code == 422

    @pytest.mark.asyncio
    async def test_create_ticket_unauthenticated(
        self,
        client: AsyncClient
    ):
        """Test creating ticket without authentication."""
        response = await client.post(
            "/api/v1/support-tickets/",
            json={
                "title": "Unauthenticated",
                "description": "Should fail",
                "type": "bug_report",
                "priority": "low"
            }
        )

        assert response.status_code in [401, 403]


class TestListTickets:
    """Tests for GET /api/v1/support-tickets/"""

    @pytest.mark.asyncio
    async def test_list_tickets_success(
        self,
        authenticated_org_client: AsyncClient,
        test_ticket: SupportTicket,
        resolved_ticket: SupportTicket
    ):
        """Test listing all tickets in organization."""
        response = await authenticated_org_client.get("/api/v1/support-tickets/")

        assert response.status_code == 200
        data = response.json()

        assert isinstance(data, list)
        assert len(data) >= 2

        # Verify tickets are from current organization
        ticket_ids = {str(test_ticket.id), str(resolved_ticket.id)}
        returned_ids = {t["id"] for t in data}
        assert ticket_ids.issubset(returned_ids)

    @pytest.mark.asyncio
    async def test_list_tickets_filter_by_status(
        self,
        authenticated_org_client: AsyncClient,
        test_ticket: SupportTicket,
        resolved_ticket: SupportTicket
    ):
        """Test filtering tickets by status."""
        # Filter for open tickets
        response = await authenticated_org_client.get(
            "/api/v1/support-tickets/?status=open"
        )

        assert response.status_code == 200
        data = response.json()

        # All returned tickets should be open
        for ticket in data:
            assert ticket["status"] == "open"

        # Should include test_ticket
        ticket_ids = [t["id"] for t in data]
        assert str(test_ticket.id) in ticket_ids

        # Filter for resolved tickets
        response = await authenticated_org_client.get(
            "/api/v1/support-tickets/?status=resolved"
        )

        assert response.status_code == 200
        data = response.json()

        for ticket in data:
            assert ticket["status"] == "resolved"

        ticket_ids = [t["id"] for t in data]
        assert str(resolved_ticket.id) in ticket_ids

    @pytest.mark.asyncio
    async def test_list_tickets_filter_by_priority(
        self,
        authenticated_org_client: AsyncClient,
        test_ticket: SupportTicket
    ):
        """Test filtering tickets by priority."""
        response = await authenticated_org_client.get(
            "/api/v1/support-tickets/?priority=high"
        )

        assert response.status_code == 200
        data = response.json()

        for ticket in data:
            assert ticket["priority"] == "high"

    @pytest.mark.asyncio
    async def test_list_tickets_filter_by_type(
        self,
        authenticated_org_client: AsyncClient,
        test_ticket: SupportTicket
    ):
        """Test filtering tickets by type."""
        response = await authenticated_org_client.get(
            "/api/v1/support-tickets/?type=bug_report"
        )

        assert response.status_code == 200
        data = response.json()

        for ticket in data:
            assert ticket["type"] == "bug_report"

    @pytest.mark.asyncio
    async def test_list_tickets_filter_created_by_me(
        self,
        authenticated_org_client: AsyncClient,
        test_ticket: SupportTicket,
        test_user: User
    ):
        """Test filtering tickets created by current user."""
        response = await authenticated_org_client.get(
            "/api/v1/support-tickets/?created_by_me=true"
        )

        assert response.status_code == 200
        data = response.json()

        # All tickets should be created by current user
        for ticket in data:
            assert ticket["created_by"] == str(test_user.id)

    @pytest.mark.asyncio
    async def test_list_tickets_pagination(
        self,
        authenticated_org_client: AsyncClient,
        test_ticket: SupportTicket,
        resolved_ticket: SupportTicket
    ):
        """Test ticket list pagination."""
        # Get first page with limit 1
        response = await authenticated_org_client.get(
            "/api/v1/support-tickets/?limit=1&offset=0"
        )

        assert response.status_code == 200
        data = response.json()
        assert len(data) == 1

        # Get second page
        response = await authenticated_org_client.get(
            "/api/v1/support-tickets/?limit=1&offset=1"
        )

        assert response.status_code == 200
        data = response.json()
        assert len(data) >= 1

    @pytest.mark.asyncio
    async def test_list_tickets_sorting(
        self,
        authenticated_org_client: AsyncClient,
        test_ticket: SupportTicket,
        resolved_ticket: SupportTicket
    ):
        """Test ticket list sorting."""
        # Sort by created_at descending (default)
        response = await authenticated_org_client.get(
            "/api/v1/support-tickets/?sort_by=created_at&sort_order=desc"
        )

        assert response.status_code == 200
        data = response.json()

        if len(data) >= 2:
            # Verify descending order
            for i in range(len(data) - 1):
                assert data[i]["created_at"] >= data[i+1]["created_at"]

        # Sort by priority ascending
        response = await authenticated_org_client.get(
            "/api/v1/support-tickets/?sort_by=priority&sort_order=asc"
        )

        assert response.status_code == 200

    @pytest.mark.asyncio
    async def test_list_tickets_multi_tenant_isolation(
        self,
        authenticated_org_client: AsyncClient,
        test_ticket: SupportTicket,
        second_org_ticket: SupportTicket
    ):
        """Test that users can only see tickets from their organization."""
        response = await authenticated_org_client.get("/api/v1/support-tickets/")

        assert response.status_code == 200
        data = response.json()

        # Should include test_ticket
        ticket_ids = [t["id"] for t in data]
        assert str(test_ticket.id) in ticket_ids

        # Should NOT include second_org_ticket
        assert str(second_org_ticket.id) not in ticket_ids

    @pytest.mark.asyncio
    async def test_list_tickets_unauthenticated(
        self,
        client: AsyncClient
    ):
        """Test listing tickets without authentication."""
        response = await client.get("/api/v1/support-tickets/")

        assert response.status_code in [401, 403]


class TestGetTicket:
    """Tests for GET /api/v1/support-tickets/{ticket_id}"""

    @pytest.mark.asyncio
    async def test_get_ticket_success(
        self,
        authenticated_org_client: AsyncClient,
        test_ticket: SupportTicket
    ):
        """Test getting a ticket by ID."""
        response = await authenticated_org_client.get(
            f"/api/v1/support-tickets/{test_ticket.id}"
        )

        assert response.status_code == 200
        data = response.json()

        assert data["id"] == str(test_ticket.id)
        assert data["title"] == test_ticket.title
        assert data["description"] == test_ticket.description
        assert data["type"] == test_ticket.type
        assert data["priority"] == test_ticket.priority
        assert data["status"] == test_ticket.status

    @pytest.mark.asyncio
    async def test_get_ticket_not_found(
        self,
        authenticated_org_client: AsyncClient
    ):
        """Test getting a non-existent ticket."""
        fake_id = str(uuid.uuid4())
        response = await authenticated_org_client.get(
            f"/api/v1/support-tickets/{fake_id}"
        )

        assert response.status_code == 404

    @pytest.mark.asyncio
    async def test_get_ticket_invalid_uuid(
        self,
        authenticated_org_client: AsyncClient
    ):
        """Test getting ticket with invalid UUID."""
        response = await authenticated_org_client.get(
            "/api/v1/support-tickets/invalid-uuid"
        )

        assert response.status_code == 422

    @pytest.mark.asyncio
    async def test_get_ticket_multi_tenant_isolation(
        self,
        authenticated_org_client: AsyncClient,
        second_org_ticket: SupportTicket
    ):
        """Test that users cannot access tickets from other organizations."""
        response = await authenticated_org_client.get(
            f"/api/v1/support-tickets/{second_org_ticket.id}"
        )

        # Should return 404 to prevent information disclosure
        assert response.status_code == 404

    @pytest.mark.asyncio
    async def test_get_ticket_unauthenticated(
        self,
        client: AsyncClient,
        test_ticket: SupportTicket
    ):
        """Test getting ticket without authentication."""
        response = await client.get(
            f"/api/v1/support-tickets/{test_ticket.id}"
        )

        assert response.status_code in [401, 403]


class TestUpdateTicket:
    """Tests for PATCH /api/v1/support-tickets/{ticket_id}"""

    @pytest.mark.asyncio
    async def test_update_ticket_status(
        self,
        authenticated_org_client: AsyncClient,
        test_ticket: SupportTicket
    ):
        """Test updating ticket status."""
        response = await authenticated_org_client.patch(
            f"/api/v1/support-tickets/{test_ticket.id}",
            json={"status": "in_progress"}
        )

        assert response.status_code == 200
        data = response.json()

        assert data["status"] == "in_progress"
        assert data["id"] == str(test_ticket.id)

    @pytest.mark.asyncio
    async def test_update_ticket_to_resolved(
        self,
        authenticated_org_client: AsyncClient,
        test_ticket: SupportTicket
    ):
        """Test updating ticket to resolved status."""
        response = await authenticated_org_client.patch(
            f"/api/v1/support-tickets/{test_ticket.id}",
            json={
                "status": "resolved",
                "resolution_notes": "Fixed by updating the configuration"
            }
        )

        assert response.status_code == 200
        data = response.json()

        assert data["status"] == "resolved"
        assert data["resolution_notes"] == "Fixed by updating the configuration"
        assert data["resolved_at"] is not None

    @pytest.mark.asyncio
    async def test_update_ticket_priority(
        self,
        authenticated_org_client: AsyncClient,
        test_ticket: SupportTicket
    ):
        """Test updating ticket priority."""
        response = await authenticated_org_client.patch(
            f"/api/v1/support-tickets/{test_ticket.id}",
            json={"priority": "critical"}
        )

        assert response.status_code == 200
        data = response.json()

        assert data["priority"] == "critical"

    @pytest.mark.asyncio
    async def test_update_ticket_assignment(
        self,
        authenticated_org_client: AsyncClient,
        test_ticket: SupportTicket,
        test_user: User
    ):
        """Test assigning ticket to a user."""
        response = await authenticated_org_client.patch(
            f"/api/v1/support-tickets/{test_ticket.id}",
            json={"assigned_to": str(test_user.id)}
        )

        assert response.status_code == 200
        data = response.json()

        assert data["assigned_to"] == str(test_user.id)
        assert data["assignee_name"] == test_user.name
        assert data["assignee_email"] == test_user.email

    @pytest.mark.asyncio
    async def test_update_ticket_multiple_fields(
        self,
        authenticated_org_client: AsyncClient,
        test_ticket: SupportTicket
    ):
        """Test updating multiple fields at once."""
        response = await authenticated_org_client.patch(
            f"/api/v1/support-tickets/{test_ticket.id}",
            json={
                "title": "Updated Title",
                "description": "Updated description",
                "priority": "low",
                "status": "waiting_for_user"
            }
        )

        assert response.status_code == 200
        data = response.json()

        assert data["title"] == "Updated Title"
        assert data["description"] == "Updated description"
        assert data["priority"] == "low"
        assert data["status"] == "waiting_for_user"

    @pytest.mark.asyncio
    async def test_update_ticket_not_found(
        self,
        authenticated_org_client: AsyncClient
    ):
        """Test updating non-existent ticket."""
        fake_id = str(uuid.uuid4())
        response = await authenticated_org_client.patch(
            f"/api/v1/support-tickets/{fake_id}",
            json={"status": "resolved"}
        )

        assert response.status_code == 404

    @pytest.mark.asyncio
    async def test_update_ticket_invalid_status(
        self,
        authenticated_org_client: AsyncClient,
        test_ticket: SupportTicket
    ):
        """Test updating ticket with invalid status."""
        response = await authenticated_org_client.patch(
            f"/api/v1/support-tickets/{test_ticket.id}",
            json={"status": "invalid_status"}
        )

        assert response.status_code == 422

    @pytest.mark.asyncio
    async def test_update_ticket_multi_tenant_isolation(
        self,
        authenticated_org_client: AsyncClient,
        second_org_ticket: SupportTicket
    ):
        """Test that users cannot update tickets from other organizations."""
        response = await authenticated_org_client.patch(
            f"/api/v1/support-tickets/{second_org_ticket.id}",
            json={"status": "resolved"}
        )

        # Should return 404 to prevent information disclosure
        assert response.status_code == 404

    @pytest.mark.asyncio
    async def test_update_ticket_unauthenticated(
        self,
        client: AsyncClient,
        test_ticket: SupportTicket
    ):
        """Test updating ticket without authentication."""
        response = await client.patch(
            f"/api/v1/support-tickets/{test_ticket.id}",
            json={"status": "resolved"}
        )

        assert response.status_code in [401, 403]


class TestDeleteTicket:
    """Tests for DELETE /api/v1/support-tickets/{ticket_id}"""

    @pytest.mark.asyncio
    async def test_delete_ticket_success(
        self,
        authenticated_org_client: AsyncClient,
        test_ticket: SupportTicket,
        test_user: User
    ):
        """Test deleting a ticket by its creator."""
        response = await authenticated_org_client.delete(
            f"/api/v1/support-tickets/{test_ticket.id}"
        )

        assert response.status_code == 200
        data = response.json()
        assert "message" in data

        # Verify ticket is deleted
        get_response = await authenticated_org_client.get(
            f"/api/v1/support-tickets/{test_ticket.id}"
        )
        assert get_response.status_code == 404

    @pytest.mark.asyncio
    async def test_delete_ticket_not_creator(
        self,
        db_session: AsyncSession,
        authenticated_org_client: AsyncClient,
        test_organization: Organization
    ):
        """Test that non-creator cannot delete ticket."""
        # Create a second user in same org
        second_user = User(
            email="seconduser@example.com",
            name="Second User",
            password_hash=native_auth_service.hash_password("password123"),
            is_active=True,
            email_verified=True
        )
        db_session.add(second_user)
        await db_session.commit()
        await db_session.refresh(second_user)

        # Create ticket by second user
        ticket = SupportTicket(
            organization_id=test_organization.id,
            title="Second User Ticket",
            description="Created by second user",
            type="bug_report",
            priority="low",
            status="open",
            created_by=second_user.id
        )
        db_session.add(ticket)
        await db_session.commit()
        await db_session.refresh(ticket)

        # Try to delete with authenticated_client (different user)
        response = await authenticated_org_client.delete(
            f"/api/v1/support-tickets/{ticket.id}"
        )

        # Should be forbidden
        assert response.status_code == 403

    @pytest.mark.asyncio
    async def test_delete_ticket_not_found(
        self,
        authenticated_org_client: AsyncClient
    ):
        """Test deleting non-existent ticket."""
        fake_id = str(uuid.uuid4())
        response = await authenticated_org_client.delete(
            f"/api/v1/support-tickets/{fake_id}"
        )

        assert response.status_code == 404

    @pytest.mark.asyncio
    async def test_delete_ticket_multi_tenant_isolation(
        self,
        authenticated_org_client: AsyncClient,
        second_org_ticket: SupportTicket
    ):
        """Test that users cannot delete tickets from other organizations."""
        response = await authenticated_org_client.delete(
            f"/api/v1/support-tickets/{second_org_ticket.id}"
        )

        # Should return 404 to prevent information disclosure
        assert response.status_code == 404

    @pytest.mark.asyncio
    async def test_delete_ticket_unauthenticated(
        self,
        client: AsyncClient,
        test_ticket: SupportTicket
    ):
        """Test deleting ticket without authentication."""
        response = await client.delete(
            f"/api/v1/support-tickets/{test_ticket.id}"
        )

        assert response.status_code in [401, 403]


class TestTicketComments:
    """Tests for ticket comment endpoints"""

    @pytest.mark.asyncio
    async def test_add_comment_success(
        self,
        authenticated_org_client: AsyncClient,
        test_ticket: SupportTicket
    ):
        """Test adding a comment to a ticket."""
        response = await authenticated_org_client.post(
            f"/api/v1/support-tickets/{test_ticket.id}/comments",
            json={
                "comment": "This is a test comment",
                "is_internal": False
            }
        )

        assert response.status_code == 200
        data = response.json()

        assert data["comment"] == "This is a test comment"
        assert data["is_internal"] is False
        assert data["is_system_message"] is False
        assert data["ticket_id"] == str(test_ticket.id)
        assert "user_name" in data
        assert "user_email" in data

    @pytest.mark.asyncio
    async def test_add_internal_comment(
        self,
        authenticated_org_client: AsyncClient,
        test_ticket: SupportTicket
    ):
        """Test adding an internal comment."""
        response = await authenticated_org_client.post(
            f"/api/v1/support-tickets/{test_ticket.id}/comments",
            json={
                "comment": "Internal note for team only",
                "is_internal": True
            }
        )

        assert response.status_code == 200
        data = response.json()

        assert data["is_internal"] is True

    @pytest.mark.asyncio
    async def test_add_comment_to_nonexistent_ticket(
        self,
        authenticated_org_client: AsyncClient
    ):
        """Test adding comment to non-existent ticket."""
        fake_id = str(uuid.uuid4())
        response = await authenticated_org_client.post(
            f"/api/v1/support-tickets/{fake_id}/comments",
            json={"comment": "Test comment"}
        )

        assert response.status_code == 404

    @pytest.mark.asyncio
    async def test_add_comment_multi_tenant_isolation(
        self,
        authenticated_org_client: AsyncClient,
        second_org_ticket: SupportTicket
    ):
        """Test that users cannot comment on tickets from other organizations."""
        response = await authenticated_org_client.post(
            f"/api/v1/support-tickets/{second_org_ticket.id}/comments",
            json={"comment": "Should fail"}
        )

        assert response.status_code == 404

    @pytest.mark.asyncio
    async def test_list_comments_success(
        self,
        authenticated_org_client: AsyncClient,
        test_ticket: SupportTicket,
        db_session: AsyncSession,
        test_user: User
    ):
        """Test listing comments for a ticket."""
        # Add some comments
        comment1 = TicketComment(
            ticket_id=test_ticket.id,
            user_id=test_user.id,
            comment="First comment",
            is_internal=False
        )
        comment2 = TicketComment(
            ticket_id=test_ticket.id,
            user_id=test_user.id,
            comment="Second comment - internal",
            is_internal=True
        )

        db_session.add(comment1)
        db_session.add(comment2)
        await db_session.commit()

        # Get all comments (excluding internal by default)
        response = await authenticated_org_client.get(
            f"/api/v1/support-tickets/{test_ticket.id}/comments"
        )

        assert response.status_code == 200
        data = response.json()

        assert isinstance(data, list)
        # Should only include public comments
        assert len(data) >= 1
        public_comments = [c for c in data if not c["is_internal"]]
        assert len(public_comments) >= 1

    @pytest.mark.asyncio
    async def test_list_comments_include_internal(
        self,
        authenticated_org_client: AsyncClient,
        test_ticket: SupportTicket,
        db_session: AsyncSession,
        test_user: User
    ):
        """Test listing comments including internal ones."""
        # Add comments
        comment1 = TicketComment(
            ticket_id=test_ticket.id,
            user_id=test_user.id,
            comment="Public comment",
            is_internal=False
        )
        comment2 = TicketComment(
            ticket_id=test_ticket.id,
            user_id=test_user.id,
            comment="Internal comment",
            is_internal=True
        )

        db_session.add(comment1)
        db_session.add(comment2)
        await db_session.commit()

        # Get all comments including internal
        response = await authenticated_org_client.get(
            f"/api/v1/support-tickets/{test_ticket.id}/comments?include_internal=true"
        )

        assert response.status_code == 200
        data = response.json()

        assert len(data) >= 2
        internal_comments = [c for c in data if c["is_internal"]]
        assert len(internal_comments) >= 1

    @pytest.mark.asyncio
    async def test_list_comments_multi_tenant_isolation(
        self,
        authenticated_org_client: AsyncClient,
        second_org_ticket: SupportTicket
    ):
        """Test that users cannot list comments from other organizations."""
        response = await authenticated_org_client.get(
            f"/api/v1/support-tickets/{second_org_ticket.id}/comments"
        )

        assert response.status_code == 404

    @pytest.mark.asyncio
    async def test_add_comment_unauthenticated(
        self,
        client: AsyncClient,
        test_ticket: SupportTicket
    ):
        """Test adding comment without authentication."""
        response = await client.post(
            f"/api/v1/support-tickets/{test_ticket.id}/comments",
            json={"comment": "Test"}
        )

        assert response.status_code in [401, 403]


class TestTicketAttachments:
    """Tests for ticket attachment endpoints"""

    @pytest.mark.asyncio
    async def test_upload_attachment_success(
        self,
        authenticated_org_client: AsyncClient,
        test_ticket: SupportTicket
    ):
        """Test uploading an attachment to a ticket."""
        # Create a temporary file
        with tempfile.NamedTemporaryFile(mode='w', suffix='.txt', delete=False) as f:
            f.write("Test attachment content")
            temp_file_path = f.name

        try:
            # Upload the file
            with open(temp_file_path, 'rb') as f:
                response = await authenticated_org_client.post(
                    f"/api/v1/support-tickets/{test_ticket.id}/attachments",
                    files={"file": ("test.txt", f, "text/plain")}
                )

            assert response.status_code == 200
            data = response.json()

            assert "id" in data
            assert data["file_name"] == "test.txt"
            assert data["file_type"] == "text/plain"
            assert data["file_size"] > 0
            assert "file_url" in data
        finally:
            # Cleanup
            Path(temp_file_path).unlink(missing_ok=True)

    @pytest.mark.asyncio
    async def test_upload_attachment_to_nonexistent_ticket(
        self,
        authenticated_org_client: AsyncClient
    ):
        """Test uploading attachment to non-existent ticket."""
        fake_id = str(uuid.uuid4())

        with tempfile.NamedTemporaryFile(mode='w', suffix='.txt', delete=False) as f:
            f.write("Test")
            temp_file_path = f.name

        try:
            with open(temp_file_path, 'rb') as f:
                response = await authenticated_org_client.post(
                    f"/api/v1/support-tickets/{fake_id}/attachments",
                    files={"file": ("test.txt", f, "text/plain")}
                )

            assert response.status_code == 404
        finally:
            Path(temp_file_path).unlink(missing_ok=True)

    @pytest.mark.asyncio
    async def test_upload_attachment_multi_tenant_isolation(
        self,
        authenticated_org_client: AsyncClient,
        second_org_ticket: SupportTicket
    ):
        """Test that users cannot upload attachments to other organizations' tickets."""
        with tempfile.NamedTemporaryFile(mode='w', suffix='.txt', delete=False) as f:
            f.write("Test")
            temp_file_path = f.name

        try:
            with open(temp_file_path, 'rb') as f:
                response = await authenticated_org_client.post(
                    f"/api/v1/support-tickets/{second_org_ticket.id}/attachments",
                    files={"file": ("test.txt", f, "text/plain")}
                )

            assert response.status_code == 404
        finally:
            Path(temp_file_path).unlink(missing_ok=True)

    @pytest.mark.asyncio
    async def test_download_attachment_success(
        self,
        authenticated_org_client: AsyncClient,
        test_ticket: SupportTicket,
        db_session: AsyncSession,
        test_user: User
    ):
        """Test downloading an attachment."""
        # Create a test file first
        upload_dir = Path("uploads") / "support_tickets" / str(test_ticket.organization_id) / str(test_ticket.id)
        upload_dir.mkdir(parents=True, exist_ok=True)

        test_file_path = upload_dir / "test_download.txt"
        test_file_path.write_text("Test download content")

        try:
            # Create attachment record
            attachment = TicketAttachment(
                ticket_id=test_ticket.id,
                file_name="test_download.txt",
                file_url=str(test_file_path),
                file_type="text/plain",
                file_size=20,
                uploaded_by=test_user.id
            )

            db_session.add(attachment)
            await db_session.commit()
            await db_session.refresh(attachment)

            # Download the file
            response = await authenticated_org_client.get(
                f"/api/v1/support-tickets/{test_ticket.id}/attachments/{attachment.id}"
            )

            assert response.status_code == 200
            assert response.headers["content-type"] == "text/plain; charset=utf-8"
        finally:
            # Cleanup
            test_file_path.unlink(missing_ok=True)

    @pytest.mark.asyncio
    async def test_download_attachment_not_found(
        self,
        authenticated_org_client: AsyncClient,
        test_ticket: SupportTicket
    ):
        """Test downloading non-existent attachment."""
        fake_id = str(uuid.uuid4())
        response = await authenticated_org_client.get(
            f"/api/v1/support-tickets/{test_ticket.id}/attachments/{fake_id}"
        )

        assert response.status_code == 404

    @pytest.mark.asyncio
    async def test_download_attachment_multi_tenant_isolation(
        self,
        authenticated_org_client: AsyncClient,
        second_org_ticket: SupportTicket,
        db_session: AsyncSession,
        second_org_user: User
    ):
        """Test that users cannot download attachments from other organizations."""
        # Create attachment in second org
        upload_dir = Path("uploads") / "support_tickets" / str(second_org_ticket.organization_id) / str(second_org_ticket.id)
        upload_dir.mkdir(parents=True, exist_ok=True)

        test_file_path = upload_dir / "second_org_file.txt"
        test_file_path.write_text("Second org content")

        try:
            attachment = TicketAttachment(
                ticket_id=second_org_ticket.id,
                file_name="second_org_file.txt",
                file_url=str(test_file_path),
                file_type="text/plain",
                file_size=18,
                uploaded_by=second_org_user.id
            )

            db_session.add(attachment)
            await db_session.commit()
            await db_session.refresh(attachment)

            # Try to download with authenticated_client (different org)
            response = await authenticated_org_client.get(
                f"/api/v1/support-tickets/{second_org_ticket.id}/attachments/{attachment.id}"
            )

            # Should be forbidden or not found
            assert response.status_code in [403, 404]
        finally:
            test_file_path.unlink(missing_ok=True)

    @pytest.mark.asyncio
    async def test_upload_attachment_unauthenticated(
        self,
        client: AsyncClient,
        test_ticket: SupportTicket
    ):
        """Test uploading attachment without authentication."""
        with tempfile.NamedTemporaryFile(mode='w', suffix='.txt', delete=False) as f:
            f.write("Test")
            temp_file_path = f.name

        try:
            with open(temp_file_path, 'rb') as f:
                response = await client.post(
                    f"/api/v1/support-tickets/{test_ticket.id}/attachments",
                    files={"file": ("test.txt", f, "text/plain")}
                )

            assert response.status_code in [401, 403]
        finally:
            Path(temp_file_path).unlink(missing_ok=True)
