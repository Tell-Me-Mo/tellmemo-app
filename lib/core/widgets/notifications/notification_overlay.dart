import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/notification_service.dart';
import '../../models/notification_model.dart';
import 'notification_toast.dart';

class NotificationOverlay extends ConsumerStatefulWidget {
  final Widget child;

  const NotificationOverlay({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<NotificationOverlay> createState() => _NotificationOverlayState();
}

class _NotificationOverlayState extends ConsumerState<NotificationOverlay> {
  final Map<NotificationPosition, List<String>> _positionedNotifications = {};

  @override
  Widget build(BuildContext context) {
    final notificationState = ref.watch(notificationServiceProvider);
    final notificationService = ref.read(notificationServiceProvider.notifier);

    _updatePositionedNotifications(notificationState);

    // Check if we have a Directionality widget in the tree
    final hasDirectionality = Directionality.maybeOf(context) != null;

    Widget stackWidget = Stack(
      // Use non-directional alignment if no Directionality is available
      alignment: hasDirectionality ? AlignmentDirectional.topStart : Alignment.topLeft,
      children: [
        widget.child,
        ..._buildNotificationOverlays(notificationState, notificationService),
      ],
    );

    // If no Directionality is found, provide one
    if (!hasDirectionality) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: stackWidget,
      );
    }

    return stackWidget;
  }

  void _updatePositionedNotifications(NotificationState state) {
    _positionedNotifications.clear();
    for (final notification in state.active.where((n) => n.showAsToast)) {
      _positionedNotifications
          .putIfAbsent(notification.position, () => [])
          .add(notification.id);
    }
  }

  List<Widget> _buildNotificationOverlays(
    NotificationState state,
    NotificationService service,
  ) {
    final overlays = <Widget>[];
    final safeAreaPadding = MediaQuery.of(context).padding;

    for (final position in NotificationPosition.values) {
      final notifications = _positionedNotifications[position] ?? [];
      if (notifications.isEmpty) continue;

      overlays.add(
        Positioned(
          top: _getTop(position, safeAreaPadding),
          bottom: _getBottom(position, safeAreaPadding),
          left: _getLeft(position),
          right: _getRight(position),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: _getCrossAxisAlignment(position),
            children: notifications.map((id) {
              final notification = state.active.firstWhere(
                (n) => n.id == id,
                orElse: () => throw Exception('Notification not found'),
              );
              return NotificationToast(
                key: ValueKey(notification.id),
                notification: notification,
                onDismiss: () => service.dismiss(notification.id),
                animation: const AlwaysStoppedAnimation(1.0),
              );
            }).toList(),
          ),
        ),
      );
    }

    return overlays;
  }

  double? _getTop(NotificationPosition position, EdgeInsets safeAreaPadding) {
    switch (position) {
      case NotificationPosition.top:
      case NotificationPosition.topLeft:
      case NotificationPosition.topRight:
        // Position notifications directly below status bar/safe area with no margin
        return safeAreaPadding.top;
      default:
        return null;
    }
  }

  double? _getBottom(NotificationPosition position, EdgeInsets safeAreaPadding) {
    switch (position) {
      case NotificationPosition.bottom:
      case NotificationPosition.bottomLeft:
      case NotificationPosition.bottomRight:
        return safeAreaPadding.bottom + 16; // Add safe area padding + 16px margin
      default:
        return null;
    }
  }

  double? _getLeft(NotificationPosition position) {
    switch (position) {
      case NotificationPosition.topLeft:
      case NotificationPosition.bottomLeft:
        return 0;
      case NotificationPosition.top:
      case NotificationPosition.bottom:
        return null;
      default:
        return null;
    }
  }

  double? _getRight(NotificationPosition position) {
    switch (position) {
      case NotificationPosition.topRight:
      case NotificationPosition.bottomRight:
        return 0;
      case NotificationPosition.top:
      case NotificationPosition.bottom:
        return null;
      default:
        return null;
    }
  }

  CrossAxisAlignment _getCrossAxisAlignment(NotificationPosition position) {
    switch (position) {
      case NotificationPosition.topLeft:
      case NotificationPosition.bottomLeft:
        return CrossAxisAlignment.start;
      case NotificationPosition.topRight:
      case NotificationPosition.bottomRight:
        return CrossAxisAlignment.end;
      case NotificationPosition.top:
      case NotificationPosition.bottom:
        return CrossAxisAlignment.center;
    }
  }
}