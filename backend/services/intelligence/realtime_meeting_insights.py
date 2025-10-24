"""
Real-time Meeting Insights Service.

This service processes live meeting transcript chunks and extracts actionable insights
in real-time, including action items, decisions, questions, risks, and contextual
information from past meetings.

Architecture:
- Sliding window context management for conversation continuity
- Incremental insight extraction with deduplication
- Semantic search for related past discussions
- Structured insight categorization and prioritization
"""

import asyncio
import time
import uuid
from typing import List, Dict, Any, Optional, Set, Tuple
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
from collections import deque
import json

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from models.project import Project
from models.live_meeting_insight import LiveMeetingInsight
from services.llm.multi_llm_client import get_multi_llm_client
from services.rag.embedding_service import embedding_service
from services.prompts.realtime_insights_prompts import (
    get_realtime_insight_extraction_prompt,
    get_contradiction_detection_prompt,
    get_meeting_summary_prompt_realtime
)
from db.multi_tenant_vector_store import multi_tenant_vector_store
from config import get_settings
from utils.logger import get_logger, sanitize_for_log
from services.intelligence.question_detector import QuestionDetector
from services.intelligence.question_answering_service import QuestionAnsweringService
from services.intelligence.clarification_service import ClarificationService
from services.intelligence.conflict_detection_service import ConflictDetectionService
from services.intelligence.action_item_quality_service import ActionItemQualityService
from services.intelligence.follow_up_suggestions_service import FollowUpSuggestionsService
from services.intelligence.shared_search_cache import shared_search_cache
from services.intelligence.insight_evolution_tracker import get_evolution_tracker, EvolutionType

logger = get_logger(__name__)


class InsightType(Enum):
    """Types of insights that can be extracted from meetings."""
    ACTION_ITEM = "action_item"
    DECISION = "decision"
    QUESTION = "question"
    RISK = "risk"
    KEY_POINT = "key_point"
    RELATED_DISCUSSION = "related_discussion"
    CONTRADICTION = "contradiction"
    MISSING_INFO = "missing_info"


class InsightPriority(Enum):
    """Priority levels for insights."""
    CRITICAL = "critical"
    HIGH = "high"
    MEDIUM = "medium"
    LOW = "low"


class ProcessingStatus(Enum):
    """Overall processing status for insight extraction."""
    OK = "ok"  # All phases succeeded
    DEGRADED = "degraded"  # Some phases failed but core extraction succeeded
    FAILED = "failed"  # Core extraction failed


class PhaseStatus(Enum):
    """Status of individual processing phases."""
    SUCCESS = "success"
    FAILED = "failed"
    SKIPPED = "skipped"  # Phase not relevant for this chunk


@dataclass
class MeetingInsight:
    """Structured representation of a meeting insight."""
    insight_id: str
    type: InsightType
    priority: InsightPriority
    content: str
    context: str
    timestamp: datetime

    # Additional metadata
    assigned_to: Optional[str] = None
    due_date: Optional[str] = None
    source_chunk_index: int = 0
    confidence_score: float = 0.0

    # For related discussions
    related_content_ids: List[str] = field(default_factory=list)
    similarity_scores: List[float] = field(default_factory=list)

    # For contradictions
    contradicts_content_id: Optional[str] = None
    contradiction_explanation: Optional[str] = None

    def to_dict(self) -> Dict[str, Any]:
        """Convert insight to dictionary for serialization."""
        return {
            'insight_id': self.insight_id,
            'type': self.type.value,
            'priority': self.priority.value,
            'content': self.content,
            'context': self.context,
            'timestamp': self.timestamp.isoformat(),
            'assigned_to': self.assigned_to,
            'due_date': self.due_date,
            'source_chunk_index': self.source_chunk_index,
            'confidence_score': self.confidence_score,
            'related_content_ids': self.related_content_ids,
            'similarity_scores': self.similarity_scores,
            'contradicts_content_id': self.contradicts_content_id,
            'contradiction_explanation': self.contradiction_explanation
        }


@dataclass
class TranscriptChunk:
    """Represents a chunk of meeting transcript."""
    chunk_id: str
    text: str
    timestamp: datetime
    index: int
    speaker: Optional[str] = None
    duration_seconds: float = 0.0


@dataclass
class ProcessingMetadata:
    """
    Metadata about why and how processing occurred.

    Provides visibility into the adaptive processing decision logic
    for debugging and user transparency.
    """
    # Insight Processing Decision
    trigger: Optional[str] = None  # e.g., "semantic_score_threshold", "max_batch_reached"
    priority: Optional[str] = None  # e.g., "IMMEDIATE", "HIGH", "MEDIUM", "LOW"
    semantic_score: Optional[float] = None
    signals_detected: List[str] = field(default_factory=list)  # e.g., ["action_verbs", "time_references"]
    chunks_accumulated: int = 0
    decision_reason: Optional[str] = None  # Human-readable explanation

    # Proactive Assistance Processing
    active_phases: List[str] = field(default_factory=list)  # Which phases ran
    skipped_phases: List[str] = field(default_factory=list)  # Which phases were skipped
    phase_execution_times_ms: Dict[str, float] = field(default_factory=dict)  # Timing per phase

    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary for WebSocket serialization."""
        return {
            'trigger': self.trigger,
            'priority': self.priority,
            'semantic_score': self.semantic_score,
            'signals_detected': self.signals_detected,
            'chunks_accumulated': self.chunks_accumulated,
            'decision_reason': self.decision_reason,
            'active_phases': self.active_phases,
            'skipped_phases': self.skipped_phases,
            'phase_execution_times_ms': self.phase_execution_times_ms,
        }


@dataclass
class ProcessingResult:
    """
    Result of insight extraction with phase-level status tracking.

    This enables graceful degradation when some Active Intelligence phases fail
    while still delivering core insights to the user.
    """
    # Core data
    session_id: str
    chunk_index: int
    insights: List[MeetingInsight] = field(default_factory=list)
    proactive_assistance: List[Dict[str, Any]] = field(default_factory=list)
    evolved_insights: List[Dict[str, Any]] = field(default_factory=list)  # Insights that updated existing ones

    # Status tracking
    overall_status: ProcessingStatus = ProcessingStatus.OK
    phase_status: Dict[str, PhaseStatus] = field(default_factory=dict)

    # Metadata
    total_insights_count: int = 0
    processing_time_ms: int = 0
    context_window_size: int = 0

    # Error details (if any)
    failed_phases: List[str] = field(default_factory=list)
    error_messages: Dict[str, str] = field(default_factory=dict)

    # Skip tracking (duplicate/validation)
    skipped_reason: Optional[str] = None
    similarity_score: Optional[float] = None

    # Processing decision visibility (NEW)
    processing_metadata: Optional[ProcessingMetadata] = None

    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary for WebSocket serialization."""
        result = {
            'session_id': self.session_id,
            'chunk_index': self.chunk_index,
            'insights': [insight.to_dict() for insight in self.insights],
            'proactive_assistance': self.proactive_assistance,
            'evolved_insights': self.evolved_insights,
            'status': self.overall_status.value,
            'phase_status': {k: v.value for k, v in self.phase_status.items()},
            'total_insights': self.total_insights_count,
            'processing_time_ms': self.processing_time_ms,
            'context_window_size': self.context_window_size,
            'failed_phases': self.failed_phases,
            'error_messages': self.error_messages,
            'skipped_reason': self.skipped_reason,
            'similarity_score': self.similarity_score,
        }

        # Include processing metadata if available
        if self.processing_metadata:
            result['processing_metadata'] = self.processing_metadata.to_dict()

        return result

    def get_warning_message(self) -> Optional[str]:
        """Generate user-friendly warning message for degraded status."""
        if self.overall_status == ProcessingStatus.DEGRADED:
            failed_count = len(self.failed_phases)
            if failed_count == 1:
                return f"Some AI features temporarily unavailable ({self.failed_phases[0]})"
            else:
                return f"Some AI features temporarily unavailable ({failed_count} features affected)"
        return None


@dataclass
class SlidingWindowContext:
    """
    Manages sliding window context for conversation continuity with semantic duplicate detection.

    Features:
    - Maintains recent conversation chunks for context
    - Tracks embeddings for semantic similarity comparison
    - Early duplicate detection to avoid redundant LLM calls
    """
    max_chunks: int = 10  # Keep last 10 chunks (~100 seconds of conversation)
    duplicate_window_size: int = 5  # Check last N chunks for duplicates
    duplicate_threshold: float = 0.90  # Semantic similarity threshold (higher than insight dedup)

    chunks: deque = field(default_factory=deque)
    chunk_embeddings: deque = field(default_factory=deque)  # Corresponding embeddings

    def add_chunk(self, chunk: TranscriptChunk) -> None:
        """Add a new chunk to the sliding window."""
        self.chunks.append(chunk)
        if len(self.chunks) > self.max_chunks:
            self.chunks.popleft()

    def add_chunk_embedding(self, embedding: List[float]) -> None:
        """Add embedding for the most recent chunk."""
        self.chunk_embeddings.append(embedding)
        if len(self.chunk_embeddings) > self.max_chunks:
            self.chunk_embeddings.popleft()

    def get_context_text(self, include_speakers: bool = True) -> str:
        """Get the full context text from all chunks in the window."""
        if include_speakers:
            return "\n".join([
                f"[{chunk.speaker or 'Unknown'}]: {chunk.text}"
                for chunk in self.chunks
            ])
        return "\n".join([chunk.text for chunk in self.chunks])

    def get_recent_context(self, num_chunks: int = 3) -> str:
        """Get the most recent N chunks as context."""
        recent_chunks = list(self.chunks)[-num_chunks:] if len(self.chunks) >= num_chunks else list(self.chunks)
        return "\n".join([chunk.text for chunk in recent_chunks])

    def get_recent_embeddings(self, num_chunks: int = None) -> List[List[float]]:
        """
        Get embeddings for recent chunks for duplicate detection.

        Args:
            num_chunks: Number of recent embeddings to return (default: duplicate_window_size)

        Returns:
            List of embeddings for recent chunks
        """
        if num_chunks is None:
            num_chunks = self.duplicate_window_size

        recent = list(self.chunk_embeddings)[-num_chunks:]
        return recent if recent else []


class RealtimeMeetingInsightsService:
    """
    Service for extracting insights from live meeting transcripts in real-time.

    Features:
    - Sliding window context management
    - Incremental insight extraction
    - Semantic deduplication
    - Past meeting correlation
    - Structured insight categorization
    """

    def __init__(self):
        self.settings = get_settings()
        self.llm_client = get_multi_llm_client(self.settings)

        # Insight extraction configuration
        self.min_confidence_threshold = 0.6
        self.semantic_similarity_threshold = 0.85  # For insight-level deduplication
        self.past_meeting_search_limit = 5

        # Early duplicate detection (chunk-level)
        self.chunk_duplicate_threshold = 0.90  # Higher threshold for chunk duplicates
        self.enable_early_duplicate_detection = True  # Feature flag

        # Context management
        self.active_contexts: Dict[str, SlidingWindowContext] = {}

        # Insight cache for deduplication (session_id -> set of insight embeddings)
        self.extracted_insights: Dict[str, List[MeetingInsight]] = {}
        self.insight_embeddings: Dict[str, List[List[float]]] = {}

        # Rate limiting for semantic search (avoid overwhelming Qdrant)
        self.last_semantic_search: Dict[str, float] = {}
        self.semantic_search_interval = 30.0  # seconds

        # Shared Search Cache for Active Intelligence (reduces redundant vector searches)
        self.search_cache = shared_search_cache

        # Active Intelligence services
        # Phase 1: Question Auto-Answering
        self.question_detector = QuestionDetector(llm_client=self.llm_client)
        self.qa_service = QuestionAnsweringService(
            vector_store=multi_tenant_vector_store,
            llm_client=self.llm_client,
            embedding_service=embedding_service,
            search_cache=self.search_cache,
            min_confidence_threshold=0.7
        )
        # Phase 2: Proactive Clarification
        self.clarification_service = ClarificationService(llm_client=self.llm_client)
        # Phase 3: Real-Time Conflict Detection
        self.conflict_detection_service = ConflictDetectionService(
            vector_store=multi_tenant_vector_store,
            llm_client=self.llm_client,
            embedding_service=embedding_service,
            search_cache=self.search_cache
        )
        # Phase 4: Action Item Quality Enhancement
        self.quality_service = ActionItemQualityService(llm_client=self.llm_client)
        # Phase 5: Follow-up Suggestions
        self.follow_up_service = FollowUpSuggestionsService(
            vector_store=multi_tenant_vector_store,
            llm_client=self.llm_client,
            embedding_service=embedding_service,
            search_cache=self.search_cache
        )

        # Insight Evolution Tracker - tracks how insights change over time
        self.evolution_tracker = get_evolution_tracker()

    async def process_transcript_chunk(
        self,
        session_id: str,
        project_id: str,
        organization_id: str,
        chunk: TranscriptChunk,
        db: AsyncSession,
        enabled_insight_types: Optional[List[str]] = None,
        adaptive_stats: Optional[Dict[str, Any]] = None,
        adaptive_reason: Optional[str] = None
    ) -> ProcessingResult:
        """
        Process a single transcript chunk and extract insights.

        Flow:
        1. Early duplicate detection (chunk-level) - Avoids redundant LLM calls
        2. Extract insights from LLM (only if not duplicate)
        3. Deduplicate insights (insight-level)
        4. Run Active Intelligence phases (only on unique insights)

        RESILIENCE: Each Active Intelligence phase is wrapped in error handling
        to ensure partial failures don't block the entire pipeline. Returns
        ProcessingResult with status tracking for graceful degradation.

        Args:
            session_id: Unique identifier for the meeting session
            project_id: Project UUID
            organization_id: Organization UUID
            chunk: Transcript chunk to process
            db: Database session
            adaptive_stats: Optional stats from AdaptiveInsightProcessor for metadata
            adaptive_reason: Optional reason for processing decision

        Returns:
            ProcessingResult with insights, status, and phase-level error tracking
        """
        start_time = time.time()

        # Initialize processing metadata
        metadata = ProcessingMetadata()

        # Populate metadata from adaptive processor if available
        if adaptive_stats:
            metadata.priority = adaptive_stats.get('priority')
            metadata.semantic_score = adaptive_stats.get('semantic_score')
            metadata.decision_reason = adaptive_reason

            # Extract signals detected from stats
            signals = adaptive_stats.get('signals', {})
            metadata.signals_detected = [
                signal for signal, detected in signals.items() if detected
            ]

        if adaptive_reason:
            # Parse trigger from reason string
            if 'threshold' in adaptive_reason:
                metadata.trigger = 'semantic_score_threshold'
            elif 'max_batch' in adaptive_reason:
                metadata.trigger = 'max_batch_reached'
            elif 'word_threshold' in adaptive_reason:
                metadata.trigger = 'word_threshold_reached'
            else:
                metadata.trigger = adaptive_reason

        try:
            # Initialize context if first chunk
            if session_id not in self.active_contexts:
                self.active_contexts[session_id] = SlidingWindowContext(
                    duplicate_threshold=self.chunk_duplicate_threshold
                )
                self.extracted_insights[session_id] = []
                self.insight_embeddings[session_id] = []
                logger.info(f"Initialized context for session {sanitize_for_log(session_id)}")

            # Add chunk to sliding window (before duplicate check)
            context = self.active_contexts[session_id]
            context.add_chunk(chunk)

            # PHASE 0: Early Duplicate Detection (BEFORE expensive LLM calls)
            is_duplicate, similarity_score = await self._is_duplicate_chunk(
                session_id=session_id,
                chunk_text=chunk.text
            )

            # If duplicate detected, skip expensive processing
            if is_duplicate:
                processing_time = time.time() - start_time

                logger.info(
                    f"Skipping chunk {chunk.index} (duplicate, similarity: {similarity_score:.3f}): "
                    f"Saved ~$0.002 in LLM costs"
                )

                # Populate metadata for skipped (duplicate) processing
                metadata.decision_reason = "Chunk is semantically duplicate of recent chunk"
                metadata.trigger = "duplicate_detection"

                return ProcessingResult(
                    session_id=session_id,
                    chunk_index=chunk.index,
                    insights=[],
                    proactive_assistance=[],
                    overall_status=ProcessingStatus.OK,
                    phase_status={},
                    total_insights_count=len(self.extracted_insights[session_id]),
                    processing_time_ms=int(processing_time * 1000),
                    context_window_size=len(context.chunks),
                    skipped_reason='duplicate_chunk',
                    similarity_score=similarity_score,
                    processing_metadata=metadata
                )

            # Get conversation context
            full_context = context.get_context_text(include_speakers=True)
            recent_context = context.get_recent_context(num_chunks=3)

            # PHASE 1: Extract insights from current chunk (LLM call with user preferences)
            insights = await self._extract_insights(
                session_id=session_id,
                project_id=project_id,
                organization_id=organization_id,
                current_chunk=chunk,
                recent_context=recent_context,
                full_context=full_context,
                db=db,
                enabled_insight_types=enabled_insight_types
            )

            # PHASE 2: Deduplicate insights (insight-level semantic similarity)
            new_insights = await self._deduplicate_insights(session_id, insights)

            # PHASE 2.5: Check for insight evolution (priority escalation, content expansion)
            # This happens AFTER deduplication but BEFORE storing
            truly_new_insights, evolved_insights = await self._check_insight_evolution(
                session_id=session_id,
                insights=new_insights,
                chunk_index=chunk.index
            )

            # Store truly new insights (not evolutions)
            self.extracted_insights[session_id].extend(truly_new_insights)

            # PHASE 1-6: Active Intelligence - Process all proactive assistance
            # Note: Process proactive assistance on truly_new_insights (not evolved ones)
            # Returns: (proactive_responses, phase_status, error_messages, phase_timings)
            proactive_assistance, phase_status, error_messages, phase_timings = await self._process_proactive_assistance(
                session_id=session_id,
                project_id=project_id,
                organization_id=organization_id,
                insights=truly_new_insights,
                context=full_context,
                current_chunk=chunk
            )

            processing_time = time.time() - start_time

            # Determine overall processing status
            failed_phases = [phase for phase, status in phase_status.items() if status == PhaseStatus.FAILED]
            if failed_phases:
                overall_status = ProcessingStatus.DEGRADED
                logger.warning(
                    f"Degraded mode for chunk {chunk.index}: {len(failed_phases)} phases failed: {', '.join(failed_phases)}"
                )
            else:
                overall_status = ProcessingStatus.OK

            # Populate processing metadata for active phases
            metadata.active_phases = [phase for phase, status in phase_status.items() if status == PhaseStatus.SUCCESS]
            metadata.skipped_phases = [phase for phase, status in phase_status.items() if status == PhaseStatus.SKIPPED]
            metadata.phase_execution_times_ms = phase_timings
            metadata.chunks_accumulated = len(context.chunks)

            # Build processing result
            result = ProcessingResult(
                session_id=session_id,
                chunk_index=chunk.index,
                insights=truly_new_insights,
                proactive_assistance=proactive_assistance,
                evolved_insights=evolved_insights,
                overall_status=overall_status,
                phase_status=phase_status,
                total_insights_count=len(self.extracted_insights[session_id]),
                processing_time_ms=int(processing_time * 1000),
                context_window_size=len(context.chunks),
                failed_phases=failed_phases,
                error_messages=error_messages,
                processing_metadata=metadata
            )

            logger.info(
                f"Processed chunk {chunk.index} for session {sanitize_for_log(session_id)}: "
                f"{len(truly_new_insights)} new insights, {len(evolved_insights)} evolved in {processing_time:.2f}s "
                f"(status: {overall_status.value})"
            )

            return result

        except Exception as e:
            # Core extraction failed - return FAILED status
            logger.error(f"Error processing transcript chunk: {e}", exc_info=True)

            # Populate metadata for failed processing
            metadata.decision_reason = f"Core extraction failed: {str(e)}"
            metadata.trigger = "error"

            return ProcessingResult(
                session_id=session_id,
                chunk_index=chunk.index,
                insights=[],
                proactive_assistance=[],
                overall_status=ProcessingStatus.FAILED,
                phase_status={},
                total_insights_count=0,
                processing_time_ms=0,
                context_window_size=0,
                failed_phases=['core_extraction'],
                error_messages={'core_extraction': str(e)},
                processing_metadata=metadata
            )

    async def _extract_insights(
        self,
        session_id: str,
        project_id: str,
        organization_id: str,
        current_chunk: TranscriptChunk,
        recent_context: str,
        full_context: str,
        db: AsyncSession,
        enabled_insight_types: Optional[List[str]] = None
    ) -> List[MeetingInsight]:
        """
        Extract insights from the current chunk with context.

        Uses LLM to analyze the conversation and extract structured insights.
        Only extracts insight types specified by the user for cost optimization.
        """
        insights = []

        try:
            # Query for related past discussions (rate-limited)
            related_discussions = await self._get_related_discussions(
                session_id=session_id,
                project_id=project_id,
                organization_id=organization_id,
                current_text=current_chunk.text
            )

            # Build prompt for insight extraction with user preferences
            prompt = get_realtime_insight_extraction_prompt(
                current_chunk=current_chunk.text,
                recent_context=recent_context,
                related_discussions=related_discussions,
                speaker_info=f"Speaker: {current_chunk.speaker}" if current_chunk.speaker else None,
                enabled_insight_types=enabled_insight_types  # COST OPTIMIZATION
            )

            # Call LLM for insight extraction
            response = await self.llm_client.create_message(
                prompt=prompt,
                model="claude-3-5-haiku-20241022",  # Fast model for real-time processing
                max_tokens=2000,
                temperature=0.1,  # Low temperature for consistent extraction
                system="You are an expert meeting analyst extracting actionable insights in real-time."
            )

            if not response:
                logger.warning("LLM returned empty response for insight extraction")
                return insights

            # Parse LLM response
            extracted_data = self._parse_llm_response(response)

            # Convert to MeetingInsight objects
            for idx, item in enumerate(extracted_data.get('insights', [])):
                insight = MeetingInsight(
                    insight_id=f"{session_id}_{current_chunk.index}_{idx}",
                    type=InsightType(item.get('type', 'key_point').lower()),
                    priority=InsightPriority(item.get('priority', 'medium').lower()),
                    content=item.get('content', ''),
                    context=recent_context,
                    timestamp=current_chunk.timestamp,
                    assigned_to=item.get('assigned_to'),
                    due_date=item.get('due_date'),
                    source_chunk_index=current_chunk.index,
                    confidence_score=item.get('confidence', 0.7)
                )

                # Filter by confidence threshold
                if insight.confidence_score >= self.min_confidence_threshold:
                    insights.append(insight)

            # Add related discussion insights
            if related_discussions:
                for discussion in related_discussions[:3]:  # Top 3 most relevant
                    insight = MeetingInsight(
                        insight_id=f"{session_id}_{current_chunk.index}_related_{discussion['content_id']}",
                        type=InsightType.RELATED_DISCUSSION,
                        priority=InsightPriority.LOW,
                        content=f"Related to past discussion: {discussion.get('title', 'Untitled')}",
                        context=discussion.get('snippet', ''),
                        timestamp=current_chunk.timestamp,
                        source_chunk_index=current_chunk.index,
                        confidence_score=discussion.get('similarity_score', 0.0),
                        related_content_ids=[discussion['content_id']],
                        similarity_scores=[discussion.get('similarity_score', 0.0)]
                    )
                    insights.append(insight)

            logger.debug(f"Extracted {len(insights)} insights from chunk {current_chunk.index}")

        except Exception as e:
            logger.error(f"Error extracting insights: {e}", exc_info=True)

        return insights

    async def _get_related_discussions(
        self,
        session_id: str,
        project_id: str,
        organization_id: str,
        current_text: str
    ) -> List[Dict[str, Any]]:
        """
        Query Qdrant for related past discussions (rate-limited).

        Only performs search if enough time has passed since last search.
        """
        current_time = time.time()
        last_search_time = self.last_semantic_search.get(session_id, 0)

        # Rate limit: only search every N seconds
        if current_time - last_search_time < self.semantic_search_interval:
            return []

        try:
            # Generate embedding for current text
            embedding = await embedding_service.generate_embedding(current_text)

            # Search in Qdrant
            results = await multi_tenant_vector_store.search_vectors(
                organization_id=organization_id,
                query_vector=embedding,
                limit=self.past_meeting_search_limit,
                filter_dict={
                    'project_id': project_id
                }
            )

            # Update last search time
            self.last_semantic_search[session_id] = current_time

            # Format results
            related = []
            for result in results:
                payload = result.get('payload', {})
                related.append({
                    'content_id': payload.get('content_id', result.get('id')),
                    'title': payload.get('title', 'Untitled'),
                    'snippet': payload.get('content', payload.get('text', ''))[:200],
                    'similarity_score': result.get('score', 0.0)
                })

            logger.debug(f"Found {len(related)} related discussions for session {sanitize_for_log(session_id)}")
            return related

        except Exception as e:
            logger.error(f"Error searching for related discussions: {e}", exc_info=True)
            return []


    def _parse_llm_response(self, response: Any) -> Dict[str, Any]:
        """
        Parse LLM response and extract structured data.

        Handles both text and API response objects.
        """
        try:
            # Extract text from response
            if hasattr(response, 'content') and isinstance(response.content, list):
                # Anthropic API format
                text = response.content[0].text
            elif hasattr(response, 'choices'):
                # OpenAI API format
                text = response.choices[0].message.content
            else:
                text = str(response)

            # Find JSON in response
            start = text.find('{')
            end = text.rfind('}') + 1

            if start >= 0 and end > start:
                json_text = text[start:end]
                return json.loads(json_text)

            logger.warning("No valid JSON found in LLM response")
            return {'insights': []}

        except json.JSONDecodeError as e:
            logger.error(f"Failed to parse JSON from LLM response: {e}")
            return {'insights': []}
        except Exception as e:
            logger.error(f"Error parsing LLM response: {e}", exc_info=True)
            return {'insights': []}

    async def _deduplicate_insights(
        self,
        session_id: str,
        new_insights: List[MeetingInsight]
    ) -> List[MeetingInsight]:
        """
        Deduplicate insights using semantic similarity.

        Compares new insights against previously extracted insights
        to avoid showing duplicates.
        """
        if session_id not in self.insight_embeddings:
            self.insight_embeddings[session_id] = []

        unique_insights = []
        existing_embeddings = self.insight_embeddings[session_id]

        for insight in new_insights:
            # Generate embedding for insight content
            try:
                insight_embedding = await embedding_service.generate_embedding(insight.content)

                # Check similarity with existing insights
                is_duplicate = False
                for existing_emb in existing_embeddings:
                    similarity = self._cosine_similarity(insight_embedding, existing_emb)
                    if similarity >= self.semantic_similarity_threshold:
                        is_duplicate = True
                        logger.debug(
                            f"Duplicate insight detected (similarity: {similarity:.2f}): {insight.content[:50]}"
                        )
                        break

                if not is_duplicate:
                    unique_insights.append(insight)
                    self.insight_embeddings[session_id].append(insight_embedding)

            except Exception as e:
                logger.error(f"Error during deduplication: {e}")
                # If embedding fails, include the insight anyway
                unique_insights.append(insight)

        logger.debug(f"Deduplication: {len(new_insights)} -> {len(unique_insights)} unique insights")
        return unique_insights

    async def _check_insight_evolution(
        self,
        session_id: str,
        insights: List[MeetingInsight],
        chunk_index: int
    ) -> Tuple[List[MeetingInsight], List[Dict[str, Any]]]:
        """
        Check if insights are evolutions of previous insights.

        This detects:
        - Priority escalation (e.g., LOW → CRITICAL)
        - Content expansion (e.g., vague → detailed)
        - Refinement (e.g., added owner/deadline)

        Args:
            session_id: Meeting session ID
            insights: List of deduplicated insights
            chunk_index: Current chunk index

        Returns:
            Tuple of (truly_new_insights, evolved_insights)
            - truly_new_insights: Brand new insights to add
            - evolved_insights: Insights that updated existing ones (for WebSocket)
        """
        truly_new = []
        evolved = []

        for insight in insights:
            # Convert MeetingInsight to dict for evolution tracker
            insight_dict = insight.to_dict()

            # Check if this is an evolution
            evolution_result = await self.evolution_tracker.check_evolution(
                session_id=session_id,
                new_insight=insight_dict,
                chunk_index=chunk_index
            )

            if evolution_result.is_evolution:
                # This insight evolved from a previous one
                if evolution_result.evolution_type in (EvolutionType.ESCALATED, EvolutionType.EXPANDED, EvolutionType.REFINED):
                    # Use the merged insight from evolution tracker
                    evolved.append(evolution_result.merged_insight)

                    logger.info(
                        f"Insight evolution detected: {evolution_result.evolution_type.value} "
                        f"(similarity: {evolution_result.similarity_score:.2f})"
                    )
                # If DUPLICATE, skip it entirely (already logged in evolution tracker)

            else:
                # Brand new insight - add to truly new list
                truly_new.append(insight)

        return truly_new, evolved

    async def _is_duplicate_chunk(
        self,
        session_id: str,
        chunk_text: str
    ) -> Tuple[bool, Optional[float]]:
        """
        Early duplicate detection: Check if chunk is semantically similar to recent chunks.

        This prevents redundant LLM calls when participants repeat themselves
        (e.g., "Let's use GraphQL" said multiple times).

        Args:
            session_id: Meeting session identifier
            chunk_text: Current transcript chunk text

        Returns:
            Tuple of (is_duplicate, max_similarity_score)
        """
        if not self.enable_early_duplicate_detection:
            return False, None

        if session_id not in self.active_contexts:
            return False, None

        context = self.active_contexts[session_id]

        # Need at least one previous chunk to compare
        if len(context.chunks) == 0:
            return False, None

        try:
            # Generate embedding for current chunk
            current_embedding = await embedding_service.generate_embedding(chunk_text)

            # Get recent embeddings for comparison
            recent_embeddings = context.get_recent_embeddings()

            if not recent_embeddings:
                return False, None

            # Check semantic similarity with recent chunks
            max_similarity = 0.0
            for past_embedding in recent_embeddings:
                similarity = self._cosine_similarity(current_embedding, past_embedding)
                max_similarity = max(max_similarity, similarity)

                if similarity >= self.chunk_duplicate_threshold:
                    logger.info(
                        f"Chunk duplicate detected (similarity: {similarity:.3f}, threshold: {self.chunk_duplicate_threshold}): "
                        f"'{chunk_text[:60]}...'"
                    )
                    return True, similarity

            logger.debug(
                f"Chunk is unique (max_similarity: {max_similarity:.3f}, threshold: {self.chunk_duplicate_threshold})"
            )

            # Store embedding for future comparisons
            context.add_chunk_embedding(current_embedding)

            return False, max_similarity

        except Exception as e:
            logger.error(f"Error during chunk duplicate detection: {e}", exc_info=True)
            # On error, assume not duplicate and continue processing
            return False, None

    @staticmethod
    def _cosine_similarity(vec1: List[float], vec2: List[float]) -> float:
        """Calculate cosine similarity between two vectors."""
        import numpy as np

        vec1_np = np.array(vec1)
        vec2_np = np.array(vec2)

        dot_product = np.dot(vec1_np, vec2_np)
        norm1 = np.linalg.norm(vec1_np)
        norm2 = np.linalg.norm(vec2_np)

        if norm1 == 0 or norm2 == 0:
            return 0.0

        return float(dot_product / (norm1 * norm2))

    async def finalize_session(
        self,
        session_id: str,
        project_id: str,
        organization_id: str,
        db: AsyncSession
    ) -> Dict[str, Any]:
        """
        Finalize a meeting session, persist insights to database, and return all extracted insights.

        Args:
            session_id: Meeting session identifier
            project_id: Project UUID
            organization_id: Organization UUID
            db: Database session

        Returns:
            Summary of all insights extracted during the session
        """
        if session_id not in self.extracted_insights:
            return {
                'session_id': session_id,
                'insights': [],
                'summary': 'No insights found for this session'
            }

        insights = self.extracted_insights[session_id]

        # Persist insights to database
        try:
            persisted_count = 0
            for insight in insights:
                # Prepare metadata
                metadata = {}
                if insight.related_content_ids:
                    metadata['related_content_ids'] = insight.related_content_ids
                if insight.contradicts_content_id:
                    metadata['contradicts_content_id'] = insight.contradicts_content_id
                if insight.contradiction_explanation:
                    metadata['contradiction_explanation'] = insight.contradiction_explanation

                # Create database model
                db_insight = LiveMeetingInsight(
                    id=uuid.uuid4(),
                    session_id=session_id,
                    project_id=uuid.UUID(project_id),
                    organization_id=uuid.UUID(organization_id),
                    insight_type=insight.type.value,
                    priority=insight.priority.value,
                    content=insight.content,
                    context=insight.context,
                    assigned_to=insight.assigned_to,
                    due_date=insight.due_date,
                    confidence_score=insight.confidence_score,
                    chunk_index=insight.source_chunk_index,
                    insight_metadata=metadata if metadata else None
                )
                db.add(db_insight)
                persisted_count += 1

            await db.commit()
            logger.info(f"Persisted {persisted_count} insights to database for session {sanitize_for_log(session_id)}")

        except Exception as e:
            logger.error(f"Failed to persist insights for session {sanitize_for_log(session_id)}: {e}", exc_info=True)
            await db.rollback()
            # Continue even if persistence fails - return insights to client

        # Group insights by type
        insights_by_type = {}
        for insight in insights:
            insight_type = insight.type.value
            if insight_type not in insights_by_type:
                insights_by_type[insight_type] = []
            insights_by_type[insight_type].append(insight.to_dict())

        # Clean up session data from memory
        del self.extracted_insights[session_id]
        del self.insight_embeddings[session_id]
        del self.active_contexts[session_id]
        if session_id in self.last_semantic_search:
            del self.last_semantic_search[session_id]

        # Clean up shared search cache for this session
        self.search_cache.clear_session(session_id)

        # Clean up insight evolution tracker for this session
        self.evolution_tracker.cleanup_session(session_id)

        # Log evolution summary before cleanup
        evolution_summary = self.evolution_tracker.get_evolution_summary(session_id)
        logger.info(
            f"Session evolution summary: {evolution_summary['evolved_insights']}/{evolution_summary['total_insights']} "
            f"insights evolved ({evolution_summary.get('evolution_rate', 0.0):.1%} evolution rate)"
        )

        logger.info(f"Finalized session {sanitize_for_log(session_id)}: {len(insights)} total insights")

        return {
            'session_id': session_id,
            'total_insights': len(insights),
            'insights_by_type': insights_by_type,
            'insights': [insight.to_dict() for insight in insights]
        }

    def _determine_active_phases(
        self,
        chunk_text: str,
        insights: List[MeetingInsight]
    ) -> Set[str]:
        """
        Determine which Active Intelligence phases are relevant for the current chunk.

        This optimization avoids running unnecessary phases, reducing LLM calls by 40-60%.

        Phase activation logic:
        - Phase 1 (question_answering): Only if question detected OR question insight extracted
        - Phase 2 (clarification): Only if action item or decision insight extracted
        - Phase 3 (conflict_detection): Only if decision keywords detected OR decision insight extracted
        - Phase 4 (action_item_quality): Only if action item insight extracted
        - Phase 5 (follow_up_suggestions): Only if decision or key_point insight extracted
        - Phase 6 (meeting_efficiency): Always active (lightweight time tracking)

        Args:
            chunk_text: Current transcript chunk text
            insights: List of insights extracted from chunk

        Returns:
            Set of active phase names
        """
        active_phases = set()
        chunk_lower = chunk_text.lower()

        # Question markers for Phase 1
        question_markers = ["what", "when", "where", "who", "why", "how"]
        has_question_mark = "?" in chunk_text
        has_question_word = any(word in chunk_lower for word in question_markers)

        # Decision keywords for Phase 3
        decision_keywords = [
            "decided", "agreed", "approved", "let's", "we'll", "going to",
            "will do", "plan to", "commit to", "choose", "selected"
        ]
        has_decision_keyword = any(keyword in chunk_lower for keyword in decision_keywords)

        # Check insights to determine which phases are needed
        has_question_insight = False
        has_action_item_insight = False
        has_decision_insight = False
        has_key_point_insight = False

        for insight in insights:
            if insight.type == InsightType.QUESTION:
                has_question_insight = True
            elif insight.type == InsightType.ACTION_ITEM:
                has_action_item_insight = True
            elif insight.type == InsightType.DECISION:
                has_decision_insight = True
            elif insight.type == InsightType.KEY_POINT:
                has_key_point_insight = True

        # Phase 1: Question Auto-Answering
        # Activate if: question mark OR question words OR question insight extracted
        if has_question_mark or has_question_word or has_question_insight:
            active_phases.add('question_answering')
            logger.debug(
                f"Phase 1 (question_answering) activated: "
                f"question_mark={has_question_mark}, question_word={has_question_word}, "
                f"question_insight={has_question_insight}"
            )

        # Phase 2: Proactive Clarification
        # Activate if: action item or decision insight extracted
        if has_action_item_insight or has_decision_insight:
            active_phases.add('clarification')
            logger.debug(
                f"Phase 2 (clarification) activated: "
                f"action_item={has_action_item_insight}, decision={has_decision_insight}"
            )

        # Phase 3: Conflict Detection
        # Activate if: decision keywords OR decision insight extracted
        if has_decision_keyword or has_decision_insight:
            active_phases.add('conflict_detection')
            logger.debug(
                f"Phase 3 (conflict_detection) activated: "
                f"decision_keyword={has_decision_keyword}, decision_insight={has_decision_insight}"
            )

        # Phase 4: Action Item Quality
        # Activate if: action item insight extracted
        if has_action_item_insight:
            active_phases.add('action_item_quality')
            logger.debug(f"Phase 4 (action_item_quality) activated: action_item={has_action_item_insight}")

        # Phase 5: Follow-up Suggestions
        # Activate if: decision or key point insight extracted
        if has_decision_insight or has_key_point_insight:
            active_phases.add('follow_up_suggestions')
            logger.debug(
                f"Phase 5 (follow_up_suggestions) activated: "
                f"decision={has_decision_insight}, key_point={has_key_point_insight}"
            )

        return active_phases

    async def _process_proactive_assistance(
        self,
        session_id: str,
        project_id: str,
        organization_id: str,
        insights: List[MeetingInsight],
        context: str,
        current_chunk: TranscriptChunk
    ) -> Tuple[List[Dict[str, Any]], Dict[str, PhaseStatus], Dict[str, str], Dict[str, float]]:
        """
        Process insights to provide proactive assistance with selective phase execution.

        OPTIMIZATION: Only runs phases that are relevant to the current chunk content
        to reduce unnecessary LLM calls by 40-60%.

        RESILIENCE: Each phase is wrapped in try-except to ensure that failures in
        individual phases don't block the entire pipeline. Phase status is tracked
        and reported to enable graceful degradation.

        Phase 1: Question Auto-Answering - Checks if any insights are questions and
                 attempts to answer them automatically using RAG.
        Phase 2: Proactive Clarification - Detects vague statements in action items
                 and decisions, suggesting clarifying questions.
        Phase 3: Real-Time Conflict Detection - Detects when current decisions conflict
                 with past decisions and alerts the team immediately.
        Phase 4: Action Item Quality Enhancement - Checks action items for completeness
                 (owner, deadline, clarity) and suggests improvements.
        Phase 5: Follow-up Suggestions - Suggests related topics to discuss based on
                 current conversation (open items, past decisions with implications).

        Args:
            session_id: Current session ID
            project_id: Project ID
            organization_id: Organization ID
            insights: List of newly extracted insights
            context: Full conversation context
            current_chunk: Current transcript chunk being processed

        Returns:
            Tuple of:
            - List of proactive assistance items (auto-answers, clarifications, etc.)
            - Dict mapping phase names to their status (success/failed/skipped)
            - Dict mapping phase names to error messages (only for failed phases)
            - Dict mapping phase names to execution times in milliseconds
        """
        proactive_responses = []
        phase_status: Dict[str, PhaseStatus] = {}
        error_messages: Dict[str, str] = {}
        phase_timings: Dict[str, float] = {}

        # OPTIMIZATION: Pre-determine which phases are relevant to avoid unnecessary processing
        active_phases = self._determine_active_phases(
            chunk_text=current_chunk.text,
            insights=insights
        )

        # Initialize phase status for all possible phases
        all_phases = ['question_answering', 'clarification', 'conflict_detection',
                      'action_item_quality', 'follow_up_suggestions']
        for phase in all_phases:
            if phase not in active_phases:
                phase_status[phase] = PhaseStatus.SKIPPED

        # Enhanced logging (Oct 2025) - Track phase skipping for debugging missing features
        skipped_phases = set(all_phases) - active_phases
        logger.info(
            f"🔍 Phase Execution Stats for chunk {current_chunk.index} (session {sanitize_for_log(session_id[:8])}): "
            f"✅ Active: {len(active_phases)} ({', '.join(sorted(active_phases))}), "
            f"⏭️  Skipped: {len(skipped_phases)} ({', '.join(sorted(skipped_phases))}), "
            f"📊 Insights: {len(insights)}"
        )

        for insight in insights:
            # Phase 1: Auto-answer questions (only if phase 1 is active)
            if 'question_answering' in active_phases and insight.type == InsightType.QUESTION:
                phase_start = time.time()
                try:
                    # Detect and classify the question
                    detected_question = await self.question_detector.detect_and_classify_question(
                        text=insight.content,
                        context=context
                    )

                    if detected_question:
                        # Attempt to auto-answer (with shared cache support)
                        answer = await self.qa_service.answer_question(
                            question=detected_question.text,
                            question_type=detected_question.type,
                            project_id=project_id,
                            organization_id=organization_id,
                            context=context,
                            session_id=session_id
                        )

                        if answer:
                            # Convert AnswerSource objects to dicts
                            sources_dict = [
                                {
                                    'content_id': source.content_id,
                                    'title': source.title,
                                    'snippet': source.snippet,
                                    'date': source.date.isoformat(),
                                    'relevance_score': source.relevance_score,
                                    'meeting_type': source.meeting_type
                                }
                                for source in answer.sources
                            ]

                            proactive_responses.append({
                                'type': 'auto_answer',
                                'insight_id': insight.insight_id,
                                'question': detected_question.text,
                                'answer': answer.answer_text,
                                'confidence': answer.confidence,
                                'sources': sources_dict,
                                'reasoning': answer.reasoning,
                                'timestamp': datetime.now().isoformat()
                            })

                            logger.info(
                                f"Auto-answered question for session {sanitize_for_log(session_id)}: "
                                f"'{detected_question.text[:50]}...' (confidence: {answer.confidence:.2f})"
                            )

                    # Mark Phase 1 as successful
                    phase_status['question_answering'] = PhaseStatus.SUCCESS
                    phase_timings['question_answering'] = (time.time() - phase_start) * 1000

                except Exception as e:
                    # Phase 1 failed - log error but continue processing
                    phase_status['question_answering'] = PhaseStatus.FAILED
                    error_messages['question_answering'] = str(e)
                    phase_timings['question_answering'] = (time.time() - phase_start) * 1000
                    logger.error(
                        f"Phase 1 (question_answering) failed for session {sanitize_for_log(session_id)}: {e}",
                        exc_info=True
                    )

            # Phase 2: Clarification suggestions for vague statements (only if phase 2 is active)
            if 'clarification' in active_phases and insight.type in [InsightType.ACTION_ITEM, InsightType.DECISION]:
                try:
                    clarification = await self.clarification_service.detect_vagueness(
                        statement=insight.content,
                        context=context
                    )

                    # Updated threshold from 0.7 to 0.75 (Oct 2025) to reduce false positives
                    if clarification and clarification.confidence >= 0.75:
                        proactive_responses.append({
                            'type': 'clarification_needed',
                            'insight_id': insight.insight_id,
                            'statement': clarification.statement,
                            'vagueness_type': clarification.vagueness_type,
                            'suggested_questions': clarification.suggested_questions,
                            'confidence': clarification.confidence,
                            'reasoning': clarification.reasoning,
                            'timestamp': datetime.now().isoformat()
                        })

                        logger.info(
                            f"Detected vague statement ({clarification.vagueness_type}) for session "
                            f"{sanitize_for_log(session_id)}: '{clarification.statement[:50]}...' "
                            f"(confidence: {clarification.confidence:.2f})"
                        )

                    # Mark Phase 2 as successful
                    phase_status['clarification'] = PhaseStatus.SUCCESS

                except Exception as e:
                    # Phase 2 failed - log error but continue processing
                    phase_status['clarification'] = PhaseStatus.FAILED
                    error_messages['clarification'] = str(e)
                    logger.error(
                        f"Phase 2 (clarification) failed for session {sanitize_for_log(session_id)}: {e}",
                        exc_info=True
                    )

            # Phase 3: Conflict detection for decisions (only if phase 3 is active)
            if 'conflict_detection' in active_phases and insight.type == InsightType.DECISION:
                try:
                    conflict = await self.conflict_detection_service.detect_conflicts(
                        statement=insight.content,
                        statement_type='decision',
                        project_id=project_id,
                        organization_id=organization_id,
                        context=context,
                        session_id=session_id
                    )

                    if conflict:
                        proactive_responses.append({
                            'type': 'conflict_detected',
                            'insight_id': insight.insight_id,
                            'current_statement': conflict.current_statement,
                            'conflicting_content_id': conflict.conflicting_content_id,
                            'conflicting_title': conflict.conflicting_title,
                            'conflicting_snippet': conflict.conflicting_snippet,
                            'conflicting_date': conflict.conflicting_date.isoformat(),
                            'conflict_severity': conflict.conflict_severity,
                            'confidence': conflict.confidence,
                            'reasoning': conflict.reasoning,
                            'resolution_suggestions': conflict.resolution_suggestions,
                            'timestamp': datetime.now().isoformat()
                        })

                        logger.warning(
                            f"Detected conflict ({conflict.conflict_severity}) for session "
                            f"{sanitize_for_log(session_id)}: '{conflict.current_statement[:50]}...' "
                            f"conflicts with '{conflict.conflicting_title}' "
                            f"(confidence: {conflict.confidence:.2f})"
                        )

                    # Mark Phase 3 as successful
                    phase_status['conflict_detection'] = PhaseStatus.SUCCESS

                except Exception as e:
                    # Phase 3 failed - log error but continue processing
                    phase_status['conflict_detection'] = PhaseStatus.FAILED
                    error_messages['conflict_detection'] = str(e)
                    logger.error(
                        f"Phase 3 (conflict_detection) failed for session {sanitize_for_log(session_id)}: {e}",
                        exc_info=True
                    )

            # Phase 4: Action Item Quality Enhancement (only if phase 4 is active)
            if 'action_item_quality' in active_phases and insight.type == InsightType.ACTION_ITEM:
                try:
                    quality_report = await self.quality_service.check_quality(
                        action_item=insight.content,
                        context=context
                    )

                    # Only suggest improvements if completeness score is critically low
                    # Threshold lowered from 0.8 to 0.5 to reduce false positives (Oct 2025)
                    # Alert only on action items that are less than 50% complete OR have 2+ critical issues
                    critical_issues = [issue for issue in quality_report.issues if issue.severity == 'critical']

                    should_alert = (
                        quality_report.completeness_score < 0.5  # Less than 50% complete
                        or len(critical_issues) >= 2  # Missing both owner AND deadline
                    )

                    if should_alert and len(quality_report.issues) > 0:
                        # Convert QualityIssue objects to dicts
                        issues_dict = [
                            {
                                'field': issue.field,
                                'severity': issue.severity,
                                'message': issue.message,
                                'suggested_fix': issue.suggested_fix
                            }
                            for issue in quality_report.issues
                        ]

                        proactive_responses.append({
                            'type': 'incomplete_action_item',
                            'insight_id': insight.insight_id,
                            'action_item': quality_report.action_item,
                            'completeness_score': quality_report.completeness_score,
                            'issues': issues_dict,
                            'improved_version': quality_report.improved_version,
                            'timestamp': datetime.now().isoformat()
                        })

                        logger.info(
                            f"Detected incomplete action item for session "
                            f"{sanitize_for_log(session_id)}: '{quality_report.action_item[:50]}...' "
                            f"(completeness: {quality_report.completeness_score:.2f}, "
                            f"issues: {len(quality_report.issues)})"
                        )

                    # Mark Phase 4 as successful
                    phase_status['action_item_quality'] = PhaseStatus.SUCCESS

                except Exception as e:
                    # Phase 4 failed - log error but continue processing
                    phase_status['action_item_quality'] = PhaseStatus.FAILED
                    error_messages['action_item_quality'] = str(e)
                    logger.error(
                        f"Phase 4 (action_item_quality) failed for session {sanitize_for_log(session_id)}: {e}",
                        exc_info=True
                    )

            # Phase 5: Follow-up Suggestions (only if phase 5 is active)
            # Suggest follow-ups for decisions and key discussion points
            if 'follow_up_suggestions' in active_phases and insight.type in [InsightType.DECISION, InsightType.KEY_POINT]:
                try:
                    follow_up_suggestions = await self.follow_up_service.suggest_follow_ups(
                        current_topic=insight.content,
                        insight_type=insight.type.value,
                        project_id=project_id,
                        organization_id=organization_id,
                        context=context,
                        session_id=session_id
                    )

                    for suggestion in follow_up_suggestions:
                        proactive_responses.append({
                            'type': 'follow_up_suggestion',
                            'insight_id': insight.insight_id,
                            'topic': suggestion.topic,
                            'reason': suggestion.reason,
                            'related_content_id': suggestion.related_content_id,
                            'related_title': suggestion.related_title,
                            'related_date': suggestion.related_date.isoformat(),
                            'urgency': suggestion.urgency,
                            'context_snippet': suggestion.context_snippet,
                            'confidence': suggestion.confidence,
                            'timestamp': datetime.now().isoformat()
                        })

                        logger.info(
                            f"Suggested follow-up ({suggestion.urgency}) for session "
                            f"{sanitize_for_log(session_id)}: '{suggestion.topic}' "
                            f"(confidence: {suggestion.confidence:.2f})"
                        )

                    # Mark Phase 5 as successful
                    phase_status['follow_up_suggestions'] = PhaseStatus.SUCCESS

                except Exception as e:
                    # Phase 5 failed - log error but continue processing
                    phase_status['follow_up_suggestions'] = PhaseStatus.FAILED
                    error_messages['follow_up_suggestions'] = str(e)
                    logger.error(
                        f"Phase 5 (follow_up_suggestions) failed for session {sanitize_for_log(session_id)}: {e}",
                        exc_info=True
                    )


        # DEDUPLICATION: Merge redundant assistance cards (Oct 2025)
        # Issue #3: Action items often generate both "clarification_needed" and "incomplete_action_item"
        # Solution: Merge them into a single "action_item_quality" card with combined information
        proactive_responses = self._deduplicate_assistance_cards(proactive_responses)

        return proactive_responses, phase_status, error_messages, phase_timings

    def _deduplicate_assistance_cards(self, proactive_responses: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """
        Deduplicate and merge redundant proactive assistance cards.

        Issue: Action items often generate both:
        1. "clarification_needed" (from Phase 2: vagueness detection)
        2. "incomplete_action_item" (from Phase 4: quality check)

        These are effectively the same issue presented twice, creating UI clutter.

        Solution: When both exist for the same action item, merge into single enhanced card:
        - Keep "incomplete_action_item" type (more actionable with specific improvements)
        - Add clarification suggestions as additional context
        - Combine all relevant information into one comprehensive card

        Args:
            proactive_responses: List of raw proactive assistance items

        Returns:
            Deduplicated list with merged cards
        """
        # Group responses by insight_id to find duplicates
        responses_by_insight: Dict[str, List[Dict[str, Any]]] = {}
        for response in proactive_responses:
            insight_id = response.get('insight_id', 'global')
            if insight_id not in responses_by_insight:
                responses_by_insight[insight_id] = []
            responses_by_insight[insight_id].append(response)

        deduplicated = []

        for insight_id, responses in responses_by_insight.items():
            # Check if this insight has both clarification and quality issues
            clarification_card = None
            quality_card = None
            other_cards = []

            for response in responses:
                response_type = response.get('type')
                if response_type == 'clarification_needed':
                    clarification_card = response
                elif response_type == 'incomplete_action_item':
                    quality_card = response
                else:
                    other_cards.append(response)

            # MERGE LOGIC: If both clarification and quality cards exist, merge them
            if clarification_card and quality_card:
                # Merge into enhanced quality card
                merged_card = quality_card.copy()

                # Add clarification information as additional context
                merged_card['clarification_suggestions'] = clarification_card.get('suggested_questions', [])
                merged_card['vagueness_type'] = clarification_card.get('vagueness_type')
                merged_card['vagueness_confidence'] = clarification_card.get('confidence', 0.0)

                # Update reasoning to include both aspects
                clarification_reasoning = clarification_card.get('reasoning', '')
                if clarification_reasoning:
                    merged_card['combined_reasoning'] = f"{clarification_reasoning}. Additionally, the action item needs quality improvements."

                deduplicated.append(merged_card)

                logger.debug(
                    f"Merged clarification and quality cards for insight {insight_id}: "
                    f"vagueness_type={clarification_card.get('vagueness_type')}, "
                    f"completeness_score={quality_card.get('completeness_score', 0):.2f}"
                )

            # If only one type exists, keep it as-is
            elif clarification_card:
                deduplicated.append(clarification_card)
            elif quality_card:
                deduplicated.append(quality_card)

            # Add all other card types
            deduplicated.extend(other_cards)

        # Log deduplication stats
        original_count = len(proactive_responses)
        final_count = len(deduplicated)
        if original_count > final_count:
            logger.info(
                f"Deduplicated proactive assistance: {original_count} → {final_count} cards "
                f"({original_count - final_count} redundant cards merged)"
            )

        return deduplicated

    def cleanup_stale_sessions(self, max_age_hours: int = 4) -> int:
        """
        Clean up stale sessions that haven't been updated recently.

        Args:
            max_age_hours: Maximum age of inactive sessions in hours

        Returns:
            Number of sessions cleaned up
        """
        # TODO: Implement timestamp tracking for sessions
        # For now, manual cleanup via finalize_session
        return 0


# Global service instance
realtime_insights_service = RealtimeMeetingInsightsService()
