import 'package:shared_preferences/shared_preferences.dart';
import '../../presentation/providers/tasks_filter_provider.dart';
import '../../presentation/providers/tasks_state_provider.dart';
import '../../../projects/domain/entities/task.dart';

class TaskPreferencesService {
  static const String _keyPrefix = 'task_prefs_';

  // Keys for different preferences
  static const String _keySortBy = '${_keyPrefix}sort_by';
  static const String _keySortOrder = '${_keyPrefix}sort_order';
  static const String _keyGroupBy = '${_keyPrefix}group_by';
  static const String _keyViewMode = '${_keyPrefix}view_mode';
  static const String _keyShowOverdueOnly = '${_keyPrefix}show_overdue_only';
  static const String _keyShowMyTasksOnly = '${_keyPrefix}show_my_tasks_only';
  static const String _keyShowAiGeneratedOnly = '${_keyPrefix}show_ai_generated_only';
  static const String _keySelectedStatuses = '${_keyPrefix}selected_statuses';
  static const String _keySelectedPriorities = '${_keyPrefix}selected_priorities';
  static const String _keySelectedProjects = '${_keyPrefix}selected_projects';

  final SharedPreferences _prefs;

  TaskPreferencesService(this._prefs);

  // Factory constructor to create instance
  static Future<TaskPreferencesService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return TaskPreferencesService(prefs);
  }

  // Save filter preferences
  Future<void> saveFilterPreferences(TasksFilter filter) async {
    await _prefs.setString(_keySortBy, filter.sortBy.name);
    await _prefs.setString(_keySortOrder, filter.sortOrder.name);
    await _prefs.setString(_keyGroupBy, filter.groupBy.name);
    await _prefs.setBool(_keyShowOverdueOnly, filter.showOverdueOnly);
    await _prefs.setBool(_keyShowMyTasksOnly, filter.showMyTasksOnly);
    await _prefs.setBool(_keyShowAiGeneratedOnly, filter.showAiGeneratedOnly);

    // Save sets as string lists
    await _prefs.setStringList(
      _keySelectedStatuses,
      filter.statuses.map((s) => s.name).toList(),
    );
    await _prefs.setStringList(
      _keySelectedPriorities,
      filter.priorities.map((p) => p.name).toList(),
    );
    await _prefs.setStringList(
      _keySelectedProjects,
      filter.projectIds.toList(),
    );
  }

  // Load filter preferences
  TasksFilter loadFilterPreferences() {
    final sortByStr = _prefs.getString(_keySortBy);
    final sortOrderStr = _prefs.getString(_keySortOrder);
    final groupByStr = _prefs.getString(_keyGroupBy);

    final sortBy = sortByStr != null
        ? TaskSortBy.values.firstWhere(
            (e) => e.name == sortByStr,
            orElse: () => TaskSortBy.priority,
          )
        : TaskSortBy.priority;

    final sortOrder = sortOrderStr != null
        ? TaskSortOrder.values.firstWhere(
            (e) => e.name == sortOrderStr,
            orElse: () => TaskSortOrder.descending,
          )
        : TaskSortOrder.descending;

    final groupBy = groupByStr != null
        ? TaskGroupBy.values.firstWhere(
            (e) => e.name == groupByStr,
            orElse: () => TaskGroupBy.none,
          )
        : TaskGroupBy.none;

    // Load status filter
    final statusStrings = _prefs.getStringList(_keySelectedStatuses) ?? [];
    final statuses = statusStrings
        .map((s) => TaskStatus.values.firstWhereOrNull((e) => e.name == s))
        .whereType<TaskStatus>()
        .toSet();

    // Load priority filter
    final priorityStrings = _prefs.getStringList(_keySelectedPriorities) ?? [];
    final priorities = priorityStrings
        .map((p) => TaskPriority.values.firstWhereOrNull((e) => e.name == p))
        .whereType<TaskPriority>()
        .toSet();

    // Load project filter
    final projectIds = _prefs.getStringList(_keySelectedProjects)?.toSet() ?? {};

    return TasksFilter(
      sortBy: sortBy,
      sortOrder: sortOrder,
      groupBy: groupBy,
      showOverdueOnly: _prefs.getBool(_keyShowOverdueOnly) ?? false,
      showMyTasksOnly: _prefs.getBool(_keyShowMyTasksOnly) ?? false,
      showAiGeneratedOnly: _prefs.getBool(_keyShowAiGeneratedOnly) ?? false,
      statuses: statuses,
      priorities: priorities,
      projectIds: projectIds,
    );
  }

  // Save view mode preference
  Future<void> saveViewMode(TaskViewMode viewMode) async {
    await _prefs.setString(_keyViewMode, viewMode.name);
  }

  // Load view mode preference
  TaskViewMode loadViewMode() {
    final viewModeStr = _prefs.getString(_keyViewMode);
    if (viewModeStr != null) {
      return TaskViewMode.values.firstWhere(
        (e) => e.name == viewModeStr,
        orElse: () => TaskViewMode.compact,
      );
    }
    return TaskViewMode.compact;
  }


  // Clear all task preferences (useful for sign out)
  Future<void> clearAllPreferences() async {
    final keys = _prefs.getKeys().where((key) => key.startsWith(_keyPrefix));
    for (final key in keys) {
      await _prefs.remove(key);
    }
  }

  // Get user-specific key (if you want per-user preferences)
  static String getUserKey(String userId, String key) {
    return 'user_${userId}_$key';
  }
}

// Extension to help with null-safe enum lookup
extension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    try {
      return firstWhere(test);
    } catch (_) {
      return null;
    }
  }
}