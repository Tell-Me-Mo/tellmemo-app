import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/historical_insights_provider.dart';
import '../widgets/timeline_insight_badge.dart';
import '../widgets/insights_filter_dialog.dart';

/// Screen for displaying historical insights from past sessions
class HistoricalInsightsScreen extends ConsumerStatefulWidget {
  final String projectId;
  final String? projectName;

  const HistoricalInsightsScreen({
    super.key,
    required this.projectId,
    this.projectName,
  });

  @override
  ConsumerState<HistoricalInsightsScreen> createState() =>
      _HistoricalInsightsScreenState();
}

class _HistoricalInsightsScreenState
    extends ConsumerState<HistoricalInsightsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref
          .read(historicalInsightsProvider.notifier)
          .loadProjectInsights(widget.projectId);
    });

    // Setup pagination on scroll
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      // Load more when 80% scrolled
      final state = ref.read(historicalInsightsProvider);
      if (!state.isLoading && state.hasMore) {
        ref
            .read(historicalInsightsProvider.notifier)
            .loadMore(widget.projectId);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(historicalInsightsProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Historical Insights'),
            if (widget.projectName != null)
              Text(
                widget.projectName!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        actions: [
          // Filter button
          IconButton(
            icon: Badge(
              isLabelVisible: state.filterType != null ||
                  state.filterPriority != null ||
                  state.sessionId != null,
              child: const Icon(Icons.filter_list),
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const InsightsFilterDialog(),
              ).then((_) {
                // Reload with new filters
                ref
                    .read(historicalInsightsProvider.notifier)
                    .loadProjectInsights(widget.projectId);
              });
            },
            tooltip: 'Filter Insights',
          ),
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref
                  .read(historicalInsightsProvider.notifier)
                  .loadProjectInsights(widget.projectId);
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(context, state),
    );
  }

  Widget _buildBody(BuildContext context, HistoricalInsightsState state) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Loading state (initial load)
    if (state.isLoading && state.insights.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Error state
    if (state.error != null && state.insights.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load insights',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              state.error!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              onPressed: () {
                ref
                    .read(historicalInsightsProvider.notifier)
                    .loadProjectInsights(widget.projectId);
              },
            ),
          ],
        ),
      );
    }

    // Empty state
    if (state.insights.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.insights_outlined,
              size: 64,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              _getEmptyStateTitle(state),
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _getEmptyStateMessage(state),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (state.filterType != null || state.filterPriority != null) ...[
              const SizedBox(height: 24),
              FilledButton.tonal(
                onPressed: () {
                  ref.read(historicalInsightsProvider.notifier).clearFilters();
                  ref
                      .read(historicalInsightsProvider.notifier)
                      .loadProjectInsights(widget.projectId);
                },
                child: const Text('Clear Filters'),
              ),
            ],
          ],
        ),
      );
    }

    // Success state with data
    return Column(
      children: [
        // Stats bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            border: Border(
              bottom: BorderSide(
                color: colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.insights,
                size: 20,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                '${state.total} insights',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (state.filterType != null || state.filterPriority != null)
                Chip(
                  avatar: const Icon(Icons.filter_list, size: 16),
                  label: Text(
                    'Filtered (${state.insights.length} shown)',
                    style: theme.textTheme.labelSmall,
                  ),
                  backgroundColor: colorScheme.primaryContainer,
                  side: BorderSide.none,
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
        ),

        // Insights list
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: state.insights.length + (state.hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              // Loading indicator at the bottom
              if (index == state.insights.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final insight = state.insights[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TimelineInsightBadge(insight: insight),
              );
            },
          ),
        ),
      ],
    );
  }

  String _getEmptyStateTitle(HistoricalInsightsState state) {
    if (state.filterType != null || state.filterPriority != null) {
      return 'No matching insights';
    }
    return 'No insights yet';
  }

  String _getEmptyStateMessage(HistoricalInsightsState state) {
    if (state.filterType != null || state.filterPriority != null) {
      return 'Try adjusting your filters to see more results';
    }
    return 'Insights from live recording sessions will appear here';
  }
}
