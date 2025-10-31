import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:http/http.dart' as http;
import 'package:sentry_flutter/sentry_flutter.dart';
import '../../domain/services/audio_recording_service.dart';
import '../../domain/services/transcription_service.dart';
import '../../domain/services/live_audio_streaming_service.dart';
import '../../domain/services/live_audio_websocket_service.dart';
import '../../../../features/meetings/presentation/providers/upload_provider.dart';
import '../../../../features/content/presentation/providers/processing_jobs_provider.dart';
import '../../../../core/services/firebase_analytics_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/config/api_config.dart';
import '../../../../core/utils/error_utils.dart';
import 'recording_preferences_provider.dart';
import '../../../../features/live_insights/presentation/providers/live_insights_provider.dart';
import '../../../../features/live_insights/presentation/providers/tier_settings_provider.dart';
import '../../../../features/live_insights/domain/models/tier_settings.dart';

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
  final bool aiAssistantEnabled; // Added to track AI Assistant toggle state

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
    this.aiAssistantEnabled = false,
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
    bool? aiAssistantEnabled,
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
      aiAssistantEnabled: aiAssistantEnabled ?? this.aiAssistantEnabled,
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

  // Live insights services (initialized when AI Assistant is enabled)
  LiveAudioStreamingService? _liveAudioStreamingService;
  LiveAudioWebSocketService? _liveAudioWebSocketService;
  StreamSubscription? _audioChunkSubscription;

  @override
  RecordingStateModel build() {
    _audioService = ref.watch(audioRecordingServiceProvider);
    _transcriptionService = ref.watch(transcriptionServiceProvider);

    // Set up listeners
    _setupListeners();

    // Load AI Assistant preference
    _loadAiAssistantPreference();

    return RecordingStateModel();
  }

  /// Load AI Assistant enabled preference from SharedPreferences
  Future<void> _loadAiAssistantPreference() async {
    final prefsService = ref.read(recordingPreferencesServiceProvider);
    prefsService.whenData((service) {
      final enabled = service.getAiAssistantEnabled();
      state = state.copyWith(aiAssistantEnabled: enabled);
    });
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

      // Initialize live insights WebSocket if AI Assistant is enabled
      if (state.aiAssistantEnabled) {
        debugPrint('[RecordingProvider] AI Assistant enabled - initializing live insights');
        try {
          // 1. Get tier settings
          final tierSettings = await ref.read(tierSettingsNotifierProvider.future);
          final enabledTiers = tierSettings.enabledTiers;
          debugPrint('[RecordingProvider] Using tier configuration: $enabledTiers');

          // 2. Connect to live insights WebSocket (for receiving questions/actions/transcriptions)
          final liveInsightsService = ref.read(liveInsightsWebSocketServiceProvider);
          await liveInsightsService.connect(sessionId, enabledTiers: enabledTiers);
          debugPrint('[RecordingProvider] Connected to live insights WebSocket');

          // 2. Initialize live audio streaming service
          _liveAudioStreamingService = LiveAudioStreamingService();
          debugPrint('[RecordingProvider] Initialized live audio streaming service');

          // 3. Initialize and connect audio WebSocket for streaming audio to backend
          final authService = AuthService();
          final token = await authService.getToken();
          if (token != null) {
            _liveAudioWebSocketService = LiveAudioWebSocketService(
              baseUrl: ApiConfig.baseUrl,
            );

            final audioWsConnected = await _liveAudioWebSocketService!.connect(
              sessionId: sessionId,
              token: token,
              projectId: projectId,
            );

            if (audioWsConnected) {
              debugPrint('[RecordingProvider] Connected to audio streaming WebSocket');

              // 4. Start streaming audio chunks
              final streamingStarted = await _liveAudioStreamingService!.startStreaming();
              if (streamingStarted) {
                debugPrint('[RecordingProvider] Started audio streaming');

                // 5. Pipe audio chunks from streaming service to WebSocket
                _audioChunkSubscription = _liveAudioStreamingService!.audioChunkStream.listen(
                  (chunk) {
                    _liveAudioWebSocketService?.sendAudioChunk(chunk);
                  },
                  onError: (error) {
                    debugPrint('[RecordingProvider] Audio chunk stream error: $error');
                  },
                );
                debugPrint('[RecordingProvider] Audio chunk pipeline established');
              } else {
                // SILENT FAILURE: Audio streaming failed to start
                debugPrint('[RecordingProvider] Failed to start audio streaming');
                throw Exception('Failed to start audio streaming - check microphone permissions and codec support');
              }
            } else {
              // SILENT FAILURE: Audio WebSocket connection failed
              debugPrint('[RecordingProvider] Failed to connect audio WebSocket');
              throw Exception('Failed to connect audio WebSocket - check network connectivity');
            }
          } else {
            // SILENT FAILURE: No auth token available
            debugPrint('[RecordingProvider] No auth token available for audio streaming');
            throw Exception('No authentication token available for audio streaming');
          }
        } catch (e, stackTrace) {
          debugPrint('[RecordingProvider] Failed to initialize live insights: $e');
          // Report to Sentry with context
          await Sentry.captureException(
            e,
            stackTrace: stackTrace,
            hint: Hint.withMap({
              'context': 'AI Assistant initialization during recording start',
              'projectId': projectId,
              'sessionId': sessionId,
              'platform': kIsWeb ? 'web' : 'native',
            }),
          );

          // Show elegant notification to user
          ref.read(notificationServiceProvider.notifier).showWarning(
            'Live insights are disabled. Recording will continue normally.',
            title: 'AI Assistant unavailable',
          );

          // Don't fail the recording if live insights connection fails
          state = state.copyWith(
            errorMessage: null, // Clear error message since we're showing notification
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

    // Pause audio streaming if AI Assistant is enabled
    if (state.aiAssistantEnabled && _liveAudioStreamingService != null) {
      try {
        await _liveAudioStreamingService!.stopStreaming();
        debugPrint('[RecordingProvider] Paused audio streaming');
      } catch (e, stackTrace) {
        debugPrint('[RecordingProvider] Error pausing audio streaming: $e');
        await Sentry.captureException(
          e,
          stackTrace: stackTrace,
          hint: Hint.withMap({
            'context': 'Pausing audio streaming',
            'sessionId': state.sessionId,
            'platform': kIsWeb ? 'web' : 'native',
          }),
        );
      }
    }

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

    // Resume audio streaming if AI Assistant is enabled
    if (state.aiAssistantEnabled && _liveAudioStreamingService != null) {
      try {
        await _liveAudioStreamingService!.startStreaming();
        debugPrint('[RecordingProvider] Resumed audio streaming');

        // Re-establish audio chunk pipeline
        _audioChunkSubscription?.cancel();
        _audioChunkSubscription = _liveAudioStreamingService!.audioChunkStream.listen(
          (chunk) {
            _liveAudioWebSocketService?.sendAudioChunk(chunk);
          },
          onError: (error) {
            debugPrint('[RecordingProvider] Audio chunk stream error: $error');
          },
        );
        debugPrint('[RecordingProvider] Re-established audio chunk pipeline');
      } catch (e, stackTrace) {
        debugPrint('[RecordingProvider] Error resuming audio streaming: $e');
        await Sentry.captureException(
          e,
          stackTrace: stackTrace,
          hint: Hint.withMap({
            'context': 'Resuming audio streaming',
            'sessionId': state.sessionId,
            'platform': kIsWeb ? 'web' : 'native',
          }),
        );
      }
    }

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
      // Cleanup live insights services if AI Assistant was enabled
      if (state.aiAssistantEnabled) {
        debugPrint('[RecordingProvider] Cleaning up live insights services');
        try {
          // 1. Cancel audio chunk subscription
          await _audioChunkSubscription?.cancel();
          _audioChunkSubscription = null;
          debugPrint('[RecordingProvider] Cancelled audio chunk subscription');

          // 2. Stop audio streaming service
          if (_liveAudioStreamingService != null) {
            await _liveAudioStreamingService!.stopStreaming();
            _liveAudioStreamingService!.dispose();
            _liveAudioStreamingService = null;
            debugPrint('[RecordingProvider] Stopped and disposed audio streaming service');
          }

          // 3. Disconnect audio WebSocket
          if (_liveAudioWebSocketService != null) {
            await _liveAudioWebSocketService!.disconnect();
            _liveAudioWebSocketService = null;
            debugPrint('[RecordingProvider] Disconnected audio WebSocket');
          }

          // 4. Disconnect live insights WebSocket
          final liveInsightsService = ref.read(liveInsightsWebSocketServiceProvider);
          await liveInsightsService.disconnect();
          debugPrint('[RecordingProvider] Disconnected live insights WebSocket');

          debugPrint('[RecordingProvider] All live insights services cleaned up');
        } catch (e, stackTrace) {
          debugPrint('[RecordingProvider] Error during live insights cleanup: $e');
          await Sentry.captureException(
            e,
            stackTrace: stackTrace,
            hint: Hint.withMap({
              'context': 'Cleaning up live insights on recording stop',
              'sessionId': state.sessionId,
              'platform': kIsWeb ? 'web' : 'native',
            }),
          );
          // Continue with recording stop even if cleanup fails
        }
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

        // Get live transcription if AI Assistant was enabled
        String? transcriptionText;
        String? transcriptionSegments;

        if (state.aiAssistantEnabled) {
          debugPrint('[RecordingProvider] AI Assistant was enabled - fetching live transcription for upload');
          try {
            // Ensure provider is ready
            await ref.read(liveTranscriptionsTrackerProvider.future);

            // Get full transcription text
            final fullTranscription = ref.read(liveTranscriptionsTrackerProvider.notifier).getFullTranscription();
            debugPrint('[RecordingProvider] Full transcription length: ${fullTranscription.length} characters');

            if (fullTranscription.isNotEmpty) {
              transcriptionText = fullTranscription;
              debugPrint('[RecordingProvider] ✓ Will send live transcription: ${transcriptionText.substring(0, transcriptionText.length > 100 ? 100 : transcriptionText.length)}...');

              // Get segments with timing information
              final segments = ref.read(liveTranscriptionsTrackerProvider.notifier).getTranscriptionSegments();
              debugPrint('[RecordingProvider] Transcription segments count: ${segments.length}');

              if (segments.isNotEmpty) {
                // Convert to JSON string
                transcriptionSegments = json.encode(segments);
                debugPrint('[RecordingProvider] ✓ Will send ${segments.length} transcription segments');
              } else {
                debugPrint('[RecordingProvider] ⚠ No transcription segments available');
              }
            } else {
              debugPrint('[RecordingProvider] ⚠ No live transcription text available - backend will transcribe audio');
            }
          } catch (e, stackTrace) {
            debugPrint('[RecordingProvider] ✗ Error fetching live transcription: $e');
            debugPrint('[RecordingProvider] Stack trace: $stackTrace');
            await Sentry.captureException(
              e,
              stackTrace: stackTrace,
              hint: Hint.withMap({
                'context': 'Fetching live transcription for upload',
                'sessionId': state.sessionId,
                'aiAssistantEnabled': state.aiAssistantEnabled,
                'platform': kIsWeb ? 'web' : 'native',
              }),
            );
            // Continue without transcription - backend will transcribe audio file
          }
        } else {
          debugPrint('[RecordingProvider] AI Assistant was NOT enabled - will transcribe audio file');
        }

        debugPrint('[RecordingProvider] Final transcription parameters - text: ${transcriptionText != null ? "YES (${transcriptionText.length} chars)" : "NO"}, segments: ${transcriptionSegments != null ? "YES" : "NO"}');

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
          transcriptionText: transcriptionText,
          transcriptionSegments: transcriptionSegments,
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
    // Cleanup live insights services if AI Assistant was enabled
    if (state.aiAssistantEnabled) {
      debugPrint('[RecordingProvider] Cancelling recording - cleaning up live insights');
      try {
        // Cancel audio chunk subscription
        await _audioChunkSubscription?.cancel();
        _audioChunkSubscription = null;

        // Stop and dispose audio streaming service
        if (_liveAudioStreamingService != null) {
          await _liveAudioStreamingService!.stopStreaming();
          _liveAudioStreamingService!.dispose();
          _liveAudioStreamingService = null;
        }

        // Disconnect audio WebSocket
        if (_liveAudioWebSocketService != null) {
          await _liveAudioWebSocketService!.disconnect();
          _liveAudioWebSocketService = null;
        }

        // Disconnect live insights WebSocket
        final liveInsightsService = ref.read(liveInsightsWebSocketServiceProvider);
        await liveInsightsService.disconnect();

        debugPrint('[RecordingProvider] Live insights cleanup completed on cancel');
      } catch (e, stackTrace) {
        debugPrint('[RecordingProvider] Error during live insights cleanup on cancel: $e');
        await Sentry.captureException(
          e,
          stackTrace: stackTrace,
          hint: Hint.withMap({
            'context': 'Cleaning up live insights on recording cancel',
            'sessionId': state.sessionId,
            'platform': kIsWeb ? 'web' : 'native',
          }),
        );
      }
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

  /// Toggle AI Assistant enabled state
  Future<void> toggleAiAssistant() async {
    final newValue = !state.aiAssistantEnabled;
    state = state.copyWith(aiAssistantEnabled: newValue);

    // Persist preference
    final prefsService = ref.read(recordingPreferencesServiceProvider);
    prefsService.whenData((service) async {
      await service.setAiAssistantEnabled(newValue);
    });
  }

  /// Set AI Assistant enabled state
  Future<void> setAiAssistantEnabled(bool enabled) async {
    state = state.copyWith(aiAssistantEnabled: enabled);

    // Persist preference
    final prefsService = ref.read(recordingPreferencesServiceProvider);
    prefsService.whenData((service) async {
      await service.setAiAssistantEnabled(enabled);
    });
  }

  // Clean up subscriptions
  void disposeSubscriptions() {
    _amplitudeSubscription?.cancel();
    _durationSubscription?.cancel();
    _stateSubscription?.cancel();
    _warningSubscription?.cancel();
  }
}
