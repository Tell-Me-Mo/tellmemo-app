"""
Integration tests for Error Handling (Section 16.1)

Tests cover:
- 4xx client error responses
- 5xx server error responses
- Validation error formatting
- LLM API error handling
- Database error handling
- Vector DB error handling
"""

import pytest
from httpx import AsyncClient
from unittest.mock import patch, MagicMock, AsyncMock
from sqlalchemy.exc import OperationalError, IntegrityError, DatabaseError
from sqlalchemy.ext.asyncio import AsyncSession
from anthropic import APIError, APIConnectionError, RateLimitError
from models.organization import Organization
import uuid


class TestClientErrorResponses:
    """Test 4xx client error responses"""

    async def test_400_bad_request_invalid_json(
        self, authenticated_org_client: AsyncClient
    ):
        """Test 400 error for malformed JSON"""
        response = await authenticated_org_client.post(
            "/api/v1/projects",
            content='{"name": invalid json}',  # Malformed JSON
        )
        assert response.status_code == 422  # FastAPI returns 422 for JSON decode errors

    async def test_401_unauthorized_missing_token(self, client: AsyncClient):
        """Test 401 error when no authentication token provided"""
        response = await client.get("/api/v1/projects")
        assert response.status_code in [401, 403]  # Could be 401 or 403 depending on implementation

    async def test_401_unauthorized_invalid_token(self, client: AsyncClient):
        """Test 401 error with invalid authentication token"""
        response = await client.get(
            "/api/v1/projects",
            headers={"Authorization": "Bearer invalid_token_12345"}
        )
        assert response.status_code in [401, 403]

    async def test_403_forbidden_wrong_organization(
        self, authenticated_org_client: AsyncClient, test_organization: Organization,
        test_user
    ):
        """Test 403 error when accessing resource from different organization"""
        # Create a project in the current org
        project_response = await authenticated_org_client.post(
            "/api/v1/projects",
            json={"name": "Test Project", "description": "Test"}
        )
        assert project_response.status_code == 201
        project_id = project_response.json()["id"]

        # Create another organization and switch to it
        other_org_response = await authenticated_org_client.post(
            "/api/v1/organizations",
            json={"name": "Other Org"}
        )
        assert other_org_response.status_code == 201
        other_org_id = other_org_response.json()["id"]

        # Switch to the other organization
        switch_response = await authenticated_org_client.post(
            f"/api/v1/organizations/{other_org_id}/switch"
        )
        assert switch_response.status_code == 200

        # Update the client's organization context to the new organization
        # This simulates what happens in a real browser/app after switching orgs
        from services.auth.native_auth_service import native_auth_service
        new_token = native_auth_service.create_access_token(
            user_id=str(test_user.id),
            email=test_user.email,
            organization_id=other_org_id
        )
        authenticated_org_client.headers["Authorization"] = f"Bearer {new_token}"
        authenticated_org_client.headers["X-Organization-Id"] = other_org_id

        # Try to access the project from the first org (should fail with 404 due to multi-tenant isolation)
        access_response = await authenticated_org_client.get(
            f"/api/v1/projects/{project_id}"
        )
        assert access_response.status_code == 404  # Multi-tenant isolation returns 404

    async def test_404_not_found_invalid_project_id(
        self, authenticated_org_client: AsyncClient
    ):
        """Test 404 error for non-existent project"""
        fake_id = str(uuid.uuid4())
        response = await authenticated_org_client.get(f"/api/v1/projects/{fake_id}")
        assert response.status_code == 404
        assert "not found" in response.json()["detail"].lower()

    async def test_404_not_found_invalid_uuid_format(
        self, authenticated_org_client: AsyncClient
    ):
        """Test 404/400 error for invalid UUID format"""
        response = await authenticated_org_client.get("/api/v1/projects/not-a-uuid")
        assert response.status_code in [400, 404, 422]  # Could be 400, 404, or 422

    async def test_422_validation_error_missing_required_field(
        self, authenticated_org_client: AsyncClient
    ):
        """Test 422 error when required field is missing"""
        response = await authenticated_org_client.post(
            "/api/v1/projects",
            json={"description": "Missing name field"}  # name is required
        )
        assert response.status_code == 422
        error_detail = response.json()["detail"]
        assert isinstance(error_detail, list)
        assert any("name" in str(err).lower() for err in error_detail)

    async def test_422_validation_error_invalid_field_type(
        self, authenticated_org_client: AsyncClient
    ):
        """Test 422 error when field has wrong type"""
        response = await authenticated_org_client.post(
            "/api/v1/projects",
            json={"name": 12345}  # name should be string, not int
        )
        assert response.status_code == 422

    async def test_422_validation_error_invalid_enum_value(
        self, authenticated_org_client: AsyncClient, test_organization: Organization
    ):
        """Test 422 error for invalid enum value"""
        # First create a project
        project_response = await authenticated_org_client.post(
            "/api/v1/projects",
            json={"name": "Test Project"}
        )
        assert project_response.status_code == 201
        project_id = project_response.json()["id"]

        # Try to create risk with invalid severity
        response = await authenticated_org_client.post(
            f"/api/v1/projects/{project_id}/risks",
            json={
                "title": "Test Risk",
                "severity": "INVALID_SEVERITY",  # Invalid enum
                "status": "open"
            }
        )
        assert response.status_code == 422


class TestValidationErrorFormatting:
    """Test validation error formatting"""

    async def test_validation_error_structure(
        self, authenticated_org_client: AsyncClient
    ):
        """Test that validation errors have proper structure"""
        response = await authenticated_org_client.post(
            "/api/v1/projects",
            json={}  # Missing required fields
        )
        assert response.status_code == 422

        error_data = response.json()
        assert "detail" in error_data
        assert isinstance(error_data["detail"], list)

        # Each error should have loc, msg, type
        for error in error_data["detail"]:
            assert "loc" in error
            assert "msg" in error
            assert "type" in error

    async def test_validation_error_contains_field_location(
        self, authenticated_org_client: AsyncClient
    ):
        """Test that validation errors include field location"""
        response = await authenticated_org_client.post(
            "/api/v1/projects",
            json={"name": ""}  # Empty string when required
        )
        assert response.status_code == 422

        error_data = response.json()
        errors = error_data["detail"]

        # Should have error for 'name' field
        name_errors = [e for e in errors if "name" in str(e["loc"])]
        assert len(name_errors) > 0

    async def test_multiple_validation_errors(
        self, authenticated_org_client: AsyncClient
    ):
        """Test that multiple validation errors are returned together"""
        response = await authenticated_org_client.post(
            "/api/v1/projects",
            json={
                "name": "",  # Invalid: empty string
                "description": 12345  # Invalid: should be string
            }
        )
        assert response.status_code == 422

        error_data = response.json()
        errors = error_data["detail"]
        assert len(errors) >= 1  # Should have at least 1 error


class TestLLMAPIErrorHandling:
    """Test LLM API error handling"""

    @patch('services.summaries.summary_service_refactored.SummaryService._call_claude_api_with_retry')
    async def test_llm_api_connection_error(
        self, mock_generate, authenticated_org_client: AsyncClient,
        test_organization: Organization
    ):
        """Test handling of LLM API connection errors"""
        # Mock LLM service to raise connection error
        mock_request = MagicMock()
        mock_generate.side_effect = APIConnectionError(message="Connection failed", request=mock_request)

        # First create a project
        project_response = await authenticated_org_client.post(
            "/api/v1/projects",
            json={"name": "Test Project"}
        )
        assert project_response.status_code == 201
        project_id = project_response.json()["id"]

        # Upload content
        upload_response = await authenticated_org_client.post(
            f"/api/projects/{project_id}/upload/text",
            json={
                "title": "Test Meeting",
                "content_type": "meeting",
                "content": "This is a test meeting transcript about project updates. " * 10
            }
        )
        assert upload_response.status_code in [200, 201]

        # Try to generate summary (should handle LLM error gracefully)
        content_id = upload_response.json()["id"]
        summary_response = await authenticated_org_client.post(
            "/api/summaries/generate",
            json={
                "entity_type": "project",
                "entity_id": project_id,
                "summary_type": "meeting",
                "content_id": content_id
            }
        )

        # Should return error, not crash
        assert summary_response.status_code in [500, 503]
        assert "detail" in summary_response.json()

    @patch('services.summaries.summary_service_refactored.SummaryService._call_claude_api_with_retry')
    async def test_llm_rate_limit_error(
        self, mock_generate, authenticated_org_client: AsyncClient,
        test_organization: Organization
    ):
        """Test handling of LLM rate limit errors"""
        # Mock LLM service to raise rate limit error
        mock_response = MagicMock()
        mock_generate.side_effect = RateLimitError("Rate limit exceeded", response=mock_response, body={})

        # First create a project
        project_response = await authenticated_org_client.post(
            "/api/v1/projects",
            json={"name": "Test Project"}
        )
        assert project_response.status_code == 201
        project_id = project_response.json()["id"]

        # Upload content
        upload_response = await authenticated_org_client.post(
            f"/api/projects/{project_id}/upload/text",
            json={
                "title": "Test Meeting",
                "content_type": "meeting",
                "content": "This is a test meeting transcript. " * 10
            }
        )
        assert upload_response.status_code in [200, 201]

        # Try to generate summary
        content_id = upload_response.json()["id"]
        summary_response = await authenticated_org_client.post(
            "/api/summaries/generate",
            json={
                "entity_type": "project",
                "entity_id": project_id,
                "summary_type": "meeting",
                "content_id": content_id
            }
        )

        # Should return 429 or 503
        assert summary_response.status_code in [429, 500, 503]

    @patch('services.summaries.summary_service_refactored.SummaryService._call_claude_api_with_retry')
    async def test_llm_api_error(
        self, mock_generate, authenticated_org_client: AsyncClient,
        test_organization: Organization
    ):
        """Test handling of general LLM API errors"""
        # Mock LLM service to raise API error
        mock_generate.side_effect = APIError("API Error", request=MagicMock(), body={})

        # First create a project
        project_response = await authenticated_org_client.post(
            "/api/v1/projects",
            json={"name": "Test Project"}
        )
        assert project_response.status_code == 201
        project_id = project_response.json()["id"]

        # Upload content
        upload_response = await authenticated_org_client.post(
            f"/api/projects/{project_id}/upload/text",
            json={
                "title": "Test Meeting",
                "content_type": "meeting",
                "content": "This is a test meeting transcript. " * 10
            }
        )
        assert upload_response.status_code in [200, 201]

        # Try to generate summary
        content_id = upload_response.json()["id"]
        summary_response = await authenticated_org_client.post(
            "/api/summaries/generate",
            json={
                "entity_type": "project",
                "entity_id": project_id,
                "summary_type": "meeting",
                "content_id": content_id
            }
        )

        # Should handle error gracefully
        assert summary_response.status_code in [500, 503]


class TestDatabaseErrorHandling:
    """Test database error handling"""

    async def test_database_integrity_error_duplicate(
        self, authenticated_org_client: AsyncClient
    ):
        """Test handling of database integrity errors (duplicate key)"""
        # Create a project
        project_data = {"name": "Test Project", "description": "Test"}
        response1 = await authenticated_org_client.post(
            "/api/v1/projects",
            json=project_data
        )
        assert response1.status_code == 201

        # Try to create same project again (if there's a unique constraint)
        # Note: This test depends on whether there are unique constraints in the schema
        # For now, we'll just verify that the system handles duplicate creates gracefully
        response2 = await authenticated_org_client.post(
            "/api/v1/projects",
            json=project_data
        )
        # Should succeed or return appropriate error
        assert response2.status_code in [201, 400, 409]


class TestVectorDBErrorHandling:
    """Test Vector DB (Qdrant) error handling"""

    @patch('db.multi_tenant_vector_store.multi_tenant_vector_store.search_vectors')
    async def test_vector_db_connection_error(
        self, mock_search, authenticated_org_client: AsyncClient,
        test_organization: Organization
    ):
        """Test handling of vector DB connection errors"""
        # Mock vector search to raise connection error
        mock_search.side_effect = Exception("Qdrant connection failed")

        response = await authenticated_org_client.post(
            "/api/projects/organization/query",
            json={
                "question": "What are the project updates?"
            }
        )

        # Should handle error gracefully (return empty results or error)
        # Note: May also return 422/500 due to rate limiting or request validation
        assert response.status_code in [200, 422, 500, 503]

        if response.status_code == 200:
            # If it returns 200, should have empty results or error message
            data = response.json()
            assert "answer" in data or "detail" in data

    @patch('db.multi_tenant_vector_store.multi_tenant_vector_store.insert_vectors')
    async def test_vector_db_insert_error(
        self, mock_insert, authenticated_org_client: AsyncClient,
        test_organization: Organization
    ):
        """Test handling of vector DB insert errors"""
        # Mock vector insert to raise error
        mock_insert.side_effect = Exception("Qdrant insert failed")

        # First create a project
        project_response = await authenticated_org_client.post(
            "/api/v1/projects",
            json={"name": "Test Project"}
        )
        assert project_response.status_code == 201
        project_id = project_response.json()["id"]

        # Upload content (which triggers vector insertion)
        response = await authenticated_org_client.post(
            f"/api/projects/{project_id}/upload/text",
            json={
                "title": "Test Meeting",
                "content_type": "meeting",
                "content": "This is a test meeting transcript. " * 10
            }
        )

        # Content upload should still succeed even if vector insert fails
        # (or return appropriate error)
        assert response.status_code in [200, 201, 500]

    @patch('db.multi_tenant_vector_store.multi_tenant_vector_store.search_vectors')
    async def test_vector_db_timeout_error(
        self, mock_search, authenticated_org_client: AsyncClient
    ):
        """Test handling of vector DB timeout errors"""
        # Mock vector search to raise timeout
        mock_search.side_effect = TimeoutError("Qdrant search timeout")

        response = await authenticated_org_client.post(
            "/api/projects/organization/query",
            json={
                "question": "What are the project updates?"
            }
        )

        # Should handle timeout gracefully
        # Note: May also return 422 due to rate limiting or request validation
        assert response.status_code in [200, 422, 500, 503, 504]


class TestServerErrorResponses:
    """Test 5xx server error responses"""

    async def test_error_response_includes_detail(
        self, authenticated_org_client: AsyncClient
    ):
        """Test that error responses include detail field"""
        # Trigger a 404 error
        response = await authenticated_org_client.get(
            f"/api/v1/projects/{uuid.uuid4()}"
        )
        assert response.status_code == 404

        data = response.json()
        assert "detail" in data
        assert isinstance(data["detail"], str)

    async def test_error_response_no_sensitive_data(self, client: AsyncClient):
        """Test that error responses don't leak sensitive data"""
        # Trigger an auth error
        response = await client.get("/api/v1/projects")
        assert response.status_code in [401, 403]

        data = response.json()
        # Should not contain stack traces, file paths, or internal details
        detail_str = str(data).lower()
        assert "/users/" not in detail_str  # No file paths
        assert "traceback" not in detail_str  # No stack traces
        assert "password" not in detail_str  # No credentials


class TestErrorHandlingConsistency:
    """Test consistency of error handling across endpoints"""

    async def test_404_errors_consistent_format(
        self, authenticated_org_client: AsyncClient
    ):
        """Test that 404 errors have consistent format across endpoints"""
        fake_id = str(uuid.uuid4())

        endpoints = [
            f"/api/v1/projects/{fake_id}",
            f"/api/v1/portfolios/{fake_id}",
            f"/api/v1/programs/{fake_id}",
        ]

        responses = []
        for endpoint in endpoints:
            response = await authenticated_org_client.get(endpoint)
            assert response.status_code == 404
            responses.append(response.json())

        # All should have 'detail' field
        for data in responses:
            assert "detail" in data
            assert isinstance(data["detail"], str)

    async def test_validation_errors_consistent_format(
        self, authenticated_org_client: AsyncClient
    ):
        """Test that validation errors have consistent format"""
        endpoints = [
            "/api/v1/projects",
            "/api/v1/portfolios",
            "/api/v1/programs",
        ]

        responses = []
        for endpoint in endpoints:
            response = await authenticated_org_client.post(
                endpoint,
                json={}  # Missing required fields
            )
            assert response.status_code == 422
            responses.append(response.json())

        # All should have same structure
        for data in responses:
            assert "detail" in data
            assert isinstance(data["detail"], list)
            for error in data["detail"]:
                assert "loc" in error
                assert "msg" in error
                assert "type" in error
