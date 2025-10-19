import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:json_annotation/json_annotation.dart';
import '../../domain/models/live_insight_model.dart';

part 'live_insights_api_service.g.dart';

/// Response model for list of historical insights
@JsonSerializable()
class LiveInsightsListResponse {
  final List<LiveInsightModel> insights;
  final int total;
  @JsonKey(name: 'session_id')
  final String? sessionId;
  @JsonKey(name: 'project_id')
  final String projectId;

  LiveInsightsListResponse({
    required this.insights,
    required this.total,
    this.sessionId,
    required this.projectId,
  });

  factory LiveInsightsListResponse.fromJson(Map<String, dynamic> json) =>
      _$LiveInsightsListResponseFromJson(json);

  Map<String, dynamic> toJson() => _$LiveInsightsListResponseToJson(this);
}

@RestApi()
abstract class LiveInsightsApiService {
  factory LiveInsightsApiService(Dio dio, {String? baseUrl}) =
      _LiveInsightsApiService;

  /// Get live insights for a project with optional filtering and pagination
  ///
  /// Parameters:
  /// - [projectId] - Project UUID
  /// - [sessionId] - Optional: filter by specific session
  /// - [insightType] - Optional: filter by type (action_item, decision, question, risk, etc.)
  /// - [priority] - Optional: filter by priority (critical, high, medium, low)
  /// - [limit] - Max results (default: 100, max: 500)
  /// - [offset] - Pagination offset (default: 0)
  @GET('/api/v1/projects/{projectId}/live-insights')
  Future<LiveInsightsListResponse> getProjectLiveInsights(
    @Path('projectId') String projectId, {
    @Query('session_id') String? sessionId,
    @Query('insight_type') String? insightType,
    @Query('priority') String? priority,
    @Query('limit') int? limit,
    @Query('offset') int? offset,
  });

  /// Get all live insights for a specific session
  ///
  /// Parameters:
  /// - [sessionId] - Session identifier
  ///
  /// Returns insights ordered chronologically by chunk_index
  @GET('/api/v1/sessions/{sessionId}/live-insights')
  Future<LiveInsightsListResponse> getSessionLiveInsights(
    @Path('sessionId') String sessionId,
  );
}
