"""
Unit test for project_was_created flag in job results.

Tests that when a new project is created via AI matching, the job result
includes the project_was_created flag for frontend to display "NEW" label.
"""

import pytest
from services.core.upload_job_service import UploadJobService, JobType, JobStatus


def test_project_was_created_flag_added_to_result():
    """Test that project_was_created flag is added to job result when is_new_project is true."""
    # Arrange
    job_service = UploadJobService()

    # Create a job with is_new_project metadata (simulating AI matching creating new project)
    job_id = job_service.create_job(
        project_id="test-project-123",
        job_type=JobType.TEXT_UPLOAD,
        filename="test.txt",
        file_size=1024,
        total_steps=1,
        metadata={"is_new_project": True}
    )

    # Act - Simulate the logic from content_service.py process_content_async (lines 559-561)
    result_data = {
        "content_id": "test-content-456",
        "chunks": 5
    }

    # Get job and check metadata
    job = job_service.get_job(job_id)
    if job and job.metadata.get('is_new_project'):
        result_data["project_was_created"] = True

    # Complete job with result
    job_service.update_job_progress(
        job_id,
        status=JobStatus.COMPLETED,
        progress=100.0,
        result=result_data
    )

    # Assert - Verify flag is in job result
    completed_job = job_service.get_job(job_id)
    assert completed_job is not None, "Job should exist"
    assert completed_job.result is not None, "Job should have result"
    assert "project_was_created" in completed_job.result, "Result should contain project_was_created flag"
    assert completed_job.result["project_was_created"] is True, "Flag should be True for new projects"


def test_project_was_created_flag_not_added_when_matched_to_existing():
    """Test that project_was_created flag is NOT added when matched to existing project."""
    # Arrange
    job_service = UploadJobService()

    # Create a job with is_new_project=False (matched to existing project)
    job_id = job_service.create_job(
        project_id="existing-project-789",
        job_type=JobType.TEXT_UPLOAD,
        filename="test2.txt",
        file_size=2048,
        total_steps=1,
        metadata={"is_new_project": False}
    )

    # Act
    result_data = {
        "content_id": "test-content-789",
        "chunks": 3
    }

    # Get job and check metadata (should not add flag)
    job = job_service.get_job(job_id)
    if job and job.metadata.get('is_new_project'):
        result_data["project_was_created"] = True

    job_service.update_job_progress(
        job_id,
        status=JobStatus.COMPLETED,
        progress=100.0,
        result=result_data
    )

    # Assert - Verify flag is NOT in job result
    completed_job = job_service.get_job(job_id)
    assert completed_job is not None
    assert completed_job.result is not None
    assert "project_was_created" not in completed_job.result, "Flag should NOT be present for existing projects"


def test_project_was_created_flag_not_added_without_metadata():
    """Test that project_was_created flag is NOT added when metadata doesn't indicate new project."""
    # Arrange
    job_service = UploadJobService()

    # Create a job without is_new_project metadata
    job_id = job_service.create_job(
        project_id="project-without-metadata",
        job_type=JobType.TEXT_UPLOAD,
        filename="test3.txt",
        file_size=512,
        total_steps=1,
        metadata={}  # No metadata
    )

    # Act
    result_data = {
        "content_id": "test-content-999",
        "chunks": 2
    }

    job = job_service.get_job(job_id)
    if job and job.metadata.get('is_new_project'):
        result_data["project_was_created"] = True

    job_service.update_job_progress(
        job_id,
        status=JobStatus.COMPLETED,
        progress=100.0,
        result=result_data
    )

    # Assert
    completed_job = job_service.get_job(job_id)
    assert completed_job is not None
    assert completed_job.result is not None
    assert "project_was_created" not in completed_job.result, "Flag should NOT be present without metadata"
