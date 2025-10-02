import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_annotation/json_annotation.dart';

part 'notification_model.freezed.dart';
part 'notification_model.g.dart';

enum NotificationType {
  info,
  success,
  warning,
  error,
  custom,
}

enum NotificationPriority {
  low,
  normal,
  high,
  critical,
}

enum NotificationPosition {
  top,
  bottom,
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
}

@freezed
class AppNotification with _$AppNotification {
  const factory AppNotification({
    required String id,
    required String title,
    String? message,
    required NotificationType type,
    @Default(NotificationPriority.normal) NotificationPriority priority,
    @Default(NotificationPosition.topRight) NotificationPosition position,
    @Default(4000) int durationMs,
    @Default(false) bool persistent,
    @Default(false) bool isRead,
    String? actionLabel,
    @JsonKey(includeFromJson: false, includeToJson: false) VoidCallback? onAction,
    @JsonKey(includeFromJson: false, includeToJson: false) VoidCallback? onDismiss,
    @JsonKey(includeFromJson: false, includeToJson: false) IconData? icon,
    String? avatarUrl,
    String? imageUrl,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? expiresAt,
    @Default(true) bool showInCenter,
    @Default(true) bool showAsToast,
  }) = _AppNotification;

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      _$AppNotificationFromJson(json);
}

extension NotificationTypeExtension on NotificationType {
  Color getColor(BuildContext context) {
    final theme = Theme.of(context);
    switch (this) {
      case NotificationType.info:
        return theme.colorScheme.primary;
      case NotificationType.success:
        return Colors.green;
      case NotificationType.warning:
        return Colors.orange;
      case NotificationType.error:
        return theme.colorScheme.error;
      case NotificationType.custom:
        return theme.colorScheme.secondary;
    }
  }

  IconData getDefaultIcon() {
    switch (this) {
      case NotificationType.info:
        return Icons.info_outline;
      case NotificationType.success:
        return Icons.check_circle_outline;
      case NotificationType.warning:
        return Icons.warning_amber_outlined;
      case NotificationType.error:
        return Icons.error_outline;
      case NotificationType.custom:
        return Icons.notifications_outlined;
    }
  }

  String getSoundName() {
    switch (this) {
      case NotificationType.info:
        return 'info';
      case NotificationType.success:
        return 'success';
      case NotificationType.warning:
        return 'warning';
      case NotificationType.error:
        return 'error';
      case NotificationType.custom:
        return 'default';
    }
  }
}

extension NotificationPriorityExtension on NotificationPriority {
  int get value {
    switch (this) {
      case NotificationPriority.low:
        return 0;
      case NotificationPriority.normal:
        return 1;
      case NotificationPriority.high:
        return 2;
      case NotificationPriority.critical:
        return 3;
    }
  }

  bool get shouldPlaySound {
    return this == NotificationPriority.high || this == NotificationPriority.critical;
  }

  bool get shouldVibrate {
    return this == NotificationPriority.critical;
  }
}