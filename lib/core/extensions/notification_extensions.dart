import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/notification_service.dart';
import '../models/notification_model.dart';

extension NotificationContextExtension on BuildContext {
  NotificationService notifications(WidgetRef ref) {
    return ref.read(notificationServiceProvider.notifier);
  }

  void showNotification({
    required String title,
    String? message,
    NotificationType type = NotificationType.info,
    NotificationPriority priority = NotificationPriority.normal,
    String? actionLabel,
    VoidCallback? onAction,
    bool persistent = false,
  }) {
    // This extension is primarily meant for use with WidgetRef
    // For BuildContext usage, use the WidgetRef extension instead
    throw UnimplementedError(
      'Use WidgetRef extension methods instead for notification access',
    );
  }

  void showError(String message, {String? title}) {
    showNotification(
      title: title ?? 'Error',
      message: message,
      type: NotificationType.error,
      priority: NotificationPriority.high,
    );
  }

  void showSuccess(String message, {String? title}) {
    showNotification(
      title: title ?? 'Success',
      message: message,
      type: NotificationType.success,
    );
  }

  void showWarning(String message, {String? title}) {
    showNotification(
      title: title ?? 'Warning',
      message: message,
      type: NotificationType.warning,
    );
  }

  void showInfo(String message, {String? title}) {
    showNotification(
      title: title ?? 'Information',
      message: message,
      type: NotificationType.info,
    );
  }
}

extension NotificationWidgetRefExtension on WidgetRef {
  NotificationService get notifications => read(notificationServiceProvider.notifier);

  void showNotification({
    required String title,
    String? message,
    NotificationType type = NotificationType.info,
    NotificationPriority priority = NotificationPriority.normal,
    String? actionLabel,
    VoidCallback? onAction,
    bool persistent = false,
    int? durationMs,
  }) {
    notifications.show(
      title: title,
      message: message,
      type: type,
      priority: priority,
      actionLabel: actionLabel,
      onAction: onAction,
      persistent: persistent,
      durationMs: durationMs,
    );
  }

  void showError(String message, {String? title, VoidCallback? onAction}) {
    notifications.showError(message, title: title, onAction: onAction);
  }

  void showSuccess(String message, {String? title}) {
    notifications.showSuccess(message, title: title);
  }

  void showWarning(String message, {String? title}) {
    notifications.showWarning(message, title: title);
  }

  void showInfo(String message, {String? title}) {
    notifications.showInfo(message, title: title);
  }

  void dismissNotification(String id) {
    notifications.dismiss(id);
  }

  void clearAllNotifications() {
    notifications.clearAll();
  }

  void markNotificationAsRead(String id) {
    notifications.markAsRead(id);
  }

  void markAllNotificationsAsRead() {
    notifications.markAllAsRead();
  }
}

extension AsyncValueNotificationExtension<T> on AsyncValue<T> {
  void showErrorIfFailed(WidgetRef ref, {String? title}) {
    whenOrNull(
      error: (error, stack) {
        ref.showError(
          error.toString(),
          title: title ?? 'Operation Failed',
        );
      },
    );
  }

  void showSuccessIfData(WidgetRef ref, String message, {String? title}) {
    whenOrNull(
      data: (_) {
        ref.showSuccess(message, title: title);
      },
    );
  }

  void showLoadingNotification(WidgetRef ref, String message) {
    whenOrNull(
      loading: () {
        ref.showInfo(message, title: 'Loading');
      },
    );
  }
}