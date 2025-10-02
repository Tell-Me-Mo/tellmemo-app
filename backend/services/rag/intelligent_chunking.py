"""Intelligent chunking service with content-aware and semantic boundary detection."""

import re
import math
from typing import List, Dict, Any, Optional, Tuple, Set
from dataclasses import dataclass, asdict
from collections import defaultdict
from enum import Enum

from sentence_transformers import SentenceTransformer
import numpy as np

from utils.logger import get_logger
from utils.monitoring import monitor_sync_operation, monitor_operation, MonitoringContext
from services.transcription.advanced_transcript_parser import (
    AdvancedTranscriptAnalysis, SpeakerTurn, TopicSegment, 
    DecisionPoint, ActionItem, advanced_transcript_processor
)
from services.rag.chunking_service import TextChunk, ChunkingService

logger = get_logger(__name__)


class ChunkType(Enum):
    """Types of content chunks."""
    SPEAKER_TURN = "speaker_turn"
    TOPIC_SEGMENT = "topic_segment"
    DECISION_CONTEXT = "decision_context"
    ACTION_CONTEXT = "action_context"
    DISCUSSION_BLOCK = "discussion_block"
    SEMANTIC_BOUNDARY = "semantic_boundary"


@dataclass
class IntelligentChunk:
    """Enhanced chunk with meeting intelligence metadata."""
    # Base chunk information
    chunk_id: str
    index: int
    text: str
    word_count: int
    char_count: int
    
    # Position information
    start_position: int
    end_position: int
    
    # Content type and structure
    chunk_type: ChunkType
    content_category: str  # 'discussion', 'decision', 'action', 'metadata'
    
    # Meeting intelligence
    speakers_involved: List[str]
    topic_id: Optional[str]
    topic_name: Optional[str]
    related_decisions: List[str]
    related_actions: List[str]
    
    # Semantic information
    semantic_boundary_score: float
    context_continuity_score: float
    importance_score: float
    
    # Temporal context
    timestamp_start: Optional[str]
    timestamp_end: Optional[str]
    turn_indices: List[int]
    
    # Overlap information
    overlap_with_previous: int
    overlap_with_next: int
    
    # Quality metrics
    coherence_score: float
    completeness_score: float
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary format."""
        return asdict(self)
    
    def to_text_chunk(self) -> TextChunk:
        """Convert to standard TextChunk format for backward compatibility."""
        return TextChunk(
            index=self.index,
            text=self.text,
            word_count=self.word_count,
            char_count=self.char_count,
            start_position=self.start_position,
            end_position=self.end_position,
            start_sentence=-1,  # Not used in intelligent chunking
            end_sentence=-1
        )


@dataclass
class ChunkingStrategy:
    """Configuration for chunking optimized for EmbeddingGemma 2048 context."""
    base_chunk_size: int = 1500  # Optimized for 2048 token context
    max_chunk_size: int = 1800   # ~90% of 2048 tokens
    min_chunk_size: int = 300    # Minimum for meaningful context
    overlap_size: int = 200      # Better coherence between chunks

    # Semantic parameters (enhanced for better quality)
    semantic_threshold: float = 0.85  # Higher threshold for better coherence
    topic_boundary_bonus: float = 0.3
    speaker_change_bonus: float = 0.2
    
    # Content type weights
    decision_importance_weight: float = 1.5
    action_importance_weight: float = 1.3
    discussion_importance_weight: float = 1.0
    
    # Quality thresholds
    min_coherence_score: float = 0.6
    min_completeness_score: float = 0.5


class IntelligentChunkingService:
    """Advanced chunking service with meeting intelligence awareness."""
    
    def __init__(self, strategy: Optional[ChunkingStrategy] = None):
        """Initialize intelligent chunking service with EmbeddingGemma optimization."""
        from config import get_settings
        self.settings = get_settings()
        self.strategy = strategy or ChunkingStrategy()
        self.sentence_transformer = None

        # Use larger chunk sizes optimized for EmbeddingGemma
        self.fallback_chunker = ChunkingService(
            chunk_size_words=self.strategy.base_chunk_size,
            overlap_words=self.strategy.overlap_size
        )

        # MRL configuration for semantic analysis
        self.use_mrl_for_coherence = self.settings.enable_mrl
        self.coherence_dimension = 256  # Use 256d for fast coherence checks
        
        # Initialize sentence transformer for semantic analysis
        self._initialize_models()
        
        # Content type patterns
        self.decision_patterns = [
            r'\b(decided|decision|choose|selected|approved|agreed|concluded|resolved)\b',
            r'\b(final|settled|determined|committed|consensus)\b'
        ]
        
        self.action_patterns = [
            r'\b(will|should|must|need to|action|task|todo|responsibility)\b',
            r'\b(assigned|follow up|next step|by \w+day)\b'
        ]
        
        self.discussion_patterns = [
            r'\b(discussed|talked about|mentioned|brought up|suggested)\b',
            r'\b(question|concern|issue|point|idea)\b'
        ]
    
    def _initialize_models(self):
        """Initialize ML models for semantic analysis."""
        try:
            self.sentence_transformer = SentenceTransformer(self.settings.sentence_transformer_model)
            logger.info("Initialized SentenceTransformer for intelligent chunking")
        except Exception as e:
            logger.warning(f"Failed to initialize SentenceTransformer: {e}")
            self.sentence_transformer = None
    
    @monitor_operation("chunk_meeting_content", "chunking", capture_args=True)
    async def chunk_meeting_content(
        self,
        transcript_analysis: AdvancedTranscriptAnalysis,
        strategy: Optional[ChunkingStrategy] = None
    ) -> List[IntelligentChunk]:
        """
        Perform intelligent chunking on meeting content.
        
        Args:
            transcript_analysis: Advanced analysis of meeting transcript
            strategy: Optional custom chunking strategy
            
        Returns:
            List of IntelligentChunk objects with meeting intelligence
        """
        if strategy:
            self.strategy = strategy
        
        logger.info("Starting intelligent chunking of meeting content")
        
        try:
            # Step 1: Speaker-turn aware chunking
            speaker_chunks = await self._chunk_by_speaker_turns(transcript_analysis)
            
            # Step 2: Topic-based chunking
            topic_chunks = await self._chunk_by_topics(transcript_analysis)
            
            # Step 3: Content-type specific chunking
            content_chunks = await self._chunk_by_content_type(transcript_analysis)
            
            # Step 4: Semantic boundary detection
            semantic_chunks = await self._detect_semantic_boundaries(
                transcript_analysis, speaker_chunks
            )
            
            # Step 5: Merge and optimize chunks
            final_chunks = await self._merge_and_optimize_chunks(
                semantic_chunks, transcript_analysis
            )
            
            # Step 6: Add overlapping windows
            overlapped_chunks = await self._add_sliding_windows(final_chunks)
            
            # Step 7: Quality scoring and validation
            validated_chunks = await self._score_and_validate_chunks(
                overlapped_chunks, transcript_analysis
            )
            
            logger.info(f"Intelligent chunking completed: {len(validated_chunks)} chunks created")
            
            # Log statistics
            self._log_chunking_statistics(validated_chunks, transcript_analysis)
            
            return validated_chunks
            
        except Exception as e:
            logger.error(f"Intelligent chunking failed: {e}")
            # Fallback to basic chunking
            return await self._fallback_chunking(transcript_analysis)
    
    @monitor_operation("chunk_by_speaker_turns", "chunking")
    async def _chunk_by_speaker_turns(
        self, 
        analysis: AdvancedTranscriptAnalysis
    ) -> List[IntelligentChunk]:
        """Create chunks based on speaker turns and conversation flow."""
        chunks = []
        chunk_index = 0
        
        current_turn_group = []
        current_word_count = 0
        
        for turn in analysis.speaker_turns:
            turn_words = len(turn.text.split())
            
            # Check if adding this turn exceeds chunk size
            if (current_word_count + turn_words > self.strategy.base_chunk_size and 
                current_turn_group and
                current_word_count >= self.strategy.min_chunk_size):
                
                # Create chunk from current group
                chunk = await self._create_speaker_turn_chunk(
                    current_turn_group, chunk_index
                )
                chunks.append(chunk)
                chunk_index += 1
                
                # Start new group with overlap
                overlap_turns = self._get_overlap_turns(
                    current_turn_group, self.strategy.overlap_size
                )
                current_turn_group = overlap_turns + [turn]
                current_word_count = sum(len(t.text.split()) for t in current_turn_group)
            else:
                current_turn_group.append(turn)
                current_word_count += turn_words
        
        # Add remaining turns as final chunk
        if current_turn_group:
            chunk = await self._create_speaker_turn_chunk(
                current_turn_group, chunk_index
            )
            chunks.append(chunk)
        
        logger.debug(f"Created {len(chunks)} speaker-turn chunks")
        return chunks
    
    @monitor_operation("chunk_by_topics", "chunking")
    async def _chunk_by_topics(
        self, 
        analysis: AdvancedTranscriptAnalysis
    ) -> List[IntelligentChunk]:
        """Create chunks aligned with topic segments."""
        chunks = []
        
        for i, topic_segment in enumerate(analysis.topic_segments):
            # Calculate if topic segment needs to be split
            total_words = sum(len(turn.text.split()) for turn in topic_segment.speaker_turns)
            
            if total_words <= self.strategy.max_chunk_size:
                # Single chunk for entire topic
                chunk = await self._create_topic_chunk(topic_segment, i)
                chunks.append(chunk)
            else:
                # Split topic into multiple chunks
                topic_chunks = await self._split_topic_segment(topic_segment, i)
                chunks.extend(topic_chunks)
        
        logger.debug(f"Created {len(chunks)} topic-based chunks")
        return chunks
    
    @monitor_operation("chunk_by_content_type", "chunking")
    async def _chunk_by_content_type(
        self, 
        analysis: AdvancedTranscriptAnalysis
    ) -> List[IntelligentChunk]:
        """Create chunks based on content types (decisions, actions, discussions)."""
        chunks = []
        chunk_index = 0
        
        # Decision-focused chunks
        for decision in analysis.decision_points:
            chunk = await self._create_decision_chunk(
                decision, analysis.speaker_turns, chunk_index
            )
            if chunk:
                chunks.append(chunk)
                chunk_index += 1
        
        # Action-focused chunks
        for action in analysis.action_items:
            chunk = await self._create_action_chunk(
                action, analysis.speaker_turns, chunk_index
            )
            if chunk:
                chunks.append(chunk)
                chunk_index += 1
        
        logger.debug(f"Created {len(chunks)} content-type chunks")
        return chunks
    
    @monitor_operation("detect_semantic_boundaries", "chunking")
    async def _detect_semantic_boundaries(
        self,
        analysis: AdvancedTranscriptAnalysis,
        base_chunks: List[IntelligentChunk]
    ) -> List[IntelligentChunk]:
        """Detect semantic boundaries using MRL for fast processing."""
        try:
            # Import embedding service for MRL support
            from services.rag.embedding_service import embedding_service

            # Get embeddings for all speaker turns using MRL for speed
            turn_texts = [turn.text for turn in analysis.speaker_turns]

            # Use MRL with reduced dimensions for fast coherence checking
            if self.use_mrl_for_coherence:
                # Generate 256d embeddings for fast semantic analysis
                embeddings = []
                for text in turn_texts:
                    embedding = await embedding_service.generate_embedding_mrl(
                        text, dimension=self.coherence_dimension
                    )
                    embeddings.append(embedding)
                logger.debug(f"Using {self.coherence_dimension}d MRL for semantic boundaries")
            else:
                # Fallback to sentence transformer if available
                if self.sentence_transformer:
                    embeddings = self.sentence_transformer.encode(turn_texts)
                else:
                    logger.warning("No embedding method available, using basic chunking")
                    return base_chunks

            # Calculate semantic similarity between consecutive turns
            boundaries = []
            for i in range(len(embeddings) - 1):
                similarity = self._cosine_similarity(embeddings[i], embeddings[i + 1])

                # Low similarity indicates potential boundary
                # With higher threshold for better coherence
                if similarity < self.strategy.semantic_threshold:
                    boundaries.append(i + 1)  # Boundary after turn i

            # Refine chunks based on semantic boundaries
            refined_chunks = await self._refine_chunks_with_boundaries(
                base_chunks, boundaries, analysis.speaker_turns
            )

            logger.debug(f"Detected {len(boundaries)} semantic boundaries with threshold {self.strategy.semantic_threshold}")
            return refined_chunks
            
        except Exception as e:
            logger.error(f"Semantic boundary detection failed: {e}")
            return base_chunks
    
    @monitor_operation("merge_and_optimize_chunks", "chunking")
    async def _merge_and_optimize_chunks(
        self,
        chunks: List[IntelligentChunk],
        analysis: AdvancedTranscriptAnalysis
    ) -> List[IntelligentChunk]:
        """Merge similar chunks and optimize for better retrieval."""
        if not chunks:
            return []
        
        # Sort chunks by position
        sorted_chunks = sorted(chunks, key=lambda x: x.start_position)
        
        optimized_chunks = []
        current_chunk = sorted_chunks[0]
        
        for i in range(1, len(sorted_chunks)):
            next_chunk = sorted_chunks[i]
            
            # Check if chunks should be merged
            should_merge = await self._should_merge_chunks(current_chunk, next_chunk)
            
            if should_merge and current_chunk.word_count + next_chunk.word_count <= self.strategy.max_chunk_size:
                # Merge chunks
                current_chunk = await self._merge_chunks(current_chunk, next_chunk)
            else:
                # Finalize current chunk and move to next
                optimized_chunks.append(current_chunk)
                current_chunk = next_chunk
        
        # Add final chunk
        optimized_chunks.append(current_chunk)
        
        logger.debug(f"Optimized {len(chunks)} chunks to {len(optimized_chunks)}")
        return optimized_chunks
    
    async def _add_sliding_windows(
        self, 
        chunks: List[IntelligentChunk]
    ) -> List[IntelligentChunk]:
        """Add overlapping sliding windows between chunks."""
        if len(chunks) <= 1:
            return chunks
        
        windowed_chunks = []
        
        for i, chunk in enumerate(chunks):
            windowed_chunks.append(chunk)
            
            # Add sliding window overlap with next chunk
            if i < len(chunks) - 1:
                next_chunk = chunks[i + 1]
                
                # Create overlap window
                overlap_window = await self._create_overlap_window(
                    chunk, next_chunk, i
                )
                
                if overlap_window:
                    windowed_chunks.append(overlap_window)
        
        # Re-index chunks
        for i, chunk in enumerate(windowed_chunks):
            chunk.index = i
        
        logger.debug(f"Added sliding windows: {len(windowed_chunks)} total chunks")
        return windowed_chunks
    
    @monitor_operation("score_and_validate_chunks", "chunking")
    async def _score_and_validate_chunks(
        self,
        chunks: List[IntelligentChunk],
        analysis: AdvancedTranscriptAnalysis
    ) -> List[IntelligentChunk]:
        """Score chunks for quality and validate content."""
        validated_chunks = []
        
        for chunk in chunks:
            # Calculate quality scores
            chunk.coherence_score = await self._calculate_coherence_score(chunk)
            chunk.completeness_score = await self._calculate_completeness_score(chunk, analysis)
            chunk.importance_score = await self._calculate_importance_score(chunk, analysis)
            
            # Validate chunk quality
            if (chunk.coherence_score >= self.strategy.min_coherence_score and
                chunk.completeness_score >= self.strategy.min_completeness_score and
                chunk.word_count >= self.strategy.min_chunk_size):
                
                validated_chunks.append(chunk)
            else:
                logger.debug(f"Filtered out low-quality chunk {chunk.chunk_id}")
        
        logger.debug(f"Validated {len(validated_chunks)}/{len(chunks)} chunks")
        return validated_chunks
    
    async def _fallback_chunking(
        self, 
        analysis: AdvancedTranscriptAnalysis
    ) -> List[IntelligentChunk]:
        """Fallback to basic chunking if intelligent chunking fails."""
        logger.warning("Using fallback chunking strategy")
        
        # Extract full text content
        content = analysis.original_transcript.raw_content
        
        # Use basic chunking service
        basic_chunks = self.fallback_chunker.chunk_text(content)
        
        # Convert to IntelligentChunk format
        intelligent_chunks = []
        for i, basic_chunk in enumerate(basic_chunks):
            chunk = IntelligentChunk(
                chunk_id=f"fallback_{i:03d}",
                index=i,
                text=basic_chunk.text,
                word_count=basic_chunk.word_count,
                char_count=basic_chunk.char_count,
                start_position=basic_chunk.start_position,
                end_position=basic_chunk.end_position,
                chunk_type=ChunkType.DISCUSSION_BLOCK,
                content_category='discussion',
                speakers_involved=[],
                topic_id=None,
                topic_name=None,
                related_decisions=[],
                related_actions=[],
                semantic_boundary_score=0.5,
                context_continuity_score=0.5,
                importance_score=0.5,
                timestamp_start=None,
                timestamp_end=None,
                turn_indices=[],
                overlap_with_previous=0,
                overlap_with_next=0,
                coherence_score=0.7,
                completeness_score=0.7
            )
            intelligent_chunks.append(chunk)
        
        return intelligent_chunks
    
    # Helper methods for chunk creation
    
    async def _create_speaker_turn_chunk(
        self,
        turns: List[SpeakerTurn],
        index: int
    ) -> IntelligentChunk:
        """Create chunk from speaker turns."""
        combined_text = ' '.join(turn.text for turn in turns)
        speakers = list(set(turn.speaker for turn in turns))
        
        # Find related topic
        topic_id = turns[0].topic_id if turns and turns[0].topic_id else None
        topic_name = None
        
        return IntelligentChunk(
            chunk_id=f"speaker_turn_{index:03d}",
            index=index,
            text=combined_text,
            word_count=len(combined_text.split()),
            char_count=len(combined_text),
            start_position=turns[0].start_position if turns else 0,
            end_position=turns[-1].end_position if turns else 0,
            chunk_type=ChunkType.SPEAKER_TURN,
            content_category='discussion',
            speakers_involved=speakers,
            topic_id=topic_id,
            topic_name=topic_name,
            related_decisions=[],
            related_actions=[],
            semantic_boundary_score=0.8,
            context_continuity_score=0.9,
            importance_score=1.0,
            timestamp_start=turns[0].timestamp if turns else None,
            timestamp_end=turns[-1].timestamp if turns else None,
            turn_indices=[t.turn_index for t in turns],
            overlap_with_previous=0,
            overlap_with_next=0,
            coherence_score=0.8,
            completeness_score=0.8
        )
    
    async def _create_topic_chunk(
        self,
        topic_segment: TopicSegment,
        index: int
    ) -> IntelligentChunk:
        """Create chunk from topic segment."""
        combined_text = ' '.join(turn.text for turn in topic_segment.speaker_turns)
        
        return IntelligentChunk(
            chunk_id=f"topic_{index:03d}",
            index=index,
            text=combined_text,
            word_count=len(combined_text.split()),
            char_count=len(combined_text),
            start_position=topic_segment.speaker_turns[0].start_position if topic_segment.speaker_turns else 0,
            end_position=topic_segment.speaker_turns[-1].end_position if topic_segment.speaker_turns else 0,
            chunk_type=ChunkType.TOPIC_SEGMENT,
            content_category='discussion',
            speakers_involved=topic_segment.speakers,
            topic_id=topic_segment.topic_id,
            topic_name=topic_segment.topic_name,
            related_decisions=[],
            related_actions=[],
            semantic_boundary_score=topic_segment.semantic_score,
            context_continuity_score=0.9,
            importance_score=1.2,
            timestamp_start=topic_segment.start_timestamp,
            timestamp_end=topic_segment.end_timestamp,
            turn_indices=[t.turn_index for t in topic_segment.speaker_turns],
            overlap_with_previous=0,
            overlap_with_next=0,
            coherence_score=0.85,
            completeness_score=0.9
        )
    
    async def _create_decision_chunk(
        self,
        decision: DecisionPoint,
        speaker_turns: List[SpeakerTurn],
        index: int
    ) -> Optional[IntelligentChunk]:
        """Create chunk focused on decision context."""
        # Find turns related to this decision
        related_turns = []
        for turn in speaker_turns:
            if decision.context in turn.text or any(
                participant in turn.speaker for participant in decision.participants
            ):
                related_turns.append(turn)
        
        if not related_turns:
            return None
        
        # Include context around decision
        turn_indices = [speaker_turns.index(turn) for turn in related_turns if turn in speaker_turns]
        if turn_indices:
            start_idx = max(0, min(turn_indices) - 1)
            end_idx = min(len(speaker_turns), max(turn_indices) + 2)
            context_turns = speaker_turns[start_idx:end_idx]
        else:
            context_turns = related_turns
        
        combined_text = ' '.join(turn.text for turn in context_turns)
        speakers = list(set(turn.speaker for turn in context_turns))
        
        return IntelligentChunk(
            chunk_id=f"decision_{decision.decision_id}_{index}",
            index=index,
            text=combined_text,
            word_count=len(combined_text.split()),
            char_count=len(combined_text),
            start_position=context_turns[0].start_position if context_turns else 0,
            end_position=context_turns[-1].end_position if context_turns else 0,
            chunk_type=ChunkType.DECISION_CONTEXT,
            content_category='decision',
            speakers_involved=speakers,
            topic_id=None,
            topic_name=decision.related_topic,
            related_decisions=[decision.decision_id],
            related_actions=[],
            semantic_boundary_score=0.9,
            context_continuity_score=0.8,
            importance_score=self.strategy.decision_importance_weight,
            timestamp_start=decision.timestamp,
            timestamp_end=decision.timestamp,
            turn_indices=[t.turn_index for t in context_turns],
            overlap_with_previous=0,
            overlap_with_next=0,
            coherence_score=0.9,
            completeness_score=0.85
        )
    
    async def _create_action_chunk(
        self,
        action: ActionItem,
        speaker_turns: List[SpeakerTurn],
        index: int
    ) -> Optional[IntelligentChunk]:
        """Create chunk focused on action item context."""
        # Find turns related to this action
        related_turns = []
        for turn in speaker_turns:
            if (action.context in turn.text or 
                (action.assignee and action.assignee in turn.speaker)):
                related_turns.append(turn)
        
        if not related_turns:
            return None
        
        # Include context around action
        turn_indices = [speaker_turns.index(turn) for turn in related_turns if turn in speaker_turns]
        if turn_indices:
            start_idx = max(0, min(turn_indices) - 1)
            end_idx = min(len(speaker_turns), max(turn_indices) + 2)
            context_turns = speaker_turns[start_idx:end_idx]
        else:
            context_turns = related_turns
        
        combined_text = ' '.join(turn.text for turn in context_turns)
        speakers = list(set(turn.speaker for turn in context_turns))
        
        return IntelligentChunk(
            chunk_id=f"action_{action.action_id}_{index}",
            index=index,
            text=combined_text,
            word_count=len(combined_text.split()),
            char_count=len(combined_text),
            start_position=context_turns[0].start_position if context_turns else 0,
            end_position=context_turns[-1].end_position if context_turns else 0,
            chunk_type=ChunkType.ACTION_CONTEXT,
            content_category='action',
            speakers_involved=speakers,
            topic_id=None,
            topic_name=None,
            related_decisions=[],
            related_actions=[action.action_id],
            semantic_boundary_score=0.85,
            context_continuity_score=0.8,
            importance_score=self.strategy.action_importance_weight,
            timestamp_start=action.timestamp,
            timestamp_end=action.timestamp,
            turn_indices=[t.turn_index for t in context_turns],
            overlap_with_previous=0,
            overlap_with_next=0,
            coherence_score=0.88,
            completeness_score=0.82
        )
    
    # Helper methods for optimization
    
    def _get_overlap_turns(self, turns: List[SpeakerTurn], overlap_words: int) -> List[SpeakerTurn]:
        """Get turns for overlap based on word count."""
        overlap_turns = []
        word_count = 0
        
        for turn in reversed(turns):
            turn_words = len(turn.text.split())
            if word_count + turn_words <= overlap_words:
                overlap_turns.insert(0, turn)
                word_count += turn_words
            else:
                break
        
        return overlap_turns
    
    async def _split_topic_segment(
        self,
        topic_segment: TopicSegment,
        base_index: int
    ) -> List[IntelligentChunk]:
        """Split large topic segment into smaller chunks."""
        chunks = []
        current_turns = []
        current_words = 0
        chunk_count = 0
        
        for turn in topic_segment.speaker_turns:
            turn_words = len(turn.text.split())
            
            if (current_words + turn_words > self.strategy.base_chunk_size and 
                current_turns and current_words >= self.strategy.min_chunk_size):
                
                # Create chunk
                chunk = await self._create_topic_sub_chunk(
                    current_turns, topic_segment, f"{base_index}_{chunk_count}"
                )
                chunks.append(chunk)
                
                # Start new chunk with overlap
                overlap_turns = self._get_overlap_turns(current_turns, self.strategy.overlap_size)
                current_turns = overlap_turns + [turn]
                current_words = sum(len(t.text.split()) for t in current_turns)
                chunk_count += 1
            else:
                current_turns.append(turn)
                current_words += turn_words
        
        # Add remaining turns
        if current_turns:
            chunk = await self._create_topic_sub_chunk(
                current_turns, topic_segment, f"{base_index}_{chunk_count}"
            )
            chunks.append(chunk)
        
        return chunks
    
    async def _create_topic_sub_chunk(
        self,
        turns: List[SpeakerTurn],
        topic_segment: TopicSegment,
        chunk_id: str
    ) -> IntelligentChunk:
        """Create sub-chunk from topic segment."""
        combined_text = ' '.join(turn.text for turn in turns)
        speakers = list(set(turn.speaker for turn in turns))
        
        return IntelligentChunk(
            chunk_id=f"topic_sub_{chunk_id}",
            index=0,  # Will be re-indexed later
            text=combined_text,
            word_count=len(combined_text.split()),
            char_count=len(combined_text),
            start_position=turns[0].start_position,
            end_position=turns[-1].end_position,
            chunk_type=ChunkType.TOPIC_SEGMENT,
            content_category='discussion',
            speakers_involved=speakers,
            topic_id=topic_segment.topic_id,
            topic_name=topic_segment.topic_name,
            related_decisions=[],
            related_actions=[],
            semantic_boundary_score=topic_segment.semantic_score,
            context_continuity_score=0.85,
            importance_score=1.1,
            timestamp_start=turns[0].timestamp,
            timestamp_end=turns[-1].timestamp,
            turn_indices=[t.turn_index for t in turns],
            overlap_with_previous=0,
            overlap_with_next=0,
            coherence_score=0.8,
            completeness_score=0.85
        )
    
    async def _refine_chunks_with_boundaries(
        self,
        chunks: List[IntelligentChunk],
        boundaries: List[int],
        speaker_turns: List[SpeakerTurn]
    ) -> List[IntelligentChunk]:
        """Refine chunks based on semantic boundaries."""
        # For now, return chunks as-is
        # This could be enhanced to actually split chunks at semantic boundaries
        return chunks
    
    async def _should_merge_chunks(
        self,
        chunk1: IntelligentChunk,
        chunk2: IntelligentChunk
    ) -> bool:
        """Determine if two chunks should be merged."""
        # Don't merge if they're different content types
        if chunk1.content_category != chunk2.content_category:
            return False
        
        # Don't merge if they're from different topics
        if chunk1.topic_id and chunk2.topic_id and chunk1.topic_id != chunk2.topic_id:
            return False
        
        # Merge if they're both small
        if (chunk1.word_count < self.strategy.min_chunk_size * 1.2 and
            chunk2.word_count < self.strategy.min_chunk_size * 1.2):
            return True
        
        return False
    
    async def _merge_chunks(
        self,
        chunk1: IntelligentChunk,
        chunk2: IntelligentChunk
    ) -> IntelligentChunk:
        """Merge two chunks into one."""
        merged_text = f"{chunk1.text} {chunk2.text}"
        merged_speakers = list(set(chunk1.speakers_involved + chunk2.speakers_involved))
        
        return IntelligentChunk(
            chunk_id=f"merged_{chunk1.chunk_id}_{chunk2.chunk_id}",
            index=chunk1.index,
            text=merged_text,
            word_count=chunk1.word_count + chunk2.word_count,
            char_count=chunk1.char_count + chunk2.char_count,
            start_position=chunk1.start_position,
            end_position=chunk2.end_position,
            chunk_type=chunk1.chunk_type,
            content_category=chunk1.content_category,
            speakers_involved=merged_speakers,
            topic_id=chunk1.topic_id or chunk2.topic_id,
            topic_name=chunk1.topic_name or chunk2.topic_name,
            related_decisions=list(set(chunk1.related_decisions + chunk2.related_decisions)),
            related_actions=list(set(chunk1.related_actions + chunk2.related_actions)),
            semantic_boundary_score=(chunk1.semantic_boundary_score + chunk2.semantic_boundary_score) / 2,
            context_continuity_score=(chunk1.context_continuity_score + chunk2.context_continuity_score) / 2,
            importance_score=max(chunk1.importance_score, chunk2.importance_score),
            timestamp_start=chunk1.timestamp_start,
            timestamp_end=chunk2.timestamp_end,
            turn_indices=list(set(chunk1.turn_indices + chunk2.turn_indices)),
            overlap_with_previous=chunk1.overlap_with_previous,
            overlap_with_next=chunk2.overlap_with_next,
            coherence_score=(chunk1.coherence_score + chunk2.coherence_score) / 2,
            completeness_score=(chunk1.completeness_score + chunk2.completeness_score) / 2
        )
    
    async def _create_overlap_window(
        self,
        chunk1: IntelligentChunk,
        chunk2: IntelligentChunk,
        index: int
    ) -> Optional[IntelligentChunk]:
        """Create overlap window between two chunks."""
        # Extract overlap text from end of chunk1 and beginning of chunk2
        words1 = chunk1.text.split()
        words2 = chunk2.text.split()
        
        overlap_size = min(self.strategy.overlap_size, len(words1), len(words2))
        if overlap_size < 20:  # Minimum meaningful overlap
            return None
        
        overlap_words = words1[-overlap_size//2:] + words2[:overlap_size//2]
        overlap_text = ' '.join(overlap_words)
        
        return IntelligentChunk(
            chunk_id=f"overlap_{index}_{index+1}",
            index=index * 10 + 5,  # Insert between chunks
            text=overlap_text,
            word_count=len(overlap_words),
            char_count=len(overlap_text),
            start_position=chunk1.end_position - len(' '.join(words1[-overlap_size//2:])),
            end_position=chunk2.start_position + len(' '.join(words2[:overlap_size//2])),
            chunk_type=ChunkType.SEMANTIC_BOUNDARY,
            content_category='transition',
            speakers_involved=list(set(chunk1.speakers_involved + chunk2.speakers_involved)),
            topic_id=chunk1.topic_id or chunk2.topic_id,
            topic_name=None,
            related_decisions=list(set(chunk1.related_decisions + chunk2.related_decisions)),
            related_actions=list(set(chunk1.related_actions + chunk2.related_actions)),
            semantic_boundary_score=0.5,  # Boundary by definition
            context_continuity_score=0.9,  # High continuity
            importance_score=(chunk1.importance_score + chunk2.importance_score) / 2,
            timestamp_start=chunk1.timestamp_end,
            timestamp_end=chunk2.timestamp_start,
            turn_indices=[],
            overlap_with_previous=overlap_size//2,
            overlap_with_next=overlap_size//2,
            coherence_score=0.7,
            completeness_score=0.6
        )
    
    # Quality scoring methods
    
    async def _calculate_coherence_score(self, chunk: IntelligentChunk) -> float:
        """Calculate coherence score for chunk."""
        # Simple heuristic based on content type and structure
        base_score = 0.7
        
        # Boost for complete sentences
        sentences = chunk.text.split('.')
        complete_sentences = [s.strip() for s in sentences if s.strip() and len(s.strip()) > 5]
        if len(complete_sentences) > 0:
            base_score += 0.1
        
        # Boost for specific content types
        if chunk.chunk_type in [ChunkType.DECISION_CONTEXT, ChunkType.ACTION_CONTEXT]:
            base_score += 0.1
        
        # Penalty for very short chunks
        if chunk.word_count < self.strategy.min_chunk_size * 0.8:
            base_score -= 0.2
        
        return min(max(base_score, 0.0), 1.0)
    
    async def _calculate_completeness_score(
        self,
        chunk: IntelligentChunk,
        analysis: AdvancedTranscriptAnalysis
    ) -> float:
        """Calculate completeness score for chunk."""
        base_score = 0.6
        
        # Boost for containing complete speaker turns
        if chunk.turn_indices and len(chunk.turn_indices) > 0:
            base_score += 0.2
        
        # Boost for topic alignment
        if chunk.topic_id:
            base_score += 0.1
        
        # Boost for decision/action context
        if chunk.related_decisions or chunk.related_actions:
            base_score += 0.1
        
        return min(max(base_score, 0.0), 1.0)
    
    async def _calculate_importance_score(
        self,
        chunk: IntelligentChunk,
        analysis: AdvancedTranscriptAnalysis
    ) -> float:
        """Calculate importance score for chunk."""
        base_score = 1.0
        
        # Weight by content category
        if chunk.content_category == 'decision':
            base_score *= self.strategy.decision_importance_weight
        elif chunk.content_category == 'action':
            base_score *= self.strategy.action_importance_weight
        
        # Boost for multiple speakers (indicates discussion)
        if len(chunk.speakers_involved) > 2:
            base_score *= 1.1
        
        return min(base_score, 2.0)
    
    # Utility methods
    
    def _cosine_similarity(self, a: np.ndarray, b: np.ndarray) -> float:
        """Calculate cosine similarity between vectors."""
        return np.dot(a, b) / (np.linalg.norm(a) * np.linalg.norm(b))
    
    def _log_chunking_statistics(
        self,
        chunks: List[IntelligentChunk],
        analysis: AdvancedTranscriptAnalysis
    ):
        """Log statistics about the chunking results."""
        if not chunks:
            return
        
        total_words = sum(chunk.word_count for chunk in chunks)
        word_counts = [chunk.word_count for chunk in chunks]
        
        chunk_types = defaultdict(int)
        content_categories = defaultdict(int)
        
        for chunk in chunks:
            chunk_types[chunk.chunk_type.value] += 1
            content_categories[chunk.content_category] += 1
        
        logger.info(f"Chunking Statistics:")
        logger.info(f"  Total chunks: {len(chunks)}")
        logger.info(f"  Total words: {total_words}")
        logger.info(f"  Average words per chunk: {total_words / len(chunks):.1f}")
        logger.info(f"  Min/Max words: {min(word_counts)}/{max(word_counts)}")
        logger.info(f"  Chunk types: {dict(chunk_types)}")
        logger.info(f"  Content categories: {dict(content_categories)}")
        logger.info(f"  Average importance: {sum(c.importance_score for c in chunks) / len(chunks):.2f}")
        logger.info(f"  Average coherence: {sum(c.coherence_score for c in chunks) / len(chunks):.2f}")


# Global service instance
intelligent_chunking_service = IntelligentChunkingService()