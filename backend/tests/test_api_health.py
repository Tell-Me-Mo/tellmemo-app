"""
API Integration Tests - Health and Root Endpoints
Tests for system health checks and root endpoint
"""

import pytest
from httpx import AsyncClient
from fastapi import status


@pytest.mark.asyncio
class TestHealthEndpoints:
    """Test health check and root endpoints"""
    
    async def test_health_check_endpoint(self, api_client: AsyncClient):
        """Test /api/health endpoint returns system status"""
        response = await api_client.get("/api/health")
        
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        
        # Verify response structure
        assert "status" in data
        assert data["status"] == "healthy"
        assert "timestamp" in data
        assert "services" in data
        
        # Verify service statuses
        services = data["services"]
        assert "database" in services
        assert "qdrant" in services  # API uses "qdrant" not "vector_store"
        assert services["database"]["status"] in ["healthy", "degraded", "unhealthy"]
        assert services["qdrant"]["status"] in ["healthy", "degraded", "unhealthy", "green"]
        
        # If Langfuse is configured, it should be in services
        if "langfuse" in services:
            assert services["langfuse"]["status"] in ["healthy", "degraded", "unhealthy", "disabled"]
    
    async def test_root_endpoint(self, api_client: AsyncClient):
        """Test root endpoint returns API information"""
        response = await api_client.get("/")
        
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        
        # Verify response structure - API returns different fields
        assert "name" in data
        assert "PM Master" in data["name"] or "Meeting RAG" in data["name"]
        assert "version" in data
        assert "docs" in data
        assert "/docs" in data["docs"]
    
    async def test_health_check_with_service_degradation(self, api_client: AsyncClient):
        """Test health check reports degraded status when services have issues"""
        # This test would require mocking service failures
        # For now, just verify the endpoint is accessible
        response = await api_client.get("/api/health")
        assert response.status_code == status.HTTP_200_OK
        
        data = response.json()
        # Even with degraded services, endpoint should return 200
        assert data["status"] in ["healthy", "degraded"]
    
    async def test_openapi_documentation(self, api_client: AsyncClient):
        """Test that OpenAPI documentation is accessible"""
        response = await api_client.get("/openapi.json")
        
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        
        # Verify OpenAPI schema structure
        assert "openapi" in data
        assert "info" in data
        assert "paths" in data
        
        # Verify API info
        info = data["info"]
        assert "title" in info
        assert "Meeting RAG System" in info["title"]
        assert "version" in info