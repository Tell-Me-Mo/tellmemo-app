import '../entities/portfolio.dart';
import '../entities/program.dart';
import '../entities/hierarchy_item.dart';

abstract class HierarchyRepository {
  // Hierarchy operations
  Future<List<HierarchyItem>> getFullHierarchy({bool includeArchived = false});
  Future<HierarchyItem> moveItem({
    required String itemId,
    required String itemType,
    String? targetParentId,
    String? targetParentType,
  });
  Future<Map<String, dynamic>> bulkMoveItems({
    required List<Map<String, String>> items,
    String? targetParentId,
    String? targetParentType,
  });
  Future<Map<String, dynamic>> bulkDeleteItems({
    required List<Map<String, String>> items,
    bool deleteChildren,
    String? reassignToId,
    String? reassignToType,
  });
  Future<List<HierarchyBreadcrumb>> getHierarchyPath({
    required String itemId,
    required String itemType,
  });
  Future<Map<String, dynamic>> getHierarchyStatistics();

  // Portfolio operations
  Future<List<Portfolio>> getPortfolios();
  Future<Portfolio?> getPortfolio(String portfolioId);
  Future<Portfolio> createPortfolio({
    required String name,
    String? description,
  });
  Future<Portfolio> updatePortfolio({
    required String portfolioId,
    String? name,
    String? description,
    String? owner,
    HealthStatus? healthStatus,
    String? riskSummary,
  });
  Future<void> deletePortfolio({
    required String portfolioId,
    bool cascadeDelete,
  });
  Future<Map<String, dynamic>> getPortfolioStatistics(String portfolioId);

  // Program operations
  Future<List<Program>> getPrograms({String? portfolioId});
  Future<Program?> getProgram(String programId);
  Future<Program> createProgram({
    required String name,
    String? portfolioId,
    String? description,
  });
  Future<Program> updateProgram({
    required String programId,
    String? name,
    String? description,
    String? portfolioId,
  });
  Future<void> deleteProgram({
    required String programId,
    bool cascadeDelete,
  });
  Future<Map<String, dynamic>> moveProjectsToProgram({
    required String programId,
    required List<String> projectIds,
  });
  Future<Map<String, dynamic>> getProgramStatistics(String programId);
}