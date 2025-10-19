import 'package:freezed_annotation/freezed_annotation.dart';

part 'live_insight_model.freezed.dart';
part 'live_insight_model.g.dart';

/// Types of insights that can be extracted
enum LiveInsightType {
  @JsonValue('action_item')
  actionItem,
  @JsonValue('decision')
  decision,
  @JsonValue('question')
  question,
  @JsonValue('risk')
  risk,
  @JsonValue('key_point')
  keyPoint,
  @JsonValue('related_discussion')
  relatedDiscussion,
  @JsonValue('contradiction')
  contradiction,
  @JsonValue('missing_info')
  missingInfo,
}

/// Priority levels for insights
enum LiveInsightPriority {
  @JsonValue('critical')
  critical,
  @JsonValue('high')
  high,
  @JsonValue('medium')
  medium,
  @JsonValue('low')
  low,
}

/// Model representing a single meeting insight
@freezed
class LiveInsightModel with _$LiveInsightModel {
  const factory LiveInsightModel({
    // Support both API formats: 'id' from REST API, 'insight_id' from WebSocket
    @JsonKey(name: 'id', defaultValue: '') String? id,
    @JsonKey(name: 'insight_id') String? insightId,
    // Accept both 'type' (WebSocket) and 'insight_type' (REST API)
    @JsonKey(name: 'type') required LiveInsightType type,
    required LiveInsightPriority priority,
    required String content,
    @Default('') String context,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    DateTime? timestamp,
    @JsonKey(name: 'assigned_to') String? assignedTo,
    @JsonKey(name: 'due_date') String? dueDate,
    @JsonKey(name: 'confidence_score') @Default(0.0) double confidenceScore,
    @JsonKey(name: 'chunk_index') int? sourceChunkIndex,
    Map<String, dynamic>? metadata,
    // WebSocket-only fields
    List<String>? relatedContentIds,
    List<double>? similarityScores,
    String? contradictsContentId,
    String? contradictionExplanation,
  }) = _LiveInsightModel;

  factory LiveInsightModel.fromJson(Map<String, dynamic> json) =>
      _$LiveInsightModelFromJson(json);
}

/// WebSocket message types
enum LiveInsightMessageType {
  sessionInitialized,
  transcriptChunk,
  insightsExtracted,
  metricsUpdate,
  sessionPaused,
  sessionResumed,
  sessionFinalized,
  error,
  pong,
}

/// Base WebSocket message model
@freezed
class LiveInsightMessage with _$LiveInsightMessage {
  const factory LiveInsightMessage({
    required LiveInsightMessageType type,
    required DateTime timestamp,
    String? sessionId,
    String? projectId,
    String? message,
    Map<String, dynamic>? data,
  }) = _LiveInsightMessage;

  factory LiveInsightMessage.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String?;
    final LiveInsightMessageType type;

    switch (typeStr) {
      case 'session_initialized':
        type = LiveInsightMessageType.sessionInitialized;
        break;
      case 'transcript_chunk':
        type = LiveInsightMessageType.transcriptChunk;
        break;
      case 'insights_extracted':
        type = LiveInsightMessageType.insightsExtracted;
        break;
      case 'metrics_update':
        type = LiveInsightMessageType.metricsUpdate;
        break;
      case 'session_paused':
        type = LiveInsightMessageType.sessionPaused;
        break;
      case 'session_resumed':
        type = LiveInsightMessageType.sessionResumed;
        break;
      case 'session_finalized':
        type = LiveInsightMessageType.sessionFinalized;
        break;
      case 'error':
        type = LiveInsightMessageType.error;
        break;
      case 'pong':
        type = LiveInsightMessageType.pong;
        break;
      default:
        type = LiveInsightMessageType.error;
    }

    return LiveInsightMessage(
      type: type,
      timestamp: DateTime.parse(json['timestamp'] as String),
      sessionId: json['session_id'] as String?,
      projectId: json['project_id'] as String?,
      message: json['message'] as String?,
      data: json,
    );
  }
}

/// Transcript chunk model
@freezed
class TranscriptChunk with _$TranscriptChunk {
  const factory TranscriptChunk({
    required int chunkIndex,
    required String text,
    String? speaker,
    required DateTime timestamp,
  }) = _TranscriptChunk;

  factory TranscriptChunk.fromJson(Map<String, dynamic> json) =>
      _$TranscriptChunkFromJson(json);
}

/// Insights extraction result
@freezed
class InsightsExtractionResult with _$InsightsExtractionResult {
  const factory InsightsExtractionResult({
    required int chunkIndex,
    required List<LiveInsightModel> insights,
    required int totalInsights,
    required int processingTimeMs,
    required DateTime timestamp,
  }) = _InsightsExtractionResult;

  factory InsightsExtractionResult.fromJson(Map<String, dynamic> json) {
    return InsightsExtractionResult(
      chunkIndex: json['chunk_index'] as int,
      insights: (json['insights'] as List<dynamic>)
          .map((e) => LiveInsightModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalInsights: json['total_insights'] as int,
      processingTimeMs: json['processing_time_ms'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

/// Session metrics model
@freezed
class SessionMetrics with _$SessionMetrics {
  const factory SessionMetrics({
    required double sessionDurationSeconds,
    required int chunksProcessed,
    required int totalInsights,
    required Map<String, int> insightsByType,
    required double avgProcessingTimeMs,
    required double avgTranscriptionTimeMs,
  }) = _SessionMetrics;

  factory SessionMetrics.fromJson(Map<String, dynamic> json) {
    return SessionMetrics(
      sessionDurationSeconds:
          (json['session_duration_seconds'] as num).toDouble(),
      chunksProcessed: json['chunks_processed'] as int,
      totalInsights: json['total_insights'] as int,
      insightsByType: Map<String, int>.from(json['insights_by_type'] as Map),
      avgProcessingTimeMs: (json['avg_processing_time_ms'] as num).toDouble(),
      avgTranscriptionTimeMs:
          (json['avg_transcription_time_ms'] as num).toDouble(),
    );
  }
}

/// Session finalized result
@freezed
class SessionFinalizedResult with _$SessionFinalizedResult {
  const factory SessionFinalizedResult({
    required String sessionId,
    required int totalInsights,
    required Map<String, List<LiveInsightModel>> insightsByType,
    required List<LiveInsightModel> allInsights,
    required SessionMetrics metrics,
  }) = _SessionFinalizedResult;

  factory SessionFinalizedResult.fromJson(Map<String, dynamic> json) {
    final insightsData = json['insights'] as Map<String, dynamic>;

    // Parse insights by type
    final insightsByType = <String, List<LiveInsightModel>>{};
    final insightsByTypeData =
        insightsData['insights_by_type'] as Map<String, dynamic>?;

    if (insightsByTypeData != null) {
      insightsByTypeData.forEach((key, value) {
        insightsByType[key] = (value as List<dynamic>)
            .map((e) => LiveInsightModel.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    }

    // Parse all insights
    final allInsights = (insightsData['insights'] as List<dynamic>)
        .map((e) => LiveInsightModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return SessionFinalizedResult(
      sessionId: json['session_id'] as String,
      totalInsights: insightsData['total_insights'] as int,
      insightsByType: insightsByType,
      allInsights: allInsights,
      metrics: SessionMetrics.fromJson(json['metrics'] as Map<String, dynamic>),
    );
  }
}
