// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'integration.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$IntegrationImpl _$$IntegrationImplFromJson(Map<String, dynamic> json) =>
    _$IntegrationImpl(
      id: json['id'] as String,
      type: $enumDecode(_$IntegrationTypeEnumMap, json['type']),
      name: json['name'] as String,
      description: json['description'] as String,
      iconUrl: json['iconUrl'] as String,
      status: $enumDecode(_$IntegrationStatusEnumMap, json['status']),
      configuration: json['configuration'] as Map<String, dynamic>?,
      connectedAt: json['connectedAt'] == null
          ? null
          : DateTime.parse(json['connectedAt'] as String),
      lastSyncAt: json['lastSyncAt'] == null
          ? null
          : DateTime.parse(json['lastSyncAt'] as String),
      errorMessage: json['errorMessage'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$$IntegrationImplToJson(_$IntegrationImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$IntegrationTypeEnumMap[instance.type]!,
      'name': instance.name,
      'description': instance.description,
      'iconUrl': instance.iconUrl,
      'status': _$IntegrationStatusEnumMap[instance.status]!,
      'configuration': instance.configuration,
      'connectedAt': instance.connectedAt?.toIso8601String(),
      'lastSyncAt': instance.lastSyncAt?.toIso8601String(),
      'errorMessage': instance.errorMessage,
      'metadata': instance.metadata,
    };

const _$IntegrationTypeEnumMap = {
  IntegrationType.aiBrain: 'aiBrain',
  IntegrationType.fireflies: 'fireflies',
  IntegrationType.slack: 'slack',
  IntegrationType.teams: 'teams',
  IntegrationType.zoom: 'zoom',
  IntegrationType.transcription: 'transcription',
};

const _$IntegrationStatusEnumMap = {
  IntegrationStatus.notConnected: 'notConnected',
  IntegrationStatus.connecting: 'connecting',
  IntegrationStatus.connected: 'connected',
  IntegrationStatus.error: 'error',
  IntegrationStatus.disconnected: 'disconnected',
};

_$IntegrationConfigImpl _$$IntegrationConfigImplFromJson(
  Map<String, dynamic> json,
) => _$IntegrationConfigImpl(
  integrationId: json['integrationId'] as String,
  type: $enumDecode(_$IntegrationTypeEnumMap, json['type']),
  apiKey: json['apiKey'] as String?,
  apiSecret: json['apiSecret'] as String?,
  webhookUrl: json['webhookUrl'] as String?,
  webhookSecret: json['webhookSecret'] as String?,
  customSettings: (json['customSettings'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(k, e as String),
  ),
  autoSync: json['autoSync'] as bool?,
  syncIntervalMinutes: (json['syncIntervalMinutes'] as num?)?.toInt(),
  allowedProjects: (json['allowedProjects'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$$IntegrationConfigImplToJson(
  _$IntegrationConfigImpl instance,
) => <String, dynamic>{
  'integrationId': instance.integrationId,
  'type': _$IntegrationTypeEnumMap[instance.type]!,
  'apiKey': instance.apiKey,
  'apiSecret': instance.apiSecret,
  'webhookUrl': instance.webhookUrl,
  'webhookSecret': instance.webhookSecret,
  'customSettings': instance.customSettings,
  'autoSync': instance.autoSync,
  'syncIntervalMinutes': instance.syncIntervalMinutes,
  'allowedProjects': instance.allowedProjects,
};

_$FirefliesDataImpl _$$FirefliesDataImplFromJson(Map<String, dynamic> json) =>
    _$FirefliesDataImpl(
      transcriptId: json['transcriptId'] as String,
      title: json['title'] as String,
      transcript: json['transcript'] as String,
      meetingDate: DateTime.parse(json['meetingDate'] as String),
      duration: (json['duration'] as num).toInt(),
      participants: (json['participants'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      meetingUrl: json['meetingUrl'] as String?,
      recordingUrl: json['recordingUrl'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$$FirefliesDataImplToJson(_$FirefliesDataImpl instance) =>
    <String, dynamic>{
      'transcriptId': instance.transcriptId,
      'title': instance.title,
      'transcript': instance.transcript,
      'meetingDate': instance.meetingDate.toIso8601String(),
      'duration': instance.duration,
      'participants': instance.participants,
      'meetingUrl': instance.meetingUrl,
      'recordingUrl': instance.recordingUrl,
      'metadata': instance.metadata,
    };
