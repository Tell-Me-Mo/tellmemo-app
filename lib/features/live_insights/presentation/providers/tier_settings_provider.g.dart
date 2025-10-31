// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tier_settings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$tierSettingsNotifierHash() =>
    r'60495f738503336be5be2e3d21e4d3b0d3a85eda';

/// Provider for managing answer discovery tier settings
/// Persists settings to SharedPreferences
///
/// Copied from [TierSettingsNotifier].
@ProviderFor(TierSettingsNotifier)
final tierSettingsNotifierProvider =
    AsyncNotifierProvider<TierSettingsNotifier, TierSettings>.internal(
      TierSettingsNotifier.new,
      name: r'tierSettingsNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$tierSettingsNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$TierSettingsNotifier = AsyncNotifier<TierSettings>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
