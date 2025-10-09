import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/services/job_websocket_service.dart';
import '../../domain/models/job_model.dart';
import 'package:flutter/foundation.dart';
import '../../../content/presentation/providers/new_items_provider.dart';
import '../../../meetings/presentation/providers/meetings_provider.dart';
import '../../../summaries/presentation/providers/summary_provider.dart';
import '../../../projects/presentation/providers/risks_tasks_provider.dart';
import '../../../projects/presentation/providers/lessons_learned_provider.dart';
import '../../../projects/presentation/providers/projects_provider.dart';

part 'job_websocket_provider.g.dart';

/// WebSocket service provider
/// Using keepAlive to prevent recreation and connection leaks
@Riverpod(keepAlive: true)
JobWebSocketService jobWebSocketService(Ref ref) {
  final service = JobWebSocketService();

  // Auto-connect when service is created
  service.connect();

  // Cleanup on dispose
  ref.onDispose(() {
    debugPrint('[JobWebSocketProvider] Disposing service and closing connection');
    service.dispose();
  });

  return service;
}

/// Stream of job updates from WebSocket
@riverpod
Stream<JobModel> jobWebSocketUpdates(Ref ref) {
  final service = ref.watch(jobWebSocketServiceProvider);
  return service.jobUpdates;
}

/// WebSocket connection state
@riverpod
Stream<bool> jobWebSocketConnectionState(Ref ref) {
  final service = ref.watch(jobWebSocketServiceProvider);
  return service.connectionState;
}

/// Active jobs tracker using WebSocket
@riverpod
class WebSocketActiveJobsTracker extends _$WebSocketActiveJobsTracker {
  final Map<String, JobModel> _activeJobs = {};
  StreamSubscription? _jobUpdateSubscription;
  Timer? _cleanupTimer;
  final Set<String> _invalidatedJobs = {}; // Track which jobs have already triggered invalidations
  
  @override
  Future<List<JobModel>> build() async {
    final service = ref.watch(jobWebSocketServiceProvider);
    
    // Subscribe to job updates
    _jobUpdateSubscription?.cancel();
    _jobUpdateSubscription = service.jobUpdates.listen(
      (job) {
        _handleJobUpdate(job);
      },
      onError: (error) {
        debugPrint('[WebSocketActiveJobsTracker] Stream error: $error');
      },
    );
    
    // Start cleanup timer to remove completed jobs after a delay
    _startCleanupTimer();
    
    // Cleanup on dispose
    ref.onDispose(() {
      _jobUpdateSubscription?.cancel();
      _cleanupTimer?.cancel();
    });
    
    return _activeJobs.values.toList();
  }
  
  void _handleJobUpdate(JobModel job) {
    // Check if this is a child content processing job updating its parent
    final parentJobId = job.metadata['parent_transcription_job_id'] as String?;
    if (parentJobId != null && parentJobId.isNotEmpty && _activeJobs.containsKey(parentJobId)) {
      // This is a child job - update the parent's progress based on child progress
      final parentJob = _activeJobs[parentJobId]!;

      // Map child progress (0-100) to parent progress (75-100)
      // 75 = transcription complete, 100 = everything complete
      final mappedProgress = 75 + (job.progress * 0.25);

      final updatedParent = JobModel(
        jobId: parentJob.jobId,
        projectId: parentJob.projectId,
        jobType: parentJob.jobType,
        status: job.status == JobStatus.completed ? JobStatus.completed : JobStatus.processing,
        progress: job.status == JobStatus.completed ? 100 : mappedProgress,
        currentStep: parentJob.currentStep,
        totalSteps: parentJob.totalSteps,
        stepDescription: job.status == JobStatus.completed
            ? 'All processing complete'
            : (job.stepDescription ?? 'Processing content and generating summary...'),
        createdAt: parentJob.createdAt,
        updatedAt: DateTime.now(),
        completedAt: job.status == JobStatus.completed ? DateTime.now() : null,
        metadata: parentJob.metadata,
        result: job.status == JobStatus.completed ? job.result : parentJob.result,
        errorMessage: job.errorMessage,
        filename: parentJob.filename,
      );

      _activeJobs[parentJobId] = updatedParent;
      debugPrint('[WebSocketActiveJobsTracker] Updated parent job $parentJobId based on child ${job.jobId} progress: ${job.progress}% -> parent: ${mappedProgress.toInt()}%');

      // Don't process the child job itself - we only care about updating the parent
      // Call _updateState() once and return early
      _updateState();
      return;
    }

    // Check if this job has a child content processing job that we should track
    final childJobId = job.metadata['content_processing_job_id'] as String?;
    if (childJobId != null && childJobId.isNotEmpty) {
      // This is a transcription job that has spawned a content processing job
      // Subscribe to the child job so we can track the complete pipeline
      if (!_activeJobs.containsKey(childJobId)) {
        debugPrint('[WebSocketActiveJobsTracker] Transcription job ${job.jobId} has child job $childJobId - subscribing');
        subscribeToJob(childJobId);
      }

      // Check if the child job has completed by looking at the parent's metadata
      final childCompleted = job.metadata['content_processing_completed'] as bool? ?? false;
      if (!childCompleted) {
        // Child is still processing, so keep showing processing status
        // Override the parent job status to show processing
        final updatedJob = JobModel(
          jobId: job.jobId,
          projectId: job.projectId,
          jobType: job.jobType,
          status: JobStatus.processing,  // Keep as processing until child completes
          progress: 75,  // Show as 75% complete (transcription done, summary in progress)
          currentStep: job.currentStep,
          totalSteps: job.totalSteps,
          stepDescription: job.stepDescription ?? 'Transcription complete. Processing content and generating summary...',
          createdAt: job.createdAt,
          updatedAt: job.updatedAt,
          completedAt: job.completedAt,
          metadata: job.metadata,
          result: job.result,
          errorMessage: job.errorMessage,
          filename: job.filename,
        );
        _activeJobs[job.jobId] = updatedJob;
        _updateState();
        return;  // Don't process as completed yet
      }
      // If childCompleted is true, fall through to normal completion handling
    }

    // Update or add job to active jobs
    if (job.status == JobStatus.pending || job.status == JobStatus.processing) {
      _activeJobs[job.jobId] = job;
    } else {
      // Job completed/failed/cancelled - update the job status in active list
      // Keep it for 15 seconds to show completion status in progress widget
      _activeJobs[job.jobId] = job;

      if (job.status == JobStatus.completed) {
        // Check if this is a child job - don't invalidate for child jobs, only for parent jobs
        final isChildJob = job.metadata['parent_transcription_job_id'] != null;

        // Get result and contentId outside the guard so it's available for navigation
        final result = job.result;
        final contentId = result?['content_id'] as String?;

        // Only invalidate providers once per parent job
        if (!isChildJob && !_invalidatedJobs.contains(job.jobId)) {
          _invalidatedJobs.add(job.jobId);

          // Mark the content document as NEW when job completes
          // This ensures items are marked as NEW even after page refresh
          if (contentId != null) {
            ref.read(newItemsProvider.notifier).addNewItem(contentId);
            debugPrint('[WebSocketActiveJobsTracker] Marked content $contentId as NEW');
          }

          // Check for summary ID in the result
          final summaryId = result?['summary_id'] as String? ??
                           result?['id'] as String?;
          if (summaryId != null) {
            ref.read(newItemsProvider.notifier).addNewItem(summaryId);
            debugPrint('[WebSocketActiveJobsTracker] Marked summary $summaryId as NEW');
          }

          // Check if a new project was created during this job
          final projectWasCreated = result?['project_was_created'] as bool? ?? false;
          final actualProjectId = job.metadata['project_id'] as String? ?? job.projectId;

          debugPrint('[WebSocketActiveJobsTracker] Job completed - projectWasCreated: $projectWasCreated, actualProjectId: $actualProjectId, result keys: ${result?.keys.toList()}');

          if (projectWasCreated && actualProjectId.isNotEmpty) {
            ref.read(newItemsProvider.notifier).addNewItem(actualProjectId);
            debugPrint('[WebSocketActiveJobsTracker] Marked project $actualProjectId as NEW');
          }

          // Refresh the lists to show the new items (ONLY ONCE)
          // This ensures the UI updates even after page refresh
          ref.invalidate(meetingsListProvider);
          ref.invalidate(projectSummariesProvider(actualProjectId));
          ref.invalidate(risksNotifierProvider(actualProjectId));
          ref.invalidate(tasksNotifierProvider(actualProjectId));
          ref.invalidate(lessonsLearnedNotifierProvider(actualProjectId));
          ref.invalidate(projectDetailProvider(actualProjectId));
          ref.invalidate(projectsListProvider);
          debugPrint('[WebSocketActiveJobsTracker] Refreshed all content sections (meetings, summaries, risks, tasks, lessons, description, projects) for project $actualProjectId');

          // If it's a transcription or text upload job with content_id, consider navigation
          if (contentId != null &&
              (job.jobType == JobType.transcription || job.jobType == JobType.textUpload)) {

            // Smart navigation logic to handle multiple parallel jobs
            _handleNavigationForCompletedJob(job, contentId);
          }
        }
      }

      // Remove job from active list after a longer delay
      // This allows the UI to show completion status and lets users click the View button
      Future.delayed(const Duration(seconds: 15), () {
        _activeJobs.remove(job.jobId);
        _updateState();

        // All jobs complete - no need for navigation flag anymore
        if (_activeJobs.isEmpty) {
          debugPrint('[WebSocketActiveJobsTracker] All jobs complete');
        }
      });
    }

    _updateState();
  }
  
  void _handleNavigationForCompletedJob(JobModel job, String contentId) {
    // Don't auto-navigate anymore - user will click "View" button if they want to see the summary
    // The processing overlay will show a "View" button when completed

    // Check for integration jobs
    final isFromIntegration = job.metadata['source'] == 'fireflies' ||
                             job.metadata['source'] == 'integration';
    if (isFromIntegration) {
      debugPrint('[WebSocketActiveJobsTracker] Integration job completed (source: ${job.metadata['source']})');
      return;
    }

    // Check if there are other jobs still processing
    final hasOtherActiveJobs = _activeJobs.values.any((j) =>
      j.jobId != job.jobId &&
      (j.status == JobStatus.pending || j.status == JobStatus.processing)
    );

    if (hasOtherActiveJobs) {
      debugPrint('[WebSocketActiveJobsTracker] Job completed but ${_activeJobs.length - 1} other jobs still active');
    } else {
      debugPrint('[WebSocketActiveJobsTracker] All jobs complete, user can click View button to see summary');
    }
  }
  
  void _updateState() {
    state = AsyncValue.data(_activeJobs.values.toList());
  }
  
  void _startCleanupTimer() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      // Remove completed jobs older than 10 seconds
      final now = DateTime.now();
      _activeJobs.removeWhere((id, job) {
        if (job.status == JobStatus.completed || 
            job.status == JobStatus.failed || 
            job.status == JobStatus.cancelled) {
          final completedAt = job.completedAt ?? job.updatedAt;
          return now.difference(completedAt).inSeconds > 10;
        }
        return false;
      });
      
      _updateState();
    });
  }
  
  /// Subscribe to a specific job
  Future<void> subscribeToJob(String jobId) async {
    final service = ref.read(jobWebSocketServiceProvider);
    await service.subscribeToJob(jobId);
    debugPrint('[WebSocketActiveJobsTracker] Subscribed to job $jobId');
  }
  
  /// Subscribe to all jobs in a project
  Future<void> subscribeToProject(String projectId) async {
    final service = ref.read(jobWebSocketServiceProvider);
    await service.subscribeToProject(projectId);
    debugPrint('[WebSocketActiveJobsTracker] Subscribed to project $projectId');
  }
  
  /// Cancel a job
  Future<void> cancelJob(String jobId) async {
    final service = ref.read(jobWebSocketServiceProvider);
    try {
      await service.cancelJob(jobId);
      debugPrint('[WebSocketActiveJobsTracker] Successfully sent cancel request for job $jobId');
    } catch (e) {
      debugPrint('[WebSocketActiveJobsTracker] Error cancelling job $jobId: $e');
      rethrow;
    }
  }
}

/// Provider to track jobs for a specific project
@riverpod
class WebSocketProjectJobsTracker extends _$WebSocketProjectJobsTracker {
  final Map<String, JobModel> _projectJobs = {};
  StreamSubscription? _jobUpdateSubscription;
  
  @override
  Future<List<JobModel>> build(String projectId) async {
    final service = ref.watch(jobWebSocketServiceProvider);
    
    // Subscribe to project jobs
    await service.subscribeToProject(projectId);
    
    // Listen to job updates
    _jobUpdateSubscription?.cancel();
    _jobUpdateSubscription = service.jobUpdates.listen(
      (job) {
        if (job.projectId == projectId) {
          _handleJobUpdate(job);
        }
      },
      onError: (error) {
        debugPrint('[WebSocketProjectJobsTracker] Stream error: $error');
      },
    );
    
    // Cleanup on dispose
    ref.onDispose(() {
      _jobUpdateSubscription?.cancel();
    });
    
    return _projectJobs.values.toList();
  }
  
  void _handleJobUpdate(JobModel job) {
    _projectJobs[job.jobId] = job;
    _updateState();
  }
  
  void _updateState() {
    state = AsyncValue.data(
      _projectJobs.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt))
    );
  }
}

/// Provider to track a specific job
@riverpod
class WebSocketJobTracker extends _$WebSocketJobTracker {
  StreamSubscription? _jobUpdateSubscription;
  
  @override
  Future<JobModel?> build(String jobId) async {
    final service = ref.watch(jobWebSocketServiceProvider);
    
    // Subscribe to this specific job
    await service.subscribeToJob(jobId);
    
    // Get initial status
    service.getJobStatus(jobId);
    
    // Listen to updates for this job
    _jobUpdateSubscription?.cancel();
    _jobUpdateSubscription = service.jobUpdates
        .where((job) => job.jobId == jobId)
        .listen(
          (job) {
            state = AsyncValue.data(job);
          },
          onError: (error) {
            debugPrint('[WebSocketJobTracker] Stream error: $error');
          },
        );
    
    // Cleanup on dispose
    ref.onDispose(() {
      _jobUpdateSubscription?.cancel();
      // Unsubscribe from job
      service.unsubscribeFromJob(jobId);
    });
    
    return null; // Will be updated via stream
  }
}