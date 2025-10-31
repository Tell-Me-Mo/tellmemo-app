import 'package:freezed_annotation/freezed_annotation.dart';

part 'transcript_model.freezed.dart';
part 'transcript_model.g.dart';

/// Enum for transcription state
enum TranscriptionState {
  @JsonValue('partial')
  partial,
  @JsonValue('final')
  final_,
}

/// Model for a single transcript segment
/// Represents a transcribed piece of audio with speaker attribution
@freezed
class TranscriptModel with _$TranscriptModel {
  const factory TranscriptModel({
    /// Unique identifier for this transcript segment
    required String id,

    /// The transcribed text
    required String text,

    /// Speaker label (e.g., "Speaker A", "Speaker B", or actual name if mapped)
    String? speaker,

    /// Timestamp when this segment was spoken
    required DateTime timestamp,

    /// Transcription state (partial or final)
    required TranscriptionState state,

    /// Confidence score from transcription service (0.0 - 1.0)
    double? confidence,

    /// Start time in milliseconds from beginning of recording
    int? startMs,

    /// End time in milliseconds from beginning of recording
    int? endMs,
  }) = _TranscriptModel;

  factory TranscriptModel.fromJson(Map<String, dynamic> json) =>
      _$TranscriptModelFromJson(json);
}

/// Extension methods for TranscriptModel
extension TranscriptModelX on TranscriptModel {
  /// Check if this is a partial (unstable) transcript
  bool get isPartial => state == TranscriptionState.partial;

  /// Check if this is a final (stable) transcript
  bool get isFinal => state == TranscriptionState.final_;

  /// Get a display-friendly speaker label
  String get displaySpeaker => speaker ?? 'Unknown Speaker';

  /// Get confidence percentage for display
  String get confidenceDisplay =>
      confidence != null ? '${(confidence! * 100).toStringAsFixed(0)}%' : '';
}
