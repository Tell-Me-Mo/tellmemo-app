// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'proactive_assistance_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AnswerSourceImpl _$$AnswerSourceImplFromJson(Map<String, dynamic> json) =>
    _$AnswerSourceImpl(
      contentId: json['contentId'] as String,
      title: json['title'] as String,
      snippet: json['snippet'] as String,
      date: DateTime.parse(json['date'] as String),
      relevanceScore: (json['relevanceScore'] as num).toDouble(),
      meetingType: json['meetingType'] as String,
    );

Map<String, dynamic> _$$AnswerSourceImplToJson(_$AnswerSourceImpl instance) =>
    <String, dynamic>{
      'contentId': instance.contentId,
      'title': instance.title,
      'snippet': instance.snippet,
      'date': instance.date.toIso8601String(),
      'relevanceScore': instance.relevanceScore,
      'meetingType': instance.meetingType,
    };

_$AutoAnswerAssistanceImpl _$$AutoAnswerAssistanceImplFromJson(
  Map<String, dynamic> json,
) => _$AutoAnswerAssistanceImpl(
  insightId: json['insightId'] as String,
  question: json['question'] as String,
  answer: json['answer'] as String,
  confidence: (json['confidence'] as num).toDouble(),
  sources: (json['sources'] as List<dynamic>)
      .map((e) => AnswerSource.fromJson(e as Map<String, dynamic>))
      .toList(),
  reasoning: json['reasoning'] as String,
  timestamp: DateTime.parse(json['timestamp'] as String),
);

Map<String, dynamic> _$$AutoAnswerAssistanceImplToJson(
  _$AutoAnswerAssistanceImpl instance,
) => <String, dynamic>{
  'insightId': instance.insightId,
  'question': instance.question,
  'answer': instance.answer,
  'confidence': instance.confidence,
  'sources': instance.sources,
  'reasoning': instance.reasoning,
  'timestamp': instance.timestamp.toIso8601String(),
};
