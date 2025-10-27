import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/datetime_utils.dart';
import '../../data/models/transcript_model.dart';

/// Live Transcription Display Widget
///
/// Displays real-time transcription from AssemblyAI with:
/// - Speaker attribution (color-coded)
/// - Partial vs Final state indicators
/// - Auto-scroll to latest transcript
/// - Clickable timestamps
/// - Collapsible panel
class LiveTranscriptionWidget extends ConsumerStatefulWidget {
  final List<TranscriptModel> transcripts;
  final bool isCollapsed;
  final VoidCallback? onToggleCollapse;

  const LiveTranscriptionWidget({
    super.key,
    required this.transcripts,
    this.isCollapsed = false,
    this.onToggleCollapse,
  });

  @override
  ConsumerState<LiveTranscriptionWidget> createState() =>
      _LiveTranscriptionWidgetState();
}

class _LiveTranscriptionWidgetState
    extends ConsumerState<LiveTranscriptionWidget> {
  final ScrollController _scrollController = ScrollController();
  bool _autoScroll = true;
  bool _showNewTranscriptButton = false;

  // Speaker colors for visual tracking
  final Map<String, Color> _speakerColors = {};
  final List<Color> _availableColors = [
    const Color(0xFF6366F1), // Indigo
    const Color(0xFF8B5CF6), // Purple
    const Color(0xFFEC4899), // Pink
    const Color(0xFF10B981), // Green
    const Color(0xFFF59E0B), // Amber
    const Color(0xFF3B82F6), // Blue
    const Color(0xFFEF4444), // Red
    const Color(0xFF14B8A6), // Teal
  ];
  int _colorIndex = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(LiveTranscriptionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Auto-scroll to bottom when new transcripts arrive
    if (_autoScroll &&
        widget.transcripts.length > oldWidget.transcripts.length) {
      _scrollToBottom();
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final isAtBottom = _scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 50;

    // If user scrolls up, pause auto-scroll
    if (!isAtBottom && _autoScroll) {
      setState(() {
        _autoScroll = false;
        _showNewTranscriptButton = true;
      });
    }

    // If user scrolls back to bottom, resume auto-scroll
    if (isAtBottom && !_autoScroll) {
      setState(() {
        _autoScroll = true;
        _showNewTranscriptButton = false;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleResumeAutoScroll() {
    setState(() {
      _autoScroll = true;
      _showNewTranscriptButton = false;
    });
    _scrollToBottom();
  }

  Color _getSpeakerColor(String? speaker) {
    if (speaker == null) return Colors.grey;

    if (!_speakerColors.containsKey(speaker)) {
      _speakerColors[speaker] = _availableColors[_colorIndex % _availableColors.length];
      _colorIndex++;
    }

    return _speakerColors[speaker]!;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Show collapsed state (only last 2 transcripts)
    if (widget.isCollapsed) {
      return _buildCollapsedView(theme, colorScheme);
    }

    // Show expanded state (full scrollable history)
    return _buildExpandedView(theme, colorScheme);
  }

  Widget _buildCollapsedView(ThemeData theme, ColorScheme colorScheme) {
    final lastTwo = widget.transcripts.length > 2
        ? widget.transcripts.sublist(widget.transcripts.length - 2)
        : widget.transcripts;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header removed - parent widget now handles it
          ...lastTwo.map((transcript) => _buildTranscriptItem(
                transcript,
                theme,
                colorScheme,
                isCompact: true,
              )),
        ],
      ),
    );
  }

  Widget _buildExpandedView(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header removed - parent widget now handles it
        Expanded(
          child: Stack(
            children: [
              // Transcript list
              widget.transcripts.isEmpty
                  ? _buildEmptyState(theme, colorScheme)
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.only(bottom: 8),
                      itemCount: widget.transcripts.length,
                      itemBuilder: (context, index) {
                        return _buildTranscriptItem(
                          widget.transcripts[index],
                          theme,
                          colorScheme,
                        );
                      },
                    ),

              // "New transcript" floating button
              if (_showNewTranscriptButton)
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: FloatingActionButton.small(
                    onPressed: _handleResumeAutoScroll,
                    backgroundColor: colorScheme.primaryContainer,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'New transcript',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_downward,
                          size: 16,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.mic_none,
            size: 32,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 8),
          Text(
            'Waiting for audio...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Transcription will appear here in real-time',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTranscriptItem(
    TranscriptModel transcript,
    ThemeData theme,
    ColorScheme colorScheme, {
    bool isCompact = false,
  }) {
    final speakerColor = _getSpeakerColor(transcript.speaker);
    final isOlderThan5Min = DateTime.now().difference(transcript.timestamp).inMinutes > 5;

    return Padding(
      padding: EdgeInsets.only(bottom: isCompact ? 4 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timestamp
          SizedBox(
            width: 50,
            child: Text(
              isOlderThan5Min
                  ? DateTimeUtils.formatTime(transcript.timestamp)
                  : DateTimeUtils.formatTimeAgo(transcript.timestamp),
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Speaker indicator and label
          if (transcript.speaker != null) ...[
            Container(
              width: 3,
              height: 20,
              decoration: BoxDecoration(
                color: speakerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 80,
              child: Text(
                transcript.displaySpeaker,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: speakerColor,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
          ],

          // Transcript text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transcript.text,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: transcript.isPartial
                        ? colorScheme.onSurfaceVariant.withValues(alpha: 0.7)
                        : colorScheme.onSurface,
                    fontStyle: transcript.isPartial
                        ? FontStyle.italic
                        : FontStyle.normal,
                    height: 1.5,
                  ),
                ),
                if (!isCompact) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      // State indicator
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: transcript.isFinal
                              ? colorScheme.primaryContainer.withValues(alpha: 0.3)
                              : colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              transcript.isFinal ? Icons.check : Icons.more_horiz,
                              size: 10,
                              color: transcript.isFinal
                                  ? colorScheme.primary
                                  : colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              transcript.isFinal ? 'FINAL' : 'PARTIAL',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontSize: 9,
                                color: transcript.isFinal
                                    ? colorScheme.primary
                                    : colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Confidence indicator (if available)
                      if (transcript.confidence != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          transcript.confidenceDisplay,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 9,
                            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
