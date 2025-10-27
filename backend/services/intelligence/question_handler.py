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

    def __init__(self):
        """Initialize the question handler."""
        # Question lifecycle configuration
        self.monitoring_timeout_seconds = 15  # Tier 3: Live monitoring timeout
        self.rag_search_timeout = 2.0  # Tier 1: RAG search timeout
        self.meeting_context_timeout = 1.5  # Tier 2: Meeting context timeout
        self.gpt_generation_timeout = 3.0  # Tier 4: GPT answer generation timeout

        # Active questions being monitored (session_id -> {question_id -> task})
        self._active_monitoring: Dict[str, Dict[str, asyncio.Task]] = {}

        # Answer detection events for Tier 3 live monitoring (session_id -> {question_id -> Event})
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
        session: AsyncSession,
        project_id: str,
        organization_id: str,
        recording_id: str
    ) -> Optional[LiveMeetingInsight]:
        """Process question detection event and trigger parallel answer discovery.

        Args:
            session_id: The meeting session ID
            question_data: Question data from GPT stream {id, text, speaker, timestamp, ...}
            session: Database session
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
            await self._broadcast_event(session_id, {
                "type": "QUESTION_DETECTED",
                "question": question_insight.to_dict()
            })

            # Start parallel answer discovery (Tiers 1, 2, and 3)
            # Note: Tier 4 (GPT-generated) will be triggered only if other tiers fail
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

        Tiers execute in parallel:
        - Tier 1: RAG Search (2s timeout)
        - Tier 2: Meeting Context Search (1.5s timeout)
        - Tier 3: Live Conversation Monitoring (15s window)
        - Tier 4: GPT-Generated Answer (triggered only if all others fail, 3s timeout)

        Args:
            session_id: Meeting session ID
            question_id: Database question ID (UUID)
            question_text: The question text
            project_id: Project UUID string
            organization_id: Organization UUID string
            speaker: Speaker who asked the question (optional)
        """
        try:
            # Execute Tier 1 and Tier 2 in parallel
            tier1_task = asyncio.create_task(
                self._tier1_rag_search(session_id, question_id, question_text, project_id, organization_id)
            )
            tier2_task = asyncio.create_task(
                self._tier2_meeting_context_search(
                    session_id, question_id, question_text, speaker, organization_id
                )
            )

            # Start Tier 3: Live monitoring (15s window)
            tier3_task = asyncio.create_task(
                self._tier3_live_monitoring(session_id, question_id, question_text)
            )

            # Store monitoring task for potential cancellation
            if session_id not in self._active_monitoring:
                self._active_monitoring[session_id] = {}
            self._active_monitoring[session_id][question_id] = tier3_task

            # Wait for Tier 1 and Tier 2 to complete
            tier1_found, tier2_found = await asyncio.gather(tier1_task, tier2_task)

            # Wait for Tier 3 to complete (or timeout)
            tier3_found = await tier3_task

            # Clean up monitoring task
            if session_id in self._active_monitoring:
                self._active_monitoring[session_id].pop(question_id, None)

            # Check if any tier found an answer
            answer_found = tier1_found or tier2_found or tier3_found

            if not answer_found:
                # Tier 4: GPT-generated answer (fallback)
                logger.info(f"No answer found in Tiers 1-3 for question {question_id}, triggering Tier 4")
                await self._tier4_gpt_generated_answer(session_id, question_id, question_text, speaker)

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
                    await self._broadcast_event(session_id, {
                        "type": "RAG_RESULT_PROGRESSIVE",
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

            # Update database with all collected results
            from db.database import get_db_context
            async with get_db_context() as db_session:
                result = await db_session.execute(
                    select(LiveMeetingInsight).where(
                        LiveMeetingInsight.id == uuid.UUID(question_id)
                    )
                )
                question = result.scalar_one_or_none()

                if question:
                    # Calculate average confidence from relevance scores
                    avg_confidence = sum(s["relevance_score"] for s in collected_sources) / len(collected_sources)

                    # Add RAG tier result with all sources
                    question.add_tier_result("rag", {
                        "sources": collected_sources,
                        "num_sources": len(collected_sources),
                        "confidence": avg_confidence,
                        "timestamp": datetime.utcnow().isoformat()
                    })

                    # Update status
                    question.update_status(InsightStatus.FOUND.value)
                    question.set_answer_source(AnswerSource.RAG.value, avg_confidence)

                    await db_session.commit()

                    # Broadcast final RAG completion event
                    await self._broadcast_event(session_id, {
                        "type": "RAG_RESULT_COMPLETE",
                        "question_id": question_id,
                        "num_sources": len(collected_sources),
                        "confidence": avg_confidence,
                        "tier": "rag",
                        "label": "📚 From Documents"
                    })

                    logger.info(
                        f"Tier 1: Found {len(collected_sources)} RAG sources for question {question_id} "
                        f"(confidence: {avg_confidence:.3f})"
                    )
                    return True

            return False

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

            # Update database with meeting context result
            from db.database import get_db_context
            async with get_db_context() as db_session:
                db_result = await db_session.execute(
                    select(LiveMeetingInsight).where(
                        LiveMeetingInsight.id == uuid.UUID(question_id)
                    )
                )
                question = db_result.scalar_one_or_none()

                if question:
                    # Add meeting context tier result
                    question.add_tier_result("meeting_context", {
                        "answer_text": result.answer_text,
                        "quotes": result.quotes,
                        "confidence": result.confidence,
                        "search_duration_ms": result.search_duration_ms,
                        "timestamp": datetime.utcnow().isoformat()
                    })

                    # Update status and answer source
                    question.update_status(InsightStatus.FOUND.value)
                    question.set_answer_source(
                        AnswerSource.MEETING_CONTEXT.value,
                        result.confidence
                    )

                    await db_session.commit()

                    # Broadcast ANSWER_FROM_MEETING event
                    await self._broadcast_event(session_id, {
                        "type": "ANSWER_FROM_MEETING",
                        "question_id": question_id,
                        "answer_text": result.answer_text,
                        "quotes": result.quotes,
                        "confidence": result.confidence,
                        "tier": "meeting_context",
                        "label": "💬 Earlier in Meeting"
                    })

                    logger.info(
                        f"Tier 2: Found answer in meeting context for question {question_id} "
                        f"(confidence: {result.confidence:.3f}, quotes: {len(result.quotes)}, "
                        f"duration: {result.search_duration_ms}ms)"
                    )
                    return True

            return False

        except Exception as e:
            logger.error(
                f"Tier 2: Meeting context search failed for question {question_id}: {e}",
                exc_info=True
            )
            return False

    async def _tier3_live_monitoring(
        self,
        session_id: str,
        question_id: str,
        question_text: str
    ) -> bool:
        """Tier 3: Monitor live conversation for answers (15 second window).

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
                f"Tier 3: Starting live monitoring for question {question_id} "
                f"({self.monitoring_timeout_seconds}s window)"
            )

            # Create event for this question to signal answer detection
            if session_id not in self._answer_events:
                self._answer_events[session_id] = {}

            answer_event = asyncio.Event()
            self._answer_events[session_id][question_id] = answer_event

            # Update status to MONITORING
            from db.database import get_db_context
            async with get_db_context() as db_session:
                result = await db_session.execute(
                    select(LiveMeetingInsight).where(
                        LiveMeetingInsight.id == uuid.UUID(question_id)
                    )
                )
                question = result.scalar_one_or_none()

                if question:
                    # Only update to monitoring if not already answered by Tier 1 or 2
                    if question.status in [InsightStatus.SEARCHING.value, InsightStatus.FOUND.value]:
                        question.update_status(InsightStatus.MONITORING.value)
                        await db_session.commit()

                        # Broadcast MONITORING status to clients
                        await self._broadcast_event(session_id, {
                            "type": "QUESTION_MONITORING",
                            "question_id": question_id,
                            "tier": "live_conversation",
                            "label": "👂 Listening...",
                            "duration_seconds": self.monitoring_timeout_seconds
                        })

            # Wait for either answer detection or timeout
            try:
                await asyncio.wait_for(
                    answer_event.wait(),
                    timeout=self.monitoring_timeout_seconds
                )

                # Answer was detected!
                logger.info(
                    f"Tier 3: Answer detected in live conversation for question {question_id}"
                )

                # Clean up event
                if session_id in self._answer_events:
                    self._answer_events[session_id].pop(question_id, None)

                return True

            except asyncio.TimeoutError:
                # Timeout - no answer detected in 15 seconds
                logger.debug(
                    f"Tier 3: Live monitoring timeout for question {question_id} "
                    f"(no answer in {self.monitoring_timeout_seconds}s)"
                )

                # Clean up event
                if session_id in self._answer_events:
                    self._answer_events[session_id].pop(question_id, None)

                return False

        except asyncio.CancelledError:
            # Monitoring was cancelled (likely because answer found in Tier 1 or 2)
            logger.debug(
                f"Tier 3: Live monitoring cancelled for question {question_id} "
                "(answer found in earlier tier)"
            )

            # Clean up event
            if session_id in self._answer_events:
                self._answer_events[session_id].pop(question_id, None)

            return False

        except Exception as e:
            logger.error(
                f"Tier 3: Live monitoring failed for question {question_id}: {e}",
                exc_info=True
            )

            # Clean up event
            if session_id in self._answer_events:
                self._answer_events[session_id].pop(question_id, None)

            return False

    async def _tier4_gpt_generated_answer(
        self,
        session_id: str,
        question_id: str,
        question_text: str,
        speaker: Optional[str] = None
    ) -> bool:
        """Tier 4: Generate answer using GPT-5-mini (fallback when all tiers fail).

        Args:
            session_id: Meeting session ID
            question_id: Question database ID
            question_text: The question text
            speaker: Speaker who asked the question (optional)

        Returns:
            True if GPT generated a confident answer, False otherwise
        """
        try:
            logger.info(f"Tier 4: Requesting GPT-generated answer for question {question_id}")

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
                        f"Tier 4: Successfully generated GPT answer for question {question_id}"
                    )
                    return True

                # If GPT generation failed or confidence too low, mark as unanswered
                logger.info(
                    f"Tier 4: GPT could not confidently answer question {question_id}, "
                    "marking as unanswered"
                )

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

                    # Broadcast unanswered event
                    await self._broadcast_event(session_id, {
                        "type": "QUESTION_UNANSWERED",
                        "question_id": question_id,
                        "timestamp": datetime.utcnow().isoformat()
                    })

                return False

        except Exception as e:
            logger.error(
                f"Tier 4: GPT answer generation failed for question {question_id}: {e}",
                exc_info=True
            )
            return False

    def signal_answer_detected(self, session_id: str, question_id: str) -> None:
        """Signal that an answer was detected for a monitored question.

        This method is called by AnswerHandler when it detects an answer in the
        live conversation that matches a question being monitored by Tier 3.

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


# Global service instance
question_handler = QuestionHandler()
