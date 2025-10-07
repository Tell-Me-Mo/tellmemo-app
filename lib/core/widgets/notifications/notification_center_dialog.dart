import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../services/notification_service.dart';
import '../../models/notification_model.dart';

// Provider for notification filter state (false = all, true = unread only)
final notificationFilterProvider = StateProvider<bool>((ref) => false);

class NotificationCenterDialog extends ConsumerStatefulWidget {
  const NotificationCenterDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (_) => const NotificationCenterDialog(),
    );
  }

  @override
  ConsumerState<NotificationCenterDialog> createState() => _NotificationCenterDialogState();
}

class _NotificationCenterDialogState extends ConsumerState<NotificationCenterDialog> {

  @override
  Widget build(BuildContext context) {
    final notificationState = ref.watch(notificationServiceProvider);
    final notificationService = ref.read(notificationServiceProvider.notifier);
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        color: Colors.transparent,
        child: Center(
          child: GestureDetector(
            onTap: () {}, // Prevent closing when clicking inside
            child: Material(
              color: Colors.transparent,
              child: Container(
                constraints: const BoxConstraints(
                  maxWidth: 480,
                  minWidth: 320,
                  maxHeight: 580,
                  minHeight: 380,
                ),
                width: screenSize.width * 0.35,
                height: screenSize.height * 0.65,
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.notifications,
                              color: theme.colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Notifications',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (notificationState.unreadCount > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${notificationState.unreadCount} new',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Action buttons - more compact
                  LayoutBuilder(
                    builder: (context, constraints) {
                      // Use narrow mode when available width is less than 360px
                      // This accounts for buttons + segmented button + spacing
                      final isNarrow = constraints.maxWidth < 360;
                      return Row(
                        children: [
                          if (notificationState.unreadCount > 0)
                            Flexible(
                              child: isNarrow
                                  ? IconButton(
                                      onPressed: () => notificationService.markAllAsRead(),
                                      icon: const Icon(Icons.done_all, size: 16),
                                      tooltip: 'Mark all read',
                                      padding: const EdgeInsets.all(8),
                                      constraints: const BoxConstraints(),
                                    )
                                  : TextButton.icon(
                                      onPressed: () => notificationService.markAllAsRead(),
                                      icon: const Icon(Icons.done_all, size: 16),
                                      label: const Text('Mark all read', style: TextStyle(fontSize: 12)),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        minimumSize: const Size(0, 32),
                                      ),
                                    ),
                            ),
                          const SizedBox(width: 4),
                          if (notificationState.allNotifications.isNotEmpty)
                            Flexible(
                              child: isNarrow
                                  ? IconButton(
                                      onPressed: () => notificationService.clearAll(),
                                      icon: Icon(
                                        Icons.clear_all,
                                        size: 16,
                                        color: theme.colorScheme.error,
                                      ),
                                      tooltip: 'Clear all',
                                      padding: const EdgeInsets.all(8),
                                      constraints: const BoxConstraints(),
                                    )
                                  : TextButton.icon(
                                      onPressed: () => notificationService.clearAll(),
                                      icon: Icon(
                                        Icons.clear_all,
                                        size: 16,
                                        color: theme.colorScheme.error,
                                      ),
                                      label: Text(
                                        'Clear all',
                                        style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
                                      ),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        minimumSize: const Size(0, 32),
                                      ),
                                    ),
                            ),
                          const Spacer(),
                          // Filter toggle for unread/all notifications
                          SegmentedButton<bool>(
                            segments: [
                              ButtonSegment<bool>(
                                value: false,
                                label: isNarrow ? null : const Text('All', style: TextStyle(fontSize: 12)),
                                icon: const Icon(Icons.inbox, size: 16),
                              ),
                              ButtonSegment<bool>(
                                value: true,
                                label: isNarrow ? null : const Text('Unread', style: TextStyle(fontSize: 12)),
                                icon: const Icon(Icons.markunread, size: 16),
                              ),
                            ],
                            selected: {ref.watch(notificationFilterProvider)},
                            onSelectionChanged: (Set<bool> newSelection) {
                              ref.read(notificationFilterProvider.notifier).state = newSelection.first;
                            },
                            style: ButtonStyle(
                              visualDensity: VisualDensity.compact,
                              padding: WidgetStateProperty.all(
                                EdgeInsets.symmetric(horizontal: isNarrow ? 4 : 8, vertical: 0),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            // Notifications list
            Expanded(
              child: Builder(
                builder: (context) {
                  final showUnreadOnly = ref.watch(notificationFilterProvider);

                  // Filter notifications based on the selected filter
                  final filteredPersistent = showUnreadOnly
                      ? notificationState.persistentNotifications.where((n) => !n.isRead).toList()
                      : notificationState.persistentNotifications;

                  // Get non-persistent active notifications for RECENT section
                  final nonPersistentActive = notificationState.active
                      .where((n) => !n.persistent)
                      .toList();

                  // Combine non-persistent active and history for RECENT section
                  final recentNotifications = [...nonPersistentActive, ...notificationState.history];

                  final filteredRecent = showUnreadOnly
                      ? recentNotifications.where((n) => !n.isRead).toList()
                      : recentNotifications;

                  final hasAnyNotifications = filteredPersistent.isNotEmpty || filteredRecent.isNotEmpty;

                  if (!hasAnyNotifications) {
                    return _buildEmptyState(theme, showUnreadOnly);
                  }

                  return ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (filteredPersistent.isNotEmpty) ...[
                          _buildSectionHeader('IMPORTANT', theme),
                          const SizedBox(height: 8),
                          ...filteredPersistent
                              .map((notification) => _buildNotificationCard(
                                    context,
                                    notification,
                                    notificationService,
                                    theme,
                                  )),
                          const SizedBox(height: 16),
                        ],
                        if (filteredRecent.isNotEmpty) ...[
                          _buildSectionHeader('RECENT', theme),
                          const SizedBox(height: 8),
                          ...filteredRecent
                              .take(20)
                              .map((notification) => _buildNotificationCard(
                                    context,
                                    notification,
                                    notificationService,
                                    theme,
                                  )),
                        ],
                      ],
                    );
                },
              ),
            ),
          ],
        ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, [bool showingUnreadOnly = false]) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            showingUnreadOnly ? 'No unread notifications' : 'No notifications',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            showingUnreadOnly ? 'All notifications have been read' : 'You\'re all caught up!',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Text(
      title,
      style: theme.textTheme.labelMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    AppNotification notification,
    NotificationService service,
    ThemeData theme,
  ) {
    final color = notification.type.getColor(context);

    return Card(
      elevation: notification.isRead ? 0 : 1,
      color: notification.isRead
          ? theme.colorScheme.surfaceContainerHighest
          : theme.colorScheme.surface,
      margin: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: () {
          if (!notification.isRead) {
            service.markAsRead(notification.id);
          }
          if (notification.onAction != null) {
            notification.onAction!();
            Navigator.of(context).pop();
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: notification.isRead
                      ? theme.colorScheme.surfaceContainer
                      : color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  notification.icon ?? notification.type.getDefaultIcon(),
                  size: 18,
                  color: notification.isRead
                      ? theme.colorScheme.onSurfaceVariant
                      : color,
                ),
              ),
              const SizedBox(width: 10),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: notification.isRead
                                  ? FontWeight.normal
                                  : FontWeight.w600,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (notification.persistent)
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'PINNED',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (notification.message != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        notification.message!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatTime(notification.createdAt ?? DateTime.now()),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                          ),
                        ),
                        if (notification.actionLabel != null) ...[
                          const SizedBox(width: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.touch_app,
                                  size: 14,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  notification.actionLabel!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Unread indicator
              if (!notification.isRead)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              // Actions
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                onSelected: (value) {
                  if (value == 'mark_read' && !notification.isRead) {
                    service.markAsRead(notification.id);
                  } else if (value == 'dismiss') {
                    service.dismiss(notification.id);
                  }
                },
                itemBuilder: (context) => [
                  if (!notification.isRead)
                    const PopupMenuItem(
                      value: 'mark_read',
                      child: Row(
                        children: [
                          Icon(Icons.done, size: 18),
                          SizedBox(width: 8),
                          Text('Mark as read'),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'dismiss',
                    child: Row(
                      children: [
                        Icon(Icons.close, size: 18),
                        SizedBox(width: 8),
                        Text('Dismiss'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
        return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
      }
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday at ${DateFormat('HH:mm').format(dateTime)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM d, yyyy').format(dateTime);
    }
  }
}