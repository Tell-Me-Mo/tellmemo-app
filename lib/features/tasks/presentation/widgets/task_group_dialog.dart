import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/tasks_filter_provider.dart';

class TaskGroupDialog extends ConsumerStatefulWidget {
  const TaskGroupDialog({super.key});

  @override
  ConsumerState<TaskGroupDialog> createState() => _TaskGroupDialogState();
}

class _TaskGroupDialogState extends ConsumerState<TaskGroupDialog> {
  late TaskGroupBy _selectedGroupBy;

  @override
  void initState() {
    super.initState();
    final filter = ref.read(tasksFilterProvider);
    _selectedGroupBy = filter.groupBy;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 450,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
          minWidth: 400,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                    Icons.workspaces_outline,
                    color: colorScheme.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Group Tasks',
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
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Group Options Section
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorScheme.outline.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Group tasks by',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...TaskGroupBy.values.map((groupBy) => _buildGroupOption(
                                groupBy: groupBy,
                                theme: theme,
                                colorScheme: colorScheme,
                              )),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Info Box
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: colorScheme.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Grouping helps organize tasks into sections for better visibility',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Footer with actions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                  ),
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
                  FilledButton(
                    onPressed: () {
                      ref.read(tasksFilterProvider.notifier).updateGrouping(_selectedGroupBy);
                      Navigator.of(context).pop();
                    },
                    child: const Text('Apply'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupOption({
    required TaskGroupBy groupBy,
    required ThemeData theme,
    required ColorScheme colorScheme,
  }) {
    final isSelected = _selectedGroupBy == groupBy;

    final String label = switch (groupBy) {
      TaskGroupBy.none => 'No Grouping',
      TaskGroupBy.project => 'Project',
      TaskGroupBy.status => 'Status',
      TaskGroupBy.priority => 'Priority',
      TaskGroupBy.assignee => 'Assignee',
      TaskGroupBy.dueDate => 'Due Date',
    };

    final IconData icon = switch (groupBy) {
      TaskGroupBy.none => Icons.clear,
      TaskGroupBy.project => Icons.folder,
      TaskGroupBy.status => Icons.check_circle_outline,
      TaskGroupBy.priority => Icons.flag,
      TaskGroupBy.assignee => Icons.person,
      TaskGroupBy.dueDate => Icons.calendar_today,
    };

    final String description = switch (groupBy) {
      TaskGroupBy.none => 'Show all tasks in a single list',
      TaskGroupBy.project => 'Group tasks by their project',
      TaskGroupBy.status => 'Group by task status (To Do, In Progress, etc.)',
      TaskGroupBy.priority => 'Group by priority level',
      TaskGroupBy.assignee => 'Group by assigned team member',
      TaskGroupBy.dueDate => 'Group by due date (overdue, today, this week, etc.)',
    };

    return InkWell(
      onTap: () {
        setState(() {
          _selectedGroupBy = groupBy;
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withValues(alpha: 0.12)
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary.withValues(alpha: 0.4)
                : colorScheme.outline.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.primary.withValues(alpha: 0.15)
                    : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurface,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                size: 20,
                color: colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }
}