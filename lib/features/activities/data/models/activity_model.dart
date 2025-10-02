import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/activity.dart';

part 'activity_model.freezed.dart';
part 'activity_model.g.dart';

// Custom converter to parse timestamps as UTC
class UtcDateTimeConverter implements JsonConverter<DateTime, String> {
  const UtcDateTimeConverter();

  @override
  DateTime fromJson(String json) {
    // Parse the timestamp and ensure it's treated as UTC
    final parsed = DateTime.parse(json);
    if (!parsed.isUtc) {
      // If not already UTC, create a new DateTime in UTC with the same values
      return DateTime.utc(
        parsed.year,
        parsed.month,
        parsed.day,
        parsed.hour,
        parsed.minute,
        parsed.second,
        parsed.millisecond,
        parsed.microsecond,
      );
    }
    return parsed;
  }

  @override
  String toJson(DateTime object) => object.toUtc().toIso8601String();
}

@freezed
class ActivityModel with _$ActivityModel {
  const factory ActivityModel({
    required String id,
    @JsonKey(name: 'project_id') required String projectId,
    required String type,
    required String title,
    required String description,
    String? metadata,
    @UtcDateTimeConverter() required DateTime timestamp,
    @JsonKey(name: 'user_id') String? userId,
    @JsonKey(name: 'user_name') String? userName,
  }) = _ActivityModel;

  factory ActivityModel.fromJson(Map<String, dynamic> json) =>
      _$ActivityModelFromJson(json);

  const ActivityModel._();

  Activity toEntity() {
    // Timestamp is now guaranteed to be UTC from the converter, convert to local for display
    final localTimestamp = timestamp.toLocal();

    return Activity(
      id: id,
      projectId: projectId,
      type: _parseActivityType(type),
      title: title,
      description: description,
      metadata: metadata,
      timestamp: localTimestamp,
      userId: userId,
      userName: userName,
    );
  }

  static ActivityType _parseActivityType(String type) {
    switch (type) {
      case 'project_created':
        return ActivityType.projectCreated;
      case 'project_updated':
        return ActivityType.projectUpdated;
      case 'project_deleted':
        return ActivityType.projectDeleted;
      case 'content_uploaded':
        return ActivityType.contentUploaded;
      case 'summary_generated':
        return ActivityType.summaryGenerated;
      case 'query_submitted':
        return ActivityType.querySubmitted;
      case 'report_generated':
        return ActivityType.reportGenerated;
      case 'member_added':
        return ActivityType.memberAdded;
      case 'member_removed':
        return ActivityType.memberRemoved;
      default:
        return ActivityType.projectUpdated;
    }
  }
}