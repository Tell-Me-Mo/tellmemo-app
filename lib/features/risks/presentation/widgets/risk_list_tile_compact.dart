import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../projects/domain/entities/risk.dart';
import '../providers/aggregated_risks_provider.dart';

class RiskListTileCompact extends ConsumerWidget {
  final AggregatedRisk aggregatedRisk;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Function(String action, Risk risk, String projectId)? onActionSelected;

  const RiskListTileCompact({
    super.key,
    required this.aggregatedRisk,
    required this.isSelected,
    required this.isSelectionMode,
    this.onTap,
    this.onLongPress,
    this.onActionSelected,
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

  Color _getStatusColor(RiskStatus status) {
    switch (status) {
      case RiskStatus.identified:
        return Colors.amber;
      case RiskStatus.mitigating:
        return Colors.blue;
      case RiskStatus.resolved:
        return Colors.green;
      case RiskStatus.accepted:
        return Colors.grey;
      case RiskStatus.escalated:
        return Colors.deepPurple;
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
    final statusColor = _getStatusColor(risk.status);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(
          color: isSelected
              ? colorScheme.error
              : colorScheme.outline.withValues(alpha: 0.15),
          width: isSelected ? 2 : 1,
        ),
      ),
      color: isSelected
          ? colorScheme.errorContainer.withValues(alpha: 0.1)
          : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          padding: const EdgeInsets.only(left: 10, top: 10, bottom: 10, right: 10),
          child: Row(
            children: [
              // Priority indicator - vertical line
              Container(
                width: 2,
                height: 36,
                decoration: BoxDecoration(
                  color: severityColor,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
              const SizedBox(width: 10),

              // Selection checkbox (if in selection mode)
              if (isSelectionMode) ...[
                SizedBox(
                  width: 28,
                  height: 28,
                  child: Checkbox(
                    value: isSelected,
                    onChanged: (value) => onTap?.call(),
                  ),
                ),
                const SizedBox(width: 10),
              ],

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title and badges row
                    Row(
                      children: [
                        // Title
                        Expanded(
                          child: Text(
                            risk.title,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Severity badge (only show if high or critical)
                        if (risk.severity == RiskSeverity.high ||
                            risk.severity == RiskSeverity.critical)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: severityColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Icon(
                              Icons.flag,
                              size: 11,
                              color: severityColor,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Metadata row
                    Row(
                      children: [
                        // Left side - project and metadata
                        Expanded(
                          child: Row(
                            children: [
                              // Project label
                              Icon(
                                Icons.folder_outlined,
                                size: 11,
                                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                              ),
                              const SizedBox(width: 3),
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 100),
                                child: Text(
                                  project.name,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                                    fontSize: 10,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Status badge (only show for non-identified)
                              if (risk.status != RiskStatus.identified)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Text(
                                    risk.statusLabel,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: statusColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),

                              // Assignee (if assigned)
                              if (risk.assignedTo != null) ...[
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.person_outline,
                                  size: 11,
                                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                                ),
                                const SizedBox(width: 3),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 80),
                                  child: Text(
                                    risk.assignedTo!,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: colorScheme.tertiary,
                                      fontSize: 10,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        // Right side - badges
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Date (if available)
                            if (risk.identifiedDate != null) ...[
                              Text(
                                _formatCompactDate(risk.identifiedDate!),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Context menu (if not in selection mode)
              if (!isSelectionMode && onActionSelected != null)
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    size: 16,
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  onSelected: (action) => onActionSelected!(action, risk, project.id),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit, size: 16),
                        title: Text('Edit'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'assign',
                      child: ListTile(
                        leading: Icon(Icons.person_add, size: 16),
                        title: Text('Assign'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'status',
                      child: ListTile(
                        leading: Icon(Icons.flag, size: 16),
                        title: Text('Update Status'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete, size: 16, color: Colors.red),
                        title: Text('Delete', style: TextStyle(color: Colors.red)),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}