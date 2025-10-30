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
  bool _intentionalDisconnect = false; // Track if disconnect was intentional

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
  Future<void> connect(String sessionId, {List<String>? enabledTiers}) async {
    // Reset intentional disconnect flag when reconnecting
    _intentionalDisconnect = false;

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

      // Send tier configuration if provided
      if (enabledTiers != null && enabledTiers.isNotEmpty) {
        _sendMessage({
          'type': 'SET_TIER_CONFIG',
          'enabled_tiers': enabledTiers,
        });
        debugPrint('[LiveInsightsWebSocket] Sent tier configuration: $enabledTiers');
      }

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
        case 'RAG_RESULT_PROGRESSIVE':
        case 'RAG_RESULT_COMPLETE':
        case 'GPT_GENERATED_ANSWER':
          _handleQuestionUpdate(data);
          break;

        case 'QUESTION_MONITORING':
          _handleQuestionMonitoring(data);
          break;

        case 'QUESTION_UNANSWERED':
          _handleQuestionUnanswered(data);
          break;

        case 'ANSWER_DETECTED':
          _handleAnswerDetected(data);
          break;

        case 'ANSWER_FROM_MEETING':
          _handleAnswerFromMeeting(data);
          break;

        case 'QUESTION_ANSWERED_LIVE':
          _handleQuestionAnsweredLive(data);
          break;

        case 'ANSWER_DETECTED_ENRICHED':
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

        case 'SEGMENT_TRANSITION':
          // Segment transition events for meeting phase detection
          debugPrint('[LiveInsightsWebSocket] Segment transition: $data');
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

  /// Handle QUESTION_MONITORING event (just metadata, not full question)
  /// This is a lightweight notification that Tier 3 (live conversation monitoring) has started.
  /// The full question object with tier results will come via ANSWER_DETECTED_ENRICHED.
  void _handleQuestionMonitoring(Map<String, dynamic> data) {
    debugPrint('[LiveInsightsWebSocket] ✅ ENTERED _handleQuestionMonitoring handler');
    try {
      final monitoringData = data['data'] as Map<String, dynamic>;
      final questionId = monitoringData['question_id'] as String;
      final monitoringTimeout = monitoringData['monitoring_timeout'] as int?;

      debugPrint(
        '[LiveInsightsWebSocket] Question $questionId is being monitored for live answers '
        '(timeout: ${monitoringTimeout}s)'
      );

      // Note: This is an informational event only. The backend will send
      // ANSWER_DETECTED_ENRICHED when an answer is found, which contains
      // the full question object with tier results. We don't need to emit
      // anything here since the question was already created via QUESTION_DETECTED.
    } catch (e) {
      debugPrint('[LiveInsightsWebSocket] Error handling question monitoring: $e');
    }
  }

  /// Handle ANSWER_DETECTED event (lightweight answer notification)
  /// This is Phase 1 of the two-phase answer broadcast pattern for fast UX feedback.
  /// Phase 2 (ANSWER_DETECTED_ENRICHED) will contain the full enriched question object.
  void _handleAnswerDetected(Map<String, dynamic> data) {
    debugPrint('[LiveInsightsWebSocket] ✅ ENTERED _handleAnswerDetected handler');
    try {
      final answerData = data['data'] as Map<String, dynamic>;
      final questionId = answerData['id'] as String;
      final answerText = answerData['answerText'] as String?;
      final answerSpeaker = answerData['answerSpeaker'] as String?;
      final answerConfidence = (answerData['answerConfidence'] as num?)?.toDouble();

      debugPrint(
        '[LiveInsightsWebSocket] Answer detected for question $questionId: '
        '${answerText?.substring(0, answerText.length > 50 ? 50 : answerText.length)}... '
        '(speaker: $answerSpeaker, confidence: $answerConfidence)'
      );

      // Note: This is a lightweight notification for fast UX. The full enriched
      // question object with complete tier results will arrive shortly via
      // ANSWER_DETECTED_ENRICHED event. We don't emit this to the stream
      // to avoid partial updates - the provider will get the complete data.
    } catch (e) {
      debugPrint('[LiveInsightsWebSocket] Error handling answer detected: $e');
    }
  }

  /// Handle QUESTION_UNANSWERED event (lightweight notification)
  /// Sent when all tiers have been exhausted without finding an answer.
  /// Updates the question status to 'unanswered' in the UI.
  void _handleQuestionUnanswered(Map<String, dynamic> data) {
    debugPrint('[LiveInsightsWebSocket] ✅ ENTERED _handleQuestionUnanswered handler');
    try {
      // Backend sends: { type: QUESTION_UNANSWERED, data: { question_id: xxx, status: unanswered, ... }, timestamp: xxx }
      final unansweredData = data['data'] as Map<String, dynamic>;
      final questionId = unansweredData['question_id'] as String;
      final status = unansweredData['status'] as String?;
      final timestamp = unansweredData['timestamp'] as String?;

      debugPrint(
        '[LiveInsightsWebSocket] Question $questionId remained unanswered '
        'after all tiers exhausted (status: $status, timestamp: $timestamp)'
      );

      // With 60-second monitoring timeout, we don't need a grace period
      // The extended monitoring window gives sufficient time for answers to arrive
      // Create status-only update that preserves existing question text and tier results
      // The provider's merge logic will preserve all existing data except status
      final minimalUpdate = LiveQuestion(
        id: questionId,
        text: '', // Will be preserved from existing question during merge
        speaker: null,
        timestamp: DateTime.tryParse(timestamp ?? '') ?? DateTime.now(),
        status: InsightStatus.unanswered,
        answerSource: AnswerSource.unanswered,
        tierResults: [], // Will be preserved from existing question during merge
      );

      _questionsController.add(minimalUpdate);
      debugPrint(
        '[LiveInsightsWebSocket] Emitted UNANSWERED status update for question $questionId'
      );
    } catch (e) {
      debugPrint('[LiveInsightsWebSocket] Error handling question unanswered: $e');
    }
  }

  /// Handle ANSWER_FROM_MEETING event (lightweight answer notification from Tier 2)
  /// This is Phase 1 of the two-phase answer broadcast pattern for meeting context search.
  /// Phase 2 (enriched event with full question object) will be sent after DB persistence.
  void _handleAnswerFromMeeting(Map<String, dynamic> data) {
    debugPrint('[LiveInsightsWebSocket] ✅ ENTERED _handleAnswerFromMeeting handler');
    try {
      // Backend sends: { type: ANSWER_FROM_MEETING, data: { question_id: xxx, answer_text: ..., ... } }
      // Note: question_id is INSIDE the 'data' object, not at top level
      final answerData = data['data'] as Map<String, dynamic>;

      final questionId = answerData['question_id'] as String;
      final answerText = answerData['answer_text'] as String?;
      final confidence = (answerData['confidence'] as num?)?.toDouble();
      final tier = answerData['tier'] as String?;
      final quotes = answerData['quotes'] as List<dynamic>?;

      debugPrint(
        '[LiveInsightsWebSocket] Answer from meeting context found for question $questionId: '
        '${answerText?.substring(0, answerText.length > 50 ? 50 : answerText.length)}... '
        '(confidence: $confidence, tier: $tier, quotes: ${quotes?.length ?? 0})'
      );

      // Note: This is a lightweight notification (Phase 1) for fast UX feedback.
      // The full enriched question object with complete tier results will arrive
      // shortly via a subsequent enriched event after database persistence.
      // We don't emit this to the stream to avoid partial updates - the provider
      // will get the complete data from the enriched event.
    } catch (e) {
      debugPrint('[LiveInsightsWebSocket] Error handling answer from meeting: $e');
    }
  }

  /// Handle QUESTION_ANSWERED_LIVE event (Tier 4 - live conversation monitoring)
  /// Can receive either lightweight notification (Phase 1) or full question object (Phase 2).
  /// This is distinct from ANSWER_FROM_MEETING (Tier 2 - meeting context search).
  void _handleQuestionAnsweredLive(Map<String, dynamic> data) {
    debugPrint('[LiveInsightsWebSocket] ✅ ENTERED _handleQuestionAnsweredLive handler');
    try {
      final dataField = data['data'];

      // Check if this is Phase 1 (lightweight) or Phase 2 (full question object)
      // Phase 1: { type: QUESTION_ANSWERED_LIVE, question_id: xxx, data: { answer_text, speaker, ... } }
      // Phase 2: { type: QUESTION_ANSWERED_LIVE, data: { id, text, tierResults, ... } } (full question)

      if (dataField is Map<String, dynamic>) {
        // Check if it's a full question object (has 'id', 'text', 'tierResults')
        final hasQuestionStructure = dataField.containsKey('id') &&
                                     dataField.containsKey('text') &&
                                     dataField.containsKey('tierResults');

        if (hasQuestionStructure) {
          // Phase 2: Full question object - route to question update handler
          debugPrint('[LiveInsightsWebSocket] QUESTION_ANSWERED_LIVE Phase 2 (enriched) - routing to question update');
          _handleQuestionUpdate(data);
        } else {
          // Phase 1: Lightweight notification
          final questionId = data['question_id'] as String?;
          final answerText = dataField['answer_text'] as String?;
          final speaker = dataField['speaker'] as String?;
          final confidence = (dataField['confidence'] as num?)?.toDouble();
          final tier = dataField['tier'] as String?;

          debugPrint(
            '[LiveInsightsWebSocket] Live conversation answer detected for question $questionId: '
            '${answerText != null ? answerText.substring(0, answerText.length > 50 ? 50 : answerText.length) : 'N/A'}... '
            '(speaker: $speaker, confidence: $confidence, tier: $tier) 👂'
          );

          // Note: This is Phase 1 lightweight notification for fast UX.
          // Phase 2 with full question object will arrive shortly.
          // We don't emit to stream to avoid partial updates.
        }
      }
    } catch (e) {
      debugPrint('[LiveInsightsWebSocket] Error handling question answered live: $e');
    }
  }

  /// Handle question update events
  void _handleQuestionUpdate(Map<String, dynamic> data) {
    final String? type = data['type'] as String?;
    debugPrint('[LiveInsightsWebSocket] ✅ ENTERED _handleQuestionUpdate handler for type: $type');

    try {
      // Handle tier result events - these contain updates to existing questions
      // Parse the data and let the provider merge it with existing question state
      debugPrint('[LiveInsightsWebSocket] Processing tier result event: $type');

      // Handle different event structures from backend
      // Some events have 'question' key, others have 'data' key
      final Map<String, dynamic> questionData;
      if (data.containsKey('question')) {
        questionData = data['question'] as Map<String, dynamic>;
      } else if (data.containsKey('data')) {
        questionData = data['data'] as Map<String, dynamic>;
      } else {
        debugPrint('[LiveInsightsWebSocket] Question event missing data key: $data');
        return;
      }

      // DEBUG: Log raw tierResults from JSON
      final rawTierResults = questionData['tierResults'];
      debugPrint('[LiveInsightsWebSocket] Raw tierResults from backend: type=${rawTierResults.runtimeType}, value=$rawTierResults');

      // DEBUG: Log answerSource from JSON
      final rawAnswerSource = questionData['answer_source'];
      debugPrint('[LiveInsightsWebSocket] Raw answer_source from backend: $rawAnswerSource');

      final question = LiveQuestion.fromJson(questionData);
      _questionsController.add(question);
      debugPrint(
          '[LiveInsightsWebSocket] Question update: ${question.id} - ${question.status} - answerSource: ${question.answerSource}');
    } catch (e) {
      debugPrint('[LiveInsightsWebSocket] Error parsing question: $e');
    }
  }

  /// Handle action update events
  void _handleActionUpdate(Map<String, dynamic> data) {
    try {
      // Handle different event structures from backend
      // Some events have 'action' key, others have 'data' key
      final Map<String, dynamic> actionData;
      if (data.containsKey('action')) {
        actionData = data['action'] as Map<String, dynamic>;
      } else if (data.containsKey('data')) {
        actionData = data['data'] as Map<String, dynamic>;
      } else {
        debugPrint('[LiveInsightsWebSocket] Action event missing data key: $data');
        return;
      }

      final action = LiveAction.fromJson(actionData);
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
      // Handle different event structures from backend
      // Some events have 'transcript' key, others have 'data' key
      final Map<String, dynamic> transcriptData;
      if (data.containsKey('transcript')) {
        transcriptData = data['transcript'] as Map<String, dynamic>;
      } else if (data.containsKey('data')) {
        transcriptData = data['data'] as Map<String, dynamic>;
      } else {
        debugPrint('[LiveInsightsWebSocket] Transcription event missing data key: $data');
        return;
      }

      final transcription = TranscriptSegment.fromJson(transcriptData);
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

    // Only attempt reconnection if disconnect was NOT intentional
    if (!_intentionalDisconnect) {
      _handleError('Connection closed');
    } else {
      debugPrint('[LiveInsightsWebSocket] Intentional disconnect - skipping reconnection');
    }
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

  /// Disconnect from WebSocket (can reconnect later)
  Future<void> disconnect() async {
    debugPrint('[LiveInsightsWebSocket] Disconnecting from session');

    // Mark as intentional disconnect to prevent automatic reconnection
    _intentionalDisconnect = true;

    _reconnectTimer?.cancel();
    _pingTimer?.cancel();

    if (_channel != null) {
      await _channel!.sink.close();
      _channel = null;
    }

    _isConnected = false;
    _connectionStateController.add(false);

    debugPrint('[LiveInsightsWebSocket] Disconnected successfully');
  }

  /// Disconnect and cleanup (full disposal)
  Future<void> dispose() async {
    debugPrint('[LiveInsightsWebSocket] Disposing service');

    // Mark as intentional disconnect to prevent automatic reconnection
    _intentionalDisconnect = true;

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
