"""API endpoints for lessons learned management."""

from typing import List, Optional
from uuid import UUID
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_, or_, func
from sqlalchemy.orm import selectinload

from db.database import get_db
from dependencies.auth import get_current_organization, get_current_user
from models.organization import Organization
from models.user import User
from models.lesson_learned import LessonLearned, LessonCategory, LessonType, LessonLearnedImpact
from models.project import Project
from utils.logger import get_logger
from utils.monitoring import monitor_operation
from pydantic import BaseModel
from datetime import datetime

logger = get_logger(__name__)
router = APIRouter(prefix="/api", tags=["lessons-learned"])


class LessonLearnedCreate(BaseModel):
    """Schema for creating a lesson learned."""
    title: str
    description: str
    category: str = "other"
    lesson_type: str = "improvement"
    impact: str = "medium"
    recommendation: Optional[str] = None
    context: Optional[str] = None
    tags: Optional[str] = None


class LessonLearnedUpdate(BaseModel):
    """Schema for updating a lesson learned."""
    title: Optional[str] = None
    description: Optional[str] = None
    category: Optional[str] = None
    lesson_type: Optional[str] = None
    impact: Optional[str] = None
    recommendation: Optional[str] = None
    context: Optional[str] = None
    tags: Optional[str] = None


class LessonLearnedResponse(BaseModel):
    """Schema for lesson learned response."""
    id: str
    project_id: str
    title: str
    description: str
    category: str
    lesson_type: str
    impact: str
    recommendation: Optional[str]
    context: Optional[str]
    tags: List[str]
    ai_generated: bool
    ai_confidence: Optional[float]
    source_content_id: Optional[str]
    identified_date: Optional[datetime]
    last_updated: Optional[datetime]
    updated_by: Optional[str]


@router.get("/projects/{project_id}/lessons-learned", response_model=List[LessonLearnedResponse])
@monitor_operation("get_project_lessons_learned", "api")
async def get_project_lessons_learned(
    project_id: UUID,
    category: Optional[str] = Query(None),
    lesson_type: Optional[str] = Query(None),
    impact: Optional[str] = Query(None),
    db: AsyncSession = Depends(get_db)
):
    """Get all lessons learned for a project with optional filtering."""
    try:
        # Build query with filters
        query = select(LessonLearned).where(LessonLearned.project_id == project_id)

        if category:
            query = query.where(LessonLearned.category == LessonCategory(category))

        if lesson_type:
            query = query.where(LessonLearned.lesson_type == LessonType(lesson_type))

        if impact:
            query = query.where(LessonLearned.impact == LessonLearnedImpact(impact))

        # Order by identified date (most recent first)
        query = query.order_by(LessonLearned.identified_date.desc())

        result = await db.execute(query)
        lessons = result.scalars().all()

        return [
            LessonLearnedResponse(
                id=str(lesson.id),
                project_id=str(lesson.project_id),
                title=lesson.title,
                description=lesson.description,
                category=lesson.category.value if lesson.category else "other",
                lesson_type=lesson.lesson_type.value if lesson.lesson_type else "improvement",
                impact=lesson.impact.value if lesson.impact else "medium",
                recommendation=lesson.recommendation,
                context=lesson.context,
                tags=lesson.tags.split(',') if lesson.tags else [],
                ai_generated=lesson.ai_generated == "true",
                ai_confidence=lesson.ai_confidence,
                source_content_id=str(lesson.source_content_id) if lesson.source_content_id else None,
                identified_date=lesson.identified_date,
                last_updated=lesson.last_updated,
                updated_by=lesson.updated_by
            )
            for lesson in lessons
        ]

    except Exception as e:
        logger.error(f"Failed to get lessons learned for project {project_id}: {e}")
        raise HTTPException(status_code=500, detail="Failed to retrieve lessons learned")


@router.post("/projects/{project_id}/lessons-learned", response_model=LessonLearnedResponse)
@monitor_operation("create_lesson_learned", "api")
async def create_lesson_learned(
    project_id: UUID,
    lesson_data: LessonLearnedCreate,
    db: AsyncSession = Depends(get_db)
):
    """Create a new lesson learned for a project."""
    try:
        # Verify project exists
        project_result = await db.execute(
            select(Project).where(Project.id == project_id)
        )
        project = project_result.scalar_one_or_none()

        if not project:
            raise HTTPException(status_code=404, detail="Project not found")

        # Create lesson learned
        lesson = LessonLearned(
            project_id=project_id,
            title=lesson_data.title,
            description=lesson_data.description,
            category=LessonCategory(lesson_data.category),
            lesson_type=LessonType(lesson_data.lesson_type),
            impact=LessonLearnedImpact(lesson_data.impact),
            recommendation=lesson_data.recommendation,
            context=lesson_data.context,
            tags=lesson_data.tags,
            ai_generated="false",
            updated_by="manual",
            identified_date=datetime.utcnow(),
            last_updated=datetime.utcnow()
        )

        db.add(lesson)
        await db.commit()
        await db.refresh(lesson)

        logger.info(f"Created lesson learned {lesson.id} for project {project_id}")

        return LessonLearnedResponse(
            id=str(lesson.id),
            project_id=str(lesson.project_id),
            title=lesson.title,
            description=lesson.description,
            category=lesson.category.value,
            lesson_type=lesson.lesson_type.value,
            impact=lesson.impact.value,
            recommendation=lesson.recommendation,
            context=lesson.context,
            tags=lesson.tags.split(',') if lesson.tags else [],
            ai_generated=False,
            ai_confidence=None,
            source_content_id=None,
            identified_date=lesson.identified_date,
            last_updated=lesson.last_updated,
            updated_by=lesson.updated_by
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to create lesson learned for project {project_id}: {e}")
        raise HTTPException(status_code=500, detail="Failed to create lesson learned")


@router.put("/lessons-learned/{lesson_id}", response_model=LessonLearnedResponse)
@monitor_operation("update_lesson_learned", "api")
async def update_lesson_learned(
    lesson_id: UUID,
    lesson_data: LessonLearnedUpdate,
    db: AsyncSession = Depends(get_db)
):
    """Update an existing lesson learned."""
    try:
        # Get lesson learned
        result = await db.execute(
            select(LessonLearned).where(LessonLearned.id == lesson_id)
        )
        lesson = result.scalar_one_or_none()

        if not lesson:
            raise HTTPException(status_code=404, detail="Lesson learned not found")

        # Update fields
        if lesson_data.title is not None:
            lesson.title = lesson_data.title
        if lesson_data.description is not None:
            lesson.description = lesson_data.description
        if lesson_data.category is not None:
            lesson.category = LessonCategory(lesson_data.category)
        if lesson_data.lesson_type is not None:
            lesson.lesson_type = LessonType(lesson_data.lesson_type)
        if lesson_data.impact is not None:
            lesson.impact = LessonLearnedImpact(lesson_data.impact)
        if lesson_data.recommendation is not None:
            lesson.recommendation = lesson_data.recommendation
        if lesson_data.context is not None:
            lesson.context = lesson_data.context
        if lesson_data.tags is not None:
            lesson.tags = lesson_data.tags

        lesson.last_updated = datetime.utcnow()
        lesson.updated_by = "manual"

        await db.commit()
        await db.refresh(lesson)

        logger.info(f"Updated lesson learned {lesson_id}")

        return LessonLearnedResponse(
            id=str(lesson.id),
            project_id=str(lesson.project_id),
            title=lesson.title,
            description=lesson.description,
            category=lesson.category.value,
            lesson_type=lesson.lesson_type.value,
            impact=lesson.impact.value,
            recommendation=lesson.recommendation,
            context=lesson.context,
            tags=lesson.tags.split(',') if lesson.tags else [],
            ai_generated=lesson.ai_generated == "true",
            ai_confidence=lesson.ai_confidence,
            source_content_id=str(lesson.source_content_id) if lesson.source_content_id else None,
            identified_date=lesson.identified_date,
            last_updated=lesson.last_updated,
            updated_by=lesson.updated_by
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to update lesson learned {lesson_id}: {e}")
        raise HTTPException(status_code=500, detail="Failed to update lesson learned")


@router.delete("/lessons-learned/{lesson_id}")
@monitor_operation("delete_lesson_learned", "api")
async def delete_lesson_learned(
    lesson_id: UUID,
    db: AsyncSession = Depends(get_db)
):
    """Delete a lesson learned."""
    try:
        # Get lesson learned
        result = await db.execute(
            select(LessonLearned).where(LessonLearned.id == lesson_id)
        )
        lesson = result.scalar_one_or_none()

        if not lesson:
            raise HTTPException(status_code=404, detail="Lesson learned not found")

        await db.delete(lesson)
        await db.commit()

        logger.info(f"Deleted lesson learned {lesson_id}")

        return {"message": "Lesson learned deleted successfully"}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to delete lesson learned {lesson_id}: {e}")
        raise HTTPException(status_code=500, detail="Failed to delete lesson learned")


@router.post("/projects/{project_id}/lessons-learned/batch")
@monitor_operation("batch_create_lessons_learned", "api")
async def batch_create_lessons_learned(
    project_id: UUID,
    lessons_data: List[dict],
    source_content_id: Optional[UUID] = None,
    db: AsyncSession = Depends(get_db)
):
    """Create multiple lessons learned from AI extraction."""
    try:
        # Verify project exists
        project_result = await db.execute(
            select(Project).where(Project.id == project_id)
        )
        project = project_result.scalar_one_or_none()

        if not project:
            raise HTTPException(status_code=404, detail="Project not found")

        created_lessons = []

        for lesson_data in lessons_data:
            lesson = LessonLearned(
                project_id=project_id,
                title=lesson_data.get('title'),
                description=lesson_data.get('description'),
                category=LessonCategory(lesson_data.get('category', 'other')),
                lesson_type=LessonType(lesson_data.get('lesson_type', 'improvement')),
                impact=LessonLearnedImpact(lesson_data.get('impact', 'medium')),
                recommendation=lesson_data.get('recommendation'),
                context=lesson_data.get('context'),
                tags=lesson_data.get('tags'),
                ai_generated="true",
                ai_confidence=lesson_data.get('ai_confidence', lesson_data.get('confidence', 0.7)),
                source_content_id=source_content_id,
                updated_by="ai",
                identified_date=datetime.utcnow(),
                last_updated=datetime.utcnow()
            )

            db.add(lesson)
            created_lessons.append(lesson)

        await db.commit()

        # Refresh all lessons
        for lesson in created_lessons:
            await db.refresh(lesson)

        logger.info(f"Created {len(created_lessons)} lessons learned for project {project_id}")

        return {
            "message": f"Created {len(created_lessons)} lessons learned",
            "lessons": [lesson.to_dict() for lesson in created_lessons]
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to batch create lessons learned for project {project_id}: {e}")
        raise HTTPException(status_code=500, detail="Failed to create lessons learned")