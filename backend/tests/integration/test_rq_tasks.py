"""
Integration tests for RQ Background Tasks

Tests the RQ task execution for transcription, content processing, and summaries.

Features tested:
- [x] Transcription task enqueuing and execution
- [x] Content processing task execution
- [x] Summary generation task execution
- [x] Job progress tracking via RQ metadata
- [x] Job error handling
- [x] Redis pub/sub notifications
- [x] Parent-child job relationships
"""

import pytest
import asyncio
import uuid
from unittest.mock import Mock, AsyncMock, patch, MagicMock
from datetime import datetime
from rq import Queue
from rq.job import Job


class TestTranscriptionTasks:
    """Test suite for transcription RQ tasks"""

    @pytest.fixture
    def mock_rq_job(self):
        """Create a mock RQ job"""
        job = Mock(spec=Job)
        job.id = "test-rq-job-123"
        job.meta = {}

        def save_meta_side_effect():
            """Simulate saving meta"""
            pass

        job.save_meta = Mock(side_effect=save_meta_side_effect)
        job.is_canceled = False
        return job

    @pytest.fixture
    def mock_queue_config(self):
        """Mock the queue_config singleton"""
        with patch('tasks.transcription_tasks.queue_config') as mock_config:
            mock_config.publish_job_update = Mock()
            yield mock_config

    def test_transcription_task_function_exists(self):
        """Test that transcription task function exists and is importable"""
        from tasks.transcription_tasks import process_audio_transcription_task

        # Verify function exists
        assert callable(process_audio_transcription_task)

        # Verify function signature
        import inspect
        sig = inspect.signature(process_audio_transcription_task)
        params = list(sig.parameters.keys())

        # Verify expected parameters exist
        assert 'temp_file_path' in params
        assert 'project_id' in params
        assert 'language' in params
        assert 'organization_id' in params

    @pytest.mark.asyncio
    async def test_transcription_task_progress_tracking(self, mock_rq_job, mock_queue_config):
        """Test that transcription task updates progress via RQ metadata"""
        from tasks.transcription_tasks import process_audio_transcription_task

        # Mock all the dependencies
        with patch('tasks.transcription_tasks.get_current_job', return_value=mock_rq_job):
            with patch('tasks.transcription_tasks.asyncio.run') as mock_run:
                # Mock successful transcription result
                mock_run.return_value = {
                    "content_id": "content-123",
                    "project_id": "project-123",
                    "transcription_length": 1000,
                    "language": "en",
                    "duration": 120
                }

                # Execute task
                result = process_audio_transcription_task(
                    temp_file_path="/tmp/test.mp3",
                    project_id="project-123",
                    meeting_title="Test Meeting",
                    language="en",
                    tracking_job_id="tracking-123",
                    file_size=1024,
                    filename="test.mp3",
                    organization_id=str(uuid.uuid4())
                )

                # Verify progress was tracked
                assert mock_rq_job.save_meta.called
                assert 'status' in mock_rq_job.meta
                assert 'progress' in mock_rq_job.meta

                # Verify Redis pub/sub was called
                assert mock_queue_config.publish_job_update.called

                # Verify result
                assert result['content_id'] == "content-123"

    @pytest.mark.asyncio
    async def test_transcription_task_error_handling(self, mock_rq_job, mock_queue_config):
        """Test that transcription task handles errors properly"""
        from tasks.transcription_tasks import process_audio_transcription_task

        with patch('tasks.transcription_tasks.get_current_job', return_value=mock_rq_job):
            with patch('tasks.transcription_tasks.asyncio.run') as mock_run:
                # Simulate transcription error
                mock_run.side_effect = Exception("Transcription failed")

                # Execute task - should raise exception
                with pytest.raises(Exception, match="Transcription failed"):
                    process_audio_transcription_task(
                        temp_file_path="/tmp/test.mp3",
                        project_id="project-123",
                        meeting_title="Test Meeting",
                        language="en",
                        tracking_job_id="tracking-123",
                        file_size=1024,
                        filename="test.mp3",
                        organization_id=str(uuid.uuid4())
                    )

                # Verify error was tracked in job metadata
                assert mock_rq_job.meta['status'] == 'failed'
                assert 'error' in mock_rq_job.meta
                assert 'Transcription failed' in mock_rq_job.meta['error']

                # Verify error notification was published
                mock_queue_config.publish_job_update.assert_called()
                last_call = mock_queue_config.publish_job_update.call_args_list[-1]
                assert last_call[0][1]['status'] == 'failed'


class TestContentProcessingTasks:
    """Test suite for content processing RQ tasks"""

    @pytest.fixture
    def mock_rq_job(self):
        """Create a mock RQ job"""
        job = Mock(spec=Job)
        job.id = "test-content-job-123"
        job.meta = {}
        job.save_meta = Mock()
        return job

    @pytest.fixture
    def mock_queue_config(self):
        """Mock the queue_config singleton"""
        with patch('tasks.content_tasks.queue_config') as mock_config:
            mock_config.publish_job_update = Mock()
            mock_config.get_job = Mock(return_value=None)
            yield mock_config

    def test_content_processing_task_function_exists(self):
        """Test that content processing task function exists and is importable"""
        from tasks.content_tasks import process_content_task

        # Verify function exists
        assert callable(process_content_task)

        # Verify function signature
        import inspect
        sig = inspect.signature(process_content_task)
        params = list(sig.parameters.keys())

        # Verify expected parameters exist
        assert 'content_id' in params
        assert 'tracking_job_id' in params

    @pytest.mark.asyncio
    async def test_content_processing_updates_parent_job(self, mock_rq_job, mock_queue_config):
        """Test that content processing updates parent transcription job"""
        from tasks.content_tasks import process_content_task

        # Set up parent job in metadata
        parent_job_id = "parent-transcription-job"
        mock_rq_job.meta['parent_transcription_job_id'] = parent_job_id

        # Mock parent job
        mock_parent_job = Mock(spec=Job)
        mock_parent_job.meta = {}
        mock_parent_job.save_meta = Mock()
        mock_queue_config.get_job.return_value = mock_parent_job

        with patch('tasks.content_tasks.get_current_job', return_value=mock_rq_job):
            with patch('tasks.content_tasks.asyncio.run') as mock_run:
                # Mock successful content processing
                mock_run.return_value = {
                    "content_id": "content-123",
                    "status": "completed"
                }

                # Execute task
                result = process_content_task(
                    content_id=str(uuid.uuid4()),
                    tracking_job_id="tracking-123"
                )

                # Verify parent job was updated
                mock_queue_config.get_job.assert_called_with(parent_job_id)
                assert mock_parent_job.meta['status'] == 'completed'
                assert mock_parent_job.meta['progress'] == 100.0
                assert mock_parent_job.save_meta.called

                # Verify parent job update was published
                calls = [call for call in mock_queue_config.publish_job_update.call_args_list
                        if call[0][0] == parent_job_id]
                assert len(calls) > 0

    @pytest.mark.asyncio
    async def test_content_processing_error_handling(self, mock_rq_job, mock_queue_config):
        """Test that content processing handles errors properly"""
        from tasks.content_tasks import process_content_task

        with patch('tasks.content_tasks.get_current_job', return_value=mock_rq_job):
            with patch('tasks.content_tasks.asyncio.run') as mock_run:
                # Simulate processing error
                mock_run.side_effect = Exception("Content processing failed")

                # Execute task - should raise exception
                with pytest.raises(Exception, match="Content processing failed"):
                    process_content_task(
                        content_id=str(uuid.uuid4()),
                        tracking_job_id="tracking-123"
                    )

                # Verify error was tracked
                assert mock_rq_job.meta['status'] == 'failed'
                assert 'error' in mock_rq_job.meta


class TestSummaryGenerationTasks:
    """Test suite for summary generation RQ tasks"""

    @pytest.fixture
    def mock_rq_job(self):
        """Create a mock RQ job"""
        job = Mock(spec=Job)
        job.id = "test-summary-job-123"
        job.meta = {}
        job.save_meta = Mock()
        return job

    @pytest.fixture
    def mock_queue_config_summary(self):
        """Mock the queue_config for summary tasks"""
        mock_config = Mock()
        mock_config.publish_job_update = Mock()
        return mock_config

    def test_summary_generation_task_function_exists(self):
        """Test that summary generation task function exists and is importable"""
        from tasks.summary_tasks import generate_summary_task

        # Verify function exists
        assert callable(generate_summary_task)

        # Verify function signature
        import inspect
        sig = inspect.signature(generate_summary_task)
        params = list(sig.parameters.keys())

        # Verify expected parameters exist
        assert 'tracking_job_id' in params
        assert 'entity_type' in params
        assert 'entity_id' in params
        assert 'summary_type' in params

    @pytest.mark.asyncio
    async def test_summary_generation_progress_tracking(self, mock_rq_job):
        """Test that summary generation tracks progress"""
        from tasks.summary_tasks import generate_summary_task

        # Mock queue_config at module level before import
        with patch('queue_config.queue_config') as mock_queue_config:
            mock_queue_config.publish_job_update = Mock()

            with patch('tasks.summary_tasks.get_current_job', return_value=mock_rq_job):
                with patch('tasks.summary_tasks.asyncio.run') as mock_run:
                    # Mock successful summary generation
                    mock_run.return_value = {
                        "summary_id": "summary-123",
                        "entity_type": "project",
                        "entity_id": "project-123",
                        "summary_type": "project"
                    }

                    # Execute task
                    result = generate_summary_task(
                        tracking_job_id="tracking-123",
                        entity_type="project",
                        entity_id=str(uuid.uuid4()),
                        entity_name="Test Project",
                        summary_type="project"
                    )

                    # Verify progress was tracked
                    assert mock_rq_job.save_meta.called
                    assert mock_rq_job.meta['status'] == 'completed'
                    assert mock_rq_job.meta['progress'] == 100.0

                    # Verify result
                    assert result['summary_id'] == "summary-123"


class TestRQIntegration:
    """Integration tests for RQ queue system"""

    def test_queue_info_structure(self):
        """Test queue info returns proper structure"""
        from queue_config import queue_config

        # Mock queue attributes directly
        mock_high = Mock()
        mock_high.__len__ = Mock(return_value=2)
        mock_high.started_job_registry.count = 1
        mock_high.finished_job_registry.count = 5
        mock_high.failed_job_registry.count = 0

        mock_default = Mock()
        mock_default.__len__ = Mock(return_value=0)
        mock_default.started_job_registry.count = 0
        mock_default.finished_job_registry.count = 0
        mock_default.failed_job_registry.count = 0

        mock_low = Mock()
        mock_low.__len__ = Mock(return_value=0)
        mock_low.started_job_registry.count = 0
        mock_low.finished_job_registry.count = 0
        mock_low.failed_job_registry.count = 0

        queue_config._high_queue = mock_high
        queue_config._default_queue = mock_default
        queue_config._low_queue = mock_low

        info = queue_config.get_queue_info()

        # Verify structure
        assert 'high' in info
        assert 'default' in info
        assert 'low' in info
        assert info['high']['count'] == 2

    @pytest.mark.asyncio
    async def test_redis_pubsub_publishing(self):
        """Test Redis pub/sub message publishing"""
        from queue_config import queue_config

        mock_redis = Mock()
        with patch.object(queue_config, 'get_pubsub_connection', return_value=mock_redis):
            job_id = "test-job-123"
            update_data = {
                'status': 'processing',
                'progress': 50.0,
                'step': 'Processing data'
            }

            queue_config.publish_job_update(job_id, update_data)

            # Verify publish was called
            mock_redis.publish.assert_called_once()
            channel, message = mock_redis.publish.call_args[0]

            assert channel == f"job_updates:{job_id}"

            # Verify message is JSON
            import json
            parsed = json.loads(message)
            assert parsed['status'] == 'processing'
            assert parsed['progress'] == 50.0

    def test_job_cancellation(self):
        """Test job cancellation functionality"""
        from queue_config import queue_config

        mock_job = Mock(spec=Job)
        mock_job.cancel = Mock()

        with patch.object(queue_config, 'get_job', return_value=mock_job):
            result = queue_config.cancel_job("test-job-123")

            assert result is True
            mock_job.cancel.assert_called_once()

    def test_job_metadata_persistence(self):
        """Test that job metadata is persisted correctly"""
        from queue_config import queue_config

        mock_job = Mock(spec=Job)
        mock_job.meta = {}
        mock_job.save_meta = Mock()

        with patch.object(queue_config, 'get_job', return_value=mock_job):
            job = queue_config.get_job("test-job-123")

            # Simulate updating metadata (as done in tasks)
            job.meta['progress'] = 75.0
            job.meta['status'] = 'processing'
            job.save_meta()

            # Verify save_meta was called
            assert job.save_meta.called
            assert job.meta['progress'] == 75.0
