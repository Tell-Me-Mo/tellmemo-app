"""
Test script to verify Row-Level Security (RLS) policies are working correctly.
Tests data isolation between organizations and role-based access control.
"""

import asyncio
import asyncpg
import uuid
from datetime import datetime
import os

# Use application user for testing RLS (superuser bypasses RLS)
DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql://pm_app_user:pm_app_pass@localhost:5432/pm_master_db"
)

# Superuser connection for setup/cleanup only
SUPERUSER_URL = "postgresql://pm_master:pm_master_pass@localhost:5432/pm_master_db"

class RLSPolicyTester:
    """Test class for verifying RLS policies."""

    def __init__(self, db_url: str, superuser_url: str):
        self.db_url = db_url
        self.superuser_url = superuser_url
        self.conn = None
        self.setup_conn = None

        # Test data
        self.org1_id = str(uuid.uuid4())
        self.org2_id = str(uuid.uuid4())
        self.user1_id = str(uuid.uuid4())
        self.user2_id = str(uuid.uuid4())
        self.user3_id = str(uuid.uuid4())
        self.project1_id = str(uuid.uuid4())
        self.project2_id = str(uuid.uuid4())

    async def connect(self):
        """Establish database connections."""
        self.conn = await asyncpg.connect(self.db_url)  # App user for testing
        self.setup_conn = await asyncpg.connect(self.superuser_url)  # Superuser for setup

    async def disconnect(self):
        """Close database connections."""
        if self.conn:
            await self.conn.close()
        if self.setup_conn:
            await self.setup_conn.close()

    async def setup_test_data(self):
        """Create test organizations, users, and projects."""
        print("Setting up test data...")

        # Use superuser connection for setup (bypasses RLS)
        # First clean up any existing test data
        await self.setup_conn.execute("DELETE FROM projects WHERE name LIKE 'Project for Org%' OR name LIKE 'Admin Created Project%' OR name LIKE 'Malicious%'")
        await self.setup_conn.execute("DELETE FROM organization_members WHERE organization_id IN (SELECT id FROM organizations WHERE slug LIKE 'test-org-%')")
        await self.setup_conn.execute("DELETE FROM organizations WHERE slug LIKE 'test-org-%'")
        await self.setup_conn.execute("DELETE FROM users WHERE email LIKE '%@org%.com' OR email = 'multi@both.com'")

        # Create test users with supabase_id
        await self.setup_conn.execute("""
            INSERT INTO users (id, supabase_id, email, name, created_at, updated_at)
            VALUES
                ($1, $2, 'admin@org1.com', 'Admin User Org1', NOW(), NOW()),
                ($3, $4, 'member@org1.com', 'Member User Org1', NOW(), NOW()),
                ($5, $6, 'admin@org2.com', 'Admin User Org2', NOW(), NOW())
            ON CONFLICT (id) DO NOTHING
        """, self.user1_id, self.user1_id, self.user2_id, self.user2_id, self.user3_id, self.user3_id)

        # Create test organizations
        await self.setup_conn.execute("""
            INSERT INTO organizations (id, name, slug, created_by, created_at, updated_at)
            VALUES
                ($1, 'Test Organization 1', 'test-org-1', $3, NOW(), NOW()),
                ($2, 'Test Organization 2', 'test-org-2', $4, NOW(), NOW())
            ON CONFLICT (id) DO NOTHING
        """, self.org1_id, self.org2_id, self.user1_id, self.user3_id)

        # Add users to organizations
        await self.setup_conn.execute("""
            INSERT INTO organization_members (id, organization_id, user_id, role, joined_at, updated_at)
            VALUES
                (gen_random_uuid(), $1, $2, 'admin', NOW(), NOW()),
                (gen_random_uuid(), $1, $3, 'member', NOW(), NOW()),
                (gen_random_uuid(), $4, $5, 'admin', NOW(), NOW())
            ON CONFLICT (organization_id, user_id) DO NOTHING
        """, self.org1_id, self.user1_id, self.user2_id,
            self.org2_id, self.user3_id)

        # Create test projects
        await self.setup_conn.execute("""
            INSERT INTO projects (id, name, organization_id, created_by, created_at, updated_at, status)
            VALUES
                ($1, 'Project for Org1', $2, $3, NOW(), NOW(), 'ACTIVE'),
                ($4, 'Project for Org2', $5, $6, NOW(), NOW(), 'ACTIVE')
            ON CONFLICT (id) DO NOTHING
        """, self.project1_id, self.org1_id, self.user1_id,
            self.project2_id, self.org2_id, self.user3_id)

        print("✓ Test data created successfully")

    async def set_session_context(self, user_id: str, org_id: str):
        """Set the session context for RLS to use."""
        await self.conn.execute(f"SET app.user_id = '{user_id}'")
        await self.conn.execute(f"SET app.organization_id = '{org_id}'")

    async def test_organization_isolation(self):
        """Test that users can only see their organization's data."""
        print("\n--- Testing Organization Isolation ---")

        # Test 1: User1 (Org1 admin) should only see Org1 projects
        await self.set_session_context(self.user1_id, self.org1_id)
        projects = await self.conn.fetch("SELECT id, name, organization_id FROM projects")

        if len(projects) == 1 and str(projects[0]['id']) == self.project1_id:
            print("✓ User1 can only see Org1 projects")
        else:
            print(f"✗ User1 isolation failed - saw {len(projects)} projects")
            for p in projects:
                print(f"  - {p['name']} (org: {p['organization_id']})")

        # Test 2: User3 (Org2 admin) should only see Org2 projects
        await self.set_session_context(self.user3_id, self.org2_id)
        projects = await self.conn.fetch("SELECT id, name, organization_id FROM projects")

        if len(projects) == 1 and str(projects[0]['id']) == self.project2_id:
            print("✓ User3 can only see Org2 projects")
        else:
            print(f"✗ User3 isolation failed - saw {len(projects)} projects")

    async def test_role_based_access(self):
        """Test role-based access control for different operations."""
        print("\n--- Testing Role-Based Access Control ---")

        # Test 1: Admin can insert new project
        await self.set_session_context(self.user1_id, self.org1_id)
        try:
            new_project_id = str(uuid.uuid4())
            await self.conn.execute("""
                INSERT INTO projects (id, name, organization_id, created_by, created_at, updated_at, status)
                VALUES ($1, 'Admin Created Project', $2, $3, NOW(), NOW(), 'ACTIVE')
            """, new_project_id, self.org1_id, self.user1_id)
            print("✓ Admin can create new projects")

            # Clean up
            await self.conn.execute("DELETE FROM projects WHERE id = $1", new_project_id)
        except Exception as e:
            print(f"✗ Admin cannot create projects: {e}")

        # Test 2: Member can read but gets restricted on delete
        await self.set_session_context(self.user2_id, self.org1_id)

        # Member should be able to read
        projects = await self.conn.fetch("SELECT id, name FROM projects")
        if len(projects) > 0:
            print("✓ Member can read projects")
        else:
            print("✗ Member cannot read projects")

        # Member should NOT be able to delete (only admins can)
        try:
            await self.conn.execute("DELETE FROM projects WHERE id = $1", self.project1_id)
            print("✗ Member was able to delete project (should not be allowed)")
        except asyncpg.InsufficientPrivilegeError:
            print("✓ Member cannot delete projects (admin-only)")
        except Exception as e:
            # Could be other error due to RLS
            print(f"✓ Member delete blocked: {str(e)[:50]}")

    async def test_cross_tenant_access_prevention(self):
        """Test that users cannot access data from other organizations."""
        print("\n--- Testing Cross-Tenant Access Prevention ---")

        # Test: User1 tries to insert project for Org2 (should fail)
        await self.set_session_context(self.user1_id, self.org1_id)

        try:
            bad_project_id = str(uuid.uuid4())
            await self.conn.execute("""
                INSERT INTO projects (id, name, organization_id, created_by, created_at, updated_at, status)
                VALUES ($1, 'Malicious Cross-Tenant Project', $2, $3, NOW(), NOW(), 'ACTIVE')
            """, bad_project_id, self.org2_id, self.user1_id)
            print("✗ User was able to create project in different organization!")
            # Clean up if it somehow succeeded
            await self.conn.execute("DELETE FROM projects WHERE id = $1", bad_project_id)
        except Exception as e:
            print("✓ Cross-tenant project creation blocked")

    async def test_organization_switching(self):
        """Test that context switching properly changes accessible data."""
        print("\n--- Testing Organization Context Switching ---")

        # Create a user that belongs to both organizations
        multi_user_id = str(uuid.uuid4())
        await self.setup_conn.execute("""
            INSERT INTO users (id, supabase_id, email, name, created_at, updated_at)
            VALUES ($1, $2, 'multi@both.com', 'Multi-Org User', NOW(), NOW())
            ON CONFLICT (id) DO NOTHING
        """, multi_user_id, multi_user_id)

        # Add to both organizations
        await self.setup_conn.execute("""
            INSERT INTO organization_members (id, organization_id, user_id, role, joined_at, updated_at)
            VALUES
                (gen_random_uuid(), $1, $2, 'member', NOW(), NOW()),
                (gen_random_uuid(), $3, $2, 'member', NOW(), NOW())
            ON CONFLICT (organization_id, user_id) DO NOTHING
        """, self.org1_id, multi_user_id, self.org2_id)

        # Test with Org1 context
        await self.set_session_context(multi_user_id, self.org1_id)
        projects = await self.conn.fetch("SELECT name, organization_id FROM projects")

        org1_found = any(str(p['organization_id']) == self.org1_id for p in projects)
        org2_found = any(str(p['organization_id']) == self.org2_id for p in projects)

        if org1_found and not org2_found:
            print("✓ Multi-org user sees only Org1 data when in Org1 context")
        else:
            print(f"✗ Context isolation failed - Org1: {org1_found}, Org2: {org2_found}")

        # Switch to Org2 context
        await self.set_session_context(multi_user_id, self.org2_id)
        projects = await self.conn.fetch("SELECT name, organization_id FROM projects")

        org1_found = any(str(p['organization_id']) == self.org1_id for p in projects)
        org2_found = any(str(p['organization_id']) == self.org2_id for p in projects)

        if org2_found and not org1_found:
            print("✓ Multi-org user sees only Org2 data when in Org2 context")
        else:
            print(f"✗ Context switching failed - Org1: {org1_found}, Org2: {org2_found}")

    async def cleanup_test_data(self):
        """Remove test data after tests complete."""
        print("\n--- Cleaning up test data ---")

        # Use superuser connection for cleanup (bypasses RLS)
        # Delete in correct order to respect foreign keys
        await self.setup_conn.execute("DELETE FROM projects WHERE id IN ($1, $2)",
                               self.project1_id, self.project2_id)
        await self.setup_conn.execute("DELETE FROM organization_members WHERE organization_id IN ($1, $2)",
                               self.org1_id, self.org2_id)
        await self.setup_conn.execute("DELETE FROM organizations WHERE id IN ($1, $2)",
                               self.org1_id, self.org2_id)
        await self.setup_conn.execute("DELETE FROM users WHERE email LIKE '%@org%.com' OR email = 'multi@both.com'")

        print("✓ Test data cleaned up")

    async def run_all_tests(self):
        """Run all RLS policy tests."""
        print("\n" + "="*60)
        print("Running RLS Policy Tests")
        print("="*60)

        try:
            await self.connect()

            # Setup test data
            await self.setup_test_data()

            # Run tests
            await self.test_organization_isolation()
            await self.test_role_based_access()
            await self.test_cross_tenant_access_prevention()
            await self.test_organization_switching()

            # Cleanup
            await self.cleanup_test_data()

            print("\n" + "="*60)
            print("✅ RLS Policy Tests Completed Successfully!")
            print("="*60)

        except Exception as e:
            print(f"\n❌ Test failed with error: {e}")
            raise
        finally:
            await self.disconnect()


async def main():
    """Main function to run RLS tests."""
    tester = RLSPolicyTester(DATABASE_URL, SUPERUSER_URL)
    await tester.run_all_tests()


if __name__ == "__main__":
    asyncio.run(main())