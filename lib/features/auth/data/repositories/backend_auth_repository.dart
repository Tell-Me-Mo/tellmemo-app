import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../domain/auth_interface.dart';
import '../../../../core/services/auth_service.dart';

class BackendAuthRepository implements AuthInterface {
  final Dio _dio;
  final AuthService _authService;

  // Stream controller for auth state changes
  final _authStateController = StreamController<AuthStateChange>.broadcast();

  // Cache current user and session in memory
  AppAuthUser? _cachedUser;
  AuthSession? _cachedSession;

  BackendAuthRepository(this._dio, this._authService) {
    debugPrint('🔧 BackendAuthRepository: Initialized with Dio baseUrl: ${_dio.options.baseUrl}');
  }

  @override
  Stream<AuthStateChange> get authStateChanges => _authStateController.stream;

  @override
  AppAuthUser? get currentUser => _cachedUser;

  @override
  AuthSession? get currentSession => _cachedSession;

  @override
  Future<AuthResult> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      debugPrint('🔐 BackendAuthRepository.signUp: Starting signup for email: $email');
      debugPrint('🔐 BackendAuthRepository.signUp: Request URL: ${_dio.options.baseUrl}/api/auth/signup');
      debugPrint('🔐 BackendAuthRepository.signUp: Request data: {email: $email, password: ***, metadata: $metadata}');

      final response = await _dio.post('/api/auth/signup', data: {
        'email': email,
        'password': password,
        ...?metadata,
      });

      debugPrint('🔐 BackendAuthRepository.signUp: Response status: ${response.statusCode}');
      debugPrint('🔐 BackendAuthRepository.signUp: Response data: ${response.data}');

      final data = response.data;
      final token = data['access_token'] as String;
      final refreshToken = data['refresh_token'] as String?;
      final userId = data['user_id'] as String;

      // Store tokens and user info
      await _authService.setToken(token);
      if (refreshToken != null) {
        await _authService.setRefreshToken(refreshToken);
      }
      await _authService.setUserId(userId);

      if (data['organization_id'] != null) {
        await _authService.setOrganizationId(data['organization_id'] as String);
      }

      final user = AppAuthUser(
        id: userId,
        email: email,
        metadata: metadata,
      );

      final session = AuthSession(
        accessToken: token,
        user: user,
      );

      // Cache user and session
      _cachedUser = user;
      _cachedSession = session;

      // Emit auth state change
      _authStateController.add(AuthStateChange(session: session, user: user));

      debugPrint('🔐 BackendAuthRepository.signUp: Success! User ID: $userId');
      return AuthResult(user: user, session: session);
    } on DioException catch (e) {
      debugPrint('❌ BackendAuthRepository.signUp: DioException occurred');
      debugPrint('❌ BackendAuthRepository.signUp: Error type: ${e.type}');
      debugPrint('❌ BackendAuthRepository.signUp: Error message: ${e.message}');
      debugPrint('❌ BackendAuthRepository.signUp: Error: ${e.error}');
      debugPrint('❌ BackendAuthRepository.signUp: Response: ${e.response?.data}');
      debugPrint('❌ BackendAuthRepository.signUp: Status code: ${e.response?.statusCode}');
      debugPrint('❌ BackendAuthRepository.signUp: Request options: ${e.requestOptions.uri}');
      debugPrint('❌ BackendAuthRepository.signUp: Full error: $e');
      throw _handleDioException(e);
    } catch (e, stackTrace) {
      debugPrint('❌ BackendAuthRepository.signUp: Unexpected error: $e');
      debugPrint('❌ BackendAuthRepository.signUp: Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post('/api/auth/login', data: {
        'email': email,
        'password': password,
      });

      final data = response.data;
      final token = data['access_token'] as String;
      final refreshToken = data['refresh_token'] as String?;
      final userId = data['user_id'] as String;

      // Store tokens and user info
      await _authService.setToken(token);
      if (refreshToken != null) {
        await _authService.setRefreshToken(refreshToken);
      }
      await _authService.setUserId(userId);

      if (data['organization_id'] != null) {
        await _authService.setOrganizationId(data['organization_id'] as String);
      }

      final user = AppAuthUser(
        id: userId,
        email: email,
      );

      final session = AuthSession(
        accessToken: token,
        user: user,
      );

      // Cache user and session
      _cachedUser = user;
      _cachedSession = session;

      // Emit auth state change
      _authStateController.add(AuthStateChange(session: session, user: user));

      return AuthResult(user: user, session: session);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Invalid email or password');
      }
      throw _handleDioException(e);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      // Call backend logout endpoint if available
      try {
        await _dio.post('/api/auth/logout');
      } catch (_) {
        // Ignore backend errors during logout
      }

      // Clear local auth state
      await _authService.clearAuth();

      // Clear cached user and session
      _cachedUser = null;
      _cachedSession = null;

      // Emit auth state change
      _authStateController.add(AuthStateChange(session: null, user: null));
    } catch (e) {
      throw Exception('Failed to sign out: ${e.toString()}');
    }
  }

  @override
  Future<void> resetPassword(String email) async {
    try {
      await _dio.post('/api/auth/reset-password', data: {
        'email': email,
      });
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<AuthResult> updatePassword(String newPassword) async {
    try {
      final response = await _dio.put('/api/auth/password', data: {
        'new_password': newPassword,
      });

      final data = response.data;
      final userId = await _authService.getUserId();

      final user = AppAuthUser(
        id: userId ?? '',
        email: data['email'] as String?,
      );

      return AuthResult(user: user);
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<AuthResult> updateProfile({
    String? email,
    String? phone,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await _dio.put('/api/auth/profile', data: {
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
        if (data != null) ...data,
      });

      final responseData = response.data;
      final userId = await _authService.getUserId();

      final user = AppAuthUser(
        id: userId ?? '',
        email: email ?? responseData['email'] as String?,
        phone: phone ?? responseData['phone'] as String?,
        metadata: data,
      );

      return AuthResult(user: user);
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<void> verifyOTP({
    required String email,
    required String token,
  }) async {
    try {
      await _dio.post('/api/auth/verify-otp', data: {
        'email': email,
        'token': token,
      });
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<AuthSession?> recoverSession() async {
    try {
      final token = await _authService.getToken();

      if (token == null || token.isEmpty) {
        return null;
      }

      // Verify token with backend
      try {
        final response = await _dio.get('/api/auth/verify-token');
        final data = response.data;

        final userId = data['user_id'] as String;

        final user = AppAuthUser(
          id: userId,
          email: data['email'] as String?,
        );

        final session = AuthSession(
          accessToken: token,
          user: user,
        );

        // Cache user and session
        _cachedUser = user;
        _cachedSession = session;

        // Emit auth state change
        _authStateController.add(AuthStateChange(session: session, user: user));

        return session;
      } on DioException catch (e) {
        // If token verification fails with 401, try to refresh
        if (e.response?.statusCode == 401) {
          debugPrint('🔄 BackendAuthRepository.recoverSession: Access token expired, attempting refresh');

          final refreshToken = await _authService.getRefreshToken();
          if (refreshToken == null || refreshToken.isEmpty) {
            debugPrint('❌ BackendAuthRepository.recoverSession: No refresh token available');
            await _authService.clearAuth();
            _cachedUser = null;
            _cachedSession = null;
            return null;
          }

          try {
            // Try to refresh the token
            final refreshResponse = await _dio.post('/api/auth/refresh', data: {
              'refresh_token': refreshToken,
            });

            final refreshData = refreshResponse.data;
            final newAccessToken = refreshData['access_token'] as String;
            final newRefreshToken = refreshData['refresh_token'] as String?;
            final userId = refreshData['user_id'] as String;

            // Store new tokens
            await _authService.setToken(newAccessToken);
            if (newRefreshToken != null) {
              await _authService.setRefreshToken(newRefreshToken);
            }

            final user = AppAuthUser(
              id: userId,
              email: refreshData['email'] as String?,
            );

            final session = AuthSession(
              accessToken: newAccessToken,
              user: user,
            );

            // Cache user and session
            _cachedUser = user;
            _cachedSession = session;

            // Emit auth state change
            _authStateController.add(AuthStateChange(session: session, user: user));

            debugPrint('✅ BackendAuthRepository.recoverSession: Session refreshed successfully');
            return session;
          } catch (refreshError) {
            // Refresh failed, clear auth
            debugPrint('❌ BackendAuthRepository.recoverSession: Token refresh failed: $refreshError');
            await _authService.clearAuth();
            _cachedUser = null;
            _cachedSession = null;
            return null;
          }
        }

        // Other errors, clear auth
        await _authService.clearAuth();
        _cachedUser = null;
        _cachedSession = null;
        return null;
      } catch (e) {
        // Unexpected error, clear auth
        await _authService.clearAuth();
        _cachedUser = null;
        _cachedSession = null;
        return null;
      }
    } catch (e) {
      await _authService.clearAuth();
      _cachedUser = null;
      _cachedSession = null;
      return null;
    }
  }

  Exception _handleDioException(DioException e) {
    if (e.response != null) {
      final message = e.response?.data['detail'] ?? e.response?.data['message'] ?? 'An error occurred';
      return Exception(message);
    }
    return Exception('Network error: ${e.message}');
  }

  void dispose() {
    _authStateController.close();
  }
}
