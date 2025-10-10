import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../projects/domain/entities/task.dart';
import '../../../projects/domain/repositories/risks_tasks_repository.dart';
import '../../../projects/presentation/providers/risks_tasks_provider.dart';
import 'aggregated_tasks_provider.dart';
import 'tasks_preferences_provider.dart';

class SelectedTasksNotifier extends StateNotifier<Set<String>> {
  SelectedTasksNotifier() : super({});

  void toggle(String taskId) {
    if (state.contains(taskId)) {
      state = {...state}..remove(taskId);
    } else {
      state = {...state, taskId};
    }
  }

  void selectAll(List<String> taskIds) {
    state = taskIds.toSet();
  }

  void clearSelection() {
    state = {};
  }

  bool isSelected(String taskId) => state.contains(taskId);
}

final selectedTasksProvider = StateNotifierProvider<SelectedTasksNotifier, Set<String>>((ref) {
  return SelectedTasksNotifier();
});

// Provider for bulk operations
final bulkTaskOperationsProvider = Provider((ref) {
  final repository = ref.watch(risksTasksRepositoryProvider);

  return BulkTaskOperations(repository, ref);
});

class BulkTaskOperations {
  final RisksTasksRepository _repository;
  final Ref _ref;

  BulkTaskOperations(this._repository, this._ref);

  Future<void> updateStatus(Set<String> taskIds, TaskStatus newStatus) async {
    final tasks = _ref.read(aggregatedTasksProvider).value ?? [];

    for (final taskId in taskIds) {
      final taskWithProject = tasks.firstWhere(
        (t) => t.task.id == taskId,
        orElse: () => throw Exception('Task not found'),
      );

      final updatedTask = taskWithProject.task.copyWith(
        status: newStatus,
        completedDate: newStatus == TaskStatus.completed ? DateTime.now() : null,
      );

      await _repository.updateTask(taskId, updatedTask);
    }

    // Use the force refresh provider to ensure UI updates
    await _ref.read(forceRefreshTasksProvider)();
  }

  Future<void> updatePriority(Set<String> taskIds, TaskPriority newPriority) async {
    final tasks = _ref.read(aggregatedTasksProvider).value ?? [];

    for (final taskId in taskIds) {
      final taskWithProject = tasks.firstWhere(
        (t) => t.task.id == taskId,
        orElse: () => throw Exception('Task not found'),
      );

      final updatedTask = taskWithProject.task.copyWith(priority: newPriority);

      await _repository.updateTask(taskId, updatedTask);
    }

    // Use the force refresh provider to ensure UI updates
    await _ref.read(forceRefreshTasksProvider)();
  }

  Future<void> deleteTasks(Set<String> taskIds) async {
    for (final taskId in taskIds) {
      await _repository.deleteTask(taskId);
    }

    // Use the force refresh provider to ensure UI updates
    await _ref.read(forceRefreshTasksProvider)();
  }

  Future<void> assignTasks(Set<String> taskIds, String assignee) async {
    final tasks = _ref.read(aggregatedTasksProvider).value ?? [];

    for (final taskId in taskIds) {
      final taskWithProject = tasks.firstWhere(
        (t) => t.task.id == taskId,
        orElse: () => throw Exception('Task not found'),
      );

      final updatedTask = taskWithProject.task.copyWith(assignee: assignee);

      await _repository.updateTask(taskId, updatedTask);
    }

    // Use the force refresh provider to ensure UI updates
    await _ref.read(forceRefreshTasksProvider)();
  }
}

// View mode provider
enum TaskViewMode {
  list,
  compact,
  kanban,
}

final taskViewModeProvider = StateProvider<TaskViewMode>((ref) {
  // Load saved view mode preference
  final prefsAsync = ref.watch(taskPreferencesServiceProvider);

  final initialMode = prefsAsync.maybeWhen(
    data: (service) => service.loadViewMode(),
    orElse: () => TaskViewMode.compact,
  );

  // Auto-save when view mode changes
  ref.listenSelf((previous, next) async {
    if (previous != next && prefsAsync.hasValue) {
      await prefsAsync.value!.saveViewMode(next);
    }
  });

  return initialMode;
});

// Refresh controller
class TasksRefreshNotifier extends StateNotifier<bool> {
  TasksRefreshNotifier(this._ref) : super(false);

  final Ref _ref;

  Future<void> refresh() async {
    if (state) return; // Already refreshing

    state = true;
    try {
      // Invalidate the aggregated tasks provider to force a refresh
      _ref.invalidate(aggregatedTasksProvider);

      // Wait for the new data to load
      await _ref.read(aggregatedTasksProvider.future);
    } finally {
      state = false;
    }
  }
}

final tasksRefreshProvider = StateNotifierProvider<TasksRefreshNotifier, bool>((ref) {
  return TasksRefreshNotifier(ref);
});

// Page size for pagination
final taskPageSizeProvider = StateProvider<int>((ref) => 20);

// Current page for pagination
final taskCurrentPageProvider = StateProvider<int>((ref) => 0);