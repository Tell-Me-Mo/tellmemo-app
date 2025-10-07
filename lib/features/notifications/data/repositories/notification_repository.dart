import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../models/notification_model.dart';

class NotificationRepository {
  late final Dio _dio;

  NotificationRepository() {
    _dio = DioClient.instance;
  }

  Future<NotificationListResponse> getNotifications({
    bool? isRead,
    bool isArchived = false,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final queryParams = {
        if (isRead != null) 'is_read': isRead,
        'is_archived': isArchived,
        'limit': limit,
        'offset': offset,
      };

      final response = await _dio.get(
        '/api/v1/notifications',
        queryParameters: queryParams,
      );

      return NotificationListResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<int> getUnreadCount() async {
    try {
      final response = await _dio.get('/api/v1/notifications/unread-count');
      return response.data['unread_count'] ?? 0;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<bool> markAsRead(String notificationId) async {
    try {
      await _dio.put('/api/v1/notifications/$notificationId/read');
      return true;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<int> markMultipleAsRead({
    List<String>? notificationIds,
    bool markAll = false,
  }) async {
    try {
      final response = await _dio.put(
        '/api/v1/notifications/mark-read',
        data: {
          'notification_ids': notificationIds,
          'mark_all': markAll,
        },
      );
      return response.data['count'] ?? 0;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<bool> archiveNotification(String notificationId) async {
    try {
      await _dio.put('/api/v1/notifications/$notificationId/archive');
      return true;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<bool> deleteNotification(String notificationId) async {
    try {
      await _dio.delete('/api/v1/notifications/$notificationId');
      return true;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<NotificationModel> createNotification({
    required String title,
    String? message,
    String type = 'info',
    String priority = 'normal',
    String category = 'other',
    String? entityType,
    String? entityId,
    String? actionUrl,
    String? actionLabel,
    Map<String, dynamic>? metadata,
    int? expiresInHours,
  }) async {
    try {
      final response = await _dio.post(
        '/api/v1/notifications',
        data: {
          'title': title,
          'message': message,
          'type': type,
          'priority': priority,
          'category': category,
          'entity_type': entityType,
          'entity_id': entityId,
          'action_url': actionUrl,
          'action_label': actionLabel,
          'metadata': metadata,
          'expires_in_hours': expiresInHours,
        },
      );

      return NotificationModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(DioException error) {
    if (error.response != null) {
      final statusCode = error.response!.statusCode;
      final message = error.response!.data['detail'] ?? 'Unknown error';

      switch (statusCode) {
        case 401:
          return Exception('Unauthorized: Please log in');
        case 404:
          return Exception('Notification not found');
        case 500:
          return Exception('Server error: $message');
        default:
          return Exception('Error: $message');
      }
    } else if (error.type == DioExceptionType.connectionTimeout) {
      return Exception('Connection timeout');
    } else if (error.type == DioExceptionType.receiveTimeout) {
      return Exception('Receive timeout');
    } else {
      return Exception('Network error: ${error.message}');
    }
  }
}