import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_sound/flutter_sound.dart';

/// Service for real-time audio streaming using flutter_sound
///
/// This service captures audio in real-time and provides it as chunks
/// for live transcription and insights generation.
class AudioStreamingService {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final StreamController<Uint8List> _audioChunkController = StreamController<Uint8List>.broadcast();

  bool _isInitialized = false;
  bool _isRecording = false;

  // Configuration
  static const int sampleRate = 16000; // 16kHz for speech recognition

  /// Stream of audio chunks (each chunk is ~10 seconds of audio)
  Stream<Uint8List> get audioChunkStream => _audioChunkController.stream;

  /// Check if the service is initialized
  bool get isInitialized => _isInitialized;

  /// Check if currently recording
  bool get isRecording => _isRecording;

  /// Initialize the audio streaming service
  Future<bool> initialize() async {
    try {
      if (_isInitialized) {
        print('[AudioStreamingService] Already initialized');
        return true;
      }

      // Open the audio session (flutter_sound handles permissions internally)
      await _recorder.openRecorder();

      _isInitialized = true;
      print('[AudioStreamingService] Initialized successfully');
      return true;
    } catch (e) {
      print('[AudioStreamingService] Initialization error: $e');
      return false;
    }
  }

  /// Start streaming audio
  Future<bool> startStreaming() async {
    try {
      if (!_isInitialized) {
        print('[AudioStreamingService] Not initialized, initializing now...');
        final initialized = await initialize();
        if (!initialized) {
          return false;
        }
      }

      if (_isRecording) {
        print('[AudioStreamingService] Already recording');
        return false;
      }

      // Start recording to stream
      await _recorder.startRecorder(
        toStream: _audioChunkController.sink,
        codec: Codec.pcm16,
        sampleRate: sampleRate,
        numChannels: 1,
      );

      _isRecording = true;
      print('[AudioStreamingService] Started streaming audio');
      return true;
    } catch (e) {
      print('[AudioStreamingService] Error starting stream: $e');
      return false;
    }
  }

  /// Stop streaming audio
  Future<void> stopStreaming() async {
    try {
      if (!_isRecording) {
        print('[AudioStreamingService] Not recording');
        return;
      }

      await _recorder.stopRecorder();

      _isRecording = false;
      print('[AudioStreamingService] Stopped streaming audio');
    } catch (e) {
      print('[AudioStreamingService] Error stopping stream: $e');
    }
  }

  /// Pause streaming (keeps session open)
  Future<void> pauseStreaming() async {
    try {
      if (!_isRecording) {
        print('[AudioStreamingService] Not recording');
        return;
      }

      await _recorder.pauseRecorder();
      print('[AudioStreamingService] Paused streaming');
    } catch (e) {
      print('[AudioStreamingService] Error pausing stream: $e');
    }
  }

  /// Resume streaming
  Future<void> resumeStreaming() async {
    try {
      await _recorder.resumeRecorder();
      print('[AudioStreamingService] Resumed streaming');
    } catch (e) {
      print('[AudioStreamingService] Error resuming stream: $e');
    }
  }

  /// Dispose of the service and clean up resources
  Future<void> dispose() async {
    try {
      if (_isRecording) {
        await stopStreaming();
      }

      if (_isInitialized) {
        await _recorder.closeRecorder();
        _isInitialized = false;
      }

      await _audioChunkController.close();

      print('[AudioStreamingService] Disposed');
    } catch (e) {
      print('[AudioStreamingService] Error disposing: $e');
    }
  }
}
