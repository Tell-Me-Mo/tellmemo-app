import '../entities/project.dart';

abstract class ProjectsRepository {
  Future<List<Project>> getProjects();
  Future<Project> getProject(String id);
  Future<Project> createProject({
    required String name,
    required String description,
    required String createdBy,
    String? portfolioId,
    String? programId,
  });
  Future<Project> updateProject(String id, Map<String, dynamic> updates);
  Future<void> archiveProject(String id);
  Future<void> restoreProject(String id);
  Future<void> deleteProject(String id);
}