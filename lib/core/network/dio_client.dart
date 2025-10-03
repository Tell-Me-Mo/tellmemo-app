import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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