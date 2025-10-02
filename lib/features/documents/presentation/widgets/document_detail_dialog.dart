import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/datetime_utils.dart';
import '../../../meetings/domain/entities/content.dart';
import '../providers/document_detail_provider.dart';

class DocumentDetailDialog extends ConsumerStatefulWidget {
  final Content document;

  const DocumentDetailDialog({
    super.key,
    required this.document,
  });

  static void show(BuildContext context, Content document) {
    showDialog(
      context: context,
      builder: (context) => DocumentDetailDialog(document: document),
      barrierDismissible: true,
    );
  }

  @override
  ConsumerState<DocumentDetailDialog> createState() => _DocumentDetailDialogState();
}

class _DocumentDetailDialogState extends ConsumerState<DocumentDetailDialog> {
  bool _showFullTranscript = false;
  bool _showFullSummary = false;
  static const int _previewLines = 15;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenSize = MediaQuery.of(context).size;
    final dialogWidth = screenSize.width > 800 ? 700.0 : screenSize.width * 0.9;
    final isMobile = screenSize.width < 600;

    final contentAsync = ref.watch(documentDetailProvider(
      projectId: widget.document.projectId,
      contentId: widget.document.id,
    ));

    final summaryAsync = ref.watch(documentSummaryProvider(
      projectId: widget.document.projectId,
      contentId: widget.document.id,
    ));

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: dialogWidth,
        constraints: BoxConstraints(
          maxHeight: screenSize.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context),
            Flexible(
              child: contentAsync.when(
                data: (content) => SingleChildScrollView(
                  padding: EdgeInsets.all(isMobile ? 16 : 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMetadataRow(context, isMobile),
                      if (widget.document.summaryGenerated) ...[
                        SizedBox(height: isMobile ? 16 : 24),
                        _buildSummarySection(context, summaryAsync, isMobile),
                      ],
                      if (content != null && content['content'] != null) ...[
                        SizedBox(height: isMobile ? 16 : 24),
                        _buildTranscriptionSection(context, content['content'], isMobile),
                      ],
                    ],
                  ),
                ),
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(48),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, _) => _buildErrorContent(context, error),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Color typeColor;
    IconData typeIcon;
    switch (widget.document.contentType) {
      case ContentType.meeting:
        typeColor = Colors.blue.shade600;
        typeIcon = Icons.videocam;
        break;
      case ContentType.email:
        typeColor = Colors.orange.shade600;
        typeIcon = Icons.email;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            colorScheme.surface,
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              typeIcon,
              color: typeColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.document.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.document.typeLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.close,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataRow(BuildContext context, bool isMobile) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final date = widget.document.date ?? widget.document.uploadedAt;

    if (isMobile) {
      // Stack chips vertically on mobile for better readability
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _buildMetadataChip(
            context,
            Icons.calendar_today_outlined,
            DateTimeUtils.formatDateTime(date),
            Colors.blue,
            isMobile,
          ),
          if (widget.document.isProcessed)
            _buildMetadataChip(
              context,
              Icons.check_circle_outline,
              'Processed',
              Colors.green,
              isMobile,
            )
          else if (widget.document.isProcessing)
            _buildMetadataChip(
              context,
              Icons.schedule,
              'Processing',
              Colors.orange,
              isMobile,
            )
          else if (widget.document.hasError)
            _buildMetadataChip(
              context,
              Icons.error_outline,
              'Error',
              colorScheme.error,
              isMobile,
            ),
          if (widget.document.chunkCount > 0)
            _buildMetadataChip(
              context,
              Icons.segment,
              '${widget.document.chunkCount}',
              Colors.purple,
              isMobile,
            ),
        ],
      );
    }

    return Row(
      children: [
        _buildMetadataChip(
          context,
          Icons.calendar_today_outlined,
          DateTimeUtils.formatDateTime(date),
          Colors.blue,
          isMobile,
        ),
        const SizedBox(width: 12),
        if (widget.document.isProcessed)
          _buildMetadataChip(
            context,
            Icons.check_circle_outline,
            'Processed',
            Colors.green,
            isMobile,
          )
        else if (widget.document.isProcessing)
          _buildMetadataChip(
            context,
            Icons.schedule,
            'Processing',
            Colors.orange,
            isMobile,
          )
        else if (widget.document.hasError)
          _buildMetadataChip(
            context,
            Icons.error_outline,
            'Error',
            colorScheme.error,
            isMobile,
          ),
        const SizedBox(width: 12),
        if (widget.document.chunkCount > 0)
          _buildMetadataChip(
            context,
            Icons.segment,
            '${widget.document.chunkCount} chunks',
            Colors.purple,
            isMobile,
          ),
      ],
    );
  }

  Widget _buildMetadataChip(BuildContext context, IconData icon, String label, Color color, bool isMobile) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 10 : 12,
        vertical: isMobile ? 5 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: isMobile ? 14 : 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: isMobile ? 11 : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTranscriptionSection(BuildContext context, String content, bool isMobile) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Calculate character limit for preview - shorter on mobile
    final int previewCharLimit = isMobile ? 400 : 1200;

    // Determine if content should be truncated
    final bool hasMoreContent = content.length > previewCharLimit;

    // Get the display content
    String displayContent;
    if (_showFullTranscript || !hasMoreContent) {
      displayContent = content;
    } else {
      // Find a good break point near the character limit
      String truncated = content.substring(0, previewCharLimit);

      // Try to break at a natural point (newline, period, or space)
      int breakPoint = previewCharLimit;

      // Look for newline first
      int lastNewline = truncated.lastIndexOf('\n');
      if (lastNewline > previewCharLimit * 0.8) {
        breakPoint = lastNewline;
      } else {
        // Look for sentence end
        int lastPeriod = truncated.lastIndexOf('. ');
        if (lastPeriod > previewCharLimit * 0.8) {
          breakPoint = lastPeriod + 1;
        } else {
          // Fall back to last space
          int lastSpace = truncated.lastIndexOf(' ');
          if (lastSpace > previewCharLimit * 0.8) {
            breakPoint = lastSpace;
          }
        }
      }

      displayContent = content.substring(0, breakPoint);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.article_outlined,
              size: isMobile ? 18 : 20,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Transcription',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: isMobile ? 15 : null,
              ),
            ),
          ],
        ),
        SizedBox(height: isMobile ? 8 : 12),
        Container(
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.08),
            ),
          ),
          constraints: BoxConstraints(
            maxHeight: _showFullTranscript
                ? double.infinity
                : (isMobile ? 250 : 400),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                fit: FlexFit.loose,
                child: SingleChildScrollView(
                  child: SelectableText(
                    displayContent,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.6,
                      color: colorScheme.onSurface,
                      fontFamily: 'monospace',
                      fontSize: isMobile ? 13 : null,
                    ),
                  ),
                ),
              ),
              if (hasMoreContent) ...[
                if (!_showFullTranscript) ...[
                  const SizedBox(height: 8),
                  Text(
                    '...',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Center(
                  child: TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _showFullTranscript = !_showFullTranscript;
                      });
                    },
                    icon: Icon(
                      _showFullTranscript
                          ? Icons.expand_less
                          : Icons.expand_more,
                      size: 20,
                    ),
                    label: Text(
                      _showFullTranscript ? 'Show Less' : 'View More',
                      style: theme.textTheme.labelLarge,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummarySection(BuildContext context, AsyncValue<Map<String, dynamic>?> summaryAsync, bool isMobile) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.summarize,
              size: isMobile ? 18 : 20,
              color: Colors.purple,
            ),
            const SizedBox(width: 8),
            Text(
              'Summary',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: isMobile ? 15 : null,
              ),
            ),
          ],
        ),
        SizedBox(height: isMobile ? 8 : 12),
        summaryAsync.when(
          data: (summary) {
            if (summary == null) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.purple.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  'Summary available. Click to view details.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              );
            }

            // Try different possible field names for summary content
            final summaryContent = summary['body'] ??
                                  summary['summary_content'] ??
                                  summary['content'] ??
                                  '';

            // Also get key points if available
            final keyPoints = summary['key_points'] as List?;
            final decisions = summary['decisions'] as List?;
            final actionItems = summary['action_items'] as List?;

            // For mobile, truncate summary text
            String displaySummary = summaryContent.toString();
            bool isSummaryTruncated = false;
            if (isMobile && !_showFullSummary && displaySummary.length > 300) {
              isSummaryTruncated = true;
              // Find a good break point
              int breakPoint = 300;
              int lastPeriod = displaySummary.substring(0, 300).lastIndexOf('. ');
              if (lastPeriod > 200) {
                breakPoint = lastPeriod + 1;
              }
              displaySummary = displaySummary.substring(0, breakPoint);
            }

            return Container(
              padding: EdgeInsets.all(isMobile ? 12 : 16),
              decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.purple.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (summaryContent.toString().isNotEmpty) ...[
                    SelectableText(
                      displaySummary,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface,
                        height: 1.5,
                        fontSize: isMobile ? 13 : null,
                      ),
                    ),
                    if (isMobile && isSummaryTruncated) ...[
                      const SizedBox(height: 8),
                      Center(
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              _showFullSummary = !_showFullSummary;
                            });
                          },
                          child: Text(
                            _showFullSummary ? 'Show Less' : 'Read More',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: Colors.purple,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                  if (keyPoints != null && keyPoints.isNotEmpty && (!isMobile || _showFullSummary)) ...[
                    SizedBox(height: isMobile ? 12 : 16),
                    Text(
                      'Key Points:',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.purple,
                        fontSize: isMobile ? 13 : null,
                      ),
                    ),
                    SizedBox(height: isMobile ? 6 : 8),
                    ...keyPoints.take(isMobile && !_showFullSummary ? 3 : keyPoints.length).map((point) => Padding(
                      padding: EdgeInsets.only(left: isMobile ? 12 : 16, bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('• ', style: TextStyle(color: Colors.purple, fontSize: isMobile ? 12 : null)),
                          Expanded(
                            child: SelectableText(
                              point.toString(),
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: isMobile ? 12 : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                  if (actionItems != null && actionItems.isNotEmpty && (!isMobile || _showFullSummary)) ...[
                    SizedBox(height: isMobile ? 12 : 16),
                    Text(
                      'Action Items:',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.purple,
                        fontSize: isMobile ? 13 : null,
                      ),
                    ),
                    SizedBox(height: isMobile ? 6 : 8),
                    ...actionItems.take(isMobile && !_showFullSummary ? 3 : actionItems.length).map((item) => Padding(
                      padding: EdgeInsets.only(left: isMobile ? 12 : 16, bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.check_box_outline_blank,
                            size: isMobile ? 14 : 16,
                            color: Colors.purple,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SelectableText(
                              item.toString(),
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: isMobile ? 12 : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                ],
              ),
            );
          },
          loading: () => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.purple.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.purple.withValues(alpha: 0.2),
              ),
            ),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          error: (_, __) => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.purple.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.purple.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              'Summary available. Click to view details.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorContent(BuildContext context, Object error) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: colorScheme.error.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load content',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'The document content could not be retrieved. Please try again later.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

}