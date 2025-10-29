// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'live_insights_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$liveInsightsWebSocketServiceHash() =>
    r'2a4aba94762c1e784ea69dfd8c2c11dc8cc4e765';

/// Provider for LiveInsightsWebSocketService (keepAlive)
/// Manages persistent WebSocket connection for live meeting insights
///
/// Copied from [liveInsightsWebSocketService].
@ProviderFor(liveInsightsWebSocketService)
final liveInsightsWebSocketServiceProvider =
    Provider<LiveInsightsWebSocketService>.internal(
      liveInsightsWebSocketService,
      name: r'liveInsightsWebSocketServiceProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$liveInsightsWebSocketServiceHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef LiveInsightsWebSocketServiceRef =
    ProviderRef<LiveInsightsWebSocketService>;
String _$liveQuestionsTrackerHash() =>
    r'7e91dba96a1378be475a5c6fb69aad1392de5e3b';

/// Provider for tracking live questions during a meeting
/// Maintains a map of questions by ID for efficient updates
///
/// Copied from [LiveQuestionsTracker].
@ProviderFor(LiveQuestionsTracker)
final liveQuestionsTrackerProvider =
    AutoDisposeAsyncNotifierProvider<
      LiveQuestionsTracker,
      List<LiveQuestion>
    >.internal(
      LiveQuestionsTracker.new,
      name: r'liveQuestionsTrackerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$liveQuestionsTrackerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$LiveQuestionsTracker = AutoDisposeAsyncNotifier<List<LiveQuestion>>;
String _$liveActionsTrackerHash() =>
    r'2531c98fb08f5e20ccfdfbf1b86880b1b7f88769';

/// Provider for tracking live actions during a meeting
/// Maintains a map of actions by ID for efficient updates
///
/// Copied from [LiveActionsTracker].
@ProviderFor(LiveActionsTracker)
final liveActionsTrackerProvider =
    AutoDisposeAsyncNotifierProvider<
      LiveActionsTracker,
      List<LiveAction>
    >.internal(
      LiveActionsTracker.new,
      name: r'liveActionsTrackerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$liveActionsTrackerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$LiveActionsTracker = AutoDisposeAsyncNotifier<List<LiveAction>>;
String _$liveTranscriptionsTrackerHash() =>
    r'6cc85f20b255712d820ae4831a724291ee1e2537';

/// Provider for tracking live transcriptions during a meeting
///
/// Copied from [LiveTranscriptionsTracker].
@ProviderFor(LiveTranscriptionsTracker)
final liveTranscriptionsTrackerProvider =
    AutoDisposeAsyncNotifierProvider<
      LiveTranscriptionsTracker,
      List<TranscriptSegment>
    >.internal(
      LiveTranscriptionsTracker.new,
      name: r'liveTranscriptionsTrackerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$liveTranscriptionsTrackerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$LiveTranscriptionsTracker =
    AutoDisposeAsyncNotifier<List<TranscriptSegment>>;
String _$liveInsightsConnectionHash() =>
    r'5b849ee065f3ab5f242b82fcd56204285c9f5bbd';

/// Provider for managing Live Insights connection state
/// Connects to WebSocket when session_id is available
///
/// Copied from [LiveInsightsConnection].
@ProviderFor(LiveInsightsConnection)
final liveInsightsConnectionProvider =
    AutoDisposeAsyncNotifierProvider<LiveInsightsConnection, bool>.internal(
      LiveInsightsConnection.new,
      name: r'liveInsightsConnectionProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$liveInsightsConnectionHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$LiveInsightsConnection = AutoDisposeAsyncNotifier<bool>;
String _$dismissedInsightsHash() => r'44b1b7def5e445510af6cda0803b6ced7bdb4744';

/// Provider for local persistence of dismissed items
/// Stores dismissed question/action IDs to prevent showing them again
///
/// Copied from [DismissedInsights].
@ProviderFor(DismissedInsights)
final dismissedInsightsProvider =
    AsyncNotifierProvider<DismissedInsights, Map<String, Set<String>>>.internal(
      DismissedInsights.new,
      name: r'dismissedInsightsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$dismissedInsightsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$DismissedInsights = AsyncNotifier<Map<String, Set<String>>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
