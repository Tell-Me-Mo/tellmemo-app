// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'portfolio_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PortfolioModelImpl _$$PortfolioModelImplFromJson(Map<String, dynamic> json) =>
    _$PortfolioModelImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      owner: json['owner'] as String?,
      healthStatus: json['health_status'] as String? ?? 'not_set',
      riskSummary: json['risk_summary'] as String?,
      createdBy: json['created_by'] as String?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      programs:
          (json['programs'] as List<dynamic>?)
              ?.map((e) => ProgramModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      directProjects:
          (json['direct_projects'] as List<dynamic>?)
              ?.map((e) => ProjectModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      programCount: (json['program_count'] as num?)?.toInt() ?? 0,
      directProjectCount: (json['direct_project_count'] as num?)?.toInt() ?? 0,
      totalProjectCount: (json['total_project_count'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$PortfolioModelImplToJson(
  _$PortfolioModelImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'owner': instance.owner,
  'health_status': instance.healthStatus,
  'risk_summary': instance.riskSummary,
  'created_by': instance.createdBy,
  'created_at': instance.createdAt,
  'updated_at': instance.updatedAt,
  'programs': instance.programs,
  'direct_projects': instance.directProjects,
  'program_count': instance.programCount,
  'direct_project_count': instance.directProjectCount,
  'total_project_count': instance.totalProjectCount,
};
