import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../jobs/domain/models/job_model.dart';
import '../../../jobs/domain/services/job_websocket_service.dart';
import '../../../jobs/presentation/providers/job_websocket_provider.dart';
import '../../../meetings/presentation/providers/meetings_provider.dart';
import '../../../summaries/presentation/providers/summary_provider.dart';
import '../../../projects/presentation/providers/projects_provider.dart';
import '../../../projects/presentation/providers/risks_tasks_provider.dart';
import 'content_status_provider.dart';
import 'new_items_provider.dart';

part 'processing_jobs_provider.g.dart';

// State class to track processing jobs
class ProcessingJob {
  final String jobId;
  final String? contentId;
  final String projectId;
  final JobModel? jobModel;
  final DateTime startTime;
  final String? summaryId;
  final Function(String)? onSummaryGenerated;

  ProcessingJob({
    required this.jobId,
    this.contentId,
    required this.projectId,
    this.jobModel,
    DateTime? startTime,
    this.summaryId,
    this.onSummaryGenerated,
  }) : startTime = startTime ?? DateTime.now();

  ProcessingJob copyWith({
    JobModel? jobModel,
    String? summaryId,
  }) {
    return ProcessingJob(
      jobId: jobId,
      contentId: contentId,
      projectId: projectId,
      jobModel: jobModel ?? this.jobModel,
      startTime: startTime,
      summaryId: summaryId ?? this.summaryId,
      onSummaryGenerated: onSummaryGenerated,
    );
  }

  bool get isCompleted => jobModel?.status == JobStatus.completed;
  bool get isFailed => jobModel?.status == JobStatus.failed;
  bool get isProcessing => jobModel?.status == JobStatus.processing || jobModel?.status == JobStatus.pending;
  double get progress => jobModel?.progress ?? 0.0;
}

@Riverpod(keepAlive: true)
class ProcessingJobs extends _$ProcessingJobs {
  final Map<String, StreamSubscription<JobModel>> _subscriptions = {};
  JobWebSocketService? _service;

  @override
  List<ProcessingJob> build() {
    ref.onDispose(() {
      _cleanup();
    });
    return [];
  }

  void _cleanup() {
    // Cancel all subscriptions
    for (final subscription in _subscriptions.values) {
      subscription.cancel();
    }
    _subscriptions.clear();
  }

  // Add a new job to track
  Future<void> addJob({
    required String jobId,
    String? contentId,
    required String projectId,
    Function(String)? onSummaryGenerated,
  }) async {
    // Check if already tracking
    if (state.any((job) => job.jobId == jobId)) {
      return;
    }

    // Add to state
    state = [
      ...state,
      ProcessingJob(
        jobId: jobId,
        contentId: contentId,
        projectId: projectId,
        onSummaryGenerated: onSummaryGenerated,
      ),
    ];

    // Subscribe to WebSocket updates
    _service ??= ref.read(jobWebSocketServiceProvider);
    await _service!.subscribeToJob(jobId);

    // Listen for updates
    final subscription = _service!.jobUpdates
        .where((job) => job.jobId == jobId)
        .listen((jobModel) {
      _updateJob(jobId, jobModel);
    });

    _subscriptions[jobId] = subscription;
  }

  void _updateJob(String jobId, JobModel jobModel) {
    state = state.map((job) {
      if (job.jobId == jobId) {
        // Check if summary was generated
        String? summaryId;
        if (jobModel.status == JobStatus.completed) {
          // For transcription jobs, extract content_id from result if not already set
          String? contentId = job.contentId;
          if (contentId == null && jobModel.result != null) {
            contentId = jobModel.result!['content_id'] as String?;
          }

          // Mark the content document as new if we have a contentId
          if (contentId != null) {
            ref.read(newItemsProvider.notifier).addNewItem(contentId);
          }

          // Extract summary ID from result if available
          // The result might have 'summary_id' or 'id' depending on the backend response
          if (jobModel.result != null) {
            summaryId = jobModel.result!['summary_id'] as String? ??
                       jobModel.result!['id'] as String?;

            // Mark the summary as new
            if (summaryId != null) {
              ref.read(newItemsProvider.notifier).addNewItem(summaryId);
            }

            // Don't call the navigation callback anymore - user will click button to navigate
          }

          // Refresh meetings and summaries lists for the project
          // This ensures new items appear immediately
          ref.invalidate(meetingsListProvider);
          ref.invalidate(projectSummariesProvider(job.projectId));

          // Only refresh projects list if a new project was created via AI matching
          // Check if the result indicates a new project was created
          final isNewProject = jobModel.result?['project_created'] == true ||
                               jobModel.result?['new_project'] == true;
          if (isNewProject) {
            ref.invalidate(projectsListProvider);
          }

          // Refresh project items (risks, tasks, lessons, blockers)
          // Import is at the top of the file, so we can use these providers
          ref.invalidate(blockersNotifierProvider(job.projectId));
        }

        final updatedJob = job.copyWith(
          jobModel: jobModel,
          summaryId: summaryId,
        );

        // Auto-remove completed/failed jobs after longer delay
        // Keep completed jobs visible for 15 seconds so users can see and click view button
        if (updatedJob.isCompleted || updatedJob.isFailed) {
          Future.delayed(const Duration(seconds: 15), () {
            removeJob(jobId);
          });
        }

        return updatedJob;
      }
      return job;
    }).toList();
  }

  // Remove a job from tracking
  void removeJob(String jobId) {
    // Cancel subscription
    _subscriptions[jobId]?.cancel();
    _subscriptions.remove(jobId);

    // Unsubscribe from WebSocket
    try {
      _service?.unsubscribeFromJob(jobId);
    } catch (e) {
      // Ignore errors
    }

    // Remove from state
    state = state.where((job) => job.jobId != jobId).toList();
  }

  // Get jobs for a specific project
  List<ProcessingJob> getProjectJobs(String projectId) {
    return state.where((job) => job.projectId == projectId).toList();
  }

  // Check if any jobs are processing for a project
  bool hasProcessingJobs(String projectId) {
    return state.any((job) => job.projectId == projectId && job.isProcessing);
  }
}

// Provider to check if a specific project has processing jobs
@riverpod
bool hasProcessingContent(Ref ref, String projectId) {
  final jobs = ref.watch(processingJobsProvider);
  return jobs.any((job) => job.projectId == projectId && job.isProcessing);
}

// Provider to get processing jobs for a specific project
@riverpod
List<ProcessingJob> projectProcessingJobs(Ref ref, String projectId) {
  final jobs = ref.watch(processingJobsProvider);
  return jobs.where((job) => job.projectId == projectId).toList();
}