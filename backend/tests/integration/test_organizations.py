"""
Integration tests for Organization Management API.

Covers TESTING_BACKEND.md section 2.1 - Organization Management

Status: 20/32 passing (7/10 features working, 3 blocked by backend bugs)
See TESTING_BACKEND.md "Backend Code Issues Found During Testing" for fix details.
"""

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession
from models.user import User
from models.organization import Organization
from models.organization_member import OrganizationMember, OrganizationRole


class TestOrganizationCreation:
    """Test organization creation endpoint."""

    @pytest.mark.asyncio
    async def test_create_organization_success(
        self,
        authenticated_client: AsyncClient,
        test_user: User
    ):
        """Test successful organization creation."""
        # Arrange
        org_data = {
            "name": "My New Organization",
            "description": "A test organization",
            "logo_url": "https://example.com/logo.png",
            "settings": {"theme": "dark"}
        }

        # Act
        response = await authenticated_client.post(
            "/api/v1/organizations",
            json=org_data
        )

        # Assert
        assert response.status_code == 201
        data = response.json()
        assert data["name"] == "My New Organization"
        assert data["slug"] == "my-new-organization"
        assert data["description"] == "A test organization"
        assert data["logo_url"] == "https://example.com/logo.png"
        assert data["settings"] == {"theme": "dark"}
        assert data["is_active"] is True
        assert data["created_by"] == str(test_user.id)
        assert data["member_count"] == 1
        assert data["current_user_role"] == "admin"
        assert "id" in data

    @pytest.mark.asyncio
    async def test_create_organization_with_custom_slug(
        self,
        authenticated_client: AsyncClient
    ):
        """Test organization creation with custom slug."""
        # Arrange
        org_data = {
            "name": "Custom Slug Org",
            "slug": "custom-slug"
        }

        # Act
        response = await authenticated_client.post(
            "/api/v1/organizations",
            json=org_data
        )

        # Assert
        assert response.status_code == 201
        assert response.json()["slug"] == "custom-slug"

    @pytest.mark.asyncio
    async def test_create_organization_auto_generates_slug(
        self,
        authenticated_client: AsyncClient
    ):
        """Test that slug is auto-generated from name."""
        # Arrange
        org_data = {
            "name": "Test Org With Spaces & Special!"
        }

        # Act
        response = await authenticated_client.post(
            "/api/v1/organizations",
            json=org_data
        )

        # Assert
        assert response.status_code == 201
        assert response.json()["slug"] == "test-org-with-spaces-special"

    @pytest.mark.asyncio
    async def test_create_organization_duplicate_slug_fails(
        self,
        authenticated_client: AsyncClient,
        test_organization: Organization
    ):
        """Test that duplicate slug is rejected."""
        # Arrange
        org_data = {
            "name": "Duplicate Org",
            "slug": test_organization.slug
        }

        # Act
        response = await authenticated_client.post(
            "/api/v1/organizations",
            json=org_data
        )

        # Assert
        assert response.status_code == 409
        assert "already exists" in response.json()["detail"]

    @pytest.mark.asyncio
    async def test_create_organization_invalid_slug_format(
        self,
        authenticated_client: AsyncClient
    ):
        """Test that invalid slug format is rejected."""
        # Arrange
        org_data = {
            "name": "Invalid Slug Org",
            "slug": "Invalid_Slug!"  # Uppercase and special chars
        }

        # Act
        response = await authenticated_client.post(
            "/api/v1/organizations",
            json=org_data
        )

        # Assert
        assert response.status_code == 422

    @pytest.mark.asyncio
    async def test_create_organization_without_auth_fails(
        self,
        client: AsyncClient
    ):
        """Test that unauthenticated request fails."""
        # Arrange
        org_data = {
            "name": "Unauthorized Org"
        }

        # Act
        response = await client.post(
            "/api/v1/organizations",
            json=org_data
        )

        # Assert
        assert response.status_code == 403

    @pytest.mark.asyncio
    async def test_creator_becomes_admin_and_active_org_updated(
        self,
        authenticated_client: AsyncClient,
        test_user: User,
        db_session: AsyncSession
    ):
        """Test that creator becomes admin and last_active_organization_id is updated."""
        # Act
        response = await authenticated_client.post(
            "/api/v1/organizations",
            json={"name": "New Org"}
        )

        # Assert
        assert response.status_code == 201
        org_id = response.json()["id"]

        # Refresh user from database
        await db_session.refresh(test_user)
        assert str(test_user.last_active_organization_id) == org_id


class TestOrganizationList:
    """Test listing organizations."""

    @pytest.mark.asyncio
    async def test_list_organizations_success(
        self,
        authenticated_client: AsyncClient,
        test_organization: Organization
    ):
        """Test listing user's organizations."""
        # Act
        response = await authenticated_client.get("/api/v1/organizations")

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["total"] == 1
        assert len(data["organizations"]) == 1
        assert data["organizations"][0]["id"] == str(test_organization.id)
        assert data["organizations"][0]["current_user_role"] == "admin"

    @pytest.mark.asyncio
    async def test_list_multiple_organizations(
        self,
        authenticated_client: AsyncClient,
        test_organization: Organization
    ):
        """Test listing multiple organizations."""
        # Arrange - Create second organization
        await authenticated_client.post(
            "/api/v1/organizations",
            json={"name": "Second Org"}
        )

        # Act
        response = await authenticated_client.get("/api/v1/organizations")

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["total"] == 2
        assert len(data["organizations"]) == 2

    @pytest.mark.asyncio
    async def test_list_organizations_excludes_inactive_by_default(
        self,
        authenticated_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test that inactive organizations are excluded by default."""
        # Arrange - Mark organization as inactive
        test_organization.is_active = False
        await db_session.commit()

        # Act
        response = await authenticated_client.get("/api/v1/organizations")

        # Assert
        assert response.status_code == 200
        assert response.json()["total"] == 0

    @pytest.mark.asyncio
    async def test_list_organizations_includes_inactive_when_requested(
        self,
        authenticated_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test that inactive organizations can be included."""
        # Arrange - Mark organization as inactive
        test_organization.is_active = False
        await db_session.commit()

        # Act
        response = await authenticated_client.get(
            "/api/v1/organizations?include_inactive=true"
        )

        # Assert
        assert response.status_code == 200
        assert response.json()["total"] == 1

    @pytest.mark.asyncio
    async def test_list_organizations_without_auth_fails(
        self,
        client: AsyncClient
    ):
        """Test that unauthenticated request fails."""
        # Act
        response = await client.get("/api/v1/organizations")

        # Assert
        assert response.status_code == 403


class TestGetOrganization:
    """Test getting organization details."""

    @pytest.mark.asyncio
    async def test_get_organization_success(
        self,
        authenticated_client: AsyncClient,
        test_organization: Organization
    ):
        """Test getting organization details."""
        # Act
        response = await authenticated_client.get(
            f"/api/v1/organizations/{test_organization.id}"
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["id"] == str(test_organization.id)
        assert data["name"] == test_organization.name
        assert data["slug"] == test_organization.slug
        assert data["current_user_role"] == "admin"
        assert data["member_count"] == 1

    @pytest.mark.asyncio
    async def test_get_organization_not_found(
        self,
        authenticated_client: AsyncClient
    ):
        """Test getting non-existent organization."""
        # Arrange
        fake_uuid = "00000000-0000-0000-0000-000000000000"

        # Act
        response = await authenticated_client.get(
            f"/api/v1/organizations/{fake_uuid}"
        )

        # Assert
        assert response.status_code == 404
        assert "not found" in response.json()["detail"].lower()

    @pytest.mark.asyncio
    async def test_get_organization_not_member(
        self,
        client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test that non-members cannot access organization."""
        # Arrange - Create another user
        from services.auth.native_auth_service import native_auth_service

        other_user = User(
            email="other@example.com",
            password_hash=native_auth_service.hash_password("Password123!"),
            name="Other User",
            auth_provider='native',
            email_verified=True,
            is_active=True
        )
        db_session.add(other_user)
        await db_session.commit()

        other_token = native_auth_service.create_access_token(
            user_id=str(other_user.id),
            email=other_user.email
        )

        # Act
        response = await client.get(
            f"/api/v1/organizations/{test_organization.id}",
            headers={"Authorization": f"Bearer {other_token}"}
        )

        # Assert
        assert response.status_code == 404


class TestUpdateOrganization:
    """Test updating organization details."""

    @pytest.mark.asyncio
    async def test_update_organization_as_admin(
        self,
        authenticated_client: AsyncClient,
        test_organization: Organization
    ):
        """Test updating organization as admin."""
        # Arrange
        update_data = {
            "name": "Updated Organization",
            "description": "Updated description",
            "logo_url": "https://example.com/new-logo.png",
            "settings": {"theme": "light"}
        }

        # Act
        response = await authenticated_client.put(
            f"/api/v1/organizations/{test_organization.id}",
            json=update_data
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["name"] == "Updated Organization"
        assert data["description"] == "Updated description"
        assert data["logo_url"] == "https://example.com/new-logo.png"
        assert data["settings"] == {"theme": "light"}

    @pytest.mark.asyncio
    async def test_update_organization_partial_update(
        self,
        authenticated_client: AsyncClient,
        test_organization: Organization
    ):
        """Test partial organization update."""
        # Arrange
        update_data = {
            "name": "Only Name Updated"
        }

        # Act
        response = await authenticated_client.put(
            f"/api/v1/organizations/{test_organization.id}",
            json=update_data
        )

        # Assert
        assert response.status_code == 200
        assert response.json()["name"] == "Only Name Updated"

    @pytest.mark.asyncio
    async def test_update_organization_as_non_admin_fails(
        self,
        client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test that non-admins cannot update organization."""
        # Arrange - Create member user
        from services.auth.native_auth_service import native_auth_service

        member_user = User(
            email="member@example.com",
            password_hash=native_auth_service.hash_password("Password123!"),
            name="Member User",
            auth_provider='native',
            email_verified=True,
            is_active=True
        )
        db_session.add(member_user)
        await db_session.flush()

        # Add as member (not admin)
        member = OrganizationMember(
            organization_id=test_organization.id,
            user_id=member_user.id,
            role=OrganizationRole.MEMBER.value
        )
        db_session.add(member)
        await db_session.commit()

        member_token = native_auth_service.create_access_token(
            user_id=str(member_user.id),
            email=member_user.email,
            organization_id=str(test_organization.id)
        )

        # Act
        response = await client.put(
            f"/api/v1/organizations/{test_organization.id}",
            json={"name": "Should Fail"},
            headers={"Authorization": f"Bearer {member_token}"}
        )

        # Assert
        assert response.status_code == 403
        assert "admin" in response.json()["detail"].lower()


class TestDeleteOrganization:
    """Test organization deletion."""

    @pytest.mark.asyncio
    async def test_delete_organization_as_admin(
        self,
        authenticated_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test deleting organization as admin."""
        # Act
        response = await authenticated_client.delete(
            f"/api/v1/organizations/{test_organization.id}"
        )

        # Assert
        assert response.status_code == 204

        # Verify organization is deleted
        from sqlalchemy import select
        result = await db_session.execute(
            select(Organization).where(Organization.id == test_organization.id)
        )
        assert result.scalar_one_or_none() is None

    @pytest.mark.asyncio
    async def test_delete_organization_as_non_admin_fails(
        self,
        client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test that non-admins cannot delete organization."""
        # Arrange - Create member user
        from services.auth.native_auth_service import native_auth_service

        member_user = User(
            email="member@example.com",
            password_hash=native_auth_service.hash_password("Password123!"),
            name="Member User",
            auth_provider='native',
            email_verified=True,
            is_active=True
        )
        db_session.add(member_user)
        await db_session.flush()

        member = OrganizationMember(
            organization_id=test_organization.id,
            user_id=member_user.id,
            role=OrganizationRole.MEMBER.value
        )
        db_session.add(member)
        await db_session.commit()

        member_token = native_auth_service.create_access_token(
            user_id=str(member_user.id),
            email=member_user.email,
            organization_id=str(test_organization.id)
        )

        # Act
        response = await client.delete(
            f"/api/v1/organizations/{test_organization.id}",
            headers={"Authorization": f"Bearer {member_token}"}
        )

        # Assert
        assert response.status_code == 403

    @pytest.mark.asyncio
    async def test_delete_organization_updates_user_active_org(
        self,
        authenticated_client: AsyncClient,
        test_organization: Organization,
        test_user: User,
        db_session: AsyncSession
    ):
        """Test that deleting organization updates user's active organization."""
        # Arrange - Create second organization
        response = await authenticated_client.post(
            "/api/v1/organizations",
            json={"name": "Second Org"}
        )
        second_org_id = response.json()["id"]

        # Switch to first organization
        await authenticated_client.post(
            f"/api/v1/organizations/{test_organization.id}/switch"
        )

        # Act - Delete first organization
        await authenticated_client.delete(
            f"/api/v1/organizations/{test_organization.id}"
        )

        # Assert - User's active org should be updated to second org
        await db_session.refresh(test_user)
        assert str(test_user.last_active_organization_id) == second_org_id


class TestSwitchOrganization:
    """Test organization switching."""

    @pytest.mark.asyncio
    async def test_switch_organization_success(
        self,
        authenticated_client: AsyncClient,
        test_organization: Organization,
        test_user: User,
        db_session: AsyncSession
    ):
        """Test switching to another organization."""
        # Arrange - Create second organization
        response = await authenticated_client.post(
            "/api/v1/organizations",
            json={"name": "Second Org"}
        )
        second_org_id = response.json()["id"]

        # Act
        response = await authenticated_client.post(
            f"/api/v1/organizations/{second_org_id}/switch"
        )

        # Assert
        assert response.status_code == 200
        data = response.json()
        assert data["organization_id"] == second_org_id
        assert data["organization_name"] == "Second Org"
        assert data["role"] == "admin"
        assert "Switched to" in data["message"]

        # Verify user's active org is updated
        await db_session.refresh(test_user)
        assert str(test_user.last_active_organization_id) == second_org_id

    @pytest.mark.asyncio
    async def test_switch_to_non_member_organization_fails(
        self,
        authenticated_client: AsyncClient,
        db_session: AsyncSession,
        test_user: User
    ):
        """Test that switching to non-member organization fails."""
        # Arrange - Create organization with different user
        from services.auth.native_auth_service import native_auth_service

        other_user = User(
            email="other@example.com",
            password_hash=native_auth_service.hash_password("Password123!"),
            name="Other User",
            auth_provider='native',
            email_verified=True,
            is_active=True
        )
        db_session.add(other_user)
        await db_session.flush()

        other_org = Organization(
            name="Other Org",
            slug="other-org",
            created_by=other_user.id
        )
        db_session.add(other_org)
        await db_session.commit()

        # Act
        response = await authenticated_client.post(
            f"/api/v1/organizations/{other_org.id}/switch"
        )

        # Assert
        assert response.status_code == 404


class TestListMembers:
    """Test listing organization members."""

    @pytest.mark.asyncio
    async def test_list_members_success(
        self,
        authenticated_client: AsyncClient,
        test_organization: Organization,
        test_user: User
    ):
        """Test listing organization members."""
        # Act
        response = await authenticated_client.get(
            f"/api/v1/organizations/{test_organization.id}/members"
        )

        # Assert
        assert response.status_code == 200
        members = response.json()
        assert len(members) == 1
        assert members[0]["user_id"] == str(test_user.id)
        assert members[0]["email"] == test_user.email
        assert members[0]["role"] == "admin"

    @pytest.mark.asyncio
    async def test_list_members_as_non_member_fails(
        self,
        client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test that non-members cannot list members."""
        # Arrange - Create another user
        from services.auth.native_auth_service import native_auth_service

        other_user = User(
            email="other@example.com",
            password_hash=native_auth_service.hash_password("Password123!"),
            name="Other User",
            auth_provider='native',
            email_verified=True,
            is_active=True
        )
        db_session.add(other_user)
        await db_session.commit()

        other_token = native_auth_service.create_access_token(
            user_id=str(other_user.id),
            email=other_user.email
        )

        # Act
        response = await client.get(
            f"/api/v1/organizations/{test_organization.id}/members",
            headers={"Authorization": f"Bearer {other_token}"}
        )

        # Assert
        assert response.status_code == 404


class TestMemberRoleManagement:
    """Test member role updates."""

    @pytest.mark.asyncio
    async def test_update_member_role_as_admin(
        self,
        authenticated_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test updating member role as admin."""
        # Arrange - Create member user
        from services.auth.native_auth_service import native_auth_service

        member_user = User(
            email="member@example.com",
            password_hash=native_auth_service.hash_password("Password123!"),
            name="Member User",
            auth_provider='native',
            email_verified=True,
            is_active=True
        )
        db_session.add(member_user)
        await db_session.flush()

        member = OrganizationMember(
            organization_id=test_organization.id,
            user_id=member_user.id,
            role=OrganizationRole.MEMBER.value
        )
        db_session.add(member)
        await db_session.commit()

        # Act
        response = await authenticated_client.put(
            f"/api/v1/organizations/{test_organization.id}/members/{member_user.id}",
            json={"role": "viewer"}
        )

        # Assert
        assert response.status_code == 200
        assert response.json()["role"] == "viewer"

    @pytest.mark.asyncio
    async def test_update_own_role_fails(
        self,
        authenticated_client: AsyncClient,
        test_organization: Organization,
        test_user: User
    ):
        """Test that users cannot update their own role."""
        # Act
        response = await authenticated_client.put(
            f"/api/v1/organizations/{test_organization.id}/members/{test_user.id}",
            json={"role": "member"}
        )

        # Assert
        assert response.status_code == 400
        assert "cannot modify your own role" in response.json()["detail"].lower()

    @pytest.mark.asyncio
    async def test_update_role_as_non_admin_fails(
        self,
        client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test that non-admins cannot update roles."""
        # Arrange - Create two member users
        from services.auth.native_auth_service import native_auth_service

        member1 = User(
            email="member1@example.com",
            password_hash=native_auth_service.hash_password("Password123!"),
            name="Member 1",
            auth_provider='native',
            email_verified=True,
            is_active=True
        )
        member2 = User(
            email="member2@example.com",
            password_hash=native_auth_service.hash_password("Password123!"),
            name="Member 2",
            auth_provider='native',
            email_verified=True,
            is_active=True
        )
        db_session.add_all([member1, member2])
        await db_session.flush()

        # Add both as members
        db_session.add_all([
            OrganizationMember(
                organization_id=test_organization.id,
                user_id=member1.id,
                role=OrganizationRole.MEMBER.value
            ),
            OrganizationMember(
                organization_id=test_organization.id,
                user_id=member2.id,
                role=OrganizationRole.MEMBER.value
            )
        ])
        await db_session.commit()

        member1_token = native_auth_service.create_access_token(
            user_id=str(member1.id),
            email=member1.email,
            organization_id=str(test_organization.id)
        )

        # Act - member1 tries to update member2's role
        response = await client.put(
            f"/api/v1/organizations/{test_organization.id}/members/{member2.id}",
            json={"role": "admin"},
            headers={"Authorization": f"Bearer {member1_token}"}
        )

        # Assert
        assert response.status_code == 403


class TestRemoveMember:
    """Test removing organization members."""

    @pytest.mark.asyncio
    async def test_remove_member_as_admin(
        self,
        authenticated_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test removing member as admin."""
        # Arrange - Create member user
        from services.auth.native_auth_service import native_auth_service

        member_user = User(
            email="member@example.com",
            password_hash=native_auth_service.hash_password("Password123!"),
            name="Member User",
            auth_provider='native',
            email_verified=True,
            is_active=True
        )
        db_session.add(member_user)
        await db_session.flush()

        member = OrganizationMember(
            organization_id=test_organization.id,
            user_id=member_user.id,
            role=OrganizationRole.MEMBER.value
        )
        db_session.add(member)
        await db_session.commit()

        # Act
        response = await authenticated_client.delete(
            f"/api/v1/organizations/{test_organization.id}/members/{member_user.id}"
        )

        # Assert
        assert response.status_code == 204

        # Verify member is removed
        from sqlalchemy import select
        result = await db_session.execute(
            select(OrganizationMember).where(
                OrganizationMember.organization_id == test_organization.id,
                OrganizationMember.user_id == member_user.id
            )
        )
        assert result.scalar_one_or_none() is None

    @pytest.mark.asyncio
    async def test_remove_self_fails(
        self,
        authenticated_client: AsyncClient,
        test_organization: Organization,
        test_user: User
    ):
        """Test that users cannot remove themselves."""
        # Act
        response = await authenticated_client.delete(
            f"/api/v1/organizations/{test_organization.id}/members/{test_user.id}"
        )

        # Assert
        assert response.status_code == 400
        assert "cannot remove yourself" in response.json()["detail"].lower()

    @pytest.mark.asyncio
    async def test_remove_creator_fails(
        self,
        authenticated_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test that organization creator cannot be removed."""
        # Arrange - Add another admin who will try to remove creator
        from services.auth.native_auth_service import native_auth_service

        admin_user = User(
            email="admin@example.com",
            password_hash=native_auth_service.hash_password("Password123!"),
            name="Admin User",
            auth_provider='native',
            email_verified=True,
            is_active=True
        )
        db_session.add(admin_user)
        await db_session.flush()

        admin_member = OrganizationMember(
            organization_id=test_organization.id,
            user_id=admin_user.id,
            role=OrganizationRole.ADMIN.value
        )
        db_session.add(admin_member)
        await db_session.commit()

        admin_token = native_auth_service.create_access_token(
            user_id=str(admin_user.id),
            email=admin_user.email,
            organization_id=str(test_organization.id)
        )

        # Act - Try to remove creator
        response = await authenticated_client.delete(
            f"/api/v1/organizations/{test_organization.id}/members/{test_organization.created_by}",
            headers={"Authorization": f"Bearer {admin_token}"}
        )

        # Assert
        assert response.status_code == 400
        assert "creator" in response.json()["detail"].lower()

    @pytest.mark.asyncio
    async def test_remove_member_clears_active_org_if_last(
        self,
        authenticated_client: AsyncClient,
        test_organization: Organization,
        db_session: AsyncSession
    ):
        """Test that removing member clears their active org if it was their last."""
        # Arrange - Create member user
        from services.auth.native_auth_service import native_auth_service

        member_user = User(
            email="member@example.com",
            password_hash=native_auth_service.hash_password("Password123!"),
            name="Member User",
            auth_provider='native',
            email_verified=True,
            is_active=True,
            last_active_organization_id=test_organization.id
        )
        db_session.add(member_user)
        await db_session.flush()

        member = OrganizationMember(
            organization_id=test_organization.id,
            user_id=member_user.id,
            role=OrganizationRole.MEMBER.value
        )
        db_session.add(member)
        await db_session.commit()

        # Act
        await authenticated_client.delete(
            f"/api/v1/organizations/{test_organization.id}/members/{member_user.id}"
        )

        # Assert
        await db_session.refresh(member_user)
        assert member_user.last_active_organization_id is None
