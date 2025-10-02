import 'package:freezed_annotation/freezed_annotation.dart';
import 'portfolio.dart';
import 'program.dart';
import '../../../projects/domain/entities/project.dart';

part 'hierarchy_item.freezed.dart';

enum HierarchyItemType {
  portfolio,
  program,
  project,
}

@freezed
class HierarchyItem with _$HierarchyItem {
  const factory HierarchyItem({
    required String id,
    required String name,
    String? description,
    required HierarchyItemType type,
    String? portfolioId,
    String? programId,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default([]) List<HierarchyItem> children,
    Map<String, dynamic>? metadata,
  }) = _HierarchyItem;
  
  const HierarchyItem._();
  
  /// Create from Portfolio
  factory HierarchyItem.fromPortfolio(Portfolio portfolio) {
    List<HierarchyItem> children = [];
    
    // Add programs as children
    children.addAll(
      portfolio.programs.map((program) => HierarchyItem.fromProgram(program))
    );
    
    // Add direct projects as children
    children.addAll(
      portfolio.directProjects.map((project) => HierarchyItem.fromProject(project))
    );
    
    return HierarchyItem(
      id: portfolio.id,
      name: portfolio.name,
      description: portfolio.description,
      type: HierarchyItemType.portfolio,
      createdAt: portfolio.createdAt,
      updatedAt: portfolio.updatedAt,
      children: children,
      metadata: {
        'programCount': portfolio.programs.length,
        'directProjectCount': portfolio.directProjects.length,
        'totalProjectCount': portfolio.totalProjectCount,
        'activeProjectCount': portfolio.activeProjectCount,
        'archivedProjectCount': portfolio.archivedProjectCount,
        'hasMixedContent': portfolio.hasMixedContent,
      },
    );
  }
  
  /// Create from Program
  factory HierarchyItem.fromProgram(Program program) {
    return HierarchyItem(
      id: program.id,
      name: program.name,
      description: program.description,
      type: HierarchyItemType.program,
      portfolioId: program.portfolioId,
      createdAt: program.createdAt,
      updatedAt: program.updatedAt,
      children: program.projects.map((project) => HierarchyItem.fromProject(project)).toList(),
      metadata: {
        'portfolioName': program.portfolioName,
        'projectCount': program.projects.length,
        'activeProjectCount': program.activeProjectCount,
        'archivedProjectCount': program.archivedProjectCount,
      },
    );
  }
  
  /// Create from Project
  factory HierarchyItem.fromProject(Project project) {
    return HierarchyItem(
      id: project.id,
      name: project.name,
      description: project.description,
      type: HierarchyItemType.project,
      portfolioId: project.portfolioId,
      programId: project.programId,
      createdAt: project.createdAt,
      updatedAt: project.updatedAt,
      metadata: {
        'status': project.status.name,
        'memberCount': project.memberCount ?? 0,
      },
    );
  }
  
  /// Get hierarchy path as breadcrumb items
  List<HierarchyBreadcrumb> getPath(List<HierarchyItem> fullHierarchy) {
    List<HierarchyBreadcrumb> path = [];
    
    if (type == HierarchyItemType.project && portfolioId != null) {
      // Find portfolio
      final portfolio = fullHierarchy.firstWhere(
        (item) => item.id == portfolioId && item.type == HierarchyItemType.portfolio,
        orElse: () => throw StateError('Portfolio not found'),
      );
      path.add(HierarchyBreadcrumb(id: portfolio.id, name: portfolio.name, type: HierarchyItemType.portfolio));
      
      // Find program if exists
      if (programId != null) {
        final program = portfolio.children.firstWhere(
          (item) => item.id == programId && item.type == HierarchyItemType.program,
          orElse: () => throw StateError('Program not found'),
        );
        path.add(HierarchyBreadcrumb(id: program.id, name: program.name, type: HierarchyItemType.program));
      }
    } else if (type == HierarchyItemType.program && portfolioId != null) {
      // Find portfolio
      final portfolio = fullHierarchy.firstWhere(
        (item) => item.id == portfolioId && item.type == HierarchyItemType.portfolio,
        orElse: () => throw StateError('Portfolio not found'),
      );
      path.add(HierarchyBreadcrumb(id: portfolio.id, name: portfolio.name, type: HierarchyItemType.portfolio));
    }
    
    // Add current item
    path.add(HierarchyBreadcrumb(id: id, name: name, type: type));
    
    return path;
  }
  
  /// Check if this item can contain other items
  bool get canContainChildren => type == HierarchyItemType.portfolio || type == HierarchyItemType.program;
  
  /// Check if this item has children
  bool get hasChildren => children.isNotEmpty;
  
  /// Check if this item can be moved
  bool get canBeMoved => type == HierarchyItemType.program || type == HierarchyItemType.project;
  
  /// Get display icon based on type
  String get iconName {
    switch (type) {
      case HierarchyItemType.portfolio:
        return 'folder_special';
      case HierarchyItemType.program:
        return 'folder_open';
      case HierarchyItemType.project:
        return 'assignment';
    }
  }
}

@freezed
class HierarchyBreadcrumb with _$HierarchyBreadcrumb {
  const factory HierarchyBreadcrumb({
    required String id,
    required String name,
    required HierarchyItemType type,
  }) = _HierarchyBreadcrumb;
}

@freezed
class HierarchyStatistics with _$HierarchyStatistics {
  const factory HierarchyStatistics({
    required int portfolioCount,
    required int programCount,
    required int projectCount,
    required int standaloneCount,
    required int totalCount,
  }) = _HierarchyStatistics;
}