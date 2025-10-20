import 'package:freezed_annotation/freezed_annotation.dart';

part 'proactive_assistance_model.freezed.dart';
part 'proactive_assistance_model.g.dart';

/// Types of proactive assistance the AI can provide
enum ProactiveAssistanceType {
  @JsonValue('auto_answer')
  autoAnswer,
  @JsonValue('clarification_needed')
  clarificationNeeded,
  @JsonValue('conflict_detected')
  conflictDetected,
  @JsonValue('incomplete_action_item')
  incompleteActionItem,
  @JsonValue('follow_up_suggestion')
  followUpSuggestion,
}

/// Source document used to answer a question
@freezed
class AnswerSource with _$AnswerSource {
  const factory AnswerSource({
    required String contentId,
    required String title,
    required String snippet,
    required DateTime date,
    required double relevanceScore,
    required String meetingType,
  }) = _AnswerSource;

  factory AnswerSource.fromJson(Map<String, dynamic> json) =>
      _$AnswerSourceFromJson(json);
}

/// Auto-answered question with sources
@freezed
class AutoAnswerAssistance with _$AutoAnswerAssistance {
  const factory AutoAnswerAssistance({
    @JsonKey(name: 'insight_id') required String insightId,
    required String question,
    required String answer,
    required double confidence,
    required List<AnswerSource> sources,
    required String reasoning,
    required DateTime timestamp,
  }) = _AutoAnswerAssistance;

  factory AutoAnswerAssistance.fromJson(Map<String, dynamic> json) =>
      _$AutoAnswerAssistanceFromJson(json);
}

/// Clarification suggestion for vague statements
@freezed
class ClarificationAssistance with _$ClarificationAssistance {
  const factory ClarificationAssistance({
    @JsonKey(name: 'insight_id') required String insightId,
    required String statement,
    @JsonKey(name: 'vagueness_type') required String vaguenessType, // 'time', 'assignment', 'detail', 'scope'
    @JsonKey(name: 'suggested_questions') required List<String> suggestedQuestions,
    required double confidence,
    required String reasoning,
    required DateTime timestamp,
  }) = _ClarificationAssistance;

  factory ClarificationAssistance.fromJson(Map<String, dynamic> json) =>
      _$ClarificationAssistanceFromJson(json);
}

/// Conflict alert for decisions that contradict past decisions
@freezed
class ConflictAssistance with _$ConflictAssistance {
  const factory ConflictAssistance({
    @JsonKey(name: 'insight_id') required String insightId,
    @JsonKey(name: 'current_statement') required String currentStatement,
    @JsonKey(name: 'conflicting_content_id') required String conflictingContentId,
    @JsonKey(name: 'conflicting_title') required String conflictingTitle,
    @JsonKey(name: 'conflicting_snippet') required String conflictingSnippet,
    @JsonKey(name: 'conflicting_date') required DateTime conflictingDate,
    @JsonKey(name: 'conflict_severity') required String conflictSeverity, // 'high', 'medium', 'low'
    required double confidence,
    required String reasoning,
    @JsonKey(name: 'resolution_suggestions') required List<String> resolutionSuggestions,
    required DateTime timestamp,
  }) = _ConflictAssistance;

  factory ConflictAssistance.fromJson(Map<String, dynamic> json) =>
      _$ConflictAssistanceFromJson(json);
}

/// Quality issue found in an action item
@freezed
class QualityIssue with _$QualityIssue {
  const factory QualityIssue({
    required String field, // 'owner', 'deadline', 'description', 'success_criteria'
    required String severity, // 'critical', 'important', 'suggestion'
    required String message,
    @JsonKey(name: 'suggested_fix') String? suggestedFix,
  }) = _QualityIssue;

  factory QualityIssue.fromJson(Map<String, dynamic> json) =>
      _$QualityIssueFromJson(json);
}

/// Action item quality enhancement suggestion
@freezed
class ActionItemQualityAssistance with _$ActionItemQualityAssistance {
  const factory ActionItemQualityAssistance({
    @JsonKey(name: 'insight_id') required String insightId,
    @JsonKey(name: 'action_item') required String actionItem,
    @JsonKey(name: 'completeness_score') required double completenessScore,
    required List<QualityIssue> issues,
    @JsonKey(name: 'improved_version') String? improvedVersion,
    required DateTime timestamp,
  }) = _ActionItemQualityAssistance;

  factory ActionItemQualityAssistance.fromJson(Map<String, dynamic> json) =>
      _$ActionItemQualityAssistanceFromJson(json);
}

/// Follow-up suggestion for related topics to discuss
@freezed
class FollowUpSuggestionAssistance with _$FollowUpSuggestionAssistance {
  const factory FollowUpSuggestionAssistance({
    @JsonKey(name: 'insight_id') required String insightId,
    required String topic,
    required String reason,
    @JsonKey(name: 'related_content_id') required String relatedContentId,
    @JsonKey(name: 'related_title') required String relatedTitle,
    @JsonKey(name: 'related_date') required DateTime relatedDate,
    required String urgency, // 'high', 'medium', 'low'
    @JsonKey(name: 'context_snippet') required String contextSnippet,
    required double confidence,
    required DateTime timestamp,
  }) = _FollowUpSuggestionAssistance;

  factory FollowUpSuggestionAssistance.fromJson(Map<String, dynamic> json) =>
      _$FollowUpSuggestionAssistanceFromJson(json);
}

/// Main proactive assistance model
@freezed
class ProactiveAssistanceModel with _$ProactiveAssistanceModel {
  const factory ProactiveAssistanceModel({
    required ProactiveAssistanceType type,
    AutoAnswerAssistance? autoAnswer,
    ClarificationAssistance? clarification,
    ConflictAssistance? conflict,
    ActionItemQualityAssistance? actionItemQuality,
    FollowUpSuggestionAssistance? followUpSuggestion,
  }) = _ProactiveAssistanceModel;

  factory ProactiveAssistanceModel.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    final assistanceType = _parseAssistanceType(type);

    switch (assistanceType) {
      case ProactiveAssistanceType.autoAnswer:
        return ProactiveAssistanceModel(
          type: assistanceType,
          autoAnswer: AutoAnswerAssistance.fromJson(json),
        );
      case ProactiveAssistanceType.clarificationNeeded:
        return ProactiveAssistanceModel(
          type: assistanceType,
          clarification: ClarificationAssistance.fromJson(json),
        );
      case ProactiveAssistanceType.conflictDetected:
        return ProactiveAssistanceModel(
          type: assistanceType,
          conflict: ConflictAssistance.fromJson(json),
        );
      case ProactiveAssistanceType.incompleteActionItem:
        return ProactiveAssistanceModel(
          type: assistanceType,
          actionItemQuality: ActionItemQualityAssistance.fromJson(json),
        );
      case ProactiveAssistanceType.followUpSuggestion:
        return ProactiveAssistanceModel(
          type: assistanceType,
          followUpSuggestion: FollowUpSuggestionAssistance.fromJson(json),
        );
      default:
        return ProactiveAssistanceModel(type: assistanceType);
    }
  }

  static ProactiveAssistanceType _parseAssistanceType(String type) {
    switch (type) {
      case 'auto_answer':
        return ProactiveAssistanceType.autoAnswer;
      case 'clarification_needed':
        return ProactiveAssistanceType.clarificationNeeded;
      case 'conflict_detected':
        return ProactiveAssistanceType.conflictDetected;
      case 'incomplete_action_item':
        return ProactiveAssistanceType.incompleteActionItem;
      case 'follow_up_suggestion':
        return ProactiveAssistanceType.followUpSuggestion;
      default:
        throw ArgumentError('Unknown assistance type: $type');
    }
  }
}
