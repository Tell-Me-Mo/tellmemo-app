import '../entities/item_update.dart';

abstract class ItemUpdatesRepository {
  /// Get all updates for a specific item
  Future<List<ItemUpdate>> getItemUpdates({
    required String projectId,
    required String itemId,
    required String itemType,
  });

  /// Add a new comment/update to an item
  Future<ItemUpdate> addItemUpdate({
    required String projectId,
    required String itemId,
    required String itemType,
    required String content,
    required ItemUpdateType type,
    String? authorName,
    String? authorEmail,
  });

  /// Delete an item update (optional - for future use)
  Future<void> deleteItemUpdate(String updateId);
}
