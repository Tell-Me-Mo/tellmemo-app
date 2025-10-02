// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'summary_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ActionItemImpl _$$ActionItemImplFromJson(Map<String, dynamic> json) =>
    _$ActionItemImpl(
      description: json['description'] as String,
      urgency: json['urgency'] as String? ?? 'medium',
      dueDate: json['due_date'] as String?,
      assignee: json['assignee'] as String?,
      dependencies:
          (json['dependencies'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      status: json['status'] as String? ?? 'not_started',
      followUpRequired: json['follow_up_required'] as bool? ?? false,
    );

Map<String, dynamic> _$$ActionItemImplToJson(_$ActionItemImpl instance) =>
    <String, dynamic>{
      'description': instance.description,
      'urgency': instance.urgency,
      'due_date': instance.dueDate,
      'assignee': instance.assignee,
      'dependencies': instance.dependencies,
      'status': instance.status,
      'follow_up_required': instance.followUpRequired,
    };

_$DecisionImpl _$$DecisionImplFromJson(Map<String, dynamic> json) =>
    _$DecisionImpl(
      description: json['description'] as String,
      importanceScore: json['importance_score'] as String? ?? 'medium',
      decisionType: json['decision_type'] as String? ?? 'operational',
      stakeholdersAffected:
          (json['stakeholders_affected'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      rationale: json['rationale'] as String?,
    );

Map<String, dynamic> _$$DecisionImplToJson(_$DecisionImpl instance) =>
    <String, dynamic>{
      'description': instance.description,
      'importance_score': instance.importanceScore,
      'decision_type': instance.decisionType,
      'stakeholders_affected': instance.stakeholdersAffected,
      'rationale': instance.rationale,
    };

_$AgendaItemImpl _$$AgendaItemImplFromJson(Map<String, dynamic> json) =>
    _$AgendaItemImpl(
      title: json['title'] as String,
      description: json['description'] as String,
      priority: json['priority'] as String? ?? 'medium',
      estimatedTime: (json['estimated_time'] as num?)?.toInt() ?? 15,
      presenter: json['presenter'] as String?,
      relatedActionItems:
          (json['related_action_items'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      category: json['category'] as String? ?? 'discussion',
    );

Map<String, dynamic> _$$AgendaItemImplToJson(_$AgendaItemImpl instance) =>
    <String, dynamic>{
      'title': instance.title,
      'description': instance.description,
      'priority': instance.priority,
      'estimated_time': instance.estimatedTime,
      'presenter': instance.presenter,
      'related_action_items': instance.relatedActionItems,
      'category': instance.category,
    };

_$UnansweredQuestionImpl _$$UnansweredQuestionImplFromJson(
  Map<String, dynamic> json,
) => _$UnansweredQuestionImpl(
  question: json['question'] as String,
  context: json['context'] as String,
  urgency: json['urgency'] as String? ?? 'medium',
  raisedBy: json['raised_by'] as String?,
  topicArea: json['topic_area'] as String?,
);

Map<String, dynamic> _$$UnansweredQuestionImplToJson(
  _$UnansweredQuestionImpl instance,
) => <String, dynamic>{
  'question': instance.question,
  'context': instance.context,
  'urgency': instance.urgency,
  'raised_by': instance.raisedBy,
  'topic_area': instance.topicArea,
};

_$EffectivenessScoreImpl _$$EffectivenessScoreImplFromJson(
  Map<String, dynamic> json,
) => _$EffectivenessScoreImpl(
  overall: (json['overall'] as num?)?.toDouble() ?? 0.0,
  agendaCoverage: (json['agenda_coverage'] as num?)?.toDouble() ?? 0.0,
  decisionVelocity: (json['decision_velocity'] as num?)?.toDouble() ?? 0.0,
  timeEfficiency: (json['time_efficiency'] as num?)?.toDouble() ?? 0.0,
  participationBalance:
      (json['participation_balance'] as num?)?.toDouble() ?? 0.0,
  clarityScore: (json['clarity_score'] as num?)?.toDouble() ?? 0.0,
);

Map<String, dynamic> _$$EffectivenessScoreImplToJson(
  _$EffectivenessScoreImpl instance,
) => <String, dynamic>{
  'overall': instance.overall,
  'agenda_coverage': instance.agendaCoverage,
  'decision_velocity': instance.decisionVelocity,
  'time_efficiency': instance.timeEfficiency,
  'participation_balance': instance.participationBalance,
  'clarity_score': instance.clarityScore,
};

_$ImprovementSuggestionImpl _$$ImprovementSuggestionImplFromJson(
  Map<String, dynamic> json,
) => _$ImprovementSuggestionImpl(
  suggestion: json['suggestion'] as String,
  category: json['category'] as String? ?? 'general',
  priority: json['priority'] as String? ?? 'medium',
  expectedImpact: json['expected_impact'] as String?,
);

Map<String, dynamic> _$$ImprovementSuggestionImplToJson(
  _$ImprovementSuggestionImpl instance,
) => <String, dynamic>{
  'suggestion': instance.suggestion,
  'category': instance.category,
  'priority': instance.priority,
  'expected_impact': instance.expectedImpact,
};

_$LessonLearnedImpl _$$LessonLearnedImplFromJson(Map<String, dynamic> json) =>
    _$LessonLearnedImpl(
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String? ?? 'other',
      lessonType: json['lesson_type'] as String? ?? 'improvement',
      impact: json['impact'] as String? ?? 'medium',
      recommendation: json['recommendation'] as String?,
      context: json['context'] as String?,
    );

Map<String, dynamic> _$$LessonLearnedImplToJson(_$LessonLearnedImpl instance) =>
    <String, dynamic>{
      'title': instance.title,
      'description': instance.description,
      'category': instance.category,
      'lesson_type': instance.lessonType,
      'impact': instance.impact,
      'recommendation': instance.recommendation,
      'context': instance.context,
    };

_$CommunicationInsightsImpl _$$CommunicationInsightsImplFromJson(
  Map<String, dynamic> json,
) => _$CommunicationInsightsImpl(
  unansweredQuestions: json['unanswered_questions'] == null
      ? const []
      : _unansweredQuestionsFromJson(json['unanswered_questions']),
  effectivenessScore: _effectivenessScoreFromJson(json['effectiveness_score']),
  improvementSuggestions: json['improvement_suggestions'] == null
      ? const []
      : _improvementSuggestionsFromJson(json['improvement_suggestions']),
);

Map<String, dynamic> _$$CommunicationInsightsImplToJson(
  _$CommunicationInsightsImpl instance,
) => <String, dynamic>{
  'unanswered_questions': instance.unansweredQuestions,
  'effectiveness_score': instance.effectivenessScore,
  'improvement_suggestions': instance.improvementSuggestions,
};

_$SummaryModelImpl _$$SummaryModelImplFromJson(Map<String, dynamic> json) =>
    _$SummaryModelImpl(
      id: json['summary_id'] as String,
      projectId: json['project_id'] as String?,
      contentId: json['content_id'] as String?,
      summaryType: $enumDecode(_$SummaryTypeEnumMap, json['summary_type']),
      subject: json['subject'] as String,
      body: json['body'] as String,
      keyPoints: (json['key_points'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      decisions: _decisionsFromJson(json['decisions']),
      actionItems: _actionItemsFromJson(json['action_items']),
      lessonsLearned: _lessonsLearnedFromJson(json['lessons_learned']),
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
      crossMeetingInsights:
          json['cross_meeting_insights'] as Map<String, dynamic>?,
      nextMeetingAgenda: _agendaItemsFromJson(json['next_meeting_agenda']),
      createdAt: const DateTimeConverter().fromJson(json['created_at']),
      createdBy: json['created_by'] as String?,
      dateRangeStart: const DateTimeConverterNullable().fromJson(
        json['date_range_start'],
      ),
      dateRangeEnd: const DateTimeConverterNullable().fromJson(
        json['date_range_end'],
      ),
      tokenCount: (json['token_count'] as num?)?.toInt(),
      generationTimeMs: (json['generation_time_ms'] as num?)?.toInt(),
      llmCost: (json['llm_cost'] as num?)?.toDouble(),
      format: json['format'] as String? ?? 'general',
    );

Map<String, dynamic> _$$SummaryModelImplToJson(_$SummaryModelImpl instance) =>
    <String, dynamic>{
      'summary_id': instance.id,
      'project_id': instance.projectId,
      'content_id': instance.contentId,
      'summary_type': _$SummaryTypeEnumMap[instance.summaryType]!,
      'subject': instance.subject,
      'body': instance.body,
      'key_points': instance.keyPoints,
      'decisions': instance.decisions,
      'action_items': instance.actionItems,
      'lessons_learned': instance.lessonsLearned,
      'sentiment_analysis': instance.sentimentAnalysis,
      'risks': instance.risks,
      'blockers': instance.blockers,
      'communication_insights': instance.communicationInsights,
      'cross_meeting_insights': instance.crossMeetingInsights,
      'next_meeting_agenda': instance.nextMeetingAgenda,
      'created_at': const DateTimeConverter().toJson(instance.createdAt),
      'created_by': instance.createdBy,
      'date_range_start': const DateTimeConverterNullable().toJson(
        instance.dateRangeStart,
      ),
      'date_range_end': const DateTimeConverterNullable().toJson(
        instance.dateRangeEnd,
      ),
      'token_count': instance.tokenCount,
      'generation_time_ms': instance.generationTimeMs,
      'llm_cost': instance.llmCost,
      'format': instance.format,
    };

const _$SummaryTypeEnumMap = {
  SummaryType.meeting: 'MEETING',
  SummaryType.project: 'PROJECT',
  SummaryType.program: 'PROGRAM',
  SummaryType.portfolio: 'PORTFOLIO',
};

_$SummaryRequestImpl _$$SummaryRequestImplFromJson(Map<String, dynamic> json) =>
    _$SummaryRequestImpl(
      type: json['type'] as String,
      contentId: json['content_id'] as String?,
      dateRangeStart: json['date_range_start'] == null
          ? null
          : DateTime.parse(json['date_range_start'] as String),
      dateRangeEnd: json['date_range_end'] == null
          ? null
          : DateTime.parse(json['date_range_end'] as String),
      createdBy: json['created_by'] as String?,
      useJob: json['use_job'] as bool? ?? false,
      format: json['format'] as String? ?? 'general',
    );

Map<String, dynamic> _$$SummaryRequestImplToJson(
  _$SummaryRequestImpl instance,
) => <String, dynamic>{
  'type': instance.type,
  'content_id': instance.contentId,
  'date_range_start': instance.dateRangeStart?.toIso8601String(),
  'date_range_end': instance.dateRangeEnd?.toIso8601String(),
  'created_by': instance.createdBy,
  'use_job': instance.useJob,
  'format': instance.format,
};

_$SummariesResponseImpl _$$SummariesResponseImplFromJson(
  Map<String, dynamic> json,
) => _$SummariesResponseImpl(
  summaries: (json['summaries'] as List<dynamic>)
      .map((e) => SummaryModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  total: (json['total'] as num?)?.toInt(),
);

Map<String, dynamic> _$$SummariesResponseImplToJson(
  _$SummariesResponseImpl instance,
) => <String, dynamic>{
  'summaries': instance.summaries,
  'total': instance.total,
};
