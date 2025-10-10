import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/notification_service.dart';
import '../../../jobs/domain/models/job_model.dart';
import '../../../jobs/domain/services/job_websocket_service.dart';
import '../../../jobs/presentation/providers/job_websocket_provider.dart';

class ProjectSummaryWebSocketDialog extends ConsumerStatefulWidget {
  final String projectId;
  final String jobId;
  final DateTime startDate;
  final DateTime endDate;

  const ProjectSummaryWebSocketDialog({
    super.key,
    required this.projectId,
    required this.jobId,
    required this.startDate,
    required this.endDate,
  });

  @override
  ConsumerState<ProjectSummaryWebSocketDialog> createState() =>
      _ProjectSummaryWebSocketDialogState();
}

class _ProjectSummaryWebSocketDialogState
    extends ConsumerState<ProjectSummaryWebSocketDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  StreamSubscription<JobModel>? _jobSubscription;
  JobModel? _currentJob;
  bool _hasNavigated = false;
  JobWebSocketService? _service; // Cache service reference

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    // Subscribe to job updates
    _subscribeToJob();
  }

  void _subscribeToJob() async {
    _service = ref.read(jobWebSocketServiceProvider);
    
    // Subscribe to this specific job
    await _service!.subscribeToJob(widget.jobId);
    
    // Listen for updates
    _jobSubscription = _service!.jobUpdates
        .where((job) => job.jobId == widget.jobId)
        .listen(_handleJobUpdate);
  }

  void _handleJobUpdate(JobModel job) {
    setState(() {
      _currentJob = job;
    });
    
    // Handle completion
    if (job.status == JobStatus.completed && !_hasNavigated) {
      _hasNavigated = true;
      final summaryId = job.result?['summary_id'] as String?;
      
      if (summaryId != null) {
        // Navigate to summary detail
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.of(context).pop();
            context.push('/summaries/$summaryId');
          }
        });
      }
    } else if (job.status == JobStatus.failed) {
      // Handle error
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.of(context).pop();
          ref.read(notificationServiceProvider.notifier).showError(
            'Failed to generate summary: ${job.errorMessage}',
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _jobSubscription?.cancel();
    _animationController.dispose();
    
    // Unsubscribe from job using cached service reference
    try {
      _service?.unsubscribeFromJob(widget.jobId);
    } catch (e) {
      // Ignore errors during disposal
    }
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateFormat = DateFormat('MMM d, yyyy');
    
    final progress = _currentJob?.progress ?? 0.0;
    final stepDescription = _currentJob?.stepDescription ?? 'Initializing...';
    final currentStep = _currentJob?.currentStep ?? 0;
    final totalSteps = _currentJob?.totalSteps ?? 3;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated icon
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.auto_awesome,
                      size: 40,
                      color: colorScheme.primary,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            
            // Title
            Text(
              'Generating Project Summary',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            
            // Date range
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.date_range,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${dateFormat.format(widget.startDate)} - ${dateFormat.format(widget.endDate)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Progress indicator with percentage and spinner
            Column(
              children: [
                LinearProgressIndicator(
                  value: progress / 100,
                  minHeight: 6,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_currentJob?.status == JobStatus.processing)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                    Text(
                      '${progress.toInt()}%',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Current step description
            Text(
              stepDescription,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            
            Text(
              'Step $currentStep of $totalSteps',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),
            
            // Don't close message
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Do not close this window. You will be redirected to the summary shortly.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Status steps
            DefaultTextStyle(
              style: theme.textTheme.labelSmall!.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              child: Column(
                children: [
                  _StatusStep(
                    icon: Icons.check_circle,
                    text: 'Collecting meeting data',
                    isActive: currentStep >= 1,
                    isComplete: currentStep > 1,
                  ),
                  const SizedBox(height: 8),
                  _StatusStep(
                    icon: Icons.analytics_outlined,
                    text: 'Analyzing discussions',
                    isActive: currentStep >= 2,
                    isComplete: currentStep > 2,
                  ),
                  const SizedBox(height: 8),
                  _StatusStep(
                    icon: Icons.summarize_outlined,
                    text: 'Generating summary',
                    isActive: currentStep >= 3,
                    isComplete: _currentJob?.status == JobStatus.completed,
                  ),
                ],
              ),
            ),
            
            // Cancel button (optional)
            if (_currentJob?.status == JobStatus.processing) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  _service?.cancelJob(widget.jobId);
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusStep extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isActive;
  final bool isComplete;

  const _StatusStep({
    required this.icon,
    required this.text,
    required this.isActive,
    required this.isComplete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = isComplete 
        ? Colors.green 
        : isActive 
            ? colorScheme.primary 
            : colorScheme.onSurfaceVariant.withValues(alpha: 0.5);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isComplete ? Icons.check_circle : icon,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}