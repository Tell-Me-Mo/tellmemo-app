import 'package:freezed_annotation/freezed_annotation.dart';

part 'content_status_model.freezed.dart';
part 'content_status_model.g.dart';

enum ProcessingStatus {
  @JsonValue('queued')
  queued,
  @JsonValue('processing')
  processing,
  @JsonValue('completed')
  completed,
  @JsonValue('failed')
  failed,
}

@freezed
class ContentStatusModel with _$ContentStatusModel {
  const ContentStatusModel._();
  
  const factory ContentStatusModel({
    @JsonKey(name: 'content_id') required String contentId,
    @JsonKey(name: 'project_id') required String projectId,
    required ProcessingStatus status,
    @JsonKey(name: 'processing_message') String? processingMessage,
    @Default(0) @JsonKey(name: 'progress_percentage') int progressPercentage,
    @Default(0) @JsonKey(name: 'chunk_count') int chunkCount,
    @Default(false) @JsonKey(name: 'summary_generated') bool summaryGenerated,
    @JsonKey(name: 'summary_id') String? summaryId,
    @JsonKey(name: 'error_message') String? errorMessage,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
    @JsonKey(name: 'estimated_completion') DateTime? estimatedCompletion,
  }) = _ContentStatusModel;

  factory ContentStatusModel.fromJson(Map<String, dynamic> json) =>
      _$ContentStatusModelFromJson(json);
  
  bool get isProcessing => status == ProcessingStatus.processing;
  bool get isCompleted => status == ProcessingStatus.completed;
  bool get isFailed => status == ProcessingStatus.failed;
  bool get isQueued => status == ProcessingStatus.queued;
}