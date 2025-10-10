import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/organization_provider.dart';
import '../providers/organization_settings_provider.dart';
import '../../domain/entities/organization.dart';
import '../../../projects/presentation/providers/projects_provider.dart';
import '../../../documents/presentation/providers/documents_provider.dart';
import '../../../../core/services/notification_service.dart';

class OrganizationSettingsDialog extends ConsumerStatefulWidget {
  const OrganizationSettingsDialog({super.key});

  @override
  ConsumerState<OrganizationSettingsDialog> createState() => _OrganizationSettingsDialogState();
}

class _OrganizationSettingsDialogState extends ConsumerState<OrganizationSettingsDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  String _selectedView = 'general';
  String? _selectedDataRetentionDays = '90';
  bool _emailNotifications = true;
  bool _weeklyReports = false;
  bool _hasChanges = false;
  bool _isSaving = false;

  final List<Map<String, String>> _dataRetentionOptions = [
    {'value': '30', 'label': '30 days'},
    {'value': '60', 'label': '60 days'},
    {'value': '90', 'label': '90 days'},
    {'value': '180', 'label': '180 days'},
    {'value': '365', 'label': '1 year'},
    {'value': 'indefinite', 'label': 'Indefinite'},
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _nameController.addListener(_markChanged);
    _descriptionController.addListener(_markChanged);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _initializeFromOrganization(Organization organization) {
    _nameController.text = organization.name;
    _descriptionController.text = organization.description ?? '';

    final settings = organization.settings;
    _selectedDataRetentionDays = settings['data_retention_days']?.toString() ?? '90';
    _emailNotifications = settings['email_notifications'] ?? true;
    _weeklyReports = settings['weekly_reports'] ?? false;
  }

  void _markChanged() {
    if (!_hasChanges && mounted) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final organization = ref.read(currentOrganizationProvider).value;
    if (organization == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final updateRequest = {
        'name': _nameController.text,
        'description': _descriptionController.text.isEmpty ? null : _descriptionController.text,
        'settings': {
          'data_retention_days': _selectedDataRetentionDays == 'indefinite'
              ? null
              : int.tryParse(_selectedDataRetentionDays!),
          'email_notifications': _emailNotifications,
          'weekly_reports': _weeklyReports,
        },
      };

      await ref.read(updateOrganizationSettingsProvider(
        organizationId: organization.id,
        settings: updateRequest,
      ).future);

      if (mounted) {
        ref.read(notificationServiceProvider.notifier).showSuccess('Settings updated');
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ref.read(notificationServiceProvider.notifier).showError('Failed to save: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Organization'),
        content: const Text(
          'Are you sure you want to delete this organization? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final organization = ref.read(currentOrganizationProvider).value;
      if (organization == null) return;

      await ref.read(deleteOrganizationProvider(organization.id).future);

      if (mounted) {
        Navigator.of(context).pop();
        context.go('/dashboard');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final organizationAsync = ref.watch(currentOrganizationProvider);
    final screenSize = MediaQuery.of(context).size;
    final isDesktop = screenSize.width > 1200;
    final isMobile = screenSize.width <= 768;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: isMobile ? EdgeInsets.zero : const EdgeInsets.all(40),
      child: Container(
        width: isMobile ? screenSize.width : (isDesktop ? 720 : screenSize.width * 0.9),
        height: isMobile ? screenSize.height : screenSize.height * 0.75,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: isMobile ? BorderRadius.zero : BorderRadius.circular(20),
        ),
        child: organizationAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          error: (error, _) => Center(
            child: Text('Error: ${error.toString()}'),
          ),
          data: (organization) {
            if (organization == null) {
              return const Center(child: Text('No organization'));
            }

            if (_nameController.text.isEmpty) {
              _initializeFromOrganization(organization);
            }

            final isAdmin = organization.currentUserRole == 'admin';

            // Mobile layout - no sidebar
            if (isMobile) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  return ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                      maxHeight: constraints.maxHeight,
                    ),
                    child: Column(
                      children: [
                        // Header Bar
                        Container(
                          height: 56,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: colorScheme.outline.withValues(alpha: 0.1),
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _getViewTitle(),
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                onPressed: () => Navigator.of(context).pop(),
                                icon: const Icon(Icons.close),
                                tooltip: 'Close',
                                iconSize: 20,
                              ),
                            ],
                          ),
                        ),
                        // Mobile Tabs
                        Container(
                          height: 48,
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: colorScheme.outline.withValues(alpha: 0.1),
                              ),
                            ),
                          ),
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            cacheExtent: 1000, // Ensure all tabs are built
                            children: [
                              _buildMobileTab('general', 'General', isAdmin),
                              _buildMobileTab('notifications', 'Notifications', isAdmin),
                              _buildMobileTab('data', 'Data', isAdmin),
                              _buildMobileTab('members', 'Members', true),
                              if (isAdmin) _buildMobileTab('danger', 'Danger', isAdmin),
                            ],
                          ),
                        ),
                        // Content
                        Expanded(
                          child: Form(
                            key: _formKey,
                            onChanged: _markChanged,
                            child: _buildContent(organization, isAdmin),
                          ),
                        ),
                        // Footer
                        if (isAdmin && _selectedView != 'members')
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                  color: colorScheme.outline.withValues(alpha: 0.1),
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (_hasChanges) ...[
                                  TextButton(
                                    onPressed: () {
                                      _initializeFromOrganization(organization);
                                      setState(() {
                                        _hasChanges = false;
                                      });
                                    },
                                    child: const Text('Reset'),
                                  ),
                                  const SizedBox(width: 8),
                                  FilledButton(
                                    onPressed: _isSaving ? null : _saveChanges,
                                    child: Text(_isSaving ? 'Saving...' : 'Save'),
                                  ),
                                ],
                              ],
                            ),
                          ),
                      ],
                    ),
                  );
                },
              );
            }

            // Desktop/Tablet layout - with sidebar
            return Row(
              children: [
                // Sidebar
                Container(
                  width: 200,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLowest,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Organization Header
                      Container(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  organization.name.substring(0, 1).toUpperCase(),
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              organization.name,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                isAdmin ? 'Admin' : 'Member',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.primary,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      // Navigation
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          children: [
                            _buildNavItem(
                              'general',
                              Icons.settings_outlined,
                              'General',
                              isAdmin,
                            ),
                            _buildNavItem(
                              'notifications',
                              Icons.notifications_outlined,
                              'Notifications',
                              isAdmin,
                            ),
                            _buildNavItem(
                              'data',
                              Icons.storage_outlined,
                              'Data',
                              isAdmin,
                            ),
                            _buildNavItem(
                              'members',
                              Icons.people_outline,
                              'Members',
                              true,
                            ),
                            if (isAdmin) ...[
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: Divider(),
                              ),
                              _buildNavItem(
                                'danger',
                                Icons.warning_outlined,
                                'Danger Zone',
                                true,
                                isDanger: true,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Content Area
                Expanded(
                  child: Column(
                    children: [
                      // Header Bar
                      Container(
                        height: 60,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: colorScheme.outline.withValues(alpha: 0.05),
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              _getViewTitle(),
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(Icons.close),
                              tooltip: 'Close',
                            ),
                          ],
                        ),
                      ),
                      // Content
                      Expanded(
                        child: Form(
                          key: _formKey,
                          onChanged: _markChanged,
                          child: _buildContent(organization, isAdmin),
                        ),
                      ),
                      // Footer
                      if (isAdmin && _selectedView != 'members')
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: colorScheme.outline.withValues(alpha: 0.05),
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (_hasChanges) ...[
                                TextButton(
                                  onPressed: () {
                                    _initializeFromOrganization(organization);
                                    setState(() {
                                      _hasChanges = false;
                                    });
                                  },
                                  child: const Text('Reset'),
                                ),
                                const SizedBox(width: 8),
                                FilledButton(
                                  onPressed: _isSaving ? null : _saveChanges,
                                  child: Text(_isSaving ? 'Saving...' : 'Save'),
                                ),
                              ],
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMobileTab(String view, String label, bool enabled) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = _selectedView == view;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: enabled
              ? () {
                  setState(() {
                    _selectedView = view;
                  });
                }
              : null,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? colorScheme.primaryContainer
                  : colorScheme.surface,
              border: Border.all(
                color: isSelected
                    ? colorScheme.primary.withValues(alpha: 0.2)
                    : colorScheme.outline.withValues(alpha: 0.2),
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    String view,
    IconData icon,
    String label,
    bool enabled, {
    bool isDanger = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = _selectedView == view;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: enabled
              ? () {
                  setState(() {
                    _selectedView = view;
                  });
                }
              : null,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? colorScheme.primaryContainer.withValues(alpha: 0.15)
                  : null,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isDanger
                      ? colorScheme.error.withValues(alpha: enabled ? 1 : 0.3)
                      : isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant.withValues(
                              alpha: enabled ? 0.7 : 0.3),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDanger
                          ? colorScheme.error.withValues(alpha: enabled ? 1 : 0.3)
                          : isSelected
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant.withValues(
                                  alpha: enabled ? 1 : 0.5),
                      fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getViewTitle() {
    switch (_selectedView) {
      case 'general':
        return 'General Settings';
      case 'notifications':
        return 'Notifications';
      case 'data':
        return 'Data Management';
      case 'members':
        return 'Members';
      case 'danger':
        return 'Danger Zone';
      default:
        return 'Settings';
    }
  }

  Widget _buildContent(Organization organization, bool isAdmin) {
    switch (_selectedView) {
      case 'general':
        return _buildGeneralContent(organization, isAdmin);
      case 'notifications':
        return _buildNotificationsContent(isAdmin);
      case 'data':
        return _buildDataContent(isAdmin);
      case 'members':
        return _buildMembersContent(organization);
      case 'danger':
        return _buildDangerContent();
      default:
        return const Center(child: Text('Select an option'));
    }
  }

  Widget _buildGeneralContent(Organization organization, bool isAdmin) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isMobile = MediaQuery.of(context).size.width <= 768;

    // Watch real data
    final projectsAsync = ref.watch(projectsListProvider);
    final documentsAsync = ref.watch(documentsStatisticsProvider);

    final memberCount = organization.memberCount ?? 0;
    final projectCount = projectsAsync.valueOrNull?.length ?? 0;
    final documentCount = documentsAsync.valueOrNull?['total'] ?? 0;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Basic Info
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: colorScheme.outline.withValues(alpha: 0.1),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Basic Information',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _nameController,
                    enabled: isAdmin,
                    decoration: const InputDecoration(
                      labelText: 'Organization Name',
                      hintText: 'Enter organization name',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    enabled: isAdmin,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Describe your organization',
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Stats
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: colorScheme.outline.withValues(alpha: 0.1),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Organization Stats',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),
                  isMobile
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildStatItem('Members', memberCount.toString(), Icons.people_outline),
                            const SizedBox(height: 12),
                            _buildStatItem('Projects', projectCount.toString(), Icons.folder_outlined),
                            const SizedBox(height: 12),
                            _buildStatItem('Documents', documentCount.toString(), Icons.description_outlined),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: _buildStatItem('Members', memberCount.toString(), Icons.people_outline),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: _buildStatItem('Projects', projectCount.toString(), Icons.folder_outlined),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: _buildStatItem('Documents', documentCount.toString(), Icons.description_outlined),
                            ),
                          ],
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsContent(bool isAdmin) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isMobile = MediaQuery.of(context).size.width <= 768;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('Email Notifications'),
              subtitle: const Text('Get notified about important updates'),
              value: _emailNotifications,
              onChanged: isAdmin
                  ? (value) {
                      setState(() {
                        _emailNotifications = value;
                        _markChanged();
                      });
                    }
                  : null,
            ),
            const Divider(height: 1),
            SwitchListTile(
              title: const Text('Weekly Summary'),
              subtitle: const Text('Receive weekly reports via email'),
              value: _weeklyReports,
              onChanged: isAdmin
                  ? (value) {
                      setState(() {
                        _weeklyReports = value;
                        _markChanged();
                      });
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataContent(bool isAdmin) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isMobile = MediaQuery.of(context).size.width <= 768;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Data Retention',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                initialValue: _selectedDataRetentionDays,
                decoration: const InputDecoration(
                  labelText: 'Retention Period',
                  helperText: 'How long to keep your data',
                ),
                items: _dataRetentionOptions.map((option) {
                  return DropdownMenuItem(
                    value: option['value'],
                    child: Text(option['label']!),
                  );
                }).toList(),
                onChanged: isAdmin
                    ? (value) {
                        if (value != null) {
                          setState(() {
                            _selectedDataRetentionDays = value;
                            _markChanged();
                          });
                        }
                      }
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMembersContent(Organization organization) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.group_outlined,
            size: 64,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Member Management',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            '${organization.memberCount ?? 0} members',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Coming soon',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDangerContent() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isMobile = MediaQuery.of(context).size.width <= 768;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Card(
        elevation: 0,
        color: colorScheme.errorContainer.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: colorScheme.error.withValues(alpha: 0.2),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.warning_outlined,
                    color: colorScheme.error,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Delete Organization',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colorScheme.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Once you delete an organization, there is no going back. '
                'All data will be permanently removed.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _confirmDelete,
                icon: const Icon(Icons.delete_forever),
                label: const Text('Delete Organization'),
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.error,
                  foregroundColor: colorScheme.onError,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 20,
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}