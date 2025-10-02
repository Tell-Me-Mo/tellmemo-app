"""Comprehensive tests for enhanced RAG services."""

import pytest
import asyncio
from unittest.mock import AsyncMock, Mock, patch
from datetime import datetime
from typing import List, Dict, Any

# Import services to test
from services.transcription.advanced_transcript_parser import (
    AdvancedTranscriptProcessor, SpeakerTurn, TopicSegment, 
    DecisionPoint, ActionItem, AdvancedTranscriptAnalysis,
    advanced_transcript_processor
)
from services.rag.intelligent_chunking import (
    IntelligentChunkingService, IntelligentChunk, ChunkType,
    ChunkingStrategy, intelligent_chunking_service
)
from services.rag.multi_query_retrieval import (
    MultiQueryRetrievalService, QueryIntent, QueryAnalysis,
    MultiQueryResults, multi_query_retrieval_service
)
from services.rag.hybrid_search import (
    HybridSearchService, SearchPipeline, SearchResult, SearchType,
    HybridSearchConfig, hybrid_search_service
)
from services.intelligence.meeting_intelligence import (
    MeetingIntelligenceService, MeetingIntelligenceReport,
    ParticipantInsight, EngagementLevel, meeting_intelligence_service
)
from services.enhanced_rag_service import (
    EnhancedRAGService, RAGStrategy, enhanced_rag_service
)

# Test data
SAMPLE_TRANSCRIPT = """
Meeting: Project Alpha Status Review
Participants: John Smith (PM), Sarah Johnson (Tech Lead), Mike Chen (Designer)
Duration: 45 minutes

MEETING TRANSCRIPT:
[09:00] John Smith: Good morning everyone. Let's start with the status update for Project Alpha.
[09:01] Sarah Johnson: We've completed the backend API development. All endpoints are tested and deployed to staging.
[09:03] Mike Chen: The UI mockups are ready and I've started on the implementation. Should be done by Friday.
[09:05] John Smith: Great progress. We need to decide on the launch timeline. I'm thinking next month.
[09:06] Sarah Johnson: That sounds reasonable. We should have everything tested by then.

KEY DECISIONS MADE:
1. Launch timeline set for next month
2. Backend deployment to staging approved
3. UI implementation deadline confirmed for Friday

ACTION ITEMS:
- Mike Chen: Complete UI implementation by Friday
- Sarah Johnson: Prepare production deployment plan
- John Smith: Schedule launch coordination meeting
"""

SAMPLE_SIMPLE_TRANSCRIPT = """
Team meeting about budget planning. 
John mentioned we need to reduce costs by 10%. 
Sarah suggested cutting travel expenses. 
Mike agreed to review vendor contracts.
"""


@pytest.fixture
def mock_nlp_models():
    """Mock NLP models to avoid dependency on actual model downloads."""
    with patch('spacy.load') as mock_spacy, \
         patch('sentence_transformers.SentenceTransformer') as mock_st, \
         patch('sentence_transformers.CrossEncoder') as mock_ce:
        
        # Mock spaCy
        mock_nlp = Mock()
        mock_nlp.return_value = mock_nlp
        mock_spacy.return_value = mock_nlp
        
        # Mock SentenceTransformer
        mock_st_instance = Mock()
        mock_st_instance.encode.return_value = [[0.1] * 768 for _ in range(10)]
        mock_st.return_value = mock_st_instance
        
        # Mock CrossEncoder
        mock_ce_instance = Mock()
        mock_ce_instance.predict.return_value = [0.8, 0.7, 0.6, 0.5, 0.4]
        mock_ce.return_value = mock_ce_instance
        
        yield {
            'spacy': mock_nlp,
            'sentence_transformer': mock_st_instance,
            'cross_encoder': mock_ce_instance
        }


class TestAdvancedTranscriptProcessor:
    """Tests for advanced transcript processing."""
    
    @pytest.mark.asyncio
    async def test_process_transcript_basic(self, mock_nlp_models):
        """Test basic transcript processing."""
        processor = AdvancedTranscriptProcessor()
        
        result = await processor.process_transcript(
            SAMPLE_TRANSCRIPT, "Test Meeting"
        )
        
        assert isinstance(result, AdvancedTranscriptAnalysis)
        assert result.original_transcript.title == "Test Meeting"
        assert len(result.speaker_turns) > 0
        assert len(result.topic_segments) > 0
        assert len(result.decision_points) > 0
        assert len(result.action_items) > 0
    
    @pytest.mark.asyncio 
    async def test_extract_speaker_turns(self, mock_nlp_models):
        """Test speaker turn extraction."""
        processor = AdvancedTranscriptProcessor()
        
        # Mock parsed transcript
        from services.transcription.transcript_parser import ParsedTranscript
        parsed = ParsedTranscript(
            title="Test",
            duration="30 min",
            participants=[{"name": "John Smith", "role": "PM"}],
            dialogue=[
                {"speaker": "John Smith", "timestamp": "09:00", "text": "Hello everyone"},
                {"speaker": "Sarah Johnson", "timestamp": "09:01", "text": "Good morning"}
            ],
            decisions=["Launch next month"],
            action_items=[{"assignee": "Mike", "task": "Complete UI"}],
            raw_content=SAMPLE_TRANSCRIPT,
            format_type="structured_text"
        )
        
        turns = await processor._extract_speaker_turns(parsed)
        
        assert len(turns) == 2
        assert turns[0].speaker == "John Smith"
        assert turns[0].text == "Hello everyone"
        assert turns[1].speaker == "Sarah Johnson"
    
    @pytest.mark.asyncio
    async def test_topic_segmentation_fallback(self, mock_nlp_models):
        """Test topic segmentation fallback when models unavailable."""
        processor = AdvancedTranscriptProcessor()
        processor.sentence_transformer = None  # Disable model
        
        # Create mock speaker turns
        turns = [
            SpeakerTurn(
                speaker="John", timestamp="09:00", text="Let's discuss the budget",
                duration_seconds=30, start_position=0, end_position=25,
                segment_id="turn_001", turn_index=0
            ),
            SpeakerTurn(
                speaker="Sarah", timestamp="09:01", text="The costs are too high",
                duration_seconds=25, start_position=25, end_position=45,
                segment_id="turn_002", turn_index=1
            )
        ]
        
        segments = await processor._perform_topic_segmentation(turns)
        
        assert len(segments) > 0
        assert all(isinstance(seg, TopicSegment) for seg in segments)
    
    @pytest.mark.asyncio
    async def test_decision_extraction(self, mock_nlp_models):
        """Test decision point extraction."""
        processor = AdvancedTranscriptProcessor()
        
        turns = [
            SpeakerTurn(
                speaker="John", timestamp="09:00", 
                text="We have decided to launch next month",
                duration_seconds=30, start_position=0, end_position=30,
                segment_id="turn_001", turn_index=0
            )
        ]
        
        segments = [
            TopicSegment(
                topic_id="topic_001", topic_name="Launch Planning",
                start_timestamp="09:00", end_timestamp="09:05",
                speakers=["John"], key_points=["Launch decision"],
                speaker_turns=turns, duration_seconds=300,
                semantic_score=0.8
            )
        ]
        
        decisions = await processor._extract_decision_points(turns, segments)
        
        assert len(decisions) > 0
        assert any("decided" in d.decision_text for d in decisions)


class TestIntelligentChunking:
    """Tests for intelligent chunking service."""
    
    @pytest.mark.asyncio
    async def test_chunk_meeting_content_basic(self, mock_nlp_models):
        """Test basic intelligent chunking."""
        service = IntelligentChunkingService()
        
        # Create mock transcript analysis
        analysis = self._create_mock_analysis()
        
        chunks = await service.chunk_meeting_content(analysis)
        
        assert len(chunks) > 0
        assert all(isinstance(chunk, IntelligentChunk) for chunk in chunks)
        assert any(chunk.chunk_type == ChunkType.SPEAKER_TURN for chunk in chunks)
    
    @pytest.mark.asyncio
    async def test_speaker_turn_chunking(self, mock_nlp_models):
        """Test speaker-turn aware chunking."""
        service = IntelligentChunkingService()
        
        analysis = self._create_mock_analysis()
        
        # Test speaker turn chunking specifically
        speaker_chunks = await service._chunk_by_speaker_turns(analysis)
        
        assert len(speaker_chunks) > 0
        assert all(chunk.chunk_type == ChunkType.SPEAKER_TURN for chunk in speaker_chunks)
        assert all(len(chunk.speakers_involved) > 0 for chunk in speaker_chunks)
    
    @pytest.mark.asyncio
    async def test_topic_based_chunking(self, mock_nlp_models):
        """Test topic-based chunking."""
        service = IntelligentChunkingService()
        
        analysis = self._create_mock_analysis()
        
        topic_chunks = await service._chunk_by_topics(analysis)
        
        assert len(topic_chunks) > 0
        assert all(chunk.chunk_type == ChunkType.TOPIC_SEGMENT for chunk in topic_chunks)
        assert all(chunk.topic_id is not None for chunk in topic_chunks)
    
    @pytest.mark.asyncio
    async def test_fallback_chunking(self, mock_nlp_models):
        """Test fallback chunking when advanced features fail."""
        service = IntelligentChunkingService()
        
        analysis = self._create_mock_analysis()
        
        # Test fallback
        fallback_chunks = await service._fallback_chunking(analysis)
        
        assert len(fallback_chunks) > 0
        assert all(chunk.chunk_id.startswith("fallback_") for chunk in fallback_chunks)
    
    def _create_mock_analysis(self):
        """Create mock transcript analysis for testing."""
        from services.transcription.transcript_parser import ParsedTranscript
        
        parsed = ParsedTranscript(
            title="Test Meeting",
            duration="30 min",
            participants=[{"name": "John", "role": "PM"}],
            dialogue=[{"speaker": "John", "timestamp": "09:00", "text": "Hello"}],
            decisions=["Launch next month"],
            action_items=[{"assignee": "Mike", "task": "Complete UI"}],
            raw_content=SAMPLE_TRANSCRIPT,
            format_type="structured_text"
        )
        
        speaker_turns = [
            SpeakerTurn(
                speaker="John", timestamp="09:00", text="Hello everyone, let's start the meeting",
                duration_seconds=30, start_position=0, end_position=50,
                segment_id="turn_001", turn_index=0
            )
        ]
        
        topic_segments = [
            TopicSegment(
                topic_id="topic_001", topic_name="Meeting Start",
                start_timestamp="09:00", end_timestamp="09:05",
                speakers=["John"], key_points=["Meeting introduction"],
                speaker_turns=speaker_turns, duration_seconds=300,
                semantic_score=0.8
            )
        ]
        
        return AdvancedTranscriptAnalysis(
            original_transcript=parsed,
            speaker_turns=speaker_turns,
            topic_segments=topic_segments,
            decision_points=[],
            action_items=[],
            meeting_outcome=None,
            temporal_relationships=[],
            participant_engagement={"John": {"engagement_score": 0.8}},
            meeting_statistics={"total_words": 100},
            processing_metadata={"processing_time_seconds": 1.0}
        )


class TestMultiQueryRetrieval:
    """Tests for multi-query retrieval service."""
    
    @pytest.mark.asyncio
    async def test_query_analysis(self, mock_nlp_models):
        """Test query analysis and intent classification."""
        service = MultiQueryRetrievalService()
        
        # Test decision query
        analysis = await service._analyze_query("What decisions were made in the last meeting?")
        
        assert isinstance(analysis, QueryAnalysis)
        assert analysis.intent == QueryIntent.DECISION_LOOKUP
        assert analysis.intent_confidence > 0.5
        assert len(analysis.keywords) > 0
    
    @pytest.mark.asyncio
    async def test_query_variations_generation(self, mock_nlp_models):
        """Test query variation generation."""
        service = MultiQueryRetrievalService()
        
        analysis = QueryAnalysis(
            original_query="Who is responsible for the API development?",
            intent=QueryIntent.PEOPLE,
            intent_confidence=0.8,
            entities=[],
            keywords=["responsible", "api", "development"],
            temporal_indicators=[],
            variations=[],
            complexity_score=0.6,
            requires_decomposition=False
        )
        
        variations = await service._generate_query_variations(analysis)
        
        assert len(variations) > 1
        assert variations[0].variation_type == 'original'
        assert any(var.variation_type == 'synonym' for var in variations)
    
    @pytest.mark.asyncio
    async def test_intent_classification(self, mock_nlp_models):
        """Test different query intent classifications."""
        service = MultiQueryRetrievalService()
        
        test_cases = [
            ("When is the deadline?", QueryIntent.TEMPORAL),
            ("Who is the project manager?", QueryIntent.PEOPLE),
            ("What was decided about the budget?", QueryIntent.DECISION_LOOKUP),
            ("What are the next action items?", QueryIntent.ACTION_ITEMS),
            ("Summarize the meeting", QueryIntent.SUMMARY)
        ]
        
        for query, expected_intent in test_cases:
            intent, confidence = service._classify_intent(query)
            assert intent == expected_intent or intent == QueryIntent.GENERAL  # Allow general as fallback
            assert 0 <= confidence <= 1
    
    @pytest.mark.asyncio
    @patch('services.multi_query_retrieval.embedding_service')
    @patch('services.multi_query_retrieval.vector_store')
    async def test_retrieve_with_multi_query(self, mock_vector_store, mock_embedding_service, mock_nlp_models):
        """Test full multi-query retrieval process."""
        service = MultiQueryRetrievalService()
        
        # Mock embedding service
        mock_embedding_service.generate_embedding = AsyncMock(return_value=[0.1] * 768)
        
        # Mock vector store
        mock_vector_store.search_vectors = AsyncMock(return_value=[
            {
                'id': 'chunk_001',
                'score': 0.9,
                'payload': {
                    'text': 'The API development is John\'s responsibility',
                    'title': 'Meeting Notes',
                    'content_type': 'discussion'
                }
            }
        ])
        
        result = await service.retrieve_with_multi_query(
            "Who is responsible for API development?",
            "project_123",
            max_results=10
        )
        
        assert isinstance(result, MultiQueryResults)
        assert len(result.deduplicated_results) > 0
        assert result.query_analysis.intent in [QueryIntent.PEOPLE, QueryIntent.GENERAL]


class TestHybridSearch:
    """Tests for hybrid search service."""
    
    @pytest.mark.asyncio
    @patch('services.hybrid_search.multi_query_retrieval_service')
    async def test_semantic_search(self, mock_multi_query, mock_nlp_models):
        """Test semantic search component."""
        service = HybridSearchService()
        
        # Mock multi-query results
        mock_multi_query.retrieve_with_multi_query = AsyncMock(return_value=Mock(
            deduplicated_results=[
                Mock(
                    chunk_id='chunk_001',
                    text='Sample text',
                    metadata={'title': 'Test Doc'},
                    score=0.9,
                    relevance_factors={'semantic_similarity': 0.9}
                )
            ]
        ))
        
        results = await service._semantic_search("test query", "project_123")
        
        assert len(results) > 0
        assert all(isinstance(r, SearchResult) for r in results)
        assert SearchType.SEMANTIC in results[0].search_types
    
    @pytest.mark.asyncio
    @patch('services.hybrid_search.vector_store')
    async def test_keyword_search(self, mock_vector_store, mock_nlp_models):
        """Test keyword search component."""
        service = HybridSearchService()
        
        # Mock document retrieval
        mock_vector_store.search_vectors = AsyncMock(return_value=[
            {
                'id': 'chunk_001',
                'payload': {
                    'text': 'The API development team discussed implementation details',
                    'title': 'Technical Meeting'
                }
            },
            {
                'id': 'chunk_002', 
                'payload': {
                    'text': 'Budget constraints require careful API planning',
                    'title': 'Budget Review'
                }
            }
        ])
        
        results = await service._keyword_search("API development", "project_123")
        
        assert len(results) > 0
        assert all(isinstance(r, SearchResult) for r in results)
        assert all(SearchType.KEYWORD in r.search_types for r in results)
    
    @pytest.mark.asyncio
    async def test_bm25_scoring(self, mock_nlp_models):
        """Test BM25 scoring algorithm."""
        service = HybridSearchService()
        
        # Mock document statistics
        service.total_documents = 100
        service.average_document_length = 200
        service.document_frequencies = {'api': 20, 'development': 30}
        
        query_terms = ['api', 'development']
        document = 'The API development team is working on the new features'
        
        score = service._calculate_bm25_score(query_terms, document)
        
        assert score > 0
        assert isinstance(score, float)
    
    @pytest.mark.asyncio
    async def test_cross_encoder_reranking(self, mock_nlp_models):
        """Test cross-encoder re-ranking."""
        service = HybridSearchService()
        
        # Create mock results
        results = [
            SearchResult(
                chunk_id='chunk_001',
                text='API development is in progress',
                metadata={'title': 'Progress Report'},
                semantic_score=0.8,
                keyword_score=0.7,
                hybrid_score=0.75
            ),
            SearchResult(
                chunk_id='chunk_002', 
                text='Budget planning meeting notes',
                metadata={'title': 'Budget Meeting'},
                semantic_score=0.6,
                keyword_score=0.5,
                hybrid_score=0.55
            )
        ]
        
        reranked = await service._cross_encoder_rerank(results, "API development progress")
        
        assert len(reranked) == len(results)
        assert all(hasattr(r, 'cross_encoder_score') for r in reranked)
        assert all(hasattr(r, 'final_score') for r in reranked)


class TestMeetingIntelligence:
    """Tests for meeting intelligence service."""
    
    @pytest.mark.asyncio
    async def test_analyze_meeting_intelligence(self, mock_nlp_models):
        """Test comprehensive meeting intelligence analysis."""
        service = MeetingIntelligenceService()
        
        with patch.object(service, '_initialize_models'):
            result = await service.analyze_meeting_intelligence(
                SAMPLE_TRANSCRIPT, "Test Meeting"
            )
        
        assert isinstance(result, MeetingIntelligenceReport)
        assert result.meeting_title == "Test Meeting"
        assert len(result.participant_insights) > 0
        assert len(result.thematic_insights) > 0
        assert result.overall_effectiveness_score >= 0
    
    @pytest.mark.asyncio
    async def test_participant_analysis(self, mock_nlp_models):
        """Test participant analysis."""
        service = MeetingIntelligenceService()
        
        # Create mock analysis
        analysis = self._create_mock_intelligence_analysis()
        
        insights = await service._analyze_participants(analysis)
        
        assert len(insights) > 0
        assert all(isinstance(insight, ParticipantInsight) for insight in insights)
        assert all(insight.engagement_level in EngagementLevel for insight in insights)
    
    @pytest.mark.asyncio
    async def test_engagement_classification(self, mock_nlp_models):
        """Test engagement level classification."""
        service = MeetingIntelligenceService()
        
        test_cases = [
            (0.9, EngagementLevel.VERY_HIGH),
            (0.7, EngagementLevel.HIGH), 
            (0.5, EngagementLevel.MEDIUM),
            (0.3, EngagementLevel.LOW),
            (0.1, EngagementLevel.VERY_LOW)
        ]
        
        for score, expected_level in test_cases:
            level = service._classify_engagement_level(score)
            assert level == expected_level
    
    def _create_mock_intelligence_analysis(self):
        """Create mock analysis for intelligence testing."""
        from services.transcription.transcript_parser import ParsedTranscript
        
        parsed = ParsedTranscript(
            title="Test Meeting",
            duration="30 min",
            participants=[{"name": "John Smith", "role": "PM"}],
            dialogue=[{"speaker": "John Smith", "timestamp": "09:00", "text": "Hello"}],
            decisions=["Launch next month"],
            action_items=[{"assignee": "Mike", "task": "Complete UI"}],
            raw_content=SAMPLE_TRANSCRIPT,
            format_type="structured_text"
        )
        
        return AdvancedTranscriptAnalysis(
            original_transcript=parsed,
            speaker_turns=[],
            topic_segments=[],
            decision_points=[],
            action_items=[],
            meeting_outcome=None,
            temporal_relationships=[],
            participant_engagement={
                "John Smith": {
                    "turn_count": 5,
                    "word_count": 150,
                    "engagement_score": 0.8,
                    "speaking_time_seconds": 300
                }
            },
            meeting_statistics={"total_words": 500},
            processing_metadata={"processing_time_seconds": 2.0}
        )


class TestEnhancedRAGService:
    """Tests for enhanced RAG service."""
    
    @pytest.mark.asyncio
    async def test_strategy_selection(self, mock_nlp_models):
        """Test automatic strategy selection."""
        service = EnhancedRAGService()
        
        test_cases = [
            ("What is the API status?", [RAGStrategy.BASIC, RAGStrategy.MULTI_QUERY]),
            ("Compare the performance metrics and analyze the correlation between user engagement and feature adoption", RAGStrategy.INTELLIGENT),
            ("Who decided what and when regarding the budget planning?", [RAGStrategy.HYBRID_SEARCH, RAGStrategy.INTELLIGENT]),
            ("Explain the concept", RAGStrategy.BASIC)
        ]
        
        for query, expected_strategies in test_cases:
            strategy = service._select_optimal_strategy(query)
            if isinstance(expected_strategies, list):
                assert strategy in expected_strategies
            else:
                assert strategy == expected_strategies
    
    @pytest.mark.asyncio
    @patch('services.enhanced_rag_service.embedding_service')
    @patch('services.enhanced_rag_service.vector_store')
    async def test_basic_rag_execution(self, mock_vector_store, mock_embedding_service, mock_nlp_models):
        """Test basic RAG strategy execution."""
        service = EnhancedRAGService()
        service.llm_client.client = None  # Use placeholder responses
        
        # Mock dependencies
        mock_embedding_service.generate_embedding = AsyncMock(return_value=[0.1] * 768)
        mock_vector_store.search_vectors = AsyncMock(return_value=[
            {
                'id': 'chunk_001',
                'score': 0.9,
                'payload': {
                    'text': 'The API development is progressing well',
                    'title': 'Status Report'
                }
            }
        ])
        
        result = await service._execute_basic_rag(
            "project_123",
            "What is the API status?",
            {"max_chunks": 10},
            None
        )
        
        assert 'answer' in result
        assert 'sources' in result
        assert 'confidence' in result
        assert result['chunks_retrieved'] > 0
    
    @pytest.mark.asyncio
    async def test_query_type_classification(self, mock_nlp_models):
        """Test query type classification."""
        service = EnhancedRAGService()
        
        test_cases = [
            ("When is the deadline?", "temporal"),
            ("Who is responsible?", "people"), 
            ("What was decided?", "decision"),
            ("What are the action items?", "action_items"),
            ("What is the status?", "status"),
            ("Compare the options", "analytical"),
            ("Summarize the meeting", "summary")
        ]
        
        for query, expected_type in test_cases:
            query_type = service._classify_query_type(query)
            assert query_type == expected_type
    
    @pytest.mark.asyncio
    async def test_enhanced_confidence_calculation(self, mock_nlp_models):
        """Test enhanced confidence score calculation."""
        service = EnhancedRAGService()
        
        chunks = [
            {'score': 0.9, 'title': 'Doc1', 'text': 'High quality content'},
            {'score': 0.8, 'title': 'Doc2', 'text': 'Good content'},
            {'score': 0.7, 'title': 'Doc3', 'text': 'Decent content'}
        ]
        
        # Test different strategies
        for strategy in ['basic', 'multi_query', 'hybrid_search', 'intelligent']:
            confidence = service._calculate_enhanced_confidence(chunks, strategy)
            assert 0 <= confidence <= 1
            
            # More advanced strategies should have higher confidence
            if strategy == 'intelligent':
                basic_confidence = service._calculate_enhanced_confidence(chunks, 'basic')
                assert confidence >= basic_confidence


class TestIntegrationScenarios:
    """Integration tests for complete RAG scenarios."""
    
    @pytest.mark.asyncio
    @patch('services.enhanced_rag_service.langfuse_service')
    async def test_end_to_end_rag_query(self, mock_langfuse, mock_nlp_models):
        """Test complete end-to-end RAG query."""
        # Mock Langfuse
        mock_langfuse.create_trace = Mock(return_value=Mock(id="trace_123"))
        mock_langfuse.create_span = Mock(return_value=Mock(end=Mock()))
        mock_langfuse.flush = Mock()
        
        service = EnhancedRAGService()
        service.llm_client.client = None  # Use placeholders
        
        with patch.multiple(
            'services.enhanced_rag_service',
            embedding_service=Mock(generate_embedding=AsyncMock(return_value=[0.1] * 768)),
            vector_store=Mock(search_vectors=AsyncMock(return_value=[
                {
                    'id': 'chunk_001',
                    'score': 0.9,
                    'payload': {
                        'text': 'The team decided to launch next month after thorough testing',
                        'title': 'Decision Meeting Notes',
                        'content_type': 'decision'
                    }
                }
            ]))
        ):
            result = await service.query_project(
                project_id="project_123",
                question="What decisions were made about the launch timeline?",
                user_id="user_456",
                strategy=RAGStrategy.INTELLIGENT
            )
        
        assert 'answer' in result
        assert 'sources' in result
        assert 'confidence' in result
        assert result['strategy_used'] == 'intelligent'
        assert result['chunks_retrieved'] > 0
    
    @pytest.mark.asyncio
    async def test_error_handling_and_fallbacks(self, mock_nlp_models):
        """Test error handling and fallback mechanisms."""
        service = EnhancedRAGService()
        
        # Test with invalid strategy
        with pytest.raises(ValueError):
            await service.query_project(
                project_id="project_123",
                question="Test question",
                strategy="invalid_strategy"  # This should cause an error
            )
    
    @pytest.mark.asyncio
    async def test_performance_with_large_context(self, mock_nlp_models):
        """Test performance with large context."""
        service = EnhancedRAGService()
        service.llm_client.client = None
        
        # Create many chunks to test context length limits
        many_chunks = []
        for i in range(50):
            many_chunks.append({
                'id': f'chunk_{i:03d}',
                'text': f'This is chunk number {i} with some content about the project ' * 10,
                'title': f'Document {i}',
                'score': 0.8 - (i * 0.01)  # Decreasing scores
            })
        
        response = await service._generate_response(
            "What is the project status?",
            many_chunks,
            None,
            "intelligent"
        )
        
        assert 'answer' in response
        assert len(response['answer']) > 0
        assert 'sources' in response
    
    @pytest.mark.asyncio
    async def test_configuration_integration(self, mock_nlp_models):
        """Test integration with configuration settings."""
        from config import get_settings
        
        settings = get_settings()
        
        # Verify new configuration options are available
        assert hasattr(settings, 'intelligent_chunk_size_words')
        assert hasattr(settings, 'semantic_search_weight')
        assert hasattr(settings, 'rag_auto_strategy_selection')
        assert hasattr(settings, 'enable_advanced_nlp')
        
        # Test configuration values
        assert settings.intelligent_chunk_size_words >= 400
        assert 0 <= settings.semantic_search_weight <= 1
        assert isinstance(settings.rag_auto_strategy_selection, bool)


# Additional test utilities
class TestUtils:
    """Utility functions for testing."""
    
    @staticmethod
    def create_sample_chunks(count: int = 5) -> List[Dict[str, Any]]:
        """Create sample chunks for testing."""
        chunks = []
        for i in range(count):
            chunks.append({
                'id': f'chunk_{i:03d}',
                'text': f'This is sample content for chunk {i} discussing project topics.',
                'title': f'Document {i}',
                'score': 0.9 - (i * 0.1),
                'metadata': {
                    'content_type': 'discussion',
                    'timestamp': '2024-01-01T10:00:00Z'
                }
            })
        return chunks
    
    @staticmethod
    def assert_rag_response_quality(response: Dict[str, Any]):
        """Assert that a RAG response meets quality standards."""
        # Check required fields
        required_fields = ['answer', 'sources', 'confidence', 'chunks_retrieved']
        for field in required_fields:
            assert field in response, f"Missing required field: {field}"
        
        # Check data types and ranges
        assert isinstance(response['answer'], str)
        assert len(response['answer']) > 0
        assert isinstance(response['sources'], list)
        assert isinstance(response['confidence'], (int, float))
        assert 0 <= response['confidence'] <= 1
        assert isinstance(response['chunks_retrieved'], int)
        assert response['chunks_retrieved'] >= 0


# Run specific test categories
if __name__ == "__main__":
    # Run tests with: python -m pytest backend/tests/test_enhanced_rag_services.py -v
    
    # Example of running specific test categories:
    # pytest backend/tests/test_enhanced_rag_services.py::TestAdvancedTranscriptProcessor -v
    # pytest backend/tests/test_enhanced_rag_services.py::TestEnhancedRAGService -v
    # pytest backend/tests/test_enhanced_rag_services.py::TestIntegrationScenarios -v
    
    print("Enhanced RAG Services Test Suite")
    print("Run with: python -m pytest backend/tests/test_enhanced_rag_services.py -v")
    print("\nTest Categories:")
    print("- TestAdvancedTranscriptProcessor: Advanced transcript processing")
    print("- TestIntelligentChunking: Intelligent chunking strategies")
    print("- TestMultiQueryRetrieval: Multi-query expansion and retrieval")
    print("- TestHybridSearch: Hybrid semantic + keyword search")
    print("- TestMeetingIntelligence: Meeting intelligence extraction")
    print("- TestEnhancedRAGService: Enhanced RAG orchestration")
    print("- TestIntegrationScenarios: End-to-end integration tests")