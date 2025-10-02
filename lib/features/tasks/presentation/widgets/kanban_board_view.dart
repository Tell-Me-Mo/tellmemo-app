import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../projects/domain/entities/task.dart';
import '../../../projects/presentation/providers/risks_tasks_provider.dart';
import '../providers/aggregated_tasks_provider.dart';
import '../utils/task_ui_helpers.dart';
import 'task_kanban_card.dart';

class KanbanBoardView extends ConsumerStatefulWidget {
  final List<TaskWithProject> tasks;

  const KanbanBoardView({
    super.key,
    required this.tasks,
  });

  @override
  ConsumerState<KanbanBoardView> createState() => _KanbanBoardViewState();
}

class _KanbanBoardViewState extends ConsumerState<KanbanBoardView> {
  final ScrollController _horizontalScrollController = ScrollController();

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    super.dispose();
  }

  List<TaskWithProject> _getTasksForStatus(TaskStatus status) {
    return widget.tasks.where((t) => t.task.status == status).toList();
  }


  String _getStatusLabel(TaskStatus status) {
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

  Widget _buildColumn(TaskStatus status, ThemeData theme) {
    final tasks = _getTasksForStatus(status);
    final colorScheme = theme.colorScheme;
    final statusColor = TaskUIHelpers.getStatusColor(status, Theme.of(context).colorScheme);

    return Container(
      width: 320,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          // Column Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              border: Border.all(
                color: statusColor.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  TaskUIHelpers.getStatusIcon(status),
                  color: statusColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getStatusLabel(status),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${tasks.length}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Tasks Container
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                border: Border(
                  left: BorderSide(
                    color: statusColor.withValues(alpha: 0.3),
                  ),
                  right: BorderSide(
                    color: statusColor.withValues(alpha: 0.3),
                  ),
                  bottom: BorderSide(
                    color: statusColor.withValues(alpha: 0.3),
                  ),
                ),
              ),
              child: DragTarget<TaskWithProject>(
                onWillAcceptWithDetails: (details) {
                  // Accept tasks from other columns
                  return details.data.task.status != status;
                },
                onAcceptWithDetails: (details) async {
                  // Update task status
                  final taskWithProject = details.data;
                  _handleTaskStatusChange(taskWithProject, status);
                },
                builder: (context, candidateData, rejectedData) {
                  return Container(
                    color: candidateData.isNotEmpty
                        ? statusColor.withValues(alpha: 0.05)
                        : Colors.transparent,
                    child: tasks.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.inbox,
                                    size: 48,
                                    color: colorScheme.onSurfaceVariant
                                        .withValues(alpha: 0.3),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'No tasks',
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: colorScheme.onSurfaceVariant
                                          .withValues(alpha: 0.5),
                                    ),
                                  ),
                                  if (candidateData.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      'Drop here',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: statusColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(8),
                            itemCount: tasks.length,
                            itemBuilder: (context, index) {
                              return Draggable<TaskWithProject>(
                                data: tasks[index],
                                feedback: Material(
                                  elevation: 8,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    width: 300,
                                    child: TaskKanbanCard(
                                      taskWithProject: tasks[index],
                                      isDragging: true,
                                    ),
                                  ),
                                ),
                                childWhenDragging: Opacity(
                                  opacity: 0.5,
                                  child: TaskKanbanCard(
                                    taskWithProject: tasks[index],
                                  ),
                                ),
                                child: TaskKanbanCard(
                                  taskWithProject: tasks[index],
                                ),
                              );
                            },
                          ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleTaskStatusChange(
    TaskWithProject taskWithProject,
    TaskStatus newStatus,
  ) async {
    try {
      final repository = ref.read(risksTasksRepositoryProvider);

      final updatedTask = taskWithProject.task.copyWith(
        status: newStatus,
        completedDate: newStatus == TaskStatus.completed ? DateTime.now() : null,
        lastUpdated: DateTime.now(),
      );

      await repository.updateTask(updatedTask.id, updatedTask);

      // Force refresh the tasks (clear cache and invalidate)
      ref.read(forceRefreshTasksProvider)();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Task moved to ${_getStatusLabel(newStatus)}',
          ),
          backgroundColor: TaskUIHelpers.getStatusColor(newStatus, Theme.of(context).colorScheme),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating task: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Filter out cancelled tasks from kanban view
    final statuses = [
      TaskStatus.todo,
      TaskStatus.inProgress,
      TaskStatus.blocked,
      TaskStatus.completed,
    ];

    return Scrollbar(
      controller: _horizontalScrollController,
      child: SingleChildScrollView(
        controller: _horizontalScrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: statuses.map((status) {
              return _buildColumn(status, theme);
            }).toList(),
          ),
        ),
      ),
    );
  }
}