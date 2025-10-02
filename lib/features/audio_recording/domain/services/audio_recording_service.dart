import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
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
  final AudioRecorder _recorder = AudioRecorder();
  final StreamController<RecordingState> _stateController = StreamController<RecordingState>.broadcast();
  final StreamController<Duration> _durationController = StreamController<Duration>.broadcast();
  final StreamController<double> _amplitudeController = StreamController<double>.broadcast();
  
  RecordingState _currentState = RecordingState.idle;
  Timer? _durationTimer;
  Timer? _amplitudeTimer;
  DateTime? _recordingStartTime;
  Duration _pausedDuration = Duration.zero;
  DateTime? _pauseStartTime;
  String? _currentRecordingPath;
  
  // Getters
  Stream<RecordingState> get stateStream => _stateController.stream;
  Stream<Duration> get durationStream => _durationController.stream;
  Stream<double> get amplitudeStream => _amplitudeController.stream;
  RecordingState get currentState => _currentState;
  String? get currentRecordingPath => _currentRecordingPath;
  
  // Check and request microphone permission
  Future<bool> requestPermission() async {
    try {
      if (kIsWeb) {
        // For web, use the record package's built-in permission check
        print('[AudioRecordingService] Checking microphone permission on web...');
        final hasPermission = await _recorder.hasPermission();
        print('[AudioRecordingService] Web microphone permission: $hasPermission');
        return hasPermission;
      } else {
        // For mobile/desktop, use permission_handler
        print('[AudioRecordingService] Requesting microphone permission on native platform...');
        final status = await Permission.microphone.request();
        print('[AudioRecordingService] Native microphone permission status: $status');
        return status == PermissionStatus.granted;
      }
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
      // Check if already recording
      if (await _recorder.isRecording()) {
        print('[AudioRecordingService] Already recording, cannot start new recording');
        return false;
      }
      
      // Check permission
      print('[AudioRecordingService] Checking microphone permission...');
      final hasPermission = await requestPermission();
      if (!hasPermission) {
        print('[AudioRecordingService] Microphone permission denied');
        _updateState(RecordingState.error);
        return false;
      }
      print('[AudioRecordingService] Microphone permission granted');
      
      // Generate file path for recording
      if (kIsWeb) {
        // For web, we don't need a file path as recording is handled in memory
        print('[AudioRecordingService] Web platform detected - recording to memory');
        _currentRecordingPath = null;
      } else {
        // For native platforms, create a file path
        final directory = await getApplicationDocumentsDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = 'recording_${projectId ?? "temp"}_$timestamp.wav';
        _currentRecordingPath = path.join(directory.path, 'recordings', fileName);
        
        // Create recordings directory if it doesn't exist
        final recordingsDir = Directory(path.dirname(_currentRecordingPath!));
        if (!await recordingsDir.exists()) {
          await recordingsDir.create(recursive: true);
        }
        print('[AudioRecordingService] Recording to file: $_currentRecordingPath');
      }
      
      // Configure recording based on platform
      RecordConfig config;
      if (kIsWeb) {
        // Web-specific configuration - use WebM format
        config = const RecordConfig(
          encoder: AudioEncoder.opus, // Web supports opus in WebM container
          sampleRate: 48000, // Standard web audio sample rate
          numChannels: 1, // Mono for speech
          bitRate: 128000,
          autoGain: true,
          echoCancel: true,
          noiseSuppress: true,
        );
        print('[AudioRecordingService] Using web audio configuration: opus/48kHz');
      } else {
        // Native platform configuration
        config = const RecordConfig(
          encoder: AudioEncoder.wav, // WAV format for best quality
          sampleRate: 44100, // Higher sample rate for better quality
          numChannels: 1, // Mono is sufficient for speech
          bitRate: 128000, // High bitrate for quality
          autoGain: true,
          echoCancel: true,
          noiseSuppress: true,
        );
        print('[AudioRecordingService] Using native audio configuration: wav/44.1kHz');
      }
      
      // Start recording
      if (kIsWeb) {
        // For web, the path parameter is ignored but still required by the API
        await _recorder.start(config, path: 'web_recording');
        print('[AudioRecordingService] Started web recording');
      } else {
        // For native platforms, provide the file path
        await _recorder.start(config, path: _currentRecordingPath!);
        print('[AudioRecordingService] Started native recording to: $_currentRecordingPath');
      }
      
      // Start duration and amplitude tracking
      _recordingStartTime = DateTime.now();
      _pausedDuration = Duration.zero;
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
    if (await _recorder.isPaused()) return;
    
    await _recorder.pause();
    _pauseStartTime = DateTime.now();
    _durationTimer?.cancel();
    _amplitudeTimer?.cancel();
    _updateState(RecordingState.paused);
  }
  
  // Resume recording
  Future<void> resumeRecording() async {
    if (!await _recorder.isPaused()) return;
    
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
      
      if (!await _recorder.isRecording() && !await _recorder.isPaused()) {
        return null;
      }
      
      // Stop recording and get the result
      final result = await _recorder.stop();
      print('[AudioRecordingService] Recording stopped, result: $result');
      
      if (kIsWeb) {
        // For web, the result is a path to the blob URL or base64 data
        if (result != null && result.isNotEmpty) {
          print('[AudioRecordingService] Web recording successful, blob/data length: ${result.length}');
          _updateState(RecordingState.processing);
          _currentRecordingPath = result; // Store the blob URL or base64 data
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
    _durationTimer?.cancel();
    _amplitudeTimer?.cancel();
    
    // Stop recording
    await _recorder.cancel();
    
    // Delete the recording file if it exists
    if (_currentRecordingPath != null) {
      final file = File(_currentRecordingPath!);
      if (await file.exists()) {
        await file.delete();
      }
    }
    
    _updateState(RecordingState.idle);
    _recordingStartTime = null;
    _pausedDuration = Duration.zero;
    _currentRecordingPath = null;
  }
  
  // Start amplitude monitoring for visualization
  void _startAmplitudeMonitoring() {
    _amplitudeTimer?.cancel();
    _amplitudeTimer = Timer.periodic(const Duration(milliseconds: 100), (_) async {
      if (_currentState == RecordingState.recording) {
        final amplitude = await _recorder.getAmplitude();
        _amplitudeController.add(amplitude.current);
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
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_recordingStartTime != null) {
        _durationController.add(getRecordingDuration());
      }
    });
  }
  
  // Dispose resources
  void dispose() {
    _durationTimer?.cancel();
    _amplitudeTimer?.cancel();
    _recorder.dispose();
    _stateController.close();
    _durationController.close();
    _amplitudeController.close();
  }
  
  // Delete a recording file
  Future<void> deleteRecording(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}