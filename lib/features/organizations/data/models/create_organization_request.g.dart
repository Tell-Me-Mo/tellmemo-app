// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_organization_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CreateOrganizationRequestImpl _$$CreateOrganizationRequestImplFromJson(
  Map<String, dynamic> json,
) => _$CreateOrganizationRequestImpl(
  name: json['name'] as String,
  slug: json['slug'] as String?,
  description: json['description'] as String?,
  logoUrl: json['logo_url'] as String?,
  settings: json['settings'] as Map<String, dynamic>? ?? const {},
);

Map<String, dynamic> _$$CreateOrganizationRequestImplToJson(
  _$CreateOrganizationRequestImpl instance,
) => <String, dynamic>{
  'name': instance.name,
  'slug': instance.slug,
  'description': instance.description,
  'logo_url': instance.logoUrl,
  'settings': instance.settings,
};
