// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'integrations_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$firefliesIntegrationHash() =>
    r'71b280e48252dc1493c7df715905dd309fa0a33f';

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
String _$integrationsHash() => r'4b438b9882e3c14715be5db9663649da86a7b99e';

/// See also [Integrations].
@ProviderFor(Integrations)
final integrationsProvider =
    AutoDisposeAsyncNotifierProvider<Integrations, List<Integration>>.internal(
      Integrations.new,
      name: r'integrationsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$integrationsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$Integrations = AutoDisposeAsyncNotifier<List<Integration>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
