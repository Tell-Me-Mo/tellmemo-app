// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'document_detail_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$documentDetailHash() => r'0d7076b5e465397ad39331c2c1ebd01fd1792bac';

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

/// See also [documentDetail].
@ProviderFor(documentDetail)
const documentDetailProvider = DocumentDetailFamily();

/// See also [documentDetail].
class DocumentDetailFamily extends Family<AsyncValue<Map<String, dynamic>?>> {
  /// See also [documentDetail].
  const DocumentDetailFamily();

  /// See also [documentDetail].
  DocumentDetailProvider call({
    required String projectId,
    required String contentId,
  }) {
    return DocumentDetailProvider(projectId: projectId, contentId: contentId);
  }

  @override
  DocumentDetailProvider getProviderOverride(
    covariant DocumentDetailProvider provider,
  ) {
    return call(projectId: provider.projectId, contentId: provider.contentId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'documentDetailProvider';
}

/// See also [documentDetail].
class DocumentDetailProvider
    extends AutoDisposeFutureProvider<Map<String, dynamic>?> {
  /// See also [documentDetail].
  DocumentDetailProvider({required String projectId, required String contentId})
    : this._internal(
        (ref) => documentDetail(
          ref as DocumentDetailRef,
          projectId: projectId,
          contentId: contentId,
        ),
        from: documentDetailProvider,
        name: r'documentDetailProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$documentDetailHash,
        dependencies: DocumentDetailFamily._dependencies,
        allTransitiveDependencies:
            DocumentDetailFamily._allTransitiveDependencies,
        projectId: projectId,
        contentId: contentId,
      );

  DocumentDetailProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.projectId,
    required this.contentId,
  }) : super.internal();

  final String projectId;
  final String contentId;

  @override
  Override overrideWith(
    FutureOr<Map<String, dynamic>?> Function(DocumentDetailRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: DocumentDetailProvider._internal(
        (ref) => create(ref as DocumentDetailRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        projectId: projectId,
        contentId: contentId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Map<String, dynamic>?> createElement() {
    return _DocumentDetailProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is DocumentDetailProvider &&
        other.projectId == projectId &&
        other.contentId == contentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, projectId.hashCode);
    hash = _SystemHash.combine(hash, contentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin DocumentDetailRef on AutoDisposeFutureProviderRef<Map<String, dynamic>?> {
  /// The parameter `projectId` of this provider.
  String get projectId;

  /// The parameter `contentId` of this provider.
  String get contentId;
}

class _DocumentDetailProviderElement
    extends AutoDisposeFutureProviderElement<Map<String, dynamic>?>
    with DocumentDetailRef {
  _DocumentDetailProviderElement(super.provider);

  @override
  String get projectId => (origin as DocumentDetailProvider).projectId;
  @override
  String get contentId => (origin as DocumentDetailProvider).contentId;
}

String _$documentSummaryHash() => r'11b5ae4dff8bf6d2bbfb57ef9dd4d0435fa0f5a9';

/// See also [documentSummary].
@ProviderFor(documentSummary)
const documentSummaryProvider = DocumentSummaryFamily();

/// See also [documentSummary].
class DocumentSummaryFamily extends Family<AsyncValue<Map<String, dynamic>?>> {
  /// See also [documentSummary].
  const DocumentSummaryFamily();

  /// See also [documentSummary].
  DocumentSummaryProvider call({
    required String projectId,
    required String contentId,
  }) {
    return DocumentSummaryProvider(projectId: projectId, contentId: contentId);
  }

  @override
  DocumentSummaryProvider getProviderOverride(
    covariant DocumentSummaryProvider provider,
  ) {
    return call(projectId: provider.projectId, contentId: provider.contentId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'documentSummaryProvider';
}

/// See also [documentSummary].
class DocumentSummaryProvider
    extends AutoDisposeFutureProvider<Map<String, dynamic>?> {
  /// See also [documentSummary].
  DocumentSummaryProvider({
    required String projectId,
    required String contentId,
  }) : this._internal(
         (ref) => documentSummary(
           ref as DocumentSummaryRef,
           projectId: projectId,
           contentId: contentId,
         ),
         from: documentSummaryProvider,
         name: r'documentSummaryProvider',
         debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
             ? null
             : _$documentSummaryHash,
         dependencies: DocumentSummaryFamily._dependencies,
         allTransitiveDependencies:
             DocumentSummaryFamily._allTransitiveDependencies,
         projectId: projectId,
         contentId: contentId,
       );

  DocumentSummaryProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.projectId,
    required this.contentId,
  }) : super.internal();

  final String projectId;
  final String contentId;

  @override
  Override overrideWith(
    FutureOr<Map<String, dynamic>?> Function(DocumentSummaryRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: DocumentSummaryProvider._internal(
        (ref) => create(ref as DocumentSummaryRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        projectId: projectId,
        contentId: contentId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Map<String, dynamic>?> createElement() {
    return _DocumentSummaryProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is DocumentSummaryProvider &&
        other.projectId == projectId &&
        other.contentId == contentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, projectId.hashCode);
    hash = _SystemHash.combine(hash, contentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin DocumentSummaryRef
    on AutoDisposeFutureProviderRef<Map<String, dynamic>?> {
  /// The parameter `projectId` of this provider.
  String get projectId;

  /// The parameter `contentId` of this provider.
  String get contentId;
}

class _DocumentSummaryProviderElement
    extends AutoDisposeFutureProviderElement<Map<String, dynamic>?>
    with DocumentSummaryRef {
  _DocumentSummaryProviderElement(super.provider);

  @override
  String get projectId => (origin as DocumentSummaryProvider).projectId;
  @override
  String get contentId => (origin as DocumentSummaryProvider).contentId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
