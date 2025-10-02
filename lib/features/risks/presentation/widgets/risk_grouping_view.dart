import 'package:flutter/material.dart';
import '../../../projects/domain/entities/risk.dart';
import '../providers/aggregated_risks_provider.dart';
import '../screens/risks_aggregation_screen_v2.dart';
import 'risk_list_tile_compact.dart';

class RiskGroupingView extends StatelessWidget {
  final List<AggregatedRisk> risks;
  final GroupingMode groupingMode;
  final Function(Risk, String) onRiskTap;
  final bool isSelectionMode;
  final Set<String> selectedRiskIds;
  final Function(String, bool) onSelectionChanged;

  const RiskGroupingView({
    super.key,
    required this.risks,
    required this.groupingMode,
    required this.onRiskTap,
    this.isSelectionMode = false,
    this.selectedRiskIds = const {},
    required this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final groupedRisks = _groupRisks();

    return Column(
      children: groupedRisks.entries.map((entry) {
        final groupKey = entry.key;
        final groupRisks = entry.value;
        final isExpanded = true; // Can make this stateful if needed

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Theme(
            data: theme.copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: isExpanded,
              title: _buildGroupHeader(context, groupKey, groupRisks.length),
              children: groupRisks.map((aggregatedRisk) {
                return _buildRiskItem(context, aggregatedRisk);
              }).toList(),
            ),
          ),
        );
      }).toList(),
    );
  }

  Map<String, List<AggregatedRisk>> _groupRisks() {
    final grouped = <String, List<AggregatedRisk>>{};

    for (final risk in risks) {
      String key;
      switch (groupingMode) {
        case GroupingMode.project:
          key = risk.project.name;
          break;
        case GroupingMode.severity:
          key = risk.risk.severityLabel;
          break;
        case GroupingMode.status:
          key = risk.risk.statusLabel;
          break;
        case GroupingMode.assigned:
          key = risk.risk.assignedTo ?? 'Unassigned';
          break;
        default:
          key = 'All';
      }

      grouped.putIfAbsent(key, () => []).add(risk);
    }

    // Sort groups
    final sortedKeys = grouped.keys.toList();
    if (groupingMode == GroupingMode.severity) {
      // Sort by severity priority
      final severityOrder = {
        'Critical': 0,
        'High': 1,
        'Medium': 2,
        'Low': 3,
      };
      sortedKeys.sort((a, b) =>
          (severityOrder[a] ?? 99).compareTo(severityOrder[b] ?? 99));
    } else {
      sortedKeys.sort();
    }

    final sortedGrouped = <String, List<AggregatedRisk>>{};
    for (final key in sortedKeys) {
      sortedGrouped[key] = grouped[key]!;
    }

    return sortedGrouped;
  }

  Widget _buildGroupHeader(BuildContext context, String groupName, int count) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    IconData icon;
    Color color;

    switch (groupingMode) {
      case GroupingMode.project:
        icon = Icons.folder;
        color = colorScheme.primary;
        break;
      case GroupingMode.severity:
        icon = Icons.warning_amber;
        color = _getSeverityColorFromLabel(groupName);
        break;
      case GroupingMode.status:
        icon = Icons.flag;
        color = _getStatusColorFromLabel(groupName);
        break;
      case GroupingMode.assigned:
        icon = Icons.person;
        color = colorScheme.tertiary;
        break;
      default:
        icon = Icons.list;
        color = colorScheme.primary;
    }

    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Text(
          groupName,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRiskItem(BuildContext context, AggregatedRisk aggregatedRisk) {
    final isSelected = selectedRiskIds.contains(aggregatedRisk.risk.id);

    return RiskListTileCompact(
      aggregatedRisk: aggregatedRisk,
      isSelected: isSelected,
      isSelectionMode: isSelectionMode,
      onTap: isSelectionMode
          ? () => onSelectionChanged(aggregatedRisk.risk.id, !isSelected)
          : () => onRiskTap(aggregatedRisk.risk, aggregatedRisk.project.id),
    );
  }

  Color _getSeverityColorFromLabel(String label) {
    switch (label.toLowerCase()) {
      case 'low':
        return Colors.blue;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.deepOrange;
      case 'critical':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColorFromLabel(String label) {
    switch (label.toLowerCase()) {
      case 'identified':
        return Colors.grey;
      case 'mitigating':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      case 'accepted':
        return Colors.teal;
      case 'escalated':
        return Colors.deepPurple;
      default:
        return Colors.grey;
    }
  }
}