import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_master_v2/features/projects/domain/entities/project.dart';
import 'package:pm_master_v2/features/projects/domain/entities/task.dart';
import 'package:pm_master_v2/features/tasks/presentation/providers/aggregated_tasks_provider.dart';
import 'package:pm_master_v2/features/tasks/presentation/providers/tasks_filter_provider.dart';
import 'package:pm_master_v2/features/tasks/presentation/providers/grouped_tasks_provider.dart';

void main() {
  group('Grouped Tasks Provider Tests', () {
    late ProviderContainer container;

    // Sample test data
    final testProject1 = Project(
      id: 'project-1',
      name: 'Project Alpha',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      status: ProjectStatus.active,
    );

    final testProject2 = Project(
      id: 'project-2',
      name: 'Project Beta',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      status: ProjectStatus.active,
    );

    final testTask1 = Task(
      id: 'task-1',
      projectId: 'project-1',
      title: 'High priority task',
      status: TaskStatus.inProgress,
      priority: TaskPriority.high,
      assignee: 'john@example.com',
      dueDate: DateTime.now().add(const Duration(days: 2)),
    );

    final testTask2 = Task(
      id: 'task-2',
      projectId: 'project-1',
      title: 'Urgent task',
      status: TaskStatus.todo,
      priority: TaskPriority.urgent,
      assignee: 'jane@example.com',
      dueDate: DateTime.now().add(const Duration(days: 1)),
    );

    final testTask3 = Task(
      id: 'task-3',
      projectId: 'project-2',
      title: 'Medium priority task',
      status: TaskStatus.completed,
      priority: TaskPriority.medium,
      assignee: 'john@example.com',
      dueDate: DateTime.now().subtract(const Duration(days: 1)), // Overdue
    );

    final testTask4 = Task(
      id: 'task-4',
      projectId: 'project-2',
      title: 'Low priority task',
      status: TaskStatus.blocked,
      priority: TaskPriority.low,
      // No assignee
      dueDate: null, // No due date
    );

    tearDown(() {
      container.dispose();
    });

    group('groupBy: none', () {
      test('returns single group with all tasks', () {
        // Arrange
        final tasksWithProjects = [
          TaskWithProject(task: testTask1, project: testProject1),
          TaskWithProject(task: testTask2, project: testProject1),
          TaskWithProject(task: testTask3, project: testProject2),
        ];

        container = ProviderContainer(
          overrides: [
            tasksFilterProvider.overrideWith((ref) {
              return TasksFilterNotifier(ref, const TasksFilter(groupBy: TaskGroupBy.none));
            }),
            filteredTasksProvider.overrideWith((ref) {
              return tasksWithProjects;
            }),
          ],
        );

        // Act
        final groups = container.read(groupedTasksProvider);

        // Assert
        expect(groups.length, 1);
        expect(groups.first.id, 'all');
        expect(groups.first.name, 'All Tasks');
        expect(groups.first.tasks.length, 3);
        expect(groups.first.count, 3);
      });

      test('returns single empty group when no tasks', () {
        // Arrange
        container = ProviderContainer(
          overrides: [
            tasksFilterProvider.overrideWith((ref) {
              return TasksFilterNotifier(ref, const TasksFilter(groupBy: TaskGroupBy.none));
            }),
            filteredTasksProvider.overrideWith((ref) {
              return [];
            }),
          ],
        );

        // Act
        final groups = container.read(groupedTasksProvider);

        // Assert
        expect(groups.length, 1);
        expect(groups.first.tasks, isEmpty);
      });
    });

    group('groupBy: project', () {
      test('groups tasks by project', () {
        // Arrange
        final tasksWithProjects = [
          TaskWithProject(task: testTask1, project: testProject1),
          TaskWithProject(task: testTask2, project: testProject1),
          TaskWithProject(task: testTask3, project: testProject2),
          TaskWithProject(task: testTask4, project: testProject2),
        ];

        container = ProviderContainer(
          overrides: [
            tasksFilterProvider.overrideWith((ref) {
              return TasksFilterNotifier(ref, const TasksFilter(groupBy: TaskGroupBy.project));
            }),
            filteredTasksProvider.overrideWith((ref) {
              return tasksWithProjects;
            }),
          ],
        );

        // Act
        final groups = container.read(groupedTasksProvider);

        // Assert
        expect(groups.length, 2);
        expect(groups.map((g) => g.name).toSet(), {'Project Alpha', 'Project Beta'});
        expect(groups.where((g) => g.name == 'Project Alpha').first.tasks.length, 2);
        expect(groups.where((g) => g.name == 'Project Beta').first.tasks.length, 2);
      });
    });

    group('groupBy: status', () {
      test('groups tasks by status', () {
        // Arrange
        final tasksWithProjects = [
          TaskWithProject(task: testTask1, project: testProject1),
          TaskWithProject(task: testTask2, project: testProject1),
          TaskWithProject(task: testTask3, project: testProject2),
          TaskWithProject(task: testTask4, project: testProject2),
        ];

        container = ProviderContainer(
          overrides: [
            tasksFilterProvider.overrideWith((ref) {
              return TasksFilterNotifier(ref, const TasksFilter(groupBy: TaskGroupBy.status));
            }),
            filteredTasksProvider.overrideWith((ref) {
              return tasksWithProjects;
            }),
          ],
        );

        // Act
        final groups = container.read(groupedTasksProvider);

        // Assert
        expect(groups.length, 4); // todo, inProgress, blocked, completed
        final groupNames = groups.map((g) => g.name).toList();
        expect(groupNames, contains('To Do'));
        expect(groupNames, contains('In Progress'));
        expect(groupNames, contains('Blocked'));
        expect(groupNames, contains('Completed'));

        // Check sorting order (todo, inProgress, blocked, completed)
        expect(groups[0].name, 'To Do');
        expect(groups[1].name, 'In Progress');
        expect(groups[2].name, 'Blocked');
        expect(groups[3].name, 'Completed');
      });
    });

    group('groupBy: priority', () {
      test('groups tasks by priority', () {
        // Arrange
        final tasksWithProjects = [
          TaskWithProject(task: testTask1, project: testProject1),
          TaskWithProject(task: testTask2, project: testProject1),
          TaskWithProject(task: testTask3, project: testProject2),
          TaskWithProject(task: testTask4, project: testProject2),
        ];

        container = ProviderContainer(
          overrides: [
            tasksFilterProvider.overrideWith((ref) {
              return TasksFilterNotifier(ref, const TasksFilter(groupBy: TaskGroupBy.priority));
            }),
            filteredTasksProvider.overrideWith((ref) {
              return tasksWithProjects;
            }),
          ],
        );

        // Act
        final groups = container.read(groupedTasksProvider);

        // Assert
        expect(groups.length, 4); // urgent, high, medium, low
        final groupNames = groups.map((g) => g.name).toList();
        expect(groupNames, contains('Urgent'));
        expect(groupNames, contains('High Priority'));
        expect(groupNames, contains('Medium Priority'));
        expect(groupNames, contains('Low Priority'));

        // Check sorting order (urgent, high, medium, low)
        expect(groups[0].name, 'Urgent');
        expect(groups[1].name, 'High Priority');
        expect(groups[2].name, 'Medium Priority');
        expect(groups[3].name, 'Low Priority');
      });
    });

    group('groupBy: assignee', () {
      test('groups tasks by assignee', () {
        // Arrange
        final tasksWithProjects = [
          TaskWithProject(task: testTask1, project: testProject1),
          TaskWithProject(task: testTask2, project: testProject1),
          TaskWithProject(task: testTask3, project: testProject2),
          TaskWithProject(task: testTask4, project: testProject2),
        ];

        container = ProviderContainer(
          overrides: [
            tasksFilterProvider.overrideWith((ref) {
              return TasksFilterNotifier(ref, const TasksFilter(groupBy: TaskGroupBy.assignee));
            }),
            filteredTasksProvider.overrideWith((ref) {
              return tasksWithProjects;
            }),
          ],
        );

        // Act
        final groups = container.read(groupedTasksProvider);

        // Assert
        expect(groups.length, 3); // john@example.com, jane@example.com, Unassigned
        final groupNames = groups.map((g) => g.name).toSet();
        expect(groupNames, contains('john@example.com'));
        expect(groupNames, contains('jane@example.com'));
        expect(groupNames, contains('Unassigned'));

        // Check unassigned group
        final unassignedGroup = groups.firstWhere((g) => g.name == 'Unassigned');
        expect(unassignedGroup.tasks.length, 1);
        expect(unassignedGroup.tasks.first.task.id, testTask4.id);
      });
    });

    group('groupBy: dueDate', () {
      test('groups tasks by due date', () {
        // Arrange
        final now = DateTime.now();
        final taskOverdue = testTask3; // Due yesterday
        final taskTomorrow = testTask2.copyWith(
          id: 'task-tomorrow',
          dueDate: now.add(const Duration(hours: 25)), // Tomorrow (more than 24 hours)
        );
        final taskThisWeek = testTask1.copyWith(
          id: 'task-this-week',
          dueDate: now.add(const Duration(days: 3)),
        );
        final taskNoDueDate = testTask4; // No due date

        final tasksWithProjects = [
          TaskWithProject(task: taskOverdue, project: testProject1),
          TaskWithProject(task: taskTomorrow, project: testProject1),
          TaskWithProject(task: taskThisWeek, project: testProject2),
          TaskWithProject(task: taskNoDueDate, project: testProject2),
        ];

        container = ProviderContainer(
          overrides: [
            tasksFilterProvider.overrideWith((ref) {
              return TasksFilterNotifier(ref, const TasksFilter(groupBy: TaskGroupBy.dueDate));
            }),
            filteredTasksProvider.overrideWith((ref) {
              return tasksWithProjects;
            }),
          ],
        );

        // Act
        final groups = container.read(groupedTasksProvider);

        // Assert
        expect(groups.length, 4); // overdue, tomorrow, this-week, no-due-date
        final groupNames = groups.map((g) => g.name).toList();

        // Check for expected groups
        expect(groupNames, contains('Overdue'));
        expect(groupNames, contains('Due Tomorrow'));
        expect(groupNames, contains('Due This Week'));
        expect(groupNames, contains('No Due Date'));

        // Check sorting order (overdue first, no-due-date last)
        expect(groups.first.name, 'Overdue');
        expect(groups.last.name, 'No Due Date');
      });

      test('groups tasks by due date with today', () {
        // Arrange
        final now = DateTime.now();
        final taskToday = testTask1.copyWith(
          id: 'task-today',
          dueDate: now.add(const Duration(hours: 1)), // Due today (1 hour from now)
        );

        final tasksWithProjects = [
          TaskWithProject(task: taskToday, project: testProject1),
        ];

        container = ProviderContainer(
          overrides: [
            tasksFilterProvider.overrideWith((ref) {
              return TasksFilterNotifier(ref, const TasksFilter(groupBy: TaskGroupBy.dueDate));
            }),
            filteredTasksProvider.overrideWith((ref) {
              return tasksWithProjects;
            }),
          ],
        );

        // Act
        final groups = container.read(groupedTasksProvider);

        // Assert
        expect(groups.length, 1);
        expect(groups.first.name, 'Due Today');
      });
    });

    group('TaskGroup', () {
      test('count equals tasks length', () {
        // Arrange
        final tasksWithProjects = [
          TaskWithProject(task: testTask1, project: testProject1),
          TaskWithProject(task: testTask2, project: testProject1),
        ];

        final group = TaskGroup(
          id: 'test',
          name: 'Test Group',
          tasks: tasksWithProjects,
        );

        // Assert
        expect(group.count, 2);
        expect(group.count, tasksWithProjects.length);
      });
    });
  });
}
