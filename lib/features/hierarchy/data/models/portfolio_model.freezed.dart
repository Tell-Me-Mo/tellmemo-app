// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'portfolio_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

PortfolioModel _$PortfolioModelFromJson(Map<String, dynamic> json) {
  return _PortfolioModel.fromJson(json);
}

/// @nodoc
mixin _$PortfolioModel {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  String? get owner => throw _privateConstructorUsedError;
  @JsonKey(name: 'health_status')
  String get healthStatus => throw _privateConstructorUsedError;
  @JsonKey(name: 'risk_summary')
  String? get riskSummary => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_by')
  String? get createdBy => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  String get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  String get updatedAt => throw _privateConstructorUsedError;
  List<ProgramModel> get programs => throw _privateConstructorUsedError;
  @JsonKey(name: 'direct_projects')
  List<ProjectModel> get directProjects => throw _privateConstructorUsedError;
  @JsonKey(name: 'program_count')
  int get programCount => throw _privateConstructorUsedError;
  @JsonKey(name: 'direct_project_count')
  int get directProjectCount => throw _privateConstructorUsedError;
  @JsonKey(name: 'total_project_count')
  int get totalProjectCount => throw _privateConstructorUsedError;

  /// Serializes this PortfolioModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PortfolioModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PortfolioModelCopyWith<PortfolioModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PortfolioModelCopyWith<$Res> {
  factory $PortfolioModelCopyWith(
    PortfolioModel value,
    $Res Function(PortfolioModel) then,
  ) = _$PortfolioModelCopyWithImpl<$Res, PortfolioModel>;
  @useResult
  $Res call({
    String id,
    String name,
    String? description,
    String? owner,
    @JsonKey(name: 'health_status') String healthStatus,
    @JsonKey(name: 'risk_summary') String? riskSummary,
    @JsonKey(name: 'created_by') String? createdBy,
    @JsonKey(name: 'created_at') String createdAt,
    @JsonKey(name: 'updated_at') String updatedAt,
    List<ProgramModel> programs,
    @JsonKey(name: 'direct_projects') List<ProjectModel> directProjects,
    @JsonKey(name: 'program_count') int programCount,
    @JsonKey(name: 'direct_project_count') int directProjectCount,
    @JsonKey(name: 'total_project_count') int totalProjectCount,
  });
}

/// @nodoc
class _$PortfolioModelCopyWithImpl<$Res, $Val extends PortfolioModel>
    implements $PortfolioModelCopyWith<$Res> {
  _$PortfolioModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PortfolioModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = freezed,
    Object? owner = freezed,
    Object? healthStatus = null,
    Object? riskSummary = freezed,
    Object? createdBy = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? programs = null,
    Object? directProjects = null,
    Object? programCount = null,
    Object? directProjectCount = null,
    Object? totalProjectCount = null,
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
            owner: freezed == owner
                ? _value.owner
                : owner // ignore: cast_nullable_to_non_nullable
                      as String?,
            healthStatus: null == healthStatus
                ? _value.healthStatus
                : healthStatus // ignore: cast_nullable_to_non_nullable
                      as String,
            riskSummary: freezed == riskSummary
                ? _value.riskSummary
                : riskSummary // ignore: cast_nullable_to_non_nullable
                      as String?,
            createdBy: freezed == createdBy
                ? _value.createdBy
                : createdBy // ignore: cast_nullable_to_non_nullable
                      as String?,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as String,
            updatedAt: null == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as String,
            programs: null == programs
                ? _value.programs
                : programs // ignore: cast_nullable_to_non_nullable
                      as List<ProgramModel>,
            directProjects: null == directProjects
                ? _value.directProjects
                : directProjects // ignore: cast_nullable_to_non_nullable
                      as List<ProjectModel>,
            programCount: null == programCount
                ? _value.programCount
                : programCount // ignore: cast_nullable_to_non_nullable
                      as int,
            directProjectCount: null == directProjectCount
                ? _value.directProjectCount
                : directProjectCount // ignore: cast_nullable_to_non_nullable
                      as int,
            totalProjectCount: null == totalProjectCount
                ? _value.totalProjectCount
                : totalProjectCount // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PortfolioModelImplCopyWith<$Res>
    implements $PortfolioModelCopyWith<$Res> {
  factory _$$PortfolioModelImplCopyWith(
    _$PortfolioModelImpl value,
    $Res Function(_$PortfolioModelImpl) then,
  ) = __$$PortfolioModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    String? description,
    String? owner,
    @JsonKey(name: 'health_status') String healthStatus,
    @JsonKey(name: 'risk_summary') String? riskSummary,
    @JsonKey(name: 'created_by') String? createdBy,
    @JsonKey(name: 'created_at') String createdAt,
    @JsonKey(name: 'updated_at') String updatedAt,
    List<ProgramModel> programs,
    @JsonKey(name: 'direct_projects') List<ProjectModel> directProjects,
    @JsonKey(name: 'program_count') int programCount,
    @JsonKey(name: 'direct_project_count') int directProjectCount,
    @JsonKey(name: 'total_project_count') int totalProjectCount,
  });
}

/// @nodoc
class __$$PortfolioModelImplCopyWithImpl<$Res>
    extends _$PortfolioModelCopyWithImpl<$Res, _$PortfolioModelImpl>
    implements _$$PortfolioModelImplCopyWith<$Res> {
  __$$PortfolioModelImplCopyWithImpl(
    _$PortfolioModelImpl _value,
    $Res Function(_$PortfolioModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PortfolioModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = freezed,
    Object? owner = freezed,
    Object? healthStatus = null,
    Object? riskSummary = freezed,
    Object? createdBy = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? programs = null,
    Object? directProjects = null,
    Object? programCount = null,
    Object? directProjectCount = null,
    Object? totalProjectCount = null,
  }) {
    return _then(
      _$PortfolioModelImpl(
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
        owner: freezed == owner
            ? _value.owner
            : owner // ignore: cast_nullable_to_non_nullable
                  as String?,
        healthStatus: null == healthStatus
            ? _value.healthStatus
            : healthStatus // ignore: cast_nullable_to_non_nullable
                  as String,
        riskSummary: freezed == riskSummary
            ? _value.riskSummary
            : riskSummary // ignore: cast_nullable_to_non_nullable
                  as String?,
        createdBy: freezed == createdBy
            ? _value.createdBy
            : createdBy // ignore: cast_nullable_to_non_nullable
                  as String?,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as String,
        updatedAt: null == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as String,
        programs: null == programs
            ? _value._programs
            : programs // ignore: cast_nullable_to_non_nullable
                  as List<ProgramModel>,
        directProjects: null == directProjects
            ? _value._directProjects
            : directProjects // ignore: cast_nullable_to_non_nullable
                  as List<ProjectModel>,
        programCount: null == programCount
            ? _value.programCount
            : programCount // ignore: cast_nullable_to_non_nullable
                  as int,
        directProjectCount: null == directProjectCount
            ? _value.directProjectCount
            : directProjectCount // ignore: cast_nullable_to_non_nullable
                  as int,
        totalProjectCount: null == totalProjectCount
            ? _value.totalProjectCount
            : totalProjectCount // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PortfolioModelImpl implements _PortfolioModel {
  const _$PortfolioModelImpl({
    required this.id,
    required this.name,
    this.description,
    this.owner,
    @JsonKey(name: 'health_status') this.healthStatus = 'not_set',
    @JsonKey(name: 'risk_summary') this.riskSummary,
    @JsonKey(name: 'created_by') this.createdBy,
    @JsonKey(name: 'created_at') required this.createdAt,
    @JsonKey(name: 'updated_at') required this.updatedAt,
    final List<ProgramModel> programs = const [],
    @JsonKey(name: 'direct_projects')
    final List<ProjectModel> directProjects = const [],
    @JsonKey(name: 'program_count') this.programCount = 0,
    @JsonKey(name: 'direct_project_count') this.directProjectCount = 0,
    @JsonKey(name: 'total_project_count') this.totalProjectCount = 0,
  }) : _programs = programs,
       _directProjects = directProjects;

  factory _$PortfolioModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$PortfolioModelImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String? description;
  @override
  final String? owner;
  @override
  @JsonKey(name: 'health_status')
  final String healthStatus;
  @override
  @JsonKey(name: 'risk_summary')
  final String? riskSummary;
  @override
  @JsonKey(name: 'created_by')
  final String? createdBy;
  @override
  @JsonKey(name: 'created_at')
  final String createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final String updatedAt;
  final List<ProgramModel> _programs;
  @override
  @JsonKey()
  List<ProgramModel> get programs {
    if (_programs is EqualUnmodifiableListView) return _programs;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_programs);
  }

  final List<ProjectModel> _directProjects;
  @override
  @JsonKey(name: 'direct_projects')
  List<ProjectModel> get directProjects {
    if (_directProjects is EqualUnmodifiableListView) return _directProjects;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_directProjects);
  }

  @override
  @JsonKey(name: 'program_count')
  final int programCount;
  @override
  @JsonKey(name: 'direct_project_count')
  final int directProjectCount;
  @override
  @JsonKey(name: 'total_project_count')
  final int totalProjectCount;

  @override
  String toString() {
    return 'PortfolioModel(id: $id, name: $name, description: $description, owner: $owner, healthStatus: $healthStatus, riskSummary: $riskSummary, createdBy: $createdBy, createdAt: $createdAt, updatedAt: $updatedAt, programs: $programs, directProjects: $directProjects, programCount: $programCount, directProjectCount: $directProjectCount, totalProjectCount: $totalProjectCount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PortfolioModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.owner, owner) || other.owner == owner) &&
            (identical(other.healthStatus, healthStatus) ||
                other.healthStatus == healthStatus) &&
            (identical(other.riskSummary, riskSummary) ||
                other.riskSummary == riskSummary) &&
            (identical(other.createdBy, createdBy) ||
                other.createdBy == createdBy) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            const DeepCollectionEquality().equals(other._programs, _programs) &&
            const DeepCollectionEquality().equals(
              other._directProjects,
              _directProjects,
            ) &&
            (identical(other.programCount, programCount) ||
                other.programCount == programCount) &&
            (identical(other.directProjectCount, directProjectCount) ||
                other.directProjectCount == directProjectCount) &&
            (identical(other.totalProjectCount, totalProjectCount) ||
                other.totalProjectCount == totalProjectCount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    description,
    owner,
    healthStatus,
    riskSummary,
    createdBy,
    createdAt,
    updatedAt,
    const DeepCollectionEquality().hash(_programs),
    const DeepCollectionEquality().hash(_directProjects),
    programCount,
    directProjectCount,
    totalProjectCount,
  );

  /// Create a copy of PortfolioModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PortfolioModelImplCopyWith<_$PortfolioModelImpl> get copyWith =>
      __$$PortfolioModelImplCopyWithImpl<_$PortfolioModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$PortfolioModelImplToJson(this);
  }
}

abstract class _PortfolioModel implements PortfolioModel {
  const factory _PortfolioModel({
    required final String id,
    required final String name,
    final String? description,
    final String? owner,
    @JsonKey(name: 'health_status') final String healthStatus,
    @JsonKey(name: 'risk_summary') final String? riskSummary,
    @JsonKey(name: 'created_by') final String? createdBy,
    @JsonKey(name: 'created_at') required final String createdAt,
    @JsonKey(name: 'updated_at') required final String updatedAt,
    final List<ProgramModel> programs,
    @JsonKey(name: 'direct_projects') final List<ProjectModel> directProjects,
    @JsonKey(name: 'program_count') final int programCount,
    @JsonKey(name: 'direct_project_count') final int directProjectCount,
    @JsonKey(name: 'total_project_count') final int totalProjectCount,
  }) = _$PortfolioModelImpl;

  factory _PortfolioModel.fromJson(Map<String, dynamic> json) =
      _$PortfolioModelImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String? get description;
  @override
  String? get owner;
  @override
  @JsonKey(name: 'health_status')
  String get healthStatus;
  @override
  @JsonKey(name: 'risk_summary')
  String? get riskSummary;
  @override
  @JsonKey(name: 'created_by')
  String? get createdBy;
  @override
  @JsonKey(name: 'created_at')
  String get createdAt;
  @override
  @JsonKey(name: 'updated_at')
  String get updatedAt;
  @override
  List<ProgramModel> get programs;
  @override
  @JsonKey(name: 'direct_projects')
  List<ProjectModel> get directProjects;
  @override
  @JsonKey(name: 'program_count')
  int get programCount;
  @override
  @JsonKey(name: 'direct_project_count')
  int get directProjectCount;
  @override
  @JsonKey(name: 'total_project_count')
  int get totalProjectCount;

  /// Create a copy of PortfolioModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PortfolioModelImplCopyWith<_$PortfolioModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
