import 'package:flutter_test/flutter_test.dart';
import 'package:pm_master_v2/features/audio_recording/presentation/providers/recording_provider.dart';
import 'package:pm_master_v2/features/audio_recording/domain/services/audio_recording_service.dart';

void main() {
  group('RecordingStateModel', () {
    test('creates instance with default values', () {
      final state = RecordingStateModel();

      expect(state.state, RecordingState.idle);
      expect(state.duration, Duration.zero);
      expect(state.transcriptionText, '');
      expect(state.isProcessing, false);
      expect(state.currentRecordingPath, null);
      expect(state.sessionId, null);
      expect(state.errorMessage, null);
      expect(state.amplitude, 0.0);
      expect(state.contentId, null);
      expect(state.isUploading, false);
      expect(state.showDurationWarning, false);
    });

    test('creates instance with custom values', () {
      final state = RecordingStateModel(
        state: RecordingState.recording,
        duration: const Duration(seconds: 30),
        transcriptionText: 'Test transcription',
        isProcessing: true,
        currentRecordingPath: '/path/to/recording.wav',
        sessionId: 'session123',
        errorMessage: 'Test error',
        amplitude: 0.5,
        contentId: 'content123',
        isUploading: true,
      );

      expect(state.state, RecordingState.recording);
      expect(state.duration, const Duration(seconds: 30));
      expect(state.transcriptionText, 'Test transcription');
      expect(state.isProcessing, true);
      expect(state.currentRecordingPath, '/path/to/recording.wav');
      expect(state.sessionId, 'session123');
      expect(state.errorMessage, 'Test error');
      expect(state.amplitude, 0.5);
      expect(state.contentId, 'content123');
      expect(state.isUploading, true);
    });

    test('copyWith returns new instance with updated state', () {
      final original = RecordingStateModel();
      final updated = original.copyWith(state: RecordingState.recording);

      expect(updated.state, RecordingState.recording);
      expect(updated.duration, Duration.zero);
      expect(original.state, RecordingState.idle);
    });

    test('copyWith returns new instance with updated duration', () {
      final original = RecordingStateModel();
      final updated = original.copyWith(duration: const Duration(seconds: 45));

      expect(updated.duration, const Duration(seconds: 45));
      expect(original.duration, Duration.zero);
    });

    test('copyWith returns new instance with updated transcriptionText', () {
      final original = RecordingStateModel();
      final updated = original.copyWith(transcriptionText: 'New transcription');

      expect(updated.transcriptionText, 'New transcription');
      expect(original.transcriptionText, '');
    });

    test('copyWith returns new instance with updated isProcessing', () {
      final original = RecordingStateModel();
      final updated = original.copyWith(isProcessing: true);

      expect(updated.isProcessing, true);
      expect(original.isProcessing, false);
    });

    test('copyWith returns new instance with updated currentRecordingPath', () {
      final original = RecordingStateModel();
      final updated = original.copyWith(currentRecordingPath: '/new/path.wav');

      expect(updated.currentRecordingPath, '/new/path.wav');
      expect(original.currentRecordingPath, null);
    });

    test('copyWith returns new instance with updated sessionId', () {
      final original = RecordingStateModel();
      final updated = original.copyWith(sessionId: 'new_session');

      expect(updated.sessionId, 'new_session');
      expect(original.sessionId, null);
    });

    test('copyWith returns new instance with updated errorMessage', () {
      final original = RecordingStateModel();
      final updated = original.copyWith(errorMessage: 'Error occurred');

      expect(updated.errorMessage, 'Error occurred');
      expect(original.errorMessage, null);
    });

    test('copyWith returns new instance with updated amplitude', () {
      final original = RecordingStateModel();
      final updated = original.copyWith(amplitude: 0.8);

      expect(updated.amplitude, 0.8);
      expect(original.amplitude, 0.0);
    });

    test('copyWith returns new instance with updated contentId', () {
      final original = RecordingStateModel();
      final updated = original.copyWith(contentId: 'content456');

      expect(updated.contentId, 'content456');
      expect(original.contentId, null);
    });

    test('copyWith returns new instance with updated isUploading', () {
      final original = RecordingStateModel();
      final updated = original.copyWith(isUploading: true);

      expect(updated.isUploading, true);
      expect(original.isUploading, false);
    });

    test('copyWith returns new instance with updated showDurationWarning', () {
      final original = RecordingStateModel();
      final updated = original.copyWith(showDurationWarning: true);

      expect(updated.showDurationWarning, true);
      expect(original.showDurationWarning, false);
    });

    test('copyWith with multiple fields preserves other fields', () {
      final original = RecordingStateModel(
        state: RecordingState.recording,
        duration: const Duration(seconds: 30),
        transcriptionText: 'Original text',
        amplitude: 0.5,
      );

      final updated = original.copyWith(
        state: RecordingState.paused,
        errorMessage: 'Test error',
      );

      expect(updated.state, RecordingState.paused);
      expect(updated.errorMessage, 'Test error');
      expect(updated.duration, const Duration(seconds: 30));
      expect(updated.transcriptionText, 'Original text');
      expect(updated.amplitude, 0.5);
    });

    test('copyWith preserves original when no parameters provided', () {
      final original = RecordingStateModel(
        state: RecordingState.recording,
        duration: const Duration(seconds: 30),
      );
      final updated = original.copyWith();

      expect(updated.state, original.state);
      expect(updated.duration, original.duration);
    });
  });
}
