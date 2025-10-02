import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_model.freezed.dart';
part 'notification_model.g.dart';

@freezed
class NotificationModel with _$NotificationModel {
  const factory NotificationModel({
    required String id,
    String? organizationId,
    required String userId,
    required String title,
    String? message,
    required String type,
    required String priority,
    required String category,
    String? entityType,
    String? entityId,
    @Default(false) bool isRead,
    DateTime? readAt,
    @Default(false) bool isArchived,
    DateTime? archivedAt,
    String? actionUrl,
    String? actionLabel,
    @Default({}) Map<String, dynamic> metadata,
    required DateTime createdAt,
    DateTime? expiresAt,
  }) = _NotificationModel;

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      _$NotificationModelFromJson(json);
}

@freezed
class NotificationListResponse with _$NotificationListResponse {
  const factory NotificationListResponse({
    required List<NotificationModel> notifications,
    required int total,
    @JsonKey(name: 'unread_count') required int unreadCount,
  }) = _NotificationListResponse;

  factory NotificationListResponse.fromJson(Map<String, dynamic> json) =>
      _$NotificationListResponseFromJson(json);
}