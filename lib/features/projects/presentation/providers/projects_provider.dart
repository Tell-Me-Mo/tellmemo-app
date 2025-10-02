import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/project.dart';
import '../../domain/repositories/projects_repository.dart';
import '../../data/repositories/projects_repository_impl.dart';
import '../../../../shared/providers/api_client_provider.dart';
import '../../../organizations/presentation/providers/organization_provider.dart';
import '../../../../core/services/firebase_analytics_service.dart';

part 'projects_provider.g.dart';

// Selected project state provider
final selectedProjectProvider = StateProvider<Project?>((ref) => null);

// Repository provider
@riverpod
ProjectsRepository projectsRepository(Ref ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ProjectsRepositoryImpl(apiClient);
}

// Projects list provider
@riverpod
class ProjectsList extends _$ProjectsList {
  @override
  Future<List<Project>> build() async {
    print('[PROJECTS_DEBUG] ProjectsList.build() called at ${DateTime.now()}');

    // Watch organization changes to auto-refresh when organization switches
    ref.watch(organizationChangedProvider);

    // Provider will auto-rebuild when organization changes
    // Organization context is handled by the API interceptor
    final repository = ref.read(projectsRepositoryProvider);

    // Keep provider alive for 5 minutes to avoid refetching on navigation
    ref.keepAlive();
    Timer(const Duration(minutes: 5), () {
      ref.invalidateSelf();
    });

    print('[PROJECTS_DEBUG] Fetching projects from repository...');
    final projects = await repository.getProjects();
    print('[PROJECTS_DEBUG] Fetched ${projects.length} projects');
    return projects;
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(projectsRepositoryProvider);
      final projects = await repository.getProjects();
      state = AsyncValue.data(projects);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<Project> createProject({
    required String name,
    required String description,
    required String createdBy,
    String? portfolioId,
    String? programId,
  }) async {
    try {
      final repository = ref.read(projectsRepositoryProvider);
      final createdProject = await repository.createProject(
        name: name,
        description: description,
        createdBy: createdBy,
        portfolioId: portfolioId,
        programId: programId,
      );

      // Log project created analytics
      try {
        await FirebaseAnalyticsService().logProjectCreated(
          projectId: createdProject.id,
          projectName: createdProject.name,
          parentId: portfolioId ?? programId,
          parentType: portfolioId != null
              ? 'portfolio'
              : (programId != null ? 'program' : null),
        );
      } catch (e) {
        print('[PMaster] Failed to log project created analytics: $e');
      }

      // Refresh the list after creating
      await refresh();
      return createdProject;
    } catch (error) {
      // Handle error appropriately in UI
      rethrow;
    }
  }

  Future<void> archiveProject(String id) async {
    try {
      final repository = ref.read(projectsRepositoryProvider);
      await repository.archiveProject(id);

      // Log project archived analytics
      try {
        await FirebaseAnalyticsService().logProjectArchived(projectId: id);
      } catch (e) {
        print('[PMaster] Failed to log project archived analytics: $e');
      }

      // Refresh the list after archiving
      await refresh();
    } catch (error) {
      // Handle error appropriately in UI
      rethrow;
    }
  }

  Future<void> restoreProject(String id) async {
    try {
      final repository = ref.read(projectsRepositoryProvider);
      await repository.restoreProject(id);
      // Refresh the list after restoring
      await refresh();
    } catch (error) {
      // Handle error appropriately in UI
      rethrow;
    }
  }

  Future<void> deleteProject(String id) async {
    try {
      final repository = ref.read(projectsRepositoryProvider);
      await repository.deleteProject(id);

      // Log project deleted analytics
      try {
        await FirebaseAnalyticsService().logProjectDeleted(projectId: id);
      } catch (e) {
        print('[PMaster] Failed to log project deleted analytics: $e');
      }

      // Refresh the list after deletion
      await refresh();
    } catch (error) {
      // Handle error appropriately in UI
      rethrow;
    }
  }

  Future<void> updateProject(String id, Map<String, dynamic> updates) async {
    try {
      final repository = ref.read(projectsRepositoryProvider);
      await repository.updateProject(id, updates);

      // Log project updated analytics
      try {
        await FirebaseAnalyticsService().logProjectUpdated(
          projectId: id,
          fieldsChanged: updates.keys.toList(),
        );
      } catch (e) {
        print('[PMaster] Failed to log project updated analytics: $e');
      }

      // Refresh the list after updating
      await refresh();
    } catch (error) {
      // Handle error appropriately in UI
      rethrow;
    }
  }
}

// Individual project provider
@riverpod
class ProjectDetail extends _$ProjectDetail {
  @override
  Future<Project?> build(String projectId) async {
    // Organization context is handled by the API interceptor
    final repository = ref.read(projectsRepositoryProvider);

    // Keep provider alive for 5 minutes
    ref.keepAlive();
    Timer(const Duration(minutes: 5), () {
      ref.invalidateSelf();
    });

    try {
      final project = await repository.getProject(projectId);

      // Log project viewed analytics
      if (project != null) {
        try {
          await FirebaseAnalyticsService().logProjectViewed(
            projectId: project.id,
            projectName: project.name,
            viewSource: 'detail_page',
          );
        } catch (e) {
          print('[PMaster] Failed to log project viewed analytics: $e');
        }
      }

      return project;
    } catch (e) {
      // If project not found, return null
      return null;
    }
  }

  Future<void> updateProject(Map<String, dynamic> updates) async {
    final currentProject = state.value;
    if (currentProject == null) return;

    try {
      final repository = ref.read(projectsRepositoryProvider);
      final updatedProject = await repository.updateProject(
        currentProject.id,
        updates,
      );
      state = AsyncValue.data(updatedProject);

      // Log project updated analytics
      try {
        await FirebaseAnalyticsService().logProjectUpdated(
          projectId: currentProject.id,
          fieldsChanged: updates.keys.toList(),
        );
      } catch (e) {
        print('[PMaster] Failed to log project updated analytics: $e');
      }

      // Also refresh the projects list
      ref.invalidate(projectsListProvider);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}