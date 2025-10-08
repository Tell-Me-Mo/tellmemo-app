import 'dart:convert';
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
      // For backend auth, proactively check and refresh token if expired
      final token = await _authService.getToken();

      if (token != null && token.isNotEmpty) {
        // Check if token is expired or about to expire (within 60 seconds)
        if (_isTokenExpiredOrExpiring(token)) {
          if (AppConfig.enableLogging) {
            print('[AuthInterceptor] Token expired or expiring soon, refreshing proactively...');
          }

          // Proactively refresh the token before making the request
          final newToken = await _refreshNativeToken();

          if (newToken != null) {
            options.headers['Authorization'] = 'Bearer $newToken';
            if (AppConfig.enableLogging) {
              print('[AuthInterceptor] Token refreshed successfully');
            }
          } else {
            // Refresh failed, use old token (will likely fail with 401)
            options.headers['Authorization'] = 'Bearer $token';
            if (AppConfig.enableLogging) {
              print('[AuthInterceptor] Token refresh failed, using expired token');
            }
          }
        } else {
          // Token is still valid, use it
          options.headers['Authorization'] = 'Bearer $token';
        }
      }
    }

    handler.next(options);
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
        '/api/v1/auth/refresh',
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

  /// Checks if a JWT token is expired or about to expire
  /// Returns true if token is expired or will expire within 60 seconds
  bool _isTokenExpiredOrExpiring(String token) {
    try {
      // JWT tokens are in format: header.payload.signature
      final parts = token.split('.');
      if (parts.length != 3) {
        return true; // Invalid token format, treat as expired
      }

      // Decode the payload (second part)
      final payload = parts[1];

      // Add padding if needed for base64 decoding
      String normalizedPayload = base64Url.normalize(payload);

      // Decode the payload
      final decodedPayload = utf8.decode(base64Url.decode(normalizedPayload));
      final Map<String, dynamic> payloadMap = json.decode(decodedPayload);

      // Get expiration time (exp is in seconds since epoch)
      final exp = payloadMap['exp'] as int?;
      if (exp == null) {
        return true; // No expiration time, treat as expired
      }

      // Check if token is expired or will expire within 60 seconds
      final expirationTime = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      final now = DateTime.now();
      final bufferTime = const Duration(seconds: 60);

      final isExpiring = expirationTime.isBefore(now.add(bufferTime));

      if (isExpiring && AppConfig.enableLogging) {
        final timeUntilExpiry = expirationTime.difference(now);
        if (timeUntilExpiry.isNegative) {
          print('[AuthInterceptor] Token expired ${timeUntilExpiry.abs().inSeconds}s ago');
        } else {
          print('[AuthInterceptor] Token expires in ${timeUntilExpiry.inSeconds}s');
        }
      }

      return isExpiring;
    } catch (e) {
      if (AppConfig.enableLogging) {
        print('[AuthInterceptor] Error checking token expiration: $e');
      }
      return true; // If we can't parse it, treat as expired
    }
  }
}