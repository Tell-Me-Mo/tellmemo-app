import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_master_v2/features/summaries/data/models/summary_model.dart';
import 'package:pm_master_v2/features/summaries/presentation/widgets/summary_card.dart';

void main() {
  group('SummaryCard', () {
    testWidgets('displays summary subject', (WidgetTester tester) async {
      // Arrange
      final summary = SummaryModel(
        id: '1',
        summaryType: SummaryType.meeting,
        subject: 'Project Kickoff Meeting',
        body: 'Meeting summary body',
        createdAt: DateTime.now(),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SummaryCard(summary: summary),
          ),
        ),
      );

      // Assert
      expect(find.text('Project Kickoff Meeting'), findsOneWidget);
    });

    testWidgets('displays meeting type badge', (WidgetTester tester) async {
      // Arrange
      final summary = SummaryModel(
        id: '1',
        summaryType: SummaryType.meeting,
        subject: 'Team Meeting',
        body: 'Body',
        createdAt: DateTime.now(),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SummaryCard(summary: summary),
          ),
        ),
      );

      // Assert
      expect(find.text('Meeting Summary'), findsOneWidget);
      expect(find.byIcon(Icons.meeting_room), findsOneWidget);
    });

    testWidgets('displays project type badge', (WidgetTester tester) async {
      // Arrange
      final summary = SummaryModel(
        id: '1',
        summaryType: SummaryType.project,
        subject: 'Weekly Project Update',
        body: 'Body',
        createdAt: DateTime.now(),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SummaryCard(summary: summary),
          ),
        ),
      );

      // Assert
      expect(find.text('Project Summary'), findsOneWidget);
      expect(find.byIcon(Icons.calendar_view_week), findsOneWidget);
    });

    testWidgets('displays program type badge', (WidgetTester tester) async {
      // Arrange
      final summary = SummaryModel(
        id: '1',
        summaryType: SummaryType.program,
        subject: 'Program Review',
        body: 'Body',
        createdAt: DateTime.now(),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SummaryCard(summary: summary),
          ),
        ),
      );

      // Assert
      expect(find.text('Program Summary'), findsOneWidget);
      expect(find.byIcon(Icons.folder), findsOneWidget);
    });

    testWidgets('displays portfolio type badge', (WidgetTester tester) async {
      // Arrange
      final summary = SummaryModel(
        id: '1',
        summaryType: SummaryType.portfolio,
        subject: 'Q4 Portfolio Review',
        body: 'Body',
        createdAt: DateTime.now(),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SummaryCard(summary: summary),
          ),
        ),
      );

      // Assert
      expect(find.text('Portfolio Summary'), findsOneWidget);
      expect(find.text('Q4 Portfolio Review'), findsOneWidget);
      expect(find.byIcon(Icons.business_center), findsOneWidget);
    });

    testWidgets('displays executive format badge', (WidgetTester tester) async {
      // Arrange
      final summary = SummaryModel(
        id: '1',
        summaryType: SummaryType.meeting,
        subject: 'Executive Meeting',
        body: 'Body',
        createdAt: DateTime.now(),
        format: 'executive',
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SummaryCard(summary: summary),
          ),
        ),
      );

      // Assert
      expect(find.text('Executive'), findsOneWidget);
      expect(find.byIcon(Icons.business_center), findsAtLeastNWidgets(1));
    });

    testWidgets('displays technical format badge', (WidgetTester tester) async {
      // Arrange
      final summary = SummaryModel(
        id: '1',
        summaryType: SummaryType.meeting,
        subject: 'Technical Review',
        body: 'Body',
        createdAt: DateTime.now(),
        format: 'technical',
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SummaryCard(summary: summary),
          ),
        ),
      );

      // Assert
      expect(find.text('Technical'), findsOneWidget);
      expect(find.byIcon(Icons.code), findsOneWidget);
    });

    testWidgets('displays stakeholder format badge', (WidgetTester tester) async {
      // Arrange
      final summary = SummaryModel(
        id: '1',
        summaryType: SummaryType.meeting,
        subject: 'Stakeholder Update',
        body: 'Body',
        createdAt: DateTime.now(),
        format: 'stakeholder',
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SummaryCard(summary: summary),
          ),
        ),
      );

      // Assert
      expect(find.text('Stakeholder'), findsOneWidget);
      expect(find.byIcon(Icons.groups), findsOneWidget);
    });

    testWidgets('displays key points section', (WidgetTester tester) async {
      // Arrange
      final summary = SummaryModel(
        id: '1',
        summaryType: SummaryType.meeting,
        subject: 'Meeting',
        body: 'Body',
        createdAt: DateTime.now(),
        keyPoints: ['Point 1', 'Point 2', 'Point 3'],
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SummaryCard(summary: summary),
          ),
        ),
      );

      // Assert
      expect(find.text('Key Points'), findsOneWidget);
      // Should only show first 2 points (maxItems: 2 in the code)
      expect(find.text('Point 1'), findsOneWidget);
      expect(find.text('Point 2'), findsOneWidget);
    });

    testWidgets('displays decisions section', (WidgetTester tester) async {
      // Arrange
      final summary = SummaryModel(
        id: '1',
        summaryType: SummaryType.meeting,
        subject: 'Meeting',
        body: 'Body',
        createdAt: DateTime.now(),
        decisions: [
          const Decision(description: 'Approved new feature'),
          const Decision(description: 'Postponed release'),
        ],
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SummaryCard(summary: summary),
          ),
        ),
      );

      // Assert
      expect(find.text('Decisions'), findsOneWidget);
      expect(find.text('Approved new feature'), findsOneWidget);
    });

    testWidgets('displays action items section', (WidgetTester tester) async {
      // Arrange
      final summary = SummaryModel(
        id: '1',
        summaryType: SummaryType.meeting,
        subject: 'Meeting',
        body: 'Body',
        createdAt: DateTime.now(),
        actionItems: [
          const ActionItem(description: 'Complete documentation'),
          const ActionItem(description: 'Review pull request'),
        ],
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SummaryCard(summary: summary),
          ),
        ),
      );

      // Assert
      expect(find.text('Action Items'), findsOneWidget);
      expect(find.text('Complete documentation'), findsOneWidget);
    });

    testWidgets('displays token count when available', (WidgetTester tester) async {
      // Arrange
      final summary = SummaryModel(
        id: '1',
        summaryType: SummaryType.meeting,
        subject: 'Meeting',
        body: 'Body',
        createdAt: DateTime.now(),
        tokenCount: 1500,
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SummaryCard(summary: summary),
          ),
        ),
      );

      // Assert
      expect(find.text('1500 tokens'), findsOneWidget);
      expect(find.byIcon(Icons.token), findsOneWidget);
    });

    testWidgets('displays LLM cost when available', (WidgetTester tester) async {
      // Arrange
      final summary = SummaryModel(
        id: '1',
        summaryType: SummaryType.meeting,
        subject: 'Meeting',
        body: 'Body',
        createdAt: DateTime.now(),
        llmCost: 0.0025,
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SummaryCard(summary: summary),
          ),
        ),
      );

      // Assert
      expect(find.text('\$0.0025'), findsOneWidget);
      expect(find.byIcon(Icons.attach_money), findsOneWidget);
    });

    testWidgets('displays generation time when available', (WidgetTester tester) async {
      // Arrange
      final summary = SummaryModel(
        id: '1',
        summaryType: SummaryType.meeting,
        subject: 'Meeting',
        body: 'Body',
        createdAt: DateTime.now(),
        generationTimeMs: 3500,
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SummaryCard(summary: summary),
          ),
        ),
      );

      // Assert
      expect(find.text('3.5s'), findsOneWidget);
      expect(find.byIcon(Icons.timer_outlined), findsOneWidget);
    });

    testWidgets('displays export option in popup menu', (WidgetTester tester) async {
      // Arrange
      final summary = SummaryModel(
        id: '1',
        summaryType: SummaryType.meeting,
        subject: 'Meeting',
        body: 'Body',
        createdAt: DateTime.now(),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SummaryCard(summary: summary),
          ),
        ),
      );

      // Open popup menu
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Export as PDF'), findsOneWidget);
      expect(find.byIcon(Icons.download), findsOneWidget);
    });

    testWidgets('calls onExport when export is selected', (WidgetTester tester) async {
      // Arrange
      var exportCalled = false;
      final summary = SummaryModel(
        id: '1',
        summaryType: SummaryType.meeting,
        subject: 'Meeting',
        body: 'Body',
        createdAt: DateTime.now(),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SummaryCard(
              summary: summary,
              onExport: () => exportCalled = true,
            ),
          ),
        ),
      );

      // Open popup menu and tap export
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Export as PDF'));
      await tester.pumpAndSettle();

      // Assert
      expect(exportCalled, true);
    });

    testWidgets('displays View Details button', (WidgetTester tester) async {
      // Arrange
      final summary = SummaryModel(
        id: '1',
        summaryType: SummaryType.meeting,
        subject: 'Meeting',
        body: 'Body',
        createdAt: DateTime.now(),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SummaryCard(summary: summary),
          ),
        ),
      );

      // Assert
      expect(find.text('View Details'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
    });

    testWidgets('calls onTap when card is tapped', (WidgetTester tester) async {
      // Arrange
      var tapped = false;
      final summary = SummaryModel(
        id: '1',
        summaryType: SummaryType.meeting,
        subject: 'Meeting',
        body: 'Body',
        createdAt: DateTime.now(),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SummaryCard(
              summary: summary,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      // Tap the card
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      // Assert
      expect(tapped, true);
    });

    testWidgets('displays date range for project summaries', (WidgetTester tester) async {
      // Arrange
      final startDate = DateTime(2024, 1, 1);
      final endDate = DateTime(2024, 1, 31);
      final summary = SummaryModel(
        id: '1',
        summaryType: SummaryType.project,
        subject: 'Project Weekly Summary',
        body: 'Body',
        createdAt: DateTime.now(),
        dateRangeStart: startDate,
        dateRangeEnd: endDate,
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SummaryCard(summary: summary),
          ),
        ),
      );

      // Assert - Check date range is displayed
      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
      expect(find.textContaining('Jan 01, 2024'), findsOneWidget);
      expect(find.textContaining('Jan 31, 2024'), findsOneWidget);
    });

    testWidgets('displays single date for meeting summaries', (WidgetTester tester) async {
      // Arrange
      final createdDate = DateTime(2024, 2, 15);
      final summary = SummaryModel(
        id: '1',
        summaryType: SummaryType.meeting,
        subject: 'Team Meeting',
        body: 'Body',
        createdAt: createdDate,
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SummaryCard(summary: summary),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
      expect(find.textContaining('Feb 15, 2024'), findsOneWidget);
    });

    testWidgets('displays next meeting agenda section for meeting summaries', (WidgetTester tester) async {
      // Arrange
      final summary = SummaryModel(
        id: '1',
        summaryType: SummaryType.meeting,
        subject: 'Team Meeting',
        body: 'Body',
        createdAt: DateTime.now(),
        nextMeetingAgenda: [
          const AgendaItem(title: 'Review sprint goals', description: ''),
          const AgendaItem(title: 'Discuss blockers', description: ''),
          const AgendaItem(title: 'Plan next iteration', description: ''),
        ],
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SummaryCard(summary: summary),
          ),
        ),
      );

      // Assert
      expect(find.text('Next Meeting Agenda'), findsOneWidget);
      expect(find.text('Review sprint goals'), findsOneWidget);
      expect(find.text('Discuss blockers'), findsOneWidget);
    });

    testWidgets('does not display next meeting agenda for non-meeting summaries', (WidgetTester tester) async {
      // Arrange
      final summary = SummaryModel(
        id: '1',
        summaryType: SummaryType.project,
        subject: 'Project Summary',
        body: 'Body',
        createdAt: DateTime.now(),
        nextMeetingAgenda: [
          const AgendaItem(title: 'Review goals', description: ''),
        ],
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SummaryCard(summary: summary),
          ),
        ),
      );

      // Assert
      expect(find.text('Next Meeting Agenda'), findsNothing);
    });
  });
}
