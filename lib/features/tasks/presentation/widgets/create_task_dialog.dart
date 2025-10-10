import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/services/notification_service.dart';
import '../../../projects/domain/entities/task.dart';
import '../../../projects/presentation/providers/projects_provider.dart';
import '../../../projects/presentation/providers/risks_tasks_provider.dart';
import '../providers/aggregated_tasks_provider.dart';
import '../utils/task_ui_helpers.dart';

class CreateTaskDialog extends ConsumerStatefulWidget {
  final String? initialProjectId;

  const CreateTaskDialog({
    super.key,
    this.initialProjectId,
  });

  @override
  ConsumerState<CreateTaskDialog> createState() => _CreateTaskDialogState();
}

class _CreateTaskDialogState extends ConsumerState<CreateTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _assigneeController = TextEditingController();

  String? _selectedProjectId;
  TaskStatus _selectedStatus = TaskStatus.todo;
  TaskPriority _selectedPriority = TaskPriority.medium;
  DateTime? _selectedDueDate;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _selectedProjectId = widget.initialProjectId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _assigneeController.dispose();
    super.dispose();
  }

  Future<void> _selectDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );

    if (date != null) {
      setState(() {
        _selectedDueDate = date;
      });
    }
  }

  Future<void> _createTask() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedProjectId == null) {
      ref.read(notificationServiceProvider.notifier).showWarning('Please select a project');
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      final repository = ref.read(risksTasksRepositoryProvider);

      final newTask = Task(
        id: const Uuid().v4(),
        projectId: _selectedProjectId!,
        title: _titleController.text,
        description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
        status: _selectedStatus,
        priority: _selectedPriority,
        assignee: _assigneeController.text.isEmpty ? null : _assigneeController.text,
        dueDate: _selectedDueDate,
        createdDate: DateTime.now(),
        lastUpdated: DateTime.now(),
        progressPercentage: 0,
        aiGenerated: false,
      );

      await repository.createTask(_selectedProjectId!, newTask);

      // Force refresh the tasks list (clear cache and invalidate)
      await ref.read(forceRefreshTasksProvider)();

      if (mounted) {
        Navigator.of(context).pop(true);
        ref.read(notificationServiceProvider.notifier).showSuccess('Task created successfully');
      }
    } catch (e) {
      if (mounted) {
        ref.read(notificationServiceProvider.notifier).showError('Error creating task: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final projectsAsync = ref.watch(projectsListProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Dialog(
      insetPadding: isMobile
          ? const EdgeInsets.symmetric(horizontal: 16, vertical: 24)
          : const EdgeInsets.symmetric(horizontal: 40.0, vertical: 24.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isMobile ? double.infinity : 500,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
          minWidth: isMobile ? 0 : 400,
        ),
        child: IntrinsicHeight(
          child: Form(
            key: _formKey,
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
                child: Row(
                  children: [
                    Icon(
                      Icons.add_task,
                      color: colorScheme.primary,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Create New Task',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
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
                      // Project Selection
                      projectsAsync.when(
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (error, stack) => Text('Error loading projects: $error'),
                        data: (projects) => DropdownButtonFormField<String>(
                          value: _selectedProjectId,
                          menuMaxHeight: 300,
                          borderRadius: BorderRadius.circular(12),
                          elevation: 8,
                          decoration: InputDecoration(
                            labelText: 'Project *',
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
                              Icons.folder,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select a project';
                            }
                            return null;
                          },
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
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Title
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'Title *',
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
                            Icons.title,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a task title';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // Description
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Description',
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
                          alignLabelWithHint: true,
                          prefixIcon: Icon(
                            Icons.description,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        maxLines: 3,
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
                                DropdownButtonFormField<TaskStatus>(
                                  value: _selectedStatus,
                                  isExpanded: true,
                                  menuMaxHeight: 300,
                                  borderRadius: BorderRadius.circular(12),
                                  elevation: 8,
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
                                      vertical: 12,
                                    ),
                                  ),
                                  items: TaskStatus.values.map((status) {
                                    final task = Task(
                                      id: '',
                                      projectId: '',
                                      title: '',
                                      status: status,
                                      priority: TaskPriority.medium,
                                    );
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
                                          Flexible(
                                            child: Text(
                                              task.statusLabel,
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
                                      });
                                    }
                                  },
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
                                DropdownButtonFormField<TaskPriority>(
                                  value: _selectedPriority,
                                  isExpanded: true,
                                  menuMaxHeight: 300,
                                  borderRadius: BorderRadius.circular(12),
                                  elevation: 8,
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
                                      vertical: 12,
                                    ),
                                  ),
                                  items: TaskPriority.values.map((priority) {
                                    final task = Task(
                                      id: '',
                                      projectId: '',
                                      title: '',
                                      status: TaskStatus.todo,
                                      priority: priority,
                                    );
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
                                          Flexible(
                                            child: Text(
                                              task.priorityLabel,
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
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: isMobile ? 16 : 20),

                      // Assignee and Due Date Row
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Assignee',
                                  style: theme.textTheme.labelLarge,
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _assigneeController,
                                  decoration: InputDecoration(
                                    hintText: 'Enter assignee name',
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
                                  'Due Date',
                                  style: theme.textTheme.labelLarge,
                                ),
                                const SizedBox(height: 8),
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
                                      _selectedDueDate != null
                                          ? DateFormat('MMM d, y').format(_selectedDueDate!)
                                          : 'Select due date',
                                      style: TextStyle(
                                        color: _selectedDueDate == null
                                            ? colorScheme.onSurfaceVariant
                                            : null,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                    ],
                  ),
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
                      onPressed: _isCreating ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _isCreating ? null : _createTask,
                      icon: _isCreating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.add),
                      label: Text(_isCreating ? 'Creating...' : 'Create Task'),
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