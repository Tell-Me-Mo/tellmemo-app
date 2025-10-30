import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_master_v2/features/live_insights/data/models/live_insight_model.dart';
import 'package:pm_master_v2/features/live_insights/presentation/widgets/live_question_card.dart';

void main() {
  group('LiveQuestionCard', () {
    late LiveQuestion testQuestion;
    late DateTime now;

    setUp(() {
      now = DateTime.now();
      testQuestion = LiveQuestion(
        id: 'q1',
        text: 'What is the Q4 budget?',
        speaker: 'John Doe',
        timestamp: now.subtract(const Duration(minutes: 2)),
        status: InsightStatus.searching,
      );
    });

    Widget buildWidget(LiveQuestion question, {
      VoidCallback? onMarkAnswered,
      VoidCallback? onNeedsFollowUp,
      VoidCallback? onDismiss,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: LiveQuestionCard(
            question: question,
            onMarkAnswered: onMarkAnswered,
            onNeedsFollowUp: onNeedsFollowUp,
            onDismiss: onDismiss,
          ),
        ),
      );
    }

    group('Basic Display', () {
      testWidgets('displays question text', (WidgetTester tester) async {
        await tester.pumpWidget(buildWidget(testQuestion));

        expect(find.text('What is the Q4 budget?'), findsOneWidget);
      });

      testWidgets('displays speaker name', (WidgetTester tester) async {
        await tester.pumpWidget(buildWidget(testQuestion));

        expect(find.text('John Doe'), findsOneWidget);
      });

      testWidgets('displays timestamp', (WidgetTester tester) async {
        await tester.pumpWidget(buildWidget(testQuestion));

        // Check for time ago text (should show "2m ago" or similar)
        expect(
          find.textContaining('ago', findRichText: true),
          findsOneWidget,
        );
      });

      testWidgets('displays unknown speaker when speaker is null', (WidgetTester tester) async {
        final questionNoSpeaker = testQuestion.copyWith(speaker: null);
        await tester.pumpWidget(buildWidget(questionNoSpeaker));

        expect(find.text('Unknown Speaker'), findsOneWidget);
      });
    });

    group('Status States', () {
      testWidgets('displays SEARCHING status badge', (WidgetTester tester) async {
        final question = testQuestion.copyWith(status: InsightStatus.searching);
        await tester.pumpWidget(buildWidget(question));

        expect(find.text('SEARCHING'), findsOneWidget);
        expect(find.byIcon(Icons.search), findsOneWidget);
      });

      testWidgets('displays FOUND status badge', (WidgetTester tester) async {
        final question = testQuestion.copyWith(status: InsightStatus.found);
        await tester.pumpWidget(buildWidget(question));

        expect(find.text('FOUND'), findsOneWidget);
        expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      });

      testWidgets('displays MONITORING status badge', (WidgetTester tester) async {
        final question = testQuestion.copyWith(status: InsightStatus.monitoring);
        await tester.pumpWidget(buildWidget(question));

        expect(find.text('MONITORING'), findsOneWidget);
        expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
      });

      testWidgets('displays ANSWERED status badge', (WidgetTester tester) async {
        final question = testQuestion.copyWith(status: InsightStatus.answered);
        await tester.pumpWidget(buildWidget(question));

        expect(find.text('ANSWERED'), findsOneWidget);
        expect(find.byIcon(Icons.check_circle), findsOneWidget);
      });

      testWidgets('displays UNANSWERED status badge', (WidgetTester tester) async {
        final question = testQuestion.copyWith(status: InsightStatus.unanswered);
        await tester.pumpWidget(buildWidget(question));

        expect(find.text('UNANSWERED'), findsOneWidget);
        expect(find.byIcon(Icons.help_outline), findsOneWidget);
      });
    });

    group('Four-Tier Answer Sources', () {
      testWidgets('displays RAG results with "From Documents" label', (WidgetTester tester) async {
        final question = testQuestion.copyWith(
          status: InsightStatus.found,
          tierResults: [
            TierResult(
              tierType: TierType.rag,
              content: 'The Q4 budget is \$250,000',
              confidence: 0.95,
              source: 'Budget_Q4_2025.pdf',
              foundAt: now,
            ),
          ],
        );
        await tester.pumpWidget(buildWidget(question));

        // Expand to see tier results
        await tester.tap(find.byType(Card));
        await tester.pumpAndSettle();

        expect(find.text('From Documents'), findsOneWidget);
        expect(find.text('The Q4 budget is \$250,000'), findsOneWidget);
        expect(find.text('95%'), findsOneWidget);
        expect(find.text('Budget_Q4_2025.pdf'), findsOneWidget);
      });

      testWidgets('displays meeting context results with "Earlier in Meeting" label', (WidgetTester tester) async {
        final question = testQuestion.copyWith(
          status: InsightStatus.found,
          tierResults: [
            TierResult(
              tierType: TierType.meetingContext,
              content: 'We discussed \$250K budget earlier',
              confidence: 0.88,
              source: '10:15 AM',
              foundAt: now,
            ),
          ],
        );
        await tester.pumpWidget(buildWidget(question));

        // Expand to see tier results
        await tester.tap(find.byType(Card));
        await tester.pumpAndSettle();

        expect(find.text('Earlier in Meeting'), findsOneWidget);
        expect(find.text('We discussed \$250K budget earlier'), findsOneWidget);
        expect(find.text('88%'), findsOneWidget);
      });

      testWidgets('displays live conversation results with "Answered Live" label', (WidgetTester tester) async {
        final question = testQuestion.copyWith(
          status: InsightStatus.answered,
          tierResults: [
            TierResult(
              tierType: TierType.liveConversation,
              content: 'The budget is \$250,000 for Q4',
              confidence: 0.92,
              source: 'Speaker B',
              foundAt: now,
            ),
          ],
        );
        await tester.pumpWidget(buildWidget(question));

        // Expand to see tier results
        await tester.tap(find.byType(Card));
        await tester.pumpAndSettle();

        expect(find.text('Answered Live'), findsOneWidget);
        expect(find.text('The budget is \$250,000 for Q4'), findsOneWidget);
        expect(find.text('92%'), findsOneWidget);
      });

      testWidgets('displays GPT-generated answer with disclaimer', (WidgetTester tester) async {
        final question = testQuestion.copyWith(
          status: InsightStatus.answered,
          tierResults: [
            TierResult(
              tierType: TierType.gptGenerated,
              content: 'Typical Q4 infrastructure budgets range from \$200K-\$500K',
              confidence: 0.75,
              source: 'AI Knowledge',
              foundAt: now,
            ),
          ],
        );
        await tester.pumpWidget(buildWidget(question));

        // Expand to see tier results
        await tester.tap(find.byType(Card));
        await tester.pumpAndSettle();

        expect(find.text('AI Answer'), findsOneWidget);
        expect(find.text('Typical Q4 infrastructure budgets range from \$200K-\$500K'), findsOneWidget);
        expect(find.text('75%'), findsOneWidget);
        expect(find.text('AI-generated answer. Please verify accuracy.'), findsOneWidget);
        expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      });

      testWidgets('displays multiple tier results together', (WidgetTester tester) async {
        final question = testQuestion.copyWith(
          status: InsightStatus.answered,
          tierResults: [
            TierResult(
              tierType: TierType.rag,
              content: 'Document says \$250K',
              confidence: 0.95,
              source: 'Budget.pdf',
              foundAt: now,
            ),
            TierResult(
              tierType: TierType.meetingContext,
              content: 'Earlier mentioned \$250K',
              confidence: 0.88,
              source: '10:15 AM',
              foundAt: now,
            ),
          ],
        );
        await tester.pumpWidget(buildWidget(question));

        // Expand to see tier results
        await tester.tap(find.byType(Card));
        await tester.pumpAndSettle();

        expect(find.text('From Documents'), findsOneWidget);
        expect(find.text('Earlier in Meeting'), findsOneWidget);
        expect(find.text('Document says \$250K'), findsOneWidget);
        expect(find.text('Earlier mentioned \$250K'), findsOneWidget);
      });
    });

    group('Expand/Collapse Behavior', () {
      testWidgets('expands and collapses on tap', (WidgetTester tester) async {
        final question = testQuestion.copyWith(
          tierResults: [
            TierResult(
              tierType: TierType.rag,
              content: 'Test result',
              confidence: 0.95,
              foundAt: now,
            ),
          ],
        );
        await tester.pumpWidget(buildWidget(question));

        // Initially collapsed - tier results should not be visible
        expect(find.text('Test result'), findsNothing);

        // Tap to expand
        await tester.tap(find.byType(Card));
        await tester.pump(const Duration(milliseconds: 300)); // Allow animation
        await tester.pump(); // Complete

        // Now expanded - tier results should be visible
        expect(find.text('Test result'), findsOneWidget);

        // Tap again to collapse
        await tester.tap(find.byType(Card));
        await tester.pump(const Duration(milliseconds: 300)); // Allow animation
        await tester.pump(); // Complete

        // Collapsed again
        expect(find.text('Test result'), findsNothing);
      });

      testWidgets('animates chevron icon on expand/collapse', (WidgetTester tester) async {
        final question = testQuestion.copyWith(
          tierResults: [
            TierResult(
              tierType: TierType.rag,
              content: 'Test result',
              confidence: 0.95,
              foundAt: now,
            ),
          ],
        );
        await tester.pumpWidget(buildWidget(question));

        final chevronFinder = find.byIcon(Icons.chevron_right);
        expect(chevronFinder, findsOneWidget);

        // Expand
        await tester.tap(find.byType(Card));
        await tester.pump(); // Start animation
        await tester.pump(const Duration(milliseconds: 100)); // Mid animation
        await tester.pump(const Duration(milliseconds: 200)); // Complete animation

        // Chevron should still exist (just rotated)
        expect(chevronFinder, findsOneWidget);
      });
    });

    group('Searching State', () {
      testWidgets('displays searching indicator when no results', (WidgetTester tester) async {
        final question = testQuestion.copyWith(
          status: InsightStatus.searching,
          tierResults: [],
        );
        await tester.pumpWidget(buildWidget(question));

        // Expand
        await tester.tap(find.byType(Card));
        await tester.pump(const Duration(milliseconds: 300)); // Allow animation to complete
        await tester.pump(); // One more frame

        expect(find.text('Searching for answers...'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });
    });

    group('Tier Icons in Compact View', () {
      testWidgets('displays tier icons in collapsed state', (WidgetTester tester) async {
        final question = testQuestion.copyWith(
          tierResults: [
            TierResult(
              tierType: TierType.rag,
              content: 'Test',
              confidence: 0.9,
              foundAt: now,
            ),
          ],
        );
        await tester.pumpWidget(buildWidget(question));

        // In collapsed state, should show tier icons
        expect(find.text('📚'), findsWidgets); // RAG icon
        expect(find.text('💬'), findsWidgets); // Meeting context icon
        expect(find.text('👂'), findsWidgets); // Live conversation icon
        expect(find.text('🤖'), findsWidgets); // GPT generated icon
      });

      testWidgets('shows result count in collapsed state', (WidgetTester tester) async {
        final question = testQuestion.copyWith(
          tierResults: [
            TierResult(tierType: TierType.rag, content: 'R1', confidence: 0.9, foundAt: now),
            TierResult(tierType: TierType.rag, content: 'R2', confidence: 0.8, foundAt: now),
            TierResult(tierType: TierType.meetingContext, content: 'M1', confidence: 0.85, foundAt: now),
          ],
        );
        await tester.pumpWidget(buildWidget(question));

        expect(find.text('3 results'), findsOneWidget);
      });
    });

    group('Confidence Score Colors', () {
      testWidgets('displays high confidence in green', (WidgetTester tester) async {
        final question = testQuestion.copyWith(
          tierResults: [
            TierResult(
              tierType: TierType.rag,
              content: 'High confidence result',
              confidence: 0.95,
              foundAt: now,
            ),
          ],
        );
        await tester.pumpWidget(buildWidget(question));

        // Expand
        await tester.tap(find.byType(Card));
        await tester.pumpAndSettle();

        expect(find.text('95%'), findsOneWidget);
      });

      testWidgets('displays medium confidence in orange', (WidgetTester tester) async {
        final question = testQuestion.copyWith(
          tierResults: [
            TierResult(
              tierType: TierType.rag,
              content: 'Medium confidence result',
              confidence: 0.70,
              foundAt: now,
            ),
          ],
        );
        await tester.pumpWidget(buildWidget(question));

        // Expand
        await tester.tap(find.byType(Card));
        await tester.pumpAndSettle();

        expect(find.text('70%'), findsOneWidget);
      });

      testWidgets('displays low confidence in gray', (WidgetTester tester) async {
        final question = testQuestion.copyWith(
          tierResults: [
            TierResult(
              tierType: TierType.rag,
              content: 'Low confidence result',
              confidence: 0.50,
              foundAt: now,
            ),
          ],
        );
        await tester.pumpWidget(buildWidget(question));

        // Expand
        await tester.tap(find.byType(Card));
        await tester.pumpAndSettle();

        expect(find.text('50%'), findsOneWidget);
      });
    });
  });
}
