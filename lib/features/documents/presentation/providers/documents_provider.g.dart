// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'documents_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$documentsListHash() => r'14644504f63a5bdb9fc88d202bd61b5f6151e700';

/// See also [documentsList].
@ProviderFor(documentsList)
final documentsListProvider = AutoDisposeFutureProvider<List<Content>>.internal(
  documentsList,
  name: r'documentsListProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$documentsListHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DocumentsListRef = AutoDisposeFutureProviderRef<List<Content>>;
String _$documentsStatisticsHash() =>
    r'19c1d58586b151d9bcc176a3957f4c450a1ea967';

/// See also [documentsStatistics].
@ProviderFor(documentsStatistics)
final documentsStatisticsProvider =
    AutoDisposeFutureProvider<Map<String, int>>.internal(
      documentsStatistics,
      name: r'documentsStatisticsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$documentsStatisticsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DocumentsStatisticsRef = AutoDisposeFutureProviderRef<Map<String, int>>;
String _$filteredDocumentsHash() => r'6511088daa78394db7de186cf9ace42f0ec3d8ba';

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

/// See also [filteredDocuments].
@ProviderFor(filteredDocuments)
const filteredDocumentsProvider = FilteredDocumentsFamily();

/// See also [filteredDocuments].
class FilteredDocumentsFamily extends Family<AsyncValue<List<Content>>> {
  /// See also [filteredDocuments].
  const FilteredDocumentsFamily();

  /// See also [filteredDocuments].
  FilteredDocumentsProvider call({
    ContentType? filterType,
    String searchQuery = '',
    String sortBy = 'recent',
  }) {
    return FilteredDocumentsProvider(
      filterType: filterType,
      searchQuery: searchQuery,
      sortBy: sortBy,
    );
  }

  @override
  FilteredDocumentsProvider getProviderOverride(
    covariant FilteredDocumentsProvider provider,
  ) {
    return call(
      filterType: provider.filterType,
      searchQuery: provider.searchQuery,
      sortBy: provider.sortBy,
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
  String? get name => r'filteredDocumentsProvider';
}

/// See also [filteredDocuments].
class FilteredDocumentsProvider
    extends AutoDisposeFutureProvider<List<Content>> {
  /// See also [filteredDocuments].
  FilteredDocumentsProvider({
    ContentType? filterType,
    String searchQuery = '',
    String sortBy = 'recent',
  }) : this._internal(
         (ref) => filteredDocuments(
           ref as FilteredDocumentsRef,
           filterType: filterType,
           searchQuery: searchQuery,
           sortBy: sortBy,
         ),
         from: filteredDocumentsProvider,
         name: r'filteredDocumentsProvider',
         debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
             ? null
             : _$filteredDocumentsHash,
         dependencies: FilteredDocumentsFamily._dependencies,
         allTransitiveDependencies:
             FilteredDocumentsFamily._allTransitiveDependencies,
         filterType: filterType,
         searchQuery: searchQuery,
         sortBy: sortBy,
       );

  FilteredDocumentsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.filterType,
    required this.searchQuery,
    required this.sortBy,
  }) : super.internal();

  final ContentType? filterType;
  final String searchQuery;
  final String sortBy;

  @override
  Override overrideWith(
    FutureOr<List<Content>> Function(FilteredDocumentsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: FilteredDocumentsProvider._internal(
        (ref) => create(ref as FilteredDocumentsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        filterType: filterType,
        searchQuery: searchQuery,
        sortBy: sortBy,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<Content>> createElement() {
    return _FilteredDocumentsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FilteredDocumentsProvider &&
        other.filterType == filterType &&
        other.searchQuery == searchQuery &&
        other.sortBy == sortBy;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, filterType.hashCode);
    hash = _SystemHash.combine(hash, searchQuery.hashCode);
    hash = _SystemHash.combine(hash, sortBy.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin FilteredDocumentsRef on AutoDisposeFutureProviderRef<List<Content>> {
  /// The parameter `filterType` of this provider.
  ContentType? get filterType;

  /// The parameter `searchQuery` of this provider.
  String get searchQuery;

  /// The parameter `sortBy` of this provider.
  String get sortBy;
}

class _FilteredDocumentsProviderElement
    extends AutoDisposeFutureProviderElement<List<Content>>
    with FilteredDocumentsRef {
  _FilteredDocumentsProviderElement(super.provider);

  @override
  ContentType? get filterType =>
      (origin as FilteredDocumentsProvider).filterType;
  @override
  String get searchQuery => (origin as FilteredDocumentsProvider).searchQuery;
  @override
  String get sortBy => (origin as FilteredDocumentsProvider).sortBy;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
