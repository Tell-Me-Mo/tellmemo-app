import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../projects/domain/entities/risk.dart';
import '../providers/aggregated_risks_provider.dart';

class RiskKanbanCard extends ConsumerWidget {
  final AggregatedRisk aggregatedRisk;
  final bool isDragging;

  const RiskKanbanCard({
    super.key,
    required this.aggregatedRisk,
    this.isDragging = false,
  });

  Color _getSeverityColor(RiskSeverity severity) {
    switch (severity) {
      case RiskSeverity.low:
        return Colors.green;
      case RiskSeverity.medium:
        return Colors.orange;
      case RiskSeverity.high:
        return Colors.red.shade400;
      case RiskSeverity.critical:
        return Colors.red;
    }
  }

  String _formatCompactDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return '1d ago';
    } else if (difference.inDays < 30) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).round()}mo ago';
    } else {
      return '${(difference.inDays / 365).round()}y ago';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final risk = aggregatedRisk.risk;
    final project = aggregatedRisk.project;
    final severityColor = _getSeverityColor(risk.severity);

    return Card(
      elevation: isDragging ? 8 : 1,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: severityColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with severity and project
            Row(
              children: [
                // Severity badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: severityColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.flag,
                        size: 12,
                        color: severityColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        risk.severityLabel,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: severityColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),

                // Project badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.folder_outlined,
                        size: 12,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 80),
                        child: Text(
                          project.name,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w500,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Risk title
            Text(
              risk.title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            // Description (if present)
            if (risk.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                risk.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),

            // Bottom row with metadata
            Row(
              children: [
                // Assignee (if assigned)
                if (risk.assignedTo != null) ...[
                  Icon(
                    Icons.person_outline,
                    size: 14,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 4),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 80),
                    child: Text(
                      risk.assignedTo!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.tertiary,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Spacer(),
                ],

                // AI-generated badge
                if (risk.aiGenerated)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      size: 12,
                      color: Colors.purple,
                    ),
                  ),

                // Date (if available)
                if (risk.identifiedDate != null) ...[
                  if (risk.aiGenerated || risk.assignedTo != null) const SizedBox(width: 8),
                  if (risk.assignedTo == null && !risk.aiGenerated) const Spacer(),
                  Text(
                    _formatCompactDate(risk.identifiedDate!),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}