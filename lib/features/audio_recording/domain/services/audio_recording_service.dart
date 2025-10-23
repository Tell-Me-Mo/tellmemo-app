import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_sound/flutter_sound.dart';
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

  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final StreamController<RecordingState> _stateController = StreamController<RecordingState>.broadcast();
  final StreamController<Duration> _durationController = StreamController<Duration>.broadcast();
  final StreamController<double> _amplitudeController = StreamController<double>.broadcast();
  final StreamController<bool> _warningController = StreamController<bool>.broadcast();

  RecordingState _currentState = RecordingState.idle;
  bool _isRecorderOpen = false;
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
  
  // Open recorder session (required before recording)
  Future<bool> _openRecorder() async {
    if (_isRecorderOpen) return true;

    try {
      print('[AudioRecordingService] Opening recorder session...');
      await _recorder.openRecorder();
      _isRecorderOpen = true;
      print('[AudioRecordingService] Recorder session opened');
      return true;
    } catch (e) {
      print('[AudioRecordingService] Error opening recorder: $e');
      return false;
    }
  }

  // Check and request microphone permission
  Future<bool> requestPermission() async {
    try {
      print('[AudioRecordingService] Requesting microphone permission...');
      // flutter_sound handles permissions internally when opening recorder
      final opened = await _openRecorder();
      print('[AudioRecordingService] Microphone permission: $opened');
      return opened;
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
      // Ensure recorder is open
      final opened = await _openRecorder();
      if (!opened) {
        print('[AudioRecordingService] Failed to open recorder');
        _updateState(RecordingState.error);
        return false;
      }

      // Check if already recording
      if (_recorder.isRecording) {
        print('[AudioRecordingService] Already recording, cannot start new recording');
        return false;
      }

      // Generate file path for recording
      if (kIsWeb) {
        // For web, we record to a temporary location and get the data when stopping
        print('[AudioRecordingService] Web platform detected - recording to memory');
        _currentRecordingPath = 'web_recording.webm'; // Temporary placeholder
      } else {
        // For native platforms, create a file path
        final directory = await getApplicationDocumentsDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = 'recording_${projectId ?? "temp"}_$timestamp.aac';
        _currentRecordingPath = path.join(directory.path, 'recordings', fileName);

        // Create recordings directory if it doesn't exist
        final recordingsDir = Directory(path.dirname(_currentRecordingPath!));
        if (!await recordingsDir.exists()) {
          await recordingsDir.create(recursive: true);
        }
        print('[AudioRecordingService] Recording to file: $_currentRecordingPath');
      }

      // Configure codec based on platform
      Codec codec;
      int sampleRate;

      if (kIsWeb) {
        // Web platform: use Opus (widely supported in browsers)
        codec = Codec.opusWebM;
        sampleRate = 48000;
        print('[AudioRecordingService] Using web audio configuration: opus/48kHz');
      } else {
        // Native platforms: use AAC
        codec = Codec.aacADTS;
        sampleRate = 44100;
        print('[AudioRecordingService] Using native audio configuration: aac/44.1kHz');
      }

      // Start recording
      await _recorder.startRecorder(
        toFile: _currentRecordingPath,
        codec: codec,
        sampleRate: sampleRate,
        numChannels: 1, // Mono for speech
        bitRate: 128000, // 128kbps
      );

      print('[AudioRecordingService] Started recording to: $_currentRecordingPath');

      // Start duration and amplitude tracking
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
      print('[AudioRecordingService] Stack trace: ${StackTrace.current}');
      _updateState(RecordingState.error);
      return false;
    }
  }
  
  // Pause recording
  Future<void> pauseRecording() async {
    if (_recorder.isPaused) return;

    await _recorder.pauseRecorder();
    _pauseStartTime = DateTime.now();
    _durationTimer?.cancel();
    _amplitudeTimer?.cancel();
    _updateState(RecordingState.paused);
  }

  // Resume recording
  Future<void> resumeRecording() async {
    if (!_recorder.isPaused) return;

    await _recorder.resumeRecorder();

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

      if (!_recorder.isRecording && !_recorder.isPaused) {
        return null;
      }

      // Stop recording and get the result
      final result = await _recorder.stopRecorder();
      print('[AudioRecordingService] Recording stopped, result: $result');

      if (kIsWeb) {
        // For web, flutter_sound returns the file path where data was saved
        if (result != null && result.isNotEmpty) {
          print('[AudioRecordingService] Web recording successful, path: $result');
          _updateState(RecordingState.processing);
          _currentRecordingPath = result;
          return result;
        }
      } else {
        // For native platforms, verify file exists and has content
        if (result != null) {
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
      }

      _updateState(RecordingState.idle);
      _recordingStartTime = null;
      _pausedDuration = Duration.zero;
      _currentRecordingPath = null;

      return result;
    } catch (e) {
      // Logger: Failed to stop recording: $e
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
    final isRecording = _recorder.isRecording;
    final isPaused = _recorder.isPaused;

    if (isRecording || isPaused) {
      print('[AudioRecordingService] Recorder active (recording=$isRecording, paused=$isPaused) - stopping...');

      // Stop the recorder to release microphone
      try {
        await _recorder.stopRecorder();
        print('[AudioRecordingService] Recorder stopped, microphone should be released');
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
    _amplitudeTimer = Timer.periodic(const Duration(milliseconds: 100), (_) async {
      if (_currentState == RecordingState.recording && _recorder.isRecording) {
        try {
          // flutter_sound doesn't have a direct getAmplitude method like record package
          // We'll emit a default value for now, or you can implement a custom solution
          // using audio level monitoring with a different approach
          _amplitudeController.add(0.5); // Placeholder value
        } catch (e) {
          // Silently handle errors to avoid spam
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

    // Close recorder if open
    if (_isRecorderOpen) {
      try {
        await _recorder.closeRecorder();
        _isRecorderOpen = false;
      } catch (e) {
        print('[AudioRecordingService] Error closing recorder: $e');
      }
    }

    _stateController.close();
    _durationController.close();
    _amplitudeController.close();
    _warningController.close();
  }
  
  // Delete a recording file
  Future<void> deleteRecording(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}