import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_master_v2/features/summaries/data/models/summary_model.dart';
import 'package:pm_master_v2/features/summaries/presentation/widgets/enhanced_action_items_widget.dart';

void main() {
  group('EnhancedActionItemsWidget', () {
    testWidgets('displays action item description', (WidgetTester tester) async {
      // Arrange
      final actionItems = [
        const ActionItem(
          description: 'Complete project documentation',
          urgency: 'medium',
        ),
      ];

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EnhancedActionItemsWidget(actionItems: actionItems),
          ),
        ),
      );

      // Assert
      expect(find.text('Complete project documentation'), findsOneWidget);
    });

    testWidgets('displays assignee when provided', (WidgetTester tester) async {
      // Arrange
      final actionItems = [
        const ActionItem(
          description: 'Review code changes',
          urgency: 'high',
          assignee: 'John Doe',
        ),
      ];

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EnhancedActionItemsWidget(actionItems: actionItems),
          ),
        ),
      );

      // Assert
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.byIcon(Icons.person_outline), findsOneWidget);
    });

    testWidgets('displays due date when provided', (WidgetTester tester) async {
      // Arrange
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final actionItems = [
        ActionItem(
          description: 'Submit report',
          urgency: 'medium',
          dueDate: tomorrow.toUtc().toIso8601String().split('.')[0], // ISO 8601 without milliseconds
        ),
      ];

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EnhancedActionItemsWidget(actionItems: actionItems),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.schedule_outlined), findsOneWidget);
    });

    testWidgets('displays OVERDUE badge for past due dates', (WidgetTester tester) async {
      // Arrange
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final actionItems = [
        ActionItem(
          description: 'Overdue task',
          urgency: 'medium',
          dueDate: yesterday.toUtc().toIso8601String().split('.')[0],
        ),
      ];

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EnhancedActionItemsWidget(actionItems: actionItems),
          ),
        ),
      );

      // Assert
      expect(find.text('OVERDUE'), findsOneWidget);
    });

    testWidgets('displays HIGH urgency badge', (WidgetTester tester) async {
      // Arrange
      final actionItems = [
        const ActionItem(
          description: 'Critical bug fix',
          urgency: 'high',
        ),
      ];

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EnhancedActionItemsWidget(actionItems: actionItems),
          ),
        ),
      );

      // Assert
      expect(find.text('HIGH'), findsOneWidget);
    });

    testWidgets('displays CRITICAL urgency badge', (WidgetTester tester) async {
      // Arrange
      final actionItems = [
        const ActionItem(
          description: 'Security vulnerability fix',
          urgency: 'critical',
        ),
      ];

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EnhancedActionItemsWidget(actionItems: actionItems),
          ),
        ),
      );

      // Assert
      expect(find.text('CRITICAL'), findsOneWidget);
    });

    testWidgets('does not display badge for medium urgency', (WidgetTester tester) async {
      // Arrange
      final actionItems = [
        const ActionItem(
          description: 'Regular task',
          urgency: 'medium',
        ),
      ];

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EnhancedActionItemsWidget(actionItems: actionItems),
          ),
        ),
      );

      // Assert
      expect(find.text('MEDIUM'), findsNothing);
    });

    testWidgets('does not display badge for low urgency', (WidgetTester tester) async {
      // Arrange
      final actionItems = [
        const ActionItem(
          description: 'Low priority task',
          urgency: 'low',
        ),
      ];

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EnhancedActionItemsWidget(actionItems: actionItems),
          ),
        ),
      );

      // Assert
      expect(find.text('LOW'), findsNothing);
    });

    testWidgets('displays multiple action items', (WidgetTester tester) async {
      // Arrange
      final actionItems = [
        const ActionItem(
          description: 'Task 1',
          urgency: 'high',
        ),
        const ActionItem(
          description: 'Task 2',
          urgency: 'medium',
        ),
        const ActionItem(
          description: 'Task 3',
          urgency: 'low',
        ),
      ];

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EnhancedActionItemsWidget(actionItems: actionItems),
          ),
        ),
      );

      // Assert
      expect(find.text('Task 1'), findsOneWidget);
      expect(find.text('Task 2'), findsOneWidget);
      expect(find.text('Task 3'), findsOneWidget);
    });

    testWidgets('displays both assignee and due date', (WidgetTester tester) async {
      // Arrange
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final actionItems = [
        ActionItem(
          description: 'Complete review',
          urgency: 'high',
          assignee: 'Jane Smith',
          dueDate: tomorrow.toUtc().toIso8601String().split('.')[0],
        ),
      ];

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EnhancedActionItemsWidget(actionItems: actionItems),
          ),
        ),
      );

      // Assert
      expect(find.text('Jane Smith'), findsOneWidget);
      expect(find.byIcon(Icons.person_outline), findsOneWidget);
      expect(find.byIcon(Icons.schedule_outlined), findsOneWidget);
    });

    testWidgets('displays urgency status indicator as colored dot', (WidgetTester tester) async {
      // Arrange
      final actionItems = [
        const ActionItem(
          description: 'Task with status indicator',
          urgency: 'high',
        ),
      ];

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EnhancedActionItemsWidget(actionItems: actionItems),
          ),
        ),
      );

      // Assert
      // Find all containers and look for one with circular shape decoration
      final containers = tester.widgetList<Container>(find.byType(Container));
      final circularContainers = containers.where((container) {
        final decoration = container.decoration;
        return decoration is BoxDecoration && decoration.shape == BoxShape.circle;
      });
      expect(circularContainers.isNotEmpty, true);
    });

    testWidgets('handles empty action items list', (WidgetTester tester) async {
      // Arrange
      final actionItems = <ActionItem>[];

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EnhancedActionItemsWidget(actionItems: actionItems),
          ),
        ),
      );

      // Assert
      expect(find.byType(EnhancedActionItemsWidget), findsOneWidget);
      expect(find.text(''), findsNothing); // No text should be displayed
    });
  });
}
