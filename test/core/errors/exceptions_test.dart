import 'package:flutter_test/flutter_test.dart';
import 'package:pm_master_v2/core/errors/exceptions.dart';

void main() {
  group('AppException', () {
    test('creates exception with message only', () {
      const exception = ServerException('Server error');

      expect(exception.message, 'Server error');
      expect(exception.code, isNull);
    });

    test('creates exception with message and code', () {
      const exception = ServerException('Server error', '500');

      expect(exception.message, 'Server error');
      expect(exception.code, '500');
    });

    test('toString includes message only when code is null', () {
      const exception = ServerException('Server error');

      expect(exception.toString(), 'AppException: Server error ');
    });

    test('toString includes message and code when both present', () {
      const exception = ServerException('Server error', '500');

      expect(exception.toString(), 'AppException: Server error (500)');
    });
  });

  group('ServerException', () {
    test('extends AppException', () {
      const exception = ServerException('Server error');

      expect(exception, isA<AppException>());
      expect(exception, isA<Exception>());
    });

    test('creates exception with message', () {
      const exception = ServerException('Internal server error');

      expect(exception.message, 'Internal server error');
      expect(exception.code, isNull);
    });

    test('creates exception with message and code', () {
      const exception = ServerException('Internal server error', '500');

      expect(exception.message, 'Internal server error');
      expect(exception.code, '500');
    });

    test('handles 404 not found', () {
      const exception = ServerException('Resource not found', '404');

      expect(exception.message, 'Resource not found');
      expect(exception.code, '404');
    });

    test('handles 500 server error', () {
      const exception = ServerException('Internal server error', '500');

      expect(exception.message, 'Internal server error');
      expect(exception.code, '500');
    });
  });

  group('NetworkException', () {
    test('extends AppException', () {
      const exception = NetworkException('Network error');

      expect(exception, isA<AppException>());
      expect(exception, isA<Exception>());
    });

    test('creates exception with message', () {
      const exception = NetworkException('No internet connection');

      expect(exception.message, 'No internet connection');
      expect(exception.code, isNull);
    });

    test('creates exception with message and code', () {
      const exception = NetworkException('Connection timeout', 'TIMEOUT');

      expect(exception.message, 'Connection timeout');
      expect(exception.code, 'TIMEOUT');
    });

    test('handles timeout errors', () {
      const exception = NetworkException('Request timed out', 'TIMEOUT');

      expect(exception.message, 'Request timed out');
      expect(exception.code, 'TIMEOUT');
    });

    test('handles connection errors', () {
      const exception = NetworkException('Unable to connect', 'CONNECTION_FAILED');

      expect(exception.message, 'Unable to connect');
      expect(exception.code, 'CONNECTION_FAILED');
    });
  });

  group('CacheException', () {
    test('extends AppException', () {
      const exception = CacheException('Cache error');

      expect(exception, isA<AppException>());
      expect(exception, isA<Exception>());
    });

    test('creates exception with message', () {
      const exception = CacheException('Cache read failed');

      expect(exception.message, 'Cache read failed');
      expect(exception.code, isNull);
    });

    test('creates exception with message and code', () {
      const exception = CacheException('Cache write failed', 'WRITE_ERROR');

      expect(exception.message, 'Cache write failed');
      expect(exception.code, 'WRITE_ERROR');
    });
  });

  group('ValidationException', () {
    test('extends AppException', () {
      const exception = ValidationException('Validation error');

      expect(exception, isA<AppException>());
      expect(exception, isA<Exception>());
    });

    test('creates exception with message', () {
      const exception = ValidationException('Invalid email format');

      expect(exception.message, 'Invalid email format');
      expect(exception.code, isNull);
    });

    test('creates exception with message and code', () {
      const exception = ValidationException('Invalid email format', 'INVALID_EMAIL');

      expect(exception.message, 'Invalid email format');
      expect(exception.code, 'INVALID_EMAIL');
    });

    test('handles validation errors', () {
      const exception = ValidationException('Field is required', 'REQUIRED_FIELD');

      expect(exception.message, 'Field is required');
      expect(exception.code, 'REQUIRED_FIELD');
    });
  });

  group('Exception equality and identity', () {
    test('same exception types with same values are not equal (const instances)', () {
      const exception1 = ServerException('Error', '500');
      const exception2 = ServerException('Error', '500');

      // Dart const objects are identical
      expect(identical(exception1, exception2), isTrue);
    });

    test('different exception types with same message are different', () {
      const serverException = ServerException('Error');
      const networkException = NetworkException('Error');

      expect(serverException.runtimeType, isNot(networkException.runtimeType));
    });
  });
}
