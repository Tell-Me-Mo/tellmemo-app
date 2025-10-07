import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pm_master_v2/features/organizations/presentation/providers/invitation_notifications_provider.dart';
import 'package:intl/intl.dart';

class InvitationNotificationsWidget extends ConsumerWidget {
  final VoidCallback? onNotificationTapped;

  const InvitationNotificationsWidget({
    super.key,
    this.onNotificationTapped,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationState = ref.watch(invitationNotificationsProvider);
    final theme = Theme.of(context);

    return PopupMenuButton<String>(
      offset: const Offset(0, 40),
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
          if (notificationState.hasUnread)
            Positioned(
              right: -4,
              top: -4,
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
                  minWidth: 8,
                  minHeight: 8,
                ),
              ),
            ),
        ],
      ),
      tooltip: 'Invitation Notifications',
      onSelected: (value) {
        if (value == 'clear_all') {
          ref.read(invitationNotificationsProvider.notifier).clearNotifications();
        } else if (value == 'mark_all_read') {
          ref.read(invitationNotificationsProvider.notifier).markAllAsRead();
        } else {
          // Handle individual notification tap
          ref.read(invitationNotificationsProvider.notifier).markAsRead(value);
          onNotificationTapped?.call();
        }
      },
      itemBuilder: (context) {
        if (notificationState.notifications.isEmpty) {
          return [
            PopupMenuItem<String>(
              enabled: false,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    Icon(
                      Icons.inbox,
                      size: 32,
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No notifications',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ];
        }

        final items = <PopupMenuEntry<String>>[];

        // Header
        items.add(
          PopupMenuItem<String>(
            enabled: false,
            child: Container(
              padding: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: theme.dividerColor),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'Invitation Notifications',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (notificationState.hasUnread)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${notificationState.notifications.where((n) => !n.isRead).length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );

        // Notifications
        for (final notification in notificationState.notifications.take(5)) {
          items.add(
            PopupMenuItem<String>(
              value: notification.id,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: notification.isRead
                          ? theme.colorScheme.surfaceContainerHighest
                          : theme.colorScheme.primaryContainer,
                      child: Icon(
                        Icons.person_add,
                        size: 16,
                        color: notification.isRead
                            ? theme.colorScheme.onSurfaceVariant
                            : theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${notification.userName} accepted',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: notification.isRead
                                  ? FontWeight.normal
                                  : FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            notification.userEmail,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatTime(notification.acceptedAt),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!notification.isRead)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        }

        // Footer actions
        if (notificationState.notifications.isNotEmpty) {
          items.add(const PopupMenuDivider());
          items.add(
            PopupMenuItem<String>(
              value: 'mark_all_read',
              child: Row(
                children: [
                  Icon(
                    Icons.done_all,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Mark all as read',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          );
          items.add(
            PopupMenuItem<String>(
              value: 'clear_all',
              child: Row(
                children: [
                  Icon(
                    Icons.clear_all,
                    size: 18,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Clear all',
                    style: TextStyle(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return items;
      },
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes} min ago';
      }
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM d').format(dateTime);
    }
  }
}