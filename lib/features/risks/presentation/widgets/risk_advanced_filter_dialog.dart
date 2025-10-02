import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../projects/domain/entities/risk.dart';
import '../../../projects/presentation/providers/projects_provider.dart';

class RiskAdvancedFilterDialog extends ConsumerStatefulWidget {
  final RiskSeverity? selectedSeverity;
  final RiskStatus? selectedStatus;
  final bool showAIGeneratedOnly;
  final String? selectedAssignee;
  final DateTimeRange? selectedDateRange;
  final String? selectedProjectId;
  final Function({
    RiskSeverity? severity,
    RiskStatus? status,
    bool? aiGeneratedOnly,
    String? assignee,
    DateTimeRange? dateRange,
    String? projectId,
  }) onFiltersChanged;

  const RiskAdvancedFilterDialog({
    super.key,
    this.selectedSeverity,
    this.selectedStatus,
    this.showAIGeneratedOnly = false,
    this.selectedAssignee,
    this.selectedDateRange,
    this.selectedProjectId,
    required this.onFiltersChanged,
  });

  @override
  ConsumerState<RiskAdvancedFilterDialog> createState() => _RiskAdvancedFilterDialogState();
}

class _RiskAdvancedFilterDialogState extends ConsumerState<RiskAdvancedFilterDialog> {
  late RiskSeverity? _selectedSeverity;
  late RiskStatus? _selectedStatus;
  late bool _showAIGeneratedOnly;
  late String? _selectedAssignee;
  late DateTimeRange? _selectedDateRange;
  late String? _selectedProjectId;
  DateTime? _startDate;
  DateTime? _endDate;
  final DateFormat _dateFormat = DateFormat('MMM d, y');

  @override
  void initState() {
    super.initState();
    _selectedSeverity = widget.selectedSeverity;
    _selectedStatus = widget.selectedStatus;
    _showAIGeneratedOnly = widget.showAIGeneratedOnly;
    _selectedAssignee = widget.selectedAssignee;
    _selectedDateRange = widget.selectedDateRange;
    _selectedProjectId = widget.selectedProjectId;
    _startDate = widget.selectedDateRange?.start;
    _endDate = widget.selectedDateRange?.end;
  }

  String _getSeverityLabel(RiskSeverity severity) {
    switch (severity) {
      case RiskSeverity.low:
        return 'Low';
      case RiskSeverity.medium:
        return 'Medium';
      case RiskSeverity.high:
        return 'High';
      case RiskSeverity.critical:
        return 'Critical';
    }
  }

  String _getStatusLabel(RiskStatus status) {
    switch (status) {
      case RiskStatus.identified:
        return 'Identified';
      case RiskStatus.mitigating:
        return 'Mitigating';
      case RiskStatus.resolved:
        return 'Resolved';
      case RiskStatus.accepted:
        return 'Accepted';
      case RiskStatus.escalated:
        return 'Escalated';
    }
  }

  Color _getSeverityColor(RiskSeverity severity) {
    switch (severity) {
      case RiskSeverity.low:
        return Colors.green;
      case RiskSeverity.medium:
        return Colors.orange;
      case RiskSeverity.high:
        return Colors.red.shade400;
      case RiskSeverity.critical:
        return Colors.red;
    }
  }

  int _countActiveFilters() {
    int count = 0;
    if (_selectedSeverity != null) count++;
    if (_selectedStatus != null) count++;
    if (_showAIGeneratedOnly) count++;
    if (_selectedAssignee != null) count++;
    if (_selectedDateRange != null) count++;
    if (_selectedProjectId != null) count++;
    return count;
  }

  void _clearAllFilters() {
    setState(() {
      _selectedSeverity = null;
      _selectedStatus = null;
      _showAIGeneratedOnly = false;
      _selectedAssignee = null;
      _selectedDateRange = null;
      _selectedProjectId = null;
    });
  }

  void _applyFilters() {
    // Create DateTimeRange from start and end dates if both are set
    DateTimeRange? dateRange;
    if (_startDate != null && _endDate != null) {
      dateRange = DateTimeRange(start: _startDate!, end: _endDate!);
    }

    widget.onFiltersChanged(
      severity: _selectedSeverity,
      status: _selectedStatus,
      aiGeneratedOnly: _showAIGeneratedOnly,
      assignee: _selectedAssignee,
      dateRange: dateRange,
      projectId: _selectedProjectId,
    );
    Navigator.of(context).pop();
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

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 500,
          maxHeight: 600,
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
                    // Active filters info
                    if (_countActiveFilters() > 0) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
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
                            Text(
                              '${_countActiveFilters()} filter${_countActiveFilters() == 1 ? '' : 's'} active',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Quick Filters
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
                            'Quick Filters',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SwitchListTile(
                            title: const Text('AI Generated Only'),
                            subtitle: const Text('Show only AI-identified risks'),
                            value: _showAIGeneratedOnly,
                            onChanged: (value) {
                              setState(() {
                                _showAIGeneratedOnly = value;
                              });
                            },
                            contentPadding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Severity Filter
                    Text(
                      'Severity',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: RiskSeverity.values.map((severity) {
                        final isSelected = _selectedSeverity == severity;
                        final severityColor = _getSeverityColor(severity);
                        return FilterChip(
                          label: Text(
                            _getSeverityLabel(severity),
                            style: TextStyle(
                              fontSize: 13,
                              color: isSelected ? Colors.white : colorScheme.onSurface,
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedSeverity = selected ? severity : null;
                            });
                          },
                          selectedColor: severityColor,
                          backgroundColor: colorScheme.surfaceContainerHighest,
                          surfaceTintColor: Colors.transparent,
                          elevation: 0,
                          side: BorderSide(
                            color: isSelected
                                ? severityColor
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

                    // Status Filter
                    Text(
                      'Status',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: RiskStatus.values.map((status) {
                        final isSelected = _selectedStatus == status;
                        return FilterChip(
                          label: Text(
                            _getStatusLabel(status),
                            style: TextStyle(
                              fontSize: 13,
                              color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedStatus = selected ? status : null;
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

                    // Projects Filter
                    Text(
                      'Projects',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    projectsAsync.when(
                      loading: () => const CircularProgressIndicator(),
                      error: (error, stack) => Text('Failed to load projects: $error'),
                      data: (projects) => Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: projects.map((project) {
                          final isSelected = _selectedProjectId == project.id;
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
                                _selectedProjectId = selected ? project.id : null;
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

                    // Date Range - Compact inline selection (matching tasks design)
                    Text(
                      'Date Range',
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
                  ],
                ),
              ),
            ),

            // Footer
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _clearAllFilters,
                    child: const Text('Clear All'),
                  ),
                  const SizedBox(width: 8),
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
            ),
          ],
        ),
      ),
    );
  }
}