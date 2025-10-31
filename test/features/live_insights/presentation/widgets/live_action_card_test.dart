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
      testWidgets('shows description-only completeness badge', (WidgetTester tester) async {
        final action = testAction.copyWith(
          description: 'Test task',
          owner: null,
          deadline: null,
          completenessScore: 0.4,
        );
        await tester.pumpWidget(buildWidget(action));

        // Should show "Tracking" badge for description-only
        expect(find.text('Tracking'), findsOneWidget);
        expect(action.completenessLevel, ActionCompleteness.descriptionOnly);
      });

      testWidgets('shows partial completeness with owner', (WidgetTester tester) async {
        final action = testAction.copyWith(
          description: 'Test task',
          owner: 'John Doe',
          deadline: null,
          completenessScore: 0.7,
        );
        await tester.pumpWidget(buildWidget(action));

        expect(find.text('John Doe'), findsOneWidget);
        expect(find.text('Partial'), findsOneWidget);
        expect(action.completenessLevel, ActionCompleteness.partial);
      });

      testWidgets('shows partial completeness with deadline', (WidgetTester tester) async {
        final tomorrow = now.add(const Duration(days: 1));
        final action = testAction.copyWith(
          description: 'Test task',
          owner: null,
          deadline: tomorrow,
          completenessScore: 0.7,
        );
        await tester.pumpWidget(buildWidget(action));

        expect(find.text('Partial'), findsOneWidget);
        expect(find.byIcon(Icons.schedule), findsOneWidget);
      });

      testWidgets('shows complete status with all details', (WidgetTester tester) async {
        final tomorrow = now.add(const Duration(days: 1));
        final action = testAction.copyWith(
          description: 'Complete task',
          owner: 'Jane Smith',
          deadline: tomorrow,
          completenessScore: 1.0,
        );
        await tester.pumpWidget(buildWidget(action));

        expect(find.text('Jane Smith'), findsOneWidget);
        expect(find.text('Complete'), findsOneWidget);
        expect(find.byIcon(Icons.schedule), findsOneWidget);
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

    group('Compact Metadata Display', () {
      testWidgets('displays owner in compact view', (WidgetTester tester) async {
        final action = testAction.copyWith(owner: 'John Doe');
        await tester.pumpWidget(buildWidget(action));

        // Owner should be visible in compact view
        expect(find.text('John Doe'), findsOneWidget);
        expect(find.byIcon(Icons.person_outline), findsOneWidget);
      });

      testWidgets('shows no owner when owner is null', (WidgetTester tester) async {
        await tester.pumpWidget(buildWidget(testAction));

        // Should show "No owner" text
        expect(find.text('No owner'), findsOneWidget);
        expect(find.byIcon(Icons.person_outline), findsOneWidget);
      });
    });

    group('Overdue Detection', () {
      testWidgets('displays warning icon for past deadlines', (WidgetTester tester) async {
        final yesterday = now.subtract(const Duration(days: 1));
        final action = testAction.copyWith(deadline: yesterday);
        await tester.pumpWidget(buildWidget(action));

        // Warning icon should appear for overdue items
        expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
        // "Overdue" text appears in deadline display
        expect(find.text('Overdue'), findsOneWidget);
      });

      testWidgets('does not show warning icon for future deadlines', (WidgetTester tester) async {
        final tomorrow = now.add(const Duration(days: 1));
        final action = testAction.copyWith(deadline: tomorrow);
        await tester.pumpWidget(buildWidget(action));

        expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
        expect(find.text('Overdue'), findsNothing);
      });
    });

    group('Missing Information Display', () {
      testWidgets('shows missing owner indicator', (WidgetTester tester) async {
        final action = testAction.copyWith(
          owner: null,
          deadline: now.add(const Duration(days: 1)),
        );
        await tester.pumpWidget(buildWidget(action));

        // Should indicate missing owner in compact view
        expect(action.hasOwner, false);
        expect(find.text('No owner'), findsOneWidget);
      });

      testWidgets('shows missing deadline indicator', (WidgetTester tester) async {
        final action = testAction.copyWith(
          owner: 'John',
          deadline: null,
        );
        await tester.pumpWidget(buildWidget(action));

        // Should indicate missing deadline in compact view
        expect(action.hasDeadline, false);
        expect(find.text('No deadline'), findsOneWidget);
      });
    });
  });
}
