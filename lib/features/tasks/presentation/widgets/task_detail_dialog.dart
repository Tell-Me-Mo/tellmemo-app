import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/notification_service.dart';
import '../../../projects/domain/entities/task.dart';
import '../../../projects/presentation/providers/risks_tasks_provider.dart';
import '../providers/aggregated_tasks_provider.dart';
import '../utils/task_ui_helpers.dart';
import '../../../queries/presentation/widgets/ask_ai_panel.dart';
import '../../../queries/presentation/providers/query_provider.dart';

class TaskDetailDialog extends ConsumerStatefulWidget {
  final TaskWithProject taskWithProject;

  const TaskDetailDialog({
    super.key,
    required this.taskWithProject,
  });

  @override
  ConsumerState<TaskDetailDialog> createState() => _TaskDetailDialogState();
}

class _TaskDetailDialogState extends ConsumerState<TaskDetailDialog> {
  late Task _editedTask;
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _assigneeController;
  late TextEditingController _blockerController;
  late TextEditingController _questionController;
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _editedTask = widget.taskWithProject.task;
    _titleController = TextEditingController(text: _editedTask.title);
    _descriptionController = TextEditingController(text: _editedTask.description ?? '');
    _assigneeController = TextEditingController(text: _editedTask.assignee ?? '');
    _blockerController = TextEditingController(text: _editedTask.blockerDescription ?? '');
    _questionController = TextEditingController(text: _editedTask.questionToAsk ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _assigneeController.dispose();
    _blockerController.dispose();
    _questionController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (_titleController.text.isEmpty) {
      ref.read(notificationServiceProvider.notifier).showWarning('Title cannot be empty');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final repository = ref.read(risksTasksRepositoryProvider);

      final updatedTask = _editedTask.copyWith(
        title: _titleController.text,
        description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
        assignee: _assigneeController.text.isEmpty ? null : _assigneeController.text,
        blockerDescription: _blockerController.text.isEmpty ? null : _blockerController.text,
        questionToAsk: _questionController.text.isEmpty ? null : _questionController.text,
        lastUpdated: DateTime.now(),
      );

      await repository.updateTask(_editedTask.id, updatedTask);

      // Force refresh the tasks list (clear cache and invalidate)
      await ref.read(forceRefreshTasksProvider)();

      if (mounted) {
        setState(() {
          _editedTask = updatedTask;
          _isEditing = false;
        });
        ref.read(notificationServiceProvider.notifier).showSuccess('Task updated successfully');
      }
    } catch (e) {
      if (mounted) {
        ref.read(notificationServiceProvider.notifier).showError('Error updating task: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _toggleComplete() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final repository = ref.read(risksTasksRepositoryProvider);

      final newStatus = _editedTask.status == TaskStatus.completed
          ? TaskStatus.todo
          : TaskStatus.completed;

      final updatedTask = _editedTask.copyWith(
        status: newStatus,
        completedDate: newStatus == TaskStatus.completed
            ? DateTime.now()
            : null,
        lastUpdated: DateTime.now(),
      );

      await repository.updateTask(_editedTask.id, updatedTask);

      // Force refresh the tasks list
      await ref.read(forceRefreshTasksProvider)();

      if (mounted) {
        setState(() {
          _editedTask = updatedTask;
        });
        ref.read(notificationServiceProvider.notifier).showSuccess(
          newStatus == TaskStatus.completed
              ? 'Task marked as completed'
              : 'Task marked as incomplete'
        );
      }
    } catch (e) {
      if (mounted) {
        ref.read(notificationServiceProvider.notifier).showError('Error updating task: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _startWorking() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final repository = ref.read(risksTasksRepositoryProvider);

      final updatedTask = _editedTask.copyWith(
        status: TaskStatus.inProgress,
        lastUpdated: DateTime.now(),
      );

      await repository.updateTask(_editedTask.id, updatedTask);

      // Force refresh the tasks list
      await ref.read(forceRefreshTasksProvider)();

      if (mounted) {
        setState(() {
          _editedTask = updatedTask;
        });
        ref.read(notificationServiceProvider.notifier).showSuccess('Task marked as in progress');
      }
    } catch (e) {
      if (mounted) {
        ref.read(notificationServiceProvider.notifier).showError('Error updating task: $e');
      }
    } finally{
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _markAsBlocked() async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    // Show dialog to get blocker description
    final blockerDescription = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        String description = '';
        return Dialog(
          insetPadding: isMobile
              ? const EdgeInsets.symmetric(horizontal: 16, vertical: 24)
              : const EdgeInsets.symmetric(horizontal: 40.0, vertical: 24.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isMobile ? double.infinity : 450,
              minWidth: isMobile ? 0 : 350,
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
                          onPressed: () => Navigator.of(dialogContext).pop(),
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
                          onChanged: (value) => description = value,
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
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 12),
                        FilledButton(
                          onPressed: () => Navigator.of(dialogContext).pop(description),
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

    if (blockerDescription == null || blockerDescription.isEmpty) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final repository = ref.read(risksTasksRepositoryProvider);

      final updatedTask = _editedTask.copyWith(
        status: TaskStatus.blocked,
        blockerDescription: blockerDescription,
        lastUpdated: DateTime.now(),
      );

      await repository.updateTask(_editedTask.id, updatedTask);

      // Force refresh the tasks list
      await ref.read(forceRefreshTasksProvider)();

      if (mounted) {
        setState(() {
          _editedTask = updatedTask;
          _blockerController.text = blockerDescription;
        });
        ref.read(notificationServiceProvider.notifier).showSuccess('Task marked as blocked');
      }
    } catch (e) {
      if (mounted) {
        ref.read(notificationServiceProvider.notifier).showError('Error updating task: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _deleteTask() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final repository = ref.read(risksTasksRepositoryProvider);
      await repository.deleteTask(_editedTask.id);

      // Force refresh the tasks list (clear cache and invalidate)
      await ref.read(forceRefreshTasksProvider)();

      if (mounted) {
        Navigator.of(context).pop();
        ref.read(notificationServiceProvider.notifier).showSuccess('Task deleted successfully');
      }
    } catch (e) {
      if (mounted) {
        ref.read(notificationServiceProvider.notifier).showError('Error deleting task: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _selectDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _editedTask.dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );

    if (date != null) {
      setState(() {
        _editedTask = _editedTask.copyWith(dueDate: date);
      });
    }
  }


  String _buildTaskContext(Task task) {
    return '''Task Details:
- Status: ${task.status.name}
- Priority: ${task.priority.name}
- Description: ${task.description ?? 'No description'}${task.assignee != null ? '\n- Assigned to: ${task.assignee}' : ''}${task.dueDate != null ? '\n- Due Date: ${task.dueDate!.toIso8601String().split('T')[0]}' : ''}${task.progressPercentage > 0 ? '\n- Progress: ${task.progressPercentage}%' : ''}${task.blockerDescription != null ? '\n- Blocker: ${task.blockerDescription}' : ''}${task.questionToAsk != null ? '\n- Question: ${task.questionToAsk}' : ''}''';
  }

  void _openAIDialog() {
    // Build the task context that will be prepended invisibly
    final taskContext = '''Context: Analyzing a task in the project.
Task Title: ${_editedTask.title}
${_buildTaskContext(_editedTask)}''';

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      transitionDuration: Duration.zero,
      pageBuilder: (context, animation, secondaryAnimation) {
        return AskAIPanel(
          projectId: widget.taskWithProject.project.id,
          projectName: widget.taskWithProject.project.name,
          contextInfo: taskContext,
          conversationId: 'task_${_editedTask.id}', // Unique ID for this task's conversation
          rightOffset: 0.0,  // Keep panel at right edge
          onClose: () {
            Navigator.of(context).pop();
            ref.read(queryProvider.notifier).clearConversation();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Padding(
      padding: isMobile ? EdgeInsets.zero : const EdgeInsets.only(right: 100), // Add padding to push dialog left on desktop
      child: Dialog(
      insetPadding: isMobile
          ? const EdgeInsets.symmetric(horizontal: 8, vertical: 24)
          : const EdgeInsets.symmetric(horizontal: 40.0, vertical: 24.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isMobile ? double.infinity : 600,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
          minWidth: isMobile ? 0 : 400,
        ),
        child: IntrinsicHeight(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            // Header
            Container(
              padding: EdgeInsets.all(isMobile ? 12 : 20),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: isMobile
                ? Row(
                    children: [
                      Icon(
                        Icons.task_alt,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _isEditing ? 'Edit Task' : 'Task Details',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (!_isEditing) ...[
                        // Dynamic primary action based on status
                        if (_editedTask.status == TaskStatus.todo)
                          IconButton(
                            icon: const Icon(Icons.play_arrow),
                            onPressed: _isSaving ? null : _startWorking,
                            tooltip: 'Start Task',
                            iconSize: isMobile ? 20 : 24,
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.blue.withValues(alpha: 0.1),
                              foregroundColor: Colors.blue,
                            ),
                          )
                        else if (_editedTask.status == TaskStatus.blocked)
                          IconButton(
                            icon: const Icon(Icons.play_arrow),
                            iconSize: isMobile ? 20 : 24,
                            onPressed: _isSaving
                                ? null
                                : () async {
                                    // Unblock and set to in progress
                                    setState(() {
                                      _isSaving = true;
                                    });
                                    try {
                                      final repository = ref.read(risksTasksRepositoryProvider);
                                      final updatedTask = _editedTask.copyWith(
                                        status: TaskStatus.inProgress,
                                        blockerDescription: null,
                                        lastUpdated: DateTime.now(),
                                      );
                                      await repository.updateTask(_editedTask.id, updatedTask);
                                      await ref.read(forceRefreshTasksProvider)();
                                      if (mounted) {
                                        setState(() {
                                          _editedTask = updatedTask;
                                          _blockerController.clear();
                                        });
                                        if (!context.mounted) return;
                                        ref.read(notificationServiceProvider.notifier).showSuccess('Task unblocked and marked as in progress');
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        if (!context.mounted) return;
                                        ref.read(notificationServiceProvider.notifier).showError('Error updating task: $e');
                                      }
                                    } finally {
                                      if (mounted) {
                                        setState(() {
                                          _isSaving = false;
                                        });
                                      }
                                    }
                                  },
                            tooltip: 'Resume Task',
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.green.withValues(alpha: 0.1),
                              foregroundColor: Colors.green,
                            ),
                          )
                        else if (_editedTask.status == TaskStatus.inProgress)
                          IconButton(
                            icon: const Icon(Icons.block),
                            onPressed: _isSaving ? null : _markAsBlocked,
                            tooltip: 'Block Task',
                            iconSize: isMobile ? 20 : 24,
                            style: IconButton.styleFrom(
                              foregroundColor: Colors.orange,
                            ),
                          ),

                        // Complete/Incomplete toggle
                        IconButton(
                          icon: Icon(
                            _editedTask.status == TaskStatus.completed
                                ? Icons.check_circle
                                : Icons.check_circle_outline,
                          ),
                          onPressed: _isSaving ? null : _toggleComplete,
                          tooltip: _editedTask.status == TaskStatus.completed
                              ? 'Mark as incomplete'
                              : 'Mark as complete',
                          iconSize: isMobile ? 20 : 24,
                          style: IconButton.styleFrom(
                            foregroundColor: _editedTask.status == TaskStatus.completed
                                ? Colors.green
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),

                        // More actions menu (Edit moved inside for mobile)
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          tooltip: 'More actions',
                          iconSize: 20,
                          offset: const Offset(0, 40),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 8,
                          onSelected: (value) {
                            switch (value) {
                              case 'edit':
                                setState(() {
                                  _isEditing = true;
                                });
                                break;
                              case 'delete':
                                _deleteTask();
                                break;
                            }
                          },
                          itemBuilder: (BuildContext context) => [
                            PopupMenuItem<String>(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit_outlined, size: 20, color: colorScheme.primary),
                                  const SizedBox(width: 12),
                                  const Text('Edit'),
                                ],
                              ),
                            ),
                            const PopupMenuDivider(),
                            const PopupMenuItem<String>(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                  SizedBox(width: 12),
                                  Text('Delete', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        ),

                        if (!isMobile) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 1,
                            height: 24,
                            color: colorScheme.outline.withValues(alpha: 0.2),
                          ),
                          const SizedBox(width: 8),
                        ],

                        // AI Assistant button
                        IconButton(
                          onPressed: _openAIDialog,
                          icon: const Icon(Icons.auto_awesome),
                          tooltip: 'AI Assistant',
                          iconSize: 20,
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.green.withValues(alpha: 0.1),
                            foregroundColor: Colors.green,
                          ),
                        ),
                      ],
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                        iconSize: 20,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  )
              : Row(
                  children: [
                    Icon(
                      Icons.task_alt,
                      color: colorScheme.primary,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isEditing ? 'Edit Task' : 'Task Details',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            widget.taskWithProject.project.name,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!_isEditing) ...[
                      // Primary Action Buttons Row
                      Row(
                        children: [
                          // Dynamic primary action based on status
                          if (_editedTask.status == TaskStatus.todo)
                            IconButton(
                              icon: const Icon(Icons.play_arrow),
                              onPressed: _isSaving ? null : _startWorking,
                              tooltip: 'Start Task',
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.blue.withValues(alpha: 0.1),
                                foregroundColor: Colors.blue,
                              ),
                            )
                          else if (_editedTask.status == TaskStatus.blocked)
                            IconButton(
                              icon: const Icon(Icons.play_arrow),
                              onPressed: _isSaving
                                  ? null
                                  : () async {
                                      // Unblock and set to in progress
                                      setState(() {
                                        _isSaving = true;
                                      });
                                      try {
                                        final repository = ref.read(risksTasksRepositoryProvider);
                                        final updatedTask = _editedTask.copyWith(
                                          status: TaskStatus.inProgress,
                                          blockerDescription: null,
                                          lastUpdated: DateTime.now(),
                                        );
                                        await repository.updateTask(_editedTask.id, updatedTask);
                                        await ref.read(forceRefreshTasksProvider)();
                                        if (mounted) {
                                          setState(() {
                                            _editedTask = updatedTask;
                                            _blockerController.clear();
                                          });
                                          if (!context.mounted) return;
                                          ref.read(notificationServiceProvider.notifier).showSuccess('Task unblocked and marked as in progress');
                                        }
                                      } catch (e) {
                                        if (mounted) {
                                          if (!context.mounted) return;
                                          ref.read(notificationServiceProvider.notifier).showError('Error updating task: $e');
                                        }
                                      } finally {
                                        if (mounted) {
                                          setState(() {
                                            _isSaving = false;
                                          });
                                        }
                                      }
                                    },
                              tooltip: 'Resume Task',
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.green.withValues(alpha: 0.1),
                                foregroundColor: Colors.green,
                              ),
                            )
                          else if (_editedTask.status == TaskStatus.inProgress)
                            IconButton(
                              icon: const Icon(Icons.block),
                              onPressed: _isSaving ? null : _markAsBlocked,
                              tooltip: 'Block Task',
                              style: IconButton.styleFrom(
                                foregroundColor: Colors.orange,
                              ),
                            ),

                          // Complete/Incomplete toggle
                          IconButton(
                            icon: Icon(
                              _editedTask.status == TaskStatus.completed
                                  ? Icons.check_circle
                                  : Icons.check_circle_outline,
                            ),
                            onPressed: _isSaving ? null : _toggleComplete,
                            tooltip: _editedTask.status == TaskStatus.completed
                                ? 'Mark as incomplete'
                                : 'Mark as complete',
                            style: IconButton.styleFrom(
                              foregroundColor: _editedTask.status == TaskStatus.completed
                                  ? Colors.green
                                  : colorScheme.onSurfaceVariant,
                            ),
                          ),

                          // More actions menu
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert),
                            tooltip: 'More actions',
                            offset: const Offset(0, 45),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 8,
                            onSelected: (value) {
                              switch (value) {
                                case 'edit':
                                  setState(() {
                                    _isEditing = true;
                                  });
                                  break;
                                case 'delete':
                                  _deleteTask();
                                  break;
                              }
                            },
                            itemBuilder: (BuildContext context) => [
                              PopupMenuItem<String>(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit_outlined, size: 20, color: colorScheme.primary),
                                    const SizedBox(width: 12),
                                    const Text('Edit'),
                                  ],
                                ),
                              ),
                              const PopupMenuDivider(),
                              const PopupMenuItem<String>(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                    SizedBox(width: 12),
                                    Text('Delete', style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(width: 8),
                      Container(
                        width: 1,
                        height: 24,
                        color: colorScheme.outline.withValues(alpha: 0.2),
                      ),
                      const SizedBox(width: 8),

                      // AI Assistant button
                      IconButton(
                        onPressed: _openAIDialog,
                        icon: const Icon(Icons.auto_awesome),
                        tooltip: 'AI Assistant',
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.green.withValues(alpha: 0.1),
                          foregroundColor: Colors.green,
                        ),
                      ),
                    ],
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isMobile ? 12 : 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    if (_isEditing)
                      TextField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'Title',
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
                              color: colorScheme.primary.withValues(alpha: 0.5),
                            ),
                          ),
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        ),
                        style: theme.textTheme.titleMedium,
                      )
                    else
                      Text(
                        _editedTask.title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                    SizedBox(height: isMobile ? 16 : 20),

                    // Status and Priority Row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Status',
                                style: theme.textTheme.labelLarge,
                              ),
                              const SizedBox(height: 8),
                              if (_isEditing)
                                DropdownButtonFormField<TaskStatus>(
                                  initialValue: _editedTask.status,
                                  decoration: InputDecoration(
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
                                        color: colorScheme.primary.withValues(alpha: 0.5),
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                  items: TaskStatus.values.map((status) {
                                    return DropdownMenuItem(
                                      value: status,
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 12,
                                            height: 12,
                                            decoration: BoxDecoration(
                                              color: TaskUIHelpers.getStatusColor(status, Theme.of(context).colorScheme),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(_editedTask.copyWith(status: status).statusLabel),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        _editedTask = _editedTask.copyWith(
                                          status: value,
                                          completedDate: value == TaskStatus.completed
                                              ? DateTime.now()
                                              : null,
                                        );
                                      });
                                    }
                                  },
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: TaskUIHelpers.getStatusColor(_editedTask.status, Theme.of(context).colorScheme)
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: TaskUIHelpers.getStatusColor(_editedTask.status, Theme.of(context).colorScheme),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: TaskUIHelpers.getStatusColor(_editedTask.status, Theme.of(context).colorScheme),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _editedTask.statusLabel,
                                        style: TextStyle(
                                          color: TaskUIHelpers.getStatusColor(_editedTask.status, Theme.of(context).colorScheme),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        SizedBox(width: isMobile ? 12 : 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Priority',
                                style: theme.textTheme.labelLarge,
                              ),
                              const SizedBox(height: 8),
                              if (_isEditing)
                                DropdownButtonFormField<TaskPriority>(
                                  initialValue: _editedTask.priority,
                                  decoration: InputDecoration(
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
                                        color: colorScheme.primary.withValues(alpha: 0.5),
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                  items: TaskPriority.values.map((priority) {
                                    return DropdownMenuItem(
                                      value: priority,
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.flag,
                                            size: 16,
                                            color: TaskUIHelpers.getPriorityColor(priority),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(_editedTask.copyWith(priority: priority).priorityLabel),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        _editedTask = _editedTask.copyWith(priority: value);
                                      });
                                    }
                                  },
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: TaskUIHelpers.getPriorityColor(_editedTask.priority)
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.flag,
                                        size: 16,
                                        color: TaskUIHelpers.getPriorityColor(_editedTask.priority),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _editedTask.priorityLabel,
                                        style: TextStyle(
                                          color: TaskUIHelpers.getPriorityColor(_editedTask.priority),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: isMobile ? 16 : 20),

                    // Description
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Description',
                          style: theme.textTheme.labelLarge,
                        ),
                        const SizedBox(height: 8),
                        if (_isEditing)
                          TextField(
                            controller: _descriptionController,
                            decoration: InputDecoration(
                              hintText: 'Enter task description...',
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
                                  color: colorScheme.primary.withValues(alpha: 0.5),
                                ),
                              ),
                              filled: true,
                              fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                            ),
                            maxLines: 3,
                          )
                        else
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _editedTask.description ?? 'No description',
                              style: TextStyle(
                                color: _editedTask.description == null
                                    ? colorScheme.onSurfaceVariant
                                    : null,
                              ),
                            ),
                          ),
                      ],
                    ),

                    // Question to Ask (if exists)
                    if (_editedTask.questionToAsk != null || _isEditing) ...[
                      SizedBox(height: isMobile ? 16 : 20),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Question to Ask',
                            style: theme.textTheme.labelLarge,
                          ),
                          const SizedBox(height: 8),
                          if (_isEditing)
                            TextField(
                              controller: _questionController,
                              decoration: InputDecoration(
                                hintText: 'What specific question needs to be asked?',
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
                                    color: colorScheme.primary.withValues(alpha: 0.5),
                                  ),
                                ),
                                filled: true,
                                fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                              ),
                              maxLines: 3,
                            )
                          else
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _editedTask.questionToAsk ?? 'No question to ask',
                                style: TextStyle(
                                  color: _editedTask.questionToAsk == null
                                      ? colorScheme.onSurfaceVariant
                                      : null,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],

                    SizedBox(height: isMobile ? 16 : 20),

                    // Assignee and Due Date Row
                    Flex(
                      direction: isMobile ? Axis.vertical : Axis.horizontal,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: isMobile ? 0 : 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Assignee',
                                style: theme.textTheme.labelLarge,
                              ),
                              const SizedBox(height: 8),
                              if (_isEditing)
                                TextField(
                                  controller: _assigneeController,
                                  decoration: InputDecoration(
                                    hintText: 'Enter assignee name...',
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
                                        color: colorScheme.primary.withValues(alpha: 0.5),
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                    prefixIcon: Icon(
                                      Icons.person,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                )
                              else
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerHighest
                                        .withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.person,
                                        size: 16,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          _editedTask.assignee ?? 'Unassigned',
                                          style: TextStyle(
                                            color: _editedTask.assignee == null
                                                ? colorScheme.onSurfaceVariant
                                                : null,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        SizedBox(width: isMobile ? 0 : 20, height: isMobile ? 12 : 0),
                        Expanded(
                          flex: isMobile ? 0 : 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Due Date',
                                style: theme.textTheme.labelLarge,
                              ),
                              const SizedBox(height: 8),
                              if (_isEditing)
                                InkWell(
                                  onTap: _selectDueDate,
                                  child: InputDecorator(
                                    decoration: InputDecoration(
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
                                          color: colorScheme.primary.withValues(alpha: 0.5),
                                        ),
                                      ),
                                      filled: true,
                                      fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                      prefixIcon: Icon(
                                        Icons.calendar_today,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    child: Text(
                                      _editedTask.dueDate != null
                                          ? DateFormat('MMM d, y').format(_editedTask.dueDate!)
                                          : 'Select due date',
                                      style: TextStyle(
                                        color: _editedTask.dueDate == null
                                            ? colorScheme.onSurfaceVariant
                                            : null,
                                      ),
                                    ),
                                  ),
                                )
                              else
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: _editedTask.isOverdue
                                        ? Colors.red.withValues(alpha: 0.1)
                                        : colorScheme.surfaceContainerHighest
                                            .withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today,
                                        size: 16,
                                        color: _editedTask.isOverdue
                                            ? Colors.red
                                            : colorScheme.onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          _editedTask.dueDate != null
                                              ? DateFormat('MMM d, y').format(_editedTask.dueDate!)
                                              : 'No due date',
                                          style: TextStyle(
                                            color: _editedTask.isOverdue
                                                ? Colors.red
                                                : _editedTask.dueDate == null
                                                    ? colorScheme.onSurfaceVariant
                                                    : null,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (_editedTask.isOverdue) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            'OVERDUE',
                                            style: theme.textTheme.labelSmall?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Progress
                    if (_editedTask.status == TaskStatus.inProgress) ...[
                      SizedBox(height: isMobile ? 16 : 20),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Progress',
                                style: theme.textTheme.labelLarge,
                              ),
                              Text(
                                '${_editedTask.progressPercentage}%',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (_isEditing)
                            Slider(
                              value: _editedTask.progressPercentage.toDouble(),
                              min: 0,
                              max: 100,
                              divisions: 10,
                              label: '${_editedTask.progressPercentage}%',
                              onChanged: (value) {
                                setState(() {
                                  _editedTask = _editedTask.copyWith(
                                    progressPercentage: value.round(),
                                  );
                                });
                              },
                            )
                          else
                            LinearProgressIndicator(
                              value: _editedTask.progressPercentage / 100,
                              minHeight: 8,
                              borderRadius: BorderRadius.circular(4),
                            ),
                        ],
                      ),
                    ],

                    // Blocker Description (if blocked)
                    if (_editedTask.status == TaskStatus.blocked) ...[
                      SizedBox(height: isMobile ? 16 : 20),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Blocker Description',
                            style: theme.textTheme.labelLarge,
                          ),
                          const SizedBox(height: 8),
                          if (_isEditing)
                            TextField(
                              controller: _blockerController,
                              decoration: InputDecoration(
                                hintText: 'Describe what is blocking this task...',
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
                                    color: colorScheme.primary.withValues(alpha: 0.5),
                                  ),
                                ),
                                filled: true,
                                fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                              ),
                              maxLines: 2,
                            )
                          else
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.orange.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.warning_amber,
                                    color: Colors.orange,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _editedTask.blockerDescription ??
                                          'No blocker description provided',
                                      style: TextStyle(
                                        color: _editedTask.blockerDescription == null
                                            ? colorScheme.onSurfaceVariant
                                            : null,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],

                    // Metadata
                    SizedBox(height: isMobile ? 16 : 20),
                    const Divider(),
                    SizedBox(height: isMobile ? 12 : 20),

                    Text(
                      'Metadata',
                      style: theme.textTheme.labelLarge,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        if (_editedTask.createdDate != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.create,
                                size: 14,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Created: ${DateFormat('MMM d, y').format(_editedTask.createdDate!)}',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        if (_editedTask.lastUpdated != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.update,
                                size: 14,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Updated: ${DateFormat('MMM d, y').format(_editedTask.lastUpdated!)}',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        if (_editedTask.completedDate != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check_circle,
                                size: 14,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Completed: ${DateFormat('MMM d, y').format(_editedTask.completedDate!)}',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Actions
            if (_isEditing)
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
                      onPressed: _isSaving
                          ? null
                          : () {
                              setState(() {
                                _isEditing = false;
                                // Reset controllers
                                _titleController.text = widget.taskWithProject.task.title;
                                _descriptionController.text = widget.taskWithProject.task.description ?? '';
                                _assigneeController.text = widget.taskWithProject.task.assignee ?? '';
                                _blockerController.text = widget.taskWithProject.task.blockerDescription ?? '';
                                _questionController.text = widget.taskWithProject.task.questionToAsk ?? '';
                                _editedTask = widget.taskWithProject.task;
                              });
                            },
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _saveChanges,
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save Changes'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}