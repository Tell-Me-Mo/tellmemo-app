import 'dart:async';
import 'dart:typed_data';
import 'package:record/record.dart';

/// Service for real-time audio streaming using record package
///
/// This service captures audio in real-time and buffers it into proper chunks
/// for live transcription and insights generation.
///
/// AudioRecorder emits small fragments continuously, so we buffer them
/// into ~10 second chunks before emitting to avoid overwhelming the transcription API.
class AudioStreamingService {
  final AudioRecorder _recorder = AudioRecorder();
  final StreamController<Uint8List> _audioChunkController = StreamController<Uint8List>.broadcast();

  bool _isInitialized = false;
  bool _isRecording = false;
  StreamSubscription<Uint8List>? _recordingStreamSubscription;

  // Audio buffering
  final List<int> _audioBuffer = [];

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

      // Check for permission
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        print('[AudioStreamingService] No microphone permission');
        return false;
      }

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
    // Stop processing if recording has been stopped
    if (!_isRecording) {
      return;
    }

    // Add fragment to buffer
    _audioBuffer.addAll(fragment);

    // Check if we've accumulated enough audio for a full chunk
    if (_audioBuffer.length >= targetChunkSize) {
      // Double-check recording status before emitting
      if (!_isRecording) {
        return;
      }

      // Extract exactly targetChunkSize bytes for this chunk
      final chunkBytes = Uint8List.fromList(_audioBuffer.sublist(0, targetChunkSize));

      // Remove the extracted bytes from buffer (keep any extra for next chunk)
      _audioBuffer.removeRange(0, targetChunkSize);

      final durationSeconds = chunkBytes.length / (sampleRate * bytesPerSample);
      print('[AudioStreamingService] ✅ Emitting chunk: ${chunkBytes.length} bytes (~${durationSeconds.toStringAsFixed(1)}s)');

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

      // Configure for PCM16 streaming
      final config = RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: sampleRate,
        numChannels: 1, // Mono for speech
      );

      // Start recording to stream
      final stream = await _recorder.startStream(config);

      // Subscribe to the stream and handle fragments
      _recordingStreamSubscription = stream.listen(
        _handleAudioFragment,
        onError: (error) {
          print('[AudioStreamingService] Stream error: $error');
          _isRecording = false;
        },
        onDone: () {
          print('[AudioStreamingService] Stream done');
          _isRecording = false;
        },
        cancelOnError: false,
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

      print('[AudioStreamingService] Stopping streaming...');

      // Set flag FIRST to prevent _handleAudioFragment from processing new fragments
      _isRecording = false;

      // Cancel stream subscription
      await _recordingStreamSubscription?.cancel();
      _recordingStreamSubscription = null;

      // Stop the recorder to release microphone
      try {
        await _recorder.stop();
        print('[AudioStreamingService] Recorder stopped, microphone released');
      } catch (e) {
        print('[AudioStreamingService] Error stopping recorder: $e');
        // Continue cleanup even if stop fails
      }

      // Clear buffer immediately
      if (_audioBuffer.isNotEmpty) {
        print('[AudioStreamingService] Discarding ${_audioBuffer.length} buffered bytes');
        _audioBuffer.clear();
      }

      print('[AudioStreamingService] Stopped streaming audio');
    } catch (e) {
      print('[AudioStreamingService] Error stopping stream: $e');
      _isRecording = false;  // Ensure flag is set even on error
    }
  }

  /// Pause streaming
  Future<void> pauseStreaming() async {
    try {
      if (!_isRecording) {
        print('[AudioStreamingService] Not recording');
        return;
      }

      await _recorder.pause();
      print('[AudioStreamingService] Paused streaming');
    } catch (e) {
      print('[AudioStreamingService] Error pausing stream: $e');
    }
  }

  /// Resume streaming
  Future<void> resumeStreaming() async {
    try {
      await _recorder.resume();
      print('[AudioStreamingService] Resumed streaming');
    } catch (e) {
      print('[AudioStreamingService] Error resuming stream: $e');
    }
  }

  /// Dispose of the service and clean up resources
  Future<void> dispose() async {
    try {
      print('[AudioStreamingService] Starting disposal...');

      // Stop recording first if active
      if (_isRecording) {
        print('[AudioStreamingService] Stopping active recording...');
        await stopStreaming();
      }

      // Cancel stream subscription
      print('[AudioStreamingService] Cancelling stream subscription...');
      await _recordingStreamSubscription?.cancel();
      _recordingStreamSubscription = null;

      // Dispose recorder
      if (_isInitialized) {
        print('[AudioStreamingService] Disposing recorder...');
        try {
          await _recorder.dispose();
          _isInitialized = false;
          print('[AudioStreamingService] Recorder disposed');
        } catch (e) {
          print('[AudioStreamingService] Error disposing recorder: $e');
          // Continue cleanup even if this fails
        }
      }

      // Close stream controller
      print('[AudioStreamingService] Closing stream controller...');
      if (!_audioChunkController.isClosed) {
        await _audioChunkController.close();
      }

      // Clear buffer
      _audioBuffer.clear();

      print('[AudioStreamingService] Disposed successfully');
    } catch (e) {
      print('[AudioStreamingService] Error disposing: $e');
    }
  }
}
