import 'package:pm_master_v2/features/hierarchy/domain/entities/hierarchy_item.dart';

/// Test fixtures for hierarchy widgets
class HierarchyTestFixtures {
  static HierarchyItem createPortfolio({
    String id = 'portfolio-1',
    String name = 'Test Portfolio',
    String? description,
    List<HierarchyItem> children = const [],
    Map<String, dynamic>? metadata,
  }) {
    return HierarchyItem(
      id: id,
      name: name,
      description: description,
      type: HierarchyItemType.portfolio,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 15),
      children: children,
      metadata: metadata ?? {
        'programCount': 2,
        'directProjectCount': 1,
        'count': children.length,
      },
    );
  }

  static HierarchyItem createProgram({
    String id = 'program-1',
    String name = 'Test Program',
    String? description,
    String? portfolioId = 'portfolio-1',
    List<HierarchyItem> children = const [],
    Map<String, dynamic>? metadata,
  }) {
    return HierarchyItem(
      id: id,
      name: name,
      description: description,
      type: HierarchyItemType.program,
      portfolioId: portfolioId,
      createdAt: DateTime(2024, 1, 5),
      updatedAt: DateTime(2024, 1, 20),
      children: children,
      metadata: metadata ?? {
        'projectCount': 3,
        'count': children.length,
      },
    );
  }

  static HierarchyItem createProject({
    String id = 'project-1',
    String name = 'Test Project',
    String? description,
    String? portfolioId = 'portfolio-1',
    String? programId,
    Map<String, dynamic>? metadata,
  }) {
    return HierarchyItem(
      id: id,
      name: name,
      description: description,
      type: HierarchyItemType.project,
      portfolioId: portfolioId,
      programId: programId,
      createdAt: DateTime(2024, 1, 10),
      updatedAt: DateTime(2024, 1, 25),
      metadata: metadata ?? {'status': 'active', 'memberCount': 5},
    );
  }

  static List<HierarchyItem> createSampleHierarchy() {
    final project1 = createProject(
      id: 'proj-1',
      name: 'Project Alpha',
      description: 'First project',
      programId: 'prog-1',
    );
    final project2 = createProject(
      id: 'proj-2',
      name: 'Project Beta',
      description: 'Second project',
      programId: 'prog-1',
    );
    final project3 = createProject(
      id: 'proj-3',
      name: 'Project Gamma',
      description: 'Third project',
    );

    final program1 = createProgram(
      id: 'prog-1',
      name: 'Program A',
      description: 'First program',
      children: [project1, project2],
    );
    final program2 = createProgram(
      id: 'prog-2',
      name: 'Program B',
      description: 'Second program',
      children: [],
    );

    final portfolio1 = createPortfolio(
      id: 'port-1',
      name: 'Portfolio X',
      description: 'Main portfolio',
      children: [program1, program2, project3],
    );

    return [portfolio1];
  }

  static HierarchyStatistics createSampleStatistics({
    int portfolioCount = 2,
    int programCount = 5,
    int projectCount = 15,
    int standaloneCount = 3,
  }) {
    return HierarchyStatistics(
      portfolioCount: portfolioCount,
      programCount: programCount,
      projectCount: projectCount,
      standaloneCount: standaloneCount,
      totalCount: portfolioCount + programCount + projectCount + standaloneCount,
    );
  }
}
