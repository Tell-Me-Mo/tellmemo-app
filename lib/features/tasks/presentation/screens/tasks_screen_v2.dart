import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/breakpoints.dart';
import '../../../../core/constants/layout_constants.dart';
import '../../../../core/services/notification_service.dart';
import '../../../projects/domain/entities/task.dart';
import '../providers/aggregated_tasks_provider.dart';
import '../providers/tasks_filter_provider.dart';
import '../providers/tasks_state_provider.dart';
import '../widgets/kanban_board_view.dart';
import '../widgets/create_task_dialog.dart';
import '../widgets/advanced_filter_dialog.dart';
import '../widgets/task_export_dialog.dart';
import '../widgets/task_sort_dialog.dart';
import '../widgets/task_group_dialog.dart';
import '../widgets/grouped_tasks_view.dart';
import '../../../projects/presentation/providers/projects_provider.dart';

class TasksScreenV2 extends ConsumerStatefulWidget {
  final String? projectId;
  final String? fromRoute;

  const TasksScreenV2({
    super.key,
    this.projectId,
    this.fromRoute,
  });

  @override
  ConsumerState<TasksScreenV2> createState() => _TasksScreenV2State();
}

class _TasksScreenV2State extends ConsumerState<TasksScreenV2>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  Timer? _filterDebounceTimer;
  int _buildCount = 0;

  @override
  void initState() {
    super.initState();
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
      length: 5, // All, To Do, In Progress, Blocked, Completed
      vsync: this,
    );
    _tabController.addListener(() {
      // Tab changes are handled by TabBarView, no setState needed
      print('📑 Tab changed to index: ${_tabController.index}');
    });

    // Initialize project filter if coming from a project
    if (widget.projectId != null) {
      // Set filter immediately (synchronously) for first render
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(tasksFilterProvider.notifier).clearAllFilters();
        ref.read(tasksFilterProvider.notifier).updateProjectIds({widget.projectId!});
      });

      // Also set immediately as backup using microtask
      Future.microtask(() {
        if (mounted) {
          ref.read(tasksFilterProvider.notifier).clearAllFilters();
          ref.read(tasksFilterProvider.notifier).updateProjectIds({widget.projectId!});
        }
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _tabController.dispose();
    _searchController.dispose();
    _filterDebounceTimer?.cancel();
    super.dispose();
  }

  void _showCreateTaskDialog() {
    showDialog(
      context: context,
      builder: (context) => const CreateTaskDialog(),
    );
  }

  void _showFilterDialog() {
    print('🎛️ Opening filter dialog');
    showDialog(
      context: context,
      builder: (context) => AdvancedFilterDialog(
        onFilterUpdate: _updateLocalFilter,
      ),
    );
  }

  void _showSortDialog() {
    print('📊 Opening sort dialog');
    showDialog(
      context: context,
      builder: (context) => const TaskSortDialog(),
    );
  }

  void _showGroupDialog() {
    print('👥 Opening group dialog');
    showDialog(
      context: context,
      builder: (context) => const TaskGroupDialog(),
    );
  }

  void _showExportDialog(List<TaskWithProject> tasks) {
    showDialog(
      context: context,
      builder: (context) => TaskExportDialog(tasks: tasks),
    );
  }

  Future<void> _handleRefresh() async {
    final refresh = ref.read(tasksRefreshProvider.notifier);
    await refresh.refresh();
  }

  void _updateLocalFilter(TasksFilter newFilter) {
    print('🔄 Filter update received: ${newFilter.activeFilterCount} active filters');
    // Directly update provider without local state or setState
    final notifier = ref.read(tasksFilterProvider.notifier);
    notifier.updateFromFilter(newFilter);
  }



  void _handleBulkAction(String action, Set<String> selectedIds, List<TaskWithProject> tasks) async {
    final bulkOps = ref.read(bulkTaskOperationsProvider);

    switch (action) {
      case 'complete':
        await bulkOps.updateStatus(selectedIds, TaskStatus.completed);
        break;
      case 'delete':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Tasks'),
            content: Text('Are you sure you want to delete ${selectedIds.length} tasks?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
        if (confirm == true) {
          await bulkOps.deleteTasks(selectedIds);
        }
        break;
      case 'priority-urgent':
        await bulkOps.updatePriority(selectedIds, TaskPriority.urgent);
        break;
      case 'priority-high':
        await bulkOps.updatePriority(selectedIds, TaskPriority.high);
        break;
    }

    // Clear selection
    ref.read(selectedTasksProvider.notifier).clearSelection();
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

  Widget _buildViewModeButton({
    required IconData icon,
    required TaskViewMode mode,
    required TaskViewMode currentMode,
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
                ? theme.colorScheme.primary.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
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
                        ? colorScheme.primary
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


  @override
  Widget build(BuildContext context) {
    _buildCount++;
    print('🔄 TasksScreenV2 build #$_buildCount triggered');
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= Breakpoints.desktop;
    final isTablet = screenWidth >= Breakpoints.tablet && screenWidth < Breakpoints.desktop;
    final isMobile = screenWidth < Breakpoints.tablet;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateTaskDialog,
        icon: const Icon(Icons.add),
        label: const Text('New Task'),
        backgroundColor: colorScheme.primary,
      ),
      body: Consumer(builder: (context, ref, child) {
        // Watch all providers inside Consumer to prevent full widget rebuilds
        final tasksAsync = ref.watch(aggregatedTasksProvider);

        return tasksAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                  const SizedBox(height: 16),
                  Text('Failed to load tasks', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _handleRefresh,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
            data: (_) {
              // Watch providers only within Consumer to localize rebuilds
              final filteredTasksFromProvider = ref.watch(filteredTasksProvider);
              final statistics = ref.watch(taskStatisticsProvider);
              final viewMode = ref.watch(taskViewModeProvider);
              final selectedTasks = ref.watch(selectedTasksProvider);
              final filter = ref.watch(tasksFilterProvider);
              final isRefreshing = ref.watch(tasksRefreshProvider);
              final taskErrors = ref.watch(taskLoadErrorsProvider);

              print('📦 Consumer rebuild: filter.searchQuery="${filter.searchQuery}", viewMode=$viewMode');

              // Use provider-filtered tasks directly (no local filtering needed)
              final filteredTasks = filteredTasksFromProvider;

              // Group tasks by status
              final allTasks = filteredTasks;
              final todoTasks = filteredTasks.where((t) => t.task.status == TaskStatus.todo).toList();
              final inProgressTasks = filteredTasks.where((t) => t.task.status == TaskStatus.inProgress).toList();
              final blockedTasks = filteredTasks.where((t) => t.task.status == TaskStatus.blocked).toList();
              final completedTasks = filteredTasks.where((t) => t.task.status == TaskStatus.completed).toList();

              // Show errors if any projects failed to load
              if (taskErrors.isNotEmpty && !isRefreshing) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ref.read(notificationServiceProvider.notifier).showWarning(
                  'Failed to load tasks from ${taskErrors.length} project(s)',
                );
              });
            }

              return Column(
              children: [
                // Fixed Header
                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colorScheme.primary.withValues(alpha: 0.02),
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
                                        Icons.task_alt,
                                        color: colorScheme.primary,
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
                                                'Tasks',
                                                style: theme.textTheme.headlineSmall?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              if (filter.hasActiveFilters) ...[
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                                  decoration: BoxDecoration(
                                                    color: colorScheme.primary.withValues(alpha: 0.1),
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                  child: Text(
                                                    '${filter.activeFilterCount} filters',
                                                    style: theme.textTheme.labelSmall?.copyWith(
                                                      color: colorScheme.primary,
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
                                                value: statistics['total'].toString(),
                                                label: 'Total tasks',
                                                theme: theme,
                                              ),
                                              Container(
                                                height: 30,
                                                width: 1,
                                                color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                                              ),
                                              _buildSimpleStatCard(
                                                value: (statistics['todo']! + statistics['inProgress']!).toString(),
                                                label: 'In progress',
                                                theme: theme,
                                              ),
                                              if (statistics['overdue']! > 0) ...[
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
                                                        statistics['overdue'].toString(),
                                                        style: theme.textTheme.headlineMedium?.copyWith(
                                                          fontWeight: FontWeight.w600,
                                                          color: Colors.deepOrange,
                                                          fontSize: 24,
                                                          height: 1.1,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        'Overdue',
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
                                                value: statistics['completed'].toString(),
                                                label: 'Completed',
                                                theme: theme,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),

                                    // Action Buttons
                                    if (selectedTasks.isNotEmpty) ...[
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
                                                '${selectedTasks.length}',
                                                style: const TextStyle(color: Colors.white),
                                              ),
                                            ],
                                          ),
                                        ),
                                        onSelected: (action) => _handleBulkAction(
                                          action,
                                          selectedTasks,
                                          filteredTasks,
                                        ),
                                        itemBuilder: (context) => [
                                          const PopupMenuItem(
                                            value: 'complete',
                                            child: ListTile(
                                              leading: Icon(Icons.check_circle, color: Colors.green),
                                              title: Text('Mark Complete'),
                                            ),
                                          ),
                                          const PopupMenuItem(
                                            value: 'priority-urgent',
                                            child: ListTile(
                                              leading: Icon(Icons.flag, color: Colors.red),
                                              title: Text('Set Urgent'),
                                            ),
                                          ),
                                          const PopupMenuItem(
                                            value: 'priority-high',
                                            child: ListTile(
                                              leading: Icon(Icons.flag, color: Colors.orange),
                                              title: Text('Set High Priority'),
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
                                    IconButton(
                                      onPressed: () => _showExportDialog(filteredTasks),
                                      icon: const Icon(Icons.download),
                                      tooltip: 'Export Tasks',
                                    ),
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
                                      Icons.task_alt,
                                      color: colorScheme.primary,
                                      size: 22,
                                    ),
                                    const SizedBox(width: 8),
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Tasks',
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
                                          Icon(Icons.task_alt, size: 14, color: Colors.blue),
                                          const SizedBox(width: 4),
                                          Text(statistics['total'].toString(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                          const SizedBox(width: 8),
                                          Icon(Icons.pending_actions, size: 14, color: Colors.orange),
                                          const SizedBox(width: 4),
                                          Text((statistics['todo']! + statistics['inProgress']!).toString(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                          const SizedBox(width: 8),
                                          Icon(Icons.check_circle, size: 14, color: Colors.green),
                                          const SizedBox(width: 4),
                                          Text(statistics['completed'].toString(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                    ),
                  ),
                ),

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
                          padding: EdgeInsets.symmetric(
                            vertical: LayoutConstants.spacingMd,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            border: Border(
                              bottom: BorderSide(
                                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                                width: 1,
                              ),
                            ),
                          ),
                          child: Column(
                            children: [
                        // Search and Controls Row - Cleaner unified design
                        Row(
                          children: [
                            // Search Field - Provider-based without screen refresh
                            Expanded(
                              child: ValueListenableBuilder<TextEditingValue>(
                                valueListenable: _searchController,
                                builder: (context, value, child) {
                                  return Container(
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: value.text.isNotEmpty
                                            ? colorScheme.primary.withValues(alpha: 0.3)
                                            : colorScheme.outline.withValues(alpha: 0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: TextField(
                                      controller: _searchController,
                                      onChanged: (value) {
                                        print('🔍 Search changed to: "$value"');
                                        // Debounced provider update without setState
                                        _filterDebounceTimer?.cancel();
                                        _filterDebounceTimer = Timer(const Duration(milliseconds: 300), () {
                                          if (mounted) {
                                            print('⏱️ Debounced search update: "$value"');
                                            ref.read(tasksFilterProvider.notifier).updateSearchQuery(value);
                                          }
                                        });
                                      },
                                      style: theme.textTheme.bodyMedium,
                                      decoration: InputDecoration(
                                        hintText: 'Search tasks...',
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
                                                  _filterDebounceTimer?.cancel();
                                                  ref.read(tasksFilterProvider.notifier).updateSearchQuery('');
                                                },
                                              )
                                            : null,
                                        border: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        errorBorder: InputBorder.none,
                                        disabledBorder: InputBorder.none,
                                        focusedErrorBorder: InputBorder.none,
                                        filled: false,
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Filter Button - Unified style
                            IconButton(
                              onPressed: _showFilterDialog,
                              icon: Badge(
                                isLabelVisible: filter.hasActiveFilters,
                                label: Text(filter.activeFilterCount.toString()),
                                child: Icon(
                                  Icons.filter_list,
                                  color: filter.hasActiveFilters
                                      ? colorScheme.primary
                                      : colorScheme.onSurfaceVariant,
                                  size: 22,
                                ),
                              ),
                              tooltip: 'Filters',
                              style: IconButton.styleFrom(
                                backgroundColor: filter.hasActiveFilters
                                    ? colorScheme.primary.withValues(alpha: 0.1)
                                    : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                              ),
                            ),

                            // Sort Button
                            const SizedBox(width: 4),
                            IconButton(
                              onPressed: _showSortDialog,
                              icon: Icon(
                                Icons.sort,
                                color: filter.sortBy != TaskSortBy.priority
                                    ? colorScheme.primary
                                    : colorScheme.onSurfaceVariant,
                                size: 22,
                              ),
                              tooltip: 'Sort',
                              style: IconButton.styleFrom(
                                backgroundColor: filter.sortBy != TaskSortBy.priority
                                    ? colorScheme.primary.withValues(alpha: 0.1)
                                    : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                              ),
                            ),

                            // Group Button
                            const SizedBox(width: 4),
                            IconButton(
                              onPressed: _showGroupDialog,
                              icon: Icon(
                                Icons.workspaces_outline,
                                color: filter.groupBy != TaskGroupBy.none
                                    ? colorScheme.primary
                                    : colorScheme.onSurfaceVariant,
                                size: 22,
                              ),
                              tooltip: 'Group',
                              style: IconButton.styleFrom(
                                backgroundColor: filter.groupBy != TaskGroupBy.none
                                    ? colorScheme.primary.withValues(alpha: 0.1)
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
                                      mode: TaskViewMode.list,
                                      currentMode: viewMode,
                                      tooltip: 'List',
                                      onTap: () => ref.read(taskViewModeProvider.notifier).state = TaskViewMode.list,
                                    ),
                                    _buildViewModeButton(
                                      icon: Icons.view_compact,
                                      mode: TaskViewMode.compact,
                                      currentMode: viewMode,
                                      tooltip: 'Compact',
                                      onTap: () => ref.read(taskViewModeProvider.notifier).state = TaskViewMode.compact,
                                    ),
                                    _buildViewModeButton(
                                      icon: Icons.view_kanban,
                                      mode: TaskViewMode.kanban,
                                      currentMode: viewMode,
                                      tooltip: 'Kanban',
                                      onTap: () => ref.read(taskViewModeProvider.notifier).state = TaskViewMode.kanban,
                                    ),
                                  ],
                                ),
                              ),
                            ],

                          ],
                        ),

                        // Status Filter Tabs - Only show for list and compact views
                        if (viewMode == TaskViewMode.list || viewMode == TaskViewMode.compact) ...[
                          const SizedBox(height: 12),
                          Container(
                            height: 38,
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.all(3),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                return Row(
                                  children: [
                                    _buildStatusTab(
                                      label: 'All',
                                      count: allTasks.length,
                                      isSelected: _tabController.index == 0,
                                      onTap: () => _tabController.animateTo(0),
                                      colorScheme: colorScheme,
                                    ),
                                    _buildStatusTab(
                                      label: 'To Do',
                                      count: todoTasks.length,
                                      isSelected: _tabController.index == 1,
                                      onTap: () => _tabController.animateTo(1),
                                      colorScheme: colorScheme,
                                    ),
                                    _buildStatusTab(
                                      label: 'In Progress',
                                      count: inProgressTasks.length,
                                      isSelected: _tabController.index == 2,
                                      onTap: () => _tabController.animateTo(2),
                                      colorScheme: colorScheme,
                                    ),
                                    if (!isMobile) ...[
                                      _buildStatusTab(
                                        label: 'Blocked',
                                        count: blockedTasks.length,
                                        isSelected: _tabController.index == 3,
                                        onTap: () => _tabController.animateTo(3),
                                        colorScheme: colorScheme,
                                        color: Colors.orange,
                                      ),
                                      _buildStatusTab(
                                        label: 'Completed',
                                        count: completedTasks.length,
                                        isSelected: _tabController.index == 4,
                                        onTap: () => _tabController.animateTo(4),
                                        colorScheme: colorScheme,
                                        color: Colors.green,
                                      ),
                                    ],
                                  ],
                                );
                              },
                            ),
                          ),
                        ],

                        // Quick Filters - Optional secondary row
                        if (filter.hasActiveFilters) ...[
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 32,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: [
                                if (filter.showMyTasksOnly)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: FilterChip(
                                      label: const Text('My Tasks', style: TextStyle(fontSize: 12)),
                                      selected: true,
                                      onSelected: (_) {
                                        ref.read(tasksFilterProvider.notifier).toggleMyTasksOnly();
                                      },
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ),
                                if (filter.priorities.contains(TaskPriority.urgent))
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: FilterChip(
                                      label: const Text('Urgent', style: TextStyle(fontSize: 12)),
                                      selected: true,
                                      onSelected: (_) {
                                        ref.read(tasksFilterProvider.notifier).togglePriority(TaskPriority.urgent);
                                      },
                                      selectedColor: Colors.red.withValues(alpha: 0.2),
                                      checkmarkColor: Colors.red,
                                      labelStyle: const TextStyle(color: Colors.red),
                                      side: BorderSide(
                                        color: Colors.red.withValues(alpha: 0.5),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ),
                                if (filter.hasActiveFilters) ...[
                                  const SizedBox(width: 8),
                                  ActionChip(
                                    label: const Text('Clear filters', style: TextStyle(fontSize: 12)),
                                    onPressed: () {
                                      ref.read(tasksFilterProvider.notifier).clearAllFilters();
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
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),

                // Scrollable Content
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: viewMode == TaskViewMode.kanban
                          ? 0
                          : (isDesktop ? 24 : 16),
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1400),
                        child: viewMode == TaskViewMode.kanban
                            ? KanbanBoardView(tasks: filteredTasks)
                            : viewMode == TaskViewMode.list || viewMode == TaskViewMode.compact
                                ? TabBarView(
                                    controller: _tabController,
                                    physics: const NeverScrollableScrollPhysics(),
                                    children: [
                                      _buildTasksView(allTasks, viewMode, theme, isDesktop, isTablet),
                                      _buildTasksView(todoTasks, viewMode, theme, isDesktop, isTablet),
                                      _buildTasksView(inProgressTasks, viewMode, theme, isDesktop, isTablet),
                                      _buildTasksView(blockedTasks, viewMode, theme, isDesktop, isTablet),
                                      _buildTasksView(completedTasks, viewMode, theme, isDesktop, isTablet),
                                    ],
                                  )
                                : _buildTasksView(filteredTasks, viewMode, theme, isDesktop, isTablet),
                      ),
                    ),
                  ),
                ),
              ],
            );
            },
          );
        }),
      );
  }

  Widget _buildTasksView(
    List<TaskWithProject> tasks,
    TaskViewMode viewMode,
    ThemeData theme,
    bool isDesktop,
    bool isTablet,
  ) {
    if (tasks.isEmpty) {
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
              Icons.inbox,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No tasks found',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasProjects
                  ? 'Upload meeting transcripts or emails to generate actionable tasks'
                  : 'Create your first project and upload content to track tasks',
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

    // Use grouped view for list and compact modes with the filtered tasks
    return GroupedTasksView(viewMode: viewMode, tasks: tasks);
  }
}