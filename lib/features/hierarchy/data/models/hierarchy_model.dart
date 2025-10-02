import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/hierarchy_item.dart';
import 'portfolio_model.dart';
import 'program_model.dart';
import '../../../projects/data/models/project_model.dart';

part 'hierarchy_model.freezed.dart';
part 'hierarchy_model.g.dart';

@freezed
class HierarchyResponse with _$HierarchyResponse {
  const factory HierarchyResponse({
    required List<HierarchyNodeModel> hierarchy,
    @JsonKey(name: 'include_archived') @Default(false) bool includeArchived,
    @JsonKey(name: 'total_portfolios') @Default(0) int totalPortfolios,
    @JsonKey(name: 'has_orphaned_items') @Default(false) bool hasOrphanedItems,
  }) = _HierarchyResponse;

  factory HierarchyResponse.fromJson(Map<String, dynamic> json) =>
      _$HierarchyResponseFromJson(json);
}

@freezed
class HierarchyNodeModel with _$HierarchyNodeModel {
  const factory HierarchyNodeModel({
    required String id,
    required String name,
    String? description,
    required String type, // 'portfolio', 'program', 'project', 'virtual'
    @JsonKey(name: 'portfolio_id') String? portfolioId,
    @JsonKey(name: 'program_id') String? programId,
    @JsonKey(name: 'created_at') String? createdAt,
    @JsonKey(name: 'updated_at') String? updatedAt,
    String? status, // For projects
    @JsonKey(name: 'member_count') int? memberCount,
    
    // Nested content
    @Default([]) List<HierarchyNodeModel> children,
    @Default([]) List<HierarchyNodeModel> programs,
    @JsonKey(name: 'direct_projects') @Default([]) List<HierarchyNodeModel> directProjects,
    @Default([]) List<HierarchyNodeModel> projects,
  }) = _HierarchyNodeModel;

  factory HierarchyNodeModel.fromJson(Map<String, dynamic> json) =>
      _$HierarchyNodeModelFromJson(json);
}

@freezed
class MoveItemRequest with _$MoveItemRequest {
  const MoveItemRequest._();
  const factory MoveItemRequest({
    @JsonKey(name: 'item_id') required String itemId,
    @JsonKey(name: 'item_type') required String itemType,
    @JsonKey(name: 'target_parent_id') String? targetParentId,
    @JsonKey(name: 'target_parent_type') String? targetParentType,
  }) = _MoveItemRequest;

  factory MoveItemRequest.fromJson(Map<String, dynamic> json) =>
      _$MoveItemRequestFromJson(json);
}

@freezed
class BulkMoveRequest with _$BulkMoveRequest {
  const BulkMoveRequest._();
  const factory BulkMoveRequest({
    required List<MoveItemData> items,
    @JsonKey(name: 'target_parent_id') String? targetParentId,
    @JsonKey(name: 'target_parent_type') String? targetParentType,
  }) = _BulkMoveRequest;

  factory BulkMoveRequest.fromJson(Map<String, dynamic> json) =>
      _$BulkMoveRequestFromJson(json);
}

@freezed
class MoveItemData with _$MoveItemData {
  const MoveItemData._();
  const factory MoveItemData({
    required String id,
    required String type,
  }) = _MoveItemData;

  factory MoveItemData.fromJson(Map<String, dynamic> json) =>
      _$MoveItemDataFromJson(json);
}

@freezed
class MoveItemResponse with _$MoveItemResponse {
  const factory MoveItemResponse({
    required bool success,
    required String message,
    required HierarchyNodeModel item,
  }) = _MoveItemResponse;

  factory MoveItemResponse.fromJson(Map<String, dynamic> json) =>
      _$MoveItemResponseFromJson(json);
}

@freezed
class BulkMoveResponse with _$BulkMoveResponse {
  const factory BulkMoveResponse({
    required String message,
    required BulkMoveResults results,
  }) = _BulkMoveResponse;

  factory BulkMoveResponse.fromJson(Map<String, dynamic> json) =>
      _$BulkMoveResponseFromJson(json);
}

@freezed
class BulkMoveResults with _$BulkMoveResults {
  const factory BulkMoveResults({
    @JsonKey(name: 'success_count') required int successCount,
    @JsonKey(name: 'error_count') required int errorCount,
    @Default([]) List<Map<String, dynamic>> errors,
    @JsonKey(name: 'moved_items') @Default([]) List<HierarchyNodeModel> movedItems,
  }) = _BulkMoveResults;

  factory BulkMoveResults.fromJson(Map<String, dynamic> json) =>
      _$BulkMoveResultsFromJson(json);
}

@freezed
class BulkDeleteRequest with _$BulkDeleteRequest {
  const BulkDeleteRequest._();
  const factory BulkDeleteRequest({
    required List<MoveItemData> items,
    @JsonKey(name: 'delete_children') required bool deleteChildren,
    @JsonKey(name: 'reassign_to_id') String? reassignToId,
    @JsonKey(name: 'reassign_to_type') String? reassignToType,
  }) = _BulkDeleteRequest;

  factory BulkDeleteRequest.fromJson(Map<String, dynamic> json) =>
      _$BulkDeleteRequestFromJson(json);
}

@freezed
class BulkDeleteResponse with _$BulkDeleteResponse {
  const factory BulkDeleteResponse({
    required String message,
    required BulkDeleteResults results,
  }) = _BulkDeleteResponse;

  factory BulkDeleteResponse.fromJson(Map<String, dynamic> json) =>
      _$BulkDeleteResponseFromJson(json);
}

@freezed
class BulkDeleteResults with _$BulkDeleteResults {
  const factory BulkDeleteResults({
    @JsonKey(name: 'deleted_count') required int deletedCount,
    @JsonKey(name: 'reassigned_count') int? reassignedCount,
    @JsonKey(name: 'error_count') required int errorCount,
    @Default([]) List<Map<String, dynamic>> errors,
  }) = _BulkDeleteResults;

  factory BulkDeleteResults.fromJson(Map<String, dynamic> json) =>
      _$BulkDeleteResultsFromJson(json);
}

extension HierarchyNodeModelX on HierarchyNodeModel {
  /// Convert to HierarchyItem entity
  HierarchyItem toEntity() {
    HierarchyItemType itemType;
    switch (type) {
      case 'portfolio':
        itemType = HierarchyItemType.portfolio;
        break;
      case 'program':
        itemType = HierarchyItemType.program;
        break;
      case 'project':
        itemType = HierarchyItemType.project;
        break;
      default:
        itemType = HierarchyItemType.portfolio; // Default for virtual/unknown types
    }

    // Use children field if present, otherwise fall back to separate fields
    List<HierarchyItem> childItems = [];
    if (this.children.isNotEmpty) {
      childItems.addAll(this.children.map((c) => c.toEntity()));
    } else {
      childItems.addAll(programs.map((p) => p.toEntity()));
      childItems.addAll(directProjects.map((p) => p.toEntity()));
      childItems.addAll(projects.map((p) => p.toEntity()));
    }

    return HierarchyItem(
      id: id,
      name: name,
      description: description,
      type: itemType,
      portfolioId: portfolioId,
      programId: programId,
      createdAt: createdAt != null ? DateTime.parse('${createdAt}Z').toLocal() : DateTime.now(),
      updatedAt: updatedAt != null ? DateTime.parse('${updatedAt}Z').toLocal() : DateTime.now(),
      children: childItems,
      metadata: {
        'status': status,
        'memberCount': memberCount ?? 0,
        'childCount': childItems.length,
        'type': type,
      },
    );
  }

  /// Check if this is a container node (portfolio or program)
  bool get isContainer => type == 'portfolio' || type == 'program';

  /// Get total child count
  int get totalChildCount => children.length + programs.length + directProjects.length + projects.length;

  /// Check if this node has any children
  bool get hasChildren => totalChildCount > 0;
}