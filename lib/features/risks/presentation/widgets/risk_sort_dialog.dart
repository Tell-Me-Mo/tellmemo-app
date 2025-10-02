import 'package:flutter/material.dart';

enum RiskSortOption {
  severity,
  dateIdentified,
  dateResolved,
  project,
  status,
  assignee,
}

enum SortOrder {
  ascending,
  descending,
}

class RiskSortDialog extends StatefulWidget {
  final RiskSortOption? currentSortBy;
  final SortOrder currentSortOrder;
  final Function(RiskSortOption sortBy, SortOrder sortOrder) onSortChanged;

  const RiskSortDialog({
    super.key,
    this.currentSortBy,
    this.currentSortOrder = SortOrder.ascending,
    required this.onSortChanged,
  });

  @override
  State<RiskSortDialog> createState() => _RiskSortDialogState();
}

class _RiskSortDialogState extends State<RiskSortDialog> {
  late RiskSortOption? _selectedSortBy;
  late SortOrder _selectedSortOrder;

  @override
  void initState() {
    super.initState();
    _selectedSortBy = widget.currentSortBy;
    _selectedSortOrder = widget.currentSortOrder;
  }

  String _getSortOptionLabel(RiskSortOption option) {
    switch (option) {
      case RiskSortOption.severity:
        return 'Severity';
      case RiskSortOption.dateIdentified:
        return 'Date Identified';
      case RiskSortOption.dateResolved:
        return 'Date Resolved';
      case RiskSortOption.project:
        return 'Project';
      case RiskSortOption.status:
        return 'Status';
      case RiskSortOption.assignee:
        return 'Assignee';
    }
  }

  String _getSortOptionDescription(RiskSortOption option) {
    switch (option) {
      case RiskSortOption.severity:
        return 'Sort by risk severity level';
      case RiskSortOption.dateIdentified:
        return 'Sort by when risk was identified';
      case RiskSortOption.dateResolved:
        return 'Sort by when risk was resolved';
      case RiskSortOption.project:
        return 'Sort alphabetically by project name';
      case RiskSortOption.status:
        return 'Sort by risk status';
      case RiskSortOption.assignee:
        return 'Sort alphabetically by assignee';
    }
  }

  IconData _getSortOptionIcon(RiskSortOption option) {
    switch (option) {
      case RiskSortOption.severity:
        return Icons.flag;
      case RiskSortOption.dateIdentified:
        return Icons.calendar_today;
      case RiskSortOption.dateResolved:
        return Icons.calendar_month;
      case RiskSortOption.project:
        return Icons.folder_outlined;
      case RiskSortOption.status:
        return Icons.info_outline;
      case RiskSortOption.assignee:
        return Icons.person_outline;
    }
  }

  Color _getSortOptionColor(RiskSortOption option, ColorScheme colorScheme) {
    switch (option) {
      case RiskSortOption.severity:
        return Colors.red;
      case RiskSortOption.dateIdentified:
        return Colors.blue;
      case RiskSortOption.dateResolved:
        return Colors.green;
      case RiskSortOption.project:
        return Colors.orange;
      case RiskSortOption.status:
        return Colors.purple;
      case RiskSortOption.assignee:
        return Colors.teal;
    }
  }

  void _applySorting() {
    if (_selectedSortBy != null) {
      widget.onSortChanged(_selectedSortBy!, _selectedSortOrder);
    }
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
          maxWidth: 400,
          minWidth: 350,
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
                    Icons.sort,
                    color: colorScheme.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Sort Risks',
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
                    // Sort By Section (wrapped in container like tasks)
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
                            'Sort by',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...RiskSortOption.values.map((option) => _buildSortOption(
                                sortBy: option,
                                theme: theme,
                                colorScheme: colorScheme,
                              )),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Sort Order Section (matching tasks style)
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
                            'Sort order',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: colorScheme.outline.withValues(alpha: 0.1),
                              ),
                            ),
                            padding: const EdgeInsets.all(4),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _buildOrderOption(
                                    order: SortOrder.ascending,
                                    label: 'Ascending',
                                    icon: Icons.arrow_upward,
                                    theme: theme,
                                    colorScheme: colorScheme,
                                  ),
                                ),
                                Expanded(
                                  child: _buildOrderOption(
                                    order: SortOrder.descending,
                                    label: 'Descending',
                                    icon: Icons.arrow_downward,
                                    theme: theme,
                                    colorScheme: colorScheme,
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
                    onPressed: _selectedSortBy != null ? _applySorting : null,
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

  Widget _buildSortOption({
    required RiskSortOption sortBy,
    required ThemeData theme,
    required ColorScheme colorScheme,
  }) {
    final isSelected = _selectedSortBy == sortBy;
    final optionColor = _getSortOptionColor(sortBy, colorScheme);

    return InkWell(
      onTap: () {
        setState(() {
          _selectedSortBy = sortBy;
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        margin: const EdgeInsets.only(bottom: 6),
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
            Icon(
              _getSortOptionIcon(sortBy),
              size: 20,
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _getSortOptionLabel(sortBy),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
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

  Widget _buildOrderOption({
    required SortOrder order,
    required String label,
    required IconData icon,
    required ThemeData theme,
    required ColorScheme colorScheme,
  }) {
    final isSelected = _selectedSortOrder == order;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedSortOrder = order;
        });
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isSelected
                    ? colorScheme.onSurface
                    : colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}