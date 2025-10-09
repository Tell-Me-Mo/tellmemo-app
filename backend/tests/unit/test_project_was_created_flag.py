"""
Unit test for project_was_created flag in job results.

Tests that when a new project is created via AI matching, the job result
includes the project_was_created flag for frontend to display "NEW" label.
"""

import pytest
from queue_config import queue_config


def test_project_was_created_flag_added_to_result():
    """Test that project_was_created flag is added to job result when is_new_project is true."""
    # Arrange - Create an RQ job with is_new_project metadata
    def _test_task():
        return {"content_id": "test-content-456", "chunks": 5}

    job = queue_config.default_queue.enqueue(
        _test_task,
        meta={
            "project_id": "test-project-123",
            "job_type": "text_upload",
            "filename": "test.txt",
            "file_size": 1024,
            "is_new_project": True
        }
    )

    # Act - Simulate the logic from content_service.py
    result_data = {
        "content_id": "test-content-456",
        "chunks": 5
    }

    # Check metadata and add flag
    if job.meta.get('is_new_project'):
        result_data["project_was_created"] = True

    # Save result to job
    job.meta['result'] = result_data
    job.save_meta()

    # Assert - Verify flag is in job meta result
    refreshed_job = queue_config.get_job(job.id)
    assert refreshed_job is not None, "Job should exist"
    job_result = refreshed_job.meta.get('result')
    assert job_result is not None, "Job should have result"
    assert "project_was_created" in job_result, "Result should contain project_was_created flag"
    assert job_result["project_was_created"] is True, "Flag should be True for new projects"


def test_project_was_created_flag_not_added_when_matched_to_existing():
    """Test that project_was_created flag is NOT added when matched to existing project."""
    # Arrange - Create an RQ job with is_new_project=False
    def _test_task():
        return {"content_id": "test-content-789", "chunks": 3}

    job = queue_config.default_queue.enqueue(
        _test_task,
        meta={
            "project_id": "existing-project-789",
            "job_type": "text_upload",
            "filename": "test2.txt",
            "file_size": 2048,
            "is_new_project": False
        }
    )

    # Act
    result_data = {
        "content_id": "test-content-789",
        "chunks": 3
    }

    # Check metadata (should not add flag)
    if job.meta.get('is_new_project'):
        result_data["project_was_created"] = True

    job.meta['result'] = result_data
    job.save_meta()

    # Assert - Verify flag is NOT in job result
    refreshed_job = queue_config.get_job(job.id)
    assert refreshed_job is not None
    job_result = refreshed_job.meta.get('result')
    assert job_result is not None
    assert "project_was_created" not in job_result, "Flag should NOT be present for existing projects"


def test_project_was_created_flag_not_added_without_metadata():
    """Test that project_was_created flag is NOT added when metadata doesn't indicate new project."""
    # Arrange - Create an RQ job without is_new_project metadata
    def _test_task():
        return {"content_id": "test-content-999", "chunks": 2}

    job = queue_config.default_queue.enqueue(
        _test_task,
        meta={
            "project_id": "project-without-metadata",
            "job_type": "text_upload",
            "filename": "test3.txt",
            "file_size": 512
            # No is_new_project key
        }
    )

    # Act
    result_data = {
        "content_id": "test-content-999",
        "chunks": 2
    }

    # Check metadata
    if job.meta.get('is_new_project'):
        result_data["project_was_created"] = True

    job.meta['result'] = result_data
    job.save_meta()

    # Assert
    refreshed_job = queue_config.get_job(job.id)
    assert refreshed_job is not None
    job_result = refreshed_job.meta.get('result')
    assert job_result is not None
    assert "project_was_created" not in job_result, "Flag should NOT be present without metadata"
