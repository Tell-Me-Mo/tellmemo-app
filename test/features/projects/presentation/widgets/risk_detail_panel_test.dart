import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_master_v2/features/projects/presentation/widgets/risk_detail_panel.dart';
import 'package:pm_master_v2/features/projects/domain/entities/risk.dart';
import 'package:pm_master_v2/features/projects/domain/entities/project.dart';
import '../../../../helpers/test_helpers.dart';
import '../../../../mocks/mock_providers.dart';

void main() {
  late Project testProject;
  late Risk testRisk;

  setUp(() {
    testProject = Project(
      id: 'project-1',
      name: 'Test Project',
      description: 'Test description',
      status: ProjectStatus.active,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
      createdBy: 'test@example.com',
    );

    testRisk = Risk(
      id: 'risk-1',
      projectId: 'project-1',
      title: 'Test Risk',
      description: 'Test risk description',
      severity: RiskSeverity.high,
      status: RiskStatus.identified,
      probability: 0.5,
      identifiedDate: DateTime(2024, 1, 1),
      lastUpdated: DateTime(2024, 1, 1),
      updatedBy: 'test@example.com',
    );
  });

  group('RiskDetailPanel - Creation', () {
    testWidgets('displays create mode with required fields', (tester) async {
      await pumpWidgetWithProviders(
        tester,
        const Scaffold(
          body: RiskDetailPanel(
            projectId: 'project-1',
            initiallyInEditMode: true,
          ),
        ),
        overrides: [
          createProjectsListOverride(projects: [testProject]),
          createItemUpdatesRepositoryOverride(updates: []),
        ],
        screenSize: const Size(1200, 800),
      );

      // Check header
      expect(find.text('Create New Risk'), findsOneWidget);

      // Check form fields exist
      expect(find.text('Risk Title *'), findsOneWidget);
      expect(find.text('Description *'), findsOneWidget);
      expect(find.text('Impact'), findsOneWidget);
      expect(find.textContaining('Probability'), findsOneWidget);
      expect(find.text('Status'), findsOneWidget);
    });

    testWidgets('validates required title field', (tester) async {
      await pumpWidgetWithProviders(
        tester,
        const Scaffold(
          body: RiskDetailPanel(
            projectId: 'project-1',
            initiallyInEditMode: true,
          ),
        ),
        overrides: [
          createProjectsListOverride(projects: [testProject]),
          createItemUpdatesRepositoryOverride(updates: []),
        ],
        screenSize: const Size(1200, 800),
      );

      // Try to submit without title
      final createButton = find.text('Create');
      await tester.ensureVisible(createButton);
      await tester.tap(createButton);
      await tester.pump(); // Allow validation to run

      // Should show warning
      expect(find.textContaining('Title is required'), findsOneWidget);
    });
  });

  group('RiskDetailPanel - Viewing', () {
    testWidgets('displays existing risk in view mode', (tester) async {
      await pumpWidgetWithProviders(
        tester,
        Scaffold(
          body: RiskDetailPanel(
            projectId: 'project-1',
            risk: testRisk,
            project: testProject,
          ),
        ),
        overrides: [
          createItemUpdatesRepositoryOverride(updates: []),
        ],
        screenSize: const Size(1200, 800),
      );

      // Check header shows risk title (not "Risk Details")
      expect(find.text('Test Risk'), findsOneWidget);

      // Check risk data is displayed
      expect(find.text('Test risk description'), findsOneWidget);
    });

    testWidgets('can enter edit mode', (tester) async {
      await pumpWidgetWithProviders(
        tester,
        Scaffold(
          body: RiskDetailPanel(
            projectId: 'project-1',
            risk: testRisk,
            project: testProject,
          ),
        ),
        overrides: [
          createItemUpdatesRepositoryOverride(updates: []),
        ],
        screenSize: const Size(1200, 800),
      );

      // Open edit menu
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300)); // Wait for menu animation

      // Tap edit
      await tester.tap(find.text('Edit'));
      await tester.pump();

      // Should show Save button in edit mode (title still shows risk name, not "Edit Risk")
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('cancel edit returns to view mode', (tester) async {
      await pumpWidgetWithProviders(
        tester,
        Scaffold(
          body: RiskDetailPanel(
            projectId: 'project-1',
            risk: testRisk,
            project: testProject,
          ),
        ),
        overrides: [
          createItemUpdatesRepositoryOverride(updates: []),
        ],
        screenSize: const Size(1200, 800),
      );

      // Enter edit mode
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300)); // Wait for menu animation
      await tester.tap(find.text('Edit'));
      await tester.pump();

      // Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pump();

      // Should return to view mode (action buttons visible instead of Save/Cancel)
      expect(find.text('Save'), findsNothing);
      expect(find.byIcon(Icons.more_vert), findsOneWidget);
    });
  });
}
