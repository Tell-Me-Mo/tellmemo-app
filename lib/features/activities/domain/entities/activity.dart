import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../core/utils/datetime_utils.dart';

part 'activity.freezed.dart';

enum ActivityType {
  projectCreated,
  projectUpdated,
  projectDeleted,
  contentUploaded,
  summaryGenerated,
  querySubmitted,
  reportGenerated,
  memberAdded,
  memberRemoved,
}

@freezed
class Activity with _$Activity {
  const factory Activity({
    required String id,
    required String projectId,
    required ActivityType type,
    required String title,
    required String description,
    String? metadata,
    required DateTime timestamp,
    String? userId,
    String? userName,
  }) = _Activity;

  const Activity._();

  String get formattedTime {
    return DateTimeUtils.formatTimeAgo(timestamp);
  }

  String get icon {
    switch (type) {
      case ActivityType.projectCreated:
        return '📁';
      case ActivityType.projectUpdated:
        return '✏️';
      case ActivityType.projectDeleted:
        return '🗑️';
      case ActivityType.contentUploaded:
        return '📤';
      case ActivityType.summaryGenerated:
        return '✨';
      case ActivityType.querySubmitted:
        return '❓';
      case ActivityType.reportGenerated:
        return '📄';
      case ActivityType.memberAdded:
        return '👤';
      case ActivityType.memberRemoved:
        return '👥';
    }
  }
}