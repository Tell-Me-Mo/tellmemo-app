import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/organization_provider.dart';
import '../providers/organization_settings_provider.dart';
import '../../domain/entities/organization.dart';
import '../../../projects/presentation/providers/projects_provider.dart';
import '../../../documents/presentation/providers/documents_provider.dart';

class OrganizationSettingsScreen extends ConsumerStatefulWidget {
  const OrganizationSettingsScreen({super.key});

  @override
  ConsumerState<OrganizationSettingsScreen> createState() => _OrganizationSettingsScreenState();
}

class _OrganizationSettingsScreenState extends ConsumerState<OrganizationSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  String? _selectedDataRetentionDays = '90';
  bool _emailNotifications = true;
  bool _weeklyReports = false;
  bool _isEditMode = false;
  bool _hasChanges = false;


  final List<Map<String, String>> _dataRetentionOptions = [
    {'value': '30', 'label': '30 days'},
    {'value': '60', 'label': '60 days'},
    {'value': '90', 'label': '90 days (recommended)'},
    {'value': '180', 'label': '180 days'},
    {'value': '365', 'label': '1 year'},
    {'value': 'indefinite', 'label': 'Indefinite'},
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
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

  void _setEditMode(bool enabled) {
    setState(() {
      _isEditMode = enabled;
      _hasChanges = false;
    });
  }

  void _markChanged() {
    if (!_hasChanges) {
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

    _setEditMode(false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Organization settings updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showManageMembersDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Manage Members'),
        content: const Text('Member management functionality is not yet implemented.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showBackupDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Backup Data'),
        content: const Text('Data backup functionality is not yet implemented.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAnalyticsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('View Analytics'),
        content: const Text('Analytics functionality is not yet implemented.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAdminPanelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Admin Panel'),
        content: const Text('Admin panel functionality is not yet implemented.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSecuritySettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Security Settings'),
        content: const Text('Security settings functionality is not yet implemented.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showBillingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Billing & Usage'),
        content: const Text('Billing and usage functionality is not yet implemented.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Organization'),
        content: const Text(
          'Are you sure you want to delete this organization? '
          'This action cannot be undone and will permanently delete all associated data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final organization = ref.read(currentOrganizationProvider).value;
      if (organization == null) return;

      await ref.read(deleteOrganizationProvider(organization.id).future);

      if (mounted) {
        context.go('/dashboard');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final organizationAsync = ref.watch(currentOrganizationProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1200;
    final isTablet = screenWidth > 768;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(currentOrganizationProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.all(isDesktop ? 32 : 16),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isDesktop ? 1400 : double.infinity),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Section
                      _buildHeader(context),
                      const SizedBox(height: 32),

                      // Main Content
                      organizationAsync.when(
                        loading: () => const Center(
                          child: Padding(
                            padding: EdgeInsets.all(48),
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        error: (error, stackTrace) => _buildErrorState(error.toString()),
                        data: (organization) {
                          if (organization == null) {
                            return const Center(
                              child: Text('No organization selected'),
                            );
                          }

                          if (_nameController.text.isEmpty) {
                            _initializeFromOrganization(organization);
                          }

                          final isAdmin = organization.currentUserRole == 'admin';

                          // Desktop layout with right panel
                          if (isDesktop) {
                            return IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Main Content Area (left side)
                                  Expanded(
                                    flex: 2,
                                    child: Form(
                                      key: _formKey,
                                      onChanged: _markChanged,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          _buildProfileSection(theme, organization, isAdmin),
                                          const SizedBox(height: 32),
                                          _buildDataSettingsSection(theme, isAdmin),
                                          const SizedBox(height: 32),
                                          _buildNotificationSettingsSection(theme, isAdmin),
                                          if (isAdmin) ...[
                                            const SizedBox(height: 48),
                                            _buildDangerZoneSection(theme),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),

                                  // Visual Separator
                                  Container(
                                    width: 1,
                                    margin: const EdgeInsets.symmetric(horizontal: 24),
                                    color: colorScheme.outline.withValues(alpha: 0.2),
                                  ),

                                  // Right Panel
                                  SizedBox(
                                    width: 320,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Organization Quick Actions
                                        _buildOrganizationQuickActions(context, organization, isAdmin),
                                        const SizedBox(height: 24),

                                        // Organization Statistics
                                        _buildOrganizationStats(context, organization),
                                        const SizedBox(height: 24),

                                        // Admin Quick Links
                                        if (isAdmin) _buildAdminQuickLinks(context),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          } else {
                            // Mobile/Tablet layout
                            return Form(
                              key: _formKey,
                              onChanged: _markChanged,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Organization Quick Actions for mobile/tablet
                                  if (isTablet) ...[
                                    _buildOrganizationActionsGrid(context, organization, isAdmin),
                                    const SizedBox(height: 32),
                                  ],

                                  _buildProfileSection(theme, organization, isAdmin),
                                  const SizedBox(height: 32),
                                  _buildDataSettingsSection(theme, isAdmin),
                                  const SizedBox(height: 32),
                                  _buildNotificationSettingsSection(theme, isAdmin),
                                  if (isAdmin) ...[
                                    const SizedBox(height: 32),
                                    _buildOrganizationStats(context, organization),
                                    const SizedBox(height: 48),
                                    _buildDangerZoneSection(theme),
                                  ],
                                ],
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),

      // Floating Action Button for mobile
      floatingActionButton: screenWidth <= 768 && !_isEditMode
        ? organizationAsync.whenOrNull(
            data: (organization) {
              if (organization?.currentUserRole == 'admin') {
                return FloatingActionButton.extended(
                  onPressed: () => _setEditMode(true),
                  backgroundColor: theme.colorScheme.primary,
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit Settings'),
                );
              }
              return null;
            },
          )
        : null,
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    final organizationAsync = ref.watch(currentOrganizationProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Organization Settings',
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Manage your organization configuration and preferences',
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        // Edit/Save Actions for desktop
        if (MediaQuery.of(context).size.width > 768)
          ...organizationAsync.maybeWhen(
            data: (organization) {
              if (organization == null) return [];
              final isAdmin = organization.currentUserRole == 'admin';
              if (!isAdmin) return [];

              return [
                Row(
                  children: [
                    if (!_isEditMode) ...[
                      OutlinedButton.icon(
                        onPressed: () => _setEditMode(true),
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Edit Settings'),
                      ),
                    ] else ...[
                      OutlinedButton(
                        onPressed: () => _setEditMode(false),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        onPressed: _hasChanges ? _saveChanges : null,
                        icon: const Icon(Icons.save, size: 18),
                        label: const Text('Save Changes'),
                      ),
                    ],
                  ],
                ),
              ];
            },
            orElse: () => [],
          ),
      ],
    );
  }

  Widget _buildErrorState(String error) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Center(
      child: Container(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading organization',
              style: textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => ref.invalidate(currentOrganizationProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrganizationQuickActions(BuildContext context, Organization organization, bool isAdmin) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final actions = [
      {
        'icon': Icons.people,
        'label': 'Manage Members',
        'color': Colors.blue,
        'onTap': () => _showManageMembersDialog(context),
      },
      {
        'icon': Icons.backup,
        'label': 'Backup Data',
        'color': Colors.green,
        'onTap': () => _showBackupDataDialog(context),
      },
      {
        'icon': Icons.analytics,
        'label': 'View Analytics',
        'color': Colors.purple,
        'onTap': () => _showAnalyticsDialog(context),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...actions.map((action) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: action['onTap'] as VoidCallback,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.08),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      action['icon'] as IconData,
                      color: action['color'] as Color,
                      size: 18,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        action['label'] as String,
                        style: textTheme.bodyMedium,
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 12,
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                    ),
                  ],
                ),
              ),
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildOrganizationActionsGrid(BuildContext context, Organization organization, bool isAdmin) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final actions = [
      {
        'icon': Icons.people,
        'label': 'Members',
        'color': Colors.blue,
        'onTap': () => _showManageMembersDialog(context),
      },
      {
        'icon': Icons.backup,
        'label': 'Backup',
        'color': Colors.green,
        'onTap': () => _showBackupDataDialog(context),
      },
      {
        'icon': Icons.analytics,
        'label': 'Analytics',
        'color': Colors.purple,
        'onTap': () => _showAnalyticsDialog(context),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          childAspectRatio: 2.5,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: actions.map((action) => Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: action['onTap'] as VoidCallback,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      action['icon'] as IconData,
                      color: action['color'] as Color,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        action['label'] as String,
                        style: textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildOrganizationStats(BuildContext context, Organization organization) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // Watch real data providers
    final projectsAsync = ref.watch(projectsListProvider);
    final documentsAsync = ref.watch(documentsStatisticsProvider);

    // Get actual counts
    final memberCount = organization.memberCount ?? 0;
    final projectCount = projectsAsync.valueOrNull?.length ?? 0;
    final documentCount = documentsAsync.valueOrNull?['total'] ?? 0;

    final stats = [
      {'label': 'Members', 'value': memberCount.toString(), 'icon': Icons.people, 'color': Colors.blue},
      {'label': 'Projects', 'value': projectCount.toString(), 'icon': Icons.work, 'color': Colors.green},
      {'label': 'Documents', 'value': documentCount.toString(), 'icon': Icons.description, 'color': Colors.orange},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Organization Overview',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Column(
          children: stats.map((stat) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.surface,
                  colorScheme.surface.withValues(alpha: 0.95),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (stat['color'] as Color).withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (stat['color'] as Color).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    stat['icon'] as IconData,
                    color: stat['color'] as Color,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stat['value'] as String,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        stat['label'] as String,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildAdminQuickLinks(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final links = [
      {
        'icon': Icons.admin_panel_settings,
        'label': 'Admin Panel',
        'onTap': () => _showAdminPanelDialog(context),
      },
      {
        'icon': Icons.security,
        'label': 'Security Settings',
        'onTap': () => _showSecuritySettingsDialog(context),
      },
      {
        'icon': Icons.receipt_long,
        'label': 'Billing & Usage',
        'onTap': () => _showBillingDialog(context),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Admin Controls',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...links.map((link) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: link['onTap'] as VoidCallback,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.08),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      link['icon'] as IconData,
                      color: colorScheme.onSurfaceVariant,
                      size: 18,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        link['label'] as String,
                        style: textTheme.bodyMedium,
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 12,
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                    ),
                  ],
                ),
              ),
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildProfileSection(ThemeData theme, Organization organization, bool isAdmin) {
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.surface,
            colorScheme.surface.withValues(alpha: 0.95),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.business,
                size: 20,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Organization Profile',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.2),
                    width: 2,
                  ),
                ),
                child: organization.logoUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          organization.logoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.business,
                            size: 40,
                            color: colorScheme.primary,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.business,
                        size: 40,
                        color: colorScheme.primary,
                      ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      enabled: _isEditMode && isAdmin,
                      decoration: InputDecoration(
                        labelText: 'Organization Name',
                        hintText: 'Enter organization name',
                        prefixIcon: const Icon(Icons.badge),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Organization name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      enabled: _isEditMode && isAdmin,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Description (Optional)',
                        hintText: 'Enter a brief description of your organization',
                        alignLabelWithHint: true,
                        prefixIcon: const Icon(Icons.description),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

Widget _buildDataSettingsSection(ThemeData theme, bool isAdmin) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Data Management',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),

            DropdownButtonFormField<String>(
              initialValue: _selectedDataRetentionDays,
              decoration: const InputDecoration(
                labelText: 'Data Retention Period',
                prefixIcon: Icon(Icons.storage),
                helperText: 'How long to keep meeting data and transcripts',
              ),
              items: _dataRetentionOptions.map((option) {
                return DropdownMenuItem(
                  value: option['value'],
                  child: Text(option['label']!),
                );
              }).toList(),
              onChanged: _isEditMode
                  ? (value) {
                      if (value != null) {
                        setState(() {
                          _selectedDataRetentionDays = value;
                        });
                      }
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationSettingsSection(ThemeData theme, bool isAdmin) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notification Preferences',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),

            SwitchListTile(
              title: const Text('Email Notifications'),
              subtitle: const Text('Receive email notifications for important updates'),
              value: _emailNotifications,
              onChanged: _isEditMode
                  ? (value) {
                      setState(() {
                        _emailNotifications = value;
                      });
                    }
                  : null,
              secondary: const Icon(Icons.email),
            ),

            SwitchListTile(
              title: const Text('Weekly Reports'),
              subtitle: const Text('Receive weekly summary reports via email'),
              value: _weeklyReports,
              onChanged: _isEditMode
                  ? (value) {
                      setState(() {
                        _weeklyReports = value;
                      });
                    }
                  : null,
              secondary: const Icon(Icons.summarize),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDangerZoneSection(ThemeData theme) {
    return Card(
      color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(width: 8),
                Text(
                  'Danger Zone',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Deleting your organization will permanently remove all data including projects, summaries, and documents. This action cannot be undone.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _confirmDelete,
              icon: const Icon(Icons.delete_forever),
              label: const Text('Delete Organization'),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
                side: BorderSide(color: theme.colorScheme.error),
              ),
            ),
          ],
        ),
      ),
    );
  }
}