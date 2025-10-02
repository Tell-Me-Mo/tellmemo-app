"""
API Integration Tests - Error Handling and Edge Cases
Tests for API error handling, validation, and edge cases
"""

import pytest
from httpx import AsyncClient
from fastapi import status
import asyncio
import uuid


@pytest.mark.asyncio
class TestErrorHandling:
    """Test API error handling and edge cases"""
    
    async def test_invalid_uuid_formats(self, api_client: AsyncClient):
        """Test handling of invalid UUID formats across endpoints"""
        invalid_uuids = [
            "not-a-uuid",
            "123456",
            "xyz-abc-def",
            "",
            "00000000-0000-0000-0000-00000000000g",  # Invalid character
            "00000000-0000-0000-0000-0000000000",     # Too short
        ]
        
        for invalid_id in invalid_uuids:
            # Test project endpoint
            response = await api_client.get(f"/api/projects/{invalid_id}")
            assert response.status_code in [
                status.HTTP_422_UNPROCESSABLE_ENTITY,
                status.HTTP_404_NOT_FOUND
            ]
            
            # Test content endpoint
            response = await api_client.get(f"/api/projects/{invalid_id}/content")
            assert response.status_code in [
                status.HTTP_422_UNPROCESSABLE_ENTITY,
                status.HTTP_404_NOT_FOUND
            ]
    
    async def test_malformed_json_requests(self, api_client: AsyncClient):
        """Test handling of malformed JSON in request bodies"""
        # Invalid JSON string
        response = await api_client.post(
            "/api/projects",
            content='{"name": "Test", "description": invalid json}',
            headers={"Content-Type": "application/json"}
        )
        assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY
    
    async def test_missing_required_fields(self, api_client: AsyncClient):
        """Test validation of required fields"""
        # Project without name
        response = await api_client.post(
            "/api/projects",
            json={"description": "No name project"}
        )
        assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY
        
        # Upload without content_type
        test_project = await self._create_test_project(api_client)
        try:
            response = await api_client.post(
                f"/api/projects/{test_project}/upload/text",
                json={"title": "No type", "content": "Some content"}
            )
            assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY
        finally:
            await api_client.delete(f"/api/projects/{test_project}")
    
    async def test_invalid_enum_values(self, api_client: AsyncClient):
        """Test handling of invalid enum values"""
        test_project = await self._create_test_project(api_client)
        try:
            # Invalid content_type
            response = await api_client.post(
                f"/api/projects/{test_project}/upload/text",
                json={
                    "content_type": "invalid_type",
                    "title": "Test",
                    "content": "Content"
                }
            )
            assert response.status_code in [
                status.HTTP_400_BAD_REQUEST,
                status.HTTP_422_UNPROCESSABLE_ENTITY
            ]
            
            # Invalid project status
            response = await api_client.put(
                f"/api/projects/{test_project}",
                json={"status": "invalid_status"}
            )
            assert response.status_code in [
                status.HTTP_400_BAD_REQUEST,
                status.HTTP_422_UNPROCESSABLE_ENTITY
            ]
        finally:
            await api_client.delete(f"/api/projects/{test_project}")
    
    async def test_request_size_limits(self, api_client: AsyncClient):
        """Test handling of oversized requests"""
        test_project = await self._create_test_project(api_client)
        try:
            # Very large content (simulate > 10MB)
            huge_content = "X" * (11 * 1024 * 1024)  # 11MB
            
            response = await api_client.post(
                f"/api/projects/{test_project}/upload/text",
                json={
                    "content_type": "meeting",
                    "title": "Huge content",
                    "content": huge_content,
                    "date": "2024-02-26"
                }
            )
            
            # Should reject or handle gracefully
            assert response.status_code in [
                status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
                status.HTTP_400_BAD_REQUEST,
                status.HTTP_422_UNPROCESSABLE_ENTITY
            ]
        finally:
            await api_client.delete(f"/api/projects/{test_project}")
    
    async def test_sql_injection_attempts(self, api_client: AsyncClient):
        """Test that SQL injection attempts are handled safely"""
        # Try SQL injection in project name
        malicious_names = [
            "'; DROP TABLE projects; --",
            "1' OR '1'='1",
            "admin'--",
            "' UNION SELECT * FROM users--"
        ]
        
        for malicious_name in malicious_names:
            response = await api_client.post(
                "/api/projects",
                json={
                    "name": malicious_name,
                    "description": "Test SQL injection",
                    "created_by": "test@example.com"
                }
            )
            
            # Should either create safely or reject
            if response.status_code == status.HTTP_201_CREATED:
                # Clean up if created
                project_id = response.json()["id"]
                await api_client.delete(f"/api/projects/{project_id}")
                
                # Verify the system is still working
                health_response = await api_client.get("/api/health")
                assert health_response.status_code == status.HTTP_200_OK
    
    async def test_xss_prevention(self, api_client: AsyncClient):
        """Test that XSS attempts are handled safely"""
        test_project = await self._create_test_project(api_client)
        try:
            xss_payloads = [
                "<script>alert('XSS')</script>",
                "javascript:alert('XSS')",
                "<img src=x onerror=alert('XSS')>",
                "<svg onload=alert('XSS')>"
            ]
            
            for payload in xss_payloads:
                response = await api_client.post(
                    f"/api/projects/{test_project}/upload/text",
                    json={
                        "content_type": "meeting",
                        "title": payload,
                        "content": f"Content with {payload}",
                        "date": "2024-02-27"
                    }
                )
                
                # Should accept but sanitize or escape
                if response.status_code == status.HTTP_202_ACCEPTED:
                    content_id = response.json()["content_id"]
                    
                    # Wait for processing
                    await asyncio.sleep(3)
                    
                    # Retrieve and verify content is safe
                    response = await api_client.get(
                        f"/api/projects/{test_project}/content/{content_id}"
                    )
                    
                    if response.status_code == status.HTTP_200_OK:
                        content = response.json()
                        # Verify script tags are escaped or removed
                        assert "<script>" not in content.get("title", "")
                        assert "javascript:" not in content.get("title", "")
        finally:
            await api_client.delete(f"/api/projects/{test_project}")
    
    async def test_concurrent_resource_access(self, api_client: AsyncClient):
        """Test handling of concurrent access to same resource"""
        test_project = await self._create_test_project(api_client)
        try:
            # Multiple concurrent updates to same project
            update_tasks = []
            for i in range(5):
                update_data = {
                    "name": f"Concurrent Update {i}",
                    "description": f"Update number {i}"
                }
                task = api_client.put(
                    f"/api/projects/{test_project}",
                    json=update_data
                )
                update_tasks.append(task)
            
            responses = await asyncio.gather(*update_tasks, return_exceptions=True)
            
            # All should complete without errors
            success_count = sum(
                1 for r in responses 
                if not isinstance(r, Exception) and r.status_code == status.HTTP_200_OK
            )
            assert success_count >= 1  # At least one should succeed
            
            # Verify final state is consistent
            response = await api_client.get(f"/api/projects/{test_project}")
            assert response.status_code == status.HTTP_200_OK
            
        finally:
            await api_client.delete(f"/api/projects/{test_project}")
    
    async def test_rate_limiting_behavior(self, api_client: AsyncClient):
        """Test API behavior under high request rate"""
        # Send many requests quickly
        tasks = []
        for _ in range(20):
            task = api_client.get("/api/health")
            tasks.append(task)
        
        responses = await asyncio.gather(*tasks, return_exceptions=True)
        
        # Count successful responses
        success_count = sum(
            1 for r in responses 
            if not isinstance(r, Exception) and r.status_code == status.HTTP_200_OK
        )
        
        # Should handle all requests (no rate limiting in dev) or rate limit gracefully
        assert success_count >= 10  # At least half should succeed
        
        # If rate limited, should return appropriate status
        rate_limited = [
            r for r in responses 
            if not isinstance(r, Exception) and r.status_code == status.HTTP_429_TOO_MANY_REQUESTS
        ]
        # Rate limiting is optional in development
    
    async def test_database_connection_recovery(self, api_client: AsyncClient):
        """Test API recovery from database connection issues"""
        # This test would require ability to disconnect/reconnect database
        # For now, just verify health check reports status
        
        response = await api_client.get("/api/health")
        assert response.status_code == status.HTTP_200_OK
        
        data = response.json()
        assert "services" in data
        assert "database" in data["services"]
        
        # Database should be healthy in normal conditions
        assert data["services"]["database"]["status"] in ["healthy", "degraded"]
    
    async def test_invalid_date_formats(self, api_client: AsyncClient):
        """Test handling of invalid date formats"""
        test_project = await self._create_test_project(api_client)
        try:
            invalid_dates = [
                "not-a-date",
                "2024-13-01",  # Invalid month
                "2024-02-30",  # Invalid day
                "02/28/2024",  # Wrong format
                "2024",        # Incomplete
            ]
            
            for invalid_date in invalid_dates:
                response = await api_client.post(
                    f"/api/projects/{test_project}/upload/text",
                    json={
                        "content_type": "meeting",
                        "title": "Date test",
                        "content": "Testing date validation",
                        "date": invalid_date
                    }
                )
                
                # Should either handle gracefully or reject
                assert response.status_code in [
                    status.HTTP_202_ACCEPTED,  # May accept and use current date
                    status.HTTP_400_BAD_REQUEST,
                    status.HTTP_422_UNPROCESSABLE_ENTITY
                ]
        finally:
            await api_client.delete(f"/api/projects/{test_project}")
    
    async def test_empty_request_bodies(self, api_client: AsyncClient):
        """Test handling of empty request bodies"""
        # Empty body for POST
        response = await api_client.post(
            "/api/projects",
            json={}
        )
        assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY
        
        # Empty body for PUT
        test_project = await self._create_test_project(api_client)
        try:
            response = await api_client.put(
                f"/api/projects/{test_project}",
                json={}
            )
            # Should either accept (no changes) or require at least one field
            assert response.status_code in [
                status.HTTP_200_OK,
                status.HTTP_400_BAD_REQUEST,
                status.HTTP_422_UNPROCESSABLE_ENTITY
            ]
        finally:
            await api_client.delete(f"/api/projects/{test_project}")
    
    async def test_special_characters_in_input(self, api_client: AsyncClient):
        """Test handling of special characters in various inputs"""
        special_chars = [
            "Test™",
            "Test®",
            "Test with émojis 😀🎉",
            "Test with unicode: 你好世界",
            "Test with symbols: @#$%^&*()",
            "Test\nwith\nnewlines",
            "Test\twith\ttabs",
        ]
        
        for special_name in special_chars:
            response = await api_client.post(
                "/api/projects",
                json={
                    "name": special_name,
                    "description": f"Testing: {special_name}",
                    "created_by": "test@example.com"
                }
            )
            
            # Should handle gracefully
            assert response.status_code in [
                status.HTTP_201_CREATED,
                status.HTTP_400_BAD_REQUEST
            ]
            
            if response.status_code == status.HTTP_201_CREATED:
                # Clean up
                project_id = response.json()["id"]
                await api_client.delete(f"/api/projects/{project_id}")
    
    # Helper methods
    async def _create_test_project(self, api_client: AsyncClient) -> str:
        """Helper to create a test project"""
        response = await api_client.post(
            "/api/projects",
            json={
                "name": "Error Test Project",
                "description": "Project for error testing",
                "created_by": "test@example.com"
            }
        )
        return response.json()["id"]