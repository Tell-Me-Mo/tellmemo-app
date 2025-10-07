"""Unified API endpoints for all summary operations across projects, programs, and portfolios."""

from fastapi import APIRouter, HTTPException, Depends, BackgroundTasks
from pydantic import BaseModel, Field
from typing import Optional, List, Literal
from datetime import datetime, timedelta
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_
import uuid

from utils.logger import get_logger, sanitize_for_log
from db.database import get_db
from services.summaries.summary_service_refactored import summary_service
from models.summary import Summary, SummaryType
from models.project import Project
from models.program import Program
from models.portfolio import Portfolio
from models.user import User
from models.organization import Organization
from services.core.upload_job_service import upload_job_service, JobType
from dependencies.auth import get_current_user, get_current_organization

router = APIRouter()
logger = get_logger(__name__)


class UnifiedSummaryRequest(BaseModel):
    """Unified request model for all summary generation."""
    entity_type: Literal["project", "program", "portfolio"] = Field(..., description="Type of entity")
    entity_id: str = Field(..., description="ID of the entity")
    summary_type: Literal["meeting", "project", "program", "portfolio"] = Field(..., description="Type of summary")
    content_id: Optional[str] = Field(None, description="Content ID for meeting summaries")
    date_range_start: Optional[datetime] = Field(None, description="Start date for summaries")
    date_range_end: Optional[datetime] = Field(None, description="End date for summaries")
    format: Optional[str] = Field("general", description="Summary format: 'general', 'executive', 'technical', or 'stakeholder'")
    created_by: Optional[str] = Field(None, description="User who requested the summary")
    use_job: Optional[bool] = Field(False, description="Use job-based async generation")


class UnifiedSummaryResponse(BaseModel):
    """Unified response model for all summaries."""
    summary_id: str
    entity_type: str
    entity_id: str
    entity_name: str
    project_id: Optional[str] = None  # Added for Flutter model compatibility
    content_id: Optional[str] = None
    summary_type: str
    subject: str
    body: str
    key_points: Optional[list] = None
    decisions: Optional[list] = None
    action_items: Optional[list] = None
    lessons_learned: Optional[list] = None  # Added lessons learned field
    sentiment_analysis: Optional[dict] = None
    risks: Optional[list] = None
    blockers: Optional[list] = None
    communication_insights: Optional[dict] = None
    cross_meeting_insights: Optional[dict] = None  # Added for program/portfolio metrics
    next_meeting_agenda: Optional[list] = None
    format: str = "general"
    token_count: Optional[int] = None
    generation_time_ms: Optional[int] = None
    llm_cost: Optional[float] = None
    created_at: str
    created_by: Optional[str] = None
    date_range_start: Optional[str] = None
    date_range_end: Optional[str] = None


class SummaryFilters(BaseModel):
    """Filters for querying summaries."""
    entity_type: Optional[Literal["project", "program", "portfolio"]] = None
    entity_id: Optional[str] = Field(None, description="Entity UUID or 'auto' to return all summaries for the organization")
    summary_type: Optional[str] = None
    format: Optional[str] = None
    created_after: Optional[datetime] = None
    created_before: Optional[datetime] = None
    limit: int = Field(100, le=500)
    offset: int = Field(0, ge=0)


@router.post(
    "/generate",
    response_model=UnifiedSummaryResponse,
    summary="Generate Unified Summary",
    description="Generate a summary for any entity type (project, program, portfolio). "
                "This is the preferred endpoint for all summary generation operations.",
    responses={
        200: {"description": "Summary generated successfully"},
        400: {"description": "Invalid request parameters"},
        404: {"description": "Entity not found"},
        500: {"description": "Internal server error"}
    }
)
async def generate_summary(
    request: UnifiedSummaryRequest,
    background_tasks: BackgroundTasks,
    session: AsyncSession = Depends(get_db),
    current_org: Organization = Depends(get_current_organization),
    current_user: User = Depends(get_current_user)
):
    """
    Generate a summary for any entity type (project, program, portfolio).

    This unified endpoint handles all summary generation operations:
    - **Meeting summaries**: For individual meeting content
    - **Weekly summaries**: For project progress over time
    - **Program summaries**: Aggregated insights from multiple projects
    - **Portfolio summaries**: High-level insights from multiple programs

    **Request Parameters:**
    - `entity_type`: The type of entity (project, program, portfolio)
    - `entity_id`: UUID of the entity
    - `summary_type`: Type of summary (meeting, weekly, program, portfolio)
    - `format`: Output format (general, executive, technical, stakeholder)
    - `use_job`: Whether to use background job processing

    **Response:**
    Returns either the generated summary or job information if `use_job=true`.
    """
    logger.info(f"Generating {sanitize_for_log(request.summary_type)} summary for {sanitize_for_log(request.entity_type)} {sanitize_for_log(request.entity_id)}")

    try:
        # Validate and convert entity_id to UUID
        try:
            entity_uuid = uuid.UUID(request.entity_id)
        except ValueError:
            raise HTTPException(status_code=400, detail=f"Invalid {request.entity_type} ID format")

        # Validate entity exists
        entity = None
        entity_name = "Unknown"

        if request.entity_type == "project":
            result = await session.execute(select(Project).where(Project.id == entity_uuid))
            entity = result.scalar_one_or_none()
            if entity:
                entity_name = entity.name
        elif request.entity_type == "program":
            result = await session.execute(select(Program).where(Program.id == entity_uuid))
            entity = result.scalar_one_or_none()
            if entity:
                entity_name = entity.name
        elif request.entity_type == "portfolio":
            result = await session.execute(select(Portfolio).where(Portfolio.id == entity_uuid))
            entity = result.scalar_one_or_none()
            if entity:
                entity_name = entity.name

        if not entity:
            raise HTTPException(status_code=404, detail=f"{request.entity_type.capitalize()} '{request.entity_id}' not found")

        # Validate summary type matches entity type
        if request.entity_type == "program" and request.summary_type not in ["program", "project"]:
            raise HTTPException(status_code=400, detail="Programs can only have program or project summaries")
        if request.entity_type == "portfolio" and request.summary_type not in ["portfolio", "project"]:
            raise HTTPException(status_code=400, detail="Portfolios can only have portfolio or project summaries")

        # Set default date range if not provided (ensure timezone-naive)
        if not request.date_range_start:
            request.date_range_start = datetime.now().replace(tzinfo=None) - timedelta(days=7)
        else:
            # Convert to timezone-naive if timezone-aware
            if request.date_range_start.tzinfo is not None:
                request.date_range_start = request.date_range_start.replace(tzinfo=None)

        if not request.date_range_end:
            request.date_range_end = datetime.now().replace(tzinfo=None)
        else:
            # Convert to timezone-naive if timezone-aware
            if request.date_range_end.tzinfo is not None:
                request.date_range_end = request.date_range_end.replace(tzinfo=None)

        # Handle job-based generation for long-running summaries
        if request.use_job and request.summary_type in ["project", "program", "portfolio"]:
            job_id = upload_job_service.create_job(
                project_id=str(entity_uuid),
                job_type=JobType.PROJECT_SUMMARY,
                filename=f"{request.summary_type}_summary_{request.date_range_start.strftime('%Y%m%d')}",
                metadata={
                    "entity_type": request.entity_type,
                    "entity_id": str(entity_uuid),
                    "summary_type": request.summary_type,
                    "format": request.format,
                    "date_range_start": request.date_range_start.isoformat(),
                    "date_range_end": request.date_range_end.isoformat(),
                    "created_by": current_user.email,
                    "created_by_id": str(current_user.id)
                },
                total_steps=3
            )

            # Start background task
            background_tasks.add_task(
                generate_summary_with_job,
                job_id,
                request,
                entity_uuid,
                entity_name
            )

            # Return job response
            return UnifiedSummaryResponse(
                summary_id=job_id,
                entity_type=request.entity_type,
                entity_id=str(entity_uuid),
                entity_name=entity_name,
                project_id=None,  # Added for Flutter model compatibility
                summary_type=request.summary_type.upper(),  # Convert to uppercase for Flutter enum
                subject=f"Generating {request.summary_type} summary...",
                body="Summary generation in progress. Check job status for updates.",
                format=request.format,
                created_at=datetime.now().isoformat(),
                created_by=request.created_by
            )

        # Direct generation
        summary_data = None

        if request.summary_type == "meeting":
            if not request.content_id:
                raise HTTPException(status_code=400, detail="content_id required for meeting summaries")

            # Validate content_id format
            try:
                content_uuid = uuid.UUID(request.content_id)
            except ValueError:
                raise HTTPException(status_code=400, detail="Invalid content_id format")

            summary_data = await summary_service.generate_meeting_summary(
                session=session,
                project_id=entity_uuid,
                content_id=content_uuid,
                created_by=current_user.email,
                created_by_id=str(current_user.id),
                format_type=request.format
            )

        elif request.summary_type == "project":
            if request.entity_type == "project":
                summary_data = await summary_service.generate_project_summary(
                    session=session,
                    project_id=entity_uuid,
                    week_start=request.date_range_start,
                    week_end=request.date_range_end,
                    created_by=current_user.email,
                    created_by_id=str(current_user.id),
                    format_type=request.format
                )
            else:
                # For programs and portfolios, aggregate their children
                raise HTTPException(status_code=501, detail="Project summaries for programs/portfolios not yet implemented")

        elif request.summary_type == "program":
            summary_data = await summary_service.generate_program_summary(
                session=session,
                program_id=entity_uuid,
                week_start=request.date_range_start,
                week_end=request.date_range_end,
                created_by=current_user.email,
                created_by_id=str(current_user.id),
                format_type=request.format
            )

        elif request.summary_type == "portfolio":
            summary_data = await summary_service.generate_portfolio_summary(
                session=session,
                portfolio_id=entity_uuid,
                week_start=request.date_range_start,
                week_end=request.date_range_end,
                created_by=current_user.email,
                created_by_id=str(current_user.id),
                format_type=request.format
            )

        # Convert to response - Include project_id for compatibility with Flutter model
        response_data = {
            "summary_id": summary_data.get("id", str(uuid.uuid4())),
            "entity_type": request.entity_type,
            "entity_id": str(entity_uuid),
            "entity_name": entity_name,
            "content_id": request.content_id,
            "summary_type": request.summary_type.upper(),  # Convert to uppercase for Flutter enum
            "subject": summary_data.get("subject", "Summary"),
            "body": summary_data.get("summary_text", ""),
            "key_points": summary_data.get("key_points"),
            "decisions": summary_data.get("decisions"),
            "action_items": summary_data.get("action_items"),
            "sentiment_analysis": summary_data.get("sentiment_analysis"),
            "risks": summary_data.get("risks"),
            "blockers": summary_data.get("blockers"),
            "communication_insights": summary_data.get("communication_insights"),
            "cross_meeting_insights": summary_data.get("cross_meeting_insights"),
            "next_meeting_agenda": summary_data.get("next_meeting_agenda"),
            "format": request.format,
            "token_count": summary_data.get("token_count"),
            "generation_time_ms": summary_data.get("generation_time_ms"),
            "llm_cost": summary_data.get("llm_cost"),
            "created_at": datetime.now().isoformat(),
            "created_by": request.created_by,
            "date_range_start": request.date_range_start.isoformat() if request.date_range_start else None,
            "date_range_end": request.date_range_end.isoformat() if request.date_range_end else None
        }

        # Add project_id field for Flutter model compatibility
        # For portfolio and program summaries, we'll use the entity_id as project_id
        if request.entity_type == "project":
            response_data["project_id"] = str(entity_uuid)
        elif request.entity_type in ["program", "portfolio"]:
            # For non-project entities, set project_id to None for Flutter model
            response_data["project_id"] = None

        return UnifiedSummaryResponse(**response_data)

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to generate summary: {sanitize_for_log(str(e))}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/{summary_id}", response_model=UnifiedSummaryResponse)
async def get_summary(
    summary_id: str,
    session: AsyncSession = Depends(get_db),
    current_org: Organization = Depends(get_current_organization)
):
    """Get any summary by ID, regardless of entity type."""
    logger.info(f"Fetching summary {sanitize_for_log(summary_id)}")

    try:
        summary_uuid = uuid.UUID(summary_id)

        result = await session.execute(
            select(Summary).where(Summary.id == summary_uuid)
        )
        summary = result.scalar_one_or_none()

        if not summary:
            raise HTTPException(status_code=404, detail="Summary not found")

        # Multi-tenant validation - ensure summary belongs to current organization
        if summary.organization_id != current_org.id:
            raise HTTPException(status_code=404, detail="Summary not found")

        # Determine entity type and get entity name
        entity_type = "unknown"
        entity_id = None
        entity_name = "Unknown"

        if summary.project_id:
            entity_type = "project"
            entity_id = summary.project_id
            project_result = await session.execute(
                select(Project).where(Project.id == summary.project_id)
            )
            project = project_result.scalar_one_or_none()
            if project:
                entity_name = project.name
        elif summary.program_id:
            entity_type = "program"
            entity_id = summary.program_id
            program_result = await session.execute(
                select(Program).where(Program.id == summary.program_id)
            )
            program = program_result.scalar_one_or_none()
            if program:
                entity_name = program.name
        elif summary.portfolio_id:
            entity_type = "portfolio"
            entity_id = summary.portfolio_id
            portfolio_result = await session.execute(
                select(Portfolio).where(Portfolio.id == summary.portfolio_id)
            )
            portfolio = portfolio_result.scalar_one_or_none()
            if portfolio:
                entity_name = portfolio.name

        return UnifiedSummaryResponse(
            summary_id=str(summary.id),
            entity_type=entity_type,
            entity_id=str(entity_id) if entity_id else "",
            entity_name=entity_name,
            project_id=str(summary.project_id) if summary.project_id else None,  # Added for Flutter compatibility
            content_id=str(summary.content_id) if summary.content_id else None,
            summary_type=summary.summary_type.value.upper(),
            subject=summary.subject,
            body=summary.body or "",
            key_points=summary.key_points,
            decisions=summary.decisions,
            action_items=summary.action_items,
            lessons_learned=summary.lessons_learned,  # Include lessons learned
            sentiment_analysis=summary.sentiment_analysis,
            risks=summary.risks,
            blockers=summary.blockers,
            communication_insights=summary.communication_insights,
            cross_meeting_insights=summary.cross_meeting_insights,  # Include program/portfolio metrics
            next_meeting_agenda=summary.next_meeting_agenda,
            format=getattr(summary, 'format', 'general'),
            token_count=summary.token_count,
            generation_time_ms=summary.generation_time_ms,
            llm_cost=getattr(summary, 'llm_cost', None),
            created_at=summary.created_at.isoformat(),
            created_by=summary.created_by,
            date_range_start=summary.date_range_start.isoformat() if summary.date_range_start else None,
            date_range_end=summary.date_range_end.isoformat() if summary.date_range_end else None
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to fetch summary: {sanitize_for_log(str(e))}")
        raise HTTPException(status_code=500, detail="Failed to fetch summary")


@router.post("/list", response_model=List[UnifiedSummaryResponse])
async def list_summaries(
    filters: SummaryFilters,
    session: AsyncSession = Depends(get_db),
    current_org: Organization = Depends(get_current_organization),
    current_user: User = Depends(get_current_user)
):
    """
    List summaries with flexible filtering.
    Can filter by entity type, entity ID, summary type, format, and date range.
    """
    logger.info(f"Listing summaries with filters: {sanitize_for_log(filters)}")

    try:
        # Build query
        query = select(Summary)

        # Apply filters
        conditions = []

        # Multi-tenant filtering - only show summaries from current organization
        conditions.append(Summary.organization_id == current_org.id)

        if filters.entity_type and filters.entity_id:
            # Handle special 'auto' project identifier
            # 'auto' is a sentinel value meaning "use AI to determine project"
            # When querying summaries with 'auto', skip entity filtering to return all summaries
            if filters.entity_id == "auto":
                logger.debug("Skipping entity_id filtering for 'auto' sentinel value")
                # Don't add any entity filter condition - will return all summaries for the organization
            else:
                # Normal UUID parsing
                try:
                    entity_uuid = uuid.UUID(filters.entity_id)
                    if filters.entity_type == "project":
                        conditions.append(Summary.project_id == entity_uuid)
                    elif filters.entity_type == "program":
                        conditions.append(Summary.program_id == entity_uuid)
                    elif filters.entity_type == "portfolio":
                        conditions.append(Summary.portfolio_id == entity_uuid)
                except ValueError:
                    logger.error(f"Invalid entity_id format: {sanitize_for_log(filters.entity_id)}")
                    raise HTTPException(status_code=400, detail="Invalid entity_id format. Expected UUID or 'auto'")

        if filters.summary_type:
            try:
                type_enum = SummaryType(filters.summary_type.lower())
                conditions.append(Summary.summary_type == type_enum)
            except ValueError:
                logger.warning(f"Invalid summary type filter: {sanitize_for_log(filters.summary_type)}")

        if filters.format:
            conditions.append(Summary.format == filters.format)

        if filters.created_after:
            conditions.append(Summary.created_at >= filters.created_after)

        if filters.created_before:
            conditions.append(Summary.created_at <= filters.created_before)

        if conditions:
            query = query.where(and_(*conditions))

        # Apply sorting and pagination
        query = query.order_by(Summary.created_at.desc())
        query = query.limit(filters.limit).offset(filters.offset)

        # Execute query
        result = await session.execute(query)
        summaries = result.scalars().all()

        # Convert to response format
        response_summaries = []
        for summary in summaries:
            # Determine entity type and get entity name
            entity_type = "unknown"
            entity_id = None
            entity_name = "Unknown"

            if summary.project_id:
                entity_type = "project"
                entity_id = summary.project_id
                # Batch fetch project names later for optimization
                entity_name = f"Project {summary.project_id}"
            elif summary.program_id:
                entity_type = "program"
                entity_id = summary.program_id
                entity_name = f"Program {summary.program_id}"
            elif summary.portfolio_id:
                entity_type = "portfolio"
                entity_id = summary.portfolio_id
                entity_name = f"Portfolio {summary.portfolio_id}"

            response_summaries.append(UnifiedSummaryResponse(
                summary_id=str(summary.id),
                entity_type=entity_type,
                entity_id=str(entity_id) if entity_id else "",
                entity_name=entity_name,
                project_id=str(summary.project_id) if summary.project_id else None,
                content_id=str(summary.content_id) if summary.content_id else None,
                summary_type=summary.summary_type.value.upper(),
                subject=summary.subject,
                body=summary.body or "",
                key_points=summary.key_points,
                decisions=summary.decisions,
                action_items=summary.action_items,
                sentiment_analysis=summary.sentiment_analysis,
                risks=summary.risks,
                blockers=summary.blockers,
                communication_insights=summary.communication_insights,
                next_meeting_agenda=summary.next_meeting_agenda,
                format=getattr(summary, 'format', 'general'),
                token_count=summary.token_count,
                generation_time_ms=summary.generation_time_ms,
                llm_cost=getattr(summary, 'llm_cost', None),
                created_at=summary.created_at.isoformat(),
                created_by=summary.created_by,
                date_range_start=summary.date_range_start.isoformat() if summary.date_range_start else None,
                date_range_end=summary.date_range_end.isoformat() if summary.date_range_end else None
            ))

        return response_summaries

    except Exception as e:
        logger.error(f"Failed to list summaries: {sanitize_for_log(str(e))}")
        raise HTTPException(status_code=500, detail="Failed to list summaries")


@router.delete("/{summary_id}")
async def delete_summary(
    summary_id: str,
    session: AsyncSession = Depends(get_db),
    current_org: Organization = Depends(get_current_organization)
):
    """Delete a summary by ID."""
    logger.info(f"Deleting summary {sanitize_for_log(summary_id)}")

    try:
        summary_uuid = uuid.UUID(summary_id)

        result = await session.execute(
            select(Summary).where(Summary.id == summary_uuid)
        )
        summary = result.scalar_one_or_none()

        if not summary:
            raise HTTPException(status_code=404, detail="Summary not found")

        # Multi-tenant validation - ensure summary belongs to current organization
        if summary.organization_id != current_org.id:
            raise HTTPException(status_code=404, detail="Summary not found")

        await session.delete(summary)
        await session.commit()

        return {"message": "Summary deleted successfully"}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to delete summary: {sanitize_for_log(str(e))}")
        await session.rollback()
        raise HTTPException(status_code=500, detail="Failed to delete summary")


async def generate_summary_with_job(
    job_id: str,
    request: UnifiedSummaryRequest,
    entity_uuid: uuid.UUID,
    entity_name: str
):
    """Background task to generate summary with job tracking."""
    try:
        # Import here to avoid circular dependency
        from db.database import db_manager

        # Get job to retrieve metadata with user info
        job = upload_job_service.get_job(job_id)
        if not job or not job.metadata:
            raise ValueError(f"Job {job_id} not found or missing metadata")

        # Extract created_by info from metadata
        created_by = job.metadata.get("created_by")
        created_by_id = job.metadata.get("created_by_id")

        if not created_by or not created_by_id:
            raise ValueError("Job metadata missing created_by or created_by_id")

        # Update job progress
        await upload_job_service.update_job_progress_async(
            job_id,
            progress=10.0,
            current_step=1,
            step_description="Initializing summary generation"
        )

        async with db_manager.sessionmaker() as session:
            # Update progress
            await upload_job_service.update_job_progress_async(
                job_id,
                progress=30.0,
                current_step=2,
                step_description="Collecting and analyzing data"
            )

            # Generate the summary based on type
            summary_data = None

            if request.summary_type == "program":
                summary_data = await summary_service.generate_program_summary(
                    session=session,
                    program_id=entity_uuid,
                    week_start=request.date_range_start,
                    week_end=request.date_range_end,
                    created_by=created_by,
                    created_by_id=created_by_id,
                    format_type=request.format
                )
            elif request.summary_type == "portfolio":
                summary_data = await summary_service.generate_portfolio_summary(
                    session=session,
                    portfolio_id=entity_uuid,
                    week_start=request.date_range_start,
                    week_end=request.date_range_end,
                    created_by=created_by,
                    created_by_id=created_by_id,
                    format_type=request.format
                )
            elif request.summary_type == "project":
                summary_data = await summary_service.generate_project_summary(
                    session=session,
                    project_id=entity_uuid,
                    week_start=request.date_range_start,
                    week_end=request.date_range_end,
                    created_by=created_by,
                    created_by_id=created_by_id,
                    format_type=request.format
                )

            # Update progress
            await upload_job_service.update_job_progress_async(
                job_id,
                progress=90.0,
                current_step=3,
                step_description="Finalizing summary"
            )

            # Complete job
            await upload_job_service.complete_job(
                job_id,
                result={
                    "summary_id": summary_data.get("id"),
                    "entity_type": request.entity_type,
                    "entity_id": str(entity_uuid),
                    "entity_name": entity_name,
                    "summary_type": request.summary_type
                }
            )

    except Exception as e:
        logger.error(f"Failed to generate summary in job {job_id}: {sanitize_for_log(str(e))}")
        await upload_job_service.fail_job(
            job_id,
            error_message="Failed to generate summary"
        )


class UpdateSummaryRequest(BaseModel):
    """Request model for updating summary fields."""
    subject: Optional[str] = None
    body: Optional[str] = None
    key_points: Optional[List[str]] = None
    decisions: Optional[List[dict]] = None
    action_items: Optional[List[dict]] = None
    sentiment_analysis: Optional[dict] = None
    risks: Optional[list] = None
    blockers: Optional[list] = None
    format: Optional[str] = None


@router.put(
    "/{summary_id}",
    response_model=UnifiedSummaryResponse,
    summary="Update Summary",
    description="Update an existing summary's fields",
    responses={
        200: {"description": "Summary updated successfully"},
        404: {"description": "Summary not found"},
        400: {"description": "Invalid request parameters"}
    }
)
async def update_summary(
    summary_id: str,
    update_request: UpdateSummaryRequest,
    session: AsyncSession = Depends(get_db),
    current_org: Organization = Depends(get_current_organization)
):
    """
    Update an existing summary's fields.

    Only the provided fields will be updated, others remain unchanged.
    """
    logger.info(f"Updating summary {sanitize_for_log(summary_id)}")

    try:
        # Validate and convert summary_id to UUID
        try:
            summary_uuid = uuid.UUID(summary_id)
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid summary ID format")

        # Get the existing summary
        result = await session.execute(
            select(Summary).where(Summary.id == summary_uuid)
        )
        summary = result.scalar_one_or_none()

        if not summary:
            raise HTTPException(status_code=404, detail=f"Summary '{summary_id}' not found")

        # Multi-tenant validation - ensure summary belongs to current organization
        if summary.organization_id != current_org.id:
            raise HTTPException(status_code=404, detail=f"Summary '{summary_id}' not found")

        # Update fields if provided
        if update_request.subject is not None:
            summary.subject = update_request.subject

        if update_request.body is not None:
            summary.body = update_request.body

        if update_request.key_points is not None:
            summary.key_points = update_request.key_points

        if update_request.decisions is not None:
            summary.decisions = update_request.decisions

        if update_request.action_items is not None:
            summary.action_items = update_request.action_items

        if update_request.sentiment_analysis is not None:
            summary.sentiment_analysis = update_request.sentiment_analysis

        if update_request.risks is not None:
            summary.risks = update_request.risks

        if update_request.blockers is not None:
            summary.blockers = update_request.blockers

        if update_request.format is not None:
            summary.format = update_request.format

        # Save changes
        await session.commit()
        await session.refresh(summary)

        # Get entity details for response
        entity_type = ""
        entity_id = ""
        entity_name = "Unknown"

        if summary.project_id:
            entity_type = "project"
            entity_id = str(summary.project_id)
            project_result = await session.execute(
                select(Project).where(Project.id == summary.project_id)
            )
            project = project_result.scalar_one_or_none()
            if project:
                entity_name = project.name
        elif summary.program_id:
            entity_type = "program"
            entity_id = str(summary.program_id)
            program_result = await session.execute(
                select(Program).where(Program.id == summary.program_id)
            )
            program = program_result.scalar_one_or_none()
            if program:
                entity_name = program.name
        elif summary.portfolio_id:
            entity_type = "portfolio"
            entity_id = str(summary.portfolio_id)
            portfolio_result = await session.execute(
                select(Portfolio).where(Portfolio.id == summary.portfolio_id)
            )
            portfolio = portfolio_result.scalar_one_or_none()
            if portfolio:
                entity_name = portfolio.name

        # Build response
        return UnifiedSummaryResponse(
            summary_id=str(summary.id),
            entity_type=entity_type,
            entity_id=entity_id,
            entity_name=entity_name,
            project_id=str(summary.project_id) if summary.project_id else None,
            content_id=str(summary.content_id) if summary.content_id else None,
            summary_type=summary.summary_type.value,
            subject=summary.subject,
            body=summary.body,
            key_points=summary.key_points,
            decisions=summary.decisions,
            action_items=summary.action_items,
            sentiment_analysis=summary.sentiment_analysis,
            risks=summary.risks,
            blockers=summary.blockers,
            communication_insights=summary.communication_insights,
            cross_meeting_insights=summary.cross_meeting_insights,
            next_meeting_agenda=summary.next_meeting_agenda,
            format=summary.format,
            token_count=summary.token_count,
            generation_time_ms=summary.generation_time_ms,
            llm_cost=None,  # Field doesn't exist in model
            created_at=summary.created_at.isoformat() if summary.created_at else "",
            created_by=summary.created_by,
            date_range_start=summary.date_range_start.isoformat() if summary.date_range_start else None,
            date_range_end=summary.date_range_end.isoformat() if summary.date_range_end else None
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to update summary {sanitize_for_log(summary_id)}: {sanitize_for_log(str(e))}")
        await session.rollback()
        raise HTTPException(status_code=500, detail="Failed to update summary")