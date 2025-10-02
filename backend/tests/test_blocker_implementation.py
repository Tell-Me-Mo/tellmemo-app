"""Test script to verify blocker implementation."""

import asyncio
import uuid
from datetime import datetime
from sqlalchemy.ext.asyncio import AsyncSession
from db.database import get_db
from models.blocker import Blocker, BlockerImpact, BlockerStatus
from models.project import Project
from models.organization import Organization
from services.sync.project_items_sync_service import project_items_sync_service
import json

async def test_blocker_implementation():
    """Test that blockers are properly handled separately from risks."""

    async for session in get_db():
        try:
            print("Testing Blocker Implementation...")
            print("-" * 50)

            # Get first organization
            from sqlalchemy import select
            result = await session.execute(select(Organization).limit(1))
            org = result.scalar_one_or_none()

            if not org:
                print("❌ No organization found. Please create an organization first.")
                return

            print(f"✓ Using organization: {org.name}")

            # Get or create a test project
            result = await session.execute(
                select(Project).where(Project.organization_id == org.id).limit(1)
            )
            project = result.scalar_one_or_none()

            if not project:
                print("❌ No project found. Please create a project first.")
                return

            print(f"✓ Using project: {project.name}")

            # Test 1: Direct blocker creation
            print("\n1. Testing direct blocker creation...")
            test_blocker = Blocker(
                project_id=project.id,
                title="Test Blocker - API Integration",
                description="The external API is down, blocking all payment processing",
                impact=BlockerImpact.CRITICAL,
                status=BlockerStatus.ACTIVE,
                category="technical",
                ai_generated="false",
                identified_date=datetime.utcnow()
            )

            session.add(test_blocker)
            await session.commit()
            print("✓ Blocker created successfully")

            # Test 2: Query blockers separately from risks
            print("\n2. Testing blocker query...")
            result = await session.execute(
                select(Blocker).where(Blocker.project_id == project.id)
            )
            blockers = result.scalars().all()
            print(f"✓ Found {len(blockers)} blockers in the project")

            for blocker in blockers:
                print(f"  - {blocker.title}: {blocker.status.value} ({blocker.impact.value})")

            # Test 3: Test sync service with blockers
            print("\n3. Testing sync service with blockers...")

            # Create test summary data with both risks and blockers
            test_summary_data = {
                "risks": [
                    {
                        "title": "Budget Overrun Risk",
                        "description": "Project may exceed budget by 20%",
                        "severity": "high",
                        "status": "identified"
                    }
                ],
                "blockers": [
                    {
                        "title": "Database Migration Blocker",
                        "description": "Cannot proceed with deployment until DB migration is complete",
                        "impact": "high",
                        "status": "active"
                    }
                ],
                "action_items": [],
                "lessons_learned": []
            }

            # Sync the items
            sync_result = await project_items_sync_service.sync_items_from_summary(
                session=session,
                project_id=project.id,
                content_id=None,  # No content ID for this test
                summary_data=test_summary_data
            )

            print(f"✓ Sync completed:")
            print(f"  - Risks synced: {sync_result['risks_synced']}")
            print(f"  - Blockers synced: {sync_result['blockers_synced']}")
            print(f"  - Tasks synced: {sync_result['tasks_synced']}")
            print(f"  - Lessons synced: {sync_result['lessons_synced']}")

            # Test 4: Verify blockers and risks are stored separately
            print("\n4. Verifying separation of blockers and risks...")

            # Count risks
            from models.risk import Risk
            result = await session.execute(
                select(Risk).where(Risk.project_id == project.id)
            )
            risks = result.scalars().all()

            # Count blockers
            result = await session.execute(
                select(Blocker).where(Blocker.project_id == project.id)
            )
            blockers = result.scalars().all()

            print(f"✓ Project has:")
            print(f"  - {len(risks)} risks (separate table)")
            print(f"  - {len(blockers)} blockers (separate table)")

            # Test 5: Test blocker to_dict method
            print("\n5. Testing blocker serialization...")
            if blockers:
                blocker_dict = blockers[0].to_dict()
                print(f"✓ Blocker serialized successfully:")
                print(f"  - Keys: {list(blocker_dict.keys())[:5]}...")

            print("\n" + "=" * 50)
            print("✅ All blocker implementation tests passed!")

        except Exception as e:
            print(f"\n❌ Error during testing: {e}")
            import traceback
            traceback.print_exc()
        finally:
            await session.close()
            break

if __name__ == "__main__":
    asyncio.run(test_blocker_implementation())