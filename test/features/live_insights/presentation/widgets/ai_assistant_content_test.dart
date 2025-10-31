import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_master_v2/features/live_insights/data/models/live_insight_model.dart';
import 'package:pm_master_v2/features/live_insights/presentation/widgets/ai_assistant_content.dart';
import 'package:pm_master_v2/features/live_insights/presentation/widgets/live_question_card.dart';
import 'package:pm_master_v2/features/live_insights/presentation/widgets/live_action_card.dart';

void main() {
  group('AIAssistantContentSection', () {
    late DateTime now;

    setUp(() {
      now = DateTime.now();
    });

    Widget buildWidget({
      List<LiveQuestion>? questions,
      List<LiveAction>? actions,
      Function(String)? onQuestionMarkAnswered,
      Function(String)? onQuestionDismiss,
      Function(String, String)? onActionAssignOwner,
      Function(String)? onActionMarkComplete,
      VoidCallback? onDismissAll,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: AIAssistantContentSection(
            questions: questions ?? [],
            actions: actions ?? [],
            onQuestionMarkAnswered: onQuestionMarkAnswered,
            onQuestionDismiss: onQuestionDismiss,
            onActionAssignOwner: onActionAssignOwner,
            onActionMarkComplete: onActionMarkComplete,
            onDismissAll: onDismissAll,
          ),
        ),
      );
    }

    group('Layout and Structure', () {
      testWidgets('displays section headers', (WidgetTester tester) async {
        await tester.pumpWidget(buildWidget());

        expect(find.text('Questions'), findsOneWidget);
        expect(find.text('Actions'), findsOneWidget);
      });

      testWidgets('displays questions section with icon and label', (WidgetTester tester) async {
        await tester.pumpWidget(buildWidget());

        expect(find.byIcon(Icons.help_outline), findsOneWidget);
        expect(find.text('Questions'), findsOneWidget);
      });

      testWidgets('displays actions section with icon and label', (WidgetTester tester) async {
        await tester.pumpWidget(buildWidget());

        expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
        expect(find.text('Actions'), findsOneWidget);
      });

      testWidgets('is scrollable', (WidgetTester tester) async {
        await tester.pumpWidget(buildWidget());

        expect(find.byType(SingleChildScrollView), findsOneWidget);
      });
    });

    group('Questions Display', () {
      testWidgets('displays question cards when questions provided', (WidgetTester tester) async {
        final questions = [
          LiveQuestion(
            id: 'q1',
            text: 'What is the budget?',
            timestamp: now,
            status: InsightStatus.searching,
          ),
          LiveQuestion(
            id: 'q2',
            text: 'Who is responsible?',
            timestamp: now,
            status: InsightStatus.monitoring,
          ),
        ];

        await tester.pumpWidget(buildWidget(questions: questions));

        expect(find.byType(LiveQuestionCard), findsNWidgets(2));
        expect(find.text('What is the budget?'), findsOneWidget);
        expect(find.text('Who is responsible?'), findsOneWidget);
      });

      testWidgets('displays correct question count', (WidgetTester tester) async {
        final questions = [
          LiveQuestion(id: 'q1', text: 'Q1', timestamp: now, status: InsightStatus.searching),
          LiveQuestion(id: 'q2', text: 'Q2', timestamp: now, status: InsightStatus.searching),
          LiveQuestion(id: 'q3', text: 'Q3', timestamp: now, status: InsightStatus.searching),
        ];

        await tester.pumpWidget(buildWidget(questions: questions));

        expect(find.text('3'), findsOneWidget);
      });

      testWidgets('displays empty state when no questions', (WidgetTester tester) async {
        await tester.pumpWidget(buildWidget(questions: []));

        expect(find.text('Listening for questions...'), findsOneWidget);
        expect(find.text('Questions detected in the conversation will appear here'), findsOneWidget);
        expect(find.byIcon(Icons.question_answer_outlined), findsOneWidget);
      });
    });

    group('Actions Display', () {
      testWidgets('displays action cards when actions provided', (WidgetTester tester) async {
        final actions = [
          LiveAction(
            id: 'a1',
            description: 'Update documentation',
            timestamp: now,
            status: InsightStatus.tracked,
          ),
          LiveAction(
            id: 'a2',
            description: 'Review code',
            timestamp: now,
            status: InsightStatus.complete,
          ),
        ];

        await tester.pumpWidget(buildWidget(actions: actions));

        expect(find.byType(LiveActionCard), findsNWidgets(2));
        expect(find.text('Update documentation'), findsOneWidget);
        expect(find.text('Review code'), findsOneWidget);
      });

      testWidgets('displays correct action count', (WidgetTester tester) async {
        final actions = [
          LiveAction(id: 'a1', description: 'A1', timestamp: now, status: InsightStatus.tracked),
          LiveAction(id: 'a2', description: 'A2', timestamp: now, status: InsightStatus.tracked),
          LiveAction(id: 'a3', description: 'A3', timestamp: now, status: InsightStatus.tracked),
          LiveAction(id: 'a4', description: 'A4', timestamp: now, status: InsightStatus.tracked),
        ];

        await tester.pumpWidget(buildWidget(actions: actions));

        expect(find.text('4'), findsOneWidget);
      });

      testWidgets('displays empty state when no actions', (WidgetTester tester) async {
        await tester.pumpWidget(buildWidget(actions: []));

        expect(find.text('Tracking actions...'), findsOneWidget);
        expect(find.text('Action items mentioned will appear here'), findsOneWidget);
        expect(find.byIcon(Icons.task_alt), findsOneWidget);
      });
    });

    group('Empty States', () {
      testWidgets('shows both empty states when no questions and no actions', (WidgetTester tester) async {
        await tester.pumpWidget(buildWidget());

        expect(find.text('Listening for questions...'), findsOneWidget);
        expect(find.text('Tracking actions...'), findsOneWidget);
      });

      testWidgets('shows only questions empty state when no questions but has actions', (WidgetTester tester) async {
        final actions = [
          LiveAction(id: 'a1', description: 'Test', timestamp: now, status: InsightStatus.tracked),
        ];

        await tester.pumpWidget(buildWidget(actions: actions));

        expect(find.text('Listening for questions...'), findsOneWidget);
        expect(find.text('Tracking actions...'), findsNothing);
      });

      testWidgets('shows only actions empty state when no actions but has questions', (WidgetTester tester) async {
        final questions = [
          LiveQuestion(id: 'q1', text: 'Test?', timestamp: now, status: InsightStatus.searching),
        ];

        await tester.pumpWidget(buildWidget(questions: questions));

        expect(find.text('Listening for questions...'), findsNothing);
        expect(find.text('Tracking actions...'), findsOneWidget);
      });
    });

    group('Dismiss All Functionality', () {
      testWidgets('displays Dismiss All button when callback provided and items exist', (WidgetTester tester) async {
        final questions = [
          LiveQuestion(id: 'q1', text: 'Q1', timestamp: now, status: InsightStatus.searching),
        ];

        bool dismissAllCalled = false;

        await tester.pumpWidget(buildWidget(
          questions: questions,
          onDismissAll: () => dismissAllCalled = true,
        ));

        expect(find.text('Dismiss All'), findsOneWidget);
        expect(find.byIcon(Icons.clear_all), findsOneWidget);

        await tester.tap(find.text('Dismiss All'));
        await tester.pumpAndSettle();

        expect(dismissAllCalled, true);
      });

      testWidgets('hides Dismiss All button when no items', (WidgetTester tester) async {
        await tester.pumpWidget(buildWidget(
          onDismissAll: () {},
        ));

        expect(find.text('Dismiss All'), findsNothing);
      });

      testWidgets('hides Dismiss All button when callback not provided', (WidgetTester tester) async {
        final questions = [
          LiveQuestion(id: 'q1', text: 'Q1', timestamp: now, status: InsightStatus.searching),
        ];

        await tester.pumpWidget(buildWidget(questions: questions));

        expect(find.text('Dismiss All'), findsNothing);
      });
    });

    group('Callbacks', () {
      // Note: Mark Answered and Follow-up buttons are not implemented in LiveQuestionCard
      // Only Dismiss functionality is tested

      testWidgets('propagates question dismiss callback', (WidgetTester tester) async {
        String? dismissedQuestionId;
        final questions = [
          LiveQuestion(
            id: 'q2',
            text: 'Test question?',
            timestamp: now,
            status: InsightStatus.searching,
            tierResults: [
              TierResult(
                tierType: TierType.rag,
                content: 'Test result',
                confidence: 0.9,
                foundAt: now,
              ),
            ],
          ),
        ];

        await tester.pumpWidget(buildWidget(
          questions: questions,
          onQuestionDismiss: (id) => dismissedQuestionId = id,
        ));

        // Expand question card and tap dismiss button
        await tester.tap(find.byType(LiveQuestionCard));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();

        expect(dismissedQuestionId, 'q2');
      });

      // Note: Action buttons (Mark Complete, Assign) are not implemented in LiveActionCard
      // These tests have been removed as the feature is not planned
    });

    group('Mixed Content', () {
      testWidgets('displays both questions and actions together', (WidgetTester tester) async {
        final questions = [
          LiveQuestion(id: 'q1', text: 'Question 1', timestamp: now, status: InsightStatus.searching),
          LiveQuestion(id: 'q2', text: 'Question 2', timestamp: now, status: InsightStatus.answered),
        ];

        final actions = [
          LiveAction(id: 'a1', description: 'Action 1', timestamp: now, status: InsightStatus.tracked),
          LiveAction(id: 'a2', description: 'Action 2', timestamp: now, status: InsightStatus.complete),
          LiveAction(id: 'a3', description: 'Action 3', timestamp: now, status: InsightStatus.tracked),
        ];

        await tester.pumpWidget(buildWidget(
          questions: questions,
          actions: actions,
        ));

        expect(find.byType(LiveQuestionCard), findsNWidgets(2));
        expect(find.byType(LiveActionCard), findsNWidgets(3));
        expect(find.text('2'), findsOneWidget); // question count
        expect(find.text('3'), findsOneWidget); // action count
      });

      testWidgets('displays correct section counts with mixed content', (WidgetTester tester) async {
        final questions = [
          LiveQuestion(id: 'q1', text: 'Q1', timestamp: now, status: InsightStatus.searching),
        ];

        final actions = [
          LiveAction(id: 'a1', description: 'A1', timestamp: now, status: InsightStatus.tracked),
          LiveAction(id: 'a2', description: 'A2', timestamp: now, status: InsightStatus.tracked),
        ];

        await tester.pumpWidget(buildWidget(
          questions: questions,
          actions: actions,
        ));

        // Find count badges
        final countTexts = tester.widgetList<Text>(
          find.descendant(
            of: find.byType(Container),
            matching: find.byType(Text),
          ),
        ).map((t) => t.data).toList();

        expect(countTexts.contains('1'), true); // 1 question
        expect(countTexts.contains('2'), true); // 2 actions
      });
    });

    group('Scroll Behavior', () {
      testWidgets('preserves scroll controller', (WidgetTester tester) async {
        final questions = List.generate(
          10,
          (i) => LiveQuestion(
            id: 'q$i',
            text: 'Question $i',
            timestamp: now,
            status: InsightStatus.searching,
          ),
        );

        await tester.pumpWidget(buildWidget(questions: questions));

        final scrollView = tester.widget<SingleChildScrollView>(
          find.byType(SingleChildScrollView),
        );

        expect(scrollView.controller, isNotNull);
      });

      testWidgets('uses AlwaysScrollableScrollPhysics', (WidgetTester tester) async {
        await tester.pumpWidget(buildWidget());

        final scrollView = tester.widget<SingleChildScrollView>(
          find.byType(SingleChildScrollView),
        );

        expect(scrollView.physics, isA<AlwaysScrollableScrollPhysics>());
      });
    });

    group('Live Insights Header', () {
      testWidgets('displays Live Insights header when items exist', (WidgetTester tester) async {
        final questions = [
          LiveQuestion(id: 'q1', text: 'Test', timestamp: now, status: InsightStatus.searching),
        ];

        await tester.pumpWidget(buildWidget(questions: questions));

        expect(find.text('Live Insights'), findsOneWidget);
      });

      testWidgets('hides Live Insights header when no items', (WidgetTester tester) async {
        await tester.pumpWidget(buildWidget());

        expect(find.text('Live Insights'), findsNothing);
      });
    });
  });
}
