// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'organization_member.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$OrganizationMemberImpl _$$OrganizationMemberImplFromJson(
  Map<String, dynamic> json,
) => _$OrganizationMemberImpl(
  organizationId: json['organizationId'] as String,
  userId: json['userId'] as String,
  userEmail: json['userEmail'] as String,
  userName: json['userName'] as String,
  userAvatarUrl: json['userAvatarUrl'] as String?,
  role: json['role'] as String,
  status: json['status'] as String? ?? 'active',
  invitedBy: json['invitedBy'] as String?,
  joinedAt: json['joinedAt'] == null
      ? null
      : DateTime.parse(json['joinedAt'] as String),
  invitedAt: json['invitedAt'] == null
      ? null
      : DateTime.parse(json['invitedAt'] as String),
  lastActiveAt: json['lastActiveAt'] == null
      ? null
      : DateTime.parse(json['lastActiveAt'] as String),
);

Map<String, dynamic> _$$OrganizationMemberImplToJson(
  _$OrganizationMemberImpl instance,
) => <String, dynamic>{
  'organizationId': instance.organizationId,
  'userId': instance.userId,
  'userEmail': instance.userEmail,
  'userName': instance.userName,
  'userAvatarUrl': instance.userAvatarUrl,
  'role': instance.role,
  'status': instance.status,
  'invitedBy': instance.invitedBy,
  'joinedAt': instance.joinedAt?.toIso8601String(),
  'invitedAt': instance.invitedAt?.toIso8601String(),
  'lastActiveAt': instance.lastActiveAt?.toIso8601String(),
};
