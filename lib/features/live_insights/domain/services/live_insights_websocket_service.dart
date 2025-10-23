import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/live_insight_model.dart';
import '../models/proactive_assistance_model.dart';
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
  bool _isDisconnecting = false;  // Flag to prevent reconnection during manual disconnect

  // Stream controllers for different message types
  final _insightsController =
      StreamController<InsightsExtractionResult>.broadcast();
  final _transcriptsController = StreamController<TranscriptChunk>.broadcast();
  final _metricsController = StreamController<SessionMetrics>.broadcast();
  final _sessionStateController = StreamController<String>.broadcast();
  final _errorController = StreamController<String>.broadcast();
  final _connectionStateController = StreamController<bool>.broadcast();
  final _proactiveAssistanceController =
      StreamController<List<ProactiveAssistanceModel>>.broadcast();

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
  Stream<List<ProactiveAssistanceModel>> get proactiveAssistanceStream =>
      _proactiveAssistanceController.stream;

  bool get isConnected => _isConnected;
  String? get sessionId => _sessionId;
  String? get projectId => _projectId;

  /// Inject a WebSocket channel for testing purposes
  @visibleForTesting
  void injectChannelForTesting(WebSocketChannel channel) {
    _channel = channel;
    _isConnected = true;
    _connectionStateController.add(true);  // Emit connection state for tests

    // Listen to messages
    _channel!.stream.listen(
      _handleMessage,
      onError: _handleError,
      onDone: _handleDisconnect,
      cancelOnError: false,
    );

    _connectionStateController.add(true);
  }

  /// Generate WebSocket URL with authentication token
  String _getWsUrl(String projectId, String? token) {
    final baseUrl = ApiConfig.baseUrl;
    final wsProtocol = baseUrl.startsWith('https') ? 'wss' : 'ws';
    final host = baseUrl.replaceAll(RegExp(r'^https?://'), '');

    // Add token as query parameter for WebSocket authentication
    final tokenParam = token != null ? '&token=$token' : '';
    return '$wsProtocol://$host/ws/live-insights?project_id=$projectId$tokenParam';
  }

  /// Connect to WebSocket server and initialize session
  ///
  /// [projectId] - The project ID to connect to
  /// [token] - Optional JWT authentication token. If not provided, will try to get from auth service.
  Future<void> connect(String projectId, {String? token}) async {
    if (_isConnecting) {
      debugPrint('[LiveInsightsWS] Connection already in progress');
      return;
    }

    if (_isConnected && _channel != null && _projectId == projectId) {
      debugPrint('[LiveInsightsWS] Already connected to project $projectId');
      return;
    }

    _isConnecting = true;
    _isDisconnecting = false;  // Reset flag when reconnecting intentionally
    _projectId = projectId;

    try {
      // Close existing connection if any
      if (_channel != null) {
        debugPrint('[LiveInsightsWS] Closing existing connection');
        await _channel!.sink.close();
        _channel = null;
        _isConnected = false;
      }

      final wsUrl = _getWsUrl(projectId, token);
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

  /// Send user feedback for proactive assistance
  Future<void> sendFeedback({
    required String insightId,
    required bool isHelpful,
    required String assistanceType,
    double? confidenceScore,
    String? feedbackText,
    String? feedbackCategory,
  }) async {
    if (!_isConnected) {
      debugPrint('[LiveInsightsWS] Cannot send feedback - not connected');
      return;
    }

    await _sendMessage({
      'action': 'feedback',
      'insight_id': insightId,
      'helpful': isHelpful,
      'assistance_type': assistanceType,
      if (confidenceScore != null) 'confidence_score': confidenceScore,
      if (feedbackText != null) 'feedback_text': feedbackText,
      if (feedbackCategory != null) 'feedback_category': feedbackCategory,
    });

    debugPrint(
      '[LiveInsightsWS] Sent ${isHelpful ? "positive" : "negative"} feedback '
      'for $assistanceType (insight_id=$insightId)'
    );
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

          debugPrint('📥 [LiveInsightsWS] ========================================');
          debugPrint('📥 [LiveInsightsWS] Received ${result.insights.length} new insights from chunk ${result.chunkIndex}');

          // Log each insight for debugging
          for (var insight in result.insights) {
            final content = insight.content ?? '';
            final preview = content.length > 50 ? content.substring(0, 50) : content;
            debugPrint('📥 [LiveInsightsWS]   - ${insight.type}: $preview...');
          }

          debugPrint('📥 [LiveInsightsWS] Adding to stream controller...');
          _insightsController.add(result);
          debugPrint('📥 [LiveInsightsWS] Insight added to stream! Has listeners: ${_insightsController.hasListener}');
          debugPrint('📥 [LiveInsightsWS] ========================================');

          // PHASE 1: Handle proactive assistance (auto-answers, etc.)
          if (data.containsKey('proactive_assistance')) {
            final assistanceList = data['proactive_assistance'] as List;
            if (assistanceList.isNotEmpty) {
              try {
                final assistance = assistanceList
                    .map((item) => ProactiveAssistanceModel.fromJson(
                        item as Map<String, dynamic>))
                    .toList();
                _proactiveAssistanceController.add(assistance);
                debugPrint(
                  '[LiveInsightsWS] Received ${assistance.length} proactive assistance items',
                );
              } catch (e) {
                debugPrint('[LiveInsightsWS] Error parsing proactive assistance: $e');
              }
            }
          }
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
          // Backend sends nested structure:
          // { type, session_id, insights: {...}, metrics: {...} }
          // Extract the nested 'insights' object and merge with metrics at top level
          final insightsData = data['insights'] as Map<String, dynamic>? ?? {};
          final metricsData = data['metrics'] as Map<String, dynamic>? ?? {};
          final flattenedData = {
            ...insightsData,  // Contains: session_id, total_insights, insights_by_type, insights
            'metrics': metricsData,
          };
          final finalResult = SessionFinalizedResult.fromJson(flattenedData);
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

    // Only schedule reconnection if this is NOT a manual disconnect
    if (!_isDisconnecting) {
      _scheduleReconnect();
    } else {
      debugPrint('[LiveInsightsWS] Manual disconnect - not scheduling reconnection');
    }
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

    // Set flag to prevent reconnection
    _isDisconnecting = true;

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
    await _proactiveAssistanceController.close();

    debugPrint('[LiveInsightsWS] Service disposed');
  }
}
