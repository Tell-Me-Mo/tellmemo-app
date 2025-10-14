import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_master_v2/features/tasks/presentation/widgets/task_detail_panel.dart';
import 'package:pm_master_v2/features/projects/domain/entities/task.dart';
import 'package:pm_master_v2/features/projects/domain/entities/project.dart';
import 'package:pm_master_v2/features/tasks/presentation/providers/aggregated_tasks_provider.dart';
import '../../../../helpers/test_helpers.dart';
import '../../../../mocks/mock_providers.dart';
import '../../../../mocks/mock_tasks_providers.dart';

void main() {
  late List<Project> testProjects;
  late Task testTask;

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

    testTask = Task(
      id: 'task-1',
      projectId: 'project-1',
      title: 'Test Task',
      description: 'Test description',
      status: TaskStatus.todo,
      priority: TaskPriority.medium,
      assignee: 'John Doe',
      progressPercentage: 0,
      createdDate: DateTime(2024, 1, 1),
      lastUpdated: DateTime(2024, 1, 1),
    );
  });

  Future<void> pumpPanelForCreation(
    WidgetTester tester, {
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
      Scaffold(
        body: TaskDetailPanel(
          projectId: 'project-1',
          projectName: 'Test Project 1',
          initiallyInEditMode: true,
        ),
      ),
      overrides: overrides,
      screenSize: const Size(1200, 800),
    );
  }

  Future<void> pumpPanelForViewing(
    WidgetTester tester,
    TaskWithProject taskWithProject, {
    Future<Task> Function(String, Task)? onUpdateTask,
    VoidCallback? onRefresh,
  }) async {
    final overrides = [
      createProjectsListOverride(projects: testProjects),
      createRisksTasksRepositoryOverride(onUpdateTask: onUpdateTask),
      createForceRefreshTasksOverride(onRefresh: onRefresh),
    ];

    await pumpWidgetWithProviders(
      tester,
      Scaffold(
        body: TaskDetailPanel(taskWithProject: taskWithProject),
      ),
      overrides: overrides,
      screenSize: const Size(1200, 800),
    );
  }

  group('TaskDetailPanel - Creation', () {
    testWidgets('displays create mode with all required fields', (tester) async {
      await pumpPanelForCreation(tester);

      // Check header
      expect(find.text('Create New Task'), findsOneWidget);

      // Check form fields
      expect(find.text('Project *'), findsOneWidget);
      expect(find.text('Title *'), findsOneWidget);
      expect(find.text('Description'), findsOneWidget);
      expect(find.text('Status'), findsOneWidget);
      expect(find.text('Priority'), findsOneWidget);
      expect(find.text('Assignee'), findsOneWidget);
      expect(find.text('Due Date'), findsOneWidget);
    });

    testWidgets('validates required title field', (tester) async {
      Task? capturedTask;
      bool refreshCalled = false;

      final overrides = [
        createProjectsListOverride(projects: testProjects),
        createRisksTasksRepositoryOverride(
          onCreateTask: (projectId, task) async {
            capturedTask = task;
            return task;
          },
        ),
        createForceRefreshTasksOverride(onRefresh: () => refreshCalled = true),
      ];

      await pumpWidgetWithProviders(
        tester,
        Scaffold(
          body: TaskDetailPanel(
            projectId: 'project-1',
            projectName: 'Test Project 1',
            initiallyInEditMode: true,
          ),
        ),
        overrides: overrides,
        screenSize: const Size(1200, 800),
      );

      // Select project
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Test Project 1').last);
      await tester.pumpAndSettle();

      // Try to submit without title (leave title empty)
      final createButton = find.text('Create');
      await tester.ensureVisible(createButton);
      await tester.tap(createButton);
      await tester.pumpAndSettle();

      // Verify task was NOT created (validation prevented it)
      expect(capturedTask, isNull);
      expect(refreshCalled, false);
    });


    testWidgets('creates task with valid data', (tester) async {
      Task? capturedTask;
      String? capturedProjectId;
      bool refreshCalled = false;

      await pumpPanelForCreation(
        tester,
        onCreateTask: (projectId, task) async {
          capturedProjectId = projectId;
          capturedTask = task;
          return task;
        },
        onRefresh: () => refreshCalled = true,
      );

      // Select project
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Test Project 1').last);
      await tester.pumpAndSettle();

      // Fill in title
      await tester.enterText(find.widgetWithText(TextField, 'Enter task title'), 'New Task');
      await tester.pumpAndSettle();

      // Submit
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      // Verify task was created
      expect(capturedProjectId, 'project-1');
      expect(capturedTask?.title, 'New Task');
      expect(capturedTask?.status, TaskStatus.todo);
      expect(capturedTask?.priority, TaskPriority.medium);
      expect(refreshCalled, true);
    });

    testWidgets('shows default status and priority', (tester) async {
      await pumpPanelForCreation(tester);

      // Status should default to "To Do" - but the dropdown shows the enum name
      expect(find.text('todo'), findsOneWidget);
      // Priority should default to "Medium"
      expect(find.text('medium'), findsOneWidget);
    });
  });

  group('TaskDetailPanel - Viewing', () {
    testWidgets('displays existing task in view mode', (tester) async {
      final taskWithProject = TaskWithProject(
        task: testTask,
        project: testProjects[0],
      );

      await pumpPanelForViewing(tester, taskWithProject);

      // Check header shows view mode
      expect(find.text('Task Details'), findsOneWidget);

      // Check task data is displayed
      expect(find.text('Test Task'), findsOneWidget);
      expect(find.text('Test description'), findsOneWidget);
      expect(find.text('John Doe'), findsOneWidget);
    });

    testWidgets('can edit existing task', (tester) async {
      Task? capturedTask;
      bool refreshCalled = false;

      final taskWithProject = TaskWithProject(
        task: testTask,
        project: testProjects[0],
      );

      await pumpPanelForViewing(
        tester,
        taskWithProject,
        onUpdateTask: (projectId, task) async {
          capturedTask = task;
          return task;
        },
        onRefresh: () => refreshCalled = true,
      );

      // Open edit menu
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // Tap edit
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      // Should show edit mode
      expect(find.text('Edit Task'), findsOneWidget);

      // Modify title
      final titleField = find.widgetWithText(TextField, 'Test Task');
      await tester.enterText(titleField, 'Updated Task Title');
      await tester.pumpAndSettle();

      // Save changes
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Verify update was called
      expect(capturedTask?.title, 'Updated Task Title');
      expect(refreshCalled, true);
    });

    testWidgets('can delete task', (tester) async {
      String? deletedTaskId;

      final taskWithProject = TaskWithProject(
        task: testTask,
        project: testProjects[0],
      );

      final overrides = [
        createProjectsListOverride(projects: testProjects),
        createRisksTasksRepositoryOverride(
          onDeleteTask: (taskId) async {
            deletedTaskId = taskId;
          },
        ),
        createForceRefreshTasksOverride(onRefresh: () {}),
      ];

      await pumpWidgetWithProviders(
        tester,
        Scaffold(
          body: TaskDetailPanel(taskWithProject: taskWithProject),
        ),
        overrides: overrides,
        screenSize: const Size(1200, 800),
      );

      // Open more menu
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // Tap delete
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Confirm deletion
      await tester.tap(find.text('Delete', skipOffstage: false).last);
      await tester.pumpAndSettle();

      // Verify delete was called
      expect(deletedTaskId, 'task-1');
    });

    testWidgets('can toggle task completion', (tester) async {
      Task? updatedTask;

      final taskWithProject = TaskWithProject(
        task: testTask,
        project: testProjects[0],
      );

      await pumpPanelForViewing(
        tester,
        taskWithProject,
        onUpdateTask: (projectId, task) async {
          updatedTask = task;
          return task;
        },
      );

      // Tap complete button
      await tester.tap(find.byIcon(Icons.check_circle_outline));
      await tester.pumpAndSettle();

      // Verify status was changed to completed
      expect(updatedTask?.status, TaskStatus.completed);
    });

    testWidgets('cancel edit returns to view mode', (tester) async {
      final taskWithProject = TaskWithProject(
        task: testTask,
        project: testProjects[0],
      );

      await pumpPanelForViewing(tester, taskWithProject);

      // Enter edit mode
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      // Verify in edit mode
      expect(find.text('Edit Task'), findsOneWidget);

      // Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Should return to view mode
      expect(find.text('Task Details'), findsOneWidget);
    });
  });

  group('TaskDetailPanel - Status Changes', () {
    testWidgets('can start working on todo task', (tester) async {
      Task? updatedTask;

      final taskWithProject = TaskWithProject(
        task: testTask.copyWith(status: TaskStatus.todo),
        project: testProjects[0],
      );

      await pumpPanelForViewing(
        tester,
        taskWithProject,
        onUpdateTask: (projectId, task) async {
          updatedTask = task;
          return task;
        },
      );

      // Tap start button
      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pumpAndSettle();

      // Verify status changed to in progress
      expect(updatedTask?.status, TaskStatus.inProgress);
    });

    testWidgets('can mark task as blocked', (tester) async {
      Task? updatedTask;

      final taskWithProject = TaskWithProject(
        task: testTask.copyWith(status: TaskStatus.inProgress),
        project: testProjects[0],
      );

      await pumpPanelForViewing(
        tester,
        taskWithProject,
        onUpdateTask: (projectId, task) async {
          updatedTask = task;
          return task;
        },
      );

      // Tap block button
      await tester.tap(find.byIcon(Icons.block));
      await tester.pumpAndSettle();

      // Enter blocker description
      await tester.enterText(find.widgetWithText(TextField, 'What is blocking this task?'), 'Waiting for approval');
      await tester.pumpAndSettle();

      // Confirm (use .last to avoid ambiguity - there are 2 instances)
      await tester.tap(find.text('Mark as Blocked').last);
      await tester.pumpAndSettle();

      // Verify task was blocked
      expect(updatedTask?.status, TaskStatus.blocked);
      expect(updatedTask?.blockerDescription, 'Waiting for approval');
    });
  });

  group('TaskDetailPanel - Error Handling', () {
    testWidgets('handles creation error gracefully', (tester) async {
      await pumpPanelForCreation(
        tester,
        onCreateTask: (projectId, task) async {
          throw Exception('Network error');
        },
      );

      // Select project
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Test Project 1').last);
      await tester.pumpAndSettle();

      // Fill in title
      await tester.enterText(find.widgetWithText(TextField, 'Enter task title'), 'New Task');
      await tester.pumpAndSettle();

      // Submit
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      // Should show error
      expect(find.textContaining('Error saving task'), findsOneWidget);
    });
  });
}
