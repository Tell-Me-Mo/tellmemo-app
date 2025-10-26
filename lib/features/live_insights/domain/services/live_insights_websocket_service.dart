import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter/foundation.dart';
import '../../data/models/live_insight_model.dart';
import '../../../../core/config/api_config.dart';
import '../../../../core/services/auth_service.dart';

/// Service for managing WebSocket connection to live meeting insights backend
/// Handles real-time questions and actions during live meetings
class LiveInsightsWebSocketService {
  WebSocketChannel? _channel;
  String? _sessionId;
  bool _isConnected = false;
  bool _isConnecting = false;

  // Stream controllers for live insights updates
  final _questionsController = StreamController<LiveQuestion>.broadcast();
  final _actionsController = StreamController<LiveAction>.broadcast();
  final _transcriptionsController = StreamController<TranscriptSegment>.broadcast();
  final _connectionStateController = StreamController<bool>.broadcast();

  // Reconnection settings
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 3);

  // Ping/pong for keepalive
  Timer? _pingTimer;
  static const Duration _pingInterval = Duration(seconds: 30);

  // Streams
  Stream<LiveQuestion> get questionUpdates => _questionsController.stream;
  Stream<LiveAction> get actionUpdates => _actionsController.stream;
  Stream<TranscriptSegment> get transcriptionUpdates =>
      _transcriptionsController.stream;
  Stream<bool> get connectionState => _connectionStateController.stream;
  bool get isConnected => _isConnected;

  // Generate WebSocket URL
  String _getWsUrl(String sessionId, String token) {
    final baseUrl = ApiConfig.baseUrl;
    final wsProtocol = baseUrl.startsWith('https') ? 'wss' : 'ws';
    final host = baseUrl.replaceAll(RegExp(r'^https?://'), '');
    return '$wsProtocol://$host/ws/live-insights/$sessionId?token=$token';
  }

  /// Connect to WebSocket server for a specific session
  Future<void> connect(String sessionId) async {
    // Prevent concurrent connection attempts
    if (_isConnecting) {
      debugPrint(
          '[LiveInsightsWebSocket] Connection already in progress, skipping');
      return;
    }

    // If already connected to same session, skip
    if (_isConnected && _sessionId == sessionId && _channel != null) {
      debugPrint(
          '[LiveInsightsWebSocket] Already connected to session $sessionId, skipping');
      return;
    }

    _isConnecting = true;

    try {
      // Close old connection if exists
      if (_channel != null) {
        debugPrint(
            '[LiveInsightsWebSocket] Closing existing connection before reconnecting');
        await _channel!.sink.close();
        _channel = null;
        _isConnected = false;
      }

      _sessionId = sessionId;

      // Get JWT token from auth service
      final authService = AuthService();
      final token = await authService.getToken();
      if (token == null) {
        throw Exception('No authentication token available');
      }

      final wsUrl = _getWsUrl(sessionId, token);
      debugPrint('[LiveInsightsWebSocket] Connecting to $wsUrl');

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

      // Start ping timer for keepalive
      _startPingTimer();

      debugPrint('[LiveInsightsWebSocket] Connected successfully');
    } catch (e) {
      debugPrint('[LiveInsightsWebSocket] Connection failed: $e');
      _isConnected = false;
      _handleError(e);
    } finally {
      _isConnecting = false;
    }
  }

  /// Handle incoming WebSocket messages
  void _handleMessage(dynamic message) {
    try {
      final data = json.decode(message as String) as Map<String, dynamic>;
      final type = data['type'] as String?;

      debugPrint('[LiveInsightsWebSocket] Received message type: $type');

      switch (type) {
        case 'QUESTION_DETECTED':
        case 'RAG_RESULT':
        case 'ANSWER_FROM_MEETING':
        case 'QUESTION_ANSWERED_LIVE':
        case 'GPT_GENERATED_ANSWER':
        case 'QUESTION_UNANSWERED':
          _handleQuestionUpdate(data);
          break;

        case 'ACTION_TRACKED':
        case 'ACTION_UPDATED':
        case 'ACTION_ALERT':
          _handleActionUpdate(data);
          break;

        case 'TRANSCRIPTION_PARTIAL':
        case 'TRANSCRIPTION_FINAL':
          _handleTranscriptionUpdate(data);
          break;

        case 'SYNC_STATE':
          _handleSyncState(data);
          break;

        case 'pong':
          // Keepalive response
          debugPrint('[LiveInsightsWebSocket] Received pong');
          break;

        default:
          debugPrint(
              '[LiveInsightsWebSocket] Unknown message type: $type');
      }
    } catch (e) {
      debugPrint('[LiveInsightsWebSocket] Error parsing message: $e');
    }
  }

  /// Handle question update events
  void _handleQuestionUpdate(Map<String, dynamic> data) {
    try {
      final question = LiveQuestion.fromJson(data['question'] as Map<String, dynamic>);
      _questionsController.add(question);
      debugPrint(
          '[LiveInsightsWebSocket] Question update: ${question.id} - ${question.status}');
    } catch (e) {
      debugPrint('[LiveInsightsWebSocket] Error parsing question: $e');
    }
  }

  /// Handle action update events
  void _handleActionUpdate(Map<String, dynamic> data) {
    try {
      final action = LiveAction.fromJson(data['action'] as Map<String, dynamic>);
      _actionsController.add(action);
      debugPrint(
          '[LiveInsightsWebSocket] Action update: ${action.id} - ${action.status}');
    } catch (e) {
      debugPrint('[LiveInsightsWebSocket] Error parsing action: $e');
    }
  }

  /// Handle transcription update events
  void _handleTranscriptionUpdate(Map<String, dynamic> data) {
    try {
      final transcription = TranscriptSegment.fromJson(
          data['transcript'] as Map<String, dynamic>);
      _transcriptionsController.add(transcription);
    } catch (e) {
      debugPrint('[LiveInsightsWebSocket] Error parsing transcription: $e');
    }
  }

  /// Handle state synchronization on reconnect
  void _handleSyncState(Map<String, dynamic> data) {
    try {
      // Parse questions
      final questions = (data['questions'] as List<dynamic>?)
          ?.map((q) => LiveQuestion.fromJson(q as Map<String, dynamic>))
          .toList();

      // Parse actions
      final actions = (data['actions'] as List<dynamic>?)
          ?.map((a) => LiveAction.fromJson(a as Map<String, dynamic>))
          .toList();

      debugPrint(
          '[LiveInsightsWebSocket] State sync: ${questions?.length ?? 0} questions, ${actions?.length ?? 0} actions');

      // Emit all questions and actions
      if (questions != null) {
        for (final question in questions) {
          _questionsController.add(question);
        }
      }

      if (actions != null) {
        for (final action in actions) {
          _actionsController.add(action);
        }
      }
    } catch (e) {
      debugPrint('[LiveInsightsWebSocket] Error parsing sync state: $e');
    }
  }

  /// Handle connection errors
  void _handleError(dynamic error) {
    debugPrint('[LiveInsightsWebSocket] Error: $error');
    _isConnected = false;
    _connectionStateController.add(false);

    // Attempt reconnection with exponential backoff
    if (_reconnectAttempts < _maxReconnectAttempts) {
      _reconnectAttempts++;
      final delay = _reconnectDelay * _reconnectAttempts;

      debugPrint(
          '[LiveInsightsWebSocket] Reconnecting in ${delay.inSeconds}s (attempt $_reconnectAttempts/$_maxReconnectAttempts)');

      _reconnectTimer?.cancel();
      _reconnectTimer = Timer(delay, () {
        if (_sessionId != null) {
          connect(_sessionId!);
        }
      });
    } else {
      debugPrint(
          '[LiveInsightsWebSocket] Max reconnection attempts reached');
    }
  }

  /// Handle WebSocket disconnection
  void _handleDisconnect() {
    debugPrint('[LiveInsightsWebSocket] Disconnected');
    _isConnected = false;
    _connectionStateController.add(false);
    _pingTimer?.cancel();

    // Attempt reconnection
    _handleError('Connection closed');
  }

  /// Start ping timer for keepalive
  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(_pingInterval, (timer) {
      if (_isConnected && _channel != null) {
        _sendMessage({'type': 'ping'});
      }
    });
  }

  /// Send message to server
  void _sendMessage(Map<String, dynamic> message) {
    if (_isConnected && _channel != null) {
      try {
        _channel!.sink.add(json.encode(message));
      } catch (e) {
        debugPrint('[LiveInsightsWebSocket] Error sending message: $e');
      }
    } else {
      debugPrint('[LiveInsightsWebSocket] Cannot send message: not connected');
    }
  }

  /// Send user feedback to backend
  Future<void> markQuestionAsAnswered(String questionId) async {
    _sendMessage({
      'type': 'USER_FEEDBACK',
      'action': 'mark_answered',
      'question_id': questionId,
    });
  }

  Future<void> markQuestionNeedsFollowUp(String questionId) async {
    _sendMessage({
      'type': 'USER_FEEDBACK',
      'action': 'needs_followup',
      'question_id': questionId,
    });
  }

  Future<void> dismissQuestion(String questionId) async {
    _sendMessage({
      'type': 'USER_FEEDBACK',
      'action': 'dismiss_question',
      'question_id': questionId,
    });
  }

  Future<void> assignAction(
      String actionId, String owner, DateTime? deadline) async {
    _sendMessage({
      'type': 'USER_FEEDBACK',
      'action': 'assign_action',
      'action_id': actionId,
      'owner': owner,
      'deadline': deadline?.toIso8601String(),
    });
  }

  Future<void> markActionComplete(String actionId) async {
    _sendMessage({
      'type': 'USER_FEEDBACK',
      'action': 'mark_complete',
      'action_id': actionId,
    });
  }

  Future<void> dismissAction(String actionId) async {
    _sendMessage({
      'type': 'USER_FEEDBACK',
      'action': 'dismiss_action',
      'action_id': actionId,
    });
  }

  /// Disconnect and cleanup
  Future<void> dispose() async {
    debugPrint('[LiveInsightsWebSocket] Disposing service');

    _reconnectTimer?.cancel();
    _pingTimer?.cancel();

    if (_channel != null) {
      await _channel!.sink.close();
      _channel = null;
    }

    _isConnected = false;
    _sessionId = null;
    _reconnectAttempts = 0;

    await _questionsController.close();
    await _actionsController.close();
    await _transcriptionsController.close();
    await _connectionStateController.close();
  }
}
