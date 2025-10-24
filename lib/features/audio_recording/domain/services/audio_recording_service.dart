import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

enum RecordingState {
  idle,
  recording,
  paused,
  processing,
  error,
}

class AudioRecordingService {
  // Recording duration limits
  static const Duration maxRecordingDuration = Duration(hours: 2); // 2 hours max
  static const Duration warningThreshold = Duration(minutes: 90); // Warning at 90 minutes

  final AudioRecorder _recorder = AudioRecorder();
  final StreamController<RecordingState> _stateController = StreamController<RecordingState>.broadcast();
  final StreamController<Duration> _durationController = StreamController<Duration>.broadcast();
  final StreamController<double> _amplitudeController = StreamController<double>.broadcast();
  final StreamController<bool> _warningController = StreamController<bool>.broadcast();

  RecordingState _currentState = RecordingState.idle;
  Timer? _durationTimer;
  Timer? _amplitudeTimer;
  DateTime? _recordingStartTime;
  Duration _pausedDuration = Duration.zero;
  DateTime? _pauseStartTime;
  String? _currentRecordingPath;
  bool _hasShownWarning = false;

  // Getters
  Stream<RecordingState> get stateStream => _stateController.stream;
  Stream<Duration> get durationStream => _durationController.stream;
  Stream<double> get amplitudeStream => _amplitudeController.stream;
  Stream<bool> get warningStream => _warningController.stream;
  RecordingState get currentState => _currentState;
  String? get currentRecordingPath => _currentRecordingPath;

  // Check and request microphone permission
  Future<bool> requestPermission() async {
    try {
      print('[AudioRecordingService] Requesting microphone permission...');
      final hasPermission = await _recorder.hasPermission();
      print('[AudioRecordingService] Microphone permission: $hasPermission');
      return hasPermission;
    } catch (e) {
      print('[AudioRecordingService] Error checking permission: $e');
      return false;
    }
  }

  // Start recording to file
  Future<bool> startRecording({
    String? projectId,
    String? meetingTitle,
  }) async {
    try {
      // Check permission
      final hasPermission = await requestPermission();
      if (!hasPermission) {
        print('[AudioRecordingService] No microphone permission');
        _updateState(RecordingState.error);
        return false;
      }

      // Check if already recording
      final isRecording = await _recorder.isRecording();
      if (isRecording) {
        print('[AudioRecordingService] Already recording, cannot start new recording');
        return false;
      }

      // Generate file path for recording
      if (kIsWeb) {
        // For web, we record to a temporary location and get the data when stopping
        print('[AudioRecordingService] Web platform detected - recording to memory');
        _currentRecordingPath = 'web_recording'; // Placeholder, actual path returned on stop
      } else {
        // For native platforms, create a file path
        final directory = await getApplicationDocumentsDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = 'recording_${projectId ?? "temp"}_$timestamp.m4a';
        _currentRecordingPath = path.join(directory.path, 'recordings', fileName);

        // Create recordings directory if it doesn't exist
        final recordingsDir = Directory(path.dirname(_currentRecordingPath!));
        if (!await recordingsDir.exists()) {
          await recordingsDir.create(recursive: true);
        }
        print('[AudioRecordingService] Recording to file: $_currentRecordingPath');
      }

      // Configure codec based on platform
      final config = RecordConfig(
        encoder: kIsWeb ? AudioEncoder.opus : AudioEncoder.aacLc,
        sampleRate: kIsWeb ? 48000 : 44100,
        numChannels: 1, // Mono for speech
        bitRate: 128000, // 128kbps
      );

      print('[AudioRecordingService] Using ${kIsWeb ? 'web' : 'native'} audio configuration: ${config.encoder}/${config.sampleRate}Hz');

      // Start recording
      // Note: path is required but ignored on web (returns blob URL on stop)
      await _recorder.start(config, path: _currentRecordingPath!);

      print('[AudioRecordingService] Started recording');

      // Start duration tracking and amplitude monitoring
      _recordingStartTime = DateTime.now();
      _pausedDuration = Duration.zero;
      _hasShownWarning = false; // Reset warning flag for new recording
      _startDurationTimer();
      _startAmplitudeMonitoring();

      _updateState(RecordingState.recording);
      print('[AudioRecordingService] Recording started successfully');
      return true;
    } catch (e) {
      print('[AudioRecordingService] Failed to start recording: $e');
      print('[AudioRecordingService] Error type: ${e.runtimeType}');
      _updateState(RecordingState.error);
      return false;
    }
  }

  // Pause recording
  Future<void> pauseRecording() async {
    final isPaused = await _recorder.isPaused();
    if (isPaused) return;

    await _recorder.pause();
    _pauseStartTime = DateTime.now();
    _durationTimer?.cancel();
    _amplitudeTimer?.cancel();
    _updateState(RecordingState.paused);
  }

  // Resume recording
  Future<void> resumeRecording() async {
    final isPaused = await _recorder.isPaused();
    if (!isPaused) return;

    await _recorder.resume();

    // Add paused duration to total
    if (_pauseStartTime != null) {
      _pausedDuration += DateTime.now().difference(_pauseStartTime!);
      _pauseStartTime = null;
    }

    _startDurationTimer();
    _startAmplitudeMonitoring();
    _updateState(RecordingState.recording);
  }

  // Stop recording and return file path
  Future<String?> stopRecording() async {
    try {
      _durationTimer?.cancel();
      _amplitudeTimer?.cancel();

      final isRecording = await _recorder.isRecording();
      if (!isRecording) {
        return null;
      }

      // Stop recording and get the result
      final result = await _recorder.stop();
      print('[AudioRecordingService] Recording stopped, result: $result');

      if (result != null && result.isNotEmpty) {
        if (kIsWeb) {
          // For web, record package returns the blob URL
          print('[AudioRecordingService] Web recording successful, blob URL: $result');
          _currentRecordingPath = result;
        } else {
          // For native platforms, verify file exists and has content
          final file = File(result);
          if (await file.exists()) {
            final fileSize = await file.length();
            print('[AudioRecordingService] Recording file size: $fileSize bytes');
            if (fileSize > 0) {
              _updateState(RecordingState.processing);
              return result;
            }
          }
        }
        _updateState(RecordingState.processing);
        return result;
      }

      _updateState(RecordingState.idle);
      _recordingStartTime = null;
      _pausedDuration = Duration.zero;
      _currentRecordingPath = null;

      return result;
    } catch (e) {
      print('[AudioRecordingService] Failed to stop recording: $e');
      _updateState(RecordingState.error);
      return null;
    }
  }

  // Cancel recording and delete file
  Future<void> cancelRecording() async {
    print('[AudioRecordingService] Cancelling recording...');

    _durationTimer?.cancel();
    _amplitudeTimer?.cancel();

    // Check if recorder is actually recording or paused
    final isRecording = await _recorder.isRecording();
    final isPaused = await _recorder.isPaused();

    if (isRecording || isPaused) {
      print('[AudioRecordingService] Recorder active (recording=$isRecording, paused=$isPaused) - stopping...');

      // Stop the recorder to release microphone
      try {
        await _recorder.stop();
        print('[AudioRecordingService] Recorder stopped, microphone released');
      } catch (e) {
        print('[AudioRecordingService] Error stopping recorder: $e');
      }
    } else {
      print('[AudioRecordingService] Recorder not active, no need to stop');
    }

    print('[AudioRecordingService] Recording cancelled and file discarded');

    _updateState(RecordingState.idle);
    _recordingStartTime = null;
    _pausedDuration = Duration.zero;
    _currentRecordingPath = null;
  }

  // Start amplitude monitoring for visualization
  void _startAmplitudeMonitoring() {
    _amplitudeTimer?.cancel();

    // Poll amplitude every 100ms for smooth visualization
    _amplitudeTimer = Timer.periodic(const Duration(milliseconds: 100), (_) async {
      if (_currentState == RecordingState.recording) {
        try {
          final amplitude = await _recorder.getAmplitude();
          // record package returns Amplitude with current and max dB values
          // current is typically in range -160 (silence) to 0 (max)
          _amplitudeController.add(amplitude.current);
        } catch (e) {
          // Silently ignore amplitude errors (happens when recording stops)
        }
      }
    });
  }

  // Get recording duration
  Duration getRecordingDuration() {
    if (_recordingStartTime == null) return Duration.zero;

    var totalDuration = DateTime.now().difference(_recordingStartTime!);

    // Subtract paused duration
    totalDuration -= _pausedDuration;

    // If currently paused, subtract current pause duration
    if (_pauseStartTime != null) {
      totalDuration -= DateTime.now().difference(_pauseStartTime!);
    }

    return totalDuration;
  }

  // Update state and notify listeners
  void _updateState(RecordingState newState) {
    _currentState = newState;
    _stateController.add(newState);
  }

  // Start duration timer
  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (_recordingStartTime != null) {
        final duration = getRecordingDuration();
        _durationController.add(duration);

        // Check for warning threshold (90 minutes)
        if (!_hasShownWarning && duration >= warningThreshold) {
          _hasShownWarning = true;
          _warningController.add(true);
          print('[AudioRecordingService] Warning: Recording has reached 90 minutes');
        }

        // Auto-stop at max duration (2 hours)
        if (duration >= maxRecordingDuration) {
          print('[AudioRecordingService] Max duration reached - auto-stopping recording');
          await stopRecording();
        }
      }
    });
  }

  // Dispose resources
  Future<void> dispose() async {
    _durationTimer?.cancel();
    _amplitudeTimer?.cancel();

    // Stop and dispose recorder
    try {
      final isRecording = await _recorder.isRecording();
      if (isRecording) {
        await _recorder.stop();
      }
      await _recorder.dispose();
    } catch (e) {
      print('[AudioRecordingService] Error disposing recorder: $e');
    }

    await _stateController.close();
    await _durationController.close();
    await _amplitudeController.close();
    await _warningController.close();
  }

  // Delete a recording file
  Future<void> deleteRecording(String filePath) async {
    if (!kIsWeb) {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    }
    // On web, blob URLs are automatically garbage collected
  }
}
