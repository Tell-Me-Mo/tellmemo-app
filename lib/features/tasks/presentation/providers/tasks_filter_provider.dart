import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../projects/domain/entities/task.dart';
import 'tasks_preferences_provider.dart';

enum TaskSortBy {
  priority,
  dueDate,
  createdDate,
  projectName,
  status,
  assignee,
}

enum TaskSortOrder {
  ascending,
  descending,
}

enum TaskGroupBy {
  none,
  project,
  status,
  priority,
  assignee,
  dueDate,
}

class TasksFilter {
  final Set<String> projectIds;
  final Set<TaskStatus> statuses;
  final Set<TaskPriority> priorities;
  final Set<String> assignees;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool showOverdueOnly;
  final bool showMyTasksOnly;
  final bool showAiGeneratedOnly;
  final String searchQuery;
  final TaskSortBy sortBy;
  final TaskSortOrder sortOrder;
  final TaskGroupBy groupBy;

  const TasksFilter({
    this.projectIds = const {},
    this.statuses = const {},
    this.priorities = const {},
    this.assignees = const {},
    this.startDate,
    this.endDate,
    this.showOverdueOnly = false,
    this.showMyTasksOnly = false,
    this.showAiGeneratedOnly = false,
    this.searchQuery = '',
    this.sortBy = TaskSortBy.priority,
    this.sortOrder = TaskSortOrder.descending,
    this.groupBy = TaskGroupBy.none,
  });

  TasksFilter copyWith({
    Set<String>? projectIds,
    Set<TaskStatus>? statuses,
    Set<TaskPriority>? priorities,
    Set<String>? assignees,
    DateTime? startDate,
    DateTime? endDate,
    bool? showOverdueOnly,
    bool? showMyTasksOnly,
    bool? showAiGeneratedOnly,
    String? searchQuery,
    TaskSortBy? sortBy,
    TaskSortOrder? sortOrder,
    TaskGroupBy? groupBy,
  }) {
    return TasksFilter(
      projectIds: projectIds ?? this.projectIds,
      statuses: statuses ?? this.statuses,
      priorities: priorities ?? this.priorities,
      assignees: assignees ?? this.assignees,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      showOverdueOnly: showOverdueOnly ?? this.showOverdueOnly,
      showMyTasksOnly: showMyTasksOnly ?? this.showMyTasksOnly,
      showAiGeneratedOnly: showAiGeneratedOnly ?? this.showAiGeneratedOnly,
      searchQuery: searchQuery ?? this.searchQuery,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
      groupBy: groupBy ?? this.groupBy,
    );
  }

  bool get hasActiveFilters {
    return projectIds.isNotEmpty ||
        statuses.isNotEmpty ||
        priorities.isNotEmpty ||
        assignees.isNotEmpty ||
        startDate != null ||
        endDate != null ||
        showOverdueOnly ||
        showMyTasksOnly ||
        showAiGeneratedOnly ||
        searchQuery.isNotEmpty;
  }

  int get activeFilterCount {
    int count = 0;
    if (projectIds.isNotEmpty) count++;
    if (statuses.isNotEmpty) count++;
    if (priorities.isNotEmpty) count++;
    if (assignees.isNotEmpty) count++;
    if (startDate != null || endDate != null) count++;
    if (showOverdueOnly) count++;
    if (showMyTasksOnly) count++;
    if (showAiGeneratedOnly) count++;
    if (searchQuery.isNotEmpty) count++;
    return count;
  }

  void clearFilters() {
    // This is handled by the notifier
  }
}

class TasksFilterNotifier extends StateNotifier<TasksFilter> {
  final Ref _ref;

  TasksFilterNotifier(this._ref, TasksFilter initialFilter) : super(initialFilter) {
    // Auto-save preferences when state changes
    addListener((state) async {
      final prefsAsync = _ref.read(taskPreferencesServiceProvider);
      if (prefsAsync.hasValue) {
        await prefsAsync.value!.saveFilterPreferences(state);
      }
    });
  }

  void updateProjectIds(Set<String> projectIds) {
    state = state.copyWith(projectIds: projectIds);
  }

  void toggleProjectId(String projectId) {
    final newSet = Set<String>.from(state.projectIds);
    if (newSet.contains(projectId)) {
      newSet.remove(projectId);
    } else {
      newSet.add(projectId);
    }
    state = state.copyWith(projectIds: newSet);
  }

  void updateStatuses(Set<TaskStatus> statuses) {
    state = state.copyWith(statuses: statuses);
  }

  void toggleStatus(TaskStatus status) {
    final newSet = Set<TaskStatus>.from(state.statuses);
    if (newSet.contains(status)) {
      newSet.remove(status);
    } else {
      newSet.add(status);
    }
    state = state.copyWith(statuses: newSet);
  }

  void updatePriorities(Set<TaskPriority> priorities) {
    state = state.copyWith(priorities: priorities);
  }

  void togglePriority(TaskPriority priority) {
    final newSet = Set<TaskPriority>.from(state.priorities);
    if (newSet.contains(priority)) {
      newSet.remove(priority);
    } else {
      newSet.add(priority);
    }
    state = state.copyWith(priorities: newSet);
  }

  void updateAssignees(Set<String> assignees) {
    state = state.copyWith(assignees: assignees);
  }

  void toggleAssignee(String assignee) {
    final newSet = Set<String>.from(state.assignees);
    if (newSet.contains(assignee)) {
      newSet.remove(assignee);
    } else {
      newSet.add(assignee);
    }
    state = state.copyWith(assignees: newSet);
  }

  void updateDateRange(DateTime? startDate, DateTime? endDate) {
    state = state.copyWith(startDate: startDate, endDate: endDate);
  }

  void toggleOverdueOnly() {
    state = state.copyWith(showOverdueOnly: !state.showOverdueOnly);
  }

  void toggleMyTasksOnly() {
    state = state.copyWith(showMyTasksOnly: !state.showMyTasksOnly);
  }

  void toggleAiGeneratedOnly() {
    state = state.copyWith(showAiGeneratedOnly: !state.showAiGeneratedOnly);
  }

  void updateSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void updateSorting(TaskSortBy sortBy, [TaskSortOrder? sortOrder]) {
    state = state.copyWith(
      sortBy: sortBy,
      sortOrder: sortOrder ?? state.sortOrder,
    );
  }

  void toggleSortOrder() {
    state = state.copyWith(
      sortOrder: state.sortOrder == TaskSortOrder.ascending
          ? TaskSortOrder.descending
          : TaskSortOrder.ascending,
    );
  }

  void clearAllFilters() {
    state = const TasksFilter();
  }

  void updateGrouping(TaskGroupBy groupBy) {
    state = state.copyWith(groupBy: groupBy);
  }

  void applyQuickFilter(String filterType) {
    clearAllFilters();
    switch (filterType) {
      case 'overdue':
        state = state.copyWith(showOverdueOnly: true);
        break;
      case 'my-tasks':
        state = state.copyWith(showMyTasksOnly: true);
        break;
      case 'urgent':
        state = state.copyWith(priorities: {TaskPriority.urgent});
        break;
      case 'in-progress':
        state = state.copyWith(statuses: {TaskStatus.inProgress});
        break;
      case 'blocked':
        state = state.copyWith(statuses: {TaskStatus.blocked});
        break;
      case 'ai-generated':
        state = state.copyWith(showAiGeneratedOnly: true);
        break;
    }
  }

  void updateFromFilter(TasksFilter newFilter) {
    state = newFilter;
  }
}

final tasksFilterProvider = StateNotifierProvider<TasksFilterNotifier, TasksFilter>((ref) {
  // Try to load saved preferences
  final prefsAsync = ref.watch(taskPreferencesServiceProvider);

  final initialFilter = prefsAsync.maybeWhen(
    data: (service) => service.loadFilterPreferences(),
    orElse: () => const TasksFilter(),
  );

  return TasksFilterNotifier(ref, initialFilter);
});