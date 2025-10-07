import 'package:flutter/material.dart';
import 'package:pm_master_v2/features/organizations/data/models/organization_member.dart';

class MemberRoleDialog extends StatefulWidget {
  final OrganizationMember member;
  final String currentRole;

  const MemberRoleDialog({
    super.key,
    required this.member,
    required this.currentRole,
  });

  @override
  State<MemberRoleDialog> createState() => _MemberRoleDialogState();
}

class _MemberRoleDialogState extends State<MemberRoleDialog> {
  late String _selectedRole;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.currentRole;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Change Member Role'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Member Info
          Row(
            children: [
              CircleAvatar(
                backgroundImage: widget.member.userAvatarUrl != null
                    ? NetworkImage(widget.member.userAvatarUrl!)
                    : null,
                child: widget.member.userAvatarUrl == null
                    ? Text(widget.member.userName.substring(0, 2).toUpperCase())
                    : null,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.member.userName,
                    style: theme.textTheme.titleMedium,
                  ),
                  Text(
                    widget.member.userEmail,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Role Selection
          Text(
            'Select New Role',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 12),

          // Admin Role
          RadioListTile<String>(
            title: const Text('Admin'),
            subtitle: const Text('Full access to all features and settings'),
            value: 'admin',
            groupValue: _selectedRole,
            onChanged: (value) {
              setState(() {
                _selectedRole = value!;
              });
            },
            secondary: Icon(
              Icons.admin_panel_settings,
              color: _selectedRole == 'admin'
                  ? theme.colorScheme.error
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),

          // Member Role
          RadioListTile<String>(
            title: const Text('Member'),
            subtitle: const Text('Can access and modify organization data'),
            value: 'member',
            groupValue: _selectedRole,
            onChanged: (value) {
              setState(() {
                _selectedRole = value!;
              });
            },
            secondary: Icon(
              Icons.person,
              color: _selectedRole == 'member'
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),

          // Viewer Role
          RadioListTile<String>(
            title: const Text('Viewer'),
            subtitle: const Text('Read-only access to organization data'),
            value: 'viewer',
            groupValue: _selectedRole,
            onChanged: (value) {
              setState(() {
                _selectedRole = value!;
              });
            },
            secondary: Icon(
              Icons.visibility,
              color: _selectedRole == 'viewer'
                  ? theme.colorScheme.secondary
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),

          if (_selectedRole != widget.currentRole) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Changing from ${widget.currentRole} to $_selectedRole',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _selectedRole == widget.currentRole
              ? null
              : () => Navigator.of(context).pop(_selectedRole),
          child: const Text('Update Role'),
        ),
      ],
    );
  }
}