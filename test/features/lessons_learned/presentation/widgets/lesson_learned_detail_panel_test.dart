import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_master_v2/features/lessons_learned/presentation/widgets/lesson_learned_detail_panel.dart';
import 'package:pm_master_v2/features/projects/domain/entities/lesson_learned.dart';
import 'package:pm_master_v2/features/projects/domain/entities/project.dart';
import '../../../../helpers/test_helpers.dart';
import '../../../../mocks/mock_providers.dart';

void main() {
  late LessonLearned testLesson;
  late Project testProject;

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

    testLesson = LessonLearned(
      id: 'lesson-1',
      projectId: 'project-1',
      title: 'Test Lesson',
      description: 'Test lesson description',
      category: LessonCategory.process,
      lessonType: LessonType.success,
      impact: LessonImpact.high,
      tags: [],
      identifiedDate: DateTime(2024, 1, 1),
      lastUpdated: DateTime(2024, 1, 1),
    );
  });

  group('LessonLearnedDetailPanel - Creation', () {
    testWidgets('displays create mode with required fields', (tester) async {
      await pumpWidgetWithProviders(
        tester,
        const Scaffold(
          body: LessonLearnedDetailPanel(
            projectId: 'project-1',
            projectName: 'Test Project',
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
      expect(find.text('Create New Lesson'), findsOneWidget);

      // Check form fields exist
      expect(find.text('Title *'), findsOneWidget);
      expect(find.text('Description *'), findsOneWidget);
      expect(find.text('Category'), findsOneWidget);
      expect(find.text('Impact'), findsOneWidget);
    });

    testWidgets('validates required title field', (tester) async {
      await pumpWidgetWithProviders(
        tester,
        const Scaffold(
          body: LessonLearnedDetailPanel(
            projectId: 'project-1',
            projectName: 'Test Project',
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
      expect(find.textContaining('Please enter a title'), findsOneWidget);
    });

    testWidgets('validates required description field', (tester) async {
      await pumpWidgetWithProviders(
        tester,
        const Scaffold(
          body: LessonLearnedDetailPanel(
            projectId: 'project-1',
            projectName: 'Test Project',
            initiallyInEditMode: true,
          ),
        ),
        overrides: [
          createProjectsListOverride(projects: [testProject]),
          createItemUpdatesRepositoryOverride(updates: []),
        ],
        screenSize: const Size(1200, 800),
      );

      // Fill in title but not description
      await tester.enterText(find.widgetWithText(TextFormField, 'Brief title of the lesson learned'), 'New Lesson');
      await tester.pump();

      // Try to submit
      final createButton = find.text('Create');
      await tester.ensureVisible(createButton);
      await tester.tap(createButton);
      await tester.pump(); // Allow validation to run

      // Should show warning
      expect(find.textContaining('Please enter a description'), findsOneWidget);
    });
  });

  group('LessonLearnedDetailPanel - Viewing', () {
    testWidgets('displays existing lesson in view mode', (tester) async {
      await pumpWidgetWithProviders(
        tester,
        Scaffold(
          body: LessonLearnedDetailPanel(
            projectId: 'project-1',
            projectName: 'Test Project',
            lesson: testLesson,
          ),
        ),
        overrides: [
          createItemUpdatesRepositoryOverride(updates: []),
        ],
        screenSize: const Size(1200, 800),
      );

      // Check header shows view mode
      expect(find.text('Lesson Learned'), findsOneWidget);

      // Check lesson data is displayed
      expect(find.text('Test Lesson'), findsOneWidget);
      expect(find.text('Test lesson description'), findsOneWidget);
    });

    testWidgets('can enter edit mode', (tester) async {
      await pumpWidgetWithProviders(
        tester,
        Scaffold(
          body: LessonLearnedDetailPanel(
            projectId: 'project-1',
            projectName: 'Test Project',
            lesson: testLesson,
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
      expect(find.text('Edit Lesson'), findsOneWidget);
    });

    testWidgets('cancel edit returns to view mode', (tester) async {
      await pumpWidgetWithProviders(
        tester,
        Scaffold(
          body: LessonLearnedDetailPanel(
            projectId: 'project-1',
            projectName: 'Test Project',
            lesson: testLesson,
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
      expect(find.text('Lesson Learned'), findsOneWidget);
    });
  });
}
