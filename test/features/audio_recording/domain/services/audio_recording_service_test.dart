import 'package:flutter_test/flutter_test.dart';
import 'package:pm_master_v2/features/audio_recording/domain/services/audio_recording_service.dart';

void main() {
  group('AudioRecordingService - Duration Limits', () {
    test('has correct max recording duration of 2 hours', () {
      expect(
        AudioRecordingService.maxRecordingDuration,
        const Duration(hours: 2),
      );
    });

    test('has correct warning threshold of 90 minutes', () {
      expect(
        AudioRecordingService.warningThreshold,
        const Duration(minutes: 90),
      );
    });

    test('warning threshold comes before max duration', () {
      expect(
        AudioRecordingService.warningThreshold <
            AudioRecordingService.maxRecordingDuration,
        true,
      );
    });

    test('max duration is exactly 120 minutes', () {
      expect(
        AudioRecordingService.maxRecordingDuration.inMinutes,
        120,
      );
    });

    test('warning threshold is exactly 90 minutes', () {
      expect(
        AudioRecordingService.warningThreshold.inMinutes,
        90,
      );
    });

    test('time between warning and max duration is 30 minutes', () {
      final difference = AudioRecordingService.maxRecordingDuration -
          AudioRecordingService.warningThreshold;
      expect(difference, const Duration(minutes: 30));
    });
  });
}
