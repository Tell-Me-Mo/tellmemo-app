import 'dart:async';
import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';
import '../utils/logger.dart';

final notificationServiceProvider = StateNotifierProvider<NotificationService, NotificationState>((ref) {
  return NotificationService();
});

class NotificationState {
  final Queue<AppNotification> queue;
  final List<AppNotification> active;
  final List<AppNotification> history;
  final int unreadCount;
  final bool hasUnread;
  final AppNotification? currentToast;

  NotificationState({
    Queue<AppNotification>? queue,
    this.active = const [],
    this.history = const [],
    this.unreadCount = 0,
    this.currentToast,
  }) : queue = queue ?? Queue<AppNotification>(),
        hasUnread = unreadCount > 0;

  NotificationState copyWith({
    Queue<AppNotification>? queue,
    List<AppNotification>? active,
    List<AppNotification>? history,
    int? unreadCount,
    AppNotification? currentToast,
    bool clearCurrentToast = false,
  }) {
    return NotificationState(
      queue: queue ?? this.queue,
      active: active ?? this.active,
      history: history ?? this.history,
      unreadCount: unreadCount ?? this.unreadCount,
      currentToast: clearCurrentToast ? null : (currentToast ?? this.currentToast),
    );
  }

  List<AppNotification> get allNotifications => [...active, ...history];

  List<AppNotification> get unreadNotifications =>
      allNotifications.where((n) => !n.isRead).toList();

  List<AppNotification> get persistentNotifications =>
      active.where((n) => n.persistent).toList();
}

class NotificationService extends StateNotifier<NotificationState> {
  final Map<String, Timer> _autoDissmissTimers = {};
  static const int _maxHistorySize = 100;
  static const int _maxActiveSize = 5;
  int _idCounter = 0; // Counter to ensure unique IDs

  NotificationService() : super(NotificationState());

  void _processQueue() {
    // Process queue immediately when called, no periodic timer needed
    if (state.queue.isEmpty || state.currentToast != null) return;

    if (state.active.length >= _maxActiveSize) {
      final nonPersistent = state.active.where((n) => !n.persistent).toList();
      if (nonPersistent.isNotEmpty) {
        dismiss(nonPersistent.first.id);
      }
      return;
    }

    final notification = state.queue.removeFirst();
    _showNotification(notification);

    // Process next item in queue if available (recursive call)
    if (state.queue.isNotEmpty) {
      Future.microtask(() => _processQueue());
    }
  }

  void _showNotification(AppNotification notification) {
    final updatedActive = [...state.active, notification];
    final updatedUnread = state.unreadCount + (notification.isRead ? 0 : 1);

    state = state.copyWith(
      active: updatedActive,
      unreadCount: updatedUnread,
      currentToast: notification.showAsToast ? notification : state.currentToast,
    );

    if (!notification.persistent && notification.durationMs > 0) {
      _autoDissmissTimers[notification.id] = Timer(
        Duration(milliseconds: notification.durationMs),
        () => dismiss(notification.id),
      );
    }

    Logger.info('Notification shown: ${notification.title}');
  }

  String show({
    required String title,
    String? message,
    NotificationType type = NotificationType.info,
    NotificationPriority priority = NotificationPriority.normal,
    NotificationPosition position = NotificationPosition.topRight,
    int? durationMs,
    bool persistent = false,
    String? actionLabel,
    VoidCallback? onAction,
    VoidCallback? onDismiss,
    IconData? icon,
    String? avatarUrl,
    String? imageUrl,
    Map<String, dynamic>? metadata,
    bool showInCenter = true,
    bool showAsToast = true,
  }) {
    // Generate unique ID using timestamp + counter to avoid collisions
    final id = '${DateTime.now().millisecondsSinceEpoch}_${_idCounter++}';

    final notification = AppNotification(
      id: id,
      title: title,
      message: message,
      type: type,
      priority: priority,
      position: position,
      durationMs: durationMs ?? _getDefaultDuration(type, priority),
      persistent: persistent,
      actionLabel: actionLabel,
      onAction: onAction,
      onDismiss: onDismiss,
      icon: icon ?? type.getDefaultIcon(),
      avatarUrl: avatarUrl,
      imageUrl: imageUrl,
      metadata: metadata,
      createdAt: DateTime.now(),
      showInCenter: showInCenter,
      showAsToast: showAsToast,
    );

    if (priority == NotificationPriority.critical) {
      _showNotification(notification);
    } else {
      state = state.copyWith(
        queue: Queue<AppNotification>.from([...state.queue, notification]),
      );
      // Trigger queue processing immediately after adding
      Future.microtask(() => _processQueue());
    }

    return id;
  }

  void dismiss(String id, {bool moveToHistory = true}) {
    _autoDissmissTimers[id]?.cancel();
    _autoDissmissTimers.remove(id);

    final notification = state.active.firstWhere(
      (n) => n.id == id,
      orElse: () => throw Exception('Notification not found'),
    );

    final updatedActive = state.active.where((n) => n.id != id).toList();
    final updatedHistory = moveToHistory
        ? _addToHistory(notification)
        : state.history;

    final wasUnread = !notification.isRead;
    final updatedUnread = wasUnread
        ? (state.unreadCount - 1).clamp(0, double.infinity).toInt()
        : state.unreadCount;

    state = state.copyWith(
      active: updatedActive,
      history: updatedHistory,
      unreadCount: updatedUnread,
      clearCurrentToast: state.currentToast?.id == id,
    );

    notification.onDismiss?.call();

    // Process queue after dismissing (might free up space)
    Future.microtask(() => _processQueue());
  }

  List<AppNotification> _addToHistory(AppNotification notification) {
    final updatedHistory = [notification, ...state.history];
    if (updatedHistory.length > _maxHistorySize) {
      updatedHistory.removeRange(_maxHistorySize, updatedHistory.length);
    }
    return updatedHistory;
  }

  void markAsRead(String id) {
    final allNotifications = [...state.active, ...state.history];
    final notification = allNotifications.firstWhere(
      (n) => n.id == id,
      orElse: () => throw Exception('Notification not found'),
    );

    if (notification.isRead) return;

    final updatedNotification = notification.copyWith(isRead: true);

    if (state.active.contains(notification)) {
      state = state.copyWith(
        active: state.active.map((n) => n.id == id ? updatedNotification : n).toList(),
        unreadCount: (state.unreadCount - 1).clamp(0, double.infinity).toInt(),
      );
    } else {
      state = state.copyWith(
        history: state.history.map((n) => n.id == id ? updatedNotification : n).toList(),
        unreadCount: (state.unreadCount - 1).clamp(0, double.infinity).toInt(),
      );
    }
  }

  void markAllAsRead() {
    state = state.copyWith(
      active: state.active.map((n) => n.copyWith(isRead: true)).toList(),
      history: state.history.map((n) => n.copyWith(isRead: true)).toList(),
      unreadCount: 0,
    );
  }

  void clearAll({bool keepPersistent = true}) {
    for (final timer in _autoDissmissTimers.values) {
      timer.cancel();
    }
    _autoDissmissTimers.clear();

    if (keepPersistent) {
      final persistent = state.active.where((n) => n.persistent).toList();
      state = state.copyWith(
        queue: Queue<AppNotification>(),
        active: persistent,
        history: [],
        unreadCount: persistent.where((n) => !n.isRead).length,
        clearCurrentToast: true,
      );
    } else {
      state = NotificationState();
    }
  }

  void clearHistory() {
    state = state.copyWith(history: []);
  }

  void dismissToast() {
    if (state.currentToast != null) {
      state = state.copyWith(clearCurrentToast: true);
    }
  }

  void showError(String message, {String? title, VoidCallback? onAction}) {
    show(
      title: title ?? 'Error',
      message: message,
      type: NotificationType.error,
      priority: NotificationPriority.high,
      onAction: onAction,
    );
  }

  void showSuccess(String message, {String? title}) {
    show(
      title: title ?? 'Success',
      message: message,
      type: NotificationType.success,
    );
  }

  void showWarning(String message, {String? title}) {
    show(
      title: title ?? 'Warning',
      message: message,
      type: NotificationType.warning,
    );
  }

  void showInfo(String message, {String? title}) {
    show(
      title: title ?? 'Info',
      message: message,
      type: NotificationType.info,
    );
  }

  int _getDefaultDuration(NotificationType type, NotificationPriority priority) {
    if (priority == NotificationPriority.critical) return 0;
    if (priority == NotificationPriority.high) return 6000;

    switch (type) {
      case NotificationType.error:
        return 5000;
      case NotificationType.warning:
        return 4000;
      case NotificationType.success:
        return 3000;
      case NotificationType.info:
      case NotificationType.custom:
        return 4000;
    }
  }

  @override
  void dispose() {
    for (final timer in _autoDissmissTimers.values) {
      timer.cancel();
    }
    super.dispose();
  }
}