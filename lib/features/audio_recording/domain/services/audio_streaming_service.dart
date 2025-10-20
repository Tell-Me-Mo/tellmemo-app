import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_sound/flutter_sound.dart';

/// Service for real-time audio streaming using flutter_sound
///
/// This service captures audio in real-time and buffers it into proper chunks
/// for live transcription and insights generation.
///
/// FlutterSoundRecorder emits small fragments continuously, so we buffer them
/// into ~10 second chunks before emitting to avoid overwhelming the transcription API.
class AudioStreamingService {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final StreamController<Uint8List> _audioChunkController = StreamController<Uint8List>.broadcast();
  final StreamController<Uint8List> _internalStreamController = StreamController<Uint8List>();

  bool _isInitialized = false;
  bool _isRecording = false;

  // Audio buffering
  final List<int> _audioBuffer = [];
  StreamSubscription<Uint8List>? _bufferSubscription;

  // Configuration
  static const int sampleRate = 16000; // 16kHz for speech recognition
  static const int chunkDurationSeconds = 10; // Buffer 10 seconds of audio per chunk
  static const int bytesPerSample = 2; // 16-bit PCM = 2 bytes per sample
  static const int targetChunkSize = sampleRate * chunkDurationSeconds * bytesPerSample; // ~320KB for 10s

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

      // Set up buffering: listen to raw stream and accumulate into chunks
      _bufferSubscription = _internalStreamController.stream.listen(
        _handleAudioFragment,
        onError: (error) {
          print('[AudioStreamingService] Buffer stream error: $error');
        },
      );

      _isInitialized = true;
      print('[AudioStreamingService] Initialized successfully (chunk size: ${targetChunkSize ~/ 1024}KB for ${chunkDurationSeconds}s)');
      return true;
    } catch (e) {
      print('[AudioStreamingService] Initialization error: $e');
      return false;
    }
  }

  /// Handle incoming audio fragments and buffer them into proper chunks
  void _handleAudioFragment(Uint8List fragment) {
    // Add fragment to buffer
    _audioBuffer.addAll(fragment);

    print('[AudioStreamingService] Buffered ${fragment.length} bytes, total: ${_audioBuffer.length}/${targetChunkSize} bytes (${(_audioBuffer.length / targetChunkSize * 100).toStringAsFixed(1)}%)');

    // Check if we've accumulated enough audio for a full chunk
    if (_audioBuffer.length >= targetChunkSize) {
      // Extract exactly targetChunkSize bytes for this chunk
      final chunkBytes = Uint8List.fromList(_audioBuffer.sublist(0, targetChunkSize));

      // Remove the extracted bytes from buffer (keep any extra for next chunk)
      _audioBuffer.removeRange(0, targetChunkSize);

      final durationSeconds = chunkBytes.length / (sampleRate * bytesPerSample);
      print('[AudioStreamingService] Emitting chunk: ${chunkBytes.length} bytes (~${durationSeconds.toStringAsFixed(1)}s), remaining buffer: ${_audioBuffer.length} bytes');

      // Emit the complete chunk
      _audioChunkController.add(chunkBytes);
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

      // Clear any existing buffer
      _audioBuffer.clear();

      // Start recording to internal stream (which feeds the buffer)
      await _recorder.startRecorder(
        toStream: _internalStreamController.sink,
        codec: Codec.pcm16,
        sampleRate: sampleRate,
        numChannels: 1,
      );

      _isRecording = true;
      print('[AudioStreamingService] Started streaming audio with buffering (target: ${chunkDurationSeconds}s chunks)');
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

      // Flush any remaining buffered audio (if there's at least 1 second of audio)
      if (_audioBuffer.isNotEmpty && _audioBuffer.length >= sampleRate * bytesPerSample) {
        final remainingBytes = Uint8List.fromList(_audioBuffer);
        final durationSeconds = remainingBytes.length / (sampleRate * bytesPerSample);

        print('[AudioStreamingService] Flushing final chunk: ${remainingBytes.length} bytes (~${durationSeconds.toStringAsFixed(1)}s)');
        _audioChunkController.add(remainingBytes);
        _audioBuffer.clear();
      } else if (_audioBuffer.isNotEmpty) {
        print('[AudioStreamingService] Discarding ${_audioBuffer.length} bytes (< 1s, too short)');
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

      // Cancel buffer subscription
      await _bufferSubscription?.cancel();
      _bufferSubscription = null;

      if (_isInitialized) {
        await _recorder.closeRecorder();
        _isInitialized = false;
      }

      // Close stream controllers
      await _internalStreamController.close();
      await _audioChunkController.close();

      // Clear buffer
      _audioBuffer.clear();

      print('[AudioStreamingService] Disposed');
    } catch (e) {
      print('[AudioStreamingService] Error disposing: $e');
    }
  }
}
