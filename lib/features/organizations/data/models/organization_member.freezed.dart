// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'organization_member.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

OrganizationMember _$OrganizationMemberFromJson(Map<String, dynamic> json) {
  return _OrganizationMember.fromJson(json);
}

/// @nodoc
mixin _$OrganizationMember {
  String get organizationId => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String get userEmail => throw _privateConstructorUsedError;
  String get userName => throw _privateConstructorUsedError;
  String? get userAvatarUrl => throw _privateConstructorUsedError;
  String get role => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  String? get invitedBy => throw _privateConstructorUsedError;
  DateTime? get joinedAt => throw _privateConstructorUsedError;
  DateTime? get invitedAt => throw _privateConstructorUsedError;
  DateTime? get lastActiveAt => throw _privateConstructorUsedError;

  /// Serializes this OrganizationMember to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of OrganizationMember
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OrganizationMemberCopyWith<OrganizationMember> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OrganizationMemberCopyWith<$Res> {
  factory $OrganizationMemberCopyWith(
    OrganizationMember value,
    $Res Function(OrganizationMember) then,
  ) = _$OrganizationMemberCopyWithImpl<$Res, OrganizationMember>;
  @useResult
  $Res call({
    String organizationId,
    String userId,
    String userEmail,
    String userName,
    String? userAvatarUrl,
    String role,
    String status,
    String? invitedBy,
    DateTime? joinedAt,
    DateTime? invitedAt,
    DateTime? lastActiveAt,
  });
}

/// @nodoc
class _$OrganizationMemberCopyWithImpl<$Res, $Val extends OrganizationMember>
    implements $OrganizationMemberCopyWith<$Res> {
  _$OrganizationMemberCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of OrganizationMember
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? organizationId = null,
    Object? userId = null,
    Object? userEmail = null,
    Object? userName = null,
    Object? userAvatarUrl = freezed,
    Object? role = null,
    Object? status = null,
    Object? invitedBy = freezed,
    Object? joinedAt = freezed,
    Object? invitedAt = freezed,
    Object? lastActiveAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            organizationId: null == organizationId
                ? _value.organizationId
                : organizationId // ignore: cast_nullable_to_non_nullable
                      as String,
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String,
            userEmail: null == userEmail
                ? _value.userEmail
                : userEmail // ignore: cast_nullable_to_non_nullable
                      as String,
            userName: null == userName
                ? _value.userName
                : userName // ignore: cast_nullable_to_non_nullable
                      as String,
            userAvatarUrl: freezed == userAvatarUrl
                ? _value.userAvatarUrl
                : userAvatarUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            role: null == role
                ? _value.role
                : role // ignore: cast_nullable_to_non_nullable
                      as String,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            invitedBy: freezed == invitedBy
                ? _value.invitedBy
                : invitedBy // ignore: cast_nullable_to_non_nullable
                      as String?,
            joinedAt: freezed == joinedAt
                ? _value.joinedAt
                : joinedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            invitedAt: freezed == invitedAt
                ? _value.invitedAt
                : invitedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            lastActiveAt: freezed == lastActiveAt
                ? _value.lastActiveAt
                : lastActiveAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$OrganizationMemberImplCopyWith<$Res>
    implements $OrganizationMemberCopyWith<$Res> {
  factory _$$OrganizationMemberImplCopyWith(
    _$OrganizationMemberImpl value,
    $Res Function(_$OrganizationMemberImpl) then,
  ) = __$$OrganizationMemberImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String organizationId,
    String userId,
    String userEmail,
    String userName,
    String? userAvatarUrl,
    String role,
    String status,
    String? invitedBy,
    DateTime? joinedAt,
    DateTime? invitedAt,
    DateTime? lastActiveAt,
  });
}

/// @nodoc
class __$$OrganizationMemberImplCopyWithImpl<$Res>
    extends _$OrganizationMemberCopyWithImpl<$Res, _$OrganizationMemberImpl>
    implements _$$OrganizationMemberImplCopyWith<$Res> {
  __$$OrganizationMemberImplCopyWithImpl(
    _$OrganizationMemberImpl _value,
    $Res Function(_$OrganizationMemberImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of OrganizationMember
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? organizationId = null,
    Object? userId = null,
    Object? userEmail = null,
    Object? userName = null,
    Object? userAvatarUrl = freezed,
    Object? role = null,
    Object? status = null,
    Object? invitedBy = freezed,
    Object? joinedAt = freezed,
    Object? invitedAt = freezed,
    Object? lastActiveAt = freezed,
  }) {
    return _then(
      _$OrganizationMemberImpl(
        organizationId: null == organizationId
            ? _value.organizationId
            : organizationId // ignore: cast_nullable_to_non_nullable
                  as String,
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        userEmail: null == userEmail
            ? _value.userEmail
            : userEmail // ignore: cast_nullable_to_non_nullable
                  as String,
        userName: null == userName
            ? _value.userName
            : userName // ignore: cast_nullable_to_non_nullable
                  as String,
        userAvatarUrl: freezed == userAvatarUrl
            ? _value.userAvatarUrl
            : userAvatarUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        role: null == role
            ? _value.role
            : role // ignore: cast_nullable_to_non_nullable
                  as String,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        invitedBy: freezed == invitedBy
            ? _value.invitedBy
            : invitedBy // ignore: cast_nullable_to_non_nullable
                  as String?,
        joinedAt: freezed == joinedAt
            ? _value.joinedAt
            : joinedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        invitedAt: freezed == invitedAt
            ? _value.invitedAt
            : invitedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        lastActiveAt: freezed == lastActiveAt
            ? _value.lastActiveAt
            : lastActiveAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$OrganizationMemberImpl implements _OrganizationMember {
  const _$OrganizationMemberImpl({
    required this.organizationId,
    required this.userId,
    required this.userEmail,
    required this.userName,
    this.userAvatarUrl,
    required this.role,
    this.status = 'active',
    this.invitedBy,
    this.joinedAt,
    this.invitedAt,
    this.lastActiveAt,
  });

  factory _$OrganizationMemberImpl.fromJson(Map<String, dynamic> json) =>
      _$$OrganizationMemberImplFromJson(json);

  @override
  final String organizationId;
  @override
  final String userId;
  @override
  final String userEmail;
  @override
  final String userName;
  @override
  final String? userAvatarUrl;
  @override
  final String role;
  @override
  @JsonKey()
  final String status;
  @override
  final String? invitedBy;
  @override
  final DateTime? joinedAt;
  @override
  final DateTime? invitedAt;
  @override
  final DateTime? lastActiveAt;

  @override
  String toString() {
    return 'OrganizationMember(organizationId: $organizationId, userId: $userId, userEmail: $userEmail, userName: $userName, userAvatarUrl: $userAvatarUrl, role: $role, status: $status, invitedBy: $invitedBy, joinedAt: $joinedAt, invitedAt: $invitedAt, lastActiveAt: $lastActiveAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OrganizationMemberImpl &&
            (identical(other.organizationId, organizationId) ||
                other.organizationId == organizationId) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.userEmail, userEmail) ||
                other.userEmail == userEmail) &&
            (identical(other.userName, userName) ||
                other.userName == userName) &&
            (identical(other.userAvatarUrl, userAvatarUrl) ||
                other.userAvatarUrl == userAvatarUrl) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.invitedBy, invitedBy) ||
                other.invitedBy == invitedBy) &&
            (identical(other.joinedAt, joinedAt) ||
                other.joinedAt == joinedAt) &&
            (identical(other.invitedAt, invitedAt) ||
                other.invitedAt == invitedAt) &&
            (identical(other.lastActiveAt, lastActiveAt) ||
                other.lastActiveAt == lastActiveAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    organizationId,
    userId,
    userEmail,
    userName,
    userAvatarUrl,
    role,
    status,
    invitedBy,
    joinedAt,
    invitedAt,
    lastActiveAt,
  );

  /// Create a copy of OrganizationMember
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OrganizationMemberImplCopyWith<_$OrganizationMemberImpl> get copyWith =>
      __$$OrganizationMemberImplCopyWithImpl<_$OrganizationMemberImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$OrganizationMemberImplToJson(this);
  }
}

abstract class _OrganizationMember implements OrganizationMember {
  const factory _OrganizationMember({
    required final String organizationId,
    required final String userId,
    required final String userEmail,
    required final String userName,
    final String? userAvatarUrl,
    required final String role,
    final String status,
    final String? invitedBy,
    final DateTime? joinedAt,
    final DateTime? invitedAt,
    final DateTime? lastActiveAt,
  }) = _$OrganizationMemberImpl;

  factory _OrganizationMember.fromJson(Map<String, dynamic> json) =
      _$OrganizationMemberImpl.fromJson;

  @override
  String get organizationId;
  @override
  String get userId;
  @override
  String get userEmail;
  @override
  String get userName;
  @override
  String? get userAvatarUrl;
  @override
  String get role;
  @override
  String get status;
  @override
  String? get invitedBy;
  @override
  DateTime? get joinedAt;
  @override
  DateTime? get invitedAt;
  @override
  DateTime? get lastActiveAt;

  /// Create a copy of OrganizationMember
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OrganizationMemberImplCopyWith<_$OrganizationMemberImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
