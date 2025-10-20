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
  insightId: json['insight_id'] as String,
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
  'insight_id': instance.insightId,
  'question': instance.question,
  'answer': instance.answer,
  'confidence': instance.confidence,
  'sources': instance.sources,
  'reasoning': instance.reasoning,
  'timestamp': instance.timestamp.toIso8601String(),
};

_$ClarificationAssistanceImpl _$$ClarificationAssistanceImplFromJson(
  Map<String, dynamic> json,
) => _$ClarificationAssistanceImpl(
  insightId: json['insight_id'] as String,
  statement: json['statement'] as String,
  vaguenessType: json['vagueness_type'] as String,
  suggestedQuestions: (json['suggested_questions'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  confidence: (json['confidence'] as num).toDouble(),
  reasoning: json['reasoning'] as String,
  timestamp: DateTime.parse(json['timestamp'] as String),
);

Map<String, dynamic> _$$ClarificationAssistanceImplToJson(
  _$ClarificationAssistanceImpl instance,
) => <String, dynamic>{
  'insight_id': instance.insightId,
  'statement': instance.statement,
  'vagueness_type': instance.vaguenessType,
  'suggested_questions': instance.suggestedQuestions,
  'confidence': instance.confidence,
  'reasoning': instance.reasoning,
  'timestamp': instance.timestamp.toIso8601String(),
};
