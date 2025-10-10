import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pm_master_v2/features/organizations/data/services/organization_api_service.dart';
import 'package:pm_master_v2/features/organizations/presentation/providers/organization_provider.dart';
import 'package:pm_master_v2/features/organizations/presentation/widgets/csv_bulk_invite_dialog.dart';
import 'package:pm_master_v2/core/services/notification_service.dart';

class InviteMembersDialog extends ConsumerStatefulWidget {
  final String organizationId;

  const InviteMembersDialog({
    super.key,
    required this.organizationId,
  });

  @override
  ConsumerState<InviteMembersDialog> createState() => _InviteMembersDialogState();
}

class _InviteMembersDialogState extends ConsumerState<InviteMembersDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _bulkEmailsController = TextEditingController();
  String _selectedRole = 'member';
  bool _isBulkMode = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _bulkEmailsController.dispose();
    super.dispose();
  }

  Future<void> _sendInvitations() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = ref.read(organizationApiServiceProvider);

      final emails = _isBulkMode
          ? _bulkEmailsController.text.split('\n')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList()
          : [_emailController.text.trim()];

      for (final email in emails) {
        await apiService.inviteToOrganization(
          widget.organizationId,
          {
            'email': email,
            'role': _selectedRole,
          },
        );
      }

      if (mounted) {
        ref.read(notificationServiceProvider.notifier).showSuccess(
          emails.length == 1
              ? 'Invitation sent successfully'
              : '${emails.length} invitations sent successfully',
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ref.read(notificationServiceProvider.notifier).showError('Failed to send invitations: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Icon(
                      Icons.person_add,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Invite Team Members',
                        style: theme.textTheme.headlineSmall,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Mode Toggle
                Row(
                  children: [
                    Flexible(
                      child: ChoiceChip(
                        label: const Text('Single Invite'),
                        selected: !_isBulkMode,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _isBulkMode = false;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: ChoiceChip(
                        label: const Text('Bulk Invite'),
                        selected: _isBulkMode,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _isBulkMode = true;
                            });
                          }
                        },
                      ),
                    ),
                    const Spacer(),
                    Flexible(
                      child: TextButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          showDialog(
                            context: context,
                            builder: (context) => CsvBulkInviteDialog(
                              organizationId: widget.organizationId,
                            ),
                          );
                        },
                        icon: const Icon(Icons.upload_file, size: 18),
                        label: const Text('CSV Import'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Scrollable content
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Email Input
                        if (!_isBulkMode) ...[
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email Address',
                      hintText: 'colleague@company.com',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an email address';
                      }
                      final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                      if (!emailRegex.hasMatch(value)) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                  ),
                ] else ...[
                  TextFormField(
                    controller: _bulkEmailsController,
                    decoration: const InputDecoration(
                      labelText: 'Email Addresses (one per line)',
                      hintText: 'user1@company.com\nuser2@company.com\nuser3@company.com',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    keyboardType: TextInputType.multiline,
                    maxLines: 5,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter at least one email address';
                      }
                      final emails = value.split('\n')
                          .map((e) => e.trim())
                          .where((e) => e.isNotEmpty)
                          .toList();
                      if (emails.isEmpty) {
                        return 'Please enter at least one valid email address';
                      }
                      final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                      for (final email in emails) {
                        if (!emailRegex.hasMatch(email)) {
                          return 'Invalid email: $email';
                        }
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 16),

                // Role Selection
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Role',
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'admin',
                          label: Text('Admin'),
                          icon: Icon(Icons.admin_panel_settings),
                        ),
                        ButtonSegment(
                          value: 'member',
                          label: Text('Member'),
                          icon: Icon(Icons.person),
                        ),
                        ButtonSegment(
                          value: 'viewer',
                          label: Text('Viewer'),
                          icon: Icon(Icons.visibility),
                        ),
                      ],
                      selected: {_selectedRole},
                      onSelectionChanged: (Set<String> newSelection) {
                        setState(() {
                          _selectedRole = newSelection.first;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getRoleDescription(_selectedRole),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _sendInvitations,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send),
                      label: Text(
                        _isLoading
                            ? 'Sending...'
                            : _isBulkMode
                                ? 'Send Invitations'
                                : 'Send Invitation',
                      ),
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

  String _getRoleDescription(String role) {
    switch (role) {
      case 'admin':
        return 'Full access to all features, settings, and user management';
      case 'member':
        return 'Can access and modify organization data, use integrations';
      case 'viewer':
        return 'Read-only access to organization data';
      default:
        return '';
    }
  }
}