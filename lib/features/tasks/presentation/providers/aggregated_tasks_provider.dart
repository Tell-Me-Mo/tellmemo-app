import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../projects/domain/entities/task.dart';
import '../../../projects/domain/entities/project.dart';
import '../../../projects/presentation/providers/projects_provider.dart';
import '../../../projects/presentation/providers/risks_tasks_provider.dart';
import 'tasks_filter_provider.dart';

class TaskWithProject {
  final Task task;
  final Project project;

  TaskWithProject({
    required this.task,
    required this.project,
  });
}

class TaskLoadError {
  final String projectId;
  final String projectName;
  final String error;

  TaskLoadError({
    required this.projectId,
    required this.projectName,
    required this.error,
  });
}

// Provider for task loading errors
final taskLoadErrorsProvider = StateProvider<List<TaskLoadError>>((ref) => []);

// Main aggregated tasks provider - simplified without manual caching
final aggregatedTasksProvider = FutureProvider<List<TaskWithProject>>((ref) async {
  final projects = await ref.watch(projectsListProvider.future);
  final errors = <TaskLoadError>[];

  if (projects.isEmpty) {
    return [];
  }

  final List<TaskWithProject> allTasks = [];

  for (final project in projects) {
    try {
      // Always fetch fresh - let Riverpod handle caching naturally
      final tasks = await ref.watch(projectTasksProvider(project.id).future);

      for (final task in tasks) {
        allTasks.add(TaskWithProject(
          task: task,
          project: project,
        ));
      }
    } catch (e) {
      // Track errors for each project
      errors.add(TaskLoadError(
        projectId: project.id,
        projectName: project.name,
        error: e.toString(),
      ));
      // Continue loading tasks from other projects if one fails
      continue;
    }
  }

  // Store errors for display
  ref.read(taskLoadErrorsProvider.notifier).state = errors;

  return allTasks;
});

// Filtered tasks provider
final filteredTasksProvider = Provider<List<TaskWithProject>>((ref) {
  final tasksAsync = ref.watch(aggregatedTasksProvider);
  final filter = ref.watch(tasksFilterProvider);
  final currentUser = 'current_user'; // TODO: Get from auth provider

  return tasksAsync.maybeWhen(
    data: (tasks) {
      var filtered = tasks;

      // Apply filters
      if (filter.projectIds.isNotEmpty) {
        filtered = filtered.where((t) => filter.projectIds.contains(t.task.projectId)).toList();
      }

      if (filter.statuses.isNotEmpty) {
        filtered = filtered.where((t) => filter.statuses.contains(t.task.status)).toList();
      }

      if (filter.priorities.isNotEmpty) {
        filtered = filtered.where((t) => filter.priorities.contains(t.task.priority)).toList();
      }

      if (filter.assignees.isNotEmpty) {
        filtered = filtered.where((t) =>
          t.task.assignee != null && filter.assignees.contains(t.task.assignee!)).toList();
      }

      if (filter.showOverdueOnly) {
        filtered = filtered.where((t) => t.task.isOverdue).toList();
      }

      if (filter.showMyTasksOnly) {
        filtered = filtered.where((t) => t.task.assignee == currentUser).toList();
      }

      if (filter.showAiGeneratedOnly) {
        filtered = filtered.where((t) => t.task.aiGenerated).toList();
      }

      if (filter.startDate != null) {
        filtered = filtered.where((t) =>
          t.task.dueDate != null &&
          t.task.dueDate!.isAfter(filter.startDate!)).toList();
      }

      if (filter.endDate != null) {
        filtered = filtered.where((t) =>
          t.task.dueDate != null &&
          t.task.dueDate!.isBefore(filter.endDate!.add(const Duration(days: 1)))).toList();
      }

      if (filter.searchQuery.isNotEmpty) {
        final query = filter.searchQuery.toLowerCase();
        filtered = filtered.where((taskWithProject) {
          final task = taskWithProject.task;
          return task.title.toLowerCase().contains(query) ||
                 (task.description?.toLowerCase().contains(query) ?? false) ||
                 (task.assignee?.toLowerCase().contains(query) ?? false) ||
                 taskWithProject.project.name.toLowerCase().contains(query);
        }).toList();
      }

      // Apply sorting based on filter settings
      _sortTasks(filtered, filter.sortBy, filter.sortOrder);

      return filtered;
    },
    orElse: () => [],
  );
});

// Helper function to sort tasks
void _sortTasks(List<TaskWithProject> tasks, TaskSortBy sortBy, TaskSortOrder sortOrder) {
  tasks.sort((a, b) {
    int comparison = 0;

    switch (sortBy) {
      case TaskSortBy.priority:
        final priorityOrder = {
          TaskPriority.urgent: 0,
          TaskPriority.high: 1,
          TaskPriority.medium: 2,
          TaskPriority.low: 3,
        };
        comparison = priorityOrder[a.task.priority]!.compareTo(priorityOrder[b.task.priority]!);
        break;

      case TaskSortBy.dueDate:
        if (a.task.dueDate != null && b.task.dueDate != null) {
          comparison = a.task.dueDate!.compareTo(b.task.dueDate!);
        } else if (a.task.dueDate != null) {
          comparison = -1;
        } else if (b.task.dueDate != null) {
          comparison = 1;
        }
        break;

      case TaskSortBy.createdDate:
        if (a.task.createdDate != null && b.task.createdDate != null) {
          comparison = a.task.createdDate!.compareTo(b.task.createdDate!);
        }
        break;

      case TaskSortBy.projectName:
        comparison = a.project.name.compareTo(b.project.name);
        break;

      case TaskSortBy.status:
        final statusOrder = {
          TaskStatus.todo: 0,
          TaskStatus.inProgress: 1,
          TaskStatus.blocked: 2,
          TaskStatus.completed: 3,
          TaskStatus.cancelled: 4,
        };
        comparison = statusOrder[a.task.status]!.compareTo(statusOrder[b.task.status]!);
        break;

      case TaskSortBy.assignee:
        final aAssignee = a.task.assignee ?? '';
        final bAssignee = b.task.assignee ?? '';
        comparison = aAssignee.compareTo(bAssignee);
        break;
    }

    // Apply sort order
    return sortOrder == TaskSortOrder.ascending ? comparison : -comparison;
  });
}

// Force refresh provider - using refresh instead of invalidate
final forceRefreshTasksProvider = Provider((ref) {
  return () async {
    // Invalidate all project task providers first
    ref.invalidate(projectTasksProvider);

    // Invalidate all tasks notifier providers to refresh project details screens
    ref.invalidate(tasksNotifierProvider);

    // Refresh (not invalidate) - this waits for fresh data before returning
    final _ = await ref.refresh(aggregatedTasksProvider.future);
  };
});

// Provider for task statistics
final taskStatisticsProvider = Provider<Map<String, int>>((ref) {
  final tasksAsync = ref.watch(aggregatedTasksProvider);

  return tasksAsync.maybeWhen(
    data: (tasks) {
      final stats = <String, int>{
        'total': tasks.length,
        'todo': tasks.where((t) => t.task.status == TaskStatus.todo).length,
        'inProgress': tasks.where((t) => t.task.status == TaskStatus.inProgress).length,
        'blocked': tasks.where((t) => t.task.status == TaskStatus.blocked).length,
        'completed': tasks.where((t) => t.task.status == TaskStatus.completed).length,
        'cancelled': tasks.where((t) => t.task.status == TaskStatus.cancelled).length,
        'overdue': tasks.where((t) => t.task.isOverdue).length,
        'urgent': tasks.where((t) => t.task.priority == TaskPriority.urgent).length,
        'high': tasks.where((t) => t.task.priority == TaskPriority.high).length,
        'aiGenerated': tasks.where((t) => t.task.aiGenerated).length,
      };
      return stats;
    },
    orElse: () => {
      'total': 0,
      'todo': 0,
      'inProgress': 0,
      'blocked': 0,
      'completed': 0,
      'cancelled': 0,
      'overdue': 0,
      'urgent': 0,
      'high': 0,
      'aiGenerated': 0,
    },
  );
});