import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/datetime_utils.dart';
import '../../../meetings/domain/entities/content.dart';
import '../providers/document_detail_provider.dart';
import '../../../../shared/widgets/item_detail_panel.dart';
import '../../../../shared/widgets/item_updates_tab.dart';

class DocumentDetailPanel extends ConsumerStatefulWidget {
  final Content document;

  const DocumentDetailPanel({
    super.key,
    required this.document,
  });

  @override
  ConsumerState<DocumentDetailPanel> createState() => _DocumentDetailPanelState();
}

class _DocumentDetailPanelState extends ConsumerState<DocumentDetailPanel> {
  bool _showFullTranscript = false;
  bool _showFullSummary = false;
  bool _showAllKeyPoints = false;
  bool _showAllActionItems = false;

  Color _getTypeColor() {
    switch (widget.document.contentType) {
      case ContentType.meeting:
        return Colors.blue.shade600;
      case ContentType.email:
        return Colors.orange.shade600;
    }
  }

  IconData _getTypeIcon() {
    switch (widget.document.contentType) {
      case ContentType.meeting:
        return Icons.videocam;
      case ContentType.email:
        return Icons.email;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ItemDetailPanel(
      title: widget.document.title,
      subtitle: widget.document.typeLabel,
      headerIcon: _getTypeIcon(),
      headerIconColor: _getTypeColor(),
      onClose: () => Navigator.of(context).pop(),
      headerActions: [
        // AI Assistant button (for future implementation)
        // IconButton(
        //   onPressed: () {
        //     // TODO: Implement AI assistant for documents
        //   },
        //   icon: const Icon(Icons.auto_awesome),
        //   tooltip: 'AI Assistant',
        // ),
      ],
      mainViewContent: _buildMainView(context),
      updatesContent: _buildUpdatesTab(),
    );
  }

  Widget _buildMainView(BuildContext context) {
    final contentAsync = ref.watch(documentDetailProvider(
      projectId: widget.document.projectId,
      contentId: widget.document.id,
    ));

    final summaryAsync = ref.watch(documentSummaryProvider(
      projectId: widget.document.projectId,
      contentId: widget.document.id,
    ));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Metadata Section
          _buildMetadataSection(context),

          const SizedBox(height: 24),

          // Summary Section (if available)
          if (widget.document.summaryGenerated) ...[
            _buildSummarySection(context, summaryAsync),
            const SizedBox(height: 24),
          ],

          // Transcription/Content Section
          contentAsync.when(
            data: (content) {
              if (content != null && content['content'] != null) {
                return _buildTranscriptionSection(context, content['content']);
              }
              return _buildEmptyContent(context);
            },
            loading: () => _buildLoadingContent(context),
            error: (error, _) => _buildErrorContent(context, error),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataSection(BuildContext context) {
    final theme = Theme.of(context);
    final date = widget.document.date ?? widget.document.uploadedAt;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Document Information',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildMetadataChip(
              context,
              Icons.calendar_today_outlined,
              DateTimeUtils.formatDateTime(date),
              Colors.blue,
            ),
            _buildStatusChip(context),
            if (widget.document.chunkCount > 0)
              _buildMetadataChip(
                context,
                Icons.segment,
                '${widget.document.chunkCount} chunks',
                Colors.purple,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusChip(BuildContext context) {
    IconData icon;
    String label;
    Color color;

    if (widget.document.isProcessed) {
      icon = Icons.check_circle_outline;
      label = 'Processed';
      color = Colors.green;
    } else if (widget.document.isProcessing) {
      icon = Icons.schedule;
      label = 'Processing';
      color = Colors.orange;
    } else if (widget.document.hasError) {
      icon = Icons.error_outline;
      label = 'Error';
      color = Theme.of(context).colorScheme.error;
    } else {
      icon = Icons.info_outline;
      label = 'Pending';
      color = Colors.grey;
    }

    return _buildMetadataChip(context, icon, label, color);
  }

  Widget _buildMetadataChip(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Use neutral colors instead of bright ones
    final chipColor = colorScheme.surfaceContainerHighest;
    final iconColor = colorScheme.onSurfaceVariant;
    final textColor = colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection(
    BuildContext context,
    AsyncValue<Map<String, dynamic>?> summaryAsync,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.summarize,
              size: 20,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Summary',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        summaryAsync.when(
          data: (summary) {
            if (summary == null) {
              return _buildSummaryPlaceholder(context);
            }

            final summaryContent = summary['body'] ??
                summary['summary_content'] ??
                summary['content'] ??
                '';
            final keyPoints = summary['key_points'] as List?;
            final actionItems = summary['action_items'] as List?;

            String displaySummary = summaryContent.toString();
            bool isSummaryTruncated = false;

            if (!_showFullSummary && displaySummary.length > 400) {
              isSummaryTruncated = true;
              int breakPoint = 400;
              int lastPeriod = displaySummary.substring(0, 400).lastIndexOf('. ');
              if (lastPeriod > 300) {
                breakPoint = lastPeriod + 1;
              }
              displaySummary = displaySummary.substring(0, breakPoint);
            }

            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.15),
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
                        height: 1.6,
                      ),
                    ),
                    if (isSummaryTruncated) ...[
                      const SizedBox(height: 8),
                      Center(
                        child: TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _showFullSummary = !_showFullSummary;
                            });
                          },
                          icon: Icon(
                            _showFullSummary ? Icons.expand_less : Icons.expand_more,
                            size: 18,
                          ),
                          label: Text(_showFullSummary ? 'Show Less' : 'Read More'),
                        ),
                      ),
                    ],
                  ],
                  if (keyPoints != null && keyPoints.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),
                    Text(
                      'Key Points:',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...(_showAllKeyPoints ? keyPoints : keyPoints.take(3)).map((point) {
                      // Parse key point - it can be a string or an object
                      String displayText;
                      if (point is Map) {
                        // If it's a map/object, try to extract meaningful text
                        displayText = point['text']?.toString() ??
                            point['point']?.toString() ??
                            point['description']?.toString() ??
                            point.values.firstOrNull?.toString() ??
                            '';
                      } else {
                        displayText = point.toString();
                      }

                      return Padding(
                        padding: const EdgeInsets.only(left: 16, bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('• ', style: TextStyle(color: colorScheme.primary)),
                            Expanded(
                              child: SelectableText(
                                displayText,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    if (keyPoints.length > 3) ...[
                      const SizedBox(height: 4),
                      Center(
                        child: TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _showAllKeyPoints = !_showAllKeyPoints;
                            });
                          },
                          icon: Icon(
                            _showAllKeyPoints ? Icons.expand_less : Icons.expand_more,
                            size: 18,
                          ),
                          label: Text(_showAllKeyPoints
                            ? 'Show Less'
                            : 'Show ${keyPoints.length - 3} More'),
                        ),
                      ),
                    ],
                  ],
                  if (actionItems != null && actionItems.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),
                    Text(
                      'Action Items:',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...(_showAllActionItems ? actionItems : actionItems.take(3)).map((item) {
                      // Parse action item - it can be a string or an object
                      String displayText;
                      if (item is Map) {
                        // If it's a map/object, extract title and description
                        final title = item['title']?.toString() ?? '';
                        final description = item['description']?.toString() ?? '';
                        final assignee = item['assignee']?.toString();
                        final dueDate = item['due_date']?.toString();

                        // Build a readable display text
                        final parts = <String>[];
                        if (title.isNotEmpty) {
                          parts.add(title);
                        }
                        if (description.isNotEmpty && description != title) {
                          parts.add(description);
                        }
                        if (assignee != null && assignee != 'null' && assignee.isNotEmpty) {
                          parts.add('Assignee: $assignee');
                        }
                        if (dueDate != null && dueDate != 'null' && dueDate.isNotEmpty) {
                          try {
                            final date = DateTime.parse(dueDate);
                            parts.add('Due: ${DateFormat('MMM d, y').format(date)}');
                          } catch (_) {
                            // Ignore date parsing errors
                          }
                        }

                        displayText = parts.join(' • ');
                      } else {
                        displayText = item.toString();
                      }

                      return Padding(
                        padding: const EdgeInsets.only(left: 16, bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.check_box_outline_blank,
                              size: 16,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: SelectableText(
                                displayText,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    if (actionItems.length > 3) ...[
                      const SizedBox(height: 4),
                      Center(
                        child: TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _showAllActionItems = !_showAllActionItems;
                            });
                          },
                          icon: Icon(
                            _showAllActionItems ? Icons.expand_less : Icons.expand_more,
                            size: 18,
                          ),
                          label: Text(_showAllActionItems
                            ? 'Show Less'
                            : 'Show ${actionItems.length - 3} More'),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            );
          },
          loading: () => _buildLoadingContent(context),
          error: (_, __) => _buildSummaryPlaceholder(context),
        ),
      ],
    );
  }

  Widget _buildSummaryPlaceholder(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.15),
        ),
      ),
      child: Text(
        'Summary available. Loading details...',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurface.withValues(alpha: 0.6),
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildTranscriptionSection(BuildContext context, String content) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final int previewCharLimit = 400;
    final bool hasMoreContent = content.length > previewCharLimit;

    String displayContent;
    if (_showFullTranscript || !hasMoreContent) {
      displayContent = content;
    } else {
      String truncated = content.substring(0, previewCharLimit);
      int breakPoint = previewCharLimit;

      int lastNewline = truncated.lastIndexOf('\n');
      if (lastNewline > previewCharLimit * 0.8) {
        breakPoint = lastNewline;
      } else {
        int lastPeriod = truncated.lastIndexOf('. ');
        if (lastPeriod > previewCharLimit * 0.8) {
          breakPoint = lastPeriod + 1;
        } else {
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
              size: 20,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Transcription',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SelectableText(
                displayContent,
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.6,
                  color: colorScheme.onSurface,
                  fontFamily: 'monospace',
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
                      _showFullTranscript ? Icons.expand_less : Icons.expand_more,
                      size: 20,
                    ),
                    label: Text(_showFullTranscript ? 'Show Less' : 'View More'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyContent(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 48,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No content available',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'The document content is not yet available.',
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

  Widget _buildLoadingContent(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorContent(BuildContext context, Object error) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(32),
      child: Center(
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
              'The document content could not be retrieved.',
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

  Widget _buildUpdatesTab() {
    // TODO: Replace with actual updates from backend when API is ready
    final mockUpdates = <ItemUpdate>[
      ItemUpdate(
        id: '1',
        content: 'Document uploaded and processed',
        authorName: 'System',
        timestamp: widget.document.uploadedAt,
        type: ItemUpdateType.created,
      ),
    ];

    return ItemUpdatesTab(
      updates: mockUpdates,
      itemType: 'document',
      onAddComment: (content) async {
        // TODO: Implement comment submission to backend
        // For now, documents are read-only
      },
    );
  }
}
