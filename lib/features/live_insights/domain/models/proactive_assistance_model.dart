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
    required String insightId,
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

/// Main proactive assistance model
@freezed
class ProactiveAssistanceModel with _$ProactiveAssistanceModel {
  const factory ProactiveAssistanceModel({
    required ProactiveAssistanceType type,
    AutoAnswerAssistance? autoAnswer,
    // Future phases:
    // ClarificationAssistance? clarification,
    // ConflictAssistance? conflict,
    // ActionItemQualityAssistance? actionItemQuality,
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
      // Future phases will add other types here
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
