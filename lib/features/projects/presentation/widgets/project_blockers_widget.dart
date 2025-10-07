import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/blocker.dart';
import '../../domain/entities/project.dart';
import '../providers/risks_tasks_provider.dart';
import 'blocker_dialog.dart';
import 'blocker_detail_dialog.dart';

class ProjectBlockersWidget extends ConsumerWidget {
  final String projectId;
  final int? limit;
  final Project? project;

  const ProjectBlockersWidget({
    super.key,
    required this.projectId,
    this.limit,
    this.project,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blockersAsync = ref.watch(blockersNotifierProvider(projectId));
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        blockersAsync.when(
          data: (blockers) => _buildHeader(context, ref, theme, blockers.isNotEmpty, blockers.length),
          loading: () => _buildHeader(context, ref, theme, false, 0),
          error: (_, __) => _buildHeader(context, ref, theme, false, 0),
        ),
        const SizedBox(height: 12),
        blockersAsync.when(
          data: (blockers) {
            if (blockers.isEmpty) {
              return _buildEmptyCard(context, ref, 'No active blockers');
            }

            // Apply limit if specified
            List<Blocker> displayBlockers = blockers;
            if (limit != null) {
              displayBlockers = blockers.take(limit!).toList();
            }

            final activeBlockers = displayBlockers.where((b) => b.isActive).toList();
            final pendingBlockers = displayBlockers.where((b) => b.isPending).toList();
            final resolvedBlockers = displayBlockers.where((b) => b.isResolved).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Active blockers
                if (activeBlockers.isNotEmpty) ...[
                  ...activeBlockers.map((blocker) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _buildBlockerCard(context, ref, blocker),
                  )),
                ],

                // Pending blockers
                if (pendingBlockers.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ExpansionTile(
                    title: Text(
                      'Pending (${pendingBlockers.length})',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    children: pendingBlockers.map((blocker) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _buildBlockerCard(context, ref, blocker),
                    )).toList(),
                  ),
                ],

                // Resolved blockers
                if (resolvedBlockers.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ExpansionTile(
                    title: Text(
                      'Resolved (${resolvedBlockers.length})',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    children: resolvedBlockers.map((blocker) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _buildBlockerCard(context, ref, blocker),
                    )).toList(),
                  ),
                ],
              ],
            );
          },
          loading: () => const LinearProgressIndicator(),
          error: (_, __) => _buildEmptyCard(context, ref, 'Error loading blockers'),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, ThemeData theme, bool hasBlockers, int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              Icons.block,
              size: 20,
              color: theme.colorScheme.error.withValues(alpha: 0.8),
            ),
            const SizedBox(width: 8),
            Text(
              'Blockers',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (count > 0) Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
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
            if (hasBlockers)
              TextButton(
                onPressed: () => _showAllBlockersDialog(context, ref),
                child: const Text('See all'),
              ),
            IconButton(
              icon: const Icon(Icons.add, size: 20),
              onPressed: () => _showAddBlockerDialog(context, ref),
              tooltip: 'Add Blocker',
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 20 : 40,
        horizontal: isMobile ? 16 : 24,
      ),
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
              padding: EdgeInsets.all(isMobile ? 8 : 12),
              decoration: BoxDecoration(
                color: colorScheme.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.block_outlined,
                size: isMobile ? 24 : 32,
                color: colorScheme.error.withValues(alpha: 0.6),
              ),
            ),
            SizedBox(height: isMobile ? 12 : 16),
            Text(
              'No blockers identified',
              style: textTheme.titleSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
                fontSize: isMobile ? 13 : null,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Track critical issues that are blocking project progress',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                fontSize: isMobile ? 11 : null,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlockerCard(BuildContext context, WidgetRef ref, Blocker blocker) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showBlockerDetails(context, ref, blocker),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _getBlockerBackgroundColor(blocker, colorScheme),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _getImpactColor(blocker.impact).withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Impact indicator
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _getImpactColor(blocker.impact),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              // Status icon
              Icon(
                _getStatusIcon(blocker.status),
                size: 16,
                color: _getStatusColor(blocker.status, colorScheme),
              ),
              const SizedBox(width: 8),
              // Content
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            blocker.title,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                              decoration: blocker.isResolved ? TextDecoration.lineThrough : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${blocker.impactLabel} Impact • ${blocker.statusLabel}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (blocker.aiGenerated)
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
                    // Owner/Assignee display
                    if (blocker.owner != null || blocker.assignedTo != null) ...[
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
                                blocker.owner ?? blocker.assignedTo ?? '',
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

  Widget _buildExpandedBlockerCard(BuildContext context, WidgetRef ref, Blocker blocker) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showBlockerDetails(context, ref, blocker),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _getBlockerBackgroundColor(blocker, colorScheme),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _getImpactColor(blocker.impact).withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with impact indicator, title, and metadata
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Impact indicator
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 6),
                    decoration: BoxDecoration(
                      color: _getImpactColor(blocker.impact),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Title and content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title row with status and AI badge
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                blocker.title,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  decoration: blocker.isResolved ? TextDecoration.lineThrough : null,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Status icon
                            Icon(
                              _getStatusIcon(blocker.status),
                              size: 16,
                              color: _getStatusColor(blocker.status, colorScheme),
                            ),
                            if (blocker.aiGenerated) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'AI',
                                  style: TextStyle(
                                    color: Colors.blue.withValues(alpha: 0.8),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Description
                        if (blocker.description.isNotEmpty)
                          Text(
                            blocker.description,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                              height: 1.4,
                            ),
                          ),
                        const SizedBox(height: 12),
                        // Metadata row
                        Row(
                          children: [
                            // Impact and status
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getImpactColor(blocker.impact).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${blocker.impactLabel} Impact',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: _getImpactColor(blocker.impact),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getStatusColor(blocker.status, colorScheme).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                blocker.statusLabel,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: _getStatusColor(blocker.status, colorScheme),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const Spacer(),
                            // Owner/Assignee
                            if (blocker.owner != null || blocker.assignedTo != null) ...[
                              Icon(
                                Icons.person_outline,
                                size: 14,
                                color: colorScheme.tertiary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                blocker.owner ?? blocker.assignedTo ?? '',
                                style: TextStyle(
                                  color: colorScheme.tertiary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
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

  void _showAllBlockersDialog(BuildContext context, WidgetRef ref) {
    final blockersAsync = ref.watch(blockersNotifierProvider(projectId));

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          constraints: const BoxConstraints(
            maxWidth: 600,
            maxHeight: 700,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.block,
                      size: 24,
                      color: Theme.of(context).colorScheme.error.withValues(alpha: 0.8),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'All Blockers',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Close',
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: blockersAsync.when(
                  data: (blockers) {
                    if (blockers.isEmpty) {
                      return _buildEmptyDialogState(context);
                    }

                    final activeBlockers = blockers.where((b) => b.isActive).toList();
                    final pendingBlockers = blockers.where((b) => b.isPending).toList();
                    final resolvedBlockers = blockers.where((b) => b.isResolved).toList();

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Active blockers
                          if (activeBlockers.isNotEmpty) ...[
                            _buildDialogSectionHeader(context, 'Active Blockers', Colors.red, activeBlockers.length),
                            const SizedBox(height: 12),
                            ...activeBlockers.map((blocker) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _buildExpandedBlockerCard(context, ref, blocker),
                            )),
                          ],

                          // Pending blockers
                          if (pendingBlockers.isNotEmpty) ...[
                            if (activeBlockers.isNotEmpty) const SizedBox(height: 24),
                            _buildDialogSectionHeader(context, 'Pending Blockers', Colors.orange, pendingBlockers.length),
                            const SizedBox(height: 12),
                            ...pendingBlockers.map((blocker) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _buildExpandedBlockerCard(context, ref, blocker),
                            )),
                          ],

                          // Resolved blockers
                          if (resolvedBlockers.isNotEmpty) ...[
                            if (activeBlockers.isNotEmpty || pendingBlockers.isNotEmpty) const SizedBox(height: 24),
                            _buildDialogSectionHeader(context, 'Resolved Blockers', Colors.green, resolvedBlockers.length),
                            const SizedBox(height: 12),
                            ...resolvedBlockers.map((blocker) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _buildExpandedBlockerCard(context, ref, blocker),
                            )),
                          ],
                        ],
                      ),
                    );
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (error, stackTrace) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Theme.of(context).colorScheme.error.withValues(alpha: 0.7),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Failed to load blockers',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            error.toString(),
                            style: Theme.of(context).textTheme.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Footer with action button
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _showAddBlockerDialog(context, ref);
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Blocker'),
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

  Widget _buildDialogSectionHeader(BuildContext context, String title, Color color, int count) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
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
            count.toString(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyDialogState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.block_outlined,
                size: 48,
                color: colorScheme.error.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No blockers found',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Track critical issues that are blocking project progress',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showAddBlockerDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => BlockerDialog(
        projectId: projectId,
      ),
    ).then((_) {
      ref.refresh(blockersNotifierProvider(projectId));
    });
  }

  void _showBlockerDetails(BuildContext context, WidgetRef ref, Blocker blocker) {
    showDialog(
      context: context,
      builder: (context) => BlockerDetailDialog(
        projectId: projectId,
        blocker: blocker,
        project: project,
      ),
    ).then((_) {
      ref.refresh(blockersNotifierProvider(projectId));
    });
  }

  Color _getImpactColor(BlockerImpact impact) {
    switch (impact) {
      case BlockerImpact.low:
        return Colors.blue;
      case BlockerImpact.medium:
        return Colors.orange;
      case BlockerImpact.high:
        return Colors.deepOrange;
      case BlockerImpact.critical:
        return Colors.red;
    }
  }

  Color _getBlockerBackgroundColor(Blocker blocker, ColorScheme colorScheme) {
    if (blocker.isResolved) {
      return colorScheme.surfaceContainerHighest.withValues(alpha: 0.04);
    } else if (blocker.status == BlockerStatus.escalated) {
      return colorScheme.error.withValues(alpha: 0.05);
    } else if (blocker.status == BlockerStatus.pending) {
      return colorScheme.tertiary.withValues(alpha: 0.05);
    } else {
      return colorScheme.surfaceContainerHighest.withValues(alpha: 0.08);
    }
  }

  IconData _getStatusIcon(BlockerStatus status) {
    switch (status) {
      case BlockerStatus.active:
        return Icons.error_outline;
      case BlockerStatus.resolved:
        return Icons.check_circle_outline;
      case BlockerStatus.pending:
        return Icons.schedule;
      case BlockerStatus.escalated:
        return Icons.trending_up;
    }
  }

  Color _getStatusColor(BlockerStatus status, ColorScheme colorScheme) {
    switch (status) {
      case BlockerStatus.active:
        return colorScheme.error;
      case BlockerStatus.resolved:
        return Colors.green;
      case BlockerStatus.pending:
        return colorScheme.tertiary;
      case BlockerStatus.escalated:
        return colorScheme.error;
    }
  }
}