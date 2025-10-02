import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'new_items_provider.g.dart';

// Class to track when an item was marked as new
class NewItemEntry {
  final String itemId;
  final DateTime addedAt;

  NewItemEntry({
    required this.itemId,
    required this.addedAt,
  });

  // Items stay "new" for 5 minutes
  bool get isExpired {
    final now = DateTime.now();
    return now.difference(addedAt).inMinutes >= 5;
  }
}

// Provider to track newly generated items (documents and summaries)
// Items are marked as "new" for 5 minutes after creation
// This persists across page navigation within the time window
@Riverpod(keepAlive: true)
class NewItems extends _$NewItems {
  @override
  Map<String, NewItemEntry> build() {
    // Initialize with empty map
    return {};
  }

  void addNewItem(String itemId) {
    // Add or update the item with current timestamp
    state = {
      ...state,
      itemId: NewItemEntry(
        itemId: itemId,
        addedAt: DateTime.now(),
      ),
    };
  }

  void removeNewItem(String itemId) {
    state = {...state}..remove(itemId);
  }

  void clearNewItems() {
    state = {};
  }

  void clearExpiredItems() {
    _cleanupExpiredItems();
  }

  bool isNewItem(String itemId) {
    // Clean up expired items first
    _cleanupExpiredItems();

    // Check if item exists and is not expired
    final entry = state[itemId];
    if (entry != null && !entry.isExpired) {
      return true;
    }

    // Remove expired item if it exists
    if (entry != null) {
      removeNewItem(itemId);
    }

    return false;
  }

  void _cleanupExpiredItems() {
    // Check if state is initialized before trying to clean it up
    try {
      final currentState = state;
      final nonExpiredItems = <String, NewItemEntry>{};

      currentState.forEach((id, entry) {
        if (!entry.isExpired) {
          nonExpiredItems[id] = entry;
        }
      });

      if (nonExpiredItems.length != currentState.length) {
        state = nonExpiredItems;
      }
    } catch (e) {
      // State not yet initialized, skip cleanup
      return;
    }
  }
}