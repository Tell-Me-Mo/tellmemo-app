"""
Insight Evolution Tracker Service.

This service tracks how insights and proactive assistance evolve over time during a meeting,
detecting priority escalations, content expansions, and refinements that should trigger
UI updates rather than creating duplicate entries.

Architecture:
- Semantic similarity matching to identify evolved versions of previous insights
- Priority escalation detection (e.g., medium → high → critical)
- Content expansion tracking (e.g., vague action item → detailed with owner/deadline)
- Temporal tracking of insight lifecycle (original → updates → final state)

Use Cases:
1. Priority Escalation: "Review the API" (LOW) → "API security breach detected!" (CRITICAL)
2. Content Expansion: "John will do something" → "John will complete API security audit by Friday"
3. Refinement: "We decided on GraphQL" → "We decided on GraphQL v5 with Apollo Server 4"
4. Status Updates: "Need to discuss pricing" → "Pricing approved at $99/month"
"""

import time
from typing import Dict, List, Optional, Tuple
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum

from services.rag.embedding_service import embedding_service
from utils.logger import get_logger

logger = get_logger(__name__)


class EvolutionType(Enum):
    """Types of insight evolution."""
    NEW = "new"  # Brand new insight
    ESCALATED = "escalated"  # Priority increased
    EXPANDED = "expanded"  # More details added
    REFINED = "refined"  # Content improved/clarified
    UPDATED = "updated"  # Status or state changed
    DUPLICATE = "duplicate"  # Exact duplicate (no evolution)


@dataclass
class InsightEvolution:
    """
    Tracks the evolution of a single insight over time.

    Maintains:
    - Original insight ID and content
    - All versions with timestamps
    - Evolution history (escalated/expanded/refined)
    - Merged content showing progression
    """
    original_insight_id: str
    original_content: str
    original_priority: str
    original_timestamp: datetime

    # Current state (after all evolutions)
    current_content: str
    current_priority: str
    last_updated: datetime

    # Evolution history
    evolution_count: int = 0
    evolution_types: List[EvolutionType] = field(default_factory=list)
    evolution_timestamps: List[datetime] = field(default_factory=list)
    evolution_chunk_indices: List[int] = field(default_factory=list)

    # All versions of this insight
    version_history: List[Dict] = field(default_factory=list)

    def to_dict(self) -> Dict:
        """Convert to dictionary for serialization."""
        return {
            'original_insight_id': self.original_insight_id,
            'original_content': self.original_content,
            'original_priority': self.original_priority,
            'original_timestamp': self.original_timestamp.isoformat(),
            'current_content': self.current_content,
            'current_priority': self.current_priority,
            'last_updated': self.last_updated.isoformat(),
            'evolution_count': self.evolution_count,
            'evolution_types': [et.value for et in self.evolution_types],
            'evolution_timestamps': [ts.isoformat() for ts in self.evolution_timestamps],
            'evolution_chunk_indices': self.evolution_chunk_indices,
            'version_history': self.version_history,
        }


@dataclass
class EvolutionResult:
    """
    Result of checking if an insight is an evolution of a previous one.
    """
    is_evolution: bool
    evolution_type: EvolutionType
    original_insight_id: Optional[str] = None
    similarity_score: float = 0.0
    reason: str = ""
    merged_insight: Optional[Dict] = None  # The merged/updated insight to send to UI


class InsightEvolutionTracker:
    """
    Tracks insight evolution during a meeting session.

    Features:
    - Semantic similarity matching (threshold: 0.75 for evolution detection)
    - Priority escalation detection (LOW → MEDIUM → HIGH → CRITICAL)
    - Content expansion analysis (word count, detail level)
    - Refinement detection (improved clarity, added specifics)
    - WebSocket update generation for UI sync

    Performance:
    - <50ms per insight check (embedding similarity)
    - Memory: ~5KB per tracked insight
    - Automatic cleanup on session end
    """

    # Priority ordering (higher index = higher priority)
    PRIORITY_ORDER = {
        'low': 0,
        'medium': 1,
        'high': 2,
        'critical': 3,
    }

    # Similarity threshold for considering insights as related
    SIMILARITY_THRESHOLD = 0.75  # Lower than duplicate detection (0.85)

    # Content expansion thresholds
    MIN_EXPANSION_RATIO = 1.3  # 30% more content = expansion
    MIN_WORD_DIFFERENCE = 5  # At least 5 more words

    def __init__(self):
        # Session-level tracking: session_id → {insight_id → InsightEvolution}
        self.session_evolutions: Dict[str, Dict[str, InsightEvolution]] = {}

        # Cached embeddings for fast similarity checks: session_id → {insight_id → embedding}
        self.insight_embeddings: Dict[str, Dict[str, List[float]]] = {}

    async def check_evolution(
        self,
        session_id: str,
        new_insight: Dict,
        chunk_index: int
    ) -> EvolutionResult:
        """
        Check if a new insight is an evolution of a previous one.

        Process:
        1. Generate embedding for new insight
        2. Compare with all existing insights in session
        3. If similar (>0.75), check for evolution:
           - Priority escalation
           - Content expansion
           - Refinement
        4. If evolution detected, merge and generate update

        Args:
            session_id: Meeting session ID
            new_insight: New insight dictionary from extraction
            chunk_index: Current chunk index

        Returns:
            EvolutionResult with evolution type and merged insight
        """
        start_time = time.time()

        # Initialize session tracking if needed
        if session_id not in self.session_evolutions:
            self.session_evolutions[session_id] = {}
            self.insight_embeddings[session_id] = {}

        # Generate embedding for new insight
        new_content = new_insight.get('content', '')
        new_priority = new_insight.get('priority', 'medium').lower()
        new_type = new_insight.get('type', 'key_point')

        try:
            new_embedding = await embedding_service.generate_embedding(new_content)
        except Exception as e:
            logger.error(f"Failed to generate embedding for evolution check: {e}")
            # If embedding fails, treat as new insight
            return EvolutionResult(
                is_evolution=False,
                evolution_type=EvolutionType.NEW,
                reason="Embedding generation failed - treating as new"
            )

        # Check similarity with existing insights of the same type
        similar_insights = await self._find_similar_insights(
            session_id=session_id,
            new_embedding=new_embedding,
            new_type=new_type,
            new_priority=new_priority
        )

        if not similar_insights:
            # Brand new insight - store and track it
            await self._store_new_insight(
                session_id=session_id,
                insight=new_insight,
                embedding=new_embedding,
                chunk_index=chunk_index
            )

            elapsed = (time.time() - start_time) * 1000
            logger.debug(f"New insight detected in {elapsed:.1f}ms")

            return EvolutionResult(
                is_evolution=False,
                evolution_type=EvolutionType.NEW,
                reason="No similar existing insights found"
            )

        # Found similar insight(s) - check for evolution
        # Use the most similar one
        original_id, similarity = similar_insights[0]
        original_evolution = self.session_evolutions[session_id][original_id]

        # Check for priority escalation
        if self._is_priority_escalation(original_evolution.current_priority, new_priority):
            merged = self._merge_escalated_insight(
                original_evolution=original_evolution,
                new_insight=new_insight,
                chunk_index=chunk_index
            )

            elapsed = (time.time() - start_time) * 1000
            logger.info(
                f"Priority escalation detected: {original_evolution.current_priority} → {new_priority} "
                f"(similarity: {similarity:.2f}, {elapsed:.1f}ms)"
            )

            return EvolutionResult(
                is_evolution=True,
                evolution_type=EvolutionType.ESCALATED,
                original_insight_id=original_id,
                similarity_score=similarity,
                reason=f"Priority escalated from {original_evolution.current_priority} to {new_priority}",
                merged_insight=merged
            )

        # Check for content expansion
        if self._is_content_expansion(original_evolution.current_content, new_content):
            merged = self._merge_expanded_insight(
                original_evolution=original_evolution,
                new_insight=new_insight,
                chunk_index=chunk_index
            )

            elapsed = (time.time() - start_time) * 1000
            logger.info(
                f"Content expansion detected: {len(original_evolution.current_content)} → {len(new_content)} chars "
                f"(similarity: {similarity:.2f}, {elapsed:.1f}ms)"
            )

            return EvolutionResult(
                is_evolution=True,
                evolution_type=EvolutionType.EXPANDED,
                original_insight_id=original_id,
                similarity_score=similarity,
                reason=f"Content expanded by {len(new_content) - len(original_evolution.current_content)} characters",
                merged_insight=merged
            )

        # Check for refinement (similar length but improved clarity)
        if self._is_refinement(original_evolution.current_content, new_content, new_insight):
            merged = self._merge_refined_insight(
                original_evolution=original_evolution,
                new_insight=new_insight,
                chunk_index=chunk_index
            )

            elapsed = (time.time() - start_time) * 1000
            logger.info(
                f"Refinement detected: improved clarity/specificity "
                f"(similarity: {similarity:.2f}, {elapsed:.1f}ms)"
            )

            return EvolutionResult(
                is_evolution=True,
                evolution_type=EvolutionType.REFINED,
                original_insight_id=original_id,
                similarity_score=similarity,
                reason="Content refined with more specific details",
                merged_insight=merged
            )

        # High similarity but no significant evolution - likely duplicate
        if similarity > 0.85:
            elapsed = (time.time() - start_time) * 1000
            logger.debug(
                f"Duplicate insight detected (similarity: {similarity:.2f}, {elapsed:.1f}ms)"
            )

            return EvolutionResult(
                is_evolution=False,
                evolution_type=EvolutionType.DUPLICATE,
                original_insight_id=original_id,
                similarity_score=similarity,
                reason=f"Very similar to existing insight (similarity: {similarity:.2f})"
            )

        # Similar but different enough - treat as new
        await self._store_new_insight(
            session_id=session_id,
            insight=new_insight,
            embedding=new_embedding,
            chunk_index=chunk_index
        )

        elapsed = (time.time() - start_time) * 1000
        logger.debug(
            f"New insight (similar but distinct, similarity: {similarity:.2f}, {elapsed:.1f}ms)"
        )

        return EvolutionResult(
            is_evolution=False,
            evolution_type=EvolutionType.NEW,
            reason=f"Similar but distinct enough to be separate (similarity: {similarity:.2f})"
        )

    async def _find_similar_insights(
        self,
        session_id: str,
        new_embedding: List[float],
        new_type: str,
        new_priority: str
    ) -> List[Tuple[str, float]]:
        """
        Find existing insights similar to the new one.

        Only compares insights of the same type for relevance.
        Returns list of (insight_id, similarity_score) tuples sorted by similarity.
        """
        similar = []

        for insight_id, stored_embedding in self.insight_embeddings[session_id].items():
            evolution = self.session_evolutions[session_id][insight_id]

            # Only compare with same type
            if evolution.version_history and evolution.version_history[0].get('type') != new_type:
                continue

            # Calculate cosine similarity
            similarity = self._cosine_similarity(new_embedding, stored_embedding)

            if similarity >= self.SIMILARITY_THRESHOLD:
                similar.append((insight_id, similarity))

        # Sort by similarity (highest first)
        similar.sort(key=lambda x: x[1], reverse=True)

        return similar

    def _is_priority_escalation(self, old_priority: str, new_priority: str) -> bool:
        """Check if priority increased."""
        old_level = self.PRIORITY_ORDER.get(old_priority.lower(), 1)
        new_level = self.PRIORITY_ORDER.get(new_priority.lower(), 1)
        return new_level > old_level

    def _is_content_expansion(self, old_content: str, new_content: str) -> bool:
        """
        Check if content significantly expanded.

        Criteria:
        - At least 30% more characters
        - At least 5 more words
        """
        old_words = len(old_content.split())
        new_words = len(new_content.split())

        expansion_ratio = len(new_content) / max(len(old_content), 1)
        word_diff = new_words - old_words

        return (
            expansion_ratio >= self.MIN_EXPANSION_RATIO and
            word_diff >= self.MIN_WORD_DIFFERENCE
        )

    def _is_refinement(self, old_content: str, new_content: str, new_insight: Dict) -> bool:
        """
        Check if content was refined (improved without major expansion).

        Refinement indicators:
        - Similar length (within 20%)
        - New content has more specific details (assigned_to, due_date)
        - More structured/clear wording
        """
        length_ratio = len(new_content) / max(len(old_content), 1)

        # Check if length is similar (0.8 to 1.2x)
        if not (0.8 <= length_ratio <= 1.2):
            return False

        # Check if new insight has more specific fields
        has_assigned_to = bool(new_insight.get('assigned_to'))
        has_due_date = bool(new_insight.get('due_date'))

        # Refinement if added specific details
        return has_assigned_to or has_due_date

    def _merge_escalated_insight(
        self,
        original_evolution: InsightEvolution,
        new_insight: Dict,
        chunk_index: int
    ) -> Dict:
        """
        Merge insights when priority escalated.

        Strategy: Keep new priority, combine content to show progression.
        """
        new_priority = new_insight.get('priority', 'medium')
        new_content = new_insight.get('content', '')

        # Update evolution tracking
        original_evolution.current_priority = new_priority
        original_evolution.current_content = new_content
        original_evolution.last_updated = datetime.utcnow()
        original_evolution.evolution_count += 1
        original_evolution.evolution_types.append(EvolutionType.ESCALATED)
        original_evolution.evolution_timestamps.append(datetime.utcnow())
        original_evolution.evolution_chunk_indices.append(chunk_index)

        # Add to version history
        original_evolution.version_history.append({
            'content': new_content,
            'priority': new_priority,
            'timestamp': datetime.utcnow().isoformat(),
            'chunk_index': chunk_index,
            'evolution_type': EvolutionType.ESCALATED.value,
        })

        # Build merged insight
        merged = {
            'insight_id': original_evolution.original_insight_id,
            'type': new_insight.get('type'),
            'priority': new_priority,  # Use new priority
            'content': new_content,  # Use new content
            'context': new_insight.get('context', ''),
            'timestamp': original_evolution.original_timestamp.isoformat(),
            'assigned_to': new_insight.get('assigned_to'),
            'due_date': new_insight.get('due_date'),
            'source_chunk_index': chunk_index,
            'confidence_score': new_insight.get('confidence_score', 0.0),
            'evolution_note': f"Priority escalated at chunk {chunk_index} ({original_evolution.evolution_count} updates)",
            'evolution_type': EvolutionType.ESCALATED.value,
            'original_priority': original_evolution.original_priority,
        }

        return merged

    def _merge_expanded_insight(
        self,
        original_evolution: InsightEvolution,
        new_insight: Dict,
        chunk_index: int
    ) -> Dict:
        """
        Merge insights when content expanded.

        Strategy: Use new expanded content, keep highest priority.
        """
        new_priority = new_insight.get('priority', 'medium')
        new_content = new_insight.get('content', '')

        # Keep highest priority
        old_level = self.PRIORITY_ORDER.get(original_evolution.current_priority.lower(), 1)
        new_level = self.PRIORITY_ORDER.get(new_priority.lower(), 1)
        final_priority = new_priority if new_level > old_level else original_evolution.current_priority

        # Update evolution tracking
        original_evolution.current_priority = final_priority
        original_evolution.current_content = new_content
        original_evolution.last_updated = datetime.utcnow()
        original_evolution.evolution_count += 1
        original_evolution.evolution_types.append(EvolutionType.EXPANDED)
        original_evolution.evolution_timestamps.append(datetime.utcnow())
        original_evolution.evolution_chunk_indices.append(chunk_index)

        # Add to version history
        original_evolution.version_history.append({
            'content': new_content,
            'priority': final_priority,
            'timestamp': datetime.utcnow().isoformat(),
            'chunk_index': chunk_index,
            'evolution_type': EvolutionType.EXPANDED.value,
        })

        # Build merged insight
        merged = {
            'insight_id': original_evolution.original_insight_id,
            'type': new_insight.get('type'),
            'priority': final_priority,
            'content': new_content,  # Use expanded content
            'context': new_insight.get('context', ''),
            'timestamp': original_evolution.original_timestamp.isoformat(),
            'assigned_to': new_insight.get('assigned_to'),
            'due_date': new_insight.get('due_date'),
            'source_chunk_index': chunk_index,
            'confidence_score': new_insight.get('confidence_score', 0.0),
            'evolution_note': f"Content expanded at chunk {chunk_index} ({original_evolution.evolution_count} updates)",
            'evolution_type': EvolutionType.EXPANDED.value,
        }

        return merged

    def _merge_refined_insight(
        self,
        original_evolution: InsightEvolution,
        new_insight: Dict,
        chunk_index: int
    ) -> Dict:
        """
        Merge insights when refined with more specific details.

        Strategy: Use new refined content, preserve priority unless escalated.
        """
        new_priority = new_insight.get('priority', 'medium')
        new_content = new_insight.get('content', '')

        # Keep highest priority
        old_level = self.PRIORITY_ORDER.get(original_evolution.current_priority.lower(), 1)
        new_level = self.PRIORITY_ORDER.get(new_priority.lower(), 1)
        final_priority = new_priority if new_level > old_level else original_evolution.current_priority

        # Update evolution tracking
        original_evolution.current_priority = final_priority
        original_evolution.current_content = new_content
        original_evolution.last_updated = datetime.utcnow()
        original_evolution.evolution_count += 1
        original_evolution.evolution_types.append(EvolutionType.REFINED)
        original_evolution.evolution_timestamps.append(datetime.utcnow())
        original_evolution.evolution_chunk_indices.append(chunk_index)

        # Add to version history
        original_evolution.version_history.append({
            'content': new_content,
            'priority': final_priority,
            'timestamp': datetime.utcnow().isoformat(),
            'chunk_index': chunk_index,
            'evolution_type': EvolutionType.REFINED.value,
        })

        # Build merged insight
        merged = {
            'insight_id': original_evolution.original_insight_id,
            'type': new_insight.get('type'),
            'priority': final_priority,
            'content': new_content,  # Use refined content
            'context': new_insight.get('context', ''),
            'timestamp': original_evolution.original_timestamp.isoformat(),
            'assigned_to': new_insight.get('assigned_to'),
            'due_date': new_insight.get('due_date'),
            'source_chunk_index': chunk_index,
            'confidence_score': new_insight.get('confidence_score', 0.0),
            'evolution_note': f"Content refined at chunk {chunk_index} ({original_evolution.evolution_count} updates)",
            'evolution_type': EvolutionType.REFINED.value,
        }

        return merged

    async def _store_new_insight(
        self,
        session_id: str,
        insight: Dict,
        embedding: List[float],
        chunk_index: int
    ):
        """Store a new insight and its embedding for future evolution tracking."""
        insight_id = insight.get('insight_id', f"insight_{chunk_index}")
        content = insight.get('content', '')
        priority = insight.get('priority', 'medium').lower()
        timestamp = datetime.utcnow()

        # Create evolution tracking
        evolution = InsightEvolution(
            original_insight_id=insight_id,
            original_content=content,
            original_priority=priority,
            original_timestamp=timestamp,
            current_content=content,
            current_priority=priority,
            last_updated=timestamp,
            version_history=[{
                'content': content,
                'priority': priority,
                'timestamp': timestamp.isoformat(),
                'chunk_index': chunk_index,
                'evolution_type': EvolutionType.NEW.value,
            }]
        )

        # Store tracking and embedding
        self.session_evolutions[session_id][insight_id] = evolution
        self.insight_embeddings[session_id][insight_id] = embedding

    def _cosine_similarity(self, vec1: List[float], vec2: List[float]) -> float:
        """Calculate cosine similarity between two vectors."""
        if not vec1 or not vec2 or len(vec1) != len(vec2):
            return 0.0

        dot_product = sum(a * b for a, b in zip(vec1, vec2))
        norm1 = sum(a * a for a in vec1) ** 0.5
        norm2 = sum(b * b for b in vec2) ** 0.5

        if norm1 == 0 or norm2 == 0:
            return 0.0

        return dot_product / (norm1 * norm2)

    def get_evolution_summary(self, session_id: str) -> Dict:
        """
        Get summary of all evolved insights for a session.

        Useful for analytics and debugging.
        """
        if session_id not in self.session_evolutions:
            return {
                'total_insights': 0,
                'evolved_insights': 0,
                'evolution_breakdown': {},
            }

        evolutions = self.session_evolutions[session_id]
        total = len(evolutions)
        evolved = sum(1 for e in evolutions.values() if e.evolution_count > 0)

        # Count evolution types
        evolution_counts = {}
        for evolution in evolutions.values():
            for etype in evolution.evolution_types:
                evolution_counts[etype.value] = evolution_counts.get(etype.value, 0) + 1

        return {
            'total_insights': total,
            'evolved_insights': evolved,
            'evolution_rate': evolved / total if total > 0 else 0.0,
            'evolution_breakdown': evolution_counts,
        }

    def cleanup_session(self, session_id: str):
        """Clean up tracking data for a completed session."""
        if session_id in self.session_evolutions:
            del self.session_evolutions[session_id]

        if session_id in self.insight_embeddings:
            del self.insight_embeddings[session_id]

        logger.info(f"Cleaned up evolution tracking for session {session_id}")


# Singleton instance
_evolution_tracker = None


def get_evolution_tracker() -> InsightEvolutionTracker:
    """Get the singleton InsightEvolutionTracker instance."""
    global _evolution_tracker
    if _evolution_tracker is None:
        _evolution_tracker = InsightEvolutionTracker()
    return _evolution_tracker
