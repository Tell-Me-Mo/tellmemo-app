import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_master_v2/features/projects/domain/entities/risk.dart';
import 'package:pm_master_v2/features/projects/domain/entities/project.dart';
import 'package:pm_master_v2/features/risks/presentation/providers/aggregated_risks_provider.dart';
import 'package:pm_master_v2/features/risks/presentation/widgets/risk_kanban_card.dart';
import '../../../../helpers/test_helpers.dart';

void main() {
  late AggregatedRisk testAggregatedRisk;
  late Project testProject;
  late Risk testRisk;

  setUp(() {
    testProject = Project(
      id: 'project-1',
      name: 'Mobile App Redesign',
      description: 'Test Description',
      createdAt: DateTime(2020, 1, 1),
      updatedAt: DateTime(2020, 1, 1),
      status: ProjectStatus.active,
    );

    testRisk = Risk(
      id: 'risk-1',
      projectId: 'project-1',
      title: 'API Rate Limiting Issue',
      description: 'Third-party API may throttle requests during peak hours',
      severity: RiskSeverity.high,
      status: RiskStatus.identified,
      identifiedDate: DateTime.now().subtract(const Duration(days: 3)),
    );

    testAggregatedRisk = AggregatedRisk(
      risk: testRisk,
      project: testProject,
    );
  });

  Future<void> pumpTestWidget(
    WidgetTester tester,
    AggregatedRisk aggregatedRisk, {
    bool isDragging = false,
  }) async {
    await pumpWidgetWithProviders(
      tester,
      Scaffold(
        body: RiskKanbanCard(
          aggregatedRisk: aggregatedRisk,
          isDragging: isDragging,
        ),
      ),
    );
  }

  group('RiskKanbanCard', () {
    testWidgets('displays risk title', (tester) async {
      await pumpTestWidget(tester, testAggregatedRisk);

      expect(find.text('API Rate Limiting Issue'), findsOneWidget);
    });

    testWidgets('displays risk description when present', (tester) async {
      await pumpTestWidget(tester, testAggregatedRisk);

      expect(
        find.text('Third-party API may throttle requests during peak hours'),
        findsOneWidget,
      );
    });

    testWidgets('hides description when empty', (tester) async {
      final riskWithoutDesc = testRisk.copyWith(description: '');
      final aggregatedRisk = AggregatedRisk(risk: riskWithoutDesc, project: testProject);

      await pumpTestWidget(tester, aggregatedRisk);

      expect(find.text('Third-party API may throttle requests during peak hours'), findsNothing);
    });

    testWidgets('displays severity badge with correct color - Critical', (tester) async {
      final criticalRisk = testRisk.copyWith(severity: RiskSeverity.critical);
      final aggregatedRisk = AggregatedRisk(risk: criticalRisk, project: testProject);

      await pumpTestWidget(tester, aggregatedRisk);

      // Verify flag icon is present for severity badge
      expect(find.byIcon(Icons.flag), findsAtLeastNWidgets(1));

      // Verify critical severity color (red) is applied to the flag icon
      final flagIcon = tester.widget<Icon>(find.byIcon(Icons.flag).first);
      expect(flagIcon.color, Colors.red);
    });

    testWidgets('displays severity badge with correct color - High', (tester) async {
      await pumpTestWidget(tester, testAggregatedRisk);

      // Verify flag icon is present for severity badge
      expect(find.byIcon(Icons.flag), findsAtLeastNWidgets(1));

      // Verify high severity color (red.shade400) is applied to the flag icon
      final flagIcon = tester.widget<Icon>(find.byIcon(Icons.flag).first);
      expect(flagIcon.color, Colors.red.shade400);
    });

    testWidgets('displays severity badge with correct color - Medium', (tester) async {
      final mediumRisk = testRisk.copyWith(severity: RiskSeverity.medium);
      final aggregatedRisk = AggregatedRisk(risk: mediumRisk, project: testProject);

      await pumpTestWidget(tester, aggregatedRisk);

      // Verify flag icon is present for severity badge
      expect(find.byIcon(Icons.flag), findsAtLeastNWidgets(1));

      // Verify medium severity color (orange) is applied to the flag icon
      final flagIcon = tester.widget<Icon>(find.byIcon(Icons.flag).first);
      expect(flagIcon.color, Colors.orange);
    });

    testWidgets('displays severity badge with correct color - Low', (tester) async {
      final lowRisk = testRisk.copyWith(severity: RiskSeverity.low);
      final aggregatedRisk = AggregatedRisk(risk: lowRisk, project: testProject);

      await pumpTestWidget(tester, aggregatedRisk);

      // Verify flag icon is present for severity badge
      expect(find.byIcon(Icons.flag), findsAtLeastNWidgets(1));

      // Verify low severity color (green) is applied to the flag icon
      final flagIcon = tester.widget<Icon>(find.byIcon(Icons.flag).first);
      expect(flagIcon.color, Colors.green);
    });

    testWidgets('displays severity badge with flag icon', (tester) async {
      await pumpTestWidget(tester, testAggregatedRisk);

      // Find flag icons (there are two in the severity badge)
      final flagIcons = find.byIcon(Icons.flag);
      expect(flagIcons, findsAtLeastNWidgets(1));
    });

    testWidgets('displays project name with folder icon', (tester) async {
      await pumpTestWidget(tester, testAggregatedRisk);

      expect(find.text('Mobile App Redesign'), findsOneWidget);
      expect(find.byIcon(Icons.folder_outlined), findsOneWidget);
    });

    testWidgets('displays assignee when assigned', (tester) async {
      final assignedRisk = testRisk.copyWith(assignedTo: 'Jane Smith');
      final aggregatedRisk = AggregatedRisk(risk: assignedRisk, project: testProject);

      await pumpTestWidget(tester, aggregatedRisk);

      expect(find.text('Jane Smith'), findsOneWidget);
      expect(find.byIcon(Icons.person_outline), findsOneWidget);
    });

    testWidgets('hides assignee when not assigned', (tester) async {
      await pumpTestWidget(tester, testAggregatedRisk);

      expect(find.byIcon(Icons.person_outline), findsNothing);
    });

    testWidgets('displays AI-generated badge when applicable', (tester) async {
      final aiRisk = testRisk.copyWith(aiGenerated: true);
      final aggregatedRisk = AggregatedRisk(risk: aiRisk, project: testProject);

      await pumpTestWidget(tester, aggregatedRisk);

      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
    });

    testWidgets('hides AI-generated badge when not AI-generated', (tester) async {
      await pumpTestWidget(tester, testAggregatedRisk);

      expect(find.byIcon(Icons.auto_awesome), findsNothing);
    });

    testWidgets('displays formatted date - days ago', (tester) async {
      await pumpTestWidget(tester, testAggregatedRisk);

      expect(find.text('3d ago'), findsOneWidget);
    });

    testWidgets('displays formatted date - today', (tester) async {
      final todayRisk = testRisk.copyWith(identifiedDate: DateTime.now());
      final aggregatedRisk = AggregatedRisk(risk: todayRisk, project: testProject);

      await pumpTestWidget(tester, aggregatedRisk);

      expect(find.text('Today'), findsOneWidget);
    });

    testWidgets('displays formatted date - months ago', (tester) async {
      final oldRisk = testRisk.copyWith(
        identifiedDate: DateTime.now().subtract(const Duration(days: 90)),
      );
      final aggregatedRisk = AggregatedRisk(risk: oldRisk, project: testProject);

      await pumpTestWidget(tester, aggregatedRisk);

      expect(find.text('3mo ago'), findsOneWidget);
    });

    testWidgets('hides date when identifiedDate is null', (tester) async {
      final riskWithoutDate = Risk(
        id: 'risk-1',
        projectId: 'project-1',
        title: 'API Rate Limiting Issue',
        description: 'Third-party API may throttle requests during peak hours',
        severity: RiskSeverity.high,
        status: RiskStatus.identified,
        identifiedDate: null,
      );
      final aggregatedRisk = AggregatedRisk(risk: riskWithoutDate, project: testProject);

      await pumpTestWidget(tester, aggregatedRisk);

      // Should not display any date
      expect(find.textContaining('ago'), findsNothing);
      expect(find.text('Today'), findsNothing);
    });

    testWidgets('applies elevated styling when dragging', (tester) async {
      await pumpTestWidget(tester, testAggregatedRisk, isDragging: true);

      final card = tester.widget<Card>(find.byType(Card));
      expect(card.elevation, 8);
    });

    testWidgets('applies normal styling when not dragging', (tester) async {
      await pumpTestWidget(tester, testAggregatedRisk, isDragging: false);

      final card = tester.widget<Card>(find.byType(Card));
      expect(card.elevation, 1);
    });

    testWidgets('displays all metadata: assignee, AI badge, and date', (tester) async {
      final fullRisk = testRisk.copyWith(
        assignedTo: 'John Doe',
        aiGenerated: true,
        identifiedDate: DateTime.now().subtract(const Duration(days: 5)),
      );
      final aggregatedRisk = AggregatedRisk(risk: fullRisk, project: testProject);

      await pumpTestWidget(tester, aggregatedRisk);

      expect(find.text('John Doe'), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
      expect(find.text('5d ago'), findsOneWidget);
    });
  });
}

