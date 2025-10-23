import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/models/live_insight_model.dart';

/// Card widget to display a single live insight
class InsightCard extends StatelessWidget {
  final LiveInsightModel insight;
  final VoidCallback? onTap;

  const InsightCard({
    super.key,
    required this.insight,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Type and Priority
              Row(
                children: [
                  _buildTypeChip(context),
                  const SizedBox(width: 8),
                  _buildPriorityChip(context),
                  const Spacer(),
                  if (insight.confidenceScore > 0)
                    Tooltip(
                      message: 'Confidence Score',
                      child: Row(
                        children: [
                          Icon(
                            Icons.stars,
                            size: 16,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${(insight.confidenceScore * 100).toStringAsFixed(0)}%',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Content
              Text(
                insight.content ?? '',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),

              // Context (if available)
              if (insight.context.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          insight.context,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Footer: Metadata
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  // Created timestamp
                  if (insight.createdAt != null || insight.timestamp != null)
                    _buildMetadataItem(
                      context,
                      Icons.access_time,
                      _formatTimestamp(insight.createdAt ?? insight.timestamp!),
                    ),

                  // Assigned to
                  if (insight.assignedTo != null && insight.assignedTo!.isNotEmpty)
                    _buildMetadataItem(
                      context,
                      Icons.person_outline,
                      insight.assignedTo!,
                    ),

                  // Due date
                  if (insight.dueDate != null && insight.dueDate!.isNotEmpty)
                    _buildMetadataItem(
                      context,
                      Icons.event_outlined,
                      insight.dueDate!,
                    ),

                  // Chunk index
                  if (insight.sourceChunkIndex != null)
                    _buildMetadataItem(
                      context,
                      Icons.layers_outlined,
                      'Chunk #${insight.sourceChunkIndex}',
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChip(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final icon = _getTypeIcon();
    final label = _getTypeLabel();

    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      labelStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
      backgroundColor: colorScheme.secondaryContainer,
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  Widget _buildPriorityChip(BuildContext context) {
    final color = _getPriorityColor(context);
    final label = _getPriorityLabel();

    return Chip(
      label: Text(label),
      labelStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide(color: color, width: 1),
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  Widget _buildMetadataItem(BuildContext context, IconData icon, String text) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  IconData _getTypeIcon() {
    switch (insight.type) {
      case LiveInsightType.actionItem:
        return Icons.task_alt;
      case LiveInsightType.decision:
        return Icons.gavel;
      case LiveInsightType.question:
        return Icons.help_outline;
      case LiveInsightType.risk:
        return Icons.warning_amber;
      case LiveInsightType.keyPoint:
        return Icons.lightbulb_outline;
      case LiveInsightType.relatedDiscussion:
        return Icons.link;
      case LiveInsightType.contradiction:
        return Icons.report_problem_outlined;
      case LiveInsightType.missingInfo:
        return Icons.info_outline;
    }
  }

  String _getTypeLabel() {
    switch (insight.type) {
      case LiveInsightType.actionItem:
        return 'Action Item';
      case LiveInsightType.decision:
        return 'Decision';
      case LiveInsightType.question:
        return 'Question';
      case LiveInsightType.risk:
        return 'Risk';
      case LiveInsightType.keyPoint:
        return 'Key Point';
      case LiveInsightType.relatedDiscussion:
        return 'Related';
      case LiveInsightType.contradiction:
        return 'Contradiction';
      case LiveInsightType.missingInfo:
        return 'Missing Info';
    }
  }

  Color _getPriorityColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (insight.priority) {
      case LiveInsightPriority.critical:
        return Colors.red.shade700;
      case LiveInsightPriority.high:
        return Colors.orange.shade700;
      case LiveInsightPriority.medium:
        return Colors.blue.shade700;
      case LiveInsightPriority.low:
        return colorScheme.onSurfaceVariant;
    }
  }

  String _getPriorityLabel() {
    switch (insight.priority) {
      case LiveInsightPriority.critical:
        return 'CRITICAL';
      case LiveInsightPriority.high:
        return 'HIGH';
      case LiveInsightPriority.medium:
        return 'MEDIUM';
      case LiveInsightPriority.low:
        return 'LOW';
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, y').format(timestamp);
    }
  }
}
