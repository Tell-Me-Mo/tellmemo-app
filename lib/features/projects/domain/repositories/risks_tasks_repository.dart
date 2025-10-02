import '../entities/risk.dart';
import '../entities/task.dart';
import '../entities/blocker.dart';

abstract class RisksTasksRepository {
  Future<List<Risk>> getProjectRisks(String projectId);
  Future<List<Task>> getProjectTasks(String projectId);
  Future<List<Blocker>> getProjectBlockers(String projectId);
  Future<Risk> createRisk(String projectId, Risk risk);
  Future<Task> createTask(String projectId, Task task);
  Future<Blocker> createBlocker(String projectId, Blocker blocker);
  Future<Risk> updateRisk(String riskId, Risk risk);
  Future<Task> updateTask(String taskId, Task task);
  Future<Blocker> updateBlocker(String blockerId, Blocker blocker);
  Future<void> deleteRisk(String riskId);
  Future<void> deleteTask(String taskId);
  Future<void> deleteBlocker(String blockerId);
}