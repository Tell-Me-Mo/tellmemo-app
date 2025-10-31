"""Enhanced RAG service refactored."""

import asyncio
import time
from typing import List, Dict, Any, Optional, Tuple
from datetime import datetime
import uuid
import json
import httpx
from enum import Enum

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from models.query import Query
from models.project import Project
from db.database import get_db
from db.multi_tenant_vector_store import multi_tenant_vector_store
from services.rag.embedding_service import embedding_service
from services.rag.multi_query_retrieval import (
    multi_query_retrieval_service, MultiQueryResults, QueryIntent
)
from services.rag.hybrid_search import (
    hybrid_search_service, HybridSearchConfig, SearchPipeline
)
from services.intelligence.meeting_intelligence import MeetingIntelligenceReport
from services.llm.multi_llm_client import get_multi_llm_client
from services.prompts.rag_prompts import (
    get_basic_rag_prompt,
    get_intelligent_rag_prompt
)
from config import get_settings
from utils.logger import get_logger, sanitize_for_log

logger = get_logger(__name__)


class RAGStrategy(Enum):
    """Different RAG strategies available."""
    BASIC = "basic"
    MULTI_QUERY = "multi_query"
    HYBRID_SEARCH = "hybrid_search"
    INTELLIGENT = "intelligent"
    AUTO = "auto"


class EnhancedRAGService:
    """Enhanced service for intelligent retrieval-augmented generation."""

    def __init__(self):
        # Enhanced retrieval parameters
        self.max_chunks_step1 = 15
        self.max_chunks_step2 = 10
        self.similarity_threshold = 0.05
        self.max_context_length = 8000

        # Organization ID cache to avoid repeated DB lookups
        self._org_cache = {}  # project_id -> organization_id mapping
        self._cache_hits = 0
        self._cache_misses = 0
        
        # Strategy configurations
        self.strategy_configs = {
            RAGStrategy.BASIC: {
                'max_chunks': 10,
                'use_multi_query': False,
                'use_hybrid_search': False,
                'use_intelligence': False
            },
            RAGStrategy.MULTI_QUERY: {
                'max_chunks': 15,
                'use_multi_query': True,
                'use_hybrid_search': False,
                'use_intelligence': False
            },
            RAGStrategy.HYBRID_SEARCH: {
                'max_chunks': 20,
                'use_multi_query': True,
                'use_hybrid_search': True,
                'use_intelligence': False
            },
            RAGStrategy.INTELLIGENT: {
                'max_chunks': 25,
                'use_multi_query': True,
                'use_hybrid_search': True,
                'use_intelligence': True
            }
        }
        
        # Initialize LLM configuration
        settings = get_settings()
        # Use multi-provider client's configured model (PRIMARY_LLM_MODEL)
        self.llm_model = None
        self.max_tokens = settings.max_tokens
        self.temperature = settings.temperature

        # Use multi-provider LLM client
        self.llm_client = get_multi_llm_client(settings)

        if not self.llm_client.is_available():
            logger.warning("LLM client not available for enhanced RAG service")
        
        # Query type patterns for strategy selection
        self.complex_query_indicators = [
            'compare', 'analyze', 'relationship', 'correlation', 'impact',
            'multiple', 'various', 'different', 'contrast', 'evaluate',
            'comprehensive', 'detailed', 'thorough', 'complex'
        ]
        self.simple_query_indicators = [
            'who', 'when', 'where', 'what is', 'define', 'explain', 
            'tell me', 'show me', 'simple', 'quick'
        ]
        
        # Hybrid search configuration - optimized for meeting transcripts
        self.hybrid_config = HybridSearchConfig(
            semantic_weight=0.45,  # Better balance for keyword-rich transcripts
            keyword_weight=0.55,  # Higher weight for exact matches in meetings
            cross_encoder_weight=0.5,  # Better relevance ranking
            max_results_per_method=30,  # Larger candidate pool
            final_result_count=15,
            diversity_boost=0.1
        )
    
    async def query_project(
        self,
        project_id: str,
        question: str,
        user_id: Optional[str] = None,
        strategy: RAGStrategy = RAGStrategy.AUTO,
        organization_id: Optional[str] = None
    ) -> Dict[str, Any]:
        """Execute enhanced RAG query."""
        start_time = time.time()

        # Detect if this is a context-enhanced query from conversation
        is_context_enhanced = self._detect_context_enhanced_query(question)
        if is_context_enhanced:
            logger.info(f"Processing context-enhanced query for project {sanitize_for_log(project_id)}")

        # Auto-select strategy if requested
        if strategy == RAGStrategy.AUTO:
            strategy = self._select_optimal_strategy(question)
            logger.info(f"Auto-selected strategy: {strategy.value}")

        try:
            # Execute strategy-specific retrieval and generation
            config = self.strategy_configs[strategy]

            if strategy == RAGStrategy.BASIC:
                result = await self._execute_basic_rag(project_id, question, config)
            elif strategy == RAGStrategy.MULTI_QUERY:
                result = await self._execute_multi_query_rag(project_id, question, config)
            elif strategy == RAGStrategy.HYBRID_SEARCH:
                result = await self._execute_hybrid_search_rag(project_id, question, config)
            elif strategy == RAGStrategy.INTELLIGENT:
                result = await self._execute_intelligent_rag(project_id, question, config)
            else:
                raise ValueError(f"Unknown strategy: {strategy}")

            # Calculate total response time
            total_time = int((time.time() - start_time) * 1000)
            result['response_time_ms'] = total_time
            result['strategy_used'] = strategy.value

            logger.info(f"Enhanced RAG query completed using {strategy.value} in {total_time}ms")
            return result

        except Exception as e:
            logger.error(f"Enhanced RAG query failed for project {sanitize_for_log(project_id)}: {e}")
            raise

    async def query_multiple_projects(
        self,
        project_ids: List[str],
        question: str,
        user_id: Optional[str] = None,
        strategy: RAGStrategy = RAGStrategy.AUTO,
        organization_id: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Query multiple projects simultaneously using unified search.

        This is the proper way to query across programs/portfolios - it performs
        a single unified search across all project vectors instead of querying
        projects sequentially.

        Args:
            project_ids: List of project IDs to query
            question: The question to answer
            user_id: Optional user ID for tracking
            strategy: RAG strategy to use
            organization_id: Optional organization ID (will be fetched if not provided)

        Returns:
            Dict containing unified answer, sources grouped by project, and metadata
        """
        start_time = time.time()

        if not project_ids:
            raise ValueError("project_ids cannot be empty")

        logger.info(f"Querying {sanitize_for_log(len(project_ids))} projects with unified search: {sanitize_for_log(question[:100])}")

        # Detect if this is a context-enhanced query
        is_context_enhanced = self._detect_context_enhanced_query(question)

        # Auto-select strategy if requested
        if strategy == RAGStrategy.AUTO:
            strategy = self._select_optimal_strategy(question)
            logger.info(f"Auto-selected strategy for multi-project query: {strategy.value}")

        try:
            # Execute unified retrieval across all projects
            config = self.strategy_configs[strategy]
            result = await self._execute_unified_multi_project_search(
                project_ids, question, config, strategy
            )

            # Calculate total response time
            total_time = int((time.time() - start_time) * 1000)
            result['response_time_ms'] = total_time
            result['strategy_used'] = strategy.value

            logger.info(f"Multi-project RAG query completed for {len(project_ids)} projects in {total_time}ms")
            return result

        except Exception as e:
            logger.error(f"Multi-project RAG query failed: {e}")
            raise

    async def _get_organization_id(self, project_id: str) -> str:
        """Get organization ID with caching to avoid repeated DB lookups."""
        # Check cache first
        if project_id in self._org_cache:
            self._cache_hits += 1
            logger.debug(f"Organization ID cache hit for project {sanitize_for_log(project_id)} (total hits: {sanitize_for_log(self._cache_hits)})")
            return self._org_cache[project_id]

        # Cache miss - fetch from database
        self._cache_misses += 1
        logger.debug(f"Organization ID cache miss for project {sanitize_for_log(project_id)} (total misses: {sanitize_for_log(self._cache_misses)})")

        organization_id = None
        from db.database import get_db
        async for session in get_db():
            project = await session.get(Project, project_id)
            if project:
                organization_id = str(project.organization_id)
                # Store in cache for future use
                self._org_cache[project_id] = organization_id
                logger.info(f"Cached organization {sanitize_for_log(organization_id)} for project {sanitize_for_log(project_id)}")
            break

        if not organization_id:
            raise ValueError(f"Could not determine organization for project {project_id}")

        return organization_id

    def clear_org_cache(self, project_id: Optional[str] = None):
        """Clear organization cache, optionally for a specific project."""
        if project_id:
            self._org_cache.pop(project_id, None)
            logger.info(f"Cleared organization cache for project {project_id}")
        else:
            cache_size = len(self._org_cache)
            self._org_cache.clear()
            logger.info(f"Cleared entire organization cache ({cache_size} entries)")

    async def _execute_basic_rag(
        self,
        project_id: str,
        question: str,
        config: Dict[str, Any]
    ) -> Dict[str, Any]:
        """Execute basic 3-step RAG process."""
        # Generate embedding
        query_embedding = await embedding_service.generate_embedding(question)

        # Perform vector search
        chunks = []
        # Get organization_id using cache
        organization_id = await self._get_organization_id(project_id)

        # Use two-stage MRL search if enabled for better quality
        settings = get_settings()
        if settings.enable_mrl and settings.rag_use_two_stage_search:
            results = await multi_tenant_vector_store.search_vectors_two_stage(
                organization_id=organization_id,
                query_vector=query_embedding,
                initial_limit=config['max_chunks'] * 3,  # Get more candidates
                final_limit=config['max_chunks'],
                score_threshold=self.similarity_threshold,
                filter_dict={"project_id": project_id}
            )
        else:
            results = await multi_tenant_vector_store.search_vectors(
                organization_id=organization_id,
                query_vector=query_embedding,
                limit=config['max_chunks'],
                score_threshold=self.similarity_threshold,
                filter_dict={"project_id": project_id}
            )

        for result in results:
            chunk_data = {
                'id': result['id'],
                'text': result['payload'].get('text', ''),
                'title': result['payload'].get('title', ''),
                'score': result['score']
            }
            chunks.append(chunk_data)

        # Generate response
        response = await self._generate_response(question, chunks, "basic")

        return {
            'answer': response['answer'],
            'sources': response['sources'],
            'confidence': response['confidence'],
            'chunks_retrieved': len(chunks),
            'token_count': response.get('token_count', 0),
            'cost': response.get('cost', 0.0),
            'retrieval_quality': {
                'avg_score': sum(c['score'] for c in chunks) / len(chunks) if chunks else 0,
                'score_range': f"{min(c['score'] for c in chunks):.3f}-{max(c['score'] for c in chunks):.3f}" if chunks else "0-0"
            }
        }
    
    async def _execute_multi_query_rag(
        self,
        project_id: str,
        question: str,
        config: Dict[str, Any]
    ) -> Dict[str, Any]:
        """Execute multi-query RAG."""
        chunks = []
        multi_results = None

        # Use multi-query retrieval service
        multi_results = await multi_query_retrieval_service.retrieve_with_multi_query(
            question, project_id, config['max_chunks']
        )

        # Convert results to standard format
        for result in multi_results.deduplicated_results:
            chunk_data = {
                'id': result.chunk_id,
                'text': result.text,
                'title': result.metadata.get('title', ''),
                'score': result.score
            }
            chunks.append(chunk_data)

        # Generate response
        response = await self._generate_response(question, chunks, "multi_query")

        return {
            'answer': response['answer'],
            'sources': response['sources'],
            'confidence': response['confidence'],
            'chunks_retrieved': len(chunks),
            'token_count': response.get('token_count', 0),
            'cost': response.get('cost', 0.0),
            'retrieval_quality': {
                'query_variations': multi_results.total_queries_executed,
                'diversity_score': multi_results.result_diversity_score,
                'coverage_score': multi_results.coverage_score,
                'best_variation': multi_results.best_performing_variation
            },
            'query_analysis': {
                'intent': multi_results.query_analysis.intent.value,
                'complexity_score': multi_results.query_analysis.complexity_score,
                'entities': len(multi_results.query_analysis.entities),
                'keywords': len(multi_results.query_analysis.keywords)
            }
        }
    
    async def _execute_hybrid_search_rag(
        self,
        project_id: str,
        question: str,
        config: Dict[str, Any]
    ) -> Dict[str, Any]:
        """Execute hybrid search RAG."""
        chunks = []
        search_pipeline = None

        # Use hybrid search service
        search_pipeline = await hybrid_search_service.hybrid_search(
            question, project_id, self.hybrid_config
        )

        # Convert results to standard format
        for result in search_pipeline.final_results:
            chunk_data = {
                'id': result.chunk_id,
                'text': result.text,
                'title': result.metadata.get('title', ''),
                'score': result.final_score
            }
            chunks.append(chunk_data)

        # Generate response
        response = await self._generate_response(question, chunks, "hybrid_search")

        return {
            'answer': response['answer'],
            'sources': response['sources'],
            'confidence': response['confidence'],
            'chunks_retrieved': len(chunks),
            'token_count': response.get('token_count', 0),
            'cost': response.get('cost', 0.0),
            'retrieval_quality': {
                'semantic_results': search_pipeline.semantic_result_count,
                'keyword_results': search_pipeline.keyword_result_count,
                'result_overlap': search_pipeline.overlap_count,
                'diversity_score': search_pipeline.diversity_score,
                'confidence_distribution': search_pipeline.confidence_distribution,
                'processing_time_ms': search_pipeline.processing_time_ms
            }
        }
    
    async def _execute_unified_multi_project_search(
        self,
        project_ids: List[str],
        question: str,
        config: Dict[str, Any],
        strategy: RAGStrategy
    ) -> Dict[str, Any]:
        """
        Execute unified search across multiple projects.

        This performs a single vector search with OR filter for all project IDs,
        then generates a unified answer from the results.
        """
        # Generate embedding
        query_embedding = await embedding_service.generate_embedding(question)

        # Get organization_id from first project
        organization_id = await self._get_organization_id(project_ids[0])

        # Perform parallel vector search across all projects
        # Search all projects in parallel and merge results by relevance score
        settings = get_settings()

        # Increase max_chunks proportionally to number of projects
        max_chunks_per_project = config['max_chunks']
        max_total_chunks = min(max_chunks_per_project * len(project_ids), 50)

        # Define search function for each project
        async def search_project(project_id: str):
            try:
                if settings.enable_mrl and settings.rag_use_two_stage_search:
                    return await multi_tenant_vector_store.search_vectors_two_stage(
                        organization_id=organization_id,
                        query_vector=query_embedding,
                        initial_limit=max_chunks_per_project * 3,
                        final_limit=max_chunks_per_project,
                        score_threshold=self.similarity_threshold,
                        filter_dict={"project_id": project_id}
                    )
                else:
                    return await multi_tenant_vector_store.search_vectors(
                        organization_id=organization_id,
                        query_vector=query_embedding,
                        limit=max_chunks_per_project,
                        score_threshold=self.similarity_threshold,
                        filter_dict={"project_id": project_id}
                    )
            except Exception as e:
                logger.warning(f"Failed to search project {project_id}: {e}")
                return []

        # Search all projects in parallel using asyncio.gather
        logger.info(f"Searching {len(project_ids)} projects in parallel")
        search_tasks = [search_project(pid) for pid in project_ids]
        project_results_list = await asyncio.gather(*search_tasks)

        # Flatten and collect all results
        all_search_results = []
        for project_results in project_results_list:
            all_search_results.extend(project_results)

        logger.info(f"Collected {len(all_search_results)} total chunks from all projects")

        # Sort all results by score and take top N
        all_search_results.sort(key=lambda x: x['score'], reverse=True)
        results = all_search_results[:max_total_chunks]

        # Group results by project
        chunks_by_project = {}
        all_chunks = []

        for result in results:
            chunk_project_id = result['payload'].get('project_id', '')
            chunk_data = {
                'id': result['id'],
                'text': result['payload'].get('text', ''),
                'title': result['payload'].get('title', ''),
                'score': result['score'],
                'project_id': chunk_project_id
            }
            all_chunks.append(chunk_data)

            if chunk_project_id not in chunks_by_project:
                chunks_by_project[chunk_project_id] = []
            chunks_by_project[chunk_project_id].append(chunk_data)

        # Generate unified response
        response = await self._generate_unified_multi_project_response(
            question, all_chunks, chunks_by_project, strategy.value
        )

        return {
            'answer': response['answer'],
            'sources': response['sources'],
            'sources_by_project': response['sources_by_project'],
            'confidence': response['confidence'],
            'chunks_retrieved': len(all_chunks),
            'projects_with_results': len(chunks_by_project),
            'token_count': response.get('token_count', 0),
            'cost': response.get('cost', 0.0),
            'retrieval_quality': {
                'avg_score': sum(c['score'] for c in all_chunks) / len(all_chunks) if all_chunks else 0,
                'projects_queried': len(project_ids),
                'projects_with_results': len(chunks_by_project),
                'score_range': f"{min(c['score'] for c in all_chunks):.3f}-{max(c['score'] for c in all_chunks):.3f}" if all_chunks else "0-0"
            }
        }

    async def _generate_unified_multi_project_response(
        self,
        question: str,
        all_chunks: List[Dict[str, Any]],
        chunks_by_project: Dict[str, List[Dict[str, Any]]],
        strategy: str
    ) -> Dict[str, Any]:
        """Generate unified response from multi-project chunks."""
        if not all_chunks:
            return {
                'answer': "I couldn't find relevant information in any of the projects.",
                'sources': [],
                'sources_by_project': {},
                'confidence': 0.0,
                'token_count': 0,
                'cost': 0.0
            }

        # Prepare context from all chunks (sorted by score)
        sorted_chunks = sorted(all_chunks, key=lambda x: x['score'], reverse=True)
        context_parts = []
        sources_by_project = {}

        for chunk in sorted_chunks:
            project_id = chunk['project_id']
            context_parts.append(f"From {chunk['title']}: {chunk['text']}")

            if project_id not in sources_by_project:
                sources_by_project[project_id] = set()
            sources_by_project[project_id].add(chunk['title'])

        context = "\n\n".join(context_parts)
        all_sources = list(set(chunk['title'] for chunk in sorted_chunks))

        # Convert sources_by_project to serializable format
        sources_by_project_list = {
            pid: list(sources) for pid, sources in sources_by_project.items()
        }

        # Generate with Claude
        if self.llm_client.is_available():
            try:
                response = await self.llm_client.create_message(
                    prompt=self._build_multi_project_prompt(question, context, len(chunks_by_project)),
                    model=self.llm_model,
                    max_tokens=self.max_tokens,
                    temperature=self.temperature
                )

                answer = response.content[0].text
                token_usage = {
                    'input_tokens': response.usage.input_tokens,
                    'output_tokens': response.usage.output_tokens
                }
                cost = self._calculate_cost(token_usage)

            except Exception as e:
                logger.error(f"Multi-project Claude API call failed: {e}")
                answer = self._generate_multi_project_placeholder(question, sorted_chunks, chunks_by_project)
                token_usage = {'input_tokens': 0, 'output_tokens': 0}
                cost = 0.0
        else:
            answer = self._generate_multi_project_placeholder(question, sorted_chunks, chunks_by_project)
            token_usage = {'input_tokens': 0, 'output_tokens': 0}
            cost = 0.0

        confidence = self._calculate_confidence(sorted_chunks, strategy)

        return {
            'answer': answer,
            'sources': all_sources,
            'sources_by_project': sources_by_project_list,
            'confidence': confidence,
            'token_count': token_usage.get('input_tokens', 0) + token_usage.get('output_tokens', 0),
            'cost': cost
        }

    def _build_multi_project_prompt(self, question: str, context: str, project_count: int) -> str:
        """Build prompt for multi-project query."""
        return f"""You are analyzing content from {project_count} different projects to answer a question.

The context below contains information from multiple projects. Provide a unified answer that:
1. Directly answers the question
2. Only includes information that is relevant to the question
3. Clearly indicates which project(s) contain relevant information
4. Does not force answers from projects that don't have relevant information

Question: {question}

Context from {project_count} projects:
{context}

Provide a clear, unified answer based on the relevant information found."""

    def _generate_multi_project_placeholder(
        self,
        question: str,
        sorted_chunks: List[Dict[str, Any]],
        chunks_by_project: Dict[str, List[Dict[str, Any]]]
    ) -> str:
        """Generate placeholder response for multi-project query."""
        response_parts = [
            f"Based on information from {len(chunks_by_project)} project(s) for: '{question}'",
            ""
        ]

        for project_id, chunks in chunks_by_project.items():
            sources = set(chunk['title'] for chunk in chunks)
            response_parts.append(f"**Project {project_id[:8]}...:**")
            for source in list(sources)[:2]:
                relevant_chunks = [c for c in chunks if c['title'] == source]
                if relevant_chunks:
                    response_parts.append(f"- From {source}: {relevant_chunks[0]['text'][:150]}...")
            response_parts.append("")

        return "\n".join(response_parts)


    async def _execute_intelligent_rag(
        self,
        project_id: str,
        question: str,
        config: Dict[str, Any]
    ) -> Dict[str, Any]:
        """Execute intelligent RAG."""
        # Step 1: Hybrid search retrieval
        search_pipeline = await hybrid_search_service.hybrid_search(
            question, project_id, self.hybrid_config
        )

        # Step 2: Apply meeting intelligence
        intelligence_insights = {}
        try:
            intelligence_insights = await self._extract_contextual_intelligence(
                search_pipeline.final_results, question
            )
        except Exception as e:
            logger.warning(f"Meeting intelligence extraction failed: {e}")

        # Convert results to standard format
        chunks = []
        for result in search_pipeline.final_results:
            chunk_data = {
                'id': result.chunk_id,
                'text': result.text,
                'title': result.metadata.get('title', ''),
                'score': result.final_score,
                'search_types': [st.value for st in result.search_types] if hasattr(result, 'search_types') else [],
                'matched_keywords': getattr(result, 'matched_keywords', [])
            }
            chunks.append(chunk_data)

        # Generate enhanced response
        response = await self._generate_intelligent_response(
            question, chunks, intelligence_insights
        )

        return {
            'answer': response['answer'],
            'sources': response['sources'],
            'confidence': response['confidence'],
            'chunks_retrieved': len(chunks),
            'token_count': response.get('token_count', 0),
            'cost': response.get('cost', 0.0),
            'retrieval_quality': {
                'semantic_results': search_pipeline.semantic_result_count,
                'keyword_results': search_pipeline.keyword_result_count,
                'result_overlap': search_pipeline.overlap_count,
                'diversity_score': search_pipeline.diversity_score
            },
            'intelligence_insights': intelligence_insights
        }
    
    async def _generate_response(
        self,
        question: str,
        chunks: List[Dict[str, Any]],
        strategy: str
    ) -> Dict[str, Any]:
        """Generate response using Claude with context managers."""
        if not chunks:
            return {
                'answer': "I couldn't find relevant information to answer your question.",
                'sources': [],
                'confidence': 0.0,
                'token_count': 0,
                'cost': 0.0
            }
        
        # Prepare context
        context_parts = []
        sources = set()
        
        for chunk in chunks:
            context_parts.append(f"From {chunk['title']}: {chunk['text']}")
            sources.add(chunk['title'])
        
        context = "\n\n".join(context_parts)

        # Generate with Claude
        if self.llm_client.is_available():
            try:
                response = await self.llm_client.create_message(
                    prompt=self._build_prompt(question, context, strategy),
                    model=self.llm_model,
                    max_tokens=self.max_tokens,
                    temperature=self.temperature
                )

                answer = response.content[0].text
                token_usage = {
                    'input_tokens': response.usage.input_tokens,
                    'output_tokens': response.usage.output_tokens
                }
                cost = self._calculate_cost(token_usage)

            except Exception as e:
                logger.error(f"Claude API call failed: {e}")
                answer = self._generate_placeholder_response(question, context, chunks, strategy)
                token_usage = {'input_tokens': 0, 'output_tokens': 0}
                cost = 0.0
        else:
            answer = self._generate_placeholder_response(question, context, chunks, strategy)
            token_usage = {'input_tokens': 0, 'output_tokens': 0}
            cost = 0.0
        
        confidence = self._calculate_confidence(chunks, strategy)
        
        return {
            'answer': answer,
            'sources': list(sources),
            'confidence': confidence,
            'token_count': token_usage.get('input_tokens', 0) + token_usage.get('output_tokens', 0),
            'cost': cost
        }
    
    async def _generate_intelligent_response(
        self,
        question: str,
        chunks: List[Dict[str, Any]],
        intelligence_insights: Dict[str, Any]
    ) -> Dict[str, Any]:
        """Generate intelligent response with meeting intelligence."""
        if not chunks:
            return {
                'answer': "I couldn't find relevant information to answer your question.",
                'sources': [],
                'confidence': 0.0,
                'token_count': 0,
                'cost': 0.0
            }
        
        # Prepare enhanced context
        context_parts = []
        sources = set()
        
        # Add intelligence context if available
        if intelligence_insights:
            intel_summary = []
            if intelligence_insights.get('decision_indicators', 0) > 0:
                intel_summary.append(f"Content contains {intelligence_insights['decision_indicators']} decision indicators")
            if intelligence_insights.get('action_indicators', 0) > 0:
                intel_summary.append(f"Content contains {intelligence_insights['action_indicators']} action indicators")
            if intelligence_insights.get('participant_mentions'):
                intel_summary.append(f"Key participants: {', '.join(intelligence_insights['participant_mentions'][:3])}")
            
            if intel_summary:
                context_parts.append(f"Meeting Intelligence: {'; '.join(intel_summary)}\n")
        
        # Add chunk content
        for chunk in chunks:
            enhanced_header = f"From {chunk['title']}"
            if 'search_types' in chunk and chunk['search_types']:
                enhanced_header += f" (via: {', '.join(chunk['search_types'])})"
            if 'matched_keywords' in chunk and chunk['matched_keywords']:
                enhanced_header += f" [keywords: {', '.join(chunk['matched_keywords'][:3])}]"
            
            context_parts.append(f"{enhanced_header}: {chunk['text']}")
            sources.add(chunk['title'])
        
        context = "\n\n".join(context_parts)

        # Generate with Claude
        if self.llm_client.is_available():
            try:
                response = await self.llm_client.create_message(
                    prompt=self._build_intelligent_prompt(question, context, intelligence_insights),
                    model=self.llm_model,
                    max_tokens=self.max_tokens,
                    temperature=self.temperature * 0.9
                )

                answer = response.content[0].text
                token_usage = {
                    'input_tokens': response.usage.input_tokens,
                    'output_tokens': response.usage.output_tokens
                }
                cost = self._calculate_cost(token_usage)

            except Exception as e:
                logger.error(f"Intelligent Claude API call failed: {e}")
                answer = self._generate_intelligent_placeholder_response(
                    question, context, chunks, intelligence_insights
                )
                token_usage = {'input_tokens': 0, 'output_tokens': 0}
                cost = 0.0
        else:
            answer = self._generate_intelligent_placeholder_response(
                question, context, chunks, intelligence_insights
            )
            token_usage = {'input_tokens': 0, 'output_tokens': 0}
            cost = 0.0
        
        confidence = self._calculate_intelligent_confidence(chunks, intelligence_insights)
        
        return {
            'answer': answer,
            'sources': list(sources),
            'confidence': confidence,
            'token_count': token_usage.get('input_tokens', 0) + token_usage.get('output_tokens', 0),
            'cost': cost
        }
    
    # Helper methods remain the same...
    def _select_optimal_strategy(self, question: str) -> RAGStrategy:
        """Automatically select the optimal RAG strategy."""
        question_lower = question.lower()
        
        complex_score = sum(1 for indicator in self.complex_query_indicators if indicator in question_lower)
        simple_score = sum(1 for indicator in self.simple_query_indicators if indicator in question_lower)
        
        word_count = len(question.split())
        has_multiple_questions = question.count('?') > 1
        has_connectors = any(word in question_lower for word in ['and', 'or', 'also', 'additionally'])
        
        if simple_score > complex_score and word_count <= 10 and not has_multiple_questions:
            return RAGStrategy.BASIC
        elif complex_score > 0 or has_multiple_questions or word_count > 20:
            return RAGStrategy.INTELLIGENT
        elif has_connectors or word_count > 15:
            return RAGStrategy.HYBRID_SEARCH
        else:
            return RAGStrategy.MULTI_QUERY
    
    def _classify_query_type(self, question: str) -> str:
        """Classify the type of query."""
        question_lower = question.lower()

        if any(word in question_lower for word in ['when', 'date', 'timeline']):
            return "temporal"
        elif any(word in question_lower for word in ['who', 'team', 'member']):
            return "people"
        elif any(word in question_lower for word in ['what', 'how', 'explain']):
            return "informational"
        elif any(word in question_lower for word in ['decide', 'decision']):
            return "decision"
        elif any(word in question_lower for word in ['action', 'todo', 'task']):
            return "action_items"
        else:
            return "general"

    def _detect_context_enhanced_query(self, question: str) -> bool:
        """Detect if a query has been enhanced with conversation context."""
        # Look for conversation context indicators
        context_indicators = [
            "based on this conversation context:",
            "previous q1:", "previous a1:",
            "previous q2:", "previous a2:",
            "previous q3:", "previous a3:",
            "current question:",
            "please search for information that addresses the current question while considering the conversation context"
        ]

        question_lower = question.lower()
        return any(indicator in question_lower for indicator in context_indicators)
    
    async def _extract_contextual_intelligence(
        self,
        results: List[Any],
        question: str
    ) -> Dict[str, Any]:
        """Extract contextual intelligence from results."""
        if not results:
            return {}
        
        all_text = ' '.join(result.text for result in results)
        
        intelligence = {
            'content_types_found': [],
            'decision_indicators': 0,
            'action_indicators': 0,
            'participant_mentions': [],
            'temporal_references': []
        }
        
        # Decision patterns
        decision_patterns = ['decided', 'concluded', 'agreed', 'resolved']
        intelligence['decision_indicators'] = sum(
            all_text.lower().count(pattern) for pattern in decision_patterns
        )
        
        # Action patterns  
        action_patterns = ['will', 'should', 'action item', 'next step']
        intelligence['action_indicators'] = sum(
            all_text.lower().count(pattern) for pattern in action_patterns
        )
        
        # Content types
        for result in results:
            content_type = result.metadata.get('content_type', 'unknown')
            if content_type not in intelligence['content_types_found']:
                intelligence['content_types_found'].append(content_type)
        
        return intelligence
    
    def _build_prompt(self, question: str, context: str, strategy: str) -> str:
        """Build Claude prompt."""
        strategy_instructions = {
            'basic': "Provide a clear and direct answer based on the available context.",
            'multi_query': "Consider the comprehensive context from multiple query perspectives.",
            'hybrid_search': "Leverage both semantic understanding and keyword matches.",
            'intelligent': "Use the enhanced context and meeting intelligence."
        }
        
        return get_basic_rag_prompt(question=question, context=context, strategy=strategy)
    
    def _build_intelligent_prompt(
        self,
        question: str,
        context: str,
        intelligence_insights: Dict[str, Any]
    ) -> str:
        """Build intelligent Claude prompt."""
        intel_summary = []
        if intelligence_insights:
            if intelligence_insights.get('decision_indicators', 0) > 0:
                intel_summary.append(f"Decisions detected: {intelligence_insights['decision_indicators']}")
            if intelligence_insights.get('action_indicators', 0) > 0:
                intel_summary.append(f"Actions detected: {intelligence_insights['action_indicators']}")
            if intelligence_insights.get('participant_mentions'):
                intel_summary.append(f"Key participants: {', '.join(intelligence_insights['participant_mentions'][:3])}")
        
        intel_text = "\n".join(intel_summary) if intel_summary else "No specific intelligence extracted"
        
        return get_intelligent_rag_prompt(
            question=question,
            context=context,
            intelligence_summary=intel_text
        )
    
    def _calculate_confidence(self, chunks: List[Dict[str, Any]], strategy: str) -> float:
        """Calculate confidence score."""
        if not chunks:
            return 0.0
        
        avg_score = sum(c['score'] for c in chunks) / len(chunks)
        
        strategy_multipliers = {
            'basic': 1.0,
            'multi_query': 1.1,
            'hybrid_search': 1.2,
            'intelligent': 1.3
        }
        
        confidence = avg_score * strategy_multipliers.get(strategy, 1.0)
        
        if len(set(c['title'] for c in chunks)) > 2:
            confidence *= 1.1
        
        return min(confidence, 0.95)
    
    def _calculate_intelligent_confidence(
        self,
        chunks: List[Dict[str, Any]],
        intelligence_insights: Dict[str, Any]
    ) -> float:
        """Calculate intelligent confidence."""
        base_confidence = self._calculate_confidence(chunks, 'intelligent')
        
        if intelligence_insights.get('decision_indicators', 0) > 0:
            base_confidence *= 1.05
        if intelligence_insights.get('action_indicators', 0) > 0:
            base_confidence *= 1.05
        
        return min(base_confidence, 0.98)
    
    def _calculate_cost(self, token_usage: Dict[str, int]) -> float:
        """Calculate cost based on token usage."""
        # Claude 3.5 Haiku pricing
        input_cost_per_million = 0.80
        output_cost_per_million = 4.00
        
        input_cost = (token_usage.get('input_tokens', 0) / 1_000_000) * input_cost_per_million
        output_cost = (token_usage.get('output_tokens', 0) / 1_000_000) * output_cost_per_million
        
        return input_cost + output_cost
    
    def _generate_placeholder_response(
        self,
        question: str,
        context: str,
        chunks: List[Dict[str, Any]],
        strategy: str
    ) -> str:
        """Generate placeholder response."""
        if not chunks:
            return "No relevant information found."
        
        by_source = {}
        for chunk in chunks:
            title = chunk['title']
            if title not in by_source:
                by_source[title] = []
            by_source[title].append(chunk['text'][:200])
        
        response_parts = [
            f"Based on {strategy} retrieval strategy for: '{question}'",
            ""
        ]
        
        for source, texts in by_source.items():
            response_parts.append(f"**From {source}:**")
            for text in texts[:2]:
                response_parts.append(f"- {text}...")
            response_parts.append("")
        
        return "\n".join(response_parts)
    
    def _generate_intelligent_placeholder_response(
        self,
        question: str,
        context: str,
        chunks: List[Dict[str, Any]],
        intelligence_insights: Dict[str, Any]
    ) -> str:
        """Generate intelligent placeholder response."""
        response_parts = [f"**Intelligent Analysis** for: '{question}'", ""]
        
        if intelligence_insights:
            response_parts.append("**Meeting Intelligence:**")
            if intelligence_insights.get('decision_indicators', 0) > 0:
                response_parts.append(f"- {intelligence_insights['decision_indicators']} decisions found")
            if intelligence_insights.get('action_indicators', 0) > 0:
                response_parts.append(f"- {intelligence_insights['action_indicators']} actions found")
            response_parts.append("")
        
        by_source = {}
        for chunk in chunks[:5]:
            title = chunk['title']
            if title not in by_source:
                by_source[title] = []
            by_source[title].append(chunk['text'][:200])
        
        response_parts.append("**Content Analysis:**")
        for source, texts in by_source.items():
            response_parts.append(f"**{source}:**")
            for text in texts[:1]:
                response_parts.append(f"- {text}...")
        
        return "\n".join(response_parts)

    async def query_for_live_insights(
        self,
        question: str,
        project_id: str,
        organization_id: str,
        max_chunks: int = 5,
        timeout: float = 5.0
    ) -> Dict[str, Any]:
        """
        Optimized RAG query for live meeting insights.

        Uses fast retrieval + LLM for concise answers during meetings:
        - 5-second timeout for LLM generation
        - Minimal token usage (concise prompt)
        - Direct, factual answers only
        - No complex strategies (just basic semantic search)
        - Automatic fallback to document excerpts on timeout

        Args:
            question: The question asked during the meeting
            project_id: Project UUID string
            organization_id: Organization UUID string
            max_chunks: Maximum document chunks to retrieve (default: 5)
            timeout: Maximum time allowed for LLM call (default: 5.0s)

        Returns:
            Dict with keys: answer, sources, confidence, response_time_ms
        """
        start_time = time.time()

        try:
            # Step 1: Fast vector search (typically <200ms)
            query_embedding = await embedding_service.generate_embedding(question)

            # Use two-stage MRL search for better quality
            results = await multi_tenant_vector_store.search_vectors_two_stage(
                organization_id=organization_id,
                query_vector=query_embedding,
                initial_limit=max_chunks * 3,  # 3x candidates for stage 1
                final_limit=max_chunks,
                score_threshold=0.3,
                filter_dict={"project_id": project_id}
            )

            if not results:
                return {
                    'answer': "No relevant documents found.",
                    'sources': [],
                    'confidence': 0.0,
                    'response_time_ms': int((time.time() - start_time) * 1000),
                    'chunks_retrieved': 0
                }

            # Step 2: Prepare context for LLM
            chunks = []
            sources = set()
            context_parts = []

            for result in results:
                payload = result.get('payload', {})
                title = payload.get('title', 'Untitled Document')
                text = payload.get('text', '')
                score = result.get('score', 0.0)

                chunks.append({'title': title, 'text': text, 'score': score})
                sources.add(title)
                context_parts.append(f"From {title}:\n{text}")

            context = "\n\n".join(context_parts)

            # Step 3: Generate concise answer with LLM (with timeout)
            if not self.llm_client.is_available():
                # Fallback: return first document excerpt
                return {
                    'answer': chunks[0]['text'][:200] + "...",
                    'sources': list(sources),
                    'confidence': chunks[0]['score'],
                    'response_time_ms': int((time.time() - start_time) * 1000),
                    'chunks_retrieved': len(chunks)
                }

            # Import the live insights prompt
            from services.prompts.rag_prompts import get_live_insights_rag_prompt

            try:
                # Use asyncio.wait_for to enforce timeout
                response = await asyncio.wait_for(
                    self.llm_client.create_message(
                        prompt=get_live_insights_rag_prompt(question, context),
                        model=self.llm_model,
                        max_tokens=150,  # Limit to keep answer concise
                        temperature=0.0  # Deterministic for factual answers
                    ),
                    timeout=timeout
                )

                answer = response.content[0].text.strip()

                # Calculate confidence from retrieval scores
                avg_score = sum(c['score'] for c in chunks) / len(chunks)
                confidence = min(avg_score, 1.0)

                return {
                    'answer': answer,
                    'sources': list(sources),
                    'confidence': confidence,
                    'response_time_ms': int((time.time() - start_time) * 1000),
                    'chunks_retrieved': len(chunks),
                    'token_count': response.usage.input_tokens + response.usage.output_tokens
                }

            except asyncio.TimeoutError:
                logger.warning(f"LLM timeout ({timeout}s) for live insights query")
                # Fallback to document excerpt
                return {
                    'answer': chunks[0]['text'][:200] + "...",
                    'sources': list(sources),
                    'confidence': chunks[0]['score'],
                    'response_time_ms': int((time.time() - start_time) * 1000),
                    'chunks_retrieved': len(chunks)
                }

        except Exception as e:
            logger.error(f"Live insights RAG query failed: {e}", exc_info=True)
            return {
                'answer': "Error processing query.",
                'sources': [],
                'confidence': 0.0,
                'response_time_ms': int((time.time() - start_time) * 1000),
                'chunks_retrieved': 0
            }


# Global enhanced service instance
enhanced_rag_service = EnhancedRAGService()

# Maintain backward compatibility
rag_service = enhanced_rag_service