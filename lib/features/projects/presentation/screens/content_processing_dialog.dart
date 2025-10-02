import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../jobs/domain/models/job_model.dart';
import '../../../jobs/domain/services/job_websocket_service.dart';
import '../../../jobs/presentation/providers/job_websocket_provider.dart';
import '../../domain/entities/project.dart';

class ContentProcessingDialog extends ConsumerStatefulWidget {
  final Project project;
  final String jobId;
  final String? contentId;

  const ContentProcessingDialog({
    super.key,
    required this.project,
    required this.jobId,
    this.contentId,
  });

  @override
  ConsumerState<ContentProcessingDialog> createState() => _ContentProcessingDialogState();
}

class _ContentProcessingDialogState extends ConsumerState<ContentProcessingDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  StreamSubscription<JobModel>? _jobSubscription;
  JobModel? _currentJob;
  bool _hasCompleted = false;
  JobWebSocketService? _service;

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
    if (job.status == JobStatus.completed && !_hasCompleted) {
      _hasCompleted = true;

      // Auto close after showing completion
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          Navigator.of(context).pop();

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 20),
                  SizedBox(width: 12),
                  Text('Content processed successfully'),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      });
    } else if (job.status == JobStatus.failed) {
      // Handle error
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Processing failed: ${job.errorMessage}'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _jobSubscription?.cancel();
    _animationController.dispose();

    // Unsubscribe from job
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

    final progress = _currentJob?.progress ?? 0.0;
    final stepDescription = _currentJob?.stepDescription ?? 'Initializing...';
    final currentStep = _currentJob?.currentStep ?? 0;
    final totalSteps = _currentJob?.totalSteps ?? 5;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      backgroundColor: colorScheme.surface,
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
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.blue.withValues(alpha: 0.2),
                          Colors.purple.withValues(alpha: 0.2),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _currentJob?.status == JobStatus.completed
                        ? Icons.check_circle
                        : Icons.upload_file,
                      size: 32,
                      color: _currentJob?.status == JobStatus.completed
                        ? Colors.green
                        : Colors.blue,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              'Processing Content',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Project name
            Text(
              widget.project.name,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),

            // Progress bar
            Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress / 100,
                    minHeight: 8,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_currentJob?.status == JobStatus.processing)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: SizedBox(
                          width: 14,
                          height: 14,
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
                      style: theme.textTheme.labelLarge?.copyWith(
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
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                stepDescription,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),

            Text(
              'Step $currentStep of $totalSteps',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 20),

            // Processing steps
            Column(
              children: [
                _ProcessingStep(
                  icon: Icons.description,
                  text: 'Parsing content',
                  isActive: currentStep >= 1,
                  isComplete: currentStep > 1,
                ),
                const SizedBox(height: 8),
                _ProcessingStep(
                  icon: Icons.cut,
                  text: 'Creating chunks',
                  isActive: currentStep >= 2,
                  isComplete: currentStep > 2,
                ),
                const SizedBox(height: 8),
                _ProcessingStep(
                  icon: Icons.memory,
                  text: 'Generating embeddings',
                  isActive: currentStep >= 3,
                  isComplete: currentStep > 3,
                ),
                const SizedBox(height: 8),
                _ProcessingStep(
                  icon: Icons.storage,
                  text: 'Storing vectors',
                  isActive: currentStep >= 4,
                  isComplete: currentStep > 4,
                ),
                const SizedBox(height: 8),
                _ProcessingStep(
                  icon: Icons.auto_awesome,
                  text: 'Generating summary',
                  isActive: currentStep >= 5,
                  isComplete: _currentJob?.status == JobStatus.completed,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProcessingStep extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isActive;
  final bool isComplete;

  const _ProcessingStep({
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
            : colorScheme.onSurfaceVariant.withValues(alpha: 0.4);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isComplete ? Icons.check_circle : icon,
          size: 18,
          color: color,
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}