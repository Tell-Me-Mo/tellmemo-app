import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Code Quality - No SnackBar Usage', () {
    test('should not use SnackBar or ScaffoldMessenger in lib/', () {
      // Get all Dart files in lib directory
      final libDir = Directory('lib');
      final dartFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .toList();

      expect(dartFiles.isNotEmpty, true, reason: 'No Dart files found in lib/');

      // Patterns to check for
      final forbiddenPatterns = [
        'ScaffoldMessenger',
        'showSnackBar',
        'SnackBar(',
      ];

      final violations = <String>[];

      for (final file in dartFiles) {
        final content = file.readAsStringSync();
        final lines = content.split('\n');

        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          final lineNumber = i + 1;

          // Skip comments
          final trimmedLine = line.trim();
          if (trimmedLine.startsWith('//') || trimmedLine.startsWith('*')) {
            continue;
          }

          // Check for forbidden patterns
          for (final pattern in forbiddenPatterns) {
            if (line.contains(pattern)) {
              final relativePath = file.path.replaceFirst(RegExp(r'^.*lib/'), 'lib/');
              violations.add('$relativePath:$lineNumber - Found "$pattern"');
            }
          }
        }
      }

      if (violations.isNotEmpty) {
        fail(
          'Found ${violations.length} SnackBar/ScaffoldMessenger usage(s):\n'
          '${violations.join('\n')}\n\n'
          'Use notification service instead:\n'
          '  ref.read(notificationServiceProvider.notifier).showSuccess("message")\n'
          '  ref.read(notificationServiceProvider.notifier).showError("message")\n'
          '  ref.read(notificationServiceProvider.notifier).showWarning("message")\n'
          '  ref.read(notificationServiceProvider.notifier).showInfo("message")',
        );
      }
    });

    test('should use notification service consistently', () {
      // Get all Dart files in lib directory
      final libDir = Directory('lib');
      final dartFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .toList();

      var notificationServiceUsages = 0;

      for (final file in dartFiles) {
        final content = file.readAsStringSync();
        // Count notification service usages
        notificationServiceUsages += 'notificationServiceProvider'.allMatches(content).length;
      }

      // We should have a reasonable number of notification service usages
      // (at least 50+ based on our migration)
      expect(
        notificationServiceUsages,
        greaterThan(50),
        reason: 'Expected to find notification service usage throughout the app',
      );
    });
  });
}
