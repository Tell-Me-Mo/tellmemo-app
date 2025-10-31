// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transcript_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TranscriptModelImpl _$$TranscriptModelImplFromJson(
  Map<String, dynamic> json,
) => _$TranscriptModelImpl(
  id: json['id'] as String,
  text: json['text'] as String,
  speaker: json['speaker'] as String?,
  timestamp: DateTime.parse(json['timestamp'] as String),
  state: $enumDecode(_$TranscriptionStateEnumMap, json['state']),
  confidence: (json['confidence'] as num?)?.toDouble(),
  startMs: (json['startMs'] as num?)?.toInt(),
  endMs: (json['endMs'] as num?)?.toInt(),
);

Map<String, dynamic> _$$TranscriptModelImplToJson(
  _$TranscriptModelImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'text': instance.text,
  'speaker': instance.speaker,
  'timestamp': instance.timestamp.toIso8601String(),
  'state': _$TranscriptionStateEnumMap[instance.state]!,
  'confidence': instance.confidence,
  'startMs': instance.startMs,
  'endMs': instance.endMs,
};

const _$TranscriptionStateEnumMap = {
  TranscriptionState.partial: 'partial',
  TranscriptionState.final_: 'final',
};
