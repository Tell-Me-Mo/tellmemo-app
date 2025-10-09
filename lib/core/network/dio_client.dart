import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import '../config/api_config.dart';
import '../services/auth_service.dart';
import 'interceptors.dart';
import 'organization_interceptor.dart';

class DioClient {
  static Dio? _dio;

  static Dio getInstance({required AuthService authService}) {
    if (_dio == null) {
      final baseOptions = BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.timeout,
        receiveTimeout: ApiConfig.timeout,
        headers: ApiConfig.defaultHeaders,
      );

      // Only set sendTimeout for non-web platforms to avoid warning
      // On web, sendTimeout is only used for requests with a body
      if (!kIsWeb) {
        baseOptions.sendTimeout = ApiConfig.timeout;
      }

      _dio = Dio(baseOptions);

      // Add interceptors
      _dio!.interceptors.addAll([
        HeaderInterceptor(),
        AuthInterceptor(authService),
        OrganizationInterceptor(),
        // Custom retry interceptor that excludes client errors (4xx)
        CustomRetryInterceptor(
          dio: _dio!,
          maxRetries: 3,
        ),
        LoggingInterceptor(),
        if (kIsWeb) WebRequestInterceptor(),
      ]);
    }

    return _dio!;
  }

  // Legacy getter for backward compatibility
  static Dio get instance {
    if (_dio == null) {
      throw Exception('DioClient not initialized. Call getInstance(authService: authService) first.');
    }
    return _dio!;
  }

  static void reset() {
    _dio = null;
  }
}

// Interceptor to handle sendTimeout for web platform
class WebRequestInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // On web, only set sendTimeout for requests with a body
    if (kIsWeb && options.data != null) {
      options.sendTimeout = ApiConfig.timeout;
    }
    handler.next(options);
  }
}

// Custom retry interceptor that excludes client errors (4xx)
class CustomRetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;
  final List<Duration> retryDelays;

  CustomRetryInterceptor({
    required this.dio,
    this.maxRetries = 3,
  }) : retryDelays = [
    const Duration(seconds: 1),
    const Duration(seconds: 2),
    const Duration(seconds: 3),
  ];

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final response = err.response;
    final extra = err.requestOptions.extra;
    final attempt = extra['retry_attempt'] as int? ?? 0;

    // Check if we should retry
    if (_shouldRetry(err, attempt)) {
      if (kDebugMode) {
        print('🔄 Retry attempt ${attempt + 1}/$maxRetries for ${err.requestOptions.path}');
      }

      // Wait before retrying
      if (attempt < retryDelays.length) {
        await Future.delayed(retryDelays[attempt]);
      } else {
        await Future.delayed(retryDelays.last);
      }

      // Update retry attempt count
      err.requestOptions.extra['retry_attempt'] = attempt + 1;

      // Retry the request
      try {
        final response = await dio.fetch(err.requestOptions);
        return handler.resolve(response);
      } catch (e) {
        // If retry fails, pass the new error
        if (e is DioException) {
          return handler.reject(e);
        }
        return handler.reject(err);
      }
    }

    // Don't retry, pass the error through
    handler.next(err);
  }

  bool _shouldRetry(DioException err, int attempt) {
    // Don't retry if we've exceeded max retries
    if (attempt >= maxRetries) {
      return false;
    }

    // Don't retry client errors (4xx)
    final statusCode = err.response?.statusCode;
    if (statusCode != null && statusCode >= 400 && statusCode < 500) {
      if (kDebugMode) {
        print('🔄 Not retrying client error: $statusCode');
      }
      return false;
    }

    // Don't retry if the request was cancelled
    if (err.type == DioExceptionType.cancel) {
      return false;
    }

    // Retry on network errors and server errors (5xx)
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.unknown ||
        (statusCode != null && statusCode >= 500);
  }
}