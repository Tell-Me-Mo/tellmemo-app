"""
Integration tests for Invitation Management API.

Covers TESTING_BACKEND.md section 2.2 - Invitations (invitations.py)

Tests cover:
- Send organization invitations (via organizations.py)
- Accept invitations (via invitations.py)
- Delete/revoke invitations (via invitations.py)
- List pending invitations (via organizations.py)
"""

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from models.user import User
from models.organization import Organization
from models.organization_member import OrganizationMember, OrganizationRole
from services.auth.native_auth_service import native_auth_service


@pytest.fixture
async def second_user(db_session: AsyncSession) -> User:
    """Create a second test user for invitation testing."""
    password_hash = native_auth_service.hash_password("SecondUser123!")

    user = User(
        email="seconduser@example.com",
        password_hash=password_hash,
        name="Second User",
        auth_provider='native',
        email_verified=True,
        is_active=True
    )

    db_session.add(user)
    await db_session.commit()
    await db_session.refresh(user)

    return user


@pytest.fixture
async def third_user(db_session: AsyncSession) -> User:
    """Create a third test user for multi-user invitation testing."""
    password_hash = native_auth_service.hash_password("ThirdUser123!")

    user = User(
        email="thirduser@example.com",
        password_hash=password_hash,
        name="Third User",
        auth_provider='native',
        email_verified=True,
        is_active=True
    )

    db_session.add(user)
    await db_session.commit()
    await db_session.refresh(user)

    return user


@pytest.fixture
async def second_user_token(second_user: User) -> str:
    """Create a valid access token for the second user."""
    return native_auth_service.create_access_token(
        user_id=str(second_user.id),
        email=second_user.email,
        organization_id=None
    )


@pytest.fixture
async def third_user_token(third_user: User) -> str:
    """Create a valid access token for the third user."""
    return native_auth_service.create_access_token(
        user_id=str(third_user.id),
        email=third_user.email,
        organization_id=None
    )




class TestSendInvitations:
    """Test sending organization invitations."""

    @pytest.mark.asyncio
    async def test_send_invitation_to_new_email_success(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test successfully sending invitation to a new email address."""
        # Arrange
        invitation_data = {
            "email": "newmember@example.com",
            "role": "member"
        }

        # Act
        response = await authenticated_org_client.post(
            f"/api/v1/organizations/{test_organization.id}/members/invite",
            json=invitation_data
        )

        # Assert
        assert response.status_code == 201
        data = response.json()
        assert data["email"] == "newmember@example.com"
        assert data["role"] == "member"
        assert data["organization_id"] == str(test_organization.id)
        assert "invitation_token" in data
        assert data["invitation_token"] is not None
        assert "invitation_sent_at" in data
        assert "id" in data

        # Verify invitation was created in database
        invitation_query = await db_session.execute(
            select(OrganizationMember).where(
                OrganizationMember.invitation_token == data["invitation_token"]
            )
        )
        invitation = invitation_query.scalar_one_or_none()
        assert invitation is not None
        assert invitation.invitation_email == "newmember@example.com"
        assert invitation.joined_at is None  # Not yet accepted

    @pytest.mark.asyncio
    async def test_send_invitation_to_existing_user(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        second_user: User,
        db_session: AsyncSession
    ):
        """Test sending invitation to an existing user in the system."""
        # Arrange
        invitation_data = {
            "email": second_user.email,
            "role": "admin"
        }

        # Act
        response = await authenticated_org_client.post(
            f"/api/v1/organizations/{test_organization.id}/members/invite",
            json=invitation_data
        )

        # Assert
        assert response.status_code == 201
        data = response.json()
        assert data["email"] == second_user.email
        assert data["role"] == "admin"

        # Verify invitation links to existing user
        invitation_query = await db_session.execute(
            select(OrganizationMember).where(
                OrganizationMember.invitation_token == data["invitation_token"]
            )
        )
        invitation = invitation_query.scalar_one_or_none()
        assert invitation is not None
        assert invitation.user_id == second_user.id

    @pytest.mark.asyncio
    async def test_send_invitation_default_member_role(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization
    ):
        """Test that invitation defaults to member role when not specified."""
        # Arrange
        invitation_data = {
            "email": "defaultrole@example.com"
        }

        # Act
        response = await authenticated_org_client.post(
            f"/api/v1/organizations/{test_organization.id}/members/invite",
            json=invitation_data
        )

        # Assert
        assert response.status_code == 201
        assert response.json()["role"] == "member"

    @pytest.mark.asyncio
    async def test_send_invitation_duplicate_email_fails(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization
    ):
        """Test that sending invitation to same email twice fails."""
        # Arrange
        invitation_data = {
            "email": "duplicate@example.com",
            "role": "member"
        }

        # Act - Send first invitation
        response1 = await authenticated_org_client.post(
            f"/api/v1/organizations/{test_organization.id}/members/invite",
            json=invitation_data
        )
        assert response1.status_code == 201

        # Act - Try to send second invitation
        response2 = await authenticated_org_client.post(
            f"/api/v1/organizations/{test_organization.id}/members/invite",
            json=invitation_data
        )

        # Assert
        assert response2.status_code == 400
        assert "already been sent" in response2.json()["detail"]

    @pytest.mark.asyncio
    async def test_send_invitation_to_existing_member_fails(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        test_user: User
    ):
        """Test that inviting an existing member fails."""
        # Arrange - test_user is already a member via test_organization fixture
        invitation_data = {
            "email": test_user.email,
            "role": "member"
        }

        # Act
        response = await authenticated_org_client.post(
            f"/api/v1/organizations/{test_organization.id}/members/invite",
            json=invitation_data
        )

        # Assert
        assert response.status_code == 400
        assert "already a member" in response.json()["detail"]

    @pytest.mark.asyncio
    async def test_send_invitation_without_auth_fails(
        self,
        client: AsyncClient,
        test_organization: Organization
    ):
        """Test that unauthenticated users cannot send invitations."""
        # Arrange
        invitation_data = {
            "email": "unauthorized@example.com",
            "role": "member"
        }

        # Act
        response = await client.post(
            f"/api/v1/organizations/{test_organization.id}/members/invite",
            json=invitation_data
        )

        # Assert
        assert response.status_code in [401, 403]

    @pytest.mark.asyncio
    async def test_send_invitation_to_nonexistent_org_fails(
        self,
        authenticated_client: AsyncClient
    ):
        """Test that sending invitation to non-existent organization fails."""
        # Arrange
        fake_org_id = "00000000-0000-0000-0000-000000000000"
        invitation_data = {
            "email": "test@example.com",
            "role": "member"
        }

        # Act
        response = await authenticated_client.post(
            f"/api/v1/organizations/{fake_org_id}/members/invite",
            json=invitation_data
        )

        # Assert
        assert response.status_code in [403, 404]


class TestListInvitations:
    """Test listing pending invitations."""

    @pytest.mark.asyncio
    async def test_list_pending_invitations_success(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization
    ):
        """Test successfully listing pending invitations."""
        # Arrange - Create some invitations
        emails = ["invite1@example.com", "invite2@example.com", "invite3@example.com"]
        for email in emails:
            await authenticated_org_client.post(
                f"/api/v1/organizations/{test_organization.id}/members/invite",
                json={"email": email, "role": "member"}
            )

        # Act
        response = await authenticated_org_client.get(
            f"/api/v1/organizations/{test_organization.id}/invitations"
        )

        # Assert
        assert response.status_code == 200
        invitations = response.json()
        assert len(invitations) == 3
        invitation_emails = [inv["email"] for inv in invitations]
        assert all(email in invitation_emails for email in emails)

        # Verify all have tokens
        assert all("invitation_token" in inv for inv in invitations)

    @pytest.mark.asyncio
    async def test_list_invitations_empty_list(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization
    ):
        """Test listing invitations when there are none."""
        # Act
        response = await authenticated_org_client.get(
            f"/api/v1/organizations/{test_organization.id}/invitations"
        )

        # Assert
        assert response.status_code == 200
        assert response.json() == []

    @pytest.mark.asyncio
    async def test_list_invitations_without_auth_fails(
        self,
        client: AsyncClient,
        test_organization: Organization
    ):
        """Test that unauthenticated users cannot list invitations."""
        # Act
        response = await client.get(
            f"/api/v1/organizations/{test_organization.id}/invitations"
        )

        # Assert
        assert response.status_code in [401, 403]


class TestAcceptInvitations:
    """Test accepting organization invitations."""

    @pytest.mark.asyncio
    async def test_accept_invitation_success(
        self,
        authenticated_org_client: AsyncClient,
        client_factory,
        test_organization: Organization,
        second_user: User,
        second_user_token: str,
        db_session: AsyncSession
    ):
        """Test successfully accepting an invitation."""
        # Arrange - Create invitation for second_user using admin client
        invite_response = await authenticated_org_client.post(
            f"/api/v1/organizations/{test_organization.id}/members/invite",
            json={"email": second_user.email, "role": "member"}
        )
        assert invite_response.status_code == 201
        invitation_token = invite_response.json()["invitation_token"]

        # Act - Create a separate client for second user to accept invitation
        second_user_client = await client_factory(Authorization=f"Bearer {second_user_token}")

        response = await second_user_client.post(
            "/api/v1/invitations/accept",
            json={"token": invitation_token}
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["organization_id"] == str(test_organization.id)
        assert data["organization_name"] == test_organization.name
        assert data["role"] == "member"
        assert "Successfully joined" in data["message"]

        # Verify invitation was accepted in database
        member_query = await db_session.execute(
            select(OrganizationMember).where(
                OrganizationMember.organization_id == test_organization.id,
                OrganizationMember.user_id == second_user.id
            )
        )
        member = member_query.scalar_one_or_none()
        assert member is not None
        assert member.joined_at is not None
        assert member.invitation_token is None  # Token cleared after acceptance

    @pytest.mark.asyncio
    async def test_accept_invitation_sets_last_active_org(
        self,
        authenticated_org_client: AsyncClient,
        client_factory,
        test_organization: Organization,
        second_user: User,
        second_user_token: str,
        db_session: AsyncSession
    ):
        """Test that accepting invitation sets user's last active organization."""
        # Arrange - Create invitation using admin client
        invite_response = await authenticated_org_client.post(
            f"/api/v1/organizations/{test_organization.id}/members/invite",
            json={"email": second_user.email, "role": "member"}
        )
        assert invite_response.status_code == 201
        invitation_token = invite_response.json()["invitation_token"]

        # Verify user doesn't have last_active_organization_id
        assert second_user.last_active_organization_id is None

        # Act - Create a separate client for second user to accept invitation
        second_user_client = await client_factory(Authorization=f"Bearer {second_user_token}")

        response = await second_user_client.post(
            "/api/v1/invitations/accept",
            json={"token": invitation_token}
        )

        # Assert
        assert response.status_code == 200

        # Refresh user from database
        await db_session.refresh(second_user)
        assert second_user.last_active_organization_id == test_organization.id

    @pytest.mark.asyncio
    async def test_accept_invitation_invalid_token_fails(
        self,
        client_factory,
        second_user_token: str
    ):
        """Test accepting invitation with invalid token fails."""
        # Arrange - Create client for second user
        second_user_client = await client_factory(Authorization=f"Bearer {second_user_token}")

        # Act
        response = await second_user_client.post(
            "/api/v1/invitations/accept",
            json={"token": "invalid-token-12345"}
        )

        # Assert
        assert response.status_code == 404
        assert "Invalid or expired" in response.json()["detail"]

    @pytest.mark.asyncio
    async def test_accept_invitation_wrong_user_fails(
        self,
        authenticated_org_client: AsyncClient,
        client_factory,
        test_organization: Organization,
        second_user: User,
        third_user_token: str,
        db_session: AsyncSession
    ):
        """Test that user cannot accept invitation meant for someone else."""
        # Arrange - Create invitation for second_user using admin client
        invite_response = await authenticated_org_client.post(
            f"/api/v1/organizations/{test_organization.id}/members/invite",
            json={"email": second_user.email, "role": "member"}
        )
        assert invite_response.status_code == 201
        invitation_token = invite_response.json()["invitation_token"]

        # Act - Create a separate client for third user to try accepting second user's invitation
        third_user_client = await client_factory(Authorization=f"Bearer {third_user_token}")

        response = await third_user_client.post(
            "/api/v1/invitations/accept",
            json={"token": invitation_token}
        )

        # Assert
        assert response.status_code == 403
        assert "different user" in response.json()["detail"]

    @pytest.mark.asyncio
    async def test_accept_invitation_already_member_fails(
        self,
        authenticated_org_client: AsyncClient,
        client_factory,
        test_organization: Organization,
        second_user: User,
        second_user_token: str,
        db_session: AsyncSession
    ):
        """Test that user cannot accept invitation if already a member."""
        # Arrange - Create invitation using admin client
        invite_response = await authenticated_org_client.post(
            f"/api/v1/organizations/{test_organization.id}/members/invite",
            json={"email": second_user.email, "role": "member"}
        )
        assert invite_response.status_code == 201
        invitation_token = invite_response.json()["invitation_token"]

        # Accept invitation first time with second user client
        second_user_client = await client_factory(Authorization=f"Bearer {second_user_token}")

        first_response = await second_user_client.post(
            "/api/v1/invitations/accept",
            json={"token": invitation_token}
        )

        assert first_response.status_code == 200

        # Act - Try to send another invitation (should fail because user is already a member)
        second_invite_response = await authenticated_org_client.post(
            f"/api/v1/organizations/{test_organization.id}/members/invite",
            json={"email": second_user.email, "role": "member"}
        )

        # Assert - Can't invite someone who's already a member
        assert second_invite_response.status_code == 400
        assert "already a member" in second_invite_response.json()["detail"]

    @pytest.mark.asyncio
    async def test_accept_invitation_without_auth_fails(
        self,
        client: AsyncClient
    ):
        """Test that unauthenticated users cannot accept invitations."""
        # Act
        response = await client.post(
            "/api/v1/invitations/accept",
            json={"token": "some-token"}
        )

        # Assert
        assert response.status_code in [401, 403]


class TestRevokeInvitations:
    """Test deleting/revoking organization invitations."""

    @pytest.mark.asyncio
    async def test_revoke_invitation_by_admin_success(
        self,
        authenticated_org_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test admin can successfully revoke an invitation."""
        # Arrange - Create invitation
        invite_response = await authenticated_org_client.post(
            f"/api/v1/organizations/{test_organization.id}/members/invite",
            json={"email": "revoke@example.com", "role": "member"}
        )
        assert invite_response.status_code == 201
        invitation_token = invite_response.json()["invitation_token"]

        # Act - Revoke invitation
        response = await authenticated_org_client.delete(
            f"/api/v1/invitations/{invitation_token}"
        )

        # Assert
        assert response.status_code == 200
        assert "cancelled" in response.json()["message"]

        # Verify invitation was deleted from database
        invitation_query = await db_session.execute(
            select(OrganizationMember).where(
                OrganizationMember.invitation_token == invitation_token
            )
        )
        invitation = invitation_query.scalar_one_or_none()
        assert invitation is None

    @pytest.mark.asyncio
    async def test_revoke_invitation_by_inviter_success(
        self,
        client: AsyncClient,
        test_organization: Organization,
        second_user: User,
        db_session: AsyncSession
    ):
        """Test that the user who sent invitation can revoke it."""
        # Arrange - Add second_user as member (not admin)
        member = OrganizationMember(
            organization_id=test_organization.id,
            user_id=second_user.id,
            role=OrganizationRole.MEMBER.value,
            invited_by=second_user.id
        )
        db_session.add(member)
        await db_session.commit()

        # Create invitation sent by second_user
        second_user_token = native_auth_service.create_access_token(
            user_id=str(second_user.id),
            email=second_user.email,
            organization_id=str(test_organization.id)
        )

        member_client = AsyncClient(
            transport=client._transport,
            base_url=client.base_url
        )
        member_client.headers["Authorization"] = f"Bearer {second_user_token}"
        member_client.headers["X-Organization-Id"] = str(test_organization.id)

        invite_response = await member_client.post(
            f"/api/v1/organizations/{test_organization.id}/members/invite",
            json={"email": "inviterrevoke@example.com", "role": "member"}
        )
        assert invite_response.status_code == 201
        invitation_token = invite_response.json()["invitation_token"]

        # Act - Second user revokes their own invitation
        response = await member_client.delete(
            f"/api/v1/invitations/{invitation_token}"
        )
        await member_client.aclose()

        # Assert
        assert response.status_code == 200
        assert "cancelled" in response.json()["message"]

    @pytest.mark.asyncio
    async def test_revoke_invitation_invalid_token_fails(
        self,
        authenticated_org_client: AsyncClient
    ):
        """Test revoking non-existent invitation fails."""
        # Act
        response = await authenticated_org_client.delete(
            "/api/v1/invitations/invalid-token-xyz"
        )

        # Assert
        assert response.status_code == 404
        assert "Invalid or already accepted" in response.json()["detail"]

    @pytest.mark.asyncio
    async def test_revoke_invitation_unauthorized_user_fails(
        self,
        client: AsyncClient,
        test_organization: Organization,
        second_user: User,
        third_user: User,
        db_session: AsyncSession
    ):
        """Test that unauthorized user cannot revoke invitation."""
        # Arrange - Admin creates invitation
        admin = await db_session.execute(
            select(User).where(User.email == "test@example.com")
        )
        admin_user = admin.scalar_one()
        admin_token = native_auth_service.create_access_token(
            user_id=str(admin_user.id),
            email=admin_user.email,
            organization_id=str(test_organization.id)
        )

        admin_client = AsyncClient(
            transport=client._transport,
            base_url=client.base_url
        )
        admin_client.headers["Authorization"] = f"Bearer {admin_token}"
        admin_client.headers["X-Organization-Id"] = str(test_organization.id)

        invite_response = await admin_client.post(
            f"/api/v1/organizations/{test_organization.id}/members/invite",
            json={"email": "unauthorized@example.com", "role": "member"}
        )
        await admin_client.aclose()
        invitation_token = invite_response.json()["invitation_token"]

        # Act - Third user (not a member, not inviter) tries to revoke
        third_user_token = native_auth_service.create_access_token(
            user_id=str(third_user.id),
            email=third_user.email,
            organization_id=None
        )

        unauth_client = AsyncClient(
            transport=client._transport,
            base_url=client.base_url
        )
        unauth_client.headers["Authorization"] = f"Bearer {third_user_token}"

        response = await unauth_client.delete(
            f"/api/v1/invitations/{invitation_token}"
        )
        await unauth_client.aclose()

        # Assert
        assert response.status_code == 403
        assert "permission" in response.json()["detail"]

    @pytest.mark.asyncio
    async def test_revoke_invitation_without_auth_fails(
        self,
        client: AsyncClient
    ):
        """Test that unauthenticated users cannot revoke invitations."""
        # Act
        response = await client.delete(
            "/api/v1/invitations/some-token"
        )

        # Assert
        assert response.status_code in [401, 403]

    @pytest.mark.asyncio
    async def test_revoke_accepted_invitation_fails(
        self,
        authenticated_org_client: AsyncClient,
        client_factory,
        test_organization: Organization,
        second_user: User,
        second_user_token: str,
        db_session: AsyncSession
    ):
        """Test that accepted invitations cannot be revoked."""
        # Arrange - Create invitation using admin client
        invite_response = await authenticated_org_client.post(
            f"/api/v1/organizations/{test_organization.id}/members/invite",
            json={"email": second_user.email, "role": "member"}
        )
        assert invite_response.status_code == 201
        invitation_token = invite_response.json()["invitation_token"]

        # Accept invitation with second user using a separate client
        second_user_client = await client_factory(Authorization=f"Bearer {second_user_token}")

        accept_response = await second_user_client.post(
            "/api/v1/invitations/accept",
            json={"token": invitation_token}
        )

        assert accept_response.status_code == 200

        # Act - Try to revoke accepted invitation with admin client
        response = await authenticated_org_client.delete(
            f"/api/v1/invitations/{invitation_token}"
        )

        # Assert - Should fail because token is cleared after acceptance
        assert response.status_code == 404
        assert "Invalid or already accepted" in response.json()["detail"]
