import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/task.dart';
import '../providers/risks_tasks_provider.dart';
import 'task_dialog.dart';
import 'package:go_router/go_router.dart';
import '../../../tasks/presentation/widgets/create_task_dialog.dart';
import '../../../tasks/presentation/widgets/task_detail_dialog.dart';
import '../../../tasks/presentation/providers/aggregated_tasks_provider.dart';
import '../providers/projects_provider.dart';

class ProjectTasksWidget extends ConsumerWidget {
  final String projectId;
  final int? limit;

  const ProjectTasksWidget({
    super.key,
    required this.projectId,
    this.limit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksNotifierProvider(projectId));
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        tasksAsync.when(
          data: (tasks) => _buildHeader(context, ref, theme, tasks.isNotEmpty, tasks.length),
          loading: () => _buildHeader(context, ref, theme, false, 0),
          error: (_, __) => _buildHeader(context, ref, theme, false, 0),
        ),
        const SizedBox(height: 12),
        tasksAsync.when(
          data: (tasks) {
            if (tasks.isEmpty) {
              return _buildEmptyCard(context, ref, 'No tasks yet');
            }

            // Apply limit if specified
            List<Task> displayTasks = tasks;
            if (limit != null) {
              displayTasks = tasks.take(limit!).toList();
            }

            final activeTasks = displayTasks.where((t) => t.isActive).toList();
            final completedTasks = displayTasks.where((t) => t.isCompleted).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Active tasks
                if (activeTasks.isNotEmpty) ...[
                  ...activeTasks.map((task) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _buildTaskCard(context, ref, task),
                  )),
                ],

                // Completed tasks
                if (completedTasks.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ExpansionTile(
                    title: Text(
                      'Completed (${completedTasks.length})',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    children: completedTasks.map((task) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _buildTaskCard(context, ref, task),
                    )).toList(),
                  ),
                ],
              ],
            );
          },
          loading: () => const LinearProgressIndicator(),
          error: (_, __) => _buildEmptyCard(context, ref, 'Error loading tasks'),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, ThemeData theme, bool hasTasks, int count) {
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              'Tasks & Action Items',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (count > 0) Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasTasks)
              TextButton(
                onPressed: () => context.push('/tasks?project=$projectId&from=project'),
                child: const Text('See all'),
              ),
            IconButton(
              icon: const Icon(Icons.add, size: 20),
              onPressed: () => _showAddTaskDialog(context, ref),
              tooltip: 'Add Task',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyCard(BuildContext context, WidgetRef ref, String message) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.08),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.task_outlined,
                size: 32,
                color: colorScheme.primary.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No tasks created yet',
              style: textTheme.titleSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Upload meeting transcripts to automatically extract action items and track progress',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, WidgetRef ref, Task task) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showTaskDetails(context, ref, task),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.05),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Checkbox/Status indicator
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: task.isCompleted
                    ? Colors.green
                    : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: task.isCompleted
                      ? Colors.green
                      : _getPriorityColor(task.priority).withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
                child: task.isCompleted
                  ? const Icon(Icons.check, size: 10, color: Colors.white)
                  : null,
              ),
              const SizedBox(width: 10),
              // Content
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                              decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                              color: task.isCompleted
                                ? colorScheme.onSurfaceVariant.withValues(alpha: 0.5)
                                : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${task.priorityLabel} • ${task.statusLabel}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (task.questionToAsk != null)
                      Tooltip(
                        message: task.questionToAsk!,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          margin: const EdgeInsets.only(left: 8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Icon(
                            Icons.help_outline,
                            size: 14,
                            color: Colors.blue.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    if (task.aiGenerated)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        margin: const EdgeInsets.only(left: 8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          'AI',
                          style: TextStyle(
                            color: Colors.blue.withValues(alpha: 0.8),
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
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

  void _showAddTaskDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => CreateTaskDialog(initialProjectId: projectId),
    );
  }

  void _showTaskDetails(BuildContext context, WidgetRef ref, Task task) {
    final projectAsync = ref.watch(projectDetailProvider(projectId));

    projectAsync.when(
      data: (project) {
        if (project != null) {
          showDialog(
            context: context,
            builder: (context) => TaskDetailDialog(
              taskWithProject: TaskWithProject(
                task: task,
                project: project,
              ),
            ),
          );
        }
      },
      loading: () {
        // Show loading indicator or handle loading state
        showDialog(
          context: context,
          builder: (context) => const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Loading project details...'),
              ],
            ),
          ),
        );
      },
      error: (error, stackTrace) {
        // Handle error case - fallback to original dialog
        showDialog(
          context: context,
          builder: (context) => TaskDialog(
            projectId: projectId,
            projectName: 'Project',
            task: task,
          ),
        );
      },
    );
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return Colors.blue;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.high:
        return Colors.deepOrange;
      case TaskPriority.urgent:
        return Colors.red;
    }
  }

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo:
        return Colors.grey;
      case TaskStatus.inProgress:
        return Colors.blue;
      case TaskStatus.blocked:
        return Colors.red;
      case TaskStatus.completed:
        return Colors.green;
      case TaskStatus.cancelled:
        return Colors.grey;
    }
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}