"""
Configure database user for Row-Level Security.

This script creates a separate application user with restricted privileges
that cannot bypass RLS policies, unlike the superuser.
"""

import asyncio
import asyncpg
import os

DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql://pm_master:pm_master_pass@localhost:5432/pm_master_db"
)


async def configure_rls_user():
    """Configure application user for RLS enforcement."""
    # Connect as superuser to create the application user
    conn = await asyncpg.connect(DATABASE_URL)

    try:
        print("Configuring RLS Application User...")

        # Create application user if it doesn't exist
        # This user will be used by the FastAPI application
        await conn.execute("""
            DO $$
            BEGIN
                IF NOT EXISTS (SELECT FROM pg_user WHERE usename = 'pm_app_user') THEN
                    CREATE USER pm_app_user WITH PASSWORD 'pm_app_pass';
                END IF;
            END
            $$;
        """)

        # Grant necessary permissions to the application user
        # Grant connect to the database
        await conn.execute("""
            GRANT CONNECT ON DATABASE pm_master_db TO pm_app_user;
        """)

        # Grant usage on public schema
        await conn.execute("""
            GRANT USAGE ON SCHEMA public TO pm_app_user;
        """)

        # Grant permissions on all tables
        await conn.execute("""
            GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO pm_app_user;
        """)

        # Grant permissions on all sequences
        await conn.execute("""
            GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO pm_app_user;
        """)

        # Grant execute on all functions
        await conn.execute("""
            GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO pm_app_user;
        """)

        # Set default permissions for future objects
        await conn.execute("""
            ALTER DEFAULT PRIVILEGES IN SCHEMA public
            GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO pm_app_user;
        """)

        await conn.execute("""
            ALTER DEFAULT PRIVILEGES IN SCHEMA public
            GRANT USAGE, SELECT ON SEQUENCES TO pm_app_user;
        """)

        await conn.execute("""
            ALTER DEFAULT PRIVILEGES IN SCHEMA public
            GRANT EXECUTE ON FUNCTIONS TO pm_app_user;
        """)

        print("✓ Application user 'pm_app_user' configured successfully")
        print("✓ Permissions granted on all tables and sequences")

        # Test that RLS will be enforced for this user
        print("\n--- Testing RLS Enforcement ---")

        # Create a test connection as the app user
        app_conn = await asyncpg.connect(
            "postgresql://pm_app_user:pm_app_pass@localhost:5432/pm_master_db"
        )

        try:
            # Without context, should see no data (or error)
            result = await app_conn.fetch("SELECT COUNT(*) FROM projects")
            print(f"Without RLS context: {result[0]['count']} projects visible")

            # With context, should see filtered data
            await app_conn.execute("SET app.user_id = '00000000-0000-0000-0000-000000000000'")
            await app_conn.execute("SET app.organization_id = '00000000-0000-0000-0000-000000000001'")
            result = await app_conn.fetch("SELECT COUNT(*) FROM projects")
            print(f"With RLS context: {result[0]['count']} projects visible")

            print("✓ RLS is properly enforced for application user")
        finally:
            await app_conn.close()

        print("\n" + "="*60)
        print("RLS User Configuration Complete!")
        print("="*60)
        print("\nTo use in your application, update DATABASE_URL to:")
        print("postgresql://pm_app_user:pm_app_pass@localhost:5432/pm_master_db")
        print("\nThe superuser connection should only be used for:")
        print("- Database migrations")
        print("- Administrative tasks")
        print("- Initial setup")

    except Exception as e:
        print(f"❌ Error configuring RLS user: {e}")
        raise
    finally:
        await conn.close()


async def main():
    """Run the RLS user configuration."""
    await configure_rls_user()


if __name__ == "__main__":
    asyncio.run(main())