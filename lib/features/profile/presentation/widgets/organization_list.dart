import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../organizations/domain/entities/organization.dart';
import '../../../organizations/presentation/providers/organization_provider.dart';
import '../../../../core/services/notification_service.dart';

class OrganizationList extends ConsumerStatefulWidget {
  const OrganizationList({super.key});

  @override
  ConsumerState<OrganizationList> createState() => _OrganizationListState();
}

class _OrganizationListState extends ConsumerState<OrganizationList> {
  String? _switchingToOrgId;

  Future<void> _switchOrganization(String organizationId) async {
    setState(() {
      _switchingToOrgId = organizationId;
    });

    try {
      await ref.read(currentOrganizationProvider.notifier).switchOrganization(organizationId);

      if (mounted) {
        ref.read(notificationServiceProvider.notifier).showSuccess('Organization switched successfully');
      }
    } catch (error) {
      if (mounted) {
        ref.read(notificationServiceProvider.notifier).showError('Failed to switch organization: ${error.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _switchingToOrgId = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final currentOrgAsync = ref.watch(currentOrganizationProvider);
    final userOrgsAsync = ref.watch(userOrganizationsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Your Organizations',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w300,
                fontSize: 16,
              ),
            ),
            TextButton.icon(
              onPressed: () => context.go('/organization/create'),
              icon: Icon(
                Icons.add_outlined,
                size: 16,
                color: colorScheme.primary.withValues(alpha: 0.7),
              ),
              label: Text(
                'New',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.primary.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w300,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.1),
            ),
          ),
          child: userOrgsAsync.when(
            loading: () => const SizedBox(
              height: 120,
              child: Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (error, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: colorScheme.error.withValues(alpha: 0.7),
                    size: 18,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Failed to load organizations',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
            ),
            data: (organizations) {
              if (organizations.isEmpty) {
                return _buildEmptyState(context);
              }

              return Column(
                children: organizations.asMap().entries.map((entry) {
                  final index = entry.key;
                  final org = entry.value;
                  final isLast = index == organizations.length - 1;
                  final isCurrentOrg = currentOrgAsync.value?.id == org.id;
                  final isSwitching = _switchingToOrgId == org.id;

                  return Column(
                    children: [
                      _buildOrganizationTile(
                        context,
                        org,
                        isCurrentOrg: isCurrentOrg,
                        isSwitching: isSwitching,
                      ),
                      if (!isLast)
                        Divider(
                          height: 1,
                          color: colorScheme.outline.withValues(alpha: 0.05),
                          indent: 56,
                        ),
                    ],
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOrganizationTile(
    BuildContext context,
    Organization org,
    {required bool isCurrentOrg, required bool isSwitching}
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isCurrentOrg || isSwitching ? null : () => _switchOrganization(org.id),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isCurrentOrg
                    ? colorScheme.primaryContainer.withValues(alpha: 0.3)
                    : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: isCurrentOrg
                    ? Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.3),
                        width: 1,
                      )
                    : null,
                ),
                child: Center(
                  child: Text(
                    org.name.substring(0, 1).toUpperCase(),
                    style: textTheme.bodyMedium?.copyWith(
                      color: isCurrentOrg
                        ? colorScheme.primary.withValues(alpha: 0.8)
                        : colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            org.name,
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: isCurrentOrg ? FontWeight.w500 : FontWeight.w400,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isCurrentOrg) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'ACTIVE',
                              style: textTheme.labelSmall?.copyWith(
                                color: colorScheme.primary.withValues(alpha: 0.8),
                                fontSize: 9,
                                fontWeight: FontWeight.w400,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (org.description?.isNotEmpty == true) ...[
                      const SizedBox(height: 2),
                      Text(
                        org.description!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w300,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Trailing Widget
              if (isSwitching)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: colorScheme.primary.withValues(alpha: 0.6),
                  ),
                )
              else if (!isCurrentOrg)
                Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.business_outlined,
            size: 32,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 12),
          Text(
            'No organizations yet',
            style: textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Create your first organization',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              fontWeight: FontWeight.w300,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}