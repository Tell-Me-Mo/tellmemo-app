import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/models/live_insight_model.dart';
import '../../data/services/live_insights_api_service.dart';
import 'live_insights_api_provider.dart';

part 'historical_insights_provider.freezed.dart';

/// State for historical insights
@freezed
class HistoricalInsightsState with _$HistoricalInsightsState {
  const factory HistoricalInsightsState({
    @Default([]) List<LiveInsightModel> insights,
    @Default(0) int total,
    @Default(false) bool isLoading,
    @Default(false) bool hasMore,
    String? error,
    String? sessionId,
    LiveInsightType? filterType,
    LiveInsightPriority? filterPriority,
    @Default(100) int limit,
    @Default(0) int offset,
  }) = _HistoricalInsightsState;
}

/// Notifier for managing historical insights
class HistoricalInsightsNotifier extends StateNotifier<HistoricalInsightsState> {
  final LiveInsightsApiService _apiService;

  HistoricalInsightsNotifier(this._apiService)
      : super(const HistoricalInsightsState());

  /// Load insights for a specific project with current filters
  Future<void> loadProjectInsights(String projectId, {bool append = false}) async {
    if (!mounted) return;

    state = state.copyWith(
      isLoading: true,
      error: null,
    );

    try {
      final response = await _apiService.getProjectLiveInsights(
        projectId,
        sessionId: state.sessionId,
        insightType: state.filterType?.name,
        priority: state.filterPriority?.name,
        limit: state.limit,
        offset: append ? state.offset : 0,
      );

      if (!mounted) return;

      final newInsights = append
          ? [...state.insights, ...response.insights]
          : response.insights;

      state = state.copyWith(
        insights: newInsights,
        total: response.total,
        isLoading: false,
        hasMore: newInsights.length < response.total,
        offset: append ? state.offset + response.insights.length : response.insights.length,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load insights: ${e.toString()}',
      );
    }
  }

  /// Load insights for a specific session
  Future<void> loadSessionInsights(String sessionId) async {
    if (!mounted) return;

    state = state.copyWith(
      isLoading: true,
      error: null,
      sessionId: sessionId,
    );

    try {
      final response = await _apiService.getSessionLiveInsights(sessionId);

      if (!mounted) return;

      state = state.copyWith(
        insights: response.insights,
        total: response.total,
        isLoading: false,
        hasMore: false, // Session endpoint returns all insights
        offset: response.insights.length,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load session insights: ${e.toString()}',
      );
    }
  }

  /// Load more insights (pagination)
  Future<void> loadMore(String projectId) async {
    if (state.isLoading || !state.hasMore || !mounted) return;
    await loadProjectInsights(projectId, append: true);
  }

  /// Apply filter by insight type
  void setTypeFilter(LiveInsightType? type) {
    if (!mounted) return;
    state = state.copyWith(
      filterType: type,
      offset: 0,
      insights: [],
    );
  }

  /// Apply filter by priority
  void setPriorityFilter(LiveInsightPriority? priority) {
    if (!mounted) return;
    state = state.copyWith(
      filterPriority: priority,
      offset: 0,
      insights: [],
    );
  }

  /// Apply session filter
  void setSessionFilter(String? sessionId) {
    if (!mounted) return;
    state = state.copyWith(
      sessionId: sessionId,
      offset: 0,
      insights: [],
    );
  }

  /// Clear all filters
  void clearFilters() {
    if (!mounted) return;
    state = state.copyWith(
      filterType: null,
      filterPriority: null,
      sessionId: null,
      offset: 0,
      insights: [],
    );
  }

  /// Reset state
  void reset() {
    if (!mounted) return;
    state = const HistoricalInsightsState();
  }
}

/// Provider for historical insights state
final historicalInsightsProvider =
    StateNotifierProvider<HistoricalInsightsNotifier, HistoricalInsightsState>(
        (ref) {
  final apiService = ref.watch(liveInsightsApiServiceProvider);
  return HistoricalInsightsNotifier(apiService);
});
