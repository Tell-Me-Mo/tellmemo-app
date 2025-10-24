// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'live_insights_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$LiveInsightsSettingsImpl _$$LiveInsightsSettingsImplFromJson(
  Map<String, dynamic> json,
) => _$LiveInsightsSettingsImpl(
  enabledPhases:
      (json['enabledPhases'] as List<dynamic>?)
          ?.map((e) => $enumDecode(_$ProactiveAssistanceTypeEnumMap, e))
          .toSet() ??
      const {
        ProactiveAssistanceType.autoAnswer,
        ProactiveAssistanceType.conflictDetected,
        ProactiveAssistanceType.incompleteActionItem,
      },
  enabledInsightTypes:
      (json['enabledInsightTypes'] as List<dynamic>?)
          ?.map((e) => $enumDecode(_$LiveInsightTypeEnumMap, e))
          .toSet() ??
      const {
        LiveInsightType.actionItem,
        LiveInsightType.decision,
        LiveInsightType.question,
        LiveInsightType.risk,
        LiveInsightType.keyPoint,
        LiveInsightType.relatedDiscussion,
        LiveInsightType.contradiction,
        LiveInsightType.missingInfo,
      },
  quietMode: json['quietMode'] as bool? ?? false,
  showCollapsedItems: json['showCollapsedItems'] as bool? ?? true,
  enableFeedback: json['enableFeedback'] as bool? ?? true,
  autoExpandHighConfidence: json['autoExpandHighConfidence'] as bool? ?? true,
);

Map<String, dynamic> _$$LiveInsightsSettingsImplToJson(
  _$LiveInsightsSettingsImpl instance,
) => <String, dynamic>{
  'enabledPhases': instance.enabledPhases
      .map((e) => _$ProactiveAssistanceTypeEnumMap[e]!)
      .toList(),
  'enabledInsightTypes': instance.enabledInsightTypes
      .map((e) => _$LiveInsightTypeEnumMap[e]!)
      .toList(),
  'quietMode': instance.quietMode,
  'showCollapsedItems': instance.showCollapsedItems,
  'enableFeedback': instance.enableFeedback,
  'autoExpandHighConfidence': instance.autoExpandHighConfidence,
};

const _$ProactiveAssistanceTypeEnumMap = {
  ProactiveAssistanceType.autoAnswer: 'auto_answer',
  ProactiveAssistanceType.clarificationNeeded: 'clarification_needed',
  ProactiveAssistanceType.conflictDetected: 'conflict_detected',
  ProactiveAssistanceType.incompleteActionItem: 'incomplete_action_item',
  ProactiveAssistanceType.followUpSuggestion: 'follow_up_suggestion',
  ProactiveAssistanceType.repetitionDetected: 'repetition_detected',
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
