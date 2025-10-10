import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/task.dart';
import '../providers/risks_tasks_provider.dart';
import '../../../../core/services/notification_service.dart';

class TaskDialog extends ConsumerStatefulWidget {
  final String projectId;
  final String? projectName;
  final Task? task; // null for add, existing task for edit

  const TaskDialog({
    super.key,
    required this.projectId,
    this.projectName,
    this.task,
  });

  @override
  ConsumerState<TaskDialog> createState() => _TaskDialogState();
}

class _TaskDialogState extends ConsumerState<TaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _assigneeController = TextEditingController();
  final _blockerDescriptionController = TextEditingController();
  final _progressController = TextEditingController();

  TaskPriority _selectedPriority = TaskPriority.medium;
  TaskStatus _selectedStatus = TaskStatus.todo;
  DateTime? _selectedDueDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      _titleController.text = widget.task!.title;
      _descriptionController.text = widget.task!.description ?? '';
      _assigneeController.text = widget.task!.assignee ?? '';
      _blockerDescriptionController.text = widget.task!.blockerDescription ?? '';
      _progressController.text = widget.task!.progressPercentage.toString();
      _selectedPriority = widget.task!.priority;
      _selectedStatus = widget.task!.status;
      _selectedDueDate = widget.task!.dueDate;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _assigneeController.dispose();
    _blockerDescriptionController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.task != null;

    return Padding(
      padding: const EdgeInsets.only(right: 100), // Add padding to push dialog left
      child: Dialog(
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.task_alt_rounded,
                    color: Colors.blue,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isEditing ? 'Edit Task' : 'Add Task',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Flexible(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: 'Task Title *',
                            hintText: 'Brief description of the task',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Title is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Description
                        TextFormField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            hintText: 'Detailed description of the task',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),

                        // Priority and Status
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<TaskPriority>(
                                initialValue: _selectedPriority,
                                decoration: const InputDecoration(
                                  labelText: 'Priority',
                                  border: OutlineInputBorder(),
                                ),
                                items: TaskPriority.values.map((priority) {
                                  return DropdownMenuItem(
                                    value: priority,
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: _getPriorityColor(priority),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(_getPriorityLabel(priority)),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      _selectedPriority = value;
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<TaskStatus>(
                                initialValue: _selectedStatus,
                                decoration: const InputDecoration(
                                  labelText: 'Status',
                                  border: OutlineInputBorder(),
                                ),
                                items: TaskStatus.values.map((status) {
                                  return DropdownMenuItem(
                                    value: status,
                                    child: Text(_getStatusLabel(status)),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      _selectedStatus = value;
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Assignee and Progress
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _assigneeController,
                                decoration: const InputDecoration(
                                  labelText: 'Assignee',
                                  hintText: 'Who is responsible for this task',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.person),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _progressController,
                                decoration: const InputDecoration(
                                  labelText: 'Progress (%)',
                                  hintText: '0-100',
                                  border: OutlineInputBorder(),
                                  suffixText: '%',
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value != null && value.isNotEmpty) {
                                    final progress = int.tryParse(value);
                                    if (progress == null || progress < 0 || progress > 100) {
                                      return 'Must be between 0 and 100';
                                    }
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Due Date
                        InkWell(
                          onTap: _selectDueDate,
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Due Date',
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(Icons.calendar_today),
                            ),
                            child: Text(
                              _selectedDueDate != null
                                  ? '${_selectedDueDate!.day}/${_selectedDueDate!.month}/${_selectedDueDate!.year}'
                                  : 'Select due date (optional)',
                              style: TextStyle(
                                color: _selectedDueDate != null
                                    ? Theme.of(context).textTheme.bodyMedium?.color
                                    : Theme.of(context).hintColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Blocker Description (only if status is blocked)
                        if (_selectedStatus == TaskStatus.blocked) ...[
                          TextFormField(
                            controller: _blockerDescriptionController,
                            decoration: const InputDecoration(
                              labelText: 'Blocker Description *',
                              hintText: 'What is blocking this task?',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.block),
                            ),
                            maxLines: 2,
                            validator: (value) {
                              if (_selectedStatus == TaskStatus.blocked &&
                                  (value == null || value.trim().isEmpty)) {
                                return 'Blocker description is required when status is blocked';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (isEditing) ...[
                    TextButton(
                      onPressed: _isLoading ? null : _showDeleteConfirmation,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      child: const Text('Delete'),
                    ),
                    const SizedBox(width: 8),
                  ],
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveTask,
                    child: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(isEditing ? 'Update' : 'Add'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  Future<void> _selectDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDueDate = picked;
      });
    }
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final task = Task(
        id: widget.task?.id ?? '',
        projectId: widget.projectId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        priority: _selectedPriority,
        status: _selectedStatus,
        assignee: _assigneeController.text.trim().isEmpty
            ? null
            : _assigneeController.text.trim(),
        dueDate: _selectedDueDate,
        progressPercentage: _progressController.text.trim().isEmpty
            ? 0
            : int.tryParse(_progressController.text.trim()) ?? 0,
        blockerDescription: _blockerDescriptionController.text.trim().isEmpty
            ? null
            : _blockerDescriptionController.text.trim(),
      );

      final notifier = ref.read(tasksNotifierProvider(widget.projectId).notifier);

      if (widget.task == null) {
        await notifier.addTask(task);
      } else {
        await notifier.updateTask(task);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ref.read(notificationServiceProvider.notifier).showSuccess(
          widget.task == null ? 'Task added successfully' : 'Task updated successfully'
        );
      }
    } catch (e) {
      if (mounted) {
        ref.read(notificationServiceProvider.notifier).showError('Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showDeleteConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text('Are you sure you want to delete this task? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && widget.task != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        final notifier = ref.read(tasksNotifierProvider(widget.projectId).notifier);
        await notifier.deleteTask(widget.task!.id);

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
            _isLoading = false;
          });
        }
      }
    }
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

  String _getPriorityLabel(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.high:
        return 'High';
      case TaskPriority.urgent:
        return 'Urgent';
    }
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
}