// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'unified_summary_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UnifiedSummaryRequestImpl _$$UnifiedSummaryRequestImplFromJson(
  Map<String, dynamic> json,
) => _$UnifiedSummaryRequestImpl(
  entityType: $enumDecode(_$EntityTypeEnumMap, json['entity_type']),
  entityId: json['entity_id'] as String,
  summaryType: $enumDecode(_$SummaryTypeEnumMap, json['summary_type']),
  contentId: json['content_id'] as String?,
  dateRangeStart: const DateTimeConverterNullable().fromJson(
    json['date_range_start'],
  ),
  dateRangeEnd: const DateTimeConverterNullable().fromJson(
    json['date_range_end'],
  ),
  format: json['format'] as String? ?? 'general',
  createdBy: json['created_by'] as String?,
  useJob: json['use_job'] as bool? ?? false,
);

Map<String, dynamic> _$$UnifiedSummaryRequestImplToJson(
  _$UnifiedSummaryRequestImpl instance,
) => <String, dynamic>{
  'entity_type': _$EntityTypeEnumMap[instance.entityType]!,
  'entity_id': instance.entityId,
  'summary_type': _$SummaryTypeEnumMap[instance.summaryType]!,
  'content_id': instance.contentId,
  'date_range_start': const DateTimeConverterNullable().toJson(
    instance.dateRangeStart,
  ),
  'date_range_end': const DateTimeConverterNullable().toJson(
    instance.dateRangeEnd,
  ),
  'format': instance.format,
  'created_by': instance.createdBy,
  'use_job': instance.useJob,
};

const _$EntityTypeEnumMap = {
  EntityType.project: 'project',
  EntityType.program: 'program',
  EntityType.portfolio: 'portfolio',
};

const _$SummaryTypeEnumMap = {
  SummaryType.meeting: 'MEETING',
  SummaryType.project: 'PROJECT',
  SummaryType.program: 'PROGRAM',
  SummaryType.portfolio: 'PORTFOLIO',
};

_$UnifiedSummaryResponseImpl _$$UnifiedSummaryResponseImplFromJson(
  Map<String, dynamic> json,
) => _$UnifiedSummaryResponseImpl(
  summaryId: json['summary_id'] as String,
  entityType: json['entity_type'] as String,
  entityId: json['entity_id'] as String,
  entityName: json['entity_name'] as String,
  contentId: json['content_id'] as String?,
  summaryType: json['summary_type'] as String,
  subject: json['subject'] as String,
  body: json['body'] as String,
  keyPoints: (json['key_points'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  decisions: _decisionsFromJson(json['decisions']),
  actionItems: _actionItemsFromJson(json['action_items']),
  sentimentAnalysis: json['sentiment_analysis'] as Map<String, dynamic>?,
  risks: (json['risks'] as List<dynamic>?)
      ?.map((e) => e as Map<String, dynamic>)
      .toList(),
  blockers: (json['blockers'] as List<dynamic>?)
      ?.map((e) => e as Map<String, dynamic>)
      .toList(),
  communicationInsights: _communicationInsightsFromJson(
    json['communication_insights'],
  ),
  nextMeetingAgenda: _agendaItemsFromJson(json['next_meeting_agenda']),
  format: json['format'] as String? ?? 'general',
  tokenCount: (json['token_count'] as num?)?.toInt(),
  generationTimeMs: (json['generation_time_ms'] as num?)?.toInt(),
  llmCost: (json['llm_cost'] as num?)?.toDouble(),
  createdAt: const DateTimeConverter().fromJson(json['created_at']),
  createdBy: json['created_by'] as String?,
  dateRangeStart: const DateTimeConverterNullable().fromJson(
    json['date_range_start'],
  ),
  dateRangeEnd: const DateTimeConverterNullable().fromJson(
    json['date_range_end'],
  ),
);

Map<String, dynamic> _$$UnifiedSummaryResponseImplToJson(
  _$UnifiedSummaryResponseImpl instance,
) => <String, dynamic>{
  'summary_id': instance.summaryId,
  'entity_type': instance.entityType,
  'entity_id': instance.entityId,
  'entity_name': instance.entityName,
  'content_id': instance.contentId,
  'summary_type': instance.summaryType,
  'subject': instance.subject,
  'body': instance.body,
  'key_points': instance.keyPoints,
  'decisions': instance.decisions,
  'action_items': instance.actionItems,
  'sentiment_analysis': instance.sentimentAnalysis,
  'risks': instance.risks,
  'blockers': instance.blockers,
  'communication_insights': instance.communicationInsights,
  'next_meeting_agenda': instance.nextMeetingAgenda,
  'format': instance.format,
  'token_count': instance.tokenCount,
  'generation_time_ms': instance.generationTimeMs,
  'llm_cost': instance.llmCost,
  'created_at': const DateTimeConverter().toJson(instance.createdAt),
  'created_by': instance.createdBy,
  'date_range_start': const DateTimeConverterNullable().toJson(
    instance.dateRangeStart,
  ),
  'date_range_end': const DateTimeConverterNullable().toJson(
    instance.dateRangeEnd,
  ),
};

_$SummaryFiltersImpl _$$SummaryFiltersImplFromJson(Map<String, dynamic> json) =>
    _$SummaryFiltersImpl(
      entityType: json['entity_type'] as String?,
      entityId: json['entity_id'] as String?,
      summaryType: json['summary_type'] as String?,
      format: json['format'] as String?,
      createdAfter: json['created_after'] == null
          ? null
          : DateTime.parse(json['created_after'] as String),
      createdBefore: json['created_before'] == null
          ? null
          : DateTime.parse(json['created_before'] as String),
      limit: (json['limit'] as num?)?.toInt() ?? 100,
      offset: (json['offset'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$SummaryFiltersImplToJson(
  _$SummaryFiltersImpl instance,
) => <String, dynamic>{
  'entity_type': instance.entityType,
  'entity_id': instance.entityId,
  'summary_type': instance.summaryType,
  'format': instance.format,
  'created_after': instance.createdAfter?.toIso8601String(),
  'created_before': instance.createdBefore?.toIso8601String(),
  'limit': instance.limit,
  'offset': instance.offset,
};
