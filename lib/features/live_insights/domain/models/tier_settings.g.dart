// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tier_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TierSettingsImpl _$$TierSettingsImplFromJson(Map<String, dynamic> json) =>
    _$TierSettingsImpl(
      ragEnabled: json['ragEnabled'] as bool? ?? true,
      meetingContextEnabled: json['meetingContextEnabled'] as bool? ?? true,
      liveConversationEnabled: json['liveConversationEnabled'] as bool? ?? true,
      gptGeneratedEnabled: json['gptGeneratedEnabled'] as bool? ?? true,
      showQuestionsSection: json['showQuestionsSection'] as bool? ?? true,
      showActionsSection: json['showActionsSection'] as bool? ?? true,
    );

Map<String, dynamic> _$$TierSettingsImplToJson(_$TierSettingsImpl instance) =>
    <String, dynamic>{
      'ragEnabled': instance.ragEnabled,
      'meetingContextEnabled': instance.meetingContextEnabled,
      'liveConversationEnabled': instance.liveConversationEnabled,
      'gptGeneratedEnabled': instance.gptGeneratedEnabled,
      'showQuestionsSection': instance.showQuestionsSection,
      'showActionsSection': instance.showActionsSection,
    };
