import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pm_master_v2/core/converters/date_time_converter.dart';
import '../../domain/entities/content.dart';

part 'content_model.freezed.dart';
part 'content_model.g.dart';

@freezed
class ContentModel with _$ContentModel {
  const ContentModel._();

  const factory ContentModel({
    required String id,
    @JsonKey(name: 'project_id') required String projectId,
    @JsonKey(name: 'content_type') required String contentType,
    required String title,
    @DateTimeConverterNullable() DateTime? date,
    @JsonKey(name: 'uploaded_at') @DateTimeConverter() required DateTime uploadedAt,
    @JsonKey(name: 'uploaded_by') String? uploadedBy,
    @JsonKey(name: 'chunk_count') required int chunkCount,
    @JsonKey(name: 'summary_generated') required bool summaryGenerated,
    @JsonKey(name: 'processed_at') @DateTimeConverterNullable() DateTime? processedAt,
    @JsonKey(name: 'processing_error') String? processingError,
  }) = _ContentModel;

  factory ContentModel.fromJson(Map<String, dynamic> json) =>
      _$ContentModelFromJson(json);

  Content toEntity() {
    return Content(
      id: id,
      projectId: projectId,
      contentType: contentType == 'meeting' ? ContentType.meeting : ContentType.email,
      title: title,
      date: date,
      uploadedAt: uploadedAt,
      uploadedBy: uploadedBy,
      chunkCount: chunkCount,
      summaryGenerated: summaryGenerated,
      processedAt: processedAt,
      processingError: processingError,
    );
  }

  static ContentModel fromEntity(Content entity) {
    return ContentModel(
      id: entity.id,
      projectId: entity.projectId,
      contentType: entity.contentType == ContentType.meeting ? 'meeting' : 'email',
      title: entity.title,
      date: entity.date,
      uploadedAt: entity.uploadedAt,
      uploadedBy: entity.uploadedBy,
      chunkCount: entity.chunkCount,
      summaryGenerated: entity.summaryGenerated,
      processedAt: entity.processedAt,
      processingError: entity.processingError,
    );
  }
}