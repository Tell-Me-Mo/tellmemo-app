// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'risk_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$RiskModelImpl _$$RiskModelImplFromJson(Map<String, dynamic> json) =>
    _$RiskModelImpl(
      id: json['id'] as String,
      projectId: json['project_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      severity: json['severity'] as String,
      status: json['status'] as String,
      mitigation: json['mitigation'] as String?,
      impact: json['impact'] as String?,
      probability: (json['probability'] as num?)?.toDouble(),
      aiGenerated: json['ai_generated'] as bool,
      aiConfidence: (json['ai_confidence'] as num?)?.toDouble(),
      sourceContentId: json['source_content_id'] as String?,
      identifiedDate: json['identified_date'] as String?,
      resolvedDate: json['resolved_date'] as String?,
      lastUpdated: json['last_updated'] as String?,
      updatedBy: json['updated_by'] as String?,
      assignedTo: json['assigned_to'] as String?,
      assignedToEmail: json['assigned_to_email'] as String?,
    );

Map<String, dynamic> _$$RiskModelImplToJson(_$RiskModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'project_id': instance.projectId,
      'title': instance.title,
      'description': instance.description,
      'severity': instance.severity,
      'status': instance.status,
      'mitigation': instance.mitigation,
      'impact': instance.impact,
      'probability': instance.probability,
      'ai_generated': instance.aiGenerated,
      'ai_confidence': instance.aiConfidence,
      'source_content_id': instance.sourceContentId,
      'identified_date': instance.identifiedDate,
      'resolved_date': instance.resolvedDate,
      'last_updated': instance.lastUpdated,
      'updated_by': instance.updatedBy,
      'assigned_to': instance.assignedTo,
      'assigned_to_email': instance.assignedToEmail,
    };
