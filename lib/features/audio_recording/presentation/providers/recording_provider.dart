import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:http/http.dart' as http;
import '../../domain/services/audio_recording_service.dart';
import '../../domain/services/audio_streaming_service.dart';
import '../../domain/services/transcription_service.dart';
import '../../../../features/meetings/presentation/providers/upload_provider.dart';
import '../../../../features/content/presentation/providers/processing_jobs_provider.dart';
import '../../../../features/live_insights/domain/services/live_insights_websocket_service.dart';
import '../../../../features/live_insights/domain/models/live_insight_model.dart';
import '../../../../features/live_insights/presentation/providers/live_insights_settings_provider.dart';
import '../../../../core/services/firebase_analytics_service.dart';
import '../../../../core/utils/error_utils.dart';

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
  final String? contentId; // Added to track uploaded content
  final bool isUploading; // Added to track upload status
  final bool showDurationWarning; // Added to track 90-minute warning
  final bool liveInsightsEnabled; // Added for live insights feature
  final String? liveInsightsSessionId; // Added to track live insights session
  final List<LiveInsightModel> liveInsights; // Added to store live insights

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
    this.showDurationWarning = false,
    this.liveInsightsEnabled = false,
    this.liveInsightsSessionId,
    this.liveInsights = const [],
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
    bool? showDurationWarning,
    bool? liveInsightsEnabled,
    String? liveInsightsSessionId,
    List<LiveInsightModel>? liveInsights,
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
      showDurationWarning: showDurationWarning ?? this.showDurationWarning,
      liveInsightsEnabled: liveInsightsEnabled ?? this.liveInsightsEnabled,
      liveInsightsSessionId: liveInsightsSessionId ?? this.liveInsightsSessionId,
      liveInsights: liveInsights ?? this.liveInsights,
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
  StreamSubscription? _warningSubscription;

  // Live insights support
  LiveInsightsWebSocketService? _liveInsightsService;
  AudioStreamingService? _audioStreamingService;
  StreamSubscription? _audioChunkSubscription;
  StreamSubscription? _liveInsightsSubscription;
  StreamSubscription? _liveTranscriptsSubscription;

  // Getter to expose WebSocket service for UI components
  LiveInsightsWebSocketService? get liveInsightsService => _liveInsightsService;

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

    // Listen to warning notifications
    _warningSubscription?.cancel();
    _warningSubscription = _audioService.warningStream.listen((showWarning) {
      state = state.copyWith(showDurationWarning: showWarning);
    });
  }

  // Start recording (audio only, transcription happens after stopping)
  Future<void> startRecording({
    required String projectId,
    String? meetingTitle,
    bool enableLiveInsights = false,
    String? authToken,
  }) async {
    try {
      print('[RecordingProvider] Starting recording for project: $projectId');

      // Clear previous transcription, errors, and warning
      state = state.copyWith(
        transcriptionText: '',
        errorMessage: null,
        isProcessing: false,
        showDurationWarning: false,
      );

      // Start audio recording to file
      print('[RecordingProvider] Starting audio recording...');
      final recordingStarted = await _audioService.startRecording(
        projectId: projectId,
        meetingTitle: meetingTitle,
      );

      if (!recordingStarted) {
        print('[RecordingProvider] Failed to start recording');
        state = state.copyWith(
          errorMessage:
              'Failed to start recording. Please check microphone permissions.',
          state: RecordingState.error,
        );
        return;
      }
      print('[RecordingProvider] Recording started successfully');

      // Generate session ID for this recording
      final sessionId = '${projectId}_${DateTime.now().millisecondsSinceEpoch}';
      state = state.copyWith(sessionId: sessionId);

      // Initialize live insights if enabled
      if (enableLiveInsights && authToken != null) {
        try {
          print('[RecordingProvider] Initializing live insights...');
          await _initializeLiveInsights(projectId, authToken);
          print('[RecordingProvider] Live insights initialized');
        } catch (e) {
          print('[RecordingProvider] Failed to initialize live insights: $e');
          // Don't fail the recording if live insights fail
          state = state.copyWith(
            liveInsightsEnabled: false,
            errorMessage: 'Live insights unavailable: $e',
          );
        }
      }

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
      // Stop live insights if enabled
      if (state.liveInsightsEnabled) {
        await _stopLiveInsights();
      }

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
        print(
          '[RecordingProvider] Uploading audio file via upload provider: $filePath',
        );

        // Get the upload provider to use the exact same upload flow
        final uploadProvider = ref.read(uploadContentProvider.notifier);

        // Prepare file data for upload
        Uint8List? fileBytes;
        String fileName =
            'recording_${DateTime.now().millisecondsSinceEpoch}.webm';

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
          title:
              meetingTitle ?? 'Recording ${DateTime.now().toIso8601String()}',
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
          final actualProjectId =
              response['project_id'] as String? ?? projectId;

          // Add job to processing tracker using the actual project ID
          if (jobId != null && actualProjectId != null) {
            await ref
                .read(processingJobsProvider.notifier)
                .addJob(
                  jobId: jobId,
                  contentId: contentId,
                  projectId:
                      actualProjectId, // Use actual project ID, not "auto"
                );
            print(
              '[RecordingProvider] Added job to processing tracker: $jobId for project: $actualProjectId',
            );
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
                projectId: actualProjectId, // Use actual project ID
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
            'projectId': actualProjectId, // Include actual project ID
            'transcription': '', // Will be available via job tracking
          };
        } else {
          throw Exception('Upload failed - no response');
        }
      } catch (e) {
        // Extract user-friendly error message
        final errorMessage = ErrorUtils.getUserFriendlyMessage(e);

        state = state.copyWith(
          errorMessage: errorMessage,
          isProcessing: false,
          state: RecordingState.error,
        );
        return {'filePath': filePath}; // Return path even if upload fails
      }
    } catch (e) {
      // Extract user-friendly error message
      final errorMessage = ErrorUtils.getUserFriendlyMessage(e);

      state = state.copyWith(
        errorMessage: errorMessage,
        isProcessing: false,
        state: RecordingState.error,
      );
      return null;
    }
  }

  // Cancel recording without saving
  Future<void> cancelRecording() async {
    print('[RecordingProvider] Cancelling recording...');

    // Stop live insights if enabled
    if (state.liveInsightsEnabled) {
      print('[RecordingProvider] Stopping live insights...');
      await _stopLiveInsights();
    }

    // Cancel recording and delete file
    print('[RecordingProvider] Cancelling audio recording...');
    await _audioService.cancelRecording();

    // Reset state completely, including live insights
    state = state.copyWith(
      state: RecordingState.idle,
      transcriptionText: '',
      duration: Duration.zero,
      isProcessing: false,
      sessionId: null,
      errorMessage: null,
      currentRecordingPath: null,
      liveInsightsEnabled: false,
      liveInsightsSessionId: null,
      liveInsights: [],
    );

    print('[RecordingProvider] Recording cancelled successfully');
  }

  // Retry transcription with existing file
  Future<void> retryTranscription({
    required String filePath,
    String? projectId,
    String? language,
  }) async {
    state = state.copyWith(isProcessing: true, errorMessage: null);

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
    state = state.copyWith(transcriptionText: '', contentId: null);
  }

  // Get supported languages
  Future<List<String>> getSupportedLanguages() async {
    return await _transcriptionService.getSupportedLanguages();
  }

  // Initialize live insights WebSocket connection
  Future<void> _initializeLiveInsights(String projectId, String authToken) async {
    // Create live insights service
    _liveInsightsService = LiveInsightsWebSocketService();

    // Get user's enabled insight types from settings
    final settings = ref.read(liveInsightsSettingsSyncProvider);
    final enabledTypes = settings.enabledInsightTypes
        .map((type) => type.name) // Convert enum to string (e.g., "actionItem")
        .toList();

    print('🔍 [RecordingProvider] Connecting with enabled insight types: $enabledTypes');

    // Connect to WebSocket with auth token and insight type preferences
    await _liveInsightsService!.connect(
      projectId,
      token: authToken,
      enabledInsightTypes: enabledTypes,
    );

    // Listen to insights stream
    _liveInsightsSubscription = _liveInsightsService!.insightsStream.listen(
      (result) {
        print('🔍 [RecordingProvider] ========================================');
        print('🔍 [RecordingProvider] Received ${result.insights.length} new insights from chunk ${result.chunkIndex}');

        // Log each insight for debugging
        for (var insight in result.insights) {
          final content = insight.content ?? '';
          final preview = content.length > 50 ? content.substring(0, 50) : content;
          print('🔍 [RecordingProvider]   - ${insight.type}: $preview...');
        }

        // Filter insights based on user settings
        final settings = ref.read(liveInsightsSettingsSyncProvider);
        final filteredInsights = result.insights.where((insight) {
          return settings.shouldShowInsight(insight);
        }).toList();

        print('🔍 [RecordingProvider] Filtered ${result.insights.length} insights to ${filteredInsights.length} based on settings');

        // Add filtered insights to the list
        final updatedInsights = List<LiveInsightModel>.from(state.liveInsights);
        updatedInsights.addAll(filteredInsights);

        print('🔍 [RecordingProvider] Total insights now: ${updatedInsights.length} (was: ${state.liveInsights.length})');
        print('🔍 [RecordingProvider] Updating state...');

        state = state.copyWith(liveInsights: updatedInsights);

        print('🔍 [RecordingProvider] State updated! New state has ${state.liveInsights.length} insights');
        print('🔍 [RecordingProvider] ========================================');
      },
      onError: (error) {
        print('❌ [RecordingProvider] Live insights error: $error');
      },
    );

    // Listen to transcript stream (optional - for displaying live transcripts)
    _liveTranscriptsSubscription = _liveInsightsService!.transcriptsStream.listen(
      (transcript) {
        print('[RecordingProvider] Live transcript: ${transcript.text}');
      },
    );

    // Initialize audio streaming service
    _audioStreamingService = AudioStreamingService();
    final initialized = await _audioStreamingService!.initialize();

    if (!initialized) {
      throw Exception('Failed to initialize audio streaming service');
    }

    // Start streaming audio
    final started = await _audioStreamingService!.startStreaming();

    if (!started) {
      throw Exception('Failed to start audio streaming');
    }

    // Listen to audio chunks and send to WebSocket
    _audioChunkSubscription = _audioStreamingService!.audioChunkStream.listen(
      (audioChunk) async {
        await _sendAudioChunk(audioChunk);
      },
      onError: (error) {
        print('[RecordingProvider] Audio chunk stream error: $error');
      },
    );

    // Update state
    state = state.copyWith(
      liveInsightsEnabled: true,
      liveInsightsSessionId: _liveInsightsService!.sessionId,
    );

    print('[RecordingProvider] Live insights with real-time audio streaming initialized');
  }

  // Send audio chunk to live insights WebSocket
  Future<void> _sendAudioChunk(Uint8List audioChunk) async {
    if (_liveInsightsService == null || !_liveInsightsService!.isConnected) {
      return;
    }

    try {
      // Convert audio chunk to base64
      final base64Audio = base64Encode(audioChunk);

      // Calculate duration (10 seconds for full chunks, less for final chunk)
      final duration = audioChunk.length / (AudioStreamingService.sampleRate * 2); // 2 bytes per sample (16-bit PCM)

      // Send to WebSocket
      await _liveInsightsService!.sendAudioChunk(
        audioData: base64Audio,
        duration: duration,
        speaker: null,
      );

      print('[RecordingProvider] Sent audio chunk: ${audioChunk.length} bytes, ~${duration.toStringAsFixed(1)}s duration');
    } catch (e) {
      print('[RecordingProvider] Error sending audio chunk: $e');
    }
  }

  // Stop live insights session
  Future<void> _stopLiveInsights() async {
    print('[RecordingProvider] Stopping live insights...');

    // CRITICAL ORDER FOR CLEAN CANCELLATION:
    // 1. Stop audio streaming FIRST (stops new chunks from being sent)
    // 2. Disconnect WebSocket SECOND (closes connection gracefully)
    // 3. Cancel subscriptions LAST (cleanup listeners)

    // 1. Stop and dispose audio streaming service FIRST
    if (_audioStreamingService != null) {
      try {
        print('[RecordingProvider] Stopping audio streaming service...');
        if (_audioStreamingService!.isRecording) {
          await _audioStreamingService!.stopStreaming();
        }
        await _audioStreamingService!.dispose();
        print('[RecordingProvider] Audio streaming service disposed');
      } catch (e) {
        print('[RecordingProvider] Error stopping audio streaming: $e');
      }
      _audioStreamingService = null;
    }

    // 2. Stop live insights WebSocket SECOND (no more chunks will be sent)
    if (_liveInsightsService != null) {
      try {
        print('[RecordingProvider] Disconnecting live insights WebSocket...');
        // Don't call endSession() on cancellation - just disconnect immediately
        await _liveInsightsService!.disconnect();
        print('[RecordingProvider] Live insights WebSocket disconnected');
      } catch (e) {
        print('[RecordingProvider] Error disconnecting WebSocket: $e');
      }
      _liveInsightsService = null;
    }

    // 3. Cancel all subscriptions LAST (after everything is stopped)
    print('[RecordingProvider] Cancelling subscriptions...');
    await _audioChunkSubscription?.cancel();
    await _liveInsightsSubscription?.cancel();
    await _liveTranscriptsSubscription?.cancel();
    _audioChunkSubscription = null;
    _liveInsightsSubscription = null;
    _liveTranscriptsSubscription = null;

    state = state.copyWith(
      liveInsightsEnabled: false,
      liveInsightsSessionId: null,
    );

    print('[RecordingProvider] Live insights stopped successfully');
  }

  // Clean up subscriptions
  void disposeSubscriptions() {
    _amplitudeSubscription?.cancel();
    _durationSubscription?.cancel();
    _stateSubscription?.cancel();
    _warningSubscription?.cancel();
    _audioChunkSubscription?.cancel();
    _liveInsightsSubscription?.cancel();
    _liveTranscriptsSubscription?.cancel();
    _liveInsightsService?.dispose();
    _audioStreamingService?.dispose();
  }
}
