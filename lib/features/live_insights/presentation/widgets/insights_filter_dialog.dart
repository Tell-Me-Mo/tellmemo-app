import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/live_insight_model.dart';
import '../providers/historical_insights_provider.dart';

/// Dialog for filtering historical insights
class InsightsFilterDialog extends ConsumerWidget {
  const InsightsFilterDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(historicalInsightsProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.filter_list, color: colorScheme.primary),
          const SizedBox(width: 12),
          const Text('Filter Insights'),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type Filter
            Text(
              'Insight Type',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildTypeFilterChip(
                  context,
                  ref,
                  null,
                  'All Types',
                  state.filterType == null,
                ),
                ...LiveInsightType.values.map((type) => _buildTypeFilterChip(
                      context,
                      ref,
                      type,
                      _getTypeLabel(type),
                      state.filterType == type,
                    )),
              ],
            ),
            const SizedBox(height: 24),

            // Priority Filter
            Text(
              'Priority',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildPriorityFilterChip(
                  context,
                  ref,
                  null,
                  'All Priorities',
                  state.filterPriority == null,
                ),
                ...LiveInsightPriority.values.map((priority) =>
                    _buildPriorityFilterChip(
                      context,
                      ref,
                      priority,
                      _getPriorityLabel(priority),
                      state.filterPriority == priority,
                    )),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            ref.read(historicalInsightsProvider.notifier).clearFilters();
            Navigator.of(context).pop();
          },
          child: const Text('Clear All'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Apply'),
        ),
      ],
    );
  }

  Widget _buildTypeFilterChip(
    BuildContext context,
    WidgetRef ref,
    LiveInsightType? type,
    String label,
    bool isSelected,
  ) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        ref.read(historicalInsightsProvider.notifier).setTypeFilter(
              selected ? type : null,
            );
      },
    );
  }

  Widget _buildPriorityFilterChip(
    BuildContext context,
    WidgetRef ref,
    LiveInsightPriority? priority,
    String label,
    bool isSelected,
  ) {
    final color = priority != null ? _getPriorityColor(context, priority) : null;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: color?.withValues(alpha: 0.2),
      checkmarkColor: color,
      onSelected: (selected) {
        ref.read(historicalInsightsProvider.notifier).setPriorityFilter(
              selected ? priority : null,
            );
      },
    );
  }

  String _getTypeLabel(LiveInsightType type) {
    switch (type) {
      case LiveInsightType.actionItem:
        return 'Action Items';
      case LiveInsightType.decision:
        return 'Decisions';
      case LiveInsightType.question:
        return 'Questions';
      case LiveInsightType.risk:
        return 'Risks';
      case LiveInsightType.keyPoint:
        return 'Key Points';
      case LiveInsightType.relatedDiscussion:
        return 'Related';
      case LiveInsightType.contradiction:
        return 'Contradictions';
      case LiveInsightType.missingInfo:
        return 'Missing Info';
    }
  }

  String _getPriorityLabel(LiveInsightPriority priority) {
    switch (priority) {
      case LiveInsightPriority.critical:
        return 'Critical';
      case LiveInsightPriority.high:
        return 'High';
      case LiveInsightPriority.medium:
        return 'Medium';
      case LiveInsightPriority.low:
        return 'Low';
    }
  }

  Color _getPriorityColor(BuildContext context, LiveInsightPriority priority) {
    switch (priority) {
      case LiveInsightPriority.critical:
        return Colors.red.shade700;
      case LiveInsightPriority.high:
        return Colors.orange.shade700;
      case LiveInsightPriority.medium:
        return Colors.blue.shade700;
      case LiveInsightPriority.low:
        return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }
}
