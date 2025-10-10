import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/aggregated_tasks_provider.dart';
import '../providers/grouped_tasks_provider.dart';
import '../providers/tasks_filter_provider.dart';
import '../providers/tasks_state_provider.dart';
import 'task_list_tile.dart';
import 'task_list_tile_compact.dart';

class GroupedTasksView extends ConsumerStatefulWidget {
  final TaskViewMode viewMode;
  final List<TaskWithProject>? tasks;

  const GroupedTasksView({
    super.key,
    required this.viewMode,
    this.tasks,
  });

  @override
  ConsumerState<GroupedTasksView> createState() => _GroupedTasksViewState();
}

class _GroupedTasksViewState extends ConsumerState<GroupedTasksView> {
  final Map<String, bool> _expandedGroups = {};

  // Caching variables to prevent expensive regrouping
  TaskGroupBy? _lastGroupBy;
  List<TaskWithProject>? _lastTasks;
  List<TaskGroup>? _cachedGroups;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1200;
    final isTablet = screenWidth >= 600 && screenWidth < 1200;

    final filter = ref.watch(tasksFilterProvider);

    // Use provided tasks or fall back to grouped provider
    final List<TaskGroup> taskGroups;
    if (widget.tasks != null) {
      // Group the provided tasks with caching
      taskGroups = _getCachedGroups(widget.tasks!, filter.groupBy);
    } else {
      taskGroups = ref.watch(groupedTasksProvider);
    }

    // If no grouping, show regular view
    if (filter.groupBy == TaskGroupBy.none && taskGroups.length == 1) {
      return _buildTasksList(
        taskGroups.first.tasks,
        widget.viewMode,
        theme,
        isDesktop,
        isTablet,
        isNestedInGroup: false,  // This is the main list, should be scrollable
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: taskGroups.length,
      itemBuilder: (context, index) {
        final group = taskGroups[index];
        final isExpanded = _expandedGroups[group.id] ?? true;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Theme(
            data: theme.copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: isExpanded,
              title: _buildGroupHeader(context, group, filter.groupBy, colorScheme, theme),
              onExpansionChanged: (expanded) {
                setState(() {
                  _expandedGroups[group.id] = expanded;
                });
              },
              children: group.tasks.map((taskWithProject) {
                return _buildTaskItem(context, taskWithProject);
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGroupHeader(BuildContext context, TaskGroup group, TaskGroupBy groupBy, ColorScheme colorScheme, ThemeData theme) {
    IconData icon;
    Color color;

    switch (groupBy) {
      case TaskGroupBy.project:
        icon = Icons.folder;
        color = colorScheme.primary;
        break;
      case TaskGroupBy.status:
        switch (group.id) {
          case 'todo':
            icon = Icons.circle_outlined;
            color = Colors.grey;
            break;
          case 'inProgress':
            icon = Icons.timelapse;
            color = Colors.blue;
            break;
          case 'blocked':
            icon = Icons.block;
            color = Colors.orange;
            break;
          case 'completed':
            icon = Icons.check_circle;
            color = Colors.green;
            break;
          default:
            icon = Icons.cancel;
            color = Colors.red;
        }
        break;
      case TaskGroupBy.priority:
        switch (group.id) {
          case 'urgent':
            icon = Icons.flag;
            color = Colors.red;
            break;
          case 'high':
            icon = Icons.flag;
            color = Colors.orange;
            break;
          case 'medium':
            icon = Icons.flag_outlined;
            color = Colors.yellow[700]!;
            break;
          default:
            icon = Icons.flag_outlined;
            color = Colors.grey;
        }
        break;
      case TaskGroupBy.assignee:
        icon = Icons.person;
        color = colorScheme.tertiary;
        break;
      case TaskGroupBy.dueDate:
        switch (group.id) {
          case 'overdue':
            icon = Icons.warning;
            color = Colors.red;
            break;
          case 'today':
            icon = Icons.today;
            color = Colors.orange;
            break;
          case 'tomorrow':
            icon = Icons.event;
            color = Colors.blue;
            break;
          default:
            icon = Icons.calendar_today;
            color = colorScheme.primary;
        }
        break;
      default:
        icon = Icons.list;
        color = colorScheme.primary;
    }

    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Text(
          group.name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
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
            '${group.count}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTaskItem(BuildContext context, TaskWithProject taskWithProject) {
    return TaskListTileCompact(taskWithProject: taskWithProject);
  }

  Widget _buildTasksList(
    List<TaskWithProject> tasks,
    TaskViewMode viewMode,
    ThemeData theme,
    bool isDesktop,
    bool isTablet, {
    bool isNestedInGroup = false,
  }) {
    if (tasks.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'No tasks',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
          ),
        ),
      );
    }

    // List view
    final isCompact = viewMode == TaskViewMode.compact;

    // If not nested in a group, use ListView.builder for better performance and scrolling
    if (!isNestedInGroup) {
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 16),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final taskWithProject = tasks[index];
            final isSelected = ref.watch(selectedTasksProvider).contains(taskWithProject.task.id);

            return Padding(
              padding: EdgeInsets.only(bottom: isCompact ? 4 : 8),
              child: Row(
                children: [
                  if (ref.watch(selectedTasksProvider).isNotEmpty)
                    Checkbox(
                      value: isSelected,
                      onChanged: (_) {
                        ref.read(selectedTasksProvider.notifier).toggle(taskWithProject.task.id);
                      },
                    ),
                  Expanded(
                    child: isCompact
                        ? TaskListTileCompact(taskWithProject: taskWithProject)
                        : TaskListTile(taskWithProject: taskWithProject),
                  ),
                ],
              ),
            );
          },
        );
      }

      // For nested groups, keep the non-scrollable ListView
      return ListView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: tasks.map((taskWithProject) {
          final isSelected = ref.watch(selectedTasksProvider).contains(taskWithProject.task.id);

          return Padding(
            padding: EdgeInsets.only(bottom: isCompact ? 4 : 8),
            child: Row(
              children: [
                if (ref.watch(selectedTasksProvider).isNotEmpty)
                  Checkbox(
                    value: isSelected,
                    onChanged: (_) {
                      ref.read(selectedTasksProvider.notifier).toggle(taskWithProject.task.id);
                    },
                  ),
                Expanded(
                  child: isCompact
                      ? TaskListTileCompact(taskWithProject: taskWithProject)
                      : TaskListTile(taskWithProject: taskWithProject),
                ),
              ],
            ),
          );
        }).toList(),
      );
    }

  List<TaskGroup> _groupTasks(List<TaskWithProject> tasks, TaskGroupBy groupBy) {
    if (groupBy == TaskGroupBy.none || tasks.isEmpty) {
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

      switch (groupBy) {
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
      switch (groupBy) {
        case TaskGroupBy.project:
          groupName = groupTasks.first.project.name;
          break;

        case TaskGroupBy.status:
          groupName = _getStatusLabel(groupKey);
          break;

        case TaskGroupBy.priority:
          groupName = _getPriorityLabel(groupKey);
          break;

        case TaskGroupBy.assignee:
          groupName = groupKey == 'unassigned' ? 'Unassigned' : groupKey;
          break;

        case TaskGroupBy.dueDate:
          groupName = _getDueDateGroupLabel(groupKey);
          break;

        case TaskGroupBy.none:
          groupName = 'All Tasks';
      }

      return TaskGroup(
        id: groupKey,
        name: groupName,
        tasks: groupTasks,
      );
    }).toList();

    // Sort groups based on grouping type
    _sortGroups(taskGroups, groupBy);

    return taskGroups;
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'todo':
        return 'To Do';
      case 'inProgress':
        return 'In Progress';
      case 'blocked':
        return 'Blocked';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  String _getPriorityLabel(String priority) {
    switch (priority) {
      case 'urgent':
        return 'Urgent';
      case 'high':
        return 'High Priority';
      case 'medium':
        return 'Medium Priority';
      case 'low':
        return 'Low Priority';
      default:
        return priority;
    }
  }

  String _getDueDateGroupLabel(String groupKey) {
    switch (groupKey) {
      case 'overdue':
        return 'Overdue';
      case 'today':
        return 'Today';
      case 'tomorrow':
        return 'Tomorrow';
      case 'this-week':
        return 'This Week';
      case 'this-month':
        return 'This Month';
      case 'later':
        return 'Later';
      case 'no-due-date':
        return 'No Due Date';
      default:
        return groupKey;
    }
  }

  void _sortGroups(List<TaskGroup> groups, TaskGroupBy groupBy) {
    switch (groupBy) {
      case TaskGroupBy.status:
        final statusOrder = ['todo', 'inProgress', 'blocked', 'completed', 'cancelled'];
        groups.sort((a, b) => statusOrder.indexOf(a.id).compareTo(statusOrder.indexOf(b.id)));
        break;

      case TaskGroupBy.priority:
        final priorityOrder = ['urgent', 'high', 'medium', 'low'];
        groups.sort((a, b) => priorityOrder.indexOf(a.id).compareTo(priorityOrder.indexOf(b.id)));
        break;

      case TaskGroupBy.dueDate:
        final dueDateOrder = ['overdue', 'today', 'tomorrow', 'this-week', 'this-month', 'later', 'no-due-date'];
        groups.sort((a, b) => dueDateOrder.indexOf(a.id).compareTo(dueDateOrder.indexOf(b.id)));
        break;

      case TaskGroupBy.project:
      case TaskGroupBy.assignee:
        groups.sort((a, b) => a.name.compareTo(b.name));
        break;

      case TaskGroupBy.none:
        // No sorting needed
        break;
    }
  }

  /// Get cached groups to prevent expensive regrouping operations
  List<TaskGroup> _getCachedGroups(List<TaskWithProject> tasks, TaskGroupBy groupBy) {
    // Only recompute if data actually changed
    if (_lastGroupBy == groupBy &&
        _lastTasks != null &&
        _cachedGroups != null &&
        _listsEqual(_lastTasks!, tasks)) {
      return _cachedGroups!;
    }

    // Cache miss - recompute and update cache
    _lastGroupBy = groupBy;
    _lastTasks = List.from(tasks);
    _cachedGroups = _groupTasks(tasks, groupBy);
    return _cachedGroups!;
  }

  /// Efficient list equality check for caching
  bool _listsEqual(List<TaskWithProject> list1, List<TaskWithProject> list2) {
    if (list1.length != list2.length) return false;

    // Compare task IDs AND key properties that affect rendering
    for (int i = 0; i < list1.length; i++) {
      final task1 = list1[i].task;
      final task2 = list2[i].task;

      // If IDs differ, lists are different
      if (task1.id != task2.id) return false;

      // If same ID but different status or update time, lists are different
      if (task1.status != task2.status ||
          task1.lastUpdated != task2.lastUpdated) {
        return false;
      }
    }

    return true;
  }
}