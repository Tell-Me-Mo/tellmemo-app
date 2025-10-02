"""
API Integration Tests - Content Management Endpoints
Tests for file uploads, text uploads, and content retrieval
"""

import pytest
import uuid
import io
from httpx import AsyncClient
from fastapi import status
import asyncio


@pytest.mark.asyncio
class TestContentManagement:
    """Test content upload and retrieval operations"""
    
    async def test_upload_text_content(self, api_client: AsyncClient, test_project):
        test_project_id = test_project["id"] if isinstance(test_project, dict) else test_project
        """Test uploading text content directly"""
        content_data = {
            "content_type": "meeting",
            "title": "API Test Meeting",
            "content": """
            Meeting Notes - API Integration Test
            Date: 2024-01-20
            Attendees: Test Suite
            
            Discussion Points:
            1. API endpoints are working correctly
            2. Integration tests are comprehensive
            3. Performance metrics are within acceptable ranges
            
            Decisions:
            - Continue with current testing approach
            - Add more edge case scenarios
            
            Action Items:
            - Complete remaining test cases
            - Document test coverage
            """,
            "date": "2024-01-20"
        }
        
        response = await api_client.post(
            f"/api/projects/{test_project_id}/upload/text",
            json=content_data
        )
        
        assert response.status_code in [status.HTTP_200_OK, status.HTTP_202_ACCEPTED]
        data = response.json()
        
        assert "id" in data
        assert "message" in data
        assert data["status"] == "processing"
        
        # Wait for processing to complete
        await asyncio.sleep(3)
        
        return data["id"]
    
    async def test_upload_file_content(self, api_client: AsyncClient, test_project):
        """Test uploading content via file upload"""
        test_project_id = test_project["id"] if isinstance(test_project, dict) else test_project
        # Create a test file
        file_content = b"""
        Project Status Meeting
        Date: 2024-01-21
        
        Progress Update:
        - Completed 80% of planned features
        - API integration is working well
        - Testing coverage at 75%
        
        Next Steps:
        - Finish remaining features
        - Increase test coverage to 90%
        - Prepare for deployment
        """
        
        files = {
            "file": ("meeting_notes.txt", io.BytesIO(file_content), "text/plain")
        }
        
        data = {
            "content_type": "meeting",
            "title": "File Upload Test",
            "date": "2024-01-21"
        }
        
        response = await api_client.post(
            f"/api/projects/{test_project_id}/upload",
            files=files,
            data=data
        )
        
        assert response.status_code in [status.HTTP_200_OK, status.HTTP_202_ACCEPTED]
        result = response.json()
        
        assert "id" in result
        assert result["status"] == "processing"
        
        # Wait for processing
        await asyncio.sleep(3)
        
        return result["id"]
    
    async def test_upload_large_file(self, api_client: AsyncClient, test_project):
        """Test uploading a file near the size limit"""
        test_project_id = test_project["id"] if isinstance(test_project, dict) else test_project
        # Create a 9MB file (under 10MB limit)
        large_content = b"Large meeting transcript. " * 350000  # ~9MB
        
        files = {
            "file": ("large_meeting.txt", io.BytesIO(large_content), "text/plain")
        }
        
        data = {
            "content_type": "meeting",
            "title": "Large File Test",
            "date": "2024-01-22"
        }
        
        response = await api_client.post(
            f"/api/projects/{test_project_id}/upload",
            files=files,
            data=data
        )
        
        assert response.status_code in [status.HTTP_200_OK, status.HTTP_202_ACCEPTED]
        
        # Wait for processing
        await asyncio.sleep(5)
    
    async def test_upload_oversized_file(self, api_client: AsyncClient, test_project):
        """Test uploading a file over the size limit"""
        test_project_id = test_project["id"] if isinstance(test_project, dict) else test_project
        # Create an 11MB file (over 10MB limit)
        oversized_content = b"X" * (11 * 1024 * 1024)
        
        files = {
            "file": ("oversized.txt", io.BytesIO(oversized_content), "text/plain")
        }
        
        data = {
            "content_type": "meeting",
            "title": "Oversized File",
            "date": "2024-01-23"
        }
        
        response = await api_client.post(
            f"/api/projects/{test_project_id}/upload",
            files=files,
            data=data
        )
        
        # Should reject oversized file
        assert response.status_code == status.HTTP_413_REQUEST_ENTITY_TOO_LARGE
    
    async def test_upload_invalid_file_type(self, api_client: AsyncClient, test_project):
        """Test uploading unsupported file type"""
        test_project_id = test_project["id"] if isinstance(test_project, dict) else test_project
        files = {
            "file": ("test.exe", io.BytesIO(b"binary content"), "application/octet-stream")
        }
        
        data = {
            "content_type": "meeting",
            "title": "Invalid File Type",
            "date": "2024-01-24"
        }
        
        response = await api_client.post(
            f"/api/projects/{test_project_id}/upload",
            files=files,
            data=data
        )
        
        # Should reject invalid file type
        assert response.status_code in [
            status.HTTP_400_BAD_REQUEST,
            status.HTTP_415_UNSUPPORTED_MEDIA_TYPE
        ]
    
    async def test_upload_email_content(self, api_client: AsyncClient, test_project):
        """Test uploading email content type"""
        test_project_id = test_project["id"] if isinstance(test_project, dict) else test_project
        email_data = {
            "content_type": "email",
            "title": "RE: Project Update",
            "content": """
            From: client@example.com
            To: team@example.com
            Subject: RE: Project Update
            
            Hi Team,
            
            Thanks for the update. I have a few questions:
            1. Can we accelerate the timeline?
            2. What are the main risks?
            3. Do we need additional resources?
            
            Please let me know your thoughts.
            
            Best regards,
            Client
            """,
            "date": "2024-01-25"
        }
        
        response = await api_client.post(
            f"/api/projects/{test_project_id}/upload/text",
            json=email_data
        )
        
        assert response.status_code in [status.HTTP_200_OK, status.HTTP_202_ACCEPTED]
        data = response.json()
        
        # Verify content type is preserved
        await asyncio.sleep(3)
        
        # Get content to verify type
        response = await api_client.get(f"/api/projects/{test_project_id}/content")
        contents = response.json()
        
        email_content = next(
            (c for c in contents if c["id"] == data["id"]),
            None
        )
        assert email_content is not None
        assert email_content["content_type"] == "email"
    
    async def test_get_project_content_list(self, api_client: AsyncClient, test_project):
        """Test retrieving all content for a project"""
        test_project_id = test_project["id"] if isinstance(test_project, dict) else test_project
        # Upload multiple content items
        content_ids = []
        
        for i in range(3):
            content_data = {
                "content_type": "meeting",
                "title": f"Meeting {i+1}",
                "content": f"Content for meeting {i+1}",
                "date": f"2024-01-{20+i}"
            }
            
            response = await api_client.post(
                f"/api/projects/{test_project_id}/upload/text",
                json=content_data
            )
            content_ids.append(response.json()["id"])
        
        # Wait for processing
        await asyncio.sleep(3)
        
        # Get all content
        response = await api_client.get(f"/api/projects/{test_project_id}/content")
        assert response.status_code == status.HTTP_200_OK
        
        contents = response.json()
        assert isinstance(contents, list)
        assert len(contents) >= 3
        
        # Verify our uploaded content is present
        retrieved_ids = [c["id"] for c in contents]
        for content_id in content_ids:
            assert content_id in retrieved_ids
    
    async def test_get_specific_content(self, api_client: AsyncClient, test_project):
        """Test retrieving specific content by ID"""
        test_project_id = test_project["id"] if isinstance(test_project, dict) else test_project
        # Upload content
        content_data = {
            "content_type": "meeting",
            "title": "Specific Content Test",
            "content": "This is specific content for retrieval testing",
            "date": "2024-01-26"
        }
        
        response = await api_client.post(
            f"/api/projects/{test_project_id}/upload/text",
            json=content_data
        )
        content_id = response.json()["id"]
        
        # Wait for processing
        await asyncio.sleep(3)
        
        # Get specific content
        response = await api_client.get(
            f"/api/projects/{test_project_id}/content/{content_id}"
        )
        assert response.status_code == status.HTTP_200_OK
        
        content = response.json()
        assert content["id"] == content_id
        assert content["title"] == content_data["title"]
        assert content["content_type"] == content_data["content_type"]
        assert "content" in content
        assert "chunk_count" in content
        assert "processing_status" in content
    
    async def test_get_nonexistent_content(self, api_client: AsyncClient, test_project):
        """Test retrieving content that doesn't exist"""
        test_project_id = test_project["id"] if isinstance(test_project, dict) else test_project
        fake_id = str(uuid.uuid4())
        
        response = await api_client.get(
            f"/api/projects/{test_project_id}/content/{fake_id}"
        )
        
        assert response.status_code == status.HTTP_404_NOT_FOUND
    
    async def test_upload_without_required_fields(self, api_client: AsyncClient, test_project):
        """Test upload with missing required fields"""
        test_project_id = test_project["id"] if isinstance(test_project, dict) else test_project
        # Missing content_type
        invalid_data = {
            "title": "Invalid Upload",
            "content": "Some content",
            "date": "2024-01-27"
        }
        
        response = await api_client.post(
            f"/api/projects/{test_project_id}/upload/text",
            json=invalid_data
        )
        
        assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY
    
    async def test_upload_with_invalid_content_type(self, api_client: AsyncClient, test_project):
        """Test upload with invalid content type"""
        test_project_id = test_project["id"] if isinstance(test_project, dict) else test_project
        invalid_data = {
            "content_type": "invalid_type",
            "title": "Invalid Type",
            "content": "Some content",
            "date": "2024-01-28"
        }
        
        response = await api_client.post(
            f"/api/projects/{test_project_id}/upload/text",
            json=invalid_data
        )
        
        assert response.status_code in [
            status.HTTP_400_BAD_REQUEST,
            status.HTTP_422_UNPROCESSABLE_ENTITY
        ]
    
    async def test_content_processing_status(self, api_client: AsyncClient, test_project):
        """Test that content processing status is tracked correctly"""
        test_project_id = test_project["id"] if isinstance(test_project, dict) else test_project
        content_data = {
            "content_type": "meeting",
            "title": "Processing Status Test",
            "content": "Testing processing status tracking",
            "date": "2024-01-29"
        }
        
        response = await api_client.post(
            f"/api/projects/{test_project_id}/upload/text",
            json=content_data
        )
        content_id = response.json()["id"]
        
        # Check initial status
        response = await api_client.get(
            f"/api/projects/{test_project_id}/content/{content_id}"
        )
        content = response.json()
        assert content["processing_status"] in ["processing", "completed"]
        
        # Wait and check again
        await asyncio.sleep(5)
        
        response = await api_client.get(
            f"/api/projects/{test_project_id}/content/{content_id}"
        )
        content = response.json()
        assert content["processing_status"] == "completed"
        assert content["chunk_count"] > 0
    
    async def test_concurrent_uploads(self, api_client: AsyncClient, test_project):
        """Test handling multiple concurrent uploads"""
        test_project_id = test_project["id"] if isinstance(test_project, dict) else test_project
        upload_tasks = []
        
        for i in range(5):
            content_data = {
                "content_type": "meeting",
                "title": f"Concurrent Upload {i}",
                "content": f"Content for concurrent test {i}",
                "date": f"2024-01-{30+i}"
            }
            
            task = api_client.post(
                f"/api/projects/{test_project_id}/upload/text",
                json=content_data
            )
            upload_tasks.append(task)
        
        # Execute all uploads concurrently
        responses = await asyncio.gather(*upload_tasks)
        
        # All should succeed
        for response in responses:
            assert response.status_code in [status.HTTP_200_OK, status.HTTP_202_ACCEPTED]
            assert "content_id" in response.json()