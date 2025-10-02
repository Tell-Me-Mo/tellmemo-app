import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../projects/domain/entities/task.dart';
import '../providers/aggregated_tasks_provider.dart';
import '../utils/task_ui_helpers.dart';
import 'task_detail_dialog.dart';

class TaskKanbanCard extends StatelessWidget {
  final TaskWithProject taskWithProject;
  final bool isDragging;

  const TaskKanbanCard({
    super.key,
    required this.taskWithProject,
    this.isDragging = false,
  });


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final task = taskWithProject.task;
    final project = taskWithProject.project;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Card(
        elevation: isDragging ? 8 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: isDragging
              ? null
              : () {
                  showDialog(
                    context: context,
                    builder: (context) => TaskDetailDialog(
                      taskWithProject: taskWithProject,
                    ),
                  );
                },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Priority and Project Row
                Row(
                  children: [
                    // Priority Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: TaskUIHelpers.getPriorityColor(task.priority).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.flag,
                            size: 12,
                            color: TaskUIHelpers.getPriorityColor(task.priority),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            task.priorityLabel,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: TaskUIHelpers.getPriorityColor(task.priority),
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Project Badge
                    Container(
                      constraints: const BoxConstraints(maxWidth: 100),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.folder_outlined,
                            size: 12,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              project.name,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.primary,
                                fontSize: 10,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Title
                Text(
                  task.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                if (task.description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    task.description!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                const SizedBox(height: 8),

                // Bottom Row
                Row(
                  children: [
                    // Assignee
                    if (task.assignee != null) ...[
                      Icon(
                        Icons.person_outline,
                        size: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          task.assignee!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ] else
                      const Spacer(),

                    // Due Date
                    if (task.dueDate != null) ...[
                      Icon(
                        Icons.calendar_today,
                        size: 12,
                        color: task.isOverdue ? Colors.red : colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('MMM d').format(task.dueDate!),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: task.isOverdue ? Colors.red : colorScheme.onSurfaceVariant,
                          fontWeight: task.isOverdue ? FontWeight.bold : null,
                        ),
                      ),
                    ],

                    // AI Badge
                    if (task.aiGenerated) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.auto_awesome,
                        size: 14,
                        color: colorScheme.tertiary,
                      ),
                    ],
                  ],
                ),

                // Progress Bar (if in progress)
                if (task.progressPercentage > 0 && task.status == TaskStatus.inProgress) ...[
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: task.progressPercentage / 100,
                    minHeight: 3,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}