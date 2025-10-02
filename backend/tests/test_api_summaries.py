"""
API Integration Tests - Summary Management Endpoints
Tests for summary generation and retrieval
"""

import pytest
import uuid
from httpx import AsyncClient
from fastapi import status
import asyncio


@pytest.mark.asyncio
class TestSummaryManagement:
    """Test summary generation and retrieval operations"""
    
    async def test_generate_meeting_summary(self, api_client: AsyncClient, test_project):
        test_project_id = test_project["id"] if isinstance(test_project, dict) else test_project
        """Test generating a summary for a specific meeting"""
        # First upload content
        content_data = {
            "content_type": "meeting",
            "title": "Summary Test Meeting",
            "content": """
            Product Planning Meeting
            Date: 2024-01-30
            Attendees: Product Team
            
            Discussion:
            - Reviewed Q1 roadmap and priorities
            - Discussed new feature requirements from customers
            - Analyzed competitor offerings and market trends
            - Evaluated technical feasibility of proposed features
            
            Decisions Made:
            - Prioritize mobile app improvements for Q1
            - Delay advanced analytics to Q2
            - Allocate 2 additional developers to critical path items
            
            Action Items:
            - Sarah: Create detailed specs for mobile features by Feb 5
            - John: Set up technical spike for new architecture by Feb 3
            - Maria: Schedule customer feedback sessions for Feb 10-12
            
            Next Steps:
            - Review specs in next week's meeting
            - Begin development sprint on Feb 7
            """,
            "date": "2024-01-30"
        }
        
        response = await api_client.post(
            f"/api/projects/{test_project_id}/upload/text",
            json=content_data
        )
        assert response.status_code in [200, 202], f"Upload failed: {response.status_code} - {response.text}"
        content_id = response.json()["id"]
        
        # Wait for processing
        await asyncio.sleep(5)
        
        # Generate summary
        summary_request = {
            "type": "meeting",
            "content_id": content_id
        }
        
        response = await api_client.post(
            f"/api/projects/{test_project_id}/summary",
            json=summary_request
        )
        
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        
        assert "summary_id" in data
        assert "summary" in data
        assert data["summary"]["type"] == "meeting"
        assert "key_points" in data["summary"]
        assert "decisions" in data["summary"]
        assert "action_items" in data["summary"]
        
        return data["summary_id"]
    
    async def test_generate_project_summary(self, api_client: AsyncClient, test_project):
        test_project_id = test_project["id"] if isinstance(test_project, dict) else test_project
        """Test generating a project summary for a project"""
        # Upload multiple meetings for the week
        for i in range(3):
            content_data = {
                "content_type": "meeting",
                "title": f"Project Meeting {i+1}",
                "content": f"""
                Meeting {i+1} for Project Summary
                Date: 2024-02-0{i+1}
                
                Progress:
                - Completed task {i+1}
                - Working on feature {i+1}
                
                Decisions:
                - Decision {i+1} was made
                
                Action Items:
                - Action item {i+1}
                """,
                "date": f"2024-02-0{i+1}"
            }
            
            response = await api_client.post(
                f"/api/projects/{test_project_id}/upload/text",
                json=content_data
            )
            
            # Wait between uploads
            await asyncio.sleep(2)
        
        # Wait for all processing
        await asyncio.sleep(5)
        
        # Generate project summary
        summary_request = {
            "type": "project",
            "date_from": "2024-02-01",
            "date_to": "2024-02-07"
        }
        
        response = await api_client.post(
            f"/api/projects/{test_project_id}/summary",
            json=summary_request
        )
        
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        
        assert "summary_id" in data
        assert data["summary"]["type"] == "project"
        assert "project_highlights" in data["summary"]
        assert "progress_update" in data["summary"]
    
    async def test_get_project_summaries(self, api_client: AsyncClient, test_project):
        test_project_id = test_project["id"] if isinstance(test_project, dict) else test_project
        """Test retrieving all summaries for a project"""
        # Generate a couple of summaries first
        # Upload content
        content_data = {
            "content_type": "meeting",
            "title": "Summary List Test",
            "content": "Meeting content for summary list testing",
            "date": "2024-02-10"
        }
        
        response = await api_client.post(
            f"/api/projects/{test_project_id}/upload/text",
            json=content_data
        )
        assert response.status_code in [200, 202], f"Upload failed: {response.status_code} - {response.text}"
        content_id = response.json()["id"]
        
        await asyncio.sleep(5)
        
        # Generate meeting summary
        response = await api_client.post(
            f"/api/projects/{test_project_id}/summary",
            json={"type": "meeting", "content_id": content_id}
        )
        summary1_id = response.json()["summary_id"]
        
        # Generate project summary
        response = await api_client.post(
            f"/api/projects/{test_project_id}/summary",
            json={"type": "project"}
        )
        summary2_id = response.json()["summary_id"]
        
        # Get all summaries
        response = await api_client.get(f"/api/projects/{test_project}/summaries")
        assert response.status_code == status.HTTP_200_OK
        
        summaries = response.json()
        assert isinstance(summaries, list)
        assert len(summaries) >= 2
        
        summary_ids = [s["id"] for s in summaries]
        assert summary1_id in summary_ids
        assert summary2_id in summary_ids
        
        # Verify summary structure
        for summary in summaries:
            assert "id" in summary
            assert "summary_type" in summary
            assert "created_at" in summary
    
    async def test_get_summaries_by_type(self, api_client: AsyncClient, test_project):
        test_project_id = test_project["id"] if isinstance(test_project, dict) else test_project
        """Test filtering summaries by type"""
        # Create both types of summaries
        # Upload content for meeting summary
        content_data = {
            "content_type": "meeting",
            "title": "Type Filter Test",
            "content": "Content for type filtering",
            "date": "2024-02-11"
        }
        
        response = await api_client.post(
            f"/api/projects/{test_project_id}/upload/text",
            json=content_data
        )
        assert response.status_code in [200, 202], f"Upload failed: {response.status_code} - {response.text}"
        content_id = response.json()["id"]
        
        await asyncio.sleep(5)
        
        # Generate meeting summary
        await api_client.post(
            f"/api/projects/{test_project_id}/summary",
            json={"type": "meeting", "content_id": content_id}
        )
        
        # Generate weekly summary
        await api_client.post(
            f"/api/projects/{test_project_id}/summary",
            json={"type": "weekly"}
        )
        
        # Get meeting summaries only
        response = await api_client.get(
            f"/api/projects/{test_project_id}/summaries?type=meeting"
        )
        assert response.status_code == status.HTTP_200_OK
        
        meeting_summaries = response.json()
        for summary in meeting_summaries:
            assert summary["summary_type"] == "meeting"
        
        # Get project summaries only
        response = await api_client.get(
            f"/api/projects/{test_project_id}/summaries?type=project"
        )
        assert response.status_code == status.HTTP_200_OK

        project_summaries = response.json()
        for summary in project_summaries:
            assert summary["summary_type"] == "project"
    
    async def test_get_specific_summary(self, api_client: AsyncClient, test_project):
        test_project_id = test_project["id"] if isinstance(test_project, dict) else test_project
        """Test retrieving a specific summary by ID"""
        # Generate a summary
        content_data = {
            "content_type": "meeting",
            "title": "Specific Summary Test",
            "content": "Content for specific summary retrieval",
            "date": "2024-02-12"
        }
        
        response = await api_client.post(
            f"/api/projects/{test_project_id}/upload/text",
            json=content_data
        )
        assert response.status_code in [200, 202], f"Upload failed: {response.status_code} - {response.text}"
        content_id = response.json()["id"]
        
        await asyncio.sleep(5)
        
        response = await api_client.post(
            f"/api/projects/{test_project_id}/summary",
            json={"type": "meeting", "content_id": content_id}
        )
        summary_id = response.json()["summary_id"]
        
        # Get specific summary
        response = await api_client.get(
            f"/api/projects/{test_project_id}/summaries/{summary_id}"
        )
        assert response.status_code == status.HTTP_200_OK
        
        summary = response.json()
        assert summary["id"] == summary_id
        assert "key_points" in summary
        assert "decisions" in summary
        assert "action_items" in summary
        assert "body" in summary
        assert "created_at" in summary
    
    async def test_get_nonexistent_summary(self, api_client: AsyncClient, test_project):
        test_project_id = test_project["id"] if isinstance(test_project, dict) else test_project
        """Test retrieving a summary that doesn't exist"""
        fake_id = str(uuid.uuid4())
        
        response = await api_client.get(
            f"/api/projects/{test_project_id}/summaries/{fake_id}"
        )
        
        assert response.status_code == status.HTTP_404_NOT_FOUND
    
    async def test_generate_summary_without_content(self, api_client: AsyncClient, test_project):
        """Test generating a project summary when no content exists"""
        # Create a new project with no content
        project_data = {
            "name": "Empty Project for Summary",
            "description": "No content project",
            "created_by": "test@example.com"
        }
        
        response = await api_client.post("/api/projects", json=project_data)
        empty_project_id = response.json()["id"]
        
        try:
            # Try to generate project summary
            response = await api_client.post(
                f"/api/projects/{empty_project_id}/summary",
                json={"type": "project"}
            )
            
            # Should handle gracefully
            if response.status_code == status.HTTP_200_OK:
                data = response.json()
                assert "No meetings found" in str(data["summary"]) or \
                       "No content available" in str(data["summary"])
            else:
                assert response.status_code == status.HTTP_404_NOT_FOUND
                
        finally:
            # Clean up
            await api_client.delete(f"/api/projects/{empty_project_id}")
    
    async def test_generate_summary_invalid_content_id(self, api_client: AsyncClient, test_project):
        test_project_id = test_project["id"] if isinstance(test_project, dict) else test_project
        """Test generating a meeting summary with invalid content ID"""
        fake_content_id = str(uuid.uuid4())
        
        response = await api_client.post(
            f"/api/projects/{test_project_id}/summary",
            json={"type": "meeting", "content_id": fake_content_id}
        )
        
        assert response.status_code in [
            status.HTTP_404_NOT_FOUND,
            status.HTTP_400_BAD_REQUEST
        ]
    
    async def test_summary_generation_performance(self, api_client: AsyncClient, test_project):
        test_project_id = test_project["id"] if isinstance(test_project, dict) else test_project
        """Test that summary generation completes within acceptable time"""
        # Upload content
        content_data = {
            "content_type": "meeting",
            "title": "Performance Test Meeting",
            "content": "Meeting content " * 100,  # Reasonably sized content
            "date": "2024-02-13"
        }
        
        response = await api_client.post(
            f"/api/projects/{test_project_id}/upload/text",
            json=content_data
        )
        assert response.status_code in [200, 202], f"Upload failed: {response.status_code} - {response.text}"
        content_id = response.json()["id"]
        
        await asyncio.sleep(5)
        
        # Time the summary generation
        import time
        start_time = time.time()
        
        response = await api_client.post(
            f"/api/projects/{test_project_id}/summary",
            json={"type": "meeting", "content_id": content_id}
        )
        
        generation_time = time.time() - start_time
        
        assert response.status_code == status.HTTP_200_OK
        assert generation_time < 10  # Should complete within 10 seconds
    
    async def test_summary_with_date_range(self, api_client: AsyncClient, test_project):
        test_project_id = test_project["id"] if isinstance(test_project, dict) else test_project
        """Test generating summary with specific date range"""
        # Upload content across different dates
        dates = ["2024-02-14", "2024-02-15", "2024-02-20", "2024-02-21"]
        
        for date in dates:
            content_data = {
                "content_type": "meeting",
                "title": f"Meeting on {date}",
                "content": f"Content for {date}",
                "date": date
            }
            
            await api_client.post(
                f"/api/projects/{test_project_id}/upload/text",
                json=content_data
            )
            await asyncio.sleep(1)
        
        await asyncio.sleep(5)
        
        # Generate summary for specific date range
        response = await api_client.post(
            f"/api/projects/{test_project_id}/summary",
            json={
                "type": "project",
                "date_from": "2024-02-14",
                "date_to": "2024-02-16"
            }
        )
        
        assert response.status_code == status.HTTP_200_OK
        
        # The summary should only include meetings from Feb 14-16
        summary = response.json()["summary"]
        
        # Verify it processed the right date range
        assert "2024-02-14" in str(summary) or "2024-02-15" in str(summary) or \
               "February 14" in str(summary) or "February 15" in str(summary) or \
               "2 meetings" in str(summary).lower()