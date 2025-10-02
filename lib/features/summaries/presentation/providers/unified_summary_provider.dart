import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../core/network/api_service.dart';
import '../../data/models/unified_summary_model.dart';
import '../../data/models/summary_model.dart';

part 'unified_summary_provider.freezed.dart';

@freezed
class UnifiedSummaryState with _$UnifiedSummaryState {
  const factory UnifiedSummaryState({
    @Default(false) bool isLoading,
    @Default([]) List<UnifiedSummaryResponse> summaries,
    @Default(null) String? error,
    @Default(null) UnifiedSummaryResponse? selectedSummary,
  }) = _UnifiedSummaryState;
}

@freezed
class SummaryGenerationState with _$SummaryGenerationState {
  const factory SummaryGenerationState({
    @Default(false) bool isGenerating,
    @Default(null) UnifiedSummaryResponse? generatedSummary,
    @Default(null) String? error,
    @Default(0.0) double progress,
    @Default(null) String? jobId,
  }) = _SummaryGenerationState;
}

class UnifiedSummaryNotifier extends StateNotifier<UnifiedSummaryState> {
  final Ref ref;

  UnifiedSummaryNotifier(this.ref) : super(const UnifiedSummaryState());

  Future<void> loadSummariesForEntity({
    required String entityType,
    required String entityId,
    String? summaryType,
    String? format,
    DateTime? createdAfter,
    DateTime? createdBefore,
    int limit = 100,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final apiService = ref.read(apiServiceProvider);
      final client = apiService.client;

      final summaries = await client.listSummaries(
        entityType: entityType,
        entityId: entityId,
        summaryType: summaryType,
        format: format,
        createdAfter: createdAfter,
        createdBefore: createdBefore,
        limit: limit,
      );

      final unifiedSummaries = summaries
          .map((json) => UnifiedSummaryResponse.fromJson(json))
          .toList();

      state = state.copyWith(
        isLoading: false,
        summaries: unifiedSummaries,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load summaries: ${e.toString()}',
      );
    }
  }

  Future<void> loadAllSummaries({
    String? summaryType,
    String? format,
    DateTime? createdAfter,
    DateTime? createdBefore,
    int limit = 100,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final apiService = ref.read(apiServiceProvider);
      final client = apiService.client;

      final summaries = await client.listSummaries(
        summaryType: summaryType,
        format: format,
        createdAfter: createdAfter,
        createdBefore: createdBefore,
        limit: limit,
      );

      final unifiedSummaries = summaries
          .map((json) => UnifiedSummaryResponse.fromJson(json))
          .toList();

      state = state.copyWith(
        isLoading: false,
        summaries: unifiedSummaries,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load summaries: ${e.toString()}',
      );
    }
  }

  Future<void> loadSummaryById(String summaryId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final apiService = ref.read(apiServiceProvider);
      final client = apiService.client;

      final response = await client.getSummaryById(summaryId);
      final summary = UnifiedSummaryResponse.fromJson(response);

      state = state.copyWith(
        isLoading: false,
        selectedSummary: summary,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load summary: ${e.toString()}',
      );
    }
  }

  Future<void> deleteSummary(String summaryId) async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final client = apiService.client;

      await client.deleteSummary(summaryId);

      // Remove from local state
      final updatedSummaries = state.summaries
          .where((s) => s.summaryId != summaryId)
          .toList();

      state = state.copyWith(summaries: updatedSummaries);
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to delete summary: ${e.toString()}',
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void clearSelectedSummary() {
    state = state.copyWith(selectedSummary: null);
  }
}

class SummaryGenerationNotifier extends StateNotifier<SummaryGenerationState> {
  final Ref ref;

  SummaryGenerationNotifier(this.ref) : super(const SummaryGenerationState());

  Future<String?> generateSummary({
    required EntityType entityType,
    required String entityId,
    required SummaryType summaryType,
    String? contentId,
    DateTime? dateRangeStart,
    DateTime? dateRangeEnd,
    String format = 'general',
    String? createdBy,
    bool useJob = false,
  }) async {
    state = state.copyWith(
      isGenerating: true,
      error: null,
      progress: 0.1,
      jobId: null,
    );

    try {
      final apiService = ref.read(apiServiceProvider);
      final client = apiService.client;

      state = state.copyWith(progress: 0.3);

      final request = UnifiedSummaryRequest(
        entityType: entityType,
        entityId: entityId,
        summaryType: summaryType,
        contentId: contentId,
        dateRangeStart: dateRangeStart,
        dateRangeEnd: dateRangeEnd,
        format: format,
        createdBy: createdBy,
        useJob: useJob,
      );

      state = state.copyWith(progress: 0.5);

      final response = await client.generateUnifiedSummary(request.toJson());

      // Response received from unified summary API

      // Check if it's a job response
      if (useJob && response is Map<String, dynamic> && response.containsKey('summary_id')) {
        // For job-based generation, the summary_id field contains the job_id
        final jobId = response['summary_id'] as String;
        // Job-based summary generation initiated

        state = state.copyWith(
          isGenerating: false,
          progress: 1.0,
          jobId: jobId,
        );

        return jobId; // Return job ID for tracking
      } else {
        // Direct generation - parse summary
        state = state.copyWith(progress: 0.8);

        try {
          final summary = UnifiedSummaryResponse.fromJson(response as Map<String, dynamic>);
          // Summary generated successfully

          state = state.copyWith(
            isGenerating: false,
            generatedSummary: summary,
            progress: 1.0,
          );

          // Trigger refresh of summary lists
          ref.read(unifiedSummaryProvider.notifier).loadSummariesForEntity(
            entityType: entityType.name,
            entityId: entityId,
          );

          return null; // No job ID for direct generation
        } catch (parseError) {
          // Failed to parse summary response
          state = state.copyWith(
            isGenerating: false,
            error: 'Failed to parse summary response',
            progress: 0.0,
          );
          rethrow;
        }
      }
    } catch (e) {
      // Summary generation failed
      state = state.copyWith(
        isGenerating: false,
        error: 'Failed to generate summary: ${e.toString()}',
        progress: 0.0,
      );
      return null;
    }
  }

  void reset() {
    state = const SummaryGenerationState();
  }
}

// Providers
final unifiedSummaryProvider = StateNotifierProvider<UnifiedSummaryNotifier, UnifiedSummaryState>(
  (ref) => UnifiedSummaryNotifier(ref),
);

final summaryGenerationUnifiedProvider = StateNotifierProvider<SummaryGenerationNotifier, SummaryGenerationState>(
  (ref) => SummaryGenerationNotifier(ref),
);

// Convenience providers for specific entity types
final projectSummariesUnifiedProvider = StateNotifierProvider.family<ProjectSummariesUnifiedNotifier, AsyncValue<List<UnifiedSummaryResponse>>, String>(
  (ref, projectId) => ProjectSummariesUnifiedNotifier(ref, projectId),
);

final programSummariesUnifiedProvider = StateNotifierProvider.family<ProgramSummariesUnifiedNotifier, AsyncValue<List<UnifiedSummaryResponse>>, String>(
  (ref, programId) => ProgramSummariesUnifiedNotifier(ref, programId),
);

final portfolioSummariesUnifiedProvider = StateNotifierProvider.family<PortfolioSummariesUnifiedNotifier, AsyncValue<List<UnifiedSummaryResponse>>, String>(
  (ref, portfolioId) => PortfolioSummariesUnifiedNotifier(ref, portfolioId),
);

// Entity-specific notifiers
class ProjectSummariesUnifiedNotifier extends StateNotifier<AsyncValue<List<UnifiedSummaryResponse>>> {
  final Ref ref;
  final String projectId;

  ProjectSummariesUnifiedNotifier(this.ref, this.projectId) : super(const AsyncValue.loading()) {
    fetchSummaries();
  }

  Future<void> fetchSummaries() async {
    if (!mounted) return;

    state = const AsyncValue.loading();

    try {
      final apiService = ref.read(apiServiceProvider);
      final client = apiService.client;

      final response = await client.listSummaries(
        entityType: 'project',
        entityId: projectId,
        limit: 100,
      );

      if (!mounted) return;

      final summaries = response
          .map((json) => UnifiedSummaryResponse.fromJson(json))
          .toList();

      // Sort by created_at descending
      summaries.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (!mounted) return;

      state = AsyncValue.data(summaries);
    } catch (e, stack) {
      if (mounted) {
        state = AsyncValue.error(e, stack);
      }
    }
  }
}

class ProgramSummariesUnifiedNotifier extends StateNotifier<AsyncValue<List<UnifiedSummaryResponse>>> {
  final Ref ref;
  final String programId;

  ProgramSummariesUnifiedNotifier(this.ref, this.programId) : super(const AsyncValue.loading()) {
    fetchSummaries();
  }

  Future<void> fetchSummaries() async {
    if (!mounted) return;

    state = const AsyncValue.loading();

    try {
      final apiService = ref.read(apiServiceProvider);
      final client = apiService.client;

      final response = await client.listSummaries(
        entityType: 'program',
        entityId: programId,
        limit: 100,
      );

      if (!mounted) return;

      final summaries = response
          .map((json) => UnifiedSummaryResponse.fromJson(json))
          .toList();

      // Sort by created_at descending
      summaries.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (!mounted) return;

      state = AsyncValue.data(summaries);
    } catch (e, stack) {
      if (mounted) {
        state = AsyncValue.error(e, stack);
      }
    }
  }
}

class PortfolioSummariesUnifiedNotifier extends StateNotifier<AsyncValue<List<UnifiedSummaryResponse>>> {
  final Ref ref;
  final String portfolioId;

  PortfolioSummariesUnifiedNotifier(this.ref, this.portfolioId) : super(const AsyncValue.loading()) {
    fetchSummaries();
  }

  Future<void> fetchSummaries() async {
    if (!mounted) return;

    state = const AsyncValue.loading();

    try {
      final apiService = ref.read(apiServiceProvider);
      final client = apiService.client;

      final response = await client.listSummaries(
        entityType: 'portfolio',
        entityId: portfolioId,
        limit: 100,
      );

      if (!mounted) return;

      final summaries = response
          .map((json) => UnifiedSummaryResponse.fromJson(json))
          .toList();

      // Sort by created_at descending
      summaries.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (!mounted) return;

      state = AsyncValue.data(summaries);
    } catch (e, stack) {
      if (mounted) {
        state = AsyncValue.error(e, stack);
      }
    }
  }
}