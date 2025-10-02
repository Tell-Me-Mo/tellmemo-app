// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'projects_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$projectsRepositoryHash() =>
    r'2e748ead949917fc34053db6a64b6eb8cd053062';

/// See also [projectsRepository].
@ProviderFor(projectsRepository)
final projectsRepositoryProvider =
    AutoDisposeProvider<ProjectsRepository>.internal(
      projectsRepository,
      name: r'projectsRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$projectsRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ProjectsRepositoryRef = AutoDisposeProviderRef<ProjectsRepository>;
String _$projectsListHash() => r'17cf57ba32da2fde5c89f5c0e15ae324bbd26979';

/// See also [ProjectsList].
@ProviderFor(ProjectsList)
final projectsListProvider =
    AutoDisposeAsyncNotifierProvider<ProjectsList, List<Project>>.internal(
      ProjectsList.new,
      name: r'projectsListProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$projectsListHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ProjectsList = AutoDisposeAsyncNotifier<List<Project>>;
String _$projectDetailHash() => r'8346d5809193a5148caefcdaf2ddf0c5afa7abb5';

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

abstract class _$ProjectDetail
    extends BuildlessAutoDisposeAsyncNotifier<Project?> {
  late final String projectId;

  FutureOr<Project?> build(String projectId);
}

/// See also [ProjectDetail].
@ProviderFor(ProjectDetail)
const projectDetailProvider = ProjectDetailFamily();

/// See also [ProjectDetail].
class ProjectDetailFamily extends Family<AsyncValue<Project?>> {
  /// See also [ProjectDetail].
  const ProjectDetailFamily();

  /// See also [ProjectDetail].
  ProjectDetailProvider call(String projectId) {
    return ProjectDetailProvider(projectId);
  }

  @override
  ProjectDetailProvider getProviderOverride(
    covariant ProjectDetailProvider provider,
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
  String? get name => r'projectDetailProvider';
}

/// See also [ProjectDetail].
class ProjectDetailProvider
    extends AutoDisposeAsyncNotifierProviderImpl<ProjectDetail, Project?> {
  /// See also [ProjectDetail].
  ProjectDetailProvider(String projectId)
    : this._internal(
        () => ProjectDetail()..projectId = projectId,
        from: projectDetailProvider,
        name: r'projectDetailProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$projectDetailHash,
        dependencies: ProjectDetailFamily._dependencies,
        allTransitiveDependencies:
            ProjectDetailFamily._allTransitiveDependencies,
        projectId: projectId,
      );

  ProjectDetailProvider._internal(
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
  FutureOr<Project?> runNotifierBuild(covariant ProjectDetail notifier) {
    return notifier.build(projectId);
  }

  @override
  Override overrideWith(ProjectDetail Function() create) {
    return ProviderOverride(
      origin: this,
      override: ProjectDetailProvider._internal(
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
  AutoDisposeAsyncNotifierProviderElement<ProjectDetail, Project?>
  createElement() {
    return _ProjectDetailProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ProjectDetailProvider && other.projectId == projectId;
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
mixin ProjectDetailRef on AutoDisposeAsyncNotifierProviderRef<Project?> {
  /// The parameter `projectId` of this provider.
  String get projectId;
}

class _ProjectDetailProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<ProjectDetail, Project?>
    with ProjectDetailRef {
  _ProjectDetailProviderElement(super.provider);

  @override
  String get projectId => (origin as ProjectDetailProvider).projectId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
