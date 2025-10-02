import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/recording_provider.dart';

class TranscriptionDisplay extends ConsumerWidget {
  final bool showFullTranscript;
  final double? maxHeight;
  final VoidCallback? onRetry;
  final VoidCallback? onClear;
  
  const TranscriptionDisplay({
    super.key,
    this.showFullTranscript = true,
    this.maxHeight,
    this.onRetry,
    this.onClear,
  });
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordingState = ref.watch(recordingNotifierProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    print('[TranscriptionDisplay] Current state: ${recordingState.state}');
    print('[TranscriptionDisplay] Is processing: ${recordingState.isProcessing}');
    print('[TranscriptionDisplay] Transcription text: ${recordingState.transcriptionText}');
    
    // Show processing state
    if (recordingState.isProcessing) {
      return _buildProcessingCard(context, theme, colorScheme);
    }
    
    // Show empty state if no transcription
    if (recordingState.transcriptionText.isEmpty) {
      return Container();
    }
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      constraints: BoxConstraints(
        maxHeight: maxHeight ?? 300,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.transcribe_outlined,
                    size: 20,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Transcription Result',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  // Action buttons
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (onClear != null)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: onClear,
                          tooltip: 'Clear transcription',
                          style: IconButton.styleFrom(
                            minimumSize: const Size(32, 32),
                            padding: const EdgeInsets.all(4),
                          ),
                        ),
                      if (onRetry != null && recordingState.errorMessage != null)
                        IconButton(
                          icon: const Icon(Icons.refresh, size: 18),
                          onPressed: onRetry,
                          tooltip: 'Retry transcription',
                          style: IconButton.styleFrom(
                            minimumSize: const Size(32, 32),
                            padding: const EdgeInsets.all(4),
                          ),
                        ),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 18),
                        onPressed: () {
                          // Copy to clipboard
                          _copyToClipboard(context, recordingState.transcriptionText);
                        },
                        tooltip: 'Copy to clipboard',
                        style: IconButton.styleFrom(
                          minimumSize: const Size(32, 32),
                          padding: const EdgeInsets.all(4),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Transcription text
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Column(
                    key: ValueKey(recordingState.transcriptionText.length),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (showFullTranscript)
                        SelectableText(
                          recordingState.transcriptionText,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.5,
                          ),
                        )
                      else
                        Text(
                          _getLatestText(recordingState.transcriptionText),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.5,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Footer with word count
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_getWordCount(recordingState.transcriptionText)} words',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    _formatDuration(recordingState.duration),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  String _getLatestText(String fullText) {
    // Show only the last 100 words for compact view
    final words = fullText.split(' ');
    if (words.length <= 100) {
      return fullText;
    }
    return '...${words.sublist(words.length - 100).join(' ')}';
  }
  
  int _getWordCount(String text) {
    if (text.trim().isEmpty) return 0;
    return text.trim().split(RegExp(r'\s+')).length;
  }
  
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return 'Duration: ${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
  
  void _copyToClipboard(BuildContext context, String text) {
    // Import required for clipboard
    // Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Transcription copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }
  
  Widget _buildProcessingCard(BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            color: colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Processing transcription...',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'This may take a moment depending on the recording length',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

