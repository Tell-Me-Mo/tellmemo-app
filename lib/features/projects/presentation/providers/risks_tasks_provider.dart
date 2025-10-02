import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../domain/entities/risk.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/blocker.dart';
import '../../domain/repositories/risks_tasks_repository.dart';
import '../../data/repositories/risks_tasks_repository_impl.dart';
import '../../../../core/network/dio_client.dart';
import '../../../risks/presentation/providers/global_risks_sync_provider.dart';
import '../../../../core/services/firebase_analytics_service.dart';

// Repository provider
final risksTasksRepositoryProvider = Provider<RisksTasksRepository>((ref) {
  return RisksTasksRepositoryImpl(dio: DioClient.instance);
});

// Risks provider for a specific project
final projectRisksProvider = FutureProvider.family<List<Risk>, String>((ref, projectId) async {
  final repository = ref.watch(risksTasksRepositoryProvider);
  return repository.getProjectRisks(projectId);
});

// Tasks provider for a specific project
final projectTasksProvider = FutureProvider.family<List<Task>, String>((ref, projectId) async {
  final repository = ref.watch(risksTasksRepositoryProvider);
  return repository.getProjectTasks(projectId);
});

// Blockers provider for a specific project
final projectBlockersProvider = FutureProvider.family<List<Blocker>, String>((ref, projectId) async {
  final repository = ref.watch(risksTasksRepositoryProvider);
  return repository.getProjectBlockers(projectId);
});

// State notifiers for managing risks and tasks
class RisksNotifier extends StateNotifier<AsyncValue<List<Risk>>> {
  final RisksTasksRepository _repository;
  final String projectId;
  final Ref _ref;

  RisksNotifier(this._repository, this.projectId, this._ref) : super(const AsyncValue.loading()) {
    loadRisks();
  }

  Future<void> loadRisks() async {
    if (!mounted) return;
    state = const AsyncValue.loading();
    try {
      final risks = await _repository.getProjectRisks(projectId);
      if (!mounted) return;
      state = AsyncValue.data(risks);
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addRisk(Risk risk) async {
    try {
      final newRisk = await _repository.createRisk(projectId, risk);
      if (!mounted) return;
      state = state.whenData((risks) => [...risks, newRisk]);

      // Log risk identified analytics
      try {
        await FirebaseAnalyticsService().logRiskIdentified(
          riskId: newRisk.id,
          projectId: projectId,
          severity: newRisk.severity.name,
          isAiGenerated: newRisk.aiGenerated,
          source: newRisk.sourceContentId != null ? 'ai_content' : 'manual',
        );
      } catch (e) {
        // Silently fail analytics
      }

      // Invalidate aggregated providers to sync across screens
      _invalidateAggregatedProviders();
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateRisk(Risk risk) async {
    try {
      // Get old risk for comparison
      final oldRisk = state.value?.firstWhere((r) => r.id == risk.id, orElse: () => risk);

      final updatedRisk = await _repository.updateRisk(risk.id, risk);
      if (!mounted) return;
      state = state.whenData((risks) {
        final index = risks.indexWhere((r) => r.id == risk.id);
        if (index != -1) {
          final newList = [...risks];
          newList[index] = updatedRisk;
          return newList;
        }
        return risks;
      });

      // Log risk analytics
      try {
        // Track status change separately
        if (oldRisk != null && oldRisk.status != updatedRisk.status) {
          await FirebaseAnalyticsService().logRiskStatusChanged(
            riskId: updatedRisk.id,
            projectId: projectId,
            fromStatus: oldRisk.status.name,
            toStatus: updatedRisk.status.name,
          );
        }

        // Track severity change separately
        if (oldRisk != null && oldRisk.severity != updatedRisk.severity) {
          await FirebaseAnalyticsService().logRiskSeverityChanged(
            riskId: updatedRisk.id,
            projectId: projectId,
            fromSeverity: oldRisk.severity.name,
            toSeverity: updatedRisk.severity.name,
          );
        }

        // Track assignee change
        if (oldRisk != null && oldRisk.assignedTo != updatedRisk.assignedTo) {
          await FirebaseAnalyticsService().logRiskAssigned(
            riskId: updatedRisk.id,
            projectId: projectId,
            hasAssignee: updatedRisk.assignedTo != null,
          );
        }

        // Track general update
        final fieldsChanged = <String>[];
        if (oldRisk != null) {
          if (oldRisk.title != updatedRisk.title) fieldsChanged.add('title');
          if (oldRisk.description != updatedRisk.description) fieldsChanged.add('description');
          if (oldRisk.mitigation != updatedRisk.mitigation) fieldsChanged.add('mitigation');
          if (oldRisk.impact != updatedRisk.impact) fieldsChanged.add('impact');
          if (oldRisk.probability != updatedRisk.probability) fieldsChanged.add('probability');
        }

        if (fieldsChanged.isNotEmpty) {
          await FirebaseAnalyticsService().logRiskUpdated(
            riskId: updatedRisk.id,
            projectId: projectId,
            fieldsChanged: fieldsChanged,
          );
        }
      } catch (e) {
        // Silently fail analytics
      }

      // Invalidate aggregated providers to sync across screens
      _invalidateAggregatedProviders();
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteRisk(String riskId) async {
    try {
      await _repository.deleteRisk(riskId);
      if (!mounted) return;
      state = state.whenData((risks) => risks.where((r) => r.id != riskId).toList());
      // Invalidate aggregated providers to sync across screens
      _invalidateAggregatedProviders();
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncValue.error(e, st);
    }
  }

  void _invalidateAggregatedProviders() {
    // Import the aggregated risks provider and invalidate it
    // This will be done by importing and invalidating specific providers
    _invalidateRiskProviders();
  }

  void _invalidateRiskProviders() {
    try {
      // Invalidate local project risks provider
      _ref.invalidate(projectRisksProvider(projectId));
      // Trigger global risks sync to update all aggregated views
      triggerGlobalRisksSync(_ref);
    } catch (e) {
      // Silently handle invalidation errors to prevent crashes
    }
  }
}

class TasksNotifier extends StateNotifier<AsyncValue<List<Task>>> {
  final RisksTasksRepository _repository;
  final String projectId;

  TasksNotifier(this._repository, this.projectId) : super(const AsyncValue.loading()) {
    loadTasks();
  }

  Future<void> loadTasks() async {
    if (!mounted) return;
    state = const AsyncValue.loading();
    try {
      final tasks = await _repository.getProjectTasks(projectId);
      if (!mounted) return;
      state = AsyncValue.data(tasks);
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addTask(Task task) async {
    try {
      final newTask = await _repository.createTask(projectId, task);
      if (!mounted) return;
      state = state.whenData((tasks) => [...tasks, newTask]);

      // Log task created analytics
      try {
        await FirebaseAnalyticsService().logTaskCreated(
          taskId: newTask.id,
          projectId: projectId,
          priority: newTask.priority.name,
          hasDueDate: newTask.dueDate != null,
          hasAssignee: newTask.assignee != null,
        );
      } catch (e) {
        // Silently fail analytics
      }
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateTask(Task task) async {
    try {
      // Get old task for comparison
      final oldTask = state.value?.firstWhere((t) => t.id == task.id, orElse: () => task);

      final updatedTask = await _repository.updateTask(task.id, task);
      if (!mounted) return;
      state = state.whenData((tasks) {
        final index = tasks.indexWhere((t) => t.id == task.id);
        if (index != -1) {
          final newList = [...tasks];
          newList[index] = updatedTask;
          return newList;
        }
        return tasks;
      });

      // Log task updated analytics
      try {
        // Track status change separately if it changed
        if (oldTask != null && oldTask.status != updatedTask.status) {
          await FirebaseAnalyticsService().logTaskStatusChanged(
            taskId: updatedTask.id,
            projectId: projectId,
            fromStatus: oldTask.status.name,
            toStatus: updatedTask.status.name,
          );
        }

        // Track general update
        final fieldsChanged = <String>[];
        if (oldTask != null) {
          if (oldTask.title != updatedTask.title) fieldsChanged.add('title');
          if (oldTask.description != updatedTask.description) fieldsChanged.add('description');
          if (oldTask.priority != updatedTask.priority) fieldsChanged.add('priority');
          if (oldTask.assignee != updatedTask.assignee) fieldsChanged.add('assignee');
          if (oldTask.dueDate != updatedTask.dueDate) fieldsChanged.add('dueDate');
          if (oldTask.progressPercentage != updatedTask.progressPercentage) fieldsChanged.add('progress');
        }

        if (fieldsChanged.isNotEmpty) {
          await FirebaseAnalyticsService().logTaskUpdated(
            taskId: updatedTask.id,
            projectId: projectId,
            fieldsChanged: fieldsChanged,
          );
        }
      } catch (e) {
        // Silently fail analytics
      }
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      await _repository.deleteTask(taskId);
      if (!mounted) return;
      state = state.whenData((tasks) => tasks.where((t) => t.id != taskId).toList());

      // Log task deleted analytics
      try {
        await FirebaseAnalyticsService().logTaskDeleted(
          taskId: taskId,
          projectId: projectId,
        );
      } catch (e) {
        // Silently fail analytics
      }
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncValue.error(e, st);
    }
  }
}

class BlockersNotifier extends StateNotifier<AsyncValue<List<Blocker>>> {
  final RisksTasksRepository _repository;
  final String projectId;
  final Ref _ref;

  BlockersNotifier(this._repository, this.projectId, this._ref) : super(const AsyncValue.loading()) {
    loadBlockers();
  }

  Future<void> loadBlockers() async {
    if (!mounted) return;
    state = const AsyncValue.loading();
    try {
      final blockers = await _repository.getProjectBlockers(projectId);
      if (!mounted) return;
      state = AsyncValue.data(blockers);
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addBlocker(Blocker blocker) async {
    try {
      final newBlocker = await _repository.createBlocker(projectId, blocker);
      if (!mounted) return;
      state = state.whenData((blockers) => [...blockers, newBlocker]);
      // Refresh the provider
      _ref.invalidate(projectBlockersProvider(projectId));
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateBlocker(Blocker blocker) async {
    try {
      final updatedBlocker = await _repository.updateBlocker(blocker.id, blocker);
      if (!mounted) return;
      state = state.whenData((blockers) {
        final index = blockers.indexWhere((b) => b.id == blocker.id);
        if (index != -1) {
          final newList = [...blockers];
          newList[index] = updatedBlocker;
          return newList;
        }
        return blockers;
      });
      // Refresh the provider
      _ref.invalidate(projectBlockersProvider(projectId));
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteBlocker(String blockerId) async {
    try {
      await _repository.deleteBlocker(blockerId);
      if (!mounted) return;
      state = state.whenData((blockers) => blockers.where((b) => b.id != blockerId).toList());
      // Refresh the provider
      _ref.invalidate(projectBlockersProvider(projectId));
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncValue.error(e, st);
    }
  }
}

// State notifier providers
final risksNotifierProvider = StateNotifierProvider.family<RisksNotifier, AsyncValue<List<Risk>>, String>((ref, projectId) {
  final repository = ref.watch(risksTasksRepositoryProvider);
  return RisksNotifier(repository, projectId, ref);
});

final tasksNotifierProvider = StateNotifierProvider.family<TasksNotifier, AsyncValue<List<Task>>, String>((ref, projectId) {
  final repository = ref.watch(risksTasksRepositoryProvider);
  return TasksNotifier(repository, projectId);
});

final blockersNotifierProvider = StateNotifierProvider.family<BlockersNotifier, AsyncValue<List<Blocker>>, String>((ref, projectId) {
  final repository = ref.watch(risksTasksRepositoryProvider);
  return BlockersNotifier(repository, projectId, ref);
});