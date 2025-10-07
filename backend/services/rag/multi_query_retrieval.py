"""Multi-Query Retrieval Service with query expansion and intent classification."""

import re
import asyncio
from typing import List, Dict, Any, Optional, Tuple, Set
from dataclasses import dataclass
from collections import defaultdict
from enum import Enum
import json

import spacy
from sentence_transformers import SentenceTransformer

from utils.logger import get_logger, sanitize_for_log
from utils.monitoring import monitor_operation, monitor_sync_operation, MonitoringContext
from services.rag.embedding_service import embedding_service
from db.multi_tenant_vector_store import multi_tenant_vector_store
from models.project import Project

logger = get_logger(__name__)


class QueryIntent(Enum):
    """Types of query intents."""
    DECISION_LOOKUP = "decision_lookup"      # Looking for decisions made
    STATUS_UPDATE = "status_update"         # Asking about project status
    ACTION_ITEMS = "action_items"          # Looking for action items/tasks
    TEMPORAL = "temporal"                  # When/timeline questions
    PEOPLE = "people"                      # Who questions
    INFORMATIONAL = "informational"       # What/how questions
    SUMMARY = "summary"                    # Summarization requests
    PROBLEMS = "problems"                  # Issues/blockers/risks
    GENERAL = "general"                    # General queries


@dataclass
class QueryVariation:
    """Represents a query variation with metadata."""
    original_query: str
    variation_text: str
    variation_type: str  # 'synonym', 'paraphrase', 'expansion', 'decomposition'
    intent: QueryIntent
    confidence: float
    entities: List[Dict[str, Any]]
    keywords: List[str]


@dataclass
class QueryAnalysis:
    """Complete analysis of a query."""
    original_query: str
    intent: QueryIntent
    intent_confidence: float
    entities: List[Dict[str, Any]]
    keywords: List[str]
    temporal_indicators: List[str]
    variations: List[QueryVariation]
    complexity_score: float
    requires_decomposition: bool


@dataclass
class RetrievalResult:
    """Enhanced retrieval result with metadata."""
    chunk_id: str
    text: str
    score: float
    source_query: str  # Which query variation retrieved this
    source_variation_type: str
    metadata: Dict[str, Any]
    relevance_factors: Dict[str, float]


@dataclass
class MultiQueryResults:
    """Results from multi-query retrieval."""
    original_query: str
    query_analysis: QueryAnalysis
    all_results: List[RetrievalResult]
    deduplicated_results: List[RetrievalResult]
    result_diversity_score: float
    coverage_score: float
    total_queries_executed: int
    best_performing_variation: str


class MultiQueryRetrievalService:
    """Service for advanced multi-query retrieval with query expansion."""
    
    def __init__(self):
        """Initialize multi-query retrieval service."""
        from config import get_settings
        self.settings = get_settings()
        self.nlp_model = None
        self.sentence_transformer = None
        self.max_variations = 5
        self.max_results_per_query = 10
        self.similarity_threshold = self.settings.query_similarity_threshold  # Use config value
        self.deduplication_threshold = 0.9

        # Organization ID cache to avoid repeated DB lookups
        self._org_cache = {}  # project_id -> organization_id mapping

        # Query patterns for intent classification
        self.intent_patterns = {
            QueryIntent.DECISION_LOOKUP: [
                r'\b(decided?|decision|choose|chose|selected?|approved?|agreed?)\b',
                r'\b(concluded?|resolved?|determined?|final|settled)\b',
                r'\b(what.*decided|what.*conclusion|what.*outcome)\b'
            ],
            QueryIntent.STATUS_UPDATE: [
                r'\b(status|progress|update|current|state|where.*stand)\b',
                r'\b(how.*going|what.*status|latest|recent)\b'
            ],
            QueryIntent.ACTION_ITEMS: [
                r'\b(action|task|todo|next steps?|follow[- ]?up)\b',
                r'\b(responsibility|assigned?|owner|who.*will|what.*need)\b',
                r'\b(deliverables?|milestones?)\b'
            ],
            QueryIntent.TEMPORAL: [
                r'\b(when|timeline|schedule|deadline|date|time)\b',
                r'\b(before|after|during|by.*when|how long)\b'
            ],
            QueryIntent.PEOPLE: [
                r'\b(who|team|member|person|people|participant)\b',
                r'\b(assigned|responsible|owner|lead)\b'
            ],
            QueryIntent.INFORMATIONAL: [
                r'\b(what|how|why|explain|describe|detail)\b',
                r'\b(information|details?|specification)\b'
            ],
            QueryIntent.SUMMARY: [
                r'\b(summary|summarize|overview|key points?)\b',
                r'\b(main.*points?|highlights?|takeaways?)\b'
            ],
            QueryIntent.PROBLEMS: [
                r'\b(problem|issue|blocker|risk|concern|challenge)\b',
                r'\b(difficulty|obstacle|impediment)\b'
            ]
        }
        
        # Synonym dictionaries for query expansion
        self.synonyms = {
            'decided': ['concluded', 'resolved', 'determined', 'settled', 'agreed', 'chose'],
            'meeting': ['session', 'discussion', 'call', 'conference', 'gathering'],
            'team': ['group', 'members', 'participants', 'attendees'],
            'status': ['progress', 'state', 'situation', 'condition', 'update'],
            'problem': ['issue', 'blocker', 'concern', 'challenge', 'obstacle'],
            'action': ['task', 'todo', 'assignment', 'responsibility', 'deliverable'],
            'timeline': ['schedule', 'deadline', 'timeframe', 'duration'],
            'project': ['initiative', 'effort', 'work', 'development']
        }
        
        # Initialize models
        self._initialize_models()

    async def _get_organization_id(self, project_id: str) -> str:
        """Get organization ID with caching to avoid repeated DB lookups."""
        # Check cache first
        if project_id in self._org_cache:
            logger.debug(f"Organization ID cache hit for project {sanitize_for_log(project_id)}")
            return self._org_cache[project_id]

        # Cache miss - fetch from database
        logger.debug(f"Organization ID cache miss for project {sanitize_for_log(project_id)}")
        organization_id = None
        from db.database import get_db
        from models.project import Project

        async for session in get_db():
            project = await session.get(Project, project_id)
            if project:
                organization_id = str(project.organization_id)
                # Store in cache for future use
                self._org_cache[project_id] = organization_id
                logger.info(f"Cached organization {sanitize_for_log(organization_id)} for project {sanitize_for_log(project_id)}")
            break

        if not organization_id:
            logger.error(f"Could not determine organization for project {sanitize_for_log(project_id)}")
            raise ValueError(f"Could not determine organization for project {project_id}")

        return organization_id

    def _initialize_models(self):
        """Initialize NLP models for query processing."""
        try:
            # Load spaCy model for NER and linguistic processing
            try:
                self.nlp_model = spacy.load("en_core_web_sm")
                logger.info("Loaded spaCy model for multi-query retrieval")
            except OSError:
                logger.warning("spaCy model not available - entity extraction will be limited")
                self.nlp_model = None
            
            # Load sentence transformer for semantic similarity
            try:
                self.sentence_transformer = SentenceTransformer(self.settings.sentence_transformer_model)
                logger.info("Loaded SentenceTransformer for query similarity")
            except Exception as e:
                logger.warning(f"Failed to load SentenceTransformer: {e}")
                self.sentence_transformer = None
                
        except Exception as e:
            logger.error(f"Failed to initialize models for multi-query retrieval: {e}")
    
    @monitor_operation(
        operation_name="multi_query_retrieval",
        operation_type="search",
        capture_args=True,
        capture_result=True
    )
    async def retrieve_with_multi_query(
        self,
        query: str,
        project_id: str,
        max_results: int = 15
    ) -> MultiQueryResults:
        """
        Perform multi-query retrieval with expansion and intent analysis.
        
        Args:
            query: Original user query
            project_id: Project ID for filtering
            max_results: Maximum results to return
            
        Returns:
            MultiQueryResults with comprehensive retrieval data
        """
        logger.info(f"Starting multi-query retrieval for: '{sanitize_for_log(query)}'")
        
        try:
            # Step 1: Analyze the query
            query_analysis = await self._analyze_query(query)
            logger.debug(f"Query intent: {query_analysis.intent.value} (confidence: {query_analysis.intent_confidence:.2f})")
            
            # Step 2: Generate query variations
            variations = await self._generate_query_variations(query_analysis)
            logger.debug(f"Generated {len(variations)} query variations")
            
            # Step 3: Execute retrieval for each variation
            all_results = []
            for variation in variations:
                results = await self._execute_single_query(
                    variation, project_id, self.max_results_per_query
                )
                all_results.extend(results)
            
            # Step 4: Deduplicate and merge results
            deduplicated_results = await self._deduplicate_results(all_results)
            logger.info(f"📝 Deduplication: {len(all_results)} results -> {len(deduplicated_results)} unique results")
            if deduplicated_results:
                scores = [r.score for r in deduplicated_results]
                logger.info(f"📊 Deduplicated scores: min={min(scores):.3f}, max={max(scores):.3f}, avg={sum(scores)/len(scores):.3f}")
            
            # Step 5: Score and rank final results
            ranked_results = await self._score_and_rank_results(
                deduplicated_results, query_analysis, max_results
            )
            
            # Step 6: Calculate quality metrics
            diversity_score = self._calculate_diversity_score(ranked_results)
            coverage_score = self._calculate_coverage_score(ranked_results, query_analysis)
            best_variation = self._find_best_variation(variations, all_results)
            
            results = MultiQueryResults(
                original_query=query,
                query_analysis=query_analysis,
                all_results=all_results,
                deduplicated_results=ranked_results,
                result_diversity_score=diversity_score,
                coverage_score=coverage_score,
                total_queries_executed=len(variations),
                best_performing_variation=best_variation
            )
            
            logger.info(f"Multi-query retrieval completed: {len(ranked_results)} final results, "
                       f"diversity: {diversity_score:.2f}, coverage: {coverage_score:.2f}")
            
            return results
            
        except Exception as e:
            logger.error(f"Multi-query retrieval failed: {e}")
            # Fallback to simple retrieval
            return await self._fallback_retrieval(query, project_id, max_results)
    
    @monitor_operation(
        operation_name="query_analysis",
        operation_type="analysis",
        capture_args=False,
        capture_result=True
    )
    async def _analyze_query(self, query: str) -> QueryAnalysis:
        """Analyze query to determine intent, extract entities, and identify complexity."""
        # Classify intent
        intent, intent_confidence = self._classify_intent(query)
        
        # Extract entities using NLP
        entities = await self._extract_entities(query)
        
        # Extract keywords
        keywords = self._extract_keywords(query)
        
        # Find temporal indicators
        temporal_indicators = self._extract_temporal_indicators(query)
        
        # Calculate complexity score
        complexity_score = self._calculate_query_complexity(query, entities, keywords)
        
        # Determine if decomposition is needed
        requires_decomposition = complexity_score > 0.7 and len(keywords) > 5
        
        return QueryAnalysis(
            original_query=query,
            intent=intent,
            intent_confidence=intent_confidence,
            entities=entities,
            keywords=keywords,
            temporal_indicators=temporal_indicators,
            variations=[],  # Will be filled later
            complexity_score=complexity_score,
            requires_decomposition=requires_decomposition
        )
    
    @monitor_sync_operation(
        operation_name="intent_classification",
        operation_type="analysis"
    )
    def _classify_intent(self, query: str) -> Tuple[QueryIntent, float]:
        """Classify query intent using pattern matching."""
        query_lower = query.lower()
        intent_scores = defaultdict(float)
        
        # Score each intent based on pattern matches
        for intent, patterns in self.intent_patterns.items():
            for pattern in patterns:
                matches = len(re.findall(pattern, query_lower))
                if matches > 0:
                    intent_scores[intent] += matches * 0.3
        
        # Boost scores based on question words
        question_words = {
            'what': [QueryIntent.INFORMATIONAL, QueryIntent.DECISION_LOOKUP],
            'when': [QueryIntent.TEMPORAL],
            'who': [QueryIntent.PEOPLE],
            'how': [QueryIntent.INFORMATIONAL, QueryIntent.STATUS_UPDATE],
            'why': [QueryIntent.INFORMATIONAL],
            'where': [QueryIntent.STATUS_UPDATE]
        }
        
        for word, intents in question_words.items():
            if word in query_lower:
                for intent in intents:
                    intent_scores[intent] += 0.2
        
        # Determine best intent
        if intent_scores:
            best_intent = max(intent_scores, key=intent_scores.get)
            confidence = min(intent_scores[best_intent], 0.95)
        else:
            best_intent = QueryIntent.GENERAL
            confidence = 0.5
        
        return best_intent, confidence
    
    async def _extract_entities(self, query: str) -> List[Dict[str, Any]]:
        """Extract named entities from query."""
        entities = []
        
        if self.nlp_model:
            try:
                doc = self.nlp_model(query)
                for ent in doc.ents:
                    entities.append({
                        'text': ent.text,
                        'label': ent.label_,
                        'start': ent.start_char,
                        'end': ent.end_char,
                        'confidence': 0.8  # Default confidence
                    })
            except Exception as e:
                logger.warning(f"NER extraction failed: {e}")
        
        # Fallback entity extraction using patterns
        if not entities:
            entities = self._extract_entities_with_patterns(query)
        
        return entities
    
    def _extract_entities_with_patterns(self, query: str) -> List[Dict[str, Any]]:
        """Extract entities using regex patterns."""
        entities = []
        
        # Date patterns
        date_patterns = [
            r'\b(monday|tuesday|wednesday|thursday|friday|saturday|sunday)\b',
            r'\b(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})\b',
            r'\b(january|february|march|april|may|june|july|august|september|october|november|december)\s+\d{1,2}\b',
            r'\b(today|yesterday|tomorrow|last week|next week|this week)\b'
        ]
        
        for pattern in date_patterns:
            matches = re.finditer(pattern, query, re.IGNORECASE)
            for match in matches:
                entities.append({
                    'text': match.group(0),
                    'label': 'DATE',
                    'start': match.start(),
                    'end': match.end(),
                    'confidence': 0.7
                })
        
        # Person name patterns (simple heuristic)
        name_pattern = r'\b[A-Z][a-z]+\s+[A-Z][a-z]+\b'
        matches = re.finditer(name_pattern, query)
        for match in matches:
            entities.append({
                'text': match.group(0),
                'label': 'PERSON',
                'start': match.start(),
                'end': match.end(),
                'confidence': 0.6
            })
        
        return entities
    
    def _extract_keywords(self, query: str) -> List[str]:
        """Extract important keywords from query."""
        # Remove stop words and extract meaningful terms
        stop_words = {
            'a', 'an', 'and', 'are', 'as', 'at', 'be', 'by', 'for', 'from',
            'has', 'he', 'in', 'is', 'it', 'its', 'of', 'on', 'that', 'the',
            'to', 'was', 'will', 'with', 'what', 'when', 'where', 'who', 'how',
            'i', 'we', 'you', 'they', 'me', 'us', 'him', 'her', 'them'
        }
        
        # Clean and tokenize
        cleaned_query = re.sub(r'[^\w\s]', ' ', query.lower())
        words = cleaned_query.split()
        
        # Filter keywords
        keywords = []
        for word in words:
            if (len(word) > 2 and 
                word not in stop_words and 
                not word.isdigit()):
                keywords.append(word)
        
        return list(set(keywords))  # Remove duplicates
    
    def _extract_temporal_indicators(self, query: str) -> List[str]:
        """Extract temporal indicators from query."""
        temporal_patterns = [
            r'\b(when|during|before|after|by|until|since)\b',
            r'\b(today|yesterday|tomorrow|now|currently)\b',
            r'\b(last|next|this|previous)\s+(week|month|quarter|year)\b',
            r'\b(deadline|due|schedule|timeline)\b',
            r'\b\d{1,2}:\d{2}\b',  # Time patterns
            r'\b\d{1,2}[/-]\d{1,2}\b'  # Date patterns
        ]
        
        indicators = []
        for pattern in temporal_patterns:
            matches = re.findall(pattern, query.lower())
            indicators.extend(matches)
        
        return list(set(indicators))
    
    def _calculate_query_complexity(
        self,
        query: str,
        entities: List[Dict[str, Any]],
        keywords: List[str]
    ) -> float:
        """Calculate complexity score for query."""
        base_score = 0.3
        
        # Length factor
        word_count = len(query.split())
        if word_count > 10:
            base_score += 0.2
        if word_count > 20:
            base_score += 0.2
        
        # Entity factor
        base_score += len(entities) * 0.1
        
        # Keyword diversity factor
        base_score += len(keywords) * 0.05
        
        # Multiple question words
        question_words = ['what', 'when', 'who', 'where', 'why', 'how']
        question_count = sum(1 for word in question_words if word in query.lower())
        if question_count > 1:
            base_score += 0.2
        
        # Logical connectors
        connectors = ['and', 'or', 'but', 'also', 'additionally', 'furthermore']
        connector_count = sum(1 for conn in connectors if conn in query.lower())
        base_score += connector_count * 0.1
        
        return min(base_score, 1.0)
    
    @monitor_operation(
        operation_name="query_variation_generation",
        operation_type="analysis",
        capture_args=False,
        capture_result=True
    )
    async def _generate_query_variations(self, analysis: QueryAnalysis) -> List[QueryVariation]:
        """Generate multiple query variations for comprehensive retrieval."""
        variations = []
        original_query = analysis.original_query
        
        # Add original query as first variation
        original_variation = QueryVariation(
            original_query=original_query,
            variation_text=original_query,
            variation_type='original',
            intent=analysis.intent,
            confidence=1.0,
            entities=analysis.entities,
            keywords=analysis.keywords
        )
        variations.append(original_variation)
        
        # Generate synonym variations
        synonym_variations = self._generate_synonym_variations(analysis)
        variations.extend(synonym_variations[:2])  # Limit to top 2
        
        # Generate paraphrase variations
        paraphrase_variations = self._generate_paraphrase_variations(analysis)
        variations.extend(paraphrase_variations[:2])  # Limit to top 2
        
        # Generate expansion variations
        expansion_variations = self._generate_expansion_variations(analysis)
        variations.extend(expansion_variations[:1])  # Limit to top 1
        
        # Generate decomposed variations for complex queries
        if analysis.requires_decomposition:
            decomposed_variations = self._generate_decomposed_variations(analysis)
            variations.extend(decomposed_variations[:2])  # Limit to top 2
        
        # Limit total variations
        analysis.variations = variations[:self.max_variations]
        
        logger.debug(f"Generated {len(analysis.variations)} query variations:")
        for var in analysis.variations:
            logger.debug(f"  {var.variation_type}: '{var.variation_text}'")
        
        return analysis.variations
    
    def _generate_synonym_variations(self, analysis: QueryAnalysis) -> List[QueryVariation]:
        """Generate variations using synonyms."""
        variations = []
        original = analysis.original_query.lower()
        
        # Try replacing each keyword with synonyms
        for keyword in analysis.keywords:
            if keyword in self.synonyms:
                for synonym in self.synonyms[keyword][:2]:  # Limit synonyms
                    variation_text = original.replace(keyword, synonym)
                    if variation_text != original:
                        variation = QueryVariation(
                            original_query=analysis.original_query,
                            variation_text=variation_text,
                            variation_type='synonym',
                            intent=analysis.intent,
                            confidence=0.8,
                            entities=analysis.entities,
                            keywords=analysis.keywords
                        )
                        variations.append(variation)
        
        return variations[:3]  # Limit variations
    
    def _generate_paraphrase_variations(self, analysis: QueryAnalysis) -> List[QueryVariation]:
        """Generate paraphrased variations."""
        variations = []
        original = analysis.original_query
        
        # Intent-based paraphrasing
        if analysis.intent == QueryIntent.DECISION_LOOKUP:
            paraphrases = [
                f"what was decided about {' '.join(analysis.keywords)}",
                f"what conclusions were reached regarding {' '.join(analysis.keywords[:3])}",
                f"decisions made about {' '.join(analysis.keywords[:3])}"
            ]
        elif analysis.intent == QueryIntent.ACTION_ITEMS:
            paraphrases = [
                f"action items for {' '.join(analysis.keywords[:3])}",
                f"tasks related to {' '.join(analysis.keywords[:3])}",
                f"next steps for {' '.join(analysis.keywords[:3])}"
            ]
        elif analysis.intent == QueryIntent.STATUS_UPDATE:
            paraphrases = [
                f"current status of {' '.join(analysis.keywords[:3])}",
                f"progress on {' '.join(analysis.keywords[:3])}",
                f"latest update about {' '.join(analysis.keywords[:3])}"
            ]
        elif analysis.intent == QueryIntent.PEOPLE:
            paraphrases = [
                f"who is involved in {' '.join(analysis.keywords[:3])}",
                f"team members for {' '.join(analysis.keywords[:3])}",
                f"participants in {' '.join(analysis.keywords[:3])}"
            ]
        else:
            # General paraphrasing
            paraphrases = [
                f"information about {' '.join(analysis.keywords[:3])}",
                f"details on {' '.join(analysis.keywords[:3])}"
            ]
        
        for paraphrase in paraphrases[:2]:  # Limit paraphrases
            if paraphrase.lower() != original.lower():
                variation = QueryVariation(
                    original_query=original,
                    variation_text=paraphrase,
                    variation_type='paraphrase',
                    intent=analysis.intent,
                    confidence=0.7,
                    entities=analysis.entities,
                    keywords=analysis.keywords
                )
                variations.append(variation)
        
        return variations
    
    def _generate_expansion_variations(self, analysis: QueryAnalysis) -> List[QueryVariation]:
        """Generate expanded variations with additional context."""
        variations = []
        original = analysis.original_query
        
        # Add context based on intent
        if analysis.intent == QueryIntent.DECISION_LOOKUP:
            expansions = [
                f"{original} meeting outcomes decisions",
                f"{original} conclusions agreements"
            ]
        elif analysis.intent == QueryIntent.ACTION_ITEMS:
            expansions = [
                f"{original} tasks assignments responsibilities",
                f"{original} deliverables next steps"
            ]
        elif analysis.intent == QueryIntent.TEMPORAL:
            expansions = [
                f"{original} timeline schedule deadline",
                f"{original} dates timeframe"
            ]
        else:
            # General expansion with related terms
            expansions = [
                f"{original} discussion meeting content"
            ]
        
        for expansion in expansions[:1]:  # Limit expansions
            variation = QueryVariation(
                original_query=original,
                variation_text=expansion,
                variation_type='expansion',
                intent=analysis.intent,
                confidence=0.6,
                entities=analysis.entities,
                keywords=analysis.keywords
            )
            variations.append(variation)
        
        return variations
    
    def _generate_decomposed_variations(self, analysis: QueryAnalysis) -> List[QueryVariation]:
        """Generate decomposed variations for complex queries."""
        variations = []
        
        # Split complex queries into simpler components
        if len(analysis.keywords) > 5:
            # Create variations focusing on different keyword groups
            keyword_groups = [
                analysis.keywords[:3],
                analysis.keywords[2:5],
                analysis.keywords[-3:]
            ]
            
            for i, group in enumerate(keyword_groups):
                if group:
                    variation_text = ' '.join(group)
                    variation = QueryVariation(
                        original_query=analysis.original_query,
                        variation_text=variation_text,
                        variation_type='decomposition',
                        intent=analysis.intent,
                        confidence=0.5,
                        entities=analysis.entities,
                        keywords=group
                    )
                    variations.append(variation)
        
        return variations[:2]  # Limit decompositions
    
    @monitor_operation(
        operation_name="single_query_execution",
        operation_type="search",
        capture_args=False,
        capture_result=True
    )
    async def _execute_single_query(
        self,
        variation: QueryVariation,
        project_id: str,
        max_results: int
    ) -> List[RetrievalResult]:
        """Execute retrieval for a single query variation."""
        try:
            # Generate embedding for the variation
            embedding = await embedding_service.generate_embedding(variation.variation_text)
            
            # Search vector store
            # Get organization_id using cache
            organization_id = await self._get_organization_id(project_id)

            # Check if we should use two-stage search
            if self.settings.enable_mrl and self.settings.rag_use_two_stage_search:
                logger.info(f"Using two-stage MRL search for variation: '{variation.variation_text[:30]}...'")
                search_results = await multi_tenant_vector_store.search_vectors_two_stage(
                    organization_id=organization_id,
                    query_vector=embedding,
                    initial_limit=max_results * 3,
                    final_limit=max_results,
                    score_threshold=self.similarity_threshold,
                    filter_dict={"project_id": project_id}
                )
            else:
                search_results = await multi_tenant_vector_store.search_vectors(
                    organization_id=organization_id,
                    query_vector=embedding,
                    limit=max_results,
                    score_threshold=self.similarity_threshold,
                    filter_dict={"project_id": project_id}
                )

            # Log score distribution for debugging
            if search_results:
                scores = [r['score'] for r in search_results]
                logger.info(f"Search scores for '{variation.variation_text[:30]}...': "
                          f"min={min(scores):.3f}, max={max(scores):.3f}, "
                          f"avg={sum(scores)/len(scores):.3f}, "
                          f"threshold={self.similarity_threshold}")

            # Convert to RetrievalResult format
            results = []
            for result in search_results:
                retrieval_result = RetrievalResult(
                    chunk_id=result['id'],
                    text=result['payload'].get('text', ''),
                    score=result['score'],
                    source_query=variation.variation_text,
                    source_variation_type=variation.variation_type,
                    metadata=result['payload'],
                    relevance_factors=self._calculate_relevance_factors(
                        result, variation
                    )
                )
                results.append(retrieval_result)

            logger.debug(f"Retrieved {len(results)} results for variation: '{variation.variation_text}'")
            return results
            
        except Exception as e:
            logger.error(f"Query execution failed for '{variation.variation_text}': {e}")
            return []
    
    def _calculate_relevance_factors(
        self,
        search_result: Dict[str, Any],
        variation: QueryVariation
    ) -> Dict[str, float]:
        """Calculate relevance factors for result ranking."""
        factors = {
            'semantic_similarity': search_result['score'],
            'intent_match': 0.5,  # Default
            'entity_overlap': 0.0,
            'keyword_match': 0.0
        }
        
        result_text = search_result['payload'].get('text', '').lower()
        
        # Calculate keyword match score
        matching_keywords = sum(
            1 for keyword in variation.keywords 
            if keyword.lower() in result_text
        )
        factors['keyword_match'] = (
            matching_keywords / len(variation.keywords) 
            if variation.keywords else 0
        )
        
        # Calculate entity overlap (if entities are present)
        matching_entities = sum(
            1 for entity in variation.entities
            if entity['text'].lower() in result_text
        )
        factors['entity_overlap'] = (
            matching_entities / len(variation.entities)
            if variation.entities else 0
        )
        
        # Intent-based scoring
        if variation.intent == QueryIntent.DECISION_LOOKUP:
            decision_indicators = ['decided', 'decision', 'concluded', 'agreed']
            factors['intent_match'] = (
                0.8 if any(indicator in result_text for indicator in decision_indicators) else 0.3
            )
        elif variation.intent == QueryIntent.ACTION_ITEMS:
            action_indicators = ['action', 'task', 'will', 'should', 'assigned']
            factors['intent_match'] = (
                0.8 if any(indicator in result_text for indicator in action_indicators) else 0.3
            )
        
        return factors
    
    @monitor_operation(
        operation_name="result_deduplication",
        operation_type="analysis",
        capture_args=False,
        capture_result=True
    )
    async def _deduplicate_results(
        self,
        results: List[RetrievalResult]
    ) -> List[RetrievalResult]:
        """Remove duplicate results using semantic similarity."""
        if not results or not self.sentence_transformer:
            return results
        
        try:
            # Generate embeddings for all result texts
            texts = [result.text for result in results]
            embeddings = self.sentence_transformer.encode(texts)
            
            # Find duplicates using similarity threshold
            deduplicated = []
            used_indices = set()
            
            for i, result in enumerate(results):
                if i in used_indices:
                    continue
                
                deduplicated.append(result)
                used_indices.add(i)
                
                # Mark similar results as used
                for j in range(i + 1, len(results)):
                    if j not in used_indices:
                        similarity = self._cosine_similarity(embeddings[i], embeddings[j])
                        if similarity > self.deduplication_threshold:
                            used_indices.add(j)
                            # Keep the higher scoring result
                            if results[j].score > result.score:
                                deduplicated[-1] = results[j]
            
            return deduplicated
            
        except Exception as e:
            logger.error(f"Deduplication failed: {e}")
            # Fallback to simple deduplication by chunk_id
            seen_ids = set()
            deduplicated = []
            for result in results:
                if result.chunk_id not in seen_ids:
                    deduplicated.append(result)
                    seen_ids.add(result.chunk_id)
            return deduplicated
    
    async def _score_and_rank_results(
        self,
        results: List[RetrievalResult],
        analysis: QueryAnalysis,
        max_results: int
    ) -> List[RetrievalResult]:
        """Score and rank results for final presentation."""
        # Calculate composite scores
        for result in results:
            composite_score = self._calculate_composite_score(result, analysis)
            result.score = composite_score
        
        # Sort by composite score
        ranked_results = sorted(results, key=lambda x: x.score, reverse=True)
        
        return ranked_results[:max_results]
    
    def _calculate_composite_score(
        self,
        result: RetrievalResult,
        analysis: QueryAnalysis
    ) -> float:
        """Calculate composite relevance score."""
        factors = result.relevance_factors
        
        # Weight different factors based on query intent
        if analysis.intent == QueryIntent.DECISION_LOOKUP:
            weights = {
                'semantic_similarity': 0.4,
                'intent_match': 0.3,
                'keyword_match': 0.2,
                'entity_overlap': 0.1
            }
        elif analysis.intent == QueryIntent.ACTION_ITEMS:
            weights = {
                'semantic_similarity': 0.4,
                'intent_match': 0.3,
                'keyword_match': 0.2,
                'entity_overlap': 0.1
            }
        else:
            # Default weighting
            weights = {
                'semantic_similarity': 0.5,
                'intent_match': 0.2,
                'keyword_match': 0.2,
                'entity_overlap': 0.1
            }
        
        # Calculate weighted score
        composite_score = sum(
            factors.get(factor, 0) * weight
            for factor, weight in weights.items()
        )
        
        # Boost for high-confidence query variations
        if result.source_variation_type == 'original':
            composite_score *= 1.1
        elif result.source_variation_type == 'synonym':
            composite_score *= 1.05
        
        return min(composite_score, 1.0)
    
    def _calculate_diversity_score(self, results: List[RetrievalResult]) -> float:
        """Calculate diversity score for result set."""
        if len(results) <= 1:
            return 0.0
        
        # Simple diversity based on source variation types
        variation_types = set(result.source_variation_type for result in results)
        type_diversity = len(variation_types) / len(results)
        
        # Content diversity (simplified)
        if self.sentence_transformer and len(results) > 1:
            try:
                texts = [result.text[:200] for result in results]  # Limit text length
                embeddings = self.sentence_transformer.encode(texts)
                
                # Calculate average pairwise similarity
                similarities = []
                for i in range(len(embeddings)):
                    for j in range(i + 1, len(embeddings)):
                        sim = self._cosine_similarity(embeddings[i], embeddings[j])
                        similarities.append(sim)
                
                avg_similarity = sum(similarities) / len(similarities)
                content_diversity = 1.0 - avg_similarity  # Lower similarity = higher diversity
                
                return (type_diversity + content_diversity) / 2
            except Exception:
                return type_diversity
        
        return type_diversity
    
    def _calculate_coverage_score(
        self,
        results: List[RetrievalResult],
        analysis: QueryAnalysis
    ) -> float:
        """Calculate how well results cover the query intent."""
        if not results or not analysis.keywords:
            return 0.0
        
        # Check coverage of keywords across all results
        all_result_text = ' '.join(result.text.lower() for result in results)
        covered_keywords = sum(
            1 for keyword in analysis.keywords
            if keyword.lower() in all_result_text
        )
        
        keyword_coverage = covered_keywords / len(analysis.keywords)
        
        # Check coverage of entities
        entity_coverage = 0.0
        if analysis.entities:
            covered_entities = sum(
                1 for entity in analysis.entities
                if entity['text'].lower() in all_result_text
            )
            entity_coverage = covered_entities / len(analysis.entities)
        
        # Combine coverage metrics
        return (keyword_coverage + entity_coverage) / 2
    
    def _find_best_variation(
        self,
        variations: List[QueryVariation],
        results: List[RetrievalResult]
    ) -> str:
        """Find the best performing query variation."""
        variation_scores = defaultdict(list)
        
        # Group results by variation
        for result in results:
            variation_scores[result.source_query].append(result.score)
        
        # Calculate average score per variation
        best_variation = variations[0].variation_text
        best_avg_score = 0.0
        
        for variation_text, scores in variation_scores.items():
            if scores:
                avg_score = sum(scores) / len(scores)
                if avg_score > best_avg_score:
                    best_avg_score = avg_score
                    best_variation = variation_text
        
        return best_variation
    
    def _cosine_similarity(self, a, b) -> float:
        """Calculate cosine similarity between vectors."""
        import numpy as np
        return np.dot(a, b) / (np.linalg.norm(a) * np.linalg.norm(b))
    
    async def _fallback_retrieval(
        self,
        query: str,
        project_id: str,
        max_results: int
    ) -> MultiQueryResults:
        """Fallback to simple retrieval if multi-query fails."""
        logger.warning("Using fallback retrieval for multi-query service")
        
        try:
            # Simple analysis
            intent, confidence = self._classify_intent(query)
            keywords = self._extract_keywords(query)
            
            analysis = QueryAnalysis(
                original_query=query,
                intent=intent,
                intent_confidence=confidence,
                entities=[],
                keywords=keywords,
                temporal_indicators=[],
                variations=[],
                complexity_score=0.5,
                requires_decomposition=False
            )
            
            # Simple retrieval
            embedding = await embedding_service.generate_embedding(query)
            # Get organization_id
            from db.database import get_db
            organization_id = None
            # Get organization_id using cache
            organization_id = await self._get_organization_id(project_id)

            # Check if we should use two-stage search
            if self.settings.enable_mrl and self.settings.rag_use_two_stage_search:
                logger.info(f"Using two-stage MRL search for variation: '{variation.variation_text[:30]}...'")
                search_results = await multi_tenant_vector_store.search_vectors_two_stage(
                    organization_id=organization_id,
                    query_vector=embedding,
                    initial_limit=max_results * 3,
                    final_limit=max_results,
                    score_threshold=self.similarity_threshold,
                    filter_dict={"project_id": project_id}
                )
            else:
                search_results = await multi_tenant_vector_store.search_vectors(
                    organization_id=organization_id,
                    query_vector=embedding,
                    limit=max_results,
                    score_threshold=self.similarity_threshold,
                    filter_dict={"project_id": project_id}
                )
            
            # Convert results
            results = []
            for result in search_results:
                retrieval_result = RetrievalResult(
                    chunk_id=result['id'],
                    text=result['payload'].get('text', ''),
                    score=result['score'],
                    source_query=query,
                    source_variation_type='original',
                    metadata=result['payload'],
                    relevance_factors={'semantic_similarity': result['score']}
                )
                results.append(retrieval_result)
            
            return MultiQueryResults(
                original_query=query,
                query_analysis=analysis,
                all_results=results,
                deduplicated_results=results,
                result_diversity_score=0.5,
                coverage_score=0.5,
                total_queries_executed=1,
                best_performing_variation=query
            )
            
        except Exception as e:
            logger.error(f"Fallback retrieval failed: {e}")
            raise


# Global service instance
multi_query_retrieval_service = MultiQueryRetrievalService()