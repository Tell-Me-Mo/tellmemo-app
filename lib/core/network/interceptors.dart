import 'package:dio/dio.dart';
import '../config/env_config.dart';
import '../config/supabase_config.dart';

class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (EnvConfig.enableLogging) {
      print('REQUEST[${options.method}] => PATH: ${options.path}');
      print('Headers: ${options.headers}');
      if (options.data != null) {
        print('Body: ${options.data}');
      }
    }
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (EnvConfig.enableLogging) {
      print('RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}');
      // Only log data for non-summary endpoints or limit the output
      if (!response.requestOptions.path.contains('/summaries')) {
        final dataStr = response.data.toString();
        if (dataStr.length > 200) {
          print('Data: ${dataStr.substring(0, 200)}... [truncated]');
        } else {
          print('Data: ${response.data}');
        }
      } else {
        // For summaries, just show count
        if (response.data is List) {
          print('Data: [${(response.data as List).length} summaries]');
        } else {
          print('Data: [summary response]');
        }
      }
    }
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (EnvConfig.enableLogging) {
      print('ERROR[${err.response?.statusCode}] => PATH: ${err.requestOptions.path}');
      print('Message: ${err.message}');
      if (err.response?.data != null) {
        print('Error Data: ${err.response?.data}');
      }
    }
    super.onError(err, handler);
  }
}

class HeaderInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers.addAll({
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    });

    // Add API key for admin endpoints
    if (options.path.contains('/admin/')) {
      options.headers['X-API-Key'] = EnvConfig.apiKey;
    }

    super.onRequest(options, handler);
  }
}

class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Add authentication token from Supabase
    final session = SupabaseConfig.client.auth.currentSession;
    if (session?.accessToken != null) {
      options.headers['Authorization'] = 'Bearer ${session!.accessToken}';
    }

    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Try to refresh the token
      try {
        final response = await SupabaseConfig.client.auth.refreshSession();
        if (response.session?.accessToken != null) {
          // Retry the original request with the new token
          final options = err.requestOptions;
          options.headers['Authorization'] = 'Bearer ${response.session!.accessToken}';

          final clonedRequest = await Dio().fetch(options);
          return handler.resolve(clonedRequest);
        }
      } catch (e) {
        // Refresh failed, let the original error pass through
      }
    }

    super.onError(err, handler);
  }
}