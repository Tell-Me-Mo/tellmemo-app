// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'organization_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

OrganizationModel _$OrganizationModelFromJson(Map<String, dynamic> json) {
  return _OrganizationModel.fromJson(json);
}

/// @nodoc
mixin _$OrganizationModel {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get slug => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  @JsonKey(name: 'logo_url')
  String? get logoUrl => throw _privateConstructorUsedError;
  Map<String, dynamic> get settings => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_active')
  bool get isActive => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_by')
  String? get createdBy => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  DateTime get updatedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'member_count')
  int? get memberCount => throw _privateConstructorUsedError;
  @JsonKey(name: 'current_user_role')
  String? get currentUserRole => throw _privateConstructorUsedError;
  @JsonKey(name: 'current_user_id')
  String? get currentUserId => throw _privateConstructorUsedError;
  @JsonKey(name: 'project_count')
  int? get projectCount => throw _privateConstructorUsedError;
  @JsonKey(name: 'document_count')
  int? get documentCount => throw _privateConstructorUsedError;

  /// Serializes this OrganizationModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of OrganizationModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OrganizationModelCopyWith<OrganizationModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OrganizationModelCopyWith<$Res> {
  factory $OrganizationModelCopyWith(
    OrganizationModel value,
    $Res Function(OrganizationModel) then,
  ) = _$OrganizationModelCopyWithImpl<$Res, OrganizationModel>;
  @useResult
  $Res call({
    String id,
    String name,
    String slug,
    String? description,
    @JsonKey(name: 'logo_url') String? logoUrl,
    Map<String, dynamic> settings,
    @JsonKey(name: 'is_active') bool isActive,
    @JsonKey(name: 'created_by') String? createdBy,
    @JsonKey(name: 'created_at') DateTime createdAt,
    @JsonKey(name: 'updated_at') DateTime updatedAt,
    @JsonKey(name: 'member_count') int? memberCount,
    @JsonKey(name: 'current_user_role') String? currentUserRole,
    @JsonKey(name: 'current_user_id') String? currentUserId,
    @JsonKey(name: 'project_count') int? projectCount,
    @JsonKey(name: 'document_count') int? documentCount,
  });
}

/// @nodoc
class _$OrganizationModelCopyWithImpl<$Res, $Val extends OrganizationModel>
    implements $OrganizationModelCopyWith<$Res> {
  _$OrganizationModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of OrganizationModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? slug = null,
    Object? description = freezed,
    Object? logoUrl = freezed,
    Object? settings = null,
    Object? isActive = null,
    Object? createdBy = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? memberCount = freezed,
    Object? currentUserRole = freezed,
    Object? currentUserId = freezed,
    Object? projectCount = freezed,
    Object? documentCount = freezed,
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
            slug: null == slug
                ? _value.slug
                : slug // ignore: cast_nullable_to_non_nullable
                      as String,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
            logoUrl: freezed == logoUrl
                ? _value.logoUrl
                : logoUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            settings: null == settings
                ? _value.settings
                : settings // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>,
            isActive: null == isActive
                ? _value.isActive
                : isActive // ignore: cast_nullable_to_non_nullable
                      as bool,
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
            memberCount: freezed == memberCount
                ? _value.memberCount
                : memberCount // ignore: cast_nullable_to_non_nullable
                      as int?,
            currentUserRole: freezed == currentUserRole
                ? _value.currentUserRole
                : currentUserRole // ignore: cast_nullable_to_non_nullable
                      as String?,
            currentUserId: freezed == currentUserId
                ? _value.currentUserId
                : currentUserId // ignore: cast_nullable_to_non_nullable
                      as String?,
            projectCount: freezed == projectCount
                ? _value.projectCount
                : projectCount // ignore: cast_nullable_to_non_nullable
                      as int?,
            documentCount: freezed == documentCount
                ? _value.documentCount
                : documentCount // ignore: cast_nullable_to_non_nullable
                      as int?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$OrganizationModelImplCopyWith<$Res>
    implements $OrganizationModelCopyWith<$Res> {
  factory _$$OrganizationModelImplCopyWith(
    _$OrganizationModelImpl value,
    $Res Function(_$OrganizationModelImpl) then,
  ) = __$$OrganizationModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    String slug,
    String? description,
    @JsonKey(name: 'logo_url') String? logoUrl,
    Map<String, dynamic> settings,
    @JsonKey(name: 'is_active') bool isActive,
    @JsonKey(name: 'created_by') String? createdBy,
    @JsonKey(name: 'created_at') DateTime createdAt,
    @JsonKey(name: 'updated_at') DateTime updatedAt,
    @JsonKey(name: 'member_count') int? memberCount,
    @JsonKey(name: 'current_user_role') String? currentUserRole,
    @JsonKey(name: 'current_user_id') String? currentUserId,
    @JsonKey(name: 'project_count') int? projectCount,
    @JsonKey(name: 'document_count') int? documentCount,
  });
}

/// @nodoc
class __$$OrganizationModelImplCopyWithImpl<$Res>
    extends _$OrganizationModelCopyWithImpl<$Res, _$OrganizationModelImpl>
    implements _$$OrganizationModelImplCopyWith<$Res> {
  __$$OrganizationModelImplCopyWithImpl(
    _$OrganizationModelImpl _value,
    $Res Function(_$OrganizationModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of OrganizationModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? slug = null,
    Object? description = freezed,
    Object? logoUrl = freezed,
    Object? settings = null,
    Object? isActive = null,
    Object? createdBy = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? memberCount = freezed,
    Object? currentUserRole = freezed,
    Object? currentUserId = freezed,
    Object? projectCount = freezed,
    Object? documentCount = freezed,
  }) {
    return _then(
      _$OrganizationModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        slug: null == slug
            ? _value.slug
            : slug // ignore: cast_nullable_to_non_nullable
                  as String,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
        logoUrl: freezed == logoUrl
            ? _value.logoUrl
            : logoUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        settings: null == settings
            ? _value._settings
            : settings // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>,
        isActive: null == isActive
            ? _value.isActive
            : isActive // ignore: cast_nullable_to_non_nullable
                  as bool,
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
        memberCount: freezed == memberCount
            ? _value.memberCount
            : memberCount // ignore: cast_nullable_to_non_nullable
                  as int?,
        currentUserRole: freezed == currentUserRole
            ? _value.currentUserRole
            : currentUserRole // ignore: cast_nullable_to_non_nullable
                  as String?,
        currentUserId: freezed == currentUserId
            ? _value.currentUserId
            : currentUserId // ignore: cast_nullable_to_non_nullable
                  as String?,
        projectCount: freezed == projectCount
            ? _value.projectCount
            : projectCount // ignore: cast_nullable_to_non_nullable
                  as int?,
        documentCount: freezed == documentCount
            ? _value.documentCount
            : documentCount // ignore: cast_nullable_to_non_nullable
                  as int?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$OrganizationModelImpl extends _OrganizationModel {
  const _$OrganizationModelImpl({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    @JsonKey(name: 'logo_url') this.logoUrl,
    final Map<String, dynamic> settings = const {},
    @JsonKey(name: 'is_active') this.isActive = true,
    @JsonKey(name: 'created_by') this.createdBy,
    @JsonKey(name: 'created_at') required this.createdAt,
    @JsonKey(name: 'updated_at') required this.updatedAt,
    @JsonKey(name: 'member_count') this.memberCount,
    @JsonKey(name: 'current_user_role') this.currentUserRole,
    @JsonKey(name: 'current_user_id') this.currentUserId,
    @JsonKey(name: 'project_count') this.projectCount,
    @JsonKey(name: 'document_count') this.documentCount,
  }) : _settings = settings,
       super._();

  factory _$OrganizationModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$OrganizationModelImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String slug;
  @override
  final String? description;
  @override
  @JsonKey(name: 'logo_url')
  final String? logoUrl;
  final Map<String, dynamic> _settings;
  @override
  @JsonKey()
  Map<String, dynamic> get settings {
    if (_settings is EqualUnmodifiableMapView) return _settings;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_settings);
  }

  @override
  @JsonKey(name: 'is_active')
  final bool isActive;
  @override
  @JsonKey(name: 'created_by')
  final String? createdBy;
  @override
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;
  @override
  @JsonKey(name: 'member_count')
  final int? memberCount;
  @override
  @JsonKey(name: 'current_user_role')
  final String? currentUserRole;
  @override
  @JsonKey(name: 'current_user_id')
  final String? currentUserId;
  @override
  @JsonKey(name: 'project_count')
  final int? projectCount;
  @override
  @JsonKey(name: 'document_count')
  final int? documentCount;

  @override
  String toString() {
    return 'OrganizationModel(id: $id, name: $name, slug: $slug, description: $description, logoUrl: $logoUrl, settings: $settings, isActive: $isActive, createdBy: $createdBy, createdAt: $createdAt, updatedAt: $updatedAt, memberCount: $memberCount, currentUserRole: $currentUserRole, currentUserId: $currentUserId, projectCount: $projectCount, documentCount: $documentCount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OrganizationModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.slug, slug) || other.slug == slug) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.logoUrl, logoUrl) || other.logoUrl == logoUrl) &&
            const DeepCollectionEquality().equals(other._settings, _settings) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            (identical(other.createdBy, createdBy) ||
                other.createdBy == createdBy) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.memberCount, memberCount) ||
                other.memberCount == memberCount) &&
            (identical(other.currentUserRole, currentUserRole) ||
                other.currentUserRole == currentUserRole) &&
            (identical(other.currentUserId, currentUserId) ||
                other.currentUserId == currentUserId) &&
            (identical(other.projectCount, projectCount) ||
                other.projectCount == projectCount) &&
            (identical(other.documentCount, documentCount) ||
                other.documentCount == documentCount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    slug,
    description,
    logoUrl,
    const DeepCollectionEquality().hash(_settings),
    isActive,
    createdBy,
    createdAt,
    updatedAt,
    memberCount,
    currentUserRole,
    currentUserId,
    projectCount,
    documentCount,
  );

  /// Create a copy of OrganizationModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OrganizationModelImplCopyWith<_$OrganizationModelImpl> get copyWith =>
      __$$OrganizationModelImplCopyWithImpl<_$OrganizationModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$OrganizationModelImplToJson(this);
  }
}

abstract class _OrganizationModel extends OrganizationModel {
  const factory _OrganizationModel({
    required final String id,
    required final String name,
    required final String slug,
    final String? description,
    @JsonKey(name: 'logo_url') final String? logoUrl,
    final Map<String, dynamic> settings,
    @JsonKey(name: 'is_active') final bool isActive,
    @JsonKey(name: 'created_by') final String? createdBy,
    @JsonKey(name: 'created_at') required final DateTime createdAt,
    @JsonKey(name: 'updated_at') required final DateTime updatedAt,
    @JsonKey(name: 'member_count') final int? memberCount,
    @JsonKey(name: 'current_user_role') final String? currentUserRole,
    @JsonKey(name: 'current_user_id') final String? currentUserId,
    @JsonKey(name: 'project_count') final int? projectCount,
    @JsonKey(name: 'document_count') final int? documentCount,
  }) = _$OrganizationModelImpl;
  const _OrganizationModel._() : super._();

  factory _OrganizationModel.fromJson(Map<String, dynamic> json) =
      _$OrganizationModelImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get slug;
  @override
  String? get description;
  @override
  @JsonKey(name: 'logo_url')
  String? get logoUrl;
  @override
  Map<String, dynamic> get settings;
  @override
  @JsonKey(name: 'is_active')
  bool get isActive;
  @override
  @JsonKey(name: 'created_by')
  String? get createdBy;
  @override
  @JsonKey(name: 'created_at')
  DateTime get createdAt;
  @override
  @JsonKey(name: 'updated_at')
  DateTime get updatedAt;
  @override
  @JsonKey(name: 'member_count')
  int? get memberCount;
  @override
  @JsonKey(name: 'current_user_role')
  String? get currentUserRole;
  @override
  @JsonKey(name: 'current_user_id')
  String? get currentUserId;
  @override
  @JsonKey(name: 'project_count')
  int? get projectCount;
  @override
  @JsonKey(name: 'document_count')
  int? get documentCount;

  /// Create a copy of OrganizationModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OrganizationModelImplCopyWith<_$OrganizationModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
