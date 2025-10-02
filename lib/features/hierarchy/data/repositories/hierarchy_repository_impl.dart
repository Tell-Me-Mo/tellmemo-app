import '../../domain/entities/portfolio.dart';
import '../../domain/entities/program.dart';
import '../../domain/entities/hierarchy_item.dart';
import '../../domain/repositories/hierarchy_repository.dart';
import '../services/hierarchy_api_service.dart';
import '../models/hierarchy_model.dart';
import '../models/portfolio_model.dart';
import '../models/program_model.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/logger.dart';

class HierarchyRepositoryImpl implements HierarchyRepository {
  final HierarchyApiService _apiService;
  
  HierarchyRepositoryImpl(this._apiService);

  @override
  Future<List<HierarchyItem>> getFullHierarchy({bool includeArchived = false}) async {
    try {
      final response = await _apiService.getFullHierarchy(includeArchived);
      return response.hierarchy.map((node) => node.toEntity()).toList();
    } catch (e) {
      Logger.error('Failed to get full hierarchy', e);
      throw ServerException('Failed to get hierarchy: ${e.toString()}');
    }
  }

  @override
  Future<HierarchyItem> moveItem({
    required String itemId,
    required String itemType,
    String? targetParentId,
    String? targetParentType,
  }) async {
    try {
      final request = MoveItemRequest(
        itemId: itemId,
        itemType: itemType,
        targetParentId: targetParentId,
        targetParentType: targetParentType,
      );
      
      final response = await _apiService.moveItem(request);
      return response.item.toEntity();
    } catch (e) {
      Logger.error('Failed to move item', e);
      throw ServerException('Failed to move item: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> bulkMoveItems({
    required List<Map<String, String>> items,
    String? targetParentId,
    String? targetParentType,
  }) async {
    try {
      final moveItems = items.map((item) => MoveItemData(
        id: item['id']!,
        type: item['type']!,
      )).toList();
      
      final request = BulkMoveRequest(
        items: moveItems,
        targetParentId: targetParentId,
        targetParentType: targetParentType,
      );
      
      final response = await _apiService.bulkMoveItems(request);
      return {
        'message': response.message,
        'success_count': response.results.successCount,
        'error_count': response.results.errorCount,
        'errors': response.results.errors,
        'moved_items': response.results.movedItems.map((item) => item.toEntity()).toList(),
      };
    } catch (e) {
      Logger.error('Failed to bulk move items', e);
      throw ServerException('Failed to bulk move items: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> bulkDeleteItems({
    required List<Map<String, String>> items,
    bool deleteChildren = true,
    String? reassignToId,
    String? reassignToType,
  }) async {
    try {
      final deleteItems = items.map((item) => MoveItemData(
        id: item['id']!,
        type: item['type']!,
      )).toList();
      
      final request = BulkDeleteRequest(
        items: deleteItems,
        deleteChildren: deleteChildren,
        reassignToId: reassignToId,
        reassignToType: reassignToType,
      );
      
      final response = await _apiService.bulkDeleteItems(request);
      return {
        'message': response.message,
        'deleted_count': response.results.deletedCount,
        'reassigned_count': response.results.reassignedCount ?? 0,
        'error_count': response.results.errorCount,
        'errors': response.results.errors,
      };
    } catch (e) {
      Logger.error('Failed to bulk delete items', e);
      throw ServerException('Failed to bulk delete items: ${e.toString()}');
    }
  }

  @override
  Future<List<HierarchyBreadcrumb>> getHierarchyPath({
    required String itemId,
    required String itemType,
  }) async {
    try {
      final httpResponse = await _apiService.getHierarchyPath({
        'item_id': itemId,
        'item_type': itemType,
      });
      
      final response = httpResponse.data as Map<String, dynamic>;
      final pathData = response['path'] as List<dynamic>;
      return pathData.map((item) {
        final data = item as Map<String, dynamic>;
        return HierarchyBreadcrumb(
          id: data['id'] as String,
          name: data['name'] as String,
          type: _parseHierarchyItemType(data['type'] as String),
        );
      }).toList();
    } catch (e) {
      Logger.error('Failed to get hierarchy path', e);
      throw ServerException('Failed to get hierarchy path: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> getHierarchyStatistics() async {
    try {
      final httpResponse = await _apiService.getHierarchyStatistics();
      return httpResponse.data as Map<String, dynamic>;
    } catch (e) {
      Logger.error('Failed to get hierarchy statistics', e);
      throw ServerException('Failed to get hierarchy statistics: ${e.toString()}');
    }
  }

  @override
  Future<List<Portfolio>> getPortfolios() async {
    try {
      final portfolioModels = await _apiService.getPortfolios();
      return portfolioModels.map((model) => model.toEntity()).toList();
    } catch (e) {
      Logger.error('Failed to get portfolios', e);
      throw ServerException('Failed to get portfolios: ${e.toString()}');
    }
  }

  @override
  Future<Portfolio?> getPortfolio(String portfolioId) async {
    try {
      final model = await _apiService.getPortfolio(portfolioId);
      return model.toEntity();
    } catch (e) {
      Logger.error('Failed to get portfolio', e);
      if (e.toString().contains('404')) {
        return null;
      }
      throw ServerException('Failed to get portfolio: ${e.toString()}');
    }
  }

  @override
  Future<Portfolio> createPortfolio({
    required String name,
    String? description,
  }) async {
    try {
      Logger.info('Creating portfolio with name: $name, description: $description');
      final model = await _apiService.createPortfolio({
        'name': name,
        if (description != null) 'description': description,
      });
      Logger.info('Received portfolio model: ${model.toJson()}');
      final entity = model.toEntity();
      Logger.info('Converted to entity successfully');
      return entity;
    } catch (e, stackTrace) {
      Logger.error('Failed to create portfolio', e);
      Logger.error('Stack trace:', stackTrace);
      throw ServerException('Failed to create portfolio: ${e.toString()}');
    }
  }

  @override
  Future<Portfolio> updatePortfolio({
    required String portfolioId,
    String? name,
    String? description,
    String? owner,
    HealthStatus? healthStatus,
    String? riskSummary,
  }) async {
    try {
      final model = await _apiService.updatePortfolio(portfolioId, {
        if (name != null) 'name': name,
        if (description != null) 'description': description,
        if (owner != null) 'owner': owner,
        if (healthStatus != null) 'health_status': healthStatus.name.toLowerCase(),
        if (riskSummary != null) 'risk_summary': riskSummary,
      });
      return model.toEntity();
    } catch (e) {
      Logger.error('Failed to update portfolio', e);
      throw ServerException('Failed to update portfolio: ${e.toString()}');
    }
  }

  @override
  Future<void> deletePortfolio({
    required String portfolioId,
    bool cascadeDelete = false,
  }) async {
    try {
      await _apiService.deletePortfolio(portfolioId, cascadeDelete);
      // HttpResponse is handled, no return needed for void
    } catch (e) {
      Logger.error('Failed to delete portfolio', e);
      throw ServerException('Failed to delete portfolio: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> getPortfolioStatistics(String portfolioId) async {
    try {
      final httpResponse = await _apiService.getPortfolioStatistics(portfolioId);
      return httpResponse.data as Map<String, dynamic>;
    } catch (e) {
      Logger.error('Failed to get portfolio statistics', e);
      throw ServerException('Failed to get portfolio statistics: ${e.toString()}');
    }
  }

  @override
  Future<List<Program>> getPrograms({String? portfolioId}) async {
    try {
      final programModels = await _apiService.getPrograms(portfolioId);
      return programModels.map((model) => model.toEntity()).toList();
    } catch (e) {
      Logger.error('Failed to get programs', e);
      throw ServerException('Failed to get programs: ${e.toString()}');
    }
  }

  @override
  Future<Program?> getProgram(String programId) async {
    try {
      Logger.info('Fetching program with ID: $programId');
      final model = await _apiService.getProgram(programId);
      Logger.info('Received program model: ${model.toJson()}');
      
      // Check for null fields that should not be null
      if (model.portfolioId == null) {
        Logger.warning('Program ${model.id} has null portfolioId');
      }
      
      final entity = model.toEntity();
      Logger.info('Converted to entity successfully');
      return entity;
    } catch (e, stackTrace) {
      Logger.error('Failed to get program', e);
      Logger.error('Stack trace: $stackTrace');
      if (e.toString().contains('404')) {
        return null;
      }
      throw ServerException('Failed to get program: ${e.toString()}');
    }
  }

  @override
  Future<Program> createProgram({
    required String name,
    String? portfolioId,
    String? description,
  }) async {
    try {
      final model = await _apiService.createProgram({
        'name': name,
        if (portfolioId != null) 'portfolio_id': portfolioId,
        if (description != null) 'description': description,
      });
      return model.toEntity();
    } catch (e) {
      Logger.error('Failed to create program', e);
      throw ServerException('Failed to create program: ${e.toString()}');
    }
  }

  @override
  Future<Program> updateProgram({
    required String programId,
    String? name,
    String? description,
    String? portfolioId,
  }) async {
    try {
      final model = await _apiService.updateProgram(programId, {
        if (name != null) 'name': name,
        if (description != null) 'description': description,
        // Always include portfolio_id when name is provided (move operation)
        // This allows setting it to null for standalone
        if (name != null || portfolioId != null) 'portfolio_id': portfolioId,
      });
      return model.toEntity();
    } catch (e) {
      Logger.error('Failed to update program', e);
      throw ServerException('Failed to update program: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteProgram({
    required String programId,
    bool cascadeDelete = false,
  }) async {
    try {
      await _apiService.deleteProgram(programId, cascadeDelete);
      // HttpResponse is handled, no return needed for void
    } catch (e) {
      Logger.error('Failed to delete program', e);
      throw ServerException('Failed to delete program: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> moveProjectsToProgram({
    required String programId,
    required List<String> projectIds,
  }) async {
    try {
      final httpResponse = await _apiService.moveProjectsToProgram(programId, {
        'project_ids': projectIds,
      });
      return httpResponse.data as Map<String, dynamic>;
    } catch (e) {
      Logger.error('Failed to move projects to program', e);
      throw ServerException('Failed to move projects to program: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> getProgramStatistics(String programId) async {
    try {
      final httpResponse = await _apiService.getProgramStatistics(programId);
      return httpResponse.data as Map<String, dynamic>;
    } catch (e) {
      Logger.error('Failed to get program statistics', e);
      throw ServerException('Failed to get program statistics: ${e.toString()}');
    }
  }

  HierarchyItemType _parseHierarchyItemType(String type) {
    switch (type) {
      case 'portfolio':
        return HierarchyItemType.portfolio;
      case 'program':
        return HierarchyItemType.program;
      case 'project':
        return HierarchyItemType.project;
      default:
        return HierarchyItemType.portfolio;
    }
  }
}