import 'package:flutter/material.dart';
import '../../domain/services/audio_recording_service.dart';
import '../providers/recording_provider.dart';

/// Compact recording header widget for AI Assistant mode
///
/// Displays recording timer, amplitude meter, and control buttons
/// in a horizontal compact layout (60px height).
class CompactRecordingHeader extends StatelessWidget {
  final RecordingStateModel recordingState;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onStop;
  final bool aiAssistantEnabled;

  const CompactRecordingHeader({
    super.key,
    required this.recordingState,
    required this.onPause,
    required this.onResume,
    required this.onStop,
    required this.aiAssistantEnabled,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Recording indicator with timer
          _buildRecordingIndicator(theme, colorScheme),

          const SizedBox(width: 16),

          // Amplitude meter
          Expanded(
            flex: 2,
            child: _buildAmplitudeMeter(colorScheme),
          ),

          const SizedBox(width: 16),

          // Control buttons
          _buildControlButtons(colorScheme),
        ],
      ),
    );
  }

  Widget _buildRecordingIndicator(ThemeData theme, ColorScheme colorScheme) {
    final isRecording = recordingState.state == RecordingState.recording;
    final isPaused = recordingState.state == RecordingState.paused;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Animated recording dot
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isPaused
                ? colorScheme.onSurfaceVariant.withValues(alpha: 0.5)
                : Colors.red,
          ),
          child: isPaused
              ? null
              : AnimatedOpacity(
                  opacity: isRecording ? 1.0 : 0.3,
                  duration: const Duration(milliseconds: 500),
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red,
                    ),
                  ),
                ),
        ),

        const SizedBox(width: 8),

        // Timer
        Text(
          _formatDuration(recordingState.duration),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            fontFeatures: [const FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }

  Widget _buildAmplitudeMeter(ColorScheme colorScheme) {
    // Normalize amplitude (0.0 - 1.0)
    final normalizedAmplitude = (recordingState.amplitude / 160.0).clamp(0.0, 1.0);
    final percentage = (normalizedAmplitude * 100).toInt();

    return Row(
      children: [
        // Amplitude bars
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: normalizedAmplitude,
              backgroundColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation<Color>(
                _getAmplitudeColor(normalizedAmplitude, colorScheme),
              ),
              minHeight: 8,
            ),
          ),
        ),

        const SizedBox(width: 8),

        // Percentage
        SizedBox(
          width: 40,
          child: Text(
            '$percentage%',
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
              fontFeatures: [const FontFeature.tabularFigures()],
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildControlButtons(ColorScheme colorScheme) {
    final isRecording = recordingState.state == RecordingState.recording;
    final isPaused = recordingState.state == RecordingState.paused;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Pause/Resume button
        if (isRecording || isPaused) ...[
          IconButton.filled(
            onPressed: isPaused ? onResume : onPause,
            icon: Icon(
              isPaused ? Icons.play_arrow : Icons.pause,
              size: 20,
            ),
            tooltip: isPaused ? 'Resume' : 'Pause',
            style: IconButton.styleFrom(
              backgroundColor: colorScheme.secondaryContainer,
              foregroundColor: colorScheme.onSecondaryContainer,
              minimumSize: const Size(36, 36),
              padding: EdgeInsets.zero,
            ),
          ),

          const SizedBox(width: 8),
        ],

        // Stop button
        if (isRecording || isPaused)
          IconButton.filled(
            onPressed: onStop,
            icon: const Icon(
              Icons.stop,
              size: 20,
            ),
            tooltip: 'Stop',
            style: IconButton.styleFrom(
              backgroundColor: Colors.red.withValues(alpha: 0.15),
              foregroundColor: Colors.red,
              minimumSize: const Size(36, 36),
              padding: EdgeInsets.zero,
            ),
          ),
      ],
    );
  }

  Color _getAmplitudeColor(double amplitude, ColorScheme colorScheme) {
    if (amplitude < 0.3) {
      return colorScheme.primary.withValues(alpha: 0.5);
    } else if (amplitude < 0.7) {
      return colorScheme.primary;
    } else {
      return Colors.orange;
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
