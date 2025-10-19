import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/projects/domain/entities/project.dart';
import '../../features/audio_recording/domain/services/audio_recording_service.dart';
import '../../features/projects/presentation/providers/projects_provider.dart';
import '../../features/meetings/presentation/providers/upload_provider.dart';
import '../../features/audio_recording/presentation/providers/recording_provider.dart';
import '../../features/audio_recording/presentation/widgets/recording_button.dart';
import '../../features/content/presentation/providers/processing_jobs_provider.dart';
import '../../features/meetings/presentation/widgets/live_insights_panel.dart';
import '../../features/live_insights/domain/models/live_insight_model.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/auth_service.dart';

enum ProjectSelectionMode { automatic, manual, specific }

// Constants for commonly used values
class _DialogConstants {
  static const double borderRadius = 12.0;
  static const double largeBorderRadius = 20.0;
  static const double padding = 20.0;
  static const double smallPadding = 16.0;
  static const double tinyPadding = 12.0;
  static const double spacing = 16.0;
  static const double smallSpacing = 8.0;
  static const double tinySpacing = 4.0;

  // Opacity values
  static const double highOpacity = 0.3;
  static const double mediumOpacity = 0.2;
  static const double lowOpacity = 0.1;
  static const double minimalOpacity = 0.05;
}

class RecordMeetingDialog extends ConsumerStatefulWidget {
  final Project? project; // Can be null when called from dashboard
  final VoidCallback? onRecordingComplete;

  const RecordMeetingDialog({
    super.key,
    this.project,
    this.onRecordingComplete,
  });

  @override
  ConsumerState<RecordMeetingDialog> createState() => _RecordMeetingDialogState();
}

class _RecordMeetingDialogState extends ConsumerState<RecordMeetingDialog> {
  final _titleController = TextEditingController();
  ProjectSelectionMode _projectMode = ProjectSelectionMode.automatic;
  String? _selectedProjectId;
  bool _enableLiveInsights = false; // Toggle for live insights

  @override
  void initState() {
    super.initState();
    // If specific project is provided, use specific mode
    if (widget.project != null) {
      _projectMode = ProjectSelectionMode.specific;
      _selectedProjectId = widget.project!.id;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  // Helper function to map LiveInsightType to InsightType for the panel
  InsightType _mapInsightType(LiveInsightType type) {
    switch (type) {
      case LiveInsightType.actionItem:
        return InsightType.actionItem;
      case LiveInsightType.decision:
        return InsightType.decision;
      case LiveInsightType.question:
        return InsightType.question;
      case LiveInsightType.risk:
        return InsightType.risk;
      case LiveInsightType.keyPoint:
        return InsightType.keyPoint;
      case LiveInsightType.relatedDiscussion:
        return InsightType.relatedDiscussion;
      case LiveInsightType.contradiction:
        return InsightType.contradiction;
      case LiveInsightType.missingInfo:
        return InsightType.missingInfo;
    }
  }

  // Helper function to map LiveInsightPriority to InsightPriority
  InsightPriority _mapInsightPriority(LiveInsightPriority priority) {
    switch (priority) {
      case LiveInsightPriority.critical:
        return InsightPriority.critical;
      case LiveInsightPriority.high:
        return InsightPriority.high;
      case LiveInsightPriority.medium:
        return InsightPriority.medium;
      case LiveInsightPriority.low:
        return InsightPriority.low;
    }
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
      projectId = "auto"; // Special ID for automatic matching
      useAiMatching = true;
    } else {
      if (mounted) {
        ref.read(notificationServiceProvider.notifier).showWarning('Please select a project or choose automatic matching');
      }
      return;
    }

    // Upload the audio file with transcription
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

        // Get the actual project ID for tracking
        final projectIdToUse = returnedProjectId ?? _selectedProjectId ?? widget.project?.id ?? '';

        // Refresh projects list FIRST if we used AI matching
        // This ensures the new project exists before we add the job
        if (useAiMatching && returnedProjectId != null) {
          ref.invalidate(projectsListProvider);
          // Force refresh to complete
          await ref.read(projectsListProvider.future);
        }

        // Add job to processing tracker
        await ref.read(processingJobsProvider.notifier).addJob(
          jobId: jobId,
          contentId: contentId,
          projectId: projectIdToUse,
        );

        // Close recording dialog
        if (mounted) {
          Navigator.of(context).pop();
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
    final recordingState = ref.watch(recordingNotifierProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header with consistent design
        _DialogHeader(
          project: widget.project,
          colorScheme: colorScheme,
          textTheme: textTheme,
          onClose: () {
            // Cancel any ongoing recording before closing
            final recordingState = ref.read(recordingNotifierProvider);
            if (recordingState.state == RecordingState.recording ||
                recordingState.state == RecordingState.paused) {
              ref.read(recordingNotifierProvider.notifier).cancelRecording();
            }
            Navigator.of(context).pop();
          },
        ),
        // Content section with padding - wrapped in Flexible to prevent overflow
        Flexible(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: _DialogConstants.padding,
                vertical: _DialogConstants.padding,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [

                    // Project Selection (if not specific project)
                    if (widget.project == null) ...[
                      _ProjectSelectionSection(
                        projectMode: _projectMode,
                        selectedProjectId: _selectedProjectId,
                        onModeChanged: (mode) => setState(() {
                          _projectMode = mode;
                          if (mode == ProjectSelectionMode.automatic) {
                            _selectedProjectId = null;
                          }
                        }),
                        onProjectSelected: (projectId) => setState(() {
                          _selectedProjectId = projectId;
                        }),
                        colorScheme: colorScheme,
                        textTheme: textTheme,
                      ),
                      const SizedBox(height: _DialogConstants.padding),
                    ],

                    // Title Field with consistent styling
                    _TitleField(
                      controller: _titleController,
                      colorScheme: colorScheme,
                    ),
                    const SizedBox(height: _DialogConstants.spacing),

                    // Live Insights Toggle
                    CheckboxListTile(
                      value: _enableLiveInsights,
                      onChanged: (value) {
                        setState(() {
                          _enableLiveInsights = value ?? false;
                        });
                      },
                      title: Text(
                        'Enable Live Insights',
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        'Get real-time action items, decisions, and risks during the meeting',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      secondary: Icon(
                        Icons.lightbulb_outline,
                        color: colorScheme.primary,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: _DialogConstants.tinyPadding,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(_DialogConstants.borderRadius),
                      ),
                      tileColor: _enableLiveInsights
                          ? colorScheme.primaryContainer.withValues(alpha: 0.3)
                          : null,
                    ),
                    const SizedBox(height: _DialogConstants.spacing),

                  // Recording Button Container with dynamic sizing
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: EdgeInsets.all(
                      recordingState.state == RecordingState.idle
                        ? _DialogConstants.padding * 2
                        : _DialogConstants.padding,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: recordingState.state == RecordingState.recording
                            ? Colors.red.withValues(alpha: _DialogConstants.highOpacity)
                            : colorScheme.outline.withValues(alpha: _DialogConstants.mediumOpacity),
                        width: recordingState.state == RecordingState.recording ? 2 : 1.5,
                      ),
                      borderRadius: BorderRadius.circular(_DialogConstants.borderRadius),
                      color: recordingState.state == RecordingState.recording
                          ? Colors.red.withValues(alpha: _DialogConstants.minimalOpacity)
                          : colorScheme.surfaceContainerHighest.withValues(alpha: 0.05),
                    ),
                    child: Center(
                      child: FutureBuilder<String?>(
                        future: ref.read(authServiceProvider).getToken(),
                        builder: (context, snapshot) {
                          final authToken = snapshot.data;
                          return RecordingButton(
                            onRecordingComplete: _handleRecordingComplete,
                            projectId: _projectMode == ProjectSelectionMode.automatic ? 'auto' :
                                      (_selectedProjectId ?? widget.project?.id ?? 'auto'),
                            meetingTitle: _titleController.text,
                            enableLiveInsights: _enableLiveInsights,
                            authToken: authToken,
                          );
                        },
                      ),
                    ),
                  ),

                  // Live Insights Panel (shown during recording if enabled)
                  if (recordingState.liveInsightsEnabled &&
                      (recordingState.state == RecordingState.recording ||
                       recordingState.state == RecordingState.paused)) ...[
                    const SizedBox(height: _DialogConstants.spacing),
                    Container(
                      constraints: const BoxConstraints(
                        maxHeight: 400,
                        minHeight: 200,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: colorScheme.primary.withValues(alpha: 0.3),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(_DialogConstants.borderRadius),
                        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.05),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(_DialogConstants.borderRadius),
                        child: LiveInsightsPanel(
                          insights: recordingState.liveInsights.map((insight) {
                            return MeetingInsight(
                              insightId: insight.insightId,
                              type: _mapInsightType(insight.type),
                              priority: _mapInsightPriority(insight.priority),
                              content: insight.content,
                              context: insight.context,
                              timestamp: insight.timestamp,
                              assignedTo: insight.assignedTo,
                              dueDate: insight.dueDate,
                              confidenceScore: insight.confidenceScore,
                            );
                          }).toList(),
                          isRecording: recordingState.state == RecordingState.recording,
                          onClose: null, // Don't allow closing during recording
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        // Bottom actions bar
        _DialogActions(
          isRecording: recordingState.state == RecordingState.recording ||
                      recordingState.state == RecordingState.paused,
          colorScheme: colorScheme,
        ),
      ],
    );
  }
}

// Extracted Header Widget
class _DialogHeader extends StatelessWidget {
  final Project? project;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final VoidCallback onClose;

  const _DialogHeader({
    required this.project,
    required this.colorScheme,
    required this.textTheme,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(_DialogConstants.padding),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: _DialogConstants.lowOpacity),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(_DialogConstants.largeBorderRadius),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: _DialogConstants.lowOpacity),
              borderRadius: BorderRadius.circular(_DialogConstants.borderRadius),
            ),
            child: const Icon(
              Icons.mic,
              color: Colors.red,
              size: 24,
            ),
          ),
          const SizedBox(width: _DialogConstants.spacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Record Audio',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  project != null ?
                    'Add recording to ${project!.name}' :
                    'Record and transcribe meeting',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close),
            style: IconButton.styleFrom(
              backgroundColor: colorScheme.surfaceContainerHighest.withValues(
                alpha: _DialogConstants.highOpacity,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Extracted Project Selection Section with Segmented Control
class _ProjectSelectionSection extends ConsumerWidget {
  final ProjectSelectionMode projectMode;
  final String? selectedProjectId;
  final Function(ProjectSelectionMode) onModeChanged;
  final Function(String?) onProjectSelected;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const _ProjectSelectionSection({
    required this.projectMode,
    required this.selectedProjectId,
    required this.onModeChanged,
    required this.onProjectSelected,
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(projectsListProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Project Selection',
              style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 8),
            if (projectMode == ProjectSelectionMode.automatic)
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
        const SizedBox(height: _DialogConstants.tinyPadding),
        // Segmented Control
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: _DialogConstants.lowOpacity),
            borderRadius: BorderRadius.circular(_DialogConstants.borderRadius),
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              Expanded(
                child: _SegmentedButton(
                  label: 'AI Auto-match',
                  icon: Icons.auto_awesome,
                  isSelected: projectMode == ProjectSelectionMode.automatic,
                  onTap: () => onModeChanged(ProjectSelectionMode.automatic),
                  colorScheme: colorScheme,
                  textTheme: textTheme,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _SegmentedButton(
                  label: 'Select Project',
                  icon: Icons.format_list_bulleted,
                  isSelected: projectMode == ProjectSelectionMode.manual,
                  onTap: () => onModeChanged(ProjectSelectionMode.manual),
                  colorScheme: colorScheme,
                  textTheme: textTheme,
                ),
              ),
            ],
          ),
        ),
        // Animated transition for dropdown
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: projectMode == ProjectSelectionMode.manual
              ? Column(
                  children: [
                    const SizedBox(height: _DialogConstants.spacing),
                    projectsAsync.when(
                    data: (projects) => _ProjectDropdown(
                      projects: projects,
                      selectedProjectId: selectedProjectId,
                      onChanged: onProjectSelected,
                      colorScheme: colorScheme,
                      textTheme: textTheme,
                    ),
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(_DialogConstants.smallSpacing),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    error: (error, _) => Padding(
                      padding: const EdgeInsets.all(_DialogConstants.smallSpacing),
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
}

// Segmented Button for Project Mode
class _SegmentedButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const _SegmentedButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
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
                ? colorScheme.primary.withValues(alpha: _DialogConstants.lowOpacity)
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
                  style: textTheme.bodyMedium?.copyWith(
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
}

// Project Dropdown Widget
class _ProjectDropdown extends StatelessWidget {
  final List<Project> projects;
  final String? selectedProjectId;
  final Function(String?) onChanged;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const _ProjectDropdown({
    required this.projects,
    required this.selectedProjectId,
    required this.onChanged,
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_DialogConstants.smallSpacing),
            borderSide: BorderSide(
              color: colorScheme.outline.withValues(alpha: _DialogConstants.highOpacity),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_DialogConstants.smallSpacing),
            borderSide: BorderSide(
              color: colorScheme.outline.withValues(alpha: _DialogConstants.highOpacity),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_DialogConstants.smallSpacing),
            borderSide: BorderSide(color: colorScheme.primary, width: 2),
          ),
          filled: true,
          fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: _DialogConstants.highOpacity),
        ),
      ),
      child: DropdownButtonFormField<String>(
        initialValue: selectedProjectId,
        decoration: InputDecoration(
          hintText: 'Choose a project',
          hintStyle: TextStyle(
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
          prefixIcon: Icon(
            Icons.folder_outlined,
            color: selectedProjectId != null ?
              colorScheme.primary :
              colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            size: 20,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: _DialogConstants.tinyPadding,
            vertical: 14,
          ),
        ),
        dropdownColor: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(_DialogConstants.borderRadius),
        elevation: 4,
        style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
        icon: Icon(
          Icons.keyboard_arrow_down_rounded,
          color: colorScheme.onSurfaceVariant,
        ),
        selectedItemBuilder: (BuildContext context) {
          return projects.map<Widget>((project) {
            return Container(
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: _DialogConstants.tinyPadding),
                  Text(
                    project.name,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }).toList();
        },
        items: projects.map((project) {
          return DropdownMenuItem<String>(
            value: project.id,
            child: _ProjectDropdownItem(
              project: project,
              colorScheme: colorScheme,
              textTheme: textTheme,
            ),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}

// Project Dropdown Item
class _ProjectDropdownItem extends StatelessWidget {
  final Project project;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const _ProjectDropdownItem({
    required this.project,
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: _DialogConstants.tinySpacing),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: _DialogConstants.highOpacity),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.work_outline,
              size: 16,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: _DialogConstants.tinyPadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  project.name,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                ),
                if (project.description != null && project.description!.isNotEmpty)
                  Text(
                    project.description!,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Title Field with consistent visual alignment
class _TitleField extends StatelessWidget {
  final TextEditingController controller;
  final ColorScheme colorScheme;

  const _TitleField({
    required this.controller,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Meeting Title (optional)',
          style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: _DialogConstants.tinyPadding),
        TextField(
          controller: controller,
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
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_DialogConstants.borderRadius),
              borderSide: BorderSide(
                color: colorScheme.outline.withValues(alpha: _DialogConstants.mediumOpacity),
                width: 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_DialogConstants.borderRadius),
              borderSide: BorderSide(
                color: colorScheme.outline.withValues(alpha: _DialogConstants.mediumOpacity),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_DialogConstants.borderRadius),
              borderSide: BorderSide(
                color: colorScheme.primary,
                width: 2,
              ),
            ),
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.05),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: _DialogConstants.smallPadding,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }
}

// Dialog Actions with consistent design
class _DialogActions extends StatelessWidget {
  final bool isRecording;
  final ColorScheme colorScheme;

  const _DialogActions({
    required this.isRecording,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(_DialogConstants.padding),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: _DialogConstants.lowOpacity),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(_DialogConstants.largeBorderRadius),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: isRecording ? null : () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}