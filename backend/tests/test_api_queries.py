"""
API Integration Tests - Query Endpoints
Tests for RAG query system and response generation
"""

import pytest
from httpx import AsyncClient
from fastapi import status
import asyncio
import time


@pytest.mark.asyncio
class TestQueryEndpoints:
    """Test RAG query system and natural language processing"""
    
    async def test_simple_query(self, api_client: AsyncClient, test_project):
        """Test basic query processing"""
        test_project_id = test_project["id"] if isinstance(test_project, dict) else test_project
        # First upload content to query
        content_data = {
            "content_type": "meeting",
            "title": "Query Test Meeting",
            "content": """
            Engineering Team Meeting
            Date: 2024-02-18
            
            Discussion:
            - API performance has improved by 40% after optimization
            - Database queries are now cached effectively
            - Frontend load time reduced to under 2 seconds
            - Mobile app crashes decreased by 60%
            
            Decisions:
            - Implement Redis for session management
            - Migrate to PostgreSQL 17 next month
            - Add monitoring dashboards for all services
            
            Action Items:
            - John: Set up Redis cluster by March 1
            - Sarah: Create migration plan for PostgreSQL
            - Mike: Deploy monitoring solution
            """,
            "date": "2024-02-18"
        }
        
        response = await api_client.post(
            f"/api/projects/{test_project_id}/upload/text",
            json=content_data
        )
        
        # Wait for processing and indexing
        await asyncio.sleep(5)
        
        # Query the content
        query_data = {
            "question": "What performance improvements were discussed?"
        }
        
        response = await api_client.post(
            f"/api/projects/{test_project_id}/query",
            json=query_data
        )
        
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        
        assert "answer" in data
        assert "sources" in data
        assert "confidence" in data
        assert "response_time_ms" in data
        
        # Answer should mention performance improvements
        answer_lower = data["answer"].lower()
        assert any(term in answer_lower for term in ["performance", "40%", "optimization", "improved"])
        
        # Should have sources
        assert len(data["sources"]) > 0
        assert data["confidence"] > 0
    
    async def test_complex_multi_part_query(self, api_client: AsyncClient, test_project):
        """Test complex query requiring multi-step reasoning"""
        test_project_id = test_project["id"] if isinstance(test_project, dict) else test_project
        # Upload multiple related documents
        meetings = [
            {
                "content_type": "meeting",
                "title": "Sprint Planning",
                "content": """
                Sprint Planning Meeting
                Date: 2024-02-19
                
                Sprint Goals:
                - Complete user authentication module
                - Implement payment processing
                - Fix critical bugs in mobile app
                
                Team Assignments:
                - Alice: Authentication backend
                - Bob: Payment integration
                - Charlie: Mobile bug fixes
                
                Timeline: 2 week sprint ending March 4
                """,
                "date": "2024-02-19"
            },
            {
                "content_type": "meeting",
                "title": "Sprint Review",
                "content": """
                Sprint Review Meeting
                Date: 2024-03-04
                
                Completed:
                - Authentication module 100% complete
                - Payment processing 80% complete
                - Mobile bugs: 5 of 8 fixed
                
                Challenges:
                - Payment gateway API changes delayed integration
                - Mobile team blocked by iOS deployment issues
                
                Next Sprint:
                - Complete payment processing
                - Resolve remaining mobile bugs
                - Start performance optimization
                """,
                "date": "2024-03-04"
            }
        ]
        
        for meeting in meetings:
            await api_client.post(
                f"/api/projects/{test_project_id}/upload/text",
                json=meeting
            )
            await asyncio.sleep(2)
        
        await asyncio.sleep(5)
        
        # Complex query requiring correlation
        query_data = {
            "question": "What was the progress on the sprint goals and what challenges were faced?"
        }
        
        response = await api_client.post(
            f"/api/projects/{test_project_id}/query",
            json=query_data
        )
        
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        
        # Should reference both meetings
        assert len(data["sources"]) >= 2
        
        # Answer should mention goals and challenges
        answer_lower = data["answer"].lower()
        assert any(term in answer_lower for term in ["authentication", "payment", "mobile"])
        assert any(term in answer_lower for term in ["challenge", "delay", "blocked", "issue"])
    
    async def test_query_response_time(self, api_client: AsyncClient, test_project):
        """Test that queries complete within acceptable time limits"""
        test_project_id = test_project["id"] if isinstance(test_project, dict) else test_project
        # Upload content
        content_data = {
            "content_type": "meeting",
            "title": "Performance Test Content",
            "content": "Quick test content for performance testing. " * 50,
            "date": "2024-02-20"
        }
        
        await api_client.post(
            f"/api/projects/{test_project_id}/upload/text",
            json=content_data
        )
        
        await asyncio.sleep(5)
        
        # Time the query
        start_time = time.time()
        
        response = await api_client.post(
            f"/api/projects/{test_project_id}/query",
            json={"question": "What is this document about?"}
        )
        
        query_time = time.time() - start_time
        
        assert response.status_code == status.HTTP_200_OK
        
        # Query should complete within 10 seconds
        assert query_time < 10
        
        # Response should include timing
        data = response.json()
        assert "response_time_ms" in data
        assert data["response_time_ms"] < 10000
    
    async def test_query_with_no_relevant_content(self, api_client: AsyncClient, test_project):
        """Test query when no relevant content exists"""
        test_project_id = test_project["id"] if isinstance(test_project, dict) else test_project
        # Upload unrelated content
        content_data = {
            "content_type": "meeting",
            "title": "Unrelated Meeting",
            "content": "Discussion about office furniture and lunch options",
            "date": "2024-02-21"
        }
        
        await api_client.post(
            f"/api/projects/{test_project_id}/upload/text",
            json=content_data
        )
        
        await asyncio.sleep(5)
        
        # Query about something not in the content
        query_data = {
            "question": "What is the deployment strategy for Kubernetes?"
        }
        
        response = await api_client.post(
            f"/api/projects/{test_project_id}/query",
            json=query_data
        )
        
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        
        # Should handle gracefully
        assert "answer" in data
        
        # Confidence should be low or answer should indicate no information
        answer_lower = data["answer"].lower()
        assert data["confidence"] < 0.5 or \
               any(term in answer_lower for term in ["no information", "not found", "not mentioned", "unable"])
    
    async def test_query_empty_project(self, api_client: AsyncClient):
        """Test querying a project with no content"""
        # Create empty project
        project_data = {
            "name": "Empty Query Test",
            "description": "No content",
            "created_by": "test@example.com"
        }
        
        response = await api_client.post("/api/projects", json=project_data)
        empty_project_id = response.json()["id"]
        
        try:
            response = await api_client.post(
                f"/api/projects/{empty_project_id}/query",
                json={"question": "What meetings have we had?"}
            )
            
            assert response.status_code == status.HTTP_200_OK
            data = response.json()
            
            # Should indicate no content available
            answer_lower = data["answer"].lower()
            assert any(term in answer_lower for term in ["no content", "no meetings", "no information", "empty"])
            
        finally:
            # Clean up
            await api_client.delete(f"/api/projects/{empty_project_id}")
    
    async def test_query_different_types(self, api_client: AsyncClient, test_project):
        """Test different query types (factual, conceptual, task-oriented)"""
        test_project_id = test_project["id"] if isinstance(test_project, dict) else test_project
        # Upload diverse content
        content_data = {
            "content_type": "meeting",
            "title": "Comprehensive Meeting",
            "content": """
            Product Strategy Meeting
            Date: 2024-02-22
            
            Facts:
            - Current user base: 10,000 active users
            - Revenue: $50,000 MRR
            - Team size: 15 people
            
            Strategy:
            - Focus on enterprise customers
            - Build integration partnerships
            - Improve onboarding experience
            
            Tasks:
            - Launch enterprise plan by Q2
            - Sign 3 integration partners
            - Reduce onboarding time to 5 minutes
            """,
            "date": "2024-02-22"
        }
        
        await api_client.post(
            f"/api/projects/{test_project_id}/upload/text",
            json=content_data
        )
        
        await asyncio.sleep(5)
        
        # Test factual query
        response = await api_client.post(
            f"/api/projects/{test_project_id}/query",
            json={"question": "What is our current MRR?"}
        )
        assert response.status_code == status.HTTP_200_OK
        assert "50,000" in response.json()["answer"] or "50000" in response.json()["answer"]
        
        # Test conceptual query
        response = await api_client.post(
            f"/api/projects/{test_project_id}/query",
            json={"question": "What is our product strategy?"}
        )
        assert response.status_code == status.HTTP_200_OK
        answer = response.json()["answer"].lower()
        assert any(term in answer for term in ["enterprise", "integration", "onboarding"])
        
        # Test task-oriented query
        response = await api_client.post(
            f"/api/projects/{test_project_id}/query",
            json={"question": "What needs to be done by Q2?"}
        )
        assert response.status_code == status.HTTP_200_OK
        assert "enterprise" in response.json()["answer"].lower()
    
    async def test_query_with_special_characters(self, api_client: AsyncClient, test_project):
        """Test queries containing special characters"""
        test_project_id = test_project["id"] if isinstance(test_project, dict) else test_project
        # Upload content with special characters
        content_data = {
            "content_type": "meeting",
            "title": "Technical Meeting",
            "content": """
            Code Review Meeting
            
            Discussed:
            - Function foo() needs refactoring
            - API endpoint /api/v2/users/{id} is slow
            - SQL query: SELECT * FROM users WHERE email LIKE '%@example.com'
            - Config setting: max_connections = 100
            """,
            "date": "2024-02-23"
        }
        
        await api_client.post(
            f"/api/projects/{test_project_id}/upload/text",
            json=content_data
        )
        
        await asyncio.sleep(5)
        
        # Query with special characters
        queries = [
            "What about the foo() function?",
            "Tell me about /api/v2/users/{id}",
            "What SQL queries were discussed?",
            "What is max_connections set to?"
        ]
        
        for query in queries:
            response = await api_client.post(
                f"/api/projects/{test_project_id}/query",
                json={"question": query}
            )
            assert response.status_code == status.HTTP_200_OK
    
    async def test_concurrent_queries(self, api_client: AsyncClient, test_project):
        """Test handling multiple concurrent queries"""
        test_project_id = test_project["id"] if isinstance(test_project, dict) else test_project
        # Upload content
        content_data = {
            "content_type": "meeting",
            "title": "Concurrent Query Test",
            "content": "Test content for concurrent queries",
            "date": "2024-02-24"
        }
        
        await api_client.post(
            f"/api/projects/{test_project_id}/upload/text",
            json=content_data
        )
        
        await asyncio.sleep(5)
        
        # Send multiple queries concurrently
        questions = [
            "What is this about?",
            "When was this meeting?",
            "What was discussed?",
            "Any action items?",
            "Who attended?"
        ]
        
        tasks = []
        for question in questions:
            task = api_client.post(
                f"/api/projects/{test_project_id}/query",
                json={"question": question}
            )
            tasks.append(task)
        
        responses = await asyncio.gather(*tasks)
        
        # All should succeed
        for response in responses:
            assert response.status_code == status.HTTP_200_OK
            assert "answer" in response.json()
    
    async def test_query_validation(self, api_client: AsyncClient, test_project):
        """Test query input validation"""
        test_project_id = test_project["id"] if isinstance(test_project, dict) else test_project
        # Empty question
        response = await api_client.post(
            f"/api/projects/{test_project_id}/query",
            json={"question": ""}
        )
        assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY
        
        # Missing question field
        response = await api_client.post(
            f"/api/projects/{test_project_id}/query",
            json={}
        )
        assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY
        
        # Very long question (over 1000 chars)
        long_question = "What about " * 200
        response = await api_client.post(
            f"/api/projects/{test_project_id}/query",
            json={"question": long_question}
        )
        # Should either accept or reject gracefully
        assert response.status_code in [
            status.HTTP_200_OK,
            status.HTTP_400_BAD_REQUEST,
            status.HTTP_422_UNPROCESSABLE_ENTITY
        ]
    
    async def test_query_metadata_tracking(self, api_client: AsyncClient, test_project):
        """Test that queries are logged with metadata"""
        test_project_id = test_project["id"] if isinstance(test_project, dict) else test_project
        # Upload content
        content_data = {
            "content_type": "meeting",
            "title": "Metadata Test",
            "content": "Content for metadata tracking test",
            "date": "2024-02-25"
        }
        
        await api_client.post(
            f"/api/projects/{test_project_id}/upload/text",
            json=content_data
        )
        
        await asyncio.sleep(5)
        
        # Make a query
        response = await api_client.post(
            f"/api/projects/{test_project_id}/query",
            json={"question": "What is this test about?"}
        )
        
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        
        # Should include metadata
        assert "response_time_ms" in data
        assert "confidence" in data
        assert "sources" in data
        
        # If token tracking is enabled
        if "tokens_used" in data:
            assert data["tokens_used"] > 0
        
        # If cost tracking is enabled
        if "cost" in data:
            assert data["cost"] >= 0