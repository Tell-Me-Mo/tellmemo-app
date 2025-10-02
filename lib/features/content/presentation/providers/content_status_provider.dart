import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../core/network/api_service.dart';
import '../../data/models/content_status_model.dart';
import '../../../summaries/presentation/providers/summary_provider.dart';

part 'content_status_provider.freezed.dart';

@freezed
class ContentStatusState with _$ContentStatusState {
  const factory ContentStatusState({
    @Default(false) bool isPolling,
    @Default(null) ContentStatusModel? status,
    @Default(null) String? error,
    @Default(null) Timer? pollingTimer,
  }) = _ContentStatusState;
}

class ContentStatusNotifier extends StateNotifier<ContentStatusState> {
  final Ref ref;
  Timer? _pollingTimer;
  
  ContentStatusNotifier(this.ref) : super(const ContentStatusState());

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }

  // Start polling for content processing status
  Future<void> startPolling(String projectId, String contentId) async {
    // Stop any existing polling
    stopPolling();
    
    state = state.copyWith(isPolling: true, error: null);
    
    // Initial status check
    await _checkStatus(projectId, contentId);
    
    // Start periodic polling if still processing or waiting for summary
    if (state.status != null) {
      _pollingTimer = Timer.periodic(
        const Duration(seconds: 2), // Poll every 2 seconds
        (_) async {
          await _checkStatus(projectId, contentId);
          
          // Stop polling if:
          // 1. Failed
          // 2. Completed AND summary is generated
          if (state.status != null) {
            if (state.status!.isFailed) {
              stopPolling();
            } else if (state.status!.isCompleted && state.status!.summaryGenerated) {
              stopPolling();
              // Notify other providers about completion
              _onProcessingComplete(projectId, contentId);
            }
            // Keep polling if completed but no summary yet
          }
        },
      );
    }
  }

  // Check status once
  Future<void> checkStatus(String projectId, String contentId) async {
    state = state.copyWith(error: null);
    await _checkStatus(projectId, contentId);
  }

  // Internal status check
  Future<void> _checkStatus(String projectId, String contentId) async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final client = apiService.client;
      
      // Make API call to check content status
      // For now, we'll simulate this since the endpoint might not exist yet
      final response = await _getContentStatus(client, projectId, contentId);
      
      if (response != null) {
        final status = ContentStatusModel.fromJson(response);
        
        state = state.copyWith(status: status);
      }
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to check status: ${e.toString()}',
      );
    }
  }

  // Simulate getting content status - replace with actual API call
  Future<Map<String, dynamic>?> _getContentStatus(
    dynamic client,
    String projectId,
    String contentId,
  ) async {
    try {
      // Try to get content details which should include processing status
      final response = await client.getContent(projectId, contentId);
      
      if (response != null) {
        // Map the response to our status model format
        // Determine status based on processed_at and summary_generated fields
        final isProcessed = response['processed_at'] != null;
        final hasSummary = response['summary_generated'] == true;
        String statusStr = 'processing';
        
        if (hasSummary) {
          statusStr = 'completed';
        } else if (isProcessed) {
          statusStr = 'completed';  // Processed but no summary yet
        }
        
        
        return {
          'content_id': contentId,
          'project_id': projectId,
          'status': statusStr,
          'processing_message': response['processing_message'],
          'progress_percentage': response['progress_percentage'] ?? 
                                (response['chunk_count'] != null && response['chunk_count'] > 0 ? 100 : 50),
          'chunk_count': response['chunk_count'] ?? 0,
          'summary_generated': hasSummary,
          'summary_id': response['summary_id'],
          'error_message': response['processing_error'],
          'created_at': response['uploaded_at'] ?? DateTime.now().toIso8601String(),
          'updated_at': response['processed_at'] ?? DateTime.now().toIso8601String(),
        };
      }
    } catch (e) {
      // If the endpoint doesn't exist, simulate based on time
      final now = DateTime.now();
      final createdAt = now.subtract(const Duration(seconds: 10));
      final isCompleted = now.difference(createdAt).inSeconds > 15;
      
      return {
        'content_id': contentId,
        'project_id': projectId,
        'status': isCompleted ? 'completed' : 'processing',
        'processing_message': isCompleted ? 'Summary generated successfully' : 'Processing content...',
        'progress_percentage': isCompleted ? 100 : 50,
        'chunk_count': isCompleted ? 2 : 0,
        'summary_generated': isCompleted,
        'created_at': createdAt.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };
    }
    
    return null;
  }

  // Stop polling
  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    state = state.copyWith(isPolling: false);
  }

  // Handle processing completion
  void _onProcessingComplete(String projectId, String contentId) {
    // Invalidate related providers to trigger refresh
    // This will cause the summaries to reload
    try {
      // Import and use the summary provider
      ref.invalidate(projectSummariesProvider(projectId));
    } catch (e) {
      // Provider might not be available
    }
  }

  // Clear status
  void clearStatus() {
    stopPolling();
    state = const ContentStatusState();
  }
}

// Provider
final contentStatusProvider = StateNotifierProvider<ContentStatusNotifier, ContentStatusState>(
  (ref) => ContentStatusNotifier(ref),
);

// Family provider for multiple content items
final contentStatusFamilyProvider = StateNotifierProvider.family<
    ContentStatusNotifier, ContentStatusState, String>(
  (ref, contentId) => ContentStatusNotifier(ref),
);

