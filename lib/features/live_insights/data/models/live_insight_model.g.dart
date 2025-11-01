// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'live_insight_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TierResultImpl _$$TierResultImplFromJson(Map<String, dynamic> json) =>
    _$TierResultImpl(
      tierType: $enumDecode(_$TierTypeEnumMap, json['tierType']),
      content: json['content'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
      source: json['source'] as String?,
      foundAt: const DateTimeConverter().fromJson(json['foundAt']),
    );

Map<String, dynamic> _$$TierResultImplToJson(_$TierResultImpl instance) =>
    <String, dynamic>{
      'tierType': _$TierTypeEnumMap[instance.tierType]!,
      'content': instance.content,
      'confidence': instance.confidence,
      'metadata': instance.metadata,
      'source': instance.source,
      'foundAt': const DateTimeConverter().toJson(instance.foundAt),
    };

const _$TierTypeEnumMap = {
  TierType.rag: 'rag',
  TierType.meetingContext: 'meeting_context',
  TierType.liveConversation: 'live_conversation',
  TierType.gptGenerated: 'gpt_generated',
};

_$LiveQuestionImpl _$$LiveQuestionImplFromJson(Map<String, dynamic> json) =>
    _$LiveQuestionImpl(
      id: json['id'] as String,
      text: json['text'] as String,
      timestamp: const DateTimeConverter().fromJson(json['timestamp']),
      status: $enumDecode(_$InsightStatusEnumMap, json['status']),
      tierResults:
          (json['tierResults'] as List<dynamic>?)
              ?.map((e) => TierResult.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      answerSource: $enumDecodeNullable(
        _$AnswerSourceEnumMap,
        json['answerSource'],
      ),
      category: json['category'] as String? ?? 'factual',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
      answeredAt: const DateTimeConverterNullable().fromJson(
        json['answeredAt'],
      ),
    );

Map<String, dynamic> _$$LiveQuestionImplToJson(
  _$LiveQuestionImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'text': instance.text,
  'timestamp': const DateTimeConverter().toJson(instance.timestamp),
  'status': _$InsightStatusEnumMap[instance.status]!,
  'tierResults': instance.tierResults,
  'answerSource': _$AnswerSourceEnumMap[instance.answerSource],
  'category': instance.category,
  'confidence': instance.confidence,
  'metadata': instance.metadata,
  'answeredAt': const DateTimeConverterNullable().toJson(instance.answeredAt),
};

const _$InsightStatusEnumMap = {
  InsightStatus.searching: 'searching',
  InsightStatus.found: 'found',
  InsightStatus.monitoring: 'monitoring',
  InsightStatus.answered: 'answered',
  InsightStatus.unanswered: 'unanswered',
  InsightStatus.tracked: 'tracked',
  InsightStatus.complete: 'complete',
};

const _$AnswerSourceEnumMap = {
  AnswerSource.rag: 'rag',
  AnswerSource.meetingContext: 'meeting_context',
  AnswerSource.liveConversation: 'live_conversation',
  AnswerSource.gptGenerated: 'gpt_generated',
  AnswerSource.userProvided: 'user_provided',
  AnswerSource.unanswered: 'unanswered',
};

_$LiveActionImpl _$$LiveActionImplFromJson(Map<String, dynamic> json) =>
    _$LiveActionImpl(
      id: json['id'] as String,
      description: json['description'] as String,
      owner: json['owner'] as String?,
      deadline: const DateTimeConverterNullable().fromJson(json['deadline']),
      completenessScore: (json['completenessScore'] as num?)?.toDouble() ?? 0.4,
      status:
          $enumDecodeNullable(_$InsightStatusEnumMap, json['status']) ??
          InsightStatus.tracked,
      timestamp: const DateTimeConverter().fromJson(json['timestamp']),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
      completedAt: const DateTimeConverterNullable().fromJson(
        json['completedAt'],
      ),
    );

Map<String, dynamic> _$$LiveActionImplToJson(
  _$LiveActionImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'description': instance.description,
  'owner': instance.owner,
  'deadline': const DateTimeConverterNullable().toJson(instance.deadline),
  'completenessScore': instance.completenessScore,
  'status': _$InsightStatusEnumMap[instance.status]!,
  'timestamp': const DateTimeConverter().toJson(instance.timestamp),
  'confidence': instance.confidence,
  'metadata': instance.metadata,
  'completedAt': const DateTimeConverterNullable().toJson(instance.completedAt),
};

_$TranscriptSegmentImpl _$$TranscriptSegmentImplFromJson(
  Map<String, dynamic> json,
) => _$TranscriptSegmentImpl(
  id: json['id'] as String,
  text: json['text'] as String,
  startTime: const DateTimeConverter().fromJson(json['startTime']),
  endTime: const DateTimeConverterNullable().fromJson(json['endTime']),
  isFinal: json['isFinal'] as bool? ?? false,
  confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
  metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
);

Map<String, dynamic> _$$TranscriptSegmentImplToJson(
  _$TranscriptSegmentImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'text': instance.text,
  'startTime': const DateTimeConverter().toJson(instance.startTime),
  'endTime': const DateTimeConverterNullable().toJson(instance.endTime),
  'isFinal': instance.isFinal,
  'confidence': instance.confidence,
  'metadata': instance.metadata,
};
