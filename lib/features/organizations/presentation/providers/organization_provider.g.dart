// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'organization_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$currentOrganizationHash() =>
    r'4df00740ef5fc046d2f9e21d721a7bb9f3a85fbb';

/// See also [CurrentOrganization].
@ProviderFor(CurrentOrganization)
final currentOrganizationProvider =
    AutoDisposeAsyncNotifierProvider<
      CurrentOrganization,
      Organization?
    >.internal(
      CurrentOrganization.new,
      name: r'currentOrganizationProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$currentOrganizationHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$CurrentOrganization = AutoDisposeAsyncNotifier<Organization?>;
String _$userOrganizationsHash() => r'56123c93e6c8b6d892a5b4c460e6216f803b4874';

/// See also [UserOrganizations].
@ProviderFor(UserOrganizations)
final userOrganizationsProvider =
    AutoDisposeAsyncNotifierProvider<
      UserOrganizations,
      List<Organization>
    >.internal(
      UserOrganizations.new,
      name: r'userOrganizationsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$userOrganizationsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$UserOrganizations = AutoDisposeAsyncNotifier<List<Organization>>;
String _$createOrganizationControllerHash() =>
    r'8ee0e0daba2cff3c4021bc3f9025c797334f7aff';

/// See also [CreateOrganizationController].
@ProviderFor(CreateOrganizationController)
final createOrganizationControllerProvider =
    AutoDisposeAsyncNotifierProvider<
      CreateOrganizationController,
      void
    >.internal(
      CreateOrganizationController.new,
      name: r'createOrganizationControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$createOrganizationControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$CreateOrganizationController = AutoDisposeAsyncNotifier<void>;
String _$organizationWizardHash() =>
    r'4ccb14b699c285ff27c706ba48b8899db5b2802f';

/// See also [OrganizationWizard].
@ProviderFor(OrganizationWizard)
final organizationWizardProvider =
    AutoDisposeNotifierProvider<
      OrganizationWizard,
      OrganizationWizardState
    >.internal(
      OrganizationWizard.new,
      name: r'organizationWizardProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$organizationWizardHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$OrganizationWizard = AutoDisposeNotifier<OrganizationWizardState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
