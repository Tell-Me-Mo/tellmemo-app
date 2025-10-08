import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:pm_master_v2/core/utils/error_utils.dart';

void main() {
  group('ErrorUtils', () {
    group('getUserFriendlyMessage', () {
      test('extracts detail field from FastAPI error response', () {
        // Arrange - Create a DioException with FastAPI-style error
        final response = Response(
          requestOptions: RequestOptions(path: '/api/test'),
          data: {'detail': 'File too large. Maximum size is 500MB'},
          statusCode: 413,
        );
        final error = DioException(
          requestOptions: RequestOptions(path: '/api/test'),
          response: response,
          type: DioExceptionType.badResponse,
        );

        // Act
        final message = ErrorUtils.getUserFriendlyMessage(error);

        // Assert
        expect(message, 'File too large. Maximum size is 500MB');
        // Should NOT contain technical jargon
        expect(message, isNot(contains('DioException')));
        expect(message, isNot(contains('RequestOptions')));
        expect(message, isNot(contains('status code')));
      });

      test('extracts message field from alternative error format', () {
        // Arrange
        final response = Response(
          requestOptions: RequestOptions(path: '/api/test'),
          data: {'message': 'Custom error message'},
          statusCode: 400,
        );
        final error = DioException(
          requestOptions: RequestOptions(path: '/api/test'),
          response: response,
          type: DioExceptionType.badResponse,
        );

        // Act
        final message = ErrorUtils.getUserFriendlyMessage(error);

        // Assert
        expect(message, 'Custom error message');
      });

      test('handles string response data', () {
        // Arrange
        final response = Response(
          requestOptions: RequestOptions(path: '/api/test'),
          data: 'Simple error string',
          statusCode: 500,
        );
        final error = DioException(
          requestOptions: RequestOptions(path: '/api/test'),
          response: response,
          type: DioExceptionType.badResponse,
        );

        // Act
        final message = ErrorUtils.getUserFriendlyMessage(error);

        // Assert
        expect(message, 'Simple error string');
      });

      test('provides friendly message for 413 status without detail', () {
        // Arrange
        final response = Response(
          requestOptions: RequestOptions(path: '/api/test'),
          statusCode: 413,
          statusMessage: 'Payload Too Large',
        );
        final error = DioException(
          requestOptions: RequestOptions(path: '/api/test'),
          response: response,
          type: DioExceptionType.badResponse,
        );

        // Act
        final message = ErrorUtils.getUserFriendlyMessage(error);

        // Assert
        expect(message, contains('Payload Too Large'));
      });

      test('provides friendly message for common HTTP status codes', () {
        final testCases = [
          (400, 'Invalid request'),
          (401, 'Authentication required'),
          (403, 'Access denied'),
          (404, 'not found'),
          (422, 'Validation error'),
          (429, 'Too many requests'),
          (500, 'Server error'),
          (503, 'temporarily unavailable'),
        ];

        for (final (statusCode, expectedText) in testCases) {
          // Arrange
          final response = Response(
            requestOptions: RequestOptions(path: '/api/test'),
            statusCode: statusCode,
          );
          final error = DioException(
            requestOptions: RequestOptions(path: '/api/test'),
            response: response,
            type: DioExceptionType.badResponse,
          );

          // Act
          final message = ErrorUtils.getUserFriendlyMessage(error);

          // Assert
          expect(
            message.toLowerCase(),
            contains(expectedText.toLowerCase()),
            reason: 'Status $statusCode should mention "$expectedText"',
          );
        }
      });

      test('provides friendly message for network timeout', () {
        // Arrange
        final error = DioException(
          requestOptions: RequestOptions(path: '/api/test'),
          type: DioExceptionType.connectionTimeout,
          message: 'Connection timeout',
        );

        // Act
        final message = ErrorUtils.getUserFriendlyMessage(error);

        // Assert
        expect(message, contains('timeout'));
        expect(message, contains('internet connection'));
      });

      test('provides friendly message for send timeout (large file)', () {
        // Arrange
        final error = DioException(
          requestOptions: RequestOptions(path: '/api/test'),
          type: DioExceptionType.sendTimeout,
          message: 'Send timeout',
        );

        // Act
        final message = ErrorUtils.getUserFriendlyMessage(error);

        // Assert
        expect(message, contains('timeout'));
        expect(message.toLowerCase(), contains('large'));
      });

      test('handles non-DioException errors gracefully', () {
        // Act
        final message1 = ErrorUtils.getUserFriendlyMessage(
          Exception('Something went wrong'),
        );
        final message2 = ErrorUtils.getUserFriendlyMessage(
          'String error',
        );

        // Assert
        expect(message1, 'Something went wrong');
        expect(message2, 'String error');
      });
    });

    group('helper methods', () {
      test('isFileTooLarge returns true for 413 status', () {
        final response = Response(
          requestOptions: RequestOptions(path: '/api/test'),
          statusCode: 413,
        );
        final error = DioException(
          requestOptions: RequestOptions(path: '/api/test'),
          response: response,
        );

        expect(ErrorUtils.isFileTooLarge(error), isTrue);
      });

      test('isUnauthorized returns true for 401 status', () {
        final response = Response(
          requestOptions: RequestOptions(path: '/api/test'),
          statusCode: 401,
        );
        final error = DioException(
          requestOptions: RequestOptions(path: '/api/test'),
          response: response,
        );

        expect(ErrorUtils.isUnauthorized(error), isTrue);
      });

      test('isServerError returns true for 5xx status codes', () {
        final statusCodes = [500, 501, 502, 503, 504];

        for (final statusCode in statusCodes) {
          final response = Response(
            requestOptions: RequestOptions(path: '/api/test'),
            statusCode: statusCode,
          );
          final error = DioException(
            requestOptions: RequestOptions(path: '/api/test'),
            response: response,
          );

          expect(
            ErrorUtils.isServerError(error),
            isTrue,
            reason: '$statusCode should be recognized as server error',
          );
        }
      });

      test('isNetworkError returns true for connection issues', () {
        final networkErrorTypes = [
          DioExceptionType.connectionTimeout,
          DioExceptionType.sendTimeout,
          DioExceptionType.receiveTimeout,
          DioExceptionType.connectionError,
        ];

        for (final errorType in networkErrorTypes) {
          final error = DioException(
            requestOptions: RequestOptions(path: '/api/test'),
            type: errorType,
          );

          expect(
            ErrorUtils.isNetworkError(error),
            isTrue,
            reason: '$errorType should be recognized as network error',
          );
        }
      });
    });
  });
}
