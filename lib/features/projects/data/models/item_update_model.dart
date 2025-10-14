import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/item_update.dart';

part 'item_update_model.freezed.dart';
part 'item_update_model.g.dart';

@freezed
class ItemUpdateModel with _$ItemUpdateModel {
  const factory ItemUpdateModel({
    required String id,
    @JsonKey(name: 'item_id') required String itemId,
    @JsonKey(name: 'item_type') required String itemType,
    @JsonKey(name: 'project_id') required String projectId,
    required String content,
    @JsonKey(name: 'author_name') required String authorName,
    @JsonKey(name: 'author_email') String? authorEmail,
    required String timestamp,
    @JsonKey(name: 'update_type') required String updateType,
  }) = _ItemUpdateModel;

  factory ItemUpdateModel.fromJson(Map<String, dynamic> json) =>
      _$ItemUpdateModelFromJson(json);
}

extension ItemUpdateModelX on ItemUpdateModel {
  ItemUpdate toEntity() {
    return ItemUpdate(
      id: id,
      itemId: itemId,
      itemType: itemType,
      projectId: projectId,
      content: content,
      authorName: authorName,
      authorEmail: authorEmail,
      timestamp: DateTime.parse(timestamp + (timestamp.endsWith('Z') ? '' : 'Z')).toLocal(),
      type: ItemUpdateType.values.firstWhere(
        (t) => t.name == updateType,
        orElse: () => ItemUpdateType.comment,
      ),
    );
  }
}

extension ItemUpdateX on ItemUpdate {
  ItemUpdateModel toModel() {
    return ItemUpdateModel(
      id: id,
      itemId: itemId,
      itemType: itemType,
      projectId: projectId,
      content: content,
      authorName: authorName,
      authorEmail: authorEmail,
      timestamp: timestamp.toUtc().toIso8601String(),
      updateType: type.name,
    );
  }
}
