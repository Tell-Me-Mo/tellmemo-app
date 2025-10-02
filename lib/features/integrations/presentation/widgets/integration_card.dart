import 'package:flutter/material.dart';
import '../../../../core/utils/datetime_utils.dart';
import '../../domain/models/integration.dart';

class IntegrationCard extends StatelessWidget {
  final Integration integration;
  final VoidCallback onTap;

  const IntegrationCard({
    super.key,
    required this.integration,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isConnected = integration.status == IntegrationStatus.connected;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isConnected
              ? Colors.green.withValues(alpha: 0.2)
              : colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with icon and status
                Row(
                  children: [
                    _buildIntegrationIcon(integration.type, colorScheme),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            integration.name,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          _buildStatusBadge(integration.status, colorScheme),
                        ],
                      ),
                    ),
                    if (integration.status == IntegrationStatus.connected)
                      _buildOptionsButton(context, colorScheme),
                  ],
                ),

                // Description
                const SizedBox(height: 12),
                Text(
                  integration.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const Spacer(),

                // Footer with action button
                const SizedBox(height: 12),
                if (isConnected) ...[
                  _buildConnectedFooter(context, colorScheme),
                ] else ...[
                  _buildDisconnectedFooter(context, colorScheme),
                ],
              ],
            ),
          ),
        ),
      );
  }

  Widget _buildIntegrationIcon(IntegrationType type, ColorScheme colorScheme) {
    IconData iconData;
    Color iconColor;
    Color gradientStart;
    Color gradientEnd;

    switch (type) {
      case IntegrationType.fireflies:
        iconData = Icons.mic_rounded;
        iconColor = Colors.orange;
        gradientStart = Colors.orange.shade300;
        gradientEnd = Colors.orange.shade600;
        break;
      case IntegrationType.slack:
        iconData = Icons.chat_bubble_rounded;
        iconColor = Colors.purple;
        gradientStart = Colors.purple.shade300;
        gradientEnd = Colors.purple.shade600;
        break;
      case IntegrationType.teams:
        iconData = Icons.groups_rounded;
        iconColor = Colors.blue;
        gradientStart = Colors.blue.shade300;
        gradientEnd = Colors.blue.shade600;
        break;
      case IntegrationType.zoom:
        iconData = Icons.videocam_rounded;
        iconColor = Colors.blue.shade700;
        gradientStart = Colors.blue.shade400;
        gradientEnd = Colors.blue.shade700;
        break;
      case IntegrationType.transcription:
        iconData = Icons.transcribe;
        iconColor = Colors.teal;
        gradientStart = Colors.teal.shade300;
        gradientEnd = Colors.teal.shade600;
        break;
      case IntegrationType.aiBrain:
        iconData = Icons.psychology;
        iconColor = Colors.deepPurple;
        gradientStart = Colors.deepPurple.shade300;
        gradientEnd = Colors.deepPurple.shade600;
        break;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            gradientStart.withValues(alpha: 0.15),
            gradientEnd.withValues(alpha: 0.25),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: iconColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Icon(
        iconData,
        size: 20,
        color: iconColor,
      ),
    );
  }

  Widget _buildStatusBadge(IntegrationStatus status, ColorScheme colorScheme) {
    Color badgeColor;
    Color textColor;
    Color borderColor;
    String label;
    IconData? icon;

    switch (status) {
      case IntegrationStatus.connected:
        badgeColor = Colors.green.withValues(alpha: 0.1);
        textColor = Colors.green.shade700;
        borderColor = Colors.green.withValues(alpha: 0.3);
        label = 'Connected';
        icon = Icons.check_circle_rounded;
        break;
      case IntegrationStatus.connecting:
        badgeColor = Colors.orange.withValues(alpha: 0.1);
        textColor = Colors.orange.shade700;
        borderColor = Colors.orange.withValues(alpha: 0.3);
        label = 'Connecting';
        icon = Icons.schedule_rounded;
        break;
      case IntegrationStatus.error:
        badgeColor = Colors.red.withValues(alpha: 0.1);
        textColor = Colors.red.shade700;
        borderColor = Colors.red.withValues(alpha: 0.3);
        label = 'Error';
        icon = Icons.error_rounded;
        break;
      case IntegrationStatus.disconnected:
      case IntegrationStatus.notConnected:
        badgeColor = colorScheme.outline.withValues(alpha: 0.05);
        textColor = colorScheme.onSurface.withValues(alpha: 0.5);
        borderColor = colorScheme.outline.withValues(alpha: 0.2);
        label = 'Not Connected';
        icon = Icons.link_off_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: textColor,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsButton(BuildContext context, ColorScheme colorScheme) {
    return IconButton(
      icon: Icon(
        Icons.more_vert_rounded,
        size: 20,
        color: colorScheme.onSurface.withValues(alpha: 0.5),
      ),
      onPressed: () {
        _showOptionsMenu(context);
      },
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(
        minWidth: 32,
        minHeight: 32,
      ),
    );
  }

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.settings_rounded, color: colorScheme.onSurface),
                title: const Text('Configure'),
                onTap: () {
                  Navigator.pop(context);
                  onTap();
                },
              ),
              ListTile(
                leading: Icon(Icons.sync_rounded, color: colorScheme.onSurface),
                title: const Text('Sync Now'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Syncing ${integration.name}...'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.link_off_rounded, color: Colors.red),
                title: const Text('Disconnect'),
                onTap: () {
                  Navigator.pop(context);
                  _showDisconnectDialog(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDisconnectDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Disconnect ${integration.name}?'),
        content: Text(
          'Are you sure you want to disconnect from ${integration.name}? '
          'You can reconnect at any time.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Disconnected from ${integration.name}'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectedFooter(BuildContext context, ColorScheme colorScheme) {
    return Row(
      children: [
        if (integration.lastSyncAt != null) ...[
          Icon(
            Icons.sync_rounded,
            size: 14,
            color: colorScheme.onSurface.withValues(alpha: 0.4),
          ),
          const SizedBox(width: 6),
          Text(
            'Synced ${DateTimeUtils.formatTimeAgo(integration.lastSyncAt!)}',
            style: TextStyle(
              fontSize: 11,
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
        const Spacer(),
        OutlinedButton.icon(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            minimumSize: const Size(0, 32),
            side: BorderSide(
              color: colorScheme.outline.withValues(alpha: 0.3),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          icon: Icon(Icons.settings_rounded, size: 14, color: colorScheme.onSurface.withValues(alpha: 0.7)),
          label: Text(
            'Configure',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colorScheme.onSurface.withValues(alpha: 0.7)),
          ),
        ),
      ],
    );
  }

  Widget _buildDisconnectedFooter(BuildContext context, ColorScheme colorScheme) {
    return Row(
      children: [
        // Optional: Add some info text or leave empty for cleaner look
        Text(
          'Not connected',
          style: TextStyle(
            fontSize: 11,
            color: colorScheme.onSurface.withValues(alpha: 0.4),
          ),
        ),
        const Spacer(),
        // Compact connect button with icon
        FilledButton.icon(
          onPressed: onTap,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            minimumSize: const Size(0, 32),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            elevation: 0,
          ),
          icon: const Icon(Icons.add_link_rounded, size: 14),
          label: const Text(
            'Connect',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}