// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'hierarchy_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

HierarchyResponse _$HierarchyResponseFromJson(Map<String, dynamic> json) {
  return _HierarchyResponse.fromJson(json);
}

/// @nodoc
mixin _$HierarchyResponse {
  List<HierarchyNodeModel> get hierarchy => throw _privateConstructorUsedError;
  @JsonKey(name: 'include_archived')
  bool get includeArchived => throw _privateConstructorUsedError;
  @JsonKey(name: 'total_portfolios')
  int get totalPortfolios => throw _privateConstructorUsedError;
  @JsonKey(name: 'has_orphaned_items')
  bool get hasOrphanedItems => throw _privateConstructorUsedError;

  /// Serializes this HierarchyResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of HierarchyResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $HierarchyResponseCopyWith<HierarchyResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HierarchyResponseCopyWith<$Res> {
  factory $HierarchyResponseCopyWith(
    HierarchyResponse value,
    $Res Function(HierarchyResponse) then,
  ) = _$HierarchyResponseCopyWithImpl<$Res, HierarchyResponse>;
  @useResult
  $Res call({
    List<HierarchyNodeModel> hierarchy,
    @JsonKey(name: 'include_archived') bool includeArchived,
    @JsonKey(name: 'total_portfolios') int totalPortfolios,
    @JsonKey(name: 'has_orphaned_items') bool hasOrphanedItems,
  });
}

/// @nodoc
class _$HierarchyResponseCopyWithImpl<$Res, $Val extends HierarchyResponse>
    implements $HierarchyResponseCopyWith<$Res> {
  _$HierarchyResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of HierarchyResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? hierarchy = null,
    Object? includeArchived = null,
    Object? totalPortfolios = null,
    Object? hasOrphanedItems = null,
  }) {
    return _then(
      _value.copyWith(
            hierarchy: null == hierarchy
                ? _value.hierarchy
                : hierarchy // ignore: cast_nullable_to_non_nullable
                      as List<HierarchyNodeModel>,
            includeArchived: null == includeArchived
                ? _value.includeArchived
                : includeArchived // ignore: cast_nullable_to_non_nullable
                      as bool,
            totalPortfolios: null == totalPortfolios
                ? _value.totalPortfolios
                : totalPortfolios // ignore: cast_nullable_to_non_nullable
                      as int,
            hasOrphanedItems: null == hasOrphanedItems
                ? _value.hasOrphanedItems
                : hasOrphanedItems // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$HierarchyResponseImplCopyWith<$Res>
    implements $HierarchyResponseCopyWith<$Res> {
  factory _$$HierarchyResponseImplCopyWith(
    _$HierarchyResponseImpl value,
    $Res Function(_$HierarchyResponseImpl) then,
  ) = __$$HierarchyResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    List<HierarchyNodeModel> hierarchy,
    @JsonKey(name: 'include_archived') bool includeArchived,
    @JsonKey(name: 'total_portfolios') int totalPortfolios,
    @JsonKey(name: 'has_orphaned_items') bool hasOrphanedItems,
  });
}

/// @nodoc
class __$$HierarchyResponseImplCopyWithImpl<$Res>
    extends _$HierarchyResponseCopyWithImpl<$Res, _$HierarchyResponseImpl>
    implements _$$HierarchyResponseImplCopyWith<$Res> {
  __$$HierarchyResponseImplCopyWithImpl(
    _$HierarchyResponseImpl _value,
    $Res Function(_$HierarchyResponseImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of HierarchyResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? hierarchy = null,
    Object? includeArchived = null,
    Object? totalPortfolios = null,
    Object? hasOrphanedItems = null,
  }) {
    return _then(
      _$HierarchyResponseImpl(
        hierarchy: null == hierarchy
            ? _value._hierarchy
            : hierarchy // ignore: cast_nullable_to_non_nullable
                  as List<HierarchyNodeModel>,
        includeArchived: null == includeArchived
            ? _value.includeArchived
            : includeArchived // ignore: cast_nullable_to_non_nullable
                  as bool,
        totalPortfolios: null == totalPortfolios
            ? _value.totalPortfolios
            : totalPortfolios // ignore: cast_nullable_to_non_nullable
                  as int,
        hasOrphanedItems: null == hasOrphanedItems
            ? _value.hasOrphanedItems
            : hasOrphanedItems // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$HierarchyResponseImpl implements _HierarchyResponse {
  const _$HierarchyResponseImpl({
    required final List<HierarchyNodeModel> hierarchy,
    @JsonKey(name: 'include_archived') this.includeArchived = false,
    @JsonKey(name: 'total_portfolios') this.totalPortfolios = 0,
    @JsonKey(name: 'has_orphaned_items') this.hasOrphanedItems = false,
  }) : _hierarchy = hierarchy;

  factory _$HierarchyResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$HierarchyResponseImplFromJson(json);

  final List<HierarchyNodeModel> _hierarchy;
  @override
  List<HierarchyNodeModel> get hierarchy {
    if (_hierarchy is EqualUnmodifiableListView) return _hierarchy;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_hierarchy);
  }

  @override
  @JsonKey(name: 'include_archived')
  final bool includeArchived;
  @override
  @JsonKey(name: 'total_portfolios')
  final int totalPortfolios;
  @override
  @JsonKey(name: 'has_orphaned_items')
  final bool hasOrphanedItems;

  @override
  String toString() {
    return 'HierarchyResponse(hierarchy: $hierarchy, includeArchived: $includeArchived, totalPortfolios: $totalPortfolios, hasOrphanedItems: $hasOrphanedItems)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HierarchyResponseImpl &&
            const DeepCollectionEquality().equals(
              other._hierarchy,
              _hierarchy,
            ) &&
            (identical(other.includeArchived, includeArchived) ||
                other.includeArchived == includeArchived) &&
            (identical(other.totalPortfolios, totalPortfolios) ||
                other.totalPortfolios == totalPortfolios) &&
            (identical(other.hasOrphanedItems, hasOrphanedItems) ||
                other.hasOrphanedItems == hasOrphanedItems));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_hierarchy),
    includeArchived,
    totalPortfolios,
    hasOrphanedItems,
  );

  /// Create a copy of HierarchyResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$HierarchyResponseImplCopyWith<_$HierarchyResponseImpl> get copyWith =>
      __$$HierarchyResponseImplCopyWithImpl<_$HierarchyResponseImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$HierarchyResponseImplToJson(this);
  }
}

abstract class _HierarchyResponse implements HierarchyResponse {
  const factory _HierarchyResponse({
    required final List<HierarchyNodeModel> hierarchy,
    @JsonKey(name: 'include_archived') final bool includeArchived,
    @JsonKey(name: 'total_portfolios') final int totalPortfolios,
    @JsonKey(name: 'has_orphaned_items') final bool hasOrphanedItems,
  }) = _$HierarchyResponseImpl;

  factory _HierarchyResponse.fromJson(Map<String, dynamic> json) =
      _$HierarchyResponseImpl.fromJson;

  @override
  List<HierarchyNodeModel> get hierarchy;
  @override
  @JsonKey(name: 'include_archived')
  bool get includeArchived;
  @override
  @JsonKey(name: 'total_portfolios')
  int get totalPortfolios;
  @override
  @JsonKey(name: 'has_orphaned_items')
  bool get hasOrphanedItems;

  /// Create a copy of HierarchyResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$HierarchyResponseImplCopyWith<_$HierarchyResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

HierarchyNodeModel _$HierarchyNodeModelFromJson(Map<String, dynamic> json) {
  return _HierarchyNodeModel.fromJson(json);
}

/// @nodoc
mixin _$HierarchyNodeModel {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  String get type =>
      throw _privateConstructorUsedError; // 'portfolio', 'program', 'project', 'virtual'
  @JsonKey(name: 'portfolio_id')
  String? get portfolioId => throw _privateConstructorUsedError;
  @JsonKey(name: 'program_id')
  String? get programId => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  String? get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  String? get updatedAt => throw _privateConstructorUsedError;
  String? get status => throw _privateConstructorUsedError; // For projects
  @JsonKey(name: 'member_count')
  int? get memberCount => throw _privateConstructorUsedError; // Nested content
  List<HierarchyNodeModel> get children => throw _privateConstructorUsedError;
  List<HierarchyNodeModel> get programs => throw _privateConstructorUsedError;
  @JsonKey(name: 'direct_projects')
  List<HierarchyNodeModel> get directProjects =>
      throw _privateConstructorUsedError;
  List<HierarchyNodeModel> get projects => throw _privateConstructorUsedError;

  /// Serializes this HierarchyNodeModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of HierarchyNodeModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $HierarchyNodeModelCopyWith<HierarchyNodeModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HierarchyNodeModelCopyWith<$Res> {
  factory $HierarchyNodeModelCopyWith(
    HierarchyNodeModel value,
    $Res Function(HierarchyNodeModel) then,
  ) = _$HierarchyNodeModelCopyWithImpl<$Res, HierarchyNodeModel>;
  @useResult
  $Res call({
    String id,
    String name,
    String? description,
    String type,
    @JsonKey(name: 'portfolio_id') String? portfolioId,
    @JsonKey(name: 'program_id') String? programId,
    @JsonKey(name: 'created_at') String? createdAt,
    @JsonKey(name: 'updated_at') String? updatedAt,
    String? status,
    @JsonKey(name: 'member_count') int? memberCount,
    List<HierarchyNodeModel> children,
    List<HierarchyNodeModel> programs,
    @JsonKey(name: 'direct_projects') List<HierarchyNodeModel> directProjects,
    List<HierarchyNodeModel> projects,
  });
}

/// @nodoc
class _$HierarchyNodeModelCopyWithImpl<$Res, $Val extends HierarchyNodeModel>
    implements $HierarchyNodeModelCopyWith<$Res> {
  _$HierarchyNodeModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of HierarchyNodeModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = freezed,
    Object? type = null,
    Object? portfolioId = freezed,
    Object? programId = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? status = freezed,
    Object? memberCount = freezed,
    Object? children = null,
    Object? programs = null,
    Object? directProjects = null,
    Object? projects = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as String,
            portfolioId: freezed == portfolioId
                ? _value.portfolioId
                : portfolioId // ignore: cast_nullable_to_non_nullable
                      as String?,
            programId: freezed == programId
                ? _value.programId
                : programId // ignore: cast_nullable_to_non_nullable
                      as String?,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as String?,
            updatedAt: freezed == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as String?,
            status: freezed == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String?,
            memberCount: freezed == memberCount
                ? _value.memberCount
                : memberCount // ignore: cast_nullable_to_non_nullable
                      as int?,
            children: null == children
                ? _value.children
                : children // ignore: cast_nullable_to_non_nullable
                      as List<HierarchyNodeModel>,
            programs: null == programs
                ? _value.programs
                : programs // ignore: cast_nullable_to_non_nullable
                      as List<HierarchyNodeModel>,
            directProjects: null == directProjects
                ? _value.directProjects
                : directProjects // ignore: cast_nullable_to_non_nullable
                      as List<HierarchyNodeModel>,
            projects: null == projects
                ? _value.projects
                : projects // ignore: cast_nullable_to_non_nullable
                      as List<HierarchyNodeModel>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$HierarchyNodeModelImplCopyWith<$Res>
    implements $HierarchyNodeModelCopyWith<$Res> {
  factory _$$HierarchyNodeModelImplCopyWith(
    _$HierarchyNodeModelImpl value,
    $Res Function(_$HierarchyNodeModelImpl) then,
  ) = __$$HierarchyNodeModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    String? description,
    String type,
    @JsonKey(name: 'portfolio_id') String? portfolioId,
    @JsonKey(name: 'program_id') String? programId,
    @JsonKey(name: 'created_at') String? createdAt,
    @JsonKey(name: 'updated_at') String? updatedAt,
    String? status,
    @JsonKey(name: 'member_count') int? memberCount,
    List<HierarchyNodeModel> children,
    List<HierarchyNodeModel> programs,
    @JsonKey(name: 'direct_projects') List<HierarchyNodeModel> directProjects,
    List<HierarchyNodeModel> projects,
  });
}

/// @nodoc
class __$$HierarchyNodeModelImplCopyWithImpl<$Res>
    extends _$HierarchyNodeModelCopyWithImpl<$Res, _$HierarchyNodeModelImpl>
    implements _$$HierarchyNodeModelImplCopyWith<$Res> {
  __$$HierarchyNodeModelImplCopyWithImpl(
    _$HierarchyNodeModelImpl _value,
    $Res Function(_$HierarchyNodeModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of HierarchyNodeModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = freezed,
    Object? type = null,
    Object? portfolioId = freezed,
    Object? programId = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? status = freezed,
    Object? memberCount = freezed,
    Object? children = null,
    Object? programs = null,
    Object? directProjects = null,
    Object? projects = null,
  }) {
    return _then(
      _$HierarchyNodeModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as String,
        portfolioId: freezed == portfolioId
            ? _value.portfolioId
            : portfolioId // ignore: cast_nullable_to_non_nullable
                  as String?,
        programId: freezed == programId
            ? _value.programId
            : programId // ignore: cast_nullable_to_non_nullable
                  as String?,
        createdAt: freezed == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as String?,
        updatedAt: freezed == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as String?,
        status: freezed == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String?,
        memberCount: freezed == memberCount
            ? _value.memberCount
            : memberCount // ignore: cast_nullable_to_non_nullable
                  as int?,
        children: null == children
            ? _value._children
            : children // ignore: cast_nullable_to_non_nullable
                  as List<HierarchyNodeModel>,
        programs: null == programs
            ? _value._programs
            : programs // ignore: cast_nullable_to_non_nullable
                  as List<HierarchyNodeModel>,
        directProjects: null == directProjects
            ? _value._directProjects
            : directProjects // ignore: cast_nullable_to_non_nullable
                  as List<HierarchyNodeModel>,
        projects: null == projects
            ? _value._projects
            : projects // ignore: cast_nullable_to_non_nullable
                  as List<HierarchyNodeModel>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$HierarchyNodeModelImpl implements _HierarchyNodeModel {
  const _$HierarchyNodeModelImpl({
    required this.id,
    required this.name,
    this.description,
    required this.type,
    @JsonKey(name: 'portfolio_id') this.portfolioId,
    @JsonKey(name: 'program_id') this.programId,
    @JsonKey(name: 'created_at') this.createdAt,
    @JsonKey(name: 'updated_at') this.updatedAt,
    this.status,
    @JsonKey(name: 'member_count') this.memberCount,
    final List<HierarchyNodeModel> children = const [],
    final List<HierarchyNodeModel> programs = const [],
    @JsonKey(name: 'direct_projects')
    final List<HierarchyNodeModel> directProjects = const [],
    final List<HierarchyNodeModel> projects = const [],
  }) : _children = children,
       _programs = programs,
       _directProjects = directProjects,
       _projects = projects;

  factory _$HierarchyNodeModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$HierarchyNodeModelImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String? description;
  @override
  final String type;
  // 'portfolio', 'program', 'project', 'virtual'
  @override
  @JsonKey(name: 'portfolio_id')
  final String? portfolioId;
  @override
  @JsonKey(name: 'program_id')
  final String? programId;
  @override
  @JsonKey(name: 'created_at')
  final String? createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final String? updatedAt;
  @override
  final String? status;
  // For projects
  @override
  @JsonKey(name: 'member_count')
  final int? memberCount;
  // Nested content
  final List<HierarchyNodeModel> _children;
  // Nested content
  @override
  @JsonKey()
  List<HierarchyNodeModel> get children {
    if (_children is EqualUnmodifiableListView) return _children;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_children);
  }

  final List<HierarchyNodeModel> _programs;
  @override
  @JsonKey()
  List<HierarchyNodeModel> get programs {
    if (_programs is EqualUnmodifiableListView) return _programs;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_programs);
  }

  final List<HierarchyNodeModel> _directProjects;
  @override
  @JsonKey(name: 'direct_projects')
  List<HierarchyNodeModel> get directProjects {
    if (_directProjects is EqualUnmodifiableListView) return _directProjects;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_directProjects);
  }

  final List<HierarchyNodeModel> _projects;
  @override
  @JsonKey()
  List<HierarchyNodeModel> get projects {
    if (_projects is EqualUnmodifiableListView) return _projects;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_projects);
  }

  @override
  String toString() {
    return 'HierarchyNodeModel(id: $id, name: $name, description: $description, type: $type, portfolioId: $portfolioId, programId: $programId, createdAt: $createdAt, updatedAt: $updatedAt, status: $status, memberCount: $memberCount, children: $children, programs: $programs, directProjects: $directProjects, projects: $projects)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HierarchyNodeModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.portfolioId, portfolioId) ||
                other.portfolioId == portfolioId) &&
            (identical(other.programId, programId) ||
                other.programId == programId) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.memberCount, memberCount) ||
                other.memberCount == memberCount) &&
            const DeepCollectionEquality().equals(other._children, _children) &&
            const DeepCollectionEquality().equals(other._programs, _programs) &&
            const DeepCollectionEquality().equals(
              other._directProjects,
              _directProjects,
            ) &&
            const DeepCollectionEquality().equals(other._projects, _projects));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    description,
    type,
    portfolioId,
    programId,
    createdAt,
    updatedAt,
    status,
    memberCount,
    const DeepCollectionEquality().hash(_children),
    const DeepCollectionEquality().hash(_programs),
    const DeepCollectionEquality().hash(_directProjects),
    const DeepCollectionEquality().hash(_projects),
  );

  /// Create a copy of HierarchyNodeModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$HierarchyNodeModelImplCopyWith<_$HierarchyNodeModelImpl> get copyWith =>
      __$$HierarchyNodeModelImplCopyWithImpl<_$HierarchyNodeModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$HierarchyNodeModelImplToJson(this);
  }
}

abstract class _HierarchyNodeModel implements HierarchyNodeModel {
  const factory _HierarchyNodeModel({
    required final String id,
    required final String name,
    final String? description,
    required final String type,
    @JsonKey(name: 'portfolio_id') final String? portfolioId,
    @JsonKey(name: 'program_id') final String? programId,
    @JsonKey(name: 'created_at') final String? createdAt,
    @JsonKey(name: 'updated_at') final String? updatedAt,
    final String? status,
    @JsonKey(name: 'member_count') final int? memberCount,
    final List<HierarchyNodeModel> children,
    final List<HierarchyNodeModel> programs,
    @JsonKey(name: 'direct_projects')
    final List<HierarchyNodeModel> directProjects,
    final List<HierarchyNodeModel> projects,
  }) = _$HierarchyNodeModelImpl;

  factory _HierarchyNodeModel.fromJson(Map<String, dynamic> json) =
      _$HierarchyNodeModelImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String? get description;
  @override
  String get type; // 'portfolio', 'program', 'project', 'virtual'
  @override
  @JsonKey(name: 'portfolio_id')
  String? get portfolioId;
  @override
  @JsonKey(name: 'program_id')
  String? get programId;
  @override
  @JsonKey(name: 'created_at')
  String? get createdAt;
  @override
  @JsonKey(name: 'updated_at')
  String? get updatedAt;
  @override
  String? get status; // For projects
  @override
  @JsonKey(name: 'member_count')
  int? get memberCount; // Nested content
  @override
  List<HierarchyNodeModel> get children;
  @override
  List<HierarchyNodeModel> get programs;
  @override
  @JsonKey(name: 'direct_projects')
  List<HierarchyNodeModel> get directProjects;
  @override
  List<HierarchyNodeModel> get projects;

  /// Create a copy of HierarchyNodeModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$HierarchyNodeModelImplCopyWith<_$HierarchyNodeModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MoveItemRequest _$MoveItemRequestFromJson(Map<String, dynamic> json) {
  return _MoveItemRequest.fromJson(json);
}

/// @nodoc
mixin _$MoveItemRequest {
  @JsonKey(name: 'item_id')
  String get itemId => throw _privateConstructorUsedError;
  @JsonKey(name: 'item_type')
  String get itemType => throw _privateConstructorUsedError;
  @JsonKey(name: 'target_parent_id')
  String? get targetParentId => throw _privateConstructorUsedError;
  @JsonKey(name: 'target_parent_type')
  String? get targetParentType => throw _privateConstructorUsedError;

  /// Serializes this MoveItemRequest to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MoveItemRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MoveItemRequestCopyWith<MoveItemRequest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MoveItemRequestCopyWith<$Res> {
  factory $MoveItemRequestCopyWith(
    MoveItemRequest value,
    $Res Function(MoveItemRequest) then,
  ) = _$MoveItemRequestCopyWithImpl<$Res, MoveItemRequest>;
  @useResult
  $Res call({
    @JsonKey(name: 'item_id') String itemId,
    @JsonKey(name: 'item_type') String itemType,
    @JsonKey(name: 'target_parent_id') String? targetParentId,
    @JsonKey(name: 'target_parent_type') String? targetParentType,
  });
}

/// @nodoc
class _$MoveItemRequestCopyWithImpl<$Res, $Val extends MoveItemRequest>
    implements $MoveItemRequestCopyWith<$Res> {
  _$MoveItemRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MoveItemRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? itemId = null,
    Object? itemType = null,
    Object? targetParentId = freezed,
    Object? targetParentType = freezed,
  }) {
    return _then(
      _value.copyWith(
            itemId: null == itemId
                ? _value.itemId
                : itemId // ignore: cast_nullable_to_non_nullable
                      as String,
            itemType: null == itemType
                ? _value.itemType
                : itemType // ignore: cast_nullable_to_non_nullable
                      as String,
            targetParentId: freezed == targetParentId
                ? _value.targetParentId
                : targetParentId // ignore: cast_nullable_to_non_nullable
                      as String?,
            targetParentType: freezed == targetParentType
                ? _value.targetParentType
                : targetParentType // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MoveItemRequestImplCopyWith<$Res>
    implements $MoveItemRequestCopyWith<$Res> {
  factory _$$MoveItemRequestImplCopyWith(
    _$MoveItemRequestImpl value,
    $Res Function(_$MoveItemRequestImpl) then,
  ) = __$$MoveItemRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'item_id') String itemId,
    @JsonKey(name: 'item_type') String itemType,
    @JsonKey(name: 'target_parent_id') String? targetParentId,
    @JsonKey(name: 'target_parent_type') String? targetParentType,
  });
}

/// @nodoc
class __$$MoveItemRequestImplCopyWithImpl<$Res>
    extends _$MoveItemRequestCopyWithImpl<$Res, _$MoveItemRequestImpl>
    implements _$$MoveItemRequestImplCopyWith<$Res> {
  __$$MoveItemRequestImplCopyWithImpl(
    _$MoveItemRequestImpl _value,
    $Res Function(_$MoveItemRequestImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MoveItemRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? itemId = null,
    Object? itemType = null,
    Object? targetParentId = freezed,
    Object? targetParentType = freezed,
  }) {
    return _then(
      _$MoveItemRequestImpl(
        itemId: null == itemId
            ? _value.itemId
            : itemId // ignore: cast_nullable_to_non_nullable
                  as String,
        itemType: null == itemType
            ? _value.itemType
            : itemType // ignore: cast_nullable_to_non_nullable
                  as String,
        targetParentId: freezed == targetParentId
            ? _value.targetParentId
            : targetParentId // ignore: cast_nullable_to_non_nullable
                  as String?,
        targetParentType: freezed == targetParentType
            ? _value.targetParentType
            : targetParentType // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$MoveItemRequestImpl extends _MoveItemRequest {
  const _$MoveItemRequestImpl({
    @JsonKey(name: 'item_id') required this.itemId,
    @JsonKey(name: 'item_type') required this.itemType,
    @JsonKey(name: 'target_parent_id') this.targetParentId,
    @JsonKey(name: 'target_parent_type') this.targetParentType,
  }) : super._();

  factory _$MoveItemRequestImpl.fromJson(Map<String, dynamic> json) =>
      _$$MoveItemRequestImplFromJson(json);

  @override
  @JsonKey(name: 'item_id')
  final String itemId;
  @override
  @JsonKey(name: 'item_type')
  final String itemType;
  @override
  @JsonKey(name: 'target_parent_id')
  final String? targetParentId;
  @override
  @JsonKey(name: 'target_parent_type')
  final String? targetParentType;

  @override
  String toString() {
    return 'MoveItemRequest(itemId: $itemId, itemType: $itemType, targetParentId: $targetParentId, targetParentType: $targetParentType)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MoveItemRequestImpl &&
            (identical(other.itemId, itemId) || other.itemId == itemId) &&
            (identical(other.itemType, itemType) ||
                other.itemType == itemType) &&
            (identical(other.targetParentId, targetParentId) ||
                other.targetParentId == targetParentId) &&
            (identical(other.targetParentType, targetParentType) ||
                other.targetParentType == targetParentType));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    itemId,
    itemType,
    targetParentId,
    targetParentType,
  );

  /// Create a copy of MoveItemRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MoveItemRequestImplCopyWith<_$MoveItemRequestImpl> get copyWith =>
      __$$MoveItemRequestImplCopyWithImpl<_$MoveItemRequestImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$MoveItemRequestImplToJson(this);
  }
}

abstract class _MoveItemRequest extends MoveItemRequest {
  const factory _MoveItemRequest({
    @JsonKey(name: 'item_id') required final String itemId,
    @JsonKey(name: 'item_type') required final String itemType,
    @JsonKey(name: 'target_parent_id') final String? targetParentId,
    @JsonKey(name: 'target_parent_type') final String? targetParentType,
  }) = _$MoveItemRequestImpl;
  const _MoveItemRequest._() : super._();

  factory _MoveItemRequest.fromJson(Map<String, dynamic> json) =
      _$MoveItemRequestImpl.fromJson;

  @override
  @JsonKey(name: 'item_id')
  String get itemId;
  @override
  @JsonKey(name: 'item_type')
  String get itemType;
  @override
  @JsonKey(name: 'target_parent_id')
  String? get targetParentId;
  @override
  @JsonKey(name: 'target_parent_type')
  String? get targetParentType;

  /// Create a copy of MoveItemRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MoveItemRequestImplCopyWith<_$MoveItemRequestImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

BulkMoveRequest _$BulkMoveRequestFromJson(Map<String, dynamic> json) {
  return _BulkMoveRequest.fromJson(json);
}

/// @nodoc
mixin _$BulkMoveRequest {
  List<MoveItemData> get items => throw _privateConstructorUsedError;
  @JsonKey(name: 'target_parent_id')
  String? get targetParentId => throw _privateConstructorUsedError;
  @JsonKey(name: 'target_parent_type')
  String? get targetParentType => throw _privateConstructorUsedError;

  /// Serializes this BulkMoveRequest to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of BulkMoveRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BulkMoveRequestCopyWith<BulkMoveRequest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BulkMoveRequestCopyWith<$Res> {
  factory $BulkMoveRequestCopyWith(
    BulkMoveRequest value,
    $Res Function(BulkMoveRequest) then,
  ) = _$BulkMoveRequestCopyWithImpl<$Res, BulkMoveRequest>;
  @useResult
  $Res call({
    List<MoveItemData> items,
    @JsonKey(name: 'target_parent_id') String? targetParentId,
    @JsonKey(name: 'target_parent_type') String? targetParentType,
  });
}

/// @nodoc
class _$BulkMoveRequestCopyWithImpl<$Res, $Val extends BulkMoveRequest>
    implements $BulkMoveRequestCopyWith<$Res> {
  _$BulkMoveRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BulkMoveRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? targetParentId = freezed,
    Object? targetParentType = freezed,
  }) {
    return _then(
      _value.copyWith(
            items: null == items
                ? _value.items
                : items // ignore: cast_nullable_to_non_nullable
                      as List<MoveItemData>,
            targetParentId: freezed == targetParentId
                ? _value.targetParentId
                : targetParentId // ignore: cast_nullable_to_non_nullable
                      as String?,
            targetParentType: freezed == targetParentType
                ? _value.targetParentType
                : targetParentType // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$BulkMoveRequestImplCopyWith<$Res>
    implements $BulkMoveRequestCopyWith<$Res> {
  factory _$$BulkMoveRequestImplCopyWith(
    _$BulkMoveRequestImpl value,
    $Res Function(_$BulkMoveRequestImpl) then,
  ) = __$$BulkMoveRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    List<MoveItemData> items,
    @JsonKey(name: 'target_parent_id') String? targetParentId,
    @JsonKey(name: 'target_parent_type') String? targetParentType,
  });
}

/// @nodoc
class __$$BulkMoveRequestImplCopyWithImpl<$Res>
    extends _$BulkMoveRequestCopyWithImpl<$Res, _$BulkMoveRequestImpl>
    implements _$$BulkMoveRequestImplCopyWith<$Res> {
  __$$BulkMoveRequestImplCopyWithImpl(
    _$BulkMoveRequestImpl _value,
    $Res Function(_$BulkMoveRequestImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of BulkMoveRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? targetParentId = freezed,
    Object? targetParentType = freezed,
  }) {
    return _then(
      _$BulkMoveRequestImpl(
        items: null == items
            ? _value._items
            : items // ignore: cast_nullable_to_non_nullable
                  as List<MoveItemData>,
        targetParentId: freezed == targetParentId
            ? _value.targetParentId
            : targetParentId // ignore: cast_nullable_to_non_nullable
                  as String?,
        targetParentType: freezed == targetParentType
            ? _value.targetParentType
            : targetParentType // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$BulkMoveRequestImpl extends _BulkMoveRequest {
  const _$BulkMoveRequestImpl({
    required final List<MoveItemData> items,
    @JsonKey(name: 'target_parent_id') this.targetParentId,
    @JsonKey(name: 'target_parent_type') this.targetParentType,
  }) : _items = items,
       super._();

  factory _$BulkMoveRequestImpl.fromJson(Map<String, dynamic> json) =>
      _$$BulkMoveRequestImplFromJson(json);

  final List<MoveItemData> _items;
  @override
  List<MoveItemData> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  @JsonKey(name: 'target_parent_id')
  final String? targetParentId;
  @override
  @JsonKey(name: 'target_parent_type')
  final String? targetParentType;

  @override
  String toString() {
    return 'BulkMoveRequest(items: $items, targetParentId: $targetParentId, targetParentType: $targetParentType)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BulkMoveRequestImpl &&
            const DeepCollectionEquality().equals(other._items, _items) &&
            (identical(other.targetParentId, targetParentId) ||
                other.targetParentId == targetParentId) &&
            (identical(other.targetParentType, targetParentType) ||
                other.targetParentType == targetParentType));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_items),
    targetParentId,
    targetParentType,
  );

  /// Create a copy of BulkMoveRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BulkMoveRequestImplCopyWith<_$BulkMoveRequestImpl> get copyWith =>
      __$$BulkMoveRequestImplCopyWithImpl<_$BulkMoveRequestImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$BulkMoveRequestImplToJson(this);
  }
}

abstract class _BulkMoveRequest extends BulkMoveRequest {
  const factory _BulkMoveRequest({
    required final List<MoveItemData> items,
    @JsonKey(name: 'target_parent_id') final String? targetParentId,
    @JsonKey(name: 'target_parent_type') final String? targetParentType,
  }) = _$BulkMoveRequestImpl;
  const _BulkMoveRequest._() : super._();

  factory _BulkMoveRequest.fromJson(Map<String, dynamic> json) =
      _$BulkMoveRequestImpl.fromJson;

  @override
  List<MoveItemData> get items;
  @override
  @JsonKey(name: 'target_parent_id')
  String? get targetParentId;
  @override
  @JsonKey(name: 'target_parent_type')
  String? get targetParentType;

  /// Create a copy of BulkMoveRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BulkMoveRequestImplCopyWith<_$BulkMoveRequestImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MoveItemData _$MoveItemDataFromJson(Map<String, dynamic> json) {
  return _MoveItemData.fromJson(json);
}

/// @nodoc
mixin _$MoveItemData {
  String get id => throw _privateConstructorUsedError;
  String get type => throw _privateConstructorUsedError;

  /// Serializes this MoveItemData to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MoveItemData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MoveItemDataCopyWith<MoveItemData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MoveItemDataCopyWith<$Res> {
  factory $MoveItemDataCopyWith(
    MoveItemData value,
    $Res Function(MoveItemData) then,
  ) = _$MoveItemDataCopyWithImpl<$Res, MoveItemData>;
  @useResult
  $Res call({String id, String type});
}

/// @nodoc
class _$MoveItemDataCopyWithImpl<$Res, $Val extends MoveItemData>
    implements $MoveItemDataCopyWith<$Res> {
  _$MoveItemDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MoveItemData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? id = null, Object? type = null}) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MoveItemDataImplCopyWith<$Res>
    implements $MoveItemDataCopyWith<$Res> {
  factory _$$MoveItemDataImplCopyWith(
    _$MoveItemDataImpl value,
    $Res Function(_$MoveItemDataImpl) then,
  ) = __$$MoveItemDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String type});
}

/// @nodoc
class __$$MoveItemDataImplCopyWithImpl<$Res>
    extends _$MoveItemDataCopyWithImpl<$Res, _$MoveItemDataImpl>
    implements _$$MoveItemDataImplCopyWith<$Res> {
  __$$MoveItemDataImplCopyWithImpl(
    _$MoveItemDataImpl _value,
    $Res Function(_$MoveItemDataImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MoveItemData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? id = null, Object? type = null}) {
    return _then(
      _$MoveItemDataImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$MoveItemDataImpl extends _MoveItemData {
  const _$MoveItemDataImpl({required this.id, required this.type}) : super._();

  factory _$MoveItemDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$MoveItemDataImplFromJson(json);

  @override
  final String id;
  @override
  final String type;

  @override
  String toString() {
    return 'MoveItemData(id: $id, type: $type)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MoveItemDataImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.type, type) || other.type == type));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, type);

  /// Create a copy of MoveItemData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MoveItemDataImplCopyWith<_$MoveItemDataImpl> get copyWith =>
      __$$MoveItemDataImplCopyWithImpl<_$MoveItemDataImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MoveItemDataImplToJson(this);
  }
}

abstract class _MoveItemData extends MoveItemData {
  const factory _MoveItemData({
    required final String id,
    required final String type,
  }) = _$MoveItemDataImpl;
  const _MoveItemData._() : super._();

  factory _MoveItemData.fromJson(Map<String, dynamic> json) =
      _$MoveItemDataImpl.fromJson;

  @override
  String get id;
  @override
  String get type;

  /// Create a copy of MoveItemData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MoveItemDataImplCopyWith<_$MoveItemDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MoveItemResponse _$MoveItemResponseFromJson(Map<String, dynamic> json) {
  return _MoveItemResponse.fromJson(json);
}

/// @nodoc
mixin _$MoveItemResponse {
  bool get success => throw _privateConstructorUsedError;
  String get message => throw _privateConstructorUsedError;
  HierarchyNodeModel get item => throw _privateConstructorUsedError;

  /// Serializes this MoveItemResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MoveItemResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MoveItemResponseCopyWith<MoveItemResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MoveItemResponseCopyWith<$Res> {
  factory $MoveItemResponseCopyWith(
    MoveItemResponse value,
    $Res Function(MoveItemResponse) then,
  ) = _$MoveItemResponseCopyWithImpl<$Res, MoveItemResponse>;
  @useResult
  $Res call({bool success, String message, HierarchyNodeModel item});

  $HierarchyNodeModelCopyWith<$Res> get item;
}

/// @nodoc
class _$MoveItemResponseCopyWithImpl<$Res, $Val extends MoveItemResponse>
    implements $MoveItemResponseCopyWith<$Res> {
  _$MoveItemResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MoveItemResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? success = null,
    Object? message = null,
    Object? item = null,
  }) {
    return _then(
      _value.copyWith(
            success: null == success
                ? _value.success
                : success // ignore: cast_nullable_to_non_nullable
                      as bool,
            message: null == message
                ? _value.message
                : message // ignore: cast_nullable_to_non_nullable
                      as String,
            item: null == item
                ? _value.item
                : item // ignore: cast_nullable_to_non_nullable
                      as HierarchyNodeModel,
          )
          as $Val,
    );
  }

  /// Create a copy of MoveItemResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $HierarchyNodeModelCopyWith<$Res> get item {
    return $HierarchyNodeModelCopyWith<$Res>(_value.item, (value) {
      return _then(_value.copyWith(item: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$MoveItemResponseImplCopyWith<$Res>
    implements $MoveItemResponseCopyWith<$Res> {
  factory _$$MoveItemResponseImplCopyWith(
    _$MoveItemResponseImpl value,
    $Res Function(_$MoveItemResponseImpl) then,
  ) = __$$MoveItemResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({bool success, String message, HierarchyNodeModel item});

  @override
  $HierarchyNodeModelCopyWith<$Res> get item;
}

/// @nodoc
class __$$MoveItemResponseImplCopyWithImpl<$Res>
    extends _$MoveItemResponseCopyWithImpl<$Res, _$MoveItemResponseImpl>
    implements _$$MoveItemResponseImplCopyWith<$Res> {
  __$$MoveItemResponseImplCopyWithImpl(
    _$MoveItemResponseImpl _value,
    $Res Function(_$MoveItemResponseImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MoveItemResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? success = null,
    Object? message = null,
    Object? item = null,
  }) {
    return _then(
      _$MoveItemResponseImpl(
        success: null == success
            ? _value.success
            : success // ignore: cast_nullable_to_non_nullable
                  as bool,
        message: null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String,
        item: null == item
            ? _value.item
            : item // ignore: cast_nullable_to_non_nullable
                  as HierarchyNodeModel,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$MoveItemResponseImpl implements _MoveItemResponse {
  const _$MoveItemResponseImpl({
    required this.success,
    required this.message,
    required this.item,
  });

  factory _$MoveItemResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$MoveItemResponseImplFromJson(json);

  @override
  final bool success;
  @override
  final String message;
  @override
  final HierarchyNodeModel item;

  @override
  String toString() {
    return 'MoveItemResponse(success: $success, message: $message, item: $item)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MoveItemResponseImpl &&
            (identical(other.success, success) || other.success == success) &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.item, item) || other.item == item));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, success, message, item);

  /// Create a copy of MoveItemResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MoveItemResponseImplCopyWith<_$MoveItemResponseImpl> get copyWith =>
      __$$MoveItemResponseImplCopyWithImpl<_$MoveItemResponseImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$MoveItemResponseImplToJson(this);
  }
}

abstract class _MoveItemResponse implements MoveItemResponse {
  const factory _MoveItemResponse({
    required final bool success,
    required final String message,
    required final HierarchyNodeModel item,
  }) = _$MoveItemResponseImpl;

  factory _MoveItemResponse.fromJson(Map<String, dynamic> json) =
      _$MoveItemResponseImpl.fromJson;

  @override
  bool get success;
  @override
  String get message;
  @override
  HierarchyNodeModel get item;

  /// Create a copy of MoveItemResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MoveItemResponseImplCopyWith<_$MoveItemResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

BulkMoveResponse _$BulkMoveResponseFromJson(Map<String, dynamic> json) {
  return _BulkMoveResponse.fromJson(json);
}

/// @nodoc
mixin _$BulkMoveResponse {
  String get message => throw _privateConstructorUsedError;
  BulkMoveResults get results => throw _privateConstructorUsedError;

  /// Serializes this BulkMoveResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of BulkMoveResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BulkMoveResponseCopyWith<BulkMoveResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BulkMoveResponseCopyWith<$Res> {
  factory $BulkMoveResponseCopyWith(
    BulkMoveResponse value,
    $Res Function(BulkMoveResponse) then,
  ) = _$BulkMoveResponseCopyWithImpl<$Res, BulkMoveResponse>;
  @useResult
  $Res call({String message, BulkMoveResults results});

  $BulkMoveResultsCopyWith<$Res> get results;
}

/// @nodoc
class _$BulkMoveResponseCopyWithImpl<$Res, $Val extends BulkMoveResponse>
    implements $BulkMoveResponseCopyWith<$Res> {
  _$BulkMoveResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BulkMoveResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? message = null, Object? results = null}) {
    return _then(
      _value.copyWith(
            message: null == message
                ? _value.message
                : message // ignore: cast_nullable_to_non_nullable
                      as String,
            results: null == results
                ? _value.results
                : results // ignore: cast_nullable_to_non_nullable
                      as BulkMoveResults,
          )
          as $Val,
    );
  }

  /// Create a copy of BulkMoveResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $BulkMoveResultsCopyWith<$Res> get results {
    return $BulkMoveResultsCopyWith<$Res>(_value.results, (value) {
      return _then(_value.copyWith(results: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$BulkMoveResponseImplCopyWith<$Res>
    implements $BulkMoveResponseCopyWith<$Res> {
  factory _$$BulkMoveResponseImplCopyWith(
    _$BulkMoveResponseImpl value,
    $Res Function(_$BulkMoveResponseImpl) then,
  ) = __$$BulkMoveResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String message, BulkMoveResults results});

  @override
  $BulkMoveResultsCopyWith<$Res> get results;
}

/// @nodoc
class __$$BulkMoveResponseImplCopyWithImpl<$Res>
    extends _$BulkMoveResponseCopyWithImpl<$Res, _$BulkMoveResponseImpl>
    implements _$$BulkMoveResponseImplCopyWith<$Res> {
  __$$BulkMoveResponseImplCopyWithImpl(
    _$BulkMoveResponseImpl _value,
    $Res Function(_$BulkMoveResponseImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of BulkMoveResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? message = null, Object? results = null}) {
    return _then(
      _$BulkMoveResponseImpl(
        message: null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String,
        results: null == results
            ? _value.results
            : results // ignore: cast_nullable_to_non_nullable
                  as BulkMoveResults,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$BulkMoveResponseImpl implements _BulkMoveResponse {
  const _$BulkMoveResponseImpl({required this.message, required this.results});

  factory _$BulkMoveResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$BulkMoveResponseImplFromJson(json);

  @override
  final String message;
  @override
  final BulkMoveResults results;

  @override
  String toString() {
    return 'BulkMoveResponse(message: $message, results: $results)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BulkMoveResponseImpl &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.results, results) || other.results == results));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, message, results);

  /// Create a copy of BulkMoveResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BulkMoveResponseImplCopyWith<_$BulkMoveResponseImpl> get copyWith =>
      __$$BulkMoveResponseImplCopyWithImpl<_$BulkMoveResponseImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$BulkMoveResponseImplToJson(this);
  }
}

abstract class _BulkMoveResponse implements BulkMoveResponse {
  const factory _BulkMoveResponse({
    required final String message,
    required final BulkMoveResults results,
  }) = _$BulkMoveResponseImpl;

  factory _BulkMoveResponse.fromJson(Map<String, dynamic> json) =
      _$BulkMoveResponseImpl.fromJson;

  @override
  String get message;
  @override
  BulkMoveResults get results;

  /// Create a copy of BulkMoveResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BulkMoveResponseImplCopyWith<_$BulkMoveResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

BulkMoveResults _$BulkMoveResultsFromJson(Map<String, dynamic> json) {
  return _BulkMoveResults.fromJson(json);
}

/// @nodoc
mixin _$BulkMoveResults {
  @JsonKey(name: 'success_count')
  int get successCount => throw _privateConstructorUsedError;
  @JsonKey(name: 'error_count')
  int get errorCount => throw _privateConstructorUsedError;
  List<Map<String, dynamic>> get errors => throw _privateConstructorUsedError;
  @JsonKey(name: 'moved_items')
  List<HierarchyNodeModel> get movedItems => throw _privateConstructorUsedError;

  /// Serializes this BulkMoveResults to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of BulkMoveResults
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BulkMoveResultsCopyWith<BulkMoveResults> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BulkMoveResultsCopyWith<$Res> {
  factory $BulkMoveResultsCopyWith(
    BulkMoveResults value,
    $Res Function(BulkMoveResults) then,
  ) = _$BulkMoveResultsCopyWithImpl<$Res, BulkMoveResults>;
  @useResult
  $Res call({
    @JsonKey(name: 'success_count') int successCount,
    @JsonKey(name: 'error_count') int errorCount,
    List<Map<String, dynamic>> errors,
    @JsonKey(name: 'moved_items') List<HierarchyNodeModel> movedItems,
  });
}

/// @nodoc
class _$BulkMoveResultsCopyWithImpl<$Res, $Val extends BulkMoveResults>
    implements $BulkMoveResultsCopyWith<$Res> {
  _$BulkMoveResultsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BulkMoveResults
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? successCount = null,
    Object? errorCount = null,
    Object? errors = null,
    Object? movedItems = null,
  }) {
    return _then(
      _value.copyWith(
            successCount: null == successCount
                ? _value.successCount
                : successCount // ignore: cast_nullable_to_non_nullable
                      as int,
            errorCount: null == errorCount
                ? _value.errorCount
                : errorCount // ignore: cast_nullable_to_non_nullable
                      as int,
            errors: null == errors
                ? _value.errors
                : errors // ignore: cast_nullable_to_non_nullable
                      as List<Map<String, dynamic>>,
            movedItems: null == movedItems
                ? _value.movedItems
                : movedItems // ignore: cast_nullable_to_non_nullable
                      as List<HierarchyNodeModel>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$BulkMoveResultsImplCopyWith<$Res>
    implements $BulkMoveResultsCopyWith<$Res> {
  factory _$$BulkMoveResultsImplCopyWith(
    _$BulkMoveResultsImpl value,
    $Res Function(_$BulkMoveResultsImpl) then,
  ) = __$$BulkMoveResultsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'success_count') int successCount,
    @JsonKey(name: 'error_count') int errorCount,
    List<Map<String, dynamic>> errors,
    @JsonKey(name: 'moved_items') List<HierarchyNodeModel> movedItems,
  });
}

/// @nodoc
class __$$BulkMoveResultsImplCopyWithImpl<$Res>
    extends _$BulkMoveResultsCopyWithImpl<$Res, _$BulkMoveResultsImpl>
    implements _$$BulkMoveResultsImplCopyWith<$Res> {
  __$$BulkMoveResultsImplCopyWithImpl(
    _$BulkMoveResultsImpl _value,
    $Res Function(_$BulkMoveResultsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of BulkMoveResults
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? successCount = null,
    Object? errorCount = null,
    Object? errors = null,
    Object? movedItems = null,
  }) {
    return _then(
      _$BulkMoveResultsImpl(
        successCount: null == successCount
            ? _value.successCount
            : successCount // ignore: cast_nullable_to_non_nullable
                  as int,
        errorCount: null == errorCount
            ? _value.errorCount
            : errorCount // ignore: cast_nullable_to_non_nullable
                  as int,
        errors: null == errors
            ? _value._errors
            : errors // ignore: cast_nullable_to_non_nullable
                  as List<Map<String, dynamic>>,
        movedItems: null == movedItems
            ? _value._movedItems
            : movedItems // ignore: cast_nullable_to_non_nullable
                  as List<HierarchyNodeModel>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$BulkMoveResultsImpl implements _BulkMoveResults {
  const _$BulkMoveResultsImpl({
    @JsonKey(name: 'success_count') required this.successCount,
    @JsonKey(name: 'error_count') required this.errorCount,
    final List<Map<String, dynamic>> errors = const [],
    @JsonKey(name: 'moved_items')
    final List<HierarchyNodeModel> movedItems = const [],
  }) : _errors = errors,
       _movedItems = movedItems;

  factory _$BulkMoveResultsImpl.fromJson(Map<String, dynamic> json) =>
      _$$BulkMoveResultsImplFromJson(json);

  @override
  @JsonKey(name: 'success_count')
  final int successCount;
  @override
  @JsonKey(name: 'error_count')
  final int errorCount;
  final List<Map<String, dynamic>> _errors;
  @override
  @JsonKey()
  List<Map<String, dynamic>> get errors {
    if (_errors is EqualUnmodifiableListView) return _errors;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_errors);
  }

  final List<HierarchyNodeModel> _movedItems;
  @override
  @JsonKey(name: 'moved_items')
  List<HierarchyNodeModel> get movedItems {
    if (_movedItems is EqualUnmodifiableListView) return _movedItems;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_movedItems);
  }

  @override
  String toString() {
    return 'BulkMoveResults(successCount: $successCount, errorCount: $errorCount, errors: $errors, movedItems: $movedItems)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BulkMoveResultsImpl &&
            (identical(other.successCount, successCount) ||
                other.successCount == successCount) &&
            (identical(other.errorCount, errorCount) ||
                other.errorCount == errorCount) &&
            const DeepCollectionEquality().equals(other._errors, _errors) &&
            const DeepCollectionEquality().equals(
              other._movedItems,
              _movedItems,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    successCount,
    errorCount,
    const DeepCollectionEquality().hash(_errors),
    const DeepCollectionEquality().hash(_movedItems),
  );

  /// Create a copy of BulkMoveResults
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BulkMoveResultsImplCopyWith<_$BulkMoveResultsImpl> get copyWith =>
      __$$BulkMoveResultsImplCopyWithImpl<_$BulkMoveResultsImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$BulkMoveResultsImplToJson(this);
  }
}

abstract class _BulkMoveResults implements BulkMoveResults {
  const factory _BulkMoveResults({
    @JsonKey(name: 'success_count') required final int successCount,
    @JsonKey(name: 'error_count') required final int errorCount,
    final List<Map<String, dynamic>> errors,
    @JsonKey(name: 'moved_items') final List<HierarchyNodeModel> movedItems,
  }) = _$BulkMoveResultsImpl;

  factory _BulkMoveResults.fromJson(Map<String, dynamic> json) =
      _$BulkMoveResultsImpl.fromJson;

  @override
  @JsonKey(name: 'success_count')
  int get successCount;
  @override
  @JsonKey(name: 'error_count')
  int get errorCount;
  @override
  List<Map<String, dynamic>> get errors;
  @override
  @JsonKey(name: 'moved_items')
  List<HierarchyNodeModel> get movedItems;

  /// Create a copy of BulkMoveResults
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BulkMoveResultsImplCopyWith<_$BulkMoveResultsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

BulkDeleteRequest _$BulkDeleteRequestFromJson(Map<String, dynamic> json) {
  return _BulkDeleteRequest.fromJson(json);
}

/// @nodoc
mixin _$BulkDeleteRequest {
  List<MoveItemData> get items => throw _privateConstructorUsedError;
  @JsonKey(name: 'delete_children')
  bool get deleteChildren => throw _privateConstructorUsedError;
  @JsonKey(name: 'reassign_to_id')
  String? get reassignToId => throw _privateConstructorUsedError;
  @JsonKey(name: 'reassign_to_type')
  String? get reassignToType => throw _privateConstructorUsedError;

  /// Serializes this BulkDeleteRequest to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of BulkDeleteRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BulkDeleteRequestCopyWith<BulkDeleteRequest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BulkDeleteRequestCopyWith<$Res> {
  factory $BulkDeleteRequestCopyWith(
    BulkDeleteRequest value,
    $Res Function(BulkDeleteRequest) then,
  ) = _$BulkDeleteRequestCopyWithImpl<$Res, BulkDeleteRequest>;
  @useResult
  $Res call({
    List<MoveItemData> items,
    @JsonKey(name: 'delete_children') bool deleteChildren,
    @JsonKey(name: 'reassign_to_id') String? reassignToId,
    @JsonKey(name: 'reassign_to_type') String? reassignToType,
  });
}

/// @nodoc
class _$BulkDeleteRequestCopyWithImpl<$Res, $Val extends BulkDeleteRequest>
    implements $BulkDeleteRequestCopyWith<$Res> {
  _$BulkDeleteRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BulkDeleteRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? deleteChildren = null,
    Object? reassignToId = freezed,
    Object? reassignToType = freezed,
  }) {
    return _then(
      _value.copyWith(
            items: null == items
                ? _value.items
                : items // ignore: cast_nullable_to_non_nullable
                      as List<MoveItemData>,
            deleteChildren: null == deleteChildren
                ? _value.deleteChildren
                : deleteChildren // ignore: cast_nullable_to_non_nullable
                      as bool,
            reassignToId: freezed == reassignToId
                ? _value.reassignToId
                : reassignToId // ignore: cast_nullable_to_non_nullable
                      as String?,
            reassignToType: freezed == reassignToType
                ? _value.reassignToType
                : reassignToType // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$BulkDeleteRequestImplCopyWith<$Res>
    implements $BulkDeleteRequestCopyWith<$Res> {
  factory _$$BulkDeleteRequestImplCopyWith(
    _$BulkDeleteRequestImpl value,
    $Res Function(_$BulkDeleteRequestImpl) then,
  ) = __$$BulkDeleteRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    List<MoveItemData> items,
    @JsonKey(name: 'delete_children') bool deleteChildren,
    @JsonKey(name: 'reassign_to_id') String? reassignToId,
    @JsonKey(name: 'reassign_to_type') String? reassignToType,
  });
}

/// @nodoc
class __$$BulkDeleteRequestImplCopyWithImpl<$Res>
    extends _$BulkDeleteRequestCopyWithImpl<$Res, _$BulkDeleteRequestImpl>
    implements _$$BulkDeleteRequestImplCopyWith<$Res> {
  __$$BulkDeleteRequestImplCopyWithImpl(
    _$BulkDeleteRequestImpl _value,
    $Res Function(_$BulkDeleteRequestImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of BulkDeleteRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? deleteChildren = null,
    Object? reassignToId = freezed,
    Object? reassignToType = freezed,
  }) {
    return _then(
      _$BulkDeleteRequestImpl(
        items: null == items
            ? _value._items
            : items // ignore: cast_nullable_to_non_nullable
                  as List<MoveItemData>,
        deleteChildren: null == deleteChildren
            ? _value.deleteChildren
            : deleteChildren // ignore: cast_nullable_to_non_nullable
                  as bool,
        reassignToId: freezed == reassignToId
            ? _value.reassignToId
            : reassignToId // ignore: cast_nullable_to_non_nullable
                  as String?,
        reassignToType: freezed == reassignToType
            ? _value.reassignToType
            : reassignToType // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$BulkDeleteRequestImpl extends _BulkDeleteRequest {
  const _$BulkDeleteRequestImpl({
    required final List<MoveItemData> items,
    @JsonKey(name: 'delete_children') required this.deleteChildren,
    @JsonKey(name: 'reassign_to_id') this.reassignToId,
    @JsonKey(name: 'reassign_to_type') this.reassignToType,
  }) : _items = items,
       super._();

  factory _$BulkDeleteRequestImpl.fromJson(Map<String, dynamic> json) =>
      _$$BulkDeleteRequestImplFromJson(json);

  final List<MoveItemData> _items;
  @override
  List<MoveItemData> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  @JsonKey(name: 'delete_children')
  final bool deleteChildren;
  @override
  @JsonKey(name: 'reassign_to_id')
  final String? reassignToId;
  @override
  @JsonKey(name: 'reassign_to_type')
  final String? reassignToType;

  @override
  String toString() {
    return 'BulkDeleteRequest(items: $items, deleteChildren: $deleteChildren, reassignToId: $reassignToId, reassignToType: $reassignToType)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BulkDeleteRequestImpl &&
            const DeepCollectionEquality().equals(other._items, _items) &&
            (identical(other.deleteChildren, deleteChildren) ||
                other.deleteChildren == deleteChildren) &&
            (identical(other.reassignToId, reassignToId) ||
                other.reassignToId == reassignToId) &&
            (identical(other.reassignToType, reassignToType) ||
                other.reassignToType == reassignToType));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_items),
    deleteChildren,
    reassignToId,
    reassignToType,
  );

  /// Create a copy of BulkDeleteRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BulkDeleteRequestImplCopyWith<_$BulkDeleteRequestImpl> get copyWith =>
      __$$BulkDeleteRequestImplCopyWithImpl<_$BulkDeleteRequestImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$BulkDeleteRequestImplToJson(this);
  }
}

abstract class _BulkDeleteRequest extends BulkDeleteRequest {
  const factory _BulkDeleteRequest({
    required final List<MoveItemData> items,
    @JsonKey(name: 'delete_children') required final bool deleteChildren,
    @JsonKey(name: 'reassign_to_id') final String? reassignToId,
    @JsonKey(name: 'reassign_to_type') final String? reassignToType,
  }) = _$BulkDeleteRequestImpl;
  const _BulkDeleteRequest._() : super._();

  factory _BulkDeleteRequest.fromJson(Map<String, dynamic> json) =
      _$BulkDeleteRequestImpl.fromJson;

  @override
  List<MoveItemData> get items;
  @override
  @JsonKey(name: 'delete_children')
  bool get deleteChildren;
  @override
  @JsonKey(name: 'reassign_to_id')
  String? get reassignToId;
  @override
  @JsonKey(name: 'reassign_to_type')
  String? get reassignToType;

  /// Create a copy of BulkDeleteRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BulkDeleteRequestImplCopyWith<_$BulkDeleteRequestImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

BulkDeleteResponse _$BulkDeleteResponseFromJson(Map<String, dynamic> json) {
  return _BulkDeleteResponse.fromJson(json);
}

/// @nodoc
mixin _$BulkDeleteResponse {
  String get message => throw _privateConstructorUsedError;
  BulkDeleteResults get results => throw _privateConstructorUsedError;

  /// Serializes this BulkDeleteResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of BulkDeleteResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BulkDeleteResponseCopyWith<BulkDeleteResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BulkDeleteResponseCopyWith<$Res> {
  factory $BulkDeleteResponseCopyWith(
    BulkDeleteResponse value,
    $Res Function(BulkDeleteResponse) then,
  ) = _$BulkDeleteResponseCopyWithImpl<$Res, BulkDeleteResponse>;
  @useResult
  $Res call({String message, BulkDeleteResults results});

  $BulkDeleteResultsCopyWith<$Res> get results;
}

/// @nodoc
class _$BulkDeleteResponseCopyWithImpl<$Res, $Val extends BulkDeleteResponse>
    implements $BulkDeleteResponseCopyWith<$Res> {
  _$BulkDeleteResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BulkDeleteResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? message = null, Object? results = null}) {
    return _then(
      _value.copyWith(
            message: null == message
                ? _value.message
                : message // ignore: cast_nullable_to_non_nullable
                      as String,
            results: null == results
                ? _value.results
                : results // ignore: cast_nullable_to_non_nullable
                      as BulkDeleteResults,
          )
          as $Val,
    );
  }

  /// Create a copy of BulkDeleteResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $BulkDeleteResultsCopyWith<$Res> get results {
    return $BulkDeleteResultsCopyWith<$Res>(_value.results, (value) {
      return _then(_value.copyWith(results: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$BulkDeleteResponseImplCopyWith<$Res>
    implements $BulkDeleteResponseCopyWith<$Res> {
  factory _$$BulkDeleteResponseImplCopyWith(
    _$BulkDeleteResponseImpl value,
    $Res Function(_$BulkDeleteResponseImpl) then,
  ) = __$$BulkDeleteResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String message, BulkDeleteResults results});

  @override
  $BulkDeleteResultsCopyWith<$Res> get results;
}

/// @nodoc
class __$$BulkDeleteResponseImplCopyWithImpl<$Res>
    extends _$BulkDeleteResponseCopyWithImpl<$Res, _$BulkDeleteResponseImpl>
    implements _$$BulkDeleteResponseImplCopyWith<$Res> {
  __$$BulkDeleteResponseImplCopyWithImpl(
    _$BulkDeleteResponseImpl _value,
    $Res Function(_$BulkDeleteResponseImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of BulkDeleteResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? message = null, Object? results = null}) {
    return _then(
      _$BulkDeleteResponseImpl(
        message: null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String,
        results: null == results
            ? _value.results
            : results // ignore: cast_nullable_to_non_nullable
                  as BulkDeleteResults,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$BulkDeleteResponseImpl implements _BulkDeleteResponse {
  const _$BulkDeleteResponseImpl({
    required this.message,
    required this.results,
  });

  factory _$BulkDeleteResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$BulkDeleteResponseImplFromJson(json);

  @override
  final String message;
  @override
  final BulkDeleteResults results;

  @override
  String toString() {
    return 'BulkDeleteResponse(message: $message, results: $results)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BulkDeleteResponseImpl &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.results, results) || other.results == results));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, message, results);

  /// Create a copy of BulkDeleteResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BulkDeleteResponseImplCopyWith<_$BulkDeleteResponseImpl> get copyWith =>
      __$$BulkDeleteResponseImplCopyWithImpl<_$BulkDeleteResponseImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$BulkDeleteResponseImplToJson(this);
  }
}

abstract class _BulkDeleteResponse implements BulkDeleteResponse {
  const factory _BulkDeleteResponse({
    required final String message,
    required final BulkDeleteResults results,
  }) = _$BulkDeleteResponseImpl;

  factory _BulkDeleteResponse.fromJson(Map<String, dynamic> json) =
      _$BulkDeleteResponseImpl.fromJson;

  @override
  String get message;
  @override
  BulkDeleteResults get results;

  /// Create a copy of BulkDeleteResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BulkDeleteResponseImplCopyWith<_$BulkDeleteResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

BulkDeleteResults _$BulkDeleteResultsFromJson(Map<String, dynamic> json) {
  return _BulkDeleteResults.fromJson(json);
}

/// @nodoc
mixin _$BulkDeleteResults {
  @JsonKey(name: 'deleted_count')
  int get deletedCount => throw _privateConstructorUsedError;
  @JsonKey(name: 'reassigned_count')
  int? get reassignedCount => throw _privateConstructorUsedError;
  @JsonKey(name: 'error_count')
  int get errorCount => throw _privateConstructorUsedError;
  List<Map<String, dynamic>> get errors => throw _privateConstructorUsedError;

  /// Serializes this BulkDeleteResults to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of BulkDeleteResults
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BulkDeleteResultsCopyWith<BulkDeleteResults> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BulkDeleteResultsCopyWith<$Res> {
  factory $BulkDeleteResultsCopyWith(
    BulkDeleteResults value,
    $Res Function(BulkDeleteResults) then,
  ) = _$BulkDeleteResultsCopyWithImpl<$Res, BulkDeleteResults>;
  @useResult
  $Res call({
    @JsonKey(name: 'deleted_count') int deletedCount,
    @JsonKey(name: 'reassigned_count') int? reassignedCount,
    @JsonKey(name: 'error_count') int errorCount,
    List<Map<String, dynamic>> errors,
  });
}

/// @nodoc
class _$BulkDeleteResultsCopyWithImpl<$Res, $Val extends BulkDeleteResults>
    implements $BulkDeleteResultsCopyWith<$Res> {
  _$BulkDeleteResultsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BulkDeleteResults
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? deletedCount = null,
    Object? reassignedCount = freezed,
    Object? errorCount = null,
    Object? errors = null,
  }) {
    return _then(
      _value.copyWith(
            deletedCount: null == deletedCount
                ? _value.deletedCount
                : deletedCount // ignore: cast_nullable_to_non_nullable
                      as int,
            reassignedCount: freezed == reassignedCount
                ? _value.reassignedCount
                : reassignedCount // ignore: cast_nullable_to_non_nullable
                      as int?,
            errorCount: null == errorCount
                ? _value.errorCount
                : errorCount // ignore: cast_nullable_to_non_nullable
                      as int,
            errors: null == errors
                ? _value.errors
                : errors // ignore: cast_nullable_to_non_nullable
                      as List<Map<String, dynamic>>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$BulkDeleteResultsImplCopyWith<$Res>
    implements $BulkDeleteResultsCopyWith<$Res> {
  factory _$$BulkDeleteResultsImplCopyWith(
    _$BulkDeleteResultsImpl value,
    $Res Function(_$BulkDeleteResultsImpl) then,
  ) = __$$BulkDeleteResultsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'deleted_count') int deletedCount,
    @JsonKey(name: 'reassigned_count') int? reassignedCount,
    @JsonKey(name: 'error_count') int errorCount,
    List<Map<String, dynamic>> errors,
  });
}

/// @nodoc
class __$$BulkDeleteResultsImplCopyWithImpl<$Res>
    extends _$BulkDeleteResultsCopyWithImpl<$Res, _$BulkDeleteResultsImpl>
    implements _$$BulkDeleteResultsImplCopyWith<$Res> {
  __$$BulkDeleteResultsImplCopyWithImpl(
    _$BulkDeleteResultsImpl _value,
    $Res Function(_$BulkDeleteResultsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of BulkDeleteResults
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? deletedCount = null,
    Object? reassignedCount = freezed,
    Object? errorCount = null,
    Object? errors = null,
  }) {
    return _then(
      _$BulkDeleteResultsImpl(
        deletedCount: null == deletedCount
            ? _value.deletedCount
            : deletedCount // ignore: cast_nullable_to_non_nullable
                  as int,
        reassignedCount: freezed == reassignedCount
            ? _value.reassignedCount
            : reassignedCount // ignore: cast_nullable_to_non_nullable
                  as int?,
        errorCount: null == errorCount
            ? _value.errorCount
            : errorCount // ignore: cast_nullable_to_non_nullable
                  as int,
        errors: null == errors
            ? _value._errors
            : errors // ignore: cast_nullable_to_non_nullable
                  as List<Map<String, dynamic>>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$BulkDeleteResultsImpl implements _BulkDeleteResults {
  const _$BulkDeleteResultsImpl({
    @JsonKey(name: 'deleted_count') required this.deletedCount,
    @JsonKey(name: 'reassigned_count') this.reassignedCount,
    @JsonKey(name: 'error_count') required this.errorCount,
    final List<Map<String, dynamic>> errors = const [],
  }) : _errors = errors;

  factory _$BulkDeleteResultsImpl.fromJson(Map<String, dynamic> json) =>
      _$$BulkDeleteResultsImplFromJson(json);

  @override
  @JsonKey(name: 'deleted_count')
  final int deletedCount;
  @override
  @JsonKey(name: 'reassigned_count')
  final int? reassignedCount;
  @override
  @JsonKey(name: 'error_count')
  final int errorCount;
  final List<Map<String, dynamic>> _errors;
  @override
  @JsonKey()
  List<Map<String, dynamic>> get errors {
    if (_errors is EqualUnmodifiableListView) return _errors;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_errors);
  }

  @override
  String toString() {
    return 'BulkDeleteResults(deletedCount: $deletedCount, reassignedCount: $reassignedCount, errorCount: $errorCount, errors: $errors)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BulkDeleteResultsImpl &&
            (identical(other.deletedCount, deletedCount) ||
                other.deletedCount == deletedCount) &&
            (identical(other.reassignedCount, reassignedCount) ||
                other.reassignedCount == reassignedCount) &&
            (identical(other.errorCount, errorCount) ||
                other.errorCount == errorCount) &&
            const DeepCollectionEquality().equals(other._errors, _errors));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    deletedCount,
    reassignedCount,
    errorCount,
    const DeepCollectionEquality().hash(_errors),
  );

  /// Create a copy of BulkDeleteResults
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BulkDeleteResultsImplCopyWith<_$BulkDeleteResultsImpl> get copyWith =>
      __$$BulkDeleteResultsImplCopyWithImpl<_$BulkDeleteResultsImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$BulkDeleteResultsImplToJson(this);
  }
}

abstract class _BulkDeleteResults implements BulkDeleteResults {
  const factory _BulkDeleteResults({
    @JsonKey(name: 'deleted_count') required final int deletedCount,
    @JsonKey(name: 'reassigned_count') final int? reassignedCount,
    @JsonKey(name: 'error_count') required final int errorCount,
    final List<Map<String, dynamic>> errors,
  }) = _$BulkDeleteResultsImpl;

  factory _BulkDeleteResults.fromJson(Map<String, dynamic> json) =
      _$BulkDeleteResultsImpl.fromJson;

  @override
  @JsonKey(name: 'deleted_count')
  int get deletedCount;
  @override
  @JsonKey(name: 'reassigned_count')
  int? get reassignedCount;
  @override
  @JsonKey(name: 'error_count')
  int get errorCount;
  @override
  List<Map<String, dynamic>> get errors;

  /// Create a copy of BulkDeleteResults
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BulkDeleteResultsImplCopyWith<_$BulkDeleteResultsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
