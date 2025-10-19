import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/live_insight_model.dart';
import '../../../../core/config/api_config.dart';

/// Service for managing WebSocket connection for live meeting insights.
///
/// Handles:
/// - WebSocket connection lifecycle
/// - Audio chunk streaming
/// - Real-time insight reception
/// - Session management
/// - Automatic reconnection
class LiveInsightsWebSocketService {
  WebSocketChannel? _channel;
  String? _sessionId;
  String? _projectId;
  bool _isConnected = false;
  bool _isConnecting = false;

  // Stream controllers for different message types
  final _insightsController =
      StreamController<InsightsExtractionResult>.broadcast();
  final _transcriptsController = StreamController<TranscriptChunk>.broadcast();
  final _metricsController = StreamController<SessionMetrics>.broadcast();
  final _sessionStateController = StreamController<String>.broadcast();
  final _errorController = StreamController<String>.broadcast();
  final _connectionStateController = StreamController<bool>.broadcast();

  // Reconnection settings
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 3);
  static const Duration _pingInterval = Duration(seconds: 30);

  // Getters for streams
  Stream<InsightsExtractionResult> get insightsStream =>
      _insightsController.stream;
  Stream<TranscriptChunk> get transcriptsStream =>
      _transcriptsController.stream;
  Stream<SessionMetrics> get metricsStream => _metricsController.stream;
  Stream<String> get sessionStateStream => _sessionStateController.stream;
  Stream<String> get errorStream => _errorController.stream;
  Stream<bool> get connectionStateStream => _connectionStateController.stream;

  bool get isConnected => _isConnected;
  String? get sessionId => _sessionId;
  String? get projectId => _projectId;

  /// Generate WebSocket URL
  String _getWsUrl(String projectId) {
    final baseUrl = ApiConfig.baseUrl;
    final wsProtocol = baseUrl.startsWith('https') ? 'wss' : 'ws';
    final host = baseUrl.replaceAll(RegExp(r'^https?://'), '');
    return '$wsProtocol://$host/ws/live-insights?project_id=$projectId';
  }

  /// Connect to WebSocket server and initialize session
  Future<void> connect(String projectId) async {
    if (_isConnecting) {
      debugPrint('[LiveInsightsWS] Connection already in progress');
      return;
    }

    if (_isConnected && _channel != null && _projectId == projectId) {
      debugPrint('[LiveInsightsWS] Already connected to project $projectId');
      return;
    }

    _isConnecting = true;
    _projectId = projectId;

    try {
      // Close existing connection if any
      if (_channel != null) {
        debugPrint('[LiveInsightsWS] Closing existing connection');
        await _channel!.sink.close();
        _channel = null;
        _isConnected = false;
      }

      final wsUrl = _getWsUrl(projectId);
      debugPrint('[LiveInsightsWS] Connecting to $wsUrl');

      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      // Listen to messages
      _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnect,
        cancelOnError: false,
      );

      _isConnected = true;
      _reconnectAttempts = 0;
      _connectionStateController.add(true);

      // Send initialization message
      await _sendInit(projectId);

      // Start ping timer for keepalive
      _startPingTimer();

      debugPrint('[LiveInsightsWS] Connected successfully');
    } catch (e) {
      debugPrint('[LiveInsightsWS] Connection failed: $e');
      _isConnected = false;
      _connectionStateController.add(false);
      _errorController.add('Failed to connect: $e');
      _handleError(e);
    } finally {
      _isConnecting = false;
    }
  }

  /// Send initialization message
  Future<void> _sendInit(String projectId) async {
    await _sendMessage({
      'action': 'init',
      'project_id': projectId,
    });
  }

  /// Send audio chunk for transcription and insight extraction
  Future<void> sendAudioChunk({
    required String audioData,
    required double duration,
    String? speaker,
  }) async {
    if (!_isConnected) {
      debugPrint('[LiveInsightsWS] Not connected, cannot send audio chunk');
      return;
    }

    await _sendMessage({
      'action': 'audio_chunk',
      'data': audioData,
      'duration': duration,
      'speaker': speaker,
    });
  }

  /// Pause the meeting session
  Future<void> pauseSession() async {
    if (!_isConnected) return;

    await _sendMessage({'action': 'pause'});
    _sessionStateController.add('paused');
  }

  /// Resume the meeting session
  Future<void> resumeSession() async {
    if (!_isConnected) return;

    await _sendMessage({'action': 'resume'});
    _sessionStateController.add('active');
  }

  /// End the meeting session and finalize insights
  Future<void> endSession() async {
    if (!_isConnected) return;

    await _sendMessage({'action': 'end'});
    _sessionStateController.add('finalizing');
  }

  /// Send ping message for keepalive
  void _sendPing() {
    if (_isConnected) {
      _sendMessage({'action': 'ping'});
    }
  }

  /// Send JSON message to server
  Future<void> _sendMessage(Map<String, dynamic> message) async {
    if (_channel == null) return;

    try {
      final json = jsonEncode(message);
      _channel!.sink.add(json);
    } catch (e) {
      debugPrint('[LiveInsightsWS] Error sending message: $e');
      _errorController.add('Failed to send message: $e');
    }
  }

  /// Handle incoming WebSocket messages
  void _handleMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String) as Map<String, dynamic>;
      final liveMessage = LiveInsightMessage.fromJson(data);

      debugPrint('[LiveInsightsWS] Received message: ${liveMessage.type}');

      switch (liveMessage.type) {
        case LiveInsightMessageType.sessionInitialized:
          _sessionId = liveMessage.sessionId;
          _sessionStateController.add('initialized');
          debugPrint(
            '[LiveInsightsWS] Session initialized: $_sessionId',
          );
          break;

        case LiveInsightMessageType.transcriptChunk:
          final transcript = TranscriptChunk.fromJson(data);
          _transcriptsController.add(transcript);
          break;

        case LiveInsightMessageType.insightsExtracted:
          final result = InsightsExtractionResult.fromJson(data);
          _insightsController.add(result);
          debugPrint(
            '[LiveInsightsWS] Received ${result.insights.length} new insights',
          );
          break;

        case LiveInsightMessageType.metricsUpdate:
          final metrics = SessionMetrics.fromJson(
            data['metrics'] as Map<String, dynamic>,
          );
          _metricsController.add(metrics);
          break;

        case LiveInsightMessageType.sessionPaused:
          _sessionStateController.add('paused');
          break;

        case LiveInsightMessageType.sessionResumed:
          _sessionStateController.add('active');
          break;

        case LiveInsightMessageType.sessionFinalized:
          final finalResult = SessionFinalizedResult.fromJson(data);
          _sessionStateController.add('completed');
          debugPrint(
            '[LiveInsightsWS] Session finalized: ${finalResult.totalInsights} total insights',
          );
          break;

        case LiveInsightMessageType.error:
          final errorMsg = liveMessage.message ?? 'Unknown error';
          _errorController.add(errorMsg);
          debugPrint('[LiveInsightsWS] Server error: $errorMsg');
          break;

        case LiveInsightMessageType.pong:
          // Heartbeat response
          break;
      }
    } catch (e) {
      debugPrint('[LiveInsightsWS] Error handling message: $e');
      _errorController.add('Failed to process message: $e');
    }
  }

  /// Handle WebSocket errors
  void _handleError(dynamic error) {
    debugPrint('[LiveInsightsWS] WebSocket error: $error');
    _errorController.add('Connection error: $error');
    _handleDisconnect();
  }

  /// Handle WebSocket disconnect
  void _handleDisconnect() {
    if (!_isConnected) return;

    debugPrint('[LiveInsightsWS] Disconnected');
    _isConnected = false;
    _connectionStateController.add(false);
    _cancelPingTimer();
    _scheduleReconnect();
  }

  /// Schedule reconnection attempt
  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('[LiveInsightsWS] Max reconnection attempts reached');
      _errorController.add('Connection lost. Max retry attempts reached.');
      return;
    }

    _cancelReconnectTimer();
    _reconnectAttempts++;

    debugPrint(
      '[LiveInsightsWS] Scheduling reconnect attempt $_reconnectAttempts/$_maxReconnectAttempts',
    );

    _reconnectTimer = Timer(_reconnectDelay, () async {
      if (!_isConnected && _projectId != null) {
        await connect(_projectId!);
      }
    });
  }

  /// Cancel reconnection timer
  void _cancelReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  /// Start ping timer for keepalive
  void _startPingTimer() {
    _cancelPingTimer();

    _pingTimer = Timer.periodic(_pingInterval, (_) {
      if (_isConnected) {
        _sendPing();
      }
    });
  }

  /// Cancel ping timer
  void _cancelPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = null;
  }

  /// Disconnect from WebSocket server
  Future<void> disconnect() async {
    debugPrint('[LiveInsightsWS] Disconnecting...');

    _cancelReconnectTimer();
    _cancelPingTimer();

    if (_channel != null) {
      await _channel!.sink.close();
      _channel = null;
    }

    _isConnected = false;
    _isConnecting = false;
    _sessionId = null;
    _projectId = null;
    _reconnectAttempts = 0;

    _connectionStateController.add(false);
  }

  /// Clean up resources
  Future<void> dispose() async {
    debugPrint('[LiveInsightsWS] Disposing service...');

    await disconnect();

    await _insightsController.close();
    await _transcriptsController.close();
    await _metricsController.close();
    await _sessionStateController.close();
    await _errorController.close();
    await _connectionStateController.close();

    debugPrint('[LiveInsightsWS] Service disposed');
  }
}
