import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../live_insights/domain/models/proactive_assistance_model.dart';
import '../../../live_insights/presentation/widgets/timeline_proactive_card.dart';
import '../../../live_insights/presentation/widgets/timeline_insight_badge.dart';
import '../../../live_insights/presentation/providers/live_insights_settings_provider.dart';
import '../../../audio_recording/presentation/providers/recording_provider.dart';
import '../../../live_insights/domain/models/live_insight_model.dart';

/// Timeline-based Live Insights Panel
///
/// Redesigned panel with proactive assistance as primary hero cards
/// and insights as compact secondary badges within a unified timeline.
class LiveInsightsTimelinePanel extends ConsumerStatefulWidget {
  final List<LiveInsightModel> insights;
  final bool isRecording;
  final VoidCallback? onClose;
  final double? width;

  const LiveInsightsTimelinePanel({
    super.key,
    required this.insights,
    this.isRecording = false,
    this.onClose,
    this.width,
  });

  @override
  ConsumerState<LiveInsightsTimelinePanel> createState() =>
      _LiveInsightsTimelinePanelState();
}

class _LiveInsightsTimelinePanelState
    extends ConsumerState<LiveInsightsTimelinePanel> {
  // Proactive assistance state with timestamps
  List<ProactiveAssistanceModel> _proactiveAssistance = [];
  final Map<ProactiveAssistanceModel, DateTime> _assistanceTimestamps = {};
  StreamSubscription<List<ProactiveAssistanceModel>>? _assistanceSubscription;

  @override
  void initState() {
    super.initState();
    _setupProactiveAssistanceListener();
  }

  @override
  void dispose() {
    _assistanceSubscription?.cancel();
    super.dispose();
  }

  void _setupProactiveAssistanceListener() {
    final recordingNotifier = ref.read(recordingNotifierProvider.notifier);
    final wsService = recordingNotifier.liveInsightsService;

    if (wsService != null) {
      _assistanceSubscription = wsService.proactiveAssistanceStream.listen(
        (assistance) {
          if (mounted) {
            setState(() {
              final settings = ref.read(liveInsightsSettingsSyncProvider);
              final visibleAssistance = assistance
                  .where((item) => settings.shouldShowAssistance(item))
                  .toList();

              final now = DateTime.now();
              for (final item in visibleAssistance) {
                _assistanceTimestamps[item] = now;
              }

              _proactiveAssistance.addAll(visibleAssistance);
            });
          }
        },
      );
    }
  }

  void _handleDismissAssistance(int index) {
    setState(() {
      final item = _proactiveAssistance[index];
      _proactiveAssistance.removeAt(index);
      _assistanceTimestamps.remove(item);
    });
  }

  void _handleFeedback(ProactiveAssistanceModel assistance, bool isHelpful) {
    final recordingNotifier = ref.read(recordingNotifierProvider.notifier);
    final wsService = recordingNotifier.liveInsightsService;

    if (wsService == null) return;

    String? insightId;
    String assistanceType = assistance.type.name;
    double? confidenceScore;

    switch (assistance.type) {
      case ProactiveAssistanceType.autoAnswer:
        insightId = assistance.autoAnswer?.insightId;
        confidenceScore = assistance.autoAnswer?.confidence;
        break;
      case ProactiveAssistanceType.clarificationNeeded:
        insightId = assistance.clarification?.insightId;
        confidenceScore = assistance.clarification?.confidence;
        break;
      case ProactiveAssistanceType.conflictDetected:
        insightId = assistance.conflict?.insightId;
        confidenceScore = assistance.conflict?.confidence;
        break;
      case ProactiveAssistanceType.incompleteActionItem:
        insightId = assistance.actionItemQuality?.insightId;
        confidenceScore = null;
        break;
      case ProactiveAssistanceType.followUpSuggestion:
        insightId = assistance.followUpSuggestion?.insightId;
        confidenceScore = assistance.followUpSuggestion?.confidence;
        break;
    }

    if (insightId != null) {
      wsService.sendFeedback(
        insightId: insightId,
        isHelpful: isHelpful,
        assistanceType: assistanceType,
        confidenceScore: confidenceScore,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: widget.width ?? double.infinity,
      child: _proactiveAssistance.isEmpty && widget.insights.isEmpty
          ? _buildEmptyState(theme)
          : Align(
              alignment: Alignment.topCenter,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Proactive Assistance Timeline Section
                    if (_proactiveAssistance.isNotEmpty) ...[
                      _buildSectionHeader(theme, 'AI Assistance', _proactiveAssistance.length),
                      _buildProactiveTimeline(theme),
                    ],

                    // Insights Section (Separate)
                    if (widget.insights.isNotEmpty) ...[
                      _buildSectionHeader(theme, 'Insights', widget.insights.length),
                      _buildInsightsSection(theme),
                    ],
                  ],
                ),
              ),
            ),
    );
  }


  Widget _buildSectionHeader(ThemeData theme, String title, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Row(
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProactiveTimeline(ThemeData theme) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: _proactiveAssistance.length,
      itemBuilder: (context, index) {
        final assistance = _proactiveAssistance[index];
        final isLast = index == _proactiveAssistance.length - 1;

        return _buildProactiveTimelineItem(theme, assistance, isLast, index);
      },
    );
  }

  Widget _buildProactiveTimelineItem(
    ThemeData theme,
    ProactiveAssistanceModel assistance,
    bool isLast,
    int index,
  ) {
    final timestamp = _assistanceTimestamps[assistance];
    final timeString = timestamp != null ? _formatTime(timestamp) : '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator with timestamp
          Column(
            children: [
              // Timestamp above dot
              if (timeString.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    timeString,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              // Timeline dot
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.surface,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              // Connecting line
              if (!isLast)
                Container(
                  width: 2,
                  height: 40,
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                  margin: const EdgeInsets.symmetric(vertical: 3),
                ),
            ],
          ),
          const SizedBox(width: 12),

          // Proactive card (full-width, hero treatment)
          Expanded(
            child: TimelineProactiveCard(
              assistance: assistance,
              onDismiss: () => _handleDismissAssistance(index),
              onFeedback: (isHelpful) => _handleFeedback(assistance, isHelpful),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inSeconds < 60) {
      return 'now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m';
    } else {
      return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    }
  }

  Widget _buildInsightsSection(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: widget.insights.map((insight) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TimelineInsightBadge(insight: insight),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated microphone icon
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: 0.8 + (value * 0.2),
                  child: Opacity(
                    opacity: value,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            theme.colorScheme.primary.withValues(alpha: 0.15),
                            theme.colorScheme.secondary.withValues(alpha: 0.1),
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withValues(alpha: 0.1),
                            blurRadius: 24,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Icon(
                        widget.isRecording ? Icons.mic_rounded : Icons.mic_none_rounded,
                        size: 48,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),

            // Title with gradient
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.secondary,
                ],
              ).createShader(bounds),
              child: Text(
                widget.isRecording
                    ? 'Listening for insights...'
                    : 'Ready for Live Insights',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.5,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),

            // Description
            Text(
              widget.isRecording
                  ? 'AI is analyzing your conversation in real-time'
                  : 'Start recording to get AI-powered assistance',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            // Feature cards
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildFeatureCard(
                  theme,
                  icon: Icons.auto_awesome,
                  label: 'Auto-Answers',
                  color: Colors.blue,
                ),
                _buildFeatureCard(
                  theme,
                  icon: Icons.help_outline,
                  label: 'Clarifications',
                  color: Colors.orange,
                ),
                _buildFeatureCard(
                  theme,
                  icon: Icons.warning_amber_rounded,
                  label: 'Conflict Detection',
                  color: Colors.red,
                ),
                _buildFeatureCard(
                  theme,
                  icon: Icons.gavel,
                  label: 'Decisions',
                  color: Colors.green,
                ),
                _buildFeatureCard(
                  theme,
                  icon: Icons.flag_outlined,
                  label: 'Risks',
                  color: Colors.deepOrange,
                ),
                _buildFeatureCard(
                  theme,
                  icon: Icons.tips_and_updates_outlined,
                  label: 'Follow-ups',
                  color: Colors.purple,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: color.withValues(alpha: 0.9),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
