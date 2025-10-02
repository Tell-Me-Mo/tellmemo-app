"""Summary generation service refactored with Langfuse v3 context managers."""

import uuid
import time
from datetime import datetime, timedelta, timezone
from typing import Dict, Any, Optional, List
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_, or_

from config import get_settings
from utils.logger import (
    get_logger,
    SummaryGenerationLogger,
    get_correlation_id,
    log_execution_time,
    LogComponent
)
from utils.exceptions import (
    LLMOverloadedException,
    LLMRateLimitException,
    LLMAuthenticationException,
    LLMTimeoutException,
    InsufficientDataException
)
from utils.retry import async_retry, RetryConfig
from models.summary import Summary, SummaryType
from models.content import Content
from models.project import Project
from models.program import Program
from models.portfolio import Portfolio
from services.observability.langfuse_service import langfuse_service
from services.activity.activity_service import ActivityService
from services.core.upload_job_service import upload_job_service
from services.llm.multi_llm_client import get_multi_llm_client
from services.prompts.summary_prompts import (
    get_meeting_summary_prompt,
    get_project_summary_prompt,
    get_program_summary_prompt,
    get_portfolio_summary_prompt
)

logger = get_logger(__name__)
structured_logger = SummaryGenerationLogger(__name__)


class SummaryService:
    """Service for generating meeting and weekly summaries using Claude API with proper Langfuse v3 integration."""

    def __init__(self):
        """Initialize the summary service with configuration."""
        settings = get_settings()
        self.llm_model = settings.llm_model
        self.max_tokens = settings.max_tokens
        self.temperature = settings.temperature

        # Use multi-provider LLM client
        self.llm_client = get_multi_llm_client(settings)

        if not self.llm_client.is_available():
            logger.warning("LLM client not available, summary generation will use placeholder responses")
    
    async def generate_meeting_summary(
        self,
        session: AsyncSession,
        project_id: uuid.UUID,
        content_id: uuid.UUID,
        created_by: Optional[str] = None,
        created_by_id: Optional[str] = None,
        job_id: Optional[str] = None,
        format_type: str = "general"
    ) -> Dict[str, Any]:
        """Generate a meeting summary with proper Langfuse v3 context managers."""
        start_time = time.time()
        correlation_id = get_correlation_id()

        # Log generation start
        structured_logger.log_generation_start(
            entity_type="project",
            entity_id=str(project_id),
            summary_type="meeting",
            format_type=format_type,
            correlation_id=correlation_id
        )
        
        # Check if Langfuse client supports context managers
        langfuse_client = langfuse_service.client
        if not langfuse_client or not hasattr(langfuse_client, 'start_as_current_span'):
            # Fallback to simpler implementation
            return await self._generate_meeting_summary_fallback(
                session, project_id, content_id, created_by, job_id
            )
        
        try:
            # Use Langfuse v3 context manager for proper span nesting
            with langfuse_client.start_as_current_span(
                name="generate_meeting_summary",
                input={
                    "project_id": str(project_id),
                    "content_id": str(content_id),
                    "created_by": created_by
                },
                metadata={
                    "summary_type": "meeting"
                },
                version="2.0.0"
            ) as trace_span:
                
                # Update progress: Starting summary generation (91%)
                if job_id:
                    upload_job_service.update_job_progress(
                        job_id,
                        progress=91.0,
                        step_description="Starting summary generation"
                    )
                
                # Validate project exists
                project = None
                with langfuse_client.start_as_current_span(
                    name="validate_project"
                ) as validate_span:
                    with structured_logger.timer("validate_project", correlation_id=correlation_id):
                        project_result = await session.execute(
                            select(Project).where(Project.id == project_id)
                        )
                        project = project_result.scalar_one_or_none()
                        if not project:
                            structured_logger.error(
                                f"Project {project_id} not found",
                                correlation_id=correlation_id,
                                project_id=str(project_id)
                            )
                            raise ValueError(f"Project {project_id} not found")
                        structured_logger.info(
                            f"Found project: {project.name}",
                            correlation_id=correlation_id,
                            project_name=project.name
                        )
                    
                    if hasattr(validate_span, 'update'):
                        validate_span.update(
                            output={"project_name": project.name}
                        )
                
                # Update progress: Fetching content (92%)
                if job_id:
                    upload_job_service.update_job_progress(
                        job_id,
                        progress=92.0,
                        step_description="Fetching content for summary"
                    )
                
                # Get content to summarize
                content = None
                with langfuse_client.start_as_current_span(
                    name="fetch_content"
                ) as content_span:
                    with structured_logger.timer("fetch_content", correlation_id=correlation_id):
                        content_result = await session.execute(
                        select(Content).where(
                            and_(Content.id == content_id, Content.project_id == project_id)
                        )
                    )
                        content = content_result.scalar_one_or_none()
                        if not content:
                            structured_logger.error(
                                f"Content {content_id} not found in project {project_id}",
                                correlation_id=correlation_id,
                                content_id=str(content_id),
                                project_id=str(project_id)
                            )
                            raise ValueError(f"Content {content_id} not found in project {project_id}")
                        structured_logger.info(
                            f"Found content: {content.title}",
                            correlation_id=correlation_id,
                            content_title=content.title,
                            content_length=len(content.content) if content.content else 0
                        )
                    
                    if hasattr(content_span, 'update'):
                        content_span.update(
                            output={
                                "content_title": content.title,
                                "content_length": len(content.content)
                            }
                        )
                
                # Update progress: Generating summary with AI (93%)
                if job_id:
                    upload_job_service.update_job_progress(
                        job_id,
                        progress=93.0,
                        step_description="Analyzing with AI"
                    )
                
                # Generate summary using Claude API
                llm_start = time.time()
                structured_logger.info(
                    "Starting LLM generation",
                    correlation_id=correlation_id,
                    model=self.llm_model,
                    format_type=format_type
                )
                summary_data = await self._generate_claude_summary_with_context(
                    content_type="meeting",
                    project_name=project.name,
                    content_title=content.title,
                    content_text=content.content,
                    content_date=content.date,
                    job_id=job_id,
                    format_type=format_type
                )
                llm_duration = (time.time() - llm_start) * 1000
                structured_logger.info(
                    "LLM generation completed",
                    correlation_id=correlation_id,
                    duration_ms=llm_duration,
                    token_count=summary_data.get("token_count", 0)
                )
                
                # Update progress: Processing AI response (97%)
                if job_id:
                    upload_job_service.update_job_progress(
                        job_id,
                        progress=97.0,
                        step_description="Extracting insights"
                    )
                
                # Process Claude's extracted intelligence (sentiment, risks, blockers)
                sentiment_data = None
                risks_blockers_data = None
                with langfuse_client.start_as_current_span(
                    name="process_claude_intelligence"
                ) as intelligence_span:
                    try:
                        # Process sentiment analysis from Claude's response
                        sentiment_data = self._process_claude_sentiment(summary_data)
                        if sentiment_data:
                            logger.info(f"Processed Claude-extracted sentiment: {sentiment_data.get('overall', 'unknown')}")
                        
                        # Process risks and blockers from Claude's response
                        risks_blockers_data = self._process_claude_risks_blockers(summary_data)
                        if risks_blockers_data:
                            logger.info(f"Processed Claude-extracted risks and blockers: {len(risks_blockers_data.get('risks', []))} risks, {len(risks_blockers_data.get('blockers', []))} blockers")
                        
                        if hasattr(intelligence_span, 'update'):
                            intelligence_span.update(
                                output={
                                    "sentiment_analysis": sentiment_data,
                                    "risks_blockers": risks_blockers_data
                                }
                            )
                    except Exception as e:
                        logger.warning(f"Claude intelligence processing failed: {e}")
                        sentiment_data = None
                        risks_blockers_data = None
                
                # Update progress: Saving summary (98%)
                if job_id:
                    upload_job_service.update_job_progress(
                        job_id,
                        progress=98.0,
                        step_description="Saving summary"
                    )
                
                # Create summary record
                summary = None
                with langfuse_client.start_as_current_span(
                    name="save_summary"
                ) as save_span:
                    # Log communication insights before saving
                    comm_insights = summary_data.get("communication_insights", {})
                    logger.info(f"Communication insights to save: {comm_insights}")

                    # DEBUG: Log lessons learned extraction
                    lessons_learned_data = summary_data.get("lessons_learned", [])
                    logger.info(f"DEBUG: Lessons learned from Claude response: {lessons_learned_data}")
                    logger.info(f"DEBUG: Number of lessons learned: {len(lessons_learned_data)}")
                    if lessons_learned_data:
                        logger.info(f"DEBUG: First lesson learned: {lessons_learned_data[0] if lessons_learned_data else 'None'}")

                    summary = Summary(
                        id=uuid.uuid4(),
                        organization_id=project.organization_id,  # Add organization_id from project
                        project_id=project_id,
                        content_id=content_id,
                        summary_type=SummaryType.MEETING,
                        subject=content.title + " - Meeting Summary",
                        body=summary_data["summary_text"],
                        key_points=summary_data.get("key_points", []),
                        action_items=summary_data.get("action_items", []),
                        decisions=summary_data.get("decisions", []),
                        lessons_learned=lessons_learned_data,
                        sentiment_analysis=sentiment_data,
                        risks=risks_blockers_data.get("risks", []) if risks_blockers_data else [],
                        blockers=risks_blockers_data.get("blockers", []) if risks_blockers_data else [],
                        communication_insights=comm_insights,
                        next_meeting_agenda=summary_data.get("next_meeting_agenda", []),
                        created_by=created_by,
                        token_count=summary_data.get("token_count", 0),
                        generation_time_ms=int((time.time() - start_time) * 1000),
                        format=format_type
                    )
                    
                    session.add(summary)
                    await session.flush()
                    
                    # Log activity for meeting summary generation
                    await ActivityService.log_summary_generated(
                        db=session,
                        project_id=project_id,
                        summary_type="meeting",
                        summary_subject=summary.subject,
                        user_name=created_by or "system",
                        user_id=created_by_id
                    )
                    
                    await session.commit()
                    
                    if hasattr(save_span, 'update'):
                        save_span.update(
                            output={"summary_id": str(summary.id)}
                        )
                
                # Calculate total time
                total_time = time.time() - start_time
                
                # Update trace span with final output
                if hasattr(trace_span, 'update'):
                    trace_span.update(
                        output={
                            "summary_id": str(summary.id),
                            "summary_preview": summary_data["summary_text"][:200] + "...",
                            "key_points_count": len(summary_data.get("key_points", [])),
                            "action_items_count": len(summary_data.get("action_items", [])),
                            "decisions_count": len(summary_data.get("decisions", [])),
                            "total_time_s": total_time,
                            "token_count": summary_data.get("token_count", 0),
                            "cost_usd": summary_data.get("cost_usd", 0.0)
                        }
                    )
                
                # Add cost score
                if hasattr(trace_span, 'score'):
                    trace_span.score(
                        name="cost_usd",
                        value=summary_data.get("cost_usd", 0.0),
                        comment="Cost for meeting summary generation"
                    )
            
            # Update progress: Finalizing (99%)
            if job_id:
                upload_job_service.update_job_progress(
                    job_id,
                    progress=99.0,
                    step_description="Finalizing"
                )
            
            # Flush Langfuse events
            langfuse_service.flush()
            
            logger.info(f"Meeting summary generated for content {content_id} in {total_time:.2f}s")
            
            return {
                "id": str(summary.id),
                "summary_text": summary.body,
                "subject": summary.subject,
                "key_points": summary.key_points,
                "action_items": summary.action_items,
                "decisions": summary.decisions,
                "lessons_learned": summary.lessons_learned,  # Add lessons learned to return
                "sentiment_analysis": summary.sentiment_analysis,
                "risks": summary.risks,
                "blockers": summary.blockers,
                "communication_insights": summary.communication_insights,
                "next_meeting_agenda": summary.next_meeting_agenda,
                "token_count": summary.token_count,
                "generation_time_ms": summary.generation_time_ms
            }
            
            logger.info(f"API Response - communication_insights field: {summary.communication_insights}")
            
        except Exception as e:
            logger.error(f"Meeting summary generation failed: {e}")
            raise
    
    async def generate_project_summary(
        self,
        session: AsyncSession,
        project_id: uuid.UUID,
        week_start: datetime,
        week_end: Optional[datetime] = None,
        created_by: Optional[str] = None,
        created_by_id: Optional[str] = None,
        format_type: str = "general"
    ) -> Dict[str, Any]:
        """Generate a project summary with proper Langfuse v3 context managers."""
        start_time = time.time()
        
        # Check if Langfuse client supports context managers
        langfuse_client = langfuse_service.client
        if not langfuse_client or not hasattr(langfuse_client, 'start_as_current_span'):
            # Fallback to simpler implementation
            return await self._generate_project_summary_fallback(
                session, project_id, week_start, week_end, created_by, format_type
            )
        
        try:
            # Use provided week_end or default to 7 days after start
            if week_end is None:
                week_end = week_start + timedelta(days=7)
            
            # Use Langfuse v3 context manager
            with langfuse_client.start_as_current_span(
                name="generate_project_summary",
                input={
                    "project_id": str(project_id),
                    "week_start": week_start.isoformat(),
                    "week_end": week_end.isoformat(),
                    "created_by": created_by
                },
                metadata={
                    "summary_type": "project"
                },
                version="2.0.0"
            ) as trace_span:
                
                # Validate project
                project = None
                with langfuse_client.start_as_current_span(
                    name="validate_project"
                ) as validate_span:
                    project_result = await session.execute(
                        select(Project).where(Project.id == project_id)
                    )
                    project = project_result.scalar_one_or_none()
                    if not project:
                        raise ValueError(f"Project {project_id} not found")
                    
                    if hasattr(validate_span, 'update'):
                        validate_span.update(
                            output={"project_name": project.name}
                        )
                
                # Get meeting summaries for the week (not full content)
                summaries = []
                contents_map = {}
                with langfuse_client.start_as_current_span(
                    name="fetch_project_summaries"
                ) as fetch_span:
                    # Fetch meeting summaries with their associated content info
                    summary_result = await session.execute(
                        select(Summary, Content).join(Content).where(
                            and_(
                                Summary.project_id == project_id,
                                Summary.summary_type == SummaryType.MEETING,
                                Content.date >= week_start,
                                Content.date < week_end
                            )
                        ).order_by(Content.date)
                    )
                    results = summary_result.all()
                    
                    for summary, content in results:
                        summaries.append(summary)
                        contents_map[str(summary.id)] = {
                            'title': content.title,
                            'date': content.date.isoformat() if content.date else None,
                            'content_type': content.content_type
                        }
                    
                    if hasattr(fetch_span, 'update'):
                        fetch_span.update(
                            output={
                                "summary_count": len(summaries),
                                "total_chars": sum(len(s.body) for s in summaries)
                            }
                        )
                
                if not summaries:
                    logger.warning(f"No meeting summaries found for project {project_id} for period starting {week_start}")
                    raise ValueError(
                        f"No meeting summaries available for project '{project.name}' in the specified date range. "
                        f"Please upload meeting content and generate meeting summaries first."
                    )
                
                # Build comprehensive data structure with ALL fields from meeting summaries
                meeting_data_for_claude = []
                for summary in summaries:
                    content_info = contents_map.get(str(summary.id), {})
                    
                    # Create a comprehensive meeting data object with ALL available fields
                    meeting_obj = {
                        "meeting_title": content_info.get('title', summary.subject),
                        "meeting_date": content_info.get('date', summary.created_at.isoformat()),
                        "summary_text": summary.body,
                        "key_points": summary.key_points or [],
                        "action_items": summary.action_items or [],
                        "decisions": summary.decisions or [],
                        "lessons_learned": summary.lessons_learned or [],
                        "sentiment_analysis": summary.sentiment_analysis or {},
                        "risks": summary.risks or [],
                        "blockers": summary.blockers or [],
                        "communication_insights": summary.communication_insights or {},
                        "next_meeting_agenda": summary.next_meeting_agenda or [],
                        "metadata": {
                            "summary_id": str(summary.id),
                            "content_id": str(summary.content_id) if summary.content_id else None,
                            "generated_at": summary.created_at.isoformat(),
                            "token_count": summary.token_count,
                            "generation_time_ms": summary.generation_time_ms
                        }
                    }
                    meeting_data_for_claude.append(meeting_obj)
                
                # Create structured input for Claude with ALL meeting data
                import json
                combined_text = json.dumps({
                    "week_start": week_start.isoformat(),
                    "week_end": week_end.isoformat(),
                    "project_name": project.name,
                    "meeting_count": len(summaries),
                    "meetings": meeting_data_for_claude
                }, indent=2)
                
                # Generate summary using Claude API
                summary_data = await self._generate_claude_summary_with_context(
                    content_type="project",
                    project_name=project.name,
                    content_title=f"Week of {week_start.strftime('%Y-%m-%d')}",
                    content_text=combined_text,
                    content_date=week_start,
                    additional_context={
                        "meeting_count": len(summaries),
                        "meeting_titles": [contents_map.get(str(s.id), {}).get('title', s.subject) for s in summaries],
                        "structured_data": meeting_data_for_claude
                    },
                    format_type=format_type
                )
                
                # Process enhanced fields for weekly summary
                sentiment_data = summary_data.get("sentiment", {})
                if sentiment_data:
                    sentiment_data = {
                        "overall": sentiment_data.get("overall", "neutral"),
                        "confidence": sentiment_data.get("confidence", 0.0),
                        "key_emotions": sentiment_data.get("key_emotions", []),
                        "trend": sentiment_data.get("trend", "stable")
                    }
                
                risks_blockers_data = {
                    "risks": summary_data.get("risks", []),
                    "blockers": summary_data.get("blockers", []),
                    "mitigation_strategies": []
                }
                
                comm_insights = summary_data.get("communication_insights", {})
                
                # Create summary record
                summary = None
                with langfuse_client.start_as_current_span(
                    name="save_project_summary"
                ) as save_span:
                    summary = Summary(
                        id=uuid.uuid4(),
                        organization_id=project.organization_id,  # Add organization_id from project
                        project_id=project_id,
                        summary_type=SummaryType.PROJECT,
                        subject=f"Project Summary - {week_start.strftime('%Y-%m-%d')}",
                        body=summary_data["summary_text"],
                        key_points=summary_data.get("key_points", []),
                        action_items=summary_data.get("action_items", []),
                        decisions=summary_data.get("decisions", []),
                        lessons_learned=summary_data.get("lessons_learned", []),
                        sentiment_analysis=sentiment_data,
                        risks=risks_blockers_data.get("risks", []) if risks_blockers_data else [],
                        blockers=risks_blockers_data.get("blockers", []) if risks_blockers_data else [],
                        communication_insights=comm_insights,
                        next_meeting_agenda=summary_data.get("next_meeting_agenda", []),
                        created_by=created_by,
                        date_range_start=week_start,
                        date_range_end=week_end,
                        token_count=summary_data.get("token_count", 0),
                        generation_time_ms=int((time.time() - start_time) * 1000),
                        format=format_type
                    )
                    
                    session.add(summary)
                    await session.flush()
                    
                    # Log activity for project summary generation
                    await ActivityService.log_summary_generated(
                        db=session,
                        project_id=project_id,
                        summary_type="project",
                        summary_subject=summary.subject,
                        user_name=created_by or "system",
                        user_id=created_by_id
                    )
                    
                    await session.commit()
                    
                    if hasattr(save_span, 'update'):
                        save_span.update(
                            output={"summary_id": str(summary.id)}
                        )
                
                # Calculate total time
                total_time = time.time() - start_time
                
                # Update trace span
                if hasattr(trace_span, 'update'):
                    trace_span.update(
                        output={
                            "summary_id": str(summary.id),
                            "meeting_count": len(summaries),
                            "total_time_s": total_time,
                            "token_count": summary_data.get("token_count", 0),
                            "cost_usd": summary_data.get("cost_usd", 0.0)
                        }
                    )
            
            # Flush Langfuse events
            langfuse_service.flush()
            
            logger.info(f"Project summary generated for period {week_start} in {total_time:.2f}s")
            
            return {
                "id": str(summary.id),
                "summary_text": summary.body,
                "subject": summary.subject,
                "key_points": summary.key_points,
                "action_items": summary.action_items,
                "decisions": summary.decisions,
                "sentiment_analysis": summary.sentiment_analysis,
                "risks": summary.risks,
                "blockers": summary.blockers,
                "communication_insights": summary.communication_insights,
                "next_meeting_agenda": summary.next_meeting_agenda,
                "date_range_start": summary.date_range_start.isoformat() if summary.date_range_start else None,
                "date_range_end": summary.date_range_end.isoformat() if summary.date_range_end else None,
                "token_count": summary.token_count,
                "generation_time_ms": summary.generation_time_ms
            }
            
        except Exception as e:
            logger.error(f"Project summary generation failed: {e}")
            raise

    async def generate_program_summary(
        self,
        session: AsyncSession,
        program_id: uuid.UUID,
        week_start: datetime,
        week_end: Optional[datetime] = None,
        created_by: Optional[str] = None,
        created_by_id: Optional[str] = None,
        format_type: str = "general"
    ) -> Dict[str, Any]:
        """Generate a summary for all projects in a program."""
        start_time = time.time()
        correlation_id = get_correlation_id()

        structured_logger.log_generation_start(
            entity_type="program",
            entity_id=str(program_id),
            summary_type="program",
            format_type=format_type,
            correlation_id=correlation_id
        )
        logger.info(f"Starting program summary generation for program {program_id}")

        try:
            # Get program
            with structured_logger.timer("fetch_program", correlation_id=correlation_id):
                program_result = await session.execute(
                    select(Program).where(Program.id == program_id)
                )
                program = program_result.scalars().first()
                if not program:
                    structured_logger.error(
                        f"Program {program_id} not found",
                        correlation_id=correlation_id,
                        program_id=str(program_id)
                    )
                    raise ValueError(f"Program {program_id} not found")
                structured_logger.info(
                    f"Found program: {program.name}",
                    correlation_id=correlation_id,
                    program_name=program.name
                )

            # Get all projects in the program
            with structured_logger.timer("fetch_program_projects", correlation_id=correlation_id):
                projects_result = await session.execute(
                    select(Project).where(Project.program_id == program_id)
                )
                projects = projects_result.scalars().all()

                if not projects:
                    structured_logger.warning(
                        f"No projects found in program {program_id}",
                        correlation_id=correlation_id,
                        program_id=str(program_id)
                    )
                    raise ValueError(f"No projects found in program {program_id}")

                structured_logger.log_aggregation_stats(
                    entity_type="program",
                    entity_id=str(program_id),
                    projects_count=len(projects),
                    content_items=0,  # Will be updated
                    total_tokens=0,
                    correlation_id=correlation_id
                )

            # Collect all summaries from all projects
            all_summaries = []
            summary_type_counts = {}

            for project in projects:
                # Build flexible query for summaries
                query_conditions = [Summary.project_id == project.id]

                # Include MEETING and PROJECT summaries (both are relevant for program summaries)
                query_conditions.append(
                    Summary.summary_type.in_([SummaryType.MEETING, SummaryType.PROJECT])
                )

                # Flexible date range filtering - check for overlap OR within creation date
                if week_end:
                    date_conditions = or_(
                        # Summaries that overlap with the requested date range
                        and_(
                            Summary.date_range_start != None,
                            Summary.date_range_end != None,
                            Summary.date_range_start <= week_end,
                            Summary.date_range_end >= week_start
                        ),
                        # Summaries created within the date range (fallback)
                        and_(
                            Summary.created_at >= week_start,
                            Summary.created_at <= week_end
                        ),
                        # Summaries without date ranges but created recently
                        and_(
                            Summary.date_range_start == None,
                            Summary.created_at >= week_start - timedelta(days=7)  # Include recent summaries
                        )
                    )
                else:
                    # If no end date specified, get summaries from start date onwards
                    date_conditions = or_(
                        Summary.date_range_start >= week_start,
                        Summary.created_at >= week_start,
                        and_(
                            Summary.date_range_start == None,
                            Summary.created_at >= week_start - timedelta(days=7)
                        )
                    )

                query_conditions.append(date_conditions)

                summaries_result = await session.execute(
                    select(Summary).where(
                        and_(*query_conditions)
                    ).order_by(Summary.created_at.desc())
                )
                project_summaries = summaries_result.scalars().all()

                # Track summary types found
                for summary in project_summaries:
                    summary_type = summary.summary_type.value if hasattr(summary.summary_type, 'value') else str(summary.summary_type)
                    summary_type_counts[summary_type] = summary_type_counts.get(summary_type, 0) + 1

                all_summaries.extend(project_summaries)

            # Log what we found for debugging
            logger.info(f"Found {len(all_summaries)} summaries for program {program_id}")
            logger.info(f"Summary types found: {summary_type_counts}")

            # Check if we have any summaries to work with
            if not all_summaries:
                logger.warning(f"No summaries found for program {program_id} in the specified date range")
                logger.warning(f"Searched in {len(projects)} projects with date range {week_start} to {week_end}")
                raise ValueError(
                    f"No project summaries (MEETING or PROJECT) available for program '{program.name}' "
                    f"in the specified date range ({week_start.strftime('%Y-%m-%d')} to "
                    f"{week_end.strftime('%Y-%m-%d') if week_end else 'now'}). "
                    f"Found {len(projects)} project(s) but no summaries. "
                    f"Please ensure projects have content uploaded and summaries generated."
                )

            # Use smart context building with hybrid approach
            logger.info("Building smart program context using hybrid approach")
            combined_text = await self._build_program_context(
                session=session,
                program_id=program_id,
                projects=projects,
                week_start=week_start,
                week_end=week_end
            )

            # Generate program-level summary
            summary_data = await self._generate_claude_summary_with_context(
                content_type="program",
                project_name=program.name,
                content_title=f"Program Summary - {week_start.strftime('%Y-%m-%d')}",
                content_text=combined_text,
                content_date=week_start,
                additional_context={
                    "project_count": len(projects),
                    "summary_count": len(all_summaries),
                    "project_names": [p.name for p in projects]
                },
                format_type=format_type
            )

            # Process sentiment analysis if present
            sentiment_data = self._process_claude_sentiment(summary_data) if summary_data else None

            # Process risks and blockers
            risks_blockers_data = self._process_claude_risks_blockers(summary_data) if summary_data else None
            if not risks_blockers_data:
                # Fallback to simple format
                risks_blockers_data = {
                    "risks": summary_data.get("risks", []),
                    "blockers": summary_data.get("blockers", [])
                }

            # Process communication insights
            comm_insights_raw = summary_data.get("communication_insights", {})
            comm_insights = None
            if comm_insights_raw and isinstance(comm_insights_raw, dict):
                # Convert to the expected format
                comm_insights = {
                    "unanswered_questions": comm_insights_raw.get("unanswered_questions", []),
                    "follow_ups": comm_insights_raw.get("follow_ups", []),
                    "clarity_issues": comm_insights_raw.get("clarity_issues", []),
                    "agenda_alignment": comm_insights_raw.get("agenda_alignment", {}),
                    "effectiveness_score": comm_insights_raw.get("effectiveness_score", {}),
                    "improvement_suggestions": comm_insights_raw.get("improvement_suggestions", [])
                }

            # Log what we got from Claude
            logger.info(f"Program summary - cross_project_dependencies: {summary_data.get('cross_project_dependencies', [])}")
            logger.info(f"Program summary - program_health: {summary_data.get('program_health', {})}")
            logger.info(f"Program summary - resource_metrics: {summary_data.get('resource_metrics', {})}")
            logger.info(f"Program summary - next_meeting_agenda: {summary_data.get('next_meeting_agenda', [])}")

            # Store program-specific metrics in cross_meeting_insights (repurposed for program data)
            program_metrics = {
                "cross_project_dependencies": summary_data.get("cross_project_dependencies", []),
                "resource_metrics": summary_data.get("resource_metrics", {}),
                "program_health": summary_data.get("program_health", {}),
                "financial_summary": summary_data.get("financial_summary", {}),
                "strategic_alignment": summary_data.get("strategic_alignment", {}),
                "technical_metrics": summary_data.get("technical_metrics", {}),
                "architecture_insights": summary_data.get("architecture_insights", {}),
                "value_delivered": summary_data.get("value_delivered", {}),
                "stakeholder_feedback": summary_data.get("stakeholder_feedback", {})
            }

            # Log what we're saving
            logger.info(f"Saving program_metrics to cross_meeting_insights: {program_metrics}")

            # Save program summary
            summary = Summary(
                id=uuid.uuid4(),
                organization_id=program.organization_id,  # Add organization_id from program
                project_id=None,  # No project ID for program summaries
                program_id=program_id,  # Store program ID directly
                portfolio_id=None,
                summary_type=SummaryType.PROGRAM,
                subject=f"Program Summary - {program.name}",
                body=summary_data["summary_text"],
                key_points=summary_data.get("key_points", []),
                action_items=summary_data.get("action_items", []),
                decisions=summary_data.get("decisions", []),
                lessons_learned=summary_data.get("lessons_learned", []),
                sentiment_analysis=sentiment_data,  # Add sentiment analysis
                risks=risks_blockers_data.get("risks", []) if risks_blockers_data else [],
                blockers=risks_blockers_data.get("blockers", []) if risks_blockers_data else [],
                communication_insights=comm_insights,  # Add communication insights
                cross_meeting_insights=program_metrics,  # Store program-specific data
                next_meeting_agenda=summary_data.get("next_meeting_agenda", []),  # Add next meeting agenda
                created_by=created_by,
                date_range_start=week_start,
                date_range_end=week_end,
                format=format_type,
                generation_time_ms=int((time.time() - start_time) * 1000),
                token_count=summary_data.get("token_count", 0)
            )

            session.add(summary)
            await session.flush()
            await session.commit()

            return {
                "id": str(summary.id),
                "summary_text": summary.body,
                "subject": summary.subject,
                "key_points": summary.key_points,
                "action_items": summary.action_items,
                "decisions": summary.decisions,
                "sentiment_analysis": summary.sentiment_analysis,
                "risks": summary.risks,
                "blockers": summary.blockers,
                "communication_insights": summary.communication_insights,
                "cross_meeting_insights": summary.cross_meeting_insights,  # Contains program-specific metrics
                "next_meeting_agenda": summary.next_meeting_agenda,
                "date_range_start": summary.date_range_start.isoformat() if summary.date_range_start else None,
                "date_range_end": summary.date_range_end.isoformat() if summary.date_range_end else None,
                "token_count": summary.token_count,
                "generation_time_ms": summary.generation_time_ms,
                # Also include the raw fields for backward compatibility
                "risks": summary_data.get("risks", []),
                "blockers": summary_data.get("blockers", []),
                "cross_project_dependencies": summary_data.get("cross_project_dependencies", []),
                "resource_metrics": summary_data.get("resource_metrics", {}),
                "program_health": summary_data.get("program_health", {})
            }

        except Exception as e:
            logger.error(f"Program summary generation failed: {e}")
            raise

    async def generate_portfolio_summary(
        self,
        session: AsyncSession,
        portfolio_id: uuid.UUID,
        week_start: datetime,
        week_end: Optional[datetime] = None,
        created_by: Optional[str] = None,
        created_by_id: Optional[str] = None,
        format_type: str = "general"
    ) -> Dict[str, Any]:
        """Generate a summary for all projects in a portfolio."""
        start_time = time.time()
        logger.info(f"Starting portfolio summary generation for portfolio {portfolio_id}")

        try:
            # Get portfolio
            portfolio_result = await session.execute(
                select(Portfolio).where(Portfolio.id == portfolio_id)
            )
            portfolio = portfolio_result.scalars().first()
            if not portfolio:
                raise ValueError(f"Portfolio {portfolio_id} not found")

            # Get all programs in portfolio
            programs_result = await session.execute(
                select(Program).where(Program.portfolio_id == portfolio_id)
            )
            programs = programs_result.scalars().all()

            # Get all projects (both direct and through programs)
            all_projects = []

            # Direct projects
            direct_projects_result = await session.execute(
                select(Project).where(Project.portfolio_id == portfolio_id)
            )
            all_projects.extend(direct_projects_result.scalars().all())

            # Projects through programs
            for program in programs:
                program_projects_result = await session.execute(
                    select(Project).where(Project.program_id == program.id)
                )
                all_projects.extend(program_projects_result.scalars().all())

            if not all_projects:
                raise ValueError(f"No projects found in portfolio {portfolio_id}")

            # Collect all summaries from all projects
            all_summaries = []
            summary_type_counts = {}

            for project in all_projects:
                # Build flexible query for summaries
                query_conditions = [Summary.project_id == project.id]

                # Include MEETING and PROJECT summaries (both are relevant for portfolio summaries)
                query_conditions.append(
                    Summary.summary_type.in_([SummaryType.MEETING, SummaryType.PROJECT])
                )

                # Flexible date range filtering - check for overlap OR within creation date
                if week_end:
                    date_conditions = or_(
                        # Summaries that overlap with the requested date range
                        and_(
                            Summary.date_range_start != None,
                            Summary.date_range_end != None,
                            Summary.date_range_start <= week_end,
                            Summary.date_range_end >= week_start
                        ),
                        # Summaries created within the date range (fallback)
                        and_(
                            Summary.created_at >= week_start,
                            Summary.created_at <= week_end
                        ),
                        # Summaries without date ranges but created recently
                        and_(
                            Summary.date_range_start == None,
                            Summary.created_at >= week_start - timedelta(days=7)  # Include recent summaries
                        )
                    )
                else:
                    # If no end date specified, get summaries from start date onwards
                    date_conditions = or_(
                        Summary.date_range_start >= week_start,
                        Summary.created_at >= week_start,
                        and_(
                            Summary.date_range_start == None,
                            Summary.created_at >= week_start - timedelta(days=7)
                        )
                    )

                query_conditions.append(date_conditions)

                summaries_result = await session.execute(
                    select(Summary).where(
                        and_(*query_conditions)
                    ).order_by(Summary.created_at.desc())
                )
                project_summaries = summaries_result.scalars().all()

                # Track summary types found
                for summary in project_summaries:
                    summary_type = summary.summary_type.value if hasattr(summary.summary_type, 'value') else str(summary.summary_type)
                    summary_type_counts[summary_type] = summary_type_counts.get(summary_type, 0) + 1

                all_summaries.extend(project_summaries)

            # Log what we found for debugging
            logger.info(f"Found {len(all_summaries)} summaries for portfolio {portfolio_id}")
            logger.info(f"Summary types found: {summary_type_counts}")

            # Check if we have any summaries to work with
            if not all_summaries:
                logger.warning(f"No summaries found for portfolio {portfolio_id} in the specified date range")
                logger.warning(f"Searched in {len(all_projects)} projects with date range {week_start} to {week_end}")
                raise ValueError(
                    f"No project summaries (MEETING or PROJECT) available for portfolio '{portfolio.name}' "
                    f"in the specified date range ({week_start.strftime('%Y-%m-%d')} to "
                    f"{week_end.strftime('%Y-%m-%d') if week_end else 'now'}). "
                    f"Found {len(all_projects)} project(s) but no summaries. "
                    f"Please ensure projects have content uploaded and summaries generated."
                )

            # Use smart context building with hybrid approach
            logger.info("Building smart portfolio context using hybrid approach")
            combined_text = await self._build_portfolio_context(
                session=session,
                portfolio_id=portfolio_id,
                programs=programs,
                all_projects=all_projects,
                week_start=week_start,
                week_end=week_end
            )

            # Generate portfolio-level summary
            summary_data = await self._generate_claude_summary_with_context(
                content_type="portfolio",
                project_name=portfolio.name,
                content_title=f"Portfolio Summary - {week_start.strftime('%Y-%m-%d')}",
                content_text=combined_text,
                content_date=week_start,
                additional_context={
                    "program_count": len(programs),
                    "project_count": len(all_projects),
                    "summary_count": len(all_summaries),
                    "program_names": [p.name for p in programs],
                    "project_names": [p.name for p in all_projects]
                },
                format_type=format_type
            )

            # Process sentiment analysis if present
            sentiment_data = self._process_claude_sentiment(summary_data) if summary_data else None

            # Process risks and blockers
            risks_blockers_data = self._process_claude_risks_blockers(summary_data) if summary_data else None
            if not risks_blockers_data:
                # Fallback to simple format
                risks_blockers_data = {
                    "risks": summary_data.get("risks", []),
                    "blockers": summary_data.get("blockers", [])
                }

            # Process communication insights
            comm_insights_raw = summary_data.get("communication_insights", {})
            comm_insights = None
            if comm_insights_raw and isinstance(comm_insights_raw, dict):
                # Convert to the expected format
                comm_insights = {
                    "unanswered_questions": comm_insights_raw.get("unanswered_questions", []),
                    "follow_ups": comm_insights_raw.get("follow_ups", []),
                    "clarity_issues": comm_insights_raw.get("clarity_issues", []),
                    "agenda_alignment": comm_insights_raw.get("agenda_alignment", {}),
                    "effectiveness_score": comm_insights_raw.get("effectiveness_score", {}),
                    "improvement_suggestions": comm_insights_raw.get("improvement_suggestions", [])
                }

            # Log what Claude returned for portfolio-specific fields
            logger.info(f"Portfolio summary - portfolio_metrics from Claude: {summary_data.get('portfolio_metrics', {})}")
            logger.info(f"Portfolio summary - executive_dashboard from Claude: {summary_data.get('executive_dashboard', {})}")
            logger.info(f"Portfolio summary - cross_project_dependencies from Claude: {summary_data.get('cross_project_dependencies', [])}")
            logger.info(f"Portfolio summary - strategic_initiatives from Claude: {summary_data.get('strategic_initiatives', [])}")

            # Store portfolio-specific metrics in cross_meeting_insights (repurposed for portfolio data)
            portfolio_metrics = {
                "program_performance": summary_data.get("program_performance", []),
                "portfolio_metrics": summary_data.get("portfolio_metrics", {}),
                "strategic_initiatives": summary_data.get("strategic_initiatives", []),
                "governance_items": summary_data.get("governance_items", []),
                "executive_dashboard": summary_data.get("executive_dashboard", {}),
                "board_items": summary_data.get("board_items", []),
                "investment_analysis": summary_data.get("investment_analysis", {}),
                "enterprise_architecture": summary_data.get("enterprise_architecture", {}),
                "technology_landscape": summary_data.get("technology_landscape", {}),
                "capability_assessment": summary_data.get("capability_assessment", {}),
                "business_outcomes": summary_data.get("business_outcomes", {}),
                "stakeholder_matrix": summary_data.get("stakeholder_matrix", []),
                "value_realization": summary_data.get("value_realization", {}),
                "cross_project_dependencies": summary_data.get("cross_project_dependencies", [])  # Add this for dependencies tab
            }

            # Save portfolio summary
            summary = Summary(
                id=uuid.uuid4(),
                organization_id=portfolio.organization_id,  # Add organization_id from portfolio
                project_id=None,  # No project ID for portfolio summaries
                program_id=None,
                portfolio_id=portfolio_id,  # Store portfolio ID directly
                summary_type=SummaryType.PORTFOLIO,
                subject=f"Portfolio Summary - {portfolio.name}",
                body=summary_data["summary_text"],
                key_points=summary_data.get("key_points", []),
                action_items=summary_data.get("action_items", []),
                decisions=summary_data.get("decisions", []),
                lessons_learned=summary_data.get("lessons_learned", []),
                sentiment_analysis=sentiment_data,  # Add sentiment analysis
                risks=risks_blockers_data.get("risks", []) if risks_blockers_data else [],
                blockers=risks_blockers_data.get("blockers", []) if risks_blockers_data else [],
                communication_insights=comm_insights,  # Add communication insights
                cross_meeting_insights=portfolio_metrics,  # Store portfolio-specific data
                next_meeting_agenda=summary_data.get("next_meeting_agenda", []),  # Add next meeting agenda
                created_by=created_by,
                date_range_start=week_start,
                date_range_end=week_end,
                format=format_type,
                generation_time_ms=int((time.time() - start_time) * 1000),
                token_count=summary_data.get("token_count", 0)
            )

            session.add(summary)
            await session.flush()
            await session.commit()

            return {
                "id": str(summary.id),
                "summary_text": summary.body,
                "subject": summary.subject,
                "key_points": summary.key_points,
                "action_items": summary.action_items,
                "decisions": summary.decisions,
                "sentiment_analysis": summary.sentiment_analysis,
                "risks": summary.risks,
                "blockers": summary.blockers,
                "communication_insights": summary.communication_insights,
                "cross_meeting_insights": summary.cross_meeting_insights,  # Contains portfolio-specific metrics
                "next_meeting_agenda": summary.next_meeting_agenda,
                "date_range_start": summary.date_range_start.isoformat() if summary.date_range_start else None,
                "date_range_end": summary.date_range_end.isoformat() if summary.date_range_end else None,
                "token_count": summary.token_count,
                "generation_time_ms": summary.generation_time_ms,
                # Also include the raw fields for backward compatibility
                "risks": summary_data.get("risks", []),
                "blockers": summary_data.get("blockers", []),
                "program_performance": summary_data.get("program_performance", []),
                "portfolio_metrics": summary_data.get("portfolio_metrics", {}),
                "strategic_initiatives": summary_data.get("strategic_initiatives", [])
            }

        except Exception as e:
            logger.error(f"Portfolio summary generation failed: {e}")
            raise

    @async_retry(RetryConfig(
        max_attempts=3,
        initial_delay=2.0,
        max_delay=30.0,
        exponential_base=2.0,
        jitter=True
    ))
    async def _call_claude_api_with_retry(self, prompt: str) -> Any:
        """Make the actual API call to Claude with retry logic."""
        return await self.llm_client.create_message(
            prompt=prompt,
            model=self.llm_model,
            max_tokens=self.max_tokens,
            temperature=self.temperature,
            system="You are a JSON API that ONLY returns valid JSON responses. Never ask questions or engage in conversation. Process the input and return the complete JSON summary immediately."
        )

    async def _build_program_context(
        self,
        session: AsyncSession,
        program_id: uuid.UUID,
        projects: List[Project],
        week_start: datetime,
        week_end: Optional[datetime] = None,
        max_tokens: int = 150000
    ) -> str:
        """
        Build smart context for program summaries using hybrid approach:
        1. Structured data from DB (cheap)
        2. Recent project summaries (moderate cost)
        3. Selective raw content via semantic search (expensive but targeted)
        """
        from models.risk import Risk
        from models.task import Task
        from db.multi_tenant_vector_store import multi_tenant_vector_store

        logger.info(f"Building smart context for program {program_id} with {len(projects)} projects")

        # Get organization_id from first project
        organization_id = str(projects[0].organization_id) if projects else None

        context_parts = []

        # 1. TIER 1: Structured data from database (minimal tokens, max insight)
        logger.info("Tier 1: Fetching structured risks and tasks from database")
        project_ids = [p.id for p in projects]

        # Fetch all active risks
        risks_result = await session.execute(
            select(Risk).where(
                and_(
                    Risk.project_id.in_(project_ids),
                    Risk.status.in_(['identified', 'mitigating', 'escalated'])
                )
            ).order_by(Risk.severity.desc(), Risk.identified_date.desc())
        )
        active_risks = risks_result.scalars().all()

        # Fetch all open tasks
        tasks_result = await session.execute(
            select(Task).where(
                and_(
                    Task.project_id.in_(project_ids),
                    Task.status.in_(['todo', 'in_progress', 'blocked'])
                )
            ).order_by(Task.priority.desc(), Task.due_date.asc())
        )
        open_tasks = tasks_result.scalars().all()

        # Build structured summary
        context_parts.append("=== STRUCTURED DATA FROM DATABASE ===\n")
        context_parts.append(f"Active Risks Across All Projects ({len(active_risks)}):\n")
        for risk in active_risks[:20]:  # Top 20 most critical
            project = next((p for p in projects if p.id == risk.project_id), None)
            project_name = project.name if project else "Unknown"
            context_parts.append(
                f"- [{project_name}] {risk.title} (Severity: {risk.severity.value})\n"
                f"  Description: {risk.description}\n"
                f"  Mitigation: {risk.mitigation or 'None specified'}\n"
            )

        context_parts.append(f"\nOpen Tasks Across All Projects ({len(open_tasks)}):\n")
        for task in open_tasks[:30]:  # Top 30 most urgent
            project = next((p for p in projects if p.id == task.project_id), None)
            project_name = project.name if project else "Unknown"
            context_parts.append(
                f"- [{project_name}] {task.title} (Priority: {task.priority.value}, Status: {task.status.value})\n"
                f"  Assignee: {task.assignee or 'Unassigned'}\n"
                f"  Due: {task.due_date.strftime('%Y-%m-%d') if task.due_date else 'No due date'}\n"
            )

        # 2. TIER 2: Recent project summaries (moderate token cost)
        logger.info("Tier 2: Fetching recent project summaries")
        context_parts.append("\n=== PROJECT SUMMARIES (LAST 30 DAYS) ===\n")

        for project in projects:
            # Get recent summaries for this project
            summaries_result = await session.execute(
                select(Summary).where(
                    and_(
                        Summary.project_id == project.id,
                        Summary.summary_type.in_([SummaryType.PROJECT, SummaryType.MEETING]),
                        Summary.created_at >= week_start - timedelta(days=30)
                    )
                ).order_by(Summary.created_at.desc()).limit(3)  # Last 3 summaries per project
            )
            recent_summaries = summaries_result.scalars().all()

            if recent_summaries:
                context_parts.append(f"\nProject: {project.name}\n")
                for summary in recent_summaries:
                    context_parts.append(f"  - {summary.subject} ({summary.created_at.strftime('%Y-%m-%d')})\n")
                    context_parts.append(f"    {summary.body[:500]}...\n")  # First 500 chars

                    # Include key points if available
                    if summary.key_points:
                        context_parts.append(f"    Key Points: {', '.join(summary.key_points[:3])}\n")

        # 3. TIER 3: Selective raw content via semantic search (expensive but targeted)
        if organization_id:
            logger.info("Tier 3: Performing semantic search for critical content")
            context_parts.append("\n=== CRITICAL CONTENT (VIA SEMANTIC SEARCH) ===\n")

            # Define critical search queries
            critical_queries = [
                "critical blockers escalations urgent issues",
                "major risks high severity threats",
                "important decisions strategic changes",
                "deadline delays timeline slippage"
            ]

            from services.rag.embedding_service import embedding_service

            for query in critical_queries:
                try:
                    # Get embedding for query
                    query_embedding = await embedding_service.generate_embedding(query)

                    # Search across all projects in the program (no project filter, org filter is automatic)
                    results = await multi_tenant_vector_store.search_vectors(
                        organization_id=organization_id,
                        query_vector=query_embedding,
                        collection_type="content",
                        limit=5,  # Top 5 per query
                        score_threshold=0.6  # Only high-relevance content
                    )

                    if results:
                        logger.info(f"Semantic search for '{query}' returned {len(results)} results")
                        context_parts.append(f"\nQuery: '{query}'\n")
                        for result in results:
                            payload = result.get('payload', {})
                            content_text = payload.get('content', '')
                            title = payload.get('title', 'Untitled')
                            date = payload.get('date', 'Unknown date')

                            # Add snippet
                            context_parts.append(
                                f"- [{title}] ({date}, relevance: {result['score']:.2f})\n"
                                f"  {content_text[:300]}...\n"
                            )
                            logger.debug(f"Added result: {title} (score: {result['score']:.2f})")
                    else:
                        logger.info(f"Semantic search for '{query}' returned NO results (empty or below threshold)")
                except Exception as e:
                    logger.warning(f"Semantic search failed for query '{query}': {e}")

        # Combine all context parts
        full_context = ''.join(context_parts)

        # Token estimation (rough: ~4 chars per token)
        estimated_tokens = len(full_context) // 4
        logger.info(f"Built program context with ~{estimated_tokens} tokens from {len(active_risks)} risks, {len(open_tasks)} tasks, and semantic search")

        # If too large, truncate Tier 3 first
        if estimated_tokens > max_tokens:
            logger.warning(f"Context too large ({estimated_tokens} tokens), truncating to {max_tokens}")
            # Truncate to fit
            target_chars = max_tokens * 4
            full_context = full_context[:target_chars] + "\n\n[Context truncated due to size]"

        return full_context

    async def _build_portfolio_context(
        self,
        session: AsyncSession,
        portfolio_id: uuid.UUID,
        programs: List[Program],
        all_projects: List[Project],
        week_start: datetime,
        week_end: Optional[datetime] = None,
        max_tokens: int = 150000
    ) -> str:
        """
        Build smart context for portfolio summaries using hybrid approach:
        1. Structured data aggregated across all programs/projects
        2. Recent program summaries (if any)
        3. Critical issues via semantic search across entire portfolio
        """
        from models.risk import Risk
        from models.task import Task
        from db.multi_tenant_vector_store import multi_tenant_vector_store

        logger.info(f"Building smart context for portfolio {portfolio_id} with {len(programs)} programs and {len(all_projects)} projects")

        # Get organization_id from first project
        organization_id = str(all_projects[0].organization_id) if all_projects else None

        context_parts = []

        # 1. TIER 1: High-level structured data (minimal tokens)
        logger.info("Tier 1: Fetching portfolio-wide structured data")
        project_ids = [p.id for p in all_projects]

        # Fetch critical risks only
        risks_result = await session.execute(
            select(Risk).where(
                and_(
                    Risk.project_id.in_(project_ids),
                    Risk.severity.in_(['high', 'critical']),
                    Risk.status.in_(['identified', 'mitigating', 'escalated'])
                )
            ).order_by(Risk.severity.desc())
        )
        critical_risks = risks_result.scalars().all()

        # Fetch high-priority tasks only
        tasks_result = await session.execute(
            select(Task).where(
                and_(
                    Task.project_id.in_(project_ids),
                    Task.priority.in_(['high', 'urgent']),
                    Task.status.in_(['todo', 'in_progress', 'blocked'])
                )
            ).order_by(Task.priority.desc())
        )
        urgent_tasks = tasks_result.scalars().all()

        # Build portfolio overview
        context_parts.append("=== PORTFOLIO-WIDE STRUCTURED DATA ===\n")
        context_parts.append(f"Critical Risks ({len(critical_risks)}):\n")
        for risk in critical_risks[:15]:  # Top 15 most critical across portfolio
            project = next((p for p in all_projects if p.id == risk.project_id), None)
            project_name = project.name if project else "Unknown"
            context_parts.append(
                f"- [{project_name}] {risk.title} ({risk.severity.value})\n"
                f"  {risk.description[:200]}...\n"
            )

        context_parts.append(f"\nUrgent Tasks ({len(urgent_tasks)}):\n")
        for task in urgent_tasks[:20]:  # Top 20 most urgent
            project = next((p for p in all_projects if p.id == task.project_id), None)
            project_name = project.name if project else "Unknown"
            context_parts.append(
                f"- [{project_name}] {task.title} ({task.priority.value})\n"
            )

        # 2. TIER 2: Program summaries (if any exist)
        logger.info("Tier 2: Fetching recent program summaries")
        context_parts.append("\n=== PROGRAM SUMMARIES (RECENT) ===\n")

        for program in programs:
            summaries_result = await session.execute(
                select(Summary).where(
                    and_(
                        Summary.program_id == program.id,
                        Summary.summary_type == SummaryType.PROGRAM,
                        Summary.created_at >= week_start - timedelta(days=30)
                    )
                ).order_by(Summary.created_at.desc()).limit(2)
            )
            program_summaries = summaries_result.scalars().all()

            if program_summaries:
                context_parts.append(f"\nProgram: {program.name}\n")
                for summary in program_summaries:
                    context_parts.append(f"  - {summary.subject}\n")
                    context_parts.append(f"    {summary.body[:400]}...\n")

        # Also get recent project summaries for projects not in programs
        direct_projects = [p for p in all_projects if not p.program_id]
        if direct_projects:
            context_parts.append("\n=== DIRECT PROJECT SUMMARIES ===\n")
            for project in direct_projects[:5]:  # Limit to top 5 direct projects
                summaries_result = await session.execute(
                    select(Summary).where(
                        and_(
                            Summary.project_id == project.id,
                            Summary.summary_type == SummaryType.PROJECT,
                            Summary.created_at >= week_start - timedelta(days=14)
                        )
                    ).order_by(Summary.created_at.desc()).limit(1)
                )
                recent_summary = summaries_result.scalar_one_or_none()

                if recent_summary:
                    context_parts.append(f"\n{project.name}: {recent_summary.body[:300]}...\n")

        # 3. TIER 3: Critical alerts via semantic search
        if organization_id:
            logger.info("Tier 3: Performing semantic search for portfolio-wide critical alerts")
            context_parts.append("\n=== CRITICAL ALERTS (SEMANTIC SEARCH) ===\n")

            # Portfolio-level critical queries
            critical_queries = [
                "executive escalation board-level critical strategic",
                "budget overrun financial risk cost issues",
                "major milestone delays schedule risk"
            ]

            from services.rag.embedding_service import embedding_service

            for query in critical_queries:
                try:
                    query_embedding = await embedding_service.generate_embedding(query)

                    results = await multi_tenant_vector_store.search_vectors(
                        organization_id=organization_id,
                        query_vector=query_embedding,
                        collection_type="content",
                        limit=3,  # Top 3 per query (keep it minimal for portfolio level)
                        score_threshold=0.7  # Higher threshold for portfolio level
                    )

                    if results:
                        logger.info(f"Portfolio semantic search for '{query}' returned {len(results)} results")
                        context_parts.append(f"\nQuery: '{query}'\n")
                        for result in results:
                            payload = result.get('payload', {})
                            title = payload.get('title', 'Untitled')
                            context_parts.append(
                                f"- {title} (relevance: {result['score']:.2f})\n"
                                f"  {payload.get('content', '')[:200]}...\n"
                            )
                            logger.debug(f"Added portfolio result: {title} (score: {result['score']:.2f})")
                    else:
                        logger.info(f"Portfolio semantic search for '{query}' returned NO results (empty or below threshold)")
                except Exception as e:
                    logger.warning(f"Portfolio semantic search failed for '{query}': {e}")

        full_context = ''.join(context_parts)

        estimated_tokens = len(full_context) // 4
        logger.info(f"Built portfolio context with ~{estimated_tokens} tokens")

        if estimated_tokens > max_tokens:
            logger.warning(f"Portfolio context too large ({estimated_tokens} tokens), truncating")
            target_chars = max_tokens * 4
            full_context = full_context[:target_chars] + "\n\n[Context truncated due to size]"

        return full_context

    async def _generate_claude_summary_with_context(
        self,
        content_type: str,
        project_name: str,
        content_title: str,
        content_text: str,
        content_date: Any,
        additional_context: Optional[Dict[str, Any]] = None,
        job_id: Optional[str] = None,
        format_type: str = "general"
    ) -> Dict[str, Any]:
        """Generate summary using Claude API with Langfuse context managers."""
        langfuse_client = langfuse_service.client
        
        if not self.llm_client.is_available():
            logger.error("LLM client not available - cannot generate summary")
            raise ValueError("AI service is not configured. Please check your API settings.")
        
        try:
            # Build prompt based on summary type using imported functions
            if content_type == "meeting":
                prompt = get_meeting_summary_prompt(
                    project_name, content_title, content_text,
                    content_date.strftime("%Y-%m-%d") if content_date else "N/A",
                    format_type=format_type
                )
            elif content_type == "project":
                prompt = get_project_summary_prompt(
                    project_name, content_title, content_text,
                    additional_context.get("meeting_titles", []) if additional_context else [],
                    format_type=format_type
                )
            elif content_type == "program":
                project_list = []
                if additional_context and "project_names" in additional_context:
                    project_list = additional_context["project_names"]
                prompt = get_program_summary_prompt(
                    project_name, content_title, content_text,
                    project_list,
                    format_type=format_type
                )
            elif content_type == "portfolio":
                program_list = []
                project_list = []
                if additional_context:
                    program_list = additional_context.get("program_names", [])
                    project_list = additional_context.get("project_names", [])
                prompt = get_portfolio_summary_prompt(
                    project_name, content_title, content_text,
                    program_list, project_list,
                    format_type=format_type
                )
            else:
                prompt = get_project_summary_prompt(
                    project_name, content_title, content_text,
                    additional_context.get("meeting_titles", []) if additional_context else [],
                    format_type=format_type
                )
            
            # Update progress: Making API call (94%)
            if job_id:
                upload_job_service.update_job_progress(
                    job_id,
                    progress=94.0,
                    step_description="Calling Claude AI"
                )
            
            # Generate with Claude using context manager
            if langfuse_client and hasattr(langfuse_client, 'start_as_current_generation'):
                with langfuse_client.start_as_current_generation(
                    name=f"claude_{content_type}_summary",
                    model=self.llm_model,
                    model_parameters={
                        "max_tokens": self.max_tokens,
                        "temperature": self.temperature
                    },
                    input=prompt[:2000]  # Truncate for logging
                ) as gen_span:
                    # Make API call to Claude with retry logic
                    response = await self._call_claude_api_with_retry(prompt)
                    
                    # Update progress: Processing API response (96%)
                    if job_id:
                        upload_job_service.update_job_progress(
                            job_id,
                            progress=96.0,
                            step_description="Processing AI response"
                        )
                    
                    response_text = response.content[0].text
                    
                    # Calculate token usage and cost
                    input_tokens = response.usage.input_tokens
                    output_tokens = response.usage.output_tokens
                    total_tokens = input_tokens + output_tokens
                    cost = self._calculate_cost(input_tokens, output_tokens)
                    
                    # Update generation span
                    if hasattr(gen_span, 'update'):
                        gen_span.update(
                            output=response_text[:500],  # Truncate for logging
                            usage={
                                "input": input_tokens,
                                "output": output_tokens,
                                "total": total_tokens,
                                "unit": "TOKENS"
                            },
                            metadata={
                                "cost_usd": cost,
                                "content_type": content_type
                            }
                        )
            else:
                # Update progress: Making API call (94%)
                if job_id:
                    upload_job_service.update_job_progress(
                        job_id,
                        progress=94.0,
                        step_description="Calling Claude AI"
                    )
                
                # Fallback without context manager but with retry logic
                response = await self._call_claude_api_with_retry(prompt)
                
                # Update progress: Processing API response (96%)
                if job_id:
                    upload_job_service.update_job_progress(
                        job_id,
                        progress=96.0,
                        step_description="Processing AI response"
                    )
                
                response_text = response.content[0].text
                input_tokens = response.usage.input_tokens
                output_tokens = response.usage.output_tokens
                total_tokens = input_tokens + output_tokens
                cost = self._calculate_cost(input_tokens, output_tokens)
            
            # Parse structured response
            logger.info(f"DEBUG: Raw Claude response (first 500 chars): {response_text[:500]}")
            summary_data = self._parse_claude_response(response_text, content_type, content_title)
            logger.info(f"DEBUG: Parsed summary_data keys: {summary_data.keys()}")
            logger.info(f"DEBUG: Lessons learned in parsed data: {summary_data.get('lessons_learned', 'NOT FOUND')}")
            summary_data["token_count"] = total_tokens
            summary_data["cost_usd"] = cost

            return summary_data
            
        except Exception as e:
            logger.error(f"Claude API call failed: {e}")
            error_message = str(e).lower()

            # Handle different error types with proper exceptions
            if "overloaded" in error_message or "529" in str(e):
                raise LLMOverloadedException()
            elif "rate_limit" in error_message or "429" in str(e):
                raise LLMRateLimitException()
            elif "authentication" in error_message or "api_key" in error_message or "401" in str(e):
                raise LLMAuthenticationException()
            elif "timeout" in error_message or "504" in str(e):
                raise LLMTimeoutException()
            elif "insufficient" in error_message or "not enough" in error_message:
                raise InsufficientDataException()
            else:
                # For other errors, still raise ValueError but with the original error
                raise ValueError(f"Failed to generate summary: {str(e)}")
    
    def _parse_claude_response(
        self,
        response_text: str,
        content_type: str,
        content_title: str
    ) -> Dict[str, Any]:
        """Parse Claude's response into structured data."""
        try:
            import json
            # Try to parse as JSON
            if "{" in response_text and "}" in response_text:
                json_start = response_text.index("{")
                json_end = response_text.rindex("}") + 1
                json_str = response_text[json_start:json_end]
                data = json.loads(json_str)
                
                # Process action items to ensure they have the expected structure
                action_items = data.get("action_items", [])
                if action_items:
                    logger.info(f"Raw action_items from Claude: {action_items[:2]}")  # Log first 2 items for debugging
                processed_action_items = []
                for item in action_items:
                    if isinstance(item, dict):
                        # Handle enhanced format with title, priority, question_to_ask, and confidence
                        title = item.get("title", "")
                        description = item.get("description", "")

                        # Fallback for description if missing
                        if not description:
                            # Try alternative field names
                            description = item.get("task", "") or item.get("action", "") or title

                        # If we have a title but no description, use title as description
                        if title and not description:
                            description = title

                        # Ensure all string fields are strings and lists are lists
                        urgency = item.get("urgency", "medium")
                        if isinstance(urgency, (int, float)):
                            urgency = str(urgency)

                        # Handle priority field (new in enhanced format)
                        priority = item.get("priority", urgency)  # Use urgency as fallback
                        if not isinstance(priority, str):
                            priority = str(priority) if priority else "medium"

                        due_date = item.get("due_date")
                        if due_date is not None and not isinstance(due_date, str):
                            due_date = str(due_date)

                        assignee = item.get("assignee")
                        if assignee is not None and not isinstance(assignee, str):
                            assignee = str(assignee)

                        dependencies = item.get("dependencies", [])
                        if not isinstance(dependencies, list):
                            dependencies = [str(dependencies)] if dependencies else []

                        status = item.get("status", "not_started")
                        if not isinstance(status, str):
                            status = str(status)

                        # Get question_to_ask for communication tasks (new in enhanced format)
                        question_to_ask = item.get("question_to_ask")
                        if question_to_ask and not isinstance(question_to_ask, str):
                            question_to_ask = str(question_to_ask)

                        # Get confidence score (new in enhanced format)
                        confidence = item.get("confidence", 1.0)
                        if not isinstance(confidence, (int, float)):
                            confidence = 1.0

                        # If still no description, create one from other fields
                        if not description and assignee:
                            description = f"Task for {assignee}"
                            if item.get("due_date"):
                                description += f" (due {item.get('due_date')})"

                        # Build action item dict - include both old and new fields for compatibility
                        action_item = {
                            "description": str(description) if description else "Task description not provided",
                            "urgency": urgency,
                            "due_date": due_date,
                            "assignee": assignee,
                            "dependencies": dependencies,
                            "status": status,
                            "follow_up_required": bool(item.get("follow_up_required", False))
                        }

                        # Add enhanced fields if present
                        if title:
                            action_item["title"] = str(title)
                        if priority and priority != urgency:
                            action_item["priority"] = priority
                        if question_to_ask:
                            action_item["question_to_ask"] = question_to_ask
                        if confidence != 1.0:
                            action_item["confidence"] = float(confidence)

                        processed_action_items.append(action_item)
                    elif isinstance(item, str):
                        # Backward compatibility: convert string to new format
                        processed_action_items.append({
                            "description": item,
                            "urgency": "medium",
                            "due_date": None,
                            "assignee": None,
                            "dependencies": [],
                            "status": "not_started",
                            "follow_up_required": False
                        })
                
                # Process decisions to ensure they have the expected structure
                decisions = data.get("decisions", [])
                logger.info(f"Raw decisions from Claude: {decisions}")
                processed_decisions = []
                for decision in decisions:
                    if isinstance(decision, dict):
                        # Handle both "description" and "title" fields (Claude sometimes uses "title")
                        description = decision.get("description") or decision.get("title", "")

                        # Handle importance_score - Claude might return "importance", "strategic_impact", or numeric value
                        importance = decision.get("importance_score") or decision.get("importance")
                        strategic_impact = decision.get("strategic_impact", "")

                        if not importance:
                            if strategic_impact:
                                # If strategic_impact contains text, use "high" as default for executive summaries
                                importance = "high"
                            else:
                                importance = "medium"

                        # Convert to string if it's not already
                        if isinstance(importance, (int, float)):
                            importance = str(importance)
                        elif isinstance(importance, str):
                            # Normalize to lowercase for consistency
                            importance = importance.lower()
                            if importance not in ['critical', 'high', 'medium', 'low']:
                                importance = 'medium'

                        # Ensure stakeholders_affected is always a list
                        stakeholders = decision.get("stakeholders_affected", [])
                        if not isinstance(stakeholders, list):
                            stakeholders = [str(stakeholders)] if stakeholders else []

                        # Ensure decision_type is a string
                        decision_type = decision.get("decision_type", "strategic" if importance == "high" else "operational")
                        if not isinstance(decision_type, str):
                            decision_type = str(decision_type)

                        # Use expected_outcome as rationale if rationale is missing
                        rationale = decision.get("rationale") or decision.get("expected_outcome")

                        # Get confidence score (new in enhanced format)
                        confidence = decision.get("confidence", 1.0)
                        if not isinstance(confidence, (int, float)):
                            confidence = 1.0

                        processed_decision = {
                            "description": str(description),
                            "importance_score": importance,
                            "decision_type": decision_type,
                            "stakeholders_affected": stakeholders,
                            "rationale": rationale or strategic_impact  # Use strategic_impact as rationale if rationale is missing
                        }

                        # Add confidence if not default
                        if confidence != 1.0:
                            processed_decision["confidence"] = float(confidence)

                        logger.debug(f"Processed decision: {processed_decision}")
                        processed_decisions.append(processed_decision)
                    elif isinstance(decision, str):
                        # Backward compatibility: convert string to new format
                        processed_decisions.append({
                            "description": decision,
                            "importance_score": "medium",
                            "decision_type": "operational",
                            "stakeholders_affected": [],
                            "rationale": None
                        })

                logger.info(f"Processed {len(processed_decisions)} decisions from {len(decisions)} raw decisions")

                # Process next_meeting_agenda to ensure proper structure
                next_agenda = data.get("next_meeting_agenda", [])
                processed_agenda = []
                for agenda_item in next_agenda:
                    if isinstance(agenda_item, dict):
                        # Ensure all fields have the expected types
                        processed_agenda.append({
                            "title": str(agenda_item.get("title", "")),
                            "description": str(agenda_item.get("description", "")),
                            "priority": str(agenda_item.get("priority", "medium")),
                            "estimated_time": int(agenda_item.get("estimated_time", 15)),
                            "presenter": agenda_item.get("presenter"),
                            "related_action_items": agenda_item.get("related_action_items", []),
                            "category": str(agenda_item.get("category", "discussion"))
                        })
                
                # Process communication insights
                communication_insights_raw = data.get("communication_insights", {})
                logger.info(f"Raw communication_insights from Claude: {communication_insights_raw}")

                # Ensure communication_insights_raw is a dict
                if not isinstance(communication_insights_raw, dict):
                    communication_insights_raw = {}

                # Always process communication insights, even if empty
                # Process unanswered questions
                unanswered_questions = communication_insights_raw.get("unanswered_questions", [])
                processed_questions = []
                for question in unanswered_questions:
                    if isinstance(question, dict):
                        processed_questions.append({
                            "question": str(question.get("question", "")),
                            "context": str(question.get("context", "")),
                            "urgency": str(question.get("urgency", "medium")),
                            "raised_by": question.get("raised_by"),
                            "topic_area": str(question.get("topic_area", ""))
                        })

                # Process improvement suggestions
                improvement_suggestions = communication_insights_raw.get("improvement_suggestions", [])
                processed_suggestions = []
                for suggestion in improvement_suggestions:
                    if isinstance(suggestion, dict):
                        processed_suggestions.append({
                            "suggestion": str(suggestion.get("suggestion", "")),
                            "category": str(suggestion.get("category", "general")),
                            "priority": str(suggestion.get("priority", "medium")),
                            "expected_impact": str(suggestion.get("expected_impact", ""))
                        })

                # Normalize effectiveness scores from 0-10 to 0-1 for frontend
                effectiveness_raw = communication_insights_raw.get("effectiveness_score", {})
                effectiveness_normalized = {}
                if effectiveness_raw:
                    # Check if effectiveness_raw is a dict or handle individual float values
                    if isinstance(effectiveness_raw, dict):
                        # Map and normalize the fields to match frontend model
                        clarity = effectiveness_raw.get("clarity", 0)
                        engagement = effectiveness_raw.get("engagement", 0)
                        productivity = effectiveness_raw.get("productivity", 0)
                    else:
                        # Handle cases where Claude returns float values directly
                        # Try to get individual scores from communication_insights_raw
                        clarity = communication_insights_raw.get("clarity_score", 0) if isinstance(communication_insights_raw.get("clarity_score"), (int, float)) else 0
                        engagement = communication_insights_raw.get("effectiveness_score", 0) if isinstance(communication_insights_raw.get("effectiveness_score"), (int, float)) else 0
                        productivity = communication_insights_raw.get("participation_balance", 0) if isinstance(communication_insights_raw.get("participation_balance"), (int, float)) else 0

                    # Normalize from 0-10 to 0-1 scale
                    clarity_norm = clarity / 10.0 if isinstance(clarity, (int, float)) else 0.0
                    engagement_norm = engagement / 10.0 if isinstance(engagement, (int, float)) else 0.0
                    productivity_norm = productivity / 10.0 if isinstance(productivity, (int, float)) else 0.0

                    # Calculate overall as average of the three scores
                    overall = (clarity_norm + engagement_norm + productivity_norm) / 3.0

                    effectiveness_normalized = {
                        "overall": overall,
                        "clarity_score": clarity_norm,  # Map to frontend field name
                        "time_efficiency": engagement_norm,  # Map engagement to time_efficiency
                        "participation_balance": productivity_norm  # Map productivity to participation_balance
                    }

                communication_insights = {
                    "unanswered_questions": processed_questions,
                    "effectiveness_score": effectiveness_normalized,
                    "improvement_suggestions": processed_suggestions
                }
                logger.info(f"Processed communication_insights: {communication_insights}")
                
                # Build response based on content type
                response_data = {
                    "summary_text": data.get("summary_text", ""),
                    "key_points": data.get("key_points", []),
                    "decisions": processed_decisions,
                    "action_items": processed_action_items,
                    "risks": data.get("risks", []),
                    "blockers": data.get("blockers", [])
                }

                # Add type-specific fields based on content_type
                if content_type == "meeting":
                    # DEBUG: Log lessons learned processing
                    lessons_learned_raw = data.get("lessons_learned", [])
                    logger.info(f"DEBUG: Raw lessons_learned from JSON: {lessons_learned_raw}")

                    response_data.update({
                        "participants": data.get("participants", []),
                        "sentiment": data.get("sentiment", {}),
                        "communication_insights": communication_insights,
                        "next_meeting_agenda": processed_agenda,
                        "lessons_learned": lessons_learned_raw  # Add lessons learned to response
                    })
                elif content_type == "program":
                    response_data.update({
                        "cross_project_dependencies": data.get("cross_project_dependencies", []),
                        "resource_metrics": data.get("resource_metrics", {}),
                        "program_health": data.get("program_health", {}),
                        "financial_summary": data.get("financial_summary", {}),
                        "strategic_alignment": data.get("strategic_alignment", {}),
                        "technical_metrics": data.get("technical_metrics", {}),
                        "architecture_insights": data.get("architecture_insights", {}),
                        "value_delivered": data.get("value_delivered", {}),
                        "stakeholder_feedback": data.get("stakeholder_feedback", {}),
                        "next_meeting_agenda": processed_agenda  # Add next_meeting_agenda for program summaries
                    })
                elif content_type == "portfolio":
                    response_data.update({
                        "program_performance": data.get("program_performance", []),
                        "portfolio_metrics": data.get("portfolio_metrics", {}),
                        "strategic_initiatives": data.get("strategic_initiatives", []),
                        "governance_items": data.get("governance_items", []),
                        "executive_dashboard": data.get("executive_dashboard", {}),
                        "board_items": data.get("board_items", []),
                        "investment_analysis": data.get("investment_analysis", {}),
                        "enterprise_architecture": data.get("enterprise_architecture", {}),
                        "technology_landscape": data.get("technology_landscape", {}),
                        "capability_assessment": data.get("capability_assessment", {}),
                        "business_outcomes": data.get("business_outcomes", {}),
                        "stakeholder_matrix": data.get("stakeholder_matrix", []),
                        "value_realization": data.get("value_realization", {}),
                        "next_meeting_agenda": processed_agenda  # Add next_meeting_agenda for portfolio summaries
                    })
                elif content_type == "project":
                    # Also add lessons learned for project summaries
                    lessons_learned_raw = data.get("lessons_learned", [])
                    logger.info(f"DEBUG: Project summary lessons_learned: {lessons_learned_raw}")

                    response_data.update({
                        "participants": data.get("participants", []),
                        "sentiment": data.get("sentiment", {}),
                        "communication_insights": communication_insights,
                        "next_meeting_agenda": processed_agenda,
                        "lessons_learned": lessons_learned_raw  # Add lessons learned to response
                    })

                return response_data
        except Exception as e:
            logger.warning(f"Failed to parse Claude response as JSON: {e}")
        
        # Fallback: return response as summary text with empty enhanced fields
        fallback_response = {
            "summary_text": response_text,
            "key_points": [],
            "decisions": [],
            "action_items": [],
            "risks": [],
            "blockers": []
        }

        # Add type-specific empty fields for fallback
        if content_type in ["meeting", "project"]:
            fallback_response.update({
                "participants": [],
                "sentiment": {},
                "communication_insights": {},
                "next_meeting_agenda": [],
                "lessons_learned": []  # Add empty lessons learned for fallback
            })
        elif content_type == "program":
            fallback_response.update({
                "cross_project_dependencies": [],
                "resource_metrics": {},
                "program_health": {}
            })
        elif content_type == "portfolio":
            fallback_response.update({
                "program_performance": [],
                "portfolio_metrics": {},
                "strategic_initiatives": [],
                "governance_items": []
            })

        return fallback_response
    
    def _calculate_cost(self, input_tokens: int, output_tokens: int) -> float:
        """Calculate the cost based on token usage."""
        # Claude 3.5 Haiku pricing (as of 2025)
        input_cost_per_million = 0.80
        output_cost_per_million = 4.00
        
        input_cost = (input_tokens / 1_000_000) * input_cost_per_million
        output_cost = (output_tokens / 1_000_000) * output_cost_per_million
        
        return input_cost + output_cost
    
    def _process_claude_sentiment(self, summary_data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """Process sentiment analysis from Claude's response into expected format."""
        try:
            sentiment_data = summary_data.get("sentiment", {})
            
            if not sentiment_data:
                # Return default neutral sentiment if not provided
                return {
                    "overall": "neutral",
                    "overall_score": 0.5,  # Add numerical score
                    "trajectory": ["neutral"],
                    "topics": {},
                    "engagement": {},
                    "scores": {
                        "positive": 0.33,
                        "neutral": 0.34,
                        "negative": 0.33
                    },
                    "meeting_dynamics": {
                        "participation_balance": 0.5,
                        "collaboration_indicators": 0.5,
                        "conflict_indicators": 0.0,
                        "consensus_building_score": 0.5,
                        "decision_making_efficiency": 0.5
                    }
                }
            
            # Process dynamics data
            dynamics = sentiment_data.get("dynamics", {})
            meeting_dynamics = {
                "participation_balance": 0.5,  # Default balanced
                "collaboration_indicators": dynamics.get("collaboration_score", 0.5),
                "conflict_indicators": dynamics.get("conflict_indicators", 0.0),
                "consensus_building_score": dynamics.get("consensus_level", 0.5),
                "decision_making_efficiency": 0.5  # Could be calculated from decisions/duration
            }
            
            # Calculate sentiment scores from overall sentiment
            overall = sentiment_data.get("overall", "neutral").lower()
            scores = {
                "positive": 0.0,
                "neutral": 0.0,
                "negative": 0.0
            }

            # Calculate overall_score (0-1 scale where 1 is most positive)
            overall_score = 0.5  # Default neutral

            if overall == "positive":
                scores = {"positive": 0.7, "neutral": 0.2, "negative": 0.1}
                overall_score = 0.7
            elif overall == "negative":
                scores = {"positive": 0.1, "neutral": 0.2, "negative": 0.7}
                overall_score = 0.2
            elif overall == "mixed":
                scores = {"positive": 0.35, "neutral": 0.3, "negative": 0.35}
                overall_score = 0.5
            else:  # neutral
                scores = {"positive": 0.2, "neutral": 0.6, "negative": 0.2}
                overall_score = 0.5

            return {
                "overall": overall,
                "overall_score": overall_score,  # Add numerical score for frontend
                "trajectory": sentiment_data.get("trajectory", [overall]),
                "topics": sentiment_data.get("topics", {}),
                "engagement": sentiment_data.get("engagement", {}),
                "scores": scores,
                "meeting_dynamics": meeting_dynamics
            }
            
        except Exception as e:
            logger.error(f"Failed to process Claude sentiment: {e}")
            return None
    
    def _convert_numeric_to_severity_string(self, value: Any) -> str:
        """Convert numeric severity/impact (0-1) or string to standard severity level."""
        if isinstance(value, str):
            # If it's already a string, validate and return
            valid_severities = ["critical", "high", "medium", "low"]
            severity_lower = value.lower()
            return severity_lower if severity_lower in valid_severities else "medium"

        # Convert numeric to string
        try:
            severity_num = float(value)
            if severity_num >= 0.9:
                return "critical"
            elif severity_num >= 0.7:
                return "high"
            elif severity_num >= 0.4:
                return "medium"
            else:
                return "low"
        except (ValueError, TypeError):
            return "medium"

    def _process_claude_risks_blockers(self, summary_data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """Process risks and blockers from Claude's response into expected format."""
        try:
            risks = summary_data.get("risks", [])
            blockers = summary_data.get("blockers", [])

            logger.info(f"Processing Claude risks and blockers - Risks: {len(risks)}, Blockers: {len(blockers)}")
            logger.debug(f"Raw risks: {risks}")
            logger.debug(f"Raw blockers: {blockers}")

            # Valid risk statuses from the RiskStatus enum
            valid_risk_statuses = ['identified', 'mitigating', 'resolved', 'accepted', 'escalated']

            # Mapping for common incorrect statuses to valid ones
            risk_status_mapping = {
                'active': 'identified',  # 'active' is for blockers, not risks
                'pending': 'identified',
                'in_progress': 'mitigating',
                'closed': 'resolved',
                'done': 'resolved'
            }

            # Transform risks into expected format
            processed_risks = []
            for risk in risks:
                if isinstance(risk, dict):
                    # Preserve both title and description fields
                    title = risk.get("title", "")
                    description = risk.get("description", "")

                    # If title is missing but description exists, create title from description
                    if not title and description:
                        title = description[:100].split('.')[0]
                        if len(title) > 80:
                            title = title[:77] + '...'
                    elif not title and not description:
                        title = "Risk identified in meeting"

                    mitigation = risk.get("mitigation") or risk.get("mitigation_strategy")

                    # Convert numeric severity to string
                    raw_severity = risk.get("severity", "medium")
                    severity = self._convert_numeric_to_severity_string(raw_severity)

                    # Get category and convert to string if needed
                    category = risk.get("category", "general")
                    if isinstance(category, str):
                        category = category.lower()
                    else:
                        category = "general"

                    # Get owner and ensure it's a string or None
                    owner = risk.get("owner")
                    if owner and not isinstance(owner, str):
                        owner = str(owner) if owner else None

                    # Validate and map risk status
                    risk_status = risk.get("status", "identified")
                    if isinstance(risk_status, str):
                        risk_status = risk_status.lower()
                        # Map invalid status to valid one
                        if risk_status not in valid_risk_statuses:
                            original_status = risk_status
                            risk_status = risk_status_mapping.get(risk_status, 'identified')
                            logger.warning(f"Invalid risk status '{original_status}' mapped to '{risk_status}' for risk '{title}'")

                    processed_risks.append({
                        "title": str(title),
                        "description": str(description),
                        "severity": severity,
                        "status": risk_status,
                        "category": category,
                        "owner": owner,
                        "mitigation": mitigation,
                        "impact": risk.get("impact"),
                        "confidence": risk.get("confidence", 0.8),
                        "identified_by": risk.get("identified_by") if isinstance(risk.get("identified_by"), str) else None
                    })
                elif isinstance(risk, str):
                    # If Claude returns strings instead of objects
                    # Create title from string (first part of description)
                    title = risk[:100].split('.')[0] if risk else "Risk identified"
                    if len(title) > 80:
                        title = title[:77] + '...'

                    processed_risks.append({
                        "title": title,
                        "description": risk,
                        "severity": "medium",
                        "status": "identified",
                        "category": "general",
                        "owner": None,
                        "mitigation": None,
                        "impact": None,
                        "confidence": 0.8,
                        "identified_by": None
                    })
            
            # Transform blockers into expected format
            processed_blockers = []
            for blocker in blockers:
                if isinstance(blocker, dict):
                    # Preserve both title and description fields
                    title = blocker.get("title", "")
                    description = blocker.get("description", "")

                    # If title is missing but description exists, create title from description
                    if not title and description:
                        title = description[:100].split('.')[0]
                        if len(title) > 80:
                            title = title[:77] + '...'
                    elif not title and not description:
                        title = "Blocker identified in meeting"

                    resolution = blocker.get("resolution") or blocker.get("required_action")

                    # Convert numeric impact to string (same scale as severity)
                    raw_impact = blocker.get("impact", "medium")
                    impact = self._convert_numeric_to_severity_string(raw_impact)

                    # Get category and convert to string if needed
                    category = blocker.get("category", "general")
                    if isinstance(category, str):
                        category = category.lower()
                    else:
                        category = "general"

                    # Get status and ensure it's a string
                    status = blocker.get("status", "active")
                    if isinstance(status, str):
                        status = status.lower()
                    else:
                        status = "active"

                    # Get owner and ensure it's a string or None
                    owner = blocker.get("owner")
                    if owner and not isinstance(owner, str):
                        owner = str(owner) if owner else None

                    processed_blockers.append({
                        "title": str(title),
                        "description": str(description),
                        "impact": impact,
                        "status": status,
                        "category": category,
                        "owner": owner,
                        "resolution": resolution,
                        "confidence": blocker.get("confidence", 0.8),
                        "dependencies": blocker.get("dependencies") if isinstance(blocker.get("dependencies"), list) else None
                    })
                elif isinstance(blocker, str):
                    # If Claude returns strings instead of objects
                    # Create title from string (first part of description)
                    title = blocker[:100].split('.')[0] if blocker else "Blocker identified"
                    if len(title) > 80:
                        title = title[:77] + '...'

                    processed_blockers.append({
                        "title": title,
                        "description": blocker,
                        "impact": "medium",
                        "status": "active",
                        "category": "general",
                        "owner": None,
                        "resolution": None,
                        "confidence": 0.8,
                        "dependencies": None
                    })
            
            # Calculate metrics
            critical_count = sum(1 for r in processed_risks if r["severity"] == "critical")
            critical_count += sum(1 for b in processed_blockers if b["impact"] == "critical")
            
            mitigation_count = sum(1 for r in processed_risks if r.get("mitigation"))
            mitigation_coverage = (mitigation_count / len(processed_risks)) if processed_risks else 0.0
            
            # Calculate risk score
            severity_weights = {"critical": 10, "high": 7, "medium": 4, "low": 1}
            total_score = sum(severity_weights.get(r["severity"], 0) for r in processed_risks)
            max_possible = len(processed_risks) * 10 if processed_risks else 1
            risk_score = min((total_score / max_possible) * 100, 100.0) if max_possible > 0 else 0.0
            
            # Determine timeline impact
            if critical_count > 0:
                timeline_impact = "high_risk"
            elif len(processed_blockers) > 2:
                timeline_impact = "moderate_risk"
            elif processed_risks:
                timeline_impact = "low_risk"
            else:
                timeline_impact = "on_track"
            
            return {
                "risks": processed_risks,
                "blockers": processed_blockers,
                "total_risk_score": risk_score,
                "critical_count": critical_count,
                "mitigation_coverage": mitigation_coverage,
                "categories": {},
                "timeline_impact": timeline_impact
            }
            
        except Exception as e:
            logger.error(f"Failed to process Claude risks and blockers: {e}")
            return None
    
    async def _generate_meeting_summary_fallback(
        self,
        session: AsyncSession,
        project_id: uuid.UUID,
        content_id: uuid.UUID,
        created_by: Optional[str] = None,
        job_id: Optional[str] = None
    ) -> Dict[str, Any]:
        """Fallback implementation without context managers."""
        logger.error("Langfuse context managers not available for meeting summary generation")
        raise ValueError("Summary generation service is not properly configured. Please contact support.")
    
    async def _generate_project_summary_fallback(
        self,
        session: AsyncSession,
        project_id: uuid.UUID,
        week_start: datetime,
        week_end: Optional[datetime] = None,
        created_by: Optional[str] = None,
        format_type: str = "general"
    ) -> Dict[str, Any]:
        """Fallback implementation without context managers."""
        logger.error("Langfuse context managers not available for project summary generation")
        raise ValueError("Summary generation service is not properly configured. Please contact support.")


# Global service instance
summary_service = SummaryService()