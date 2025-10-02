import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/hierarchy_item.dart';
import '../../domain/entities/portfolio.dart';
import '../../domain/entities/program.dart';
import '../../domain/repositories/hierarchy_repository.dart';
import '../../../projects/domain/entities/project.dart';
import '../../../../core/utils/logger.dart';
import '../../data/repositories/hierarchy_repository_impl.dart';
import '../../data/services/hierarchy_api_service.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/services/firebase_analytics_service.dart';

part 'hierarchy_providers.g.dart';

// Core providers
@riverpod
HierarchyApiService hierarchyApiService(HierarchyApiServiceRef ref) {
  return HierarchyApiService(DioClient.instance);
}

@riverpod
HierarchyRepository hierarchyRepository(HierarchyRepositoryRef ref) {
  final apiService = ref.watch(hierarchyApiServiceProvider);
  return HierarchyRepositoryImpl(apiService);
}

// Hierarchy state providers
@riverpod
class HierarchyState extends _$HierarchyState {
  @override
  Future<List<HierarchyItem>> build({bool includeArchived = false}) async {
    // Keep provider alive for 5 minutes to avoid refetching on navigation
    ref.keepAlive();
    Timer(const Duration(minutes: 5), () {
      ref.invalidateSelf();
    });

    final repository = ref.watch(hierarchyRepositoryProvider);
    return await repository.getFullHierarchy(includeArchived: includeArchived);
  }

  Future<void> refresh({bool includeArchived = false}) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(hierarchyRepositoryProvider);
      final hierarchy = await repository.getFullHierarchy(includeArchived: includeArchived);
      state = AsyncValue.data(hierarchy);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> moveItem({
    required String itemId,
    required String itemType,
    String? targetParentId,
    String? targetParentType,
  }) async {
    try {
      final repository = ref.read(hierarchyRepositoryProvider);
      await repository.moveItem(
        itemId: itemId,
        itemType: itemType,
        targetParentId: targetParentId,
        targetParentType: targetParentType,
      );
      
      // Refresh hierarchy after move
      await refresh(includeArchived: state.value?.any((item) => 
        _hasArchivedProjects(item)) ?? false);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> bulkMoveItems({
    required List<Map<String, String>> items,
    String? targetParentId,
    String? targetParentType,
  }) async {
    try {
      final repository = ref.read(hierarchyRepositoryProvider);
      final result = await repository.bulkMoveItems(
        items: items,
        targetParentId: targetParentId,
        targetParentType: targetParentType,
      );
      
      // Refresh hierarchy after bulk move
      await refresh(includeArchived: state.value?.any((item) => 
        _hasArchivedProjects(item)) ?? false);
      
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> bulkDeleteItems({
    required List<Map<String, String>> items,
    bool deleteChildren = true,
    String? reassignToId,
    String? reassignToType,
  }) async {
    try {
      final repository = ref.read(hierarchyRepositoryProvider);
      final result = await repository.bulkDeleteItems(
        items: items,
        deleteChildren: deleteChildren,
        reassignToId: reassignToId,
        reassignToType: reassignToType,
      );
      
      // Refresh hierarchy after bulk delete
      await refresh(includeArchived: state.value?.any((item) => 
        _hasArchivedProjects(item)) ?? false);
      
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  bool _hasArchivedProjects(HierarchyItem item) {
    final metadata = item.metadata;
    if (metadata != null && metadata['status'] == 'archived') {
      return true;
    }
    return item.children.any(_hasArchivedProjects);
  }
}

// Portfolio providers
@riverpod
class PortfolioList extends _$PortfolioList {
  @override
  Future<List<Portfolio>> build() async {
    final repository = ref.watch(hierarchyRepositoryProvider);
    return await repository.getPortfolios();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(hierarchyRepositoryProvider);
      final portfolios = await repository.getPortfolios();
      state = AsyncValue.data(portfolios);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<Portfolio> createPortfolio({
    required String name,
    String? description,
  }) async {
    final repository = ref.read(hierarchyRepositoryProvider);
    final portfolio = await repository.createPortfolio(
      name: name,
      description: description,
    );

    // Log portfolio created analytics
    try {
      await FirebaseAnalyticsService().logPortfolioCreated(
        portfolioId: portfolio.id,
        portfolioName: portfolio.name,
      );
    } catch (e) {
      Logger.error('Failed to log portfolio created analytics', e);
    }

    // Refresh portfolios list
    await refresh();

    return portfolio;
  }

  Future<Portfolio> updatePortfolio({
    required String portfolioId,
    String? name,
    String? description,
    String? owner,
    HealthStatus? healthStatus,
    String? riskSummary,
  }) async {
    final repository = ref.read(hierarchyRepositoryProvider);
    final portfolio = await repository.updatePortfolio(
      portfolioId: portfolioId,
      name: name,
      description: description,
      owner: owner,
      healthStatus: healthStatus,
      riskSummary: riskSummary,
    );
    
    // Refresh portfolios list
    await refresh();
    
    return portfolio;
  }

  Future<void> deletePortfolio({
    required String portfolioId,
    bool cascadeDelete = false,
  }) async {
    final repository = ref.read(hierarchyRepositoryProvider);
    await repository.deletePortfolio(
      portfolioId: portfolioId,
      cascadeDelete: cascadeDelete,
    );

    // Refresh portfolios list
    await refresh();
  }
}

@riverpod
Future<Portfolio?> portfolio(PortfolioRef ref, String portfolioId) async {
  final repository = ref.watch(hierarchyRepositoryProvider);
  final portfolio = await repository.getPortfolio(portfolioId);

  if (portfolio != null) {
    // Log portfolio viewed analytics
    try {
      await FirebaseAnalyticsService().logPortfolioViewed(
        portfolioId: portfolio.id,
        portfolioName: portfolio.name,
      );
    } catch (e) {
      Logger.error('Failed to log portfolio viewed analytics', e);
    }

    // Fetch programs for this portfolio to ensure we have the complete list
    try {
      final programs = await repository.getPrograms(portfolioId: portfolioId);
      // Fetch projects directly assigned to this portfolio (not through programs)
      final hierarchyData = await repository.getFullHierarchy();
      final portfolioHierarchy = hierarchyData.firstWhere(
        (item) => item.id == portfolioId && item.type == HierarchyItemType.portfolio,
        orElse: () => HierarchyItem(
          id: portfolioId,
          name: portfolio.name,
          type: HierarchyItemType.portfolio,
          children: [],
          createdAt: portfolio.createdAt,
          updatedAt: portfolio.updatedAt,
        ),
      );

      // Get direct projects (projects that belong to portfolio but not to any program)
      final directProjects = <Project>[];
      for (final child in portfolioHierarchy.children) {
        if (child.type == HierarchyItemType.project) {
          // This is a direct project
          directProjects.add(Project(
            id: child.id,
            name: child.name,
            description: child.description ?? '',
            status: ProjectStatus.active,
            createdBy: portfolio.createdBy ?? '',
            createdAt: child.createdAt,
            updatedAt: child.updatedAt,
            portfolioId: portfolioId,
            programId: null,
          ));
        }
      }

      // Return portfolio with updated programs and projects
      return portfolio.copyWith(
        programs: programs,
        directProjects: directProjects,
      );
    } catch (e) {
      // If we can't fetch programs, return portfolio as is
      Logger.error('Failed to fetch programs for portfolio', e);
      return portfolio;
    }
  }

  return portfolio;
}

@riverpod
Future<Map<String, dynamic>> portfolioStatistics(
  PortfolioStatisticsRef ref,
  String portfolioId,
) async {
  final repository = ref.watch(hierarchyRepositoryProvider);
  return await repository.getPortfolioStatistics(portfolioId);
}

// Program providers
@riverpod
class ProgramList extends _$ProgramList {
  @override
  Future<List<Program>> build({String? portfolioId}) async {
    final repository = ref.watch(hierarchyRepositoryProvider);
    return await repository.getPrograms(portfolioId: portfolioId);
  }

  Future<void> refresh({String? portfolioId}) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(hierarchyRepositoryProvider);
      final programs = await repository.getPrograms(portfolioId: portfolioId);
      state = AsyncValue.data(programs);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<Program> createProgram({
    required String name,
    String? portfolioId,
    String? description,
  }) async {
    final repository = ref.read(hierarchyRepositoryProvider);
    final program = await repository.createProgram(
      name: name,
      portfolioId: portfolioId,
      description: description,
    );

    // Log program created analytics
    try {
      await FirebaseAnalyticsService().logProgramCreated(
        programId: program.id,
        programName: program.name,
        portfolioId: portfolioId,
      );
    } catch (e) {
      Logger.error('Failed to log program created analytics', e);
    }

    // Refresh programs list
    await refresh(portfolioId: portfolioId);

    return program;
  }

  Future<Program> updateProgram({
    required String programId,
    String? name,
    String? description,
    String? portfolioId,
  }) async {
    final repository = ref.read(hierarchyRepositoryProvider);
    final program = await repository.updateProgram(
      programId: programId,
      name: name,
      description: description,
      portfolioId: portfolioId,
    );
    
    // Refresh programs list
    await refresh(portfolioId: program.portfolioId);
    
    return program;
  }

  Future<void> deleteProgram({
    required String programId,
    bool cascadeDelete = false,
    String? portfolioId,
  }) async {
    final repository = ref.read(hierarchyRepositoryProvider);
    await repository.deleteProgram(
      programId: programId,
      cascadeDelete: cascadeDelete,
    );

    // Refresh programs list
    await refresh(portfolioId: portfolioId);
  }

  Future<Map<String, dynamic>> moveProjectsToProgram({
    required String programId,
    required List<String> projectIds,
  }) async {
    final repository = ref.read(hierarchyRepositoryProvider);
    final result = await repository.moveProjectsToProgram(
      programId: programId,
      projectIds: projectIds,
    );
    
    // Refresh hierarchy after moving projects
    ref.invalidate(hierarchyStateProvider);
    
    return result;
  }
}

@riverpod
Future<Program?> program(ProgramRef ref, String programId) async {
  final repository = ref.watch(hierarchyRepositoryProvider);
  final program = await repository.getProgram(programId);

  // Log program viewed analytics
  if (program != null) {
    try {
      await FirebaseAnalyticsService().logProgramViewed(
        programId: program.id,
        programName: program.name,
      );
    } catch (e) {
      Logger.error('Failed to log program viewed analytics', e);
    }
  }

  return program;
}

@riverpod
Future<Map<String, dynamic>> programStatistics(
  ProgramStatisticsRef ref,
  String programId,
) async {
  final repository = ref.watch(hierarchyRepositoryProvider);
  return await repository.getProgramStatistics(programId);
}

// Utility providers
@riverpod
Future<List<HierarchyBreadcrumb>> hierarchyPath(
  HierarchyPathRef ref,
  String itemId,
  String itemType,
) async {
  final repository = ref.watch(hierarchyRepositoryProvider);
  final path = await repository.getHierarchyPath(itemId: itemId, itemType: itemType);

  // Log hierarchy navigation analytics
  try {
    await FirebaseAnalyticsService().logHierarchyNavigated(
      level: itemType,
      entityId: itemId,
      navigationSource: 'breadcrumb',
    );
  } catch (e) {
    Logger.error('Failed to log hierarchy navigated analytics', e);
  }

  return path;
}

@riverpod
Future<Map<String, dynamic>> hierarchyStatistics(HierarchyStatisticsRef ref) async {
  final repository = ref.watch(hierarchyRepositoryProvider);
  return await repository.getHierarchyStatistics();
}

// Selection state for UI operations
@riverpod
class HierarchySelection extends _$HierarchySelection {
  @override
  Set<String> build() {
    return <String>{};
  }

  void toggleSelection(String itemId) {
    if (state.contains(itemId)) {
      state = Set.from(state)..remove(itemId);
    } else {
      state = Set.from(state)..add(itemId);
    }
  }

  void selectAll(List<String> itemIds) {
    state = Set.from(itemIds);
  }

  void clearSelection() {
    state = <String>{};
  }

  void selectItem(String itemId) {
    state = {itemId};
  }

  bool isSelected(String itemId) {
    return state.contains(itemId);
  }

  bool get hasSelection => state.isNotEmpty;
  int get selectionCount => state.length;
  List<String> get selectedItems => state.toList();
}