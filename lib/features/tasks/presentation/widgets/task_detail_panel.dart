import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/widgets/dialogs/enhanced_confirmation_dialog.dart';
import '../../../projects/domain/entities/task.dart';
import '../../../projects/presentation/providers/risks_tasks_provider.dart';
import '../../../projects/presentation/providers/projects_provider.dart';
import '../../../projects/presentation/providers/item_updates_provider.dart';
import '../providers/aggregated_tasks_provider.dart';
import '../utils/task_ui_helpers.dart';
import '../../../queries/presentation/widgets/ask_ai_panel.dart';
import '../../../queries/presentation/providers/query_provider.dart';
import '../../../../shared/widgets/item_detail_panel.dart';
import '../../../../shared/widgets/item_updates_tab.dart';
import '../../../projects/domain/entities/item_update.dart' as domain;

class TaskDetailPanel extends ConsumerStatefulWidget {
  final TaskWithProject? taskWithProject; // null for creating new task
  final String? projectId; // Required when creating new task
  final String? projectName; // Required when creating new task
  final bool initiallyInEditMode;

  const TaskDetailPanel({
    super.key,
    this.taskWithProject,
    this.projectId,
    this.projectName,
    this.initiallyInEditMode = false,
  });

  @override
  ConsumerState<TaskDetailPanel> createState() => _TaskDetailPanelState();
}

class _TaskDetailPanelState extends ConsumerState<TaskDetailPanel> {
  late Task? _editedTask;
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _assigneeController;
  late TextEditingController _blockerController;
  late TextEditingController _questionController;
  late TaskStatus _selectedStatus;
  late TaskPriority _selectedPriority;
  late String? _selectedProjectId; // Track selected project
  DateTime? _selectedDueDate; // Track due date for new tasks separately
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _editedTask = widget.taskWithProject?.task;
    _isEditing = widget.initiallyInEditMode || widget.taskWithProject == null;

    _titleController = TextEditingController(text: _editedTask?.title ?? '');
    _descriptionController = TextEditingController(text: _editedTask?.description ?? '');
    _assigneeController = TextEditingController(text: _editedTask?.assignee ?? '');
    _blockerController = TextEditingController(text: _editedTask?.blockerDescription ?? '');
    _questionController = TextEditingController(text: _editedTask?.questionToAsk ?? '');
    _selectedStatus = _editedTask?.status ?? TaskStatus.todo;
    _selectedPriority = _editedTask?.priority ?? TaskPriority.medium;

    // Initialize selected project ID from existing task OR from widget params (when creating from specific project)
    _selectedProjectId = widget.taskWithProject?.project.id ?? widget.projectId;

    // Initialize due date (for existing tasks)
    _selectedDueDate = _editedTask?.dueDate;
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

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
      if (_isEditing && _editedTask != null) {
        // Reset form to current task values when entering edit mode
        _titleController.text = _editedTask!.title;
        _descriptionController.text = _editedTask!.description ?? '';
        _assigneeController.text = _editedTask!.assignee ?? '';
        _blockerController.text = _editedTask!.blockerDescription ?? '';
        _questionController.text = _editedTask!.questionToAsk ?? '';
        _selectedStatus = _editedTask!.status;
        _selectedPriority = _editedTask!.priority;
      }
    });
  }

  void _cancelEdit() {
    if (_editedTask == null) {
      // If creating new, close the panel
      Navigator.of(context).pop();
    } else {
      // If editing existing, just exit edit mode
      setState(() {
        _isEditing = false;
      });
    }
  }

  Future<void> _saveChanges() async {
    if (_titleController.text.trim().isEmpty) {
      ref.read(notificationServiceProvider.notifier).showWarning('Title cannot be empty');
      return;
    }

    if (_selectedProjectId == null || _selectedProjectId!.isEmpty) {
      ref.read(notificationServiceProvider.notifier).showWarning('Please select a project');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final repository = ref.read(risksTasksRepositoryProvider);
      final projectIdToUse = _selectedProjectId!;

      final taskToSave = Task(
        id: _editedTask?.id ?? const Uuid().v4(),
        projectId: projectIdToUse,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        status: _selectedStatus,
        priority: _selectedPriority,
        assignee: _assigneeController.text.trim().isEmpty ? null : _assigneeController.text.trim(),
        blockerDescription: _blockerController.text.trim().isEmpty ? null : _blockerController.text.trim(),
        questionToAsk: _questionController.text.trim().isEmpty ? null : _questionController.text.trim(),
        dueDate: _selectedDueDate,
        progressPercentage: _editedTask?.progressPercentage ?? 0,
        createdDate: _editedTask?.createdDate ?? DateTime.now(),
        lastUpdated: DateTime.now(),
        completedDate: _selectedStatus == TaskStatus.completed ? (_editedTask?.completedDate ?? DateTime.now()) : null,
        aiGenerated: false,
      );

      if (_editedTask == null) {
        // Creating new task
        await repository.createTask(projectIdToUse, taskToSave);
        await ref.read(forceRefreshTasksProvider)();
        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        // Updating existing task
        await repository.updateTask(_editedTask!.id, taskToSave);
        await ref.read(forceRefreshTasksProvider)();
        if (mounted) {
          // Refresh the updates provider to get the new updates
          final params = ItemUpdatesParams(
            projectId: _selectedProjectId!,
            itemId: _editedTask!.id,
            itemType: 'tasks',
          );
          ref.invalidate(itemUpdatesNotifierProvider(params));

          setState(() {
            _editedTask = taskToSave;
            _isEditing = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ref.read(notificationServiceProvider.notifier).showError('Error saving task: $e');
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
    if (_editedTask == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final repository = ref.read(risksTasksRepositoryProvider);
      final task = _editedTask!;
      final newStatus = task.status == TaskStatus.completed
          ? TaskStatus.todo
          : TaskStatus.completed;

      final updatedTask = task.copyWith(
        status: newStatus,
        completedDate: newStatus == TaskStatus.completed ? DateTime.now() : null,
        lastUpdated: DateTime.now(),
      );

      await repository.updateTask(task.id, updatedTask);
      await ref.read(forceRefreshTasksProvider)();

      if (mounted) {
        // Refresh the updates provider to get the new updates
        final params = ItemUpdatesParams(
          projectId: _selectedProjectId ?? widget.taskWithProject!.project.id,
          itemId: task.id,
          itemType: 'tasks',
        );
        ref.invalidate(itemUpdatesNotifierProvider(params));

        setState(() {
          _editedTask = updatedTask;
        });
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
    if (_editedTask == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final repository = ref.read(risksTasksRepositoryProvider);
      final task = _editedTask!;
      final updatedTask = task.copyWith(
        status: TaskStatus.inProgress,
        lastUpdated: DateTime.now(),
      );

      await repository.updateTask(task.id, updatedTask);
      await ref.read(forceRefreshTasksProvider)();

      if (mounted) {
        // Refresh the updates provider to get the new updates
        final params = ItemUpdatesParams(
          projectId: _selectedProjectId ?? widget.taskWithProject!.project.id,
          itemId: task.id,
          itemType: 'tasks',
        );
        ref.invalidate(itemUpdatesNotifierProvider(params));

        setState(() {
          _editedTask = updatedTask;
        });
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

  Future<void> _markAsBlocked() async {
    if (_editedTask == null) return;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final blockerDescription = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        String description = '';
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450, minWidth: 350),
            child: IntrinsicHeight(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                        const Icon(Icons.block, color: Colors.orange, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text('Mark as Blocked',
                              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        ),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(dialogContext).pop()),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Blocker Description *',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          autofocus: true,
                          decoration: InputDecoration(
                            hintText: 'What is blocking this task?',
                            hintStyle: TextStyle(
                              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: colorScheme.primary,
                                width: 1.5,
                              ),
                            ),
                            filled: true,
                            fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
                            contentPadding: const EdgeInsets.all(16),
                          ),
                          maxLines: 3,
                          onChanged: (value) => description = value,
                        ),
                      ],
                    ),
                  ),
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
                        TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
                        const SizedBox(width: 12),
                        FilledButton(
                          onPressed: () => Navigator.of(dialogContext).pop(description),
                          style: FilledButton.styleFrom(backgroundColor: Colors.orange),
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

    if (blockerDescription == null || blockerDescription.isEmpty) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final repository = ref.read(risksTasksRepositoryProvider);
      final task = _editedTask!;
      final updatedTask = task.copyWith(
        status: TaskStatus.blocked,
        blockerDescription: blockerDescription,
        lastUpdated: DateTime.now(),
      );

      await repository.updateTask(task.id, updatedTask);
      await ref.read(forceRefreshTasksProvider)();

      if (mounted) {
        setState(() {
          _editedTask = updatedTask;
          _blockerController.text = blockerDescription;
        });
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

  Future<void> _unblockTask() async {
    if (_editedTask == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final repository = ref.read(risksTasksRepositoryProvider);
      final task = _editedTask!;
      final updatedTask = task.copyWith(
        status: TaskStatus.inProgress,
        blockerDescription: null,
        lastUpdated: DateTime.now(),
      );

      await repository.updateTask(task.id, updatedTask);
      await ref.read(forceRefreshTasksProvider)();

      if (mounted) {
        setState(() {
          _editedTask = updatedTask;
          _blockerController.clear();
        });
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
    if (_editedTask == null) return;

    final confirm = await EnhancedConfirmationDialog.show(
      context: context,
      title: 'Delete Task',
      message: 'Are you sure you want to delete this task?',
      severity: ConfirmationSeverity.danger,
      confirmText: 'Delete',
      showUndoHint: true,
    );

    if (!confirm) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final repository = ref.read(risksTasksRepositoryProvider);
      await repository.deleteTask(_editedTask!.id);
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
      initialDate: _selectedDueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );

    if (date != null) {
      setState(() {
        _selectedDueDate = date;
        // Update _editedTask if it exists
        if (_editedTask != null) {
          _editedTask = _editedTask!.copyWith(dueDate: date);
        }
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
    if (_editedTask == null) return;

    final task = _editedTask!;
    final taskContext = '''Context: Analyzing a task in the project.
Task Title: ${task.title}
${_buildTaskContext(task)}''';

    final projectId = widget.taskWithProject?.project.id ?? widget.projectId!;
    final projectName = widget.taskWithProject?.project.name ?? widget.projectName!;

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      transitionDuration: Duration.zero,
      pageBuilder: (context, animation, secondaryAnimation) {
        return AskAIPanel(
          projectId: projectId,
          projectName: projectName,
          contextInfo: taskContext,
          conversationId: 'task_${task.id}',
          rightOffset: 0.0,
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
    final colorScheme = Theme.of(context).colorScheme;
    final isCreating = _editedTask == null;
    final projectName = widget.taskWithProject?.project.name ?? widget.projectName ?? 'Project';

    // Get comment count for the badge
    int? commentCount;
    if (_editedTask != null && _selectedProjectId != null) {
      final params = ItemUpdatesParams(
        projectId: _selectedProjectId!,
        itemId: _editedTask!.id,
        itemType: 'tasks',
      );
      final updatesAsync = ref.watch(itemUpdatesNotifierProvider(params));
      commentCount = updatesAsync.when(
        data: (updates) => updates.where((u) => u.type == domain.ItemUpdateType.comment).length,
        loading: () => null,
        error: (_, _) => null,
      );
    }

    return ItemDetailPanel(
      title: isCreating ? 'Create New Task' : (_editedTask?.title ?? 'Task'),
      subtitle: projectName,
      headerIcon: Icons.task_alt,
      headerIconColor: _editedTask != null
          ? TaskUIHelpers.getStatusColor(_editedTask!.status, colorScheme)
          : Colors.blue,
      onClose: () => Navigator.of(context).pop(),
      commentCount: commentCount,
      headerActions: _isEditing ? [
        // Edit mode actions
        TextButton(
          onPressed: _isSaving ? null : _cancelEdit,
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: _isSaving ? null : _saveChanges,
          icon: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save, size: 18),
          label: Text(_isSaving ? 'Saving...' : (isCreating ? 'Create' : 'Save')),
        ),
      ] : [
        // View mode actions (only show if not creating)
        if (!isCreating && _editedTask != null) ...[
          // Dynamic primary action based on status
          if (_editedTask!.status == TaskStatus.todo)
            IconButton(
              icon: const Icon(Icons.play_arrow),
              onPressed: _isSaving ? null : _startWorking,
              tooltip: 'Start Task',
            )
          else if (_editedTask!.status == TaskStatus.blocked)
            IconButton(
              icon: const Icon(Icons.play_arrow),
              onPressed: _isSaving ? null : _unblockTask,
              tooltip: 'Resume Task',
            )
          else if (_editedTask!.status == TaskStatus.inProgress)
            IconButton(
              icon: const Icon(Icons.block),
              onPressed: _isSaving ? null : _markAsBlocked,
              tooltip: 'Block Task',
            ),

          // Complete/Incomplete toggle
          IconButton(
            icon: Icon(
              _editedTask!.status == TaskStatus.completed ? Icons.check_circle : Icons.check_circle_outline,
            ),
            onPressed: _isSaving ? null : _toggleComplete,
            tooltip: _editedTask!.status == TaskStatus.completed ? 'Mark as incomplete' : 'Mark as complete',
          ),

          // More actions menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'More actions',
            offset: const Offset(0, 45),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  _toggleEditMode();
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
          ),
        ],
      ],
      mainViewContent: _buildMainView(context),
      updatesContent: _buildUpdatesTab(),
    );
  }

  Widget _buildMainView(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // In edit mode with null task, show empty form
    // In view mode with null task, show error message
    if (_editedTask == null && !_isEditing) {
      return const Center(child: Text('No task data available'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Project Selection (only show when creating NEW task WITHOUT a preset projectId)
          if (_editedTask == null && widget.projectId == null) ...[
            Consumer(
              builder: (context, ref, child) {
                final projectsAsync = ref.watch(projectsListProvider);
                return projectsAsync.when(
                  loading: () => const CircularProgressIndicator(),
                  error: (error, stack) => Text('Error loading projects: $error'),
                  data: (projects) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Project *',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: _selectedProjectId,
                        decoration: InputDecoration(
                          hintText: 'Select a project',
                          hintStyle: TextStyle(
                            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: colorScheme.primary,
                              width: 1.5,
                            ),
                          ),
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          prefixIcon: Icon(
                            Icons.folder_outlined,
                            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                            size: 20,
                          ),
                        ),
                        items: projects.map((project) {
                          return DropdownMenuItem(
                            value: project.id,
                            child: Text(project.name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedProjectId = value;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a project';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
          ],

          // Title (only show in edit mode)
          if (_isEditing) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Title *',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: 'Enter task title',
                    hintStyle: TextStyle(
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: colorScheme.primary,
                        width: 1.5,
                      ),
                    ),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    prefixIcon: Icon(
                      Icons.label_outline,
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      size: 20,
                    ),
                  ),
                  style: theme.textTheme.bodyLarge,
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],

          // Status and Priority Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_isEditing)
                      DropdownButtonFormField<TaskStatus>(
                        isExpanded: true,
                        initialValue: _selectedStatus,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: colorScheme.primary,
                              width: 1.5,
                            ),
                          ),
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                                    color: TaskUIHelpers.getStatusColor(status, colorScheme),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    status.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedStatus = value;
                              if (_editedTask != null) {
                                _editedTask = _editedTask!.copyWith(
                                  status: value,
                                  completedDate: value == TaskStatus.completed ? DateTime.now() : null,
                                );
                              }
                            });
                          }
                        },
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: TaskUIHelpers.getStatusColor(_editedTask!.status, colorScheme).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: TaskUIHelpers.getStatusColor(_editedTask!.status, colorScheme),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _editedTask!.statusLabel,
                              style: TextStyle(
                                color: TaskUIHelpers.getStatusColor(_editedTask!.status, colorScheme),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Priority',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_isEditing)
                      DropdownButtonFormField<TaskPriority>(
                        isExpanded: true,
                        initialValue: _selectedPriority,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: colorScheme.primary,
                              width: 1.5,
                            ),
                          ),
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                        items: TaskPriority.values.map((priority) {
                          return DropdownMenuItem(
                            value: priority,
                            child: Row(
                              children: [
                                Icon(Icons.flag, size: 16, color: TaskUIHelpers.getPriorityColor(priority)),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    priority.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedPriority = value;
                              if (_editedTask != null) {
                                _editedTask = _editedTask!.copyWith(priority: value);
                              }
                            });
                          }
                        },
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: TaskUIHelpers.getPriorityColor(_editedTask!.priority).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.flag, size: 16, color: TaskUIHelpers.getPriorityColor(_editedTask!.priority)),
                            const SizedBox(width: 8),
                            Text(
                              _editedTask!.priorityLabel,
                              style: TextStyle(
                                color: TaskUIHelpers.getPriorityColor(_editedTask!.priority),
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

          const SizedBox(height: 24),

          // Description
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Description',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.1,
                ),
              ),
              const SizedBox(height: 12),
              if (_isEditing)
                TextField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    hintText: 'Enter task description...',
                    hintStyle: TextStyle(
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: colorScheme.primary,
                        width: 1.5,
                      ),
                    ),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  maxLines: 4,
                )
              else
                _ExpandableTextContainer(
                  text: _editedTask!.description ?? 'No description',
                  colorScheme: colorScheme,
                  showAsPlaceholder: _editedTask!.description == null,
                ),
            ],
          ),

          // Question to Ask (if exists)
          if ((_editedTask?.questionToAsk != null) || _isEditing) ...[
            const SizedBox(height: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Question to Ask',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: 12),
                if (_isEditing)
                  TextField(
                    controller: _questionController,
                    decoration: InputDecoration(
                      hintText: 'What specific question needs to be asked?',
                      hintStyle: TextStyle(
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: colorScheme.primary,
                          width: 1.5,
                        ),
                      ),
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
                      contentPadding: const EdgeInsets.all(16),
                      prefixIcon: Icon(
                        Icons.help_outline,
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                        size: 20,
                      ),
                    ),
                    maxLines: 3,
                  )
                else
                  _ExpandableTextContainer(
                    text: _editedTask!.questionToAsk ?? 'No question to ask',
                    colorScheme: colorScheme,
                    showAsPlaceholder: _editedTask!.questionToAsk == null,
                  ),
              ],
            ),
          ],

          const SizedBox(height: 24),

          // Assignee and Due Date Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Assignee',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_isEditing)
                      TextField(
                        controller: _assigneeController,
                        decoration: InputDecoration(
                          hintText: 'Enter assignee name...',
                          hintStyle: TextStyle(
                            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: colorScheme.primary,
                              width: 1.5,
                            ),
                          ),
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
                          contentPadding: const EdgeInsets.all(16),
                          prefixIcon: Icon(
                            Icons.person,
                            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                            size: 20,
                          ),
                        ),
                      )
                    else
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.person, size: 16, color: colorScheme.onSurfaceVariant),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                _editedTask!.assignee ?? 'Unassigned',
                                style:
                                    TextStyle(color: _editedTask!.assignee == null ? colorScheme.onSurfaceVariant : null),
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
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Due Date',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_isEditing)
                      InkWell(
                        onTap: _selectDueDate,
                        child: InputDecorator(
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: colorScheme.primary,
                                width: 1.5,
                              ),
                            ),
                            filled: true,
                            fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
                            contentPadding: const EdgeInsets.all(16),
                            prefixIcon: Icon(
                              Icons.calendar_today,
                              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                              size: 20,
                            ),
                          ),
                          child: Text(
                            _selectedDueDate != null
                                ? DateFormat('MMM d, y').format(_selectedDueDate!)
                                : 'Select due date',
                            style: TextStyle(
                              color: _selectedDueDate == null
                                  ? colorScheme.onSurfaceVariant.withValues(alpha: 0.6)
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
                          color: _editedTask!.isOverdue
                              ? Colors.red.withValues(alpha: 0.1)
                              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: _editedTask!.isOverdue ? Colors.red : colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                _editedTask!.dueDate != null
                                    ? DateFormat('MMM d, y').format(_editedTask!.dueDate!)
                                    : 'No due date',
                                style: TextStyle(
                                  color: _editedTask!.isOverdue
                                      ? Colors.red
                                      : _editedTask!.dueDate == null
                                          ? colorScheme.onSurfaceVariant
                                          : null,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (_editedTask!.isOverdue) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
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
          if ((_editedTask?.status == TaskStatus.inProgress || _selectedStatus == TaskStatus.inProgress)) ...[
            const SizedBox(height: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Progress', style: theme.textTheme.labelLarge),
                    Text(
                      '${_editedTask?.progressPercentage ?? 0}%',
                      style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_isEditing)
                  Slider(
                    value: (_editedTask?.progressPercentage ?? 0).toDouble(),
                    min: 0,
                    max: 100,
                    divisions: 10,
                    label: '${_editedTask?.progressPercentage ?? 0}%',
                    onChanged: (value) {
                      setState(() {
                        if (_editedTask != null) {
                          _editedTask = _editedTask!.copyWith(progressPercentage: value.round());
                        }
                      });
                    },
                  )
                else
                  LinearProgressIndicator(
                    value: (_editedTask?.progressPercentage ?? 0) / 100,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
              ],
            ),
          ],

          // Blocker Description (if blocked)
          if ((_editedTask?.status == TaskStatus.blocked || _selectedStatus == TaskStatus.blocked)) ...[
            const SizedBox(height: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Blocker Description',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: 12),
                if (_isEditing)
                  TextField(
                    controller: _blockerController,
                    decoration: InputDecoration(
                      hintText: 'Describe what is blocking this task...',
                      hintStyle: TextStyle(
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: colorScheme.primary,
                          width: 1.5,
                        ),
                      ),
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
                      contentPadding: const EdgeInsets.all(16),
                      prefixIcon: Icon(
                        Icons.block,
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                        size: 20,
                      ),
                    ),
                    maxLines: 3,
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _editedTask?.blockerDescription ?? 'No blocker description provided',
                            style: TextStyle(
                                color: _editedTask?.blockerDescription == null ? colorScheme.onSurfaceVariant : null),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],

          // Metadata (only show for existing tasks, not when creating)
          if (_editedTask != null && !_isEditing) ...[
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),
            Text('Metadata', style: theme.textTheme.labelLarge),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                if (_editedTask!.createdDate != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.create, size: 14, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        'Created: ${DateFormat('MMM d, y').format(_editedTask!.createdDate!)}',
                        style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                if (_editedTask!.lastUpdated != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.update, size: 14, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        'Updated: ${DateFormat('MMM d, y').format(_editedTask!.lastUpdated!)}',
                        style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                if (_editedTask!.completedDate != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle, size: 14, color: Colors.green),
                      const SizedBox(width: 4),
                      Text(
                        'Completed: ${DateFormat('MMM d, y').format(_editedTask!.completedDate!)}',
                        style: theme.textTheme.labelSmall?.copyWith(color: Colors.green),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUpdatesTab() {
    if (_editedTask == null || _selectedProjectId == null) {
      return _buildCreateModeEmptyState();
    }

    final params = ItemUpdatesParams(
      projectId: _selectedProjectId!,
      itemId: _editedTask!.id,
      itemType: 'tasks',
    );

    final updatesAsync = ref.watch(itemUpdatesNotifierProvider(params));

    return updatesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error loading updates: $error'),
      ),
      data: (domainUpdates) {
        // Convert domain ItemUpdate to widget ItemUpdate
        final widgetUpdates = domainUpdates.map((domainUpdate) {
          return ItemUpdate(
            id: domainUpdate.id,
            content: domainUpdate.content,
            authorName: domainUpdate.authorName,
            timestamp: domainUpdate.timestamp,
            type: _convertDomainUpdateTypeToWidget(domainUpdate.type),
          );
        }).toList();

        return ItemUpdatesTab(
          updates: widgetUpdates,
          itemType: 'task',
          onAddComment: (content) async {
            try {
              await ref
                  .read(itemUpdatesNotifierProvider(params).notifier)
                  .addComment(content);
              // Success notification disabled per user request
            } catch (e) {
              if (mounted) {
                ref
                    .read(notificationServiceProvider.notifier)
                    .showError('Failed to add comment: $e');
              }
            }
          },
        );
      },
    );
  }

  // Helper method to convert domain ItemUpdateType to widget ItemUpdateType
  ItemUpdateType _convertDomainUpdateTypeToWidget(domain.ItemUpdateType type) {
    switch (type) {
      case domain.ItemUpdateType.comment:
        return ItemUpdateType.comment;
      case domain.ItemUpdateType.statusChange:
        return ItemUpdateType.statusChange;
      case domain.ItemUpdateType.assignment:
        return ItemUpdateType.assignment;
      case domain.ItemUpdateType.edit:
        return ItemUpdateType.edit;
      case domain.ItemUpdateType.created:
        return ItemUpdateType.created;
    }
  }

  Widget _buildCreateModeEmptyState() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated gradient circle with icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.primaryContainer.withValues(alpha: 0.4),
                    colorScheme.secondaryContainer.withValues(alpha: 0.3),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    blurRadius: 32,
                    spreadRadius: 8,
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.surface,
                  ),
                  child: Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 48,
                    color: colorScheme.primary.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Title
            Text(
              'Create Task First',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            // Description
            Text(
              'Save this task to start tracking updates,\ncomments, and activity history',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // Feature hints
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildFeatureHint(
                  theme,
                  colorScheme,
                  Icons.comment_rounded,
                  'Comments',
                  Colors.blue,
                ),
                const SizedBox(width: 24),
                _buildFeatureHint(
                  theme,
                  colorScheme,
                  Icons.history_rounded,
                  'Activity',
                  Colors.purple,
                ),
                const SizedBox(width: 24),
                _buildFeatureHint(
                  theme,
                  colorScheme,
                  Icons.notifications_outlined,
                  'Updates',
                  Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureHint(
    ThemeData theme,
    ColorScheme colorScheme,
    IconData icon,
    String label,
    Color accentColor,
  ) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 24,
            color: accentColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// A widget that displays text with automatic truncation and "read more" functionality
class _ExpandableTextContainer extends StatefulWidget {
  final String text;
  final ColorScheme colorScheme;
  final bool showAsPlaceholder;

  const _ExpandableTextContainer({
    required this.text,
    required this.colorScheme,
    this.showAsPlaceholder = false,
  });

  @override
  State<_ExpandableTextContainer> createState() => _ExpandableTextContainerState();
}

class _ExpandableTextContainerState extends State<_ExpandableTextContainer> {
  bool _isExpanded = false;
  static const int _maxCharacters = 200;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shouldTruncate = widget.text.length > _maxCharacters;
    final displayText = shouldTruncate && !_isExpanded
        ? '${widget.text.substring(0, _maxCharacters)}...'
        : widget.text;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            displayText,
            style: widget.showAsPlaceholder
                ? TextStyle(color: widget.colorScheme.onSurfaceVariant)
                : null,
          ),
          if (shouldTruncate) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isExpanded ? 'Read less' : 'Read more',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: widget.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _isExpanded ? Icons.expand_less : Icons.expand_more,
                      size: 16,
                      color: widget.colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
