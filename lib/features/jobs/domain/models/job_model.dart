import 'package:freezed_annotation/freezed_annotation.dart';

part 'job_model.freezed.dart';
part 'job_model.g.dart';

@JsonEnum(fieldRename: FieldRename.snake)
enum JobStatus {
  pending,
  processing,
  completed,
  failed,
  cancelled,
}

@JsonEnum(fieldRename: FieldRename.snake)
enum JobType {
  transcription,
  textUpload,
  emailUpload,
  batchUpload,
  projectSummary,
  meetingSummary,
}

@Freezed(fromJson: true, toJson: true)
class JobModel with _$JobModel {
  const JobModel._();
  
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory JobModel({
    required String jobId,
    required String projectId,
    required JobType jobType,
    required JobStatus status,
    @Default(0.0) double progress,
    @Default(1) int totalSteps,
    @Default(0) int currentStep,
    String? stepDescription,
    String? filename,
    int? fileSize,
    String? errorMessage,
    Map<String, dynamic>? result,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? completedAt,
    @Default({}) Map<String, dynamic> metadata,
  }) = _JobModel;

  factory JobModel.fromJson(Map<String, dynamic> json) => _$JobModelFromJson(json);
  
  bool get isActive => status == JobStatus.pending || status == JobStatus.processing;
  bool get isComplete => status == JobStatus.completed || status == JobStatus.failed || status == JobStatus.cancelled;
}

// Extension methods for enum conversions
extension JobStatusExtension on JobStatus {
  String get value {
    switch (this) {
      case JobStatus.pending:
        return 'pending';
      case JobStatus.processing:
        return 'processing';
      case JobStatus.completed:
        return 'completed';
      case JobStatus.failed:
        return 'failed';
      case JobStatus.cancelled:
        return 'cancelled';
    }
  }
  
  static JobStatus fromString(String value) {
    switch (value) {
      case 'pending':
        return JobStatus.pending;
      case 'processing':
        return JobStatus.processing;
      case 'completed':
        return JobStatus.completed;
      case 'failed':
        return JobStatus.failed;
      case 'cancelled':
        return JobStatus.cancelled;
      default:
        throw ArgumentError('Unknown JobStatus: $value');
    }
  }
}

extension JobTypeExtension on JobType {
  String get value {
    switch (this) {
      case JobType.transcription:
        return 'transcription';
      case JobType.textUpload:
        return 'text_upload';
      case JobType.emailUpload:
        return 'email_upload';
      case JobType.batchUpload:
        return 'batch_upload';
      case JobType.projectSummary:
        return 'project_summary';
      case JobType.meetingSummary:
        return 'meeting_summary';
    }
  }
  
  static JobType fromString(String value) {
    switch (value) {
      case 'transcription':
        return JobType.transcription;
      case 'text_upload':
        return JobType.textUpload;
      case 'email_upload':
        return JobType.emailUpload;
      case 'batch_upload':
        return JobType.batchUpload;
      case 'project_summary':
        return JobType.projectSummary;
      case 'meeting_summary':
        return JobType.meetingSummary;
      default:
        throw ArgumentError('Unknown JobType: $value');
    }
  }
}