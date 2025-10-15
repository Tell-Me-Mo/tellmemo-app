import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_master_v2/features/projects/presentation/widgets/blocker_detail_panel.dart';
import 'package:pm_master_v2/features/projects/domain/entities/blocker.dart';
import 'package:pm_master_v2/features/projects/domain/entities/project.dart';
import '../../../../helpers/test_helpers.dart';
import '../../../../mocks/mock_providers.dart';

void main() {
  late Project testProject;
  late Blocker testBlocker;

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

    testBlocker = Blocker(
      id: 'blocker-1',
      projectId: 'project-1',
      title: 'Test Blocker',
      description: 'Test blocker description',
      impact: BlockerImpact.high,
      status: BlockerStatus.active,
      identifiedDate: DateTime(2024, 1, 1),
      lastUpdated: DateTime(2024, 1, 1),
      updatedBy: 'test@example.com',
    );
  });

  group('BlockerDetailPanel - Creation', () {
    testWidgets('displays create mode with required fields', (tester) async {
      await pumpWidgetWithProviders(
        tester,
        const Scaffold(
          body: BlockerDetailPanel(
            projectId: 'project-1',
            projectName: 'Test Project',
            initiallyInEditMode: true,
          ),
        ),
        overrides: [
          createItemUpdatesRepositoryOverride(updates: []),
        ],
        screenSize: const Size(1200, 800),
      );

      // Check header
      expect(find.text('Create New Blocker'), findsOneWidget);

      // Check form fields
      expect(find.text('Title *'), findsOneWidget);
      expect(find.text('Description'), findsOneWidget);
      expect(find.text('Status'), findsOneWidget);
      expect(find.text('Impact'), findsOneWidget);
      expect(find.text('Assigned To'), findsOneWidget);
      expect(find.text('Category'), findsOneWidget);
      expect(find.text('Target Date'), findsOneWidget);
    });

    testWidgets('validates required title field', (tester) async {
      await pumpWidgetWithProviders(
        tester,
        const Scaffold(
          body: BlockerDetailPanel(
            projectId: 'project-1',
            projectName: 'Test Project',
            initiallyInEditMode: true,
          ),
        ),
        overrides: [
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

    testWidgets('shows default impact and status', (tester) async {
      await pumpWidgetWithProviders(
        tester,
        const Scaffold(
          body: BlockerDetailPanel(
            projectId: 'project-1',
            projectName: 'Test Project',
            initiallyInEditMode: true,
          ),
        ),
        overrides: [
          createItemUpdatesRepositoryOverride(updates: []),
        ],
        screenSize: const Size(1200, 800),
      );

      // Status should default to "active"
      expect(find.text('active'), findsOneWidget);
      // Impact should default to "high"
      expect(find.text('high'), findsOneWidget);
    });
  });

  group('BlockerDetailPanel - Viewing', () {
    testWidgets('displays existing blocker in view mode', (tester) async {
      await pumpWidgetWithProviders(
        tester,
        Scaffold(
          body: BlockerDetailPanel(
            projectId: 'project-1',
            projectName: 'Test Project',
            blocker: testBlocker,
            project: testProject,
          ),
        ),
        overrides: [
          createItemUpdatesRepositoryOverride(updates: []),
        ],
        screenSize: const Size(1200, 800),
      );

      // Check header shows view mode
      expect(find.text('Blocker Details'), findsOneWidget);

      // Check blocker data is displayed
      expect(find.text('Test Blocker'), findsOneWidget);
      expect(find.text('Test blocker description'), findsOneWidget);
    });

    testWidgets('can enter edit mode', (tester) async {
      await pumpWidgetWithProviders(
        tester,
        Scaffold(
          body: BlockerDetailPanel(
            projectId: 'project-1',
            projectName: 'Test Project',
            blocker: testBlocker,
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

      // Should show edit mode
      expect(find.text('Edit Blocker'), findsOneWidget);
    });

    testWidgets('cancel edit returns to view mode', (tester) async {
      await pumpWidgetWithProviders(
        tester,
        Scaffold(
          body: BlockerDetailPanel(
            projectId: 'project-1',
            projectName: 'Test Project',
            blocker: testBlocker,
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

      // Should return to view mode
      expect(find.text('Blocker Details'), findsOneWidget);
    });
  });
}
