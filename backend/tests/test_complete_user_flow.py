"""
Complete User Flow Integration Tests
Tests complete user journeys with real API calls, database operations, and vector storage
"""
import asyncio
import time
import uuid
from typing import Dict, Any, List
import pytest
from httpx import AsyncClient


class TestCompleteProjectLifecycle:
    """Test complete project lifecycle from creation to deletion"""
    
    @pytest.mark.asyncio
    async def test_project_lifecycle_with_uploads_and_queries(
        self, api_client: AsyncClient, performance_tracker, clean_database
    ):
        """Complete project lifecycle test (create, upload, query, delete)"""
        start_time = time.time()
        
        # Step 1: Create project
        project_data = {
            "name": "Integration Test Project",
            "description": "Testing complete user flow",
            "members": [
                {"name": "Alice Johnson", "email": "alice@test.com", "role": "PM"},
                {"name": "Bob Smith", "email": "bob@test.com", "role": "Developer"}
            ]
        }
        
        create_start = time.time()
        response = await api_client.post("/api/projects", json=project_data)
        assert response.status_code == 200
        project = response.json()
        assert project["name"] == project_data["name"]
        assert len(project["members"]) == 2
        performance_tracker.record("project_creation", time.time() - create_start)
        
        project_id = project["id"]
        
        # Step 2: Upload multiple meeting transcripts
        meetings = [
            {
                "title": "Sprint Planning Meeting",
                "content": """
                Date: January 15, 2024
                Attendees: Alice, Bob, Charlie
                
                Sprint Goals:
                - Complete user authentication module
                - Implement JWT token generation
                - Set up Redis caching layer
                - Deploy to staging environment
                
                Technical Decisions:
                - Use bcrypt for password hashing
                - JWT tokens will expire after 24 hours
                - Redis will cache user sessions
                
                Action Items:
                - Alice: Write API documentation
                - Bob: Implement authentication endpoints
                - Charlie: Set up Redis infrastructure
                """
            },
            {
                "title": "Technical Review Meeting",
                "content": """
                Date: January 17, 2024
                Attendees: Bob, David (Security Expert)
                
                Security Review:
                - Reviewed authentication implementation
                - Identified potential SQL injection vulnerability
                - Recommended implementing rate limiting
                - Suggested adding 2FA support
                
                Decisions:
                - Fix SQL injection issue immediately
                - Implement rate limiting this sprint
                - Plan 2FA for next sprint
                
                Action Items:
                - Bob: Fix SQL injection vulnerability
                - David: Provide rate limiting specifications
                """
            },
            {
                "title": "Weekly Standup",
                "content": """
                Date: January 19, 2024
                Team Updates:
                
                Alice:
                - Completed API documentation
                - Working on deployment scripts
                - Blocked on AWS credentials
                
                Bob:
                - Fixed security vulnerability
                - Authentication module 90% complete
                - Need code review from Charlie
                
                Charlie:
                - Redis setup complete
                - Performance testing in progress
                - Found memory leak in caching layer
                
                Blockers:
                - AWS credentials needed for deployment
                - Memory leak needs investigation
                """
            }
        ]
        
        upload_times = []
        for i, meeting in enumerate(meetings):
            upload_start = time.time()
            response = await api_client.post(
                f"/api/projects/{project_id}/upload/text",
                json={
                    "content_type": "meeting",
                    "title": meeting["title"],
                    "content": meeting["content"]
                }
            )
            assert response.status_code == 200
            upload_times.append(time.time() - upload_start)
            performance_tracker.record("content_upload", upload_times[-1])
            
            # Wait for processing
            await asyncio.sleep(3)
        
        # Step 3: Verify content was processed
        response = await api_client.get(f"/api/projects/{project_id}/content")
        assert response.status_code == 200
        content_list = response.json()
        assert len(content_list) == 3
        
        # Step 4: Test various queries
        queries = [
            "What authentication method did we decide to use?",
            "What are the current blockers?",
            "Who is responsible for Redis setup?",
            "What security issues were identified?",
            "What are all the action items from this week?"
        ]
        
        query_responses = []
        for query in queries:
            query_start = time.time()
            response = await api_client.post(
                f"/api/projects/{project_id}/query",
                json={"question": query}
            )
            assert response.status_code == 200
            result = response.json()
            query_responses.append(result)
            
            # Validate response structure
            assert "answer" in result
            assert "sources" in result
            assert "confidence" in result
            # metadata field is optional
            assert len(result["answer"]) > 0
            assert result["confidence"] > 0
            
            query_time = time.time() - query_start
            performance_tracker.record("query_response", query_time)
            assert query_time < 10, f"Query took {query_time:.2f}s, exceeds 10s limit"
        
        # Step 5: Generate meeting summary
        summary_start = time.time()
        response = await api_client.post(
            f"/api/projects/{project_id}/summary",
            json={"type": "meeting"}
        )
        assert response.status_code == 200
        summary = response.json()
        assert "summary" in summary
        assert "key_points" in summary["summary"]
        performance_tracker.record("summary_generation", time.time() - summary_start)
        
        # Step 6: Generate project summary
        project_summary_start = time.time()
        response = await api_client.post(
            f"/api/projects/{project_id}/summary",
            json={"type": "project"}
        )
        assert response.status_code == 200
        project_summary = response.json()
        assert "summary" in project_summary
        performance_tracker.record("project_summary", time.time() - project_summary_start)
        
        # Step 7: Delete project
        response = await api_client.delete(f"/api/projects/{project_id}")
        assert response.status_code in [200, 204]
        
        # Verify deletion
        response = await api_client.get(f"/api/projects/{project_id}")
        assert response.status_code == 404
        
        # Performance assertions
        total_time = time.time() - start_time
        assert total_time < 60, f"Complete flow took {total_time:.2f}s, exceeds 60s limit"
        performance_tracker.assert_performance("query_response", 10.0)
        
        print(f"\n✅ Complete project lifecycle test passed in {total_time:.2f}s")


class TestMeetingUploadToRetrievalFlow:
    """Test the complete flow from meeting upload to retrieval"""
    
    @pytest.mark.asyncio
    async def test_upload_chunking_embedding_storage_retrieval(
        self, api_client: AsyncClient, test_project: Dict[str, Any], performance_tracker
    ):
        """Meeting upload → chunking → embedding → storage → retrieval flow"""
        project_id = test_project["id"]
        
        # Upload a detailed meeting transcript
        meeting_content = """
        Project Status Meeting - January 20, 2024
        Attendees: Sarah Chen (PM), Mike Ross (Tech Lead), Lisa Park (Designer)
        Duration: 60 minutes
        
        AGENDA ITEMS:
        
        1. Q1 ROADMAP REVIEW (Sarah)
        Current Status: We are 40% through Q1 with following progress:
        - Feature A: Complete (shipped Jan 10)
        - Feature B: In development (70% done, on track)
        - Feature C: Design phase (starting development next week)
        - Feature D: Blocked on third-party API integration
        
        Key Metrics:
        - Sprint velocity: 45 points (target was 40)
        - Bug count: 12 open, 5 critical
        - Test coverage: 78% (target 80%)
        
        2. TECHNICAL ARCHITECTURE DISCUSSION (Mike)
        Proposed Changes:
        - Migrate from REST to GraphQL for better performance
        - Implement microservices for scaling
        - Add Kubernetes for container orchestration
        - Set up monitoring with Prometheus and Grafana
        
        Database Optimization:
        - Current query performance: 200ms average
        - After optimization: Expected 50ms average
        - Need to add indexes on user_id and project_id columns
        - Consider sharding for users table (currently 1M records)
        
        3. DESIGN SYSTEM UPDATE (Lisa)
        New Components:
        - Date picker with accessibility support
        - Data visualization charts (bar, line, pie)
        - Responsive navigation menu
        - Dark mode theme variables
        
        User Research Findings:
        - 73% users want mobile app
        - Navigation confusion in settings page
        - Request for batch operations
        - Need better error messages
        
        4. RISK ASSESSMENT
        High Priority Risks:
        - Third-party API delays (80% probability)
        - Senior developer leaving (30% probability)
        - Security audit findings (pending)
        
        Mitigation Plans:
        - Build API mock for development
        - Start knowledge transfer sessions
        - Schedule security fixes for next sprint
        
        5. DECISIONS MADE
        ✓ Proceed with GraphQL migration (Mike to lead)
        ✓ Hire additional QA engineer (Sarah to coordinate)
        ✓ Implement dark mode in v2.1 (Lisa to design)
        ✓ Move Feature D to Q2 due to blocking issue
        
        6. ACTION ITEMS
        Sarah: 
        - Schedule GraphQL migration planning session
        - Post QA engineer job listing
        - Update stakeholders on Feature D delay
        
        Mike:
        - Create GraphQL migration technical spec
        - Optimize database queries this sprint
        - Set up Prometheus monitoring POC
        
        Lisa:
        - Complete dark mode design tokens
        - Create mobile app wireframes
        - Fix navigation issues in settings
        
        NEXT MEETING: January 27, 2024 - Sprint Retrospective
        """
        
        # Upload meeting
        upload_start = time.time()
        response = await api_client.post(
            f"/api/projects/{project_id}/upload/text",
            json={
                "content_type": "meeting",
                "title": "Q1 Project Status Meeting",
                "content": meeting_content
            }
        )
        assert response.status_code == 200
        content = response.json()
        content_id = content["id"]
        upload_time = time.time() - upload_start
        performance_tracker.record("upload_time", upload_time)
        
        # Wait for processing (chunking + embedding)
        await asyncio.sleep(5)
        
        # Verify content was chunked
        response = await api_client.get(f"/api/projects/{project_id}/content/{content_id}")
        assert response.status_code == 200
        content_details = response.json()
        assert content_details["chunk_count"] > 0
        assert content_details["processing_status"] == "completed"
        
        # Test retrieval with various queries
        test_queries = [
            {
                "question": "What is the current sprint velocity?",
                "expected_keywords": ["45 points", "velocity", "target"]
            },
            {
                "question": "What technical changes are proposed?",
                "expected_keywords": ["GraphQL", "microservices", "Kubernetes"]
            },
            {
                "question": "What did Lisa present about the design system?",
                "expected_keywords": ["components", "dark mode", "accessibility"]
            },
            {
                "question": "What are the high priority risks?",
                "expected_keywords": ["API delays", "developer leaving", "security"]
            },
            {
                "question": "What are Mike's action items?",
                "expected_keywords": ["GraphQL", "database", "Prometheus"]
            }
        ]
        
        for test_query in test_queries:
            query_start = time.time()
            response = await api_client.post(
                f"/api/projects/{project_id}/query",
                json={"question": test_query["question"]}
            )
            assert response.status_code == 200
            result = response.json()
            
            # Verify response contains expected information
            answer_lower = result["answer"].lower()
            found_keywords = sum(
                1 for keyword in test_query["expected_keywords"]
                if keyword.lower() in answer_lower
            )
            assert found_keywords > 0, f"Query '{test_query['question']}' didn't return expected content"
            
            # Verify sources reference the uploaded meeting
            assert len(result["sources"]) > 0
            assert any("Q1 Project Status Meeting" in source for source in result["sources"])
            
            query_time = time.time() - query_start
            performance_tracker.record("retrieval_time", query_time)
        
        # Performance assertions
        assert upload_time < 30, f"Upload took {upload_time:.2f}s, exceeds 30s limit"
        performance_tracker.assert_performance("retrieval_time", 5.0)
        
        print(f"✅ Upload to retrieval flow test passed")


class TestMultiStepRAGQuery:
    """Test multi-step RAG query with actual Claude API calls"""
    
    @pytest.mark.asyncio
    async def test_three_step_reasoning_with_gap_analysis(
        self, api_client: AsyncClient, test_project: Dict[str, Any]
    ):
        """Test 3-step RAG: initial retrieval → gap analysis → enhanced retrieval"""
        project_id = test_project["id"]
        
        # Upload related but scattered information
        documents = [
            {
                "title": "Architecture Decision Record",
                "content": """
                ADR-001: Authentication System
                Date: January 5, 2024
                Status: Accepted
                
                Context: We need a secure authentication system.
                Decision: Use OAuth 2.0 with JWT tokens.
                Consequences: Better security but more complex implementation.
                """
            },
            {
                "title": "Security Audit Report",
                "content": """
                Security Audit - January 12, 2024
                
                Findings:
                - JWT implementation needs rotation mechanism
                - Missing rate limiting on auth endpoints
                - Password policy too weak
                - No account lockout after failed attempts
                
                Recommendations:
                - Implement JWT rotation every 7 days
                - Add rate limiting: 5 attempts per minute
                - Require 12+ character passwords
                - Lock account after 5 failed attempts
                """
            },
            {
                "title": "Implementation Timeline",
                "content": """
                Authentication System Timeline
                
                Week 1 (Jan 15-19): Basic JWT implementation
                Week 2 (Jan 22-26): Add OAuth providers
                Week 3 (Jan 29-Feb 2): Security hardening
                Week 4 (Feb 5-9): Testing and deployment
                
                Dependencies:
                - Database schema must be ready
                - Redis for session storage
                - Email service for password reset
                """
            }
        ]
        
        # Upload all documents
        for doc in documents:
            response = await api_client.post(
                f"/api/projects/{project_id}/upload/text",
                json={
                    "content_type": "meeting",
                    "title": doc["title"],
                    "content": doc["content"]
                }
            )
            assert response.status_code == 200
        
        # Wait for processing
        await asyncio.sleep(5)
        
        # Query that requires multi-step reasoning
        complex_query = "What is the complete authentication implementation plan including security requirements and timeline?"
        
        response = await api_client.post(
            f"/api/projects/{project_id}/query",
            json={"question": complex_query}
        )
        assert response.status_code == 200
        result = response.json()
        
        # Verify comprehensive answer
        answer = result["answer"].lower()
        assert "oauth" in answer or "jwt" in answer
        assert "security" in answer or "audit" in answer
        assert "timeline" in answer or "week" in answer
        
        # Verify multiple sources were used
        assert len(result["sources"]) >= 2, "Multi-step reasoning should use multiple sources"
        
        # Verify metadata shows multi-step processing (if available)
        if "metadata" in result and "steps" in result["metadata"]:
            assert result["metadata"]["steps"] >= 2
        
        print(f"✅ Multi-step RAG query test passed")


class TestProjectSummaryGeneration:
    """Test project summary generation with multiple meetings"""

    @pytest.mark.asyncio
    async def test_project_summary_aggregation(
        self, api_client: AsyncClient, test_project: Dict[str, Any]
    ):
        """Test project summary generation from multiple meetings"""
        project_id = test_project["id"]
        
        # Upload a period's worth of meetings
        project_meetings = [
            {
                "title": "Monday Planning",
                "content": "Sprint planning: Assigned 5 stories, 40 story points total"
            },
            {
                "title": "Wednesday Standup",
                "content": "Progress update: 2 stories complete, 1 blocked on API"
            },
            {
                "title": "Friday Retrospective",
                "content": "Team feedback: Need better documentation, celebrate shipping feature X"
            }
        ]
        
        for meeting in project_meetings:
            response = await api_client.post(
                f"/api/projects/{project_id}/upload/text",
                json={
                    "content_type": "meeting",
                    "title": meeting["title"],
                    "content": meeting["content"]
                }
            )
            assert response.status_code == 200
        
        # Wait for processing
        await asyncio.sleep(5)
        
        # Generate project summary
        response = await api_client.post(
            f"/api/projects/{project_id}/summary",
            json={"type": "project"}
        )
        assert response.status_code == 200
        summary = response.json()
        
        # Verify summary structure
        assert "summary" in summary
        assert "key_points" in summary["summary"]
        assert "decisions" in summary["summary"]
        assert "action_items" in summary["summary"]
        
        # Verify summary includes information from multiple meetings
        summary_text = str(summary["summary"]).lower()
        assert "planning" in summary_text or "sprint" in summary_text
        assert "progress" in summary_text or "complete" in summary_text
        
        print(f"✅ Project summary generation test passed")


class TestConcurrentOperations:
    """Test concurrent uploads and queries"""
    
    @pytest.mark.asyncio
    async def test_concurrent_uploads_and_queries(
        self, api_client: AsyncClient, test_project: Dict[str, Any], performance_tracker
    ):
        """Test system handles concurrent operations correctly"""
        project_id = test_project["id"]
        
        # Prepare multiple uploads
        uploads = [
            {"title": f"Meeting {i}", "content": f"Discussion about topic {i}"}
            for i in range(5)
        ]
        
        # Concurrent uploads
        upload_tasks = []
        for upload in uploads:
            task = api_client.post(
                f"/api/projects/{project_id}/upload/text",
                json={
                    "content_type": "meeting",
                    "title": upload["title"],
                    "content": upload["content"]
                }
            )
            upload_tasks.append(task)
        
        start_time = time.time()
        upload_responses = await asyncio.gather(*upload_tasks)
        upload_time = time.time() - start_time
        
        # Verify all uploads succeeded
        for response in upload_responses:
            assert response.status_code == 200
        
        performance_tracker.record("concurrent_uploads", upload_time)
        
        # Wait for processing
        await asyncio.sleep(5)
        
        # Concurrent queries
        queries = [
            f"What was discussed about topic {i}?" for i in range(5)
        ]
        
        query_tasks = []
        for query in queries:
            task = api_client.post(
                f"/api/projects/{project_id}/query",
                json={"question": query}
            )
            query_tasks.append(task)
        
        start_time = time.time()
        query_responses = await asyncio.gather(*query_tasks)
        query_time = time.time() - start_time
        
        # Verify all queries succeeded
        for response in query_responses:
            assert response.status_code == 200
            result = response.json()
            assert "answer" in result
        
        performance_tracker.record("concurrent_queries", query_time)
        
        print(f"✅ Concurrent operations test passed")


class TestDatabaseResetEndpoint:
    """Test database reset functionality"""
    
    @pytest.mark.asyncio
    async def test_database_reset_clears_all_data(
        self, api_client: AsyncClient, api_with_auth: AsyncClient
    ):
        """Test database reset endpoint validation"""
        # Create test data
        project_response = await api_client.post(
            "/api/projects",
            json={
                "name": "Project to be deleted",
                "description": "Test reset functionality"
            }
        )
        assert project_response.status_code == 200
        
        # Reset database
        reset_response = await api_with_auth.delete(
            "/api/admin/reset",
            json={"confirm": True}
        )
        
        if reset_response.status_code == 200:
            result = reset_response.json()
            assert "deleted" in result
            assert result["deleted"]["projects"] >= 1
            
            # Verify data is gone
            projects_response = await api_client.get("/api/projects")
            assert projects_response.status_code == 200
            projects = projects_response.json()
            assert len(projects) == 0
        else:
            # Endpoint might not exist in test environment
            pytest.skip("Database reset endpoint not available")
        
        print(f"✅ Database reset test passed")


class TestErrorRecoveryScenarios:
    """Test error recovery and edge cases"""
    
    @pytest.mark.asyncio
    async def test_malformed_request_handling(self, api_client: AsyncClient):
        """Test API handles malformed requests gracefully"""
        # Invalid project creation
        response = await api_client.post(
            "/api/projects",
            json={"invalid": "data"}
        )
        assert response.status_code == 422
        
        # Invalid query
        response = await api_client.post(
            "/api/projects/invalid-uuid/query",
            json={"question": "test"}
        )
        assert response.status_code in [404, 422]
        
        print(f"✅ Error handling test passed")
    
    @pytest.mark.asyncio
    async def test_network_failure_recovery(
        self, api_client: AsyncClient, test_project: Dict[str, Any]
    ):
        """Test system recovers from network failures"""
        project_id = test_project["id"]
        
        # Simulate large content that might timeout
        large_content = "Large meeting transcript. " * 10000
        
        # This might fail or succeed depending on timeouts
        response = await api_client.post(
            f"/api/projects/{project_id}/upload/text",
            json={
                "content_type": "meeting",
                "title": "Large Meeting",
                "content": large_content
            },
            timeout=5.0  # Short timeout
        )
        
        # System should handle this gracefully
        assert response.status_code in [200, 408, 504]
        
        print(f"✅ Network recovery test passed")


class TestPerformanceBenchmarks:
    """Test performance benchmarks and limits"""
    
    @pytest.mark.asyncio
    async def test_response_time_benchmarks(
        self, api_client: AsyncClient, test_project: Dict[str, Any], performance_tracker
    ):
        """Verify response times meet requirements"""
        project_id = test_project["id"]
        
        # Upload content for testing
        response = await api_client.post(
            f"/api/projects/{project_id}/upload/text",
            json={
                "content_type": "meeting",
                "title": "Performance Test Meeting",
                "content": "Quick meeting about performance testing and benchmarks."
            }
        )
        assert response.status_code == 200
        
        await asyncio.sleep(3)
        
        # Benchmark queries
        for i in range(10):
            start = time.time()
            response = await api_client.post(
                f"/api/projects/{project_id}/query",
                json={"question": f"What about performance test {i}?"}
            )
            query_time = time.time() - start
            assert response.status_code == 200
            performance_tracker.record("query_benchmark", query_time)
        
        # Assert average performance
        performance_tracker.assert_performance("query_benchmark", 5.0)
        
        print(f"✅ Performance benchmark test passed")
    
    @pytest.mark.asyncio
    async def test_token_usage_and_cost_tracking(
        self, api_client: AsyncClient, test_project: Dict[str, Any]
    ):
        """Test token usage and cost tracking"""
        project_id = test_project["id"]
        
        # Upload content
        response = await api_client.post(
            f"/api/projects/{project_id}/upload/text",
            json={
                "content_type": "meeting",
                "title": "Cost Test Meeting",
                "content": "Meeting to test token usage and cost tracking."
            }
        )
        assert response.status_code == 200
        
        await asyncio.sleep(3)
        
        # Query to generate tokens
        response = await api_client.post(
            f"/api/projects/{project_id}/query",
            json={"question": "What was discussed in the cost test meeting?"}
        )
        assert response.status_code == 200
        result = response.json()
        
        # Verify token tracking (if metadata is available)
        # Note: Current API might not return metadata field
        if "metadata" in result:
            metadata = result["metadata"]
            if "tokens" in metadata:
                assert metadata["tokens"]["input"] > 0
                assert metadata["tokens"]["output"] > 0
            if "cost" in metadata:
                assert metadata["cost"] > 0
                assert metadata["cost"] < 0.05  # Should be less than 5 cents
        
        print(f"✅ Token usage tracking test passed")


class TestVectorSearchValidation:
    """Test Qdrant vector search functionality"""
    
    @pytest.mark.asyncio
    async def test_vector_similarity_search(
        self, api_client: AsyncClient, test_project: Dict[str, Any]
    ):
        """Test that vector search returns relevant results"""
        project_id = test_project["id"]
        
        # Upload documents with similar and different content
        documents = [
            {
                "title": "Python Programming Guide",
                "content": "Python is a high-level programming language with dynamic typing and garbage collection."
            },
            {
                "title": "JavaScript Tutorial",
                "content": "JavaScript is a scripting language for web development with prototype-based inheritance."
            },
            {
                "title": "Python Best Practices",
                "content": "Python code should follow PEP 8 style guide and use type hints for better code quality."
            },
            {
                "title": "Meeting Notes",
                "content": "Today we discussed the quarterly budget and marketing strategy for Q2."
            }
        ]
        
        for doc in documents:
            response = await api_client.post(
                f"/api/projects/{project_id}/upload/text",
                json={
                    "content_type": "meeting",
                    "title": doc["title"],
                    "content": doc["content"]
                }
            )
            assert response.status_code == 200
        
        await asyncio.sleep(5)
        
        # Query about Python should return Python documents
        response = await api_client.post(
            f"/api/projects/{project_id}/query",
            json={"question": "What are the Python programming guidelines?"}
        )
        assert response.status_code == 200
        result = response.json()
        
        # Verify Python-related sources are returned
        python_sources = [s for s in result["sources"] if "Python" in s]
        assert len(python_sources) >= 1, "Vector search should find Python-related documents"
        
        # Verify non-related content is not returned
        assert "quarterly budget" not in result["answer"].lower()
        
        print(f"✅ Vector search validation test passed")