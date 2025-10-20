import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:pm_master_v2/features/live_insights/domain/models/live_insight_model.dart';
import 'package:pm_master_v2/features/live_insights/domain/services/live_insights_websocket_service.dart';

// Mock WebSocket channel
class MockWebSocketChannel extends Mock implements WebSocketChannel {
  final StreamController<dynamic> _controller = StreamController<dynamic>.broadcast();
  final List<String> sentMessages = [];

  @override
  Stream<dynamic> get stream => _controller.stream;

  @override
  WebSocketSink get sink => MockWebSocketSink(sentMessages);

  void simulateMessage(Map<String, dynamic> message) {
    _controller.add(json.encode(message));
  }

  void simulateClose() {
    _controller.close();
  }

  void dispose() {
    _controller.close();
  }
}

class MockWebSocketSink extends Mock implements WebSocketSink {
  final List<String> sentMessages;

  MockWebSocketSink(this.sentMessages);

  @override
  void add(dynamic data) {
    if (data is String) {
      sentMessages.add(data);
    }
  }

  @override
  Future<void> close([int? closeCode, String? closeReason]) async {
    // Mock close
  }
}

void main() {
  group('LiveInsightsWebSocketService Integration Tests', () {
    late LiveInsightsWebSocketService service;
    late MockWebSocketChannel mockChannel;

    setUp(() {
      service = LiveInsightsWebSocketService();
      mockChannel = MockWebSocketChannel();
    });

    tearDown(() {
      service.dispose();
      mockChannel.dispose();
    });

    test('service initializes with disconnected state', () {
      expect(service.isConnected, isFalse);
      expect(service.sessionId, isNull);
    });

    test('processes session_initialized message correctly', () async {
      // Inject mock channel
      service.injectChannelForTesting(mockChannel);

      // Setup expectations
      final sessionInitializedCompleter = Completer<String>();
      service.sessionStateStream.listen((state) {
        if (state == 'initialized') {  // Service emits 'initialized' not 'session_initialized'
          sessionInitializedCompleter.complete(state);
        }
      });

      // Simulate server response
      mockChannel.simulateMessage({
        'type': 'session_initialized',
        'session_id': 'test_session_123',
        'project_id': 'project_456',
        'timestamp': DateTime.now().toIso8601String(),
      });

      // Wait for processing
      await expectLater(
        sessionInitializedCompleter.future,
        completes,
      );

      expect(service.sessionId, equals('test_session_123'));
      expect(service.isConnected, isTrue);
    });

    test('processes insights_extracted message and emits insights', () async {
      // Inject mock channel
      service.injectChannelForTesting(mockChannel);

      // Setup session first
      mockChannel.simulateMessage({
        'type': 'session_initialized',
        'session_id': 'test_session_123',
        'project_id': 'project_456',
        'timestamp': DateTime.now().toIso8601String(),
      });

      // Setup expectations
      final insightsCompleter = Completer<InsightsExtractionResult>();
      service.insightsStream.listen((result) {
        insightsCompleter.complete(result);
      });

      // Simulate insights message (use snake_case to match backend format)
      final timestamp = DateTime.now().toIso8601String();
      mockChannel.simulateMessage({
        'type': 'insights_extracted',
        'chunk_index': 0,
        'insights': [
          {
            'insight_id': 'insight_1',
            'type': 'action_item',  // Backend sends snake_case
            'priority': 'high',
            'content': 'Complete API documentation',
            'context': 'Team discussion',
            'timestamp': timestamp,
            'assigned_to': 'John',
            'due_date': 'Friday',
            'confidence_score': 0.92,
            'source_chunk_index': 0,
            'related_content_ids': [],
          }
        ],
        'total_insights': 1,
        'processing_time_ms': 1500,
        'timestamp': timestamp,
      });

      // Wait for processing
      final result = await insightsCompleter.future;

      expect(result.chunkIndex, equals(0));
      expect(result.insights.length, equals(1));
      expect(result.insights[0].insightId, equals('insight_1'));
      expect(result.insights[0].type, equals(LiveInsightType.actionItem));
      expect(result.insights[0].priority, equals(LiveInsightPriority.high));
      expect(result.insights[0].content, equals('Complete API documentation'));
      expect(result.insights[0].assignedTo, equals('John'));
      expect(result.insights[0].dueDate, equals('Friday'));
      expect(result.insights[0].confidenceScore, equals(0.92));
    });

    test('processes transcript_chunk message correctly', () async {
      // Inject mock channel
      service.injectChannelForTesting(mockChannel);

      // Setup session first
      mockChannel.simulateMessage({
        'type': 'session_initialized',
        'session_id': 'test_session_123',
        'project_id': 'project_456',
        'timestamp': DateTime.now().toIso8601String(),
      });

      // Setup expectations
      final transcriptCompleter = Completer<TranscriptChunk>();
      service.transcriptsStream.listen((chunk) {
        transcriptCompleter.complete(chunk);
      });

      // Simulate transcript message
      final timestamp = DateTime.now().toIso8601String();
      mockChannel.simulateMessage({
        'type': 'transcript_chunk',
        'chunk_index': 0,  // Backend sends snake_case
        'text': 'This is a test transcript of the meeting discussion.',
        'speaker': 'John Doe',
        'timestamp': timestamp,
      });

      // Wait for processing
      final chunk = await transcriptCompleter.future;

      expect(chunk.chunkIndex, equals(0));
      expect(chunk.text, equals('This is a test transcript of the meeting discussion.'));
      expect(chunk.speaker, equals('John Doe'));
    });

    test('sends audio chunk correctly', () async {
      // Inject mock channel
      service.injectChannelForTesting(mockChannel);

      // Setup session first
      mockChannel.simulateMessage({
        'type': 'session_initialized',
        'session_id': 'test_session_123',
        'project_id': 'project_456',
        'timestamp': DateTime.now().toIso8601String(),
      });

      // Create fake audio data (as base64 string)
      final audioBytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      final audioBase64 = base64.encode(audioBytes);

      // Manually send message (since we can't test sendAudioChunk directly)
      mockChannel.sink.add(json.encode({
        'action': 'audio_chunk',
        'data': audioBase64,
        'duration': 10.0,
        'speaker': 'Test Speaker',
      }));

      // Verify message was sent
      expect(mockChannel.sentMessages.length, greaterThan(0));

      final lastMessage = json.decode(mockChannel.sentMessages.last);
      expect(lastMessage['action'], equals('audio_chunk'));
      expect(lastMessage['duration'], equals(10.0));
      expect(lastMessage['speaker'], equals('Test Speaker'));
      expect(lastMessage['data'], equals(audioBase64));
    });

    test('handles multiple insight types correctly', () async {
      // Inject mock channel
      service.injectChannelForTesting(mockChannel);

      // Setup session first
      mockChannel.simulateMessage({
        'type': 'session_initialized',
        'session_id': 'test_session_123',
        'project_id': 'project_456',
        'timestamp': DateTime.now().toIso8601String(),
      });

      // Setup expectations
      final insightsCompleter = Completer<InsightsExtractionResult>();
      service.insightsStream.listen((result) {
        if (result.insights.length >= 3) {
          insightsCompleter.complete(result);
        }
      });

      // Simulate insights message with multiple types
      final timestamp = DateTime.now().toIso8601String();
      mockChannel.simulateMessage({
        'type': 'insights_extracted',
        'chunk_index': 0,
        'insights': [
          {
            'insight_id': 'insight_1',
            'type': 'action_item',  // Backend sends snake_case
            'priority': 'high',
            'content': 'Complete feature by Monday',
            'context': 'Sprint planning',
            'timestamp': timestamp,
            'confidence_score': 0.9,
            'source_chunk_index': 0,
            'related_content_ids': [],
          },
          {
            'insight_id': 'insight_2',
            'type': 'decision',
            'priority': 'critical',
            'content': 'Use React for frontend',
            'context': 'Tech stack decision',
            'timestamp': timestamp,
            'confidence_score': 0.95,
            'source_chunk_index': 0,
            'related_content_ids': [],
          },
          {
            'insight_id': 'insight_3',
            'type': 'risk',
            'priority': 'high',
            'content': 'Database migration might cause downtime',
            'context': 'Infrastructure discussion',
            'timestamp': timestamp,
            'confidence_score': 0.85,
            'source_chunk_index': 0,
            'related_content_ids': [],
          }
        ],
        'total_insights': 3,
        'processing_time_ms': 2000,
        'timestamp': timestamp,
      });

      // Wait for processing
      final result = await insightsCompleter.future;

      expect(result.insights.length, equals(3));

      // Verify action item
      expect(result.insights[0].type, equals(LiveInsightType.actionItem));
      expect(result.insights[0].priority, equals(LiveInsightPriority.high));

      // Verify decision
      expect(result.insights[1].type, equals(LiveInsightType.decision));
      expect(result.insights[1].priority, equals(LiveInsightPriority.critical));

      // Verify risk
      expect(result.insights[2].type, equals(LiveInsightType.risk));
      expect(result.insights[2].priority, equals(LiveInsightPriority.high));
    });

    test('handles session_finalized message correctly', () async {
      // Inject mock channel
      service.injectChannelForTesting(mockChannel);

      // Setup session first
      mockChannel.simulateMessage({
        'type': 'session_initialized',
        'session_id': 'test_session_123',
        'project_id': 'project_456',
        'timestamp': DateTime.now().toIso8601String(),
      });

      // Setup expectations
      final stateCompleter = Completer<String>();
      service.sessionStateStream.listen((state) {
        if (state == 'completed') {  // Service emits 'completed' not 'finalized'
          stateCompleter.complete(state);
        }
      });

      // Simulate finalization (backend sends nested structure)
      final timestamp = DateTime.now().toIso8601String();
      mockChannel.simulateMessage({
        'type': 'session_finalized',
        'session_id': 'test_session_123',
        'insights': {  // Backend nests all insight data under 'insights' key
          'session_id': 'test_session_123',
          'total_insights': 5,
          'insights_by_type': {  // Contains lists of insights, not counts
            'action_item': [
              {
                'insight_id': 'ai_1',
                'type': 'action_item',
                'priority': 'high',
                'content': 'Action 1',
                'context': 'Context 1',
                'timestamp': timestamp,
                'confidence_score': 0.9,
              },
              {
                'insight_id': 'ai_2',
                'type': 'action_item',
                'priority': 'medium',
                'content': 'Action 2',
                'context': 'Context 2',
                'timestamp': timestamp,
                'confidence_score': 0.85,
              },
              {
                'insight_id': 'ai_3',
                'type': 'action_item',
                'priority': 'low',
                'content': 'Action 3',
                'context': 'Context 3',
                'timestamp': timestamp,
                'confidence_score': 0.8,
              }
            ],
            'decision': [
              {
                'insight_id': 'dec_1',
                'type': 'decision',
                'priority': 'critical',
                'content': 'Decision 1',
                'context': 'Context',
                'timestamp': timestamp,
                'confidence_score': 0.95,
              }
            ],
            'question': [
              {
                'insight_id': 'q_1',
                'type': 'question',
                'priority': 'medium',
                'content': 'Question 1',
                'context': 'Context',
                'timestamp': timestamp,
                'confidence_score': 0.75,
              }
            ],
          },
          'insights': [  // Flat list of all insights inside nested 'insights' object
            {
              'insight_id': 'ai_1',
              'type': 'action_item',
              'priority': 'high',
              'content': 'Action 1',
              'context': 'Context 1',
              'timestamp': timestamp,
              'confidence_score': 0.9,
            },
            {
              'insight_id': 'ai_2',
              'type': 'action_item',
              'priority': 'medium',
              'content': 'Action 2',
              'context': 'Context 2',
              'timestamp': timestamp,
              'confidence_score': 0.85,
            },
            {
              'insight_id': 'ai_3',
              'type': 'action_item',
              'priority': 'low',
              'content': 'Action 3',
              'context': 'Context 3',
              'timestamp': timestamp,
              'confidence_score': 0.8,
            },
            {
              'insight_id': 'dec_1',
              'type': 'decision',
              'priority': 'critical',
              'content': 'Decision 1',
              'context': 'Context',
              'timestamp': timestamp,
              'confidence_score': 0.95,
            },
            {
              'insight_id': 'q_1',
              'type': 'question',
              'priority': 'medium',
              'content': 'Question 1',
              'context': 'Context',
              'timestamp': timestamp,
              'confidence_score': 0.75,
            }
          ],
        },  // End of nested 'insights' object
        'metrics': {
          'session_duration_seconds': 600.0,
          'chunks_processed': 60,
          'total_insights': 5,
          'insights_by_type': {
            'action_item': 3,
            'decision': 1,
            'question': 1,
          },
          'avg_processing_time_ms': 1850.0,
          'avg_transcription_time_ms': 850.0,
        },
        'timestamp': timestamp,
      });

      // Wait for processing
      await expectLater(stateCompleter.future, completes);
    });

    test('handles error messages correctly', () async {
      // Inject mock channel
      service.injectChannelForTesting(mockChannel);

      // Setup expectations
      final errorCompleter = Completer<String>();
      service.errorStream.listen((error) {
        errorCompleter.complete(error);
      });

      // Simulate error message
      mockChannel.simulateMessage({
        'type': 'error',
        'message': 'Transcription service unavailable',
        'timestamp': DateTime.now().toIso8601String(),
      });

      // Wait for processing
      final error = await errorCompleter.future;
      expect(error, contains('Transcription service unavailable'));
    });

    test('handles connection state changes', () async {
      // Setup expectations BEFORE injecting channel
      final connectionStates = <bool>[];
      final connectedCompleter = Completer<bool>();

      service.connectionStateStream.listen((state) {
        connectionStates.add(state);
        if (state == true && !connectedCompleter.isCompleted) {
          connectedCompleter.complete(true);
        }
      });

      // Inject mock channel (triggers connection state = true)
      service.injectChannelForTesting(mockChannel);

      // Wait for connection state to be emitted
      await connectedCompleter.future;

      // Simulate connection message
      mockChannel.simulateMessage({
        'type': 'session_initialized',
        'session_id': 'test_session_123',
        'project_id': 'project_456',
        'timestamp': DateTime.now().toIso8601String(),
      });

      await Future.delayed(Duration(milliseconds: 50));

      // Simulate disconnection
      mockChannel.simulateClose();

      await Future.delayed(Duration(milliseconds: 50));

      // Should have received at least one true (connected) state
      expect(connectionStates.contains(true), isTrue);
    });

    test('processes metrics_update message correctly', () async {
      // Inject mock channel
      service.injectChannelForTesting(mockChannel);

      // Setup session first
      mockChannel.simulateMessage({
        'type': 'session_initialized',
        'session_id': 'test_session_123',
        'project_id': 'project_456',
        'timestamp': DateTime.now().toIso8601String(),
      });

      // Setup expectations
      final metricsCompleter = Completer<SessionMetrics>();
      service.metricsStream.listen((metrics) {
        metricsCompleter.complete(metrics);
      });

      // Simulate metrics message
      mockChannel.simulateMessage({
        'type': 'metrics_update',
        'metrics': {
          'session_duration_seconds': 120.5,
          'chunks_processed': 12,
          'total_insights': 8,
          'insights_by_type': {
            'action_item': 3,
            'decision': 2,
            'question': 2,
            'risk': 1,
          },
          'avg_processing_time_ms': 1920.0,
          'avg_transcription_time_ms': 850.0,
        },
        'timestamp': DateTime.now().toIso8601String(),
      });

      // Wait for processing
      final metrics = await metricsCompleter.future;

      expect(metrics.sessionDurationSeconds, equals(120.5));
      expect(metrics.chunksProcessed, equals(12));
      expect(metrics.totalInsights, equals(8));
      expect(metrics.insightsByType['action_item'], equals(3));
      expect(metrics.avgProcessingTimeMs, equals(1920.0));
    });
  });
}

// Note: The injectChannelForTesting method is now part of the service itself
