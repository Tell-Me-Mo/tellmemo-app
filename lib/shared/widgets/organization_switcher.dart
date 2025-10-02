import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/organizations/domain/entities/organization.dart';
import '../../features/organizations/presentation/providers/organization_provider.dart';

class OrganizationSwitcher extends ConsumerWidget {
  const OrganizationSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentOrgAsync = ref.watch(currentOrganizationProvider);
    final userOrgsAsync = ref.watch(userOrganizationsProvider);

    return currentOrgAsync.when(
      loading: () => const _LoadingIndicator(),
      error: (error, stack) => const _ErrorIndicator(),
      data: (currentOrg) {
        return userOrgsAsync.when(
          loading: () => const _LoadingIndicator(),
          error: (error, stack) => const _ErrorIndicator(),
          data: (organizations) {
            if (organizations.isEmpty) {
              return _CreateOrganizationButton();
            }

            return _OrganizationDropdown(
              currentOrganization: currentOrg,
              organizations: organizations,
            );
          },
        );
      },
    );
  }
}

class _OrganizationDropdown extends ConsumerStatefulWidget {
  final Organization? currentOrganization;
  final List<Organization> organizations;

  const _OrganizationDropdown({
    required this.currentOrganization,
    required this.organizations,
  });

  @override
  ConsumerState<_OrganizationDropdown> createState() => _OrganizationDropdownState();
}

class _OrganizationDropdownState extends ConsumerState<_OrganizationDropdown> {
  bool _isSwitching = false;

  Future<void> _handleOrganizationChange(String? organizationId) async {
    if (organizationId == null || organizationId == widget.currentOrganization?.id) {
      return;
    }

    if (organizationId == 'create_new') {
      // Navigate to create organization
      context.go('/organization/create');
      return;
    }

    setState(() {
      _isSwitching = true;
    });

    try {
      await ref.read(currentOrganizationProvider.notifier).switchOrganization(organizationId);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Switched to ${widget.organizations.firstWhere((org) => org.id == organizationId).name}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to switch organization: ${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSwitching = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: widget.currentOrganization?.id,
          isDense: true,
          icon: _isSwitching
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colorScheme.primary,
                  ),
                )
              : Icon(
                  Icons.arrow_drop_down,
                  color: colorScheme.onSurface,
                ),
          selectedItemBuilder: (context) {
            return [
              ...widget.organizations.map((org) {
                return Container(
                  alignment: Alignment.centerLeft,
                  constraints: const BoxConstraints(maxWidth: 200),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _OrganizationAvatar(
                        name: org.name,
                        logoUrl: org.logoUrl,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          org.name,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              Container(), // Placeholder for "Create new" option
            ];
          },
          items: [
            ...widget.organizations.map((org) {
              final isSelected = org.id == widget.currentOrganization?.id;
              return DropdownMenuItem<String>(
                value: org.id,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      _OrganizationAvatar(
                        name: org.name,
                        logoUrl: org.logoUrl,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              org.name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                              ),
                            ),
                            if (org.description != null && org.description!.isNotEmpty)
                              Text(
                                org.description!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check,
                          size: 20,
                          color: colorScheme.primary,
                        ),
                    ],
                  ),
                ),
              );
            }),
            const DropdownMenuItem<String>(
              value: null,
              enabled: false,
              child: Divider(),
            ),
            DropdownMenuItem<String>(
              value: 'create_new',
              child: Row(
                children: [
                  Icon(
                    Icons.add_circle_outline,
                    size: 32,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Create new organization',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
          onChanged: _isSwitching ? null : _handleOrganizationChange,
        ),
      ),
    );
  }
}

class _OrganizationAvatar extends StatelessWidget {
  final String name;
  final String? logoUrl;
  final double size;

  const _OrganizationAvatar({
    required this.name,
    this.logoUrl,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (logoUrl != null && logoUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size / 4),
        child: Image.network(
          logoUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildInitialsAvatar(colorScheme);
          },
        ),
      );
    }

    return _buildInitialsAvatar(colorScheme);
  }

  Widget _buildInitialsAvatar(ColorScheme colorScheme) {
    final initials = name.split(' ')
        .map((word) => word.isNotEmpty ? word[0].toUpperCase() : '')
        .take(2)
        .join();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(size / 4),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontSize: size * 0.4,
          fontWeight: FontWeight.w600,
          color: colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}

class _CreateOrganizationButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return TextButton.icon(
      onPressed: () {
        context.go('/organization/create');
      },
      icon: Icon(
        Icons.add_circle_outline,
        size: 20,
        color: colorScheme.primary,
      ),
      label: Text(
        'Create Organization',
        style: TextStyle(
          color: colorScheme.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}

class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}

class _ErrorIndicator extends StatelessWidget {
  const _ErrorIndicator();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return IconButton(
      icon: Icon(
        Icons.error_outline,
        color: colorScheme.error,
        size: 20,
      ),
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load organizations'),
            backgroundColor: Colors.red,
          ),
        );
      },
      tooltip: 'Failed to load organizations',
    );
  }
}