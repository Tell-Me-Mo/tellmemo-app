import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/notification_service.dart';
import '../../../projects/domain/entities/task.dart';
import '../../../projects/presentation/providers/risks_tasks_provider.dart';
import '../providers/aggregated_tasks_provider.dart';
import '../providers/tasks_state_provider.dart';
import '../utils/task_ui_helpers.dart';
import 'task_detail_panel.dart';

class TaskListTileCompact extends ConsumerWidget {
  final TaskWithProject taskWithProject;

  const TaskListTileCompact({
    super.key,
    required this.taskWithProject,
  });



  Future<void> _updateTaskStatus(BuildContext context, WidgetRef ref, TaskStatus newStatus, {String? blockerDescription}) async {
    final repository = ref.read(risksTasksRepositoryProvider);
    final task = taskWithProject.task;

    try {
      final updatedTask = task.copyWith(
        status: newStatus,
        completedDate: newStatus == TaskStatus.completed ? DateTime.now() : null,
        blockerDescription: newStatus == TaskStatus.blocked ? blockerDescription : null,
        lastUpdated: DateTime.now(),
      );

      await repository.updateTask(task.id, updatedTask);

      // Force refresh the tasks list
      ref.read(forceRefreshTasksProvider)();

      if (context.mounted) {
        ref.read(notificationServiceProvider.notifier).showSuccess(_getStatusUpdateMessage(newStatus));
      }
    } catch (e) {
      if (context.mounted) {
        ref.read(notificationServiceProvider.notifier).showError('Error updating task: $e');
      }
    }
  }

  String _getStatusUpdateMessage(TaskStatus status) {
    switch (status) {
      case TaskStatus.completed:
        return 'Task marked as completed';
      case TaskStatus.inProgress:
        return 'Task marked as in progress';
      case TaskStatus.blocked:
        return 'Task marked as blocked';
      case TaskStatus.todo:
        return 'Task marked as to do';
      case TaskStatus.cancelled:
        return 'Task cancelled';
    }
  }

  Future<void> _showBlockerDialog(BuildContext context, WidgetRef ref) async {
    String blockerDescription = '';
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final result = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      transitionDuration: Duration.zero,
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 450,
            minWidth: 350,
          ),
          child: IntrinsicHeight(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.block,
                        color: Colors.orange,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Mark as Blocked',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                      ),
                    ],
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Blocker Description *',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'What is blocking this task?',
                          hintStyle: TextStyle(
                            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: colorScheme.outline.withValues(alpha: 0.3),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: colorScheme.outline.withValues(alpha: 0.3),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Colors.orange.withValues(alpha: 0.5),
                            ),
                          ),
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        ),
                        maxLines: 3,
                        onChanged: (value) => blockerDescription = value,
                      ),
                    ],
                  ),
                ),

                // Actions
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      FilledButton(
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.orange,
                        ),
                        child: const Text('Mark as Blocked'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      },
    );

    if (result == true && blockerDescription.isNotEmpty && context.mounted) {
      await _updateTaskStatus(context, ref, TaskStatus.blocked, blockerDescription: blockerDescription);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final task = taskWithProject.task;
    final project = taskWithProject.project;
    final priorityColor = TaskUIHelpers.getPriorityColor(task.priority);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.15)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () {
          showGeneralDialog(
            context: context,
            barrierDismissible: false,
            barrierColor: Colors.transparent,
            transitionDuration: Duration.zero,
            pageBuilder: (context, animation, secondaryAnimation) {
              return TaskDetailPanel(
                taskWithProject: taskWithProject,
              );
            },
          );
        },
        child: Container(
          padding: const EdgeInsets.only(left: 12, top: 10, bottom: 10, right: 4),
          child: Row(
            children: [
              // Priority indicator
              Container(
                width: 2,
                height: 36,
                decoration: BoxDecoration(
                  color: priorityColor,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
              const SizedBox(width: 10),

              // Quick Complete Button
              InkWell(
                onTap: () async {
                  final bulkOps = ref.read(bulkTaskOperationsProvider);
                  await bulkOps.updateStatus(
                    {task.id},
                    task.status == TaskStatus.completed
                        ? TaskStatus.todo
                        : TaskStatus.completed,
                  );
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: task.status == TaskStatus.completed
                        ? Colors.green.withValues(alpha: 0.15)
                        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    task.status == TaskStatus.completed
                        ? Icons.check
                        : Icons.circle_outlined,
                    size: 16,
                    color: task.status == TaskStatus.completed
                        ? Colors.green
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title and status row
                    Row(
                      children: [
                        // Title
                        Expanded(
                          child: Text(
                            task.title,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              decoration: task.status == TaskStatus.completed
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: task.status == TaskStatus.completed
                                  ? colorScheme.onSurfaceVariant.withValues(alpha: 0.6)
                                  : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Priority badge (only show if high or urgent)
                        if (task.priority == TaskPriority.urgent ||
                            task.priority == TaskPriority.high)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: priorityColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Icon(
                              Icons.flag,
                              size: 12,
                              color: priorityColor,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Metadata row
                    Row(
                      children: [
                        // Left side - labels
                        Expanded(
                          child: Row(
                            children: [
                              // Project label
                              Icon(
                                Icons.folder_outlined,
                                size: 11,
                                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                              ),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  project.name,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                                    fontSize: 11,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Status badge (only if not todo or completed)
                              if (task.status != TaskStatus.todo &&
                                  task.status != TaskStatus.completed) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: TaskUIHelpers.getStatusColor(task.status, colorScheme).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Text(
                                    task.statusLabel,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: TaskUIHelpers.getStatusColor(task.status, colorScheme),
                                      fontWeight: FontWeight.w500,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ],

                              // Assignee (if exists)
                              if (task.assignee != null) ...[
                                Icon(
                                  Icons.person_outline,
                                  size: 11,
                                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                                ),
                                const SizedBox(width: 3),
                                Flexible(
                                  child: Text(
                                    task.assignee!,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                                      fontSize: 10,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],

                              // Blocked indicator
                              if (task.status == TaskStatus.blocked) ...[
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.warning_amber,
                                  size: 11,
                                  color: Colors.orange,
                                ),
                              ],
                            ],
                          ),
                        ),

                        // Due date on the right (with warning if overdue)
                        if (task.dueDate != null)
                          Row(
                            children: [
                              if (task.isOverdue)
                                Icon(
                                  Icons.schedule,
                                  size: 11,
                                  color: Colors.red,
                                ),
                              if (task.isOverdue)
                                const SizedBox(width: 3),
                              Text(
                                _formatDate(task.dueDate!),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: task.isOverdue
                                      ? Colors.red
                                      : colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                                  fontSize: 11,
                                  fontWeight: task.isOverdue ? FontWeight.bold : null,
                                ),
                              ),
                            ],
                          ),

                        // Progress indicator (if in progress)
                        if (task.progressPercentage > 0 &&
                            task.status == TaskStatus.inProgress) ...[
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 30,
                            height: 3,
                            child: LinearProgressIndicator(
                              value: task.progressPercentage / 100,
                              backgroundColor: colorScheme.surfaceContainerHighest,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                TaskUIHelpers.getStatusColor(task.status, colorScheme),
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${task.progressPercentage}%',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // More Actions Menu
              const SizedBox(width: 4),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  size: 18,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 36,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                onSelected: (value) async {
                  switch (value) {
                    case 'complete':
                      await _updateTaskStatus(
                        context,
                        ref,
                        task.status == TaskStatus.completed
                            ? TaskStatus.todo
                            : TaskStatus.completed,
                      );
                      break;
                    case 'start':
                      await _updateTaskStatus(context, ref, TaskStatus.inProgress);
                      break;
                    case 'block':
                      await _showBlockerDialog(context, ref);
                      break;
                    case 'unblock':
                      await _updateTaskStatus(context, ref, TaskStatus.inProgress);
                      break;
                  }
                },
                itemBuilder: (BuildContext context) {
                  return <PopupMenuEntry<String>>[
                    // Complete/Incomplete Toggle
                    PopupMenuItem<String>(
                      value: 'complete',
                      child: Row(
                        children: [
                          Icon(
                            task.status == TaskStatus.completed
                                ? Icons.check_box_outline_blank
                                : Icons.check_box,
                            size: 20,
                            color: task.status == TaskStatus.completed
                                ? colorScheme.onSurfaceVariant
                                : Colors.green,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            task.status == TaskStatus.completed
                                ? 'Mark as Incomplete'
                                : 'Mark as Complete',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),

                    // Start Working (if not in progress or completed)
                    if (task.status != TaskStatus.inProgress &&
                        task.status != TaskStatus.completed)
                      PopupMenuItem<String>(
                        value: 'start',
                        child: Row(
                          children: [
                            const Icon(
                              Icons.play_arrow,
                              size: 20,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Start Working',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),

                    // Mark as Blocked (if not blocked)
                    if (task.status != TaskStatus.blocked)
                      PopupMenuItem<String>(
                        value: 'block',
                        child: Row(
                          children: [
                            const Icon(
                              Icons.block,
                              size: 20,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Mark as Blocked',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),

                    // Unblock (if blocked)
                    if (task.status == TaskStatus.blocked)
                      PopupMenuItem<String>(
                        value: 'unblock',
                        child: Row(
                          children: [
                            const Icon(
                              Icons.play_arrow,
                              size: 20,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Unblock & Start',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                  ];
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    final difference = today.difference(dateOnly);

    if (difference.isNegative) {
      final futureDiff = dateOnly.difference(today);
      if (futureDiff.inDays == 0) {
        return 'Today';
      } else if (futureDiff.inDays == 1) {
        return 'Tomorrow';
      } else if (futureDiff.inDays < 7) {
        return 'in ${futureDiff.inDays}d';
      } else if (futureDiff.inDays < 30) {
        return 'in ${(futureDiff.inDays / 7).floor()}w';
      } else {
        return '${date.month}/${date.day}';
      }
    } else {
      if (difference.inDays == 0) {
        return 'Today';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return 'Overdue';
      }
    }
  }
}