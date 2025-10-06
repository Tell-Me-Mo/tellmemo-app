from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from typing import List, Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_, update
from datetime import datetime

from db.database import get_db
from dependencies.auth import get_current_organization, get_current_user, require_role
from models.organization import Organization
from models.user import User
from models.project import Project
from models.program import Program
from models.portfolio import Portfolio
from models.conversation import Conversation
from services.rag.enhanced_rag_service_refactored import enhanced_rag_service
from services.rag.conversation_context_service import conversation_context_service
from services.activity.activity_service import ActivityService
from utils.logger import get_logger
import uuid

router = APIRouter()
logger = get_logger(__name__)


class QueryRequest(BaseModel):
    question: str
    conversation_id: Optional[str] = None  # UUID of existing conversation, if any


class QueryResponse(BaseModel):
    answer: str
    sources: List[str]
    confidence: float
    conversation_id: str  # UUID of the conversation this Q&A belongs to
    is_followup: bool = False  # Whether this was detected as a follow-up question


@router.post("/organization/query", response_model=QueryResponse)
async def query_organization(
    request: QueryRequest,
    session: AsyncSession = Depends(get_db),
    current_org: Organization = Depends(get_current_organization),
    current_user: User = Depends(get_current_user),
    _: str = Depends(require_role("member"))
):
    """
    Query all organization content (across all projects) using unified RAG search.

    Args:
        request: Query request containing the question and optional conversation_id
        session: Database session

    Returns:
        QueryResponse with answer, sources, confidence, conversation_id, and is_followup
    """
    logger.info(f"Querying organization {current_org.id}: {request.question}")

    try:
        # Get all projects in this organization
        all_projects_result = await session.execute(
            select(Project).where(
                Project.organization_id == current_org.id
            )
        )
        all_projects = all_projects_result.scalars().all()

        if not all_projects:
            raise HTTPException(
                status_code=404,
                detail=f"No projects found in organization"
            )

        project_ids = [str(p.id) for p in all_projects]
        logger.info(f"Querying {len(project_ids)} projects in organization {current_org.name}")

        # Handle conversation context
        conversation = None
        conversation_messages = []
        is_followup = False
        actual_question = request.question

        if request.conversation_id:
            conversation, conversation_messages = await conversation_context_service.get_conversation_context(
                conversation_id=request.conversation_id,
                session=session,
                organization_id=str(current_org.id)
            )

            if conversation:
                is_followup = await conversation_context_service.detect_followup_question(
                    question=request.question,
                    conversation_messages=conversation_messages
                )

                if is_followup:
                    actual_question = await conversation_context_service.enhance_query_with_context(
                        question=request.question,
                        conversation_messages=conversation_messages
                    )
                    logger.info(f"Enhanced follow-up question with context for conversation {request.conversation_id}")

        # Use unified multi-project RAG query
        rag_response = await enhanced_rag_service.query_multiple_projects(
            project_ids=project_ids,
            question=actual_question,
            user_id=current_user.email,
            organization_id=str(current_org.id)
        )

        # Create or update conversation
        conversation_id = request.conversation_id

        if not conversation:
            conversation_title = conversation_context_service.create_conversation_title(request.question)
            new_conversation = Conversation(
                project_id=None,  # Organization-level conversation
                organization_id=current_org.id,
                title=f"[Organization: {current_org.name}] {conversation_title}",
                messages=[],
                created_by=current_user.email or "unknown",
                created_at=datetime.utcnow(),
                last_accessed_at=datetime.utcnow()
            )
            session.add(new_conversation)
            await session.flush()
            conversation_id = str(new_conversation.id)
            conversation = new_conversation

        # Add current Q&A to conversation messages
        new_message = conversation_context_service.format_message_for_storage(
            question=request.question,
            answer=rag_response['answer'],
            sources=rag_response['sources'][:10],
            confidence=rag_response['confidence']
        )

        # Update conversation
        updated_messages = (conversation.messages or []) + [new_message]
        await session.execute(
            update(Conversation)
            .where(Conversation.id == conversation_id)
            .values(
                messages=updated_messages,
                last_accessed_at=datetime.utcnow()
            )
        )

        await session.commit()

        # Note: Activity logging skipped for organization-level queries as they don't belong to a specific project
        # Activities are tracked at the project level via ActivityService.log_query_submitted

        logger.info(
            f"Organization query completed - conversation_id: {conversation_id}, "
            f"is_followup: {is_followup}, projects_with_results: {rag_response.get('projects_with_results', 0)}"
        )

        return QueryResponse(
            answer=rag_response['answer'],
            sources=rag_response['sources'][:10],
            confidence=rag_response['confidence'],
            conversation_id=conversation_id,
            is_followup=is_followup
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Query failed for organization {current_org.id}: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/{project_id}/query", response_model=QueryResponse)
async def query_project(
    project_id: str,
    request: QueryRequest,
    session: AsyncSession = Depends(get_db),
    current_org: Organization = Depends(get_current_organization),
    current_user: User = Depends(get_current_user),
    _: str = Depends(require_role("member"))
):
    """
    Query project content using RAG system with conversation context awareness.

    Args:
        project_id: UUID of the project
        request: Query request containing the question and optional conversation_id
        session: Database session

    Returns:
        QueryResponse with answer, sources, confidence, conversation_id, and is_followup
    """
    logger.info(f"Querying project {project_id}: {request.question}")

    try:
        # Verify project exists and belongs to current organization
        result = await session.execute(
            select(Project).where(
                and_(
                    Project.id == project_id,
                    Project.organization_id == current_org.id
                )
            )
        )
        project = result.scalar_one_or_none()

        if not project:
            raise HTTPException(status_code=404, detail=f"Project {project_id} not found")

        # Handle conversation context
        conversation = None
        conversation_messages = []
        is_followup = False
        actual_question = request.question

        if request.conversation_id:
            # Get existing conversation context
            conversation, conversation_messages = await conversation_context_service.get_conversation_context(
                conversation_id=request.conversation_id,
                session=session,
                organization_id=str(current_org.id)
            )

            if conversation:
                # Detect if this is a follow-up question
                is_followup = await conversation_context_service.detect_followup_question(
                    question=request.question,
                    conversation_messages=conversation_messages
                )

                if is_followup:
                    # Enhance query with conversation context
                    actual_question = await conversation_context_service.enhance_query_with_context(
                        question=request.question,
                        conversation_messages=conversation_messages
                    )
                    logger.info(f"Enhanced follow-up question with context for conversation {request.conversation_id}")

        # Execute enhanced RAG query with context-aware question
        response = await enhanced_rag_service.query_project(
            project_id=project_id,
            question=actual_question
        )

        # Create or update conversation
        conversation_id = request.conversation_id

        if not conversation:
            # Create new conversation
            conversation_title = conversation_context_service.create_conversation_title(request.question)
            new_conversation = Conversation(
                project_id=uuid.UUID(project_id),
                organization_id=current_org.id,
                title=conversation_title,
                messages=[],
                created_by=current_user.email or "unknown",
                created_at=datetime.utcnow(),
                last_accessed_at=datetime.utcnow()
            )
            session.add(new_conversation)
            await session.flush()  # Get the ID
            conversation_id = str(new_conversation.id)
            conversation = new_conversation

        # Add current Q&A to conversation messages
        new_message = conversation_context_service.format_message_for_storage(
            question=request.question,
            answer=response['answer'],
            sources=response['sources'],
            confidence=response['confidence']
        )

        # Update conversation with new message and last accessed time
        updated_messages = (conversation.messages or []) + [new_message]
        await session.execute(
            update(Conversation)
            .where(Conversation.id == conversation_id)
            .values(
                messages=updated_messages,
                last_accessed_at=datetime.utcnow()
            )
        )

        # Log activity for query submission
        try:
            project_uuid = uuid.UUID(project_id)
            await ActivityService.log_query_submitted(
                db=session,
                project_id=project_uuid,
                query_text=request.question,
                user_name=current_user.email or "unknown"
            )
            await session.commit()
        except Exception as e:
            logger.warning(f"Failed to log query activity: {e}")
            # Still commit conversation updates
            await session.commit()

        logger.info(f"Query completed - conversation_id: {conversation_id}, is_followup: {is_followup}")

        return QueryResponse(
            answer=response['answer'],
            sources=response['sources'][:10],  # Limit to 10 sources for consistency
            confidence=response['confidence'],
            conversation_id=conversation_id,
            is_followup=is_followup
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Query failed for project {project_id}: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/program/{program_id}/query", response_model=QueryResponse)
async def query_program(
    program_id: str,
    request: QueryRequest,
    session: AsyncSession = Depends(get_db),
    current_org: Organization = Depends(get_current_organization),
    current_user: User = Depends(get_current_user),
    _: str = Depends(require_role("member"))
):
    """
    Query program content (across all projects in the program) using unified RAG search.

    Args:
        program_id: UUID of the program
        request: Query request containing the question and optional conversation_id
        session: Database session

    Returns:
        QueryResponse with answer, sources, confidence, conversation_id, and is_followup
    """
    logger.info(f"Querying program {program_id}: {request.question}")

    try:
        # Verify program exists and belongs to current organization
        result = await session.execute(
            select(Program).where(
                and_(
                    Program.id == program_id,
                    Program.organization_id == current_org.id
                )
            )
        )
        program = result.scalar_one_or_none()

        if not program:
            raise HTTPException(status_code=404, detail=f"Program {program_id} not found")

        # Get all projects in this program
        projects_result = await session.execute(
            select(Project).where(
                and_(
                    Project.program_id == program_id,
                    Project.organization_id == current_org.id
                )
            )
        )
        projects = projects_result.scalars().all()

        if not projects:
            raise HTTPException(
                status_code=404,
                detail=f"No projects found in program {program_id}"
            )

        project_ids = [str(p.id) for p in projects]
        logger.info(f"Querying {len(project_ids)} projects in program {program.name}")

        # Handle conversation context
        conversation = None
        conversation_messages = []
        is_followup = False
        actual_question = request.question

        if request.conversation_id:
            # Get existing conversation context
            conversation, conversation_messages = await conversation_context_service.get_conversation_context(
                conversation_id=request.conversation_id,
                session=session,
                organization_id=str(current_org.id)
            )

            if conversation:
                # Detect if this is a follow-up question
                is_followup = await conversation_context_service.detect_followup_question(
                    question=request.question,
                    conversation_messages=conversation_messages
                )

                if is_followup:
                    # Enhance query with conversation context
                    actual_question = await conversation_context_service.enhance_query_with_context(
                        question=request.question,
                        conversation_messages=conversation_messages
                    )
                    logger.info(f"Enhanced follow-up question with context for conversation {request.conversation_id}")

        # Use unified multi-project RAG query
        rag_response = await enhanced_rag_service.query_multiple_projects(
            project_ids=project_ids,
            question=actual_question,
            user_id=current_user.email,
            organization_id=str(current_org.id)
        )

        # Create or update conversation (using program_id as the entity)
        conversation_id = request.conversation_id

        if not conversation:
            # Create new conversation (store with program_id as project_id)
            conversation_title = conversation_context_service.create_conversation_title(request.question)
            new_conversation = Conversation(
                project_id=uuid.UUID(program_id),
                organization_id=current_org.id,
                title=f"[Program: {program.name}] {conversation_title}",
                messages=[],
                created_by=current_user.email or "unknown",
                created_at=datetime.utcnow(),
                last_accessed_at=datetime.utcnow()
            )
            session.add(new_conversation)
            await session.flush()
            conversation_id = str(new_conversation.id)
            conversation = new_conversation

        # Add current Q&A to conversation messages
        new_message = conversation_context_service.format_message_for_storage(
            question=request.question,
            answer=rag_response['answer'],
            sources=rag_response['sources'][:10],
            confidence=rag_response['confidence']
        )

        # Update conversation with new message and last accessed time
        updated_messages = (conversation.messages or []) + [new_message]
        await session.execute(
            update(Conversation)
            .where(Conversation.id == conversation_id)
            .values(
                messages=updated_messages,
                last_accessed_at=datetime.utcnow()
            )
        )

        await session.commit()

        logger.info(
            f"Program query completed - conversation_id: {conversation_id}, "
            f"is_followup: {is_followup}, projects_with_results: {rag_response.get('projects_with_results', 0)}"
        )

        return QueryResponse(
            answer=rag_response['answer'],
            sources=rag_response['sources'][:10],
            confidence=rag_response['confidence'],
            conversation_id=conversation_id,
            is_followup=is_followup
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Query failed for program {program_id}: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/portfolio/{portfolio_id}/query", response_model=QueryResponse)
async def query_portfolio(
    portfolio_id: str,
    request: QueryRequest,
    session: AsyncSession = Depends(get_db),
    current_org: Organization = Depends(get_current_organization),
    current_user: User = Depends(get_current_user),
    _: str = Depends(require_role("member"))
):
    """
    Query portfolio content (across all projects in all programs in the portfolio) using unified RAG search.

    Args:
        portfolio_id: UUID of the portfolio
        request: Query request containing the question and optional conversation_id
        session: Database session

    Returns:
        QueryResponse with answer, sources, confidence, conversation_id, and is_followup
    """
    logger.info(f"Querying portfolio {portfolio_id}: {request.question}")

    try:
        # Verify portfolio exists and belongs to current organization
        result = await session.execute(
            select(Portfolio).where(
                and_(
                    Portfolio.id == portfolio_id,
                    Portfolio.organization_id == current_org.id
                )
            )
        )
        portfolio = result.scalar_one_or_none()

        if not portfolio:
            raise HTTPException(status_code=404, detail=f"Portfolio {portfolio_id} not found")

        # Get all programs in this portfolio
        programs_result = await session.execute(
            select(Program).where(
                and_(
                    Program.portfolio_id == portfolio_id,
                    Program.organization_id == current_org.id
                )
            )
        )
        programs = programs_result.scalars().all()

        # Get all projects in this portfolio (both direct and through programs)
        direct_projects_result = await session.execute(
            select(Project).where(
                and_(
                    Project.portfolio_id == portfolio_id,
                    Project.organization_id == current_org.id
                )
            )
        )
        direct_projects = direct_projects_result.scalars().all()

        # Get projects through programs
        program_ids = [str(p.id) for p in programs]
        program_projects = []
        if program_ids:
            program_projects_result = await session.execute(
                select(Project).where(
                    and_(
                        Project.program_id.in_(program_ids),
                        Project.organization_id == current_org.id
                    )
                )
            )
            program_projects = program_projects_result.scalars().all()

        all_projects = list(direct_projects) + list(program_projects)

        if not all_projects:
            raise HTTPException(
                status_code=404,
                detail=f"No projects found in portfolio {portfolio_id}"
            )

        # Deduplicate project IDs (a project can be in both direct and program lists)
        project_ids = list(set([str(p.id) for p in all_projects]))
        logger.info(f"Querying {len(project_ids)} projects in portfolio {portfolio.name}")

        # Handle conversation context
        conversation = None
        conversation_messages = []
        is_followup = False
        actual_question = request.question

        if request.conversation_id:
            conversation, conversation_messages = await conversation_context_service.get_conversation_context(
                conversation_id=request.conversation_id,
                session=session,
                organization_id=str(current_org.id)
            )

            if conversation:
                is_followup = await conversation_context_service.detect_followup_question(
                    question=request.question,
                    conversation_messages=conversation_messages
                )

                if is_followup:
                    actual_question = await conversation_context_service.enhance_query_with_context(
                        question=request.question,
                        conversation_messages=conversation_messages
                    )
                    logger.info(f"Enhanced follow-up question with context for conversation {request.conversation_id}")

        # Use unified multi-project RAG query
        rag_response = await enhanced_rag_service.query_multiple_projects(
            project_ids=project_ids,
            question=actual_question,
            user_id=current_user.email,
            organization_id=str(current_org.id)
        )

        # Create or update conversation
        conversation_id = request.conversation_id

        if not conversation:
            conversation_title = conversation_context_service.create_conversation_title(request.question)
            new_conversation = Conversation(
                project_id=uuid.UUID(portfolio_id),
                organization_id=current_org.id,
                title=f"[Portfolio: {portfolio.name}] {conversation_title}",
                messages=[],
                created_by=current_user.email or "unknown",
                created_at=datetime.utcnow(),
                last_accessed_at=datetime.utcnow()
            )
            session.add(new_conversation)
            await session.flush()
            conversation_id = str(new_conversation.id)
            conversation = new_conversation

        # Add current Q&A to conversation messages
        new_message = conversation_context_service.format_message_for_storage(
            question=request.question,
            answer=rag_response['answer'],
            sources=rag_response['sources'][:10],
            confidence=rag_response['confidence']
        )

        # Update conversation
        updated_messages = (conversation.messages or []) + [new_message]
        await session.execute(
            update(Conversation)
            .where(Conversation.id == conversation_id)
            .values(
                messages=updated_messages,
                last_accessed_at=datetime.utcnow()
            )
        )

        await session.commit()

        logger.info(
            f"Portfolio query completed - conversation_id: {conversation_id}, "
            f"is_followup: {is_followup}, projects_with_results: {rag_response.get('projects_with_results', 0)}"
        )

        return QueryResponse(
            answer=rag_response['answer'],
            sources=rag_response['sources'][:10],
            confidence=rag_response['confidence'],
            conversation_id=conversation_id,
            is_followup=is_followup
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Query failed for portfolio {portfolio_id}: {e}")
        raise HTTPException(status_code=500, detail=str(e))

