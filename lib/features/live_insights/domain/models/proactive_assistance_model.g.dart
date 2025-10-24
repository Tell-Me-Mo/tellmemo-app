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

_$ConflictAssistanceImpl _$$ConflictAssistanceImplFromJson(
  Map<String, dynamic> json,
) => _$ConflictAssistanceImpl(
  insightId: json['insight_id'] as String,
  currentStatement: json['current_statement'] as String,
  conflictingContentId: json['conflicting_content_id'] as String,
  conflictingTitle: json['conflicting_title'] as String,
  conflictingSnippet: json['conflicting_snippet'] as String,
  conflictingDate: DateTime.parse(json['conflicting_date'] as String),
  conflictSeverity: json['conflict_severity'] as String,
  confidence: (json['confidence'] as num).toDouble(),
  reasoning: json['reasoning'] as String,
  resolutionSuggestions: (json['resolution_suggestions'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  timestamp: DateTime.parse(json['timestamp'] as String),
);

Map<String, dynamic> _$$ConflictAssistanceImplToJson(
  _$ConflictAssistanceImpl instance,
) => <String, dynamic>{
  'insight_id': instance.insightId,
  'current_statement': instance.currentStatement,
  'conflicting_content_id': instance.conflictingContentId,
  'conflicting_title': instance.conflictingTitle,
  'conflicting_snippet': instance.conflictingSnippet,
  'conflicting_date': instance.conflictingDate.toIso8601String(),
  'conflict_severity': instance.conflictSeverity,
  'confidence': instance.confidence,
  'reasoning': instance.reasoning,
  'resolution_suggestions': instance.resolutionSuggestions,
  'timestamp': instance.timestamp.toIso8601String(),
};

_$QualityIssueImpl _$$QualityIssueImplFromJson(Map<String, dynamic> json) =>
    _$QualityIssueImpl(
      field: json['field'] as String,
      severity: json['severity'] as String,
      message: json['message'] as String,
      suggestedFix: json['suggested_fix'] as String?,
    );

Map<String, dynamic> _$$QualityIssueImplToJson(_$QualityIssueImpl instance) =>
    <String, dynamic>{
      'field': instance.field,
      'severity': instance.severity,
      'message': instance.message,
      'suggested_fix': instance.suggestedFix,
    };

_$ActionItemQualityAssistanceImpl _$$ActionItemQualityAssistanceImplFromJson(
  Map<String, dynamic> json,
) => _$ActionItemQualityAssistanceImpl(
  insightId: json['insight_id'] as String,
  actionItem: json['action_item'] as String,
  completenessScore: (json['completeness_score'] as num).toDouble(),
  issues: (json['issues'] as List<dynamic>)
      .map((e) => QualityIssue.fromJson(e as Map<String, dynamic>))
      .toList(),
  improvedVersion: json['improved_version'] as String?,
  timestamp: DateTime.parse(json['timestamp'] as String),
  clarificationSuggestions:
      (json['clarification_suggestions'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
  vaguenessType: json['vagueness_type'] as String?,
  vaguenessConfidence: (json['vagueness_confidence'] as num?)?.toDouble(),
  combinedReasoning: json['combined_reasoning'] as String?,
);

Map<String, dynamic> _$$ActionItemQualityAssistanceImplToJson(
  _$ActionItemQualityAssistanceImpl instance,
) => <String, dynamic>{
  'insight_id': instance.insightId,
  'action_item': instance.actionItem,
  'completeness_score': instance.completenessScore,
  'issues': instance.issues,
  'improved_version': instance.improvedVersion,
  'timestamp': instance.timestamp.toIso8601String(),
  'clarification_suggestions': instance.clarificationSuggestions,
  'vagueness_type': instance.vaguenessType,
  'vagueness_confidence': instance.vaguenessConfidence,
  'combined_reasoning': instance.combinedReasoning,
};

_$FollowUpSuggestionAssistanceImpl _$$FollowUpSuggestionAssistanceImplFromJson(
  Map<String, dynamic> json,
) => _$FollowUpSuggestionAssistanceImpl(
  insightId: json['insight_id'] as String,
  topic: json['topic'] as String,
  reason: json['reason'] as String,
  relatedContentId: json['related_content_id'] as String,
  relatedTitle: json['related_title'] as String,
  relatedDate: DateTime.parse(json['related_date'] as String),
  urgency: json['urgency'] as String,
  contextSnippet: json['context_snippet'] as String,
  confidence: (json['confidence'] as num).toDouble(),
  timestamp: DateTime.parse(json['timestamp'] as String),
);

Map<String, dynamic> _$$FollowUpSuggestionAssistanceImplToJson(
  _$FollowUpSuggestionAssistanceImpl instance,
) => <String, dynamic>{
  'insight_id': instance.insightId,
  'topic': instance.topic,
  'reason': instance.reason,
  'related_content_id': instance.relatedContentId,
  'related_title': instance.relatedTitle,
  'related_date': instance.relatedDate.toIso8601String(),
  'urgency': instance.urgency,
  'context_snippet': instance.contextSnippet,
  'confidence': instance.confidence,
  'timestamp': instance.timestamp.toIso8601String(),
};

_$RepetitionDetectionAssistanceImpl
_$$RepetitionDetectionAssistanceImplFromJson(Map<String, dynamic> json) =>
    _$RepetitionDetectionAssistanceImpl(
      topic: json['topic'] as String,
      firstMentionIndex: (json['first_mention_index'] as num).toInt(),
      currentMentionIndex: (json['current_mention_index'] as num).toInt(),
      occurrences: (json['occurrences'] as num).toInt(),
      timeSpanMinutes: (json['time_span_minutes'] as num).toDouble(),
      confidence: (json['confidence'] as num).toDouble(),
      reasoning: json['reasoning'] as String,
      suggestions: (json['suggestions'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );

Map<String, dynamic> _$$RepetitionDetectionAssistanceImplToJson(
  _$RepetitionDetectionAssistanceImpl instance,
) => <String, dynamic>{
  'topic': instance.topic,
  'first_mention_index': instance.firstMentionIndex,
  'current_mention_index': instance.currentMentionIndex,
  'occurrences': instance.occurrences,
  'time_span_minutes': instance.timeSpanMinutes,
  'confidence': instance.confidence,
  'reasoning': instance.reasoning,
  'suggestions': instance.suggestions,
  'timestamp': instance.timestamp.toIso8601String(),
};
