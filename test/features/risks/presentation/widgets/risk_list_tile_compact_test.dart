import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pm_master_v2/features/projects/domain/entities/risk.dart';
import 'package:pm_master_v2/features/projects/domain/entities/project.dart';
import 'package:pm_master_v2/features/risks/presentation/providers/aggregated_risks_provider.dart';
import 'package:pm_master_v2/features/risks/presentation/widgets/risk_list_tile_compact.dart';
import '../../../../helpers/test_helpers.dart';

void main() {
  late AggregatedRisk testAggregatedRisk;
  late Project testProject;
  late Risk testRisk;

  setUp(() {
    testProject = Project(
      id: 'project-1',
      name: 'Test Project',
      description: 'Test Description',
      createdAt: DateTime(2020, 1, 1),
      updatedAt: DateTime(2020, 1, 1),
      status: ProjectStatus.active,
    );

    testRisk = Risk(
      id: 'risk-1',
      projectId: 'project-1',
      title: 'Critical Database Performance Issue',
      description: 'Database queries are slow',
      severity: RiskSeverity.critical,
      status: RiskStatus.identified,
      identifiedDate: DateTime.now().subtract(const Duration(days: 2)),
    );

    testAggregatedRisk = AggregatedRisk(
      risk: testRisk,
      project: testProject,
    );
  });

  Future<void> pumpTestWidget(
    WidgetTester tester,
    AggregatedRisk aggregatedRisk, {
    bool isSelected = false,
    bool isSelectionMode = false,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    Function(String, Risk, String)? onActionSelected,
  }) async {
    await pumpWidgetWithProviders(
      tester,
      Scaffold(
        body: RiskListTileCompact(
          aggregatedRisk: aggregatedRisk,
          isSelected: isSelected,
          isSelectionMode: isSelectionMode,
          onTap: onTap,
          onLongPress: onLongPress,
          onActionSelected: onActionSelected,
        ),
      ),
    );
  }

  group('RiskListTileCompact', () {
    testWidgets('displays risk title correctly', (tester) async {
      await pumpTestWidget(tester, testAggregatedRisk);

      expect(find.text('Critical Database Performance Issue'), findsOneWidget);
    });

    testWidgets('displays project name with folder icon', (tester) async {
      await pumpTestWidget(tester, testAggregatedRisk);

      expect(find.text('Test Project'), findsOneWidget);
      expect(find.byIcon(Icons.folder_outlined), findsOneWidget);
    });

    testWidgets('displays severity indicator for critical risks', (tester) async {
      await pumpTestWidget(tester, testAggregatedRisk);

      // Should show flag icon for critical severity
      expect(find.byIcon(Icons.flag), findsOneWidget);
    });

    testWidgets('displays severity indicator for high risks', (tester) async {
      final highRisk = testRisk.copyWith(severity: RiskSeverity.high);
      final aggregatedRisk = AggregatedRisk(risk: highRisk, project: testProject);

      await pumpTestWidget(tester, aggregatedRisk);

      // Should show flag icon for high severity
      expect(find.byIcon(Icons.flag), findsOneWidget);
    });

    testWidgets('hides severity indicator for medium/low risks', (tester) async {
      final mediumRisk = testRisk.copyWith(severity: RiskSeverity.medium);
      final aggregatedRisk = AggregatedRisk(risk: mediumRisk, project: testProject);

      await pumpTestWidget(tester, aggregatedRisk);

      // Should not show flag icon for medium severity
      expect(find.byIcon(Icons.flag), findsNothing);
    });

    testWidgets('displays status badge for non-identified status', (tester) async {
      final mitigatingRisk = testRisk.copyWith(status: RiskStatus.mitigating);
      final aggregatedRisk = AggregatedRisk(risk: mitigatingRisk, project: testProject);

      await pumpTestWidget(tester, aggregatedRisk);

      expect(find.text('Mitigating'), findsOneWidget);
    });

    testWidgets('hides status badge for identified status', (tester) async {
      await pumpTestWidget(tester, testAggregatedRisk);

      // Should not show status for identified risks
      expect(find.text('Identified'), findsNothing);
    });

    testWidgets('displays assignee when assigned', (tester) async {
      final assignedRisk = testRisk.copyWith(assignedTo: 'John Doe');
      final aggregatedRisk = AggregatedRisk(risk: assignedRisk, project: testProject);

      await pumpTestWidget(tester, aggregatedRisk);

      expect(find.text('John Doe'), findsOneWidget);
      expect(find.byIcon(Icons.person_outline), findsOneWidget);
    });

    testWidgets('hides assignee when not assigned', (tester) async {
      await pumpTestWidget(tester, testAggregatedRisk);

      expect(find.byIcon(Icons.person_outline), findsNothing);
    });

    testWidgets('displays formatted date correctly - today', (tester) async {
      final todayRisk = testRisk.copyWith(identifiedDate: DateTime.now());
      final aggregatedRisk = AggregatedRisk(risk: todayRisk, project: testProject);

      await pumpTestWidget(tester, aggregatedRisk);

      expect(find.text('Today'), findsOneWidget);
    });

    testWidgets('displays formatted date correctly - days ago', (tester) async {
      await pumpTestWidget(tester, testAggregatedRisk);

      expect(find.text('2d ago'), findsOneWidget);
    });

    testWidgets('displays formatted date correctly - months ago', (tester) async {
      final oldRisk = testRisk.copyWith(
        identifiedDate: DateTime.now().subtract(const Duration(days: 60)),
      );
      final aggregatedRisk = AggregatedRisk(risk: oldRisk, project: testProject);

      await pumpTestWidget(tester, aggregatedRisk);

      expect(find.text('2mo ago'), findsOneWidget);
    });

    testWidgets('shows checkbox in selection mode', (tester) async {
      await pumpTestWidget(
        tester,
        testAggregatedRisk,
        isSelectionMode: true,
      );

      expect(find.byType(Checkbox), findsOneWidget);
    });

    testWidgets('hides checkbox when not in selection mode', (tester) async {
      await pumpTestWidget(
        tester,
        testAggregatedRisk,
        isSelectionMode: false,
      );

      expect(find.byType(Checkbox), findsNothing);
    });

    testWidgets('checkbox reflects selection state', (tester) async {
      await pumpTestWidget(
        tester,
        testAggregatedRisk,
        isSelectionMode: true,
        isSelected: true,
      );

      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, true);
    });

    testWidgets('shows popup menu when not in selection mode', (tester) async {
      await pumpTestWidget(
        tester,
        testAggregatedRisk,
        isSelectionMode: false,
        onActionSelected: (action, risk, projectId) {},
      );

      expect(find.byType(PopupMenuButton<String>), findsOneWidget);
    });

    testWidgets('hides popup menu in selection mode', (tester) async {
      await pumpTestWidget(
        tester,
        testAggregatedRisk,
        isSelectionMode: true,
        onActionSelected: (action, risk, projectId) {},
      );

      expect(find.byType(PopupMenuButton<String>), findsNothing);
    });

    testWidgets('popup menu contains edit, assign, status, and delete actions', (tester) async {
      await pumpTestWidget(
        tester,
        testAggregatedRisk,
        onActionSelected: (action, risk, projectId) {},
      );

      // Tap the more button
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Assign'), findsOneWidget);
      expect(find.text('Update Status'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('calls onActionSelected when menu item is tapped', (tester) async {
      String? capturedAction;
      Risk? capturedRisk;
      String? capturedProjectId;

      await pumpTestWidget(
        tester,
        testAggregatedRisk,
        onActionSelected: (action, risk, projectId) {
          capturedAction = action;
          capturedRisk = risk;
          capturedProjectId = projectId;
        },
      );

      // Tap the more button
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // Tap edit action
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      expect(capturedAction, 'edit');
      expect(capturedRisk, testRisk);
      expect(capturedProjectId, 'project-1');
    });

    testWidgets('calls onTap when tile is tapped', (tester) async {
      bool tapped = false;

      await pumpTestWidget(
        tester,
        testAggregatedRisk,
        onTap: () {
          tapped = true;
        },
      );

      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      expect(tapped, true);
    });

    testWidgets('calls onLongPress when tile is long pressed', (tester) async {
      bool longPressed = false;

      await pumpTestWidget(
        tester,
        testAggregatedRisk,
        onLongPress: () {
          longPressed = true;
        },
      );

      await tester.longPress(find.byType(InkWell));
      await tester.pumpAndSettle();

      expect(longPressed, true);
    });

    testWidgets('applies selected styling when selected', (tester) async {
      await pumpTestWidget(
        tester,
        testAggregatedRisk,
        isSelected: true,
      );

      final card = tester.widget<Card>(find.byType(Card));
      final shape = card.shape as RoundedRectangleBorder;

      // Check that border width is 2 for selected items
      expect(shape.side.width, 2);
    });

    testWidgets('applies normal styling when not selected', (tester) async {
      await pumpTestWidget(
        tester,
        testAggregatedRisk,
        isSelected: false,
      );

      final card = tester.widget<Card>(find.byType(Card));
      final shape = card.shape as RoundedRectangleBorder;

      // Check that border width is 1 for non-selected items
      expect(shape.side.width, 1);
    });
  });
}

