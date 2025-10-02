"""Test script to debug blocker syncing issue."""

import asyncio
import json
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from db.database import get_db
from models.summary import Summary
from models.blocker import Blocker
from services.sync.project_items_sync_service import project_items_sync_service

async def test_blocker_sync():
    """Test why blockers aren't being synced to the blockers table."""

    async for session in get_db():
        try:
            # Get the summary with blockers
            result = await session.execute(
                select(Summary).where(
                    Summary.id == 'e98a789a-0ae5-4a1d-8dd4-f7310bf3def7'
                )
            )
            summary = result.scalar_one_or_none()

            if not summary:
                print("❌ Summary not found")
                return

            print(f"✓ Found summary for project: {summary.project_id}")

            # Check the risks and blockers content
            risks = summary.risks or []
            blockers = summary.blockers or []

            print(f"✓ Summary contains {len(risks)} risks and {len(blockers)} blockers:")
            for blocker in blockers:
                if isinstance(blocker, dict):
                    print(f"  - {blocker.get('title')}: {blocker.get('status')}")

            # Prepare summary data for sync
            summary_data = {
                'risks': risks,
                'blockers': blockers,
                'action_items': summary.action_items or [],
                'lessons_learned': summary.lessons_learned or []
            }

            print("\nAttempting to sync items from summary...")

            # Try to sync items
            sync_result = await project_items_sync_service.sync_items_from_summary(
                session=session,
                project_id=summary.project_id,
                content_id=summary.content_id,
                summary_data=summary_data
            )

            print(f"\nSync result:")
            print(f"  - Risks synced: {sync_result['risks_synced']}")
            print(f"  - Blockers synced: {sync_result['blockers_synced']}")
            print(f"  - Tasks synced: {sync_result['tasks_synced']}")
            print(f"  - Lessons synced: {sync_result['lessons_synced']}")

            if sync_result.get('errors'):
                print(f"  - Errors: {sync_result['errors']}")

            # Check blockers table
            result = await session.execute(
                select(Blocker).where(Blocker.project_id == summary.project_id)
            )
            blockers_in_db = result.scalars().all()

            print(f"\n✓ Blockers in database: {len(blockers_in_db)}")
            for blocker in blockers_in_db:
                print(f"  - {blocker.title}: {blocker.status.value if blocker.status else 'unknown'}")

        except Exception as e:
            print(f"\n❌ Error during test: {e}")
            import traceback
            traceback.print_exc()
        finally:
            await session.close()
            break

if __name__ == "__main__":
    asyncio.run(test_blocker_sync())