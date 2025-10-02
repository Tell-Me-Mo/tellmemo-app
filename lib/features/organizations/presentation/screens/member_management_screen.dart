import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pm_master_v2/core/utils/layout_constants.dart';
import 'package:pm_master_v2/core/widgets/dialogs/enhanced_confirmation_dialog.dart';
import 'package:pm_master_v2/features/organizations/data/models/organization_member.dart';
import 'package:pm_master_v2/features/organizations/presentation/providers/organization_provider.dart';
import 'package:pm_master_v2/features/organizations/presentation/providers/members_provider.dart';
import 'package:pm_master_v2/features/organizations/presentation/widgets/invite_members_dialog.dart';
import 'package:pm_master_v2/features/organizations/presentation/widgets/member_role_dialog.dart';

class MemberManagementScreen extends ConsumerStatefulWidget {
  const MemberManagementScreen({super.key});

  @override
  ConsumerState<MemberManagementScreen> createState() => _MemberManagementScreenState();
}

class _MemberManagementScreenState extends ConsumerState<MemberManagementScreen> {
  String _searchQuery = '';
  String _roleFilter = 'all';
  String _statusFilter = 'active';
  final TextEditingController _searchController = TextEditingController();
  Set<String> _selectedMemberIds = {};
  bool _isMultiSelectMode = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<OrganizationMember> _filterMembers(List<OrganizationMember> members) {
    return members.where((member) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesName = member.userName.toLowerCase().contains(query);
        final matchesEmail = member.userEmail.toLowerCase().contains(query);
        if (!matchesName && !matchesEmail) return false;
      }

      // Role filter
      if (_roleFilter != 'all' && member.role != _roleFilter) {
        return false;
      }

      // Status filter
      if (_statusFilter == 'active' && member.status != 'active') {
        return false;
      } else if (_statusFilter == 'invited' && member.status != 'invited') {
        return false;
      }

      return true;
    }).toList();
  }

  Future<void> _removeMember(OrganizationMember member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => EnhancedConfirmationDialog(
        title: 'Remove Member',
        message: 'Are you sure you want to remove ${member.userName} from this organization?\n\nThey will lose access to all organization data immediately.',
        confirmText: 'Remove',
        severity: ConfirmationSeverity.danger,
        impact: ImpactSummary(
          totalItems: 1,
          affectedItems: [
            'Access will be revoked immediately',
            'Their active sessions will be terminated',
            'They can be re-invited later if needed',
          ],
        ),
      ),
    );

    if (confirmed == true && mounted) {
      final organizationId = ref.read(currentOrganizationProvider).value?.id;
      if (organizationId != null) {
        await ref.read(membersProvider(organizationId).notifier).removeMember(member.userId);
      }
    }
  }

  Future<void> _updateMemberRole(OrganizationMember member) async {
    final newRole = await showDialog<String>(
      context: context,
      builder: (context) => MemberRoleDialog(
        member: member,
        currentRole: member.role,
      ),
    );

    if (newRole != null && newRole != member.role && mounted) {
      final organizationId = ref.read(currentOrganizationProvider).value?.id;
      if (organizationId != null) {
        await ref.read(membersProvider(organizationId).notifier)
            .updateMemberRole(member.userId, newRole);
      }
    }
  }

  Future<void> _inviteMembers() async {
    final organizationId = ref.read(currentOrganizationProvider).value?.id;
    if (organizationId == null) return;

    await showDialog(
      context: context,
      builder: (context) => InviteMembersDialog(organizationId: organizationId),
    );
  }

  Future<void> _bulkRemoveMembers() async {
    if (_selectedMemberIds.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => EnhancedConfirmationDialog(
        title: 'Remove ${_selectedMemberIds.length} Members',
        message: 'Are you sure you want to remove the selected members?\n\nThey will lose access to all organization data immediately.',
        confirmText: 'Remove All',
        severity: ConfirmationSeverity.danger,
        requireExplicitConfirmation: true,
        explicitConfirmationText: 'REMOVE',
        impact: ImpactSummary(
          totalItems: _selectedMemberIds.length,
          affectedItems: [
            '${_selectedMemberIds.length} members will be removed',
            'Access will be revoked immediately',
            'Their active sessions will be terminated',
          ],
        ),
      ),
    );

    if (confirmed == true && mounted) {
      final organizationId = ref.read(currentOrganizationProvider).value?.id;
      if (organizationId != null) {
        await ref.read(membersProvider(organizationId).notifier)
            .removeMembersInBatch(_selectedMemberIds.toList());
        setState(() {
          _selectedMemberIds.clear();
          _isMultiSelectMode = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final organization = ref.watch(currentOrganizationProvider);
    final isAdmin = organization.value?.currentUserRole == 'admin';

    if (!organization.hasValue || organization.value == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final membersAsync = ref.watch(membersProvider(organization.value!.id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Organization Members'),
        actions: [
          if (_isMultiSelectMode && _selectedMemberIds.isNotEmpty) ...[
            TextButton.icon(
              onPressed: _bulkRemoveMembers,
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              label: Text(
                'Remove (${_selectedMemberIds.length})',
                style: const TextStyle(color: Colors.red),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedMemberIds.clear();
                  _isMultiSelectMode = false;
                });
              },
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 16),
          ] else if (isAdmin) ...[
            IconButton(
              icon: const Icon(Icons.checklist),
              tooltip: 'Select Multiple',
              onPressed: () {
                setState(() {
                  _isMultiSelectMode = true;
                });
              },
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _inviteMembers,
              icon: const Icon(Icons.person_add),
              label: const Text('Invite Members'),
            ),
            const SizedBox(width: 16),
          ],
        ],
      ),
      body: membersAsync.when(
        data: (members) {
          final filteredMembers = _filterMembers(members);

          return Column(
            children: [
              // Search and Filter Bar
              Container(
                padding: const EdgeInsets.all(LayoutConstants.paddingMedium),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  border: Border(
                    bottom: BorderSide(color: theme.dividerColor),
                  ),
                ),
                child: Row(
                  children: [
                    // Search Field
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search by name or email...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    setState(() {
                                      _searchController.clear();
                                      _searchQuery = '';
                                    });
                                  },
                                )
                              : null,
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: LayoutConstants.paddingMedium),

                    // Role Filter
                    PopupMenuButton<String>(
                      child: Chip(
                        avatar: const Icon(Icons.badge, size: 16),
                        label: Text(_roleFilter == 'all' ? 'All Roles' : _roleFilter),
                        deleteIcon: _roleFilter != 'all'
                            ? const Icon(Icons.clear, size: 16)
                            : null,
                        onDeleted: _roleFilter != 'all'
                            ? () {
                                setState(() {
                                  _roleFilter = 'all';
                                });
                              }
                            : null,
                      ),
                      onSelected: (value) {
                        setState(() {
                          _roleFilter = value;
                        });
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'all',
                          child: Text('All Roles'),
                        ),
                        const PopupMenuItem(
                          value: 'admin',
                          child: Text('Admin'),
                        ),
                        const PopupMenuItem(
                          value: 'member',
                          child: Text('Member'),
                        ),
                        const PopupMenuItem(
                          value: 'viewer',
                          child: Text('Viewer'),
                        ),
                      ],
                    ),
                    const SizedBox(width: LayoutConstants.paddingSmall),

                    // Status Filter
                    PopupMenuButton<String>(
                      child: Chip(
                        avatar: Icon(
                          _statusFilter == 'active'
                              ? Icons.check_circle
                              : Icons.schedule,
                          size: 16,
                        ),
                        label: Text(_statusFilter == 'active' ? 'Active' : 'Invited'),
                      ),
                      onSelected: (value) {
                        setState(() {
                          _statusFilter = value;
                        });
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'active',
                          child: Text('Active Members'),
                        ),
                        const PopupMenuItem(
                          value: 'invited',
                          child: Text('Pending Invitations'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Results Summary
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: LayoutConstants.paddingMedium,
                  vertical: LayoutConstants.paddingSmall,
                ),
                child: Row(
                  children: [
                    Text(
                      '${filteredMembers.length} member${filteredMembers.length == 1 ? '' : 's'}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Last updated: ${DateTime.now().toString().substring(0, 16)}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),

              // Members List
              Expanded(
                child: filteredMembers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.group_off,
                              size: 64,
                              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'No members found matching your search'
                                  : 'No members to display',
                              style: theme.textTheme.titleMedium,
                            ),
                            if (isAdmin && _searchQuery.isEmpty) ...[
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: _inviteMembers,
                                icon: const Icon(Icons.person_add),
                                label: const Text('Invite First Member'),
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: filteredMembers.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final member = filteredMembers[index];
                          final isCurrentUser = member.userId == organization.value!.currentUserId;
                          final isOwner = member.userId == organization.value!.createdBy;

                          return ListTile(
                            leading: _isMultiSelectMode
                                ? Checkbox(
                                    value: _selectedMemberIds.contains(member.userId),
                                    onChanged: isOwner || isCurrentUser
                                        ? null
                                        : (value) {
                                            setState(() {
                                              if (value == true) {
                                                _selectedMemberIds.add(member.userId);
                                              } else {
                                                _selectedMemberIds.remove(member.userId);
                                              }
                                            });
                                          },
                                  )
                                : CircleAvatar(
                                    backgroundImage: member.userAvatarUrl != null
                                        ? NetworkImage(member.userAvatarUrl!)
                                        : null,
                                    child: member.userAvatarUrl == null
                                        ? Text(member.userName.substring(0, 2).toUpperCase())
                                        : null,
                                  ),
                            title: Row(
                              children: [
                                Text(member.userName),
                                if (isCurrentUser) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'You',
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: theme.colorScheme.onPrimaryContainer,
                                      ),
                                    ),
                                  ),
                                ],
                                if (isOwner) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Owner',
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: theme.colorScheme.onPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(member.userEmail),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    _buildRoleBadge(member.role, theme),
                                    const SizedBox(width: 8),
                                    if (member.status == 'invited')
                                      _buildStatusBadge('Pending', theme, Colors.orange)
                                    else if (member.lastActiveAt != null)
                                      Text(
                                        'Active ${_formatLastActive(member.lastActiveAt!)}',
                                        style: theme.textTheme.bodySmall,
                                      ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: isAdmin && !isOwner && !_isMultiSelectMode
                                ? PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert),
                                    onSelected: (value) {
                                      switch (value) {
                                        case 'change_role':
                                          _updateMemberRole(member);
                                          break;
                                        case 'remove':
                                          _removeMember(member);
                                          break;
                                        case 'resend':
                                          ref.read(membersProvider(organization.value!.id).notifier)
                                              .resendInvitation(member.userEmail);
                                          break;
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      if (member.status == 'active')
                                        const PopupMenuItem(
                                          value: 'change_role',
                                          child: ListTile(
                                            leading: Icon(Icons.badge),
                                            title: Text('Change Role'),
                                            contentPadding: EdgeInsets.zero,
                                          ),
                                        ),
                                      if (member.status == 'invited')
                                        const PopupMenuItem(
                                          value: 'resend',
                                          child: ListTile(
                                            leading: Icon(Icons.send),
                                            title: Text('Resend Invitation'),
                                            contentPadding: EdgeInsets.zero,
                                          ),
                                        ),
                                      if (!isCurrentUser)
                                        const PopupMenuItem(
                                          value: 'remove',
                                          child: ListTile(
                                            leading: Icon(Icons.remove_circle_outline, color: Colors.red),
                                            title: Text('Remove', style: TextStyle(color: Colors.red)),
                                            contentPadding: EdgeInsets.zero,
                                          ),
                                        ),
                                    ],
                                  )
                                : null,
                          );
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Failed to load members',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  ref.invalidate(membersProvider(organization.value!.id));
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleBadge(String role, ThemeData theme) {
    Color color;
    IconData icon;

    switch (role.toLowerCase()) {
      case 'admin':
        color = theme.colorScheme.error;
        icon = Icons.admin_panel_settings;
        break;
      case 'member':
        color = theme.colorScheme.primary;
        icon = Icons.person;
        break;
      case 'viewer':
        color = theme.colorScheme.secondary;
        icon = Icons.visibility;
        break;
      default:
        color = theme.colorScheme.tertiary;
        icon = Icons.badge;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            role,
            style: theme.textTheme.labelSmall?.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status, ThemeData theme, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            status,
            style: theme.textTheme.labelSmall?.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  String _formatLastActive(DateTime lastActive) {
    final now = DateTime.now();
    final difference = now.difference(lastActive);

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }
}