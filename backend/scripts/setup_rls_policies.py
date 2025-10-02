"""
Script to set up Row-Level Security (RLS) policies for multi-tenant architecture.
This script enables RLS on all tenant-specific tables and creates appropriate policies.
"""

import asyncio
import os
from typing import List, Dict, Any
import asyncpg
from datetime import datetime

# Database connection settings
DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql://pm_master:pm_master_pass@localhost:5432/pm_master_db"
)

class RLSPolicyManager:
    """Manager for creating and managing PostgreSQL Row-Level Security policies."""

    def __init__(self, db_url: str):
        self.db_url = db_url
        self.conn = None

    async def connect(self):
        """Establish database connection."""
        self.conn = await asyncpg.connect(self.db_url)

    async def disconnect(self):
        """Close database connection."""
        if self.conn:
            await self.conn.close()

    async def execute(self, query: str) -> None:
        """Execute a single query."""
        try:
            await self.conn.execute(query)
            print(f"✓ Executed: {query[:100]}...")
        except Exception as e:
            print(f"✗ Failed: {query[:100]}...")
            print(f"  Error: {e}")
            raise

    async def create_session_variables_function(self):
        """Create function to safely get session variables."""
        query = """
        -- Create a function to safely get current organization_id from session
        CREATE OR REPLACE FUNCTION current_org_id()
        RETURNS UUID AS $$
        BEGIN
            -- Try to get organization_id from session variable
            -- This will be set by the application when a user authenticates
            RETURN current_setting('app.organization_id', true)::UUID;
        EXCEPTION
            WHEN OTHERS THEN
                RETURN NULL;
        END;
        $$ LANGUAGE plpgsql SECURITY DEFINER;

        -- Create a function to safely get current user_id from session
        CREATE OR REPLACE FUNCTION current_user_id()
        RETURNS UUID AS $$
        BEGIN
            -- Try to get user_id from session variable
            RETURN current_setting('app.user_id', true)::UUID;
        EXCEPTION
            WHEN OTHERS THEN
                RETURN NULL;
        END;
        $$ LANGUAGE plpgsql SECURITY DEFINER;

        -- Create a function to check if user is member of organization
        CREATE OR REPLACE FUNCTION is_org_member(org_id UUID, user_id UUID)
        RETURNS BOOLEAN AS $$
        BEGIN
            RETURN EXISTS (
                SELECT 1 FROM organization_members
                WHERE organization_id = org_id
                AND user_id = user_id
            );
        END;
        $$ LANGUAGE plpgsql SECURITY DEFINER;
        """
        await self.execute(query)
        print("✓ Created helper functions for RLS policies")

    async def enable_rls_on_tables(self, tables: List[str]):
        """Enable RLS on specified tables."""
        for table in tables:
            try:
                # First check if RLS is already enabled
                check_query = f"""
                SELECT relrowsecurity
                FROM pg_class
                WHERE relname = '{table}'
                """
                result = await self.conn.fetchval(check_query)

                if not result:
                    # Enable RLS
                    query = f"ALTER TABLE {table} ENABLE ROW LEVEL SECURITY"
                    await self.execute(query)
                    print(f"✓ Enabled RLS on table: {table}")
                else:
                    print(f"ℹ RLS already enabled on table: {table}")
            except Exception as e:
                print(f"✗ Failed to enable RLS on {table}: {e}")

    async def create_organization_policies(self):
        """Create RLS policies for tables with direct organization_id."""
        tables_with_org_id = [
            'portfolios',
            'programs',
            'projects',
            'ai_configurations',
            'integrations'
        ]

        for table in tables_with_org_id:
            # Drop existing policies if they exist
            drop_policies = f"""
            DROP POLICY IF EXISTS {table}_select_policy ON {table};
            DROP POLICY IF EXISTS {table}_insert_policy ON {table};
            DROP POLICY IF EXISTS {table}_update_policy ON {table};
            DROP POLICY IF EXISTS {table}_delete_policy ON {table};
            """
            await self.execute(drop_policies)

            # Create SELECT policy
            select_policy = f"""
            CREATE POLICY {table}_select_policy ON {table}
            FOR SELECT
            USING (organization_id = current_org_id());
            """
            await self.execute(select_policy)

            # Create INSERT policy
            insert_policy = f"""
            CREATE POLICY {table}_insert_policy ON {table}
            FOR INSERT
            WITH CHECK (organization_id = current_org_id());
            """
            await self.execute(insert_policy)

            # Create UPDATE policy
            update_policy = f"""
            CREATE POLICY {table}_update_policy ON {table}
            FOR UPDATE
            USING (organization_id = current_org_id())
            WITH CHECK (organization_id = current_org_id());
            """
            await self.execute(update_policy)

            # Create DELETE policy (admins only)
            delete_policy = f"""
            CREATE POLICY {table}_delete_policy ON {table}
            FOR DELETE
            USING (
                organization_id = current_org_id()
                AND EXISTS (
                    SELECT 1 FROM organization_members
                    WHERE organization_id = current_org_id()
                    AND user_id = current_user_id()
                    AND role = 'admin'
                )
            );
            """
            await self.execute(delete_policy)

            print(f"✓ Created RLS policies for table: {table}")

    async def create_project_scoped_policies(self):
        """Create RLS policies for tables that inherit organization through project."""
        project_scoped_tables = [
            'content',
            'queries',
            'activities',
            'risks',
            'tasks',
            'project_members'
        ]

        for table in project_scoped_tables:
            # Drop existing policies
            drop_policies = f"""
            DROP POLICY IF EXISTS {table}_select_policy ON {table};
            DROP POLICY IF EXISTS {table}_insert_policy ON {table};
            DROP POLICY IF EXISTS {table}_update_policy ON {table};
            DROP POLICY IF EXISTS {table}_delete_policy ON {table};
            """
            await self.execute(drop_policies)

            # Create SELECT policy
            select_policy = f"""
            CREATE POLICY {table}_select_policy ON {table}
            FOR SELECT
            USING (
                EXISTS (
                    SELECT 1 FROM projects p
                    WHERE p.id = {table}.project_id
                    AND p.organization_id = current_org_id()
                )
            );
            """
            await self.execute(select_policy)

            # Create INSERT policy
            insert_policy = f"""
            CREATE POLICY {table}_insert_policy ON {table}
            FOR INSERT
            WITH CHECK (
                EXISTS (
                    SELECT 1 FROM projects p
                    WHERE p.id = {table}.project_id
                    AND p.organization_id = current_org_id()
                )
            );
            """
            await self.execute(insert_policy)

            # Create UPDATE policy
            update_policy = f"""
            CREATE POLICY {table}_update_policy ON {table}
            FOR UPDATE
            USING (
                EXISTS (
                    SELECT 1 FROM projects p
                    WHERE p.id = {table}.project_id
                    AND p.organization_id = current_org_id()
                )
            )
            WITH CHECK (
                EXISTS (
                    SELECT 1 FROM projects p
                    WHERE p.id = {table}.project_id
                    AND p.organization_id = current_org_id()
                )
            );
            """
            await self.execute(update_policy)

            # Create DELETE policy
            delete_policy = f"""
            CREATE POLICY {table}_delete_policy ON {table}
            FOR DELETE
            USING (
                EXISTS (
                    SELECT 1 FROM projects p
                    WHERE p.id = {table}.project_id
                    AND p.organization_id = current_org_id()
                )
                AND EXISTS (
                    SELECT 1 FROM organization_members om
                    WHERE om.organization_id = current_org_id()
                    AND om.user_id = current_user_id()
                    AND om.role IN ('admin', 'member')
                )
            );
            """
            await self.execute(delete_policy)

            print(f"✓ Created RLS policies for project-scoped table: {table}")

    async def create_summaries_policies(self):
        """Create RLS policies for summaries table (multi-entity)."""
        # Drop existing policies
        drop_policies = """
        DROP POLICY IF EXISTS summaries_select_policy ON summaries;
        DROP POLICY IF EXISTS summaries_insert_policy ON summaries;
        DROP POLICY IF EXISTS summaries_update_policy ON summaries;
        DROP POLICY IF EXISTS summaries_delete_policy ON summaries;
        """
        await self.execute(drop_policies)

        # Create SELECT policy
        select_policy = """
        CREATE POLICY summaries_select_policy ON summaries
        FOR SELECT
        USING (
            -- Check project association
            (project_id IS NOT NULL AND EXISTS (
                SELECT 1 FROM projects p
                WHERE p.id = summaries.project_id
                AND p.organization_id = current_org_id()
            ))
            OR
            -- Check program association
            (program_id IS NOT NULL AND EXISTS (
                SELECT 1 FROM programs pr
                WHERE pr.id = summaries.program_id
                AND pr.organization_id = current_org_id()
            ))
            OR
            -- Check portfolio association
            (portfolio_id IS NOT NULL AND EXISTS (
                SELECT 1 FROM portfolios pf
                WHERE pf.id = summaries.portfolio_id
                AND pf.organization_id = current_org_id()
            ))
        );
        """
        await self.execute(select_policy)

        # Create INSERT policy
        insert_policy = """
        CREATE POLICY summaries_insert_policy ON summaries
        FOR INSERT
        WITH CHECK (
            -- Check project association
            (project_id IS NOT NULL AND EXISTS (
                SELECT 1 FROM projects p
                WHERE p.id = summaries.project_id
                AND p.organization_id = current_org_id()
            ))
            OR
            -- Check program association
            (program_id IS NOT NULL AND EXISTS (
                SELECT 1 FROM programs pr
                WHERE pr.id = summaries.program_id
                AND pr.organization_id = current_org_id()
            ))
            OR
            -- Check portfolio association
            (portfolio_id IS NOT NULL AND EXISTS (
                SELECT 1 FROM portfolios pf
                WHERE pf.id = summaries.portfolio_id
                AND pf.organization_id = current_org_id()
            ))
        );
        """
        await self.execute(insert_policy)

        # Similar UPDATE and DELETE policies
        update_policy = """
        CREATE POLICY summaries_update_policy ON summaries
        FOR UPDATE
        USING (
            (project_id IS NOT NULL AND EXISTS (
                SELECT 1 FROM projects p
                WHERE p.id = summaries.project_id
                AND p.organization_id = current_org_id()
            ))
            OR
            (program_id IS NOT NULL AND EXISTS (
                SELECT 1 FROM programs pr
                WHERE pr.id = summaries.program_id
                AND pr.organization_id = current_org_id()
            ))
            OR
            (portfolio_id IS NOT NULL AND EXISTS (
                SELECT 1 FROM portfolios pf
                WHERE pf.id = summaries.portfolio_id
                AND pf.organization_id = current_org_id()
            ))
        )
        WITH CHECK (
            (project_id IS NOT NULL AND EXISTS (
                SELECT 1 FROM projects p
                WHERE p.id = summaries.project_id
                AND p.organization_id = current_org_id()
            ))
            OR
            (program_id IS NOT NULL AND EXISTS (
                SELECT 1 FROM programs pr
                WHERE pr.id = summaries.program_id
                AND pr.organization_id = current_org_id()
            ))
            OR
            (portfolio_id IS NOT NULL AND EXISTS (
                SELECT 1 FROM portfolios pf
                WHERE pf.id = summaries.portfolio_id
                AND pf.organization_id = current_org_id()
            ))
        );
        """
        await self.execute(update_policy)

        delete_policy = """
        CREATE POLICY summaries_delete_policy ON summaries
        FOR DELETE
        USING (
            ((project_id IS NOT NULL AND EXISTS (
                SELECT 1 FROM projects p
                WHERE p.id = summaries.project_id
                AND p.organization_id = current_org_id()
            ))
            OR
            (program_id IS NOT NULL AND EXISTS (
                SELECT 1 FROM programs pr
                WHERE pr.id = summaries.program_id
                AND pr.organization_id = current_org_id()
            ))
            OR
            (portfolio_id IS NOT NULL AND EXISTS (
                SELECT 1 FROM portfolios pf
                WHERE pf.id = summaries.portfolio_id
                AND pf.organization_id = current_org_id()
            )))
            AND EXISTS (
                SELECT 1 FROM organization_members om
                WHERE om.organization_id = current_org_id()
                AND om.user_id = current_user_id()
                AND om.role IN ('admin', 'member')
            )
        );
        """
        await self.execute(delete_policy)

        print("✓ Created RLS policies for summaries table")

    async def create_organization_members_policies(self):
        """Create RLS policies for organization_members table."""
        # Drop existing policies
        drop_policies = """
        DROP POLICY IF EXISTS org_members_select_policy ON organization_members;
        DROP POLICY IF EXISTS org_members_insert_policy ON organization_members;
        DROP POLICY IF EXISTS org_members_update_policy ON organization_members;
        DROP POLICY IF EXISTS org_members_delete_policy ON organization_members;
        """
        await self.execute(drop_policies)

        # SELECT - members can see other members in their organization
        select_policy = """
        CREATE POLICY org_members_select_policy ON organization_members
        FOR SELECT
        USING (organization_id = current_org_id());
        """
        await self.execute(select_policy)

        # INSERT - only admins can add new members
        insert_policy = """
        CREATE POLICY org_members_insert_policy ON organization_members
        FOR INSERT
        WITH CHECK (
            organization_id = current_org_id()
            AND EXISTS (
                SELECT 1 FROM organization_members om
                WHERE om.organization_id = current_org_id()
                AND om.user_id = current_user_id()
                AND om.role = 'admin'
            )
        );
        """
        await self.execute(insert_policy)

        # UPDATE - only admins can update roles
        update_policy = """
        CREATE POLICY org_members_update_policy ON organization_members
        FOR UPDATE
        USING (
            organization_id = current_org_id()
            AND EXISTS (
                SELECT 1 FROM organization_members om
                WHERE om.organization_id = current_org_id()
                AND om.user_id = current_user_id()
                AND om.role = 'admin'
            )
        )
        WITH CHECK (
            organization_id = current_org_id()
        );
        """
        await self.execute(update_policy)

        # DELETE - only admins can remove members
        delete_policy = """
        CREATE POLICY org_members_delete_policy ON organization_members
        FOR DELETE
        USING (
            organization_id = current_org_id()
            AND EXISTS (
                SELECT 1 FROM organization_members om
                WHERE om.organization_id = current_org_id()
                AND om.user_id = current_user_id()
                AND om.role = 'admin'
            )
        );
        """
        await self.execute(delete_policy)

        print("✓ Created RLS policies for organization_members table")

    async def create_organizations_policies(self):
        """Create RLS policies for organizations table."""
        # Drop existing policies
        drop_policies = """
        DROP POLICY IF EXISTS organizations_select_policy ON organizations;
        DROP POLICY IF EXISTS organizations_update_policy ON organizations;
        DROP POLICY IF EXISTS organizations_delete_policy ON organizations;
        """
        await self.execute(drop_policies)

        # SELECT - users can see organizations they belong to
        select_policy = """
        CREATE POLICY organizations_select_policy ON organizations
        FOR SELECT
        USING (
            EXISTS (
                SELECT 1 FROM organization_members om
                WHERE om.organization_id = organizations.id
                AND om.user_id = current_user_id()
            )
        );
        """
        await self.execute(select_policy)

        # UPDATE - only admins can update organization settings
        update_policy = """
        CREATE POLICY organizations_update_policy ON organizations
        FOR UPDATE
        USING (
            EXISTS (
                SELECT 1 FROM organization_members om
                WHERE om.organization_id = organizations.id
                AND om.user_id = current_user_id()
                AND om.role = 'admin'
            )
        )
        WITH CHECK (
            EXISTS (
                SELECT 1 FROM organization_members om
                WHERE om.organization_id = organizations.id
                AND om.user_id = current_user_id()
                AND om.role = 'admin'
            )
        );
        """
        await self.execute(update_policy)

        # DELETE - only the organization creator can delete it
        delete_policy = """
        CREATE POLICY organizations_delete_policy ON organizations
        FOR DELETE
        USING (
            created_by = current_user_id()
        );
        """
        await self.execute(delete_policy)

        print("✓ Created RLS policies for organizations table")

    async def verify_rls_status(self):
        """Verify RLS is enabled and policies are created."""
        query = """
        SELECT
            c.relname as table_name,
            c.relrowsecurity as rls_enabled,
            COUNT(p.polname) as policy_count
        FROM pg_class c
        LEFT JOIN pg_policy p ON c.oid = p.polrelid
        WHERE c.relkind = 'r'
        AND c.relname NOT LIKE 'pg_%'
        AND c.relname NOT LIKE 'sql_%'
        AND c.relname != 'alembic_version'
        AND c.relname != 'users'
        GROUP BY c.relname, c.relrowsecurity
        ORDER BY c.relname;
        """

        results = await self.conn.fetch(query)

        print("\n" + "="*60)
        print("RLS Status Summary:")
        print("="*60)

        for row in results:
            status = "✓ Enabled" if row['rls_enabled'] else "✗ Disabled"
            policies = row['policy_count']
            print(f"{row['table_name']:30s} | RLS: {status:10s} | Policies: {policies}")

        print("="*60)

    async def setup_all_policies(self):
        """Main method to set up all RLS policies."""
        print("\n" + "="*60)
        print("Setting up Row-Level Security Policies")
        print("="*60 + "\n")

        try:
            await self.connect()

            # Create helper functions
            await self.create_session_variables_function()

            # Get list of all tables that need RLS
            all_tables = [
                'organizations',
                'organization_members',
                'portfolios',
                'programs',
                'projects',
                'ai_configurations',
                'integrations',
                'content',
                'queries',
                'activities',
                'risks',
                'tasks',
                'project_members',
                'summaries'
            ]

            # Enable RLS on all tables
            print("\n--- Enabling RLS on Tables ---")
            await self.enable_rls_on_tables(all_tables)

            # Create policies for each category
            print("\n--- Creating Organization Policies ---")
            await self.create_organizations_policies()
            await self.create_organization_members_policies()

            print("\n--- Creating Direct Organization-Scoped Policies ---")
            await self.create_organization_policies()

            print("\n--- Creating Project-Scoped Policies ---")
            await self.create_project_scoped_policies()

            print("\n--- Creating Multi-Entity Policies ---")
            await self.create_summaries_policies()

            # Verify final status
            await self.verify_rls_status()

            print("\n✅ RLS setup completed successfully!")

        except Exception as e:
            print(f"\n❌ Error during RLS setup: {e}")
            raise
        finally:
            await self.disconnect()


async def main():
    """Main function to run the RLS setup."""
    manager = RLSPolicyManager(DATABASE_URL)
    await manager.setup_all_policies()


if __name__ == "__main__":
    asyncio.run(main())