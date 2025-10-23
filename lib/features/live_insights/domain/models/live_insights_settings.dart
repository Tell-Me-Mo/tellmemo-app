import 'package:freezed_annotation/freezed_annotation.dart';
import 'proactive_assistance_model.dart';

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
    /// Set of enabled proactive assistance types
    @Default({
      ProactiveAssistanceType.autoAnswer,
      ProactiveAssistanceType.conflictDetected,
      ProactiveAssistanceType.incompleteActionItem,
    })
    Set<ProactiveAssistanceType> enabledPhases,

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
    ProactiveAssistanceType.repetitionDetected,
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
      case ProactiveAssistanceType.repetitionDetected:
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
      case ProactiveAssistanceType.repetitionDetected:
        return 'Repetition Detection';
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
      case ProactiveAssistanceType.repetitionDetected:
        return 'Detect circular discussions and monitor time usage';
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
      case ProactiveAssistanceType.repetitionDetected:
        return '🔶';
    }
  }

  factory LiveInsightsSettings.fromJson(Map<String, dynamic> json) =>
      _$LiveInsightsSettingsFromJson(json);
}
