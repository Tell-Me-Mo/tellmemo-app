// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'organization_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$OrganizationModelImpl _$$OrganizationModelImplFromJson(
  Map<String, dynamic> json,
) => _$OrganizationModelImpl(
  id: json['id'] as String,
  name: json['name'] as String,
  slug: json['slug'] as String,
  description: json['description'] as String?,
  logoUrl: json['logo_url'] as String?,
  settings: json['settings'] as Map<String, dynamic>? ?? const {},
  isActive: json['is_active'] as bool? ?? true,
  createdBy: json['created_by'] as String?,
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
  memberCount: (json['member_count'] as num?)?.toInt(),
  currentUserRole: json['current_user_role'] as String?,
  currentUserId: json['current_user_id'] as String?,
  projectCount: (json['project_count'] as num?)?.toInt(),
  documentCount: (json['document_count'] as num?)?.toInt(),
);

Map<String, dynamic> _$$OrganizationModelImplToJson(
  _$OrganizationModelImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'slug': instance.slug,
  'description': instance.description,
  'logo_url': instance.logoUrl,
  'settings': instance.settings,
  'is_active': instance.isActive,
  'created_by': instance.createdBy,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
  'member_count': instance.memberCount,
  'current_user_role': instance.currentUserRole,
  'current_user_id': instance.currentUserId,
  'project_count': instance.projectCount,
  'document_count': instance.documentCount,
};
