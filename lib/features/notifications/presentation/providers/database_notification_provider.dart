import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/notification_model.dart' as core;
import '../../../../core/services/notification_service.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/models/notification_model.dart';
import '../../data/repositories/notification_repository.dart';
import '../../services/websocket_notification_service.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository();
});

final databaseNotificationProvider = StateNotifierProvider<DatabaseNotificationNotifier, DatabaseNotificationState>((ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  final localService = ref.watch(notificationServiceProvider.notifier);
  final webSocketService = ref.watch(webSocketNotificationServiceProvider);
  return DatabaseNotificationNotifier(repository, localService, webSocketService, ref);
});

class DatabaseNotificationState {
  final List<NotificationModel> notifications;
  final int unreadCount;
  final bool isLoading;
  final String? error;
  final bool hasMore;

  DatabaseNotificationState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.isLoading = false,
    this.error,
    this.hasMore = true,
  });

  DatabaseNotificationState copyWith({
    List<NotificationModel>? notifications,
    int? unreadCount,
    bool? isLoading,
    String? error,
    bool? hasMore,
  }) {
    return DatabaseNotificationState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class DatabaseNotificationNotifier extends StateNotifier<DatabaseNotificationState> {
  final NotificationRepository _repository;
  final NotificationService _localService;
  final WebSocketNotificationService _webSocketService;
  final Ref _ref;
  Timer? _pollingTimer;
  Timer? _syncTimer;
  StreamSubscription<WebSocketMessage>? _webSocketSubscription;

  static const int _pageSize = 50;
  int _currentOffset = 0;

  DatabaseNotificationNotifier(
    this._repository,
    this._localService,
    this._webSocketService,
    this._ref,
  ) : super(DatabaseNotificationState()) {
    _initialize();
  }

  void _initialize() {
    // Load initial notifications
    loadNotifications();

    // Connect to WebSocket for real-time updates
    _connectWebSocket();

    // Fallback polling every 60 seconds (reduced frequency due to WebSocket)
    _pollingTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (!_webSocketService.isConnected) {
        refreshNotifications();
      }
    });

    // Sync local notifications to database every 5 seconds
    _syncTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _syncLocalToDatabase();
    });
  }

  void _connectWebSocket() {
    _webSocketService.connect().then((_) {
      // Listen to WebSocket messages
      _webSocketSubscription = _webSocketService.messages.listen(_handleWebSocketMessage);
    }).catchError((error) {
      debugPrint('Failed to connect WebSocket: $error');
    });
  }

  void _handleWebSocketMessage(WebSocketMessage message) {
    if (message.isNotification) {
      // Handle new notification
      final notification = message.notification;
      if (notification != null) {
        _handleNewNotification(notification);
      }
    } else if (message.isUnreadCount) {
      // Update unread count
      final count = message.unreadCount;
      if (count != null) {
        state = state.copyWith(unreadCount: count);
      }
    } else if (message.isNotificationRead) {
      // Update notification read status
      final notificationId = message.notificationId;
      if (notificationId != null) {
        _updateNotificationReadStatus(notificationId, true);
      }
    } else if (message.isNotificationArchived) {
      // Remove archived notification
      final notificationId = message.notificationId;
      if (notificationId != null) {
        _removeNotification(notificationId);
      }
    } else if (message.isError) {
      debugPrint('WebSocket error: ${message.errorMessage}');
    }
  }

  void _handleNewNotification(NotificationModel notification) {
    // Add to the beginning of the list
    final notifications = [notification, ...state.notifications];

    // Update state
    state = state.copyWith(
      notifications: notifications,
      unreadCount: state.unreadCount + (notification.isRead ? 0 : 1),
    );

    // Show as toast
    _showAsToast(notification);
  }

  void _updateNotificationReadStatus(String notificationId, bool isRead) {
    final notifications = state.notifications.map((n) {
      if (n.id == notificationId) {
        return n.copyWith(isRead: isRead, readAt: isRead ? DateTime.now() : null);
      }
      return n;
    }).toList();

    final oldNotification = state.notifications.firstWhere(
      (n) => n.id == notificationId,
      orElse: () => state.notifications.first,
    );

    if (oldNotification.isRead != isRead) {
      state = state.copyWith(
        notifications: notifications,
        unreadCount: (state.unreadCount + (isRead ? -1 : 1)).clamp(0, double.infinity).toInt(),
      );
    }
  }

  void _removeNotification(String notificationId) {
    final notifications = state.notifications
        .where((n) => n.id != notificationId)
        .toList();

    final wasUnread = state.notifications
        .firstWhere(
          (n) => n.id == notificationId,
          orElse: () => state.notifications.first,
        )
        .isRead == false;

    state = state.copyWith(
      notifications: notifications,
      unreadCount: wasUnread
          ? (state.unreadCount - 1).clamp(0, double.infinity).toInt()
          : state.unreadCount,
    );
  }

  void _showAsToast(NotificationModel notification) {
    _localService.show(
      title: notification.title,
      message: notification.message,
      type: _mapNotificationType(notification.type),
      priority: _mapNotificationPriority(notification.priority),
      persistent: notification.priority == 'high' || notification.priority == 'critical',
      actionLabel: notification.actionLabel,
      onAction: notification.actionUrl != null
          ? () => _handleNotificationAction(notification)
          : null,
      showAsToast: true,
      showInCenter: true,
    );
  }

  Future<void> loadNotifications({bool refresh = false}) async {
    if (state.isLoading) return;

    if (refresh) {
      _currentOffset = 0;
      state = state.copyWith(notifications: [], hasMore: true);
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _repository.getNotifications(
        limit: _pageSize,
        offset: _currentOffset,
      );

      final updatedNotifications = refresh
          ? response.notifications
          : [...state.notifications, ...response.notifications];

      _currentOffset += response.notifications.length;

      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: response.unreadCount,
        hasMore: response.notifications.length == _pageSize,
        isLoading: false,
      );

      // Sync to local notification service for display
      _syncToLocalService(response.notifications);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> refreshNotifications() async {
    try {
      final response = await _repository.getNotifications(
        limit: _pageSize,
        offset: 0,
      );

      // Only update if there are new notifications
      if (response.notifications.isNotEmpty &&
          (state.notifications.isEmpty ||
              response.notifications.first.id != state.notifications.first.id)) {
        _currentOffset = response.notifications.length;

        state = state.copyWith(
          notifications: response.notifications,
          unreadCount: response.unreadCount,
          hasMore: response.notifications.length == _pageSize,
        );

        // Show toast for new notifications
        _showNewNotifications(response.notifications);
      }

      // Always update unread count
      state = state.copyWith(unreadCount: response.unreadCount);
    } catch (_) {
      // Silently fail for background refresh
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      // Update local state optimistically
      final notifications = state.notifications.map((n) {
        if (n.id == notificationId) {
          return n.copyWith(isRead: true, readAt: DateTime.now());
        }
        return n;
      }).toList();

      state = state.copyWith(
        notifications: notifications,
        unreadCount: (state.unreadCount - 1).clamp(0, double.infinity).toInt(),
      );

      // Send via WebSocket if connected
      if (_webSocketService.isConnected) {
        await _webSocketService.markAsRead(notificationId);
      } else {
        // Fallback to direct API call
        await _repository.markAsRead(notificationId);
      }

      // Mark in local service
      _localService.markAsRead(notificationId);
    } catch (e) {
      // Revert on error
      await refreshNotifications();
      throw e;
    }
  }

  Future<void> markAllAsRead() async {
    try {
      // Update local state optimistically
      final notifications = state.notifications.map((n) {
        return n.copyWith(isRead: true, readAt: DateTime.now());
      }).toList();

      state = state.copyWith(
        notifications: notifications,
        unreadCount: 0,
      );

      // Send via WebSocket if connected
      if (_webSocketService.isConnected) {
        await _webSocketService.markAllAsRead();
      } else {
        // Fallback to direct API call
        await _repository.markMultipleAsRead(markAll: true);
      }

      // Mark in local service
      _localService.markAllAsRead();
    } catch (e) {
      // Revert on error
      await refreshNotifications();
      throw e;
    }
  }

  Future<void> archiveNotification(String notificationId) async {
    try {
      // Remove from local state
      final notifications = state.notifications
          .where((n) => n.id != notificationId)
          .toList();

      final wasUnread = state.notifications
          .firstWhere((n) => n.id == notificationId)
          .isRead == false;

      state = state.copyWith(
        notifications: notifications,
        unreadCount: wasUnread
            ? (state.unreadCount - 1).clamp(0, double.infinity).toInt()
            : state.unreadCount,
      );

      // Archive in database
      await _repository.archiveNotification(notificationId);

      // Dismiss in local service
      _localService.dismiss(notificationId);
    } catch (e) {
      // Revert on error
      await refreshNotifications();
      throw e;
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      // Remove from local state
      final notifications = state.notifications
          .where((n) => n.id != notificationId)
          .toList();

      final wasUnread = state.notifications
          .firstWhere((n) => n.id == notificationId)
          .isRead == false;

      state = state.copyWith(
        notifications: notifications,
        unreadCount: wasUnread
            ? (state.unreadCount - 1).clamp(0, double.infinity).toInt()
            : state.unreadCount,
      );

      // Delete from database
      await _repository.deleteNotification(notificationId);

      // Dismiss in local service
      _localService.dismiss(notificationId);
    } catch (e) {
      // Revert on error
      await refreshNotifications();
      throw e;
    }
  }

  void _syncToLocalService(List<NotificationModel> notifications) {
    // Add recent unread notifications to local service for toasts
    final recentUnread = notifications
        .where((n) => !n.isRead)
        .take(5)
        .toList();

    for (final notification in recentUnread) {
      _localService.show(
        title: notification.title,
        message: notification.message,
        type: _mapNotificationType(notification.type),
        priority: _mapNotificationPriority(notification.priority),
        persistent: notification.priority == 'high' || notification.priority == 'critical',
        actionLabel: notification.actionLabel,
        onAction: notification.actionUrl != null
            ? () => _handleNotificationAction(notification)
            : null,
        showAsToast: false,  // Don't show old notifications as toasts
        showInCenter: true,
      );
    }
  }

  void _showNewNotifications(List<NotificationModel> notifications) {
    // Only show toast for the first new unread notification
    final newUnread = notifications
        .where((n) => !n.isRead)
        .where((n) => !state.notifications.any((existing) => existing.id == n.id))
        .take(1);

    for (final notification in newUnread) {
      _localService.show(
        title: notification.title,
        message: notification.message,
        type: _mapNotificationType(notification.type),
        priority: _mapNotificationPriority(notification.priority),
        persistent: false,
        actionLabel: notification.actionLabel,
        onAction: notification.actionUrl != null
            ? () => _handleNotificationAction(notification)
            : null,
        showAsToast: true,
        showInCenter: true,
      );
    }
  }

  void _syncLocalToDatabase() {
    // This would sync local notifications to database
    // For now, we're only syncing from database to local
  }

  void _handleNotificationAction(NotificationModel notification) {
    // Mark as read
    markAsRead(notification.id);

    // Navigate based on entity type and action URL
    if (notification.actionUrl != null) {
      // TODO: Implement navigation
      // _ref.read(routerProvider).push(notification.actionUrl!);
    }
  }

  core.NotificationType _mapNotificationType(String type) {
    switch (type) {
      case 'success':
        return core.NotificationType.success;
      case 'warning':
        return core.NotificationType.warning;
      case 'error':
        return core.NotificationType.error;
      case 'system':
      case 'custom':
        return core.NotificationType.custom;
      default:
        return core.NotificationType.info;
    }
  }

  core.NotificationPriority _mapNotificationPriority(String priority) {
    switch (priority) {
      case 'low':
        return core.NotificationPriority.low;
      case 'high':
        return core.NotificationPriority.high;
      case 'critical':
        return core.NotificationPriority.critical;
      default:
        return core.NotificationPriority.normal;
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _syncTimer?.cancel();
    _webSocketSubscription?.cancel();
    _webSocketService.disconnect();
    super.dispose();
  }
}