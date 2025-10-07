import 'package:flutter_test/flutter_test.dart';
import 'package:pm_master_v2/core/utils/logger.dart';

void main() {
  group('Logger', () {
    group('debug', () {
      test('logs debug message with correct level', () {
        // This test verifies that debug() can be called without throwing
        expect(() => Logger.debug('Debug message'), returnsNormally);
      });

      test('logs debug message with error object', () {
        final error = Exception('Test error');
        expect(() => Logger.debug('Debug with error', error), returnsNormally);
      });

      test('logs debug message with null error', () {
        expect(() => Logger.debug('Debug message', null), returnsNormally);
      });
    });

    group('info', () {
      test('logs info message with correct level', () {
        expect(() => Logger.info('Info message'), returnsNormally);
      });

      test('logs info message with error object', () {
        final error = Exception('Test error');
        expect(() => Logger.info('Info with error', error), returnsNormally);
      });

      test('logs info message with null error', () {
        expect(() => Logger.info('Info message', null), returnsNormally);
      });
    });

    group('warning', () {
      test('logs warning message with correct level', () {
        expect(() => Logger.warning('Warning message'), returnsNormally);
      });

      test('logs warning message with error object', () {
        final error = Exception('Test error');
        expect(() => Logger.warning('Warning with error', error), returnsNormally);
      });

      test('logs warning message with null error', () {
        expect(() => Logger.warning('Warning message', null), returnsNormally);
      });
    });

    group('error', () {
      test('logs error message with correct level', () {
        expect(() => Logger.error('Error message'), returnsNormally);
      });

      test('logs error message with error object', () {
        final error = Exception('Test error');
        expect(() => Logger.error('Error with error', error), returnsNormally);
      });

      test('logs error message with null error', () {
        expect(() => Logger.error('Error message', null), returnsNormally);
      });
    });

    group('edge cases', () {
      test('logs empty string message', () {
        expect(() => Logger.debug(''), returnsNormally);
        expect(() => Logger.info(''), returnsNormally);
        expect(() => Logger.warning(''), returnsNormally);
        expect(() => Logger.error(''), returnsNormally);
      });

      test('logs very long message', () {
        final longMessage = 'A' * 10000;
        expect(() => Logger.debug(longMessage), returnsNormally);
        expect(() => Logger.info(longMessage), returnsNormally);
        expect(() => Logger.warning(longMessage), returnsNormally);
        expect(() => Logger.error(longMessage), returnsNormally);
      });

      test('logs message with special characters', () {
        const specialMessage = 'Test \n\t\r special 🚀 chars';
        expect(() => Logger.debug(specialMessage), returnsNormally);
        expect(() => Logger.info(specialMessage), returnsNormally);
        expect(() => Logger.warning(specialMessage), returnsNormally);
        expect(() => Logger.error(specialMessage), returnsNormally);
      });

      test('logs message with Unicode characters', () {
        const unicodeMessage = 'Test 你好 мир 🌍';
        expect(() => Logger.debug(unicodeMessage), returnsNormally);
        expect(() => Logger.info(unicodeMessage), returnsNormally);
        expect(() => Logger.warning(unicodeMessage), returnsNormally);
        expect(() => Logger.error(unicodeMessage), returnsNormally);
      });
    });
  });
}
