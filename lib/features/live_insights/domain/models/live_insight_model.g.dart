// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'live_insight_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$LiveInsightModelImpl _$$LiveInsightModelImplFromJson(
  Map<String, dynamic> json,
) => _$LiveInsightModelImpl(
  insightId: json['insightId'] as String,
  type: $enumDecode(_$LiveInsightTypeEnumMap, json['type']),
  priority: $enumDecode(_$LiveInsightPriorityEnumMap, json['priority']),
  content: json['content'] as String,
  context: json['context'] as String,
  timestamp: DateTime.parse(json['timestamp'] as String),
  assignedTo: json['assignedTo'] as String?,
  dueDate: json['dueDate'] as String?,
  confidenceScore: (json['confidenceScore'] as num?)?.toDouble() ?? 0.0,
  sourceChunkIndex: (json['sourceChunkIndex'] as num?)?.toInt(),
  relatedContentIds: (json['relatedContentIds'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  similarityScores: (json['similarityScores'] as List<dynamic>?)
      ?.map((e) => (e as num).toDouble())
      .toList(),
  contradictsContentId: json['contradictsContentId'] as String?,
  contradictionExplanation: json['contradictionExplanation'] as String?,
);

Map<String, dynamic> _$$LiveInsightModelImplToJson(
  _$LiveInsightModelImpl instance,
) => <String, dynamic>{
  'insightId': instance.insightId,
  'type': _$LiveInsightTypeEnumMap[instance.type]!,
  'priority': _$LiveInsightPriorityEnumMap[instance.priority]!,
  'content': instance.content,
  'context': instance.context,
  'timestamp': instance.timestamp.toIso8601String(),
  'assignedTo': instance.assignedTo,
  'dueDate': instance.dueDate,
  'confidenceScore': instance.confidenceScore,
  'sourceChunkIndex': instance.sourceChunkIndex,
  'relatedContentIds': instance.relatedContentIds,
  'similarityScores': instance.similarityScores,
  'contradictsContentId': instance.contradictsContentId,
  'contradictionExplanation': instance.contradictionExplanation,
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

_$TranscriptChunkImpl _$$TranscriptChunkImplFromJson(
  Map<String, dynamic> json,
) => _$TranscriptChunkImpl(
  chunkIndex: (json['chunkIndex'] as num).toInt(),
  text: json['text'] as String,
  speaker: json['speaker'] as String?,
  timestamp: DateTime.parse(json['timestamp'] as String),
);

Map<String, dynamic> _$$TranscriptChunkImplToJson(
  _$TranscriptChunkImpl instance,
) => <String, dynamic>{
  'chunkIndex': instance.chunkIndex,
  'text': instance.text,
  'speaker': instance.speaker,
  'timestamp': instance.timestamp.toIso8601String(),
};
