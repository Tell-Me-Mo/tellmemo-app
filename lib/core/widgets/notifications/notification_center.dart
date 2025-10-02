import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'notification_center_dialog.dart';
import '../../services/notification_service.dart';

class NotificationCenter extends ConsumerWidget {
  final VoidCallback? onNotificationTapped;

  const NotificationCenter({
    super.key,
    this.onNotificationTapped,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationState = ref.watch(notificationServiceProvider);
    final theme = Theme.of(context);

    return IconButton(
      onPressed: () {
        NotificationCenterDialog.show(context);
        onNotificationTapped?.call();
      },
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            notificationState.hasUnread
                ? Icons.notifications_active
                : Icons.notifications_outlined,
            color: notificationState.hasUnread
                ? theme.colorScheme.primary
                : null,
          ),
          if (notificationState.unreadCount > 0)
            Positioned(
              right: -8,
              top: -8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.surface,
                    width: 2,
                  ),
                ),
                constraints: const BoxConstraints(
                  minWidth: 20,
                  minHeight: 20,
                ),
                child: Center(
                  child: Text(
                    notificationState.unreadCount > 99
                        ? '99+'
                        : notificationState.unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      tooltip: 'Notifications',
    );
  }
}