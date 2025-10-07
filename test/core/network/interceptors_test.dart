import 'package:dio/dio.dart';
import 'package:dio_retry_plus/dio_retry_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pm_master_v2/core/network/interceptors.dart';
import 'package:pm_master_v2/core/services/auth_service.dart';

@GenerateMocks([AuthService, RequestInterceptorHandler, ErrorInterceptorHandler, ResponseInterceptorHandler])
import 'interceptors_test.mocks.dart';

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
