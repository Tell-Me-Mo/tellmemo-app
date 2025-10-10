import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/datetime_utils.dart';
import '../../../../core/widgets/breadcrumb_navigation.dart';
import '../../../../core/services/notification_service.dart';
import '../../data/models/summary_model.dart';

class ExecutiveSummaryViewer extends ConsumerStatefulWidget {
  final SummaryModel summary;
  final VoidCallback? onExport;
  final VoidCallback? onCopy;
  final VoidCallback? onBack;
  final List<BreadcrumbItem>? breadcrumbs;

  const ExecutiveSummaryViewer({
    super.key,
    required this.summary,
    this.onExport,
    this.onCopy,
    this.onBack,
    this.breadcrumbs,
  });

  @override
  ConsumerState<ExecutiveSummaryViewer> createState() => _ExecutiveSummaryViewerState();
}

class _ExecutiveSummaryViewerState extends ConsumerState<ExecutiveSummaryViewer> {
  final Map<String, bool> _editModes = {};
  final Map<String, ValueNotifier<bool>> _expansionNotifiers = {};
  late TextEditingController _subjectController;
  late TextEditingController _bodyController;
  List<TextEditingController> _keyPointsControllers = [];
  List<TextEditingController> _decisionsControllers = [];
  bool _isSaving = false;

  // Store local copy of summary data for instant updates
  late SummaryModel _localSummary;

  @override
  void initState() {
    super.initState();
    _localSummary = widget.summary;
    _initializeControllers();
    _initializeExpansionStates();
  }

  void _initializeExpansionStates() {
    // Executive overview always expanded
    _expansionNotifiers['overview'] = ValueNotifier(true);
    // Strategic decisions collapsed by default on mobile
    _expansionNotifiers['decisions'] = ValueNotifier(false);
    // Risks collapsed by default on mobile
    _expansionNotifiers['risks'] = ValueNotifier(false);
  }

  @override
  void didUpdateWidget(ExecutiveSummaryViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.summary != widget.summary) {
      _localSummary = widget.summary;
      _initializeControllers();
    }
  }

  void _initializeControllers() {
    _subjectController = TextEditingController(text: _localSummary.subject);
    _bodyController = TextEditingController(text: _localSummary.body);

    _keyPointsControllers = (_localSummary.keyPoints ?? [])
        .map((point) => TextEditingController(text: point))
        .toList();

    _decisionsControllers = (_localSummary.decisions ?? [])
        .map((decision) => TextEditingController(text: decision.description))
        .toList();
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _bodyController.dispose();
    for (final controller in _keyPointsControllers) {
      controller.dispose();
    }
    for (final controller in _decisionsControllers) {
      controller.dispose();
    }
    for (final notifier in _expansionNotifiers.values) {
      notifier.dispose();
    }
    super.dispose();
  }

  void _toggleEditMode(String section) {
    setState(() {
      _editModes[section] = !(_editModes[section] ?? false);

      if (!_editModes[section]!) {
        switch (section) {
          case 'summary':
            _bodyController.text = _localSummary.body;
            break;
          case 'keyPoints':
            _keyPointsControllers = (_localSummary.keyPoints ?? [])
                .map((point) => TextEditingController(text: point))
                .toList();
            break;
          case 'decisions':
            _decisionsControllers = (_localSummary.decisions ?? [])
                .map((decision) => TextEditingController(text: decision.description))
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
        case 'summary':
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
        case 'decisions':
          updateData = {
            'decisions': _decisionsControllers
                .where((c) => c.text.isNotEmpty)
                .map((c) => {'description': c.text})
                .toList(),
          };
          break;
      }

      final apiClient = ApiClient(DioClient.instance);
      await apiClient.updateSummary(_localSummary.id, updateData);

      if (mounted) {
        setState(() {
          // Update local summary data based on what was saved
          switch (section) {
            case 'summary':
              _localSummary = _localSummary.copyWith(body: _bodyController.text);
              break;
            case 'keyPoints':
              final newKeyPoints = _keyPointsControllers
                  .where((c) => c.text.isNotEmpty)
                  .map((c) => c.text)
                  .toList();
              _localSummary = _localSummary.copyWith(keyPoints: newKeyPoints);
              break;
            case 'decisions':
              final newDecisions = _decisionsControllers
                  .where((c) => c.text.isNotEmpty)
                  .map((c) => Decision(description: c.text))
                  .toList();
              _localSummary = _localSummary.copyWith(decisions: newDecisions);
              break;
          }

          _editModes[section] = false;
        });

        // Optional: Still call onEdit for any parent-level updates if needed
        // widget.onEdit?.call();

        ref.read(notificationServiceProvider.notifier).showSuccess(
          '${_getSectionName(section)} updated successfully',
        );
      }
    } catch (e) {
      if (mounted) {
        ref.read(notificationServiceProvider.notifier).showError(
          'Failed to update: $e',
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
      case 'summary':
        return 'Executive Summary';
      case 'keyPoints':
        return 'Key Points';
      case 'decisions':
        return 'Critical Decisions';
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
    final isMobile = screenWidth <= 768;
    final sectionSpacing = isMobile ? 12.0 : 16.0;
    final headerSpacing = isMobile ? 16.0 : 24.0;

    final content = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 1400),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
              // Common Header (like general format)
              _buildCommonHeader(context, isMobile),
              SizedBox(height: headerSpacing),

              // Executive Summary Text
              _buildCleanSection(
                context,
                sectionId: 'overview',
                title: 'Executive Overview',
                child: _buildExecutiveSummaryContent(context),
                editSection: 'summary',
              ),
              SizedBox(height: sectionSpacing),

              // Critical Decisions & Risks Grid
              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildCleanSection(
                        context,
                        sectionId: 'decisions',
                        title: 'Strategic Decisions',
                        child: _buildCriticalDecisionsContent(context),
                        editSection: 'decisions',
                        count: (_localSummary.decisions
                            ?.where((d) => d.importanceScore == 'high' || d.importanceScore == 'medium')
                            .length ?? 0),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildCleanSection(
                        context,
                        sectionId: 'risks',
                        title: 'Critical Risks & Blockers',
                        child: _buildCriticalRisksContent(context),
                        count: ((_localSummary.risks as List?)
                            ?.where((r) {
                              final severity = r['severity']?.toString().toLowerCase();
                              return severity == 'critical' || severity == 'high' || severity == 'medium';
                            })
                            .length ?? 0) + ((_localSummary.blockers as List?)?.length ?? 0),
                        isHighPriority: true,
                      ),
                    ),
                  ],
                )
              else ...[
                _buildCleanSection(
                  context,
                  sectionId: 'decisions',
                  title: 'Strategic Decisions',
                  child: _buildCriticalDecisionsContent(context),
                  editSection: 'decisions',
                  count: (_localSummary.decisions
                      ?.where((d) => d.importanceScore == 'high' || d.importanceScore == 'medium')
                      .length ?? 0),
                ),
                SizedBox(height: sectionSpacing),
                _buildCleanSection(
                  context,
                  sectionId: 'risks',
                  title: 'Critical Risks & Blockers',
                  child: _buildCriticalRisksContent(context),
                  count: ((_localSummary.risks as List?)
                      ?.where((r) {
                        final severity = r['severity']?.toString().toLowerCase();
                        return severity == 'critical' || severity == 'high' || severity == 'medium';
                      })
                      .length ?? 0) + ((_localSummary.blockers as List?)?.length ?? 0),
                  isHighPriority: true,
                ),
              ],
              SizedBox(height: isMobile ? 80 : 32),
            ],
          ),
    );

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : (isDesktop ? 120 : 24),
            vertical: isDesktop ? 32 : 16,
          ),
          child: isDesktop ? Center(child: content) : content,
        ),
      ),
    );
  }

  Widget _buildCommonHeader(BuildContext context, bool isMobile) {
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
                padding: isMobile ? const EdgeInsets.all(8) : null,
              ),
            ),
            SizedBox(width: isMobile ? 8 : 16),

            // Title (expanded to take available space)
            Expanded(
              child: Text(
                _localSummary.subject,
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.5,
                  fontSize: isMobile ? 18 : null,
                ),
                maxLines: isMobile ? 2 : 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            if (!isMobile) const SizedBox(width: 16),

            // Action buttons - Hidden on mobile, shown on tablet/desktop
            if (!isMobile) ...[
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
          ],
        ),
        SizedBox(height: isMobile ? 6 : 8),
        Padding(
          padding: EdgeInsets.only(left: isMobile ? 48 : 56),
          child: Wrap(
            spacing: 8,
            runSpacing: 6,
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
                      size: isMobile ? 12 : 14,
                      color: _getTypeColor(),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatSummaryType(_localSummary.summaryType),
                      style: textTheme.labelSmall?.copyWith(
                        color: _getTypeColor(),
                        fontWeight: FontWeight.w500,
                        fontSize: isMobile ? 11 : null,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.access_time,
                    size: isMobile ? 12 : 14,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    createdAt,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                      fontSize: isMobile ? 11 : null,
                    ),
                  ),
                ],
              ),
              // Format label - Show on all screens
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.deepOrange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: Colors.deepOrange.withValues(alpha: 0.3),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.business, size: isMobile ? 12 : 14, color: Colors.deepOrange),
                    const SizedBox(width: 4),
                    Text(
                      'EXECUTIVE',
                      style: textTheme.labelSmall?.copyWith(
                        color: Colors.deepOrange,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        fontSize: isMobile ? 10 : null,
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
    required String sectionId,
    required String title,
    required Widget child,
    String? editSection,
    int? count,
    bool isHighPriority = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth <= 768;
    final expansionNotifier = _expansionNotifiers[sectionId];

    // On mobile, make sections collapsible
    if (isMobile && expansionNotifier != null) {
      return ValueListenableBuilder<bool>(
        valueListenable: expansionNotifier,
        builder: (context, isExpanded, _) {
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
                // Section header - tappable on mobile
                InkWell(
                  onTap: () {
                    expansionNotifier.value = !expansionNotifier.value;
                  },
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLowest.withValues(alpha: 0.3),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                    ),
                    child: Row(
                      children: [
                        // Expand/collapse icon
                        Icon(
                          isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          size: 20,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            title,
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.2,
                              fontSize: 14,
                            ),
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
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                        if (editSection != null && isExpanded) ...[
                          const SizedBox(width: 8),
                          _buildEditButton(editSection),
                        ],
                      ],
                    ),
                  ),
                ),
                // Section content - collapsible
                if (isExpanded)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    child: child,
                  ),
              ],
            ),
          );
        },
      );
    }

    // Desktop/tablet: non-collapsible sections
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

  Widget _buildExecutiveSummaryContent(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isEditingSummary = _editModes['summary'] ?? false;
    final isEditingKeyPoints = _editModes['keyPoints'] ?? false;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth <= 768;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          if (isEditingSummary)
            TextField(
              controller: _bodyController,
              decoration: const InputDecoration(
                labelText: 'Executive Summary',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 8,
            )
          else if (isMobile && _localSummary.body.length > 300)
            _ReadMoreText(
              text: _localSummary.body,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.5,
              ),
              trimLength: 250,
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
                  'Strategic Highlights',
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
                                labelText: 'Key Point ${index + 1}',
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
                    label: const Text('Add Key Point'),
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

  Widget _buildCriticalDecisionsContent(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final criticalDecisions = _localSummary.decisions
        ?.where((d) => d.importanceScore == 'high' || d.importanceScore == 'medium')
        .toList() ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          if (criticalDecisions.isEmpty)
            Text(
              'No strategic decisions in this period',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            ...criticalDecisions.map((decision) => Padding(
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
                          decision.description,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (decision.rationale != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            decision.rationale!,
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

  Widget _buildCriticalRisksContent(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final risks = (_localSummary.risks as List?)
        ?.where((r) {
          final severity = r['severity']?.toString().toLowerCase();
          return severity == 'critical' || severity == 'high' || severity == 'medium';
        })
        .toList() ?? [];
    final blockers = (_localSummary.blockers as List?) ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          if (risks.isEmpty && blockers.isEmpty)
            Text(
              'No critical risks or blockers identified',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            )
          else ...[
            ...risks.map((risk) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'RISK',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                (risk['severity'] as String).toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          risk['description'] ?? risk['title'] ?? '',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (risk['mitigation'] != null || risk['mitigation_strategy'] != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Mitigation: ${risk['mitigation'] ?? risk['mitigation_strategy']}',
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
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'BLOCKER',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          blocker['description'] ?? blocker['title'] ?? '',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (blocker['owner'] != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Owner: ${blocker['owner']}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                        if (blocker['status'] != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Status: ${blocker['status']}',
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
}

// Read More Text Widget for Mobile
class _ReadMoreText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final int trimLength;

  const _ReadMoreText({
    required this.text,
    this.style,
    this.trimLength = 200,
  });

  @override
  State<_ReadMoreText> createState() => _ReadMoreTextState();
}

class _ReadMoreTextState extends State<_ReadMoreText> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final shouldTrim = widget.text.length > widget.trimLength;

    String displayText = widget.text;
    if (shouldTrim && !_isExpanded) {
      // Find a good breaking point (end of sentence or word)
      int breakPoint = widget.trimLength;
      final sentenceEnd = widget.text.lastIndexOf('.', breakPoint);
      if (sentenceEnd > widget.trimLength * 0.7) {
        breakPoint = sentenceEnd + 1;
      } else {
        final spaceIndex = widget.text.lastIndexOf(' ', breakPoint);
        if (spaceIndex > widget.trimLength * 0.8) {
          breakPoint = spaceIndex;
        }
      }
      displayText = '${widget.text.substring(0, breakPoint).trim()}...';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          displayText,
          style: widget.style,
        ),
        if (shouldTrim) ...[
          const SizedBox(height: 8),
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isExpanded ? 'Read less' : 'Read more',
                    style: widget.style?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 16,
                    color: colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}