import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/item_update.dart';
import '../../domain/repositories/item_updates_repository.dart';
import '../../data/repositories/item_updates_repository_impl.dart';
import '../../../../core/network/dio_client.dart';

// Repository provider
final itemUpdatesRepositoryProvider = Provider<ItemUpdatesRepository>((ref) {
  return ItemUpdatesRepositoryImpl(dio: DioClient.instance);
});

// Parameters for ItemUpdates family provider
class ItemUpdatesParams {
  final String projectId;
  final String itemId;
  final String itemType;

  const ItemUpdatesParams({
    required this.projectId,
    required this.itemId,
    required this.itemType,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ItemUpdatesParams &&
          runtimeType == other.runtimeType &&
          projectId == other.projectId &&
          itemId == other.itemId &&
          itemType == other.itemType;

  @override
  int get hashCode => projectId.hashCode ^ itemId.hashCode ^ itemType.hashCode;
}

// State notifier for managing item updates
class ItemUpdatesNotifier extends StateNotifier<AsyncValue<List<ItemUpdate>>> {
  final ItemUpdatesRepository _repository;
  final ItemUpdatesParams params;

  ItemUpdatesNotifier(this._repository, this.params) : super(const AsyncValue.loading()) {
    loadUpdates();
  }

  Future<void> loadUpdates() async {
    if (!mounted) return;
    state = const AsyncValue.loading();
    try {
      final updates = await _repository.getItemUpdates(
        projectId: params.projectId,
        itemId: params.itemId,
        itemType: params.itemType,
      );
      if (!mounted) return;
      state = AsyncValue.data(updates);
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addComment(String content) async {
    try {
      final newUpdate = await _repository.addItemUpdate(
        projectId: params.projectId,
        itemId: params.itemId,
        itemType: params.itemType,
        content: content,
        type: ItemUpdateType.comment,
      );
      if (!mounted) return;
      state = state.whenData((updates) => [...updates, newUpdate]);
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deleteUpdate(String updateId) async {
    try {
      await _repository.deleteItemUpdate(updateId);
      if (!mounted) return;
      state = state.whenData((updates) =>
          updates.where((u) => u.id != updateId).toList());
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncValue.error(e, st);
    }
  }
}

// State notifier provider for item updates
final itemUpdatesNotifierProvider = StateNotifierProvider.family<
    ItemUpdatesNotifier,
    AsyncValue<List<ItemUpdate>>,
    ItemUpdatesParams>((ref, params) {
  final repository = ref.watch(itemUpdatesRepositoryProvider);
  return ItemUpdatesNotifier(repository, params);
});
