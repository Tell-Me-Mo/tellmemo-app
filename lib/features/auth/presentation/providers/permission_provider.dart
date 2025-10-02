import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../organizations/presentation/providers/organization_provider.dart';

part 'permission_provider.g.dart';

enum Permission {
  // Organization management
  manageOrganization,
  inviteMembers,
  removeMembers,
  updateMemberRoles,

  // Content and project management
  createProjects,
  editProjects,
  deleteProjects,

  // Integration management
  manageIntegrations,

  // General content access
  viewContent,
  createContent,
  editContent,
  deleteContent,
}

@riverpod
class UserPermissions extends _$UserPermissions {
  @override
  Set<Permission> build() {
    final organization = ref.watch(currentOrganizationProvider).valueOrNull;
    final userRole = organization?.currentUserRole;

    if (userRole == null) {
      return <Permission>{};
    }

    return _getPermissionsForRole(userRole);
  }

  Set<Permission> _getPermissionsForRole(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return {
          // All permissions for admin
          Permission.manageOrganization,
          Permission.inviteMembers,
          Permission.removeMembers,
          Permission.updateMemberRoles,
          Permission.createProjects,
          Permission.editProjects,
          Permission.deleteProjects,
          Permission.manageIntegrations,
          Permission.viewContent,
          Permission.createContent,
          Permission.editContent,
          Permission.deleteContent,
        };

      case 'member':
        return {
          // Standard member permissions
          Permission.createProjects,
          Permission.editProjects,
          Permission.viewContent,
          Permission.createContent,
          Permission.editContent,
          Permission.deleteContent,
        };

      case 'viewer':
        return {
          // Read-only permissions
          Permission.viewContent,
        };

      default:
        return <Permission>{};
    }
  }

  bool hasPermission(Permission permission) {
    return state.contains(permission);
  }

  bool hasAnyPermission(List<Permission> permissions) {
    return permissions.any((permission) => state.contains(permission));
  }

  bool hasAllPermissions(List<Permission> permissions) {
    return permissions.every((permission) => state.contains(permission));
  }

  bool get isAdmin {
    final organization = ref.read(currentOrganizationProvider).valueOrNull;
    return organization?.currentUserRole?.toLowerCase() == 'admin';
  }

  bool get isMember {
    final organization = ref.read(currentOrganizationProvider).valueOrNull;
    final role = organization?.currentUserRole?.toLowerCase();
    return role == 'admin' || role == 'member';
  }

  bool get isViewer {
    final organization = ref.read(currentOrganizationProvider).valueOrNull;
    return organization?.currentUserRole?.toLowerCase() == 'viewer';
  }
}

// Convenience provider for checking specific permissions
@riverpod
bool canManageOrganization(Ref ref) {
  final permissions = ref.watch(userPermissionsProvider);
  return permissions.contains(Permission.manageOrganization);
}

@riverpod
bool canManageMembers(Ref ref) {
  final permissions = ref.watch(userPermissionsProvider);
  return permissions.contains(Permission.inviteMembers) ||
         permissions.contains(Permission.removeMembers) ||
         permissions.contains(Permission.updateMemberRoles);
}

@riverpod
bool canManageProjects(Ref ref) {
  final permissions = ref.watch(userPermissionsProvider);
  return permissions.contains(Permission.createProjects) ||
         permissions.contains(Permission.editProjects) ||
         permissions.contains(Permission.deleteProjects);
}

@riverpod
bool canManageIntegrations(Ref ref) {
  final permissions = ref.watch(userPermissionsProvider);
  return permissions.contains(Permission.manageIntegrations);
}