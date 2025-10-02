import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/datetime_utils.dart';
import '../../../../core/widgets/breadcrumb_navigation.dart';
import '../../data/models/summary_model.dart';

class StakeholderSummaryViewer extends ConsumerStatefulWidget {
  final SummaryModel summary;
  final VoidCallback? onExport;
  final VoidCallback? onCopy;
  final VoidCallback? onBack;
  final List<BreadcrumbItem>? breadcrumbs;

  const StakeholderSummaryViewer({
    super.key,
    required this.summary,
    this.onExport,
    this.onCopy,
    this.onBack,
    this.breadcrumbs,
  });

  @override
  ConsumerState<StakeholderSummaryViewer> createState() => _StakeholderSummaryViewerState();
}

class _StakeholderSummaryViewerState extends ConsumerState<StakeholderSummaryViewer> {
  final Map<String, bool> _editModes = {};
  late TextEditingController _bodyController;
  List<TextEditingController> _keyPointsControllers = [];
  bool _isSaving = false;
  late SummaryModel _localSummary;

  @override
  void initState() {
    super.initState();
    _localSummary = widget.summary;
    _initializeControllers();
  }

  @override
  void didUpdateWidget(StakeholderSummaryViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.summary != widget.summary) {
      _localSummary = widget.summary;
      _initializeControllers();
    }
  }

  void _initializeControllers() {
    _bodyController = TextEditingController(text: _localSummary.body);

    _keyPointsControllers = (_localSummary.keyPoints ?? [])
        .map((point) => TextEditingController(text: point))
        .toList();
  }

  @override
  void dispose() {
    _bodyController.dispose();
    for (final controller in _keyPointsControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _toggleEditMode(String section) {
    setState(() {
      _editModes[section] = !(_editModes[section] ?? false);

      if (!_editModes[section]!) {
        switch (section) {
          case 'overview':
            _bodyController.text = _localSummary.body;
            break;
          case 'keyPoints':
            _keyPointsControllers = (_localSummary.keyPoints ?? [])
                .map((point) => TextEditingController(text: point))
                .toList();
            break;
        }
      }
    });
  }

  Future<void> _saveSection(String section) async {
    setState(() {
      _isSaving = true;
    });

    try {
      Map<String, dynamic> updateData = {};

      switch (section) {
        case 'overview':
          updateData = {
            'body': _bodyController.text,
          };
          break;
        case 'keyPoints':
          updateData = {
            'key_points': _keyPointsControllers
                .where((c) => c.text.isNotEmpty)
                .map((c) => c.text)
                .toList(),
          };
          break;
      }

      final apiClient = ApiClient(DioClient.instance);
      await apiClient.updateSummary(_localSummary.id, updateData);

      if (mounted) {
        // Update local summary with the changes
        switch (section) {
          case 'overview':
            _localSummary = _localSummary.copyWith(body: _bodyController.text);
            break;
          case 'keyPoints':
            final newKeyPoints = _keyPointsControllers
                .where((c) => c.text.isNotEmpty)
                .map((c) => c.text)
                .toList();
            _localSummary = _localSummary.copyWith(keyPoints: newKeyPoints);
            break;
        }

        setState(() {
          _editModes[section] = false;
        });

        // widget.onEdit?.call();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_getSectionName(section)} updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  String _getSectionName(String section) {
    switch (section) {
      case 'overview':
        return 'Progress Overview';
      case 'keyPoints':
        return 'Key Achievements';
      default:
        return section;
    }
  }

  Widget _buildEditButton(String section) {
    final isEditing = _editModes[section] ?? false;

    if (isEditing) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton.icon(
            onPressed: _isSaving ? null : () => _toggleEditMode(section),
            icon: const Icon(Icons.close, size: 16),
            label: const Text('Cancel'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey,
              minimumSize: const Size(80, 32),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: _isSaving ? null : () => _saveSection(section),
            icon: _isSaving
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.check, size: 16),
            label: const Text('Apply'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(80, 32),
            ),
          ),
        ],
      );
    } else {
      return IconButton(
        onPressed: () => _toggleEditMode(section),
        icon: const Icon(Icons.edit, size: 18),
        tooltip: 'Edit ${_getSectionName(section)}',
        style: IconButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.primary,
        ),
        constraints: const BoxConstraints(
          minWidth: 32,
          minHeight: 32,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(isDesktop ? 32 : 16),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isDesktop ? 1400 : double.infinity),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Common Header
                    _buildCommonHeader(context),
                    const SizedBox(height: 24),

                    // Progress Overview
                    _buildCleanSection(
                      context,
                      title: 'Progress Overview',
                      child: _buildProgressOverviewContent(context),
                      editSection: 'overview',
                      icon: Icons.trending_up,
                    ),
                    const SizedBox(height: 16),

                    // Deliverables and Milestones
                    _buildCleanSection(
                      context,
                      title: 'Deliverables & Milestones',
                      child: _buildDeliverablesContent(context),
                      count: _localSummary.actionItems?.length,
                      icon: Icons.assignment_turned_in,
                      iconColor: Colors.green,
                    ),
                    const SizedBox(height: 16),

                    // Timeline and Next Steps
                    if (_localSummary.nextMeetingAgenda != null && _localSummary.nextMeetingAgenda!.isNotEmpty)
                      _buildCleanSection(
                        context,
                        title: 'Timeline & Next Steps',
                        child: _buildTimelineContent(context),
                        count: _localSummary.nextMeetingAgenda!.length,
                        icon: Icons.timeline,
                      ),

                    // External Dependencies
                    if (_hasExternalDependencies()) ...[
                      const SizedBox(height: 16),
                      _buildCleanSection(
                        context,
                        title: 'External Dependencies & Blockers',
                        child: _buildDependenciesContent(context),
                        count: (_localSummary.blockers as List?)?.length,
                        isHighPriority: true,
                        icon: Icons.link_off,
                        iconColor: Colors.orange,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCommonHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final createdAt = DateTimeUtils.formatDateTime(_localSummary.createdAt);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Combined header row with back button, title, and actions
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Back button
            IconButton(
              onPressed: widget.onBack ?? () => Navigator.of(context).pop(),
              icon: Icon(Icons.arrow_back, size: 20),
              style: IconButton.styleFrom(
                foregroundColor: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 16),

            // Title (expanded to take available space)
            Expanded(
              child: Text(
                _localSummary.subject,
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const SizedBox(width: 16),

            // Action buttons
            TextButton.icon(
              onPressed: widget.onExport,
              icon: Icon(Icons.download_outlined, size: 18),
              label: const Text('Export'),
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: widget.onCopy,
              icon: Icon(Icons.copy_outlined, size: 18),
              label: const Text('Copy'),
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 56), // Align with title (icon button width + spacing)
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getTypeColor().withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: _getTypeColor().withValues(alpha: 0.3),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getSummaryIcon(),
                      size: 14,
                      color: _getTypeColor(),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatSummaryType(_localSummary.summaryType),
                      style: textTheme.labelSmall?.copyWith(
                        color: _getTypeColor(),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.access_time,
                size: 14,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 4),
              Text(
                createdAt,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.teal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: Colors.teal.withValues(alpha: 0.3),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.people, size: 14, color: Colors.teal),
                    const SizedBox(width: 4),
                    Text(
                      'STAKEHOLDER',
                      style: textTheme.labelSmall?.copyWith(
                        color: Colors.teal,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getSummaryIcon() {
    switch (_localSummary.summaryType) {
      case SummaryType.meeting:
        return Icons.groups_outlined;
      case SummaryType.project:
        return Icons.folder_outlined;
      case SummaryType.program:
        return Icons.dashboard_outlined;
      case SummaryType.portfolio:
        return Icons.business_center_outlined;
    }
  }

  Color _getTypeColor() {
    switch (_localSummary.summaryType) {
      case SummaryType.meeting:
        return Colors.blue;
      case SummaryType.project:
        return Colors.green;
      case SummaryType.program:
        return Colors.purple;
      case SummaryType.portfolio:
        return Colors.orange;
    }
  }

  String _formatSummaryType(SummaryType type) {
    switch (type) {
      case SummaryType.meeting:
        return 'Meeting Summary';
      case SummaryType.project:
        return 'Project Summary';
      case SummaryType.program:
        return 'Program Summary';
      case SummaryType.portfolio:
        return 'Portfolio Summary';
    }
  }

  Widget _buildCleanSection(BuildContext context, {
    required String title,
    required Widget child,
    String? editSection,
    int? count,
    bool isHighPriority = false,
    IconData? icon,
    Color? iconColor,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isHighPriority
              ? Colors.orange.withValues(alpha: 0.4)
              : colorScheme.outlineVariant.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLowest.withValues(alpha: 0.3),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    color: iconColor ?? colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  title,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                ),
                if (count != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isHighPriority
                          ? Colors.orange.withValues(alpha: 0.1)
                          : colorScheme.primaryContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      count.toString(),
                      style: textTheme.labelSmall?.copyWith(
                        color: isHighPriority
                            ? Colors.orange
                            : colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                if (editSection != null) _buildEditButton(editSection),
              ],
            ),
          ),
          // Section content
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressOverviewContent(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isEditingOverview = _editModes['overview'] ?? false;
    final isEditingKeyPoints = _editModes['keyPoints'] ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          if (isEditingOverview)
            TextField(
              controller: _bodyController,
              decoration: const InputDecoration(
                labelText: 'Progress Overview',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 8,
            )
          else
            Text(
              _localSummary.body,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.6,
              ),
            ),
          if (_localSummary.keyPoints != null && _localSummary.keyPoints!.isNotEmpty || isEditingKeyPoints) ...[
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'Key Achievements',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                _buildEditButton('keyPoints'),
              ],
            ),
            const SizedBox(height: 12),
                  if (isEditingKeyPoints)
                    Column(
                      children: [
                        ..._keyPointsControllers.asMap().entries.map((entry) {
                          final index = entry.key;
                          final controller = entry.value;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: controller,
                                    decoration: InputDecoration(
                                      labelText: 'Key Achievement ${index + 1}',
                                      border: const OutlineInputBorder(),
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  onPressed: () {
                                    setState(() {
                                      _keyPointsControllers[index].dispose();
                                      _keyPointsControllers.removeAt(index);
                                    });
                                  },
                                  color: Colors.red,
                                ),
                              ],
                            ),
                          );
                        }),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _keyPointsControllers.add(TextEditingController());
                            });
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Add Key Achievement'),
                        ),
                      ],
                    )
                  else
                    ..._localSummary.keyPoints!.map((point) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: colorScheme.primary,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            point,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  )),
          ],
      ],
    );
  }

  Widget _buildDeliverablesContent(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          if (_localSummary.actionItems?.isEmpty ?? true)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 48,
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No pending deliverables',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._localSummary.actionItems!.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: item.status == 'completed' ? Colors.green : colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.description,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            decoration: item.status == 'completed'
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            if (item.assignee != null)
                              Text(
                                'Owner: ${item.assignee}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            if (item.dueDate != null)
                              Text(
                                '• Due: ${DateFormat('MMM dd').format(_parseDueDate(item.dueDate!))}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            Text(
                              '• ${item.urgency.toUpperCase()}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: _getUrgencyColor(item.urgency),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildTimelineContent(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          if (_localSummary.nextMeetingAgenda != null && _localSummary.nextMeetingAgenda!.isNotEmpty) ...[
            ..._localSummary.nextMeetingAgenda!.map((agenda) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          agenda.title,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (agenda.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            agenda.description,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            )),
          ],
      ],
    );
  }

  Widget _buildDependenciesContent(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final blockers = (_localSummary.blockers as List?) ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          ...blockers.map((blocker) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        blocker['title'] ?? blocker['description'] ?? 'Blocker',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (blocker['impact'] != null || blocker['status'] != null) ...[
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          children: [
                            if (blocker['impact'] != null)
                              Text(
                                'Impact: ${blocker['impact']}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: _getImpactColor(blocker['impact']),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            if (blocker['status'] != null)
                              Text(
                                '• Status: ${blocker['status']}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ],
                      if (blocker['resolution_strategy'] != null || blocker['resolution'] != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Resolution: ${blocker['resolution_strategy'] ?? blocker['resolution']}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          )),
      ],
    );
  }

  bool _hasExternalDependencies() {
    final blockers = (_localSummary.blockers as List?) ?? [];
    return blockers.isNotEmpty;
  }

  Color _getUrgencyColor(String urgency) {
    switch (urgency.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  DateTime _parseDueDate(String dueDate) {
    // Handle various date formats that might come from the backend
    try {
      // First try to parse as-is
      return DateTime.parse(dueDate).toLocal();
    } catch (e) {
      // If it fails, try adding time component if it's just a date
      try {
        if (dueDate.contains('Z')) {
          // Remove trailing Z if it's malformed (like "2024-01-15Z")
          final cleanDate = dueDate.replaceAll('Z', '');
          return DateTime.parse('${cleanDate}T00:00:00Z').toLocal();
        } else if (!dueDate.contains('T')) {
          // It's just a date, add time component
          return DateTime.parse('${dueDate}T00:00:00Z').toLocal();
        } else {
          // Add Z if missing
          return DateTime.parse('${dueDate}Z').toLocal();
        }
      } catch (e) {
        // Fallback to today if parsing fails
        return DateTime.now();
      }
    }
  }


  Color _getImpactColor(String? impact) {
    switch (impact?.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.yellow;
      default:
        return Colors.grey;
    }
  }

}