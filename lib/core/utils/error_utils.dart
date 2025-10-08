import 'package:dio/dio.dart';

/// Utility functions for handling and formatting errors
class ErrorUtils {
  /// Extract a user-friendly error message from any exception
  ///
  /// Handles DioException specially to extract the backend error message
  /// from the response body rather than showing verbose stack traces.
  static String getUserFriendlyMessage(dynamic error) {
    if (error is DioException) {
      return _extractDioErrorMessage(error);
    }

    // For other exceptions, just return the message
    return error.toString().replaceAll('Exception: ', '');
  }

  /// Extract user-friendly message from DioException
  ///
  /// Priority:
  /// 1. response.data['detail'] (FastAPI standard error field)
  /// 2. response.data['message'] (alternative error field)
  /// 3. response.statusMessage (HTTP status text)
  /// 4. Generic message based on status code
  static String _extractDioErrorMessage(DioException error) {
    // Try to extract error from response data
    if (error.response?.data != null) {
      final data = error.response!.data;

      // Check for 'detail' field (FastAPI standard)
      if (data is Map && data.containsKey('detail')) {
        return data['detail'].toString();
      }

      // Check for 'message' field
      if (data is Map && data.containsKey('message')) {
        return data['message'].toString();
      }

      // If data is a string, return it
      if (data is String) {
        return data;
      }
    }

    // Fall back to status-based messages
    final statusCode = error.response?.statusCode;

    switch (statusCode) {
      case 400:
        return 'Invalid request. Please check your input.';
      case 401:
        return 'Authentication required. Please log in.';
      case 403:
        return 'Access denied. You don\'t have permission for this action.';
      case 404:
        return 'Resource not found.';
      case 413:
        return error.response?.statusMessage ?? 'File too large. Please use a smaller file.';
      case 422:
        return 'Validation error. Please check your input.';
      case 429:
        return 'Too many requests. Please try again later.';
      case 500:
        return 'Server error. Please try again later.';
      case 503:
        return 'Service temporarily unavailable. Please try again later.';
      default:
        // Check for network errors
        if (error.type == DioExceptionType.connectionTimeout) {
          return 'Connection timeout. Please check your internet connection.';
        }
        if (error.type == DioExceptionType.sendTimeout) {
          return 'Request timeout. The file may be too large.';
        }
        if (error.type == DioExceptionType.receiveTimeout) {
          return 'Response timeout. Please try again.';
        }
        if (error.type == DioExceptionType.connectionError) {
          return 'Network error. Please check your internet connection.';
        }

        // Generic error message
        return error.message ?? 'An unexpected error occurred.';
    }
  }

  /// Check if an error is a specific HTTP status code
  static bool isStatusCode(dynamic error, int statusCode) {
    if (error is DioException && error.response != null) {
      return error.response!.statusCode == statusCode;
    }
    return false;
  }

  /// Check if error is file too large (413)
  static bool isFileTooLarge(dynamic error) {
    return isStatusCode(error, 413);
  }

  /// Check if error is unauthorized (401)
  static bool isUnauthorized(dynamic error) {
    return isStatusCode(error, 401);
  }

  /// Check if error is forbidden (403)
  static bool isForbidden(dynamic error) {
    return isStatusCode(error, 403);
  }

  /// Check if error is not found (404)
  static bool isNotFound(dynamic error) {
    return isStatusCode(error, 404);
  }

  /// Check if error is server error (5xx)
  static bool isServerError(dynamic error) {
    if (error is DioException && error.response != null) {
      final statusCode = error.response!.statusCode ?? 0;
      return statusCode >= 500 && statusCode < 600;
    }
    return false;
  }

  /// Check if error is network-related (no internet, timeout, etc.)
  static bool isNetworkError(dynamic error) {
    if (error is DioException) {
      return error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.connectionError;
    }
    return false;
  }
}
