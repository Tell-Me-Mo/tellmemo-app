import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pm_master_v2/features/projects/domain/entities/task.dart';
import 'package:pm_master_v2/features/projects/domain/repositories/risks_tasks_repository.dart';
import 'package:pm_master_v2/features/projects/presentation/providers/risks_tasks_provider.dart';
import 'package:pm_master_v2/features/tasks/presentation/providers/aggregated_tasks_provider.dart';

/// Mock RisksTasksRepository for testing
class MockRisksTasksRepository implements RisksTasksRepository {
  final Future<Task> Function(String projectId, Task task)? _onCreateTask;
  final Future<Task> Function(String taskId, Task task)? _onUpdateTask;
  final Future<void> Function(String taskId)? _onDeleteTask;
  final List<Task> Function(String projectId)? _onGetTasks;

  MockRisksTasksRepository({
    Future<Task> Function(String projectId, Task task)? onCreateTask,
    Future<Task> Function(String taskId, Task task)? onUpdateTask,
    Future<void> Function(String taskId)? onDeleteTask,
    List<Task> Function(String projectId)? onGetTasks,
  })  : _onCreateTask = onCreateTask,
        _onUpdateTask = onUpdateTask,
        _onDeleteTask = onDeleteTask,
        _onGetTasks = onGetTasks;

  @override
  Future<Task> createTask(String projectId, Task task) async {
    if (_onCreateTask != null) {
      return _onCreateTask!(projectId, task);
    }
    return task;
  }

  @override
  Future<Task> updateTask(String taskId, Task task) async {
    if (_onUpdateTask != null) {
      return _onUpdateTask!(taskId, task);
    }
    return task;
  }

  @override
  Future<void> deleteTask(String taskId) async {
    if (_onDeleteTask != null) {
      return _onDeleteTask!(taskId);
    }
  }

  @override
  Future<List<Task>> getProjectTasks(String projectId) async {
    if (_onGetTasks != null) {
      return _onGetTasks!(projectId);
    }
    return [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError('Not implemented in mock');
}

/// Helper function to create tasks repository provider override
Override createRisksTasksRepositoryOverride({
  Future<Task> Function(String projectId, Task task)? onCreateTask,
  Future<Task> Function(String taskId, Task task)? onUpdateTask,
  Future<void> Function(String taskId)? onDeleteTask,
  List<Task> Function(String projectId)? onGetTasks,
}) {
  return risksTasksRepositoryProvider.overrideWith((ref) {
    return MockRisksTasksRepository(
      onCreateTask: onCreateTask,
      onUpdateTask: onUpdateTask,
      onDeleteTask: onDeleteTask,
      onGetTasks: onGetTasks,
    );
  });
}

/// Helper function to create force refresh provider override
Override createForceRefreshTasksOverride({VoidCallback? onRefresh}) {
  return forceRefreshTasksProvider.overrideWith((ref) {
    return () async {
      if (onRefresh != null) {
        onRefresh();
      }
      // Invalidate providers
      ref.invalidate(projectTasksProvider);
      await ref.refresh(aggregatedTasksProvider.future);
    };
  });
}
