// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meetings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$meetingsListHash() => r'7b7b9a6a1bf3dd52b1d50d73c11c2bcbebcbac6a';

/// See also [meetingsList].
@ProviderFor(meetingsList)
final meetingsListProvider = AutoDisposeFutureProvider<List<Content>>.internal(
  meetingsList,
  name: r'meetingsListProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$meetingsListHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MeetingsListRef = AutoDisposeFutureProviderRef<List<Content>>;
String _$filteredMeetingsHash() => r'4a5439ae9c8e9102d0b268d6b639f3337e42e4d9';

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

/// See also [filteredMeetings].
@ProviderFor(filteredMeetings)
const filteredMeetingsProvider = FilteredMeetingsFamily();

/// See also [filteredMeetings].
class FilteredMeetingsFamily extends Family<AsyncValue<List<Content>>> {
  /// See also [filteredMeetings].
  const FilteredMeetingsFamily();

  /// See also [filteredMeetings].
  FilteredMeetingsProvider call({
    ContentType? filterType,
    String searchQuery = '',
  }) {
    return FilteredMeetingsProvider(
      filterType: filterType,
      searchQuery: searchQuery,
    );
  }

  @override
  FilteredMeetingsProvider getProviderOverride(
    covariant FilteredMeetingsProvider provider,
  ) {
    return call(
      filterType: provider.filterType,
      searchQuery: provider.searchQuery,
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
  String? get name => r'filteredMeetingsProvider';
}

/// See also [filteredMeetings].
class FilteredMeetingsProvider
    extends AutoDisposeFutureProvider<List<Content>> {
  /// See also [filteredMeetings].
  FilteredMeetingsProvider({ContentType? filterType, String searchQuery = ''})
    : this._internal(
        (ref) => filteredMeetings(
          ref as FilteredMeetingsRef,
          filterType: filterType,
          searchQuery: searchQuery,
        ),
        from: filteredMeetingsProvider,
        name: r'filteredMeetingsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$filteredMeetingsHash,
        dependencies: FilteredMeetingsFamily._dependencies,
        allTransitiveDependencies:
            FilteredMeetingsFamily._allTransitiveDependencies,
        filterType: filterType,
        searchQuery: searchQuery,
      );

  FilteredMeetingsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.filterType,
    required this.searchQuery,
  }) : super.internal();

  final ContentType? filterType;
  final String searchQuery;

  @override
  Override overrideWith(
    FutureOr<List<Content>> Function(FilteredMeetingsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: FilteredMeetingsProvider._internal(
        (ref) => create(ref as FilteredMeetingsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        filterType: filterType,
        searchQuery: searchQuery,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<Content>> createElement() {
    return _FilteredMeetingsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FilteredMeetingsProvider &&
        other.filterType == filterType &&
        other.searchQuery == searchQuery;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, filterType.hashCode);
    hash = _SystemHash.combine(hash, searchQuery.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin FilteredMeetingsRef on AutoDisposeFutureProviderRef<List<Content>> {
  /// The parameter `filterType` of this provider.
  ContentType? get filterType;

  /// The parameter `searchQuery` of this provider.
  String get searchQuery;
}

class _FilteredMeetingsProviderElement
    extends AutoDisposeFutureProviderElement<List<Content>>
    with FilteredMeetingsRef {
  _FilteredMeetingsProviderElement(super.provider);

  @override
  ContentType? get filterType =>
      (origin as FilteredMeetingsProvider).filterType;
  @override
  String get searchQuery => (origin as FilteredMeetingsProvider).searchQuery;
}

String _$meetingDetailHash() => r'6c871723a78d54c42ca2efba76217b8a42dcd1db';

/// See also [meetingDetail].
@ProviderFor(meetingDetail)
const meetingDetailProvider = MeetingDetailFamily();

/// See also [meetingDetail].
class MeetingDetailFamily extends Family<AsyncValue<Content?>> {
  /// See also [meetingDetail].
  const MeetingDetailFamily();

  /// See also [meetingDetail].
  MeetingDetailProvider call(String contentId) {
    return MeetingDetailProvider(contentId);
  }

  @override
  MeetingDetailProvider getProviderOverride(
    covariant MeetingDetailProvider provider,
  ) {
    return call(provider.contentId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'meetingDetailProvider';
}

/// See also [meetingDetail].
class MeetingDetailProvider extends AutoDisposeFutureProvider<Content?> {
  /// See also [meetingDetail].
  MeetingDetailProvider(String contentId)
    : this._internal(
        (ref) => meetingDetail(ref as MeetingDetailRef, contentId),
        from: meetingDetailProvider,
        name: r'meetingDetailProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$meetingDetailHash,
        dependencies: MeetingDetailFamily._dependencies,
        allTransitiveDependencies:
            MeetingDetailFamily._allTransitiveDependencies,
        contentId: contentId,
      );

  MeetingDetailProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.contentId,
  }) : super.internal();

  final String contentId;

  @override
  Override overrideWith(
    FutureOr<Content?> Function(MeetingDetailRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: MeetingDetailProvider._internal(
        (ref) => create(ref as MeetingDetailRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        contentId: contentId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Content?> createElement() {
    return _MeetingDetailProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is MeetingDetailProvider && other.contentId == contentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, contentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin MeetingDetailRef on AutoDisposeFutureProviderRef<Content?> {
  /// The parameter `contentId` of this provider.
  String get contentId;
}

class _MeetingDetailProviderElement
    extends AutoDisposeFutureProviderElement<Content?>
    with MeetingDetailRef {
  _MeetingDetailProviderElement(super.provider);

  @override
  String get contentId => (origin as MeetingDetailProvider).contentId;
}

String _$meetingsStatisticsHash() =>
    r'f48795b54aae7a1daaf1cc25678571e36a6b2fd6';

/// See also [meetingsStatistics].
@ProviderFor(meetingsStatistics)
final meetingsStatisticsProvider =
    AutoDisposeFutureProvider<Map<String, int>>.internal(
      meetingsStatistics,
      name: r'meetingsStatisticsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$meetingsStatisticsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MeetingsStatisticsRef = AutoDisposeFutureProviderRef<Map<String, int>>;
String _$meetingsFilterHash() => r'c4b0fe07ef0704874f1c65fdac061fc3067f827d';

/// See also [MeetingsFilter].
@ProviderFor(MeetingsFilter)
final meetingsFilterProvider =
    AutoDisposeNotifierProvider<
      MeetingsFilter,
      ({ContentType? type, String searchQuery})
    >.internal(
      MeetingsFilter.new,
      name: r'meetingsFilterProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$meetingsFilterHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$MeetingsFilter =
    AutoDisposeNotifier<({ContentType? type, String searchQuery})>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
