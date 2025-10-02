import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/risk.dart';
import '../providers/risks_tasks_provider.dart';
import '../../../risks/presentation/screens/risks_aggregation_screen_v2.dart';
import 'risk_view_dialog.dart';

class ProjectRisksWidget extends ConsumerWidget {
  final String projectId;
  final int? limit;

  const ProjectRisksWidget({
    super.key,
    required this.projectId,
    this.limit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final risksAsync = ref.watch(risksNotifierProvider(projectId));
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        risksAsync.when(
          data: (risks) => _buildHeader(context, ref, theme, risks.isNotEmpty, risks.length),
          loading: () => _buildHeader(context, ref, theme, false, 0),
          error: (_, __) => _buildHeader(context, ref, theme, false, 0),
        ),
        const SizedBox(height: 12),
        risksAsync.when(
          data: (risks) {
            if (risks.isEmpty) {
              return _buildEmptyCard(context, ref, 'No active risks');
            }

            // Apply limit if specified
            List<Risk> displayRisks = risks;
            if (limit != null) {
              displayRisks = risks.take(limit!).toList();
            }

            final activeRisks = displayRisks.where((r) => r.isActive).toList();
            final resolvedRisks = displayRisks.where((r) => !r.isActive).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Active risks
                if (activeRisks.isNotEmpty) ...[
                  ...activeRisks.map((risk) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _buildRiskCard(context, ref, risk),
                  )),
                ],

                // Resolved risks
                if (resolvedRisks.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Theme(
                    data: Theme.of(context).copyWith(
                      dividerColor: Colors.transparent,
                    ),
                    child: ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      childrenPadding: EdgeInsets.zero,
                      collapsedShape: const RoundedRectangleBorder(
                        side: BorderSide.none,
                      ),
                      shape: const RoundedRectangleBorder(
                        side: BorderSide.none,
                      ),
                      title: Text(
                        'Resolved (${resolvedRisks.length})',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      children: resolvedRisks.map((risk) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _buildRiskCard(context, ref, risk),
                      )).toList(),
                    ),
                  ),
                ],
              ],
            );
          },
          loading: () => const LinearProgressIndicator(),
          error: (_, __) => _buildEmptyCard(context, ref, 'Error loading risks'),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, ThemeData theme, bool hasRisks, int count) {
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              'Risks & Issues',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (count > 0) Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasRisks)
              TextButton(
                onPressed: () => context.push('/risks?project=$projectId&from=project'),
                child: const Text('See all'),
              ),
            IconButton(
              icon: const Icon(Icons.add, size: 20),
              onPressed: () => _showAddRiskDialog(context, ref),
              tooltip: 'Add Risk',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyCard(BuildContext context, WidgetRef ref, String message) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.08),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.shield_outlined,
                size: 32,
                color: colorScheme.primary.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No risks identified yet',
              style: textTheme.titleSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Upload meeting transcripts to automatically identify project risks and issues',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskCard(BuildContext context, WidgetRef ref, Risk risk) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showRiskDetails(context, ref, risk),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.05),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Severity indicator dot
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _getSeverityColor(risk.severity),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              // Content
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            risk.title,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${risk.severityLabel} • ${risk.statusLabel}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (risk.aiGenerated)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        margin: const EdgeInsets.only(left: 8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          'AI',
                          style: TextStyle(
                            color: Colors.blue.withValues(alpha: 0.8),
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    // Assignment display
                    if (risk.assignedTo != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        constraints: const BoxConstraints(maxWidth: 80),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 12,
                              color: colorScheme.tertiary,
                            ),
                            const SizedBox(width: 2),
                            Flexible(
                              child: Text(
                                risk.assignedTo!,
                                style: TextStyle(
                                  color: colorScheme.tertiary,
                                  fontSize: 10,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
                    Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddRiskDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => CreateRiskDialog(
        initialProjectId: projectId,
        onCreated: () {
          ref.refresh(risksNotifierProvider(projectId));
        },
      ),
    );
  }

  void _showRiskDetails(BuildContext context, WidgetRef ref, Risk risk) {
    showDialog(
      context: context,
      builder: (context) => RiskViewDialog(projectId: projectId, risk: risk),
    ).then((_) {
      ref.refresh(risksNotifierProvider(projectId));
    });
  }

  Color _getSeverityColor(RiskSeverity severity) {
    switch (severity) {
      case RiskSeverity.low:
        return Colors.blue;
      case RiskSeverity.medium:
        return Colors.orange;
      case RiskSeverity.high:
        return Colors.deepOrange;
      case RiskSeverity.critical:
        return Colors.red;
    }
  }

}