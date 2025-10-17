"""Hybrid Search & Re-ranking Service combining semantic and keyword search."""

import re
import math
import asyncio
from typing import List, Dict, Any, Optional, Tuple, Set
from dataclasses import dataclass, field
from collections import defaultdict, Counter
from enum import Enum
import json

from sentence_transformers import SentenceTransformer, CrossEncoder

from utils.logger import get_logger, sanitize_for_log
from services.rag.embedding_service import embedding_service
from services.rag.multi_query_retrieval import (
    MultiQueryResults, RetrievalResult, QueryAnalysis, QueryIntent,
    multi_query_retrieval_service
)
from db.multi_tenant_vector_store import multi_tenant_vector_store
from models.project import Project

logger = get_logger(__name__)


class SearchType(Enum):
    """Types of search methods."""
    SEMANTIC = "semantic"
    KEYWORD = "keyword" 
    HYBRID = "hybrid"
    CROSS_ENCODED = "cross_encoded"


@dataclass
class SearchResult:
    """Enhanced search result with multiple scoring methods."""
    chunk_id: str
    text: str
    metadata: Dict[str, Any]
    
    # Scoring components
    semantic_score: float = 0.0
    keyword_score: float = 0.0
    hybrid_score: float = 0.0
    cross_encoder_score: Optional[float] = None
    final_score: float = 0.0
    
    # Analysis components
    search_types: List[SearchType] = field(default_factory=list)
    matched_keywords: List[str] = field(default_factory=list)
    keyword_positions: List[int] = field(default_factory=list)
    
    # Quality indicators
    relevance_indicators: Dict[str, float] = field(default_factory=dict)
    confidence_score: float = 0.0
    source_diversity: float = 0.0


@dataclass
class HybridSearchConfig:
    """Configuration for hybrid search - optimized for meeting transcripts."""
    # Semantic search parameters
    semantic_weight: float = 0.45  # Reduced from 0.6 for better keyword matching
    semantic_threshold: float = 0.1

    # Keyword search parameters
    keyword_weight: float = 0.55  # Increased from 0.4 for better exact matches
    bm25_k1: float = 1.2  # Reduced from 1.5 for less term frequency saturation
    bm25_b: float = 0.5  # Reduced from 0.75 for consistent-length transcripts

    # Cross-encoder parameters
    cross_encoder_weight: float = 0.5  # Increased from 0.3 for better relevance
    cross_encoder_threshold: float = 0.5

    # Result optimization
    max_results_per_method: int = 30  # Increased from 20 for better candidate pool
    final_result_count: int = 15
    diversity_boost: float = 0.1

    # Diversity optimization
    diversity_similarity_threshold: float = 0.85  # Results with similarity > this are considered duplicates

    # Quality filters
    min_confidence_score: float = 0.3
    filter_low_quality: bool = True


@dataclass
class SearchPipeline:
    """Multi-stage search pipeline results."""
    query: str
    config: HybridSearchConfig
    
    # Stage results
    semantic_results: List[SearchResult]
    keyword_results: List[SearchResult]
    merged_results: List[SearchResult]
    cross_encoded_results: List[SearchResult]
    final_results: List[SearchResult]
    
    # Pipeline metrics
    semantic_result_count: int = 0
    keyword_result_count: int = 0
    overlap_count: int = 0
    diversity_score: float = 0.0
    confidence_distribution: Dict[str, int] = field(default_factory=dict)
    processing_time_ms: int = 0


class HybridSearchService:
    """Advanced hybrid search combining semantic, keyword, and cross-encoder approaches."""
    
    def __init__(self, config: Optional[HybridSearchConfig] = None):
        """Initialize hybrid search service with MRL optimization."""
        from config import get_settings
        self.settings = get_settings()
        self.config = config or HybridSearchConfig()

        # MRL configuration for multi-stage search
        self.use_mrl_search = self.settings.enable_mrl
        self.search_dimension = self.settings.mrl_search_dimension  # 128d for fast search
        self.rerank_dimension = self.settings.mrl_rerank_dimension  # 768d for accurate rerank
        
        # Models for different search approaches
        self.sentence_transformer = None
        self.cross_encoder = None
        
        # Keyword search components
        self.document_frequencies = {}
        self.total_documents = 0
        self.document_lengths = {}
        self.average_document_length = 0.0
        
        # Search quality components
        self.quality_indicators = {
            'title_match': 2.0,
            'exact_phrase_match': 1.8,
            'keyword_density': 1.5,
            'position_bonus': 1.3,
            'content_type_match': 1.2
        }
        
        # Initialize models
        self._initialize_models()
    
    def _initialize_models(self):
        """Initialize ML models for hybrid search."""
        try:
            # Load sentence transformer for semantic search
            try:
                self.sentence_transformer = SentenceTransformer(self.settings.sentence_transformer_model)
                logger.info("Loaded SentenceTransformer for hybrid search")
            except Exception as e:
                logger.warning(f"Failed to load SentenceTransformer: {e}")

            # Load cross-encoder for re-ranking
            try:
                self.cross_encoder = CrossEncoder('cross-encoder/ms-marco-MiniLM-L-2-v2')
                logger.info("Loaded CrossEncoder for result re-ranking")
            except Exception as e:
                logger.warning(f"Failed to load CrossEncoder: {e}")
                self.cross_encoder = None

        except Exception as e:
            logger.error(f"Failed to initialize hybrid search models: {e}")
    
    async def hybrid_search(
        self,
        query: str,
        project_id: str,
        config: Optional[HybridSearchConfig] = None
    ) -> SearchPipeline:
        """
        Perform hybrid search combining multiple approaches.
        
        Args:
            query: Search query
            project_id: Project ID for filtering
            config: Optional search configuration
            
        Returns:
            SearchPipeline with comprehensive search results
        """
        import time
        start_time = time.time()
        
        if config:
            self.config = config
        
        logger.info(f"Starting hybrid search for: '{sanitize_for_log(query)}'")
        
        try:
            # Stage 1: Semantic search
            logger.debug("Stage 1: Performing semantic search")
            semantic_results = await self._semantic_search(query, project_id)
            
            # Stage 2: Keyword search (BM25)
            logger.debug("Stage 2: Performing keyword search")
            keyword_results = await self._keyword_search(query, project_id)
            
            # Stage 3: Merge and deduplicate results
            logger.debug("Stage 3: Merging results")
            merged_results = await self._merge_results(
                semantic_results, keyword_results, query
            )
            
            # Stage 4: Cross-encoder re-ranking
            logger.debug("Stage 4: Cross-encoder re-ranking")
            cross_encoded_results = await self._cross_encoder_rerank(
                merged_results, query
            )
            
            # Stage 5: Final optimization and diversity
            logger.debug("Stage 5: Final optimization")
            final_results = await self._optimize_final_results(
                cross_encoded_results, query
            )
            
            # Calculate pipeline metrics
            processing_time = int((time.time() - start_time) * 1000)
            diversity_score = await self._calculate_diversity_score(final_results)
            pipeline = SearchPipeline(
                query=query,
                config=self.config,
                semantic_results=semantic_results,
                keyword_results=keyword_results,
                merged_results=merged_results,
                cross_encoded_results=cross_encoded_results,
                final_results=final_results,
                semantic_result_count=len(semantic_results),
                keyword_result_count=len(keyword_results),
                overlap_count=self._calculate_overlap(semantic_results, keyword_results),
                diversity_score=diversity_score,
                confidence_distribution=self._calculate_confidence_distribution(final_results),
                processing_time_ms=processing_time
            )
            
            logger.info(f"Hybrid search completed in {processing_time}ms: "
                       f"{len(final_results)} final results, "
                       f"diversity: {pipeline.diversity_score:.2f}")
            
            self._log_search_statistics(pipeline)
            
            return pipeline
            
        except Exception as e:
            logger.error(f"Hybrid search failed: {e}")
            # Fallback to semantic search only
            return await self._fallback_search(query, project_id)
    
    async def _semantic_search(self, query: str, project_id: str) -> List[SearchResult]:
        """Perform semantic vector search with MRL optimization."""
        try:
            # Validate query length to prevent embedding errors
            if len(query) > 2000:
                logger.warning(f"Query too long ({len(query)} chars), truncating for search")
                query = query[:2000] + "..."

            if self.use_mrl_search:
                # Multi-stage search with MRL
                return await self._semantic_search_mrl(query, project_id)
            else:
                # Standard semantic search
                return await self._semantic_search_standard(query, project_id)

        except Exception as e:
            logger.error(f"Semantic search failed: {e}")
            return []

    async def _semantic_search_mrl(self, query: str, project_id: str) -> List[SearchResult]:
        """
        Multi-stage semantic search using MRL:
        1. Fast filtering with 128d embeddings
        2. Accurate reranking with 768d embeddings
        """
        from services.rag.embedding_service import embedding_service

        # Get organization_id from project_id
        organization_id = await self._get_organization_id(project_id)
        if not organization_id:
            logger.error(f"Could not determine organization for project {sanitize_for_log(project_id)}")
            return []

        # Generate query embeddings at different dimensions
        query_embeddings = await embedding_service.generate_search_embeddings(query)

        # Stage 1: Fast filtering with 128d (get 3x candidates)
        fast_candidates = await multi_tenant_vector_store.search_vectors(
            organization_id=organization_id,
            query_vector=query_embeddings['search'],  # 128d
            limit=self.config.max_results_per_method * 3,
            score_threshold=self.config.semantic_threshold,
            filter_dict={"project_id": project_id}
        )

        if not fast_candidates:
            return []

        # Stage 2: Accurate reranking with 768d
        reranked_results = []
        for candidate in fast_candidates:
            # Calculate precise similarity with full embeddings
            chunk_embedding_768 = candidate.get('embedding_768', candidate.get('embedding', []))
            if chunk_embedding_768:
                precise_score = embedding_service.calculate_similarity(
                    query_embeddings['rerank'],  # 768d
                    chunk_embedding_768
                )
            else:
                precise_score = candidate['score']

            # Extract text from payload
            payload = candidate.get('payload', {})
            text = payload.get('text', payload.get('content', ''))

            search_result = SearchResult(
                chunk_id=candidate['id'],
                text=text,
                metadata=payload,
                semantic_score=precise_score,
                search_types=[SearchType.SEMANTIC],
                relevance_indicators=['mrl_optimized'],
                confidence_score=precise_score
            )
            reranked_results.append(search_result)

        # Sort by precise scores and return top results
        reranked_results.sort(key=lambda x: x.semantic_score, reverse=True)
        results = reranked_results[:self.config.max_results_per_method]

        logger.debug(f"MRL semantic search: {len(fast_candidates)} candidates → {len(results)} results")
        return results

    async def _semantic_search_standard(self, query: str, project_id: str) -> List[SearchResult]:
        """Standard semantic search without MRL optimization."""
        # Use multi-query retrieval for expanded semantic search
        multi_query_results = await multi_query_retrieval_service.retrieve_with_multi_query(
            query, project_id, self.config.max_results_per_method
        )

        # Convert to SearchResult format
        search_results = []
        for result in multi_query_results.deduplicated_results:
            search_result = SearchResult(
                chunk_id=result.chunk_id,
                text=result.text,
                metadata=result.metadata,
                semantic_score=result.score,
                search_types=[SearchType.SEMANTIC],
                relevance_indicators=result.relevance_factors,
                confidence_score=result.score
            )
            search_results.append(search_result)

        logger.debug(f"Standard semantic search retrieved {len(search_results)} results")
        return search_results[:self.config.max_results_per_method]
    
    async def _keyword_search(self, query: str, project_id: str) -> List[SearchResult]:
        """Perform keyword-based search using BM25 scoring."""
        try:
            # Get all documents for the project (this is a simplified approach)
            # In a real implementation, you'd have a proper inverted index
            all_results = await self._get_all_project_documents(project_id)
            
            if not all_results:
                logger.warning("No documents found for keyword search")
                return []
            
            # Update document statistics
            await self._update_document_statistics(all_results)
            
            # Calculate BM25 scores for query
            query_terms = self._tokenize_query(query)
            scored_results = []
            
            for doc in all_results:
                # Get text from payload - handle both direct text field and nested structure
                payload = doc.get('payload', {})
                doc_text = payload.get('text', '') or payload.get('content', '')

                if not doc_text:
                    continue

                bm25_score = self._calculate_bm25_score(query_terms, doc_text)

                if bm25_score > 0:  # Only include documents with some relevance
                    # Find matched keywords and positions
                    matched_keywords, positions = self._find_matched_keywords(
                        query_terms, doc_text
                    )

                    search_result = SearchResult(
                        chunk_id=doc.get('id', ''),
                        text=doc_text,
                        metadata=payload,
                        keyword_score=bm25_score,
                        search_types=[SearchType.KEYWORD],
                        matched_keywords=matched_keywords,
                        keyword_positions=positions,
                        confidence_score=min(bm25_score, 1.0)
                    )
                    scored_results.append(search_result)
            
            # Sort by BM25 score
            scored_results.sort(key=lambda x: x.keyword_score, reverse=True)
            
            logger.debug(f"Keyword search retrieved {len(scored_results)} results")
            return scored_results[:self.config.max_results_per_method]
            
        except Exception as e:
            logger.error(f"Keyword search failed: {e}")
            return []
    
    async def _get_organization_id(self, project_id: str) -> Optional[str]:
        """Get organization_id from project_id using cached enhanced RAG service."""
        try:
            # Use the cached organization lookup from enhanced RAG service
            from services.rag.enhanced_rag_service_refactored import enhanced_rag_service
            org_id = await enhanced_rag_service._get_organization_id(project_id)
            logger.debug(f"Hybrid search organization lookup: project_id={sanitize_for_log(project_id)} -> organization_id={sanitize_for_log(org_id)}")
            return org_id
        except Exception as e:
            logger.error(f"Failed to get organization_id for project {sanitize_for_log(project_id)}: {e}")
            return None

    async def _get_all_project_documents(self, project_id: str) -> List[Dict[str, Any]]:
        """Get all documents for BM25 calculation using scroll API."""
        try:
            # Get organization_id from project_id
            organization_id = await self._get_organization_id(project_id)
            if not organization_id:
                logger.error(f"Could not determine organization for project {sanitize_for_log(project_id)}")
                return []

            # Use scroll API to fetch documents without vector similarity
            results = await multi_tenant_vector_store.scroll_documents(
                organization_id=organization_id,
                collection_type="content",
                filter_dict={"project_id": project_id},
                limit=1000,  # Get many documents for BM25
                with_payload=True,
                with_vectors=False  # Don't need vectors for keyword search
            )

            logger.debug(f"Retrieved {sanitize_for_log(len(results))} documents for keyword search from project {sanitize_for_log(project_id)}")
            return results

        except Exception as e:
            logger.error(f"Failed to get project documents: {e}")
            return []
    
    def _tokenize_query(self, query: str) -> List[str]:
        """Tokenize query for keyword matching."""
        # Remove common noise prefixes
        noise_prefixes = ['regarding', 'about', 're:', 'subject:']
        query_lower = query.lower()
        for prefix in noise_prefixes:
            if query_lower.startswith(prefix):
                query = query[len(prefix):].strip()
                if query.startswith('-'):
                    query = query[1:].strip()
                break

        # Clean and tokenize query
        cleaned = re.sub(r'[^\w\s]', ' ', query.lower())
        tokens = cleaned.split()

        # Extended stop words including common noise words
        stop_words = {
            'a', 'an', 'and', 'are', 'as', 'at', 'be', 'by', 'for', 'from',
            'has', 'he', 'in', 'is', 'it', 'its', 'of', 'on', 'that', 'the',
            'to', 'was', 'will', 'with', 'what', 'when', 'where', 'who', 'how',
            'regarding', 'about', 're', 'subject'
        }

        return [token for token in tokens if token not in stop_words and len(token) > 2]
    
    def _calculate_bm25_score(self, query_terms: List[str], document: str) -> float:
        """Calculate BM25 score for document given query terms."""
        if not query_terms or not document:
            return 0.0
        
        doc_tokens = self._tokenize_query(document)
        doc_length = len(doc_tokens)
        
        if doc_length == 0:
            return 0.0
        
        # Calculate term frequencies in document
        doc_term_freq = Counter(doc_tokens)
        
        score = 0.0
        for term in query_terms:
            if term in doc_term_freq:
                # Term frequency in document
                tf = doc_term_freq[term]
                
                # Document frequency for term (simplified - would need proper index)
                df = self.document_frequencies.get(term, 1)
                
                # IDF calculation
                idf = math.log((self.total_documents + 1) / (df + 1))
                
                # BM25 formula
                numerator = tf * (self.config.bm25_k1 + 1)
                denominator = (
                    tf + self.config.bm25_k1 * (
                        1 - self.config.bm25_b + 
                        self.config.bm25_b * (doc_length / self.average_document_length)
                    )
                )
                
                score += idf * (numerator / denominator)
        
        return score
    
    async def _update_document_statistics(self, documents: List[Dict[str, Any]]):
        """Update document statistics for BM25 calculation."""
        self.total_documents = len(documents)
        self.document_frequencies.clear()
        
        doc_lengths = []
        all_terms = set()
        
        for doc in documents:
            text = doc.get('payload', {}).get('text', '')
            tokens = self._tokenize_query(text)
            doc_lengths.append(len(tokens))
            
            # Count term occurrences across documents
            unique_terms = set(tokens)
            all_terms.update(unique_terms)
            
            for term in unique_terms:
                self.document_frequencies[term] = self.document_frequencies.get(term, 0) + 1
        
        # Calculate average document length
        self.average_document_length = sum(doc_lengths) / len(doc_lengths) if doc_lengths else 0
        
        logger.debug(f"Updated statistics: {self.total_documents} docs, "
                    f"avg length: {self.average_document_length:.1f}")
    
    def _find_matched_keywords(
        self, 
        query_terms: List[str], 
        text: str
    ) -> Tuple[List[str], List[int]]:
        """Find matched keywords and their positions in text."""
        text_lower = text.lower()
        matched_keywords = []
        positions = []
        
        for term in query_terms:
            if term in text_lower:
                matched_keywords.append(term)
                # Find all positions of the term
                start = 0
                while True:
                    pos = text_lower.find(term, start)
                    if pos == -1:
                        break
                    positions.append(pos)
                    start = pos + 1
        
        return matched_keywords, positions
    
    async def _merge_results(
        self,
        semantic_results: List[SearchResult],
        keyword_results: List[SearchResult],
        query: str
    ) -> List[SearchResult]:
        """Merge and deduplicate results from different search methods."""
        # Create lookup for existing results
        result_map = {}
        
        # Add semantic results
        for result in semantic_results:
            result_map[result.chunk_id] = result
        
        # Merge keyword results
        for kw_result in keyword_results:
            if kw_result.chunk_id in result_map:
                # Merge with existing result
                existing = result_map[kw_result.chunk_id]
                existing.keyword_score = kw_result.keyword_score
                existing.matched_keywords = kw_result.matched_keywords
                existing.keyword_positions = kw_result.keyword_positions
                existing.search_types.append(SearchType.KEYWORD)
                
                # Update confidence based on multiple signals
                existing.confidence_score = max(
                    existing.confidence_score,
                    kw_result.confidence_score
                )
            else:
                # Add new keyword-only result
                result_map[kw_result.chunk_id] = kw_result
        
        # Calculate hybrid scores
        merged_results = []
        for result in result_map.values():
            # Calculate hybrid score
            result.hybrid_score = (
                result.semantic_score * self.config.semantic_weight +
                result.keyword_score * self.config.keyword_weight
            )
            
            # Add quality bonuses
            quality_bonus = self._calculate_quality_bonus(result, query)
            result.hybrid_score *= (1.0 + quality_bonus)
            
            result.search_types.append(SearchType.HYBRID)
            merged_results.append(result)
        
        # Sort by hybrid score
        merged_results.sort(key=lambda x: x.hybrid_score, reverse=True)
        
        logger.debug(f"Merged to {len(merged_results)} unique results")
        return merged_results
    
    def _calculate_quality_bonus(self, result: SearchResult, query: str) -> float:
        """Calculate quality bonus based on various factors - optimized for meeting transcripts."""
        bonus = 0.0
        text_lower = result.text.lower()
        query_lower = query.lower()

        # Title/metadata match bonus (reduced from 0.2)
        title = result.metadata.get('title', '').lower()
        if any(word in title for word in query_lower.split()):
            bonus += 0.1

        # Exact phrase match bonus (reduced from 0.15)
        if query_lower in text_lower:
            bonus += 0.08

        # Keyword density bonus (reduced from 0.1)
        query_words = query_lower.split()
        matched_words = sum(1 for word in query_words if word in text_lower)
        if query_words:
            density = matched_words / len(query_words)
            bonus += density * 0.05

        # Position bonus (reduced from 0.1)
        if result.keyword_positions:
            avg_position = sum(result.keyword_positions) / len(result.keyword_positions)
            text_length = len(result.text)
            if text_length > 0:
                position_factor = 1.0 - (avg_position / text_length)
                bonus += position_factor * 0.05

        # Content type bonus for meeting-specific content
        content_type = result.metadata.get('content_type', '').lower()
        if content_type in ['meeting', 'decision', 'action_item']:
            bonus += 0.08
        elif content_type in ['summary']:
            bonus += 0.05

        # Meeting-specific bonuses

        # Speaker attribution bonus (new) - important for "who said what"
        if ':' in text_lower and any(word in query_lower for word in ['who', 'said', 'mentioned', 'suggested']):
            # Check if text contains speaker patterns
            speaker_pattern = r'\b[A-Z][a-z]+(?:\s+[A-Z][a-z]+)?:'
            import re
            if re.search(speaker_pattern, result.text):
                bonus += 0.06

        # Temporal reference bonus (new) - for time-related queries
        temporal_words = ['yesterday', 'today', 'tomorrow', 'monday', 'tuesday', 'wednesday',
                         'thursday', 'friday', 'next week', 'last week', 'deadline', 'due date']
        if any(word in query_lower for word in temporal_words):
            if any(word in text_lower for word in temporal_words):
                bonus += 0.05

        # Action/decision keywords bonus (new) - for actionable items
        action_words = ['action', 'task', 'todo', 'assigned', 'responsible', 'decision',
                       'agreed', 'decided', 'will', 'should', 'must']
        matching_action_words = sum(1 for word in action_words if word in text_lower and word in query_lower)
        if matching_action_words > 0:
            bonus += min(matching_action_words * 0.03, 0.09)

        # Project/proper noun bonus (new) - for specific entity queries
        # Check for capitalized words that might be names or projects
        query_words_original = query.split()
        capitalized_in_query = [w for w in query_words_original if w[0].isupper()]
        if capitalized_in_query:
            matches = sum(1 for word in capitalized_in_query if word.lower() in text_lower)
            if matches > 0:
                bonus += min(matches * 0.04, 0.08)

        return min(bonus, 0.3)  # Cap bonus at 30% (reduced from 50%)
    
    async def _cross_encoder_rerank(
        self,
        results: List[SearchResult],
        query: str
    ) -> List[SearchResult]:
        """Re-rank results using cross-encoder model."""
        if not self.cross_encoder or not results:
            logger.debug("Cross-encoder not available or no results to re-rank")
            return results
        
        try:
            # Prepare query-document pairs for cross-encoder
            pairs = []
            for result in results:
                # Limit text length for cross-encoder
                text_snippet = result.text[:512]
                pairs.append([query, text_snippet])
            
            # Get cross-encoder scores
            ce_scores = self.cross_encoder.predict(pairs)
            
            # Update results with cross-encoder scores
            for i, result in enumerate(results):
                result.cross_encoder_score = float(ce_scores[i])
                
                # Calculate final score combining hybrid and cross-encoder
                result.final_score = (
                    result.hybrid_score * (1 - self.config.cross_encoder_weight) +
                    result.cross_encoder_score * self.config.cross_encoder_weight
                )
                
                result.search_types.append(SearchType.CROSS_ENCODED)
            
            # Re-sort by final score
            results.sort(key=lambda x: x.final_score, reverse=True)
            
            logger.debug(f"Cross-encoder re-ranked {len(results)} results")
            return results
            
        except Exception as e:
            logger.error(f"Cross-encoder re-ranking failed: {e}")
            # Use hybrid scores as final scores
            for result in results:
                result.final_score = result.hybrid_score
            return results
    
    async def _optimize_final_results(
        self,
        results: List[SearchResult],
        query: str
    ) -> List[SearchResult]:
        """Optimize final results for diversity and quality."""
        if not results:
            return results
        
        # Filter low-quality results
        if self.config.filter_low_quality:
            filtered_results = [
                r for r in results 
                if r.confidence_score >= self.config.min_confidence_score
            ]
            if filtered_results:
                results = filtered_results
        
        # Apply diversity optimization
        diverse_results = await self._diversify_results(results, query)
        
        # Final ranking with diversity boost
        for i, result in enumerate(diverse_results):
            # Add small diversity boost based on position
            diversity_boost = self.config.diversity_boost * (1.0 - i / len(diverse_results))
            result.final_score += diversity_boost
            
            # Calculate source diversity
            result.source_diversity = len(set(result.search_types)) / 4.0  # Max 4 types
        
        # Final sort and limit
        diverse_results.sort(key=lambda x: x.final_score, reverse=True)
        final_results = diverse_results[:self.config.final_result_count]
        
        logger.debug(f"Optimized to {len(final_results)} final results")
        return final_results
    
    async def _diversify_results(
        self,
        results: List[SearchResult],
        query: str
    ) -> List[SearchResult]:
        """Apply diversity optimization to avoid redundant results."""
        if not results or len(results) <= 1:
            return results

        # Simple diversity based on content similarity
        if self.sentence_transformer:
            try:
                # Get embeddings for result texts
                texts = [r.text[:200] for r in results]  # Limit length
                # Run blocking sentence transformer in thread pool to avoid blocking event loop
                embeddings = await asyncio.to_thread(self.sentence_transformer.encode, texts)

                # SIMPLIFIED: Just filter out highly similar consecutive results
                # This is much faster than full MMR and good enough for our use case
                diverse_results = [results[0]]  # Always keep the best result
                selected_indices = [0]  # Track indices of selected results

                for i in range(1, len(results)):
                    # Check similarity to all selected results
                    is_diverse = True
                    for selected_idx in selected_indices:
                        sim = self._cosine_similarity(embeddings[i], embeddings[selected_idx])

                        # If too similar to any selected result, skip it
                        if sim > self.config.diversity_similarity_threshold:
                            is_diverse = False
                            break

                    if is_diverse:
                        diverse_results.append(results[i])
                        selected_indices.append(i)

                return diverse_results
                
            except Exception as e:
                logger.error(f"Diversity optimization failed: {e}")
        
        # Fallback: return results as-is
        return results
    
    # Utility and metrics methods
    
    def _calculate_overlap(
        self, 
        semantic_results: List[SearchResult],
        keyword_results: List[SearchResult]
    ) -> int:
        """Calculate overlap between semantic and keyword results."""
        semantic_ids = set(r.chunk_id for r in semantic_results)
        keyword_ids = set(r.chunk_id for r in keyword_results)
        return len(semantic_ids.intersection(keyword_ids))
    
    async def _calculate_diversity_score(self, results: List[SearchResult]) -> float:
        """Calculate diversity score for result set."""
        if len(results) <= 1:
            return 0.0

        # Diversity based on search method coverage
        search_types = set()
        for result in results:
            search_types.update(result.search_types)

        type_diversity = len(search_types) / 4.0  # Max 4 search types

        # Content diversity (if embeddings available)
        content_diversity = 0.5  # Default
        if self.sentence_transformer and len(results) > 1:
            try:
                texts = [r.text[:100] for r in results[:10]]  # Sample for performance
                # Run blocking sentence transformer in thread pool
                embeddings = await asyncio.to_thread(self.sentence_transformer.encode, texts)
                
                similarities = []
                for i in range(len(embeddings)):
                    for j in range(i + 1, len(embeddings)):
                        sim = self._cosine_similarity(embeddings[i], embeddings[j])
                        similarities.append(sim)
                
                avg_similarity = sum(similarities) / len(similarities)
                content_diversity = 1.0 - avg_similarity
                
            except Exception:
                pass
        
        return (type_diversity + content_diversity) / 2
    
    def _calculate_confidence_distribution(
        self, 
        results: List[SearchResult]
    ) -> Dict[str, int]:
        """Calculate distribution of confidence scores."""
        distribution = {'high': 0, 'medium': 0, 'low': 0}
        
        for result in results:
            if result.confidence_score >= 0.7:
                distribution['high'] += 1
            elif result.confidence_score >= 0.4:
                distribution['medium'] += 1
            else:
                distribution['low'] += 1
        
        return distribution
    
    def _cosine_similarity(self, a, b) -> float:
        """Calculate cosine similarity between vectors."""
        import numpy as np
        return np.dot(a, b) / (np.linalg.norm(a) * np.linalg.norm(b))
    
    def _log_search_statistics(self, pipeline: SearchPipeline):
        """Log detailed search statistics."""
        logger.info("Hybrid Search Statistics:")
        logger.info(f"  Query: '{pipeline.query}'")
        logger.info(f"  Processing time: {pipeline.processing_time_ms}ms")
        logger.info(f"  Semantic results: {pipeline.semantic_result_count}")
        logger.info(f"  Keyword results: {pipeline.keyword_result_count}")
        logger.info(f"  Result overlap: {pipeline.overlap_count}")
        logger.info(f"  Final results: {len(pipeline.final_results)}")
        logger.info(f"  Diversity score: {pipeline.diversity_score:.2f}")
        logger.info(f"  Confidence distribution: {pipeline.confidence_distribution}")
        
        if pipeline.final_results:
            scores = [r.final_score for r in pipeline.final_results]
            logger.info(f"  Score range: {min(scores):.3f} - {max(scores):.3f}")
            logger.info(f"  Average score: {sum(scores) / len(scores):.3f}")
    
    async def _fallback_search(
        self, 
        query: str, 
        project_id: str
    ) -> SearchPipeline:
        """Fallback to simple semantic search if hybrid search fails."""
        logger.warning("Using fallback search for hybrid service")
        
        try:
            # Simple semantic search
            embedding = await embedding_service.generate_embedding(query)
            # Get organization_id for fallback
            from db.database import get_db
            organization_id = None
            async for session in get_db():
                project = await session.get(Project, project_id)
                if project:
                    organization_id = str(project.organization_id)
                break

            if not organization_id:
                logger.error(f"Could not determine organization for project {sanitize_for_log(project_id)}")
                return []

            results = await multi_tenant_vector_store.search_vectors(
                organization_id=organization_id,
                query_vector=embedding,
                limit=self.config.final_result_count,
                score_threshold=0.1,
                filter_dict={"project_id": project_id}
            )
            
            # Convert to SearchResult format
            search_results = []
            for result in results:
                search_result = SearchResult(
                    chunk_id=result['id'],
                    text=result['payload'].get('text', ''),
                    metadata=result['payload'],
                    semantic_score=result['score'],
                    final_score=result['score'],
                    search_types=[SearchType.SEMANTIC],
                    confidence_score=result['score']
                )
                search_results.append(search_result)
            
            return SearchPipeline(
                query=query,
                config=self.config,
                semantic_results=search_results,
                keyword_results=[],
                merged_results=search_results,
                cross_encoded_results=search_results,
                final_results=search_results,
                semantic_result_count=len(search_results),
                keyword_result_count=0,
                overlap_count=0,
                diversity_score=0.5,
                confidence_distribution=self._calculate_confidence_distribution(search_results),
                processing_time_ms=0
            )
            
        except Exception as e:
            logger.error(f"Fallback search failed: {e}")
            raise


# Global service instance
hybrid_search_service = HybridSearchService()