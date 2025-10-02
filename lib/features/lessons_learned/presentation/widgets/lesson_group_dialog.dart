import 'package:flutter/material.dart';

enum LessonGroupingMode { none, project, category, type, impact }

class LessonGroupDialog extends StatefulWidget {
  final LessonGroupingMode currentGrouping;
  final Function(LessonGroupingMode grouping) onGroupingChanged;

  const LessonGroupDialog({
    super.key,
    required this.currentGrouping,
    required this.onGroupingChanged,
  });

  @override
  State<LessonGroupDialog> createState() => _LessonGroupDialogState();
}

class _LessonGroupDialogState extends State<LessonGroupDialog> {
  late LessonGroupingMode _selectedGrouping;

  @override
  void initState() {
    super.initState();
    _selectedGrouping = widget.currentGrouping;
  }

  String _getGroupingLabel(LessonGroupingMode grouping) {
    switch (grouping) {
      case LessonGroupingMode.none:
        return 'No Grouping';
      case LessonGroupingMode.project:
        return 'Group by Project';
      case LessonGroupingMode.category:
        return 'Group by Category';
      case LessonGroupingMode.type:
        return 'Group by Type';
      case LessonGroupingMode.impact:
        return 'Group by Impact';
    }
  }

  String _getGroupingDescription(LessonGroupingMode grouping) {
    switch (grouping) {
      case LessonGroupingMode.none:
        return 'Show all lessons in a single list';
      case LessonGroupingMode.project:
        return 'Organize lessons by their associated project';
      case LessonGroupingMode.category:
        return 'Organize lessons by category (Technical, Process, etc.)';
      case LessonGroupingMode.type:
        return 'Organize lessons by type (Success, Challenge, Best Practice)';
      case LessonGroupingMode.impact:
        return 'Organize lessons by impact level (High, Medium, Low)';
    }
  }

  IconData _getGroupingIcon(LessonGroupingMode grouping) {
    switch (grouping) {
      case LessonGroupingMode.none:
        return Icons.list;
      case LessonGroupingMode.project:
        return Icons.folder_outlined;
      case LessonGroupingMode.category:
        return Icons.category_outlined;
      case LessonGroupingMode.type:
        return Icons.label_outline;
      case LessonGroupingMode.impact:
        return Icons.flag_outlined;
    }
  }


  void _applyGrouping() {
    widget.onGroupingChanged(_selectedGrouping);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 450,
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
                    Icons.group_work_outlined,
                    color: colorScheme.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Group Lessons',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    color: colorScheme.onSurfaceVariant,
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
                            'Group lessons by',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...LessonGroupingMode.values.map((grouping) => _buildGroupOption(
                                groupBy: grouping,
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
                              'Grouping helps organize lessons into sections for better visibility',
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

            // Footer
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
                    onPressed: _applyGrouping,
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
    required LessonGroupingMode groupBy,
    required ThemeData theme,
    required ColorScheme colorScheme,
  }) {
    final isSelected = _selectedGrouping == groupBy;

    final String label = _getGroupingLabel(groupBy);
    final IconData icon = _getGroupingIcon(groupBy);
    final String description = _getGroupingDescription(groupBy);

    return InkWell(
      onTap: () {
        setState(() {
          _selectedGrouping = groupBy;
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