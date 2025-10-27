import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../projects/domain/entities/project.dart';
import '../../domain/services/audio_recording_service.dart';
import '../../../projects/presentation/providers/projects_provider.dart';
import '../../../meetings/presentation/providers/upload_provider.dart';
import '../providers/recording_provider.dart';
import 'recording_button.dart';
import 'compact_recording_header.dart';
import '../../../content/presentation/providers/processing_jobs_provider.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/utils/screen_info.dart';
import '../../../live_insights/presentation/widgets/live_transcription_widget.dart';
import '../../../live_insights/data/models/transcript_model.dart';
import '../../../live_insights/data/models/live_insight_model.dart';

enum ProjectSelectionMode { automatic, manual, specific }

class RecordingPanel extends ConsumerStatefulWidget {
  final Project? project;
  final VoidCallback onClose;
  final VoidCallback? onRecordingComplete;
  final double rightOffset;

  const RecordingPanel({
    super.key,
    this.project,
    required this.onClose,
    this.onRecordingComplete,
    this.rightOffset = 0.0,
  });

  @override
  ConsumerState<RecordingPanel> createState() => _RecordingPanelState();
}

class _RecordingPanelState extends ConsumerState<RecordingPanel> with TickerProviderStateMixin {
  final _titleController = TextEditingController();
  ProjectSelectionMode _projectMode = ProjectSelectionMode.automatic;
  String? _selectedProjectId;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  // Live transcription state
  final List<TranscriptModel> _transcripts = [];
  bool _transcriptionCollapsed = false;

  // Live insights state (questions and actions)
  final List<LiveQuestion> _questions = [];
  final List<LiveAction> _actions = [];

  @override
  void initState() {
    super.initState();

    // If specific project is provided, use specific mode
    if (widget.project != null) {
      _projectMode = ProjectSelectionMode.specific;
      _selectedProjectId = widget.project!.id;
    }

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _handleClose() async {
    // Check if recording is active
    final recordingState = ref.read(recordingNotifierProvider);
    if (recordingState.state == RecordingState.recording ||
        recordingState.state == RecordingState.paused) {
      // Show confirmation dialog
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cancel Recording?'),
          content: const Text(
            'Are you sure you want to cancel this recording? All recorded audio will be lost.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep Recording'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );

      if (confirm != true) {
        return; // User chose to keep recording
      }

      // Cancel the recording
      await ref.read(recordingNotifierProvider.notifier).cancelRecording();
      if (mounted) {
        ref.read(notificationServiceProvider.notifier).showInfo('Recording cancelled');
      }
    }

    // Close the panel
    _animationController.reverse().then((_) {
      widget.onClose();
    });
  }

  Future<void> _handleRecordingComplete(String? filePath) async {
    if (filePath == null) return;

    // Determine project selection
    String projectId;
    bool useAiMatching = false;

    if (_projectMode == ProjectSelectionMode.specific && widget.project != null) {
      projectId = widget.project!.id;
    } else if (_projectMode == ProjectSelectionMode.manual && _selectedProjectId != null) {
      projectId = _selectedProjectId!;
    } else if (_projectMode == ProjectSelectionMode.automatic) {
      projectId = "auto";
      useAiMatching = true;
    } else {
      if (mounted) {
        ref.read(notificationServiceProvider.notifier).showWarning('Please select a project or choose automatic matching');
      }
      return;
    }

    try {
      final uploadProvider = ref.read(uploadContentProvider.notifier);
      final title = _titleController.text.isNotEmpty
          ? _titleController.text
          : 'Recording - ${DateTime.now().toLocal().toString().substring(0, 16)}';

      final response = await uploadProvider.uploadAudioFile(
        projectId: projectId,
        filePath: filePath,
        fileName: 'recording.wav',
        title: title,
        contentType: 'meeting',
        date: DateTime.now().toIso8601String().split('T')[0],
        useAiMatching: useAiMatching,
      );

      if (response != null && response['job_id'] != null) {
        final jobId = response['job_id'];
        final contentId = response['id'] as String?;
        final returnedProjectId = response['project_id'];

        final projectIdToUse = returnedProjectId ?? _selectedProjectId ?? widget.project?.id ?? '';

        if (useAiMatching && returnedProjectId != null) {
          ref.invalidate(projectsListProvider);
          await ref.read(projectsListProvider.future);
        }

        await ref.read(processingJobsProvider.notifier).addJob(
          jobId: jobId,
          contentId: contentId,
          projectId: projectIdToUse,
        );

        if (mounted) {
          _handleClose();
          widget.onRecordingComplete?.call();
        }
      }
    } catch (e) {
      if (mounted) {
        ref.read(notificationServiceProvider.notifier).showError('Failed to upload recording: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final recordingState = ref.watch(recordingNotifierProvider);
    final screenInfo = ScreenInfo.fromContext(context);
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final screenWidth = MediaQuery.of(context).size.width;

    // Responsive panel width based on AI Assistant state
    double panelWidth;
    if (screenInfo.isMobile) {
      // Mobile: Always full width
      panelWidth = screenWidth;
    } else if (recordingState.aiAssistantEnabled) {
      // Desktop with AI: 80% of screen width for spacious layout
      panelWidth = screenWidth * 0.8;
    } else {
      // Desktop without AI: Narrow panel (original behavior)
      panelWidth = screenWidth * 0.45;
      const maxWidth = 600.0;
      if (panelWidth > maxWidth) panelWidth = maxWidth;
    }

    final actualWidth = panelWidth;

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // Backdrop
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return _animationController.value > 0
                  ? GestureDetector(
                      onTap: _handleClose,
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.5 * _animationController.value),
                      ),
                    )
                  : const SizedBox.shrink();
            },
          ),
          // Panel with animated width
          Positioned(
            right: widget.rightOffset,
            top: 0,
            bottom: screenInfo.isMobile ? keyboardHeight : 0,
            child: SlideTransition(
              position: _slideAnimation,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOutCubic,
                width: actualWidth,
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(-5, 0),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Header
                    Container(
                      padding: EdgeInsets.only(
                        left: 24,
                        right: 16,
                        top: MediaQuery.of(context).padding.top + 16,
                        bottom: 16,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        border: Border(
                          bottom: BorderSide(
                            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.mic,
                              size: 24,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Record Meeting',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.project != null
                                      ? widget.project!.name
                                      : 'Record and transcribe meeting',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: _handleClose,
                            tooltip: 'Close',
                          ),
                        ],
                      ),
                    ),
                    // Content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Project Selection (if not specific project)
                            if (widget.project == null) ...[
                              _buildProjectSelection(),
                              const SizedBox(height: 24),
                            ],
                            // Title Field
                            _buildTitleField(),
                            const SizedBox(height: 24),
                            // AI Assistant Toggle
                            _buildAiAssistantToggle(recordingState),
                            // AI Assistant Content (when enabled)
                            AnimatedSize(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeInOut,
                              child: recordingState.aiAssistantEnabled
                                  ? Column(
                                      children: [
                                        const SizedBox(height: 16),
                                        _buildAiAssistantContent(recordingState),
                                      ],
                                    )
                                  : const SizedBox.shrink(),
                            ),
                            const SizedBox(height: 32),
                            // Recording Button
                            _buildRecordingSection(recordingState),
                          ],
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
    );
  }

  Widget _buildProjectSelection() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final projectsAsync = ref.watch(projectsListProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Project Selection',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 8),
            if (_projectMode == ProjectSelectionMode.automatic)
              Tooltip(
                message: 'AI will analyze your recording and automatically match it to an existing project or create a new one',
                child: Icon(
                  Icons.info_outline,
                  size: 16,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        // Segmented Control
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              Expanded(
                child: _buildSegmentedButton(
                  label: 'AI Auto-match',
                  icon: Icons.auto_awesome,
                  isSelected: _projectMode == ProjectSelectionMode.automatic,
                  onTap: () => setState(() {
                    _projectMode = ProjectSelectionMode.automatic;
                    _selectedProjectId = null;
                  }),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _buildSegmentedButton(
                  label: 'Select Project',
                  icon: Icons.format_list_bulleted,
                  isSelected: _projectMode == ProjectSelectionMode.manual,
                  onTap: () => setState(() {
                    _projectMode = ProjectSelectionMode.manual;
                  }),
                ),
              ),
            ],
          ),
        ),
        // Dropdown
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: _projectMode == ProjectSelectionMode.manual
              ? Column(
                  children: [
                    const SizedBox(height: 16),
                    projectsAsync.when(
                      data: (projects) => _buildProjectDropdown(projects),
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(8),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      error: (error, _) => Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          'Error loading projects',
                          style: TextStyle(color: colorScheme.error),
                        ),
                      ),
                    ),
                  ],
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildSegmentedButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primary.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isSelected
                ? Border.all(color: colorScheme.primary.withValues(alpha: 0.3))
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProjectDropdown(List<Project> projects) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DropdownButtonFormField<String>(
      key: ValueKey(_selectedProjectId),
      initialValue: _selectedProjectId,
      decoration: InputDecoration(
        hintText: 'Choose a project',
        hintStyle: TextStyle(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
        ),
        prefixIcon: Icon(
          Icons.folder_outlined,
          color: _selectedProjectId != null
              ? colorScheme.primary
              : colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          size: 20,
        ),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
      ),
      dropdownColor: colorScheme.surfaceContainer,
      borderRadius: BorderRadius.circular(12),
      elevation: 8,
      style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
      icon: Icon(
        Icons.keyboard_arrow_down_rounded,
        color: colorScheme.onSurfaceVariant,
      ),
      isExpanded: true,
      items: projects.map((project) {
        return DropdownMenuItem<String>(
          value: project.id,
          child: Text(
            project.name,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (value) => setState(() {
        _selectedProjectId = value;
      }),
    );
  }

  Widget _buildTitleField() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Meeting Title (optional)',
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _titleController,
          decoration: InputDecoration(
            hintText: 'Enter a descriptive title for this recording',
            hintStyle: TextStyle(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            prefixIcon: Icon(
              Icons.title,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              size: 20,
            ),
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: colorScheme.primary,
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAiAssistantToggle(RecordingStateModel recordingState) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: recordingState.aiAssistantEnabled
            ? colorScheme.primaryContainer.withValues(alpha: 0.3)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: recordingState.aiAssistantEnabled
              ? colorScheme.primary.withValues(alpha: 0.5)
              : colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.auto_awesome,
            size: 20,
            color: recordingState.aiAssistantEnabled
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Assistant',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: recordingState.aiAssistantEnabled
                        ? colorScheme.primary
                        : colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Live transcription, questions & actions',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: recordingState.aiAssistantEnabled,
            onChanged: (_) {
              ref.read(recordingNotifierProvider.notifier).toggleAiAssistant();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAiAssistantContent(RecordingStateModel recordingState) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;

    // Determine layout based on screen size
    final bool isDesktop = screenWidth >= 1024;
    final bool isTablet = screenWidth >= 768 && screenWidth < 1024;
    final bool isMobile = screenWidth < 768;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Compact recording header (when recording)
        if (recordingState.state == RecordingState.recording ||
            recordingState.state == RecordingState.paused)
          CompactRecordingHeader(
            recordingState: recordingState,
            onPause: () => ref.read(recordingNotifierProvider.notifier).pauseRecording(),
            onResume: () => ref.read(recordingNotifierProvider.notifier).resumeRecording(),
            onStop: () => ref.read(recordingNotifierProvider.notifier).stopRecording(),
            aiAssistantEnabled: recordingState.aiAssistantEnabled,
          ),

        const SizedBox(height: 16),

        // Main content area with responsive layout
        Expanded(
          child: Container(
            padding: EdgeInsets.all(isMobile ? 12 : 20),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 2-column layout for Questions and Actions (desktop/tablet)
                // Single column with tabs for mobile
                Expanded(
                  flex: 2,
                  child: (isDesktop || isTablet)
                      ? _buildTwoColumnLayout(colorScheme, isMobile: isMobile)
                      : _buildMobileTabLayout(colorScheme),
                ),

                const SizedBox(height: 16),

                // Live Transcript at bottom (collapsible)
                _buildLiveTranscriptSection(colorScheme, isMobile: isMobile),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTwoColumnLayout(ColorScheme colorScheme, {required bool isMobile}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Questions column (left)
        Expanded(
          child: _buildQuestionsSection(colorScheme, isMobile: isMobile),
        ),

        const SizedBox(width: 16),

        // Actions column (right)
        Expanded(
          child: _buildActionsSection(colorScheme, isMobile: isMobile),
        ),
      ],
    );
  }

  Widget _buildMobileTabLayout(ColorScheme colorScheme) {
    // Mobile uses tabs to switch between Questions and Actions
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.help_outline, size: 18),
                    const SizedBox(width: 8),
                    Text('Questions (${_questions.length})'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_outline, size: 18),
                    const SizedBox(width: 8),
                    Text('Actions (${_actions.length})'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TabBarView(
              children: [
                _buildQuestionsSection(colorScheme, isMobile: true),
                _buildActionsSection(colorScheme, isMobile: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionsSection(ColorScheme colorScheme, {required bool isMobile}) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.help_outline, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Questions (${_questions.length})',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: colorScheme.outlineVariant.withValues(alpha: 0.3)),

          // Questions list
          Expanded(
            child: _questions.isEmpty
                ? _buildEmptyState(
                    icon: Icons.question_answer,
                    title: 'Listening for questions...',
                    subtitle: 'Questions detected in the conversation will appear here',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _questions.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final question = _questions[index];
                      return Container(
                        // Question card placeholder - will use LiveQuestionCard widget
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(question.text),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection(ColorScheme colorScheme, {required bool isMobile}) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Actions (${_actions.length})',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: colorScheme.outlineVariant.withValues(alpha: 0.3)),

          // Actions list
          Expanded(
            child: _actions.isEmpty
                ? _buildEmptyState(
                    icon: Icons.task_alt,
                    title: 'Tracking actions...',
                    subtitle: 'Action items mentioned will appear here',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _actions.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final action = _actions[index];
                      return Container(
                        // Action card placeholder - will use LiveActionCard widget
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(action.description),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveTranscriptSection(ColorScheme colorScheme, {required bool isMobile}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _transcriptionCollapsed ? 80 : (isMobile ? 150 : 200),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          // Header with collapse button
          InkWell(
            onTap: () {
              setState(() {
                _transcriptionCollapsed = !_transcriptionCollapsed;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.mic, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Live Transcript',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _transcriptionCollapsed
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                  ),
                ],
              ),
            ),
          ),
          if (!_transcriptionCollapsed) ...[
            Divider(height: 1, color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
            Expanded(
              child: LiveTranscriptionWidget(
                transcripts: _transcripts,
                isCollapsed: _transcriptionCollapsed,
                onToggleCollapse: () {
                  setState(() {
                    _transcriptionCollapsed = !_transcriptionCollapsed;
                  });
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingSection(RecordingStateModel recordingState) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: EdgeInsets.all(
        recordingState.state == RecordingState.idle ? 40 : 20,
      ),
      decoration: BoxDecoration(
        border: Border.all(
          color: recordingState.state == RecordingState.recording
              ? Colors.red.withValues(alpha: 0.3)
              : colorScheme.outline.withValues(alpha: 0.2),
          width: recordingState.state == RecordingState.recording ? 2 : 1.5,
        ),
        borderRadius: BorderRadius.circular(12),
        color: recordingState.state == RecordingState.recording
            ? Colors.red.withValues(alpha: 0.05)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.05),
      ),
      child: Center(
        child: RecordingButton(
          onRecordingComplete: _handleRecordingComplete,
          projectId: _projectMode == ProjectSelectionMode.automatic
              ? 'auto'
              : (_selectedProjectId ?? widget.project?.id ?? 'auto'),
          meetingTitle: _titleController.text,
        ),
      ),
    );
  }
}
