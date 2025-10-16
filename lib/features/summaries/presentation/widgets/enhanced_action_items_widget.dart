import 'package:flutter/material.dart';
import '../../../../core/utils/datetime_utils.dart';
import '../../data/models/summary_model.dart';

class EnhancedActionItemsWidget extends StatelessWidget {
  final List<ActionItem> actionItems;

  const EnhancedActionItemsWidget({
    super.key,
    required this.actionItems,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: actionItems.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        return _buildActionItem(context, item, index);
      }).toList(),
    );
  }

  Widget _buildActionItem(BuildContext context, ActionItem item, int index) {
    final theme = Theme.of(context);
    final urgencyColor = _getUrgencyColor(item.urgency);
    final dueDate = _parseDueDate(item.dueDate);
    final isOverdue = _isOverdue(dueDate);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status indicator
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isOverdue ? Colors.red : urgencyColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Action description
                SelectableText(
                  item.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.4,
                  ),
                ),

                // Owner and due date info
                if (item.assignee != null || item.dueDate != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (item.assignee != null) ...[
                        Icon(
                          Icons.person_outline,
                          size: 14,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item.assignee!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      if (item.assignee != null && item.dueDate != null) ...[
                        const SizedBox(width: 12),
                      ],
                      if (item.dueDate != null && dueDate != null) ...[
                        Icon(
                          Icons.schedule_outlined,
                          size: 14,
                          color: isOverdue
                            ? Colors.red
                            : theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateTimeUtils.formatRelativeTime(dueDate),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isOverdue
                              ? Colors.red
                              : theme.colorScheme.onSurfaceVariant,
                            fontWeight: isOverdue ? FontWeight.w600 : null,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Priority/Status indicator
          if (_isHighUrgency(item.urgency) || isOverdue)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: (isOverdue ? Colors.red : urgencyColor).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isOverdue ? 'OVERDUE' : _formatUrgency(item.urgency).toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isOverdue ? Colors.red : urgencyColor,
                  letterSpacing: 0.5,
                ),
              ),
            ),
        ],
      ),
    );
  }

  bool _isHighUrgency(String urgency) {
    switch (urgency.toLowerCase()) {
      case 'critical':
      case 'high':
      case 'urgent':
        return true;
      default:
        return false;
    }
  }

  bool _isOverdue(DateTime? dueDate) {
    if (dueDate == null) return false;
    return DateTime.now().isAfter(dueDate);
  }


  Color _getUrgencyColor(String urgency) {
    switch (urgency.toLowerCase()) {
      case 'critical':
        return Colors.red.shade600;
      case 'high':
      case 'urgent':
        return Colors.orange.shade600;
      case 'medium':
        return Colors.blue.shade600;
      case 'low':
        return Colors.green.shade600;
      default:
        return Colors.blue.shade600;
    }
  }

  String _formatUrgency(String urgency) {
    return urgency.split(' ').map((word) {
      return word.isNotEmpty
        ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
        : '';
    }).join(' ');
  }

  DateTime? _parseDueDate(String? dueDate) {
    if (dueDate == null || dueDate.isEmpty) return null;
    try {
      return DateTime.parse('${dueDate}Z').toLocal();
    } catch (e) {
      return null;
    }
  }
}