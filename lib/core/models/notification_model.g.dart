// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AppNotificationImpl _$$AppNotificationImplFromJson(
  Map<String, dynamic> json,
) => _$AppNotificationImpl(
  id: json['id'] as String,
  title: json['title'] as String,
  message: json['message'] as String?,
  type: $enumDecode(_$NotificationTypeEnumMap, json['type']),
  priority:
      $enumDecodeNullable(_$NotificationPriorityEnumMap, json['priority']) ??
      NotificationPriority.normal,
  position:
      $enumDecodeNullable(_$NotificationPositionEnumMap, json['position']) ??
      NotificationPosition.topRight,
  durationMs: (json['durationMs'] as num?)?.toInt() ?? 4000,
  persistent: json['persistent'] as bool? ?? false,
  isRead: json['isRead'] as bool? ?? false,
  actionLabel: json['actionLabel'] as String?,
  avatarUrl: json['avatarUrl'] as String?,
  imageUrl: json['imageUrl'] as String?,
  metadata: json['metadata'] as Map<String, dynamic>?,
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  expiresAt: json['expiresAt'] == null
      ? null
      : DateTime.parse(json['expiresAt'] as String),
  showInCenter: json['showInCenter'] as bool? ?? true,
  showAsToast: json['showAsToast'] as bool? ?? true,
);

Map<String, dynamic> _$$AppNotificationImplToJson(
  _$AppNotificationImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'message': instance.message,
  'type': _$NotificationTypeEnumMap[instance.type]!,
  'priority': _$NotificationPriorityEnumMap[instance.priority]!,
  'position': _$NotificationPositionEnumMap[instance.position]!,
  'durationMs': instance.durationMs,
  'persistent': instance.persistent,
  'isRead': instance.isRead,
  'actionLabel': instance.actionLabel,
  'avatarUrl': instance.avatarUrl,
  'imageUrl': instance.imageUrl,
  'metadata': instance.metadata,
  'createdAt': instance.createdAt?.toIso8601String(),
  'expiresAt': instance.expiresAt?.toIso8601String(),
  'showInCenter': instance.showInCenter,
  'showAsToast': instance.showAsToast,
};

const _$NotificationTypeEnumMap = {
  NotificationType.info: 'info',
  NotificationType.success: 'success',
  NotificationType.warning: 'warning',
  NotificationType.error: 'error',
  NotificationType.custom: 'custom',
};

const _$NotificationPriorityEnumMap = {
  NotificationPriority.low: 'low',
  NotificationPriority.normal: 'normal',
  NotificationPriority.high: 'high',
  NotificationPriority.critical: 'critical',
};

const _$NotificationPositionEnumMap = {
  NotificationPosition.top: 'top',
  NotificationPosition.bottom: 'bottom',
  NotificationPosition.topLeft: 'topLeft',
  NotificationPosition.topRight: 'topRight',
  NotificationPosition.bottomLeft: 'bottomLeft',
  NotificationPosition.bottomRight: 'bottomRight',
};
