import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../core/network/api_service.dart';
import '../../data/models/summary_model.dart';

part 'summary_provider.freezed.dart';

// State for summary list
@freezed
class SummaryListState with _$SummaryListState {
  const factory SummaryListState({
    @Default(false) bool isLoading,
    @Default([]) List<SummaryModel> summaries,
    @Default(null) String? error,
    @Default(null) String? selectedProjectId,
    @Default(null) SummaryType? filterType,
  }) = _SummaryListState;
}

// State for single summary detail
@freezed
class SummaryDetailState with _$SummaryDetailState {
  const factory SummaryDetailState({
    @Default(false) bool isLoading,
    @Default(null) SummaryModel? summary,
    @Default(null) String? error,
    @Default(false) bool isExporting,
  }) = _SummaryDetailState;
}

// State for summary generation
@freezed
class SummaryGenerationState with _$SummaryGenerationState {
  const factory SummaryGenerationState({
    @Default(false) bool isGenerating,
    @Default(null) SummaryModel? generatedSummary,
    @Default(null) String? error,
    @Default(0.0) double progress,
  }) = _SummaryGenerationState;
}

// Provider for summary list
class SummaryListNotifier extends StateNotifier<SummaryListState> {
  final Ref ref;
  
  SummaryListNotifier(this.ref) : super(const SummaryListState());

  Future<void> loadSummaries(String projectId, {SummaryType? filterType}) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      selectedProjectId: projectId,
      filterType: filterType,
    );

    try {
      final apiService = ref.read(apiServiceProvider);
      final client = apiService.client;
      
      // Use unified endpoint to list summaries
      final response = await client.listSummaries(
        entityType: 'project',
        entityId: projectId,
        summaryType: filterType?.name.toLowerCase(),
      );

      final summaries = response
          .map((json) => SummaryModel.fromJson(json))
          .toList();

      state = state.copyWith(
        isLoading: false,
        summaries: summaries,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load summaries: ${e.toString()}',
      );
    }
  }

  void setFilter(SummaryType? type) {
    if (state.selectedProjectId != null) {
      loadSummaries(state.selectedProjectId!, filterType: type);
    }
  }

  void clearSummaries() {
    state = const SummaryListState();
  }
}

// Provider for summary detail
class SummaryDetailNotifier extends StateNotifier<SummaryDetailState> {
  final Ref ref;
  
  SummaryDetailNotifier(this.ref) : super(const SummaryDetailState());

  Future<void> loadSummary(String? projectId, String summaryId) async {
    // Check if notifier is still mounted before updating state
    if (!mounted) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final apiService = ref.read(apiServiceProvider);
      final client = apiService.client;

      // Use the new endpoint that doesn't require projectId
      final response = await client.getSummaryById(summaryId);

      // Check again after async operation
      if (!mounted) return;

      // DEBUG: Log the raw API response
      print('DEBUG API Response: ${response}');
      if (response is Map<String, dynamic>) {
        print('DEBUG API Response has lessons_learned key: ${response.containsKey('lessons_learned')}');
        print('DEBUG API Response lessons_learned value: ${response['lessons_learned']}');
        print('DEBUG API Response has next_meeting_agenda key: ${response.containsKey('next_meeting_agenda')}');
        print('DEBUG API Response next_meeting_agenda value: ${response['next_meeting_agenda']}');
      }

      final summary = SummaryModel.fromJson(response as Map<String, dynamic>);

      state = state.copyWith(
        isLoading: false,
        summary: summary,
      );
    } catch (e) {
      // Only update state if still mounted
      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to load summary: ${e.toString()}',
        );
      }
    }
  }

  Future<void> exportSummary(ExportFormat format) async {
    if (state.summary == null) return;

    state = state.copyWith(isExporting: true);

    try {
      // Export logic here - could be PDF, email, clipboard
      await Future.delayed(const Duration(seconds: 1)); // Simulate export
      
      // For now, just copy to clipboard
      // Would implement actual export logic based on format
      
      state = state.copyWith(isExporting: false);
    } catch (e) {
      state = state.copyWith(
        isExporting: false,
        error: 'Failed to export: ${e.toString()}',
      );
    }
  }

  void clearSummary() {
    state = const SummaryDetailState();
  }
}

// Provider for summary generation
class SummaryGenerationNotifier extends StateNotifier<SummaryGenerationState> {
  final Ref ref;
  
  SummaryGenerationNotifier(this.ref) : super(const SummaryGenerationState());

  Future<String?> generateSummary({
    required String projectId,
    required SummaryType type,
    String? contentId,
    DateTime? startDate,
    DateTime? endDate,
    String format = 'general',
  }) async {
    state = state.copyWith(
      isGenerating: true,
      error: null,
      progress: 0.1,
    );

    try {
      final apiService = ref.read(apiServiceProvider);
      final client = apiService.client;

      state = state.copyWith(progress: 0.3);

      final request = SummaryRequest(
        type: type.name.toLowerCase(),
        contentId: contentId,
        dateRangeStart: startDate,
        dateRangeEnd: endDate,
        createdBy: 'User', // Would get from user context
        format: format,
      );

      state = state.copyWith(progress: 0.5);

      // Use the new unified summary endpoint
      final unifiedRequest = {
        'entity_type': 'project',
        'entity_id': projectId,
        'summary_type': request.type,
        'content_id': request.contentId,
        'date_range_start': request.dateRangeStart?.toIso8601String(),
        'date_range_end': request.dateRangeEnd?.toIso8601String(),
        'format': request.format,
        'created_by': request.createdBy,
      };

      final response = await client.generateUnifiedSummary(unifiedRequest);

      // Response received successfully

      // Manual summaries (project/program/portfolio) always return job_id
      if (response is Map<String, dynamic> && response.containsKey('job_id')) {
        // Job-based generation - return job ID
        final jobId = response['job_id'] as String;
        
        state = state.copyWith(
          isGenerating: false,
          progress: 1.0,
        );
        
        return jobId; // Return job ID for tracking
      } else {
        // Direct generation - parse unified summary response
        state = state.copyWith(progress: 0.8);

        try {
          print('[DEBUG] Provider: Response received from API');
          print('[DEBUG] Provider: Response type: ${response.runtimeType}');
          print('[DEBUG] Provider: Response: $response');

          // The response is a UnifiedSummaryResponse, not a SummaryModel
          // We need to extract the summary_id and create a minimal SummaryModel
          final responseMap = response as Map<String, dynamic>;
          final summaryId = responseMap['summary_id'] as String?;
          print('[DEBUG] Provider: Extracted summary_id: $summaryId');

          if (summaryId != null) {
            // Create a SummaryModel with the ID so navigation can work
            final summary = SummaryModel(
              id: summaryId,
              subject: responseMap['subject'] ?? 'Summary',
              body: responseMap['body'] ?? '',
              summaryType: type,
              createdAt: DateTime.now(),
              format: format,
              keyPoints: (responseMap['key_points'] as List<dynamic>?)?.cast<String>(),
            );

            print('[DEBUG] Provider: Created SummaryModel with id: ${summary.id}');

            state = state.copyWith(
              isGenerating: false,
              generatedSummary: summary,
              progress: 1.0,
            );
            print('[DEBUG] Provider: State updated with generated summary');
            // State updated successfully with summary ID: $summaryId
          } else {
            print('[DEBUG] Provider: No summary_id in response');
            throw Exception('No summary ID in response');
          }
        } catch (parseError) {
          print('[DEBUG] Provider: Error parsing response: $parseError');
          // Error parsing summary response
          // Try to at least clear the generating state
          state = state.copyWith(
            isGenerating: false,
            error: 'Failed to parse summary response: $parseError',
            progress: 0.0,
          );
          rethrow;
        }
      }

      // Refresh the summary list
      ref.read(summaryListProvider.notifier).loadSummaries(projectId);
      
      return null; // No job ID for direct generation
    } catch (e) {
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

enum ExportFormat { pdf, email, clipboard }

// Providers
final summaryListProvider = StateNotifierProvider<SummaryListNotifier, SummaryListState>(
  (ref) => SummaryListNotifier(ref),
);

final summaryDetailProvider = StateNotifierProvider<SummaryDetailNotifier, SummaryDetailState>(
  (ref) => SummaryDetailNotifier(ref),
);

final summaryGenerationProvider = StateNotifierProvider<SummaryGenerationNotifier, SummaryGenerationState>(
  (ref) => SummaryGenerationNotifier(ref),
);

// Selected summary provider for navigation
final selectedSummaryProvider = StateProvider<String?>((ref) => null);

// Provider for project-specific summaries
final projectSummariesProvider = StateNotifierProvider.family<ProjectSummariesNotifier, AsyncValue<List<SummaryModel>>, String>(
  (ref, projectId) => ProjectSummariesNotifier(ref, projectId),
);

class ProjectSummariesNotifier extends StateNotifier<AsyncValue<List<SummaryModel>>> {
  final Ref ref;
  final String projectId;
  
  ProjectSummariesNotifier(this.ref, this.projectId) : super(const AsyncValue.loading()) {
    fetchSummaries();
  }

  Future<void> fetchSummaries() async {
    // Check if notifier is still mounted
    if (!mounted) return;
    
    state = const AsyncValue.loading();
    
    try {
      final apiService = ref.read(apiServiceProvider);
      final client = apiService.client;
      
      // Use unified endpoint to list summaries
      final response = await client.listSummaries(
        entityType: 'project',
        entityId: projectId,
      );

      // Check again after async operation
      if (!mounted) return;
      
      final summaries = response
          .map((json) {
            // Ensure project_id is present
            if (json['project_id'] == null) {
              json['project_id'] = projectId;
            }
            // Fix summary_type if needed
            if (json['summary_type'] != null) {
              final summaryType = json['summary_type'].toString().toUpperCase();
              if (summaryType != 'MEETING' && summaryType != 'PROJECT') {
                // Default to MEETING if invalid
                json['summary_type'] = 'MEETING';
              } else {
                json['summary_type'] = summaryType;
              }
            } else {
              // Default to MEETING if null
              json['summary_type'] = 'MEETING';
            }
            return SummaryModel.fromJson(json);
          })
          .toList();
      
      // Sort by created_at descending to show latest first
      summaries.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Final check before setting state
      if (!mounted) return;
      
      state = AsyncValue.data(summaries);
    } catch (e, stack) {
      // Only set error state if still mounted
      if (mounted) {
        state = AsyncValue.error(e, stack);
      }
    }
  }
}