import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Service for real-time audio streaming using flutter_sound
///
/// This service captures audio in real-time and provides it as chunks
/// for live transcription and insights generation.
class AudioStreamingService {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final StreamController<Uint8List> _audioChunkController = StreamController<Uint8List>.broadcast();

  bool _isInitialized = false;
  bool _isRecording = false;
  List<int> _audioBuffer = [];

  // Configuration
  static const int sampleRate = 16000; // 16kHz for speech recognition
  static const int bufferSize = 160000; // 10 seconds of audio at 16kHz (16000 * 10)

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

      _audioBuffer.clear();

      // Start recording to stream
      await _recorder.startRecorder(
        toStream: _handleAudioData,
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

  /// Handle incoming audio data from the recorder
  void _handleAudioData(Uint8List data) {
    try {
      // Add data to buffer
      _audioBuffer.addAll(data);

      // Check if buffer has reached 10 seconds worth of audio
      if (_audioBuffer.length >= bufferSize) {
        // Extract the chunk
        final chunk = Uint8List.fromList(_audioBuffer.take(bufferSize).toList());

        // Remove processed data from buffer
        _audioBuffer.removeRange(0, bufferSize);

        // Emit the chunk
        _audioChunkController.add(chunk);

        print('[AudioStreamingService] Emitted audio chunk: ${chunk.length} bytes');
      }
    } catch (e) {
      print('[AudioStreamingService] Error handling audio data: $e');
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

      // Emit any remaining audio in buffer as final chunk
      if (_audioBuffer.isNotEmpty) {
        final finalChunk = Uint8List.fromList(_audioBuffer);
        _audioChunkController.add(finalChunk);
        print('[AudioStreamingService] Emitted final chunk: ${finalChunk.length} bytes');
        _audioBuffer.clear();
      }

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
      _audioBuffer.clear();

      print('[AudioStreamingService] Disposed');
    } catch (e) {
      print('[AudioStreamingService] Error disposing: $e');
    }
  }
}
