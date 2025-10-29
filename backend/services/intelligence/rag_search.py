"""RAG Search Service for Tier 1 Answer Discovery.

Provides streaming semantic search across organization documents
for real-time question answering during meetings.
"""

import asyncio
from datetime import datetime
from typing import AsyncGenerator, Dict, List, Optional, Any
from uuid import UUID

from services.rag.enhanced_rag_service_refactored import enhanced_rag_service, RAGStrategy
from services.rag.embedding_service import embedding_service
from db.multi_tenant_vector_store import multi_tenant_vector_store
from utils.logger import get_logger, sanitize_for_log

logger = get_logger(__name__)


class RAGSearchResult:
    """Container for a single RAG search result."""

    def __init__(
        self,
        document_id: str,
        title: str,
        content: str,
        relevance_score: float,
        url: Optional[str] = None,
        last_updated: Optional[datetime] = None,
        metadata: Optional[Dict[str, Any]] = None
    ):
        """Initialize RAG search result.

        Args:
            document_id: Unique document identifier
            title: Document title
            content: Relevant content excerpt
            relevance_score: Relevance score (0.0-1.0)
            url: Document URL if available
            last_updated: Last update timestamp
            metadata: Additional document metadata
        """
        self.document_id = document_id
        self.title = title
        self.content = content
        self.relevance_score = relevance_score
        self.url = url
        self.last_updated = last_updated
        self.metadata = metadata or {}

    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary for serialization."""
        return {
            "document_id": self.document_id,
            "title": self.title,
            "content": self.content,
            "relevance_score": self.relevance_score,
            "url": self.url,
            "last_updated": self.last_updated.isoformat() if self.last_updated else None,
            "metadata": self.metadata
        }


class RAGSearchService:
    """Service for searching organization's document repository.

    Implements Tier 1 of the four-tier answer discovery system.
    Provides streaming results for progressive UI updates.
    """

    def __init__(
        self,
        timeout: float = 2.0,
        max_results: int = 5,
        score_threshold: float = 0.3,
        use_mrl_search: bool = True
    ):
        """Initialize RAG search service.

        Args:
            timeout: Maximum search time in seconds (default: 2.0)
            max_results: Maximum number of results to return (default: 5)
            score_threshold: Minimum relevance score threshold (default: 0.3)
            use_mrl_search: Use MRL two-stage search for better quality (default: True)
        """
        self.timeout = timeout
        self.max_results = max_results
        self.score_threshold = score_threshold
        self.use_mrl_search = use_mrl_search

    async def search(
        self,
        question: str,
        project_id: str,
        organization_id: str,
        streaming: bool = True
    ) -> AsyncGenerator[RAGSearchResult, None]:
        """Search organization documents for relevant answers.

        Args:
            question: The question text to search for
            project_id: Project UUID string
            organization_id: Organization UUID string
            streaming: If True, yield results as found; if False, yield all at end

        Yields:
            RAGSearchResult objects as they are found

        Raises:
            asyncio.TimeoutError: If search exceeds timeout
        """
        try:
            logger.debug(
                f"Starting RAG search for project {sanitize_for_log(project_id)}: "
                f"{sanitize_for_log(question[:100])}"
            )

            # Execute search with timeout using asyncio.wait_for on the entire generator iteration
            start_time = asyncio.get_event_loop().time()

            try:
                async for result in self._execute_search(question, project_id, organization_id, streaming):
                    # Check if we've exceeded timeout
                    elapsed = asyncio.get_event_loop().time() - start_time
                    if elapsed > self.timeout:
                        logger.warning(
                            f"RAG search timeout ({self.timeout}s) for project {project_id} "
                            f"after {elapsed:.2f}s"
                        )
                        return

                    yield result

            except asyncio.TimeoutError:
                logger.warning(f"RAG search timeout ({self.timeout}s) for project {project_id}")
                return

        except Exception as e:
            logger.error(
                f"RAG search failed for project {project_id}: {e}",
                exc_info=True
            )
            # Continue execution - graceful degradation

    async def _execute_search(
        self,
        question: str,
        project_id: str,
        organization_id: str,
        streaming: bool
    ) -> AsyncGenerator[RAGSearchResult, None]:
        """Execute the actual search against vector store.

        Args:
            question: Question text
            project_id: Project UUID string
            organization_id: Organization UUID string
            streaming: Whether to stream results progressively

        Yields:
            RAGSearchResult objects
        """
        try:
            # Strategy 1: Use enhanced RAG service (full pipeline with LLM)
            # This provides context-aware answers, not just document chunks
            rag_result = await enhanced_rag_service.query_project(
                project_id=project_id,
                question=question,
                strategy=RAGStrategy.BASIC,  # Use BASIC for speed (2s constraint)
                organization_id=organization_id
            )

            # Extract sources from RAG result
            sources = rag_result.get("sources", [])
            answer = rag_result.get("answer", "")
            confidence = rag_result.get("confidence", 0.0)

            if sources:
                logger.info(f"Found {len(sources)} RAG sources for question")

                # Convert sources to RAGSearchResult objects
                for idx, source in enumerate(sources[:self.max_results]):
                    result = self._convert_source_to_result(source, idx)
                    if result and result.relevance_score >= self.score_threshold:
                        if streaming:
                            yield result
                            # Small delay between results for progressive UI updates
                            await asyncio.sleep(0.05)
                        else:
                            yield result

            # If enhanced RAG didn't find anything, try direct vector search
            if not sources:
                logger.debug("Enhanced RAG returned no sources, trying direct vector search")
                async for result in self._direct_vector_search(
                    question, project_id, organization_id, streaming
                ):
                    yield result

        except Exception as e:
            logger.error(f"Error executing RAG search: {e}", exc_info=True)
            # Try fallback to direct vector search
            try:
                async for result in self._direct_vector_search(
                    question, project_id, organization_id, streaming
                ):
                    yield result
            except Exception as fallback_error:
                logger.error(f"Fallback vector search also failed: {fallback_error}")

    async def _direct_vector_search(
        self,
        question: str,
        project_id: str,
        organization_id: str,
        streaming: bool
    ) -> AsyncGenerator[RAGSearchResult, None]:
        """Direct vector similarity search without LLM processing.

        Fallback method when enhanced RAG fails or returns no results.

        Args:
            question: Question text
            project_id: Project UUID string
            organization_id: Organization UUID string
            streaming: Whether to stream results

        Yields:
            RAGSearchResult objects
        """
        try:
            # Generate query embedding
            query_embedding = await embedding_service.generate_embedding(question)

            if not query_embedding:
                logger.warning("Failed to generate query embedding")
                return

            # Perform vector search
            if self.use_mrl_search:
                # Two-stage MRL search for better quality
                search_results = await multi_tenant_vector_store.search_vectors_two_stage(
                    organization_id=organization_id,
                    query_vector=query_embedding,
                    initial_limit=self.max_results * 3,  # 3x candidates for stage 1
                    final_limit=self.max_results,
                    score_threshold=self.score_threshold,
                    filter_dict={"project_id": project_id}
                )
            else:
                # Standard vector search
                search_results = await multi_tenant_vector_store.search_vectors(
                    organization_id=organization_id,
                    query_vector=query_embedding,
                    limit=self.max_results,
                    score_threshold=self.score_threshold,
                    filter_dict={"project_id": project_id}
                )

            # Convert vector results to RAGSearchResult objects
            for idx, vec_result in enumerate(search_results):
                result = self._convert_vector_result_to_search_result(vec_result, idx)
                if result:
                    if streaming:
                        yield result
                        await asyncio.sleep(0.05)
                    else:
                        yield result

        except Exception as e:
            logger.error(f"Direct vector search failed: {e}", exc_info=True)

    def _convert_source_to_result(
        self,
        source: Dict[str, Any],
        index: int
    ) -> Optional[RAGSearchResult]:
        """Convert enhanced RAG source to RAGSearchResult.

        Args:
            source: Source dictionary from enhanced_rag_service
            index: Result index (for ordering)

        Returns:
            RAGSearchResult or None if conversion fails
        """
        try:
            return RAGSearchResult(
                document_id=source.get("content_id", f"doc_{index}"),
                title=source.get("title", "Untitled Document"),
                content=source.get("content", ""),
                relevance_score=source.get("score", 0.0),
                url=source.get("url"),
                last_updated=None,  # Not typically available in sources
                metadata={
                    "chunk_index": source.get("chunk_index"),
                    "content_type": source.get("content_type"),
                    "date": source.get("date"),
                    "project_id": source.get("project_id")
                }
            )
        except Exception as e:
            logger.warning(f"Failed to convert source to result: {e}")
            return None

    def _convert_vector_result_to_search_result(
        self,
        vec_result: Any,
        index: int
    ) -> Optional[RAGSearchResult]:
        """Convert Qdrant vector result to RAGSearchResult.

        Args:
            vec_result: Vector search result from Qdrant
            index: Result index (for ordering)

        Returns:
            RAGSearchResult or None if conversion fails
        """
        try:
            payload = vec_result.payload if hasattr(vec_result, 'payload') else {}
            score = vec_result.score if hasattr(vec_result, 'score') else 0.0

            return RAGSearchResult(
                document_id=str(payload.get("content_id", f"vec_{index}")),
                title=payload.get("title", "Untitled Document"),
                content=payload.get("content", ""),
                relevance_score=float(score),
                url=payload.get("url"),
                last_updated=None,
                metadata={
                    "chunk_index": payload.get("chunk_index"),
                    "content_type": payload.get("content_type"),
                    "date": payload.get("date"),
                    "project_id": payload.get("project_id"),
                    "organization_id": payload.get("organization_id")
                }
            )
        except Exception as e:
            logger.warning(f"Failed to convert vector result to search result: {e}")
            return None

    async def search_and_collect(
        self,
        question: str,
        project_id: str,
        organization_id: str
    ) -> List[RAGSearchResult]:
        """Convenience method to collect all search results in a list.

        Args:
            question: The question text
            project_id: Project UUID string
            organization_id: Organization UUID string

        Returns:
            List of RAGSearchResult objects
        """
        results = []
        async for result in self.search(
            question=question,
            project_id=project_id,
            organization_id=organization_id,
            streaming=False
        ):
            results.append(result)
        return results

    def is_available(self) -> bool:
        """Check if RAG search service is available.

        Returns:
            True if vector store and embedding service are available
        """
        try:
            # Check if vector store client is initialized
            if not hasattr(multi_tenant_vector_store, '_client'):
                logger.debug("Vector store client not initialized")
                return False

            # Verify client is not None
            if multi_tenant_vector_store._client is None:
                logger.debug("Vector store client is None")
                return False

            # Check if embedding service is available
            # EmbeddingService uses _model (private attribute) not model
            if not hasattr(embedding_service, '_model'):
                logger.debug("Embedding service model not initialized")
                return False

            # Verify model is not None
            if embedding_service._model is None:
                logger.debug("Embedding service model is None")
                return False

            logger.debug("RAG service is available")
            return True
        except Exception as e:
            logger.warning(f"Error checking RAG availability: {e}")
            return False


# Global service instance
rag_search_service = RAGSearchService(
    timeout=2.0,
    max_results=5,
    score_threshold=0.3,
    use_mrl_search=True
)
