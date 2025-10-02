import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../projects/domain/entities/task.dart';
import '../../../projects/presentation/providers/projects_provider.dart';
import '../providers/tasks_filter_provider.dart';
import '../providers/aggregated_tasks_provider.dart';

class AdvancedFilterDialog extends ConsumerStatefulWidget {
  final Function(TasksFilter)? onFilterUpdate;

  const AdvancedFilterDialog({
    super.key,
    this.onFilterUpdate,
  });

  @override
  ConsumerState<AdvancedFilterDialog> createState() => _AdvancedFilterDialogState();
}

class _AdvancedFilterDialogState extends ConsumerState<AdvancedFilterDialog> {
  late TasksFilter _tempFilter;
  DateTime? _startDate;
  DateTime? _endDate;
  final DateFormat _dateFormat = DateFormat('MMM d, y');

  @override
  void initState() {
    super.initState();
    _tempFilter = ref.read(tasksFilterProvider);
    _startDate = _tempFilter.startDate;
    _endDate = _tempFilter.endDate;
  }

  void _applyFilters() {
    final updatedFilter = _tempFilter.copyWith(
      startDate: _startDate,
      endDate: _endDate,
    );

    // Use callback for immediate local updates if available
    if (widget.onFilterUpdate != null) {
      widget.onFilterUpdate!(updatedFilter);
    } else {
      // Fallback to provider updates for batch operation
      final notifier = ref.read(tasksFilterProvider.notifier);
      notifier.updateFromFilter(updatedFilter);
    }

    Navigator.of(context).pop();
  }

  void _clearAllFilters() {
    setState(() {
      _tempFilter = const TasksFilter();
      _startDate = null;
      _endDate = null;
    });
  }

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            dialogBackgroundColor: Theme.of(context).colorScheme.surface,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(_startDate!)) {
          _endDate = null;
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? (_startDate ?? DateTime.now()),
      firstDate: _startDate ?? DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            dialogBackgroundColor: Theme.of(context).colorScheme.surface,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final projectsAsync = ref.watch(projectsListProvider);
    final tasksAsync = ref.watch(aggregatedTasksProvider);

    // Get unique assignees from all tasks
    final assignees = <String>{};
    tasksAsync.whenData((tasks) {
      for (final task in tasks) {
        if (task.task.assignee != null) {
          assignees.add(task.task.assignee!);
        }
      }
    });

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 500,
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
                    Icons.filter_list,
                    color: colorScheme.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Advanced Filters',
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
            // Special Filters - First and compact
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Quick Filters',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildCompactSwitch(
                    title: 'Overdue Only',
                    icon: Icons.warning,
                    color: Colors.orange,
                    value: _tempFilter.showOverdueOnly,
                    onChanged: (value) {
                      setState(() {
                        _tempFilter = _tempFilter.copyWith(showOverdueOnly: value);
                      });
                    },
                    theme: theme,
                    colorScheme: colorScheme,
                  ),
                  const SizedBox(height: 4),
                  _buildCompactSwitch(
                    title: 'My Tasks',
                    icon: Icons.person,
                    color: colorScheme.primary,
                    value: _tempFilter.showMyTasksOnly,
                    onChanged: (value) {
                      setState(() {
                        _tempFilter = _tempFilter.copyWith(showMyTasksOnly: value);
                      });
                    },
                    theme: theme,
                    colorScheme: colorScheme,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Projects
            Text(
              'Projects',
              style: theme.textTheme.titleSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            projectsAsync.when(
              loading: () => const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              error: (_, __) => const Text('Error loading projects'),
              data: (projects) => Wrap(
                spacing: 6,
                runSpacing: 6,
                children: projects.map((project) {
                  final isSelected = _tempFilter.projectIds.contains(project.id);
                  return FilterChip(
                    label: Text(
                      project.name,
                      style: TextStyle(
                        fontSize: 13,
                        color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _tempFilter = _tempFilter.copyWith(
                            projectIds: {..._tempFilter.projectIds, project.id},
                          );
                        } else {
                          _tempFilter = _tempFilter.copyWith(
                            projectIds: {..._tempFilter.projectIds}..remove(project.id),
                          );
                        }
                      });
                    },
                    selectedColor: colorScheme.primary,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    surfaceTintColor: Colors.transparent,
                    elevation: 0,
                    side: BorderSide(
                      color: isSelected
                        ? colorScheme.primary
                        : colorScheme.outlineVariant.withValues(alpha: 0.5),
                      width: 1,
                    ),
                    checkmarkColor: colorScheme.onPrimary,
                    showCheckmark: false,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 16),

            // Priority
            Text(
              'Priority',
              style: theme.textTheme.titleSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: TaskPriority.values.map((priority) {
                final isSelected = _tempFilter.priorities.contains(priority);
                final String label = switch (priority) {
                  TaskPriority.low => 'Low',
                  TaskPriority.medium => 'Medium',
                  TaskPriority.high => 'High',
                  TaskPriority.urgent => 'Urgent',
                };
                final Color color = switch (priority) {
                  TaskPriority.urgent => Colors.red,
                  TaskPriority.high => Colors.orange,
                  TaskPriority.medium => Colors.yellow[700]!,
                  TaskPriority.low => Colors.grey,
                };

                return FilterChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.flag,
                        size: 14,
                        color: isSelected ? Colors.white : color,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 13,
                          color: isSelected ? Colors.white : colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _tempFilter = _tempFilter.copyWith(
                          priorities: {..._tempFilter.priorities, priority},
                        );
                      } else {
                        _tempFilter = _tempFilter.copyWith(
                          priorities: {..._tempFilter.priorities}..remove(priority),
                        );
                      }
                    });
                  },
                  selectedColor: color,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  surfaceTintColor: Colors.transparent,
                  elevation: 0,
                  side: BorderSide(
                    color: isSelected
                      ? color
                      : colorScheme.outlineVariant.withValues(alpha: 0.5),
                    width: 1,
                  ),
                  checkmarkColor: Colors.white,
                  showCheckmark: false,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // Assignees
            if (assignees.isNotEmpty) ...[
              Text(
                'Assignees',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: assignees.map((assignee) {
                  final isSelected = _tempFilter.assignees.contains(assignee);
                  return FilterChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 14,
                          color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          assignee,
                          style: TextStyle(
                            fontSize: 13,
                            color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _tempFilter = _tempFilter.copyWith(
                            assignees: {..._tempFilter.assignees, assignee},
                          );
                        } else {
                          _tempFilter = _tempFilter.copyWith(
                            assignees: {..._tempFilter.assignees}..remove(assignee),
                          );
                        }
                      });
                    },
                    selectedColor: colorScheme.primary,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    surfaceTintColor: Colors.transparent,
                    elevation: 0,
                    side: BorderSide(
                      color: isSelected
                        ? colorScheme.primary
                        : colorScheme.outlineVariant.withValues(alpha: 0.5),
                      width: 1,
                    ),
                    checkmarkColor: colorScheme.onPrimary,
                    showCheckmark: false,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // Date Range - Compact inline selection
            Text(
              'Due Date Range',
              style: theme.textTheme.titleSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _selectStartDate,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: colorScheme.outline.withValues(alpha: 0.3),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, size: 16, color: colorScheme.onSurfaceVariant),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _startDate != null
                                ? _dateFormat.format(_startDate!)
                                : 'From',
                              style: TextStyle(
                                fontSize: 13,
                                color: _startDate == null
                                  ? colorScheme.onSurfaceVariant.withValues(alpha: 0.6)
                                  : colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward, size: 16, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: _selectEndDate,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: colorScheme.outline.withValues(alpha: 0.3),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, size: 16, color: colorScheme.onSurfaceVariant),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _endDate != null
                                ? _dateFormat.format(_endDate!)
                                : 'To',
                              style: TextStyle(
                                fontSize: 13,
                                color: _endDate == null
                                  ? colorScheme.onSurfaceVariant.withValues(alpha: 0.6)
                                  : colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_startDate != null || _endDate != null) ...[
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _startDate = null;
                      _endDate = null;
                    });
                  },
                  icon: const Icon(Icons.clear, size: 16),
                  label: const Text('Clear dates', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
              ),
            ],

            // Active filters count
            if (_tempFilter.hasActiveFilters || _startDate != null || _endDate != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 14,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${_getActiveFilterCount()} active filter${_getActiveFilterCount() != 1 ? 's' : ''}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: _tempFilter.hasActiveFilters || _startDate != null || _endDate != null
                        ? _clearAllFilters
                        : null,
                    icon: const Icon(Icons.clear_all, size: 18),
                    label: const Text('Clear All'),
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _applyFilters,
                        child: const Text('Apply'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactSwitch({
    required String title,
    required IconData icon,
    required Color color,
    required bool value,
    required ValueChanged<bool> onChanged,
    required ThemeData theme,
    required ColorScheme colorScheme,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 16, color: value ? color : colorScheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  color: value ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ),
    );
  }

  int _getActiveFilterCount() {
    int count = _tempFilter.activeFilterCount;
    if (_startDate != null || _endDate != null) count++;
    return count;
  }
}