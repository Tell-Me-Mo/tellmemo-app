import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:dio_retry_plus/dio_retry_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pm_master_v2/core/network/interceptors.dart';
import 'package:pm_master_v2/core/services/auth_service.dart';

@GenerateMocks([AuthService, RequestInterceptorHandler, ErrorInterceptorHandler, ResponseInterceptorHandler])
import 'interceptors_test.mocks.dart';

/// Helper function to generate a JWT token for testing
String generateTestJwtToken({required int expiresInSeconds}) {
  final now = DateTime.now();
  final expiration = now.add(Duration(seconds: expiresInSeconds));

  final header = base64Url.encode(utf8.encode(json.encode({
    'alg': 'HS256',
    'typ': 'JWT',
  })));

  final payload = base64Url.encode(utf8.encode(json.encode({
    'sub': 'test-user-id',
    'email': 'test@example.com',
    'exp': expiration.millisecondsSinceEpoch ~/ 1000,
    'iat': now.millisecondsSinceEpoch ~/ 1000,
  })));

  final signature = base64Url.encode(utf8.encode('test-signature'));

  return '$header.$payload.$signature';
}

void main() {
  group('HeaderInterceptor', () {
    late HeaderInterceptor interceptor;
    late MockRequestInterceptorHandler mockHandler;
    late RequestOptions requestOptions;

    setUp(() {
      interceptor = HeaderInterceptor();
      mockHandler = MockRequestInterceptorHandler();
      requestOptions = RequestOptions(path: '/test');
    });

    test('adds Content-Type and Accept headers to request', () {
      // Act
      interceptor.onRequest(requestOptions, mockHandler);

      // Assert
      expect(requestOptions.headers['Content-Type'], 'application/json');
      expect(requestOptions.headers['Accept'], 'application/json');
      verify(mockHandler.next(requestOptions)).called(1);
    });

    test('preserves existing headers', () {
      // Arrange
      requestOptions.headers['X-Custom-Header'] = 'custom-value';

      // Act
      interceptor.onRequest(requestOptions, mockHandler);

      // Assert
      expect(requestOptions.headers['Content-Type'], 'application/json');
      expect(requestOptions.headers['Accept'], 'application/json');
      expect(requestOptions.headers['X-Custom-Header'], 'custom-value');
    });

    test('overwrites Content-Type if already exists', () {
      // Arrange
      requestOptions.headers['Content-Type'] = 'text/plain';

      // Act
      interceptor.onRequest(requestOptions, mockHandler);

      // Assert
      expect(requestOptions.headers['Content-Type'], 'application/json');
    });
  });

  group('AuthInterceptor', () {
    late AuthInterceptor interceptor;
    late MockAuthService mockAuthService;
    late MockErrorInterceptorHandler mockErrorHandler;

    setUp(() {
      mockAuthService = MockAuthService();
      interceptor = AuthInterceptor(mockAuthService);
      mockErrorHandler = MockErrorInterceptorHandler();
    });

    test('handles 401 error by attempting token refresh', () async {
      // Arrange
      when(mockAuthService.getRefreshToken()).thenAnswer((_) async => null);
      when(mockAuthService.clearAuth()).thenAnswer((_) async => {});

      final dioError = DioException(
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          data: {'detail': 'Token expired'},
          statusCode: 401,
          requestOptions: RequestOptions(path: '/test'),
        ),
      );

      // Act
      interceptor.onError(dioError, mockErrorHandler);
      await Future.microtask(() {}); // Allow async to start
      await Future.delayed(Duration(milliseconds: 50));

      // Assert - should attempt to get refresh token
      verify(mockAuthService.getRefreshToken()).called(1);
      verify(mockErrorHandler.next(dioError)).called(1);
    });

    test('ignores non-401 errors', () async {
      // Arrange
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          data: {'detail': 'Server error'},
          statusCode: 500,
          requestOptions: RequestOptions(path: '/test'),
        ),
      );

      // Act
      interceptor.onError(dioError, mockErrorHandler);
      await Future.microtask(() {});
      await Future.delayed(Duration(milliseconds: 50));

      // Assert - error should pass through without token refresh attempt
      verify(mockErrorHandler.next(dioError)).called(1);
      verifyNever(mockAuthService.getRefreshToken());
    });

    test('passes through 401 error without refresh token', () async {
      // Arrange
      when(mockAuthService.getRefreshToken()).thenAnswer((_) async => null);
      when(mockAuthService.clearAuth()).thenAnswer((_) async => {});

      final dioError = DioException(
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          data: {'detail': 'Token expired'},
          statusCode: 401,
          requestOptions: RequestOptions(path: '/test'),
        ),
      );

      // Act
      interceptor.onError(dioError, mockErrorHandler);
      await Future.microtask(() {});
      await Future.delayed(Duration(milliseconds: 50));

      // Assert
      verify(mockErrorHandler.next(dioError)).called(1);
    });
  });

  group('AuthInterceptor - Proactive Token Refresh', () {
    late AuthInterceptor interceptor;
    late MockAuthService mockAuthService;
    late MockRequestInterceptorHandler mockHandler;
    late RequestOptions requestOptions;

    setUp(() {
      mockAuthService = MockAuthService();
      interceptor = AuthInterceptor(mockAuthService);
      mockHandler = MockRequestInterceptorHandler();
      requestOptions = RequestOptions(path: '/test');
    });

    test('does not refresh token when token is valid and not expiring', () async {
      // Arrange - token expires in 5 minutes (300 seconds)
      final validToken = generateTestJwtToken(expiresInSeconds: 300);
      when(mockAuthService.getToken()).thenAnswer((_) async => validToken);

      // Act
      interceptor.onRequest(requestOptions, mockHandler);
      await Future.delayed(Duration(milliseconds: 50)); // Wait for async token check

      // Assert - token should be used as-is without refresh attempt
      expect(requestOptions.headers['Authorization'], 'Bearer $validToken');
      verify(mockAuthService.getToken()).called(1);
      verifyNever(mockAuthService.getRefreshToken());
      verify(mockHandler.next(requestOptions)).called(1);
    });

    test('proactively refreshes token when token expires within 60 seconds', () async {
      // Arrange - token expires in 30 seconds (within buffer)
      final expiringToken = generateTestJwtToken(expiresInSeconds: 30);
      final newToken = generateTestJwtToken(expiresInSeconds: 3600);
      final refreshToken = 'refresh-token-123';

      when(mockAuthService.getToken()).thenAnswer((_) async => expiringToken);
      when(mockAuthService.getRefreshToken()).thenAnswer((_) async => refreshToken);
      when(mockAuthService.setToken(any)).thenAnswer((_) async => {});

      // Mock the refresh endpoint response using interceptor
      final testDio = Dio();
      testDio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path.contains('/auth/refresh')) {
              handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'access_token': newToken,
                    'refresh_token': 'new-refresh-token',
                  },
                ),
              );
            } else {
              handler.next(options);
            }
          },
        ),
      );

      // Act
      interceptor.onRequest(requestOptions, mockHandler);
      await Future.delayed(Duration(milliseconds: 100)); // Wait for async refresh

      // Assert - should attempt token refresh
      verify(mockAuthService.getToken()).called(greaterThanOrEqualTo(1));
      verify(mockAuthService.getRefreshToken()).called(1);
    });

    test('proactively refreshes token when token is already expired', () async {
      // Arrange - token expired 10 seconds ago
      final expiredToken = generateTestJwtToken(expiresInSeconds: -10);
      final refreshToken = 'refresh-token-123';

      when(mockAuthService.getToken()).thenAnswer((_) async => expiredToken);
      when(mockAuthService.getRefreshToken()).thenAnswer((_) async => refreshToken);
      when(mockAuthService.setToken(any)).thenAnswer((_) async => {});

      // Act
      interceptor.onRequest(requestOptions, mockHandler);
      await Future.delayed(Duration(milliseconds: 100)); // Wait for async refresh

      // Assert - should attempt token refresh
      verify(mockAuthService.getToken()).called(greaterThanOrEqualTo(1));
      verify(mockAuthService.getRefreshToken()).called(1);
    });

    test('uses expired token when refresh fails', () async {
      // Arrange - token expired, but refresh fails
      final expiredToken = generateTestJwtToken(expiresInSeconds: -10);

      when(mockAuthService.getToken()).thenAnswer((_) async => expiredToken);
      when(mockAuthService.getRefreshToken()).thenAnswer((_) async => null);
      when(mockAuthService.clearAuth()).thenAnswer((_) async => {});

      // Act
      interceptor.onRequest(requestOptions, mockHandler);
      await Future.delayed(Duration(milliseconds: 100)); // Wait for async refresh

      // Assert - should use expired token (request will likely fail with 401)
      verify(mockAuthService.getToken()).called(greaterThanOrEqualTo(1));
      verify(mockAuthService.getRefreshToken()).called(1);
      verify(mockHandler.next(requestOptions)).called(1);
    });

    test('handles invalid token format gracefully', () async {
      // Arrange - invalid JWT format (missing parts)
      final invalidToken = 'invalid.token';

      when(mockAuthService.getToken()).thenAnswer((_) async => invalidToken);
      when(mockAuthService.getRefreshToken()).thenAnswer((_) async => null);
      when(mockAuthService.clearAuth()).thenAnswer((_) async => {});

      // Act
      interceptor.onRequest(requestOptions, mockHandler);
      await Future.delayed(Duration(milliseconds: 100)); // Wait for async refresh

      // Assert - should attempt refresh even for invalid token
      verify(mockAuthService.getToken()).called(greaterThanOrEqualTo(1));
      verify(mockAuthService.getRefreshToken()).called(1);
    });

    test('handles token without expiration field', () async {
      // Arrange - create JWT without 'exp' field
      final header = base64Url.encode(utf8.encode(json.encode({'alg': 'HS256', 'typ': 'JWT'})));
      final payload = base64Url.encode(utf8.encode(json.encode({'sub': 'test-user'})));
      final signature = base64Url.encode(utf8.encode('signature'));
      final tokenWithoutExp = '$header.$payload.$signature';

      when(mockAuthService.getToken()).thenAnswer((_) async => tokenWithoutExp);
      when(mockAuthService.getRefreshToken()).thenAnswer((_) async => null);
      when(mockAuthService.clearAuth()).thenAnswer((_) async => {});

      // Act
      interceptor.onRequest(requestOptions, mockHandler);
      await Future.delayed(Duration(milliseconds: 100)); // Wait for async refresh

      // Assert - should treat as expired and attempt refresh
      verify(mockAuthService.getToken()).called(greaterThanOrEqualTo(1));
      verify(mockAuthService.getRefreshToken()).called(1);
    });

    test('does not add Authorization header when no token available', () async {
      // Arrange
      when(mockAuthService.getToken()).thenAnswer((_) async => null);

      // Act
      interceptor.onRequest(requestOptions, mockHandler);
      await Future.delayed(Duration(milliseconds: 50)); // Wait for async check

      // Assert
      expect(requestOptions.headers.containsKey('Authorization'), false);
      verify(mockHandler.next(requestOptions)).called(1);
      verifyNever(mockAuthService.getRefreshToken());
    });
  });

  group('LoggingInterceptor', () {
    late LoggingInterceptor interceptor;
    late MockRequestInterceptorHandler mockRequestHandler;
    late MockResponseInterceptorHandler mockResponseHandler;
    late MockErrorInterceptorHandler mockErrorHandler;

    setUp(() {
      interceptor = LoggingInterceptor();
      mockRequestHandler = MockRequestInterceptorHandler();
      mockResponseHandler = MockResponseInterceptorHandler();
      mockErrorHandler = MockErrorInterceptorHandler();
    });

    test('calls next handler for requests', () {
      // Arrange
      final requestOptions = RequestOptions(
        path: '/api/test',
        method: 'GET',
        headers: {'Authorization': 'Bearer token'},
      );

      // Act
      interceptor.onRequest(requestOptions, mockRequestHandler);

      // Assert
      verify(mockRequestHandler.next(requestOptions)).called(1);
    });

    test('calls next handler for responses', () {
      // Arrange
      final response = Response(
        data: {'id': '123', 'name': 'Test'},
        statusCode: 200,
        requestOptions: RequestOptions(path: '/api/test'),
      );

      // Act
      interceptor.onResponse(response, mockResponseHandler);

      // Assert
      verify(mockResponseHandler.next(response)).called(1);
    });

    test('calls next handler for errors', () {
      // Arrange
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/api/test'),
        response: Response(
          data: {'detail': 'Not found'},
          statusCode: 404,
          requestOptions: RequestOptions(path: '/api/test'),
        ),
        message: 'Not found',
      );

      // Act
      interceptor.onError(dioError, mockErrorHandler);

      // Assert
      verify(mockErrorHandler.next(dioError)).called(1);
    });

    test('handles errors without response data', () {
      // Arrange
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/api/test'),
        message: 'Network error',
      );

      // Act
      interceptor.onError(dioError, mockErrorHandler);

      // Assert
      verify(mockErrorHandler.next(dioError)).called(1);
    });
  });

  group('RetryInterceptor', () {
    test('retries on connection timeout', () async {
      // Arrange
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:9999'));
      int attemptCount = 0;

      dio.interceptors.add(
        RetryInterceptor(
          dio: dio,
          retries: 2,
          retryDelays: const [Duration(milliseconds: 100), Duration(milliseconds: 100)],
          toNoInternetPageNavigator: () async {},
          logPrint: (message) {},
        ),
      );

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            attemptCount++;
            handler.next(options);
          },
        ),
      );

      // Act & Assert
      try {
        await dio.get('/test', options: Options(
          receiveTimeout: const Duration(milliseconds: 500),
        ));
        fail('Should have thrown DioException');
      } catch (e) {
        // Expect original request + 2 retries = 3 attempts
        expect(attemptCount, greaterThanOrEqualTo(3));
      }
    });

    test('does not retry on HTTP 401 error', () async {
      // Arrange
      final dio = Dio();
      int attemptCount = 0;

      dio.interceptors.add(
        RetryInterceptor(
          dio: dio,
          retries: 2,
          retryDelays: const [Duration(milliseconds: 100), Duration(milliseconds: 100)],
          toNoInternetPageNavigator: () async {},
          logPrint: (message) {},
        ),
      );

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            attemptCount++;
            // Simulate 401 HTTP error response
            handler.reject(
              DioException(
                requestOptions: options,
                response: Response(
                  statusCode: 401,
                  requestOptions: options,
                  data: {'detail': 'Unauthorized'},
                ),
              ),
            );
          },
        ),
      );

      // Act & Assert
      try {
        await dio.get('/test');
        fail('Should have thrown DioException');
      } catch (e) {
        // Should only attempt once (no retries for HTTP errors)
        expect(attemptCount, equals(1));
      }
    });
  });
}
