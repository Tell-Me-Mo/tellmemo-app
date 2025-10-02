"""
API Integration Tests - Scheduler Management Endpoints
Tests for scheduler status, manual triggers, and rescheduling
"""

import pytest
from httpx import AsyncClient
from fastapi import status
import asyncio


@pytest.mark.asyncio
class TestSchedulerManagement:
    """Test scheduler endpoints for automated report generation"""
    
    async def test_get_scheduler_status(self, api_client: AsyncClient):
        """Test getting scheduler status and job list"""
        response = await api_client.get(
            "/api/scheduler/status",
            headers={"x-api-key": "test-api-key"}
        )
        
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        
        assert "scheduler_running" in data
        assert "jobs" in data
        assert isinstance(data["jobs"], list)
        
        # If there are scheduled jobs, verify their structure
        if data["jobs"]:
            job = data["jobs"][0]
            assert "id" in job
            assert "name" in job
            assert "next_run_time" in job
            assert "trigger" in job
    
    async def test_scheduler_status_without_auth(self, api_client: AsyncClient):
        """Test that scheduler status requires authentication"""
        response = await api_client.get("/api/scheduler/status")
        
        assert response.status_code == status.HTTP_403_FORBIDDEN
        assert "API key required" in response.json()["detail"]
    
    async def test_scheduler_status_with_invalid_auth(self, api_client: AsyncClient):
        """Test scheduler status with invalid API key"""
        response = await api_client.get(
            "/api/scheduler/status",
            headers={"x-api-key": "invalid-key"}
        )
        
        assert response.status_code == status.HTTP_403_FORBIDDEN
        assert "Invalid API key" in response.json()["detail"]
    
    async def test_trigger_project_reports_all_projects(self, api_client: AsyncClient, test_project):
        """Test manually triggering project reports for all projects"""
        test_project_id = test_project["id"] if isinstance(test_project, dict) else test_project
        # First upload some content to have data for reports
        content_data = {
            "content_type": "meeting",
            "title": "Meeting for Weekly Report",
            "content": """
            Weekly Status Meeting
            Date: 2024-02-15
            
            Progress:
            - Completed feature A
            - Working on feature B
            
            Blockers:
            - Need design review
            
            Next Week:
            - Complete feature B
            - Start feature C
            """,
            "date": "2024-02-15"
        }
        
        await api_client.post(
            f"/api/projects/{test_project_id}/upload/text",
            json=content_data
        )
        
        await asyncio.sleep(5)
        
        # Trigger project reports
        response = await api_client.post(
            "/api/scheduler/trigger-project-reports",
            json={}
        )
        
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        
        assert "message" in data
        assert "triggered" in data["message"].lower()
        assert "summaries_generated" in data
        assert data["summaries_generated"] >= 0
    
    async def test_trigger_project_reports_specific_project(self, api_client: AsyncClient, test_project):
        """Test triggering project report for a specific project"""
        test_project_id = test_project["id"] if isinstance(test_project, dict) else test_project
        # Upload content
        content_data = {
            "content_type": "meeting",
            "title": "Project Specific Report Test",
            "content": "Meeting content for specific project report",
            "date": "2024-02-16"
        }
        
        await api_client.post(
            f"/api/projects/{test_project_id}/upload/text",
            json=content_data
        )
        
        await asyncio.sleep(5)
        
        # Trigger report for specific project
        response = await api_client.post(
            "/api/scheduler/trigger-project-reports",
            json={"project_id": test_project_id}
        )
        
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        
        assert "summaries_generated" in data
        assert data["summaries_generated"] >= 0
    
    async def test_trigger_reports_invalid_project(self, api_client: AsyncClient):
        """Test triggering reports for non-existent project"""
        fake_project_id = "00000000-0000-0000-0000-000000000000"

        response = await api_client.post(
            "/api/scheduler/trigger-project-reports",
            json={"project_id": fake_project_id}
        )
        
        # Should handle gracefully
        assert response.status_code in [
            status.HTTP_200_OK,  # May return 0 summaries
            status.HTTP_404_NOT_FOUND
        ]
        
        if response.status_code == status.HTTP_200_OK:
            data = response.json()
            assert data["summaries_generated"] == 0
    
    async def test_trigger_reports_without_auth(self, api_client: AsyncClient):
        """Test that trigger endpoint requires authentication"""
        response = await api_client.post(
            "/api/scheduler/trigger-project-reports",
            json={}
        )
        
        assert response.status_code == status.HTTP_403_FORBIDDEN
    
    async def test_reschedule_project_reports(self, api_client: AsyncClient):
        """Test rescheduling the project report generation"""
        reschedule_data = {
            "cron_expression": "0 18 * * FRI",  # 6 PM on Fridays
            "timezone": "America/New_York"
        }
        
        response = await api_client.post(
            "/api/scheduler/reschedule",
            json=reschedule_data
        )
        
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        
        assert "message" in data
        assert "rescheduled" in data["message"].lower()
        assert "next_run_time" in data
    
    async def test_reschedule_with_invalid_cron(self, api_client: AsyncClient):
        """Test rescheduling with invalid cron expression"""
        reschedule_data = {
            "cron_expression": "invalid cron",
            "timezone": "America/New_York"
        }
        
        response = await api_client.post(
            "/api/scheduler/reschedule",
            json=reschedule_data
        )
        
        assert response.status_code == status.HTTP_400_BAD_REQUEST
    
    async def test_reschedule_with_invalid_timezone(self, api_client: AsyncClient):
        """Test rescheduling with invalid timezone"""
        reschedule_data = {
            "cron_expression": "0 17 * * FRI",
            "timezone": "Invalid/Timezone"
        }
        
        response = await api_client.post(
            "/api/scheduler/reschedule",
            json=reschedule_data
        )
        
        assert response.status_code == status.HTTP_400_BAD_REQUEST
    
    async def test_reschedule_without_auth(self, api_client: AsyncClient):
        """Test that reschedule endpoint requires authentication"""
        response = await api_client.post(
            "/api/scheduler/reschedule",
            json={"cron_expression": "0 17 * * FRI"}
        )
        
        assert response.status_code == status.HTTP_403_FORBIDDEN
    
    async def test_scheduler_job_persistence(self, api_client: AsyncClient):
        """Test that scheduled jobs persist across checks"""
        # Get initial status
        response1 = await api_client.get(
            "/api/scheduler/status",
            headers={"x-api-key": "test-api-key"}
        )
        initial_jobs = response1.json()["jobs"]
        
        # Wait a moment
        await asyncio.sleep(2)
        
        # Get status again
        response2 = await api_client.get(
            "/api/scheduler/status",
            headers={"x-api-key": "test-api-key"}
        )
        later_jobs = response2.json()["jobs"]
        
        # Job count should be consistent
        assert len(initial_jobs) == len(later_jobs)
        
        # If project report job exists, it should persist
        initial_project = next(
            (j for j in initial_jobs if "project" in j["name"].lower()),
            None
        )
        later_project = next(
            (j for j in later_jobs if "project" in j["name"].lower()),
            None
        )

        if initial_project:
            assert later_project is not None
            assert initial_project["id"] == later_project["id"]
    
    async def test_concurrent_trigger_requests(self, api_client: AsyncClient, test_project):
        """Test handling concurrent trigger requests"""
        test_project_id = test_project["id"] if isinstance(test_project, dict) else test_project
        # Upload content first
        content_data = {
            "content_type": "meeting",
            "title": "Concurrent Trigger Test",
            "content": "Content for concurrent trigger testing",
            "date": "2024-02-17"
        }
        
        await api_client.post(
            f"/api/projects/{test_project_id}/upload/text",
            json=content_data
        )
        
        await asyncio.sleep(5)
        
        # Send multiple trigger requests concurrently
        tasks = []
        for _ in range(3):
            task = api_client.post(
                "/api/scheduler/trigger-project-reports",
                    json={"project_id": test_project_id}
            )
            tasks.append(task)
        
        responses = await asyncio.gather(*tasks, return_exceptions=True)
        
        # All should complete without errors
        for response in responses:
            if not isinstance(response, Exception):
                assert response.status_code == status.HTTP_200_OK
    
    async def test_scheduler_handles_empty_projects(self, api_client: AsyncClient):
        """Test scheduler behavior with projects that have no content"""
        # Create empty project
        project_data = {
            "name": "Empty Project for Scheduler",
            "description": "No content",
            "created_by": "test@example.com"
        }
        
        response = await api_client.post("/api/projects", json=project_data)
        empty_project_id = response.json()["id"]
        
        try:
            # Trigger report for empty project
            response = await api_client.post(
                "/api/scheduler/trigger-project-reports",
                    json={"project_id": empty_project_id}
            )
            
            assert response.status_code == status.HTTP_200_OK
            data = response.json()
            
            # Should generate 0 or 1 summary (might create empty summary)
            assert data["summaries_generated"] in [0, 1]
            
        finally:
            # Clean up
            await api_client.delete(f"/api/projects/{empty_project_id}")