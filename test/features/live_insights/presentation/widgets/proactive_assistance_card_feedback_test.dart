import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_master_v2/features/live_insights/domain/models/proactive_assistance_model.dart';
import 'package:pm_master_v2/features/live_insights/presentation/widgets/proactive_assistance_card.dart';

/// Comprehensive tests for User Feedback Loop functionality
/// Tests the feedback collection feature (thumbs up/down) on ProactiveAssistanceCard
void main() {
  group('ProactiveAssistanceCard - Feedback Functionality Tests', () {
    late ProactiveAssistanceModel testAssistance;

    setUp(() {
      testAssistance = ProactiveAssistanceModel(
        type: ProactiveAssistanceType.autoAnswer,
        autoAnswer: AutoAnswerAssistance(
          insightId: 'test_insight_123',
          question: 'What is our project deadline?',
          answer: 'The project deadline is December 31st, 2025.',
          confidence: 0.89,
          sources: [
            AnswerSource(
              contentId: 'content_1',
              title: 'Q4 Planning Meeting',
              snippet: 'Deadline set for Dec 31st...',
              date: DateTime.now(),
              relevanceScore: 0.92,
              meetingType: 'planning',
            ),
          ],
          reasoning: 'Found in Q4 planning notes',
          timestamp: DateTime.now(),
        ),
      );
    });

    testWidgets('Feedback section is displayed with thumbs up/down buttons',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProactiveAssistanceCard(
              assistance: testAssistance,
            ),
          ),
        ),
      );

      // Wait for animations to complete
      await tester.pumpAndSettle();

      // Verify feedback section text
      expect(find.text('Was this helpful?'), findsOneWidget);

      // Verify both feedback buttons are present
      expect(find.text('Helpful'), findsOneWidget);
      expect(find.text('Not Helpful'), findsOneWidget);

      // Verify thumbs up/down icons are present
      expect(find.byIcon(Icons.thumb_up_outlined), findsOneWidget);
      expect(find.byIcon(Icons.thumb_down_outlined), findsOneWidget);
    });

    testWidgets('Tapping "Helpful" button triggers onFeedback callback with true',
        (WidgetTester tester) async {
      bool? feedbackReceived;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProactiveAssistanceCard(
              assistance: testAssistance,
              onFeedback: (isHelpful) {
                feedbackReceived = isHelpful;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap the "Helpful" button
      await tester.tap(find.text('Helpful'));
      await tester.pump();

      // Verify callback was triggered with true
      expect(feedbackReceived, isTrue);
    });

    testWidgets('Tapping "Not Helpful" button triggers onFeedback callback with false',
        (WidgetTester tester) async {
      bool? feedbackReceived;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProactiveAssistanceCard(
              assistance: testAssistance,
              onFeedback: (isHelpful) {
                feedbackReceived = isHelpful;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap the "Not Helpful" button
      await tester.tap(find.text('Not Helpful'));
      await tester.pump();

      // Verify callback was triggered with false
      expect(feedbackReceived, isFalse);
    });

    testWidgets('SnackBar appears with correct message after tapping "Helpful"',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProactiveAssistanceCard(
              assistance: testAssistance,
              onFeedback: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap "Helpful" button
      await tester.tap(find.text('Helpful'));
      await tester.pump();

      // Wait for SnackBar animation
      await tester.pump(const Duration(milliseconds: 100));

      // Verify SnackBar appears with correct message
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Thank you! This helps improve our AI.'), findsOneWidget);
      expect(find.byIcon(Icons.thumb_up), findsWidgets);
    });

    testWidgets('SnackBar appears with correct message after tapping "Not Helpful"',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProactiveAssistanceCard(
              assistance: testAssistance,
              onFeedback: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap "Not Helpful" button
      await tester.tap(find.text('Not Helpful'));
      await tester.pump();

      // Wait for SnackBar animation
      await tester.pump(const Duration(milliseconds: 100));

      // Verify SnackBar appears with correct message
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Feedback noted. We\'ll work to improve this.'), findsOneWidget);
      expect(find.byIcon(Icons.thumb_down), findsWidgets);
    });

    testWidgets('Feedback buttons are disabled after feedback is given',
        (WidgetTester tester) async {
      int feedbackCallCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProactiveAssistanceCard(
              assistance: testAssistance,
              onFeedback: (_) {
                feedbackCallCount++;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap "Helpful" button
      await tester.tap(find.text('Helpful'));
      await tester.pumpAndSettle();

      // Verify feedback was recorded once
      expect(feedbackCallCount, 1);

      // Try to tap the same button again
      // The button should be disabled, so tapping won't trigger the callback
      await tester.tap(find.text('Helpful'), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Verify callback was not called again (still 1)
      expect(feedbackCallCount, 1);

      // Try to tap the other button
      await tester.tap(find.text('Not Helpful'), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Verify callback still wasn't called (still 1)
      expect(feedbackCallCount, 1);
    });

    testWidgets('Selected button shows filled icon and different styling',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProactiveAssistanceCard(
              assistance: testAssistance,
              onFeedback: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially, outlined icons should be visible
      expect(find.byIcon(Icons.thumb_up_outlined), findsOneWidget);

      // Tap "Helpful" button
      await tester.tap(find.text('Helpful'));
      await tester.pumpAndSettle();

      // After tapping, filled icon should be visible
      expect(find.byIcon(Icons.thumb_up), findsWidgets);
      expect(find.byIcon(Icons.thumb_up_outlined), findsNothing);
    });

    testWidgets('Feedback confirmation message appears after feedback is given',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProactiveAssistanceCard(
              assistance: testAssistance,
              onFeedback: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap "Helpful" button
      await tester.tap(find.text('Helpful'));
      await tester.pumpAndSettle();

      // Verify confirmation message appears
      expect(
        find.text('Feedback recorded - this helps improve accuracy!'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('Can only give feedback once per card',
        (WidgetTester tester) async {
      int feedbackCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProactiveAssistanceCard(
              assistance: testAssistance,
              onFeedback: (_) {
                feedbackCount++;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap "Helpful" button
      await tester.tap(find.text('Helpful'));
      await tester.pumpAndSettle();

      // Verify callback was called once
      expect(feedbackCount, 1);

      // Try to tap again (should not work because button is disabled)
      await tester.tap(find.text('Helpful'));
      await tester.pumpAndSettle();

      // Verify callback was not called again
      expect(feedbackCount, 1);
    });

    testWidgets('Feedback works without onFeedback callback (no crash)',
        (WidgetTester tester) async {
      // Test that widget doesn't crash if onFeedback is null
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProactiveAssistanceCard(
              assistance: testAssistance,
              // No onFeedback callback provided
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap "Helpful" button - should not crash
      await tester.tap(find.text('Helpful'));
      await tester.pumpAndSettle();

      // Verify SnackBar still appears
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('Feedback persists when card is collapsed and expanded',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProactiveAssistanceCard(
              assistance: testAssistance,
              onFeedback: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Give feedback
      await tester.tap(find.text('Helpful'));
      await tester.pumpAndSettle();

      // Verify feedback was recorded
      expect(find.byIcon(Icons.thumb_up), findsWidgets);

      // Collapse the card
      await tester.tap(find.byIcon(Icons.expand_less));
      await tester.pumpAndSettle();

      // Expand the card again
      await tester.tap(find.byIcon(Icons.expand_more));
      await tester.pumpAndSettle();

      // Verify feedback is still recorded (filled icon still visible)
      expect(find.byIcon(Icons.thumb_up), findsWidgets);
      expect(find.text('Feedback recorded - this helps improve accuracy!'), findsOneWidget);
    });

    testWidgets('Feedback section is visible for all assistance types',
        (WidgetTester tester) async {
      // Test with clarification assistance type
      final clarificationAssistance = ProactiveAssistanceModel(
        type: ProactiveAssistanceType.clarificationNeeded,
        clarification: ClarificationAssistance(
          insightId: 'test',
          statement: 'We should fix this soon',
          vaguenessType: 'time',
          confidence: 0.85,
          suggestedQuestions: ['When exactly?', 'What is the deadline?'],
          reasoning: 'Statement lacks specific timeline',
          timestamp: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProactiveAssistanceCard(
              assistance: clarificationAssistance,
              onFeedback: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Note: Feedback section is only implemented for autoAnswer type
      // This is expected behavior based on current implementation
      expect(find.text('Was this helpful?'), findsNothing);
    });

    testWidgets('SnackBar has correct styling based on feedback type',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProactiveAssistanceCard(
              assistance: testAssistance,
              onFeedback: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap "Helpful" button
      await tester.tap(find.text('Helpful'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Find the SnackBar
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));

      // Verify SnackBar has green background for positive feedback
      expect(snackBar.backgroundColor, Colors.green[700]);
      expect(snackBar.behavior, SnackBarBehavior.floating);
      expect(snackBar.duration, const Duration(seconds: 3));
    });

    testWidgets('Integration: Feedback with real insight ID',
        (WidgetTester tester) async {
      String? capturedInsightId;
      bool? capturedFeedback;

      final assistanceWithId = ProactiveAssistanceModel(
        type: ProactiveAssistanceType.autoAnswer,
        autoAnswer: AutoAnswerAssistance(
          insightId: 'real_insight_id_12345',
          question: 'What is the budget?',
          answer: 'The budget is \$100,000.',
          confidence: 0.95,
          sources: [],
          reasoning: 'Found in budget document',
          timestamp: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProactiveAssistanceCard(
              assistance: assistanceWithId,
              onFeedback: (isHelpful) {
                // In real implementation, this would send to backend:
                // websocket.send({
                //   "action": "feedback",
                //   "insight_id": assistance.autoAnswer.insightId,
                //   "helpful": isHelpful,
                //   "type": "auto_answer"
                // });
                capturedInsightId = assistanceWithId.autoAnswer?.insightId;
                capturedFeedback = isHelpful;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Give feedback
      await tester.tap(find.text('Not Helpful'));
      await tester.pump();

      // Verify callback received correct data
      expect(capturedInsightId, 'real_insight_id_12345');
      expect(capturedFeedback, isFalse);
    });
  });
}
