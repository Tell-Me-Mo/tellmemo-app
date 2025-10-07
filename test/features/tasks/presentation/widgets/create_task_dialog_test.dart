import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pm_master_v2/features/tasks/presentation/widgets/create_task_dialog.dart';
import 'package:pm_master_v2/features/projects/domain/entities/task.dart';
import 'package:pm_master_v2/features/projects/domain/entities/project.dart';
import '../../../../helpers/test_helpers.dart';
import '../../../../mocks/mock_providers.dart';
import '../../../../mocks/mock_tasks_providers.dart';

void main() {
  late List<Project> testProjects;

  setUp(() {
    testProjects = [
      Project(
        id: 'project-1',
        name: 'Test Project 1',
        description: 'First project',
        status: ProjectStatus.active,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        createdBy: 'test@example.com',
      ),
      Project(
        id: 'project-2',
        name: 'Test Project 2',
        description: 'Second project',
        status: ProjectStatus.active,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        createdBy: 'test@example.com',
      ),
    ];
  });

  Future<void> pumpTestWidget(
    WidgetTester tester, {
    String? initialProjectId,
    Future<Task> Function(String, Task)? onCreateTask,
    VoidCallback? onRefresh,
  }) async {
    final overrides = [
      createProjectsListOverride(projects: testProjects),
      createRisksTasksRepositoryOverride(onCreateTask: onCreateTask),
      createForceRefreshTasksOverride(onRefresh: onRefresh),
    ];

    await pumpWidgetWithProviders(
      tester,
      Builder(
        builder: (context) {
          return Scaffold(
            body: ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => CreateTaskDialog(initialProjectId: initialProjectId),
                );
              },
              child: const Text('Show Dialog'),
            ),
          );
        },
      ),
      overrides: overrides,
    );
  }

  group('CreateTaskDialog', () {
    testWidgets('displays dialog header and close button', (tester) async {
      await pumpTestWidget(tester);
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Check header elements
      expect(find.text('Create New Task'), findsOneWidget);
      expect(find.byIcon(Icons.add_task), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('displays all required form fields', (tester) async {
      await pumpTestWidget(tester);
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Check form fields
      expect(find.text('Project *'), findsOneWidget);
      expect(find.text('Title *'), findsOneWidget);
      expect(find.text('Description'), findsOneWidget);
      expect(find.text('Status'), findsOneWidget);
      expect(find.text('Priority'), findsOneWidget);
      expect(find.text('Assignee'), findsOneWidget);
      expect(find.text('Due Date'), findsOneWidget);
    });

    testWidgets('loads and displays projects in dropdown', (tester) async {
      await pumpTestWidget(tester);
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Open project dropdown
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      // Check projects are listed
      expect(find.text('Test Project 1').hitTestable(), findsOneWidget);
      expect(find.text('Test Project 2').hitTestable(), findsOneWidget);
    });

    testWidgets('pre-selects project when initialProjectId is provided', (tester) async {
      await pumpTestWidget(tester, initialProjectId: 'project-1');
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Check that project is pre-selected
      expect(find.text('Test Project 1'), findsOneWidget);
    });

    testWidgets('validates required project selection', (tester) async {
      await pumpTestWidget(tester);
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Try to submit without selecting a project
      await tester.tap(find.text('Create Task'));
      await tester.pumpAndSettle();

      // Should show snackbar error
      expect(find.text('Please select a project'), findsOneWidget);
    });

    testWidgets('validates required title field', (tester) async {
      await pumpTestWidget(tester, initialProjectId: 'project-1');
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Try to submit without title
      await tester.tap(find.text('Create Task'));
      await tester.pumpAndSettle();

      // Should show validation error
      expect(find.text('Please enter a task title'), findsOneWidget);
    });

    testWidgets('displays status dropdown with default value "To Do"', (tester) async {
      await pumpTestWidget(tester);
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Check default status
      expect(find.text('To Do'), findsOneWidget);
    });

    testWidgets('displays priority dropdown with default value "Medium"', (tester) async {
      await pumpTestWidget(tester);
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Check default priority
      expect(find.text('Medium'), findsOneWidget);
    });

    testWidgets('allows changing status', (tester) async {
      await pumpTestWidget(tester, initialProjectId: 'project-1');
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Open status dropdown
      await tester.tap(find.byType(DropdownButtonFormField<TaskStatus>));
      await tester.pumpAndSettle();

      // Select In Progress
      await tester.tap(find.text('In Progress').last);
      await tester.pumpAndSettle();

      // Verify selection
      expect(find.text('In Progress'), findsOneWidget);
    });

    testWidgets('allows changing priority', (tester) async {
      await pumpTestWidget(tester, initialProjectId: 'project-1');
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Open priority dropdown
      await tester.tap(find.byType(DropdownButtonFormField<TaskPriority>));
      await tester.pumpAndSettle();

      // Select Urgent
      await tester.tap(find.text('Urgent').last);
      await tester.pumpAndSettle();

      // Verify selection
      expect(find.text('Urgent'), findsOneWidget);
    });

    testWidgets('successfully creates task with valid data', (tester) async {
      Task? capturedTask;
      String? capturedProjectId;
      bool refreshCalled = false;

      await pumpTestWidget(
        tester,
        initialProjectId: 'project-1',
        onCreateTask: (projectId, task) async {
          capturedProjectId = projectId;
          capturedTask = task;
          return task;
        },
        onRefresh: () => refreshCalled = true,
      );
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Fill in title (find by the first TextFormField after the project dropdown)
      final titleField = find.byType(TextFormField).at(0);
      await tester.enterText(titleField, 'Test Task');

      // Fill in description
      final descField = find.byType(TextFormField).at(1);
      await tester.enterText(descField, 'Test description');

      // Fill in assignee
      final assigneeField = find.byType(TextFormField).at(2);
      await tester.enterText(assigneeField, 'John Doe');

      // Submit
      await tester.tap(find.text('Create Task'));
      await tester.pumpAndSettle();

      // Verify task was created
      expect(capturedProjectId, 'project-1');
      expect(capturedTask?.title, 'Test Task');
      expect(capturedTask?.description, 'Test description');
      expect(capturedTask?.assignee, 'John Doe');
      expect(capturedTask?.status, TaskStatus.todo);
      expect(capturedTask?.priority, TaskPriority.medium);
      expect(capturedTask?.aiGenerated, false);

      // Verify refresh was called
      expect(refreshCalled, true);

      // Dialog should be closed
      expect(find.byType(CreateTaskDialog), findsNothing);

      // Success snackbar should be shown
      expect(find.text('Task created successfully'), findsOneWidget);
    });

    testWidgets('creates task with selected status and priority', (tester) async {
      Task? capturedTask;

      await pumpTestWidget(
        tester,
        initialProjectId: 'project-1',
        onCreateTask: (projectId, task) async {
          capturedTask = task;
          return task;
        },
      );
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Enter title
      final titleField = find.byType(TextFormField).at(0);
      await tester.enterText(titleField, 'Urgent Task');

      // Change status to In Progress
      await tester.tap(find.byType(DropdownButtonFormField<TaskStatus>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('In Progress').last);
      await tester.pumpAndSettle();

      // Change priority to Urgent
      await tester.tap(find.byType(DropdownButtonFormField<TaskPriority>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Urgent').last);
      await tester.pumpAndSettle();

      // Submit
      await tester.tap(find.text('Create Task'));
      await tester.pumpAndSettle();

      // Verify status and priority
      expect(capturedTask?.status, TaskStatus.inProgress);
      expect(capturedTask?.priority, TaskPriority.urgent);
    });

    testWidgets('handles error during task creation', (tester) async {
      await pumpTestWidget(
        tester,
        initialProjectId: 'project-1',
        onCreateTask: (projectId, task) async {
          throw Exception('Network error');
        },
      );
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Enter title
      final titleField = find.byType(TextFormField).at(0);
      await tester.enterText(titleField, 'Test Task');

      // Submit
      await tester.tap(find.text('Create Task'));
      await tester.pumpAndSettle();

      // Should show error snackbar
      expect(find.textContaining('Error creating task'), findsOneWidget);

      // Dialog should still be open
      expect(find.byType(CreateTaskDialog), findsOneWidget);
    });

    testWidgets('cancel button closes dialog', (tester) async {
      await pumpTestWidget(tester);
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Tap cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Dialog should be closed
      expect(find.byType(CreateTaskDialog), findsNothing);
    });

    testWidgets('close button in header closes dialog', (tester) async {
      await pumpTestWidget(tester);
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Tap close button
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Dialog should be closed
      expect(find.byType(CreateTaskDialog), findsNothing);
    });

    testWidgets('description field is optional', (tester) async {
      Task? capturedTask;

      await pumpTestWidget(
        tester,
        initialProjectId: 'project-1',
        onCreateTask: (projectId, task) async {
          capturedTask = task;
          return task;
        },
      );
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Enter only title
      final titleField = find.byType(TextFormField).at(0);
      await tester.enterText(titleField, 'Task without description');

      // Submit
      await tester.tap(find.text('Create Task'));
      await tester.pumpAndSettle();

      // Verify description is null
      expect(capturedTask?.description, isNull);
    });

    testWidgets('assignee field is optional', (tester) async {
      Task? capturedTask;

      await pumpTestWidget(
        tester,
        initialProjectId: 'project-1',
        onCreateTask: (projectId, task) async {
          capturedTask = task;
          return task;
        },
      );
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Enter only title
      final titleField = find.byType(TextFormField).at(0);
      await tester.enterText(titleField, 'Unassigned task');

      // Submit
      await tester.tap(find.text('Create Task'));
      await tester.pumpAndSettle();

      // Verify assignee is null
      expect(capturedTask?.assignee, isNull);
    });

    testWidgets('shows loading state during task creation', (tester) async {
      await pumpTestWidget(
        tester,
        initialProjectId: 'project-1',
        onCreateTask: (projectId, task) async {
          // Simulate delay
          await Future.delayed(const Duration(milliseconds: 100));
          return task;
        },
      );
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Enter title
      final titleField = find.byType(TextFormField).at(0);
      await tester.enterText(titleField, 'Test Task');

      // Submit
      await tester.tap(find.text('Create Task'));
      await tester.pump(); // Don't settle, so we can see loading state

      // Should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Creating...'), findsOneWidget);

      // Buttons should be disabled
      final cancelButton = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Cancel'),
      );
      expect(cancelButton.onPressed, isNull);

      await tester.pumpAndSettle();
    });

    testWidgets('displays project loading state', (tester) async {
      final overrides = <Override>[
        createProjectsListOverride(projects: testProjects),
      ];

      await pumpWidgetWithProviders(
        tester,
        Builder(
          builder: (context) {
            return Scaffold(
              body: ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => const CreateTaskDialog(),
                  );
                },
                child: const Text('Show Dialog'),
              ),
            );
          },
        ),
        overrides: overrides,
        settle: false,
      );
      await tester.tap(find.text('Show Dialog'));
      await tester.pump();

      // Should show loading indicator for projects
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();
    });
  });
}
