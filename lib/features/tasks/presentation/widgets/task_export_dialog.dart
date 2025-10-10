import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import '../../../../core/services/notification_service.dart';
import '../providers/aggregated_tasks_provider.dart';

class TaskExportDialog extends ConsumerStatefulWidget {
  final List<TaskWithProject> tasks;

  const TaskExportDialog({
    super.key,
    required this.tasks,
  });

  @override
  ConsumerState<TaskExportDialog> createState() => _TaskExportDialogState();
}

class _TaskExportDialogState extends ConsumerState<TaskExportDialog> {
  String _selectedFormat = 'csv';
  bool _includeCompleted = true;
  bool _includeCancelled = false;

  String _generateCSV() {
    final buffer = StringBuffer();

    // CSV Header
    buffer.writeln('Title,Project,Status,Priority,Assignee,Due Date,Created Date,Description');

    // CSV Data
    for (final taskWithProject in widget.tasks) {
      final task = taskWithProject.task;
      final project = taskWithProject.project;

      // Skip completed/cancelled based on filters
      if (!_includeCompleted && task.isCompleted) continue;
      if (!_includeCancelled && task.status.name == 'cancelled') continue;

      final title = _escapeCSV(task.title);
      final projectName = _escapeCSV(project.name);
      final status = task.statusLabel;
      final priority = task.priorityLabel;
      final assignee = task.assignee ?? '';
      final dueDate = task.dueDate != null
          ? DateFormat('yyyy-MM-dd').format(task.dueDate!)
          : '';
      final createdDate = task.createdDate != null
          ? DateFormat('yyyy-MM-dd').format(task.createdDate!)
          : '';
      final description = _escapeCSV(task.description ?? '');

      buffer.writeln('$title,$projectName,$status,$priority,$assignee,$dueDate,$createdDate,$description');
    }

    return buffer.toString();
  }

  String _escapeCSV(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  String _generateJSON() {
    final tasks = <Map<String, dynamic>>[];

    for (final taskWithProject in widget.tasks) {
      final task = taskWithProject.task;
      final project = taskWithProject.project;

      // Skip completed/cancelled based on filters
      if (!_includeCompleted && task.isCompleted) continue;
      if (!_includeCancelled && task.status.name == 'cancelled') continue;

      tasks.add({
        'id': task.id,
        'title': task.title,
        'description': task.description,
        'project': {
          'id': project.id,
          'name': project.name,
        },
        'status': task.status.name,
        'priority': task.priority.name,
        'assignee': task.assignee,
        'dueDate': task.dueDate?.toIso8601String(),
        'createdDate': task.createdDate?.toIso8601String(),
        'completedDate': task.completedDate?.toIso8601String(),
        'progressPercentage': task.progressPercentage,
        'aiGenerated': task.aiGenerated,
        'aiConfidence': task.aiConfidence,
        'isOverdue': task.isOverdue,
      });
    }

    return const JsonEncoder.withIndent('  ').convert(tasks);
  }

  String _generateMarkdown() {
    final buffer = StringBuffer();

    buffer.writeln('# Tasks Export');
    buffer.writeln();
    buffer.writeln('Generated on: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}');
    buffer.writeln();

    // Group tasks by project
    final tasksByProject = <String, List<TaskWithProject>>{};
    for (final taskWithProject in widget.tasks) {
      final task = taskWithProject.task;

      // Skip completed/cancelled based on filters
      if (!_includeCompleted && task.isCompleted) continue;
      if (!_includeCancelled && task.status.name == 'cancelled') continue;

      final projectName = taskWithProject.project.name;
      tasksByProject[projectName] ??= [];
      tasksByProject[projectName]!.add(taskWithProject);
    }

    // Generate markdown for each project
    for (final entry in tasksByProject.entries) {
      buffer.writeln('## ${entry.key}');
      buffer.writeln();

      for (final taskWithProject in entry.value) {
        final task = taskWithProject.task;
        final checkbox = task.isCompleted ? '[x]' : '[ ]';
        final priority = task.priority.name.toUpperCase();
        final dueDate = task.dueDate != null
            ? ' (Due: ${DateFormat('MMM d').format(task.dueDate!)})'
            : '';

        buffer.writeln('- $checkbox **${task.title}** [$priority]$dueDate');

        if (task.description != null && task.description!.isNotEmpty) {
          buffer.writeln('  - ${task.description}');
        }

        if (task.assignee != null) {
          buffer.writeln('  - Assignee: ${task.assignee}');
        }
      }

      buffer.writeln();
    }

    return buffer.toString();
  }

  void _copyToClipboard(String content) {
    Clipboard.setData(ClipboardData(text: content));
    ref.read(notificationServiceProvider.notifier).showSuccess('Copied to clipboard!');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
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
                    Icons.download,
                    color: colorScheme.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Export Tasks',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${widget.tasks.length} tasks selected',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
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
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    // Format Selection
                    Text(
                      'Export Format',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Column(
                      children: [
                        RadioListTile<String>(
                          title: const Text('CSV'),
                          subtitle: const Text('Spreadsheet compatible'),
                          value: 'csv',
                          groupValue: _selectedFormat,
                          onChanged: (value) {
                            setState(() {
                              _selectedFormat = value!;
                            });
                          },
                        ),
                        RadioListTile<String>(
                          title: const Text('JSON'),
                          subtitle: const Text('For developers & integrations'),
                          value: 'json',
                          groupValue: _selectedFormat,
                          onChanged: (value) {
                            setState(() {
                              _selectedFormat = value!;
                            });
                          },
                        ),
                        RadioListTile<String>(
                          title: const Text('Markdown'),
                          subtitle: const Text('Human-readable format'),
                          value: 'markdown',
                          groupValue: _selectedFormat,
                          onChanged: (value) {
                            setState(() {
                              _selectedFormat = value!;
                            });
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 20),

                    // Options
                    Text(
                      'Options',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      title: const Text('Include completed tasks'),
                      value: _includeCompleted,
                      onChanged: (value) {
                        setState(() {
                          _includeCompleted = value!;
                        });
                      },
                    ),
                    CheckboxListTile(
                      title: const Text('Include cancelled tasks'),
                      value: _includeCancelled,
                      onChanged: (value) {
                        setState(() {
                          _includeCancelled = value!;
                        });
                      },
                    ),
                    ],
                  ),
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
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      String content;
                      switch (_selectedFormat) {
                        case 'csv':
                          content = _generateCSV();
                          break;
                        case 'json':
                          content = _generateJSON();
                          break;
                        case 'markdown':
                          content = _generateMarkdown();
                          break;
                        default:
                          content = _generateCSV();
                      }
                      _copyToClipboard(content);
                    },
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy to Clipboard'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}