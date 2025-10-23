// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'live_insight_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$LiveInsightModelImpl _$$LiveInsightModelImplFromJson(
  Map<String, dynamic> json,
) => _$LiveInsightModelImpl(
  id: json['id'] as String? ?? '',
  insightId: json['insight_id'] as String?,
  type: $enumDecode(_$LiveInsightTypeEnumMap, json['type']),
  priority: $enumDecode(_$LiveInsightPriorityEnumMap, json['priority']),
  content: json['content'] as String,
  context: json['context'] as String? ?? '',
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  timestamp: json['timestamp'] == null
      ? null
      : DateTime.parse(json['timestamp'] as String),
  assignedTo: json['assigned_to'] as String?,
  dueDate: json['due_date'] as String?,
  confidenceScore: (json['confidence_score'] as num?)?.toDouble() ?? 0.0,
  sourceChunkIndex: (json['chunk_index'] as num?)?.toInt(),
  metadata: json['metadata'] as Map<String, dynamic>?,
  relatedContentIds: (json['relatedContentIds'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  similarityScores: (json['similarityScores'] as List<dynamic>?)
      ?.map((e) => (e as num).toDouble())
      .toList(),
  contradictsContentId: json['contradictsContentId'] as String?,
  contradictionExplanation: json['contradictionExplanation'] as String?,
  evolutionType: json['evolution_type'] as String?,
  evolutionNote: json['evolution_note'] as String?,
  originalPriority: json['original_priority'] as String?,
);

Map<String, dynamic> _$$LiveInsightModelImplToJson(
  _$LiveInsightModelImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'insight_id': instance.insightId,
  'type': _$LiveInsightTypeEnumMap[instance.type]!,
  'priority': _$LiveInsightPriorityEnumMap[instance.priority]!,
  'content': instance.content,
  'context': instance.context,
  'created_at': instance.createdAt?.toIso8601String(),
  'timestamp': instance.timestamp?.toIso8601String(),
  'assigned_to': instance.assignedTo,
  'due_date': instance.dueDate,
  'confidence_score': instance.confidenceScore,
  'chunk_index': instance.sourceChunkIndex,
  'metadata': instance.metadata,
  'relatedContentIds': instance.relatedContentIds,
  'similarityScores': instance.similarityScores,
  'contradictsContentId': instance.contradictsContentId,
  'contradictionExplanation': instance.contradictionExplanation,
  'evolution_type': instance.evolutionType,
  'evolution_note': instance.evolutionNote,
  'original_priority': instance.originalPriority,
};

const _$LiveInsightTypeEnumMap = {
  LiveInsightType.actionItem: 'action_item',
  LiveInsightType.decision: 'decision',
  LiveInsightType.question: 'question',
  LiveInsightType.risk: 'risk',
  LiveInsightType.keyPoint: 'key_point',
  LiveInsightType.relatedDiscussion: 'related_discussion',
  LiveInsightType.contradiction: 'contradiction',
  LiveInsightType.missingInfo: 'missing_info',
};

const _$LiveInsightPriorityEnumMap = {
  LiveInsightPriority.critical: 'critical',
  LiveInsightPriority.high: 'high',
  LiveInsightPriority.medium: 'medium',
  LiveInsightPriority.low: 'low',
};
