import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pm_master_v2/core/utils/layout_constants.dart';
import 'package:pm_master_v2/core/widgets/dialogs/enhanced_confirmation_dialog.dart';
import 'package:pm_master_v2/features/organizations/data/models/organization_member.dart';
import 'package:pm_master_v2/features/organizations/presentation/providers/members_provider.dart';
import 'package:intl/intl.dart';
import 'package:pm_master_v2/core/services/notification_service.dart';

class PendingInvitationsListWidget extends ConsumerStatefulWidget {
  final String organizationId;
  final bool isAdmin;
  final VoidCallback? onInvitationsCanceled;

  const PendingInvitationsListWidget({
    super.key,
    required this.organizationId,
    required this.isAdmin,
    this.onInvitationsCanceled,
  });

  @override
  ConsumerState<PendingInvitationsListWidget> createState() => _PendingInvitationsListWidgetState();
}

class _PendingInvitationsListWidgetState extends ConsumerState<PendingInvitationsListWidget> {
  final Set<String> _processingEmails = {};
  bool _showNotificationBadge = false;

  List<OrganizationMember> _getPendingInvitations(List<OrganizationMember> members) {
    return members.where((member) => member.status == 'invited').toList()
      ..sort((a, b) => (b.invitedAt ?? DateTime.now()).compareTo(a.invitedAt ?? DateTime.now()));
  }

  Future<void> _resendInvitation(OrganizationMember member) async {
    setState(() {
      _processingEmails.add(member.userEmail);
    });

    try {
      await ref.read(membersProvider(widget.organizationId).notifier)
          .resendInvitation(member.userEmail);

      if (mounted) {
        ref.read(notificationServiceProvider.notifier).showSuccess('Invitation resent to ${member.userEmail}');
      }
    } catch (e) {
      if (mounted) {
        ref.read(notificationServiceProvider.notifier).showError('Failed to resend invitation: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _processingEmails.remove(member.userEmail);
        });
      }
    }
  }

  Future<void> _cancelInvitation(OrganizationMember member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => EnhancedConfirmationDialog(
        title: 'Cancel Invitation',
        message: 'Are you sure you want to cancel the invitation for ${member.userEmail}?',
        confirmText: 'Cancel Invitation',
        severity: ConfirmationSeverity.warning,
        impact: ImpactSummary(
          totalItems: 1,
          affectedItems: [
            'The invitation link will be invalidated',
            'User will not be able to join with this invitation',
            'You can send a new invitation later if needed',
          ],
        ),
      ),
    );

    if (confirmed == true && mounted) {
      setState(() {
        _processingEmails.add(member.userEmail);
      });

      try {
        // Since there's no cancel endpoint in the API service yet, we'll use remove member
        // This should be updated when a proper cancel invitation endpoint is available
        await ref.read(membersProvider(widget.organizationId).notifier)
            .removeMember(member.userId);

        if (mounted) {
          ref.read(notificationServiceProvider.notifier).showInfo('Invitation canceled for ${member.userEmail}');
          widget.onInvitationsCanceled?.call();
        }
      } catch (e) {
        if (mounted) {
          ref.read(notificationServiceProvider.notifier).showError('Failed to cancel invitation: ${e.toString()}');
        }
      } finally {
        if (mounted) {
          setState(() {
            _processingEmails.remove(member.userEmail);
          });
        }
      }
    }
  }

  void _copyInvitationLink(String email) {
    // This would typically generate or retrieve the invitation link
    // For now, we'll copy the email as a placeholder
    Clipboard.setData(ClipboardData(text: email));
    ref.read(notificationServiceProvider.notifier).showInfo('Email copied to clipboard');
  }

  String _formatInvitationDate(DateTime? date) {
    if (date == null) return 'Unknown';
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(date);
    }
  }

  Widget _buildRoleBadge(String role) {
    IconData icon;
    Color color;

    switch (role.toLowerCase()) {
      case 'admin':
        icon = Icons.admin_panel_settings;
        color = Colors.orange;
        break;
      case 'member':
        icon = Icons.person;
        color = Colors.blue;
        break;
      case 'viewer':
        icon = Icons.visibility;
        color = Colors.green;
        break;
      default:
        icon = Icons.person_outline;
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            role.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final membersAsync = ref.watch(membersProvider(widget.organizationId));

    return Material(
      color: Colors.transparent,
      child: membersAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load invitations',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.refresh(membersProvider(widget.organizationId)),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (members) {
        final pendingInvitations = _getPendingInvitations(members);

        if (pendingInvitations.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.mail_outline,
                    size: 64,
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No pending invitations',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'All invitations have been accepted or expired',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        // Check for recently accepted invitations and show notification
        if (_showNotificationBadge) {
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              setState(() {
                _showNotificationBadge = false;
              });
            }
          });
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with count
            Padding(
              padding: const EdgeInsets.all(LayoutConstants.paddingMedium),
              child: Row(
                children: [
                  Icon(
                    Icons.schedule_send,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${pendingInvitations.length} Pending Invitation${pendingInvitations.length == 1 ? '' : 's'}',
                    style: theme.textTheme.titleSmall,
                  ),
                  if (_showNotificationBadge) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'NEW',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Invitations list
            Expanded(
              child: ListView.separated(
                itemCount: pendingInvitations.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final invitation = pendingInvitations[index];
                  final isProcessing = _processingEmails.contains(invitation.userEmail);

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: LayoutConstants.paddingMedium,
                      vertical: LayoutConstants.paddingSmall,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(
                        invitation.userEmail[0].toUpperCase(),
                        style: TextStyle(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      invitation.userEmail,
                      style: theme.textTheme.bodyLarge,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'Invited ${_formatInvitationDate(invitation.invitedAt)}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (invitation.invitedBy != null) ...[
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'by ${invitation.invitedBy}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        _buildRoleBadge(invitation.role),
                      ],
                    ),
                    trailing: widget.isAdmin
                        ? PopupMenuButton<String>(
                            enabled: !isProcessing,
                            icon: isProcessing
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.more_vert),
                            onSelected: (value) {
                              switch (value) {
                                case 'resend':
                                  _resendInvitation(invitation);
                                  break;
                                case 'cancel':
                                  _cancelInvitation(invitation);
                                  break;
                                case 'copy':
                                  _copyInvitationLink(invitation.userEmail);
                                  break;
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'resend',
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.send, size: 20),
                                    SizedBox(width: 12),
                                    Flexible(
                                      child: Text(
                                        'Resend Invitation',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'copy',
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.copy, size: 20),
                                    SizedBox(width: 12),
                                    Flexible(
                                      child: Text(
                                        'Copy Email',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const PopupMenuDivider(),
                              PopupMenuItem(
                                value: 'cancel',
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.cancel, size: 20, color: Colors.red),
                                    const SizedBox(width: 12),
                                    Flexible(
                                      child: Text(
                                        'Cancel Invitation',
                                        style: TextStyle(color: Colors.red),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : null,
                    onTap: widget.isAdmin
                        ? () {
                            // Show invitation details dialog
                            _showInvitationDetailsDialog(invitation);
                          }
                        : null,
                  );
                },
              ),
            ),
          ],
        );
      },
      ),
    );
  }

  void _showInvitationDetailsDialog(OrganizationMember invitation) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Invitation Details',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildDetailRow('Email', invitation.userEmail),
                const SizedBox(height: 12),
                _buildDetailRow('Role', invitation.role.toUpperCase()),
                const SizedBox(height: 12),
                _buildDetailRow(
                  'Invited',
                  invitation.invitedAt != null
                      ? DateFormat('MMM d, yyyy h:mm a').format(invitation.invitedAt!)
                      : 'Unknown',
                ),
                if (invitation.invitedBy != null) ...[
                  const SizedBox(height: 12),
                  _buildDetailRow('Invited By', invitation.invitedBy!),
                ],
                const SizedBox(height: 12),
                _buildDetailRow('Status', 'Pending Acceptance'),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _resendInvitation(invitation);
                      },
                      icon: const Icon(Icons.send),
                      label: const Text('Resend'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}