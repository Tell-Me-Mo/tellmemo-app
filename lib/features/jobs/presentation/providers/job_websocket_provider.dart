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
@riverpod
JobWebSocketService jobWebSocketService(Ref ref) {
  final service = JobWebSocketService();
  
  // Auto-connect when service is created
  service.connect();
  
  // Cleanup on dispose
  ref.onDispose(() {
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
  
  @override
  Future<List<JobModel>> build() async {
    final service = ref.watch(jobWebSocketServiceProvider);
    
    // Subscribe to job updates
    _jobUpdateSubscription?.cancel();
    _jobUpdateSubscription = service.jobUpdates.listen((job) {
      _handleJobUpdate(job);
    });
    
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
    // Update or add job to active jobs
    if (job.status == JobStatus.pending || job.status == JobStatus.processing) {
      _activeJobs[job.jobId] = job;
    } else {
      // Job completed/failed/cancelled - update the job status in active list
      // Keep it for 15 seconds to show completion status in progress widget
      _activeJobs[job.jobId] = job;

      if (job.status == JobStatus.completed) {
        // Check if this is a meeting content that generated a summary
        final result = job.result;
        final contentId = result?['content_id'] as String?;

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

        // Refresh the lists to show the new items
        // This ensures the UI updates even after page refresh
        ref.invalidate(meetingsListProvider);
        ref.invalidate(projectSummariesProvider(job.projectId));
        ref.invalidate(risksNotifierProvider(job.projectId));
        ref.invalidate(tasksNotifierProvider(job.projectId));
        ref.invalidate(lessonsLearnedNotifierProvider(job.projectId));
        ref.invalidate(projectDetailProvider(job.projectId));
        debugPrint('[WebSocketActiveJobsTracker] Refreshed all content sections (meetings, summaries, risks, tasks, lessons, description) for project ${job.projectId}');

        // If it's a transcription or text upload job with content_id, consider navigation
        if (contentId != null &&
            (job.jobType == JobType.transcription || job.jobType == JobType.textUpload)) {

          // Smart navigation logic to handle multiple parallel jobs
          _handleNavigationForCompletedJob(job, contentId);
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
    service.cancelJob(jobId);
    debugPrint('[WebSocketActiveJobsTracker] Cancelling job $jobId');
  }
}

/// Provider to track jobs for a specific project
@riverpod
class WebSocketProjectJobsTracker extends _$WebSocketProjectJobsTracker {
  final Map<String, JobModel> _projectJobs = {};
  StreamSubscription? _jobUpdateSubscription;
  String? _currentProjectId;
  
  @override
  Future<List<JobModel>> build(String projectId) async {
    _currentProjectId = projectId;
    
    final service = ref.watch(jobWebSocketServiceProvider);
    
    // Subscribe to project jobs
    await service.subscribeToProject(projectId);
    
    // Listen to job updates
    _jobUpdateSubscription?.cancel();
    _jobUpdateSubscription = service.jobUpdates.listen((job) {
      if (job.projectId == projectId) {
        _handleJobUpdate(job);
      }
    });
    
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
        .listen((job) {
      state = AsyncValue.data(job);
    });
    
    // Cleanup on dispose
    ref.onDispose(() {
      _jobUpdateSubscription?.cancel();
      // Unsubscribe from job
      service.unsubscribeFromJob(jobId);
    });
    
    return null; // Will be updated via stream
  }
}