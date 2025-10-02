import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../projects/domain/entities/project.dart';

part 'program.freezed.dart';

@freezed
class Program with _$Program {
  const factory Program({
    required String id,
    required String name,
    String? description,
    String? portfolioId,
    String? portfolioName,
    String? createdBy,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default([]) List<Project> projects,
    @Default(0) int projectCount,
  }) = _Program;
  
  const Program._();
  
  /// Get count of active projects
  int get activeProjectCount => projects.where((p) => p.status == ProjectStatus.active).length;
  
  /// Get count of archived projects
  int get archivedProjectCount => projects.where((p) => p.status == ProjectStatus.archived).length;
  
  /// Check if program has any projects
  bool get isEmpty => projects.isEmpty;
  
  /// Get projects by status
  List<Project> getProjectsByStatus(ProjectStatus status) => 
      projects.where((p) => p.status == status).toList();
}