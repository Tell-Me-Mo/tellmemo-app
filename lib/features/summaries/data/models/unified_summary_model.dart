import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pm_master_v2/core/converters/date_time_converter.dart';
import 'summary_model.dart';

part 'unified_summary_model.freezed.dart';
part 'unified_summary_model.g.dart';

enum EntityType {
  @JsonValue('project')
  project,
  @JsonValue('program')
  program,
  @JsonValue('portfolio')
  portfolio,
}

@freezed
class UnifiedSummaryRequest with _$UnifiedSummaryRequest {
  const factory UnifiedSummaryRequest({
    @JsonKey(name: 'entity_type') required EntityType entityType,
    @JsonKey(name: 'entity_id') required String entityId,
    @JsonKey(name: 'summary_type') required SummaryType summaryType,
    @JsonKey(name: 'content_id') String? contentId,
    @JsonKey(name: 'date_range_start') @DateTimeConverterNullable() DateTime? dateRangeStart,
    @JsonKey(name: 'date_range_end') @DateTimeConverterNullable() DateTime? dateRangeEnd,
    @Default('general') String format,
    @JsonKey(name: 'created_by') String? createdBy,
  }) = _UnifiedSummaryRequest;

  factory UnifiedSummaryRequest.fromJson(Map<String, dynamic> json) =>
      _$UnifiedSummaryRequestFromJson(json);
}

@freezed
class UnifiedSummaryResponse with _$UnifiedSummaryResponse {
  const UnifiedSummaryResponse._();

  const factory UnifiedSummaryResponse({
    @JsonKey(name: 'summary_id') required String summaryId,
    @JsonKey(name: 'entity_type') required String entityType,
    @JsonKey(name: 'entity_id') required String entityId,
    @JsonKey(name: 'entity_name') required String entityName,
    @JsonKey(name: 'content_id') String? contentId,
    @JsonKey(name: 'summary_type') required String summaryType,
    required String subject,
    required String body,
    @JsonKey(name: 'key_points') List<String>? keyPoints,
    @JsonKey(name: 'decisions', fromJson: _decisionsFromJson) List<Decision>? decisions,
    @JsonKey(name: 'action_items', fromJson: _actionItemsFromJson) List<ActionItem>? actionItems,
    @JsonKey(name: 'sentiment_analysis') Map<String, dynamic>? sentimentAnalysis,
    @JsonKey(name: 'risks') List<Map<String, dynamic>>? risks,
    @JsonKey(name: 'blockers') List<Map<String, dynamic>>? blockers,
    @JsonKey(name: 'communication_insights', fromJson: _communicationInsightsFromJson) CommunicationInsights? communicationInsights,
    @JsonKey(name: 'next_meeting_agenda', fromJson: _agendaItemsFromJson) List<AgendaItem>? nextMeetingAgenda,
    @Default('general') String format,
    @JsonKey(name: 'token_count') int? tokenCount,
    @JsonKey(name: 'generation_time_ms') int? generationTimeMs,
    @JsonKey(name: 'llm_cost') double? llmCost,
    @JsonKey(name: 'created_at') @DateTimeConverter() required DateTime createdAt,
    @JsonKey(name: 'created_by') String? createdBy,
    @JsonKey(name: 'date_range_start') @DateTimeConverterNullable() DateTime? dateRangeStart,
    @JsonKey(name: 'date_range_end') @DateTimeConverterNullable() DateTime? dateRangeEnd,
  }) = _UnifiedSummaryResponse;

  factory UnifiedSummaryResponse.fromJson(Map<String, dynamic> json) =>
      _$UnifiedSummaryResponseFromJson(json);

  // Convert to legacy SummaryModel for backward compatibility
  SummaryModel toLegacySummaryModel() {
    return SummaryModel(
      id: summaryId,
      projectId: entityType == 'project' ? entityId : null,
      contentId: contentId,
      summaryType: SummaryType.values.firstWhere(
        (e) => e.name.toUpperCase() == summaryType.toUpperCase(),
        orElse: () => SummaryType.meeting,
      ),
      subject: subject,
      body: body,
      keyPoints: keyPoints,
      decisions: decisions,
      actionItems: actionItems,
      sentimentAnalysis: sentimentAnalysis,
      risks: risks,
      blockers: blockers,
      communicationInsights: communicationInsights,
      nextMeetingAgenda: nextMeetingAgenda,
      createdAt: createdAt,
      createdBy: createdBy,
      dateRangeStart: dateRangeStart,
      dateRangeEnd: dateRangeEnd,
      tokenCount: tokenCount,
      generationTimeMs: generationTimeMs,
      llmCost: llmCost,
      format: format,
    );
  }
}

@freezed
class SummaryFilters with _$SummaryFilters {
  const factory SummaryFilters({
    @JsonKey(name: 'entity_type') String? entityType,
    @JsonKey(name: 'entity_id') String? entityId,
    @JsonKey(name: 'summary_type') String? summaryType,
    String? format,
    @JsonKey(name: 'created_after') DateTime? createdAfter,
    @JsonKey(name: 'created_before') DateTime? createdBefore,
    @Default(100) int limit,
    @Default(0) int offset,
  }) = _SummaryFilters;

  factory SummaryFilters.fromJson(Map<String, dynamic> json) =>
      _$SummaryFiltersFromJson(json);
}

// Helper functions for parsing (reused from summary_model.dart)
List<Decision>? _decisionsFromJson(dynamic json) {
  if (json == null) return null;
  if (json is List) {
    return json.map((item) {
      if (item is String) {
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
      return AgendaItem(
        title: 'Agenda Item',
        description: item.toString(),
      );
    }).toList();
  }
  return null;
}

CommunicationInsights? _communicationInsightsFromJson(dynamic json) {
  if (json == null) return null;
  if (json is Map<String, dynamic>) {
    return CommunicationInsights.fromJson(json);
  }
  return null;
}