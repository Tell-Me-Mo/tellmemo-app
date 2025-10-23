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
