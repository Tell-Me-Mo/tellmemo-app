// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'job_websocket_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$jobWebSocketServiceHash() =>
    r'0863f56d40b16a351cc8b715538b088d5e4e074e';

/// WebSocket service provider
///
/// Copied from [jobWebSocketService].
@ProviderFor(jobWebSocketService)
final jobWebSocketServiceProvider =
    AutoDisposeProvider<JobWebSocketService>.internal(
      jobWebSocketService,
      name: r'jobWebSocketServiceProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$jobWebSocketServiceHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef JobWebSocketServiceRef = AutoDisposeProviderRef<JobWebSocketService>;
String _$jobWebSocketUpdatesHash() =>
    r'62cf8d0f6f2043eef898ac67359462a44cebe32f';

/// Stream of job updates from WebSocket
///
/// Copied from [jobWebSocketUpdates].
@ProviderFor(jobWebSocketUpdates)
final jobWebSocketUpdatesProvider =
    AutoDisposeStreamProvider<JobModel>.internal(
      jobWebSocketUpdates,
      name: r'jobWebSocketUpdatesProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$jobWebSocketUpdatesHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef JobWebSocketUpdatesRef = AutoDisposeStreamProviderRef<JobModel>;
String _$jobWebSocketConnectionStateHash() =>
    r'e30c40960f39228fb59c06a0892348db8936b31a';

/// WebSocket connection state
///
/// Copied from [jobWebSocketConnectionState].
@ProviderFor(jobWebSocketConnectionState)
final jobWebSocketConnectionStateProvider =
    AutoDisposeStreamProvider<bool>.internal(
      jobWebSocketConnectionState,
      name: r'jobWebSocketConnectionStateProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$jobWebSocketConnectionStateHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef JobWebSocketConnectionStateRef = AutoDisposeStreamProviderRef<bool>;
String _$webSocketActiveJobsTrackerHash() =>
    r'04e0a81d74892be8a7a5162955a14affa274b6f4';

/// Active jobs tracker using WebSocket
///
/// Copied from [WebSocketActiveJobsTracker].
@ProviderFor(WebSocketActiveJobsTracker)
final webSocketActiveJobsTrackerProvider =
    AutoDisposeAsyncNotifierProvider<
      WebSocketActiveJobsTracker,
      List<JobModel>
    >.internal(
      WebSocketActiveJobsTracker.new,
      name: r'webSocketActiveJobsTrackerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$webSocketActiveJobsTrackerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$WebSocketActiveJobsTracker = AutoDisposeAsyncNotifier<List<JobModel>>;
String _$webSocketProjectJobsTrackerHash() =>
    r'3e4ab531e3c748e8e59429554437d31fb5746580';

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

abstract class _$WebSocketProjectJobsTracker
    extends BuildlessAutoDisposeAsyncNotifier<List<JobModel>> {
  late final String projectId;

  FutureOr<List<JobModel>> build(String projectId);
}

/// Provider to track jobs for a specific project
///
/// Copied from [WebSocketProjectJobsTracker].
@ProviderFor(WebSocketProjectJobsTracker)
const webSocketProjectJobsTrackerProvider = WebSocketProjectJobsTrackerFamily();

/// Provider to track jobs for a specific project
///
/// Copied from [WebSocketProjectJobsTracker].
class WebSocketProjectJobsTrackerFamily
    extends Family<AsyncValue<List<JobModel>>> {
  /// Provider to track jobs for a specific project
  ///
  /// Copied from [WebSocketProjectJobsTracker].
  const WebSocketProjectJobsTrackerFamily();

  /// Provider to track jobs for a specific project
  ///
  /// Copied from [WebSocketProjectJobsTracker].
  WebSocketProjectJobsTrackerProvider call(String projectId) {
    return WebSocketProjectJobsTrackerProvider(projectId);
  }

  @override
  WebSocketProjectJobsTrackerProvider getProviderOverride(
    covariant WebSocketProjectJobsTrackerProvider provider,
  ) {
    return call(provider.projectId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'webSocketProjectJobsTrackerProvider';
}

/// Provider to track jobs for a specific project
///
/// Copied from [WebSocketProjectJobsTracker].
class WebSocketProjectJobsTrackerProvider
    extends
        AutoDisposeAsyncNotifierProviderImpl<
          WebSocketProjectJobsTracker,
          List<JobModel>
        > {
  /// Provider to track jobs for a specific project
  ///
  /// Copied from [WebSocketProjectJobsTracker].
  WebSocketProjectJobsTrackerProvider(String projectId)
    : this._internal(
        () => WebSocketProjectJobsTracker()..projectId = projectId,
        from: webSocketProjectJobsTrackerProvider,
        name: r'webSocketProjectJobsTrackerProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$webSocketProjectJobsTrackerHash,
        dependencies: WebSocketProjectJobsTrackerFamily._dependencies,
        allTransitiveDependencies:
            WebSocketProjectJobsTrackerFamily._allTransitiveDependencies,
        projectId: projectId,
      );

  WebSocketProjectJobsTrackerProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.projectId,
  }) : super.internal();

  final String projectId;

  @override
  FutureOr<List<JobModel>> runNotifierBuild(
    covariant WebSocketProjectJobsTracker notifier,
  ) {
    return notifier.build(projectId);
  }

  @override
  Override overrideWith(WebSocketProjectJobsTracker Function() create) {
    return ProviderOverride(
      origin: this,
      override: WebSocketProjectJobsTrackerProvider._internal(
        () => create()..projectId = projectId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        projectId: projectId,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<
    WebSocketProjectJobsTracker,
    List<JobModel>
  >
  createElement() {
    return _WebSocketProjectJobsTrackerProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is WebSocketProjectJobsTrackerProvider &&
        other.projectId == projectId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, projectId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin WebSocketProjectJobsTrackerRef
    on AutoDisposeAsyncNotifierProviderRef<List<JobModel>> {
  /// The parameter `projectId` of this provider.
  String get projectId;
}

class _WebSocketProjectJobsTrackerProviderElement
    extends
        AutoDisposeAsyncNotifierProviderElement<
          WebSocketProjectJobsTracker,
          List<JobModel>
        >
    with WebSocketProjectJobsTrackerRef {
  _WebSocketProjectJobsTrackerProviderElement(super.provider);

  @override
  String get projectId =>
      (origin as WebSocketProjectJobsTrackerProvider).projectId;
}

String _$webSocketJobTrackerHash() =>
    r'55cfff586aee5ae1ff2fdc6c04ada48e9a3bcdb2';

abstract class _$WebSocketJobTracker
    extends BuildlessAutoDisposeAsyncNotifier<JobModel?> {
  late final String jobId;

  FutureOr<JobModel?> build(String jobId);
}

/// Provider to track a specific job
///
/// Copied from [WebSocketJobTracker].
@ProviderFor(WebSocketJobTracker)
const webSocketJobTrackerProvider = WebSocketJobTrackerFamily();

/// Provider to track a specific job
///
/// Copied from [WebSocketJobTracker].
class WebSocketJobTrackerFamily extends Family<AsyncValue<JobModel?>> {
  /// Provider to track a specific job
  ///
  /// Copied from [WebSocketJobTracker].
  const WebSocketJobTrackerFamily();

  /// Provider to track a specific job
  ///
  /// Copied from [WebSocketJobTracker].
  WebSocketJobTrackerProvider call(String jobId) {
    return WebSocketJobTrackerProvider(jobId);
  }

  @override
  WebSocketJobTrackerProvider getProviderOverride(
    covariant WebSocketJobTrackerProvider provider,
  ) {
    return call(provider.jobId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'webSocketJobTrackerProvider';
}

/// Provider to track a specific job
///
/// Copied from [WebSocketJobTracker].
class WebSocketJobTrackerProvider
    extends
        AutoDisposeAsyncNotifierProviderImpl<WebSocketJobTracker, JobModel?> {
  /// Provider to track a specific job
  ///
  /// Copied from [WebSocketJobTracker].
  WebSocketJobTrackerProvider(String jobId)
    : this._internal(
        () => WebSocketJobTracker()..jobId = jobId,
        from: webSocketJobTrackerProvider,
        name: r'webSocketJobTrackerProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$webSocketJobTrackerHash,
        dependencies: WebSocketJobTrackerFamily._dependencies,
        allTransitiveDependencies:
            WebSocketJobTrackerFamily._allTransitiveDependencies,
        jobId: jobId,
      );

  WebSocketJobTrackerProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.jobId,
  }) : super.internal();

  final String jobId;

  @override
  FutureOr<JobModel?> runNotifierBuild(covariant WebSocketJobTracker notifier) {
    return notifier.build(jobId);
  }

  @override
  Override overrideWith(WebSocketJobTracker Function() create) {
    return ProviderOverride(
      origin: this,
      override: WebSocketJobTrackerProvider._internal(
        () => create()..jobId = jobId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        jobId: jobId,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<WebSocketJobTracker, JobModel?>
  createElement() {
    return _WebSocketJobTrackerProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is WebSocketJobTrackerProvider && other.jobId == jobId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, jobId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin WebSocketJobTrackerRef on AutoDisposeAsyncNotifierProviderRef<JobModel?> {
  /// The parameter `jobId` of this provider.
  String get jobId;
}

class _WebSocketJobTrackerProviderElement
    extends
        AutoDisposeAsyncNotifierProviderElement<WebSocketJobTracker, JobModel?>
    with WebSocketJobTrackerRef {
  _WebSocketJobTrackerProviderElement(super.provider);

  @override
  String get jobId => (origin as WebSocketJobTrackerProvider).jobId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
