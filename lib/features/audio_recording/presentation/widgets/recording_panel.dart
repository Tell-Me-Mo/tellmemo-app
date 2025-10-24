import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../projects/domain/entities/project.dart';
import '../../domain/services/audio_recording_service.dart';
import '../../../projects/presentation/providers/projects_provider.dart';
import '../../../meetings/presentation/providers/upload_provider.dart';
import '../providers/recording_provider.dart';
import 'recording_button.dart';
import '../../../content/presentation/providers/processing_jobs_provider.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/utils/screen_info.dart';
import '../../../live_insights/domain/models/live_insight_model.dart';
import '../../../live_insights/domain/models/proactive_assistance_model.dart';
import '../../../live_insights/presentation/widgets/live_insights_settings_dialog.dart';

enum ProjectSelectionMode { automatic, manual, specific }

/// Redesigned Recording Panel - Unified design with minimized recording controls
/// when live insights are active
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

class _RecordingPanelState extends ConsumerState<RecordingPanel>
    with TickerProviderStateMixin {
  final _titleController = TextEditingController();
  ProjectSelectionMode _projectMode = ProjectSelectionMode.automatic;
  String? _selectedProjectId;
  bool _enableLiveInsights = false;

  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  // Live insights state
  final List<LiveInsightModel> _liveInsights = [];
  final List<ProactiveAssistanceModel> _proactiveAssistance = [];
  StreamSubscription<InsightsExtractionResult>? _insightsSubscription;
  StreamSubscription<List<ProactiveAssistanceModel>>? _assistanceSubscription;

  @override
  void initState() {
    super.initState();

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
    _insightsSubscription?.cancel();
    _assistanceSubscription?.cancel();
    super.dispose();
  }

  void _handleClose() {
    final recordingState = ref.read(recordingNotifierProvider);
    if (recordingState.state == RecordingState.recording ||
        recordingState.state == RecordingState.paused) {
      _showCancelConfirmation();
    } else {
      _animationController.reverse().then((_) {
        widget.onClose();
      });
    }
  }

  Future<void> _showCancelConfirmation() async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // Prevent dismissing while cancelling
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

    if (confirm == true) {
      if (!mounted) return;

      try {
        // Cancel the recording
        await ref.read(recordingNotifierProvider.notifier).cancelRecording();

        // Wait a frame to ensure state has updated
        if (!mounted) return;
        await Future.delayed(const Duration(milliseconds: 50));

        if (!mounted) return;

        // Animate out and close
        await _animationController.reverse();

        if (mounted) {
          widget.onClose();
        }
      } catch (e) {
        debugPrint('[RecordingPanel] Error during cancellation: $e');
        // Still try to close even if cancellation fails
        if (mounted) {
          await _animationController.reverse();
          widget.onClose();
        }
      }
    }
  }

  void _setupInsightsListener() {
    final recordingNotifier = ref.read(recordingNotifierProvider.notifier);
    final wsService = recordingNotifier.liveInsightsService;

    if (wsService != null) {
      debugPrint('📊 [RecordingPanel] Setting up insights listener');

      // Insights listener
      _insightsSubscription = wsService.insightsStream.listen(
        (result) {
          if (mounted) {
            setState(() {
              _liveInsights.addAll(result.insights);
            });
          }
        },
        onError: (error) {
          debugPrint('❌ [RecordingPanel] Insights stream error: $error');
        },
      );

      // Proactive assistance listener
      _assistanceSubscription = wsService.proactiveAssistanceStream.listen(
        (assistance) {
          if (mounted) {
            setState(() {
              _proactiveAssistance.addAll(assistance);
            });
          }
        },
        onError: (error) {
          debugPrint('❌ [RecordingPanel] Assistance stream error: $error');
        },
      );
    }
  }

  /// Show Live Insights settings dialog
  void _showLiveInsightsSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const LiveInsightsSettingsDialog(),
    );
  }

  Future<void> _handleRecordingComplete(String? filePath) async {
    if (filePath == null) return;

    String projectId;
    bool useAiMatching = false;

    if (_projectMode == ProjectSelectionMode.specific && widget.project != null) {
      projectId = widget.project!.id;
    } else if (_projectMode == ProjectSelectionMode.manual &&
        _selectedProjectId != null) {
      projectId = _selectedProjectId!;
    } else if (_projectMode == ProjectSelectionMode.automatic) {
      projectId = "auto";
      useAiMatching = true;
    } else {
      if (mounted) {
        ref
            .read(notificationServiceProvider.notifier)
            .showWarning('Please select a project or choose automatic matching');
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

        final projectIdToUse =
            returnedProjectId ?? _selectedProjectId ?? widget.project?.id ?? '';

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
          _animationController.reverse().then((_) {
            widget.onClose();
            widget.onRecordingComplete?.call();
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ref
            .read(notificationServiceProvider.notifier)
            .showError('Failed to upload recording: $e');
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

    // Watch for recording state changes
    ref.listen(recordingNotifierProvider, (previous, next) {
      if (previous?.liveInsightsSessionId != next.liveInsightsSessionId &&
          next.liveInsightsSessionId != null &&
          _enableLiveInsights) {
        _setupInsightsListener();
      }
    });

    final isRecording = recordingState.state == RecordingState.recording ||
        recordingState.state == RecordingState.paused;
    final showInsights = _enableLiveInsights && isRecording;

    final panelWidth = screenInfo.isMobile
        ? MediaQuery.of(context).size.width
        : (showInsights ? 1400.0 : 550.0);

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
                        color: Colors.black
                            .withValues(alpha: 0.5 * _animationController.value),
                      ),
                    )
                  : const SizedBox.shrink();
            },
          ),

          // Unified Panel
          Positioned(
            right: widget.rightOffset,
            top: 0,
            bottom: screenInfo.isMobile ? keyboardHeight : 0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: panelWidth,
              child: SlideTransition(
                position: _slideAnimation,
                child: Container(
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
                      // Unified Header
                      _buildUnifiedHeader(theme, colorScheme, recordingState, isRecording),

                      // Main Content Area
                      Expanded(
                        child: showInsights
                            ? _buildInsightsContent(theme, colorScheme, recordingState)
                            : _buildRecordingSetup(theme, colorScheme, recordingState),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Unified header that adapts based on state
  Widget _buildUnifiedHeader(ThemeData theme, ColorScheme colorScheme,
      RecordingStateModel recordingState, bool isRecording) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 16,
        top: MediaQuery.of(context).padding.top + 16,
        bottom: 16,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Recording indicator
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isRecording
                      ? Colors.red.withValues(alpha: 0.15)
                      : colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.mic,
                  size: 20,
                  color: isRecording ? Colors.red : colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),

              // Title and status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Record Meeting',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (isRecording) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.red.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _formatDuration(recordingState.duration),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.red,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (!isRecording) ...[
                      const SizedBox(height: 2),
                      Text(
                        widget.project != null
                            ? widget.project!.name
                            : 'Configure recording settings',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // Live Insights badge (when active)
              if (_enableLiveInsights && isRecording) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lightbulb,
                        size: 14,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${_liveInsights.length + _proactiveAssistance.length}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Live Insights settings button
                IconButton(
                  icon: const Icon(Icons.settings_outlined, size: 18),
                  onPressed: () => _showLiveInsightsSettings(context),
                  tooltip: 'Live Insights Settings',
                  style: IconButton.styleFrom(
                    padding: const EdgeInsets.all(8),
                  ),
                ),
              ],

              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: _handleClose,
                tooltip: 'Close',
                style: IconButton.styleFrom(
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ],
          ),

          // Minimized recording controls when insights are showing
          if (isRecording && _enableLiveInsights)
            _buildMinimizedRecordingControls(theme, colorScheme, recordingState),
        ],
      ),
    );
  }

  // Minimized recording controls
  Widget _buildMinimizedRecordingControls(ThemeData theme,
      ColorScheme colorScheme, RecordingStateModel recordingState) {
    final isRecording = recordingState.state == RecordingState.recording;
    final isPaused = recordingState.state == RecordingState.paused;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          // Pause/Resume
          IconButton(
            onPressed: () {
              if (isRecording) {
                ref.read(recordingNotifierProvider.notifier).pauseRecording();
              } else if (isPaused) {
                ref.read(recordingNotifierProvider.notifier).resumeRecording();
              }
            },
            icon: Icon(
              isRecording ? Icons.pause : Icons.play_arrow,
              size: 18,
            ),
            style: IconButton.styleFrom(
              padding: const EdgeInsets.all(8),
              minimumSize: const Size(36, 36),
              backgroundColor: colorScheme.surface,
            ),
            tooltip: isRecording ? 'Pause' : 'Resume',
          ),
          const SizedBox(width: 8),

          // Stop
          IconButton(
            onPressed: () async {
              final confirm = await _showStopConfirmation();
              if (confirm == true && mounted) {
                final notifier = ref.read(recordingNotifierProvider.notifier);
                await notifier.stopRecording(
                  projectId: _projectMode == ProjectSelectionMode.automatic
                      ? 'auto'
                      : (_selectedProjectId ?? widget.project?.id ?? 'auto'),
                  meetingTitle: _titleController.text,
                );
              }
            },
            icon: const Icon(Icons.stop, size: 18),
            style: IconButton.styleFrom(
              padding: const EdgeInsets.all(8),
              minimumSize: const Size(36, 36),
              backgroundColor: colorScheme.surface,
            ),
            tooltip: 'Stop Recording',
          ),
          const SizedBox(width: 8),

          // Cancel
          IconButton(
            onPressed: () => _cancelRecording(context, ref),
            icon: const Icon(Icons.close, size: 18),
            style: IconButton.styleFrom(
              padding: const EdgeInsets.all(8),
              minimumSize: const Size(36, 36),
              backgroundColor: colorScheme.errorContainer.withValues(alpha: 0.3),
              foregroundColor: colorScheme.error,
            ),
            tooltip: 'Cancel Recording',
          ),

          const Spacer(),

          // Audio level indicator
          if (!isPaused)
            StreamBuilder<double>(
              stream: ref.read(audioRecordingServiceProvider).amplitudeStream,
              builder: (context, snapshot) {
                final amplitude = snapshot.data ?? -160.0;
                // record package returns dB values: -160 (silence) to 0 (max)
                // Web microphone typically gives -60 dB (silence) to -30 dB (loud speech)
                // Map -60 dB (silence) to 0.0, and -30 dB (very loud) to 1.0
                final normalizedLevel = ((amplitude + 60) / 30).clamp(0.0, 1.0);

                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(8, (index) {
                    // Create wave effect with varying heights per bar
                    final centerDistance = (index - 4).abs() / 4.0;
                    final centerFactor = 1.0 - (centerDistance * 0.4);

                    // Add slight variation to each bar for more natural look
                    final barVariation = 0.8 + (index.isEven ? 0.2 : 0.0);
                    final barHeight = (normalizedLevel * centerFactor * barVariation).clamp(0.15, 1.0);

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 100),
                      width: 2.5,
                      height: 20 * barHeight,
                      margin: const EdgeInsets.symmetric(horizontal: 1.5),
                      decoration: BoxDecoration(
                        color: _getBarColor(barHeight),
                        borderRadius: BorderRadius.circular(1.5),
                      ),
                    );
                  }),
                );
              },
            ),
          if (isPaused)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(8, (index) {
                return Container(
                  width: 2.5,
                  height: 3,
                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                );
              }),
            ),
        ],
      ),
    );
  }

  // Recording setup view (before recording)
  Widget _buildRecordingSetup(ThemeData theme, ColorScheme colorScheme,
      RecordingStateModel recordingState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Project Selection
          if (widget.project == null) ...[
            _buildProjectSelection(theme, colorScheme),
            const SizedBox(height: 20),
          ],

          // Title Field
          _buildTitleField(theme, colorScheme),
          const SizedBox(height: 16),

          // Live Insights Toggle
          _buildLiveInsightsToggle(theme, colorScheme),
          const SizedBox(height: 20),

          // Recording Button
          _buildRecordingButton(theme, colorScheme, recordingState),
        ],
      ),
    );
  }

  // Insights content view (during recording with insights enabled)
  Widget _buildInsightsContent(ThemeData theme, ColorScheme colorScheme,
      RecordingStateModel recordingState) {
    final hasInsights = _liveInsights.isNotEmpty;
    final hasAssistance = _proactiveAssistance.isNotEmpty;

    return Column(
      children: [
        // Content - Side by side for desktop when insights are enabled
        Expanded(
          child: hasInsights || hasAssistance
              ? Row(
                  children: [
                    // Insights column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Insights header
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: colorScheme.outlineVariant
                                      .withValues(alpha: 0.2),
                                ),
                              ),
                            ),
                            child: Text(
                              'Insights',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                          // Insights list
                          Expanded(
                            child: _buildInsightsList(theme, colorScheme),
                          ),
                        ],
                      ),
                    ),
                    // Divider
                    VerticalDivider(
                      width: 1,
                      thickness: 1,
                      color: colorScheme.outlineVariant.withValues(alpha: 0.2),
                    ),
                    // Assistance column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Assistance header
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: colorScheme.outlineVariant
                                      .withValues(alpha: 0.2),
                                ),
                              ),
                            ),
                            child: Text(
                              'Assistance',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                          // Assistance list
                          Expanded(
                            child: _buildAssistanceList(theme, colorScheme),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : _buildEmptyInsightsState(theme, colorScheme),
        ),
      ],
    );
  }

  Widget _buildInsightsList(ThemeData theme, ColorScheme colorScheme) {
    if (_liveInsights.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lightbulb_outline,
              size: 48,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No insights yet',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Insights will appear here as the meeting progresses',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _liveInsights.length,
      itemBuilder: (context, index) {
        final insight = _liveInsights[index];
        return _buildInsightCard(insight, theme, colorScheme);
      },
    );
  }

  Widget _buildInsightCard(LiveInsightModel insight, ThemeData theme,
      ColorScheme colorScheme) {
    final typeColor = _getInsightTypeColor(insight.type);
    final priorityColor = _getInsightPriorityColor(insight.priority);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: typeColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _getInsightTypeLabel(insight.type),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: typeColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: priorityColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  insight.priority.toString().split('.').last.toUpperCase(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: priorityColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                _formatTime(insight.timestamp ?? DateTime.now()),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            insight.content ?? '',
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.4,
            ),
          ),
          if (insight.context.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              insight.context,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAssistanceList(ThemeData theme, ColorScheme colorScheme) {
    if (_proactiveAssistance.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_awesome,
              size: 48,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No assistance suggestions yet',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _proactiveAssistance.length,
      itemBuilder: (context, index) {
        final assistance = _proactiveAssistance[index];
        return _buildAssistanceCard(assistance, theme, colorScheme);
      },
    );
  }

  Widget _buildAssistanceCard(ProactiveAssistanceModel assistance,
      ThemeData theme, ColorScheme colorScheme) {
    String title;
    String content;
    IconData icon;

    switch (assistance.type) {
      case ProactiveAssistanceType.autoAnswer:
        title = 'Auto-Answer';
        content = assistance.autoAnswer?.question ?? 'Question answered';
        icon = Icons.quiz;
        break;
      case ProactiveAssistanceType.clarificationNeeded:
        title = 'Clarification Needed';
        content = assistance.clarification?.statement ?? 'Needs clarification';
        icon = Icons.help_outline;
        break;
      case ProactiveAssistanceType.conflictDetected:
        title = 'Conflict Detected';
        content = assistance.conflict?.currentStatement ?? 'Conflict found';
        icon = Icons.warning_amber;
        break;
      case ProactiveAssistanceType.incompleteActionItem:
        title = 'Incomplete Action Item';
        content = assistance.actionItemQuality?.actionItem ?? 'Action item needs improvement';
        icon = Icons.assignment_late;
        break;
      case ProactiveAssistanceType.followUpSuggestion:
        title = 'Follow-Up Suggestion';
        content = assistance.followUpSuggestion?.topic ?? 'Follow-up recommended';
        icon = Icons.lightbulb_outline;
        break;
      case ProactiveAssistanceType.repetitionDetected:
        title = 'Repetition Detected';
        content = assistance.repetitionDetection?.topic ?? 'Topic repeated';
        icon = Icons.repeat;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyInsightsState(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lightbulb_outline,
                size: 48,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Live Insights Active',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'AI is listening and will extract insights as the meeting progresses',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildInsightTypeChip('Action Items', Icons.assignment, Colors.blue, theme),
                const SizedBox(width: 8),
                _buildInsightTypeChip('Decisions', Icons.check_circle, Colors.green, theme),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildInsightTypeChip('Risks', Icons.warning, Colors.red, theme),
                const SizedBox(width: 8),
                _buildInsightTypeChip('Questions', Icons.help_outline, Colors.orange, theme),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightTypeChip(String label, IconData icon, Color color, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  Color _getInsightTypeColor(LiveInsightType type) {
    switch (type) {
      case LiveInsightType.actionItem:
        return Colors.blue;
      case LiveInsightType.decision:
        return Colors.green;
      case LiveInsightType.question:
        return Colors.orange;
      case LiveInsightType.risk:
        return Colors.red;
      case LiveInsightType.keyPoint:
        return Colors.purple;
      case LiveInsightType.relatedDiscussion:
        return Colors.teal;
      case LiveInsightType.contradiction:
        return Colors.deepOrange;
      case LiveInsightType.missingInfo:
        return Colors.amber;
    }
  }

  Color _getInsightPriorityColor(LiveInsightPriority priority) {
    switch (priority) {
      case LiveInsightPriority.critical:
        return Colors.red;
      case LiveInsightPriority.high:
        return Colors.orange;
      case LiveInsightPriority.medium:
        return Colors.blue;
      case LiveInsightPriority.low:
        return Colors.grey;
    }
  }

  String _getInsightTypeLabel(LiveInsightType type) {
    switch (type) {
      case LiveInsightType.actionItem:
        return 'ACTION ITEM';
      case LiveInsightType.decision:
        return 'DECISION';
      case LiveInsightType.question:
        return 'QUESTION';
      case LiveInsightType.risk:
        return 'RISK';
      case LiveInsightType.keyPoint:
        return 'KEY POINT';
      case LiveInsightType.relatedDiscussion:
        return 'RELATED';
      case LiveInsightType.contradiction:
        return 'CONTRADICTION';
      case LiveInsightType.missingInfo:
        return 'MISSING INFO';
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Color _getBarColor(double level) {
    // Color based on audio level intensity
    if (level < 0.3) {
      return Colors.green.withValues(alpha: 0.7);
    } else if (level < 0.5) {
      return Color.lerp(Colors.green, Colors.yellow, (level - 0.3) * 5)!;
    } else if (level < 0.7) {
      return Color.lerp(Colors.yellow, Colors.orange, (level - 0.5) * 5)!;
    } else if (level < 0.9) {
      return Color.lerp(Colors.orange, Colors.red, (level - 0.7) * 5)!;
    } else {
      return Colors.red.withValues(alpha: 0.9);
    }
  }

  Future<void> _cancelRecording(BuildContext context, WidgetRef ref) async {
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
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Cancel Recording'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await ref.read(recordingNotifierProvider.notifier).cancelRecording();
      if (mounted) {
        ref.read(notificationServiceProvider.notifier).showInfo('Recording cancelled');
      }
    }
  }

  Future<bool?> _showStopConfirmation() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stop Recording?'),
        content: const Text(
          'Your recording will be saved and automatically transcribed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continue'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Stop & Save'),
          ),
        ],
      ),
    );
  }

  // Reuse existing methods from original implementation
  Widget _buildProjectSelection(ThemeData theme, ColorScheme colorScheme) {
    final projectsAsync = ref.watch(projectsListProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Project Selection',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
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
                  colorScheme: colorScheme,
                  theme: theme,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _buildSegmentedButton(
                  label: 'Select',
                  icon: Icons.folder_outlined,
                  isSelected: _projectMode == ProjectSelectionMode.manual,
                  onTap: () => setState(() {
                    _projectMode = ProjectSelectionMode.manual;
                  }),
                  colorScheme: colorScheme,
                  theme: theme,
                ),
              ),
            ],
          ),
        ),
        if (_projectMode == ProjectSelectionMode.manual) ...[
          const SizedBox(height: 12),
          projectsAsync.when(
            data: (projects) => _buildProjectDropdown(projects, theme, colorScheme),
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (error, _) => Text(
              'Error loading projects',
              style: TextStyle(color: colorScheme.error),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSegmentedButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
    required ThemeData theme,
  }) {
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
                ? colorScheme.primary.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
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
                  style: theme.textTheme.bodySmall?.copyWith(
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

  Widget _buildProjectDropdown(
      List<Project> projects, ThemeData theme, ColorScheme colorScheme) {
    return DropdownButtonFormField<String>(
      initialValue: _selectedProjectId,
      decoration: InputDecoration(
        hintText: 'Choose a project',
        prefixIcon: const Icon(Icons.folder_outlined, size: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      items: projects.map((project) {
        return DropdownMenuItem<String>(
          value: project.id,
          child: Text(
            project.name,
            style: theme.textTheme.bodyMedium,
          ),
        );
      }).toList(),
      onChanged: (value) => setState(() {
        _selectedProjectId = value;
      }),
    );
  }

  Widget _buildTitleField(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Meeting Title (optional)',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _titleController,
          decoration: InputDecoration(
            hintText: 'Enter a title for this recording',
            prefixIcon: const Icon(Icons.title, size: 18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildLiveInsightsToggle(ThemeData theme, ColorScheme colorScheme) {
    return Material(
      color: _enableLiveInsights
          ? colorScheme.primaryContainer.withValues(alpha: 0.3)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => setState(() {
          _enableLiveInsights = !_enableLiveInsights;
        }),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _enableLiveInsights
                  ? colorScheme.primary.withValues(alpha: 0.3)
                  : colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.lightbulb,
                  size: 20,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enable Live Insights',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Get real-time action items, decisions, and risks',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _enableLiveInsights,
                onChanged: (value) => setState(() {
                  _enableLiveInsights = value;
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecordingButton(
      ThemeData theme, ColorScheme colorScheme, RecordingStateModel recordingState) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border.all(
          color: recordingState.state == RecordingState.recording
              ? Colors.red.withValues(alpha: 0.3)
              : colorScheme.outline.withValues(alpha: 0.2),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(16),
        color: recordingState.state == RecordingState.recording
            ? Colors.red.withValues(alpha: 0.05)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
      ),
      child: Center(
        child: FutureBuilder<String?>(
          future: ref.read(authServiceProvider).getToken(),
          builder: (context, snapshot) {
            final authToken = snapshot.data;
            return RecordingButton(
              onRecordingComplete: _handleRecordingComplete,
              projectId: _projectMode == ProjectSelectionMode.automatic
                  ? 'auto'
                  : (_selectedProjectId ?? widget.project?.id ?? 'auto'),
              meetingTitle: _titleController.text,
              enableLiveInsights: _enableLiveInsights,
              authToken: authToken,
            );
          },
        ),
      ),
    );
  }
}
