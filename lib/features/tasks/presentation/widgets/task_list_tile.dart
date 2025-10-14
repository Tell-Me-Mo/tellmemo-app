import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../projects/domain/entities/task.dart';
import '../providers/aggregated_tasks_provider.dart';
import '../providers/tasks_state_provider.dart';
import '../utils/task_ui_helpers.dart';
import 'task_detail_panel.dart';

class TaskListTile extends ConsumerWidget {
  final TaskWithProject taskWithProject;

  const TaskListTile({
    super.key,
    required this.taskWithProject,
  });


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final task = taskWithProject.task;
    final project = taskWithProject.project;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Quick Complete Button
              IconButton(
                icon: Icon(
                  task.status == TaskStatus.completed
                      ? Icons.check_circle
                      : Icons.circle_outlined,
                  color: task.status == TaskStatus.completed
                      ? Colors.green
                      : colorScheme.onSurfaceVariant,
                  size: 28,
                ),
                onPressed: () async {
                  final bulkOps = ref.read(bulkTaskOperationsProvider);
                  await bulkOps.updateStatus(
                    {task.id},
                    task.status == TaskStatus.completed
                        ? TaskStatus.todo
                        : TaskStatus.completed,
                  );
                },
              ),
              const SizedBox(width: 12),

              // Main Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title Row
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            task.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    if (task.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        task.description!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    const SizedBox(height: 8),

                    // Info Row
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                              // Project Badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.folder_outlined,
                                      size: 14,
                                      color: colorScheme.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        project.name,
                                        style: theme.textTheme.labelSmall?.copyWith(
                                          color: colorScheme.primary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Status Badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: TaskUIHelpers.getStatusColor(task.status, colorScheme).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  task.statusLabel,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: TaskUIHelpers.getStatusColor(task.status, colorScheme),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),

                              // Due Date
                              if (task.dueDate != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: task.isOverdue
                                        ? Colors.red.withValues(alpha: 0.1)
                                        : colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.calendar_today,
                                        size: 14,
                                        color: task.isOverdue
                                            ? Colors.red
                                            : colorScheme.onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        DateFormat('MMM d, y').format(task.dueDate!),
                                        style: theme.textTheme.labelSmall?.copyWith(
                                          color: task.isOverdue
                                              ? Colors.red
                                              : colorScheme.onSurfaceVariant,
                                          fontWeight: task.isOverdue ? FontWeight.bold : null,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              // Assignee
                              if (task.assignee != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.person_outline,
                                        size: 14,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        task.assignee!,
                                        style: theme.textTheme.labelSmall?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              // Blocked Badge
                              if (task.status == TaskStatus.blocked && task.blockerDescription != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.warning_amber,
                                        size: 14,
                                        color: Colors.orange,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Blocked',
                                        style: theme.textTheme.labelSmall?.copyWith(
                                          color: Colors.orange,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                      ],
                    ),

                    // Progress Bar
                    if (task.progressPercentage > 0 && task.status != TaskStatus.completed) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: LinearProgressIndicator(
                              value: task.progressPercentage / 100,
                              backgroundColor: colorScheme.surfaceContainerHighest,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                TaskUIHelpers.getStatusColor(task.status, colorScheme),
                              ),
                              minHeight: 4,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${task.progressPercentage}%',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Priority Badge (centered vertically)
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: TaskUIHelpers.getPriorityColor(task.priority).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.flag,
                      size: 14,
                      color: TaskUIHelpers.getPriorityColor(task.priority),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      task.priorityLabel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: TaskUIHelpers.getPriorityColor(task.priority),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}