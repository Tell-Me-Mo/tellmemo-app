import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../organizations/domain/entities/organization.dart';
import '../../../organizations/presentation/providers/organization_provider.dart';
import '../../../organizations/presentation/widgets/organization_settings_dialog.dart';

class EnhancedOrganizationCard extends ConsumerWidget {
  const EnhancedOrganizationCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentOrgAsync = ref.watch(currentOrganizationProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Current Organization',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w300,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        currentOrgAsync.when(
          loading: () => Container(
            height: 160,
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.1),
              ),
            ),
            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          error: (error, _) => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: colorScheme.error.withValues(alpha: 0.7),
                  size: 18,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Error loading organization',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ),
              ],
            ),
          ),
          data: (organization) {
            if (organization == null) {
              return _buildNoOrganizationCard(context);
            }
            return _buildOrganizationCard(context, organization);
          },
        ),
      ],
    );
  }

  Widget _buildNoOrganizationCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.business_outlined,
            size: 32,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(
            'No Organization Selected',
            style: textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Create or join an organization',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              fontWeight: FontWeight.w300,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.go('/organization/create'),
              icon: Icon(Icons.add_outlined, size: 16),
              label: Text(
                'Create Organization',
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w300,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.1),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrganizationCard(BuildContext context, Organization organization) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isAdmin = organization.currentUserRole?.toLowerCase() == 'admin';

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          // Header Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Organization Avatar
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      organization.name.isNotEmpty
                        ? organization.name.substring(0, 1).toUpperCase()
                        : 'O',
                      style: textTheme.titleMedium?.copyWith(
                        color: colorScheme.primary.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Organization Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        organization.name,
                        style: textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w400,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        organization.currentUserRole?.toUpperCase() ?? 'MEMBER',
                        style: textTheme.labelSmall?.copyWith(
                          color: isAdmin
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w300,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.settings_outlined,
                    size: 18,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  onPressed: () => _showSettingsDialog(context),
                  tooltip: 'Organization Settings',
                ),
              ],
            ),
          ),

          Divider(
            height: 1,
            color: colorScheme.outline.withValues(alpha: 0.05),
          ),

          // Stats Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  context,
                  icon: Icons.people_outline,
                  label: 'Members',
                  value: '${organization.memberCount ?? 1}',
                ),
                Container(
                  height: 32,
                  color: colorScheme.outline.withValues(alpha: 0.1),
                ),
                _buildStatItem(
                  context,
                  icon: Icons.folder_outlined,
                  label: 'Projects',
                  value: '${organization.projectCount ?? 0}',
                ),
                Container(
                  height: 32,
                  color: colorScheme.outline.withValues(alpha: 0.1),
                ),
                _buildStatItem(
                  context,
                  icon: Icons.description_outlined,
                  label: 'Documents',
                  value: '${organization.documentCount ?? 0}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Column(
      children: [
        Icon(
          icon,
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          size: 18,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            fontSize: 10,
            fontWeight: FontWeight.w300,
          ),
        ),
      ],
    );
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const OrganizationSettingsDialog(),
    );
  }
}