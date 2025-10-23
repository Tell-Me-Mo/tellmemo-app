import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../live_insights/domain/models/proactive_assistance_model.dart';
import '../../../live_insights/presentation/widgets/proactive_assistance_card.dart';
import '../../../live_insights/presentation/widgets/live_insights_settings_dialog.dart';
import '../../../live_insights/presentation/providers/live_insights_settings_provider.dart';
import '../../../audio_recording/presentation/providers/recording_provider.dart';

/// Types of insights that can be displayed
enum InsightType {
  actionItem('action_item', Icons.assignment, Colors.blue),
  decision('decision', Icons.check_circle, Colors.green),
  question('question', Icons.help_outline, Colors.orange),
  risk('risk', Icons.warning, Colors.red),
  keyPoint('key_point', Icons.lightbulb_outline, Colors.purple),
  relatedDiscussion('related_discussion', Icons.history, Colors.teal),
  contradiction('contradiction', Icons.error_outline, Colors.deepOrange),
  missingInfo('missing_info', Icons.info_outline, Colors.amber);

  const InsightType(this.value, this.icon, this.color);
  final String value;
  final IconData icon;
  final Color color;

  static InsightType fromString(String value) {
    return InsightType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => InsightType.keyPoint,
    );
  }
}

/// Priority levels for insights
enum InsightPriority {
  critical('critical', Colors.red),
  high('high', Colors.orange),
  medium('medium', Colors.blue),
  low('low', Colors.grey);

  const InsightPriority(this.value, this.color);
  final String value;
  final Color color;

  static InsightPriority fromString(String value) {
    return InsightPriority.values.firstWhere(
      (priority) => priority.value == value,
      orElse: () => InsightPriority.medium,
    );
  }
}

/// Model class for meeting insights
class MeetingInsight {
  final String insightId;
  final InsightType type;
  final InsightPriority priority;
  final String content;
  final String context;
  final DateTime timestamp;
  final String? assignedTo;
  final String? dueDate;
  final double confidenceScore;
  final List<String>? relatedContentIds;
  final String? contradictionExplanation;

  const MeetingInsight({
    required this.insightId,
    required this.type,
    required this.priority,
    required this.content,
    required this.context,
    required this.timestamp,
    this.assignedTo,
    this.dueDate,
    this.confidenceScore = 0.0,
    this.relatedContentIds,
    this.contradictionExplanation,
  });

  factory MeetingInsight.fromJson(Map<String, dynamic> json) {
    return MeetingInsight(
      insightId: json['insight_id'] as String,
      type: InsightType.fromString(json['type'] as String),
      priority: InsightPriority.fromString(json['priority'] as String),
      content: json['content'] as String,
      context: json['context'] as String? ?? '',
      timestamp: DateTime.parse(json['timestamp'] as String),
      assignedTo: json['assigned_to'] as String?,
      dueDate: json['due_date'] as String?,
      confidenceScore: (json['confidence_score'] as num?)?.toDouble() ?? 0.0,
      relatedContentIds: (json['related_content_ids'] as List?)?.cast<String>(),
      contradictionExplanation: json['contradiction_explanation'] as String?,
    );
  }
}

/// Live Insights Panel Widget
///
/// Displays real-time insights extracted during a meeting in a side panel.
/// Shows categorized insights with filtering and search capabilities.
class LiveInsightsPanel extends ConsumerStatefulWidget {
  final List<MeetingInsight> insights;
  final bool isRecording;
  final VoidCallback? onClose;
  final double? width;

  const LiveInsightsPanel({
    super.key,
    required this.insights,
    this.isRecording = false,
    this.onClose,
    this.width,
  });

  @override
  ConsumerState<LiveInsightsPanel> createState() => _LiveInsightsPanelState();
}

class _LiveInsightsPanelState extends ConsumerState<LiveInsightsPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  Set<InsightType> _selectedTypes = {};
  Set<InsightPriority> _selectedPriorities = {};
  bool _showFilters = false;

  // Proactive assistance state
  List<ProactiveAssistanceModel> _proactiveAssistance = [];
  StreamSubscription<List<ProactiveAssistanceModel>>? _assistanceSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _setupProactiveAssistanceListener();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _assistanceSubscription?.cancel();
    super.dispose();
  }

  void _setupProactiveAssistanceListener() {
    // Get the WebSocket service from the recording provider
    final recordingNotifier = ref.read(recordingNotifierProvider.notifier);
    final wsService = recordingNotifier.liveInsightsService;

    if (wsService != null) {
      _assistanceSubscription = wsService.proactiveAssistanceStream.listen(
        (assistance) {
          if (mounted) {
            setState(() {
              // Get current settings
              final settings = ref.read(liveInsightsSettingsProvider);

              // Filter items based on settings (phase enabled, quiet mode, confidence)
              final visibleAssistance = assistance
                  .where((item) => settings.shouldShowAssistance(item))
                  .toList();

              _proactiveAssistance.addAll(visibleAssistance);
            });
          }
        },
        onError: (error) {
          debugPrint('[LiveInsightsPanel] Proactive assistance stream error: $error');
        },
      );
    }
  }

  void _handleAcceptAssistance(int index) {
    setState(() {
      _proactiveAssistance.removeAt(index);
    });
    debugPrint('[LiveInsightsPanel] User accepted assistance at index $index');
  }

  void _handleDismissAssistance(int index) {
    setState(() {
      _proactiveAssistance.removeAt(index);
    });
    debugPrint('[LiveInsightsPanel] User dismissed assistance at index $index');
  }

  /// Handle user feedback on proactive assistance
  void _handleFeedback(ProactiveAssistanceModel assistance, bool isHelpful) {
    // Get the WebSocket service
    final recordingNotifier = ref.read(recordingNotifierProvider.notifier);
    final wsService = recordingNotifier.liveInsightsService;

    if (wsService == null) {
      debugPrint('[LiveInsightsPanel] Cannot send feedback - WebSocket service not available');
      return;
    }

    // Extract insight ID and assistance type
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
        confidenceScore = null; // Uses completeness score instead
        break;
      case ProactiveAssistanceType.followUpSuggestion:
        insightId = assistance.followUpSuggestion?.insightId;
        confidenceScore = assistance.followUpSuggestion?.confidence;
        break;
      case ProactiveAssistanceType.repetitionDetected:
        insightId = assistance.repetitionDetection?.topic; // Use topic as ID
        confidenceScore = assistance.repetitionDetection?.confidence;
        break;
    }

    if (insightId == null) {
      debugPrint('[LiveInsightsPanel] Cannot send feedback - insight ID not found');
      return;
    }

    // Send feedback via WebSocket
    wsService.sendFeedback(
      insightId: insightId,
      isHelpful: isHelpful,
      assistanceType: assistanceType,
      confidenceScore: confidenceScore,
    );

    debugPrint(
      '[LiveInsightsPanel] Sent ${isHelpful ? "positive" : "negative"} feedback '
      'for $assistanceType (insight_id=$insightId)'
    );
  }

  List<MeetingInsight> get _filteredInsights {
    var filtered = widget.insights;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((insight) {
        return insight.content.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (insight.assignedTo?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      }).toList();
    }

    // Apply type filter
    if (_selectedTypes.isNotEmpty) {
      filtered = filtered.where((insight) => _selectedTypes.contains(insight.type)).toList();
    }

    // Apply priority filter
    if (_selectedPriorities.isNotEmpty) {
      filtered =
          filtered.where((insight) => _selectedPriorities.contains(insight.priority)).toList();
    }

    return filtered;
  }

  Map<InsightType, List<MeetingInsight>> get _insightsByType {
    final Map<InsightType, List<MeetingInsight>> grouped = {};
    for (final insight in _filteredInsights) {
      grouped.putIfAbsent(insight.type, () => []).add(insight);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = widget.width ?? 400.0;

    // Debug: Log insights count on every build
    debugPrint('🎨 [LiveInsightsPanel] build() called - ${widget.insights.length} insights passed to panel');
    if (widget.insights.isNotEmpty) {
      debugPrint('🎨 [LiveInsightsPanel] First insight: ${widget.insights.first.content.substring(0, widget.insights.first.content.length > 50 ? 50 : widget.insights.first.content.length)}...');
    }

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          left: BorderSide(
            color: theme.dividerColor,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(-2, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(theme),

          // Status indicator
          if (widget.isRecording) _buildRecordingIndicator(theme),

          // NEW: Proactive Assistance Section (AI Auto-Answers)
          if (_proactiveAssistance.isNotEmpty) ...[
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
                      Icon(Icons.auto_awesome, color: Colors.blue[700], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'AI Assistant',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[900],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_proactiveAssistance.length}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.blue[900],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 250,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _proactiveAssistance.length,
                      itemBuilder: (context, index) {
                        final assistance = _proactiveAssistance[index];
                        return SizedBox(
                          width: 350,
                          child: ProactiveAssistanceCard(
                            assistance: assistance,
                            onAccept: () => _handleAcceptAssistance(index),
                            onDismiss: () => _handleDismissAssistance(index),
                            onFeedback: (isHelpful) => _handleFeedback(assistance, isHelpful),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Statistics
          _buildStatistics(theme),

          // Search and filters
          _buildSearchAndFilters(theme),

          // Tab bar
          _buildTabBar(theme),

          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAllInsightsTab(),
                _buildCategorizedTab(),
                _buildTimelineTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.insights,
            color: theme.colorScheme.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Live Insights',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${widget.insights.length} insights extracted',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          const LiveInsightsSettingsButton(),
          if (widget.onClose != null)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: widget.onClose,
              tooltip: 'Close panel',
            ),
        ],
      ),
    );
  }

  Widget _buildRecordingIndicator(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.red.withOpacity(0.1),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Recording in progress...',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.red,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics(ThemeData theme) {
    final grouped = _insightsByType;
    final topTypes = grouped.entries.take(4).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: topTypes.map((entry) {
          return Chip(
            avatar: Icon(entry.key.icon, size: 16),
            label: Text('${entry.value.length}'),
            labelStyle: theme.textTheme.bodySmall,
            backgroundColor: entry.key.color.withOpacity(0.1),
            side: BorderSide(color: entry.key.color.withOpacity(0.3)),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSearchAndFilters(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Search bar
          TextField(
            decoration: InputDecoration(
              hintText: 'Search insights...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: Icon(
                  _showFilters ? Icons.filter_list_off : Icons.filter_list,
                ),
                onPressed: () {
                  setState(() {
                    _showFilters = !_showFilters;
                  });
                },
                tooltip: 'Toggle filters',
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),

          // Filters (collapsible)
          if (_showFilters) ...[
            const SizedBox(height: 12),
            _buildFilterChips(theme),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChips(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Filter by type',
          style: theme.textTheme.labelSmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: InsightType.values.map((type) {
            final isSelected = _selectedTypes.contains(type);
            return FilterChip(
              label: Text(type.value.replaceAll('_', ' ')),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedTypes.add(type);
                  } else {
                    _selectedTypes.remove(type);
                  }
                });
              },
              avatar: Icon(type.icon, size: 16),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTabBar(ThemeData theme) {
    return TabBar(
      controller: _tabController,
      tabs: const [
        Tab(text: 'All'),
        Tab(text: 'By Type'),
        Tab(text: 'Timeline'),
      ],
    );
  }

  Widget _buildAllInsightsTab() {
    if (_filteredInsights.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredInsights.length,
      itemBuilder: (context, index) {
        return _buildInsightCard(_filteredInsights[index]);
      },
    );
  }

  Widget _buildCategorizedTab() {
    final grouped = _insightsByType;

    if (grouped.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final entry = grouped.entries.elementAt(index);
        return _buildCategorySection(entry.key, entry.value);
      },
    );
  }

  Widget _buildTimelineTab() {
    if (_filteredInsights.isEmpty) {
      return _buildEmptyState();
    }

    // Sort by timestamp (most recent first)
    final sorted = List<MeetingInsight>.from(_filteredInsights)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sorted.length,
      itemBuilder: (context, index) {
        return _buildTimelineItem(sorted[index]);
      },
    );
  }

  Widget _buildInsightCard(MeetingInsight insight) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  insight.type.icon,
                  size: 20,
                  color: insight.type.color,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    insight.type.value.replaceAll('_', ' ').toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: insight.type.color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Priority indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: insight.priority.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: insight.priority.color.withOpacity(0.3)),
                  ),
                  child: Text(
                    insight.priority.value.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: insight.priority.color,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Content
            Text(
              insight.content,
              style: theme.textTheme.bodyMedium,
            ),

            // Metadata
            if (insight.assignedTo != null || insight.dueDate != null) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                children: [
                  if (insight.assignedTo != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          insight.assignedTo!,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  if (insight.dueDate != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          insight.dueDate!,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                ],
              ),
            ],

            // Confidence indicator
            if (insight.confidenceScore > 0) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: insight.confidenceScore,
                backgroundColor: Colors.grey.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation(insight.type.color),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection(InsightType type, List<MeetingInsight> insights) {
    return ExpansionTile(
      leading: Icon(type.icon, color: type.color),
      title: Text('${type.value.replaceAll('_', ' ')} (${insights.length})'),
      initiallyExpanded: true,
      children: insights.map((insight) => _buildInsightCard(insight)).toList(),
    );
  }

  Widget _buildTimelineItem(MeetingInsight insight) {
    final theme = Theme.of(context);
    final timeAgo = _getTimeAgo(insight.timestamp);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline indicator
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: insight.type.color,
                shape: BoxShape.circle,
              ),
            ),
            Container(
              width: 2,
              height: 40,
              color: theme.dividerColor,
            ),
          ],
        ),
        const SizedBox(width: 12),

        // Content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                timeAgo,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 4),
              _buildInsightCard(insight),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.insights_outlined,
            size: 64,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            widget.isRecording
                ? 'Listening for insights...'
                : 'No insights yet',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.isRecording
                ? 'Insights will appear here as the meeting progresses'
                : 'Start recording to see live insights',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else {
      return '${difference.inHours}h ago';
    }
  }
}
