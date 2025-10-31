"""Question Handler Service.

Processes question detection events from GPT stream, triggers parallel searches
across four tiers (RAG, Meeting Context, Live Monitoring, GPT-Generated), and manages
question lifecycle.
"""

import asyncio
import uuid
from datetime import datetime
from typing import Dict, Any, Optional, List, Callable
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_

from models.live_insight import (
    LiveMeetingInsight,
    InsightType,
    InsightStatus,
    AnswerSource
)
from services.intelligence.rag_search import rag_search_service
from services.intelligence.meeting_context_search import get_meeting_context_search
from utils.logger import get_logger, sanitize_for_log

logger = get_logger(__name__)


class QuestionHandler:
    """Handler for question detection and four-tier answer discovery."""

    def __init__(self, enabled_tiers: Optional[List[str]] = None):
        """Initialize the question handler.

        Args:
            enabled_tiers: List of enabled tier names. Defaults to all tiers enabled.
                         Valid values: 'rag', 'meeting_context', 'live_conversation', 'gpt_generated'
        """
        # Question lifecycle configuration
        self.monitoring_timeout_seconds = 60  # Tier 4: Live monitoring timeout
        self.rag_search_timeout = 2.0  # Tier 1: RAG search timeout
        self.meeting_context_timeout = 1.5  # Tier 2: Meeting context timeout
        self.gpt_generation_timeout = 3.0  # Tier 3: GPT answer generation timeout

        # Tier configuration (which tiers are enabled)
        if enabled_tiers is None:
            # Default: all tiers enabled
            enabled_tiers = ['rag', 'meeting_context', 'live_conversation', 'gpt_generated']

        self.tier_config = {
            'rag': 'rag' in enabled_tiers,
            'meeting_context': 'meeting_context' in enabled_tiers,
            'live_conversation': 'live_conversation' in enabled_tiers,
            'gpt_generated': 'gpt_generated' in enabled_tiers,
        }

        logger.info(f"QuestionHandler initialized with tier config: {self.tier_config}")

        # Active questions being monitored (session_id -> {question_id -> task})
        self._active_monitoring: Dict[str, Dict[str, asyncio.Task]] = {}

        # Answer detection events for Tier 4 live monitoring (session_id -> {question_id -> Event})
        self._answer_events: Dict[str, Dict[str, asyncio.Event]] = {}

        # WebSocket broadcast callback (set by orchestrator)
        self._ws_broadcast_callback: Optional[Callable] = None

    def set_websocket_callback(self, callback: Callable) -> None:
        """Set the WebSocket broadcast callback.

        Args:
            callback: Async function to broadcast updates to clients
        """
        self._ws_broadcast_callback = callback

    async def handle_question(
        self,
        session_id: str,
        question_data: dict,
        project_id: str,
        organization_id: str,
        recording_id: str,
        session: Optional[AsyncSession] = None
    ) -> Optional[LiveMeetingInsight]:
        """Process question detection event and trigger parallel answer discovery.

        This method manages its own database session by default for clean transaction
        boundaries. An optional session parameter is provided for legacy compatibility.

        Args:
            session_id: The meeting session ID
            question_data: Question data from GPT stream {id, text, speaker, timestamp, ...}
            project_id: Project UUID
            organization_id: Organization UUID
            recording_id: Recording UUID
            session: Optional database session (will create own if not provided)

        Returns:
            Created LiveMeetingInsight instance or None if failed
        """
        # ========================================================================
        # Database Session Management
        # ========================================================================
        # Create own session for clean transaction boundaries
        # This ensures committed data is visible to background tasks
        if session is None:
            from db.database import get_db_context
            async with get_db_context() as db_session:
                return await self._handle_question_impl(
                    session_id=session_id,
                    question_data=question_data,
                    session=db_session,
                    project_id=project_id,
                    organization_id=organization_id,
                    recording_id=recording_id
                )
        else:
            # Use provided session (legacy compatibility)
            return await self._handle_question_impl(
                session_id=session_id,
                question_data=question_data,
                session=session,
                project_id=project_id,
                organization_id=organization_id,
                recording_id=recording_id
            )

    async def _handle_question_impl(
        self,
        session_id: str,
        question_data: dict,
        session: AsyncSession,
        project_id: str,
        organization_id: str,
        recording_id: str
    ) -> Optional[LiveMeetingInsight]:
        """Internal implementation of question handling.

        Args:
            session_id: The meeting session ID
            question_data: Question data from GPT stream
            session: Database session (always provided)
            project_id: Project UUID
            organization_id: Organization UUID
            recording_id: Recording UUID

        Returns:
            Created LiveMeetingInsight instance or None if failed
        """
        try:
            question_id = question_data.get("id", f"q_{uuid.uuid4()}")
            question_text = question_data.get("text", "")
            speaker = question_data.get("speaker")
            timestamp_str = question_data.get("timestamp")
            confidence = question_data.get("confidence", 0.0)
            category = question_data.get("category", "factual")

            # Parse timestamp
            detected_at = datetime.utcnow()
            if timestamp_str:
                try:
                    detected_at = datetime.fromisoformat(timestamp_str.replace('Z', '+00:00'))
                except Exception as e:
                    logger.warning(f"Failed to parse timestamp {timestamp_str}: {e}")

            logger.info(
                f"Processing question for session {sanitize_for_log(session_id)}: "
                f"{sanitize_for_log(question_text[:100])}"
            )

            # Check for duplicate question (deduplication by text similarity)
            existing_question = await session.execute(
                select(LiveMeetingInsight).where(
                    and_(
                        LiveMeetingInsight.session_id == session_id,
                        LiveMeetingInsight.insight_type == InsightType.QUESTION,
                        LiveMeetingInsight.content == question_text  # Exact match for now
                    )
                )
            )
            existing = existing_question.scalars().first()

            if existing:
                logger.info(
                    f"Duplicate question detected for session {session_id}, skipping: "
                    f"'{question_text[:50]}...' (existing ID: {existing.id})"
                )
                return existing

            # Create LiveMeetingInsight record
            question_insight = LiveMeetingInsight(
                session_id=session_id,
                recording_id=uuid.UUID(recording_id) if recording_id else None,
                project_id=uuid.UUID(project_id) if project_id else None,
                organization_id=uuid.UUID(organization_id) if organization_id else None,
                insight_type=InsightType.QUESTION,
                detected_at=detected_at,
                speaker=speaker,
                content=question_text,
                status=InsightStatus.SEARCHING.value,
                insight_metadata={
                    "gpt_id": question_id,
                    "category": category,
                    "confidence": confidence,
                    "tier_results": {}
                }
            )

            session.add(question_insight)
            await session.flush()  # Get the database ID

            db_question_id = str(question_insight.id)

            # Broadcast QUESTION_DETECTED event
            question_dict = question_insight.to_dict()
            logger.info(f"🔊 Broadcasting QUESTION_DETECTED for session {session_id}: question_id={db_question_id}, text='{question_text[:50]}'")
            await self._broadcast_event(session_id, {
                "type": "QUESTION_DETECTED",
                "data": question_dict,  # Use 'data' key for consistency with frontend
                "timestamp": datetime.utcnow().isoformat()
            })
            logger.info(f"✅ Broadcast completed for question {db_question_id}")

            # Start parallel answer discovery (Tiers 1, 2, and 4)
            # Note: Tier 3 (GPT-generated) will be triggered only if other tiers fail
            asyncio.create_task(
                self._parallel_answer_discovery(
                    session_id=session_id,
                    question_id=db_question_id,
                    question_text=question_text,
                    project_id=project_id,
                    organization_id=organization_id,
                    speaker=speaker
                )
            )

            await session.commit()

            logger.info(
                f"Question {db_question_id} created and answer discovery started for session {session_id}"
            )

            return question_insight

        except Exception as e:
            logger.error(f"Failed to handle question for session {session_id}: {e}", exc_info=True)
            await session.rollback()
            return None

    async def _parallel_answer_discovery(
        self,
        session_id: str,
        question_id: str,
        question_text: str,
        project_id: str,
        organization_id: str,
        speaker: Optional[str] = None
    ) -> None:
        """Execute parallel answer discovery across four tiers.

        Execution strategy:
        - Tier 1 (RAG) and Tier 2 (Meeting Context) run in parallel (fast tiers)
        - Tier 4 (Live Monitoring) runs in parallel from start (background, 15s window)
        - Tier 3 (GPT) triggers if Tiers 1-2 fail, WITHOUT waiting for Tier 4
        - Tier 4 continues monitoring and can provide answer even after Tier 3

        Tiers:
        - Tier 1: RAG Search (2s timeout)
        - Tier 2: Meeting Context Search (1.5s timeout)
        - Tier 3: GPT-Generated Answer (triggered if T1-2 fail, 3s timeout)
        - Tier 4: Live Conversation Monitoring (15s window, runs in background)

        Args:
            session_id: Meeting session ID
            question_id: Database question ID (UUID)
            question_text: The question text
            project_id: Project UUID string
            organization_id: Organization UUID string
            speaker: Speaker who asked the question (optional)
        """
        try:
            # Start fast tiers (Tier 1 and Tier 2) in parallel
            fast_tasks = []
            tier1_task = None
            tier2_task = None

            # Tier 1: RAG Search
            if self.tier_config['rag']:
                tier1_task = asyncio.create_task(
                    self._tier1_rag_search(session_id, question_id, question_text, project_id, organization_id)
                )
                fast_tasks.append(('tier1', tier1_task))
            else:
                logger.info(f"Tier 1 (RAG) disabled for question {question_id}")

            # Tier 2: Meeting Context
            if self.tier_config['meeting_context']:
                tier2_task = asyncio.create_task(
                    self._tier2_meeting_context_search(
                        session_id, question_id, question_text, speaker, organization_id
                    )
                )
                fast_tasks.append(('tier2', tier2_task))
            else:
                logger.info(f"Tier 2 (Meeting Context) disabled for question {question_id}")

            # Tier 4: Live Monitoring (runs in background, does NOT block Tier 3)
            tier4_task = None
            if self.tier_config['live_conversation']:
                tier4_task = asyncio.create_task(
                    self._tier4_live_monitoring(session_id, question_id, question_text)
                )

                # Store monitoring task for potential cancellation
                if session_id not in self._active_monitoring:
                    self._active_monitoring[session_id] = {}
                self._active_monitoring[session_id][question_id] = tier4_task
            else:
                logger.info(f"Tier 4 (Live Conversation) disabled for question {question_id}")

            # Wait ONLY for fast tiers (Tier 1 and 2), NOT Tier 4
            tier1_found = tier2_found = False
            if fast_tasks:
                results = await asyncio.gather(*[task for _, task in fast_tasks])
                # Map results back to tier names
                for (tier_name, _), result in zip(fast_tasks, results):
                    if tier_name == 'tier1':
                        tier1_found = result
                    elif tier_name == 'tier2':
                        tier2_found = result

            # Check if fast tiers found an answer
            fast_tiers_found = tier1_found or tier2_found

            # Tier 3: Trigger GPT if fast tiers failed (don't wait for Tier 4)
            tier3_found = False
            if not fast_tiers_found and self.tier_config['gpt_generated']:
                logger.info(
                    f"No answer found in Tiers 1-2 for question {question_id}, "
                    f"triggering Tier 3 (GPT). Tier 4 continues monitoring in background."
                )
                tier3_found = await self._tier3_gpt_generated_answer(session_id, question_id, question_text, speaker)

            # Wait for Tier 4 to complete (if it's running) before marking as unanswered
            tier4_found = False
            if tier4_task:
                try:
                    tier4_found = await tier4_task
                    logger.debug(
                        f"Tier 4 completed for question {question_id}: "
                        f"answer_found={tier4_found}"
                    )
                except Exception as e:
                    logger.error(
                        f"Tier 4 monitoring failed for question {question_id}: {e}",
                        exc_info=True
                    )

            # Check if ANY tier found an answer
            any_tier_found = tier1_found or tier2_found or tier3_found or tier4_found

            # If NO tier found an answer, verify question is still unanswered before broadcasting
            if not any_tier_found:
                # ========================================================================
                # IMPORTANT: Check database status before broadcasting UNANSWERED
                # ========================================================================
                # This prevents race condition where AnswerHandler detects an answer
                # AFTER Tier 4 timeout but BEFORE we broadcast UNANSWERED
                try:
                    from db.database import get_db_context

                    async with get_db_context() as db_session:
                        result = await db_session.execute(
                            select(LiveMeetingInsight).where(
                                LiveMeetingInsight.id == uuid.UUID(question_id)
                            )
                        )
                        question = result.scalar_one_or_none()

                        if not question:
                            logger.warning(
                                f"Question {question_id} not found in database - "
                                f"cannot verify status before marking unanswered"
                            )
                            return

                        # Check if question was answered by AnswerHandler during monitoring
                        if question.status == InsightStatus.ANSWERED.value:
                            logger.info(
                                f"Question {question_id} was answered by live conversation "
                                f"after Tier 4 timeout - skipping UNANSWERED broadcast"
                            )
                            return

                        # Question is still not answered - proceed with UNANSWERED broadcast
                        logger.info(
                            f"All 4 tiers exhausted for question {question_id} without finding answer. "
                            f"Marking as UNANSWERED."
                        )

                        # Update status to UNANSWERED
                        question.update_status(InsightStatus.UNANSWERED.value)
                        question.set_answer_source(AnswerSource.UNANSWERED.value)

                        logger.debug(
                            f"Persisted UNANSWERED status to database "
                            f"for question {question_id}"
                        )

                        # Broadcast UNANSWERED event
                        await self._broadcast_event(session_id, {
                            "type": "QUESTION_UNANSWERED",
                            "data": {
                                "question_id": question_id,
                                "status": "unanswered",
                                "answer_source": "none",
                                "timestamp": datetime.utcnow().isoformat()
                            },
                            "timestamp": datetime.utcnow().isoformat()
                        })

                        logger.info(
                            f"Broadcast UNANSWERED status for question {question_id} "
                            f"after all tiers completed"
                        )

                except Exception as e:
                    logger.error(
                        f"Failed to handle UNANSWERED status for question {question_id}: {e}",
                        exc_info=True
                    )

        except Exception as e:
            logger.error(
                f"Error in parallel answer discovery for question {question_id}: {e}",
                exc_info=True
            )

    async def _tier1_rag_search(
        self,
        session_id: str,
        question_id: str,
        question_text: str,
        project_id: str,
        organization_id: str
    ) -> bool:
        """Tier 1: Search organization's document repository (RAG).

        Uses streaming RAG search service to progressively return top 5 relevant documents.

        Args:
            session_id: Meeting session ID
            question_id: Question database ID
            question_text: The question text
            project_id: Project UUID string
            organization_id: Organization UUID string

        Returns:
            True if relevant documents found, False otherwise
        """
        try:
            logger.debug(f"Tier 1: Starting RAG search for question {question_id}")

            # Check if RAG service is available
            if not rag_search_service.is_available():
                logger.warning("Tier 1: RAG service unavailable, skipping search")
                return False

            # Track if any results were found
            found_results = False
            collected_sources = []

            # Execute streaming RAG search with progressive updates
            try:
                async for result in rag_search_service.search(
                    question=question_text,
                    project_id=project_id,
                    organization_id=organization_id,
                    streaming=True
                ):
                    found_results = True
                    collected_sources.append(result.to_dict())

                    # Broadcast progressive RAG result to clients (streaming UI update)
                    # Use 'data' wrapper for consistency with other events
                    await self._broadcast_event(session_id, {
                        "type": "RAG_RESULT_PROGRESSIVE",
                        "data": {
                            "question_id": question_id,
                            "document": {
                                "title": result.title,
                                "content": result.content[:500],  # First 500 chars
                                "relevance_score": result.relevance_score,
                                "url": result.url
                            },
                            "source": "rag",
                            "tier": "rag",
                            "label": "📚 From Documents"
                        }
                    })

                    logger.debug(
                        f"Tier 1: Streamed RAG result for question {question_id}: "
                        f"{result.title} (score: {result.relevance_score:.3f})"
                    )

            except asyncio.TimeoutError:
                logger.warning(f"Tier 1: RAG search timeout for question {question_id}")
                # Continue with results found so far
            except Exception as search_error:
                logger.error(f"Tier 1: RAG search error for question {question_id}: {search_error}")
                return False

            # If no results found, return False
            if not found_results:
                logger.debug(f"Tier 1: No RAG results for question {question_id}")
                return False

            # ========================================================================
            # PHASE 1: Notify user that search is complete (immediate feedback)
            # ========================================================================
            # Calculate average confidence from relevance scores
            avg_confidence = sum(s["relevance_score"] for s in collected_sources) / len(collected_sources)
            num_sources = len(collected_sources)

            # Broadcast final RAG completion event immediately after search completes
            # This provides instant feedback to the user without waiting for DB persistence
            await self._broadcast_event(session_id, {
                "type": "RAG_RESULT_COMPLETE",
                "data": {
                    "question_id": question_id,
                    "num_sources": num_sources,
                    "confidence": avg_confidence,
                    "tier": "rag",
                    "label": "📚 From Documents"
                }
            })

            logger.info(
                f"Tier 1: RAG search complete for question {question_id} - "
                f"found {num_sources} sources (confidence: {avg_confidence:.3f})"
            )

            # ========================================================================
            # PHASE 2: Persist results to database (background data operation)
            # ========================================================================
            # This happens after user notification for better UX responsiveness
            try:
                from db.database import get_db_context
                async with get_db_context() as db_session:
                    result = await db_session.execute(
                        select(LiveMeetingInsight).where(
                            LiveMeetingInsight.id == uuid.UUID(question_id)
                        )
                    )
                    question = result.scalar_one_or_none()

                    if question:
                        # Store RAG tier result with all sources
                        question.add_tier_result("rag", {
                            "sources": collected_sources,
                            "num_sources": num_sources,
                            "confidence": avg_confidence,
                            "timestamp": datetime.utcnow().isoformat()
                        })

                        # Update question status
                        question.update_status(InsightStatus.FOUND.value)
                        question.set_answer_source(AnswerSource.RAG.value, avg_confidence)

                        await db_session.commit()

                        logger.debug(
                            f"Tier 1: Persisted {num_sources} RAG results to database "
                            f"for question {question_id}"
                        )

                        # ====================================================================
                        # PHASE 3: Broadcast enriched event with full question object
                        # ====================================================================
                        # After DB persistence, send the complete question data to frontend
                        # This includes tier results, status, answer_source, etc.
                        await db_session.refresh(question)
                        question_dict = question.to_dict()

                        enriched_event = {
                            "type": "RAG_RESULT_ENRICHED",
                            "data": question_dict,
                            "timestamp": datetime.utcnow().isoformat() + "Z"
                        }

                        await self._broadcast_event(session_id, enriched_event)
                        logger.debug(
                            f"Tier 1: Broadcasted enriched event with full question data "
                            f"for question {question_id}"
                        )
                    else:
                        logger.error(
                            f"Tier 1: Question {question_id} not found in database - "
                            f"cannot persist RAG results"
                        )

            except Exception as persistence_error:
                # Log persistence errors but don't fail the tier
                # User already got their results via the completion broadcast
                logger.error(
                    f"Tier 1: Failed to persist RAG results for question {question_id}: "
                    f"{persistence_error}",
                    exc_info=True
                )
                # Still return True because search succeeded and user was notified

            return True

        except Exception as e:
            logger.error(f"Tier 1: RAG search failed for question {question_id}: {e}", exc_info=True)
            return False

    async def _tier2_meeting_context_search(
        self,
        session_id: str,
        question_id: str,
        question_text: str,
        speaker: Optional[str] = None,
        organization_id: Optional[str] = None
    ) -> bool:
        """Tier 2: Search current meeting transcript for answers.

        Uses GPT-5-mini to semantically search the current meeting transcript
        for answers to the detected question. Returns exact quotes with
        speaker attribution and clickable timestamps.

        Args:
            session_id: Meeting session ID
            question_id: Question database ID
            question_text: The question text
            speaker: Who asked the question (optional)
            organization_id: Organization ID for tracking (optional)

        Returns:
            True if answer found in meeting context, False otherwise
        """
        try:
            logger.debug(f"Tier 2: Starting meeting context search for question {question_id}")

            # Get meeting context search service
            meeting_context_search = get_meeting_context_search()

            # Search meeting transcript for answer
            result = await meeting_context_search.search(
                question=question_text,
                session_id=session_id,
                speaker=speaker,
                organization_id=organization_id
            )

            # If no answer found, return False
            if not result.found_answer:
                logger.debug(
                    f"Tier 2: No answer found in meeting context for question {question_id}"
                )
                return False

            # ========================================================================
            # PHASE 1: Notify user that answer was found (immediate feedback)
            # ========================================================================
            # Broadcast ANSWER_FROM_MEETING event immediately after search completes
            # This provides instant feedback to the user without waiting for DB persistence
            await self._broadcast_event(session_id, {
                "type": "ANSWER_FROM_MEETING",
                "data": {
                    "question_id": question_id,
                    "answer_text": result.answer_text,
                    "quotes": result.quotes,
                    "confidence": result.confidence,
                    "tier": "meeting_context",
                    "label": "💬 Earlier in Meeting"
                }
            })

            logger.info(
                f"Tier 2: Meeting context search complete for question {question_id} - "
                f"found answer (confidence: {result.confidence:.3f}, quotes: {len(result.quotes)}, "
                f"duration: {result.search_duration_ms}ms)"
            )

            # ========================================================================
            # PHASE 2: Persist results to database (background data operation)
            # ========================================================================
            # This happens after user notification for better UX responsiveness
            try:
                from db.database import get_db_context
                async with get_db_context() as db_session:
                    db_result = await db_session.execute(
                        select(LiveMeetingInsight).where(
                            LiveMeetingInsight.id == uuid.UUID(question_id)
                        )
                    )
                    question = db_result.scalar_one_or_none()

                    if question:
                        # Store meeting context tier result
                        question.add_tier_result("meeting_context", {
                            "answer_text": result.answer_text,
                            "quotes": result.quotes,
                            "confidence": result.confidence,
                            "search_duration_ms": result.search_duration_ms,
                            "timestamp": datetime.utcnow().isoformat()
                        })

                        # Update question status
                        question.update_status(InsightStatus.FOUND.value)
                        question.set_answer_source(
                            AnswerSource.MEETING_CONTEXT.value,
                            result.confidence
                        )

                        await db_session.commit()

                        logger.debug(
                            f"Tier 2: Persisted meeting context result to database "
                            f"for question {question_id}"
                        )

                        # ====================================================================
                        # PHASE 3: Broadcast enriched event with full question object
                        # ====================================================================
                        # After DB persistence, send the complete question data to frontend
                        # This includes tier results, status, answer_source, etc.
                        await db_session.refresh(question)
                        question_dict = question.to_dict()

                        enriched_event = {
                            "type": "ANSWER_DETECTED_ENRICHED",
                            "data": question_dict,
                            "timestamp": datetime.utcnow().isoformat() + "Z"
                        }

                        await self._broadcast_event(session_id, enriched_event)
                        logger.debug(
                            f"Tier 2: Broadcasted enriched event with full question data "
                            f"for question {question_id}"
                        )
                    else:
                        logger.error(
                            f"Tier 2: Question {question_id} not found in database - "
                            f"cannot persist meeting context result"
                        )

            except Exception as persistence_error:
                # Log persistence errors but don't fail the tier
                # User already got their answer via the completion broadcast
                logger.error(
                    f"Tier 2: Failed to persist meeting context result for question {question_id}: "
                    f"{persistence_error}",
                    exc_info=True
                )
                # Still return True because search succeeded and user was notified

            return True

        except Exception as e:
            logger.error(
                f"Tier 2: Meeting context search failed for question {question_id}: {e}",
                exc_info=True
            )
            return False

    async def _tier4_live_monitoring(
        self,
        session_id: str,
        question_id: str,
        question_text: str
    ) -> bool:
        """Tier 4: Monitor live conversation for answers (15 second window).

        This method waits for up to 15 seconds for AnswerHandler to detect and signal
        an answer in the live conversation. The AnswerHandler processes answer events
        from GPT stream and signals this monitoring task via asyncio.Event when a
        match is found.

        Args:
            session_id: Meeting session ID
            question_id: Question database ID
            question_text: The question text

        Returns:
            True if answer detected in live conversation, False if timeout
        """
        try:
            logger.debug(
                f"Tier 4: Starting live monitoring for question {question_id} "
                f"({self.monitoring_timeout_seconds}s window)"
            )

            # Create event for this question to signal answer detection
            if session_id not in self._answer_events:
                self._answer_events[session_id] = {}

            answer_event = asyncio.Event()
            self._answer_events[session_id][question_id] = answer_event

            # ========================================================================
            # Check current status and broadcast MONITORING if appropriate
            # ========================================================================
            from db.database import get_db_context

            # First, check if we should enter monitoring (query only, no updates yet)
            should_monitor = False
            async with get_db_context() as db_session:
                result = await db_session.execute(
                    select(LiveMeetingInsight).where(
                        LiveMeetingInsight.id == uuid.UUID(question_id)
                    )
                )
                question = result.scalar_one_or_none()

                if question:
                    # Only monitor if not already answered by Tier 1 or 2
                    if question.status in [InsightStatus.SEARCHING.value, InsightStatus.FOUND.value]:
                        should_monitor = True

            if should_monitor:
                # ====================================================================
                # PHASE 1: Notify user immediately (fast UX feedback)
                # ====================================================================
                await self._broadcast_event(session_id, {
                    "type": "QUESTION_MONITORING",
                    "data": {
                        "question_id": question_id,
                        "status": "monitoring",
                        "monitoring_timeout": self.monitoring_timeout_seconds,
                        "timestamp": datetime.utcnow().isoformat()
                    },
                    "timestamp": datetime.utcnow().isoformat()
                })

                logger.debug(
                    f"Tier 4: Broadcast MONITORING status for question {question_id}"
                )

                # ====================================================================
                # PHASE 2: Persist status to database (background operation)
                # ====================================================================
                try:
                    async with get_db_context() as db_session:
                        result = await db_session.execute(
                            select(LiveMeetingInsight).where(
                                LiveMeetingInsight.id == uuid.UUID(question_id)
                            )
                        )
                        question = result.scalar_one_or_none()

                        if question and question.status in [InsightStatus.SEARCHING.value, InsightStatus.FOUND.value]:
                            question.update_status(InsightStatus.MONITORING.value)
                            await db_session.commit()

                            logger.debug(
                                f"Tier 4: Persisted MONITORING status to database "
                                f"for question {question_id}"
                            )

                except Exception as persistence_error:
                    # Log persistence errors but don't fail the monitoring
                    # User already got notification via broadcast
                    logger.error(
                        f"Tier 4: Failed to persist MONITORING status for question {question_id}: "
                        f"{persistence_error}",
                        exc_info=True
                    )

            # Wait for either answer detection or timeout
            try:
                await asyncio.wait_for(
                    answer_event.wait(),
                    timeout=self.monitoring_timeout_seconds
                )

                # Answer was detected!
                logger.info(
                    f"Tier 4: Answer detected in live conversation for question {question_id}"
                )

                # Clean up event
                if session_id in self._answer_events:
                    self._answer_events[session_id].pop(question_id, None)

                return True

            except asyncio.TimeoutError:
                # Timeout - no answer detected in 15 seconds
                logger.debug(
                    f"Tier 4: Live monitoring timeout for question {question_id} "
                    f"(no answer in {self.monitoring_timeout_seconds}s)"
                )

                # Clean up event
                if session_id in self._answer_events:
                    self._answer_events[session_id].pop(question_id, None)

                return False

        except asyncio.CancelledError:
            # Monitoring was cancelled (likely because answer found in Tier 1 or 2)
            logger.debug(
                f"Tier 4: Live monitoring cancelled for question {question_id} "
                "(answer found in earlier tier)"
            )

            # Clean up event
            if session_id in self._answer_events:
                self._answer_events[session_id].pop(question_id, None)

            return False

        except Exception as e:
            logger.error(
                f"Tier 4: Live monitoring failed for question {question_id}: {e}",
                exc_info=True
            )

            # Clean up event
            if session_id in self._answer_events:
                self._answer_events[session_id].pop(question_id, None)

            return False

    async def _tier3_gpt_generated_answer(
        self,
        session_id: str,
        question_id: str,
        question_text: str,
        speaker: Optional[str] = None
    ) -> bool:
        """Tier 3: Generate answer using GPT-5-mini (fallback when all tiers fail).

        Args:
            session_id: Meeting session ID
            question_id: Question database ID
            question_text: The question text
            speaker: Speaker who asked the question (optional)

        Returns:
            True if GPT generated a confident answer, False otherwise
        """
        try:
            logger.info(f"Tier 3: Requesting GPT-generated answer for question {question_id}")

            # Import GPT Answer Generator
            from services.intelligence.gpt_answer_generator import GPTAnswerGenerator

            # Create generator with broadcast callback and configured timeout
            generator = GPTAnswerGenerator(
                broadcast_callback=self._ws_broadcast_callback,
                timeout=self.gpt_generation_timeout,
                confidence_threshold=0.70
            )

            # Get database session for updates
            from db.database import get_db_context
            async with get_db_context() as db_session:
                # Generate answer
                success = await generator.generate_answer(
                    session_id=session_id,
                    question_id=question_id,
                    question_text=question_text,
                    speaker=speaker,
                    meeting_context=None,  # TODO: Add meeting context if available
                    db_session=db_session
                )

                if success:
                    logger.info(
                        f"Tier 3: Successfully generated GPT answer for question {question_id}"
                    )
                    return True

                # If GPT generation failed or confidence too low
                logger.info(
                    f"Tier 3: GPT could not confidently answer question {question_id}. "
                    f"Tier 4 (live monitoring) will continue in background."
                )

                # DO NOT mark as unanswered yet - Tier 4 is still running!
                # The _parallel_answer_discovery method will handle broadcasting
                # QUESTION_UNANSWERED after Tier 4 completes without finding answer.

                return False

        except Exception as e:
            logger.error(
                f"Tier 3: GPT answer generation failed for question {question_id}: {e}",
                exc_info=True
            )
            return False

    def signal_answer_detected(self, session_id: str, question_id: str) -> None:
        """Signal that an answer was detected for a monitored question.

        This method is called by AnswerHandler when it detects an answer in the
        live conversation that matches a question being monitored by Tier 4.

        Args:
            session_id: Meeting session ID
            question_id: Question database ID
        """
        if session_id in self._answer_events:
            if question_id in self._answer_events[session_id]:
                event = self._answer_events[session_id][question_id]
                event.set()  # Signal the monitoring task
                logger.debug(
                    f"Signaled answer detection for question {question_id} "
                    f"in session {session_id}"
                )
            else:
                logger.debug(
                    f"Question {question_id} not in active monitoring events "
                    f"for session {session_id}"
                )
        else:
            logger.debug(
                f"Session {session_id} has no active monitoring events"
            )

    async def cancel_monitoring(self, session_id: str, question_id: str) -> None:
        """Cancel live monitoring for a question (called when answer found early).

        This method cancels the Tier 3 monitoring task and signals any waiting
        answer detection event.

        Args:
            session_id: Meeting session ID
            question_id: Question database ID
        """
        # Signal answer event (in case monitoring is waiting)
        self.signal_answer_detected(session_id, question_id)

        # Cancel monitoring task
        if session_id in self._active_monitoring:
            if question_id in self._active_monitoring[session_id]:
                task = self._active_monitoring[session_id][question_id]
                if not task.done():
                    task.cancel()
                    logger.debug(f"Cancelled monitoring task for question {question_id}")

    async def cleanup_session(self, session_id: str) -> None:
        """Cleanup resources for a meeting session.

        Cancels all active monitoring tasks and clears answer detection events.

        Args:
            session_id: Meeting session ID
        """
        # Cancel all active monitoring tasks
        if session_id in self._active_monitoring:
            for question_id, task in self._active_monitoring[session_id].items():
                if not task.done():
                    task.cancel()
            del self._active_monitoring[session_id]

        # Clean up answer detection events
        if session_id in self._answer_events:
            del self._answer_events[session_id]

        logger.info(f"Cleaned up question handler resources for session {session_id}")

    async def _broadcast_event(self, session_id: str, event_data: dict) -> None:
        """Broadcast event to WebSocket clients.

        Args:
            session_id: Meeting session ID
            event_data: Event data to broadcast
        """
        if self._ws_broadcast_callback:
            try:
                await self._ws_broadcast_callback(session_id, event_data)
            except Exception as e:
                logger.error(f"Failed to broadcast event to clients: {e}")
        else:
            logger.debug("No WebSocket callback configured, skipping broadcast")

    async def _mark_question_unanswered(self, question_id: str) -> None:
        """Mark a question as unanswered when all tiers fail.

        Args:
            question_id: Question database ID
        """
        try:
            from db.database import get_db_context
            async with get_db_context() as db_session:
                result = await db_session.execute(
                    select(LiveMeetingInsight).where(
                        LiveMeetingInsight.id == uuid.UUID(question_id)
                    )
                )
                question = result.scalar_one_or_none()

                if question:
                    question.update_status(InsightStatus.UNANSWERED.value)
                    question.set_answer_source(AnswerSource.UNANSWERED.value)
                    await db_session.commit()
                    logger.info(f"Marked question {question_id} as unanswered")
                else:
                    logger.warning(f"Question {question_id} not found when marking as unanswered")
        except Exception as e:
            logger.error(f"Failed to mark question {question_id} as unanswered: {e}", exc_info=True)


# Global service instance
question_handler = QuestionHandler()
