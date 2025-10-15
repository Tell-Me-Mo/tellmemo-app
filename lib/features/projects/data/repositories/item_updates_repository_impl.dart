import 'package:dio/dio.dart';
import '../../domain/entities/item_update.dart';
import '../../domain/repositories/item_updates_repository.dart';
import '../models/item_update_model.dart';
import '../../../../core/utils/logger.dart' as logger;

class ItemUpdatesRepositoryImpl implements ItemUpdatesRepository {
  final Dio _dio;

  ItemUpdatesRepositoryImpl({
    required Dio dio,
  }) : _dio = dio;

  @override
  Future<List<ItemUpdate>> getItemUpdates({
    required String projectId,
    required String itemId,
    required String itemType,
  }) async {
    try {
      final response = await _dio.get(
        '/api/v1/projects/$projectId/$itemType/$itemId/updates',
      );

      final updates = (response.data as List)
          .map((json) => ItemUpdateModel.fromJson(json).toEntity())
          .toList();

      return updates;
    } catch (e) {
      logger.Logger.error('Failed to fetch item updates for $itemType $itemId', e);
      rethrow;
    }
  }

  @override
  Future<ItemUpdate> addItemUpdate({
    required String projectId,
    required String itemId,
    required String itemType,
    required String content,
    required ItemUpdateType type,
    String? authorName,
    String? authorEmail,
  }) async {
    try {
      final response = await _dio.post(
        '/api/v1/projects/$projectId/$itemType/$itemId/updates',
        data: {
          'content': content,
          'update_type': type.name,
          'author_name': authorName ?? 'Current User',
          'author_email': authorEmail,
        },
      );

      return ItemUpdateModel.fromJson(response.data).toEntity();
    } catch (e) {
      logger.Logger.error('Failed to add item update for $itemType $itemId', e);
      rethrow;
    }
  }

  @override
  Future<void> deleteItemUpdate(String updateId) async {
    try {
      await _dio.delete('/api/v1/updates/$updateId');
    } catch (e) {
      logger.Logger.error('Failed to delete item update $updateId', e);
      rethrow;
    }
  }
}
