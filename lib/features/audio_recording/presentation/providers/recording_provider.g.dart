// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recording_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$audioRecordingServiceHash() =>
    r'c7e4c53b01b24ce11ec7e39e3432670de5baeab8';

/// See also [audioRecordingService].
@ProviderFor(audioRecordingService)
final audioRecordingServiceProvider =
    AutoDisposeProvider<AudioRecordingService>.internal(
      audioRecordingService,
      name: r'audioRecordingServiceProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$audioRecordingServiceHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AudioRecordingServiceRef =
    AutoDisposeProviderRef<AudioRecordingService>;
String _$transcriptionServiceHash() =>
    r'a2465a2681633dabe6d797a805f8e4efd87f81be';

/// See also [transcriptionService].
@ProviderFor(transcriptionService)
final transcriptionServiceProvider =
    AutoDisposeProvider<TranscriptionService>.internal(
      transcriptionService,
      name: r'transcriptionServiceProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$transcriptionServiceHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TranscriptionServiceRef = AutoDisposeProviderRef<TranscriptionService>;
String _$recordingNotifierHash() => r'9799b6b4421f6204cfab90c62e0e6befdaade517';

/// See also [RecordingNotifier].
@ProviderFor(RecordingNotifier)
final recordingNotifierProvider =
    AutoDisposeNotifierProvider<
      RecordingNotifier,
      RecordingStateModel
    >.internal(
      RecordingNotifier.new,
      name: r'recordingNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$recordingNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$RecordingNotifier = AutoDisposeNotifier<RecordingStateModel>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
