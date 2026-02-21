"""Tests for the demo data seed/check/clear service."""

import pytest
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from models.portfolio import Portfolio
from models.program import Program
from models.project import Project
from models.content import Content
from models.summary import Summary
from models.task import Task
from models.risk import Risk
from models.blocker import Blocker
from models.lesson_learned import LessonLearned
from models.activity import Activity
from services.demo.demo_data_service import DemoDataService


@pytest.mark.asyncio
class TestDemoDataService:

    async def test_seed_creates_full_hierarchy(self, db_session: AsyncSession, test_organization, test_user):
        """Seeding should create 1 portfolio, 1 program, 2 projects, and child records."""
        result = await DemoDataService.seed_demo_data(
            db_session, test_organization.id, test_user.email
        )
        await db_session.flush()

        assert result is True

        # Verify hierarchy
        portfolios = (await db_session.execute(
            select(func.count()).select_from(Portfolio).where(
                Portfolio.organization_id == test_organization.id, Portfolio.is_demo == True
            )
        )).scalar()
        assert portfolios == 1

        programs = (await db_session.execute(
            select(func.count()).select_from(Program).where(
                Program.organization_id == test_organization.id, Program.is_demo == True
            )
        )).scalar()
        assert programs == 1

        projects = (await db_session.execute(
            select(func.count()).select_from(Project).where(
                Project.organization_id == test_organization.id, Project.is_demo == True
            )
        )).scalar()
        assert projects == 2

        # Verify child records exist (at least some)
        tasks = (await db_session.execute(
            select(func.count()).select_from(Task).where(Task.is_demo == True)
        )).scalar()
        assert tasks > 0

        risks = (await db_session.execute(
            select(func.count()).select_from(Risk).where(Risk.is_demo == True)
        )).scalar()
        assert risks > 0

    async def test_has_demo_data(self, db_session: AsyncSession, test_organization, test_user):
        """has_demo_data should return False before seeding and True after."""
        assert await DemoDataService.has_demo_data(db_session, test_organization.id) is False

        await DemoDataService.seed_demo_data(db_session, test_organization.id, test_user.email)
        await db_session.flush()

        assert await DemoDataService.has_demo_data(db_session, test_organization.id) is True

    async def test_clear_removes_all_demo_data(self, db_session: AsyncSession, test_organization, test_user):
        """Clearing should remove all demo records and return counts."""
        await DemoDataService.seed_demo_data(db_session, test_organization.id, test_user.email)
        await db_session.flush()

        counts = await DemoDataService.clear_demo_data(db_session, test_organization.id)
        await db_session.flush()

        assert counts["portfolios"] == 1
        assert counts["programs"] == 1
        assert counts["projects"] == 2
        assert await DemoDataService.has_demo_data(db_session, test_organization.id) is False

    async def test_clear_preserves_real_data(self, db_session: AsyncSession, test_organization, test_user):
        """Clearing demo data should not touch non-demo records."""
        # Create a real project
        real_project = Project(
            organization_id=test_organization.id,
            name="Real Project",
            description="Not demo",
            created_by=test_user.email,
            is_demo=False,
        )
        db_session.add(real_project)
        await db_session.flush()

        # Seed and clear demo data
        await DemoDataService.seed_demo_data(db_session, test_organization.id, test_user.email)
        await db_session.flush()
        await DemoDataService.clear_demo_data(db_session, test_organization.id)
        await db_session.flush()

        # Real project should still exist
        remaining = (await db_session.execute(
            select(func.count()).select_from(Project).where(
                Project.organization_id == test_organization.id
            )
        )).scalar()
        assert remaining == 1

        real = (await db_session.execute(
            select(Project).where(Project.id == real_project.id)
        )).scalar_one()
        assert real.name == "Real Project"
