// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'organization_settings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$updateOrganizationSettingsHash() =>
    r'f56fc410d65478dcaaa232ca3bf726d3b8648413';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [updateOrganizationSettings].
@ProviderFor(updateOrganizationSettings)
const updateOrganizationSettingsProvider = UpdateOrganizationSettingsFamily();

/// See also [updateOrganizationSettings].
class UpdateOrganizationSettingsFamily
    extends Family<AsyncValue<OrganizationModel>> {
  /// See also [updateOrganizationSettings].
  const UpdateOrganizationSettingsFamily();

  /// See also [updateOrganizationSettings].
  UpdateOrganizationSettingsProvider call({
    required String organizationId,
    required Map<String, dynamic> settings,
  }) {
    return UpdateOrganizationSettingsProvider(
      organizationId: organizationId,
      settings: settings,
    );
  }

  @override
  UpdateOrganizationSettingsProvider getProviderOverride(
    covariant UpdateOrganizationSettingsProvider provider,
  ) {
    return call(
      organizationId: provider.organizationId,
      settings: provider.settings,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'updateOrganizationSettingsProvider';
}

/// See also [updateOrganizationSettings].
class UpdateOrganizationSettingsProvider
    extends AutoDisposeFutureProvider<OrganizationModel> {
  /// See also [updateOrganizationSettings].
  UpdateOrganizationSettingsProvider({
    required String organizationId,
    required Map<String, dynamic> settings,
  }) : this._internal(
         (ref) => updateOrganizationSettings(
           ref as UpdateOrganizationSettingsRef,
           organizationId: organizationId,
           settings: settings,
         ),
         from: updateOrganizationSettingsProvider,
         name: r'updateOrganizationSettingsProvider',
         debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
             ? null
             : _$updateOrganizationSettingsHash,
         dependencies: UpdateOrganizationSettingsFamily._dependencies,
         allTransitiveDependencies:
             UpdateOrganizationSettingsFamily._allTransitiveDependencies,
         organizationId: organizationId,
         settings: settings,
       );

  UpdateOrganizationSettingsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.organizationId,
    required this.settings,
  }) : super.internal();

  final String organizationId;
  final Map<String, dynamic> settings;

  @override
  Override overrideWith(
    FutureOr<OrganizationModel> Function(UpdateOrganizationSettingsRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: UpdateOrganizationSettingsProvider._internal(
        (ref) => create(ref as UpdateOrganizationSettingsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        organizationId: organizationId,
        settings: settings,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<OrganizationModel> createElement() {
    return _UpdateOrganizationSettingsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UpdateOrganizationSettingsProvider &&
        other.organizationId == organizationId &&
        other.settings == settings;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, organizationId.hashCode);
    hash = _SystemHash.combine(hash, settings.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin UpdateOrganizationSettingsRef
    on AutoDisposeFutureProviderRef<OrganizationModel> {
  /// The parameter `organizationId` of this provider.
  String get organizationId;

  /// The parameter `settings` of this provider.
  Map<String, dynamic> get settings;
}

class _UpdateOrganizationSettingsProviderElement
    extends AutoDisposeFutureProviderElement<OrganizationModel>
    with UpdateOrganizationSettingsRef {
  _UpdateOrganizationSettingsProviderElement(super.provider);

  @override
  String get organizationId =>
      (origin as UpdateOrganizationSettingsProvider).organizationId;
  @override
  Map<String, dynamic> get settings =>
      (origin as UpdateOrganizationSettingsProvider).settings;
}

String _$deleteOrganizationHash() =>
    r'2c2d7ec1198ff9cc3a881da8b804e2b16c57a6ac';

/// See also [deleteOrganization].
@ProviderFor(deleteOrganization)
const deleteOrganizationProvider = DeleteOrganizationFamily();

/// See also [deleteOrganization].
class DeleteOrganizationFamily extends Family<AsyncValue<void>> {
  /// See also [deleteOrganization].
  const DeleteOrganizationFamily();

  /// See also [deleteOrganization].
  DeleteOrganizationProvider call(String organizationId) {
    return DeleteOrganizationProvider(organizationId);
  }

  @override
  DeleteOrganizationProvider getProviderOverride(
    covariant DeleteOrganizationProvider provider,
  ) {
    return call(provider.organizationId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'deleteOrganizationProvider';
}

/// See also [deleteOrganization].
class DeleteOrganizationProvider extends AutoDisposeFutureProvider<void> {
  /// See also [deleteOrganization].
  DeleteOrganizationProvider(String organizationId)
    : this._internal(
        (ref) =>
            deleteOrganization(ref as DeleteOrganizationRef, organizationId),
        from: deleteOrganizationProvider,
        name: r'deleteOrganizationProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$deleteOrganizationHash,
        dependencies: DeleteOrganizationFamily._dependencies,
        allTransitiveDependencies:
            DeleteOrganizationFamily._allTransitiveDependencies,
        organizationId: organizationId,
      );

  DeleteOrganizationProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.organizationId,
  }) : super.internal();

  final String organizationId;

  @override
  Override overrideWith(
    FutureOr<void> Function(DeleteOrganizationRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: DeleteOrganizationProvider._internal(
        (ref) => create(ref as DeleteOrganizationRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        organizationId: organizationId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<void> createElement() {
    return _DeleteOrganizationProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is DeleteOrganizationProvider &&
        other.organizationId == organizationId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, organizationId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin DeleteOrganizationRef on AutoDisposeFutureProviderRef<void> {
  /// The parameter `organizationId` of this provider.
  String get organizationId;
}

class _DeleteOrganizationProviderElement
    extends AutoDisposeFutureProviderElement<void>
    with DeleteOrganizationRef {
  _DeleteOrganizationProviderElement(super.provider);

  @override
  String get organizationId =>
      (origin as DeleteOrganizationProvider).organizationId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
