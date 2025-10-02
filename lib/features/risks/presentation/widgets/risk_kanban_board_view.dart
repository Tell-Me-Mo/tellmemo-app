import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../projects/domain/entities/risk.dart';
import '../../../projects/presentation/providers/risks_tasks_provider.dart';
import '../providers/aggregated_risks_provider.dart';
import '../providers/global_risks_sync_provider.dart';
import 'risk_kanban_card.dart';

class RiskKanbanBoardView extends ConsumerStatefulWidget {
  final List<AggregatedRisk> risks;

  const RiskKanbanBoardView({
    super.key,
    required this.risks,
  });

  @override
  ConsumerState<RiskKanbanBoardView> createState() => _RiskKanbanBoardViewState();
}

class _RiskKanbanBoardViewState extends ConsumerState<RiskKanbanBoardView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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

  String _getStatusLabel(RiskStatus status) {
    switch (status) {
      case RiskStatus.identified:
        return 'Identified';
      case RiskStatus.mitigating:
        return 'Mitigating';
      case RiskStatus.resolved:
        return 'Resolved';
      case RiskStatus.accepted:
        return 'Accepted';
      case RiskStatus.escalated:
        return 'Escalated';
    }
  }

  IconData _getStatusIcon(RiskStatus status) {
    switch (status) {
      case RiskStatus.identified:
        return Icons.visibility;
      case RiskStatus.mitigating:
        return Icons.engineering;
      case RiskStatus.resolved:
        return Icons.check_circle;
      case RiskStatus.accepted:
        return Icons.thumb_up;
      case RiskStatus.escalated:
        return Icons.priority_high;
    }
  }

  List<AggregatedRisk> _getRisksForStatus(RiskStatus status) {
    return widget.risks.where((ar) => ar.risk.status == status).toList();
  }

  Future<void> _handleRiskStatusChange(AggregatedRisk aggregatedRisk, RiskStatus newStatus) async {
    if (aggregatedRisk.risk.status == newStatus) return;

    final repository = ref.read(risksTasksRepositoryProvider);

    try {
      final updatedRisk = aggregatedRisk.risk.copyWith(
        status: newStatus,
        resolvedDate: newStatus == RiskStatus.resolved ? DateTime.now() : null,
        lastUpdated: DateTime.now(),
      );

      await repository.updateRisk(aggregatedRisk.risk.id, updatedRisk);

      // Use global sync to refresh all risk providers
      ref.read(globalRisksSyncProvider.notifier).invalidateAllRiskProviders();

      // No success snackbar needed - UI will update automatically
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update risk: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Define the status columns (excluding accepted for now)
    final statuses = [
      RiskStatus.identified,
      RiskStatus.mitigating,
      RiskStatus.escalated,
      RiskStatus.resolved,
    ];

    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: statuses.map((status) => _buildColumn(status, theme)).toList(),
        ),
      ),
    );
  }

  Widget _buildColumn(RiskStatus status, ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final statusColor = _getStatusColor(status);
    final risks = _getRisksForStatus(status);

    return Container(
      width: 320,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Column header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              border: Border.all(
                color: statusColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getStatusIcon(status),
                  size: 20,
                  color: statusColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getStatusLabel(status),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${risks.length}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Column content with drag target
          Expanded(
            child: DragTarget<AggregatedRisk>(
              onWillAcceptWithDetails: (details) {
                // Accept risks from other columns only
                return details.data.risk.status != status;
              },
              onAcceptWithDetails: (details) async {
                await _handleRiskStatusChange(details.data, status);
              },
              builder: (context, candidateData, rejectedData) {
                return Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(minHeight: 200),
                  decoration: BoxDecoration(
                    color: candidateData.isNotEmpty
                        ? statusColor.withValues(alpha: 0.05)
                        : colorScheme.surface,
                    border: Border.all(
                      color: candidateData.isNotEmpty
                          ? statusColor.withValues(alpha: 0.3)
                          : colorScheme.outline.withValues(alpha: 0.2),
                      width: candidateData.isNotEmpty ? 2 : 1,
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  child: risks.isEmpty
                      ? _buildEmptyColumn(theme, statusColor)
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          shrinkWrap: true,
                          itemCount: risks.length,
                          itemBuilder: (context, index) {
                            final aggregatedRisk = risks[index];
                            return Draggable<AggregatedRisk>(
                              data: aggregatedRisk,
                              feedback: Material(
                                elevation: 8,
                                borderRadius: BorderRadius.circular(8),
                                child: SizedBox(
                                  width: 300,
                                  child: RiskKanbanCard(
                                    aggregatedRisk: aggregatedRisk,
                                    isDragging: true,
                                  ),
                                ),
                              ),
                              childWhenDragging: Opacity(
                                opacity: 0.5,
                                child: RiskKanbanCard(
                                  aggregatedRisk: aggregatedRisk,
                                ),
                              ),
                              child: RiskKanbanCard(
                                aggregatedRisk: aggregatedRisk,
                              ),
                            );
                          },
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyColumn(ThemeData theme, Color statusColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 48,
            color: statusColor.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 12),
          Text(
            'Drop here',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: statusColor.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}