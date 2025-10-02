import 'package:freezed_annotation/freezed_annotation.dart';
import 'program.dart';
import '../../../projects/domain/entities/project.dart';

part 'portfolio.freezed.dart';

enum HealthStatus {
  green,
  amber,
  red,
  notSet,
}

@freezed
class Portfolio with _$Portfolio {
  const factory Portfolio({
    required String id,
    required String name,
    String? description,
    String? owner,
    @Default(HealthStatus.notSet) HealthStatus healthStatus,
    String? riskSummary,
    String? createdBy,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default([]) List<Program> programs,
    @Default([]) List<Project> directProjects,
  }) = _Portfolio;
  
  const Portfolio._();
  
  /// Get total project count including projects in programs and direct projects
  int get totalProjectCount {
    int directCount = directProjects.length;
    int programProjectCount = programs.fold(0, (sum, program) => sum + program.projects.length);
    return directCount + programProjectCount;
  }
  
  /// Get count of active projects only
  int get activeProjectCount {
    int directActive = directProjects.where((p) => p.status == ProjectStatus.active).length;
    int programActive = programs.fold(0, (sum, program) => 
      sum + program.projects.where((p) => p.status == ProjectStatus.active).length
    );
    return directActive + programActive;
  }
  
  /// Get count of archived projects
  int get archivedProjectCount {
    int directArchived = directProjects.where((p) => p.status == ProjectStatus.archived).length;
    int programArchived = programs.fold(0, (sum, program) => 
      sum + program.projects.where((p) => p.status == ProjectStatus.archived).length
    );
    return directArchived + programArchived;
  }
  
  /// Check if portfolio has any content
  bool get isEmpty => programs.isEmpty && directProjects.isEmpty;
  
  /// Check if portfolio has mixed content (both programs and direct projects)
  bool get hasMixedContent => programs.isNotEmpty && directProjects.isNotEmpty;
}