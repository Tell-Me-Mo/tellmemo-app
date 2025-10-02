// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fireflies_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$firefliesIntegrationHash() =>
    r'a6062ca4c052ba699a646485da0c681d95746786';

/// See also [firefliesIntegration].
@ProviderFor(firefliesIntegration)
final firefliesIntegrationProvider =
    AutoDisposeFutureProvider<Integration?>.internal(
      firefliesIntegration,
      name: r'firefliesIntegrationProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$firefliesIntegrationHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FirefliesIntegrationRef = AutoDisposeFutureProviderRef<Integration?>;
String _$firefliesActivityHash() => r'36a14da57da43c4c559eb3f92bf88ce321da474b';

/// See also [firefliesActivity].
@ProviderFor(firefliesActivity)
final firefliesActivityProvider =
    AutoDisposeFutureProvider<List<Map<String, dynamic>>>.internal(
      firefliesActivity,
      name: r'firefliesActivityProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$firefliesActivityHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FirefliesActivityRef =
    AutoDisposeFutureProviderRef<List<Map<String, dynamic>>>;
String _$firefliesWebhookHash() => r'7bd28bb6ba49968b3cbd8cf945864ec03f1c1001';

/// See also [FirefliesWebhook].
@ProviderFor(FirefliesWebhook)
final firefliesWebhookProvider =
    AutoDisposeAsyncNotifierProvider<FirefliesWebhook, void>.internal(
      FirefliesWebhook.new,
      name: r'firefliesWebhookProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$firefliesWebhookHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$FirefliesWebhook = AutoDisposeAsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
