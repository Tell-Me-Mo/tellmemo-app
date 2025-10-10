import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/user_profile_provider.dart';
import '../widgets/user_avatar.dart';
import '../widgets/organization_card.dart';
import '../widgets/organization_list.dart';
import '../../domain/entities/user_profile.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../organizations/presentation/widgets/organization_settings_dialog.dart';
import '../../../../core/services/notification_service.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  const UserProfileScreen({super.key});

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  String? _avatarUrl;
  bool _emailNotifications = true;
  bool _weeklyDigest = false;
  bool _isEditMode = false;
  bool _hasChanges = false;


  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _bioController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _initializeFromProfile(UserProfile profile, UserPreferences preferences) {
    _nameController.text = profile.name ?? '';
    _bioController.text = profile.bio ?? '';
    _avatarUrl = profile.avatarUrl;
    _emailNotifications = preferences.emailNotifications;
    _weeklyDigest = preferences.weeklyDigest;
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

    try {
      // Update profile information
      await ref.read(userProfileControllerProvider.notifier).updateProfile(
        name: _nameController.text.isEmpty ? null : _nameController.text,
        bio: _bioController.text.isEmpty ? null : _bioController.text,
        avatarUrl: _avatarUrl,
      );

      // Update preferences
      final newPreferences = UserPreferences(
        emailNotifications: _emailNotifications,
        weeklyDigest: _weeklyDigest,
      );

      await ref.read(userProfileControllerProvider.notifier).updatePreferences(newPreferences);

      _setEditMode(false);

      if (mounted) {
        ref.read(notificationServiceProvider.notifier).showSuccess('Profile updated successfully');
      }
    } catch (e) {
      if (mounted) {
        ref.read(notificationServiceProvider.notifier).showError('Error updating profile: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final profileAsync = ref.watch(userProfileControllerProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1200;
    final isTablet = screenWidth > 768;
    final isMobile = screenWidth <= 768;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Column(
        children: [
          // Fixed App Bar - matching lessons tab
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primary.withValues(alpha: 0.02),
                  colorScheme.secondary.withValues(alpha: 0.01),
                ],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 24 : 16,
                  vertical: isMobile ? 12 : 16,
                ),
                child: Center(
                  child: _buildHeader(context),
                ),
              ),
            ),
          ),
          // Main Content
          Expanded(
            child: profileAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(48),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, stackTrace) => _buildErrorState(error.toString()),
              data: (profile) {
                if (profile == null) {
                  return const Center(
                    child: Text('No profile data available'),
                  );
                }

                final profileController = ref.read(userProfileControllerProvider.notifier);
                final preferences = profileController.preferences;

                if (_nameController.text.isEmpty) {
                  _initializeFromProfile(profile, preferences);
                }

                // Desktop layout with sticky right panel
                if (isDesktop) {
                  return Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1400),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Main Content Area (left side - scrollable)
                            Expanded(
                              flex: 2,
                              child: RefreshIndicator(
                                onRefresh: () async {
                                  ref.invalidate(userProfileControllerProvider);
                                },
                                child: SingleChildScrollView(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  child: Form(
                                    key: _formKey,
                                    onChanged: _markChanged,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildProfileSection(theme, profile),
                                        const SizedBox(height: 32),
                                        _buildNotificationSettingsSection(theme),
                                        const SizedBox(height: 32),
                                        _buildAccountSettingsSection(theme),
                                        const SizedBox(height: 100), // Extra padding at bottom
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // Visual Separator
                            Container(
                              width: 1,
                              margin: const EdgeInsets.symmetric(horizontal: 24),
                              color: colorScheme.outline.withValues(alpha: 0.2),
                            ),

                            // Right Panel (sticky)
                            SizedBox(
                              width: 380,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Enhanced Current Organization Card
                                  const EnhancedOrganizationCard(),
                                  const SizedBox(height: 16),

                                  // Organization List
                                  const OrganizationList(),
                                  const SizedBox(height: 24),

                                  // Privacy & Security Quick Links
                                  _buildPrivacyQuickLinks(context),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                } else if (isTablet) {
                  // Tablet layout
                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(userProfileControllerProvider);
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 800),
                          child: Form(
                            key: _formKey,
                            onChanged: _markChanged,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildOrganizationActionsGrid(context),
                                const SizedBox(height: 32),
                                _buildProfileSection(theme, profile),
                                const SizedBox(height: 32),
                                _buildNotificationSettingsSection(theme),
                                const SizedBox(height: 32),
                                const EnhancedOrganizationCard(),
                                const SizedBox(height: 16),
                                const OrganizationList(),
                                const SizedBox(height: 32),
                                _buildAccountSettingsSection(theme),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                } else {
                  // Mobile layout
                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(userProfileControllerProvider);
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        onChanged: _markChanged,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildProfileSection(theme, profile),
                            const SizedBox(height: 32),
                            _buildNotificationSettingsSection(theme),
                            const SizedBox(height: 32),
                            const EnhancedOrganizationCard(),
                            const SizedBox(height: 16),
                            const OrganizationList(),
                            const SizedBox(height: 32),
                            _buildAccountSettingsSection(theme),
                          ],
                        ),
                      ),
                    ),
                  );
                }
              },
            ),
          ),

        ],
      ),
      // Floating Action Button for mobile
      floatingActionButton: screenWidth <= 768 && !_isEditMode
        ? FloatingActionButton.extended(
            onPressed: () => _setEditMode(true),
            backgroundColor: theme.colorScheme.primary,
            icon: const Icon(Icons.edit),
            label: const Text('Edit Profile'),
          )
        : null,
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1200;
    final isMobile = screenWidth <= 768;

    if (isMobile) {
      // Mobile header - compact design matching Projects tab
      return Row(
        children: [
          Icon(
            Icons.person,
            color: colorScheme.primary,
            size: 22,
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Profile',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Text(
                'Settings',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      );
    }

    // Desktop header
    return Row(
      children: [
        // Icon and Title Section (matching lessons tab)
        Icon(
          Icons.person,
          color: colorScheme.primary,
          size: 28,
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Profile Settings',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Manage your account and preferences',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const Spacer(),
        // Edit/Save Actions for desktop
        if (isDesktop)
          Row(
            children: [
              if (!_isEditMode) ...[
                OutlinedButton.icon(
                  onPressed: () => _setEditMode(true),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit Profile'),
                ),
              ] else ...[
                OutlinedButton(
                  onPressed: () => _setEditMode(false),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: _hasChanges ? _saveChanges : null,
                  icon: const Icon(Icons.save_outlined, size: 16),
                  label: const Text('Save Changes'),
                ),
              ],
            ],
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
              'Error loading profile',
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
              onPressed: () => ref.invalidate(userProfileControllerProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

Widget _buildOrganizationActionsGrid(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final actions = [
      {
        'icon': Icons.settings,
        'label': 'Settings',
        'color': colorScheme.primary.withValues(alpha: 0.8),
        'onTap': () => _showOrganizationSettingsDialog(context),
      },
      {
        'icon': Icons.people_outline,
        'label': 'Members',
        'color': colorScheme.primary.withValues(alpha: 0.8),
        'onTap': () => context.go('/organization/members'),
      },
      {
        'icon': Icons.shield_outlined,
        'label': 'Security',
        'color': colorScheme.primary.withValues(alpha: 0.8),
        'onTap': () => context.go('/organization/security'),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Organization Actions',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w300,
            fontSize: 16,
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


  Widget _buildPrivacyQuickLinks(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final links = [
      {
        'icon': Icons.lock,
        'label': 'Change Password',
        'onTap': () => context.go('/profile/change-password'),
      },
      {
        'icon': Icons.security,
        'label': 'Privacy Settings',
        'onTap': () => context.go('/profile/privacy'),
      },
      {
        'icon': Icons.download,
        'label': 'Export Data',
        'onTap': () => _showExportDataDialog(context),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Privacy & Security',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w300,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        ...links.map((link) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: link['onTap'] as VoidCallback,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.1),
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
        )).toList(),
      ],
    );
  }

  Widget _buildProfileSection(ThemeData theme, UserProfile profile) {
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
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
                Icons.person_outline,
                size: 18,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 8),
              Text(
                'Personal Information',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w300,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AvatarPicker(
                currentImageUrl: _avatarUrl,
                userName: _nameController.text,
                onImageSelected: _isEditMode ? (url) {
                  setState(() {
                    _avatarUrl = url;
                  });
                  _markChanged();
                } : (_) {},
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      enabled: _isEditMode,
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        hintText: 'Enter your full name',
                        prefixIcon: Icon(Icons.badge_outlined, size: 20, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: colorScheme.outline.withValues(alpha: 0.1),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: colorScheme.outline.withValues(alpha: 0.1),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: colorScheme.primary.withValues(alpha: 0.5),
                          ),
                        ),
                        disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: colorScheme.outline.withValues(alpha: 0.1),
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value != null && value.isNotEmpty && value.length < 2) {
                          return 'Name must be at least 2 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _bioController,
                      enabled: _isEditMode,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Bio (Optional)',
                        hintText: 'Tell us a little about yourself',
                        alignLabelWithHint: true,
                        prefixIcon: Icon(Icons.description_outlined, size: 20, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: colorScheme.outline.withValues(alpha: 0.1),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: colorScheme.outline.withValues(alpha: 0.1),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: colorScheme.primary.withValues(alpha: 0.5),
                          ),
                        ),
                        disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: colorScheme.outline.withValues(alpha: 0.1),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: profile.email,
                      enabled: false,
                      decoration: InputDecoration(
                        labelText: 'Email Address',
                        helperText: 'Contact support to change your email',
                        prefixIcon: Icon(Icons.email_outlined, size: 20, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: colorScheme.outline.withValues(alpha: 0.1),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: colorScheme.outline.withValues(alpha: 0.1),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: colorScheme.primary.withValues(alpha: 0.5),
                          ),
                        ),
                        disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: colorScheme.outline.withValues(alpha: 0.1),
                          ),
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

Widget _buildNotificationSettingsSection(ThemeData theme) {
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
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
                Icons.notifications_outlined,
                size: 18,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 8),
              Text(
                'Notification Preferences',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w300,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Email Notifications'),
                  subtitle: const Text('Receive important updates via email'),
                  value: _emailNotifications,
                  onChanged: _isEditMode
                      ? (value) {
                          setState(() {
                            _emailNotifications = value;
                          });
                          _markChanged();
                        }
                      : null,
                  secondary: Icon(
                    Icons.email_outlined,
                    color: colorScheme.primary.withValues(alpha: 0.6),
                    size: 20,
                  ),
                ),
                Divider(
                  height: 1,
                  color: colorScheme.outline.withValues(alpha: 0.1),
                ),
                SwitchListTile(
                  title: const Text('Weekly Digest'),
                  subtitle: const Text('Receive weekly summary emails'),
                  value: _weeklyDigest,
                  onChanged: _isEditMode
                      ? (value) {
                          setState(() {
                            _weeklyDigest = value;
                          });
                          _markChanged();
                        }
                      : null,
                  secondary: Icon(
                    Icons.summarize_outlined,
                    color: colorScheme.secondary.withValues(alpha: 0.6),
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSettingsSection(ThemeData theme) {
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
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
                Icons.security,
                size: 20,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Account & Security',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w300,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => context.go('/profile/change-password'),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lock_outline,
                            color: colorScheme.primary.withValues(alpha: 0.6),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Change Password',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Update your account password',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Divider(
                  height: 1,
                  color: colorScheme.outline.withValues(alpha: 0.1),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _signOut,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.logout,
                            color: colorScheme.tertiary.withValues(alpha: 0.6),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Sign Out',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Sign out from your account',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Divider(
                  height: 1,
                  color: colorScheme.outline.withValues(alpha: 0.1),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _showDeleteAccountDialog(),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_forever,
                            color: colorScheme.error.withValues(alpha: 0.6),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Delete Account',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w400,
                                    color: colorScheme.error,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Permanently delete your account and data',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteAccountDialog() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone and will permanently delete all your data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implement account deletion
              ref.read(notificationServiceProvider.notifier).showInfo('Account deletion not implemented yet');
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }


  void _showOrganizationSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const OrganizationSettingsDialog(),
    );
  }

  void _showExportDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Data'),
        content: const Text('Data export functionality is not yet implemented.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref.read(authControllerProvider.notifier).signOut();
        if (mounted) {
          context.go('/signin');
        }
      } catch (e) {
        if (mounted) {
          ref.read(notificationServiceProvider.notifier).showError('Error signing out: $e');
        }
      }
    }
  }
}