// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activity_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ActivityModelImpl _$$ActivityModelImplFromJson(Map<String, dynamic> json) =>
    _$ActivityModelImpl(
      id: json['id'] as String,
      projectId: json['project_id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      metadata: json['metadata'] as String?,
      timestamp: const UtcDateTimeConverter().fromJson(
        json['timestamp'] as String,
      ),
      userId: json['user_id'] as String?,
      userName: json['user_name'] as String?,
    );

Map<String, dynamic> _$$ActivityModelImplToJson(_$ActivityModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'project_id': instance.projectId,
      'type': instance.type,
      'title': instance.title,
      'description': instance.description,
      'metadata': instance.metadata,
      'timestamp': const UtcDateTimeConverter().toJson(instance.timestamp),
      'user_id': instance.userId,
      'user_name': instance.userName,
    };
