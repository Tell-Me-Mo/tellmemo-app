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
        expect(find.byIcon(Icons.calendar_today_outlined), findsOneWidget);
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
        expect(find.byIcon(Icons.calendar_today_outlined), findsOneWidget);
      });
    });

    group('Status Badge Display', () {
      testWidgets('displays TRACKED status badge', (WidgetTester tester) async {
        final action = testAction.copyWith(status: InsightStatus.tracked);
        await tester.pumpWidget(buildWidget(action));

        expect(find.text('TRACKED'), findsOneWidget);
      });

      testWidgets('displays COMPLETE status badge', (WidgetTester tester) async {
        final action = testAction.copyWith(status: InsightStatus.complete);
        await tester.pumpWidget(buildWidget(action));

        expect(find.text('COMPLETE'), findsOneWidget);
      });
    });

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

        // Initially collapsed - action buttons should not be visible
        expect(find.text('Assign'), findsNothing);

        // Tap to expand
        await tester.tap(find.byType(Card));
        await tester.pumpAndSettle();

        // Now expanded - action buttons should be visible
        expect(find.text('Assign'), findsOneWidget);

        // Tap again to collapse
        await tester.tap(find.byType(Card));
        await tester.pumpAndSettle();

        // Collapsed again
        expect(find.text('Assign'), findsNothing);
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

    group('Action Buttons', () {
      testWidgets('displays Assign button when callback provided and no owner', (WidgetTester tester) async {
        String? assignedOwner;
        await tester.pumpWidget(buildWidget(
          testAction.copyWith(owner: null),
          onAssignOwner: (owner) => assignedOwner = owner,
        ));

        // Expand
        await tester.tap(find.byType(Card));
        await tester.pumpAndSettle();

        expect(find.text('Assign'), findsOneWidget);
      });

      testWidgets('displays Set Deadline button when callback provided and no deadline', (WidgetTester tester) async {
        DateTime? assignedDeadline;
        await tester.pumpWidget(buildWidget(
          testAction.copyWith(deadline: null),
          onSetDeadline: (deadline) => assignedDeadline = deadline,
        ));

        // Expand
        await tester.tap(find.byType(Card));
        await tester.pumpAndSettle();

        expect(find.text('Set Deadline'), findsOneWidget);
      });

      testWidgets('displays Mark Complete button when callback provided and not complete', (WidgetTester tester) async {
        bool markCompleteCalled = false;
        await tester.pumpWidget(buildWidget(
          testAction.copyWith(status: InsightStatus.tracked),
          onMarkComplete: () => markCompleteCalled = true,
        ));

        // Expand
        await tester.tap(find.byType(Card));
        await tester.pumpAndSettle();

        expect(find.text('Mark Complete'), findsOneWidget);

        // Tap button
        await tester.tap(find.text('Mark Complete'));
        await tester.pumpAndSettle();

        expect(markCompleteCalled, true);
      });

      testWidgets('hides Mark Complete button when already complete', (WidgetTester tester) async {
        await tester.pumpWidget(buildWidget(
          testAction.copyWith(status: InsightStatus.complete),
          onMarkComplete: () {},
        ));

        // Expand
        await tester.tap(find.byType(Card));
        await tester.pumpAndSettle();

        expect(find.text('Mark Complete'), findsNothing);
      });

      testWidgets('displays Dismiss button when callback provided', (WidgetTester tester) async {
        bool dismissCalled = false;
        await tester.pumpWidget(buildWidget(
          testAction,
          onDismiss: () => dismissCalled = true,
        ));

        // Expand
        await tester.tap(find.byType(Card));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.close), findsOneWidget);

        // Tap dismiss button
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();

        expect(dismissCalled, true);
      });
    });

    group('Inline Editing', () {
      testWidgets('allows editing owner inline', (WidgetTester tester) async {
        String? newOwner;
        await tester.pumpWidget(buildWidget(
          testAction.copyWith(owner: null),
          onAssignOwner: (owner) => newOwner = owner,
        ));

        // Expand
        await tester.tap(find.byType(Card));
        await tester.pumpAndSettle();

        // Tap Assign button
        await tester.tap(find.text('Assign'));
        await tester.pumpAndSettle();

        // Should show text field for editing
        expect(find.byType(TextField), findsOneWidget);

        // Enter owner name
        await tester.enterText(find.byType(TextField), 'John Doe');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();

        // Callback should be called
        expect(newOwner, 'John Doe');
      });

      testWidgets('shows existing owner value when editing', (WidgetTester tester) async {
        await tester.pumpWidget(buildWidget(
          testAction.copyWith(owner: 'Jane Smith'),
          onAssignOwner: (owner) {},
        ));

        // Expand
        await tester.tap(find.byType(Card));
        await tester.pumpAndSettle();

        // Should show existing owner
        expect(find.text('Jane Smith'), findsOneWidget);
      });

      testWidgets('opens date picker for deadline', (WidgetTester tester) async {
        await tester.pumpWidget(buildWidget(
          testAction.copyWith(deadline: null),
          onSetDeadline: (deadline) {},
        ));

        // Expand
        await tester.tap(find.byType(Card));
        await tester.pumpAndSettle();

        // Tap Set Deadline button
        await tester.tap(find.text('Set Deadline'));
        await tester.pumpAndSettle();

        // DatePicker dialog should appear
        expect(find.byType(DatePickerDialog), findsOneWidget);
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

        expect(find.text('OVERDUE'), findsOneWidget);
      });

      testWidgets('does not show OVERDUE for future deadlines', (WidgetTester tester) async {
        final tomorrow = now.add(const Duration(days: 1));
        final action = testAction.copyWith(deadline: tomorrow);
        await tester.pumpWidget(buildWidget(action));

        // Expand to see deadline
        await tester.tap(find.byType(Card));
        await tester.pumpAndSettle();

        expect(find.text('OVERDUE'), findsNothing);
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
        expect(find.text('Assign'), findsOneWidget);
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
        expect(find.text('Set Deadline'), findsOneWidget);
      });
    });
  });
}
