import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_master_v2/features/live_insights/domain/models/proactive_assistance_model.dart';
import 'package:pm_master_v2/features/live_insights/presentation/widgets/proactive_assistance_card.dart';

/// Integration tests for Phase 4: Action Item Quality Enhancement UI
void main() {
  group('ActionItemQualityCard', () {
    testWidgets('should display action item quality feedback', (WidgetTester tester) async {
      // Arrange - Create a quality assistance model
      final qualityAssistance = ActionItemQualityAssistance(
        insightId: 'test-123',
        actionItem: 'Looking into that bug',
        completenessScore: 0.35,
        issues: [
          const QualityIssue(
            field: 'owner',
            severity: 'critical',
            message: 'No owner specified. Action items need a clear owner.',
            suggestedFix: 'Add "John to..." or "Assigned to: Sarah"',
          ),
          const QualityIssue(
            field: 'deadline',
            severity: 'critical',
            message: 'No deadline specified.',
            suggestedFix: 'Add "by Friday" or "deadline: 10/25"',
          ),
        ],
        improvedVersion: 'John to investigate and fix the bug by Friday',
        timestamp: DateTime.now(),
      );

      final assistance = ProactiveAssistanceModel(
        type: ProactiveAssistanceType.incompleteActionItem,
        actionItemQuality: qualityAssistance,
      );

      // Act - Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProactiveAssistanceCard(assistance: assistance),
          ),
        ),
      );

      // Assert - Check that key elements are rendered
      expect(find.text('📝 Incomplete Action Item'), findsOneWidget);
      // Action item text appears twice: once in header (gray/italic) and once in body (amber)
      expect(find.text('Looking into that bug'), findsWidgets);
      expect(find.text('John to investigate and fix the bug by Friday'), findsOneWidget);

      // Check that completeness score is shown
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      // Check that issues are displayed (issues appear with their labels and suggested fixes)
      expect(find.textContaining('owner'), findsWidgets);
      expect(find.textContaining('deadline'), findsWidgets);
    });

    testWidgets('should show high completeness score in green', (WidgetTester tester) async {
      // Arrange - Create a nearly complete action item
      final qualityAssistance = ActionItemQualityAssistance(
        insightId: 'test-456',
        actionItem: 'John to review the PR',
        completenessScore: 0.95,
        issues: [
          const QualityIssue(
            field: 'success_criteria',
            severity: 'suggestion',
            message: 'Consider adding success criteria for clarity.',
          ),
        ],
        timestamp: DateTime.now(),
      );

      final assistance = ProactiveAssistanceModel(
        type: ProactiveAssistanceType.incompleteActionItem,
        actionItemQuality: qualityAssistance,
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProactiveAssistanceCard(assistance: assistance),
          ),
        ),
      );

      // Assert - Progress bar should be green for high scores
      final progressIndicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progressIndicator.value, 0.95);
    });

    testWidgets('should handle missing improved version gracefully', (WidgetTester tester) async {
      // Arrange - Quality assistance without improved version
      final qualityAssistance = ActionItemQualityAssistance(
        insightId: 'test-789',
        actionItem: 'Fix the bug',
        completenessScore: 0.70,
        issues: [
          const QualityIssue(
            field: 'description',
            severity: 'important',
            message: 'Description is too brief.',
          ),
        ],
        timestamp: DateTime.now(),
      );

      final assistance = ProactiveAssistanceModel(
        type: ProactiveAssistanceType.incompleteActionItem,
        actionItemQuality: qualityAssistance,
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProactiveAssistanceCard(assistance: assistance),
          ),
        ),
      );

      // Assert - Should render without improved version section
      // Action item text appears twice: once in header (gray/italic) and once in body (amber)
      expect(find.text('Fix the bug'), findsWidgets);
      expect(find.text('💡 Suggested Improvement'), findsNothing);
    });
  });

  group('QualityIssue Model', () {
    test('should create quality issue from JSON', () {
      // Arrange
      final json = {
        'field': 'owner',
        'severity': 'critical',
        'message': 'No owner specified',
        'suggested_fix': 'Add owner name',
      };

      // Act
      final issue = QualityIssue.fromJson(json);

      // Assert
      expect(issue.field, 'owner');
      expect(issue.severity, 'critical');
      expect(issue.message, 'No owner specified');
      expect(issue.suggestedFix, 'Add owner name');
    });

    test('should handle missing suggested_fix', () {
      // Arrange
      final json = {
        'field': 'deadline',
        'severity': 'critical',
        'message': 'No deadline',
      };

      // Act
      final issue = QualityIssue.fromJson(json);

      // Assert
      expect(issue.suggestedFix, isNull);
    });
  });

  group('ActionItemQualityAssistance Model', () {
    test('should create from JSON', () {
      // Arrange
      final json = {
        'insight_id': 'insight-123',
        'action_item': 'Test action item',
        'completeness_score': 0.5,
        'issues': [
          {
            'field': 'owner',
            'severity': 'critical',
            'message': 'Missing owner',
          }
        ],
        'improved_version': 'Improved action item',
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Act
      final assistance = ActionItemQualityAssistance.fromJson(json);

      // Assert
      expect(assistance.insightId, 'insight-123');
      expect(assistance.actionItem, 'Test action item');
      expect(assistance.completenessScore, 0.5);
      expect(assistance.issues.length, 1);
      expect(assistance.improvedVersion, 'Improved action item');
    });
  });
}
