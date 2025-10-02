import 'hierarchy_api_service.dart';
import '../../domain/entities/hierarchy_item.dart';

extension HierarchyApiServiceExtensions on HierarchyApiService {
  Future<Map<String, dynamic>> getDeletionImpact(
    String itemId,
    HierarchyItemType itemType,
  ) async {
    switch (itemType) {
      case HierarchyItemType.portfolio:
        final response = await getPortfolioDeletionImpact(itemId);
        return response.data as Map<String, dynamic>;
      case HierarchyItemType.program:
        final response = await getProgramDeletionImpact(itemId);
        return response.data as Map<String, dynamic>;
      case HierarchyItemType.project:
        // Projects don't have child items to check
        return {
          'affected_items': [],
        };
    }
  }
}