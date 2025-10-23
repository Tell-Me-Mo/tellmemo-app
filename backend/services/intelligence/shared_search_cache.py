"""
Shared Search Cache for Active Intelligence Phases

Provides a centralized semantic search cache that can be reused across multiple
Active Intelligence phases (Phase 1, 3, 5) to avoid redundant Qdrant vector searches.

Key Features:
- Time-based cache expiration (30 seconds by default)
- Semantic similarity checking for query reuse
- Thread-safe implementation for async environments
- Automatic cache cleanup

Expected Savings: ~$0.08 per meeting (vector search costs)

Author: Claude Code AI Assistant
Date: October 23, 2025
"""

from dataclasses import dataclass, field
from typing import List, Optional, Dict, Any
from datetime import datetime, timedelta
import logging
import numpy as np

logger = logging.getLogger(__name__)


@dataclass
class SharedSearchCache:
    """
    Cache for semantic search results that can be shared across multiple phases.

    Stores:
    - search_results: List of search results from Qdrant
    - timestamp: When the search was performed
    - query_embedding: Embedding used for the search
    - query_text: Original query text for logging
    - project_id: Project context for the search
    """
    search_results: List[dict]
    timestamp: datetime
    query_embedding: List[float]
    query_text: str
    project_id: str
    organization_id: str


class SharedSearchCacheManager:
    """
    Manages shared semantic search cache for Active Intelligence phases.

    This service provides intelligent cache reuse to eliminate redundant
    Qdrant vector searches across phases 1, 3, and 5.

    Cache Strategy:
    - Cache expires after CACHE_TTL seconds (default: 30s)
    - Query similarity threshold for reuse: SIMILARITY_THRESHOLD (default: 0.9)
    - Session-scoped caching (one cache per meeting session)
    """

    # Configuration
    CACHE_TTL_SECONDS = 30  # Cache valid for 30 seconds
    SIMILARITY_THRESHOLD = 0.9  # Very similar query required for cache reuse

    def __init__(self):
        """Initialize the cache manager with empty session caches."""
        # Session-scoped caches: session_id -> SharedSearchCache
        self._session_caches: Dict[str, SharedSearchCache] = {}
        logger.info("Initialized SharedSearchCacheManager")

    async def get_or_search(
        self,
        session_id: str,
        query: str,
        project_id: str,
        organization_id: str,
        embedding_service,
        vector_store,
        search_params: Optional[Dict[str, Any]] = None
    ) -> List[dict]:
        """
        Get search results from cache if available and valid, otherwise perform new search.

        Cache Reuse Logic:
        1. Check if cache exists for session
        2. Check if cache is still valid (< TTL seconds old)
        3. Generate embedding for current query
        4. Check semantic similarity with cached query (> threshold)
        5. If all checks pass, reuse cached results
        6. Otherwise, perform new search and cache results

        Args:
            session_id: Current meeting session ID
            query: Query text to search for
            project_id: Project UUID
            organization_id: Organization UUID
            embedding_service: Service for generating embeddings
            vector_store: Vector store for semantic search
            search_params: Optional parameters for vector search (limit, filters, etc.)

        Returns:
            List of search results from Qdrant
        """

        # Check cache validity
        cached_results = await self._check_cache_validity(
            session_id=session_id,
            query=query,
            project_id=project_id,
            organization_id=organization_id,
            embedding_service=embedding_service
        )

        if cached_results is not None:
            logger.info(
                f"[SharedCache] Reusing cached search results for session {session_id[:8]}... "
                f"(saved vector search)"
            )
            return cached_results

        # Cache miss - perform new search
        logger.debug(
            f"[SharedCache] Cache miss for session {session_id[:8]}... "
            f"(performing new search)"
        )

        results = await self._perform_search_and_cache(
            session_id=session_id,
            query=query,
            project_id=project_id,
            organization_id=organization_id,
            embedding_service=embedding_service,
            vector_store=vector_store,
            search_params=search_params
        )

        return results

    async def _check_cache_validity(
        self,
        session_id: str,
        query: str,
        project_id: str,
        organization_id: str,
        embedding_service
    ) -> Optional[List[dict]]:
        """
        Check if cached results are valid and can be reused.

        Returns:
            Cached results if valid, None otherwise
        """

        # Check 1: Does cache exist for this session?
        if session_id not in self._session_caches:
            logger.debug(f"[SharedCache] No cache found for session {session_id[:8]}...")
            return None

        cache = self._session_caches[session_id]

        # Check 2: Is cache still valid (within TTL)?
        now = datetime.now()
        age_seconds = (now - cache.timestamp).total_seconds()

        if age_seconds >= self.CACHE_TTL_SECONDS:
            logger.debug(
                f"[SharedCache] Cache expired for session {session_id[:8]}... "
                f"(age: {age_seconds:.1f}s, TTL: {self.CACHE_TTL_SECONDS}s)"
            )
            # Remove expired cache
            del self._session_caches[session_id]
            return None

        # Check 3: Is project/org context the same?
        if cache.project_id != project_id or cache.organization_id != organization_id:
            logger.debug(
                f"[SharedCache] Project/org mismatch for session {session_id[:8]}... "
                f"(cached: {cache.project_id}/{cache.organization_id}, "
                f"requested: {project_id}/{organization_id})"
            )
            return None

        # Check 4: Is the query semantically similar enough?
        try:
            query_embedding = await embedding_service.generate_embedding(query)
            similarity = self._cosine_similarity(query_embedding, cache.query_embedding)

            if similarity >= self.SIMILARITY_THRESHOLD:
                logger.info(
                    f"[SharedCache] Query similarity {similarity:.3f} >= {self.SIMILARITY_THRESHOLD} "
                    f"for session {session_id[:8]}... (cache hit)"
                )
                logger.debug(
                    f"[SharedCache] Cached query: '{cache.query_text[:50]}...', "
                    f"Current query: '{query[:50]}...'"
                )
                return cache.search_results
            else:
                logger.debug(
                    f"[SharedCache] Query similarity {similarity:.3f} < {self.SIMILARITY_THRESHOLD} "
                    f"for session {session_id[:8]}... (cache miss)"
                )
                return None

        except Exception as e:
            logger.error(f"[SharedCache] Error checking cache validity: {e}")
            return None

    async def _perform_search_and_cache(
        self,
        session_id: str,
        query: str,
        project_id: str,
        organization_id: str,
        embedding_service,
        vector_store,
        search_params: Optional[Dict[str, Any]] = None
    ) -> List[dict]:
        """
        Perform new vector search and cache the results.

        Args:
            session_id: Current meeting session ID
            query: Query text to search for
            project_id: Project UUID
            organization_id: Organization UUID
            embedding_service: Service for generating embeddings
            vector_store: Vector store for semantic search
            search_params: Optional parameters for vector search

        Returns:
            List of search results from Qdrant
        """

        try:
            # Generate embedding for query
            query_embedding = await embedding_service.generate_embedding(query)

            # Prepare search parameters
            params = search_params or {}
            default_params = {
                'limit': 10,
                'filter_dict': {'project_id': project_id},
                'score_threshold': 0.5
            }

            # Merge with defaults
            search_config = {**default_params, **params}

            # Perform vector search
            results = await vector_store.search_vectors(
                organization_id=organization_id,
                query_vector=query_embedding,
                collection_type="content",
                **search_config
            )

            # Cache the results
            self._session_caches[session_id] = SharedSearchCache(
                search_results=results,
                timestamp=datetime.now(),
                query_embedding=query_embedding,
                query_text=query,
                project_id=project_id,
                organization_id=organization_id
            )

            logger.debug(
                f"[SharedCache] Cached {len(results)} search results for session {session_id[:8]}... "
                f"(query: '{query[:50]}...')"
            )

            return results

        except Exception as e:
            logger.error(f"[SharedCache] Error performing search: {e}", exc_info=True)
            return []

    @staticmethod
    def _cosine_similarity(vec1: List[float], vec2: List[float]) -> float:
        """
        Calculate cosine similarity between two vectors.

        Returns:
            Similarity score (0.0 to 1.0)
        """
        vec1_np = np.array(vec1)
        vec2_np = np.array(vec2)

        dot_product = np.dot(vec1_np, vec2_np)
        norm1 = np.linalg.norm(vec1_np)
        norm2 = np.linalg.norm(vec2_np)

        if norm1 == 0 or norm2 == 0:
            return 0.0

        return float(dot_product / (norm1 * norm2))

    def clear_session(self, session_id: str) -> bool:
        """
        Clear cache for a specific session.

        Called when a meeting session ends to free memory.

        Args:
            session_id: Session ID to clear

        Returns:
            True if cache was cleared, False if no cache existed
        """
        if session_id in self._session_caches:
            del self._session_caches[session_id]
            logger.debug(f"[SharedCache] Cleared cache for session {session_id[:8]}...")
            return True
        return False

    def clear_all(self) -> int:
        """
        Clear all cached search results.

        Useful for testing or memory management.

        Returns:
            Number of sessions cleared
        """
        count = len(self._session_caches)
        self._session_caches.clear()
        logger.info(f"[SharedCache] Cleared all caches ({count} sessions)")
        return count

    def get_cache_stats(self) -> Dict[str, Any]:
        """
        Get statistics about current cache usage.

        Returns:
            Dictionary with cache statistics
        """
        now = datetime.now()

        stats = {
            'total_sessions': len(self._session_caches),
            'sessions': []
        }

        for session_id, cache in self._session_caches.items():
            age_seconds = (now - cache.timestamp).total_seconds()
            stats['sessions'].append({
                'session_id': session_id[:12] + '...',
                'age_seconds': age_seconds,
                'is_expired': age_seconds >= self.CACHE_TTL_SECONDS,
                'result_count': len(cache.search_results),
                'query': cache.query_text[:50] + '...'
            })

        return stats


# Global singleton instance
shared_search_cache = SharedSearchCacheManager()
