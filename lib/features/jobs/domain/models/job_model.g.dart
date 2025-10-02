// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'job_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$JobModelImpl _$$JobModelImplFromJson(Map<String, dynamic> json) =>
    _$JobModelImpl(
      jobId: json['job_id'] as String,
      projectId: json['project_id'] as String,
      jobType: $enumDecode(_$JobTypeEnumMap, json['job_type']),
      status: $enumDecode(_$JobStatusEnumMap, json['status']),
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      totalSteps: (json['total_steps'] as num?)?.toInt() ?? 1,
      currentStep: (json['current_step'] as num?)?.toInt() ?? 0,
      stepDescription: json['step_description'] as String?,
      filename: json['filename'] as String?,
      fileSize: (json['file_size'] as num?)?.toInt(),
      errorMessage: json['error_message'] as String?,
      result: json['result'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      completedAt: json['completed_at'] == null
          ? null
          : DateTime.parse(json['completed_at'] as String),
      metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$$JobModelImplToJson(_$JobModelImpl instance) =>
    <String, dynamic>{
      'job_id': instance.jobId,
      'project_id': instance.projectId,
      'job_type': _$JobTypeEnumMap[instance.jobType]!,
      'status': _$JobStatusEnumMap[instance.status]!,
      'progress': instance.progress,
      'total_steps': instance.totalSteps,
      'current_step': instance.currentStep,
      'step_description': instance.stepDescription,
      'filename': instance.filename,
      'file_size': instance.fileSize,
      'error_message': instance.errorMessage,
      'result': instance.result,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'completed_at': instance.completedAt?.toIso8601String(),
      'metadata': instance.metadata,
    };

const _$JobTypeEnumMap = {
  JobType.transcription: 'transcription',
  JobType.textUpload: 'text_upload',
  JobType.emailUpload: 'email_upload',
  JobType.batchUpload: 'batch_upload',
  JobType.projectSummary: 'project_summary',
  JobType.meetingSummary: 'meeting_summary',
};

const _$JobStatusEnumMap = {
  JobStatus.pending: 'pending',
  JobStatus.processing: 'processing',
  JobStatus.completed: 'completed',
  JobStatus.failed: 'failed',
  JobStatus.cancelled: 'cancelled',
};
