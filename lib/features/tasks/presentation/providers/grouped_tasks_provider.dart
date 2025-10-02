import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../projects/domain/entities/task.dart';
import 'aggregated_tasks_provider.dart';
import 'tasks_filter_provider.dart';

class TaskGroup {
  final String id;
  final String name;
  final List<TaskWithProject> tasks;
  final int count;

  TaskGroup({
    required this.id,
    required this.name,
    required this.tasks,
  }) : count = tasks.length;
}

final groupedTasksProvider = Provider<List<TaskGroup>>((ref) {
  final filter = ref.watch(tasksFilterProvider);
  final tasks = ref.watch(filteredTasksProvider);

  if (filter.groupBy == TaskGroupBy.none || tasks.isEmpty) {
    // No grouping - return single group with all tasks
    return [
      TaskGroup(
        id: 'all',
        name: 'All Tasks',
        tasks: tasks,
      ),
    ];
  }

  // Group tasks based on selected grouping
  final Map<String, List<TaskWithProject>> groups = {};

  for (final taskWithProject in tasks) {
    final task = taskWithProject.task;
    String groupKey;

    switch (filter.groupBy) {
      case TaskGroupBy.project:
        groupKey = taskWithProject.project.id;
        break;

      case TaskGroupBy.status:
        groupKey = task.status.name;
        break;

      case TaskGroupBy.priority:
        groupKey = task.priority.name;
        break;

      case TaskGroupBy.assignee:
        groupKey = task.assignee ?? 'unassigned';
        break;

      case TaskGroupBy.dueDate:
        if (task.dueDate == null) {
          groupKey = 'no-due-date';
        } else {
          final now = DateTime.now();
          final dueDate = task.dueDate!;
          final difference = dueDate.difference(now);

          if (difference.isNegative) {
            groupKey = 'overdue';
          } else if (difference.inDays == 0) {
            groupKey = 'today';
          } else if (difference.inDays == 1) {
            groupKey = 'tomorrow';
          } else if (difference.inDays <= 7) {
            groupKey = 'this-week';
          } else if (difference.inDays <= 30) {
            groupKey = 'this-month';
          } else {
            groupKey = 'later';
          }
        }
        break;

      case TaskGroupBy.none:
        continue; // Should not reach here
    }

    groups[groupKey] ??= [];
    groups[groupKey]!.add(taskWithProject);
  }

  // Convert map to list of TaskGroups and sort
  final taskGroups = groups.entries.map((entry) {
    final groupKey = entry.key;
    final groupTasks = entry.value;

    // Get proper group name based on grouping type
    String groupName;
    switch (filter.groupBy) {
      case TaskGroupBy.project:
        groupName = groupTasks.first.project.name;
        break;
      case TaskGroupBy.status:
        groupName = _getStatusDisplayName(groupTasks.first.task.status);
        break;
      case TaskGroupBy.priority:
        groupName = _getPriorityDisplayName(groupTasks.first.task.priority);
        break;
      case TaskGroupBy.assignee:
        groupName = groupTasks.first.task.assignee ?? 'Unassigned';
        break;
      case TaskGroupBy.dueDate:
        groupName = _getGroupNameFromKey(groupKey);
        break;
      case TaskGroupBy.none:
        groupName = 'All Tasks';
        break;
    }

    return TaskGroup(
      id: groupKey,
      name: groupName,
      tasks: groupTasks,
    );
  }).toList();

  // Sort groups based on grouping type
  switch (filter.groupBy) {
    case TaskGroupBy.status:
      taskGroups.sort((a, b) {
        final statusOrder = ['todo', 'inProgress', 'blocked', 'completed', 'cancelled'];
        final aIndex = statusOrder.indexOf(a.id);
        final bIndex = statusOrder.indexOf(b.id);
        if (aIndex == -1 && bIndex == -1) return a.name.compareTo(b.name);
        if (aIndex == -1) return 1;
        if (bIndex == -1) return -1;
        return aIndex.compareTo(bIndex);
      });
      break;

    case TaskGroupBy.priority:
      taskGroups.sort((a, b) {
        final priorityOrder = ['urgent', 'high', 'medium', 'low'];
        final aIndex = priorityOrder.indexOf(a.id);
        final bIndex = priorityOrder.indexOf(b.id);
        if (aIndex == -1 && bIndex == -1) return a.name.compareTo(b.name);
        if (aIndex == -1) return 1;
        if (bIndex == -1) return -1;
        return aIndex.compareTo(bIndex);
      });
      break;

    case TaskGroupBy.dueDate:
      taskGroups.sort((a, b) {
        final dateOrder = ['overdue', 'today', 'tomorrow', 'this-week', 'this-month', 'later', 'no-due-date'];
        final aIndex = dateOrder.indexOf(a.id);
        final bIndex = dateOrder.indexOf(b.id);
        if (aIndex == -1 && bIndex == -1) return a.name.compareTo(b.name);
        if (aIndex == -1) return 1;
        if (bIndex == -1) return -1;
        return aIndex.compareTo(bIndex);
      });
      break;

    default:
      taskGroups.sort((a, b) => a.name.compareTo(b.name));
  }

  return taskGroups;
});

String _getStatusDisplayName(TaskStatus status) {
  switch (status) {
    case TaskStatus.todo:
      return 'To Do';
    case TaskStatus.inProgress:
      return 'In Progress';
    case TaskStatus.blocked:
      return 'Blocked';
    case TaskStatus.completed:
      return 'Completed';
    case TaskStatus.cancelled:
      return 'Cancelled';
  }
}

String _getPriorityDisplayName(TaskPriority priority) {
  switch (priority) {
    case TaskPriority.urgent:
      return 'Urgent';
    case TaskPriority.high:
      return 'High Priority';
    case TaskPriority.medium:
      return 'Medium Priority';
    case TaskPriority.low:
      return 'Low Priority';
  }
}

String _getGroupNameFromKey(String key) {
  switch (key) {
    case 'overdue':
      return 'Overdue';
    case 'today':
      return 'Due Today';
    case 'tomorrow':
      return 'Due Tomorrow';
    case 'this-week':
      return 'Due This Week';
    case 'this-month':
      return 'Due This Month';
    case 'later':
      return 'Due Later';
    case 'no-due-date':
      return 'No Due Date';
    default:
      return key;
  }
}