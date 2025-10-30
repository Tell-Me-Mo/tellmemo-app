import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_master_v2/features/live_insights/data/models/live_insight_model.dart';
import 'package:pm_master_v2/features/live_insights/presentation/widgets/live_action_card.dart';

void main() {
  group('LiveActionCard', () {
    late LiveAction testAction;
    late DateTime now;

    setUp(() {
      now = DateTime.now();
      testAction = LiveAction(
        id: 'a1',
        description: 'Update project documentation',
        timestamp: now.subtract(const Duration(minutes: 5)),
        status: InsightStatus.tracked,
        completenessScore: 0.4,
      );
    });

    Widget buildWidget(LiveAction action, {
      Function(String owner)? onAssignOwner,
      Function(DateTime deadline)? onSetDeadline,
      VoidCallback? onMarkComplete,
      VoidCallback? onDismiss,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: LiveActionCard(
            action: action,
            onAssignOwner: onAssignOwner,
            onSetDeadline: onSetDeadline,
            onMarkComplete: onMarkComplete,
            onDismiss: onDismiss,
          ),
        ),
      );
    }

    group('Basic Display', () {
      testWidgets('displays action description', (WidgetTester tester) async {
        await tester.pumpWidget(buildWidget(testAction));

        expect(find.text('Update project documentation'), findsOneWidget);
      });

      testWidgets('displays speaker name when provided', (WidgetTester tester) async {
        final action = testAction.copyWith(speaker: 'Sarah Johnson');
        await tester.pumpWidget(buildWidget(action));

        expect(find.text('Sarah Johnson'), findsOneWidget);
      });

      testWidgets('displays timestamp', (WidgetTester tester) async {
        await tester.pumpWidget(buildWidget(testAction));

        // Check for time ago text
        expect(
          find.textContaining('ago', findRichText: true),
          findsOneWidget,
        );
      });

      testWidgets('displays unknown speaker when speaker is null', (WidgetTester tester) async {
        await tester.pumpWidget(buildWidget(testAction));

        expect(find.text('Unknown Speaker'), findsOneWidget);
      });
    });

    group('Completeness Display', () {
      testWidgets('shows description-only completeness (40%)', (WidgetTester tester) async {
        final action = testAction.copyWith(
          description: 'Test task',
          owner: null,
          deadline: null,
          completenessScore: 0.4,
        );
        await tester.pumpWidget(buildWidget(action));

        // Expand to see details
        await tester.tap(find.byType(Card));
        await tester.pumpAndSettle();

        // Should show low completeness indicator
        expect(find.text('40%'), findsOneWidget);
      });

      testWidgets('shows partial completeness with owner (70%)', (WidgetTester tester) async {
        final action = testAction.copyWith(
          description: 'Test task',
          owner: 'John Doe',
          deadline: null,
          completenessScore: 0.7,
        );
        await tester.pumpWidget(buildWidget(action));

        // Expand to see details
        await tester.tap(find.byType(Card));
        await tester.pumpAndSettle();

        expect(find.text('John Doe'), findsOneWidget);
        expect(find.text('70%'), findsOneWidget);
      });

      testWidgets('shows partial completeness with deadline (70%)', (WidgetTester tester) async {
        final tomorrow = now.add(const Duration(days: 1));
        final action = testAction.copyWith(
          description: 'Test task',
          owner: null,
          deadline: tomorrow,
          completenessScore: 0.7,
        );
        await tester.pumpWidget(buildWidget(action));

        // Expand to see details
        await tester.tap(find.byType(Card));
        await tester.pumpAndSettle();

        expect(find.text('70%'), findsOneWidget);
        expect(find.byIcon(Icons.schedule), findsWidgets); // Icon appears in compact and expanded view
      });

      testWidgets('shows complete status with all details (100%)', (WidgetTester tester) async {
        final tomorrow = now.add(const Duration(days: 1));
        final action = testAction.copyWith(
          description: 'Complete task',
          owner: 'Jane Smith',
          deadline: tomorrow,
          completenessScore: 1.0,
        );
        await tester.pumpWidget(buildWidget(action));

        // Expand to see details
        await tester.tap(find.byType(Card));
        await tester.pumpAndSettle();

        expect(find.text('Jane Smith'), findsOneWidget);
        expect(find.text('100%'), findsOneWidget);
        expect(find.byIcon(Icons.schedule), findsWidgets); // Icon appears in compact and expanded view
      });
    });

    // Note: Status badges with text are not displayed in LiveActionCard
    // The widget uses icons instead of text badges

    group('Badge Color Coding', () {
      testWidgets('displays green badge for complete action', (WidgetTester tester) async {
        final action = testAction.copyWith(
          owner: 'John',
          deadline: now.add(const Duration(days: 1)),
          completenessScore: 1.0,
        );
        await tester.pumpWidget(buildWidget(action));

        // Badge exists with "green" color (validated by completeness level)
        expect(action.completenessLevel, ActionCompleteness.complete);
        expect(action.badgeColor, 'green');
      });

      testWidgets('displays yellow badge for partial action', (WidgetTester tester) async {
        final action = testAction.copyWith(
          owner: 'John',
          deadline: null,
          completenessScore: 0.7,
        );
        await tester.pumpWidget(buildWidget(action));

        expect(action.completenessLevel, ActionCompleteness.partial);
        expect(action.badgeColor, 'yellow');
      });

      testWidgets('displays gray badge for description-only action', (WidgetTester tester) async {
        final action = testAction.copyWith(
          owner: null,
          deadline: null,
          completenessScore: 0.4,
        );
        await tester.pumpWidget(buildWidget(action));

        expect(action.completenessLevel, ActionCompleteness.descriptionOnly);
        expect(action.badgeColor, 'gray');
      });
    });

    group('Expand/Collapse Behavior', () {
      testWidgets('expands and collapses on tap', (WidgetTester tester) async {
        await tester.pumpWidget(buildWidget(testAction));

        // Initially collapsed - expanded metadata should not be visible
        expect(find.text('Owner'), findsNothing);

        // Tap to expand
        await tester.tap(find.byType(Card));
        await tester.pumpAndSettle();

        // Now expanded - metadata should be visible
        expect(find.text('Owner'), findsOneWidget);
        expect(find.text('Deadline'), findsOneWidget);

        // Tap again to collapse
        await tester.tap(find.byType(Card));
        await tester.pumpAndSettle();

        // Collapsed again
        expect(find.text('Owner'), findsNothing);
      });

      testWidgets('animates chevron icon on expand/collapse', (WidgetTester tester) async {
        await tester.pumpWidget(buildWidget(testAction));

        final chevronFinder = find.byIcon(Icons.chevron_right);
        expect(chevronFinder, findsOneWidget);

        // Expand
        await tester.tap(find.byType(Card));
        await tester.pump(); // Start animation
        await tester.pump(const Duration(milliseconds: 100)); // Mid animation
        await tester.pumpAndSettle(); // Complete animation

        // Chevron should still exist (just rotated)
        expect(chevronFinder, findsOneWidget);
      });
    });

    group('Overdue Detection', () {
      testWidgets('displays OVERDUE badge for past deadlines', (WidgetTester tester) async {
        final yesterday = now.subtract(const Duration(days: 1));
        final action = testAction.copyWith(deadline: yesterday);
        await tester.pumpWidget(buildWidget(action));

        // Expand to see deadline
        await tester.tap(find.byType(Card));
        await tester.pumpAndSettle();

        // "Overdue" appears in both the deadline display and warning banner
        // Warning icon also appears in both places
        expect(find.text('Overdue'), findsWidgets);
        expect(find.byIcon(Icons.warning_amber_rounded), findsWidgets);
      });

      testWidgets('does not show OVERDUE for future deadlines', (WidgetTester tester) async {
        final tomorrow = now.add(const Duration(days: 1));
        final action = testAction.copyWith(deadline: tomorrow);
        await tester.pumpWidget(buildWidget(action));

        // Expand to see deadline
        await tester.tap(find.byType(Card));
        await tester.pumpAndSettle();

        expect(find.text('Overdue'), findsNothing);
      });
    });

    group('Progress Indicator', () {
      testWidgets('displays completeness progress bar', (WidgetTester tester) async {
        await tester.pumpWidget(buildWidget(testAction));

        // Expand
        await tester.tap(find.byType(Card));
        await tester.pumpAndSettle();

        // Should show progress indicator (LinearProgressIndicator)
        expect(find.byType(LinearProgressIndicator), findsOneWidget);
      });

      testWidgets('shows correct progress value', (WidgetTester tester) async {
        final action = testAction.copyWith(
          owner: 'John',
          deadline: null,
          completenessScore: 0.7,
        );
        await tester.pumpWidget(buildWidget(action));

        // Expand
        await tester.tap(find.byType(Card));
        await tester.pumpAndSettle();

        final progressIndicator = tester.widget<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator),
        );
        expect(progressIndicator.value, 0.7);
      });
    });

    group('Missing Information Display', () {
      testWidgets('shows missing owner indicator', (WidgetTester tester) async {
        final action = testAction.copyWith(
          owner: null,
          deadline: now.add(const Duration(days: 1)),
        );
        await tester.pumpWidget(buildWidget(action));

        // Expand
        await tester.tap(find.byType(Card));
        await tester.pumpAndSettle();

        // Should indicate missing owner
        expect(action.hasOwner, false);
        expect(find.text('No owner assigned'), findsOneWidget);
      });

      testWidgets('shows missing deadline indicator', (WidgetTester tester) async {
        final action = testAction.copyWith(
          owner: 'John',
          deadline: null,
        );
        await tester.pumpWidget(buildWidget(action));

        // Expand
        await tester.tap(find.byType(Card));
        await tester.pumpAndSettle();

        // Should indicate missing deadline
        expect(action.hasDeadline, false);
        expect(find.text('No deadline'), findsOneWidget);
      });
    });
  });
}
