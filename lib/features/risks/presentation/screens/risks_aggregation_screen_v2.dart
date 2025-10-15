import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/services/notification_service.dart';
import '../../../projects/domain/entities/risk.dart';
import '../../../projects/presentation/widgets/risk_detail_panel.dart';
import '../../../projects/presentation/providers/projects_provider.dart';
import '../../../projects/presentation/providers/risks_tasks_provider.dart';
import '../providers/aggregated_risks_provider.dart';
import '../providers/enhanced_risks_provider.dart' hide riskWebSocketProvider, uniqueAssigneesProvider;
import '../providers/risks_filter_provider.dart';
import '../providers/risk_preferences_provider.dart';
import '../widgets/risk_export_dialog.dart';
import '../widgets/risk_assignment_dialog.dart';
import '../widgets/risk_grouping_view.dart';
import '../widgets/risk_list_tile_compact.dart';
import '../widgets/risk_kanban_board_view.dart';
import '../widgets/risk_advanced_filter_dialog.dart';
import '../widgets/risk_sort_dialog.dart';
import '../widgets/risk_group_dialog.dart';
// import '../widgets/date_range_filter.dart'; // Not needed - date range filter is inline

enum GroupingMode { none, project, severity, status, assigned }
enum RiskViewMode { list, compact, kanban }

class RisksAggregationScreenV2 extends ConsumerStatefulWidget {
  final String? projectId;
  final String? fromRoute;

  const RisksAggregationScreenV2({
    super.key,
    this.projectId,
    this.fromRoute,
  });

  @override
  ConsumerState<RisksAggregationScreenV2> createState() => _RisksAggregationScreenV2State();
}

class _RisksAggregationScreenV2State extends ConsumerState<RisksAggregationScreenV2>
    with TickerProviderStateMixin {
  bool _hasLoadedOnce = false;

  // Search and Filter State
  String _searchQuery = '';
  RiskSeverity? _selectedSeverity;
  RiskStatus? _selectedStatus;
  bool _showAIGeneratedOnly = false;
  String? _selectedAssignee;
  DateTimeRange? _selectedDateRange;
  String? _selectedProjectId;

  // Grouping and View State (loaded from providers)
  late GroupingMode _groupingMode;
  late RiskViewMode _viewMode;

  // Sort and Group Dialog State
  RiskSortOption? _selectedSortBy;
  SortOrder _selectedSortOrder = SortOrder.ascending;
  RiskGroupingMode _selectedRiskGrouping = RiskGroupingMode.none;

  // Bulk Selection State
  bool _isSelectionMode = false;
  final Set<String> _selectedRiskIds = {};

  // Controllers
  final ScrollController _scrollController = ScrollController();
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;


  @override
  void initState() {
    super.initState();
    _hasLoadedOnce = false;

    // Load persisted preferences
    _loadPersistedPreferences();

    _selectedProjectId = widget.projectId ?? ref.read(riskSelectedProjectProvider);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();

    _tabController = TabController(
      length: 5, // All, Identified, Mitigating, Escalated, Resolved
      vsync: this,
    );
    _tabController.addListener(() {
      setState(() {}); // Update UI when tab changes
    });

    // Subscribe to real-time updates
    _subscribeToRealTimeUpdates();

    // Check for stale data in the next frame
    WidgetsBinding.instance.addPostFrameCallback((_) {

      // Check if projects are still loading
      final projectsAsync = ref.read(projectsListProvider);

      final initialRisks = ref.read(aggregatedRisksProvider);

      // If we have stale empty data AND projects haven't loaded yet, force a refresh
      if (!initialRisks.isLoading && !initialRisks.hasError && (initialRisks.value?.isEmpty ?? true) && projectsAsync.isLoading) {
        ref.invalidate(aggregatedRisksProvider);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(RisksAggregationScreenV2 oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _animationController.dispose();
    _tabController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _loadPersistedPreferences() {
    // Load persisted view mode and grouping mode
    _viewMode = ref.read(riskViewModeProvider);
    _groupingMode = ref.read(riskGroupingModeProvider);

    // Load persisted filter settings from provider
    final filter = ref.read(risksFilterProvider);
    _selectedSeverity = filter.severity;
    _selectedStatus = filter.status;
    _selectedAssignee = filter.assignee;
    _showAIGeneratedOnly = filter.showAIGeneratedOnly;
    _selectedSortBy = _mapRiskSortByToOption(filter.sortBy);
    _selectedSortOrder = filter.sortAscending ? SortOrder.ascending : SortOrder.descending;
    _selectedDateRange = filter.startDate != null && filter.endDate != null
        ? DateTimeRange(start: filter.startDate!, end: filter.endDate!)
        : null;

    // Map grouping mode to risk grouping mode
    _selectedRiskGrouping = _mapGroupingModeToRiskGrouping(_groupingMode);
  }

  RiskSortOption? _mapRiskSortByToOption(RiskSortBy sortBy) {
    switch (sortBy) {
      case RiskSortBy.severity:
        return RiskSortOption.severity;
      case RiskSortBy.date:
        return RiskSortOption.dateIdentified;
      case RiskSortBy.project:
        return RiskSortOption.project;
      case RiskSortBy.assignee:
        return RiskSortOption.assignee;
      case RiskSortBy.status:
        return RiskSortOption.status;
    }
  }

  RiskSortBy _mapSortOptionToRiskSortBy(RiskSortOption option) {
    switch (option) {
      case RiskSortOption.severity:
        return RiskSortBy.severity;
      case RiskSortOption.dateIdentified:
      case RiskSortOption.dateResolved:
        return RiskSortBy.date;
      case RiskSortOption.project:
        return RiskSortBy.project;
      case RiskSortOption.assignee:
        return RiskSortBy.assignee;
      case RiskSortOption.status:
        return RiskSortBy.status;
    }
  }

  RiskGroupingMode _mapGroupingModeToRiskGrouping(GroupingMode mode) {
    switch (mode) {
      case GroupingMode.none:
        return RiskGroupingMode.none;
      case GroupingMode.project:
        return RiskGroupingMode.project;
      case GroupingMode.severity:
        return RiskGroupingMode.severity;
      case GroupingMode.status:
        return RiskGroupingMode.status;
      case GroupingMode.assigned:
        return RiskGroupingMode.assigned;
    }
  }

  void _subscribeToRealTimeUpdates() {
    // Subscribe to WebSocket updates for risks
    Future.microtask(() {
      ref.read(riskWebSocketProvider.notifier).connect();
    });
  }

  @override
  Widget build(BuildContext context) {

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1200;
    final isTablet = screenWidth >= 768 && screenWidth < 1200;
    final isMobile = screenWidth < 768;

    final risksAsync = ref.watch(aggregatedRisksProvider);

    final filteredRisks = _applyAllFilters(risksAsync.value ?? []);

    final statistics = ref.watch(enhancedRiskStatisticsProvider);

    // Listen for filter changes to sync local state
    ref.listen(risksFilterProvider, (previous, next) {
      // Only update local state if it's different from the provider
      if (mounted && previous != next) {
        setState(() {
          _selectedSeverity = next.severity;
          _selectedStatus = next.status;
          _selectedAssignee = next.assignee;
          _showAIGeneratedOnly = next.showAIGeneratedOnly;
          _selectedSortBy = _mapRiskSortByToOption(next.sortBy);
          _selectedSortOrder = next.sortAscending ? SortOrder.ascending : SortOrder.descending;
          _selectedDateRange = next.startDate != null && next.endDate != null
              ? DateTimeRange(start: next.startDate!, end: next.endDate!)
              : null;
        });
      }
    });

    // Group risks by status
    final allRisks = filteredRisks;
    final identifiedRisks = filteredRisks.where((r) => r.risk.status == RiskStatus.identified).toList();
    final mitigatingRisks = filteredRisks.where((r) => r.risk.status == RiskStatus.mitigating).toList();
    final escalatedRisks = filteredRisks.where((r) => r.risk.status == RiskStatus.escalated).toList();
    final resolvedRisks = filteredRisks.where((r) => r.risk.status == RiskStatus.resolved).toList();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateRiskDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('New Risk'),
        backgroundColor: colorScheme.error,
      ),
      body: risksAsync.when(
          loading: () {
            return const Center(child: CircularProgressIndicator());
          },
          error: (error, stack) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                  const SizedBox(height: 16),
                  Text('Failed to load risks', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      ref.invalidate(aggregatedRisksProvider);
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          },
          data: (risksData) {

            // If we have empty data but haven't loaded once, and projects are still loading, keep showing spinner
            if (!_hasLoadedOnce && risksData.isEmpty) {
              final projectsAsync = ref.watch(projectsListProvider);
              if (projectsAsync.isLoading || !projectsAsync.hasValue) {
                return const Center(child: CircularProgressIndicator());
              }
            }

            // Mark that we've loaded real data
            if (risksData.isNotEmpty && !_hasLoadedOnce) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                setState(() {
                  _hasLoadedOnce = true;
                });
              });
            }

            return Column(
              children: [
                // Compact App Bar
                _buildCompactAppBar(context, theme, isDesktop, isMobile),

                // Filter and View Controls
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 24 : 16,
                  ),
                  color: colorScheme.surface,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1400),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Column(
                          children: [
                            // Search and Controls Row
                            _buildSearchAndControls(theme, isDesktop, isMobile),

                            // Status Filter Tabs
                            if (_groupingMode == GroupingMode.none) ...[
                              const SizedBox(height: 12),
                              _buildStatusTabs(theme, colorScheme, isMobile, allRisks, identifiedRisks, mitigatingRisks, escalatedRisks, resolvedRisks),
                            ],

                            // Quick Filters
                            if (_hasActiveFilters() || (statistics['critical'] ?? 0) > 0) ...[
                              const SizedBox(height: 8),
                              _buildQuickFilters(theme, colorScheme, statistics),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Content
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: _groupingMode != GroupingMode.none ? 0 : (isDesktop ? 24 : 16),
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1400),
                        child: _groupingMode == GroupingMode.none
                            ? TabBarView(
                                controller: _tabController,
                                physics: const NeverScrollableScrollPhysics(), // Disable swipe
                                children: [
                                  _buildRisksView(allRisks, theme, isDesktop, isTablet),
                                  _buildRisksView(identifiedRisks, theme, isDesktop, isTablet),
                                  _buildRisksView(mitigatingRisks, theme, isDesktop, isTablet),
                                  _buildRisksView(escalatedRisks, theme, isDesktop, isTablet),
                                  _buildRisksView(resolvedRisks, theme, isDesktop, isTablet),
                                ],
                              )
                            : _buildGroupedRisks(theme, isDesktop),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
      ),
    );
  }

  Widget _buildCompactAppBar(BuildContext context, ThemeData theme, bool isDesktop, bool isMobile) {
    final colorScheme = theme.colorScheme;
    final statistics = ref.watch(enhancedRiskStatisticsProvider);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.error.withValues(alpha: 0.02),
            colorScheme.secondary.withValues(alpha: 0.01),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 24 : 16,
            vertical: isMobile ? 12 : 16,
          ),
          child: !isMobile
                  ? Center(
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Row(
                          children: [
                            // Back button if coming from project
                            if (widget.fromRoute == 'project') ...[
                              IconButton(
                                icon: const Icon(Icons.arrow_back),
                                onPressed: () => context.pop(),
                                tooltip: 'Back to Project',
                              ),
                              const SizedBox(width: 8),
                            ],
                            // Title Section
                            Icon(
                              Icons.warning_amber_outlined,
                              color: colorScheme.error,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Risks',
                                      style: theme.textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (_hasActiveFilters()) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: colorScheme.error.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          '${_countActiveFilters()} filters',
                                          style: theme.textTheme.labelSmall?.copyWith(
                                            color: colorScheme.error,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                Text(
                                  'Manage across all projects',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 32),

                            // Clean Statistics Section
                            Expanded(
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 24),
                                child: Row(
                                  children: [
                                    _buildSimpleStatCard(
                                      value: statistics['total']?.toString() ?? '0',
                                      label: 'Total risks',
                                      theme: theme,
                                    ),
                                    Container(
                                      height: 30,
                                      width: 1,
                                      color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                                    ),
                                    _buildSimpleStatCard(
                                      value: statistics['active']?.toString() ?? '0',
                                      label: 'Active',
                                      theme: theme,
                                    ),
                                    if ((statistics['critical'] ?? 0) > 0) ...[
                                      Container(
                                        height: 30,
                                        width: 1,
                                        color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              statistics['critical'].toString(),
                                              style: theme.textTheme.headlineMedium?.copyWith(
                                                fontWeight: FontWeight.w600,
                                                color: Colors.red,
                                                fontSize: 24,
                                                height: 1.1,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Critical',
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                                                fontSize: 11,
                                                fontWeight: FontWeight.w400,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    Container(
                                      height: 30,
                                      width: 1,
                                      color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                                    ),
                                    _buildSimpleStatCard(
                                      value: statistics['resolved']?.toString() ?? '0',
                                      label: 'Resolved',
                                      theme: theme,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),

                            // Action Buttons
                            if (_selectedRiskIds.isNotEmpty) ...[
                              PopupMenuButton<String>(
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: colorScheme.secondary,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.checklist, color: Colors.white, size: 20),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${_selectedRiskIds.length}',
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ),
                                onSelected: (action) => _handleBulkAction(action),
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'resolve',
                                    child: ListTile(
                                      leading: Icon(Icons.check_circle, color: Colors.green),
                                      title: Text('Mark Resolved'),
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'critical',
                                    child: ListTile(
                                      leading: Icon(Icons.flag, color: Colors.red),
                                      title: Text('Set Critical'),
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'assign',
                                    child: ListTile(
                                      leading: Icon(Icons.person_add, color: Colors.blue),
                                      title: Text('Assign'),
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: ListTile(
                                      leading: Icon(Icons.delete, color: Colors.red),
                                      title: Text('Delete'),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 8),
                            ],
                          ],
                        ),
                      ),
                    )
                  : Row(
                      children: [
                        // Back button if coming from project
                        if (widget.fromRoute == 'project') ...[
                          IconButton(
                            icon: const Icon(Icons.arrow_back, size: 20),
                            onPressed: () => context.pop(),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: 'Back to Project',
                          ),
                          const SizedBox(width: 8),
                        ],
                        Icon(
                          Icons.warning_amber_outlined,
                          color: colorScheme.error,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Risks',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              'All projects',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        // Compact stats inline
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.warning_amber, size: 14, color: Colors.orange),
                              const SizedBox(width: 4),
                              Text(statistics['total']?.toString() ?? '0', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
                              Icon(Icons.trending_up, size: 14, color: Colors.blue),
                              const SizedBox(width: 4),
                              Text(statistics['active']?.toString() ?? '0', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
                              Icon(Icons.check_circle, size: 14, color: Colors.green),
                              const SizedBox(width: 4),
                              Text(statistics['resolved']?.toString() ?? '0', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }

  Widget _buildSearchAndControls(ThemeData theme, bool isDesktop, bool isMobile) {
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        // Search Field
        Expanded(
          child: ValueListenableBuilder<TextEditingValue>(
            valueListenable: _searchController,
            builder: (context, value, child) {
              return TextField(
                controller: _searchController,
                onChanged: (value) {
                  _debounceTimer?.cancel();
                  _debounceTimer = Timer(const Duration(milliseconds: 300), () {
                    if (mounted) {
                      setState(() {
                        _searchQuery = value;
                      });
                    }
                  });
                },
                style: theme.textTheme.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Search risks...',
                  hintStyle: TextStyle(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                  suffixIcon: value.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear,
                            size: 18,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            _debounceTimer?.cancel();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: colorScheme.outline.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: colorScheme.outline.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: colorScheme.error.withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 8),

        // Filter Button
        IconButton(
          onPressed: _showAdvancedFilterDialog,
          icon: Badge(
            isLabelVisible: _hasActiveFilters(),
            label: Text(_countActiveFilters().toString()),
            child: Icon(
              Icons.filter_list,
              color: _hasActiveFilters()
                  ? colorScheme.error
                  : colorScheme.onSurfaceVariant,
              size: 22,
            ),
          ),
          tooltip: 'Filters',
          style: IconButton.styleFrom(
            backgroundColor: _hasActiveFilters()
                ? colorScheme.error.withValues(alpha: 0.1)
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          ),
        ),

        // Sort Button
        const SizedBox(width: 4),
        IconButton(
          onPressed: _showSortDialog,
          icon: Icon(
            Icons.sort,
            color: colorScheme.onSurfaceVariant,
            size: 22,
          ),
          tooltip: 'Sort',
          style: IconButton.styleFrom(
            backgroundColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          ),
        ),

        // Group Button
        const SizedBox(width: 4),
        IconButton(
          onPressed: _showGroupDialog,
          icon: Icon(
            Icons.workspaces_outline,
            color: _groupingMode != GroupingMode.none
                ? colorScheme.error
                : colorScheme.onSurfaceVariant,
            size: 22,
          ),
          tooltip: 'Group',
          style: IconButton.styleFrom(
            backgroundColor: _groupingMode != GroupingMode.none
                ? colorScheme.error.withValues(alpha: 0.1)
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          ),
        ),

        // View Mode Toggle - Hidden on mobile, shown on tablet/desktop
        if (!isMobile) ...[
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            padding: const EdgeInsets.all(2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildViewModeButton(
                  icon: Icons.view_list,
                  mode: RiskViewMode.list,
                  currentMode: _viewMode,
                  tooltip: 'List',
                  onTap: () {
                    setState(() {
                      _viewMode = RiskViewMode.list;
                    });
                    // Persist the change
                    ref.read(riskViewModeProvider.notifier).state = RiskViewMode.list;
                  },
                ),
                _buildViewModeButton(
                  icon: Icons.view_compact,
                  mode: RiskViewMode.compact,
                  currentMode: _viewMode,
                  tooltip: 'Compact',
                  onTap: () {
                    setState(() {
                      _viewMode = RiskViewMode.compact;
                    });
                    // Persist the change
                    ref.read(riskViewModeProvider.notifier).state = RiskViewMode.compact;
                  },
                ),
                _buildViewModeButton(
                  icon: Icons.view_kanban,
                  mode: RiskViewMode.kanban,
                  currentMode: _viewMode,
                  tooltip: 'Kanban',
                  onTap: () {
                    setState(() {
                      _viewMode = RiskViewMode.kanban;
                    });
                    // Persist the change
                    ref.read(riskViewModeProvider.notifier).state = RiskViewMode.kanban;
                  },
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildViewModeButton({
    required IconData icon,
    required RiskViewMode mode,
    required RiskViewMode currentMode,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isSelected = mode == currentMode;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.error.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isSelected
                ? theme.colorScheme.error
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusTabs(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isMobile,
    List<AggregatedRisk> allRisks,
    List<AggregatedRisk> identifiedRisks,
    List<AggregatedRisk> mitigatingRisks,
    List<AggregatedRisk> escalatedRisks,
    List<AggregatedRisk> resolvedRisks,
  ) {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          _buildStatusTab(
            label: 'All',
            count: allRisks.length,
            isSelected: _tabController.index == 0,
            onTap: () => _tabController.animateTo(0),
            colorScheme: colorScheme,
          ),
          _buildStatusTab(
            label: 'Identified',
            count: identifiedRisks.length,
            isSelected: _tabController.index == 1,
            onTap: () => _tabController.animateTo(1),
            colorScheme: colorScheme,
          ),
          _buildStatusTab(
            label: 'Mitigating',
            count: mitigatingRisks.length,
            isSelected: _tabController.index == 2,
            onTap: () => _tabController.animateTo(2),
            colorScheme: colorScheme,
            color: Colors.blue,
          ),
          if (!isMobile) ...[
            _buildStatusTab(
              label: 'Escalated',
              count: escalatedRisks.length,
              isSelected: _tabController.index == 3,
              onTap: () => _tabController.animateTo(3),
              colorScheme: colorScheme,
              color: Colors.deepPurple,
            ),
            _buildStatusTab(
              label: 'Resolved',
              count: resolvedRisks.length,
              isSelected: _tabController.index == 4,
              onTap: () => _tabController.animateTo(4),
              colorScheme: colorScheme,
              color: Colors.green,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusTab({
    required String label,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
    Color? color,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.surface
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: colorScheme.shadow.withValues(alpha: 0.05),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (color != null && count > 0)
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? colorScheme.onSurface
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '($count)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isSelected
                        ? colorScheme.error
                        : colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickFilters(ThemeData theme, ColorScheme colorScheme, Map<String, dynamic> statistics) {
    return SizedBox(
      height: 32,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          if ((statistics['critical'] ?? 0) > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text('Critical (${statistics['critical']})',
                  style: const TextStyle(fontSize: 12),
                ),
                selected: _selectedSeverity == RiskSeverity.critical,
                onSelected: (_) {
                  setState(() {
                    _selectedSeverity = _selectedSeverity == RiskSeverity.critical ? null : RiskSeverity.critical;
                  });
                  // Persist the change
                  ref.read(risksFilterProvider.notifier).setSeverity(_selectedSeverity);
                },
                selectedColor: Colors.red.withValues(alpha: 0.2),
                checkmarkColor: Colors.red,
                labelStyle: TextStyle(
                  color: _selectedSeverity == RiskSeverity.critical ? Colors.red : null,
                ),
                side: BorderSide(
                  color: _selectedSeverity == RiskSeverity.critical
                      ? Colors.red.withValues(alpha: 0.5)
                      : colorScheme.outline.withValues(alpha: 0.3),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          if (_showAIGeneratedOnly)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: const Text('AI Identified', style: TextStyle(fontSize: 12)),
                selected: true,
                onSelected: (_) {
                  setState(() {
                    _showAIGeneratedOnly = false;
                  });
                  // Persist the change
                  ref.read(risksFilterProvider.notifier).toggleAIGeneratedOnly();
                },
                selectedColor: Colors.purple.withValues(alpha: 0.2),
                checkmarkColor: Colors.purple,
                labelStyle: const TextStyle(color: Colors.purple),
                side: BorderSide(
                  color: Colors.purple.withValues(alpha: 0.5),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          if (_hasActiveFilters()) ...[
            const SizedBox(width: 8),
            ActionChip(
              label: const Text('Clear filters', style: TextStyle(fontSize: 12)),
              onPressed: () {
                _clearAllFilters();
                _searchController.clear();
              },
              avatar: Icon(Icons.clear, size: 14, color: colorScheme.onSurfaceVariant),
              backgroundColor: colorScheme.surface,
              side: BorderSide(
                color: colorScheme.outline.withValues(alpha: 0.3),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSimpleStatCard({
    required String value,
    required String label,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
              fontSize: 24,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              fontSize: 11,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileStatBadge({
    required String label,
    required String value,
    required Color? color,
    required ThemeData theme,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: color ?? theme.colorScheme.onSurface,
            fontSize: 16,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label.toLowerCase(),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            fontSize: 11,
          ),
        ),
      ],
    );
  }


  Widget _buildEnhancedFilters(ThemeData theme, bool isDesktop) {
    final colorScheme = theme.colorScheme;
    final assignees = ref.watch(uniqueAssigneesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search Bar
        TextField(
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
          decoration: InputDecoration(
            hintText: 'Search risks by title, description, project, or assignee...',
            hintStyle: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            prefixIcon: Icon(
              Icons.search,
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                  )
                : null,
            filled: true,
            fillColor: colorScheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: colorScheme.outline.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: colorScheme.outline.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: colorScheme.error.withValues(alpha: 0.5),
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Filter Chips Row 1: Severity and Status
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // Severity Filters
            ...RiskSeverity.values.map((severity) {
              final isSelected = _selectedSeverity == severity;
              return FilterChip(
                label: Text(_getSeverityLabel(severity)),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedSeverity = selected ? severity : null;
                  });
                  // Persist the change
                  ref.read(risksFilterProvider.notifier).setSeverity(_selectedSeverity);
                },
                avatar: CircleAvatar(
                  backgroundColor: _getSeverityColor(severity),
                  radius: 6,
                ),
                backgroundColor: colorScheme.surface,
                selectedColor: _getSeverityColor(severity).withValues(alpha: 0.15),
                checkmarkColor: _getSeverityColor(severity),
                side: BorderSide(
                  color: isSelected
                      ? _getSeverityColor(severity)
                      : colorScheme.outline.withValues(alpha: 0.2),
                ),
              );
            }),

            const SizedBox(width: 16),

            // Status Filter
            PopupMenuButton<RiskStatus?>(
              child: Chip(
                label: Text(_selectedStatus != null
                    ? _getStatusLabel(_selectedStatus!)
                    : 'All Statuses'),
                avatar: Icon(
                  Icons.filter_list,
                  size: 18,
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                backgroundColor: _selectedStatus != null
                    ? _getStatusColor(_selectedStatus!).withValues(alpha: 0.15)
                    : colorScheme.surface,
                side: BorderSide(
                  color: _selectedStatus != null
                      ? _getStatusColor(_selectedStatus!)
                      : colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              onSelected: (status) {
                setState(() {
                  _selectedStatus = status;
                });
                // Persist the change
                ref.read(risksFilterProvider.notifier).setStatus(status);
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: null,
                  child: Text('All Statuses'),
                ),
                ...RiskStatus.values.map((status) => PopupMenuItem(
                      value: status,
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: _getStatusColor(status),
                            radius: 6,
                          ),
                          const SizedBox(width: 8),
                          Text(_getStatusLabel(status)),
                        ],
                      ),
                    )),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Filter Chips Row 2: Date Range, Assignee, AI
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // Date Range Filter
            ActionChip(
              label: Text(_selectedDateRange != null
                  ? '${DateFormat('MMM d').format(_selectedDateRange!.start)} - ${DateFormat('MMM d').format(_selectedDateRange!.end)}'
                  : 'Date Range'),
              avatar: const Icon(Icons.date_range, size: 18),
              onPressed: () => _selectDateRange(context),
              backgroundColor: _selectedDateRange != null
                  ? colorScheme.primary.withValues(alpha: 0.15)
                  : colorScheme.surface,
              side: BorderSide(
                color: _selectedDateRange != null
                    ? colorScheme.primary
                    : colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),

            // Assignee Filter
            if (assignees.isNotEmpty)
              PopupMenuButton<String?>(
                child: Chip(
                  label: Text(_selectedAssignee ?? 'All Assignees'),
                  avatar: Icon(
                    Icons.person,
                    size: 18,
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  backgroundColor: _selectedAssignee != null
                      ? colorScheme.tertiary.withValues(alpha: 0.15)
                      : colorScheme.surface,
                  side: BorderSide(
                    color: _selectedAssignee != null
                        ? colorScheme.tertiary
                        : colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                onSelected: (assignee) {
                  setState(() {
                    _selectedAssignee = assignee;
                  });
                  // Persist the change
                  ref.read(risksFilterProvider.notifier).setAssignee(assignee);
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: null,
                    child: Text('All Assignees'),
                  ),
                  ...assignees.map((assignee) => PopupMenuItem(
                        value: assignee,
                        child: Text(assignee),
                      )),
                ],
              ),

            // AI Generated Filter
            FilterChip(
              label: const Text('AI Identified'),
              selected: _showAIGeneratedOnly,
              onSelected: (selected) {
                setState(() {
                  _showAIGeneratedOnly = selected;
                });
                // Persist the change
                if (selected != ref.read(risksFilterProvider).showAIGeneratedOnly) {
                  ref.read(risksFilterProvider.notifier).toggleAIGeneratedOnly();
                }
              },
              avatar: Icon(
                Icons.auto_awesome,
                size: 18,
                color: _showAIGeneratedOnly
                    ? Colors.purple
                    : colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              backgroundColor: colorScheme.surface,
              selectedColor: Colors.purple.withValues(alpha: 0.15),
              checkmarkColor: Colors.purple,
              side: BorderSide(
                color: _showAIGeneratedOnly
                    ? Colors.purple
                    : colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),

            // Clear All Filters
            if (_hasActiveFilters())
              ActionChip(
                label: const Text('Clear Filters'),
                avatar: const Icon(Icons.clear, size: 18),
                onPressed: _clearAllFilters,
                backgroundColor: Colors.red.withValues(alpha: 0.1),
                side: BorderSide(
                  color: Colors.red.withValues(alpha: 0.3),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildBulkActionsBar(ThemeData theme) {
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Text(
            '${_selectedRiskIds.length} selected',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: colorScheme.primary,
            ),
          ),
          const Spacer(),

          // Bulk Update Status
          TextButton.icon(
            onPressed: _selectedRiskIds.isEmpty ? null : () => _showBulkStatusUpdate(),
            icon: const Icon(Icons.flag, size: 18),
            label: const Text('Update Status'),
          ),

          // Bulk Assign
          TextButton.icon(
            onPressed: _selectedRiskIds.isEmpty ? null : () => _showBulkAssignment(),
            icon: const Icon(Icons.person_add, size: 18),
            label: const Text('Assign'),
          ),

          // Bulk Export
          TextButton.icon(
            onPressed: _selectedRiskIds.isEmpty ? null : () => _exportSelectedRisks(),
            icon: const Icon(Icons.download, size: 18),
            label: const Text('Export'),
          ),

          // Cancel Selection
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              setState(() {
                _isSelectionMode = false;
                _selectedRiskIds.clear();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRisksView(
    List<AggregatedRisk> risks,
    ThemeData theme,
    bool isDesktop,
    bool isTablet,
  ) {

    if (risks.isEmpty) {
      // Check if there are any projects
      final projectsAsync = ref.watch(projectsListProvider);
      final hasProjects = projectsAsync.whenOrNull(
        data: (projects) => projects.isNotEmpty,
      ) ?? false;

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No risks found',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasProjects
                  ? 'Upload meeting transcripts or emails to identify project risks'
                  : 'Create your first project and upload content to identify risks',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                context.go('/hierarchy');
              },
              icon: const Icon(Icons.folder),
              label: Text(hasProjects ? 'Go to Projects' : 'Create First Project'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    // Wrap with RefreshIndicator for pull-to-refresh
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(aggregatedRisksProvider);
        await ref.read(aggregatedRisksProvider.future);
      },
      child: _viewMode == RiskViewMode.kanban
          ? _buildKanbanView(risks, theme, isDesktop)
          : _viewMode == RiskViewMode.compact
              ? _buildCompactView(risks, theme, isDesktop)
              : _buildListView(risks, theme, isDesktop),
    );
  }

  Widget _buildListView(
    List<AggregatedRisk> risks,
    ThemeData theme,
    bool isDesktop,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.only(top: 12),
      itemCount: risks.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final aggregatedRisk = risks[index];
        return _buildEnhancedRiskCard(theme, aggregatedRisk, isDesktop);
      },
    );
  }

  Widget _buildGridView(
    List<AggregatedRisk> risks,
    ThemeData theme,
    bool isDesktop,
    bool isTablet,
  ) {
    final crossAxisCount = isDesktop ? 3 : (isTablet ? 2 : 1);

    return GridView.builder(
      padding: const EdgeInsets.only(top: 12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: isDesktop ? 1.2 : (isTablet ? 1.1 : 1.3),
      ),
      itemCount: risks.length,
      itemBuilder: (context, index) {
        final aggregatedRisk = risks[index];
        return _buildGridRiskCard(theme, aggregatedRisk, isDesktop);
      },
    );
  }

  Widget _buildCompactView(
    List<AggregatedRisk> risks,
    ThemeData theme,
    bool isDesktop,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.only(top: 12),
      itemCount: risks.length,
      separatorBuilder: (context, index) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        final aggregatedRisk = risks[index];
        return RiskListTileCompact(
          aggregatedRisk: aggregatedRisk,
          isSelected: _selectedRiskIds.contains(aggregatedRisk.risk.id),
          isSelectionMode: _isSelectionMode,
          onTap: _isSelectionMode
              ? () {
                  setState(() {
                    if (_selectedRiskIds.contains(aggregatedRisk.risk.id)) {
                      _selectedRiskIds.remove(aggregatedRisk.risk.id);
                    } else {
                      _selectedRiskIds.add(aggregatedRisk.risk.id);
                    }
                  });
                }
              : () => _showRiskDetails(context, aggregatedRisk.risk, aggregatedRisk.project.id),
          onLongPress: !_isSelectionMode
              ? () {
                  setState(() {
                    _isSelectionMode = true;
                    _selectedRiskIds.add(aggregatedRisk.risk.id);
                  });
                }
              : null,
          onActionSelected: (action, risk, projectId) => _handleRiskAction(action, risk, projectId),
        );
      },
    );
  }

  Widget _buildKanbanView(
    List<AggregatedRisk> risks,
    ThemeData theme,
    bool isDesktop,
  ) {
    return RiskKanbanBoardView(
      risks: risks,
      onRiskTap: (risk, projectId) => _showRiskDetails(context, risk, projectId),
    );
  }

  Widget _buildGridRiskCard(ThemeData theme, AggregatedRisk aggregatedRisk, bool isDesktop) {
    final colorScheme = theme.colorScheme;
    final risk = aggregatedRisk.risk;
    final project = aggregatedRisk.project;
    final isSelected = _selectedRiskIds.contains(risk.id);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isSelectionMode
            ? () {
                setState(() {
                  if (isSelected) {
                    _selectedRiskIds.remove(risk.id);
                  } else {
                    _selectedRiskIds.add(risk.id);
                  }
                });
              }
            : () => _showRiskDetails(context, risk, project.id),
        onLongPress: !_isSelectionMode
            ? () {
                setState(() {
                  _isSelectionMode = true;
                  _selectedRiskIds.add(risk.id);
                });
              }
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Card(
          elevation: 1,
          color: isSelected
              ? colorScheme.errorContainer.withValues(alpha: 0.2)
              : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected
                  ? colorScheme.error
                  : _getSeverityColor(risk.severity).withValues(alpha: 0.3),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with severity indicator and selection
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _getSeverityColor(risk.severity),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getSeverityLabel(risk.severity),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: _getSeverityColor(risk.severity),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (_isSelectionMode)
                    Checkbox(
                      value: isSelected,
                      onChanged: (value) {
                        setState(() {
                          if (value ?? false) {
                            _selectedRiskIds.add(risk.id);
                          } else {
                            _selectedRiskIds.remove(risk.id);
                          }
                        });
                      },
                    ),
                  if (risk.aiGenerated && !_isSelectionMode)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.purple.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        size: 12,
                        color: Colors.purple,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Title
              Text(
                risk.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Description
              Text(
                risk.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),

              // Footer with project and status
              Row(
                children: [
                  Expanded(
                    child: Text(
                      project.name,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(risk.status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getStatusLabel(risk.status),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _getStatusColor(risk.status),
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGroupedRisks(ThemeData theme, bool isDesktop) {
    final aggregatedRisks = ref.watch(aggregatedRisksProvider);

    return aggregatedRisks.when(
      data: (risks) {
        final filteredRisks = _applyAllFilters(risks);
        return RiskGroupingView(
          risks: filteredRisks,
          groupingMode: _groupingMode,
          onRiskTap: (risk, projectId) => _showRiskDetails(context, risk, projectId),
          isSelectionMode: _isSelectionMode,
          selectedRiskIds: _selectedRiskIds,
          onSelectionChanged: (riskId, selected) {
            setState(() {
              if (selected) {
                _selectedRiskIds.add(riskId);
              } else {
                _selectedRiskIds.remove(riskId);
              }
            });
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(theme, error.toString()),
    );
  }

  Widget _buildEnhancedRiskCard(ThemeData theme, AggregatedRisk aggregatedRisk, bool isDesktop) {
    final colorScheme = theme.colorScheme;
    final risk = aggregatedRisk.risk;
    final project = aggregatedRisk.project;
    final isSelected = _selectedRiskIds.contains(risk.id);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isSelectionMode
            ? () {
                setState(() {
                  if (isSelected) {
                    _selectedRiskIds.remove(risk.id);
                  } else {
                    _selectedRiskIds.add(risk.id);
                  }
                });
              }
            : () => _showRiskDetails(context, risk, project.id),
        onLongPress: !_isSelectionMode
            ? () {
                setState(() {
                  _isSelectionMode = true;
                  _selectedRiskIds.add(risk.id);
                });
              }
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Card(
          elevation: 1,
          color: isSelected
              ? colorScheme.primaryContainer.withValues(alpha: 0.2)
              : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.outline.withValues(alpha: 0.2),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Selection Checkbox
              if (_isSelectionMode) ...[
                Checkbox(
                  value: isSelected,
                  onChanged: (value) {
                    setState(() {
                      if (value ?? false) {
                        _selectedRiskIds.add(risk.id);
                      } else {
                        _selectedRiskIds.remove(risk.id);
                      }
                    });
                  },
                ),
                const SizedBox(width: 12),
              ],

              // Severity Indicator
              Container(
                width: 4,
                height: 80,
                decoration: BoxDecoration(
                  color: _getSeverityColor(risk.severity),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 16),

              // Risk Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title, Project, and Assignee
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  risk.title,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (risk.assignedTo != null) ...[
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.person_outline,
                                  size: 14,
                                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  risk.assignedTo!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.tertiary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        // Badges
                        Row(
                          children: [
                            if (risk.aiGenerated)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                margin: const EdgeInsets.only(left: 8),
                                decoration: BoxDecoration(
                                  color: Colors.purple.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.auto_awesome,
                                      size: 14,
                                      color: Colors.purple,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'AI',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: Colors.purple,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            // Action Menu
                            if (!_isSelectionMode)
                              PopupMenuButton<String>(
                                icon: Icon(
                                  Icons.more_vert,
                                  size: 20,
                                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                                ),
                                onSelected: (action) => _handleRiskAction(action, risk, project.id),
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: ListTile(
                                      leading: Icon(Icons.edit, size: 20),
                                      title: Text('Edit'),
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'assign',
                                    child: ListTile(
                                      leading: Icon(Icons.person_add, size: 20),
                                      title: Text('Assign'),
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'status',
                                    child: ListTile(
                                      leading: Icon(Icons.flag, size: 20),
                                      title: Text('Update Status'),
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                  const PopupMenuDivider(),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: ListTile(
                                      leading: Icon(Icons.delete, size: 20, color: Colors.red),
                                      title: Text('Delete', style: TextStyle(color: Colors.red)),
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ),
                    // Description
                    Text(
                      risk.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Status Chips and Metadata
                    Row(
                      children: [
                        // Project chip
                        _StatusChip(
                          label: project.name,
                          color: colorScheme.primary.withValues(alpha: 0.8),
                          icon: Icons.folder_outlined,
                        ),
                        const SizedBox(width: 8),
                        _StatusChip(
                          label: risk.severityLabel,
                          color: _getSeverityColor(risk.severity),
                        ),
                        const SizedBox(width: 8),
                        _StatusChip(
                          label: risk.statusLabel,
                          color: _getStatusColor(risk.status),
                        ),
                        if (risk.probability != null) ...[
                          const SizedBox(width: 8),
                          _StatusChip(
                            label: 'Probability: ${(risk.probability! * 100).toStringAsFixed(0)}%',
                            color: colorScheme.tertiary,
                          ),
                        ],
                        const Spacer(),
                        if (risk.identifiedDate != null)
                          Text(
                            _formatDate(risk.identifiedDate!),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAdvancedFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => RiskAdvancedFilterDialog(
        selectedSeverity: _selectedSeverity,
        selectedStatus: _selectedStatus,
        showAIGeneratedOnly: _showAIGeneratedOnly,
        selectedAssignee: _selectedAssignee,
        selectedDateRange: _selectedDateRange,
        selectedProjectId: _selectedProjectId,
        onFiltersChanged: ({
          RiskSeverity? severity,
          RiskStatus? status,
          bool? aiGeneratedOnly,
          String? assignee,
          DateTimeRange? dateRange,
          String? projectId,
        }) {
          // Only update if values have actually changed
          final filterNotifier = ref.read(risksFilterProvider.notifier);
          final currentFilter = ref.read(risksFilterProvider);

          setState(() {
            _selectedSeverity = severity;
            _selectedStatus = status;
            _showAIGeneratedOnly = aiGeneratedOnly ?? false;
            _selectedAssignee = assignee;
            _selectedDateRange = dateRange;
            _selectedProjectId = projectId;
          });

          // Only persist changes that are different from current values
          if (severity != currentFilter.severity) {
            filterNotifier.setSeverity(severity);
          }
          if (status != currentFilter.status) {
            filterNotifier.setStatus(status);
          }
          if (assignee != currentFilter.assignee) {
            filterNotifier.setAssignee(assignee);
          }
          if ((aiGeneratedOnly ?? false) != currentFilter.showAIGeneratedOnly) {
            filterNotifier.toggleAIGeneratedOnly();
          }
          if (dateRange?.start != currentFilter.startDate || dateRange?.end != currentFilter.endDate) {
            filterNotifier.setDateRange(dateRange?.start, dateRange?.end);
          }
          // Persist project selection if changed
          if (projectId != ref.read(riskSelectedProjectProvider)) {
            ref.read(riskSelectedProjectProvider.notifier).state = projectId;
          }
        },
      ),
    );
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) => RiskSortDialog(
        currentSortBy: _selectedSortBy,
        currentSortOrder: _selectedSortOrder,
        onSortChanged: (sortBy, sortOrder) {
          setState(() {
            _selectedSortBy = sortBy;
            _selectedSortOrder = sortOrder;
          });
          // Persist the changes
          if (sortBy != null) {
            final filterNotifier = ref.read(risksFilterProvider.notifier);
            // Convert RiskSortOption to RiskSortBy
            final riskSortBy = _mapSortOptionToRiskSortBy(sortBy);
            filterNotifier.setSortBy(riskSortBy);
            if ((sortOrder == SortOrder.ascending) != ref.read(risksFilterProvider).sortAscending) {
              filterNotifier.toggleSortDirection();
            }
          }
        },
      ),
    );
  }

  void _showGroupDialog() {
    showDialog(
      context: context,
      builder: (context) => RiskGroupDialog(
        currentGrouping: _selectedRiskGrouping,
        onGroupingChanged: (grouping) {
          setState(() {
            _selectedRiskGrouping = grouping;
            // Convert RiskGroupingMode to GroupingMode for backward compatibility
            _groupingMode = _convertToGroupingMode(grouping);
          });
          // Persist the change
          ref.read(riskGroupingModeProvider.notifier).state = _groupingMode;
        },
      ),
    );
  }

  GroupingMode _convertToGroupingMode(RiskGroupingMode riskGrouping) {
    switch (riskGrouping) {
      case RiskGroupingMode.none:
        return GroupingMode.none;
      case RiskGroupingMode.project:
        return GroupingMode.project;
      case RiskGroupingMode.severity:
        return GroupingMode.severity;
      case RiskGroupingMode.status:
        return GroupingMode.status;
      case RiskGroupingMode.assigned:
        return GroupingMode.assigned;
    }
  }

  void _showExportDialog(List<AggregatedRisk> risks) {
    showDialog(
      context: context,
      builder: (context) => RiskExportDialog(
        format: 'csv',
        onExport: () => _exportRisksToCSV(risks),
      ),
    );
  }

  void _handleBulkAction(String action) {
    switch (action) {
      case 'resolve':
        _showBulkStatusUpdate();
        break;
      case 'critical':
        // Handle bulk set critical
        break;
      case 'assign':
        _showBulkAssignment();
        break;
      case 'delete':
        // Handle bulk delete
        break;
    }
  }

  Widget _buildEmptyState(ThemeData theme) {
    final colorScheme = theme.colorScheme;

    // Check if there are any projects
    final projectsAsync = ref.watch(projectsListProvider);
    final hasProjects = projectsAsync.whenOrNull(
      data: (projects) => projects.isNotEmpty,
    ) ?? false;

    return Container(
      padding: const EdgeInsets.all(48),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _hasActiveFilters()
                ? Icons.search_off
                : Icons.check_circle_outline,
            size: 64,
            color: _hasActiveFilters()
                ? colorScheme.onSurfaceVariant.withValues(alpha: 0.3)
                : Colors.green.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No risks found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _hasActiveFilters()
                ? 'Try adjusting your search or filters'
                : hasProjects
                    ? 'Upload meeting transcripts or emails to identify project risks'
                    : 'Create your first project and upload content to identify risks',
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (_hasActiveFilters()) ...[
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _selectedSeverity = null;
                  _selectedStatus = null;
                  _showAIGeneratedOnly = false;
                  _selectedAssignee = null;
                  _selectedDateRange = null;
                  _searchController.clear();
                });
                // Clear persisted filters
                ref.read(risksFilterProvider.notifier).clearAllFilters();
                ref.read(riskSelectedProjectProvider.notifier).state = null;
              },
              icon: const Icon(Icons.clear),
              label: const Text('Clear Filters'),
            ),
          ] else ...[
            ElevatedButton.icon(
              onPressed: () {
                context.go('/hierarchy');
              },
              icon: const Icon(Icons.folder),
              label: Text(hasProjects ? 'Go to Projects' : 'Create First Project'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, String error) {
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load risks',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => ref.refresh(aggregatedRisksProvider),
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // Helper Methods
  List<AggregatedRisk> _applyAllFilters(List<AggregatedRisk> risks) {
    var filtered = risks;

    // Search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((ar) {
        return ar.risk.title.toLowerCase().contains(query) ||
            ar.risk.description.toLowerCase().contains(query) ||
            ar.project.name.toLowerCase().contains(query) ||
            (ar.risk.assignedTo?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // Severity filter
    if (_selectedSeverity != null) {
      filtered = filtered.where((ar) => ar.risk.severity == _selectedSeverity).toList();
    }

    // Status filter
    if (_selectedStatus != null) {
      filtered = filtered.where((ar) => ar.risk.status == _selectedStatus).toList();
    }

    // AI generated filter
    if (_showAIGeneratedOnly) {
      filtered = filtered.where((ar) => ar.risk.aiGenerated).toList();
    }

    // Assignee filter
    if (_selectedAssignee != null) {
      filtered = filtered.where((ar) => ar.risk.assignedTo == _selectedAssignee).toList();
    }

    // Date range filter
    if (_selectedDateRange != null) {
      filtered = filtered.where((ar) {
        final date = ar.risk.identifiedDate;
        if (date == null) return false;
        return date.isAfter(_selectedDateRange!.start) &&
            date.isBefore(_selectedDateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }

    // Project filter
    if (_selectedProjectId != null) {
      filtered = filtered.where((ar) => ar.project.id == _selectedProjectId).toList();
    }

    // Apply sorting
    if (_selectedSortBy != null) {
      filtered = _applySorting(filtered);
    }

    return filtered;
  }

  List<AggregatedRisk> _applySorting(List<AggregatedRisk> risks) {
    if (_selectedSortBy == null) return risks;

    final sortedList = List<AggregatedRisk>.from(risks);

    sortedList.sort((a, b) {
      int comparison = 0;

      switch (_selectedSortBy!) {
        case RiskSortOption.severity:
          // Critical=3, High=2, Medium=1, Low=0 for proper severity ordering
          final aSeverityValue = _getSeverityValue(a.risk.severity);
          final bSeverityValue = _getSeverityValue(b.risk.severity);
          comparison = aSeverityValue.compareTo(bSeverityValue);
          break;

        case RiskSortOption.dateIdentified:
          final aDate = a.risk.identifiedDate ?? DateTime(1970);
          final bDate = b.risk.identifiedDate ?? DateTime(1970);
          comparison = aDate.compareTo(bDate);
          break;

        case RiskSortOption.dateResolved:
          final aDate = a.risk.resolvedDate ?? DateTime(1970);
          final bDate = b.risk.resolvedDate ?? DateTime(1970);
          comparison = aDate.compareTo(bDate);
          break;

        case RiskSortOption.project:
          comparison = a.project.name.toLowerCase().compareTo(b.project.name.toLowerCase());
          break;

        case RiskSortOption.status:
          // Convert status to int for comparison
          final aStatusValue = _getStatusValue(a.risk.status);
          final bStatusValue = _getStatusValue(b.risk.status);
          comparison = aStatusValue.compareTo(bStatusValue);
          break;

        case RiskSortOption.assignee:
          final aAssignee = a.risk.assignedTo?.toLowerCase() ?? '';
          final bAssignee = b.risk.assignedTo?.toLowerCase() ?? '';
          comparison = aAssignee.compareTo(bAssignee);
          break;
      }

      // Apply sort order (ascending/descending)
      return _selectedSortOrder == SortOrder.ascending ? comparison : -comparison;
    });

    return sortedList;
  }

  int _getSeverityValue(RiskSeverity severity) {
    switch (severity) {
      case RiskSeverity.low:
        return 0;
      case RiskSeverity.medium:
        return 1;
      case RiskSeverity.high:
        return 2;
      case RiskSeverity.critical:
        return 3;
    }
  }

  int _getStatusValue(RiskStatus status) {
    switch (status) {
      case RiskStatus.identified:
        return 0;
      case RiskStatus.mitigating:
        return 1;
      case RiskStatus.escalated:
        return 2;
      case RiskStatus.accepted:
        return 3;
      case RiskStatus.resolved:
        return 4;
    }
  }

  bool _hasActiveFilters() {
    return _searchQuery.isNotEmpty ||
        _selectedSeverity != null ||
        _selectedStatus != null ||
        _showAIGeneratedOnly ||
        _selectedAssignee != null ||
        _selectedDateRange != null ||
        _selectedProjectId != null;
  }

  int _countActiveFilters() {
    int count = 0;
    if (_searchQuery.isNotEmpty) count++;
    if (_selectedSeverity != null) count++;
    if (_selectedStatus != null) count++;
    if (_showAIGeneratedOnly) count++;
    if (_selectedAssignee != null) count++;
    if (_selectedDateRange != null) count++;
    if (_selectedProjectId != null) count++;
    return count;
  }

  void _clearAllFilters() {
    setState(() {
      _searchQuery = '';
      _selectedSeverity = null;
      _selectedStatus = null;
      _showAIGeneratedOnly = false;
      _selectedAssignee = null;
      _selectedDateRange = null;
      _selectedProjectId = null;
    });
    // Clear persisted filters
    ref.read(risksFilterProvider.notifier).clearAllFilters();
    ref.read(riskSelectedProjectProvider.notifier).state = null;
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      initialDateRange: _selectedDateRange,
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  void _showRiskDetails(BuildContext context, Risk risk, String projectId) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      transitionDuration: Duration.zero,
      pageBuilder: (context, animation, secondaryAnimation) {
        return RiskDetailPanel(
          projectId: projectId,
          risk: risk,
        );
      },
    );
  }

  void _showCreateRiskDialog(BuildContext context) {
    // Check if there are any projects first
    final projectsAsync = ref.read(projectsListProvider);
    final hasProjects = projectsAsync.whenOrNull(
      data: (projects) => projects.isNotEmpty,
    ) ?? false;

    if (!hasProjects) {
      ref.read(notificationServiceProvider.notifier).showError(
        'Please create a project first before adding risks',
      );
      return;
    }

    // Get project from widget (if coming from project screen)
    String? projectId = widget.projectId;
    // If no project from widget, let user choose via dropdown (don't auto-select)

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      transitionDuration: Duration.zero,
      pageBuilder: (context, animation, secondaryAnimation) {
        return RiskDetailPanel(
          projectId: projectId,  // Will be null if not from project context
          risk: null,
          initiallyInEditMode: true,
        );
      },
    ).then((_) {
      ref.invalidate(aggregatedRisksProvider);
    });
  }

  void _handleRiskAction(String action, Risk risk, String projectId) {
    switch (action) {
      case 'edit':
        showGeneralDialog(
          context: context,
          barrierDismissible: false,
          barrierColor: Colors.transparent,
          transitionDuration: Duration.zero,
          pageBuilder: (context, animation, secondaryAnimation) {
            return RiskDetailPanel(
              projectId: projectId,
              risk: risk,
              initiallyInEditMode: true,
            );
          },
        ).then((_) {
          ref.invalidate(aggregatedRisksProvider);
        });
        break;
      case 'assign':
        _showAssignmentDialog(risk, projectId);
        break;
      case 'status':
        _showStatusUpdateDialog(risk, projectId);
        break;
      case 'delete':
        _confirmDeleteRisk(risk, projectId);
        break;
    }
  }

  void _showAssignmentDialog(Risk risk, String projectId) {
    showDialog(
      context: context,
      builder: (context) => RiskAssignmentDialog(
        risk: risk,
        projectId: projectId,
        onAssigned: () {
          ref.invalidate(aggregatedRisksProvider);
        },
      ),
    );
  }

  void _showStatusUpdateDialog(Risk risk, String projectId) {
    // Implementation for status update dialog
  }

  void _confirmDeleteRisk(Risk risk, String projectId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Risk'),
        content: Text('Are you sure you want to delete "${risk.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(risksNotifierProvider(projectId).notifier).deleteRisk(risk.id);
              ref.invalidate(aggregatedRisksProvider);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showBulkStatusUpdate() {
    // Implementation for bulk status update
  }

  void _showBulkAssignment() {
    // Implementation for bulk assignment
  }

  void _exportSelectedRisks() {
    final risks = ref.read(aggregatedRisksProvider).value ?? [];
    final selectedRisks = risks.where((r) => _selectedRiskIds.contains(r.risk.id)).toList();
    _exportRisksToCSV(selectedRisks);
  }

  Future<void> _handleExport(String format) async {
    switch (format) {
      case 'csv':
        await _exportToCSV();
        break;
      case 'pdf':
        await _exportToPDF();
        break;
      case 'report':
        await _generateReport();
        break;
    }
  }

  Future<void> _exportToCSV() async {
    final risks = ref.read(aggregatedRisksProvider).value ?? [];
    await _exportRisksToCSV(risks);
  }

  Future<void> _exportRisksToCSV(List<AggregatedRisk> risks) async {
    final List<List<dynamic>> rows = [
      [
        'ID',
        'Title',
        'Description',
        'Project',
        'Severity',
        'Status',
        'Assigned To',
        'Probability',
        'Impact',
        'Mitigation',
        'AI Generated',
        'Identified Date',
        'Resolved Date',
      ],
    ];

    for (final ar in risks) {
      rows.add([
        ar.risk.id,
        ar.risk.title,
        ar.risk.description,
        ar.project.name,
        ar.risk.severityLabel,
        ar.risk.statusLabel,
        ar.risk.assignedTo ?? '',
        ar.risk.probability?.toString() ?? '',
        ar.risk.impact ?? '',
        ar.risk.mitigation ?? '',
        ar.risk.aiGenerated ? 'Yes' : 'No',
        ar.risk.identifiedDate?.toIso8601String() ?? '',
        ar.risk.resolvedDate?.toIso8601String() ?? '',
      ]);
    }

    final csv = const ListToCsvConverter().convert(rows);

    // Save to file
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/risks_export_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(csv);

    // Share file
    await Share.shareXFiles([XFile(file.path)], text: 'Risk Export');
  }

  Future<void> _exportToPDF() async {
    // Implementation for PDF export
    showDialog(
      context: context,
      builder: (context) => RiskExportDialog(
        format: 'pdf',
        onExport: () {
          // PDF export logic
        },
      ),
    );
  }

  Future<void> _generateReport() async {
    // Implementation for report generation
    showDialog(
      context: context,
      builder: (context) => RiskExportDialog(
        format: 'report',
        onExport: () {
          // Report generation logic
        },
      ),
    );
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

  Color _getStatusColor(RiskStatus status) {
    switch (status) {
      case RiskStatus.identified:
        return Colors.grey;
      case RiskStatus.mitigating:
        return Colors.blue;
      case RiskStatus.resolved:
        return Colors.green;
      case RiskStatus.accepted:
        return Colors.teal;
      case RiskStatus.escalated:
        return Colors.deepPurple;
    }
  }

  String _getSeverityLabel(RiskSeverity severity) {
    switch (severity) {
      case RiskSeverity.low:
        return 'Low';
      case RiskSeverity.medium:
        return 'Medium';
      case RiskSeverity.high:
        return 'High';
      case RiskSeverity.critical:
        return 'Critical';
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks week${weeks > 1 ? 's' : ''} ago';
    } else {
      return DateFormat('MMM d, y').format(date);
    }
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const _StatusChip({
    required this.label,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 12,
              color: color,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
