import 'package:flutter_test/flutter_test.dart';
import 'package:pm_master_v2/core/errors/failures.dart';

void main() {
  group('ServerFailure', () {
    test('creates failure with message only', () {
      const failure = Failure.server(message: 'Server error');

      expect(failure, isA<ServerFailure>());
      failure.when(
        server: (message, code) {
          expect(message, 'Server error');
          expect(code, isNull);
        },
        network: (_, _) => fail('Should be ServerFailure'),
        cache: (_, _) => fail('Should be ServerFailure'),
        validation: (_, _) => fail('Should be ServerFailure'),
        unknown: (_, _) => fail('Should be ServerFailure'),
      );
    });

    test('creates failure with message and code', () {
      const failure = Failure.server(message: 'Server error', code: '500');

      failure.when(
        server: (message, code) {
          expect(message, 'Server error');
          expect(code, '500');
        },
        network: (_, _) => fail('Should be ServerFailure'),
        cache: (_, _) => fail('Should be ServerFailure'),
        validation: (_, _) => fail('Should be ServerFailure'),
        unknown: (_, _) => fail('Should be ServerFailure'),
      );
    });

    test('handles 404 not found', () {
      const failure = Failure.server(message: 'Resource not found', code: '404');

      failure.when(
        server: (message, code) {
          expect(message, 'Resource not found');
          expect(code, '404');
        },
        network: (_, _) => fail('Should be ServerFailure'),
        cache: (_, _) => fail('Should be ServerFailure'),
        validation: (_, _) => fail('Should be ServerFailure'),
        unknown: (_, _) => fail('Should be ServerFailure'),
      );
    });

    test('handles 500 server error', () {
      const failure = Failure.server(message: 'Internal server error', code: '500');

      failure.when(
        server: (message, code) {
          expect(message, 'Internal server error');
          expect(code, '500');
        },
        network: (_, _) => fail('Should be ServerFailure'),
        cache: (_, _) => fail('Should be ServerFailure'),
        validation: (_, _) => fail('Should be ServerFailure'),
        unknown: (_, _) => fail('Should be ServerFailure'),
      );
    });
  });

  group('NetworkFailure', () {
    test('creates failure with message only', () {
      const failure = Failure.network(message: 'Network error');

      expect(failure, isA<NetworkFailure>());
      failure.when(
        server: (_, _) => fail('Should be NetworkFailure'),
        network: (message, code) {
          expect(message, 'Network error');
          expect(code, isNull);
        },
        cache: (_, _) => fail('Should be NetworkFailure'),
        validation: (_, _) => fail('Should be NetworkFailure'),
        unknown: (_, _) => fail('Should be NetworkFailure'),
      );
    });

    test('creates failure with message and code', () {
      const failure = Failure.network(message: 'Connection timeout', code: 'TIMEOUT');

      failure.when(
        server: (_, _) => fail('Should be NetworkFailure'),
        network: (message, code) {
          expect(message, 'Connection timeout');
          expect(code, 'TIMEOUT');
        },
        cache: (_, _) => fail('Should be NetworkFailure'),
        validation: (_, _) => fail('Should be NetworkFailure'),
        unknown: (_, _) => fail('Should be NetworkFailure'),
      );
    });

    test('handles timeout errors', () {
      const failure = Failure.network(message: 'Request timed out', code: 'TIMEOUT');

      failure.when(
        server: (_, _) => fail('Should be NetworkFailure'),
        network: (message, code) {
          expect(message, 'Request timed out');
          expect(code, 'TIMEOUT');
        },
        cache: (_, _) => fail('Should be NetworkFailure'),
        validation: (_, _) => fail('Should be NetworkFailure'),
        unknown: (_, _) => fail('Should be NetworkFailure'),
      );
    });
  });

  group('CacheFailure', () {
    test('creates failure with message only', () {
      const failure = Failure.cache(message: 'Cache error');

      expect(failure, isA<CacheFailure>());
      failure.when(
        server: (_, _) => fail('Should be CacheFailure'),
        network: (_, _) => fail('Should be CacheFailure'),
        cache: (message, code) {
          expect(message, 'Cache error');
          expect(code, isNull);
        },
        validation: (_, _) => fail('Should be CacheFailure'),
        unknown: (_, _) => fail('Should be CacheFailure'),
      );
    });

    test('creates failure with message and code', () {
      const failure = Failure.cache(message: 'Cache write failed', code: 'WRITE_ERROR');

      failure.when(
        server: (_, _) => fail('Should be CacheFailure'),
        network: (_, _) => fail('Should be CacheFailure'),
        cache: (message, code) {
          expect(message, 'Cache write failed');
          expect(code, 'WRITE_ERROR');
        },
        validation: (_, _) => fail('Should be CacheFailure'),
        unknown: (_, _) => fail('Should be CacheFailure'),
      );
    });
  });

  group('ValidationFailure', () {
    test('creates failure with message only', () {
      const failure = Failure.validation(message: 'Validation error');

      expect(failure, isA<ValidationFailure>());
      failure.when(
        server: (_, _) => fail('Should be ValidationFailure'),
        network: (_, _) => fail('Should be ValidationFailure'),
        cache: (_, _) => fail('Should be ValidationFailure'),
        validation: (message, code) {
          expect(message, 'Validation error');
          expect(code, isNull);
        },
        unknown: (_, _) => fail('Should be ValidationFailure'),
      );
    });

    test('creates failure with message and code', () {
      const failure = Failure.validation(
        message: 'Invalid email format',
        code: 'INVALID_EMAIL',
      );

      failure.when(
        server: (_, _) => fail('Should be ValidationFailure'),
        network: (_, _) => fail('Should be ValidationFailure'),
        cache: (_, _) => fail('Should be ValidationFailure'),
        validation: (message, code) {
          expect(message, 'Invalid email format');
          expect(code, 'INVALID_EMAIL');
        },
        unknown: (_, _) => fail('Should be ValidationFailure'),
      );
    });

    test('handles validation errors', () {
      const failure = Failure.validation(
        message: 'Field is required',
        code: 'REQUIRED_FIELD',
      );

      failure.when(
        server: (_, _) => fail('Should be ValidationFailure'),
        network: (_, _) => fail('Should be ValidationFailure'),
        cache: (_, _) => fail('Should be ValidationFailure'),
        validation: (message, code) {
          expect(message, 'Field is required');
          expect(code, 'REQUIRED_FIELD');
        },
        unknown: (_, _) => fail('Should be ValidationFailure'),
      );
    });
  });

  group('UnknownFailure', () {
    test('creates failure with message only', () {
      const failure = Failure.unknown(message: 'Unknown error');

      expect(failure, isA<UnknownFailure>());
      failure.when(
        server: (_, _) => fail('Should be UnknownFailure'),
        network: (_, _) => fail('Should be UnknownFailure'),
        cache: (_, _) => fail('Should be UnknownFailure'),
        validation: (_, _) => fail('Should be UnknownFailure'),
        unknown: (message, code) {
          expect(message, 'Unknown error');
          expect(code, isNull);
        },
      );
    });

    test('creates failure with message and code', () {
      const failure = Failure.unknown(
        message: 'Unexpected error',
        code: 'UNKNOWN',
      );

      failure.when(
        server: (_, _) => fail('Should be UnknownFailure'),
        network: (_, _) => fail('Should be UnknownFailure'),
        cache: (_, _) => fail('Should be UnknownFailure'),
        validation: (_, _) => fail('Should be UnknownFailure'),
        unknown: (message, code) {
          expect(message, 'Unexpected error');
          expect(code, 'UNKNOWN');
        },
      );
    });
  });

  group('Failure pattern matching', () {
    test('maybeWhen handles specific case', () {
      const failure = Failure.server(message: 'Server error');

      final result = failure.maybeWhen(
        server: (message, code) => 'Handled server error: $message',
        orElse: () => 'Other error',
      );

      expect(result, 'Handled server error: Server error');
    });

    test('maybeWhen falls through to orElse', () {
      const failure = Failure.network(message: 'Network error');

      final result = failure.maybeWhen(
        server: (_, _) => 'Server error',
        orElse: () => 'Other error',
      );

      expect(result, 'Other error');
    });

    test('map transforms failure types', () {
      const failure = Failure.validation(message: 'Invalid input');

      final result = failure.map(
        server: (_) => 'server',
        network: (_) => 'network',
        cache: (_) => 'cache',
        validation: (_) => 'validation',
        unknown: (_) => 'unknown',
      );

      expect(result, 'validation');
    });
  });

  group('Failure equality', () {
    test('same failure types with same values are equal', () {
      const failure1 = Failure.server(message: 'Error', code: '500');
      const failure2 = Failure.server(message: 'Error', code: '500');

      expect(failure1, equals(failure2));
    });

    test('different failure types with same message are not equal', () {
      const serverFailure = Failure.server(message: 'Error');
      const networkFailure = Failure.network(message: 'Error');

      expect(serverFailure, isNot(equals(networkFailure)));
    });

    test('same failure types with different messages are not equal', () {
      const failure1 = Failure.server(message: 'Error 1');
      const failure2 = Failure.server(message: 'Error 2');

      expect(failure1, isNot(equals(failure2)));
    });

    test('same failure types with different codes are not equal', () {
      const failure1 = Failure.server(message: 'Error', code: '500');
      const failure2 = Failure.server(message: 'Error', code: '404');

      expect(failure1, isNot(equals(failure2)));
    });
  });

  group('Failure copyWith', () {
    test('copyWith updates message', () {
      const original = Failure.server(message: 'Original', code: '500');
      final updated = original.copyWith(message: 'Updated');

      updated.when(
        server: (message, code) {
          expect(message, 'Updated');
          expect(code, '500');
        },
        network: (_, _) => fail('Should be ServerFailure'),
        cache: (_, _) => fail('Should be ServerFailure'),
        validation: (_, _) => fail('Should be ServerFailure'),
        unknown: (_, _) => fail('Should be ServerFailure'),
      );
    });

    test('copyWith updates code', () {
      const original = Failure.server(message: 'Error', code: '500');
      final updated = original.copyWith(code: '404');

      updated.when(
        server: (message, code) {
          expect(message, 'Error');
          expect(code, '404');
        },
        network: (_, _) => fail('Should be ServerFailure'),
        cache: (_, _) => fail('Should be ServerFailure'),
        validation: (_, _) => fail('Should be ServerFailure'),
        unknown: (_, _) => fail('Should be ServerFailure'),
      );
    });

    test('copyWith removes code when set to null', () {
      const original = Failure.server(message: 'Error', code: '500');
      final updated = original.copyWith(code: null);

      updated.when(
        server: (message, code) {
          expect(message, 'Error');
          expect(code, isNull);
        },
        network: (_, _) => fail('Should be ServerFailure'),
        cache: (_, _) => fail('Should be ServerFailure'),
        validation: (_, _) => fail('Should be ServerFailure'),
        unknown: (_, _) => fail('Should be ServerFailure'),
      );
    });
  });
}
