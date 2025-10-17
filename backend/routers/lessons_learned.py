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
from utils.logger import get_logger, sanitize_for_log
from pydantic import BaseModel
from datetime import datetime
from services.item_updates_service import ItemUpdatesService

logger = get_logger(__name__)
router = APIRouter(prefix="/api/v1", tags=["lessons-learned"])


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
async def get_project_lessons_learned(
    project_id: UUID,
    category: Optional[str] = Query(None),
    lesson_type: Optional[str] = Query(None),
    impact: Optional[str] = Query(None),
    current_user: User = Depends(get_current_user),
    current_org: Organization = Depends(get_current_organization),
    db: AsyncSession = Depends(get_db)
):
    """Get all lessons learned for a project with optional filtering."""
    try:
        # Verify project exists and belongs to user's organization
        project_result = await db.execute(
            select(Project).where(Project.id == project_id)
        )
        project = project_result.scalar_one_or_none()

        if not project or project.organization_id != current_org.id:
            raise HTTPException(status_code=404, detail="Project not found")

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

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get lessons learned for project {sanitize_for_log(project_id)}: {e}")
        raise HTTPException(status_code=500, detail="Failed to retrieve lessons learned")


@router.post("/projects/{project_id}/lessons-learned", response_model=LessonLearnedResponse)
async def create_lesson_learned(
    project_id: UUID,
    lesson_data: LessonLearnedCreate,
    current_user: User = Depends(get_current_user),
    current_org: Organization = Depends(get_current_organization),
    db: AsyncSession = Depends(get_db)
):
    """Create a new lesson learned for a project."""
    try:
        # Verify project exists and belongs to user's organization
        project_result = await db.execute(
            select(Project).where(Project.id == project_id)
        )
        project = project_result.scalar_one_or_none()

        if not project or project.organization_id != current_org.id:
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

        # Create CREATED update
        author_name = current_user.name or current_user.email or "User"
        await ItemUpdatesService.create_item_created_update(
            db=db,
            project_id=project_id,
            item_id=lesson.id,
            item_type='lessons',
            item_title=lesson.title,
            author_name=author_name,
            author_email=current_user.email,
            ai_generated=False
        )
        await db.commit()

        logger.info(f"Created lesson learned {sanitize_for_log(lesson.id)} for project {sanitize_for_log(project_id)}")

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
        logger.error(f"Failed to create lesson learned for project {sanitize_for_log(project_id)}: {e}")
        raise HTTPException(status_code=500, detail="Failed to create lesson learned")


@router.put("/lessons-learned/{lesson_id}", response_model=LessonLearnedResponse)
async def update_lesson_learned(
    lesson_id: UUID,
    lesson_data: LessonLearnedUpdate,
    current_user: User = Depends(get_current_user),
    current_org: Organization = Depends(get_current_organization),
    db: AsyncSession = Depends(get_db)
):
    """Update an existing lesson learned."""
    try:
        # Get lesson learned with project to verify organization
        result = await db.execute(
            select(LessonLearned)
            .options(selectinload(LessonLearned.project))
            .where(LessonLearned.id == lesson_id)
        )
        lesson = result.scalar_one_or_none()

        if not lesson:
            raise HTTPException(status_code=404, detail="Lesson learned not found")

        # Verify lesson's project belongs to user's organization
        if lesson.project.organization_id != current_org.id:
            raise HTTPException(status_code=404, detail="Lesson learned not found")

        # Build update data dict
        update_data = {}
        if lesson_data.title is not None:
            update_data['title'] = lesson_data.title
        if lesson_data.description is not None:
            update_data['description'] = lesson_data.description
        if lesson_data.category is not None:
            update_data['category'] = LessonCategory(lesson_data.category)
        if lesson_data.lesson_type is not None:
            update_data['lesson_type'] = LessonType(lesson_data.lesson_type)
        if lesson_data.impact is not None:
            update_data['impact'] = LessonLearnedImpact(lesson_data.impact)
        if lesson_data.recommendation is not None:
            update_data['recommendation'] = lesson_data.recommendation
        if lesson_data.context is not None:
            update_data['context'] = lesson_data.context
        if lesson_data.tags is not None:
            update_data['tags'] = lesson_data.tags

        # Track field changes
        author_name = current_user.name or current_user.email or "User"
        changes = ItemUpdatesService.detect_changes(lesson, update_data)
        if changes:
            await ItemUpdatesService.track_field_changes(
                db=db,
                project_id=lesson.project_id,
                item_id=lesson.id,
                item_type='lessons',
                changes=changes,
                author_name=author_name,
                author_email=current_user.email
            )

        # Apply updates
        for key, value in update_data.items():
            if hasattr(lesson, key):
                setattr(lesson, key, value)

        lesson.last_updated = datetime.utcnow()
        lesson.updated_by = "manual"

        await db.commit()
        await db.refresh(lesson)

        logger.info(f"Updated lesson learned {sanitize_for_log(lesson_id)}")

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
        logger.error(f"Failed to update lesson learned {sanitize_for_log(lesson_id)}: {e}")
        raise HTTPException(status_code=500, detail="Failed to update lesson learned")


@router.delete("/lessons-learned/{lesson_id}")
async def delete_lesson_learned(
    lesson_id: UUID,
    current_user: User = Depends(get_current_user),
    current_org: Organization = Depends(get_current_organization),
    db: AsyncSession = Depends(get_db)
):
    """Delete a lesson learned."""
    try:
        # Get lesson learned with project to verify organization
        result = await db.execute(
            select(LessonLearned)
            .options(selectinload(LessonLearned.project))
            .where(LessonLearned.id == lesson_id)
        )
        lesson = result.scalar_one_or_none()

        if not lesson:
            raise HTTPException(status_code=404, detail="Lesson learned not found")

        # Verify lesson's project belongs to user's organization
        if lesson.project.organization_id != current_org.id:
            raise HTTPException(status_code=404, detail="Lesson learned not found")

        await db.delete(lesson)
        await db.commit()

        logger.info(f"Deleted lesson learned {sanitize_for_log(lesson_id)}")

        return {"message": "Lesson learned deleted successfully"}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to delete lesson learned {sanitize_for_log(lesson_id)}: {e}")
        raise HTTPException(status_code=500, detail="Failed to delete lesson learned")


@router.post("/projects/{project_id}/lessons-learned/batch")
async def batch_create_lessons_learned(
    project_id: UUID,
    lessons_data: List[dict],
    source_content_id: Optional[UUID] = Query(None),
    current_user: User = Depends(get_current_user),
    current_org: Organization = Depends(get_current_organization),
    db: AsyncSession = Depends(get_db)
):
    """Create multiple lessons learned from AI extraction."""
    try:
        # Verify project exists and belongs to user's organization
        project_result = await db.execute(
            select(Project).where(Project.id == project_id)
        )
        project = project_result.scalar_one_or_none()

        if not project or project.organization_id != current_org.id:
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

        logger.info(f"Created {len(created_lessons)} lessons learned for project {sanitize_for_log(project_id)}")

        return {
            "message": f"Created {len(created_lessons)} lessons learned",
            "lessons": [lesson.to_dict() for lesson in created_lessons]
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to batch create lessons learned for project {sanitize_for_log(project_id)}: {e}")
        raise HTTPException(status_code=500, detail="Failed to create lessons learned")


# ItemUpdate endpoints for lessons
from models.item_update import ItemUpdate, ItemUpdateType
from pydantic import BaseModel as PydanticBase, validator


class ItemUpdateCreate(PydanticBase):
    content: str
    update_type: str = ItemUpdateType.COMMENT  # Now using string with default
    author_name: str
    author_email: Optional[str] = None

    @validator('update_type')
    def validate_update_type(cls, v):
        """Validate that update_type is one of the allowed values."""
        if not ItemUpdateType.is_valid(v):
            raise ValueError(f"Invalid update_type. Must be one of: {', '.join(ItemUpdateType.ALL_TYPES)}")
        return v


@router.get("/projects/{project_id}/lessons/{lesson_id}/updates")
async def get_lesson_updates(
    project_id: UUID,
    lesson_id: UUID,
    current_user: User = Depends(get_current_user),
    current_org: Organization = Depends(get_current_organization),
    db: AsyncSession = Depends(get_db)
):
    """Get all updates for a specific lesson learned."""
    try:
        # Verify project belongs to organization
        project_result = await db.execute(
            select(Project).where(
                and_(
                    Project.id == project_id,
                    Project.organization_id == current_org.id
                )
            )
        )
        project = project_result.scalar_one_or_none()
        if not project:
            raise HTTPException(status_code=404, detail="Project not found")

        # Query item updates - ordered by most recent first
        query = select(ItemUpdate).where(
            and_(
                ItemUpdate.project_id == project_id,
                ItemUpdate.item_id == lesson_id,
                ItemUpdate.item_type == 'lessons'
            )
        ).order_by(ItemUpdate.timestamp.desc())

        result = await db.execute(query)
        updates = result.scalars().all()

        return [update.to_dict() for update in updates]

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get lesson updates for {sanitize_for_log(lesson_id)}: {e}")
        raise HTTPException(status_code=500, detail="Failed to retrieve lesson updates")


@router.post("/projects/{project_id}/lessons/{lesson_id}/updates")
async def create_lesson_update(
    project_id: UUID,
    lesson_id: UUID,
    update_data: ItemUpdateCreate,
    current_user: User = Depends(get_current_user),
    current_org: Organization = Depends(get_current_organization),
    db: AsyncSession = Depends(get_db)
):
    """Create a new update/comment for a lesson learned."""
    try:
        # Verify project belongs to organization
        project_result = await db.execute(
            select(Project).where(
                and_(
                    Project.id == project_id,
                    Project.organization_id == current_org.id
                )
            )
        )
        project = project_result.scalar_one_or_none()
        if not project:
            raise HTTPException(status_code=404, detail="Project not found")

        # Create update
        new_update = ItemUpdate(
            project_id=project_id,
            item_id=lesson_id,
            item_type='lessons',
            content=update_data.content,
            update_type=update_data.update_type,
            author_name=update_data.author_name,
            author_email=update_data.author_email,
            timestamp=datetime.utcnow()
        )

        db.add(new_update)
        await db.commit()
        await db.refresh(new_update)

        logger.info(f"Created update for lesson {sanitize_for_log(lesson_id)}")

        return new_update.to_dict()

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to create lesson update for {sanitize_for_log(lesson_id)}: {e}")
        raise HTTPException(status_code=500, detail="Failed to create lesson update")