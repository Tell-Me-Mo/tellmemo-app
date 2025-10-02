// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hierarchy_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$hierarchyApiServiceHash() =>
    r'ad3572dcf98370c3a4e4e04248104e640894e835';

/// See also [hierarchyApiService].
@ProviderFor(hierarchyApiService)
final hierarchyApiServiceProvider =
    AutoDisposeProvider<HierarchyApiService>.internal(
      hierarchyApiService,
      name: r'hierarchyApiServiceProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$hierarchyApiServiceHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef HierarchyApiServiceRef = AutoDisposeProviderRef<HierarchyApiService>;
String _$hierarchyRepositoryHash() =>
    r'68676199f63c5becd71b263a7d240a41e62bf64c';

/// See also [hierarchyRepository].
@ProviderFor(hierarchyRepository)
final hierarchyRepositoryProvider =
    AutoDisposeProvider<HierarchyRepository>.internal(
      hierarchyRepository,
      name: r'hierarchyRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$hierarchyRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef HierarchyRepositoryRef = AutoDisposeProviderRef<HierarchyRepository>;
String _$portfolioHash() => r'cdd191aa33031c66c242e1c2830b1c544e448fb7';

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

/// See also [portfolio].
@ProviderFor(portfolio)
const portfolioProvider = PortfolioFamily();

/// See also [portfolio].
class PortfolioFamily extends Family<AsyncValue<Portfolio?>> {
  /// See also [portfolio].
  const PortfolioFamily();

  /// See also [portfolio].
  PortfolioProvider call(String portfolioId) {
    return PortfolioProvider(portfolioId);
  }

  @override
  PortfolioProvider getProviderOverride(covariant PortfolioProvider provider) {
    return call(provider.portfolioId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'portfolioProvider';
}

/// See also [portfolio].
class PortfolioProvider extends AutoDisposeFutureProvider<Portfolio?> {
  /// See also [portfolio].
  PortfolioProvider(String portfolioId)
    : this._internal(
        (ref) => portfolio(ref as PortfolioRef, portfolioId),
        from: portfolioProvider,
        name: r'portfolioProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$portfolioHash,
        dependencies: PortfolioFamily._dependencies,
        allTransitiveDependencies: PortfolioFamily._allTransitiveDependencies,
        portfolioId: portfolioId,
      );

  PortfolioProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.portfolioId,
  }) : super.internal();

  final String portfolioId;

  @override
  Override overrideWith(
    FutureOr<Portfolio?> Function(PortfolioRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PortfolioProvider._internal(
        (ref) => create(ref as PortfolioRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        portfolioId: portfolioId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Portfolio?> createElement() {
    return _PortfolioProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PortfolioProvider && other.portfolioId == portfolioId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, portfolioId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin PortfolioRef on AutoDisposeFutureProviderRef<Portfolio?> {
  /// The parameter `portfolioId` of this provider.
  String get portfolioId;
}

class _PortfolioProviderElement
    extends AutoDisposeFutureProviderElement<Portfolio?>
    with PortfolioRef {
  _PortfolioProviderElement(super.provider);

  @override
  String get portfolioId => (origin as PortfolioProvider).portfolioId;
}

String _$portfolioStatisticsHash() =>
    r'4aa57763ffb1eb4f6253180316f8cc614817f3c9';

/// See also [portfolioStatistics].
@ProviderFor(portfolioStatistics)
const portfolioStatisticsProvider = PortfolioStatisticsFamily();

/// See also [portfolioStatistics].
class PortfolioStatisticsFamily
    extends Family<AsyncValue<Map<String, dynamic>>> {
  /// See also [portfolioStatistics].
  const PortfolioStatisticsFamily();

  /// See also [portfolioStatistics].
  PortfolioStatisticsProvider call(String portfolioId) {
    return PortfolioStatisticsProvider(portfolioId);
  }

  @override
  PortfolioStatisticsProvider getProviderOverride(
    covariant PortfolioStatisticsProvider provider,
  ) {
    return call(provider.portfolioId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'portfolioStatisticsProvider';
}

/// See also [portfolioStatistics].
class PortfolioStatisticsProvider
    extends AutoDisposeFutureProvider<Map<String, dynamic>> {
  /// See also [portfolioStatistics].
  PortfolioStatisticsProvider(String portfolioId)
    : this._internal(
        (ref) =>
            portfolioStatistics(ref as PortfolioStatisticsRef, portfolioId),
        from: portfolioStatisticsProvider,
        name: r'portfolioStatisticsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$portfolioStatisticsHash,
        dependencies: PortfolioStatisticsFamily._dependencies,
        allTransitiveDependencies:
            PortfolioStatisticsFamily._allTransitiveDependencies,
        portfolioId: portfolioId,
      );

  PortfolioStatisticsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.portfolioId,
  }) : super.internal();

  final String portfolioId;

  @override
  Override overrideWith(
    FutureOr<Map<String, dynamic>> Function(PortfolioStatisticsRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PortfolioStatisticsProvider._internal(
        (ref) => create(ref as PortfolioStatisticsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        portfolioId: portfolioId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Map<String, dynamic>> createElement() {
    return _PortfolioStatisticsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PortfolioStatisticsProvider &&
        other.portfolioId == portfolioId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, portfolioId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin PortfolioStatisticsRef
    on AutoDisposeFutureProviderRef<Map<String, dynamic>> {
  /// The parameter `portfolioId` of this provider.
  String get portfolioId;
}

class _PortfolioStatisticsProviderElement
    extends AutoDisposeFutureProviderElement<Map<String, dynamic>>
    with PortfolioStatisticsRef {
  _PortfolioStatisticsProviderElement(super.provider);

  @override
  String get portfolioId => (origin as PortfolioStatisticsProvider).portfolioId;
}

String _$programHash() => r'a14182ae581caf37b1c64bc6b4aefb1a8d29514f';

/// See also [program].
@ProviderFor(program)
const programProvider = ProgramFamily();

/// See also [program].
class ProgramFamily extends Family<AsyncValue<Program?>> {
  /// See also [program].
  const ProgramFamily();

  /// See also [program].
  ProgramProvider call(String programId) {
    return ProgramProvider(programId);
  }

  @override
  ProgramProvider getProviderOverride(covariant ProgramProvider provider) {
    return call(provider.programId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'programProvider';
}

/// See also [program].
class ProgramProvider extends AutoDisposeFutureProvider<Program?> {
  /// See also [program].
  ProgramProvider(String programId)
    : this._internal(
        (ref) => program(ref as ProgramRef, programId),
        from: programProvider,
        name: r'programProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$programHash,
        dependencies: ProgramFamily._dependencies,
        allTransitiveDependencies: ProgramFamily._allTransitiveDependencies,
        programId: programId,
      );

  ProgramProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.programId,
  }) : super.internal();

  final String programId;

  @override
  Override overrideWith(
    FutureOr<Program?> Function(ProgramRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ProgramProvider._internal(
        (ref) => create(ref as ProgramRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        programId: programId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Program?> createElement() {
    return _ProgramProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ProgramProvider && other.programId == programId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, programId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ProgramRef on AutoDisposeFutureProviderRef<Program?> {
  /// The parameter `programId` of this provider.
  String get programId;
}

class _ProgramProviderElement extends AutoDisposeFutureProviderElement<Program?>
    with ProgramRef {
  _ProgramProviderElement(super.provider);

  @override
  String get programId => (origin as ProgramProvider).programId;
}

String _$programStatisticsHash() => r'ab75d37272fc0d1762922ef12eaac772fbd70679';

/// See also [programStatistics].
@ProviderFor(programStatistics)
const programStatisticsProvider = ProgramStatisticsFamily();

/// See also [programStatistics].
class ProgramStatisticsFamily extends Family<AsyncValue<Map<String, dynamic>>> {
  /// See also [programStatistics].
  const ProgramStatisticsFamily();

  /// See also [programStatistics].
  ProgramStatisticsProvider call(String programId) {
    return ProgramStatisticsProvider(programId);
  }

  @override
  ProgramStatisticsProvider getProviderOverride(
    covariant ProgramStatisticsProvider provider,
  ) {
    return call(provider.programId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'programStatisticsProvider';
}

/// See also [programStatistics].
class ProgramStatisticsProvider
    extends AutoDisposeFutureProvider<Map<String, dynamic>> {
  /// See also [programStatistics].
  ProgramStatisticsProvider(String programId)
    : this._internal(
        (ref) => programStatistics(ref as ProgramStatisticsRef, programId),
        from: programStatisticsProvider,
        name: r'programStatisticsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$programStatisticsHash,
        dependencies: ProgramStatisticsFamily._dependencies,
        allTransitiveDependencies:
            ProgramStatisticsFamily._allTransitiveDependencies,
        programId: programId,
      );

  ProgramStatisticsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.programId,
  }) : super.internal();

  final String programId;

  @override
  Override overrideWith(
    FutureOr<Map<String, dynamic>> Function(ProgramStatisticsRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ProgramStatisticsProvider._internal(
        (ref) => create(ref as ProgramStatisticsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        programId: programId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Map<String, dynamic>> createElement() {
    return _ProgramStatisticsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ProgramStatisticsProvider && other.programId == programId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, programId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ProgramStatisticsRef
    on AutoDisposeFutureProviderRef<Map<String, dynamic>> {
  /// The parameter `programId` of this provider.
  String get programId;
}

class _ProgramStatisticsProviderElement
    extends AutoDisposeFutureProviderElement<Map<String, dynamic>>
    with ProgramStatisticsRef {
  _ProgramStatisticsProviderElement(super.provider);

  @override
  String get programId => (origin as ProgramStatisticsProvider).programId;
}

String _$hierarchyPathHash() => r'5a082067a265cfe488eee56b1c7b0710fde65844';

/// See also [hierarchyPath].
@ProviderFor(hierarchyPath)
const hierarchyPathProvider = HierarchyPathFamily();

/// See also [hierarchyPath].
class HierarchyPathFamily
    extends Family<AsyncValue<List<HierarchyBreadcrumb>>> {
  /// See also [hierarchyPath].
  const HierarchyPathFamily();

  /// See also [hierarchyPath].
  HierarchyPathProvider call(String itemId, String itemType) {
    return HierarchyPathProvider(itemId, itemType);
  }

  @override
  HierarchyPathProvider getProviderOverride(
    covariant HierarchyPathProvider provider,
  ) {
    return call(provider.itemId, provider.itemType);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'hierarchyPathProvider';
}

/// See also [hierarchyPath].
class HierarchyPathProvider
    extends AutoDisposeFutureProvider<List<HierarchyBreadcrumb>> {
  /// See also [hierarchyPath].
  HierarchyPathProvider(String itemId, String itemType)
    : this._internal(
        (ref) => hierarchyPath(ref as HierarchyPathRef, itemId, itemType),
        from: hierarchyPathProvider,
        name: r'hierarchyPathProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$hierarchyPathHash,
        dependencies: HierarchyPathFamily._dependencies,
        allTransitiveDependencies:
            HierarchyPathFamily._allTransitiveDependencies,
        itemId: itemId,
        itemType: itemType,
      );

  HierarchyPathProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.itemId,
    required this.itemType,
  }) : super.internal();

  final String itemId;
  final String itemType;

  @override
  Override overrideWith(
    FutureOr<List<HierarchyBreadcrumb>> Function(HierarchyPathRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: HierarchyPathProvider._internal(
        (ref) => create(ref as HierarchyPathRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        itemId: itemId,
        itemType: itemType,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<HierarchyBreadcrumb>> createElement() {
    return _HierarchyPathProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is HierarchyPathProvider &&
        other.itemId == itemId &&
        other.itemType == itemType;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, itemId.hashCode);
    hash = _SystemHash.combine(hash, itemType.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin HierarchyPathRef
    on AutoDisposeFutureProviderRef<List<HierarchyBreadcrumb>> {
  /// The parameter `itemId` of this provider.
  String get itemId;

  /// The parameter `itemType` of this provider.
  String get itemType;
}

class _HierarchyPathProviderElement
    extends AutoDisposeFutureProviderElement<List<HierarchyBreadcrumb>>
    with HierarchyPathRef {
  _HierarchyPathProviderElement(super.provider);

  @override
  String get itemId => (origin as HierarchyPathProvider).itemId;
  @override
  String get itemType => (origin as HierarchyPathProvider).itemType;
}

String _$hierarchyStatisticsHash() =>
    r'02e53fafa3e92657fca5f92559e4cf8a795fc887';

/// See also [hierarchyStatistics].
@ProviderFor(hierarchyStatistics)
final hierarchyStatisticsProvider =
    AutoDisposeFutureProvider<Map<String, dynamic>>.internal(
      hierarchyStatistics,
      name: r'hierarchyStatisticsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$hierarchyStatisticsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef HierarchyStatisticsRef =
    AutoDisposeFutureProviderRef<Map<String, dynamic>>;
String _$hierarchyStateHash() => r'b9a9a246e75da66c58b8767a45c020adfae92c35';

abstract class _$HierarchyState
    extends BuildlessAutoDisposeAsyncNotifier<List<HierarchyItem>> {
  late final bool includeArchived;

  FutureOr<List<HierarchyItem>> build({bool includeArchived = false});
}

/// See also [HierarchyState].
@ProviderFor(HierarchyState)
const hierarchyStateProvider = HierarchyStateFamily();

/// See also [HierarchyState].
class HierarchyStateFamily extends Family<AsyncValue<List<HierarchyItem>>> {
  /// See also [HierarchyState].
  const HierarchyStateFamily();

  /// See also [HierarchyState].
  HierarchyStateProvider call({bool includeArchived = false}) {
    return HierarchyStateProvider(includeArchived: includeArchived);
  }

  @override
  HierarchyStateProvider getProviderOverride(
    covariant HierarchyStateProvider provider,
  ) {
    return call(includeArchived: provider.includeArchived);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'hierarchyStateProvider';
}

/// See also [HierarchyState].
class HierarchyStateProvider
    extends
        AutoDisposeAsyncNotifierProviderImpl<
          HierarchyState,
          List<HierarchyItem>
        > {
  /// See also [HierarchyState].
  HierarchyStateProvider({bool includeArchived = false})
    : this._internal(
        () => HierarchyState()..includeArchived = includeArchived,
        from: hierarchyStateProvider,
        name: r'hierarchyStateProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$hierarchyStateHash,
        dependencies: HierarchyStateFamily._dependencies,
        allTransitiveDependencies:
            HierarchyStateFamily._allTransitiveDependencies,
        includeArchived: includeArchived,
      );

  HierarchyStateProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.includeArchived,
  }) : super.internal();

  final bool includeArchived;

  @override
  FutureOr<List<HierarchyItem>> runNotifierBuild(
    covariant HierarchyState notifier,
  ) {
    return notifier.build(includeArchived: includeArchived);
  }

  @override
  Override overrideWith(HierarchyState Function() create) {
    return ProviderOverride(
      origin: this,
      override: HierarchyStateProvider._internal(
        () => create()..includeArchived = includeArchived,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        includeArchived: includeArchived,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<HierarchyState, List<HierarchyItem>>
  createElement() {
    return _HierarchyStateProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is HierarchyStateProvider &&
        other.includeArchived == includeArchived;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, includeArchived.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin HierarchyStateRef
    on AutoDisposeAsyncNotifierProviderRef<List<HierarchyItem>> {
  /// The parameter `includeArchived` of this provider.
  bool get includeArchived;
}

class _HierarchyStateProviderElement
    extends
        AutoDisposeAsyncNotifierProviderElement<
          HierarchyState,
          List<HierarchyItem>
        >
    with HierarchyStateRef {
  _HierarchyStateProviderElement(super.provider);

  @override
  bool get includeArchived =>
      (origin as HierarchyStateProvider).includeArchived;
}

String _$portfolioListHash() => r'a16625136244795b33feb537ba1f817d64b0b837';

/// See also [PortfolioList].
@ProviderFor(PortfolioList)
final portfolioListProvider =
    AutoDisposeAsyncNotifierProvider<PortfolioList, List<Portfolio>>.internal(
      PortfolioList.new,
      name: r'portfolioListProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$portfolioListHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$PortfolioList = AutoDisposeAsyncNotifier<List<Portfolio>>;
String _$programListHash() => r'fc9935dd409db5e1c0d82b81d745e88bbf9c9af7';

abstract class _$ProgramList
    extends BuildlessAutoDisposeAsyncNotifier<List<Program>> {
  late final String? portfolioId;

  FutureOr<List<Program>> build({String? portfolioId});
}

/// See also [ProgramList].
@ProviderFor(ProgramList)
const programListProvider = ProgramListFamily();

/// See also [ProgramList].
class ProgramListFamily extends Family<AsyncValue<List<Program>>> {
  /// See also [ProgramList].
  const ProgramListFamily();

  /// See also [ProgramList].
  ProgramListProvider call({String? portfolioId}) {
    return ProgramListProvider(portfolioId: portfolioId);
  }

  @override
  ProgramListProvider getProviderOverride(
    covariant ProgramListProvider provider,
  ) {
    return call(portfolioId: provider.portfolioId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'programListProvider';
}

/// See also [ProgramList].
class ProgramListProvider
    extends AutoDisposeAsyncNotifierProviderImpl<ProgramList, List<Program>> {
  /// See also [ProgramList].
  ProgramListProvider({String? portfolioId})
    : this._internal(
        () => ProgramList()..portfolioId = portfolioId,
        from: programListProvider,
        name: r'programListProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$programListHash,
        dependencies: ProgramListFamily._dependencies,
        allTransitiveDependencies: ProgramListFamily._allTransitiveDependencies,
        portfolioId: portfolioId,
      );

  ProgramListProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.portfolioId,
  }) : super.internal();

  final String? portfolioId;

  @override
  FutureOr<List<Program>> runNotifierBuild(covariant ProgramList notifier) {
    return notifier.build(portfolioId: portfolioId);
  }

  @override
  Override overrideWith(ProgramList Function() create) {
    return ProviderOverride(
      origin: this,
      override: ProgramListProvider._internal(
        () => create()..portfolioId = portfolioId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        portfolioId: portfolioId,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<ProgramList, List<Program>>
  createElement() {
    return _ProgramListProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ProgramListProvider && other.portfolioId == portfolioId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, portfolioId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ProgramListRef on AutoDisposeAsyncNotifierProviderRef<List<Program>> {
  /// The parameter `portfolioId` of this provider.
  String? get portfolioId;
}

class _ProgramListProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<ProgramList, List<Program>>
    with ProgramListRef {
  _ProgramListProviderElement(super.provider);

  @override
  String? get portfolioId => (origin as ProgramListProvider).portfolioId;
}

String _$hierarchySelectionHash() =>
    r'6c8ffc666ac3ebe5b077da178df0d5702bb60600';

/// See also [HierarchySelection].
@ProviderFor(HierarchySelection)
final hierarchySelectionProvider =
    AutoDisposeNotifierProvider<HierarchySelection, Set<String>>.internal(
      HierarchySelection.new,
      name: r'hierarchySelectionProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$hierarchySelectionHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$HierarchySelection = AutoDisposeNotifier<Set<String>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
