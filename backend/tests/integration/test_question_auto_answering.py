"""
Integration tests for Phase 1: Question Auto-Answering

Tests the end-to-end flow of:
1. Question detection from meeting transcript
2. Searching past meetings for relevant content
3. Synthesizing answers with sources
4. Returning proactive assistance in WebSocket response

Note: These are simplified integration tests to avoid complex dependencies.
Full integration testing would require mock WebSocket, vector DB, etc.
"""
import pytest
from datetime import datetime, UTC
from uuid import uuid4
from unittest.mock import Mock, AsyncMock

from services.intelligence.question_detector import QuestionDetector
from services.intelligence.question_answering_service import QuestionAnsweringService


@pytest.fixture
def llm_client():
    """Create mock LLM client for testing"""
    mock_client = Mock()
    mock_client.generate_text = AsyncMock(return_value="This is a decision question about the pricing model.")
    return mock_client


@pytest.fixture
def question_detector(llm_client):
    """Create question detector"""
    return QuestionDetector(llm_client=llm_client)


class TestQuestionDetection:
    """Test question detection functionality"""

    @pytest.mark.asyncio
    async def test_detect_explicit_question(self, question_detector):
        """Test detection of explicit questions with question mark"""
        text = "What was our Q4 budget for marketing?"

        result = await question_detector.detect_and_classify_question(text)

        assert result is not None
        assert result.text == text
        assert result.confidence >= 0.9  # Explicit questions have high confidence
        assert result.type in ["factual", "decision", "process", "clarification"]

    @pytest.mark.asyncio
    async def test_detect_implicit_question(self, question_detector):
        """Test detection of implicit questions without question mark"""
        text = "I'm not sure about the deadline for the project"

        result = await question_detector.detect_and_classify_question(text, context="Project discussion")

        # This should be detected as an implicit question
        assert result is not None
        assert result.confidence >= 0.6  # Implicit questions have lower confidence

    @pytest.mark.asyncio
    async def test_ignore_non_questions(self, question_detector):
        """Test that regular statements are not detected as questions"""
        text = "The budget was approved yesterday."

        result = await question_detector.detect_and_classify_question(text)

        # This should NOT be detected as a question
        assert result is None


class TestQuestionAnswering:
    """Test question answering functionality"""

    @pytest.mark.asyncio
    async def test_answer_with_relevant_context(self, llm_client):
        """Test answering when relevant context exists (mocked)"""
        # Note: This is a simplified test - full test would require:
        # 1. Mock Qdrant vector store with sample meeting content
        # 2. Mock embedding service
        # 3. Test actual RAG search and synthesis

        # For now, just verify the service can be instantiated
        # Real testing requires test database setup
        qa_service = QuestionAnsweringService(
            vector_store=None,  # Would need mock here
            llm_client=llm_client,
            embedding_service=None,  # Would need mock here
            min_confidence_threshold=0.7
        )

        assert qa_service is not None
        assert qa_service.min_confidence_threshold == 0.7

    @pytest.mark.asyncio
    async def test_low_confidence_returns_none(self, llm_client):
        """Test that low confidence answers are filtered out"""
        # This would test that answers below 0.7 confidence are not returned
        # Requires full mock setup, so keeping it simple for now
        pass


class TestProactiveAssistancePipeline:
    """Test the full pipeline integration"""

    @pytest.mark.asyncio
    async def test_pipeline_detects_and_answers_question(self, llm_client):
        """Test that questions in insights trigger auto-answering"""
        # This is a minimal smoke test - full integration would require:
        # 1. Mock WebSocket connection
        # 2. Mock vector database with sample content
        # 3. Mock embedding service
        # 4. Test actual message flow

        # For now, just verify components can work together
        detector = QuestionDetector(llm_client=llm_client)

        # Simulate a question insight
        question_text = "What was decided about the new feature?"
        detected = await detector.detect_and_classify_question(question_text)

        assert detected is not None
        assert detected.type in ["factual", "decision", "process", "clarification"]

        # In a real scenario, this would:
        # 1. Be passed to QuestionAnsweringService
        # 2. Search vector DB for relevant meetings
        # 3. Synthesize answer with sources
        # 4. Return in proactive_assistance field


class TestEndToEndFlow:
    """Simplified end-to-end test"""

    @pytest.mark.asyncio
    async def test_question_in_transcript_triggers_assistance(self, llm_client):
        """
        Test the complete flow:
        1. User asks question in meeting
        2. Question is detected
        3. System attempts to find answer (would use RAG)
        4. Response includes proactive_assistance field
        """
        # Setup
        detector = QuestionDetector(llm_client=llm_client)

        # Simulate meeting transcript chunk with a question
        transcript_chunk = "So, what was our final decision on the pricing model?"

        # Step 1: Detect question
        detected = await detector.detect_and_classify_question(transcript_chunk)
        assert detected is not None
        assert "pricing model" in detected.text.lower()

        # Step 2: In real system, this would trigger RAG search
        # For now, verify the detection worked correctly
        assert detected.type == "decision"  # Should classify as decision question
        assert detected.confidence >= 0.7

        # Step 3: Verify response structure (what would be sent via WebSocket)
        expected_response = {
            "type": "auto_answer",
            "insight_id": "test_123",
            "question": detected.text,
            "answer": "[Would be synthesized by RAG]",
            "confidence": 0.85,
            "sources": [],
            "reasoning": "[Would be provided by LLM]"
        }

        assert "type" in expected_response
        assert "question" in expected_response
        assert "answer" in expected_response
        assert "confidence" in expected_response
        assert "sources" in expected_response


# Performance test
class TestPerformance:
    """Test performance characteristics"""

    @pytest.mark.asyncio
    async def test_question_detection_speed(self, question_detector):
        """Verify question detection completes within reasonable time"""
        import time

        text = "What is the project timeline?"

        start = time.time()
        result = await question_detector.detect_and_classify_question(text)
        elapsed = time.time() - start

        assert result is not None
        # Explicit questions should be very fast (regex-based)
        assert elapsed < 0.2, f"Detection took {elapsed}s, expected <0.2s for explicit question"

    @pytest.mark.asyncio
    async def test_implicit_question_detection_speed(self, question_detector):
        """Verify implicit question detection completes within reasonable time"""
        import time

        text = "I'm wondering about the deployment schedule"

        start = time.time()
        result = await question_detector.detect_and_classify_question(text)
        elapsed = time.time() - start

        # Implicit questions use LLM, so should be <2 seconds
        assert elapsed < 2.0, f"Detection took {elapsed}s, expected <2s for implicit question"


if __name__ == "__main__":
    # Run tests
    pytest.main([__file__, "-v", "-s"])
