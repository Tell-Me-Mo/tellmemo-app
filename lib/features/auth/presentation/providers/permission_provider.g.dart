// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'permission_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$canManageOrganizationHash() =>
    r'd5a03fb33724ca72ded2f0be073ca1184cc39f0d';

/// See also [canManageOrganization].
@ProviderFor(canManageOrganization)
final canManageOrganizationProvider = AutoDisposeProvider<bool>.internal(
  canManageOrganization,
  name: r'canManageOrganizationProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$canManageOrganizationHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CanManageOrganizationRef = AutoDisposeProviderRef<bool>;
String _$canManageMembersHash() => r'4918056ea14f461a77c5587f571f5b24348cf361';

/// See also [canManageMembers].
@ProviderFor(canManageMembers)
final canManageMembersProvider = AutoDisposeProvider<bool>.internal(
  canManageMembers,
  name: r'canManageMembersProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$canManageMembersHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CanManageMembersRef = AutoDisposeProviderRef<bool>;
String _$canManageProjectsHash() => r'2736fd01876c3105801f74b313db6cc446810cfe';

/// See also [canManageProjects].
@ProviderFor(canManageProjects)
final canManageProjectsProvider = AutoDisposeProvider<bool>.internal(
  canManageProjects,
  name: r'canManageProjectsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$canManageProjectsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CanManageProjectsRef = AutoDisposeProviderRef<bool>;
String _$canManageIntegrationsHash() =>
    r'205522fd601a03e397dc2db1ec318fc306ce40cc';

/// See also [canManageIntegrations].
@ProviderFor(canManageIntegrations)
final canManageIntegrationsProvider = AutoDisposeProvider<bool>.internal(
  canManageIntegrations,
  name: r'canManageIntegrationsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$canManageIntegrationsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CanManageIntegrationsRef = AutoDisposeProviderRef<bool>;
String _$userPermissionsHash() => r'5c3c4ca743f49caafe8db0dc22160dbeac24a3aa';

/// See also [UserPermissions].
@ProviderFor(UserPermissions)
final userPermissionsProvider =
    AutoDisposeNotifierProvider<UserPermissions, Set<Permission>>.internal(
      UserPermissions.new,
      name: r'userPermissionsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$userPermissionsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$UserPermissions = AutoDisposeNotifier<Set<Permission>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
