import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pm_master_v2/features/audio_recording/presentation/widgets/recording_button.dart';
import 'package:pm_master_v2/features/audio_recording/presentation/providers/recording_provider.dart';
import 'package:pm_master_v2/features/audio_recording/domain/services/audio_recording_service.dart';

void main() {
  group('RecordingButton', () {
    Widget createTestWidget({
      required RecordingStateModel state,
      String projectId = 'test-project',
      String? meetingTitle,
      Function(String? contentId)? onRecordingComplete,
    }) {
      return ProviderScope(
        overrides: [
          recordingNotifierProvider.overrideWith(
            () => _MockRecordingNotifier(state),
          ),
          audioRecordingServiceProvider.overrideWith(
            (ref) => _MockAudioRecordingService(),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: RecordingButton(
                projectId: projectId,
                meetingTitle: meetingTitle,
                onRecordingComplete: onRecordingComplete,
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('displays idle state by default', (tester) async {
      final state = RecordingStateModel();

      await tester.pumpWidget(createTestWidget(state: state));
      await tester.pumpAndSettle();

      expect(find.text('Start Recording'), findsOneWidget);
      expect(find.byIcon(Icons.mic), findsOneWidget);
    });

    testWidgets('displays recording state with correct UI', (tester) async {
      final state = RecordingStateModel(
        state: RecordingState.recording,
        duration: const Duration(seconds: 30),
      );

      await tester.pumpWidget(createTestWidget(state: state));
      await tester.pump(); // Use pump() for animations

      expect(find.text('Recording...'), findsOneWidget);
      expect(find.text('00:30'), findsOneWidget);
      expect(find.byIcon(Icons.fiber_manual_record), findsOneWidget);
    });

    testWidgets('displays paused state with correct UI', (tester) async {
      final state = RecordingStateModel(
        state: RecordingState.paused,
        duration: const Duration(minutes: 1, seconds: 15),
      );

      await tester.pumpWidget(createTestWidget(state: state));
      await tester.pump();

      expect(find.text('Paused'), findsOneWidget);
      expect(find.text('01:15'), findsOneWidget);
      expect(find.byIcon(Icons.pause), findsOneWidget);
    });

    testWidgets('displays processing state with correct UI', (tester) async {
      final state = RecordingStateModel(
        state: RecordingState.processing,
      );

      await tester.pumpWidget(createTestWidget(state: state));
      await tester.pump();

      expect(find.text('Transcribing...'), findsOneWidget);
      expect(find.text('Transcribing audio...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsAtLeast(1));
    });

    testWidgets('displays error state with message', (tester) async {
      final state = RecordingStateModel(
        state: RecordingState.error,
        errorMessage: 'Microphone permission denied',
      );

      await tester.pumpWidget(createTestWidget(state: state));
      await tester.pump();

      expect(find.text('Error'), findsOneWidget);
      expect(find.text('Microphone permission denied'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsAtLeast(1));
    });

    testWidgets('shows control buttons when recording', (tester) async {
      final state = RecordingStateModel(
        state: RecordingState.recording,
      );

      await tester.pumpWidget(createTestWidget(state: state));
      await tester.pump();

      expect(find.byTooltip('Pause'), findsOneWidget);
      expect(find.byTooltip('Stop Recording'), findsOneWidget);
      expect(find.byTooltip('Cancel'), findsOneWidget);
    });

    testWidgets('shows control buttons when paused', (tester) async {
      final state = RecordingStateModel(
        state: RecordingState.paused,
      );

      await tester.pumpWidget(createTestWidget(state: state));
      await tester.pump();

      expect(find.byTooltip('Resume'), findsOneWidget);
      expect(find.byTooltip('Stop Recording'), findsOneWidget);
      expect(find.byTooltip('Cancel'), findsOneWidget);
    });

    testWidgets('hides control buttons when idle', (tester) async {
      final state = RecordingStateModel();

      await tester.pumpWidget(createTestWidget(state: state));
      await tester.pumpAndSettle();

      expect(find.byTooltip('Pause'), findsNothing);
      expect(find.byTooltip('Stop Recording'), findsNothing);
      expect(find.byTooltip('Cancel'), findsNothing);
    });

    testWidgets('hides control buttons when processing', (tester) async {
      final state = RecordingStateModel(
        state: RecordingState.processing,
      );

      await tester.pumpWidget(createTestWidget(state: state));
      await tester.pump();

      expect(find.byTooltip('Pause'), findsNothing);
      expect(find.byTooltip('Stop Recording'), findsNothing);
    });

    testWidgets('main button is disabled when processing', (tester) async {
      final state = RecordingStateModel(
        state: RecordingState.processing,
      );

      await tester.pumpWidget(createTestWidget(state: state));
      await tester.pump();

      // Find the InkWell (button wrapper)
      final inkWell = tester.widget<InkWell>(find.byType(InkWell));
      expect(inkWell.onTap, isNull);
    });

    testWidgets('formats duration correctly (under 1 minute)', (tester) async {
      final state = RecordingStateModel(
        state: RecordingState.recording,
        duration: const Duration(seconds: 45),
      );

      await tester.pumpWidget(createTestWidget(state: state));
      await tester.pump();

      expect(find.text('00:45'), findsOneWidget);
    });

    testWidgets('formats duration correctly (over 1 minute)', (tester) async {
      final state = RecordingStateModel(
        state: RecordingState.recording,
        duration: const Duration(minutes: 3, seconds: 7),
      );

      await tester.pumpWidget(createTestWidget(state: state));
      await tester.pump();

      expect(find.text('03:07'), findsOneWidget);
    });

    testWidgets('shows pause icon when recording', (tester) async {
      final state = RecordingStateModel(
        state: RecordingState.recording,
      );

      await tester.pumpWidget(createTestWidget(state: state));
      await tester.pump();

      // Find pause button in control buttons
      final pauseButtons = find.descendant(
        of: find.byType(IconButton),
        matching: find.byIcon(Icons.pause),
      );
      expect(pauseButtons, findsOneWidget);
    });

    testWidgets('shows play icon when paused', (tester) async {
      final state = RecordingStateModel(
        state: RecordingState.paused,
      );

      await tester.pumpWidget(createTestWidget(state: state));
      await tester.pump();

      // Find play button in control buttons
      final playButtons = find.descendant(
        of: find.byType(IconButton),
        matching: find.byIcon(Icons.play_arrow),
      );
      expect(playButtons, findsOneWidget);
    });

    testWidgets('shows stop icon in control buttons', (tester) async {
      final state = RecordingStateModel(
        state: RecordingState.recording,
      );

      await tester.pumpWidget(createTestWidget(state: state));
      await tester.pump();

      final stopButtons = find.descendant(
        of: find.byType(IconButton),
        matching: find.byIcon(Icons.stop),
      );
      expect(stopButtons, findsOneWidget);
    });

    testWidgets('shows close icon for cancel button', (tester) async {
      final state = RecordingStateModel(
        state: RecordingState.recording,
      );

      await tester.pumpWidget(createTestWidget(state: state));
      await tester.pump();

      final closeButtons = find.descendant(
        of: find.byType(IconButton),
        matching: find.byIcon(Icons.close),
      );
      expect(closeButtons, findsOneWidget);
    });

    testWidgets('does not show duration when idle', (tester) async {
      final state = RecordingStateModel();

      await tester.pumpWidget(createTestWidget(state: state));
      await tester.pumpAndSettle();

      expect(find.textContaining(':'), findsNothing);
    });

    testWidgets('does not show duration when error', (tester) async {
      final state = RecordingStateModel(
        state: RecordingState.error,
        errorMessage: 'Test error',
      );

      await tester.pumpWidget(createTestWidget(state: state));
      await tester.pump();

      expect(find.textContaining(':'), findsNothing);
    });

    testWidgets('shows confirmation dialog when tapping main button while recording', (tester) async {
      final state = RecordingStateModel(
        state: RecordingState.recording,
        duration: const Duration(seconds: 10),
      );

      await tester.pumpWidget(createTestWidget(state: state));
      await tester.pump();

      // Tap the main red recording button (the one with fiber_manual_record icon)
      final mainButton = find.ancestor(
        of: find.byIcon(Icons.fiber_manual_record),
        matching: find.byType(InkWell),
      );
      await tester.tap(mainButton);
      await tester.pumpAndSettle();

      // Verify confirmation dialog appears
      expect(find.text('Stop Recording?'), findsOneWidget);
      expect(find.text('Your recording will be saved and automatically transcribed.'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
      expect(find.text('Stop & Save'), findsOneWidget);
    });

    testWidgets('shows confirmation dialog when tapping stop button', (tester) async {
      final state = RecordingStateModel(
        state: RecordingState.recording,
        duration: const Duration(seconds: 10),
      );

      await tester.pumpWidget(createTestWidget(state: state));
      await tester.pump();

      // Tap the stop button
      await tester.tap(find.byTooltip('Stop Recording'));
      await tester.pumpAndSettle();

      // Verify confirmation dialog appears
      expect(find.text('Stop Recording?'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
      expect(find.text('Stop & Save'), findsOneWidget);
    });

    testWidgets('shows cancel confirmation dialog when tapping cancel button', (tester) async {
      final state = RecordingStateModel(
        state: RecordingState.recording,
        duration: const Duration(seconds: 10),
      );

      await tester.pumpWidget(createTestWidget(state: state));
      await tester.pump();

      // Tap the cancel button
      await tester.tap(find.byTooltip('Cancel'));
      await tester.pumpAndSettle();

      // Verify cancel confirmation dialog appears
      expect(find.text('Cancel Recording?'), findsOneWidget);
      expect(find.text('Are you sure you want to cancel this recording? All recorded audio will be lost.'), findsOneWidget);
      expect(find.text('Keep Recording'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('dismisses stop dialog when tapping Continue', (tester) async {
      final state = RecordingStateModel(
        state: RecordingState.recording,
        duration: const Duration(seconds: 10),
      );

      await tester.pumpWidget(createTestWidget(state: state));
      await tester.pump();

      // Tap the stop button
      await tester.tap(find.byTooltip('Stop Recording'));
      await tester.pumpAndSettle();

      // Tap Continue button
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Dialog should be dismissed
      expect(find.text('Stop Recording?'), findsNothing);
    });
  });
}

// Mock RecordingNotifier for testing
class _MockRecordingNotifier extends RecordingNotifier {
  final RecordingStateModel _state;

  _MockRecordingNotifier(this._state);

  @override
  RecordingStateModel build() => _state;

  @override
  Future<void> startRecording({
    required String projectId,
    String? meetingTitle,
  }) async {
    // No-op for testing
  }

  @override
  Future<void> pauseRecording() async {
    // No-op for testing
  }

  @override
  Future<void> resumeRecording() async {
    // No-op for testing
  }

  @override
  Future<Map<String, dynamic>?> stopRecording({
    String? projectId,
    String? language,
    String? meetingTitle,
  }) async {
    return null;
  }

  @override
  Future<void> cancelRecording() async {
    // No-op for testing
  }

  @override
  void clearError() {
    // No-op for testing
  }
}

// Mock AudioRecordingService for testing
class _MockAudioRecordingService extends AudioRecordingService {
  @override
  Stream<double> get amplitudeStream => Stream.value(0.0);
}
