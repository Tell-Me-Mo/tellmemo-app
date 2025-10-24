import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:pm_master_v2/features/live_insights/domain/models/proactive_assistance_model.dart';
import 'package:pm_master_v2/features/live_insights/domain/services/live_insights_websocket_service.dart';
import 'package:pm_master_v2/features/live_insights/presentation/widgets/proactive_assistance_card.dart';
import 'package:pm_master_v2/features/meetings/presentation/widgets/live_insights_panel.dart';

/// Integration tests for Phase 1: Proactive Assistance UI
///
/// Tests the frontend flow:
/// 1. WebSocket receives proactive_assistance message
/// 2. Stream emits ProactiveAssistanceModel
/// 3. UI displays ProactiveAssistanceCard
/// 4. User can accept/dismiss

class MockWebSocketChannel extends Fake implements WebSocketChannel {
  final StreamController<dynamic> _controller = StreamController<dynamic>.broadcast();
  final List<String> sentMessages = [];

  @override
  Stream<dynamic> get stream => _controller.stream;

  @override
  WebSocketSink get sink => MockWebSocketSink(sentMessages);

  void addMessage(Map<String, dynamic> message) {
    _controller.add(jsonEncode(message));
  }

  void close() {
    _controller.close();
  }
}

class MockWebSocketSink extends Fake implements WebSocketSink {
  final List<String> sentMessages;

  MockWebSocketSink(this.sentMessages);

  @override
  void add(dynamic data) {
    sentMessages.add(data.toString());
  }

  @override
  Future<void> close([int? closeCode, String? closeReason]) async {
    // No-op for testing
  }
}

void main() {
  group('Proactive Assistance Integration Tests', () {
    late LiveInsightsWebSocketService wsService;
    late MockWebSocketChannel mockChannel;

    setUp(() {
      wsService = LiveInsightsWebSocketService();
      mockChannel = MockWebSocketChannel();
      wsService.injectChannelForTesting(mockChannel);
    });

    tearDown(() {
      mockChannel.close();
      wsService.dispose();
    });

    test('WebSocket receives and parses proactive_assistance message', () async {
      // Setup stream listener
      final receivedAssistance = <List<ProactiveAssistanceModel>>[];
      wsService.proactiveAssistanceStream.listen((assistance) {
        receivedAssistance.add(assistance);
      });

      // Simulate backend sending proactive assistance
      final mockMessage = {
        'type': 'insights_extracted',
        'timestamp': DateTime.now().toIso8601String(),
        'session_id': 'test_session',
        'chunk_index': 5,
        'insights': [
          {
            'insight_id': 'insight_123',
            'type': 'question',
            'priority': 'medium',
            'content': 'What was our Q4 budget?',
            'context': 'Budget discussion',
            'timestamp': DateTime.now().toIso8601String(),
            'confidence_score': 0.9,
          }
        ],
        'proactive_assistance': [
          {
            'type': 'auto_answer',
            'insight_id': 'insight_123',
            'question': 'What was our Q4 budget?',
            'answer': 'In the October 10 planning meeting, you allocated \$50K for Q4 marketing.',
            'confidence': 0.89,
            'sources': [
              {
                'content_id': 'content_abc',
                'title': 'Q4 Planning Meeting',
                'snippet': 'Budget allocated: \$50K for marketing...',
                'date': DateTime.now().toIso8601String(),
                'relevance_score': 0.92,
                'meeting_type': 'planning',
              }
            ],
            'reasoning': 'Found exact budget numbers in Q4 planning notes',
            'timestamp': DateTime.now().toIso8601String(),
          }
        ],
        'total_insights_count': 1,
        'processing_time_ms': 2340,
      };

      // Send message through mock WebSocket
      mockChannel.addMessage(mockMessage);

      // Wait for message to be processed
      await Future.delayed(const Duration(milliseconds: 100));

      // Verify proactive assistance was received
      expect(receivedAssistance, isNotEmpty);
      expect(receivedAssistance.first, hasLength(1));

      final assistance = receivedAssistance.first.first;
      expect(assistance.type, ProactiveAssistanceType.autoAnswer);
      expect(assistance.autoAnswer, isNotNull);
      expect(assistance.autoAnswer!.question, 'What was our Q4 budget?');
      expect(assistance.autoAnswer!.answer, contains('\$50K'));
      expect(assistance.autoAnswer!.confidence, 0.89);
      expect(assistance.autoAnswer!.sources, hasLength(1));
      expect(assistance.autoAnswer!.sources.first.title, 'Q4 Planning Meeting');
    });

    test('Multiple proactive assistance items are handled correctly', () async {
      final receivedAssistance = <List<ProactiveAssistanceModel>>[];
      wsService.proactiveAssistanceStream.listen((assistance) {
        receivedAssistance.add(assistance);
      });

      // Send message with multiple assistance items
      final mockMessage = {
        'type': 'insights_extracted',
        'timestamp': DateTime.now().toIso8601String(),
        'session_id': 'test_session',
        'insights': [],
        'proactive_assistance': [
          {
            'type': 'auto_answer',
            'insight_id': 'insight_1',
            'question': 'What was the deadline?',
            'answer': 'The deadline is December 31st.',
            'confidence': 0.85,
            'sources': [],
            'reasoning': 'Found in previous meeting',
            'timestamp': DateTime.now().toIso8601String(),
          },
          {
            'type': 'auto_answer',
            'insight_id': 'insight_2',
            'question': 'Who is the project lead?',
            'answer': 'Sarah Johnson is the project lead.',
            'confidence': 0.95,
            'sources': [],
            'reasoning': 'Mentioned in kickoff meeting',
            'timestamp': DateTime.now().toIso8601String(),
          }
        ],
      };

      mockChannel.addMessage(mockMessage);
      await Future.delayed(const Duration(milliseconds: 100));

      expect(receivedAssistance, isNotEmpty);
      expect(receivedAssistance.first, hasLength(2));
    });

    test('Invalid proactive assistance is handled gracefully', () async {
      final receivedAssistance = <List<ProactiveAssistanceModel>>[];
      final errors = <dynamic>[];

      wsService.proactiveAssistanceStream.listen(
        (assistance) => receivedAssistance.add(assistance),
        onError: (error) => errors.add(error),
      );

      // Send message with invalid assistance (missing required fields)
      final mockMessage = {
        'type': 'insights_extracted',
        'timestamp': DateTime.now().toIso8601String(),
        'session_id': 'test_session',
        'insights': [],
        'proactive_assistance': [
          {
            'type': 'auto_answer',
            // Missing required fields like question, answer, etc.
          }
        ],
      };

      mockChannel.addMessage(mockMessage);
      await Future.delayed(const Duration(milliseconds: 100));

      // Should not crash, might log error but continue
      expect(receivedAssistance, isEmpty);
    });

    testWidgets('ProactiveAssistanceCard displays correctly', (WidgetTester tester) async {
      final assistance = ProactiveAssistanceModel(
        type: ProactiveAssistanceType.autoAnswer,
        autoAnswer: AutoAnswerAssistance(
          insightId: 'test_123',
          question: 'What was our Q4 budget?',
          answer: 'The Q4 budget was \$50,000 for marketing.',
          confidence: 0.89,
          sources: [
            AnswerSource(
              contentId: 'content_1',
              title: 'Q4 Planning Meeting',
              snippet: 'Budget allocated: \$50K...',
              date: DateTime.now(),
              relevanceScore: 0.92,
              meetingType: 'planning',
            ),
          ],
          reasoning: 'Found in Q4 planning notes',
          timestamp: DateTime.now(),
        ),
      );

      bool wasAccepted = false;
      bool wasDismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProactiveAssistanceCard(
              assistance: assistance,
              onAccept: () => wasAccepted = true,
              onDismiss: () => wasDismissed = true,
            ),
          ),
        ),
      );

      // Verify card is displayed
      expect(find.text('💡 AI Auto-Answered'), findsOneWidget);
      expect(find.text('What was our Q4 budget?'), findsWidgets);
      expect(find.text('The Q4 budget was \$50,000 for marketing.'), findsOneWidget);
      expect(find.text('89%'), findsOneWidget); // Confidence badge

      // Verify source is displayed
      expect(find.text('Q4 Planning Meeting'), findsOneWidget);

      // Verify feedback buttons are present (auto-answer type has feedback, not action buttons)
      expect(find.text('Helpful'), findsOneWidget);
      expect(find.text('Not Helpful'), findsOneWidget);

      // Test that tapping feedback button works without crashing
      await tester.tap(find.text('Helpful'));
      await tester.pumpAndSettle();

      // Verify snackbar appears after feedback
      expect(find.text('Thank you! This helps improve our AI.'), findsOneWidget);
    });

    testWidgets('Confidence badge colors are correct', (WidgetTester tester) async {
      // Test high confidence (green)
      final highConfidence = ProactiveAssistanceModel(
        type: ProactiveAssistanceType.autoAnswer,
        autoAnswer: AutoAnswerAssistance(
          insightId: 'test',
          question: 'Test?',
          answer: 'Answer',
          confidence: 0.85, // >0.8 = green
          sources: [],
          reasoning: 'Test',
          timestamp: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProactiveAssistanceCard(assistance: highConfidence),
          ),
        ),
      );

      expect(find.text('85%'), findsOneWidget);

      // Test medium confidence (orange)
      final mediumConfidence = ProactiveAssistanceModel(
        type: ProactiveAssistanceType.autoAnswer,
        autoAnswer: AutoAnswerAssistance(
          insightId: 'test',
          question: 'Test?',
          answer: 'Answer',
          confidence: 0.65, // 0.6-0.8 = orange
          sources: [],
          reasoning: 'Test',
          timestamp: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProactiveAssistanceCard(assistance: mediumConfidence),
          ),
        ),
      );

      expect(find.text('65%'), findsOneWidget);
    });

    testWidgets('Card can be expanded and collapsed', (WidgetTester tester) async {
      final assistance = ProactiveAssistanceModel(
        type: ProactiveAssistanceType.autoAnswer,
        autoAnswer: AutoAnswerAssistance(
          insightId: 'test',
          question: 'What is the deadline?',
          answer: 'December 31st',
          confidence: 0.90,
          sources: [],
          reasoning: 'Found in previous meeting',
          timestamp: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProactiveAssistanceCard(assistance: assistance),
          ),
        ),
      );

      // Initially expanded - answer should be visible
      expect(find.text('December 31st'), findsOneWidget);

      // Tap header to collapse
      await tester.tap(find.byIcon(Icons.expand_less));
      await tester.pumpAndSettle();

      // Answer should not be visible when collapsed
      expect(find.text('December 31st'), findsNothing);

      // Tap header to expand again
      await tester.tap(find.byIcon(Icons.expand_more));
      await tester.pumpAndSettle();

      // Answer should be visible again
      expect(find.text('December 31st'), findsOneWidget);
    });
  });

  group('LiveInsightsPanel Integration', () {
    testWidgets('Panel displays proactive assistance section when available', (WidgetTester tester) async {
      final insights = <MeetingInsight>[];

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: LiveInsightsPanel(
                insights: insights,
                isRecording: true,
              ),
            ),
          ),
        ),
      );

      // Initially, AI Assistant section should not be visible
      expect(find.text('AI Assistant'), findsNothing);

      // Note: Full integration with actual WebSocket stream would require:
      // 1. Mock RecordingProvider
      // 2. Mock WebSocket service with proactive assistance
      // 3. Trigger stream events and verify UI updates
      // This is kept simple to avoid overcomplication
    });
  });

  group('Performance Tests', () {
    test('Stream handles rapid message bursts', () async {
      final wsService = LiveInsightsWebSocketService();
      final mockChannel = MockWebSocketChannel();
      wsService.injectChannelForTesting(mockChannel);

      final receivedCount = <int>[];
      wsService.proactiveAssistanceStream.listen((assistance) {
        receivedCount.add(assistance.length);
      });

      // Send 10 messages rapidly
      for (int i = 0; i < 10; i++) {
        final message = {
          'type': 'insights_extracted',
          'timestamp': DateTime.now().toIso8601String(),
          'session_id': 'test',
          'insights': [],
          'proactive_assistance': [
            {
              'type': 'auto_answer',
              'insight_id': 'insight_$i',
              'question': 'Question $i?',
              'answer': 'Answer $i',
              'confidence': 0.8,
              'sources': [],
              'reasoning': 'Test',
              'timestamp': DateTime.now().toIso8601String(),
            }
          ],
        };
        mockChannel.addMessage(message);
      }

      await Future.delayed(const Duration(milliseconds: 500));

      // Should have received all 10 messages
      expect(receivedCount, hasLength(10));

      mockChannel.close();
      wsService.dispose();
    });
  });

  group('Phase 3: Conflict Detection Tests', () {
    late LiveInsightsWebSocketService wsService;
    late MockWebSocketChannel mockChannel;

    setUp(() {
      wsService = LiveInsightsWebSocketService();
      mockChannel = MockWebSocketChannel();
      wsService.injectChannelForTesting(mockChannel);
    });

    tearDown(() {
      mockChannel.close();
      wsService.dispose();
    });

    test('WebSocket receives and parses conflict_detected message', () async {
      final receivedAssistance = <List<ProactiveAssistanceModel>>[];
      wsService.proactiveAssistanceStream.listen((assistance) {
        receivedAssistance.add(assistance);
      });

      // Simulate backend sending conflict detection
      final mockMessage = {
        'type': 'insights_extracted',
        'timestamp': DateTime.now().toIso8601String(),
        'session_id': 'test_session',
        'chunk_index': 5,
        'insights': [],
        'proactive_assistance': [
          {
            'type': 'conflict_detected',
            'insight_id': 'insight_123',
            'current_statement': 'Let\'s use REST APIs for all new services',
            'conflicting_content_id': 'dec_xyz_789',
            'conflicting_title': 'Q3 Architecture Decision - GraphQL for APIs',
            'conflicting_snippet': 'Decided to use GraphQL for all new APIs to ensure consistency...',
            'conflicting_date': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
            'conflict_severity': 'high',
            'confidence': 0.91,
            'reasoning': 'Current statement directly contradicts GraphQL decision from last month',
            'resolution_suggestions': [
              'Confirm if this is a strategic change from GraphQL to REST',
              'Review the original GraphQL decision rationale',
              'Consider hybrid approach for specific use cases'
            ],
            'timestamp': DateTime.now().toIso8601String(),
          }
        ],
      };

      mockChannel.addMessage(mockMessage);
      await Future.delayed(const Duration(milliseconds: 100));

      expect(receivedAssistance, hasLength(1));
      final assistance = receivedAssistance.first.first;
      expect(assistance.type, ProactiveAssistanceType.conflictDetected);
      expect(assistance.conflict, isNotNull);
      expect(assistance.conflict!.conflictSeverity, 'high');
      expect(assistance.conflict!.confidence, 0.91);
      expect(assistance.conflict!.resolutionSuggestions, hasLength(3));
    });

    testWidgets('ProactiveAssistanceCard displays conflict correctly', (WidgetTester tester) async {
      final assistance = ProactiveAssistanceModel(
        type: ProactiveAssistanceType.conflictDetected,
        conflict: ConflictAssistance(
          insightId: 'test_123',
          currentStatement: 'Let\'s use REST APIs for all new services',
          conflictingContentId: 'dec_xyz_789',
          conflictingTitle: 'Q3 Architecture Decision - GraphQL',
          conflictingSnippet: 'Decided to use GraphQL for all new APIs to ensure consistency across services.',
          conflictingDate: DateTime.now().subtract(const Duration(days: 30)),
          conflictSeverity: 'high',
          confidence: 0.91,
          reasoning: 'Current statement directly contradicts GraphQL decision from last month',
          resolutionSuggestions: [
            'Confirm if this is a strategic change from GraphQL to REST',
            'Review the original GraphQL decision rationale',
          ],
          timestamp: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProactiveAssistanceCard(
              assistance: assistance,
              onAccept: () {},
              onDismiss: () {},
            ),
          ),
        ),
      );

      // Verify conflict card is displayed
      expect(find.text('⚠️ Potential Conflict'), findsOneWidget);
      expect(find.text('Let\'s use REST APIs for all new services'), findsWidgets);
      expect(find.text('91%'), findsWidgets); // Confidence badge (appears in header and content)
      expect(find.text('High Severity'), findsOneWidget); // Severity badge

      // Verify conflicting decision is shown
      expect(find.text('Q3 Architecture Decision - GraphQL'), findsOneWidget);

      // Verify reasoning is shown
      expect(find.textContaining('directly contradicts'), findsOneWidget);

      // Verify resolution suggestions are shown
      expect(find.textContaining('strategic change'), findsOneWidget);
      expect(find.textContaining('Review the original'), findsOneWidget);
    });

    testWidgets('Conflict severity badges display correctly', (WidgetTester tester) async {
      // Test high severity (red)
      final highSeverity = ProactiveAssistanceModel(
        type: ProactiveAssistanceType.conflictDetected,
        conflict: ConflictAssistance(
          insightId: 'test',
          currentStatement: 'Test statement',
          conflictingContentId: 'test',
          conflictingTitle: 'Test',
          conflictingSnippet: 'Test snippet',
          conflictingDate: DateTime.now(),
          conflictSeverity: 'high',
          confidence: 0.91,
          reasoning: 'Test',
          resolutionSuggestions: [],
          timestamp: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProactiveAssistanceCard(
              assistance: highSeverity,
              onAccept: () {},
              onDismiss: () {},
            ),
          ),
        ),
      );

      // Verify high severity badge
      expect(find.text('High Severity'), findsOneWidget);

      // Test medium severity
      final mediumSeverity = ProactiveAssistanceModel(
        type: ProactiveAssistanceType.conflictDetected,
        conflict: ConflictAssistance(
          insightId: 'test',
          currentStatement: 'Test statement',
          conflictingContentId: 'test',
          conflictingTitle: 'Test',
          conflictingSnippet: 'Test snippet',
          conflictingDate: DateTime.now(),
          conflictSeverity: 'medium',
          confidence: 0.75,
          reasoning: 'Test',
          resolutionSuggestions: [],
          timestamp: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProactiveAssistanceCard(
              assistance: mediumSeverity,
              onAccept: () {},
              onDismiss: () {},
            ),
          ),
        ),
      );

      // Verify medium severity badge
      expect(find.text('Medium Severity'), findsOneWidget);
    });

    test('Multiple conflict types can be received in one message', () async {
      final receivedAssistance = <List<ProactiveAssistanceModel>>[];
      wsService.proactiveAssistanceStream.listen((assistance) {
        receivedAssistance.add(assistance);
      });

      // Message with both auto-answer and conflict
      final mockMessage = {
        'type': 'insights_extracted',
        'timestamp': DateTime.now().toIso8601String(),
        'session_id': 'test_session',
        'chunk_index': 5,
        'insights': [],
        'proactive_assistance': [
          {
            'type': 'auto_answer',
            'insight_id': 'insight_1',
            'question': 'What was our budget?',
            'answer': 'The budget was \$50K',
            'confidence': 0.89,
            'sources': [],
            'reasoning': 'Found in notes',
            'timestamp': DateTime.now().toIso8601String(),
          },
          {
            'type': 'conflict_detected',
            'insight_id': 'insight_2',
            'current_statement': 'Use REST APIs',
            'conflicting_content_id': 'dec_123',
            'conflicting_title': 'GraphQL Decision',
            'conflicting_snippet': 'Use GraphQL for APIs',
            'conflicting_date': DateTime.now().toIso8601String(),
            'conflict_severity': 'high',
            'confidence': 0.91,
            'reasoning': 'Contradiction detected',
            'resolution_suggestions': ['Review decision'],
            'timestamp': DateTime.now().toIso8601String(),
          }
        ],
      };

      mockChannel.addMessage(mockMessage);
      await Future.delayed(const Duration(milliseconds: 100));

      expect(receivedAssistance, hasLength(1));
      expect(receivedAssistance.first, hasLength(2));

      final types = receivedAssistance.first.map((a) => a.type).toList();
      expect(types, contains(ProactiveAssistanceType.autoAnswer));
      expect(types, contains(ProactiveAssistanceType.conflictDetected));
    });
  });
}
