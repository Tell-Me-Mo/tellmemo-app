import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../config/supabase_config.dart';
import '../services/auth_service.dart';

class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (AppConfig.enableLogging) {
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
    if (AppConfig.enableLogging) {
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
    if (AppConfig.enableLogging) {
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


    super.onRequest(options, handler);
  }
}

class AuthInterceptor extends Interceptor {
  final AuthService _authService;
  bool _isRefreshing = false;

  AuthInterceptor(this._authService);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (AppConfig.useSupabaseAuth) {
      // Add authentication token from Supabase
      final session = SupabaseConfig.client.auth.currentSession;
      if (session?.accessToken != null) {
        options.headers['Authorization'] = 'Bearer ${session!.accessToken}';
      }
    } else {
      // For backend auth, get token from auth service
      final token = await _authService.getToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      final errorMessage = err.response?.data?['detail']?.toString().toLowerCase() ?? '';

      // Check if token is expired
      if (errorMessage.contains('expired') || errorMessage.contains('token')) {
        if (AppConfig.useSupabaseAuth) {
          // Try to refresh the token (Supabase auth)
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
        } else {
          // Native auth refresh
          final newToken = await _refreshNativeToken();
          if (newToken != null) {
            // Retry the original request with the new token
            final options = err.requestOptions;
            options.headers['Authorization'] = 'Bearer $newToken';

            try {
              final clonedRequest = await Dio().fetch(options);
              return handler.resolve(clonedRequest);
            } catch (e) {
              // Retry failed
            }
          }
        }
      }
    }

    super.onError(err, handler);
  }

  Future<String?> _refreshNativeToken() async {
    // Prevent multiple simultaneous refresh calls
    if (_isRefreshing) {
      await Future.delayed(const Duration(milliseconds: 500));
      return await _authService.getToken();
    }

    _isRefreshing = true;

    try {
      final refreshToken = await _authService.getRefreshToken();

      if (refreshToken == null || refreshToken.isEmpty) {
        return null;
      }

      // Call refresh endpoint
      final dio = Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl));
      final response = await dio.post(
        '/api/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final newAccessToken = data['access_token'] as String?;
        final newRefreshToken = data['refresh_token'] as String?;

        if (newAccessToken != null) {
          await _authService.setToken(newAccessToken);
          if (newRefreshToken != null) {
            await _authService.setRefreshToken(newRefreshToken);
          }
          return newAccessToken;
        }
      }

      return null;
    } catch (e) {
      // Clear auth on refresh failure to force re-login
      await _authService.clearAuth();
      return null;
    } finally {
      _isRefreshing = false;
    }
  }
}