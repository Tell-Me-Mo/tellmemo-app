// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'processing_jobs_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$hasProcessingContentHash() =>
    r'd180ac69ed2357fd39e1d3e110737e0253522444';

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

/// See also [hasProcessingContent].
@ProviderFor(hasProcessingContent)
const hasProcessingContentProvider = HasProcessingContentFamily();

/// See also [hasProcessingContent].
class HasProcessingContentFamily extends Family<bool> {
  /// See also [hasProcessingContent].
  const HasProcessingContentFamily();

  /// See also [hasProcessingContent].
  HasProcessingContentProvider call(String projectId) {
    return HasProcessingContentProvider(projectId);
  }

  @override
  HasProcessingContentProvider getProviderOverride(
    covariant HasProcessingContentProvider provider,
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
  String? get name => r'hasProcessingContentProvider';
}

/// See also [hasProcessingContent].
class HasProcessingContentProvider extends AutoDisposeProvider<bool> {
  /// See also [hasProcessingContent].
  HasProcessingContentProvider(String projectId)
    : this._internal(
        (ref) =>
            hasProcessingContent(ref as HasProcessingContentRef, projectId),
        from: hasProcessingContentProvider,
        name: r'hasProcessingContentProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$hasProcessingContentHash,
        dependencies: HasProcessingContentFamily._dependencies,
        allTransitiveDependencies:
            HasProcessingContentFamily._allTransitiveDependencies,
        projectId: projectId,
      );

  HasProcessingContentProvider._internal(
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
  Override overrideWith(
    bool Function(HasProcessingContentRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: HasProcessingContentProvider._internal(
        (ref) => create(ref as HasProcessingContentRef),
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
  AutoDisposeProviderElement<bool> createElement() {
    return _HasProcessingContentProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is HasProcessingContentProvider &&
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
mixin HasProcessingContentRef on AutoDisposeProviderRef<bool> {
  /// The parameter `projectId` of this provider.
  String get projectId;
}

class _HasProcessingContentProviderElement
    extends AutoDisposeProviderElement<bool>
    with HasProcessingContentRef {
  _HasProcessingContentProviderElement(super.provider);

  @override
  String get projectId => (origin as HasProcessingContentProvider).projectId;
}

String _$projectProcessingJobsHash() =>
    r'a24fe55a8360dd6e384ca86793592fb0664d2bd8';

/// See also [projectProcessingJobs].
@ProviderFor(projectProcessingJobs)
const projectProcessingJobsProvider = ProjectProcessingJobsFamily();

/// See also [projectProcessingJobs].
class ProjectProcessingJobsFamily extends Family<List<ProcessingJob>> {
  /// See also [projectProcessingJobs].
  const ProjectProcessingJobsFamily();

  /// See also [projectProcessingJobs].
  ProjectProcessingJobsProvider call(String projectId) {
    return ProjectProcessingJobsProvider(projectId);
  }

  @override
  ProjectProcessingJobsProvider getProviderOverride(
    covariant ProjectProcessingJobsProvider provider,
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
  String? get name => r'projectProcessingJobsProvider';
}

/// See also [projectProcessingJobs].
class ProjectProcessingJobsProvider
    extends AutoDisposeProvider<List<ProcessingJob>> {
  /// See also [projectProcessingJobs].
  ProjectProcessingJobsProvider(String projectId)
    : this._internal(
        (ref) =>
            projectProcessingJobs(ref as ProjectProcessingJobsRef, projectId),
        from: projectProcessingJobsProvider,
        name: r'projectProcessingJobsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$projectProcessingJobsHash,
        dependencies: ProjectProcessingJobsFamily._dependencies,
        allTransitiveDependencies:
            ProjectProcessingJobsFamily._allTransitiveDependencies,
        projectId: projectId,
      );

  ProjectProcessingJobsProvider._internal(
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
  Override overrideWith(
    List<ProcessingJob> Function(ProjectProcessingJobsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ProjectProcessingJobsProvider._internal(
        (ref) => create(ref as ProjectProcessingJobsRef),
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
  AutoDisposeProviderElement<List<ProcessingJob>> createElement() {
    return _ProjectProcessingJobsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ProjectProcessingJobsProvider &&
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
mixin ProjectProcessingJobsRef on AutoDisposeProviderRef<List<ProcessingJob>> {
  /// The parameter `projectId` of this provider.
  String get projectId;
}

class _ProjectProcessingJobsProviderElement
    extends AutoDisposeProviderElement<List<ProcessingJob>>
    with ProjectProcessingJobsRef {
  _ProjectProcessingJobsProviderElement(super.provider);

  @override
  String get projectId => (origin as ProjectProcessingJobsProvider).projectId;
}

String _$processingJobsHash() => r'b60b0317e391078f94d418fadba0f9b5ce34c35c';

/// See also [ProcessingJobs].
@ProviderFor(ProcessingJobs)
final processingJobsProvider =
    NotifierProvider<ProcessingJobs, List<ProcessingJob>>.internal(
      ProcessingJobs.new,
      name: r'processingJobsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$processingJobsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ProcessingJobs = Notifier<List<ProcessingJob>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
