import 'package:dio/dio.dart';
import '../models/email_digest_preferences.dart';

/// API service for email preferences endpoints
class EmailPreferencesApiService {
  final Dio _dio;

  EmailPreferencesApiService(this._dio);

  /// Get current email digest preferences
  /// GET /api/v1/email-preferences/digest
  Future<EmailDigestPreferences> getDigestPreferences() async {
    try {
      final response = await _dio.get('/api/v1/email-preferences/digest');
      return EmailDigestPreferences.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to get email preferences');
    }
  }

  /// Update email digest preferences
  /// PUT /api/v1/email-preferences/digest
  Future<EmailDigestPreferences> updateDigestPreferences(
    EmailDigestPreferences preferences,
  ) async {
    try {
      final response = await _dio.put(
        '/api/v1/email-preferences/digest',
        data: preferences.toJson(),
      );
      return EmailDigestPreferences.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to update email preferences');
    }
  }

  /// Preview digest without sending
  /// POST /api/v1/email-preferences/digest/preview?digest_type=weekly
  Future<Map<String, dynamic>> previewDigest({
    String digestType = 'weekly',
  }) async {
    try {
      final response = await _dio.post(
        '/api/v1/email-preferences/digest/preview',
        queryParameters: {'digest_type': digestType},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to generate digest preview');
    }
  }

  /// Send test digest email
  /// POST /api/v1/email-preferences/digest/send-test
  Future<Map<String, dynamic>> sendTestDigest() async {
    try {
      final response = await _dio.post(
        '/api/v1/email-preferences/digest/send-test',
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to send test digest');
    }
  }

  /// Unsubscribe from digests using JWT token
  /// GET /api/v1/email-preferences/unsubscribe?token=<jwt>
  Future<void> unsubscribe(String token) async {
    try {
      await _dio.get(
        '/api/v1/email-preferences/unsubscribe',
        queryParameters: {'token': token},
      );
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to unsubscribe');
    }
  }

  /// Handle Dio errors and return user-friendly messages
  Exception _handleError(DioException e, String defaultMessage) {
    if (e.response != null) {
      final statusCode = e.response!.statusCode;
      final data = e.response!.data;

      // Extract error message from response
      String message = defaultMessage;
      if (data is Map<String, dynamic> && data['detail'] != null) {
        message = data['detail'] as String;
      }

      switch (statusCode) {
        case 400:
          return Exception('Invalid request: $message');
        case 401:
          return Exception('Authentication required. Please sign in again.');
        case 403:
          return Exception('Access denied: $message');
        case 404:
          return Exception('Resource not found');
        case 422:
          return Exception('Validation error: $message');
        case 500:
          return Exception('Server error: $message');
        default:
          return Exception(message);
      }
    }

    // Network or other errors
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return Exception('Connection timeout. Please check your network.');
    }

    if (e.type == DioExceptionType.connectionError) {
      return Exception('Network error. Please check your internet connection.');
    }

    return Exception(defaultMessage);
  }
}
