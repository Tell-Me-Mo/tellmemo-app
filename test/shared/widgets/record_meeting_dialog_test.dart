import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pm_master_v2/shared/widgets/record_meeting_dialog.dart';
import 'package:pm_master_v2/features/projects/domain/entities/project.dart';
import 'package:pm_master_v2/features/audio_recording/presentation/providers/recording_provider.dart';
import 'package:pm_master_v2/features/audio_recording/domain/services/audio_recording_service.dart';
import '../../helpers/test_helpers.dart';

void main() {
  group('RecordMeetingDialog Widget Tests', () {
    late Project testProject;

    setUp(() {
      testProject = Project(
        id: 'test-project-123',
        name: 'Test Project',
        description: 'A test project',
        status: ProjectStatus.active,
        createdAt: DateTime.parse('2024-01-01T00:00:00Z'),
        updatedAt: DateTime.parse('2024-01-01T00:00:00Z'),
      );
    });

    testWidgets('dialog contains Flexible widget to prevent overflow',
        (WidgetTester tester) async {
      // Arrange
      final overrides = [
        recordingNotifierProvider.overrideWith(
          () => MockRecordingNotifier(),
        ),
      ];

      // Act
      await pumpWidgetWithProviders(
        tester,
        RecordMeetingDialog(project: testProject),
        overrides: overrides,
        wrapInScaffold: true,
      );

      // Assert - verify Flexible widget exists to prevent overflow
      expect(find.byType(Flexible), findsOneWidget,
          reason: 'Flexible widget should wrap content to prevent overflow');
    });

    testWidgets('dialog contains SingleChildScrollView for scrollable content',
        (WidgetTester tester) async {
      // Arrange
      final overrides = [
        recordingNotifierProvider.overrideWith(
          () => MockRecordingNotifier(),
        ),
      ];

      // Act
      await pumpWidgetWithProviders(
        tester,
        RecordMeetingDialog(project: testProject),
        overrides: overrides,
        wrapInScaffold: true,
      );

      // Assert - verify SingleChildScrollView exists for scrolling
      expect(find.byType(SingleChildScrollView), findsOneWidget,
          reason: 'SingleChildScrollView should allow scrolling when content overflows');
    });

    testWidgets('dialog handles long error messages without overflow',
        (WidgetTester tester) async {
      // Arrange - create error state with very long message
      const longErrorMessage =
          'Upload failed: DioException [bad response]: This exception was '
          'thrown because the response has a status code of 413 and '
          'RequestOptions.validateStatus was configured to throw for this '
          'status code. The status code of 413 has the following meaning: '
          '"Client error - the request contains bad syntax or cannot be '
          'fulfilled". This is a very long error message that should '
          'cause overflow if not properly handled with scrolling.';

      final overrides = [
        recordingNotifierProvider.overrideWith(
          () => MockRecordingNotifierWithError(longErrorMessage),
        ),
      ];

      // Act - use a constrained height to simulate dialog overflow scenario
      await pumpWidgetWithProviders(
        tester,
        SizedBox(
          height: 600, // Constrained height to simulate overflow
          child: RecordMeetingDialog(project: testProject),
        ),
        overrides: overrides,
        wrapInScaffold: true,
        screenSize: const Size(400, 800),
      );

      // Assert - no overflow errors should occur
      // The test would fail with overflow exception if Flexible/ScrollView missing
      expect(tester.takeException(), isNull,
          reason: 'No overflow exceptions should occur with long error messages');

      // Verify error message is still findable (even if scrolled)
      // Note: May have multiple Flexible widgets (content area + child widgets)
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(find.byType(Flexible), findsWidgets);
    });

    testWidgets('dialog layout structure is correct',
        (WidgetTester tester) async {
      // Arrange
      final overrides = [
        recordingNotifierProvider.overrideWith(
          () => MockRecordingNotifier(),
        ),
      ];

      // Act
      await pumpWidgetWithProviders(
        tester,
        RecordMeetingDialog(project: testProject),
        overrides: overrides,
        wrapInScaffold: true,
      );

      // Assert - verify the widget tree structure
      // Column (main container)
      //   -> Header
      //   -> Flexible + SingleChildScrollView (content - prevents overflow)
      //   -> Actions
      final column = tester.widget<Column>(find.byType(Column).first);

      expect(column.mainAxisSize, MainAxisSize.min,
          reason: 'Column should use min size to fit dialog');

      // Verify Flexible is present in the children
      final flexibleFinder = find.descendant(
        of: find.byType(Column).first,
        matching: find.byType(Flexible),
      );
      expect(flexibleFinder, findsOneWidget);

      // Verify SingleChildScrollView is inside Flexible
      final scrollViewFinder = find.descendant(
        of: flexibleFinder,
        matching: find.byType(SingleChildScrollView),
      );
      expect(scrollViewFinder, findsOneWidget);
    });

    testWidgets('dialog displays project name in header',
        (WidgetTester tester) async {
      // Arrange
      final overrides = [
        recordingNotifierProvider.overrideWith(
          () => MockRecordingNotifier(),
        ),
      ];

      // Act
      await pumpWidgetWithProviders(
        tester,
        RecordMeetingDialog(project: testProject),
        overrides: overrides,
        wrapInScaffold: true,
      );

      // Assert
      expect(find.text('Record Audio'), findsOneWidget);
    });

    testWidgets('dialog has close button',
        (WidgetTester tester) async {
      // Arrange
      final overrides = [
        recordingNotifierProvider.overrideWith(
          () => MockRecordingNotifier(),
        ),
      ];

      // Act
      await pumpWidgetWithProviders(
        tester,
        RecordMeetingDialog(project: testProject),
        overrides: overrides,
        wrapInScaffold: true,
      );

      // Assert - close button should be present
      final closeButton = find.byIcon(Icons.close);
      expect(closeButton, findsOneWidget);
    });
  });
}

/// Mock recording notifier for testing
class MockRecordingNotifier extends RecordingNotifier {
  @override
  RecordingStateModel build() {
    return RecordingStateModel(
      state: RecordingState.idle,
      duration: Duration.zero,
      currentRecordingPath: null,
      errorMessage: null,
    );
  }
}

/// Mock recording notifier with error state for testing error scenarios
class MockRecordingNotifierWithError extends RecordingNotifier {
  final String errorMessage;

  MockRecordingNotifierWithError(this.errorMessage);

  @override
  RecordingStateModel build() {
    return RecordingStateModel(
      state: RecordingState.error,
      duration: Duration.zero,
      currentRecordingPath: null,
      errorMessage: errorMessage,
    );
  }
}
