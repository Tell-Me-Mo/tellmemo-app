// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TaskModelImpl _$$TaskModelImplFromJson(Map<String, dynamic> json) =>
    _$TaskModelImpl(
      id: json['id'] as String,
      projectId: json['project_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      status: json['status'] as String,
      priority: json['priority'] as String,
      assignee: json['assignee'] as String?,
      dueDate: json['due_date'] as String?,
      completedDate: json['completed_date'] as String?,
      progressPercentage: (json['progress_percentage'] as num).toInt(),
      blockerDescription: json['blocker_description'] as String?,
      questionToAsk: json['question_to_ask'] as String?,
      aiGenerated: json['ai_generated'] as bool,
      aiConfidence: (json['ai_confidence'] as num?)?.toDouble(),
      sourceContentId: json['source_content_id'] as String?,
      dependsOnRiskId: json['depends_on_risk_id'] as String?,
      createdDate: json['created_date'] as String?,
      lastUpdated: json['last_updated'] as String?,
      updatedBy: json['updated_by'] as String?,
    );

Map<String, dynamic> _$$TaskModelImplToJson(_$TaskModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'project_id': instance.projectId,
      'title': instance.title,
      'description': instance.description,
      'status': instance.status,
      'priority': instance.priority,
      'assignee': instance.assignee,
      'due_date': instance.dueDate,
      'completed_date': instance.completedDate,
      'progress_percentage': instance.progressPercentage,
      'blocker_description': instance.blockerDescription,
      'question_to_ask': instance.questionToAsk,
      'ai_generated': instance.aiGenerated,
      'ai_confidence': instance.aiConfidence,
      'source_content_id': instance.sourceContentId,
      'depends_on_risk_id': instance.dependsOnRiskId,
      'created_date': instance.createdDate,
      'last_updated': instance.lastUpdated,
      'updated_by': instance.updatedBy,
    };
