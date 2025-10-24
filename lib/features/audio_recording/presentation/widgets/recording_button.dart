import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/recording_provider.dart';
import '../../domain/services/audio_recording_service.dart';
import '../../../../core/services/notification_service.dart';

class RecordingButton extends ConsumerWidget {
  final String projectId;
  final String? meetingTitle;
  final Function(String? contentId)? onRecordingComplete;  // Updated to pass contentId
  final String? language;
  final bool enableLiveInsights;
  final String? authToken;

  const RecordingButton({
    super.key,
    required this.projectId,
    this.meetingTitle,
    this.onRecordingComplete,
    this.language,
    this.enableLiveInsights = false,
    this.authToken,
  });
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordingState = ref.watch(recordingNotifierProvider);
    final recordingNotifier = ref.read(recordingNotifierProvider.notifier);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Determine button appearance based on state
    final isRecording = recordingState.state == RecordingState.recording;
    final isPaused = recordingState.state == RecordingState.paused;
    final isProcessing = recordingState.state == RecordingState.processing;
    final hasError = recordingState.state == RecordingState.error;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Main recording button
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: isRecording ? [
              BoxShadow(
                color: Colors.red.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ] : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(40),
              onTap: isProcessing ? null : () => _handleButtonPress(
                context,
                ref,
                recordingState,
                recordingNotifier,
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _getButtonColor(recordingState.state, colorScheme),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _getButtonIcon(recordingState.state),
                ),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Status text and duration
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Column(
            key: ValueKey(recordingState.state),
            children: [
              Text(
                _getStatusText(recordingState.state),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: _getStatusColor(recordingState.state, colorScheme),
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (isRecording || isPaused) ...[
                const SizedBox(height: 4),
                Text(
                  _formatDuration(recordingState.duration),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),

        // 90-minute warning notification
        if ((isRecording || isPaused) && recordingState.showDurationWarning) ...[
          const SizedBox(height: 12),
          _DurationWarningBanner(colorScheme: colorScheme),
        ],
        
        // Audio level indicator when recording
        if (isRecording) ...[
          const SizedBox(height: 16),
          StreamBuilder<double>(
            stream: ref.read(audioRecordingServiceProvider).amplitudeStream,
            builder: (context, snapshot) {
              final amplitude = snapshot.data ?? -160.0;
              return _AudioLevelIndicator(amplitude: amplitude);
            },
          ),
        ],
        
        // Control buttons when recording
        if (isRecording || isPaused) ...[
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Pause/Resume button
              IconButton(
                onPressed: () {
                  if (isRecording) {
                    recordingNotifier.pauseRecording();
                  } else if (isPaused) {
                    recordingNotifier.resumeRecording();
                  }
                },
                icon: Icon(
                  isRecording ? Icons.pause : Icons.play_arrow,
                  size: 20,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  foregroundColor: colorScheme.onSurfaceVariant,
                ),
                tooltip: isRecording ? 'Pause' : 'Resume',
              ),
              const SizedBox(width: 12),
              
              // Stop button
              IconButton(
                onPressed: () async {
                  final confirm = await _showStopConfirmationDialog(context);
                  if (confirm == true && context.mounted) {
                    await _stopRecording(context, ref, recordingNotifier);
                  }
                },
                icon: const Icon(Icons.stop, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  foregroundColor: colorScheme.onSurfaceVariant,
                ),
                tooltip: 'Stop Recording',
              ),
              const SizedBox(width: 12),
              
              // Cancel button
              IconButton(
                onPressed: () => _cancelRecording(context, ref, recordingNotifier),
                icon: const Icon(Icons.close, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  foregroundColor: colorScheme.error,
                ),
                tooltip: 'Cancel',
              ),
            ],
          ),
        ],
        
        // Error message
        if (hasError && recordingState.errorMessage != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 16,
                  color: colorScheme.onErrorContainer,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    recordingState.errorMessage!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        
        // Processing indicator
        if (isProcessing) ...[
          const SizedBox(height: 8),
          Text(
            'Transcribing audio...',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.primary,
            ),
          ),
        ],
      ],
    );
  }
  
  Future<void> _handleButtonPress(
    BuildContext context,
    WidgetRef ref,
    RecordingStateModel state,
    RecordingNotifier notifier,
  ) async {
    if (state.state == RecordingState.idle) {
      notifier.startRecording(
        projectId: projectId,
        meetingTitle: meetingTitle,
        enableLiveInsights: enableLiveInsights,
        authToken: authToken,
      );
    } else if (state.state == RecordingState.recording ||
               state.state == RecordingState.paused) {
      // Show confirmation dialog before stopping
      final confirm = await _showStopConfirmationDialog(context);
      if (confirm == true && context.mounted) {
        await _stopRecording(context, ref, notifier);
      }
    } else if (state.state == RecordingState.error) {
      notifier.clearError();
    }
  }
  
  Future<void> _stopRecording(
    BuildContext context,
    WidgetRef ref,
    RecordingNotifier notifier,
  ) async {
    // Stop recording and upload using same flow as file upload
    final result = await notifier.stopRecording(
      projectId: projectId,
      meetingTitle: meetingTitle,
    );

    if (result != null && context.mounted) {
      // Check if upload was successful
      final state = ref.read(recordingNotifierProvider);
      final jobId = result['jobId'] as String?;

      if (jobId != null) {
        // Recording uploaded successfully and being processed
        // Close the dialog immediately - just like file upload does
        if (context.mounted) {
          Navigator.of(context).pop();
        }

        // The progress overlay will automatically show via WebSocket tracking
        // No need to show any snackbar - the overlay handles it
      } else if (state.errorMessage != null) {
        if (context.mounted) {
          ref.read(notificationServiceProvider.notifier).showError('Recording failed: ${state.errorMessage}');
        }
      } else {
        if (context.mounted) {
          ref.read(notificationServiceProvider.notifier).showInfo('Recording saved, processing...');
        }
      }
    }
  }
  
  Future<void> _cancelRecording(
    BuildContext context,
    WidgetRef ref,
    RecordingNotifier notifier,
  ) async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Recording?'),
        content: const Text(
          'Are you sure you want to cancel this recording? All recorded audio will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep Recording'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await notifier.cancelRecording();
      if (context.mounted) {
        ref.read(notificationServiceProvider.notifier).showInfo('Recording cancelled');
      }
    }
  }

  Future<bool?> _showStopConfirmationDialog(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.stop_circle_outlined,
                color: colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Stop Recording?'),
            ),
          ],
        ),
        content: Text(
          'Your recording will be saved and automatically transcribed.',
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Continue'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => Navigator.pop(context, true),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Stop & Save'),
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Color _getButtonColor(RecordingState state, ColorScheme colorScheme) {
    switch (state) {
      case RecordingState.idle:
        return colorScheme.primary;
      case RecordingState.recording:
        return Colors.red;
      case RecordingState.paused:
        return Colors.orange;
      case RecordingState.processing:
        return colorScheme.surfaceContainerHighest;
      case RecordingState.error:
        return colorScheme.error;
    }
  }
  
  Widget _getButtonIcon(RecordingState state) {
    switch (state) {
      case RecordingState.idle:
        return const Icon(
          Icons.mic,
          key: ValueKey('mic'),
          color: Colors.white,
          size: 32,
        );
      case RecordingState.recording:
        return const Icon(
          Icons.fiber_manual_record,
          key: ValueKey('recording'),
          color: Colors.white,
          size: 32,
        );
      case RecordingState.paused:
        return const Icon(
          Icons.pause,
          key: ValueKey('paused'),
          color: Colors.white,
          size: 32,
        );
      case RecordingState.processing:
        return const SizedBox(
          key: ValueKey('processing'),
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 3,
          ),
        );
      case RecordingState.error:
        return const Icon(
          Icons.error_outline,
          key: ValueKey('error'),
          color: Colors.white,
          size: 32,
        );
    }
  }
  
  String _getStatusText(RecordingState state) {
    switch (state) {
      case RecordingState.idle:
        return 'Start Recording';
      case RecordingState.recording:
        return 'Recording...';
      case RecordingState.paused:
        return 'Paused';
      case RecordingState.processing:
        return 'Transcribing...';
      case RecordingState.error:
        return 'Error';
    }
  }
  
  Color _getStatusColor(RecordingState state, ColorScheme colorScheme) {
    switch (state) {
      case RecordingState.idle:
        return colorScheme.onSurfaceVariant;
      case RecordingState.recording:
        return Colors.red;
      case RecordingState.paused:
        return Colors.orange;
      case RecordingState.processing:
        return colorScheme.primary;
      case RecordingState.error:
        return colorScheme.error;
    }
  }
  
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');

    // Show hours if duration is >= 1 hour
    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }
}

// Audio level indicator widget
class _AudioLevelIndicator extends StatefulWidget {
  final double amplitude;
  
  const _AudioLevelIndicator({required this.amplitude});

  @override
  State<_AudioLevelIndicator> createState() => _AudioLevelIndicatorState();
}

class _AudioLevelIndicatorState extends State<_AudioLevelIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  static const int barCount = 20;
  final List<double> _barHeights = List.filled(barCount, 0.1);
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
  }
  
  @override
  void didUpdateWidget(_AudioLevelIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.amplitude != oldWidget.amplitude) {
      _updateBars();
    }
  }
  
  void _updateBars() {
    // Normalize amplitude from record package (dB values: -160 to 0)
    // Web microphone typically gives -60 dB (silence) to -30 dB (loud speech)
    // Map -60 dB (silence) to 0.0, and -30 dB (very loud) to 1.0
    double normalizedLevel = (widget.amplitude + 60) / 30;
    normalizedLevel = normalizedLevel.clamp(0.0, 1.0);
    
    // Update bar heights with some randomness for visual effect
    setState(() {
      for (int i = 0; i < barCount; i++) {
        // Create a wave effect where center bars are higher
        final centerDistance = (i - barCount / 2).abs() / (barCount / 2);
        final centerFactor = 1.0 - (centerDistance * 0.3);
        
        // Add some randomness for natural look
        final randomFactor = 0.8 + (0.4 * (i.isEven ? 1.0 : 0.7));
        
        // Calculate final height
        _barHeights[i] = (normalizedLevel * centerFactor * randomFactor).clamp(0.1, 1.0);
      }
    });
    
    _animationController.forward(from: 0);
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(barCount, (index) {
          return Expanded(
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 50),
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(
                    color: _getBarColor(_barHeights[index], colorScheme),
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: _barHeights[index] > 0.5 ? [
                      BoxShadow(
                        color: _getBarColor(_barHeights[index], colorScheme).withValues(alpha: 0.3),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ] : null,
                  ),
                  height: 40 * _barHeights[index] * _animation.value,
                );
              },
            ),
          );
        }),
      ),
    );
  }
  
  Color _getBarColor(double level, ColorScheme colorScheme) {
    // Color based on audio level intensity
    if (level < 0.3) {
      // Low level - green
      return Colors.green.withValues(alpha: 0.8);
    } else if (level < 0.5) {
      // Medium-low - yellow-green
      return Color.lerp(Colors.green, Colors.yellow, (level - 0.3) * 5)!;
    } else if (level < 0.7) {
      // Medium - yellow to orange
      return Color.lerp(Colors.yellow, Colors.orange, (level - 0.5) * 5)!;
    } else if (level < 0.9) {
      // High - orange to red
      return Color.lerp(Colors.orange, Colors.red, (level - 0.7) * 5)!;
    } else {
      // Very high - red
      return Colors.red;
    }
  }
}

// Duration warning banner widget - compact and elegant
class _DurationWarningBanner extends StatelessWidget {
  final ColorScheme colorScheme;

  const _DurationWarningBanner({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.3),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.access_time_rounded,
            size: 14,
            color: Colors.orange.shade700,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              '90 min · Auto-stop at 2 hours',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.orange.shade800,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}