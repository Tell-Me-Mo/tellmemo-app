// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'upload_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$uploadStateHash() => r'c07662666288d520f63f05614bec63d8ae2f4056';

/// See also [uploadState].
@ProviderFor(uploadState)
final uploadStateProvider = AutoDisposeProvider<UploadState>.internal(
  uploadState,
  name: r'uploadStateProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$uploadStateHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UploadStateRef = AutoDisposeProviderRef<UploadState>;
String _$uploadContentHash() => r'f5f88115b91b002dda03f9125f344af620d17b59';

/// See also [UploadContent].
@ProviderFor(UploadContent)
final uploadContentProvider =
    AutoDisposeNotifierProvider<UploadContent, UploadState>.internal(
      UploadContent.new,
      name: r'uploadContentProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$uploadContentHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$UploadContent = AutoDisposeNotifier<UploadState>;
String _$multiFileUploadHash() => r'add8bb1c577d687f801674846f9023e9d239870e';

/// See also [MultiFileUpload].
@ProviderFor(MultiFileUpload)
final multiFileUploadProvider =
    AutoDisposeNotifierProvider<MultiFileUpload, MultiFileUploadState>.internal(
      MultiFileUpload.new,
      name: r'multiFileUploadProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$multiFileUploadHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$MultiFileUpload = AutoDisposeNotifier<MultiFileUploadState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
