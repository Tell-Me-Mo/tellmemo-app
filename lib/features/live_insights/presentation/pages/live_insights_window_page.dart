import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/proactive_assistance_model.dart';
import '../../domain/models/live_insight_model.dart';
import '../widgets/proactive_assistance_card.dart';
import '../../../audio_recording/presentation/providers/recording_provider.dart';
import '../../../meetings/presentation/widgets/live_insights_panel.dart';

/// Live Insights Window Page
///
/// Displays in a separate window/tab for multi-monitor setups.
/// Includes feature toggles for enabling/disabling each AI assistance feature.
class LiveInsightsWindowPage extends ConsumerStatefulWidget {
  final String sessionId;

  const LiveInsightsWindowPage({
    super.key,
    required this.sessionId,
  });

  @override
  ConsumerState<LiveInsightsWindowPage> createState() =>
      _LiveInsightsWindowPageState();
}

class _LiveInsightsWindowPageState
    extends ConsumerState<LiveInsightsWindowPage> {
  // Proactive assistance state
  List<ProactiveAssistanceModel> _proactiveAssistance = [];
  StreamSubscription<List<ProactiveAssistanceModel>>? _assistanceSubscription;

  // Feature toggles (persisted to localStorage via provider)
  final Map<ProactiveAssistanceType, bool> _featureToggles = {
    ProactiveAssistanceType.autoAnswer: true, // Phase 1
    ProactiveAssistanceType.clarificationNeeded: true, // Phase 2
    ProactiveAssistanceType.conflictDetected: true, // Phase 3
    ProactiveAssistanceType.incompleteActionItem: true, // Phase 4
    ProactiveAssistanceType.followUpSuggestion: true, // Phase 5
    ProactiveAssistanceType.repetitionDetected: true, // Phase 6
  };

  bool _showSettings = false;
  InsightsExtractionResult? _latestInsights;

  @override
  void initState() {
    super.initState();
    _setupProactiveAssistanceListener();
    _loadFeatureToggles();
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
              // Filter based on feature toggles
              final filteredAssistance = assistance.where((item) {
                return _featureToggles[item.type] ?? false;
              }).toList();
              _proactiveAssistance.addAll(filteredAssistance);
            });
          }
        },
      );

      // Also listen to insights stream
      wsService.insightsStream.listen((insights) {
        if (mounted) {
          setState(() {
            _latestInsights = insights;
          });
        }
      });
    }
  }

  void _loadFeatureToggles() {
    // TODO: Load from localStorage/SharedPreferences
    // For now, all features enabled by default
  }

  void _saveFeatureToggles() {
    // TODO: Save to localStorage/SharedPreferences
  }

  void _toggleFeature(ProactiveAssistanceType type, bool enabled) {
    setState(() {
      _featureToggles[type] = enabled;
    });
    _saveFeatureToggles();
  }

  List<ProactiveAssistanceModel> _getFilteredAssistance() {
    return _proactiveAssistance.where((item) {
      return _featureToggles[item.type] ?? false;
    }).toList();
  }

  String _mapInsightTypeToString(LiveInsightType type) {
    switch (type) {
      case LiveInsightType.actionItem:
        return 'action_item';
      case LiveInsightType.decision:
        return 'decision';
      case LiveInsightType.question:
        return 'question';
      case LiveInsightType.risk:
        return 'risk';
      case LiveInsightType.keyPoint:
        return 'key_point';
      case LiveInsightType.relatedDiscussion:
        return 'related_discussion';
      case LiveInsightType.contradiction:
        return 'contradiction';
      case LiveInsightType.missingInfo:
        return 'missing_info';
    }
  }

  String _mapInsightPriorityToString(LiveInsightPriority priority) {
    switch (priority) {
      case LiveInsightPriority.critical:
        return 'critical';
      case LiveInsightPriority.high:
        return 'high';
      case LiveInsightPriority.medium:
        return 'medium';
      case LiveInsightPriority.low:
        return 'low';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredAssistance = _getFilteredAssistance();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.auto_awesome, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Live Insights - AI Assistant'),
          ],
        ),
        actions: [
          // Feature toggles button
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Configure AI Features',
            onPressed: () {
              setState(() {
                _showSettings = !_showSettings;
              });
            },
          ),
          // Close window button
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Close Window',
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: Row(
        children: [
          // Main content
          Expanded(
            child: Column(
              children: [
                // AI Assistant Section
                if (filteredAssistance.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.05),
                      border: Border(
                        bottom: BorderSide(color: theme.dividerColor),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.auto_awesome,
                                color: Colors.blue[700], size: 24),
                            const SizedBox(width: 12),
                            Text(
                              'AI Proactive Assistance',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[900],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                '${filteredAssistance.length}',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: Colors.blue[900],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 280,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: filteredAssistance.length,
                            itemBuilder: (context, index) {
                              return Container(
                                width: 400,
                                margin: const EdgeInsets.only(right: 16),
                                child: ProactiveAssistanceCard(
                                  assistance: filteredAssistance[index],
                                  onAccept: () => _handleAcceptAssistance(index),
                                  onDismiss: () =>
                                      _handleDismissAssistance(index),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Regular Insights Panel
                Expanded(
                  child: LiveInsightsPanel(
                    insights: _latestInsights?.insights.map((insight) {
                      return MeetingInsight(
                        insightId: insight.insightId ?? insight.id ?? '',
                        type: InsightType.fromString(_mapInsightTypeToString(insight.type)),
                        priority: InsightPriority.fromString(_mapInsightPriorityToString(insight.priority)),
                        content: insight.content,
                        context: insight.context,
                        timestamp: insight.timestamp ?? insight.createdAt ?? DateTime.now(),
                        assignedTo: insight.assignedTo,
                        dueDate: insight.dueDate,
                        confidenceScore: insight.confidenceScore,
                      );
                    }).toList() ?? [],
                    isRecording: true,
                    onClose: null,
                  ),
                ),
              ],
            ),
          ),

          // Settings Panel (slide in from right)
          if (_showSettings)
            Container(
              width: 350,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  left: BorderSide(color: theme.dividerColor, width: 2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(-2, 0),
                  ),
                ],
              ),
              child: _buildSettingsPanel(theme),
            ),
        ],
      ),
    );
  }

  Widget _buildSettingsPanel(ThemeData theme) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withOpacity(0.3),
            border: Border(bottom: BorderSide(color: theme.dividerColor)),
          ),
          child: Row(
            children: [
              Icon(Icons.tune, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Text(
                'AI Features',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () {
                  setState(() {
                    _showSettings = false;
                  });
                },
              ),
            ],
          ),
        ),

        // Feature toggles
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Enable or disable AI assistance features:',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 16),

              _buildFeatureToggle(
                type: ProactiveAssistanceType.autoAnswer,
                title: '💡 Question Auto-Answering',
                description:
                    'Automatically answers questions using past meeting content',
                icon: Icons.auto_awesome,
                color: Colors.blue,
                phase: 'Phase 1',
              ),

              _buildFeatureToggle(
                type: ProactiveAssistanceType.clarificationNeeded,
                title: '❓ Proactive Clarification',
                description:
                    'Detects vague statements and suggests clarifying questions',
                icon: Icons.help_outline,
                color: Colors.orange,
                phase: 'Phase 2',
              ),

              _buildFeatureToggle(
                type: ProactiveAssistanceType.conflictDetected,
                title: '⚠️ Conflict Detection',
                description:
                    'Alerts when current decisions conflict with past decisions',
                icon: Icons.warning_amber,
                color: Colors.red,
                phase: 'Phase 3',
              ),

              _buildFeatureToggle(
                type: ProactiveAssistanceType.incompleteActionItem,
                title: '📝 Action Item Quality',
                description:
                    'Ensures action items have owners, deadlines, and clear descriptions',
                icon: Icons.error_outline,
                color: Colors.amber,
                phase: 'Phase 4',
              ),

              _buildFeatureToggle(
                type: ProactiveAssistanceType.followUpSuggestion,
                title: '💭 Follow-up Suggestions',
                description:
                    'Recommends related topics and open items from past meetings',
                icon: Icons.tips_and_updates,
                color: Colors.purple,
                phase: 'Phase 5',
              ),

              _buildFeatureToggle(
                type: ProactiveAssistanceType.repetitionDetected,
                title: '🔁 Repetition Detection & Time Alerts',
                description:
                    'Detects circular discussions and tracks meeting duration',
                icon: Icons.loop,
                color: Colors.deepOrange,
                phase: 'Phase 6',
              ),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),

              // Quick actions
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    for (final key in _featureToggles.keys) {
                      _featureToggles[key] = true;
                    }
                  });
                  _saveFeatureToggles();
                },
                icon: const Icon(Icons.check_circle),
                label: const Text('Enable All Features'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    for (final key in _featureToggles.keys) {
                      _featureToggles[key] = false;
                    }
                  });
                  _saveFeatureToggles();
                },
                icon: const Icon(Icons.cancel),
                label: const Text('Disable All Features'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureToggle({
    required ProactiveAssistanceType type,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required String phase,
  }) {
    final isEnabled = _featureToggles[type] ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isEnabled ? 2 : 0,
      color: isEnabled ? color.withOpacity(0.05) : Colors.grey.withOpacity(0.05),
      child: SwitchListTile(
        value: isEnabled,
        onChanged: (value) => _toggleFeature(type, value),
        title: Row(
          children: [
            Icon(icon, color: isEnabled ? color : Colors.grey, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isEnabled ? Colors.black : Colors.grey,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: isEnabled ? Colors.black87 : Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                phase,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleAcceptAssistance(int index) {
    // Track positive feedback
    debugPrint('User accepted assistance: ${_proactiveAssistance[index].type}');
    setState(() {
      _proactiveAssistance.removeAt(index);
    });
  }

  void _handleDismissAssistance(int index) {
    // Track dismissal
    debugPrint('User dismissed assistance: ${_proactiveAssistance[index].type}');
    setState(() {
      _proactiveAssistance.removeAt(index);
    });
  }
}
