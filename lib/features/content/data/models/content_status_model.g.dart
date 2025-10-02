// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'content_status_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ContentStatusModelImpl _$$ContentStatusModelImplFromJson(
  Map<String, dynamic> json,
) => _$ContentStatusModelImpl(
  contentId: json['content_id'] as String,
  projectId: json['project_id'] as String,
  status: $enumDecode(_$ProcessingStatusEnumMap, json['status']),
  processingMessage: json['processing_message'] as String?,
  progressPercentage: (json['progress_percentage'] as num?)?.toInt() ?? 0,
  chunkCount: (json['chunk_count'] as num?)?.toInt() ?? 0,
  summaryGenerated: json['summary_generated'] as bool? ?? false,
  summaryId: json['summary_id'] as String?,
  errorMessage: json['error_message'] as String?,
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
  estimatedCompletion: json['estimated_completion'] == null
      ? null
      : DateTime.parse(json['estimated_completion'] as String),
);

Map<String, dynamic> _$$ContentStatusModelImplToJson(
  _$ContentStatusModelImpl instance,
) => <String, dynamic>{
  'content_id': instance.contentId,
  'project_id': instance.projectId,
  'status': _$ProcessingStatusEnumMap[instance.status]!,
  'processing_message': instance.processingMessage,
  'progress_percentage': instance.progressPercentage,
  'chunk_count': instance.chunkCount,
  'summary_generated': instance.summaryGenerated,
  'summary_id': instance.summaryId,
  'error_message': instance.errorMessage,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
  'estimated_completion': instance.estimatedCompletion?.toIso8601String(),
};

const _$ProcessingStatusEnumMap = {
  ProcessingStatus.queued: 'queued',
  ProcessingStatus.processing: 'processing',
  ProcessingStatus.completed: 'completed',
  ProcessingStatus.failed: 'failed',
};
