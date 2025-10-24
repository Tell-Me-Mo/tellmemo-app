import 'package:freezed_annotation/freezed_annotation.dart';
import 'proactive_assistance_model.dart';
import 'live_insight_model.dart';

part 'live_insights_settings.freezed.dart';
part 'live_insights_settings.g.dart';

/// Priority level for proactive assistance
enum AssistancePriority {
  /// Critical alerts that require immediate attention
  critical,

  /// Important alerts that should be reviewed
  important,

  /// Informational alerts that are nice to have
  informational,
}

/// Settings for Live Insights and Proactive Assistance features
@freezed
class LiveInsightsSettings with _$LiveInsightsSettings {
  const LiveInsightsSettings._();

  const factory LiveInsightsSettings({
    /// Set of enabled proactive assistance types (AI suggestions)
    @Default({
      ProactiveAssistanceType.autoAnswer,
      ProactiveAssistanceType.conflictDetected,
      ProactiveAssistanceType.incompleteActionItem,
    })
    Set<ProactiveAssistanceType> enabledPhases,

    /// Set of enabled insight types (extracted data)
    @Default({
      LiveInsightType.actionItem,
      LiveInsightType.decision,
      LiveInsightType.question,
      LiveInsightType.risk,
      LiveInsightType.keyPoint,
      LiveInsightType.relatedDiscussion,
      LiveInsightType.contradiction,
      LiveInsightType.missingInfo,
    })
    Set<LiveInsightType> enabledInsightTypes,

    /// Quiet mode - only show critical alerts
    @Default(false) bool quietMode,

    /// Show collapsed items by default (medium confidence)
    @Default(true) bool showCollapsedItems,

    /// Enable feedback collection
    @Default(true) bool enableFeedback,

    /// Auto-expand high confidence items
    @Default(true) bool autoExpandHighConfidence,
  }) = _LiveInsightsSettings;

  /// Default enabled phases (most valuable features)
  static const Set<ProactiveAssistanceType> defaultEnabledPhases = {
    ProactiveAssistanceType.autoAnswer,
    ProactiveAssistanceType.conflictDetected,
    ProactiveAssistanceType.incompleteActionItem,
  };

  /// All available phases
  static const Set<ProactiveAssistanceType> allPhases = {
    ProactiveAssistanceType.autoAnswer,
    ProactiveAssistanceType.clarificationNeeded,
    ProactiveAssistanceType.conflictDetected,
    ProactiveAssistanceType.incompleteActionItem,
    ProactiveAssistanceType.followUpSuggestion,
  };

  /// All available insight types
  static const Set<LiveInsightType> allInsightTypes = {
    LiveInsightType.actionItem,
    LiveInsightType.decision,
    LiveInsightType.question,
    LiveInsightType.risk,
    LiveInsightType.keyPoint,
    LiveInsightType.relatedDiscussion,
    LiveInsightType.contradiction,
    LiveInsightType.missingInfo,
  };

  /// Default enabled insight types (all types enabled by default)
  static const Set<LiveInsightType> defaultEnabledInsightTypes = {
    LiveInsightType.actionItem,
    LiveInsightType.decision,
    LiveInsightType.question,
    LiveInsightType.risk,
    LiveInsightType.keyPoint,
    LiveInsightType.relatedDiscussion,
    LiveInsightType.contradiction,
    LiveInsightType.missingInfo,
  };

  /// Determine priority level for assistance type
  static AssistancePriority getPriorityForType(ProactiveAssistanceType type) {
    switch (type) {
      case ProactiveAssistanceType.conflictDetected:
      case ProactiveAssistanceType.incompleteActionItem:
        return AssistancePriority.critical;

      case ProactiveAssistanceType.autoAnswer:
      case ProactiveAssistanceType.clarificationNeeded:
        return AssistancePriority.important;

      case ProactiveAssistanceType.followUpSuggestion:
        return AssistancePriority.informational;
    }
  }

  /// Check if a specific assistance should be shown based on settings
  bool shouldShowAssistance(ProactiveAssistanceModel assistance) {
    // Check if phase is enabled
    if (!enabledPhases.contains(assistance.type)) {
      return false;
    }

    // In quiet mode, only show critical alerts
    if (quietMode) {
      final priority = getPriorityForType(assistance.type);
      if (priority != AssistancePriority.critical) {
        return false;
      }
    }

    // Check display mode based on confidence
    final displayMode = assistance.displayMode;

    // Never show hidden items
    if (displayMode == DisplayMode.hidden) {
      return false;
    }

    // If showCollapsedItems is false, hide collapsed items
    if (displayMode == DisplayMode.collapsed && !showCollapsedItems) {
      return false;
    }

    return true;
  }

  /// Check if a specific insight type should be shown based on settings
  bool shouldShowInsight(LiveInsightModel insight) {
    // Check if insight type is enabled
    return enabledInsightTypes.contains(insight.type);
  }

  /// Get user-friendly label for assistance type
  static String getLabelForType(ProactiveAssistanceType type) {
    switch (type) {
      case ProactiveAssistanceType.autoAnswer:
        return 'Auto-Answer Questions';
      case ProactiveAssistanceType.clarificationNeeded:
        return 'Clarification Suggestions';
      case ProactiveAssistanceType.conflictDetected:
        return 'Conflict Detection';
      case ProactiveAssistanceType.incompleteActionItem:
        return 'Action Item Quality';
      case ProactiveAssistanceType.followUpSuggestion:
        return 'Follow-up Suggestions';
    }
  }

  /// Get description for assistance type
  static String getDescriptionForType(ProactiveAssistanceType type) {
    switch (type) {
      case ProactiveAssistanceType.autoAnswer:
        return 'Automatically answer questions using past meeting context';
      case ProactiveAssistanceType.clarificationNeeded:
        return 'Detect vague statements and suggest clarifying questions';
      case ProactiveAssistanceType.conflictDetected:
        return 'Alert when decisions contradict past decisions';
      case ProactiveAssistanceType.incompleteActionItem:
        return 'Ensure action items have owners, deadlines, and clear descriptions';
      case ProactiveAssistanceType.followUpSuggestion:
        return 'Recommend related topics and open items from past meetings';
    }
  }

  /// Get icon for assistance type
  static String getIconForType(ProactiveAssistanceType type) {
    switch (type) {
      case ProactiveAssistanceType.autoAnswer:
        return '💙';
      case ProactiveAssistanceType.clarificationNeeded:
        return '🧡';
      case ProactiveAssistanceType.conflictDetected:
        return '❤️';
      case ProactiveAssistanceType.incompleteActionItem:
        return '💛';
      case ProactiveAssistanceType.followUpSuggestion:
        return '💜';
    }
  }

  /// Get user-friendly label for insight type
  static String getLabelForInsightType(LiveInsightType type) {
    switch (type) {
      case LiveInsightType.actionItem:
        return 'Action Items';
      case LiveInsightType.decision:
        return 'Decisions';
      case LiveInsightType.question:
        return 'Questions';
      case LiveInsightType.risk:
        return 'Risks';
      case LiveInsightType.keyPoint:
        return 'Key Points';
      case LiveInsightType.relatedDiscussion:
        return 'Related Discussions';
      case LiveInsightType.contradiction:
        return 'Contradictions';
      case LiveInsightType.missingInfo:
        return 'Missing Info';
    }
  }

  /// Get description for insight type
  static String getDescriptionForInsightType(LiveInsightType type) {
    switch (type) {
      case LiveInsightType.actionItem:
        return 'Tasks and action items with owners and deadlines';
      case LiveInsightType.decision:
        return 'Decisions made during the meeting';
      case LiveInsightType.question:
        return 'Questions raised by participants';
      case LiveInsightType.risk:
        return 'Risks, concerns, and potential blockers';
      case LiveInsightType.keyPoint:
        return 'Important points and highlights';
      case LiveInsightType.relatedDiscussion:
        return 'References to past meeting discussions';
      case LiveInsightType.contradiction:
        return 'Conflicts with previous decisions';
      case LiveInsightType.missingInfo:
        return 'Missing information or context';
    }
  }

  /// Get icon for insight type
  static String getIconForInsightType(LiveInsightType type) {
    switch (type) {
      case LiveInsightType.actionItem:
        return '📋';
      case LiveInsightType.decision:
        return '✅';
      case LiveInsightType.question:
        return '❓';
      case LiveInsightType.risk:
        return '⚠️';
      case LiveInsightType.keyPoint:
        return '💡';
      case LiveInsightType.relatedDiscussion:
        return '📚';
      case LiveInsightType.contradiction:
        return '🔄';
      case LiveInsightType.missingInfo:
        return 'ℹ️';
    }
  }

  factory LiveInsightsSettings.fromJson(Map<String, dynamic> json) =>
      _$LiveInsightsSettingsFromJson(json);
}
