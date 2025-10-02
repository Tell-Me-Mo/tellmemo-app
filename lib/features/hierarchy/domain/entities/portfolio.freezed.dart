// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'portfolio.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$Portfolio {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  String? get owner => throw _privateConstructorUsedError;
  HealthStatus get healthStatus => throw _privateConstructorUsedError;
  String? get riskSummary => throw _privateConstructorUsedError;
  String? get createdBy => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;
  List<Program> get programs => throw _privateConstructorUsedError;
  List<Project> get directProjects => throw _privateConstructorUsedError;

  /// Create a copy of Portfolio
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PortfolioCopyWith<Portfolio> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PortfolioCopyWith<$Res> {
  factory $PortfolioCopyWith(Portfolio value, $Res Function(Portfolio) then) =
      _$PortfolioCopyWithImpl<$Res, Portfolio>;
  @useResult
  $Res call({
    String id,
    String name,
    String? description,
    String? owner,
    HealthStatus healthStatus,
    String? riskSummary,
    String? createdBy,
    DateTime createdAt,
    DateTime updatedAt,
    List<Program> programs,
    List<Project> directProjects,
  });
}

/// @nodoc
class _$PortfolioCopyWithImpl<$Res, $Val extends Portfolio>
    implements $PortfolioCopyWith<$Res> {
  _$PortfolioCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Portfolio
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
                      as HealthStatus,
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
                      as DateTime,
            updatedAt: null == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            programs: null == programs
                ? _value.programs
                : programs // ignore: cast_nullable_to_non_nullable
                      as List<Program>,
            directProjects: null == directProjects
                ? _value.directProjects
                : directProjects // ignore: cast_nullable_to_non_nullable
                      as List<Project>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PortfolioImplCopyWith<$Res>
    implements $PortfolioCopyWith<$Res> {
  factory _$$PortfolioImplCopyWith(
    _$PortfolioImpl value,
    $Res Function(_$PortfolioImpl) then,
  ) = __$$PortfolioImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    String? description,
    String? owner,
    HealthStatus healthStatus,
    String? riskSummary,
    String? createdBy,
    DateTime createdAt,
    DateTime updatedAt,
    List<Program> programs,
    List<Project> directProjects,
  });
}

/// @nodoc
class __$$PortfolioImplCopyWithImpl<$Res>
    extends _$PortfolioCopyWithImpl<$Res, _$PortfolioImpl>
    implements _$$PortfolioImplCopyWith<$Res> {
  __$$PortfolioImplCopyWithImpl(
    _$PortfolioImpl _value,
    $Res Function(_$PortfolioImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Portfolio
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
  }) {
    return _then(
      _$PortfolioImpl(
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
                  as HealthStatus,
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
                  as DateTime,
        updatedAt: null == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        programs: null == programs
            ? _value._programs
            : programs // ignore: cast_nullable_to_non_nullable
                  as List<Program>,
        directProjects: null == directProjects
            ? _value._directProjects
            : directProjects // ignore: cast_nullable_to_non_nullable
                  as List<Project>,
      ),
    );
  }
}

/// @nodoc

class _$PortfolioImpl extends _Portfolio {
  const _$PortfolioImpl({
    required this.id,
    required this.name,
    this.description,
    this.owner,
    this.healthStatus = HealthStatus.notSet,
    this.riskSummary,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    final List<Program> programs = const [],
    final List<Project> directProjects = const [],
  }) : _programs = programs,
       _directProjects = directProjects,
       super._();

  @override
  final String id;
  @override
  final String name;
  @override
  final String? description;
  @override
  final String? owner;
  @override
  @JsonKey()
  final HealthStatus healthStatus;
  @override
  final String? riskSummary;
  @override
  final String? createdBy;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  final List<Program> _programs;
  @override
  @JsonKey()
  List<Program> get programs {
    if (_programs is EqualUnmodifiableListView) return _programs;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_programs);
  }

  final List<Project> _directProjects;
  @override
  @JsonKey()
  List<Project> get directProjects {
    if (_directProjects is EqualUnmodifiableListView) return _directProjects;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_directProjects);
  }

  @override
  String toString() {
    return 'Portfolio(id: $id, name: $name, description: $description, owner: $owner, healthStatus: $healthStatus, riskSummary: $riskSummary, createdBy: $createdBy, createdAt: $createdAt, updatedAt: $updatedAt, programs: $programs, directProjects: $directProjects)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PortfolioImpl &&
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
            ));
  }

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
  );

  /// Create a copy of Portfolio
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PortfolioImplCopyWith<_$PortfolioImpl> get copyWith =>
      __$$PortfolioImplCopyWithImpl<_$PortfolioImpl>(this, _$identity);
}

abstract class _Portfolio extends Portfolio {
  const factory _Portfolio({
    required final String id,
    required final String name,
    final String? description,
    final String? owner,
    final HealthStatus healthStatus,
    final String? riskSummary,
    final String? createdBy,
    required final DateTime createdAt,
    required final DateTime updatedAt,
    final List<Program> programs,
    final List<Project> directProjects,
  }) = _$PortfolioImpl;
  const _Portfolio._() : super._();

  @override
  String get id;
  @override
  String get name;
  @override
  String? get description;
  @override
  String? get owner;
  @override
  HealthStatus get healthStatus;
  @override
  String? get riskSummary;
  @override
  String? get createdBy;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;
  @override
  List<Program> get programs;
  @override
  List<Project> get directProjects;

  /// Create a copy of Portfolio
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PortfolioImplCopyWith<_$PortfolioImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
