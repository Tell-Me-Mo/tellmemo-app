import 'package:flutter_test/flutter_test.dart';
import 'package:pm_master_v2/features/content/presentation/providers/processing_jobs_provider.dart';
import 'package:pm_master_v2/features/jobs/domain/models/job_model.dart';

void main() {
  group('ProcessingJob', () {
    test('creates job with correct properties', () {
      final job = ProcessingJob(
        jobId: 'job-123',
        contentId: 'content-456',
        projectId: 'project-789',
      );

      expect(job.jobId, 'job-123');
      expect(job.contentId, 'content-456');
      expect(job.projectId, 'project-789');
      expect(job.jobModel, isNull);
      expect(job.summaryId, isNull);
    });

    test('copyWith updates jobModel', () {
      final job = ProcessingJob(
        jobId: 'job-123',
        projectId: 'project-789',
      );

      final now = DateTime.now();
      final jobModel = JobModel(
        jobId: 'job-123',
        projectId: 'project-789',
        jobType: JobType.transcription,
        status: JobStatus.processing,
        progress: 50,
        createdAt: now,
        updatedAt: now,
      );

      final updatedJob = job.copyWith(jobModel: jobModel);

      expect(updatedJob.jobModel, jobModel);
      expect(updatedJob.jobId, job.jobId);
      expect(updatedJob.projectId, job.projectId);
    });

    test('isCompleted returns true when job status is completed', () {
      final now = DateTime.now();
      final jobModel = JobModel(
        jobId: 'job-123',
        projectId: 'project-789',
        jobType: JobType.transcription,
        status: JobStatus.completed,
        progress: 100,
        createdAt: now,
        updatedAt: now,
      );

      final job = ProcessingJob(
        jobId: 'job-123',
        projectId: 'project-789',
        jobModel: jobModel,
      );

      expect(job.isCompleted, true);
      expect(job.isFailed, false);
      expect(job.isProcessing, false);
    });

    test('isFailed returns true when job status is failed', () {
      final now = DateTime.now();
      final jobModel = JobModel(
        jobId: 'job-123',
        projectId: 'project-789',
        jobType: JobType.transcription,
        status: JobStatus.failed,
        progress: 0,
        createdAt: now,
        updatedAt: now,
      );

      final job = ProcessingJob(
        jobId: 'job-123',
        projectId: 'project-789',
        jobModel: jobModel,
      );

      expect(job.isCompleted, false);
      expect(job.isFailed, true);
      expect(job.isProcessing, false);
    });

    test('isProcessing returns true when job status is processing', () {
      final now = DateTime.now();
      final jobModel = JobModel(
        jobId: 'job-123',
        projectId: 'project-789',
        jobType: JobType.transcription,
        status: JobStatus.processing,
        progress: 50,
        createdAt: now,
        updatedAt: now,
      );

      final job = ProcessingJob(
        jobId: 'job-123',
        projectId: 'project-789',
        jobModel: jobModel,
      );

      expect(job.isCompleted, false);
      expect(job.isFailed, false);
      expect(job.isProcessing, true);
    });

    test('isProcessing returns true when job status is pending', () {
      final now = DateTime.now();
      final jobModel = JobModel(
        jobId: 'job-123',
        projectId: 'project-789',
        jobType: JobType.transcription,
        status: JobStatus.pending,
        progress: 0,
        createdAt: now,
        updatedAt: now,
      );

      final job = ProcessingJob(
        jobId: 'job-123',
        projectId: 'project-789',
        jobModel: jobModel,
      );

      expect(job.isProcessing, true);
    });

    test('progress returns correct value from jobModel', () {
      final now = DateTime.now();
      final jobModel = JobModel(
        jobId: 'job-123',
        projectId: 'project-789',
        jobType: JobType.transcription,
        status: JobStatus.processing,
        progress: 75,
        createdAt: now,
        updatedAt: now,
      );

      final job = ProcessingJob(
        jobId: 'job-123',
        projectId: 'project-789',
        jobModel: jobModel,
      );

      expect(job.progress, 75);
    });

    test('progress returns 0 when jobModel is null', () {
      final job = ProcessingJob(
        jobId: 'job-123',
        projectId: 'project-789',
      );

      expect(job.progress, 0);
    });
  });

  // Note: Full provider integration tests would require mocking WebSocket service
  // and other dependencies, which would complicate the test setup significantly.
  // The ProcessingJob class tests above cover the core business logic.
  // UI-level testing of the refresh behavior should be done via widget/integration tests
  // that can verify the dashboard actually updates when recordings complete.
}
