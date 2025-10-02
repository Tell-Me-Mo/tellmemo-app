import '../../domain/entities/project.dart';
import '../../domain/repositories/projects_repository.dart';
import '../../../../core/network/api_client.dart';
import '../models/project_model.dart';

class ProjectsRepositoryImpl implements ProjectsRepository {
  final ApiClient _apiClient;

  ProjectsRepositoryImpl(this._apiClient);

  @override
  Future<List<Project>> getProjects() async {
    try {
      final models = await _apiClient.getProjects();
      return models.map((model) => model.toEntity()).toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Project> getProject(String id) async {
    try {
      final model = await _apiClient.getProject(id);
      return model.toEntity();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Project> createProject({
    required String name,
    required String description,
    required String createdBy,
    String? portfolioId,
    String? programId,
  }) async {
    try {
      final model = await _apiClient.createProject({
        'name': name,
        'description': description,
        'created_by': createdBy,
        if (portfolioId != null) 'portfolio_id': portfolioId,
        if (programId != null) 'program_id': programId,
      });
      return model.toEntity();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Project> updateProject(String id, Map<String, dynamic> updates) async {
    try {
      final model = await _apiClient.updateProject(id, updates);
      return model.toEntity();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> archiveProject(String id) async {
    try {
      await _apiClient.archiveProject(id);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> restoreProject(String id) async {
    try {
      await _apiClient.restoreProject(id);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> deleteProject(String id) async {
    try {
      await _apiClient.deleteProject(id);
    } catch (e) {
      rethrow;
    }
  }
}