// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$NotificationModelImpl _$$NotificationModelImplFromJson(
  Map<String, dynamic> json,
) => _$NotificationModelImpl(
  id: json['id'] as String,
  organizationId: json['organizationId'] as String?,
  userId: json['userId'] as String,
  title: json['title'] as String,
  message: json['message'] as String?,
  type: json['type'] as String,
  priority: json['priority'] as String,
  category: json['category'] as String,
  entityType: json['entityType'] as String?,
  entityId: json['entityId'] as String?,
  isRead: json['isRead'] as bool? ?? false,
  readAt: json['readAt'] == null
      ? null
      : DateTime.parse(json['readAt'] as String),
  isArchived: json['isArchived'] as bool? ?? false,
  archivedAt: json['archivedAt'] == null
      ? null
      : DateTime.parse(json['archivedAt'] as String),
  actionUrl: json['actionUrl'] as String?,
  actionLabel: json['actionLabel'] as String?,
  metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
  createdAt: DateTime.parse(json['createdAt'] as String),
  expiresAt: json['expiresAt'] == null
      ? null
      : DateTime.parse(json['expiresAt'] as String),
);

Map<String, dynamic> _$$NotificationModelImplToJson(
  _$NotificationModelImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'organizationId': instance.organizationId,
  'userId': instance.userId,
  'title': instance.title,
  'message': instance.message,
  'type': instance.type,
  'priority': instance.priority,
  'category': instance.category,
  'entityType': instance.entityType,
  'entityId': instance.entityId,
  'isRead': instance.isRead,
  'readAt': instance.readAt?.toIso8601String(),
  'isArchived': instance.isArchived,
  'archivedAt': instance.archivedAt?.toIso8601String(),
  'actionUrl': instance.actionUrl,
  'actionLabel': instance.actionLabel,
  'metadata': instance.metadata,
  'createdAt': instance.createdAt.toIso8601String(),
  'expiresAt': instance.expiresAt?.toIso8601String(),
};

_$NotificationListResponseImpl _$$NotificationListResponseImplFromJson(
  Map<String, dynamic> json,
) => _$NotificationListResponseImpl(
  notifications: (json['notifications'] as List<dynamic>)
      .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  total: (json['total'] as num).toInt(),
  unreadCount: (json['unread_count'] as num).toInt(),
);

Map<String, dynamic> _$$NotificationListResponseImplToJson(
  _$NotificationListResponseImpl instance,
) => <String, dynamic>{
  'notifications': instance.notifications,
  'total': instance.total,
  'unread_count': instance.unreadCount,
};
