import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pm_master_v2/core/converters/date_time_converter.dart';

part 'summary_model.freezed.dart';
part 'summary_model.g.dart';

enum SummaryType {
  @JsonValue('MEETING')
  meeting,
  @JsonValue('PROJECT')
  project,
  @JsonValue('PROGRAM')
  program,
  @JsonValue('PORTFOLIO')
  portfolio,
}

enum SummaryFormat {
  @JsonValue('general')
  general,
  @JsonValue('executive')
  executive,
  @JsonValue('technical')
  technical,
  @JsonValue('stakeholder')
  stakeholder,
}

// Enhanced Action Item model
@freezed
class ActionItem with _$ActionItem {
  const factory ActionItem({
    required String description,
    @Default('medium') String urgency,
    @JsonKey(name: 'due_date') String? dueDate,
    String? assignee,
    @Default([]) List<String> dependencies,
    @Default('not_started') String status,
    @JsonKey(name: 'follow_up_required') @Default(false) bool followUpRequired,
  }) = _ActionItem;

  factory ActionItem.fromJson(Map<String, dynamic> json) =>
      _$ActionItemFromJson(json);
}

// Enhanced Decision model
@freezed
class Decision with _$Decision {
  const factory Decision({
    required String description,
    @JsonKey(name: 'importance_score') @Default('medium') String importanceScore,
    @JsonKey(name: 'decision_type') @Default('operational') String decisionType,
    @JsonKey(name: 'stakeholders_affected') @Default([]) List<String> stakeholdersAffected,
    String? rationale,
  }) = _Decision;

  factory Decision.fromJson(Map<String, dynamic> json) =>
      _$DecisionFromJson(json);
}

// Next Meeting Agenda Item model
@freezed
class AgendaItem with _$AgendaItem {
  const factory AgendaItem({
    required String title,
    required String description,
    @Default('medium') String priority,
    @JsonKey(name: 'estimated_time') @Default(15) int estimatedTime,
    String? presenter,
    @JsonKey(name: 'related_action_items') @Default([]) List<String> relatedActionItems,
    @Default('discussion') String category,
  }) = _AgendaItem;

  factory AgendaItem.fromJson(Map<String, dynamic> json) =>
      _$AgendaItemFromJson(json);
}

// Communication Insights Models
@freezed
class UnansweredQuestion with _$UnansweredQuestion {
  const factory UnansweredQuestion({
    required String question,
    required String context,
    @Default('medium') String urgency,
    @JsonKey(name: 'raised_by') String? raisedBy,
    @JsonKey(name: 'topic_area') String? topicArea,
  }) = _UnansweredQuestion;

  factory UnansweredQuestion.fromJson(Map<String, dynamic> json) =>
      _$UnansweredQuestionFromJson(json);
}

@freezed
class EffectivenessScore with _$EffectivenessScore {
  const factory EffectivenessScore({
    @Default(0.0) double overall,
    @JsonKey(name: 'agenda_coverage') @Default(0.0) double agendaCoverage,
    @JsonKey(name: 'decision_velocity') @Default(0.0) double decisionVelocity,
    @JsonKey(name: 'time_efficiency') @Default(0.0) double timeEfficiency,
    @JsonKey(name: 'participation_balance') @Default(0.0) double participationBalance,
    @JsonKey(name: 'clarity_score') @Default(0.0) double clarityScore,
  }) = _EffectivenessScore;

  factory EffectivenessScore.fromJson(Map<String, dynamic> json) =>
      _$EffectivenessScoreFromJson(json);
}

@freezed
class ImprovementSuggestion with _$ImprovementSuggestion {
  const factory ImprovementSuggestion({
    required String suggestion,
    @Default('general') String category,
    @Default('medium') String priority,
    @JsonKey(name: 'expected_impact') String? expectedImpact,
  }) = _ImprovementSuggestion;

  factory ImprovementSuggestion.fromJson(Map<String, dynamic> json) =>
      _$ImprovementSuggestionFromJson(json);
}

// Lesson Learned model
@freezed
class LessonLearned with _$LessonLearned {
  const factory LessonLearned({
    required String title,
    required String description,
    @Default('other') String category,
    @JsonKey(name: 'lesson_type') @Default('improvement') String lessonType,
    @Default('medium') String impact,
    String? recommendation,
    String? context,
  }) = _LessonLearned;

  factory LessonLearned.fromJson(Map<String, dynamic> json) =>
      _$LessonLearnedFromJson(json);
}

@freezed
class CommunicationInsights with _$CommunicationInsights {
  const factory CommunicationInsights({
    @JsonKey(name: 'unanswered_questions', fromJson: _unansweredQuestionsFromJson)
    @Default([])
    List<UnansweredQuestion> unansweredQuestions,
    @JsonKey(name: 'effectiveness_score', fromJson: _effectivenessScoreFromJson)
    EffectivenessScore? effectivenessScore,
    @JsonKey(name: 'improvement_suggestions', fromJson: _improvementSuggestionsFromJson)
    @Default([])
    List<ImprovementSuggestion> improvementSuggestions,
  }) = _CommunicationInsights;

  factory CommunicationInsights.fromJson(Map<String, dynamic> json) =>
      _$CommunicationInsightsFromJson(json);
}

@freezed
class SummaryModel with _$SummaryModel {
  const SummaryModel._();
  
  const factory SummaryModel({
    @JsonKey(name: 'summary_id') required String id,
    @JsonKey(name: 'project_id') String? projectId,
    @JsonKey(name: 'content_id') String? contentId,
    @JsonKey(name: 'summary_type') required SummaryType summaryType,
    required String subject,
    required String body,
    @JsonKey(name: 'key_points') List<String>? keyPoints,
    @JsonKey(name: 'decisions', fromJson: _decisionsFromJson) List<Decision>? decisions,
    @JsonKey(name: 'action_items', fromJson: _actionItemsFromJson) List<ActionItem>? actionItems,
    @JsonKey(name: 'lessons_learned', fromJson: _lessonsLearnedFromJson) List<LessonLearned>? lessonsLearned,
    @JsonKey(name: 'sentiment_analysis') Map<String, dynamic>? sentimentAnalysis,
    @JsonKey(name: 'risks') List<Map<String, dynamic>>? risks,
    @JsonKey(name: 'blockers') List<Map<String, dynamic>>? blockers,
    @JsonKey(name: 'communication_insights', fromJson: _communicationInsightsFromJson) CommunicationInsights? communicationInsights,
    @JsonKey(name: 'cross_meeting_insights') Map<String, dynamic>? crossMeetingInsights,
    @JsonKey(name: 'next_meeting_agenda', fromJson: _agendaItemsFromJson) List<AgendaItem>? nextMeetingAgenda,
    @JsonKey(name: 'created_at') @DateTimeConverter() required DateTime createdAt,
    @JsonKey(name: 'created_by') String? createdBy,
    @JsonKey(name: 'date_range_start') @DateTimeConverterNullable() DateTime? dateRangeStart,
    @JsonKey(name: 'date_range_end') @DateTimeConverterNullable() DateTime? dateRangeEnd,
    @JsonKey(name: 'token_count') int? tokenCount,
    @JsonKey(name: 'generation_time_ms') int? generationTimeMs,
    @JsonKey(name: 'llm_cost') double? llmCost,
    @Default('general') String format,
  }) = _SummaryModel;

  factory SummaryModel.fromJson(Map<String, dynamic> json) =>
      _$SummaryModelFromJson(json);
  
  // Add a getter for backward compatibility
  String get summaryId => id;
}

// Helper functions for parsing decisions and action items with backward compatibility
List<Decision>? _decisionsFromJson(dynamic json) {
  if (json == null) return null;
  if (json is List) {
    return json.map((item) {
      if (item is String) {
        // Backward compatibility: convert string to Decision object
        return Decision(description: item);
      } else if (item is Map<String, dynamic>) {
        return Decision.fromJson(item);
      }
      return Decision(description: item.toString());
    }).toList();
  }
  return null;
}

List<ActionItem>? _actionItemsFromJson(dynamic json) {
  if (json == null) return null;
  if (json is List) {
    return json.map((item) {
      if (item is String) {
        // Backward compatibility: convert string to ActionItem object
        return ActionItem(description: item);
      } else if (item is Map<String, dynamic>) {
        return ActionItem.fromJson(item);
      }
      return ActionItem(description: item.toString());
    }).toList();
  }
  return null;
}

List<AgendaItem>? _agendaItemsFromJson(dynamic json) {
  if (json == null) return null;
  if (json is List) {
    return json.map((item) {
      if (item is Map<String, dynamic>) {
        return AgendaItem.fromJson(item);
      }
      // Fallback for unexpected data format
      return AgendaItem(
        title: 'Agenda Item',
        description: item.toString(),
      );
    }).toList();
  }
  return null;
}

List<LessonLearned>? _lessonsLearnedFromJson(dynamic json) {
  if (json == null) return null;
  if (json is List) {
    return json.map((item) {
      if (item is Map<String, dynamic>) {
        return LessonLearned.fromJson(item);
      }
      // Fallback for string format
      return LessonLearned(
        title: 'Lesson Learned',
        description: item.toString(),
      );
    }).toList();
  }
  return null;
}

// Helper functions for parsing communication insights
List<UnansweredQuestion> _unansweredQuestionsFromJson(dynamic json) {
  if (json == null) return [];
  if (json is List) {
    return json.map((item) {
      if (item is Map<String, dynamic>) {
        return UnansweredQuestion.fromJson(item);
      }
      return const UnansweredQuestion(
        question: 'Unknown question',
        context: 'Unknown context',
      );
    }).toList();
  }
  return [];
}

EffectivenessScore? _effectivenessScoreFromJson(dynamic json) {
  if (json == null) return null;
  if (json is Map<String, dynamic>) {
    return EffectivenessScore.fromJson(json);
  }
  return const EffectivenessScore();
}

List<ImprovementSuggestion> _improvementSuggestionsFromJson(dynamic json) {
  if (json == null) return [];
  if (json is List) {
    return json.map((item) {
      if (item is Map<String, dynamic>) {
        return ImprovementSuggestion.fromJson(item);
      }
      return ImprovementSuggestion(
        suggestion: item.toString(),
      );
    }).toList();
  }
  return [];
}

CommunicationInsights? _communicationInsightsFromJson(dynamic json) {
  if (json == null) return null;
  if (json is Map<String, dynamic>) {
    return CommunicationInsights.fromJson(json);
  }
  return null;
}

@freezed
class SummaryRequest with _$SummaryRequest {
  const factory SummaryRequest({
    @JsonKey(name: 'type') required String type,
    @JsonKey(name: 'content_id') String? contentId,
    @JsonKey(name: 'date_range_start') DateTime? dateRangeStart,
    @JsonKey(name: 'date_range_end') DateTime? dateRangeEnd,
    @JsonKey(name: 'created_by') String? createdBy,
    @JsonKey(name: 'format') @Default('general') String format,
  }) = _SummaryRequest;

  factory SummaryRequest.fromJson(Map<String, dynamic> json) =>
      _$SummaryRequestFromJson(json);
}

@freezed
class SummariesResponse with _$SummariesResponse {
  const factory SummariesResponse({
    required List<SummaryModel> summaries,
    int? total,
  }) = _SummariesResponse;

  factory SummariesResponse.fromJson(Map<String, dynamic> json) =>
      _$SummariesResponseFromJson(json);
}