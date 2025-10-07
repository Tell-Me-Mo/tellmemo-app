import '../../domain/entities/risk.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/blocker.dart';
import '../../domain/repositories/risks_tasks_repository.dart';
import '../models/risk_model.dart';
import '../models/task_model.dart';
import '../models/blocker_model.dart';
import '../../../../core/utils/logger.dart' as logger;
import 'package:dio/dio.dart';

class RisksTasksRepositoryImpl implements RisksTasksRepository {
  final Dio _dio;

  RisksTasksRepositoryImpl({
    required Dio dio,
  }) : _dio = dio;

  @override
  Future<List<Risk>> getProjectRisks(String projectId) async {
    try {
      final response = await _dio.get(
        '/api/v1/projects/$projectId/risks',
      );

      final risks = (response.data as List)
          .map((json) => RiskModel.fromJson(json).toEntity())
          .toList();

      return risks;
    } catch (e) {
      logger.Logger.error('Failed to fetch project risks', e);
      rethrow;
    }
  }

  @override
  Future<List<Task>> getProjectTasks(String projectId) async {
    try {
      final response = await _dio.get(
        '/api/v1/projects/$projectId/tasks',
      );

      final tasks = (response.data as List)
          .map((json) => TaskModel.fromJson(json).toEntity())
          .toList();

      return tasks;
    } catch (e) {
      logger.Logger.error('Failed to fetch project tasks', e);
      rethrow;
    }
  }

  @override
  Future<Risk> createRisk(String projectId, Risk risk) async {
    try {
      final response = await _dio.post(
        '/api/v1/projects/$projectId/risks',
        data: {
          'title': risk.title,
          'description': risk.description,
          'severity': risk.severity.name,
          'status': risk.status.name,
          'mitigation': risk.mitigation,
          'impact': risk.impact,
          'probability': risk.probability,
          'assigned_to': risk.assignedTo,
          'assigned_to_email': risk.assignedToEmail,
        },
      );

      return RiskModel.fromJson(response.data).toEntity();
    } catch (e) {
      logger.Logger.error('Failed to create risk', e);
      rethrow;
    }
  }

  @override
  Future<Task> createTask(String projectId, Task task) async {
    try {
      final response = await _dio.post(
        '/api/v1/projects/$projectId/tasks',
        data: {
          'title': task.title,
          'description': task.description,
          'status': _convertTaskStatusToBackend(task.status),
          'priority': task.priority.name,
          'assignee': task.assignee,
          'due_date': task.dueDate?.toIso8601String(),
          'progress_percentage': task.progressPercentage,
          'blocker_description': task.blockerDescription,
          'question_to_ask': task.questionToAsk,
          'depends_on_risk_id': task.dependsOnRiskId,
        },
      );

      return TaskModel.fromJson(response.data).toEntity();
    } catch (e) {
      logger.Logger.error('Failed to create task', e);
      rethrow;
    }
  }

  @override
  Future<Risk> updateRisk(String riskId, Risk risk) async {
    try {
      final response = await _dio.patch(
        '/api/v1/risks/$riskId',
        data: {
          'title': risk.title,
          'description': risk.description,
          'severity': risk.severity.name,
          'status': risk.status.name,
          'mitigation': risk.mitigation,
          'impact': risk.impact,
          'probability': risk.probability,
          'assigned_to': risk.assignedTo,
          'assigned_to_email': risk.assignedToEmail,
        },
      );

      return RiskModel.fromJson(response.data).toEntity();
    } catch (e) {
      logger.Logger.error('Failed to update risk', e);
      rethrow;
    }
  }

  @override
  Future<Task> updateTask(String taskId, Task task) async {
    try {
      final response = await _dio.patch(
        '/api/v1/tasks/$taskId',
        data: {
          'title': task.title,
          'description': task.description,
          'status': _convertTaskStatusToBackend(task.status),
          'priority': task.priority.name,
          'assignee': task.assignee,
          'due_date': task.dueDate?.toIso8601String(),
          'completed_date': task.completedDate?.toIso8601String(),
          'progress_percentage': task.progressPercentage,
          'blocker_description': task.blockerDescription,
          'question_to_ask': task.questionToAsk,
        },
      );

      return TaskModel.fromJson(response.data).toEntity();
    } catch (e) {
      logger.Logger.error('Failed to update task', e);
      rethrow;
    }
  }

  @override
  Future<void> deleteRisk(String riskId) async {
    try {
      await _dio.delete('/api/v1/risks/$riskId');
    } catch (e) {
      logger.Logger.error('Failed to delete risk', e);
      rethrow;
    }
  }

  @override
  Future<void> deleteTask(String taskId) async {
    try {
      await _dio.delete('/api/v1/tasks/$taskId');
    } catch (e) {
      logger.Logger.error('Failed to delete task', e);
      rethrow;
    }
  }

  @override
  Future<List<Blocker>> getProjectBlockers(String projectId) async {
    try {
      final response = await _dio.get(
        '/api/v1/projects/$projectId/blockers',
      );

      final blockers = (response.data as List)
          .map((json) => BlockerModel.fromJson(json).toEntity())
          .toList();

      return blockers;
    } catch (e) {
      logger.Logger.error('Failed to fetch project blockers', e);
      rethrow;
    }
  }

  @override
  Future<Blocker> createBlocker(String projectId, Blocker blocker) async {
    try {
      final response = await _dio.post(
        '/api/v1/projects/$projectId/blockers',
        data: {
          'title': blocker.title,
          'description': blocker.description,
          'impact': blocker.impact.name,
          'status': blocker.status.name,
          'resolution': blocker.resolution,
          'category': blocker.category,
          'owner': blocker.owner,
          'dependencies': blocker.dependencies,
          'target_date': blocker.targetDate?.toIso8601String(),
          'assigned_to': blocker.assignedTo,
          'assigned_to_email': blocker.assignedToEmail,
        },
      );

      return BlockerModel.fromJson(response.data).toEntity();
    } catch (e) {
      logger.Logger.error('Failed to create blocker', e);
      rethrow;
    }
  }

  @override
  Future<Blocker> updateBlocker(String blockerId, Blocker blocker) async {
    try {
      final response = await _dio.patch(
        '/api/v1/blockers/$blockerId',
        data: {
          'title': blocker.title,
          'description': blocker.description,
          'impact': blocker.impact.name,
          'status': blocker.status.name,
          'resolution': blocker.resolution,
          'category': blocker.category,
          'owner': blocker.owner,
          'dependencies': blocker.dependencies,
          'target_date': blocker.targetDate?.toIso8601String(),
          'resolved_date': blocker.resolvedDate?.toIso8601String(),
          'escalation_date': blocker.escalationDate?.toIso8601String(),
          'assigned_to': blocker.assignedTo,
          'assigned_to_email': blocker.assignedToEmail,
        },
      );

      return BlockerModel.fromJson(response.data).toEntity();
    } catch (e) {
      logger.Logger.error('Failed to update blocker', e);
      rethrow;
    }
  }

  @override
  Future<void> deleteBlocker(String blockerId) async {
    try {
      await _dio.delete('/api/v1/blockers/$blockerId');
    } catch (e) {
      logger.Logger.error('Failed to delete blocker', e);
      rethrow;
    }
  }

  String _convertTaskStatusToBackend(TaskStatus status) {
    switch (status) {
      case TaskStatus.inProgress:
        return 'in_progress';
      default:
        return status.name;
    }
  }
}