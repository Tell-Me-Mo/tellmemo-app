// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'program_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ProgramModelImpl _$$ProgramModelImplFromJson(Map<String, dynamic> json) =>
    _$ProgramModelImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      portfolioId: json['portfolio_id'] as String?,
      portfolioName: json['portfolio_name'] as String?,
      createdBy: json['created_by'] as String?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      projects:
          (json['projects'] as List<dynamic>?)
              ?.map((e) => ProjectModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      projectCount: (json['project_count'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$ProgramModelImplToJson(_$ProgramModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'portfolio_id': instance.portfolioId,
      'portfolio_name': instance.portfolioName,
      'created_by': instance.createdBy,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
      'projects': instance.projects,
      'project_count': instance.projectCount,
    };
