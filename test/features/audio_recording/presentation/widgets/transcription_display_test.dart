import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pm_master_v2/features/audio_recording/presentation/widgets/transcription_display.dart';
import 'package:pm_master_v2/features/audio_recording/presentation/providers/recording_provider.dart';
import 'package:pm_master_v2/features/audio_recording/domain/services/audio_recording_service.dart';
import 'package:pm_master_v2/core/services/notification_service.dart';
import '../../../../helpers/test_helpers.dart';

void main() {
  group('TranscriptionDisplay', () {
    late MockNotificationService mockNotificationService;

    setUp(() {
      mockNotificationService = createMockNotificationService();
    });

    Widget createTestWidget({
      required RecordingStateModel state,
      bool showFullTranscript = true,
      double? maxHeight,
      VoidCallback? onRetry,
      VoidCallback? onClear,
    }) {
      return ProviderScope(
        overrides: [
          recordingNotifierProvider.overrideWith(
            () => _MockRecordingNotifier(state),
          ),
          notificationServiceProvider.overrideWith((ref) => mockNotificationService),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: TranscriptionDisplay(
              showFullTranscript: showFullTranscript,
              maxHeight: maxHeight,
              onRetry: onRetry,
              onClear: onClear,
            ),
          ),
        ),
      );
    }

    testWidgets('displays empty container when no transcription text',
        (tester) async {
      final state = RecordingStateModel(
        transcriptionText: '',
        isProcessing: false,
      );

      await tester.pumpWidget(createTestWidget(state: state));
      await tester.pumpAndSettle();

      expect(find.text('Transcription Result'), findsNothing);
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('displays processing card when isProcessing is true',
        (tester) async {
      final state = RecordingStateModel(
        isProcessing: true,
        transcriptionText: '',
      );

      await tester.pumpWidget(createTestWidget(state: state));
      await tester.pump(); // Use pump() instead of pumpAndSettle() for continuous animations

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Processing transcription...'), findsOneWidget);
      expect(
        find.text(
            'This may take a moment depending on the recording length'),
        findsOneWidget,
      );
    });

    testWidgets('displays transcription result when text is available',
        (tester) async {
      final state = RecordingStateModel(
        transcriptionText: 'This is a test transcription',
        isProcessing: false,
        duration: const Duration(seconds: 45),
      );

      await tester.pumpWidget(createTestWidget(state: state));
      await tester.pumpAndSettle();

      expect(find.text('Transcription Result'), findsOneWidget);
      expect(find.text('This is a test transcription'), findsOneWidget);
      expect(find.byIcon(Icons.transcribe_outlined), findsOneWidget);
    });

    testWidgets('displays word count in footer', (tester) async {
      final state = RecordingStateModel(
        transcriptionText: 'Hello world test',
        isProcessing: false,
      );

      await tester.pumpWidget(createTestWidget(state: state));
      await tester.pumpAndSettle();

      // Should display "3 words" in the footer
      expect(find.text('3 words'), findsOneWidget);
    });

    testWidgets('displays duration in footer', (tester) async {
      final state = RecordingStateModel(
        transcriptionText: 'Test transcription',
        isProcessing: false,
        duration: const Duration(minutes: 2, seconds: 30),
      );

      await tester.pumpWidget(createTestWidget(state: state));
      await tester.pumpAndSettle();

      expect(find.text('Duration: 02:30'), findsOneWidget);
    });

    testWidgets('displays copy button', (tester) async {
      final state = RecordingStateModel(
        transcriptionText: 'Test transcription',
        isProcessing: false,
      );

      await tester.pumpWidget(createTestWidget(state: state));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.copy), findsOneWidget);
      expect(find.byTooltip('Copy to clipboard'), findsOneWidget);
    });

    testWidgets('copy button shows notification when tapped', (tester) async {
      final state = RecordingStateModel(
        transcriptionText: 'Test transcription',
        isProcessing: false,
      );

      await tester.pumpWidget(createTestWidget(state: state));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.copy));
      await tester.pumpAndSettle();

      expect(mockNotificationService.infoCalls, contains('Transcription copied to clipboard'));
    });

    testWidgets('displays clear button when onClear callback provided',
        (tester) async {
      bool clearCalled = false;
      final state = RecordingStateModel(
        transcriptionText: 'Test transcription',
        isProcessing: false,
      );

      await tester.pumpWidget(
        createTestWidget(
          state: state,
          onClear: () => clearCalled = true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.clear), findsOneWidget);
      expect(find.byTooltip('Clear transcription'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();

      expect(clearCalled, true);
    });

    testWidgets('displays retry button when onRetry callback provided and has error',
        (tester) async {
      bool retryCalled = false;
      final state = RecordingStateModel(
        transcriptionText: 'Test transcription',
        isProcessing: false,
        errorMessage: 'Transcription failed',
      );

      await tester.pumpWidget(
        createTestWidget(
          state: state,
          onRetry: () => retryCalled = true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.refresh), findsOneWidget);
      expect(find.byTooltip('Retry transcription'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();

      expect(retryCalled, true);
    });

    testWidgets('does not display retry button when no error', (tester) async {
      final state = RecordingStateModel(
        transcriptionText: 'Test transcription',
        isProcessing: false,
        errorMessage: null,
      );

      await tester.pumpWidget(
        createTestWidget(
          state: state,
          onRetry: () {},
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.refresh), findsNothing);
    });

    testWidgets('displays full transcript when showFullTranscript is true',
        (tester) async {
      final longText = List.generate(150, (i) => 'word$i').join(' ');
      final state = RecordingStateModel(
        transcriptionText: longText,
        isProcessing: false,
      );

      await tester.pumpWidget(
        createTestWidget(
          state: state,
          showFullTranscript: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SelectableText), findsOneWidget);
    });

    testWidgets('displays compact view when showFullTranscript is false',
        (tester) async {
      final longText = List.generate(150, (i) => 'word$i').join(' ');
      final state = RecordingStateModel(
        transcriptionText: longText,
        isProcessing: false,
      );

      await tester.pumpWidget(
        createTestWidget(
          state: state,
          showFullTranscript: false,
        ),
      );
      await tester.pumpAndSettle();

      // In compact view, it shows Text widget (not SelectableText)
      // and truncates to last 100 words with "..." prefix
      expect(find.byType(Text), findsWidgets);
      // Verify that the text starts with "..." (indicating truncation)
      final textWidgets = tester.widgetList<Text>(find.byType(Text));
      final hasEllipsis = textWidgets.any((widget) {
        final data = widget.data;
        return data != null && data.startsWith('...');
      });
      expect(hasEllipsis, true);
    });

    testWidgets('respects maxHeight constraint', (tester) async {
      final state = RecordingStateModel(
        transcriptionText: 'Test transcription',
        isProcessing: false,
      );

      await tester.pumpWidget(
        createTestWidget(
          state: state,
          maxHeight: 200,
        ),
      );
      await tester.pumpAndSettle();

      final animatedContainer = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer).first,
      );

      expect(animatedContainer.constraints?.maxHeight, 200);
    });

    testWidgets('uses default maxHeight when not provided', (tester) async {
      final state = RecordingStateModel(
        transcriptionText: 'Test transcription',
        isProcessing: false,
      );

      await tester.pumpWidget(createTestWidget(state: state));
      await tester.pumpAndSettle();

      final animatedContainer = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer).first,
      );

      expect(animatedContainer.constraints?.maxHeight, 300);
    });

    testWidgets('word count is accurate for empty text', (tester) async {
      final state = RecordingStateModel(
        transcriptionText: '',
        isProcessing: false,
      );

      await tester.pumpWidget(createTestWidget(state: state));
      await tester.pumpAndSettle();

      // Empty text should show empty container, not the result card
      expect(find.text('Transcription Result'), findsNothing);
    });

    testWidgets('word count is accurate for single word', (tester) async {
      final state = RecordingStateModel(
        transcriptionText: 'Hello',
        isProcessing: false,
      );

      await tester.pumpWidget(createTestWidget(state: state));
      await tester.pumpAndSettle();

      expect(find.text('1 words'), findsOneWidget);
    });

    testWidgets('word count is accurate for multiple words', (tester) async {
      final state = RecordingStateModel(
        transcriptionText: 'This is a test',
        isProcessing: false,
      );

      await tester.pumpWidget(createTestWidget(state: state));
      await tester.pumpAndSettle();

      expect(find.text('4 words'), findsOneWidget);
    });
  });
}

// Mock RecordingNotifier for testing
class _MockRecordingNotifier extends RecordingNotifier {
  final RecordingStateModel _state;

  _MockRecordingNotifier(this._state);

  @override
  RecordingStateModel build() => _state;
}
