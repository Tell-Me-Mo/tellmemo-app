import 'package:flutter/material.dart';
import '../../domain/models/live_insight_model.dart';

/// Compact insight badge for displaying insights separately from timeline
///
/// Works with both live insights and historical insights.
/// Small, inline badge with essential information:
/// - Type icon and label
/// - Priority indicator
/// - Content preview
/// - Timestamp
class TimelineInsightBadge extends StatelessWidget {
  final LiveInsightModel insight;
  final VoidCallback? onTap;

  const TimelineInsightBadge({
    super.key,
    required this.insight,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _getTypeColor().withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Type icon
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: _getTypeColor().withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                _getTypeIcon(),
                size: 14,
                color: _getTypeColor(),
              ),
            ),
            const SizedBox(width: 8),

            // Content preview
            Expanded(
              child: Text(
                insight.content ?? '',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),

            // Priority badge
            _buildPriorityDot(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityDot(ThemeData theme) {
    final color = _getPriorityColor();

    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  IconData _getTypeIcon() {
    switch (insight.type) {
      case LiveInsightType.decision:
        return Icons.gavel;
      case LiveInsightType.risk:
        return Icons.warning_amber;
    }
  }

  Color _getTypeColor() {
    switch (insight.type) {
      case LiveInsightType.decision:
        return Colors.green;
      case LiveInsightType.risk:
        return Colors.red;
    }
  }

  Color _getPriorityColor() {
    switch (insight.priority) {
      case LiveInsightPriority.critical:
        return Colors.red.shade700;
      case LiveInsightPriority.high:
        return Colors.orange.shade700;
      case LiveInsightPriority.medium:
        return Colors.blue.shade700;
      case LiveInsightPriority.low:
        return Colors.grey.shade600;
    }
  }
}
