import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/models/job_model.dart';
import '../providers/job_websocket_provider.dart';
import '../../../content/presentation/providers/processing_jobs_provider.dart';

class UploadProgressIndicator extends ConsumerWidget {
  final String? jobId;
  final VoidCallback? onDismiss;

  const UploadProgressIndicator({
    super.key,
    this.jobId,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (jobId == null) {
      return const SizedBox.shrink();
    }

    // First try to get job from processingJobsProvider for immediate display
    final processingJobs = ref.watch(processingJobsProvider);

    // Try to find the job in processing jobs
    ProcessingJob? processingJob;
    try {
      processingJob = processingJobs.firstWhere(
        (job) => job.jobId == jobId,
      );
    } catch (e) {
      // Job not found in processing jobs, will use WebSocket fallback
      processingJob = null;
    }

    // Use the jobModel from processingJob if available
    if (processingJob != null) {
      if (processingJob.jobModel != null) {
        // Job has a model - display it
        return _buildCompactIndicator(context, ref, processingJob.jobModel!);
      } else {
        // Job is tracked but no model yet - show pending state
        final pendingJob = JobModel(
          jobId: processingJob.jobId,
          projectId: processingJob.projectId,
          status: JobStatus.pending,
          jobType: JobType.transcription,
          progress: 0,
          currentStep: 0,
          totalSteps: 1,
          createdAt: processingJob.startTime,
          updatedAt: processingJob.startTime,
          metadata: {},
        );

        return _buildCompactIndicator(context, ref, pendingJob);
      }
    }

    // Fallback to WebSocket provider if not in processing jobs
    final jobAsync = ref.watch(webSocketJobTrackerProvider(jobId!));

    return jobAsync.when(
      data: (job) {
        if (job == null) {
          return const SizedBox.shrink();
        }

        return _buildCompactIndicator(context, ref, job);
      },
      loading: () => const LinearProgressIndicator(),
      error: (error, _) => _buildErrorIndicator(context, error),
    );
  }

  Widget _buildCompactIndicator(BuildContext context, WidgetRef ref, JobModel job) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    Color progressColor;
    IconData icon;
    String statusText;
    Color? containerColor;

    switch (job.status) {
      case JobStatus.completed:
        progressColor = Colors.green;
        icon = Icons.check_circle_outline;
        statusText = 'Complete';
        break;
      case JobStatus.failed:
        progressColor = Colors.red;
        icon = Icons.error_outline;
        statusText = 'Failed';
        containerColor = Colors.red.withValues(alpha: 0.1);
        break;
      case JobStatus.cancelled:
        progressColor = Colors.orange;
        icon = Icons.cancel_outlined;
        statusText = 'Cancelled';
        break;
      case JobStatus.processing:
        progressColor = theme.colorScheme.primary;
        icon = Icons.sync;
        statusText = 'Processing';
        break;
      default:
        progressColor = theme.colorScheme.primary.withValues(alpha: 0.7);
        icon = Icons.schedule;
        statusText = 'Pending';
    }

    return Container(
      height: (job.status == JobStatus.processing && job.stepDescription != null) ||
              job.status == JobStatus.failed ? 64 : 50,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: containerColor ?? (isDark
            ? Colors.grey[850]!.withValues(alpha: 0.95)
            : Colors.white.withValues(alpha: 0.95)),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: progressColor.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: progressColor.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onDismiss,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                // Animated icon for processing
                if (job.status == JobStatus.processing)
                  _AnimatedProcessingIcon(
                    icon: icon,
                    color: progressColor,
                    size: 20,
                  )
                else
                  Icon(icon, color: progressColor, size: 20),
                
                const SizedBox(width: 8),
                
                // File name and status - combined in single row
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _getJobTitle(job),
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if ((job.status == JobStatus.processing && job.stepDescription != null) ||
                                job.status == JobStatus.failed)
                              Text(
                                job.status == JobStatus.failed
                                    ? _getErrorMessage(job)
                                    : job.stepDescription!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 12,
                                  color: job.status == JobStatus.failed
                                      ? Colors.red[700]
                                      : theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                                  fontWeight: job.status == JobStatus.failed
                                      ? FontWeight.w500
                                      : FontWeight.normal,
                                  height: 1.2,
                                ),
                                maxLines: job.status == JobStatus.failed ? 2 : 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (!job.isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: progressColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            statusText,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: progressColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                
                // Progress indicator or percentage
                if (job.isActive) ...[
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: job.progress / 100,
                          strokeWidth: 3,
                          backgroundColor: progressColor.withValues(alpha: 0.2),
                          valueColor: AlwaysStoppedAnimation(progressColor),
                        ),
                        Text(
                          '${job.progress.toInt()}%',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                
                // View button for completed summary jobs
                if (job.status == JobStatus.completed &&
                    job.result != null &&
                    (job.result!['summary_id'] != null || job.result!['id'] != null)) ...[
                  const SizedBox(width: 6),
                  TextButton.icon(
                    onPressed: () {
                      final summaryId = job.result!['summary_id'] ?? job.result!['id'];
                      if (summaryId != null) {
                        context.push('/summaries/$summaryId');
                      }
                    },
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('View'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: const Size(0, 0),
                      textStyle: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ]
                // Status icon for other completed states
                else if (job.isComplete) ...[
                  const SizedBox(width: 6),
                  Icon(
                    job.status == JobStatus.completed
                        ? Icons.check_circle
                        : job.status == JobStatus.failed
                            ? Icons.error
                            : Icons.cancel,
                    color: progressColor,
                    size: 22,
                  ),
                  const SizedBox(width: 6),
                ],
                
                // Close/Cancel button
                if (onDismiss != null)
                  GestureDetector(
                    onTap: () async {
                      // Show confirmation dialog for active jobs
                      if (job.isActive) {
                        final shouldCancel = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Cancel Job'),
                            content: Text(
                              'Are you sure you want to cancel this ${job.jobType == JobType.transcription ? 'transcription' : 'upload'}?\n\nThe process will be stopped and any partial progress will be lost.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: const Text('Keep Processing'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                style: FilledButton.styleFrom(
                                  backgroundColor: theme.colorScheme.error.withValues(alpha: 0.9),
                                  foregroundColor: theme.colorScheme.onError,
                                ),
                                child: const Text('Cancel Job'),
                              ),
                            ],
                          ),
                        );

                        if (shouldCancel == true) {
                          try {
                            // Cancel job via WebSocket
                            final tracker = ref.read(webSocketActiveJobsTrackerProvider.notifier);
                            await tracker.cancelJob(jobId!);
                            // Also dismiss from UI
                            onDismiss?.call();
                          } catch (e) {
                            // Show error if cancellation fails
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to cancel job: ${e.toString()}'),
                                  backgroundColor: Colors.red,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          }
                        }
                      } else {
                        // Just dismiss completed/failed jobs
                        onDismiss?.call();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        size: 14,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildErrorIndicator(BuildContext context, Object error) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.error, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Error: $error',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }


  String _getJobTitle(JobModel job) {
    // Check if this is a Fireflies import job
    if (job.metadata['source'] == 'fireflies') {
      return job.metadata['title'] ?? 'Fireflies Meeting Import';
    }
    
    // Check for other special job types
    switch (job.jobType) {
      case JobType.projectSummary:
        return 'Generating Project Summary';
      case JobType.meetingSummary:
        return 'Generating Meeting Summary';
      case JobType.transcription:
        return 'Transcribing Audio';
      case JobType.textUpload:
        return job.filename ?? 'Processing Text';
      case JobType.emailUpload:
        return job.filename ?? 'Processing Email';
      case JobType.batchUpload:
        return 'Batch Upload';
    }
  }
  
  String _getErrorMessage(JobModel job) {
    // Map common error messages to friendly user messages
    final error = job.errorMessage?.toLowerCase() ?? '';

    // Check metadata for partial success scenarios
    final metadata = job.metadata;
    if (metadata['partial_success'] == true) {
      final failedComponents = <String>[];
      if (metadata['summary_failed'] == true) failedComponents.add('AI summary');
      if (metadata['risks_tasks_failed'] == true) failedComponents.add('risk extraction');
      if (metadata['description_update_failed'] == true) failedComponents.add('description update');

      if (failedComponents.isNotEmpty) {
        return 'Upload successful but ${failedComponents.join(", ")} failed. You can regenerate these later.';
      }
    }

    // AI/LLM specific errors (Claude and OpenAI)
    if (error.contains('claude') || error.contains('openai') || error.contains('ai service') ||
        error.contains('overloaded') || error.contains('529') || error.contains('503')) {
      return 'AI service is temporarily busy. Content uploaded successfully - summary will be generated when available.';
    } else if (error.contains('llm') || error.contains('anthropic') || error.contains('gpt')) {
      return 'AI processing unavailable. Content saved - you can generate insights later.';
    } else if (error.contains('salad') || error.contains('api') || error.contains('transcription')) {
      return 'Transcription service temporarily unavailable. Please try again in a moment.';
    } else if (error.contains('network') || error.contains('connection')) {
      return 'Network connection issue. Please check your internet and try again.';
    } else if (error.contains('timeout')) {
      return 'Request timed out. Please try again.';
    } else if (error.contains('file') || error.contains('format')) {
      return 'Invalid audio file format. Please use a supported format.';
    } else if (error.contains('size')) {
      return 'File too large. Maximum size is 100MB.';
    } else if (job.errorMessage != null && job.errorMessage!.isNotEmpty) {
      // If we have a specific error message but it's not one of the common ones,
      // still show something user-friendly
      return 'Processing failed. Please try again later.';
    } else {
      return 'An unexpected error occurred. Please try again.';
    }
  }

}

// Global progress overlay widget that can be shown on any screen
class GlobalUploadProgressOverlay extends ConsumerWidget {
  final Widget child;

  const GlobalUploadProgressOverlay({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch processingJobsProvider for immediate job display
    final processingJobs = ref.watch(processingJobsProvider);

    // Also watch connection state for debugging
    final connectionState = ref.watch(jobWebSocketConnectionStateProvider);

    connectionState.whenData((isConnected) {
      if (!isConnected) {
        debugPrint('[GlobalUploadProgressOverlay] WebSocket disconnected');
      }
    });

    // Debug: Print active jobs count
    if (processingJobs.isNotEmpty) {
      debugPrint('[GlobalUploadProgressOverlay] Active jobs: ${processingJobs.length}');
      for (var job in processingJobs) {
        debugPrint('  - Job ${job.jobId}: ${job.jobModel?.status.value ?? "pending"} (${job.progress.toInt()}%)');
      }
    }

    if (processingJobs.isEmpty) {
      return child;
    }

    return Stack(
      children: [
        child,
        // Show compact indicators at the bottom-middle
        Positioned(
          bottom: 20, // Above bottom edge
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              constraints: const BoxConstraints(
                maxHeight: 220, // Fixed max height instead of percentage
                maxWidth: 480, // Max width for the container
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.95),
              ),
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Job indicators without animation for cleaner look
                    ...processingJobs.take(3).map((job) { // Limit to 3 visible jobs
                      return UploadProgressIndicator(
                        key: ValueKey(job.jobId),
                        jobId: job.jobId,
                        onDismiss: () {
                          // Remove the job from processing tracker
                          ref.read(processingJobsProvider.notifier).removeJob(job.jobId);
                        },
                      );
                    }),
                    if (processingJobs.length > 3)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                        child: Text(
                          '+${processingJobs.length - 3} more',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 13,
                            color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Animated processing icon widget
class _AnimatedProcessingIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  final double size;

  const _AnimatedProcessingIcon({
    required this.icon,
    required this.color,
    required this.size,
  });

  @override
  State<_AnimatedProcessingIcon> createState() => _AnimatedProcessingIconState();
}

class _AnimatedProcessingIconState extends State<_AnimatedProcessingIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _controller.value * 2 * 3.14159,
          child: Icon(
            widget.icon,
            color: widget.color,
            size: widget.size,
          ),
        );
      },
    );
  }
}