#!/usr/bin/env python3
"""Test script for project summary job-based generation"""

import asyncio
import json
import uuid
from datetime import datetime, timedelta
from services.core.upload_job_service import upload_job_service, JobType
from utils.logger import get_logger

logger = get_logger(__name__)

async def test_job_creation():
    """Test creating a project summary job"""
    try:
        # Start the job service
        upload_job_service.start()
        
        # Create a test job
        project_id = "4d15e5ca-6433-42bc-a6b5-8a01f964312e"  # Use your test project ID
        
        job_id = upload_job_service.create_job(
            project_id=project_id,
            job_type=JobType.PROJECT_SUMMARY,
            filename=f"project_summary_test_{datetime.now().strftime('%Y%m%d')}",
            metadata={
                "period_start": (datetime.now() - timedelta(days=7)).isoformat(),
                "period_end": datetime.now().isoformat(),
                "created_by": "test_user"
            },
            total_steps=3
        )
        
        job = upload_job_service.get_job(job_id)
        
        print(f"Created job: {job.job_id}")
        print(f"Job type: {job.job_type.value}")
        print(f"Job status: {job.status.value}")
        
        # Simulate progress updates
        await asyncio.sleep(1)
        await upload_job_service.update_job_progress_async(
            job_id,
            progress=20.0,
            current_step=1,
            step_description="Collecting meeting data"
        )
        print("Updated progress to 20%")
        
        await asyncio.sleep(1)
        await upload_job_service.update_job_progress_async(
            job_id,
            progress=50.0,
            current_step=2,
            step_description="Analyzing discussions"
        )
        print("Updated progress to 50%")
        
        await asyncio.sleep(1)
        await upload_job_service.update_job_progress_async(
            job_id,
            progress=80.0,
            current_step=3,
            step_description="Generating summary"
        )
        print("Updated progress to 80%")
        
        await asyncio.sleep(1)
        # Complete the job
        await upload_job_service.complete_job(
            job_id,
            result={
                "summary_id": str(uuid.uuid4()),
                "project_id": project_id,
                "summary_type": "project"
            }
        )
        print("Job completed successfully")
        
        # Get final job status
        final_job = upload_job_service.get_job(job_id)
        print(f"Final job status: {final_job.status.value}")
        print(f"Final job result: {json.dumps(final_job.result, indent=2)}")
        
        # Stop the service
        upload_job_service.shutdown()
        
    except Exception as e:
        print(f"Test failed: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    asyncio.run(test_job_creation())