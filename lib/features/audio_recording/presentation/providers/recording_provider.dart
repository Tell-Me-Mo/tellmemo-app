import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:http/http.dart' as http;
import '../../domain/services/audio_recording_service.dart';
import '../../domain/services/transcription_service.dart';
import '../../../../features/jobs/presentation/providers/job_websocket_provider.dart';
import '../../../../features/meetings/presentation/providers/upload_provider.dart';
import '../../../../features/content/presentation/providers/processing_jobs_provider.dart';
import '../../../../core/services/firebase_analytics_service.dart';

part 'recording_provider.g.dart';

// Recording state model
class RecordingStateModel {
  final RecordingState state;
  final Duration duration;
  final String transcriptionText;
  final bool isProcessing;
  final String? currentRecordingPath;
  final String? sessionId;
  final String? errorMessage;
  final double amplitude;
  final String? contentId;  // Added to track uploaded content
  final bool isUploading;  // Added to track upload status
  
  RecordingStateModel({
    this.state = RecordingState.idle,
    this.duration = Duration.zero,
    this.transcriptionText = '',
    this.isProcessing = false,
    this.currentRecordingPath,
    this.sessionId,
    this.errorMessage,
    this.amplitude = 0.0,
    this.contentId,
    this.isUploading = false,
  });
  
  RecordingStateModel copyWith({
    RecordingState? state,
    Duration? duration,
    String? transcriptionText,
    bool? isProcessing,
    String? currentRecordingPath,
    String? sessionId,
    String? errorMessage,
    double? amplitude,
    String? contentId,
    bool? isUploading,
  }) {
    return RecordingStateModel(
      state: state ?? this.state,
      duration: duration ?? this.duration,
      transcriptionText: transcriptionText ?? this.transcriptionText,
      isProcessing: isProcessing ?? this.isProcessing,
      currentRecordingPath: currentRecordingPath ?? this.currentRecordingPath,
      sessionId: sessionId ?? this.sessionId,
      errorMessage: errorMessage ?? this.errorMessage,
      amplitude: amplitude ?? this.amplitude,
      contentId: contentId ?? this.contentId,
      isUploading: isUploading ?? this.isUploading,
    );
  }
}

// Audio recording service provider
@riverpod
AudioRecordingService audioRecordingService(Ref ref) {
  final service = AudioRecordingService();
  ref.onDispose(() => service.dispose());
  return service;
}

// Transcription service provider
@riverpod
TranscriptionService transcriptionService(Ref ref) {
  final service = TranscriptionService();
  ref.onDispose(() => service.dispose());
  return service;
}

// Main recording state provider
@riverpod
class RecordingNotifier extends _$RecordingNotifier {
  late AudioRecordingService _audioService;
  late TranscriptionService _transcriptionService;
  StreamSubscription? _amplitudeSubscription;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _stateSubscription;
  
  @override
  RecordingStateModel build() {
    _audioService = ref.watch(audioRecordingServiceProvider);
    _transcriptionService = ref.watch(transcriptionServiceProvider);
    
    // Set up listeners
    _setupListeners();
    
    return RecordingStateModel();
  }
  
  void _setupListeners() {
    // Listen to recording state changes
    _stateSubscription?.cancel();
    _stateSubscription = _audioService.stateStream.listen((newState) {
      state = state.copyWith(
        state: newState,
        currentRecordingPath: _audioService.currentRecordingPath,
      );
    });
    
    // Listen to duration updates
    _durationSubscription?.cancel();
    _durationSubscription = _audioService.durationStream.listen((duration) {
      state = state.copyWith(duration: duration);
    });
    
    // Listen to amplitude updates for visualization
    _amplitudeSubscription?.cancel();
    _amplitudeSubscription = _audioService.amplitudeStream.listen((amplitude) {
      state = state.copyWith(amplitude: amplitude);
    });
  }
  
  // Start recording (audio only, transcription happens after stopping)
  Future<void> startRecording({
    required String projectId,
    String? meetingTitle,
  }) async {
    try {
      print('[RecordingProvider] Starting recording for project: $projectId');
      
      // Clear previous transcription and errors
      state = state.copyWith(
        transcriptionText: '',
        errorMessage: null,
        isProcessing: false,
      );
      
      // Check transcription service health (optional)
      print('[RecordingProvider] Checking transcription service health...');
      final serviceHealthy = await _transcriptionService.checkServiceHealth();
      if (!serviceHealthy) {
        print('[RecordingProvider] Warning: Transcription service may be unavailable');
        // Continue anyway - transcription will be attempted after recording
      } else {
        print('[RecordingProvider] Transcription service is healthy');
      }
      
      // Start audio recording to file
      print('[RecordingProvider] Starting audio recording...');
      final recordingStarted = await _audioService.startRecording(
        projectId: projectId,
        meetingTitle: meetingTitle,
      );
      
      if (!recordingStarted) {
        print('[RecordingProvider] Failed to start recording');
        state = state.copyWith(
          errorMessage: 'Failed to start recording. Please check microphone permissions.',
          state: RecordingState.error,
        );
        return;
      }
      print('[RecordingProvider] Recording started successfully');
      
      // Generate session ID for this recording
      final sessionId = '${projectId}_${DateTime.now().millisecondsSinceEpoch}';
      state = state.copyWith(sessionId: sessionId);

      // Log recording started analytics
      try {
        await FirebaseAnalyticsService().logRecordingStarted(
          hasProjectSelected: projectId.isNotEmpty,
          projectMode: meetingTitle != null ? 'with_title' : 'without_title',
        );
      } catch (e) {
        // Silently fail analytics
      }

    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Recording error: $e',
        state: RecordingState.error,
      );
    }
  }
  
  // Pause recording
  Future<void> pauseRecording() async {
    await _audioService.pauseRecording();

    // Log recording paused analytics
    try {
      await FirebaseAnalyticsService().logRecordingPaused(
        durationSoFar: state.duration.inSeconds,
      );
    } catch (e) {
      // Silently fail analytics
    }
  }

  // Resume recording
  Future<void> resumeRecording() async {
    await _audioService.resumeRecording();

    // Log recording resumed analytics
    try {
      await FirebaseAnalyticsService().logRecordingResumed();
    } catch (e) {
      // Silently fail analytics
    }
  }
  
  // Stop recording and upload using the same flow as file upload
  Future<Map<String, dynamic>?> stopRecording({
    String? projectId,
    String? language,
    String? meetingTitle,
  }) async {
    try {
      // Stop audio recording and get file path
      final filePath = await _audioService.stopRecording();

      if (filePath == null) {
        state = state.copyWith(
          errorMessage: 'No recording file found',
          state: RecordingState.error,
        );
        return null;
      }

      // Update state to show processing
      state = state.copyWith(
        isProcessing: true,
        state: RecordingState.processing,
      );

      // Use the same upload flow as file uploads
      try {
        print('[RecordingProvider] Uploading audio file via upload provider: $filePath');

        // Get the upload provider to use the exact same upload flow
        final uploadProvider = ref.read(uploadContentProvider.notifier);

        // Prepare file data for upload
        Uint8List? fileBytes;
        String fileName = 'recording_${DateTime.now().millisecondsSinceEpoch}.webm';

        if (kIsWeb) {
          // For web, fetch the blob data
          if (filePath.startsWith('blob:') || filePath.startsWith('data:')) {
            final response = await http.get(Uri.parse(filePath));
            if (response.statusCode == 200) {
              fileBytes = response.bodyBytes;
            }
          }
        } else {
          // For native platforms, the file path is valid
          fileName = filePath.split('/').last;
        }

        // Use the uploadAudioFile method - exact same as file upload
        // Check if we should use AI matching (when projectId is 'auto')
        final useAiMatching = projectId == 'auto';

        final response = await uploadProvider.uploadAudioFile(
          projectId: projectId ?? state.sessionId?.split('_')[0] ?? '',
          contentType: 'meeting',
          title: meetingTitle ?? 'Recording ${DateTime.now().toIso8601String()}',
          date: DateTime.now().toIso8601String().split('T')[0],
          filePath: kIsWeb ? null : filePath,
          fileBytes: fileBytes,
          fileName: fileName,
          useAiMatching: useAiMatching,
        );

        print('[RecordingProvider] Upload response: $response');

        if (response != null) {
          // Extract job_id, content_id, and actual project_id from response
          final jobId = response['job_id'] as String?;
          final contentId = response['content_id'] as String?;
          // When using AI matching, backend returns the actual project UUID
          final actualProjectId = response['project_id'] as String? ?? projectId;

          // Add job to processing tracker using the actual project ID
          if (jobId != null && actualProjectId != null) {
            await ref.read(processingJobsProvider.notifier).addJob(
              jobId: jobId,
              contentId: contentId,
              projectId: actualProjectId,  // Use actual project ID, not "auto"
            );
            print('[RecordingProvider] Added job to processing tracker: $jobId for project: $actualProjectId');
          }

          // Update state
          state = state.copyWith(
            contentId: contentId,
            isProcessing: false,
            state: RecordingState.idle,
          );

          // Log recording stopped and uploaded analytics
          try {
            await FirebaseAnalyticsService().logRecordingStopped(
              totalDuration: state.duration.inSeconds,
              fileSize: fileBytes?.length,
            );

            if (actualProjectId != null && contentId != null) {
              await FirebaseAnalyticsService().logRecordingUploaded(
                projectId: actualProjectId,  // Use actual project ID
                fileSize: fileBytes?.length ?? 0,
                duration: state.duration.inSeconds,
              );
            }
          } catch (e) {
            // Silently fail analytics
          }

          // Return the response data with actual project ID
          return {
            'filePath': filePath,
            'contentId': contentId,
            'jobId': jobId,
            'projectId': actualProjectId,  // Include actual project ID
            'transcription': '', // Will be available via job tracking
          };
        } else {
          throw Exception('Upload failed - no response');
        }
      } catch (e) {
        state = state.copyWith(
          errorMessage: 'Upload failed: $e',
          isProcessing: false,
          state: RecordingState.error,
        );
        return {'filePath': filePath}; // Return path even if upload fails
      }
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Error stopping recording: $e',
        isProcessing: false,
        state: RecordingState.error,
      );
      return null;
    }
  }
  
  // Cancel recording without saving
  Future<void> cancelRecording() async {
    // Cancel any ongoing transcription if session exists
    if (state.sessionId != null) {
      await _transcriptionService.cancelTranscription(state.sessionId!);
    }

    // Cancel recording and delete file
    await _audioService.cancelRecording();

    state = state.copyWith(
      state: RecordingState.idle,
      transcriptionText: '',
      duration: Duration.zero,
      isProcessing: false,
      sessionId: null,
      errorMessage: null,
      currentRecordingPath: null,
    );
  }
  
  // Retry transcription with existing file
  Future<void> retryTranscription({
    required String filePath,
    String? projectId,
    String? language,
  }) async {
    state = state.copyWith(
      isProcessing: true,
      errorMessage: null,
    );
    
    try {
      final result = await _transcriptionService.transcribeAudioFile(
        audioFilePath: filePath,
        projectId: projectId,
        language: language,
      );
      
      state = state.copyWith(
        transcriptionText: result.text,
        isProcessing: false,
        state: RecordingState.idle,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Retry failed: $e',
        isProcessing: false,
        state: RecordingState.error,
      );
    }
  }
  
  // Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
  
  // Clear transcription and content ID
  void clearTranscription() {
    state = state.copyWith(
      transcriptionText: '',
      contentId: null,
    );
  }
  
  // Get supported languages
  Future<List<String>> getSupportedLanguages() async {
    return await _transcriptionService.getSupportedLanguages();
  }
  
  // Clean up subscriptions
  void disposeSubscriptions() {
    _amplitudeSubscription?.cancel();
    _durationSubscription?.cancel();
    _stateSubscription?.cancel();
  }
}