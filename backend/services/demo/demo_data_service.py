"""Demo data seed service for new organizations.

Creates a full set of demo data when a new organization is created,
allowing users to explore the app's features immediately.
"""

import uuid
from datetime import datetime, timedelta, date

from sqlalchemy import select, delete, and_
from sqlalchemy.ext.asyncio import AsyncSession

from models.portfolio import Portfolio, HealthStatus
from models.program import Program
from models.project import Project
from models.content import Content, ContentType
from models.summary import Summary, SummaryType
from models.task import Task, TaskStatus, TaskPriority
from models.risk import Risk, RiskSeverity, RiskStatus
from models.blocker import Blocker, BlockerImpact, BlockerStatus
from models.lesson_learned import LessonLearned, LessonCategory, LessonType, LessonLearnedImpact
from models.activity import Activity, ActivityType
from utils.logger import get_logger

from .demo_content import (
    PORTFOLIO, PROGRAM,
    PROJECT_1, PROJECT_1_CONTENT, PROJECT_1_SUMMARY,
    PROJECT_1_TASKS, PROJECT_1_RISKS, PROJECT_1_BLOCKER, PROJECT_1_LESSON,
    PROJECT_2, PROJECT_2_CONTENT, PROJECT_2_SUMMARY,
    PROJECT_2_TASKS, PROJECT_2_RISKS, PROJECT_2_BLOCKER, PROJECT_2_LESSON,
)

logger = get_logger(__name__)


# Mapping from string values to enum members
_TASK_STATUS_MAP = {s.value: s for s in TaskStatus}
_TASK_PRIORITY_MAP = {p.value: p for p in TaskPriority}
_RISK_SEVERITY_MAP = {s.value: s for s in RiskSeverity}
_RISK_STATUS_MAP = {s.value: s for s in RiskStatus}
_BLOCKER_IMPACT_MAP = {i.value: i for i in BlockerImpact}
_BLOCKER_STATUS_MAP = {s.value: s for s in BlockerStatus}
_LESSON_CATEGORY_MAP = {c.value: c for c in LessonCategory}
_LESSON_TYPE_MAP = {t.value: t for t in LessonType}
_LESSON_IMPACT_MAP = {i.value: i for i in LessonLearnedImpact}


class DemoDataService:
    """Service for creating and managing demo data for organizations."""

    @staticmethod
    async def seed_demo_data(
        db: AsyncSession,
        organization_id: uuid.UUID,
        created_by_email: str,
    ) -> bool:
        """Create a full set of demo data for a new organization.

        Structure:
        - 1 Portfolio: "Digital Transformation Portfolio"
          - 1 Program: "Customer Experience Program"
            - Project 1: "Mobile Banking App Redesign"
            - Project 2: "Customer Support AI Chatbot"

        Each project gets: content, summary, tasks, risks, blocker,
        lesson learned, and activity entries.

        Returns True on success, False on failure.
        """
        now = datetime.utcnow()

        try:
            # --- Portfolio ---
            portfolio = Portfolio(
                organization_id=organization_id,
                name=PORTFOLIO["name"],
                description=PORTFOLIO["description"],
                owner=PORTFOLIO["owner"],
                health_status=HealthStatus.GREEN,
                created_by=created_by_email,
                is_demo=True,
            )
            db.add(portfolio)
            await db.flush()

            # --- Program ---
            program = Program(
                organization_id=organization_id,
                name=PROGRAM["name"],
                description=PROGRAM["description"],
                portfolio_id=portfolio.id,
                created_by=created_by_email,
                is_demo=True,
            )
            db.add(program)
            await db.flush()

            # --- Projects ---
            for project_def, content_list, summary_def, tasks_def, risks_def, blocker_def, lesson_def in [
                (PROJECT_1, PROJECT_1_CONTENT, PROJECT_1_SUMMARY,
                 PROJECT_1_TASKS, PROJECT_1_RISKS, PROJECT_1_BLOCKER, PROJECT_1_LESSON),
                (PROJECT_2, PROJECT_2_CONTENT, PROJECT_2_SUMMARY,
                 PROJECT_2_TASKS, PROJECT_2_RISKS, PROJECT_2_BLOCKER, PROJECT_2_LESSON),
            ]:
                await DemoDataService._seed_project(
                    db=db,
                    organization_id=organization_id,
                    portfolio_id=portfolio.id,
                    program_id=program.id,
                    created_by=created_by_email,
                    now=now,
                    project_def=project_def,
                    content_list=content_list,
                    summary_def=summary_def,
                    tasks_def=tasks_def,
                    risks_def=risks_def,
                    blocker_def=blocker_def,
                    lesson_def=lesson_def,
                )

            logger.info(f"Demo data seeded for organization {organization_id}")
            return True

        except Exception as e:
            logger.error(f"Failed to seed demo data for org {organization_id}: {e}")
            return False

    @staticmethod
    async def _seed_project(
        db: AsyncSession,
        organization_id: uuid.UUID,
        portfolio_id: uuid.UUID,
        program_id: uuid.UUID,
        created_by: str,
        now: datetime,
        project_def: dict,
        content_list: list,
        summary_def: dict,
        tasks_def: list,
        risks_def: list,
        blocker_def: dict,
        lesson_def: dict,
    ) -> None:
        """Seed a single project with all related data."""

        project = Project(
            organization_id=organization_id,
            name=project_def["name"],
            description=project_def["description"],
            created_by=created_by,
            portfolio_id=portfolio_id,
            program_id=program_id,
            is_demo=True,
        )
        db.add(project)
        await db.flush()

        # --- Content items ---
        first_content_id = None
        for item in content_list:
            content_date = (now - timedelta(days=item["days_ago"])).date()
            content = Content(
                project_id=project.id,
                content_type=ContentType.MEETING,
                title=item["title"],
                content=item["content"],
                date=content_date,
                uploaded_at=now - timedelta(days=item["days_ago"]),
                uploaded_by=created_by,
                chunk_count=0,
                summary_generated=True,
                is_demo=True,
            )
            db.add(content)
            await db.flush()
            if first_content_id is None:
                first_content_id = content.id

        # --- Summary ---
        summary = Summary(
            organization_id=organization_id,
            project_id=project.id,
            content_id=first_content_id,
            summary_type=SummaryType.MEETING,
            subject=summary_def["subject"],
            body=summary_def["body"],
            key_points=summary_def.get("key_points"),
            decisions=summary_def.get("decisions"),
            action_items=summary_def.get("action_items"),
            sentiment_analysis=summary_def.get("sentiment_analysis"),
            risks=summary_def.get("risks"),
            blockers=summary_def.get("blockers"),
            lessons_learned=summary_def.get("lessons_learned"),
            next_meeting_agenda=summary_def.get("next_meeting_agenda"),
            format=summary_def.get("format", "general"),
            created_by=created_by,
            created_at=now - timedelta(days=content_list[0]["days_ago"]),
            is_demo=True,
        )
        db.add(summary)

        # --- Tasks ---
        for task_def in tasks_def:
            task = Task(
                project_id=project.id,
                title=task_def["title"],
                description=task_def["description"],
                status=_TASK_STATUS_MAP[task_def["status"]],
                priority=_TASK_PRIORITY_MAP[task_def["priority"]],
                assignee=task_def["assignee"],
                progress_percentage=task_def["progress_percentage"],
                due_date=now + timedelta(days=task_def["due_days_from_now"]),
                ai_generated="true",
                ai_confidence=0.85,
                source_content_id=first_content_id,
                created_date=now - timedelta(days=content_list[0]["days_ago"]),
                updated_by="ai",
                is_demo=True,
            )
            db.add(task)

        # --- Risks ---
        for risk_def in risks_def:
            risk = Risk(
                project_id=project.id,
                title=risk_def["title"],
                description=risk_def["description"],
                severity=_RISK_SEVERITY_MAP[risk_def["severity"]],
                status=_RISK_STATUS_MAP[risk_def["status"]],
                mitigation=risk_def["mitigation"],
                impact=risk_def["impact"],
                probability=risk_def["probability"],
                assigned_to=risk_def["assigned_to"],
                ai_generated="true",
                ai_confidence=0.80,
                source_content_id=first_content_id,
                identified_date=now - timedelta(days=content_list[0]["days_ago"]),
                updated_by="ai",
                is_demo=True,
            )
            db.add(risk)

        # --- Blocker ---
        blocker = Blocker(
            project_id=project.id,
            title=blocker_def["title"],
            description=blocker_def["description"],
            impact=_BLOCKER_IMPACT_MAP[blocker_def["impact"]],
            status=_BLOCKER_STATUS_MAP[blocker_def["status"]],
            owner=blocker_def["owner"],
            category=blocker_def.get("category", "general"),
            ai_generated="true",
            ai_confidence=0.80,
            source_content_id=first_content_id,
            identified_date=now - timedelta(days=content_list[0]["days_ago"]),
            updated_by="ai",
            is_demo=True,
        )
        db.add(blocker)

        # --- Lesson Learned ---
        lesson = LessonLearned(
            project_id=project.id,
            title=lesson_def["title"],
            description=lesson_def["description"],
            category=_LESSON_CATEGORY_MAP[lesson_def["category"]],
            lesson_type=_LESSON_TYPE_MAP[lesson_def["lesson_type"]],
            impact=_LESSON_IMPACT_MAP[lesson_def["impact"]],
            recommendation=lesson_def.get("recommendation"),
            ai_generated="true",
            ai_confidence=0.75,
            source_content_id=first_content_id,
            identified_date=now - timedelta(days=content_list[0]["days_ago"]),
            updated_by="ai",
            is_demo=True,
        )
        db.add(lesson)

        # --- Activities ---
        activities = [
            Activity(
                project_id=project.id,
                type=ActivityType.PROJECT_CREATED,
                title="Project created",
                description=f'Project "{project_def["name"]}" was created',
                timestamp=now - timedelta(days=14),
                user_name=created_by,
                is_demo=True,
            ),
            Activity(
                project_id=project.id,
                type=ActivityType.CONTENT_UPLOADED,
                title="Meeting transcript uploaded",
                description=f'"{content_list[0]["title"]}" was uploaded and processed',
                timestamp=now - timedelta(days=content_list[0]["days_ago"]),
                user_name=created_by,
                is_demo=True,
            ),
        ]
        for activity in activities:
            db.add(activity)

        await db.flush()

    @staticmethod
    async def has_demo_data(db: AsyncSession, organization_id: uuid.UUID) -> bool:
        """Check if an organization has any demo data."""
        result = await db.execute(
            select(Portfolio.id).where(
                and_(
                    Portfolio.organization_id == organization_id,
                    Portfolio.is_demo == True,
                )
            ).limit(1)
        )
        return result.scalar_one_or_none() is not None

    @staticmethod
    async def clear_demo_data(db: AsyncSession, organization_id: uuid.UUID) -> dict:
        """Delete all demo data for an organization.

        Deletion order respects foreign key constraints (children first).
        Returns counts of deleted records per table.
        """
        counts = {}

        # Get demo project IDs for this org
        result = await db.execute(
            select(Project.id).where(
                and_(
                    Project.organization_id == organization_id,
                    Project.is_demo == True,
                )
            )
        )
        demo_project_ids = [row[0] for row in result]

        if demo_project_ids:
            # Delete children of projects (order matters for FK constraints)
            for model, name in [
                (Activity, "activities"),
                (LessonLearned, "lessons_learned"),
                (Blocker, "blockers"),
                (Task, "tasks"),
                (Risk, "risks"),
            ]:
                r = await db.execute(
                    delete(model).where(
                        and_(
                            model.project_id.in_(demo_project_ids),
                            model.is_demo == True,
                        )
                    )
                )
                counts[name] = r.rowcount

            # Delete summaries (has org-level FK)
            r = await db.execute(
                delete(Summary).where(
                    and_(
                        Summary.organization_id == organization_id,
                        Summary.is_demo == True,
                    )
                )
            )
            counts["summaries"] = r.rowcount

            # Delete content (child of project)
            for pid in demo_project_ids:
                r = await db.execute(
                    delete(Content).where(
                        and_(
                            Content.project_id == pid,
                            Content.is_demo == True,
                        )
                    )
                )
                counts["content"] = counts.get("content", 0) + r.rowcount

        # Delete projects
        r = await db.execute(
            delete(Project).where(
                and_(
                    Project.organization_id == organization_id,
                    Project.is_demo == True,
                )
            )
        )
        counts["projects"] = r.rowcount

        # Delete programs
        r = await db.execute(
            delete(Program).where(
                and_(
                    Program.organization_id == organization_id,
                    Program.is_demo == True,
                )
            )
        )
        counts["programs"] = r.rowcount

        # Delete portfolios
        r = await db.execute(
            delete(Portfolio).where(
                and_(
                    Portfolio.organization_id == organization_id,
                    Portfolio.is_demo == True,
                )
            )
        )
        counts["portfolios"] = r.rowcount

        await db.flush()
        logger.info(f"Cleared demo data for org {organization_id}: {counts}")
        return counts
