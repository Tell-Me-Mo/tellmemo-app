// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item_update_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ItemUpdateModelImpl _$$ItemUpdateModelImplFromJson(
  Map<String, dynamic> json,
) => _$ItemUpdateModelImpl(
  id: json['id'] as String,
  itemId: json['item_id'] as String,
  itemType: json['item_type'] as String,
  projectId: json['project_id'] as String,
  content: json['content'] as String,
  authorName: json['author_name'] as String,
  authorEmail: json['author_email'] as String?,
  timestamp: json['timestamp'] as String,
  updateType: json['update_type'] as String,
);

Map<String, dynamic> _$$ItemUpdateModelImplToJson(
  _$ItemUpdateModelImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'item_id': instance.itemId,
  'item_type': instance.itemType,
  'project_id': instance.projectId,
  'content': instance.content,
  'author_name': instance.authorName,
  'author_email': instance.authorEmail,
  'timestamp': instance.timestamp,
  'update_type': instance.updateType,
};
