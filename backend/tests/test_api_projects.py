"""
API Integration Tests - Project Management Endpoints
Tests for complete project CRUD operations and member management
"""

import pytest
import uuid
from httpx import AsyncClient
from fastapi import status
from datetime import datetime


@pytest.mark.asyncio
class TestProjectManagement:
    """Test project CRUD operations"""
    
    async def test_create_project(self, api_client: AsyncClient):
        """Test creating a new project"""
        project_data = {
            "name": "Test Integration Project",
            "description": "Project for API integration testing",
            "created_by": "test@example.com",
            "members": [
                {"name": "John Doe", "email": "john@example.com", "role": "Developer"},
                {"name": "Jane Smith", "email": "jane@example.com", "role": "PM"}
            ]
        }
        
        response = await api_client.post("/api/projects", json=project_data)
        assert response.status_code in [status.HTTP_200_OK, status.HTTP_201_CREATED]
        
        data = response.json()
        assert "id" in data
        assert data["name"] == project_data["name"]
        assert data["description"] == project_data["description"]
        assert data["status"] == "active"
        assert len(data["members"]) == 2
        
        # Clean up
        await api_client.delete(f"/api/projects/{data['id']}")
        
        return data["id"]
    
    async def test_list_projects(self, api_client: AsyncClient):
        """Test listing all projects with filtering"""
        # Create test projects
        project1 = await self._create_test_project(api_client, "Active Project 1", "active")
        project2 = await self._create_test_project(api_client, "Active Project 2", "active")
        project3 = await self._create_test_project(api_client, "Archived Project", "archived")
        
        try:
            # Test listing all projects
            response = await api_client.get("/api/projects")
            assert response.status_code == status.HTTP_200_OK
            
            projects = response.json()
            assert isinstance(projects, list)
            assert len(projects) >= 3
            
            # Test filtering by status
            response = await api_client.get("/api/projects?status=active")
            assert response.status_code == status.HTTP_200_OK
            
            active_projects = response.json()
            active_ids = [p["id"] for p in active_projects]
            assert project1 in active_ids
            assert project2 in active_ids
            assert project3 not in active_ids
            
            # Test filtering archived projects
            response = await api_client.get("/api/projects?status=archived")
            assert response.status_code == status.HTTP_200_OK
            
            archived_projects = response.json()
            archived_ids = [p["id"] for p in archived_projects]
            assert project3 in archived_ids
            assert project1 not in archived_ids
            
        finally:
            # Clean up
            for project_id in [project1, project2, project3]:
                await api_client.delete(f"/api/projects/{project_id}")
    
    async def test_get_project_by_id(self, api_client: AsyncClient):
        """Test retrieving a specific project by ID"""
        # Create test project
        project_id = await self._create_test_project(api_client, "Test Get Project")
        
        try:
            response = await api_client.get(f"/api/projects/{project_id}")
            assert response.status_code == status.HTTP_200_OK
            
            data = response.json()
            assert data["id"] == project_id
            assert data["name"] == "Test Get Project"
            assert "created_at" in data
            assert "members" in data
            
        finally:
            # Clean up
            await api_client.delete(f"/api/projects/{project_id}")
    
    async def test_get_nonexistent_project(self, api_client: AsyncClient):
        """Test retrieving a project that doesn't exist"""
        fake_id = str(uuid.uuid4())
        response = await api_client.get(f"/api/projects/{fake_id}")
        
        assert response.status_code == status.HTTP_404_NOT_FOUND
        assert "Project not found" in response.json()["detail"]
    
    async def test_update_project(self, api_client: AsyncClient):
        """Test updating project details"""
        # Create test project
        project_id = await self._create_test_project(api_client, "Original Name")
        
        try:
            update_data = {
                "name": "Updated Project Name",
                "description": "Updated description",
                "status": "archived"
            }
            
            response = await api_client.put(
                f"/api/projects/{project_id}",
                json=update_data
            )
            assert response.status_code == status.HTTP_200_OK
            
            data = response.json()
            assert data["name"] == update_data["name"]
            assert data["description"] == update_data["description"]
            assert data["status"] == update_data["status"]
            
            # Verify update persisted
            response = await api_client.get(f"/api/projects/{project_id}")
            data = response.json()
            assert data["name"] == update_data["name"]
            assert data["status"] == "archived"
            
        finally:
            # Clean up
            await api_client.delete(f"/api/projects/{project_id}")
    
    async def test_delete_project(self, api_client: AsyncClient):
        """Test deleting (archiving) a project"""
        # Create test project
        project_id = await self._create_test_project(api_client, "To Delete")
        
        # Delete project
        response = await api_client.delete(f"/api/projects/{project_id}")
        assert response.status_code == status.HTTP_200_OK
        
        data = response.json()
        assert data["message"] == "Project archived successfully"
        
        # Verify project is archived, not deleted
        response = await api_client.get(f"/api/projects/{project_id}")
        assert response.status_code == status.HTTP_200_OK
        
        data = response.json()
        assert data["status"] == "archived"
    
    async def test_add_project_member(self, api_client: AsyncClient):
        """Test adding a member to a project"""
        # Create test project
        project_id = await self._create_test_project(api_client, "Member Test")
        
        try:
            member_data = {
                "name": "New Member",
                "email": "newmember@example.com",
                "role": "QA"
            }
            
            response = await api_client.post(
                f"/api/projects/{project_id}/members",
                json=member_data
            )
            assert response.status_code in [status.HTTP_200_OK, status.HTTP_201_CREATED]
            
            data = response.json()
            assert data["message"] == "Member added successfully"
            
            # Verify member was added
            response = await api_client.get(f"/api/projects/{project_id}")
            project = response.json()
            
            member_emails = [m["email"] for m in project["members"]]
            assert member_data["email"] in member_emails
            
        finally:
            # Clean up
            await api_client.delete(f"/api/projects/{project_id}")
    
    async def test_add_duplicate_member(self, api_client: AsyncClient):
        """Test adding a duplicate member fails gracefully"""
        # Create project with initial member
        project_data = {
            "name": "Duplicate Member Test",
            "description": "Test duplicate prevention",
            "created_by": "test@example.com",
            "members": [{"name": "John", "email": "john@example.com", "role": "Dev"}]
        }
        
        response = await api_client.post("/api/projects", json=project_data)
        project_id = response.json()["id"]
        
        try:
            # Try to add same member again
            duplicate_member = {
                "name": "John Duplicate",
                "email": "john@example.com",
                "role": "PM"
            }
            
            response = await api_client.post(
                f"/api/projects/{project_id}/members",
                json=duplicate_member
            )
            
            # Should either fail or handle gracefully
            if response.status_code == status.HTTP_400_BAD_REQUEST:
                assert "already exists" in response.json()["detail"].lower()
            elif response.status_code in [status.HTTP_200_OK, status.HTTP_201_CREATED]:
                # Verify no duplicate was actually added
                response = await api_client.get(f"/api/projects/{project_id}")
                members = response.json()["members"]
                
                john_members = [m for m in members if m["email"] == "john@example.com"]
                assert len(john_members) == 1
                
        finally:
            # Clean up
            await api_client.delete(f"/api/projects/{project_id}")
    
    async def test_remove_project_member(self, api_client: AsyncClient):
        """Test removing a member from a project"""
        # Create project with members
        project_data = {
            "name": "Remove Member Test",
            "description": "Test member removal",
            "created_by": "test@example.com",
            "members": [
                {"name": "Keep Me", "email": "keep@example.com", "role": "Dev"},
                {"name": "Remove Me", "email": "remove@example.com", "role": "QA"}
            ]
        }
        
        response = await api_client.post("/api/projects", json=project_data)
        project_id = response.json()["id"]
        
        try:
            # Remove member
            response = await api_client.delete(
                f"/api/projects/{project_id}/members/remove@example.com"
            )
            assert response.status_code == status.HTTP_200_OK
            
            # Verify member was removed
            response = await api_client.get(f"/api/projects/{project_id}")
            project = response.json()
            
            member_emails = [m["email"] for m in project["members"]]
            assert "remove@example.com" not in member_emails
            assert "keep@example.com" in member_emails
            
        finally:
            # Clean up
            await api_client.delete(f"/api/projects/{project_id}")
    
    async def test_remove_nonexistent_member(self, api_client: AsyncClient):
        """Test removing a member that doesn't exist"""
        # Create test project
        project_id = await self._create_test_project(api_client, "Nonexistent Member")
        
        try:
            response = await api_client.delete(
                f"/api/projects/{project_id}/members/nothere@example.com"
            )
            
            # Should return 404 or handle gracefully
            assert response.status_code in [status.HTTP_404_NOT_FOUND, status.HTTP_200_OK]
            
        finally:
            # Clean up
            await api_client.delete(f"/api/projects/{project_id}")
    
    async def test_invalid_project_id_format(self, api_client: AsyncClient):
        """Test handling of invalid UUID formats"""
        invalid_ids = ["not-a-uuid", "123", "xyz-abc-def", ""]
        
        for invalid_id in invalid_ids:
            response = await api_client.get(f"/api/projects/{invalid_id}")
            assert response.status_code in [
                status.HTTP_307_TEMPORARY_REDIRECT,
                status.HTTP_400_BAD_REQUEST,
                status.HTTP_422_UNPROCESSABLE_ENTITY,
                status.HTTP_404_NOT_FOUND
            ]
    
    # Helper methods
    async def _create_test_project(
        self,
        api_client: AsyncClient,
        name: str,
        status: str = "active"
    ) -> str:
        """Helper to create a test project and return its ID"""
        project_data = {
            "name": name,
            "description": f"Test project: {name}",
            "created_by": "test@example.com",
            "members": []
        }
        
        response = await api_client.post("/api/projects", json=project_data)
        project_id = response.json()["id"]
        
        if status == "archived":
            # Archive the project
            await api_client.put(
                f"/api/projects/{project_id}",
                json={"status": "archived"}
            )
        
        return project_id