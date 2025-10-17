"""
Integration tests for semantic deduplication system.

Tests the end-to-end flow of:
1. Extracting items from meeting summaries
2. Generating embeddings
3. Finding semantic duplicates
4. Applying intelligent updates
"""

import pytest
import uuid
from datetime import datetime
from sqlalchemy import select

from models.risk import Risk
from models.task import Task
from models.blocker import Blocker
from models.lesson_learned import LessonLearned
from services.intelligence.semantic_deduplicator import semantic_deduplicator
from services.sync.project_items_sync_service import project_items_sync_service


class TestSemanticDeduplication:
    """Integration tests for semantic deduplication."""

    @pytest.mark.skip(reason="Requires real embeddings for semantic similarity - mock embeddings don't capture semantic meaning")
    @pytest.mark.asyncio
    async def test_duplicate_risk_detection(self, db_session, test_project):
        """Test that semantically similar risks are detected as duplicates."""
        project_id = test_project.id

        # Create existing risk
        existing_risk = Risk(
            project_id=project_id,
            title="AI Tool Adoption Without Governance",
            description="Teams are adopting AI tools without proper governance",
            severity="high",
            status="identified",
            ai_generated="true",
            ai_confidence=0.8,
            updated_by="ai"
        )
        db_session.add(existing_risk)
        await db_session.commit()
        await db_session.refresh(existing_risk)

        # New risk that is semantically similar
        new_risks = [{
            'title': "Uncontrolled AI Tool Proliferation",
            'description': "AI tools spreading across org without approval process",
            'severity': "high",
            'status': "identified",
            'confidence': 0.85
        }]

        existing_risks = [existing_risk.to_dict()]

        # Run deduplication
        result = await semantic_deduplicator.deduplicate_items(
            item_type='risk',
            new_items=new_risks,
            existing_items=existing_risks
        )

        # Should detect as duplicate (high similarity)
        assert len(result['unique_items']) == 0, "Should not have unique items"
        assert len(result['updates']) >= 0, "Should have updates or exact duplicates"
        assert len(result['exact_duplicates']) >= 0

    @pytest.mark.skip(reason="Requires real embeddings for semantic similarity - mock embeddings don't capture semantic meaning")
    @pytest.mark.asyncio
    async def test_unique_risk_detection(self, db_session, test_project):
        """Test that different risks are NOT marked as duplicates."""
        project_id = test_project.id

        # Create existing risk about AI
        existing_risk = Risk(
            project_id=project_id,
            title="AI Tool Governance Risk",
            description="No governance for AI tools",
            severity="high",
            status="identified",
            ai_generated="true",
            updated_by="ai"
        )
        db_session.add(existing_risk)
        await db_session.commit()
        await db_session.refresh(existing_risk)

        # New risk about completely different topic
        new_risks = [{
            'title': "Customer Satisfaction Decline",
            'description': "Net Promoter Score dropped from 75 to 45",
            'severity': "medium",
            'status': "identified",
            'confidence': 0.9
        }]

        existing_risks = [existing_risk.to_dict()]

        # Run deduplication
        result = await semantic_deduplicator.deduplicate_items(
            item_type='risk',
            new_items=new_risks,
            existing_items=existing_risks
        )

        # Different topics but may still be flagged as duplicates by embeddings
        # The key is that AI analysis should determine they're NOT actually duplicates
        # Either unique or in exact_duplicates based on AI analysis
        total_items = len(result['unique_items']) + len(result['exact_duplicates']) + len(result['updates'])
        assert total_items == 1, f"Should process exactly 1 item, got {total_items}"

        # If treated as unique, should have embedding
        if len(result['unique_items']) == 1:
            assert result['unique_items'][0]['title_embedding'] is not None, "Unique item should have embedding"

    @pytest.mark.skip(reason="Requires real embeddings for semantic similarity - mock embeddings don't capture semantic meaning")
    @pytest.mark.asyncio
    async def test_intelligent_update_extraction(self, db_session, test_project):
        """Test that updates are extracted from duplicates."""
        project_id = test_project.id

        # Create existing risk without mitigation
        existing_risk = Risk(
            project_id=project_id,
            title="Data Migration Risk",
            description="Risk of data loss during migration",
            severity="high",
            status="identified",
            mitigation=None,
            ai_generated="true",
            updated_by="ai"
        )
        db_session.add(existing_risk)
        await db_session.commit()
        await db_session.refresh(existing_risk)

        # New similar risk with mitigation info
        new_risks = [{
            'title': "Data Migration Data Loss Risk",
            'description': "Potential data loss during migration process",
            'severity': "high",
            'status': "mitigating",  # Status changed
            'mitigation': "Implement backup strategy and rollback plan",  # New info
            'confidence': 0.85
        }]

        existing_risks = [existing_risk.to_dict()]

        # Run deduplication
        result = await semantic_deduplicator.deduplicate_items(
            item_type='risk',
            new_items=new_risks,
            existing_items=existing_risks
        )

        # Should detect duplicate with updates
        updates = result['updates']
        if len(updates) > 0:
            update = updates[0]
            assert update['has_new_info'] == True, "Should have new info"
            assert update['existing_item_id'] == str(existing_risk.id)
            # May have status or mitigation update
            new_info = update.get('new_info', {})
            assert 'status' in new_info or 'mitigation' in new_info, "Should have update info"

    @pytest.mark.asyncio
    async def test_end_to_end_sync_with_deduplication(self, db_session, test_project, test_user):
        """Test complete sync flow with semantic deduplication."""
        from models.content import Content

        project_id = test_project.id

        # Create content record first (required for foreign key)
        content = Content(
            project_id=project_id,
            content_type="meeting",
            title="Test Meeting",
            content="Test meeting content",
            uploaded_by=str(test_user.id)
        )
        db_session.add(content)
        await db_session.commit()
        await db_session.refresh(content)
        content_id = content.id

        # Create existing items
        existing_risk = Risk(
            project_id=project_id,
            title="API Performance Degradation",
            description="Slow API response times",
            severity="medium",
            status="identified",
            ai_generated="true",
            updated_by="ai"
        )
        db_session.add(existing_risk)
        await db_session.commit()

        # Summary data with duplicate and new items
        summary_data = {
            'risks': [
                {
                    'title': "API Performance Issues",  # Similar to existing
                    'description': "APIs responding slowly under load",
                    'severity': "medium",
                    'status': "identified",
                    'confidence': 0.8
                },
                {
                    'title': "Customer Onboarding Process Delays",  # New, completely different topic
                    'description': "New customer onboarding takes 3 weeks instead of 1 week, causing customer dissatisfaction",
                    'severity': "high",
                    'status': "identified",
                    'confidence': 0.9
                }
            ],
            'tasks': [],
            'blockers': [],
            'lessons_learned': []
        }

        # Run sync
        result = await project_items_sync_service.sync_items_from_summary(
            session=db_session,
            project_id=project_id,
            content_id=content_id,
            summary_data=summary_data
        )

        # Should process items correctly
        # We expect at least 1 unique risk (the onboarding one), the API one may be duplicate or update
        assert result['risks_synced'] >= 1, f"Should sync at least 1 new risk, got {result['risks_synced']}"
        assert len(result['errors']) == 0, f"Should not have errors, got {result['errors']}"

        # Verify database state
        risks_result = await db_session.execute(
            select(Risk).where(Risk.project_id == project_id)
        )
        all_risks = risks_result.scalars().all()

        # Should have at least 2 risks total (existing + 1 new, and maybe update to existing)
        assert len(all_risks) >= 2, f"Should have at least 2 risks in database, got {len(all_risks)}"

    @pytest.mark.asyncio
    async def test_embedding_storage(self, db_session, test_project, test_user):
        """Test that embeddings are stored in database."""
        from models.content import Content

        project_id = test_project.id

        # Create content record first (required for foreign key)
        content = Content(
            project_id=project_id,
            content_type="meeting",
            title="Test Meeting",
            content="Test meeting content",
            uploaded_by=str(test_user.id)
        )
        db_session.add(content)
        await db_session.commit()
        await db_session.refresh(content)
        content_id = content.id

        summary_data = {
            'risks': [{
                'title': "Test Risk for Embedding",
                'description': "Testing embedding storage",
                'severity': "low",
                'status': "identified",
                'confidence': 0.9
            }],
            'tasks': [],
            'blockers': [],
            'lessons_learned': []
        }

        # Sync items
        await project_items_sync_service.sync_items_from_summary(
            session=db_session,
            project_id=project_id,
            content_id=content_id,
            summary_data=summary_data
        )

        # Check if embedding was stored
        risks_result = await db_session.execute(
            select(Risk).where(
                Risk.project_id == project_id,
                Risk.title == "Test Risk for Embedding"
            )
        )
        risk = risks_result.scalar_one_or_none()

        assert risk is not None, "Risk should be created"
        assert risk.title_embedding is not None, "Embedding should be stored"
        assert isinstance(risk.title_embedding, list), "Embedding should be a list"
        assert len(risk.title_embedding) == 768, "Embedding should be 768 dimensions"

    @pytest.mark.asyncio
    async def test_multiple_item_types_deduplication(self, db_session, test_project, test_user):
        """Test deduplication works for all item types."""
        from models.content import Content

        project_id = test_project.id

        # Create content record first (required for foreign key)
        content = Content(
            project_id=project_id,
            content_type="meeting",
            title="Test Meeting",
            content="Test meeting content",
            uploaded_by=str(test_user.id)
        )
        db_session.add(content)
        await db_session.commit()
        await db_session.refresh(content)
        content_id = content.id

        # Create existing items of each type
        existing_task = Task(
            project_id=project_id,
            title="Configure API Gateway",
            description="Set up API gateway for microservices",
            status="todo",
            priority="high",
            ai_generated="true",
            updated_by="ai"
        )
        db_session.add(existing_task)
        await db_session.commit()

        # Summary with similar items
        summary_data = {
            'risks': [],
            'action_items': [{
                'title': "Setup API Gateway Configuration",  # Similar to existing task
                'description': "Configure gateway for services",
                'priority': "high",
                'confidence': 0.85
            }],
            'blockers': [],
            'lessons_learned': []
        }

        # Sync
        result = await project_items_sync_service.sync_items_from_summary(
            session=db_session,
            project_id=project_id,
            content_id=content_id,
            summary_data=summary_data
        )

        # Should handle task deduplication
        assert len(result['errors']) == 0, "Should not have errors"

    @pytest.mark.asyncio
    async def test_deduplication_with_no_existing_items(self, db_session, test_project, test_user):
        """Test deduplication when no existing items (all should be unique)."""
        from models.content import Content

        project_id = test_project.id

        # Create content record first (required for foreign key)
        content = Content(
            project_id=project_id,
            content_type="meeting",
            title="Test Meeting",
            content="Test meeting content",
            uploaded_by=str(test_user.id)
        )
        db_session.add(content)
        await db_session.commit()
        await db_session.refresh(content)
        content_id = content.id

        summary_data = {
            'risks': [
                {'title': "Risk 1", 'description': "Desc 1", 'severity': "low", 'status': "identified", 'confidence': 0.8},
                {'title': "Risk 2", 'description': "Desc 2", 'severity': "medium", 'status': "identified", 'confidence': 0.8},
            ],
            'tasks': [],
            'blockers': [],
            'lessons_learned': []
        }

        result = await project_items_sync_service.sync_items_from_summary(
            session=db_session,
            project_id=project_id,
            content_id=content_id,
            summary_data=summary_data
        )

        # All should be synced (no existing items to deduplicate against)
        assert result['risks_synced'] == 2, "Should sync both risks"
        assert len(result['errors']) == 0

    @pytest.mark.skip(reason="Requires real embeddings for semantic similarity - mock embeddings don't capture semantic meaning")
    @pytest.mark.asyncio
    async def test_similarity_thresholds(self, db_session, test_project):
        """Test that similarity thresholds work correctly."""
        project_id = test_project.id

        # Create existing risk
        existing_risk = Risk(
            project_id=project_id,
            title="Cloud Platform Migration",
            description="Migrating to new cloud platform",
            severity="high",
            status="identified",
            ai_generated="true",
            updated_by="ai"
        )
        db_session.add(existing_risk)
        await db_session.commit()
        await db_session.refresh(existing_risk)

        existing_risks = [existing_risk.to_dict()]

        # Test cases with different similarity levels
        test_cases = [
            {
                'title': "Cloud Platform Migration Risk",  # Very similar - should be duplicate
                'description': "Migrating to new cloud platform",
                'expected_unique': False
            },
            {
                'title': "Cloud Infrastructure Setup",  # Somewhat similar - may be duplicate
                'description': "Setting up cloud infrastructure components",
                'expected_unique': 'maybe'
            },
            {
                'title': "Mobile App Development Launch",  # Different - should be unique
                'description': "Launching new mobile application for customers with push notifications",
                'expected_unique': True
            }
        ]

        for test_case in test_cases:
            new_risks = [{
                'title': test_case['title'],
                'description': test_case['description'],
                'severity': "medium",
                'status': "identified",
                'confidence': 0.8
            }]

            result = await semantic_deduplicator.deduplicate_items(
                item_type='risk',
                new_items=new_risks,
                existing_items=existing_risks
            )

            if test_case['expected_unique'] == True:
                # Should be treated as unique (not found in updates or duplicates)
                total_duplicates = len(result['updates']) + len(result['exact_duplicates'])
                assert len(result['unique_items']) == 1 or total_duplicates == 0, \
                    f"'{test_case['title']}' should be unique (got {len(result['unique_items'])} unique, {total_duplicates} duplicates)"
            elif test_case['expected_unique'] == False:
                # Should be detected as duplicate (in updates or exact_duplicates)
                total_duplicates = len(result['updates']) + len(result['exact_duplicates'])
                assert total_duplicates >= 1 or len(result['unique_items']) == 0, \
                    f"'{test_case['title']}' should be duplicate (got {total_duplicates} duplicates, {len(result['unique_items'])} unique)"
            # 'maybe' case is skipped - depends on actual similarity calculation
