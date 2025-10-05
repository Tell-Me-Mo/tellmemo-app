import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/datetime_utils.dart';
import '../../../../core/widgets/breadcrumb_navigation.dart';
import '../../data/models/summary_model.dart';
import 'risks_blockers_widget.dart';
import 'enhanced_action_items_widget.dart';
import 'enhanced_decisions_widget.dart';
import 'open_questions_widget.dart';
import 'summary_export_dialog.dart';

class SummaryDetailViewer extends ConsumerStatefulWidget {
  final SummaryModel summary;
  final VoidCallback? onExport;
  final VoidCallback? onCopy;
  final VoidCallback? onBack;
  final List<BreadcrumbItem>? breadcrumbs;

  const SummaryDetailViewer({
    super.key,
    required this.summary,
    this.onExport,
    this.onCopy,
    this.onBack,
    this.breadcrumbs,
  });

  @override
  ConsumerState<SummaryDetailViewer> createState() => _SummaryDetailViewerState();
}

class _SummaryDetailViewerState extends ConsumerState<SummaryDetailViewer> {
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _sectionKeys = {};
  final Map<String, ValueNotifier<bool>> _expansionNotifiers = {};
  String? _selectedSection;

  // Store local copy of summary data for instant updates
  late SummaryModel _localSummary;

  // Edit mode tracking
  final Map<String, bool> _editModes = {};
  bool _isSaving = false;

  // Controllers for editable fields
  late TextEditingController _bodyController;
  List<TextEditingController> _keyPointsControllers = [];
  List<TextEditingController> _agendaControllers = [];

  // Controllers for Risks
  List<TextEditingController> _risksDescriptionControllers = [];
  List<TextEditingController> _risksMitigationControllers = [];

  // Controllers for Blockers
  List<TextEditingController> _blockersDescriptionControllers = [];
  List<TextEditingController> _blockersResolutionControllers = [];

  // Controllers for Action Items
  List<TextEditingController> _actionItemsControllers = [];
  List<TextEditingController> _actionItemsAssigneeControllers = [];

  // Controllers for Decisions
  List<TextEditingController> _decisionsControllers = [];

  // Controllers for Lessons Learned
  List<TextEditingController> _lessonsControllers = [];

  // Controllers for Open Questions
  List<TextEditingController> _questionsControllers = [];

  @override
  void initState() {
    super.initState();
    _localSummary = widget.summary;
    // DEBUG: Log lessons learned data
    print('DEBUG: Summary has lessons learned: ${_localSummary.lessonsLearned != null}');
    if (_localSummary.lessonsLearned != null) {
      print('DEBUG: Number of lessons: ${_localSummary.lessonsLearned!.length}');
      print('DEBUG: Lessons data: ${_localSummary.lessonsLearned}');
    }
    _initializeSectionKeys();
    _initializeControllers();
  }

  @override
  void didUpdateWidget(SummaryDetailViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.summary != widget.summary) {
      _localSummary = widget.summary;
      _initializeControllers();
      _initializeSectionKeys();
    }
  }

  void _initializeControllers() {
    _bodyController = TextEditingController(text: _localSummary.body);

    _keyPointsControllers = (_localSummary.keyPoints ?? [])
        .map((point) => TextEditingController(text: point))
        .toList();

    _agendaControllers = (_localSummary.nextMeetingAgenda ?? [])
        .map((item) => TextEditingController(text: item.title))
        .toList();

    // Initialize Risks controllers
    _risksDescriptionControllers = (_localSummary.risks ?? [])
        .map((risk) => TextEditingController(text: risk['description'] ?? ''))
        .toList();
    _risksMitigationControllers = (_localSummary.risks ?? [])
        .map((risk) => TextEditingController(text: risk['mitigation'] ?? ''))
        .toList();

    // Initialize Blockers controllers
    _blockersDescriptionControllers = (_localSummary.blockers ?? [])
        .map((blocker) => TextEditingController(text: blocker['description'] ?? ''))
        .toList();
    _blockersResolutionControllers = (_localSummary.blockers ?? [])
        .map((blocker) => TextEditingController(text: blocker['resolution'] ?? ''))
        .toList();

    // Initialize Action Items controllers
    _actionItemsControllers = (_localSummary.actionItems ?? [])
        .map((item) => TextEditingController(text: item.description))
        .toList();
    _actionItemsAssigneeControllers = (_localSummary.actionItems ?? [])
        .map((item) => TextEditingController(text: item.assignee ?? ''))
        .toList();

    // Initialize Decisions controllers
    _decisionsControllers = (_localSummary.decisions ?? [])
        .map((decision) => TextEditingController(text: decision.description))
        .toList();

    // Initialize Lessons Learned controllers
    _lessonsControllers = (_localSummary.lessonsLearned ?? [])
        .map((lesson) => TextEditingController(text: lesson.description))
        .toList();

    // Initialize Open Questions controllers
    _questionsControllers = (_localSummary.communicationInsights?.unansweredQuestions ?? [])
        .map((question) => TextEditingController(text: question.question))
        .toList();
  }

  void _initializeSectionKeys() {
    _sectionKeys['summary'] = GlobalKey();
    _expansionNotifiers['summary'] = ValueNotifier(true);

    if (_localSummary.keyPoints?.isNotEmpty ?? false) {
      _sectionKeys['keyPoints'] = GlobalKey();
      _expansionNotifiers['keyPoints'] = ValueNotifier(true);
    }

    if (_localSummary.risks?.isNotEmpty ?? false) {
      _sectionKeys['risks'] = GlobalKey();
      _expansionNotifiers['risks'] = ValueNotifier(true);
    }

    if (_localSummary.blockers?.isNotEmpty ?? false) {
      _sectionKeys['blockers'] = GlobalKey();
      _expansionNotifiers['blockers'] = ValueNotifier(true);
    }

    if (_localSummary.actionItems?.isNotEmpty ?? false) {
      _sectionKeys['actions'] = GlobalKey();
      _expansionNotifiers['actions'] = ValueNotifier(true);
    }

    if (_localSummary.decisions?.isNotEmpty ?? false) {
      _sectionKeys['decisions'] = GlobalKey();
      _expansionNotifiers['decisions'] = ValueNotifier(false);
    }

    if (_localSummary.nextMeetingAgenda?.isNotEmpty ?? false) {
      _sectionKeys['agenda'] = GlobalKey();
      _expansionNotifiers['agenda'] = ValueNotifier(false);
    }

    if (_localSummary.sentimentAnalysis?.isNotEmpty ?? false) {
      _sectionKeys['sentiment'] = GlobalKey();
      _expansionNotifiers['sentiment'] = ValueNotifier(false);
    }

    if (_localSummary.communicationInsights != null) {
      _sectionKeys['communication'] = GlobalKey();
      _expansionNotifiers['communication'] = ValueNotifier(false);
    }

    if (_localSummary.lessonsLearned?.isNotEmpty ?? false) {
      _sectionKeys['lessons'] = GlobalKey();
      _expansionNotifiers['lessons'] = ValueNotifier(true);
    }

    // Initialize questions key if any questions exist
    if (_localSummary.communicationInsights?.unansweredQuestions.isNotEmpty ?? false) {
      _sectionKeys['questions'] = GlobalKey();
      _expansionNotifiers['questions'] = ValueNotifier(false);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _bodyController.dispose();
    for (final controller in _keyPointsControllers) {
      controller.dispose();
    }
    for (final controller in _agendaControllers) {
      controller.dispose();
    }
    for (final notifier in _expansionNotifiers.values) {
      notifier.dispose();
    }
    super.dispose();
  }

  void _scrollToSection(String sectionId) {
    setState(() {
      _selectedSection = sectionId;
    });

    // First expand the section
    _expansionNotifiers[sectionId]?.value = true;

    // Then scroll to it after a short delay to allow expansion animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 100), () {
        final key = _sectionKeys[sectionId];
        if (key != null && key.currentContext != null) {
          Scrollable.ensureVisible(
            key.currentContext!,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            alignment: 0.1,
          );
        }
      });
    });
  }

  void _toggleEditMode(String section) {
    setState(() {
      _editModes[section] = !(_editModes[section] ?? false);

      if (!_editModes[section]!) {
        // Reset controllers when canceling edit
        _initializeControllers();
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
        case 'agenda':
          updateData = {
            'next_meeting_agenda': _agendaControllers
                .where((c) => c.text.isNotEmpty)
                .map((c) => {'title': c.text, 'description': '', 'estimated_time': 0})
                .toList(),
          };
          break;
        case 'risks':
          updateData = {
            'risks': List.generate(_risksDescriptionControllers.length, (i) => {
              'description': _risksDescriptionControllers[i].text,
              'mitigation': _risksMitigationControllers[i].text,
              'severity': _localSummary.risks?[i]['severity'] ?? 'medium',
            }).where((r) => r['description']?.isNotEmpty ?? false).toList(),
          };
          break;
        case 'blockers':
          updateData = {
            'blockers': List.generate(_blockersDescriptionControllers.length, (i) => {
              'description': _blockersDescriptionControllers[i].text,
              'resolution': _blockersResolutionControllers[i].text,
              'priority': _localSummary.blockers?[i]['priority'] ?? 'high',
            }).where((b) => b['description']?.isNotEmpty ?? false).toList(),
          };
          break;
        case 'actionItems':
          updateData = {
            'action_items': List.generate(_actionItemsControllers.length, (i) => {
              'description': _actionItemsControllers[i].text,
              'assignee': _actionItemsAssigneeControllers[i].text,
              'urgency': _localSummary.actionItems?[i].urgency ?? 'medium',
              'due_date': _localSummary.actionItems?[i].dueDate,
            }).where((a) => a['description']?.isNotEmpty ?? false).toList(),
          };
          break;
        case 'decisions':
          updateData = {
            'decisions': List.generate(_decisionsControllers.length, (i) => {
              'description': _decisionsControllers[i].text,
              'importance_score': _localSummary.decisions?[i].importanceScore ?? '5',
              'rationale': _localSummary.decisions?[i].rationale,
            }).where((d) => d['description']?.isNotEmpty ?? false).toList(),
          };
          break;
        case 'lessons':
          updateData = {
            'lessons_learned': List.generate(_lessonsControllers.length, (i) => {
              'description': _lessonsControllers[i].text,
              'lesson_type': _localSummary.lessonsLearned?[i].lessonType ?? 'general',
              'impact': _localSummary.lessonsLearned?[i].impact ?? 'medium',
            }).where((l) => l['description']?.isNotEmpty ?? false).toList(),
          };
          break;
        case 'questions':
          updateData = {
            'communication_insights': {
              'unanswered_questions': List.generate(_questionsControllers.length, (i) => {
                'question': _questionsControllers[i].text,
                'urgency': _localSummary.communicationInsights?.unansweredQuestions[i].urgency ?? 'medium',
                'context': _localSummary.communicationInsights?.unansweredQuestions[i].context ?? '',
              }).where((q) => q['question']?.isNotEmpty ?? false).toList(),
              'effectiveness_score': _localSummary.communicationInsights?.effectivenessScore,
            },
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
            case 'agenda':
              final newAgenda = _agendaControllers
                  .where((c) => c.text.isNotEmpty)
                  .map((c) => AgendaItem(
                        title: c.text,
                        description: '',
                        estimatedTime: 0,
                      ))
                  .toList();
              _localSummary = _localSummary.copyWith(nextMeetingAgenda: newAgenda);
              break;
          }

          _editModes[section] = false;
        });

        // Optional: Still call onEdit for any parent-level updates if needed
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
      case 'summary':
        return 'Overview';
      case 'keyPoints':
        return 'Key Points';
      case 'agenda':
        return 'Next Meeting Agenda';
      case 'risks':
        return 'Risks';
      case 'blockers':
        return 'Blockers';
      case 'actionItems':
        return 'Action Items';
      case 'decisions':
        return 'Decisions';
      case 'lessons':
        return 'Lessons Learned';
      case 'questions':
        return 'Open Questions';
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
    final isDesktop = screenWidth > 1200;

    final content = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: isDesktop ? 1400 : double.infinity),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main Content Area
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                          // Clean Header
                          _buildCleanHeader(context),
                          const SizedBox(height: 24),

                          // Overview Section
                          _buildCleanSection(
                            context,
                            key: _sectionKeys['summary']!,
                            title: 'Overview',
                            child: _buildSummaryContent(context),
                            editSection: 'summary',
                          ),

                          // Key Points Section
                          if (_localSummary.keyPoints?.isNotEmpty ?? false) ...[
                            const SizedBox(height: 16),
                            _buildCleanSection(
                              context,
                              key: _sectionKeys['keyPoints']!,
                              title: 'Key Points',
                              child: _buildKeyPointsContent(context),
                              editSection: 'keyPoints',
                              count: _localSummary.keyPoints!.length,
                            ),
                          ],

                          // Risks Section
                          if (_localSummary.risks?.isNotEmpty ?? false) ...[
                            const SizedBox(height: 16),
                            _buildCleanSection(
                              context,
                              key: _sectionKeys['risks']!,
                              title: 'Risks',
                              child: _buildRisksOnlyContent(context),
                              count: _localSummary.risks!.length,
                              isHighPriority: true,
                              editSection: 'risks',
                            ),
                          ],

                          // Blockers Section
                          if (_localSummary.blockers?.isNotEmpty ?? false) ...[
                            const SizedBox(height: 16),
                            _buildCleanSection(
                              context,
                              key: _sectionKeys['blockers']!,
                              title: 'Blockers',
                              child: _buildBlockersOnlyContent(context),
                              count: _localSummary.blockers!.length,
                              isHighPriority: true,
                              editSection: 'blockers',
                            ),
                          ],

                          // Action Items Section
                          if (_localSummary.actionItems?.isNotEmpty ?? false) ...[
                            const SizedBox(height: 16),
                            _buildCleanSection(
                              context,
                              key: _sectionKeys['actions']!,
                              title: 'Action Items',
                              child: _buildActionItemsContent(context),
                              count: _localSummary.actionItems!.length,
                              editSection: 'actionItems',
                            ),
                          ],

                          // Decisions Section
                          if (_localSummary.decisions?.isNotEmpty ?? false) ...[
                            const SizedBox(height: 16),
                            _buildCleanSection(
                              context,
                              key: _sectionKeys['decisions']!,
                              title: 'Decisions',
                              child: _buildDecisionsContent(context),
                              count: _localSummary.decisions!.length,
                              editSection: 'decisions',
                            ),
                          ],

                          // Lessons Learned Section
                          if (_localSummary.lessonsLearned?.isNotEmpty ?? false) ...[
                            const SizedBox(height: 16),
                            _buildCleanSection(
                              context,
                              key: _sectionKeys['lessons']!,
                              title: 'Lessons Learned',
                              child: _buildLessonsContent(context),
                              count: _localSummary.lessonsLearned!.length,
                              editSection: 'lessons',
                            ),
                          ],

                          // Next Meeting Agenda
                          // DEBUG: Check next meeting agenda
                          () {
                            print('DEBUG: nextMeetingAgenda is null: ${_localSummary.nextMeetingAgenda == null}');
                            if (_localSummary.nextMeetingAgenda != null) {
                              print('DEBUG: nextMeetingAgenda length: ${_localSummary.nextMeetingAgenda!.length}');
                              print('DEBUG: nextMeetingAgenda data: ${_localSummary.nextMeetingAgenda}');
                            }
                            return const SizedBox.shrink();
                          }(),
                          if (_localSummary.nextMeetingAgenda?.isNotEmpty ?? false) ...[
                            const SizedBox(height: 16),
                            _buildCleanSection(
                              context,
                              key: _sectionKeys['agenda']!,
                              title: 'Next Meeting',
                              child: _buildAgendaContent(context),
                              editSection: 'agenda',
                            ),
                          ],

                          // Open Questions Section
                          if (_localSummary.communicationInsights?.unansweredQuestions.isNotEmpty ?? false) ...[
                            const SizedBox(height: 16),
                            _buildCleanSection(
                              context,
                              key: _sectionKeys['questions']!,
                              title: 'Open Questions',
                              child: _buildOpenQuestionsContent(context),
                              count: _localSummary.communicationInsights!.unansweredQuestions.length,
                              editSection: 'questions',
                            ),
                          ],

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),

                  // Divider between panels
                  if (isDesktop) ...[
                    Container(
                      width: 1,
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      decoration: BoxDecoration(
                        color: colorScheme.outlineVariant.withValues(alpha: 0.1),
                      ),
                    ),
                    SizedBox(
                      width: 280,
                      child: Column(
                        children: [
                          // Add spacing to align with Full Summary section
                          // This aligns the Contents header with the Full Summary title
                          const SizedBox(height: 96),
                          _buildCleanNavPanel(context),
                          const SizedBox(height: 24),
                          // Analytics Widgets
                          if (_localSummary.sentimentAnalysis?.isNotEmpty ?? false) ...[
                            _buildCompactSentimentWidget(context),
                            const SizedBox(height: 16),
                          ],
                          if (_localSummary.communicationInsights?.effectivenessScore != null) ...[
                            _buildCompactEffectivenessWidget(context),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
    );

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(isDesktop ? 32 : 16),
          child: isDesktop ? Center(child: content) : content,
        ),
      ),
    );
  }


  void _copyToClipboard(BuildContext context) {
    final buffer = StringBuffer();
    buffer.writeln('# ${_localSummary.subject}');
    buffer.writeln();

    if (_localSummary.keyPoints?.isNotEmpty ?? false) {
      buffer.writeln('## Key Points');
      for (final point in _localSummary.keyPoints!) {
        buffer.writeln('- $point');
      }
      buffer.writeln();
    }

    if (_localSummary.decisions?.isNotEmpty ?? false) {
      buffer.writeln('## Decisions');
      for (final decision in _localSummary.decisions!) {
        buffer.writeln('- ${decision.description}');
      }
      buffer.writeln();
    }

    if (_localSummary.actionItems?.isNotEmpty ?? false) {
      buffer.writeln('## Action Items');
      for (final item in _localSummary.actionItems!) {
        buffer.writeln('- ${item.description}');
      }
      buffer.writeln();
    }

    buffer.writeln('## Full Summary');
    buffer.writeln(_localSummary.body);

    Clipboard.setData(ClipboardData(text: buffer.toString()));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Summary copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => SummaryExportDialog(summary: _localSummary),
    );
  }

  // New clean design methods
  Widget _buildCleanHeader(BuildContext context) {
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
              onPressed: () => _showExportDialog(context),
              icon: Icon(Icons.download_outlined, size: 18),
              label: const Text('Export'),
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: () => _copyToClipboard(context),
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
                  color: _getSummaryTypeColor().withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: _getSummaryTypeColor().withValues(alpha: 0.3),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getSummaryIcon(),
                      size: 14,
                      color: _getSummaryTypeColor(),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatSummaryType(_localSummary.summaryType),
                      style: textTheme.labelSmall?.copyWith(
                        color: _getSummaryTypeColor(),
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
            if (_localSummary.format != 'general') ...[
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _localSummary.format.toUpperCase(),
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCleanSection(BuildContext context, {
    required Key key,
    required String title,
    required Widget child,
    String? editSection,
    int? count,
    bool isHighPriority = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      key: key,
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

  Widget _buildCleanNavPanel(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLowest.withValues(alpha: 0.3),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.1),
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.toc,
                  size: 18,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  'Contents',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          // Navigation items
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                _buildNavItem(context, 'summary', 'Full Summary', Icons.article_outlined),
                if (_localSummary.keyPoints?.isNotEmpty ?? false)
                  _buildNavItem(context, 'keyPoints', 'Key Points', Icons.lightbulb_outline,
                      count: _localSummary.keyPoints!.length),
                if (_localSummary.risks?.isNotEmpty ?? false)
                  _buildNavItem(context, 'risks', 'Risks', Icons.warning_amber_outlined,
                      count: _localSummary.risks!.length, isHighPriority: true),
                if (_localSummary.blockers?.isNotEmpty ?? false)
                  _buildNavItem(context, 'blockers', 'Blockers', Icons.block_outlined,
                      count: _localSummary.blockers!.length, isHighPriority: true),
                if (_localSummary.actionItems?.isNotEmpty ?? false)
                  _buildNavItem(context, 'actions', 'Action Items', Icons.assignment_outlined,
                      count: _localSummary.actionItems!.length),
                if (_localSummary.decisions?.isNotEmpty ?? false)
                  _buildNavItem(context, 'decisions', 'Decisions', Icons.check_circle_outline,
                      count: _localSummary.decisions!.length),
                if (_localSummary.lessonsLearned?.isNotEmpty ?? false)
                  _buildNavItem(context, 'lessons', 'Lessons Learned', Icons.school_outlined,
                      count: _localSummary.lessonsLearned!.length),
                if (_localSummary.nextMeetingAgenda?.isNotEmpty ?? false)
                  _buildNavItem(context, 'agenda', 'Next Meeting', Icons.event_outlined),
                if (_localSummary.communicationInsights?.unansweredQuestions.isNotEmpty ?? false)
                  _buildNavItem(context, 'questions', 'Open Questions', Icons.help_outline,
                      count: _localSummary.communicationInsights!.unansweredQuestions.length),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, String id, String title, IconData icon, {
    int? count,
    bool isHighPriority = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = _selectedSection == id;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: () => _scrollToSection(id),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primaryContainer.withValues(alpha: 0.3)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: isHighPriority
                    ? Colors.orange
                    : isSelected
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              if (count != null) ...[
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
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isHighPriority
                          ? Colors.orange
                          : colorScheme.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryContent(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final isEditing = _editModes['summary'] ?? false;

    if (isEditing) {
      return TextField(
        controller: _bodyController,
        maxLines: null,
        style: textTheme.bodyMedium,
        decoration: InputDecoration(
          hintText: 'Enter summary...',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(width: 0.5),
          ),
          contentPadding: const EdgeInsets.all(12),
        ),
      );
    }

    return SelectableText(
      _localSummary.body,
      style: textTheme.bodyMedium?.copyWith(
        height: 1.6,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
      ),
    );
  }

  Widget _buildKeyPointsContent(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isEditing = _editModes['keyPoints'] ?? false;

    if (isEditing) {
      return Column(
        children: [
          ..._keyPointsControllers.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: entry.value,
                      decoration: InputDecoration(
                        hintText: 'Key point ${entry.key + 1}',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: BorderSide(width: 0.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.remove_circle_outline, size: 20),
                    onPressed: () {
                      setState(() {
                        _keyPointsControllers.removeAt(entry.key);
                      });
                    },
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
            icon: Icon(Icons.add, size: 16),
            label: Text('Add Key Point'),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _localSummary.keyPoints!.map((point) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
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
                child: SelectableText(
                  point,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }


  Widget _buildRisksOnlyContent(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = _editModes['risks'] ?? false;

    if (isEditing) {
      return Column(
        children: [
          ..._risksDescriptionControllers.asMap().entries.map((entry) {
            final index = entry.key;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLowest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _risksDescriptionControllers[index],
                          decoration: InputDecoration(
                            labelText: 'Risk Description',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.remove_circle_outline, color: Colors.red.shade400),
                        onPressed: () {
                          setState(() {
                            _risksDescriptionControllers.removeAt(index);
                            _risksMitigationControllers.removeAt(index);
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _risksMitigationControllers[index],
                    decoration: InputDecoration(
                      labelText: 'Mitigation Strategy',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }).toList(),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _risksDescriptionControllers.add(TextEditingController());
                _risksMitigationControllers.add(TextEditingController());
              });
            },
            icon: const Icon(Icons.add_circle_outline, size: 20),
            label: const Text('Add Risk'),
          ),
        ],
      );
    }

    return RisksBlockersWidget(
      risks: _localSummary.risks,
      blockers: null,
    );
  }

  Widget _buildBlockersOnlyContent(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = _editModes['blockers'] ?? false;

    if (isEditing) {
      return Column(
        children: [
          ..._blockersDescriptionControllers.asMap().entries.map((entry) {
            final index = entry.key;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLowest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _blockersDescriptionControllers[index],
                          decoration: InputDecoration(
                            labelText: 'Blocker Description',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.remove_circle_outline, color: Colors.red.shade400),
                        onPressed: () {
                          setState(() {
                            _blockersDescriptionControllers.removeAt(index);
                            _blockersResolutionControllers.removeAt(index);
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _blockersResolutionControllers[index],
                    decoration: InputDecoration(
                      labelText: 'Resolution Plan',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }).toList(),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _blockersDescriptionControllers.add(TextEditingController());
                _blockersResolutionControllers.add(TextEditingController());
              });
            },
            icon: const Icon(Icons.add_circle_outline, size: 20),
            label: const Text('Add Blocker'),
          ),
        ],
      );
    }

    return RisksBlockersWidget(
      risks: null,
      blockers: _localSummary.blockers,
    );
  }

  Widget _buildActionItemsContent(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = _editModes['actionItems'] ?? false;

    if (isEditing) {
      return Column(
        children: [
          ..._actionItemsControllers.asMap().entries.map((entry) {
            final index = entry.key;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLowest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _actionItemsControllers[index],
                          decoration: InputDecoration(
                            labelText: 'Action Item',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.remove_circle_outline, color: Colors.red.shade400),
                        onPressed: () {
                          setState(() {
                            _actionItemsControllers.removeAt(index);
                            _actionItemsAssigneeControllers.removeAt(index);
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _actionItemsAssigneeControllers[index],
                    decoration: InputDecoration(
                      labelText: 'Assignee',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }).toList(),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _actionItemsControllers.add(TextEditingController());
                _actionItemsAssigneeControllers.add(TextEditingController());
              });
            },
            icon: const Icon(Icons.add_circle_outline, size: 20),
            label: const Text('Add Action Item'),
          ),
        ],
      );
    }

    return EnhancedActionItemsWidget(
      actionItems: _localSummary.actionItems ?? [],
    );
  }

  Widget _buildDecisionsContent(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = _editModes['decisions'] ?? false;

    if (isEditing) {
      return Column(
        children: [
          ..._decisionsControllers.asMap().entries.map((entry) {
            final index = entry.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _decisionsControllers[index],
                      decoration: InputDecoration(
                        hintText: 'Decision ${index + 1}',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.remove_circle_outline, size: 20, color: Colors.red.shade400),
                    onPressed: () {
                      setState(() {
                        _decisionsControllers.removeAt(index);
                      });
                    },
                  ),
                ],
              ),
            );
          }).toList(),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _decisionsControllers.add(TextEditingController());
              });
            },
            icon: const Icon(Icons.add_circle_outline, size: 20),
            label: const Text('Add Decision'),
          ),
        ],
      );
    }

    return EnhancedDecisionsWidget(
      decisions: _localSummary.decisions ?? [],
    );
  }

  Widget _buildLessonsContent(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = _editModes['lessons'] ?? false;

    if (isEditing) {
      return Column(
        children: [
          ..._lessonsControllers.asMap().entries.map((entry) {
            final index = entry.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _lessonsControllers[index],
                      decoration: InputDecoration(
                        hintText: 'Lesson ${index + 1}',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.remove_circle_outline, size: 20, color: Colors.red.shade400),
                    onPressed: () {
                      setState(() {
                        _lessonsControllers.removeAt(index);
                      });
                    },
                  ),
                ],
              ),
            );
          }).toList(),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _lessonsControllers.add(TextEditingController());
              });
            },
            icon: const Icon(Icons.add_circle_outline, size: 20),
            label: const Text('Add Lesson'),
          ),
        ],
      );
    }

    return Column(
      children: _localSummary.lessonsLearned!.asMap().entries.map((entry) {
        final index = entry.key;
        final lesson = entry.value;
        final lessonColor = _getLessonTypeColor(lesson.lessonType);
        final isLast = index == _localSummary.lessonsLearned!.length - 1;

        return Container(
          margin: EdgeInsets.only(bottom: isLast ? 0 : 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bullet point
              Container(
                margin: const EdgeInsets.only(top: 6),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: lessonColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Lesson description
                    SelectableText(
                      lesson.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.4,
                      ),
                    ),

                    // Show impact if it's high
                    if (lesson.impact == 'high' ||
                        lesson.lessonType == 'best_practice' ||
                        lesson.lessonType == 'success') ...[
                      const SizedBox(height: 4),
                      Text(
                        'Impact: ${lesson.impact}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Type label for important lessons only
              if (lesson.impact == 'high' || lesson.lessonType == 'best_practice')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: lessonColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    lesson.lessonType.replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: lessonColor,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAgendaContent(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isEditing = _editModes['agenda'] ?? false;

    if (isEditing) {
      return Column(
        children: [
          ..._agendaControllers.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: entry.value,
                      decoration: InputDecoration(
                        hintText: 'Agenda item ${entry.key + 1}',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: BorderSide(width: 0.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.remove_circle_outline, size: 20),
                    onPressed: () {
                      setState(() {
                        _agendaControllers.removeAt(entry.key);
                      });
                    },
                  ),
                ],
              ),
            );
          }),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _agendaControllers.add(TextEditingController());
              });
            },
            icon: Icon(Icons.add, size: 16),
            label: Text('Add Agenda Item'),
          ),
        ],
      );
    }

    return Column(
      children: _localSummary.nextMeetingAgenda!.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        final isLast = index == _localSummary.nextMeetingAgenda!.length - 1;

        return Container(
          margin: EdgeInsets.only(bottom: isLast ? 0 : 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bullet point
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

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Agenda item title
                    SelectableText(
                      item.title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.4,
                      ),
                    ),

                    // Show description if available
                    if (item.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Time estimate (only if present and > 0)
              if (item.estimatedTime > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${item.estimatedTime}m',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // Export method removed - using _showExportDialog instead

  // Removed duplicate _printSummary method - using the one with BuildContext parameter


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

  Color _getSummaryTypeColor() {
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

  Color _getLessonTypeColor(String type) {
    switch (type) {
      case 'success':
        return Colors.green;
      case 'improvement':
        return Colors.blue;
      case 'challenge':
        return Colors.orange;
      case 'best_practice':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }


  Widget _buildCompactSentimentWidget(BuildContext context) {
    final theme = Theme.of(context);
    final overallScore = _localSummary.sentimentAnalysis!['overall_score'] as double? ?? 0.0;
    final sentiment = _getSentimentLabel(overallScore);
    final color = _getSentimentColor(overallScore);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.mood_outlined,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Meeting Sentiment',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Score display
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '${(overallScore * 100).toInt()}%',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    sentiment,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Icon(
                _getSentimentIcon(overallScore),
                color: color,
                size: 24,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          LinearProgressIndicator(
            value: overallScore.clamp(0.0, 1.0),
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            color: color,
            minHeight: 6,
          ),
        ],
      ),
    );
  }

  Widget _buildCompactEffectivenessWidget(BuildContext context) {
    final theme = Theme.of(context);
    final score = _localSummary.communicationInsights!.effectivenessScore!;
    final overallPercent = (score.overall * 100).toInt();
    final color = _getEffectivenessColor(score.overall);
    final label = _getEffectivenessLabel(score.overall);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.speed_outlined,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Communication',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Score display
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$overallPercent%',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Icon(
                Icons.insights,
                color: color,
                size: 24,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Mini metrics
          Column(
            children: [
              _buildMiniMetric(context, 'Clarity', score.clarityScore),
              const SizedBox(height: 4),
              _buildMiniMetric(context, 'Efficiency', score.timeEfficiency),
              const SizedBox(height: 4),
              _buildMiniMetric(context, 'Participation', score.participationBalance),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMetric(BuildContext context, String label, double value) {
    final theme = Theme.of(context);
    final percent = (value * 100).toInt();

    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 11,
            ),
          ),
        ),
        Expanded(
          child: LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            color: theme.colorScheme.primary.withValues(alpha: 0.7),
            minHeight: 3,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 32,
          child: Text(
            '$percent%',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: 11,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  String _getSentimentLabel(double score) {
    if (score >= 0.6) return 'Positive';
    if (score >= 0.4) return 'Neutral';
    if (score >= 0.2) return 'Mixed';
    return 'Negative';
  }

  Color _getSentimentColor(double score) {
    if (score >= 0.6) return Colors.green.shade600;
    if (score >= 0.4) return Colors.blue.shade600;
    if (score >= 0.2) return Colors.orange.shade600;
    return Colors.red.shade600;
  }

  IconData _getSentimentIcon(double score) {
    if (score >= 0.6) return Icons.sentiment_very_satisfied_outlined;
    if (score >= 0.4) return Icons.sentiment_neutral_outlined;
    if (score >= 0.2) return Icons.sentiment_dissatisfied_outlined;
    return Icons.sentiment_very_dissatisfied_outlined;
  }

  Color _getEffectivenessColor(double score) {
    if (score >= 0.8) return Colors.green.shade600;
    if (score >= 0.6) return Colors.blue.shade600;
    if (score >= 0.4) return Colors.orange.shade600;
    return Colors.red.shade600;
  }

  String _getEffectivenessLabel(double score) {
    if (score >= 0.8) return 'Excellent';
    if (score >= 0.6) return 'Good';
    if (score >= 0.4) return 'Fair';
    return 'Poor';
  }

  Widget _buildOpenQuestionsContent(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = _editModes['questions'] ?? false;

    if (isEditing) {
      return Column(
        children: [
          ..._questionsControllers.asMap().entries.map((entry) {
            final index = entry.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _questionsControllers[index],
                      decoration: InputDecoration(
                        hintText: 'Question ${index + 1}',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.remove_circle_outline, size: 20, color: Colors.red.shade400),
                    onPressed: () {
                      setState(() {
                        _questionsControllers.removeAt(index);
                      });
                    },
                  ),
                ],
              ),
            );
          }).toList(),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _questionsControllers.add(TextEditingController());
              });
            },
            icon: const Icon(Icons.add_circle_outline, size: 20),
            label: const Text('Add Question'),
          ),
        ],
      );
    }

    return OpenQuestionsWidget(
      questions: _localSummary.communicationInsights?.unansweredQuestions ?? [],
    );
  }
}