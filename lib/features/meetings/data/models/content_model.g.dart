// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'content_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ContentModelImpl _$$ContentModelImplFromJson(Map<String, dynamic> json) =>
    _$ContentModelImpl(
      id: json['id'] as String,
      projectId: json['project_id'] as String,
      contentType: json['content_type'] as String,
      title: json['title'] as String,
      date: const DateTimeConverterNullable().fromJson(json['date']),
      uploadedAt: const DateTimeConverter().fromJson(json['uploaded_at']),
      uploadedBy: json['uploaded_by'] as String?,
      chunkCount: (json['chunk_count'] as num).toInt(),
      summaryGenerated: json['summary_generated'] as bool,
      processedAt: const DateTimeConverterNullable().fromJson(
        json['processed_at'],
      ),
      processingError: json['processing_error'] as String?,
    );

Map<String, dynamic> _$$ContentModelImplToJson(_$ContentModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'project_id': instance.projectId,
      'content_type': instance.contentType,
      'title': instance.title,
      'date': const DateTimeConverterNullable().toJson(instance.date),
      'uploaded_at': const DateTimeConverter().toJson(instance.uploadedAt),
      'uploaded_by': instance.uploadedBy,
      'chunk_count': instance.chunkCount,
      'summary_generated': instance.summaryGenerated,
      'processed_at': const DateTimeConverterNullable().toJson(
        instance.processedAt,
      ),
      'processing_error': instance.processingError,
    };
