import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:web_socket_channel/web_socket_channel.dart';

/// WebSocket service for streaming audio to backend for real-time transcription.
///
/// This service:
/// - Connects to backend WebSocket endpoint: /ws/live-insights/{session_id}
/// - Sends binary audio chunks (Uint8List) to backend
/// - Receives transcription events (partial/final) from backend
/// - Handles reconnection with exponential backoff
/// - Maintains session state synchronization
///
/// Backend forwards audio to AssemblyAI for real-time transcription.
class LiveAudioWebSocketService {
  WebSocketChannel? _channel;
  StreamSubscription? _messageSubscription;

  // Configuration
  final String baseUrl;
  String? _sessionId;
  String? _token;

  // State
  final StreamController<TranscriptionEvent> _transcriptionController =
      StreamController<TranscriptionEvent>.broadcast();
  final StreamController<ConnectionState> _stateController =
      StreamController<ConnectionState>.broadcast();

  ConnectionState _currentState = ConnectionState.disconnected;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;

  // Statistics
  int _audioChunksSent = 0;
  int _totalAudioBytesSent = 0;
  DateTime? _connectionStartTime;

  // Getters
  Stream<TranscriptionEvent> get transcriptionStream => _transcriptionController.stream;
  Stream<ConnectionState> get stateStream => _stateController.stream;
  ConnectionState get currentState => _currentState;
  bool get isConnected => _currentState == ConnectionState.connected;
  int get audioChunksSent => _audioChunksSent;
  int get totalAudioBytesSent => _totalAudioBytesSent;

  LiveAudioWebSocketService({required this.baseUrl});

  /// Connect to backend WebSocket for live audio streaming
  ///
  /// [sessionId] - Recording session ID (matches recording_id)
  /// [token] - JWT authentication token
  /// [projectId] - Project ID for context
  Future<bool> connect({
    required String sessionId,
    required String token,
    String? projectId,
  }) async {
    try {
      if (isConnected) {
        print('[LiveAudioWebSocketService] Already connected');
        return true;
      }

      _sessionId = sessionId;
      _token = token;

      // Construct WebSocket URL
      final wsUrl = _buildWebSocketUrl(sessionId, token);
      print('[LiveAudioWebSocketService] Connecting to: $wsUrl');

      _updateState(ConnectionState.connecting);

      // Create WebSocket channel (uses platform-appropriate implementation)
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      // Wait for connection to establish
      await _channel!.ready;

      _connectionStartTime = DateTime.now();
      _audioChunksSent = 0;
      _totalAudioBytesSent = 0;
      _reconnectAttempts = 0;

      // Listen for incoming messages
      _messageSubscription = _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );

      // Start heartbeat
      _startHeartbeat();

      _updateState(ConnectionState.connected);
      print('[LiveAudioWebSocketService] Connected successfully');

      return true;
    } catch (e) {
      print('[LiveAudioWebSocketService] Connection failed: $e');
      _updateState(ConnectionState.error);
      _attemptReconnect();
      return false;
    }
  }

  /// Disconnect from WebSocket
  Future<void> disconnect() async {
    try {
      print('[LiveAudioWebSocketService] Disconnecting...');

      _reconnectTimer?.cancel();
      _heartbeatTimer?.cancel();
      _messageSubscription?.cancel();

      await _channel?.sink.close();
      _channel = null;

      _updateState(ConnectionState.disconnected);
      _sessionId = null;
      _token = null;

      print('[LiveAudioWebSocketService] Disconnected');
      print('[LiveAudioWebSocketService] Session stats:');
      print('  - Audio chunks sent: $_audioChunksSent');
      print('  - Total bytes sent: $_totalAudioBytesSent');
    } catch (e) {
      print('[LiveAudioWebSocketService] Error during disconnect: $e');
    }
  }

  /// Send binary audio chunk to backend
  ///
  /// Audio format: PCM 16kHz, 16-bit, mono
  /// Chunk size: typically 1600-3200 bytes (100-200ms)
  Future<void> sendAudioChunk(Uint8List audioData) async {
    if (!isConnected || _channel == null) {
      print('[LiveAudioWebSocketService] Cannot send audio - not connected');
      return;
    }

    try {
      // Send binary frame
      _channel!.sink.add(audioData);

      _audioChunksSent++;
      _totalAudioBytesSent += audioData.length;

      // Log periodically (every 100 chunks)
      if (_audioChunksSent % 100 == 0) {
        print('[LiveAudioWebSocketService] Audio chunks sent: $_audioChunksSent, '
            'total bytes: $_totalAudioBytesSent');
      }
    } catch (e) {
      print('[LiveAudioWebSocketService] Error sending audio chunk: $e');
      _updateState(ConnectionState.error);
      _attemptReconnect();
    }
  }

  /// Send JSON message (for user feedback, control messages)
  Future<void> sendMessage(Map<String, dynamic> message) async {
    if (!isConnected || _channel == null) {
      print('[LiveAudioWebSocketService] Cannot send message - not connected');
      return;
    }

    try {
      final jsonStr = json.encode(message);
      _channel!.sink.add(jsonStr);
    } catch (e) {
      print('[LiveAudioWebSocketService] Error sending message: $e');
    }
  }

  /// Handle incoming messages from backend
  void _onMessage(dynamic message) {
    try {
      // Check message type
      if (message is String) {
        // JSON message (transcription events, sync state, etc.)
        _handleJsonMessage(message);
      } else if (message is List<int>) {
        // Binary message (not expected from backend, but handle gracefully)
        print('[LiveAudioWebSocketService] Received unexpected binary message: ${message.length} bytes');
      }
    } catch (e) {
      print('[LiveAudioWebSocketService] Error handling message: $e');
    }
  }

  /// Handle JSON messages
  void _handleJsonMessage(String jsonStr) {
    try {
      final data = json.decode(jsonStr) as Map<String, dynamic>;
      final messageType = data['type'] as String?;

      if (messageType == null) {
        print('[LiveAudioWebSocketService] Received message without type: $jsonStr');
        return;
      }

      switch (messageType) {
        case 'TRANSCRIPTION_PARTIAL':
          _handleTranscriptionPartial(data);
          break;
        case 'TRANSCRIPTION_FINAL':
          _handleTranscriptionFinal(data);
          break;
        case 'QUESTION_DETECTED':
        case 'RAG_RESULT':
        case 'ANSWER_FROM_MEETING':
        case 'QUESTION_ANSWERED_LIVE':
        case 'GPT_GENERATED_ANSWER':
        case 'ACTION_TRACKED':
        case 'ACTION_UPDATED':
        case 'SYNC_STATE':
          // Forward to live insights provider (handled separately)
          print('[LiveAudioWebSocketService] Received $messageType event');
          break;
        case 'pong':
          // Heartbeat response
          break;
        default:
          print('[LiveAudioWebSocketService] Unknown message type: $messageType');
      }
    } catch (e) {
      print('[LiveAudioWebSocketService] Error parsing JSON message: $e');
    }
  }

  /// Handle partial transcription (real-time, unstable)
  void _handleTranscriptionPartial(Map<String, dynamic> data) {
    try {
      final event = TranscriptionEvent(
        type: TranscriptionType.partial,
        text: data['text'] as String,
        speaker: data['speaker'] as String?,
        timestamp: DateTime.parse(data['timestamp'] as String),
        confidence: (data['confidence'] as num?)?.toDouble(),
        startTime: (data['start_time'] as num?)?.toInt(),
        endTime: (data['end_time'] as num?)?.toInt(),
      );

      _transcriptionController.add(event);
    } catch (e) {
      print('[LiveAudioWebSocketService] Error handling partial transcription: $e');
    }
  }

  /// Handle final transcription (stable, after ~2s delay)
  void _handleTranscriptionFinal(Map<String, dynamic> data) {
    try {
      final event = TranscriptionEvent(
        type: TranscriptionType.final_,
        text: data['text'] as String,
        speaker: data['speaker'] as String?,
        timestamp: DateTime.parse(data['timestamp'] as String),
        confidence: (data['confidence'] as num?)?.toDouble(),
        startTime: (data['start_time'] as num?)?.toInt(),
        endTime: (data['end_time'] as num?)?.toInt(),
      );

      _transcriptionController.add(event);
    } catch (e) {
      print('[LiveAudioWebSocketService] Error handling final transcription: $e');
    }
  }

  /// Handle connection errors
  void _onError(Object error) {
    print('[LiveAudioWebSocketService] WebSocket error: $error');
    _updateState(ConnectionState.error);
    _attemptReconnect();
  }

  /// Handle connection close
  void _onDone() {
    print('[LiveAudioWebSocketService] WebSocket connection closed');
    _updateState(ConnectionState.disconnected);
    _attemptReconnect();
  }

  /// Attempt to reconnect with exponential backoff
  void _attemptReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      print('[LiveAudioWebSocketService] Max reconnect attempts reached');
      _updateState(ConnectionState.failed);
      return;
    }

    if (_sessionId == null || _token == null) {
      print('[LiveAudioWebSocketService] Cannot reconnect - missing session ID or token');
      return;
    }

    _reconnectAttempts++;
    final delay = Duration(seconds: (1 << (_reconnectAttempts - 1)).clamp(1, 30)); // 1s, 2s, 4s, 8s, 16s, 30s

    print('[LiveAudioWebSocketService] Reconnecting in ${delay.inSeconds}s (attempt $_reconnectAttempts/$_maxReconnectAttempts)');

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      connect(sessionId: _sessionId!, token: _token!);
    });
  }

  /// Start periodic heartbeat (ping/pong)
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (isConnected) {
        sendMessage({'type': 'ping'});
      }
    });
  }

  /// Build WebSocket URL
  String _buildWebSocketUrl(String sessionId, String token) {
    // Convert http(s) to ws(s)
    var wsBaseUrl = baseUrl.replaceFirst('http://', 'ws://').replaceFirst('https://', 'wss://');

    // Remove trailing slash
    if (wsBaseUrl.endsWith('/')) {
      wsBaseUrl = wsBaseUrl.substring(0, wsBaseUrl.length - 1);
    }

    return '$wsBaseUrl/ws/audio-stream/$sessionId?token=$token';
  }

  /// Update state and notify listeners
  void _updateState(ConnectionState newState) {
    _currentState = newState;
    _stateController.add(newState);
  }

  /// Get connection statistics
  ConnectionStatistics getStatistics() {
    return ConnectionStatistics(
      state: _currentState,
      audioChunksSent: _audioChunksSent,
      totalBytesSent: _totalAudioBytesSent,
      connectionDuration: _connectionStartTime != null
          ? DateTime.now().difference(_connectionStartTime!)
          : Duration.zero,
      reconnectAttempts: _reconnectAttempts,
    );
  }

  /// Dispose resources
  void dispose() {
    disconnect();
    _transcriptionController.close();
    _stateController.close();
  }
}

/// WebSocket connection state
enum ConnectionState {
  disconnected,
  connecting,
  connected,
  error,
  failed, // Max reconnect attempts reached
}

/// Transcription event from backend
class TranscriptionEvent {
  final TranscriptionType type;
  final String text;
  final String? speaker;
  final DateTime timestamp;
  final double? confidence;
  final int? startTime; // ms
  final int? endTime;   // ms

  const TranscriptionEvent({
    required this.type,
    required this.text,
    this.speaker,
    required this.timestamp,
    this.confidence,
    this.startTime,
    this.endTime,
  });

  @override
  String toString() {
    return 'TranscriptionEvent('
        'type: $type, '
        'text: "$text", '
        'speaker: $speaker, '
        'confidence: ${confidence?.toStringAsFixed(2)}'
        ')';
  }
}

/// Transcription type
enum TranscriptionType {
  partial,  // Real-time, unstable
  final_,   // Stable, final
}

/// Connection statistics
class ConnectionStatistics {
  final ConnectionState state;
  final int audioChunksSent;
  final int totalBytesSent;
  final Duration connectionDuration;
  final int reconnectAttempts;

  const ConnectionStatistics({
    required this.state,
    required this.audioChunksSent,
    required this.totalBytesSent,
    required this.connectionDuration,
    required this.reconnectAttempts,
  });

  @override
  String toString() {
    return 'ConnectionStatistics('
        'state: $state, '
        'chunks: $audioChunksSent, '
        'bytes: $totalBytesSent, '
        'duration: ${connectionDuration.inSeconds}s, '
        'reconnects: $reconnectAttempts'
        ')';
  }
}
