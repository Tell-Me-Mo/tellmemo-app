import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:record/record.dart';

/// Service for real-time audio streaming to backend for live transcription.
///
/// This service captures audio in PCM 16kHz, 16-bit, mono format and streams
/// chunks to the backend via WebSocket for real-time transcription with AssemblyAI.
///
/// Features:
/// - Real-time audio chunk streaming (Stream<Uint8List>)
/// - PCM 16kHz, 16-bit, mono format (AssemblyAI compatible)
/// - Audio quality monitoring (amplitude, silence, clipping detection)
/// - Timestamp synchronization with backend
/// - Platform support: Web, iOS, Android, macOS
class LiveAudioStreamingService {
  final AudioRecorder _recorder = AudioRecorder();

  // Stream controllers
  final StreamController<Uint8List> _audioChunkController = StreamController<Uint8List>.broadcast();
  final StreamController<AudioQualityMetrics> _qualityController = StreamController<AudioQualityMetrics>.broadcast();
  final StreamController<StreamingState> _stateController = StreamController<StreamingState>.broadcast();

  // State
  StreamingState _currentState = StreamingState.idle;
  StreamSubscription<Uint8List>? _audioStreamSubscription;
  DateTime? _streamStartTime;
  int _sequenceNumber = 0;
  int _totalBytesStreamed = 0;

  // Audio quality monitoring
  Timer? _qualityMonitorTimer;
  final List<double> _recentAmplitudes = [];
  static const int _amplitudeHistorySize = 50; // 5 seconds at 100ms intervals

  // Audio buffering for AssemblyAI (requires 50-1000ms chunks)
  final List<int> _audioBuffer = [];
  static const int _minBufferSizeBytes = 1600; // 50ms at 16kHz, 16-bit, mono = 50ms * 16000 * 2 = 1600 bytes
  static const int _maxBufferSizeBytes = 32000; // 1000ms at 16kHz, 16-bit, mono = 1000ms * 16000 * 2 = 32000 bytes
  static const int _targetBufferSizeBytes = 3200; // 100ms chunks (good balance)

  // Getters
  Stream<Uint8List> get audioChunkStream => _audioChunkController.stream;
  Stream<AudioQualityMetrics> get qualityMetricsStream => _qualityController.stream;
  Stream<StreamingState> get stateStream => _stateController.stream;
  StreamingState get currentState => _currentState;
  bool get isStreaming => _currentState == StreamingState.streaming;
  int get totalBytesStreamed => _totalBytesStreamed;

  /// Check and request microphone permission
  Future<bool> requestPermission() async {
    try {
      print('[LiveAudioStreamingService] Requesting microphone permission...');
      final hasPermission = await _recorder.hasPermission();
      print('[LiveAudioStreamingService] Microphone permission: $hasPermission');
      return hasPermission;
    } catch (e) {
      print('[LiveAudioStreamingService] Error checking permission: $e');
      return false;
    }
  }

  /// Start streaming audio chunks to backend
  ///
  /// Audio format: PCM 16kHz, 16-bit, mono
  /// Chunk size: ~100-200ms per chunk (1600-3200 bytes)
  ///
  /// Returns true if streaming started successfully
  Future<bool> startStreaming() async {
    try {
      // Check if already streaming
      if (await _recorder.isRecording()) {
        print('[LiveAudioStreamingService] Already streaming, cannot start new stream');
        return false;
      }

      // Check permission (skip for web - browser will prompt)
      if (!kIsWeb) {
        print('[LiveAudioStreamingService] Checking microphone permission...');
        final hasPermission = await requestPermission();
        if (!hasPermission) {
          print('[LiveAudioStreamingService] Microphone permission denied');
          _updateState(StreamingState.error);
          return false;
        }
        print('[LiveAudioStreamingService] Microphone permission granted');
      } else {
        print('[LiveAudioStreamingService] Web platform - permission will be requested by browser');
      }

      // Configure audio for streaming
      // PCM 16kHz, 16-bit, mono - AssemblyAI compatible format
      const config = RecordConfig(
        encoder: AudioEncoder.pcm16bits, // Raw PCM 16-bit
        sampleRate: 16000,                // 16kHz (AssemblyAI standard)
        numChannels: 1,                   // Mono
        bitRate: 256000,                  // 16 bits * 16000 Hz = 256kbps
        autoGain: true,                   // Enable automatic gain control
        echoCancel: true,                 // Enable echo cancellation
        noiseSuppress: true,              // Enable noise suppression
      );

      print('[LiveAudioStreamingService] Starting audio stream with config:');
      print('  - Encoder: PCM 16-bit');
      print('  - Sample Rate: 16kHz');
      print('  - Channels: Mono');
      print('  - Auto Gain: ON');
      print('  - Echo Cancel: ON');
      print('  - Noise Suppress: ON');

      // Start streaming
      final audioStream = await _recorder.startStream(config);
      _streamStartTime = DateTime.now();
      _sequenceNumber = 0;
      _totalBytesStreamed = 0;

      // Subscribe to audio stream and forward chunks
      _audioStreamSubscription = audioStream.listen(
        _onAudioChunk,
        onError: _onStreamError,
        onDone: _onStreamDone,
        cancelOnError: false,
      );

      // Start quality monitoring
      _startQualityMonitoring();

      _updateState(StreamingState.streaming);
      print('[LiveAudioStreamingService] Audio streaming started successfully');
      return true;
    } catch (e) {
      print('[LiveAudioStreamingService] Failed to start streaming: $e');
      print('[LiveAudioStreamingService] Error type: ${e.runtimeType}');
      print('[LiveAudioStreamingService] Stack trace: ${StackTrace.current}');
      _updateState(StreamingState.error);
      return false;
    }
  }

  /// Stop streaming audio
  Future<void> stopStreaming() async {
    try {
      print('[LiveAudioStreamingService] Stopping audio stream...');

      // Flush any remaining buffered audio
      if (_audioBuffer.isNotEmpty) {
        final bufferedChunk = Uint8List.fromList(_audioBuffer);
        print('[LiveAudioStreamingService] Flushing final buffered chunk: ${bufferedChunk.length} bytes');
        _audioChunkController.add(bufferedChunk);
        _audioBuffer.clear();
      }

      // Cancel subscription first
      await _audioStreamSubscription?.cancel();
      _audioStreamSubscription = null;

      // Stop recorder
      if (await _recorder.isRecording()) {
        await _recorder.stop();
      }

      // Stop quality monitoring
      _qualityMonitorTimer?.cancel();
      _qualityMonitorTimer = null;

      _updateState(StreamingState.idle);
      _streamStartTime = null;

      print('[LiveAudioStreamingService] Audio streaming stopped');
      print('[LiveAudioStreamingService] Total bytes streamed: $_totalBytesStreamed');
      print('[LiveAudioStreamingService] Total chunks: $_sequenceNumber');
    } catch (e) {
      print('[LiveAudioStreamingService] Error stopping stream: $e');
      _updateState(StreamingState.error);
    }
  }

  /// Handle incoming audio chunks
  void _onAudioChunk(Uint8List chunk) {
    try {
      if (_currentState != StreamingState.streaming) return;

      // Track metadata
      _sequenceNumber++;
      _totalBytesStreamed += chunk.length;

      // Calculate timestamp offset from stream start
      final timestamp = DateTime.now();
      final offsetMs = _streamStartTime != null
          ? timestamp.difference(_streamStartTime!).inMilliseconds
          : 0;

      // Note: Chunk logging disabled to reduce console spam

      // Calculate audio level for quality monitoring
      _calculateAudioLevel(chunk);

      // Buffer chunks to meet AssemblyAI requirements (50-1000ms)
      _bufferAndForwardChunk(chunk);
    } catch (e) {
      print('[LiveAudioStreamingService] Error processing audio chunk: $e');
    }
  }

  /// Buffer small chunks and forward when minimum size is reached
  ///
  /// AssemblyAI Universal-Streaming v3 requires audio chunks between 50ms and 1000ms
  /// (1600 to 32000 bytes at 16kHz, 16-bit, mono)
  void _bufferAndForwardChunk(Uint8List chunk) {
    // Add chunk bytes to buffer
    _audioBuffer.addAll(chunk);

    // Forward buffer when it reaches target size (or max size)
    if (_audioBuffer.length >= _targetBufferSizeBytes || _audioBuffer.length >= _maxBufferSizeBytes) {
      // Create buffered chunk
      final bufferedChunk = Uint8List.fromList(_audioBuffer);
      final durationMs = (bufferedChunk.length / 32.0).toStringAsFixed(1); // bytes / (16000 * 2 / 1000)

      // Note: Buffered chunk logging disabled to reduce console spam

      // Forward to listeners (WebSocket service will send to backend)
      _audioChunkController.add(bufferedChunk);

      // Clear buffer
      _audioBuffer.clear();
    }
  }

  /// Handle stream errors
  void _onStreamError(Object error) {
    print('[LiveAudioStreamingService] Stream error: $error');
    _updateState(StreamingState.error);
  }

  /// Handle stream completion
  void _onStreamDone() {
    print('[LiveAudioStreamingService] Audio stream completed');
    _updateState(StreamingState.idle);
  }

  /// Calculate audio level from PCM data for quality monitoring
  void _calculateAudioLevel(Uint8List chunk) {
    try {
      // PCM 16-bit data: 2 bytes per sample
      if (chunk.length < 2) return;

      // Calculate RMS (Root Mean Square) amplitude
      double sum = 0;
      int sampleCount = 0;

      for (int i = 0; i < chunk.length - 1; i += 2) {
        // Read 16-bit sample (little-endian)
        final sample = (chunk[i + 1] << 8) | chunk[i];
        // Convert to signed 16-bit
        final signedSample = sample > 32767 ? sample - 65536 : sample;
        // Normalize to -1.0 to 1.0
        final normalized = signedSample / 32768.0;
        sum += normalized * normalized;
        sampleCount++;
      }

      if (sampleCount > 0) {
        final rms = (sum / sampleCount).abs();
        final amplitude = rms.clamp(0.0, 1.0);

        // Add to history
        _recentAmplitudes.add(amplitude);
        if (_recentAmplitudes.length > _amplitudeHistorySize) {
          _recentAmplitudes.removeAt(0);
        }
      }
    } catch (e) {
      print('[LiveAudioStreamingService] Error calculating audio level: $e');
    }
  }

  /// Start periodic quality monitoring
  void _startQualityMonitoring() {
    _qualityMonitorTimer?.cancel();
    _qualityMonitorTimer = Timer.periodic(
      const Duration(milliseconds: 500), // Check every 500ms
      (_) async {
        if (_currentState != StreamingState.streaming) return;

        try {
          // Get current amplitude from recorder
          final amplitudeData = await _recorder.getAmplitude();
          final currentAmplitude = amplitudeData.current.clamp(0.0, 1.0);

          // Calculate average amplitude from recent history
          final avgAmplitude = _recentAmplitudes.isEmpty
              ? 0.0
              : _recentAmplitudes.reduce((a, b) => a + b) / _recentAmplitudes.length;

          // Detect quality issues
          final isSilent = avgAmplitude < 0.01; // Very low audio level
          final isClipping = currentAmplitude > 0.95; // Audio too loud

          // Create metrics
          final metrics = AudioQualityMetrics(
            timestamp: DateTime.now(),
            currentAmplitude: currentAmplitude,
            averageAmplitude: avgAmplitude,
            isSilent: isSilent,
            isClipping: isClipping,
            bytesStreamed: _totalBytesStreamed,
            sequenceNumber: _sequenceNumber,
          );

          // Emit metrics
          _qualityController.add(metrics);

          // Note: Quality warnings disabled to reduce console spam
          // (quality metrics still available via qualityMetricsStream)
        } catch (e) {
          print('[LiveAudioStreamingService] Error in quality monitoring: $e');
        }
      },
    );
  }

  /// Update state and notify listeners
  void _updateState(StreamingState newState) {
    _currentState = newState;
    _stateController.add(newState);
  }

  /// Get streaming duration
  Duration getStreamingDuration() {
    if (_streamStartTime == null) return Duration.zero;
    return DateTime.now().difference(_streamStartTime!);
  }

  /// Get streaming statistics
  StreamingStatistics getStatistics() {
    return StreamingStatistics(
      duration: getStreamingDuration(),
      bytesStreamed: _totalBytesStreamed,
      chunksStreamed: _sequenceNumber,
      averageChunkSize: _sequenceNumber > 0 ? _totalBytesStreamed ~/ _sequenceNumber : 0,
      isStreaming: isStreaming,
    );
  }

  /// Dispose resources
  void dispose() {
    _audioStreamSubscription?.cancel();
    _qualityMonitorTimer?.cancel();
    _recorder.dispose();
    _audioChunkController.close();
    _qualityController.close();
    _stateController.close();
  }
}

/// Streaming state enum
enum StreamingState {
  idle,
  streaming,
  error,
}

/// Audio quality metrics
class AudioQualityMetrics {
  final DateTime timestamp;
  final double currentAmplitude;
  final double averageAmplitude;
  final bool isSilent;
  final bool isClipping;
  final int bytesStreamed;
  final int sequenceNumber;

  const AudioQualityMetrics({
    required this.timestamp,
    required this.currentAmplitude,
    required this.averageAmplitude,
    required this.isSilent,
    required this.isClipping,
    required this.bytesStreamed,
    required this.sequenceNumber,
  });

  @override
  String toString() {
    return 'AudioQualityMetrics('
        'timestamp: $timestamp, '
        'current: ${(currentAmplitude * 100).toStringAsFixed(1)}%, '
        'average: ${(averageAmplitude * 100).toStringAsFixed(1)}%, '
        'silent: $isSilent, '
        'clipping: $isClipping, '
        'bytes: $bytesStreamed, '
        'seq: $sequenceNumber'
        ')';
  }
}

/// Streaming statistics
class StreamingStatistics {
  final Duration duration;
  final int bytesStreamed;
  final int chunksStreamed;
  final int averageChunkSize;
  final bool isStreaming;

  const StreamingStatistics({
    required this.duration,
    required this.bytesStreamed,
    required this.chunksStreamed,
    required this.averageChunkSize,
    required this.isStreaming,
  });

  @override
  String toString() {
    return 'StreamingStatistics('
        'duration: ${duration.inSeconds}s, '
        'bytes: $bytesStreamed, '
        'chunks: $chunksStreamed, '
        'avgChunkSize: $averageChunkSize, '
        'streaming: $isStreaming'
        ')';
  }
}
