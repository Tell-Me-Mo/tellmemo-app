import 'package:flutter/material.dart';
import '../../models/notification_model.dart';

class NotificationToast extends StatefulWidget {
  final AppNotification notification;
  final VoidCallback onDismiss;
  final Animation<double> animation;

  const NotificationToast({
    super.key,
    required this.notification,
    required this.onDismiss,
    required this.animation,
  });

  @override
  State<NotificationToast> createState() => _NotificationToastState();
}

class _NotificationToastState extends State<NotificationToast>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: _getStartOffset(),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));

    _controller.forward();
  }

  Offset _getStartOffset() {
    switch (widget.notification.position) {
      case NotificationPosition.top:
      case NotificationPosition.topLeft:
      case NotificationPosition.topRight:
        return const Offset(0, -1);
      case NotificationPosition.bottom:
      case NotificationPosition.bottomLeft:
      case NotificationPosition.bottomRight:
        return const Offset(0, 1);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDismiss() {
    _controller.reverse().then((_) {
      widget.onDismiss();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = widget.notification.type.getColor(context);

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          margin: const EdgeInsets.all(16),
          constraints: const BoxConstraints(
            minWidth: 300,
            maxWidth: 400,
          ),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            color: isDark ? theme.colorScheme.surface : Colors.white,
            child: InkWell(
              onTap: widget.notification.onAction,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: color.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Stack(
                  children: [
                    Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (widget.notification.avatarUrl != null) ...[
                                CircleAvatar(
                                  radius: 20,
                                  backgroundImage: NetworkImage(
                                    widget.notification.avatarUrl!,
                                  ),
                                ),
                                const SizedBox(width: 12),
                              ] else if (widget.notification.icon != null) ...[
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    widget.notification.icon,
                                    color: color,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                              ],
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.notification.title,
                                      style: theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (widget.notification.message != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        widget.notification.message!,
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: _handleDismiss,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ],
                          ),
                          if (widget.notification.imageUrl != null) ...[
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                widget.notification.imageUrl!,
                                height: 120,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ],
                          if (widget.notification.actionLabel != null) ...[
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    widget.notification.onAction?.call();
                                    _handleDismiss();
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor: color,
                                  ),
                                  child: Text(widget.notification.actionLabel!),
                                ),
                              ],
                            ),
                          ],
                        ],
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
}