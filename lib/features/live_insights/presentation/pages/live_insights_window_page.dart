import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/proactive_assistance_model.dart';
import '../widgets/proactive_assistance_card.dart';
import '../../../audio_recording/presentation/providers/recording_provider.dart';

/// Live Insights Window Page
///
/// Clean, responsive separate window for AI meeting assistance.
/// Displays AI suggestion cards in a responsive grid layout.
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

  // Feature toggles
  final Map<ProactiveAssistanceType, bool> _featureToggles = {
    ProactiveAssistanceType.autoAnswer: true,
    ProactiveAssistanceType.clarificationNeeded: true,
    ProactiveAssistanceType.conflictDetected: true,
    ProactiveAssistanceType.incompleteActionItem: true,
    ProactiveAssistanceType.followUpSuggestion: true,
    ProactiveAssistanceType.repetitionDetected: true,
  };

  bool _showSettings = false;

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
              final filteredAssistance = assistance.where((item) {
                return _featureToggles[item.type] ?? false;
              }).toList();
              _proactiveAssistance.addAll(filteredAssistance);
            });
          }
        },
      );
    }
  }

  void _loadFeatureToggles() {
    // TODO: Load from localStorage/SharedPreferences
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredAssistance = _getFilteredAssistance();
    final screenWidth = MediaQuery.of(context).size.width;

    // Responsive card width
    final cardWidth = screenWidth > 1400
        ? 420.0
        : screenWidth > 1000
            ? 380.0
            : screenWidth > 600
                ? 340.0
                : screenWidth * 0.9;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Icon(Icons.auto_awesome,
                color: theme.colorScheme.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              'AI Meeting Assistant',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showSettings ? Icons.close : Icons.tune,
              size: 20,
            ),
            tooltip: _showSettings ? 'Close Settings' : 'Settings',
            onPressed: () {
              setState(() {
                _showSettings = !_showSettings;
              });
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          // Main content area
          Expanded(
            child: filteredAssistance.isEmpty
                ? _buildEmptyState(theme)
                : _buildAssistanceCards(theme, filteredAssistance, cardWidth),
          ),

          // Settings sidebar
          if (_showSettings)
            Container(
              width: 320,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                border: Border(
                  left: BorderSide(
                    color: theme.dividerColor.withValues(alpha: 0.1),
                  ),
                ),
              ),
              child: _buildSettingsPanel(theme),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.psychology_outlined,
            size: 64,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Listening for insights...',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'AI suggestions will appear here as the meeting progresses',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssistanceCards(
    ThemeData theme,
    List<ProactiveAssistanceModel> assistance,
    double cardWidth,
  ) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(24),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: cardWidth,
              mainAxisExtent: 280,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return ProactiveAssistanceCard(
                  assistance: assistance[index],
                  onAccept: () => _handleAcceptAssistance(index),
                  onDismiss: () => _handleDismissAssistance(index),
                );
              },
              childCount: assistance.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsPanel(ThemeData theme) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: theme.dividerColor.withValues(alpha: 0.1),
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.tune, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Text(
                'AI Features',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
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
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 16),

              _buildFeatureToggle(
                type: ProactiveAssistanceType.autoAnswer,
                title: 'Question Auto-Answering',
                description:
                    'Automatically answers questions using past meeting content',
                icon: Icons.lightbulb_outline,
                color: Colors.blue,
              ),

              _buildFeatureToggle(
                type: ProactiveAssistanceType.clarificationNeeded,
                title: 'Proactive Clarification',
                description:
                    'Detects vague statements and suggests clarifying questions',
                icon: Icons.help_outline,
                color: Colors.orange,
              ),

              _buildFeatureToggle(
                type: ProactiveAssistanceType.conflictDetected,
                title: 'Conflict Detection',
                description:
                    'Alerts when current decisions conflict with past decisions',
                icon: Icons.warning_amber_outlined,
                color: Colors.red,
              ),

              _buildFeatureToggle(
                type: ProactiveAssistanceType.incompleteActionItem,
                title: 'Action Item Quality',
                description:
                    'Ensures action items have owners, deadlines, and clear descriptions',
                icon: Icons.task_outlined,
                color: Colors.amber,
              ),

              _buildFeatureToggle(
                type: ProactiveAssistanceType.followUpSuggestion,
                title: 'Follow-up Suggestions',
                description:
                    'Recommends related topics and open items from past meetings',
                icon: Icons.tips_and_updates_outlined,
                color: Colors.purple,
              ),

              _buildFeatureToggle(
                type: ProactiveAssistanceType.repetitionDetected,
                title: 'Repetition & Time Alerts',
                description:
                    'Detects circular discussions and tracks meeting duration',
                icon: Icons.loop,
                color: Colors.deepOrange,
              ),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),

              // Quick actions
              FilledButton.icon(
                onPressed: () {
                  setState(() {
                    for (final key in _featureToggles.keys) {
                      _featureToggles[key] = true;
                    }
                  });
                  _saveFeatureToggles();
                },
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text('Enable All'),
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
                icon: const Icon(Icons.cancel_outlined, size: 18),
                label: const Text('Disable All'),
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
  }) {
    final isEnabled = _featureToggles[type] ?? false;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isEnabled
            ? color.withValues(alpha: 0.08)
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _toggleFeature(type, !isEnabled),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isEnabled ? color : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: isEnabled
                              ? theme.colorScheme.onSurface
                              : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isEnabled
                              ? theme.colorScheme.onSurface.withValues(alpha: 0.7)
                              : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Switch(
                  value: isEnabled,
                  onChanged: (value) => _toggleFeature(type, value),
                  activeTrackColor: color,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleAcceptAssistance(int index) {
    debugPrint('User accepted assistance: ${_proactiveAssistance[index].type}');
    setState(() {
      _proactiveAssistance.removeAt(index);
    });
  }

  void _handleDismissAssistance(int index) {
    debugPrint('User dismissed assistance: ${_proactiveAssistance[index].type}');
    setState(() {
      _proactiveAssistance.removeAt(index);
    });
  }
}
